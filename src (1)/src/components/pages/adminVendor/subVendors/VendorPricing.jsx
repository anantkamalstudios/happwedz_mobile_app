import React, { useRef, useState } from "react";
import { BsFiletypePdf, BsImage, BsXCircleFill } from "react-icons/bs";
import { MdOutlineUploadFile } from "react-icons/md";

const VendorPricing = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  onSubmit,
  vendorTypeName,
}) => {
  const fileInputRef = useRef(null);
  const [dragOver, setDragOver] = useState(false);

  const handleNestedInputChange = (subSection, field, value) => {
    setFormData((prev) => ({
      ...prev,
      [subSection]: {
        ...(prev[subSection] || {}),
        [field]: value,
      },
    }));
  };

  // Compress an image File using canvas → returns base64 JPEG (≤ ~80 KB)
  const compressImage = (file) =>
    new Promise((resolve) => {
      const img = new Image();
      const objectUrl = URL.createObjectURL(file);
      img.onload = () => {
        const MAX = 600; // max dimension in px
        let { width, height } = img;
        if (width > MAX || height > MAX) {
          if (width > height) { height = Math.round((height * MAX) / width); width = MAX; }
          else { width = Math.round((width * MAX) / height); height = MAX; }
        }
        const canvas = document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        canvas.getContext("2d").drawImage(img, 0, 0, width, height);
        URL.revokeObjectURL(objectUrl);
        resolve(canvas.toDataURL("image/jpeg", 0.65));
      };
      img.src = objectUrl;
    });

  // Handle file picked via input or drag-drop
  const handleFileSelect = async (file) => {
    if (!file) return;
    const isImage = file.type.startsWith("image/");
    const isPdf = file.type === "application/pdf";
    if (!isImage && !isPdf) return;

    if (isPdf) {
      // PDFs are too large for base64 in DB — store filename only for display
      setFormData((prev) => ({
        ...prev,
        pricingBrochureBase64: null,   // not stored in DB
        pricingFilePreview: null,
        pricingFileType: "pdf",
        pricingFileName: file.name,
        pricingFile: null,
      }));
      return;
    }

    // Images: compress to stay well under the DB column limit (~80 KB base64)
    const compressed = await compressImage(file);
    setFormData((prev) => ({
      ...prev,
      pricingBrochureBase64: compressed,
      pricingFilePreview: compressed,
      pricingFileType: "image",
      pricingFileName: file.name,
      pricingFile: null,
    }));
  };

  const handleRemoveFile = () => {
    setFormData((prev) => ({
      ...prev,
      pricingFile: null,
      pricingBrochureBase64: null,
      pricingFilePreview: null,
      pricingFileType: null,
      pricingFileName: null,
    }));
    if (fileInputRef.current) fileInputRef.current.value = "";
  };

  const handleSave = async () => {
    if (onSave) await onSave();
    if (onShowSuccess) onShowSuccess();
  };

  return (
    <div className="my-5">
      <div className="p-3 border rounded bg-white">
        <h4 className="mb-3 fw-bold">Pricing & Packages</h4>
        <div className="row">
          {/* Starting Price */}
          <div className="col-md-4 mb-3">
            <label className="form-label fs-16 fw-semibold">
              Starting Price
            </label>
            <input
              type="number"
              className="form-control fs-14"
              value={formData.startingPrice || ""}
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  startingPrice: e.target.value,
                }))
              }
              placeholder="Enter starting price"
            />
          </div>

          {/* Price Range */}
          <div className="col-md-6 mb-3">
            <label className="form-label fs-16 fw-semibold">Price Range</label>
            <div className="d-flex gap-2">
              <input
                type="number"
                className="form-control fs-14"
                value={formData.priceRange?.min || ""}
                onChange={(e) =>
                  handleNestedInputChange("priceRange", "min", e.target.value)
                }
                placeholder="Min"
              />
              <span className="d-flex align-items-center">-</span>
              <input
                type="number"
                className="form-control fs-14"
                value={formData.priceRange?.max || ""}
                onChange={(e) =>
                  handleNestedInputChange("priceRange", "max", e.target.value)
                }
                placeholder="Max"
              />
            </div>
          </div>

          {/* Photo Package Price */}
          {(vendorTypeName === "Photographers" ||
            vendorTypeName === "Pre Wedding Shoot") && (
            <>
              <div className="col-md-6 mb-3">
                <label className="form-label fs-16 fw-semibold">
                  Photo Package Price
                </label>
                <input
                  type="number"
                  className="form-control fs-14"
                  value={formData.photo_package_price || ""}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      photo_package_price: e.target.value,
                    }))
                  }
                  placeholder="e.g. 24000"
                />
              </div>

              {/* Photo + Video Package Price */}
              <div className="col-md-6 mb-3">
                <label className="form-label fs-16 fw-semibold">
                  Photo + Video Package Price
                </label>
                <input
                  type="number"
                  className="form-control fs-14"
                  value={formData.photo_video_package_price || ""}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      photo_video_package_price: e.target.value,
                    }))
                  }
                  placeholder="e.g. 40000"
                />
              </div>
            </>
          )}

          {/* ─── Pricing Description ─── */}
          <div className="col-12 mb-3">
            <label className="form-label fs-16 fw-semibold">
              Pricing Description
            </label>
            <textarea
              className="form-control fs-14"
              rows={4}
              value={formData.pricingDescription || ""}
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  pricingDescription: e.target.value,
                }))
              }
              placeholder="Describe your packages, inclusions, taxes, payment terms, cancellation policy, etc."
            />
          </div>

          {/* ─── PDF / Image Upload ─── */}
          <div className="col-12 mb-3">
            <label className="form-label fs-16 fw-semibold">
              Pricing Brochure{" "}
              <span className="text-muted fw-normal fs-13">
                (PDF or Image)
              </span>
            </label>

            {/* Drop Zone */}
            {!formData.pricingFileName && (
              <div
                onClick={() => fileInputRef.current?.click()}
                onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
                onDragLeave={() => setDragOver(false)}
                onDrop={(e) => {
                  e.preventDefault();
                  setDragOver(false);
                  handleFileSelect(e.dataTransfer.files[0]);
                }}
                style={{
                  border: `2px dashed ${dragOver ? "#ed1173" : "#f9a8c9"}`,
                  borderRadius: 12,
                  padding: "28px 16px",
                  textAlign: "center",
                  cursor: "pointer",
                  background: dragOver ? "#fff0f6" : "#fdfafa",
                  transition: "all 0.2s ease",
                }}
              >
                <MdOutlineUploadFile
                  size={36}
                  color="#ed1173"
                  style={{ marginBottom: 8 }}
                />
                <p className="mb-1 fw-semibold fs-14" style={{ color: "#333" }}>
                  Drag & drop or{" "}
                  <span style={{ color: "#ed1173", textDecoration: "underline" }}>
                    click to browse
                  </span>
                </p>
                <p className="mb-0 text-muted" style={{ fontSize: 12 }}>
                  Images (JPG, PNG, WEBP) saved to server · PDFs shown here only
                </p>
              </div>
            )}

            {/* Hidden file input */}
            <input
              ref={fileInputRef}
              type="file"
              accept="application/pdf,image/*"
              className="d-none"
              onChange={(e) => handleFileSelect(e.target.files[0])}
            />

            {/* Preview after upload */}
            {formData.pricingFileName && (
              <div
                style={{
                  marginTop: 12,
                  border: "1px solid #fce7f3",
                  borderRadius: 12,
                  padding: "12px 16px",
                  background: "#fff8fb",
                  display: "flex",
                  alignItems: "center",
                  gap: 14,
                }}
              >
                {formData.pricingFileType === "image" ? (
                  <img
                    src={formData.pricingFilePreview}
                    alt="Pricing brochure preview"
                    style={{
                      width: 80,
                      height: 80,
                      objectFit: "cover",
                      borderRadius: 8,
                      flexShrink: 0,
                    }}
                  />
                ) : (
                  <div
                    style={{
                      width: 60,
                      height: 60,
                      borderRadius: 8,
                      background: "#fce7f3",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      flexShrink: 0,
                    }}
                  >
                    <BsFiletypePdf size={28} color="#ed1173" />
                  </div>
                )}

                <div style={{ flex: 1, minWidth: 0 }}>
                  <p
                    className="mb-0 fw-semibold fs-14"
                    style={{
                      color: "#333",
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                      whiteSpace: "nowrap",
                    }}
                  >
                    {formData.pricingFileName}
                  </p>
                  <span
                    className="badge mt-1"
                    style={{
                      background: "#fce7f3",
                      color: "#ed1173",
                      fontSize: 11,
                      fontWeight: 600,
                    }}
                  >
                    {formData.pricingFileType === "pdf" ? "PDF" : "Image"}
                  </span>
                  {formData.pricingFileType === "pdf" && (
                    <p className="mb-0 mt-1" style={{ fontSize: 11, color: "#999" }}>
                      PDF selected — visible this session only.
                      Upload an image to save permanently.
                    </p>
                  )}
                </div>

                <button
                  type="button"
                  onClick={handleRemoveFile}
                  style={{
                    background: "none",
                    border: "none",
                    cursor: "pointer",
                    padding: 4,
                    color: "#aaa",
                    flexShrink: 0,
                  }}
                  title="Remove file"
                >
                  <BsXCircleFill size={20} />
                </button>
              </div>
            )}

            {/* Show existing URL if loaded from server */}
            {!formData.pricingFile && formData.pricingBrochureUrl && (
              <div className="mt-2">
                <a
                  href={formData.pricingBrochureUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="fs-13"
                  style={{ color: "#ed1173" }}
                >
                  {formData.pricingBrochureUrl.endsWith(".pdf")
                    ? "📄 View current PDF"
                    : "🖼️ View current image"}
                </a>
                <span
                  className="ms-2 text-muted fs-13"
                  style={{ cursor: "pointer" }}
                  onClick={() =>
                    setFormData((prev) => ({
                      ...prev,
                      pricingBrochureUrl: null,
                    }))
                  }
                >
                  (Replace)
                </span>
              </div>
            )}
          </div>
        </div>

        <div className="row g-3 mt-3 justify-content-start">
          <div className="col-12 col-sm-6 col-md-4">
            <button
              className="btn btn-primary w-100 py-2 fs-14"
              onClick={handleSave}
            >
              Save Pricing Details
            </button>
          </div>

          <div className="col-12 col-sm-6 col-md-4">
            <button
              className="btn btn-primary w-100 py-2 fs-14"
              onClick={onSubmit}
            >
              Submit All Details
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VendorPricing;
