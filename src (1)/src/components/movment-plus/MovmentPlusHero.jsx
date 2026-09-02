import React, { useState } from "react";
import "./movment-plus.css";
import { Link } from "react-router-dom";

const MovmentPlusHero = () => {
  const heroImages = [
    {
      id: 1,
      url: "https://i.pinimg.com/736x/e8/49/ec/e849ec05e7e63c5f52881cd3613702fd.jpg",
      alt: "Bride in pink ombre lehenga",
    },
    {
      id: 2,
      url: "https://i.pinimg.com/736x/e0/b4/ef/e0b4ef360abfccb97770aa963b284180.jpg",
      alt: "Wedding couple",
    },
  ];

  return (
    <section className="hero_5k8m3">
      <div className="container-fluid px-3 px-md-5 py-5">
        <div className="row">
          <div className="col-12">
            <div className="hero_wrapper_8x4n2">
              {/* Left Content Section */}
              <div className="hero_content_2n7j9">
                <p className="hero_title_4w8p1">
                  Every Wedding Moment, Perfectly Delivered.
                </p>

                <p className="hero_subtitle_6k2m8">
                  View photos shared by your photographer
                </p>

                <Link
                  to="/movment-plus/guest-token"
                  className="cta_btn_9j4l2 text-decoration-none"
                >
                  <span>Have a private access code?</span>
                  <svg
                    width="24"
                    height="24"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                  >
                    <path d="M5 12h14M12 5l7 7-7 7" />
                  </svg>
                </Link>
              </div>

              {/* Right Images Section */}
              <div className="hero_images_3m5k7">
                <div className="img_container_1_8p3k9">
                  <img
                    src={heroImages[0].url}
                    alt={heroImages[0].alt}
                    className="hero_img_1_5n2w4 rounded-0"
                  />
                </div>
                <div className="img_container_2_7k9m1">
                  <img
                    src={heroImages[1].url}
                    alt={heroImages[1].alt}
                    className="hero_img_2_3j8p6 rounded-0"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
export default MovmentPlusHero;
