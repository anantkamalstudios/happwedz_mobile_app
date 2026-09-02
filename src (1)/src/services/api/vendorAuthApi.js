import axiosInstance from "./axiosInstance";

const API_BASE = "/vendor";

export const vendorsApi = {
  getVendors: (params) =>
    axiosInstance.get(`${API_BASE}/list`, { params }).then((res) => res.data),
  getVendorById: (id) =>
    axiosInstance.get(`${API_BASE}/${id}`).then((res) => res.data),
  createVendor: (data) =>
    axiosInstance.post(`${API_BASE}/create`, data).then((res) => res.data),
  updateVendor: (id, data) => {
    const config = {};
    if (typeof FormData !== "undefined" && data instanceof FormData) {
      config.headers = {
        "Content-Type": "multipart/form-data",
      };
    }
    return axiosInstance
      .put(`${API_BASE}/${id}`, data, config)
      .then((res) => res.data);
  },
  deleteVendor: (id) =>
    axiosInstance.delete(`${API_BASE}/${id}`).then((res) => res.data),
};

export const vendorsAuthApi = {
  register: (payload) =>
    axiosInstance.post(`${API_BASE}/register`, payload).then((res) => res.data),
  login: (payload) =>
    axiosInstance.post(`${API_BASE}/login`, payload).then((res) => res.data),
  changePassword: (payload, token) =>
    axiosInstance
      .post(`${API_BASE}/change-password`, payload, {
        headers: {
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
          "Content-Type": "application/json",
        },
      })
      .then((res) => res.data),
};

export default vendorsAuthApi;
