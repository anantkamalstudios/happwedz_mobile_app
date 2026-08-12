import { useState, useMemo } from 'react';
import { FaPlane, FaUser, FaEnvelope, FaPhone, FaChevronDown, FaChevronUp } from 'react-icons/fa';
import { createFlightPaymentOrder, verifyAndBookFlight, getFareRule, holdFlightBooking } from '../../../../../services/api/flightApi';
import FlightAddons from './FlightAddons';

const policyLabel = (type) => ({ CANCELLATION: 'Cancellation', DATECHANGE: 'Date Change', NO_SHOW: 'No Show', SEAT_CHARGEABLE: 'Seat' }[type] || type);
const timeLabel = (p) => {
  if (p.pp) return p.pp.replace(/_/g, ' ');
  if (p.et != null && p.st != null) return `${p.st}h – ${p.et}h before departure`;
  return 'As per policy';
};
function FareRuleDisplay({ data }) {
  const rule = data?.farerule || {};
  const routes = Object.keys(rule);
  if (!routes.length) return <p className="text-muted small mb-0">No fare rules available.</p>;
  return (
    <div>
      {routes.map((route) => {
        const { tfr, miscInfo } = rule[route];
        return (
          <div key={route} className="mb-3">
            <div className="fw-semibold fs-14 mb-2">{route.replace('-', ' → ')}</div>
            {miscInfo?.length ? (
              <pre style={{ fontSize: 12, whiteSpace: 'pre-wrap', maxHeight: 200, overflowY: 'auto' }}>{miscInfo.join('\n')}</pre>
            ) : tfr ? (
              Object.keys(tfr).map((type) => {
                const policies = Array.isArray(tfr[type]) ? tfr[type] : [tfr[type]];
                return (
                  <div key={type} className="mb-2">
                    <div className="fw-medium fs-13 text-secondary mb-1">{policyLabel(type)}</div>
                    {policies.map((p, i) => (
                      <div key={i} className="d-flex flex-wrap gap-3 fs-13 py-1 border-bottom">
                        <span className="text-muted">{timeLabel(p)}</span>
                        <span>Airline fee: <strong>₹{Number(p.amount || 0).toLocaleString('en-IN')}</strong></span>
                        {p.additionalFee ? <span>Platform fee: <strong>₹{Number(p.additionalFee).toLocaleString('en-IN')}</strong></span> : null}
                        {p.policyInfo ? <span className="text-muted fst-italic">{p.policyInfo}</span> : null}
                      </div>
                    ))}
                  </div>
                );
              })
            ) : (
              <p className="text-muted small mb-0">Contact support for fare rules.</p>
            )}
          </div>
        );
      })}
    </div>
  );
}

