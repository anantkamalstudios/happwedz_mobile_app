import React, { useEffect, useMemo, useState } from "react";
import axios from "axios";
import { useDispatch, useSelector } from "react-redux";
import {
  Container,
  Row,
  Col,
  Card,
  Form,
  Button,
  Spinner,
  Alert,
  Modal,
} from "react-bootstrap";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";
import { TextField } from "@mui/material";
import dayjs from "dayjs";
import { setCredentials } from "../../../../redux/authSlice";
import { getImageUrl } from "../../../../utils/imageUtils";
import { FaUndo, FaSave, FaImage, FaCamera, FaCropAlt, FaRedo } from "react-icons/fa";

const initialState = {
  id: "",
  name: "",
  email: "",
  phone: "",
  role: "user",
  weddingVenue: "",
  country: "",
  city: "",
  weddingDate: "",
  profileImage: "",
  coverImage: "",
};

const UserProfile = ({ user, token }) => {
  const auth = useSelector((state) => state.auth);
  const effectiveUser = auth?.user || user || {};
  const effectiveToken = auth?.token || token || "";
  const userId =
    effectiveUser?.id ?? effectiveUser?._id ?? effectiveUser?.user_id;

  const [formData, setFormData] = useState(initialState);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [showChangePassword, setShowChangePassword] = useState(false);
  const [passwordFields, setPasswordFields] = useState({
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  });
  const [initialValues, setInitialValues] = useState(null);

  // Image Cropper States
  const [showCropModal, setShowCropModal] = useState(false);
  const [cropImageSrc, setCropImageSrc] = useState(null);
  const [cropTargetField, setCropTargetField] = useState("profileImage");
  const [zoom, setZoom] = useState(1);
  const [rotation, setRotation] = useState(0);
  const [offsetX, setOffsetX] = useState(0);
  const [offsetY, setOffsetY] = useState(0);
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });

  const handlePointerDown = (e) => {
    setIsDragging(true);
    const clientX = e.touches ? e.touches[0].clientX : e.clientX;
    const clientY = e.touches ? e.touches[0].clientY : e.clientY;
    setDragStart({ x: clientX - offsetX, y: clientY - offsetY });
  };

  const handlePointerMove = (e) => {
    if (!isDragging) return;
    const clientX = e.touches ? e.touches[0].clientX : e.clientX;
    const clientY = e.touches ? e.touches[0].clientY : e.clientY;
    setOffsetX(clientX - dragStart.x);
    setOffsetY(clientY - dragStart.y);
  };

  const handlePointerUp = () => {
    setIsDragging(false);
  };

  useEffect(() => {
    if (!effectiveUser || !userId) return;

    const userData = {
      id: userId || "",
      name: effectiveUser.name || "",
      email: effectiveUser.email || "",
      phone: effectiveUser.phone || "",
      role: effectiveUser.role || "user",
      weddingVenue: effectiveUser.weddingVenue || "",
      country: effectiveUser.country || "",
      city: effectiveUser.city || "",
      weddingDate: effectiveUser.weddingDate
        ? String(effectiveUser.weddingDate).slice(0, 10)
        : "",
      profileImage: effectiveUser.profileImage || "",
      coverImage: effectiveUser.coverImage || "",
    };

    setFormData(userData);

    setInitialValues({
      name: effectiveUser.name || "",
      email: effectiveUser.email || "",
      phone: effectiveUser.phone || "",
      weddingVenue: effectiveUser.weddingVenue || "",
      country: effectiveUser.country || "",
      city: effectiveUser.city || "",
      weddingDate: effectiveUser.weddingDate
        ? String(effectiveUser.weddingDate).slice(0, 10)
        : "",
    });
  }, [userId]);

  const profilePreview = useMemo(() => {
    if (formData.profileImage && typeof formData.profileImage !== "string") {
      return URL.createObjectURL(formData.profileImage);
    }
    if (typeof formData.profileImage === "string" && formData.profileImage) {
      return getImageUrl(formData.profileImage);
    }
    return "";
  }, [formData.profileImage]);

  const coverPreview = useMemo(() => {
    if (formData.coverImage && typeof formData.coverImage !== "string") {
      return URL.createObjectURL(formData.coverImage);
    }
    if (typeof formData.coverImage === "string" && formData.coverImage) {
      return getImageUrl(formData.coverImage);
    }
    return "";
  }, [formData.coverImage]);

  useEffect(() => {
    let didCancel = false;
    const fetchUser = async () => {
      if (!userId) return;
      setLoading(true);
      setError("");
      try {
        const res = await fetch(`https://happywedz.com/api/user/${userId}`, {
          headers: {
            "Content-Type": "application/json",
            ...(effectiveToken
              ? { Authorization: `Bearer ${effectiveToken}` }
              : {}),
          },
        });
        if (!res.ok) throw new Error("Failed to fetch user profile");
        const data = await res.json();

        if (didCancel) return;

        setFormData((prev) => ({
          ...prev,
          id: data?.id ?? userId,
          name: data?.name ?? prev.name,
          email: data?.email ?? prev.email,
          phone: data?.phone ?? prev.phone,
          weddingVenue: data?.weddingVenue ?? prev.weddingVenue,
          country: data?.country ?? prev.country,
          city: data?.city ?? prev.city,
          weddingDate: data?.weddingDate
            ? data.weddingDate.slice(0, 10)
            : prev.weddingDate,
          profileImage: data?.profileImage ?? prev.profileImage,
          coverImage: data?.coverImage ?? prev.coverImage,
        }));
      } catch (e) {
        if (!didCancel) setError(e.message || "Something went wrong");
      } finally {
        if (!didCancel) setLoading(false);
      }
    };

    fetchUser();
    return () => {
      didCancel = true;
    };
  }, [userId, effectiveToken]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleDateChange = (newDate) => {
    const formattedDate = newDate ? dayjs(newDate).format("YYYY-MM-DD") : "";
    setFormData((prev) => ({ ...prev, weddingDate: formattedDate }));
  };

  const handleImageChange = (e) => {
    const { name, files } = e.target;
    if (!files || files.length === 0) return;
    const file = files[0];

    if (name === "coverImage") {
      setFormData((prev) => ({ ...prev, [name]: file }));
      e.target.value = "";
      return;
    }

    const imageObjectUrl = URL.createObjectURL(file);
    setCropImageSrc(imageObjectUrl);
    setCropTargetField(name);
    setZoom(1);
    setRotation(0);
    setOffsetX(0);
    setOffsetY(0);
    setShowCropModal(true);
    e.target.value = "";
  };

  const handleCropSave = () => {
    if (!cropImageSrc) return;
    const img = new Image();
    img.src = cropImageSrc;
    img.onload = () => {
      const isProfile = cropTargetField === "profileImage";
      const targetSize = isProfile ? 400 : 800;
      const targetHeight = isProfile ? 400 : 350;
      const canvas = document.createElement("canvas");
      canvas.width = targetSize;
      canvas.height = targetHeight;
      const ctx = canvas.getContext("2d");

      ctx.clearRect(0, 0, targetSize, targetHeight);
      ctx.save();

      ctx.translate(targetSize / 2, targetHeight / 2);
      ctx.rotate((rotation * Math.PI) / 180);
      ctx.scale(zoom, zoom);

      const aspect = img.width / img.height;
      let drawW = targetSize;
      let drawH = targetSize / aspect;
      if (drawH < targetHeight) {
        drawH = targetHeight;
        drawW = targetHeight * aspect;
      }

      ctx.drawImage(
        img,
        -drawW / 2 + offsetX,
        -drawH / 2 + offsetY,
        drawW,
        drawH
      );
      ctx.restore();

      canvas.toBlob((blob) => {
        if (!blob) return;
        const croppedFile = new File([blob], `${cropTargetField}_cropped.jpg`, {
          type: "image/jpeg",
        });
        setFormData((prev) => ({ ...prev, [cropTargetField]: croppedFile }));
        setShowCropModal(false);
      }, "image/jpeg", 0.92);
    };
  };

  const handlePasswordFieldChange = (e) => {
    const { name, value } = e.target;
    setPasswordFields((prev) => ({ ...prev, [name]: value }));
  };

  // Check if passwords match
  const passwordsMatch = useMemo(() => {
    if (!passwordFields.newPassword || !passwordFields.confirmPassword) {
      return null; // Not yet filled
    }
    return passwordFields.newPassword === passwordFields.confirmPassword;
  }, [passwordFields.newPassword, passwordFields.confirmPassword]);

  const passwordStrength = useMemo(() => {
    const pwd = passwordFields.newPassword || "";
    const hasMin = pwd.length >= 8;
    const hasUpper = /[A-Z]/.test(pwd);
    const hasLower = /[a-z]/.test(pwd);
    const hasNumber = /[0-9]/.test(pwd);
    const hasSpecial = /[^A-Za-z0-9]/.test(pwd);
    const notSameAsCurrent = !!pwd && pwd !== (passwordFields.currentPassword || "");
    const isStrong = hasMin && hasUpper && hasLower && hasNumber && hasSpecial && notSameAsCurrent;
    return { hasMin, hasUpper, hasLower, hasNumber, hasSpecial, notSameAsCurrent, isStrong };
  }, [passwordFields.newPassword, passwordFields.currentPassword]);

  // Check if password change form is valid
  const isPasswordFormValid = useMemo(() => {
    if (!showChangePassword) return true; // Not changing password
    return (
      passwordFields.currentPassword &&
      passwordFields.newPassword &&
      passwordStrength.isStrong &&
      passwordFields.confirmPassword &&
      passwordFields.newPassword === passwordFields.confirmPassword
    );
  }, [showChangePassword, passwordFields, passwordStrength]);

  const dispatch = useDispatch();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setError("");
    setSuccess("");
    try {
      if (showChangePassword) {
        if (!passwordFields.currentPassword) {
          throw new Error("Current password is required to change password.");
        }
        if (!passwordStrength.isStrong) {
          throw new Error(
            "Password must be 8+ chars and include upper, lower, number, special, and differ from current."
          );
        }
        if (passwordFields.newPassword !== passwordFields.confirmPassword) {
          throw new Error("New password and confirm password do not match.");
        }
      }

      const hasFiles = Boolean(
        (formData.profileImage && typeof formData.profileImage !== "string") ||
          (formData.coverImage && typeof formData.coverImage !== "string")
      );
      const isPasswordChange = Boolean(
        showChangePassword && passwordFields.newPassword
      );

      let res;

      // Handle password change separately
      if (isPasswordChange) {
        const passwordBody = {
          oldPassword: passwordFields.currentPassword,
          newPassword: passwordFields.newPassword,
        };

        const passwordRes = await axios.put(
          `https://happywedz.com/api/user/${userId}/change-password`,
          passwordBody,
          {
            headers: {
              "Content-Type": "application/json",
              ...(effectiveToken
                ? { Authorization: `Bearer ${effectiveToken}` }
                : {}),
            },
          }
        );

        // Show server response message
        const serverMessage =
          passwordRes.data?.message || "Password changed successfully!";
        setSuccess(serverMessage);
        setPasswordFields({
          currentPassword: "",
          newPassword: "",
          confirmPassword: "",
        });
        setShowChangePassword(false);
      }

      // Handle profile update
      if (hasFiles) {
        const body = new FormData();
        body.append("id", formData.id || "");
        body.append("name", formData.name || "");
        body.append("email", formData.email || "");
        body.append("phone", formData.phone || "");
        body.append("role", formData.role || "user");
        body.append("weddingVenue", formData.weddingVenue || "");
        body.append("country", formData.country || "");
        body.append("city", formData.city || "");
        body.append("weddingDate", formData.weddingDate || "");

        // Only append new images if they are File objects
        if (formData.profileImage && typeof formData.profileImage !== "string")
          body.append("profileImage", formData.profileImage);
        if (formData.coverImage && typeof formData.coverImage !== "string")
          body.append("coverImage", formData.coverImage);

        res = await axios.put(
          `https://happywedz.com/api/user/${userId}`,
          body,
          {
            headers: {
              ...(effectiveToken
                ? { Authorization: `Bearer ${effectiveToken}` }
                : {}),
            },
          }
        );
      } else if (!isPasswordChange) {
        // Only update profile fields if not just changing password
        const jsonBody = {
          id: formData.id || "",
          name: formData.name || "",
          email: formData.email || "",
          phone: formData.phone || "",
          role: formData.role || "user",
          weddingVenue: formData.weddingVenue || "",
          country: formData.country || "",
          city: formData.city || "",
          weddingDate: formData.weddingDate || "",
        };

        // Only include images if they have valid URLs (not empty strings)
        if (
          formData.profileImage &&
          typeof formData.profileImage === "string"
        ) {
          jsonBody.profileImage = formData.profileImage;
        }
        if (formData.coverImage && typeof formData.coverImage === "string") {
          jsonBody.coverImage = formData.coverImage;
        }
        res = await axios.put(
          `https://happywedz.com/api/user/${userId}`,
          jsonBody,
          {
            headers: {
              "Content-Type": "application/json",
              ...(effectiveToken
                ? { Authorization: `Bearer ${effectiveToken}` }
                : {}),
            },
          }
        );
      }

      if (res) {
        if (res.status < 200 || res.status >= 300) {
          throw new Error("Failed to save profile");
        }

        if (res.data?.user) {
          const updatedUser = res?.data?.user;

          dispatch(
            setCredentials({
              user: {
                ...effectiveUser,
                name: updatedUser.name || effectiveUser.name,
                email: updatedUser.email || effectiveUser.email,
                phone: updatedUser.phone || effectiveUser.phone,
                weddingVenue:
                  updatedUser.weddingVenue || effectiveUser.weddingVenue,
                country: updatedUser.country || effectiveUser.country,
                city: updatedUser.city || effectiveUser.city,
                weddingDate:
                  updatedUser.weddingDate || effectiveUser.weddingDate,
                profileImage:
                  updatedUser.profileImage || effectiveUser.profileImage,
                coverImage: updatedUser.coverImage || effectiveUser.coverImage,
              },
              token: effectiveToken,
            })
          );

          // Update local form data with all fields from response
          setFormData((prev) => ({
            ...prev,
            name: updatedUser.name || prev.name,
            email: updatedUser.email || prev.email,
            phone: updatedUser.phone || prev.phone,
            weddingVenue: updatedUser.weddingVenue || prev.weddingVenue,
            country: updatedUser.country || prev.country,
            city: updatedUser.city || prev.city,
            weddingDate: updatedUser.weddingDate
              ? String(updatedUser.weddingDate).slice(0, 10)
              : prev.weddingDate,
            profileImage: updatedUser.profileImage || prev.profileImage,
            coverImage: updatedUser.coverImage || prev.coverImage,
          }));

          // Update initialValues to reflect the saved state
          setInitialValues({
            name: updatedUser.name || "",
            email: updatedUser.email || "",
            phone: updatedUser.phone || "",
            weddingVenue: updatedUser.weddingVenue || "",
            country: updatedUser.country || "",
            city: updatedUser.city || "",
            weddingDate: updatedUser.weddingDate
              ? String(updatedUser.weddingDate).slice(0, 10)
              : "",
          });
        }

        setSuccess("Profile updated successfully!");
      }

      setError("");
    } catch (e) {
      setError(
        e?.response?.data?.message || e.message || "Failed to save profile"
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Container className="py-3 py-md-4">
      <style>{`
        .profile-avatar-upload:hover .profile-avatar-overlay { opacity: 1; }
        .profile-avatar-upload:focus-within { outline: 2px solid #0d6efd; outline-offset: 2px; }
      `}</style>
      <Row className="g-3 g-md-4">
        <Col xs={12}>
          <Card className="border-0 shadow-sm">
            <div
              style={{
                height: "180px",
                background:
                  coverPreview ||
                  (formData.coverImage && getImageUrl(formData.coverImage))
                    ? `url(${
                        coverPreview || getImageUrl(formData.coverImage)
                      }) center/cover no-repeat`
                    : "linear-gradient(135deg, #fdf2f8 0%, #e9d5ff 100%)",
                borderTopLeftRadius: "0.375rem",
                borderTopRightRadius: "0.375rem",
              }}
            />
            <Card.Body>
              <Row className="align-items-center">
                <Col xs="auto">
                  <label
                    htmlFor="profileImageUpload"
                    className="profile-avatar-upload"
                    title="Click to upload profile photo"
                    style={{
                      position: "relative",
                      display: "block",
                      width: "96px",
                      height: "96px",
                      borderRadius: "50%",
                      border: "3px solid #fff",
                      marginTop: "-72px",
                      boxShadow: "0 4px 16px rgba(0,0,0,0.08)",
                      backgroundColor: "#f3f4f6",
                      cursor: "pointer",
                    }}
                  >
                    <div
                      style={{
                        width: "100%",
                        height: "100%",
                        borderRadius: "50%",
                        overflow: "hidden",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                      }}
                    >
                      {profilePreview ? (
                        <img
                          src={profilePreview}
                          alt="Profile"
                          style={{
                            width: "100%",
                            height: "100%",
                            objectFit: "cover",
                          }}
                        />
                      ) : (
                        <FaCamera size={26} color="#9ca3af" />
                      )}
                    </div>

                    {/* hover overlay */}
                    <div
                      className="profile-avatar-overlay"
                      style={{
                        position: "absolute",
                        inset: 0,
                        borderRadius: "50%",
                        background: "rgba(0,0,0,0.45)",
                        color: "#fff",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        fontSize: "11px",
                        fontWeight: 600,
                        opacity: 0,
                        transition: "opacity .15s ease",
                      }}
                    >
                      {profilePreview ? "Change" : "Upload"}
                    </div>

                    {/* camera badge */}
                    <span
                      style={{
                        position: "absolute",
                        right: "-2px",
                        bottom: "-2px",
                        width: "30px",
                        height: "30px",
                        borderRadius: "50%",
                        background: "#0d6efd",
                        border: "2px solid #fff",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        boxShadow: "0 2px 6px rgba(0,0,0,0.2)",
                      }}
                    >
                      <FaCamera size={13} color="#fff" />
                    </span>

                    <input
                      id="profileImageUpload"
                      type="file"
                      accept="image/*"
                      name="profileImage"
                      onChange={handleImageChange}
                      style={{ display: "none" }}
                    />
                  </label>
                </Col>
                <Col>
                  <div className="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-2">
                    <div>
                      <h5 className="mb-1">
                        {formData.name || effectiveUser?.name || "Your Name"}
                      </h5>
                      <div className="text-muted small">
                        {formData.email || effectiveUser?.email || "your@email"}
                      </div>
                    </div>
                    <div className="d-flex gap-2">
                      <Form.Group controlId="coverImage" className="mb-0">
                        <Form.Label
                          className="btn btn-outline-secondary btn-sm mb-0 fs-14 d-inline-flex align-items-center justify-content-center"
                          title="Change cover"
                          aria-label="Change cover"
                        >
                          <FaImage size={16} />
                        </Form.Label>
                        <Form.Control
                          type="file"
                          accept="image/*"
                          name="coverImage"
                          onChange={handleImageChange}
                          className="d-none"
                        />
                      </Form.Group>
                      <label
                        htmlFor="profileImageUpload"
                        className="btn btn-outline-primary btn-sm mb-0 fs-14 d-inline-flex align-items-center justify-content-center"
                        title="Change photo"
                        aria-label="Change photo"
                      >
                        <FaCamera size={16} />
                      </label>
                    </div>
                  </div>
                </Col>
              </Row>

              <hr className="my-4" />

              {error ? (
                <Alert variant="danger" className="mb-3">
                  {error}
                </Alert>
              ) : null}
              {success ? (
                <Alert variant="success" className="mb-3">
                  {success}
                </Alert>
              ) : null}

              <Form onSubmit={handleSubmit}>
                <Row className="g-3">
                  <Col md={6}>
                    <Form.Group controlId="name">
                      <Form.Label className="fs-16">Full Name</Form.Label>
                      <Form.Control
                        className="fs-14"
                        type="text"
                        name="name"
                        value={formData.name}
                        onChange={handleChange}
                        placeholder="Enter your full name"
                        required
                      />
                    </Form.Group>
                  </Col>

                  <Col md={6}>
                    <Form.Group controlId="email">
                      <Form.Label className="fs-16">Email</Form.Label>
                      <Form.Control
                        className="fs-14"
                        type="email"
                        name="email"
                        value={formData.email}
                        onChange={handleChange}
                        placeholder="name@example.com"
                        disabled
                      />
                    </Form.Group>
                  </Col>

                  <Col md={6}>
                    <Form.Group controlId="phone">
                      <Form.Label className="fs-16">Phone</Form.Label>
                      <Form.Control
                        className="fs-14"
                        type="tel"
                        name="phone"
                        value={formData.phone}
                        onChange={handleChange}
                        placeholder="Enter phone number"
                      />
                    </Form.Group>
                  </Col>

                  <Col md={6}>
                    <Form.Group controlId="weddingDate">
                      <Form.Label className="fs-16">Wedding Date</Form.Label>

                      <LocalizationProvider dateAdapter={AdapterDayjs}>
                        <DatePicker
                          value={
                            formData.weddingDate
                              ? dayjs(formData.weddingDate)
                              : null
                          }
                          format="DD/MM/YYYY"
                          onChange={handleDateChange}
                          slotProps={{
                            textField: {
                              fullWidth: true,
                              size: "small",
                              placeholder: "Select wedding date",
                              className: "fs-14",
                              InputProps: { style: { fontSize: 14 } },
                              inputProps: { style: { fontSize: 14 } },
                            },
                          }}
                        />
                      </LocalizationProvider>
                    </Form.Group>
                  </Col>

                  <Col md={6}>
                    <Form.Group controlId="country">
                      <Form.Label className="fs-16">Country</Form.Label>
                      <Form.Control
                        className="fs-14"
                        type="text"
                        name="country"
                        value={formData.country}
                        onChange={handleChange}
                        placeholder="Country"
                      />
                    </Form.Group>
                  </Col>

                  <Col md={3}>
                    <Form.Group controlId="city">
                      <Form.Label className="fs-16">City</Form.Label>
                      <Form.Control
                        className="fs-14"
                        type="text"
                        name="city"
                        value={formData.city}
                        onChange={handleChange}
                        placeholder="City"
                      />
                    </Form.Group>
                  </Col>

                  <Col md={3}>
                    <Form.Group controlId="weddingVenue">
                      <Form.Label className="fs-16">Wedding City</Form.Label>
                      <Form.Control
                        className="fs-14"
                        type="text"
                        name="weddingVenue"
                        value={formData.weddingVenue}
                        onChange={handleChange}
                        placeholder="Wedding City"
                      />
                    </Form.Group>
                  </Col>

                  {/* Toggle link */}
                  <Col xs={12} className="mt-2">
                    <span
                      onClick={() => setShowChangePassword((s) => !s)}
                      className="text-danger fs-16 pointer"
                      role="button"
                    >
                      {showChangePassword
                        ? "Cancel password change"
                        : "Change password"}
                    </span>
                  </Col>

                  {showChangePassword ? (
                    <div className="d-flex flex-column gap-3">
                      <Col md={4}>
                        <Form.Group controlId="currentPassword">
                          <Form.Label className="fs-16">
                            Current Password
                          </Form.Label>
                          <Form.Control
                            className="fs-14"
                            type="password"
                            name="currentPassword"
                            value={passwordFields.currentPassword}
                            onChange={handlePasswordFieldChange}
                            placeholder="Current password"
                          />
                        </Form.Group>
                      </Col>

                      <Col md={4}>
                        <Form.Group controlId="newPassword">
                          <Form.Label className="fs-16">
                            New Password
                          </Form.Label>
                          <Form.Control
                            className="fs-14"
                            type="password"
                            name="newPassword"
                            value={passwordFields.newPassword}
                            onChange={handlePasswordFieldChange}
                            placeholder="New password"
                            isValid={
                              !!passwordFields.newPassword && passwordStrength.isStrong
                            }
                            isInvalid={
                              !!passwordFields.newPassword && !passwordStrength.isStrong
                            }
                          />
                          <Form.Control.Feedback type="invalid">
                            Must be 8+ chars, include upper, lower, number, special, and differ from current
                          </Form.Control.Feedback>
                          <div className="mt-2 small">
                            <div className={passwordStrength.hasMin ? "text-success" : "text-danger"}>
                              • At least 8 characters
                            </div>
                            <div className={passwordStrength.hasUpper ? "text-success" : "text-danger"}>
                              • At least one uppercase letter
                            </div>
                            <div className={passwordStrength.hasLower ? "text-success" : "text-danger"}>
                              • At least one lowercase letter
                            </div>
                            <div className={passwordStrength.hasNumber ? "text-success" : "text-danger"}>
                              • At least one number
                            </div>
                            <div className={passwordStrength.hasSpecial ? "text-success" : "text-danger"}>
                              • At least one special character
                            </div>
                            <div className={passwordStrength.notSameAsCurrent ? "text-success" : "text-danger"}>
                              • Different from current password
                            </div>
                          </div>
                        </Form.Group>
                      </Col>

                      <Col md={4}>
                        <Form.Group controlId="confirmPassword">
                          <Form.Label className="fs-16">
                            Confirm Password
                          </Form.Label>
                          <Form.Control
                            className="fs-14"
                            type="password"
                            name="confirmPassword"
                            value={passwordFields.confirmPassword}
                            onChange={handlePasswordFieldChange}
                            placeholder="Confirm new password"
                            isValid={passwordsMatch === true}
                            isInvalid={passwordsMatch === false}
                          />
                          {passwordsMatch === false && (
                            <Form.Control.Feedback type="invalid">
                              Passwords do not match
                            </Form.Control.Feedback>
                          )}
                          {passwordsMatch === true && (
                            <Form.Control.Feedback type="valid">
                              Passwords match ✓
                            </Form.Control.Feedback>
                          )}
                        </Form.Group>
                      </Col>
                    </div>
                  ) : null}

                  <Col
                    xs={12}
                    className="d-grid gap-2 d-sm-flex justify-content-sm-end mt-4"
                  >
                    <Button
                      variant="outline-secondary"
                      type="button"
                      className="fs-14"
                      title="Reset profile form"
                      onClick={() => setFormData(initialState)}
                    >
                      Reset
                    </Button>

                    <Button
                      variant="primary"
                      type="submit"
                      className="fs-14"
                      title="Save profile"
                      disabled={submitting || !isPasswordFormValid}
                    >
                      {submitting ? (
                        <>
                          <Spinner
                            as="span"
                            size="sm"
                            animation="border"
                            className="me-2"
                          />
                          Saving...
                        </>
                      ) : (
                        "Save"
                      )}
                    </Button>
                  </Col>
                </Row>
              </Form>
            </Card.Body>
            {loading ? (
              <div className="w-100 d-flex align-items-center justify-content-center py-3">
                <Spinner animation="border" size="sm" className="me-2" />
                Loading profile...
              </div>
            ) : null}
          </Card>
        </Col>
      </Row>

      {/* Image Cropper Modal */}
      <Modal
        show={showCropModal}
        onHide={() => setShowCropModal(false)}
        centered
        size="lg"
      >
        <Modal.Header closeButton>
          <Modal.Title className="fs-18 fw-bold">
            <FaCropAlt className="me-2" style={{ color: "#ed1173" }} />
            Crop {cropTargetField === "profileImage" ? "Profile Picture" : "Cover Photo"}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body className="text-center">
          <p className="text-muted small mb-2">
            💡 Drag the image with your mouse or finger to align it inside the crop circle.
          </p>
          <div
            onMouseDown={handlePointerDown}
            onMouseMove={handlePointerMove}
            onMouseUp={handlePointerUp}
            onMouseLeave={handlePointerUp}
            onTouchStart={handlePointerDown}
            onTouchMove={handlePointerMove}
            onTouchEnd={handlePointerUp}
            style={{
              position: "relative",
              width: "100%",
              height: "360px",
              backgroundColor: "#111",
              overflow: "hidden",
              borderRadius: "8px",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              cursor: isDragging ? "grabbing" : "grab",
              userSelect: "none",
              touchAction: "none",
            }}
          >
            {cropImageSrc && (
              <img
                src={cropImageSrc}
                alt="Crop Preview"
                draggable={false}
                style={{
                  transform: `translate(${offsetX}px, ${offsetY}px) rotate(${rotation}deg) scale(${zoom})`,
                  transition: isDragging ? "none" : "transform 0.05s ease-out",
                  maxHeight: "100%",
                  maxWidth: "100%",
                  objectFit: "contain",
                  userSelect: "none",
                  pointerEvents: "none",
                }}
              />
            )}
            {/* Viewport Mask Overlay */}
            <div
              style={{
                position: "absolute",
                top: "50%",
                left: "50%",
                transform: "translate(-50%, -50%)",
                width: cropTargetField === "profileImage" ? "220px" : "320px",
                height: cropTargetField === "profileImage" ? "220px" : "180px",
                borderRadius: cropTargetField === "profileImage" ? "50%" : "8px",
                border: "2px dashed #ed1173",
                boxShadow: "0 0 0 9999px rgba(0,0,0,0.55)",
                pointerEvents: "none",
              }}
            />
          </div>

          <div className="mt-3 px-3">
            <Row className="align-items-center mb-2">
              <Col xs={3} className="text-end fw-bold fs-14">Zoom:</Col>
              <Col xs={7}>
                <Form.Range
                  min={1}
                  max={3}
                  step={0.1}
                  value={zoom}
                  onChange={(e) => setZoom(parseFloat(e.target.value))}
                />
              </Col>
              <Col xs={2} className="text-start fs-14">{zoom.toFixed(1)}x</Col>
            </Row>

            <Row className="align-items-center mb-2">
              <Col xs={3} className="text-end fw-bold fs-14">Pan Horizontal (X):</Col>
              <Col xs={7}>
                <Form.Range
                  min={-150}
                  max={150}
                  value={offsetX}
                  onChange={(e) => setOffsetX(parseInt(e.target.value))}
                />
              </Col>
              <Col xs={2} className="text-start fs-14">{offsetX}px</Col>
            </Row>

            <Row className="align-items-center mb-2">
              <Col xs={3} className="text-end fw-bold fs-14">Pan Vertical (Y):</Col>
              <Col xs={7}>
                <Form.Range
                  min={-150}
                  max={150}
                  value={offsetY}
                  onChange={(e) => setOffsetY(parseInt(e.target.value))}
                />
              </Col>
              <Col xs={2} className="text-start fs-14">{offsetY}px</Col>
            </Row>

            <div className="d-flex justify-content-center gap-2 mt-3">
              <Button
                variant="outline-secondary"
                size="sm"
                onClick={() => setRotation((r) => (r + 90) % 360)}
              >
                <FaRedo className="me-1" /> Rotate 90°
              </Button>
              <Button
                variant="outline-secondary"
                size="sm"
                onClick={() => {
                  setZoom(1);
                  setRotation(0);
                  setOffsetX(0);
                  setOffsetY(0);
                }}
              >
                Reset
              </Button>
            </div>
          </div>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={() => setShowCropModal(false)}>
            Cancel
          </Button>
          <Button
            style={{ backgroundColor: "#ed1173", borderColor: "#ed1173" }}
            onClick={handleCropSave}
          >
            Apply & Save Crop
          </Button>
        </Modal.Footer>
      </Modal>
    </Container>
  );
};

export default UserProfile;
