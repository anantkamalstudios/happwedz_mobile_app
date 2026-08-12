import React, { useState, useRef, useCallback, useEffect } from "react";
import { FiX } from "react-icons/fi";
import { IMAGE_BASE_URL } from "../../../../config/constants";
import SuccessModal from "../../../ui/SuccessModal";

const PhotoGallery = ({ images = [], onImagesChange, onSave }) => {
  const [localImages, setLocalImages] = useState(images);
  const [showAll, setShowAll] = useState(false);
  const fileInputRef = useRef(null);
  const [isDragging, setIsDragging] = useState(false);
  const [showModal, setShowModal] = useState(false);

  // Browse button click
  const handleButtonClick = () => {
    fileInputRef.current.click();
  };

  // File input change
  const handleFileChange = (e) => {
    const files = Array.from(e.target.files);
    processFiles(files);
  };

  // Drag & Drop handlers
  const handleDragOver = (e) => {
    e.preventDefault();
    setIsDragging(true);
  };
  const handleDragLeave = () => setIsDragging(false);
  const handleDrop = (e) => {
    e.preventDefault();
    setIsDragging(false);
    const files = Array.from(e.dataTransfer.files);
    processFiles(files);
  };

  // Process uploaded files
  const processFiles = useCallback((files) => {
    setLocalImages((prev) => {
      const newImages = files
        .filter((file) => file.type.startsWith("image/"))
        .map((file) => ({
          file,
          preview: URL.createObjectURL(file),
        }));

      return [...prev, ...newImages];
    });
  }, []);

  // Remove an image
  const handleRemoveImage = (index) => {
    setLocalImages((prev) => prev.filter((_, i) => i !== index));
  };

  // Sync images from parent prop
  useEffect(() => {
    setLocalImages(images || []);
  }, [images]);

  // Notify parent on change
  useEffect(() => {
    onImagesChange && onImagesChange(localImages);
  }, [localImages, onImagesChange]);

  // Prepare media array for save
  const handleSave = () => {
    const media = localImages.map((img) => img.file || img.preview || img.url);
    onSave(media);
    setShowModal(true);
  };

  const getImageUrl = (image) => {
    const url = image.preview || image.url;
    if (url && url.startsWith("/uploads/")) {
      return IMAGE_BASE_URL + url;
    }
    return url;
  };

  return (
    <div className="container my-5">
      {/* Upload Card */}
      <div className="card shadow-lg border-0 rounded-3 overflow-hidden">
        <div className="card-body p-4 p-md-5">
          <h4 className="mb-4 text-center text-gradient">
            <span className="primary-text">
              Upload your best photos to showcase your work
            </span>
          </h4>

          {/* Drag & Drop Area */}
          <div
            className={`border-2 border-dashed rounded-4 p-5 text-center ${
              isDragging ? "border-primary bg-blue-10" : "border-gray-300"
            }`}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
          >
            {/* <p className="mb-2 fs-16">Drag & Drop images here</p>
            <p className="text-muted mb-3 fs-14">or</p> */}

            <button
              className="btn btn-primary px-4 rounded-pill fw-medium fs-14"
              onClick={handleButtonClick}
            >
              Browse Files
            </button>
            <p className="small text-muted mt-2 mb-0 fw-bold fs-14">
              JPG, PNG up to 1MB
            </p>

            {/* {localImages.length >= 8 && (
              <div className="mt-3 text-danger">
                Maximum of 8 images reached
              </div>
            )} */}
          </div>

          <input
            type="file"
            ref={fileInputRef}
            multiple
            accept="image/*"
            onChange={handleFileChange}
            className="d-none"
          />

          {/* Preview Section */}
          {localImages.length > 0 && (
            <div className="mt-5">
              <h4 className="mb-4">Preview Images</h4>
              <div className="row g-4">
                {(showAll ? localImages : localImages.slice(0, 8)).map(
                  (image, index) => (
                    <div key={index} className="col-md-3 col-6">
                      <div className="card border-0 shadow-sm h-100">
                        <div className="position-relative">
                          <img
                            src={getImageUrl(image)}
                            alt="Preview"
                            className="card-img-top object-fit-cover"
                            style={{ height: "150px" }}
                          />
                          <button
                            className="btn btn-danger btn-sm position-absolute top-0 end-0 m-2 rounded-circle"
                            onClick={() => handleRemoveImage(index)}
                          >
                            <FiX size={16} />
                          </button>
                        </div>
                      </div>
                    </div>
                  ),
                )}
              </div>
              {localImages.length > 8 && (
                <div className="mt-3 text-center">
                  <button
                    type="button"
                    className="btn btn-outline-primary btn-sm fs-14"
                    onClick={() => setShowAll((prev) => !prev)}
                  >
                    {showAll ? "Show less" : "Show more"}
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      <button className="btn btn-primary mt-4 fs-14 " onClick={handleSave}>
        Save Gallery
      </button>

      <SuccessModal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        message="Your Photos have been saved successfully!"
      />
    </div>
  );
};

export default PhotoGallery;
