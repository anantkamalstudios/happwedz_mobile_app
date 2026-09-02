import { useState, useEffect, useRef } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { reviewFlight } from '../../../../services/api/flightApi';
import './tripjack-styles.css';
import BookingSteps from './components/BookingSteps';
import FlightItinerary from './components/FlightItinerary';
import PassengerDetails from './components/PassengerDetails';
import BookingReview from './components/BookingReview';
import BookingConfirmation from './components/BookingConfirmation';
import SessionTimer from './components/SessionTimer';
import SessionExpiredModal from './components/SessionExpiredModal';
import { getBookingDetails } from '../../../../services/api/flightApi';
import { adaptBookingDetails } from './components/bookingDetailsAdapter';

export default function FlightBookingPage() {
  const location = useLocation();
  const navigate = useNavigate();

  const {
    outbound,
    return: returnFlight,
    multiCity,
    searchParams,
    reviewData: initialReviewData,
    bookingId: initialBookingId,
    markup: initialMarkup = 0,
    priceIds: selectedPriceIds,
  } = location.state || {};

  const urlBookingId = new URLSearchParams(location.search).get('bookingId');
  const primaryTrip = outbound || (Array.isArray(multiCity) ? multiCity[0] : null);
  const secondaryTrip = returnFlight || (Array.isArray(multiCity) ? multiCity[1] : null);

  const [step, setStep] = useState(1);
  const [bookingId, setBookingId] = useState(initialBookingId || null);
  const [reviewData, setReviewData] = useState(initialReviewData || null);
  const [travellerInfo, setTravellerInfo] = useState([]);
  const [contact, setContact] = useState({});
  const [gstInfo, setGstInfo] = useState(null);
  const [emergencyContact, setEmergencyContact] = useState(null);
  const [agentNote, setAgentNote] = useState('');
  // Raw form state, kept here so going Back from Review restores the fields
  // rather than remounting an empty form.
  const [paxForm, setPaxForm] = useState(null);
  // Seats, meals and baggage now live together on the passenger step, keyed by
  // passenger AND segment — the old seat step keyed by passenger alone and lost
  // every leg but the last on a connecting itinerary.
  const [addOns, setAddOns] = useState({ seats: {}, meals: {}, baggage: {} });
  const [confirmed, setConfirmed] = useState(null);
  // Set when the page is opened cold on ?bookingId=… and the booking has to be
  // fetched back rather than carried in from the previous step.
  const [rehydrated, setRehydrated] = useState(null);
  const [rehydrating, setRehydrating] = useState(false);
  const latestReview = useRef(null);

  /**
   * The confirmation is reachable by URL, so a refresh — or coming back later to
   * see whether the PNR landed — has to rebuild it from the booking id rather
   * than from router state that no longer exists.
   */
  useEffect(() => {
    if (!urlBookingId || confirmed || primaryTrip) return;
    let cancelled = false;
    setRehydrating(true);
    getBookingDetails(urlBookingId)
      .then((details) => {
        if (cancelled) return;
        const adapted = adaptBookingDetails(details);
        if (adapted) setRehydrated(adapted);
      })
      .catch(() => {})
      .finally(() => !cancelled && setRehydrating(false));
    return () => { cancelled = true; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [location.search]);
  // Editable here as well as on results, and shared by every step — the fare
  // summary follows the traveller from itinerary through to payment.
  const [markup, setMarkup] = useState(Number(initialMarkup) || 0);
  const [sessionExpired, setSessionExpired] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [refreshFailed, setRefreshFailed] = useState(false);
  const [priceChange, setPriceChange] = useState(null);

  /** Grand total TripJack quoted for the current session. */
  const reviewTotal = (data) =>
    Number(
      data?.totalPriceInfo?.totalFareDetail?.fC?.TF ??
        data?.totalPriceInfo?.totalFareDetail?.fC?.NF ??
        0,
    );

  /** Minutes since the session was priced, for the expiry copy. */
  const elapsedMinutes = (() => {
    const started = new Date(reviewData?.conditions?.sct || 0).getTime();
    if (!started || Number.isNaN(started)) return Math.round(Number(reviewData?.conditions?.st || 0) / 60);
    return Math.max(1, Math.floor((Date.now() - started) / 60000));
  })();

  // Re-price the itinerary and restart the clock, as the portal's Continue does.
  const handleSessionContinue = async () => {
    setRefreshing(true);
    const before = reviewTotal(reviewData);
    const ok = await refreshBookingId();
    setRefreshing(false);
    if (!ok) {
      // The priceIds came from the original search and expire with it — there
      // is nothing left to re-price, so the only honest option is a new search.
      setRefreshFailed(true);
      return;
    }
    setSessionExpired(false);
    setStep(1);
    // The whole point of re-pricing is that the fare can move — say so rather
    // than silently swapping the number the traveller already agreed to.
    const after = reviewTotal(latestReview.current);
    if (before && after && Math.abs(after - before) >= 1) {
      setPriceChange({ before, after });
    }
  };

  // Re-do the TripJack review to get a fresh bookingId when the session expires.
  // priceIds are extracted from the stored flight data (totalPriceList[0].id).
  const refreshBookingId = async () => {
    const priceIds = selectedPriceIds?.length
      ? selectedPriceIds
      : [primaryTrip?.totalPriceList?.[0]?.id, secondaryTrip?.totalPriceList?.[0]?.id].filter(Boolean);
    if (!priceIds.length) return false;
    try {
      const response = await reviewFlight(priceIds);
      if (response?.bookingId) {
        setBookingId(response.bookingId);
        setReviewData(response);
        latestReview.current = response;
        return true;
      }
      return false;
    } catch {
      return false;
    }
  };

  useEffect(() => {
    // Only bounce when there is nothing to show and nothing to fetch — a cold
    // open on ?bookingId= has no trip in router state yet still has a booking.
    if ((!primaryTrip || !searchParams) && !urlBookingId) {
      navigate('/honeymoon');
    }
  }, [primaryTrip, searchParams, navigate, urlBookingId]);

  // Opened by URL rather than stepped into: render the booking rebuilt from
  // booking-details, which is also what makes the PNR visible on a later visit.
  if (!primaryTrip || !searchParams) {
    if (rehydrated) {
      return (
        <div className="tj-booking-page">
          <div className="tj-booking-body">
            <div className="container">
              <BookingConfirmation
                bookingData={rehydrated.bookingData}
                trip={rehydrated.trip}
                returnTrip={rehydrated.returnTrip}
                travellerInfo={rehydrated.travellerInfo}
                fare={rehydrated.fare}
                returnFare={rehydrated.returnFare}
                searchParams={{}}
                addOns={{ seats: {}, meals: {}, baggage: {} }}
              />
            </div>
          </div>
        </div>
      );
    }
    if (urlBookingId) {
      return (
        <div className="tj-booking-page">
          <div className="tj-booking-body">
            <div className="container">
              <p className="rehydrate-msg">
                {rehydrating ? 'Loading your booking…' : 'That booking could not be loaded.'}
              </p>
            </div>
          </div>
        </div>
      );
    }
    return null;
  }

  // The review response carries exactly the fare that was chosen, already
  // re-priced — reading totalPriceList[0] off the *search* result showed the
  // cheapest fare on the card no matter which one the traveller picked.
  const reviewTrips = Array.isArray(reviewData?.tripInfos) ? reviewData.tripInfos : [];
  const onwardTrip = reviewTrips[0] || primaryTrip;
  const returnTripInfo = reviewTrips[1] || secondaryTrip;
  const selectedFare = reviewTrips[0]?.totalPriceList?.[0] || primaryTrip.totalPriceList[0];
  const returnFare = reviewTrips[1]?.totalPriceList?.[0] || secondaryTrip?.totalPriceList?.[0];

  return (
    <div className="tj-booking-page">
      {/* Full-bleed band, exactly like TripJack's .apt-section: the grey
          stripe reaches the viewport edges while its contents sit in the
          same .container the itinerary below uses, so step one's circle
          lines up with the left edge of the Flight Details panel. */}
      {!confirmed && (
        <div className="tj-step-band">
          <div className="container">
            <BookingSteps currentStep={step} />
          </div>
        </div>
      )}

      <div className="tj-booking-body">
        <div className="container">
          {!confirmed ? (
            <>
              {priceChange && (
                <div className="price-change-alert">
                  <span>
                    The fare changed from ₹
                    {priceChange.before.toLocaleString('en-IN', { minimumFractionDigits: 2 })} to ₹
                    {priceChange.after.toLocaleString('en-IN', { minimumFractionDigits: 2 })} when the
                    price was refreshed.
                  </span>
                  <button type="button" onClick={() => setPriceChange(null)}>Dismiss</button>
                </div>
              )}
              
              {step === 1 && (
                <FlightItinerary
                  markup={markup}
                  onMarkupChange={setMarkup}
                  trip={onwardTrip}
                  returnTrip={returnTripInfo}
                  fare={selectedFare}
                  returnFare={returnFare}
                  searchParams={searchParams}
                  bookingId={bookingId}
                  onContinue={() => setStep(2)}
                />
              )}

              {step === 2 && (
                <PassengerDetails
                  searchParams={searchParams}
                  reviewData={reviewData}
                  trip={onwardTrip}
                  returnTrip={returnTripInfo}
                  fare={selectedFare}
                  returnFare={returnFare}
                  markup={markup}
                  onMarkupChange={setMarkup}
                  bookingId={bookingId}
                  addOns={addOns}
                  onAddOnsChange={setAddOns}
                  onBack={() => setStep(1)}
                  saved={paxForm}
                  onContinue={(travellers, contactInfo, gst, emergency, note, formState) => {
                    setTravellerInfo(travellers);
                    setContact(contactInfo);
                    setGstInfo(gst);
                    setEmergencyContact(emergency || null);
                    setAgentNote(note || '');
                    setPaxForm(formState || null);
                    setStep(3);
                  }}
                />
              )}

              {step === 3 && (
                <BookingReview
                  markup={markup}
                  onMarkupChange={setMarkup}
                  trip={onwardTrip}
                  returnTrip={returnTripInfo}
                  fare={selectedFare}
                  returnFare={returnFare}
                  searchParams={searchParams}
                  travellerInfo={travellerInfo}
                  contact={contact}
                  gstInfo={gstInfo}
                  emergencyContact={emergencyContact}
                  addOns={addOns}
                  agentNote={agentNote}
                  bookingId={bookingId}
                  reviewData={reviewData}
                  onBack={() => setStep(2)}
                  onPaymentSuccess={(bookingResponse) => {
                    setConfirmed(bookingResponse);
                    const ref =
                      bookingResponse?.order_id ||
                      bookingResponse?.held_booking_id ||
                      bookingResponse?.bookingId;
                    if (ref) {
                      navigate(`/honeymoon/flights/book?bookingId=${encodeURIComponent(ref)}`, {
                        replace: true,
                        state: location.state,
                      });
                    }
                  }}
                />
              )}
            </>
          ) : (
            <BookingConfirmation
              bookingData={confirmed}
              trip={onwardTrip}
              returnTrip={returnTripInfo}
              travellerInfo={travellerInfo}
              fare={selectedFare}
              returnFare={returnFare}
              searchParams={searchParams}
              addOns={addOns}
              markup={markup}
              gstInfo={gstInfo}
              agentNote={agentNote}
              onProceedToPay={() => setConfirmed(null)}
            />
          )}
        </div>
      </div>
      {!confirmed && (
        <SessionTimer reviewData={reviewData} onExpire={() => setSessionExpired(true)} />
      )}
      {sessionExpired && !confirmed && (
        <SessionExpiredModal
          elapsedMinutes={elapsedMinutes}
          busy={refreshing}
          failed={refreshFailed}
          onContinue={handleSessionContinue}
          onBack={() => navigate(-1)}
        />
      )}
    </div>
  );
}
