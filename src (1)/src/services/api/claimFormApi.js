import axios from "axios";

const BASE_URL = "https://happywedz.com/api";

export const fetchVendorServiceDetails = async (vendorServiceId) => {
  try {
    const response = await axios.get(
      `${BASE_URL}/vendor-services/${vendorServiceId}`
    );
    return {
      success: true,
      data: response.data,
    };
  } catch (error) {
    console.error("Error fetching vendor service details:", error);
    return {
      success: false,
      error: error.response?.data?.message || "Failed to fetch vendor details",
    };
  }
};

export const submitBusinessClaim = async (formData) => {
  try {
    const response = await axios.post(`${BASE_URL}/business/claims`, formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    });
    return {
      success: true,
      data: response.data,
    };
  } catch (error) {
    console.error("Error submitting business claim:", error);
    return {
      success: false,
      error:
        error.response?.data?.message ||
        "Failed to submit claim. Please try again.",
    };
  }
};
