import React, { useEffect } from "react";
import Swiper from "swiper/bundle";
import "swiper/css/bundle";
import venues from "../../../data/venue";

const BrideSlider = () => {
  useEffect(() => {
    new Swiper(".venueSwiper", {
      slidesPerView: "auto",
      loop: true,
      speed: 8000,
      spaceBetween: 20,
      autoplay: {
        delay: 0,
        disableOnInteraction: false,
      },
      freeMode: true,
      freeModeMomentum: false,
      breakpoints: {
        0: {
          slidesPerView: 1.2,
        },
        576: {
          slidesPerView: 1.8,
        },
        768: {
          slidesPerView: 2.5,
        },
        992: {
          slidesPerView: 3.2,
        },
      },
    });
  }, []);

  return (
    <div className="container-fluid py-5">
      <div className="d-flex justify-content-around align-items-center">
        <div className="col-md-10">
          <h3 className="fw-bold mb-4 text-dark">Bride Wedding Photography</h3>
        </div>
        <div className="col-md-2 ">
          <a href="" className="text-decoration-none">
            <h6 className="fw-bold mb-4 text-dark">
              View All Venue
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                className="primary-text lucide lucide-chevron-right-icon lucide-chevron-right"
              >
                <path d="m9 18 6-6-6-6" />
              </svg>
            </h6>
          </a>
        </div>
      </div>

      <div className="swiper venueSwiper">
        <div className="venue-swiper-wrapper swiper-wrapper">
          {venues.map((venue, index) => (
            <div
              className="swiper-slide"
              key={index}
              style={{ width: "250px" }}
            >
              <div className="card border-0 shadow-sm rounded-4 overflow-hidden">
                <img
                  src={venue.image}
                  className="card-img-top rounded-4 venues-swiper-img"
                  alt={venue.name}
                />
                <div className="row">
                  <div className="d-flex">
                    <div className="card-body">
                      <h6 className="card-title fw-bold mb-1">{venue.name}</h6>
                      <p className="card-text text-muted small">
                        {venue.location}
                      </p>
                    </div>
                    <div className="card-body text-end">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        width="18"
                        height="18"
                        viewBox="0 0 24 24"
                        fill="orange"
                        stroke="orange"
                        strokeWidth="2"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        className="lucide lucide-star-icon lucide-star"
                      >
                        <path d="M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z" />
                      </svg>
                      <span className="small">5.0</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default BrideSlider;
