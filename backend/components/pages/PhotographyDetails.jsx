import React, { useState, useEffect, useMemo } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import {
  FaHeart,
  FaMapMarkerAlt,
  FaTag,
  FaUser,
  FaShareAlt,
  FaTimes,
  FaChevronLeft,
  FaChevronRight,
} from "react-icons/fa";
import { IMAGE_BASE_URL } from "../../config/constants";
import usePhotography from "../../hooks/usePhotography";
import LoadingState from "../LoadingState";
import ErrorState from "../ErrorState";
import SEO from "../common/SEO";
import { GoHeart } from "react-icons/go";

const toTitleCase = (str) =>
  (str || "")
    .toString()
    .replace(/-/g, " ")
    .replace(/\b\w/g, (l) => l.toUpperCase());

const toSlug = (str) =>
  (str || "")
    .toLowerCase()
    .replace(/\s+/g, "-")
    .replace(/[^a-z0-9\-]/g, "");

const PhotographyDetails = () => {
  const { id: routeId, subcategory, city, slug } = useParams();
  const id = useMemo(() => {
    if (routeId && !isNaN(routeId)) return routeId;
    if (slug) {
      const parts = slug.split("-");
      const lastPart = parts[parts.length - 1];
      if (lastPart && !isNaN(lastPart)) return lastPart;
    }
    return routeId;
  }, [routeId, slug]);
  const navigate = useNavigate();
  const [selectedImageIndex, setSelectedImageIndex] = useState(0);
  const [isLightboxOpen, setIsLightboxOpen] = useState(false);
  const [isLiked, setIsLiked] = useState(false);
  const [vw, setVw] = useState(
    typeof window !== "undefined" ? window.innerWidth : 1024
  );

  const {
    photo,
    photosByCategory,
    loading,
    error,
    fetchPhotoById,
    fetchPhotosByCategory,
    typesWithCategories,
    fetchTypesWithCategories
  } = usePhotography();

  useEffect(() => {
    fetchTypesWithCategories();
  }, []);

  useEffect(() => {
    if (id) {
      fetchPhotoById(id);
    }
  }, [id]);

  useEffect(() => {
    if (photo && photo.photography_category_id) {
      fetchPhotosByCategory(photo.photography_category_id);
    }
  }, [photo?.photography_category_id]);

  useEffect(() => {
    const onResize = () =>
      setVw(typeof window !== "undefined" ? window.innerWidth : 1024);
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);

  const normalizeImageUrl = (url) => {
    if (!url) return "./images/noimage.jpeg";
    if (url.startsWith("http")) {
      return url.replace("http://happywedz.com/", IMAGE_BASE_URL);
    }
    return IMAGE_BASE_URL + url.replace(/^\/+/, "");
  };

  const getFallbackImageUrl = (url) => {
    if (!url) return null;
    if (url.includes("/uploads/photography/")) {
      return url.replace("/uploads/photography/", "/uploads/blogs/");
    }
    return null;
  };

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: photo?.title || "Photography",
          text: photo?.description || "Check out this amazing photography!",
          url: window.location.href,
        });
      } catch (err) {}
    } else {
      navigator.clipboard.writeText(window.location.href);
      alert("Link copied to clipboard!");
    }
  };

  const handleLike = () => {
    setIsLiked(!isLiked);
  };

  if (loading && !photo) {
    return <LoadingState title="Loading Photography Details" />;
  }

  if (error) {
    return <ErrorState error={error} />;
  }

  if (!photo) {
    return (
      <div style={{ padding: "40px 0", textAlign: "center" }}>
        <h3>Photography not found</h3>
        <button
          style={{
            marginTop: "20px",
            padding: "10px 24px",
            background: "#e91e63",
            color: "white",
            border: "none",
            borderRadius: "4px",
            cursor: "pointer",
          }}
          onClick={() => navigate(-1)}
        >
          Go Back
        </button>
      </div>
    );
  }

  const getCategoryName = (catId) => {
    for (const t of typesWithCategories || []) {
      if (Array.isArray(t.categories)) {
        const found = t.categories.find((c) => c.id === catId);
        if (found) return found.name;
      }
    }
    return "";
  };
  const resolvedCategory = photo ? (photo.category_name || photo.type_name || photo.type || getCategoryName(photo.photography_category_id) || "") : "";
  const showTitleCrumb = photo && photo.title && resolvedCategory && photo.title.toLowerCase() !== resolvedCategory.toLowerCase() && photo.title.toLowerCase() !== "wedding photo" && photo.title.toLowerCase() !== "photo" && photo.title.toLowerCase() !== "groom wear";

  const images = photo.images || [];
  const thumbnails = photo.thumbnails || images;
  const similarPhotos =
    photosByCategory?.filter((p) => p.id !== photo.id) || [];

  const seoTitle = photo ? `${photo.title || resolvedCategory || "Wedding Photo"} in ${toTitleCase(city || photo.city_name || "India")} - HappyWedz` : "HappyWedz";
  const seoDesc = photo ? (photo.description || `View ${photo.title || resolvedCategory || "Wedding Photo"} tags and details from ${toTitleCase(city || photo.city_name || "India")} on HappyWedz.`) : "";

  return (
    <>
      <SEO title={seoTitle} description={seoDesc} />
      <div style={{ backgroundColor: "#fff", width: "100%" }}>
        <div
          style={{ maxWidth: "1200px", margin: "0 auto", padding: "24px 16px" }}
        >
          <nav style={{ marginBottom: "24px" }}>
            <ol
              style={{
                display: "flex",
                listStyle: "none",
                padding: 0,
                margin: 0,
                gap: "8px",
              }}
            >
              <li>
                <Link to="/" style={{ textDecoration: "none", color: "#666" }}>
                  Home
                </Link>
              </li>
              <li style={{ color: "#999" }}>/</li>
              <li>
                <Link
                  to="/photography"
                  style={{ textDecoration: "none", color: "#666" }}
                >
                  Photography
                </Link>
              </li>
              {resolvedCategory && (
                <>
                  <li style={{ color: "#999" }}>/</li>
                  <li>
                    <Link
                      to={`/photography/${toSlug(resolvedCategory)}/all`}
                      style={{ textDecoration: "none", color: "#666", textTransform: "capitalize" }}
                    >
                      {resolvedCategory}
                    </Link>
                  </li>
                </>
              )}
              {city && city !== "all" && (
                <>
                  <li style={{ color: "#999" }}>/</li>
                  <li>
                    {showTitleCrumb ? (
                      <Link
                        to={`/photography/${toSlug(resolvedCategory) || "all"}/${city}`}
                        style={{ textDecoration: "none", color: "#666", textTransform: "capitalize" }}
                      >
                        {city.replace(/-/g, " ")}
                      </Link>
                    ) : (
                      <span style={{ color: "#333", textTransform: "capitalize" }}>
                        {city.replace(/-/g, " ")}
                      </span>
                    )}
                  </li>
                </>
              )}
              {showTitleCrumb && (
                <>
                  <li style={{ color: "#999" }}>/</li>
                  <li style={{ color: "#333" }}>{photo.title}</li>
                </>
              )}
            </ol>
          </nav>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: vw <= 992 ? "1fr" : "1fr 1fr",
              gap: vw <= 576 ? "16px" : "32px",
            }}
          >
            <div>
              <div
                style={{
                  background: "rgba(251, 113, 147, 0.4)",
                  boxShadow: "0 2px 8px rgba(0, 0, 0, 0.08)",
                  padding: "16px",
                  borderRadius: "4px",
                  marginBottom: "24px",
                }}
              >
                <div
                  style={{
                    width: "100%",
                    height: vw <= 576 ? "320px" : vw <= 992 ? "420px" : "500px",
                    overflow: "hidden",
                    borderRadius: "4px",
                    marginBottom: "16px",
                  }}
                >
                  <img
                    src={normalizeImageUrl(
                      images[selectedImageIndex] || thumbnails[0]
                    )}
                    alt={photo.title}
                    style={{
                      width: "100%",
                      height: "100%",
                      objectFit: "contain",
                      display: "block",
                      cursor: "zoom-in",
                    }}
                    onClick={() => setIsLightboxOpen(true)}
                    onError={(e) => {
                      const fallbackUrl = getFallbackImageUrl(e.target.src);
                      if (fallbackUrl && e.target.src !== fallbackUrl) {
                        e.target.src = fallbackUrl;
                      } else {
                        e.target.onerror = null;
                        e.target.src = "./images/noimage.jpeg";
                      }
                    }}
                  />
                </div>

                {/* Thumbnails Row INSIDE SAME BOX */}
                {images.length > 1 && (
                  <div
                    style={{
                      display: "flex",
                      gap: "12px",
                      flexWrap: "wrap",
                      justifyContent: "start",
                    }}
                  >
                    {images.slice(0, 4).map((img, index) => (
                      <div
                        key={index}
                        style={{
                          width: vw <= 576 ? "72px" : "95px",
                          height: vw <= 576 ? "72px" : "95px",
                          borderRadius: "4px",
                          overflow: "hidden",
                          cursor: "pointer",
                          border:
                            selectedImageIndex === index
                              ? "3px solid #e91e63"
                              : "3px solid transparent",
                          transition: "all 0.3s ease",
                        }}
                        onClick={() => setSelectedImageIndex(index)}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.transform = "translateY(-2px)";
                          e.currentTarget.style.boxShadow =
                            "0 4px 12px rgba(0, 0, 0, 0.15)";
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.transform = "translateY(0)";
                          e.currentTarget.style.boxShadow = "none";
                        }}
                      >
                        <img
                          src={normalizeImageUrl(img)}
                          alt={`Thumbnail ${index + 1}`}
                          style={{
                            width: "100%",
                            height: "100%",
                            objectFit: "cover",
                          }}
                          onError={(e) => {
                            const fallbackUrl = getFallbackImageUrl(
                              e.target.src
                            );
                            if (fallbackUrl && e.target.src !== fallbackUrl) {
                              e.target.src = fallbackUrl;
                            } else {
                              e.target.onerror = null;
                              e.target.src = "./images/noimage.jpeg";
                            }
                          }}
                        />
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Right Column - Details */}
            <div>
              {/* Upload Date Badge with Close Button */}
              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  marginBottom: "16px",
                  flexWrap: "wrap",
                  rowGap: "12px",
                }}
              >
                {photo.createdAt && (
                  <div
                    style={{
                      display: "inline-flex",
                      alignItems: "center",
                      gap: "8px",
                      padding: "8px 16px",
                      background: "#fff",
                      border: "none",
                      fontSize: "13px",
                      color: "#e91e63",
                      fontWeight: "500",
                    }}
                  >
                    <svg
                      width="16"
                      height="16"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                    >
                      <circle cx="12" cy="12" r="10" />
                      <polyline points="12 6 12 12 16 14" />
                    </svg>
                    <span>
                      Uploaded{" "}
                      {new Date(photo.createdAt).toLocaleDateString("en-US", {
                        month: "short",
                        day: "numeric",
                        year: "numeric",
                      })}
                    </span>
                  </div>
                )}
                <button
                  onClick={() => navigate(-1)}
                  style={{
                    background: "none",
                    border: "none",
                    color: "#e91e63",
                    cursor: "pointer",
                    padding: "8px",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    fontSize: "20px",
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.opacity = "0.7")}
                  onMouseLeave={(e) => (e.currentTarget.style.opacity = "1")}
                >
                  <FaTimes size={20} />
                </button>
              </div>

              <h2
                style={{
                  fontSize: vw <= 576 ? "20px" : "24px",
                  fontWeight: "600",
                  color: "#000",
                  margin: "0 0 24px 0",
                }}
              >
                {photo.title}
              </h2>

              {/* Picture Tags */}
              {photo.tags && photo.tags.length > 0 && (
                <div style={{ marginBottom: "32px" }}>
                  <h6
                    style={{
                      fontSize: "14px",
                      fontWeight: "600",
                      color: "#000",
                      marginBottom: "12px",
                    }}
                  >
                    Picture Tags
                  </h6>
                  <div
                    style={{ display: "flex", flexWrap: "wrap", gap: "8px" }}
                  >
                    {photo.tags.map((tag, index) => (
                      <span
                        key={index}
                        style={{
                          display: "inline-block",
                          padding: "6px 14px",
                          background: "#ffe4f2",
                          border: "none",
                          borderRadius: "16px",
                          fontSize: "12px",
                          color: "#e91e63",
                          fontWeight: "500",
                          transition: "all 0.3s ease",
                          cursor: "default",
                        }}
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Photographer Info */}
              <div style={{ marginBottom: "32px" }}>
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: "12px",
                  }}
                >
                  <div
                    style={{
                      width: "45px",
                      height: "45px",
                      background: "#fff",
                      borderRadius: "25%",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      border: "1px solid #f0f0f0",
                      flexShrink: 0,
                      boxShadow: "0 4px 12px rgba(251, 231, 231, 0.37)",
                    }}
                  >
                    <FaUser size={20} />
                  </div>
                  <div style={{ display: "grid" }}>
                    <h6
                      style={{
                        fontSize: "14px",
                        fontWeight: "600",
                        color: "#000",
                      }}
                    >
                      Photographer Name
                    </h6>
                    <div
                      style={{
                        fontSize: "14px",
                        fontWeight: "400",
                        color: "#000",
                      }}
                    >
                      {photo.photographer_name || "Unknown"}
                    </div>
                  </div>
                </div>
              </div>

              {/* Location */}
              {photo.city_name && (
                <div style={{ marginBottom: "32px" }}>
                  <div
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "12px",
                    }}
                  >
                    <div
                      style={{
                        width: "45px",
                        height: "45px",
                        background: "#fff",
                        borderRadius: "25%",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        border: "1px solid #f0f0f0",
                        flexShrink: 0,
                        boxShadow: "0 4px 12px rgba(251, 231, 231, 0.37)",
                      }}
                    >
                      <FaMapMarkerAlt size={20} />
                    </div>
                    <div style={{ display: "grid" }}>
                      <h6
                        style={{
                          fontSize: "14px",
                          fontWeight: "600",
                          color: "#000",
                        }}
                      >
                        Location
                      </h6>
                      <div
                        style={{
                          fontSize: "14px",
                          fontWeight: "400",
                          color: "#000",
                        }}
                      >
                        {toTitleCase(photo.city_name)}
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Actions */}
              <div
                style={{
                  display: "flex",
                  gap: "16px",
                  marginTop: "32px",
                  justifyContent: vw <= 576 ? "flex-start" : "flex-end",
                  flexWrap: "wrap",
                }}
              >
                <button
                  onClick={handleShare}
                  style={{
                    width: "44px",
                    height: "44px",
                    borderRadius: "50%",
                    border: "1px solid #ddd",
                    background: "#fff",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    cursor: "pointer",
                    transition: "all 0.3s ease",
                    color: "#666",
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.borderColor = "#e91e63";
                    e.currentTarget.style.color = "#e91e63";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.borderColor = "#ddd";
                    e.currentTarget.style.color = "#666";
                  }}
                >
                  <FaShareAlt size={18} />
                </button>
                <button
                  onClick={handleLike}
                  style={{
                    width: "44px",
                    height: "44px",
                    borderRadius: "50%",
                    border: "1px solid #ddd",
                    background: "#fff",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    cursor: "pointer",
                    transition: "all 0.3s ease",
                    color: isLiked ? "#e91e63" : "#666",
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.color = "#e91e63";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.color = isLiked ? "#e91e63" : "#666";
                  }}
                >
                  <GoHeart size={24} fill={isLiked ? "#e91e63" : ""} />
                </button>
              </div>
            </div>
          </div>

          {/* About Section */}
          {photo.description && (
            <div
              style={{
                background: "#f8f9fa",
                padding: vw <= 576 ? "16px" : "32px",
                marginTop: "40px",
                textAlign: "center",
              }}
            >
              <h5
                style={{
                  fontSize: "16px",
                  fontWeight: "600",
                  color: "#333",
                  marginBottom: "16px",
                  width: "fit-content",
                  margin: "0 auto 16px auto",
                  paddingBottom: "4px",
                  borderBottom: "2px solid #e91e63",
                  transform: "translateX(0)",
                }}
              >
                About this Photography
              </h5>

              <p
                style={{
                  fontSize: "15px",
                  lineHeight: "1.8",
                  color: "#666",
                  margin: 0,
                }}
              >
                {photo.description}
              </p>
            </div>
          )}

          {/* Similar Photos Section */}
          {similarPhotos.length > 0 && (
            <div style={{ padding: "32px 0", marginTop: "40px" }}>
              <div
                style={{
                  display: "flex",
                  justifyContent: "center",
                  alignItems: "center",
                  marginBottom: "24px",
                }}
              >
                <h3
                  style={{
                    fontWeight: "600",
                    color: "#ed1147",
                    marginBottom: 10,
                  }}
                >
                  Browse Similar Photos
                </h3>
              </div>
              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))",
                  gap: "20px",
                  padding: "10px",
                }}
              >
                {similarPhotos.slice(0, 6).map((item) => {
                  const itemImage =
                    Array.isArray(item.images) && item.images.length > 0
                      ? item.images[0]
                      : item.image_url || item.url;

                  return (
                    <Link
                      key={item.id}
                      to={`/photography/${subcategory || "all"}/${city || "all"}/${item.id}`}
                      style={{ textDecoration: "none" }}
                    >
                      <div
                        style={{
                          background: "#fff",
                          overflow: "hidden",
                          boxShadow: "0 4px 12px rgba(0, 0, 0, 0.08)",
                          transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
                          height: "100%",
                          cursor: "pointer",
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.transform = "translateY(-8px)";
                          e.currentTarget.style.boxShadow =
                            "0 12px 24px rgba(0, 0, 0, 0.15)";
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.transform = "translateY(0)";
                          e.currentTarget.style.boxShadow =
                            "0 4px 12px rgba(0, 0, 0, 0.08)";
                        }}
                      >
                        <div
                          style={{
                            position: "relative",
                            width: "100%",
                            paddingBottom: "125%", // 4:5 aspect ratio like Pinterest
                            overflow: "hidden",
                            background: "#f5f5f5",
                          }}
                        >
                          <img
                            src={normalizeImageUrl(itemImage)}
                            alt={item.title}
                            style={{
                              position: "absolute",
                              top: 0,
                              left: 0,
                              width: "100%",
                              height: "100%",
                              objectFit: "cover",
                              display: "block",
                            }}
                            onError={(e) => {
                              const fallbackUrl = getFallbackImageUrl(
                                e.target.src
                              );
                              if (fallbackUrl && e.target.src !== fallbackUrl) {
                                e.target.src = fallbackUrl;
                              } else {
                                e.target.onerror = null;
                                e.target.src = "./images/noimage.jpeg";
                              }
                            }}
                          />
                          {/* Overlay on hover */}
                          <div
                            style={{
                              position: "absolute",
                              top: 0,
                              left: 0,
                              width: "100%",
                              height: "100%",
                              background:
                                "linear-gradient(180deg, rgba(0,0,0,0) 0%, rgba(0,0,0,0.4) 100%)",
                              opacity: 0,
                              transition: "opacity 0.3s ease",
                            }}
                            onMouseEnter={(e) => {
                              e.currentTarget.style.opacity = "1";
                            }}
                            onMouseLeave={(e) => {
                              e.currentTarget.style.opacity = "0";
                            }}
                          />
                          {/* Heart icon */}
                          <div
                            style={{
                              position: "absolute",
                              top: "12px",
                              right: "12px",
                              width: "36px",
                              height: "36px",
                              background: "rgba(255, 255, 255, 0.95)",
                              borderRadius: "50%",
                              display: "flex",
                              alignItems: "center",
                              justifyContent: "center",
                              color: "#e91e63",
                              boxShadow: "0 2px 8px rgba(0, 0, 0, 0.1)",
                              opacity: 0,
                              transition: "all 0.3s ease",
                            }}
                            onMouseEnter={(e) => {
                              e.currentTarget.style.opacity = "1";
                              e.currentTarget.style.transform = "scale(1.1)";
                              e.currentTarget.style.background = "#e91e63";
                              e.currentTarget.style.color = "#fff";
                            }}
                            onMouseLeave={(e) => {
                              e.currentTarget.style.opacity = "0";
                              e.currentTarget.style.transform = "scale(1)";
                              e.currentTarget.style.background =
                                "rgba(255, 255, 255, 0.95)";
                              e.currentTarget.style.color = "#e91e63";
                            }}
                          >
                            <FaHeart size={16} />
                          </div>
                        </div>
                        <div style={{ padding: "16px 16px 20px" }}>
                          <h6
                            style={{
                              fontSize: "15px",
                              fontWeight: "600",
                              color: "#111",
                              marginBottom: "6px",
                              overflow: "hidden",
                              textOverflow: "ellipsis",
                              whiteSpace: "nowrap",
                            }}
                          >
                            {item.title}
                          </h6>
                          <p
                            style={{
                              fontSize: "13px",
                              color: "#767676",
                              marginBottom: "8px",
                              fontWeight: "500",
                            }}
                          >
                            {item.photographer_name || "Unknown"}
                          </p>
                          <p
                            style={{
                              fontSize: "13px",
                              color: "#5f5f5f",
                              lineHeight: "1.5",
                              margin: 0,
                              display: "-webkit-box",
                              WebkitLineClamp: 2,
                              WebkitBoxOrient: "vertical",
                              overflow: "hidden",
                            }}
                          >
                            {item.description?.substring(0, 80)}
                            {item.description?.length > 80 ? "..." : ""}
                          </p>
                        </div>
                      </div>
                    </Link>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Lightbox Modal */}
      {isLightboxOpen && (
        <div
          style={{
            position: "fixed",
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: "rgba(0, 0, 0, 0.95)",
            zIndex: 9999,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            padding: vw <= 576 ? "16px" : "40px",
          }}
          onClick={() => setIsLightboxOpen(false)}
        >
          <button
            onClick={() => setIsLightboxOpen(false)}
            style={{
              position: "absolute",
              top: "20px",
              right: "20px",
              width: "50px",
              height: "50px",
              background: "rgba(255, 255, 255, 0.1)",
              border: "none",
              borderRadius: "50%",
              color: "#fff",
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              transition: "all 0.3s ease",
              backdropFilter: "blur(10px)",
            }}
            onMouseEnter={(e) =>
              (e.currentTarget.style.background = "rgba(255, 255, 255, 0.2)")
            }
            onMouseLeave={(e) =>
              (e.currentTarget.style.background = "rgba(255, 255, 255, 0.1)")
            }
          >
            <FaTimes size={24} />
          </button>

          <img
            src={normalizeImageUrl(images[selectedImageIndex] || thumbnails[0])}
            alt={photo.title}
            style={{
              maxHeight: "90vh",
              maxWidth: "90vw",
              objectFit: "contain",
            }}
            onClick={(e) => e.stopPropagation()}
            onError={(e) => {
              const fallbackUrl = getFallbackImageUrl(e.target.src);
              if (fallbackUrl && e.target.src !== fallbackUrl) {
                e.target.src = fallbackUrl;
              } else {
                e.target.onerror = null;
                e.target.src = "./images/noimage.jpeg";
              }
            }}
          />

          {images.length > 1 && (
            <>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setSelectedImageIndex((prev) =>
                    prev > 0 ? prev - 1 : images.length - 1
                  );
                }}
                style={{
                  position: "absolute",
                  top: "50%",
                  left: "20px",
                  transform: "translateY(-50%)",
                  width: "50px",
                  height: "50px",
                  background: "rgba(255, 255, 255, 0.1)",
                  border: "none",
                  borderRadius: "50%",
                  color: "#fff",
                  cursor: "pointer",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  transition: "all 0.3s ease",
                  backdropFilter: "blur(10px)",
                }}
                onMouseEnter={(e) =>
                  (e.currentTarget.style.background =
                    "rgba(255, 255, 255, 0.2)")
                }
                onMouseLeave={(e) =>
                  (e.currentTarget.style.background =
                    "rgba(255, 255, 255, 0.1)")
                }
              >
                <FaChevronLeft size={24} />
              </button>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  setSelectedImageIndex((prev) =>
                    prev < images.length - 1 ? prev + 1 : 0
                  );
                }}
                style={{
                  position: "absolute",
                  top: "50%",
                  right: "20px",
                  transform: "translateY(-50%)",
                  width: "50px",
                  height: "50px",
                  background: "rgba(255, 255, 255, 0.1)",
                  border: "none",
                  borderRadius: "50%",
                  color: "#fff",
                  cursor: "pointer",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  transition: "all 0.3s ease",
                  backdropFilter: "blur(10px)",
                }}
                onMouseEnter={(e) =>
                  (e.currentTarget.style.background =
                    "rgba(255, 255, 255, 0.2)")
                }
                onMouseLeave={(e) =>
                  (e.currentTarget.style.background =
                    "rgba(255, 255, 255, 0.1)")
                }
              >
                <FaChevronRight size={24} />
              </button>
            </>
          )}
        </div>
      )}
    </>
  );
};

export default PhotographyDetails;
