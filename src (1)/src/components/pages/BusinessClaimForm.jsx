import React from "react";
import { IoClose } from "react-icons/io5";
import { Link, useLocation } from "react-router-dom";
import useClaimForm from "../../hooks/useClaimForm";

const BusinessClaimForm = ({ setShowClaimForm, vendorServiceId = null }) => {
  const location = useLocation();
  const isOnClaimPage = location.pathname === "/claim-your-buisness";

  const {
    formData,
    loading,
    submitting,
    vendorData,
    handleInputChange,
    handleSubmit,
  } = useClaimForm(vendorServiceId);

  if (loading) {
    return (
      <div className="container">
        <div className="claim-business-card text-center">
          <div className="spinner-border text-primary" role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
          <p className="mt-3">Loading vendor details...</p>
        </div>
      </div>
    );
  }

  return (
    <>
      <div className="container">
        <div className="claim-business-card position-relative">
          <h1 className="claim-business-title">Business Claim Form</h1>
          <p className="claim-business-subtitle">
            Please take a moment to fill out this form in complete detail.
          </p>

          {vendorData && (
            <div className="alert alert-info mb-3">
              <strong>Claiming Business:</strong>{" "}
              {vendorData.vendor?.businessName ||
                vendorData.attributes?.vendor_name}
            </div>
          )}

          {setShowClaimForm && (
            <div
              style={{ position: "absolute", top: 10, right: 10 }}
              onClick={() => setShowClaimForm(false)}
            >
              <IoClose size={30} style={{ color: "#000", cursor: "pointer" }} />
            </div>
          )}

          <div>
            {/* Policyholder Information */}
            <div className="claim-business-section">
              <div className="claim-business-section-header">
                <h2 className="claim-business-section-title">
                  Business Information
                </h2>
              </div>
              <div className="claim-business-section-content">
                  <div className="row">
                    <div className="col-md-6 mb-3">
                      <input
                        type="text"
                        className="claim-business-input"
                        placeholder="Business Name"
                        name="businessName"
                        value={formData.businessName}
                        onChange={handleInputChange}
                      />
                    </div>
                    <div className="col-md-6 mb-3">
                      <input
                        type="text"
                        className="claim-business-input"
                        placeholder="Registered Business Address"
                        name="registeredAddress"
                        value={formData.registeredAddress}
                        onChange={handleInputChange}
                      />
                    </div>
                    <div className="col-md-6 mb-3">
                      <input
                        type="tel"
                        className="claim-business-input"
                        placeholder="Business Phone Number"
                        name="phoneNumber"
                        value={formData.phoneNumber}
                        onChange={handleInputChange}
                      />
                    </div>
                    <div className="col-md-6 mb-3">
                      <input
                        type="email"
                        className="claim-business-input"
                        placeholder="Business Email Address"
                        name="emailAddress"
                        value={formData.emailAddress}
                        onChange={handleInputChange}
                      />
                    </div>
                    <div className="col-md-6 mb-3">
                      <input
                        type="url"
                        className="claim-business-input"
                        placeholder="Business Website"
                        name="website"
                        value={formData.website}
                        onChange={handleInputChange}
                      />
                    </div>
                    <div className="col-md-6 mb-3">
                      <input
                        type="text"
                        className="claim-business-input"
                        placeholder="Business Category / Type"
                        name="category"
                        value={formData.category}
                        onChange={handleInputChange}
                      />
                    </div>
                    <div className="col-12 mb-3">
                      <input
                        type="text"
                        className="claim-business-input"
                        placeholder="Business Registration Number (if applicable)"
                        name="registrationNumber"
                        value={formData.registrationNumber}
                        onChange={handleInputChange}
                      />
                    </div>
                </div>
              </div>
            </div>


            {/* Replaces the declaration checkbox the trimmed form no longer carries.
                Consent given by submitting is the same consent, and it costs the vendor
                one less field. */}
            <p className="text-muted small mb-3">
              By submitting this form you confirm that the information above is true and
              accurate to the best of your knowledge, and that you are authorised to
              claim this business.
            </p>

            <button
              type="button"
              className="claim-business-submit-btn"
              onClick={handleSubmit}
              disabled={submitting}
            >
              {submitting ? (
                <>
                  <span
                    className="spinner-border spinner-border-sm me-2"
                    role="status"
                    aria-hidden="true"
                  ></span>
                  Submitting...
                </>
              ) : (
                "Submit"
              )}
            </button>

            {!isOnClaimPage && (
              <>
                <hr />
                <Link
                  to="/claim-your-buisness"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="d-flex primary-text text-center justify-content-center text-decoration-none"
                >
                  Open Claim Form Separately
                </Link>
              </>
            )}
          </div>
        </div>
      </div>
    </>
  );
};

export default BusinessClaimForm;
