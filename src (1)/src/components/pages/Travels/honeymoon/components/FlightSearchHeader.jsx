import { FaPlane, FaCalendarAlt, FaUser, FaEdit } from 'react-icons/fa';
import { IoIosArrowDropdown } from 'react-icons/io';
import { MdFlightTakeoff, MdFlightLand } from 'react-icons/md';
import { AIRLINES } from './PreferredAirline';
import { formatDateWithWeekday } from '../../../../../utils/dateFormat';

// Turn the preferredAirline value (array of codes, or legacy string) into readable names.
const formatPreferredAirlines = (pref) => {
  const codes = Array.isArray(pref) ? pref : pref ? [pref] : [];
  const valid = codes.filter((c) => c && c !== 'All');
  if (!valid.length) return '';
  return valid.map((code) => AIRLINES.find((a) => a.code === code)?.name || code).join(', ');
};

// Defaulted: this renders straight from router state, which is empty on a cold
// load of the results URL, and a missing prop should not take the page down.
export default function FlightSearchHeader({ searchParams = {}, onModify }) {
  const formatDate = (dateStr) => formatDateWithWeekday(dateStr);

  const getTripTypeLabel = () => {
    if (searchParams.tripType === 'round') return 'ROUND TRIP';
    if (searchParams.tripType === 'oneway') return 'ONE WAY';
    if (searchParams.tripType === 'multicity') return 'MULTI CITY';
    return 'MULTI CITY';
  };

  const getRouteDisplay = () => {
    // Multi-city routes
    if (searchParams.routes && searchParams.routes.length > 0) {
      return searchParams.routes.map((route, idx) => (
        <span key={idx}>
          <span className="route-city">{route.fromCode}</span>
          <FaPlane className="route-arrow" size={14} />
          <span className="route-city">{route.toCode}</span>
          {idx < searchParams.routes.length - 1 && <span className="route-separator"> → </span>}
        </span>
      ));
    }
    
    // One-way or Round-trip
    return (
      <>
        <span className="route-city">{searchParams.from}</span>
        <FaPlane className="route-arrow" size={20} />
        <span className="route-city">{searchParams.to}</span>
      </>
    );
  };

  const getDateDisplay = () => {
    // Multi-city dates
    if (searchParams.routes && searchParams.routes.length > 0) {
      return searchParams.routes.map((route, idx) => (
        <div key={idx} className="multicity-date-item">
          <span className="route-label">{route.fromCode} → {route.toCode}:</span>
          <span className="date-value">{formatDate(route.date)}</span>
        </div>
      ));
    }
    
    // One-way or Round-trip
    return null;
  };

  const getPassengerCount = () => {
    const adults = searchParams.adults || 1;
    const children = searchParams.children || 0;
    const infants = searchParams.infants || 0;
    const total = adults + children + infants;
    
    const parts = [];
    if (adults > 0) parts.push(`${adults} Adult${adults > 1 ? 's' : ''}`);
    if (children > 0) parts.push(`${children} Child${children > 1 ? 'ren' : ''}`);
    if (infants > 0) parts.push(`${infants} Infant${infants > 1 ? 's' : ''}`);
    
    return parts.join(', ');
  };

  return (
    <div className="flight-search-header">
      <div className="container">
        <div className="flight-search-header-content">
          {/* Route Section */}
          <div className="header-section route-section">
            <div className="section-content">
              <div className="section-label">{getTripTypeLabel()}</div>
              <div className="section-value">
                {getRouteDisplay()}
              </div>
            </div>
          </div>

          <div className="header-divider"></div>

          {/* Date Section - Multi-city or Single */}
          {searchParams.routes && searchParams.routes.length > 0 ? (
            <div className="header-section date-section multicity-dates">
              <div className="section-icon">
                <FaCalendarAlt size={16} />
              </div>
              <div className="section-content">
                <div className="section-label">Travel Dates</div>
                <div className="section-value multicity-dates-list">
                  {getDateDisplay()}
                </div>
              </div>
            </div>
          ) : (
            <>
              {/* Departure Date Section */}
              <div className="header-section date-section">
                <div className="section-icon">
                  <FaCalendarAlt size={16} />
                </div>
                <div className="section-content">
                  <div className="section-label">Departure Date</div>
                  <div className="section-value">{formatDate(searchParams.departureDate)}</div>
                </div>
              </div>

              {/* Return Date Section (if round trip) */}
              {searchParams.tripType === 'round' && searchParams.returnDate && (
                <>
                  <div className="header-divider"></div>
                  <div className="header-section date-section">
                    <div className="section-icon">
                      <FaCalendarAlt size={16} />
                    </div>
                    <div className="section-content">
                      <div className="section-label">Return Date</div>
                      <div className="section-value">{formatDate(searchParams.returnDate)}</div>
                    </div>
                  </div>
                </>
              )}
            </>
          )}

          <div className="header-divider"></div>

          {/* Passengers Section */}
          <div className="header-section passengers-section">
            <div className="section-icon">
              <FaUser size={16} />
            </div>
            <div className="section-content">
              <div className="section-label">Passengers & Class</div>
              <div className="section-value">
                {getPassengerCount()} | {searchParams.cabinClass?.toUpperCase() || 'ECONOMY'}
              </div>
            </div>
          </div>

          {/* Preferred Airline (if selected) */}
          {formatPreferredAirlines(searchParams.preferredAirline) && (
            <>
              <div className="header-divider"></div>
              <div className="header-section airline-section">
                <div className="section-icon">
                  <MdFlightLand size={18} />
                </div>
                <div className="section-content">
                  <div className="section-label">Preferred Airline</div>
                  <div className="section-value">{formatPreferredAirlines(searchParams.preferredAirline)}</div>
                </div>
              </div>
            </>
          )}

          {/* Modify Search Button */}
          <div className="header-section modify-section">
            <button className="modify-search-btn" onClick={onModify}>
              <IoIosArrowDropdown size={14} className="me-2" />
              MODIFY SEARCH
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
