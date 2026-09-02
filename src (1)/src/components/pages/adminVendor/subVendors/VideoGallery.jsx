import React, { useState, useEffect } from "react";
import {
  FiVideo,
  FiPlus,
  FiTrash2,
  FiX,
  FiExternalLink,
  FiCheckCircle,
  FiAlertCircle,
  FiFilm,
} from "react-icons/fi";

// Helper to extract YouTube Video ID (Standard, Shorts, Embed, youtu.be)
const getYouTubeVideoId = (url) => {
  if (!url || typeof url !== "string") return null;
  const match = url.match(
    /(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/))([\w-]{11})/
  );
  return match ? match[1] : null;
};

// Helper to extract Vimeo Video ID
const getVimeoVideoId = (url) => {
  if (!url || typeof url !== "string") return null;
  const match = url.match(
    /(?:vimeo\.com\/)(?:channels\/[A-z]+\/|groups\/[A-z]+\/videos\/|album\/(?:\d+)\/video\/|video\/|)(\d+)/
  );
  return match ? match[1] : null;
};

const VideoGallery = ({
  videos: initialVideos = [],
  onVideosChange,
  onSave,
  onShowSuccess,
}) => {
  const [videos, setVideos] = useState(initialVideos);
  const [newVideoUrl, setNewVideoUrl] = useState("");
  const [errorMessage, setErrorMessage] = useState("");
  const [showAll, setShowAll] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (Array.isArray(initialVideos)) {
      const normalized = initialVideos
        .map((v) => {
          if (v && typeof v === "object" && (v.url || v.preview)) {
            return {
              id: v.id || Math.random().toString(36).substr(2, 9),
              url: v.url || v.preview,
              preview: v.preview || v.url,
            };
          }
          if (typeof v === "string" && v.trim()) {
            return {
              id: Math.random().toString(36).substr(2, 9),
              url: v.trim(),
              preview: v.trim(),
            };
          }
          return null;
        })
        .filter(Boolean);
      setVideos(normalized);
    }
  }, [initialVideos]);

  // Sync to parent on change
  const updateVideos = (newVideosList) => {
    setVideos(newVideosList);
    if (onVideosChange) {
      onVideosChange(newVideosList);
    }
  };

  const handleAddUrl = () => {
    setErrorMessage("");
    const trimmed = newVideoUrl.trim();
    if (!trimmed) return;

    // Basic URL check
    if (!trimmed.startsWith("http://") && !trimmed.startsWith("https://")) {
      setErrorMessage("Please enter a valid URL starting with https:// or http://");
      return;
    }

    // Duplicate check
    const isDuplicate = videos.some((v) => v.url.toLowerCase() === trimmed.toLowerCase());
    if (isDuplicate) {
      setErrorMessage("This video URL is already in your gallery.");
      return;
    }

    const newVideo = {
      id: Math.random().toString(36).substr(2, 9),
      url: trimmed,
      preview: trimmed,
    };

    updateVideos([...videos, newVideo]);
    setNewVideoUrl("");
  };

  const handleRemoveVideo = (id) => {
    const updated = videos.filter((v) => v.id !== id);
    updateVideos(updated);
  };

  const handleClearAll = () => {
    updateVideos([]);
  };

  const handleKeyPress = (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      handleAddUrl();
    }
  };

  const handleSave = async () => {
    try {
      setSaving(true);
      const videoUrls = videos.map((v) => v.url);
      if (onSave) {
        await onSave(videoUrls);
      }
      if (onShowSuccess) {
        onShowSuccess();
      }
    } catch (err) {
      console.error("Error saving video gallery:", err);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="py-3">
      {/* Main Container Card */}
      <div
        className="card border-0 shadow-sm rounded-4 overflow-hidden mb-4"
        style={{ backgroundColor: "#ffffff", border: "1px solid #edf2f7" }}
      >
        <div className="card-body p-4 p-md-5">
          {/* Section Header */}
          <div className="text-center mb-4">
            <h4
              className="fw-bold mb-2"
              style={{
                color: "#0f172a",
                fontSize: "1.45rem",
                letterSpacing: "-0.02em",
              }}
            >
              Video Gallery
            </h4>
            <p className="text-muted mb-0 fs-14">
              Add and manage video links (YouTube, Vimeo, or direct MP4/WebM) to showcase your work.
            </p>
          </div>

          {/* Input Section */}
          <div
            className="rounded-4 p-3 p-md-4 mb-4"
            style={{
              backgroundColor: "#fafbfc",
              border: "1px solid #e2e8f0",
            }}
          >
            <label className="form-label fw-semibold text-dark fs-14 mb-2 d-flex align-items-center gap-2">
              <FiFilm style={{ color: "#ed1173" }} size={16} />
              <span>Add Video URL</span>
            </label>

            <div className="input-group">
              <span
                className="input-group-text bg-white border-end-0"
                style={{
                  borderRadius: "12px 0 0 12px",
                  borderColor: "#e2e8f0",
                  color: "#94a3b8",
                }}
              >
                <FiVideo size={18} />
              </span>

              <input
                type="url"
                placeholder="Enter video URL (MP4, WebM, YouTube, Vimeo)"
                value={newVideoUrl}
                onChange={(e) => {
                  setNewVideoUrl(e.target.value);
                  if (errorMessage) setErrorMessage("");
                }}
                onKeyDown={handleKeyPress}
                className="form-control form-control-lg fs-14 border-start-0 border-end-0"
                style={{
                  borderColor: "#e2e8f0",
                  padding: "12px 14px",
                  boxShadow: "none",
                }}
              />

              {newVideoUrl && (
                <button
                  type="button"
                  className="btn bg-white border border-start-0 border-end-0 text-muted"
                  style={{ borderColor: "#e2e8f0" }}
                  onClick={() => setNewVideoUrl("")}
                >
                  <FiX size={16} />
                </button>
              )}

              <button
                type="button"
                onClick={handleAddUrl}
                disabled={!newVideoUrl.trim()}
                className="btn btn-primary px-4 fw-semibold fs-14 d-inline-flex align-items-center gap-2"
                style={{
                  borderRadius: "0 12px 12px 0",
                  backgroundColor: "#ed1173",
                  borderColor: "#ed1173",
                  opacity: !newVideoUrl.trim() ? 0.6 : 1,
                  transition: "all 0.2s ease",
                }}
              >
                <FiPlus size={18} />
                <span>Add Video</span>
              </button>
            </div>

            {/* Error Message */}
            {errorMessage && (
              <div
                className="mt-3 p-2 px-3 rounded-3 d-inline-flex align-items-center gap-2 text-danger fs-13"
                style={{ backgroundColor: "#fef2f2", border: "1px solid #fee2e2" }}
              >
                <FiAlertCircle size={15} className="flex-shrink-0" />
                <span>{errorMessage}</span>
              </div>
            )}
          </div>

          {/* Video Preview Gallery */}
          {videos.length > 0 ? (
            <div className="mt-4 pt-2">
              <div className="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
                <div>
                  <h5 className="fw-bold text-dark mb-1 fs-18">
                    Preview Videos ({videos.length}{" "}
                    {videos.length === 1 ? "video" : "videos"})
                  </h5>
                  <p className="text-muted small mb-0">
                    These videos will be available to watch directly on your public storefront.
                  </p>
                </div>

                {videos.length > 1 && (
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

              {/* Videos Grid */}
              <div className="row g-3 g-md-4">
                {(showAll ? videos : videos.slice(0, 6)).map((video, index) => {
                  const youtubeId = getYouTubeVideoId(video.url);
                  const vimeoId = getVimeoVideoId(video.url);

                  return (
                    <div key={video.id || index} className="col-12 col-md-6 col-lg-4">
                      <div
                        className="card border-0 shadow-sm h-100 overflow-hidden position-relative rounded-3"
                        style={{
                          backgroundColor: "#f8fafc",
                          border: "1px solid #e2e8f0",
                          transition: "transform 0.2s ease, box-shadow 0.2s ease",
                        }}
                      >
                        {/* Video Player / Embed */}
                        <div
                          style={{
                            height: "200px",
                            width: "100%",
                            position: "relative",
                            backgroundColor: "#000000",
                            overflow: "hidden",
                          }}
                        >
                          {youtubeId ? (
                            <iframe
                              src={`https://www.youtube-nocookie.com/embed/${youtubeId}`}
                              title={`YouTube video player ${index + 1}`}
                              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                              allowFullScreen
                              style={{
                                width: "100%",
                                height: "100%",
                                border: "none",
                              }}
                            />
                          ) : vimeoId ? (
                            <iframe
                              src={`https://player.vimeo.com/video/${vimeoId}`}
                              title={`Vimeo video player ${index + 1}`}
                              allow="autoplay; fullscreen; picture-in-picture"
                              allowFullScreen
                              style={{
                                width: "100%",
                                height: "100%",
                                border: "none",
                              }}
                            />
                          ) : (
                            <video
                              src={video.url}
                              controls
                              preload="metadata"
                              style={{
                                width: "100%",
                                height: "100%",
                                objectFit: "cover",
                              }}
                            />
                          )}

                          {/* Delete Button */}
                          <button
                            type="button"
                            className="btn btn-danger btn-sm position-absolute top-0 end-0 m-2 rounded-circle d-flex align-items-center justify-content-center shadow"
                            style={{
                              width: "28px",
                              height: "28px",
                              padding: 0,
                              zIndex: 5,
                              backgroundColor: "#ef4444",
                              border: "none",
                            }}
                            onClick={() => handleRemoveVideo(video.id)}
                            title="Remove video"
                          >
                            <FiX size={15} />
                          </button>
                        </div>

                        {/* Card Info Footer */}
                        <div className="p-3 bg-white border-top">
                          <div className="d-flex align-items-center justify-content-between gap-2 mb-1">
                            <span
                              className="badge rounded-pill fw-semibold"
                              style={{
                                fontSize: "11px",
                                backgroundColor: youtubeId
                                  ? "#fee2e2"
                                  : vimeoId
                                  ? "#e0f2fe"
                                  : "#f1f5f9",
                                color: youtubeId
                                  ? "#dc2626"
                                  : vimeoId
                                  ? "#0284c7"
                                  : "#475569",
                              }}
                            >
                              {youtubeId
                                ? "YouTube"
                                : vimeoId
                                ? "Vimeo"
                                : "Direct Video"}
                            </span>

                            <a
                              href={video.url}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="text-muted small d-inline-flex align-items-center gap-1 text-decoration-none"
                              style={{ fontSize: "11px" }}
                            >
                              <span>Open</span>
                              <FiExternalLink size={11} />
                            </a>
                          </div>

                          <p
                            className="text-muted small mb-0 text-truncate"
                            title={video.url}
                            style={{ fontSize: "12px" }}
                          >
                            {video.url}
                          </p>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* Show More / Show Less */}
              {videos.length > 6 && (
                <div className="mt-4 text-center">
                  <button
                    type="button"
                    className="btn btn-outline-secondary px-4 py-2 rounded-pill fs-14 fw-semibold"
                    onClick={() => setShowAll((prev) => !prev)}
                  >
                    {showAll
                      ? "Show Less Videos"
                      : `Show All (${videos.length} Videos)`}
                  </button>
                </div>
              )}
            </div>
          ) : (
            /* Empty State */
            <div
              className="rounded-4 p-5 text-center my-3"
              style={{
                backgroundColor: "#fafbfc",
                border: "2px dashed #cbd5e1",
              }}
            >
              <div
                className="d-inline-flex align-items-center justify-content-center mb-3 rounded-circle"
                style={{
                  width: "64px",
                  height: "64px",
                  backgroundColor: "#fff1f6",
                  color: "#ed1173",
                }}
              >
                <FiFilm size={28} />
              </div>
              <h5 className="fw-bold text-dark mb-1 fs-16">No Videos Added Yet</h5>
              <p className="text-muted small mb-0" style={{ maxWidth: "420px", margin: "0 auto" }}>
                Paste your first YouTube, Vimeo, or video link above to enrich your vendor storefront portfolio.
              </p>
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
              <span>Saving Videos...</span>
            </>
          ) : (
            <>
              <FiCheckCircle size={17} />
              <span>Save Video Gallery</span>
            </>
          )}
        </button>
      </div>
    </div>
  );
};

export default VideoGallery;
