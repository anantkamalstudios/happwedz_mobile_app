// import axios from "axios";

// // Read from env, default to production API. Ensure exactly one trailing slash.
// const RAW_API_BASE =
//   import.meta?.env?.VITE_API_URL || "https://happywedz.com/api";
// const API_BASE_URL = `${RAW_API_BASE.replace(/\/+$/, "")}/`;

// const getAuthHeader = (token) =>
//   token ? { Authorization: `Bearer ${token}` } : {};

// export const createWebsite = async (formData, token) => {
//   try {
//     const res = await axios.post(
//       `${API_BASE_URL}weddingwebsite/wedding-websites`,
//       formData,
//       {
//         headers: {
//           ...getAuthHeader(token),
//           "Content-Type": "multipart/form-data",
//         },
//       }
//     );
//     return res.data;
//   } catch (err) {
//     console.error(
//       "❌ Error creating wedding website:",
//       err.response?.data || err.message
//     );
//     throw new Error(
//       `Failed to create website: ${JSON.stringify(
//         err.response?.data || err.message
//       )}`
//     );
//   }
// };

// export const getMyWebsites = async (token) => {
//   try {
//     const res = await axios.get(
//       `${API_BASE_URL}weddingwebsite/wedding-websites`,
//       {
//         headers: getAuthHeader(token),
//       }
//     );
//     return res.data;
//   } catch (err) {
//     console.error(
//       "❌ Error fetching websites:",
//       err.response?.data || err.message
//     );
//     throw err;
//   }
// };

// export const getWebsiteById = async (id, token) => {
//   try {
//     const res = await axios.get(
//       `${API_BASE_URL}weddingwebsite/wedding-websites/${id}`,
//       {
//         headers: getAuthHeader(token),
//       }
//     );
//     return res.data;
//   } catch (err) {
//     console.error(
//       "❌ Error fetching website:",
//       err.response?.data || err.message
//     );
//     throw err;
//   }
// };

// export const updateWebsite = async (id, formData, token) => {
//   try {
//     const res = await axios.put(
//       `${API_BASE_URL}weddingwebsite/wedding-websites/${id}`,
//       formData,
//       {
//         headers: {
//           ...getAuthHeader(token),
//           "Content-Type": "multipart/form-data",
//         },
//       }
//     );
//     return res.data;
//   } catch (err) {
//     console.error(
//       "❌ Error updating website:",
//       err.response?.data || err.message
//     );
//     throw new Error(
//       `Failed to update website: ${JSON.stringify(
//         err.response?.data || err.message
//       )}`
//     );
//   }
// };

// export const deleteWebsite = async (id, token) => {
//   try {
//     const res = await axios.delete(
//       `${API_BASE_URL}weddingwebsite/wedding-websites/${id}`,
//       {
//         headers: getAuthHeader(token),
//       }
//     );
//     return res.data;
//   } catch (err) {
//     console.error(
//       "❌ Error deleting website:",
//       err.response?.data || err.message
//     );
//     throw err;
//   }
// };

// export const publishWebsite = async (id, token) => {
//   try {
//     const res = await axios.post(
//       `${API_BASE_URL}weddingwebsite/wedding-websites/${id}/publish`,
//       {},
//       {
//         headers: getAuthHeader(token),
//       }
//     );
//     return res.data;
//   } catch (err) {
//     console.error(
//       "❌ Error publishing website:",
//       err.response?.data || err.message
//     );
//     throw err;
//   }
// };

// export const viewPublicWebsite = async (websiteUrl, token) => {
//   try {
//     const res = await axios.get(
//       `${API_BASE_URL}weddingwebsite/wedding/${websiteUrl}`,
//       {
//         headers: getAuthHeader(token),
//       }
//     );
//     return res.data;
//   } catch (err) {
//     console.error(
//       "❌ Error loading public website:",
//       err.response?.data || err.message
//     );
//     throw err;
//   }
// };

// export const weddingWebsiteApi = {
//   createWebsite,
//   getMyWebsites,
//   getWebsiteById,
//   updateWebsite,
//   deleteWebsite,
//   publishWebsite,
//   viewPublicWebsite,
// };

