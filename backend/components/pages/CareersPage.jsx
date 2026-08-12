import React, { useState } from "react";

const CareersPage = () => {
  const [activeTab, setActiveTab] = useState("technology");
  const [slideDirection, setSlideDirection] = useState("none");

  const handleTabChange = (tab) => {
    if (tab !== activeTab) {
      setSlideDirection(tab === "technology" ? "right" : "left");
      setTimeout(() => {
        setActiveTab(tab);
        setSlideDirection("none");
      }, 300);
    }
  };

  const commonContainerStyle = {
    maxWidth: "900px",
    transition: "all 0.3s ease-in-out",
    position: "relative",
  };

  const slideLeft = {
    transform: "translateX(-100%)",
    opacity: 0,
  };
  const slideRight = {
    transform: "translateX(100%)",
    opacity: 0,
  };
  const slideIn = {
    transform: "translateX(0)",
    opacity: 1,
  };

  return (
    <div>
      <div
        style={{
          position: "relative",
          backgroundImage:
            "url('https://images.unsplash.com/photo-1557804506-669a67965ba0?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1074')",
          backgroundSize: "cover",
          backgroundPosition: "center",
          color: "#fff",
          textAlign: "center",
          height: "70vh",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          alignItems: "center",
        }}
      >
        <div
          style={{
            position: "absolute",
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: "rgba(0, 0, 0, 0.7)",
            zIndex: 1,
          }}
        />

        <div
          style={{
            position: "relative",
            zIndex: 2,
            padding: "0 20px",
            textAlign: "center",
            maxWidth: "800px",
          }}
        >
          <h1
            style={{
              fontWeight: "bold",
              fontSize: "2.5rem",
              marginBottom: "15px",
            }}
          >
            HappyWedz Careers
          </h1>
          <p className="fs-16 mb-2">
            We are a team of killer enthusiasts, aiming to re-build the wedding
            space.
          </p>
          <p className="fs-16 mb-2">
            If you care about weddings, technology & innovation, then you could
            be the one we are looking for.
          </p>
        </div>

        <div
          style={{
            position: "absolute",
            bottom: "30px",
            left: "30%",
            transform: "translateX(-50%)",
            display: "flex",
            gap: "40px",
            fontWeight: "600",
            fontSize: "18px",
            zIndex: 3,
          }}
        >
          <button
            onClick={() => handleTabChange("technology")}
            className="fs-16"
            style={{
              background: "none",
              border: "none",
              color: activeTab === "technology" ? "#fff" : "#f8f9fa",
              borderBottom:
                activeTab === "technology"
                  ? "3px solid #d63384"
                  : "3px solid transparent",
              paddingBottom: "6px",
              cursor: "pointer",
              transition: "0.3s",
            }}
          >
            TECHNOLOGY
          </button>

          <button
            onClick={() => handleTabChange("business")}
            className="fs-16"
            style={{
              background: "none",
              border: "none",
              color: activeTab === "business" ? "#fff" : "#f8f9fa",
              borderBottom:
                activeTab === "business"
                  ? "3px solid #d63384"
                  : "3px solid transparent",
              paddingBottom: "6px",
              cursor: "pointer",
              transition: "0.3s",
            }}
          >
            BUSINESS
          </button>
        </div>
      </div>

      {/* Animated Job Section */}
      <div className="container my-5" style={commonContainerStyle}>
        <div
          style={{
            ...commonContainerStyle,
            ...(slideDirection === "left"
              ? slideLeft
              : slideDirection === "right"
              ? slideRight
              : slideIn),
          }}
        >
          {activeTab === "technology" ? (
            <>
              {/* ===== Job 1 ===== */}
              <h4 style={{ fontWeight: "600" }}>AI Product Research Intern</h4>
              <p className="fs-16 mb-2">
                We’re looking for an enthusiastic intern who loves exploring the
                world of artificial intelligence. You’ll work with the product
                team to research AI tools, analyze market trends, and assist in
                building demo prototypes for new product concepts.
              </p>

              <p className="fs-16 mb-2 fw-bolder">Key Responsibilities :</p>
              <ul style={{ lineHeight: "1.8" }} className="fs-14 mb-2">
                <li>
                  Assist in researching emerging AI and automation technologies
                </li>
                <li>
                  Collect, clean, and organize sample datasets for product
                  testing
                </li>
                <li>
                  Collaborate with product designers to brainstorm new feature
                  ideas and user flows
                </li>
                <li>
                  Prepare short reports and competitor summaries for internal
                  review
                </li>
              </ul>

              <p className="fs-16 mb-2 fw-bolder">
                Desired Skills and Experience :
              </p>
              <ul style={{ lineHeight: "1.8" }} className="fs-14 mb-2">
                <li>Basic understanding of AI/ML concepts or APIs</li>
                <li>
                  Comfortable with Google Sheets or data visualization tools
                </li>
                <li>Good written and communication skills</li>
                <li>Ability to work independently and learn quickly</li>
                <li>
                  Students from technical or business backgrounds preferred
                </li>
              </ul>

              <p className="fs-16 my-4">
                <strong>Location :</strong> Remote / Hybrid
              </p>
            </>
          ) : (
            <>
              <h4 style={{ fontWeight: "600" }}>Creative Content Strategist</h4>
              <p className="fs-16 mb-2">
                We’re seeking a creative storyteller who can craft engaging
                campaigns for our digital products. You’ll help shape how users
                discover, understand, and connect with our brand through social
                media, blogs, and newsletters.
              </p>

              <p className="fs-16 mb-2 fw-bolder">Key Responsibilities :</p>
              <ul style={{ lineHeight: "1.8" }} className="fs-14 mb-2">
                <li>
                  Develop creative content strategies to enhance user engagement
                  across platforms
                </li>
                <li>
                  Write compelling copy for product pages, campaigns, and blog
                  content
                </li>
                <li>
                  Work with designers and marketing teams to maintain a
                  consistent brand tone
                </li>
                <li>Research new trends and formats in digital storytelling</li>
              </ul>

              <p className="fs-16 mb-2 fw-bolder">
                Desired Skills and Experience :
              </p>
              <ul style={{ lineHeight: "1.8" }} className="fs-14 mb-2">
                <li>
                  1–3 years of experience in content writing or brand strategy
                </li>
                <li>
                  Excellent command of English and storytelling techniques
                </li>
                <li>
                  Strong attention to detail and understanding of audience
                  behavior
                </li>
                <li>Experience with SEO or basic analytics is a plus</li>
                <li>Creative mindset with strong execution ability</li>
              </ul>

              <p className="fs-16 my-4">
                <strong>Location :</strong> Mumbai / Remote
              </p>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default CareersPage;
