import axios from 'axios';
import { tokenStorage } from '../utils/tokenStorage';

const BASE = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:5000/api/v1';

const api = axios.create({ baseURL: BASE, timeout: 15_000 });

// ── Request: attach Bearer token ──────────────────────────────────────────────
api.interceptors.request.use(async (config) => {
  let token = tokenStorage.getAccess();

  if (token && tokenStorage.isExpired(token)) {
    const refresh = tokenStorage.getRefresh();
    if (refresh) {
      try {
        const { data } = await axios.post(`${BASE}/auth/refresh`, { refreshToken: refresh });
        const { accessToken, refreshToken } = data.data;
        tokenStorage.setTokens(accessToken, refreshToken);
        token = accessToken;
      } catch {
        tokenStorage.clear();
        window.location.href = '/login';
        return Promise.reject(new Error('Session expired'));
      }
    }
  }

  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// ── Response: surface backend error messages ──────────────────────────────────
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      tokenStorage.clear();
      window.location.href = '/login';
    }
    const message = err.response?.data?.message ?? err.message ?? 'Something went wrong';
    return Promise.reject(new Error(message));
  },
);

export default api;