import React, { useEffect, useState, useRef } from "react";
import { IMAGE_BASE_URL } from "../../config/constants";
import { Container, Row, Col, Button, Modal } from "react-bootstrap";
import { FaLocationDot } from "react-icons/fa6";
import { Swiper, SwiperSlide } from "swiper/react";
import { Autoplay } from "swiper/modules";
import { useNavigate, useParams } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { toggleWishlist } from "../../redux/authSlice";
import WishlistBubble from "../common/WishlistBubble";
import "swiper/css";
import "swiper/css/autoplay";
import PricingModal from "./PricingModal";
import BusinessClaimForm from "../pages/BusinessClaimForm";
import DOMPurify from "dompurify";

const extractMainCity = (rawCity) => {
  if (!rawCity || typeof rawCity !== "string") return null;
  let cleaned = rawCity.replace(/\bdistricts?\b/i, "").trim();
  if (cleaned.toLowerCase().includes("location not specified") || cleaned.toLowerCase() === "unknown") {
    return null;
  }
  const parts = cleaned.split(",");
  if (parts.length > 1) {
    const candidate = parts[parts.length - 1].trim();
    if (candidate && !candidate.toLowerCase().includes("location not specified") && candidate.toLowerCase() !== "unknown") {
      return candidate;
    }
  }
  return cleaned || null;
};


import {
  FaStar,
  FaMapMarkerAlt,
  FaHeart,
  FaRegHeart,
  FaUsers,
  FaUtensils,
  FaBed,
  FaParking,
  FaGlassCheers,
  FaCalendarAlt,
  FaChevronDown,
  FaChevronUp,
} from "react-icons/fa";
import { GrFormNextLink } from "react-icons/gr";
import ReviewSection from "../pages/ReviewSection";
import axios from "axios";
import { subVenuesData } from "../../data/subVenuesData";
import { subVendorsData } from "../../data/subVendorsData";
const API_BASE_URL = "https://happywedz.com";
import Swal from "sweetalert2";
import SectionTabs from "./SectionTabs";
import { TbView360Number } from "react-icons/tb";
import { hasView360 } from "../../utils/view360Helper";
import GridView from "./Main/GridView";
import SimilarServices from "./SimilarServices";
import SEO from "../common/SEO";
import VenueFAQ from "./VenueFAQ";
import Breadcrumbs from "../common/Breadcrumbs";
import StructuredData from "../common/StructuredData";
import { formatDate } from "../../utils/dateFormat";




const capitalizeWords = (str) => {
  if (!str) return "";
  return str.replace(/^(.)|\s+(.)/g, (c) => c.toUpperCase());
};

const formatList = (list, limit = 5) => {
  if (!Array.isArray(list) || list.length === 0) return "";
  return list.slice(0, limit).join(", ");
};

const formatKeyValuePairs = (obj, limit = 4) => {
  if (!obj || typeof obj !== "object" || Array.isArray(obj)) return "";
  const entries = Object.entries(obj).filter(
    ([key, value]) => key && String(value || "").trim(),
  );
  if (!entries.length) return "";
  return entries
    .slice(0, limit)
    .map(([key, value]) => `${key}: ${value}`)
    .join(", ");
};

const pushFeature = (arr, icon, label, value) => {
  if (value === undefined || value === null) return;
  const text = String(value).trim();
  if (!text) return;
  arr.push({ icon, name: `${label}: ${text}` });
};

const getYouTubeVideoId = (url) => {
  if (!url) return null;
  const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*/;
  const match = url.match(regExp);
  return match && match[2].length === 11 ? match[2] : null;
};

