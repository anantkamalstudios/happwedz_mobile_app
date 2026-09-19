import { createSlice } from "@reduxjs/toolkit";

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

import {
  safeSetItem,
  safeGetItem,
  safeRemoveItem,
  sanitizeForStorage,
} from "../utils/safeStorage";

const getVendorTokenExpiry = () => {
  const expiry = safeGetItem("vendorTokenExpiry");
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
  const vendorStr = safeGetItem("vendor");
  const vendorToken = safeGetItem("vendorToken");

  const expiry = getVendorTokenExpiry();
  const hasValidToken = vendorToken && expiry && Date.now() < expiry;

  persistedVendor = hasValidToken && vendorStr ? JSON.parse(vendorStr) : null;
  persistedToken = hasValidToken ? vendorToken : null;

  if (!hasValidToken) {
    safeRemoveItem("vendor");
    safeRemoveItem("vendorToken");
    safeRemoveItem("vendorTokenExpiry");
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

      const cleanVendor = sanitizeForStorage(action.payload.vendor);
      safeSetItem("vendor", JSON.stringify(cleanVendor));
      safeSetItem("vendorToken", action.payload.token);
      safeSetItem("vendorTokenExpiry", expiresAt.toString());
    },
    vendorLogout: (state) => {
      state.vendor = null;
      state.token = null;
      safeRemoveItem("vendor");
      safeRemoveItem("vendorToken");
      safeRemoveItem("vendorTokenExpiry");
    },
    setVendor: (state, action) => {
      state.vendor = action.payload;
      const cleanVendor = sanitizeForStorage(action.payload);
      safeSetItem("vendor", JSON.stringify(cleanVendor));
    },
  },
});

export const { setVendorCredentials, vendorLogout, setVendor } =
  vendorAuthSlice.actions;
export const loginVendor = (payload) => (dispatch) => {
  dispatch(setVendorCredentials(payload));
};
export default vendorAuthSlice.reducer;
