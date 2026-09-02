import { Button } from "react-bootstrap";
import { formatDateWithWeekday } from "../../../../utils/dateFormat";

const adultTitleOptions = ["Mr", "Mrs", "Ms", "Miss"];
const childTitleOptions = ["Master", "Miss"];
const travellerTypeLabels = {
  ADULT: "Adult",
  CHILD: "Child",
};

const getPrimaryImage = (reviewResponse) => {
  const hotelSummary = reviewResponse?.hotelSummary || {};
  const hotelInfo = reviewResponse?.hotelInfo || {};
  const images = hotelSummary?.images || hotelInfo?.images || hotelInfo?.img || [];
  const firstImage = Array.isArray(images) ? images[0] : null;
  return firstImage?.url || firstImage?.imageUrl || firstImage?.path || firstImage || "";
};

const formatStayDate = (value) => {
  if (!value) return "";
  return formatDateWithWeekday(value, { fallback: String(value) });
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
    line: [
      address?.adr,
      address?.sn,
      address?.ctn,
      address?.city?.name,
      address?.state?.name,
      address?.cn,
    ]
      .filter(Boolean)
      .join(", "),
    postalCode: address?.pc || address?.postalCode || "",
  };
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
  formatMoney,
  holdBookingUatEnabled = false,
}) {
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
        .tripjack-review-title {
          color: #1b2231;
          font-size: 36px;
          line-height: 1.05;
          font-weight: 900;
          margin: 0;
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
          border: none;
          background: transparent;
          color: #c31767;
          font-weight: 800;
          font-size: 13px;
          text-decoration: underline;
          text-underline-offset: 3px;
          padding: 0;
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
          grid-template-columns: repeat(5, minmax(0, 1fr));
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
          align-items: start;
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
          <div>
            <h1 className="tripjack-review-title">Review Your Booking</h1>
            <div className="tripjack-review-subtitle">
              Confirm your stay details, guest information, and fare summary before proceeding with this hotel booking.
            </div>
          </div>
          <button type="button" className="tripjack-review-back" onClick={onClose} disabled={bookingSubmitting}>
            Back to hotel details
          </button>
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

                  <div>
                    <div className="fs-3 fw-bold text-dark">{hotelName}</div>
                    {displayRating ? <div className="tripjack-hotel-stars">{renderStars(displayRating)}</div> : null}
                    {addressLine ? <div className="tripjack-hotel-address">{addressLine}</div> : null}
                    {postalCode ? <div className="tripjack-hotel-address">Postal Code: {postalCode}</div> : null}
                  </div>
                </div>
              </div>
            </section>

            <section className="tripjack-review-panel">
              <div className="tripjack-review-panel-inner">
                <div className="tripjack-stay-grid">
                  <div className="tripjack-stay-cell">
                    <div className="tripjack-label">Check In</div>
                    <div className="tripjack-value">{formatStayDate(checkInDate) || "Available after search"}</div>
                  </div>
                  <div className="tripjack-stay-cell">
                    <div className="tripjack-label">Stay</div>
                    <div className="tripjack-value">{nights > 0 ? `${nights} Night${nights > 1 ? "s" : ""}` : "Night count available"}</div>
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
              </div>
            </section>


            <section className="tripjack-review-panel">
              {roomBreakdown.map((room, index) => (
                <div key={`summary-room-${index}`} className="tripjack-room-card">
                  <div className="tripjack-room-header">
                    <div>
                      <div className="fw-bold fs-5 text-dark">{room.title}</div>
                      <div className="tripjack-room-copy">
                        {room.adults} Adult{room.adults === 1 ? "" : "s"}
                        {room.children ? ` | ${room.children} Child${room.children === 1 ? "" : "ren"}` : ""}
                      </div>
                    </div>
                    <div className="text-md-end">
                      <div className="fw-semibold text-dark">
                        {bookingRequirements?.isNonRefundable
                          ? "Non Refundable"
                          : bookingRequirements?.isRefundable
                            ? "Refundable"
                            : "Hotel policy"}
                      </div>
                      <div className="tripjack-room-copy">{room.mealBasis || roomSummary?.mealBasis || "Room plan available"}</div>
                    </div>
                  </div>
                </div>
              ))}
            </section>

            <section className="tripjack-review-panel">
              <div className="tripjack-review-panel-inner">
                <h3 className="fw-bold mb-1">Guest Details</h3>
                <div className="tripjack-room-copy mb-3">Only lead guest information is required for this booking.</div>

                <div className="d-grid gap-3">
                  {roomTravellerInfo.map((room, roomIndex) => (
                    <div key={`room-form-${roomIndex}`} className="tripjack-form-card">
                      <div className="d-flex justify-content-between gap-3 flex-wrap align-items-center mb-3">
                        <div className="fw-bold text-dark">Room {roomIndex + 1}: {roomBreakdown[roomIndex]?.title || reviewResponse?.displayRoomName || "Selected room"}</div>
                        <span className="tripjack-guest-badge">{roomBreakdown[roomIndex]?.mealBasis || roomSummary?.mealBasis || "Room Plan"}</span>
                      </div>

                      {(Array.isArray(room?.travellerInfo) ? room.travellerInfo : []).map((traveller, travellerIndex) => {
                        const isAdult = traveller?.pt === "ADULT";
                        const allowedTitleOptions = isAdult ? adultTitleOptions : childTitleOptions;
                        return (
                          <div key={`traveller-${roomIndex}-${travellerIndex}`} className={travellerIndex > 0 ? "mt-4" : ""}>
                            <div className="tripjack-room-copy fw-semibold mb-2">
                              {travellerTypeLabels[traveller?.pt] || "Traveller"} {travellerIndex + 1}
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
                                <label className="form-label fw-semibold">First Name</label>
                                <input
                                  className="form-control"
                                  placeholder="First Name"
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
                              {isAdult ? (
                                <div className="col-md-6">
                                  <label className="form-label fw-semibold">
                                    {bookingRequirements?.panRequired ? "PAN Number *" : "PAN Number (if available)"}
                                  </label>
                                  <input
                                    className="form-control"
                                    placeholder="ABCDE1234F"
                                    value={traveller?.pan || ""}
                                    onChange={(event) => onTravellerFieldChange(roomIndex, travellerIndex, "pan", event.target.value.toUpperCase())}
                                    disabled={bookingSubmitting}
                                  />
                                </div>
                              ) : null}
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
                  ))}
                </div>
              </div>
            </section>

            <section className="tripjack-review-panel">
              <div className="tripjack-review-panel-inner">
                <h3 className="fw-bold mb-3">Contact Details</h3>
                <div className="row g-3">
                  <div className="col-md-3">
                    <label className="form-label fw-semibold">Code</label>
                    <input
                      className="form-control"
                      value={bookingForm?.deliveryInfo?.code?.[0] || ""}
                      onChange={(event) => onContactFieldChange("code", event.target.value)}
                      disabled={bookingSubmitting}
                    />
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
                    <input
                      className="form-control"
                      type="email"
                      placeholder="Email ID"
                      value={bookingForm?.deliveryInfo?.emails?.[0] || ""}
                      onChange={(event) => onContactFieldChange("emails", event.target.value)}
                      disabled={bookingSubmitting}
                    />
                  </div>
                </div>
              </div>
            </section>

            <section className="tripjack-review-panel">
              <div className="tripjack-review-panel-inner">
                <h3 className="fw-bold mb-2">Important Information</h3>
                <div className="tripjack-room-copy mb-3">Booking notes and general terms shown by TripJack.</div>
                <ul className="tripjack-note-list">
                  <li>{bookingRequirements?.isNonRefundable ? "This selected room is non-refundable." : bookingRequirements?.isRefundable ? "Cancellation charges apply according to the policy below." : "Cancellation is subject to hotel policy."}</li>
                  <li>{bookingRequirements?.panRequired ? "PAN is required for adult guests." : "PAN is not required for this room option."}</li>
                  <li>{bookingRequirements?.passportRequired ? "Passport number is required for adult guests." : "Passport number is not required for this room option."}</li>
                  {importantNotes.map((note, index) => <li key={`important-note-${index}`}>{note}</li>)}
                </ul>
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
                          <td>{formatStayDate(row.fromDate) || row.fromDate || "Hotel policy"}</td>
                          <td>{formatStayDate(row.toDate) || row.toDate || "Hotel policy"}</td>
                          <td>
                            {row.amount !== null
                              ? `${row.currency || priceSummary?.currency || "INR"} ${Number(row.amount).toFixed(2)}`
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
              </div>
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
          </div>

          <aside className="tripjack-review-aside">
            <section className="tripjack-review-panel">
              <div className="tripjack-fare-card">
                <div className="tripjack-label">Fare Summary</div>
                <div className="tripjack-fare-row">
                  <span>Base Fare</span>
                  <strong>{priceSummary?.baseFare ? formatMoney(priceSummary.baseFare, priceSummary.currency || "INR") : "Included"}</strong>
                </div>
                <div className="tripjack-fare-row">
                  <span>Taxes and Fees</span>
                  <strong>{priceSummary?.taxesAndFees ? formatMoney(priceSummary.taxesAndFees, priceSummary.currency || "INR") : "Included"}</strong>
                </div>
                <div className="tripjack-fare-row">
                  <span className="fw-semibold text-dark">Total Amount Payable</span>
                  <strong>{priceSummary?.amount ? formatMoney(priceSummary.amount, priceSummary.currency || "INR") : "Available after review"}</strong>
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

        <div className="tripjack-action-bar">
          <Button variant="outline-secondary" onClick={onClose} disabled={bookingSubmitting}>
            Back to Hotel Details
          </Button>
          {holdBookingUatEnabled && reviewResponse?.onholdAllowed ? (
            <Button
              variant="outline-primary"
              onClick={onHoldSubmit}
              disabled={bookingSubmitting}
            >
              {bookingSubmitting ? "Submitting Booking..." : "Hold & Confirm"}
            </Button>
          ) : null}
          <Button variant="primary" onClick={onSubmit} disabled={bookingSubmitting}>
            {bookingSubmitting ? "Submitting Booking..." : "Pay & Book / Instant Booking"}
          </Button>
        </div>
      </div>
      </div>
    </>
  );
}
