import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import usePhotography from "../../hooks/usePhotography";
import ShimmerMasonry from "../ui/ShimmerMasonry";
import { resolveMediaUrl } from "../../config/constants";

const MasonryImageSection = () => {
  const { fetchAllPhotos, allPhotos, loading } = usePhotography();
  const [weddingImages, setWeddingImages] = useState([]);
  const [isMobile, setIsMobile] = useState(false);
  useEffect(() => {
    const update = () => setIsMobile(window.innerWidth < 576);
    update();
    window.addEventListener("resize", update);
    return () => window.removeEventListener("resize", update);
  }, []);

  useEffect(() => {
    const loadPhotos = async () => {
      await fetchAllPhotos();
    };
    loadPhotos();
  }, []);

  useEffect(() => {
    if (allPhotos && allPhotos.length > 0) {
      const transformedImages = allPhotos
        .filter((photo) => photo.status === "active")
        .slice(0, 6)
        .map((photo, index) => {
          // Handles S3 URLs, relative /uploads/... paths and the legacy
          // happywedz.com origin alike.
          const imageUrl = resolveMediaUrl(photo.images?.[0]);

          const size = index % 2 === 0 ? "large" : "medium";

          return {
            id: photo.id,
            src: imageUrl,
            title: photo.title || "Wedding",
            size: size,
          };
        });

      setWeddingImages(transformedImages);
    }
  }, [allPhotos]);
  return (
    <div style={{ padding: "40px 20px" }}>
      <div className="container">
        <div className="text-center mb-1">
          <img loading="lazy" decoding="async"
            src="/images/home/weddinggalleryflower.png"
            alt="inspiredTeaser"
            className="w-20 h-20"
          />
          <h3 className="fw-bold mb-2 display-5 primary-text">
            Wedding Gallery
          </h3>
          <h5 className="mb-3" data-aos="fade-up" data-aos-delay="50">
            Get inspired by our collection of beautiful wedding moments
          </h5>
        </div>

        <div className="gallery-container">
          <Link
            to="/photography"
            className="see-more-link fs-14"
            aria-label="Explore All Wedding Photography Gallery"
          >
            Explore Gallery
            <svg
              width="14"
              height="14"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M5 12h14M12 5l7 7-7 7" />
            </svg>
          </Link>

          <div className="row">
            {weddingImages.length === 0 ? (
              <div>
                <ShimmerMasonry />
              </div>
            ) : (
              <>
                <div className="col-12 col-sm-6 col-xl-4">
                  {weddingImages[0] && (
                    <div
                      className={`gallery-item ${weddingImages[0].size}`}
                      style={isMobile ? { aspectRatio: "4 / 3" } : undefined}
                    >
                      <Link to={`/photography/details/${weddingImages[0].id}`}>
                        <img loading="lazy" decoding="async"
                          src={weddingImages[0].src}
                          alt={weddingImages[0].title}
                          style={
                            isMobile
                              ? {
                                  width: "100%",
                                  height: "100%",
                                  objectFit: "contain",
                                }
                              : undefined
                          }
                          onError={(e) => {
                            e.target.onerror = null;
                            e.target.src = "./images/noimage.jpeg";
                          }}
                        />
                        <div className="gallery-overlay">
                          <p className="gallery-title">
                            {weddingImages[0].title}
                          </p>
                        </div>
                      </Link>
                    </div>
                  )}

                  {weddingImages[3] && (
                    <div
                      className={`gallery-item ${weddingImages[3].size}`}
                      style={isMobile ? { aspectRatio: "4 / 3" } : undefined}
                    >
                      <Link to={`/photography/details/${weddingImages[3].id}`}>
                        <img loading="lazy" decoding="async"
                          src={weddingImages[3].src}
                          alt={weddingImages[3].title}
                          style={
                            isMobile
                              ? {
                                  width: "100%",
                                  height: "100%",
                                  objectFit: "contain",
                                }
                              : undefined
                          }
                          onError={(e) => {
                            e.target.onerror = null;
                            e.target.src = "./images/noimage.jpeg";
                          }}
                        />
                        <div className="gallery-overlay">
                          <p className="gallery-title">
                            {weddingImages[3].title}
                          </p>
                        </div>
                      </Link>
                    </div>
                  )}
                </div>

                <div className="col-12 col-md-6 col-lg-4">
                  {weddingImages[1] && (
                    <div
                      className={`gallery-item ${weddingImages[1].size}`}
                      style={isMobile ? { aspectRatio: "4 / 3" } : undefined}
                    >
                      <Link to={`/photography/details/${weddingImages[1].id}`}>
                        <img loading="lazy" decoding="async"
                          src={weddingImages[1].src}
                          alt={weddingImages[1].title}
                          style={
                            isMobile
                              ? {
                                  width: "100%",
                                  height: "100%",
                                  objectFit: "contain",
                                }
                              : undefined
                          }
                          onError={(e) => {
                            e.target.onerror = null;
                            e.target.src = "./images/noimage.jpeg";
                          }}
                        />
                        <div className="gallery-overlay">
                          <p className="gallery-title">
                            {weddingImages[1].title}
                          </p>
                        </div>
                      </Link>
                    </div>
                  )}

                  {weddingImages[4] && (
                    <div
                      className={`gallery-item ${weddingImages[4].size}`}
                      style={isMobile ? { aspectRatio: "4 / 3" } : undefined}
                    >
                      <Link to={`/photography/details/${weddingImages[4].id}`}>
                        <img loading="lazy" decoding="async"
                          src={weddingImages[4].src}
                          alt={weddingImages[4].title}
                          style={
                            isMobile
                              ? {
                                  width: "100%",
                                  height: "100%",
                                  objectFit: "contain",
                                }
                              : undefined
                          }
                          onError={(e) => {
                            e.target.onerror = null;
                            e.target.src = "./images/noimage.jpeg";
                          }}
                        />
                        <div className="gallery-overlay">
                          <p className="gallery-title">
                            {weddingImages[4].title}
                          </p>
                        </div>
                      </Link>
                    </div>
                  )}
                </div>

                <div className="col-12 col-md-6 col-lg-4">
                  {weddingImages[2] && (
                    <div
                      className={`gallery-item ${weddingImages[2].size}`}
                      style={isMobile ? { aspectRatio: "4 / 3" } : undefined}
                    >
                      <Link to={`/photography/details/${weddingImages[2].id}`}>
                        <img loading="lazy" decoding="async"
                          src={weddingImages[2].src}
                          alt={weddingImages[2].title}
                          style={
                            isMobile
                              ? {
                                  width: "100%",
                                  height: "100%",
                                  objectFit: "contain",
                                }
                              : undefined
                          }
                          onError={(e) => {
                            e.target.onerror = null;
                            e.target.src = "./images/noimage.jpeg";
                          }}
                        />
                        <div className="gallery-overlay">
                          <p className="gallery-title">
                            {weddingImages[2].title}
                          </p>
                        </div>
                      </Link>
                    </div>
                  )}

                  {weddingImages[5] && (
                    <div
                      className={`gallery-item ${weddingImages[5].size}`}
                      style={isMobile ? { aspectRatio: "4 / 3" } : undefined}
                    >
                      <Link to={`/photography/details/${weddingImages[5].id}`}>
                        <img loading="lazy" decoding="async"
                          src={weddingImages[5].src}
                          alt={weddingImages[5].title}
                          style={
                            isMobile
                              ? {
                                  width: "100%",
                                  height: "100%",
                                  objectFit: "contain",
                                }
                              : undefined
                          }
                          onError={(e) => {
                            e.target.onerror = null;
                            e.target.src = "./images/noimage.jpeg";
                          }}
                        />
                        <div className="gallery-overlay">
                          <p className="gallery-title">
                            {weddingImages[5].title}
                          </p>
                        </div>
                      </Link>
                    </div>
                  )}
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default MasonryImageSection;
