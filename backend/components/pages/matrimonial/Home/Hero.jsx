import React, { useState, useEffect } from "react";
import { FiUser, FiLock } from "react-icons/fi";
import { Swiper, SwiperSlide } from "swiper/react";
import { EffectCoverflow, Autoplay, Pagination } from "swiper/modules";
import "swiper/css";
import "swiper/css/effect-coverflow";
import "swiper/css/pagination";
import "../../../../Matrimonial.css";

const Hero = () => {
  const [isLoginOpen, setIsLoginOpen] = useState(false);

  const toggleLogin = () => {
    setIsLoginOpen(!isLoginOpen);
  };

  useEffect(() => {
    const scrollContainer = document.querySelector(
      ".success-stories-container"
    );
    let scrollAmount = 0;

    const autoScroll = setInterval(() => {
      if (scrollContainer) {
        scrollAmount += 1;
        if (scrollAmount >= scrollContainer.scrollWidth / 2) {
          scrollAmount = 0;
        }
        scrollContainer.scrollTo({
          left: scrollAmount,
          behavior: "smooth",
        });
      }
    }, 50);

    return () => clearInterval(autoScroll);
  }, []);

  // Sample images for the swiper - you can replace these with your actual images
  const swiperImages = [
    "https://images.unsplash.com/photo-1519741497674-611481863552?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80",
    "https://images.unsplash.com/photo-1519741497674-611481863552?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80",
    "https://images.unsplash.com/photo-1519741497674-611481863552?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80",
    "https://images.unsplash.com/photo-1519741497674-611481863552?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80",
    "https://images.unsplash.com/photo-1519741497674-611481863552?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80",
    "https://images.unsplash.com/photo-1519741497674-611481863552?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80",
  ];

  return (
    <div className="matrimonial-container">
      {/* Login Modal */}
      {isLoginOpen && (
        <div className="login-modal">
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Login to Your Account</h2>
              <button className="close-btn" onClick={toggleLogin}>
                ×
              </button>
            </div>
            <div className="modal-body">
              <div className="form-group">
                <FiUser className="input-icon" />
                <input type="text" placeholder="Email or Mobile" />
              </div>
              <div className="form-group">
                <FiLock className="input-icon" />
                <input type="password" placeholder="Password" />
              </div>
              <div className="remember-forgot">
                <label>
                  <input type="checkbox" /> Remember me
                </label>
                <a href="/">Forgot Password?</a>
              </div>
              <button className="login-button">Login</button>
              {/* <div className="divider">or</div>
              <button className="signup-button">Create New Account</button> */}
            </div>
            <div className="modal-footer">
              <p>
                By logging in, you agree to our{" "}
                <a href="/">Terms & Conditions</a> and{" "}
                <a href="/">Privacy Policy</a>
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Hero Section */}
      <div className="hero-section">
        <div className="container">
          <div className="matrimonial-hero-content">
            <div className="row">
              <div className="d-flex justify-content-between">
                <div className="col-md-8">
                  <div className="hero-text">
                    <h1>Find Your Perfect Life Partner</h1>
                    <p>
                      Trusted by millions of families to discover meaningful
                      connections
                    </p>
                    <div className="stats">
                      <div className="stat-item">
                        <h3>10M+</h3>
                        <p>Registered Users</p>
                      </div>
                      <div className="stat-item">
                        <h3>500K+</h3>
                        <p>Success Stories</p>
                      </div>
                      <div className="stat-item">
                        <h3>20+</h3>
                        <p>Years of Experience</p>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="col-md-4">
                  <div className="hero-swiper-container">
                    <Swiper
                      effect={"coverflow"}
                      grabCursor={true}
                      centeredSlides={true}
                      slidesPerView={"auto"}
                      coverflowEffect={{
                        rotate: 0,
                        stretch: 0,
                        depth: 100,
                        modifier: 1,
                        slideShadows: true,
                      }}
                      autoplay={{
                        delay: 30000,
                        disableOnInteraction: false,
                      }}
                      loop={true}
                      pagination={{
                        clickable: true,
                      }}
                      modules={[EffectCoverflow, Autoplay, Pagination]}
                      className="hero-swiper"
                    >
                      {swiperImages.map((image, index) => (
                        <SwiperSlide key={index} className="hero-swiper-slide">
                          <div className="hero-image-container">
                            <img
                              src={image}
                              alt={`Happy couple ${index + 1}`}
                              className="hero-image"
                            />
                            <div className="hero-image-overlay">
                              <div className="hero-image-text">
                                <h3>Success Story {index + 1}</h3>
                                <p>Another beautiful couple found love</p>
                              </div>
                            </div>
                          </div>
                        </SwiperSlide>
                      ))}
                    </Swiper>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Hero;
