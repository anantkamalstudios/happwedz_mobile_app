// // src/services/api/userApi.js
// import axios from "axios";

// const BASE_URL = "https://happywedz.com/api/user";

// export const userApi = {
//     register: async (data) => {
//         try {
//             const response = await axios.post(`${BASE_URL}/register`, data);
//             return response.data;
//         } catch (error) {
//             return { success: false, message: error.response?.data?.message || error.message };
//         }
//     },
//     login: async (data) => {
//         try {
//             const response = await axios.post(`${BASE_URL}/login`, data);
//             return response.data;
//         } catch (error) {
//             return { success: false, message: error.response?.data?.message || error.message };
//         }
//     },
// };

// import { useState, useCallback } from "react";
// import { useDispatch } from "react-redux";
// import { setAuth, logout as logoutAction } from "../../store/authSlice";
// import { userApi } from "../../hooks/useUser";

// export const useUser = () => {
//     const dispatch = useDispatch();
//     const [loading, setLoading] = useState(false);
//     const [error, setError] = useState(null);

//     // ✅ Register user
//     const register = useCallback(async (formData) => {
//         setLoading(true);
//         setError(null);
//         try {
//             const payload = {
//                 name: formData.name,
//                 email: formData.email,
//                 password: formData.password,
//                 phone: formData.phone,
//                 role: "user",
//                 weddingVenue: formData.event_location,
//                 country: formData.country,
//                 city: formData.city || "",
//                 weddingDate: formData.event_date,
//                 profile_image: formData.profile_image || "",
//                 coverImage: formData.coverImage || "",
//                 captchaToken: formData.captchaToken || "test-captcha-token",
//             };
//             const response = await userApi.register(payload);
//             return response;
//         } catch (err) {
//             setError(err.message || "Registration error");
//             return { success: false, message: err.message };
//         } finally {
//             setLoading(false);
//         }
//     }, []);

//     // ✅ Login user
//     const login = useCallback(async (formData, rememberMe = false) => {
//         setLoading(true);
//         setError(null);
//         try {
//             const payload = {
//                 email: formData.email,
//                 password: formData.password,
//                 captchaToken: formData.captchaToken || "test-captcha-token",
//             };
//             const response = await userApi.login(payload);

//             if (response.success && response.data) {
//                 const { user, token } = response.data;

//                 // ✅ Store in Redux
//                 dispatch(setAuth({ token, user }));

//                 // ✅ Persist in localStorage if "Remember Me"
//                 if (rememberMe) {
//                     localStorage.setItem("token", token);
//                     localStorage.setItem("user", JSON.stringify(user));
//                 }

//                 return { success: true, user, token };
//             } else {
//                 setError(response.message || "Login failed");
//                 return { success: false, message: response.message };
//             }
//         } catch (err) {
//             setError(err.message || "Login error");
//             return { success: false, message: err.message };
//         } finally {
//             setLoading(false);
//         }
//     }, [dispatch]);

//     // ✅ Logout user
//     const logout = useCallback(() => {
//         dispatch(logoutAction());
//         localStorage.removeItem("token");
//         localStorage.removeItem("user");
//     }, [dispatch]);

//     return { loading, error, register, login, logout };
// };

import axiosInstance from "./axiosInstance";

const userApi = {
  register: async (data) => {
    try {
      const res = await axiosInstance.post("/user/register", data);
      return res.data;
    } catch (err) {
      return (
        err.response?.data || { success: false, message: "Registration failed" }
      );
    }
  },

  login: async (data) => {
    try {
      const res = await axiosInstance.post("/user/login", data);
      return res.data;
    } catch (err) {
      return err.response?.data || { success: false, message: "Login failed" };
    }
  },
  googleAuth: async (data) => {
    try {
      const res = await axiosInstance.post("/user/google-auth", data);
      return res.data;
    } catch (err) {
      return (
        err.response?.data || { success: false, message: "Google auth failed" }
      );
    }
  },
};

export default userApi;
