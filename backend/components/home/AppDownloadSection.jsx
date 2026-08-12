import React, { useEffect, useState } from "react";
const AppDownloadSection = () => {
  const [isMobile, setIsMobile] = useState(
    typeof window !== "undefined" ? window.innerWidth <= 768 : false
  );

  useEffect(() => {
    const onResize = () => setIsMobile(window.innerWidth <= 768);
    if (typeof window !== "undefined") {
      window.addEventListener("resize", onResize);
    }
    return () => {
      if (typeof window !== "undefined") {
        window.removeEventListener("resize", onResize);
      }
    };
  }, []);

  const sectionStyle = {
    background:
      "linear-gradient(90deg, rgba(237,17,115,0.08) 0%, rgba(237,17,115,0.02) 100%)",
    backgroundImage: isMobile ? "none" : "url('/images/home/cta1.jpg')",
    backgroundSize: isMobile ? "" : "contain",
    backgroundRepeat: "no-repeat",
    backgroundPosition: "bottom",
    overflow: "hidden",
  };

  return (
    <section className="container-fluid rounded py-5 mb-5" style={sectionStyle}>
      <div className="container d-flex flex-column flex-lg-row align-items-center justify-content-center">
        <div className={`col-12 ${isMobile ? "text-center" : "col-lg-6"}`}>
          <div className="rounded-3">
            <h6 className="fw-bold mb-3 fs-20 text-center">
              Download The HappyWedz Mobile App Today
            </h6>
            <p className="mb-4 fs-14">
              Plan your wedding on the go with the easy-to-use HappyWedz app.
              Discover top vendors, get wedding inspiration, and manage
              everything in one place.
            </p>

            <div className="d-flex flex-wrap justify-content-center gap-3">
              <a
                href="https://play.google.com/store/apps/details?id=com.happy.happy_weds_vendors"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Get HappyWedz App on Google Play Store"
              >
                <img loading="lazy" decoding="async"
                  src="/images/cta/playstore.svg"
                  alt="Google Play"
                  style={{
                    width: isMobile ? "140px" : "180px",
                    height: isMobile ? "48px" : "180px",
                    objectFit: "cover",
                  }}
                />
              </a>
              <a
                href="https://apps.apple.com/app/happywedz/id123456789"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Get HappyWedz App on Apple App Store"
              >
                <img loading="lazy" decoding="async"
                  src="/images/cta/appstore.svg"
                  alt="Apple Store"
                  style={{
                    width: isMobile ? "140px" : "180px",
                    height: isMobile ? "48px" : "180px",
                    objectFit: "cover",
                  }}
                />
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default AppDownloadSection;
