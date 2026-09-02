import React, { useState, useEffect } from "react";
import Swal from "sweetalert2";
import { MdEdit, MdDeleteOutline } from "react-icons/md";

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

  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);
  const [serverError, setServerError] = useState("");
  const [serverSuccess, setServerSuccess] = useState("");
  const [editingIndex, setEditingIndex] = useState(null);
  const hasHydrated = React.useRef(false);

  // On first load only, prefill the form with the first existing deal so the
  // form isn't blank when there's nothing else to show. This must not re-run
  // on every `deals` change, otherwise adding/editing a promotion snaps the
  // form back to the first deal's values right after saving.
  useEffect(() => {
    if (hasHydrated.current) return;
    if (Array.isArray(formData?.deals) && formData.deals.length > 0) {
      hasHydrated.current = true;
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
        termsAccepted: true,
        active: typeof d.active === "boolean" ? d.active : true,
      }));
    }
  }, [formData]);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setForm((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));
    if (errors[name]) setErrors((prev) => ({ ...prev, [name]: "" }));
  };

  const validate = () => {
    const errs = {};
    if (!form.title || !form.title.trim())
      errs.title = "Offer title is required.";
    if (!form.promoCode || !form.promoCode.trim())
      errs.promoCode = "Promo code is required.";
    if (!form.value || isNaN(form.value) || Number(form.value) <= 0)
      errs.value = "Enter a valid positive discount value.";
    if (!form.startDate) errs.startDate = "Start date is required.";
    if (!form.endDate) errs.endDate = "End date is required.";
    if (form.startDate && form.endDate) {
      const s = new Date(form.startDate);
      const e = new Date(form.endDate);
      if (s > e) errs.date = "End date cannot be earlier than start date.";
    }
    if (!form.termsAccepted)
      errs.termsAccepted = "You must confirm this offer.";
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setServerError("");
    setServerSuccess("");
    if (!validate()) return;
    setSubmitting(true);

    try {
      const dealObject = {
        title: form.title,
        code: form.promoCode,
        type: form.type,
        value: form.value,
        startDate: form.startDate,
        endDate: form.endDate,
        description: form.description,
        active: form.active,
      };

      const existingDeals = Array.isArray(formData?.deals)
        ? [...formData.deals]
        : [];
      if (editingIndex !== null && existingDeals[editingIndex]) {
        existingDeals[editingIndex] = dealObject;
      } else {
        existingDeals.push(dealObject);
      }

      setFormData((prev) => ({ ...prev, deals: existingDeals }));

      if (onSave) {
        await onSave({ ...formData, deals: existingDeals });
      }

      setServerSuccess("Promotion saved successfully.");
      Swal.fire({
        icon: "success",
        title: "Saved!",
        text: "Promotion details updated successfully.",
        timer: 1500,
        showConfirmButton: false,
      });
      setEditingIndex(null);
      resetForm();
      const existing = Array.isArray(formData?.deals)
        ? [...formData.deals]
        : [];
      if (editingIndex !== null && existing[editingIndex]) {
        existing[editingIndex] = newDeal;
      } else {
        existing.push(newDeal);
      }
      setFormData((prev) => ({ ...prev, deals: existing }));
      // Let parent handle actual API via onSave (vendorServicesApi). Pass the
      // fresh deals array directly so the save doesn't race the setFormData
      // update above (parent's formData snapshot updates asynchronously).
      await onSave?.({ deals: existing });
      setServerSuccess("Promotion added to your service and saved.");
      resetForm();
    } catch (err) {
      console.error(err);
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
    setErrors({});
    setEditingIndex(null);
    setEditingIndex(null);
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
    setEditingIndex(index);
  };

  const handleDeleteDeal = async (index) => {
    if (!Array.isArray(formData?.deals)) return;
    const confirmed = await Swal.fire({
      title: "Delete this promotion?",
      text: "This will remove the offer from your storefront.",
      icon: "warning",
      showCancelButton: true,
      confirmButtonColor: "#ed1173",
      cancelButtonColor: "#64748b",
      confirmButtonText: "Yes, delete it",
    });
    if (!confirmed.isConfirmed) return;
    const updated = formData.deals.filter((_, i) => i !== index);
    setFormData((prev) => ({ ...prev, deals: updated }));
    try {
      await onSave?.({ ...formData, deals: updated });
      // Pass the fresh deals array directly so this doesn't race the
      // setFormData update above.
      await onSave?.({ deals: updated });
      if (editingIndex === index) {
        resetForm();
      } else if (editingIndex !== null && editingIndex > index) {
        setEditingIndex(editingIndex - 1);
      }
      Swal.fire({
        icon: "success",
        title: "Deleted",
        timer: 1200,
        showConfirmButton: false,
      });
      if (editingIndex === index) {
        resetForm();
      }
    } catch (err) {
      Swal.fire({
        icon: "error",
        title: "Delete failed",
        text: err?.message || String(err),
      });
    }
  };

  const existingDealsList = Array.isArray(formData?.deals)
    ? formData.deals
    : [];

  return (
    <div className="my-5">
      <div className="p-3 border rounded bg-white">
        <div className="d-flex align-items-center justify-content-between mb-3">
          <h4 className="mb-0 fw-bold">Promotion Details</h4>
          {editingIndex !== null && (
            <span className="badge bg-light text-primary border fs-12">
              Editing Offer #{editingIndex + 1}
            </span>
          )}
        </div>

        <form onSubmit={handleSubmit}>
          <div className="row">
            {/* Offer Title */}
            <div className="col-md-6 mb-3">
              <label className="form-label fs-16 fw-semibold">
                Offer Title *
              </label>
              <input
                type="text"
                name="title"
                value={form.title}
                onChange={handleChange}
                className={`form-control fs-14 ${
                  errors.title ? "is-invalid" : ""
                }`}
                placeholder="Enter offer title"
              />
              {errors.title && (
                <div className="text-danger small mt-1">{errors.title}</div>
              )}
            </div>

            {/* Promo Code */}
            <div className="col-md-6 mb-3">
              <label className="form-label fs-16 fw-semibold">
                Promo Code *
              </label>
              <input
                type="text"
                name="promoCode"
                value={form.promoCode}
                onChange={handleChange}
                className={`form-control fs-14 text-uppercase ${
                  errors.promoCode ? "is-invalid" : ""
                }`}
                placeholder="e.g. WEDDING10"
              />
              {errors.promoCode && (
                <div className="text-danger small mt-1">{errors.promoCode}</div>
              )}
            </div>

            {/* Discount Type */}
            <div className="col-md-6 mb-3">
              <label className="form-label fs-16 fw-semibold">
                Discount Type
              </label>
              <select
                name="type"
                value={form.type}
                onChange={handleChange}
                className="form-control fs-14"
              >
                <option value="percentage">Percentage (%)</option>
                <option value="fixed">Fixed Amount (₹)</option>
              </select>
            </div>

            {/* Discount Value */}
            <div className="col-md-6 mb-3">
              <label className="form-label fs-16 fw-semibold">
                Discount Value *
              </label>
              <div className="input-group">
                <span className="input-group-text fs-14 bg-light text-muted">
                  {form.type === "percentage" ? "%" : "₹"}
                </span>
                <input
                  type="text"
                  name="value"
                  value={form.value}
                  onChange={handleChange}
                  className={`form-control fs-14 ${
                    errors.value ? "is-invalid" : ""
                  }`}
                  placeholder={form.type === "percentage" ? "10" : "5000"}
                />
              </div>
              {errors.value && (
                <div className="text-danger small mt-1">{errors.value}</div>
              )}
            </div>

            {/* Start Date */}
            <div className="col-md-6 mb-3">
              <label className="form-label fs-16 fw-semibold">
                Start Date *
              </label>
              <input
                type="date"
                name="startDate"
                value={form.startDate}
                onChange={handleChange}
                className={`form-control fs-14 ${
                  errors.startDate || errors.date ? "is-invalid" : ""
                }`}
              />
              {errors.startDate && (
                <div className="text-danger small mt-1">{errors.startDate}</div>
              )}
            </div>

            {/* End Date */}
            <div className="col-md-6 mb-3">
              <label className="form-label fs-16 fw-semibold">End Date *</label>
              <input
                type="date"
                name="endDate"
                value={form.endDate}
                onChange={handleChange}
                className={`form-control fs-14 ${
                  errors.endDate || errors.date ? "is-invalid" : ""
                }`}
              />
              {(errors.endDate || errors.date) && (
                <div className="text-danger small mt-1">
                  {errors.endDate || errors.date}
                </div>
              )}
            </div>

            {/* Description */}
            <div className="col-12 mb-3">
              <label className="form-label fs-16 fw-semibold">
                Description
              </label>
              <textarea
                name="description"
                value={form.description}
                onChange={handleChange}
                rows="3"
                className="form-control fs-14"
                placeholder="Enter description or special terms for this offer"
              />
            </div>

            {/* Status Switch */}
            <div className="col-md-6 mb-3">
              <label className="form-label fs-16 fw-semibold d-block">
                Status
              </label>
              <div className="form-check form-switch d-flex align-items-center gap-2 pt-1">
                <input
                  type="checkbox"
                  className="form-check-input"
                  role="switch"
                  id="promoStatusSwitch"
                  name="active"
                  checked={form.active}
                  onChange={handleChange}
                  style={{
                    cursor: "pointer",
                    width: "2.5em",
                    height: "1.3em",
                  }}
                />
                <label
                  htmlFor="promoStatusSwitch"
                  className="form-check-label fs-14 fw-medium text-muted cursor-pointer"
                >
                  {form.active ? "Active" : "Inactive"}
                </label>
              </div>
            </div>

            {/* Confirmation Checkbox */}
            <div className="col-12 mb-3">
              <div className="form-check d-flex align-items-center gap-2">
                <input
                  type="checkbox"
                  className="form-check-input mt-0"
                  id="termsCheck"
                  name="termsAccepted"
                  checked={form.termsAccepted}
                  onChange={handleChange}
                  style={{
                    accentColor: "#ed1173",
                    width: 18,
                    height: 18,
                    cursor: "pointer",
                  }}
                />
                <label
                  htmlFor="termsCheck"
                  className="form-check-label fs-14 text-muted cursor-pointer mb-0"
                >
                  I confirm this offer and its terms
                </label>
              </div>
              {errors.termsAccepted && (
                <div className="text-danger small mt-1">
                  {errors.termsAccepted}
                </div>
              )}
            </div>
          </div>

          <div className="d-flex align-items-center gap-2 mt-2">
            <button
              className="btn btn-primary fs-14"
              type="submit"
              disabled={submitting}
            >
              {submitting
                ? "Saving..."
                : editingIndex !== null
                  ? "Update Promotion"
                  : "Save Promotion"}
            </button>

            {editingIndex !== null && (
              <button
                className="btn btn-outline-secondary fs-14"
                type="button"
                onClick={resetForm}
              >
                Cancel Edit
              </button>
            )}
          </div>
        </form>

        {serverError && (
          <div className="alert alert-danger mt-3 mb-0 fs-14">
            {serverError}
          </div>
        )}
        {serverSuccess && (
          <div className="alert alert-success mt-3 mb-0 fs-14">
            {serverSuccess}
          </div>
        )}

        {/* Existing Offers Section inside the same standard card */}
        {existingDealsList.length > 0 && (
          <div className="mt-4 pt-3 border-top">
            <h5 className="mb-3 fw-bold">Existing Offers</h5>
            <div className="table-responsive">
              <table className="table table-hover align-middle mb-0">
                <thead className="table-light fs-14">
                  <tr>
                    <th>Offer Title</th>
                    <th>Promo Code</th>
                    <th>Discount</th>
                    <th>Validity Period</th>
                    <th>Status</th>
                    <th
                      className="text-end"
                      style={{ width: "120px", whiteSpace: "nowrap" }}
                    >
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="fs-14">
                  {existingDealsList.map((d, i) => (
                    <tr
                      key={i}
                      className={editingIndex === i ? "table-light" : ""}
                    >
                      <td className="fw-semibold">
                        {d.title || d.name || `Offer ${i + 1}`}
                      </td>
                      <td>
                        <code className="fw-bold text-dark bg-light px-2 py-1 rounded border">
                          {d.code || d.promoCode || "-"}
                        </code>
                      </td>
                      <td>
                        <span className="badge bg-success-subtle text-success border border-success-subtle px-2 py-1">
                          {d.type === "percentage"
                            ? `${d.value}% OFF`
                            : `₹${Number(d.value).toLocaleString()} OFF`}
                        </span>
                      </td>
                      <td
                        className="text-muted small"
                        style={{ whiteSpace: "nowrap" }}
                      >
                        {d.startDate || "-"} — {d.endDate || "-"}
                      </td>
                      <td>
                        <span
                          className={`badge ${
                            d.active !== false
                              ? "bg-primary-subtle text-primary border border-primary-subtle"
                              : "bg-secondary-subtle text-secondary border"
                          }`}
                        >
                          {d.active !== false ? "Active" : "Inactive"}
                        </span>
                      </td>
                      <td className="text-end" style={{ whiteSpace: "nowrap" }}>
                        <div className="d-inline-flex align-items-center justify-content-end gap-2">
                          <button
                            type="button"
                            className="btn btn-sm btn-outline-primary d-inline-flex align-items-center justify-content-center"
                            onClick={() => handleEditDeal(i)}
                            title="Edit Offer"
                            style={{
                              width: "32px",
                              height: "32px",
                              borderRadius: "6px",
                              padding: 0,
                            }}
                          >
                            <MdEdit size={16} />
                          </button>
                          <button
                            type="button"
                            className="btn btn-sm btn-outline-danger d-inline-flex align-items-center justify-content-center"
                            onClick={() => handleDeleteDeal(i)}
                            title="Delete Offer"
                            style={{
                              width: "32px",
                              height: "32px",
                              borderRadius: "6px",
                              padding: 0,
                            }}
                          >
                            <MdDeleteOutline size={17} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
