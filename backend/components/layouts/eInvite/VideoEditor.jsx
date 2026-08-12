import React, { useState, useRef, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import VideoCanvas from "./VideoCanvas";
import {
  ArrowLeft,
  ArrowRight,
  Play,
  Pause,
  Volume2,
  VolumeX,
  Download,
  Save,
  RotateCcw,
  Type,
  Image,
  Video,
  Music,
  Palette,
  Settings,
  Check,
  X,
  Plus,
  Trash2,
  Edit3,
  Move,
  RotateCw,
  Scissors,
  Clock,
  Upload,
  Eye,
} from "lucide-react";
import Swal from "sweetalert2";

const VideoEditor = ({ template, onBack, onVideoDataUpdate, onPreview }) => {
  const navigate = useNavigate();
  const videoRef = useRef(null);
  const canvasRef = useRef(null);
  const fileInputRef = useRef(null);
  const audioInputRef = useRef(null);

  const [currentStep, setCurrentStep] = useState(1);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [volume, setVolume] = useState(1);
  const [isMuted, setIsMuted] = useState(false);
  const [playbackRate, setPlaybackRate] = useState(1);
  const [activeText, setActiveText] = useState(null);
  const [textOptions, setTextOptions] = useState({
    fontSize: 30,
    fontFamily: "Arial",
    color: "#ffffff",
    text: "Your Text Here",
    fontWeight: "normal",
    fontStyle: "normal",
    stroke: "#000000",
    strokeWidth: 2,
  });
  const [videoElements, setVideoElements] = useState([]);
  const [audioTracks, setAudioTracks] = useState([]);
  const [filters, setFilters] = useState({
    brightness: 100,
    contrast: 100,
    saturation: 100,
    hue: 0,
  });
  const [transitions, setTransitions] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [projectName, setProjectName] = useState("My Wedding Video");

  const steps = [
    { id: 1, title: "Template", description: "Choose your video template" },
    { id: 2, title: "Upload", description: "Add your photos and videos" },
    { id: 3, title: "Edit", description: "Customize text and elements" },
    { id: 4, title: "Music", description: "Add background music" },
    { id: 5, title: "Effects", description: "Apply filters and transitions" },
    { id: 6, title: "Export", description: "Preview and download" },
  ];

  useEffect(() => {
    if (videoRef.current) {
      const video = videoRef.current;

      const handleTimeUpdate = () => setCurrentTime(video.currentTime);
      const handleLoadedMetadata = () => setDuration(video.duration);
      const handlePlay = () => setIsPlaying(true);
      const handlePause = () => setIsPlaying(false);

      video.addEventListener("timeupdate", handleTimeUpdate);
      video.addEventListener("loadedmetadata", handleLoadedMetadata);
      video.addEventListener("play", handlePlay);
      video.addEventListener("pause", handlePause);

      return () => {
        video.removeEventListener("timeupdate", handleTimeUpdate);
        video.removeEventListener("loadedmetadata", handleLoadedMetadata);
        video.removeEventListener("play", handlePlay);
        video.removeEventListener("pause", handlePause);
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

  const handleFileUpload = (e) => {
    const file = e.target.files[0];
    if (file && file.type.startsWith("video/")) {
      const url = URL.createObjectURL(file);
      if (videoRef.current) {
        videoRef.current.src = url;
      }
    }
  };

  const addText = () => {
    const newText = {
      id: Date.now(),
      type: "text",
      text: "New Text",
      x: 100,
      y: 100,
      fontSize: 30,
      fontFamily: "Arial",
      color: "#ffffff",
      fontWeight: "normal",
      fontStyle: "normal",
      stroke: "#000000",
      strokeWidth: 2,
      startTime: currentTime,
      endTime: currentTime + 5,
    };
    setVideoElements([...videoElements, newText]);
  };

  const addImage = () => {
    fileInputRef.current?.click();
  };

  const handleImageUpload = (e) => {
    const file = e.target.files[0];
    if (file && file.type.startsWith("image/")) {
      const reader = new FileReader();
      reader.onload = (event) => {
        const newImage = {
          id: Date.now(),
          type: "image",
          src: event.target.result,
          x: 100,
          y: 100,
          width: 200,
          height: 200,
          startTime: currentTime,
          endTime: currentTime + 5,
        };
        setVideoElements([...videoElements, newImage]);
      };
      reader.readAsDataURL(file);
    }
  };

  const addAudio = () => {
    audioInputRef.current?.click();
  };

  const handleAudioUpload = (e) => {
    const file = e.target.files[0];
    if (file && file.type.startsWith("audio/")) {
      const url = URL.createObjectURL(file);
      const newAudio = {
        id: Date.now(),
        src: url,
        name: file.name,
        startTime: currentTime,
        volume: 0.5,
      };
      setAudioTracks([...audioTracks, newAudio]);
    }
  };

  const updateText = (id, property, value) => {
    setVideoElements((elements) =>
      elements.map((el) => (el.id === id ? { ...el, [property]: value } : el))
    );
  };

  const deleteElement = (id) => {
    setVideoElements((elements) => elements.filter((el) => el.id !== id));
  };

  const applyFilter = (filterType, value) => {
    setFilters((prev) => ({ ...prev, [filterType]: value }));
    if (videoRef.current) {
      const video = videoRef.current;
      video.style.filter = `
        brightness(${filters.brightness}%) 
        contrast(${filters.contrast}%) 
        saturate(${filters.saturation}%) 
        hue-rotate(${filters.hue}deg)
      `;
    }
  };

  const exportVideo = () => {
    setIsLoading(true);
    // Simulate video export
    setTimeout(() => {
      setIsLoading(false);
      // alert("Video exported successfully!");
      Swal.fire({
        icon: "success",
        title: "Video Exported",
        text: "Your video has been successfully exported.",
        timer:1500
      })
    }, 3000);
  };

  const handlePreview = () => {
    const videoData = {
      name: projectName,
      template: template,
      elements: videoElements,
      audioTracks: audioTracks,
      filters: filters,
      transitions: transitions,
      videoUrl: template?.videoUrl,
      thumbnail: template?.thumbnail,
    };

    if (onVideoDataUpdate) {
      onVideoDataUpdate(videoData);
    }

    if (onPreview) {
      onPreview();
    }
  };

  const saveProject = () => {
    const projectData = {
      name: projectName,
      template: template,
      elements: videoElements,
      audioTracks: audioTracks,
      filters: filters,
      transitions: transitions,
      savedAt: new Date().toISOString(),
    };

    const projectId = `wedding-video-${Date.now()}`;
    localStorage.setItem(projectId, JSON.stringify(projectData));
    // alert("Project saved successfully!");
    Swal.fire({
      icon: "success",
      title: "Project Saved",
      text: "Your project has been successfully saved.",
    })
  };

  const nextStep = () => {
    if (currentStep < 6) {
      setCurrentStep(currentStep + 1);
    }
  };

  const prevStep = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  const formatTime = (time) => {
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes}:${seconds.toString().padStart(2, "0")}`;
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
            <ArrowLeft className="me-2" size={20} />
            Back to Templates
          </button>

          <h4 className="navbar-brand mb-0 mx-auto">
            Video Editor: {template?.name || "Wedding Video"}
          </h4>

          <div className="d-flex gap-2">
            <button
              className="btn btn-success d-flex align-items-center"
              onClick={saveProject}
            >
              <Save className="me-1" size={16} />
              Save
            </button>
            <button
              className="btn btn-primary d-flex align-items-center"
              onClick={exportVideo}
              disabled={isLoading}
            >
              {isLoading ? (
                <div
                  className="spinner-border spinner-border-sm me-1"
                  role="status"
                >
                  <span className="visually-hidden">Loading...</span>
                </div>
              ) : (
                <Download className="me-1" size={16} />
              )}
              Export
            </button>
          </div>
        </div>
      </nav>

      {/* Progress Steps */}
      <div className="container-fluid py-3">
        <div className="row">
          <div className="col-12">
            <div className="d-flex justify-content-between align-items-center">
              {steps.map((step, index) => (
                <div key={step.id} className="d-flex align-items-center">
                  <div
                    className={`rounded-circle d-flex align-items-center justify-content-center ${
                      currentStep >= step.id
                        ? "bg-primary text-white"
                        : "bg-light text-muted"
                    }`}
                    style={{ width: "40px", height: "40px" }}
                  >
                    {currentStep > step.id ? (
                      <Check size={20} />
                    ) : (
                      <span className="fw-bold">{step.id}</span>
                    )}
                  </div>
                  <div className="ms-2">
                    <div className="fw-bold text-sm">{step.title}</div>
                    <div className="text-muted text-xs">{step.description}</div>
                  </div>
                  {index < steps.length - 1 && (
                    <div
                      className={`mx-3 ${
                        currentStep > step.id ? "text-primary" : "text-muted"
                      }`}
                    >
                      <ArrowRight size={16} />
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="container-fluid py-4">
        <div className="row">
          {/* Left Sidebar - Tools */}
          <div className="col-xl-3 col-lg-4 mb-4">
            <div className="card">
              <div className="card-header">
                <h5 className="card-title mb-0 d-flex align-items-center">
                  <Settings className="me-2" size={20} />
                  {steps[currentStep - 1].title} Tools
                </h5>
              </div>
              <div className="card-body">
                {currentStep === 1 && (
                  <div>
                    <h6>Choose Template</h6>
                    <div className="d-grid gap-2">
                      <button className="btn btn-outline-primary btn-sm">
                        <Video className="me-1" size={16} />
                        Classic Wedding
                      </button>
                      <button className="btn btn-outline-primary btn-sm">
                        <Video className="me-1" size={16} />
                        Modern Romance
                      </button>
                      <button className="btn btn-outline-primary btn-sm">
                        <Video className="me-1" size={16} />
                        Rustic Charm
                      </button>
                    </div>
                  </div>
                )}

                {currentStep === 2 && (
                  <div>
                    <h6>Upload Media</h6>
                    <div className="d-grid gap-2">
                      <button
                        className="btn btn-outline-primary btn-sm"
                        onClick={addImage}
                      >
                        <Image className="me-1" size={16} />
                        Add Photos
                      </button>
                      <button
                        className="btn btn-outline-secondary btn-sm"
                        onClick={() => fileInputRef.current?.click()}
                      >
                        <Video className="me-1" size={16} />
                        Add Videos
                      </button>
                      <input
                        ref={fileInputRef}
                        type="file"
                        accept="video/*,image/*"
                        onChange={handleFileUpload}
                        className="d-none"
                      />
                    </div>
                  </div>
                )}

                {currentStep === 3 && (
                  <div>
                    <h6>Add Elements</h6>
                    <div className="d-grid gap-2">
                      <button
                        className="btn btn-outline-primary btn-sm"
                        onClick={addText}
                      >
                        <Type className="me-1" size={16} />
                        Add Text
                      </button>
                      <button
                        className="btn btn-outline-secondary btn-sm"
                        onClick={addImage}
                      >
                        <Image className="me-1" size={16} />
                        Add Image
                      </button>
                    </div>

                    {activeText && (
                      <>
                        <hr />
                        <div>
                          <h6>Text Properties</h6>
                          <div className="mb-3">
                            <label className="form-label">Text Content</label>
                            <textarea
                              className="form-control"
                              rows="3"
                              value={textOptions.text}
                              onChange={(e) =>
                                setTextOptions((prev) => ({
                                  ...prev,
                                  text: e.target.value,
                                }))
                              }
                            />
                          </div>
                          <div className="mb-3">
                            <label className="form-label">Font Size</label>
                            <input
                              type="range"
                              className="form-range"
                              min="8"
                              max="72"
                              value={textOptions.fontSize}
                              onChange={(e) =>
                                setTextOptions((prev) => ({
                                  ...prev,
                                  fontSize: parseInt(e.target.value),
                                }))
                              }
                            />
                          </div>
                          <div className="mb-3">
                            <label className="form-label">Text Color</label>
                            <input
                              type="color"
                              className="form-control form-control-color w-100"
                              value={textOptions.color}
                              onChange={(e) =>
                                setTextOptions((prev) => ({
                                  ...prev,
                                  color: e.target.value,
                                }))
                              }
                            />
                          </div>
                        </div>
                      </>
                    )}
                  </div>
                )}

                {currentStep === 4 && (
                  <div>
                    <h6>Audio Tracks</h6>
                    <div className="d-grid gap-2">
                      <button
                        className="btn btn-outline-primary btn-sm"
                        onClick={addAudio}
                      >
                        <Music className="me-1" size={16} />
                        Add Music
                      </button>
                      <input
                        ref={audioInputRef}
                        type="file"
                        accept="audio/*"
                        onChange={handleAudioUpload}
                        className="d-none"
                      />
                    </div>
                    {audioTracks.map((track) => (
                      <div
                        key={track.id}
                        className="d-flex align-items-center justify-content-between mt-2 p-2 bg-light rounded"
                      >
                        <span className="text-sm">{track.name}</span>
                        <button
                          className="btn btn-sm btn-outline-danger"
                          onClick={() =>
                            setAudioTracks((tracks) =>
                              tracks.filter((t) => t.id !== track.id)
                            )
                          }
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
                    ))}
                  </div>
                )}

                {currentStep === 5 && (
                  <div>
                    <h6>Video Effects</h6>
                    <div className="mb-3">
                      <label className="form-label">
                        Brightness: {filters.brightness}%
                      </label>
                      <input
                        type="range"
                        className="form-range"
                        min="0"
                        max="200"
                        value={filters.brightness}
                        onChange={(e) =>
                          applyFilter("brightness", parseInt(e.target.value))
                        }
                      />
                    </div>
                    <div className="mb-3">
                      <label className="form-label">
                        Contrast: {filters.contrast}%
                      </label>
                      <input
                        type="range"
                        className="form-range"
                        min="0"
                        max="200"
                        value={filters.contrast}
                        onChange={(e) =>
                          applyFilter("contrast", parseInt(e.target.value))
                        }
                      />
                    </div>
                    <div className="mb-3">
                      <label className="form-label">
                        Saturation: {filters.saturation}%
                      </label>
                      <input
                        type="range"
                        className="form-range"
                        min="0"
                        max="200"
                        value={filters.saturation}
                        onChange={(e) =>
                          applyFilter("saturation", parseInt(e.target.value))
                        }
                      />
                    </div>
                  </div>
                )}

                {currentStep === 6 && (
                  <div>
                    <h6>Export Options</h6>
                    <div className="mb-3">
                      <label className="form-label">Project Name</label>
                      <input
                        type="text"
                        className="form-control"
                        value={projectName}
                        onChange={(e) => setProjectName(e.target.value)}
                      />
                    </div>
                    <div className="mb-3">
                      <label className="form-label">Quality</label>
                      <select className="form-select">
                        <option value="720p">HD (720p)</option>
                        <option value="1080p">Full HD (1080p)</option>
                        <option value="4k">4K Ultra HD</option>
                      </select>
                    </div>
                    <div className="mb-3">
                      <label className="form-label">Format</label>
                      <select className="form-select">
                        <option value="mp4">MP4</option>
                        <option value="mov">MOV</option>
                        <option value="avi">AVI</option>
                      </select>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Main Video Area */}
          <div className="col-xl-6 col-lg-8 mb-4">
            <div className="card">
              <div className="card-body p-0">
                <div
                  className="position-relative"
                  style={{ backgroundColor: "#000" }}
                >
                  <video
                    ref={videoRef}
                    className="w-100"
                    style={{ maxHeight: "500px", objectFit: "contain" }}
                    controls={false}
                    muted={isMuted}
                    onTimeUpdate={(e) => setCurrentTime(e.target.currentTime)}
                  >
                    <source src={template?.videoUrl || ""} type="video/mp4" />
                    Your browser does not support the video tag.
                  </video>

                  {/* Video Overlay Elements */}
                  {videoElements.map((element) => (
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
                        cursor: "move",
                      }}
                      onMouseDown={(e) => {
                        // Handle drag functionality
                        e.preventDefault();
                      }}
                    >
                      {element.text}
                      <button
                        className="btn btn-sm btn-danger ms-2"
                        onClick={() => deleteElement(element.id)}
                      >
                        <X size={12} />
                      </button>
                    </div>
                  ))}
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

                  <div className="d-flex align-items-center">
                    <button
                      className="btn btn-outline-secondary btn-sm me-2"
                      onClick={handleMute}
                    >
                      {isMuted ? <VolumeX size={16} /> : <Volume2 size={16} />}
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

                    <select
                      className="form-select form-select-sm"
                      value={playbackRate}
                      onChange={(e) => {
                        setPlaybackRate(parseFloat(e.target.value));
                        if (videoRef.current) {
                          videoRef.current.playbackRate = parseFloat(
                            e.target.value
                          );
                        }
                      }}
                      style={{ width: "80px" }}
                    >
                      <option value="0.5">0.5x</option>
                      <option value="0.75">0.75x</option>
                      <option value="1">1x</option>
                      <option value="1.25">1.25x</option>
                      <option value="1.5">1.5x</option>
                      <option value="2">2x</option>
                    </select>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right Sidebar - Timeline */}
          <div className="col-xl-3 d-none d-xl-block">
            <div className="card">
              <div className="card-header">
                <h5 className="card-title mb-0 d-flex align-items-center">
                  <Clock className="me-2" size={20} />
                  Timeline
                </h5>
              </div>
              <div className="card-body">
                <div className="mb-3">
                  <h6>Video Elements</h6>
                  {videoElements.map((element) => (
                    <div
                      key={element.id}
                      className="d-flex align-items-center justify-content-between p-2 bg-light rounded mb-2"
                    >
                      <div>
                        <div className="fw-bold text-sm">{element.type}</div>
                        <div className="text-muted text-xs">
                          {formatTime(element.startTime)} -{" "}
                          {formatTime(element.endTime)}
                        </div>
                      </div>
                      <div className="d-flex gap-1">
                        <button
                          className="btn btn-sm btn-outline-primary"
                          onClick={() => setActiveText(element)}
                        >
                          <Edit3 size={12} />
                        </button>
                        <button
                          className="btn btn-sm btn-outline-danger"
                          onClick={() => deleteElement(element.id)}
                        >
                          <Trash2 size={12} />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>

                <div className="mb-3">
                  <h6>Audio Tracks</h6>
                  {audioTracks.map((track) => (
                    <div
                      key={track.id}
                      className="d-flex align-items-center justify-content-between p-2 bg-light rounded mb-2"
                    >
                      <div>
                        <div className="fw-bold text-sm">{track.name}</div>
                        <div className="text-muted text-xs">
                          Volume: {Math.round(track.volume * 100)}%
                        </div>
                      </div>
                      <button
                        className="btn btn-sm btn-outline-danger"
                        onClick={() =>
                          setAudioTracks((tracks) =>
                            tracks.filter((t) => t.id !== track.id)
                          )
                        }
                      >
                        <Trash2 size={12} />
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Navigation Buttons */}
        <div className="row mt-4">
          <div className="col-12">
            <div className="d-flex justify-content-between">
              <button
                className="btn btn-outline-secondary"
                onClick={prevStep}
                disabled={currentStep === 1}
              >
                <ArrowLeft className="me-1" size={16} />
                Previous
              </button>

              <div className="d-flex gap-2">
                <button
                  className="btn btn-outline-warning"
                  onClick={() => setCurrentStep(1)}
                >
                  <RotateCcw className="me-1" size={16} />
                  Reset
                </button>

                {currentStep < 6 ? (
                  <button className="btn btn-primary" onClick={nextStep}>
                    Next
                    <ArrowRight className="ms-1" size={16} />
                  </button>
                ) : (
                  <div className="d-flex gap-2">
                    <button className="btn btn-info" onClick={handlePreview}>
                      <Eye className="me-1" size={16} />
                      Preview
                    </button>
                    <button
                      className="btn btn-success"
                      onClick={exportVideo}
                      disabled={isLoading}
                    >
                      {isLoading ? (
                        <>
                          <div
                            className="spinner-border spinner-border-sm me-1"
                            role="status"
                          >
                            <span className="visually-hidden">Loading...</span>
                          </div>
                          Exporting...
                        </>
                      ) : (
                        <>
                          <Download className="me-1" size={16} />
                          Export Video
                        </>
                      )}
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VideoEditor;
