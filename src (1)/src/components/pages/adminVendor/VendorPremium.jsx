import React, { useState, useEffect } from "react";
import { FaCheck } from "react-icons/fa";

import {
  FiFileText,
  FiUsers,
  FiEdit,
  FiCheck,
  FiMail,
  FiPhone,
  FiEye,
  FiShield,
  FiHeadphones,
  FiTrendingUp,
  FiStar,
  FiTarget,
  FiAward,
  FiCheckCircle,
} from "react-icons/fi";

const VendorPremium = () => {
  const [selectedPackage, setSelectedPackage] = useState(1);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    setIsVisible(true);
  }, []);

  const benefitsData = [
    {
      icon: FiTarget,
      title: "Strategic Positioning",
      description:
        "Position your business strategically in front of couples actively searching for wedding services in your area.",
    },
    {
      icon: FiUsers,
      title: "Quality Leads",
      description:
        "Receive high-quality leads with complete contact information delivered directly to your inbox for faster response.",
    },
    {
      icon: FiTrendingUp,
      title: "Increased Bookings",
      description:
        "Connect with engaged couples ready to book, helping you secure more weddings and grow your business consistently.",
    },
  ];

  const packagesData = [
    {
      id: 0,
      name: "Starter",
      type: "BASIC",
      color: "linear-gradient(135deg, #fd7e14, #e85d04)",
      textColor: "white",
      popular: false,
      features: [
        "Create your business profile",
        "Basic listing visibility",
        "Receive inquiries via email",
        "Standard customer support",
      ],
    },
    {
      id: 1,
      name: "Professional",
      type: "PREMIUM",
      color: "linear-gradient(135deg, #fd7e14, #e85d04)",
      textColor: "white",
      popular: true,
      features: [
        "Enhanced business profile with gallery",
        "Priority listing in search results",
        "Verified business badge",
        "Lead notifications via email & SMS",
        "Display contact details prominently",
        "Remove competitor advertisements",
        "Dedicated account manager support",
        "Featured placement in category",
      ],
    },
    {
      id: 2,
      name: "Elite",
      type: "PLATINUM",
      color: "linear-gradient(135deg, #fd7e14, #e85d04)",
      textColor: "white",
      popular: false,
      features: [
        "Premium business showcase",
        "Top 3 guaranteed placement",
        "Verified premium badge",
        "Priority lead distribution",
        "Instant lead notifications",
        "Complete ad-free experience",
        "Personal success consultant",
        "Exclusive promotional opportunities",
        "Advanced analytics dashboard",
      ],
    },
  ];

  return (
    <>
      <style jsx>{`
        .services-container {
          min-height: 100vh;
          padding: 60px 0;
        }

        .section-header {
          opacity: 0;
          transform: translateY(30px);
          animation: fadeInUp 0.8s ease forwards;
        }

        .benefit-card {
          background: white;
          border-radius: 20px;
          border: none;
          transition: all 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94);
          opacity: 0;
          transform: translateY(40px);
          animation: fadeInUp 0.6s ease forwards;
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
        }

        .benefit-card:nth-child(1) {
          animation-delay: 0.1s;
        }
        .benefit-card:nth-child(2) {
          animation-delay: 0.3s;
        }
        .benefit-card:nth-child(3) {
          animation-delay: 0.5s;
        }

        .benefit-card:hover {
          transform: translateY(-10px);
          box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
        }

        .benefit-icon {
          background: linear-gradient(135deg, #fd7e14, #e85d04);
          color: white;
          width: 70px;
          height: 70px;
          border-radius: 18px;
          display: flex;
          align-items: center;
          justify-content: center;
          margin-bottom: 20px;
          transition: all 0.3s ease;
        }

        .benefit-card:hover .benefit-icon {
          transform: rotate(5deg) scale(1.1);
        }

        .packages-section {
          margin-top: 80px;
        }

        .package-card {
          background: white;
          border-radius: 25px;
          border: none;
          position: relative;
          transition: all 0.5s cubic-bezier(0.25, 0.46, 0.45, 0.94);
          opacity: 0;
          transform: translateY(50px) scale(2);
          animation: packageAppear 0.8s ease forwards;
          overflow: hidden;
        }

        .package-card:nth-child(1) {
          animation-delay: 0.2s;
        }
        .package-card:nth-child(2) {
          animation-delay: 0.4s;
        }
        .package-card:nth-child(3) {
          animation-delay: 0.6s;
        }

        .package-card:hover {
          transform: translateY(-15px) scale(2);

          box-shadow: 0 25px 50px rgba(0, 0, 0, 0.2);
        }

        .package-header {
          padding: 30px 25px 20px;
          border-radius: 25px 25px 0 0;
          position: relative;
          overflow: hidden;
        }

        .package-header::before {
          content: "";
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: inherit;
          opacity: 0.9;
        }

        .package-content {
          position: relative;
          z-index: 2;
        }

        .package-name {
          font-size: 2rem;
          font-weight: 700;
          margin-bottom: 5px;
          text-transform: uppercase;
          letter-spacing: 1px;
        }

        .package-type {
          font-size: 0.9rem;
          font-weight: 600;
          opacity: 0.9;
          letter-spacing: 2px;
        }

        .popular-badge {
          position: absolute;
          top: -5px;
          right: 20px;
          background: linear-gradient(135deg, #28a745, #20c997);
          color: white;
          padding: 8px 20px;
          border-radius: 0 0 15px 15px;
          font-weight: 600;
          font-size: 0.8rem;
          letter-spacing: 1px;
          box-shadow: 0 5px 15px rgba(40, 167, 69, 0.4);
        }

        .feature-list {
          padding: 30px 25px;
        }

        .feature-item {
          display: flex;
          align-items: center;
          padding: 12px 0;
          border-bottom: 1px solid #f8f9fa;
          transition: all 0.3s ease;
          opacity: 0;
          transform: translateX(-20px);
          animation: slideInLeft 0.5s ease forwards;
        }

        .feature-item:nth-child(1) {
          animation-delay: 0.8s;
        }
        .feature-item:nth-child(2) {
          animation-delay: 0.9s;
        }
        .feature-item:nth-child(3) {
          animation-delay: 1s;
        }
        .feature-item:nth-child(4) {
          animation-delay: 1.1s;
        }
        .feature-item:nth-child(5) {
          animation-delay: 1.2s;
        }
        .feature-item:nth-child(6) {
          animation-delay: 1.3s;
        }
        .feature-item:nth-child(7) {
          animation-delay: 1.4s;
        }
        .feature-item:nth-child(8) {
          animation-delay: 1.5s;
        }
        .feature-item:nth-child(9) {
          animation-delay: 1.6s;
        }

        .feature-item:hover {
          background: linear-gradient(90deg, #f8f9fa, transparent);
          transform: translateX(5px);
        }

        .feature-item:last-child {
          border-bottom: none;
        }

        .feature-icon {
          width: 24px;
          height: 24px;
          border: 2px solid #fd7e14;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          margin-right: 15px;
          background: rgba(253, 126, 20, 0.1);
        }

        .contact-btn {
          background: linear-gradient(135deg, #fd7e14, #e85d04);
          border: none;
          color: white;
          padding: 15px 30px;
          border-radius: 50px;
          font-weight: 600;
          letter-spacing: 1px;
          margin: 20px 25px 30px;
          transition: all 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94);
          position: relative;
          overflow: hidden;
        }

        .contact-btn::before {
          content: "";
          position: absolute;
          top: 0;
          left: -100%;
          width: 100%;
          height: 100%;
          background: linear-gradient(
            90deg,
            transparent,
            rgba(255, 255, 255, 0.2),
            transparent
          );
          transition: left 0.5s;
        }

        .contact-btn:hover::before {
          left: 100%;
        }

        .contact-btn:hover {
          transform: translateY(-3px);
          box-shadow: 0 15px 30px rgba(253, 126, 20, 0.4);
          background: linear-gradient(135deg, #e85d04, #d63384);
          color: white;
        }

        .floating-elements {
          position: absolute;
          width: 100%;
          height: 100%;
          overflow: hidden;
          pointer-events: none;
        }

        .floating-circle {
          position: absolute;
          border-radius: 50%;
          background: linear-gradient(
            135deg,
            rgba(253, 126, 20, 0.1),
            rgba(232, 93, 4, 0.1)
          );
          animation: float 6s ease-in-out infinite;
        }

        .floating-circle:nth-child(1) {
          width: 80px;
          height: 80px;
          top: 10%;
          left: 10%;
          animation-delay: 0s;
        }

        .floating-circle:nth-child(2) {
          width: 60px;
          height: 60px;
          top: 60%;
          right: 10%;
          animation-delay: -2s;
        }

        .floating-circle:nth-child(3) {
          width: 100px;
          height: 100px;
          bottom: 10%;
          left: 50%;
          animation-delay: -4s;
        }

        @keyframes fadeInUp {
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }

        @keyframes packageAppear {
          to {
            opacity: 1;
            transform: translateY(0) scale(1);
          }
        }

        @keyframes slideInLeft {
          to {
            opacity: 1;
            transform: translateX(0);
          }
        }

        @keyframes float {
          0%,
          100% {
            transform: translateY(0px) rotate(0deg);
          }
          50% {
            transform: translateY(-20px) rotate(180deg);
          }
        }

        .section-title {
          background: linear-gradient(135deg, #fd7e14, #e85d04);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
          font-weight: 800;
        }

        .section-subtitle {
          color: #6c757d;
          font-weight: 500;
        }

        @media (max-width: 768px) {
          .package-card {
            margin-bottom: 30px;
          }

          .benefit-card {
            margin-bottom: 20px;
          }
        }
      `}</style>

      <div className="services-container position-relative">
        <div className="floating-elements">
          <div className="floating-circle"></div>
          <div className="floating-circle"></div>
          <div className="floating-circle"></div>
        </div>

        <div className="container">
          <div className="section-header text-center mb-5 d-flex flex-column">
            <h1 className="section-title mb-3 display-5">
              Why Choose WeddingPro
            </h1>
            <p className="lead section-subtitle">
              Discover what we can offer to grow your wedding business
            </p>
          </div>

          <div className="row g-4 mb-5">
            {benefitsData.map((benefit, index) => (
              <div key={index} className="col-lg-4 col-md-6">
                <div className="benefit-card card h-100 p-4 text-center">
                  <div className="benefit-icon mx-auto">
                    <benefit.icon size={28} />
                  </div>
                  <h4 className="card-title justify-content-center text-center fw-bold mb-3">
                    {benefit.title}
                  </h4>
                  <p className="card-text text-muted">{benefit.description}</p>
                </div>
              </div>
            ))}
          </div>

          <div className="packages-section">
            <div className="text-center mb-5">
              <h2 className="display-5 section-title mb-3">
                WeddingPro Services
              </h2>
              <p className="lead section-subtitle">
                Choose the perfect plan that fits your business needs
              </p>
            </div>

            <div className="row g-4">
              {packagesData.map((pkg) => (
                <div key={pkg.id} className="col-lg-4 col-md-6">
                  <div className="package-card card h-100 position-relative">
                    {pkg.popular && (
                      <div className="popular-badge">
                        <FiStar className="me-1" />
                        MOST POPULAR
                      </div>
                    )}

                    <div
                      className="package-header text-center"
                      style={{ background: pkg.color }}
                    >
                      <div className="package-content">
                        <h3
                          className="package-name"
                          style={{ color: pkg.textColor }}
                        >
                          {pkg.name}
                        </h3>
                        <p
                          className="package-type mb-0"
                          style={{ color: pkg.textColor }}
                        >
                          {pkg.type}
                        </p>
                      </div>
                    </div>

                    <div className="feature-list">
                      {pkg.features.map((feature, index) => (
                        <div key={index} className="feature-item">
                          <div className="feature-icon">
                            <FaCheck />
                          </div>
                          <span className="text-dark">{feature}</span>
                        </div>
                      ))}
                    </div>

                    <button className="contact-btn w-auto">Get Started</button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default VendorPremium;
