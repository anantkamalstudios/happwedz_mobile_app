import React, { useState } from "react";

const VendorMedia = ({ formData, setFormData }) => {
  const media = formData.media || {
    coverImage: "",
    gallery: [],
    video: { url: "", thumbnails: [] },
    brochurePdf: "",
  };

  const [preview, setPreview] = useState({
    coverImage: "",
    gallery: [],
    videoThumbnails: [],
    brochurePdf: "",
  });

  const handleFileChange = (field, file, multiple = false) => {
    if (!file) return;

    const fileName = file.name;
    const fileUrl = URL.createObjectURL(file);

    setFormData((prev) => ({
      ...prev,
      media: {
        ...prev.media,
        [field]: multiple ? [...(prev.media[field] || []), fileName] : fileName,
      },
    }));

    setPreview((prev) => ({
      ...prev,
      [field]: multiple ? [...(prev[field] || []), fileUrl] : fileUrl,
    }));
  };

  const handleVideoThumbnailAdd = (files) => {
    const fileArr = Array.from(files);
    const fileNames = fileArr.map((f) => f.name);
    const fileUrls = fileArr.map((f) => URL.createObjectURL(f));

    setFormData((prev) => ({
      ...prev,
      media: {
        ...prev.media,
        video: {
          ...prev.media.video,
          thumbnails: [...(prev.media.video?.thumbnails || []), ...fileNames],
        },
      },
    }));

    setPreview((prev) => ({
      ...prev,
      videoThumbnails: [...(prev.videoThumbnails || []), ...fileUrls],
    }));
  };

  return (
    <div className="my-5">
      <div className="p-3 border rounded bg-white">
        <h6 className="mb-3 fw-bold">Media & Gallery</h6>
        <div className="row">
          {/* Cover Image */}
          <div className="col-12 mb-3">
            <label className="form-label fw-semibold">Cover Image</label>
            <input
              type="file"
              className="form-control"
              accept="image/*"
              onChange={(e) =>
                handleFileChange("coverImage", e.target.files[0])
              }
            />
            {preview.coverImage && (
              <img
                src={preview.coverImage}
                alt="cover"
                className="mt-2 rounded"
                style={{ width: "180px", height: "120px", objectFit: "cover" }}
              />
            )}
          </div>

          {/* Video Upload */}
          <div className="col-12 mb-3">
            <label className="form-label fw-semibold">Video File</label>
            <input
              type="file"
              className="form-control"
              accept="video/*"
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  media: {
                    ...prev.media,
                    video: { ...prev.media.video, url: e.target.files[0].name },
                  },
                }))
              }
            />
          </div>

          {/* Video Thumbnails */}
          <div className="col-12 mb-3">
            <label className="form-label fw-semibold">
              Video Thumbnails (Multiple)
            </label>
            <input
              type="file"
              className="form-control"
              accept="image/*"
              multiple
              onChange={(e) => handleVideoThumbnailAdd(e.target.files)}
            />
            <div className="d-flex gap-2 flex-wrap mt-2">
              {preview.videoThumbnails.map((thumb, idx) => (
                <img
                  key={idx}
                  src={thumb}
                  alt={`thumb-${idx}`}
                  style={{
                    width: "100px",
                    height: "70px",
                    objectFit: "cover",
                    borderRadius: "6px",
                  }}
                />
              ))}
            </div>
          </div>

          {/* Gallery Images */}
          <div className="col-12 mb-3">
            <label className="form-label fw-semibold">Gallery Images</label>
            <input
              type="file"
              className="form-control"
              accept="image/*"
              multiple
              onChange={(e) =>
                Array.from(e.target.files).forEach((file) =>
                  handleFileChange("gallery", file, true)
                )
              }
            />
            <div className="d-flex gap-2 flex-wrap mt-2">
              {preview.gallery.map((img, idx) => (
                <img
                  key={idx}
                  src={img}
                  alt={`gallery-${idx}`}
                  style={{
                    width: "100px",
                    height: "70px",
                    objectFit: "cover",
                    borderRadius: "6px",
                  }}
                />
              ))}
            </div>
          </div>

          {/* Brochure PDF */}
          <div className="col-12 mb-3">
            <label className="form-label fw-semibold">Brochure PDF</label>
            <input
              type="file"
              className="form-control"
              accept="application/pdf"
              onChange={(e) =>
                handleFileChange("brochurePdf", e.target.files[0])
              }
            />
            {media.brochurePdf && (
              <p className="mt-2 small text-success">
                Uploaded: {media.brochurePdf}
              </p>
            )}
          </div>
        </div>

        <button className="btn btn-primary mt-2">Save Media Details</button>
      </div>
    </div>
  );
};

export default VendorMedia;
