import React, { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import { Modal, Toast } from "react-bootstrap";
import axios from "axios";
import SummernoteEditor from "../../../ui/SummernoteEditor";

const normalizeUiStatus = (value) => {
  const normalized = String(value || "").trim().toLowerCase();
  if (normalized === "publish" || normalized === "published") return "publish";
  if (
    normalized === "hide" ||
    normalized === "draft" ||
    normalized === "archived"
  )
    return "hide";
  return "hide";
};

const VendorBasicInfo = ({ formData, setFormData, onSave, onSaveSuccess }) => {
  const vendorAuth = useSelector((state) => state.vendorAuth);
  const { vendor } = vendorAuth || {};

  const [vendorTypeName, setVendorTypeName] = useState("Loading...");
  const [subCategories, setSubCategories] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [requestCategory, setRequestCategory] = useState("");
  const [requestMsg, setRequestMsg] = useState("");
  const [showToast, setShowToast] = useState(false);

  // Prefill formData.attributes when vendor loads
  useEffect(() => {
    if (vendor) {
      setFormData((prev) => ({
        ...prev,
        vendor_subcategory_id:
          prev.vendor_subcategory_id || vendor.vendor_subcategory_id || "",
        vendor_type_id: vendor.vendor_type_id,
        attributes: {
          ...prev.attributes,
          businessName:
            prev.attributes?.businessName || vendor.businessName || "",
          // Keep a canonical `Name` in attributes for API compatibility
          Name:
            prev.attributes?.Name ||
            prev.attributes?.businessName ||
            vendor.businessName ||
            "",
          // Sync to lowercase `name` key for API storage
          name:
            prev.attributes?.name ||
            prev.attributes?.businessName ||
            vendor.businessName ||
            "",
          // Prefill slug from previous attributes or vendor if available
          slug: prev.attributes?.slug || vendor.slug || "",
          // tagline: prev.attributes?.tagline || "",
          // subtitle: prev.attributes?.subtitle || "",
          about_us: prev.attributes?.about_us || "",
        },
        status: normalizeUiStatus(prev.status || vendor.status),
      }));
    }
  }, [vendor, setFormData]);

  // Fetch Vendor Type Name + Subcategories
  useEffect(() => {
    const fetchVendorType = async () => {
      if (vendor?.vendor_type_id) {
        try {
          const response = await axios.get(
            `https://happywedz.com/api/vendor-types/${vendor.vendor_type_id}`
          );
          const vendorTypeData = response.data;
          setVendorTypeName(vendorTypeData?.name || "Unknown Type");
          setSubCategories(vendorTypeData?.subcategories || []);
        } catch (err) {
          console.error(
            "Failed to fetch vendor type + subcategories:",
            err.response?.data || err
          );
          setVendorTypeName("Could not load type");
          setSubCategories([]);
        }
      }
    };
    fetchVendorType();
  }, [vendor?.vendor_type_id, setFormData]);

  // Update attributes in formData
  const handleAttributeChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => {
      let updatedAttributes = { ...prev.attributes, [name]: value };
      // Auto-generate slug from name (kebab-case, no user id)
      if (name === "businessName") {
        const slugBase = value
          .toLowerCase()
          .trim()
          .replace(/\s+/g, "-")
          .replace(/[^a-z0-9-]/g, "");
        // Keep legacy `Name` attribute in sync with `businessName` for API
        updatedAttributes.Name = value;
        // Also sync to lowercase `name` key for API
        updatedAttributes.name = value;
        updatedAttributes.slug = slugBase;
      }
      return { ...prev, attributes: updatedAttributes };
    });
  };

  // Update root-level fields (like status)
  const handleRootChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  return (
    <div className="my-5">
      <div className="p-3 border rounded bg-white">
        <h4 className="mb-3 fw-bold">Basic Information</h4>
        <div className="row">
          {/* Vendor Name */}
          <div className="col-md-6 mb-3">
            <label className="form-label fw-semibold fs-16">
              Vendor Business Name
            </label>
            <input
              type="text"
              name="businessName"
              className="form-control fs-14"
              value={formData.attributes?.businessName || ""}
              onChange={handleAttributeChange}
              placeholder="Enter vendor name"
            />
          </div>

          {/* Slug (auto-generated, disabled) */}

          {/* Tagline */}
          {/* <div className="col-md-6 mb-3">
            <label className="form-label fw-semibold fs-16">Tagline</label>
            <input
              type="text"
              name="tagline"
              className="form-control fs-14"
              value={formData.attributes?.tagline || ""}
              onChange={handleAttributeChange}
              placeholder="Short catchy tagline"
            />
          </div>

       
          <div className="col-md-6 mb-3">
            <label className="form-label fw-semibold fs-16">Subtitle</label>
            <input
              type="text"
              name="subtitle"
              className="form-control fs-14"
              value={formData.attributes?.subtitle || ""}
              onChange={handleAttributeChange}
              placeholder="Brief subtitle"
            />
          </div> */}

          {/* Description */}
          <div className="col-12 mb-3">
            <label className="form-label fw-semibold fs-16">About US</label>
            <SummernoteEditor
              value={formData.attributes?.about_us || ""}
              onChange={(val) =>
                handleAttributeChange({
                  target: { name: "about_us", value: val },
                })
              }
            />
          </div>

          {/* Vendor Type */}
          <div className="col-md-6 mb-3">
            <label className="form-label fw-semibold fs-16">Vendor Type</label>
            <input
              type="text"
              className="form-control fs-14"
              value={vendorTypeName}
              disabled
            />

            {/* Subcategories */}
            <div className="mt-3">
              <label className="form-label fw-semibold fs-16">
                Primary Subcategory *
              </label>
              <select
                name="vendor_subcategory_id"
                className="form-select fs-14"
                value={formData.vendor_subcategory_id || ""}
                onChange={handleRootChange}
                required
              >
                <option value="" disabled>
                  -- Select a subcategory --
                </option>
                {subCategories.map((sub) => (
                  <option key={sub.id} value={sub.id}>
                    {sub.name}
                  </option>
                ))}
              </select>
              {formData.vendor_subcategory_id && (
                <div className="mt-2 p-2 bg-light border rounded small fs-14">
                  <strong>Selected: </strong>
                  {subCategories.find(
                    (s) => s.id == formData.vendor_subcategory_id
                  )?.name || "..."}
                </div>
              )}
            </div>
          </div>

          {/* Ad Status */}
          <div className="col-md-6 mb-3">
            <label className="form-label fw-semibold fs-16">Ad Status</label>
            <select
              name="status"
              className="form-select"
              value={normalizeUiStatus(formData.status)}
              onChange={handleRootChange}
            >
              <option value="publish">Published</option>
              <option value="hide">Hidden</option>
            </select>
          </div>
        </div>
        <button type="button" className="btn btn-primary mt-2" onClick={async () => {
          if (onSave) await onSave();
          if (onSaveSuccess) await onSaveSuccess();
        }}>
          Save Basic Info
        </button>
      </div>
    </div>
  );
};

export default VendorBasicInfo;
