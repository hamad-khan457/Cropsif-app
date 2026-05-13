FROM python:3.11-slim

WORKDIR /app/Plant_disease_prediction

# Increase pip timeout and retries for unstable connections
ENV PIP_DEFAULT_TIMEOUT=300
ENV PIP_RETRIES=10

# Step 1: Small packages (fast, cached as separate layer)
RUN pip install --no-cache-dir \
    fastapi==0.111.0 \
    uvicorn==0.30.1 \
    pillow==10.3.0 \
    python-multipart==0.0.9 \
    pyyaml \
    anyio \
    sniffio \
    idna \
    click \
    h11 \
    pydantic \
    pydantic-core \
    annotated-types \
    typing-extensions \
    typing-inspection \
    starlette

# Step 2: torch CPU-only — biggest download, cached as its own layer
RUN pip install --no-cache-dir \
    --index-url https://download.pytorch.org/whl/cpu \
    torch==2.2.2+cpu

# Step 3: torchvision CPU-only
RUN pip install --no-cache-dir \
    --index-url https://download.pytorch.org/whl/cpu \
    torchvision==0.17.2+cpu

# Step 4: torch dependencies
# numpy<2.0 required — torch 2.2.2 + torchvision 0.17.2 predate numpy 2.0's
# broken C API and will throw "Numpy is not available" at inference time with 2.x.
RUN pip install --no-cache-dir \
    "numpy>=1.24,<2.0" \
    filelock \
    sympy \
    networkx \
    jinja2 \
    fsspec \
    mpmath

# Step 5: timm + huggingface
RUN pip install --no-cache-dir \
    safetensors \
    huggingface-hub \
    timm

# Copy everything from ml/ into the container
COPY . /app/

EXPOSE 8000

CMD ["python", "main.py"]