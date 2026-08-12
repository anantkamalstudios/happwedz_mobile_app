import { useSelector } from "react-redux";
import { Navigate } from "react-router-dom";

const VendorPrivateRoute = ({ children }) => {
  const vendor = useSelector((state) => state.vendorAuth.vendor);
  return vendor ? children : <Navigate to="/vendor-login" replace />;
};

export default VendorPrivateRoute;
