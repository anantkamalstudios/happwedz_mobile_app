import axios from "axios";

// Use a dedicated client that always sends vendor JWT from localStorage
const client = axios.create({
  baseURL: import.meta.env.VITE_API_URL || "https://happywedz.com/api",
  headers: { "Content-Type": "application/json" },
});

client.interceptors.request.use((config) => {
  const vendorToken = localStorage.getItem("vendorToken");
  if (vendorToken) {
    config.headers.Authorization = `Bearer ${vendorToken}`;
  }
  return config;
});

const BASE = "/messages/vendor";

const vendorMessagesApi = {
  getConversations: async () => {
    const res = await client.get(`${BASE}/conversations`);
    return res.data;
  },
  getMessages: async (conversationId, params = {}) => {
    const res = await client.get(
      `${BASE}/conversations/${conversationId}/messages`,
      { params }
    );
    return res.data;
  },
  sendMessage: async (conversationId, payload) => {
    const body =
      typeof payload === "string" ? { message: payload } : payload || {};
    const res = await client.post(
      `${BASE}/conversations/${conversationId}/messages`,
      body
    );
    return res.data;
  },
};

export default vendorMessagesApi;
