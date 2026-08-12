import React, { useState, useEffect } from "react";
import { Link, useNavigate, useLocation } from "react-router-dom";
import { Form, Button } from "react-bootstrap";
import { useDispatch } from "react-redux";
import { loginVendor, setVendorCredentials } from "../../redux/vendorAuthSlice";
import vendorsAuthApi from "../../services/api/vendorAuthApi";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import { FaEye, FaEyeSlash } from "react-icons/fa";
import { SiMinutemailer } from "react-icons/si";
import { TbPassword } from "react-icons/tb";

const VendorLogin = () => {
  const persistVendorSession = (vendorData, tokenValue) => {
    const expiry = Date.now() + 60 * 60 * 1000;
    localStorage.setItem("vendor", JSON.stringify(vendorData));
    localStorage.setItem("vendorToken", tokenValue);
    localStorage.setItem("vendorTokenExpiry", expiry.toString());
  };

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [rememberMe, setRememberMe] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const navigate = useNavigate();
  const location = useLocation();
  const dispatch = useDispatch();
  const [showPassword, setShowPassword] = useState(false);
  const [sessionMessage, setSessionMessage] = useState("");

  useEffect(() => {
    const params = new URLSearchParams(location.search);
    if (params.get("session") === "expired") {
      setSessionMessage("Your session expired. Please log in again.");
    }
  }, [location.search]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    // Show toast if fields are empty
    if (!email || !password) {
      toast.error("Please fill in both email and password fields.");
      setLoading(false);
      return;
    }
    setLoading(true);
    try {
      const data = await vendorsAuthApi.login({ email, password });

      if (!data) {
        throw new Error("Login failed");
      }

      const token = data?.data?.token || data?.token || data?.accessToken;
      const vendor = data?.data?.vendor || data?.vendor || data?.user;

      if (!token || !vendor) {
        throw new Error("Invalid response from server");
      }

      persistVendorSession(vendor, token);
      dispatch(loginVendor({ token, vendor }));

      navigate("/vendor-dashboard/vendor-home", { replace: true });
    } catch (err) {
      const serverMsg =
        err.response?.data?.message ||
        err.message ||
        "Wrong email or password.";
      toast.error(serverMsg);
      setError(serverMsg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="wedding-login-container min-vh-100 d-flex align-items-center justify-content-center">
      <ToastContainer position="top-center" autoClose={3000} />
      <div
        className="row w-100 shadow-lg rounded-4 overflow-hidden"
        style={{ maxWidth: "1100px" }}
      >
        {/* Left Image Section */}
        <div className="col-lg-6 d-none d-lg-block p-0 position-relative">
          <div className="wedding-image-overlay position-absolute w-100 h-100"></div>
          <div className="position-absolute top-0 start-0 w-100 h-100 d-flex flex-column justify-content-center align-items-center text-white p-5">
            <h2
              className="display-4 fw-light mb-4"
              style={{ fontFamily: "'Playfair Display', serif" }}
            >
              Create Your <span className="gold-text">Dream Wedding</span>
            </h2>
            <div className="divider mx-auto my-4"></div>
            <p className="lead text-center">
              "The best thing to hold onto in life is each other. Plan your
              perfect day with us."
            </p>
            {/* <div className="floral-divider my-5"></div> */}
          </div>
        </div>

        {/* Right Form Section */}
        <div className="col-lg-6 bg-white p-4 p-md-5 d-flex flex-column justify-content-center">
          <div className="text-center mb-4">
            <h3 className="fw-light mb-2" style={{ color: "#8a5a76" }}>
              Welcome to <span className="gold-text">HappyWedz</span>
            </h3>
            <p className="text-muted fs-16">
              Sign in to access your wedding planning dashboard
            </p>
            {sessionMessage && (
              <div className="alert alert-warning py-2 mt-3" role="alert">
                {sessionMessage}
              </div>
            )}
          </div>

          <Form onSubmit={handleSubmit} className="mt-1">
            <Form.Group controlId="formEmail" className="mb-4">
              <Form.Label className="text-secondary fs-16">
                Email Address
              </Form.Label>
              <div className="position-relative">
                {/* <SiMinutemailer
                  size={20}
                  className="text-secondary"
                  style={{
                    position: "absolute",
                    left: "16px",
                    top: "50%",
                    transform: "translateY(-50%)",
                    pointerEvents: "none",
                  }}
                /> */}
                <Form.Control
                  type="email"
                  placeholder="Enter your email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="p-3  fs-14 shadow-sm border-light bg-light"
                  style={{ borderRadius: "12px" }}
                />
              </div>
            </Form.Group>

            <Form.Group controlId="formPassword" className="mb-4">
              <Form.Label className="text-secondary fs-16">Password</Form.Label>
              <div className="position-relative">
                {/* <TbPassword
                  size={22}
                  className="text-secondary"
                  style={{
                    position: "absolute",
                    left: "16px",
                    top: "50%",
                    transform: "translateY(-50%)",
                    pointerEvents: "none",
                  }}
                /> */}
                <Form.Control
                  type={showPassword ? "text" : "password"}
                  placeholder="Enter your password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="p-3  fs-14 shadow-sm border-light bg-light"
                  style={{
                    borderRadius: "12px",
                    paddingRight: "3rem",
                    position: "relative",
                    zIndex: 1,
                  }}
                />
                <span
                  onClick={() => setShowPassword(!showPassword)}
                  style={{
                    position: "absolute",
                    right: "16px",
                    top: "50%",
                    transform: "translateY(-50%)",
                    cursor: "pointer",
                    color: "#6c757d",
                    zIndex: 100,
                    pointerEvents: "auto",
                    touchAction: "manipulation",
                  }}
                  aria-label={showPassword ? "Hide password" : "Show password"}
                  role="button"
                >
                  {showPassword ? (
                    <FaEye size={20} />
                  ) : (
                    <FaEyeSlash size={20} />
                  )}
                </span>
              </div>
            </Form.Group>

            <div className="d-flex justify-content-between align-items-center mb-4 fs-14">
              <div className="d-flex align-items-center">
                <Form.Check
                  type="checkbox"
                  id="rememberMe"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="text-secondary fs-16 me-2 mb-0"
                  style={{ minHeight: "1.3em" }}
                />
                <label
                  htmlFor="rememberMe"
                  className="fs-16 mb-0"
                  style={{ cursor: "pointer" }}
                >
                  Remember me
                </label>
              </div>
              <Link
                className="text-decoration-none wedding-link fs-14"
                to="/vendor-forgot-password"
              >
                Forgot Password?
              </Link>
            </div>

            {error && (
              <div className="alert alert-danger py-2" role="alert">
                {error}
              </div>
            )}

            <Button
              variant="primary"
              type="submit"
              className="w-100 p-3 login-btn fs-16"
              disabled={loading}
            >
              {loading ? "Signing in..." : "Sign In"}
            </Button>

            <div className="d-flex justify-content-between align-items-center text-center mb-4 fs-14 mt-3">
              <p className="text-muted fs-14">
                Don't have an account?{" "}
                <Link
                  to="/vendor-register"
                  className="text-decoration-none wedding-link fw-semibold fs-14"
                >
                  Sign up
                </Link>
              </p>
              <p className="text-muted fs-14">
                Are you a user?{" "}
                <Link
                  to="/customer-login"
                  className="text-decoration-none wedding-link fw-semibold fs-14"
                >
                  Log in
                </Link>
              </p>
            </div>
          </Form>
        </div>
      </div>

      <div className="floral-decoration bottom-right">
        <div className="floral-svg"></div>
      </div>
    </div>
  );
};

export default VendorLogin;
