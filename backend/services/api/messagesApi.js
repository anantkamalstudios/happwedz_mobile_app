import axiosInstance from "./axiosInstance";

const BASE = "/messages/user";

const messagesApi = {
  getConversations: async () => {
    const res = await axiosInstance.get(`${BASE}/conversations`);
    return res.data;
  },

  createConversation: async (payload) => {
    const res = await axiosInstance.post(`${BASE}/conversations`, payload);
    return res.data;
  },

  getMessages: async (conversationId, params = {}) => {
    const res = await axiosInstance.get(
      `${BASE}/conversations/${conversationId}/messages`,
      { params }
    );
    return res.data;
  },

  sendMessage: async (conversationId, payload) => {
    const body =
      typeof payload === "string" ? { message: payload } : payload || {};
    const res = await axiosInstance.post(
      `${BASE}/conversations/${conversationId}/messages`,
      body
    );
    return res.data;
  },
};

export default messagesApi;