import axios from "axios";

// Read from env, default to production API. Ensure exactly one trailing slash.
const RAW_API_BASE =
  import.meta?.env?.VITE_API_URL || "https://happywedz.com/api";
const API_BASE_URL = `${RAW_API_BASE.replace(/\/+$/, "")}/`;

const getAuthHeader = (token) =>
  token ? { Authorization: `Bearer ${token}` } : {};

export const createWebsite = async (formData, token) => {
  try {
    const res = await axios.post(
      `${API_BASE_URL}weddingwebsite/wedding-websites`,
      formData,
      {
        headers: {
          ...getAuthHeader(token),
          "Content-Type": "multipart/form-data",
        },
      }
    );
    return res.data;
  } catch (err) {
    console.error(
      "❌ Error creating wedding website:",
      err.response?.data || err.message
    );
    throw new Error(
      `Failed to create website: ${JSON.stringify(
        err.response?.data || err.message
      )}`
    );
  }
};

export const getMyWebsites = async (token) => {
  try {
    const res = await axios.get(
      `${API_BASE_URL}weddingwebsite/wedding-websites`,
      {
        headers: getAuthHeader(token),
      }
    );
    return res.data;
  } catch (err) {
    console.error(
      "❌ Error fetching websites:",
      err.response?.data || err.message
    );
    throw err;
  }
};

export const getWebsiteById = async (id, token) => {
  try {
    const res = await axios.get(
      `${API_BASE_URL}weddingwebsite/wedding-websites/${id}`,
      {
        headers: getAuthHeader(token),
      }
    );
    return res.data;
  } catch (err) {
    console.error(
      "❌ Error fetching website:",
      err.response?.data || err.message
    );
    throw err;
  }
};

export const updateWebsite = async (id, formData, token) => {
  try {
    const res = await axios.put(
      `${API_BASE_URL}weddingwebsite/wedding-websites/${id}`,
      formData,
      {
        headers: {
          ...getAuthHeader(token),
          "Content-Type": "multipart/form-data",
        },
      }
    );
    return res.data;
  } catch (err) {
    console.error(
      "❌ Error updating website:",
      err.response?.data || err.message
    );
    throw new Error(
      `Failed to update website: ${JSON.stringify(
        err.response?.data || err.message
      )}`
    );
  }
};

export const deleteWebsite = async (id, token) => {
  try {
    const res = await axios.delete(
      `${API_BASE_URL}weddingwebsite/wedding-websites/${id}`,
      {
        headers: getAuthHeader(token),
      }
    );
    return res.data;
  } catch (err) {
    console.error(
      "❌ Error deleting website:",
      err.response?.data || err.message
    );
    throw err;
  }
};

export const publishWebsite = async (id, token) => {
  try {
    const res = await axios.post(
      `${API_BASE_URL}weddingwebsite/wedding-websites/${id}/publish`,
      {},
      {
        headers: getAuthHeader(token),
      }
    );
    return res.data;
  } catch (err) {
    console.error(
      "❌ Error publishing website:",
      err.response?.data || err.message
    );
    throw err;
  }
};

// ✅ PUBLIC VIEW - No authentication required
export const viewPublicWebsite = async (websiteUrl) => {
  try {
    const res = await axios.get(
      `${API_BASE_URL}weddingwebsite/wedding/${websiteUrl}`
    );
    return res.data;
  } catch (err) {
    console.error(
      "❌ Error loading public website:",
      err.response?.data || err.message
    );
    throw err;
  }
};

// ✅ Get shareable public URL for a website
export const getPublicUrl = (websiteUrl) => {
  // This will be your frontend public route
  return `${window.location.origin}/wedding/${websiteUrl}`;
};

export const weddingWebsiteApi = {
  createWebsite,
  getMyWebsites,
  getWebsiteById,
  updateWebsite,
  deleteWebsite,
  publishWebsite,
  viewPublicWebsite,
  getPublicUrl,
};
