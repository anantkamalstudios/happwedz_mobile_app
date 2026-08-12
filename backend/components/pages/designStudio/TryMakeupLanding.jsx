import { Checkbox } from "@mui/material";
import { pink } from "@mui/material/colors";
import React, { useState } from "react";
import { IoClose } from "react-icons/io5";
import { useNavigate } from "react-router-dom";

const PolicyModal = ({ open, onClose, onAgree }) => {
  const [agreeOne, setAgreeOne] = useState(false);
  const [agreeTwo, setAgreeTwo] = useState(false);

  const allAgreed = agreeOne && agreeTwo;
  const { type } = JSON.parse(localStorage.getItem("userInfo"));

  if (!open) return null;

  return (
    <div
      className="modal fade show d-block"
      tabIndex="-1"
      role="dialog"
      aria-modal="true"
      style={{
        backdropFilter: "blur(8px)",
        WebkitBackdropFilter: "blur(8px)",
        backgroundColor: "rgba(0, 0, 0, 0.5)",
        position: "fixed",
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        zIndex: 1050,
      }}
    >
      <div className="modal-dialog modal-dialog-centered border-0">
        <div
          className="modal-content border-0 p-4"
          style={{
            maxWidth: "430px",
            margin: "0 auto",
            fontWeight: "300",
            color: "#fff",
            backgroundColor: "#C31162",
          }}
        >
          {/* Close button */}
          <div className="d-flex" style={{ position: "relative" }}>
            <div className="w-100 text-center">
              <h4 className="fw-bold">Our Privacy</h4>
            </div>
            <div style={{ position: "absolute", right: "-5px", top: "-5px" }}>
              <button
                type="button"
                className="btn p-0 border-0"
                onClick={onClose}
                style={{
                  fontSize: "1.5rem",
                  lineHeight: 1,
                  fontWeight: "bold",
                  color: "#fff",
                }}
              >
                <IoClose />
              </button>
            </div>
          </div>
          <p className="mt-3 text-start small text-justify fs-14">
            To access this service, you must be at least 18 years old.
          </p>
          <p className="fs-14 text-justify text-justify">
            By continuing, you agree that HappyWedz may temporarily store your
            uploaded image only for the purpose of applying AI filters and
            generating your virtual try-on experience. Your photos are never
            shared, sold, or used for any purpose other than providing this
            feature. Images are stored securely and automatically deleted within
            a short period after processing, in line with our data retention
            policy.
          </p>

          <span className="fw-medium text-center mb-3">Privacy Notice</span>
          {/* Checkbox 1 */}
          <div className="mb-3 d-flex align-items-start gap-2">
            <div
              onClick={() => setAgreeOne(!agreeOne)}
              style={{
                width: "18px",
                height: "18px",
                border: "2px solid #fff",
                borderRadius: "4px",
                cursor: "pointer",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                backgroundColor: agreeOne ? "#fff" : "transparent",
              }}
            >
              {agreeOne && (
                <span
                  style={{
                    color: "#C31162",
                    fontSize: "14px",
                    fontWeight: "bold",
                    marginTop: "-2px",
                  }}
                >
                  ✔
                </span>
              )}
            </div>
            <label
              htmlFor="agreeOne"
              className="fs-14 text-justify"
              style={{ fontWeight: "400", color: "#fff" }}
            >
              I consent to the use of my image to apply virtual{" "}
              {type === "makeup"
                ? "makeup filters"
                : type === "jewellary"
                ? "jewellery filters"
                : "dress filters"}{" "}
              and agree to the use of AI processing as described.
            </label>
          </div>
          {/* Checkbox 2 */}
          <div className="mb-4 d-flex align-items-start gap-2">
            <div
              onClick={() => setAgreeTwo(!agreeTwo)}
              style={{
                width: "18px",
                height: "18px",
                border: "2px solid #fff",
                borderRadius: "4px",
                cursor: "pointer",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                backgroundColor: agreeTwo ? "#fff" : "transparent",
              }}
            >
              {agreeTwo && (
                <span
                  style={{
                    color: "#C31162",
                    fontSize: "14px",
                    fontWeight: "bold",
                    marginTop: "-2px",
                  }}
                >
                  ✔
                </span>
              )}
            </div>
            <label
              htmlFor="agreeTwo"
              className="fs-14 text-justify"
              style={{ fontWeight: "400", color: "#fff" }}
            >
              I am at least 18 years old and agree to the terms and privacy
              practices of HappyWedz.
            </label>
          </div>
          {/* CTA Button */}
          <div className="d-grid">
            <button
              style={{
                backgroundColor: "#fff",
                fontWeight: "500",
                border: "2px solid #C31162",
                padding: "0.5rem 0",
                borderRadius: "10px",
                color: "#C31162",
                fontSize: "1.1rem",
                width: "100%",
              }}
              disabled={!allAgreed}
              onClick={onAgree}
            >
              I Consent
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

const TryMakeupLanding = () => {
  const navigate = useNavigate();
  const [open, setOpen] = useState(true);

  const role = JSON.parse(localStorage.getItem("userInfo"))?.role;

  const handleClose = () => {
    setOpen(false);
    navigate(-1);
  };
  const handleAgree = () => {
    setOpen(false);
    navigate("/try/upload");
  };

  return (
    <div className="container py-5">
      <PolicyModal open={open} onClose={handleClose} onAgree={handleAgree} />
    </div>
  );
};

export default TryMakeupLanding;