const Detailed = () => {
  const { city, slug, section } = useParams();
  const dispatch = useDispatch();
  const { token } = useSelector((state) => state.auth);
  const [venueData, setVenueData] = useState(null);
  const id = venueData?.id;
  const [profileViews, setProfileViews] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [mainImage, setMainImage] = useState("");
  const [mainVideo, setMainVideo] = useState(null);
  const [hoveredIndex, setHoveredIndex] = useState(null);
  const [favorites, setFavorites] = useState({});
  const [wishlistIds, setWishlistIds] = useState(new Set());
  const [images, setImages] = useState([]);
  const [videos, setVideos] = useState([]);
  const [mediaTab, setMediaTab] = useState("gallery"); // 'gallery' | 'video'
  const [showPricingModal, setShowPricingModal] = useState(false);
  const [selectedVendorId, setSelectedVendorId] = useState(null);
  const [showClaimForm, setShowClaimForm] = useState(false);
  const [showAllFaqs, setShowAllFaqs] = useState(false);
  const [showAllFeatures, setShowAllFeatures] = useState(false);
  const [showStartingPrice, setShowStartingPrice] = useState(false);
  const navigate = useNavigate();
  const handleShowPricingModal = (vendorId) => {
    setSelectedVendorId(vendorId);
    setShowPricingModal(true);
  };

  const getVendorFeatures = (data) => {
    if (!data || !data.attributes) return [];

    const attributes = data.attributes;
    const amenities = [];
    const vendorType = attributes.vendor_type;
    const normalizedVendorType = String(vendorType || "").toLowerCase();
    const venueMaster = attributes.venue_master || {};
    const catererMaster = attributes.caterer_master || {};
    const photographerMaster = attributes.photographer_master || {};
    const makeupArtistMaster = attributes.makeup_artist_master || {};
    const sherwaniMaster = attributes.sherwani_master || {};
    const mehndiArtistMaster = attributes.mehndi_artist_master || {};
    const floristMaster = attributes.florist_master || {};
    const panditMaster = attributes.pandit_master || {};
    const djMaster = attributes.dj_master || {};
    const sangeetChoreographerMaster = attributes.sangeet_choreographer_master || {};
    const weddingEntertainerMaster = attributes.wedding_entertainer_master || {};
    const preWeddingLocationMaster = attributes.pre_wedding_location_master || {};
    const preWeddingPhotographerMaster = attributes.pre_wedding_photographer_master || {};
    const jewelleryMaster = attributes.jewellery_master || {};
    const jewelleryRentalMaster = attributes.jewellery_rental_master || {};
    const accessoriesMaster = attributes.accessories_master || {};
    const flowerJewelleryMaster = attributes.flower_jewellery_master || {};
    const cocktailGownMaster = attributes.cocktail_gown_master || {};
    const bridalOutfitMaster = attributes.bridal_outfit_master || {};
    const rentalOutfitMaster = attributes.rental_outfit_master || {};

    if (attributes.payment_terms) {
      amenities.push({
        icon: <FaCalendarAlt />,
        name: `Payment: ${attributes.payment_terms}`,
      });
    }
    if (attributes.travel_info) {
      amenities.push({
        icon: <FaMapMarkerAlt />,
        name: `Travel: ${attributes.travel_info}`,
      });
    }
    if (attributes.happywedz_since || attributes.HappyWedz) {
      const sinceValue = attributes.happywedz_since || attributes.HappyWedz;
      amenities.push({
        icon: <FaStar />,
        name: `HappyWedz: ${sinceValue}`,
      });
    }

    // --- VENUE-SPECIFIC FEATURES (Combined Attributes + Master) ---
    if (vendorType === "Venues" || attributes.catering_policy || attributes.rooms || Object.keys(venueMaster).length > 0) {
      // Section 1: Identity & Categories
      const vIdentity = venueMaster.identity || {};
      const vc = venueMaster.categories || {};
      pushFeature(amenities, <FaStar />, "Premium & Experience", formatList(vc.premium));
      pushFeature(amenities, <FaStar />, "Location Based", formatList(vc.locationBased));
      pushFeature(amenities, <FaStar />, "Capacity Based", formatList(vc.capacityBased));
      pushFeature(amenities, <FaStar />, "Budget Based", formatList(vc.budgetBased));
      pushFeature(amenities, <FaStar />, "Function Specific", formatList(vc.functionSpecific));
      pushFeature(amenities, <FaStar />, "Facility Based", formatList(vc.facilityBased));
      pushFeature(amenities, <FaStar />, "Booking & Usage", formatList(vc.bookingFlex));
      pushFeature(amenities, <FaStar />, "Trend & Modern", formatList(vc.trendModern));

      pushFeature(amenities, <FaMapMarkerAlt />, "Property Ownership", vIdentity.property_ownership === "Other" ? vIdentity.property_ownership_other : vIdentity.property_ownership);
      pushFeature(amenities, <FaStar />, "Years of Operation", vIdentity.years_of_operation);
      pushFeature(amenities, <FaMapMarkerAlt />, "Location Type", vIdentity.location_type === "Other" ? vIdentity.location_type_other : vIdentity.location_type);
      pushFeature(amenities, <FaStar />, "Chain Property", vIdentity.chain_property);
      pushFeature(amenities, <FaStar />, "Brand Name", vIdentity.chain_brand_name);
      pushFeature(amenities, <FaStar />, "Brand Category", vIdentity.chain_brand_category === "Other" ? vIdentity.chain_brand_category_other : vIdentity.chain_brand_category);

      // Section 2: Space & Capacity
      const vSpace = venueMaster.space_capacity || {};
      pushFeature(amenities, <FaStar />, "Space Types", formatList(vSpace.space_types));
      if (vSpace.space_types_other) pushFeature(amenities, <FaStar />, "Other Space Types", vSpace.space_types_other);
      pushFeature(amenities, <FaStar />, "Total Event Spaces", vSpace.num_event_spaces);
      pushFeature(amenities, <FaStar />, "Indoor Spaces", vSpace.indoor_spaces_count);
      pushFeature(amenities, <FaStar />, "Outdoor Spaces", vSpace.outdoor_spaces_count);
      pushFeature(amenities, <FaUsers />, "Indoor Seating", vSpace.indoor_seating);
      pushFeature(amenities, <FaUsers />, "Indoor Floating", vSpace.indoor_floating);
      pushFeature(amenities, <FaUsers />, "Outdoor Seating", vSpace.outdoor_seating);
      pushFeature(amenities, <FaUsers />, "Outdoor Floating", vSpace.outdoor_floating);
      pushFeature(amenities, <FaUsers />, "Min Guests", vSpace.min_guests);
      pushFeature(amenities, <FaUsers />, "Max Guests", vSpace.max_guests);
      pushFeature(amenities, <FaStar />, "Separate Function Areas", vSpace.separate_function_areas);
      pushFeature(amenities, <FaStar />, "Simultaneous Events", vSpace.multiple_events_simultaneous);
      pushFeature(amenities, <FaStar />, "Exclusive Booking", vSpace.exclusive_booking);
      
      if (vSpace.spaces && Array.isArray(vSpace.spaces)) {
        vSpace.spaces.forEach((s, idx) => {
          if (s.space_name) {
            let details = `${s.seating || 0} Seating | ${s.floating || 0} Floating`;
            if (s.space_type) details += ` (${s.space_type})`;
            if (s.indoor_outdoor) details += ` | ${s.indoor_outdoor}`;
            if (s.ac === "Yes") details += ` | AC`;
            if (s.dedicated_kitchen === "Yes") details += ` | Kitchen`;
            if (s.attached_rooms === "Yes") details += ` | Rooms`;
            if (s.notes) details += ` | Notes: ${s.notes}`;
            pushFeature(amenities, <FaUsers />, `Space: ${s.space_name}`, details);
          }
        });
      }

      if (attributes.area) {
        const areas = attributes.area.split(",").map((s) => s.trim());
        areas.forEach((area) => {
          const match = area.match(/(\w+)\s*(\d+)\s*Seating\s*\|\s*(\d+)\s*Floating\s*(.*)/i);
          if (match) {
            const [, , seating, floating, locationPart] = match;
            let venueName = locationPart.replace(/^(,)\s*/, "").trim() || area.split(" ")[0];
            venueName = capitalizeWords(venueName.replace("Banquetpoolside", "Banquet Poolside").replace("Poolsideoutdoor", "Poolside/Outdoor").replace("Lawnoutdoor", "Lawn/Outdoor"));
            amenities.push({ icon: <FaUsers />, name: `${venueName}: ${seating} Seating | ${floating} Floating` });
          } else {
            amenities.push({ icon: <FaUsers />, name: capitalizeWords(area) });
          }
        });
      }

      // Section 3: Rooms & Accommodation
      const vRooms = venueMaster.rooms || {};
      pushFeature(amenities, <FaBed />, "Number of Rooms", vRooms.num_rooms || attributes.rooms);
      pushFeature(amenities, <FaBed />, "Max Occupancy Per Room", vRooms.max_occupancy_per_room);
      pushFeature(amenities, <FaBed />, "Extra Bed Available", vRooms.extra_bed);
      pushFeature(amenities, <FaBed />, "Room Price Range", vRooms.room_price_range === "Other" ? vRooms.room_price_range_other : vRooms.room_price_range);
      pushFeature(amenities, <FaBed />, "Complimentary Rooms", vRooms.complimentary_rooms);
      pushFeature(amenities, <FaBed />, "Total Stay Capacity", vRooms.total_stay_capacity);
      pushFeature(amenities, <FaBed />, "Room Types", formatList(vRooms.room_types));
      if (vRooms.room_types_other) pushFeature(amenities, <FaBed />, "Other Room Types", vRooms.room_types_other);
      if (vRooms.room_type_counts && typeof vRooms.room_type_counts === "object") {
        Object.entries(vRooms.room_type_counts).forEach(([type, count]) => {
          if (count) pushFeature(amenities, <FaBed />, `${type} Rooms`, count);
        });
      }

      // Section 4: Food & Catering
      const vFood = venueMaster.food || {};
      pushFeature(amenities, <FaUtensils />, "Catering Policy", vFood.catering_policy === "Other" ? vFood.catering_policy_other : (vFood.catering_policy || attributes.catering_policy));
      pushFeature(amenities, <FaUtensils />, "Veg/Non-Veg", vFood.veg_non_veg === "Other" ? vFood.veg_non_veg_other : vFood.veg_non_veg);
      pushFeature(amenities, <FaUtensils />, "Cuisine", formatList(vFood.cuisines, 15));
      if (vFood.cuisines_other) pushFeature(amenities, <FaUtensils />, "Other Cuisines", vFood.cuisines_other);
      pushFeature(amenities, <FaUtensils />, "Jain Food", vFood.jain_food);
      pushFeature(amenities, <FaUtensils />, "Per Plate Cost", vFood.per_plate_cost_range === "Other" ? vFood.per_plate_cost_range_other : vFood.per_plate_cost_range);
      pushFeature(amenities, <FaUtensils />, "Outside Catering Charges", vFood.outside_catering_charges === "Other" ? vFood.outside_catering_charges_other : vFood.outside_catering_charges);
      pushFeature(amenities, <FaUtensils />, "Kitchen for External Caterer", vFood.kitchen_for_external);

      // Section 5: Alcohol
      const vAlcohol = venueMaster.alcohol || {};
      pushFeature(amenities, <FaGlassCheers />, "Alcohol Policy", vAlcohol.policy === "Other" ? vAlcohol.policy_other : (vAlcohol.policy || attributes.alcohol_policy));
      pushFeature(amenities, <FaGlassCheers />, "Corkage Charges", vAlcohol.corkage === "Other" ? vAlcohol.corkage_other : vAlcohol.corkage);
      pushFeature(amenities, <FaGlassCheers />, "Bar Setup", formatList(vAlcohol.bar_setup));
      if (vAlcohol.bar_setup_other) pushFeature(amenities, <FaGlassCheers />, "Other Bar Setup", vAlcohol.bar_setup_other);
      pushFeature(amenities, <FaGlassCheers />, "Outside Alcohol", attributes.outside_alcohol);

      // Section 6: Decor & Production
      const vDecor = venueMaster.decor || {};
      pushFeature(amenities, <FaStar />, "Decor Policy", vDecor.policy === "Other" ? vDecor.policy_other : (vDecor.policy || attributes.decor_policy));
      pushFeature(amenities, <FaStar />, "Decor Capabilities", formatList(vDecor.capabilities, 10));
      if (vDecor.capabilities_other) pushFeature(amenities, <FaStar />, "Other Capabilities", vDecor.capabilities_other);
      pushFeature(amenities, <FaStar />, "Stage Decor", formatList(vDecor.stage));
      if (vDecor.stage_other) pushFeature(amenities, <FaStar />, "Other Stage Decor", vDecor.stage_other);
      pushFeature(amenities, <FaStar />, "Mandap Decor", formatList(vDecor.mandap));
      if (vDecor.mandap_other) pushFeature(amenities, <FaStar />, "Other Mandap Decor", vDecor.mandap_other);
      pushFeature(amenities, <FaStar />, "Lighting Setup", formatList(vDecor.lighting));
      if (vDecor.lighting_other) pushFeature(amenities, <FaStar />, "Other Lighting", vDecor.lighting_other);
      pushFeature(amenities, <FaStar />, "Sound System", formatList(vDecor.sound));
      if (vDecor.sound_other) pushFeature(amenities, <FaStar />, "Other Sound", vDecor.sound_other);
      pushFeature(amenities, <FaStar />, "Outside Decor Charges", vDecor.outside_charges === "Other" ? vDecor.outside_charges_other : vDecor.outside_charges);

      // Section 7: Entertainment & DJ
      const vEntertainment = venueMaster.entertainment || {};
      pushFeature(amenities, <FaCalendarAlt />, "DJ Policy", vEntertainment.dj_policy === "Other" ? vEntertainment.dj_policy_other : (vEntertainment.dj_policy || attributes.dJ_policy));
      pushFeature(amenities, <FaCalendarAlt />, "Noise Restriction", vEntertainment.noise === "Other" ? vEntertainment.noise_other : vEntertainment.noise);
      pushFeature(amenities, <FaCalendarAlt />, "Live Band Available", vEntertainment.live_band);
      pushFeature(amenities, <FaCalendarAlt />, "Fireworks Allowed", vEntertainment.fireworks === "Other" ? vEntertainment.fireworks_other : vEntertainment.fireworks);
      pushFeature(amenities, <FaCalendarAlt />, "Entertainment Supported", formatList(vEntertainment.supported, 10));
      if (vEntertainment.supported_other) pushFeature(amenities, <FaCalendarAlt />, "Other Entertainment", vEntertainment.supported_other);

      // Section 8: Facilities
      const vFacilities = venueMaster.facilities || {};
      pushFeature(amenities, <FaParking />, "Parking Available", vFacilities.parking || attributes.parking);
      pushFeature(amenities, <FaParking />, "Parking Capacity", vFacilities.parking_capacity);
      pushFeature(amenities, <FaParking />, "Valet Parking", vFacilities.valet);
      pushFeature(amenities, <FaStar />, "Power Backup", formatList(vFacilities.power_backup));
      if (vFacilities.power_backup_other) pushFeature(amenities, <FaStar />, "Other Power Backup", vFacilities.power_backup_other);
      pushFeature(amenities, <FaStar />, "Air Conditioning", vFacilities.ac === "Other" ? vFacilities.ac_other : vFacilities.ac);
      pushFeature(amenities, <FaStar />, "Bridal Room", vFacilities.bridal_room);
      pushFeature(amenities, <FaStar />, "Groom Room", vFacilities.groom_room);
      pushFeature(amenities, <FaStar />, "Wheelchair Accessible", vFacilities.wheelchair);
      pushFeature(amenities, <FaStar />, "Washroom Quality", vFacilities.washroom === "Other" ? vFacilities.washroom_other : vFacilities.washroom);
      pushFeature(amenities, <FaStar />, "Lift/Elevator", vFacilities.lift);
      pushFeature(amenities, <FaStar />, "Security Services", vFacilities.security === "Other" ? vFacilities.security_other : vFacilities.security);
      pushFeature(amenities, <FaStar />, "Additional Facilities", formatList(vFacilities.additional, 10));
      if (vFacilities.additional_other) pushFeature(amenities, <FaStar />, "Other Facilities", vFacilities.additional_other);

      // Section 9: Pricing & Booking
      const vPricing = venueMaster.pricing_booking || {};
      pushFeature(amenities, <FaStar />, "Pricing Model", formatList(vPricing.pricing_model));
      if (vPricing.pricing_model_other) pushFeature(amenities, <FaStar />, "Other Pricing Model", vPricing.pricing_model_other);
      pushFeature(amenities, <FaStar />, "Starting Venue Price", vPricing.starting_venue_price);
      pushFeature(amenities, <FaStar />, "Peak Season Pricing", vPricing.peak_season_pricing);
      pushFeature(amenities, <FaStar />, "Advance Booking Required", vPricing.advance_booking_required);
      pushFeature(amenities, <FaStar />, "Advance Payment Range", vPricing.advance_payment_range === "Other" ? vPricing.advance_payment_range_other : vPricing.advance_payment_range);
      pushFeature(amenities, <FaStar />, "Min Booking Duration", formatList(vPricing.min_booking_duration));
      if (vPricing.min_booking_duration_other) pushFeature(amenities, <FaStar />, "Other Min Duration", vPricing.min_booking_duration_other);
      pushFeature(amenities, <FaStar />, "Cancellation Policy", vPricing.cancellation === "Other" ? vPricing.cancellation_other : (vPricing.cancellation || attributes.cancellation_policy));
      pushFeature(amenities, <FaStar />, "Refund Timeline", vPricing.refund_timeline === "Other" ? vPricing.refund_timeline_other : vPricing.refund_timeline);

      // Section 10: Event Suitability
      const vSuitability = venueMaster.suitability || {};
      pushFeature(amenities, <FaUsers />, "Suitable For", formatList(vSuitability.suitable_for, 20));
      if (vSuitability.suitable_for_other) pushFeature(amenities, <FaUsers />, "Other Suitable For", vSuitability.suitable_for_other);
      pushFeature(amenities, <FaUsers />, "Best For", formatList(vSuitability.best_for, 10));
      if (vSuitability.best_for_other) pushFeature(amenities, <FaUsers />, "Other Best For", vSuitability.best_for_other);
      pushFeature(amenities, <FaUsers />, "Ideal Guest Range", formatList(vSuitability.ideal_guest_range));
      if (vSuitability.ideal_guest_range_other) pushFeature(amenities, <FaUsers />, "Other Guest Range", vSuitability.ideal_guest_range_other);
    }

    // --- CATERER MASTER ATTRIBUTES ---
    if (catererMaster && Object.keys(catererMaster).length > 0) {
      const ci = catererMaster.identity || {};
      const cs = catererMaster.service_type || {};
      const cc = catererMaster.cuisine_intelligence || {};
      const cm = catererMaster.menu_customization || {};
      const cx = catererMaster.scale_execution || {};
      const cp = catererMaster.pricing_structure || {};
      const cie = catererMaster.infrastructure_equipment || {};
      const chq = catererMaster.hygiene_quality || {};
      const cl = catererMaster.venue_logistics || {};
      const ces = catererMaster.event_suitability || {};
      const cwb = catererMaster.workflow_booking || {};

      // Section 1: Basic Identity
      pushFeature(amenities, <FaStar />, "Caterer Type", ci.caterer_type);
      pushFeature(amenities, <FaStar />, "Years of Experience", ci.years_experience);
      pushFeature(amenities, <FaMapMarkerAlt />, "Service Coverage", ci.service_coverage);
      pushFeature(amenities, <FaUsers />, "Team Size", ci.team_size);
      pushFeature(amenities, <FaMapMarkerAlt />, "Service Locations", formatList(ci.service_locations));

      // Section 2: Service Type
      pushFeature(amenities, <FaUtensils />, "Catering Style", formatList(cs.catering_style));
      pushFeature(amenities, <FaCalendarAlt />, "Event Types Covered", formatList(cs.event_types_covered));
      pushFeature(amenities, <FaUtensils />, "Veg / Non-Veg", cs.veg_non_veg);
      pushFeature(amenities, <FaUtensils />, "Jain Food", cs.jain_food);
      pushFeature(amenities, <FaUtensils />, "Special Dietary Options", formatList(cs.special_dietary_options));

      // Section 3: Cuisine Intelligence
      pushFeature(amenities, <FaUtensils />, "Cuisine Types", formatList(cc.cuisine_types, 15));
      pushFeature(amenities, <FaUtensils />, "Signature Dishes", cc.signature_dishes);
      pushFeature(amenities, <FaStar />, "Best Known For", formatList(cc.best_known_for));

      // Section 4: Menu & Customization
      pushFeature(amenities, <FaUtensils />, "Custom Menu Available", cm.custom_menu_available);
      pushFeature(amenities, <FaUtensils />, "Menu Tasting Available", cm.menu_tasting_available);
      pushFeature(amenities, <FaStar />, "Tasting Charges", cm.tasting_charges);
      pushFeature(amenities, <FaUtensils />, "Menu Items Offered", cm.menu_items_offered);
      pushFeature(amenities, <FaUtensils />, "Live Counters Available", cm.live_counters_available);
      pushFeature(amenities, <FaUtensils />, "Popular Live Counters", formatList(cm.popular_live_counters));

      // Section 5: Scale & Execution
      pushFeature(amenities, <FaUsers />, "Minimum Pax", cx.minimum_pax);
      pushFeature(amenities, <FaUsers />, "Maximum Pax", cx.maximum_pax);
      pushFeature(amenities, <FaUsers />, "Events Handled Per Day", cx.events_per_day);
      pushFeature(amenities, <FaUsers />, "Multiple Event Handling", cx.multiple_event_handling);

      // Section 6: Pricing Structure
      pushFeature(amenities, <FaStar />, "Per Plate Starting Price", cp.per_plate_starting_price);
      pushFeature(amenities, <FaStar />, "Price Range", cp.price_range);
      pushFeature(amenities, <FaStar />, "Pricing Type", cp.pricing_type);
      pushFeature(amenities, <FaStar />, "Extra Charges", formatList(cp.extra_charges));

      // Section 7: Infrastructure & Equipment
      pushFeature(amenities, <FaUtensils />, "Kitchen Setup", cie.kitchen_setup);
      pushFeature(amenities, <FaUsers />, "Serving Staff Included", cie.serving_staff_included);
      pushFeature(amenities, <FaUtensils />, "Serving Style", cie.serving_style);
      pushFeature(amenities, <FaUtensils />, "Utensils & Crockery", cie.utensils_crockery);
      pushFeature(amenities, <FaUtensils />, "Eco-Friendly Options", cie.eco_friendly_options);

      // Section 8: Hygiene & Quality
      pushFeature(amenities, <FaStar />, "Hygiene Standards", formatList(chq.hygiene_standards));
      pushFeature(amenities, <FaStar />, "Food Quality Assurance", chq.food_quality_assurance);

      // Section 9: Venue & Logistics
      pushFeature(amenities, <FaMapMarkerAlt />, "Outdoor Catering Supported", cl.outdoor_catering_supported);
      pushFeature(amenities, <FaMapMarkerAlt />, "Destination Weddings Supported", cl.destination_weddings_supported);
      pushFeature(amenities, <FaMapMarkerAlt />, "Travel Charges", cl.travel_charges);
      pushFeature(amenities, <FaBed />, "Stay Requirement", cl.stay_requirement);

      // Section 10: Event Suitability
      pushFeature(amenities, <FaUsers />, "Functions Suitable For", formatList(ces.functions_suitable_for, 15));
      pushFeature(amenities, <FaStar />, "Best For", formatList(ces.best_for));

      // Section 11: Workflow & Booking
      pushFeature(amenities, <FaStar />, "Advance Required", cwb.advance_required);
      pushFeature(amenities, <FaStar />, "Advance Percentage", cwb.advance_percentage);
      pushFeature(amenities, <FaCalendarAlt />, "Booking Timeline", cwb.booking_timeline);
      pushFeature(amenities, <FaStar />, "Cancellation Policy", cwb.cancellation_policy);
      pushFeature(amenities, <FaCalendarAlt />, "Refund Timeline", cwb.refund_timeline);
    }

    // --- PHOTOGRAPHER MASTER ATTRIBUTES ---
    if (photographerMaster && Object.keys(photographerMaster).length > 0) {
      const pi = photographerMaster.identity || {};
      const ps = photographerMaster.style_intelligence || {};
      const pt = photographerMaster.team_coverage || {};
      const pd = photographerMaster.deliverables || {};
      const pe = photographerMaster.equipment || {};
      const pp = photographerMaster.pricing || {};
      const pw = photographerMaster.workflow || {};
      const ppre = photographerMaster.prewedding_specialization || {};
      const pes = photographerMaster.event_suitability || {};

      pushFeature(
        amenities,
        <FaStar />,
        "Services",
        formatList(pi.services_offered, 5),
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Photography Style",
        formatList(ps.photography_style, 4),
      );
      pushFeature(amenities, <FaStar />, "Editing Style", ps.editing_style);
      pushFeature(amenities, <FaStar />, "Best Known For", formatList(ps.best_known_for, 5));
      pushFeature(
        amenities,
        <FaStar />,
        "Ideal Wedding Type",
        formatList(ps.ideal_wedding_type, 5),
      );
      pushFeature(amenities, <FaMapMarkerAlt />, "Travel Availability", pi.travel_availability);
      pushFeature(amenities, <FaStar />, "Also Available For", pi.also_available_for);
      pushFeature(amenities, <FaStar />, "Years of Experience", pi.years_of_experience);
      pushFeature(amenities, <FaUsers />, "Team Size", pt.team_size);
      pushFeature(amenities, <FaUsers />, "Max Events Per Day", pt.max_events_per_day);
      pushFeature(amenities, <FaUsers />, "Backup Team", pt.backup_team_available);
      pushFeature(
        amenities,
        <FaUsers />,
        "Female Photographer",
        pt.female_photographer_available,
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Photos Delivered",
        pd.photos_delivered,
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Videos Delivered",
        formatList(pd.videos_delivered, 3),
      );
      pushFeature(amenities, <FaStar />, "Album Included", pd.album_included);
      pushFeature(amenities, <FaStar />, "Album Type", pd.album_type);
      pushFeature(amenities, <FaStar />, "Raw Data Provided", pd.raw_data_provided);
      pushFeature(
        amenities,
        <FaStar />,
        "Express Delivery",
        pd.express_delivery_available,
      );
      pushFeature(
        amenities,
        <FaCalendarAlt />,
        "Delivery Time",
        pd.delivery_time,
      );
      pushFeature(amenities, <FaStar />, "Camera Type", pe.camera_type);
      pushFeature(amenities, <FaStar />, "Lighting Setup", pe.lighting_setup);
      pushFeature(
        amenities,
        <FaStar />,
        "Drone Available",
        pe.drone_available,
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Live Streaming Setup",
        pe.live_streaming_setup,
      );
      pushFeature(amenities, <FaStar />, "Starting Price", pp.starting_price);
      pushFeature(amenities, <FaStar />, "Pricing Type", pp.pricing_type);
      pushFeature(amenities, <FaMapMarkerAlt />, "Travel Charges", pp.travel_charges);
      pushFeature(
        amenities,
        <FaMapMarkerAlt />,
        "Accommodation Required",
        pp.accommodation_required,
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Pre-Wedding Shoot Cost",
        pp.pre_wedding_shoot_cost,
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Booking Advance Required",
        pw.booking_advance_required,
      );
      pushFeature(amenities, <FaStar />, "Advance Percentage", pw.advance_percentage);
      pushFeature(amenities, <FaStar />, "Revision Allowed", pw.revision_allowed);
      pushFeature(
        amenities,
        <FaStar />,
        "Number of Revisions",
        pw.number_of_revisions,
      );
      pushFeature(amenities, <FaStar />, "Cancellation Policy", pw.cancellation_policy);
      pushFeature(
        amenities,
        <FaCalendarAlt />,
        "Functions Covered",
        formatList(pes.functions_covered, 7),
      );
      pushFeature(amenities, <FaStar />, "Best For", formatList(pes.best_for, 5));
      pushFeature(
        amenities,
        <FaMapMarkerAlt />,
        "Pre-Wedding Locations",
        ppre.locations_supported,
      );
      pushFeature(amenities, <FaStar />, "Props Provided", ppre.props_provided);
      pushFeature(
        amenities,
        <FaStar />,
        "Concept Shoot Available",
        ppre.concept_shoot_available,
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Location Scouting Support",
        ppre.location_scouting_support,
      );
    }

    // --- MAKEUP ARTIST MASTER ATTRIBUTES ---
    if (makeupArtistMaster && Object.keys(makeupArtistMaster).length > 0) {
      const mi = makeupArtistMaster.identity || {};
      const ms = makeupArtistMaster.makeup_style_intelligence || {};
      const msk = makeupArtistMaster.skin_hair_expertise || {};
      const mp = makeupArtistMaster.pricing_structure || {};

      pushFeature(
        amenities,
        <FaStar />,
        "Services",
        formatList(mi.services_offered, 6),
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Signature Makeup",
        formatList(ms.signature_makeup_style, 5),
      );
      pushFeature(
        amenities,
        <FaMapMarkerAlt />,
        "Travel",
        mi.travel_availability,
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Skin Types",
        formatList(msk.skin_types_handled, 5),
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Starting Price",
        mp.bridal_makeup_starting_price,
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Cities",
        formatList(mi.cities, 4),
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Skin Tone Expertise",
        formatList(msk.skin_tone_expertise, 4),
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Product Category",
        makeupArtistMaster.products_brands?.product_category,
      );
    }

    // --- DYNAMIC MASTER PROFILE EXTRACTION (Planning & Decor, Invites & Gifts, Groomwear) ---
    const mapMasterProfile = (masterData) => {
      if (!masterData || typeof masterData !== "object") return;
      const skipSections = ["ai_faq"];
      const formatKey = (key) =>
        key.split("_").map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");

      Object.keys(masterData).forEach((sectionKey) => {
        if (skipSections.includes(sectionKey)) return;
        const sectionData = masterData[sectionKey];
        if (typeof sectionData === "object" && !Array.isArray(sectionData) && sectionData !== null) {
          Object.keys(sectionData).forEach((fieldKey) => {
            if (fieldKey === "vendor_type" || fieldKey === "brand_name") return;
            let val = sectionData[fieldKey];
            if (val === true) val = "Yes";
            if (
              val === false ||
              val === null ||
              val === "" ||
              (Array.isArray(val) && val.length === 0)
            )
              return;

            const displayVal = Array.isArray(val)
              ? formatList(val, 10)
              : String(val);
            pushFeature(amenities, <FaStar />, formatKey(fieldKey), displayVal);
          });
        }
      });
    };

    const dynamicMasters = [
      attributes.wedding_planner_master,
      attributes.decorator_master,
      attributes.trousseau_master,
      attributes.invitation_gift_master,
      attributes.gift_master,
      attributes.favor_master,
      attributes.invitation_master,
      attributes.wedding_suit_master,
      attributes.sherwani_master,
    ];

    dynamicMasters.forEach((master) => {
      if (master && Object.keys(master).length > 0) {
        mapMasterProfile(master);
      }
    });
    // --- MEHNDI ARTIST MASTER ATTRIBUTES ---
    if (mehndiArtistMaster && Object.keys(mehndiArtistMaster).length > 0) {
      const id = mehndiArtistMaster.identity || {};
      const srv = mehndiArtistMaster.services || {};
      const stl = mehndiArtistMaster.style_intelligence || {};
      const brd = mehndiArtistMaster.bridal_details || {};
      const gst = mehndiArtistMaster.guest_capacity || {};
      const mat = mehndiArtistMaster.material_quality || {};
      const evt = mehndiArtistMaster.event_suitability || {};
      const spd = mehndiArtistMaster.speed_execution || {};
      const prc = mehndiArtistMaster.pricing_travel || {};
      const wf = mehndiArtistMaster.workflow || {};

      pushFeature(amenities, <FaStar />, "Artist Type", id.artist_type);
      pushFeature(amenities, <FaStar />, "Years of Experience", id.years_of_experience);
      pushFeature(amenities, <FaMapMarkerAlt />, "Travel Availability", id.travel_availability);
      pushFeature(amenities, <FaUsers />, "Team Size", id.team_size);

      pushFeature(amenities, <FaStar />, "Services", formatList(srv.services_offered, 5));
      pushFeature(amenities, <FaStar />, "Coverage Type", formatList(srv.coverage_type, 3));

      pushFeature(amenities, <FaStar />, "Mehendi Style", formatList(stl.mehendi_style, 5));
      pushFeature(amenities, <FaStar />, "Design Complexity", stl.design_complexity);
      pushFeature(amenities, <FaStar />, "Best Known For", formatList(stl.best_known_for, 4));
      pushFeature(amenities, <FaStar />, "Custom Designs", stl.custom_designs_available);
      pushFeature(amenities, <FaStar />, "Personalization", formatList(stl.personalization_options, 4));

      pushFeature(amenities, <FaStar />, "Bridal Coverage", brd.bridal_coverage);
      pushFeature(amenities, <FaStar />, "Bridal Duration", brd.bridal_duration);
      if (brd.bridal_starting_price) {
        pushFeature(amenities, <FaStar />, "Bridal Starting Price", `₹${brd.bridal_starting_price}`);
      }

      pushFeature(amenities, <FaUsers />, "Guests Per Hour", gst.guests_per_hour);
      pushFeature(amenities, <FaUsers />, "Max Guests Covered", gst.max_guests_covered);
      pushFeature(amenities, <FaStar />, "Guest Pricing Model", gst.guest_pricing_model);
      pushFeature(amenities, <FaStar />, "Team Support for Guests", gst.team_support_for_guests);

      pushFeature(amenities, <FaStar />, "Mehendi Type", mat.mehendi_type);
      pushFeature(amenities, <FaStar />, "Color Guarantee", mat.color_guarantee);
      pushFeature(amenities, <FaStar />, "Aftercare Provided", mat.aftercare_instructions_provided);
      pushFeature(amenities, <FaStar />, "Allergies Consideration", mat.allergies_consideration);

      pushFeature(amenities, <FaCalendarAlt />, "Functions Covered", formatList(evt.functions_covered, 5));
      pushFeature(amenities, <FaStar />, "Best For", formatList(evt.best_for, 4));

      pushFeature(amenities, <FaStar />, "Application Speed", spd.application_speed);
      pushFeature(amenities, <FaUsers />, "Parallel Artists", spd.parallel_artists_available);
      pushFeature(amenities, <FaCalendarAlt />, "Multiple Events Handling", spd.multiple_events_handling);

      pushFeature(amenities, <FaMapMarkerAlt />, "Travel Charges", prc.travel_charges);
      pushFeature(amenities, <FaStar />, "Stay Requirement", prc.stay_requirement);
      pushFeature(amenities, <FaStar />, "Min Booking Value", prc.minimum_booking_value);

      pushFeature(amenities, <FaStar />, "Advance Required", wf.advance_required);
      pushFeature(amenities, <FaStar />, "Advance Percentage", wf.advance_percentage);
      pushFeature(amenities, <FaStar />, "Booking Timeline", wf.booking_timeline);
      pushFeature(amenities, <FaStar />, "Cancellation Policy", wf.cancellation_policy);

      const ptag = mehndiArtistMaster.portfolio_tagging || {};
      pushFeature(amenities, <FaStar />, "Portfolio Tags", ptag.tags);
      pushFeature(amenities, <FaStar />, "Portfolio Notes", ptag.notes);
    }

    // --- FLORIST MASTER ATTRIBUTES ---
    if (floristMaster && Object.keys(floristMaster).length > 0) {
      const id = floristMaster.identity || {};
      const srv = floristMaster.services_offered || {};
      const core = floristMaster.core_intelligence || {};
      const tech = floristMaster.technical || {};
      const prc = floristMaster.pricing || {};
      const scale = floristMaster.scale_capacity || {};
      const wf = floristMaster.workflow || {};
      const ptag = floristMaster.portfolio_tagging || {};

      pushFeature(amenities, <FaStar />, "Vendor Type", id.vendor_type);
      pushFeature(amenities, <FaMapMarkerAlt />, "Service Presence", formatList(id.service_presence, 3));
      pushFeature(amenities, <FaStar />, "Store Presence", formatList(id.store_presence, 3));
      pushFeature(amenities, <FaStar />, "Years of Experience", id.years_of_experience);
      pushFeature(amenities, <FaStar />, "Specialization", formatList(id.specialization, 5));

      pushFeature(amenities, <FaStar />, "Service Types", formatList(srv.service_types, 4));
      pushFeature(amenities, <FaStar />, "Customization", srv.customization_available);
      pushFeature(amenities, <FaStar />, "Same Day Delivery", srv.same_day_delivery);
      pushFeature(amenities, <FaStar />, "Subscription Services", srv.subscription_services);
      pushFeature(amenities, <FaUsers />, "Bulk Orders", srv.bulk_order_handling);
      pushFeature(amenities, <FaStar />, "Event Setup", srv.event_setup_support);
      pushFeature(amenities, <FaStar />, "Packaging", formatList(srv.packaging_options, 3));

      pushFeature(amenities, <FaStar />, "Flower Types", formatList(core.flower_types_available, 7));
      pushFeature(amenities, <FaStar />, "Usage Types", formatList(core.usage_types, 6));
      pushFeature(amenities, <FaStar />, "Fragrance", core.fragrance_level);
      pushFeature(amenities, <FaStar />, "Longevity", core.longevity_type);
      pushFeature(amenities, <FaStar />, "Color Palette", formatList(core.color_palette, 6));
      pushFeature(amenities, <FaCalendarAlt />, "Seasonal Availability", core.seasonal_availability);

      pushFeature(amenities, <FaStar />, "Storage", tech.storage_facility);
      pushFeature(amenities, <FaStar />, "Freshness Guarantee", tech.flower_freshness_guarantee);
      pushFeature(amenities, <FaStar />, "Sourcing", formatList(tech.sourcing_type, 3));
      pushFeature(amenities, <FaStar />, "Arrangements", formatList(tech.arrangement_types, 4));
      pushFeature(amenities, <FaStar />, "Eco-Friendly", tech.eco_friendly_options);

      pushFeature(amenities, <FaStar />, "Price Range", prc.price_range);
      pushFeature(amenities, <FaStar />, "Pricing Model", prc.pricing_model);
      pushFeature(amenities, <FaStar />, "Delivery Charges", prc.delivery_charges);
      pushFeature(amenities, <FaStar />, "Setup Charges", prc.setup_charges);
      pushFeature(amenities, <FaStar />, "Bulk Discounts", prc.bulk_discounts);

      pushFeature(amenities, <FaStar />, "Daily Order Capacity", scale.daily_order_capacity);
      pushFeature(amenities, <FaCalendarAlt />, "Event Capacity", scale.event_handling_capacity);
      pushFeature(amenities, <FaUsers />, "Team Size", scale.team_size);

      pushFeature(amenities, <FaStar />, "Advance Booking", wf.advance_booking_required);
      pushFeature(amenities, <FaCalendarAlt />, "Booking Window", wf.booking_window);
      pushFeature(amenities, <FaStar />, "Customization Approval", wf.customization_approval_process);
      pushFeature(amenities, <FaStar />, "Delivery Time Slots", wf.delivery_time_slots);
      pushFeature(amenities, <FaStar />, "Payment Modes", formatList(wf.payment_modes, 4));
      pushFeature(amenities, <FaStar />, "Advance Payment", wf.advance_payment_percentage);

      pushFeature(amenities, <FaStar />, "Style Tags", formatList(ptag.style_tags, 5));
      pushFeature(amenities, <FaUsers />, "Audience Tags", formatList(ptag.audience_tags, 4));
      pushFeature(amenities, <FaStar />, "Usage Tags", formatList(ptag.usage_tags, 4));
      pushFeature(amenities, <FaStar />, "Price Segment", ptag.price_segment_tags);
    }

    // --- PANDIT MASTER ATTRIBUTES ---
    if (panditMaster && Object.keys(panditMaster).length > 0) {
      const id = panditMaster.identity || {};
      const srv = panditMaster.services_offered || {};
      const core = panditMaster.core_intelligence || {};
      const tech = panditMaster.technical || {};
      const prc = panditMaster.pricing || {};
      const scale = panditMaster.scale_capacity || {};
      const wf = panditMaster.workflow || {};
      const ptag = panditMaster.portfolio_tagging || {};

      pushFeature(amenities, <FaStar />, "Vendor Type", id.vendor_type);
      pushFeature(amenities, <FaStar />, "Pandit Name", id.pandit_name);
      pushFeature(amenities, <FaMapMarkerAlt />, "Service Presence", formatList(id.service_presence, 4));
      pushFeature(amenities, <FaMapMarkerAlt />, "City Base", id.city_base);
      pushFeature(amenities, <FaStar />, "Languages", formatList(id.languages_spoken, 5));
      pushFeature(amenities, <FaStar />, "Years of Experience", id.years_of_experience);
      pushFeature(amenities, <FaStar />, "Tradition", formatList(id.religious_tradition, 4));

      pushFeature(amenities, <FaStar />, "Ceremonies", formatList(srv.ceremony_types, 5));
      pushFeature(amenities, <FaStar />, "Destination Wedding", srv.destination_wedding_services);
      pushFeature(amenities, <FaStar />, "Virtual Ceremony", srv.virtual_ceremony_support);
      pushFeature(amenities, <FaStar />, "Ritual Explanation", srv.ritual_explanation_provided);
      pushFeature(amenities, <FaStar />, "Custom Rituals", srv.customized_rituals);
      pushFeature(amenities, <FaStar />, "Samagri", srv.samagri_provided);
      pushFeature(amenities, <FaUsers />, "Assistant Pandits", srv.assistant_pandits_included);

      pushFeature(amenities, <FaCalendarAlt />, "Ritual Duration", core.ritual_duration_options);
      pushFeature(amenities, <FaStar />, "Complexity", core.ritual_complexity_level);
      pushFeature(amenities, <FaStar />, "Muhurat Guidance", core.muhurat_guidance_provided);
      pushFeature(amenities, <FaStar />, "Horoscope Matching", core.horoscope_matching);
      pushFeature(amenities, <FaStar />, "Language Preference", formatList(core.ritual_language_preference, 3));
      pushFeature(amenities, <FaStar />, "Havan Included", core.fire_ritual_havan_included);
      pushFeature(amenities, <FaStar />, "Interfaith Ceremonies", core.interfaith_custom_ceremonies);

      pushFeature(amenities, <FaStar />, "Audio Setup", tech.audio_setup_requirement);
      pushFeature(amenities, <FaStar />, "Mic Usage", tech.microphone_usage);
      pushFeature(amenities, <FaStar />, "Samagri List Advance", tech.samagri_list_provided_in_advance);
      pushFeature(amenities, <FaCalendarAlt />, "Setup Time", tech.setup_time_required);
      pushFeature(amenities, <FaStar />, "Dress Code", tech.dress_code_provided);
      pushFeature(amenities, <FaStar />, "Ritual Booklet", tech.documentation_ritual_booklet);

      pushFeature(amenities, <FaStar />, "Price Range", prc.price_range);
      pushFeature(amenities, <FaStar />, "Pricing Model", prc.pricing_model);
      pushFeature(amenities, <FaMapMarkerAlt />, "Travel Charges", prc.travel_charges);
      pushFeature(amenities, <FaStar />, "Samagri Charges", prc.samagri_charges);
      pushFeature(amenities, <FaStar />, "Dakshina", prc.dakshina_flexibility);

      pushFeature(amenities, <FaCalendarAlt />, "Events Per Day", scale.events_per_day);
      pushFeature(amenities, <FaUsers />, "Team Size", scale.team_size);
      pushFeature(amenities, <FaMapMarkerAlt />, "Multi-Location", scale.multi_location_handling);

      pushFeature(amenities, <FaStar />, "Advance Booking", wf.advance_booking_required);
      pushFeature(amenities, <FaCalendarAlt />, "Booking Window", wf.booking_window);
      pushFeature(amenities, <FaStar />, "Pre-consultation", wf.pre_ceremony_consultation);
      pushFeature(amenities, <FaStar />, "Customization Discussion", wf.ritual_customization_discussion);
      pushFeature(amenities, <FaStar />, "Arrival Timing", wf.arrival_timing);
      pushFeature(amenities, <FaStar />, "Payment Modes", formatList(wf.payment_modes, 4));
      pushFeature(amenities, <FaStar />, "Advance Payment", wf.advance_payment_percentage);

      pushFeature(amenities, <FaStar />, "Style Tags", formatList(ptag.style_tags, 4));
      pushFeature(amenities, <FaUsers />, "Audience Tags", formatList(ptag.audience_tags, 4));
      pushFeature(amenities, <FaStar />, "Usage Tags", formatList(ptag.usage_tags, 4));
      pushFeature(amenities, <FaStar />, "Price Segment", ptag.price_segment_tags);
    }

    // --- DJ MASTER ATTRIBUTES ---
    if (djMaster && Object.keys(djMaster).length > 0) {
      // Normalize: support both nested format (djMaster.identity.brand_name)
      // and flat legacy format (djMaster.brand_name) saved by earlier versions.
      const id = Object.keys(djMaster.identity || {}).length > 0
        ? djMaster.identity
        : {
          brand_name: djMaster.brand_name,
          primary_city: djMaster.primary_city,
          service_cities: djMaster.service_cities,
          vendor_type: djMaster.vendor_type,
          years_of_experience: djMaster.years_of_experience,
          travel_policy: djMaster.travel_policy,
          languages: djMaster.languages,
        };
      const srv = Object.keys(djMaster.services || {}).length > 0
        ? djMaster.services
        : {
          event_types: djMaster.event_types,
          dj_formats: djMaster.dj_formats,
          additional_services: djMaster.additional_services,
        };
      const core = Object.keys(djMaster.core_intelligence || {}).length > 0
        ? djMaster.core_intelligence
        : {
          music_genres: djMaster.music_genres,
          crowd_handling: djMaster.crowd_handling,
          specialization_style: djMaster.specialization_style,
          live_mixing_capability: djMaster.live_mixing_capability,
          custom_playlist_support: djMaster.custom_playlist_support,
          song_request_handling: djMaster.song_request_handling,
          entry_sync: djMaster.entry_sync,
          baraat_dj_setup: djMaster.baraat_dj_setup,
          backup_dj_available: djMaster.backup_dj_available,
        };
      const tech = Object.keys(djMaster.technical_setup || {}).length > 0
        ? djMaster.technical_setup
        : {
          equipment_ownership: djMaster.equipment_ownership,
          sound_setup_capability: djMaster.sound_setup_capability,
          lighting_setup: djMaster.lighting_setup,
          console_types: djMaster.console_types,
          power_backup: djMaster.power_backup,
          setup_time_required: djMaster.setup_time_required,
          technical_team_size: djMaster.technical_team_size,
        };
      const prc = Object.keys(djMaster.pricing || {}).length > 0
        ? djMaster.pricing
        : {
          pricing_model: djMaster.pricing_model,
          starting_price_range: djMaster.starting_price_range,
          includes: djMaster.includes,
          addon_charges: djMaster.addon_charges,
          peak_season_pricing: djMaster.peak_season_pricing,
          negotiation_flexibility: djMaster.negotiation_flexibility,
        };
      const scale = Object.keys(djMaster.scale_capacity || {}).length > 0
        ? djMaster.scale_capacity
        : {
          max_events_per_day: djMaster.max_events_per_day,
          concurrent_events: djMaster.concurrent_events,
          team_multi_event: djMaster.team_multi_event,
        };
      const wf = Object.keys(djMaster.workflow || {}).length > 0
        ? djMaster.workflow
        : {
          advance_booking_time: djMaster.advance_booking_time,
          booking_advance_percent: djMaster.booking_advance_percent,
          cancellation_policy: djMaster.cancellation_policy,
          coordination_mode: djMaster.coordination_mode,
          pre_event_planning_call: djMaster.pre_event_planning_call,
        };
      const ptag = Object.keys(djMaster.portfolio_tagging || {}).length > 0
        ? djMaster.portfolio_tagging
        : {
          event_mood_tags: djMaster.event_mood_tags,
          music_style_tags: djMaster.music_style_tags,
          celebrity_big_event_experience: djMaster.celebrity_big_event_experience,
        };

      pushFeature(amenities, <FaStar />, "Vendor Type", id.vendor_type);
      pushFeature(amenities, <FaStar />, "Brand Name", id.brand_name);
      pushFeature(amenities, <FaMapMarkerAlt />, "Primary City", id.primary_city);
      pushFeature(amenities, <FaMapMarkerAlt />, "Service Cities", formatList(id.service_cities, 5));
      pushFeature(amenities, <FaStar />, "Years of Experience", id.years_of_experience);
      pushFeature(amenities, <FaMapMarkerAlt />, "Travel Policy", id.travel_policy);
      pushFeature(amenities, <FaStar />, "Languages Comfortable", formatList(id.languages, 5));

      pushFeature(amenities, <FaCalendarAlt />, "Event Types Covered", formatList(srv.event_types, 6));
      pushFeature(amenities, <FaStar />, "DJ Formats", formatList(srv.dj_formats, 4));
      pushFeature(amenities, <FaStar />, "Additional Services", formatList(srv.additional_services, 5));

      pushFeature(amenities, <FaStar />, "Music Genres", formatList(core.music_genres, 6));
      pushFeature(amenities, <FaUsers />, "Crowd Handling Capability", core.crowd_handling);
      pushFeature(amenities, <FaStar />, "Specialization Style", core.specialization_style);
      pushFeature(amenities, <FaStar />, "Live Mixing Capability", core.live_mixing_capability);
      pushFeature(amenities, <FaStar />, "Custom Playlist Support", core.custom_playlist_support);
      pushFeature(amenities, <FaStar />, "Song Request Handling", core.song_request_handling);
      pushFeature(amenities, <FaStar />, "Entry & Performance Sync", formatList(core.entry_sync, 4));
      pushFeature(amenities, <FaStar />, "Baraat DJ Setup", core.baraat_dj_setup);
      pushFeature(amenities, <FaStar />, "Backup DJ Available", core.backup_dj_available);

      pushFeature(amenities, <FaStar />, "Equipment Ownership", tech.equipment_ownership);
      pushFeature(amenities, <FaStar />, "Sound Setup Capability", tech.sound_setup_capability);
      pushFeature(amenities, <FaStar />, "Lighting Setup", tech.lighting_setup);
      pushFeature(amenities, <FaStar />, "Console Types", formatList(tech.console_types, 4));
      pushFeature(amenities, <FaStar />, "Power Backup", tech.power_backup);
      pushFeature(amenities, <FaCalendarAlt />, "Setup Time Required", tech.setup_time_required);
      pushFeature(amenities, <FaUsers />, "Technical Team Size", tech.technical_team_size);

      pushFeature(amenities, <FaStar />, "Pricing Model", prc.pricing_model);
      pushFeature(amenities, <FaStar />, "Starting Price Range", prc.starting_price_range);
      pushFeature(amenities, <FaStar />, "Includes", formatList(prc.includes, 4));
      pushFeature(amenities, <FaStar />, "Add-on Charges", formatList(prc.addon_charges, 4));
      pushFeature(amenities, <FaStar />, "Peak Season Pricing", prc.peak_season_pricing);
      pushFeature(amenities, <FaStar />, "Negotiation Flexibility", prc.negotiation_flexibility);

      pushFeature(amenities, <FaCalendarAlt />, "Max Events Per Day", scale.max_events_per_day);
      pushFeature(amenities, <FaStar />, "Concurrent Events", scale.concurrent_events);
      pushFeature(amenities, <FaUsers />, "Team-based Multi-event", scale.team_multi_event);

      pushFeature(amenities, <FaCalendarAlt />, "Advance Booking", wf.advance_booking_time);
      pushFeature(amenities, <FaStar />, "Booking Advance Percentage", wf.booking_advance_percent);
      pushFeature(amenities, <FaStar />, "Cancellation Policy", wf.cancellation_policy);
      pushFeature(amenities, <FaStar />, "Client Coordination Mode", wf.coordination_mode);
      pushFeature(amenities, <FaStar />, "Pre-event Planning Call", wf.pre_event_planning_call);

      pushFeature(amenities, <FaStar />, "Event Mood Tags", formatList(ptag.event_mood_tags, 5));
      pushFeature(amenities, <FaStar />, "Music Style Tags", formatList(ptag.music_style_tags, 5));
      pushFeature(amenities, <FaStar />, "Celebrity/Big Event Experience", ptag.celebrity_big_event_experience);
    }

    // --- SANGEET CHOREOGRAPHER MASTER ATTRIBUTES ---
    if (sangeetChoreographerMaster && Object.keys(sangeetChoreographerMaster).length > 0) {
      const id = sangeetChoreographerMaster.identity || {};
      const srv = sangeetChoreographerMaster.services || {};
      const core = sangeetChoreographerMaster.core_intelligence || {};
      const rehearsal = sangeetChoreographerMaster.rehearsal_logistics || {};
      const exec = sangeetChoreographerMaster.performance_execution || {};
      const prc = sangeetChoreographerMaster.pricing || {};
      const scale = sangeetChoreographerMaster.scale_capacity || {};
      const wf = sangeetChoreographerMaster.workflow || {};
      const ptag = sangeetChoreographerMaster.portfolio_tagging || {};

      pushFeature(amenities, <FaStar />, "Vendor Type", id.vendor_type);
      pushFeature(amenities, <FaStar />, "Brand Name", id.brand_name);
      pushFeature(amenities, <FaMapMarkerAlt />, "Primary City", id.primary_city);
      pushFeature(amenities, <FaMapMarkerAlt />, "Service Cities", formatList(id.service_cities, 5));
      pushFeature(amenities, <FaStar />, "Years of Experience", id.years_of_experience);
      pushFeature(amenities, <FaMapMarkerAlt />, "Travel Policy", id.travel_policy);
      pushFeature(amenities, <FaStar />, "Languages Comfortable", formatList(id.languages, 5));

      pushFeature(amenities, <FaCalendarAlt />, "Event Types Covered", formatList(srv.event_types, 6));
      pushFeature(amenities, <FaStar />, "Dance Formats", formatList(srv.dance_formats, 5));
      pushFeature(amenities, <FaStar />, "Special Offerings", formatList(srv.special_offerings, 5));

      pushFeature(amenities, <FaStar />, "Dance Styles", formatList(core.dance_styles, 6));
      pushFeature(amenities, <FaStar />, "Skill Level Handling", core.skill_level_handling);
      pushFeature(amenities, <FaUsers />, "Age Group Handling", formatList(core.age_group_handling, 4));
      pushFeature(amenities, <FaUsers />, "Max Participants", core.max_participants_per_act);
      pushFeature(amenities, <FaStar />, "Story-based Choreography", core.story_based_choreography);
      pushFeature(amenities, <FaStar />, "Customization Level", core.customization_level);
      pushFeature(amenities, <FaStar />, "Music Selection Support", core.music_selection_support);
      pushFeature(amenities, <FaStar />, "Rehearsal Mode", core.rehearsal_mode);
      pushFeature(amenities, <FaStar />, "Performance Polish Level", core.performance_polish_level);

      pushFeature(amenities, <FaCalendarAlt />, "Rehearsal Sessions per Act", rehearsal.rehearsal_sessions_per_act);
      pushFeature(amenities, <FaCalendarAlt />, "Session Duration", rehearsal.session_duration);
      pushFeature(amenities, <FaMapMarkerAlt />, "Practice Location", rehearsal.practice_location);
      pushFeature(amenities, <FaMapMarkerAlt />, "Travel for Practice", rehearsal.travel_for_practice);
      pushFeature(amenities, <FaStar />, "Assistant Availability", rehearsal.assistant_availability);
      pushFeature(amenities, <FaStar />, "Last-minute Practice Support", rehearsal.last_minute_practice_support);

      pushFeature(amenities, <FaStar />, "On-event Presence", exec.on_event_presence);
      pushFeature(amenities, <FaStar />, "Backstage Coordination", exec.backstage_coordination);
      pushFeature(amenities, <FaStar />, "Entry & Transition Planning", exec.entry_transition_planning);
      pushFeature(amenities, <FaStar />, "Music Editing & Mixing", exec.music_editing_mixing);
      pushFeature(amenities, <FaStar />, "Props Support", exec.props_support);
      pushFeature(amenities, <FaStar />, "Costume Guidance", exec.costume_guidance);

      pushFeature(amenities, <FaStar />, "Pricing Model", prc.pricing_model);
      pushFeature(amenities, <FaStar />, "Starting Price Range", prc.starting_price_range);
      pushFeature(amenities, <FaStar />, "Includes", formatList(prc.includes, 4));
      pushFeature(amenities, <FaStar />, "Add-on Charges", formatList(prc.addon_charges, 4));
      pushFeature(amenities, <FaStar />, "Peak Season Pricing", prc.peak_season_pricing);
      pushFeature(amenities, <FaStar />, "Negotiation Flexibility", prc.negotiation_flexibility);

      pushFeature(amenities, <FaCalendarAlt />, "Max Events Per Day", scale.max_events_per_day);
      pushFeature(amenities, <FaStar />, "Parallel Event Handling", scale.parallel_event_handling);
      pushFeature(amenities, <FaUsers />, "Team Size", scale.team_size);

      pushFeature(amenities, <FaCalendarAlt />, "Advance Booking", wf.advance_booking_time);
      pushFeature(amenities, <FaStar />, "Booking Advance Percentage", wf.booking_advance_percent);
      pushFeature(amenities, <FaStar />, "Cancellation Policy", wf.cancellation_policy);
      pushFeature(amenities, <FaStar />, "Client Coordination Mode", wf.coordination_mode);
      pushFeature(amenities, <FaStar />, "Trial Session Availability", wf.trial_session_availability);

      pushFeature(amenities, <FaStar />, "Performance Style Tags", formatList(ptag.performance_style_tags, 5));
      pushFeature(amenities, <FaStar />, "Event Scale Tags", formatList(ptag.event_scale_tags, 5));
      pushFeature(amenities, <FaStar />, "Choreography Style Tags", formatList(ptag.choreography_style_tags, 5));
    }

    // --- WEDDING ENTERTAINER MASTER ATTRIBUTES ---
    if (weddingEntertainerMaster && Object.keys(weddingEntertainerMaster).length > 0) {
      const id = weddingEntertainerMaster.identity || {};
      const srv = weddingEntertainerMaster.services || {};
      const core = weddingEntertainerMaster.core_intelligence || {};
      const tech = weddingEntertainerMaster.technical_setup || {};
      const prc = weddingEntertainerMaster.pricing || {};
      const scale = weddingEntertainerMaster.scale_capacity || {};
      const wf = weddingEntertainerMaster.workflow || {};
      const ptag = weddingEntertainerMaster.portfolio_tagging || {};

      pushFeature(amenities, <FaStar />, "Vendor Type", id.vendor_type);
      pushFeature(amenities, <FaStar />, "Brand Name", id.brand_name);
      pushFeature(amenities, <FaMapMarkerAlt />, "Primary City", id.primary_city);
      pushFeature(amenities, <FaMapMarkerAlt />, "Service Cities", formatList(id.service_cities, 5));
      const performerCat = id.performer_category === "Other" ? id.performer_category_other : id.performer_category;
      pushFeature(amenities, <FaStar />, "Performer Category", performerCat);
      pushFeature(amenities, <FaStar />, "Years of Experience", id.years_of_experience);
      pushFeature(amenities, <FaMapMarkerAlt />, "Travel Policy", id.travel_policy);
      pushFeature(amenities, <FaStar />, "Languages Comfortable", formatList(id.languages, 5));

      pushFeature(amenities, <FaCalendarAlt />, "Event Types Covered", formatList(srv.event_types, 6));
      pushFeature(amenities, <FaStar />, "Performance Types", formatList(srv.performance_types, 5));
      pushFeature(amenities, <FaUsers />, "Audience Type Handling", formatList(srv.audience_type_handling, 5));

      pushFeature(amenities, <FaStar />, "Engagement Style", core.engagement_style);
      pushFeature(amenities, <FaStar />, "Performance Duration", core.performance_duration);
      pushFeature(amenities, <FaStar />, "Performance Slots", core.performance_slots);
      pushFeature(amenities, <FaStar />, "Content Customization", core.content_customization);
      pushFeature(amenities, <FaStar />, "Theme Compatibility", formatList(core.theme_compatibility, 5));
      pushFeature(amenities, <FaStar />, "Energy Level", core.energy_level);
      pushFeature(amenities, <FaStar />, "Stage Requirement", core.stage_requirement);
      pushFeature(amenities, <FaStar />, "Sound Requirement", core.sound_requirement);
      pushFeature(amenities, <FaStar />, "Lighting Requirement", core.lighting_requirement);

      pushFeature(amenities, <FaStar />, "Equipment Ownership", tech.equipment_ownership);
      pushFeature(amenities, <FaCalendarAlt />, "Setup Time", tech.setup_time);
      pushFeature(amenities, <FaUsers />, "Team Size", tech.team_size);
      pushFeature(amenities, <FaStar />, "Power Requirement", tech.power_requirement);
      pushFeature(amenities, <FaStar />, "Green Room Requirement", tech.green_room_requirement);
      pushFeature(amenities, <FaStar />, "Outdoor Suitability", tech.outdoor_suitability);
      pushFeature(amenities, <FaStar />, "Indoor Suitability", tech.indoor_suitability);

      pushFeature(amenities, <FaStar />, "Pricing Model", prc.pricing_model);
      pushFeature(amenities, <FaStar />, "Starting Price Range", prc.starting_price_range);
      pushFeature(amenities, <FaStar />, "Includes", formatList(prc.includes, 4));
      pushFeature(amenities, <FaStar />, "Add-ons", formatList(prc.addons, 4));
      pushFeature(amenities, <FaStar />, "Peak Season Pricing", prc.peak_pricing);
      pushFeature(amenities, <FaStar />, "Negotiation Flexibility", prc.negotiation_flexibility);

      pushFeature(amenities, <FaUsers />, "Audience Size Capability", scale.audience_size_capability);
      pushFeature(amenities, <FaStar />, "Multiple Event Handling", scale.multiple_event_handling);
      pushFeature(amenities, <FaStar />, "Parallel Performances", scale.parallel_performances);

      pushFeature(amenities, <FaCalendarAlt />, "Advance Booking", wf.advance_booking_time);
      pushFeature(amenities, <FaStar />, "Booking Advance Percentage", wf.booking_advance_percent);
      pushFeature(amenities, <FaStar />, "Cancellation Policy", wf.cancellation_policy);
      pushFeature(amenities, <FaStar />, "Client Coordination Mode", wf.coordination_mode);
      pushFeature(amenities, <FaStar />, "Pre-event Briefing", wf.pre_event_briefing);

      pushFeature(amenities, <FaStar />, "Entertainment Tags", formatList(ptag.entertainment_tags, 5));
      pushFeature(amenities, <FaStar />, "Performer Tags", formatList(ptag.performer_tags, 5));
      pushFeature(amenities, <FaStar />, "Event Fit Tags", formatList(ptag.event_fit_tags, 5));
    }

    // --- PRE-WEDDING LOCATION MASTER ATTRIBUTES ---
    if (preWeddingLocationMaster && Object.keys(preWeddingLocationMaster).length > 0) {
      const id = preWeddingLocationMaster.identity || {};
      const srv = preWeddingLocationMaster.services || {};
      const core = preWeddingLocationMaster.core_intelligence || {};
      const tech = preWeddingLocationMaster.technical || {};
      const prc = preWeddingLocationMaster.pricing || {};
      const scale = preWeddingLocationMaster.scale_capacity || {};
      const wf = preWeddingLocationMaster.workflow || {};
      const ptag = preWeddingLocationMaster.portfolio_tagging || {};

      pushFeature(amenities, <FaStar />, "Location Type", id.location_type);
      pushFeature(amenities, <FaStar />, "Location Name", id.location_name);
      pushFeature(amenities, <FaStar />, "Ownership Type", id.ownership_type);
      pushFeature(amenities, <FaMapMarkerAlt />, "City", id.city);
      pushFeature(amenities, <FaStar />, "Accessibility", id.accessibility_type);
      pushFeature(amenities, <FaStar />, "Years of Operation", id.years_of_operation);

      pushFeature(amenities, <FaCalendarAlt />, "Booking Type", formatList(srv.booking_type, 4));
      pushFeature(amenities, <FaStar />, "Photography Allowed", srv.photography_allowed);
      pushFeature(amenities, <FaStar />, "Videography Allowed", srv.videography_allowed);
      pushFeature(amenities, <FaStar />, "Drone Usage Allowed", srv.drone_usage_allowed);
      pushFeature(amenities, <FaStar />, "Permission Handling", srv.permission_handling);
      pushFeature(amenities, <FaStar />, "Changing Rooms Available", srv.changing_rooms_available);
      pushFeature(amenities, <FaStar />, "Makeup Room Available", srv.makeup_room_available);
      pushFeature(amenities, <FaStar />, "Props Available", formatList(srv.props_available, 5));
      pushFeature(amenities, <FaStar />, "Power Supply Available", srv.power_supply_available);

      pushFeature(amenities, <FaStar />, "Location Themes", formatList(core.location_themes, 5));
      pushFeature(amenities, <FaCalendarAlt />, "Best Shoot Time", formatList(core.best_shoot_time, 4));
      pushFeature(amenities, <FaStar />, "Lighting Conditions", core.lighting_conditions);
      pushFeature(amenities, <FaStar />, "Weather Suitability", formatList(core.weather_suitability, 4));
      pushFeature(amenities, <FaStar />, "Privacy Level", core.privacy_level);
      pushFeature(amenities, <FaStar />, "Noise Level", core.noise_level);

      pushFeature(amenities, <FaStar />, "Area Size", tech.area_size);
      pushFeature(amenities, <FaStar />, "Shooting Spots", tech.shooting_spots);
      pushFeature(amenities, <FaStar />, "Indoor Availability", tech.indoor_availability);
      pushFeature(amenities, <FaStar />, "Outdoor Availability", tech.outdoor_availability);
      pushFeature(amenities, <FaStar />, "Terrain Type", formatList(tech.terrain_type, 5));
      pushFeature(amenities, <FaStar />, "Electric Backup", tech.electric_backup);

      pushFeature(amenities, <FaStar />, "Price Range", prc.price_range);
      pushFeature(amenities, <FaStar />, "Pricing Model", prc.pricing_model);
      pushFeature(amenities, <FaStar />, "Outfits on Rent", prc.outfits_on_rent);
      pushFeature(amenities, <FaStar />, "Security Deposit Required", prc.security_deposit_required);
      pushFeature(amenities, <FaStar />, "Permit Charges", prc.permit_charges);
      pushFeature(amenities, <FaStar />, "Cancellation Policy", prc.cancellation_policy);

      pushFeature(amenities, <FaUsers />, "Max Crew Size", scale.max_crew_size);
      pushFeature(amenities, <FaUsers />, "Simultaneous Shoots", scale.simultaneous_shoots);
      pushFeature(amenities, <FaParking />, "Parking Capacity", scale.parking_capacity);

      pushFeature(amenities, <FaCalendarAlt />, "Advance Booking", wf.advance_booking_required);
      pushFeature(amenities, <FaCalendarAlt />, "Booking Window", wf.booking_window);
      pushFeature(amenities, <FaStar />, "Time Slot Allocation", wf.time_slot_allocation);
      pushFeature(amenities, <FaStar />, "Onsite Coordinator", wf.onsite_coordinator_available);
      pushFeature(amenities, <FaStar />, "Payment Modes", formatList(wf.payment_modes, 4));
      pushFeature(amenities, <FaStar />, "Advance Payment", wf.advance_payment_percentage);

      pushFeature(amenities, <FaStar />, "Visual Style Tags", formatList(ptag.visual_style_tags, 5));
      pushFeature(amenities, <FaStar />, "Audience Tags", formatList(ptag.audience_tags, 4));
      pushFeature(amenities, <FaStar />, "Usage Tags", formatList(ptag.usage_tags, 4));
      pushFeature(amenities, <FaStar />, "Price Segment", ptag.price_segment_tags);
    }

    // --- PRE-WEDDING PHOTOGRAPHER MASTER ATTRIBUTES ---
    if (preWeddingPhotographerMaster && Object.keys(preWeddingPhotographerMaster).length > 0) {
      const id = preWeddingPhotographerMaster.identity || {};
      const srv = preWeddingPhotographerMaster.services || {};
      const core = preWeddingPhotographerMaster.core_intelligence || {};
      const tech = preWeddingPhotographerMaster.technical || {};
      const prc = preWeddingPhotographerMaster.pricing || {};
      const scale = preWeddingPhotographerMaster.scale_capacity || {};
      const wf = preWeddingPhotographerMaster.workflow || {};
      const ptag = preWeddingPhotographerMaster.portfolio_tagging || {};

      pushFeature(amenities, <FaStar />, "Vendor Type", id.vendor_type);
      pushFeature(amenities, <FaStar />, "Brand Name", id.brand_name);
      pushFeature(amenities, <FaMapMarkerAlt />, "Service Presence", formatList(id.service_presence, 4));
      pushFeature(amenities, <FaMapMarkerAlt />, "City", id.city);
      pushFeature(amenities, <FaStar />, "Years of Experience", id.years_of_experience);
      pushFeature(amenities, <FaUsers />, "Team Size", id.team_size);

      pushFeature(amenities, <FaStar />, "Shoot Types", formatList(srv.shoot_types, 4));
      pushFeature(amenities, <FaStar />, "Photography Coverage", formatList(srv.photography_coverage, 4));
      pushFeature(amenities, <FaStar />, "Drone Shooting", srv.drone_shooting);
      pushFeature(amenities, <FaStar />, "Cinematic Videography", srv.cinematic_videography);
      pushFeature(amenities, <FaStar />, "Concept Planning Support", srv.concept_planning_support);
      pushFeature(amenities, <FaStar />, "Location Assistance", srv.location_assistance);
      pushFeature(amenities, <FaStar />, "Styling Assistance", srv.styling_assistance);
      pushFeature(amenities, <FaStar />, "Outfit Coordination Support", srv.outfit_coordination_support);
      pushFeature(amenities, <FaStar />, "Travel Included", srv.travel_included);

      pushFeature(amenities, <FaStar />, "Photography Style", formatList(core.photography_style, 4));
      pushFeature(amenities, <FaStar />, "Shoot Style Themes", formatList(core.shoot_style_themes, 4));
      pushFeature(amenities, <FaStar />, "Lighting Style", formatList(core.lighting_style, 4));
      pushFeature(amenities, <FaStar />, "Editing Style", formatList(core.editing_style, 4));
      pushFeature(amenities, <FaStar />, "Reel Style Capability", formatList(core.reel_style_capability, 4));
      pushFeature(amenities, <FaCalendarAlt />, "Best Time Preference", formatList(core.best_time_preference, 4));

      pushFeature(amenities, <FaStar />, "Camera Type", formatList(tech.camera_type, 4));
      pushFeature(amenities, <FaStar />, "Drone Equipment Level", tech.drone_equipment_level);
      pushFeature(amenities, <FaStar />, "Video Resolution", tech.video_resolution);
      pushFeature(amenities, <FaStar />, "Stabilization Equipment", formatList(tech.stabilization_equipment, 4));
      pushFeature(amenities, <FaStar />, "Audio Capture", tech.audio_capture);
      pushFeature(amenities, <FaStar />, "Backup Equipment Available", tech.backup_equipment_available);

      pushFeature(amenities, <FaStar />, "Price Range", prc.price_range);
      pushFeature(amenities, <FaStar />, "Pricing Model", prc.pricing_model);
      pushFeature(amenities, <FaStar />, "Travel Charges", prc.travel_charges);
      pushFeature(amenities, <FaStar />, "Stay Charges", prc.stay_charges);
      pushFeature(amenities, <FaStar />, "Drone Charges", prc.drone_charges);
      pushFeature(amenities, <FaStar />, "Editing Charges", prc.editing_charges);
      pushFeature(amenities, <FaStar />, "Advance Payment", prc.advance_payment_percentage);

      pushFeature(amenities, <FaCalendarAlt />, "Shoots Per Month", scale.shoots_per_month);
      pushFeature(amenities, <FaUsers />, "Simultaneous Projects", scale.simultaneous_projects);
      pushFeature(amenities, <FaUsers />, "Team Scalability", scale.team_scalability);

      pushFeature(amenities, <FaCalendarAlt />, "Booking Window", wf.booking_window);
      pushFeature(amenities, <FaCalendarAlt />, "Concept Finalization", wf.concept_finalization_timeline);
      pushFeature(amenities, <FaCalendarAlt />, "Shoot Duration Options", formatList(wf.shoot_duration_options, 4));
      pushFeature(amenities, <FaStar />, "Raw Data Delivery", wf.raw_data_delivery);
      pushFeature(amenities, <FaCalendarAlt />, "Edited Photos Delivery", wf.edited_photos_delivery_timeline);
      pushFeature(amenities, <FaCalendarAlt />, "Video Delivery Timeline", wf.video_delivery_timeline);
      pushFeature(amenities, <FaStar />, "Payment Modes", formatList(wf.payment_modes, 4));

      pushFeature(amenities, <FaStar />, "Visual Style Tags", formatList(ptag.visual_style_tags, 5));
      pushFeature(amenities, <FaStar />, "Audience Tags", formatList(ptag.audience_tags, 4));
      pushFeature(amenities, <FaStar />, "Usage Tags", formatList(ptag.usage_tags, 4));
      pushFeature(amenities, <FaStar />, "Price Segment", ptag.price_segment_tags);
    }

    // --- JEWELLERY & ACCESSORIES RENTAL MASTER ---
    if (jewelleryMaster && Object.keys(jewelleryMaster).length > 0) {
      const ji = jewelleryMaster.identity || {};
      const jpc = jewelleryMaster.product_categories || {};
      const jsd = jewelleryMaster.style_design_intelligence || {};
      const jmq = jewelleryMaster.material_quality || {};
      const jrl = jewelleryMaster.rental_logic || {};
      const jai = jewelleryMaster.availability_inventory || {};
      const jdl = jewelleryMaster.delivery_logistics || {};
      const jhq = jewelleryMaster.hygiene_quality || {};
      const jes = jewelleryMaster.event_suitability || {};
      const jwb = jewelleryMaster.workflow_booking || {};

      pushFeature(
        amenities,
        <FaStar />,
        "Experience",
        ji.years_of_experience ? `${ji.years_of_experience} years` : "",
      );
      pushFeature(amenities, <FaMapMarkerAlt />, "Cities", formatList(ji.cities, 4));
      pushFeature(amenities, <FaStar />, "Service Mode", ji.service_mode);
      pushFeature(amenities, <FaStar />, "Delivery Coverage", ji.delivery_coverage);
      pushFeature(
        amenities,
        <FaStar />,
        "Jewellery Types",
        formatList(jpc.jewellery_types_offered, 50),
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Bridal Package",
        jpc.bridal_package_available,
      );
      pushFeature(amenities, <FaStar />, "Complete Set Includes", formatList(jpc.complete_set_includes, 50));
      pushFeature(
        amenities,
        <FaStar />,
        "Jewellery Style",
        formatList(jsd.jewellery_style, 50),
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Best Known For",
        formatList(jsd.best_known_for, 50),
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Suitable For",
        formatList(jsd.suitable_for, 50),
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Outfit Matching",
        jsd.outfit_matching_support,
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Styling Consultation",
        jsd.styling_consultation,
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Base Material",
        formatList(jmq.base_material, 50),
      );
      pushFeature(amenities, <FaStar />, "Finish Quality", jmq.finish_quality);
      pushFeature(amenities, <FaStar />, "Material Type", jmq.real_vs_imitation);
      pushFeature(amenities, <FaStar />, "Rental Duration", jrl.rental_duration);
      pushFeature(amenities, <FaStar />, "Rental Price Range", jrl.rental_price_range);
      pushFeature(amenities, <FaStar />, "Security Deposit", jrl.security_deposit);
      pushFeature(
        amenities,
        <FaStar />,
        "Deposit Range",
        jrl.deposit_amount_range,
      );
      pushFeature(amenities, <FaStar />, "Late Return Charges", jrl.late_return_charges);
      pushFeature(
        amenities,
        <FaStar />,
        "Advance Booking",
        jai.advance_booking_required,
      );
      pushFeature(amenities, <FaStar />, "Inventory Size", jai.inventory_size);
      pushFeature(amenities, <FaStar />, "Multiple Pieces Available", jai.multiple_pieces_available);
      pushFeature(amenities, <FaStar />, "Availability Tracking", jai.realtime_availability_tracking);
      pushFeature(
        amenities,
        <FaStar />,
        "Home Delivery",
        jdl.home_delivery_available,
      );
      pushFeature(amenities, <FaStar />, "Pickup Required", jdl.pickup_required);
      pushFeature(amenities, <FaStar />, "Try at Home", jdl.try_at_home_service);
      pushFeature(amenities, <FaStar />, "Shipping", jdl.shipping_charges);
      pushFeature(amenities, <FaStar />, "Sanitization", jhq.sanitization_process);
      pushFeature(amenities, <FaStar />, "Damage Policy", jhq.damage_policy);
      pushFeature(
        amenities,
        <FaStar />,
        "Replacement",
        jhq.replacement_available,
      );
      pushFeature(
        amenities,
        <FaStar />,
        "Functions",
        formatList(jes.functions_suitable_for, 50),
      );
      pushFeature(amenities, <FaStar />, "Best For", formatList(jes.best_for, 50));
      pushFeature(amenities, <FaCalendarAlt />, "Advance Required", jwb.advance_required);
      pushFeature(amenities, <FaCalendarAlt />, "Advance Percentage", jwb.advance_percentage);
      pushFeature(amenities, <FaCalendarAlt />, "Cancellation", jwb.cancellation_policy);
      pushFeature(amenities, <FaCalendarAlt />, "Refund Timeline", jwb.refund_timeline);
    }

    // --- JEWELLERY RENTAL MASTER ATTRIBUTES ---
    if (jewelleryRentalMaster && Object.keys(jewelleryRentalMaster).length > 0) {
      const ji = jewelleryRentalMaster.identity || {};
      const jpc = jewelleryRentalMaster.product_categories || {};
      const jsd = jewelleryRentalMaster.style_design || {};
      const jmq = jewelleryRentalMaster.material_quality || {};
      const jrl = jewelleryRentalMaster.rental_logic || {};
      const jai = jewelleryRentalMaster.availability || {};
      const jdl = jewelleryRentalMaster.delivery_logistics || {};
      const jhq = jewelleryRentalMaster.hygiene_quality || {};
      const jes = jewelleryRentalMaster.event_suitability || {};
      const jwb = jewelleryRentalMaster.workflow_booking || {};

      pushFeature(amenities, <FaStar />, "Experience", ji.years_of_experience ? `${ji.years_of_experience} years` : "");
      pushFeature(amenities, <FaMapMarkerAlt />, "City", ji.city);
      pushFeature(amenities, <FaStar />, "Service Mode", ji.service_mode);
      pushFeature(amenities, <FaStar />, "Delivery Coverage", ji.delivery_coverage);

      pushFeature(amenities, <FaStar />, "Jewellery Types", formatList(jpc.jewellery_types, 50));
      pushFeature(amenities, <FaStar />, "Bridal Package", jpc.bridal_package);
      pushFeature(amenities, <FaStar />, "Complete Set Includes", formatList(jpc.set_includes, 50));

      pushFeature(amenities, <FaStar />, "Jewellery Style", formatList(jsd.jewellery_style, 50));
      pushFeature(amenities, <FaStar />, "Best Known For", formatList(jsd.best_known_for, 50));
      pushFeature(amenities, <FaStar />, "Suitable For", formatList(jsd.suitable_for, 50));
      pushFeature(amenities, <FaStar />, "Outfit Matching", jsd.outfit_matching_support);
      pushFeature(amenities, <FaStar />, "Styling Consultation", jsd.styling_consultation);

      pushFeature(amenities, <FaStar />, "Base Material", formatList(jmq.base_material, 50));
      pushFeature(amenities, <FaStar />, "Finish Quality", jmq.finish_quality);
      pushFeature(amenities, <FaStar />, "Material Type", jmq.real_vs_imitation);

      pushFeature(amenities, <FaStar />, "Rental Duration", jrl.rental_duration);
      pushFeature(amenities, <FaStar />, "Rental Price Range", jrl.rental_price_range);
      pushFeature(amenities, <FaStar />, "Security Deposit", jrl.security_deposit);
      pushFeature(amenities, <FaStar />, "Deposit Amount Range", jrl.deposit_amount_range);
      pushFeature(amenities, <FaStar />, "Late Return Charges", jrl.late_return_charges);

      pushFeature(amenities, <FaStar />, "Advance Booking", jai.advance_booking_required);
      pushFeature(amenities, <FaStar />, "Inventory Size", jai.inventory_size);
      pushFeature(amenities, <FaStar />, "Multiple Pieces Available", jai.multiple_pieces_available);
      pushFeature(amenities, <FaStar />, "Availability Tracking", jai.availability_tracking);

      pushFeature(amenities, <FaStar />, "Home Delivery", jdl.home_delivery);
      pushFeature(amenities, <FaStar />, "Pickup Required", jdl.pickup_required);
      pushFeature(amenities, <FaStar />, "Shipping Charges", jdl.shipping_charges);
      pushFeature(amenities, <FaStar />, "Try at Home", jdl.try_at_home);

      pushFeature(amenities, <FaStar />, "Sanitization Process", jhq.sanitization_process);
      pushFeature(amenities, <FaStar />, "Damage Policy", jhq.damage_policy);
      pushFeature(amenities, <FaStar />, "Replacement Available", jhq.replacement_available);

      pushFeature(amenities, <FaStar />, "Functions Suitable", formatList(jes.functions_suitable_for, 50));
      pushFeature(amenities, <FaStar />, "Best For", formatList(jes.best_for, 50));

      pushFeature(amenities, <FaCalendarAlt />, "Advance Required", jwb.advance_required);
      pushFeature(amenities, <FaCalendarAlt />, "Advance Percentage", jwb.advance_percentage);
      pushFeature(amenities, <FaCalendarAlt />, "Cancellation Policy", jwb.cancellation_policy);
      pushFeature(amenities, <FaCalendarAlt />, "Refund Timeline", jwb.refund_timeline);
    }


    // --- ACCESSORIES MASTER ATTRIBUTES ---
    if (accessoriesMaster && Object.keys(accessoriesMaster).length > 0) {
      const ai = accessoriesMaster.identity || {};
      const apc = accessoriesMaster.product_categories || {};
      const asd = accessoriesMaster.style_intelligence || {};
      const amq = accessoriesMaster.material_quality || {};
      const arl = accessoriesMaster.sales_rental_logic || {};
      const aiv = accessoriesMaster.inventory || {};
      const al = accessoriesMaster.logistics || {};
      const aes = accessoriesMaster.event_suitability || {};
      const awb = accessoriesMaster.workflow || {};

      pushFeature(amenities, <FaStar />, "Experience", ai.years_of_experience ? `${ai.years_of_experience} years` : "");
      pushFeature(amenities, <FaMapMarkerAlt />, "City", ai.city);
      pushFeature(amenities, <FaStar />, "Service Mode", ai.service_mode);
      pushFeature(amenities, <FaStar />, "Delivery Coverage", ai.delivery_coverage);

      pushFeature(amenities, <FaStar />, "Accessories Types", formatList(apc.accessories_types, 6));
      pushFeature(amenities, <FaStar />, "Gender Focus", apc.gender_focus);
      pushFeature(amenities, <FaStar />, "Bridal Accessories", apc.bridal_accessories);
      pushFeature(amenities, <FaStar />, "Groom Accessories", apc.groom_accessories);

      pushFeature(amenities, <FaStar />, "Style Categories", formatList(asd.style_categories, 5));
      pushFeature(amenities, <FaStar />, "Best Known For", formatList(asd.best_known_for, 4));
      pushFeature(amenities, <FaStar />, "Suitable For", formatList(asd.suitable_for, 5));
      pushFeature(amenities, <FaStar />, "Outfit Matching", asd.outfit_matching);
      pushFeature(amenities, <FaStar />, "Styling Consultation", asd.styling_consultation);

      pushFeature(amenities, <FaStar />, "Materials Used", formatList(amq.materials_used, 4));
      pushFeature(amenities, <FaStar />, "Quality Tier", amq.quality_tier);
      pushFeature(amenities, <FaStar />, "Handmade Products", amq.handmade_products);

      pushFeature(amenities, <FaStar />, "Product Mode", arl.product_mode);
      pushFeature(amenities, <FaStar />, "Rental Duration", arl.rental_duration);
      pushFeature(amenities, <FaStar />, "Price Range", arl.price_range);
      pushFeature(amenities, <FaStar />, "Security Deposit", arl.security_deposit);
      pushFeature(amenities, <FaStar />, "Custom Orders", arl.custom_orders);
      pushFeature(amenities, <FaStar />, "Customization Time", arl.customization_time);

      pushFeature(amenities, <FaStar />, "Inventory Size", aiv.inventory_size);
      pushFeature(amenities, <FaStar />, "Multiple Pieces Available", aiv.multiple_pieces);
      pushFeature(amenities, <FaStar />, "Real-Time Tracking", aiv.real_time_tracking);

      pushFeature(amenities, <FaStar />, "Home Delivery", al.home_delivery);
      pushFeature(amenities, <FaStar />, "Store Pickup", al.store_pickup);
      pushFeature(amenities, <FaStar />, "Shipping Charges", al.shipping_charges);
      pushFeature(amenities, <FaStar />, "Try at Home", al.try_at_home);

      pushFeature(amenities, <FaStar />, "Functions Suitable For", formatList(aes.functions_suitable_for, 6));
      pushFeature(amenities, <FaStar />, "Best For", formatList(aes.best_for, 4));

      pushFeature(amenities, <FaCalendarAlt />, "Advance Required", awb.advance_required);
      pushFeature(amenities, <FaCalendarAlt />, "Advance Percentage", awb.advance_percentage);
      pushFeature(amenities, <FaCalendarAlt />, "Cancellation Policy", awb.cancellation_policy);
      pushFeature(amenities, <FaCalendarAlt />, "Return Policy", awb.return_policy);
    }

    // --- COCKTAIL GOWN MASTER ATTRIBUTES ---
    if (cocktailGownMaster && Object.keys(cocktailGownMaster).length > 0) {
      const ci = cocktailGownMaster.identity || {};
      const pc = cocktailGownMaster.product_catalog || {};
      const core = cocktailGownMaster.core_intelligence || {};
      const fs = cocktailGownMaster.fit_styling || {};
      const ou = cocktailGownMaster.occasion_usage || {};
      const pl = cocktailGownMaster.pricing_logic || {};
      const pd = cocktailGownMaster.production_delivery || {};
      const so = cocktailGownMaster.scale_operations || {};
      const wb = cocktailGownMaster.workflow_booking || {};
      const ptag = cocktailGownMaster.ai_tags || {};

      pushFeature(amenities, <FaStar />, "Experience", ci.years_of_experience ? `${ci.years_of_experience} years` : "");
      pushFeature(amenities, <FaMapMarkerAlt />, "Primary City", ci.primary_city);
      pushFeature(amenities, <FaStar />, "Store Presence", ci.store_presence);
      pushFeature(amenities, <FaMapMarkerAlt />, "Service Cities", formatList(ci.service_cities, 4));
      pushFeature(amenities, <FaCalendarAlt />, "Appointment", ci.appointment_requirement);

      pushFeature(amenities, <FaStar />, "Gown Types", formatList(pc.gown_types, 5));
      pushFeature(amenities, <FaStar />, "Collection Type", pc.collection_type);
      pushFeature(amenities, <FaStar />, "Design Style", formatList(pc.design_style, 5));
      pushFeature(amenities, <FaStar />, "Color Palette", formatList(pc.color_palette, 5));

      pushFeature(amenities, <FaStar />, "Silhouettes", formatList(core.silhouette_types, 5));
      pushFeature(amenities, <FaStar />, "Necklines", formatList(core.neckline_types, 5));
      pushFeature(amenities, <FaStar />, "Sleeves", core.sleeve_types);
      pushFeature(amenities, <FaStar />, "Fabrics", formatList(core.fabric_options, 5));
      pushFeature(amenities, <FaStar />, "Embellishments", formatList(core.embellishment_types, 5));
      pushFeature(amenities, <FaStar />, "Train Length", core.train_length);
      pushFeature(amenities, <FaStar />, "Weight", core.weight_category);

      pushFeature(amenities, <FaStar />, "Size Range", fs.size_range);
      pushFeature(amenities, <FaStar />, "Body Type Styling", formatList(fs.body_type_styling, 5));
      pushFeature(amenities, <FaStar />, "Fit Type", fs.fit_type);
      pushFeature(amenities, <FaStar />, "Trial Availability", fs.trial_availability);
      pushFeature(amenities, <FaStar />, "Alteration Support", fs.alteration_support);
      pushFeature(amenities, <FaStar />, "Styling Consultation", fs.styling_consultation);
      pushFeature(amenities, <FaStar />, "Accessory Styling", fs.accessory_styling_support);

      pushFeature(amenities, <FaStar />, "Occasion Suitability", formatList(ou.occasion_suitability, 5));
      pushFeature(amenities, <FaStar />, "Reusability", ou.reusability);
      pushFeature(amenities, <FaStar />, "Comfort Level", ou.comfort_level);
      pushFeature(amenities, <FaStar />, "Season Suitability", ou.season_suitability);

      pushFeature(amenities, <FaStar />, "Pricing Model", pl.pricing_model);
      pushFeature(amenities, <FaStar />, "Starting Price", pl.starting_price_range);
      pushFeature(amenities, <FaStar />, "Includes", formatList(pl.includes, 5));
      pushFeature(amenities, <FaStar />, "Add-ons", formatList(pl.add_ons, 5));
      pushFeature(amenities, <FaStar />, "Negotiation", pl.negotiation_flexibility);

      pushFeature(amenities, <FaStar />, "Production Time", pd.production_time);
      pushFeature(amenities, <FaStar />, "Urgent Orders", pd.urgent_orders);
      pushFeature(amenities, <FaStar />, "Delivery Options", formatList(pd.delivery_options, 4));
      pushFeature(amenities, <FaStar />, "Packaging", pd.packaging);

      pushFeature(amenities, <FaStar />, "Orders Per Month", so.orders_per_month);
      pushFeature(amenities, <FaStar />, "Team Size", so.team_size);

      pushFeature(amenities, <FaCalendarAlt />, "Advance Booking", wb.advance_booking_time);
      pushFeature(amenities, <FaCalendarAlt />, "Booking Advance", wb.booking_advance_percent);
      pushFeature(amenities, <FaCalendarAlt />, "Cancellation Policy", wb.cancellation_policy);
      pushFeature(amenities, <FaStar />, "Client Coordination", formatList(wb.client_coordination, 4));

      pushFeature(amenities, <FaStar />, "Gown Tags", formatList(ptag.gown_tags, 5));
      pushFeature(amenities, <FaStar />, "Style Tags", formatList(ptag.style_tags, 5));
      pushFeature(amenities, <FaUsers />, "Bride Type Tags", formatList(ptag.bride_type_tags, 5));
    }

    // --- BRIDAL OUTFIT MASTER ATTRIBUTES (Trousseau Saree / Kanjeevaram Silk Saree / Lehenga) ---
    if (bridalOutfitMaster && Object.keys(bridalOutfitMaster).length > 0) {
      const bi = bridalOutfitMaster.identity || {};
      const bpc = bridalOutfitMaster.product_catalog || {};
      const bci = bridalOutfitMaster.core_intelligence || {};
      const bfs = bridalOutfitMaster.fit_styling || {};
      const bou = bridalOutfitMaster.occasion_usage || {};
      const bpl = bridalOutfitMaster.pricing_logic || {};
      const bpd = bridalOutfitMaster.production_delivery || {};
      const bso = bridalOutfitMaster.scale_operations || {};
      const bwb = bridalOutfitMaster.workflow_booking || {};
      const ptag = bridalOutfitMaster.ai_tags || {};

      pushFeature(amenities, <FaStar />, "Experience", bi.years_of_experience ? `${bi.years_of_experience} years` : "");
      pushFeature(amenities, <FaMapMarkerAlt />, "Primary City", bi.primary_city);
      pushFeature(amenities, <FaStar />, "Store Presence", bi.store_presence);
      pushFeature(amenities, <FaMapMarkerAlt />, "Service Cities", formatList(bi.service_cities, 4));
      pushFeature(amenities, <FaCalendarAlt />, "Appointment", bi.appointment_requirement);

      pushFeature(amenities, <FaStar />, "Outfit Types", formatList(bpc.lehenga_types, 5));
      pushFeature(amenities, <FaStar />, "Collection Type", bpc.collection_type);
      pushFeature(amenities, <FaStar />, "Design Style", formatList(bpc.design_style, 5));
      pushFeature(amenities, <FaStar />, "Color Options", formatList(bpc.color_options, 5));

      pushFeature(amenities, <FaStar />, "Silhouettes", formatList(bci.silhouette_types, 5));
      pushFeature(amenities, <FaStar />, "Fabrics", formatList(bci.fabric_options, 5));
      pushFeature(amenities, <FaStar />, "Work Types", formatList(bci.work_types, 5));
      pushFeature(amenities, <FaStar />, "Weight Category", bci.weight_category);
      pushFeature(amenities, <FaStar />, "Dupatta Options", bci.dupatta_options);
      pushFeature(amenities, <FaStar />, "Customization Depth", bci.customization_depth);

      pushFeature(amenities, <FaStar />, "Size Range", bfs.size_range);
      pushFeature(amenities, <FaStar />, "Body Type Styling", formatList(bfs.body_type_styling, 5));
      pushFeature(amenities, <FaStar />, "Trial Availability", bfs.trial_availability);
      pushFeature(amenities, <FaStar />, "Alteration Support", bfs.alteration_support);
      pushFeature(amenities, <FaStar />, "Styling Consultation", bfs.styling_consultation);
      pushFeature(amenities, <FaStar />, "Blouse Customization", bfs.blouse_customization);

      pushFeature(amenities, <FaStar />, "Occasion Suitability", formatList(bou.occasion_suitability, 5));
      pushFeature(amenities, <FaStar />, "Reusability", bou.reusability);
      pushFeature(amenities, <FaStar />, "Comfort Level", bou.comfort_level);
      pushFeature(amenities, <FaStar />, "Season Suitability", bou.season_suitability);

      pushFeature(amenities, <FaStar />, "Pricing Model", bpl.pricing_model);
      pushFeature(amenities, <FaStar />, "Starting Price", bpl.starting_price_range);
      pushFeature(amenities, <FaStar />, "Includes", formatList(bpl.includes, 5));
      pushFeature(amenities, <FaStar />, "Add-ons", formatList(bpl.add_ons, 5));
      pushFeature(amenities, <FaStar />, "Negotiation", bpl.negotiation_flexibility);

      pushFeature(amenities, <FaStar />, "Production Time", bpd.production_time);
      pushFeature(amenities, <FaStar />, "Urgent Orders", bpd.urgent_orders);
      pushFeature(amenities, <FaStar />, "Delivery Options", formatList(bpd.delivery_options, 4));
      pushFeature(amenities, <FaStar />, "Packaging", bpd.packaging);

      pushFeature(amenities, <FaStar />, "Orders Per Month", bso.orders_per_month);
      pushFeature(amenities, <FaStar />, "Team Size", bso.team_size);

      pushFeature(amenities, <FaCalendarAlt />, "Advance Booking", bwb.advance_booking_time);
      pushFeature(amenities, <FaCalendarAlt />, "Booking Advance %", bwb.booking_advance_percent);
      pushFeature(amenities, <FaCalendarAlt />, "Cancellation Policy", bwb.cancellation_policy);
      pushFeature(amenities, <FaStar />, "Client Coordination", formatList(bwb.client_coordination, 4));

      pushFeature(amenities, <FaStar />, "Outfit Tags", formatList(ptag.lehenga_tags, 5));
      pushFeature(amenities, <FaStar />, "Style Tags", formatList(ptag.style_tags, 5));
      pushFeature(amenities, <FaUsers />, "Bride Type Tags", formatList(ptag.bride_type_tags, 5));
    }

    // --- RENTAL OUTFIT MASTER ATTRIBUTES (Bridal Lehenga on Rent) ---
    if (rentalOutfitMaster && Object.keys(rentalOutfitMaster).length > 0) {
      const ri = rentalOutfitMaster.identity || {};
      const rs = rentalOutfitMaster.services || {};
      const rci = rentalOutfitMaster.core_intelligence || {};
      const rt = rentalOutfitMaster.technical || {};
      const rp = rentalOutfitMaster.pricing || {};
      const rsc = rentalOutfitMaster.scale || {};
      const rw = rentalOutfitMaster.workflow || {};
      const rpo = rentalOutfitMaster.portfolio || {};

      pushFeature(amenities, <FaStar />, "Store Presence", formatList(ri.store_presence, 3));
      pushFeature(amenities, <FaMapMarkerAlt />, "City", ri.city);
      pushFeature(amenities, <FaStar />, "Store Access", ri.store_access_type);
      pushFeature(amenities, <FaStar />, "Experience", ri.years_of_experience);
      pushFeature(amenities, <FaStar />, "Specialization", formatList(ri.inventory_specialization, 4));

      pushFeature(amenities, <FaStar />, "Rental Types", formatList(rs.rental_types, 3));
      pushFeature(amenities, <FaStar />, "Trial Availability", rs.trial_availability);
      pushFeature(amenities, <FaStar />, "Customization", rs.customization_alteration);
      pushFeature(amenities, <FaStar />, "Styling Assistance", rs.styling_assistance);
      pushFeature(amenities, <FaStar />, "Accessories Available", formatList(rs.accessory_rental, 5));
      pushFeature(amenities, <FaStar />, "Dry Cleaning", rs.dry_cleaning_included);
      pushFeature(amenities, <FaStar />, "Pickup & Delivery", rs.pickup_delivery_service);
      pushFeature(amenities, <FaStar />, "Urgent Rental", rs.urgent_rental_availability);

      pushFeature(amenities, <FaStar />, "Lehenga Styles", formatList(rci.lehenga_styles, 5));
      pushFeature(amenities, <FaStar />, "Occasions", formatList(rci.occasion_suitability, 5));
      pushFeature(amenities, <FaStar />, "Work Types", formatList(rci.work_type, 5));
      pushFeature(amenities, <FaStar />, "Fabrics", formatList(rci.fabric_options, 5));
      pushFeature(amenities, <FaStar />, "Colors", formatList(rci.color_palette, 5));
      pushFeature(amenities, <FaStar />, "Designer Options", formatList(rci.designer_availability, 3));
      pushFeature(amenities, <FaStar />, "Dupatta Styles", formatList(rci.dupatta_styles, 3));

      pushFeature(amenities, <FaStar />, "Size Range", formatList(rt.size_range, 4));
      pushFeature(amenities, <FaStar />, "Adjustability", rt.adjustability_range);
      pushFeature(amenities, <FaStar />, "Weight Category", rt.lehenga_weight);
      pushFeature(amenities, <FaStar />, "Blouse Types", formatList(rt.blouse_type, 3));
      pushFeature(amenities, <FaStar />, "Can-Can Included", rt.can_can_included);
      pushFeature(amenities, <FaStar />, "Dupatta Length", rt.dupatta_length);
      pushFeature(amenities, <FaStar />, "Condition", rt.condition_quality);

      pushFeature(amenities, <FaStar />, "Rental Price Range", rp.rental_price_range);
      pushFeature(amenities, <FaStar />, "Security Deposit", rp.security_deposit_required);
      pushFeature(amenities, <FaStar />, "Deposit Amount", rp.deposit_amount_range);
      pushFeature(amenities, <FaStar />, "Late Charges", rp.late_return_charges);
      pushFeature(amenities, <FaStar />, "Damage Policy", rp.damage_policy);
      pushFeature(amenities, <FaStar />, "Cleaning Charges", rp.cleaning_charges);
      pushFeature(amenities, <FaStar />, "Trial Charges", rp.trial_charges);

      pushFeature(amenities, <FaStar />, "Inventory Size", rsc.inventory_size);
      pushFeature(amenities, <FaStar />, "Daily Trial Capacity", rsc.daily_trial_capacity);
      pushFeature(amenities, <FaStar />, "Rental Capacity", rsc.simultaneous_rentals);

      pushFeature(amenities, <FaCalendarAlt />, "Advance Booking", rw.advance_booking_required);
      pushFeature(amenities, <FaCalendarAlt />, "Booking Window", rw.booking_window);
      pushFeature(amenities, <FaCalendarAlt />, "Trial Appointment", rw.trial_appointment_required);
      pushFeature(amenities, <FaCalendarAlt />, "Fitting Timeline", rw.fitting_timeline);
      pushFeature(amenities, <FaCalendarAlt />, "Pickup Timing", rw.pickup_timing);
      pushFeature(amenities, <FaCalendarAlt />, "Return Timeline", rw.return_timeline);
      pushFeature(amenities, <FaStar />, "Payment Modes", formatList(rw.payment_modes, 4));
      pushFeature(amenities, <FaStar />, "Advance Payment", rw.advance_payment_percentage);

      pushFeature(amenities, <FaStar />, "Style Tags", formatList(rpo.style_tags, 4));
      pushFeature(amenities, <FaStar />, "Audience", formatList(rpo.audience_tags, 3));
      pushFeature(amenities, <FaStar />, "Usage", formatList(rpo.usage_tags, 4));
      pushFeature(amenities, <FaStar />, "Price Segment", formatList(rpo.price_segment_tags, 2));
    }

    // --- FLOWER JEWELLERY MASTER ATTRIBUTES ---
    if (flowerJewelleryMaster && Object.keys(flowerJewelleryMaster).length > 0) {
      const fi = flowerJewelleryMaster.identity || {};
      const fpc = flowerJewelleryMaster.product_categories || {};
      const fmt = flowerJewelleryMaster.material_type || {};
      const fsd = flowerJewelleryMaster.style_design || {};
      const ffs = flowerJewelleryMaster.function_specific || {};
      const ff = flowerJewelleryMaster.facilities || {};
      const fpl = flowerJewelleryMaster.pricing_logic || {};
      const fdt = flowerJewelleryMaster.delivery_timing || {};
      const fsh = flowerJewelleryMaster.storage_handling || {};
      const fia = flowerJewelleryMaster.inventory_availability || {};
      const fwb = flowerJewelleryMaster.workflow_booking || {};

      pushFeature(amenities, <FaStar />, "Experience", fi.years_of_experience ? `${fi.years_of_experience} years` : "");
      pushFeature(amenities, <FaMapMarkerAlt />, "City", fi.city);
      pushFeature(amenities, <FaStar />, "Service Coverage", fi.service_coverage);
      pushFeature(amenities, <FaStar />, "Delivery Mode", fi.delivery_mode);

      pushFeature(amenities, <FaStar />, "Jewellery Items", formatList(fpc.jewellery_items, 6));
      pushFeature(amenities, <FaStar />, "Bridal Set Available", fpc.bridal_set_available);
      pushFeature(amenities, <FaStar />, "Set Includes", formatList(fpc.set_includes, 5));

      pushFeature(amenities, <FaStar />, "Flower Type", fmt.flower_type);
      pushFeature(amenities, <FaStar />, "Fresh Flowers", formatList(fmt.fresh_flower_types, 5));
      pushFeature(amenities, <FaStar />, "Artificial Material", formatList(fmt.artificial_material, 3));
      pushFeature(amenities, <FaStar />, "Durability", fmt.durability);

      pushFeature(amenities, <FaStar />, "Style Categories", formatList(fsd.style_categories, 5));
      pushFeature(amenities, <FaStar />, "Best Known For", formatList(fsd.best_known_for, 4));
      pushFeature(amenities, <FaStar />, "Suitable For", formatList(fsd.suitable_for, 4));
      pushFeature(amenities, <FaStar />, "Outfit Matching", fsd.outfit_matching_support);
      pushFeature(amenities, <FaStar />, "Customization", fsd.customization_available);
      pushFeature(amenities, <FaStar />, "Design Inputs", formatList(fsd.custom_design_inputs, 4));

      pushFeature(amenities, <FaStar />, "Functions", formatList(ffs.functions_suitable_for, 5));
      pushFeature(amenities, <FaStar />, "Best Function", ffs.best_function);

      pushFeature(amenities, <FaStar />, "Storage Facilities", ff.storage_facilities);
      pushFeature(amenities, <FaStar />, "Customization Capabilities", formatList(ff.customization_capabilities, 4));
      pushFeature(amenities, <FaStar />, "Delivery Features", formatList(ff.delivery_features, 4));

      pushFeature(amenities, <FaStar />, "Starting Price", fpl.starting_price);
      pushFeature(amenities, <FaStar />, "Pricing Type", fpl.pricing_type);
      pushFeature(amenities, <FaStar />, "Bridal Set Price Range", fpl.bridal_set_price_range);
      pushFeature(amenities, <FaStar />, "Bulk Orders Supported", fpl.bulk_orders_supported);
      pushFeature(amenities, <FaStar />, "Bulk Pricing", fpl.bulk_pricing);

      pushFeature(amenities, <FaStar />, "Order Prep Time", fdt.order_prep_time);
      pushFeature(amenities, <FaStar />, "Delivery Timing", fdt.delivery_timing);
      pushFeature(amenities, <FaStar />, "Time Slot Delivery", fdt.time_slot_delivery);
      pushFeature(amenities, <FaStar />, "Early Morning Delivery", fdt.early_morning_delivery);

      pushFeature(amenities, <FaStar />, "Storage Instructions", fsh.storage_instructions);
      pushFeature(amenities, <FaStar />, "Replacement Policy", fsh.replacement_policy);
      pushFeature(amenities, <FaStar />, "Damage Handling", fsh.damage_handling);

      pushFeature(amenities, <FaStar />, "Daily Capacity", fia.daily_order_capacity);
      pushFeature(amenities, <FaStar />, "Advance Booking", fia.advance_booking_required);
      pushFeature(amenities, <FaStar />, "Peak Season", fia.peak_season_availability);

      pushFeature(amenities, <FaCalendarAlt />, "Advance Required", fwb.advance_required);
      pushFeature(amenities, <FaCalendarAlt />, "Advance Percentage", fwb.advance_percentage);
      pushFeature(amenities, <FaCalendarAlt />, "Cancellation Policy", fwb.cancellation_policy);
      pushFeature(amenities, <FaCalendarAlt />, "Refund Timeline", fwb.refund_timeline);
    }


    // --- PHOTOGRAPHER/OTHER VENDOR SPECIFIC FEATURES ---
    if (
      vendorType === "Photographers" ||
      vendorType === "Makeup Artists" ||
      attributes.Offerings
    ) {
      // Delivery Time
      if (attributes.delivery_time) {
        amenities.push({
          icon: <GrFormNextLink />,
          name: `Delivery: ${attributes.delivery_time.replace(
            "Delivery time: ",
            "",
          )}`,
        });
      }

      // Offerings (render as a single amenity with value list)
      const offeringsRaw = attributes.offerings || attributes.Offerings;
      if (offeringsRaw) {
        const services = offeringsRaw
          .split(",")
          .map((s) => s.trim())
          .filter((s) => s);
        if (services.length > 0) {
          const top = services.slice(0, 5).map((s) => capitalizeWords(s));
          amenities.push({
            icon: <FaStar />,
            name: `Offerings: ${top.join(", ")}`,
          });
        }
      }
    }

    return amenities;
  };

  const [rating, setRating] = useState(0);
  const [_hover, _setHover] = useState(0);
  const [experience, setExperience] = useState("");
  const [spent, setSpent] = useState("");
  const [_reviews, _setReviews] = useState([]);

  const _handleImageUpload = (e) => {
    const files = Array.from(e.target.files);
    const filePreviews = files.map((file) => URL.createObjectURL(file));
    setImages((prev) => [...prev, ...filePreviews]);
  };

  const _handleSubmit = () => {
    if (!rating || !experience) {
      Swal.fire({
        title: "",
        text: "Please give a rating and write your experience.",
        timer: "1500",
      });
      return;
    }

    const newReview = {
      id: Date.now(),
      rating,
      experience,
      spent,
      images,
      user: "You",
      date: formatDate(new Date()),
    };

    _setReviews((prev) => [newReview, ...prev]);
    // Reset form
    setRating(0);
    setExperience("");
    setSpent("");
    setImages([]);
  };

  // Fetch wishlist on component mount to initialize favorites
  useEffect(() => {
    if (!token || !id) {
      setFavorites({});
      setWishlistIds(new Set());
      return;
    }

    const fetchWishlist = async () => {
      try {
        const res = await fetch(`https://happywedz.com/api/wishlist`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        const data = await res.json();

        if (data.success && data.data && data.data.length > 0) {
          const ids = new Set(data.data.map((item) => item.vendor_services_id));
          setWishlistIds(ids);
          // Initialize favorites state from fetched wishlist
          const favoritesObj = {};
          ids.forEach((itemId) => {
            favoritesObj[itemId] = true;
          });
          setFavorites(favoritesObj);
        } else {
          setWishlistIds(new Set());
          setFavorites({});
        }
      } catch (error) {
        console.error("Error fetching wishlist:", error);
        setWishlistIds(new Set());
        setFavorites({});
      }
    };

    fetchWishlist();
  }, [token, id]);


  // Confirmation bubble shown next to the heart that was pressed.
  // It stays mounted with `show: false` while fading out, so the label does
  // not flip from "Added" to "Removed" mid-transition.
  const [bubble, setBubble] = useState(null); // { id, added, show }
  const bubbleTimer = useRef(null);

  const showBubble = (id, added) => {
    setBubble({ id, added, show: true });
    if (bubbleTimer.current) clearTimeout(bubbleTimer.current);
    bubbleTimer.current = setTimeout(
      () => setBubble((prev) => (prev ? { ...prev, show: false } : null)),
      2200
    );
  };

  useEffect(() => () => clearTimeout(bubbleTimer.current), []);

  const isFavorite = (vendorId) => {
    if (!vendorId) return false;
    const vendorIdStr = String(vendorId);
    const vendorIdNum = parseInt(vendorId);
    return (
      favorites[vendorIdStr] === true ||
      favorites[vendorIdNum] === true ||
      wishlistIds.has(vendorIdStr) ||
      wishlistIds.has(vendorIdNum)
    );
  };

  const handleFavoriteToggle = async (e) => {
    e.preventDefault();
    e.stopPropagation();

    if (!venueData || !id) return;

    const vendorService = {
      id: parseInt(id),
      vendor_services_id: parseInt(id),
      name: venueData?.attributes?.name || venueData?.attributes?.Name,
    };

    const wasFavorite = isFavorite(id);

    // Optimistically update UI
    setFavorites((prev) => ({
      ...prev,
      [id]: !wasFavorite,
    }));

    // Update wishlistIds set
    setWishlistIds((prev) => {
      const newSet = new Set(prev);
      if (wasFavorite) {
        newSet.delete(id);
        newSet.delete(parseInt(id));
      } else {
        newSet.add(id);
        newSet.add(parseInt(id));
      }
      return newSet;
    });

    // Dispatch toggleWishlist action
    const result = await dispatch(toggleWishlist(vendorService));

    // Roll the optimistic update back when the server did not accept it.
    if (!result?.success) {
      setFavorites((prev) => ({
        ...prev,
        [id]: wasFavorite,
      }));
      setWishlistIds((prev) => {
        const newSet = new Set(prev);
        if (wasFavorite) {
          newSet.add(id);
          newSet.add(parseInt(id));
        } else {
          newSet.delete(id);
          newSet.delete(parseInt(id));
        }
        return newSet;
      });
      return;
    }

    showBubble(id, result.added);
  };

  useEffect(() => {
    const fetchVenueData = async () => {
      if (!slug) return;

      try {
        setLoading(true);
        const cleanApiBase = API_BASE_URL.replace(/\/api$/, "");
        let data = null;

        // 1. Direct slug request
        try {
          const response = await axios.get(
            `${cleanApiBase}/api/vendor-services/slug/${slug}`,
          );
          if (response.data && (response.data.id || response.data.vendor_id || response.data.attributes)) {
            data = response.data;
          }
        } catch (directErr) {
          console.debug("Direct slug lookup not found, trying keyword search fallback...", directErr?.message);
        }

        // 2. Keyword/City search fallback
        if (!data) {
          try {
            const cleanSearch = slug.replace(/[-_]+/g, " ").trim();
            const searchRes = await axios.get(`${cleanApiBase}/api/vendor-services`, {
              params: {
                search: cleanSearch,
                limit: 5,
                ...(city && city !== "all" ? { city } : {}),
              },
            });
            const items = searchRes.data?.data || (Array.isArray(searchRes.data) ? searchRes.data : []);
            if (items.length > 0) {
              const matched = items[0];
              if (matched.slug || matched.id) {
                try {
                  const matchedDetailRes = await axios.get(
                    `${cleanApiBase}/api/vendor-services/slug/${matched.slug || matched.id}`,
                  );
                  if (matchedDetailRes.data) {
                    data = matchedDetailRes.data;
                  }
                } catch { }
              }
              if (!data) {
                data = matched;
              }
            }
          } catch (searchErr) {
            console.debug("Search fallback failed:", searchErr?.message);
          }
        }

        // 3. Static mock dataset fallback
        if (!data) {
          const cleanSlugStr = slug.toLowerCase().replace(/[^a-z0-9]/g, "");
          const staticMatch =
            (subVenuesData || []).find((v) => {
              const vSlug = String(v.slug || v.name || "").toLowerCase().replace(/[^a-z0-9]/g, "");
              return vSlug.includes(cleanSlugStr) || cleanSlugStr.includes(vSlug);
            }) ||
            (subVendorsData || []).find((v) => {
              const vSlug = String(v.slug || v.name || "").toLowerCase().replace(/[^a-z0-9]/g, "");
              return vSlug.includes(cleanSlugStr) || cleanSlugStr.includes(vSlug);
            });

          if (staticMatch) {
            data = {
              id: staticMatch.id,
              vendor_id: staticMatch.id,
              slug: staticMatch.slug || slug,
              attributes: {
                name: staticMatch.name,
                vendor_name: staticMatch.name,
                city: staticMatch.location || city || "Lucknow",
                address: staticMatch.location || "",
                veg_price: staticMatch.vegPrice || staticMatch.price || 1200,
                non_veg_price: staticMatch.nonVegPrice || 1500,
                about_us: staticMatch.description || "",
                rating: staticMatch.rating || 4.8,
                review_count: staticMatch.reviews || 10,
                rooms: staticMatch.capacity ? Math.round(staticMatch.capacity / 20) : 25,
                vendor_type: staticMatch.venueType || "Wedding Venues",
                Portfolio: staticMatch.image || "",
              },
              media: [staticMatch.image || "/images/imageNotFound.jpg"],
              vendor: {
                id: staticMatch.id,
                businessName: staticMatch.name,
                city: staticMatch.location || city,
              },
            };
          }
        }

        if (!data) {
          throw new Error("Vendor details not found");
        }

        setVenueData(data);

        (async () => {
          try {
            if (data?.vendor_id) {
              const sessionKey = `vendor_viewed_${data.vendor_id}`;
              if (!sessionStorage.getItem(sessionKey)) {
                const incRes = await axios.post(
                  `${cleanApiBase}/api/vendor/increment-view/${data.vendor_id}`,
                );
                try {
                  sessionStorage.setItem(sessionKey, Date.now().toString());
                } catch { }
                if (incRes?.data?.vendor?.profileViews !== undefined) {
                  setVenueData((prev) => ({
                    ...prev,
                    vendor: {
                      ...(prev?.vendor || {}),
                      profileViews: incRes.data.vendor.profileViews,
                    },
                  }));
                  setProfileViews(incRes.data.vendor.profileViews);
                }
              } else {
                // already counted this session — skip increment
                console.debug(
                  `skip increment-view for vendor ${data.vendor_id} (already viewed this session)`,
                );
              }
            }
          } catch (incErr) {
            // fail quietly but log for debugging
            console.debug("increment-view failed:", incErr?.message || incErr);
          }
        })();

        // Handle images from new API structure
        let parsedImages = [];
        if (data.media) {
          if (Array.isArray(data.media)) {
            parsedImages = data.media.map((item) =>
              typeof item === "string" ? item : item.url || item.path || null
            ).filter(Boolean);
          } else if (typeof data.media === "object" && Array.isArray(data.media.gallery)) {
            parsedImages = data.media.gallery.map((item) =>
              typeof item === "string" ? item : item.url || item.path || null
            ).filter(Boolean);
          }
        }

        if (!parsedImages.length && data.attributes?.Portfolio) {
          // Fallback: parse Portfolio field (pipe-separated URLs)
          parsedImages = data.attributes.Portfolio.split("|")
            .map((url) => url.trim())
            .filter((url) => url);
        }

        if (!parsedImages.length) {
          // Last resort: the vendor's own profile/cover photo. Search results
          // already fall back to it, so without this a venue like Nahata Lawns &
          // Banquets showed a real picture in the dropdown and "image not found"
          // on the page it linked to.
          parsedImages = [data.vendor?.profileImage, data.vendor?.coverImage]
            .map((url) => (typeof url === "string" ? url.trim() : ""))
            .filter(Boolean);
        }

        if (parsedImages.length > 0) {
          parsedImages = parsedImages.map(img => {
            if (typeof img === 'string' && img.startsWith('/uploads/')) {
              // Uploads are served by the backend host; happywedz.com has no
              // /uploads route and answers with the SPA shell instead of a file.
              return `${IMAGE_BASE_URL.replace(/\/+$/, "")}${img}`;
            }
            return img;
          });
          setImages(parsedImages);
          setMainImage(parsedImages[0]);
        } else {
          setMainImage("/images/imageNotFound.jpg");
        }

        // Handle videos if provided
        const videoList = Array.isArray(data.attributes?.video)
          ? data.attributes.video.filter(Boolean)
          : [];
        setVideos(videoList);
        if (videoList.length > 0) {
          setMainVideo(videoList[0]);
        } else {
          setMainVideo(null);
        }

        setError(null);
      } catch (err) {
        console.error("Error fetching vendor data:", err);
        setError("Failed to load vendor details");
      } finally {
        setLoading(false);
      }
    };

    fetchVenueData();
  }, [slug]);

  const [_faqList, _setFaqList] = useState([]);

  useEffect(() => {
    const fetchFaqData = async () => {
      if (
        !venueData?.vendor?.id &&
        !venueData?.vendor_id &&
        !venueData?.attributes?.vendor_id &&
        !venueData?.attributes?.user_id &&
        !venueData?.userId &&
        !venueData?.id
      ) {
        return;
      }

      const dynamicVendorId =
        venueData.vendor?.id ||
        venueData.vendor_id ||
        venueData.attributes?.vendor_id ||
        venueData.attributes?.user_id ||
        venueData.userId ||
        venueData.id;
      const dynamicVendorTypeId = Number(venueData.vendor?.vendorType?.id || venueData.vendor?.vendor_type_id || venueData.vendor_type_id || venueData.attributes?.vendor_type_id) || null;

      const subcategoryName = venueData.vendor?.vendorSubcategory?.name || venueData.attributes?.vendor_subcategory || venueData?.subcategory?.name || venueData.attributes?.vendor_subcategory_name || venueData.attributes?.subcategory_name || "";
      const normalizedSub = String(subcategoryName).toLowerCase();
      const isLocMaster = venueData.attributes?.pre_wedding_location_master && Object.keys(venueData.attributes.pre_wedding_location_master).length > 0;
      const isPhotoMaster = venueData.attributes?.pre_wedding_photographer_master && Object.keys(venueData.attributes.pre_wedding_photographer_master).length > 0;
      const isDjMaster = venueData.attributes?.dj_master && Object.keys(venueData.attributes.dj_master).length > 0;
      const isChoreoMaster = venueData.attributes?.sangeet_choreographer_master && Object.keys(venueData.attributes.sangeet_choreographer_master).length > 0;
      const isEntMaster = venueData.attributes?.wedding_entertainer_master && Object.keys(venueData.attributes.wedding_entertainer_master).length > 0;

      let answers = [];
      try {
        const response = await axios.get(
          `https://happywedz.com/api/faq-answers/${dynamicVendorId}`,
        );
        answers = response.data || [];
      } catch (error) {
        console.error("Error fetching FAQ answers:", error);
      }

      const answerMap = new Map(
        answers.map((a) => [Number(a.faq_question_id), a.answer]),
      );

      let vendorTypeKey = null;

      // Direct subcategory-based matching first
      // Priority: Sherwani-on-rent (vendor_type_id 22) FIRST before generic rent patterns
      const isSherwaniVendor = normalizedSub.includes("sherwani") ||
        normalizedSub.includes("shervani") ||
        normalizedSub.includes("sarvani") ||
        (venueData.attributes?.vendor_subcategory_name || "").toLowerCase().includes("sherwani") ||
        (venueData.vendor?.vendorSubcategory?.name || "").toLowerCase().includes("sherwani") ||
        (venueData.attributes?.name || "").toLowerCase().includes("sherwani") ||
        (venueData.attributes?.name || "").toLowerCase().includes("shervani") ||
        (venueData.attributes?.name || "").toLowerCase().includes("sarvani");

      if ((dynamicVendorTypeId === 22 || dynamicVendorTypeId === 11) && isSherwaniVendor) {
        vendorTypeKey = "groomwear";
      } else if (normalizedSub.includes("flower jewellery") || normalizedSub.includes("floral jewellery") || normalizedSub.includes("flower jewelry") || normalizedSub.includes("floral jewelry")) {
        vendorTypeKey = "flowerjewellery";
      } else if (normalizedSub.includes("kanjeevaram") || normalizedSub.includes("silk saree")) {
        vendorTypeKey = "kanjeevaramsilksaree";
      } else if (normalizedSub.includes("rental outfit") || normalizedSub.includes("lehenga on rent") || normalizedSub.includes("on rent") || normalizedSub.includes("rent")) {
        if (normalizedSub.includes("jewel")) {
          vendorTypeKey = "jewelleryrental";
        } else {
          vendorTypeKey = "rentaloutfit";
        }
      } else if (normalizedSub.includes("accessories")) {
        vendorTypeKey = "accessories";
      } else if (normalizedSub.includes("jewellery rental") || normalizedSub.includes("jewel rental") || (normalizedSub.includes("jewell") && normalizedSub.includes("rent"))) {
        vendorTypeKey = "jewelleryrental";
      } else if (normalizedSub.includes("cocktail gown") || normalizedSub.includes("gowns")) {
        vendorTypeKey = "cocktailgowns";
      } else if (normalizedSub.includes("trousseau packer") || normalizedSub.includes("trousseau pack")) {
        vendorTypeKey = "trousseaupacker";
      } else if (normalizedSub.includes("trousseau sarees") || normalizedSub.includes("trousseau saree")) {
        vendorTypeKey = "trousseausarees";
      } else if (normalizedSub.includes("lehenga") || normalizedSub.includes("bridal outfit") || normalizedSub.includes("trousseau")) {
        vendorTypeKey = "bridaloutfit";
      } else if (
        normalizedSub.includes("favor") ||
        normalizedSub.includes("favour") ||
        normalizedSub.includes("gift") ||
        normalizedSub.includes("invitation") ||
        (venueData.attributes?.name || "").toLowerCase().includes("favor") ||
        (venueData.attributes?.name || "").toLowerCase().includes("gift") ||
        (venueData.attributes?.name || "").toLowerCase().includes("invitation") ||
        (venueData.attributes?.businessName || "").toLowerCase().includes("favor") ||
        (venueData.vendor?.name || "").toLowerCase().includes("favor")
      ) {
        vendorTypeKey = "gifts";
      }

      // 1. Fallback to Sakshi's subcategory overrides based on attributes
      if (!vendorTypeKey) {
        const attrs = venueData.attributes || {};
        // Special: If Sherwani-on-rent (vendor_type_id 22), prioritize groomwear over rental_outfit_master
        const isSherw = normalizedSub.includes("sherwani") ||
          normalizedSub.includes("shervani") ||
          normalizedSub.includes("sarvani") ||
          (venueData.attributes?.vendor_subcategory_name || "").toLowerCase().includes("sherwani") ||
          (venueData.attributes?.vendor_subcategory_name || "").toLowerCase().includes("shervani") ||
          (venueData.attributes?.vendor_subcategory_name || "").toLowerCase().includes("sarvani") ||
          (venueData.vendor?.vendorSubcategory?.name || "").toLowerCase().includes("sherwani");

        if (dynamicVendorTypeId === 22 && isSherw) {
          vendorTypeKey = "groomwear";
        } else if (attrs.jewellery_rental_master?.ai_faq || attrs.jewellery_master?.ai_faq) {
          vendorTypeKey = "jewelleryrental";
        } else if (attrs.accessories_master?.ai_faq) {
          vendorTypeKey = "accessories";
        } else if (attrs.cocktail_gown_master?.ai_faq || venueData.vendor?.vendorType?.name === "Cocktails gowns" || venueData.vendor?.vendorType?.name === "Cocktail Gowns" || venueData.vendor?.vendorType?.name === "cocktails-gowns") {
          vendorTypeKey = "cocktailgowns";
        } else if (attrs.rental_outfit_master && Object.keys(attrs.rental_outfit_master).length > 0 && dynamicVendorTypeId !== 22) {
          vendorTypeKey = "rentaloutfit";
        } else if (attrs.rental_outfit_master && Object.keys(attrs.rental_outfit_master).length > 0) {
          // If vendor_type_id is 22 but we're here, it's sherwani - use groomwear
          vendorTypeKey = "groomwear";
        } else if (attrs.flower_jewellery_master && Object.keys(attrs.flower_jewellery_master).length > 0) {
          vendorTypeKey = "flowerjewellery";
        } else if (attrs.trousseau_master && Object.keys(attrs.trousseau_master).length > 0) {
          vendorTypeKey = "trousseaupacker";
        } else if ((attrs.favor_master && Object.keys(attrs.favor_master).length > 0) || (attrs.gift_master && Object.keys(attrs.gift_master).length > 0) || (attrs.invitation_gift_master && Object.keys(attrs.invitation_gift_master).length > 0) || (attrs.invitation_master && Object.keys(attrs.invitation_master).length > 0)) {
          vendorTypeKey = "gifts";
        } else {
          // Bridal Outfit / Kanjeevaram Silk Saree detection
          const vendorTypeName = (venueData.vendor?.vendorType?.name || "").toLowerCase();
          const subcatName = (venueData.attributes?.vendor_subcategory_name || venueData.vendor?.vendorSubcategory?.name || "").toLowerCase();
          const serviceNameLower = (venueData.attributes?.name || venueData.attributes?.businessName || "").toLowerCase();
          const isKanjeevaramVendor =
            vendorTypeName.includes("kanjeevaram") ||
            vendorTypeName.includes("silk saree") ||
            subcatName.includes("kanjeevaram") ||
            subcatName.includes("silk saree") ||
            serviceNameLower.includes("kanjeevaram") ||
            serviceNameLower.includes("silk saree");
          const isBridalOutfitVendor =
            attrs.bridal_outfit_master && Object.keys(attrs.bridal_outfit_master).length > 0 &&
            !attrs.cocktail_gown_master?.ai_faq;

          if (isKanjeevaramVendor || (isBridalOutfitVendor && isKanjeevaramVendor)) {
            vendorTypeKey = "kanjeevaramsilksaree";
          } else if (isBridalOutfitVendor) {
            vendorTypeKey = "bridaloutfit";
          }
        }
      }

      // 2. If not matched by Sakshi's overrides, use HEAD's subcategory detection logic
      if (!vendorTypeKey && dynamicVendorTypeId) {
        vendorTypeKey = Object.keys(FaqQuestions).find((key) => {
          const entry = FaqQuestions[key];
          if (entry.vendor_type_id !== dynamicVendorTypeId) return false;
          if (entry.subcategory_keyword === "location") {
            return normalizedSub.includes("location") || isLocMaster;
          }
          if (entry.subcategory_keyword === "photographer") {
            return normalizedSub.includes("photographer") || isPhotoMaster;
          }
          if (entry.subcategory_keyword === "dj") {
            return normalizedSub.includes("dj") || isDjMaster;
          }
          if (entry.subcategory_keyword === "choreographer") {
            return normalizedSub.includes("choreographer") || isChoreoMaster;
          }
          if (entry.subcategory_keyword === "entertainer") {
            return normalizedSub.includes("entertainment") || normalizedSub.includes("entertainer") || isEntMaster;
          }
          return true;
        });
      }

      // 3. Fallback: if still no vendorTypeKey but we have a matching vendor_type_id
      if (!vendorTypeKey && dynamicVendorTypeId) {
        vendorTypeKey = Object.keys(FaqQuestions).find(
          (key) => FaqQuestions[key].vendor_type_id === dynamicVendorTypeId
        ) || (venueData.vendor?.vendorType?.name?.toLowerCase().includes("rent") &&
          venueData.vendor?.vendorType?.name?.toLowerCase().includes("jewel")
          ? "jewelleryrental"
          : null);
      }

      let mergedFaqs = [];
      if (vendorTypeKey && FaqQuestions[vendorTypeKey]) {
        const allQuestions = FaqQuestions[vendorTypeKey].questions || [];
        const normSubcat = (venueData?.subcategory?.name || subcategoryName || venueData.vendor?.vendorSubcategory?.name || "").trim().toLowerCase();
        let filteredQuestions = allQuestions;

        // 3a. Groomwear (vendor_type_id: 11 or Sherwani rental under type 22)
        if (dynamicVendorTypeId === 11 || (dynamicVendorTypeId === 22 && vendorTypeKey === "groomwear")) {
          const isSherwani = normSubcat.includes("sherwani");
          const isWeddingSuit = normSubcat.includes("suit") || normSubcat.includes("wedding suite");
          filteredQuestions = allQuestions.filter(q => {
            const qid = q.id;
            if (qid >= 401 && qid <= 410) return true;
            if (qid >= 411 && qid <= 425) return isSherwani;
            if (qid >= 426 && qid <= 435) return isWeddingSuit;
            return true;
          });
        }
        // 3b. Decorators / Planning (vendor_type_id: 4) filtering
        else if (dynamicVendorTypeId === 4) {
          const isDecorator = normSubcat.includes("decorator") || normSubcat.includes("decor") || normSubcat.includes("event styling");
          filteredQuestions = allQuestions.filter(q => {
            const qid = q.id;
            if (qid >= 1201 && qid <= 1212) return true;
            if (qid >= 1213 && qid <= 1225) return isDecorator;
            return true;
          });
        }
        // 3c. Invites & Gifts (vendor_type_id: 9) filtering
        else if (dynamicVendorTypeId === 9 || vendorTypeKey === "gifts") {
          const attrs = venueData.attributes || {};
          
          // Check master profiles first (priority)
          const hasTrousseauMaster = attrs.trousseau_master && Object.keys(attrs.trousseau_master).length > 0;
          const hasGiftMaster = attrs.gift_master && Object.keys(attrs.gift_master).length > 0;
          const hasFavorMaster = attrs.favor_master && Object.keys(attrs.favor_master).length > 0;
          const hasInvitationMaster = attrs.invitation_master && Object.keys(attrs.invitation_master).length > 0;

          // Determine vendor type with priority: master profile > subcategory name
          const isTrousseauPacker = hasTrousseauMaster || (!hasGiftMaster && !hasFavorMaster && !hasInvitationMaster && (normSubcat.includes("trousseau packer") || normSubcat.includes("trousseau pack")));
          const isGift = hasGiftMaster || (!hasFavorMaster && !hasInvitationMaster && !hasTrousseauMaster && (normSubcat === "gifts" || normSubcat === "gift" || normSubcat.includes("gifting") || (normSubcat.includes("invitation") && normSubcat.includes("gift"))));
          const isFavor = hasFavorMaster || (!hasGiftMaster && !hasInvitationMaster && !hasTrousseauMaster && (normSubcat.includes("favor") || normSubcat.includes("favour")));
          const isInvitation = hasInvitationMaster || (!hasGiftMaster && !hasFavorMaster && !hasTrousseauMaster && ((normSubcat.includes("invitation") || normSubcat.includes("invite")) && !normSubcat.includes("gift")));

          filteredQuestions = allQuestions.filter(q => {
            const qid = q.id;
            // Show general questions (2101-2115) ONLY if no specific master profile exists
            if (qid >= 2101 && qid <= 2115) {
              return !hasTrousseauMaster && !hasGiftMaster && !hasFavorMaster && !hasInvitationMaster;
            }
            if (qid >= 2116 && qid <= 2129) return isTrousseauPacker;
            if (qid >= 2130 && qid <= 2144) return isGift;
            if (qid >= 2145 && qid <= 2159) return isFavor;
            if (qid >= 2160 && qid <= 2172) return isInvitation;
            return false;
          });
        }

        const getAiFaqFallback = (qId) => {
          if (vendorTypeKey === "jewelleryrental") {
            const ai =
              attrs.jewellery_rental_master?.ai_faq ||
              attrs.jewellery_master?.ai_faq ||
              {};
            switch (qId) {
              case 5001: return ai.bridal_sets || ai.bridal_jewellery_sets;
              case 5002: return ai.rental_duration;
              case 5003: return ai.security_deposit || ai.security_deposit_required;
              case 5004: return ai.deposit_amount;
              case 5005: return ai.home_delivery || ai.home_delivery_available;
              case 5006: return ai.try_at_home || ai.try_at_home_service;
              case 5007: return ai.styling_consultation || ai.styling_consultation_available;
              case 5008: return ai.jewellery_types || ai.jewellery_types_offered;
              case 5009: return ai.occasions || ai.suitable_occasions;
              case 5010: return ai.inventory_size;
              case 5011: return ai.replacement || ai.replacement_available;
              case 5012: return ai.damage_policy;
              case 5013: return ai.advance_required;
              case 5014: return ai.cancellation || ai.cancellation_policy;
              case 5015: return ai.best_known_for;
              default: return "";
            }
          } else if (vendorTypeKey === "accessories") {
            const ai = attrs.accessories_master?.ai_faq || {};
            switch (qId) {
              case 4001: return ai.bridal_accessories || ai.bridal_accessories_available;
              case 4002: return ai.groom_accessories;
              case 4003: return ai.product_mode || ai.sale_or_rental || ai.sale_rental;
              case 4004: return ai.customization_available || ai.custom_orders;
              case 4005: return ai.price_range;
              case 4006: return ai.try_at_home || ai.try_at_home_available;
              case 4007: return ai.styling_consultation || ai.styling_consultation_available;
              case 4008: return ai.outfit_matching_support || ai.outfit_matching;
              case 4009: return ai.delivery_available || ai.home_delivery;
              case 4010: return ai.return_policy;
              case 4011: return ai.rental_duration;
              case 4012: return ai.inventory_size;
              case 4013: return ai.advance_required;
              case 4014: return ai.cancellation_policy;
              case 4015: return ai.best_known_for;
              default: return "";
            }
          } else if (vendorTypeKey === "cocktailgowns") {
            const ai = attrs.cocktail_gown_master?.ai_faq || {};
            switch (qId) {
              case 4301: return ai.customizable;
              case 4302: return ai.body_measurements;
              case 4303: return ai.trial_fittings;
              case 4304: return ai.styling_consultation;
              case 4305: return ai.plus_size;
              case 4306: return ai.delivery_outside_city;
              case 4307: return ai.alterations_included;
              case 4308: return ai.urgent_order;
              case 4309: return ai.premium_designer;
              case 4310: return ai.custom_color_fabric;
              case 4311: return ai.comfortable_long_events;
              case 4312: return ai.lightweight_options;
              case 4313: return ai.appointment_required;
              case 4314: return ai.reusable;
              case 4315: return ai.accessory_styling;
              default: return "";
            }
          } else if (vendorTypeKey === "bridaloutfit") {
            const ai = attrs.bridal_outfit_master?.ai_faq || {};
            switch (qId) {
              case 6001: return ai.customization_available;
              case 6002: return ai.body_measurements;
              case 6003: return ai.trial_fittings;
              case 6004: return ai.styling_consultation;
              case 6005: return ai.plus_size;
              case 6006: return ai.delivery_outside_city;
              case 6007: return ai.alterations_included;
              case 6008: return ai.urgent_order;
              case 6009: return ai.premium_designer;
              case 6010: return ai.blouse_dupatta_included || ai.custom_color_fabric;
              case 6011: return ai.comfortable_long_wear;
              case 6012: return ai.lightweight_options;
              case 6013: return ai.appointment_required;
              case 6014: return ai.reusable_after_wedding;
              case 6015: return attrs.bridal_outfit_master?.pricing_logic?.starting_price_range || "";
              default: return "";
            }
          } else if (vendorTypeKey === "kanjeevaramsilksaree") {
            const bo = attrs.bridal_outfit_master || {};
            const ai = bo.ai_faq || {};
            const core = bo.core_intelligence || {};
            const fs = bo.fit_styling || {};
            const pc = bo.product_catalog || {};
            const bi = bo.identity || {};
            const pl = bo.pricing_logic || {};
            const pd = bo.production_delivery || {};
            const formatList = (lst, max) => Array.isArray(lst) ? lst.slice(0, max).join(", ") : String(lst || "");
            switch (qId) {
              case 7001: return core.fabric_options?.includes("Silk") ? "Yes" : "";
              case 7002: return bo.core_intelligence?.customization_depth ? "Yes" : ai.customization_available || "";
              case 7003: return "";
              case 7004: return pc.lehenga_types || pc.design_style;
              case 7005: return pl.starting_price_range || "";
              case 7006: return ai.blouse_dupatta_included || "";
              case 7007: return fs.alteration_support || "";
              case 7008: return formatList(bi.service_cities, 3) || pd.delivery_options?.includes("Home Delivery") ? "Yes – Select Cities" : "";
              case 7009: return "";
              case 7010: return core.work_types?.includes("Zari") ? "Mixed" : "";
              case 7011: return fs.styling_consultation || ai.styling_consultation || "";
              case 7012: return bi.appointment_requirement || "";
              case 7013: return bo.workflow_booking?.booking_advance_percent || "";
              case 7014: return bo.workflow_booking?.cancellation_policy || "";
              case 7015: return "";
              default: return "";
            }
          } else if (vendorTypeKey === "flowerjewellery") {
            const fi = attrs.flower_jewellery_master?.identity || {};
            const fmt = attrs.flower_jewellery_master?.material_type || {};
            const fsd = attrs.flower_jewellery_master?.style_design || {};
            const ffs = attrs.flower_jewellery_master?.function_specific || {};
            const fpl = attrs.flower_jewellery_master?.pricing_logic || {};
            const fdt = attrs.flower_jewellery_master?.delivery_timing || {};
            const fwb = attrs.flower_jewellery_master?.workflow_booking || {};
            const fia = attrs.flower_jewellery_master?.inventory_availability || {};
            switch (qId) {
              case 8001: return fi.bridal_jewellery_available || "";
              case 8002: return fmt.flower_type || "";
              case 8003: return fsd.customization_available || "";
              case 8004: return ffs.suitable_for || "";
              case 8005: return fdt.delivery_available || "";
              case 8006: return fdt.same_day_delivery || "";
              case 8007: return fdt.durability || "";
              case 8008: return fia.bulk_orders_supported || "";
              case 8009: return fsd.outfit_matching_support || "";
              case 8010: return fdt.preparation_time || "";
              case 8011: return fwb.replacement_policy || "";
              case 8012: return fwb.advance_required || "";
              case 8013: return fwb.cancellation_policy || "";
              case 8014: return fpl.price_range || "";
              case 8015: return fsd.best_known_for || "";
              default: return "";
            }
          } else if (vendorTypeKey === "rentaloutfit") {
            const ri = attrs.rental_outfit_master?.identity || {};
            const rs = attrs.rental_outfit_master?.services || {};
            const rci = attrs.rental_outfit_master?.core_intelligence || {};
            const rt = attrs.rental_outfit_master?.technical || {};
            const rp = attrs.rental_outfit_master?.pricing || {};
            const rw = attrs.rental_outfit_master?.workflow || {};
            switch (qId) {
              case 9001: return ri.bridal_lehenga_available || "Yes";
              case 9002: return rs.customization_alteration || "";
              case 9003: return rci.designer_availability || "";
              case 9004: return rp.security_deposit_required || "";
              case 9005: return rp.rental_price_range?.includes("2K–10K") || rp.rental_price_range?.includes("10K–25K") ? "Yes" : "";
              case 9006: return rs.trial_availability || "";
              case 9007: return rs.dry_cleaning_included || "";
              case 9008: return rt.size_range?.includes("XL") || rt.size_range?.includes("XXL") ? "Yes" : "";
              case 9009: return rs.rental_types?.includes("Multi-Day") ? "Yes" : "";
              case 9010: return rs.accessory_rental ? "Yes" : "";
              case 9011: return rw.booking_window?.includes("0–7") || rw.booking_window?.includes("7–30") ? "Yes" : "";
              case 9012: return rt.adjustability_range || "";
              case 9013: return rs.pickup_delivery_service || "";
              case 9014: return rci.lehenga_weight?.includes("Heavy") ? "Yes" : "";
              case 9015: return rw.trial_appointment_required || "";
              default: return "";
            }
          } else if (vendorTypeKey === "gifts") {
            const ai =
              attrs.favor_master?.ai_faq ||
              attrs.gift_master?.ai_faq ||
              attrs.invitation_gift_master?.ai_faq ||
              attrs.invitation_master?.ai_faq ||
              {};
            switch (qId) {
              case 2101: return ai.starting_price_edible;
              case 2103: return ai.starting_price_non_edible;
              case 2104: return ai.min_order_edible;
              case 2105: return ai.min_order_non_edible;
              case 2106: return ai.gift_types;
              case 2107: return Array.isArray(ai.payment_modes) ? ai.payment_modes.join(", ") : ai.payment_modes;
              case 2108: return ai.advance_booking_amount;
              case 2109: return ai.cancellation_policy;
              case 2110: return ai.starting_year;
              // Gifts AI FAQ Mapping
              case 2130: return ai.handle_bulk_orders;
              case 2131: return ai.gifts_customizable;
              case 2132: return ai.packaging_included;
              case 2133: return ai.eco_friendly_gift;
              case 2134: return ai.deliver_across_india;
              case 2135: return ai.consumable_gifts_available;
              case 2136: return ai.shelf_life_of_consumable;
              case 2137: return ai.luxury_gift_options;
              case 2138: return ai.handle_urgent_orders;
              case 2139: return ai.gift_samples_available;
              case 2140: return ai.branded_for_corporate;
              case 2141: return ai.minimum_order_quantity_required;
              case 2142: return ai.fragile_gift_safely_packed;
              case 2143: return ai.temperature_controlled_delivery;
              case 2144: return ai.suitable_for_all_guests;
              // Favors AI FAQ Mapping
              case 2145: return ai.handle_bulk_orders;
              case 2146: return ai.favors_customizable;
              case 2147: return ai.edible_favors_available;
              case 2148: return ai.shelf_life_of_edible;
              case 2149: return ai.eco_friendly_favors;
              case 2150: return ai.personalized_with_names;
              case 2151: return ai.provide_packaging;
              case 2152: return ai.deliver_across_india;
              case 2153: return ai.favors_reusable;
              case 2154: return ai.minimum_order_quantity_required;
              case 2155: return ai.handle_urgent_orders;
              case 2156: return ai.fragile_items_safely_packed;
              case 2157: return ai.match_wedding_theme;
              case 2158: return ai.suitable_for_kids;
              case 2159: return ai.premium_luxury_favors_available;
              // Invitations AI FAQ Mapping
              case 2160: return ai.create_digital_invites;
              case 2161: return ai.print_physical_cards;
              case 2162: return ai.invitations_customizable;
              case 2163: return ai.match_wedding_theme;
              case 2164: return ai.box_invitations_available;
              case 2165: return ai.handmade_paper_used;
              case 2166: return ai.min_order_quantity;
              case 2167: return ai.shipping_across_world;
              case 2168: return ai.handle_urgent_orders;
              case 2169: return ai.calligraphy_services_available;
              case 2170: return ai.samples_available;
              case 2171: return ai.designer_invitations_available;
              case 2172: return ai.qr_code_integration;
              default: return "";
            }
          } else if (vendorTypeKey === "groomwear") {
            const ai =
              attrs.sherwani_master?.ai_faq ||
              attrs.wedding_suit_master?.ai_faq ||
              attrs.groom_wear_master?.ai_faq ||
              {};
            switch (qId) {
              case 401: return Array.isArray(ai.outfit_types) ? ai.outfit_types.join(", ") : ai.outfit_types;
              case 402: return ai.customization_available;
              case 403: return ai.collection_type;
              case 404: return ai.price_range;
              case 405: return ai.trial_available;
              case 406: return ai.delivery_duration;
              case 407: return ai.advance_required;
              case 408: return ai.best_known_for;
              case 409: return ai.cancellation_policy;
              case 410: return ai.starting_year;
              // Sherwani Specific (411-425)
              case 411: return ai.groom_sherwanis || "Yes";
              case 412: return ai.customization_available;
              case 413: return ai.rental_available;
              case 414: return ai.security_deposit;
              case 415: return ai.rental_duration;
              case 416: return ai.dry_cleaning_included;
              case 417: return ai.alterations_included;
              case 418: return ai.accessories_included;
              case 419: return ai.fabric_variety;
              case 420: return ai.appointment_required;
              case 421: return ai.urgent_delivery;
              case 422: return ai.international_shipping;
              case 423: return ai.matching_stole_pagri;
              case 424: return ai.luxury_premium_range;
              case 425: return ai.return_policy;
              // Suits & Tuxedos (426-435)
              case 426: return ai.suits_tuxedos || "Yes";
              case 427: return ai.custom_tailoring;
              case 428: return ai.imported_fabrics;
              case 429: return ai.fitting_sessions;
              case 430: return ai.styling_assistance;
              case 431: return ai.ready_to_wear;
              case 432: return ai.matching_accessories;
              case 433: return ai.maintenance_tips;
              case 434: return ai.alteration_support;
              case 435: return ai.order_timeline;
              default: return "";
            }
          }
          return "";
        };

        mergedFaqs = filteredQuestions.map((q) => {
          let answer = answerMap.get(q.id) || "";
          if (!answer) {
            const fallback = getAiFaqFallback(q.id);
            if (
              fallback &&
              (Array.isArray(fallback)
                ? fallback.length > 0
                : String(fallback).trim() !== "")
            ) {
              answer = Array.isArray(fallback) ? fallback.join(", ") : fallback;
            }
          }
          return {
            ...q,
            ans: answer,
          };
        });
      }

      _setFaqList(mergedFaqs);
    };

    fetchFaqData();
  }, [venueData]);

  useEffect(() => {
    window.scrollTo({
      top: 0,
      left: 0,
      behavior: "smooth",
    });
  }, []);

  if (loading) {
    return (
      <div className="venue-detail-page">
        <Container className="py-5">
          <div className="text-center">
            <div className="spinner-border text-primary" role="status">
              <span className="visually-hidden">Loading...</span>
            </div>
            <p className="mt-3">Loading vendor details...</p>
          </div>
        </Container>
      </div>
    );
  }
  if (error || !venueData) {
    return (
      <div className="venue-detail-page py-5" style={{ minHeight: "60vh", background: "#fafafa" }}>
        <Container className="py-5">
          <div
            className="text-center mx-auto p-5 bg-white rounded-4 shadow-sm"
            style={{ maxWidth: "600px", border: "1px solid #f0f0f0" }}
          >
            <div
              className="d-inline-flex align-items-center justify-content-center mb-4 rounded-circle"
              style={{
                width: "72px",
                height: "72px",
                background: "linear-gradient(135deg, #fff1f6 0%, #ffe4ee 100%)",
                color: "#ed1173",
                fontSize: "28px",
              }}
            >
              <FaMapMarkerAlt />
            </div>
            <h3 className="fw-bold mb-2" style={{ color: "#222" }}>
              Vendor Details Unavailable
            </h3>
            <p className="text-muted mb-4" style={{ fontSize: "14.5px", lineHeight: "1.6" }}>
              We couldn't locate this specific vendor profile or the listing is currently being updated.
            </p>
            <div className="d-flex flex-wrap justify-content-center gap-3">
              {city && city !== "all" && (
                <Button
                  variant="primary"
                  onClick={() => navigate(`/wedding-venues/${city}`)}
                  className="px-4 py-2 rounded-pill fw-semibold shadow-sm"
                  style={{
                    background: "linear-gradient(135deg, #ed1173 0%, #c40a5a 100%)",
                    border: "none",
                  }}
                >
                  Explore Venues in {city.charAt(0).toUpperCase() + city.slice(1)}
                </Button>
              )}
              <Button
                variant="outline-secondary"
                onClick={() => navigate("/venues")}
                className="px-4 py-2 rounded-pill fw-semibold"
                style={{ borderColor: "#ddd", color: "#555" }}
              >
                Browse All Venues
              </Button>
            </div>
          </div>
        </Container>
      </div>
    );
  }

  function _parseDbValue(value) {
    if (
      typeof value === "string" &&
      value.startsWith("{") &&
      value.endsWith("}")
    ) {
      return value
        .replace(/[{}]/g, "")
        .split(",")
        .map((item) => item.replace(/"/g, "").trim());
    } else if (typeof value === "string") {
      return value
        .split(",")
        .map((item) => item.trim())
        .filter((item) => item);
    }
    return [value].filter((v) => v);
  }

  const isVenue = !!(
    venueData.attributes?.veg_price ||
    venueData.attributes?.catering_policy ||
    venueData.attributes?.rooms ||
    venueData.attributes?.vendor_type?.toLowerCase().includes("venue")
  );

  const displayLocation = isVenue
    ? venueData.attributes?.address ||
    venueData.attributes?.city ||
    "Location not specified"
    : venueData.attributes?.address ||
    venueData.attributes?.city ||
    venueData.vendor?.city ||
    "Location not specified";

  const rawCityVal = venueData.attributes?.city || venueData.vendor?.city || null;
  const cleanCity = extractMainCity(rawCityVal);



  // Prefer precise coordinates if present
  const latRaw =
    venueData.attributes?.latitude ?? venueData.attributes?.location?.latitude;
  const lngRaw =
    venueData.attributes?.longitude ??
    venueData.attributes?.location?.longitude;
  const lat = parseFloat(latRaw);
  const lng = parseFloat(lngRaw);
  const hasCoords = Number.isFinite(lat) && Number.isFinite(lng);
  const mapSrc = hasCoords
    ? `https://maps.google.com/maps?q=${lat},${lng}&t=&z=13&ie=UTF8&iwloc=&output=embed`
    : `https://maps.google.com/maps?q=${encodeURIComponent(
      displayLocation,
    )}&t=&z=13&ie=UTF8&iwloc=&output=embed`;

  const activeVendor = {
    id: id,
    name:
      venueData.attributes?.vendor_name ||
      venueData.attributes?.name ||
      venueData.vendor?.vendor_name ||
      "Unknown Vendor",
    location: displayLocation,
    rating: venueData.attributes?.rating || 4.5,
    reviews: venueData.attributes?.review_count || 0,
    image: mainImage || "/images/default-vendor.jpg",
  };

  // Aliases to match JSX usage
  const faqList = _faqList || [];
  const parseDbValue = _parseDbValue;
  const vendorFeatures = getVendorFeatures(venueData);
  
  // For venues, we show all sections by default if they are filled. 
  // For other vendors, we keep the slice limit.
  const isVenueType =
    String(venueData.attributes?.vendor_type || "").toLowerCase().includes("venue") ||
    String(venueData.vendor?.vendorType?.name || "").toLowerCase().includes("venue") ||
    String(venueData.subcategory?.name || "").toLowerCase().includes("venue") ||
    window.location.pathname.includes("/wedding-venues");

  const displayLimit = isVenueType ? 1000 : 9; 
  
  const hasManyFeatures = vendorFeatures.length > displayLimit;
  const featuresToRender = showAllFeatures
    ? vendorFeatures
    : vendorFeatures.slice(0, displayLimit);

  // Smooth scroll to section by id
  const scrollToSection = (sectionId) => {
    const el = document.getElementById(sectionId);
    if (el) {
      el.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  };

  const reviewCountVal = parseInt(venueData.attributes?.review_count || venueData.attributes?.reviews || 0, 10);
  const reviewPhrase = reviewCountVal > 0 ? "reviews, " : "";

  let rawTitle = isVenueType
    ? cleanCity
      ? `${activeVendor.name} — Capacity & Photos | ${cleanCity}`
      : `${activeVendor.name} — Capacity & Photos | HappyWedz`
    : cleanCity
      ? `${activeVendor.name} — Portfolio & Details | ${cleanCity}`
      : `${activeVendor.name} — Portfolio & Details | HappyWedz`;

  if (rawTitle.length > 60) {
    const shortName = activeVendor.name.length > 30 ? `${activeVendor.name.substring(0, 27)}...` : activeVendor.name;
    rawTitle = isVenueType
      ? cleanCity ? `${shortName} — Capacity | ${cleanCity}` : `${shortName} | HappyWedz`
      : cleanCity ? `${shortName} — Portfolio | ${cleanCity}` : `${shortName} | HappyWedz`;
  }
  const pageTitle = rawTitle;

  let rawDesc = isVenueType
    ? cleanCity
      ? `Compare ${activeVendor.name} in ${cleanCity} on HappyWedz. See seating capacity, photos, catering policy, ${reviewPhrase}and venue details.`
      : `Compare ${activeVendor.name} on HappyWedz. See seating capacity, photos, catering policy, ${reviewPhrase}and venue details.`
    : cleanCity
      ? `Explore ${activeVendor.name} in ${cleanCity} on HappyWedz. See photos, service offerings, ${reviewPhrase}and contact details.`
      : `Explore ${activeVendor.name} on HappyWedz. See photos, service offerings, ${reviewPhrase}and contact details.`;

  if (rawDesc.length > 155) {
    rawDesc = rawDesc.substring(0, 152).trim() + "...";
  }
  const pageDescription = rawDesc;

  const citySlug = cleanCity
    ? cleanCity.toLowerCase().trim().replace(/[^a-z0-9\s-]/g, "").replace(/\s+/g, "-")
    : "all";

  const rawSubCat = venueData.subcategory?.name || venueData.attributes?.subcategory_name || venueData.attributes?.vendor_type || "all";
  const subCatSlug = rawSubCat.toLowerCase().trim().replace(/[^a-z0-9\s-]/g, "").replace(/\s+/g, "-");

  const breadcrumbCategoryLabel = isVenueType ? "Wedding Venues" : "Vendors";
  const breadcrumbCategoryUrl = isVenueType ? "/wedding-venues" : "/vendors";
  const breadcrumbCityUrl = isVenueType
    ? `/wedding-venues/${citySlug}`
    : `/vendors/${subCatSlug}/${citySlug}`;

  return (
    <div className="venue-detail-page">
      <SEO
        title={pageTitle}
        description={pageDescription}
        image={activeVendor.image}
      />
      <StructuredData
        type={isVenueType ? "venue" : "vendor"}
        data={{
          name: activeVendor.name,
          city: cleanCity,
          address: activeVendor.location,
          image: activeVendor.image,
          rating: venueData.attributes?.rating,
          reviews: venueData.attributes?.review_count,
          capacity: venueData.attributes?.venue_master?.space_capacity?.max_guests,
          description: `Book ${activeVendor.name} on HappyWedz.`,
          phone: venueData.attributes?.contact_phone || venueData.vendor?.phone
        }}
      />
      <Container className="py-2">
        <Breadcrumbs
          items={[
            { label: "Home", url: "/" },
            {
              label: breadcrumbCategoryLabel,
              url: breadcrumbCategoryUrl
            },
            ...(cleanCity
              ? [
                  {
                    label: cleanCity,
                    url: breadcrumbCityUrl
                  }
                ]
              : []),
            { label: activeVendor.name }
          ]}
        />
        <Row>
          <Col lg={8}>
            <div className="main-image-container mb-4 position-relative">
              {mediaTab === "gallery" ? (
                mainImage ? (
                  <img
                    src={mainImage}
                    alt={`${activeVendor.name}${venueData.attributes?.vendor_type ? ` - ${venueData.attributes.vendor_type}` : ""}${cleanCity ? ` in ${cleanCity}` : ""}`}
                    className="main-image rounded-lg"
                    style={{
                      width: "100%",
                      height: "500px",
                      objectFit: "cover",
                    }}
                    onError={(e) => {
                      e.target.onerror = null;
                      // Find the next image in gallery that isn't the failed image or imageNotFound
                      const nextValid = (images || []).find(img => img && img !== mainImage && !img.includes('imageNotFound'));
                      if (nextValid) {
                        e.target.src = nextValid;
                        setMainImage(nextValid);
                      } else {
                        e.target.src = "/images/imageNotFound.jpg";
                        e.target.alt = "";
                        try {
                          setMainImage("/images/imageNotFound.jpg");
                        } catch (err) {}
                      }
                    }}
                  />
                ) : (
                  <div className="main-image rounded-lg d-flex align-items-center justify-content-center bg-light">
                    <p className="text-muted">No image available</p>
                  </div>
                )
              ) : mainVideo ? (
                getYouTubeVideoId(mainVideo) ? (
                  <iframe
                    src={`https://www.youtube.com/embed/${getYouTubeVideoId(
                      mainVideo,
                    )}`}
                    title="YouTube video player"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                    allowFullScreen
                    className="rounded-lg"
                    style={{
                      width: "100%",
                      height: "500px",
                      border: "none",
                      backgroundColor: "#000",
                    }}
                  />
                ) : (
                  <video
                    src={mainVideo}
                    controls
                    className="rounded-lg"
                    style={{
                      width: "100%",
                      height: "500px",
                      objectFit: "cover",
                      backgroundColor: "#000",
                    }}
                  />
                )
              ) : (
                <div className="main-image rounded-lg d-flex align-items-center justify-content-center bg-light">
                  <p className="text-muted">No video available</p>
                </div>
              )}
              {/* In-image media toggle */}
              <div
                className="position-absolute d-flex align-items-center"
                style={{
                  top: "12px",
                  left: "60px",
                  background: "#fff",
                  color: "#000",
                  borderRadius: "999px",
                  padding: "4px",
                  boxShadow: "0 2px 8px rgba(0,0,0,0.15)",
                  zIndex: 2,
                  gap: "6px",
                }}
              >
                <button
                  type="button"
                  className="btn btn-sm fs-14"
                  onClick={() => setMediaTab("gallery")}
                  style={{
                    background: mediaTab === "gallery" ? "#f2f2f2" : "#fff",
                    color: "#000",
                    border:
                      mediaTab === "gallery"
                        ? "2px solid #000"
                        : "1px solid #e5e5e5",
                    padding: "2px 10px",
                    height: "28px",
                    lineHeight: 1,
                    borderRadius: "999px",
                  }}
                >
                  Gallery
                </button>

                <button
                  type="button"
                  className="btn btn-sm fs-14"
                  onClick={() => setMediaTab("video")}
                  disabled={videos.length === 0}
                  title={videos.length === 0 ? "No videos available" : ""}
                  style={{
                    background: mediaTab === "video" ? "#f2f2f2" : "#fff",
                    color: "#000",
                    border:
                      mediaTab === "video"
                        ? "2px solid #000"
                        : "1px solid #e5e5e5",
                    padding: "2px 10px",
                    height: "28px",
                    lineHeight: 1,
                    opacity: videos.length === 0 ? 0.5 : 1,
                    cursor: videos.length === 0 ? "not-allowed" : "pointer",
                    borderRadius: "999px",
                  }}
                >
                  Video
                </button>
              </div>

              {isVenue && hasView360(venueData) && (
                <button
                  className="btn btn-light position-absolute rounded-circle border-0 shadow-sm"
                  title="View in 360°"
                  style={{
                    top: "12px",
                    left: "12px",
                    width: "36px",
                    height: "36px",
                    padding: "0",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                  }}
                  onClick={() => navigate(`/vendor-360/${id}`)}
                >
                  <TbView360Number className="text-dark" size={18} />
                </button>
              )}
              <button className="favorite-btn" onClick={handleFavoriteToggle}>
                <WishlistBubble
                  show={!!bubble?.show}
                  added={bubble?.added}
                />
                {isFavorite(id) ? (
                  <FaHeart className="text-danger" />
                ) : (
                  <FaRegHeart />
                )}
              </button>
            </div>

            {mediaTab === "gallery"
              ? images.length > 0 && (
                <div className="thumbnail-gallery mb-5">
                  <Swiper
                    modules={[Autoplay]}
                    spaceBetween={10}
                    slidesPerView={4}
                    autoplay={{
                      delay: 3000,
                      disableOnInteraction: false,
                    }}
                    loop={images.length > 4}
                    grabCursor={true}
                    freeMode={true}
                  >
                    {images.map((img, idx) => (
                      <SwiperSlide key={idx}>
                        <div
                          className={`thumbnail-item ${mainImage === img ? "active" : ""
                            } ${hoveredIndex !== null && hoveredIndex !== idx
                              ? "blurred"
                              : ""
                            }`}
                          onClick={() => setMainImage(img)}
                          onMouseEnter={() => setHoveredIndex(idx)}
                          onMouseLeave={() => setHoveredIndex(null)}
                        >
                          <img
                            src={img}
                            alt={`${activeVendor.name}${cleanCity ? ` in ${cleanCity}` : ""} - Photo ${idx + 1}`}
                            className="img-fluid rounded"
                            style={{
                              cursor: "pointer",
                              height: "100%",
                              objectFit: "cover",
                            }}
                            onError={(e) => {
                              e.target.onerror = null;
                              e.target.src = "/images/imageNotFound.jpg";
                            }}
                          />
                        </div>
                      </SwiperSlide>
                    ))}
                  </Swiper>
                </div>
              )
              : videos.length > 0 && (
                <div className="mb-5">
                  <div className="d-flex gap-2 flex-wrap">
                    {videos.map((vid, idx) => {
                      const youtubeId = getYouTubeVideoId(vid);
                      return youtubeId ? (
                        <div
                          key={idx}
                          onClick={() => setMainVideo(vid)}
                          className={`rounded overflow-hidden position-relative ${mainVideo === vid ? "border border-primary" : ""
                            }`}
                          style={{
                            width: "160px",
                            height: "100px",
                            backgroundColor: "#000",
                            cursor: "pointer",
                            backgroundImage: `url(https://img.youtube.com/vi/${youtubeId}/mqdefault.jpg)`,
                            backgroundSize: "cover",
                            backgroundPosition: "center",
                          }}
                        >
                          <div
                            className="d-flex align-items-center justify-content-center h-100"
                            style={{ backgroundColor: "rgba(0,0,0,0.3)" }}
                          >
                            <svg
                              width="32"
                              height="32"
                              viewBox="0 0 24 24"
                              fill="white"
                              xmlns="http://www.w3.org/2000/svg"
                            >
                              <path d="M8 5V19L19 12L8 5Z" />
                            </svg>
                          </div>
                        </div>
                      ) : (
                        <video
                          key={idx}
                          src={vid}
                          muted
                          onClick={() => setMainVideo(vid)}
                          className={`rounded ${mainVideo === vid ? "border border-primary" : ""
                            }`}
                          style={{
                            width: "160px",
                            height: "100px",
                            objectFit: "cover",
                            backgroundColor: "#000",
                            cursor: "pointer",
                          }}
                        />
                      );
                    })}
                  </div>
                </div>
              )}

            {/* In-page navigation */}
            <SectionTabs scrollToSection={scrollToSection} />

            <div id="about" className="venue-description mb-5 p-2">
              <h2 className="details-section-title fw-bold fs-22">
                About {venueData.attributes?.name || venueData.attributes?.Name}
              </h2>
              {venueData.attributes?.about_us ? (
                <div
                  className="description-text text-black fs-14 vendor-about-html"
                  dangerouslySetInnerHTML={{
                    __html: DOMPurify.sanitize(
                      venueData?.attributes?.about_us || "",
                    ),
                  }}
                />
              ) : (
                <p className="text-black text-justify">
                  No description available for this vendor.
                </p>
              )}

              {/* {venueData.attributes?.subtitle && (
                <p className="description-text text-black text-justify fs-14">
                  {venueData.attributes.subtitle}
                </p>
              )} */}
            </div>

            {/* FACILITIES & FEATURES */}
            {vendorFeatures.length > 0 && (
              <div id="facilities" className="venue-facilities mb-5 p-2">
                <h2 className="details-section-title fw-bold fs-22 mb-4">
                  Facilities & Features
                </h2>
                <div className="venue-amenities">
                  <Row>
                    {featuresToRender.map((item, index) => {
                      const raw = item.name || "";
                      const isSub = raw.startsWith("-");
                      const trimmed = isSub
                        ? raw.replace(/^\-\s*/, "").trim()
                        : raw.trim();
                      const [labelPart, ...rest] = trimmed.split(":");
                      const label = (labelPart || "").trim();
                      const value = rest.join(":").trim();

                      return (
                        <Col
                          key={index}
                          md={isSub ? 12 : 4}
                          sm={isSub ? 12 : 6}
                          xs={12}
                          className={isSub ? "mb-2" : "mb-3"}
                        >
                          <div className={`amenity-item ${isSub ? "ms-4" : ""}`}>
                            <div className="d-flex flex-column">
                              <span className="fw-semibold text-dark fs-16">
                                {label}
                              </span>
                              {value && (
                                <span className="text-muted small mt-1 fs-14">
                                  {value}
                                </span>
                              )}
                              {!value && !label && (
                                <span className="text-muted small fs-14">
                                  {trimmed}
                                </span>
                              )}
                            </div>
                          </div>
                        </Col>
                      );
                    })}
                  </Row>
                  {hasManyFeatures && (
                    <div className="mt-2">
                      <button
                        type="button"
                        className="btn btn-link p-0 text-dark fw-semibold text-decoration-underline fs-14"
                        onClick={() => setShowAllFeatures((prev) => !prev)}
                      >
                        {showAllFeatures ? "Show Less" : "Read More"}
                      </button>
                    </div>
                  )}
                </div>
              </div>
            )}

            <VenueFAQ venueData={venueData} activeVendor={activeVendor} />

            <div id="reviews" className="py-2">
              <ReviewSection vendor={venueData || activeVendor} />
            </div>

            <div id="map" className="mt-4 pt-3 border-top">
              <div
                className="mb-2 fw-semibold text-dark fs-16"
                style={{ fontSize: "1.05rem" }}
              >
                <span>
                  {venueData?.attributes?.address ||
                    extractMainCity(venueData?.attributes?.city)}
                </span>
              </div>

              {/* Show map by coordinates when available; fallback to text location */}
              <iframe
                src={mapSrc}
                width="100%"
                height="450"
                style={{
                  border: 0,
                  borderRadius: "12px",
                  boxShadow: "0 4px 10px rgba(0, 0, 0, 0.15)",
                  cursor: "grab",
                }}
                allowFullScreen
                loading="lazy"
                referrerPolicy="no-referrer-when-downgrade"
                title="Vendor Location Map"
              ></iframe>
            </div>
          </Col>

          <Col lg={4} className="ps-lg-5">
            <div
              className="venue-details-card p-4 border rounded z-0"
              style={{ top: "20px" }}
            >
              <div className="venue-info">
                {/* Title + Location */}
                <div className="mb-3">
                  <div className="d-flex">
                    <h1 className="fw-bold fs-22 text-dark m-0">
                      {venueData?.attributes?.name ||
                        venueData?.attributes?.Name ||
                        "Vendor Name"}
                    </h1>
                  </div>

                  <div
                    className={`d-flex ${(
                      venueData?.attributes?.address ||
                      venueData?.attributes?.city ||
                      ""
                    ).length > 38
                      ? "align-items-start"
                      : "align-items-center"
                      } my-2 fs-14 text-black`}
                  >
                    <FaLocationDot
                      className="me-1"
                      size={15}
                      color="#000"
                      style={{
                        marginTop:
                          (
                            venueData?.attributes?.address ||
                            venueData?.attributes?.city ||
                            ""
                          ).length > 38
                            ? "3px"
                            : "0",
                      }}
                    />
                    <span
                      style={{
                        wordBreak: "break-word",
                        lineHeight: "1.3",
                      }}
                    >
                      {venueData?.attributes?.address ||
                        extractMainCity(venueData?.attributes?.city)}
                    </span>
                  </div>

                  {/* Rating Clean */}
                  <div className="d-flex justify-content-between align-items-center mt-2">
                    <div className="rating-badge d-flex align-items-center gap-1">
                      <FaStar size={12} color="#000" />
                      <span className="fw-semibold text-dark fs-16">
                        {venueData.attributes?.rating || 0}
                      </span>
                      <span className="text-muted fs-10">
                        ({venueData.attributes?.review_count || 0} reviews)
                      </span>
                    </div>
                  </div>
                </div>

                <div className="tags mb-4 d-flex flex-wrap gap-2">
                  {/* {venueData.attributes?.vendor_type && (
                    <span className="px-2 py-1 border rounded text-dark fs-12 bg-white">
                      {venueData.attributes.vendor_type}
                    </span>
                  )} */}
                  {/* {isVenue && venueData.attributes?.rooms && (
                    <span className="px-2 py-1 border rounded text-dark fs-12 bg-white">
                      Hotel/Resort
                    </span>
                  )}
                  {isVenue && venueData.attributes?.indoor_outdoor && (
                    <span className="px-2 py-1 border rounded text-dark fs-12 bg-white">
                      {capitalizeWords(venueData.attributes.indoor_outdoor)}
                    </span>
                  )} */}
                </div>

                {/* Pricing Section */}
                <div className="pricing mb-3 text-dark">
                  {isVenue ? (
                    <>
                      <div className="fw-semibold text-black mb-1 fs-14">
                        Veg Starting Price
                      </div>
                      <div className="fw-bold fs-16 mt-1 primary-text">
                        {(() => {
                          const raw = venueData.attributes?.veg_price;
                          if (!raw) return "Contact for pricing";
                          const val = parseInt(String(raw).replace(/[^0-9]/g, ""), 10);
                          if (isNaN(val) || val <= 0) return "Contact for pricing";
                          return val >= 50000
                            ? `₹ ${val.toLocaleString("en-IN")} (Venue Package)`
                            : `₹ ${val.toLocaleString("en-IN")}`;
                        })()}
                      </div>

                      <div className="fw-semibold text-black mb-1 fs-14 mt-3">
                        Non-Veg Starting Price
                      </div>
                      <div className="fw-bold fs-16 mt-1 primary-text">
                        {(() => {
                          const raw = venueData.attributes?.non_veg_price;
                          if (!raw) return "Contact for pricing";
                          const val = parseInt(String(raw).replace(/[^0-9]/g, ""), 10);
                          if (isNaN(val) || val <= 0) return "Contact for pricing";
                          return val >= 50000
                            ? `₹ ${val.toLocaleString("en-IN")} (Venue Package)`
                            : `₹ ${val.toLocaleString("en-IN")} onwards`;
                        })()}
                      </div>

                      {venueData.attributes?.starting_price && (
                        <div
                          className="mt-3 d-flex align-items-center justify-content-between"
                          style={{ cursor: "pointer" }}
                          onClick={() => setShowStartingPrice((prev) => !prev)}
                        >
                          <span className="fw-semibold fs-14">
                            Venue starting price
                          </span>
                          <span className="d-flex align-items-center primary-text fs-14">
                            {showStartingPrice && (
                              <span className="me-2">
                                ₹{" "}
                                {parseInt(
                                  String(
                                    venueData.attributes.starting_price,
                                  ).replace(/[^0-9]/g, ""),
                                  10,
                                ).toLocaleString()}
                              </span>
                            )}
                            {showStartingPrice ? (
                              <FaChevronUp size={14} />
                            ) : (
                              <FaChevronDown size={14} />
                            )}
                          </span>
                        </div>
                      )}
                    </>
                  ) : (
                    <>
                      <span className="fw-semibold fs-16 d-block">
                        {venueData.attributes?.vendor_type === "Makeup"
                          ? "Makeup Package (Starting)"
                          : venueData.attributes?.vendor_type === "Photography"
                            ? "Photography Package (Starting)"
                            : venueData.attributes?.vendor_type ===
                              "Music And Dance"
                              ? ""
                              : ""}
                      </span>

                      <div className="fs-16 fw-bold mt-1">
                        <span className="fw-semibold fs-16 d-block">
                          Starting Price
                        </span>
                        <span className="primary-text">
                          ₹{" "}
                          {venueData.attributes?.PriceRange ||
                            venueData.attributes.starting_price
                            ? venueData.attributes.PriceRange.replace(
                              "Rs.",
                              "",
                            ).trim() || venueData.attributes.starting_price
                            : venueData.attributes.photo_package_price
                              ? `₹${parseInt(
                                venueData.attributes.photo_package_price.replace(
                                  /,/g,
                                  "",
                                ),
                              ).toLocaleString()} onwards`
                              : "Contact for pricing"}
                        </span>
                      </div>

                      {venueData.attributes?.photo_video_package_price && (
                        <>
                          <div className="fw-semibold text-black mb-1 fs-14 mt-3">
                            Photo + Video Package (Starting)
                          </div>
                          <div className="fs-16 fw-bold mt-1">
                            <span className="primary-text">
                              ₹{" "}
                              {venueData.attributes.photo_video_package_price.replace(
                                "Rs.",
                                "",
                              )}
                            </span>
                          </div>
                        </>
                      )}
                    </>
                  )}
                </div>

                <div className="details-action-group">
                  <button
                    className="btn btn-outline-primary details-action-btn rounded-2"
                    onClick={() => setShowClaimForm(true)}
                  >
                    Claim Your Business
                  </button>
                </div>

                <hr />

                <div className="details-action-group mb-3">
                  <button
                    className="btn btn-outline-primary details-action-btn rounded-2"
                    onClick={() => handleShowPricingModal(venueData.vendor_id)}
                  >
                    Request Pricing & Availability
                  </button>
                </div>
              </div>
            </div>
          </Col>
        </Row>
      </Container>

      {/* Similar Venues/Vendors section */}
      <SimilarServices
        venueData={venueData}
        currentId={id || venueData?.id}
        currentCity={city || venueData?.attributes?.city || venueData?.vendor?.city}
      />

      <PricingModal
        show={showPricingModal}
        handleClose={() => setShowPricingModal(false)}
        vendorId={selectedVendorId || venueData?.vendor_id || venueData?.id}
        availableSlots={
          venueData?.available_slots ||
          venueData?.attributes?.available_slots ||
          venueData?.availableSlots ||
          venueData?.attributes?.availableSlots
        }
      />

      <Modal
        show={showClaimForm}
        onHide={() => setShowClaimForm(false)}
        size="xl"
        centered
        scrollable
        backdrop={true}
      >
        <Modal.Body>
          <BusinessClaimForm
            setShowClaimForm={setShowClaimForm}
            vendorServiceId={venueData?.id}
          />
        </Modal.Body>
      </Modal>
    </div>
  );
};

export default Detailed;
