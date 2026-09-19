import React, { useEffect } from "react";
import { useSelector, useDispatch } from "react-redux";
import vendorsAuthApi, {
  vendorsApi,
} from "../../../../services/api/vendorAuthApi";
import { setVendor } from "../../../../redux/vendorAuthSlice";
import { useToast } from "../../../layouts/toasts/Toast";
import vendorVerificationApi from "../../../../services/api/vendorVerificationApi";
import VerificationStatusBanner from "./kyc/VerificationStatusBanner";
import BusinessDocumentsSection, {
  MAX_BUSINESS_DOCS,
} from "./kyc/BusinessDocumentsSection";

const emptyBusinessDoc = () => ({
  id: `doc-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
  label: "",
  file: null,
});

const BusinessDetails = ({ formData, setFormData, onVerificationSubmitted }) => {
  const { addToast } = useToast();
  const [showPasswordFields, setShowPasswordFields] = React.useState(false);
  const [currentPassword, setCurrentPassword] = React.useState("");
  const [newPassword, setNewPassword] = React.useState("");
  const [confirmPassword, setConfirmPassword] = React.useState("");
  const [submitting, setSubmitting] = React.useState(false);
  const [error, setError] = React.useState("");
  const [success, setSuccess] = React.useState("");
  const [changePwdLoading, setChangePwdLoading] = React.useState(false);
  const [changePwdErrors, setChangePwdErrors] = React.useState({});
  const [showPasswords, setShowPasswords] = React.useState(false);
  const [profileImageFile, setProfileImageFile] = React.useState(null);
  const [profileImagePreview, setProfileImagePreview] = React.useState(null);
  const [isImageRemoved, setIsImageRemoved] = React.useState(false);
  const [profileImageError, setProfileImageError] = React.useState("");
  const [validationErrors, setValidationErrors] = React.useState({});

  const { vendor, token } = useSelector((state) => state.vendorAuth || {});
  const dispatch = useDispatch();

  // ── Onboarding verification ────────────────────────────────────────────────
  const [access, setAccess] = React.useState(null);
  const [existingDocs, setExistingDocs] = React.useState({});
  const [kyc, setKyc] = React.useState({
    aadhaar: null,
    pan: null,
    businessDocs: [emptyBusinessDoc()],
  });
  const [kycErrors, setKycErrors] = React.useState({});

  const loadVerificationStatus = React.useCallback(async () => {
    try {
      const data = await vendorVerificationApi.getStatus();
      setAccess(data.access || null);

      // Group what is already on file so the form can show "already uploaded" and let a
      // rejected vendor replace only the document that was wrong.
      const grouped = { business: [] };
      (data.documents || []).forEach((doc) => {
        if (doc.doc_type === "business") grouped.business.push(doc);
        else grouped[doc.doc_type] = doc;
      });
      setExistingDocs(grouped);
    } catch (err) {
      console.error("Failed to load verification status:", err);
    }
  }, []);

  React.useEffect(() => {
    if (vendor?.id) loadVerificationStatus();
  }, [vendor?.id, loadVerificationStatus]);

  const isUnderReview = access?.stage === "kyc_pending";
  const needsVerification = Boolean(access?.canSubmitVerification);

  const updateKyc = (patch) => {
    setKyc((prev) => ({ ...prev, ...patch }));
    // Clear the errors for whatever the vendor just touched, so corrections feel
    // responsive instead of leaving stale red text on a field they already fixed.
    setKycErrors((prev) => {
      const next = { ...prev };
      Object.keys(patch).forEach((key) => delete next[key]);
      if (patch.businessDocs) {
        Object.keys(next)
          .filter((k) => k.startsWith("businessDoc"))
          .forEach((k) => delete next[k]);
      }
      return next;
    });
  };

  /** @returns {object} field -> message; empty when the submission is valid */
  const validateKyc = () => {
    const errors = {};
    const filled = kyc.businessDocs.filter((d) => d.file || d.label.trim());

    if (!kyc.aadhaar && !existingDocs.aadhaar) {
      errors.aadhaar = "Please upload your Aadhaar card.";
    }
    if (!kyc.pan && !existingDocs.pan) {
      errors.pan = "Please upload your PAN card.";
    }

    const hasExistingBusiness = (existingDocs.business || []).length > 0;
    if (!filled.length && !hasExistingBusiness) {
      errors.businessDocs = "Please add at least one business document.";
    }

    // A half-filled row is a mistake, not an intent — flag whichever half is missing.
    kyc.businessDocs.forEach((doc, i) => {
      const hasLabel = Boolean(doc.label.trim());
      const hasFile = Boolean(doc.file);
      if (hasFile && !hasLabel) {
        errors[`businessDocLabel-${i}`] = "Give this document a name.";
      }
      if (hasLabel && !hasFile) {
        errors[`businessDocFile-${i}`] = "Choose a file for this document.";
      }
    });

    return errors;
  };

  const handleSubmitVerification = async () => {
    setError("");
    setSuccess("");
    setValidationErrors({});

    const payload = buildRegisterPayload();
    const requiredFields = ["businessName", "email", "phone", "city"];
    const fieldErrors = {};
    requiredFields.forEach((f) => {
      if (!payload[f] || String(payload[f]).trim() === "") {
        fieldErrors[f] = "This field is required";
      }
    });

    const docErrors = validateKyc();
    setValidationErrors(fieldErrors);
    setKycErrors(docErrors);

    if (Object.keys(fieldErrors).length || Object.keys(docErrors).length) {
      const first = Object.values(fieldErrors)[0] || Object.values(docErrors)[0];
      setError(first);
      addToast?.(first, "error");
      return;
    }

    setSubmitting(true);
    try {
      const data = await vendorVerificationApi.submit({
        fields: {
          businessName: payload.businessName,
          phone: payload.phone,
          city: payload.city,
          state: payload.state || "",
          zip: payload.zip || "",
          firstName: payload.firstName || "",
          lastName: payload.lastName || "",
          website: payload.website || "",
        },
        aadhaar: kyc.aadhaar,
        pan: kyc.pan,
        businessDocs: kyc.businessDocs.filter((d) => d.file && d.label.trim()),
      });

      setAccess(data.access || null);
      setKyc({ aadhaar: null, pan: null, businessDocs: [emptyBusinessDoc()] });
      setSuccess(data.message);
      addToast?.(data.message, "success");

      await loadVerificationStatus();
      onVerificationSubmitted?.(data.access);
      window.scrollTo({ top: 0, behavior: "smooth" });
    } catch (err) {
      const msg =
        err.response?.data?.message ||
        err.message ||
        "We could not submit your documents. Please try again.";
      setError(msg);
      addToast?.(msg, "error");
    } finally {
      setSubmitting(false);
    }
  };

  // Fetch fresh vendor data from API when component loads
  useEffect(() => {
    const fetchVendorData = async () => {
      if (vendor?.id) {
        try {
          const vendorData = await vendorsApi.getVendorById(vendor.id);
          if (vendorData) {
            // Update Redux store with fresh vendor data from API
            dispatch(setVendor(vendorData));
          }
        } catch (error) {
          console.error("Failed to fetch vendor data:", error);
        }
      }
    };

    fetchVendorData();
  }, [vendor?.id, dispatch]);

  // Pre-fill data from Redux when the component loads
  useEffect(() => {
    if (vendor) {
      setFormData((prev) => ({
        ...prev,
        attributes: {
          ...prev.attributes,
          email: prev.attributes?.email || vendor.email || "",
          businessName:
            prev.attributes?.businessName || vendor.businessName || "",
          phone: prev.attributes?.phone || vendor.phone || "",
          username: prev.attributes?.username || vendor.email || "",
          vendor_type_id:
            prev.attributes?.vendor_type_id || vendor.vendor_type_id || "",
          years_in_business:
            prev.attributes?.years_in_business ||
            vendor.years_in_business ||
            "",
          firstName: prev.attributes?.firstName || vendor.firstName || "",
          lastName: prev.attributes?.lastName || vendor.lastName || "",
          city: prev.attributes?.city || vendor.city || "",
          state: prev.attributes?.state || vendor.state || "",
          zip: prev.attributes?.zip || vendor.zip || "",
          website: prev.attributes?.website || vendor.website || "",
          facebook_link:
            prev.attributes?.facebook_link || vendor.facebook_link || "",
          instagram_link:
            prev.attributes?.instagram_link || vendor.instagram_link || "",
          twitter_link:
            prev.attributes?.twitter_link || vendor.twitter_link || "",
          pinterest_link:
            prev.attributes?.pinterest_link || vendor.pinterest_link || "",
        },
      }));
    }
  }, [vendor, setFormData]);

  const handleAttributeChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      attributes: { ...prev.attributes, [name]: value },
    }));
  };

  const [isDragging, setIsDragging] = React.useState(false);
  const MAX_FILE_SIZE_MB = 5;
  const MAX_FILE_SIZE_BYTES = MAX_FILE_SIZE_MB * 1024 * 1024;

  const validateAndSetImage = (file) => {
    setProfileImageError("");
    if (!file) {
      setProfileImageFile(null);
      return;
    }

    if (!file.type.startsWith("image/")) {
      setProfileImageError("Please upload a valid image file (JPG, PNG, WEBP).");
      setProfileImageFile(null);
      return;
    }

    if (file.size > MAX_FILE_SIZE_BYTES) {
      const sizeInMB = (file.size / (1024 * 1024)).toFixed(2);
      setProfileImageError(
        `File size must be less than ${MAX_FILE_SIZE_MB} MB. (Selected: ${sizeInMB} MB)`
      );
      setProfileImageFile(null);
      return;
    }

    setProfileImageFile(file);
    setIsImageRemoved(false);
    setProfileImageError("");
  };

  const handleRemoveImage = (e) => {
    if (e) e.stopPropagation();
    setProfileImageFile(null);
    setProfileImagePreview(null);
    setIsImageRemoved(true);
    setProfileImageError("");
    const fileInput = document.getElementById("profileUpload");
    if (fileInput) fileInput.value = "";
    addToast("Profile image removed. Click Save to update.", "info");
  };

  const handleProfileImage = (e) => {
    const file = e.target.files?.[0] || null;
    validateAndSetImage(file);
    if (e.target) e.target.value = "";
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
    const file = e.dataTransfer.files?.[0] || null;
    validateAndSetImage(file);
  };

  // Build preview URL when file changes, or use existing vendor image when available
  React.useEffect(() => {
    let objectUrl;
    if (profileImageFile) {
      objectUrl = URL.createObjectURL(profileImageFile);
      setProfileImagePreview(objectUrl);
    } else if (isImageRemoved) {
      setProfileImagePreview(null);
    } else if (vendor) {
      // try multiple possible vendor image fields
      const candidate =
        vendor.profileImage ||
        vendor.profile_image ||
        vendor.avatar ||
        vendor.image ||
        vendor.picture ||
        null;

      // Normalize URL - fix /src/uploads/ to /uploads/ if present
      let imageUrl = candidate;
      if (imageUrl && typeof imageUrl === "string") {
        imageUrl = imageUrl.replace(/\/src\/uploads\//g, "/src/uploads/");
      } else {
        imageUrl = null;
      }

      setProfileImagePreview(imageUrl);
    } else {
      setProfileImagePreview(null);
    }

    return () => {
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [profileImageFile, isImageRemoved, vendor]);

  const getPasswordStrength = (pwd) => {
    if (!pwd) return null;
    let score = 0;
    if (pwd.length >= 8) score++;
    if (/[A-Z]/.test(pwd)) score++;
    if (/[0-9]/.test(pwd)) score++;
    if (/[^A-Za-z0-9]/.test(pwd)) score++;
    if (score <= 1) return "Weak";
    if (score === 2 || score === 3) return "Medium";
    return "Strong";
  };

  const buildRegisterPayload = () => {
    const a = formData.attributes || {};
    const payload = {
      businessName: a.businessName || "",
      email: a.email || "",
      phone: a.phone || "",
      city: a.city || "",
      state: a.state || null,
      zip: a.zip || null,
      website: a.website || null,
      facebook_link: a.facebook_link || null,
      instagram_link: a.instagram_link || null,
      twitter_link: a.twitter_link || null,
      pinterest_link: a.pinterest_link || null,
      vendor_type_id: a.vendor_type_id ? Number(a.vendor_type_id) : null,
      firstName: a.firstName || null,
      lastName: a.lastName || null,
    };
    if (newPassword && newPassword === confirmPassword) {
      payload.password = newPassword;
    }
    // Add profileImageFile for update (will be handled separately in FormData)
    if (profileImageFile) {
      payload.profileImage = profileImageFile;
    }
    return payload;
  };

  const handleSubmitRegister = async () => {
    setSubmitting(true);
    setError("");
    setSuccess("");
    setValidationErrors({});
    try {
      const payload = buildRegisterPayload();

      // Validate required fields
      const requiredFields = ["businessName", "email", "phone", "city"];
      const errors = {};
      requiredFields.forEach((f) => {
        const value = payload[f];
        if (value === undefined || value === null || `${value}`.trim() === "") {
          errors[f] = "Required";
        }
      });

      // On register, password is required if creating new vendor (no vendor.id)
      const isNew = !vendor?.id;
      if (isNew && !payload.password) {
        errors.password = "Required";
      }

      if (Object.keys(errors).length) {
        setValidationErrors(errors);
        throw new Error("Required fields missing");
      }

      if (vendor?.id) {
        // Update existing vendor
        let updatedVendor;
        // If profileImageFile is present, use FormData
        if (profileImageFile) {
          const formDataObj = new FormData();
          // Append all fields except profileImage (we'll append the file separately)
          Object.entries(payload).forEach(([key, value]) => {
            // Skip null/undefined values and the profileImage key (we handle file separately)
            if (value === null || value === undefined || key === "profileImage")
              return;
            // Convert numbers to strings for FormData, keep strings as-is (including empty strings)
            const formValue = typeof value === "number" ? String(value) : value;
            formDataObj.append(key, formValue);
          });
          // Append the file with the correct key
          formDataObj.append("profileImage", profileImageFile);
          updatedVendor = await vendorsApi.updateVendor(vendor.id, formDataObj);
        } else {
          // Update without file using the vendorsApi.updateVendor endpoint
          updatedVendor = await vendorsApi.updateVendor(vendor.id, payload);
        }

        // Fetch fresh vendor data from API after successful update to get updated profileImage URL
        try {
          const freshVendorData = await vendorsApi.getVendorById(vendor.id);
          if (freshVendorData) {
            // Update Redux store with fresh vendor data from API (includes updated profileImage URL)
            dispatch(setVendor(freshVendorData));
          } else {
            // Fallback: merge without profileImage File object
            const { profileImage: _, ...payloadWithoutFile } = payload;
            const mergedVendor = {
              ...vendor,
              ...payloadWithoutFile,
            };
            dispatch(setVendor(mergedVendor));
          }
        } catch (fetchError) {
          // If fetch fails, still update with what we have (excluding File object)
          console.warn("Failed to fetch updated vendor:", fetchError);
          const { profileImage: _, ...payloadWithoutFile } = payload;
          const mergedVendor = {
            ...vendor,
            ...payloadWithoutFile,
          };
          dispatch(setVendor(mergedVendor));
        }

        // Clear the file selection after successful update so preview uses server URL
        if (profileImageFile) {
          setProfileImageFile(null);
        }
      } else {
        // Register new vendor
        const newVendor = await vendorsAuthApi.register(payload);
        // Update Redux store with new vendor data
        if (newVendor) {
          dispatch(setVendor(newVendor));
        }
      }
      const successMsg = profileImageFile
        ? "Business details and profile image updated successfully!"
        : "Business details saved successfully.";
      setSuccess(successMsg);
      addToast(successMsg, "success");
    } catch (e) {
      // Prefer server message if available
      const serverMsg =
        e?.response?.data?.message || e?.response?.data || e?.message;
      setError(typeof serverMsg === "string" ? serverMsg : "Failed to save");
    } finally {
      setSubmitting(false);
    }
  };

  // Change password handler
  const handleChangePassword = async () => {
    setChangePwdErrors({});
    setError("");
    setSuccess("");

    // Basic validation
    const errs = {};
    if (!currentPassword || `${currentPassword}`.trim() === "") {
      errs.oldPassword = "Required";
    }
    if (!newPassword || `${newPassword}`.trim() === "") {
      errs.newPassword = "Required";
    }
    if (newPassword !== confirmPassword) {
      errs.confirmPassword = "Passwords do not match";
    }
    if (Object.keys(errs).length) {
      setChangePwdErrors(errs);
      return;
    }

    setChangePwdLoading(true);
    try {
      const payload = {
        vendorId: vendor?.id,
        oldPassword: currentPassword,
        newPassword: newPassword,
      };

      const result = await vendorsAuthApi.changePassword(payload, token);
      // vendorsAuthApi returns parsed data or throws on non-2xx
      if (result) {
        setSuccess(result.message || "Password changed successfully.");
        setCurrentPassword("");
        setNewPassword("");
        setConfirmPassword("");
        setShowPasswordFields(false);
      }
    } catch (e) {
      const serverMsg = e?.response?.data?.message || e?.message;
      setError(
        typeof serverMsg === "string" ? serverMsg : "Failed to change password"
      );
    } finally {
      setChangePwdLoading(false);
    }
  };

  return (
    <div className="">
      <div className="p-3 border rounded bg-white">
        <h4 className="mb-3 fw-bold">Business Details</h4>

        <VerificationStatusBanner
          access={access}
          onAction={(action) => {
            if (action?.href) window.location.assign(action.href);
          }}
        />

        <div className="mb-3">
          <label className="form-label fs-16">Profile Image</label>
          <div className="d-flex align-items-start gap-3">
            <div className="d-flex flex-column align-items-center" style={{ width: 96, flex: "0 0 96px" }}>
              <div className="position-relative" style={{ width: 96, height: 96 }}>
                {profileImagePreview &&
                typeof profileImagePreview === "string" ? (
                  <>
                    <img
                      src={profileImagePreview}
                      alt="Profile preview"
                      style={{
                        width: "96px",
                        height: "96px",
                        objectFit: "cover",
                        borderRadius: "50%",
                        border: "2px solid #fce7f3",
                      }}
                      onError={(e) => {
                        console.error(
                          "Failed to load profile image:",
                          profileImagePreview
                        );
                        e.target.style.display = "none";
                      }}
                    />
                    <button
                      type="button"
                      className="btn btn-sm btn-danger position-absolute p-0 d-flex align-items-center justify-content-center shadow"
                      style={{
                        bottom: "2px",
                        right: "2px",
                        width: "24px",
                        height: "24px",
                        borderRadius: "50%",
                        border: "2px solid #ffffff",
                        fontSize: "11px",
                        lineHeight: 1,
                      }}
                      onClick={handleRemoveImage}
                      title="Remove image"
                    >
                      ✕
                    </button>
                  </>
                ) : (
                  <div
                    style={{
                      width: "96px",
                      height: "96px",
                      borderRadius: "50%",
                      background: "#fff1f6",
                      color: "#ed1173",
                      border: "1px solid #fce7f3",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      fontWeight: 700,
                      fontSize: "1.5rem",
                    }}
                  >
                    {((vendor?.businessName || "")[0] || "U").toUpperCase()}
                  </div>
                )}
              </div>
              {profileImagePreview && (
                <button
                  type="button"
                  className="btn btn-link text-danger p-0 mt-1 text-decoration-none fw-semibold"
                  style={{ fontSize: "0.78rem" }}
                  onClick={handleRemoveImage}
                >
                  Remove
                </button>
              )}
            </div>
            <div
              className={`border rounded-3 p-3 text-center fs-14 ${
                isDragging ? "border-primary" : ""
              }`}
              style={{
                borderStyle: "dashed",
                cursor: "pointer",
                borderColor: profileImageError
                  ? "#ef4444"
                  : isDragging
                  ? "#2563eb"
                  : "#cbd5e1",
                backgroundColor: isDragging ? "#eff6ff" : "#f8fafc",
                transition: "all 0.2s ease",
              }}
              onClick={() => document.getElementById("profileUpload").click()}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
            >
              <p className="mb-1 fw-bold text-dark">Upload Profile Image</p>
              <p className="text-muted small mb-1">
                Drag & drop or click to browse
              </p>
              <span
                className="badge bg-light text-secondary border px-2 py-1"
                style={{ fontSize: "0.75rem", fontWeight: "500" }}
              >
                Max size: {MAX_FILE_SIZE_MB} MB (JPG, PNG, WEBP)
              </span>

              <input
                type="file"
                id="profileUpload"
                accept="image/png, image/jpeg, image/jpg, image/webp"
                className="d-none fs-14"
                onChange={handleProfileImage}
              />

              {profileImageError && (
                <p className="small text-danger mt-2 mb-0 fw-semibold">
                  ⚠️ {profileImageError}
                </p>
              )}
            </div>

            {/* Uploaded File Status Card in HappyWedz Theme */}
            {profileImageFile && !profileImageError && (
              <div
                className="p-3 rounded-3 border d-flex align-items-center gap-3 shadow-sm flex-grow-1 animate__animated animate__fadeIn"
                style={{
                  backgroundColor: "#fff1f6",
                  borderColor: "#fce7f3",
                  minWidth: "260px",
                  maxWidth: "400px",
                  transition: "all 0.2s ease",
                }}
              >
                <div
                  style={{
                    width: "38px",
                    height: "38px",
                    borderRadius: "50%",
                    backgroundColor: "#ed1173",
                    color: "#ffffff",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontWeight: "bold",
                    fontSize: "1rem",
                    flexShrink: 0,
                    boxShadow: "0 2px 6px rgba(237, 17, 115, 0.25)",
                  }}
                >
                  ✓
                </div>
                <div className="min-w-0 flex-grow-1">
                  <h6 className="mb-0 fw-bold text-dark fs-14 text-truncate">
                    {profileImageFile.name}
                  </h6>
                  <p className="mb-0 fw-semibold fs-12" style={{ color: "#ed1173" }}>
                    {(profileImageFile.size / (1024 * 1024)).toFixed(2)} MB • Image Ready
                  </p>
                </div>
                <button
                  type="button"
                  className="btn-close btn-sm ms-auto"
                  onClick={(e) => {
                    e.stopPropagation();
                    setProfileImageFile(null);
                  }}
                  title="Remove selected image"
                />
              </div>
            )}
          </div>
          {profileImageError && (
            <div className="text-danger small mt-2">{profileImageError}</div>
          )}
        </div>
        <div className="mb-3">
          <label className="form-label fs-16">Business Name *</label>
          <input
            name="businessName"
            type="text"
            className="form-control fs-14"
            placeholder="Enter business name"
            value={formData.attributes?.businessName || ""}
            onChange={handleAttributeChange}
          />
          {validationErrors.businessName && (
            <div className="text-danger small">
              {validationErrors.businessName}
            </div>
          )}
        </div>
        <div className="mb-3">
          <label className="form-label fs-16">Email *</label>
          <input
            name="email"
            type="email"
            className="form-control fs-14"
            placeholder="Enter email"
            value={formData.attributes?.email || ""}
            onChange={handleAttributeChange}
          />
          {validationErrors.email && (
            <div className="text-danger small">{validationErrors.email}</div>
          )}
        </div>
        <div className="mb-3">
          <label className="form-label fs-16">Mobile Number *</label>
          <input
            name="phone"
            type="text"
            className="form-control fs-14"
            placeholder="Enter phone number"
            value={formData.attributes?.phone || ""}
            onChange={handleAttributeChange}
          />
          {validationErrors.phone && (
            <div className="text-danger small">{validationErrors.phone}</div>
          )}
        </div>
        {/* <div className="mb-3">
          <label className="form-label fs-16">Mobile Number</label>
          <input
            name="mobile"
            type="text"
            className="form-control fs-14"
            placeholder="Enter mobile number"
            value={formData.attributes?.mobile || ""}
            onChange={handleAttributeChange}
          />
        </div> */}
        {/* <div className="mb-3">
          <label className="form-label fs-16">Fax</label>
          <input
            type="text"
            className="form-control fs-14"
            placeholder="Enter fax number"
          />
        </div> */}
        <div className="mb-3">
          <label className="form-label fs-16">City</label>
          <input
            name="city"
            type="text"
            className="form-control fs-14"
            placeholder="Enter city"
            value={formData.attributes?.city || ""}
            onChange={handleAttributeChange}
          />
          {validationErrors.city && (
            <div className="text-danger small">{validationErrors.city}</div>
          )}
        </div>
        <div className="mb-3">
          <label className="form-label fs-16">State</label>
          <input
            name="state"
            type="text"
            className="form-control fs-14"
            placeholder="Enter state"
            value={formData.attributes?.state || ""}
            onChange={handleAttributeChange}
          />
        </div>
        <div className="mb-3">
          <label className="form-label fs-16">Zip</label>
          <input
            name="zip"
            type="text"
            className="form-control fs-14"
            placeholder="Enter zip"
            value={formData.attributes?.zip || ""}
            onChange={handleAttributeChange}
          />
        </div>
        {/* <div>
          <label className="form-label fs-16">Website</label>
          <input
            name="website"
            type="url"
            className="form-control fs-14"
            placeholder="Enter website URL"
            value={formData.attributes?.website || ""}
            onChange={handleAttributeChange}
          />
        </div> */}
        {/* Social links moved to Social Network section */}
        <div className="mb-3">
          <input
            name="vendor_type_id"
            type="hidden"
            className="form-control fs-14"
            value={vendor?.vendor_type_id || ""}
            readOnly
          />
          <input
            type="hidden"
            name="vendor_type_id"
            value={vendor?.vendor_type_id || ""}
          />

          {validationErrors.vendor_type_id && (
            <div className="text-danger small">
              {validationErrors.vendor_type_id}
            </div>
          )}
        </div>

        <div className="mb-3">
          <label className="form-label fs-16">First Name</label>
          <input
            name="firstName"
            type="text"
            className="form-control fs-14"
            placeholder="First name"
            value={formData.attributes?.firstName || ""}
            onChange={handleAttributeChange}
          />
        </div>
        <div className="mb-3">
          <label className="form-label fs-16">Last Name</label>
          <input
            name="lastName"
            type="text"
            className="form-control fs-14"
            placeholder="Last name"
            value={formData.attributes?.lastName || ""}
            onChange={handleAttributeChange}
          />
        </div>
        {/* Hidden once the business is verified — there is nothing left to submit. */}
        {access && access.verificationStatus !== "approved" && (
          <BusinessDocumentsSection
            aadhaar={kyc.aadhaar}
            pan={kyc.pan}
            businessDocs={kyc.businessDocs}
            existing={existingDocs}
            errors={kycErrors}
            disabled={isUnderReview || submitting}
            onChange={updateKyc}
          />
        )}

        <div className="p-3 border rounded mb-4 bg-white">
          <h6 className="mb-3 fw-bold">Change Password</h6>
          {!showPasswordFields ? (
            <button
              type="button"
              className="btn btn-outline-secondary fs-14"
              onClick={() => {
                setShowPasswordFields(true);
                setError("");
                setSuccess("");
              }}
            >
              Change Password
            </button>
          ) : (
            <div>
              <div className="mb-3">
                <label className="form-label fs-16">Current Password</label>
                <input
                  type={showPasswords ? "text" : "password"}
                  className="form-control fs-14"
                  value={currentPassword}
                  onChange={(e) => setCurrentPassword(e.target.value)}
                />
                {changePwdErrors.oldPassword && (
                  <div className="text-danger small">
                    {changePwdErrors.oldPassword}
                  </div>
                )}
              </div>
              <div className="mb-3">
                <label className="form-label fs-16">New Password</label>
                <input
                  type={showPasswords ? "text" : "password"}
                  className="form-control fs-14"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                />
                {changePwdErrors.newPassword && (
                  <div className="text-danger small">
                    {changePwdErrors.newPassword}
                  </div>
                )}
                {newPassword ? (
                  <div className="small mt-1">
                    Strength:{" "}
                    <strong>{getPasswordStrength(newPassword)}</strong>
                  </div>
                ) : null}
              </div>
              <div className="mb-3">
                <label className="form-label fs-16">Confirm New Password</label>
                <input
                  type={showPasswords ? "text" : "password"}
                  className="form-control fs-14"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                />
                {changePwdErrors.confirmPassword && (
                  <div className="text-danger small">
                    {changePwdErrors.confirmPassword}
                  </div>
                )}
              </div>
              <div className="d-flex flex-column flex-md-row gap-2 align-items-md-center mt-2">
                <div className="d-flex align-items-center mb-2 mb-md-0">
                  <input
                    id="showPasswords"
                    type="checkbox"
                    className="form-check-input me-2"
                    checked={showPasswords}
                    onChange={(e) => setShowPasswords(e.target.checked)}
                    style={{ verticalAlign: "middle" }}
                  />
                  <label
                    htmlFor="showPasswords"
                    className="form-check-label mb-0 fs-14"
                  >
                    Show passwords
                  </label>
                </div>
                <button
                  type="button"
                  className="btn btn-sm btn-primary fs-14"
                  style={{ minWidth: 120 }}
                  onClick={handleChangePassword}
                  disabled={changePwdLoading}
                >
                  {changePwdLoading ? "Updating..." : "Update Password"}
                </button>
                <button
                  type="button"
                  className="btn btn-sm btn-outline-secondary fs-14"
                  style={{ minWidth: 100 }}
                  onClick={() => {
                    setShowPasswordFields(false);
                    setCurrentPassword("");
                    setNewPassword("");
                    setConfirmPassword("");
                    setChangePwdErrors({});
                  }}
                >
                  Cancel
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
      {error && <div className="alert alert-danger mt-2">{error}</div>}
      {success && <div className="alert alert-success mt-2">{success}</div>}

      {/* One button, three meanings. While onboarding is outstanding, saving and
          submitting for verification are the same action from the vendor's point of
          view, so splitting them into two buttons would only invite half-submissions. */}
      {isUnderReview ? (
        <button className="btn btn-secondary mt-2 fs-14" disabled>
          Under review
        </button>
      ) : (
        <button
          className="btn btn-primary mt-2 fs-14"
          onClick={needsVerification ? handleSubmitVerification : handleSubmitRegister}
          disabled={submitting}
        >
          {submitting
            ? needsVerification
              ? "Submitting..."
              : "Saving..."
            : needsVerification
              ? "Submit for verification"
              : "Save Business Details"}
        </button>
      )}

      {needsVerification && !submitting && (
        <p className="text-muted small mt-2 mb-0">
          Your details and documents go to our verification team. You can add up to{" "}
          {MAX_BUSINESS_DOCS} business documents.
        </p>
      )}
    </div>
  );
};

export default BusinessDetails;
