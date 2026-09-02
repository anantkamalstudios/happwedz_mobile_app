import React, { useState } from "react";
import { useSelector, useDispatch } from "react-redux";
import { vendorsApi } from "../../../../services/api/vendorAuthApi";
import { setVendor } from "../../../../redux/vendorAuthSlice";
import {
  FaFacebookF,
  FaInstagram,
  FaXTwitter,
  FaPinterestP,
} from "react-icons/fa6";
import "bootstrap/dist/css/bootstrap.min.css";

export default function SocialDetails({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
}) {
  const { vendor } = useSelector((state) => state.vendorAuth || {});
  const dispatch = useDispatch();
  const [loading, setLoading] = useState(false);

  const handleChange = (name, value) => {
    setFormData((prev) => ({
      ...prev,
      attributes: { ...(prev?.attributes || {}), [name]: value },
    }));
  };

  const getValue = (key) => {
    // Prefer formData (user edits), then vendor (saved data), then empty
    return formData?.attributes?.[key] || vendor?.[key] || "";
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      // 1. Update Vendor Auth (Redux + DB) to keep business details in sync
      // Construct full payload similar to BusinessDetails to ensure no data loss
      const payload = {
        businessName: vendor?.businessName || "",
        email: vendor?.email || "",
        phone: vendor?.phone || "",
        city: vendor?.city || "",
        state: vendor?.state || null,
        zip: vendor?.zip || null,
        firstName: vendor?.firstName || null,
        lastName: vendor?.lastName || null,
        vendor_type_id: vendor?.vendor_type_id
          ? Number(vendor.vendor_type_id)
          : null,
        years_in_business: vendor?.years_in_business
          ? Number(vendor.years_in_business)
          : null,
        // Social links from current form state (via getValue)
        facebook_link: getValue("facebook_link"),
        instagram_link: getValue("instagram_link"),
        twitter_link: getValue("twitter_link"),
        pinterest_link: getValue("pinterest_link"),
        website: getValue("website"),
      };

      if (vendor?.id) {
        try {
          await vendorsApi.updateVendor(vendor.id, payload);
          // Fetch fresh data to ensure Redux has the latest state without extra messages
          const freshVendor = await vendorsApi.getVendorById(vendor.id);
          if (freshVendor) {
            dispatch(setVendor(freshVendor));
          }
        } catch (vendorErr) {
          console.error("Failed to update vendor auth details:", vendorErr);
        }
      }

      // 2. Update Vendor Service (Storefront) via parent handler
      // if (onSave) await onSave();
      if (onShowSuccess) onShowSuccess();
    } catch (err) {
      console.error("Error saving social links:", err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container mt-4">
      <h4 className="mb-3">Add Your Professional Links</h4>
      <form className="row g-3" onSubmit={handleSubmit}>
        {/* Facebook */}
        <div className="col-md-6">
          <label className="form-label fs-16">Facebook</label>
          <div className="input-group">
            <span className="input-group-text bg-primary text-white">
              <FaFacebookF />
            </span>
            <input
              type="url"
              className="form-control fs-14"
              placeholder="https://facebook.com/yourpage"
              value={getValue("facebook_link")}
              onChange={(e) => handleChange("facebook_link", e.target.value)}
            />
          </div>
        </div>

        {/* Instagram */}
        <div className="col-md-6">
          <label className="form-label fs-16">Instagram</label>
          <div className="input-group">
            <span className="input-group-text bg-danger text-white">
              <FaInstagram />
            </span>
            <input
              type="url"
              className="form-control fs-14"
              placeholder="https://instagram.com/yourprofile"
              value={getValue("instagram_link")}
              onChange={(e) => handleChange("instagram_link", e.target.value)}
            />
          </div>
        </div>

        <div className="col-md-6">
          <label className="form-label fs-16">Website</label>
          <div className="input-group">
            <span className="input-group-text bg-primary text-white">
              <i className="fa-solid fa-globe"></i>
            </span>
            <input
              type="url"
              className="form-control fs-14"
              placeholder="https://yourwebsite.com"
              value={getValue("website")}
              onChange={(e) => handleChange("website", e.target.value)}
            />
          </div>
        </div>

        {/* X (Twitter) */}
        <div className="col-md-6">
          <label className="form-label fs-16">X (Twitter)</label>
          <div className="input-group">
            <span className="input-group-text bg-dark text-white">
              <FaXTwitter />
            </span>
            <input
              type="url"
              className="form-control fs-14"
              placeholder="https://x.com/yourhandle"
              value={getValue("twitter_link")}
              onChange={(e) => handleChange("twitter_link", e.target.value)}
            />
          </div>
        </div>

        {/* Pinterest */}
        <div className="col-md-6">
          <label className="form-label fs-16">Pinterest</label>
          <div className="input-group">
            <span className="input-group-text bg-danger text-white">
              <FaPinterestP />
            </span>
            <input
              type="url"
              className="form-control fs-14"
              placeholder="https://pinterest.com/yourprofile"
              value={getValue("pinterest_link")}
              onChange={(e) => handleChange("pinterest_link", e.target.value)}
            />
          </div>
        </div>

        {/* Save button */}
        <div className="col-12">
          <button
            type="submit"
            className="btn fs-14"
            disabled={loading}
            style={{
              backgroundColor: "#e83e8c",
              color: "white",
              border: "none",
            }}
          >
            {loading ? "Saving..." : "Save Links"}
          </button>
        </div>
      </form>
    </div>
  );
}
