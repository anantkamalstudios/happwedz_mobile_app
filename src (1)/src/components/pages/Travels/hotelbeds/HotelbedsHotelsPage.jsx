import { useEffect, useMemo, useRef, useState } from "react";
import { Button, Modal, Offcanvas } from "react-bootstrap";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import { toast } from "react-toastify";
import {
  BedDouble,
  Check,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  CircleHelp,
  ExternalLink,
  Filter,
  Images,
  LayoutGrid,
  List,
  MapPin,
  MessageCircleMore,
  Search,
  SlidersHorizontal,
  Sparkles,
  Star,
  UserRound,
  X,
} from "lucide-react";
import {
  getHotelDetail,
  searchHotels,
  trackHotelAnalyticsEvent,
} from "../../../../services/api/hotelApi";
import { formatDate as fmtDate, formatDateWithWeekday } from "../../../../utils/dateFormat";
import HotelDetailsPage, { HotelSearchBarEditable } from "./HotelbedsDetailsPage";
import HotelSearchForm from "../honeymoon/components/HotelSearchForm";
import { defaultFilters } from "./hotelbedsDetailHelpers";
import "./hotelbedsStyles.css";


const readPath = (value, path) =>
  path.reduce((acc, key) => (acc && acc[key] !== undefined ? acc[key] : undefined), value);

const findFirstArray = (value, paths) => {
  for (const path of paths) {
    const match = readPath(value, path);
    if (Array.isArray(match)) return match;
  }
  return [];
};

