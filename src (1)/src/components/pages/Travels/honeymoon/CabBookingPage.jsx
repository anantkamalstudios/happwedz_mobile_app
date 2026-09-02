import { useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { toast } from "react-toastify";
import {
  ArrowRight,
  Briefcase,
  CalendarDays,
  CheckCircle2,
  ChevronDown,
  ChevronUp,
  Info,
  Loader2,
  MapPin,
  Pencil,
  Users,
} from "lucide-react";
import {
  buildCabBookingPayload,
  createCabBooking,
  createCabPaymentOrder,
  fetchCabBookingDetails,
  loadRazorpayScript,
  normalizeCabBookingDetail,
  verifyCabPayment,
} from "../../../../services/api/cabApi";
import { formatDateTime as fmtDateTime } from "../../../../utils/dateFormat";
import { loginRedirect } from "../../../../utils/bookingDraft";
import CabPolicyModal from "./components/CabPolicyModal";
import "./index.css";
import "./components/CabBooking.css";

/** "One Way" / "Round Trip" from the API's tripType. */
const titleTrip = (value) =>
  String(value || "").toLowerCase() === "roundtrip" ? "Round Trip" : "One Way";

/** What happens after payment, as the portal spells it out. */
const STEPS = [
  {
    title: "Booking Confirmed",
    body: "You'll receive your booking voucher right after the payment.",
  },
  {
    title: "Cab & Driver Details",
    body: "We'll share your cab and driver details 6 hours before your trip.",
  },
  {
    title: "On-Time Pickup",
    body: "Your cab will arrive at the pickup point at the scheduled time. Enjoy your trip!",
  },
];

const formatFare = (value) =>
  `₹${Number(value || 0).toLocaleString("en-IN", { maximumFractionDigits: 0 })}`;

const formatDateTime = (value) => {
  if (!value) return "";
  return fmtDateTime(value, { fallback: value });
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
  const [paxOpen, setPaxOpen] = useState(true);
  const [policyOpen, setPolicyOpen] = useState(false);
  const [consent, setConsent] = useState(false);
  const [markup, setMarkup] = useState(Number(location.state?.markup) || 0);
  const [markupDraft, setMarkupDraft] = useState("");
  const [markupOpen, setMarkupOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [stage, setStage] = useState("");
  const [booking, setBooking] = useState(null);
  const [payment, setPayment] = useState(null);
  const [detail, setDetail] = useState(null);
  const [paymentError, setPaymentError] = useState("");
  const [canCheckStatus, setCanCheckStatus] = useState(false);

  // Booking is login-gated. The quote and journey arrive in history state, and
  // login forwards that state back, so the page rebuilds itself on return.
  useEffect(() => {
    if (!isAuthenticated || !user?.id) {
      navigate(...loginRedirect(location, "cab"), { replace: true });
    }
  }, [isAuthenticated, user?.id, navigate, location]);

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

    // Charge what the page shows. The markup is our margin: Razorpay collects
    // it, the supplier payload below is left at the quoted gross, exactly as the
    // flights flow treats it. Leaving it out here billed the traveller less than
    // the total they had just agreed to.
    const amount = quote.grossFare + Number(markup || 0);
    let order;
    try {
      order = await createCabPaymentOrder({
        bookingId: createdBooking.id,
        amount,
        supplierAmount: quote.grossFare,
      });
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

          <div style={{ display: "flex", gap: "10px", marginTop: "20px" }}>
            <button type="button" onClick={() => navigate("/user-dashboard/booking/travel/cabs")}>
              View my bookings
            </button>
            <button
              type="button"
              onClick={() => navigate("/honeymoon?tab=car-rental")}
              style={{ backgroundColor: "transparent", color: "#ed1173", border: "1px solid #ed1173" }}
            >
              Book another cab
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="cab-results-page cbk-page">
      <div className="container cbk-crumbs">
        <button type="button" onClick={() => navigate("/honeymoon?tab=car-rental")}>Home</button>
        <span>/</span>
        <button type="button" onClick={() => navigate(-1)}>
          Cabs in {routeDetails.origin?.city || routeDetails.origin?.displayAddress}
        </button>
        <span>/</span>
        <span>Cab Review</span>
      </div>

      <div className="container cbk-body">
        <div className="cbk-main">
          {/* trip summary */}
          <div className="cbk-card">
            <div className="cbk-trip-head">
              Cab Booking <span>|</span> {titleTrip(journeyInfo.tripType)}
            </div>
            <div className="cbk-trip-route">
              <div className="cbk-trip-end">
                <small>Pickup</small>
                <strong>{routeDetails.origin?.displayAddress}</strong>
              </div>
              <span className="cbk-trip-dash" aria-hidden="true" />
              <div className="cbk-trip-end">
                <small>Drop</small>
                <strong>{routeDetails.destination?.displayAddress}</strong>
              </div>
            </div>
            <div className="cbk-trip-when">
              <CalendarDays size={14} /> {formatDateTime(journeyInfo.pickupDateTime)}
              {journeyInfo.distance ? <span> | {journeyInfo.distance}</span> : null}
            </div>
          </div>

          {/* vehicle */}
          <div className="cbk-card cbk-vehicle">
            <div className="cbk-veh-media">
              <span className="cbk-veh-badge">
                {(quote.label || quote.vehicleType || "").toUpperCase()}
              </span>
              {quote.image ? <img src={quote.image} alt={quote.label} /> : null}
            </div>
            <div className="cbk-veh-main">
              <h3>{quote.label || quote.vehicleType}</h3>
              <div className="cbk-veh-chips">
                <span><Users size={13} /> {quote.paxCapacity ?? quote.paxCount ?? "-"} Seats</span>
                <span><Briefcase size={13} /> {quote.luggageCapacity ?? quote.luggageCount ?? "-"} Bags</span>
              </div>
              <button type="button" className="cbk-policies" onClick={() => setPolicyOpen(true)}>
                View policies
              </button>
            </div>
            <div className="cbk-veh-fare">
              <strong>{formatFare(quote.grossFare + markup)}</strong>
              <small>Inc. GST</small>
            </div>
          </div>

          {/* traveller */}
          <div className="cbk-card">
            <button
              type="button"
              className="cbk-sec-head"
              onClick={() => setPaxOpen((v) => !v)}
              aria-expanded={paxOpen}
            >
              Primary traveller details
              {paxOpen ? <ChevronUp size={17} /> : <ChevronDown size={17} />}
            </button>

            {paxOpen && (
              <>
                <p className="cbk-note">
                  <Info size={14} /> We will use your email and contact number to share cab and
                  driver details 6 hours before trip start
                </p>

                <div className="cbk-grid">
                  <div className="cbk-field">
                    <label htmlFor="cab-first-name">First name <i>*</i></label>
                    <input
                      id="cab-first-name"
                      type="text"
                      placeholder="Enter first name"
                      value={form.firstName}
                      onChange={(event) => setField("firstName", event.target.value)}
                    />
                    {errors.firstName ? <span className="cbk-err">{errors.firstName}</span> : null}
                  </div>

                  <div className="cbk-field">
                    <label htmlFor="cab-last-name">Last name <i>*</i></label>
                    <input
                      id="cab-last-name"
                      type="text"
                      placeholder="Enter last name"
                      value={form.lastName}
                      onChange={(event) => setField("lastName", event.target.value)}
                    />
                    {errors.lastName ? <span className="cbk-err">{errors.lastName}</span> : null}
                  </div>

                  <div className="cbk-field">
                    <label htmlFor="cab-email">Email address <i>*</i></label>
                    <input
                      id="cab-email"
                      type="email"
                      placeholder="Enter email address"
                      value={form.email}
                      onChange={(event) => setField("email", event.target.value)}
                    />
                    {errors.email ? <span className="cbk-err">{errors.email}</span> : null}
                  </div>

                  <div className="cbk-field">
                    <label htmlFor="cab-phone">Phone number <i>*</i></label>
                    <input
                      id="cab-phone"
                      type="tel"
                      placeholder="+91"
                      value={form.phone}
                      onChange={(event) => setField("phone", event.target.value)}
                    />
                    {errors.phone ? <span className="cbk-err">{errors.phone}</span> : null}
                  </div>

                  <div className="cbk-field">
                    <label htmlFor="cab-flight">
                      Flight Number {isAirportTransfer ? <i>*</i> : <em>(optional)</em>}
                    </label>
                    <input
                      id="cab-flight"
                      type="text"
                      placeholder="Enter Flight Number"
                      value={form.flightNumber}
                      onChange={(event) => setField("flightNumber", event.target.value)}
                    />
                    {errors.flightNumber ? <span className="cbk-err">{errors.flightNumber}</span> : null}
                  </div>

                  <div className="cbk-field">
                    <label htmlFor="cab-request">Special service request <em>(optional)</em></label>
                    <input
                      id="cab-request"
                      type="text"
                      placeholder="Enter request"
                      value={form.serviceRequest}
                      onChange={(event) => setField("serviceRequest", event.target.value)}
                    />
                  </div>
                </div>
              </>
            )}
          </div>

          {/* what happens next */}
          <div className="cbk-card cbk-steps">
            {STEPS.map((step, i) => (
              <div className="cbk-step" key={step.title}>
                <span className="cbk-step-tag">Step {i + 1}</span>
                <strong>{step.title}</strong>
                <p>{step.body}</p>
              </div>
            ))}
          </div>

          <label className="cbk-consent">
            <input
              type="checkbox"
              checked={consent}
              onChange={(e) => setConsent(e.target.checked)}
            />
            <span>
              I confirm that the booking details are accurate, the traveller has consented to this
              reservation and agrees to the <a href="/terms">Terms &amp; Conditions</a>, and I
              authorize Happy Wedz to use the traveller&apos;s email and phone number to share cab
              and driver details.
            </span>
          </label>

          <div className="cbk-pay-row">
            <button
              type="button"
              className="cbk-pay"
              onClick={handleSubmit}
              disabled={submitting || !consent}
            >
              {submitting ? (stage || "Booking...") : "Pay Now"} <ArrowRight size={16} />
            </button>
          </div>
        </div>

        {/* price breakup */}
        <aside className="cbk-side">
          <div className="cbk-card cbk-price">
            <h4>Price breakup</h4>
            <div className="cbk-price-row is-strong">
              <span>Net fare</span><span>{formatFare(quote.netFare)}</span>
            </div>
            <div className="cbk-price-row">
              <span>Forward Trip</span><span>{formatFare(quote.netFare)}</span>
            </div>
            <div className="cbk-price-row">
              <span>Management Fee</span><span>{formatFare(0)}</span>
            </div>
            <div className="cbk-price-row is-strong cbk-price-markup">
              <span>Other fees</span>
              <span>
                {formatFare(markup)}
                <button
                  type="button"
                  onClick={() => setMarkupOpen((v) => !v)}
                  aria-label="Add markup"
                >
                  <Pencil size={13} />
                </button>
              </span>

              {markupOpen && (
                <div className="cbk-markup">
                  <strong>Add markup</strong>
                  <label>
                    <span>&#8377;</span>
                    <input
                      type="number"
                      autoFocus
                      placeholder="Forward trip markup"
                      value={markupDraft}
                      onChange={(e) => setMarkupDraft(e.target.value)}
                    />
                  </label>
                  <div className="cbk-markup-actions">
                    <button type="button" onClick={() => setMarkupOpen(false)}>Cancel</button>
                    <button
                      type="button"
                      className="is-primary"
                      onClick={() => { setMarkup(Number(markupDraft) || 0); setMarkupOpen(false); }}
                    >
                      Update
                    </button>
                  </div>
                </div>
              )}
            </div>
            <div className="cbk-price-row">
              <span>Service Fee</span><span>{formatFare(quote.totalTax)}</span>
            </div>
            <div className="cbk-price-total">
              <span>Total amount</span><span>{formatFare(quote.grossFare + markup)}</span>
            </div>
          </div>
        </aside>
      </div>

      {policyOpen && (
        <CabPolicyModal quote={quote} onClose={() => setPolicyOpen(false)} />
      )}
    </div>
  );
}
