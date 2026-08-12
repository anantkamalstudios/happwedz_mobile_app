import React from "react";

const VendorPolicies = ({ formData, setFormData, onSave }) => {
  const handleInputChange = (field, value) => {
    setFormData((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  return (
    <div className="my-5">
      <div className="p-3 border rounded bg-white">
        <h4 className="mb-3 fw-bold">Policies & Terms</h4>

        <div className="row">
          {/* Cancellation Policy */}
          <div className="col-12 mb-3">
            <label className="form-label fs-16 fw-semibold">
              Cancellation Policy
            </label>
            <textarea
              className="form-control fs-14"
              rows="3"
              value={formData.cancellationPolicy || ""}
              onChange={(e) =>
                handleInputChange("cancellationPolicy", e.target.value)
              }
              placeholder="Enter cancellation policy"
            />
          </div>

          {/* Refund Policy */}
          <div className="col-12 mb-3">
            <label className="form-label fs-16 fw-semibold">
              Refund Policy
            </label>
            <textarea
              className="form-control fs-14"
              rows="3"
              value={formData.refundPolicy || ""}
              onChange={(e) =>
                handleInputChange("refundPolicy", e.target.value)
              }
              placeholder="Enter refund policy"
            />
          </div>

          {/* ✅ Payment Terms (direct string, not nested) */}
          <div className="col-md-6 mb-3">
            <label className="form-label fs-16 fw-semibold">
              Payment Terms
            </label>
            <input
              type="text"
              className="form-control fs-14"
              value={formData?.payment_terms || ""}
              onChange={(e) =>
                handleInputChange("payment_terms", e.target.value)
              }
              placeholder="e.g. Takes 50% Advance"
            />
          </div>

          {/* Terms & Conditions */}
          <div className="col-12 mb-3">
            <label className="form-label fs-16 fw-semibold">
              Terms & Conditions
            </label>
            <textarea
              className="form-control fs-14"
              rows="4"
              value={formData.tnc || ""}
              onChange={(e) => handleInputChange("tnc", e.target.value)}
              placeholder="Enter terms and conditions"
            />
          </div>
        </div>

        <button
          className="btn btn-primary mt-2 fs-14"
          type="button"
          onClick={() => onSave?.()}
        >
          Save Policies & Terms
        </button>
      </div>
    </div>
  );
};

export default VendorPolicies;
