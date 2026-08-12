import React from "react";
import {
  FaFileContract,
  FaStore,
  FaHandHoldingUsd,
  FaBan,
  FaInfoCircle,
} from "react-icons/fa";

const CancellationPolicy = () => {
  return (
    <div className="cancellation-policy-page bg-light min-vh-100 py-5">
      <div className="container">
        {/* Header Section */}
        <div className="text-center mb-5 mx-auto" style={{ maxWidth: "800px" }}>
          <h3 className="display-5 fw-bold text-dark mb-3">
            Cancellation Policy
          </h3>

          <p className="text-muted fs-18">
            Understanding how cancellations and refunds work on Happywedz.
          </p>
        </div>

        <div className="row justify-content-center">
          <div className="col-lg-10 col-xl-8">
            {/* Intro Card */}
            <div className="card border-0  rounded-4 mb-4">
              <div className="card-body p-4 p-md-5 text-center bg-white rounded-4">
                <p className="mb-0 fs-18 text-secondary">
                  "Because <strong>Happywedz</strong> is a platform and not a
                  service provider, cancellations and refunds depend entirely on
                  the individual vendor’s policies."
                </p>
              </div>
            </div>

            {/* Main Content Card */}
            <div className="card border-0 shadow-sm rounded-4 overflow-hidden">
              <div className="card-body p-4 p-md-5">
                {/* 6.1 Platform-Level Terms */}
                <div className="mb-5">
                  <div className="d-flex align-items-center mb-3">
                    <div className="bg-primary bg-opacity-10 p-3 rounded-circle me-3 text-primary">
                      <FaFileContract size={24} />
                    </div>
                    <h4 className="fw-bold mb-0">1. Platform-Level Terms</h4>
                  </div>
                  <div className="ps-md-5 ms-md-2">
                    <ul className="list-unstyled">
                      <li className="mb-2 d-flex align-items-start">
                        <span className="text-primary me-2">•</span>
                        <span>
                          Happywedz does not charge users for vendor bookings
                          unless explicitly stated.
                        </span>
                      </li>
                      <li className="mb-2 d-flex align-items-start">
                        <span className="text-primary me-2">•</span>
                        <span>
                          Happywedz does not issue refunds for vendor-related
                          payments.
                        </span>
                      </li>
                      <li className="mb-2 d-flex align-items-start">
                        <span className="text-primary me-2">•</span>
                        <span>
                          Refund requests must be directed to the vendor you
                          booked.
                        </span>
                      </li>
                    </ul>
                  </div>
                </div>

                <hr className="my-4 text-muted opacity-25" />

                {/* 6.2 Vendor-Level Policies */}
                <div className="mb-5">
                  <div className="d-flex align-items-center mb-3">
                    <div className="bg-success bg-opacity-10 p-3 rounded-circle me-3 text-success">
                      <FaStore size={24} />
                    </div>
                    <h4 className="fw-bold mb-0">2. Vendor-Level Policies</h4>
                  </div>
                  <div className="ps-md-5 ms-md-2">
                    <p className="text-muted mb-3">
                      Vendors may define their own cancellation and refund
                      rules. Common examples include:
                    </p>
                    <div className="bg-light p-4 rounded-3">
                      <ul className="list-unstyled mb-0">
                        <li className="mb-2 d-flex justify-content-between border-bottom pb-2">
                          <span>Cancellation 60+ days before event</span>
                          <span className="fw-semibold text-success">
                            Partial or full refund
                          </span>
                        </li>
                        <li className="mb-2 d-flex justify-content-between border-bottom pb-2">
                          <span>Cancellation 30–60 days before event</span>
                          <span className="fw-semibold text-warning">
                            Limited refund
                          </span>
                        </li>
                        <li className="mb-2 d-flex justify-content-between border-bottom pb-2">
                          <span>Cancellation 0–30 days before event</span>
                          <span className="fw-semibold text-danger">
                            No refund
                          </span>
                        </li>
                        <li className="mb-2 d-flex justify-content-between border-bottom pb-2">
                          <span>Customized / pre-production services</span>
                          <span className="fw-semibold text-danger">
                            Non-refundable
                          </span>
                        </li>
                        <li className="d-flex justify-content-between">
                          <span>Advance booking fees</span>
                          <span className="fw-semibold text-danger">
                            Often non-refundable
                          </span>
                        </li>
                      </ul>
                    </div>
                  </div>
                </div>

                <hr className="my-4 text-muted opacity-25" />

                {/* 6.3 Payment Disputes */}
                <div className="mb-5">
                  <div className="d-flex align-items-center mb-3">
                    <div className="bg-warning bg-opacity-10 p-3 rounded-circle me-3 text-warning">
                      <FaHandHoldingUsd size={24} />
                    </div>
                    <h4 className="fw-bold mb-0">3. Payment Disputes</h4>
                  </div>
                  <div className="ps-md-5 ms-md-2">
                    <p className="text-muted mb-3">
                      Happywedz is not responsible for:
                    </p>
                    <div className="row g-3 mb-4">
                      {[
                        "Payment disputes",
                        "Chargebacks",
                        "Failed vendor commitments",
                        "Refund delays",
                      ].map((item, idx) => (
                        <div key={idx} className="col-sm-6">
                          <div className="d-flex align-items-center p-2 border rounded bg-white">
                            <FaBan className="text-danger me-2" />
                            <span>{item}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                    <p className="text-muted small fst-italic">
                      Users and vendors must resolve disputes directly.
                      Happywedz may assist with communication at its discretion
                      but is not obligated to mediate.
                    </p>
                  </div>
                </div>

                <hr className="my-4 text-muted opacity-25" />

                {/* 6.4 Vendor Cancellation */}
                <div>
                  <div className="d-flex align-items-center mb-3">
                    <div className="bg-danger bg-opacity-10 p-3 rounded-circle me-3 text-danger">
                      <FaBan size={24} />
                    </div>
                    <h4 className="fw-bold mb-0">4. Vendor Cancellation</h4>
                  </div>
                  <div className="ps-md-5 ms-md-2">
                    <p className="text-muted mb-3">
                      If a vendor cancels a booking, users should:
                    </p>
                    <ul className="list-unstyled">
                      <li className="mb-2 d-flex align-items-center">
                        <span className="badge bg-primary rounded-pill me-3">
                          1
                        </span>
                        Contact the vendor directly for a refund
                      </li>
                      <li className="mb-2 d-flex align-items-center">
                        <span className="badge bg-primary rounded-pill me-3">
                          2
                        </span>
                        Review the vendor’s cancellation terms
                      </li>
                      <li className="mb-2 d-flex align-items-center">
                        <span className="badge bg-primary rounded-pill me-3">
                          3
                        </span>
                        Report the issue to Happywedz for review
                      </li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>

            {/* Notice */}
            <div
              className="alert alert-warning d-flex align-items-start mt-4 shadow-sm rounded-3 border-0"
              role="alert"
            >
              <FaInfoCircle className="flex-shrink-0 me-3 mt-1" size={20} />
              <div>
                <h5 className="alert-heading fw-bold fs-6">Important Notice</h5>
                <p className="mb-0 small">
                  Happywedz acts only as an intermediary platform. Users are
                  advised to review vendor cancellation and refund policies
                  carefully before booking.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CancellationPolicy;
