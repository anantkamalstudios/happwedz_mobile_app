import React, { useState } from "react";
import {
  FaBuilding,
  FaMapMarkerAlt,
  FaPhone,
  FaEnvelope,
  FaGlobe,
  FaWhatsapp,
  FaImage,
  FaVideo,
  FaFilePdf,
  FaStar,
  FaAward,
  FaRupeeSign,
  FaGift,
  FaUsers,
  FaCar,
  FaMusic,
  FaUtensils,
  FaPalette,
  FaClock,
  FaCheckCircle,
  FaTimes,
  FaPlus,
  FaTrash,
} from "react-icons/fa";

const VendorForm = () => {
  const [formData, setFormData] = useState({
    status: "draft",
    vendorType: "venue",
    name: "",
    slug: "",
    tagline: "",
    subtitle: "",
    description: "",
    faqs: [{ question: "", answer: "" }],
    contact: {
      contactName: "",
      phone: "",
      altPhone: "",
      email: "",
      website: "",
      whatsappNumber: "",
      inquiryEmail: "",
    },
    location: {
      addressLine1: "",
      addressLine2: "",
      city: "",
      state: "",
      country: "India",
      pincode: "",
      lat: "",
      lng: "",
      landmark: "",
      serviceAreas: [],
    },
    media: {
      coverImage: "",
      gallery: [],
      video: { type: "", url: "", thumbnail: "" },
      view360: { type: "", embedCode: "", panoImage: "", modelUrl: "" },
      brochurePdf: "",
    },
    rating: "",
    reviewsCount: "",
    awards: [{ year: "", title: "", org: "" }],
    badges: [],
    startingPrice: "",
    priceUnit: "",
    priceRange: { min: "", max: "" },
    currency: "INR",
    deals: [{ title: "", description: "", validTill: "" }],
    packages: [
      {
        id: "",
        name: "",
        price: "",
        priceUnit: "",
        includes: [""],
        addOns: [""],
        terms: "",
      },
    ],
    capacity: { min: "", max: "" },
    rooms: "",
    carParking: "",
    hallTypes: [],
    indoorOutdoor: "",
    alcoholPolicy: "",
    djPolicy: "",
    cateringPolicy: "",
    decoPolicy: "",
    timing: { open: "", close: "", lastEntry: "" },
    servicesOffered: [],
    features: [],
    cuisines: [],
    specialties: [],
    equipment: [],
    cancellationPolicy: "",
    refundPolicy: "",
    paymentTerms: { advancePercent: "", modes: [] },
    tnc: "",
    blackoutDates: [],
    availableSlots: [{ date: "", timeFrom: "", timeTo: "" }],
    primaryCTA: "enquire",
    ctaPhone: "",
    ctaUrl: "",
    autoReply: "",
    isFeatured: false,
    sortWeight: "",
    tags: [],
    ownerId: "",
    notes: "",
    isFeatureAvailable: "No",
    within24HrAvailable: "No",
  });

  const [activeSection, setActiveSection] = useState("basic");

  const sections = [
    { id: "basic", label: "Basic Information", icon: <FaBuilding /> },
    { id: "contact", label: "Contact Details", icon: <FaPhone /> },
    {
      id: "location",
      label: "Location & Service Areas",
      icon: <FaMapMarkerAlt />,
    },
    { id: "media", label: "Media & Gallery", icon: <FaImage /> },
    { id: "pricing", label: "Pricing & Packages", icon: <FaRupeeSign /> },
    {
      id: "facilities",
      label: "Facilities & Features",
      icon: <FaCheckCircle />,
    },
    { id: "policies", label: "Policies & Terms", icon: <FaFilePdf /> },
    { id: "availability", label: "Availability & Slots", icon: <FaClock /> },
    { id: "marketing", label: "Marketing & CTA", icon: <FaGift /> },
  ];

  const handleInputChange = (section, field, value) => {
    setFormData((prev) => ({
      ...prev,
      [section]: {
        ...prev[section],
        [field]: value,
      },
    }));
  };

  const handleNestedInputChange = (section, subSection, field, value) => {
    setFormData((prev) => ({
      ...prev,
      [section]: {
        ...prev[section],
        [subSection]: {
          ...prev[section][subSection],
          [field]: value,
        },
      },
    }));
  };

  const addArrayItem = (section, field, newItem) => {
    setFormData((prev) => ({
      ...prev,
      [section]: {
        ...prev[section],
        [field]: [...prev[section][field], newItem],
      },
    }));
  };

  const removeArrayItem = (section, field, index) => {
    setFormData((prev) => ({
      ...prev,
      [section]: {
        ...prev[section],
        [field]: prev[section][field].filter((_, i) => i !== index),
      },
    }));
  };

  const updateArrayItem = (section, field, index, updatedItem) => {
    setFormData((prev) => ({
      ...prev,
      [section]: {
        ...prev[section],
        [field]: prev[section][field].map((item, i) =>
          i === index ? updatedItem : item
        ),
      },
    }));
  };

  const renderBasicInfo = () => (
    <div className="row">
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Vendor Name *</label>
        <input
          type="text"
          className="form-control"
          value={formData.name}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, name: e.target.value }))
          }
          placeholder="Enter vendor name"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Slug</label>
        <input
          type="text"
          className="form-control"
          value={formData.slug}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, slug: e.target.value }))
          }
          placeholder="vendor-name-slug"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Tagline</label>
        <input
          type="text"
          className="form-control"
          value={formData.tagline}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, tagline: e.target.value }))
          }
          placeholder="Short catchy tagline"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Subtitle</label>
        <input
          type="text"
          className="form-control"
          value={formData.subtitle}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, subtitle: e.target.value }))
          }
          placeholder="Brief subtitle"
        />
      </div>
      <div className="col-12 mb-3">
        <label className="form-label fw-semibold">Description</label>
        <textarea
          className="form-control"
          rows="4"
          value={formData.description}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, description: e.target.value }))
          }
          placeholder="Detailed description of your business"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Vendor Type</label>
        <select
          className="form-select"
          value={formData.vendorType}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, vendorType: e.target.value }))
          }
        >
          <option value="venue">Venue</option>
          <option value="caterer">Caterer</option>
          <option value="photographer">Photographer</option>
          <option value="decorator">Decorator</option>
          <option value="dj">DJ</option>
          <option value="makeup">Makeup Artist</option>
          <option value="other">Other</option>
        </select>
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Status</label>
        <select
          className="form-select"
          value={formData.status}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, status: e.target.value }))
          }
        >
          <option value="draft">Draft</option>
          <option value="published">Published</option>
          <option value="archived">Archived</option>
        </select>
      </div>
    </div>
  );

  const renderContactDetails = () => (
    <div className="row">
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Contact Person *</label>
        <input
          type="text"
          className="form-control"
          value={formData.contact.contactName}
          onChange={(e) =>
            handleInputChange("contact", "contactName", e.target.value)
          }
          placeholder="Enter contact person name"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Primary Phone *</label>
        <input
          type="tel"
          className="form-control"
          value={formData.contact.phone}
          onChange={(e) =>
            handleInputChange("contact", "phone", e.target.value)
          }
          placeholder="Enter primary phone number"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Alternative Phone</label>
        <input
          type="tel"
          className="form-control"
          value={formData.contact.altPhone}
          onChange={(e) =>
            handleInputChange("contact", "altPhone", e.target.value)
          }
          placeholder="Enter alternative phone number"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">WhatsApp Number</label>
        <input
          type="tel"
          className="form-control"
          value={formData.contact.whatsappNumber}
          onChange={(e) =>
            handleInputChange("contact", "whatsappNumber", e.target.value)
          }
          placeholder="Enter WhatsApp number"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Email *</label>
        <input
          type="email"
          className="form-control"
          value={formData.contact.email}
          onChange={(e) =>
            handleInputChange("contact", "email", e.target.value)
          }
          placeholder="Enter email address"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Inquiry Email</label>
        <input
          type="email"
          className="form-control"
          value={formData.contact.inquiryEmail}
          onChange={(e) =>
            handleInputChange("contact", "inquiryEmail", e.target.value)
          }
          placeholder="Enter inquiry email"
        />
      </div>
      <div className="col-12 mb-3">
        <label className="form-label fw-semibold">Website</label>
        <input
          type="url"
          className="form-control"
          value={formData.contact.website}
          onChange={(e) =>
            handleInputChange("contact", "website", e.target.value)
          }
          placeholder="https://your-website.com"
        />
      </div>
    </div>
  );

  const renderLocationDetails = () => (
    <div className="row">
      <div className="col-12 mb-3">
        <label className="form-label fw-semibold">Address Line 1 *</label>
        <input
          type="text"
          className="form-control"
          value={formData.location.addressLine1}
          onChange={(e) =>
            handleInputChange("location", "addressLine1", e.target.value)
          }
          placeholder="Enter address line 1"
        />
      </div>
      <div className="col-12 mb-3">
        <label className="form-label fw-semibold">Address Line 2</label>
        <input
          type="text"
          className="form-control"
          value={formData.location.addressLine2}
          onChange={(e) =>
            handleInputChange("location", "addressLine2", e.target.value)
          }
          placeholder="Enter address line 2"
        />
      </div>
      <div className="col-md-4 mb-3">
        <label className="form-label fw-semibold">City *</label>
        <input
          type="text"
          className="form-control"
          value={formData.location.city}
          onChange={(e) =>
            handleInputChange("location", "city", e.target.value)
          }
          placeholder="Enter city"
        />
      </div>
      <div className="col-md-4 mb-3">
        <label className="form-label fw-semibold">State *</label>
        <input
          type="text"
          className="form-control"
          value={formData.location.state}
          onChange={(e) =>
            handleInputChange("location", "state", e.target.value)
          }
          placeholder="Enter state"
        />
      </div>
      <div className="col-md-4 mb-3">
        <label className="form-label fw-semibold">Pincode *</label>
        <input
          type="text"
          className="form-control"
          value={formData.location.pincode}
          onChange={(e) =>
            handleInputChange("location", "pincode", e.target.value)
          }
          placeholder="Enter pincode"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Landmark</label>
        <input
          type="text"
          className="form-control"
          value={formData.location.landmark}
          onChange={(e) =>
            handleInputChange("location", "landmark", e.target.value)
          }
          placeholder="Enter nearby landmark"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Country</label>
        <input
          type="text"
          className="form-control"
          value={formData.location.country}
          onChange={(e) =>
            handleInputChange("location", "country", e.target.value)
          }
          placeholder="Enter country"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Latitude</label>
        <input
          type="number"
          step="any"
          className="form-control"
          value={formData.location.lat}
          onChange={(e) => handleInputChange("location", "lat", e.target.value)}
          placeholder="Enter latitude"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Longitude</label>
        <input
          type="number"
          step="any"
          className="form-control"
          value={formData.location.lng}
          onChange={(e) => handleInputChange("location", "lng", e.target.value)}
          placeholder="Enter longitude"
        />
      </div>
    </div>
  );

  const renderMediaGallery = () => (
    <div className="row">
      <div className="col-12 mb-3">
        <label className="form-label fw-semibold">Cover Image URL</label>
        <input
          type="url"
          className="form-control"
          value={formData.media.coverImage}
          onChange={(e) =>
            handleInputChange("media", "coverImage", e.target.value)
          }
          placeholder="Enter cover image URL"
        />
      </div>
      <div className="col-12 mb-3">
        <label className="form-label fw-semibold">Video URL</label>
        <input
          type="url"
          className="form-control"
          value={formData.media.video.url}
          onChange={(e) =>
            handleNestedInputChange("media", "video", "url", e.target.value)
          }
          placeholder="Enter video URL"
        />
      </div>
      <div className="col-12 mb-3">
        <label className="form-label fw-semibold">Video Thumbnail URL</label>
        <input
          type="url"
          className="form-control"
          value={formData.media.video.thumbnail}
          onChange={(e) =>
            handleNestedInputChange(
              "media",
              "video",
              "thumbnail",
              e.target.value
            )
          }
          placeholder="Enter video thumbnail URL"
        />
      </div>
      <div className="col-12 mb-3">
        <label className="form-label fw-semibold">Brochure PDF URL</label>
        <input
          type="url"
          className="form-control"
          value={formData.media.brochurePdf}
          onChange={(e) =>
            handleInputChange("media", "brochurePdf", e.target.value)
          }
          placeholder="Enter brochure PDF URL"
        />
      </div>
    </div>
  );

  const renderPricingPackages = () => (
    <div className="row">
      <div className="col-md-4 mb-3">
        <label className="form-label fw-semibold">Starting Price</label>
        <input
          type="number"
          className="form-control"
          value={formData.startingPrice}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, startingPrice: e.target.value }))
          }
          placeholder="Enter starting price"
        />
      </div>
      <div className="col-md-4 mb-3">
        <label className="form-label fw-semibold">Price Unit</label>
        <select
          className="form-select"
          value={formData.priceUnit}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, priceUnit: e.target.value }))
          }
        >
          <option value="per_person">Per Person</option>
          <option value="per_event">Per Event</option>
          <option value="per_hour">Per Hour</option>
          <option value="per_day">Per Day</option>
          <option value="fixed">Fixed Price</option>
        </select>
      </div>
      <div className="col-md-4 mb-3">
        <label className="form-label fw-semibold">Currency</label>
        <select
          className="form-select"
          value={formData.currency}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, currency: e.target.value }))
          }
        >
          <option value="INR">INR</option>
          <option value="USD">USD</option>
          <option value="EUR">EUR</option>
        </select>
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Price Range Min</label>
        <input
          type="number"
          className="form-control"
          value={formData.priceRange.min}
          onChange={(e) =>
            handleNestedInputChange("priceRange", "min", e.target.value)
          }
          placeholder="Minimum price"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Price Range Max</label>
        <input
          type="number"
          className="form-control"
          value={formData.priceRange.max}
          onChange={(e) =>
            handleNestedInputChange("priceRange", "max", e.target.value)
          }
          placeholder="Maximum price"
        />
      </div>
    </div>
  );

  const renderFacilitiesFeatures = () => (
    <div className="row">
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Minimum Capacity</label>
        <input
          type="number"
          className="form-control"
          value={formData.capacity.min}
          onChange={(e) =>
            handleNestedInputChange("capacity", "min", e.target.value)
          }
          placeholder="Minimum capacity"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Maximum Capacity</label>
        <input
          type="number"
          className="form-control"
          value={formData.capacity.max}
          onChange={(e) =>
            handleNestedInputChange("capacity", "max", e.target.value)
          }
          placeholder="Maximum capacity"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Number of Rooms</label>
        <input
          type="number"
          className="form-control"
          value={formData.rooms}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, rooms: e.target.value }))
          }
          placeholder="Number of rooms"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Car Parking</label>
        <input
          type="text"
          className="form-control"
          value={formData.carParking}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, carParking: e.target.value }))
          }
          placeholder="Car parking details"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Indoor/Outdoor</label>
        <select
          className="form-select"
          value={formData.indoorOutdoor}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, indoorOutdoor: e.target.value }))
          }
        >
          <option value="">Select</option>
          <option value="indoor">Indoor</option>
          <option value="outdoor">Outdoor</option>
          <option value="both">Both</option>
        </select>
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Alcohol Policy</label>
        <select
          className="form-select"
          value={formData.alcoholPolicy}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, alcoholPolicy: e.target.value }))
          }
        >
          <option value="">Select</option>
          <option value="allowed">Allowed</option>
          <option value="not_allowed">Not Allowed</option>
          <option value="own_alcohol">Own Alcohol</option>
        </select>
      </div>
    </div>
  );

  const renderPoliciesTerms = () => (
    <div className="row">
      <div className="col-12 mb-3">
        <label className="form-label fw-semibold">Cancellation Policy</label>
        <textarea
          className="form-control"
          rows="3"
          value={formData.cancellationPolicy}
          onChange={(e) =>
            setFormData((prev) => ({
              ...prev,
              cancellationPolicy: e.target.value,
            }))
          }
          placeholder="Enter cancellation policy"
        />
      </div>
      <div className="col-12 mb-3">
        <label className="form-label fw-semibold">Refund Policy</label>
        <textarea
          className="form-control"
          rows="3"
          value={formData.refundPolicy}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, refundPolicy: e.target.value }))
          }
          placeholder="Enter refund policy"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Advance Payment %</label>
        <input
          type="number"
          className="form-control"
          value={formData.paymentTerms.advancePercent}
          onChange={(e) =>
            handleNestedInputChange(
              "paymentTerms",
              "advancePercent",
              e.target.value
            )
          }
          placeholder="Advance payment percentage"
        />
      </div>
      <div className="col-12 mb-3">
        <label className="form-label fw-semibold">Terms & Conditions</label>
        <textarea
          className="form-control"
          rows="4"
          value={formData.tnc}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, tnc: e.target.value }))
          }
          placeholder="Enter terms and conditions"
        />
      </div>
    </div>
  );

  const renderAvailabilitySlots = () => (
    <div className="row">
      <div className="col-md-4 mb-3">
        <label className="form-label fw-semibold">Opening Time</label>
        <input
          type="time"
          className="form-control"
          value={formData.timing.open}
          onChange={(e) =>
            handleNestedInputChange("timing", "open", e.target.value)
          }
        />
      </div>
      <div className="col-md-4 mb-3">
        <label className="form-label fw-semibold">Closing Time</label>
        <input
          type="time"
          className="form-control"
          value={formData.timing.close}
          onChange={(e) =>
            handleNestedInputChange("timing", "close", e.target.value)
          }
        />
      </div>
      <div className="col-md-4 mb-3">
        <label className="form-label fw-semibold">Last Entry Time</label>
        <input
          type="time"
          className="form-control"
          value={formData.timing.lastEntry}
          onChange={(e) =>
            handleNestedInputChange("timing", "lastEntry", e.target.value)
          }
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Feature Available</label>
        <select
          className="form-select"
          value={formData.isFeatureAvailable}
          onChange={(e) =>
            setFormData((prev) => ({
              ...prev,
              isFeatureAvailable: e.target.value,
            }))
          }
        >
          <option value="Yes">Yes</option>
          <option value="No">No</option>
        </select>
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">24hr Availability</label>
        <select
          className="form-select"
          value={formData.within24HrAvailable}
          onChange={(e) =>
            setFormData((prev) => ({
              ...prev,
              within24HrAvailable: e.target.value,
            }))
          }
        >
          <option value="Yes">Yes</option>
          <option value="No">No</option>
        </select>
      </div>
    </div>
  );

  const renderMarketingCTA = () => (
    <div className="row">
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Primary CTA</label>
        <select
          className="form-select"
          value={formData.primaryCTA}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, primaryCTA: e.target.value }))
          }
        >
          <option value="enquire">Enquire</option>
          <option value="call">Call</option>
          <option value="visit">Visit</option>
          <option value="book">Book</option>
        </select>
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">CTA Phone</label>
        <input
          type="tel"
          className="form-control"
          value={formData.ctaPhone}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, ctaPhone: e.target.value }))
          }
          placeholder="CTA phone number"
        />
      </div>
      <div className="col-12 mb-3">
        <label className="form-label fw-semibold">CTA URL</label>
        <input
          type="url"
          className="form-control"
          value={formData.ctaUrl}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, ctaUrl: e.target.value }))
          }
          placeholder="CTA URL"
        />
      </div>
      <div className="col-12 mb-3">
        <label className="form-label fw-semibold">Auto Reply Message</label>
        <textarea
          className="form-control"
          rows="3"
          value={formData.autoReply}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, autoReply: e.target.value }))
          }
          placeholder="Auto reply message"
        />
      </div>
      <div className="col-md-6 mb-3">
        <label className="form-label fw-semibold">Sort Weight</label>
        <input
          type="number"
          className="form-control"
          value={formData.sortWeight}
          onChange={(e) =>
            setFormData((prev) => ({ ...prev, sortWeight: e.target.value }))
          }
          placeholder="Sort weight"
        />
      </div>
      <div className="col-md-6 mb-3">
        <div className="form-check mt-4">
          <input
            className="form-check-input"
            type="checkbox"
            checked={formData.isFeatured}
            onChange={(e) =>
              setFormData((prev) => ({ ...prev, isFeatured: e.target.checked }))
            }
          />
          <label className="form-check-label fw-semibold">
            Featured Vendor
          </label>
        </div>
      </div>
    </div>
  );

  const renderContent = () => {
    switch (activeSection) {
      case "basic":
        return renderBasicInfo();
      case "contact":
        return renderContactDetails();
      case "location":
        return renderLocationDetails();
      case "media":
        return renderMediaGallery();
      case "pricing":
        return renderPricingPackages();
      case "facilities":
        return renderFacilitiesFeatures();
      case "policies":
        return renderPoliciesTerms();
      case "availability":
        return renderAvailabilitySlots();
      case "marketing":
        return renderMarketingCTA();
      default:
        return renderBasicInfo();
    }
  };

  return (
    <div className="row">
      {/* Sidebar Navigation */}
      <div className="col-md-3 border-end">
        <div className="sticky-top" style={{ top: "20px" }}>
          <h6 className="mb-3 fw-bold text-primary">Vendor Form Sections</h6>
          <nav className="nav flex-column">
            {sections.map((section) => (
              <button
                key={section.id}
                onClick={() => setActiveSection(section.id)}
                className={`nav-link text-start d-flex align-items-center gap-2 mb-2 ${
                  activeSection === section.id
                    ? "active bg-primary text-white"
                    : "text-secondary"
                }`}
                style={{
                  border: "none",
                  borderRadius: "8px",
                  padding: "12px 16px",
                  fontSize: "14px",
                  transition: "all 0.3s ease",
                }}
              >
                {section.icon}
                <span>{section.label}</span>
              </button>
            ))}
          </nav>
        </div>
      </div>

      {/* Main Content */}
      <div className="col-md-9">
        <div className="card border-0 shadow-sm">
          <div className="card-header bg-white border-bottom">
            <h5 className="mb-0 fw-bold text-primary">
              {sections.find((s) => s.id === activeSection)?.icon}{" "}
              {sections.find((s) => s.id === activeSection)?.label}
            </h5>
          </div>
          <div className="card-body p-4">{renderContent()}</div>
          <div className="card-footer bg-light border-top">
            <div className="d-flex justify-content-between align-items-center">
              <div className="text-muted small">
                Section {sections.findIndex((s) => s.id === activeSection) + 1}{" "}
                of {sections.length}
              </div>
              <div className="d-flex gap-2">
                {activeSection !== "basic" && (
                  <button
                    className="btn btn-outline-secondary"
                    onClick={() => {
                      const currentIndex = sections.findIndex(
                        (s) => s.id === activeSection
                      );
                      if (currentIndex > 0) {
                        setActiveSection(sections[currentIndex - 1].id);
                      }
                    }}
                  >
                    Previous
                  </button>
                )}
                {activeSection !== "marketing" && (
                  <button
                    className="btn btn-primary"
                    onClick={() => {
                      const currentIndex = sections.findIndex(
                        (s) => s.id === activeSection
                      );
                      if (currentIndex < sections.length - 1) {
                        setActiveSection(sections[currentIndex + 1].id);
                      }
                    }}
                  >
                    Next
                  </button>
                )}
                {activeSection === "marketing" && (
                  <button className="btn btn-success">Save Vendor</button>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VendorForm;
