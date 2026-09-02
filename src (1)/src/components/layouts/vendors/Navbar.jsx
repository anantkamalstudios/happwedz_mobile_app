import React, { useEffect, useState, useMemo } from "react";
import { useSelector } from "react-redux";
import { FaGift, FaStore, FaEnvelope, FaStar, FaCog } from "react-icons/fa";
import { LiaHomeSolid } from "react-icons/lia";
import { FaRegStar } from "react-icons/fa";
import { PiOfficeChairLight } from "react-icons/pi";
import { GoMail } from "react-icons/go";
import { IoSettingsOutline } from "react-icons/io5";
import { IoStorefrontOutline } from "react-icons/io5";
import { Link, useNavigate, useParams } from "react-router-dom";
import vendorServicesApi from "../../../services/api/vendorServicesApi";

const Navbar = () => {
  const { slug } = useParams();
  const navigate = useNavigate();
  const { token, vendor } = useSelector((state) => state.vendorAuth || {});
  const [activeTab, setActiveTab] = useState("home");
  const [storedCompletion, setStoredCompletion] = useState(0);
  const [isMobile, setIsMobile] = useState(
    typeof window !== "undefined" ? window.innerWidth <= 576 : false
  );
  const [unreadEnquiryCount, setUnreadEnquiryCount] = useState(0);
  const [showEnquiryBadge, setShowEnquiryBadge] = useState(() => {
    const stored = localStorage.getItem("showEnquiryCountBadge");
    return stored !== null ? stored === "true" : true;
  });

  useEffect(() => {
    const stored = localStorage.getItem("storefrontCompletion");
    if (stored) {
      setStoredCompletion(parseInt(stored, 10));
    }
  }, []);

  // listen for resize to adapt navbar for small screens
  useEffect(() => {
    const onResize = () => {
      setIsMobile(window.innerWidth <= 576);
    };
    onResize();
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);

  // Fetch storefront completion from backend API
  useEffect(() => {
    const fetchCompletion = async () => {
      // Always resolve service ID from logged-in vendor (avoid stale localStorage)
      let serviceId = null;
      if (vendor?.id && token) {
        serviceId = await vendorServicesApi.getServiceIdByVendorId(
          vendor.id,
          token
        );
        if (serviceId) {
          localStorage.setItem("vendorServiceId", serviceId.toString());
        }
      }

      if (!serviceId || !token) return;

      try {
        const response = await fetch(
          `https://happywedz.com/api/vendor-services/${serviceId}/storefront-completion`,
          {
            method: "GET",
            headers: {
              Authorization: `Bearer ${token}`,
            },
          }
        );
        if (response.ok) {
          const data = await response.json();

          // Handle both response formats and coerce to a safe numeric value
          let completionValue = undefined;
          if (data && typeof data === "object") {
            if (
              data.service &&
              typeof data.service === "object" &&
              data.service.storefront_completion !== undefined
            ) {
              completionValue = Number(data.service.storefront_completion);
            } else if (data.storefront_completion !== undefined) {
              completionValue = Number(data.storefront_completion);
            }
          }

          if (!Number.isFinite(completionValue)) {
            console.log(
              "Navbar: invalid completion value, defaulting to 0",
              completionValue
            );
            completionValue = 0;
          }

          // Clamp to 0..100
          completionValue = Math.max(
            0,
            Math.min(100, Math.round(completionValue))
          );

          setStoredCompletion(completionValue);
          localStorage.setItem(
            "storefrontCompletion",
            completionValue.toString()
          );
        }
      } catch (error) {
        console.error("Failed to fetch storefront completion:", error);
        // Fall back to localStorage if API fails
        const stored = localStorage.getItem("storefrontCompletion");
        if (stored) {
          setStoredCompletion(parseInt(stored, 10));
        }
      }
    };
    fetchCompletion();
  }, [vendor?.id, token]);

  // Fetch unread enquiry count
  useEffect(() => {
    const fetchUnreadCount = async () => {
      if (!token) return;

      try {
        const response = await fetch("https://happywedz.com/api/inbox", {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });

        if (response.ok) {
          const data = await response.json();
          setUnreadEnquiryCount(data.unreadCount || 0);
        }
      } catch (error) {
        console.error("Failed to fetch unread enquiry count:", error);
      }
    };

    fetchUnreadCount();

    // Refresh count every 30 seconds
    const interval = setInterval(fetchUnreadCount, 30000);
    return () => clearInterval(interval);
  }, [token]);

  // Listen for changes in the badge setting
  useEffect(() => {
    const handleStorageChange = () => {
      const stored = localStorage.getItem("showEnquiryCountBadge");
      setShowEnquiryBadge(stored !== null ? stored === "true" : true);
    };

    // Listen for custom event when setting changes in same tab
    const handleCustomStorageChange = () => {
      handleStorageChange();
    };

    window.addEventListener("storage", handleStorageChange);
    window.addEventListener(
      "enquiryBadgeSettingChanged",
      handleCustomStorageChange
    );
    // Also check periodically in case localStorage was changed in same tab
    const interval = setInterval(handleStorageChange, 1000);

    return () => {
      window.removeEventListener("storage", handleStorageChange);
      window.removeEventListener(
        "enquiryBadgeSettingChanged",
        handleCustomStorageChange
      );
      clearInterval(interval);
    };
  }, []);

  // Check if vendor is a photographer (vendor type id = 1 or 12)
  const isPhotographer = useMemo(() => {
    const vendorTypeId = vendor?.vendor_type_id;
    return vendorTypeId === 1 || vendorTypeId === 12;
  }, [vendor?.vendorType?.id]);

  const tabs = useMemo(() => {
    const baseTabs = [
      {
        id: "home",
        slug: "vendor-home",
        label: "Home",
        icon: "/images/vendorsDashboard/homeico.png",
      },
      {
        id: "storefront",
        slug: "vendor-store-front",
        label: "Storefront",
        icon: "/images/vendorsDashboard/storefrontico.png",
      },
      {
        id: "enquiries",
        slug: "vendor-enquiries",
        label: "Enquiries",
        icon: "/images/vendorsDashboard/enquireico.png",
      },
      {
        id: "message",
        slug: "vendor-messages",
        label: "Messages",
        icon: "/images/vendorsDashboard/chat.png",
      },
      {
        id: "reviews",
        slug: "vendor-reviews",
        label: "Reviews",
        icon: "/images/vendorsDashboard/reviewico.png",
      },
    ];

    // Only add Movments+ tab for photographers (vendor type id = 1 or 12)
    if (isPhotographer) {
      baseTabs.push({
        id: "movments-plus",
        slug: "movments-plus",
        label: "Movments+",
        icon: "/images/vendorsDashboard/live.png",
      });
    }

    baseTabs.push({
      id: "settings",
      slug: "vendor-setting",
      label: "Settings",
      icon: "/images/vendorsDashboard/settingsico.png",
    });

    return baseTabs;
  }, [isPhotographer]);

  useEffect(() => {
    const foundTab = tabs.find((tab) => tab.slug === slug);
    if (foundTab) {
      setActiveTab(foundTab.id);
    }
  }, [slug]);

  const handleTabClick = (tab) => {
    setActiveTab(tab.id);
    navigate(`/vendor-dashboard/${tab.slug}`);
    window.scrollTo({ top: 0, left: 0, behavior: "instant" });
  };
  return (
    <div className="adminNav">
      <div
        className="container py-2 vendor-dashboard-navbar mt-2"
        style={{
          paddingLeft: isMobile ? 12 : undefined,
          paddingRight: isMobile ? 12 : undefined,
          maxWidth: "1320px",
          overflowX: "hidden",
        }}
      >
        <div
          className="d-flex flex-column flex-lg-row justify-content-between align-items-start align-items-lg-center gap-3"
          style={{ minWidth: 0, width: "100%" }}
        >
          <div
            className="d-flex gap-3 gap-lg-4"
            style={{
              flexWrap: isMobile ? "nowrap" : "wrap",
              overflowX: isMobile ? "auto" : "visible",
              WebkitOverflowScrolling: isMobile ? "touch" : undefined,
              paddingBottom: isMobile ? 8 : undefined,
              gap: isMobile ? 12 : undefined,
              maxWidth: "100%",
            }}
          >
            {tabs.map((tab) => (
              <button
                key={tab.id}
                className={`btn border-0 d-flex flex-column align-items-center p-0 position-relative ${
                  activeTab === tab.id ? "active-tab" : ""
                }`}
                style={{
                  background: "transparent",
                  fontSize: isMobile ? 12 : 14,
                  minWidth: isMobile ? 56 : 70,
                  color:
                    activeTab === tab.id ? "var(--primary-color)" : "#2c3e50",
                  paddingLeft: isMobile ? 6 : undefined,
                  paddingRight: isMobile ? 6 : undefined,
                  marginRight: isMobile ? 4 : undefined,
                }}
                onClick={() => handleTabClick(tab)}
              >
                <div style={{ position: "relative" }}>
                  <img
                    src={tab.icon}
                    alt={tab.label}
                    style={{
                      width: isMobile ? 24 : 30,
                      height: isMobile ? 24 : 30,
                      objectFit: "cover",
                      display: "block",
                    }}
                  />
                  {tab.id === "enquiries" &&
                    showEnquiryBadge &&
                    unreadEnquiryCount > 0 && (
                      <span
                        style={{
                          position: "absolute",
                          top: -6,
                          right: -6,
                          backgroundColor: "#f12d85",
                          color: "white",
                          borderRadius: "50%",
                          minWidth: isMobile ? 16 : 18,
                          height: isMobile ? 16 : 18,
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          fontSize: isMobile ? 9 : 10,
                          fontWeight: "bold",
                          padding: unreadEnquiryCount > 99 ? "0 4px" : "0",
                          border: "2px solid white",
                        }}
                      >
                        {unreadEnquiryCount > 99 ? "99+" : unreadEnquiryCount}
                      </span>
                    )}
                </div>
                <span
                  className="mt-3"
                  style={{
                    marginTop: isMobile ? 6 : 12,
                    fontSize: isMobile ? 11 : 14,
                  }}
                >
                  {tab.label}
                </span>
              </button>
            ))}
          </div>

          {/* Right side: Go Premium + small storefront completion (label above bar) */}
          <div
            className="d-flex align-items-center gap-2 bg-light px-3 rounded-3"
            style={{
              paddingTop: 8,
              paddingBottom: 8,
              maxWidth: "100%",
              overflowX: "hidden",
            }}
          >
            <div
              style={{
                display: "flex",
                flexDirection: "column",
                alignItems: "flex-start",
                gap: 6,
              }}
            >
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: isMobile ? 12 : 40,
                  flexWrap: isMobile ? "wrap" : "nowrap",
                  rowGap: isMobile ? 8 : undefined,
                  width: "100%",
                }}
              >
                {/* Compact progress bar */}
                <div
                  style={{
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    gap: 8,
                  }}
                >
                  <span
                    style={{
                      color: "#2c3e50",
                      fontWeight: "600",
                      fontSize: "14px",
                      whiteSpace: "nowrap",
                      marginBottom: 2,
                    }}
                  >
                    Storefront Setup Progress
                  </span>
                  <div
                    style={{ display: "flex", alignItems: "center", gap: 8 }}
                  >
                    <div
                      style={{
                        width: isMobile ? 100 : 120,
                        height: 8,
                        background: "#e9ecef",
                        borderRadius: 6,
                        overflow: "hidden",
                      }}
                    >
                      <div
                        style={{
                          width: `${storedCompletion}%`,
                          height: "100%",
                          background: "#f12d85",
                          transition: "width 250ms ease",
                        }}
                      />
                    </div>
                    <span
                      style={{
                        fontWeight: 700,
                        fontSize: 13,
                        color: "#2c3e50",
                        minWidth: 36,
                        textAlign: "right",
                      }}
                    >
                      {storedCompletion}%
                    </span>
                  </div>
                </div>
                <div
                  style={{
                    display: "flex",
                    flexDirection: "column",
                  }}
                >
                  <span
                    style={{
                      color: "#2c3e50",
                      fontWeight: "600",
                      fontSize: "14px",
                      whiteSpace: "nowrap",
                      marginBottom: 2,
                    }}
                  >
                    Grow Your Business
                  </span>
                  <Link className="btn upgrade-btn border-0 p-0">
                    Upgrade Now
                  </Link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Navbar;
