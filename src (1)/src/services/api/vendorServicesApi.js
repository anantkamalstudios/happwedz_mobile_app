import axios from "axios";

const API_BASE_URL = "https://happywedz.com/api";
// const API_BASE_URL = "http://localhost:4000";

const vendorServicesApi = {
  getVendorServiceById: async (id) => {
    try {
      const response = await axios.get(`${API_BASE_URL}/vendor-services/${id}`);

      return response.data;
    } catch (error) {
      console.error(
        "Error fetching vendor service:",
        error.response?.data || error.message,
      );
      throw error.response?.data || new Error("API request failed");
    }
  },
  getAuthHeaders: (token) => {
    const authToken =
      token ||
      (typeof localStorage !== "undefined"
        ? localStorage.getItem("vendorToken")
        : null);
    return authToken ? { Authorization: `Bearer ${authToken}` } : {};
  },

  getVendorServiceByVendorId: async (vendorId, token) => {
    try {
      const response = await axios.get(
        `${API_BASE_URL}/vendor-services/vendor/${vendorId}`,
        {
          headers: {
            ...vendorServicesApi.getAuthHeaders(token),
          },
          withCredentials: true,
        }
      );
      return response.data;
    } catch (error) {
      // It's common for a new vendor to not have a service page yet (404)
      if (error.response?.status === 404) {
        return null;
      }
      throw error.response?.data || new Error("API request failed");
    }
  },
  // Get service ID directly from vendor login ID
  getServiceIdByVendorId: async (vendorId, token) => {
    try {
      const response = await axios.get(
        `${API_BASE_URL}/vendor-services/vendor/${vendorId}`,
        {
          headers: {
            ...vendorServicesApi.getAuthHeaders(token),
          },
          withCredentials: true,
        }
      );
      // Extract just the ID from the response
      if (response.data && Array.isArray(response.data)) {
        return response.data[0]?.id || null;
      } else if (response.data && response.data.id) {
        return response.data.id;
      }
      return null;
    } catch (error) {
      // It's common for a new vendor to not have a service page yet (404)
      if (error.response?.status === 404) {
        return null;
      }
      console.error("Error fetching service ID:", error);
      return null;
    }
  },
  createOrUpdateService: async (serviceData, token, id = null) => {
    try {
      let url = `${API_BASE_URL}/vendor-services`;
      let method = "post";
      if (id) {
        url = `${API_BASE_URL}/vendor-services/${id}`;
        method = "put";
      }
      const response = await axios({
        method,
        url,
        data: serviceData,
        headers: {
          "Content-Type": "multipart/form-data",
          ...vendorServicesApi.getAuthHeaders(token),
        },
        withCredentials: true,
      });
      return response.data;
    } catch (error) {
      console.error(
        "Error creating/updating vendor service:",
        error.response?.data || error.message,
      );
      const errData = error.response?.data;
      const errMsg =
        (typeof errData === "string" && errData) ||
        errData?.error ||
        errData?.message ||
        error.message ||
        "API request failed";
      const wrapped = new Error(errMsg);
      wrapped.status = error.response?.status;
      wrapped.data = errData;
      throw wrapped;
    }
  },
};

export default vendorServicesApi;
