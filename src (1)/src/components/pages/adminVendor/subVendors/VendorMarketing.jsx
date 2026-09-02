import React, { useState } from "react";

const VendorMarketing = ({ formData, setFormData, onSave, onSubmit }) => {
  React.useEffect(() => {
    localStorage.setItem("vendorFormData", JSON.stringify(formData));
  }, [formData]);

  return (
    <div className="my-5">
      <div className="p-3 border rounded bg-white">
        <h6 className="mb-3 fw-bold">Marketing & CTA</h6>
        <div className="row">
          <div className="col-md-6 mb-3">
            <label className="form-label fw-semibold">Primary CTA</label>
            <select
              className="form-select"
              value={formData.primaryCTA}
              onChange={(e) =>
                setFormData((prev) => ({ ...prev, primaryCTA: e.target.value }))
              }
            >
              <option value="enquire">Enquire</option>
              <option value="call">Call</option>
              <option value="visit">Visit</option>
              <option value="book">Book</option>
            </select>
          </div>
          <div className="col-md-6 mb-3">
            <label className="form-label fw-semibold">CTA Phone</label>
            <input
              type="tel"
              className="form-control"
              value={formData.ctaPhone}
              onChange={(e) =>
                setFormData((prev) => ({ ...prev, ctaPhone: e.target.value }))
              }
              placeholder="CTA phone number"
            />
          </div>
          <div className="col-12 mb-3">
            <label className="form-label fw-semibold">CTA URL</label>
            <input
              type="url"
              className="form-control"
              value={formData.ctaUrl}
              onChange={(e) =>
                setFormData((prev) => ({ ...prev, ctaUrl: e.target.value }))
              }
              placeholder="CTA URL"
            />
          </div>
          <div className="col-12 mb-3">
            <label className="form-label fw-semibold">Auto Reply Message</label>
            <textarea
              className="form-control"
              rows="3"
              value={formData.autoReply}
              onChange={(e) =>
                setFormData((prev) => ({ ...prev, autoReply: e.target.value }))
              }
              placeholder="Auto reply message"
            />
          </div>
          <div className="col-md-6 mb-3">
            <label className="form-label fw-semibold">Sort Weight</label>
            <input
              type="number"
              className="form-control"
              value={formData.sortWeight}
              onChange={(e) =>
                setFormData((prev) => ({ ...prev, sortWeight: e.target.value }))
              }
              placeholder="Sort weight"
            />
          </div>
          <div className="col-md-6 mb-3">
            <div className="form-check mt-4">
              <input
                className="form-check-input"
                type="checkbox"
                checked={formData.isFeatured}
                onChange={(e) =>
                  setFormData((prev) => ({
                    ...prev,
                    isFeatured: e.target.checked,
                  }))
                }
              />
              <label className="form-check-label fw-semibold">
                Featured Vendor
              </label>
            </div>
          </div>
        </div>
        <div className="d-flex gap-2 mt-2">
          <button
            type="button"
            className="btn btn-outline-primary"
            onClick={() => onSave?.()}
          >
            Save Draft
          </button>
          <button className="btn btn-primary" onClick={onSubmit}>
            Submit All Details
          </button>
        </div>
      </div>
    </div>
  );
};

export default VendorMarketing;
