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
        className="container ui-card"
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
        <div className="row">
          <div className="col-12 col-md-2 col-lg-1 text-md-end mb-3 mb-md-0">
            <img
              src={logo}
              alt="Logo"
              width="120"
              height="120"
              loading="lazy"
              decoding="async"
              className="object-fit-cover"
              /* Fixed square box + contain: the CMS logo can be any aspect
                 ratio, and letterboxing it is preferable to resizing the row. */
              style={{ width: "120px", height: "120px", objectFit: "contain" }}
            />
          </div>

          <div className="col-12 col-md-7 mb-3 mb-md-0 d-flex flex-column">
            {heading && (
              <h2
                className="mb-3 fw-bold home-cta-section-heading text-decoration-none cta-clamp"
                style={{ "--lines": 2 }}
              >
                {heading}
              </h2>
            )}
            {subHeading && (
              <div
                className="my-3 home-cta-section-sub-heading fs-18 cta-clamp"
                style={{ "--lines": 2 }}
              >
                {subHeading}
              </div>
            )}
            {title && (
              <div
                className="fw-bold mb-2 mt-2 fs-18 cta-clamp"
                style={{ "--lines": 2 }}
              >
                {title}
              </div>
            )}
            {subtitle && (
              <p className="mb-3 fs-16 cta-clamp" style={{ "--lines": 3 }}>
                {subtitle}
              </p>
            )}
            {btnName && link && (
              <div className="d-flex justify-content-center justify-content-md-end w-100 mt-auto mt-3">
                <Link to={link} className="w-100" style={{ maxWidth: "400px" }}>
                  <button
                    className="btn w-100 px-4 py-2"
                    style={{
                      backgroundColor: "#C31162",
                      color: "#fff",
                      minWidth: "200px",
                    }}
                  >
                    {btnName}
                  </button>
                </Link>
              </div>
            )}
          </div>

          <div className="col-12 col-md-3 text-center text-md-start">
            {/* The width/height attributes only reserve the box until the image
                loads; after that `img-fluid`'s height:auto re-derives the height
                from the *real* aspect ratio, and `img` here is a CMS URL whose
                dimensions are unknown — so the panel resized the moment the
                banner API responded. A hard aspect-ratio plus object-fit:cover
                keeps the box identical whatever the CMS returns. */}
            <img
              src={img}
              alt="CTA"
              width="600"
              height="563"
              loading="lazy"
              decoding="async"
              className="img-fluid rounded w-100"
              style={{ objectFit: "cover", aspectRatio: "600 / 563" }}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default CtaPanel;
