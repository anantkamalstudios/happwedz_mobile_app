import React, { useState, useEffect } from "react";
import { Nav } from "react-bootstrap";
import {
  MdDashboard,
  MdLink,
  MdCloudUpload,
  MdPhotoLibrary,
  MdAnalytics,
  MdStorage,
  MdPeople,
  MdSettings,
  MdOutlineToken,
} from "react-icons/md";
import { LuLayoutDashboard } from "react-icons/lu";
import { FiCalendar } from "react-icons/fi";

import Dashboard from "./Dashboard";
import Events from "./Events";
import TokensSharing from "./TokensSharing";
import UploadMedia from "./UploadMedia";
import Galleries from "./Galleries";
import Analytics from "./Analytics";
import PackagesStorage from "./PackagesStorage";
import GuestsAccess from "./GuestsAccess";
import Settings from "./Settings";
import { IoCloudUploadOutline, IoSettingsOutline } from "react-icons/io5";
import { TbDeviceDesktopAnalytics, TbLibraryPhoto } from "react-icons/tb";
import { GrStorage } from "react-icons/gr";
import { GoPeople } from "react-icons/go";

const MovmentsPlus = () => {
  const [activeTab, setActiveTab] = useState("dashboard");
  const [activeParams, setActiveParams] = useState(null);

  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }, [activeTab]);

  const handleNavigate = (tabId, params = null) => {
    setActiveTab(tabId);
    setActiveParams(params);
  };

  const menuItems = [
    {
      id: "dashboard",
      label: "Dashboard",
      icon: <LuLayoutDashboard size={22} />,
    },
    {
      id: "events",
      label: "Events",
      icon: <FiCalendar size={22} />,
    },
    {
      id: "tokens-sharing",
      label: "Tokens & Sharing",
      icon: <MdOutlineToken size={22} />,
    },
    {
      id: "upload-media",
      label: "Upload Media",
      icon: <IoCloudUploadOutline size={22} />,
    },
    {
      id: "galleries",
      label: "Galleries",
      icon: <TbLibraryPhoto size={22} />,
    },
    {
      id: "analytics",
      label: "Analytics",
      icon: <TbDeviceDesktopAnalytics size={22} />,
    },
    {
      id: "packages-storage",
      label: "Packages & Storage",
      icon: <GrStorage size={22} />,
    },
    // {
    //   id: "guests-access",
    //   label: "Guests Access",
    //   icon: <GoPeople size={22} />,
    // },
    // {
    //   id: "settings",
    //   label: "Settings",
    //   icon: <IoSettingsOutline size={22} />,
    // },
  ];

  const handleTabClick = (tabId) => {
    setActiveTab(tabId);
    setActiveParams(null);
  };

  const renderContent = () => {
    switch (activeTab) {
      case "dashboard":
        return <Dashboard onNavigate={handleNavigate} />;
      case "events":
        return <Events onNavigate={handleNavigate} />;
      case "tokens-sharing":
        return <TokensSharing />;
      case "upload-media":
        return <UploadMedia initialParams={activeParams} />;
      case "galleries":
        return <Galleries />;
      case "analytics":
        return <Analytics />;
      case "packages-storage":
        return <PackagesStorage />;
      case "guests-access":
        return <GuestsAccess />;
      case "settings":
        return <Settings />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <div className="container-fluid py-3 px-3 px-lg-4 px-xl-5 movments-plus-container">
      <div className="row">
        {/* Mobile Navigation */}
        <div className="col-12 d-md-none mb-3">
          <div
            className="d-flex overflow-auto pb-2 gap-2 mobile-nav-scrollbar"
            style={{ whiteSpace: "nowrap", scrollbarWidth: "none" }}
          >
            {menuItems.map((item) => (
              <button
                key={item.id}
                onClick={() => handleTabClick(item.id)}
                className={`btn btn-sm d-flex align-items-center gap-2 ${
                  activeTab === item.id
                    ? "bg-primary text-white border-primary"
                    : "bg-white text-secondary border"
                }`}
                style={{
                  borderRadius: "20px",
                  padding: "0.5rem 1rem",
                  flexShrink: 0,
                  transition: "all 0.2s",
                }}
              >
                <span style={{ fontSize: "1.1em" }}>{item.icon}</span>
                <span>{item.label}</span>
              </button>
            ))}
          </div>
        </div>

        <div className="col-lg-2 col-md-3 border-end pe-lg-4 pe-md-3 d-none d-md-block">
          <div className="sticky-top" style={{ top: "20px" }}>
            <h4 className="mb-4 fw-bold" style={{ color: "#2c3e50" }}>
              Movments+
            </h4>
            <Nav className="flex-column custom-sidebar d-flex">
              {menuItems.map((item) => (
                <Nav.Link
                  key={item.id}
                  onClick={() => handleTabClick(item.id)}
                  className={`sidebar-item d-flex align-items-center ${
                    activeTab === item.id ? "active" : ""
                  }`}
                >
                  <span className="icon-wrap">{item.icon}</span>
                  <span className="label-text">{item.label}</span>
                </Nav.Link>
              ))}
            </Nav>
          </div>
        </div>

        <div className="col-lg-10 col-md-9 col-12">
          <div style={{ minHeight: "500px" }}>{renderContent()}</div>
        </div>
      </div>
    </div>
  );
};

export default MovmentsPlus;
