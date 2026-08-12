import React, { useEffect } from "react";
import { useSelector, useDispatch } from "react-redux";
import vendorsAuthApi, {
  vendorsApi,
} from "../../../../services/api/vendorAuthApi";
import { setVendor } from "../../../../redux/vendorAuthSlice";

const BusinessDetails = ({ formData, setFormData }) => {
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
  const [validationErrors, setValidationErrors] = React.useState({});

  const { vendor, token } = useSelector((state) => state.vendorAuth || {});
  const dispatch = useDispatch();

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

  const handleProfileImage = (e) => {
    const file = e.target.files?.[0] || null;
    setProfileImageFile(file);
  };

  // Build preview URL when file changes, or use existing vendor image when available
  React.useEffect(() => {
    let objectUrl;
    if (profileImageFile) {
      objectUrl = URL.createObjectURL(profileImageFile);
      setProfileImagePreview(objectUrl);
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
        // Fix the URL path if it has /src/uploads/ instead of /uploads/
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
  }, [profileImageFile, vendor]);

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
      setSuccess("Business details saved.");
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
        <h4 className="mb-3 fw-bold">Bussiness Details</h4>
        <div className="mb-3">
          <label className="form-label fs-16">Profile Image</label>
          <div className="d-flex align-items-center gap-3">
            <div style={{ width: 96, height: 96, flex: "0 0 96px" }}>
              {profileImagePreview &&
              typeof profileImagePreview === "string" ? (
                <img
                  src={profileImagePreview}
                  alt="Profile preview"
                  style={{
                    width: "96px",
                    height: "96px",
                    objectFit: "cover",
                    borderRadius: "50%",
                    border: "1px solid #e5e7eb",
                  }}
                  onError={(e) => {
                    console.error(
                      "Failed to load profile image:",
                      profileImagePreview
                    );
                    e.target.style.display = "none";
                  }}
                  onLoad={() => {
                    console.log(
                      "Profile image loaded successfully:",
                      profileImagePreview
                    );
                  }}
                />
              ) : (
                <div
                  style={{
                    width: "96px",
                    height: "96px",
                    borderRadius: "50%",
                    background: "#f3f4f6",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    color: "#6b7280",
                    fontWeight: 600,
                  }}
                >
                  {((vendor?.businessName || "")[0] || "U").toUpperCase()}
                </div>
              )}
            </div>
            <div
              className="border rounded-3 p-2 text-center fs-14"
              style={{ borderStyle: "dashed", cursor: "pointer" }}
              onClick={() => document.getElementById("profileUpload").click()}
            >
              <p className="mb-1 fw-bold">Upload Profile Image</p>
              <p className="text-muted small mb-2">
                Drag & drop or click to browse
              </p>

              <input
                type="file"
                id="profileUpload"
                accept="image/*"
                className="d-none fs-14"
                onChange={handleProfileImage}
              />

              {profileImageFile && (
                <p className="small text-success mt-1 fs-14">
                  Selected: {profileImageFile.name}
                </p>
              )}
            </div>
          </div>
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

      <button
        className="btn btn-primary mt-2 fs-14"
        onClick={handleSubmitRegister}
        disabled={submitting}
      >
        {submitting ? "Saving..." : "Save Business Details"}
      </button>
    </div>
  );
};

export default BusinessDetails;
