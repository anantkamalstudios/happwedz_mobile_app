import { useSelector } from "react-redux";
import { Navigate, useLocation } from "react-router-dom";

const UserPrivateRoute = ({ children }) => {
  const user = useSelector((state) => state.auth.user);
  const isAuthenticated = useSelector((state) => state.auth.isAuthenticated);
  const location = useLocation();

  if (!user || !isAuthenticated) {
    return <Navigate to="/customer-login" replace state={{ from: location }} />;
  }

  return children;
};

export default UserPrivateRoute;
