import React, { useState, useRef, useCallback, useEffect } from "react";
import {
  FiX,
  FiUploadCloud,
  FiImage,
  FiTrash2,
  FiCheckCircle,
  FiAlertCircle,
  FiPlus,
} from "react-icons/fi";
import { IMAGE_BASE_URL } from "../../../../config/constants";

const PhotoGallery = ({ images = [], onImagesChange, onSave, onShowSuccess }) => {
  const [localImages, setLocalImages] = useState(images);
  const [showAll, setShowAll] = useState(false);
  const fileInputRef = useRef(null);
  const [isDragging, setIsDragging] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");

  const MAX_FILE_SIZE_MB = 5;
  const MAX_FILE_SIZE_BYTES = MAX_FILE_SIZE_MB * 1024 * 1024;

  // Browse button click
  const handleButtonClick = () => {
    if (fileInputRef.current) {
      fileInputRef.current.click();
    }
  };

  // Process uploaded files with size validation
  const processFiles = useCallback((files) => {
    setErrorMessage("");
    const validFiles = [];
    const oversizedFiles = [];
    const invalidTypes = [];

    files.forEach((file) => {
      if (!file.type.startsWith("image/")) {
        invalidTypes.push(file.name);
        return;
      }
      if (file.size > MAX_FILE_SIZE_BYTES) {
        oversizedFiles.push(
          `${file.name} (${(file.size / (1024 * 1024)).toFixed(1)}MB)`
        );
        return;
      }
      validFiles.push({
        file,
        preview: URL.createObjectURL(file),
      });
    });

    if (oversizedFiles.length > 0) {
      setErrorMessage(
        `Files skipped (> ${MAX_FILE_SIZE_MB}MB): ${oversizedFiles.join(", ")}`
      );
    } else if (invalidTypes.length > 0) {
      setErrorMessage(`Invalid file format: ${invalidTypes.join(", ")}`);
    }

    if (validFiles.length > 0) {
      setLocalImages((prev) => [...prev, ...validFiles]);
    }
  }, []);

  // File input change
  const handleFileChange = (e) => {
    const files = Array.from(e.target.files || []);
    processFiles(files);
    if (e.target) e.target.value = "";
  };

  // Drag & Drop handlers
  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
    const files = Array.from(e.dataTransfer.files || []);
    processFiles(files);
  };

  // Remove an image
  const handleRemoveImage = (index) => {
    setLocalImages((prev) => prev.filter((_, i) => i !== index));
  };

  // Clear all images
  const handleClearAll = () => {
    if (window.confirm("Are you sure you want to remove all photos?")) {
      setLocalImages([]);
    }
  };

  const [saving, setSaving] = useState(false);

  // Sync images from parent prop
  useEffect(() => {
    setLocalImages(images || []);
  }, [images]);

  // Notify parent on change
  useEffect(() => {
    onImagesChange && onImagesChange(localImages);
  }, [localImages, onImagesChange]);

  // Prepare media array for save
  const handleSave = async () => {
    try {
      setSaving(true);
      const media = localImages.map((img) => img.file || img.preview || img.url);
      if (onSave) {
        await onSave(media);
      }
      if (onShowSuccess) {
        onShowSuccess();
      }
    } catch (err) {
      console.error("Error saving photos:", err);
    } finally {
      setSaving(false);
    }
  };

  const getImageUrl = (image) => {
    const url = image.preview || image.url;
    if (url && url.startsWith("/uploads/")) {
      return IMAGE_BASE_URL + url;
    }
    return url;
  };

  return (
    <div className="py-3">
      {/* Upload Box Container */}
      <div
        className="card border-0 shadow-sm rounded-4 overflow-hidden mb-4"
        style={{ backgroundColor: "#ffffff", border: "1px solid #edf2f7" }}
      >
        <div className="card-body p-4 p-md-5">
          {/* Section Header */}
          <div className="text-center mb-4">
            <h4
              className="fw-bold mb-2"
              style={{ color: "#0f172a", fontSize: "1.45rem", letterSpacing: "-0.02em" }}
            >
              Upload Photos to Showcase Your Work
            </h4>
            <p className="text-muted mb-0 fs-14">
              Add high-resolution photos of your venues, events, and portfolio to attract couples.
            </p>
          </div>

          {/* Drag & Drop Upload Zone */}
          <div
            className={`rounded-4 p-4 p-md-5 text-center d-flex flex-column align-items-center justify-content-center ${
              isDragging ? "bg-light border-primary" : ""
            }`}
            style={{
              border: isDragging
                ? "2px dashed #2563eb"
                : "2px dashed #cbd5e1",
              backgroundColor: isDragging ? "#eff6ff" : "#fafbfc",
              cursor: "pointer",
              transition: "all 0.25s ease",
            }}
            onClick={handleButtonClick}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
          >
            {/* Upload Icon */}
            <div
              className="mb-3 d-flex align-items-center justify-content-center rounded-circle"
              style={{
                width: "64px",
                height: "64px",
                backgroundColor: "rgba(237, 17, 115, 0.08)",
                color: "#ed1173",
                fontSize: "1.75rem",
              }}
            >
              <FiUploadCloud />
            </div>

            <h6 className="fw-bold text-dark mb-1 fs-16">
              Drag & drop photos here, or click to browse
            </h6>
            <p className="text-muted small mb-3">
              Select one or multiple images at once
            </p>

            <button
              type="button"
              className="btn btn-primary px-4 py-2 rounded-pill fw-semibold fs-14 d-inline-flex align-items-center gap-2 shadow-sm"
              style={{
                backgroundColor: "#ed1173",
                borderColor: "#ed1173",
                padding: "8px 24px",
              }}
              onClick={(e) => {
                e.stopPropagation();
                handleButtonClick();
              }}
            >
              <FiPlus size={16} />
              <span>Browse Files</span>
            </button>

            {/* File Format & Size Limits */}
            <div className="mt-3">
              <span
                className="badge bg-white text-secondary border px-3 py-2 rounded-pill"
                style={{ fontSize: "0.775rem", fontWeight: "500" }}
              >
                Supported: JPG, PNG, WEBP • Max 5 MB per photo
              </span>
            </div>

            {/* Error Message */}
            {errorMessage && (
              <div
                className="alert alert-danger d-inline-flex align-items-center gap-2 mt-3 mb-0 py-2 px-3 fs-13 rounded-3"
                role="alert"
                onClick={(e) => e.stopPropagation()}
              >
                <FiAlertCircle size={16} className="flex-shrink-0" />
                <span>{errorMessage}</span>
              </div>
            )}
          </div>

          <input
            type="file"
            ref={fileInputRef}
            multiple
            accept="image/png, image/jpeg, image/jpg, image/webp"
            onChange={handleFileChange}
            className="d-none"
          />

          {/* Gallery Preview Section */}
          {localImages.length > 0 && (
            <div className="mt-5 pt-3 border-top">
              <div className="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
                <div>
                  <h5 className="fw-bold text-dark mb-1 fs-18">
                    Preview Gallery ({localImages.length}{" "}
                    {localImages.length === 1 ? "photo" : "photos"})
                  </h5>
                  <p className="text-muted small mb-0">
                    The first image will appear as your primary storefront cover.
                  </p>
                </div>

                {localImages.length > 1 && (
                  <button
                    type="button"
                    className="btn btn-outline-danger btn-sm rounded-pill px-3 py-1 fs-13 d-inline-flex align-items-center justify-content-center gap-1 shadow-none"
                    style={{
                      width: "auto",
                      maxWidth: "fit-content",
                      whiteSpace: "nowrap",
                      flexShrink: 0,
                      alignSelf: "flex-start",
                    }}
                    onClick={handleClearAll}
                  >
                    <FiTrash2 size={13} />
                    <span>Clear All</span>
                  </button>
                )}
              </div>

              {/* Grid of photos */}
              <div className="row g-3">
                {(showAll ? localImages : localImages.slice(0, 8)).map(
                  (image, index) => (
                    <div key={index} className="col-lg-3 col-md-4 col-6">
                      <div
                        className="card border-0 shadow-sm h-100 overflow-hidden position-relative rounded-3"
                        style={{
                          backgroundColor: "#f8fafc",
                          border: "1px solid #e2e8f0",
                          transition: "transform 0.2s ease, box-shadow 0.2s ease",
                        }}
                      >
                        {/* Cover Badge for index 0 */}
                        {index === 0 && (
                          <div
                            className="position-absolute top-0 start-0 m-2 px-2 py-1 bg-dark text-white rounded-pill small fw-semibold"
                            style={{
                              fontSize: "0.7rem",
                              zIndex: 2,
                              backgroundColor: "rgba(15, 23, 42, 0.85)",
                              backdropFilter: "blur(4px)",
                            }}
                          >
                            ⭐ Cover Photo
                          </div>
                        )}

                        {/* Image */}
                        <div
                          style={{
                            height: "170px",
                            width: "100%",
                            position: "relative",
                            overflow: "hidden",
                          }}
                        >
                          <img
                            src={getImageUrl(image)}
                            alt={`Preview ${index + 1}`}
                            className="w-100 h-100 object-fit-cover"
                            onError={(e) => {
                              e.target.src = "/placeholder-image.jpg";
                            }}
                          />

                          {/* Delete Button */}
                          <button
                            type="button"
                            className="btn btn-danger btn-sm position-absolute top-0 end-0 m-2 rounded-circle d-flex align-items-center justify-content-center shadow"
                            style={{
                              width: "28px",
                              height: "28px",
                              padding: 0,
                              zIndex: 3,
                              backgroundColor: "#ef4444",
                              border: "none",
                            }}
                            onClick={(e) => {
                              e.stopPropagation();
                              handleRemoveImage(index);
                            }}
                            title="Remove photo"
                          >
                            <FiX size={15} />
                          </button>
                        </div>
                      </div>
                    </div>
                  )
                )}
              </div>

              {/* Show More / Less button */}
              {localImages.length > 8 && (
                <div className="mt-4 text-center">
                  <button
                    type="button"
                    className="btn btn-outline-secondary px-4 py-2 rounded-pill fs-14 fw-semibold"
                    onClick={() => setShowAll((prev) => !prev)}
                  >
                    {showAll
                      ? "Show Less Photos"
                      : `Show All (${localImages.length} Photos)`}
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Save Button */}
      <div className="d-flex justify-content-end">
        <button
          className="btn btn-primary px-4 py-2 rounded-pill fw-semibold fs-15 d-inline-flex align-items-center gap-2 shadow-sm"
          style={{
            backgroundColor: "#ed1173",
            borderColor: "#ed1173",
            opacity: saving ? 0.7 : 1,
            cursor: saving ? "not-allowed" : "pointer",
          }}
          onClick={handleSave}
          disabled={saving}
        >
          {saving ? (
            <>
              <span className="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
              <span>Saving Photos...</span>
            </>
          ) : (
            <>
              <FiCheckCircle size={17} />
              <span>Save Gallery Photos</span>
            </>
          )}
        </button>
      </div>
    </div>
  );
};

export default PhotoGallery;
