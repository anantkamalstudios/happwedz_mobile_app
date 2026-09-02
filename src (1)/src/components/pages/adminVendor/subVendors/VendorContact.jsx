import React from "react";

const defaultContact = {
  contactName: "",
  phone: "",
  altPhone: "",
  email: "",
  website: "",
  whatsappNumber: "",
  inquiryEmail: "",
};

const VendorContact = ({ formData, setFormData, onSave }) => {
  const contact = formData.contact || defaultContact;

  const handleInputChange = (field, value) => {
    setFormData((prev) => ({
      ...prev,
      contact: {
        ...((prev && prev.contact) || {}),
        [field]: value,
      },
    }));
  };

  return (
    <div className="my-5">
      <div className="p-3 border rounded bg-white">
        <h4 className="mb-3 fw-bold">Contact Details</h4>
        <div className="row">
          <div className="col-md-6 mb-3">
            <label className="form-label fw-semibold fs-16">
              Contact Person *
            </label>
            <input
              type="text"
              className="form-control fs-14"
              value={contact.contactName}
              onChange={(e) => handleInputChange("contactName", e.target.value)}
              placeholder="Enter contact person name"
            />
          </div>
          <div className="col-md-6 mb-3">
            <label className="form-label fw-semibold fs-16">
              Primary Phone *
            </label>
            <input
              type="tel"
              className="form-control fs-14"
              value={contact.phone}
              onChange={(e) => handleInputChange("phone", e.target.value)}
              placeholder="Enter primary phone number"
            />
          </div>
          <div className="col-md-6 mb-3">
            <label className="form-label fw-semibold fs-16">
              Alternative Phone
            </label>
            <input
              type="tel"
              className="form-control fs-14"
              value={contact.altPhone}
              onChange={(e) => handleInputChange("altPhone", e.target.value)}
              placeholder="Enter alternative phone number"
            />
          </div>
          <div className="col-md-6 mb-3">
            <label className="form-label fw-semibold fs-16">
              WhatsApp Number
            </label>
            <input
              type="tel"
              className="form-control fs-14"
              value={contact.whatsappNumber}
              onChange={(e) =>
                handleInputChange("whatsappNumber", e.target.value)
              }
              placeholder="Enter WhatsApp number"
            />
          </div>
          {/* <div className="col-md-6 mb-3">
            <label className="form-label fw-semibold fs-16">Email *</label>
            <input
              type="email"
              className="form-control fs-14"
              value={contact.email}
              onChange={(e) => handleInputChange("email", e.target.value)}
              placeholder="Enter email address"
            />
          </div> */}
          {/* <div className="col-md-6 mb-3">
            <label className="form-label fw-semibold fs-16">Inquiry Email</label>
            <input
              type="email"
              className="form-control fs-14"
              value={contact.inquiryEmail}
              onChange={(e) =>
                handleInputChange("inquiryEmail", e.target.value)
              }
              placeholder="Enter inquiry email"
            />
          </div> */}
          {/* <div className="col-12 mb-3">
            <label className="form-label fw-semibold fs-16">Website</label>
            <input
              type="url"
              className="form-control fs-14"
              value={contact.website}
              onChange={(e) => handleInputChange("website", e.target.value)}
              placeholder="https://your-website.com"
            />
          </div> */}
        </div>
        <button
          className="btn btn-primary mt-2 fs-14"
          type="button"
          onClick={() => onSave?.()}
        >
          Save Contact Details
        </button>
      </div>
    </div>
  );
};

export default VendorContact;
