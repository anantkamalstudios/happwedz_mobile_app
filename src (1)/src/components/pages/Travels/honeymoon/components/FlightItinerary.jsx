import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getFareRule } from '../../../../../services/api/flightApi';
import FareSummary from './FareSummary';
import FareRulesPanel from './FareRulesPanel';
import FlightSegments from './FlightSegments';


export default function FlightItinerary({
  trip,
  returnTrip,
  fare,
  returnFare,
  searchParams,
  markup = 0,
  onMarkupChange,
  bookingId,
  onContinue,
}) {
  const navigate = useNavigate();

  const [rulesOpen, setRulesOpen] = useState(false);
  const [rules, setRules] = useState(null);
  const [rulesLoading, setRulesLoading] = useState(false);

  const toggleFareRules = async () => {
    const next = !rulesOpen;
    setRulesOpen(next);
    if (next && !rules && bookingId) {
      setRulesLoading(true);
      try {
        setRules(await getFareRule(bookingId, 'REVIEW'));
      } catch {
        setRules({ error: true });
      } finally {
        setRulesLoading(false);
      }
    }
  };


  // Net price is what TripJack is paid; amount to pay is what the traveller is
  // charged. The markup is the difference and is never sent to TripJack.

  return (
    <div className="row">
      <div className="col-lg-8">
        <div className="booking-card">
          <div className="itinerary-head">
            <h4 className="booking-card-title mb-0">Flight Details</h4>
            <button type="button" className="back-to-search" onClick={() => navigate(-1)}>
              « Back to Search
            </button>
          </div>
          
          <FlightSegments trip={trip} fare={fare} />

          {returnTrip && <FlightSegments trip={returnTrip} fare={returnFare} className="mt-4" />}

          <div className="fare-rules-block mt-4">
            <button type="button" className="fare-rules-toggle" onClick={toggleFareRules}>
              Fare Rules {rulesOpen ? '−' : '+'}
            </button>
            {rulesOpen && (
              <div className="fare-rules-body mt-2">
                {rulesLoading && <p className="text-muted small mb-0">Loading fare rules…</p>}
                {!rulesLoading && rules?.error && (
                  <p className="text-muted small mb-0">Fare rules unavailable. Please contact support.</p>
                )}
                {!rulesLoading && rules && !rules.error && (
                  <FareRulesPanel data={rules} />
                )}
              </div>
            )}
          </div>

          <div className="itinerary-actions">
            <button type="button" className="itin-btn itin-btn-next" onClick={() => navigate(-1)}>
              « Back
            </button>
            <button type="button" className="itin-btn itin-btn-next" onClick={onContinue}>
              ADD PASSENGERS »
            </button>
          </div>
        </div>
      </div>
      
      <div className="col-lg-4">
        <FareSummary
          fare={fare}
          returnFare={returnFare}
          searchParams={searchParams}
          markup={markup}
          onMarkupChange={onMarkupChange}
        />
      </div>
    </div>
  );
}
