import React, { useEffect } from "react";
import { Container, Row, Col } from "react-bootstrap";
import { CiStar } from "react-icons/ci";
import { FaStar } from "react-icons/fa";
import Swiper from "swiper/bundle";
import "swiper/css/bundle";

const TestimonialsSection = () => {
  const testimonials = [
    {
      name: "Priya & Rajesh",
      location: "Mumbai",
      image:
        "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face",
      rating: 5,
      text: "HappyWedz helped us find the perfect photographer and venue. The process was so smooth and we got exactly what we dreamed of!",
      vendor: "Wedding Photography by Studio Dreams",
    },
    {
      name: "Anita & Vikram",
      location: "Delhi",
      image:
        "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face",
      rating: 5,
      text: "Amazing platform! We found our dream wedding planner and caterer within days. The reviews were spot on and helped us make the right choice.",
      vendor: "Catering by Royal Kitchen",
    },
    {
      name: "Sneha & Arjun",
      location: "Bangalore",
      image:
        "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face",
      rating: 5,
      text: "The vendor recommendations were perfect for our budget and style. Our wedding was everything we imagined and more!",
      vendor: "Venue: The Grand Palace",
    },
    {
      name: "Kavya & Rohit",
      location: "Pune",
      image:
        "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
      rating: 5,
      text: "HappyWedz made wedding planning stress-free. The vendor profiles were detailed and the booking process was seamless.",
      vendor: "Makeup by Glam Studio",
    },
  ];

  useEffect(() => {
    new Swiper(".testimonialsSwiper", {
      slidesPerView: 1,
      spaceBetween: 30,
      loop: true,
      autoplay: {
        delay: 5000,
        disableOnInteraction: false,
      },
      pagination: {
        el: ".swiper-pagination",
        clickable: true,
      },
      breakpoints: {
        768: {
          slidesPerView: 2,
        },
        1024: {
          slidesPerView: 3,
        },
      },
    });
  }, []);

  return (
    <section className="py-5" style={{ background: "#fff" }}>
      <Container>
        <div className="text-center mb-5">
          <h2 className="fw-bold text-dark mb-3">What Our Couples Say</h2>
          <p
            className="h6 text-muted mb-3"
            data-aos="fade-up"
            data-aos-delay="50"
          >
            Real stories from real couples who made their dream wedding come
            true
          </p>
        </div>

        <div className="swiper testimonialsSwiper p-5">
          <div className="swiper-wrapper">
            {testimonials.map((testimonial, index) => (
              <div key={index} className="swiper-slide">
                <div className="testimonial-card p-4">
                  <div className="d-flex align-items-center mb-3">
                    <div className="position-relative">
                      <img loading="lazy" decoding="async"
                        src={testimonial.image}
                        alt={testimonial.name}
                        className="rounded-circle me-3"
                        style={{
                          width: "70px",
                          height: "70px",
                          objectFit: "cover",
                          border: "3px solid rgba(232, 53, 129, 0.1)",
                        }}
                      />
                      <div
                        className="position-absolute"
                        style={{
                          bottom: 0,
                          right: 8,
                          background: "#e83581",
                          width: "20px",
                          height: "20px",
                          borderRadius: "50%",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          color: "white",
                          fontSize: "12px",
                        }}
                      >
                        "
                      </div>
                    </div>
                    <div>
                      <h6 className="mb-1 fw-bold" style={{ color: "#2c3e50" }}>
                        {testimonial.name}
                      </h6>
                      <small className="text-muted d-flex align-items-center">
                        <FaStar
                          className="me-1"
                          style={{ color: "#e83581", fontSize: "12px" }}
                        />
                        {testimonial.location}
                      </small>
                    </div>
                  </div>

                  <div className="rating mb-3">
                    {[...Array(testimonial.rating)].map((_, i) => (
                      <span key={i} className="text-warning">
                        <FaStar />
                      </span>
                    ))}
                  </div>

                  <p className="testimonial-text mb-3">{testimonial.text}</p>

                  <div className="vendor-info">
                    <small className="fw-semibold d-flex align-items-center">
                      <span className="me-2" style={{ color: "#e83581" }}>
                        ❤
                      </span>
                      {testimonial.vendor}
                    </small>
                  </div>
                </div>
              </div>
            ))}
          </div>
          <div className="swiper-pagination"></div>
        </div>
      </Container>

      <style>{`
        .testimonial-card {
          background: #fff;
          border-radius: 16px;
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
          border: 1px solid rgba(232, 53, 129, 0.1);
          transition: all 0.3s ease;
          height: 300px;
          display: flex;
          flex-direction: column;
          position: relative;
          overflow: hidden;
          background: linear-gradient(135deg, #ffffff 0%, #fcf5f8 100%);
        }
        
        .testimonial-card::before {
          content: '"';
          position: absolute;
          top: -20px;
          right: 20px;
          font-size: 120px;
          font-family: Georgia, serif;
          color: rgba(232, 53, 129, 0.08);
          z-index: 0;
        }
        
        .testimonial-card:hover {
          transform: translateY(-5px);
          box-shadow: 0 8px 30px rgba(232, 53, 129, 0.15);
          border-color: rgba(232, 53, 129, 0.3);
        }
        
        .testimonial-text {
          color: #555;
          line-height: 1.7;
          font-style: italic;
          font-size: 0.95rem;
          position: relative;
          z-index: 1;
          flex-grow: 1;
          overflow: hidden;
          display: -webkit-box;
          -webkit-line-clamp: 4;
          -webkit-box-orient: vertical;
        }
        
        .rating {
          display: flex;
          gap: 4px;
        }
        
        .rating .text-warning {
          color: #ffd700 !important;
        }
        
        .vendor-info {
          border-top: 1px solid rgba(232, 53, 129, 0.1);
          padding-top: 12px;
          margin-top: auto;
        }
        
        .vendor-info small {
          color: #e83581 !important;
          font-size: 0.85rem;
        }
        
        .swiper-pagination {
          position: relative;
          margin-top: 30px;
        }
        
        .swiper-pagination-bullet {
          width: 10px;
          height: 10px;
          background: rgba(232, 53, 129, 0.2);
          opacity: 1;
          transition: all 0.3s ease;
        }
        
        .swiper-pagination-bullet-active {
          background: #e83581;
          width: 24px;
          border-radius: 5px;
        }
        
        @media (max-width: 768px) {
          .testimonial-card {
            height: 320px;
          }
        }
        
        @media (max-width: 576px) {
          .testimonial-card {
            height: auto;
            min-height: 300px;
          }
        }
      `}</style>
    </section>
  );
};

export default TestimonialsSection;
