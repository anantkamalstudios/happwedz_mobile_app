import React, { useState, useEffect } from "react";
import {
  Heart,
  Play,
  Calendar,
  Star,
  Filter,
  Search,
  Video,
  Sparkles,
} from "lucide-react";
import axios from "axios";
import { useNavigate } from "react-router-dom";

const WeddingCardDesigns = () => {
  const [activeTab, setActiveTab] = useState("wedding");
  const [selectedFilter, setSelectedFilter] = useState("all");
  const [selectedTemplate, setSelectedTemplate] = useState(null);
  const navigate = useNavigate();
  const [allCards, setAllCards] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchEInvites = async () => {
      setLoading(true);
      setError(null);
      try {
        const response = await axios.get("https://happywedz.com/api/einvites");
        if (response.data && Array.isArray(response.data)) {
          setAllCards(response.data);
        } else {
          setAllCards([]);
        }
      } catch (err) {
        setError("Failed to load e-invites. Please try again later.");
        console.error("Error fetching e-invites:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchEInvites();
  }, []);

  const weddingCards = allCards.filter(
    (card) => card.card_type === "Wedding E-Invitations"
  );
  const videoCards = allCards.filter(
    (card) => card.card_type === "Video Invitations"
  );
  const saveTheDateCards = allCards.filter(
    (card) => card.card_type === "Save The Date"
  );

  const getCurrentData = () => {
    switch (activeTab) {
      case "wedding":
        return weddingCards;
      case "video":
        return videoCards;
      case "savedate":
        return saveTheDateCards;
      default:
        return weddingCards;
    }
  };

  const getFilteredData = () => {
    const data = getCurrentData();
    if (selectedFilter === "all") return data;
    return data.filter(
      (item) =>
        item.theme === selectedFilter ||
        item.culture === selectedFilter ||
        item.style === selectedFilter
    );
  };

  const handleEditTemplate = (template) => {
    if (activeTab === "video") {
      // For video cards, navigate to the video editor
      const videoTemplate = {
        ...template,
        videoUrl:
          "https://videoinvites.wedmegood.com/1756195582718Floral+Extravaganza.mp4",
        thumbnail: template.image,
        category: template.theme,
        features: ["Text Overlay", "Music Sync", "Transitions"],
        colors: ["#FF6B9D", "#FFE4E1", "#FFFFFF"],
        price: "Free",
      };
      navigate("/video-editor", { state: { template: videoTemplate } });
    } else {
      const editorUrl = `/editor?template=${encodeURIComponent(
        JSON.stringify(template)
      )}`;
      navigate(editorUrl);
    }
  };

  const CardComponent = ({ item, type }) => (
    <div className="wc-card-container group">
      <div className="wc-card-image-wrapper">
        <img
          src={item.thumbnail_url}
          alt={item.name}
          className="wc-card-image"
        />
        <div className="wc-card-overlay">
          <div className="wc-card-overlay-content">
            {type === "video" && (
              <div className="wc-play-button">
                <Play className="w-8 h-8 text-white fill-current" />
              </div>
            )}
            <button
              className="wc-customize-btn"
              onClick={() => handleEditTemplate(item)}
            >
              Customize Now
            </button>
          </div>
        </div>
        <div className="wc-card-heart">
          <Heart className="w-5 h-5 text-pink-500 hover:fill-current cursor-pointer transition-all" />
        </div>
      </div>
      <div className="wc-card-info">
        <h3 className="wc-card-title">{item.name}</h3>
        <div className="wc-card-meta">
          <div className="wc-rating">
            <Star className="w-4 h-4 text-yellow-400 fill-current" />
            <span className="text-sm text-gray-600">{item.rating || 4.5}</span>
          </div>
          {type === "video" && (
            <span className="wc-duration">{item.duration}</span>
          )}
        </div>
      </div>
    </div>
  );

  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center vh-100">
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  if (error) return <div className="alert alert-danger">{error}</div>;

  return (
    <div className="min-vh-100" style={{ backgroundColor: "#f8f9fa" }}>
      {/* Navigation Tabs */}
      <div className="bg-white shadow-sm rounded-pill my-3">
        <div className="container">
          <ul className="nav nav-pills nav-fill py-2">
            {/* Wedding Cards */}
            <li className="nav-item px-2">
              <button
                className={`nav-link fw-semibold rounded-pill ${
                  activeTab === "wedding" ? "active" : ""
                }`}
                onClick={() => setActiveTab("wedding")}
                style={{
                  background:
                    activeTab === "wedding"
                      ? "var(--primary-color)"
                      : "#f8f9fa",
                  color: activeTab === "wedding" ? "#fff" : "#6c757d",
                  border: "1px solid #dee2e6",
                  transition: "all 0.3s ease",
                }}
              >
                Wedding Cards{" "}
                <span
                  className="badge ms-2"
                  style={{
                    background: activeTab === "wedding" ? "#fff" : "#e9ecef",
                    color:
                      activeTab === "wedding"
                        ? "var(--primary-color)"
                        : "#6c757d",
                  }}
                >
                  {weddingCards.length}
                </span>
              </button>
            </li>

            {/* Video Cards */}
            <li className="nav-item px-2">
              <button
                className={`nav-link fw-semibold rounded-pill ${
                  activeTab === "video" ? "active" : ""
                }`}
                onClick={() => setActiveTab("video")}
                style={{
                  background:
                    activeTab === "video" ? "var(--primary-color)" : "#f8f9fa",
                  color: activeTab === "video" ? "#fff" : "#6c757d",
                  border: "1px solid #dee2e6",
                  transition: "all 0.3s ease",
                }}
              >
                Video Cards{" "}
                <span
                  className="badge ms-2"
                  style={{
                    background: activeTab === "video" ? "#fff" : "#e9ecef",
                    color:
                      activeTab === "video"
                        ? "var(--primary-color)"
                        : "#6c757d",
                  }}
                >
                  {videoCards.length}
                </span>
              </button>
            </li>

            {/* Save the Date */}
            <li className="nav-item px-2">
              <button
                className={`nav-link fw-semibold rounded-pill ${
                  activeTab === "savedate" ? "active" : ""
                }`}
                onClick={() => setActiveTab("savedate")}
                style={{
                  background:
                    activeTab === "savedate"
                      ? "var(--primary-color)"
                      : "#f8f9fa",
                  color: activeTab === "savedate" ? "#fff" : "#6c757d",
                  border: "1px solid #dee2e6",
                  transition: "all 0.3s ease",
                }}
              >
                Save the Date{" "}
                <span
                  className="badge ms-2"
                  style={{
                    background: activeTab === "savedate" ? "#fff" : "#e9ecef",
                    color:
                      activeTab === "savedate"
                        ? "var(--primary-color)"
                        : "#6c757d",
                  }}
                >
                  {saveTheDateCards.length}
                </span>
              </button>
            </li>
          </ul>
        </div>
      </div>

      {/* Filters and Search */}
      <div className="bg-light py-3">
        <div className="container">
          <div className="row g-3 align-items-center">
            {/* Search Box */}
            <div className="col-md-6">
              <div className="input-group">
                <span
                  className="input-group-text bg-white border-1 rounded-0"
                  style={{ boxShadow: "none" }}
                >
                  <Search size={16} />
                </span>
                <input
                  type="text"
                  className="form-control border-1 rounded-0 shadow-none"
                  placeholder="Search designs..."
                  style={{
                    padding: "1rem",
                    boxShadow: "none",
                    outline: "none",
                  }}
                />
              </div>
            </div>

            {/* Filter Dropdown */}
            <div className="col-md-6">
              <div className="input-group">
                <span
                  className="input-group-text bg-white border-1 rounded-0"
                  style={{ boxShadow: "none" }}
                >
                  <Filter size={16} />
                </span>
                <select
                  className="form-select border-1 rounded-0 shadow-none"
                  value={selectedFilter}
                  onChange={(e) => setSelectedFilter(e.target.value)}
                  style={{
                    padding: "1rem",
                    boxShadow: "none",
                  }}
                >
                  <option value="all">All Themes</option>
                  <option value="traditional">Traditional</option>
                  <option value="modern">Modern</option>
                  <option value="floral">Floral</option>
                  <option value="romantic">Romantic</option>
                  <option value="vintage">Vintage</option>
                  <option value="elegant">Elegant</option>
                </select>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Cards Grid */}
      <main className="py-5">
        <div className="container">
          <div className="text-center mb-5">
            <h2 className="h3">
              {activeTab === "wedding" && "Wedding Card Designs"}
              {activeTab === "video" && "Video Invitation Templates"}
              {activeTab === "savedate" && "Save the Date Templates"}
            </h2>
            <p className="text-muted">
              Choose from our beautiful collection of {activeTab} templates
            </p>
          </div>

          <div className="row g-4">
            {getFilteredData().map((item) => (
              <div key={item.id} className="col-lg-4 col-md-6">
                <CardComponent item={item} type={activeTab} />
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
};

export default WeddingCardDesigns;
