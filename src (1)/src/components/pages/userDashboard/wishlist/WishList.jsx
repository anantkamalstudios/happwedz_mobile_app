import React, { useState, useEffect, useMemo } from "react";
import { useSelector } from "react-redux";
import { Link, useNavigate } from "react-router-dom";
import { BsPlusLg } from "react-icons/bs";
import { IoClose } from "react-icons/io5";
import { PiChatCircleDotsLight } from "react-icons/pi";
import { FaSearch } from "react-icons/fa";
import PricingModal from "../../../layouts/PricingModal";
import vendorServicesApi from "../../../../services/api/vendorServicesApi";
import axiosInstance from "../../../../services/api/axiosInstance";

const Wishlist = () => {
  useSelector((state) => state.auth.token); // keep for detecting auth state
  const [wishlist, setWishlist] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [showModal, setShowModal] = useState(false);
  const [selectedVendorId, setSelectedVendorId] = useState(null);
  const navigate = useNavigate();

  const handleShowModal = (vendorId) => {
    setSelectedVendorId(vendorId);
    setShowModal(true);
  };

  const IMAGE_BASE_URL = "https://happywedzbackend.happywedz.com";
  const getImageUrl = (path) => {
    if (!path) return "/images/imageNotFound.jpg";
    if (/^https?:\/\//i.test(path)) return path;
    return `${IMAGE_BASE_URL}${path.startsWith("/") ? path : "/" + path}`;
  };

  useEffect(() => {
    const fetchWishlist = async () => {
      setLoading(true);
      try {
        const res = await axiosInstance.get(`https://happywedz.com/api/wishlist`);
        const data = res.data;

        if (data.success && data.data.length > 0) {
          const enrichedData = await Promise.all(
            data.data
              .filter(
                (item) =>
                  item.vendor_services_id &&
                  item.vendor_services_id !== "undefined" &&
                  item.vendor_services_id !== undefined
              )
              .map(async (item) => {
                try {
                  const serviceId = parseInt(item.vendor_services_id);
                  if (isNaN(serviceId) || serviceId <= 0) {
                    throw new Error(
                      `Invalid vendor_services_id: ${item.vendor_services_id}`
                    );
                  }

                  const serviceData =
                    await vendorServicesApi.getVendorServiceById(serviceId);

                  return {
                    wishlist_id: item.wishlist_id,
                    vendor_services_id: item.vendor_services_id,
                    vendor_id:
                      serviceData?.vendor_id || serviceData?.vendor?.id || null,
                    businessName:
                      serviceData?.vendor?.businessName ||
                      serviceData?.attributes?.name ||
                      "Unknown Vendor",
                    city:
                      serviceData?.attributes?.location?.city ||
                      serviceData?.attributes?.city ||
                      "Unknown City",
                    image: getImageUrl(
                      serviceData?.media?.[0] ||
                      serviceData?.attributes?.cover_image ||
                      serviceData?.cover_image ||
                      serviceData?.image ||
                      null
                    ),
                  };
                } catch (err) {
                  console.error("Error fetching service:", err);
                  return {
                    wishlist_id: item.wishlist_id,
                    vendor_services_id: item.vendor_services_id,
                    businessName: item.businessName || "Unknown",
                    city: "Unknown",
                    image: "/images/imageNotFound.jpg",
                  };
                }
              })
          );

          // Filter out any null/undefined values in case of errors
          const validData = enrichedData.filter(
            (item) => item !== null && item !== undefined
          );
          setWishlist(validData);
        } else {
          setWishlist([]);
        }
      } catch (err) {
        console.error("Error fetching wishlist:", err);
      }
      setLoading(false);
    };

    fetchWishlist();
  }, []);

  const toggleWishlistItem = async (vendorId) => {
    const originalWishlist = [...wishlist];
    setWishlist((prevWishlist) =>
      prevWishlist.filter((item) => item.vendor_services_id !== vendorId)
    );

    try {
      const response = await axiosInstance.post(
        "https://happywedz.com/api/wishlist/toggle",
        { vendor_services_id: vendorId }
      );

      const result = response.data;
      if (!result.success) {
        setWishlist(originalWishlist);
        console.error("Failed to remove item from wishlist:", result.message);
      }
    } catch (err) {
      setWishlist(originalWishlist);
      console.error("Error toggling wishlist item:", err);
    }
  };

  const filteredWishlist = useMemo(() => {
    if (!searchTerm) {
      return wishlist;
    }
    return wishlist.filter(
      (vendor) =>
        vendor.businessName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        vendor.city.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [wishlist, searchTerm]);

  if (loading) {
    return (
      <div className="text-center mt-5">
        <h5>Loading wishlist...</h5>
      </div>
    );
  }

  if (wishlist.length === 0 && !loading) {
    return (
      <div className="container py-5">
        <div className="text-center py-5 bg-light rounded-4 shadow-sm">
          <i
            className="bi bi-heart text-muted"
            style={{ fontSize: "4rem" }}
          ></i>
          <h4 className="fw-bold text-dark my-3">Your Wishlist is Empty</h4>
          <p className="text-muted mb-4">
            Browse vendors and add your favorites to your wishlist.
          </p>
          <Link to="/vendors" className="btn btn-primary rounded-3 px-4">
            <BsPlusLg className="me-2" /> Browse Vendors
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="container py-4">
      <div className="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
        <div>
          <h3 className="fw-bold text-dark mb-1">My Wishlist</h3>
          <p className="text-muted mb-0 fs-14">
            Manage your selected wedding services
          </p>
        </div>
        <div className="d-flex flex-column flex-sm-row gap-2 align-items-stretch align-items-sm-center w-100 w-md-auto">
          <div className="position-relative flex-grow-1">
            <input
              type="text"
              className="form-control rounded-3 fs-14 w-100"
              placeholder="Search..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              style={{ minWidth: 0 }}
            />
          </div>
          <Link
            to="/vendors"
            className="btn btn-primary rounded-3 px-3 fs-14 w-50 w-sm-auto text-center"
          >
            <BsPlusLg className="me-2" size={16} /> Add Vendor
          </Link>
        </div>
      </div>

      <div className="row g-4">
        {filteredWishlist.map((vendor) => (
          <div key={vendor.vendor_services_id} className="col-sm-6 col-lg-4">
            <div className="card h-100 border-0 p-2">
              <div className="position-relative">
                <div className="ratio ratio-16x9 rounded-4 overflow-hidden">
                  <img
                    src={getImageUrl(vendor.image)}
                    alt={vendor.businessName}
                    className="w-100 h-100 object-fit-cover rounded-4"
                    onError={(e) => {
                      e.currentTarget.src = "/images/imageNotFound.jpg";
                    }}
                  />
                </div>
                <button
                  className="btn btn-light btn-sm position-absolute top-0 end-0 m-2 rounded-circle shadow"
                  onClick={() => toggleWishlistItem(vendor.vendor_services_id)}
                  aria-label="Remove from wishlist"
                  title="Remove"
                >
                  <IoClose size={18} />
                </button>
              </div>
              <div className="card-body d-flex flex-column">
                <p className="card-title fw-semibold mb-1 fs-16 ms-1">
                  {vendor.businessName}
                </p>
                <div className="text-muted small mb-3 fs-14">
                  <i className="bi bi-geo-alt me-1"></i>
                  {vendor.city}
                </div>
                <div className="mt-auto d-flex gap-2">
                  <button
                    className="btn btn-outline-primary w-50 rounded-3 fs-14"
                    onClick={() =>
                      navigate(`/details/info/${vendor.vendor_services_id}`)
                    }
                  >
                    View Details
                  </button>
                  <button
                    className="btn btn-primary w-50 rounded-3 fs-14"
                    onClick={() => handleShowModal(vendor.vendor_services_id)}
                  >
                    <PiChatCircleDotsLight className="me-2" size={18} />
                    Contact
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {wishlist.length > 0 && filteredWishlist.length === 0 && (
        <div className="text-center py-5 bg-light rounded-4 mt-4">
          <FaSearch className="text-muted mb-3" size={40} />
          <h5 className="fw-bold text-dark">No Vendors Found</h5>
          <p className="text-muted">No items match "{searchTerm}".</p>
        </div>
      )}

      <PricingModal
        show={showModal}
        handleClose={() => setShowModal(false)}
        vendorId={selectedVendorId}
      />
    </div>
  );
};

export default Wishlist;
