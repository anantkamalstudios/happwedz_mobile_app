import React, { useState, useEffect } from "react";
import axios from "axios";
import { FaMapMarkerAlt } from "react-icons/fa";
import RealWeddingDetails from "../layouts/realWedding/RealWeddingDetails";

export default function RealWeddingsStatic() {
  const [weddings, setWeddings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [currentView, setCurrentView] = useState("list");
  const [selectedPost, setSelectedPost] = useState(null);

  const handlePostClick = (post) => {
    setSelectedPost(post);
    setCurrentView("detail");
  };

  const handleBackClick = () => {
    setCurrentView("list");
    setSelectedPost(null);
  };

  useEffect(() => {
    const parseJSON = (value, fallback = []) => {
      if (!value) return fallback;
      if (Array.isArray(value)) return value;
      try {
        const parsed = JSON.parse(value);
        return Array.isArray(parsed) ? parsed : fallback;
      } catch (err) {
        return fallback;
      }
    };

    const normalizeWedding = (wedding) => ({
      id: wedding.id,
      title: wedding.title,
      slug: wedding.slug,
      city: wedding.city || "",
      culture: (() => {
        const cultures = parseJSON(
          wedding.cultures ?? wedding.culture,
          wedding.cultures && typeof wedding.cultures === "string"
            ? wedding.cultures.split(",")
            : []
        );
        if (Array.isArray(cultures) && cultures.length > 0) {
          return cultures[0];
        }
        return typeof wedding.culture === "string" ? wedding.culture : "";
      })(),
      themes: parseJSON(wedding.themes, []),
      brideName: wedding.bride_name || wedding.brideName || "",
      brideBio: wedding.bride_bio || wedding.brideBio || "",
      groomName: wedding.groom_name || wedding.groomName || "",
      groomBio: wedding.groom_bio || wedding.groomBio || "",
      weddingDate: wedding.wedding_date || wedding.weddingDate || "",
      story: wedding.story || "",
      coverPhoto: wedding.cover_photo || wedding.coverPhoto || "",
      highlightPhotos: parseJSON(
        wedding.highlight_photos || wedding.highlightPhotos,
        []
      ),
      allPhotos: parseJSON(wedding.all_photos || wedding.allPhotos, []),
      events: parseJSON(wedding.events, []),
      vendors: parseJSON(wedding.vendors, []),
      specialMoments: wedding.special_moments || wedding.specialMoments || "",
      brideOutfit: wedding.bride_outfit || wedding.brideOutfit || "",
      groomOutfit: wedding.groom_outfit || wedding.groomOutfit || "",
      photographer: wedding.photographer || "",
      makeup: wedding.makeup || "",
      decor: wedding.decor || "",
      status: wedding.status,
    });

    const fetchWeddings = async () => {
      try {
        setLoading(true);
        const response = await axios.get(
          "https://happywedz.com/api/realwedding/public/"
        );

        const dataArray = response.data.weddings || response.data;

        if (Array.isArray(dataArray)) {
          const normalized = dataArray.map(normalizeWedding);
          // Filter only published weddings and limit to 6 for display
          const publishedWeddings = normalized
            .filter((wedding) => wedding.status === "published")
            .slice(0, 6);
          setWeddings(publishedWeddings);
        } else {
          setWeddings([]);
        }
        setError(null);
      } catch (err) {
        setError("Failed to fetch wedding stories. Please try again later.");
        console.error("Error fetching weddings:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchWeddings();
  }, []);

  if (currentView === "detail") {
    return (
      <RealWeddingDetails post={selectedPost} onBackClick={handleBackClick} />
    );
  }

  return (
    <div className="real-weddings">
      <section className="gallery-section py-5">
        <div className="container">
          <div className="d-flex justify-content-center align-items-center m-2">
            <h1 className="mb-4" style={{ color: "#e91e63" }}>
              Real People: Real Stories
            </h1>
          </div>

          {loading ? (
            <div className="row justify-content-center">
              <div className="col-12 text-center py-5">
                <div
                  className="spinner-border text-pink mb-3"
                  role="status"
                ></div>
                <p className="text-secondary fs-5">
                  Fetching beautiful weddings...
                </p>
              </div>
            </div>
          ) : error ? (
            <div className="row justify-content-center">
              <div className="col-12 text-center py-5">
                <p className="text-danger">{error}</p>
              </div>
            </div>
          ) : weddings.length === 0 ? (
            <div className="row justify-content-center">
              <div className="col-12 text-center py-5">
                <p className="text-muted">No weddings found.</p>
              </div>
            </div>
          ) : (
            <div className="row justify-content-center">
              {weddings.map((wedding) => (
                <div key={wedding.id} className="col-lg-4 col-md-6 mb-4">
                  <div
                    className="wedding-card h-100 shadow-sm rounded-3 overflow-hidden"
                    style={{ cursor: "pointer" }}
                    // onClick={() => handlePostClick(wedding)}
                  >
                    <div className="position-relative">
                      <img
                        src={
                          wedding.coverPhoto ||
                          "https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=400&h=300&fit=crop"
                        }
                        alt={wedding.title}
                        style={{
                          width: "100%",
                          height: "400px",
                          objectFit: "cover",
                        }}
                        onError={(e) => {
                          e.target.src =
                            "https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=400&h=300&fit=crop";
                        }}
                      />
                      <div
                        className="position-absolute bottom-0 end-0 text-white p-5"
                        style={{ background: "rgba(195, 17, 98, 0.7)" }}
                      >
                        {wedding.highlightPhotos?.length || 0} Photos
                      </div>
                    </div>

                    <div className="pt-2 text-center d-flex gap-2 justify-content-center text-center">
                      <h3 className="fw-bold mb-0 fs-22">
                        {wedding.brideName || "Bride"}
                      </h3>
                      <h3 className="fw-bold mb-0 fs-22">&</h3>
                      <h3 className="fw-bold mb-0 fs-22">
                        {wedding.groomName || "Groom"}
                      </h3>
                    </div>
                    <div className="py-2 text-center d-flex gap-2 justify-content-center text-center">
                      <h3 className="mt-0 primary-text">
                        <FaMapMarkerAlt className="me-1" />
                        {wedding.city || "City"}
                      </h3>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </section>
    </div>
  );
}
