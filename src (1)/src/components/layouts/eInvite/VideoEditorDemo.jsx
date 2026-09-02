import React from "react";
import { useNavigate } from "react-router-dom";
import {
  Video,
  Play,
  Edit3,
  Download,
  Sparkles,
  ArrowRight,
  Clock,
  Star,
  Users,
  Palette,
  Music,
  Type,
  Image,
  Settings,
} from "lucide-react";

const VideoEditorDemo = () => {
  const navigate = useNavigate();

  const features = [
    {
      icon: <Type size={24} />,
      title: "Text Overlay",
      description:
        "Add beautiful text animations and custom fonts to your videos",
    },
    {
      icon: <Image size={24} />,
      title: "Photo Integration",
      description: "Seamlessly blend photos with video content",
    },
    {
      icon: <Music size={24} />,
      title: "Audio Sync",
      description: "Perfect audio synchronization with background music",
    },
    {
      icon: <Palette size={24} />,
      title: "Visual Effects",
      description: "Apply filters, transitions, and color grading",
    },
    {
      icon: <Settings size={24} />,
      title: "Advanced Controls",
      description: "Professional editing tools for precise control",
    },
    {
      icon: <Download size={24} />,
      title: "Export Options",
      description: "Export in multiple formats and quality settings",
    },
  ];

  const steps = [
    {
      number: "01",
      title: "Choose Template",
      description:
        "Select from our collection of beautiful wedding video templates",
    },
    {
      number: "02",
      title: "Upload Media",
      description: "Add your photos, videos, and audio files",
    },
    {
      number: "03",
      title: "Customize",
      description: "Edit text, add effects, and personalize your video",
    },
    {
      number: "04",
      title: "Add Music",
      description: "Choose from our music library or upload your own",
    },
    {
      number: "05",
      title: "Apply Effects",
      description: "Add filters, transitions, and visual enhancements",
    },
    {
      number: "06",
      title: "Export & Share",
      description: "Download your video and share with family and friends",
    },
  ];

  return (
    <div className="min-vh-100" style={{ backgroundColor: "#f8f9fa" }}>
      {/* Hero Section */}
      <div className="bg-gradient-to-r from-pink-500 to-purple-600 text-white py-5">
        <div className="container">
          <div className="row align-items-center">
            <div className="col-lg-6">
              <h1 className="display-4 fw-bold mb-4">
                Create Stunning Wedding Videos
              </h1>
              <p className="lead mb-4">
                Professional video editing tools designed specifically for
                wedding invitations. Create beautiful, personalized videos that
                tell your love story.
              </p>
              <div className="d-flex gap-3">
                <button
                  className="btn btn-light btn-lg px-4"
                  onClick={() => navigate("/video-templates")}
                >
                  <Video className="me-2" size={20} />
                  Browse Templates
                </button>
                <button
                  className="btn btn-outline-light btn-lg px-4"
                  onClick={() => navigate("/video-editor")}
                >
                  <Edit3 className="me-2" size={20} />
                  Start Creating
                </button>
              </div>
            </div>
            <div className="col-lg-6 text-center">
              <div className="position-relative">
                <div className="bg-white rounded-3 p-4 shadow-lg">
                  <div className="bg-dark rounded-2 p-3 mb-3">
                    <div className="d-flex align-items-center justify-content-between mb-2">
                      <div className="d-flex gap-2">
                        <div
                          className="bg-danger rounded-circle"
                          style={{ width: "12px", height: "12px" }}
                        ></div>
                        <div
                          className="bg-warning rounded-circle"
                          style={{ width: "12px", height: "12px" }}
                        ></div>
                        <div
                          className="bg-success rounded-circle"
                          style={{ width: "12px", height: "12px" }}
                        ></div>
                      </div>
                      <span className="text-white small">Video Editor</span>
                    </div>
                    <div className="bg-gradient-to-r from-pink-400 to-purple-500 rounded p-3 text-center">
                      <Play className="text-white mb-2" size={32} />
                      <div className="text-white small">
                        Wedding Video Preview
                      </div>
                    </div>
                  </div>
                  <div className="d-flex justify-content-center gap-2">
                    <button className="btn btn-sm btn-outline-primary">
                      <Play size={16} />
                    </button>
                    <button className="btn btn-sm btn-primary">
                      <Edit3 size={16} />
                    </button>
                    <button className="btn btn-sm btn-success">
                      <Download size={16} />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div className="py-5">
        <div className="container">
          <div className="text-center mb-5">
            <h2 className="h3 mb-3">Powerful Video Editing Features</h2>
            <p className="text-muted">
              Everything you need to create professional wedding videos
            </p>
          </div>

          <div className="row g-4">
            {features.map((feature, index) => (
              <div key={index} className="col-lg-4 col-md-6">
                <div className="card h-100 border-0 shadow-sm">
                  <div className="card-body text-center p-4">
                    <div
                      className="bg-primary bg-opacity-10 rounded-circle d-inline-flex align-items-center justify-content-center mb-3"
                      style={{ width: "60px", height: "60px" }}
                    >
                      <div className="text-primary">{feature.icon}</div>
                    </div>
                    <h5 className="card-title">{feature.title}</h5>
                    <p className="card-text text-muted">
                      {feature.description}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* How It Works Section */}
      <div className="bg-white py-5">
        <div className="container">
          <div className="text-center mb-5">
            <h2 className="h3 mb-3">How It Works</h2>
            <p className="text-muted">
              Create your wedding video in 6 simple steps
            </p>
          </div>

          <div className="row g-4">
            {steps.map((step, index) => (
              <div key={index} className="col-lg-4 col-md-6">
                <div className="text-center">
                  <div
                    className="bg-primary text-white rounded-circle d-inline-flex align-items-center justify-content-center mb-3"
                    style={{ width: "60px", height: "60px" }}
                  >
                    <span className="fw-bold fs-5">{step.number}</span>
                  </div>
                  <h5 className="mb-2">{step.title}</h5>
                  <p className="text-muted small">{step.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* CTA Section */}
      <div className="bg-gradient-to-r from-pink-500 to-purple-600 text-white py-5">
        <div className="container text-center">
          <h2 className="h3 mb-3">Ready to Create Your Wedding Video?</h2>
          <p className="lead mb-4">
            Join thousands of couples who have created beautiful wedding videos
            with our editor
          </p>
          <div className="d-flex justify-content-center gap-3 flex-wrap">
            <button
              className="btn btn-light btn-lg px-4"
              onClick={() => navigate("/video-templates")}
            >
              <Video className="me-2" size={20} />
              Browse Templates
            </button>
            <button
              className="btn btn-outline-light btn-lg px-4"
              onClick={() => navigate("/video-editor")}
            >
              <Sparkles className="me-2" size={20} />
              Start Creating Now
            </button>
          </div>
        </div>
      </div>

      {/* Stats Section */}
      <div className="py-5">
        <div className="container">
          <div className="row text-center">
            <div className="col-lg-3 col-md-6 mb-4">
              <div className="d-flex flex-column align-items-center">
                <div
                  className="bg-primary bg-opacity-10 rounded-circle d-flex align-items-center justify-content-center mb-3"
                  style={{ width: "80px", height: "80px" }}
                >
                  <Users className="text-primary" size={32} />
                </div>
                <h3 className="fw-bold text-primary">10,000+</h3>
                <p className="text-muted">Happy Couples</p>
              </div>
            </div>
            <div className="col-lg-3 col-md-6 mb-4">
              <div className="d-flex flex-column align-items-center">
                <div
                  className="bg-success bg-opacity-10 rounded-circle d-flex align-items-center justify-content-center mb-3"
                  style={{ width: "80px", height: "80px" }}
                >
                  <Video className="text-success" size={32} />
                </div>
                <h3 className="fw-bold text-success">50,000+</h3>
                <p className="text-muted">Videos Created</p>
              </div>
            </div>
            <div className="col-lg-3 col-md-6 mb-4">
              <div className="d-flex flex-column align-items-center">
                <div
                  className="bg-warning bg-opacity-10 rounded-circle d-flex align-items-center justify-content-center mb-3"
                  style={{ width: "80px", height: "80px" }}
                >
                  <Star className="text-warning" size={32} />
                </div>
                <h3 className="fw-bold text-warning">4.9/5</h3>
                <p className="text-muted">Average Rating</p>
              </div>
            </div>
            <div className="col-lg-3 col-md-6 mb-4">
              <div className="d-flex flex-column align-items-center">
                <div
                  className="bg-info bg-opacity-10 rounded-circle d-flex align-items-center justify-content-center mb-3"
                  style={{ width: "80px", height: "80px" }}
                >
                  <Clock className="text-info" size={32} />
                </div>
                <h3 className="fw-bold text-info">2 min</h3>
                <p className="text-muted">Average Creation Time</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VideoEditorDemo;
