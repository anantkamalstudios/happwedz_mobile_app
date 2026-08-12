import React, { useState, useEffect } from "react";
import { FaSignOutAlt } from "react-icons/fa";
import { Link, Navigate, useLocation } from "react-router-dom";
import { removeGuestToken } from "../../redux/guestToken";
import { useDispatch } from "react-redux";
// Header Component
const MovmentPlusHeader = () => {
  const location = useLocation();
  const [activeNav, setActiveNav] = useState("Home");

  const handleLogout = () => {
    dispatch(removeGuestToken());
    Navigate("/movment-plus/guest-token");
  };
  const navItems = [
    { name: "Home", path: "/movment-plus/home" },
    { name: "Guest Token", path: "/movment-plus/guest-token" },
    { name: "Upload Selfie", path: "/movment-plus/upload-selfie" },
    { name: "User Login", path: "/customer-login" },
    { name: "Photography Login", path: "/vendor-login" },
  ];

  useEffect(() => {
    const currentPath = location.pathname;
    const activeItem = navItems.find((item) => item.path === currentPath);
    if (activeItem) {
      setActiveNav(activeItem.name);
    }
  }, [location]);

  return (
    <header className="hdr_9x2k4">
      <div className="">
        <nav className="navbar navbar-expand-lg navbar-dark px-3 px-md-4">
          <Link className="navbar-brand d-flex align-items-center" to="/">
            <div className="logo_8k3m2">
              <div className="text-center">
                <div className="navbar-brand-logo">
                  <img
                    src="/images/logo.webp"
                    alt="HappyWedz"
                    height="40"
                    className="mx-auto d-block"
                  />
                </div>
              </div>
            </div>
          </Link>

          <button
            className="navbar-toggler border-0"
            type="button"
            data-bs-toggle="collapse"
            data-bs-target="#mainNav"
          >
            <span className="navbar-toggler-icon"></span>
          </button>

          <div
            className="collapse navbar-collapse justify-content-end"
            id="mainNav"
          >
            <ul className="navbar-nav nav_list_7h4k2 gap-2 gap-lg-4">
              {navItems.map((item) => (
                <li key={item.name} className="nav-item">
                  <Link
                    to={item.path}
                    className={`nav-link nav_link_3j9w1 ${activeNav === item.name ? "active_9m2l4" : ""}`}
                    onClick={() => setActiveNav(item.name)}
                  >
                    {item.name}
                  </Link>
                </li>
              ))}
              <button className="logout_btn" onClick={handleLogout}>
                <FaSignOutAlt /> Exit Gallery
              </button>
            </ul>
          </div>
        </nav>
      </div>

      <style>{`
        .hdr_9x2k4 {
          background: linear-gradient(135deg, #e91e63 0%, #d81b60 100%);
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }

        .logo_8k3m2 {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 2px;
        }

        .logo_svg_4n7x1 {
          width: 45px;
          height: 45px;
        }

        .logo_text_6p2w9 {
          fill: white;
          font-size: 36px;
          font-weight: bold;
          text-anchor: middle;
          font-family: 'Arial', sans-serif;
        }

        .logo_subtext_1m5k8 {
          color: white;
          font-size: 10px;
          font-weight: 600;
          letter-spacing: 1.5px;
          margin-top: -8px;
        }

        .nav_list_7h4k2 {
          align-items: center;
        }

        .nav_link_3j9w1 {
          color: rgba(255, 255, 255, 0.9) !important;
          font-size: 15px;
          font-weight: 500;
          padding: 8px 4px !important;
          position: relative;
          transition: all 0.3s ease;
          white-space: nowrap;
        }

        .nav_link_3j9w1:hover {
          color: white !important;
        }

        .nav_link_3j9w1.active_9m2l4 {
          color: white !important;
        }

        .nav_link_3j9w1.active_9m2l4::after {
          content: '';
          position: absolute;
          bottom: 0;
          left: 0;
          right: 0;
          height: 3px;
          background-color: white;
          border-radius: 2px 2px 0 0;
        }

        .navbar-toggler {
          padding: 8px 10px;
        }

        .navbar-toggler:focus {
          box-shadow: none;
        }

        @media (max-width: 991px) {
          .nav_list_7h4k2 {
            margin-top: 1rem;
            padding-bottom: 1rem;
          }

          .nav_link_3j9w1.active_9m2l4::after {
            left: 0;
            right: auto;
            width: 30px;
          }
        }
      `}</style>
    </header>
  );
};
export default MovmentPlusHeader;
