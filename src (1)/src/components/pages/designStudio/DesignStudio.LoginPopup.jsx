import React, { useState } from "react";
import { useDispatch } from "react-redux";
import { loginUser } from "../../../redux/authSlice";
import { GoogleLogin } from "@react-oauth/google";
import { toast, ToastContainer } from "react-toastify";
import userApi from "../../../services/api/userApi";
import { useGoogleLogin } from "@react-oauth/google";
import GoogleAuthProvider from "../../auth/GoogleAuthProvider";
import axios from "axios";
import "react-toastify/dist/ReactToastify.css";
import { IoClose } from "react-icons/io5";
import { FaRegEyeSlash } from "react-icons/fa";
import { MdOutlineRemoveRedEye } from "react-icons/md";
import { Link } from "react-router-dom";

function LoginPopupContent({ isOpen, onClose, onSuccess }) {
  const [showPassword, setShowPassword] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [rememberMe, setRememberMe] = useState(false);
  const [loading, setLoading] = useState(false);

  const dispatch = useDispatch();

  const handleSubmit = async () => {
    if (!email || !password) {
      toast.error("Please fill in both email and password fields.");
      return;
    }

    try {
      setLoading(true);
      const payload = { email, password, captchaToken: "test-captcha-token" };
      const response = await userApi.login(payload);

      if (response.success) {
        dispatch(loginUser({ user: response.user, token: response.token }));
        toast.success("Login successful!");
        onClose();
        onSuccess?.();
      } else {
        toast.error(response.message || "Login failed");
      }
    } catch (err) {
      toast.error("An error occurred. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleCredential = async (credentialResponse) => {
    try {
      setLoading(true);
      const tokenId = credentialResponse?.credential;
      if (!tokenId) {
        toast.error("Google did not return an ID token (credential).");
        return;
      }

      const authResponse = await userApi.googleAuth({ tokenId });
      if (
        authResponse &&
        authResponse.success &&
        authResponse.user &&
        authResponse.token
      ) {
        dispatch(
          loginUser({ user: authResponse.user, token: authResponse.token })
        );
        toast.success("Login successful!");
        onClose();
        onSuccess?.();
        return;
      }

      toast.error(authResponse?.message || "Google login failed on server");
    } catch (err) {
      console.error("DesignStudio Google login error:", err);
      toast.error("Google login failed: " + (err.message || ""));
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <>
      <ToastContainer position="top-center" autoClose={3000} />
      <div
        style={{
          position: "fixed",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: "rgba(0,0,0,0.8)",
          display: "flex",
          justifyContent: "center",
          alignItems: "flex-start",
          zIndex: 1050,
          paddingTop: "0",
        }}
        onClick={onClose}
      >
        <div
          className="modal-dialog modal-dialog-centered"
          style={{
            maxWidth: "500px",
            width: "100%",
            margin: 0,
            background: "#fff",
          }}
          onClick={(e) => e.stopPropagation()}
        >
          <div
            className="modal-content"
            style={{
              border: "none",
              borderRadius: "12px",
              boxShadow: "0 10px 40px rgba(0,0,0,0.2)",
              animation: "slideIn 0.3s ease-out",
              height: "600px",
              width: "500px",
            }}
          >
            <div className="modal-body p-4" style={{ padding: "40px 35px" }}>
              <button
                type="button"
                onClick={onClose}
                style={{
                  position: "absolute",
                  top: "10px",
                  right: "20px",
                  fontSize: "24px",
                  opacity: 1,
                  color: "#C31162",
                  border: "none",
                  background: "none",
                }}
              >
                <IoClose />
              </button>

              <div>
                <h2
                  className="text-center mb-2 mt-4"
                  style={{ fontSize: "32px", fontWeight: "400", color: "#333" }}
                >
                  Login
                </h2>
                <p style={{ textAlign: "center", color: "gray" }}>
                  Don't have an account?{" "}
                  <Link
                    to="/customer-register"
                    style={{ color: "#C31162", fontWeight: "600" }}
                  >
                    Sign Up
                  </Link>{" "}
                </p>
              </div>

              {/* Email */}
              {/* <div className="mb-3">
                <label className="form-label">Email or Mobile</label>
                <input
                  type="text"
                  className="form-control custom-input"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  style={{
                    padding: "14px 16px",
                    fontSize: "15px",
                    background: "#fff",
                    borderRadius: "8px",
                  }}
                />
              </div> */}

              {/* Password */}
              {/* <div className="mb-3">
                <label className="form-label">Password</label>
                <div style={{ position: "relative" }}>
                  <input
                    type={showPassword ? "text" : "password"}
                    className="form-control custom-input"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    style={{
                      padding: "14px 16px",
                      paddingRight: "45px",
                      fontSize: "15px",
                      borderRadius: "8px",
                    }}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    style={{
                      position: "absolute",
                      right: "16px",
                      top: "50%",
                      transform: "translateY(-50%)",
                      background: "none",
                      border: "none",
                      cursor: "pointer",
                    }}
                  >
                    {showPassword ? "Hide" : "Show"}
                  </button>
                </div>
              </div> */}

              <style>
                {`
    .custom-input {
      width: 100%;
      background-color: #fff;
      border: 1px solid #ddd;
      border-radius: 8px;
      padding: 14px 16px;
      font-size: 15px;
      outline: none;
      transition: border-color 0.2s, box-shadow 0.2s;
    }

    .custom-input:focus {
      border-color: #d81b60;
      box-shadow: 0 0 0 0.2rem rgba(216, 27, 96, 0.15);
    }
  `}
              </style>

              <div className="mb-3">
                <label className="form-label">Email or Mobile</label>
                <input
                  type="text"
                  className="custom-input"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
              </div>

              {/* Password */}
              <div className="mb-3">
                <label className="form-label">Password</label>
                <div style={{ position: "relative" }}>
                  <input
                    type={showPassword ? "text" : "password"}
                    className="custom-input"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    style={{ paddingRight: "48px" }}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    style={{
                      position: "absolute",
                      right: "16px",
                      top: "50%",
                      transform: "translateY(-50%)",
                      background: "none",
                      border: "none",
                      cursor: "pointer",
                      fontWeight: "600",
                      color: "#555",
                      zIndex: 9999,
                      pointerEvents: "auto",
                    }}
                    aria-label={
                      showPassword ? "Hide password" : "Show password"
                    }
                  >
                    {!showPassword ? (
                      <FaRegEyeSlash />
                    ) : (
                      <MdOutlineRemoveRedEye />
                    )}
                  </button>
                </div>
              </div>

              {/* Remember Me */}
              <div className="d-flex justify-content-between align-items-center mb-3">
                <div className="form-check">
                  <input
                    type="checkbox"
                    className="form-check-input"
                    id="rememberMe"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                  />
                  <label className="form-check-label" htmlFor="rememberMe">
                    Remember me
                  </label>
                </div>
                <Link to="/user-forgot-password" style={{ color: "#d81b60" }}>
                  Forgot Password?
                </Link>
              </div>

              <button
                type="button"
                className="btn w-100 mb-3"
                onClick={handleSubmit}
                disabled={loading}
                style={{
                  background: "linear-gradient(135deg,#d81b60 0%,#c2185b 100%)",
                  color: "#fff",
                  padding: "14px",
                  borderRadius: "8px",
                }}
              >
                {loading ? "Signing In..." : "Log In"}
              </button>

              <div
                style={{
                  position: "relative",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  margin: "1rem 0",
                }}
              >
                {/* Horizontal line */}
                <div
                  style={{
                    position: "absolute",
                    top: "50%",
                    left: 0,
                    right: 0,
                    height: "1px",
                    backgroundColor: "#ccc",
                    transform: "translateY(-50%)",
                    zIndex: 0,
                  }}
                ></div>

                {/* "Or" text */}
                <span
                  style={{
                    background: "#fff",
                    padding: "0 15px",
                    position: "relative",
                    zIndex: 1,
                    fontWeight: "500",
                    color: "#555",
                  }}
                >
                  OR
                </span>
              </div>

              <div style={{ textAlign: "center", marginTop: "0.5rem" }}>
                <GoogleLogin
                  onSuccess={handleGoogleCredential}
                  onError={() => {
                    console.error("Google Login Failed: onError");
                    toast.error("Google login failed. Please try again.");
                  }}
                />
              </div>
            </div>
          </div>
        </div>

        <style>{`
          @keyframes slideIn {
            from { opacity:0; transform: translateY(-20px); }
            to { opacity:1; transform: translateY(0); }
          }
        `}</style>
      </div>
    </>
  );
}

// Gate on `isOpen` out here so GoogleAuthProvider — and with it the Google
// Identity script — only mounts once the popup is actually opened.
export default function LoginPopup({ isOpen, onClose, onSuccess }) {
  if (!isOpen) return null;

  return (
    <GoogleAuthProvider>
      <LoginPopupContent
        isOpen={isOpen}
        onClose={onClose}
        onSuccess={onSuccess}
      />
    </GoogleAuthProvider>
  );
}
