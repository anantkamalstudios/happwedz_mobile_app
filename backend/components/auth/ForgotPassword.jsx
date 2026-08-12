import React, { useState } from "react";
import { FiMail, FiLock, FiCheck, FiArrowLeft, FiLoader, FiEye, FiEyeOff } from "react-icons/fi";
import { Link, useNavigate } from "react-router-dom";
import Swal from "sweetalert2";

const ForgotPassword = () => {
  const [activeStep, setActiveStep] = useState("forgotPassword");
  const [email, setEmail] = useState("");
  const [otp, setOtp] = useState(["", "", "", "", "", ""]);
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [storedOtp, setStoredOtp] = useState(""); // store backend OTP for testing
  const navigate = useNavigate();
  const [passwordError, setPasswordError] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);




  const isStrongPassword = (password) => {
    const strongPasswordRegex =
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    return strongPasswordRegex.test(password);
  };

  // ---------------- SEND OTP ----------------
  const handleEmailSubmit = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage("");

    try {
      const res = await fetch(
        "https://happywedz.com/api/user/forgot-password",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email }),
        }
      );

      const data = await res.json();

      if (!res.ok) throw new Error(data.message || "Failed to send OTP");

      // store OTP for testing if backend returns it (remove in production)
      if (data.otp) setStoredOtp(data.otp);

      setMessage(data.message || `OTP sent to ${email}`);
      setActiveStep("otpVerification");
    } catch (err) {
      setMessage(err.message);
      Swal.fire({
        icon: "error",
        title: "Oops...",
        text: err.message || "Failed to send OTP",
        confirmButtonColor: "#C31162",
      });
    } finally {
      setIsLoading(false);
    }
  };

  // ---------------- RESET PASSWORD ----------------
  // const handleOtpSubmit = async (e) => {
  //   e.preventDefault();
  //   setIsLoading(true);
  //   setMessage("");

  //   if (newPassword !== confirmPassword) {
  //     setMessage("Passwords do not match");
  //     setIsLoading(false);
  //     return;
  //   }

  //   try {
  //     const res = await fetch("https://happywedz.com/api/user/reset-password", {
  //       method: "POST",
  //       headers: { "Content-Type": "application/json" },
  //       body: JSON.stringify({
  //         email,
  //         otp: otp.join(""),
  //         newPassword,
  //       }),
  //     });

  //     const data = await res.json();

  //     if (!res.ok) throw new Error(data.message || "Failed to reset password");

  //     setMessage(data.message || "Password reset successful");
  //     // setActiveStep("success");
  //     navigate("/customer-login");
  //   } catch (err) {
  //     setMessage(err.message);
  //   } finally {
  //     setIsLoading(false);
  //   }
  // };

  const handleOtpSubmit = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage("");
    setPasswordError("");

    if (!isStrongPassword(newPassword)) {
      setPasswordError(
        "Password must be at least 8 characters and include uppercase, lowercase, number, and special character."
      );
      setIsLoading(false);
      return;
    }

    if (newPassword !== confirmPassword) {
      setPasswordError("Passwords do not match");
      setIsLoading(false);
      return;
    }

    try {
      const res = await fetch("https://happywedz.com/api/user/reset-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email,
          otp: otp.join(""),
          newPassword,
        }),
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.message || "Failed to reset password");

      setMessage(data.message || "Password reset successful");
      Swal.fire({
        icon: "success",
        title: "Success!",
        text: data.message || "Password reset successful",
        confirmButtonColor: "#C31162",
      }).then(() => {
        navigate("/customer-login");
      });
    } catch (err) {
      const errorMsg = err.message || "Failed to reset password";
      setMessage(errorMsg);
      setPasswordError(errorMsg);
      Swal.fire({
        icon: "error",
        title: "Oops...",
        text: errorMsg,
        confirmButtonColor: "#C31162",
      });
    } finally {
      setIsLoading(false);
    }
  };


  // ---------------- HANDLE OTP INPUT ----------------
  const handleOtpChange = (index, value) => {
    if (/^\d*$/.test(value) && value.length <= 1) {
      const newOtp = [...otp];
      newOtp[index] = value;
      setOtp(newOtp);

      if (value && index < 5) {
        document.getElementById(`weddingwire-otp-${index + 1}`).focus();
      }
    }
  };

  // ---------------- RESEND OTP ----------------
  const resendOtp = async () => {
    setIsLoading(true);
    setMessage("");
    try {
      const res = await fetch(
        "https://happywedz.com/api/user/forgot-password",
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email }),
        }
      );
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || "Failed to resend OTP");
      if (data.otp) setStoredOtp(data.otp);
      setMessage(data.message || "OTP resent successfully");
    } catch (err) {
      setMessage(err.message);
      Swal.fire({
        icon: "error",
        title: "Oops...",
        text: err.message || "Failed to resend OTP",
        confirmButtonColor: "#C31162",
      });
    } finally {
      setIsLoading(false);
    }
  };

  // ---------------- JSX ----------------
  return (
    <div className="weddingwire-auth-container">
      <div className="weddingwire-auth-card">
        <div className="weddingwire-auth-header">
          <p className="weddingwire-auth-tagline">
            Your perfect wedding starts here
          </p>
        </div>

        {activeStep === "forgotPassword" && (
          <div className="weddingwire-auth-form-container">
            <h2 className="weddingwire-auth-title">Reset Your Password</h2>
            <p className="weddingwire-auth-subtitle">
              Enter your email to receive a password reset link
            </p>

            {message && (
              <div className="alert alert-danger py-2 px-3 small mb-3" role="alert">
                {message}
              </div>
            )}

            <form
              onSubmit={handleEmailSubmit}
              className="weddingwire-auth-form"
            >
              <div className="weddingwire-auth-input-group">
                <label
                  htmlFor="weddingwire-email"
                  className="weddingwire-auth-label"
                >
                  Email Address
                </label>
                <div className="weddingwire-auth-input-wrapper">
                  <FiMail className="weddingwire-auth-input-icon" />
                  <input
                    type="email"
                    id="weddingwire-email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="weddingwire-auth-input"
                    placeholder="your.email@example.com"
                    required
                  />
                </div>
              </div>

              <button
                type="submit"
                className="weddingwire-auth-button weddingwire-auth-button-primary"
                disabled={isLoading}
              >
                {isLoading ? (
                  <span className="weddingwire-auth-button-loading">
                    <FiLoader className="weddingwire-auth-spinner" />
                    Sending...
                  </span>
                ) : (
                  "Send Reset OTP"
                )}
              </button>
            </form>

            <div className="weddingwire-auth-footer">
              Remember your password?{" "}
              <Link to="/customer-login" className="weddingwire-auth-link">
                Log In
              </Link>
            </div>
          </div>
        )}

        {activeStep === "otpVerification" && (
          <div className="weddingwire-auth-form-container">
            <h2 className="weddingwire-auth-title">Verify Your Account</h2>
            <p className="weddingwire-auth-subtitle">
              We've sent a 6-digit code to {email}
            </p>

            {message && !passwordError && (
              <div className="alert alert-success py-2 px-3 small mb-3" role="alert">
                <FiCheck className="me-1" /> {message}
              </div>
            )}
            {passwordError && (
              <div className="alert alert-danger py-2 px-3 small mb-3" role="alert">
                {passwordError}
              </div>
            )}

            <form onSubmit={handleOtpSubmit} className="weddingwire-auth-form">
              <div className="weddingwire-auth-input-group">
                <label className="weddingwire-auth-label">
                  Verification Code
                </label>
                <div className="weddingwire-auth-otp-container">
                  {otp.map((digit, index) => (
                    <input
                      key={index}
                      id={`weddingwire-otp-${index}`}
                      type="text"
                      maxLength="1"
                      value={digit}
                      onChange={(e) => handleOtpChange(index, e.target.value)}
                      className="weddingwire-auth-otp-input"
                      required
                    />
                  ))}
                </div>
                <button
                  type="button"
                  className="weddingwire-auth-resend"
                  onClick={resendOtp}
                  disabled={isLoading}
                >
                  {isLoading ? "Sending..." : "Resend Code"}
                </button>
              </div>

              <div className="weddingwire-auth-input-group">
                <label
                  htmlFor="weddingwire-password"
                  className="weddingwire-auth-label"
                >
                  New Password
                </label>
                <div className="weddingwire-auth-input-wrapper" style={{ position: "relative", display: "flex", alignItems: "center" }}>
                  <FiLock className="weddingwire-auth-input-icon" />
                  <input
                    type={showPassword ? "text" : "password"}
                    id="weddingwire-password"
                    value={newPassword}
                    onChange={(e) => {
                      setNewPassword(e.target.value);
                      setPasswordError("");
                    }}
                    className="weddingwire-auth-input"
                    placeholder="Enter new password"
                    required
                    minLength="8"
                    style={{ paddingRight: "40px" }}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="weddingwire-auth-password-toggle"
                    style={{
                      position: "absolute",
                      right: "8px",
                      background: "none",
                      border: "none",
                      padding: "0",
                      cursor: "pointer",
                      color: "#6c757d",
                      display: "flex",
                      alignItems: "center",
                      zIndex: 10,
                    }}
                  >
                    {showPassword ? <FiEye size={18} /> : <FiEyeOff size={18} />}
                  </button>
                </div>
                {passwordError && (
                  <p className="text-danger small mt-1 mb-0" style={{ fontSize: "0.875rem" }}>
                    {passwordError}
                  </p>
                )}
                <ul className="text-muted small mt-2 mb-0" style={{ fontSize: "0.75rem", listStyle: "none", paddingLeft: "0" }}>
                  <li>• Minimum 8 characters</li>
                  <li>• At least 1 uppercase letter</li>
                  <li>• At least 1 lowercase letter</li>
                  <li>• At least 1 number</li>
                  <li>• At least 1 special character (@$!%*?&)</li>
                </ul>
              </div>

              <div className="weddingwire-auth-input-group">
                <label
                  htmlFor="weddingwire-confirm-password"
                  className="weddingwire-auth-label"
                >
                  Confirm New Password
                </label>
                <div className="weddingwire-auth-input-wrapper" style={{ position: "relative", display: "flex", alignItems: "center" }}>
                  <FiLock className="weddingwire-auth-input-icon" />
                  <input
                    type={showConfirmPassword ? "text" : "password"}
                    id="weddingwire-confirm-password"
                    value={confirmPassword}
                    onChange={(e) => {
                      setConfirmPassword(e.target.value);
                      if (passwordError && newPassword === e.target.value) {
                        setPasswordError("");
                      }
                    }}
                    className="weddingwire-auth-input"
                    placeholder="Confirm your new password"
                    required
                    minLength="8"
                    style={{ paddingRight: "40px" }}
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    className="weddingwire-auth-password-toggle"
                    style={{
                      position: "absolute",
                      right: "8px",
                      background: "none",
                      border: "none",
                      padding: "0",
                      cursor: "pointer",
                      color: "#6c757d",
                      display: "flex",
                      alignItems: "center",
                      zIndex: 10,
                    }}
                  >
                    {showConfirmPassword ? <FiEye size={18} /> : <FiEyeOff size={18} />}
                  </button>
                </div>
              </div>

              <button
                type="submit"
                className="weddingwire-auth-button weddingwire-auth-button-primary"
                disabled={isLoading}
              >
                {isLoading ? (
                  <span className="weddingwire-auth-button-loading">
                    <FiLoader className="weddingwire-auth-spinner" />
                    Resetting...
                  </span>
                ) : (
                  "Reset Password"
                )}
              </button>
            </form>

            <div className="weddingwire-auth-footer">
              <a
                href="#"
                className="weddingwire-auth-link"
                onClick={() => setActiveStep("forgotPassword")}
              >
                <FiArrowLeft className="weddingwire-auth-link-icon" /> Back to
                Email
              </a>
            </div>
          </div>
        )}

        {activeStep === "success" && (
          <div className="weddingwire-auth-success-container">
            <div className="weddingwire-auth-success-icon">
              <FiCheck />
            </div>
            <h2 className="weddingwire-auth-title">Password Changed!</h2>
            <p className="weddingwire-auth-subtitle">
              Your password has been reset successfully
            </p>
            <div className="weddingwire-auth-success-message">
              <FiCheck className="weddingwire-auth-message-icon" /> {message}
            </div>
            <button
              className="weddingwire-auth-button weddingwire-auth-button-primary"
              onClick={() => {
                setActiveStep("forgotPassword");
                setEmail("");
                setOtp(["", "", "", "", "", ""]);
                setNewPassword("");
                setConfirmPassword("");
              }}
            >
              Back to Login
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default ForgotPassword;
