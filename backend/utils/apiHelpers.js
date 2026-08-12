import store from "../redux/store";
import { logout } from "../redux/authSlice";
import { vendorLogout } from "../redux/vendorAuthSlice";
import { toast } from "react-toastify";

export const authenticatedFetch = async (url, options = {}) => {
  const token = localStorage.getItem("token");
  const vendorToken = localStorage.getItem("vendorToken");

  const headers = {
    "Content-Type": "application/json",
    ...options.headers,
  };

  if (token) {
    headers.Authorization = `Bearer ${token}`;
  } else if (vendorToken) {
    headers.Authorization = `Bearer ${vendorToken}`;
  }

  try {
    const response = await fetch(url, {
      ...options,
      headers,
    });

    if (response.status === 401) {
      if (token) {
        store.dispatch(logout());
        toast.error("Your session has expired. Please login again.");

        if (window.location.pathname !== "/customer-login") {
          window.location.href = "/customer-login";
        }
      } else if (vendorToken) {
        store.dispatch(vendorLogout());
        toast.error("Your session has expired. Please login again.");

        if (window.location.pathname !== "/vendor-login") {
          window.location.href = "/vendor-login";
        }
      }
    }

    return response;
  } catch (error) {
    throw error;
  }
};
