import React, { useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import {
  Shield,
  Calendar,
  MapPin,
  Users,
  Loader2,
  Check,
  Plus,
  ChevronRight,
  Plane,
} from "lucide-react";
import { reviewInsurancePlan } from "../../../../services/api/tripSafeApi";
import InsuranceBenefitsModal from "./InsuranceBenefitsModal";

const formatPrice = (value) => {
  const num = Number(value || 0);
  if (!num) return "—";
  return `₹${num.toLocaleString("en-IN", { maximumFractionDigits: 0 })}`;
};

const formatDate = (value) => {
  if (!value) return "—";
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return value;
  return d.toLocaleDateString("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
};

const BenefitTag = ({ text }) => (
  <span className="ts-benefit-tag">
    <Check size={14} className="ts-benefit-check" />
    {text}
  </span>
);

const TravelInsuranceResults = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const searchParams = location.state?.searchParams;
  const initialResults = location.state?.initialResults;

  const [packages] = useState(initialResults?.data || []);
  const [benefitsModal, setBenefitsModal] = useState({
    open: false,
    pkg: null,
  });
  const [selectingId, setSelectingId] = useState(null);
  const [selectError, setSelectError] = useState(null);

  useEffect(() => {
    if (!searchParams) {
      navigate("/honeymoon");
    }
  }, [searchParams, navigate]);

  const handleSelectPlan = async (pkg) => {
    const key = `${pkg.plid}-${pkg.pid}`;
    setSelectingId(key);
    setSelectError(null);

    try {
      const review = await reviewInsurancePlan(pkg);
      if (!review?.status || !review.bookingId) {
        setSelectError(review?.message || "Could not review plan. Try again.");
        return;
      }

      navigate("/honeymoon/insurance/book", {
        state: {
          searchParams,
          initialResults,
          selectedPlan: pkg,
          reviewMeta: {
            bookingId: review.bookingId,
            price: review.price,
          },
        },
      });
    } catch (err) {
      setSelectError(
        err?.response?.data?.message || err?.message || "Review failed",
      );
    } finally {
      setSelectingId(null);
    }
  };

  if (!searchParams) return null;

  const regions = searchParams?.isq?.isc?.iri || [];

  return (
    <>
      <div className="ins-results-page">
        <div className="container py-4">
          <button
            type="button"
            className="btn btn-outline-secondary mb-3"
            onClick={() => navigate("/honeymoon")}
          >
            ← Back to Search
          </button>

          <div className="ins-results-header">
            <div>
              <h2 className="ins-results-title">Travel Insurance Packages</h2>
              <p className="ins-results-meta">
                <MapPin size={14} />
                {searchParams?.destinationLabel ||
                  regions.map((r) => r.rkey).join(", ") ||
                  "Selected destination"}
                <span className="mx-2">·</span>
                <Calendar size={14} />
                {formatDate(searchParams?.isq?.sd)} –{" "}
                {formatDate(searchParams?.isq?.ed)}
                <span className="mx-2">·</span>
                <Users size={14} />
                {(searchParams?.isq?.iti || []).length} traveller
                {(searchParams?.isq?.iti || []).length === 1 ? "" : "s"}
                {searchParams?.planType ? ` · ${searchParams.planType}` : ""}
              </p>
            </div>
          </div>

          {selectError && (
            <div className="alert alert-danger py-2">{selectError}</div>
          )}

          {!packages.length ? (
            <div className="alert alert-info">
              No insurance packages found. Try different dates or destination.
            </div>
          ) : (
            <div className="ts-cards-list">
              {packages.map((pkg) => {
                const cardKey = `${pkg.plid}-${pkg.pid}`;
                const isSelecting = selectingId === cardKey;
                const assistanceTags = pkg.assistanceTags || [];
                const coverageTags = pkg.coverageTags || [];

                return (
                  <article key={cardKey} className="ts-plan-card">
                    <div className="ts-plan-card-inner">
                      <div className="ts-plan-main">
                        <header className="ts-plan-header">
                          <div className="ts-plan-brand">
                            <span className="ts-shield-icon">
                              <Shield size={22} strokeWidth={2.2} />
                              <Plane size={11} className="ts-shield-plane" />
                            </span>
                            <span className="ts-plan-name">
                              TripSafe{" "}
                              <strong>{pkg.planLabel?.toUpperCase()}</strong>
                            </span>
                          </div>
                          <div className="ts-plan-pricing">
                            {pkg.earnAmount > 0 && (
                              <span className="ts-earn-badge">
                                Earn ₹{pkg.earnAmount.toLocaleString("en-IN")}*
                              </span>
                            )}
                            <div className="ts-price-block">
                              <span className="ts-price">
                                {formatPrice(pkg.price)}
                              </span>
                              <span className="ts-price-gst">Inc. GST</span>
                            </div>
                          </div>
                        </header>

                        <div className="ts-plan-body">
                          {/* Assistance column */}
                          <div className="ts-plan-col">
                            <h6 className="ts-col-title">24/7 Assistance</h6>
                            <p className="ts-col-sub">
                              Assistance by{" "}
                              {pkg.assistancePartner || "TripSafe partners"}
                            </p>
                            <div className="ts-tags-grid">
                              {assistanceTags.map((tag) => (
                                <BenefitTag key={tag} text={tag} />
                              ))}
                            </div>
                          </div>

                          {/* Coverage column */}
                          <div className="ts-plan-col">
                            <h6 className="ts-col-title">
                              {pkg.coverageAmount || "$50,000"} Travel Cover
                            </h6>
                            <p className="ts-col-sub">
                              Insurance by {pkg.insurerLabel || pkg.insurer}
                            </p>
                            <div className="ts-tags-grid">
                              {coverageTags.map((tag) => (
                                <BenefitTag key={tag} text={tag} />
                              ))}
                            </div>
                          </div>
                        </div>

                        <footer className="ts-plan-footer">
                          <button
                            type="button"
                            className="ts-view-benefits"
                            onClick={() =>
                              setBenefitsModal({ open: true, pkg })
                            }
                          >
                            View all {pkg.benefitsCount} benefits
                            <ChevronRight size={16} />
                          </button>
                          <p className="ts-disclaimer">
                            *Agent earnings are on non-insurance products |
                            Insurance is through a group master policy with{" "}
                            {pkg.insurerLabel || "the insurer"}.
                          </p>
                        </footer>
                      </div>

                      <div className="ts-plan-action">
                        <button
                          type="button"
                          className="ts-add-btn"
                          disabled={Boolean(selectingId)}
                          onClick={() => handleSelectPlan(pkg)}
                        >
                          {isSelecting ? (
                            <Loader2 size={22} className="spin" />
                          ) : (
                            <>
                              <span className="ts-add-icon">
                                <Plus size={20} strokeWidth={2.5} />
                              </span>
                              Select Plan
                            </>
                          )}
                        </button>
                      </div>
                    </div>
                  </article>
                );
              })}
            </div>
          )}
        </div>
      </div>

      <InsuranceBenefitsModal
        open={benefitsModal.open}
        planLabel={benefitsModal.pkg?.planLabel}
        benefits={benefitsModal.pkg?.benefits || []}
        onClose={() => setBenefitsModal({ open: false, pkg: null })}
      />

      <style>{`
        .ins-results-page {
          background: #f4f6f8;
          min-height: 100vh;
        }
        .ins-results-header {
          display: flex;
          flex-wrap: wrap;
          justify-content: space-between;
          align-items: flex-start;
          gap: 16px;
          margin-bottom: 20px;
        }
        .ins-results-title {
          font-size: 1.35rem;
          font-weight: 700;
          margin: 0 0 8px;
          color: #1a1a2e;
        }
        .ins-results-meta {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: 6px;
          color: #666;
          font-size: 14px;
          margin: 0;
        }
        .ins-sort-select {
          width: auto;
          min-width: 180px;
        }
        .ts-cards-list {
          display: flex;
          flex-direction: column;
          gap: 16px;
        }
        .ts-plan-card {
          background: #fff;
          border-radius: 12px;
          box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
          overflow: hidden;
        }
        .ts-plan-card-inner {
          display: flex;
          align-items: stretch;
          min-height: 200px;
        }
        .ts-plan-main {
          flex: 1;
          min-width: 0;
          display: flex;
          flex-direction: column;
        }
        .ts-plan-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          padding: 16px 20px 12px;
          gap: 16px;
          border-bottom: 1px solid #f0f0f0;
        }
        .ts-plan-brand {
          display: flex;
          align-items: center;
          gap: 10px;
        }
        .ts-shield-icon {
          position: relative;
          display: flex;
          align-items: center;
          justify-content: center;
          width: 40px;
          height: 40px;
          border-radius: 8px;
          background: linear-gradient(135deg, #1e88e5, #1565c0);
          color: #fff;
          flex-shrink: 0;
        }
        .ts-shield-plane {
          position: absolute;
          bottom: 6px;
          right: 6px;
          opacity: 0.95;
        }
        .ts-plan-name {
          font-size: 15px;
          color: #333;
        }
        .ts-plan-name strong {
          font-weight: 700;
          color: #111;
        }
        .ts-plan-pricing {
          text-align: right;
          flex-shrink: 0;
        }
        .ts-earn-badge {
          display: inline-block;
          padding: 3px 10px;
          border-radius: 4px;
          background: #e8f5e9;
          color: #2e7d32;
          font-size: 11px;
          font-weight: 600;
          margin-bottom: 4px;
        }
        .ts-price-block {
          display: flex;
          align-items: baseline;
          justify-content: flex-end;
          gap: 6px;
        }
        .ts-price {
          font-size: 1.35rem;
          font-weight: 700;
          color: #111;
        }
        .ts-price-gst {
          font-size: 12px;
          color: #888;
        }
        .ts-plan-body {
          display: flex;
          flex: 1;
          gap: 0;
          padding: 16px 20px;
        }
        .ts-plan-col {
          flex: 1;
          min-width: 0;
          padding-right: 20px;
        }
        .ts-plan-col + .ts-plan-col {
          padding-right: 0;
          padding-left: 20px;
          border-left: 1px solid #eee;
        }
        .ts-col-title {
          font-size: 14px;
          font-weight: 700;
          color: #111;
          margin: 0 0 4px;
        }
        .ts-col-sub {
          font-size: 12px;
          color: #888;
          margin: 0 0 12px;
        }
        .ts-tags-wrap {
          display: flex;
          flex-direction: column;
          gap: 8px;
        }
        .ts-tags-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 8px;
        }
        .ts-benefit-tag {
          display: inline-flex;
          align-items: flex-start;
          gap: 8px;
          padding: 8px 12px;
          background: #f5f5f5;
          border-radius: 8px;
          font-size: 12px;
          color: #444;
          line-height: 1.35;
          max-width: 100%;
        }
        .ts-benefit-check {
          flex-shrink: 0;
          color: #666;
          margin-top: 1px;
        }
        .ts-plan-footer {
          padding: 0 20px 16px;
          margin-top: auto;
        }
        .ts-view-benefits {
          border: none;
          background: none;
          padding: 0;
          color: #1976d2;
          font-size: 13px;
          font-weight: 500;
          cursor: pointer;
          display: inline-flex;
          align-items: center;
          gap: 2px;
          margin-bottom: 8px;
        }
        .ts-view-benefits:hover {
          text-decoration: underline;
        }
        .ts-disclaimer {
          font-size: 11px;
          color: #999;
          margin: 0;
          line-height: 1.4;
        }
        .ts-plan-action {
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 20px 24px;
          border-left: 1px solid #eee;
          background: #fafafa;
          min-width: 140px;
        }
        .ts-add-btn {
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          gap: 8px;
          width: 100%;
          min-width: 100px;
          padding: 20px 16px;
          border: none;
          border-radius: 10px;
          background: #ed1173;
          color: #fff;
          font-size: 15px;
          font-weight: 700;
          cursor: pointer;
          transition: background 0.2s, transform 0.15s;
        }
        .ts-add-btn:hover:not(:disabled) {
          background: #d10f65;
          transform: scale(1.02);
        }
        .ts-add-btn:disabled {
          opacity: 0.85;
          cursor: wait;
        }
        .ts-add-icon {
          display: flex;
          align-items: center;
          justify-content: center;
          width: 36px;
          height: 36px;
          border-radius: 50%;
          border: 2px solid rgba(255, 255, 255, 0.9);
        }
        .spin {
          animation: spin 1s linear infinite;
        }
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        @media (max-width: 991px) {
          .ts-plan-card-inner {
            flex-direction: column;
          }
          .ts-plan-action {
            border-left: none;
            border-top: 1px solid #eee;
            padding: 16px 20px;
          }
          .ts-add-btn {
            flex-direction: row;
            width: 100%;
            max-width: none;
          }
          .ts-plan-body {
            flex-direction: column;
          }
          .ts-plan-col + .ts-plan-col {
            border-left: none;
            border-top: 1px solid #eee;
            padding-left: 0;
            padding-top: 16px;
            margin-top: 4px;
          }
          .ts-plan-col {
            padding-right: 0;
          }
          .ts-tags-grid {
            grid-template-columns: 1fr;
          }
        }
        @media (max-width: 575px) {
          .ts-plan-header {
            flex-direction: column;
          }
          .ts-plan-pricing {
            text-align: left;
          }
          .ts-price-block {
            justify-content: flex-start;
          }
        }
      `}</style>
    </>
  );
};

export default TravelInsuranceResults;
