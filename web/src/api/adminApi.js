import api from './axios';

export const adminApi = {
  getStats: async () => {
    const { data } = await api.get('/admin/stats');
    return data.data.stats;
  },

  listUsers: async (params = {}) => {
    const { data } = await api.get('/admin/users', { params });
    return data.data; // { users, pagination }
  },

  getUserById: async (id) => {
    const { data } = await api.get(`/admin/users/${id}`);
    return data.data.user;
  },

  setUserStatus: async (id, isActive) => {
    const { data } = await api.patch(`/admin/users/${id}/status`, { isActive });
    return data.data.user;
  },
};