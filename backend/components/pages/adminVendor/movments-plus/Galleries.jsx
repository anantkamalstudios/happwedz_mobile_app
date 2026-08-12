import React, { useState, useEffect } from "react";
import axiosInstance from "../../../../services/api/axiosInstance";
import {
  FiImage,
  FiVideo,
  FiSearch,
  FiDownload,
  FiEye,
  FiEyeOff,
  FiX,
  FiChevronLeft,
  FiChevronRight,
  FiFolder,
  FiArrowLeft,
} from "react-icons/fi";
import { toast } from "react-toastify";
import "./gallery.css";

const Galleries = () => {
  const [events, setEvents] = useState([]);
  const [selectedEvent, setSelectedEvent] = useState(null);
  const [selectedCollection, setSelectedCollection] = useState(null);
  const [mediaItems, setMediaItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);

  useEffect(() => {
    fetchEvents();
  }, []);

  useEffect(() => {
    if (selectedEvent) {
      fetchMedia(selectedEvent.id);
      setSelectedCollection(null); // Reset collection when event changes
    } else {
      setMediaItems([]);
    }
  }, [selectedEvent]);

  const fetchEvents = async () => {
    try {
      const response = await axiosInstance.get("/events");
      if (response.data.success) {
        setEvents(response.data.events);
      }
    } catch (error) {
      console.error("Error fetching events:", error);
      toast.error("Failed to load events");
    }
  };

  const fetchMedia = async (eventId) => {
    try {
      setLoading(true);
      const response = await axiosInstance.get(`/media?event_id=${eventId}`);
      if (response.data.success) {
        setMediaItems(response.data.media);
      }
    } catch (err) {
      console.error("Error fetching media:", err);
      toast.error("Failed to fetch media galleries");
    } finally {
      setLoading(false);
    }
  };

  const getS3Url = (s3Key) => {
    return `https://happywedz-s3-bucket.s3.ap-south-1.amazonaws.com/${s3Key}`;
  };

  const handleDownload = async (s3Key, collection, e) => {
    if (e) e.stopPropagation();
    try {
      const url = getS3Url(s3Key);
      const response = await fetch(url);
      const blob = await response.blob();
      const downloadUrl = window.URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = downloadUrl;
      link.download = `${collection}_${Date.now()}.${s3Key.split(".").pop()}`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(downloadUrl);
      toast.success("Download started");
    } catch (err) {
      toast.error("Failed to download file");
    }
  };

  const openLightbox = (index) => {
    setCurrentImageIndex(index);
    setLightboxOpen(true);
    document.body.style.overflow = "hidden";
  };

  const closeLightbox = () => {
    setLightboxOpen(false);
    document.body.style.overflow = "auto";
  };

  // Group media by collection
  const groupedMedia = mediaItems.reduce((acc, item) => {
    const col = item.collection || "Uncategorized";
    if (!acc[col]) acc[col] = [];
    acc[col].push(item);
    return acc;
  }, {});

  // Get current view media
  const currentViewMedia = selectedCollection
    ? groupedMedia[selectedCollection] || []
    : [];

  // Filter media in the current view (collection view)
  const filteredMedia = currentViewMedia.filter((item) =>
    item.token.toLowerCase().includes(searchTerm.toLowerCase()),
  );

  // Filter collections in the folders view
  const filteredCollections = Object.keys(groupedMedia).filter((col) =>
    col.toLowerCase().includes(searchTerm.toLowerCase()),
  );

  const goToNext = () => {
    setCurrentImageIndex((prev) => (prev + 1) % filteredMedia.length);
  };

  const goToPrevious = () => {
    setCurrentImageIndex(
      (prev) => (prev - 1 + filteredMedia.length) % filteredMedia.length,
    );
  };

  const formatFileSize = (mb) => {
    return `${parseFloat(mb).toFixed(2)} MB`;
  };

  useEffect(() => {
    const handleKeyDown = (e) => {
      if (!lightboxOpen) return;
      if (e.key === "Escape") closeLightbox();
      if (e.key === "ArrowRight") goToNext();
      if (e.key === "ArrowLeft") goToPrevious();
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [lightboxOpen]);

  const currentMedia = filteredMedia[currentImageIndex];

  return (
    <div className="gallery-container">
      <div className="gallery-header">
        <div className="">
          <h3 className="gallery-title inter">Galleries</h3>
          <p className="gallery-subtitle inter">
            Manage your event collections
          </p>
        </div>

        {/* Event Selector */}
        <div className="d-flex align-items-center gap-3 inter">
          <select
            className="form-select inter"
            style={{ width: "250px" }}
            value={selectedEvent?.id || ""}
            onChange={(e) => {
              const evt = events.find(
                (ev) => ev.id.toString() === e.target.value,
              );
              setSelectedEvent(evt || null);
            }}
          >
            <option value="" className="inter">
              Select Event
            </option>
            {events.map((evt) => (
              <option key={evt.id} value={evt.id} className="inter">
                {evt.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Breadcrumb / Navigation */}
      {selectedEvent && (
        <div className="d-flex align-items-center gap-2 py-3 border-bottom mb-3 inter">
          <span
            className={`cursor-pointer inter ${!selectedCollection ? "fw-bold primary-text" : "text-muted"}`}
            onClick={() => setSelectedCollection(null)}
            style={{ cursor: "pointer" }}
          >
            Collections
          </span>
          {selectedCollection && (
            <>
              <span className="text-muted">/</span>
              <span className="fw-bold primary-text">{selectedCollection}</span>
            </>
          )}
        </div>
      )}

      {/* Search Bar */}
      {selectedEvent && (
        <div className="gallery-search mb-4">
          <FiSearch className="search-icon" />
          <input
            type="text"
            placeholder={
              selectedCollection ? "Search media..." : "Search collections..."
            }
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      )}

      {/* Content Area */}
      {loading ? (
        <div className="gallery-loader">
          <div className="spinner"></div>
        </div>
      ) : !selectedEvent ? (
        <div className="empty-state">
          <FiFolder size={64} />
          <h3>Select an Event</h3>
          <p>Please select an event to view its galleries</p>
        </div>
      ) : !selectedCollection ? (
        /* Collections View (Folders) */
        <div className="main-gallery-grid">
          {filteredCollections.length > 0 ? (
            filteredCollections.map((colName) => (
              <div
                key={colName}
                className="gallery-card folder-card"
                onClick={() => {
                  setSelectedCollection(colName);
                  setSearchTerm("");
                }}
              >
                <div className="folder-icon-wrapper">
                  <img src="/images/movments-plus/folder.png" alt="Folder" />
                </div>
                <div className="folder-info">
                  <p className="folder-name text-uppercase fw-bold fs-16 inter">
                    {colName}
                  </p>
                  <p className="gallery-folder-count fs-14 inter">
                    {groupedMedia[colName].length} items
                  </p>
                </div>
              </div>
            ))
          ) : (
            <div className="col-12 text-center py-5 inter">
              <p className="text-muted">No collections found for this event</p>
            </div>
          )}
        </div>
      ) : (
        /* Media View (Images) */
        <>
          {filteredMedia.length > 0 ? (
            <div className="gallery-grid inter">
              {filteredMedia.map((item, index) => (
                <div key={item.id} className="gallery-card">
                  <div
                    className="card-image"
                    onClick={() =>
                      item.s3_key.match(/\.(jpg|jpeg|png|gif|webp)$/i) &&
                      openLightbox(index)
                    }
                    style={{
                      cursor: item.s3_key.match(/\.(jpg|jpeg|png|gif|webp)$/i)
                        ? "pointer"
                        : "default",
                    }}
                  >
                    {item.s3_key.match(/\.(jpg|jpeg|png|gif|webp)$/i) ? (
                      <img
                        src={getS3Url(item.s3_key)}
                        alt={item.collection}
                        onError={(e) => {
                          e.target.src =
                            "https://via.placeholder.com/400x300?text=Image+Error";
                        }}
                      />
                    ) : (
                      <div className="video-placeholder">
                        <FiVideo size={40} />
                        <span>Video File</span>
                      </div>
                    )}
                    <div className="card-badges">
                      <div className="card-badge">
                        {item.visibility === "public" ? (
                          <FiEye size={12} />
                        ) : (
                          <FiEyeOff size={12} />
                        )}
                        <span>{item.visibility}</span>
                      </div>
                      <button
                        className="card-download-btn"
                        onClick={(e) =>
                          handleDownload(item.s3_key, item.collection, e)
                        }
                        title="Download"
                      >
                        <FiDownload size={14} />
                      </button>
                    </div>
                  </div>

                  <div className="card-content">
                    <h3 className="card-title">{item.collection}</h3>
                    <p className="card-price">
                      {formatFileSize(item.file_size_mb)}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="empty-state">
              <FiImage size={64} />
              <h3>No Media Found</h3>
              <p>No media files match your search criteria</p>
            </div>
          )}
        </>
      )}

      {/* Lightbox Modal */}
      {lightboxOpen && currentMedia && (
        <div className="lightbox-overlay" onClick={closeLightbox}>
          <button className="lightbox-close" onClick={closeLightbox}>
            <FiX size={24} />
          </button>

          <button
            className="lightbox-nav lightbox-prev"
            onClick={(e) => {
              e.stopPropagation();
              goToPrevious();
            }}
          >
            <FiChevronLeft size={32} />
          </button>

          <button
            className="lightbox-nav lightbox-next"
            onClick={(e) => {
              e.stopPropagation();
              goToNext();
            }}
          >
            <FiChevronRight size={32} />
          </button>

          <div
            className="lightbox-content"
            onClick={(e) => e.stopPropagation()}
          >
            <img
              src={getS3Url(currentMedia.s3_key)}
              alt={currentMedia.collection}
              className="lightbox-image"
            />
            <div className="lightbox-info">
              <div className="lightbox-details">
                <h3>{currentMedia.collection}</h3>
                <p>{formatFileSize(currentMedia.file_size_mb)}</p>
              </div>
              <button
                className="lightbox-download-btn"
                onClick={() =>
                  handleDownload(currentMedia.s3_key, currentMedia.collection)
                }
              >
                <FiDownload size={16} />
                Download
              </button>
            </div>
          </div>

          <div className="lightbox-counter">
            {currentImageIndex + 1} / {filteredMedia.length}
          </div>
        </div>
      )}
    </div>
  );
};

export default Galleries;
