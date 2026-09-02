import React, { useState } from "react";

const UserPreference = () => {
  const [visible, setVisible] = useState(() => {
    if (typeof window === "undefined") return true;
    const stored = window.localStorage.getItem("cookieConsent");
    return !stored;
  });

  const handleChoice = (choice) => {
    try {
      window.localStorage.setItem("cookieConsent", choice);
    } catch {}
    setVisible(false);
  };

  if (!visible) return null;

  const styles = `
    .cookie-consent {
      position: fixed;
      bottom: 24px;
      right: 24px;
      width: 480px;
      max-width: calc(100vw - 32px);
      z-index: 1050;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 12px 40px rgba(0, 0, 0, 0.12);
      border: 1px solid rgba(232, 53, 129, 0.18);
      background: #ffffff;
    }

    .cookie-gradient {
      background: #ffffff;
      padding: 24px;
      position: relative;
    }

    .cookie-icon {
      width: 64px;
      height: 64px;
      background: #fff0f5;
      border-radius: 50%;
      flex-shrink: 0;
      padding: 8px;
      border: 1px solid rgba(232, 53, 129, 0.15);
    }

    .cookie-icon img {
      width: 100%;
      height: 100%;
      object-fit: contain;
      display: block;
    }

    .cookie-title {
      color: #111827;
      font-size: 1.125rem;
      font-weight: 700;
      margin-bottom: 6px;
    }

    .cookie-text {
      color: #4b5563;
      font-size: 0.875rem;
      line-height: 1.5;
      margin: 0;
    }

    .btn-reject {
      background: #f3f4f6;
      border: 1px solid #e5e7eb;
      color: #374151;
      font-weight: 600;
      transition: all 0.2s;
    }

    .btn-reject:hover {
      background: #e5e7eb;
      color: #111827;
    }

    .btn-accept {
      background: linear-gradient(135deg, #e83581 0%, #c2185b 100%);
      color: #ffffff;
      font-weight: 600;
      border: none;
      box-shadow: 0 4px 14px rgba(232, 53, 129, 0.35);
      transition: all 0.2s;
    }

    .btn-accept:hover {
      transform: translateY(-1px);
      box-shadow: 0 6px 18px rgba(232, 53, 129, 0.45);
      color: #ffffff;
    }

    @media (max-width: 576px) {
      .cookie-consent {
        bottom: 12px;
        right: 12px;
        left: 12px;
        width: auto;
        max-width: none;
        border-radius: 12px;
      }
      .cookie-gradient {
        padding: 16px;
      }
      .cookie-icon {
        width: 50px;
        height: 50px;
        padding: 4px;
      }
      .cookie-title {
        font-size: 1rem;
        margin-bottom: 4px;
      }
      .cookie-text {
        font-size: 0.8rem;
        line-height: 1.3;
      }
    }
  `;

  return (
    <>
      <style>{styles}</style>
      <div className="cookie-consent">
        <div className="cookie-gradient">
          <div className="d-flex align-items-start gap-3 mb-4">
            <div className="cookie-icon d-flex align-items-center justify-content-center">
              {/* Was a 184KB 566x441 PNG for an icon that renders at ~134x104 —
                  the single largest first-party image on the page, and lazy
                  loading only moved that cost rather than removing it. Now a
                  268x208 WebP (2x for retina) at 18.6KB. The original is still
                  at images/auth/cookie.png if the source art is needed. */}
              <img
                src="/images/auth/cookie.webp"
                alt=""
                width="48"
                height="48"
                loading="lazy"
                decoding="async"
                fetchPriority="low"
              />
            </div>

            <div className="flex-grow-1">
              <h3 className="cookie-title">Cookie Settings</h3>
              <p className="cookie-text">
                We use cookies to enhance your browsing experience and analyze
                our traffic. Choose your preference below.
              </p>
            </div>
          </div>

          <div className="d-flex gap-3">
            <button
              onClick={() => handleChoice("rejected")}
              className="btn btn-reject flex-fill py-2 rounded-3"
            >
              Reject
            </button>
            <button
              onClick={() => handleChoice("accepted")}
              className="btn btn-accept flex-fill py-2 rounded-3"
            >
              Accept
            </button>
          </div>
        </div>
      </div>
    </>
  );
};

export default UserPreference;
