import React, { useState, useEffect } from "react";
import { Swiper, SwiperSlide } from "swiper/react";
import { Autoplay } from "swiper/modules";
import "swiper/css";
import { Link } from "react-router-dom";
import useApiData from "../../hooks/useApiData";
import { CiStar } from "react-icons/ci";
import { useSelector } from "react-redux";
import axios from "axios";

const IMAGE_BASE_URL = "https://happywedzbackend.happywedz.com";

const VenueSlider = () => {
  const [favorites, setFavorites] = useState([]);
  const [activeFilter, setActiveFilter] = useState("Top Rated");
  const { user } = useSelector((state) => state.auth);

  // Fetch 9 venues from API
  const {
    data: venues,
    loading,
    error,
  } = useApiData("venues", null, null, "Venues", 1, 9);

  const filterOptions = [
    { name: "Top Rated", slug: "top-rated" },
    // { name: "Resorts", slug: "top-rated" },
    { name: "Banquet Halls", slug: "venues/banquet-halls" },
    // { name: "Farmhouses", slug: "top-rated" },
    { name: "Recommendation", slug: "ai-recommandation" },
  ];

  const toggleFavorite = (id) => {
    setFavorites((prev) =>
      prev.includes(id) ? prev.filter((fav) => fav !== id) : [...prev, id]
    );
  };

  const isValidCity = (city) => {
    if (!city || typeof city !== "string") return false;
    const lower = city.toLowerCase().trim();
    if (
      !lower ||
      lower === "unknown" ||
      lower === "unknown city" ||
      lower === "null" ||
      lower === "undefined" ||
      lower === "n/a" ||
      lower === "none" ||
      lower === "all" ||
      lower.includes("location not available") ||
      lower.includes("not available") ||
      lower.includes("unknown")
    ) {
      return false;
    }
    return true;
  };

  const displayData = (venues || []).filter((v) => {
    if (!v || !v.image) return false;
    const imgStr = String(v.image).toLowerCase().trim();
    if (
      !imgStr ||
      imgStr === "null" ||
      imgStr === "undefined" ||
      imgStr.includes("placeholder") ||
      imgStr.includes("not_found") ||
      imgStr.includes("image_not_found") ||
      imgStr.includes("imagenotfound") ||
      imgStr.includes("no-image") ||
      imgStr.includes("no_image")
    ) {
      return false;
    }
    const cityVal = v.location || v.city || v.address;
    if (!isValidCity(cityVal)) return false;
    return true;
  });
  const isLoading = loading;

  // Show loading state
  if (isLoading) {
    return (
      <div className="venues-slider-container">
        <div className="venues-slider-header">
          <h2 className="fw-bold fs-28 text-dark mb-0">Pick your Venue</h2>
          {/* Same wording as the loaded state below. It used to read "SEE MORE",
              which is generic anchor text — Lighthouse's SEO "Links do not have
              descriptive text" audit flags it, and the aria-label does not
              satisfy that audit because it reads the link's text content. It
              only ever showed while the venues request was in flight, which is
              easy to miss locally but is exactly the state an audit can catch. */}
          <Link
            to="/venues"
            className="see-more-link fs-18"
            aria-label="Explore All Wedding Venues"
          >
            Explore All Venues
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
        </div>
        <div className="text-center py-5">
          <div className="spinner-border text-primary" role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
        </div>
      </div>
    );
  }

  // Show error state (only for standard fetch, or handle rec error differently?)
  if (error && activeFilter !== "Recommendation") {
    return (
      <div className="venues-slider-container">
        <div className="venues-slider-header">
          <h2 className="fw-bold fs-28 text-dark mb-0">Pick your Venue</h2>
        </div>
        <div className="text-center py-5 text-danger">
          <p>Failed to load venues. Please try again later.</p>
        </div>
      </div>
    );
  }

  // Don't render if no venues
  if ((!displayData || displayData.length === 0) && !isLoading) {
    if (activeFilter === "Recommendation" && !user) {
      // Optional: Show login prompt or empty state if user not logged in
      // For now, returning null or empty container
    }
    // return null;
  }

  return (
    <div className="venues-slider-container">
      {/* Header */}
      <div className="venues-slider-header d-flex justify-content-between align-items-end">
        <h3>Pick your Venue</h3>
        <Link
          to="/venues"
          className="see-more-link fs-14"
          aria-label="Explore All Wedding Venues"
        >
          Explore All Venues
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
      </div>

      {/* Filters */}
      <div className="venues-slider-filters px-2 fs-12">
        {filterOptions.map((filter, index) => (
          <Link
            key={index}
            onClick={() => setActiveFilter(filter.name)}
            className={`venues-slider-filter-btn ${
              activeFilter === filter.name ? "active" : ""
            }`}
            to={`/${filter.slug}`}
            style={{ textDecoration: "none" }}
          >
            {filter.name}
          </Link>
        ))}
      </div>

      {!displayData || displayData.length === 0 ? (
        <div className="text-center py-5">
          <p>No items found.</p>
        </div>
      ) : (
        <Swiper
          modules={[Autoplay]}
          spaceBetween={30}
          slidesPerView={1}
          navigation={false}
          autoplay={{
            delay: 3000,
            disableOnInteraction: false,
          }}
          breakpoints={{
            576: { slidesPerView: 1 },
            768: { slidesPerView: 2 },
            992: { slidesPerView: 3 },
          }}
          // Swiper's init reads every slide's layout (updateSize/updateSlides),
          // forcing a synchronous reflow during React's commit. Deferring
          // .init() to a macrotask cut total forced-reflow time on this page
          // from 922ms to 195ms (Chrome ForcedReflow insight, 4x CPU
          // throttle). It does NOT move LCP/FCP/TBT — this section mounts
          // after LCP anyway — but it's real main-thread work removed from
          // the scroll-in, so the carousel settles without janking.
          init={false}
          onSwiper={(swiper) =>
            setTimeout(() => {
              if (swiper && !swiper.destroyed && swiper.el) {
                swiper.init();
              }
            }, 0)
          }
        >
          {displayData.map((item) => {
            const id = item.id;
            const name = item.name;
            const rating = item.rating || 0;
            const reviews = item.reviews || item.review_count || 0;
            const city = item.location;

            const rawImage = item.image || "";
            const imageUrl = rawImage
              ? rawImage.startsWith("http")
                ? rawImage
                : `${IMAGE_BASE_URL}${rawImage}`
              : "/images/imageNotFound.jpg";

            return (
              <SwiperSlide key={id}>
                <div className="venues-slider-card shadow-sm">
                  <Link
                    to={`/details/info/${id}`}
                    className="text-decoration-none"
                  >
                    <div className="venues-slider-image-container">
                      <img loading="lazy" decoding="async"
                        src={imageUrl}
                        alt={name}
                        className="venues-slider-image"
                        onError={(e) => {
                          e.target.onerror = null;
                          const slide = e.target.closest(".swiper-slide");
                          if (slide) slide.style.display = "none";
                        }}
                      />
                      <button
                        onClick={(e) => {
                          e.preventDefault();
                          toggleFavorite(id);
                        }}
                        className="venues-slider-favorite-btn"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          viewBox="0 0 24 24"
                          fill={favorites.includes(id) ? "#e91e63" : "none"}
                          stroke={favorites.includes(id) ? "#e91e63" : "white"}
                          strokeWidth="2"
                          className="venues-slider-heart-icon"
                        >
                          <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
                        </svg>
                      </button>
                    </div>

                    <div className="venues-slider-content">
                      <div className="fw-bold mb-1 text-dark fs-18 text-truncate">{name}</div>
                      <div className="venues-slider-rating d-flex align-items-center gap-1">
                        <CiStar color="orange" />
                        <span className="venues-slider-rating-number">
                          {rating}
                        </span>
                        <span className="venues-slider-review-count text-muted">
                          ({reviews} reviews)
                        </span>
                      </div>
                      {city && <div className="text-muted fs-14">{city}</div>}
                    </div>
                  </Link>
                </div>
              </SwiperSlide>
            );
          })}
        </Swiper>
      )}
    </div>
  );
};

export default VenueSlider;
