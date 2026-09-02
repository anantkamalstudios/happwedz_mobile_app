import { useState, useMemo } from 'react';
import { FaSuitcase, FaUtensils } from 'react-icons/fa';
import { createFlightPaymentOrder, verifyAndBookFlight, holdFlightBooking } from '../../../../../services/api/flightApi';
import { ssrForTraveller, addOnTotal, addOnBreakdown } from './FlightAddOn';
import FareSummary from './FareSummary';
import FlightSegments from './FlightSegments';
import { shortDob } from './flightFormat';

/** The portal marks each traveller with their type initial after the name. */
const PAX_INITIAL = { ADULT: 'A', CHILD: 'C', INFANT: 'I' };

export default function BookingReview({ 
  markup = 0,
  trip, 
  returnTrip, 
  fare, 
  returnFare, 
  searchParams, 
  travellerInfo, 
  contact,
  gstInfo,
  emergencyContact,
  addOns,
  agentNote,
  bookingId,
  reviewData,
  onBack,
  onPaymentSuccess
}) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);


  // SSR meal/baggage options per segment, from the review response.
  // Everything seat/meal/baggage was chosen on the passenger step; the review
  // only has to price it and fold it into the traveller payload.
  const addonsTotal = addOnTotal(addOns);

  // Add-ons are keyed by TripJack's segment id; the review labels each choice
  // by its leg ("BOM-BLR : 2E"), so map ids back to route codes once.
  const segRoute = useMemo(() => {
    const map = {};
    for (const leg of [trip, returnTrip]) {
      for (const s of leg?.sI || []) map[s.id] = `${s.da.code}-${s.aa.code}`;
    }
    return map;
  }, [trip, returnTrip]);

  /**
   * Flatten one passenger's picks for a kind into [{ route, text }].
   * Seats store a single object per leg; meals and baggage store a map of
   * code -> item, so both shapes are handled here.
   */
  const segmentChoices = (bySeg) =>
    Object.entries(bySeg || {})
      .map(([segId, val]) => {
        const route = segRoute[segId] || segId;
        const text = val?.code
          ? val.code
          : Object.values(val || {})
              .filter((i) => i?.qty)
              .map((i) => (i.qty > 1 ? `${i.desc || i.code} × ${i.qty}` : i.desc || i.code))
              .join(', ');
        return { route, text };
      })
      .filter((x) => x.text);

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

  // Get confirmed amount from review API response
  const paxCounts = {
    ADULT: Number(searchParams.adults || 1),
    CHILD: Number(searchParams.children || 0),
    INFANT: Number(searchParams.infants || 0),
  };

  /**
   * Sum a fare component across every passenger type.
   *
   * `fd` is keyed by pax type and each amount is per passenger, so reading
   * `fd.ADULT` alone prices the booking for one adult regardless of who is
   * actually travelling.
   */
  const sumAcrossPax = (tripFare, key) =>
    Object.entries(paxCounts).reduce((total, [type, count]) => {
      const amount = tripFare?.fd?.[type]?.fC?.[key];
      return total + (amount ? amount * count : 0);
    }, 0);

  /** Grand total TripJack quoted for this session, across all passengers. */
  const reviewGrandTotal = () =>
    Number(
      reviewData?.totalPriceInfo?.totalFareDetail?.fC?.TF ??
        reviewData?.totalPriceInfo?.totalFareDetail?.fC?.NF ??
        0,
    );

  const calculateTotalAmount = () => {
    const legs = [fare, returnFare].filter(Boolean);
    return legs.reduce((n, f) => n + sumAcrossPax(f, 'TF'), 0) + addonsTotal;
  };

  /**
   * What the traveller is charged.
   *
   * `totalPriceInfo.totalFareDetail` is TripJack's own grand total for the
   * session and is authoritative — it already spans every passenger. Deriving
   * it by walking `tripInfos[].fd.ADULT` instead charged for a single adult
   * while TripJack was still paid in full for the whole party.
   */
  const getConfirmedAmount = () => {
    const flightAmount = reviewGrandTotal() || calculateTotalAmount() - addonsTotal;
    // The markup is deliberately excluded from `paymentInfos` below — TripJack
    // validates that against its own session fare and rejects any difference.
    return flightAmount + addonsTotal + Number(markup || 0);
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
      return { ...t, ...ssrForTraveller(addOns, idx, reviewData) };
    });

    // TripJack validates paymentInfos.amount against TF plus every SSR charge.
    const tripjackPaymentAmount = tripjackFare + addonsTotal;

    const payload = {
      bookingId: bookingId,
      paymentInfos: [{ amount: tripjackPaymentAmount }],
      travellerInfo: travellerInfoWithSsr,
      deliveryInfo: { emails: [contact.email], contacts: [fullPhoneNumber] },
      ...(agentNote?.trim() && { remarks: agentNote.trim() }),
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
          <h4 className="booking-card-title">Review</h4>
          
          {error && (
            <div className="alert alert-danger" role="alert">
              {error}
            </div>
          )}
          
          <FlightSegments trip={trip} fare={fare} />

          {returnTrip && <FlightSegments trip={returnTrip} fare={returnFare} className="mt-3" />}

          {/* The portal lays passengers out as a table with their seat and
              per-segment meal and baggage choices beside each name. */}
          <div className="rv-paxblock">
            <h4 className="rv-heading">Passenger Details <span>({travellerInfo.length})</span></h4>

            <div className="rv-table">
              <div className="rv-thead">
                <div>Sr.</div>
                <div>Name, Age &amp; Passport</div>
                <div>Seat Booking</div>
                <div>Meal &amp; Baggage Preference</div>
              </div>

              {travellerInfo.map((t, i) => {
                const seats = segmentChoices(addOns?.seats?.[i]);
                const bags = segmentChoices(addOns?.baggage?.[i]);
                const meals = segmentChoices(addOns?.meals?.[i]);
                return (
                  <div className="rv-trow" key={i}>
                    <div className="rv-td-sr">{i + 1}</div>
                    <div className="rv-td-name">
                      <span className="rv-paxname">
                        {t.ti} {t.fN} {t.lN} ({PAX_INITIAL[t.pt] || 'A'})
                      </span>
                      {t.dob ? <span className="rv-paxdob">{shortDob(t.dob)}</span> : null}
                      {t.pNum ? <span className="rv-paxdob">{t.pNum}</span> : null}
                    </div>
                    <div className="rv-td-seat">
                      {seats.length
                        ? seats.map((s) => <span key={s.route} className="rv-chip">{s.route} : {s.text}</span>)
                        : <span className="rv-chip">NA</span>}
                    </div>
                    <div className="rv-td-ssr">
                      {bags.map((s) => (
                        <div key={`b-${s.route}`} className="rv-ssr-line">
                          <FaSuitcase size={11} /> - <b>{s.route} : </b><span>{s.text}</span>
                        </div>
                      ))}
                      {meals.map((s) => (
                        <div key={`m-${s.route}`} className="rv-ssr-line">
                          <FaUtensils size={11} /> - <b>{s.route} : </b><span>{s.text}</span>
                        </div>
                      ))}
                      {!bags.length && !meals.length ? <span className="rv-none">—</span> : null}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="rv-contact">
            <h4 className="rv-heading">Contact Details</h4>
            <p>email : <span className="rv-contact-value">{contact.email}</span></p>
            <p>mobile : <span className="rv-contact-value">{contact.countryCode} {contact.mobile}</span></p>
          </div>


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
          <div className="rv-footer">
            <div className="rv-footer-left">
              <span className="rv-terms">
                By proceeding, I acknowledge and agree to the{' '}
                <a href="/terms" target="_blank" rel="noreferrer">Terms of Use and Privacy Policy.</a>
              </span>
              <button type="button" className="itin-btn itin-btn-back" onClick={onBack} disabled={loading}>
                « Back
              </button>
            </div>
            <div className="rv-footer-right">
              {/* Blocking is only offered when the fare allows it (conditions.isBA). */}
              {reviewData?.conditions?.isBA && (
                <button type="button" className="itin-btn itin-btn-next" onClick={handleHold} disabled={loading}>
                  {loading ? 'Please wait…' : '⌛ Block'}
                </button>
              )}
              <button type="button" className="itin-btn itin-btn-next" onClick={handleProceedToPayment} disabled={loading}>
                {loading ? 'Processing…' : '» PROCEED TO PAY'}
              </button>
            </div>
          </div>
        </div>
      </div>
      
      <div className="col-lg-4">
        <FareSummary
          fare={fare}
          returnFare={returnFare}
          searchParams={searchParams}
          markup={markup}
          extras={Object.entries(addOnBreakdown(addOns)).map(([label, amount]) => ({ label, amount }))}
        />
      </div>
    </div>
  );
}
