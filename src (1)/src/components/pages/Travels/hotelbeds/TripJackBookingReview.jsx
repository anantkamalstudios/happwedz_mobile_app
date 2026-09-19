import { useState } from "react";
import { Button } from "react-bootstrap";
import { ChevronDown, ChevronUp, ChevronsLeft, Mail, UtensilsCrossed } from "lucide-react";
import { formatDateWithWeekday } from "../../../../utils/dateFormat";

const adultTitleOptions = ["Mr", "Mrs", "Ms", "Miss"];
const countryCodeOptions = [
  { code: "91", label: "India" },
  { code: "971", label: "UAE" },
  { code: "44", label: "United Kingdom" },
  { code: "1", label: "USA / Canada" },
  { code: "65", label: "Singapore" },
  { code: "61", label: "Australia" },
];
const childTitleOptions = ["Master", "Miss"];

const getPrimaryImage = (reviewResponse) => {
  const hotelSummary = reviewResponse?.hotelSummary || {};
  const hotelInfo = reviewResponse?.hotelInfo || {};
  const images = hotelSummary?.images || hotelInfo?.images || hotelInfo?.img || [];
  const firstImage = Array.isArray(images) ? images[0] : null;
  return firstImage?.url || firstImage?.imageUrl || firstImage?.path || firstImage || "";
};

const STAY_MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const STAY_WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

// TripJack writes the stay dates as "Thu 10 Sep 2026".
const formatStayDate = (value) => {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return formatDateWithWeekday(value, { fallback: String(value) });
  }
  return `${STAY_WEEKDAYS[date.getDay()]} ${date.getDate()} ${STAY_MONTHS[date.getMonth()]} ${date.getFullYear()}`;
};

// TripJack's cancellation table dates read "09-09-2026".
const formatPolicyDate = (value) => {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);
  const pad = (n) => String(n).padStart(2, "0");
  return `${pad(date.getDate())}-${pad(date.getMonth() + 1)}-${date.getFullYear()}`;
};

