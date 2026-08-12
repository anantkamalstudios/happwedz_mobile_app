import { useState, useCallback } from "react";
import { useDispatch } from "react-redux";
import { setCredentials, logout as logoutAction } from "../redux/authSlice";
import axiosInstance from "../services/api/axiosInstance";

export const useUser = () => {
  const dispatch = useDispatch();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const login = useCallback(
    async (formData, rememberMe = false) => {
      setLoading(true);
      setError(null);

      try {
        const { data } = await axiosInstance.post("/user/login", formData);

        if (data.success && data.user && data.token) {
          const { user, token } = data;
          dispatch(setCredentials({ user, token }));

          if (rememberMe) {
            localStorage.setItem("user", JSON.stringify(user));
            localStorage.setItem("token", token);
          }

          return { success: true, user, token };
        } else {
          const msg = data.message || "Login failed";
          setError(msg);
          return { success: false, message: msg };
        }
      } catch (err) {
        const msg = err.response?.data?.message || err.message || "Login error";
        setError(msg);
        return { success: false, message: msg };
      } finally {
        setLoading(false);
      }
    },
    [dispatch]
  );

  const logout = useCallback(() => {
    dispatch(logoutAction());
    localStorage.removeItem("user");
    localStorage.removeItem("token");
    localStorage.removeItem("tokenTimestamp");
    axiosInstance.post("/auth/logout").catch(() => {
      /* best-effort */
    });
  }, [dispatch]);

  return { login, logout, loading, error };
};
