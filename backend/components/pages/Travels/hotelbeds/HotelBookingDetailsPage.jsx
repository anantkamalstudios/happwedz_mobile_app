import { useEffect, useMemo, useState } from "react";
import { Container } from "react-bootstrap";
import { Link, useLocation, useNavigate, useParams } from "react-router-dom";
import {
  cancelHotelBooking,
  createHotelPaymentOrder,
  confirmHotelBooking,
  downloadHotelReceipt,
  downloadHotelVoucher,
  getHotelBookingDetails,
} from "../../../../services/api/hotelApi";

function formatAmount(amount, currency = "INR") {
  const value = Number(amount || 0);
  if (!Number.isFinite(value) || value <= 0) return "Not available";
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency,
    maximumFractionDigits: 2,
  }).format(value);
}

function formatDate(value) {
  if (!value) return "Not available";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);
  return date.toLocaleDateString("en-IN", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
}

function formatDateTime(value) {
  if (!value) return "Not available";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);
  return date.toLocaleString("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
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

function getNumNights(checkIn, checkOut) {
  if (!checkIn || !checkOut) return null;
  const start = new Date(checkIn);
  const end = new Date(checkOut);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return null;
  const diff = Math.ceil((end - start) / (1000 * 60 * 60 * 24));
  return diff > 0 ? diff : null;
}

function isPaymentPendingBooking(status) {
  const normalized = String(status || "").toUpperCase();
  return ["PAYMENT_PENDING", "PENDING", "IN_PROGRESS"].includes(normalized);
}

function getBookingStatusLabel(status, userStatus) {
  const normalizedStatus = String(userStatus || status || "").trim();
  if (typeof userStatus === "string" && userStatus.trim().length > 0) {
    return userStatus;
  }
  const normalized = String(status || "").toUpperCase();
  if (normalized === "PAYMENT_PENDING") return "Payment Pending";
  if (normalized === "PAYMENT_SUCCESS") return "Payment Success - Pending Voucher";
  if (normalized === "ON_HOLD") return "On Hold";
  if (["IN_PROGRESS", "PENDING"].includes(normalized)) return "Booking Processing";
  if (normalized === "CANCELLED") return "Cancelled";
  return normalizedStatus || normalized || "-";
}

function getStatusTone(orderStatus) {
  const normalized = String(orderStatus || "").toUpperCase();
  if (["CANCELLATION_REQUESTED", "CANCELLATION_PENDING"].includes(normalized)) {
    return {
      title: "Cancellation Pending",
      subtitle: "Your cancellation request is being processed by TripJack. Please check back for the final cancellation status.",
      color: "#92400e",
      bg: "#fff7ed",
      border: "#fed7aa",
    };
  }
  if (normalized === "CANCELLED") {
    return {
      title: "Booking Cancelled",
      subtitle: "This booking has been cancelled.",
      color: "#7f1d1d",
      bg: "#fef2f2",
      border: "#fecaca",
    };
  }
  if (["SUCCESS", "CONFIRMED", "VOUCHERED"].includes(normalized)) {
    return {
      title: "Booking Payment Success",
      subtitle: "Your booking is confirmed and payment is captured.",
      color: "#2f8a1f",
      bg: "#edf8ea",
      border: "#cbeac4",
    };
  }
  if (normalized === "PAYMENT_SUCCESS") {
    return {
      title: "Payment Success - Pending Voucher",
      subtitle: "Payment is successful. Hotel confirmation is still in progress.",
      color: "#b26a00",
      bg: "#fff7e6",
      border: "#f7deb0",
    };
  }
  if (normalized === "ON_HOLD") {
    return {
      title: "Booking On Hold",
      subtitle: "This room is held in TripJack and must be confirmed before the deadline.",
      color: "#1d4ed8",
      bg: "#eff6ff",
      border: "#bfdbfe",
    };
  }
  return {
    title: "Booking Status Update",
    subtitle: "Booking status is being processed. Please refresh after some time.",
    color: "#475569",
    bg: "#f8fafc",
    border: "#e2e8f0",
  };
}

export default function HotelBookingDetailsPage() {
  const { bookingId } = useParams();
  const location = useLocation();
  const navigate = useNavigate();
  const fallbackBooking = location.state?.booking || null;
  const [loading, setLoading] = useState(true);
  const [details, setDetails] = useState(null);
  const [error, setError] = useState("");
  const [cancelLoading, setCancelLoading] = useState(false);
  const [cancelMessage, setCancelMessage] = useState("");
  const [cancellationRequested, setCancellationRequested] = useState(false);
  const [confirmHoldLoading, setConfirmHoldLoading] = useState(false);
  const [documentLoading, setDocumentLoading] = useState("");

  const loadDetails = async () => {
    if (!bookingId) {
      setError("Booking ID is missing.");
      setLoading(false);
      return;
    }

    setLoading(true);
    setError("");
    try {
      const response = await getHotelBookingDetails({ bookingId });
      setDetails(response || null);
    } catch (err) {
      setDetails(null);
      const backendMessage = err?.response?.data?.error;
      if (
        fallbackBooking &&
        isPaymentPendingBooking(fallbackBooking.status) &&
        err?.response?.status === 400 &&
        typeof backendMessage === "string" &&
        backendMessage.toLowerCase().includes("no order found")
      ) {
        setError("Payment is pending. Booking details will be available after payment completion.");
      } else {
        setError(
          backendMessage || err?.message || "Unable to fetch booking details right now.",
        );
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let active = true;
    (async () => {
      if (!active) return;
      await loadDetails();
    })();

    return () => {
      active = false;
    };
  }, [bookingId]);

  const showPendingStatusNotice = !loading && !error && fallbackBooking && isPaymentPendingBooking(fallbackBooking.status) && !details;
  const showPendingBookingSummary = showPendingStatusNotice;

  const ui = useMemo(() => {
    const display = details?.bookingDisplay || {};
    const order = details?.raw?.order || {};
    const hotelInfo = details?.raw?.itemInfos?.HOTEL?.hInfo || {};
    const option = Array.isArray(hotelInfo?.ops) && hotelInfo.ops.length ? hotelInfo.ops[0] : {};
    const room = Array.isArray(option?.ris) && option.ris.length ? option.ris[0] : {};
    const traveller = Array.isArray(room?.ti) && room.ti.length ? room.ti[0] : {};
    const fare = room?.tfcs || option?.tfcs || {};

    const hotelName = display.hotelName || hotelInfo?.name || fallbackBooking?.hotelName || "Booked Hotel";
    const address =
      display.hotelAddress ||
      hotelInfo?.ad?.adr ||
      hotelInfo?.ad?.line1 ||
      hotelInfo?.ad?.city?.name ||
      hotelInfo?.ad?.name ||
      "Not available";

    const normalizedStatus = String(
      details?.bookingStatusMeta?.normalizedStatus ||
        details?.orderStatus ||
        order?.status ||
        fallbackBooking?.status ||
        "",
    ).toUpperCase();
    const tone = getStatusTone(normalizedStatus);
    const humanStatusText = String(details?.userStatus || "").toUpperCase();
    const isCancellationFlow = [
      "CANCELLATION_REQUESTED",
      "CANCELLATION_PENDING",
      "CANCELLED",
    ].includes(normalizedStatus);
    const isCancellationText =
      humanStatusText.includes("CANCEL") ||
      humanStatusText.includes("CANCELLATION");
    const canCancel =
      !isCancellationFlow &&
      !isCancellationText &&
      !cancellationRequested &&
      ["SUCCESS", "CONFIRMED", "VOUCHERED", "ON_HOLD", "PAYMENT_SUCCESS"].includes(normalizedStatus);
    const bookingType = String(details?.bookingType || fallbackBooking?.bookingType || "").toUpperCase();
    const paymentStatus = String(details?.paymentStatus || fallbackBooking?.paymentStatus || "").toUpperCase();
    const canConfirmHold =
      bookingType === "HOLD" &&
      paymentStatus !== "PAID" &&
      ["ON_HOLD", "IN_PROGRESS", "PENDING", "PAYMENT_PENDING"].includes(normalizedStatus);
    const canDownloadReceipt =
      paymentStatus === "PAID" &&
      ["SUCCESS", "CONFIRMED", "VOUCHERED"].includes(normalizedStatus);
    const canDownloadVoucher =
      ["SUCCESS", "CONFIRMED", "VOUCHERED"].includes(normalizedStatus);
    const statusLabel = isCancellationFlow
      ? normalizedStatus === "CANCELLED"
        ? "Booking Cancelled"
        : "Cancellation Pending"
      : getBookingStatusLabel(normalizedStatus, details?.userStatus);

    return {
      tone,
      hotelName,
      address,
      bookingId: details?.bookingId || bookingId,
      checkIn: display.checkIn || room?.checkInDate || details?.raw?.itemInfos?.HOTEL?.query?.checkinDate || fallbackBooking?.checkIn,
      checkOut: display.checkOut || room?.checkOutDate || details?.raw?.itemInfos?.HOTEL?.query?.checkoutDate || fallbackBooking?.checkOut,
      roomName: display.roomName || room?.rc || room?.rt || "Not available",
      totalRooms: Array.isArray(option?.ris) ? option.ris.length : 1,
      adults: room?.adt ?? 1,
      children: room?.chd ?? 0,
      totalStay: room?.numNights
        ? `${room.numNights} Night(s)`
        : getNumNights(
            room?.checkInDate || details?.raw?.itemInfos?.HOTEL?.query?.checkinDate || fallbackBooking?.checkIn,
            room?.checkOutDate || details?.raw?.itemInfos?.HOTEL?.query?.checkoutDate || fallbackBooking?.checkOut,
          )
        ? `${getNumNights(
            room?.checkInDate || details?.raw?.itemInfos?.HOTEL?.query?.checkinDate || fallbackBooking?.checkIn,
            room?.checkOutDate || details?.raw?.itemInfos?.HOTEL?.query?.checkoutDate || fallbackBooking?.checkOut,
          )} Night(s)`
        : "Not available",
      guestName: display.guestName || [traveller?.fN, traveller?.lN].filter(Boolean).join(" ") || "Not available",
      email: display.email || details?.deliveryInfo?.emails?.[0] || order?.deliveryInfo?.emails?.[0] || "Not available",
      phone: display.phone || details?.deliveryInfo?.contacts?.[0] || order?.deliveryInfo?.contacts?.[0] || "Not available",
      createdOn: display.createdOn || details?.createdOn || order?.createdOn || fallbackBooking?.createdAt,
      deadlineDatetime:
        display.deadlineDatetime ||
        details?.deadlineDatetime ||
        fallbackBooking?.deadlineDatetime ||
        details?.raw?.itemInfos?.HOTEL?.hInfo?.ops?.[0]?.ddt ||
        null,
      baseFare: display.baseFare ?? fare?.BF,
      taxesAndFees: display.taxes ?? fare?.TAF,
      mf: display.mf,
      mft: display.mft,
      totalAmount: display.totalAmount ?? details?.amount ?? order?.amount ?? option?.tp ?? fallbackBooking?.amount ?? 0,
      currency: display.currency || fallbackBooking?.currency || option?.sc || "INR",
      cancellationPolicies: Array.isArray(display.cancellationPolicies) && display.cancellationPolicies.length > 0 ? display.cancellationPolicies : Array.isArray(option?.cnp?.pd) ? option.cnp.pd : [],
      statusLabel,
      canCancel,
      canConfirmHold,
      canDownloadReceipt,
      canDownloadVoucher,
      normalizedStatus,
      isCancellationFlow,
      isOnHold: ["ON_HOLD", "IN_PROGRESS"].includes(normalizedStatus),
    };
  }, [details, bookingId, fallbackBooking, cancellationRequested]);

  const handleDownloadReceipt = async () => {
    if (!bookingId || documentLoading) return;
    setDocumentLoading("receipt");
    setCancelMessage("");
    try {
      await downloadHotelReceipt(bookingId);
    } catch (err) {
      setCancelMessage(
        err?.response?.data?.error ||
          err?.message ||
          "Unable to download booking receipt right now.",
      );
    } finally {
      setDocumentLoading("");
    }
  };

  const handleDownloadVoucher = async () => {
    if (!bookingId || documentLoading) return;
    setDocumentLoading("voucher");
    setCancelMessage("");
    try {
      await downloadHotelVoucher(bookingId);
    } catch (err) {
      setCancelMessage(
        err?.response?.data?.error ||
          err?.message ||
          "Unable to download booking voucher right now.",
      );
    } finally {
      setDocumentLoading("");
    }
  };

  const handleConfirmHoldBooking = async () => {
    if (!bookingId || confirmHoldLoading) return;
    const ok = window.confirm("Confirm this hold booking now?");
    if (!ok) return;

    setConfirmHoldLoading(true);
    setCancelMessage("");
    try {
      const amount = Number(ui.totalAmount || 0);
      const paymentInfos = amount > 0 ? [{ amount }] : [];
// NOTE: backend requires roomTravellerInfo + deliveryInfo for payment order creation.
      // For the Hold->Pay flow, we can send whatever UI-derived values exist.
      // If TripJack returns these fields missing, backend will fall back to saved booking values.
      const payload = {
        bookingId,
        paymentInfos,
        roomTravellerInfo: details?.travellerInfo || details?.roomTravellerInfo || [],
        deliveryInfo: details?.deliveryInfo || {},
      };
      const orderResponse = await createHotelPaymentOrder(payload);
      const razorpayLoaded = await loadRazorpayScript();
      if (!razorpayLoaded || !window.Razorpay) {
        throw new Error("Unable to load Razorpay checkout");
      }

      const response = await new Promise((resolve, reject) => {
        const razorpayInstance = new window.Razorpay({
          key: orderResponse?.keyId,
          order_id: orderResponse?.razorpayOrderId,
          amount: orderResponse?.amount,
          currency: orderResponse?.currency || "INR",
          name: "HappyWedz Hotels",
          description: orderResponse?.hotelName || "TripJack hold booking confirmation",
          prefill: {
            email: ui.email !== "Not available" ? ui.email : "",
            contact: ui.phone !== "Not available" ? ui.phone : "",
          },
          theme: {
            color: "#ed1173",
          },
          modal: {
            ondismiss: () => reject(new Error("Razorpay checkout closed before payment.")),
          },
          handler: async (paymentResult) => {
            try {
              const confirmResponse = await confirmHotelBooking({
                bookingId,
                paymentInfos,
                razorpay_order_id: paymentResult?.razorpay_order_id || orderResponse?.razorpayOrderId,
                razorpay_payment_id: paymentResult?.razorpay_payment_id,
                razorpay_signature: paymentResult?.razorpay_signature,
              });
              resolve(confirmResponse);
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

      setCancelMessage(response?.message || "Hold booking confirmed. Awaiting final status.");
      await loadDetails();
    } catch (err) {
      setCancelMessage(
        err?.response?.data?.error ||
          err?.message ||
          "Unable to confirm hold booking right now.",
      );
    } finally {
      setConfirmHoldLoading(false);
    }
  };

  const handleCancelBooking = async () => {
    if (!bookingId || cancelLoading) return;
    const ok = window.confirm(
      "Are you sure you want to cancel this booking? Cancellation charges may apply.",
    );
    if (!ok) return;

    setCancelLoading(true);
    setCancelMessage("");
    try {
      const response = await cancelHotelBooking(bookingId);
      setCancelMessage(response?.message || "Cancellation request submitted.");
      setCancellationRequested(true);
      await loadDetails();
    } catch (err) {
      setCancelMessage(
        err?.response?.data?.error ||
          err?.message ||
          "Unable to submit cancellation request right now.",
      );
    } finally {
      setCancelLoading(false);
    }
  };

  return (
    <section
      style={{
        minHeight: "100vh",
        background: "linear-gradient(180deg, #f6ebe1 0%, #fbf7f2 35%, #ffffff 100%)",
        padding: "110px 0 64px",
      }}
    >
      <Container>
        <div className="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
          <div className="d-flex align-items-center flex-wrap gap-2">
            <button
              type="button"
              onClick={() => navigate(-1)}
              style={{
                border: "1px solid #cbd5e1",
                background: "#fff",
                color: "#132238",
                borderRadius: "999px",
                padding: "0.5rem 1rem",
                fontWeight: 600,
              }}
            >
              Back
            </button>
            {ui?.canDownloadReceipt ? (
              <button
                type="button"
                onClick={handleDownloadReceipt}
                disabled={Boolean(documentLoading)}
                style={{
                  border: "1px solid #132238",
                  background: "#fff",
                  color: "#132238",
                  borderRadius: "999px",
                  padding: "0.5rem 1rem",
                  fontWeight: 600,
                }}
              >
                {documentLoading === "receipt" ? "Preparing Receipt..." : "Download Receipt"}
              </button>
            ) : null}
            {ui?.canDownloadVoucher ? (
              <button
                type="button"
                onClick={handleDownloadVoucher}
                disabled={Boolean(documentLoading)}
                style={{
                  border: "1px solid #132238",
                  background: "#fff",
                  color: "#132238",
                  borderRadius: "999px",
                  padding: "0.5rem 1rem",
                  fontWeight: 600,
                }}
              >
                {documentLoading === "voucher" ? "Preparing Voucher..." : "Download Voucher"}
              </button>
            ) : null}
          </div>
          <Link
            to="/hotels/all-booking"
            style={{
              border: "1px solid #132238",
              background: "#132238",
              color: "#fff",
              borderRadius: "999px",
              padding: "0.5rem 1rem",
              textDecoration: "none",
              fontWeight: 600,
            }}
          >
            All Bookings
          </Link>
        </div>
        {cancelMessage ? (
          <div
            style={{
              border: "1px solid #cbd5e1",
              background: "#fff",
              color: "#334155",
              borderRadius: "12px",
              padding: "0.65rem 0.85rem",
              marginBottom: "0.75rem",
            }}
          >
            {cancelMessage}
          </div>
        ) : null}

        {loading ? (
          <div style={{ color: "#334155", fontWeight: 600 }}>Loading booking details...</div>
        ) : (
          <div className="row g-3">
            <div className="col-12 col-lg-8">
              <div
                style={{
                  background: "#fff",
                  borderRadius: "18px",
                  border: `1px solid ${ui.tone.border}`,
                  overflow: "hidden",
                }}
              >
                <div
                  style={{
                    background: ui.tone.bg,
                    borderBottom: `1px solid ${ui.tone.border}`,
                    padding: "1rem 1.25rem",
                  }}
                >
                  <div style={{ color: ui.tone.color, fontSize: "1.6rem", fontWeight: 800 }}>
                    {ui.tone.title}
                  </div>
                  <div style={{ marginTop: "0.2rem", color: "#475569", fontWeight: 600 }}>
                    Booking ID: {ui.bookingId}
                  </div>
                  <div style={{ marginTop: "0.2rem", color: "#64748b" }}>{ui.tone.subtitle}</div>
                </div>

                <div style={{ padding: "1.1rem 1.25rem" }}>
                  {error ? (
                    <div
                      style={{
                        borderRadius: "12px",
                        border: "1px solid #fecaca",
                        background: "#fef2f2",
                        color: "#b91c1c",
                        padding: "0.75rem 0.9rem",
                      }}
                    >
                      {error}
                    </div>
                  ) : null}

                  {showPendingStatusNotice ? (
                    <div
                      style={{
                        borderRadius: "12px",
                        border: "1px solid #c7d2fe",
                        background: "#eef2ff",
                        color: "#1e3a8a",
                        padding: "0.75rem 0.9rem",
                        marginTop: error ? "1rem" : 0,
                      }}
                    >
                      Payment is pending for this booking. Full TripJack booking details will be visible after payment completion.
                    </div>
                  ) : null}

                  {showPendingBookingSummary ? (
                    <div style={{ marginTop: error || showPendingStatusNotice ? "1rem" : 0 }}>
                      <div style={{ fontWeight: 700, fontSize: "1.2rem", color: "#132238" }}>{ui.hotelName}</div>
                      <div style={{ color: "#64748b", marginTop: "0.25rem" }}>{ui.address}</div>

                      <div className="row g-2 mt-2">
                        <div className="col-6 col-md-3">
                          <div style={{ background: "#eff6ff", borderRadius: "10px", padding: "0.7rem" }}>
                            <div style={{ color: "#64748b", fontSize: "0.82rem" }}>Check in</div>
                            <div style={{ fontWeight: 700 }}>{formatDate(ui.checkIn)}</div>
                          </div>
                        </div>
                        <div className="col-6 col-md-3">
                          <div style={{ background: "#eff6ff", borderRadius: "10px", padding: "0.7rem" }}>
                            <div style={{ color: "#64748b", fontSize: "0.82rem" }}>Check out</div>
                            <div style={{ fontWeight: 700 }}>{formatDate(ui.checkOut)}</div>
                          </div>
                        </div>
                        <div className="col-6 col-md-3">
                          <div style={{ background: "#eff6ff", borderRadius: "10px", padding: "0.7rem" }}>
                            <div style={{ color: "#64748b", fontSize: "0.82rem" }}>Total Rooms</div>
                            <div style={{ fontWeight: 700 }}>{ui.totalRooms}</div>
                          </div>
                        </div>
                        <div className="col-6 col-md-3">
                          <div style={{ background: "#eff6ff", borderRadius: "10px", padding: "0.7rem" }}>
                            <div style={{ color: "#64748b", fontSize: "0.82rem" }}>Guests</div>
                            <div style={{ fontWeight: 700 }}>
                              {ui.adults} Adult{ui.adults > 1 ? "s" : ""}{ui.children ? `, ${ui.children} Child` : ""}
                            </div>
                          </div>
                        </div>
                      </div>

                      <div style={{ marginTop: "1rem", borderTop: "1px solid #e2e8f0", paddingTop: "1rem" }}>
                        <div style={{ fontWeight: 700, color: "#132238", marginBottom: "0.35rem" }}>Status</div>
                        <div style={{ color: "#334155", fontWeight: 700 }}>{ui.statusLabel}</div>
                        <div style={{ color: "#64748b", marginTop: "0.35rem" }}>
                          Created On: {formatDateTime(ui.createdOn)}
                        </div>
                      </div>
                    </div>
                  ) : (
                    <>
                      <div style={{ marginTop: error || showPendingStatusNotice ? "1rem" : 0 }}>
                        <div style={{ fontWeight: 700, fontSize: "1.2rem", color: "#132238" }}>{ui.hotelName}</div>
                        <div style={{ color: "#64748b", marginTop: "0.25rem" }}>{ui.address}</div>
                      </div>

                      <div className="row g-2 mt-2">
                        <div className="col-6 col-md-3">
                          <div style={{ background: "#eff6ff", borderRadius: "10px", padding: "0.7rem" }}>
                            <div style={{ color: "#64748b", fontSize: "0.82rem" }}>Check in</div>
                            <div style={{ fontWeight: 700 }}>{formatDate(ui.checkIn)}</div>
                          </div>
                        </div>
                        <div className="col-6 col-md-3">
                          <div style={{ background: "#eff6ff", borderRadius: "10px", padding: "0.7rem" }}>
                            <div style={{ color: "#64748b", fontSize: "0.82rem" }}>Check out</div>
                            <div style={{ fontWeight: 700 }}>{formatDate(ui.checkOut)}</div>
                          </div>
                        </div>
                        <div className="col-6 col-md-3">
                          <div style={{ background: "#eff6ff", borderRadius: "10px", padding: "0.7rem" }}>
                            <div style={{ color: "#64748b", fontSize: "0.82rem" }}>Total Rooms</div>
                            <div style={{ fontWeight: 700 }}>{ui.totalRooms}</div>
                          </div>
                        </div>
                        <div className="col-6 col-md-3">
                          <div style={{ background: "#eff6ff", borderRadius: "10px", padding: "0.7rem" }}>
                            <div style={{ color: "#64748b", fontSize: "0.82rem" }}>Guests</div>
                            <div style={{ fontWeight: 700 }}>
                              {ui.adults} Adult{ui.adults > 1 ? "s" : ""}{ui.children ? `, ${ui.children} Child` : ""}
                            </div>
                          </div>
                        </div>
                      </div>

                      <div style={{ marginTop: "1rem", borderTop: "1px solid #e2e8f0", paddingTop: "1rem" }}>
                        <div style={{ fontWeight: 700, color: "#132238", marginBottom: "0.35rem" }}>Room Details</div>
                        <div style={{ color: "#334155" }}>{ui.roomName}</div>
                        <div style={{ color: "#64748b" }}>Guest: {ui.guestName}</div>
                        <div style={{ color: "#64748b" }}>Total Stay: {ui.totalStay}</div>
                        <div style={{ color: "#64748b", marginTop: "0.35rem" }}>Status: {ui.statusLabel}</div>
                      </div>

                      <div style={{ marginTop: "1rem", borderTop: "1px solid #e2e8f0", paddingTop: "1rem" }}>
                        <div style={{ fontWeight: 700, color: "#132238", marginBottom: "0.35rem" }}>Contact Details</div>
                        <div style={{ color: "#334155" }}>Email: {ui.email}</div>
                        <div style={{ color: "#334155" }}>Phone: {ui.phone}</div>
                        <div style={{ color: "#64748b", marginTop: "0.35rem" }}>Created On: {formatDateTime(ui.createdOn)}</div>
                        {ui.isOnHold && ui.deadlineDatetime ? (
                          <div style={{ color: "#1d4ed8", marginTop: "0.35rem", fontWeight: 700 }}>
                            Hold Deadline: {formatDateTime(ui.deadlineDatetime)}
                          </div>
                        ) : null}
                        {ui.canConfirmHold ? (
                          <div className="mt-3">
                            <button
                              type="button"
                              onClick={handleConfirmHoldBooking}
                              disabled={confirmHoldLoading}
                              style={{
                                border: "1px solid #0f766e",
                                background: "#fff",
                                color: "#0f766e",
                                borderRadius: "999px",
                                padding: "0.45rem 0.95rem",
                                fontWeight: 700,
                                cursor: confirmHoldLoading ? "not-allowed" : "pointer",
                                marginRight: "0.5rem",
                              }}
                              title="Pay and confirm held booking"
                            >
                              {confirmHoldLoading ? "Processing..." : "Pay & Confirm Hold"}
                            </button>
                          </div>
                        ) : null}
                        {ui.canCancel ? (
                          <div className="mt-3">
                            <button
                              type="button"
                              onClick={handleCancelBooking}
                              disabled={cancelLoading}
                              style={{
                                border: "1px solid #dc2626",
                                background: "#fff",
                                color: "#b91c1c",
                                borderRadius: "999px",
                                padding: "0.45rem 0.95rem",
                                fontWeight: 700,
                                cursor: cancelLoading ? "not-allowed" : "pointer",
                              }}
                              title="Submit cancellation request"
                            >
                              {cancelLoading ? "Cancelling..." : "Cancel Booking"}
                            </button>
                          </div>
                        ) : null}
                      </div>

                      <div style={{ marginTop: "1rem", borderTop: "1px solid #e2e8f0", paddingTop: "1rem" }}>
                        <div style={{ fontWeight: 700, color: "#132238", marginBottom: "0.5rem" }}>Cancellation Policy</div>
                        {ui.cancellationPolicies.length === 0 ? (
                          <div style={{ color: "#64748b" }}>Policy details are not available for this booking.</div>
                        ) : (
                          <div style={{ overflowX: "auto" }}>
                            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "0.92rem" }}>
                              <thead>
                                <tr style={{ background: "#f8fafc" }}>
                                  <th style={{ border: "1px solid #e2e8f0", padding: "0.5rem", textAlign: "left" }}>From</th>
                                  <th style={{ border: "1px solid #e2e8f0", padding: "0.5rem", textAlign: "left" }}>To</th>
                                  <th style={{ border: "1px solid #e2e8f0", padding: "0.5rem", textAlign: "left" }}>Charge</th>
                                </tr>
                              </thead>
                              <tbody>
                                {ui.cancellationPolicies.map((policy, index) => (
                                  <tr key={`${policy?.am || "am"}-${index}`}>
                                    <td style={{ border: "1px solid #e2e8f0", padding: "0.5rem" }}>
                                      {formatDate(policy?.from || policy?.fdt)}
                                    </td>
                                    <td style={{ border: "1px solid #e2e8f0", padding: "0.5rem" }}>
                                      {formatDate(policy?.to || policy?.tdt)}
                                    </td>
                                    <td style={{ border: "1px solid #e2e8f0", padding: "0.5rem" }}>
                                      {formatAmount(policy?.am, ui.currency)}
                                    </td>
                                  </tr>
                                ))}
                              </tbody>
                            </table>
                          </div>
                        )}
                      </div>
                    </>
                  )}
                </div>
              </div>
            </div>

            <div className="col-12 col-lg-4">
              <div
                style={{
                  background: "#fff",
                  borderRadius: "18px",
                  border: "1px solid #e2e8f0",
                  padding: "1rem 1.1rem",
                  position: "sticky",
                  top: "100px",
                }}
              >
                <div style={{ fontWeight: 800, color: "#132238", marginBottom: "0.75rem" }}>Fare Summary</div>
                {showPendingBookingSummary ? (
                  <>
                    <div className="d-flex justify-content-between" style={{ color: "#475569", marginBottom: "0.45rem" }}>
                      <span>Estimated Total</span>
                      <span>{formatAmount(ui.totalAmount, ui.currency)}</span>
                    </div>
                    <div style={{ color: "#475569", fontSize: "0.9rem" }}>
                      Complete fare breakdown will appear after payment completion.
                    </div>
                  </>
                ) : (
                  <>
                    <div className="d-flex justify-content-between" style={{ color: "#475569", marginBottom: "0.45rem" }}>
                      <span>Base Fare</span>
                      <span>{formatAmount(ui.baseFare, ui.currency)}</span>
                    </div>
                    <div className="d-flex justify-content-between" style={{ color: "#475569", marginBottom: "0.45rem" }}>
                      <span>Taxes & Fees</span>
                      <span>{formatAmount(ui.taxesAndFees, ui.currency)}</span>
                    </div>
                    <div className="d-flex justify-content-between" style={{ color: "#475569", marginBottom: "0.45rem" }}>
                      <span>MF</span>
                      <span>{formatAmount(ui.mf, ui.currency)}</span>
                    </div>
                    <div className="d-flex justify-content-between" style={{ color: "#475569", marginBottom: "0.45rem" }}>
                      <span>MFT</span>
                      <span>{formatAmount(ui.mft, ui.currency)}</span>
                    </div>
                    <div style={{ borderTop: "1px solid #e2e8f0", margin: "0.5rem 0" }} />
                    <div className="d-flex justify-content-between" style={{ fontWeight: 800, color: "#132238" }}>
                      <span>Total Amount</span>
                      <span>{formatAmount(ui.totalAmount, ui.currency)}</span>
                    </div>
                  </>
                )}
              </div>
            </div>
          </div>
        )}
      </Container>
    </section>
  );
}
