import { Link, useNavigate, useLocation } from "react-router-dom";
import React from "react";
import { useContext, useEffect, useRef } from "react";
import { FaFacebookF, FaInstagram } from "react-icons/fa";
import { MyContext } from "../../context/useContext";

const Footer = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const trustpilotRef = useRef(null);

  const {
    selectedCategory,
    setSelectedCategory,
    selectedCategoryName,
    setSelectedCategoryName,
    types,
  } = useContext(MyContext);

  // The Trustpilot bootstrap script used to sit in index.html as an `async`
  // tag, so it downloaded and ran during page load — Lighthouse attributed
  // ~124ms of forced reflow to it, straight into Total Blocking Time. Load it
  // only once the widget is close to the viewport, which on the home page is
  // well after the user has an interactive page.
  useEffect(() => {
    const el = trustpilotRef.current;
    if (!el) return;

    const render = () => {
      if (window.Trustpilot && trustpilotRef.current) {
        window.Trustpilot.loadFromElement(trustpilotRef.current, true);
      }
    };

    // Script already fetched by an earlier mount — just re-render the widget.
    if (window.Trustpilot) {
      render();
      return;
    }

    const TP_SRC =
      "https://widget.trustpilot.com/bootstrap/v5/tp.widget.bootstrap.min.js";

    const loadScript = () => {
      const existing = document.querySelector(`script[src="${TP_SRC}"]`);
      if (existing) {
        existing.addEventListener("load", render, { once: true });
        return;
      }
      const script = document.createElement("script");
      script.src = TP_SRC;
      script.async = true;
      script.addEventListener("load", render, { once: true });
      document.body.appendChild(script);
    };

    if (typeof IntersectionObserver === "undefined") {
      loadScript();
      return;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((entry) => entry.isIntersecting)) {
          observer.disconnect();
          loadScript();
        }
      },
      { rootMargin: "300px" }
    );
    observer.observe(el);

    return () => observer.disconnect();
  }, [location.pathname]);

  const findCategoryIdByName = (categoryName) => {
    if (!types || !Array.isArray(types)) return null;
    const category = types.find(
      (type) => type.name?.toLowerCase() === categoryName.toLowerCase()
    );
    return category ? category.id : null;
  };

  const handleCategoryClick = (categoryName) => {
    const categoryId = findCategoryIdByName(categoryName);

    if (categoryId) {
      setSelectedCategory(categoryId);
      setSelectedCategoryName(categoryName);

      if (location.pathname === "/photography") {
        // SAME PAGE → JUST SCROLL TO TOP
        window.scrollTo({ top: 0, behavior: "smooth" });
      } else {
        // DIFFERENT PAGE → NAVIGATE
        navigate("/photography");

        // after navigation, scroll to top
        setTimeout(() => {
          window.scrollTo({ top: 0, behavior: "smooth" });
        }, 150);
      }
    }
  };

  return (
    <footer
      className="footer position-relative pt-0 primary-bg text-white"
      style={{
        position: "relative",
        overflow: "hidden",
      }}
    >
      {/* Decorative Top Border */}
      <div
        style={{
          width: "100%",
          height: "4px",
          position: "absolute",
          top: 0,
          left: 0,
        }}
      />

      {/* Subtle Pattern Overlay */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: `
            radial-gradient(circle at 20% 80%, rgba(232, 53, 129, 0.03) 0%, transparent 50%),
            radial-gradient(circle at 80% 20%, rgba(255, 107, 157, 0.03) 0%, transparent 50%),
            radial-gradient(circle at 40% 40%, rgba(232, 53, 129, 0.02) 0%, transparent 50%)
          `,
          pointerEvents: "none",
        }}
      />

      <div className="container" style={{ position: "relative", zIndex: 1 }}>
        <div className="row gy-4">
          {/* === LOGO COLUMN === */}
          <div className="col-12 col-sm-6 col-lg-3">
            <Link
              to="/"
              style={{
                display: "inline-block",
                textDecoration: "none",
              }}
            >
              <img
                src="/images/logo-sm-300.webp"
                alt="HappyWedz Logo"
                width="150"
                height="38"
                loading="lazy"
                decoding="async"
                style={{
                  width: "150px",
                  height: "auto",
                  objectFit: "contain",
                }}
              />
            </Link>

            <p
              className="fs-14"
              style={{
                marginTop: "20px",
                maxWidth: "85%",
                lineHeight: "1.8",
              }}
            >
              29/1B, Sinhgad Rd, next to Vidya Sahakri Bank,
              <br /> Near Veer Baji Pasalkar Chowk, Kirti Nagar, Vadgaon Budruk,
              Pune, Maharashtra 411041
            </p>
          </div>

          {/* === PLAN YOUR WEDDING === */}
          <div className="col-12 col-sm-6 col-lg-3" style={{ color: "#fff" }}>
            <p className="footer-title fs-16">Plan Your Wedding</p>
            <ul className="footer-list">
              <li className="fs-14">
                <Link
                  to="/wedding-venues"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Start Planning
                </Link>
              </li>
              <li className="fs-14">
                <Link
                  to="/vendors"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Search By Vendor
                </Link>
              </li>
              <li className="fs-14">
                <Link
                  to="/wedding-venues"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Search By City
                </Link>
              </li>
              <li className="fs-14">
                <Link
                  to="/top-rated"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Top Rated Vendors
                </Link>
              </li>
              <li className="fs-14">
                <Link
                  to="/destination-wedding"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Destination Wedding
                </Link>
              </li>
            </ul>
          </div>

          {/* === INSPIRATION & IDEAS === */}
          <div className="col-12 col-sm-6 col-lg-3">
            <p className="footer-title fs-16">Inspiration & Ideas</p>
            <ul className="footer-list">
              <li className="fs-14">
                <Link
                  to="/blog"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Wedding Blog
                </Link>
              </li>
              <li className="fs-14">
                <Link
                  to="/photography/all/all"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Wedding Inspiration Gallery
                </Link>
              </li>
              <li className="fs-14">
                <Link
                  to="/latest-real-weddings"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Real Wedding
                </Link>
              </li>
              <li className="fs-14">
                <Link
                  to="/user-dashboard"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Submit Your Wedding
                </Link>
              </li>
              <li className="fs-14">
                <Link
                  to="/einvites"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Wedding Invitation Maker
                </Link>
              </li>
            </ul>
          </div>

          {/* === BRIDAL & GROOM FASHION === */}
          <div className="col-12 col-sm-6 col-lg-3">
            <p className="footer-title fs-16">Bridal & Groom Fashion</p>
            <ul className="footer-list" style={{ color: "#fff" }}>
              <li className="fs-14">
                <Link
                  to="/einvites"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Wedding Card Designs
                </Link>
              </li>
              <li className="fs-14">
                <Link
                  to="/vendors/bridal-wear/all"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Outfit
                </Link>
              </li>
              <li className="fs-14">
                <Link
                  to="/vendors/bridal-makeup/all"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Bridal Makeup &amp; Hair
                </Link>
              </li>
              <li className="fs-14">
                <Link
                  to="/vendors/groom-wear/all"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Groom Wear
                </Link>
              </li>
              <li className="fs-14">
                <Link
                  to="/vendors/jewellery-accessories/all"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-14"
                >
                  Jewellery &amp; Accessories
                </Link>
              </li>
            </ul>
          </div>
        </div>

        <hr className="my-4 opacity-50" style={{ background: "#fff" }} />

        <div className="row mb-4" style={{ minHeight: "52px" }}>
          <div className="col-12" style={{ minHeight: "52px" }}>
            <div
              ref={trustpilotRef}
              className="trustpilot-widget"
              data-locale="en-US"
              data-template-id="56278e9abfbbba0bdcd568bc"
              data-businessunit-id="69f89f5e283c86a87547e5f3"
              data-style-height="52px"
              data-style-width="100%"
              data-token="e35fc7f8-5dea-4218-9fb3-beab0c86bffb"
              style={{ minHeight: "52px", height: "52px", display: "block" }}
            >
              <a
                href="https://www.trustpilot.com/review/happywedz.com"
                target="_blank"
                rel="noopener noreferrer"
                style={{ color: "#fff" }}
              >
                Trustpilot
              </a>
            </div>
          </div>
        </div>

        <div className="row gy-4 text-center text-md-start">
          <div className="col-12 col-md-8 d-flex justify-content-center justify-content-md-start">
            <ul className="footer-list list-unstyled d-flex flex-wrap pt-3 justify-content-center justify-content-md-start">
              <li className="mx-3">
                <Link
                  to="/terms"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-16"
                >
                  Terms &amp; Condition
                </Link>
              </li>
              <li className="mx-3">
                <Link
                  to="/cancellation"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-16"
                >
                  Cancellation Policy
                </Link>
              </li>
              <li className="mx-3">
                <Link
                  to="/about-us"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-16"
                >
                  About HappyWedz
                </Link>
              </li>
              <li className="mx-3">
                <Link
                  to="/careers"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-16"
                >
                  Careers
                </Link>
              </li>
              <li className="mx-3">
                <Link
                  to="/contact-us"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-16"
                >
                  Contact Us
                </Link>
              </li>
              <li className="mx-3">
                <Link
                  to="/sitemap"
                  onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}
                  className="fs-16"
                >
                  Site Map
                </Link>
              </li>
            </ul>
          </div>

          <div className="col-12 col-md-4 d-flex justify-content-center justify-content-md-end">
            <div className="d-flex gap-3 align-items-center pt-2">
              {/* Facebook */}
              <a
                href="https://facebook.com/happywedz"
                aria-label="Facebook"
                target="_blank"
                rel="noopener noreferrer"
                className="social-btn"
              >
                {/* react-icons, not `fa-brands` — these two were the only Font
                    Awesome brand glyphs on the home page, and rendering them
                    pulled down the 115KB fa-brands-400.woff2 webfont. */}
                <FaFacebookF size={20} style={{ color: "#C31162" }} />
              </a>

              {/* Instagram */}
              <a
                href="https://instagram.com/happywedz/"
                aria-label="Instagram"
                target="_blank"
                rel="noopener noreferrer"
                className="social-btn"
              >
                <FaInstagram size={20} style={{ color: "#C31162" }} />
              </a>

              {/* Twitter */}
              <a
                href="https://twitter.com"
                aria-label="Twitter (X)"
                target="_blank"
                rel="noopener noreferrer"
                className="social-btn"
                style={{ color: "#C31162" }}
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 1200 1227"
                  width="20"
                  height="20"
                  fill="currentColor"
                >
                  <path d="M714.163 519.284L1160.89 0H1055.8L667.137 450.887L360.017 0H0L466.92 681.821L0 1226.55H105.08L518.72 751.869L840.882 1226.55H1200L714.163 519.284ZM567.17 689.73L523.16 627.913L143.04 80.73H310.4L621.477 532.57L665.487 594.387L1067.04 1150.63H899.68L567.17 689.73Z" />
                </svg>
              </a>

              {/* YouTube */}
              <a
                href="https://youtube.com/@HappyWedz"
                aria-label="YouTube"
                target="_blank"
                rel="noopener noreferrer"
                className="social-btn"
                style={{ color: "#C31162" }}
              >
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path d="M23.498 6.186a2.995 2.995 0 0 0-2.111-2.115C19.37 3.5 12 3.5 12 3.5s-7.37 0-9.387.571a2.995 2.995 0 0 0-2.111 2.115C.5 8.203.5 12 .5 12s0 3.797.002 5.814a2.995 2.995 0 0 0 2.111 2.115c2.016.57 9.387.57 9.387.57s7.37 0 9.387-.571a2.995 2.995 0 0 0 2.111-2.115C23.5 15.797 23.5 12 23.5 12s0-3.797-.002-5.814zM9.75 15.02V8.98l6.5 3.02-6.5 3.02z" />
                </svg>
              </a>
            </div>
          </div>
        </div>

        <hr className="my-4 opacity-50" style={{ background: "#fff" }} />

        <div className="text-center fs-14">
          <p style={{ color: "#fff" }}>
            &copy; 2025 HappyWedz Designed & Developed by AnantKamal
            Software Labs
          </p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
