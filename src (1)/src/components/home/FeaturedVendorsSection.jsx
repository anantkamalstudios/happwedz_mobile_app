import React, { useEffect } from "react";
import { Container, Row, Col } from "react-bootstrap";
import Swiper from "swiper/bundle";
import "swiper/css/bundle";
import { FaStar, FaMapMarkerAlt, FaHeart, FaEye } from "react-icons/fa";

const FeaturedVendorsSection = () => {
  const featuredVendors = [
    {
      name: "Royal Palace Venues",
      category: "Wedding Venues",
      location: "Mumbai, Delhi, Bangalore",
      rating: 4.9,
      reviews: 1250,
      price: "₹2,50,000 onwards",
      image:
        "https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=400&h=300&fit=crop",
      badge: "Most Popular",
      badgeColor: "#e83581",
    },
    {
      name: "Dream Photography Studio",
      category: "Photography",
      location: "Mumbai, Pune",
      rating: 4.8,
      reviews: 890,
      price: "₹75,000 onwards",
      image:
        "https://images.unsplash.com/photo-1606800052052-a08af7148866?w=400&h=300&fit=crop",
      badge: "Top Rated",
      badgeColor: "#ff6b9d",
    },
    {
      name: "Glamour Makeup Artists",
      category: "Bridal Makeup",
      location: "Delhi, Gurgaon",
      rating: 4.9,
      reviews: 650,
      price: "₹25,000 onwards",
      image:
        "https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=400&h=300&fit=crop",
      badge: "Featured",
      badgeColor: "#ff8fab",
    },
    {
      name: "Royal Catering Services",
      category: "Catering",
      location: "Bangalore, Chennai",
      rating: 4.7,
      reviews: 1100,
      price: "₹500 per plate",
      image:
        "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop",
      badge: "Best Value",
      badgeColor: "#ffb3c6",
    },
    {
      name: "Elegant Decorators",
      category: "Wedding Decor",
      location: "Mumbai, Thane",
      rating: 4.8,
      reviews: 780,
      price: "₹1,50,000 onwards",
      image:
        "https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=400&h=300&fit=crop",
      badge: "Trending",
      badgeColor: "#e83581",
    },
    {
      name: "Melody Music Band",
      category: "Entertainment",
      location: "Delhi, Noida",
      rating: 4.9,
      reviews: 420,
      price: "₹80,000 onwards",
      image:
        "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=300&fit=crop",
      badge: "New",
      badgeColor: "#ff6b9d",
    },
  ];

  useEffect(() => {
    new Swiper(".featuredVendorsSwiper", {
      slidesPerView: 1,
      spaceBetween: 20,
      loop: true,
      autoplay: {
        delay: 4000,
        disableOnInteraction: false,
      },
      navigation: {
        nextEl: ".swiper-button-next",
        prevEl: ".swiper-button-prev",
      },
      breakpoints: {
        576: {
          slidesPerView: 2,
        },
        768: {
          slidesPerView: 3,
        },
        1024: {
          slidesPerView: 4,
        },
      },
    });
  }, []);

  return (
    <section
      className="featured-vendors-category py-5"
      style={{ background: "#fff" }}
    >
      <Container>
        <div className="d-flex justify-content-between align-items-center mb-5">
          <div>
            <h2 className="fw-bold text-dark mb-2">Featured Wedding Vendors</h2>
            <p className="text-muted">
              Handpicked top-rated vendors for your special day
            </p>
          </div>
          <button className="cta-button">View All Vendors</button>
        </div>

        <div className="position-relative carousel-container">
          <div className="swiper featuredVendorsSwiper p-2">
            <div className="swiper-wrapper vendors-slide">
              {featuredVendors.map((vendor, index) => (
                <div key={index} className="swiper-slide">
                  <div className="vendor-card">
                    <div className="vendor-image-container">
                      <img loading="lazy" decoding="async"
                        src={vendor.image}
                        alt={vendor.name}
                        className="vendor-image"
                      />
                      <div
                        className="vendor-badge"
                        style={{ backgroundColor: vendor.badgeColor }}
                      >
                        {vendor.badge}
                      </div>
                    </div>

                    <div className="vendor-content p-3">
                      <h6 className="vendor-name fw-bold mb-1">
                        {vendor.name}
                      </h6>
                      <p className="vendor-category text-muted small mb-2">
                        {vendor.category}
                      </p>

                      <div className="vendor-location mb-2">
                        <small className="text-muted">
                          <FaMapMarkerAlt className="me-1" /> {vendor.location}
                        </small>
                      </div>

                      <div className="vendor-rating d-flex align-items-center mb-2">
                        <div className="rating-stars me-2">
                          {[...Array(5)].map((_, i) => (
                            <FaStar
                              key={i}
                              className={
                                i < Math.floor(vendor.rating)
                                  ? "star filled"
                                  : "star"
                              }
                            />
                          ))}
                        </div>
                        <span className="rating-text small">
                          {vendor.rating} ({vendor.reviews} reviews)
                        </span>
                      </div>

                      <div
                        className="vendor-price fw-semibold"
                        style={{ color: "#dc3545" }}
                      >
                        {vendor.price}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </Container>
    </section>
  );
};

export default FeaturedVendorsSection;
