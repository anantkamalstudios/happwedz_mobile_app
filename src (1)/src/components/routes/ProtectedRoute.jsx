import React, { useEffect } from "react";
import { useSelector, useDispatch } from "react-redux";
import { Navigate, useLocation } from "react-router-dom";
import { logout } from "../../redux/authSlice";
import {
  isVendorTokenExpired,
  vendorLogout,
} from "../../redux/vendorAuthSlice";

const ProtectedRoute = ({ children, redirectTo = "/customer-login" }) => {
  const { user, isAuthenticated } = useSelector((state) => state.auth);
  const { vendor, token: vendorToken } = useSelector(
    (state) => state.vendorAuth
  );
  const dispatch = useDispatch();
  const location = useLocation();

  useEffect(() => {
    if (vendorToken && isVendorTokenExpired()) {
      dispatch(vendorLogout());
    }
  }, [vendorToken, dispatch]);

  const hasUserSession = Boolean(user && isAuthenticated);
  const hasVendorSession = Boolean(
    vendor && vendorToken && !isVendorTokenExpired()
  );

  if (!hasUserSession && !hasVendorSession) {
    return <Navigate to={redirectTo} replace state={{ from: location }} />;
  }

  return children;
};

export default ProtectedRoute;
