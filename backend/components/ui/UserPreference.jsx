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
      width: 550px;
      z-index: 1050;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    }

    .cookie-gradient {
      background: linear-gradient(135deg, #f472b6 0%, #ec4899 50%, #f43f5e 100%);
      padding: 24px;
      position: relative;
      overflow: hidden;
    }

    .cookie-gradient::before {
      content: '';
      position: absolute;
      top: 0;
      left: -100%;
      width: 100%;
      height: 100%;
      background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.3), transparent);
      transition: left 1s ease-in-out;
      pointer-events: none;
    }

    .cookie-gradient:hover::before {
      left: 100%;
    }

    .cookie-icon {
      width: 150px;
      height: 150px;
      background: white;
      border-radius: 50%;
      flex-shrink: 0;
      padding: 8px;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    }

    .cookie-icon img {
      width: 100%;
      height: 100%;
      object-fit: contain;
      display: block;
    }

    .cookie-title {
      color: white;
      font-size: 1.125rem;
      font-weight: 600;
      margin-bottom: 8px;
    }

    .cookie-text {
      color: rgba(255, 255, 255, 0.95);
      font-size: 0.875rem;
      line-height: 1.5;
      margin: 0;
    }

    .btn-reject {
      background: rgba(255, 255, 255, 0.2);
      border: 1px solid rgba(255, 255, 255, 0.3);
      color: white;
      font-weight: 500;
      backdrop-filter: blur(10px);
      transition: all 0.2s;
    }

    .btn-reject:hover {
      background: rgba(255, 255, 255, 0.3);
      color: white;
      border-color: rgba(255, 255, 255, 0.4);
    }

    .btn-accept {
      background: white;
      color: #ec4899;
      font-weight: 500;
      border: none;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
      transition: all 0.2s;
    }

    .btn-accept:hover {
      background: #fce7f3;
      color: #ec4899;
      transform: translateY(-1px);
      box-shadow: 0 6px 16px rgba(0, 0, 0, 0.2);
    }
  `;

  return (
    <>
      <style>{styles}</style>
      <div className="cookie-consent">
        <div className="cookie-gradient">
          <div className="d-flex align-items-start gap-3 mb-4">
            <div className="cookie-icon d-flex align-items-center justify-content-center">
              {/* 185KB PNG for a ~48px icon. It is decorative and sits in a
                  banner nobody reads before the hero paints, so keep it out of
                  the critical fetch queue. It still needs re-encoding — see the
                  perf notes; lazy loading only moves the cost, it doesn't
                  remove it. */}
              <img
                src="/images/auth/cookie.png"
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
