import React, { useEffect, useMemo, useState } from 'react';
import { X, AlertTriangle, Loader2, CheckCircle2 } from 'lucide-react';
import {
  raiseInsuranceCancellation,
  confirmInsuranceCancellation,
} from '../../../../services/api/tripSafeApi';

const InsuranceCancellationModal = ({ open, details, onClose, onSuccess }) => {
  const [step, setStep] = useState('choose');
  const [selectedIds, setSelectedIds] = useState([]);
  const [amendmentId, setAmendmentId] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const travellers = details?.travellers || [];

  const allSelected = useMemo(() => {
    if (!travellers.length) return true;
    return travellers.every((t) => selectedIds.includes(t.id));
  }, [travellers, selectedIds]);

  useEffect(() => {
    if (!open) return;
    setStep('choose');
    setAmendmentId('');
    setError(null);
    setLoading(false);
    setSelectedIds(travellers.map((t) => t.id));
  }, [open, details?.bookingId]);

  const resetState = () => {
    setStep('choose');
    setSelectedIds(travellers.map((t) => t.id));
    setAmendmentId('');
    setError(null);
    setLoading(false);
  };

  const handleClose = () => {
    resetState();
    onClose();
  };

  if (!open || !details) return null;

  const toggleTraveller = (id) => {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
  };

  const getSelectedIds = () =>
    selectedIds.length ? selectedIds : travellers.map((t) => t.id);

  const handleRaise = async () => {
    setLoading(true);
    setError(null);
    try {
      const ids = getSelectedIds();
      const result = await raiseInsuranceCancellation(details, ids);
      if (!result?.status) {
        setError(result?.message || 'Raise amendment failed');
        return;
      }
      if (result.amendmentId) {
        setAmendmentId(String(result.amendmentId));
      }
      setStep('confirm');
    } catch (err) {
      setError(
        err?.response?.data?.message || err?.message || 'Raise amendment failed'
      );
    } finally {
      setLoading(false);
    }
  };

  const handleConfirm = async () => {
    if (!amendmentId.trim()) {
      setError('Enter amendment ID from the raise step');
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const result = await confirmInsuranceCancellation(
        details,
        amendmentId.trim(),
        getSelectedIds()
      );
      if (!result?.status) {
        setError(result?.message || 'Confirm cancellation failed');
        return;
      }
      setStep('done');
      onSuccess?.();
    } catch (err) {
      setError(
        err?.response?.data?.message ||
          err?.message ||
          'Confirm cancellation failed'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="ins-cancel-backdrop" onClick={handleClose} role="presentation">
      <div
        className="ins-cancel-modal"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
      >
        <div className="ins-cancel-header">
          <h4 className="mb-0">Cancel insurance booking</h4>
          <button type="button" className="ins-cancel-close" onClick={handleClose}>
            <X size={20} />
          </button>
        </div>

        <div className="ins-cancel-body">
          {step === 'choose' && (
            <>
              <div className="ins-cancel-warning">
                <AlertTriangle size={20} />
                <p>
                  Cancellation is a two-step process: <strong>raise amendment</strong>, then{' '}
                  <strong>confirm cancellation</strong>. Booking ID: {details.bookingId}
                </p>
              </div>

              <p className="small text-muted mb-2">Select travellers to cancel</p>
              {travellers.map((t) => (
                <label key={t.id} className="ins-cancel-traveller">
                  <input
                    type="checkbox"
                    checked={selectedIds.includes(t.id)}
                    onChange={() => toggleTraveller(t.id)}
                  />
                  <span>
                    {t.name} (ID {t.id})
                    {t.policyId ? ` · Policy ${t.policyId}` : ''}
                  </span>
                </label>
              ))}

              <button
                type="button"
                className="btn btn-outline-secondary btn-sm mt-2"
                onClick={() =>
                  setSelectedIds(allSelected ? [] : travellers.map((tr) => tr.id))
                }
              >
                {allSelected ? 'Deselect all' : 'Select all'}
              </button>
            </>
          )}

          {step === 'confirm' && (
            <>
              <div className="ins-cancel-step-badge">Step 2 of 2</div>
              <p className="mb-2">
                Amendment raised. Confirm cancellation with the amendment ID below.
              </p>
              <label className="form-label small">Amendment ID</label>
              <input
                type="text"
                className="form-control"
                value={amendmentId}
                onChange={(e) => setAmendmentId(e.target.value)}
                placeholder="e.g. 170000743562"
              />
            </>
          )}

          {step === 'done' && (
            <div className="text-center py-3">
              <CheckCircle2 size={48} className="text-success mb-3" />
              <h5>Cancellation confirmed</h5>
              <p className="text-muted small mb-0">
                Booking {details.bookingId} has been cancelled.
              </p>
            </div>
          )}

          {error && <div className="alert alert-danger py-2 mt-3 mb-0">{error}</div>}
        </div>

        <div className="ins-cancel-footer">
          {step === 'choose' && (
            <>
              <button type="button" className="btn btn-light" onClick={handleClose}>
                Close
              </button>
              <button
                type="button"
                className="btn btn-warning"
                disabled={loading || !getSelectedIds().length}
                onClick={handleRaise}
              >
                {loading ? (
                  <span className="d-inline-flex align-items-center gap-2">
                    <Loader2 size={16} className="spin" /> Raising…
                  </span>
                ) : (
                  'Step 1: Raise cancellation'
                )}
              </button>
            </>
          )}

          {step === 'confirm' && (
            <>
              <button
                type="button"
                className="btn btn-light"
                onClick={() => setStep('choose')}
                disabled={loading}
              >
                Back
              </button>
              <button
                type="button"
                className="btn btn-danger"
                disabled={loading}
                onClick={handleConfirm}
              >
                {loading ? (
                  <span className="d-inline-flex align-items-center gap-2">
                    <Loader2 size={16} className="spin" /> Confirming…
                  </span>
                ) : (
                  'Step 2: Confirm cancellation'
                )}
              </button>
            </>
          )}

          {step === 'done' && (
            <button type="button" className="btn btn-primary w-100" onClick={handleClose}>
              Done
            </button>
          )}
        </div>
      </div>

      <style>{`
        .ins-cancel-backdrop {
          position: fixed;
          inset: 0;
          background: rgba(0, 0, 0, 0.5);
          z-index: 1060;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 16px;
        }
        .ins-cancel-modal {
          background: #fff;
          border-radius: 16px;
          max-width: 480px;
          width: 100%;
          max-height: 90vh;
          display: flex;
          flex-direction: column;
          box-shadow: 0 24px 64px rgba(0, 0, 0, 0.2);
        }
        .ins-cancel-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 20px 20px 12px;
          border-bottom: 1px solid #eee;
        }
        .ins-cancel-close {
          border: none;
          background: #f5f5f5;
          border-radius: 50%;
          width: 36px;
          height: 36px;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
        }
        .ins-cancel-body {
          padding: 16px 20px;
          overflow-y: auto;
        }
        .ins-cancel-warning {
          display: flex;
          gap: 12px;
          padding: 12px;
          background: #fff8e6;
          border-radius: 10px;
          margin-bottom: 16px;
          font-size: 13px;
          color: #664d03;
        }
        .ins-cancel-warning p {
          margin: 0;
        }
        .ins-cancel-traveller {
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 10px 12px;
          border: 1px solid #eee;
          border-radius: 8px;
          margin-bottom: 8px;
          cursor: pointer;
          font-size: 14px;
        }
        .ins-cancel-step-badge {
          display: inline-block;
          padding: 4px 10px;
          background: #e3f2fd;
          color: #1565c0;
          border-radius: 999px;
          font-size: 12px;
          font-weight: 600;
          margin-bottom: 12px;
        }
        .ins-cancel-footer {
          display: flex;
          justify-content: flex-end;
          gap: 10px;
          padding: 16px 20px;
          border-top: 1px solid #eee;
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

export default InsuranceCancellationModal;
