import React, { useState, useEffect } from "react";
// (no redux selector needed in this form component)
import Swal from "sweetalert2";
import { IMAGE_BASE_URL } from "../../../../config/constants";
import { TbBookmarkEdit } from "react-icons/tb";
import { MdDeleteOutline } from "react-icons/md";

export default function PromoForm({ formData, setFormData, onSave }) {
  const [form, setForm] = useState({
    title: "",
    promoCode: "",
    type: "percentage",
    value: "",
    startDate: "",
    endDate: "",
    description: "",
    termsAccepted: false,
    active: true,
  });

  const [imagePreview, setImagePreview] = useState(null);
  const [imageFile, setImageFile] = useState(null);
  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);
  const [serverError, setServerError] = useState("");
  const [serverSuccess, setServerSuccess] = useState("");
  const [editingIndex, setEditingIndex] = useState(null);

  // If parent passed existing deals, prefill the form with the first deal
  useEffect(() => {
    if (Array.isArray(formData?.deals) && formData.deals.length > 0) {
      const d = formData.deals[0];
      setForm((s) => ({
        ...s,
        title: d.title || "",
        promoCode: d.code || d.promoCode || "",
        type: d.type || "percentage",
        value: d.value || "",
        startDate: d.startDate || "",
        endDate: d.endDate || "",
        description: d.description || "",
        active: typeof d.active === "boolean" ? d.active : true,
      }));
      // hydrate image preview if available
      if (d.imageName) {
        let preview = d.imageName;
        if (preview.startsWith("/uploads/")) preview = IMAGE_BASE_URL + preview;
        setImagePreview(preview);
      }
    }
  }, [formData?.deals]);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setForm((s) => ({ ...s, [name]: type === "checkbox" ? checked : value }));
  };

  const handleImage = (e) => {
    const file = e.target.files?.[0];
    setImageFile(file || null);
    if (!file) {
      setImagePreview(null);
      return;
    }
    const reader = new FileReader();
    reader.onload = (ev) => setImagePreview(ev.target.result);
    reader.readAsDataURL(file);
  };

  const validate = () => {
    const err = {};
    if (!form.title.trim()) err.title = "Title is required.";
    if (!form.promoCode.trim()) err.promoCode = "Promo code is required.";
    if (!form.value || isNaN(form.value) || Number(form.value) <= 0)
      err.value = "Enter a valid discount value.";
    if (!form.startDate) err.startDate = "Start date is required.";
    if (!form.endDate) err.endDate = "End date is required.";
    if (form.startDate && form.endDate && form.startDate > form.endDate)
      err.date = "End date must be after start date.";
    if (!form.termsAccepted) err.termsAccepted = "You must accept terms.";
    setErrors(err);
    return Object.keys(err).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;
    setSubmitting(true);
    setServerError("");
    setServerSuccess("");
    try {
      // merge this promo into storefront formData.deals for saving alongside service
      const newDeal = {
        title: form.title,
        code: form.promoCode,
        type: form.type,
        value: Number(form.value),
        startDate: form.startDate,
        endDate: form.endDate,
        description: form.description,
        active: !!form.active,
        imageName: imageFile?.name || null,
      };
      setFormData((prev) => {
        const existing = Array.isArray(prev.deals) ? [...prev.deals] : [];
        if (editingIndex !== null && existing[editingIndex]) {
          existing[editingIndex] = newDeal;
        } else {
          existing.push(newDeal);
        }
        return { ...prev, deals: existing };
      });
      // Let parent handle actual API via onSave (vendorServicesApi)
      await onSave?.();
      setServerSuccess("Promotion added to your service and saved.");
      const payload = { ...form, imageName: imageFile?.name || null };
      localStorage.setItem("promoDraft", JSON.stringify(payload));
    } catch (err) {
      setServerError(
        typeof err === "string" ? err : err?.message || "Failed to save",
      );
    } finally {
      setSubmitting(false);
    }
  };

  const resetForm = () => {
    setForm({
      title: "",
      promoCode: "",
      type: "percentage",
      value: "",
      startDate: "",
      endDate: "",
      description: "",
      termsAccepted: false,
      active: true,
    });
    setImageFile(null);
    setImagePreview(null);
    setErrors({});
  };

  const handleEditDeal = (index) => {
    const deal = formData?.deals?.[index];
    if (!deal) return;
    setForm({
      title: deal.title || "",
      promoCode: deal.code || deal.promoCode || "",
      type: deal.type || "percentage",
      value: deal.value || "",
      startDate: deal.startDate || "",
      endDate: deal.endDate || "",
      description: deal.description || "",
      termsAccepted: true,
      active: typeof deal.active === "boolean" ? deal.active : true,
    });
    if (deal.imageName) {
      let preview = deal.imageName;
      if (preview.startsWith("/uploads/")) preview = IMAGE_BASE_URL + preview;
      setImagePreview(preview);
    } else setImagePreview(null);
    setEditingIndex(index);
  };

  const handleDeleteDeal = async (index) => {
    if (!Array.isArray(formData?.deals)) return;
    const confirmed = await Swal.fire({
      title: "Delete this promotion?",
      text: "This will remove the offer from your storefront.",
      icon: "warning",
      showCancelButton: true,
      confirmButtonColor: "#d33",
      cancelButtonColor: "#3085d6",
      confirmButtonText: "Yes, delete it",
    });
    if (!confirmed.isConfirmed) return;
    const updated = formData.deals.filter((_, i) => i !== index);
    setFormData((prev) => ({ ...prev, deals: updated }));
    try {
      await onSave?.();
      Swal.fire({
        icon: "success",
        title: "Deleted",
        timer: 1200,
        showConfirmButton: false,
      });
    } catch (err) {
      Swal.fire({
        icon: "error",
        title: "Delete failed",
        text: err?.message || String(err),
      });
    }
  };

  const formattedValue = () =>
    form.type === "percentage" ? `${form.value}% off` : `₹ ${form.value} off`;

  return (
    <div className="promo-form-container my-5">
      <div className="promo-form-wrapper">
        <div className="form-section">
          <div className="form-card">
            <h4 className="fw-bold">Promotion Details</h4>
            <p className="form-description fs-14">
              Fill in the details of your special offer for couples
            </p>

            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="fs-16">Offer Title</label>
                <input
                  name="title"
                  value={form.title}
                  onChange={handleChange}
                  className={`form-control fs-14 ${
                    errors.title ? "error" : ""
                  }`}
                  placeholder="placeholder for offer"
                />
                {errors.title && (
                  <div className="error-message">{errors.title}</div>
                )}
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label className="fs-16">Promo Code</label>
                  <input
                    name="promoCode"
                    value={form.promoCode}
                    onChange={handleChange}
                    className={`form-control fs-14 ${
                      errors.promoCode ? "error" : ""
                    }`}
                    placeholder="E.g. WWCOUPLE10"
                  />
                  {errors.promoCode && (
                    <div className="error-message">{errors.promoCode}</div>
                  )}
                </div>

                <div className="form-group">
                  <label className="fs-16">Status</label>
                  <div className="switch-container">
                    <label className="switch" style={{ position: "relative" }}>
                      <input
                        type="checkbox"
                        className="fs-14"
                        name="active"
                        checked={form.active}
                        onChange={handleChange}
                      />
                      <span className="slider round fs-10 text-black">
                        <span
                          style={{
                            position: "absolute",
                            left: form.active ? "calc(100% - 65px)" : "5px",
                            top: "50%",
                            transform: "translateY(-50%)",
                            fontSize: "12px",
                            color: form.active ? "#fff" : "#fff",
                            width: "60px",
                            textAlign: "center",
                            transition: "left 0.2s",
                            pointerEvents: "none",
                          }}
                        >
                          {form.active ? "YES" : "NO"}
                        </span>
                      </span>
                    </label>
                  </div>
                </div>
              </div>

              <div className="form-row">
                <div className="form-group fs-14">
                  <label className="fs-16">Discount Type</label>
                  <select
                    name="type"
                    value={form.type}
                    onChange={handleChange}
                    className="form-control fs-14"
                  >
                    <option value="percentage">Percentage</option>
                    <option value="fixed">Fixed amount</option>
                  </select>
                </div>

                <div className="form-group">
                  <label className="fs-16">Discount Value</label>
                  <div className="input-with-icon fs-14">
                    <span className="input-icon fs-14">
                      {form.type === "percentage" ? "%" : "₹"}
                    </span>
                    <input
                      name="value"
                      value={form.value}
                      onChange={handleChange}
                      className={`form-control fs-14 ${
                        errors.value ? "error" : ""
                      }`}
                      placeholder={form.type === "percentage" ? "10" : "500"}
                    />
                  </div>
                  {errors.value && (
                    <div className="error-message">{errors.value}</div>
                  )}
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label className="fs-16">Start Date</label>
                  <input
                    name="startDate"
                    type="date"
                    value={form.startDate}
                    onChange={handleChange}
                    className={`form-control fs-14 ${
                      errors.startDate || errors.date ? "error" : ""
                    }`}
                  />
                  {errors.startDate && (
                    <div className="error-message">{errors.startDate}</div>
                  )}
                </div>

                <div className="form-group">
                  <label className="fs-16">End Date</label>
                  <input
                    name="endDate"
                    type="date"
                    value={form.endDate}
                    onChange={handleChange}
                    className={`form-control fs-14 ${
                      errors.endDate || errors.date ? "error" : ""
                    }`}
                  />
                  {(errors.endDate || errors.date) && (
                    <div className="error-message">
                      {errors.endDate || errors.date}
                    </div>
                  )}
                </div>
              </div>

              <div className="form-group">
                <label className="fs-16">Description</label>
                <textarea
                  name="description"
                  value={form.description}
                  onChange={handleChange}
                  rows="3"
                  className="form-control fs-14"
                  placeholder="Short note about terms or what customers get"
                />
              </div>

              {/* <div className="form-group">
                <label className="fs-16">Promotion Image</label>
                <div className="file-upload">
                  <label className="file-upload-label">
                    <input
                      type="file"
                      accept="image/*"
                      onChange={handleImage}
                      className="file-input fs-14"
                    />
                    <span className="file-upload-button">Choose File</span>
                    <span className="file-name">
                      {imageFile ? imageFile.name : "No file chosen"}
                    </span>
                  </label>
                  <small className="file-hint">
                    Recommended size: 800x400px (JPG, PNG)
                  </small>
                </div>
              </div> */}

              <div className="form-group terms-group" style={{ marginTop: 25 }}>
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: "12px",
                    minHeight: "28px",
                  }}
                >
                  <label
                    className="checkbox-container fs-14"
                    style={{
                      marginBottom: 0,
                      display: "flex",
                      alignItems: "center",
                      gap: "8px",
                    }}
                  >
                    <input
                      type="checkbox"
                      className="fs-14"
                      name="termsAccepted"
                      checked={form.termsAccepted}
                      onChange={handleChange}
                      style={{ margin: 0 }}
                    />
                    <span
                      className={`checkmark fs-14 ${
                        errors.termsAccepted ? "error" : ""
                      }`}
                    ></span>
                    <span
                      className="d-flex align-items-center"
                      style={{ marginTop: "6px" }}
                    >
                      I confirm this offer and its terms
                    </span>
                  </label>
                  {errors.termsAccepted && (
                    <div
                      className="error-message"
                      style={{
                        marginLeft: "12px",
                        marginBottom: 0,
                        whiteSpace: "nowrap",
                      }}
                    >
                      {errors.termsAccepted}
                    </div>
                  )}
                </div>
              </div>

              <div className="form-actions">
                <button
                  type="submit"
                  className="btn-primary folder-item fs-14"
                  style={{
                    background:
                      "linear-gradient(135deg, #ff6b9d 0%, #e91e63 100%)",
                  }}
                  disabled={submitting}
                >
                  {submitting ? "Saving..." : "Save Promotion"}
                </button>

                <button
                  type="button"
                  className="btn-secondary folder-item fs-14"
                  onClick={resetForm}
                  style={{
                    display: "flex",
                    justifyContent: "center",
                    textAlign: "center",
                  }}
                >
                  Reset
                </button>
              </div>
            </form>

            {serverError && (
              <div className="alert alert-danger mt-3">{serverError}</div>
            )}
            {serverSuccess && (
              <div className="alert alert-success mt-3">{serverSuccess}</div>
            )}
          </div>
        </div>

        <div className="preview-section">
          <div className="preview-card">
            {Array.isArray(formData?.deals) && formData.deals.length > 0 && (
              <div className="existing-deals-list mb-3">
                <h6>Existing Offers</h6>
                <div className="list-group">
                  {formData.deals.map((d, i) => (
                    <div
                      key={i}
                      className="d-flex align-items-center justify-content-between p-2 border mb-2 rounded"
                    >
                      <div>
                        <strong className="fs-16">
                          {d.title || d.name || `Offer ${i + 1}`}
                        </strong>
                        <div className="text-muted small fs-14">
                          Code: {d.code || d.promoCode || "-"}
                        </div>
                        <div className="text-muted small fs-14">
                          {d.startDate || "-"} — {d.endDate || "-"}
                        </div>
                      </div>
                      <div style={{ display: "flex", gap: 8 }}>
                        <button
                          type="button"
                          className="btn btn-sm btn-outline-primary  fs-14"
                          onClick={() => handleEditDeal(i)}
                        >
                          <TbBookmarkEdit />
                        </button>
                        <button
                          type="button"
                          className="btn btn-sm btn-outline-danger"
                          onClick={() => handleDeleteDeal(i)}
                        >
                          <MdDeleteOutline />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
            {/* <div className="preview-header">
              <h3>Promotion Preview</h3>
              <p>This is how couples will see your offer</p>
            </div>

            <div className="promo-preview">
              <div className="preview-content">
                <div className="preview-top">
                  <div>
                    <h4>{form.title || "Promotion title"}</h4>
                    <div className="promo-code">
                      {form.promoCode || "PROMOCODE"}
                    </div>
                  </div>
                  <div className="discount-badge">{formattedValue()}</div>
                </div>

                <div className="preview-image">
                  {imagePreview ? (
                    <img
                      src={imagePreview}
                      alt="promo"
                      className="preview-img"
                    />
                  ) : (
                    <div className="image-placeholder">
                      <div className="placeholder-icon">
                        <svg
                          width="151px"
                          height="151px"
                          viewBox="0 0 24 24"
                          fill="none"
                          xmlns="http://www.w3.org/2000/svg"
                        >
                          <g id="SVGRepo_bgCarrier" strokeWidth="0"></g>
                          <g
                            id="SVGRepo_tracerCarrier"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          ></g>
                          <g id="SVGRepo_iconCarrier">
                            {" "}
                            <circle
                              cx="12"
                              cy="13"
                              r="3"
                              stroke="#1C274C"
                              strokeWidth="1.5"
                            ></circle>{" "}
                            <path
                              d="M2 13.3636C2 10.2994 2 8.76721 2.74902 7.6666C3.07328 7.19014 3.48995 6.78104 3.97524 6.46268C4.69555 5.99013 5.59733 5.82123 6.978 5.76086C7.63685 5.76086 8.20412 5.27068 8.33333 4.63636C8.52715 3.68489 9.37805 3 10.3663 3H13.6337C14.6219 3 15.4728 3.68489 15.6667 4.63636C15.7959 5.27068 16.3631 5.76086 17.022 5.76086C18.4027 5.82123 19.3044 5.99013 20.0248 6.46268C20.51 6.78104 20.9267 7.19014 21.251 7.6666C22 8.76721 22 10.2994 22 13.3636C22 16.4279 22 17.9601 21.251 19.0607C20.9267 19.5371 20.51 19.9462 20.0248 20.2646C18.9038 21 17.3433 21 14.2222 21H9.77778C6.65675 21 5.09624 21 3.97524 20.2646C3.48995 19.9462 3.07328 19.5371 2.74902 19.0607C2.53746 18.7498 2.38566 18.4045 2.27673 18"
                              stroke="#1C274C"
                              strokeWidth="1.5"
                              strokeLinecap="round"
                            ></path>{" "}
                            <path
                              d="M19 10H18"
                              stroke="#1C274C"
                              strokeWidth="1.5"
                              strokeLinecap="round"
                            ></path>{" "}
                          </g>
                        </svg>
                      </div>
                      <p>Promotion image preview</p>
                    </div>
                  )}
                </div>

                <div className="preview-dates">
                  <span className="date-label">Valid:</span>
                  <span className="dates">
                    {form.startDate || "Start"} — {form.endDate || "End"}
                  </span>
                </div>

                <div className="preview-description">
                  <p>
                    {form.description ||
                      "Short description of the offer appears here."}
                  </p>
                  <p className="terms-note">
                    Terms apply. See full terms on booking.
                  </p>
                </div>

                <div className="preview-actions">
                  <button
                    className="btn-primary folder-item"
                    style={{
                      background:
                        "linear-gradient(135deg, #ff6b9d 0%, #e91e63 100%)",
                    }}
                  >
                    Save Promotion
                  </button>
                  <button
                    className="action-button folder-item text-center"
                    style={{
                      display: "flex",
                      justifyContent: "center",
                      textAlign: "center",
                    }}
                  >
                    Share Offer
                  </button>
                </div>
              </div>
            </div> */}
          </div>
        </div>
      </div>
    </div>
  );
}
