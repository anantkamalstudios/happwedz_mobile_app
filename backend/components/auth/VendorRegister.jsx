import React, { useEffect, useState } from "react";
import axios from "axios";
import { Link, useNavigate } from "react-router-dom";
import { useDispatch } from "react-redux";
import { loginVendor, setVendorCredentials } from "../../redux/vendorAuthSlice";
import vendorsAuthApi from "../../services/api/vendorAuthApi";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import { FaEyeSlash, FaEye } from "react-icons/fa";
import axiosInstance from "../../services/api/axiosInstance";

const API_BASE =
  import.meta.env.VITE_API_BASE_URL ||
  import.meta.env.VITE_API_URL ||
  "https://happywedz.com/api";

const VendorRegister = () => {
  const persistVendorSession = (vendorData, tokenValue) => {
    const expiry = Date.now() + 60 * 60 * 1000;
    localStorage.setItem("vendor", JSON.stringify(vendorData));
    localStorage.setItem("vendorToken", tokenValue);
    localStorage.setItem("vendorTokenExpiry", expiry.toString());
  };

  const [passwordVisible, setPasswordVisible] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [formData, setFormData] = useState({
    brandName: "",
    vendorType: "",
    email: "",
    password: "",
    phone: "",
    city: "",
    country: "India",
  });

  const [errors, setErrors] = useState({
    brandName: "",
    vendorType: "",
    email: "",
    password: "",
    phone: "",
    city: "",
  });

  const [cities, setCities] = useState([]);
  const [vendorTypes, setVendorTypes] = useState([]);
  const navigate = useNavigate();
  const dispatch = useDispatch();

  const togglePasswordVisibility = () => {
    setPasswordVisible((prev) => !prev);
  };

  useEffect(() => {
    if (!formData.country) return;

    axios
      .post("https://countriesnow.space/api/v0.1/countries/cities", {
        country: "India",
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

  useEffect(() => {
    axiosInstance
      .get(`/vendor-types`)
      .then((res) => {
        if (res.data) {
          setVendorTypes(res.data);
        } else {
          setVendorTypes([]);
        }
      })
      .catch((err) => console.error("Error fetching vendor types:", err));
  }, []);

  const validateField = (name, value) => {
    let error = "";

    switch (name) {
      case "brandName":
        if (!value.trim()) {
          error = "Brand Name is required";
        } else if (value.trim().length < 3) {
          error = "Brand Name must be at least 3 characters";
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

      case "vendorType":
        if (!value) {
          error = "Vendor Type is required";
        }
        break;

      case "city":
        if (!value) {
          error = "City is required";
        }
        break;
    }

    return error;
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value,
    });

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

    let formErrors = {};

    const brandNameError = validateField("brandName", formData.brandName);
    if (brandNameError) formErrors.brandName = brandNameError;

    const vendorTypeError = validateField("vendorType", formData.vendorType);
    if (vendorTypeError) formErrors.vendorType = vendorTypeError;

    const emailError = validateField("email", formData.email);
    if (emailError) formErrors.email = emailError;

    const passwordError = validateField("password", formData.password);
    if (passwordError) formErrors.password = passwordError;

    const phoneError = validateField("phone", formData.phone);
    if (phoneError) formErrors.phone = phoneError;

    const cityError = validateField("city", formData.city);
    if (cityError) formErrors.city = cityError;

    setErrors(formErrors);

    if (Object.keys(formErrors).length > 0) {
      const firstError = Object.values(formErrors)[0];
      toast.error(firstError);
      return;
    }

    setIsSubmitting(true);
    try {
      // Get current date/time in ISO format
      const now = new Date();
      const packageStartedAt = now.toISOString();

      const payload = {
        businessName: formData.brandName,
        email: formData.email,
        password: formData.password,
        phone: formData.phone,
        city: formData.city,
        vendor_type_id: formData.vendorType,
        current_package_id: 1,
        package_started_at: packageStartedAt,
      };

      const data = await vendorsAuthApi.register(payload);

      const token = data?.data?.token || data?.token;
      const vendor = data?.data?.vendor ||
        data?.vendor || {
          businessName: formData.brandName,
          email: formData.email,
          phone: formData.phone,
          city: formData.city,
          vendor_type_id: formData.vendorType,
        };

      if (token && vendor) {
        persistVendorSession(vendor, token);
        dispatch(loginVendor({ token, vendor }));
        navigate("/vendor-dashboard/vendor-home", { replace: true });
      } else {
        navigate("/vendor-login", { replace: true });
      }
    } catch (err) {
      const serverMsg =
        err.response?.data?.message ||
        err.message ||
        "Registration failed. Please try again.";
      toast.error(serverMsg);
      setIsSubmitting(false);
    }
  };

  return (
    <>
      <ToastContainer position="top-center" autoClose={3000} />
      <div className="container py-5" style={{ maxWidth: "1200px" }}>
        <div className="row g-0 shadow-lg rounded-4 overflow-hidden bg-white">
          <div
            className="col-lg-5 d-none d-lg-block position-relative"
            style={{
              background:
                "linear-gradient(rgba(0,0,0,0.3), rgba(0,0,0,0.3)), url('https://images.unsplash.com/photo-1511795409834-ef04bbd61622?q=80&w=2069&auto=format&fit=crop') center/cover",
              minHeight: "600px",
            }}
          >
            <div className="position-absolute bottom-0 start-0 p-5 text-white">
              <h2 className="display-5 fw-light mb-3">
                Your Perfect Wedding Starts Here
              </h2>
              <p className="mb-0">
                Join thousands of vendors who help couples plan their dream
                wedding.
              </p>
            </div>
          </div>

          <div className="col-lg-7 p-5">
            <div className="text-center mb-5">
              <h3 className="fw-bold text-dark mb-2">Vendor Registration</h3>
              <p className="text-muted fs-16">
                Create your vendor account to start providing services for
                weddings.
              </p>
            </div>

            <form onSubmit={handleSubmit} noValidate>
              <div className="row g-3 mb-4">
                <div className="col-md-6">
                  <div className="form-floating">
                    <input
                      type="text"
                      id="brandName"
                      name="brandName"
                      className={`form-control fs-14 ${
                        errors.brandName ? "is-invalid" : ""
                      }`}
                      placeholder="Brand Name"
                      value={formData.brandName}
                      onChange={handleChange}
                      required
                    />
                    <label htmlFor="brandName" className="fs-16">
                      Brand Name
                    </label>
                    {errors.brandName && (
                      <div className="invalid-feedback">{errors.brandName}</div>
                    )}
                  </div>
                </div>

                <div className="col-md-6">
                  <div className="form-floating">
                    <select
                      name="vendorType"
                      className={`form-select fs-14 ${
                        errors.vendorType ? "is-invalid" : ""
                      }`}
                      value={formData.vendorType}
                      onChange={handleChange}
                      required
                    >
                      <option value="">Select Vendor Type</option>
                      {vendorTypes.map((type) => (
                        <option
                          key={type.id}
                          value={type.id}
                          className=" fs-16"
                        >
                          {type.name}
                        </option>
                      ))}
                    </select>
                    <label className="fs-16">Vendor Type</label>
                    {errors.vendorType && (
                      <div className="invalid-feedback">
                        {errors.vendorType}
                      </div>
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
                  <div className="form-floating">
                    <select
                      name="city"
                      className={`form-select fs-14 ${
                        errors.city ? "is-invalid" : ""
                      }`}
                      value={formData.city}
                      onChange={handleChange}
                    >
                      <option value="" className="fs-16">
                        Select city
                      </option>
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
                      style={{ paddingRight: "48px" }}
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

                <style jsx>
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
                        transform: none;
                        z-index: 999;
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
                      className={`input-number form-control fs-14 ${
                        errors.phone ? "is-invalid" : ""
                      }`}
                      placeholder="Phone"
                      value={formData.phone}
                      onChange={handleChange}
                    />
                    <label className="fs-16">Phone</label>
                    {errors.phone && (
                      <div className="invalid-feedback">{errors.phone}</div>
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
                  {isSubmitting ? (
                    <span className="spinner-border spinner-border-sm me-2"></span>
                  ) : null}
                  Create Vendor Account
                </button>
              </div>

              <div className="text-center d-flex justify-content-between">
                <p className="text-muted fs-16">
                  I have an account?
                  <Link
                    to="/vendor-login"
                    className="fw-semibold px-2 wedding-link"
                  >
                    Vendor Login
                  </Link>
                </p>
                <p className="text-muted fs-16">
                  I Am a Customer?
                  <Link
                    to="/customer-login"
                    className="fw-semibold px-2 wedding-link"
                  >
                    Customer Login
                  </Link>
                </p>
              </div>
            </form>
          </div>
        </div>
      </div>
    </>
  );
};

export default VendorRegister;
