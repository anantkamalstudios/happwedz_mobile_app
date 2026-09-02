import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Play,
  Heart,
  Star,
  Filter,
  Search,
  Video,
  Clock,
  Users,
  Palette,
  Music,
  Sparkles,
} from "lucide-react";

const VideoTemplates = () => {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState("all");
  const [selectedFilter, setSelectedFilter] = useState("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedTemplate, setSelectedTemplate] = useState(null);

  const videoTemplates = [
    {
      id: 1,
      name: "Classic Romance",
      category: "romantic",
      theme: "classic",
      duration: "2:30",
      thumbnail:
        "https://image.wedmegood.com/e-invite-images/5921489f-e0f7-411a-8b19-a85f2c11d2e9-1.JPEG",
      videoUrl:
        "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
      rating: 4.8,
      downloads: 1250,
      price: "Free",
      features: ["Text Overlay", "Music Sync", "Transitions"],
      colors: ["#FF6B9D", "#FFE4E1", "#FFFFFF"],
    },
    {
      id: 2,
      name: "Modern Elegance",
      category: "modern",
      theme: "elegant",
      duration: "3:15",
      thumbnail:
        "https://image.wedmegood.com/e-invite-images/5921489f-e0f7-411a-8b19-a85f2c11d2e9-1.JPEG",
      videoUrl:
        "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4",
      rating: 4.9,
      downloads: 2100,
      price: "Premium",
      features: ["4K Quality", "Custom Music", "Advanced Effects"],
      colors: ["#2C3E50", "#ECF0F1", "#E74C3C"],
    },
    {
      id: 3,
      name: "Rustic Charm",
      category: "rustic",
      theme: "vintage",
      duration: "2:45",
      thumbnail:
        "https://image.wedmegood.com/e-invite-images/5921489f-e0f7-411a-8b19-a85f2c11d2e9-1.JPEG",
      videoUrl:
        "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_5mb.mp4",
      rating: 4.7,
      downloads: 890,
      price: "Free",
      features: ["Vintage Effects", "Warm Tones", "Natural Music"],
      colors: ["#8B4513", "#F4A460", "#F5DEB3"],
    },
    {
      id: 4,
      name: "Garden Party",
      category: "outdoor",
      theme: "floral",
      duration: "3:00",
      thumbnail:
        "https://image.wedmegood.com/e-invite-images/5921489f-e0f7-411a-8b19-a85f2c11d2e9-1.JPEG",
      videoUrl:
        "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
      rating: 4.6,
      downloads: 1560,
      price: "Premium",
      features: ["Nature Sounds", "Floral Overlays", "Soft Transitions"],
      colors: ["#90EE90", "#FFB6C1", "#FFFFFF"],
    },
    {
      id: 5,
      name: "Beach Wedding",
      category: "beach",
      theme: "tropical",
      duration: "2:20",
      thumbnail:
        "https://image.wedmegood.com/e-invite-images/5921489f-e0f7-411a-8b19-a85f2c11d2e9-1.JPEG",
      videoUrl:
        "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4",
      rating: 4.8,
      downloads: 1780,
      price: "Free",
      features: ["Ocean Sounds", "Sunset Effects", "Tropical Music"],
      colors: ["#87CEEB", "#FFD700", "#FFFFFF"],
    },
    {
      id: 6,
      name: "Winter Wonderland",
      category: "winter",
      theme: "snow",
      duration: "3:30",
      thumbnail:
        "https://image.wedmegood.com/e-invite-images/5921489f-e0f7-411a-8b19-a85f2c11d2e9-1.JPEG",
      videoUrl:
        "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_5mb.mp4",
      rating: 4.9,
      downloads: 2340,
      price: "Premium",
      features: ["Snow Effects", "Cozy Music", "Warm Lighting"],
      colors: ["#FFFFFF", "#E6E6FA", "#B0C4DE"],
    },
  ];

  const categories = [
    { id: "all", name: "All Templates", count: videoTemplates.length },
    {
      id: "romantic",
      name: "Romantic",
      count: videoTemplates.filter((t) => t.category === "romantic").length,
    },
    {
      id: "modern",
      name: "Modern",
      count: videoTemplates.filter((t) => t.category === "modern").length,
    },
    {
      id: "rustic",
      name: "Rustic",
      count: videoTemplates.filter((t) => t.category === "rustic").length,
    },
    {
      id: "outdoor",
      name: "Outdoor",
      count: videoTemplates.filter((t) => t.category === "outdoor").length,
    },
    {
      id: "beach",
      name: "Beach",
      count: videoTemplates.filter((t) => t.category === "beach").length,
    },
    {
      id: "winter",
      name: "Winter",
      count: videoTemplates.filter((t) => t.category === "winter").length,
    },
  ];

  const getFilteredTemplates = () => {
    let filtered = videoTemplates;

    if (activeTab !== "all") {
      filtered = filtered.filter((template) => template.category === activeTab);
    }

    if (selectedFilter !== "all") {
      if (selectedFilter === "free") {
        filtered = filtered.filter((template) => template.price === "Free");
      } else if (selectedFilter === "premium") {
        filtered = filtered.filter((template) => template.price === "Premium");
      } else if (selectedFilter === "popular") {
        filtered = filtered.sort((a, b) => b.downloads - a.downloads);
      }
    }

    if (searchQuery) {
      filtered = filtered.filter(
        (template) =>
          template.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
          template.theme.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }

    return filtered;
  };

  const handleEditTemplate = (template) => {
    navigate("/video-editor", {
      state: { template },
    });
  };

  const handlePreviewTemplate = (template) => {
    setSelectedTemplate(template);
  };

  const TemplateCard = ({ template }) => (
    <div className="col-lg-4 col-md-6 mb-4">
      <div className="card h-100 template-card">
        <div className="position-relative">
          <img
            src={template.thumbnail}
            alt={template.name}
            className="card-img-top template-thumbnail"
            style={{ height: "250px", objectFit: "cover" }}
          />
          <div className="template-overlay">
            <div className="template-actions">
              <button
                className="btn btn-light btn-sm me-2"
                onClick={() => handlePreviewTemplate(template)}
                data-bs-toggle="modal"
                data-bs-target="#previewModal"
              >
                <Play size={16} className="me-1" />
                Preview
              </button>
              <button
                className="btn btn-primary btn-sm"
                onClick={() => handleEditTemplate(template)}
              >
                <Video size={16} className="me-1" />
                Edit
              </button>
            </div>
          </div>
          <div className="template-badges">
            <span
              className={`badge ${
                template.price === "Free" ? "bg-success" : "bg-warning"
              }`}
            >
              {template.price}
            </span>
            <span className="badge bg-dark ms-1">
              <Clock size={12} className="me-1" />
              {template.duration}
            </span>
          </div>
        </div>
        <div className="card-body">
          <h5 className="card-title">{template.name}</h5>
          <p className="card-text text-muted">
            {template.theme} • {template.category}
          </p>

          <div className="d-flex align-items-center mb-2">
            <div className="d-flex align-items-center me-3">
              <Star size={16} className="text-warning me-1" />
              <span className="small">{template.rating}</span>
            </div>
            <div className="d-flex align-items-center">
              <Users size={16} className="text-muted me-1" />
              <span className="small text-muted">
                {template.downloads.toLocaleString()}
              </span>
            </div>
          </div>

          <div className="template-features mb-3">
            {template.features.map((feature, index) => (
              <span key={index} className="badge bg-light text-dark me-1 mb-1">
                {feature}
              </span>
            ))}
          </div>

          <div className="template-colors">
            <span className="small text-muted me-2">Colors:</span>
            {template.colors.map((color, index) => (
              <span
                key={index}
                className="color-dot me-1"
                style={{ backgroundColor: color }}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <div className="min-vh-100" style={{ backgroundColor: "#f8f9fa" }}>
      {/* Header */}
      <div className="bg-white shadow-sm">
        <div className="container py-4">
          <div className="row align-items-center">
            <div className="col-md-6">
              <h1 className="h3 mb-2">Wedding Video Templates</h1>
              <p className="text-muted mb-0">
                Create stunning wedding videos with our professional templates
              </p>
            </div>
            <div className="col-md-6 text-md-end">
              <div className="d-flex justify-content-md-end gap-2">
                <button
                  className="btn btn-outline-primary"
                  onClick={() => navigate("/video-demo")}
                >
                  <Video className="me-1" size={16} />
                  See Demo
                </button>
                <button
                  className="btn btn-primary"
                  onClick={() => navigate("/video-editor")}
                >
                  <Sparkles className="me-1" size={16} />
                  Create New Video
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="container py-4">
        <div className="row">
          {/* Sidebar Filters */}
          <div className="col-lg-3 mb-4">
            <div className="card">
              <div className="card-header">
                <h5 className="card-title mb-0 d-flex align-items-center">
                  <Filter className="me-2" size={20} />
                  Filters
                </h5>
              </div>
              <div className="card-body">
                {/* Search */}
                <div className="mb-4">
                  <label className="form-label">Search Templates</label>
                  <div className="input-group">
                    <span className="input-group-text">
                      <Search size={16} />
                    </span>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="Search by name or theme..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                    />
                  </div>
                </div>

                {/* Categories */}
                <div className="mb-4">
                  <h6>Categories</h6>
                  <div className="list-group list-group-flush">
                    {categories.map((category) => (
                      <button
                        key={category.id}
                        className={`list-group-item list-group-item-action d-flex justify-content-between align-items-center ${
                          activeTab === category.id ? "active" : ""
                        }`}
                        onClick={() => setActiveTab(category.id)}
                      >
                        <span>{category.name}</span>
                        <span className="badge bg-secondary rounded-pill">
                          {category.count}
                        </span>
                      </button>
                    ))}
                  </div>
                </div>

                {/* Price Filter */}
                <div className="mb-4">
                  <h6>Price</h6>
                  <div className="d-grid gap-2">
                    <button
                      className={`btn btn-sm ${
                        selectedFilter === "all"
                          ? "btn-primary"
                          : "btn-outline-primary"
                      }`}
                      onClick={() => setSelectedFilter("all")}
                    >
                      All Templates
                    </button>
                    <button
                      className={`btn btn-sm ${
                        selectedFilter === "free"
                          ? "btn-success"
                          : "btn-outline-success"
                      }`}
                      onClick={() => setSelectedFilter("free")}
                    >
                      Free Templates
                    </button>
                    <button
                      className={`btn btn-sm ${
                        selectedFilter === "premium"
                          ? "btn-warning"
                          : "btn-outline-warning"
                      }`}
                      onClick={() => setSelectedFilter("premium")}
                    >
                      Premium Templates
                    </button>
                    <button
                      className={`btn btn-sm ${
                        selectedFilter === "popular"
                          ? "btn-info"
                          : "btn-outline-info"
                      }`}
                      onClick={() => setSelectedFilter("popular")}
                    >
                      Most Popular
                    </button>
                  </div>
                </div>

                {/* Reset Filters */}
                <button
                  className="btn btn-outline-secondary w-100"
                  onClick={() => {
                    setActiveTab("all");
                    setSelectedFilter("all");
                    setSearchQuery("");
                  }}
                >
                  Reset Filters
                </button>
              </div>
            </div>
          </div>

          {/* Templates Grid */}
          <div className="col-lg-9">
            <div className="d-flex justify-content-between align-items-center mb-4">
              <h5 className="mb-0">
                {getFilteredTemplates().length} Templates Found
              </h5>
              <div className="d-flex gap-2">
                <select
                  className="form-select form-select-sm"
                  style={{ width: "auto" }}
                >
                  <option>Sort by Popularity</option>
                  <option>Sort by Rating</option>
                  <option>Sort by Newest</option>
                  <option>Sort by Duration</option>
                </select>
              </div>
            </div>

            <div className="row">
              {getFilteredTemplates().map((template) => (
                <TemplateCard key={template.id} template={template} />
              ))}
            </div>

            {getFilteredTemplates().length === 0 && (
              <div className="text-center py-5">
                <Video size={64} className="text-muted mb-3" />
                <h5>No templates found</h5>
                <p className="text-muted">
                  Try adjusting your filters or search terms
                </p>
                <button
                  className="btn btn-primary"
                  onClick={() => {
                    setActiveTab("all");
                    setSelectedFilter("all");
                    setSearchQuery("");
                  }}
                >
                  Clear Filters
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Preview Modal */}
      <div
        className="modal fade"
        id="previewModal"
        tabIndex="-1"
        aria-labelledby="previewModalLabel"
        aria-hidden="true"
      >
        <div className="modal-dialog modal-lg">
          <div className="modal-content">
            <div className="modal-header">
              <h5 className="modal-title" id="previewModalLabel">
                {selectedTemplate?.name}
              </h5>
              <button
                type="button"
                className="btn-close"
                data-bs-dismiss="modal"
                aria-label="Close"
              />
            </div>
            <div className="modal-body">
              {selectedTemplate && (
                <div className="text-center">
                  <video
                    className="w-100 rounded"
                    style={{ maxHeight: "400px" }}
                    controls
                    poster={selectedTemplate.thumbnail}
                  >
                    <source src={selectedTemplate.videoUrl} type="video/mp4" />
                    Your browser does not support the video tag.
                  </video>
                  <div className="mt-3">
                    <h6>{selectedTemplate.name}</h6>
                    <p className="text-muted">
                      {selectedTemplate.theme} • {selectedTemplate.category}
                    </p>
                    <div className="d-flex justify-content-center gap-2">
                      <span className="badge bg-primary">
                        {selectedTemplate.price}
                      </span>
                      <span className="badge bg-secondary">
                        <Clock size={12} className="me-1" />
                        {selectedTemplate.duration}
                      </span>
                      <span className="badge bg-warning">
                        <Star size={12} className="me-1" />
                        {selectedTemplate.rating}
                      </span>
                    </div>
                  </div>
                </div>
              )}
            </div>
            <div className="modal-footer">
              <button
                type="button"
                className="btn btn-secondary"
                data-bs-dismiss="modal"
              >
                Close
              </button>
              <button
                type="button"
                className="btn btn-primary"
                onClick={() => {
                  if (selectedTemplate) {
                    handleEditTemplate(selectedTemplate);
                  }
                }}
                data-bs-dismiss="modal"
              >
                <Video className="me-1" size={16} />
                Edit This Template
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VideoTemplates;
