import React, { useEffect, useMemo, useRef, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { Loader2, Upload, ChevronDown } from "lucide-react";
import { bookTripSafeInsurance } from "../../../../services/api/tripSafeApi";
import { formatDate as fmtDate } from "../../../../utils/dateFormat";

const NOMINEE_RELATIONS = [
  "LEGAL HEIR",
  "SPOUSE",
  "FATHER",
  "MOTHER",
  "SON",
  "DAUGHTER",
  "BROTHER",
  "SISTER",
];

const formatPrice = (value) => {
  const num = Number(value || 0);
  if (!num) return "—";
  return `₹${num.toLocaleString("en-IN", { maximumFractionDigits: 0 })}`;
};

const formatDate = (value) => {
  if (!value) return "—";
  return fmtDate(value, value);
};

const splitFullName = (fullName) => {
  const parts = String(fullName || "")
    .trim()
    .split(/\s+/)
    .filter(Boolean);
  if (!parts.length) return { fn: "", ln: "" };
  if (parts.length === 1) return { fn: parts[0], ln: parts[0] };
  return { fn: parts[0], ln: parts.slice(1).join(" ") };
};

const buildTravellerForms = (searchParams) => {
  const ages = (searchParams?.isq?.iti || []).map((t) => t.age || 30);
  const count = ages.length || 1;
  return ages.slice(0, count).map((age, index) => ({
    id: index + 1,
    age,
    fullName: "",
    gender: "M",
    dob: "",
    passport: "",
    mobile: "",
    email: "",
    pincode: "",
    nomineeName: "LEGAL HEIR",
    nomineeRelation: "LEGAL HEIR",
  }));
};

const InsuranceBookingPage = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const searchParams = location.state?.searchParams;
  const selectedPlan = location.state?.selectedPlan;
  const reviewMeta = location.state?.reviewMeta;

  const [travellers, setTravellers] = useState(() =>
    buildTravellerForms(searchParams),
  );
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [agreeToTerms, setAgreeToTerms] = useState(false);
  const passportFileInputRefs = useRef({});

  useEffect(() => {
    if (!searchParams || !selectedPlan || !reviewMeta?.bookingId) {
      navigate("/honeymoon");
    }
  }, [searchParams, selectedPlan, reviewMeta, navigate]);

  const destinationLabel = useMemo(() => {
    const regions = searchParams?.isq?.isc?.iri || [];
    return (
      searchParams?.destinationLabel ||
      regions
        .map((r) => {
          if (r.rkey === "CA") return "Canada";
          return r.rkey;
        })
        .join(", ") ||
      "Selected destination"
    );
  }, [searchParams]);

  if (!searchParams || !selectedPlan || !reviewMeta?.bookingId) return null;

  const totalPrice = reviewMeta.price || selectedPlan.price;
  const bd = selectedPlan.priceBreakdown || {};
  const earnAmount = selectedPlan.earnAmount || 0;

  const updateTraveller = (index, field, value) => {
    setTravellers((prev) => {
      const next = [...prev];
      next[index] = { ...next[index], [field]: value };
      return next;
    });
  };

  const handlePassportUploadClick = (index) => {
    const input = passportFileInputRefs.current[index];
    if (input) {
      input.click();
    }
  };

  const handlePassportFileChange = (index, file) => {
    if (!file) return;

    const allowedTypes = [
      "image/png",
      "image/jpeg",
      "application/pdf",
    ];

    if (!allowedTypes.includes(file.type)) {
      setError("Only PNG, JPG, or PDF files are allowed.");
      return;
    }

    const maxSizeBytes = 2 * 1024 * 1024;
    if (file.size > maxSizeBytes) {
      setError("Passport file must be less than 2MB.");
      return;
    }

    setError(null);
    setTravellers((prev) => {
      const next = [...prev];
      next[index] = {
        ...next[index],
        passportFile: file,
        passportFileName: file.name,
      };
      return next;
    });
  };

  const validateForm = () => {
    for (let i = 0; i < travellers.length; i += 1) {
      const t = travellers[i];
      if (!t.fullName.trim()) return `Enter full name for traveller ${i + 1}`;
      if (!t.passport.trim())
        return `Enter passport number for traveller ${i + 1}`;
      if (!t.mobile.trim() || t.mobile.length < 10) {
        return `Enter valid mobile for traveller ${i + 1}`;
      }
      if (!t.email.trim() || !t.email.includes("@")) {
        return `Enter valid email for traveller ${i + 1}`;
      }
      if (!t.pincode.trim()) return `Enter pincode for traveller ${i + 1}`;
      if (!t.nomineeName.trim())
        return `Enter nominee name for traveller ${i + 1}`;
    }
    if (!agreeToTerms) return "Please agree to the terms and conditions";
    return null;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const validationError = validateForm();
    if (validationError) {
      setError(validationError);
      return;
    }

    setSubmitting(true);
    setError(null);

    const primary = travellers[0];
    const iti = travellers.map((t) => {
      const { fn, ln } = splitFullName(t.fullName);
      return {
        id: t.id,
        age: Number(t.age),
        fn,
        ln,
        eid: t.email.trim(),
        pnum: t.passport.trim(),
        cnum: t.mobile.trim(),
        pincode: t.pincode.trim(),
        gen: t.gender,
        ni: [
          {
            nn: t.nomineeName.trim(),
            nr: t.nomineeRelation,
          },
        ],
      };
    });

    const payload = {
      bookingId: reviewMeta.bookingId,
      paymentInfos: [
        {
          paymentMedium: "WALLET",
          amount: totalPrice,
        },
      ],
      pli: [
        {
          plid: selectedPlan.plid,
          pi: [
            {
              pid: selectedPlan.pid,
              iti,
            },
          ],
        },
      ],
      deliveryInfo: {
        emails: [primary.email.trim()],
        contacts: [primary.mobile.trim()],
      },
    };

    try {
      const response = await bookTripSafeInsurance(payload);
      if (!response?.status) {
        setError(response?.message || "Booking failed");
        return;
      }
      const bookedId =
        response?.data?.bookingId ||
        response?.data?.order?.bookingId ||
        reviewMeta.bookingId;
      navigate(`/honeymoon/insurance/booking/${bookedId}`, { replace: true });
    } catch (err) {
      setError(
        err?.response?.data?.message ||
          err?.message ||
          "Unable to complete booking",
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="ins-booking-page">
      <div className="container py-4">
        <button
          type="button"
          className="btn btn-link text-decoration-none ps-0 mb-3"
          onClick={() =>
            navigate("/honeymoon/insurance", {
              state: {
                searchParams,
                initialResults: location.state?.initialResults,
              },
            })
          }
        >
          ← Back to packages
        </button>

        <div className="row g-4">
          <div className="col-lg-8">
            <form onSubmit={handleSubmit}>
              {travellers.map((traveller, index) => (
                <div key={traveller.id} className="ins-traveller-card mb-4">
                  <div className="ins-traveller-card-header">
                    Traveller {index + 1} | {traveller.age} Yrs
                  </div>

                  <div className="ins-passport-upload">
                    <Upload size={28} className="text-muted mb-2" />
                    <div className="fw-semibold">Upload Passport</div>
                    <small className="text-muted">
                      PNG, JPG, PDF | Size &lt; 2MB
                    </small>
                    <button
                      type="button"
                      className="btn btn-sm ins-upload-btn mt-2"
                      onClick={() => handlePassportUploadClick(index)}
                    >
                      UPLOAD
                    </button>
                    <input
                      ref={(el) => {
                        passportFileInputRefs.current[index] = el;
                      }}
                      type="file"
                      accept=".png,.jpg,.jpeg,.pdf"
                      style={{ display: "none" }}
                      onChange={(e) =>
                        handlePassportFileChange(index, e.target.files?.[0])
                      }
                    />
                    {traveller.passportFileName ? (
                      <div className="mt-2 small text-success fw-semibold">
                        Uploaded: {traveller.passportFileName}
                      </div>
                    ) : null}
                  </div>

                  <div className="row g-3 p-3 pt-0">
                    <div className="col-12">
                      <label className="form-label">Name</label>
                      <input
                        type="text"
                        className="form-control"
                        placeholder="Enter Full Name"
                        value={traveller.fullName}
                        onChange={(e) =>
                          updateTraveller(index, "fullName", e.target.value)
                        }
                        required
                      />
                    </div>

                    <div className="col-md-6">
                      <label className="form-label d-block">Gender</label>
                      <div className="ins-gender-group">
                        {[
                          ["M", "Male"],
                          ["F", "Female"],
                        ].map(([val, label]) => (
                          <label key={val} className="ins-gender-option">
                            <input
                              type="radio"
                              name={`gender-${index}`}
                              checked={traveller.gender === val}
                              onChange={() =>
                                updateTraveller(index, "gender", val)
                              }
                            />
                            {label}
                          </label>
                        ))}
                      </div>
                    </div>

                    <div className="col-md-6">
                      <label className="form-label">Date of Birth</label>
                      <input
                        type="date"
                        className="form-control"
                        value={traveller.dob}
                        onChange={(e) =>
                          updateTraveller(index, "dob", e.target.value)
                        }
                      />
                    </div>

                    <div className="col-md-6">
                      <label className="form-label">Passport Number</label>
                      <input
                        type="text"
                        className="form-control"
                        placeholder="Enter Number"
                        value={traveller.passport}
                        onChange={(e) =>
                          updateTraveller(index, "passport", e.target.value)
                        }
                        required
                      />
                    </div>

                    <div className="col-md-6">
                      <label className="form-label">Pincode</label>
                      <input
                        type="text"
                        className="form-control"
                        placeholder="123456"
                        value={traveller.pincode}
                        onChange={(e) =>
                          updateTraveller(index, "pincode", e.target.value)
                        }
                        required
                      />
                    </div>

                    <div className="col-md-6">
                      <label className="form-label">Nominee Name</label>
                      <input
                        type="text"
                        className="form-control"
                        value={traveller.nomineeName}
                        onChange={(e) =>
                          updateTraveller(index, "nomineeName", e.target.value)
                        }
                        required
                      />
                    </div>

                    <div className="col-md-6">
                      <label className="form-label">Relationship</label>
                      <select
                        className="form-select"
                        value={traveller.nomineeRelation}
                        onChange={(e) =>
                          updateTraveller(
                            index,
                            "nomineeRelation",
                            e.target.value,
                          )
                        }
                      >
                        {NOMINEE_RELATIONS.map((rel) => (
                          <option key={rel} value={rel}>
                            {rel}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="col-md-6">
                      <label className="form-label">Mobile Number (+91)</label>
                      <input
                        type="tel"
                        className="form-control"
                        placeholder="XXXXX XXXXX"
                        value={traveller.mobile}
                        onChange={(e) =>
                          updateTraveller(index, "mobile", e.target.value)
                        }
                        required
                      />
                    </div>

                    <div className="col-md-6">
                      <label className="form-label">Email ID</label>
                      <input
                        type="email"
                        className="form-control"
                        placeholder="Enter Email ID"
                        value={traveller.email}
                        onChange={(e) =>
                          updateTraveller(index, "email", e.target.value)
                        }
                        required
                      />
                    </div>
                  </div>
                </div>
              ))}

              {error && <div className="alert alert-danger">{error}</div>}

              <div className="mt-4">
                <div className="form-check mb-4 p-3 border rounded">
                  <input
                    className="form-check-input"
                    type="checkbox"
                    id="termsCheckbox"
                    checked={agreeToTerms}
                    onChange={(e) => setAgreeToTerms(e.target.checked)}
                  />
                  <label
                    className="form-check-label ms-2"
                    htmlFor="termsCheckbox"
                  >
                    I confirm that all passengers are Indian nationals between 0
                    to 75 years of age, have authorised me to add Insurance, and
                    agree to the{" "}
                    <a href="#" className="text-primary">
                      T&amp;C
                    </a>
                  </label>
                </div>

                <div className="d-flex justify-content-between align-items-center mb-4">
                  <button
                    type="button"
                    className="btn btn-lg"
                    style={{
                      background: "#ed1173",
                      color: "white",
                      border: "none",
                      borderRadius: "4px",
                    }}
                    onClick={() =>
                      navigate("/honeymoon/insurance", {
                        state: {
                          searchParams,
                          initialResults: location.state?.initialResults,
                        },
                      })
                    }
                  >
                    &lt;&lt; Back
                  </button>
                  <button
                    type="submit"
                    className="btn btn-lg"
                    style={{
                      background: "#ed1173",
                      color: "white",
                      border: "none",
                      borderRadius: "4px",
                    }}
                    disabled={submitting || !agreeToTerms}
                  >
                    {submitting ? (
                      <span className="d-inline-flex align-items-center gap-2">
                        <Loader2 size={18} className="spin" />
                        Booking insurance...
                      </span>
                    ) : (
                      "Continue >>"
                    )}
                  </button>
                </div>

                <div className="p-3 border rounded bg-white shadow-sm">
                  <h6 className="fw-bold mb-2">*Disclaimers</h6>
                  <ul className="small mb-0">
                    <li>Agent earnings are on non-insurance products.</li>
                    <li>
                      Insurance is through a group master policy with Aditya
                      Birla Health Insurance.
                    </li>
                  </ul>
                </div>
              </div>
            </form>
          </div>

          <div className="col-lg-4">
            <div className="ins-plan-summary sticky-top">
              <h5 className="mb-3">Plan Summary</h5>

              {/* Trip info */}
              <div className="ins-summary-trip-grid">
                <div>
                  <div className="ins-summary-label">Destination</div>
                  <div className="ins-summary-value">{destinationLabel}</div>
                </div>
                <div>
                  <div className="ins-summary-label">Start Date</div>
                  <div className="ins-summary-value">
                    {formatDate(searchParams?.isq?.sd)}
                  </div>
                </div>
                <div>
                  <div className="ins-summary-label">End Date</div>
                  <div className="ins-summary-value">
                    {formatDate(searchParams?.isq?.ed)}
                  </div>
                </div>
              </div>

              {/* Plan card */}
              <div className="ins-summary-plan mt-3">
                <small className="text-muted">
                  Plan for: Traveller 1 | {travellers[0]?.age} yrs
                </small>
                <div className="ins-summary-plan-row mt-2">
                  <div className="ins-summary-plan-badge">
                    <div className="ins-summary-plan-name">
                      TripSafe {selectedPlan.planLabel?.toUpperCase()}
                    </div>
                    <div className="ins-summary-plan-meta">
                      24/7 Assistance | {selectedPlan.coverageAmount} Travel
                      Cover
                    </div>
                  </div>
                  <div className="ins-summary-plan-price-col">
                    <div className="ins-summary-price">
                      {formatPrice(totalPrice)}
                    </div>
                    <small className="text-muted">Inc. GST</small>
                    {earnAmount > 0 && (
                      <div className="ins-earn-pill mt-1">
                        <span className="ins-earn-icon">%</span>
                        Earn ₹{earnAmount.toLocaleString("en-IN")}*
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Price breakdown */}
              <div className="ins-summary-breakdown mt-3">
                <div className="ins-breakdown-total">
                  <span className="d-flex align-items-center gap-1">
                    Total <ChevronDown size={16} />
                  </span>
                  <span>{formatPrice(totalPrice)}</span>
                </div>
                {bd.sp > 0 && (
                  <div className="ins-breakdown-row">
                    <span>TripSafe Fee</span>
                    <span>+ {formatPrice(bd.sp)}</span>
                  </div>
                )}
                {bd.spGst > 0 && (
                  <div className="ins-breakdown-row">
                    <span>TripSafe GST</span>
                    <span>+ {formatPrice(bd.spGst)}</span>
                  </div>
                )}
                {earnAmount > 0 && (
                  <div className="ins-breakdown-row ins-breakdown-earn">
                    <span>TripSafe Earnings</span>
                    <span>- {formatPrice(earnAmount)}</span>
                  </div>
                )}
                <div className="ins-breakdown-row">
                  <span>TDS</span>
                  <span>+ ₹0.00</span>
                </div>
                <div className="ins-breakdown-row ins-breakdown-net">
                  <span>Net Price</span>
                  <span>₹0.00</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <style>{`
        .ins-booking-page {
          background: #f8f5f7;
          min-height: 100vh;
        }
        .ins-traveller-card {
          background: #fff;
          border-radius: 12px;
          border: 1px solid #eee;
          overflow: hidden;
        }
        .ins-traveller-card-header {
          background: #f5f5f5;
          padding: 12px 16px;
          font-weight: 600;
          color: #444;
          font-size: 14px;
        }
        .ins-passport-upload {
          margin: 16px;
          padding: 24px;
          border: 2px dashed #ddd;
          border-radius: 8px;
          text-align: center;
          background: #fafafa;
        }
        .ins-upload-btn {
          background: #ff8c42;
          color: #fff;
          border: none;
          font-weight: 700;
        }
        .ins-gender-group {
          display: flex;
          gap: 16px;
        }
        .ins-gender-option {
          display: flex;
          align-items: center;
          gap: 6px;
          cursor: pointer;
          font-size: 14px;
        }
        .ins-submit-btn {
          background: linear-gradient(135deg, #ed1173, #ff6b9d);
          border: none;
          color: #fff;
          font-weight: 700;
          padding: 14px;
        }
        .ins-plan-summary {
          background: #fff;
          border-radius: 12px;
          border: 1px solid #eee;
          padding: 20px;
          top: 24px;
        }
        .ins-summary-trip-grid {
          display: grid;
          grid-template-columns: 1fr 1fr 1fr;
          gap: 8px;
          background: #f8f8f8;
          border-radius: 8px;
          padding: 12px;
        }
        .ins-summary-label {
          font-size: 11px;
          color: #999;
          margin-bottom: 2px;
        }
        .ins-summary-value {
          font-size: 13px;
          font-weight: 700;
          color: #222;
        }
        .ins-summary-plan-row {
          display: flex;
          gap: 12px;
          align-items: flex-start;
        }
        .ins-summary-plan-badge {
          flex: 1;
          background: linear-gradient(135deg, #4a4a4a, #1a1a1a);
          color: #fff;
          border-radius: 10px;
          padding: 12px 14px;
        }
        .ins-summary-plan-name {
          font-weight: 700;
          font-size: 14px;
        }
        .ins-summary-plan-meta {
          font-size: 11px;
          opacity: 0.8;
          margin-top: 4px;
        }
        .ins-summary-plan-price-col {
          text-align: right;
          flex-shrink: 0;
        }
        .ins-summary-price {
          font-size: 1.2rem;
          font-weight: 800;
          color: #111;
        }
        .ins-earn-pill {
          display: inline-flex;
          align-items: center;
          gap: 4px;
          background: #e8f5e9;
          color: #2e7d32;
          font-size: 12px;
          font-weight: 600;
          padding: 3px 8px;
          border-radius: 20px;
        }
        .ins-earn-icon {
          background: #2e7d32;
          color: #fff;
          border-radius: 50%;
          width: 16px;
          height: 16px;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          font-size: 10px;
          font-weight: 700;
        }
        .ins-summary-breakdown {
          background: #f8f8f8;
          border-radius: 8px;
          overflow: hidden;
        }
        .ins-breakdown-total {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 12px 14px;
          font-weight: 700;
          font-size: 15px;
          border-bottom: 1px solid #eee;
          background: #fff;
        }
        .ins-breakdown-row {
          display: flex;
          justify-content: space-between;
          padding: 8px 14px;
          font-size: 13px;
          color: #555;
          border-bottom: 1px solid #f0f0f0;
        }
        .ins-breakdown-earn {
          color: #2e7d32;
        }
        .ins-breakdown-net {
          font-weight: 700;
          color: #111;
          border-bottom: none;
        }
        .ins-booking-success {
          text-align: center;
          max-width: 480px;
          margin: 0 auto;
          padding: 48px 24px;
          background: #fff;
          border-radius: 16px;
        }
        .spin {
          animation: spin 1s linear infinite;
        }
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
};

export default InsuranceBookingPage;
