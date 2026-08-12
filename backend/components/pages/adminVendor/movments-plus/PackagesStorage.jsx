import React, { useState, useEffect } from "react";
import axiosInstance from "../../../../services/api/axiosInstance";
import Loader from "../../../ui/Loader";
import "./packages.css";
import { CiStar } from "react-icons/ci";
import { IoCheckmark } from "react-icons/io5";
import Swal from "sweetalert2";

const PackagesStorage = () => {
  const [availablePackages, setAvailablePackages] = useState([]);
  const [currentPackage, setCurrentPackage] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        setError(null);

        const dashboardRes = await axiosInstance.get(
          "/vendor/dashboard/analytics",
        );
        if (dashboardRes.data.success) {
          setCurrentPackage(dashboardRes.data.package);
        }

        const packagesRes = await axiosInstance.get("/admin/package");
        const list = Array.isArray(packagesRes.data?.packages)
          ? packagesRes.data.packages
          : [];
        setAvailablePackages(list);
      } catch (err) {
        setError(err.response?.data?.message || "Failed to load data");
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  const handlePackageSelect = (pkg) => {
    if (
      currentPackage?.name &&
      pkg.name &&
      pkg.name.toLowerCase() === currentPackage.name.toLowerCase()
    ) {
      return;
    }

    Swal.fire({
      title: "Request Upgrade?",
      text: `Do you want to request an upgrade to the ${pkg.name} plan?`,
      icon: "question",
      showCancelButton: true,
      confirmButtonColor: "#E91E63", // Pink color from theme
      cancelButtonColor: "#6c757d",
      confirmButtonText: "Yes, Request Upgrade",
      cancelButtonText: "No",
    }).then((result) => {
      if (result.isConfirmed) {
        submitUpgradeRequest(pkg);
      }
    });
  };

  const submitUpgradeRequest = async (pkg) => {
    try {
      Swal.fire({
        title: "Processing...",
        text: "Sending your request",
        allowOutsideClick: false,
        didOpen: () => {
          Swal.showLoading();
        },
      });

      const res = await axiosInstance.post("/vendor/request-package-upgrade", {
        package_id: pkg.id,
        message: `Requesting upgrade to ${pkg.name} plan.`,
      });

      Swal.fire({
        title: "Success!",
        text:
          res.data?.message || "Your package upgrade request has been sent.",
        icon: "success",
        confirmButtonColor: "#E91E63",
      });
    } catch (err) {
      Swal.fire({
        title: "Error!",
        text:
          err.response?.data?.message || "Failed to submit upgrade request.",
        icon: "error",
        confirmButtonColor: "#E91E63",
      });
    }
  };

  if (loading) {
    return (
      <div
        className="w-100 d-flex justify-content-center align-items-center"
        style={{ minHeight: "400px" }}
      >
        <Loader />
      </div>
    );
  }

  return (
    <div className="packages-storage-container">
      <div className="packages-header mb-5">
        <h1 className="packages-main-title inter">Packages & Storage</h1>
        <p className="packages-subtitle inter">
          Choose the perfect plan for your photography business
        </p>
      </div>

      {error && (
        <div className="custom-alert custom-alert-danger inter mb-4">
          {error}
        </div>
      )}

      <div className="packages-grid mb-5">
        {availablePackages.map((pkg, index) => {
          const isCurrent =
            currentPackage?.name &&
            pkg.name &&
            pkg.name.toLowerCase() === currentPackage.name.toLowerCase();
          const isMostPopular = pkg.name.toLowerCase() === "standard";
          const features = pkg.message
            ? pkg.message.split("\n").filter((f) => f.trim())
            : [];

          return (
            <div
              key={pkg.id}
              className={`package-card-wrapper ${
                isCurrent ? "current-card" : ""
              } ${isMostPopular ? "popular-card" : ""}`}
              onClick={() => handlePackageSelect(pkg)}
              style={{ cursor: isCurrent ? "default" : "pointer" }}
            >
              {isMostPopular && !isCurrent && (
                <div className="popular-badge inter">
                  <span className="star-icon">
                    <CiStar />
                  </span>
                  Most Popular
                </div>
              )}
              {isCurrent && (
                <div className="current-badge inter">✓ Current Plan</div>
              )}

              <div className="package-card-header">
                <h3 className="package-name inter">{pkg.name}</h3>
                <p className="package-storage-info inter">
                  {pkg.storage_limit_gb} GB Storage
                </p>
              </div>

              <div className="package-pricing">
                <div className="package-price inter">
                  <span className="currency">₹</span>
                  {Number(pkg.price).toLocaleString("en-IN")}
                </div>
                <p className="package-billing inter">
                  Per month, {pkg.duration_days} days validity
                </p>
              </div>

              <ul className="package-features-list inter">
                {features.map((feature, idx) => (
                  <li key={idx} className="feature-item">
                    <span className="fs-16">
                      <IoCheckmark />
                    </span>
                    <span className="fs-16">{feature}</span>
                  </li>
                ))}
              </ul>

              <button
                type="button"
                className={`package-select-btn inter ${
                  isCurrent ? "btn-disabled" : "btn-primary-pink"
                }`}
                disabled={isCurrent}
                onClick={(e) => {
                  e.stopPropagation();
                  handlePackageSelect(pkg);
                }}
              >
                {isCurrent ? "Current Plan" : `Select ${pkg.name}`}
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default PackagesStorage;
