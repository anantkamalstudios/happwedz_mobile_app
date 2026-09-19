import React, { useState, useEffect } from "react";
import {
  FaSignOutAlt,
  FaTimes,
  FaHome,
  FaKey,
  FaCamera,
  FaUser,
  FaCameraRetro,
  FaChevronDown,
} from "react-icons/fa";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { removeGuestToken } from "../../redux/guestToken";
import { useDispatch } from "react-redux";

const NAV_ITEMS = [
  { name: "Home", path: "/movment-plus/home", icon: <FaHome /> },
  { name: "Guest Token", path: "/movment-plus/guest-token", icon: <FaKey /> },
  { name: "Upload Selfie", path: "/movment-plus/upload-selfie", icon: <FaCamera /> },
  { name: "User Login", path: "/customer-login", icon: <FaUser /> },
  { name: "Photography Login", path: "/vendor-login", icon: <FaCameraRetro /> },
];

const DESKTOP_BREAKPOINT = 992;
const SIDEBAR_WIDTH = 230;

const MovmentPlusHeader = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const [activeNav, setActiveNav] = useState("Home");
  // On mobile the sidebar behaves like a toggleable drawer; on desktop it is
  // always rendered open as a permanent panel, so this only matters on mobile.
  const [isOpen, setIsOpen] = useState(false);
  const [isDesktop, setIsDesktop] = useState(
    typeof window !== "undefined" ? window.innerWidth >= DESKTOP_BREAKPOINT : true
  );
  // The site header's height (top promo strip + navbar) so the permanent
  // sidebar starts right below it instead of covering it.
  const [headerHeight, setHeaderHeight] = useState(92);

  const handleLogout = () => {
    dispatch(removeGuestToken());
    navigate("/movment-plus/guest-token");
    setIsOpen(false);
  };

  useEffect(() => {
    const currentPath = location.pathname;
    const activeItem = NAV_ITEMS.find((item) => item.path === currentPath);
    if (activeItem) {
      setActiveNav(activeItem.name);
    }
  }, [location.pathname]);

  useEffect(() => {
    const handleResize = () => setIsDesktop(window.innerWidth >= DESKTOP_BREAKPOINT);
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  // Track the site header's real height so the sidebar never overlaps it.
  useEffect(() => {
    if (!isDesktop) return undefined;
    const headerEl = document.querySelector(".navbar");
    if (!headerEl) return undefined;

    const updateHeight = () => setHeaderHeight(headerEl.getBoundingClientRect().height);
    updateHeight();

    const resizeObserver = new ResizeObserver(updateHeight);
    resizeObserver.observe(headerEl);
    window.addEventListener("resize", updateHeight);

    return () => {
      resizeObserver.disconnect();
      window.removeEventListener("resize", updateHeight);
    };
  }, [isDesktop]);

  // Event listeners to open/close/toggle the mobile drawer from other triggers
  useEffect(() => {
    const handleOpen = () => setIsOpen(true);
    const handleClose = () => setIsOpen(false);
    const handleToggle = () => setIsOpen((prev) => !prev);
    const handleKeyDown = (e) => {
      if (e.key === "Escape") setIsOpen(false);
    };

    window.addEventListener("open-movment-sidebar", handleOpen);
    window.addEventListener("close-movment-sidebar", handleClose);
    window.addEventListener("toggle-movment-sidebar", handleToggle);
    window.addEventListener("keydown", handleKeyDown);

    return () => {
      window.removeEventListener("open-movment-sidebar", handleOpen);
      window.removeEventListener("close-movment-sidebar", handleClose);
      window.removeEventListener("toggle-movment-sidebar", handleToggle);
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, []);

  // Permanent, always-open panel on desktop; toggleable drawer on mobile.
  const menuOpen = isDesktop || isOpen;

  return (
    <>
      {/* Click-outside backdrop (mobile drawer only) */}
      {!isDesktop && (
        <div
          className={`movment_nav_backdrop ${isOpen ? "open" : ""}`}
          onClick={() => setIsOpen(false)}
          aria-hidden="true"
        />
      )}

      {/* Anchor Container stuck to Top-Right */}
      <div
        className={`movment_nav_anchor ${isDesktop ? "desktop" : ""}`}
        style={
          isDesktop
            ? { top: headerHeight, height: `calc(100vh - ${headerHeight}px)` }
            : undefined
        }
      >
        {/* Trigger Button (mobile only, sidebar is always open on desktop) */}
        {!isDesktop && (
          <button
            className={`movment_nav_trigger ${isOpen ? "active" : ""}`}
            onClick={() => setIsOpen(!isOpen)}
            title={isOpen ? "Close Menu" : "Open Movments+ Menu"}
            aria-expanded={isOpen}
            aria-label="Toggle Movments+ Menu"
          >
            <FaCamera className="movment_nav_trigger_icon" />
            <span>Movments+</span>
            <FaChevronDown
              className={`movment_nav_chevron ${isOpen ? "rotate" : ""}`}
            />
          </button>
        )}

        {/* Navbar Menu: dropdown drawer on mobile, permanent sidebar on desktop */}
        <nav
          className={`movment_nav_menu ${menuOpen ? "open" : ""} ${isDesktop ? "sidebar" : ""}`}
          aria-label="Movments Plus Navigation"
        >
          {/* Header bar */}
          <div className="movment_nav_menu_header">
            <span className="movment_nav_menu_title">Movments+</span>
            {!isDesktop && (
              <button
                className="movment_nav_menu_close"
                onClick={() => setIsOpen(false)}
                aria-label="Close"
              >
                <FaTimes />
              </button>
            )}
          </div>

          {/* Links list */}
          <ul className="movment_nav_menu_list">
            {NAV_ITEMS.map((item) => {
              const isActive = activeNav === item.name;
              return (
                <li key={item.name}>
                  <Link
                    to={item.path}
                    className={`movment_nav_menu_link ${isActive ? "active" : ""}`}
                    onClick={() => {
                      setActiveNav(item.name);
                      setIsOpen(false);
                    }}
                  >
                    <span className="movment_nav_item_icon">{item.icon}</span>
                    <span>{item.name}</span>
                  </Link>
                </li>
              );
            })}
          </ul>

          <div className="movment_nav_menu_divider" />

          {/* Exit Gallery */}
          <button
            className="movment_nav_menu_logout"
            onClick={handleLogout}
            type="button"
          >
            <FaSignOutAlt className="movment_nav_item_icon text-danger" />
            <span>Exit Gallery</span>
          </button>
        </nav>
      </div>

      <style>{`
        /* Backdrop */
        .movment_nav_backdrop {
          position: fixed;
          inset: 0;
          background: rgba(0, 0, 0, 0.12);
          z-index: 10040;
          opacity: 0;
          visibility: hidden;
          transition: opacity 0.2s ease, visibility 0.2s ease;
        }

        .movment_nav_backdrop.open {
          opacity: 1;
          visibility: visible;
        }

        /* Anchor Container stuck to Top-Right */
        .movment_nav_anchor {
          position: fixed;
          top: 100px;
          right: 0;
          z-index: 10050;
          display: flex;
          flex-direction: column;
          align-items: flex-end;
          pointer-events: none;
        }

        /* Desktop: permanent sidebar, no floating trigger. Exact top/height
           (below the site header) is set inline once measured. */
        .movment_nav_anchor.desktop {
          top: 100px;
          height: calc(100vh - 100px);
          /* Below the site header's dropdowns (profile menu 1050, Bootstrap
             menus 1000), which open over the area this sidebar occupies. */
          z-index: 999;
        }

        /* Reserve room on desktop so page content never sits under the sidebar */
        @media (min-width: 992px) {
          .movment_plus_page_content {
            margin-right: ${SIDEBAR_WIDTH}px;
          }
        }

        /* Trigger Button */
        .movment_nav_trigger {
          pointer-events: auto;
          background: linear-gradient(135deg, #e91e63 0%, #d81b60 100%);
          color: #ffffff;
          border: none;
          border-radius: 20px 0 0 20px;
          padding: 8px 14px 8px 13px;
          font-weight: 600;
          font-size: 13px;
          box-shadow: -3px 3px 14px rgba(233, 30, 99, 0.4);
          display: flex;
          align-items: center;
          gap: 7px;
          cursor: pointer;
          transition: all 0.25s ease;
        }

        .movment_nav_trigger:hover {
          transform: translateX(-3px);
          box-shadow: -5px 5px 18px rgba(233, 30, 99, 0.55);
        }

        .movment_nav_trigger.active {
          background: linear-gradient(135deg, #d81b60 0%, #ad1457 100%);
        }

        .movment_nav_trigger_icon {
          font-size: 13px;
        }

        .movment_nav_chevron {
          font-size: 10px;
          transition: transform 0.2s ease;
        }

        .movment_nav_chevron.rotate {
          transform: rotate(180deg);
        }

        /* Simple Navbar Menu */
        .movment_nav_menu {
          pointer-events: auto;
          margin-top: 6px;
          margin-right: 0;
          width: ${SIDEBAR_WIDTH}px;
          background: #ffffff;
          border-radius: 14px 0 0 14px;
          box-shadow: -4px 8px 25px rgba(0, 0, 0, 0.12);
          border: 1px solid #e5e7eb;
          border-right: none;
          padding: 8px 0;
          opacity: 0;
          visibility: hidden;
          transform: translateY(-6px) scale(0.97);
          transform-origin: top right;
          transition: opacity 0.18s ease, transform 0.18s ease, visibility 0.18s ease;
        }

        .movment_nav_menu.open {
          opacity: 1;
          visibility: visible;
          transform: translateY(0) scale(1);
        }

        /* Desktop permanent sidebar: fills its anchor, always open, no floating card look */
        .movment_nav_menu.sidebar {
          margin-top: 0;
          height: 100%;
          border-radius: 0;
          border: none;
          border-left: 1px solid #e5e7eb;
          box-shadow: -2px 0 12px rgba(0, 0, 0, 0.06);
          display: flex;
          flex-direction: column;
          transform: none;
          transform-origin: initial;
        }

        .movment_nav_menu.sidebar .movment_nav_menu_list {
          flex: 1;
        }

        /* Menu Header */
        .movment_nav_menu_header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 6px 14px 8px 16px;
          border-bottom: 1px solid #f1f5f9;
          margin-bottom: 4px;
        }

        .movment_nav_menu_title {
          font-weight: 700;
          font-size: 13px;
          color: #d81b60;
          letter-spacing: 0.3px;
          text-transform: uppercase;
        }

        .movment_nav_menu_close {
          background: none;
          border: none;
          color: #94a3b8;
          font-size: 13px;
          cursor: pointer;
          padding: 2px;
          display: flex;
          align-items: center;
          justify-content: center;
          border-radius: 4px;
          transition: color 0.15s ease;
        }

        .movment_nav_menu_close:hover {
          color: #334155;
        }

        /* Menu List */
        .movment_nav_menu_list {
          list-style: none;
          padding: 0;
          margin: 0;
        }

        .movment_nav_menu_link {
          display: flex;
          align-items: center;
          gap: 11px;
          padding: 9px 16px;
          color: #334155;
          text-decoration: none;
          font-size: 13.5px;
          font-weight: 500;
          transition: all 0.15s ease;
        }

        .movment_nav_item_icon {
          font-size: 14px;
          color: #64748b;
          display: flex;
          align-items: center;
          width: 16px;
          transition: color 0.15s ease;
        }

        .movment_nav_menu_link:hover {
          background: #fdf2f7;
          color: #d81b60;
          padding-left: 19px;
        }

        .movment_nav_menu_link:hover .movment_nav_item_icon {
          color: #d81b60;
        }

        .movment_nav_menu_link.active {
          color: #d81b60;
          font-weight: 600;
          background: #fff5f8;
          border-right: 3px solid #e91e63;
        }

        .movment_nav_menu_link.active .movment_nav_item_icon {
          color: #e91e63;
        }

        /* Divider */
        .movment_nav_menu_divider {
          height: 1px;
          background: #f1f5f9;
          margin: 6px 0;
        }

        /* Logout button */
        .movment_nav_menu_logout {
          display: flex;
          align-items: center;
          gap: 11px;
          width: 100%;
          padding: 8px 16px;
          background: none;
          border: none;
          color: #dc2626;
          font-size: 13px;
          font-weight: 500;
          cursor: pointer;
          text-align: left;
          transition: all 0.15s ease;
        }

        .movment_nav_menu_logout:hover {
          background: #fef2f2;
          color: #b91c1c;
          padding-left: 19px;
        }
      `}</style>
    </>
  );
};

export default MovmentPlusHeader;
