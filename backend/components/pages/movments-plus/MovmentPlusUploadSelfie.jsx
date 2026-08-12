import React, { useState, useRef, useEffect } from "react";
import { IoClose } from "react-icons/io5";
import { useNavigate } from "react-router-dom";
import { FaCamera, FaCloudUploadAlt } from "react-icons/fa";

const PolicyModal = ({ open, onClose, onAgree }) => {
  const [agreeOne, setAgreeOne] = useState(false);
  const [agreeTwo, setAgreeTwo] = useState(false);

  const allAgreed = agreeOne && agreeTwo;

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
            borderRadius: "20px",
          }}
        >
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
          <p className="fs-14 text-justify">
            By continuing, you agree that HappyWedz may temporarily store your
            uploaded image only for the purpose of applying AI face recognition
            to find your photos. Your photos are never shared, sold, or used for
            any purpose other than providing this feature. Images are stored
            securely and automatically deleted within a short period after
            processing, in line with our data retention policy.
          </p>

          <span className="fw-medium text-center mb-3 d-block">
            Privacy Notice
          </span>

          <div className="mb-3 d-flex align-items-start gap-2">
            <div
              onClick={() => setAgreeOne(!agreeOne)}
              style={{
                minWidth: "18px",
                width: "18px",
                height: "18px",
                border: "2px solid #fff",
                borderRadius: "4px",
                cursor: "pointer",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                backgroundColor: agreeOne ? "#fff" : "transparent",
                marginTop: "3px",
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
              className="fs-14 text-justify"
              style={{ fontWeight: "400", color: "#fff", cursor: "pointer" }}
              onClick={() => setAgreeOne(!agreeOne)}
            >
              I consent to the use of my image for AI face recognition
              processing to find my photos and agree to the described usage.
            </label>
          </div>

          <div className="mb-4 d-flex align-items-start gap-2">
            <div
              onClick={() => setAgreeTwo(!agreeTwo)}
              style={{
                minWidth: "18px",
                width: "18px",
                height: "18px",
                border: "2px solid #fff",
                borderRadius: "4px",
                cursor: "pointer",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                backgroundColor: agreeTwo ? "#fff" : "transparent",
                marginTop: "3px",
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
              className="fs-14 text-justify"
              style={{ fontWeight: "400", color: "#fff", cursor: "pointer" }}
              onClick={() => setAgreeTwo(!agreeTwo)}
            >
              I am at least 18 years old and agree to the terms and privacy
              practices of HappyWedz.
            </label>
          </div>

          <div className="d-grid">
            <button
              style={{
                backgroundColor: "#fff",
                fontWeight: "600",
                border: "2px solid #C31162",
                padding: "0.6rem 0",
                borderRadius: "10px",
                color: "#C31162",
                fontSize: "1.1rem",
                width: "100%",
                transition: "all 0.3s ease",
                opacity: allAgreed ? 1 : 0.7,
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

const UploadSelectionModal = ({ open, onClose }) => {
  const fileInputRef = useRef(null);
  const videoRef = useRef(null);
  const [isCameraOpen, setIsCameraOpen] = useState(false);
  const [stream, setStream] = useState(null);
  const [capturedImage, setCapturedImage] = useState(null);

  if (!open) return null;

  const handleUploadClick = () => {
    if (fileInputRef.current) {
      fileInputRef.current.click();
    }
  };

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      console.log("File selected:", file.name);
    }
  };

  const startCamera = async () => {
    try {
      setCapturedImage(null);
      const mediaStream = await navigator.mediaDevices.getUserMedia({
        video: true,
      });
      setStream(mediaStream);
      setIsCameraOpen(true);
    } catch (err) {
      console.error("Error accessing camera:", err);
      alert(
        "Could not access camera. Please check permissions or try uploading a file.",
      );
    }
  };

  const stopCamera = () => {
    if (stream) {
      stream.getTracks().forEach((track) => track.stop());
      setStream(null);
    }
    setIsCameraOpen(false);
  };

  const takeSelfie = () => {
    if (videoRef.current) {
      const canvas = document.createElement("canvas");
      canvas.width = videoRef.current.videoWidth;
      canvas.height = videoRef.current.videoHeight;
      const ctx = canvas.getContext("2d");
      ctx.drawImage(videoRef.current, 0, 0, canvas.width, canvas.height);
      const imageSrc = canvas.toDataURL("image/png");
      console.log("Selfie captured:", imageSrc);
      setCapturedImage(imageSrc);
      stopCamera();
    }
  };

  useEffect(() => {
    if (isCameraOpen && videoRef.current && stream) {
      videoRef.current.srcObject = stream;
    }
  }, [isCameraOpen, stream]);

  useEffect(() => {
    return () => {
      if (stream) {
        stream.getTracks().forEach((track) => track.stop());
      }
    };
  }, []);

  return (
    <div
      className="modal fade show d-block"
      tabIndex="-1"
      role="dialog"
      aria-modal="true"
      style={{
        backdropFilter: "blur(5px)",
        backgroundColor: "rgba(255, 255, 255, 0.8)",
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
          className="modal-content border-0 p-4 p-md-5 text-center shadow-lg"
          style={{
            maxWidth: "500px",
            margin: "0 auto",
            borderRadius: "24px",
            backgroundColor: "#fff",
          }}
        >
          <div style={{ position: "absolute", right: "20px", top: "20px" }}>
            <button
              type="button"
              className="btn p-0 border-0 rounded-circle"
              onClick={() => {
                stopCamera();
                onClose();
              }}
              style={{
                width: "32px",
                height: "32px",
                backgroundColor: "#C31162",
                color: "#fff",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <IoClose size={20} />
            </button>
          </div>

          <h3 className="fw-bold mb-2" style={{ color: "#000" }}>
            Let Us Find Your Photos
          </h3>
          <p className="text-muted mb-4">
            Face recognition that finds your photos
          </p>

          <div className="mb-5 d-flex justify-content-center">
            <div
              style={{
                width: "300px",
                height: "300px",
                position: "relative",
                overflow: "hidden",
                borderRadius: "16px",
                backgroundColor: isCameraOpen ? "#000" : "transparent",
              }}
            >
              {isCameraOpen ? (
                <video
                  ref={videoRef}
                  autoPlay
                  playsInline
                  style={{
                    width: "100%",
                    height: "100%",
                    objectFit: "cover",
                    transform: "scaleX(-1)",
                  }}
                />
              ) : capturedImage ? (
                <img
                  src={capturedImage}
                  alt="Captured Selfie"
                  style={{
                    width: "100%",
                    height: "100%",
                    objectFit: "cover",
                    transform: "scaleX(-1)",
                  }}
                />
              ) : (
                <img
                  src="/images/movments-plus/selfie.png"
                  alt="Selfie illustration"
                  style={{
                    width: "100%",
                    height: "100%",
                    objectFit: "contain",
                  }}
                />
              )}
            </div>
          </div>

          {/* Action Buttons */}
          <div className="d-flex flex-col gap-3 w-100 flex-column">
            {!isCameraOpen ? (
              <>
                <button
                  className="btn w-100 py-2 fw-semibold"
                  onClick={startCamera}
                  style={{
                    backgroundColor: "#C31162",
                    color: "white",
                    borderRadius: "12px",
                    border: "none",
                    fontSize: "16px",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    gap: "10px",
                    boxShadow: "0 4px 15px rgba(195, 17, 98, 0.3)",
                  }}
                >
                  <FaCamera size={18} /> Selfie Mode
                </button>

                <button
                  className="btn w-100 py-2 fw-semibold"
                  onClick={handleUploadClick}
                  style={{
                    backgroundColor: "#C31162",
                    color: "white",
                    borderRadius: "12px",
                    border: "none",
                    fontSize: "16px",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    gap: "10px",
                    boxShadow: "0 4px 15px rgba(195, 17, 98, 0.3)",
                  }}
                >
                  <FaCloudUploadAlt size={20} /> Upload Photo
                </button>
              </>
            ) : (
              <button
                className="btn w-100 py-2 fw-semibold"
                onClick={takeSelfie}
                style={{
                  backgroundColor: "#C31162",
                  color: "white",
                  borderRadius: "12px",
                  border: "none",
                  fontSize: "16px",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "10px",
                  boxShadow: "0 4px 15px rgba(195, 17, 98, 0.3)",
                }}
              >
                <FaCamera size={18} /> Take Selfie
              </button>
            )}

            <input
              type="file"
              ref={fileInputRef}
              style={{ display: "none" }}
              onChange={handleFileChange}
              accept="image/*"
            />
          </div>
        </div>
      </div>
    </div>
  );
};

const MovmentPlusUploadSelfie = () => {
  const navigate = useNavigate();
  const [step, setStep] = useState("policy");

  const handleClose = () => {
    navigate(-1);
  };

  const handlePolicyAgree = () => {
    setStep("upload");
  };

  return (
    <div className="container py-5" style={{ minHeight: "80vh" }}>
      {step === "policy" && (
        <PolicyModal
          open={true}
          onClose={handleClose}
          onAgree={handlePolicyAgree}
        />
      )}

      {step === "upload" && (
        <UploadSelectionModal open={true} onClose={handleClose} />
      )}
    </div>
  );
};

export default MovmentPlusUploadSelfie;
