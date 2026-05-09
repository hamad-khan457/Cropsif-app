import api from './axios';
import { tokenStorage } from '../utils/tokenStorage';

export const authApi = {
  login: async (email, password) => {
    const { data } = await api.post('/auth/login', { identifier: email, password });
    const { accessToken, refreshToken, user } = data.data;
    tokenStorage.setTokens(accessToken, refreshToken);
    return user;
  },

  logout: async () => {
    try { await api.post('/auth/logout', {}); } finally { tokenStorage.clear(); }
  },

  me: async () => {
    const { data } = await api.get('/users/me');
    return data.data.profile;
  },

  changePassword: async (currentPassword, newPassword) => {
    await api.put('/users/me/password', { currentPassword, newPassword });
  },

  updateProfile: async (body) => {
    const { data } = await api.patch('/users/me', body);
    return data.data.user;
  },
};