export default function BookingReview({ 
  trip, 
  returnTrip, 
  fare, 
  returnFare, 
  searchParams, 
  travellerInfo, 
  contact,
  gstInfo,
  emergencyContact,
  seatSelections,
  bookingId,
  reviewData,
  onBack,
  onPaymentSuccess
}) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [fareRuleOpen, setFareRuleOpen] = useState(false);
  const [fareRuleData, setFareRuleData] = useState(null);
  const [fareRuleLoading, setFareRuleLoading] = useState(false);
  const [mealSel, setMealSel] = useState({}); // `${paxIdx}_${segId}` -> {code, amount}
  const [bagSel, setBagSel] = useState({});

  // SSR meal/baggage options per segment, from the review response.
  const ssrSegments = useMemo(() => {
    const ti = reviewData?.tripInfos;
    const trips = Array.isArray(ti) ? ti : Object.values(ti || {}).flat();
    const segs = [];
    for (const t of trips) {
      for (const s of (t?.sI || [])) {
        segs.push({
          id: String(s.id),
          label: `${s.da?.code || ''} → ${s.aa?.code || ''}`,
          meals: s.ssrInfo?.MEAL || [],
          baggage: s.ssrInfo?.BAGGAGE || [],
        });
      }
    }
    return segs;
  }, [reviewData]);

  // Total cost of selected meals + baggage.
  const addonsTotal = useMemo(() => {
    let t = 0;
    Object.values(mealSel).forEach((s) => { t += Number(s.amount) || 0; });
    Object.values(bagSel).forEach((s) => { t += Number(s.amount) || 0; });
    return t;
  }, [mealSel, bagSel]);

  // Build per-traveller ssrMealInfos / ssrBaggageInfos from the selections.
  const ssrForTraveller = (idx) => {
    const ssrMealInfos = ssrSegments
      .map((seg) => { const sel = mealSel[`${idx}_${seg.id}`]; return sel ? { key: seg.id, code: sel.code } : null; })
      .filter(Boolean);
    const ssrBaggageInfos = ssrSegments
      .map((seg) => { const sel = bagSel[`${idx}_${seg.id}`]; return sel ? { key: seg.id, code: sel.code } : null; })
      .filter(Boolean);
    return { ssrMealInfos, ssrBaggageInfos };
  };

  const handleToggleFareRule = async () => {
    setFareRuleOpen((prev) => !prev);
    if (!fareRuleOpen && !fareRuleData && bookingId) {
      setFareRuleLoading(true);
      try {
        const data = await getFareRule(bookingId, 'REVIEW');
        setFareRuleData(data);
      } catch {
        setFareRuleData({ error: true });
      } finally {
        setFareRuleLoading(false);
      }
    }
  };

  const loadRazorpayScript = () => {
    return new Promise((resolve) => {
      if (window.Razorpay) {
        resolve(true);
        return;
      }
      const script = document.createElement('script');
      script.src = 'https://checkout.razorpay.com/v1/checkout.js';
      script.onload = () => resolve(true);
      script.onerror = () => resolve(false);
      document.body.appendChild(script);
    });
  };

  const formatTime = (dateStr) => {
    return new Date(dateStr).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
  };

  const formatDate = (dateStr) => {
    return new Date(dateStr).toLocaleDateString('en-US', { day: 'numeric', month: 'short', year: 'numeric' });
  };

  const formatDuration = (minutes) => {
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    return `${h}h ${m}m`;
  };

  // Get confirmed amount from review API response
  const getConfirmedAmount = () => {
    if (!reviewData) {
      // Fallback to calculated amount if reviewData is not available
      return calculateTotalAmount();
    }

    // Try different possible paths in the review response
    let totalFlightAmount = 0;

    // Path 1: reviewData.results[] shape
    if (Array.isArray(reviewData.results) && reviewData.results.length > 0) {
      totalFlightAmount = reviewData.results.reduce((sum, r) => {
        const fare = r?.fare?.fd?.ADULT?.fC?.TF || r?.totalPriceList?.[0]?.fd?.ADULT?.fC?.TF || 0;
        return sum + Number(fare || 0);
      }, 0);
    }
    // Path 2: reviewData.totalPriceList[] shape
    else if (Array.isArray(reviewData.totalPriceList) && reviewData.totalPriceList.length > 0) {
      totalFlightAmount = Number(reviewData.totalPriceList[0]?.fd?.ADULT?.fC?.TF || 0);
    }
    // Path 3a: reviewData.tripInfos is ARRAY (your current response)
    else if (Array.isArray(reviewData.tripInfos) && reviewData.tripInfos.length > 0) {
      totalFlightAmount = reviewData.tripInfos.reduce((sum, trip) => {
        const fare = trip?.totalPriceList?.[0]?.fd?.ADULT?.fC?.TF || 0;
        return sum + Number(fare || 0);
      }, 0);
    }
    // Path 3b: reviewData.tripInfos is OBJECT with numeric keys
    else if (reviewData.tripInfos && typeof reviewData.tripInfos === 'object') {
      const tripInfosValues = Object.values(reviewData.tripInfos);
      totalFlightAmount = tripInfosValues.reduce((sum, routeTrips) => {
        if (!Array.isArray(routeTrips) || routeTrips.length === 0) return sum;
        const routeFare = routeTrips[0]?.totalPriceList?.[0]?.fd?.ADULT?.fC?.TF || 0;
        return sum + Number(routeFare || 0);
      }, 0);
    }
    // Path 4: direct totalFare
    else if (reviewData.totalFare) {
      totalFlightAmount = Number(reviewData.totalFare || 0);
    }

    if (!totalFlightAmount || Number.isNaN(totalFlightAmount)) {
      console.warn('Could not find confirmed amount in reviewData, using calculated amount');
      totalFlightAmount = calculateTotalAmount();
    }

    // Add seat + add-on (meal/baggage) charges
    const seatTotal = seatSelections?.reduce((sum, seat) => sum + (seat.amount || 0), 0) || 0;

    return totalFlightAmount + seatTotal + addonsTotal;
  };

  const calculateTotalAmount = () => {
    const adults = searchParams.adults || 1;
    const onwardTotal = fare.fd.ADULT.fC.TF * adults;
    const returnTotal = returnFare ? returnFare.fd.ADULT.fC.TF * adults : 0;
    const seatTotal = seatSelections?.reduce((sum, seat) => sum + (seat.amount || 0), 0) || 0;
    return onwardTotal + returnTotal + seatTotal;
  };

  const renderFlightSummary = (flightTrip, flightFare, title) => {
    const first = flightTrip.sI[0];
    const last = flightTrip.sI[flightTrip.sI.length - 1];
    const airline = first.fD.aI;
    const duration = flightTrip.sI.reduce((sum, seg) => sum + seg.duration, 0);
    const stops = flightTrip.sI.length - 1;

    return (
      <div className="flight-summary-compact mb-3">
        <h6 className="flight-summary-title">{title}</h6>
        <div className="d-flex align-items-center gap-3">
          <img
            src={`https://logos.skyscnr.com/images/airlines/favicon/${airline.code}.png`}
            alt={airline.name}
            className="airline-logo-sm"
            onError={(e) => {
              e.target.onerror = null;
              e.target.src = `https://airlines.airhex.com/airlines-logo/${airline.code.toLowerCase()}.png`;
            }}
          />
          <div className="flex-grow-1">
            <div className="d-flex justify-content-between align-items-center">
              <div>
                <div className="airline-name-sm">{airline.name} {first.fD.fN}</div>
                <div className="flight-route-sm">
                  {first.da.code} {formatTime(first.dt)} → {last.aa.code} {formatTime(last.at)}
                </div>
              </div>
              <div className="text-end">
                <div className="flight-duration-sm">{formatDuration(duration)}</div>
                <div className="flight-stops-sm">{stops === 0 ? 'Non-Stop' : `${stops} Stop${stops > 1 ? 's' : ''}`}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  };

  // Build the TripJack book payload + create_order/hold fields (shared by Pay & Hold).
  const buildPaymentOrderPayload = () => {
    const confirmedAmount = getConfirmedAmount();
    const cleanCountryCode = contact.countryCode.replace(/^\+/, '');
    const fullPhoneNumber = `${cleanCountryCode}${contact.mobile}`;

    // TripJack validates paymentInfos.amount against the session fare (no markup).
    const tripjackFare =
      Number(reviewData?.totalPriceInfo?.totalFareDetail?.fC?.NF) ||
      Number(reviewData?.totalPriceInfo?.totalFareDetail?.fC?.TF) ||
      confirmedAmount;

    // Attach selected seats + meals + baggage (SSR) to each traveller, keyed by segment id.
    const travellerInfoWithSsr = travellerInfo.map((t, idx) => {
      const seatsForPax = (seatSelections || []).filter((s) => s.passengerId === `passenger_${idx}`);
      const { ssrMealInfos, ssrBaggageInfos } = ssrForTraveller(idx);
      const out = { ...t };
      if (seatsForPax.length) out.ssrSeatInfos = seatsForPax.map((s) => ({ key: String(s.segmentId), code: s.seatNo }));
      if (ssrMealInfos.length) out.ssrMealInfos = ssrMealInfos;
      if (ssrBaggageInfos.length) out.ssrBaggageInfos = ssrBaggageInfos;
      return out;
    });

    const seatTotal = (seatSelections || []).reduce((sum, s) => sum + (Number(s.amount) || 0), 0);
    // TripJack validates paymentInfos.amount against TF + all SSR (seat/meal/baggage) charges.
    const tripjackPaymentAmount = tripjackFare + seatTotal + addonsTotal;

    const payload = {
      bookingId: bookingId,
      paymentInfos: [{ amount: tripjackPaymentAmount }],
      travellerInfo: travellerInfoWithSsr,
      deliveryInfo: { emails: [contact.email], contacts: [fullPhoneNumber] },
      ...(gstInfo && {
        gstInfo: {
          gstNumber: gstInfo.gstNumber,
          email: gstInfo.companyEmail,
          registeredName: gstInfo.companyName,
          mobile: fullPhoneNumber,
          address: '',
        },
      }),
      // Emergency contact (required when review conditions.iecr is true).
      ...(emergencyContact && {
        contactInfo: {
          emails: [emergencyContact.email],
          contacts: [emergencyContact.mobile],
          ecn: emergencyContact.name,
        },
      }),
    };

    return {
      provider: 'tripjack',
      offer_id: bookingId,
      trip_type: returnTrip ? 'round' : 'oneway',
      from: trip?.sI?.[0]?.da?.code || '',
      to: trip?.sI?.[trip.sI.length - 1]?.aa?.code || '',
      departure: trip?.sI?.[0]?.dt || '',
      arrival: trip?.sI?.[trip.sI.length - 1]?.at || '',
      flight_no: `${trip?.sI?.[0]?.fD?.aI?.code || ''}-${trip?.sI?.[0]?.fD?.fN || ''}`,
      airline: trip?.sI?.[0]?.fD?.aI?.name || '',
      cabin_class: fare?.fd?.ADULT?.cc || 'ECONOMY',
      price: confirmedAmount,
      passengers: travellerInfo,
      contact: { email: contact.email, phone: fullPhoneNumber },
      booking_payload: payload,
    };
  };

  // HOLD: block the fare without payment — customer pays & confirms later.
  const handleHold = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await holdFlightBooking(buildPaymentOrderPayload());
      if (res?.status) {
        onPaymentSuccess({ ...res, on_hold: true, order_id: res.held_booking_id, amount_paid: 0 });
      } else {
        setError(res?.message || 'Could not hold this fare. Please try again.');
      }
    } catch (e) {
      setError(e.response?.data?.message || 'Could not hold this fare. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleProceedToPayment = async () => {
    setLoading(true);
    setError(null);

    try {
      const razorpayReady = await loadRazorpayScript();
      if (!razorpayReady) {
        throw new Error('Razorpay SDK failed to load');
      }

      const paymentOrderPayload = buildPaymentOrderPayload();
      // These are local to buildPaymentOrderPayload — re-derive for the Razorpay options/handler below.
      const payload = paymentOrderPayload.booking_payload;
      const fullPhoneNumber = paymentOrderPayload.contact?.phone || '';

      let orderResponse;
      try {
        orderResponse = await createFlightPaymentOrder(paymentOrderPayload);
      } catch (paymentOrderError) {
        const errMsg = paymentOrderError.response?.data?.message || paymentOrderError.message || 'Failed to create payment order';
        console.error('create_order failed:', paymentOrderError.response?.data || paymentOrderError.message);
        throw new Error(errMsg);
      }

      // Support backend response: { razorpay_order_id, key_id, amount, currency }
      const orderId = orderResponse?.razorpay_order_id || orderResponse?.order_id || orderResponse?.order?.id || orderResponse?.id;
      const razorpayKey = orderResponse?.key_id || orderResponse?.key || orderResponse?.razorpay_key || import.meta.env.VITE_RAZORPAY_KEY_ID || '';
      const orderAmount = orderResponse?.amount || orderResponse?.order?.amount || undefined;
      const orderCurrency = orderResponse?.currency || orderResponse?.order?.currency || 'INR';

      if (!orderId || !razorpayKey) {
        throw new Error('Payment order created but Razorpay credentials missing. Please contact support.');
      }

      const options = {
        key: razorpayKey,
        amount: orderAmount,
        currency: orderCurrency,
        name: 'HappyWedz',
        description: 'Flight Booking Payment',
        order_id: orderId,
        prefill: {
          name: travellerInfo?.[0] ? `${travellerInfo[0].fN || ''} ${travellerInfo[0].lN || ''}`.trim() : '',
          email: contact.email,
          contact: fullPhoneNumber,
        },
        handler: async function (rzpResponse) {
          try {
            const verifyPayload = {
              razorpay_order_id: rzpResponse.razorpay_order_id,
              razorpay_payment_id: rzpResponse.razorpay_payment_id,
              razorpay_signature: rzpResponse.razorpay_signature,
              booking_payload: payload,
            };
            const verifyResponse = await verifyAndBookFlight(verifyPayload);
            if (verifyResponse && (verifyResponse.status === true || verifyResponse.booking_id || verifyResponse.order_id || verifyResponse.bookingId)) {
              onPaymentSuccess(verifyResponse);
            } else {
              setError('Payment was received but booking confirmation failed. Please contact support with payment ID: ' + rzpResponse.razorpay_payment_id);
            }
          } catch (verifyErr) {
            console.error('Payment verification error:', verifyErr);
            setError(verifyErr.response?.data?.message || 'Payment succeeded but verification failed.');
          } finally {
            setLoading(false);
          }
        },
        modal: {
          ondismiss: () => {
            setLoading(false);
          },
        },
        theme: { color: '#ed1173' },
      };

      const rzp = new window.Razorpay(options);
      rzp.on('payment.failed', function (response) {
        setLoading(false);
        setError(response?.error?.description || 'Payment failed. Please try again.');
      });
      rzp.open();
      return;
    } catch (err) {
      console.error('Booking error:', err);
      setError(err.response?.data?.message || 'Failed to complete booking. Please try again.');
      setLoading(false);
    }
  };

  return (
    <div className="row">
      <div className="col-lg-8">
        <div className="booking-card">
          <h4 className="booking-card-title">Review Your Booking</h4>
          
          {error && (
            <div className="alert alert-danger" role="alert">
              {error}
            </div>
          )}
          
          <div className="review-section">
            <h5 className="review-section-title">
              <FaPlane className="me-2" />
              Flight Details
            </h5>
            {renderFlightSummary(trip, fare, 'Onward Journey')}
            {returnTrip && renderFlightSummary(returnTrip, returnFare, 'Return Journey')}
          </div>
          
          {/* Fare Rules — fetched with REVIEW flowType so rules reflect the confirmed booking session */}
          <div className="review-section mt-3">
            <button
              type="button"
              className="btn btn-link p-0 fs-14 text-decoration-none d-flex align-items-center gap-2"
              onClick={handleToggleFareRule}
            >
              {fareRuleOpen ? <FaChevronUp /> : <FaChevronDown />}
              View Fare Rules (Cancellation &amp; Date Change policy)
            </button>
            {fareRuleOpen && (
              <div className="mt-2 p-3 rounded" style={{ background: '#f8f9fa' }}>
                {fareRuleLoading && (
                  <div className="text-center py-2">
                    <span className="spinner-border spinner-border-sm me-2" />
                    Loading fare rules…
                  </div>
                )}
                {!fareRuleLoading && fareRuleData?.error && (
                  <p className="text-muted small mb-0">Fare rules unavailable. Please contact support.</p>
                )}
                {!fareRuleLoading && !fareRuleData?.error && (
                  <FareRuleDisplay data={fareRuleData} />
                )}
              </div>
            )}
          </div>

          <div className="review-section mt-4">
            <h5 className="review-section-title">
              <FaUser className="me-2" />
              Passenger Details
            </h5>
            {travellerInfo.map((traveller, index) => (
              <div key={index} className="passenger-review-item">
                <div className="passenger-review-number">Passenger {index + 1}</div>
                <div className="passenger-review-details">
                  <strong>{traveller.ti} {traveller.fN} {traveller.lN}</strong>
                  <span className="ms-3 text-muted">{traveller.pt}</span>
                  <span className="ms-3 text-muted">DOB: {traveller.dob}</span>
                </div>
              </div>
            ))}
          </div>
          
          <div className="review-section mt-4">
            <h5 className="review-section-title">
              <FaEnvelope className="me-2" />
              Contact Information
            </h5>
            <div className="contact-review">
              <div className="contact-review-item">
                <FaPhone className="me-2" />
                {contact.countryCode} {contact.mobile}
              </div>
              <div className="contact-review-item">
                <FaEnvelope className="me-2" />
                {contact.email}
              </div>
            </div>
          </div>

          <FlightAddons
            segments={ssrSegments}
            travellers={travellerInfo}
            mealSel={mealSel}
            bagSel={bagSel}
            setMealSel={setMealSel}
            setBagSel={setBagSel}
          />

          {seatSelections && seatSelections.length > 0 && (
            <div className="review-section mt-4">
              <h5 className="review-section-title">Selected Seats</h5>
              <div className="seats-review">
                {seatSelections.map((seat, index) => (
                  <div key={index} className="seat-review-item">
                    <span className="seat-passenger">{seat.passengerName || `Passenger ${index + 1}`}</span>
                    <span className="seat-number-badge">{seat.seatNo}</span>
                    <span className="seat-amount">₹{Number(seat.amount).toLocaleString('en-IN')}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
          
          {gstInfo && (
            <div className="review-section mt-4">
              <h5 className="review-section-title">GST Details</h5>
              <div className="gst-review">
                <div><strong>Company:</strong> {gstInfo.companyName}</div>
                <div><strong>GST Number:</strong> {gstInfo.gstNumber}</div>
                <div><strong>Email:</strong> {gstInfo.companyEmail}</div>
              </div>
            </div>
          )}
        </div>
      </div>
      
      <div className="col-lg-4">
        <div className="booking-card sticky-summary">
          <h5 className="booking-card-title">Fare Summary</h5>
          
          <div className="fare-summary-review">
            <div className="fare-row">
              <span>Onward Flight</span>
              <span>₹{Number(fare.fd.ADULT.fC.TF * (searchParams.adults || 1)).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</span>
            </div>
            {returnFare && (
              <div className="fare-row">
                <span>Return Flight</span>
                <span>₹{Number(returnFare.fd.ADULT.fC.TF * (searchParams.adults || 1)).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</span>
              </div>
            )}
            {seatSelections && seatSelections.length > 0 && (
              <div className="fare-row">
                <span>Seat Charges</span>
                <span>₹{Number(seatSelections.reduce((sum, seat) => sum + (seat.amount || 0), 0)).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</span>
              </div>
            )}
            {addonsTotal > 0 && (
              <div className="fare-row">
                <span>Meals &amp; Baggage</span>
                <span>₹{Number(addonsTotal).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</span>
              </div>
            )}
            <div className="fare-row fare-total mt-3 pt-3">
              <span>Total Amount</span>
              <span>₹{Number(getConfirmedAmount()).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</span>
            </div>
          </div>
          
          <div className="terms-notice mt-3">
            <small className="text-muted">
              By proceeding, you agree to our Terms & Conditions and Privacy Policy.
            </small>
          </div>
          
          <div className="d-flex gap-2 mt-4">
            <button
              type="button"
              className="btn btn-outline-secondary flex-grow-1"
              onClick={onBack}
              disabled={loading}
            >
              Back
            </button>
            <button
              type="button"
              className="btn btn-primary flex-grow-1"
              onClick={handleProceedToPayment}
              disabled={loading}
            >
              {loading ? 'Processing...' : 'Confirm Booking'}
            </button>
          </div>

          {/* Hold option — only when TripJack allows blocking this fare (conditions.isBA) */}
          {reviewData?.conditions?.isBA && (
            <button
              type="button"
              className="btn btn-outline-primary w-100 mt-2"
              onClick={handleHold}
              disabled={loading}
            >
              {loading ? 'Please wait…' : 'Hold this fare (pay later)'}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
