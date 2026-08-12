import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  Shield,
  Calendar,
  MapPin,
  Users,
  Mail,
  Phone,
  FileText,
  CheckCircle2,
  Loader2,
} from 'lucide-react';
import { getTripSafeBookingDetails } from '../../../../services/api/tripSafeApi';
import InsuranceBenefitsModal from './InsuranceBenefitsModal';
import InsuranceCancellationModal from './InsuranceCancellationModal';

const formatPrice = (value) => {
  const num = Number(value || 0);
  if (!num) return '—';
  return `₹${num.toLocaleString('en-IN', { maximumFractionDigits: 2 })}`;
};

const formatDate = (value) => {
  if (!value) return '—';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return value;
  return d.toLocaleDateString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
};

const formatDateTime = (value) => {
  if (!value) return '—';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return value;
  return d.toLocaleString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const InsuranceBookingDetailsPage = () => {
  const { bookingId: routeBookingId } = useParams();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [details, setDetails] = useState(null);
  const [benefitsOpen, setBenefitsOpen] = useState(false);
  const [cancelOpen, setCancelOpen] = useState(false);

  const reloadDetails = () => {
    if (!routeBookingId) return;
    setLoading(true);
    getTripSafeBookingDetails(routeBookingId)
      .then((result) => {
        if (result?.status) setDetails(result);
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    if (!routeBookingId) {
      navigate('/honeymoon');
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);

    getTripSafeBookingDetails(routeBookingId)
      .then((result) => {
        if (!active) return;
        if (!result?.status) {
          setError(result?.message || 'Could not load booking details');
          return;
        }
        setDetails(result);
      })
      .catch((err) => {
        if (!active) return;
        setError(
          err?.response?.data?.message ||
            err?.message ||
            'Failed to fetch booking details'
        );
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [routeBookingId, navigate]);

  if (loading) {
    return (
      <div className="ins-details-page d-flex align-items-center justify-content-center">
        <div className="text-center py-5">
          <Loader2 size={36} className="spin text-primary mb-3" />
          <p className="text-muted mb-0">Loading booking details...</p>
        </div>
      </div>
    );
  }

  if (error || !details) {
    return (
      <div className="ins-details-page container py-5">
        <div className="alert alert-danger">{error || 'Booking not found'}</div>
        <button type="button" className="btn btn-primary" onClick={() => navigate('/honeymoon')}>
          Back to search
        </button>
      </div>
    );
  }

  const isSuccess = String(details.orderStatus).toUpperCase() === 'SUCCESS';
  const previewBenefits = details.benefits.slice(0, 4).map((b) => b.name);

  return (
    <>
      <div className="ins-details-page">
        <div className="container py-4">
          <button
            type="button"
            className="btn btn-link text-decoration-none ps-0 mb-3"
            onClick={() => navigate('/honeymoon')}
          >
            ← Back to search
          </button>

          <div className={`ins-details-hero ${isSuccess ? 'success' : ''}`}>
            <CheckCircle2 size={40} className={isSuccess ? 'text-success' : 'text-warning'} />
            <div>
              <h2 className="mb-1">Booking {isSuccess ? 'Confirmed' : details.orderStatus}</h2>
              <p className="mb-0 text-muted">
                Booking ID: <strong>{details.bookingId}</strong>
                {details.createdOn ? ` · ${formatDateTime(details.createdOn)}` : ''}
              </p>
            </div>
          </div>

          <div className="row g-4">
            <div className="col-lg-8">
              <div className="ins-details-card">
                <h5 className="ins-details-card-title">
                  <Shield size={18} /> Plan details
                </h5>
                <div className="ins-details-plan-row">
                  <div>
                    <h4 className="mb-1">{details.planLabel}</h4>
                    <p className="text-muted mb-2">
                      {details.coverageAmount} · {details.regionName}
                    </p>
                    <div className="d-flex flex-wrap gap-2">
                      {details.insurer && (
                        <span className="insurance-badge">{details.insurer}</span>
                      )}
                      {details.partners?.map((p) => (
                        <span className="insurance-badge muted" key={p}>
                          {p}
                        </span>
                      ))}
                    </div>
                  </div>
                  <div className="ins-details-amount">{formatPrice(details.amount)}</div>
                </div>

                <div className="ins-details-meta-grid">
                  <div>
                    <Calendar size={14} />
                    <span>Travel dates</span>
                    <strong>
                      {formatDate(details.startDate)} – {formatDate(details.endDate)}
                    </strong>
                  </div>
                  <div>
                    <MapPin size={14} />
                    <span>Region</span>
                    <strong>{details.regionName || '—'}</strong>
                  </div>
                  {details.activeFrom && (
                    <div>
                      <FileText size={14} />
                      <span>Active from</span>
                      <strong>{formatDate(details.activeFrom)}</strong>
                    </div>
                  )}
                </div>

                {previewBenefits.length > 0 && (
                  <ul className="ins-details-highlights">
                    {previewBenefits.map((name) => (
                      <li key={name}>{name}</li>
                    ))}
                  </ul>
                )}

                {details.benefits?.length > 0 && (
                  <button
                    type="button"
                    className="ins-benefits-link mt-2"
                    onClick={() => setBenefitsOpen(true)}
                  >
                    View all {details.benefits.length} benefits
                  </button>
                )}
              </div>

              <div className="ins-details-card mt-4">
                <h5 className="ins-details-card-title">
                  <Users size={18} /> Travellers
                </h5>
                {details.travellers.map((traveller) => (
                  <div key={traveller.id} className="ins-traveller-detail">
                    <div className="ins-traveller-detail-header">
                      <strong>{traveller.name}</strong>
                      <span className="text-muted">
                        {traveller.age} yrs · {traveller.gender}
                      </span>
                    </div>
                    <div className="ins-traveller-detail-grid">
                      <div>
                        <Mail size={14} />
                        <span>{traveller.email || '—'}</span>
                      </div>
                      <div>
                        <Phone size={14} />
                        <span>{traveller.mobile || '—'}</span>
                      </div>
                      <div>
                        <FileText size={14} />
                        <span>Passport: {traveller.passport || '—'}</span>
                      </div>
                      <div>
                        <MapPin size={14} />
                        <span>Pincode: {traveller.pincode || '—'}</span>
                      </div>
                      {traveller.policyId && (
                        <div className="ins-policy-id">
                          <Shield size={14} />
                          <span>
                            Policy ID: <strong>{traveller.policyId}</strong>
                          </span>
                        </div>
                      )}
                      {traveller.nominee && (
                        <div>
                          <Users size={14} />
                          <span>Nominee: {traveller.nominee}</span>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="col-lg-4">
              <div className="ins-details-card ins-details-summary sticky-top">
                <h5 className="mb-3">Order summary</h5>
                <div className="ins-summary-line">
                  <span>Status</span>
                  <span className={`ins-status-pill ${isSuccess ? 'ok' : ''}`}>
                    {details.orderStatus}
                  </span>
                </div>
                <div className="ins-summary-line">
                  <span>Total paid</span>
                  <strong>{formatPrice(details.amount)}</strong>
                </div>
                {details.deliveryInfo?.emails?.[0] && (
                  <div className="ins-summary-line">
                    <span>Email</span>
                    <small>{details.deliveryInfo.emails[0]}</small>
                  </div>
                )}
                {details.deliveryInfo?.contacts?.[0] && (
                  <div className="ins-summary-line">
                    <span>Contact</span>
                    <small>{details.deliveryInfo.contacts[0]}</small>
                  </div>
                )}
                <button
                  type="button"
                  className="btn ins-select-btn w-100 mt-3"
                  onClick={() => navigate('/honeymoon')}
                >
                  Book another plan
                </button>
                {isSuccess && details.plid && details.pid && (
                  <button
                    type="button"
                    className="btn btn-outline-danger w-100 mt-2"
                    onClick={() => setCancelOpen(true)}
                  >
                    Cancel this booking
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      <InsuranceCancellationModal
        open={cancelOpen}
        details={details}
        onClose={() => setCancelOpen(false)}
        onSuccess={reloadDetails}
      />

      <InsuranceBenefitsModal
        open={benefitsOpen}
        planLabel={details.planLabel}
        benefits={details.benefits}
        onClose={() => setBenefitsOpen(false)}
      />

      <style>{`
        .ins-details-page {
          background: #faf8f9;
          min-height: 100vh;
        }
        .ins-details-hero {
          display: flex;
          align-items: center;
          gap: 16px;
          background: #fff;
          border-radius: 16px;
          padding: 24px;
          margin-bottom: 24px;
          border: 1px solid #eee;
          box-shadow: 0 4px 20px rgba(0,0,0,0.04);
        }
        .ins-details-hero.success {
          border-color: rgba(25, 135, 84, 0.3);
          background: linear-gradient(135deg, #fff, #f0fff4);
        }
        .ins-details-card {
          background: #fff;
          border-radius: 16px;
          padding: 24px;
          border: 1px solid #f0e0e8;
        }
        .ins-details-card-title {
          display: flex;
          align-items: center;
          gap: 8px;
          font-size: 1rem;
          font-weight: 700;
          margin-bottom: 20px;
          color: #333;
        }
        .ins-details-plan-row {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          gap: 16px;
          margin-bottom: 20px;
        }
        .ins-details-amount {
          font-size: 1.5rem;
          font-weight: 800;
          color: #ed1173;
          white-space: nowrap;
        }
        .ins-details-meta-grid {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
          gap: 16px;
          margin-bottom: 16px;
        }
        .ins-details-meta-grid > div {
          display: flex;
          flex-direction: column;
          gap: 4px;
          font-size: 13px;
        }
        .ins-details-meta-grid span {
          color: #999;
          display: flex;
          align-items: center;
          gap: 6px;
        }
        .ins-details-meta-grid strong {
          color: #222;
          font-size: 14px;
        }
        .ins-details-highlights {
          margin: 0;
          padding-left: 18px;
          font-size: 13px;
          color: #444;
        }
        .ins-details-highlights li {
          margin-bottom: 4px;
        }
        .ins-traveller-detail {
          border: 1px solid #f0e0e8;
          border-radius: 12px;
          padding: 16px;
          margin-bottom: 12px;
        }
        .ins-traveller-detail:last-child {
          margin-bottom: 0;
        }
        .ins-traveller-detail-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 12px;
          padding-bottom: 12px;
          border-bottom: 1px solid #f5f5f5;
        }
        .ins-traveller-detail-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 10px;
          font-size: 13px;
        }
        .ins-traveller-detail-grid > div {
          display: flex;
          align-items: center;
          gap: 8px;
          color: #555;
        }
        .ins-policy-id {
          grid-column: 1 / -1;
          color: #c0006a;
        }
        .ins-summary-line {
          display: flex;
          justify-content: space-between;
          align-items: center;
          gap: 12px;
          margin-bottom: 12px;
          font-size: 14px;
        }
        .ins-summary-line span:first-child {
          color: #888;
        }
        .ins-status-pill {
          padding: 4px 10px;
          border-radius: 999px;
          background: #fff3cd;
          color: #856404;
          font-size: 12px;
          font-weight: 600;
        }
        .ins-status-pill.ok {
          background: rgba(25, 135, 84, 0.15);
          color: #198754;
        }
        .insurance-badge {
          display: inline-block;
          padding: 4px 10px;
          border-radius: 999px;
          background: rgba(237, 17, 115, 0.1);
          color: #c0006a;
          font-size: 12px;
          font-weight: 600;
        }
        .insurance-badge.muted {
          background: #f5f5f5;
          color: #666;
        }
        .ins-benefits-link {
          border: none;
          background: none;
          padding: 0;
          color: #ed1173;
          font-size: 13px;
          text-decoration: underline;
          cursor: pointer;
        }
        .ins-select-btn {
          background: linear-gradient(135deg, #ed1173, #ff6b9d);
          border: none;
          color: #fff;
          font-weight: 600;
        }
        .spin {
          animation: spin 1s linear infinite;
        }
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        @media (max-width: 575px) {
          .ins-traveller-detail-grid {
            grid-template-columns: 1fr;
          }
        }
      `}</style>
    </>
  );
};

export default InsuranceBookingDetailsPage;
