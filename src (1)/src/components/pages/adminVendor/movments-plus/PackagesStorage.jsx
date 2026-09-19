import React, { useState, useEffect, useRef } from "react";
import axiosInstance from "../../../../services/api/axiosInstance";
import { loadRazorpayScript } from "../../../../services/api/cabApi";
import Loader from "../../../ui/Loader";
import MomentsQuotaBanner from "./MomentsQuotaBanner";
import "./packages.css";
import { CiStar } from "react-icons/ci";
import { FiInfo } from "react-icons/fi";
import { IoCheckmark } from "react-icons/io5";
import Swal from "sweetalert2";

// Same wording as the admin's own help text for these fields (MomentsPlanForm.jsx),
// so a vendor reading "what is Storage" and an admin editing a plan's storage limit
// are told the same thing.
const ALLOWANCE_INFO = {
  Storage: "Total size of all photos and videos you upload.",
  Events: "Separate wedding galleries you can create.",
  "Access codes":
    "Share links you generate so a couple or their guests can view a gallery.",
  "Media files": "Number of photos and videos you can upload, regardless of size.",
};

const PackagesStorage = () => {
  const [availablePackages, setAvailablePackages] = useState([]);
  const [currentPackage, setCurrentPackage] = useState(null);
  const [quota, setQuota] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  // "<packageId>:<label>" of the one open tooltip, or null. A ref rather than only
  // state because the outside-click listener below needs the current value without
  // being re-subscribed on every open/close.
  const [openInfoKey, setOpenInfoKey] = useState(null);
  const openInfoKeyRef = useRef(openInfoKey);
  openInfoKeyRef.current = openInfoKey;

  // Tap or click anywhere else closes an open tooltip — necessary on touch devices,
  // which have no hover to fall back on.
  useEffect(() => {
    const closeOnOutsideClick = () => {
      if (openInfoKeyRef.current) setOpenInfoKey(null);
    };
    document.addEventListener("click", closeOnOutsideClick);
    return () => document.removeEventListener("click", closeOnOutsideClick);
  }, []);

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

        // Allowed to fail on its own: the plan cards are the point of this page and
        // must still render if the quota lookup does not answer.
        const quotaRes = await axiosInstance
          .get("/vendor/me/moments-quota")
          .catch(() => null);
        if (quotaRes?.data?.success) setQuota(quotaRes.data);

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

    const price = Number(pkg.price) || 0;

    // A free package has nothing to charge for, so it keeps the old request route
    // rather than opening an empty checkout.
    if (price <= 0) {
      Swal.fire({
        title: `Switch to ${pkg.name}?`,
        text: "This package is free.",
        icon: "question",
        showCancelButton: true,
        confirmButtonColor: "#E91E63",
        cancelButtonColor: "#6c757d",
        confirmButtonText: "Yes, switch",
        cancelButtonText: "No",
      }).then((result) => {
        if (result.isConfirmed) submitFreePackageRequest(pkg);
      });
      return;
    }

    Swal.fire({
      title: `Upgrade to ${pkg.name}?`,
      html: `You will be charged <b>&#8377;${price.toLocaleString("en-IN")}</b> for ${
        pkg.duration_days || 30
      } days.<br/>Your package activates as soon as the payment succeeds.`,
      icon: "question",
      showCancelButton: true,
      confirmButtonColor: "#E91E63",
      cancelButtonColor: "#6c757d",
      confirmButtonText: "Proceed to Pay",
      cancelButtonText: "Cancel",
    }).then((result) => {
      if (result.isConfirmed) startPackagePayment(pkg);
    });
  };

  /** Free plans keep the old request route; there is nothing to charge. */
  const submitFreePackageRequest = async (pkg) => {
    try {
      Swal.fire({
        title: "Processing...",
        allowOutsideClick: false,
        didOpen: () => Swal.showLoading(),
      });

      const res = await axiosInstance.post("/vendor/request-package-upgrade", {
        package_id: pkg.id,
        message: `Requesting ${pkg.name} plan.`,
      });

      Swal.fire({
        title: "Request sent",
        text: res.data?.message || "Your request has been submitted.",
        icon: "success",
        confirmButtonColor: "#E91E63",
      });
    } catch (err) {
      Swal.fire({
        title: "Error!",
        text: err.response?.data?.message || "Could not submit the request.",
        icon: "error",
        confirmButtonColor: "#E91E63",
      });
    }
  };

  /**
   * Razorpay checkout. The server activates the package on a verified payment, so
   * nothing goes to the admin panel for approval.
   */
  const startPackagePayment = async (pkg) => {
    try {
      Swal.fire({
        title: "Starting payment...",
        allowOutsideClick: false,
        didOpen: () => Swal.showLoading(),
      });

      const scriptReady = await loadRazorpayScript();
      if (!scriptReady) {
        throw new Error("Could not load the payment window. Check your connection.");
      }

      const { data } = await axiosInstance.post("/vendor/package/order", {
        package_id: pkg.id,
      });

      if (!data?.success || !data?.order?.id) {
        throw new Error(data?.message || "Could not start the payment.");
      }

      Swal.close();

      const checkout = new window.Razorpay({
        key: data.razorpayKeyId,
        order_id: data.order.id,
        amount: data.order.amount,
        currency: data.order.currency,
        name: "HappyWedz",
        description: `${pkg.name} package`,
        prefill: data.prefill || {},
        theme: { color: "#E91E63" },
        handler: async (response) => {
          try {
            Swal.fire({
              title: "Confirming payment...",
              allowOutsideClick: false,
              didOpen: () => Swal.showLoading(),
            });

            const verify = await axiosInstance.post("/vendor/package/verify", {
              razorpay_order_id: response.razorpay_order_id,
              razorpay_payment_id: response.razorpay_payment_id,
              razorpay_signature: response.razorpay_signature,
            });

            if (!verify.data?.success) {
              throw new Error(verify.data?.message || "Payment could not be confirmed.");
            }

            await Swal.fire({
              title: "Payment successful",
              text: verify.data.message || `Your ${pkg.name} package is now active.`,
              icon: "success",
              confirmButtonColor: "#E91E63",
            });

            // Quotas and storage limits all read the new package, so reload rather than
            // patch the local state piecemeal.
            window.location.reload();
          } catch (err) {
            // The money is taken and the webhook will still activate it, so this must
            // not read like a failed payment.
            Swal.fire({
              title: "Payment received, activating",
              text:
                err.response?.data?.message ||
                "We could not confirm it in the browser, but the payment went through. Your package will activate shortly — contact support if it does not.",
              icon: "warning",
              confirmButtonColor: "#E91E63",
            });
          }
        },
        modal: {
          ondismiss: () => {
            Swal.fire({
              title: "Payment cancelled",
              text: "You have not been charged.",
              icon: "info",
              confirmButtonColor: "#E91E63",
            });
          },
        },
      });

      checkout.on("payment.failed", (response) => {
        Swal.fire({
          title: "Payment failed",
          text: response?.error?.description || "The payment did not go through.",
          icon: "error",
          confirmButtonColor: "#E91E63",
        });
      });

      checkout.open();
    } catch (err) {
      Swal.fire({
        title: "Error!",
        text:
          err.response?.data?.message || err.message || "Could not start the payment.",
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

      <MomentsQuotaBanner quota={quota} />

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
                  {Number(pkg.price) === 0 ? "Starter plan" : "Paid plan"}
                </p>
              </div>

              <div className="package-pricing">
                <div className="package-price inter">
                  <span className="currency">₹</span>
                  {Number(pkg.price).toLocaleString("en-IN")}
                </div>
                <p className="package-billing inter">
                  {Number(pkg.price) === 0
                    ? "Free forever"
                    : pkg.duration_days
                      ? `Every ${pkg.duration_days} days`
                      : "No expiry"}
                </p>
              </div>

              <ul className="package-allowances inter">
                {[
                  ["Storage", `${pkg.storage_limit_gb} GB`],
                  ["Events", pkg.max_events ?? "Unlimited"],
                  ["Access codes", pkg.max_access_codes ?? "Unlimited"],
                  ["Media files", pkg.max_media_files ?? "Unlimited"],
                ].map(([label, value]) => {
                  const infoKey = `${pkg.id}:${label}`;
                  const isOpen = openInfoKey === infoKey;

                  return (
                    <li key={label} className="allowance-row">
                      <span className="allowance-label">
                        {label}
                        <span className={`allowance-info ${isOpen ? "is-open" : ""}`}>
                          <button
                            type="button"
                            className="allowance-info-btn"
                            aria-label={`What is ${label}?`}
                            aria-expanded={isOpen}
                            onClick={(e) => {
                              // Stops this same click from reaching the card's own
                              // onClick (which would open checkout) and from
                              // reaching the outside-click listener above (which
                              // would immediately close what this just opened).
                              e.stopPropagation();
                              setOpenInfoKey(isOpen ? null : infoKey);
                            }}
                          >
                            <FiInfo size={13} />
                          </button>
                          <span className="allowance-tooltip inter" role="tooltip">
                            {ALLOWANCE_INFO[label]}
                          </span>
                        </span>
                      </span>
                      <span className="allowance-value">{value}</span>
                    </li>
                  );
                })}
              </ul>

              {features.length > 0 && (
                <ul className="package-features-list inter">
                  {features.map((feature, idx) => (
                    <li key={idx} className="feature-item">
                      <span className="feature-tick">
                        <IoCheckmark />
                      </span>
                      <span>{feature}</span>
                    </li>
                  ))}
                </ul>
              )}

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
