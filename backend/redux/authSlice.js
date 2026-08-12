import { createSlice } from "@reduxjs/toolkit";

// Initialize state from localStorage if available
const storedToken = typeof window !== "undefined" ? localStorage.getItem("token") : null;
const storedUser = typeof window !== "undefined" ? localStorage.getItem("user") : null;

const initialState = {
  user: storedUser ? JSON.parse(storedUser) : null,
  token: storedToken || null,
  isAuthenticated: !!(storedToken && storedUser),
};

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
      }
    },
  },
});

export const { setCredentials, logout } = authSlice.actions;

export const loginUser = (payload) => (dispatch) => {
  dispatch(setCredentials(payload));
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
    return;
  }

  try {
    const response = await fetch("https://happywedz.com/api/wishlist/toggle", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify({
        user_id: user.id,
        vendor_services_id: vendor.id,
      }),
    });

    if (!response.ok) {
      console.error("Failed to toggle wishlist");
    }
  } catch (error) {
    console.error("Error toggling wishlist:", error);
  }
};

export default authSlice.reducer;
