import React from "react";
import { motion } from "framer-motion";

const Brands = () => {
  const logos = [
    "/trust/dtf1.jpeg",
    "/trust/justclick.jpeg",
    "/trust/kanhiyaa.jpeg",
    "/trust/sn.jpeg",
    "/trust/tp.jpeg",
    "/logo-no-bg.png",
  ];

  return (
    <div className="brands_section_7k3m9 my-5">
      <div className="container-fluid px-0">
        <div className="position-relative overflow-hidden brands_container_4n8x2">
          <div className="gradient_overlay_left_2p9k1"></div>

          <h3 className="text-center text-uppercase fw-bold mb-5">
            Loved By 4,000+ Businesses Wordwide
          </h3>

          <div className="gradient_overlay_right_5m7j4"></div>

          <motion.div
            className="d-flex brands_slider_8w2n6 pt-5"
            animate={{ x: ["0%", "-50%"] }}
            transition={{
              repeat: Infinity,
              ease: "linear",
              duration: 30,
            }}
          >
            {[...logos, ...logos].map((logo, index) => (
              <div key={index} className="brand_item_3k9m5">
                <img
                  src={logo}
                  alt={`Company Logo ${index + 1}`}
                  className="brand_logo_6j2p8"
                />
              </div>
            ))}
          </motion.div>
        </div>
      </div>

      <style>{`
        .brands_section_7k3m9 {
          padding: 60px 0;
          background-color: #ffffff;
        }

        .brands_container_4n8x2 {
          position: relative;
          overflow: hidden;
        }

        .gradient_overlay_left_2p9k1,
        .gradient_overlay_right_5m7j4 {
          position: absolute;
          top: 0;
          bottom: 0;
          width: 100px;
          z-index: 10;
          pointer-events: none;
        }

        .gradient_overlay_left_2p9k1 {
          left: 0;
          background: linear-gradient(to right, rgba(255, 255, 255, 1) 0%, rgba(255, 255, 255, 0) 100%);
        }

        .gradient_overlay_right_5m7j4 {
          right: 0;
          background: linear-gradient(to left, rgba(255, 255, 255, 1) 0%, rgba(255, 255, 255, 0) 100%);
        }

        .brands_slider_8w2n6 {
          display: flex;
          gap: 100px;
          width: fit-content; /* Ensure width wraps content for correct percentage calculation */
        }

        .brand_item_3k9m5 {
          flex-shrink: 0;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .brand_logo_6j2p8 {
          height: 80px;
          width: auto;
          max-width: 180px;
          object-fit: contain;  
          transition: all 0.3s ease;
        }

        .brand_logo_6j2p8:hover {
          filter: grayscale(0%);
          opacity: 1;
          transform: scale(1.05);
        }

        @media (max-width: 991px) {
          .brands_section_7k3m9 {
            padding: 40px 0;
          }

          .gradient_overlay_left_2p9k1,
          .gradient_overlay_right_5m7j4 {
            width: 60px;
          }

          .brands_slider_8w2n6 {
            gap: 36px;
          }

          .brand_logo_6j2p8 {
            height: 40px;
            max-width: 140px;
          }
        }

        @media (max-width: 767px) {
          .brands_section_7k3m9 {
            padding: 30px 0;
          }

          .gradient_overlay_left_2p9k1,
          .gradient_overlay_right_5m7j4 {
            width: 40px;
          }

          .brands_slider_8w2n6 {
            gap: 28px;
          }

          .brand_logo_6j2p8 {
            height: 36px;
            max-width: 120px;
          }
        }

        @media (max-width: 575px) {
          .brands_slider_8w2n6 {
            gap: 24px;
          }

          .brand_logo_6j2p8 {
            height: 32px;
            max-width: 100px;
          }
        }
      `}</style>
    </div>
  );
};

export default Brands;
