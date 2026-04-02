import api from './client';

export const authApi = {
  login: (data) => api.post('/auth/login', data),
};

export const foodApi = {
  getAll: () => api.get('/food-items'),
  create: (data) => api.post('/food-items', data),
  update: (id, data) => api.put(`/food-items/${id}`, data),
  delete: (id) => api.delete(`/food-items/${id}`),
};

export const packageApi = {
  getAll: () => api.get('/paluwagan/packages'),
  create: (data) => api.post('/paluwagan/packages', data),
  update: (id, data) => api.put(`/paluwagan/packages/${id}`, data),
  delete: (id) => api.delete(`/paluwagan/packages/${id}`),
};

export const memberApi = {
  getAll: () => api.get('/paluwagan/members'),
  getById: (id) => api.get(`/paluwagan/members/${id}`),
  create: (data) => api.post('/paluwagan/members', data),
  update: (id, data) => api.put(`/paluwagan/members/${id}`, data),
};

export const paymentApi = {
  getAll: () => api.get('/paluwagan/payments'),
  getByMember: (memberId) => api.get(`/paluwagan/payments/member/${memberId}`),
  markPaid: (id) => api.patch(`/paluwagan/payments/${id}/pay`),
  markUnpaid: (id) => api.patch(`/paluwagan/payments/${id}/unpay`),
};

export const receiptApi = {
  downloadPdf: (paymentId) =>
    api.get(`/receipts/${paymentId}/pdf`, { responseType: 'blob' }),
};

export const dashboardApi = {
  getSummary: () => api.get('/dashboard'),
};
