import React, { useState, useEffect, useRef } from "react";
import { FaBolt, FaPalette, FaMobileAlt } from "react-icons/fa";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate, useParams } from "react-router-dom";
import LoginPopup from "./DesignStudio.LoginPopup";
import { setRoleType } from "../../../redux/roleSlice";
import Slider from "react-slick";
import "slick-carousel/slick/slick.css";
import "slick-carousel/slick/slick-theme.css";
import { Card, CardActionArea, CardMedia } from "@mui/material";

const TryLanding = () => {
  const [showModal, setShowModal] = useState(false);
  const [showLoginPopup, setShowLoginPopup] = useState(false);
  const [isLoaded, setIsLoaded] = useState(false);
  const [imagesLoaded, setImagesLoaded] = useState(false);
  const [currentSlide, setCurrentSlide] = useState(0);

  const navigate = useNavigate();
  const dispatch = useDispatch();
  const user = useSelector((state) => state.auth.user);
  const autoplayRef = useRef(null);

  // List of image paths
  const imageSources = [
    "/images/try/carousel-img-1.png",
    "/images/try/carousel-img-2.png",
    "/images/try/carousel-img-3.png",
  ];

  const goToSlide = (index) => {
    setCurrentSlide(index);
  };

  // Autoplay effect
  useEffect(() => {
    autoplayRef.current = setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % imageSources.length);
    }, 1500);

    return () => {
      if (autoplayRef.current) {
        clearInterval(autoplayRef.current);
      }
    };
  }, []);

  // Preload all images
  useEffect(() => {
    let loadedCount = 0;
    const totalImages = imageSources.length;

    const handleImageLoad = () => {
      loadedCount++;
      if (loadedCount === totalImages) {
        setImagesLoaded(true);
      }
    };

    imageSources.forEach((src) => {
      const img = new Image();
      img.src = src;
      img.onload = handleImageLoad;
      img.onerror = handleImageLoad;
    });
  }, []);

  useEffect(() => {
    setIsLoaded(true);
  }, []);

  const handleLoginSuccess = () => {
    setShowLoginPopup(false);
    setShowModal(true);
  };

  const handleGetStarted = () => {
    if (!user) {
      setShowLoginPopup(true);
    } else {
      setShowModal(true);
    }
  };

  const handleModalClose = () => setShowModal(false);
  const handleLoginClose = () => setShowLoginPopup(false);

  return (
    <>
      <style>
        {` 
          @media (max-width: 992px) {
            /* md and below */
            .try-hero-flex {
              flex-direction: column !important;
              align-items: center !important;
              height: auto !important;
              max-height: none !important;
              gap: 1.5rem !important;
            }
            .try-hero-left {
              align-self: stretch !important;
              padding-left: 1rem !important;
              padding-right: 1rem !important;
              flex: 0 0 100% !important;
            }
            .try-hero-left .try-first-page-content-wrapper {
              margin-left: 0 !important;
              margin-bottom: 1rem !important;
              max-width: 100% !important;
            }
            .try-hero-right {
              align-self: stretch !important;
              margin-top: 0 !important;
              max-width: 100% !important;
              flex: 0 0 100% !important;
            }
            .try-hero-right .carousel-shell {
              max-height: 380px !important;
              height: auto !important;
            }
          }

          @media (max-width: 576px) { 
            .try-hero-right .carousel-shell {
              max-height: 320px !important;
            }
          }
        `}
      </style>
      <div className="try-first-page-container">
        <div
          className={`try-first-page-hero ${
            isLoaded ? "try-first-page-loaded" : ""
          }`}
        >
          <div
            style={{
              height: "auto",
              position: "relative",
              paddingTop: 0,
            }}
          >
            <div
              className="try-hero-flex"
              style={{
                display: "flex",
                justifyContent: "center",
                alignItems: "stretch",
                gap: "3rem",
                height: "calc(100vh - 150px)",
                maxHeight: "680px",
                paddingTop: 0,
              }}
            >
              <div
                className="try-first-page-hero-content px-6 try-hero-left"
                style={{
                  alignSelf: "flex-end",
                  display: "flex",
                  justifyContent: "flex-start",
                  alignItems: "flex-end",
                  flex: "0 0 40%",
                  gap: "2rem",
                }}
              >
                <div
                  className="try-first-page-content-wrapper"
                  style={{
                    marginBottom: "3rem",
                    marginLeft: "3rem",
                    maxWidth: "520px",
                    width: "100%",
                  }}
                >
                  <h1
                    className="try-first-page-title"
                    style={{
                      fontWeight: "400",
                      textAlign: "start",
                      color: "#C31162",
                    }}
                  >
                    Virtual Try On
                  </h1>
                  <p
                    style={{
                      fontSize: "1.6rem",
                      fontWeight: "500",
                      wordSpacing: "1.5px",
                      color: "#C31162",
                    }}
                  >
                    Makeup, Jewellary & Outfits in One Place
                  </p>
                  <button
                    style={{
                      background: "linear-gradient(to right, #E83580, #821E48)",
                      color: "#fff",
                      border: "2px solid #e9277fff",
                      padding: "0.5rem 0",
                      fontWeight: "500",
                      borderRadius: "10px",
                      fontSize: "1.5rem",
                      width: "100%",
                    }}
                    onClick={handleGetStarted}
                  >
                    Get Started
                  </button>
                </div>
              </div>

              <div
                className="try-hero-right"
                style={{
                  maxWidth: "850px",
                  height: "100%",
                  borderRadius: "20px",
                  overflow: "hidden",
                  alignSelf: "flex-start",
                  marginTop: "-20px",
                  flex: "1 1 60%",
                }}
              >
                {imagesLoaded ? (
                  <div
                    className="carousel-shell"
                    style={{
                      position: "relative",
                      width: "100%",
                      height: "100%",
                      maxHeight: "480px",
                      overflow: "hidden",
                      borderRadius: "20px",
                      background: "transparent",
                    }}
                  >
                    <div
                      style={{
                        display: "flex",
                        height: "100%",

                        transform: `translateX(-${currentSlide * 100}%)`,
                        transition: "transform 500ms ease-in-out",
                      }}
                    >
                      {imageSources.map((src, index) => (
                        <div
                          key={index}
                          style={{
                            minWidth: "100%",
                            height: "100%",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                          }}
                        >
                          <img
                            src={src}
                            alt={`carousel ${index + 1}`}
                            style={{
                              width: "100%",
                              height: "100%",
                              objectFit: "stretch",
                              borderRadius: "16px",
                            }}
                            onError={(e) => {
                              e.target.style.display = "none";
                              e.target.parentElement.innerHTML = `<div style="width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 16px; color: white; font-size: 24px;">Image ${
                                index + 1
                              }</div>`;
                            }}
                          />
                        </div>
                      ))}
                    </div>

                    <div
                      style={{
                        position: "absolute",
                        bottom: 0,
                        left: "0",
                        right: "0",
                        display: "flex",
                        justifyContent: "center",
                        alignItems: "center",
                        gap: "10px",
                        zIndex: 50,
                      }}
                    >
                      {imageSources.map((_, index) => (
                        <button
                          key={index}
                          onClick={() => goToSlide(index)}
                          style={{
                            width: "8px",
                            height: "12px",
                            borderRadius: "50%",
                            border: "none",
                            background:
                              currentSlide === index ? "#C31162" : "#ed1147",
                            cursor: "pointer",
                            transition: "all 300ms ease",
                            opacity: currentSlide === index ? 1 : 0.6,
                          }}
                          aria-label={`Go to slide ${index + 1}`}
                        />
                      ))}
                    </div>
                  </div>
                ) : (
                  <div
                    style={{
                      height: "100%",
                      background: "transparent",
                      borderRadius: "20px",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      color: "#999",
                      fontSize: "1.2rem",
                    }}
                  >
                    Loading...
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {showModal && (
          <div
            className="try-first-page-modal-backdrop"
            onClick={handleModalClose}
          >
            <div
              className="try-first-page-modal"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="try-first-page-modal-header">
                <h3 style={{ color: "#C31162" }}>Choose One</h3>
                <p className="fs-14 fw-bold">
                  Instantly try on makeup look and find your perfect shades
                </p>
                <button
                  className="try-first-page-modal-close"
                  onClick={handleModalClose}
                >
                  <span>×</span>
                </button>
              </div>

              <div className="try-first-page-modal-content">
                <div className="row g-5 text-center">
                  <div className="col-md-4">
                    <div
                      role="button"
                      onClick={() => {
                        const userInfo = { role: "bride" };
                        localStorage.setItem(
                          "userInfo",
                          JSON.stringify(userInfo)
                        );
                        dispatch(setRoleType({ role: "bride" }));
                        navigate("/try/bride");
                      }}
                      className="d-flex flex-column align-items-center"
                      style={{ height: "320px" }}
                    >
                      <img
                        src="/images/try/Bride.png"
                        alt="Bride"
                        style={{
                          width: "100%",
                          height: "100%",
                          objectFit: "cover",
                        }}
                      />
                      <h4
                        className="mt-3 fw-semibold"
                        style={{ color: "#C31162" }}
                      >
                        Bride
                      </h4>
                    </div>
                  </div>

                  {/* Groom */}
                  <div className="col-md-4">
                    <div
                      role="button"
                      onClick={() => {
                        const userInfo = { role: "groom" };
                        localStorage.setItem(
                          "userInfo",
                          JSON.stringify(userInfo)
                        );
                        dispatch(setRoleType({ role: "groom" }));
                        navigate("/try/groom");
                      }}
                      className="d-flex flex-column align-items-center"
                    >
                      <div
                        className="position-relative w-100 try-modal-container"
                        style={{ height: "320px" }}
                      >
                        <img
                          src="/images/try/Groome.png"
                          alt="Groom"
                          className="w-100 h-100"
                          style={{ objectFit: "cover" }}
                        />
                      </div>
                      <h4
                        className="mt-3 fw-semibold"
                        style={{ color: "#C31162" }}
                      >
                        Groom
                      </h4>
                    </div>
                  </div>

                  {/* Other */}
                  <div className="col-md-4">
                    <div
                      role="button"
                      className="d-flex flex-column align-items-center"
                      style={{ opacity: 0.6, pointerEvents: "none" }}
                    >
                      <div
                        className="position-relative w-100 try-modal-container"
                        style={{ height: "320px" }}
                      >
                        <img
                          src="/images/try/Others.png"
                          alt="Other"
                          className="w-100 h-100"
                          style={{ objectFit: "cover" }}
                        />
                        <div className="try-modal-hover-overlay-custom d-flex justify-content-center align-items-center rounded-5">
                          <span className="text-white fs-4 fw-bold">
                            Coming Soon
                          </span>
                        </div>
                      </div>
                      <h4
                        className="mt-3 fw-semibold"
                        style={{ color: "#C31162" }}
                      >
                        Other
                      </h4>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {showLoginPopup && (
          <LoginPopup isOpen={showLoginPopup} onClose={handleLoginClose} />
        )}
      </div>
    </>
  );
};

export default TryLanding;
