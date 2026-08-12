import React, { useState, useEffect } from "react";
import { X, Plus, Video } from "lucide-react";

const getYouTubeVideoId = (url) => {
  if (!url) return null;
  const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/;
  const match = url.match(regExp);
  return match && match[2].length === 11 ? match[2] : null;
};

const VideoGallery = ({ videos: initialVideos = [], onVideosChange }) => {
  const [videos, setVideos] = useState(initialVideos);
  const [newVideoUrl, setNewVideoUrl] = useState("");

  const handleAddUrl = () => {
    if (!newVideoUrl.trim()) return;

    const newVideo = {
      id: Math.random().toString(36).substr(2, 9),
      url: newVideoUrl.trim(),
      preview: newVideoUrl.trim(),
    };

    const updatedVideos = [...videos, newVideo];
    setVideos(updatedVideos);
    if (onVideosChange) {
      // Only pass the URL to parent, which is what we want in the final payload
      onVideosChange(updatedVideos);
    }
    setNewVideoUrl("");
  };

  const handleRemoveVideo = (id) => {
    const updatedVideos = videos.filter((v) => v.id !== id);
    setVideos(updatedVideos);
    if (onVideosChange) {
      // Only pass the URL to parent, which is what we want in the final payload
      onVideosChange(updatedVideos);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === "Enter" && newVideoUrl.trim()) {
      handleAddUrl();
    }
  };

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
          if (typeof v === "string") {
            return {
              id: Math.random().toString(36).substr(2, 9),
              url: v,
              preview: v,
            };
          }
          return null;
        })
        .filter(Boolean);
      setVideos(normalized);
    }
  }, [initialVideos]);

  return (
    <div
      style={{
        minHeight: "100vh",

        padding: "40px 0",
      }}
    >
      <div className="container">
        <div className="row justify-content-center">
          <div className="col-12 col-lg-10">
            {/* Header Card */}
            <div
              className="card shadow-lg mb-4"
              style={{
                borderRadius: "20px",
                border: "none",
                background: "rgba(255, 255, 255, 0.95)",
                backdropFilter: "blur(10px)",
              }}
            >
              <div className="card-body p-4">
                <div className="text-center mb-4">
                  <div
                    className="d-inline-flex align-items-center justify-content-center mb-3"
                    style={{
                      width: "70px",
                      height: "70px",
                      borderRadius: "20px",
                      background: "#ed1173",
                    }}
                  >
                    <Video size={35} color="white" />
                  </div>
                  <h4 className="fw-bold mb-2" style={{ color: "#2d3748" }}>
                    Video Gallery
                  </h4>
                  <p className="text-muted mb-0 fs-16">
                    Add and manage your video collection
                  </p>
                </div>

                {/* Input Section */}
                <div className="row g-2">
                  <div className="col">
                    <input
                      type="text"
                      placeholder="Enter video URL (MP4, WebM, etc.)"
                      value={newVideoUrl}
                      onChange={(e) => setNewVideoUrl(e.target.value)}
                      onKeyPress={handleKeyPress}
                      className="form-control form-control-lg fs-14"
                      style={{
                        borderRadius: "12px",
                        border: "2px solid #e2e8f0",
                        padding: "12px 20px",
                        fontSize: "16px",
                      }}
                    />
                  </div>
                  <div className="col-auto">
                    <button
                      onClick={handleAddUrl}
                      disabled={!newVideoUrl.trim()}
                      className="btn btn-lg d-flex align-items-center gap-2 fs-14"
                      style={{
                        background: "#ed1173",
                        color: "white",
                        borderRadius: "12px",
                        border: "none",
                        padding: "12px 30px",
                        fontWeight: "600",
                        transition: "all 0.3s ease",
                      }}
                      onMouseOver={(e) => {
                        if (!e.currentTarget.disabled) {
                          e.currentTarget.style.transform = "translateY(-2px)";
                          e.currentTarget.style.boxShadow =
                            "0 8px 20px rgba(102, 126, 234, 0.4)";
                        }
                      }}
                      onMouseOut={(e) => {
                        e.currentTarget.style.transform = "translateY(0)";
                        e.currentTarget.style.boxShadow = "none";
                      }}
                    >
                      <Plus size={20} />
                      Add Video
                    </button>
                  </div>
                </div>

                {videos.length > 0 && (
                  <div className="mt-3">
                    <div
                      className="badge"
                      style={{
                        background: "#ed1173",
                        color: "white",
                        fontSize: "14px",
                        padding: "8px 16px",
                        borderRadius: "8px",
                      }}
                    >
                      {videos.length} {videos.length === 1 ? "Video" : "Videos"}{" "}
                      Added
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Video Grid */}
            {videos.length > 0 && (
              <div className="row g-4">
                {videos.map((video) => (
                  <div key={video.id} className="col-12 col-sm-6 col-lg-4">
                    <div
                      className="card h-100 shadow-lg"
                      style={{
                        borderRadius: "16px",
                        border: "none",
                        overflow: "hidden",
                        background: "white",
                        transition: "all 0.3s ease",
                      }}
                      onMouseOver={(e) => {
                        e.currentTarget.style.transform = "translateY(-8px)";
                        e.currentTarget.style.boxShadow =
                          "0 20px 40px rgba(0, 0, 0, 0.15)";
                      }}
                      onMouseOut={(e) => {
                        e.currentTarget.style.transform = "translateY(0)";
                        e.currentTarget.style.boxShadow =
                          "0 10px 30px rgba(0, 0, 0, 0.1)";
                      }}
                    >
                      <div style={{ position: "relative" }}>
                        {(() => {
                          const youtubeId = getYouTubeVideoId(video.url);
                          return youtubeId ? (
                            <iframe
                              src={`https://www.youtube.com/embed/${youtubeId}`}
                              title="YouTube video player"
                              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                              allowFullScreen
                              style={{
                                width: "100%",
                                height: "220px",
                                border: "none",
                                background: "#000",
                              }}
                            />
                          ) : (
                            <video
                              src={video.url}
                              controls
                              style={{
                                width: "100%",
                                height: "220px",
                                objectFit: "cover",
                                background: "#f7fafc",
                              }}
                            />
                          );
                        })()}
                        <button
                          onClick={() => handleRemoveVideo(video.id)}
                          className="btn btn-danger btn-sm d-flex align-items-center justify-content-center"
                          style={{
                            position: "absolute",
                            top: "12px",
                            right: "12px",
                            width: "36px",
                            height: "36px",
                            borderRadius: "50%",
                            padding: "0",
                            border: "none",
                            boxShadow: "0 4px 12px rgba(0, 0, 0, 0.3)",
                            transition: "all 0.2s ease",
                          }}
                          onMouseOver={(e) => {
                            e.currentTarget.style.transform = "scale(1.1)";
                          }}
                          onMouseOut={(e) => {
                            e.currentTarget.style.transform = "scale(1)";
                          }}
                        >
                          <X size={18} />
                        </button>
                      </div>
                      <div className="card-body p-3">
                        <p
                          className="mb-0"
                          style={{
                            fontSize: "13px",
                            color: "#718096",
                            wordBreak: "break-all",
                            display: "-webkit-box",
                            WebkitLineClamp: "2",
                            WebkitBoxOrient: "vertical",
                            overflow: "hidden",
                          }}
                        >
                          {video.url}
                        </p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Empty State */}
            {videos.length === 0 && (
              <div
                className="card shadow-lg"
                style={{
                  borderRadius: "20px",
                  border: "2px dashed #cbd5e0",
                  background: "rgba(255, 255, 255, 0.95)",
                }}
              >
                <div className="card-body text-center py-5">
                  <div
                    className="d-inline-flex align-items-center justify-content-center mb-3"
                    style={{
                      width: "80px",
                      height: "80px",
                      borderRadius: "50%",
                      background: "#ed1173",
                    }}
                  >
                    <Video size={40} color="#a0aec0" />
                  </div>
                  <h4
                    className="fw-bold mb-2 fs-16"
                    style={{ color: "#4a5568" }}
                  >
                    No Videos Yet
                  </h4>
                  <p className="text-muted mb-0 fs-14">
                    Start adding video URLs to build your gallery
                  </p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default VideoGallery;
