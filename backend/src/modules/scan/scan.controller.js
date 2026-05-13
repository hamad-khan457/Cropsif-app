const http  = require('http');
const https = require('https');
const { URL } = require('url');

const ML_URL        = process.env.ML_URL || 'http://localhost:8000';
const ML_TIMEOUT_MS = 60_000; // 60 s — EfficientNet-B3 can be slow on first run

// ── Multipart helper ──────────────────────────────────────────────────────────
// Uses Node's built-in http/https — avoids native fetch/FormData/Blob quirks.
function postFileMultipart(urlStr, buffer, mimetype, filename) {
  return new Promise((resolve, reject) => {
    const boundary = `----CropsifyBoundary${Date.now()}`;
    const CRLF     = '\r\n';

    const head = Buffer.from(
      `--${boundary}${CRLF}` +
      `Content-Disposition: form-data; name="file"; filename="${filename}"${CRLF}` +
      `Content-Type: ${mimetype}${CRLF}${CRLF}`,
    );
    const tail  = Buffer.from(`${CRLF}--${boundary}--${CRLF}`);
    const body  = Buffer.concat([head, buffer, tail]);

    const parsed = new URL(urlStr);
    const lib    = parsed.protocol === 'https:' ? https : http;

    const req = lib.request(
      {
        hostname: parsed.hostname,
        port:     parsed.port || (parsed.protocol === 'https:' ? 443 : 80),
        path:     parsed.pathname + parsed.search,
        method:   'POST',
        headers:  {
          'Content-Type':   `multipart/form-data; boundary=${boundary}`,
          'Content-Length': body.length,
        },
        timeout: ML_TIMEOUT_MS,
      },
      (mlRes) => {
        const chunks = [];
        mlRes.on('data', (chunk) => chunks.push(chunk));
        mlRes.on('end',  () =>
          resolve({ status: mlRes.statusCode, body: Buffer.concat(chunks).toString() }),
        );
      },
    );

    req.on('timeout', () => {
      req.destroy();
      reject(Object.assign(new Error('ML request timed out'), { isTimeout: true }));
    });
    req.on('error', reject);

    req.write(body);
    req.end();
  });
}

// ── Controller ────────────────────────────────────────────────────────────────
async function predict(req, res, next) {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No image uploaded' });
    }

    const filename = req.file.originalname || 'leaf.jpg';
    const mimetype = req.file.mimetype     || 'image/jpeg';

    let mlResult;
    try {
      mlResult = await postFileMultipart(
        `${ML_URL}/predict`,
        req.file.buffer,
        mimetype,
        filename,
      );
    } catch (err) {
      const isDown = err.code === 'ECONNREFUSED' || err.isTimeout;
      console.error('[scan] ML unreachable:', err.message);
      return res.status(503).json({
        message: isDown
          ? 'Disease detection service is temporarily unavailable. Please try again in a moment.'
          : 'Could not reach the disease detection service. Please try again.',
      });
    }

    if (mlResult.status < 200 || mlResult.status >= 300) {
      console.error('[scan] ML error', mlResult.status, mlResult.body);
      return res.status(502).json({
        message: 'Disease detection failed. Please try a clearer leaf image.',
      });
    }

    let data;
    try {
      data = JSON.parse(mlResult.body);
    } catch {
      console.error('[scan] ML returned non-JSON:', mlResult.body);
      return res.status(502).json({ message: 'Unexpected response from disease detection service.' });
    }

    res.json(data);
  } catch (err) {
    next(err);
  }
}

module.exports = { predict };
