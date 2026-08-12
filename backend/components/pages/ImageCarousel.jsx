import React from "react";
import "bootstrap/dist/css/bootstrap.min.css";

const DestinationWeddingHero = () => {
  return (
    <section style={styles.section}>
      <div className="container">
        <div className="row align-items-start g-5">
          <div className="col-lg-6 col-12" data-aos="fade-right">
            <div style={styles.imageWrapper}>
              <img
                src="https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=900&fit=crop"
                alt="Mountain Destination Wedding"
                style={styles.image}
              />
            </div>
          </div>

          <div className="col-lg-6 col-12" data-aos="fade-left">
            <div style={styles.contentWrapper}>
              <h3 style={styles.mainTitle}>
                Dreaming of a destination wedding?
              </h3>

              <p className="fs-16" style={styles.paragraph}>
                We help you create a flawless and unforgettable celebration at
                your favourite location. From choosing the perfect venue—beach,
                palace, hill station, or luxury resort—to managing décor, guest
                stay, travel, photography, and entertainment, our team handles
                everything with complete care.
              </p>

              <p className="fs-16" style={styles.paragraph}>
                You get budget-friendly packages, verified vendors, and custom
                themes that match your style. Whether it’s Goa, Udaipur, Jaipur,
                Maldives, Dubai, or any international destination, we ensure a
                smooth, stress-free, and beautifully organised wedding
                experience for you and your guests.
              </p>

              <p className="fs-16" style={styles.paragraph}>
                Make your destination wedding magical, memorable, and perfectly
                executed.
              </p>
            </div>
          </div>
        </div>
      </div>

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

        * {
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        }

        @media (max-width: 991px) {
          .row {
            flex-direction: column-reverse;
          }
        }
      `}</style>
    </section>
  );
};

const styles = {
  section: {
    padding: "70px 0",
    backgroundColor: "#FFFFFF",
    minHeight: "70vh",
    display: "flex",
    alignItems: "center",
  },
  imageWrapper: {
    position: "relative",
    borderRadius: "24px",
    overflow: "hidden",
    boxShadow: "0 20px 60px rgba(0, 0, 0, 0.15)",
    aspectRatio: "4/4",
    width: "100%",
    maxWidth: "500px",
    margin: "0 auto",
  },
  image: {
    width: "100%",
    height: "100%",
    objectFit: "cover",
    display: "block",
  },
  contentWrapper: {
    padding: "50px 20px",
  },
  mainTitle: {
    fontSize: "clamp(2rem, 5vw, 3.5rem)",
    fontWeight: "700",
    color: "#1F2937",
    marginBottom: "16px",
    lineHeight: "1.1",
    letterSpacing: "-0.02em",
  },
  subtitle: {
    fontSize: "clamp(1.5rem, 4vw, 2.5rem)",
    fontWeight: "400",
    color: "#374151",
    marginBottom: "32px",
    lineHeight: "1.3",
  },
  paragraph: {
    fontSize: "1rem",
    lineHeight: "1.8",
    color: "#6B7280",
    marginBottom: "24px",
    textAlign: "justify",
  },
};

export default DestinationWeddingHero;
