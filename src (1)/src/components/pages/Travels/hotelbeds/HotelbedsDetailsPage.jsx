import { useEffect, useMemo, useRef, useState } from "react";
import { Button, Modal, Offcanvas } from "react-bootstrap";
import { useLocation, useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { toast } from "react-toastify";
import {
  BedDouble,
  Check,
  ChevronDown,
  ChevronRight,
  CircleHelp,
  ExternalLink,
  Filter,
  Heart,
  Images,
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
  confirmHotelBooking,
  createHotelPaymentOrder,
  downloadHotelReceipt,
  downloadHotelVoucher,
  getHotelStaticContent,
  getHotelBookingDetails,
  holdHotelBooking,
  reviewHotelBooking,
  searchHotels,
  suggestHotels,
  trackHotelAnalyticsEvent,
  trackTripjackAnalyticsEvent,
  verifyHotelPaymentAndBook,
} from "../../../../services/api/hotelApi";
import { formatDate as fmtDate, formatDateTime } from "../../../../utils/dateFormat";
import TripJackBookingReview from "./TripJackBookingReview";
import TripJackBookingStatus from "./TripJackBookingStatus";
import {
  saveBookingDraft,
  readBookingDraft,
  clearBookingDraft,
  mergeBookingForm,
  draftNeedsPan,
  loginRedirect,
} from "../../../../utils/bookingDraft";
import HotelSearchForm from "../honeymoon/components/HotelSearchForm";
import "./hotelbedsStyles.css";
import {
  buildAddressLabel,
  createCorrelationId,
  createInitialBookingForm,
  defaultFilters,
  delay,
  formatDate,
  formatMoney,
  getMealPlanOptions,
  getReviewPayloadFields,
  normalizeHotelDetails,
  normalizeReviewResponseForUi,
  normalizeImageItems,
  normalizeRoomOption,
  parseJsonSafely,
  validateBookingForm,
  normalizeAmount,
} from "./hotelbedsDetailHelpers";

// Wrapper for backward compatibility
function HotelSearchBarEditable({ payload, suggestion, onBackToSearch }) {
  const navigate = useNavigate();
  
  return (
    <HotelSearchForm
      compact
      initialPayload={payload}
      initialSuggestion={suggestion}
      onSearch={(nextPayload, response, selectedDestination) => {
        navigate("/hotels", {
          state: {
            hotelSearchPayload: nextPayload,
            hotelSearchResponse: response,
            selectedHotelSuggestion: selectedDestination,
          },
        });
      }}
    />
  );
}

function renderStars(count) {
  return Array.from({ length: Math.max(0, Math.min(5, Number(count) || 0)) }).map((_, index) => (
    <Star key={index} size={14} fill="currentColor" />
  ));
}

function loadRazorpayScript() {
  if (typeof window === "undefined") {
    return Promise.resolve(false);
  }

  if (window.Razorpay) {
    return Promise.resolve(true);
  }

  return new Promise((resolve) => {
    const existingScript = document.querySelector('script[src="https://checkout.razorpay.com/v1/checkout.js"]');
    if (existingScript) {
      existingScript.addEventListener("load", () => resolve(true), { once: true });
      existingScript.addEventListener("error", () => resolve(false), { once: true });
      return;
    }

    const script = document.createElement("script");
    script.src = "https://checkout.razorpay.com/v1/checkout.js";
    script.async = true;
    script.onload = () => resolve(true);
    script.onerror = () => resolve(false);
    document.body.appendChild(script);
  });
}

function extractOrderStatusFromBookingDetails(payload) {
  const value =
    payload?.bookingDetails?.order?.status ||
    payload?.bookingDetails?.orderStatus ||
    payload?.order?.status ||
    payload?.orderStatus ||
    "";
  return String(value || "").toUpperCase();
}

function HotelDetailsSkeleton() {
  return (
    <div className="hotel-detail-shell">
      <div className="hotel-detail-card">
        <div className="hotel-skeleton-card" style={{ width: "28%", height: 16, marginBottom: 16 }} />
        <div className="hotel-skeleton-card" style={{ width: "44%", height: 34, marginBottom: 12 }} />
        <div className="hotel-skeleton-card" style={{ width: "76%", height: 16, marginBottom: 20 }} />
        <div className="hotel-detail-gallery">
          <div className="hotel-skeleton-card" style={{ minHeight: 320 }} />
          <div className="hotel-detail-side-stack">
            <div className="hotel-skeleton-card" style={{ minHeight: 152 }} />
            <div className="hotel-skeleton-card" style={{ minHeight: 152 }} />
          </div>
        </div>
      </div>
      <div className="hotel-room-section-card">
        <div className="hotel-room-section-head">
          <div className="hotel-skeleton-card" style={{ width: 240, height: 26 }} />
          <div className="hotel-skeleton-card" style={{ width: 320, height: 42 }} />
        </div>
        <div style={{ padding: 22 }}>
          {Array.from({ length: 2 }).map((_, index) => (
            <div key={index} className="hotel-room-option">
              <div className="hotel-skeleton-card" style={{ minHeight: 220 }} />
              <div className="hotel-skeleton-card" style={{ minHeight: 220 }} />
              <div className="hotel-skeleton-card" style={{ minHeight: 220 }} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function RoomOptionSkeleton() {
  return (
    <div className="hotel-room-option">
      <div className="hotel-skeleton-card" style={{ minHeight: 220 }} />
      <div className="hotel-skeleton-card" style={{ minHeight: 220 }} />
      <div className="hotel-skeleton-card" style={{ minHeight: 220 }} />
    </div>
  );
}

function HotelHeader({ detailModel, onBackToResults, onEditMarkup, markupEnabled }) {
  const [showViewDropdown, setShowViewDropdown] = useState(false);
  const dropdownRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setShowViewDropdown(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <>
      <div className="hotel-detail-breadcrumb">
        {`Home > ${detailModel.cityName || "Hotels"} > ${detailModel.name}`}
      </div>

      <div className="hotel-detail-header-row mt-3">
        <div>
          <button type="button" className="hotel-inline-link mb-2" onClick={onBackToResults}>
            {"< Back to results"}
          </button>
          <h1 className="hotel-detail-title">{detailModel.name}</h1>
          {detailModel.starRating ? (
            <div className="hotel-stars mt-2">{renderStars(detailModel.starRating)}</div>
          ) : null}
          <div className="hotel-detail-address">
            <MapPin size={14} />
            <span>{detailModel.fullAddress || "Address unavailable"}</span>
          </div>
        </div>

        <div className="hotel-detail-actions">
          <div style={{ position: "relative" }} ref={dropdownRef}>
            {/* <button
              type="button"
              className="hotel-detail-view-btn"
              onClick={() => setShowViewDropdown(!showViewDropdown)}
            >
              <Images size={15} />
              View
              <ChevronDown size={15} />
            </button> */}
            {showViewDropdown && (
              <div className="hotel-view-dropdown">
                <button
                  type="button"
                  className="hotel-view-dropdown-item"
                  onClick={() => {
                    setShowViewDropdown(false);
                  }}
                >
                  <Check size={14} color={markupEnabled ? "#22a55a" : "transparent"} />
                  <span>With Markup</span>
                  <button
                    type="button"
                    className="hotel-inline-link"
                    style={{ marginLeft: "auto" }}
                    onClick={(e) => {
                      e.stopPropagation();
                      onEditMarkup();
                      setShowViewDropdown(false);
                    }}
                  >
                    Edit Markup
                  </button>
                </button>
                <button
                  type="button"
                  className="hotel-view-dropdown-item"
                  onClick={() => {
                    setShowViewDropdown(false);
                  }}
                >
                  <Check size={14} color={!markupEnabled ? "#22a55a" : "transparent"} />
                  <span>Without Markup</span>
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </>
  );
}

function HotelGallery({ images, hotelName, onOpenGallery }) {
  const primary = images[0]?.url || "";
  const sideOne = images[1]?.url || primary;
  const sideTwo = images[2]?.url || images[1]?.url || primary;
  const remaining = Math.max(0, images.length - 3);

  const renderImage = (url, alt, className, index) => (
    <button type="button" className={className} onClick={() => onOpenGallery(index)}>
      {url ? <img src={url} alt={alt} /> : <div className="hotel-card-image hotel-card-image--empty">Image not available</div>}
    </button>
  );

  return (
    <div className="hotel-detail-gallery">
      {renderImage(primary, hotelName, "hotel-detail-main-image", 0)}
      <div className="hotel-detail-side-stack">
        {renderImage(sideOne, hotelName, "hotel-detail-side-image", 1)}
        <div style={{ position: "relative" }}>
          {renderImage(sideTwo, hotelName, "hotel-detail-side-image", 2)}
          <button type="button" className="hotel-photo-overlay" onClick={() => onOpenGallery(0)}>
            <Images size={14} />
            {remaining > 0 ? `+${remaining} photos` : `${images.length || 0} photos`}
          </button>
        </div>
      </div>
    </div>
  );
}

function HotelBookingSummaryCard({
  option,
  roomSummary,
  onViewDetails,
  onBookNow,
  onViewAllRooms,
  hotelPanRequired,
  hotelPassportRequired,
  reviewLoadingOptionId,
}) {
  if (!option) return null;

  const isReviewing = reviewLoadingOptionId === option.id;

  return (
    <div className="hotel-detail-side hoteldetails__rightboxs">
      <div className="hotel-summary-card">
        <div className="d-flex justify-content-between gap-3 align-items-start">
          <div>
            <div className="hotel-summary-room">{option.roomName}</div>
            <div className="hotel-summary-subcopy">{roomSummary}</div>
          </div>
          {/* <button type="button" className="hotel-inline-link" onClick={() => onViewDetails(option)}>
            View details
          </button> */}
        </div>

        <ul className="hotel-summary-points">
          <li>{option.mealBasis}</li>
          <li>{option.panRequired || hotelPanRequired ? "PAN Required" : "PAN not Required"}</li>
          {option.passportRequired || hotelPassportRequired ? <li>Passport Required</li> : null}
        </ul>

        <div className="hotel-summary-price-row">
          <div>
            <div className="hotel-nightly mb-1">
              {option.nightlyPrice ? `${formatMoney(option.nightlyPrice, option.currency)} /night` : "Nightly price unavailable"}
            </div>
            <div className="hotel-summary-price">
              {option.totalPrice ? formatMoney(option.totalPrice, option.currency) : "Price unavailable"}
            </div>
            <div className="hotel-summary-subcopy mt-1">Total Price for 1 room</div>
          </div>
          <CircleHelp size={15} color="#6d7483" />
        </div>

        <button
          type="button"
          className="hotel-card-cta w-100 mt-3"
          onClick={() => onBookNow(option)}
          disabled={Boolean(reviewLoadingOptionId)}
        >
          {isReviewing ? "Reviewing..." : "Book Now"}
        </button>
      </div>

      <div className="hotel-summary-card">
        <div className="d-flex justify-content-between gap-3 align-items-center">
          <div>
            <div className="fw-bold fs-14">More options available</div>
            <div className="hotel-summary-subcopy mt-1">Compare all room types and inclusions</div>
          </div>
          <button type="button" className="hotel-detail-ghost-btn" onClick={onViewAllRooms}>
            View all rooms
          </button>
        </div>
      </div>

    </div>
  );
}

function HotelAboutSection({ aboutText, headline, onOpenModal, hasDetails }) {
  if (!aboutText && !headline) return null;

  const copy = aboutText || headline;
  const shouldClamp = copy.length > 240;
  const visible = shouldClamp ? `${copy.slice(0, 240).trim()}...` : copy;

  return (
    <section className="hotel-detail-section">
      <h4>About this property</h4>
      <div className="hotel-detail-copy">{visible}</div>
      {hasDetails || shouldClamp ? (
        <button type="button" className="hotel-inline-link mt-2" onClick={onOpenModal}>
          View more
        </button>
      ) : null}
    </section>
  );
}

function HotelAboutModal({ show, onHide, sections = {} }) {
  const renderSection = (title, content) =>
    content ? (
      <div className="hotel-about-modal-section" key={title}>
        <div className="hotel-about-modal-title">{title}</div>
        <div className="hotel-about-modal-copy">{content}</div>
      </div>
    ) : null;

  const sectionItems = [
    ["Location", sections.location],
    ["Amenities", sections.amenities],
    ["Rooms", sections.rooms],
    ["Dining", sections.dining],
    ["Business amenities", sections.businessAmenities],
    ["Attractions", sections.attractions],
    ["Onsite payments", sections.onsitePayments],
    ["Spoken languages", sections.spokenLanguages],
  ];

  return (
    <Modal show={show} onHide={onHide} centered size="lg">
      <div className="modal-content rounded-4">
        <div className="modal-header border-0">
          <h5 className="modal-title">About this property</h5>
          <button type="button" className="btn-close" onClick={onHide} aria-label="Close" />
        </div>
        <div className="modal-body">
          {renderSection("Overview", sections.headline || "")}
          {sectionItems.map(([title, content]) => renderSection(title, content))}
        </div>
      </div>
    </Modal>
  );
}

function HotelPropertyInfoSection({ propertyInfo = {} }) {
  const range = (from, till) => [from, till].filter(Boolean).join(" – ");
  const rows = [
    ["Property type", propertyInfo.propertyType],
    ["Check-in", range(propertyInfo.checkInFrom, propertyInfo.checkInTill)],
    ["Check-out", range(propertyInfo.checkOutFrom, propertyInfo.checkOutTill)],
    ["Minimum check-in age", propertyInfo.checkInMinAge],
    [
      "Hotel chain",
      propertyInfo.brand && propertyInfo.chain
        ? `${propertyInfo.chain} (${propertyInfo.brand})`
        : propertyInfo.chain || propertyInfo.brand,
    ],
    ["Phone", propertyInfo.phone],
    ["Fax", propertyInfo.fax],
  ].filter(([, value]) => value && String(value).trim());

  if (!rows.length) return null;

  return (
    <section className="hotel-detail-section">
      <h4>Property information</h4>
      <div className="hotel-property-info-grid">
        {rows.map(([label, value]) => (
          <div className="hotel-property-info-row" key={label}>
            <span className="hotel-property-info-label">{label}</span>
            <span className="hotel-property-info-value">{value}</span>
          </div>
        ))}
      </div>
    </section>
  );
}

function HotelImportantInfoSection({ importantInformation = {} }) {
  const groups = [
    ["Mandatory fees", importantInformation.mandatoryFees],
    ["Special instructions", importantInformation.specialInstructions],
    ["Know before you go", importantInformation.knowBeforeYouGo],
  ].filter(([, entries]) => Array.isArray(entries) && entries.length > 0);

  if (!groups.length) return null;

  return (
    <section className="hotel-detail-section">
      <h4>Important information</h4>
      {groups.map(([title, entries]) => (
        <div className="hotel-important-info-group" key={title}>
          <div className="hotel-important-info-title">{title}</div>
          {entries.map((entry, index) => (
            <div className="hotel-detail-copy" key={`${title}-${index}`}>
              {entry.label && entry.label.toLowerCase() !== title.toLowerCase() ? (
                <span className="hotel-important-info-label">{entry.label}: </span>
              ) : null}
              {entry.text}
            </div>
          ))}
        </div>
      ))}
    </section>
  );
}

function HotelImportantInfoModal({ show, onHide, propertyInfo = {}, importantInformation = {} }) {
  return (
    <Modal show={show} onHide={onHide} centered size="lg">
      <div className="modal-content rounded-4">
        <div className="modal-header border-0">
          <h5 className="modal-title">Property &amp; important information</h5>
          <button type="button" className="btn-close" onClick={onHide} aria-label="Close" />
        </div>
        <div className="modal-body hotel-info-modal-body">
          <HotelPropertyInfoSection propertyInfo={propertyInfo} />
          <HotelImportantInfoSection importantInformation={importantInformation} />
        </div>
      </div>
    </Modal>
  );
}

function HotelAmenities({ amenities, onViewMore }) {
  if (!amenities.length) return null;

  return (
    <section className="hotel-detail-section">
      <div className="d-flex justify-content-between gap-3 align-items-center mb-3">
        <h4 className="mb-0">Amenities</h4>
        {amenities.length > 0 ? (
          <button type="button" className="hotel-inline-link" onClick={onViewMore}>
            View more
          </button>
        ) : null}
      </div>

      <div className="hotel-detail-amenities">
        {amenities.slice(0, 6).map((amenity, index) => {
          // Convert amenity to string safely
          let amenityText = "";
          if (typeof amenity === "string") {
            amenityText = amenity;
          } else if (typeof amenity === "object" && amenity !== null) {
            amenityText = amenity.name || amenity.nm || amenity.label || String(amenity);
          } else {
            amenityText = String(amenity || "");
          }
          
          // Skip if empty or is still an object string
          if (!amenityText || amenityText === "[object Object]") return null;
          
          return (
            <span key={`amenity-${index}-${amenityText}`} className="hotel-detail-amenity">
              <Check size={14} color="#ed1173" />
              {amenityText}
            </span>
          );
        })}
      </div>
    </section>
  );
}

function RoomFilters({
  roomSearch,
  setRoomSearch,
  filterState,
  setFilterState,
  mealPlans,
  onOpenMobileFilters,
}) {
  const [showMealDropdown, setShowMealDropdown] = useState(false);
  const mealDropdownRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (mealDropdownRef.current && !mealDropdownRef.current.contains(event.target)) {
        setShowMealDropdown(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const selectedMealPlan = mealPlans.find(plan => plan.value === filterState.mealPlan);

  return (
    <>
      <input
        className="hotel-room-search"
        placeholder="Search by Room Type/Room Category"
        value={roomSearch}
        onChange={(event) => setRoomSearch(event.target.value)}
      />
      <div className="hotel-room-filter-row">
        <button
          type="button"
          className={`hotel-room-filter-chip ${filterState.refundable ? "active" : ""}`}
          onClick={() => setFilterState((prev) => ({ ...prev, refundable: !prev.refundable }))}
        >
          Refundable
        </button>
        <button
          type="button"
          className={`hotel-room-filter-chip ${filterState.breakfastIncluded ? "active" : ""}`}
          onClick={() => setFilterState((prev) => ({ ...prev, breakfastIncluded: !prev.breakfastIncluded }))}
        >
          Breakfast Included
        </button>
        <button
          type="button"
          className={`hotel-room-filter-chip ${filterState.panOptional ? "active" : ""}`}
          onClick={() => setFilterState((prev) => ({ ...prev, panOptional: !prev.panOptional }))}
        >
          PAN Optional
        </button>
        <div className="hotel-meal-dropdown-wrapper" ref={mealDropdownRef}>
          <button
            type="button"
            className={`hotel-room-filter-chip ${filterState.mealPlan ? "active" : ""}`}
            onClick={() => setShowMealDropdown(!showMealDropdown)}
          >
            Meal Plans: {selectedMealPlan ? selectedMealPlan.label : "All"}
            <ChevronDown size={14} />
          </button>
          {showMealDropdown && (
            <div className="hotel-meal-dropdown">
              <button
                type="button"
                className={`hotel-meal-option ${!filterState.mealPlan ? "selected" : ""}`}
                onClick={() => {
                  setFilterState((prev) => ({ ...prev, mealPlan: "" }));
                  setShowMealDropdown(false);
                }}
              >
                <span>All</span>
                {!filterState.mealPlan && <Check size={16} color="#ed1173" />}
              </button>
              {mealPlans.map((plan) => (
                <button
                  key={plan.value}
                  type="button"
                  className={`hotel-meal-option ${filterState.mealPlan === plan.value ? "selected" : ""}`}
                  onClick={() => {
                    setFilterState((prev) => ({ ...prev, mealPlan: plan.value }));
                    setShowMealDropdown(false);
                  }}
                >
                  <span>{plan.label}</span>
                  {filterState.mealPlan === plan.value && <Check size={16} color="#ed1173" />}
                </button>
              ))}
            </div>
          )}
        </div>
        <button type="button" className="hotel-room-filter-chip hotel-mobile-filter-btn active" onClick={onOpenMobileFilters}>
          <Filter size={15} />
          Filter
        </button>
      </div>
    </>
  );
}

function MarkupModal({ show, onHide, onUpdate }) {
  const [markupType, setMarkupType] = useState("percentage");
  const [markupValue, setMarkupValue] = useState("");

  const handleUpdate = () => {
    if (markupValue && !isNaN(markupValue)) {
      onUpdate(markupType, parseFloat(markupValue));
      onHide();
    }
  };

  return (
    <Modal show={show} onHide={onHide} centered size="sm">
      <Modal.Header closeButton>
        <Modal.Title>Edit Markup</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        <p className="text-muted mb-3">Enter the markup details.</p>
        
        <div className="mb-3">
          <label className="form-label">As Percentage %</label>
          <div className="input-group">
            <input
              type="number"
              className="form-control"
              placeholder="0"
              value={markupType === "percentage" ? markupValue : ""}
              onChange={(e) => {
                setMarkupType("percentage");
                setMarkupValue(e.target.value);
              }}
            />
            <span className="input-group-text">%</span>
          </div>
        </div>

        <div className="text-center text-muted mb-3">OR</div>

        <div className="mb-3">
          <label className="form-label">As Value</label>
          <div className="input-group">
            <span className="input-group-text">₹</span>
            <input
              type="number"
              className="form-control"
              placeholder="0"
              value={markupType === "value" ? markupValue : ""}
              onChange={(e) => {
                setMarkupType("value");
                setMarkupValue(e.target.value);
              }}
            />
          </div>
        </div>

        <button
          type="button"
          className="btn w-100"
          style={{
            background: "#ed1173",
            color: "#fff",
            fontWeight: 700,
            padding: "12px",
            borderRadius: "8px",
          }}
          onClick={handleUpdate}
        >
          Update All
        </button>
      </Modal.Body>
    </Modal>
  );
}

function RoomPolicyModal({ show, onHide, option, hotelName, starRating, searchId }) {
  if (!option) return null;

  const cancellationPenalties = option.cancellationPenalties || [];
  const isRefundable = option.refundable;

  return (
    <Modal show={show} onHide={onHide} size="lg" centered>
      <Modal.Header closeButton>
        <Modal.Title>Room with Cancellation Policy</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        <div className="mb-3">
          <strong>Cancellation Policy:</strong>
          <div className="mt-2">
            <Check size={14} color="#22a55a" style={{ marginRight: 8 }} />
            {isRefundable ? "Refundable" : "Non Refundable"}
          </div>
        </div>

        {!isRefundable ? (
          <div className="alert alert-danger" style={{ borderRadius: 12 }}>
            <strong>Non-Refundable</strong>
          </div>
        ) : null}

        <div className="d-flex justify-content-between align-items-center mb-3">
          <div><strong>Now</strong></div>
          <div className="text-end">
            <div>{formatDateTime(option.raw?.checkInDate || Date.now())}</div>
            <div className="text-muted" style={{ fontSize: 13 }}>Check-In</div>
          </div>
        </div>

        {cancellationPenalties.length > 0 ? (
          <>
            <div className="mb-3">
              <strong>Cancellation post that will be subject to a fees as follows</strong>
            </div>

            <table className="table table-bordered">
              <thead>
                <tr>
                  <th>Cancellation On or After</th>
                  <th>Cancellation On or Before</th>
                  <th>Cancellation Charges/Comments</th>
                </tr>
              </thead>
              <tbody>
                {cancellationPenalties.map((penalty, index) => (
                  <tr key={index}>
                    <td>{fmtDate(penalty.from, '-')}</td>
                    <td>{fmtDate(penalty.to, '-')}</td>
                    <td>{penalty.amount ? formatMoney(penalty.amount, option.currency) : '-'}</td>
                  </tr>
                ))}
              </tbody>
            </table>

            <div className="text-center text-muted mt-3" style={{ fontSize: 13 }}>
              <div>No Show will attract full cancellation charge unless otherwise specified.</div>
              <div className="mt-2">Early check out will attract full cancellation charge unless otherwise specified.</div>
            </div>
          </>
        ) : (
          <div className="text-center text-muted mt-3" style={{ fontSize: 14 }}>
            <div>No Show will attract full cancellation charge unless otherwise specified.</div>
            <div className="mt-2">Early check out will attract full cancellation charge unless otherwise specified.</div>
          </div>
        )}
      </Modal.Body>
    </Modal>
  );
}

const normalizeRoomAmenityText = (amenity) => {
  if (typeof amenity === "string") return amenity.trim();
  if (typeof amenity === "object" && amenity !== null) {
    const raw = amenity.name || amenity.nm || amenity.label || "";
    return String(raw).trim();
  }
  return String(amenity || "").trim();
};

const mergeAmenityLists = (...amenityLists) => {
  const seen = new Set();
  return amenityLists
    .flatMap((amenities) => (Array.isArray(amenities) ? amenities : []))
    .map(normalizeRoomAmenityText)
    .filter((text) => {
      if (!text || text === "[object Object]") return false;
      const key = text.toLowerCase();
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
};

function RoomTypeGroup({ roomName, options, selectedOptionId, onSelectRoom, onViewDetails, reviewLoadingOptionId, image, bedSummary, guestSummary, amenities, onViewPolicy, onViewMoreAmenities }) {
  const [activeImageIndex, setActiveImageIndex] = useState(0);
  
  // Get all images from the first option (they should all have the same room images)
  const images = options[0]?.images || [];
  const activeImage = images[activeImageIndex] || image;
  const mergedAmenities = mergeAmenityLists(amenities, ...options.map((option) => option?.amenities));

  const handlePrevImage = (event) => {
    event.stopPropagation();
    setActiveImageIndex((prev) => (prev === 0 ? images.length - 1 : prev - 1));
  };

  const handleNextImage = (event) => {
    event.stopPropagation();
    setActiveImageIndex((prev) => (prev === images.length - 1 ? 0 : prev + 1));
  };
  
  const handleViewMoreAmenities = () => {
    if (onViewMoreAmenities && selectedOptionInGroup) {
      onViewMoreAmenities({
        ...selectedOptionInGroup,
        amenities: mergedAmenities,
      });
    }
  };
  
  const selectedOptionInGroup = options.find((option) => option.id === selectedOptionId) || options[0] || null;

  return (
    <div className="hotel-room-type-group">
      <div className="hotel-room-type-left">
        <div className="hotel-room-thumb">
          {activeImage ? (
            <img src={typeof activeImage === 'string' ? activeImage : activeImage.url} alt={roomName} />
          ) : (
            <div className="hotel-card-image hotel-card-image--empty">Image not available</div>
          )}
          
          {images.length > 1 && (
            <>
              <button
                type="button"
                className="hotel-room-image-nav hotel-room-image-nav-left"
                onClick={handlePrevImage}
                aria-label="Previous image"
              >
                ‹
              </button>
              <button
                type="button"
                className="hotel-room-image-nav hotel-room-image-nav-right"
                onClick={handleNextImage}
                aria-label="Next image"
              >
                ›
              </button>
            </>
          )}
          
          <button type="button" className="hotel-photo-overlay">
            <Images size={14} />
            {images.length > 0 ? `+${images.length} Photos →` : "+4 Photos →"}
          </button>
        </div>

        <div className="hotel-room-feature-pills">
          {bedSummary ? (
            <span className="hotel-room-feature-pill">
              <BedDouble size={13} />
              {bedSummary}
            </span>
          ) : null}
          {guestSummary ? (
            <span className="hotel-room-feature-pill">
              <UserRound size={13} />
              {guestSummary}
            </span>
          ) : null}
        </div>

        <div className="hotel-room-amenities-preview">
          {mergedAmenities.slice(0, 4).map((amenity, index) => {
            let amenityText = "";
            if (typeof amenity === "string") {
              amenityText = amenity;
            } else if (typeof amenity === "object" && amenity !== null) {
              amenityText = amenity.name || amenity.nm || amenity.label || String(amenity);
            } else {
              amenityText = String(amenity || "");
            }
            
            // Skip if empty or is still an object string
            if (!amenityText || amenityText === "[object Object]") return null;
            
            return (
              <span key={`amenity-${index}-${amenityText}`} className="hotel-room-amenity-item hotel-room-amenity-item--green">
                <Check size={14} color="#22a55a" />
                {amenityText}
              </span>
            );
          })}
          <button type="button" className="hotel-inline-link" onClick={handleViewMoreAmenities}>
            View more amenities
          </button>
        </div>
      </div>

      <div className="hotel-room-type-right">
        {options.map((option) => (
          <RoomOptionCard
            key={option.id}
            option={option}
            isSelected={selectedOptionId === option.id}
            onSelectRoom={onSelectRoom}
            onViewDetails={onViewDetails}
            reviewLoadingOptionId={reviewLoadingOptionId}
            onViewPolicy={onViewPolicy}
          />
        ))}
      </div>
    </div>
  );
}

function RoomOptionCard({
  option,
  isSelected,
  onSelectRoom,
  onViewDetails,
  reviewLoadingOptionId,
  onViewPolicy,
}) {
  const isReviewing = reviewLoadingOptionId === option.id;

  const handleViewMore = () => {
    if (onViewPolicy) {
      onViewPolicy(option);
    }
  };

  return (
    <div className="hotel-room-option-compact">
      <div className="hotel-room-option-title">{option.roomName}</div>
      <div className="hotel-room-option-row">
        <div className="hotel-room-meal-cell">
          <strong>{option.mealBasis}</strong>
          <span className="hotel-room-divider">|</span>
          <span>{option.refundable ? "Refundable" : "Non-refundable"}</span>
          <span className="hotel-room-divider">|</span>
          <span>{option.panRequired ? "PAN Required" : "PAN not Required"}</span>
        </div>
        <div className="hotel-room-price-cell">
          <div className="hotel-room-total-compact">
            {option.totalPrice ? formatMoney(option.totalPrice, option.currency) : "N/A"}
          </div>
          <div className="hotel-summary-subcopy">Total <CircleHelp size={12} style={{ display: "inline", marginLeft: 4 }} /></div>
          <div className="hotel-summary-subcopy">Total Price for 1 room</div>
        </div>
        <div className="hotel-room-action-cell">
          <button
            type="button"
            className="hotel-card-cta"
            style={isSelected ? { boxShadow: "0 0 0 3px rgba(237, 17, 115, 0.18)" } : undefined}
            onClick={() => onSelectRoom(option)}
            disabled={Boolean(reviewLoadingOptionId)}
          >
            {isReviewing ? "Reviewing..." : isSelected ? "Selected" : "Select Room"}
          </button>
        </div>
      </div>
      <div className="hotel-room-option-footer">
        <div className="hotel-room-policy-badge">
          <Check size={14} color="#22a55a" />
          <span>{option.cancellationLabel}</span>
        </div>
        <button type="button" className="hotel-inline-link" onClick={handleViewMore}>
          View more
        </button>
      </div>
    </div>
  );
}

function RoomTypesSection({
  options,
  filteredOptions,
  roomSearch,
  setRoomSearch,
  filterState,
  setFilterState,
  mealPlans,
  selectedOptionId,
  onSelectRoom,
  onViewDetails,
  onViewPolicy,
  onViewMoreAmenities,
  shareHref,
  onOpenMobileFilters,
  roomSectionRef,
  detailLoading,
  reviewLoadingOptionId,
}) {
  // Group options by room name
  const groupedRooms = useMemo(() => {
    const groups = {};
    filteredOptions.forEach((option) => {
      const key = option.roomName;
      if (!groups[key]) {
        groups[key] = {
          roomName: key,
          image: option.image,
          bedSummary: option.bedSummary,
          guestSummary: option.guestSummary,
          amenities: [],
          options: [],
        };
      }
      groups[key].amenities = mergeAmenityLists(groups[key].amenities, option.amenities);
      groups[key].options.push(option);
    });
    return Object.values(groups);
  }, [filteredOptions]);

  return (
    <div className="hotel-room-section-card hoteldetails__bottombox" ref={roomSectionRef}>
      <div className="about-container">
      <div className="hotel-room-section-head header_wrapper">
        <div>
          <div className="hotel-room-section-title about-room-types-header__title">Room types</div>
          <div className="hotel-summary-subcopy">
            {`Showing results ${filteredOptions.length} of ${options.length} room options`}
          </div>
        </div>

        <div className="hotel-room-toolbar about-room-types-header__share">
          <div className="hotel-share-group">
            <span>Share by:</span>
            <a className="hotel-whatsapp-btn about-room-types-header__whatsapp" href={shareHref} target="_blank" rel="noreferrer">
              <MessageCircleMore size={15} />
              WhatsApp
            </a>
          </div>
          <RoomFilters
            roomSearch={roomSearch}
            setRoomSearch={setRoomSearch}
            filterState={filterState}
            setFilterState={setFilterState}
            mealPlans={mealPlans}
            onOpenMobileFilters={onOpenMobileFilters}
          />
        </div>
      </div>
      </div>

      {detailLoading && options.length === 0 ? (
        <div style={{ padding: 22 }}>
          <RoomOptionSkeleton />
          <RoomOptionSkeleton />
        </div>
      ) : filteredOptions.length === 0 ? (
        <div className="hotel-empty m-4">
          <div className="hotel-empty-title">No room options match these filters</div>
          <div className="hotel-empty-copy">Try a different meal plan or clear the room search.</div>
        </div>
      ) : (
        groupedRooms.map((group) => (
          <RoomTypeGroup
            key={group.roomName}
            roomName={group.roomName}
            options={group.options}
            selectedOptionId={selectedOptionId}
            onSelectRoom={onSelectRoom}
            onViewDetails={onViewDetails}
            onViewPolicy={onViewPolicy}
            onViewMoreAmenities={onViewMoreAmenities}
            reviewLoadingOptionId={reviewLoadingOptionId}
            image={group.image}
            bedSummary={group.bedSummary}
            guestSummary={group.guestSummary}
            amenities={group.amenities}
          />
        ))
      )}
    </div>
  );
}

function buildRoomModalOption(option) {
  const inclusions = mergeAmenityLists(option.amenities);

  return {
    key: option.id,
    roomName: option.roomName,
    mealBasis: option.mealBasis,
    bookingNotes: option.view || option.supplierRoomType || "",
    inclusions,
    images: option.images || [],
    image: option.image || "",
    bedSummary: option.bedSummary || "",
    guestSummary: option.guestSummary || "",
    cancellationLabel: option.cancellationLabel || "",
    panRequired: option.panRequired,
    passportRequired: option.passportRequired,
    pricing: {
      totalPrice: option.totalPrice,
      nightlyPrice: option.nightlyPrice,
      currency: option.currency,
    },
    cancellation: {
      penalties: option.cancellationPenalties,
    },
    raw: option.raw,
  };
}

const compactProperties = (input) => {
  const output = {};
  Object.entries(input || {}).forEach(([key, value]) => {
    if (value === undefined || value === null || value === "") return;
    output[key] = value;
  });
  return output;
};

function HotelDetailsPage({
  selectedHotel,
  detailResponse,
  detailLoading,
  initialPayload,
  initialSuggestion,
  onBackToResults,
  activeOption,
  roomModalOpen,
  setActiveOption,
  setRoomModalOpen,
}) {
  const { user, isAuthenticated } = useSelector((state) => state.auth);
  const navigate = useNavigate();
  const location = useLocation();
  const roomSectionRef = useRef(null);
  // Restoring a parked booking must happen once per mount, never on every
  // re-render of the room list.
  const draftRestoreRef = useRef(false);
  const [selectedOptionId, setSelectedOptionId] = useState("");
  const [roomSearch, setRoomSearch] = useState("");
  const [filterState, setFilterState] = useState({
    refundable: false,
    breakfastIncluded: false,
    panOptional: false,
    mealPlan: "",
  });
  const [showAmenitiesModal, setShowAmenitiesModal] = useState(false);
  const [showAboutModal, setShowAboutModal] = useState(false);
  const [showImportantInfoModal, setShowImportantInfoModal] = useState(false);
  const [showPolicyModal, setShowPolicyModal] = useState(false);
  const [selectedPolicyOption, setSelectedPolicyOption] = useState(null);
  const [showMarkupModal, setShowMarkupModal] = useState(false);
  const [markupEnabled, setMarkupEnabled] = useState(true);
  const [markupType, setMarkupType] = useState("percentage");
  const [markupValue, setMarkupValue] = useState(0);
  const [staticContentResponse, setStaticContentResponse] = useState(null);
  const [showGalleryModal, setShowGalleryModal] = useState(false);
  const [galleryIndex, setGalleryIndex] = useState(0);
  const [showRoomFilters, setShowRoomFilters] = useState(false);
  const [reviewLoadingOptionId, setReviewLoadingOptionId] = useState("");
  const [reviewResponse, setReviewResponse] = useState(null);
  const [showReviewModal, setShowReviewModal] = useState(false);
  const [bookingForm, setBookingForm] = useState(null);
  const [showBookingFormModal, setShowBookingFormModal] = useState(false);
  const [bookingSubmitting, setBookingSubmitting] = useState(false);
  const [showBookingStatusModal, setShowBookingStatusModal] = useState(false);
  const [bookingStatusState, setBookingStatusState] = useState({
    phase: "idle",
    bookingId: "",
    orderStatus: "",
    attempts: 0,
    message: "",
    details: null,
    errorCode: "",
  });
  const [documentLoading, setDocumentLoading] = useState("");
  const bookingPollSessionRef = useRef(0);
  const isMountedRef = useRef(true);

  useEffect(() => {
    return () => {
      isMountedRef.current = false;
      bookingPollSessionRef.current += 1;
    };
  }, []);

  const detailModel = useMemo(
    () =>
      normalizeHotelDetails({
        detailResponse,
        selectedHotel,
        searchPayload: initialPayload,
        selectedSuggestion: initialSuggestion,
        staticContentResponse,
      }),
    [detailResponse, initialPayload, initialSuggestion, selectedHotel, staticContentResponse],
  );

  const reviewPayloadFields = useMemo(
    () =>
      getReviewPayloadFields(
        detailModel.hotelInfo,
        selectedHotel,
        detailModel.meta,
        initialPayload,
        detailResponse || null,
      ),
    [detailModel.hotelInfo, detailModel.meta, selectedHotel, initialPayload, detailResponse],
  );

  useEffect(() => {
    if (detailModel.cheapestOption) {
      setSelectedOptionId((prev) => prev || detailModel.cheapestOption.id);
    }
  }, [detailModel.cheapestOption]);

  useEffect(() => {
    const searchId =
      reviewPayloadFields.searchId ||
      detailModel?.meta?.searchId ||
      initialPayload?.searchId ||
      initialPayload?.searchQuery?.searchId ||
      "";
    const tjHotelId =
      reviewPayloadFields.tjHotelId ||
      detailModel.id ||
      selectedHotel?.raw?.tjid ||
      selectedHotel?.raw?.hid ||
      "";
    // Static content (amenities, descriptions, address, policies, room amenities)
    // is keyed only by the hotel id — TripJack's /content/fetch-hotel-content does
    // NOT need a searchId, so we must not gate the fetch on it.
    if (!tjHotelId) {
      if (import.meta.env.DEV) {
        console.warn("Skipping TripJack static content fetch due to missing hotel id", {
          searchId,
          tjHotelId,
          reviewPayloadFields,
          detailMeta: detailModel?.meta,
        });
      }
      return undefined;
    }

    let active = true;
    getHotelStaticContent({
      tjHotelIds: [String(tjHotelId)],
      ...(searchId ? { searchId: String(searchId) } : {}),
    })
      .then((response) => {
        if (active) {
          // TripJack /content/fetch-hotel-content returns { status, hotels: [...] }.
          const hotels = Array.isArray(response)
            ? response
            : Array.isArray(response?.hotels)
              ? response.hotels
              : Array.isArray(response?.data?.hotels)
                ? response.data.hotels
                : [];
          setStaticContentResponse(hotels);
        }
      })
      .catch((error) => {
        console.error("Unable to load TripJack static hotel content", error);
        if (active) setStaticContentResponse(null);
      });

    return () => {
      active = false;
    };
  }, [
    detailModel.id,
    detailModel?.meta?.searchId,
    initialPayload?.searchId,
    initialPayload?.searchQuery?.searchId,
    reviewPayloadFields.searchId,
    reviewPayloadFields.tjHotelId,
    selectedHotel?.raw?.tjid,
    selectedHotel?.raw?.hid,
  ]);

  const selectedOption = useMemo(
    () =>
      detailModel.options.find((option) => option.id === selectedOptionId) ||
      detailModel.cheapestOption ||
      null,
    [detailModel.cheapestOption, detailModel.options, selectedOptionId],
  );

  const roomSummary = useMemo(() => {
    const roomInfo = initialPayload?.searchQuery?.roomInfo || [];
    const totalRooms = roomInfo.length || 1;
    const adults = roomInfo.reduce((sum, room) => sum + Number(room?.numberOfAdults || 0), 0);
    return `${totalRooms} Room${totalRooms > 1 ? "s" : ""} for ${adults || 1} Adult${adults === 1 ? "" : "s"}`;
  }, [initialPayload]);

  const mealPlans = useMemo(() => getMealPlanOptions(detailModel.options), [detailModel.options]);

  // Whether the "View more" (About) and "Important information" buttons have
  // anything to show — so we hide them when the static content is empty.
  const hasPropertyDetails = useMemo(() => {
    const sections = detailModel.aboutSections || {};
    return [
      "location",
      "amenities",
      "rooms",
      "dining",
      "businessAmenities",
      "attractions",
      "onsitePayments",
      "spokenLanguages",
    ].some((key) => typeof sections[key] === "string" && sections[key].trim());
  }, [detailModel.aboutSections]);

  const hasImportantInfo = useMemo(() => {
    const propertyInfo = detailModel.propertyInfo || {};
    const important = detailModel.importantInformation || {};
    const hasProperty = Object.values(propertyInfo).some((value) => value && String(value).trim());
    const hasNotes = ["specialInstructions", "knowBeforeYouGo", "mandatoryFees"].some(
      (key) => Array.isArray(important[key]) && important[key].length > 0
    );
    return hasProperty || hasNotes;
  }, [detailModel.propertyInfo, detailModel.importantInformation]);

  const filteredOptions = useMemo(() => {
    const query = roomSearch.trim().toLowerCase();
    return detailModel.options.filter((option) => {
      if (query) {
        const haystack = [option.roomName, option.supplierRoomType, option.view]
          .filter(Boolean)
          .join(" ")
          .toLowerCase();
        if (!haystack.includes(query)) return false;
      }

      if (filterState.refundable && !option.refundable) return false;
      if (filterState.breakfastIncluded && !option.mealBasis.toLowerCase().includes("breakfast")) return false;
      if (filterState.panOptional && option.panRequired) return false;
      if (filterState.mealPlan && option.mealBasis !== filterState.mealPlan) return false;

      return true;
    });
  }, [detailModel.options, filterState, roomSearch]);

  const shareHref = useMemo(() => {
    const currentUrl = typeof window !== "undefined" ? window.location.href : "";
    return `https://wa.me/?text=${encodeURIComponent(`Check out ${detailModel.name} on HappyWedz ${currentUrl}`)}`;
  }, [detailModel.name]);

  const handleViewPolicy = async (option) => {
    setSelectedPolicyOption(option);
    setShowPolicyModal(true);

    // Send analytics event
    try {
      await trackHotelAnalyticsEvent({
        event: "Hotel_PDP_RoomDetailView",
        properties: {
          Hotel_Name: detailModel.name,
          Cancellation_Check: option.refundable ? "FREE CANCELLATION" : "NO FREE CANCELLATION",
          Star_Rating: detailModel.starRating,
          Agent_Id: "313144",
          Current_Page: window.location.href,
          Current_Path: window.location.pathname,
          Date: fmtDate(new Date()),
          Previous_Page: document.referrer,
          Previous_Path: new URL(document.referrer || window.location.href).pathname,
          Product: "HOTEL",
          Search_Id: detailModel.meta.searchId,
          Unica_Id: detailModel.id,
          User_Email: "user@example.com",
          User_Role: "AGENT",
          View_More_Selected: "cancellation_policy",
          optionId: option.id,
          TimeStamp: new Date().toISOString(),
        },
      });
    } catch (error) {
      console.error("Failed to track analytics event:", error);
    }
  };

  const handleUpdateMarkup = async (type, value) => {
    setMarkupType(type);
    setMarkupValue(value);
    setMarkupEnabled(true);

    // Send analytics event
    try {
      await trackHotelAnalyticsEvent({
        event: "Hotel_Markup_Update",
        properties: {
          Markup_Type: type,
          Markup_Value: value,
          Agent_Id: "313144",
          User_Role: "AGENT",
          Current_Page: window.location.href,
          Current_Path: window.location.pathname,
          Date: fmtDate(new Date()),
          Previous_Page: document.referrer,
          Previous_Path: new URL(document.referrer || window.location.href).pathname,
          Product: "HOTEL",
          TimeStamp: new Date().toISOString(),
          User_Email: "user@example.com",
        },
      });
      toast.success(`Markup updated: ${value}${type === "percentage" ? "%" : " INR"}`);
    } catch (error) {
      console.error("Failed to track markup analytics:", error);
    }
  };

  const handleSelectRoom = (option, openModal = false) => {
    setSelectedOptionId(option.id);
    if (openModal) {
      setActiveOption(buildRoomModalOption(option));
      setRoomModalOpen(true);
    }
  };

  const handleReviewRoomOption = async (
    option,
    { openRoomModal = false, restoreForm = null, isRestore = false } = {},
  ) => {
    handleSelectRoom(option, openRoomModal);

    const resolvedCorrelationId =
      reviewPayloadFields.correlationId ||
      detailModel?.meta?.correlationId ||
      detailResponse?.correlationId ||
      initialPayload?.correlationId ||
      reviewPayloadFields.searchId ||
      "";
    const resolvedOptionId =
      option?.raw?.optionId ||
      option?.raw?.id ||
      option?.optionId ||
      option?.id ||
      "";
    const resolvedSearchId =
      reviewPayloadFields.searchId ||
      detailModel?.meta?.searchId ||
      initialPayload?.searchId ||
      initialPayload?.searchQuery?.searchId ||
      "";
    const resolvedDetailRequestId =
      reviewPayloadFields.detailRequestId ||
      reviewPayloadFields.reviewHash ||
      detailModel?.meta?.requestId ||
      detailModel?.meta?.reviewHash ||
      detailResponse?.reviewHash ||
      detailResponse?.requestId ||
      option?.raw?.reviewHash ||
      option?.raw?.requestId ||
      "";
    const resolvedTjHotelId =
      reviewPayloadFields.tjHotelId ||
      detailModel?.id ||
      selectedHotel?.raw?.tjid ||
      selectedHotel?.raw?.hid ||
      "";

    const payload = {
      correlationId: String(resolvedCorrelationId || ""),
      reviewHash: String(resolvedDetailRequestId || ""),
      hid: String(resolvedTjHotelId || ""),
      searchId: resolvedSearchId,
      detailRequestId: resolvedDetailRequestId,
      optionId: String(resolvedOptionId || ""),
      tjHotelId: String(resolvedTjHotelId || ""),
    };

    const hasOfficialPayload =
      Boolean(payload.correlationId) &&
      Boolean(payload.reviewHash) &&
      Boolean(payload.optionId) &&
      Boolean(payload.hid);
    const hasLegacyPayload =
      Boolean(payload.searchId) &&
      Boolean(payload.detailRequestId) &&
      Boolean(payload.optionId) &&
      Boolean(payload.tjHotelId);

    if (!hasOfficialPayload && !hasLegacyPayload) {
      console.warn("TripJack HMS review payload missing", { payload, candidates: reviewPayloadFields.candidates });
      toast.error("Missing review payload data. Please refresh hotel details and try again.");
      return;
    }

    setReviewLoadingOptionId(option.id);

    try {
      const response = await reviewHotelBooking(payload);
      console.log("[TripJack Review] Raw response from backend:", {
        hasPriceSummary: Boolean(response?.priceSummary),
        priceSummaryAmount: response?.priceSummary?.amount,
        hasOption: Boolean(response?.option),
        optionPricing: response?.option?.pricing,
      });
      const normalizedReviewResponse = normalizeReviewResponseForUi(
        response,
        option,
        detailModel,
        initialPayload
      );
      console.log("[TripJack Review] Normalized response:", {
        hasPriceSummary: Boolean(normalizedReviewResponse?.priceSummary),
        priceSummaryAmount: normalizedReviewResponse?.priceSummary?.amount,
        hasSelectedOption: Boolean(normalizedReviewResponse?.selectedOption),
      });
      const reviewSelectedOption = normalizedReviewResponse?.selectedOption || {};
      const effectivePanRequired = Boolean(
        normalizedReviewResponse?.bookingRequirements?.panRequired ||
        reviewSelectedOption?.ipr ||
        option?.panRequired ||
        detailModel?.panRequired
      );
      const effectivePassportRequired = Boolean(
        normalizedReviewResponse?.bookingRequirements?.passportRequired ||
        reviewSelectedOption?.ipm ||
        option?.passportRequired ||
        detailModel?.passportRequired
      );
      const enrichedReviewResponse = {
        ...normalizedReviewResponse,
        bookingRequirements: {
          ...(normalizedReviewResponse?.bookingRequirements || {}),
          panRequired: effectivePanRequired,
          passportRequired: effectivePassportRequired,
        },
        displayHotelName:
          normalizedReviewResponse?.hotelSummary?.name ||
          normalizedReviewResponse?.hotelInfo?.name ||
          detailModel.name ||
          "Selected hotel",
        displayRoomName:
          normalizedReviewResponse?.roomSummary?.roomName ||
          normalizedReviewResponse?.selectedOption?.roomInfos?.[0]?.rt ||
          normalizedReviewResponse?.selectedOption?.roomInfos?.[0]?.srn ||
          normalizedReviewResponse?.selectedOption?.ris?.[0]?.srn ||
          normalizedReviewResponse?.selectedOption?.ris?.[0]?.rt ||
          option.roomName,
      };

      setBookingStatusState({
        phase: "idle",
        bookingId: "",
        orderStatus: "",
        attempts: 0,
        message: "",
        details: null,
        errorCode: "",
      });
      setReviewResponse(enrichedReviewResponse);

      // A restored draft is merged onto the form built from the *fresh* review,
      // so room counts and required fields follow current availability. PAN is
      // never in the draft, so it comes back blank on purpose.
      const freshForm = createInitialBookingForm(enrichedReviewResponse);
      const mergedForm = restoreForm ? mergeBookingForm(freshForm, restoreForm) : freshForm;
      setBookingForm(mergedForm);

      if (isRestore) {
        toast.success(
          draftNeedsPan(mergedForm)
            ? "Your booking details are back. Please re-enter PAN and accept the terms."
            : "Your booking details are back. Please review and accept the terms.",
        );
      }
      setShowReviewModal(false);
      setShowBookingFormModal(true);
      setRoomModalOpen(false);
    } catch (error) {
      console.error("Unable to review hotel room option", error);
      if (isRestore) {
        // The parked option expired or sold out while the user was logging in.
        // Drop the draft and put them back on the room list rather than let
        // them walk into a payment that cannot succeed.
        clearBookingDraft();
        setShowBookingFormModal(false);
        setShowReviewModal(false);
        toast.error(
          "That room is no longer available at the saved price. Please pick a room again.",
        );
        roomSectionRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
      } else {
        toast.error("Unable to review this room option. Please try another room or search again.");
      }
    } finally {
      setReviewLoadingOptionId("");
    }
  };

  // ── Coming back from login ──────────────────────────────────────────────
  // Runs once the room options for this hotel are on screen. The draft supplies
  // only the option to ask about and the fields the user typed; the review call
  // below fetches a fresh bookingId, fare and cancellation policy.
  useEffect(() => {
    if (import.meta.env.DEV) {
      // TEMP DIAGNOSTIC — remove once the restore path is confirmed.
      console.log("[draft:restore-check]", {
        alreadyRan: draftRestoreRef.current,
        isAuthenticated,
        userId: user?.id,
        optionCount: detailModel?.options?.length || 0,
        hotelIdForRead: String(selectedHotel?.id || detailModel?.id || ""),
        rawDraft: window.sessionStorage.getItem("hw:bookingDraft")?.slice(0, 80) || null,
      });
    }

    if (draftRestoreRef.current) return;
    if (!isAuthenticated || !user?.id) return;
    if (!detailModel?.options?.length) return;

    const hotelId = String(selectedHotel?.id || detailModel?.id || "");
    if (!hotelId) return;

    const draft = readBookingDraft({ kind: "hotel", hotelId });
    if (import.meta.env.DEV) {
      console.log("[draft:read]", {
        found: Boolean(draft),
        savedOptionId: draft?.optionId,
        availableOptionIds: (detailModel?.options || []).slice(0, 5).map((o) => String(o?.id)),
      });
    }
    if (!draft) return;

    draftRestoreRef.current = true;

    const option = detailModel.options.find(
      (candidate) => String(candidate?.id) === String(draft.optionId),
    );

    if (!option) {
      clearBookingDraft();
      toast.error("That room is no longer listed. Please pick a room again.");
      return;
    }

    // Consumed on the way in: a draft must never be replayable.
    clearBookingDraft();
    handleReviewRoomOption(option, { restoreForm: draft.form, isRestore: true });
    // handleReviewRoomOption is stable for the life of this mount and the ref
    // guard makes this single-shot; listing it would re-run on every render.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthenticated, user?.id, detailModel?.options, selectedHotel?.id, detailModel?.id]);

  // Once TripJack has accepted the booking the draft is spent — clear it so a
  // back-button or second tab cannot resubmit the same details.
  useEffect(() => {
    if (["polling", "success"].includes(bookingStatusState?.phase)) {
      clearBookingDraft();
    }
  }, [bookingStatusState?.phase]);

  const handleOpenBookingForm = () => {
    if (!reviewResponse?.bookingId) {
      toast.error("Review data is missing. Please review the room again.");
      return;
    }

    setBookingForm((current) => current || createInitialBookingForm(reviewResponse));
    setShowReviewModal(false);
    setShowBookingFormModal(true);
  };

  const handleTravellerFieldChange = (roomIndex, travellerIndex, field, value) => {
    setBookingForm((current) => {
      if (!current) return current;
      const roomTravellerInfo = current.roomTravellerInfo.map((room, currentRoomIndex) => {
        if (currentRoomIndex !== roomIndex) return room;
        return {
          ...room,
          travellerInfo: room.travellerInfo.map((traveller, currentTravellerIndex) =>
            currentTravellerIndex === travellerIndex
              ? { ...traveller, [field]: value }
              : traveller,
          ),
        };
      });

      return {
        ...current,
        roomTravellerInfo,
      };
    });
  };

  const handleContactFieldChange = (field, value) => {
    setBookingForm((current) => {
      if (!current) return current;
      return {
        ...current,
        deliveryInfo: {
          ...current.deliveryInfo,
          [field]: [value],
        },
      };
    });
  };

  const handleTermsChange = (checked) => {
    setBookingForm((current) => (current ? { ...current, termsAccepted: checked } : current));
  };

  const pollTripjackBookingStatus = async (bookingId) => {
    const maxAttempts = 60;
    const fastPollIntervalMs = 15000;
    const slowPollIntervalMs = 60000;
    const fastAttempts = 20;
    let lastDetailsResponse = null;
    let lastStatusMeta = null;
    const sessionId = Date.now();
    bookingPollSessionRef.current = sessionId;

    for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
      if (!isMountedRef.current || bookingPollSessionRef.current !== sessionId) {
        return;
      }

      if (attempt > 1) {
        const pollDelayMs = attempt <= fastAttempts ? fastPollIntervalMs : slowPollIntervalMs;
        await delay(pollDelayMs);
      }

      if (!isMountedRef.current || bookingPollSessionRef.current !== sessionId) {
        return;
      }

      try {
        const detailsResponse = await getHotelBookingDetails({ bookingId });
        lastDetailsResponse = detailsResponse;
        const orderStatus = detailsResponse?.orderStatus || detailsResponse?.bookingStatusMeta?.rawStatus || "";
        const statusMeta = detailsResponse?.bookingStatusMeta || {};
        lastStatusMeta = statusMeta;

        if (statusMeta.isSuccessTerminal) {
          setBookingStatusState({
            phase: "success",
            bookingId,
            orderStatus,
            attempts: attempt,
            message: "Booking confirmed successfully.",
            details: detailsResponse,
            errorCode: "",
          });
          return;
        }

        if (statusMeta.isFailureTerminal) {
          setBookingStatusState({
            phase: "failed",
            bookingId,
            orderStatus,
            attempts: attempt,
            message: "Booking failed in TripJack. Please review the details and try again.",
            details: detailsResponse,
            errorCode: "",
          });
          return;
        }

        setBookingStatusState({
          phase: "polling",
          bookingId,
          orderStatus,
          attempts: attempt,
          message: statusMeta?.rawStatus === "PAYMENT_SUCCESS"
            ? `Your payment is successful. We are waiting for final confirmation from TripJack. Checked ${attempt} of ${maxAttempts} times.`
            : `Booking is still processing in TripJack. Checked ${attempt} of ${maxAttempts} times.`,
          details: detailsResponse,
          errorCode: "",
        });
      } catch (error) {
        console.error("Unable to fetch TripJack booking status", error);
        const tripjackDenied =
          error?.response?.data?.source === "TRIPJACK" &&
          error?.response?.data?.status?.success === false;

        if (tripjackDenied) {
          setBookingStatusState({
            phase: "denied",
            bookingId,
            orderStatus: "",
            attempts: 0,
            message: `TripJack denied the booking request: ${error?.response?.data?.error || "Access Denied"}`,
            details: error?.response?.data || null,
            errorCode: error?.response?.data?.errors?.[0]?.errCode || "",
          });
          return;
        }

        setBookingStatusState({
          phase: "polling",
          bookingId,
          orderStatus: "",
          attempts: attempt,
          message: "We are waiting for the next booking status update from TripJack.",
          details: null,
          errorCode: "",
        });
      }
    }

    setBookingStatusState((current) => ({
      ...current,
      phase: "timeout",
      bookingId,
      message:
        lastStatusMeta?.rawStatus === "PAYMENT_SUCCESS"
          ? "Payment is successful and booking is awaiting final hotel confirmation. Please refresh status after some time."
          : "Booking is still processing. Please refresh status after some time.",
      details: lastDetailsResponse || current?.details || null,
      errorCode: "",
    }));
  };

  const buildBookingPayload = ({ includePayment = true }) => {
    const payableAmount =
      normalizeAmount(reviewResponse?.priceSummary?.amount) ||
      normalizeAmount(reviewResponse?.selectedOption?.pricing?.totalPrice) ||
      normalizeAmount(reviewResponse?.selectedOption?.totalPrice) ||
      normalizeAmount(reviewResponse?.selectedOption?.tp);
    return {
      bookingId: reviewResponse.bookingId,
      roomTravellerInfo: bookingForm.roomTravellerInfo.map((room) => ({
        travellerInfo: room.travellerInfo.map((traveller) => ({
          ...traveller,
          fN: String(traveller.fN || "").trim(),
          lN: String(traveller.lN || "").trim(),
          ...(traveller.pan ? { pan: String(traveller.pan).trim().toUpperCase() } : {}),
          ...(traveller.pNum ? { pNum: String(traveller.pNum).trim().toUpperCase() } : {}),
        })),
      })),
      deliveryInfo: {
        emails: [String(bookingForm.deliveryInfo.emails[0] || "").trim()],
        contacts: [String(bookingForm.deliveryInfo.contacts[0] || "").trim()],
        code: [String(bookingForm.deliveryInfo.code[0] || "").trim()],
      },
      ...(includePayment ? { paymentInfos: [{ amount: payableAmount }], expectedAmount: payableAmount } : {}),
      type: "HOTEL",
      ipr: Boolean(reviewResponse?.bookingRequirements?.panRequired),
      ipm: Boolean(reviewResponse?.bookingRequirements?.passportRequired),
      hotelId: String(reviewResponse?.hotelInfo?.tjid || reviewResponse?.hotelSummary?.tjid || ""),
      optionId: String(reviewResponse?.selectedOption?.optionId || reviewResponse?.selectedOption?.id || ""),
      reviewData: reviewResponse,
    };
  };

  // Parks what the user typed, then sends them to login with a way back.
  // PAN is stripped inside saveBookingDraft; nothing time-sensitive from the
  // supplier is kept, because the review is re-run on return.
  const parkBookingAndLogin = (reason) => {
    const draftHotelId = String(selectedHotel?.id || detailModel?.id || "");
    const saved = saveBookingDraft({
      kind: "hotel",
      hotelId: draftHotelId,
      optionId: String(selectedOptionId || ""),
      searchPayload: initialPayload,
      suggestion: initialSuggestion,
      form: bookingForm,
    });
    if (import.meta.env.DEV) {
      // TEMP DIAGNOSTIC — remove once the restore path is confirmed.
      console.log("[draft:save]", {
        saved,
        hotelId: draftHotelId,
        optionId: String(selectedOptionId || ""),
        hasForm: Boolean(bookingForm),
        hasSearchPayload: Boolean(initialPayload),
        readBack: window.sessionStorage.getItem("hw:bookingDraft")?.slice(0, 80),
      });
    }
    navigate(...loginRedirect(location, reason));
  };

  const handleProceedToBook = async () => {
    if (!reviewResponse?.bookingId || !bookingForm) {
      toast.error("Booking review data is missing. Please review the room again.");
      return;
    }

    if (!isAuthenticated || !user?.id) {
      parkBookingAndLogin("booking");
      return;
    }

    const validationErrors = validateBookingForm(bookingForm, reviewResponse);
    if (validationErrors.length > 0) {
      toast.error(validationErrors[0]);
      return;
    }

    const payableAmount =
      normalizeAmount(reviewResponse?.priceSummary?.amount) ||
      normalizeAmount(reviewResponse?.selectedOption?.pricing?.totalPrice) ||
      normalizeAmount(reviewResponse?.selectedOption?.totalPrice) ||
      normalizeAmount(reviewResponse?.selectedOption?.tp);
    
    console.log("[TripJack Payment] Resolving payable amount:", {
      fromPriceSummary: reviewResponse?.priceSummary?.amount,
      fromSelectedOptionPricing: reviewResponse?.selectedOption?.pricing?.totalPrice,
      fromSelectedOptionTotalPrice: reviewResponse?.selectedOption?.totalPrice,
      fromSelectedOptionTp: reviewResponse?.selectedOption?.tp,
      finalAmount: payableAmount,
    });
    
    if (!Number.isFinite(payableAmount) || payableAmount <= 0) {
      console.error("[TripJack Payment] Booking amount unavailable", {
        reviewResponse: {
          hasPriceSummary: Boolean(reviewResponse?.priceSummary),
          priceSummaryAmount: reviewResponse?.priceSummary?.amount,
          hasSelectedOption: Boolean(reviewResponse?.selectedOption),
          selectedOptionKeys: reviewResponse?.selectedOption ? Object.keys(reviewResponse.selectedOption) : [],
        },
      });
      toast.error("Booking amount is unavailable. Please review the room again.");
      return;
    }

    const payload = buildBookingPayload({ includePayment: true });
// If payment is already captured (or TripJack says payment success), we should retry booking
// without forcing payment again.
const retryWithoutRepayment =
      ["validation_failed", "denied", "failed", "already_paid"].includes(
        String(bookingStatusState?.phase || "").toLowerCase()
      ) &&
      Boolean(
        bookingStatusState?.details?.paymentCaptured ||
        bookingStatusState?.details?.payment_status === "PAID" ||
        bookingStatusState?.paymentCaptured ||
        String(bookingStatusState?.orderStatus || "").toUpperCase() === "PAYMENT_SUCCESS"
      );


    console.log("[TripJack Booking Request]", {
      endpoint: retryWithoutRepayment ? "hotels/verify-payment-and-book" : "hotels/create-payment-order",
      bookingId: payload.bookingId,
      hotelId: payload.hotelId,
      optionId: payload.optionId,
      paymentInfos: payload.paymentInfos,
      roomTravellerInfo: payload.roomTravellerInfo,
      deliveryInfo: payload.deliveryInfo,
      retryWithoutRepayment,
    });

    setBookingSubmitting(true);
    setShowBookingStatusModal(true);
    setBookingStatusState({
      phase: "submitting",
      bookingId: payload.bookingId,
      orderStatus: "",
      attempts: 0,
      message: "Creating Razorpay payment order.",
      details: null,
      errorCode: "",
    });

    try {
      if (retryWithoutRepayment) {
        setBookingStatusState({
          phase: "submitting",
          bookingId: payload.bookingId,
          orderStatus: "PAYMENT_SUCCESS",
          attempts: 0,
          message: "Payment already captured. Retrying booking with updated traveller details.",
          details: bookingStatusState?.details || null,
          errorCode: "",
          paymentCaptured: true,
        });
        const verifyResponse = await verifyHotelPaymentAndBook({
          bookingId: payload.bookingId,
          roomTravellerInfo: payload.roomTravellerInfo,
          deliveryInfo: payload.deliveryInfo,
          ipr: payload.ipr,
          ipm: payload.ipm,
          type: payload.type,
        });

        if (
          verifyResponse?.success === false ||
          verifyResponse?.tripjackRequestAccepted === false ||
          verifyResponse?.status?.success === false
        ) {
          setShowBookingFormModal(false);
          setBookingStatusState({
            phase: "denied",
            bookingId: verifyResponse?.bookingId || payload.bookingId,
            orderStatus: "",
            attempts: 0,
            message: `TripJack denied the booking request: ${verifyResponse?.error || verifyResponse?.errors?.[0]?.message || "Access Denied"}`,
            details: verifyResponse,
            errorCode: verifyResponse?.errors?.[0]?.errCode || "",
            paymentCaptured: true,
          });
          return;
        }

        const verifyOrderStatus = extractOrderStatusFromBookingDetails(verifyResponse);
        setShowBookingFormModal(false);
        setBookingStatusState({
          phase: "polling",
          bookingId: verifyResponse?.bookingId || payload.bookingId,
          orderStatus: verifyOrderStatus || "PAYMENT_SUCCESS",
          attempts: 0,
          message:
            ["SUCCESS", "CONFIRMED", "VOUCHERED"].includes(verifyOrderStatus || "")
              ? "TripJack confirmed this booking."
              : (verifyOrderStatus || "PAYMENT_SUCCESS") === "PAYMENT_SUCCESS"
              ? "Your payment is successful. We are waiting for final hotel confirmation from TripJack."
              : "Booking request accepted. Waiting for final TripJack status.",
          details: verifyResponse?.bookingDetails || verifyResponse,
          errorCode: "",
          paymentCaptured: true,
        });

        await pollTripjackBookingStatus(verifyResponse?.bookingId || payload.bookingId);
        return;
      }

      const orderResponse = await createHotelPaymentOrder(payload);
      const razorpayLoaded = await loadRazorpayScript();
      if (!razorpayLoaded || !window.Razorpay) {
        throw new Error("Unable to load Razorpay checkout");
      }

      setBookingStatusState({
        phase: "submitting",
        bookingId: payload.bookingId,
        orderStatus: "",
        attempts: 0,
        message: "Opening Razorpay checkout.",
        details: orderResponse,
        errorCode: "",
      });

      const isRazorpayTestMode = String(orderResponse?.keyId || "").startsWith("rzp_test_");

      const bookingResponse = await new Promise((resolve, reject) => {
        const razorpayInstance = new window.Razorpay({
          key: orderResponse?.keyId,
          order_id: orderResponse?.razorpayOrderId,
          amount: orderResponse?.amount,
          currency: orderResponse?.currency || "INR",
          name: "HappyWedz Hotels",
          description: orderResponse?.hotelName || "TripJack hotel booking",
          prefill: {
            name: user?.name || "",
            email: bookingForm?.deliveryInfo?.emails?.[0] || "",
            contact: bookingForm?.deliveryInfo?.contacts?.[0] || "",
          },
          theme: {
            color: "#ed1173",
          },
          method: isRazorpayTestMode
            ? {
                upi: false,
                wallet: false,
                paylater: false,
              }
            : undefined,
          modal: {
            ondismiss: () => {
              reject(new Error("Razorpay checkout closed before payment."));
            },
          },
          handler: async (paymentResult) => {
            try {
              setBookingStatusState({
                phase: "submitting",
                bookingId: payload.bookingId,
                orderStatus: "",
                attempts: 0,
                message: "Payment verified. Sending booking request to TripJack.",
                details: paymentResult,
                errorCode: "",
              });

              const verifyResponse = await verifyHotelPaymentAndBook({
                bookingId: payload.bookingId,
                razorpay_order_id: paymentResult?.razorpay_order_id || orderResponse?.razorpayOrderId,
                razorpay_payment_id: paymentResult?.razorpay_payment_id,
                razorpay_signature: paymentResult?.razorpay_signature,
              });
              resolve(verifyResponse);
            } catch (verifyError) {
              reject(verifyError);
            }
          },
        });

        razorpayInstance.on("payment.failed", (failure) => {
          const failureDescription =
            failure?.error?.description ||
            failure?.error?.reason ||
            failure?.error?.metadata?.message ||
            "";
          const providerSideConfigError =
            /org_id provided does not exist/i.test(failureDescription) ||
            /org_id/i.test(String(failure?.error?.step || ""));

          reject(
            new Error(
              providerSideConfigError
                ? "Razorpay test-mode wallet or UPI is not configured for this account. Please use card or netbanking."
                : failureDescription || "Razorpay payment failed."
            )
          );
        });

        razorpayInstance.open();
      });

      if (
        bookingResponse?.success === false ||
        bookingResponse?.tripjackRequestAccepted === false ||
        bookingResponse?.status?.success === false
      ) {
        setShowBookingFormModal(false);
        setBookingStatusState({
          phase: "denied",
          bookingId: bookingResponse?.bookingId || payload.bookingId,
          orderStatus: "",
          attempts: 0,
          message: `TripJack denied the booking request: ${bookingResponse?.error || bookingResponse?.errors?.[0]?.message || "Access Denied"}`,
          details: bookingResponse,
          errorCode: bookingResponse?.errors?.[0]?.errCode || "",
        });
        return;
      }

      const bookingOrderStatus = extractOrderStatusFromBookingDetails(bookingResponse);
      setShowBookingFormModal(false);
      setBookingStatusState({
        phase: "polling",
        bookingId: bookingResponse?.bookingId || payload.bookingId,
        orderStatus: bookingOrderStatus || "PAYMENT_SUCCESS",
        attempts: 0,
        message:
          ["SUCCESS", "CONFIRMED", "VOUCHERED"].includes(bookingOrderStatus || "")
            ? "TripJack confirmed this booking."
            : (bookingOrderStatus || "PAYMENT_SUCCESS") === "PAYMENT_SUCCESS"
            ? "Your payment is successful. We are waiting for final hotel confirmation from TripJack."
            : "Booking request accepted. Waiting for final TripJack status.",
        details: bookingResponse?.bookingDetails || bookingResponse,
        errorCode: "",
      });

      await pollTripjackBookingStatus(bookingResponse?.bookingId || payload.bookingId);
    } catch (error) {
      const timeoutOrCanceled =
        error?.code === "ECONNABORTED" ||
        error?.code === "ERR_CANCELED" ||
        /timeout|canceled|aborted/i.test(String(error?.message || ""));
      const validationFailure = error?.response?.data?.source === "VALIDATION";
      const duplicateBookingBlocked = Boolean(error?.response?.data?.duplicateBookingBlocked);
      const tripjackDenied =
        error?.response?.data?.source === "TRIPJACK" &&
        (
          error?.response?.data?.status?.success === false ||
          Number(error?.response?.data?.status_code || error?.response?.status || 0) === 400
        );
      const tripjackServerFailure =
        error?.response?.data?.source === "TRIPJACK" &&
        Number(error?.response?.data?.status_code || error?.response?.status || 0) >= 500;
      const paymentErrorText = String(
        error?.response?.data?.error ||
        error?.response?.data?.message ||
        error?.message ||
        ""
      );
      const paymentFailure =
        error?.response?.data?.source === "PAYMENT" ||
        /razorpay/i.test(paymentErrorText) ||
        /international cards are not supported/i.test(paymentErrorText) ||
        /international_transaction_not_allowed/i.test(paymentErrorText) ||
        /payment could not be completed/i.test(paymentErrorText);
      const requiresManualAction = Boolean(error?.response?.data?.requiresManualAction);
      const paymentCaptured = Boolean(error?.response?.data?.paymentCaptured);
      const supplierFailureMessage =
        requiresManualAction || paymentCaptured
          ? "TripJack is temporarily unavailable after payment verification. Do not retry payment. Please check booking status after a short while or contact support with the booking ID."
          : error?.response?.data?.error || "TripJack is temporarily unavailable. Please try again shortly.";
      const resolvedFailureMessage = validationFailure
        ? error?.response?.data?.error || "Booking request validation failed. Please check traveller details and try again."
        : tripjackDenied
          ? `TripJack rejected the booking request: ${error?.response?.data?.error || "Invalid traveller details or supplier validation failed."}`
          : tripjackServerFailure
            ? supplierFailureMessage
            : paymentFailure
              ? error?.response?.data?.error || error?.message || "Payment could not be completed."
              : "Unable to submit this booking. Please review traveller details and try again.";

      if (!duplicateBookingBlocked || (!timeoutOrCanceled && !tripjackDenied && !validationFailure)) {
        console.error("Unable to create TripJack booking", error);
      }

      if (timeoutOrCanceled && !tripjackDenied && !validationFailure) {
        const bookingIdForRecovery = error?.response?.data?.bookingId || payload.bookingId;
        setBookingStatusState({
          phase: "timeout",
          bookingId: bookingIdForRecovery,
          orderStatus: "PAYMENT_SUCCESS",
          attempts: 0,
          message:
            "Payment appears to be successful. TripJack is still confirming the booking. Please refresh status after a short while.",
          details: error?.response?.data || null,
          errorCode: "",
          allowClose: true,
        });
        toast.info("Payment appears successful. Refresh TripJack booking status after a short while.");
        return;
      }

      if (duplicateBookingBlocked) {
        const duplicateBookingId = error?.response?.data?.bookingId || payload.bookingId;
        const duplicateMessage =
          "Previous payment was already captured for this booking. Do not pay again. We are fetching the latest TripJack status.";
        setBookingStatusState({
          phase: "already_paid",
          bookingId: duplicateBookingId,
          orderStatus: error?.response?.data?.bookingSummary?.tripjackStatus || "",
          attempts: 0,
          message: duplicateMessage,
          details: error?.response?.data?.bookingDetails || error?.response?.data || null,
          errorCode: "",
          paymentCaptured: true,
          allowClose: true,
        });
        toast.info(duplicateMessage);
        await pollTripjackBookingStatus(duplicateBookingId);
        return;
      }

      setBookingStatusState({
        phase: validationFailure ? "validation_failed" : tripjackDenied ? "denied" : "failed",
        bookingId: payload.bookingId,
        orderStatus: "",
        attempts: 0,
        message: resolvedFailureMessage,
        details: error?.response?.data || null,
        errorCode: error?.response?.data?.errors?.[0]?.errCode || "",
        paymentCaptured,
        allowClose: tripjackServerFailure || requiresManualAction || paymentCaptured,
      });
      toast.error(resolvedFailureMessage);
    } finally {
      setBookingSubmitting(false);
    }
  };

  const handleRefreshBookingStatus = async () => {
    const currentBookingId = bookingStatusState?.bookingId || reviewResponse?.bookingId;
    if (!currentBookingId) return;
    await pollTripjackBookingStatus(currentBookingId);
  };

  const currentStatusBookingId = bookingStatusState?.bookingId || reviewResponse?.bookingId || "";
  const currentStatusCode = String(
    bookingStatusState?.details?.order?.status ||
      bookingStatusState?.details?.orderStatus ||
      bookingStatusState?.orderStatus ||
      "",
  ).toUpperCase();
  const holdBookingType = String(
    bookingStatusState?.details?.bookingType ||
      bookingStatusState?.details?.booking_type ||
      ""
  ).toUpperCase();
  const holdPaymentStatus = String(
    bookingStatusState?.details?.paymentStatus ||
      bookingStatusState?.details?.payment_status ||
      ""
  ).toUpperCase();
  const isHoldPendingPayment =
    ["ON_HOLD", "IN_PROGRESS", "PENDING", "PAYMENT_PENDING"].includes(currentStatusCode) &&
    (holdBookingType === "HOLD" || currentStatusCode === "ON_HOLD") &&
    holdPaymentStatus !== "PAID";

  const isTerminalSuccessStatus = ["SUCCESS", "CONFIRMED", "VOUCHERED"].includes(currentStatusCode);
  const canDownloadReceipt =
    Boolean(currentStatusBookingId) &&
    isTerminalSuccessStatus &&
    !isHoldPendingPayment;
  const canDownloadVoucher =
    Boolean(currentStatusBookingId) &&
    isTerminalSuccessStatus &&
    !isHoldPendingPayment;
  const canPayHold = Boolean(currentStatusBookingId) && isHoldPendingPayment;

  const handleEditDetailsAndRetry = () => {
    setShowBookingStatusModal(false);
    setShowBookingFormModal(true);
  };

  const handleDownloadReceipt = async () => {
    if (!currentStatusBookingId || documentLoading) return;
    setDocumentLoading("receipt");
    try {
      await downloadHotelReceipt(currentStatusBookingId);
    } catch (error) {
      const message =
        error?.response?.data?.error ||
        error?.message ||
        "Unable to download booking receipt right now.";
      console.error("Unable to download TripJack receipt", error);
      toast.error(message);
    } finally {
      setDocumentLoading("");
    }
  };

  const handleCreateHoldBooking = async () => {
    if (!reviewResponse?.bookingId || !bookingForm) {
      toast.error("Booking review data is missing. Please review the room again.");
      return;
    }

    if (!isAuthenticated || !user?.id) {
      parkBookingAndLogin("hold");
      return;
    }

    const validationErrors = validateBookingForm(bookingForm, reviewResponse);
    if (validationErrors.length > 0) {
      toast.error(validationErrors[0]);
      return;
    }

    const payload = buildBookingPayload({ includePayment: false });
    setBookingSubmitting(true);
    setShowBookingStatusModal(true);
    setBookingStatusState({
      phase: "submitting",
      bookingId: payload.bookingId,
      orderStatus: "",
      attempts: 0,
      message: "Creating hold booking with TripJack.",
      details: null,
      errorCode: "",
    });

    try {
      const holdResponse = await holdHotelBooking(payload);

      if (
        holdResponse?.success === false ||
        holdResponse?.tripjackRequestAccepted === false ||
        holdResponse?.status?.success === false
      ) {
        setShowBookingFormModal(false);
        setBookingStatusState({
          phase: "failed",
          bookingId: holdResponse?.bookingId || payload.bookingId,
          orderStatus: "",
          attempts: 0,
          message: holdResponse?.error || holdResponse?.errors?.[0]?.message || "TripJack hold booking request failed.",
          details: holdResponse,
          errorCode: holdResponse?.errors?.[0]?.errCode || "",
        });
        return;
      }

      setShowBookingFormModal(false);
      setBookingStatusState({
        phase: "success",
        bookingId: holdResponse?.bookingId || payload.bookingId,
        orderStatus: String(holdResponse?.orderStatus || "ON_HOLD").toUpperCase(),
        attempts: 1,
        message: holdResponse?.message || "Hold booking created successfully.",
        details: holdResponse,
        errorCode: "",
      });
      toast.success("Hold booking created successfully.");
    } catch (error) {
      const message =
        error?.response?.data?.error ||
        error?.response?.data?.message ||
        error?.message ||
        "Unable to create hold booking right now.";
      setBookingStatusState({
        phase: "failed",
        bookingId: payload.bookingId,
        orderStatus: "",
        attempts: 0,
        message,
        details: error?.response?.data || null,
        errorCode: error?.response?.data?.errors?.[0]?.errCode || "",
      });
      toast.error(message);
    } finally {
      setBookingSubmitting(false);
    }
  };

  const handleDownloadVoucher = async () => {
    if (!currentStatusBookingId || documentLoading) return;
    setDocumentLoading("voucher");
    try {
      await downloadHotelVoucher(currentStatusBookingId);
    } catch (error) {
      const message =
        error?.response?.data?.error ||
        error?.message ||
        "Unable to download booking voucher right now.";
      console.error("Unable to download TripJack voucher", error);
      toast.error(message);
    } finally {
      setDocumentLoading("");
    }
  };

  const handlePayHoldBooking = async () => {
    if (!currentStatusBookingId || documentLoading) return;
    if (!bookingForm || !reviewResponse) {
      toast.error("Booking form details are missing. Please review room details again.");
      return;
    }

    const payload = buildBookingPayload({ includePayment: true });
    setDocumentLoading("hold_payment");
    try {
      const orderResponse = await createHotelPaymentOrder(payload);
      const razorpayLoaded = await loadRazorpayScript();
      if (!razorpayLoaded || !window.Razorpay) {
        throw new Error("Unable to load Razorpay checkout");
      }

      setBookingStatusState((current) => ({
        ...current,
        phase: "submitting",
        message: "Opening Razorpay checkout for hold confirmation.",
      }));

      const verifyResponse = await new Promise((resolve, reject) => {
        const razorpayInstance = new window.Razorpay({
          key: orderResponse?.keyId,
          order_id: orderResponse?.razorpayOrderId,
          amount: orderResponse?.amount,
          currency: orderResponse?.currency || "INR",
          name: "HappyWedz Hotels",
          description: orderResponse?.hotelName || "TripJack hold booking confirmation",
          prefill: {
            name: user?.name || "",
            email: bookingForm?.deliveryInfo?.emails?.[0] || "",
            contact: bookingForm?.deliveryInfo?.contacts?.[0] || "",
          },
          theme: {
            color: "#ed1173",
          },
          modal: {
            ondismiss: () => reject(new Error("Razorpay checkout closed before payment.")),
          },
          handler: async (paymentResult) => {
            try {
              const response = await confirmHotelBooking({
                bookingId: currentStatusBookingId,
                paymentInfos:
                  Number(orderResponse?.displayAmount || orderResponse?.amountDisplay || payload?.paymentInfos?.[0]?.amount || 0) > 0
                    ? [
                        {
                          amount: Number(
                            orderResponse?.displayAmount ||
                              orderResponse?.amountDisplay ||
                              payload?.paymentInfos?.[0]?.amount ||
                              0
                          ),
                        },
                      ]
                    : payload?.paymentInfos || [],
                razorpay_order_id: paymentResult?.razorpay_order_id || orderResponse?.razorpayOrderId,
                razorpay_payment_id: paymentResult?.razorpay_payment_id,
                razorpay_signature: paymentResult?.razorpay_signature,
              });
              resolve(response);
            } catch (error) {
              reject(error);
            }
          },
        });

        razorpayInstance.on("payment.failed", (failure) => {
          reject(
            new Error(
              failure?.error?.description ||
                failure?.error?.reason ||
                "Razorpay payment failed."
            )
          );
        });

        razorpayInstance.open();
      });

      const holdOrderStatus = extractOrderStatusFromBookingDetails(verifyResponse);
      setBookingStatusState({
        phase: "polling",
        bookingId: verifyResponse?.bookingId || currentStatusBookingId,
        orderStatus: holdOrderStatus || "PAYMENT_SUCCESS",
        attempts: 0,
        message:
          ["SUCCESS", "CONFIRMED", "VOUCHERED"].includes(holdOrderStatus || "")
            ? "TripJack confirmed this booking."
            : "Payment completed. Waiting for final TripJack booking confirmation.",
        details: verifyResponse?.bookingDetails || verifyResponse,
        errorCode: "",
        paymentCaptured: true,
      });
      await pollTripjackBookingStatus(verifyResponse?.bookingId || currentStatusBookingId);
    } catch (error) {
      const message =
        error?.response?.data?.error ||
        error?.response?.data?.message ||
        error?.message ||
        "Unable to process hold booking payment right now.";
      toast.error(message);
      setBookingStatusState((current) => ({
        ...current,
        phase: "failed",
        message,
      }));
    } finally {
      setDocumentLoading("");
    }
  };

  const handleOpenGallery = (index) => {
    setGalleryIndex(index);
    setShowGalleryModal(true);
  };

  const handleOpenAmenitiesModal = async () => {
    setShowAmenitiesModal(true);
    try {
      await trackHotelAnalyticsEvent({
        event: "Hotel_PDP_Amenities_ViewMore",
        properties: {
          Hotel_Name: detailModel.name,
          Star_Rating: detailModel.starRating || 0,
          Unica_Id: detailModel.id,
          Search_Id: reviewPayloadFields.searchId || "",
          CityName: String(detailModel.cityName || "").toUpperCase(),
          City_Id: "",
          Agent_Id: "313144",
          User_Role: "AGENT",
          User_Email: "nahatarishabh23@gmail.com",
          Current_Page: typeof window !== "undefined" ? window.location.href : "",
          Current_Path: typeof window !== "undefined" ? window.location.pathname : "",
          Previous_Page: typeof document !== "undefined" ? document.referrer || "" : "",
          Previous_Path:
            typeof document !== "undefined" && document.referrer
              ? new URL(document.referrer).pathname
              : "",
          Product: "HOTEL",
          Date: fmtDate(new Date()),
          TimeStamp: new Date().toISOString(),
        },
      });
    } catch (error) {
      console.error("Unable to track amenities view more event", error);
    }
  };

  const handleOpenRoomAmenitiesModal = (option) => {
    setActiveOption(buildRoomModalOption(option));
    setRoomModalOpen(true);

    const previousPage = typeof document !== "undefined" ? document.referrer || "" : "";
    let previousPath = "";
    if (previousPage) {
      try {
        previousPath = new URL(previousPage).pathname;
      } catch {
        previousPath = "";
      }
    }

    const rawSearchType =
      reviewPayloadFields.searchType ||
      initialPayload?.searchQuery?.searchCriteria?.searchRegionType ||
      initialPayload?.searchType ||
      selectedHotel?.raw?.searchType ||
      selectedHotel?.raw?.searchRegionType ||
      "";

    const searchType = String(rawSearchType || (selectedHotel?.raw?.tjid || detailModel.id ? "HOTEL" : "CITY"))
      .trim()
      .toUpperCase();

    const hotelSearchId =
      selectedHotel?.raw?.hid ||
      selectedHotel?.raw?.hotelId ||
      selectedHotel?.raw?.hotelCode ||
      initialPayload?.searchQuery?.searchCriteria?.hotelId ||
      initialPayload?.searchQuery?.searchCriteria?.hotelCode ||
      initialPayload?.searchQuery?.searchCriteria?.city;

    const cityName = searchType === "HOTEL"
      ? detailModel.name
      : String(detailModel.cityName || "").toUpperCase();

    const cityId = searchType === "HOTEL"
      ? hotelSearchId
      : (
          detailModel.cityId ||
          initialPayload?.searchQuery?.searchCriteria?.city ||
          ""
        );

    trackTripjackAnalyticsEvent({
      event: "Hotel_PDP_RoomType_Amenities_ViewMore",
      properties: compactProperties({
        Product: "HOTEL",
        Hotel_Name: detailModel.name,
        Star_Rating: detailModel.starRating || 0,
        Unica_Id: detailModel.id,
        Search_Id: reviewPayloadFields.searchId || "",
        Search_Type: searchType,
        CityName: cityName,
        City_Id: String(cityId || ""),
        Room_Type: option?.roomName,
        Current_Page: typeof window !== "undefined" ? window.location.href : "",
        Current_Path: typeof window !== "undefined" ? window.location.pathname : "",
        Previous_Page: previousPage,
        Previous_Path: previousPath,
        Date: fmtDate(new Date()),
        TimeStamp: new Date().toISOString(),
        Agent_Id: "313144",
        User_Email: "nahatarishabh23@gmail.com",
        User_Role: "AGENT",
      }),
    }).catch((error) => {
      if (import.meta.env.DEV) {
        console.error("Unable to track room amenities view more event", error);
      }
    });
  };

  return (
    <div className="hotel-list-page">
      <div className="hotel-shell">
        <HotelSearchBarEditable
          payload={initialPayload}
          suggestion={initialSuggestion}
          onBackToSearch={onBackToResults}
        />

        {showBookingFormModal && reviewResponse && bookingForm ? (
          <TripJackBookingReview
            show={showBookingFormModal}
            onClose={() => {
              // "Back to Hotel Details" is an explicit abandon.
              clearBookingDraft();
              setShowBookingFormModal(false);
            }}
            reviewResponse={reviewResponse}
            bookingForm={bookingForm}
            onTravellerFieldChange={handleTravellerFieldChange}
            onContactFieldChange={handleContactFieldChange}
            onTermsChange={handleTermsChange}
            onSubmit={handleProceedToBook}
            onHoldSubmit={handleCreateHoldBooking}
            bookingSubmitting={bookingSubmitting}
            formatMoney={formatMoney}
            formatDate={formatDate}
            holdBookingUatEnabled={true}
          />
        ) : detailLoading && !detailModel.name ? (
          <HotelDetailsSkeleton />
        ) : (
          <div className="hotel-detail-shell hoteldetails hotel__container">
            <div className="hotel-detail-card hotel-detail-hero-card hotel-details-container">
              <HotelHeader
                detailModel={detailModel}
                onBackToResults={onBackToResults}
                onEditMarkup={() => setShowMarkupModal(true)}
                markupEnabled={markupEnabled}
              />
              
              <div className="hotel-detail-overview hotel-basic-info">
                <div className="hoteldetails__leftboxes">
                  <HotelGallery images={detailModel.images} hotelName={detailModel.name} onOpenGallery={handleOpenGallery} />
                  <HotelAboutSection
                    aboutText={detailModel.aboutText}
                    headline={detailModel.headline}
                    hasDetails={hasPropertyDetails}
                    onOpenModal={() => setShowAboutModal(true)}
                  />
                  <HotelAboutModal
                    show={showAboutModal}
                    onHide={() => setShowAboutModal(false)}
                    sections={detailModel.aboutSections || {}}
                  />
                  <HotelAmenities amenities={detailModel.amenities} onViewMore={handleOpenAmenitiesModal} />
                  {hasImportantInfo ? (
                    <section className="hotel-detail-section">
                      <h4>Important information</h4>
                      <button
                        type="button"
                        className="hotel-inline-link"
                        onClick={() => setShowImportantInfoModal(true)}
                      >
                        View property &amp; important information
                      </button>
                    </section>
                  ) : null}
                  <HotelImportantInfoModal
                    show={showImportantInfoModal}
                    onHide={() => setShowImportantInfoModal(false)}
                    propertyInfo={detailModel.propertyInfo || {}}
                    importantInformation={detailModel.importantInformation || {}}
                  />
                </div>

                <HotelBookingSummaryCard
                  option={selectedOption}
                  roomSummary={roomSummary}
                  onViewDetails={(option) => handleSelectRoom(option, true)}
                  onBookNow={(option) => handleReviewRoomOption(option)}
                  onViewAllRooms={() => roomSectionRef.current?.scrollIntoView({ behavior: "smooth", block: "start" })}
                  hotelPanRequired={detailModel.panRequired}
                  hotelPassportRequired={detailModel.passportRequired}
                  reviewLoadingOptionId={reviewLoadingOptionId}
                />
              </div>
            </div>

            <RoomTypesSection
              options={detailModel.options}
              filteredOptions={filteredOptions}
              roomSearch={roomSearch}
              setRoomSearch={setRoomSearch}
              filterState={filterState}
              setFilterState={setFilterState}
              mealPlans={mealPlans}
              selectedOptionId={selectedOptionId}
              onSelectRoom={(option) => handleReviewRoomOption(option)}
              onViewDetails={handleOpenRoomAmenitiesModal}
              onViewPolicy={handleViewPolicy}
              onViewMoreAmenities={handleOpenRoomAmenitiesModal}
              shareHref={shareHref}
              onOpenMobileFilters={() => setShowRoomFilters(true)}
              roomSectionRef={roomSectionRef}
              detailLoading={detailLoading}
              reviewLoadingOptionId={reviewLoadingOptionId}
            />

            {selectedOption ? (
              <div className="hotel-detail-mobile-cta">
                <div>
                  <div className="fw-bold">{selectedOption.roomName}</div>
                  <div className="hotel-summary-subcopy text-white-50">
                    {selectedOption.totalPrice ? formatMoney(selectedOption.totalPrice, selectedOption.currency) : "Price unavailable"}
                  </div>
                </div>
                <button
                  type="button"
                  className="hotel-card-cta"
                  onClick={() => handleReviewRoomOption(selectedOption)}
                  disabled={Boolean(reviewLoadingOptionId)}
                >
                  {reviewLoadingOptionId === selectedOption.id ? "Reviewing..." : "Book Now"}
                </button>
              </div>
            ) : null}
          </div>
        )}
      </div>

      <Modal show={showAmenitiesModal} onHide={() => setShowAmenitiesModal(false)} centered size="lg">
        <div className="modal-content rounded-4">
          <div className="modal-header border-0">
            <div>
              <h5 className="modal-title">{detailModel.name}</h5>
              <div className="fs-16 mt-2">Hotel Amenities</div>
            </div>
            <button type="button" className="btn-close" onClick={() => setShowAmenitiesModal(false)} />
          </div>
          <div className="modal-body">
            {detailModel.amenityGroups?.length ? (
              <div className="hotel-amenities-modal-groups">
                {detailModel.amenityGroups.map((group) => (
                  <div key={group.title} className="hotel-amenities-modal-group">
                    <div className="hotel-amenities-modal-title">{group.title}</div>
                    <div className="hotel-amenities-modal-grid">
                      {group.items.map((item) => (
                        <div key={`${group.title}-${item.id}-${item.name}`} className="hotel-amenities-modal-item">
                          <Check size={14} color="#6d7483" />
                          <span>{item.subtext ? `${item.name} (${item.subtext})` : item.name}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="hotel-detail-amenities">
                {detailModel.amenities.map((amenity, index) => {
                  let amenityText = "";
                  if (typeof amenity === "string") {
                    amenityText = amenity;
                  } else if (typeof amenity === "object" && amenity !== null) {
                    amenityText = amenity.name || amenity.nm || amenity.label || String(amenity);
                  } else {
                    amenityText = String(amenity || "");
                  }
                  
                  // Skip if empty or is still an object string
                  if (!amenityText || amenityText === "[object Object]") return null;
                  
                  return (
                    <span key={`${amenityText}-${index}`} className="hotel-detail-amenity">
                      <Check size={14} color="#ed1173" />
                      {amenityText}
                    </span>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </Modal>

      <RoomPolicyModal
        show={showPolicyModal}
        onHide={() => setShowPolicyModal(false)}
        option={selectedPolicyOption}
        hotelName={detailModel.name}
        starRating={detailModel.starRating}
        searchId={detailModel.meta.searchId}
      />

      <MarkupModal
        show={showMarkupModal}
        onHide={() => setShowMarkupModal(false)}
        onUpdate={handleUpdateMarkup}
      />

      <Modal show={showGalleryModal} onHide={() => setShowGalleryModal(false)} centered size="xl">
        <div className="modal-content rounded-4">
          <div className="modal-header border-0">
            <h5 className="modal-title">{detailModel.name} photos</h5>
            <button type="button" className="btn-close" onClick={() => setShowGalleryModal(false)} />
          </div>
          <div className="modal-body">
            {detailModel.images[galleryIndex]?.url ? (
              <img
                src={detailModel.images[galleryIndex].url}
                alt={detailModel.name}
                style={{ width: "100%", maxHeight: 420, objectFit: "cover", borderRadius: 18 }}
              />
            ) : null}
            <div className="hotel-gallery-modal-grid mt-3">
              {detailModel.images.map((image, index) => (
                <button
                  key={`${image.url}-${index}`} type="button"
                  style={{ border: "none", background: "transparent", padding: 0 }}
                  onClick={() => setGalleryIndex(index)}
                >
                  <img src={image.url} alt={`${detailModel.name} ${index + 1}`} />
                </button>
              ))}
            </div>
          </div>
        </div>
      </Modal>

      <Offcanvas show={showRoomFilters} onHide={() => setShowRoomFilters(false)} placement="bottom">
        <Offcanvas.Header closeButton>
          <Offcanvas.Title>Room filters</Offcanvas.Title>
        </Offcanvas.Header>
        <Offcanvas.Body>
          <div className="d-grid gap-3">
            <input
              className="hotel-room-search"
              placeholder="Search by Room Type/Room Category"
              value={roomSearch}
              onChange={(event) => setRoomSearch(event.target.value)}
            />
            <button
              type="button"
              className={`hotel-room-filter-chip ${filterState.refundable ? "active" : ""}`}
              onClick={() => setFilterState((prev) => ({ ...prev, refundable: !prev.refundable }))}
            >
              Refundable
            </button>
            <button
              type="button"
              className={`hotel-room-filter-chip ${filterState.breakfastIncluded ? "active" : ""}`}
              onClick={() => setFilterState((prev) => ({ ...prev, breakfastIncluded: !prev.breakfastIncluded }))}
            >
              Breakfast Included
            </button>
            <button
              type="button"
              className={`hotel-room-filter-chip ${filterState.panOptional ? "active" : ""}`}
              onClick={() => setFilterState((prev) => ({ ...prev, panOptional: !prev.panOptional }))}
            >
              PAN Optional
            </button>
            <label className="hotel-room-filter-chip">
              Meal Plan
              <select
                value={filterState.mealPlan}
                onChange={(event) => setFilterState((prev) => ({ ...prev, mealPlan: event.target.value }))}
                style={{ border: "none", background: "transparent", fontWeight: 800 }}
              >
                <option value="">All</option>
                {mealPlans.map((plan) => (
                  <option key={plan.value} value={plan.value}>
                    {plan.label}
                  </option>
                ))}
              </select>
            </label>
          </div>
        </Offcanvas.Body>
      </Offcanvas>

      <Modal show={showReviewModal} onHide={() => setShowReviewModal(false)} centered size="lg">
        <div className="modal-content rounded-4">
          <div className="modal-header border-0">
            <div>
              <h5 className="modal-title">Booking Review</h5>
              <div className="fs-12 text-muted">TripJack review response received</div>
            </div>
            <button type="button" className="btn-close" onClick={() => setShowReviewModal(false)} />
          </div>
          <div className="modal-body">
            {reviewResponse ? (
              <div className="d-grid gap-3">
                <div className="border rounded-4 p-3 bg-light-subtle">
                  <div className="fw-bold mb-1">{reviewResponse.displayRoomName || "Selected room"}</div>
                  <div className="fs-14 text-muted">{reviewResponse.displayHotelName || detailModel.name}</div>
                </div>

                <div className="row g-3">
                  <div className="col-md-6">
                    <div className="border rounded-4 p-3 h-100">
                      <div className="text-muted fs-12 mb-1">Booking ID</div>
                      <div className="fw-bold">{reviewResponse.bookingId || "Unavailable"}</div>
                    </div>
                  </div>
                  <div className="col-md-6">
                    <div className="border rounded-4 p-3 h-100">
                      <div className="text-muted fs-12 mb-1">Total Amount</div>
                      <div className="fw-bold">
                        {reviewResponse?.priceSummary?.amount
                          ? formatMoney(reviewResponse.priceSummary.amount, reviewResponse.priceSummary.currency || "INR")
                          : "Price unavailable"}
                      </div>
                    </div>
                  </div>
                  <div className="col-md-6">
                    <div className="border rounded-4 p-3 h-100">
                      <div className="text-muted fs-12 mb-1">Base Fare</div>
                      <div className="fw-bold">
                        {reviewResponse?.priceSummary?.baseFare
                          ? formatMoney(reviewResponse.priceSummary.baseFare, reviewResponse.priceSummary.currency || "INR")
                          : "Not provided"}
                      </div>
                    </div>
                  </div>
                  <div className="col-md-6">
                    <div className="border rounded-4 p-3 h-100">
                      <div className="text-muted fs-12 mb-1">Taxes & Fees</div>
                      <div className="fw-bold">
                        {reviewResponse?.priceSummary?.taxesAndFees
                          ? formatMoney(reviewResponse.priceSummary.taxesAndFees, reviewResponse.priceSummary.currency || "INR")
                          : "Not provided"}
                      </div>
                    </div>
                  </div>
                  <div className="col-md-6">
                    <div className="border rounded-4 p-3 h-100">
                      <div className="text-muted fs-12 mb-1">Meal Basis</div>
                      <div className="fw-bold">{reviewResponse?.roomSummary?.mealBasis || "Not provided"}</div>
                    </div>
                  </div>
                  <div className="col-md-6">
                    <div className="border rounded-4 p-3 h-100">
                      <div className="text-muted fs-12 mb-1">PAN Requirement</div>
                      <div className="fw-bold">
                        {reviewResponse?.bookingRequirements?.panRequired ? "Required" : "Not required"}
                      </div>
                    </div>
                  </div>
                  <div className="col-md-6">
                    <div className="border rounded-4 p-3 h-100">
                      <div className="text-muted fs-12 mb-1">Passport Requirement</div>
                      <div className="fw-bold">
                        {reviewResponse?.bookingRequirements?.passportRequired ? "Required" : "Not required"}
                      </div>
                    </div>
                  </div>
                  <div className="col-md-6">
                    <div className="border rounded-4 p-3 h-100">
                      <div className="text-muted fs-12 mb-1">Refundability</div>
                      <div className="fw-bold">
                        {reviewResponse?.bookingRequirements?.isRefundable
                          ? "Refundable"
                          : reviewResponse?.bookingRequirements?.isNonRefundable
                            ? "Non-refundable"
                            : "Policy available"}
                      </div>
                    </div>
                  </div>
                  <div className="col-md-6">
                    <div className="border rounded-4 p-3 h-100">
                      <div className="text-muted fs-12 mb-1">Check-in Time</div>
                      <div className="fw-bold">
                        {reviewResponse?.hotelSummary?.checkInTime?.time ||
                          reviewResponse?.hotelSummary?.checkInTime?.from ||
                          reviewResponse?.hotelSummary?.checkInTime?.value ||
                          "Not provided"}
                      </div>
                    </div>
                  </div>
                  <div className="col-md-6">
                    <div className="border rounded-4 p-3 h-100">
                      <div className="text-muted fs-12 mb-1">Check-out Time</div>
                      <div className="fw-bold">
                        {reviewResponse?.hotelSummary?.checkOutTime?.time ||
                          reviewResponse?.hotelSummary?.checkOutTime?.to ||
                          reviewResponse?.hotelSummary?.checkOutTime?.value ||
                          "Not provided"}
                      </div>
                    </div>
                  </div>
                  <div className="col-md-6">
                    <div className="border rounded-4 p-3 h-100">
                      <div className="text-muted fs-12 mb-1">Hold Deadline</div>
                      <div className="fw-bold">
                        {reviewResponse?.bookingRequirements?.deadlineDatetime
                          ? formatDate(reviewResponse.bookingRequirements.deadlineDatetime)
                          : "Not provided"}
                      </div>
                    </div>
                  </div>
                </div>

                <div className="border rounded-4 p-3">
                  <div className="fw-semibold mb-2">Cancellation Policy</div>
                  <div className="fs-14 text-muted">
                    {reviewResponse?.bookingRequirements?.isNonRefundable
                      ? "This room is non-refundable. Any cancellation may incur the full booking amount."
                      : reviewResponse?.bookingRequirements?.isRefundable
                        ? "Cancellation charges apply according to the hotel policy shown on the next step."
                        : "Hotel cancellation policy will be shown in the traveller details step."}
                  </div>
                </div>

                <div className="border rounded-4 p-3">
                  <div className="fw-semibold mb-2">Current Status</div>
                  <div className="fs-14 text-muted">
                    Review succeeded. Traveller details and final booking actions will be added in the next phase.
                  </div>
                </div>
              </div>
            ) : null}
          </div>
          <div className="modal-footer border-0">
            <Button variant="outline-secondary" onClick={() => setShowReviewModal(false)}>
              Close
            </Button>
            <Button variant="primary" onClick={handleOpenBookingForm} disabled={!reviewResponse?.bookingId}>
              Continue to Traveller Details
            </Button>
          </div>
        </div>
      </Modal>

      <TripJackBookingStatus
        show={showBookingStatusModal}
        statusState={bookingStatusState}
        reviewResponse={reviewResponse}
        onClose={() => setShowBookingStatusModal(false)}
        onRefresh={handleRefreshBookingStatus}
        onEditDetails={handleEditDetailsAndRetry}
        onDownloadReceipt={handleDownloadReceipt}
        onDownloadVoucher={handleDownloadVoucher}
        onPayHold={handlePayHoldBooking}
        canDownloadReceipt={canDownloadReceipt}
        canDownloadVoucher={canDownloadVoucher}
        canPayHold={canPayHold}
        documentLoading={documentLoading}
        formatMoney={formatMoney}
      />

      {activeOption ? (
        <Modal show={roomModalOpen} onHide={() => setRoomModalOpen(false)} centered size="lg" className="hotel-room-amenities-modal">
          <div className="modal-content rounded-4 hotel-room-modal">
            <div className="modal-header border-0 pb-0 hotel-room-modal-header">
              <div>
                <h5 className="modal-title hotel-room-modal-title">{activeOption.roomName}</h5>
              </div>
              <button type="button" className="btn-close" onClick={() => setRoomModalOpen(false)} />
            </div>

            <div className="modal-body pt-2 hotel-room-modal-body">
              <div className="hotel-room-modal-gallery">
                {activeOption.image ? (
                  <img src={activeOption.image} alt={activeOption.roomName} />
                ) : (
                  <div className="hotel-card-image hotel-card-image--empty">Image not available</div>
                )}
                {activeOption.images?.length > 1 ? (
                  <button
                    type="button"
                    className="hotel-room-modal-gallery-next"
                    onClick={() => {
                      setActiveOption((current) => {
                        if (!current?.images?.length) return current;
                        const rotatedImages = [...current.images.slice(1), current.images[0]];
                        return {
                          ...current,
                          images: rotatedImages,
                          image: rotatedImages[0]?.url || current.image,
                        };
                      });
                    }}
                  >
                    <ChevronRight size={18} />
                  </button>
                ) : null}
              </div>
              <div className="hotel-room-modal-meta">
                {activeOption.guestSummary ? (
                  <div className="hotel-room-modal-copy">{activeOption.guestSummary}</div>
                ) : null}
                {activeOption.bedSummary ? (
                  <div className="hotel-room-modal-copy">
                    <BedDouble size={14} />
                    {activeOption.bedSummary}
                  </div>
                ) : null}
              </div>
              <div className="hotel-room-modal-divider" />
              {(() => {
                const roomAmenities = Array.isArray(activeOption.inclusions)
                  ? activeOption.inclusions
                  : [];
                const hasRoomAmenities = roomAmenities.length > 0;
                const propertyAmenities = Array.isArray(detailModel.amenities)
                  ? detailModel.amenities.filter((item) => typeof item === "string" && item.trim())
                  : [];
                const list = hasRoomAmenities ? roomAmenities : propertyAmenities;
                return (
                  <>
                    <div className="hotel-room-modal-section-title">
                      {hasRoomAmenities ? "Room Amenities" : "Property Amenities"}
                    </div>
                    <div className="hotel-room-modal-section-subtitle">
                      {hasRoomAmenities
                        ? "Popular with Guests"
                        : "Room-specific amenities aren't listed for this room — showing what the property offers."}
                    </div>
                    <div className="hotel-room-modal-amenities">
                      {list.length > 0 ? (
                        list.map((amenity, index) => (
                          <div key={`${amenity}-${index}`} className="hotel-room-modal-amenity">
                            <Check size={14} color="#ed1173" />
                            <span title={amenity}>{amenity}</span>
                          </div>
                        ))
                      ) : (
                        <div className="fs-14 text-muted">No amenities available for this room.</div>
                      )}
                    </div>
                  </>
                );
              })()}
              {Array.isArray(activeOption.cancellation?.penalties) && activeOption.cancellation.penalties.length > 0 ? (
                <div className="fs-12 text-muted">
                  {activeOption.cancellation.penalties
                    .map((penalty) => `${penalty.from || "—"} to ${penalty.to || "—"} (${penalty.amount ?? "—"})`)
                    .join(" • ")}
                </div>
              ) : (
                <div className="fs-12 text-muted">Cancellation policy not available.</div>
              )}
            </div>
          </div>
        </Modal>
      ) : null}
    </div>
  );
}

export { HotelSearchBarEditable };
export default HotelDetailsPage;
