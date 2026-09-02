import { createSlice } from "@reduxjs/toolkit";
import { logout } from "./authSlice";

// Fallback to 1 hour if the backend does not provide an expiry in the token.
const DEFAULT_VENDOR_TOKEN_EXPIRATION_MS = 60 * 60 * 1000;

const decodeTokenExpiry = (token) => {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;

    const payload = JSON.parse(
      decodeURIComponent(
        atob(parts[1].replace(/-/g, "+").replace(/_/g, "/"))
          .split("")
          .map((c) => "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2))
          .join("")
      )
    );

    if (!payload?.exp) return null;
    return payload.exp * 1000; // exp is in seconds
  } catch {
    return null;
  }
};

const getVendorTokenExpiry = () => {
  if (typeof localStorage === "undefined") return null;
  const expiry = localStorage.getItem("vendorTokenExpiry");
  return expiry ? parseInt(expiry, 10) : null;
};

export const isVendorTokenExpired = () => {
  const expiry = getVendorTokenExpiry();
  if (!expiry) return true;
  return Date.now() >= expiry;
};

let persistedVendor = null;
let persistedToken = null;
try {
  const vendorStr =
    typeof localStorage !== "undefined" ? localStorage.getItem("vendor") : null;
  const vendorToken =
    typeof localStorage !== "undefined"
      ? localStorage.getItem("vendorToken")
      : null;

  const expiry = getVendorTokenExpiry();
  const hasValidToken = vendorToken && expiry && Date.now() < expiry;

  persistedVendor = hasValidToken && vendorStr ? JSON.parse(vendorStr) : null;
  persistedToken = hasValidToken ? vendorToken : null;

  if (!hasValidToken) {
    localStorage.removeItem("vendor");
    localStorage.removeItem("vendorToken");
    localStorage.removeItem("vendorTokenExpiry");
  }
} catch {
  persistedVendor = null;
  persistedToken = null;
}

const initialState = {
  vendor: persistedVendor,
  token: persistedToken,
};

const vendorAuthSlice = createSlice({
  name: "vendorAuth",
  initialState,
  reducers: {
    setVendorCredentials: (state, action) => {
      state.vendor = action.payload.vendor;
      state.token = action.payload.token;

      const fromToken =
        action.payload.token && decodeTokenExpiry(action.payload.token);
      const expiresAt =
        fromToken || Date.now() + DEFAULT_VENDOR_TOKEN_EXPIRATION_MS;

      localStorage.setItem("vendor", JSON.stringify(action.payload.vendor));
      localStorage.setItem("vendorToken", action.payload.token);
      localStorage.setItem("vendorTokenExpiry", expiresAt.toString());
    },
    vendorLogout: (state) => {
      state.vendor = null;
      state.token = null;
      localStorage.removeItem("vendor");
      localStorage.removeItem("vendorToken");
      localStorage.removeItem("vendorTokenExpiry");
    },
    setVendor: (state, action) => {
      state.vendor = action.payload;
      localStorage.setItem("vendor", JSON.stringify(action.payload));
    },
  },
});

export const { setVendorCredentials, vendorLogout, setVendor } =
  vendorAuthSlice.actions;
export const loginVendor = (payload) => (dispatch) => {
  dispatch(setVendorCredentials(payload));
};
export default vendorAuthSlice.reducer;
