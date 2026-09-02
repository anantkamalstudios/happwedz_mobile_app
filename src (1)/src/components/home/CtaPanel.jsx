import { Link } from "react-router-dom";

const CtaPanel = ({
  logo,
  img,
  title,
  link,
  subtitle,
  btnName,
  heading,
  subHeading,
  background,
}) => {
  return (
    <div className="home-cta-section my-5">
      <div
        className="container ui-card p-4 p-md-4"
        style={{
          backgroundImage:
            background === "bigleaf"
              ? `linear-gradient(to bottom, #fbcfe8, #f7e0ed, #f8defc), url(${background})`
              : `url(${background})`,
          backgroundSize: "cover",
          backgroundPosition: "center",
          backgroundRepeat: "no-repeat",
        }}
      >
        <div className="row align-items-center">
          {/* Logo */}
          <div className="col-12 col-md-2 col-lg-2 mb-3 mb-md-0 d-flex justify-content-center justify-content-md-center align-items-center">
            <img
              src={logo}
              alt="Logo"
              width="150"
              height="150"
              loading="lazy"
              decoding="async"
              className="object-fit-contain"
              style={{ width: "140px", maxWidth: "100%", height: "auto" }}
            />
          </div>

          {/* Copy content */}
          <div className="col-12 col-md-6 col-lg-6 mb-3 mb-md-0 d-flex flex-column">
            {heading && (
              <h2
                className="mb-1 fw-bold home-cta-section-heading text-decoration-none"
                style={{ fontSize: "1.75rem", color: "#ed1173" }}
              >
                {heading}
              </h2>
            )}
            {subHeading && (
              <div
                className="mb-2 home-cta-section-sub-heading fs-16 fw-semibold"
                style={{ color: "#ed1173" }}
              >
                {subHeading}
              </div>
            )}
            {title && (
              <div className="fw-bold mb-1 fs-18 text-dark">
                {title}
              </div>
            )}
            {subtitle && (
              <p className="mb-3 fs-15 text-muted" style={{ lineHeight: "1.5" }}>
                {subtitle}
              </p>
            )}
            {btnName && link && (
              <div className="d-flex justify-content-start justify-content-md-start w-100 mt-2">
                <Link to={link} className="text-decoration-none">
                  <button
                    className="btn px-4 py-2 fw-semibold"
                    style={{
                      backgroundColor: "#C31162",
                      color: "#fff",
                      minWidth: "180px",
                      borderRadius: "8px",
                      boxShadow: "0 2px 8px rgba(195, 17, 98, 0.2)",
                    }}
                  >
                    {btnName}
                  </button>
                </Link>
              </div>
            )}
          </div>

          {/* Image */}
          <div className="col-12 col-md-3 col-lg-4 text-center text-md-end">
            <img
              src={img}
              alt="CTA"
              width="600"
              height="563"
              loading="lazy"
              decoding="async"
              className="img-fluid rounded-3 shadow-sm"
              style={{ maxHeight: "260px", width: "100%", maxWidth: "320px", objectFit: "cover" }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default CtaPanel;
