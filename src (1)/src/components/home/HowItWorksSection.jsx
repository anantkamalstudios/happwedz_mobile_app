import React, { useEffect, useRef } from "react";
import { Container, Row, Col } from "react-bootstrap";

const HowItWorksSection = () => {
  const countRefs = useRef([]);

  // SVG Icons
  const SearchIcon = () => (
    <svg
      width="32"
      height="32"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M21 21L16.514 16.506L21 21ZM19 10.5C19 15.194 15.194 19 10.5 19C5.806 19 2 15.194 2 10.5C2 5.806 5.806 2 10.5 2C15.194 2 19 5.806 19 10.5Z"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );

  const StarIcon = () => (
    <svg
      width="32"
      height="32"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );

  const MessageIcon = () => (
    <svg
      width="32"
      height="32"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M21 15C21 15.5304 20.7893 16.0391 20.4142 16.4142C20.0391 16.7893 19.5304 17 19 17H7L3 21V5C3 4.46957 3.21071 3.96086 3.58579 3.58579C3.96086 3.21071 4.46957 3 5 3H19C19.5304 3 20.0391 3.21071 20.4142 3.58579C20.7893 3.96086 21 4.46957 21 5V15Z"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );

  const HeartIcon = () => (
    <svg
      width="32"
      height="32"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M20.84 4.61C20.3292 4.099 19.7228 3.69364 19.0554 3.41708C18.3879 3.14052 17.6725 2.99817 16.95 2.99817C16.2275 2.99817 15.5121 3.14052 14.8446 3.41708C14.1772 3.69364 13.5708 4.099 13.06 4.61L12 5.67L10.94 4.61C9.9083 3.5783 8.50903 2.9987 7.05 2.9987C5.59096 2.9987 4.19169 3.5783 3.16 4.61C2.1283 5.6417 1.5487 7.04097 1.5487 8.5C1.5487 9.95903 2.1283 11.3583 3.16 12.39L12 21.23L20.84 12.39C21.351 11.8792 21.7563 11.2728 22.0329 10.6053C22.3095 9.93789 22.4518 9.22248 22.4518 8.5C22.4518 7.77752 22.3095 7.06211 22.0329 6.39467C21.7563 5.72723 21.351 5.1208 20.84 4.61Z"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );

  const steps = [
    {
      number: "01",
      title: "Search & Discover",
      description:
        "Browse thousands of verified wedding vendors by category, location, and budget",
      icon: <SearchIcon />,
      color: "#e83581",
    },
    {
      number: "02",
      title: "Compare & Review",
      description:
        "Read genuine reviews, check portfolios, and compare prices from multiple vendors",
      icon: <StarIcon />,
      color: "#ff6b9d",
    },
    {
      number: "03",
      title: "Connect & Book",
      description:
        "Contact vendors directly, get quotes, and book your favorites with confidence",
      icon: <MessageIcon />,
      color: "#ff8fab",
    },
    {
      number: "04",
      title: "Plan & Celebrate",
      description:
        "Work with your chosen vendors to create the perfect wedding day",
      icon: <HeartIcon />,
      color: "#ffb3c6",
    },
  ];

  // Animation function for counting
  const animateCount = (element, target) => {
    let current = 0;
    const increment = target / 50;
    const timer = setInterval(() => {
      current += increment;
      if (current >= target) {
        current = target;
        clearInterval(timer);
      }
      element.textContent = Math.floor(current).toString().padStart(2, "0");
    }, 30);
  };

  // Intersection Observer for animation trigger
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const index = parseInt(entry.target.dataset.index);
            if (countRefs.current[index]) {
              animateCount(countRefs.current[index], index + 1);
            }
          }
        });
      },
      { threshold: 0.5 }
    );

    countRefs.current.forEach((ref) => {
      if (ref) observer.observe(ref);
    });

    return () => observer.disconnect();
  }, []);

  return (
    <>
      <section className="how-it-works-section">
        <div className="container">
          <div className="text-center">
            {/* <button className="cta-button">Start Planning Your Wedding</button> */}
            <h3 className="fw-bold text-dark mb-2">HappyWedz Works</h3>
            <h6
              className="text-muted mb-3"
              data-aos="fade-up"
              data-aos-delay="50"
            >
              Start Planning Your Wedding
            </h6>
          </div>

          <div className="steps-container mt-5">
            <div className="connecting-line"></div>

            {steps.map((step, index) => (
              <div key={index} className="step-card" data-index={index}>
                <div
                  className="step-number-badge"
                  style={{
                    background:
                      "conic-gradient(from 180deg at 50% 50%, #FFB6C1, #FF69B4, #C71585, #FFB6C1)",
                  }}
                >
                  <span
                    ref={(el) => (countRefs.current[index] = el)}
                    className="step-number-animated"
                  >
                    {step.number ? step.number : "00"}
                  </span>
                </div>

                <span className="step-icon">{step.icon}</span>

                <p className="step-title fs-16">{step.title}</p>

                <p className="step-description fs-14">{step.description}</p>

                {index < steps.length - 1 && (
                  <div className="step-arrow">
                    <svg
                      className="arrow-svg"
                      viewBox="0 0 40 40"
                      fill="none"
                      xmlns="http://www.w3.org/2000/svg"
                    >
                      <circle
                        cx="20"
                        cy="20"
                        r="18"
                        fill="white"
                        stroke={step.color}
                        strokeWidth="2"
                      />
                      <path
                        d="M16 14L22 20L16 26"
                        stroke={step.color}
                        strokeWidth="2"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      />
                    </svg>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>
    </>
  );
};

export default HowItWorksSection;
