import React, { useState } from "react";
import { Button } from "react-bootstrap";
import { getSafe360Url } from "../../../../utils/view360Helper";

const View360 = ({
  images = [],
  setImages,
  videos = [],
  setVideos,
  url = "",
  setUrl,
  onSave,
  onShowSuccess,
}) => {
  // const [activeTab, setActiveTab] = useState("images");
  const [activeTab, setActiveTab] = useState("videos");
  const [urlError, setUrlError] = useState("");
  const safeUrl = getSafe360Url(url);

  const handleAddFiles = (event, type) => {
    const files = Array.from(event.target.files || []);
    if (!files.length) return;
    const mapped = files.map((file, idx) => ({
      id: `${type}_${Date.now()}_${idx}`,
      file,
      preview: URL.createObjectURL(file),
    }));
    if (type === "image") {
      setImages((prev) => [...prev, ...mapped]);
    } else {
      setVideos((prev) => [...prev, ...mapped]);
    }
    event.target.value = "";
  };

  const handleRemove = (id, type) => {
    if (type === "image") {
      setImages((prev) => prev.filter((i) => i.id !== id));
    } else {
      setVideos((prev) => prev.filter((v) => v.id !== id));
    }
  };

  const handleSave = () => {
    if (url.trim() && !safeUrl) {
      setActiveTab("url");
      setUrlError("Enter a full link starting with http:// or https://");
      return;
    }
    onSave?.();
  };

  const tabClass = (tab) =>
    `btn pb-2 ${
      activeTab === tab
        ? "border-0 border-bottom border-3 rounded-0 fs-16 border-primary"
        : "border-0 fs-14"
    }`;

  const renderList = (items, type) => {
    if (!items.length) {
      return (
        <div className="text-muted small py-3">
          {type === "image"
            ? "Add pano images to show in 360° view."
            : "Add videos to store under view360_video."}
        </div>
      );
    }
    return (
      <div className="row g-3">
        {items.map((item) => (
          <div key={item.id} className="col-12 col-sm-6 col-md-4">
            <div className="card h-100 shadow-sm">
              {type === "image" ? (
                <img
                  src={item.preview}
                  alt="360 preview"
                  className="card-img-top"
                  style={{ objectFit: "cover", height: 180 }}
                />
              ) : (
                <video
                  controls
                  src={item.preview}
                  className="w-100"
                  style={{ height: 180, objectFit: "cover" }}
                />
              )}
              <div className="card-body p-2 d-flex justify-content-between">
                <small className="text-truncate flex-grow-1 me-2">
                  {item.file?.name || "Existing file"}
                </small>
                <button
                  type="button"
                  className="btn btn-sm btn-outline-danger"
                  onClick={() => handleRemove(item.id, type)}
                >
                  Remove
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    );
  };

  return (
    <div className="p-3">
      <div className="d-flex gap-3 border-bottom mb-3 col-12 col-md-6">
        {/* <button
          type="button"
          className={tabClass("images")}
          onClick={() => setActiveTab("images")}
        >
          Pano Images
        </button> */}
        <button
          type="button"
          className={tabClass("videos")}
          onClick={() => setActiveTab("videos")}
        >
          Videos
        </button>
        <button
          type="button"
          className={tabClass("url")}
          onClick={() => setActiveTab("url")}
        >
          URL
        </button>
      </div>

      {activeTab === "images" && (
        <div className="mb-4">
          <p className="text-muted fs-14">
            Upload pano images to display in the 360° view (stored under
            view360_images).
          </p>
          <div className="d-flex flex-column gap-2 mb-3">
            <input
              type="file"
              accept="image/*"
              multiple
              onChange={(e) => handleAddFiles(e, "image")}
              className="form-control fs-14"
            />
          </div>
          {renderList(images, "image")}
        </div>
      )}

      {activeTab === "videos" && (
        <div className="mb-4">
          <p className="text-muted fs-14">Upload 360° videos.</p>
          <div className="d-flex flex-column gap-2 mb-3">
            <input
              type="file"
              accept="video/*"
              multiple
              onChange={(e) => handleAddFiles(e, "video")}
              className="form-control fs-14"
            />
          </div>
          {renderList(videos, "video")}
        </div>
      )}

      {activeTab === "url" && (
        <div className="mb-4">
          <p className="text-muted fs-14">
            Paste a link to your 360° tour or video, for example a Matterport
            or Kuula tour, or a YouTube 360° video.
          </p>
          <input
            type="url"
            inputMode="url"
            placeholder="https://"
            value={url}
            onChange={(e) => {
              setUrl?.(e.target.value);
              setUrlError("");
            }}
            className={`form-control fs-14 ${urlError ? "is-invalid" : ""}`}
          />
          {urlError && (
            <div className="invalid-feedback d-block">{urlError}</div>
          )}
          {safeUrl && (
            <a
              href={safeUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="d-inline-block mt-2 fs-14"
            >
              Open link to check it
            </a>
          )}
        </div>
      )}

      <div className="d-flex justify-content-start gap-2 w-100 col-12 col-md-auto">
        <Button
          variant="primary"
          className="fs-16 w-100 w-md-auto"
          style={{ maxWidth: 250 }}
          onClick={handleSave}
        >
          Save 360° Assets
        </Button>
      </div>
    </div>
  );
};

export default View360;
