import React, { useState } from "react";
import Navbar from "../../layouts/vendors/Navbar";
import HomeAdmin from "./HomeAdmin";
import Storefront from "./Storefront";
import { useParams } from "react-router-dom";
import VendorDashboard from "./VendorDashboard";
import StorefrontPage from "./StorefrontPage";
import ReviewsPage from "./ReviewsPage";
import EnquiryManagement from "./EnquiryManagement";
import Settings from "./Settings";
import ReviewsDashboard from "./subVendors/ReviewsDashboard";
import Reviews from "./subVendors/Reviews";
import VendorMessages from "./messages/VendorMessages";
import VendorLeadsPage from "./VendorLeadsPage";
import MovmentsPlus from "./movments-plus/MovmentsPlus";

const Main = () => {
  const { slug } = useParams();
  const [storefrontCompletion, setStorefrontCompletion] = useState(() => {
    const stored = localStorage.getItem("storefrontCompletion");
    return stored ? parseInt(stored, 10) : 0;
  });

  const renderContent = () => {
    switch (slug) {
      case "vendor-home":
        return <HomeAdmin />;
      case "vendor-store-front":
        return <Storefront setCompletion={setStorefrontCompletion} />;
      case "vendor-reviews":
        return <ReviewsPage />;
      case "vendor-setting":
        return <Settings />;
      case "vendor-messages":
        return <VendorMessages />;
      case "vendor-enquiries":
        return <EnquiryManagement />;
      case "total-leads":
        return <VendorLeadsPage />;
      case "movments-plus":
        return <MovmentsPlus />;
      default:
        return <HomeAdmin />;
    }
  };

  return (
    <div>
      <Navbar storefrontCompletion={storefrontCompletion} />
      {renderContent()}
    </div>
  );
};

export default Main;
