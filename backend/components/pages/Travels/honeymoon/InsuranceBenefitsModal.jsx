import React from 'react';
import { X } from 'lucide-react';

const InsuranceBenefitsModal = ({ open, planLabel, benefits, onClose }) => {
  if (!open) return null;

  const grouped = benefits.reduce((acc, benefit) => {
    const key = benefit.category || 'Other';
    if (!acc[key]) acc[key] = [];
    acc[key].push(benefit);
    return acc;
  }, {});

  return (
    <div className="ins-benefits-modal-backdrop" onClick={onClose} role="presentation">
      <div
        className="ins-benefits-modal"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="benefits-modal-title"
      >
        <div className="ins-benefits-modal-header">
          <div>
            <h4 id="benefits-modal-title" className="mb-1">
              All benefits
            </h4>
            <p className="text-muted small mb-0">{planLabel}</p>
          </div>
          <button type="button" className="ins-benefits-close" onClick={onClose} aria-label="Close">
            <X size={20} />
          </button>
        </div>

        <div className="ins-benefits-modal-body">
          {Object.entries(grouped).map(([category, items]) => (
            <div key={category} className="ins-benefits-group">
              <h6 className="ins-benefits-category">{category}</h6>
              <ul className="ins-benefits-list">
                {items.map((item) => (
                  <li key={item.name}>
                    <strong>{item.name}</strong>
                    {item.coverage ? (
                      <span className="ins-benefits-coverage"> — {item.coverage}</span>
                    ) : null}
                    {item.description ? (
                      <p className="ins-benefits-desc">{item.description}</p>
                    ) : null}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>

      <style>{`
        .ins-benefits-modal-backdrop {
          position: fixed;
          inset: 0;
          background: rgba(0, 0, 0, 0.5);
          z-index: 1050;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 16px;
        }
        .ins-benefits-modal {
          background: #fff;
          border-radius: 16px;
          max-width: 640px;
          width: 100%;
          max-height: 85vh;
          display: flex;
          flex-direction: column;
          box-shadow: 0 24px 64px rgba(0, 0, 0, 0.2);
        }
        .ins-benefits-modal-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          padding: 20px 20px 12px;
          border-bottom: 1px solid #f0e0e8;
        }
        .ins-benefits-close {
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
        .ins-benefits-modal-body {
          overflow-y: auto;
          padding: 16px 20px 24px;
        }
        .ins-benefits-group {
          margin-bottom: 20px;
        }
        .ins-benefits-category {
          font-size: 13px;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          color: #ed1173;
          margin-bottom: 10px;
          font-weight: 700;
        }
        .ins-benefits-list {
          margin: 0;
          padding-left: 18px;
        }
        .ins-benefits-list li {
          margin-bottom: 12px;
          color: #333;
          font-size: 14px;
        }
        .ins-benefits-coverage {
          color: #666;
          font-weight: 500;
        }
        .ins-benefits-desc {
          margin: 4px 0 0;
          font-size: 12px;
          color: #888;
        }
      `}</style>
    </div>
  );
};

export default InsuranceBenefitsModal;
