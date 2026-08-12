import React, { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import axios from "axios";
import { useDispatch } from "react-redux";
import { useSelector } from "react-redux";
import { setCredentials } from "../../redux/authSlice";
import axiosInstance from "../../services/api/axiosInstance";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import { FaEye, FaEyeSlash } from "react-icons/fa";

const CustomerRegister = () => {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    password: "",
    phone: "",
    weddingVenue: "",
    country: "",
    city: "",
    weddingDate: "",
    profile_image: "",
    coverImage: "",
    captchaToken: "test-captcha-token",
  });

  const dispatch = useDispatch();
  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [countries, setCountries] = useState([]);
  const [cities, setCities] = useState([]);
  const navigate = useNavigate();
  const [passwordVisible, setPasswordVisible] = useState(false);
  const auth = useSelector((state) => state.auth);
  const [signInCms, setSignInCms] = useState(null);
  const normalizeUrl = (u) =>
    typeof u === "string" ? u.replace(/`/g, "").trim() : null;
  const persistUserSession = (user, token) => {
    localStorage.setItem("user", JSON.stringify(user));
    localStorage.setItem("token", token);
    localStorage.setItem("tokenTimestamp", Date.now().toString());
  };

  // Redirect authenticated users away from register page
  useEffect(() => {
    if (auth?.isAuthenticated) {
      navigate("/", { replace: true });
    }
  }, [auth?.isAuthenticated, navigate]);

  useEffect(() => {
    (async () => {
      try {
        const res = await fetch("https://happywedz.com/api/sign-in-cms");
        const data = await res.json();
        setSignInCms(data?.data || data || null);
      } catch (err) {
        console.error("Error fetching sign-in CMS:", err);
        setSignInCms(null);
      } finally {
        hideLoader();
      }
    })();
  }, []);

  useEffect(() => {
    axios
      .get("https://restcountries.com/v3.1/all?fields=name,cca2")
      .then((res) => {
        const sorted = res.data
          .map((c) => ({
            name: c.name.common,
            code: c.cca2,
          }))
          .sort((a, b) => a.name.localeCompare(b.name));
        setCountries(sorted);
      });
  }, []);

  useEffect(() => {
    if (!formData.country) return;
    axios
      .post("https://countriesnow.space/api/v0.1/countries/cities", {
        country: formData.country,
      })
      .then((res) => {
        if (res.data && res.data.data) {
          setCities(res.data.data);
        } else {
          setCities([]);
        }
      })
      .catch(() => setCities([]));
  }, [formData.country]);

  const validateField = (name, value) => {
    let error = "";

    switch (name) {
      case "name":
        const nameRegex =
          /^([A-Za-z]{3,16})([ ]{0,1})([A-Za-z]{3,16})?([ ]{0,1})?([A-Za-z]{3,16})?([ ]{0,1})?([A-Za-z]{3,16})$/;
        if (!value.trim()) {
          error = "Full name is required";
        } else if (!nameRegex.test(value)) {
          error = "Name must contain 3-16 letters per word, spaces allowed";
        }
        break;

      case "email":
        const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
        if (!value.trim()) {
          error = "Email is required";
        } else if (!emailRegex.test(value)) {
          error = "Please enter a valid email address";
        }
        break;

      case "password":
        const passwordRegex =
          /^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$/;
        if (!value) {
          error = "Password is required";
        } else if (!passwordRegex.test(value)) {
          error =
            "Password must be 8+ chars with uppercase, lowercase, special character and number";
        }
        break;

      case "phone":
        if (!value.trim()) {
          error = "Phone number is required";
        } else if (!/^\d{10}$/.test(value)) {
          error = "Phone number must be exactly 10 digits";
        }
        break;

      case "weddingVenue":
        if (!value.trim()) {
          error = "Wedding venue is required";
        }
        break;

      case "country":
        if (!value) {
          error = "Country is required";
        }
        break;

      case "city":
        if (!value) {
          error = "City is required";
        }
        break;

      case "weddingDate":
        if (!value) {
          error = "Wedding date is required";
        } else {
          const dateVal = new Date(value);
          const year = dateVal.getFullYear();
          if (!/^\d{4}$/.test(String(year))) {
            error = "Year must be 4 digits";
          }
        }
        break;
    }

    return error;
  };

  const validate = () => {
    const newErrors = {};

    const nameRegex =
      /^([A-Za-z]{3,16})([ ]{0,1})([A-Za-z]{3,16})?([ ]{0,1})?([A-Za-z]{3,16})?([ ]{0,1})?([A-Za-z]{3,16})$/;
    if (!formData.name.trim()) {
      newErrors.name = "Full name is required";
    } else if (!nameRegex.test(formData.name)) {
      newErrors.name =
        "Name must contain 3-16 letters per word, spaces allowed";
    }

    const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
    if (!formData.email.trim()) {
      newErrors.email = "Email is required";
    } else if (!emailRegex.test(formData.email)) {
      newErrors.email = "Please enter a valid email address";
    }

    const passwordRegex = /^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$/;
    if (!formData.password) {
      newErrors.password = "Password is required";
    } else if (!passwordRegex.test(formData.password)) {
      newErrors.password =
        "Password must be 8+ chars with uppercase, lowercase, special character and number";
    }

    if (!formData.phone.trim()) {
      newErrors.phone = "Phone number is required";
    } else if (!/^\d{10}$/.test(formData.phone)) {
      newErrors.phone = "Phone number must be exactly 10 digits";
    }

    if (!formData.weddingDate) {
      newErrors.weddingDate = "Wedding date is required";
    } else {
      const dateVal = new Date(formData.weddingDate);
      const year = dateVal.getFullYear();
      if (!/^\d{4}$/.test(String(year))) {
        newErrors.weddingDate = "Year must be 4 digits";
      }
    }

    if (!formData.city) {
      newErrors.city = "City is required";
    }

    if (!formData.country) {
      newErrors.country = "Country is required";
    }

    if (!formData.weddingVenue.trim()) {
      newErrors.weddingVenue = "Wedding venue is required";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));

    const fieldError = validateField(name, value);
    if (fieldError) {
      setErrors((prev) => ({ ...prev, [name]: fieldError }));
    } else {
      setErrors((prev) => {
        const newErrors = { ...prev };
        delete newErrors[name];
        return newErrors;
      });
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (validate()) {
      setIsSubmitting(true);

      const payload = {
        ...formData,
        role: "user",
      };

      try {
        const res = await axiosInstance.post("/user/register", payload);
        const data = res.data;

        if (data?.success && data.user && data.token) {
          persistUserSession(data.user, data.token);
          dispatch(setCredentials({ user: data.user, token: data.token }));

          setFormData({
            name: "",
            email: "",
            password: "",
            phone: "",
            weddingVenue: "",
            country: "",
            city: "",
            weddingDate: "",
            profile_image: "",
            coverImage: "",
            captchaToken: "test-captcha-token",
          });
          toast.success("Registration successful!");
          navigate("/");
        } else {
          const msg = data.message || "Registration failed";
          if (
            msg.toLowerCase().includes("mobile") &&
            msg.toLowerCase().includes("already")
          ) {
            toast.error(
              "Mobile number already exists. Please use a different number.",
            );
          } else if (
            msg.toLowerCase().includes("email") &&
            msg.toLowerCase().includes("already")
          ) {
            toast.error("Email already exists. Please use a different email.");
          } else {
            toast.error(msg);
          }
        }
      } catch (error) {
        toast.error(error.message);
      }

      setIsSubmitting(false);
    }
  };

  const togglePasswordVisibility = () => {
    setPasswordVisible((prev) => !prev);
  };

  return (
    <div className="container py-5" style={{ maxWidth: "1200px" }}>
      <ToastContainer position="top-center" autoClose={3000} />
      <div className="row g-0 shadow-lg rounded-4 overflow-hidden bg-white">
        <div
          className="col-lg-5 d-none d-lg-block position-relative"
          style={{
            background: signInCms?.image
              ? `linear-gradient(rgba(0,0,0,0.3), rgba(0,0,0,0.3)), url('${normalizeUrl(
                  signInCms?.image,
                )}') center/cover`
              : "linear-gradient(rgba(0,0,0,0.3), rgba(0,0,0,0.3)), url('https://images.unsplash.com/photo-1511795409834-ef04bbd61622?q=80&w=2069&auto=format&fit=crop') center/cover",
            minHeight: "600px",
          }}
        >
          <div className="position-absolute bottom-0 start-0 p-5 text-white">
            <h2 className="display-5 fw-light mb-3">
              {signInCms?.heading || "Your Perfect Wedding Starts Here"}
            </h2>
            <p className="mb-0">
              {signInCms?.subheading ||
                "Join thousands of couples who planned their dream wedding with us"}
            </p>
          </div>
        </div>

        <div className="col-lg-7 p-5">
          <div className="text-center mb-5">
            <h3 className="fw-bold text-dark mb-2">
              {signInCms?.title || "Wedding Registration"}
            </h3>
            <p className="text-muted fs-16">
              {signInCms?.description ||
                "Create your account to start planning your special day"}
            </p>
          </div>

          <form onSubmit={handleSubmit} noValidate>
            <div className="row g-3 mb-4">
              <div className="col-md-6">
                <div className="form-floating">
                  <input
                    type="text"
                    name="name"
                    className={`form-control fs-14 ${
                      errors.name ? "is-invalid" : ""
                    }`}
                    placeholder="Full Name"
                    value={formData.name}
                    onChange={handleChange}
                  />
                  <label className="fs-16">Full Name</label>
                  {errors.name && (
                    <div className="invalid-feedback">{errors.name}</div>
                  )}
                </div>
              </div>

              <div className="col-md-6">
                <div className="form-floating">
                  <input
                    type="email"
                    name="email"
                    className={`form-control fs-14 ${
                      errors.email ? "is-invalid" : ""
                    }`}
                    placeholder="Email"
                    value={formData.email}
                    onChange={handleChange}
                  />
                  <label className="fs-16">Email</label>
                  {errors.email && (
                    <div className="invalid-feedback">{errors.email}</div>
                  )}
                </div>
              </div>

              <div className="col-md-6">
                <div className="form-floating position-relative">
                  <input
                    type={passwordVisible ? "text" : "password"}
                    name="password"
                    className={`form-control fs-14 ${
                      errors.password ? "is-invalid" : ""
                    }`}
                    placeholder="Password"
                    value={formData.password}
                    onChange={handleChange}
                  />
                  <label className="fs-16">Password</label>
                  <button
                    type="button"
                    className="position-absolute end-0 top-50 translate-middle-y border-0 bg-transparent"
                    onClick={togglePasswordVisibility}
                    style={{
                      zIndex: 10,
                      marginRight: "10px",
                    }}
                    aria-label={
                      passwordVisible ? "Hide password" : "Show password"
                    }
                  >
                    {passwordVisible ? <FaEye /> : <FaEyeSlash />}
                  </button>
                  {errors.password && (
                    <div className="invalid-feedback">{errors.password}</div>
                  )}
                </div>
              </div>

              <style>
                {`
                  .input-number::-webkit-inner-spin-button,
                  .input-number::-webkit-outer-spin-button {
                    -webkit-appearance: none;
                    margin: 0;
                  }
                  .input-number {
                    -moz-appearance: textfield;
                  }

                  /* Ensure labels appear visually above inputs on mobile */
                  @media (max-width: 768px) {
                    .form-floating {
                      position: relative;
                    }

                    .form-floating > .form-control,
                    .form-floating > .form-select {
                      min-height: 3.25rem;
                      padding-top: 1.4rem;
                      padding-bottom: 0.75rem;
                      font-size: 0.875rem; /* ~fs-14 */
                    }

                    .form-floating > label {
                      position: absolute;
                      top: 0.1rem;
                      left: 0.9rem;
                      z-index: 999;
                      transform: none;
                      font-size: 1rem;
                      opacity: 1;
                      height: auto;
                      padding: 0 0.25rem;
                      background: #ffffff;
                      pointer-events: none;
                    }
                    input,
                    select,
                    textarea {
                      z-index: 0 !important;
                    }

                    .form-floating > .form-control::placeholder {
                      opacity: 0.7 !important;
                    }
                  }
                `}
              </style>
              <div className="col-md-6">
                <div className="form-floating">
                  <input
                    type="number"
                    name="phone"
                    className={`input-number form-control fs-16 ${
                      errors.phone ? "is-invalid" : ""
                    }`}
                    placeholder="Phone"
                    value={formData.phone}
                    onChange={handleChange}
                    inputMode="numeric"
                    maxLength={10}
                    pattern="\\d{10}"
                  />
                  <label className="fs-16">Phone</label>
                  {errors.phone && (
                    <div className="invalid-feedback">{errors.phone}</div>
                  )}
                </div>
              </div>

              <div className="col-md-6">
                <div className="form-floating">
                  <input
                    type="text"
                    name="weddingVenue"
                    className={`form-control fs-14 ${
                      errors.weddingVenue ? "is-invalid" : ""
                    }`}
                    placeholder="Wedding Venue"
                    value={formData.weddingVenue}
                    onChange={handleChange}
                  />
                  <label className="fs-16">Wedding Venue</label>
                  {errors.weddingVenue && (
                    <div className="invalid-feedback">
                      {errors.weddingVenue}
                    </div>
                  )}
                </div>
              </div>

              <div className="col-md-6">
                <div className="form-floating">
                  <select
                    name="country"
                    className={`form-select fs-14 ${
                      errors.country ? "is-invalid" : ""
                    }`}
                    value={formData.country}
                    onChange={handleChange}
                  >
                    <option value="">Select country</option>
                    {countries.map((c) => (
                      <option key={c.code} value={c.name}>
                        {c.name}
                      </option>
                    ))}
                  </select>
                  <label className="fs-16">Country</label>
                  {errors.country && (
                    <div className="invalid-feedback">{errors.country}</div>
                  )}
                </div>
              </div>

              <div className="col-md-6">
                <div className="form-floating">
                  <select
                    name="city"
                    className={`form-select fs-14 ${
                      errors.city ? "is-invalid" : ""
                    }`}
                    value={formData.city}
                    onChange={handleChange}
                  >
                    <option value="">Select city</option>
                    {cities.map((city, i) => (
                      <option key={i} value={city}>
                        {city}
                      </option>
                    ))}
                  </select>
                  <label className="fs-16">City</label>
                  {errors.city && (
                    <div className="invalid-feedback">{errors.city}</div>
                  )}
                </div>
              </div>

              <div className="col-md-6">
                <div className="form-floating">
                  <input
                    type="date"
                    name="weddingDate"
                    className={`form-control fs-14 ${
                      errors.weddingDate ? "is-invalid" : ""
                    }`}
                    value={formData.weddingDate}
                    onChange={handleChange}
                  />
                  <label className="fs-16">Wedding Date</label>
                  {errors.weddingDate && (
                    <div className="invalid-feedback">{errors.weddingDate}</div>
                  )}
                </div>
              </div>
            </div>

            <div className="d-grid mb-4">
              <button
                type="submit"
                className="btn btn-lg btn-primary fw-medium py-3 fs-16"
                disabled={isSubmitting}
              >
                {isSubmitting && (
                  <span className="spinner-border spinner-border-sm me-2"></span>
                )}
                Create Wedding Account
              </button>
            </div>

            <div className="text-center d-flex justify-content-between">
              <p className="text-muted fs-16">
                I have an account?
                <Link
                  to="/customer-login"
                  className="fw-semibold px-2 wedding-link"
                >
                  Login
                </Link>
              </p>
              <p className="text-muted fs-16">
                I Am Vendor?
                <Link
                  to="/vendor-login"
                  className="fw-semibold px-2 wedding-link"
                >
                  Vendor
                </Link>
              </p>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default CustomerRegister;
