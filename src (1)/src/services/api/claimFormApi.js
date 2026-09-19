import axios from "axios";
import { API_BASE_URL as BASE_URL } from "../../config/constants";

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

export const submitBusinessClaim = async (payload) => {
  try {
    // JSON, not multipart: the claim form no longer carries documents. Leaving the
    // multipart header on would send a JSON body the server parses as an empty form.
    const response = await axios.post(`${BASE_URL}/business/claims`, payload, {
      headers: {
        "Content-Type": "application/json",
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
