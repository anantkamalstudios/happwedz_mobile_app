import axiosInstance from "./axiosInstance";

const triggerBrowserDownload = (blob, filename) => {
  if (typeof window === "undefined") return;
  const objectUrl = window.URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = objectUrl;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  document.body.removeChild(anchor);
  window.URL.revokeObjectURL(objectUrl);
};

const enrichBlobError = async (error) => {
  const blob = error?.response?.data;
  if (!(blob instanceof Blob)) return error;
  try {
    const text = await blob.text();
    const parsed = JSON.parse(text);
    if (parsed?.error || parsed?.message) {
      error.response.data = parsed;
    }
  } catch (_) {
    // Ignore blob parsing failures and keep original error.
  }
  return error;
};

const getErrorMessage = (error, fallback) => {
  if (typeof error === "string" && error.trim()) return error;
  if (typeof error?.message === "string" && error.message.trim()) return error.message;
  if (typeof error?.response?.data?.message === "string" && error.response.data.message.trim()) {
    return error.response.data.message;
  }
  if (typeof error?.response?.data?.error === "string" && error.response.data.error.trim()) {
    return error.response.data.error;
  }
  return fallback;
};

export const suggestHotels = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/suggestions", payload);
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error fetching hotel suggestions"));
    throw error;
  }
};

export const fetchHotelCityRegions = async (params = {}, options = {}) => {
  try {
    const response = await axiosInstance.get("hotels/city-regions", {
      params,
      signal: options?.signal,
    });
    return response.data;
  } catch (error) {
    if (error?.response?.status === 404) {
      try {
        const fallback = await axiosInstance.post("hotels/city-regions", params, {
          signal: options?.signal,
        });
        return fallback.data;
      } catch (fallbackError) {
        console.error(getErrorMessage(fallbackError, "Error fetching hotel city regions"));
        throw fallbackError;
      }
    }
    console.error(getErrorMessage(error, "Error fetching hotel city regions"));
    throw error;
  }
};

export const fetchHotelCountries = async () => {
  try {
    const response = await axiosInstance.get("hotels/countries");
    return response.data;
  } catch (error) {
    // Hero / search UI should not break if TripJack catalog is temporarily failing.
    console.error(getErrorMessage(error, "Error fetching hotel countries"));

    // Safe fallback: minimal countries structure expected by UI.
    // TripJack/legacy UIs typically default nationality/countryOfResidence to "106" (India).
    return {
      success: false,
      countries: [
        { id: "106", code: "IN", name: "India" },
        { id: "0", code: "NA", name: "Other" },
      ],
      fallback: true,
    };
  }
};

export const fetchStaticHotelsSuggestions = async (params = {}, options = {}) => {
  try {
    const response = await axiosInstance.get("hotels/static-hotels/search", {
      params,
      signal: options?.signal,
    });
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error fetching static hotel suggestions"));
    throw error;
  }
};

export const searchHotels = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/search", payload);
    console.log("[TripJack Listing Raw /hotels/search response]", response.data);
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error searching hotels"));
    throw error;
  }
};

export const getHotelFilters = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/filters", payload);
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error fetching hotel filters"));
    throw error;
  }
};

export const getHotelDetail = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/detail", payload);
    console.log(
      "[TripJack Pricing Raw /hotels/detail response]",
      response?.data?.raw || response?.data,
    );
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error fetching hotel detail"));
    throw error;
  }
};

export const getHotelStaticContent = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/static-content", payload);
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error fetching hotel static content"));
    throw error;
  }
};

export const trackHotelAnalyticsEvent = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/analytics-event", payload);
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error tracking hotel analytics event"));
    throw error;
  }
};

export const trackTripjackAnalyticsEvent = async (payload) => {
  try {
    const response = await fetch("https://apitest.tripjack.com/xms/v1/analytics/events", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      throw new Error(`TripJack analytics request failed with status ${response.status}`);
    }

    return response;
  } catch (error) {
    try {
      const response = await axiosInstance.post("hotels/analytics-event", payload);
      return response.data;
    } catch (proxyError) {
      console.error(getErrorMessage(proxyError, "Error tracking TripJack analytics event"));
      throw proxyError;
    }
  }
};

export const reviewHotelBooking = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/review", payload);
    console.log("[TripJack Review Raw /hotels/review response]", response?.data);
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error reviewing hotel booking"));
    throw error;
  }
};

export const getHotelCancellationPolicy = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/cancellation-policy", payload);
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error fetching hotel cancellation policy"));
    throw error;
  }
};

export const bookHotel = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/book", payload);
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error creating hotel booking"));
    throw error;
  }
};

export const createHotelPaymentOrder = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/create-payment-order", payload);
    return response.data;
  } catch (error) {
    if (!error?.response?.data?.duplicateBookingBlocked) {
      console.error(getErrorMessage(error, "Error creating hotel payment order"));
    }
    throw error;
  }
};

export const verifyHotelPaymentAndBook = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/verify-payment-and-book", payload, {
      timeout: 30000,
    });
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error verifying hotel payment"));
    throw error;
  }
};

export const holdHotelBooking = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/hold", payload);
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error creating hotel hold booking"));
    throw error;
  }
};

export const confirmHotelBooking = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/confirm-book", payload);
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error confirming hotel booking"));
    throw error;
  }
};

export const getHotelBookingDetails = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/booking-details", payload);
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error fetching hotel booking details"));
    throw error;
  }
};

export const cancelHotelBooking = async (bookingId) => {
  try {
    const response = await axiosInstance.post(`hotels/cancel-booking/${bookingId}`);
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error cancelling hotel booking"));
    throw error;
  }
};

export const getRecentHotelBookings = async (payload) => {
  try {
    const response = await axiosInstance.post("hotels/recent-bookings", payload);
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error fetching recent hotel bookings"));
    throw error;
  }
};

export const getAllHotelBookings = async (params = {}) => {
  try {
    const response = await axiosInstance.get("hotels/all-bookings", { params });
    return response.data;
  } catch (error) {
    console.error(getErrorMessage(error, "Error fetching hotel bookings"));
    throw error;
  }
};

export const downloadHotelReceipt = async (bookingId) => {
  try {
    const response = await axiosInstance.get(`hotels/${bookingId}/receipt`, {
      responseType: "blob",
    });
    triggerBrowserDownload(response.data, `tripjack-receipt-${bookingId}.pdf`);
    return true;
  } catch (error) {
    await enrichBlobError(error);
    console.error(getErrorMessage(error, "Error downloading hotel receipt"));
    throw error;
  }
};

export const downloadHotelVoucher = async (bookingId) => {
  try {
    const response = await axiosInstance.get(`hotels/${bookingId}/voucher`, {
      responseType: "blob",
    });
    triggerBrowserDownload(response.data, `tripjack-voucher-${bookingId}.pdf`);
    return true;
  } catch (error) {
    await enrichBlobError(error);
    console.error(getErrorMessage(error, "Error downloading hotel voucher"));
    throw error;
  }
};
