import React from "react";
import { FaStar } from "react-icons/fa6";

const SmartPhotoSharing = () => {
  const features = [
    {
      id: 1,
      text: "Get photos privately",
    },
    {
      id: 2,
      text: "Get your photos on Email / WhatsApp",
    },
  ];

  return (
    <section className="smart_photo_section_9k3m7">
      {/* Background Image */}
      <div className="bg_image_overlay_5n8w2"></div>

      <div className="container px-3 px-md-4 px-lg-5">
        <div className="row justify-content-center">
          <div className="col-12 col-lg-10 col-xl-9">
            <div className="content_card_7j2k9">
              <div className="red-border_7j2k0"></div>
              {/* Heading */}
              <h2 className="card_heading_4m8p6">
                Smart photo sharing powered by AI
              </h2>

              {/* Features List */}
              <ul className="features_list_3k9n5">
                {features.map((feature) => (
                  <li key={feature.id} className="feature_item_8w2m4">
                    <FaStar className="star_icon_6p3k7" />
                    <span className="feature_text_5k7m2">{feature.text}</span>
                  </li>
                ))}
              </ul>

              {/* CTA Button */}
              <button className="signup_btn_2n9k8">Free Signup</button>
            </div>
          </div>
        </div>
      </div>

      <style>{`
        .smart_photo_section_9k3m7 {
          position: relative;
          min-height: 600px;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 80px 0;
          overflow: hidden;
          background-image: url('https://images.unsplash.com/photo-1610173826608-bd1f53a52db1?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D');
          background-size: cover;
          background-position: center;
          background-repeat: no-repeat;
        }

        .bg_image_overlay_5n8w2 {
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.15);
          z-index: 1;
        }

        .container {
          position: relative;
          z-index: 2;
        }

        .content_card_7j2k9 {
          background: rgba(255, 255, 255, 0.8);
          backdrop-filter: blur(0px);
          -webkit-backdrop-filter: blur(10px);
          padding: 60px 50px;
          text-align: center;
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
        }

        .red-border_7j2k0 {
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          margin:1rem;
          border: 1px solid #FF0000;
          pointer-events: none;
        }

        .card_heading_4m8p6 {
          font-size: 42px;
          font-weight: 700;
          color: #d81b60;
          margin-bottom: 48px;
          line-height: 1.3;
        }

        .features_list_3k9n5 {
          list-style: none;
          padding: 0;
          margin: 0 0 48px 0;
        }

        .feature_item_8w2m4 {
          padding: 0 1.5rem;
          display: flex;
          align-items: center;
          justify-content: start;
          gap: 20px;
          margin-bottom: 24px;
          font-size: 22px;
          color: #1a1a1a;
          font-weight: 500;
        }

        .feature_item_8w2m4:last-child {
          margin-bottom: 0;
        }

        .star_icon_6p3k7 {
          color: #d81b60;
          flex-shrink: 0;
        } 

        .signup_btn_2n9k8 {
          background: linear-gradient(135deg, #d81b60 0%, #c2185b 100%);
          color: white;
          border: none;
          padding: 10px 60px;
          font-size: 18px;
          font-weight: 500;
          border-radius: 10px;
          cursor: pointer;
          transition: all 0.3s ease;
          box-shadow: 0 6px 24px rgba(216, 27, 96, 0.4);
          margin-top: 12px;
        }

        .signup_btn_2n9k8:hover {
          transform: translateY(-3px);
          box-shadow: 0 8px 30px rgba(216, 27, 96, 0.5);
          background: linear-gradient(135deg, #e91e63 0%, #d81b60 100%);
        }

        .signup_btn_2n9k8:active {
          transform: translateY(-1px);
        }

        /* Responsive Styles */
        @media (max-width: 1199px) {
          .smart_photo_section_9k3m7 {
            min-height: 550px;
            padding: 70px 0;
          }

          .content_card_7j2k9 {
            padding: 50px 40px;
          }

          .card_heading_4m8p6 {
            font-size: 38px;
            margin-bottom: 40px;
          }

          .feature_item_8w2m4 {
            font-size: 20px;
          }
        }

        @media (max-width: 991px) {
          .smart_photo_section_9k3m7 {
            min-height: 500px;
            padding: 60px 0;
          }

          .content_card_7j2k9 {
            padding: 45px 35px;
          }

          .card_heading_4m8p6 {
            font-size: 34px;
            margin-bottom: 36px;
          }

          .feature_item_8w2m4 {
            font-size: 19px;
            margin-bottom: 20px;
          }

          .features_list_3k9n5 {
            margin-bottom: 40px;
          }

          .signup_btn_2n9k8 {
            padding: 16px 50px;
            font-size: 17px;
          }
        }

        @media (max-width: 767px) {
          .smart_photo_section_9k3m7 {
            min-height: 450px;
            padding: 50px 0;
          }

          .content_card_7j2k9 {
            padding: 40px 30px;
          }

          .card_heading_4m8p6 {
            font-size: 30px;
            margin-bottom: 32px;
          }

          .feature_item_8w2m4 {
            font-size: 18px;
            gap: 12px;
          }

          .star_icon_6p3k7 {
            width: 28px;
            height: 28px;
          }

          .signup_btn_2n9k8 {
            padding: 15px 45px;
            font-size: 16px;
          }
        }

        @media (max-width: 575px) {
          .smart_photo_section_9k3m7 {
            min-height: 400px;
            padding: 40px 0;
          }

          .content_card_7j2k9 {
            padding: 35px 24px;
          }

          .card_heading_4m8p6 {
            font-size: 26px;
            margin-bottom: 28px;
          }

          .feature_item_8w2m4 {
            font-size: 16px;
            flex-direction: row;
            text-align: left;
            justify-content: flex-start;
            margin-bottom: 16px;
          }

          .star_icon_6p3k7 {
            width: 24px;
            height: 24px;
          }

          .signup_btn_2n9k8 {
            width: 100%;
            padding: 14px 36px;
            font-size: 16px;
          }
        }
      `}</style>
    </section>
  );
};

export default SmartPhotoSharing;
