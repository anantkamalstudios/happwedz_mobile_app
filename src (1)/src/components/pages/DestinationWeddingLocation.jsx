import React, { useRef } from "react";
import { useNavigate } from "react-router-dom";
import { WiDirectionUpRight } from "react-icons/wi";
import { Swiper, SwiperSlide } from "swiper/react";
import { Navigation, Autoplay } from "swiper/modules";
import "swiper/css";
import "swiper/css/navigation";
import { destinationWeddingData } from "../../data/designationWedding";

const DestinationWeddingLayout = ({
  icon,
  title,
  subtitle,
  btnName,
  redirectUrl,
  images: apiImages = [],
}) => {
  const navigate = useNavigate();
  const swiperRef = useRef(null);

  const normalizeUrl = (u) =>
    typeof u === "string" ? u.replace(/`/g, "").trim() : u;

  const sourceImages =
    Array.isArray(apiImages) && apiImages.length > 0
      ? apiImages
      : destinationWeddingData;

  const images = sourceImages.map((item, idx) => {
    const normalizedUrl = normalizeUrl(
      item.cardImage || item.url || item.heroImage
    );
    const slug =
      item.slug ||
      (item.title || "")
        .toLowerCase()
        .replace(/&/g, "and")
        .replace(/\s+/g, "-");
    return {
      ...item,
      id: item.id || idx + 1,
      url: normalizedUrl,
      alt: item.alt || `${item.title || "Destination"} Wedding`,
      slug,
    };
  });

  const nextSlide = () => {
    if (swiperRef.current) {
      swiperRef.current.slideNext();
    }
  };

  const prevSlide = () => {
    if (swiperRef.current) {
      swiperRef.current.slidePrev();
    }
  };

  return (
    <div className="destination-wedding-container">
      <div className="layout-wrapper py-5">
        <div className="left-section">
          <h1 className="main-title">
            {title ||
              "Which Are The Best Destination Wedding Locations In India?"}
          </h1>
        </div>

        {/* Right Section - Cards Display */}
        <div className="right-section py-5">
          {/* Cards Container */}
          <div className="cards-wrapper">
            <Swiper
              onSwiper={(swiper) => {
                swiperRef.current = swiper;
              }}
              slidesPerView={1}
              slidesPerGroup={1}
              spaceBetween={20}
              modules={[Navigation, Autoplay]}
              autoplay={{
                delay: 8000,
                disableOnInteraction: false,
              }}
              loop={true}
              breakpoints={{
                576: {
                  slidesPerView: 2,
                  slidesPerGroup: 2,
                },
                992: {
                  slidesPerView: 3,
                  slidesPerGroup: 3,
                },
              }}
              className="destination-swiper"
            >
              {images.map((image, index) => (
                <SwiperSlide key={`${image.id}-${index}`}>
                  <div className="card rounded-0">
                    {/* Image */}
                    <div className="card-image p-2">
                      <img src={image.url} alt={image.alt} />
                    </div>

                    {/* Content */}
                    <div className="card-content">
                      <h4 className="card-title fw-bold">{image.title}</h4>
                      {image.subtitle && (
                        <p
                          className="fs-16"
                          style={{
                            color: "#d81b60",
                            marginBottom: "10px",
                            fontWeight: "600",
                          }}
                        >
                          {image.subtitle}
                        </p>
                      )}
                      <p className="card-description fs-14">
                        {image.description}
                      </p>

                      <div style={{ marginBottom: "15px", fontSize: "14px" }}>
                        <p className="fs-14" style={{ margin: "5px 0" }}>
                          <strong>Best Season:</strong> {image.bestSeason}
                        </p>
                        <p className="fs-14" style={{ margin: "5px 0" }}>
                          <strong>Average Cost:</strong> {image.averageCost}
                        </p>
                        {image.weddingStyles && (
                          <div className="fs-14" style={{ marginTop: "10px" }}>
                            <strong>Wedding Styles:</strong>
                            <ul
                              className="fs-14"
                              style={{
                                paddingLeft: "20px",
                                marginTop: "5px",
                                color: "#666",
                              }}
                            >
                              {image.weddingStyles.map((style, i) => (
                                <li className="fs-14" key={i}>
                                  {style}
                                </li>
                              ))}
                            </ul>
                          </div>
                        )}
                      </div>

                      <button
                        className="card-button fs-14"
                        onClick={() =>
                          navigate(`/destination-wedding/${image.slug}`)
                        }
                      >
                        See Details
                        <WiDirectionUpRight size={30} />
                      </button>
                    </div>
                  </div>
                </SwiperSlide>
              ))}
            </Swiper>
          </div>

          {/* Navigation Buttons */}
          <div className="navigation-buttons">
            <button onClick={prevSlide} className="nav-button nav-prev">
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#333"
                strokeWidth="2"
              >
                <path d="m15 18-6-6 6-6" />
              </svg>
            </button>
            <button onClick={nextSlide} className="nav-button nav-next">
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="white"
                strokeWidth="2"
              >
                <path d="m9 18 6-6-6-6" />
              </svg>
            </button>
          </div>
        </div>
      </div>

      <style>{`
        .destination-wedding-container {
          width: 100%; 
          overflow: hidden;
        }

        .layout-wrapper {
          display: flex;
          min-height: 600px;
          position: relative;
        }

        .left-section {
          width: 40%;
          background-color: #d81b60;
          padding: 80px 60px;
          display: flex;
          flex-direction: column;
          justify-content: center;
          color: white;
          position: relative;
          z-index: 0;
          box-shadow: 10px 0 30px rgba(0, 0, 0, 0.15);
        }

        .main-title {
          font-size: 48px;
          font-weight: bold;
          line-height: 1.2;
          margin: 0;
          font-family: Georgia, serif;
        }

        .right-section {
          width: 60%;
          padding: 40px 0 40px 0px;
          display: flex;
          align-items: center;
          position: relative;
          overflow: visible;
          margin-left: -50px;
          z-index: 1;
        }

        .cards-wrapper {
          width: 100%;
          overflow: hidden;
        }

        .cards-container {
          display: flex;
          gap: 20px;
          width: 100%;
          transition: transform 0.5s ease;
        }

        .destination-swiper {
          width: 100%;
          overflow: visible;
        }

        .destination-swiper .swiper-wrapper {
          display: flex;
        }

        .destination-swiper .swiper-slide {
          height: auto;
        }

        .destination-swiper .swiper-button-next,
        .destination-swiper .swiper-button-prev {
          display: none !important;
        }

        .destination-swiper .swiper-pagination {
          display: none !important;
        }

        .card {
          flex: 0 0 calc(33.333% - 20px);
          background-color: white;
          border-radius: 8px;
          overflow: hidden;
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
          transition: transform 0.3s ease, box-shadow 0.3s ease;
          display: flex;
          flex-direction: column;
        }

        .card:hover {
          transform: translateY(-5px);
          box-shadow: 0 8px 20px rgba(0, 0, 0, 0.15);
        }

        .card-image {
          width: 100%;
          height: 200px;
          overflow: hidden;
          flex-shrink: 0;
        }

        .card-image img {
          width: 100%;
          height: 100%;
          object-fit: cover;
          transition: transform 0.3s ease;
        }

        .card:hover .card-image img {
          transform: scale(1.05);
        }

        .card-content {
          padding: 20px;
          flex-grow: 1;
          display: flex;
          flex-direction: column;
        }

        .card-title {
          color: #d81b60;
          font-size: 24px;
          font-weight: bold;
          margin: 0 0 5px 0;
          font-family: Georgia, serif;
        }

        .card-description {
          color: #666;
          font-size: 14px;
          line-height: 1.6;
          margin: 0 0 15px 0;
        }

        .card-button {
          background-color: transparent;
          border: 1px solid #d81b60;
          color: #d81b60;
          padding: 10px 24px;
          border-radius: 25px;
          font-size: 14px;
          font-weight: 600;
          cursor: pointer;
          display: flex;
          align-items: center;
          gap: 8px;
          transition: all 0.3s ease;
          margin-top: auto;
          width: fit-content;
        }

        .card-button:hover {
          background-color: #d81b60;
          color: white;
        }

        .navigation-buttons {
          position: absolute;
          bottom: -20px;
          right: 40px;
          display: flex;
          gap: 10px; 
          z-index: 10;
        }

        .nav-button {
          width: 40px;
          height: 40px;
          border-radius: 50%;
          cursor: pointer;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: all 0.3s ease;
          border: none;
        }

        .nav-prev {
          border: 1px solid #ddd;
          background-color: white;
        }

        .nav-prev:hover {
          background-color: #f0f0f0;
        }

        .nav-next {
          background-color: #d81b60;
        }

        .nav-next:hover {
          background-color: #c2185b;
        }

        /* Responsive Design */
        @media (max-width: 1200px) {
          .main-title {
            font-size: 40px;
          }

          .card-title {
            font-size: 20px;
          }
        }

        @media (max-width: 992px) {
          .layout-wrapper {
            flex-direction: column;
            min-height: auto;
          }

          .left-section {
            width: 100%;
            padding: 60px 40px;
            box-shadow: none;
          }

          .main-title {
            font-size: 36px;
          }

          .right-section {
            width: 100%;
            padding: 40px 20px;
            margin-left: 0;
            margin-top: -30px;
            z-index: 1;
          }

          .destination-swiper {
            overflow: visible;
          }

          .navigation-buttons {
            bottom: 20px;
            right: 20px;
          }
        }

        @media (max-width: 768px) {
          .left-section {
            padding: 40px 30px;
          }

          .main-title {
            font-size: 28px;
          }

          .right-section {
            padding: 30px 15px;
          }

          .destination-swiper {
            overflow: visible;
          }

          .card-image {
            height: 180px;
          }

          .card-content {
            padding: 15px;
          }

          .card-title {
            font-size: 20px;
          }

          .card-description {
            font-size: 13px;
          }

          .navigation-buttons {
            bottom: 15px;
            right: 15px;
          }

          .nav-button {
            width: 35px;
            height: 35px;
          }
        }

        @media (max-width: 480px) {
          .left-section {
            padding: 30px 20px;
          }

          .main-title {
            font-size: 24px;
          }

          .right-section {
            padding: 20px 10px;
          }

          .card-image {
            height: 160px;
          }
        }
      `}</style>
    </div>
  );
};

export default DestinationWeddingLayout;