const createCorrelationId = () => {
  if (typeof globalThis.crypto?.randomUUID === "function") {
    return globalThis.crypto.randomUUID();
  }
  return `corr-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
};

const getErrorMessage = (error, fallback) => {
  if (typeof error === "string" && error.trim()) return error;
  if (typeof error?.message === "string" && error.message.trim()) return error.message;
  if (typeof error?.response?.data?.message === "string" && error.response.data.message.trim()) {
    return error.response.data.message;
  }
  if (typeof error?.response?.data?.error === "string" && error.response.data.error.trim()) {
    return error.response.data.error;
  }
  return fallback;
};

const formatMoney = (value, currency = "INR", compact = false) => {
  const amount = Number(value);
  if (!Number.isFinite(amount)) return "Price not available";
  const localeCurrency = currency === "INR" ? "INR" : currency;
  const formatted = new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: localeCurrency,
    maximumFractionDigits: 0,
  }).format(amount);
  return compact ? formatted.replace("₹", "₹") : formatted;
};

const formatDate = (value) => {
  if (!value) return "Select date";
  return formatDateWithWeekday(value, { fallback: value });
};

const getHotelId = (hotel) =>
  String(
    hotel?.tjid ||
      hotel?.tjHotelId ||
      hotel?.hotelId ||
      hotel?.raw?.tjHotelId ||
      hotel?.raw?.hotelId ||
      hotel?.hid ||
      hotel?.id ||
      hotel?.hotelCode ||
      "",
  );

const getReviewPayloadFields = (hotelInfo, selectedHotel, detailMeta, searchPayload, searchResponse) => {
  const searchIdCandidates = [
    detailMeta?.searchId,
    searchResponse?.metaData?.searchId,
    searchResponse?.searchId,
    searchPayload?.searchId,
    selectedHotel?.raw?.searchId,
  ]
    .filter(Boolean)
    .map((value) => String(value));

  const detailRequestIdCandidates = [
    detailMeta?.requestId,
    searchResponse?.metaData?.requestId,
    searchResponse?.requestId,
    hotelInfo?.requestId,
    hotelInfo?.detailRequestId,
    selectedHotel?.raw?.requestId,
  ]
    .filter(Boolean)
    .map((value) => String(value));

  const tjHotelIdCandidates = [
    hotelInfo?.tjid,
    hotelInfo?.tjHotelId,
    selectedHotel?.raw?.tjid,
    selectedHotel?.raw?.tjHotelId,
    selectedHotel?.raw?.hotelId,
  ]
    .filter(Boolean)
    .map((value) => String(value));

  return {
    searchId: searchIdCandidates[0] || "",
    detailRequestId: detailRequestIdCandidates[0] || "",
    tjHotelId: tjHotelIdCandidates[0] || "",
    candidates: {
      searchIdCandidates,
      detailRequestIdCandidates,
      tjHotelIdCandidates,
    },
  };
};

const buildDefaultTraveller = (passengerType, bookingRequirements) => {
  const isAdult = passengerType === "ADULT";
  return {
    ti: isAdult ? "Mr" : "Master",
    pt: passengerType,
    fN: "",
    lN: "",
    ...(bookingRequirements?.panRequired && isAdult ? { pan: "" } : {}),
    ...(bookingRequirements?.passportRequired && isAdult ? { pNum: "" } : {}),
  };
};

const getReviewRoomInfos = (reviewResponse) => {
  const selectedOption = reviewResponse?.selectedOption || {};
  if (Array.isArray(selectedOption?.roomInfos) && selectedOption.roomInfos.length > 0) {
    return selectedOption.roomInfos;
  }
  if (Array.isArray(selectedOption?.ris) && selectedOption.ris.length > 0) {
    return selectedOption.ris;
  }

  const fallbackAdults = Number(reviewResponse?.roomSummary?.adults || 1);
  const fallbackChildren = Number(reviewResponse?.roomSummary?.children || 0);
  return [
    {
      adt: fallbackAdults,
      chd: fallbackChildren,
    },
  ];
};

const createInitialBookingForm = (reviewResponse) => {
  const bookingRequirements = reviewResponse?.bookingRequirements || {};
  const roomTravellerInfo = getReviewRoomInfos(reviewResponse).map((roomInfo) => {
    const adultCount = Math.max(Number(roomInfo?.adt || 0), 1);
    const childCount = Math.max(Number(roomInfo?.chd || 0), 0);
    const travellerInfo = [
      ...Array.from({ length: adultCount }, () => buildDefaultTraveller("ADULT", bookingRequirements)),
      ...Array.from({ length: childCount }, () => buildDefaultTraveller("CHILD", bookingRequirements)),
    ];

    return { travellerInfo };
  });

  return {
    roomTravellerInfo,
    deliveryInfo: {
      emails: [""],
      contacts: [""],
      code: ["+91"],
    },
    termsAccepted: false,
  };
};

const validateBookingForm = (bookingForm, reviewResponse) => {
  const errors = [];
  const bookingRequirements = reviewResponse?.bookingRequirements || {};
  const roomTravellerInfo = Array.isArray(bookingForm?.roomTravellerInfo) ? bookingForm.roomTravellerInfo : [];

  if (roomTravellerInfo.length === 0) {
    errors.push("At least one traveller is required.");
  }

  roomTravellerInfo.forEach((room, roomIndex) => {
    const travellerInfo = Array.isArray(room?.travellerInfo) ? room.travellerInfo : [];
    if (travellerInfo.length === 0) {
      errors.push(`Room ${roomIndex + 1} needs at least one traveller.`);
      return;
    }

    travellerInfo.forEach((traveller, travellerIndex) => {
      if (!traveller?.fN?.trim()) {
        errors.push(`Enter first name for room ${roomIndex + 1}, traveller ${travellerIndex + 1}.`);
      }
      if (!traveller?.lN?.trim()) {
        errors.push(`Enter last name for room ${roomIndex + 1}, traveller ${travellerIndex + 1}.`);
      }
      if (traveller?.pt === "ADULT" && bookingRequirements?.panRequired) {
        if (!/^[A-Z]{5}[0-9]{4}[A-Z]$/.test(String(traveller?.pan || "").trim().toUpperCase())) {
          errors.push(`Enter a valid PAN for room ${roomIndex + 1}, traveller ${travellerIndex + 1}.`);
        }
      }
      if (traveller?.pt === "ADULT" && bookingRequirements?.passportRequired) {
        if (!/^[A-Z0-9]{6,20}$/i.test(String(traveller?.pNum || "").trim())) {
          errors.push(`Enter a valid passport number for room ${roomIndex + 1}, traveller ${travellerIndex + 1}.`);
        }
      }
    });
  });

  const email = String(bookingForm?.deliveryInfo?.emails?.[0] || "").trim();
  const phone = String(bookingForm?.deliveryInfo?.contacts?.[0] || "").trim();
  const code = String(bookingForm?.deliveryInfo?.code?.[0] || "").trim();

  if (!email || !/^\S+@\S+\.\S+$/.test(email)) {
    errors.push("Enter a valid contact email address.");
  }
  if (!phone || !/^[0-9]{7,15}$/.test(phone)) {
    errors.push("Enter a valid contact phone number.");
  }
  if (!code || !/^\+?\d{1,4}$/.test(code)) {
    errors.push("Enter a valid phone country code.");
  }
  if (!bookingForm?.termsAccepted) {
    errors.push("Accept the booking terms before proceeding.");
  }

  return errors;
};

const delay = (ms) => new Promise((resolve) => {
  window.setTimeout(resolve, ms);
});

const normalizeAmount = (value) => {
  const num = Number(value || 0);
  if (!Number.isFinite(num) || num <= 0) return 0;
  return Number(num.toFixed(2));
};

const getHotelImages = (hotel) => {
  const images = [
    ...(Array.isArray(hotel?.images) ? hotel.images : []),
    ...(Array.isArray(hotel?.img) ? hotel.img : []),
    ...(hotel?.heroImage ? [hotel.heroImage] : []),
    ...(hotel?.image ? [hotel.image] : []),
  ];
  return images
    .map((image) => image?.url || image?.imageUrl || image?.path || image?.links?.Standard?.href || image)
    .filter(Boolean);
};

const getHotelAddress = (hotel, searchPayload) => {
  const address = hotel?.address || {};
  return [
    address?.ctn,
    address?.sn,
    hotel?.cityName,
    hotel?.location,
    searchPayload?.searchQuery?.searchCriteria?.searchRegionName,
  ]
    .filter(Boolean)
    .join(", ");
};

// Suppliers return place names shouted in caps ("BHAVANI NAGAR"). Short tokens
// that are already all-caps and no more than three letters are left alone, so
// "NEW DELHI NCR" keeps its NCR and "UK" stays UK.
const toTitleCase = (value) => {
  const text = String(value || "").trim();
  if (!text) return "";
  if (text !== text.toUpperCase()) return text; // already mixed case, leave it
  return text.toLowerCase().replace(/\b[a-z]/g, (ch) => ch.toUpperCase());
};

const getDisplayRating = (score) => {
  const numeric = Number(score);
  if (!Number.isFinite(numeric) || numeric <= 0) return null;
  return (numeric / 20).toFixed(1);
};

const getRatingLabel = (hotel) => hotel?.userRating?.label || "No rating";

const getPriceInfo = (hotel, searchPayload) => {
  const rate = Array.isArray(hotel?.rate) ? hotel.rate[0] : hotel?.rate?.[0];
  const rawOption = Array.isArray(hotel?.options) ? hotel.options[0] : null;
  const rawPricing = rawOption?.pricing || null;
  const supplierNightly = Number(rate?.nightlyPrice ?? rate?.pricePerNight ?? hotel?.nightlyPrice);
  const totalPrice = Number(
    hotel?.minPrice ??
      rate?.totalPrice ??
      rate?.price?.totalPrice ??
      rawPricing?.totalPrice ??
      hotel?.price,
  );

  // The search response carries only a total, so every card used to print
  // "Price on request" directly above a real price. Derive the nightly rate the
  // same way normalizeRoomOption already does for the detail page.
  const nights = Math.max(1, getNightCount(searchPayload));
  const derivedNightly =
    Number.isFinite(totalPrice) && totalPrice > 0 ? totalPrice / nights : Number.NaN;
  const nightlyPrice =
    Number.isFinite(supplierNightly) && supplierNightly > 0 ? supplierNightly : derivedNightly;

  return {
    nightlyPrice: Number.isFinite(nightlyPrice) && nightlyPrice > 0 ? nightlyPrice : null,
    totalPrice: Number.isFinite(totalPrice) ? totalPrice : null,
    currency: rate?.currency || rawPricing?.currency || hotel?.currency || "INR",
    mealBasis: rate?.mealbasis || rate?.mealBasis || rawOption?.mealBasis || hotel?.mealBasis || "Room Only",
    optionId: rate?.optionId || rawOption?.optionId || hotel?.optionId || "",
    supplierName: rate?.supplierName || hotel?.supplierName || "",
    cancellation: rate?.cancellation || rawOption?.cancellation || hotel?.cancellation || null,
    isRefundable:
      rate?.cancellation?.isRefundable ??
      rawOption?.cancellation?.isRefundable ??
      hotel?.cancellation?.isRefundable ??
      false,
  };
};

const getAmenities = (hotel) => {
  const preferred = [];
  const seen = new Set();

  if (Array.isArray(hotel?.tja)) {
    hotel.tja.forEach((group) => {
      if (Array.isArray(group?.am)) {
        group.am.forEach((item) => {
          const name = String(item?.name || item || "").trim();
          if (name && !seen.has(name.toLowerCase())) {
            seen.add(name.toLowerCase());
            preferred.push(name);
          }
        });
      }
    });
  }

  if (preferred.length === 0 && Array.isArray(hotel?.facilities)) {
    hotel.facilities.forEach((item) => {
      const name = String(item?.name || item || "").trim();
      if (name && !seen.has(name.toLowerCase())) {
        seen.add(name.toLowerCase());
        preferred.push(name);
      }
    });
  }

  return preferred.slice(0, 4);
};

const normalizeHotel = (hotel, searchPayload) => {
  const images = getHotelImages(hotel);
  const priceInfo = getPriceInfo(hotel, searchPayload);
  return {
    id: getHotelId(hotel),
    name: hotel?.name || hotel?.hotelName || "Hotel",
    location: toTitleCase(getHotelAddress(hotel, searchPayload)),
    image: images[0] || "",
    imageCount: images.length,
    images,
    starRating: Number(hotel?.starRating || 0),
    userRating: getDisplayRating(hotel?.userRating?.score),
    userRatingLabel: getRatingLabel(hotel),
    ratingCount: Number(hotel?.userRating?.rc || 0),
    userFavourite: Boolean(hotel?.userFavourite),
    propertyType: hotel?.propertyType || hotel?.categoryName || "",
    brand: hotel?.brand || hotel?.chain || "",
    amenities: getAmenities(hotel),
    priceInfo,
    raw: hotel,
  };
};

const extractHotels = (payload, searchPayload) =>
  findFirstArray(payload, [
    ["hotels"],
    ["data", "hotels"],
    ["searchResult", "hotels"],
    ["hotelSearchResult", "hotels"],
    ["hotelSearchResult", "searchResult", "hotels"],
    ["result", "hotels"],
  ])
    .map((hotel) => normalizeHotel(hotel, searchPayload))
    .filter((hotel) => hotel.id);

const extractSearchId = (payload) =>
  payload?.searchId ||
  payload?.data?.searchId ||
  payload?.searchResult?.searchId ||
  payload?.hotelSearchResult?.searchId ||
  "";

const extractHotelCount = (payload, fallbackCount = 0) =>
  Number(
    payload?.hotelCount ??
      payload?.data?.hotelCount ??
      payload?.searchResult?.hotelCount ??
      payload?.hotelSearchResult?.hotelCount ??
      fallbackCount,
  ) || fallbackCount;

const extractLastHotelId = (payload, hotels = []) =>
  payload?.lastHotelId ||
  payload?.data?.lastHotelId ||
  payload?.pagination?.lastHotelId ||
  payload?.data?.pagination?.lastHotelId ||
  hotels[hotels.length - 1]?.id ||
  "";

const mergeHotels = (currentHotels, incomingHotels) => {
  const merged = [...currentHotels];
  const seen = new Set(currentHotels.map((hotel) => hotel.id));

  incomingHotels.forEach((hotel) => {
    if (!hotel?.id) return;

    if (seen.has(hotel.id)) {
      const index = merged.findIndex((item) => item.id === hotel.id);
      if (index >= 0) merged[index] = hotel;
      return;
    }

    seen.add(hotel.id);
    merged.push(hotel);
  });

  return merged;
};

const normalizeFilterOption = (item) => ({
  value: String(item?.value ?? item?.label ?? item ?? ""),
  label: String(item?.label ?? item?.value ?? item ?? ""),
  count: Number(item?.count ?? 0) || 0,
  state: item?.state || "ENABLED",
});

const normalizeFilterKey = (name) => {
  const key = String(name || "").toLowerCase();
  if (key === "property type") return "propertyType";
  if (key === "popular places") return "popularPlaces";
  if (key === "rating") return "ratings";
  if (key === "user rating") return "userRating";
  if (key === "amenities") return "amenities";
  if (key === "free cancellation") return "cancellationPolicy";
  if (key === "price range") return "priceRange";
  if (key === "search by hotel name") return "hotelName";
  return key.replace(/\s+/g, "");
};

const extractFilterGroups = (payload) => {
  const groups = Array.isArray(payload?.filters)
    ? payload.filters
    : Array.isArray(payload?.data?.filters)
      ? payload.data.filters
      : [];

  return groups.map((group) => ({
    key: normalizeFilterKey(group?.name),
    name: group?.name || "",
    filterType: group?.filterType || "STATIC",
    options: Array.isArray(group?.options)
      ? group.options
          .map(normalizeFilterOption)
          .filter((item) => item.value && item.label && item.state !== "DISABLED")
      : [],
  }));
};

const buildDetailPayload = (hotel, searchPayload, searchResponse) => {
  const searchQuery = searchPayload?.searchQuery || {};
  const criteria = searchQuery.searchCriteria || {};
  return {
    correlationId:
      searchResponse?.correlationId ||
      searchPayload?.correlationId ||
      createCorrelationId(),
    searchQuery: {
      checkInDate: searchQuery.checkinDate,
      checkoutDate: searchQuery.checkoutDate,
      roomInfo: searchQuery.roomInfo || [],
      hotelSearchCriteria: {
        nationality: criteria.nationality || "106",
        countryOfResidence: criteria.countryOfResidence || "106",
        currency: criteria.currency || "INR",
      },
      searchPreferences: {
        hids: [hotel.id],
      },
      searchRegionId: criteria.city || "",
      searchRegionName: criteria.searchRegionName || "",
      searchRegionType: criteria.searchRegionType || searchQuery.searchType || "CITY",
      gstApplied: false,
      isLimitOptionAllowed: true,
    },
    searchId: searchResponse?.searchId || searchPayload?.searchId || "",
    userIntent: {
      optionId: hotel?.priceInfo?.optionId || "",
      supplierName: hotel?.priceInfo?.supplierName || "",
      price: Number.isFinite(hotel?.priceInfo?.totalPrice)
        ? String(hotel.priceInfo.totalPrice)
        : "",
    },
  };
};

const mapSortOrderToAPI = (sortOrder) => {
  const sortMapping = {
    "popularity": "popularity",
    "priceLowToHigh": "price_asc", 
    "priceHighToLow": "price_desc",
    "starRatingHighToLow": "rating"
  };
  return sortMapping[sortOrder] || "popularity";
};

const mapSortOrderToDisplayName = (sortOrder) => {
  const displayMapping = {
    "popularity": "Most Popular",
    "priceLowToHigh": "Price ( Lowest first )",
    "priceHighToLow": "Price ( Highest first )",
    "starRatingHighToLow": "Star rating ( High to Low )"
  };
  return displayMapping[sortOrder] || "Most Popular";
};

const trackSortAnalyticsEvent = async (sortOrder, searchPayload, searchResponse, initialSuggestion) => {
  try {
    const searchId = searchResponse?.searchId || searchPayload?.searchId || "";
    const cityName = initialSuggestion?.displayName || 
                    searchPayload?.searchQuery?.searchCriteria?.searchRegionName || 
                    "Unknown";
    const cityId = searchPayload?.searchQuery?.searchCriteria?.city || 
                   initialSuggestion?.id || "";
    
    const analyticsPayload = {
      event: "Hotel_SRP_Sort_By_CTA",
      properties: {
        Search_Id: searchId,
        Sort_By_Option: mapSortOrderToDisplayName(sortOrder),
        City_Id: cityId,
        City_Name: cityName,
        Product: "HOTEL",
        Search_Type: searchPayload?.searchQuery?.searchCriteria?.searchRegionType || "CITY",
        Selected_Option_Id: cityId,
        Selected_Option_Name: cityName,
        TimeStamp: new Date().toISOString(),
        Date: fmtDate(new Date()),
        Current_Page: window.location.href,
        Current_Path: window.location.pathname,
        Previous_Page: document.referrer || "",
        Previous_Path: new URL(document.referrer || window.location.href).pathname,
      }
    };

    await trackHotelAnalyticsEvent(analyticsPayload);
  } catch (error) {
    console.error("Failed to track sort analytics event:", error);
  }
};

const buildFilterPayload = (searchPayload, searchResponse, sortOrder) => {
  return {
    ...searchPayload,
    appliedFilters: {
      ...(searchPayload?.appliedFilters || {}),
    },
    searchId: searchResponse?.searchId || searchPayload?.searchId || "",
    correlationId: searchPayload?.correlationId || createCorrelationId(),
    sortOrder: mapSortOrderToAPI(sortOrder),
  };
};

const getPriceRangeBucket = (amount) => {
  const value = Number(amount || 0);
  if (!Number.isFinite(value) || value <= 0) return null;
  if (value < 3000) return "UNDER_3000";
  if (value < 6000) return "3000_6000";
  if (value < 10000) return "6000_10000";
  return "ABOVE_10000";
};

// Star ratings and price bands are ordinal: they read 5-4-3-2 and cheapest-first,
// never "whichever bucket happens to have the most hotels". Everything else
// (amenities, property type) is unordered and stays sorted by popularity.
const PRICE_RANGE_ORDER = ["UNDER_3000", "3000_6000", "6000_10000", "ABOVE_10000"];

const PRICE_RANGE_LABELS = {
  UNDER_3000: "Under ₹3,000",
  "3000_6000": "₹3,000 - ₹6,000",
  "6000_10000": "₹6,000 - ₹10,000",
  ABOVE_10000: "Above ₹10,000",
};

const buildLocalFilterGroups = (hotels = []) => {
  const source = Array.isArray(hotels) ? hotels : [];
  const aggregate = (key, values) => {
    const countMap = new Map();
    values.forEach((value) => {
      const v = String(value || "").trim();
      if (!v) return;
      countMap.set(v, (countMap.get(v) || 0) + 1);
    });
    return {
      key,
      name:
        key === "ratings"
          ? "Rating"
          : key === "propertyType"
            ? "Property Type"
            : key === "mealType"
              ? "Meal Type"
              : key === "cancellationPolicy"
                ? "Free Cancellation"
                : key === "amenities"
                  ? "Amenities"
                  : key === "priceRange"
                    ? "Price Range"
                    : key,
      filterType: "STATIC",
      options: [...countMap.entries()]
        .map(([value, count]) => ({
          value,
          label: key === "priceRange" ? PRICE_RANGE_LABELS[value] || value : value,
          count,
          state: "ENABLED",
        }))
        .sort((a, b) => {
          if (key === "ratings") return Number(b.value) - Number(a.value);
          if (key === "priceRange") {
            return PRICE_RANGE_ORDER.indexOf(a.value) - PRICE_RANGE_ORDER.indexOf(b.value);
          }
          return b.count - a.count || String(a.label).localeCompare(String(b.label));
        }),
    };
  };

  const ratings = source.map((hotel) => (hotel.starRating > 0 ? String(Math.round(hotel.starRating)) : ""));
  const propertyTypes = source.map((hotel) => hotel.propertyType || "");
  const mealTypes = source.map((hotel) => hotel.priceInfo?.mealBasis || "");
  const cancellation = source.map((hotel) =>
    hotel.priceInfo?.isRefundable ? "REFUNDABLE" : "NON_REFUNDABLE",
  );
  const amenities = source.flatMap((hotel) => (Array.isArray(hotel.amenities) ? hotel.amenities : []).slice(0, 8));
  const priceRanges = source.map((hotel) => getPriceRangeBucket(hotel.priceInfo?.totalPrice || 0));

  return [
    aggregate("ratings", ratings),
    aggregate("propertyType", propertyTypes),
    aggregate("mealType", mealTypes),
    aggregate("cancellationPolicy", cancellation),
    aggregate("amenities", amenities),
    aggregate("priceRange", priceRanges),
  ].filter((group) => group.options.length > 0);
};

const sanitizeArrayFilterValues = (values = []) => {
  if (!Array.isArray(values)) return [];
  return values
    .map((value) => (typeof value === "string" ? value.trim() : value))
    .filter((value) => value !== undefined && value !== null && String(value).trim() !== "")
    .filter((value) => {
      const text = String(value).trim();
      // Drop stale currency chips like "$2500.0" restored from previous UI state.
      if (/^[\$€£]\s*\d/.test(text)) return false;
      return true;
    });
};

const sanitizeAppliedFilters = (filters = {}, filterGroups = []) => {
  const base = { ...defaultFilters(), ...(filters || {}) };

  const sanitized = { ...defaultFilters() };
  Object.keys(sanitized).forEach((key) => {
    const value = base[key];
    if (Array.isArray(sanitized[key])) {
      sanitized[key] = sanitizeArrayFilterValues(Array.isArray(value) ? value : []);
    } else if (typeof sanitized[key] === "boolean") {
      sanitized[key] = Boolean(value);
    } else {
      sanitized[key] = typeof value === "string" ? value : "";
    }
  });

  if (Array.isArray(filterGroups) && filterGroups.length > 0) {
    const optionsByKey = new Map(
      filterGroups.map((group) => [
        group.key,
        new Set((group.options || []).map((option) => String(option.value))),
      ]),
    );

    Object.keys(sanitized).forEach((key) => {
      if (!Array.isArray(sanitized[key])) return;
      const allowed = optionsByKey.get(key);
      if (!allowed || allowed.size === 0) return;
      sanitized[key] = sanitized[key].filter((item) => allowed.has(String(item)));
    });
  }

  return sanitized;
};

const areArrayFiltersEqual = (a = [], b = []) => {
  if (a === b) return true;
  if (!Array.isArray(a) || !Array.isArray(b)) return false;
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i += 1) {
    if (String(a[i]) !== String(b[i])) return false;
  }
  return true;
};

const areAppliedFiltersEqual = (left = {}, right = {}) => {
  const base = defaultFilters();
  const keys = Object.keys(base);
  for (const key of keys) {
    const leftValue = left?.[key];
    const rightValue = right?.[key];
    if (Array.isArray(base[key])) {
      if (!areArrayFiltersEqual(leftValue, rightValue)) return false;
    } else if (typeof base[key] === "boolean") {
      if (Boolean(leftValue) !== Boolean(rightValue)) return false;
    } else if (String(leftValue || "") !== String(rightValue || "")) {
      return false;
    }
  }
  return true;
};

const buildSearchPayload = (
  searchPayload,
  searchResponse,
  sortOrder,
  lastHotelId = "",
) => ({
  ...buildFilterPayload(searchPayload, searchResponse, sortOrder),
  pagination: {
    ...(searchPayload?.pagination || {}),
    pageSize:
      searchPayload?.pagination?.pageSize ||
      searchResponse?.pagination?.pageSize ||
      searchResponse?.data?.pagination?.pageSize ||
      15,
    lastHotelId,
  },
  allOptions: searchPayload?.allOptions ?? true,
  filterType: searchPayload?.filterType || "BOTH",
  searchId: extractSearchId(searchResponse) || searchPayload?.searchId || "",
});

const parseJsonSafely = (value) => {
  if (!value || typeof value !== "string") return null;
  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
};

const dedupeStrings = (values) => {
  const seen = new Set();
  return values.filter((value) => {
    const normalized = String(value || "").trim();
    if (!normalized) return false;
    const key = normalized.toLowerCase();
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
};

const dedupeImages = (values) => {
  const seen = new Set();
  return values.filter((item) => {
    const url = String(item?.url || item || "").trim();
    if (!url) return false;
    if (seen.has(url)) return false;
    seen.add(url);
    return true;
  });
};

const normalizeImageItems = (items) =>
  dedupeImages(
    (Array.isArray(items) ? items : [])
      .map((item) => item?.url || item?.imageUrl || item?.path || item?.links?.[0]?.url || item)
      .filter(Boolean)
      .map((url) => ({ url })),
  );

const escapeRegExp = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const buildAddressParts = (address = {}) =>
  [
    address?.adr,
    address?.adr2,
    address?.ctn || address?.city?.name,
    address?.sn || address?.state?.name,
    address?.postalCode,
    address?.cn || address?.country?.name,
  ].filter(Boolean);

const buildAddressLabel = (address = {}) => buildAddressParts(address).join(", ");

const getRoomMetadata = (hotelInfo, roomInfo) => {
  const roomId = String(roomInfo?.id || roomInfo?.rid || roomInfo?.roomId || "");
  const roomMetaMap = hotelInfo?.oprmd || hotelInfo?.roomMeta || {};
  return roomMetaMap?.[roomId] || roomInfo || {};
};

const getRoomBedSummary = (roomMeta) => {
  const beds = Array.isArray(roomMeta?.bds)
    ? roomMeta.bds
    : Array.isArray(roomMeta?.radi?.bds)
      ? roomMeta.radi.bds
      : [];

  if (beds.length === 0) return "";

  return beds
    .map((bed) => `${bed?.bc || 1} ${bed?.bt || "Bed"}`.trim())
    .filter(Boolean)
    .join(", ");
};

const getRoomGuestSummary = (roomMeta, roomInfo) => {
  const maxGuests = Number(roomMeta?.mga ?? roomMeta?.radi?.mga ?? roomInfo?.mga ?? 0);
  const maxAdults = Number(roomMeta?.maa ?? roomMeta?.radi?.maa ?? roomInfo?.adt ?? 0);
  const maxChildren = Number(roomMeta?.mca ?? roomMeta?.radi?.mca ?? roomInfo?.chd ?? 0);

  if (!maxGuests && !maxAdults && !maxChildren) return "";

  const parts = [];
  if (maxGuests) parts.push(`Fits max. ${maxGuests} guest${maxGuests > 1 ? "s" : ""}`);
  else if (maxAdults) parts.push(`${maxAdults} adult${maxAdults > 1 ? "s" : ""}`);
  if (maxChildren) parts.push(`${maxChildren} child${maxChildren > 1 ? "ren" : ""}`);
  return parts.join(" • ");
};

const getCancellationLabel = (cnp) => {
  if (cnp?.ifra === true) return "Refundable";
  if (cnp?.inra === true) return "Non-refundable";
  if (cnp?.isRefundable === true) return "Refundable";
  return "Cancellation policy";
};

const getCancellationPenalties = (cnp) =>
  Array.isArray(cnp?.pd)
    ? cnp.pd.map((penalty) => ({
        from: penalty?.fdt || penalty?.from || "",
        to: penalty?.tdt || penalty?.to || "",
        amount: penalty?.am ?? penalty?.amount ?? "",
      }))
    : Array.isArray(cnp?.penalties)
      ? cnp.penalties
      : [];

const getNightCount = (searchPayload) => {
  const checkin = new Date(searchPayload?.searchQuery?.checkinDate || searchPayload?.searchQuery?.checkInDate);
  const checkout = new Date(searchPayload?.searchQuery?.checkoutDate || searchPayload?.searchQuery?.checkOutDate);
  if (Number.isNaN(checkin.getTime()) || Number.isNaN(checkout.getTime())) return 1;
  const diff = Math.round((checkout.getTime() - checkin.getTime()) / 86400000);
  return diff > 0 ? diff : 1;
};

const getRoomImages = (roomMeta) =>
  normalizeImageItems([
    ...(Array.isArray(roomMeta?.img) ? roomMeta.img.flatMap((item) => item?.links || item) : []),
    ...(Array.isArray(roomMeta?.imgs) ? roomMeta.imgs : []),
  ]);

const ROOM_DESCRIPTION_SECTION_LABELS = [
  "Layout",
  "Internet",
  "Entertainment",
  "Food & Drink",
  "Sleep",
  "Bathroom",
  "Practical",
  "Comfort",
  "Need to Know",
  "Accessibility",
];

const normalizeRoomAmenityText = (value) => {
  const text = String(value || "").replace(/\s+/g, " ").trim().replace(/[.]+$/, "");
  if (!text) return "";
  if (/^cable channels$/i.test(text)) return "Television";
  if (/^climate-controlled air conditioning$/i.test(text)) {
    return "In-room climate control (air conditioning)";
  }
  return text;
};

const parseRoomDescriptionAmenities = (description) => {
  const raw = String(description || "").replace(/\s+/g, " ").trim();
  if (!raw) return [];

  let normalized = raw;
  ROOM_DESCRIPTION_SECTION_LABELS.forEach((label) => {
    normalized = normalized.replace(
      new RegExp(`\\s*${escapeRegExp(label)}\\s*-\\s*`, "gi"),
      `|||${label}:::`,
    );
  });
  normalized = normalized.replace(/\s+(Non-Smoking|Smoking)\b/gi, "|||$1");

  return normalized
    .split("|||")
    .slice(1)
    .flatMap((section) => {
      const [label, body = ""] = section.split(":::");
      const normalizedLabel = normalizeRoomAmenityText(label);
      if (!body && /^(non-smoking|smoking)$/i.test(normalizedLabel)) {
        return [normalizedLabel];
      }
      return body
        .split(/,|;|\band\b/gi)
        .map(normalizeRoomAmenityText)
        .filter(Boolean);
    });
};

const getRoomAmenities = (roomMeta, roomInfo = {}) =>
  dedupeStrings([
    ...(Array.isArray(roomMeta?.fcs) ? roomMeta.fcs : []),
    ...(Array.isArray(roomMeta?.am) ? roomMeta.am.map((item) => item?.name || item) : []),
    ...(Array.isArray(roomMeta?.rexb?.BENEFIT)
      ? roomMeta.rexb.BENEFIT.flatMap((item) => item?.values || [])
      : []),
    ...parseRoomDescriptionAmenities(roomMeta?.des || roomInfo?.des || roomMeta?.radi?.des || ""),
  ]);

const getRoomMealBasis = (option, roomInfo) => option?.mb || roomInfo?.mb || "Room Only";

const getOptionPanRequired = (hotelInfo, option, optionIndex) => {
  if (hotelInfo?.panRequired === true) return true;
  if (Array.isArray(hotelInfo?.filters?.panRequired)) {
    return hotelInfo.filters.panRequired.includes(optionIndex) ||
      hotelInfo.filters.panRequired.includes(option?.id)
      ? true
      : false;
  }
  return false;
};

const getOptionPanOptional = (hotelInfo, option, optionIndex) => {
  if (Array.isArray(hotelInfo?.filters?.panNotRequired)) {
    return hotelInfo.filters.panNotRequired.includes(optionIndex) ||
      hotelInfo.filters.panNotRequired.includes(option?.id)
      ? true
      : false;
  }
  return !getOptionPanRequired(hotelInfo, option, optionIndex);
};

const getOptionTotalPrice = (option, roomInfo) =>
  Number(option?.totalPrice ?? option?.tp ?? roomInfo?.totalPrice ?? roomInfo?.tp ?? 0);

const getOptionNightlyPrice = (option, roomInfo, nights) => {
  const direct = Number(option?.nightlyPrice ?? roomInfo?.nightlyPrice ?? 0);
  if (Number.isFinite(direct) && direct > 0) return direct;
  const total = getOptionTotalPrice(option, roomInfo);
  return total > 0 ? total / Math.max(1, nights) : 0;
};

const normalizeRoomOption = (option, optionIndex, hotelInfo, nights) => {
  const roomInfo = option?.roomInfos?.[0] || option?.ris?.[0] || {};
  const roomMeta = getRoomMetadata(hotelInfo, roomInfo);
  const images = getRoomImages(roomMeta);
  const amenities = getRoomAmenities(roomMeta, roomInfo);
  const totalPrice = getOptionTotalPrice(option, roomInfo);
  const nightlyPrice = getOptionNightlyPrice(option, roomInfo, nights);
  const mealBasis = getRoomMealBasis(option, roomInfo);
  const cancellation = option?.cnp || roomInfo?.cnp || {};
  const roomName = roomInfo?.srn || roomInfo?.rt || roomInfo?.rc || "Room";
  const supplierRoomType = roomInfo?.rc || roomInfo?.rt || roomName;

  return {
    id: String(option?.id || option?.optionId || `${optionIndex}`),
    optionIndex,
    roomId: String(roomInfo?.id || roomInfo?.rid || roomMeta?.rid || `${optionIndex}`),
    roomName,
    supplierRoomType,
    mealBasis,
    totalPrice: Number.isFinite(totalPrice) && totalPrice > 0 ? totalPrice : null,
    nightlyPrice: Number.isFinite(nightlyPrice) && nightlyPrice > 0 ? nightlyPrice : null,
    currency: option?.currency || option?.sc || roomInfo?.currency || "INR",
    cancellation,
    cancellationLabel: getCancellationLabel(cancellation),
    cancellationPenalties: getCancellationPenalties(cancellation),
    refundable: cancellation?.ifra === true || cancellation?.isRefundable === true,
    nonRefundable: cancellation?.inra === true,
    panRequired: getOptionPanRequired(hotelInfo, option, optionIndex),
    panOptional: getOptionPanOptional(hotelInfo, option, optionIndex),
    passportRequired: Boolean(hotelInfo?.passportRequired),
    adults: Number(roomInfo?.adt || 0),
    children: Number(roomInfo?.chd || 0),
    bedSummary: getRoomBedSummary(roomMeta),
    guestSummary: getRoomGuestSummary(roomMeta, roomInfo),
    images,
    image: images[0]?.url || "",
    amenities,
    view: Array.isArray(roomMeta?.vw)
      ? roomMeta.vw.join(", ")
      : Array.isArray(roomMeta?.radi?.vi)
        ? roomMeta.radi.vi.join(", ")
        : "",
    raw: option,
    roomInfo,
    roomMeta,
  };
};

const extractDetailHotelRoot = (payload) =>
  payload?.searchResult?.hotelInfos?.[0] ||
  payload?.data?.searchResult?.hotelInfos?.[0] ||
  payload?.hotel ||
  payload?.data?.hotel ||
  payload?.searchResult?.hotel ||
  payload?.hotelInfos?.[0] ||
  null;

const extractDetailMeta = (payload) => ({
  searchId:
    payload?.metaData?.searchId ||
    payload?.data?.metaData?.searchId ||
    payload?.searchQuery?.searchId ||
    payload?.id ||
    "",
  requestId:
    payload?.metaData?.requestId ||
    payload?.data?.metaData?.requestId ||
    payload?.requestId ||
    payload?.id ||
    "",
});

// Removed old SearchBar component - now using HotelSearchBar from HotelSearchBar.jsx

function ResultHeader({
  destination,
  hotelCount,
  sortOrder,
  setSortOrder,
  viewMode,
  setViewMode,
  favoritesOnly,
  setFavoritesOnly,
  onOpenMobileFilters,
  onSortChange,
}) {
  const handleSortChange = (e) => {
    const newSortOrder = e.target.value;
    setSortOrder(newSortOrder);
    if (onSortChange) {
      onSortChange(newSortOrder);
    }
  };

  return (
    <div className="hotel-results-header">
      <div className="hotel-breadcrumb-row">
        <span className="hotel-breadcrumb-text">Home Hotels  {destination}</span>
      </div>
      
      <div className="hotel-controls-row">
        <div className="hotel-controls-left">
          <div className="hotel-sort-dropdown">
            <span className="hotel-sort-label">Sort By:</span>
            <select 
              className="hotel-sort-select" 
              value={sortOrder} 
              onChange={handleSortChange}
            >
              <option value="popularity">Most Popular</option>
              <option value="priceLowToHigh">Price (Lowest first)</option>
              <option value="priceHighToLow">Price (Highest first)</option>
              <option value="starRatingHighToLow">Star Rating (High to Low)</option>
            </select>
          </div>
          
          <div className="hotel-results-text">
            Showing {hotelCount} hotels for <strong>{toTitleCase(destination)}</strong>
          </div>
        </div>

        <div className="hotel-controls-right">
          <button
            type="button"
            className="hotel-mobile-filter-btn"
            onClick={onOpenMobileFilters}
          >
            Filters
          </button>
          
          <button
            type="button"
            className={`hotel-view-btn ${viewMode === "grid" ? "active" : ""}`}
            onClick={() => setViewMode("grid")}
          >
            Grid View
          </button>
          
          <button
            type="button"
            className={`hotel-view-btn ${viewMode === "list" ? "active" : ""}`}
            onClick={() => setViewMode("list")}
          >
            List View
          </button>
          
          <button
            type="button"
            className={`hotel-favorites-btn ${favoritesOnly ? "active" : ""}`}
            onClick={() => setFavoritesOnly((prev) => !prev)}
          >
            ❤️ View Favourites
          </button>
        </div>
      </div>
    </div>
  );
}

function FilterChips({ chips, onRemove, onClearAll }) {
  if (chips.length === 0) return null;

  return (
    <div className="hotel-filter-chips">
      {chips.map((chip) => (
        <span key={`${chip.group}-${chip.value}`} className="hotel-chip">
          {chip.label}
          <button type="button" onClick={() => onRemove(chip.group, chip.value)}>
            <X size={13} />
          </button>
        </span>
      ))}
      <span className="hotel-chip">
        Clear all
        <button type="button" onClick={onClearAll}>
          <X size={13} />
        </button>
      </span>
    </div>
  );
}

function FilterSkeleton() {
  return (
    <div className="hotel-sidebar-card">
      <div className="hotel-sidebar-head">
        <div className="hotel-filter-skeleton" style={{ width: 90, height: 18 }} />
        <div className="hotel-filter-skeleton" style={{ width: 56, height: 14 }} />
      </div>
      <div style={{ padding: 18 }}>
        {Array.from({ length: 6 }).map((_, index) => (
          <div key={index} style={{ marginBottom: 22 }}>
            <div className="hotel-filter-skeleton" style={{ width: "55%", height: 16, marginBottom: 12 }} />
            {Array.from({ length: 4 }).map((__, optionIndex) => (
              <div
                key={optionIndex}
                className="hotel-filter-skeleton"
                style={{ width: "100%", height: 14, marginBottom: 10 }}
              />
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}

function HotelFilterSidebar({
  filterGroups,
  appliedFilters,
  toggleFilter,
  clearAllFilters,
  favoritesOnly,
  setFavoritesOnly,
  hotelNameQuery,
  setHotelNameQuery,
}) {
  const [collapsed, setCollapsed] = useState({});
  const [expanded, setExpanded] = useState({});

  const INITIAL_ITEMS_COUNT = 5; // Show first 5 items, then "View More"

  const toggleExpanded = (groupKey) => {
    setExpanded(prev => ({ ...prev, [groupKey]: !prev[groupKey] }));
  };

  // Calculate total applied filters count
  const getAppliedFiltersCount = () => {
    let count = 0;
    Object.entries(appliedFilters).forEach(([key, value]) => {
      if (key === "hotelName" && String(value || "").trim()) {
        count += 1;
      } else if (Array.isArray(value)) {
        count += value.length;
      }
    });
    if (favoritesOnly) count += 1;
    return count;
  };

  // Get applied filter chips for display
  const getAppliedFilterChips = () => {
    const chips = [];
    
    Object.entries(appliedFilters).forEach(([group, value]) => {
      if (group === "hotelName" && String(value || "").trim()) {
        chips.push({ 
          group, 
          value, 
          label: `Hotel: ${value}`,
          onRemove: () => setHotelNameQuery("")
        });
      } else if (Array.isArray(value)) {
        value.forEach((item) => {
          const filterGroup = filterGroups.find((fg) => fg.key === group);
          const option = filterGroup?.options.find((opt) => opt.value === item);
          const label = option?.label || item;
          chips.push({ 
            group, 
            value: item, 
            label,
            onRemove: () => toggleFilter(group, item)
          });
        });
      }
    });

    if (favoritesOnly) {
      chips.push({ 
        group: "onlyFavorites", 
        value: "1", 
        label: "Favourites only",
        onRemove: () => setFavoritesOnly(false)
      });
    }

    return chips;
  };

  const appliedFiltersCount = getAppliedFiltersCount();
  const appliedFilterChips = getAppliedFilterChips();

  return (
    <div className="hotel-sidebar-card">
      <div className="hotel-sidebar-head">
        <div className="hotel-sidebar-title">
          {appliedFiltersCount > 0 ? (
            <>
              <span className="filter-active-badge">{appliedFiltersCount}</span>
              Active Filter{appliedFiltersCount !== 1 ? 's' : ''}
            </>
          ) : (
            'Filters'
          )}
        </div>
      </div>

      <div className="hotel-sidebar-scroll">

      <div className="hotel-filter-block">
        <div className="hotel-filter-content-static">
          <input
            className="hotel-filter-search"
            placeholder="🔍 Select by Hotel Name"
            value={hotelNameQuery}
            onChange={(e) => setHotelNameQuery(e.target.value)}
          />
        </div>
      </div>

      {appliedFilterChips.length > 0 && (
        <div className="hotel-filter-block">
          <div className="hotel-applied-filters-header">
            <span className="hotel-applied-filters-title">Applied Filters</span>
            <button 
              type="button" 
              className="hotel-clear-filters-btn"
              onClick={() => {
                clearAllFilters();
                setFavoritesOnly(false);
                setHotelNameQuery("");
              }}
            >
              Clear Filters
            </button>
          </div>
          <div className="hotel-applied-filters-chips">
            {appliedFilterChips.map((chip, index) => (
              <div key={`${chip.group}-${chip.value}-${index}`} className="hotel-applied-filter-chip">
                <span>{chip.label}</span>
                <button 
                  type="button" 
                  className="hotel-applied-filter-remove"
                  onClick={chip.onRemove}
                >
                  ×
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="hotel-filter-block">
        <div className="hotel-filter-option">
          <label>
            <input
              type="checkbox"
              checked={favoritesOnly}
              onChange={() => setFavoritesOnly((prev) => !prev)}
            />
            <span>View favourites only</span>
          </label>
        </div>
      </div>

      {filterGroups.map((group) => {
        const isExpanded = expanded[group.key];
        const shouldShowViewMore = group.options.length > INITIAL_ITEMS_COUNT;
        const visibleOptions = isExpanded ? group.options : group.options.slice(0, INITIAL_ITEMS_COUNT);
        const remainingCount = group.options.length - INITIAL_ITEMS_COUNT;

        return (
          <div className="hotel-filter-block" key={group.key}>
            <button
              type="button"
              className="hotel-filter-toggle"
              onClick={() =>
                setCollapsed((prev) => ({ ...prev, [group.key]: !prev[group.key] }))
              }
            >
              <span>{group.name}</span>
              <span>{collapsed[group.key] ? "+" : "−"}</span>
            </button>
            {!collapsed[group.key] ? (
              <div className="hotel-filter-content-expandable">
                {visibleOptions.map((option) => (
                  <div className="hotel-filter-option" key={`${group.key}-${option.value}`}>
                    <label>
                      <input
                        type="checkbox"
                        checked={(appliedFilters[group.key] || []).includes(option.value)}
                        onChange={() => toggleFilter(group.key, option.value)}
                      />
                      <span>{option.label}</span>
                    </label>
                    <span className="hotel-filter-count">{option.count ? `(${option.count})` : ""}</span>
                  </div>
                ))}
                {shouldShowViewMore && (
                  <button
                    type="button"
                    className="hotel-filter-view-more"
                    onClick={() => toggleExpanded(group.key)}
                  >
                    {isExpanded ? 'View Less' : `View More (${remainingCount})`}
                  </button>
                )}
              </div>
            ) : null}
          </div>
        );
      })}
      </div>
    </div>
  );
}

function HotelCardSkeleton() {
  return (
    <div className="hotel-card">
      <div className="hotel-skeleton-card" style={{ aspectRatio: "16 / 10" }} />
      <div className="hotel-card-body">
        <div className="hotel-skeleton-card" style={{ width: "72%", height: 22 }} />
        <div className="hotel-skeleton-card" style={{ width: "48%", height: 14 }} />
        <div className="hotel-skeleton-card" style={{ width: "100%", height: 14 }} />
        <div className="hotel-skeleton-card" style={{ width: "86%", height: 14 }} />
        <div className="hotel-skeleton-card" style={{ width: "54%", height: 34, marginTop: 12 }} />
      </div>
    </div>
  );
}

function renderStars(count) {
  return Array.from({ length: Math.max(0, Math.min(5, Number(count) || 0)) }).map((_, index) => (
    <Star key={index} size={14} fill="currentColor" />
  ));
}

function HotelCard({ hotel, onClick }) {
  const images = hotel.images?.length ? hotel.images : hotel.image ? [hotel.image] : [];
  const [activeImageIndex, setActiveImageIndex] = useState(0);

  useEffect(() => {
    setActiveImageIndex(0);
  }, [hotel.id]);

  const activeImage = images[activeImageIndex] || "";

  const handlePrevImage = (event) => {
    event.stopPropagation();
    setActiveImageIndex((prev) => (prev === 0 ? images.length - 1 : prev - 1));
  };

  const handleNextImage = (event) => {
    event.stopPropagation();
    setActiveImageIndex((prev) => (prev === images.length - 1 ? 0 : prev + 1));
  };

  return (
    <div className="hotel-card" onClick={onClick}>
      <div className="hotel-image-container">
        {activeImage ? (
          <img
            className="hotel-image"
            src={activeImage}
            alt={`${hotel.name} image ${activeImageIndex + 1}`}
          />
        ) : (
          <div className="hotel-image-placeholder">
            <BedDouble size={26} strokeWidth={1.5} />
            <span>Photo coming soon</span>
          </div>
        )}
        
        <div className="image-count-badge">{activeImageIndex + 1}/{images.length || 1}</div>
        
        {images.length > 1 && (
          <>
            <button
              type="button"
              className="image-nav-btn prev"
              onClick={handlePrevImage}
            >
              ‹
            </button>
            <button
              type="button"
              className="image-nav-btn next"
              onClick={handleNextImage}
            >
              ›
            </button>
          </>
        )}
        
      </div>

      <div className="hotel-content">
        <div className="hotel-header">
          <div className="hotel-title-section">
            <h4 className="hotel-name">{hotel.name}</h4>
            <div className="hotel-location">{hotel.location || "Location unavailable"}</div>
          </div>
          <div className="hotel-rating">
            {renderStars(hotel.starRating)}
          </div>
        </div>

        <div className="hotel-inclusion">
          • {hotel.priceInfo.mealBasis}
        </div>

        <div className="hotel-facilities">
          {hotel.amenities.length > 0
            ? hotel.amenities.slice(0, 3).map((amenity, index) => {
                const amenityText = typeof amenity === 'object' && amenity !== null 
                  ? (amenity.name || amenity.nm || "Amenity")
                  : String(amenity || 'Amenity');
                return amenityText;
              }).join(" | ")
            : "Standard Amenities"}
        </div>

        <div className="hotel-pricing">
          <div className="price-per-night">
            {hotel.priceInfo.nightlyPrice
              ? `${formatMoney(hotel.priceInfo.nightlyPrice, hotel.priceInfo.currency)}/night`
              : "Price on request"}
          </div>
          <div className="total-price">
            {hotel.priceInfo.totalPrice
              ? formatMoney(hotel.priceInfo.totalPrice, hotel.priceInfo.currency)
              : "—"} <span className="total-label">Total</span>
          </div>
          <div className="tax-info">(Incl. of all taxes)</div>
        </div>
      </div>
    </div>
  );
}

function HotelListCard({ hotel, onClick }) {
  const images = hotel.images?.length ? hotel.images : hotel.image ? [hotel.image] : [];
  const [activeImageIndex, setActiveImageIndex] = useState(0);

  useEffect(() => {
    setActiveImageIndex(0);
  }, [hotel.id]);

  const activeImage = images[activeImageIndex] || "";

  const handlePrevImage = (event) => {
    event.stopPropagation();
    setActiveImageIndex((prev) => (prev === 0 ? images.length - 1 : prev - 1));
  };

  const handleNextImage = (event) => {
    event.stopPropagation();
    setActiveImageIndex((prev) => (prev === images.length - 1 ? 0 : prev + 1));
  };

  return (
    <div className="hotel-card" onClick={onClick}>
      <div className="hotel-list-card">
        <div className="hotel-list-image-wrap">
          {activeImage ? (
            <img
              className="hotel-card-image"
              src={activeImage}
              alt={`${hotel.name} image ${activeImageIndex + 1}`}
            />
          ) : null}
          <span className="hotel-image-pill">{`${activeImageIndex + 1}/${images.length || 1}`}</span>
          {images.length > 1 ? (
            <>
              <button
                type="button"
                className="hotel-image-nav left"
                aria-label={`Show previous image for ${hotel.name}`}
                onClick={handlePrevImage}
              >
                <ChevronLeft size={18} />
              </button>
              <button
                type="button"
                className="hotel-image-nav right"
                aria-label={`Show next image for ${hotel.name}`}
                onClick={handleNextImage}
              >
                <ChevronRight size={18} />
              </button>
            </>
          ) : null} 
        </div>

        <div className="hotel-list-main">
          <div className="hotel-title-block">
            <h4 className="hotel-name">{hotel.name}</h4>
            <div className="hotel-location">
              <MapPin size={14} />
              <span>{hotel.location || "Location unavailable"}</span>
            </div>
            <div className="hotel-stars">{renderStars(hotel.starRating)}</div>
          </div>

          <div className="hotel-meal-line">{hotel.priceInfo.mealBasis}</div>

          <div className="hotel-amenities">
            {hotel.amenities.length > 0
              ? hotel.amenities.map((amenity, index) => {
                  const amenityText = typeof amenity === 'object' && amenity !== null 
                    ? (amenity.name || amenity.nm || JSON.stringify(amenity))
                    : String(amenity || '');
                  return (
                    <span key={`${amenityText}-${index}`} className="hotel-amenity-chip">
                      {amenityText}
                    </span>
                  );
                })
              : <span className="hotel-amenity-chip">Amenities unavailable</span>}
          </div>
        </div>

        <div className="hotel-list-side">
          <div className="hotel-rating-box">
            {hotel.userRating ? (
              <>
                <div className="hotel-rating-badge">
                  <Star size={12} fill="currentColor" />
                  <span>{hotel.userRating}</span>
                </div>
                <div className="hotel-rating-meta">
                  <div>{hotel.userRatingLabel}</div>
                  <div>{hotel.ratingCount ? `(${hotel.ratingCount} Ratings)` : ""}</div>
                </div>
              </>
            ) : hotel.starRating ? (
              <div className="hotel-rating-meta">
                <div>{hotel.starRating} Star Hotel</div>
              </div>
            ) : (
              <div className="hotel-rating-meta">No rating</div>
            )}
          </div>

          <div className="hotel-price-meta" style={{ textAlign: "right" }}>
            <div className="hotel-nightly">
              {hotel.priceInfo.nightlyPrice
                ? `${formatMoney(hotel.priceInfo.nightlyPrice, hotel.priceInfo.currency)} /night`
                : "Nightly price unavailable"}
            </div>
            <div className="hotel-total-inline" style={{ justifyContent: "flex-end" }}>
              <div className="hotel-total-price">
              {hotel.priceInfo.totalPrice
                ? formatMoney(hotel.priceInfo.totalPrice, hotel.priceInfo.currency, true)
                : "—"}
            </div>
              <div className="hotel-total-caption">Total</div>
            </div>
            <div className="hotel-tax-copy">Incl. of all taxes</div>
          </div>

          <button type="button" className="hotel-card-cta">
            View Details
          </button>
        </div>
      </div>
    </div>
  );
}

function EmptyState({ onClearAll }) {
  return (
    <div className="hotel-empty">
      <SlidersHorizontal size={26} color="#ed1173" />
      <div className="hotel-empty-title">No hotels match these filters</div>
      <div className="hotel-empty-copy">
        Try clearing a few filters or broaden your destination and price range.
      </div>
      <Button
        className="hotel-card-cta mt-3"
        style={{ width: "auto" }}
        onClick={onClearAll}
      >
        Clear all filters
      </Button>
    </div>
  );
}

function ErrorState({ onRetry }) {
  return (
    <div className="hotel-error">
      <X size={26} color="#ed1173" />
      <div className="hotel-error-title">Unable to load hotels</div>
      <div className="hotel-error-copy">
        Something went wrong while refreshing these results.
      </div>
      <Button
        className="hotel-card-cta mt-3"
        style={{ width: "auto" }}
        onClick={onRetry}
      >
        Retry
      </Button>
    </div>
  );
}

export default function HotelbedsHotelsPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { hotelId } = useParams();

  const initialPayload = location.state?.hotelSearchPayload || null;
  const initialResponse = location.state?.hotelSearchResponse || null;
  const initialSuggestion = location.state?.selectedHotelSuggestion || null;
  const [searchPayload, setSearchPayload] = useState(initialPayload);
  const [selectedSuggestion, setSelectedSuggestion] = useState(initialSuggestion);

  const [searchResponse, setSearchResponse] = useState(initialResponse);
  const [loadedHotels, setLoadedHotels] = useState(() =>
    extractHotels(initialResponse, initialPayload),
  );
  const [filterGroups, setFilterGroups] = useState([]);
  const [filtersLoading, setFiltersLoading] = useState(false);
  const [resultsLoading, setResultsLoading] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [resultsError, setResultsError] = useState("");
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailResponse, setDetailResponse] = useState(null);
  const [activeOption, setActiveOption] = useState(null);
  const [roomModalOpen, setRoomModalOpen] = useState(false);
  const [sortOrder, setSortOrder] = useState("popularity");
  const [viewMode, setViewMode] = useState("grid");
  const [favoritesOnly, setFavoritesOnly] = useState(
    Boolean(searchPayload?.appliedFilters?.onlyFavorites),
  );
  const [showMobileFilters, setShowMobileFilters] = useState(false);
  const [appliedFilters, setAppliedFilters] = useState(() =>
    sanitizeAppliedFilters(searchPayload?.appliedFilters || {}),
  );
  const [hotelNameDraft, setHotelNameDraft] = useState(
    () => (searchPayload?.appliedFilters?.hotelName || ""),
  );
  const [hasMoreResults, setHasMoreResults] = useState(true);
  const [lastHotelId, setLastHotelId] = useState(() =>
    extractLastHotelId(initialResponse, extractHotels(initialResponse, initialPayload)),
  );
  const loadMoreRef = useRef(null);
  const appendRequestRef = useRef(false);

  const hotels = loadedHotels;
  const activePayload = searchPayload || initialPayload;
  const activeSuggestion = selectedSuggestion || initialSuggestion;
  const selectedHotel = useMemo(
    () => hotels.find((hotel) => hotel.id === hotelId) || null,
    [hotelId, hotels],
  );

  const hotelNameQuery = hotelNameDraft || "";

  useEffect(() => {
    setHotelNameDraft(appliedFilters.hotelName || "");
  }, [appliedFilters.hotelName]);

  useEffect(() => {
    const timeoutId = window.setTimeout(() => {
      setAppliedFilters((prev) => {
        const nextHotelName = hotelNameDraft || "";
        if ((prev.hotelName || "") === nextHotelName) return prev;
        return { ...prev, hotelName: nextHotelName };
      });
    }, 250);

    return () => window.clearTimeout(timeoutId);
  }, [hotelNameDraft]);

  useEffect(() => {
    if (!activePayload) return;
    setFiltersLoading(true);
    const groups = buildLocalFilterGroups(loadedHotels);
    setFilterGroups(groups);
    setAppliedFilters((prev) => {
      const next = sanitizeAppliedFilters(prev, groups);
      return areAppliedFiltersEqual(prev, next) ? prev : next;
    });
    setFiltersLoading(false);
  }, [activePayload, searchResponse, loadedHotels]);

  useEffect(() => {
    if (!activePayload || hotelId) return undefined;

    let active = true;
    appendRequestRef.current = false;
    setResultsLoading(true);
    setResultsError("");

    searchHotels(buildSearchPayload(activePayload, searchResponse, sortOrder, ""))
      .then((response) => {
        if (!active) return;
        const nextHotels = extractHotels(response, activePayload);
        const nextLastHotelId = extractLastHotelId(response, nextHotels);
        const nextHotelCount = extractHotelCount(response, nextHotels.length);
        setSearchResponse(response);
        setLoadedHotels(nextHotels);
        setLastHotelId(nextLastHotelId);
        setHasMoreResults(Boolean(nextLastHotelId) && nextHotels.length < nextHotelCount);
      })
      .catch((error) => {
        console.error(getErrorMessage(error, "Unable to refresh hotel results"));
        if (active) setResultsError("Unable to refresh hotel results");
      })
      .finally(() => {
        if (active) setResultsLoading(false);
      });

    return () => {
      active = false;
    };
  }, [activePayload, hotelId, sortOrder]);

  useEffect(() => {
    if (!activePayload || hotelId || !hasMoreResults || !lastHotelId) return undefined;

    const node = loadMoreRef.current;
    if (!node) return undefined;

    const observer = new IntersectionObserver(
      (entries) => {
        const [entry] = entries;
        if (!entry?.isIntersecting) return;
        if (resultsLoading || loadingMore || appendRequestRef.current) return;

        let active = true;
        appendRequestRef.current = true;
        setLoadingMore(true);

        searchHotels(
          buildSearchPayload(activePayload, searchResponse, sortOrder, lastHotelId),
        )
          .then((response) => {
            if (!active) return;
            const incomingHotels = extractHotels(response, activePayload);
            setSearchResponse(response);
            setLoadedHotels((prev) => {
              const mergedHotels = mergeHotels(prev, incomingHotels);
              const nextLastHotelId = extractLastHotelId(response, incomingHotels);
              const totalCount = extractHotelCount(response, mergedHotels.length);
              setLastHotelId(nextLastHotelId);
              setHasMoreResults(
                Boolean(nextLastHotelId) &&
                  incomingHotels.length > 0 &&
                  mergedHotels.length < totalCount,
              );
              return mergedHotels;
            });
          })
          .catch((error) => {
            console.error(getErrorMessage(error, "Unable to load more hotel results"));
          })
          .finally(() => {
            if (active) setLoadingMore(false);
            appendRequestRef.current = false;
          });
      },
      { rootMargin: "300px 0px" },
    );

    observer.observe(node);

    return () => {
      observer.disconnect();
    };
  }, [
    hasMoreResults,
    hotelId,
    activePayload,
    lastHotelId,
    loadingMore,
    resultsLoading,
    searchResponse,
    sortOrder,
  ]);
  useEffect(() => {
    if (!hotelId || !selectedHotel || !activePayload) return undefined;

    let active = true;
    setDetailLoading(true);
    getHotelDetail(buildDetailPayload(selectedHotel, activePayload, searchResponse))
      .then((response) => {
        if (!active) return;
        setDetailResponse(response);
      })
      .catch((error) => {
        console.error(getErrorMessage(error, "Unable to load hotel detail"));
        if (active) setDetailResponse(null);
      })
      .finally(() => {
        if (active) setDetailLoading(false);
      });

    return () => {
      active = false;
    };
  }, [activePayload, hotelId, searchResponse, selectedHotel]);

  const clearAllFilters = () => {
    setAppliedFilters(sanitizeAppliedFilters(defaultFilters(), filterGroups));
    setHotelNameDraft("");
    setFavoritesOnly(false);
  };

  const toggleFilter = (group, value) => {
    setAppliedFilters((prev) => {
      const currentValues = Array.isArray(prev[group]) ? prev[group] : [];
      const exists = currentValues.includes(value);
      return {
        ...prev,
        [group]: exists
          ? currentValues.filter((item) => item !== value)
          : [...currentValues, value],
      };
    });
  };

  const removeFilterChip = (group, value) => {
    if (group === "onlyFavorites") {
      setFavoritesOnly(false);
      return;
    }
    if (group === "hotelName") {
      setHotelNameDraft("");
      setAppliedFilters((prev) => ({ ...prev, hotelName: "" }));
      return;
    }
    toggleFilter(group, value);
  };

  const selectedFilterChips = useMemo(() => {
    const chips = [];

    Object.entries(appliedFilters).forEach(([group, value]) => {
      if (group === "hotelName" && String(value || "").trim()) {
        chips.push({ group, value, label: `Hotel: ${value}` });
      } else if (Array.isArray(value)) {
        value.forEach((item) => {
          const label =
            filterGroups
              .find((filterGroup) => filterGroup.key === group)
              ?.options.find((option) => option.value === item)?.label || item;
          chips.push({ group, value: item, label });
        });
      }
    });

    if (favoritesOnly) {
      chips.push({ group: "onlyFavorites", value: "1", label: "Favourites only" });
    }

    return chips;
  }, [appliedFilters, favoritesOnly, filterGroups]);

  const visibleHotels = useMemo(() => {
    let nextHotels = [...hotels];

    if (hotelNameQuery.trim()) {
      const query = hotelNameQuery.trim().toLowerCase();
      nextHotels = nextHotels.filter((hotel) => hotel.name.toLowerCase().includes(query));
    }

    if (favoritesOnly) {
      nextHotels = nextHotels.filter((hotel) => hotel.userFavourite);
    }

    const selectedRatings = Array.isArray(appliedFilters?.ratings) ? appliedFilters.ratings : [];
    if (selectedRatings.length > 0) {
      nextHotels = nextHotels.filter((hotel) =>
        selectedRatings.includes(String(Math.round(Number(hotel.starRating || 0)))),
      );
    }

    const selectedPropertyTypes = Array.isArray(appliedFilters?.propertyType)
      ? appliedFilters.propertyType
      : [];
    if (selectedPropertyTypes.length > 0) {
      nextHotels = nextHotels.filter((hotel) =>
        selectedPropertyTypes.includes(String(hotel.propertyType || "")),
      );
    }

    const selectedMealTypes = Array.isArray(appliedFilters?.mealType) ? appliedFilters.mealType : [];
    if (selectedMealTypes.length > 0) {
      nextHotels = nextHotels.filter((hotel) =>
        selectedMealTypes.includes(String(hotel.priceInfo?.mealBasis || "")),
      );
    }

    const selectedCancellation = Array.isArray(appliedFilters?.cancellationPolicy)
      ? appliedFilters.cancellationPolicy
      : [];
    if (selectedCancellation.length > 0) {
      nextHotels = nextHotels.filter((hotel) => {
        const code = hotel.priceInfo?.isRefundable ? "REFUNDABLE" : "NON_REFUNDABLE";
        return selectedCancellation.includes(code);
      });
    }

    const selectedAmenities = Array.isArray(appliedFilters?.amenities) ? appliedFilters.amenities : [];
    if (selectedAmenities.length > 0) {
      nextHotels = nextHotels.filter((hotel) => {
        const amenitySet = new Set((hotel.amenities || []).map((item) => String(item || "").toLowerCase()));
        return selectedAmenities.some((item) => amenitySet.has(String(item || "").toLowerCase()));
      });
    }

    const selectedPriceRanges = Array.isArray(appliedFilters?.priceRange) ? appliedFilters.priceRange : [];
    if (selectedPriceRanges.length > 0) {
      nextHotels = nextHotels.filter((hotel) => {
        const bucket = getPriceRangeBucket(hotel.priceInfo?.totalPrice || 0);
        return bucket && selectedPriceRanges.includes(bucket);
      });
    }

    return nextHotels;
  }, [favoritesOnly, hotelNameQuery, hotels, appliedFilters]);

  const destinationName =
    activeSuggestion?.displayName ||
    activePayload?.searchQuery?.searchCriteria?.searchRegionName ||
    "Hotels";

  const hotelCount =
    Number(
      searchResponse?.hotelCount ??
      searchResponse?.data?.hotelCount ??
      hotels.length,
    ) || hotels.length;

  const handleSortChange = (valueOrEvent) => {
    const nextSortOrder =
      typeof valueOrEvent === "string" ? valueOrEvent : valueOrEvent?.target?.value;
    if (!nextSortOrder || nextSortOrder === sortOrder) return;

    setSortOrder(nextSortOrder);
    trackSortAnalyticsEvent(nextSortOrder, activePayload, searchResponse, activeSuggestion);
  };

  const setHotelNameQuery = (value) => {
    setHotelNameDraft(value);
  };

  if (selectedHotel) {
    return (
      <HotelDetailsPage
        selectedHotel={selectedHotel}
        detailResponse={detailResponse}
        detailLoading={detailLoading}
        initialPayload={activePayload}
        initialSuggestion={activeSuggestion}
        onBackToResults={() => navigate("/hotels", { state: location.state })}
        activeOption={activeOption}
        roomModalOpen={roomModalOpen}
        setActiveOption={setActiveOption}
        setRoomModalOpen={setRoomModalOpen}
      />
    );
  }

  return (
    <div className="hotel-list-page">
      <div className="hotel-search-bar-container">
        <HotelSearchForm
          compact
          initialPayload={activePayload}
          initialSuggestion={activeSuggestion}
          onSearch={(nextPayload, response, selectedDestination) => {
            // Update the state with new search results
            setSearchPayload(nextPayload);
            setSelectedSuggestion(selectedDestination || null);
            setSearchResponse(response);
            const nextHotels = extractHotels(response, nextPayload);
            setLoadedHotels(nextHotels);
            const nextLastHotelId = extractLastHotelId(response, nextHotels);
            setLastHotelId(nextLastHotelId);
            const nextHotelCount = extractHotelCount(response, nextHotels.length);
            setHasMoreResults(Boolean(nextLastHotelId) && nextHotels.length < nextHotelCount);
          }}
        />
      </div>

      <div className="page-container">
        <div className="breadcrumb-row">
          <span className="breadcrumb-text">Home Hotels {destinationName}</span>

          <div className="top-controls">
          <div className="left-controls">
            <div className="sort-button">
              <span className="sort-label">Sort By:</span>
              <select 
                className="sort-select" 
                value={sortOrder} 
                onChange={handleSortChange}
              >
                <option value="popularity">Most Popular</option>
                <option value="priceLowToHigh">Price (Lowest first)</option>
                <option value="priceHighToLow">Price (Highest first)</option>
                <option value="starRatingHighToLow">Star Rating (High to Low)</option>
              </select>
            </div>
            
            <div className="result-count">
              Showing {hotelCount} hotels for <strong>{toTitleCase(destinationName)}</strong>
            </div>
          </div>

          <div className="right-controls">
            <button
              type="button"
              className="mobile-filter-btn"
              onClick={() => setShowMobileFilters(true)}
            >
              Filters
            </button>
            
            <button
              type="button"
              className={`view-btn ${viewMode === "grid" ? "active" : ""}`}
              onClick={() => setViewMode("grid")}
            >
              Grid View
            </button>
            
            <button
              type="button"
              className={`view-btn ${viewMode === "list" ? "active" : ""}`}
              onClick={() => setViewMode("list")}
            >
              List View
            </button>
            
            <button
              type="button"
              className={`favorites-btn ${favoritesOnly ? "active" : ""}`}
              onClick={() => setFavoritesOnly((prev) => !prev)}
            >
              ❤️ View Favourites
            </button>
          </div>
          </div>
        </div>

        {!activePayload ? (
          <div className="hotel-empty">
            <div className="hotel-empty-title">No hotel search loaded</div>
            <div className="hotel-empty-copy">
              Start from the honeymoon hotel search to view results here.
            </div>
          </div>
        ) : (
          <div className="content-layout">
            <aside className="filter-sidebar">
              <button className="see-on-map-btn">
                See on Map
              </button>
              
              {filtersLoading ? (
                <FilterSkeleton />
              ) : (
                <HotelFilterSidebar
                  filterGroups={filterGroups}
                  appliedFilters={appliedFilters}
                  toggleFilter={toggleFilter}
                  clearAllFilters={clearAllFilters}
                  favoritesOnly={favoritesOnly}
                  setFavoritesOnly={setFavoritesOnly}
                  hotelNameQuery={hotelNameQuery}
                  setHotelNameQuery={setHotelNameQuery}
                />
              )}
            </aside>

            <main className="hotel-results">
              <div className="section-title">Popular in {destinationName}</div>
              
              {resultsError ? (
                <ErrorState
                  onRetry={() =>
                    searchHotels(
                      buildSearchPayload(activePayload, searchResponse, sortOrder, ""),
                    ).then(setSearchResponse)
                  }
                />
              ) : resultsLoading && hotels.length === 0 ? (
                <div className={viewMode === "grid" ? "hotel-grid" : "hotel-list"}>
                  {Array.from({ length: viewMode === "grid" ? 6 : 4 }).map((_, index) => (
                    <HotelCardSkeleton key={index} />
                  ))}
                </div>
              ) : visibleHotels.length === 0 ? (
                <EmptyState onClearAll={clearAllFilters} />
              ) : viewMode === "grid" ? (
                <div className="hotel-grid">
                  {visibleHotels.map((hotel) => (
                    <HotelCard
                      key={hotel.id}
                      hotel={hotel}
                      onClick={() =>
                        navigate(`/hotels/${hotel.id}`, {
                          state: {
                            ...location.state,
                            hotelSearchResponse: searchResponse,
                          },
                        })
                      }
                    />
                  ))}
                </div>
              ) : (
                <div className="hotel-list">
                  {visibleHotels.map((hotel) => (
                    <HotelListCard
                      key={hotel.id}
                      hotel={hotel}
                      onClick={() =>
                        navigate(`/hotels/${hotel.id}`, {
                          state: {
                            ...location.state,
                            hotelSearchResponse: searchResponse,
                          },
                        })
                      }
                    />
                  ))}
                </div>
              )}
              {!resultsError && visibleHotels.length > 0 ? (
                <>
                  {loadingMore ? <div className="hotel-load-more">Loading more hotels...</div> : null}
                  {hasMoreResults ? <div ref={loadMoreRef} className="hotel-scroll-sentinel" /> : null}
                </>
              ) : null}
            </main>
          </div>
        )}
      </div>

      <Offcanvas
        show={showMobileFilters}
        onHide={() => setShowMobileFilters(false)}
        placement="start"
      >
        <Offcanvas.Header closeButton>
          <Offcanvas.Title>Filters</Offcanvas.Title>
        </Offcanvas.Header>
        <Offcanvas.Body style={{ padding: 0 }}>
          {filtersLoading ? (
            <div className="p-3">
              <FilterSkeleton />
            </div>
          ) : (
            <div className="p-3">
              <HotelFilterSidebar
                filterGroups={filterGroups}
                appliedFilters={appliedFilters}
                toggleFilter={toggleFilter}
                clearAllFilters={clearAllFilters}
                favoritesOnly={favoritesOnly}
                setFavoritesOnly={setFavoritesOnly}
                hotelNameQuery={hotelNameQuery}
                setHotelNameQuery={setHotelNameQuery}
              />
            </div>
          )}
        </Offcanvas.Body>
      </Offcanvas>
    </div>
  );
}
