import React, { useEffect, useState, useRef } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import LocationModalWithCategories from "./LocationModalWithCategories";
import { RiMenuFill } from "react-icons/ri";
import { IoClose } from "react-icons/io5";
import { useDispatch, useSelector } from "react-redux";
import { logout } from "../../redux/authSlice";
import { vendorLogout } from "../../redux/vendorAuthSlice";
import { setLocation } from "../../redux/locationSlice";
import { FiMail, FiPhone, FiMapPin, FiSearch, FiEdit3, FiSmartphone, FiUser, FiLogOut, FiGrid } from "react-icons/fi";
import { FaArrowRightLong, FaChevronDown, FaChevronUp, FaCaretDown } from "react-icons/fa6";
import usePhotography from "../../hooks/usePhotography";
import { useFilter } from "../../context/realWedding.context";
import axiosInstance from "../../services/api/axiosInstance";
import { fetchVendorTypesWithSubcategoriesApi } from "../../services/api/vendorTypesWithSubcategoriesApi";
import { API_BASE_URL, STORE_ORIGIN } from "../../config/constants";

const Header = () => {
  // Add state to track window width for responsive UI
  const [windowWidth, setWindowWidth] = useState(window.innerWidth);

  useEffect(() => {
    const handleResize = () => setWindowWidth(window.innerWidth);
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);
  const dispatch = useDispatch();
  const { slug } = useParams();
  const reduxLocation = useSelector((state) => state.location.selectedLocation);
  const [activeTab, setActiveTab] = useState("");
  const [selectedCity, setSelectedCity] = useState(reduxLocation);
  const [openMenu, setOpenMenu] = useState(null);
  const megaMenuTimeoutRef = useRef(null);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [mobileSubmenu, setMobileSubmenu] = useState(null);

  // Small delay before closing a mega-dropdown so moving the mouse across the
  // gap between the nav tab and the dropdown panel doesn't close it early.
  const handleMegaMenuEnter = (name) => {
    if (megaMenuTimeoutRef.current) {
      clearTimeout(megaMenuTimeoutRef.current);
      megaMenuTimeoutRef.current = null;
    }
    setOpenMenu(name);
  };

  const handleMegaMenuLeave = () => {
    if (megaMenuTimeoutRef.current) {
      clearTimeout(megaMenuTimeoutRef.current);
    }
    megaMenuTimeoutRef.current = setTimeout(() => {
      setOpenMenu(null);
    }, 280);
  };

  useEffect(() => {
    return () => {
      if (megaMenuTimeoutRef.current) {
        clearTimeout(megaMenuTimeoutRef.current);
      }
    };
  }, []);
  const navigate = useNavigate();
  const {
    setSelectCity,
    setSelectedCulture,
    setSelectedTheme,
    cultures,
    themes,
  } = useFilter();

  const formatName = (name) => name.replace(/\band\b/gi, "&");

  const [popularSections, setPopularSections] = useState([]);
  const [browseByCategory, setBrowseByCategory] = useState([]);
  const [mostSearchedBlogs, setMostSearchedBlogs] = useState([]);

  useEffect(() => {
    const fetchCategories = async (type, setter) => {
      try {
        const res = await fetch(
          `${API_BASE_URL}/blog-categories/all?type=${type}&status=active`,
        );
        const json = await res.json();
        const arr = Array.isArray(json.data) ? json.data : [];
        setter(arr);
      } catch (e) {
        setter([]);
      }
    };
    fetchCategories("popular_section", setPopularSections);
    fetchCategories("browse_by_category", setBrowseByCategory);
    fetchCategories("most_searched", setMostSearchedBlogs);
  }, []);

  const byCity = ["Mumbai", "Bangalore", "Pune", "Kolkata", "Jaipur", "Others"];

  const handleLogout = async () => {
    try {
      await axiosInstance.post("/auth/logout");
    } catch (error) {
      console.error("Logout request failed", error);
    }

    if (isVendorLoggedIn) {
      dispatch(vendorLogout());
    } else {
      dispatch(logout());
    }

    localStorage.removeItem("user");
    localStorage.removeItem("token");
    localStorage.removeItem("tokenTimestamp");
    localStorage.removeItem("vendor");
    localStorage.removeItem("vendorToken");
    localStorage.removeItem("vendorTokenExpiry");
    setMobileMenuOpen(false);
  };

  const [profileMenuOpen, setProfileMenuOpen] = useState(false);
  const profileMenuTimeoutRef = useRef(null);
  const profileMenuContainerRef = useRef(null);

  const { user, isAuthenticated } = useSelector((state) => state.auth);
  const { vendor, token: vendorToken } = useSelector(
    (state) => state.vendorAuth,
  );

  const isUserLoggedIn = !!user && !!isAuthenticated;
  const isVendorLoggedIn = !!vendorToken && !!vendor;
  const isLoggedIn = isUserLoggedIn || isVendorLoggedIn;

  const handleProfileMouseEnter = () => {
    if (profileMenuTimeoutRef.current) {
      clearTimeout(profileMenuTimeoutRef.current);
      profileMenuTimeoutRef.current = null;
    }
    if (isLoggedIn) {
      setProfileMenuOpen(true);
    }
  };

  const handleProfileMouseLeave = () => {
    if (profileMenuTimeoutRef.current) {
      clearTimeout(profileMenuTimeoutRef.current);
    }
    profileMenuTimeoutRef.current = setTimeout(() => {
      setProfileMenuOpen(false);
    }, 280);
  };

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (
        profileMenuContainerRef.current &&
        !profileMenuContainerRef.current.contains(e.target)
      ) {
        setProfileMenuOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
      if (profileMenuTimeoutRef.current) {
        clearTimeout(profileMenuTimeoutRef.current);
      }
    };
  }, []);

  const profileName =
    user?.name ||
    user?.userName ||
    user?.username ||
    user?.data?.name ||
    vendor?.businessName ||
    vendor?.name ||
    vendor?.vendor?.businessName ||
    "";
  const profileInitial = profileName ? profileName.trim().charAt(0).toUpperCase() : "";
  const profileAvatar =
    user?.profileImage ||
    user?.profile_picture ||
    user?.profilePic ||
    user?.avatar ||
    vendor?.profileImage ||
    vendor?.logo ||
    null;
  const profileEmail =
    user?.email ||
    user?.userEmail ||
    user?.mail ||
    user?.data?.email ||
    vendor?.email ||
    vendor?.vendor?.email ||
    "";

  const toSlug = (text) =>
    text
      ?.toLowerCase()
      .replace(/\s+/g, "-")
      .replace(/[^a-z0-9\-]/g, "") || "";

  const location = window.location.pathname;

  useEffect(() => {
    setMobileMenuOpen(false);
    setMobileSubmenu(null);
  }, [location]);

  useEffect(() => {
    if (mobileMenuOpen) {
      document.body.style.overflow = "hidden";
      document.body.style.touchAction = "none";
    } else {
      document.body.style.overflow = "";
      document.body.style.touchAction = "";
    }
    return () => {
      document.body.style.overflow = "";
      document.body.style.touchAction = "";
    };
  }, [mobileMenuOpen]);

  const tabs = [
    {
      id: "wedding",
      slug: "my-wedding",
      label: "My Wedding",
      img: "/images/userDashboard/mywedding-img.svg",
    },
    {
      id: "checklist",
      slug: "checklist",
      label: "Checklist",
      img: "/images/userDashboard/checklist-img.svg",
    },
    {
      id: "vendors",
      slug: "vendor",
      label: "Vendor",
      img: "/images/userDashboard/vendor-img.svg",
    },
    {
      id: "guest-list",
      slug: "guest-list",
      label: "Guest list",
      img: "/images/userDashboard/guestlist-img.svg",
    },
    {
      id: "budget",
      slug: "budget",
      label: "Budget",
      img: "/images/userDashboard/budget-img.svg",
    },
    {
      id: "wishlist",
      slug: "wishlist",
      label: "Wishlist",
      img: "/images/userDashboard/wishlist-img.svg",
    },
    {
      id: "message",
      slug: "message",
      label: "Message",
      img: "/images/userDashboard/message-img.svg",
    },
    {
      id: "real-wedding",
      slug: "real-wedding",
      label: "Real wedding",
      img: "/images/userDashboard/real-wedding-img1.png",
    },
    {
      id: "user-profile",
      slug: "user-profile",
      label: "Profile",
      img: "/images/userDashboard/userProfile-img.svg",
    },
  ];

  const [venueSubcategories, setVenueSubcategories] = useState([]);
  const [vendorCategories, setVendorCategories] = useState([]);
  const [einviteCategories, setEinviteCategories] = useState([
    {
      cardType: "wedding_einvite",
      title: "Wedding E-Invitations",
      icon: "bi-heart",
    },
    { cardType: "video", title: "Video Invitations", icon: "bi-play-circle" },
    {
      cardType: "save_the_date",
      title: "Save the Date",
      icon: "bi-calendar-heart",
    },
  ]);

  // One shared, deduped request feeds both the vendor menu and the venues submenu.
  // These were two separate fetches of the same endpoint.
  useEffect(() => {
    let cancelled = false;
    fetchVendorTypesWithSubcategoriesApi().then((data) => {
      if (cancelled) return;
      setVendorCategories(data);
      const venues = data.find(
        (vendor) => vendor.name && vendor.name.toLowerCase() === "venues",
      );
      setVenueSubcategories(
        venues && Array.isArray(venues.subcategories) ? venues.subcategories : [],
      );
    });
    return () => {
      cancelled = true;
    };
  }, []);

  const {
    typesWithCategories,
    fetchTypesWithCategories,
    loading: photographyLoading,
    error: photographyError,
  } = usePhotography();

  const [photography, setPhotography] = useState([]);
  useEffect(() => {
    const fetchData = async () => {
      await fetchTypesWithCategories();
    };
    fetchData();
  }, []);

  useEffect(() => {
    setPhotography(typesWithCategories);
  }, [typesWithCategories]);

  const vendorType = encodeURIComponent("Venues");
  const cityParam = selectedCity
    ? `&city=${encodeURIComponent(selectedCity)}`
    : "";

  const targetURL = `/vendors/all?vendorType=${vendorType}${cityParam}`;

  const toggleMobileSubmenu = (menu) => {
    setMobileSubmenu(mobileSubmenu === menu ? null : menu);
  };

  const handleMobileLinkClick = () => {
    setMobileMenuOpen(false);
    setMobileSubmenu(null);
  };

  return (
    <>
      {mobileMenuOpen && (
        <div
          className="position-fixed top-0 start-0 w-100 h-100 bg-dark"
          style={{
            opacity: 0.5,
            zIndex: 1049,
            transition: "opacity 0.3s ease",
          }}
          onClick={() => setMobileMenuOpen(false)}
        />
      )}

      <nav className="navbar navbar-expand-lg navbar-light shadow-sm primary-bg p-0">
        <div className="container-fluid p-0">
          <div className="d-flex d-lg-none justify-content-between align-items-center w-100 py-2 px-3">
            <Link
              className="navbar-brand m-0"
              to="/"
              onClick={handleMobileLinkClick}
            >
              <img src="/images/logo-sm-300.webp" alt="HappyWedz" width="120" height="30" />
            </Link>

            {windowWidth <= 1299 && (
              <button
                className="navbar-toggler border-0 p-0"
                type="button"
                onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                aria-label="Toggle navigation"
              >
                <RiMenuFill color="white" size={35} />
              </button>
            )}
          </div>

          {/* Mobile Side Drawer */}
          <div
            className={`position-fixed top-0 start-0 h-100 bg-white shadow-lg d-lg-none ${
              mobileMenuOpen ? "mobile-drawer-open" : ""
            }`}
            style={{
              width: "85%",
              maxWidth: "400px",
              zIndex: 1050,
              transform: mobileMenuOpen ? "translateX(0)" : "translateX(-100%)",
              transition: "transform 0.3s ease-in-out",
              overflowY: "auto",
            }}
          >
            {/* Drawer Header */}
            <div className="d-flex justify-content-between align-items-center p-3 primary-bg">
              <Link to="/" onClick={handleMobileLinkClick}>
                <img src="/images/logo-sm-300.webp" alt="HappyWedz" width="120" height="30" />
              </Link>
              <button
                className="btn border-0 p-0"
                onClick={() => setMobileMenuOpen(false)}
                aria-label="Close menu"
                style={{ textAlign: "end" }}
              >
                <IoClose color="white" size={30} />
              </button>
            </div>

            {/* Drawer Content */}
            <div className="p-3">
              {/* Location Selector */}
              <div className="mb-3 d-flex align-items-center justify-content-between">
                <LocationModalWithCategories />
                {/* Design Studio (virtual try-on) entry point — disabled.

                <div>
                  <Link
                    to="/try"
                    state={{ title: "Try" }}
                    onClick={handleMobileLinkClick}
                  >
                    <img
                      src="/images/header/tryimg.png"
                      alt="Design Studio"
                      width="40"
                      height="40"
                      className="img-fluid"
                      loading="lazy"
                      decoding="async"
                      style={{
                        height: "40px",
                        width: "40px",
                        objectFit: "contain",
                        cursor: "pointer",
                      }}
                    />
                  </Link>
                </div>
                */}
              </div>

              {/* Menu Items */}
              <ul className="list-unstyled mb-0">
                {/* Planning Tools */}
                <li className="mb-2">
                  <button
                    className="btn w-100 text-start d-flex justify-content-between align-items-center p-3 border-0 bg-light"
                    onClick={() => toggleMobileSubmenu("planning")}
                  >
                    <span className="fw-semibold">Planning Tools</span>
                    {mobileSubmenu === "planning" ? (
                      <FaChevronUp />
                    ) : (
                      <FaChevronDown />
                    )}
                  </button>
                  {mobileSubmenu === "planning" && (
                    <div className="ps-3 mt-2">
                      {tabs.map((tab) => (
                        <Link
                          key={tab.id}
                          to={`/user-dashboard/${tab.slug}`}
                          className="d-flex align-items-center py-2 text-decoration-none text-dark"
                          onClick={handleMobileLinkClick}
                        >
                          <div
                            className="d-flex align-items-center justify-content-center me-2"
                            style={{
                              width: "35px",
                              height: "35px",
                              borderRadius: "50%",
                              backgroundColor: "#ed1173",
                            }}
                          >
                            <img
                              src={tab.img}
                              alt=""
                              style={{
                                height: "25px",
                                width: "25px",
                                objectFit: "contain",
                              }}
                            />
                          </div>
                          <span className="small">{tab.label}</span>
                        </Link>
                      ))}
                    </div>
                  )}
                </li>

                {/* Venues */}
                <li className="mb-2">
                  <button
                    className="btn w-100 text-start d-flex justify-content-between align-items-center p-3 border-0 bg-light"
                    // onClick={() => toggleMobileSubmenu("venues")}
                  >
                    <span
                      className="fw-semibold"
                      onClick={() => navigate("/venues")}
                    >
                      Venues
                    </span>
                    {mobileSubmenu === "venues" ? (
                      <FaChevronUp
                        onClick={() => toggleMobileSubmenu("venues")}
                      />
                    ) : (
                      <FaChevronDown
                        onClick={() => toggleMobileSubmenu("venues")}
                      />
                    )}
                  </button>
                  {mobileSubmenu === "venues" && (
                    <div className="ps-3 mt-2">
                      <h6 className="fw-bold small text-uppercase primary-text mb-2">
                        By Type
                      </h6>
                      {(venueSubcategories.length > 0
                        ? [
                            ...venueSubcategories.map((s) => s.name),
                            "View All Venues",
                          ]
                        : [
                            "Banquet Halls",
                            "Marriage Garden / Lawns",
                            "Wedding Resorts",
                            "Small Function / Party Halls",
                            "Destination Wedding Venues",
                            "Kalyana Mandapams",
                            "4 Star & Above Wedding Hotels",
                            "Venue Concierge Services",
                            "View All Venues",
                          ]
                      ).map((item, i) => {
                        const isShowMore = item === "View All Venues";
                        const cleanSlug = item
                          .toLowerCase()
                          .replace(/&/g, "and")
                          .replace(/[^a-z0-9\s-]/g, "")
                          .replace(/\s+/g, "-")
                          .replace(/-+/g, "-")
                          .replace(/^-+|-+$/g, "");
                        const path = isShowMore ? "/venues" : `/venues/${cleanSlug}`;
                        return (
                          <Link
                            key={i}
                            to={path}
                            className="d-block py-2 text-decoration-none text-dark small"
                            onClick={handleMobileLinkClick}
                          >
                            {item}
                          </Link>
                        );
                      })}

                      <h6 className="fw-bold small text-uppercase primary-text mt-3 mb-2">
                        By City
                      </h6>
                      {[
                        "Mumbai",
                        "Bangalore",
                        "Pune",
                        "Kolkata",
                        "Jaipur",
                        "Lucknow",
                        "Hyderabad",
                        "More",
                      ].map((city, i) => {
                        const isMore = city === "More";
                        const path = isMore
                          ? "/venues"
                          : `/wedding-venues/${city.toLowerCase().replace(/[^a-z0-9\s-]/g, "").replace(/\s+/g, "-").replace(/-+/g, "-").replace(/^-+|-+$/g, "")}`;
                        return (
                          <Link
                            key={i}
                            to={path}
                            onClick={() => {
                              if (!isMore) {
                                dispatch(setLocation(city));
                              }
                              handleMobileLinkClick();
                            }}
                            className="d-block py-2 text-decoration-none text-dark small"
                          >
                            {city}
                          </Link>
                        );
                      })}
                    </div>
                  )}
                </li>

                {/* Vendors */}
                <li className="mb-2">
                  <button
                    className="btn w-100 text-start d-flex justify-content-between align-items-center p-3 border-0 bg-light"
                    // onClick={() => toggleMobileSubmenu("vendors")}
                  >
                    <span
                      className="fw-semibold"
                      role="button"
                      onClick={() => navigate("/vendors")}
                    >
                      Vendors
                    </span>
                    {mobileSubmenu === "vendors" ? (
                      <FaChevronUp
                        onClick={() => toggleMobileSubmenu("vendors")}
                      />
                    ) : (
                      <FaChevronDown
                        onClick={() => toggleMobileSubmenu("vendors")}
                      />
                    )}
                  </button>
                  {mobileSubmenu === "vendors" && (
                    <div
                      className="ps-3 mt-2"
                      style={{ maxHeight: "400px", overflowY: "auto" }}
                    >
                      {vendorCategories.length > 0 &&
                        vendorCategories.map((cat, i) => (
                          <div key={cat.id || i} className="mb-3">
                            <h6 className="fw-bold small text-uppercase primary-text mb-2">
                              {cat.name}
                            </h6>
                            {Array.isArray(cat.subcategories) &&
                              cat.subcategories.length > 0 && (
                                <div>
                                  {cat.subcategories.map((sub, j) => (
                                    <Link
                                      key={sub.id || j}
                                      to={`/vendors/${toSlug(sub.name)}/${
                                        reduxLocation
                                          ? reduxLocation.toLowerCase().replace(/[^a-z0-9\s-]/g, "").replace(/\s+/g, "-").replace(/-+/g, "-").replace(/^-+|-+$/g, "")
                                          : "all"
                                      }`}
                                      className="d-block py-2 text-decoration-none text-dark small"
                                      onClick={handleMobileLinkClick}
                                    >
                                      {formatName(sub.name)}
                                    </Link>
                                  ))}
                                </div>
                              )}
                          </div>
                        ))}
                    </div>
                  )}
                </li>

                {/* Wedding Inspiration */}
                <li className="mb-2">
                  <button
                    className="btn w-100 text-start d-flex justify-content-between align-items-center p-3 border-0 bg-light"
                    // onClick={() => toggleMobileSubmenu("photography")}
                  >
                    <span
                      className="fw-semibold"
                      role="button"
                      onClick={() => navigate("/photography")}
                    >
                      Wedding Inspiration
                    </span>
                    {mobileSubmenu === "photography" ? (
                      <FaChevronUp
                        onClick={() => toggleMobileSubmenu("photography")}
                      />
                    ) : (
                      <FaChevronDown
                        onClick={() => toggleMobileSubmenu("photography")}
                      />
                    )}
                  </button>
                  {mobileSubmenu === "photography" && (
                    <div
                      className="ps-3 mt-2"
                      style={{ maxHeight: "400px", overflowY: "auto" }}
                    >
                      {photography.length > 0 &&
                        photography.map((cat, i) => (
                          <div key={cat.id || i} className="mb-3">
                            <h6 className="fw-bold small text-uppercase primary-text mb-2">
                              {cat.name}
                            </h6>
                            {Array.isArray(cat.categories) &&
                              cat.categories.length > 0 && (
                                <div>
                                  {cat.categories.map((sub, j) => (
                                    <Link
                                      key={sub.id || j}
                                      to={`/photography/${toSlug(sub.name)}/${
                                        reduxLocation
                                          ? reduxLocation.toLowerCase().replace(/[^a-z0-9\s-]/g, "").replace(/\s+/g, "-").replace(/-+/g, "-").replace(/^-+|-+$/g, "")
                                          : "all"
                                      }`}
                                      className="d-block py-2 text-decoration-none text-dark small"
                                      onClick={handleMobileLinkClick}
                                    >
                                      {formatName(sub.name)}
                                    </Link>
                                  ))}
                                </div>
                              )}
                          </div>
                        ))}
                    </div>
                  )}
                </li>

                {/* Photography */}
                <li className="mb-2">
                  <Link
                    to="/movment-plus/home"
                    className="btn w-100 text-start p-3 border-0 bg-light fw-semibold text-dark"
                    onClick={(e) => {
                      handleMobileLinkClick(e);
                      window.dispatchEvent(
                        new CustomEvent("open-movment-sidebar")
                      );
                    }}
                  >
                    Photography
                  </Link>
                </li>

                {/* E-Invites */}
                <li className="mb-2">
                  <button
                    className="btn w-100 text-start d-flex justify-content-between align-items-center p-3 border-0 bg-light"
                    // onClick={() => toggleMobileSubmenu("einvites")}
                  >
                    <span
                      className="fw-semibold"
                      role="button"
                      onClick={() => navigate("/einvites")}
                    >
                      E-Invites
                    </span>
                    {mobileSubmenu === "einvites" ? (
                      <FaChevronUp
                        onClick={() => toggleMobileSubmenu("einvites")}
                      />
                    ) : (
                      <FaChevronDown
                        onClick={() => toggleMobileSubmenu("einvites")}
                      />
                    )}
                  </button>
                  {mobileSubmenu === "einvites" && (
                    <div className="ps-3 mt-2">
                      {einviteCategories.map((sub, j) => (
                        <Link
                          key={sub.cardType || j}
                          to={`/einvites/category/${sub.cardType}`}
                          className="d-block py-2 text-decoration-none text-dark small"
                          onClick={handleMobileLinkClick}
                        >
                          {formatName(sub.title)}
                        </Link>
                      ))}
                    </div>
                  )}
                </li>

                {/* Shop */}
                <li className="mb-2">
                  <a
                    href={`${STORE_ORIGIN}/`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn w-100 text-start p-3 border-0 bg-light fw-semibold text-dark"
                    onClick={handleMobileLinkClick}
                  >
                    Shop
                  </a>
                </li>

                {/* Blog is hidden on mobile so the drawer carries the same
                    sections as the desktop bar, where this entry is also commented
                    out. Restore here and in the desktop nav together. */}
                {/*
                <li className="mb-2">
                  <button
                    className="btn w-100 text-start d-flex justify-content-between align-items-center p-3 border-0 bg-light"
                    // onClick={() => toggleMobileSubmenu("blog")}
                  >
                    <span
                      className="fw-semibold"
                      role="button"
                      onClick={() => navigate("/blog")}
                    >
                      Blog
                    </span>
                    {mobileSubmenu === "blog" ? (
                      <FaChevronUp
                        onClick={() => toggleMobileSubmenu("blog")}
                      />
                    ) : (
                      <FaChevronDown
                        onClick={() => toggleMobileSubmenu("blog")}
                      />
                    )}
                  </button>
                  {mobileSubmenu === "blog" && (
                    <div
                      className="ps-3 mt-2"
                      style={{ maxHeight: "400px", overflowY: "auto" }}
                    >
                      <h6 className="fw-bold small text-uppercase primary-text mb-2">
                        Browse by Category
                      </h6>
                      {browseByCategory.map((topic, index) => (
                        <Link
                          key={index}
                          to="/blog"
                          className="d-block py-2 text-decoration-none text-dark small"
                          onClick={handleMobileLinkClick}
                        >
                          {topic}
                        </Link>
                      ))}

                      <h6 className="fw-bold small text-uppercase primary-text mt-3 mb-2">
                        Popular Sections
                      </h6>
                      {popularSections.map((category, index) => (
                        <Link
                          key={index}
                          to="/blog"
                          className="d-block py-2 text-decoration-none text-dark small"
                          onClick={handleMobileLinkClick}
                        >
                          {category}
                        </Link>
                      ))}

                      <h6 className="fw-bold small text-uppercase primary-text mt-3 mb-2">
                        Most Searched Blogs
                      </h6>
                      {mostSearchedBlogs.map((idea, index) => (
                        <Link
                          key={index}
                          to="/blog"
                          className="d-block py-2 text-decoration-none text-dark small"
                          onClick={handleMobileLinkClick}
                        >
                          {idea}
                        </Link>
                      ))}
                    </div>
                  )}
                </li>
                */}

                {/* Genie */}
                <li className="mb-2">
                  <Link
                    to="/shaadi-ai"
                    className="btn w-100 text-start p-3 border-0 bg-light fw-semibold text-dark"
                    onClick={handleMobileLinkClick}
                  >
                    ShaadiAI
                  </Link>
                </li>

                {/* Honeymoon */}
                <li className="mb-2">
                  <Link
                    to="/honeymoon"
                    className="btn w-100 text-start p-3 border-0 bg-light fw-semibold text-dark"
                    onClick={handleMobileLinkClick}
                  >
                    Honeymoon
                  </Link>
                </li>

                {/* Real Wedding is hidden on mobile so the drawer carries the same
                    sections as the desktop bar, where this entry is also commented
                    out. Restore here and in the desktop nav together. */}
                {/*
                <li className="mb-2">
                  <button className="btn w-100 text-start d-flex justify-content-between align-items-center p-3 border-0 bg-light">
                    <span
                      className="fw-semibold"
                      role="button"
                      onClick={() => navigate("real-wedding")}
                    >
                      Real Wedding
                    </span>
                    {mobileSubmenu === "real-wedding" ? (
                      <FaChevronUp
                        onClick={() => toggleMobileSubmenu("real-wedding")}
                      />
                    ) : (
                      <FaChevronDown
                        onClick={() => toggleMobileSubmenu("real-wedding")}
                      />
                    )}
                  </button>
                  {mobileSubmenu === "real-wedding" && (
                    <div className="ps-3 mt-2">
                      <h6 className="fw-bold small text-uppercase primary-text mb-2">
                        By City
                      </h6>
                      {byCity.map((city, index) => (
                        <Link
                          key={index}
                          to="/real-wedding"
                          className="d-block py-2 text-decoration-none text-dark small"
                          onClick={() => {
                            setSelectCity(city);
                            setSelectedCulture("All Cultures");
                            setSelectedTheme("All Themes");
                            navigate("/real-wedding");
                            handleMobileLinkClick();
                          }}
                        >
                          {city}
                        </Link>
                      ))}

                      <h6 className="fw-bold small text-uppercase primary-text mt-3 mb-2">
                        By Culture
                      </h6>
                      {cultures.map((culture, index) => (
                        <Link
                          key={index}
                          to="/real-wedding"
                          className="d-block py-2 text-decoration-none text-dark small"
                          onClick={() => {
                            setSelectedCulture(culture?.name || culture);
                            setSelectCity("All Cities");
                            setSelectedTheme("All Themes");
                            navigate("/real-wedding");
                            handleMobileLinkClick();
                          }}
                        >
                          {culture?.name || String(culture)}
                        </Link>
                      ))}

                      <h6 className="fw-bold small text-uppercase primary-text mt-3 mb-2">
                        By Theme
                      </h6>
                      {themes.map((theme, index) => (
                        <Link
                          key={index}
                          to="/real-wedding"
                          className="d-block py-2 text-decoration-none text-dark small"
                          onClick={() => {
                            setSelectedTheme(theme);
                            setSelectCity("All Cities");
                            setSelectedCulture("All Cultures");
                            navigate("/real-wedding");
                            handleMobileLinkClick();
                          }}
                        >
                          {theme}
                        </Link>
                      ))}
                    </div>
                  )}
                </li>
                */}

                {/* Auth Links */}
                <li className="mb-2">
                  {isUserLoggedIn ? (
                    <Link
                      to="/user-dashboard"
                      className="btn w-100 text-start p-3 border-0 bg-light fw-semibold text-dark"
                      onClick={handleMobileLinkClick}
                    >
                      User Dashboard
                    </Link>
                  ) : isVendorLoggedIn ? (
                    <Link
                      to="/vendor-dashboard"
                      className="btn w-100 text-start p-3 border-0 bg-light fw-semibold text-dark"
                      onClick={handleMobileLinkClick}
                    >
                      Vendor Dashboard
                    </Link>
                  ) : (
                    <Link
                      to="/customer-login"
                      className="btn w-100 text-start p-3 border-0 bg-light fw-semibold text-dark"
                      onClick={handleMobileLinkClick}
                    >
                      Login
                    </Link>
                  )}
                </li>

                {isLoggedIn && (
                  <li className="mb-2">
                    <button
                      onClick={handleLogout}
                      className="btn w-100 text-start p-3 border-0 bg-danger text-white fw-semibold"
                    >
                      Logout
                    </button>
                  </li>
                )}
              </ul>

              {/* App Download Section - Mobile */}
              <div className="mt-4 pt-3 border-top">
                <div
                  style={{
                    background: "#e83581",
                    borderRadius: "8px",
                    padding: "10px 16px",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    gap: "14px",
                  }}
                >
                  <a
                    href="https://play.google.com/store/apps/details?id=com.happy.happy_wedz&pcampaignid=web_share"
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "7px",
                      color: "#fff",
                      textDecoration: "none",
                      fontWeight: "600",
                      fontSize: "13px",
                      whiteSpace: "nowrap",
                    }}
                  >
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M3 20.5v-17c0-.83.94-1.3 1.6-.8l14 8.5c.67.4.67 1.4 0 1.8l-14 8.5c-.66.5-1.6.03-1.6-.8z"/>
                    </svg>
                    Play Store
                  </a>
                  <div style={{ width: "1px", height: "18px", backgroundColor: "rgba(255,255,255,0.4)" }} />
                  <a
                    href="https://apps.apple.com/in/app/happy-wedz/id6756042192"
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "7px",
                      color: "#fff",
                      textDecoration: "none",
                      fontWeight: "600",
                      fontSize: "13px",
                      whiteSpace: "nowrap",
                    }}
                  >
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.32c.62-.75 1.04-1.8 0.93-2.85-.9.04-2 .61-2.65 1.37-.58.67-1.09 1.75-.95 2.78 1.01.08 2.05-.55 2.67-1.3"/>
                    </svg>
                    Apple Store
                  </a>
                </div>
              </div>
            </div>
          </div>

          {/* DESKTOP VIEW */}
          <div className="d-none d-lg-block w-100">
            <div className="row w-100" style={{ margin: 0, padding: 0 }}>
              {/* TIER 1: Top Bar (White) */}
              <div className="col-12 p-0 header-topbar d-flex align-items-center" style={{ backgroundColor: "#ffffff", borderBottom: "1px solid #eaeaea", height: "42px", minHeight: "42px" }}>
                <div className="container-fluid w-100 px-4 h-100">
                  <div className="d-flex align-items-center justify-content-between flex-nowrap h-100">
                    {/* Left: Tagline + Location Modal */}
                    <div className="d-flex align-items-center gap-3">
                      <span
                        className="fw-bold text-nowrap m-0 p-0 fs-14"
                        style={{ color: "#c2185b" }}
                      >
                        India's Most Loved Wedding Planning Platform
                      </span>
                      <LocationModalWithCategories />
                    </div>

                    {/* Right: Play Store & App Store Vector Badges */}
                    <div className="d-flex align-items-center gap-2">
                      {/* Google Play Badge */}
                      <a
                        href="https://play.google.com/store/apps/details?id=com.happy.happy_wedz&pcampaignid=web_share"
                        target="_blank"
                        rel="noopener noreferrer"
                        title="Google Play"
                        style={{
                          display: "inline-flex",
                          alignItems: "center",
                          gap: "8px",
                          backgroundColor: "#000000",
                          color: "#ffffff",
                          padding: "4px 10px",
                          borderRadius: "6px",
                          textDecoration: "none",
                          height: "30px",
                          boxShadow: "0 2px 6px rgba(0,0,0,0.15)",
                          transition: "transform 0.2s"
                        }}
                        onMouseEnter={(e) => { e.currentTarget.style.transform = "scale(1.04)"; }}
                        onMouseLeave={(e) => { e.currentTarget.style.transform = "scale(1)"; }}
                      >
                        <svg width="15" height="15" viewBox="0 0 24 24">
                          <path fill="#4285F4" d="M3 20.5v-17c0-.83.94-1.3 1.6-.8l14 8.5c.67.4.67 1.4 0 1.8l-14 8.5c-.66.5-1.6.03-1.6-.8z"/>
                          <path fill="#34A853" d="M3 3.5l10.5 10.5L3 20.5V3.5z"/>
                          <path fill="#EA4335" d="M13.5 14L3 20.5c.66.5 1.6.03 1.6-.8l8.9-5.7z"/>
                          <path fill="#FBBC04" d="M13.5 10L4.6 4.3C3.94 3.8 3 4.27 3 5.1v.4l10.5 4.5z"/>
                        </svg>
                        <div style={{ display: "flex", flexDirection: "column", textAlign: "left" }}>
                          <span style={{ fontSize: "7px", textTransform: "uppercase", letterSpacing: "0.5px", opacity: 0.85, lineHeight: "1" }}>GET IT ON</span>
                          <span style={{ fontSize: "11px", fontWeight: "700", lineHeight: "1.1", fontFamily: "Roboto, sans-serif" }}>Google Play</span>
                        </div>
                      </a>

                      {/* App Store Badge */}
                      <a
                        href="https://apps.apple.com/in/app/happy-wedz/id6756042192"
                        target="_blank"
                        rel="noopener noreferrer"
                        title="App Store"
                        style={{
                          display: "inline-flex",
                          alignItems: "center",
                          gap: "8px",
                          backgroundColor: "#000000",
                          color: "#ffffff",
                          padding: "4px 10px",
                          borderRadius: "6px",
                          textDecoration: "none",
                          height: "30px",
                          boxShadow: "0 2px 6px rgba(0,0,0,0.15)",
                          transition: "transform 0.2s"
                        }}
                        onMouseEnter={(e) => { e.currentTarget.style.transform = "scale(1.04)"; }}
                        onMouseLeave={(e) => { e.currentTarget.style.transform = "scale(1)"; }}
                      >
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="#ffffff">
                          <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.32c.62-.75 1.04-1.8 0.93-2.85-.9.04-2 .61-2.65 1.37-.58.67-1.09 1.75-.95 2.78 1.01.08 2.05-.55 2.67-1.3"/>
                        </svg>
                        <div style={{ display: "flex", flexDirection: "column", textAlign: "left" }}>
                          <span style={{ fontSize: "7px", opacity: 0.85, lineHeight: "1" }}>Download on the</span>
                          <span style={{ fontSize: "11px", fontWeight: "700", lineHeight: "1.1", fontFamily: "-apple-system, sans-serif" }}>App Store</span>
                        </div>
                      </a>
                    </div>
                  </div>
                </div>
              </div>

              {/* TIER 2: Main Navbar Bar (Vibrant Pink) */}
              <div className="col-12 p-0 primary-bg d-flex align-items-center" style={{ backgroundColor: "#ed1173", height: "50px", minHeight: "50px" }}>
                <style>{`
                  .header-mainnav {
                    display: flex !important;
                    flex-direction: row !important;
                    /* Stretch, not center. Centred, each tab was only as tall as its
                       link, leaving about 10px of dead space between the tab and the
                       dropdown below it. Moving the cursor down crossed that strip,
                       hover ended, and the dropdown closed. Stretched, the tab reaches
                       the bottom of the bar, which is exactly where the dropdown starts.
                       Each .nav-item still centres its own link, so nothing moves. */
                    align-items: stretch !important;
                    gap: 6px !important;
                    margin: 0 0 0 14px !important;
                    padding: 0 !important;
                    list-style: none !important;
                  }
                  @media (min-width: 1400px) {
                    .header-mainnav {
                      gap: 12px !important;
                      margin-left: 22px !important;
                    }
                  }
                  .header-mainnav .nav-item {
                    display: flex !important;
                    align-items: center !important;
                    padding-top: 0 !important;
                    padding-bottom: 0 !important;
                  }
                  .header-mainnav .nav-link {
                    font-size: 15.5px !important;
                    padding: 6px 7px !important;
                    color: #ffffff !important;
                    white-space: nowrap !important;
                    font-weight: 500 !important;
                    line-height: 1.2 !important;
                    text-decoration: none !important;
                    border-radius: 4px !important;
                    transition: background-color 0.15s ease, opacity 0.15s ease !important;
                    transform: none !important;
                  }
                  @media (min-width: 1400px) {
                    .header-mainnav .nav-link {
                      font-size: 16px !important;
                      padding: 6px 10px !important;
                    }
                  }
                  .header-mainnav .nav-link:hover {
                    background-color: rgba(255, 255, 255, 0.18) !important;
                    color: #ffffff !important;
                    transform: none !important;
                  }
                  .header-mainnav .dropdown-toggle::after {
                    margin-left: 4px !important;
                    vertical-align: 1px !important;
                  }
                `}</style>
                <div className="container-fluid px-2 px-xl-3 w-100" style={{ height: "50px" }}>
                  <div className="d-flex w-100 align-items-center flex-nowrap" style={{ height: "50px" }}>
                    <div className="d-flex align-items-center flex-shrink-0">
                      <Link className="navbar-brand-logo me-1 me-xl-2 d-flex align-items-center" to="/">
                        <img
                          src="/images/logo-sm-300.webp"
                          alt="HappyWedz"
                          width="135"
                          height="30"
                          className="d-block"
                          style={{ filter: "brightness(0) invert(1)", height: "30px", objectFit: "contain" }}
                        />
                      </Link>
                    </div>
                    <ul className="navbar-nav header-mainnav d-flex flex-row justify-content-start m-0 p-0" style={{ height: "50px", minHeight: "50px" }}>
                        {/* Planning Tools Dropdown */}
                        <li
                          className="py-0 nav-item dropdown mega-dropdown-wrapper position-static"
                          onMouseEnter={() => handleMegaMenuEnter("planning")}
                          onMouseLeave={handleMegaMenuLeave}
                        >
                          <div className="dropdown-wrapper">
                            <button
                              className="nav-link dropdown-toggle text-white fs-16"
                              onClick={() => setOpenMenu(null)}
                            >
                              Planning Tools
                            </button>

                            <div
                              className="dropdown-menu mega-dropdown w-75 border-0 mt-0 p-4 rounded-0 shadow-sm bg-white"
                              style={{
                                display:
                                  openMenu === "planning" ? "block" : "none",
                              }}
                              onClick={() => setOpenMenu(null)}
                            >
                              <div className="container">
                                <div className="row g-4">
                                  {/* LEFT SECTION */}
                                  <div className="col-md-8">
                                    <p className="fw-semibold text-dark mb-4 fs-16">
                                      Plan your unique wedding
                                    </p>

                                    <div
                                      style={{
                                        display: "grid",
                                        gridTemplateColumns: "repeat(3, 1fr)",
                                        gap: "1.25rem 1rem",
                                      }}
                                    >
                                      {tabs.map((tab) => (
                                        <div
                                          key={tab.id}
                                          onClick={() =>
                                            navigate(
                                              `/user-dashboard/${tab.slug}`,
                                            )
                                          }
                                          className="d-flex align-items-center fs-16"
                                          style={{
                                            cursor: "pointer",
                                            transition:
                                              "color 0.2s ease-in-out",
                                          }}
                                          onMouseEnter={(e) =>
                                            (e.currentTarget.style.color =
                                              "#e91e63")
                                          }
                                          onMouseLeave={(e) =>
                                            (e.currentTarget.style.color =
                                              "#212529")
                                          }
                                        >
                                          <div
                                            className="d-flex align-items-center justify-content-center"
                                            style={{
                                              width: "45px",
                                              height: "45px",
                                              borderRadius: "50%",
                                              backgroundColor: "#ed1173",
                                              color: "#fff",
                                            }}
                                          >
                                            <div
                                              style={{
                                                height: "45px",
                                                width: "45px",
                                                padding: "5px",
                                                border: "none",
                                              }}
                                            >
                                              <img
                                                src={tab.img}
                                                alt=""
                                                style={{
                                                  height: "100%",
                                                  width: "100%",
                                                  objectFit: "contain",
                                                  borderRadius: "50%",
                                                }}
                                              />
                                            </div>
                                          </div>
                                          <span className="ms-2 small">
                                            {tab.label}
                                          </span>
                                        </div>
                                      ))}
                                    </div>
                                  </div>

                                  {/* RIGHT SECTION */}
                                  <div className="col-md-4">
                                    <div className="d-flex flex-column gap-3">
                                      {[
                                        {
                                          title: "Get the HappyWedz App",
                                          desc: "Plan your wedding on the go with the HappyWedz app.",
                                          image: "/images/header/playstore.png",
                                          route:
                                            "https://play.google.com/store/apps/details?id=com.happy.happy_wedz&pcampaignid=web_share",
                                        },
                                        {
                                          title: "Happywedz Website",
                                          desc: "Showcase your wedding website to friends and family.",
                                          image: "/images/couple.png",
                                          route: "/choose-template",
                                        },
                                      ].map((item, i) => (
                                        <div
                                          key={i}
                                          className="p-3 rounded-4 bg-white shadow-lg border-2"
                                          style={{
                                            border: "1px solid #f0f0f0",
                                            cursor: "pointer",
                                            transition: "all 0.2s ease-in-out",
                                          }}
                                          onMouseEnter={(e) =>
                                            (e.currentTarget.style.boxShadow =
                                              "0 4px 12px rgba(0,0,0,0.08)")
                                          }
                          onMouseLeave={(e) =>
                                            (e.currentTarget.style.boxShadow =
                                              "0 2px 4px rgba(0,0,0,0.04)")
                                          }
                                        >
                                          {item.route.startsWith("http") ? (
                                            <a
                                              href={item.route}
                                              target="_blank"
                                              rel="noopener noreferrer"
                                              aria-label={item.title}
                                              className="text-decoration-none d-flex justify-content-between align-items-center"
                                            >
                                              <div className="me-3">
                                                <p className="fw-semibold mb-1 text-dark fs-16">
                                                  {item.title}
                                                </p>
                                                <p
                                                  className="mb-0 text-muted fs-14"
                                                  style={{
                                                    fontSize: "13px",
                                                    lineHeight: "1.4",
                                                  }}
                                                >
                                                  {item.desc}
                                                </p>
                                              </div>
                                              <div>
                                                <img
                                                  src={item.image}
                                                  alt={item.title}
                                                  style={{
                                                    width: "38px",
                                                    height: "38px",
                                                    borderRadius: "8px",
                                                    objectFit: "cover",
                                                  }}
                                                />
                                              </div>
                                            </a>
                                          ) : (
                                            <Link
                                              to={item.route}
                                              aria-label={item.title}
                                              className="text-decoration-none d-flex justify-content-between align-items-center"
                                            >
                                              <div className="me-3">
                                                <p className="fw-semibold mb-1 text-dark fs-16">
                                                  {item.title}
                                                </p>
                                                <p
                                                  className="mb-0 text-muted fs-14"
                                                  style={{
                                                    fontSize: "13px",
                                                    lineHeight: "1.4",
                                                  }}
                                                >
                                                  {item.desc}
                                                </p>
                                              </div>
                                              <div>
                                                <img
                                                  src={item.image}
                                                  alt={item.title}
                                                  style={{
                                                    width: "38px",
                                                    height: "38px",
                                                    borderRadius: "8px",
                                                    objectFit: "cover",
                                                  }}
                                                />
                                              </div>
                                            </Link>
                                          )}
                                        </div>
                                      ))}
                                    </div>
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                        </li>

                        {/* Venues Dropdown */}
                        <li
                          className="py-2 nav-item dropdown mega-dropdown-wrapper position-static"
                          onMouseEnter={() => handleMegaMenuEnter("venues")}
                          onMouseLeave={handleMegaMenuLeave}
                        >
                          <Link
                            to="/venues"
                            className="nav-link dropdown-toggle text-white fs-16"
                            onClick={() => setOpenMenu(null)}
                          >
                            Venues
                          </Link>

                          <div
                            className="dropdown-menu mega-dropdown w-75 shadow border-0 mt-0 rounded-0"
                            style={{
                              display: openMenu === "venues" ? "block" : "none",
                            }}
                            onClick={() => setOpenMenu(null)}
                          >
                            <div className="container-fluid">
                              <div className="row g-4">
                                <div className="col-md-4 d-none d-md-block">
                                  <div className="primary-light-bg rounded-4 shadow-sm p-4 h-100 d-flex flex-column justify-content-between">
                                    <div>
                                      <p className="fw-bold mb-3 fs-16">
                                        Popular Categories
                                      </p>
                                      <div className="d-flex flex-column flex-wrap gap-2">
                                        <Link
                                          to="/venues"
                                          className="primary-text py-2 fs-14 me-2 d-flex align-items-center justify-content-between"
                                        >
                                          Wedding Venues <FaArrowRightLong />
                                        </Link>

                                        <Link
                                          to="/venues"
                                          className="primary-text  py-2 fs-14 me-2 d-flex align-items-center justify-content-between"
                                        >
                                          Popular Locations <FaArrowRightLong />
                                        </Link>

                                        {!isLoggedIn && (
                                          <Link
                                            to="/vendor-login"
                                            className="primary-text  py-2 fs-14 me-2 d-flex align-items-center justify-content-between"
                                          >
                                            Are You Vendor <FaArrowRightLong />
                                          </Link>
                                        )}
                                      </div>
                                    </div>
                                  </div>
                                </div>

                                <div className="col-md-5 p-4">
                                  <p className="fw-bold primary-text text-uppercase mb-3 fs-16">
                                    By Type
                                  </p>
                                  <div className="row">
                                    {(venueSubcategories.length > 0
                                      ? [
                                          ...venueSubcategories.map(
                                            (s) => s.name,
                                          ),
                                          "View All Venues",
                                        ]
                                      : [
                                          "Banquet Halls",
                                          "Marriage Garden / Lawns",
                                          "Wedding Resorts",
                                          "Small Function / Party Halls",
                                          "Destination Wedding Venues",
                                          "Kalyana Mandapams",
                                          "4 Star & Above Wedding Hotels",
                                          "Venue Concierge Services",
                                          "View All Venues",
                                        ]
                                    ).map((item, i) => {
                                      const isShowMore =
                                        item === "View All Venues";
                                      const cleanSlug = item
                                        .toLowerCase()
                                        .replace(/&/g, "and")
                                        .replace(/[^a-z0-9\s-]/g, "")
                                        .replace(/\s+/g, "-")
                                        .replace(/-+/g, "-")
                                        .replace(/^-+|-+$/g, "");
                                      const path = isShowMore
                                        ? "/venues"
                                        : `/venues/${cleanSlug}`;
                                      return (
                                        <div className="col-12 mb-2" key={i}>
                                          <Link
                                            to={path}
                                            className={`dropdown-link d-flex align-items-center ${
                                              isShowMore
                                                ? "primary-text fw-bold text-decoration-underline"
                                                : ""
                                            }`}
                                          >
                                            <i className="bi bi-check-circle text-primary"></i>
                                            <span className="fs-14">
                                              {item}
                                            </span>
                                          </Link>
                                        </div>
                                      );
                                    })}
                                  </div>
                                </div>

                                <div className="col-md-3 p-4">
                                  <p className="fw-bold primary-text text-uppercase mb-3 fs-16">
                                    By City
                                  </p>
                                  <div className="row">
                                    {[
                                      "Mumbai",
                                      "Bangalore",
                                      "Pune",
                                      "Kolkata",
                                      "Jaipur",
                                      "Lucknow",
                                      "Hyderabad",
                                      "More Cities",
                                    ].map((city, i) => {
                                       const isMore = city === "More Cities" || city === "More";
                                       const cityName = isMore ? "More Cities" : city;
                                       const path = isMore
                                         ? "/venues"
                                         : `/wedding-venues/${city.toLowerCase().replace(/[^a-z0-9\s-]/g, "").replace(/\s+/g, "-").replace(/-+/g, "-").replace(/^-+|-+$/g, "")}`;
                                      return (
                                        <div className="col-12 mb-2" key={i}>
                                          <Link
                                            to={path}
                                            aria-label={isMore ? "Explore Wedding Venues in More Cities" : `Wedding Venues in ${city}`}
                                            onClick={() => {
                                              if (!isMore) {
                                                dispatch(setLocation(city));
                                              }
                                            }}
                                            className={`dropdown-link d-flex align-items-center ${
                                              isMore
                                                ? "primary-text fw-bold text-decoration-underline"
                                                : ""
                                            }`}
                                          >
                                            <i className="bi bi-geo-alt text-primary"></i>
                                            <span className="fs-14">
                                              {cityName}
                                            </span>
                                          </Link>
                                        </div>
                                      );
                                    })}
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                        </li>

                        {/* Vendors Dropdown */}
                        <li
                          className="py-2 nav-item dropdown mega-dropdown-wrapper position-static"
                          onMouseEnter={() => handleMegaMenuEnter("vendors")}
                          onMouseLeave={handleMegaMenuLeave}
                        >
                          <div className="dropdown-wrapper">
                            <Link
                              to="/vendors"
                              className="nav-link dropdown-toggle text-white fs-16"
                              onClick={() => setOpenMenu(null)}
                            >
                              Vendors
                            </Link>
                            <div
                              className="dropdown-menu mega-dropdown w-75 shadow border-0 mt-0 p-4 rounded-0"
                              style={{
                                display:
                                  openMenu === "vendors" ? "block" : "none",
                              }}
                              onClick={() => setOpenMenu(null)}
                            >
                              <div className="container">
                                <div
                                  style={{
                                    columnCount: 4,
                                    columnGap: "1rem",
                                  }}
                                  className="grid-layout"
                                >
                                  {vendorCategories.length > 0 &&
                                    vendorCategories.map((cat, i) => (
                                      <div
                                        className="mb-4 d-inline-block w-100"
                                        key={cat.id || i}
                                      >
                                        <div className="fw-bold primary-text text-uppercase mb-2 fs-16">
                                          {cat.name}
                                        </div>
                                        {Array.isArray(cat.subcategories) &&
                                          cat.subcategories.length > 0 && (
                                            <ul className="list-unstyled">
                                              {cat.subcategories.map(
                                                (sub, j) => (
                                                  <li
                                                    key={sub.id || j}
                                                    className="mb-1"
                                                  >
                                                    <Link
                                                      to={`/vendors/${toSlug(sub.name)}/${
                                                        reduxLocation
                                                          ? reduxLocation.toLowerCase().replace(/[^a-z0-9\s-]/g, "").replace(/\s+/g, "-").replace(/-+/g, "-").replace(/^-+|-+$/g, "")
                                                          : "all"
                                                      }`}
                                                      className="dropdown-link fs-14 d-block"
                                                    >
                                                      {formatName(sub.name)}
                                                    </Link>
                                                  </li>
                                                ),
                                              )}
                                            </ul>
                                          )}
                                      </div>
                                    ))}
                                </div>
                              </div>
                            </div>
                          </div>
                        </li>

                        {/* Wedding Inspiration Dropdown */}
                        <li
                          className="py-2 nav-item dropdown mega-dropdown-wrapper position-static"
                          onMouseEnter={() => handleMegaMenuEnter("photography")}
                          onMouseLeave={handleMegaMenuLeave}
                        >
                          <div className="dropdown-wrapper">
                            <Link
                              className="nav-link dropdown-toggle text-white fs-16"
                              to="/photography"
                              id="photoDropdown"
                              role="button"
                              onClick={() => setOpenMenu(null)}
                            >
                              Wedding Inspiration
                            </Link>
                            <div
                              className="dropdown-menu mega-dropdown w-75 shadow border-0 mt-0 p-4 rounded-0"
                              style={{
                                display:
                                  openMenu === "photography" ? "block" : "none",
                              }}
                              onClick={() => setOpenMenu(null)}
                            >
                              <div className="container">
                                <div className="row">
                                  <div className="col-md-9">
                                    <div
                                      style={{
                                        columnCount: 3,
                                        columnGap: "1rem",
                                      }}
                                      className="grid-layout"
                                    >
                                      {photography.length > 0 &&
                                        photography.map((cat, i) => (
                                          <div
                                            className="mb-4 d-inline-block w-100"
                                            key={cat.id || i}
                                          >
                                            <div className="fw-bold primary-text text-uppercase mb-2 fs-16">
                                              {cat.name}
                                            </div>
                                            {Array.isArray(cat.categories) &&
                                              cat.categories.length > 0 && (
                                                <ul className="list-unstyled">
                                                  {cat.categories.map(
                                                    (sub, j) => (
                                                      <li
                                                        key={sub.id || j}
                                                        className="mb-1"
                                                      >
                                                        <Link
                                                          to={`/photography/${toSlug(sub.name)}/${
                                                            reduxLocation
                                                              ? reduxLocation.toLowerCase().replace(/[^a-z0-9\s-]/g, "").replace(/\s+/g, "-").replace(/-+/g, "-").replace(/^-+|-+$/g, "")
                                                              : "all"
                                                          }`}
                                                          className="dropdown-link fs-14 d-block"
                                                        >
                                                          {formatName(sub.name)}
                                                        </Link>
                                                      </li>
                                                    ),
                                                  )}
                                                </ul>
                                              )}
                                          </div>
                                        ))}
                                    </div>
                                  </div>
                                  <div className="col-md-3">
                                    <Link
                                      to="/movment-plus/home"
                                      className="text-decoration-none"
                                      onClick={() => {
                                        window.dispatchEvent(
                                          new CustomEvent("open-movment-sidebar")
                                        );
                                      }}
                                    >
                                      <div className="h-100 d-flex flex-column justify-content-center align-items-center text-center p-1 rounded">
                                        <img
                                          src="https://img.freepik.com/free-photo/bride-groom-having-their-wedding-beach_23-2149043965.jpg?semt=ais_hybrid&w=740&q=80"
                                          alt="Moments Plus"
                                          className="mb-3 rounded"
                                          style={{
                                            width: "100%",
                                            height: "auto",
                                            objectFit: "cover",
                                          }}
                                        />
                                        <div className="fw-bold primary-text text-uppercase fs-16">
                                          Moments Plus
                                        </div>
                                        <div className="small mt-2 fs-14 text-black">
                                          All-new gallery experience for
                                          photographers with Moments+.
                                        </div>
                                      </div>
                                    </Link>
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                        </li>

                        {/* Photography */}
                        <li className="py-2 nav-item dropdown mega-dropdown-wrapper position-static">
                          <div className="dropdown-wrapper">
                            <Link
                              className="nav-link text-white fs-16"
                              to="/movment-plus/home"
                              id="photographyLink"
                              role="button"
                              onClick={() => {
                                window.dispatchEvent(
                                  new CustomEvent("open-movment-sidebar")
                                );
                              }}
                            >
                              Photography
                            </Link>
                          </div>
                        </li>

                        {/* E-Invites Dropdown */}
                        {/* <li
                          className="py-2 nav-item dropdown mega-dropdown-wrapper position-static"
                          onMouseEnter={() => handleMegaMenuEnter("einvites")}
                          onMouseLeave={handleMegaMenuLeave}
                        >
                          <div className="dropdown-wrapper">
                            <Link
                              className="nav-link dropdown-toggle text-white fs-18"
                              to="/einvites"
                              state={{ title: "E-Invites" }}
                              id="einvitesDropdown"
                              role="button"
                              onClick={() => setOpenMenu(null)}
                            >
                              E-Invites
                            </Link>

                            <div
                              className="dropdown-menu mega-dropdown w-75 shadow border-0 mt-0 p-4 rounded-0"
                              style={{
                                display:
                                  openMenu === "einvites" ? "block" : "none",
                              }}
                              onClick={() => setOpenMenu(null)}
                            >
                              <div className="container p-0">
                                <div className="row g-4">
                                  <div className="col-md-12">
                                    <h6 className="fw-semibold mb-3 primary-text text-uppercase">
                                      E-Invitation Categories
                                    </h6>
                                    <ul className="list-unstyled col m-0 p-0">
                                      {einviteCategories.map((sub, j) => (
                                        <li
                                          key={sub.id || j}
                                          className="col-12 col-md-4 mb-1 p-0"
                                        >
                                          <Link
                                            to={`/einvites/category/${sub.cardType}`}
                                            className="dropdown-link small d-block"
                                          >
                                            {formatName(sub.title)}
                                          </Link>
                                        </li>
                                      ))}
                                    </ul>
                                  </div>
                                  <div></div>
                                </div>
                              </div>
                            </div>
                          </div>
                        </li> */}
                        <li
                          className="py-2 nav-item dropdown mega-dropdown-wrapper position-static"
                          onMouseEnter={() => handleMegaMenuEnter("einvites")}
                          onMouseLeave={handleMegaMenuLeave}
                        >
                          <div className="dropdown-wrapper">
                            <Link
                              className="nav-link dropdown-toggle text-white fs-16"
                              to="/einvites"
                              state={{ title: "E-Invites" }}
                              id="einvitesDropdown"
                              role="button"
                              onClick={() => setOpenMenu(null)}
                            >
                              E-Invites
                            </Link>

                            <div
                              className="dropdown-menu mega-dropdown w-75 shadow border-0 mt-0 p-4 rounded-0"
                              style={{
                                display:
                                  openMenu === "einvites" ? "block" : "none",
                              }}
                              onClick={() => setOpenMenu(null)}
                            >
                              <div className="container p-0">
                                <div className="row align-items-start">
                                  {/* LEFT SIDE MENU */}
                                  <div className="col-md-6">
                                    <p className="fw-semibold mb-3 primary-text text-uppercase fs-16">
                                      E-Invitation Categories
                                    </p>
                                    <ul className="list-unstyled m-0 p-0">
                                      {einviteCategories.map((sub, j) => (
                                        <li key={j} className="mb-2">
                                          <Link
                                            to={`/einvites/category/${sub.cardType}`}
                                            className="dropdown-link fs-14 d-block"
                                          >
                                            {formatName(sub.title)}
                                          </Link>
                                        </li>
                                      ))}
                                    </ul>
                                  </div>

                                  {/* RIGHT SIDE IMAGES */}
                                  <div className="col-md-6">
                                    <div className="d-flex gap-2 justify-content-between">
                                      <img
                                        src="/e-card1.jpg"
                                        alt=""
                                        className="rounded"
                                        style={{
                                          width: "32%",
                                          height: "100px",
                                          objectFit: "cover",
                                        }}
                                      />
                                      <img
                                        src="/e-card20.png"
                                        alt=""
                                        className="rounded"
                                        style={{
                                          width: "32%",
                                          height: "100px",
                                          objectFit: "cover",
                                        }}
                                      />
                                      <img
                                        src="/e-card3.jpg"
                                        alt=""
                                        className="rounded"
                                        style={{
                                          width: "32%",
                                          height: "100px",
                                          objectFit: "cover",
                                        }}
                                      />
                                    </div>
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                        </li>

                        {/* Shop */}
                        <li className="py-2 nav-item dropdown mega-dropdown-wrapper position-static">
                          <div className="dropdown-wrapper">
                            <a
                              className="nav-link text-white fs-16"
                              href={`${STORE_ORIGIN}/`}
                              id="shopLink"
                              role="button"
                              target="_blank"
                              rel="noopener noreferrer"
                            >
                              Shop
                            </a>
                          </div>
                        </li>

                        {/* Blog Dropdown */}
                        {/* <li
                          className="py-2 nav-item dropdown mega-dropdown-wrapper position-static"
                          onMouseEnter={() => setOpenMenu("blog")}
                          onMouseLeave={() => setOpenMenu(null)}
                        >
                          <div className="dropdown-wrapper">
                            <Link
                              className="nav-link dropdown-toggle text-white fs-16"
                              to="/blog"
                              state={{ title: "Blog" }}
                              id="blog"
                              role="button"
                              onClick={() => setOpenMenu(null)}
                            >
                              Blog
                            </Link>

                            <div
                              className="dropdown-menu mega-dropdown w-75 shadow border-0 mt-0 p-4 rounded-0"
                              style={{
                                display: openMenu === "blog" ? "block" : "none",
                              }}
                              onClick={() => setOpenMenu(null)}
                            >
                              <div className="container">
                                <div className="row">
                                  <div className="col-12 col-md-3">
                                    <div className="fw-bold primary-text text-uppercase fs-16">
                                      Browse by Category
                                    </div>
                                    <ul className="list-unstyled col mt-2 p-0">
                                      {browseByCategory.map((cat) => (
                                        <li
                                          key={cat.id}
                                          className="dropdown-link fs-14 d-block mb-2"
                                        >
                                          <Link
                                            to={`/blog?type=browse_by_category&categoryId=${cat.id}`}
                                            style={{
                                              textDecoration: " none",
                                              color: "#212529",
                                              marginBottom: "10px",
                                            }}
                                          >
                                            {formatName(cat.name)}
                                          </Link>
                                        </li>
                                      ))}
                                    </ul>
                                  </div>

                                  <div className="col-12 col-md-3">
                                    <h6 className="primary-text fw-bold fs-16">
                                      Popular Sections
                                    </h6>
                                    <ul className="list-unstyled mt-2">
                                      {popularSections.map((cat) => (
                                        <li
                                          key={cat.id}
                                          className="dropdown-link fs-14 d-block mb-2"
                                        >
                                          <Link
                                            to={`/blog?type=popular_section&categoryId=${cat.id}`}
                                            style={{
                                              textDecoration: " none",
                                              color: "#212529",
                                            }}
                                          >
                                            {formatName(cat.name)}
                                          </Link>
                                        </li>
                                      ))}
                                    </ul>
                                  </div>

                                  <div className="col-12 col-md-3">
                                    <h6 className="primary-text fw-bold fs-16">
                                      Most Searched Blogs
                                    </h6>
                                    <ul className="list-unstyled mb-0 mt-2">
                                      {mostSearchedBlogs.map((cat) => (
                                        <li
                                          key={cat.id}
                                          className="dropdown-link fs-14 d-block mb-2"
                                        >
                                          <Link
                                            to={`/blog?type=most_searched&categoryId=${cat.id}`}
                                            style={{
                                              textDecoration: " none",
                                              color: "#212529",
                                            }}
                                          >
                                            {formatName(cat.name)}
                                          </Link>
                                        </li>
                                      ))}
                                    </ul>
                                  </div>
                                  <div className="col-12 col-md-3 d-flex flex-column align-items-center">
                                    
                                    <img
                                      src="/blog1.jpg"
                                      alt="Top"
                                      style={{
                                        width: "100%",
                                        height: "auto",
                                        marginBottom: "10px",
                                        borderRadius: "10px",
                                      }}
                                    />

                                    <img
                                      src="/blog2.jpg"
                                      alt="Bottom"
                                      style={{
                                        width: "100%",
                                        height: "auto",
                                        borderRadius: "10px",
                                      }}
                                    />
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                        </li> */}

                        {/* Genie */}
                        <li className="py-2 nav-item dropdown mega-dropdown-wrapper position-static">
                          <div className="dropdown-wrapper">
                            <Link
                              className="nav-link text-white fs-16"
                              to="/shaadi-ai"
                              state={{ title: "Genie" }}
                              id="photoDropdown"
                              role="button"
                            >
                              ShaadiAI
                            </Link>
                          </div>
                        </li>

                        {/* Honeymoon */}
                        <li className="py-2 nav-item dropdown mega-dropdown-wrapper position-static">
                          <div className="dropdown-wrapper">
                            <Link
                              className="nav-link text-white fs-16"
                              to="/honeymoon"
                              id="honeymoonLink"
                              role="button"
                            >
                              Honeymoon
                            </Link>
                          </div>
                        </li>

                        {/* Real Wedding Dropdown */}
                        {/* <li
                          className="py-2 nav-item dropdown mega-dropdown-wrapper position-static"
                          onMouseEnter={() => setOpenMenu("real-wedding")}
                          onMouseLeave={() => setOpenMenu(null)}
                        >
                          <div className="dropdown-wrapper">
                            <Link
                              className="nav-link dropdown-toggle text-white fs-16"
                              to="/real-wedding"
                              state={{ title: "Real Wedding" }}
                              id="real-wedding"
                              role="button"
                              onClick={() => setOpenMenu(null)}
                            >
                              Real Wedding
                            </Link>

                            <div
                              className="dropdown-menu mega-dropdown w-75 shadow border-0 mt-0 p-4 rounded-0"
                              style={{
                                display:
                                  openMenu === "real-wedding"
                                    ? "block"
                                    : "none",
                              }}
                              onClick={() => setOpenMenu(null)}
                            >
                              <div className="container">
                                <div className="row">
                                  <div className="col-12 col-md-3">
                                    <div className="fw-bold primary-text text-uppercase fs-16">
                                      By City
                                    </div>
                                    <ul className="list-unstyled mb-0 mt-2">
                                      {byCity.map((city, index) => (
                                        <li
                                          key={index}
                                          className="dropdown-link small d-block"
                                        >
                                          <Link
                                            className="fs-14"
                                            to="/real-wedding"
                                            style={{
                                              textDecoration: "none",
                                              color: "#212529",
                                            }}
                                            onClick={() => {
                                              setSelectCity(city);
                                              setSelectedCulture(
                                                "All Cultures",
                                              );
                                              setSelectedTheme("All Themes");
                                            }}
                                          >
                                            {city}
                                          </Link>
                                        </li>
                                      ))}
                                    </ul>
                                  </div>

                                  <div className="col-12 col-md-3">
                                    <h6 className="primary-text fw-bold fs-16">
                                      By Culture
                                    </h6>
                                    <ul className="list-unstyled mb-0 mt-2">
                                      {cultures.map((culture, index) => (
                                        <li
                                          key={index}
                                          className="dropdown-link small d-block"
                                        >
                                          <Link
                                            className="fs-14"
                                            to="/real-wedding"
                                            style={{
                                              textDecoration: " none",
                                              color: "#212529",
                                            }}
                                            onClick={() => {
                                              setSelectedCulture(
                                                culture?.name || culture,
                                              );
                                              setSelectCity("All Cities");
                                              setSelectedTheme("All Themes");
                                            }}
                                          >
                                            {culture.name}
                                          </Link>
                                        </li>
                                      ))}
                                    </ul>
                                  </div>

                                  <div className="col-12 col-md-3">
                                    <h6 className="primary-text fw-bold fs-16">
                                      By Theme
                                    </h6>
                                    <ul className="list-unstyled mb-0 mt-2">
                                      {themes.map((theme, index) => (
                                        <li
                                          key={index}
                                          className="dropdown-link small d-block"
                                        >
                                          <Link
                                            className="fs-14"
                                            to="/real-wedding"
                                            style={{
                                              textDecoration: " none",
                                              color: "#212529",
                                            }}
                                            onClick={() => {
                                              setSelectedTheme(theme);
                                              setSelectCity("All Cities");
                                              setSelectedCulture(
                                                "All Cultures",
                                              );
                                            }}
                                          >
                                            {theme}
                                          </Link>
                                        </li>
                                      ))}
                                    </ul>
                                  </div>
                                  <div className="col-12 col-md-3 d-flex flex-column align-items-center">
                                    <img
                                      src="/realweding1.jpg"
                                      alt="Top"
                                      style={{
                                        width: "100%",
                                        height: "auto",
                                        marginBottom: "10px",
                                        borderRadius: "10px",
                                      }}
                                    />

                                    <img
                                      src="/realweding2.jpg"
                                      alt="Bottom"
                                      style={{
                                        width: "100%",
                                        height: "auto",
                                        borderRadius: "10px",
                                      }}
                                    />
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                        </li> */}

                      </ul>
                      {/* Right Actions: Circular Profile Avatar (Only shows dropdown when logged in) */}
                      <div
                        ref={profileMenuContainerRef}
                        className="position-relative d-inline-flex align-items-center ms-auto me-1 flex-shrink-0"
                        onMouseEnter={handleProfileMouseEnter}
                        onMouseLeave={handleProfileMouseLeave}
                        style={{ height: "100%", zIndex: 1050 }}
                      >
                        {isLoggedIn ? (
                          /* Logged-in Profile Avatar Button with Dropdown Triangle */
                          <button
                            type="button"
                            onClick={() => {
                              if (profileMenuTimeoutRef.current) {
                                clearTimeout(profileMenuTimeoutRef.current);
                                profileMenuTimeoutRef.current = null;
                              }
                              setProfileMenuOpen((prev) => !prev);
                            }}
                            aria-label="User profile and menu"
                            aria-expanded={profileMenuOpen}
                            style={{
                              backgroundColor: "transparent",
                              border: "none",
                              display: "inline-flex",
                              alignItems: "center",
                              gap: "5px",
                              cursor: "pointer",
                              padding: "2px 0",
                              transition: "all 0.2s ease",
                            }}
                            title={profileName || "Profile Menu"}
                          >
                            <div
                              style={{
                                width: "36px",
                                height: "36px",
                                borderRadius: "50%",
                                backgroundColor: "#ffffff",
                                border: "2px solid rgba(255, 255, 255, 0.9)",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                boxShadow: profileMenuOpen
                                  ? "0 0 0 3px rgba(255, 255, 255, 0.45)"
                                  : "0 2px 6px rgba(0, 0, 0, 0.16)",
                                transition: "all 0.2s ease",
                                transform: profileMenuOpen ? "scale(1.05)" : "scale(1)",
                              }}
                            >
                              <FiUser
                                style={{
                                  color: isVendorLoggedIn ? "#7c3aed" : "#ed1173",
                                  fontSize: "19px",
                                }}
                              />
                            </div>
                            <FaCaretDown
                              style={{
                                color: "#ffffff",
                                fontSize: "13px",
                                transition: "transform 0.2s ease",
                                transform: profileMenuOpen ? "rotate(180deg)" : "rotate(0deg)",
                                filter: "drop-shadow(0 1px 2px rgba(0, 0, 0, 0.25))",
                              }}
                            />
                          </button>
                        ) : (
                          /* Guest: Direct link to Customer Login without any popup dropdown */
                          <Link
                            to="/customer-login"
                            aria-label="Customer Log In"
                            title="Log In"
                            style={{
                              width: "36px",
                              height: "36px",
                              borderRadius: "50%",
                              backgroundColor: "#ffffff",
                              border: "2px solid rgba(255, 255, 255, 0.9)",
                              display: "flex",
                              alignItems: "center",
                              justifyContent: "center",
                              cursor: "pointer",
                              padding: 0,
                              boxShadow: "0 2px 6px rgba(0, 0, 0, 0.16)",
                              transition: "all 0.2s ease",
                              textDecoration: "none",
                            }}
                            onMouseEnter={(e) => {
                              e.currentTarget.style.transform = "scale(1.05)";
                              e.currentTarget.style.boxShadow =
                                "0 0 0 3px rgba(255, 255, 255, 0.45)";
                            }}
                            onMouseLeave={(e) => {
                              e.currentTarget.style.transform = "scale(1)";
                              e.currentTarget.style.boxShadow =
                                "0 2px 6px rgba(0, 0, 0, 0.16)";
                            }}
                          >
                            <FiUser
                              style={{
                                color: "#ed1173",
                                fontSize: "19px",
                              }}
                            />
                          </Link>
                        )}

                        {/* Dropdown Menu (ONLY rendered when logged in) */}
                        {isLoggedIn && profileMenuOpen && (
                          <div
                            onMouseEnter={handleProfileMouseEnter}
                            onMouseLeave={handleProfileMouseLeave}
                            style={{
                              position: "absolute",
                              top: "100%",
                              right: 0,
                              paddingTop: "6px",
                              zIndex: 1050,
                              minWidth: "230px",
                            }}
                          >
                            {/* Invisible hover bridge connecting button to card */}
                            <div
                              style={{
                                position: "absolute",
                                top: "-15px",
                                left: "-50px",
                                right: 0,
                                height: "20px",
                                backgroundColor: "transparent",
                                pointerEvents: "auto",
                              }}
                            />
                            <div
                              style={{
                                backgroundColor: "#ffffff",
                                borderRadius: "14px",
                                boxShadow:
                                  "0 12px 32px rgba(0, 0, 0, 0.18), 0 2px 8px rgba(0, 0, 0, 0.06)",
                                border: "1px solid #eaeaea",
                                overflow: "hidden",
                                textAlign: "left",
                                position: "relative",
                              }}
                            >
                              {/* Logged-In User/Vendor Header */}
                              <div
                                style={{
                                  padding: "12px 16px",
                                  background:
                                    "linear-gradient(135deg, #fff2f6 0%, #ffffff 100%)",
                                  borderBottom: "1px solid #f0f0f0",
                                }}
                              >
                                <div
                                  style={{
                                    fontWeight: "700",
                                    fontSize: "14px",
                                    color: "#1f2937",
                                    whiteSpace: "nowrap",
                                    overflow: "hidden",
                                    textOverflow: "ellipsis",
                                  }}
                                >
                                  {profileName ||
                                    (isVendorLoggedIn ? "Vendor Partner" : "My Account")}
                                </div>
                                {profileEmail && (
                                  <div
                                    style={{
                                      fontSize: "12px",
                                      color: "#6b7280",
                                      marginTop: "2px",
                                      whiteSpace: "nowrap",
                                      overflow: "hidden",
                                      textOverflow: "ellipsis",
                                    }}
                                  >
                                    {profileEmail}
                                  </div>
                                )}
                                <span
                                  style={{
                                    display: "inline-block",
                                    fontSize: "10px",
                                    fontWeight: "700",
                                    textTransform: "uppercase",
                                    letterSpacing: "0.5px",
                                    padding: "2px 8px",
                                    borderRadius: "10px",
                                    backgroundColor: isVendorLoggedIn
                                      ? "#7c3aed"
                                      : "#e72e76",
                                    color: "#ffffff",
                                    marginTop: "6px",
                                  }}
                                >
                                  {isVendorLoggedIn ? "Vendor" : "Customer"}
                                </span>
                              </div>

                              {/* Menu Options */}
                              <div style={{ padding: "6px 0" }}>
                                {isUserLoggedIn && (
                                  <Link
                                    to="/user-dashboard"
                                    onClick={() => setProfileMenuOpen(false)}
                                    style={{
                                      display: "flex",
                                      alignItems: "center",
                                      gap: "10px",
                                      padding: "10px 16px",
                                      color: "#374151",
                                      textDecoration: "none",
                                      fontSize: "13px",
                                      fontWeight: "600",
                                      transition: "background-color 0.15s",
                                    }}
                                    onMouseEnter={(e) =>
                                      (e.currentTarget.style.backgroundColor =
                                        "#fff0f5")
                                    }
                                    onMouseLeave={(e) =>
                                      (e.currentTarget.style.backgroundColor =
                                        "transparent")
                                    }
                                  >
                                    <FiGrid size={16} color="#e72e76" />
                                    <span>User Dashboard</span>
                                  </Link>
                                )}

                                {isVendorLoggedIn && (
                                  <Link
                                    to="/vendor-dashboard"
                                    onClick={() => setProfileMenuOpen(false)}
                                    style={{
                                      display: "flex",
                                      alignItems: "center",
                                      gap: "10px",
                                      padding: "10px 16px",
                                      color: "#374151",
                                      textDecoration: "none",
                                      fontSize: "13px",
                                      fontWeight: "600",
                                      transition: "background-color 0.15s",
                                    }}
                                    onMouseEnter={(e) =>
                                      (e.currentTarget.style.backgroundColor =
                                        "#f5f3ff")
                                    }
                                    onMouseLeave={(e) =>
                                      (e.currentTarget.style.backgroundColor =
                                        "transparent")
                                    }
                                  >
                                    <FiGrid size={16} color="#7c3aed" />
                                    <span>Vendor Dashboard</span>
                                  </Link>
                                )}

                                <div
                                  style={{
                                    height: "1px",
                                    backgroundColor: "#f0f0f0",
                                    margin: "4px 0",
                                  }}
                                />

                                <button
                                  onClick={() => {
                                    setProfileMenuOpen(false);
                                    handleLogout();
                                  }}
                                  style={{
                                    width: "100%",
                                    display: "flex",
                                    alignItems: "center",
                                    gap: "10px",
                                    padding: "10px 16px",
                                    color: "#dc2626",
                                    backgroundColor: "transparent",
                                    border: "none",
                                    fontSize: "13px",
                                    fontWeight: "600",
                                    cursor: "pointer",
                                    transition: "background-color 0.15s",
                                    textAlign: "left",
                                  }}
                                  onMouseEnter={(e) =>
                                    (e.currentTarget.style.backgroundColor =
                                      "#fef2f2")
                                  }
                                  onMouseLeave={(e) =>
                                    (e.currentTarget.style.backgroundColor =
                                      "transparent")
                                  }
                                >
                                  <FiLogOut size={16} color="#dc2626" />
                                  <span>Logout</span>
                                </button>
                              </div>
                            </div>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </nav>
    </>
  );
};

export default Header;
