import { useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { toast } from "react-toastify";
import { ArrowRight, CheckCircle2, Loader2, MapPin } from "lucide-react";
import {
  buildCabBookingPayload,
  createCabBooking,
  createCabPaymentOrder,
  fetchCabBookingDetails,
  loadRazorpayScript,
  normalizeCabBookingDetail,
  verifyCabPayment,
} from "../../../../services/api/cabApi";
import "./index.css";

const formatFare = (value) =>
  `₹${Number(value || 0).toLocaleString("en-IN", { maximumFractionDigits: 0 })}`;

const formatDateTime = (value) => {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
};

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function CabBookingPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, isAuthenticated } = useSelector((state) => state.auth);

  const quote = location.state?.quote || null;
  const journeyInfo = location.state?.journeyInfo || null;
  const routeDetails = location.state?.routeDetails || null;

  const isAirportTransfer =
    String(journeyInfo?.journeyType || "").toUpperCase() === "AIRPORT_TRANSFER";

  const [form, setForm] = useState({
    firstName: "",
    lastName: "",
    email: "",
    phone: "",
    flightNumber: "",
    serviceRequest: "",
  });
  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);
  const [stage, setStage] = useState("");
  const [booking, setBooking] = useState(null);
  const [payment, setPayment] = useState(null);
  const [detail, setDetail] = useState(null);
  const [paymentError, setPaymentError] = useState("");
  const [canCheckStatus, setCanCheckStatus] = useState(false);

  // Booking is login-gated; a direct visit without a session goes to login.
  useEffect(() => {
    if (!isAuthenticated || !user?.id) {
      toast.error("Please login before booking a cab.");
      navigate("/customer-login");
    }
  }, [isAuthenticated, user?.id, navigate]);

  // Prefill from the logged-in profile where we can.
  useEffect(() => {
    if (!user) return;
    setForm((prev) => ({
      ...prev,
      firstName: prev.firstName || user.firstName || user.name?.split(" ")[0] || "",
      lastName: prev.lastName || user.lastName || "",
      email: prev.email || user.email || "",
      phone: prev.phone || user.phone || user.mobile || "",
    }));
  }, [user]);

  const setField = (key, value) => {
    setForm((prev) => ({ ...prev, [key]: value }));
    setErrors((prev) => ({ ...prev, [key]: "" }));
  };

  const validate = () => {
    const next = {};
    if (!form.firstName.trim()) next.firstName = "First name is required";
    if (!form.lastName.trim()) next.lastName = "Last name is required";
    if (!EMAIL_RE.test(form.email.trim())) next.email = "Enter a valid email";
    if (!/^\+?\d{8,15}$/.test(form.phone.replace(/[\s-]/g, ""))) {
      next.phone = "Enter a valid phone number";
    }
    setErrors(next);
    return Object.keys(next).length === 0;
  };

  const handleSubmit = async () => {
    if (!validate()) return;

    setSubmitting(true);
    try {
      const payload = buildCabBookingPayload({
        journeyInfo,
        routeDetails,
        quote,
        passenger: {
          firstName: form.firstName.trim(),
          lastName: form.lastName.trim(),
          email: form.email.trim(),
          phone: form.phone.trim(),
          flightNumber: isAirportTransfer ? form.flightNumber.trim() : "",
        },
        serviceRequest: form.serviceRequest.trim(),
        agentEmail: user?.email || form.email.trim(),
        agentPhone: form.phone.trim(),
        agentId: user?.id,
      });

      setStage("Creating booking...");
      const result = await createCabBooking(payload);
      if (!result?.id) {
        toast.error("Booking could not be created. Please try again.");
        return;
      }
      setBooking(result);
      await runPayment(result);
    } catch (error) {
      const message =
        error?.response?.data?.message || "Booking failed. Please try again.";
      toast.error(message);
    } finally {
      setSubmitting(false);
      setStage("");
    }
  };

  /**
   * The booking is created as PAYMENT_PENDING. Collect the fare from the
   * customer via Razorpay; the backend verifies the signature and then settles
   * with TripJack from the agent wallet, refunding automatically if that fails.
   */
  const runPayment = async (createdBooking) => {
    setPaymentError("");

    setStage("Starting payment...");
    const scriptReady = await loadRazorpayScript();
    if (!scriptReady || !window.Razorpay) {
      setPaymentError("Could not load the payment gateway. Please retry.");
      return;
    }

    const amount = quote.grossFare;
    let order;
    try {
      order = await createCabPaymentOrder({ bookingId: createdBooking.id, amount });
    } catch {
      setPaymentError("Could not start the payment. Please retry.");
      return;
    }
    if (!order?.razorpayOrderId || !order?.keyId) {
      setPaymentError("Payment order could not be created. Please retry.");
      return;
    }

    setStage("Opening payment gateway...");

    // Bridge the Razorpay callback promise so the caller can await the result
    // and the finally-block clears the submitting state correctly.
    await new Promise((resolve) => {
      const rzp = new window.Razorpay({
        key: order.keyId,
        order_id: order.razorpayOrderId,
        amount: order.amount,
        currency: order.currency || "INR",
        name: "HappyWedz Cabs",
        description: `${quote.label} — ${createdBooking.id}`,
        prefill: {
          name: `${form.firstName} ${form.lastName}`.trim(),
          email: form.email,
          contact: form.phone,
        },
        theme: { color: "#ed1173" },
        modal: {
          ondismiss: () => {
            setPaymentError("Payment was cancelled before completion.");
            resolve();
          },
        },
        handler: async (rzpResult) => {
          try {
            setStage("Confirming your cab...");
            const verifyResult = await verifyCabPayment({
              razorpay_order_id: rzpResult.razorpay_order_id || order.razorpayOrderId,
              razorpay_payment_id: rzpResult.razorpay_payment_id,
              razorpay_signature: rzpResult.razorpay_signature,
            });

            setPayment({ status: "SUCCESS", paymentRefId: verifyResult?.paymentId });
            const list = verifyResult?.bookingDetails;
            if (Array.isArray(list) && list.length) {
              setDetail(normalizeCabBookingDetail(list[0]));
            }
            toast.success("Payment successful. Your cab is booked.");
          } catch (error) {
            // Signature valid but settlement failed → backend has already
            // refunded. A verification/network failure is also surfaced here.
            const message =
              error?.response?.data?.message ||
              "Payment could not be confirmed. If you were charged, it will be refunded.";
            setPaymentError(message);
            setCanCheckStatus(true);
            toast.error(message);
          } finally {
            resolve();
          }
        },
      });

      rzp.on("payment.failed", (failure) => {
        setPaymentError(
          failure?.error?.description || "Payment failed. Please try again.",
        );
        resolve();
      });

      rzp.open();
    });
  };

  /**
   * Reconciles against TripJack when a verification result was lost (network
   * drop after charge). If the booking already settled, confirm it; otherwise
   * allow a fresh payment attempt.
   */
  const handleCheckStatus = async () => {
    if (!booking) return;
    setSubmitting(true);
    setStage("Checking payment status...");
    try {
      const details = await fetchCabBookingDetails(booking.id);
      const normalized = details.length
        ? normalizeCabBookingDetail(details[0])
        : null;
      if (normalized) setDetail(normalized);

      if (normalized && String(normalized.paymentStatus).toUpperCase() === "SUCCESS") {
        setPaymentError("");
        setPayment((prev) => prev || { status: "SUCCESS" });
        toast.success("Payment already completed. Your cab is booked.");
      } else {
        setCanCheckStatus(false);
        setPaymentError("Payment is not confirmed yet. You can pay again.");
      }
    } catch {
      setCanCheckStatus(false);
      setPaymentError("Could not check status. You can pay again.");
    } finally {
      setSubmitting(false);
      setStage("");
    }
  };

  const handleRetryPayment = async () => {
    if (!booking) return;
    setSubmitting(true);
    try {
      await runPayment(booking);
    } finally {
      setSubmitting(false);
      setStage("");
    }
  };

  if (!quote || !journeyInfo || !routeDetails) {
    return (
      <div className="cab-results-page">
        <div className="container cab-results-empty">
          <h2>No cab selected</h2>
          <p>Please search and select a cab before booking.</p>
          <button type="button" onClick={() => navigate("/honeymoon?tab=car-rental")}>
            Search cabs
          </button>
        </div>
      </div>
    );
  }

  if (booking) {
    // Prefer the post-payment order view when it has loaded; fall back to the
    // create-booking response while payment is still in flight.
    const paid = String(payment?.status).toUpperCase() === "SUCCESS";
    const vehicle = detail?.vehicle?.clazz || booking.bookingVehicle?.clazz || quote.label;
    const passengerName = detail?.passenger?.fullName || booking.passenger?.fullName;
    const journeyView = detail?.journey || booking.journey || {};
    const total = detail?.pricing?.grossAmount ?? booking.totalPrice;
    const trackingLink = detail?.trackingLink || booking.trackingLink;

    return (
      <div className="cab-results-page">
        <div className="container cab-booking-success">
          <CheckCircle2 size={44} color={paid ? "#22c55e" : "#f59e0b"} />
          <h2>{paid ? "Booking confirmed" : "Booking created"}</h2>
          <p className="cab-booking-id">Booking ID: {booking.id}</p>

          {submitting ? (
            <div className="cab-results-state">
              <Loader2 size={18} className="spin" /> {stage}
            </div>
          ) : null}

          {paymentError ? (
            <div className="cab-booking-payment-error">
              <p>{paymentError}</p>
              <div className="cab-booking-payment-actions">
                <button
                  type="button"
                  onClick={handleCheckStatus}
                  disabled={submitting}
                >
                  Check payment status
                </button>
                {/* Retry hidden right after a timeout: confirm status first so a
                    completed-but-unacknowledged debit isn't charged twice. */}
                {!canCheckStatus ? (
                  <button
                    type="button"
                    className="cab-booking-retry"
                    onClick={handleRetryPayment}
                    disabled={submitting}
                  >
                    Retry payment
                  </button>
                ) : null}
              </div>
            </div>
          ) : null}

          <div className="cab-booking-summary-card">
            <div className="cab-booking-summary-row">
              <span>Vehicle</span>
              <strong>{vehicle}</strong>
            </div>
            <div className="cab-booking-summary-row">
              <span>Passenger</span>
              <strong>{passengerName}</strong>
            </div>
            <div className="cab-booking-summary-row">
              <span>Pick-up</span>
              <strong>{formatDateTime(journeyView.pickupDate)}</strong>
            </div>
            <div className="cab-booking-summary-row">
              <span>Route</span>
              <strong>
                {journeyView.source} → {journeyView.destination}
              </strong>
            </div>
            {journeyView.distance ? (
              <div className="cab-booking-summary-row">
                <span>Distance</span>
                <strong>{journeyView.distance}</strong>
              </div>
            ) : null}
            <div className="cab-booking-summary-row">
              <span>Booking status</span>
              <strong>{detail?.status || booking.status}</strong>
            </div>
            <div className="cab-booking-summary-row">
              <span>Payment status</span>
              <strong>{detail?.paymentStatus || payment?.status || booking.paymentStatus}</strong>
            </div>
            {payment?.paymentRefId ? (
              <div className="cab-booking-summary-row">
                <span>Payment reference</span>
                <strong>{payment.paymentRefId}</strong>
              </div>
            ) : null}
            {detail?.rideStatus ? (
              <div className="cab-booking-summary-row">
                <span>Ride status</span>
                <strong>{detail.rideStatus.replace(/_/g, " ")}</strong>
              </div>
            ) : null}
            <div className="cab-booking-summary-row cab-booking-total">
              <span>Total paid</span>
              <strong>{formatFare(total)}</strong>
            </div>
          </div>

          {detail?.helpline ? (
            <p className="cab-booking-helpline">{detail.helpline}</p>
          ) : null}

          {trackingLink ? (
            <a
              className="cab-booking-track"
              href={trackingLink}
              target="_blank"
              rel="noopener noreferrer"
            >
              Track your ride
            </a>
          ) : null}

          <button type="button" onClick={() => navigate("/honeymoon?tab=car-rental")}>
            Book another cab
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="cab-results-page">
      <div className="cab-results-header">
        <div className="container">
          <div className="cab-route-line">
            <span>
              <MapPin size={16} /> {routeDetails.origin?.displayAddress}
            </span>
            <ArrowRight size={16} />
            <span>
              <MapPin size={16} /> {routeDetails.destination?.displayAddress}
            </span>
          </div>
          <div className="cab-route-meta">
            <span>{formatDateTime(journeyInfo.pickupDateTime)}</span>
            {journeyInfo.distance ? <span>{journeyInfo.distance}</span> : null}
          </div>
        </div>
      </div>

      <div className="container cab-results-body">
        <div className="cab-booking-layout">
          <div className="cab-booking-form">
            <h3>Passenger details</h3>

            <div className="cab-form-grid">
              <div className="cab-form-field">
                <label htmlFor="cab-first-name">First name</label>
                <input
                  id="cab-first-name"
                  type="text"
                  value={form.firstName}
                  onChange={(event) => setField("firstName", event.target.value)}
                />
                {errors.firstName ? <span>{errors.firstName}</span> : null}
              </div>

              <div className="cab-form-field">
                <label htmlFor="cab-last-name">Last name</label>
                <input
                  id="cab-last-name"
                  type="text"
                  value={form.lastName}
                  onChange={(event) => setField("lastName", event.target.value)}
                />
                {errors.lastName ? <span>{errors.lastName}</span> : null}
              </div>

              <div className="cab-form-field">
                <label htmlFor="cab-email">Email</label>
                <input
                  id="cab-email"
                  type="email"
                  value={form.email}
                  onChange={(event) => setField("email", event.target.value)}
                />
                {errors.email ? <span>{errors.email}</span> : null}
              </div>

              <div className="cab-form-field">
                <label htmlFor="cab-phone">Phone</label>
                <input
                  id="cab-phone"
                  type="tel"
                  placeholder="+919876543210"
                  value={form.phone}
                  onChange={(event) => setField("phone", event.target.value)}
                />
                {errors.phone ? <span>{errors.phone}</span> : null}
              </div>

              {isAirportTransfer ? (
                <div className="cab-form-field">
                  <label htmlFor="cab-flight">Flight number (optional)</label>
                  <input
                    id="cab-flight"
                    type="text"
                    placeholder="e.g. AI2952"
                    value={form.flightNumber}
                    onChange={(event) => setField("flightNumber", event.target.value)}
                  />
                </div>
              ) : null}

              <div className="cab-form-field cab-form-field--full">
                <label htmlFor="cab-request">Special request (optional)</label>
                <input
                  id="cab-request"
                  type="text"
                  placeholder="e.g. AC mandatory in car"
                  value={form.serviceRequest}
                  onChange={(event) => setField("serviceRequest", event.target.value)}
                />
              </div>
            </div>
          </div>

          <aside className="cab-booking-aside">
            <h3>Fare summary</h3>
            <div className="cab-booking-vehicle">
              {quote.image ? <img src={quote.image} alt={quote.label} /> : null}
              <div>
                <div className="cab-quote-title">{quote.label}</div>
                <div className="cab-quote-sub">{quote.model || quote.similarType}</div>
              </div>
            </div>

            <div className="cab-booking-summary-row">
              <span>Base fare</span>
              <strong>{formatFare(quote.netFare)}</strong>
            </div>
            <div className="cab-booking-summary-row">
              <span>Taxes &amp; fees</span>
              <strong>{formatFare(quote.totalTax)}</strong>
            </div>
            <div className="cab-booking-summary-row cab-booking-total">
              <span>Total payable</span>
              <strong>{formatFare(quote.grossFare)}</strong>
            </div>

            <button
              type="button"
              className="cab-quote-book cab-booking-submit"
              onClick={handleSubmit}
              disabled={submitting}
            >
              {submitting ? <Loader2 size={16} className="spin" /> : null}
              {submitting ? stage || "Booking..." : "Confirm & pay"}
            </button>
          </aside>
        </div>
      </div>
    </div>
  );
}
