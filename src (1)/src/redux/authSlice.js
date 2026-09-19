import { createSlice } from "@reduxjs/toolkit";
import { toast } from "react-toastify";
import {
  writeSsoCookies,
  clearSsoCookies,
  readHwCookie,
} from "../utils/ssoCookies";
import { API_BASE_URL } from "../config/constants";

// Initialize state from localStorage if available
const storedToken = typeof window !== "undefined" ? localStorage.getItem("token") : null;
const storedUser = typeof window !== "undefined" ? localStorage.getItem("user") : null;

/**
 * The session to start from.
 *
 * localStorage first, since that is where this app has always kept it. When it
 * is empty the shared cookie is consulted, which is what makes the store -> here
 * direction work: someone who signed in on store.happywedz.com arrives with no
 * localStorage for this origin but a valid `hwUserInfo` cookie, and is adopted
 * as logged in rather than being asked to sign in a second time.
 *
 * The adopted session is copied into localStorage so the rest of the app — which
 * reads `localStorage.getItem("token")` directly in several places — behaves
 * identically whichever door the user came through.
 */
const resolveInitialSession = () => {
  if (typeof window === "undefined") {
    return { user: null, token: null, isAuthenticated: false };
  }

  if (storedToken && storedUser) {
    return {
      user: JSON.parse(storedUser),
      token: storedToken,
      isAuthenticated: true,
    };
  }

  const shared = readHwCookie();

  if (shared?.token && shared?.id) {
    const user = {
      id: shared.id,
      name: shared.name,
      email: shared.email,
      role: shared.role,
    };

    localStorage.setItem("user", JSON.stringify(user));
    localStorage.setItem("token", shared.token);
    localStorage.setItem("tokenTimestamp", Date.now().toString());

    return { user, token: shared.token, isAuthenticated: true };
  }

  return { user: null, token: null, isAuthenticated: false };
};

const initialState = resolveInitialSession();

const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {
    setCredentials: (state, action) => {
      state.user = action.payload.user;
      state.token = action.payload.token;
      state.isAuthenticated = true;
      // Persist to localStorage
      if (typeof window !== "undefined") {
        localStorage.setItem("user", JSON.stringify(action.payload.user));
        localStorage.setItem("token", action.payload.token);
        localStorage.setItem("tokenTimestamp", Date.now().toString());

        // ...and mirror both sessions into the shared cookies, so the store
        // finds the user already signed in. `storeSession` comes straight from
        // the login response and is simply absent if the store was unreachable.
        writeSsoCookies(
          action.payload.user,
          action.payload.token,
          action.payload.storeSession
        );
      }
    },

    updateUserProfile: (state, action) => {
      if (state.user) {
        state.user = { ...state.user, ...action.payload };
        if (typeof window !== "undefined") {
          localStorage.setItem("user", JSON.stringify(state.user));
        }
      }
    },

    logout: (state) => {
      state.user = null;
      state.token = null;
      state.isAuthenticated = false;
      // Clear localStorage
      if (typeof window !== "undefined") {
        localStorage.removeItem("user");
        localStorage.removeItem("token");
        localStorage.removeItem("tokenTimestamp");

        // Signing out has to take the store with it. Leaving the cookies behind
        // would sign the user straight back in on the next page load, since
        // resolveInitialSession() adopts them.
        clearSsoCookies();
      }
    },
  },
});

export const { setCredentials, updateUserProfile, logout } = authSlice.actions;

export const loginUser = (payload) => (dispatch) => {
  dispatch(setCredentials(payload));
};

// Success is reported by the caller, right next to the heart that was pressed
// (see WishlistBubble). Only failures surface as a toast, since once the
// optimistic state has been rolled back there is nothing left to anchor to.
const WISHLIST_TOAST_ID = "wishlist-status";

const showWishlistError = (message) => {
  const options = { autoClose: 3000, toastId: WISHLIST_TOAST_ID };

  if (toast.isActive(WISHLIST_TOAST_ID)) {
    toast.update(WISHLIST_TOAST_ID, { render: message, ...options });
  } else {
    toast.error(message, options);
  }
};

export const toggleWishlist = (vendor) => async (dispatch, getState) => {
  const { auth } = getState();
  const { isAuthenticated, user } = auth;

  if (!isAuthenticated || !user) {
    // Loaded on demand: this slice is pulled in by the redux store on every page,
    // and a static sweetalert2 import made it part of the initial bundle.
    const { default: Swal } = await import("sweetalert2");
    Swal.fire({
      icon: "warning",
      text: "Please log in to add items to your wishlist.",
      confirmButtonText: "Login",
      showCancelButton: true,
      cancelButtonText: "Cancel",
    });
    window.location.href = `/customer-login?redirect=/vendors/${vendor.slug || vendor.id
      }`;
    return { success: false, requiresLogin: true };
  }

  // The backend resolves the owner from the token, and rejects the request
  // with a 401 when it is missing, so the header has to be sent explicitly.
  const token = auth.token || localStorage.getItem("token");
  const vendorServicesId = vendor?.vendor_services_id ?? vendor?.id;

  if (!vendorServicesId) {
    console.error("toggleWishlist: missing vendor service id", vendor);
    return { success: false };
  }

  try {
    const response = await fetch(`${API_BASE_URL}/wishlist/toggle`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      credentials: "include",
      body: JSON.stringify({
        vendor_services_id: vendorServicesId,
      }),
    });

    const result = await response.json().catch(() => ({}));

    if (!response.ok || !result.success) {
      console.error(
        "Failed to toggle wishlist:",
        result.message || response.status
      );
      showWishlistError(result.message || "Could not update your wishlist.");
      return { success: false, message: result.message };
    }

    // The toggle endpoint only returns `data` when the item was added.
    return { success: true, added: !!result.data };
  } catch (error) {
    console.error("Error toggling wishlist:", error);
    showWishlistError("Could not update your wishlist. Please try again.");
    return { success: false };
  }
};

export default authSlice.reducer;
