import React, { useState, useEffect, useMemo, useCallback } from "react";
import { Link, useNavigate, useLocation } from "react-router-dom";
import { isInternalPath } from "../../utils/bookingDraft";
import { Form, Button } from "react-bootstrap";
import { useDispatch, useSelector } from "react-redux";
import { loginUser } from "../../redux/authSlice";
import { GoogleLogin } from "@react-oauth/google";
import GoogleAuthProvider from "./GoogleAuthProvider";
import { toast, ToastContainer } from "react-toastify";
import { useLoader } from "../context/LoaderContext";
import userApi from "../../services/api/userApi";
import "react-toastify/dist/ReactToastify.css";
import { FaEye, FaEyeSlash } from "react-icons/fa";

// Reasons a flow can hand to /customer-login?reason=... so the page can say why.
const LOGIN_REASON_MESSAGES = {
  booking: "Log in to complete your hotel booking. Your details have been saved.",
  hold: "Log in to hold this room. Your details have been saved.",
  cab: "Log in to complete your cab booking.",
};

const CustomerLoginForm = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [rememberMe, setRememberMe] = useState(false);
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [sessionMessage, setSessionMessage] = useState("");

  const navigate = useNavigate();
  const location = useLocation();
  const dispatch = useDispatch();
  const { showLoader, hideLoader } = useLoader();

  // Check if user is already authenticated
  const { isAuthenticated } = useSelector((state) => state.auth);

  // Where to go after signing in. `state.from` is the whole location object,
  // so forwarding its `state` below carries history state — the hotel search
  // payload and response live there — back to the page. The `redirect` query
  // param is the fallback for when that state is gone: a hard reload here, or
  // the login page opened in a new tab.
  const returnTarget = useMemo(() => {
    const raw = location.state?.from;

    if (raw && typeof raw === "object" && raw.pathname) {
      return {
        to: {
          pathname: raw.pathname,
          search: raw.search || "",
          hash: raw.hash || "",
        },
        state: raw.state,
      };
    }

    if (isInternalPath(raw)) return { to: raw, state: undefined };

    const redirect = new URLSearchParams(location.search).get("redirect");
    if (isInternalPath(redirect)) return { to: redirect, state: undefined };

    return { to: "/", state: undefined };
  }, [location.state, location.search]);

  const goToReturnTarget = useCallback(() => {
    navigate(returnTarget.to, { replace: true, state: returnTarget.state });
  }, [navigate, returnTarget]);
  const [loginCms, setLoginCms] = useState(null);
  const normalizeUrl = (u) =>
    typeof u === "string" ? u.replace(/`/g, "").trim() : null;

  // Redirect authenticated users away from login page
  useEffect(() => {
    if (isAuthenticated) {
      goToReturnTarget();
    }
  }, [isAuthenticated, goToReturnTarget]);

  const persistUserSession = (user, token) => {
    localStorage.setItem("user", JSON.stringify(user));
    localStorage.setItem("token", token);
    localStorage.setItem("tokenTimestamp", Date.now().toString());
  };

  useEffect(() => {
    (async () => {
      try {
        const res = await fetch("https://happywedz.com/api/login-cms");
        const data = await res.json();
        setLoginCms(data?.data || data || null);
      } catch (err) {
        console.error("Error fetching login CMS:", err);
        setLoginCms(null);
      } finally {
        hideLoader();
      }
    })();
  }, []);

  useEffect(() => {
    const params = new URLSearchParams(location.search);
    if (params.get("session") === "expired") {
      setSessionMessage("Your session expired. Please log in again.");
      return;
    }
    const reason = params.get("reason");
    if (reason && LOGIN_REASON_MESSAGES[reason]) {
      setSessionMessage(LOGIN_REASON_MESSAGES[reason]);
    }
  }, [location.search]);

  const handleGoogleCredential = async (credentialResponse) => {
    try {
      showLoader();
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
        persistUserSession(authResponse.user, authResponse.token);
        dispatch(
          loginUser({ user: authResponse.user, token: authResponse.token }),
        );
        toast.success("Login successful!");
        goToReturnTarget();
        return;
      }

      const msg = authResponse?.message || "Google login failed on server";
      toast.error(msg);
    } catch (err) {
      console.error("Google credential error:", err);
      toast.error("Google login failed: " + (err.message || ""));
    } finally {
      hideLoader();
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!email || !password) {
      toast.error("Please fill in both email and password fields.");
      return;
    }

    try {
      setLoading(true);

      const payload = {
        email,
        password,
        captchaToken: "test-captcha-token",
      };

      const response = await userApi.login(payload);

      if (response.success) {
        persistUserSession(response.user, response.token);
        dispatch(loginUser({ user: response.user, token: response.token }));
        toast.success("Login successful!");
        goToReturnTarget();
      } else {
        const msg = response.message || "Login failed";

        if (
          msg.toLowerCase().includes("invalid") ||
          msg.toLowerCase().includes("wrong")
        ) {
          toast.error(
            "Invalid credentials. Please check your email and password.",
          );
        } else if (
          msg.toLowerCase().includes("already exists") ||
          msg.toLowerCase().includes("email already")
        ) {
          toast.error("Email already exists. Please use a different email.");
        } else {
          toast.error(msg);
        }
      }
    } catch {
      toast.error("An error occurred. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container min-vh-100 d-flex align-items-center justify-content-center my-5">
      <ToastContainer position="top-center" autoClose={3000} />
      <div className="row w-100 shadow-lg rounded-4 overflow-hidden">
        <div
          className="col-lg-6 d-none d-lg-block p-0 position-relative"
          style={{
            ...(loginCms?.image
              ? {
                  backgroundImage: `url(${normalizeUrl(loginCms?.image)})`,
                  backgroundSize: "cover",
                  backgroundPosition: "center",
                  minHeight: "600px",
                }
              : {}),
          }}
        >
          <div className="wedding-image-overlay position-absolute w-100 h-100"></div>
          <div className="position-absolute top-0 start-0 w-100 h-100 d-flex flex-column justify-content-center align-items-center text-white p-5">
            <h2
              className="display-4 fw-light mb-4"
              style={{ fontFamily: "'Playfair Display', serif" }}
            >
              {loginCms?.heading ? (
                loginCms.heading
              ) : (
                <>
                  Create Your <span className="gold-text">Dream Wedding</span>
                </>
              )}
            </h2>
            <div className="divider mx-auto my-4"></div>
            <p className="lead text-center">
              {loginCms?.subheading ||
                "The best thing to hold onto in life is each other. Plan your perfect day with us."}
            </p>
          </div>
        </div>

        <div className="col-lg-6 bg-white p-4 p-md-5 d-flex flex-column justify-content-center">
          <div className="text-center mb-4">
            <h3 className="mb-2" style={{ color: "#8a5a76" }}>
              {loginCms?.title ? (
                loginCms.title
              ) : (
                <>
                  Welcome to{" "}
                  <span className="primary-text fw-bold">HappyWedz</span>
                </>
              )}
            </h3>
            <p className="text-muted fs-14">
              {loginCms?.description ||
                "Sign in to access your wedding planning dashboard"}
            </p>
            {sessionMessage && (
              <div className="alert alert-warning py-2 mt-3" role="alert">
                {sessionMessage}
              </div>
            )}
          </div>

          <Form onSubmit={handleSubmit} className="mt-4">
            <Form.Group controlId="formEmail" className="mb-4">
              <Form.Label className="text-secondary fs-16">
                Email Address
              </Form.Label>
              <Form.Control
                type="email"
                placeholder="Enter your email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="p-3 fs-14"
                required
              />
            </Form.Group>

            <Form.Group
              controlId="formPassword"
              className="mb-4 position-relative"
            >
              <Form.Label className="text-secondary fs-16">Password</Form.Label>

              <Form.Control
                type={showPassword ? "text" : "password"}
                placeholder="Enter your password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="p-3 fs-14"
                style={{
                  paddingRight: "2.75rem",
                  position: "relative",
                  zIndex: 1,
                }}
                required
              />

              {/* Eye Icon inside input */}
              <span
                onClick={() => setShowPassword(!showPassword)}
                style={{
                  position: "absolute",
                  right: "15px",
                  top: "65%",
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
                {showPassword ? <FaEye size={20} /> : <FaEyeSlash size={20} />}
              </span>
            </Form.Group>

            <div className="d-flex justify-content-between align-items-center text-center mb-4 fs-14">
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
                to="/user-forgot-password"
              >
                Forgot Password?
              </Link>
            </div>

            <Button
              variant="primary"
              type="submit"
              className="w-100 p-3 login-btn fs-16"
              disabled={loading}
            >
              {loading ? "Signing In..." : "Sign In"}
            </Button>
          </Form>

          <div className="mt-4 justify-content-center align-items-center fs-14">
            <GoogleLogin
              onSuccess={handleGoogleCredential}
              onError={() => {
                console.error("Google Login Failed: onError");
                toast.error("Google login failed. Please try again.");
              }}
            />
          </div>

          <div className="d-flex justify-content-between align-items-center text-center mb-4 fs-14 mt-3">
            <p className="text-muted fs-14">
              Don't have an account?{" "}
              <Link
                to="/customer-register"
                className="text-decoration-none wedding-link fw-semibold"
              >
                Sign up
              </Link>
            </p>
            <p className="text-muted fs-14">
              I am a{" "}
              <Link
                to="/vendor-login"
                className="text-decoration-none fw-semibold wedding-link"
              >
                vendor
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

// The Google Identity script is pulled in here rather than at the app root, so
// visitors who never open a login screen never download or execute it.
const CustomerLogin = () => (
  <GoogleAuthProvider>
    <CustomerLoginForm />
  </GoogleAuthProvider>
);

export default CustomerLogin;
