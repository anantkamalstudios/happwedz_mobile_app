import React, { useState, useRef, useCallback } from "react";
import { Modal, Button, Nav, Tab, Form } from "react-bootstrap";
import { FaCamera, FaUpload, FaTimes, FaRedo } from "react-icons/fa";
import "./upload-selection-modal.css";

const UploadSelectionModal = ({ show, onHide, collectionName, onUpload }) => {
  const [activeTab, setActiveTab] = useState("file");
  const [selectedFile, setSelectedFile] = useState(null);
  const [previewUrl, setPreviewUrl] = useState(null);
  const [cameraStream, setCameraStream] = useState(null);
  const [capturedImage, setCapturedImage] = useState(null);
  const videoRef = useRef(null);
  const canvasRef = useRef(null);

  // Reset state when modal opens/closes
  React.useEffect(() => {
    if (!show) {
      stopCamera();
      setSelectedFile(null);
      setPreviewUrl(null);
      setCapturedImage(null);
      setActiveTab("file");
    }
  }, [show]);

  // Handle File Selection
  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setSelectedFile(file);
      setPreviewUrl(URL.createObjectURL(file));
    }
  };

  // Start Camera
  const startCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "user" },
      });
      setCameraStream(stream);
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
      }
    } catch (err) {
      console.error("Error accessing camera:", err);
      alert("Could not access camera. Please allow camera permissions.");
    }
  };

  // Stop Camera
  const stopCamera = () => {
    if (cameraStream) {
      cameraStream.getTracks().forEach((track) => track.stop());
      setCameraStream(null);
    }
  };

  // Capture Selfie
  const captureSelfie = () => {
    if (videoRef.current && canvasRef.current) {
      const video = videoRef.current;
      const canvas = canvasRef.current;
      const context = canvas.getContext("2d");

      // Set canvas dimensions to match video
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;

      // Draw video frame to canvas
      // Mirror the image
      context.translate(canvas.width, 0);
      context.scale(-1, 1);
      context.drawImage(video, 0, 0, canvas.width, canvas.height);

      // Convert to data URL
      const dataUrl = canvas.toDataURL("image/jpeg");
      setCapturedImage(dataUrl);
      stopCamera();
    }
  };

  // Retake Selfie
  const retakeSelfie = () => {
    setCapturedImage(null);
    startCamera();
  };

  // Handle Upload
  const handleUploadClick = () => {
    if (activeTab === "file" && selectedFile) {
      onUpload(selectedFile, collectionName);
    } else if (activeTab === "selfie" && capturedImage) {
      // Convert data URL to Blob/File
      fetch(capturedImage)
        .then((res) => res.blob())
        .then((blob) => {
          const file = new File([blob], `selfie_${Date.now()}.jpg`, {
            type: "image/jpeg",
          });
          onUpload(file, collectionName);
        });
    }
  };

  return (
    <Modal show={show} onHide={onHide} centered size="lg" className="upload-modal">
      <Modal.Header closeButton>
        <Modal.Title>Upload to {collectionName}</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        <Tab.Container activeKey={activeTab} onSelect={(k) => setActiveTab(k)}>
          <Nav variant="tabs" className="mb-3 justify-content-center">
            <Nav.Item>
              <Nav.Link eventKey="file" onClick={stopCamera}>
                <FaUpload className="me-2" /> Upload File
              </Nav.Link>
            </Nav.Item>
            <Nav.Item>
              <Nav.Link eventKey="selfie" onClick={startCamera}>
                <FaCamera className="me-2" /> Selfie Mode
              </Nav.Link>
            </Nav.Item>
          </Nav>

          <Tab.Content>
            {/* File Upload Tab */}
            <Tab.Pane eventKey="file">
              <div className="text-center p-4 border rounded bg-light">
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleFileChange}
                  className="d-none"
                  id="file-upload-input"
                />
                {!previewUrl ? (
                  <label htmlFor="file-upload-input" className="btn btn-outline-primary">
                    Select Image
                  </label>
                ) : (
                  <div className="preview-container">
                    <img src={previewUrl} alt="Preview" className="img-fluid rounded mb-3" style={{ maxHeight: "300px" }} />
                    <div>
                      <label htmlFor="file-upload-input" className="btn btn-sm btn-secondary me-2">
                        Change
                      </label>
                    </div>
                  </div>
                )}
              </div>
            </Tab.Pane>

            {/* Selfie Tab */}
            <Tab.Pane eventKey="selfie">
              <div className="text-center bg-dark rounded overflow-hidden position-relative" style={{ minHeight: "300px" }}>
                {!capturedImage ? (
                  <>
                    <video
                      ref={videoRef}
                      autoPlay
                      playsInline
                      muted
                      style={{
                        width: "100%",
                        height: "auto",
                        maxHeight: "400px",
                        transform: "scaleX(-1)", // Mirror preview
                      }}
                    />
                    <div className="position-absolute bottom-0 w-100 p-3 bg-dark bg-opacity-50">
                      <Button variant="light" onClick={captureSelfie} className="rounded-circle p-3">
                        <FaCamera size={24} />
                      </Button>
                    </div>
                  </>
                ) : (
                  <>
                    <img src={capturedImage} alt="Captured Selfie" className="img-fluid" style={{ maxHeight: "400px" }} />
                    <div className="mt-3 pb-3">
                      <Button variant="secondary" onClick={retakeSelfie} className="me-2">
                        <FaRedo className="me-2" /> Retake
                      </Button>
                    </div>
                  </>
                )}
                <canvas ref={canvasRef} style={{ display: "none" }} />
              </div>
            </Tab.Pane>
          </Tab.Content>
        </Tab.Container>
      </Modal.Body>
      <Modal.Footer>
        <Button variant="secondary" onClick={onHide}>
          Cancel
        </Button>
        <Button
          variant="primary"
          onClick={handleUploadClick}
          disabled={
            (activeTab === "file" && !selectedFile) ||
            (activeTab === "selfie" && !capturedImage)
          }
        >
          Upload
        </Button>
      </Modal.Footer>
    </Modal>
  );
};

export default UploadSelectionModal;