// The fare summary is a payment figure, so it keeps its paise.
const formatFare = (amount, currency = "INR") => {
  const value = Number(amount);
  if (!Number.isFinite(value)) return "";
  const symbol = currency === "INR" ? "₹" : `${currency} `;
  return `${symbol}${value.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
};

const getNightCount = (checkIn, checkOut) => {
  const start = new Date(checkIn);
  const end = new Date(checkOut);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return 0;
  const diff = Math.round((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
  return diff > 0 ? diff : 0;
};

const getSummaryInfo = (searchQuery) => {
  const roomInfo = Array.isArray(searchQuery?.roomInfo) ? searchQuery.roomInfo : [];
  const totalRooms = roomInfo.length || 1;
  let totalGuests = 0;

  roomInfo.forEach((room) => {
    totalGuests += Number(room?.numberOfAdults || room?.adults || 0);
    totalGuests += Number(room?.numberOfChildren || room?.children || (Array.isArray(room?.childAge) ? room.childAge.length : 0) || 0);
  });

  return {
    totalRooms,
    totalGuests: totalGuests || 1,
  };
};

const getAddressText = (address) => {
  if (!address) return { line: "", postalCode: "" };
  return {
    line: [address?.adr, address?.adr2 || address?.adr_2]
      .filter(Boolean)
      .join(", "),
    postalCode: address?.pc || address?.postalCode || "",
  };
};

const toSentenceCase = (value) => {
  const text = String(value || "").trim();
  if (!text) return "";
  return text
    .split(" ")
    .map((word) => (word ? word[0].toUpperCase() + word.slice(1).toLowerCase() : word))
    .join(" ");
};

const formatTimeRange = (value) => {
  if (!value) return "";
  const begin = value?.beginTime || value?.startTime || value?.from || value?.time || value?.value || "";
  const end = value?.endTime || value?.to || "";
  if (begin && end) return `${begin} - ${end}`;
  return begin || end || "";
};

const getRoomBreakdown = (reviewResponse, roomTravellerInfo) => {
  const selectedOption = reviewResponse?.selectedOption || {};
  const roomInfos = Array.isArray(selectedOption?.roomInfos) && selectedOption.roomInfos.length
    ? selectedOption.roomInfos
    : Array.isArray(selectedOption?.ris) && selectedOption.ris.length
      ? selectedOption.ris
      : [];

  return roomTravellerInfo.map((room, index) => {
    const roomMeta = roomInfos[index] || roomInfos[0] || {};
    const travellers = Array.isArray(room?.travellerInfo) ? room.travellerInfo : [];
    return {
      title:
        roomMeta?.rt ||
        roomMeta?.srn ||
        reviewResponse?.displayRoomName ||
        reviewResponse?.roomSummary?.roomName ||
        `Room ${index + 1}`,
      mealBasis:
        roomMeta?.mb ||
        reviewResponse?.selectedOption?.mb ||
        reviewResponse?.roomSummary?.mealBasis ||
        "Room plan included",
      adults: travellers.filter((traveller) => traveller?.pt === "ADULT").length,
      children: travellers.filter((traveller) => traveller?.pt === "CHILD").length,
    };
  });
};

const getCancellationRows = (policy) => {
  const penalties = Array.isArray(policy?.pd) ? policy.pd : [];
  return penalties.map((item) => ({
    fromDate: item?.fdt || item?.fromDate || item?.from || "",
    toDate: item?.tdt || item?.toDate || item?.to || "",
    amount: item?.am ?? item?.charge ?? item?.amount ?? null,
    currency: item?.sc || item?.currency || "",
    remarks: item?.remarks || item?.comment || item?.type || "",
  }));
};

const getImportantNotes = (reviewResponse) => {
  const notes = [];
  const bookingConditions = reviewResponse?.bookingConditions;
  const alerts = Array.isArray(reviewResponse?.alerts) ? reviewResponse.alerts : [];

  if (bookingConditions && typeof bookingConditions === "object") {
    Object.values(bookingConditions).forEach((value) => {
      if (Array.isArray(value)) {
        value.forEach((item) => {
          if (typeof item === "string" && item.trim()) notes.push(item.trim());
        });
      } else if (typeof value === "string" && value.trim()) {
        notes.push(value.trim());
      }
    });
  }

  alerts.forEach((item) => {
    const message = typeof item === "string" ? item : item?.message || item?.msg || "";
    if (message) notes.push(message);
  });

  return notes.slice(0, 8);
};

const renderStars = (rating) => {
  const count = Math.max(0, Math.min(5, Math.round(Number(rating) || 0)));
  return Array.from({ length: 5 }, (_, index) => (
    <span key={`review-star-${index}`}>{index < count ? "★" : "☆"}</span>
  ));
};

export default function TripJackBookingReview({
  show,
  onClose,
  reviewResponse,
  bookingForm,
  onTravellerFieldChange,
  onContactFieldChange,
  onTermsChange,
  onSubmit,
  onHoldSubmit,
  bookingSubmitting,
  holdBookingUatEnabled = false,
}) {
  const [baseFareOpen, setBaseFareOpen] = useState(true);
  const [taxesOpen, setTaxesOpen] = useState(true);
  const [panMode, setPanMode] = useState("Personal PAN");

  if (!show || !reviewResponse || !bookingForm) return null;

  const bookingRequirements = reviewResponse?.bookingRequirements || {};
  const priceSummary = reviewResponse?.priceSummary || {};
  const roomSummary = reviewResponse?.roomSummary || {};
  const hotelSummary = reviewResponse?.hotelSummary || {};
  const hotelInfo = reviewResponse?.hotelInfo || {};
  const searchQuery = reviewResponse?.searchQuery || {};
  const roomTravellerInfo = Array.isArray(bookingForm?.roomTravellerInfo) ? bookingForm.roomTravellerInfo : [];
  const hotelImage = getPrimaryImage(reviewResponse);
  const hotelName = reviewResponse?.displayHotelName || hotelSummary?.name || hotelInfo?.name || "Selected hotel";
  const { line: addressLine, postalCode } = getAddressText(hotelSummary?.address || hotelInfo?.ad);
  const checkInDate = searchQuery?.checkInDate || searchQuery?.checkinDate;
  const checkOutDate = searchQuery?.checkoutDate || searchQuery?.checkOutDate;
  const nights = getNightCount(checkInDate, checkOutDate);
  const { totalRooms, totalGuests } = getSummaryInfo(searchQuery);
  const checkInTime = formatTimeRange(hotelSummary?.checkInTime || hotelInfo?.checkInTime);
  const checkOutTime = formatTimeRange(hotelSummary?.checkOutTime || hotelInfo?.checkOutTime);
  const roomBreakdown = getRoomBreakdown(reviewResponse, roomTravellerInfo);
  const cancellationRows = getCancellationRows(bookingRequirements?.cancellationPolicy);
  const policyNotes = Array.isArray(reviewResponse?.policyNotes) ? reviewResponse.policyNotes : [];
  const fareCurrency = priceSummary?.currency || "INR";
  // Whatever is not the management fee or its tax is our own markup.
  const fareMarkup = Math.max(
    0,
    Math.round(
      (Number(priceSummary?.taxesAndFees || 0) -
        Number(priceSummary?.managementFee || 0) -
        Number(priceSummary?.managementFeeTax || 0)) * 100
    ) / 100
  );
  const serviceFeePerNight =
    nights > 0 && totalRooms > 0 && Number(priceSummary?.managementFee) > 0
      ? Number(priceSummary.managementFee) / (nights * totalRooms)
      : 0;
  const importantNotes = getImportantNotes(reviewResponse);
  const displayRating = hotelSummary?.rating || hotelInfo?.rating || hotelInfo?.rt;

  return (
    <>
      <style>{`
        .tripjack-review-shell {
          width: min(1280px, 100%);
          margin: 0 auto;
          padding: 8px 24px 24px;
          box-sizing: border-box;
        }
        .tripjack-review-page {
          display: grid;
          gap: 22px;
        }
        .tripjack-review-head {
          display: flex;
          justify-content: space-between;
          gap: 16px;
          align-items: flex-start;
        }
        /* App.css sets global h1/h3 sizes with !important, which is why these headings
           came out at 48px and 32px against TripJack's 20px and 17px. */
        .tripjack-review-title {
          color: #1b2231;
          font-size: 20px !important;
          line-height: 1.2;
          font-weight: 700 !important;
          margin: 0;
        }
        .tripjack-review-page h3 {
          font-size: 17px !important;
          font-weight: 700 !important;
          color: #1b2231;
        }
        .tripjack-review-subtitle {
          color: #5f6678;
          font-size: 15px;
          line-height: 1.7;
          max-width: 760px;
          margin-top: 10px;
        }
        .tripjack-review-layout {
          display: grid;
          grid-template-columns: minmax(0, 1.7fr) 340px;
          gap: 24px;
          align-items: start;
        }
        .tripjack-review-main {
          display: grid;
          gap: 18px;
        }
        .tripjack-review-panel {
          background: #fff;
          border: 1px solid rgba(237, 17, 115, 0.14);
          border-radius: 24px;
          box-shadow: 0 18px 38px rgba(17, 24, 39, 0.06);
          overflow: hidden;
        }
        .tripjack-review-panel-inner {
          padding: 22px;
        }
        /* The stay grid and times row already have their own outlines, so the panel
           around them was drawing a second border. */
        .tripjack-review-panel--bare {
          background: transparent;
          border: 0;
          box-shadow: none;
          border-radius: 0;
        }
        .tripjack-review-panel--bare .tripjack-review-panel-inner {
          padding: 0;
        }
        .tripjack-hotel-summary {
          display: grid;
          grid-template-columns: 200px minmax(0, 1fr);
          gap: 20px;
          align-items: start;
        }
        .tripjack-hotel-photo {
          width: 100%;
          height: 140px;
          object-fit: cover;
          border-radius: 20px;
          background: linear-gradient(135deg, rgba(237, 17, 115, 0.12), rgba(246, 81, 150, 0.08));
        }
        .tripjack-review-back {
          display: inline-flex;
          align-items: center;
          gap: 4px;
          border: none;
          background: transparent;
          color: #c31767;
          font-weight: 700;
          font-size: 13px;
          padding: 0;
          white-space: nowrap;
        }
        .tripjack-hotel-meta {
          min-width: 0;
        }
        .tripjack-hotel-name-row {
          display: flex;
          align-items: flex-start;
          justify-content: space-between;
          gap: 16px;
        }
        .tripjack-hotel-name {
          color: #1b2231;
          font-size: 20px;
          font-weight: 700;
          line-height: 1.25;
        }
        /* Night count sits on the divider between the two dates. */
        .tripjack-stay-nights {
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 0 6px;
        }
        .tripjack-night-pill {
          background: rgba(237, 17, 115, 0.1);
          color: #1b2231;
          border-radius: 999px;
          padding: 5px 12px;
          font-size: 13px;
          font-weight: 700;
          white-space: nowrap;
        }
        .tripjack-stay-cell .tripjack-label,
        .tripjack-stay-time .tripjack-label {
          text-transform: none;
          letter-spacing: 0;
          font-size: 13px;
          font-weight: 400;
          color: #5f6678;
        }
        .tripjack-room-name {
          color: #1b2231;
          font-size: 16px;
          font-weight: 700;
        }
        .tripjack-room-terms {
          color: #1b2231;
          font-size: 15px;
          font-weight: 700;
        }
        .tripjack-room-form {
          border: 1px solid #e8eaf0;
          border-radius: 12px;
          overflow: hidden;
        }
        .tripjack-room-form-head {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 12px;
          flex-wrap: wrap;
          padding: 11px 16px;
          background: #eef2fb;
          font-size: 14px;
          font-weight: 700;
          color: #1b2231;
        }
        .tripjack-meal-tag {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          font-weight: 600;
          color: #4f5668;
        }
        .tripjack-room-form-occupancy {
          display: flex;
          align-items: center;
          gap: 14px;
          padding: 9px 16px;
          background: #fdf2f7;
          font-size: 13px;
          font-weight: 600;
          color: #1b2231;
        }
        .tripjack-occupancy-sep {
          width: 1px;
          height: 15px;
          background: rgba(237, 17, 115, 0.25);
        }
        .tripjack-room-form-body {
          padding: 16px;
        }
        .tripjack-guest-caption {
          font-size: 11px;
          letter-spacing: 0.08em;
          text-transform: uppercase;
          color: #8b92a1;
          font-weight: 600;
          margin-bottom: 10px;
        }
        .tripjack-input-icon {
          position: relative;
        }
        .tripjack-input-icon .form-control {
          padding-right: 38px;
        }
        .tripjack-input-icon svg {
          position: absolute;
          right: 12px;
          top: 50%;
          transform: translateY(-50%);
          color: #8b92a1;
          pointer-events: none;
        }
        .tripjack-pan-modes {
          display: flex;
          align-items: center;
          gap: 24px;
          flex-wrap: wrap;
          padding: 11px 16px;
          background: #eef2fb;
          border-radius: 10px;
        }
        .tripjack-pan-mode {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          font-size: 14px;
          font-weight: 600;
          color: #1b2231;
          margin: 0;
        }
        .tripjack-policy-footnotes {
          margin: 14px 0 0;
          padding-left: 18px;
          color: #4f5668;
          font-size: 13px;
          line-height: 1.7;
        }
        .tripjack-fare-toggle {
          width: 100%;
          border: none;
          background: transparent;
          text-align: left;
        }
        .tripjack-fare-toggle span {
          display: inline-flex;
          align-items: center;
          gap: 5px;
        }
        .tripjack-fare-subrow {
          color: #9aa1af;
          font-size: 13px;
          padding: 6px 0;
          border-bottom: 0;
        }
        .tripjack-fare-total {
          border-bottom: 0;
        }
        .tripjack-hotel-stars {
          display: inline-flex;
          gap: 4px;
          color: #f59e0b;
          font-size: 16px;
          line-height: 1;
          margin: 6px 0 10px;
        }
        .tripjack-hotel-address {
          color: #4f5668;
          font-size: 14px;
          line-height: 1.7;
        }
        .tripjack-stay-grid {
          display: grid;
          grid-template-columns: minmax(0, 1fr) auto repeat(3, minmax(0, 1fr));
          border: 1px solid rgba(237, 17, 115, 0.16);
          border-radius: 20px;
          overflow: hidden;
          background: linear-gradient(180deg, #fff 0%, #fff9fc 100%);
        }
        .tripjack-stay-cell {
          padding: 16px 14px;
          text-align: center;
          border-right: 1px solid rgba(237, 17, 115, 0.12);
        }
        .tripjack-stay-cell:last-child {
          border-right: 0;
        }
        /* Check-in/check-out window, shown as its own bar under the stay grid. */
        .tripjack-stay-times {
          display: grid;
          grid-template-columns: repeat(2, minmax(0, 1fr));
          margin-top: 10px;
          border: 1px solid rgba(237, 17, 115, 0.16);
          border-radius: 14px;
          overflow: hidden;
          background: #fff;
        }
        .tripjack-stay-time {
          display: flex;
          align-items: baseline;
          justify-content: center;
          gap: 8px;
          padding: 10px 14px;
          border-right: 1px solid rgba(237, 17, 115, 0.12);
        }
        .tripjack-stay-time:last-child {
          border-right: 0;
        }
        .tripjack-stay-time-value {
          background: rgba(237, 17, 115, 0.08);
          border-radius: 999px;
          padding: 4px 12px;
          font-size: 13px;
          font-weight: 700;
          color: #1b2231;
        }
        .tripjack-policy-notes {
          margin-top: 14px;
          padding-top: 12px;
          border-top: 1px solid #f0f1f5;
        }
        .tripjack-policy-note {
          font-size: 13px;
          line-height: 1.6;
          color: #4f5668;
          margin-bottom: 8px;
        }
        .tripjack-policy-note-label {
          font-weight: 700;
          color: #1b2231;
        }
        .tripjack-label {
          font-size: 11px;
          text-transform: uppercase;
          letter-spacing: 0.08em;
          color: #8b90a0;
          font-weight: 800;
          margin-bottom: 6px;
        }
        .tripjack-value {
          color: #1a2332;
          font-size: 15px;
          font-weight: 800;
          line-height: 1.45;
        }
        .tripjack-time-grid {
          display: grid;
          grid-template-columns: repeat(2, minmax(0, 1fr));
          gap: 16px;
        }
        .tripjack-time-card {
          border: 1px solid rgba(237, 17, 115, 0.12);
          border-radius: 18px;
          padding: 14px 18px;
          background: linear-gradient(180deg, #fff 0%, #fff8fb 100%);
        }
        .tripjack-room-card {
          padding: 18px 22px;
          border-top: 1px solid rgba(237, 17, 115, 0.1);
        }
        .tripjack-room-card:first-child {
          border-top: 0;
        }
        .tripjack-room-header {
          display: flex;
          justify-content: space-between;
          gap: 16px;
          flex-wrap: wrap;
          align-items: center;
        }
        .tripjack-room-header > :last-child {
          margin-right: auto;
          margin-left: 6%;
        }
        .tripjack-room-copy {
          color: #5f6678;
          font-size: 13px;
          line-height: 1.6;
        }
        .tripjack-guest-badge {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          border-radius: 12px;
          background: rgba(237, 17, 115, 0.06);
          color: #ab0f56;
          padding: 8px 12px;
          font-size: 12px;
          font-weight: 800;
        }
        .tripjack-form-card {
          border: 1px solid rgba(17, 24, 39, 0.08);
          border-radius: 20px;
          padding: 18px;
          background: linear-gradient(180deg, #fff 0%, #fffafb 100%);
        }
        .tripjack-policy-table {
          width: 100%;
          border-collapse: collapse;
          overflow: hidden;
          border-radius: 18px;
          border: 1px solid rgba(17, 24, 39, 0.08);
        }
        .tripjack-policy-table th,
        .tripjack-policy-table td {
          padding: 12px 14px;
          border-bottom: 1px solid rgba(17, 24, 39, 0.08);
          font-size: 13px;
          vertical-align: top;
        }
        .tripjack-policy-table th {
          background: rgba(237, 17, 115, 0.06);
          color: #9f1d59;
          font-weight: 800;
        }
        .tripjack-policy-table tr:last-child td {
          border-bottom: 0;
        }
        .tripjack-note-list {
          margin: 0;
          padding-left: 18px;
          display: grid;
          gap: 8px;
          color: #4f5668;
          font-size: 14px;
          line-height: 1.7;
        }
        .tripjack-review-aside {
          position: sticky;
          top: 12px;
          display: grid;
          gap: 16px;
        }
        .tripjack-fare-card {
          padding: 18px;
          border-radius: 22px;
          background: linear-gradient(180deg, rgba(237, 17, 115, 0.08) 0%, rgba(246, 81, 150, 0.03) 100%);
          border: 1px solid rgba(237, 17, 115, 0.12);
        }
        .tripjack-fare-row {
          display: flex;
          justify-content: space-between;
          gap: 12px;
          align-items: center;
          padding: 10px 0;
          border-bottom: 1px dashed rgba(17, 24, 39, 0.08);
          color: #4f5668;
          font-size: 14px;
        }
        .tripjack-fare-row:last-child {
          border-bottom: 0;
          padding-bottom: 0;
        }
        .tripjack-fare-row strong {
          color: #1b2231;
        }
        /* TripJack puts the pay button directly under the fare summary. */
        .tripjack-pay-actions {
          display: grid;
          gap: 10px;
          margin-top: 16px;
        }
        .tripjack-pay-actions .btn {
          width: 100%;
          font-weight: 700;
          padding: 11px 16px;
          border-radius: 10px;
        }
        .tripjack-action-bar {
          display: flex;
          justify-content: flex-end;
          gap: 12px;
          flex-wrap: wrap;
        }
        @media (max-width: 1100px) {
          .tripjack-review-layout {
            grid-template-columns: 1fr;
          }
          .tripjack-review-aside {
            position: static;
          }
        }
        @media (max-width: 820px) {
          .tripjack-review-shell {
            padding: 6px 14px 20px;
          }
          .tripjack-hotel-summary {
            grid-template-columns: 1fr;
          }
          .tripjack-stay-grid {
            grid-template-columns: repeat(2, minmax(0, 1fr));
          }
          .tripjack-stay-cell:nth-child(2n) {
            border-right: 0;
          }
          .tripjack-stay-cell {
            border-bottom: 1px solid rgba(237, 17, 115, 0.1);
          }
          .tripjack-stay-cell:last-child,
          .tripjack-stay-cell:nth-last-child(2) {
            border-bottom: 0;
          }
          .tripjack-time-grid {
            grid-template-columns: 1fr;
          }
          .tripjack-review-title {
            font-size: 30px;
          }
        }
        @media (max-width: 640px) {
          .tripjack-review-shell {
            padding: 4px 12px 16px;
          }
          .tripjack-stay-grid {
            grid-template-columns: 1fr;
          }
          .tripjack-stay-cell {
            border-right: 0;
          }
        }
      `}</style>

      <div className="tripjack-review-shell">
      <div className="tripjack-review-page">
        <div className="tripjack-review-head">
          <h1 className="tripjack-review-title">Review Your Booking</h1>
        </div>

        <div className="tripjack-review-layout">
          <div className="tripjack-review-main">
            <section className="tripjack-review-panel">
              <div className="tripjack-review-panel-inner">
                <div className="tripjack-hotel-summary">
                  {hotelImage ? (
                    <img src={hotelImage} alt={hotelName} className="tripjack-hotel-photo" />
                  ) : (
                    <div className="tripjack-hotel-photo d-flex align-items-center justify-content-center text-muted fw-semibold">
                      Hotel image
                    </div>
                  )}

                  <div className="tripjack-hotel-meta">
                    <div className="tripjack-hotel-name-row">
                      <div className="tripjack-hotel-name">{hotelName}</div>
                      <button
                        type="button"
                        className="tripjack-review-back"
                        onClick={onClose}
                        disabled={bookingSubmitting}
                      >
                        <ChevronsLeft size={14} />
                        Back to hotel details
                      </button>
                    </div>
                    {displayRating ? <div className="tripjack-hotel-stars">{renderStars(displayRating)}</div> : null}
                    {addressLine ? <div className="tripjack-hotel-address">{addressLine}</div> : null}
                    {postalCode ? <div className="tripjack-hotel-address">Postal Code: {postalCode}</div> : null}
                  </div>
                </div>
              </div>
            </section>

            <section className="tripjack-review-panel tripjack-review-panel--bare">
              <div className="tripjack-review-panel-inner">
                <div className="tripjack-stay-grid">
                  <div className="tripjack-stay-cell">
                    <div className="tripjack-label">Check In</div>
                    <div className="tripjack-value">{formatStayDate(checkInDate) || "Available after search"}</div>
                  </div>
                  <div className="tripjack-stay-nights">
                    <span className="tripjack-night-pill">
                      {nights > 0 ? `${nights} Night${nights > 1 ? "s" : ""}` : "Nights"}
                    </span>
                  </div>
                  <div className="tripjack-stay-cell">
                    <div className="tripjack-label">Check Out</div>
                    <div className="tripjack-value">{formatStayDate(checkOutDate) || "Available after search"}</div>
                  </div>
                  <div className="tripjack-stay-cell">
                    <div className="tripjack-label">Total Rooms</div>
                    <div className="tripjack-value">{`${totalRooms} Room${totalRooms > 1 ? "s" : ""}`}</div>
                  </div>
                  <div className="tripjack-stay-cell">
                    <div className="tripjack-label">Total Guests</div>
                    <div className="tripjack-value">{`${totalGuests} Guest${totalGuests > 1 ? "s" : ""}`}</div>
                  </div>
                </div>

                {checkInTime || checkOutTime ? (
                  <div className="tripjack-stay-times">
                    {checkInTime ? (
                      <div className="tripjack-stay-time">
                        <span className="tripjack-label">Check In</span>
                        <span className="tripjack-stay-time-value">{checkInTime}</span>
                      </div>
                    ) : null}
                    {checkOutTime ? (
                      <div className="tripjack-stay-time">
                        <span className="tripjack-label">Check Out</span>
                        <span className="tripjack-stay-time-value">{checkOutTime}</span>
                      </div>
                    ) : null}
                  </div>
                ) : null}
              </div>
            </section>


            <section className="tripjack-review-panel">
              {roomBreakdown.map((room, index) => (
                <div key={`summary-room-${index}`} className="tripjack-room-card">
                  <div className="tripjack-room-header">
                    <div>
                      <div className="tripjack-room-name">{room.title}</div>
                      <div className="tripjack-room-copy">
                        ({room.adults} Adult{room.adults === 1 ? "" : "s"}
                        {room.children ? `, ${room.children} Child${room.children === 1 ? "" : "ren"}` : ""})
                      </div>
                    </div>
                    {/* TripJack runs refundability and meal plan together on one line. */}
                    <div className="tripjack-room-terms">
                      {[
                        bookingRequirements?.isNonRefundable
                          ? "Non Refundable"
                          : bookingRequirements?.isRefundable
                            ? "Refundable"
                            : "Hotel policy",
                        room.mealBasis || roomSummary?.mealBasis || "",
                      ]
                        .filter(Boolean)
                        .join(" | ")}
                    </div>
                  </div>
                </div>
              ))}
            </section>

            <section className="tripjack-review-panel">
              <div className="tripjack-review-panel-inner">
                <div className="form-check">
                  <input
                    className="form-check-input"
                    type="checkbox"
                    id="tripjack-booking-terms"
                    checked={Boolean(bookingForm?.termsAccepted)}
                    onChange={(event) => onTermsChange(event.target.checked)}
                    disabled={bookingSubmitting}
                  />
                  <label className="form-check-label ps-2 tripjack-room-copy" htmlFor="tripjack-booking-terms">
                    I confirm that I have reviewed and agree to proceed with the selected room category and hotel booking terms.
                  </label>
                </div>
              </div>
            </section>

            <section className="tripjack-review-panel">
              <div className="tripjack-review-panel-inner">
                <h3 className="fw-bold mb-3">Cancellation Policy</h3>
                {cancellationRows.length > 0 ? (
                  <table className="tripjack-policy-table">
                    <thead>
                      <tr>
                        <th>Cancellation on or After</th>
                        <th>Cancellation on or Before</th>
                        <th>Cancellation Charges / Comments</th>
                      </tr>
                    </thead>
                    <tbody>
                      {cancellationRows.map((row, index) => (
                        <tr key={`cancellation-row-${index}`}>
                          <td>{formatPolicyDate(row.fromDate) || "Hotel policy"}</td>
                          <td>{formatPolicyDate(row.toDate) || "Hotel policy"}</td>
                          <td>
                            {row.amount !== null
                              ? formatFare(row.amount, row.currency || priceSummary?.currency || "INR")
                              : "As per hotel policy"}
                            {row.remarks ? ` • ${row.remarks}` : ""}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                ) : (
                  <ul className="tripjack-note-list">
                    <li>Detailed cancellation slabs are not available from TripJack for this room.</li>
                    {bookingRequirements?.deadlineDatetime ? <li>Hold deadline: {bookingRequirements.deadlineDatetime}</li> : null}
                  </ul>
                )}

                {/* TripJack prints these four notes under every cancellation table. The
                    service fee is the management fee, so it is derived rather than fixed. */}
                <ul className="tripjack-policy-footnotes">
                  {serviceFeePerNight > 0 ? (
                    <li>
                      {`A non-refundable service fee of ${formatFare(serviceFeePerNight, priceSummary?.currency || "INR")} per room per night is applicable to each booking.`}
                    </li>
                  ) : null}
                  <li>In case of a no-show, the full cancellation charge will apply unless otherwise specified.</li>
                  <li>Early check-outs will incur the full cancellation charge unless otherwise specified.</li>
                  <li>Please note that redeemed taxes and fees are non-refundable.</li>
                </ul>
              </div>
            </section>

            <section className="tripjack-review-panel">
              <div className="tripjack-review-panel-inner">
                <h3 className="fw-bold mb-1">Guest Details</h3>
                <div className="tripjack-room-copy mb-3">Only Lead Guest Name is Required</div>

                <div className="d-grid gap-3">
                  {roomTravellerInfo.map((room, roomIndex) => {
                    const travellers = Array.isArray(room?.travellerInfo) ? room.travellerInfo : [];
                    const adultCount = travellers.filter((t) => t?.pt === "ADULT").length;
                    const childCount = travellers.filter((t) => t?.pt === "CHILD").length;
                    // One block per guest in the selected occupancy. Only the lead
                    // name is mandatory; the rest are validated only once filled in.
                    const visible = travellers;

                    return (
                      <div key={`room-form-${roomIndex}`} className="tripjack-room-form">
                        <div className="tripjack-room-form-head">
                          <span>
                            Room {roomIndex + 1} : {roomBreakdown[roomIndex]?.title || reviewResponse?.displayRoomName || "Selected room"}
                          </span>
                          <span className="tripjack-meal-tag">
                            <UtensilsCrossed size={14} />
                            {roomBreakdown[roomIndex]?.mealBasis || roomSummary?.mealBasis || "Room Plan"}
                          </span>
                        </div>

                        <div className="tripjack-room-form-occupancy">
                          <span>{adultCount} Adult{adultCount === 1 ? "" : "s"}</span>
                          <span className="tripjack-occupancy-sep" />
                          <span>{childCount} {childCount === 1 ? "Child" : "Children"}</span>
                        </div>

                        <div className="tripjack-room-form-body">
                          {visible.map((traveller, travellerIndex) => {
                            const isAdult = traveller?.pt === "ADULT";
                            const allowedTitleOptions = isAdult ? adultTitleOptions : childTitleOptions;
                            const isLead = travellerIndex === 0;
                            return (
                              <div key={`traveller-${roomIndex}-${travellerIndex}`} className={travellerIndex > 0 ? "mt-4" : ""}>
                                <div className="tripjack-guest-caption">
                                  {`ROOM ${roomIndex + 1} · ${isAdult ? "GUEST" : "CHILD"} ${
                                    visible
                                      .slice(0, travellerIndex + 1)
                                      .filter((item) => (item?.pt === "ADULT") === isAdult).length
                                  }`}
                                </div>
                                <div className="row g-3">
                                  <div className="col-md-2">
                                    <label className="form-label fw-semibold">Title</label>
                                    <select
                                      className="form-select"
                                      value={traveller?.ti || ""}
                                      onChange={(event) => onTravellerFieldChange(roomIndex, travellerIndex, "ti", event.target.value)}
                                      disabled={bookingSubmitting}
                                    >
                                      {allowedTitleOptions.map((option) => (
                                        <option key={option} value={option}>{option}</option>
                                      ))}
                                    </select>
                                  </div>
                                  <div className="col-md-5">
                                    <label className="form-label fw-semibold">
                                      {isLead ? "Lead Pax First Name" : "First Name"}
                                    </label>
                                    <input
                                      className="form-control"
                                      placeholder={isLead ? "Lead Pax First Name" : "First Name"}
                                      value={traveller?.fN || ""}
                                      onChange={(event) => onTravellerFieldChange(roomIndex, travellerIndex, "fN", event.target.value)}
                                      disabled={bookingSubmitting}
                                    />
                                  </div>
                                  <div className="col-md-5">
                                    <label className="form-label fw-semibold">Last Name</label>
                                    <input
                                      className="form-control"
                                      placeholder="Last Name"
                                      value={traveller?.lN || ""}
                                      onChange={(event) => onTravellerFieldChange(roomIndex, travellerIndex, "lN", event.target.value)}
                                      disabled={bookingSubmitting}
                                    />
                                  </div>
                                  {bookingRequirements?.passportRequired && isAdult ? (
                                    <div className="col-md-6">
                                      <label className="form-label fw-semibold">Passport Number</label>
                                      <input
                                        className="form-control"
                                        placeholder="Passport Number"
                                        value={traveller?.pNum || ""}
                                        onChange={(event) => onTravellerFieldChange(roomIndex, travellerIndex, "pNum", event.target.value.toUpperCase())}
                                        disabled={bookingSubmitting}
                                      />
                                    </div>
                                  ) : null}
                                </div>
                              </div>
                            );
                          })}

                        </div>
                      </div>
                    );
                  })}
                </div>

                <h3 className="fw-bold mt-4 mb-3">Contact Details</h3>
                <div className="row g-3">
                  <div className="col-md-3">
                    <label className="form-label fw-semibold">Code</label>
                    <select
                      className="form-select"
                      value={bookingForm?.deliveryInfo?.code?.[0] || "91"}
                      onChange={(event) => onContactFieldChange("code", event.target.value)}
                      disabled={bookingSubmitting}
                    >
                      {countryCodeOptions.map((option) => (
                        <option key={option.code} value={option.code}>
                          {`${option.label} (+${option.code})`}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="col-md-4">
                    <label className="form-label fw-semibold">Mobile No.</label>
                    <input
                      className="form-control"
                      placeholder="Mobile No."
                      value={bookingForm?.deliveryInfo?.contacts?.[0] || ""}
                      onChange={(event) => onContactFieldChange("contacts", event.target.value)}
                      disabled={bookingSubmitting}
                    />
                  </div>
                  <div className="col-md-5">
                    <label className="form-label fw-semibold">Email ID</label>
                    <div className="tripjack-input-icon">
                      <input
                        className="form-control"
                        type="email"
                        placeholder="Email ID"
                        value={bookingForm?.deliveryInfo?.emails?.[0] || ""}
                        onChange={(event) => onContactFieldChange("emails", event.target.value)}
                        disabled={bookingSubmitting}
                      />
                      <Mail size={15} />
                    </div>
                  </div>
                </div>
              </div>
            </section>

            {/* PAN sits in its own panel on TripJack, one entry per room rather than
                one per adult. The value writes to that room's lead guest, which is the
                field the booking payload actually carries. */}
            {bookingRequirements?.panRequired ? (
              <section className="tripjack-review-panel">
                <div className="tripjack-review-panel-inner">
                  <h3 className="fw-bold mb-3">PAN Information</h3>

                  <div className="tripjack-pan-modes">
                    {["Personal PAN", "Corporate PAN"].map((mode) => (
                      <label key={mode} className="tripjack-pan-mode">
                        <input
                          type="radio"
                          name="tripjack-pan-mode"
                          checked={panMode === mode}
                          onChange={() => setPanMode(mode)}
                          disabled={bookingSubmitting}
                        />
                        <span>{mode}</span>
                      </label>
                    ))}
                  </div>

                  {roomTravellerInfo.map((room, roomIndex) => {
                    const travellers = Array.isArray(room?.travellerInfo) ? room.travellerInfo : [];
                    const leadIndex = travellers.findIndex((t) => t?.pt === "ADULT");
                    const index = leadIndex >= 0 ? leadIndex : 0;
                    const lead = travellers[index] || {};
                    const leadName = [lead?.fN, lead?.lN].filter(Boolean).join(" ");
                    return (
                      <div key={`pan-room-${roomIndex}`} className="row g-3 mt-1">
                        <div className="col-md-5">
                          <label className="form-label fw-semibold">
                            {panMode === "Corporate PAN" ? `Company Name (Room ${roomIndex + 1})` : `Name (Room ${roomIndex + 1})`}
                          </label>
                          <input
                            className="form-control"
                            placeholder="Name"
                            value={leadName}
                            readOnly
                            title="Taken from the lead guest for this room"
                          />
                        </div>
                        <div className="col-md-5">
                          <label className="form-label fw-semibold">PAN</label>
                          <input
                            className="form-control"
                            placeholder="ABCDE1234F"
                            value={lead?.pan || ""}
                            onChange={(event) => onTravellerFieldChange(roomIndex, index, "pan", event.target.value.toUpperCase())}
                            disabled={bookingSubmitting}
                          />
                        </div>
                      </div>
                    );
                  })}
                </div>
              </section>
            ) : null}

            <section className="tripjack-review-panel">
              <div className="tripjack-review-panel-inner">
                <h3 className="fw-bold mb-2">Important Information</h3>
                <div className="tripjack-room-copy mb-3">Booking Notes and General Term &amp; Conditions</div>
                <ul className="tripjack-note-list">
                  <li>{bookingRequirements?.isNonRefundable ? "This selected room is non-refundable." : bookingRequirements?.isRefundable ? "Cancellation charges apply according to the policy below." : "Cancellation is subject to hotel policy."}</li>
                  <li>{bookingRequirements?.panRequired ? "PAN is required for adult guests." : "PAN is not required for this room option."}</li>
                  <li>{bookingRequirements?.passportRequired ? "Passport number is required for adult guests." : "Passport number is not required for this room option."}</li>
                  {importantNotes.map((note, index) => <li key={`important-note-${index}`}>{note}</li>)}
                </ul>

                {policyNotes.length > 0 ? (
                  <div className="tripjack-policy-notes">
                    <div className="fw-semibold text-dark mb-2">Policies</div>
                    {policyNotes.map((note, index) => (
                      <div key={`policy-note-${index}`} className="tripjack-policy-note">
                        {note.label ? (
                          <span className="tripjack-policy-note-label">{toSentenceCase(note.label)}: </span>
                        ) : null}
                        <span>{note.text}</span>
                      </div>
                    ))}
                  </div>
                ) : null}
              </div>
            </section>


          </div>

          <aside className="tripjack-review-aside">
            <section className="tripjack-review-panel">
              <div className="tripjack-fare-card">
                <div className="tripjack-label">Fare Summary</div>

                <button
                  type="button"
                  className="tripjack-fare-row tripjack-fare-toggle"
                  onClick={() => setBaseFareOpen((open) => !open)}
                >
                  <span>
                    Base Fare
                    {baseFareOpen ? <ChevronUp size={13} /> : <ChevronDown size={13} />}
                  </span>
                  <strong>{formatFare(priceSummary?.baseFare, fareCurrency) || "Included"}</strong>
                </button>
                {baseFareOpen ? (
                  <div className="tripjack-fare-row tripjack-fare-subrow">
                    <span>{roomSummary?.roomName || "Room"}</span>
                    <span>{formatFare(priceSummary?.baseFare, fareCurrency)}</span>
                  </div>
                ) : null}

                <button
                  type="button"
                  className="tripjack-fare-row tripjack-fare-toggle"
                  onClick={() => setTaxesOpen((open) => !open)}
                >
                  <span>
                    Taxes and fees
                    {taxesOpen ? <ChevronUp size={13} /> : <ChevronDown size={13} />}
                  </span>
                  <strong>
                    {Number.isFinite(Number(priceSummary?.taxesAndFees))
                      ? formatFare(priceSummary.taxesAndFees, fareCurrency)
                      : "Included"}
                  </strong>
                </button>
                {taxesOpen ? (
                  <>
                    <div className="tripjack-fare-row tripjack-fare-subrow">
                      <span>Markup</span>
                      <span>{formatFare(fareMarkup, fareCurrency)}</span>
                    </div>
                    <div className="tripjack-fare-row tripjack-fare-subrow">
                      <span>Management Fees</span>
                      <span>{formatFare(priceSummary?.managementFee || 0, fareCurrency)}</span>
                    </div>
                    <div className="tripjack-fare-row tripjack-fare-subrow">
                      <span>Management Fees Tax</span>
                      <span>{formatFare(priceSummary?.managementFeeTax || 0, fareCurrency)}</span>
                    </div>
                  </>
                ) : null}

                <div className="tripjack-fare-row tripjack-fare-total">
                  <span className="fw-semibold text-dark">Total Amount Payable</span>
                  <strong>{formatFare(priceSummary?.amount, fareCurrency) || "Available after review"}</strong>
                </div>

                <div className="tripjack-pay-actions">
                  <Button variant="primary" onClick={onSubmit} disabled={bookingSubmitting}>
                    {bookingSubmitting ? "Submitting Booking..." : "Pay & Book / Instant Booking"}
                  </Button>
                  {holdBookingUatEnabled && reviewResponse?.onholdAllowed ? (
                    <Button variant="outline-primary" onClick={onHoldSubmit} disabled={bookingSubmitting}>
                      {bookingSubmitting ? "Submitting Booking..." : "Hold & Confirm"}
                    </Button>
                  ) : null}
                </div>
              </div>
            </section>

            <section className="tripjack-review-panel">
              <div className="tripjack-review-panel-inner">
                <div className="tripjack-label">Booking Snapshot</div>
                <div className="tripjack-fare-row">
                  <span>Booking ID</span>
                  <strong>{reviewResponse?.bookingId || "Pending"}</strong>
                </div>
                <div className="tripjack-fare-row">
                  <span>Room</span>
                  <strong>{reviewResponse?.displayRoomName || roomSummary?.roomName || "Selected room"}</strong>
                </div>
                <div className="tripjack-fare-row">
                  <span>Meal Basis</span>
                  <strong>{roomSummary?.mealBasis || "Room plan included"}</strong>
                </div>
                <div className="tripjack-fare-row">
                  <span>Refundability</span>
                  <strong>{bookingRequirements?.isNonRefundable ? "Non-refundable" : bookingRequirements?.isRefundable ? "Refundable" : "Hotel policy"}</strong>
                </div>
              </div>
            </section>
          </aside>
        </div>

      </div>
      </div>
    </>
  );
}
