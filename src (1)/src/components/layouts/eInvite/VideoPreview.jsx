import React, { useState, useRef, useEffect } from "react";
import {
  Play,
  Pause,
  Download,
  Share2,
  Settings,
  Volume2,
  VolumeX,
  Maximize2,
  RotateCcw,
  CheckCircle,
  AlertCircle,
  Clock,
  FileVideo,
  Eye,
  EyeOff,
} from "lucide-react";

const VideoPreview = ({
  videoData,
  onExport,
  onSave,
  onBack,
  isExporting = false,
  exportProgress = 0,
}) => {
  const videoRef = useRef(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [volume, setVolume] = useState(1);
  const [isMuted, setIsMuted] = useState(false);
  const [playbackRate, setPlaybackRate] = useState(1);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [exportFormat, setExportFormat] = useState("mp4");
  const [exportQuality, setExportQuality] = useState("1080p");
  const [exportStatus, setExportStatus] = useState("ready"); // ready, exporting, completed, error

  useEffect(() => {
    if (videoRef.current) {
      const video = videoRef.current;

      const handleTimeUpdate = () => setCurrentTime(video.currentTime);
      const handleLoadedMetadata = () => setDuration(video.duration);
      const handlePlay = () => setIsPlaying(true);
      const handlePause = () => setIsPlaying(false);
      const handleEnded = () => setIsPlaying(false);

      video.addEventListener("timeupdate", handleTimeUpdate);
      video.addEventListener("loadedmetadata", handleLoadedMetadata);
      video.addEventListener("play", handlePlay);
      video.addEventListener("pause", handlePause);
      video.addEventListener("ended", handleEnded);

      return () => {
        video.removeEventListener("timeupdate", handleTimeUpdate);
        video.removeEventListener("loadedmetadata", handleLoadedMetadata);
        video.removeEventListener("play", handlePlay);
        video.removeEventListener("pause", handlePause);
        video.removeEventListener("ended", handleEnded);
      };
    }
  }, []);

  const handlePlayPause = () => {
    if (videoRef.current) {
      if (isPlaying) {
        videoRef.current.pause();
      } else {
        videoRef.current.play();
      }
    }
  };

  const handleSeek = (e) => {
    if (videoRef.current) {
      const rect = e.currentTarget.getBoundingClientRect();
      const clickX = e.clientX - rect.left;
      const newTime = (clickX / rect.width) * duration;
      videoRef.current.currentTime = newTime;
    }
  };

  const handleVolumeChange = (e) => {
    const newVolume = parseFloat(e.target.value);
    setVolume(newVolume);
    if (videoRef.current) {
      videoRef.current.volume = newVolume;
    }
  };

  const handleMute = () => {
    setIsMuted(!isMuted);
    if (videoRef.current) {
      videoRef.current.muted = !isMuted;
    }
  };

  const handlePlaybackRateChange = (rate) => {
    setPlaybackRate(rate);
    if (videoRef.current) {
      videoRef.current.playbackRate = rate;
    }
  };

  const handleFullscreen = () => {
    if (videoRef.current) {
      if (!document.fullscreenElement) {
        videoRef.current.requestFullscreen();
        setIsFullscreen(true);
      } else {
        document.exitFullscreen();
        setIsFullscreen(false);
      }
    }
  };

  const handleExport = async () => {
    setExportStatus("exporting");
    try {
      await onExport({
        format: exportFormat,
        quality: exportQuality,
        name: videoData.name || "wedding-video",
      });
      setExportStatus("completed");
    } catch (error) {
      setExportStatus("error");
      console.error("Export failed:", error);
    }
  };

  const formatTime = (time) => {
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes}:${seconds.toString().padStart(2, "0")}`;
  };

  const getExportStatusIcon = () => {
    switch (exportStatus) {
      case "exporting":
        return (
          <div className="spinner-border spinner-border-sm text-primary" />
        );
      case "completed":
        return <CheckCircle className="text-success" size={20} />;
      case "error":
        return <AlertCircle className="text-danger" size={20} />;
      default:
        return <FileVideo size={20} />;
    }
  };

  const getExportStatusText = () => {
    switch (exportStatus) {
      case "exporting":
        return `Exporting... ${exportProgress}%`;
      case "completed":
        return "Export completed!";
      case "error":
        return "Export failed. Please try again.";
      default:
        return "Ready to export";
    }
  };

  return (
    <div className="min-vh-100" style={{ backgroundColor: "#f8f9fa" }}>
      {/* Header */}
      <nav className="navbar navbar-expand-lg navbar-light bg-white shadow-sm">
        <div className="container-fluid">
          <button
            className="btn btn-outline-secondary d-flex align-items-center"
            onClick={onBack}
          >
            <RotateCcw className="me-2" size={20} />
            Back to Editor
          </button>

          <h4 className="navbar-brand mb-0 mx-auto">
            Video Preview: {videoData?.name || "Wedding Video"}
          </h4>

          <div className="d-flex gap-2">
            <button
              className="btn btn-success d-flex align-items-center"
              onClick={onSave}
            >
              <Settings className="me-1" size={16} />
              Save Project
            </button>
            <button
              className="btn btn-primary d-flex align-items-center"
              onClick={handleExport}
              disabled={exportStatus === "exporting"}
            >
              {getExportStatusIcon()}
              <span className="ms-1">{getExportStatusText()}</span>
            </button>
          </div>
        </div>
      </nav>

      <div className="container-fluid py-4">
        <div className="row">
          {/* Main Video Preview */}
          <div className="col-lg-8 mb-4">
            <div className="card">
              <div className="card-body p-0">
                <div
                  className="position-relative"
                  style={{ backgroundColor: "#000" }}
                >
                  <video
                    ref={videoRef}
                    className="w-100"
                    style={{ maxHeight: "600px", objectFit: "contain" }}
                    controls={false}
                    muted={isMuted}
                    poster={videoData?.thumbnail}
                  >
                    <source src={videoData?.videoUrl} type="video/mp4" />
                    Your browser does not support the video tag.
                  </video>

                  {/* Video Overlay Elements */}
                  {videoData?.elements?.map((element) => (
                    <div
                      key={element.id}
                      className="position-absolute"
                      style={{
                        left: element.x,
                        top: element.y,
                        color: element.color,
                        fontSize: element.fontSize,
                        fontFamily: element.fontFamily,
                        fontWeight: element.fontWeight,
                        fontStyle: element.fontStyle,
                        WebkitTextStroke: `${element.strokeWidth}px ${element.stroke}`,
                        opacity: element.opacity || 1,
                        transform: `rotate(${element.angle || 0}deg) scale(${
                          element.scaleX || 1
                        }, ${element.scaleY || 1})`,
                        transformOrigin: "center",
                      }}
                    >
                      {element.text}
                    </div>
                  ))}

                  {/* Play/Pause Overlay */}
                  {!isPlaying && (
                    <div className="position-absolute top-50 start-50 translate-middle">
                      <button
                        className="btn btn-light btn-lg rounded-circle shadow"
                        onClick={handlePlayPause}
                        style={{ width: "80px", height: "80px" }}
                      >
                        <Play size={32} />
                      </button>
                    </div>
                  )}
                </div>

                {/* Video Controls */}
                <div className="p-3 bg-light">
                  <div className="d-flex align-items-center mb-2">
                    <button
                      className="btn btn-outline-primary btn-sm me-2"
                      onClick={handlePlayPause}
                    >
                      {isPlaying ? <Pause size={16} /> : <Play size={16} />}
                    </button>

                    <div className="flex-grow-1 mx-2">
                      <div
                        className="progress"
                        style={{ height: "6px", cursor: "pointer" }}
                        onClick={handleSeek}
                      >
                        <div
                          className="progress-bar"
                          style={{
                            width: `${(currentTime / duration) * 100}%`,
                            backgroundColor: "#007bff",
                          }}
                        />
                      </div>
                    </div>

                    <span className="text-muted small">
                      {formatTime(currentTime)} / {formatTime(duration)}
                    </span>
                  </div>

                  <div className="d-flex align-items-center justify-content-between">
                    <div className="d-flex align-items-center">
                      <button
                        className="btn btn-outline-secondary btn-sm me-2"
                        onClick={handleMute}
                      >
                        {isMuted ? (
                          <VolumeX size={16} />
                        ) : (
                          <Volume2 size={16} />
                        )}
                      </button>

                      <input
                        type="range"
                        className="form-range me-3"
                        min="0"
                        max="1"
                        step="0.1"
                        value={volume}
                        onChange={handleVolumeChange}
                        style={{ width: "100px" }}
                      />
                    </div>

                    <div className="d-flex align-items-center gap-2">
                      <select
                        className="form-select form-select-sm"
                        value={playbackRate}
                        onChange={(e) =>
                          handlePlaybackRateChange(parseFloat(e.target.value))
                        }
                        style={{ width: "80px" }}
                      >
                        <option value="0.5">0.5x</option>
                        <option value="0.75">0.75x</option>
                        <option value="1">1x</option>
                        <option value="1.25">1.25x</option>
                        <option value="1.5">1.5x</option>
                        <option value="2">2x</option>
                      </select>

                      <button
                        className="btn btn-outline-secondary btn-sm"
                        onClick={handleFullscreen}
                      >
                        <Maximize2 size={16} />
                      </button>

                      <button
                        className="btn btn-outline-secondary btn-sm"
                        onClick={() => setShowSettings(!showSettings)}
                      >
                        <Settings size={16} />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Export Settings Sidebar */}
          <div className="col-lg-4">
            <div className="card">
              <div className="card-header">
                <h5 className="card-title mb-0 d-flex align-items-center">
                  <Download className="me-2" size={20} />
                  Export Settings
                </h5>
              </div>
              <div className="card-body">
                {/* Export Progress */}
                {exportStatus === "exporting" && (
                  <div className="mb-4">
                    <div className="d-flex justify-content-between align-items-center mb-2">
                      <span className="small fw-bold">Export Progress</span>
                      <span className="small text-muted">
                        {exportProgress}%
                      </span>
                    </div>
                    <div className="progress">
                      <div
                        className="progress-bar progress-bar-striped progress-bar-animated"
                        style={{ width: `${exportProgress}%` }}
                      />
                    </div>
                  </div>
                )}

                {/* Export Format */}
                <div className="mb-3">
                  <label className="form-label">Format</label>
                  <select
                    className="form-select"
                    value={exportFormat}
                    onChange={(e) => setExportFormat(e.target.value)}
                    disabled={exportStatus === "exporting"}
                  >
                    <option value="mp4">MP4 (Recommended)</option>
                    <option value="mov">MOV (Apple)</option>
                    <option value="avi">AVI (Windows)</option>
                    <option value="webm">WebM (Web)</option>
                  </select>
                </div>

                {/* Export Quality */}
                <div className="mb-3">
                  <label className="form-label">Quality</label>
                  <select
                    className="form-select"
                    value={exportQuality}
                    onChange={(e) => setExportQuality(e.target.value)}
                    disabled={exportStatus === "exporting"}
                  >
                    <option value="720p">HD (720p) - Smaller file</option>
                    <option value="1080p">Full HD (1080p) - Balanced</option>
                    <option value="4k">4K Ultra HD - Best quality</option>
                  </select>
                </div>

                {/* Video Info */}
                <div className="mb-3">
                  <h6>Video Information</h6>
                  <div className="small text-muted">
                    <div className="d-flex justify-content-between">
                      <span>Duration:</span>
                      <span>{formatTime(duration)}</span>
                    </div>
                    <div className="d-flex justify-content-between">
                      <span>Elements:</span>
                      <span>{videoData?.elements?.length || 0}</span>
                    </div>
                    <div className="d-flex justify-content-between">
                      <span>Audio Tracks:</span>
                      <span>{videoData?.audioTracks?.length || 0}</span>
                    </div>
                    <div className="d-flex justify-content-between">
                      <span>Resolution:</span>
                      <span>{exportQuality}</span>
                    </div>
                  </div>
                </div>

                {/* Export Actions */}
                <div className="d-grid gap-2">
                  <button
                    className="btn btn-primary"
                    onClick={handleExport}
                    disabled={exportStatus === "exporting"}
                  >
                    <Download className="me-1" size={16} />
                    Export Video
                  </button>

                  <button
                    className="btn btn-outline-secondary"
                    onClick={() =>
                      navigator.share &&
                      navigator.share({
                        title: videoData?.name,
                        text: "Check out my wedding video!",
                        url: window.location.href,
                      })
                    }
                  >
                    <Share2 className="me-1" size={16} />
                    Share
                  </button>
                </div>

                {/* Export History */}
                <div className="mt-4">
                  <h6>Recent Exports</h6>
                  <div className="list-group list-group-flush">
                    <div className="list-group-item d-flex justify-content-between align-items-center px-0">
                      <div>
                        <div className="fw-bold small">wedding-video-1.mp4</div>
                        <div className="text-muted small">2 hours ago</div>
                      </div>
                      <button className="btn btn-sm btn-outline-primary">
                        <Download size={14} />
                      </button>
                    </div>
                    <div className="list-group-item d-flex justify-content-between align-items-center px-0">
                      <div>
                        <div className="fw-bold small">wedding-video-2.mov</div>
                        <div className="text-muted small">1 day ago</div>
                      </div>
                      <button className="btn btn-sm btn-outline-primary">
                        <Download size={14} />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Advanced Settings */}
            {showSettings && (
              <div className="card mt-3">
                <div className="card-header">
                  <h6 className="card-title mb-0">Advanced Settings</h6>
                </div>
                <div className="card-body">
                  <div className="mb-3">
                    <label className="form-label">Bitrate</label>
                    <select className="form-select form-select-sm">
                      <option value="auto">Auto</option>
                      <option value="low">Low (1 Mbps)</option>
                      <option value="medium">Medium (5 Mbps)</option>
                      <option value="high">High (10 Mbps)</option>
                    </select>
                  </div>

                  <div className="mb-3">
                    <label className="form-label">Frame Rate</label>
                    <select className="form-select form-select-sm">
                      <option value="24">24 fps (Cinematic)</option>
                      <option value="30">30 fps (Standard)</option>
                      <option value="60">60 fps (Smooth)</option>
                    </select>
                  </div>

                  <div className="form-check">
                    <input
                      className="form-check-input"
                      type="checkbox"
                      id="includeWatermark"
                    />
                    <label
                      className="form-check-label"
                      htmlFor="includeWatermark"
                    >
                      Include watermark
                    </label>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default VideoPreview;
