import { useState } from 'react';
import { ChevronDown, ChevronUp } from 'lucide-react';
import { WiMoonAltNew } from 'react-icons/wi';
import { TbSunrise, TbSun, TbSunset2 } from 'react-icons/tb';

export default function FlightFiltersSidebar({ filtersMeta, filters, onFilterChange, onClearFilters, searchParams }) {
  const [expandedSections, setExpandedSections] = useState({
    popularFilters: true,
    stops: true,
    returnSpecial: true,
    departureFrom: true,
    arrivalFrom: true,
    departureReturn: true,
    arrivalReturn: true,
    baggage: true,
    airlines: true,
  });

  const toggleSection = (section) => {
    setExpandedSections(prev => ({ ...prev, [section]: !prev[section] }));
  };

  const timeSlots = [
    { value: '00-06', label: '00-06', icon: WiMoonAltNew },
    { value: '06-12', label: '06-12', icon: TbSunrise },
    { value: '12-18', label: '12-18', icon: TbSun },
    { value: '18-24', label: '18-24', icon: TbSunset2 },
  ];

  const fromCity = searchParams?.from || 'Origin';
  const toCity = searchParams?.to || 'Destination';
  const isRoundTrip = searchParams?.tripType === 'round';

  return (
    <div className="tj-filters-sidebar">
      <div className="tj-filters-header">
        <h6 className="tj-filters-title">Filters</h6>
        <button className="tj-reset-btn" onClick={onClearFilters}>
          RESET ALL
        </button>
      </div>

      <div className="tj-filter-section">
        <div className="tj-filter-section-header">
          <span className="tj-filter-section-title">Price</span>
        </div>
        <div className="tj-filter-section-body">
          <div className="tj-price-checkboxes">
            <label className="tj-checkbox-inline">
              <input type="checkbox" />
              <span>Show Incv</span>
            </label>
            <label className="tj-checkbox-inline">
              <input type="checkbox" />
              <span>Show Net</span>
            </label>
            <label className="tj-checkbox-inline">
              <input type="checkbox" />
              <span>Hide Nearby Airports</span>
            </label>
          </div>
        </div>
      </div>

      <div className="tj-filter-section">
        <div className="tj-filter-section-header" onClick={() => toggleSection('popularFilters')}>
          <span className="tj-filter-section-title">Popular Filters</span>
          {expandedSections.popularFilters ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
        </div>
        {expandedSections.popularFilters && (
          <div className="tj-filter-section-body">
            <div className="tj-route-pills">
              <div className={`tj-route-pill ${filters.stops.includes(0) ? 'active' : ''}`}>
                {fromCity}-{toCity}
              </div>
              {isRoundTrip && (
                <div className={`tj-route-pill ${filters.stops.includes(0) ? 'active' : ''}`}>
                  {toCity}-{fromCity}
                </div>
              )}
            </div>
          </div>
        )}
      </div>

      <div className="tj-filter-section">
        <div className="tj-filter-section-header" onClick={() => toggleSection('stops')}>
          <span className="tj-filter-section-title">Stops</span>
          {expandedSections.stops ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
        </div>
        {expandedSections.stops && (
          <div className="tj-filter-section-body">
            <div className="tj-stop-pills">
              {[0, 1, 2, 3].map(stop => {
                const stopData = filtersMeta?.stops?.find(s => s.value === stop);
                return (
                  <div
                    key={stop}
                    className={`tj-stop-pill ${filters.stops.includes(stop) ? 'active' : ''}`}
                    onClick={() => onFilterChange('stops', stop)}
                  >
                    <div className="tj-stop-pill-label">{stop === 3 ? '3+' : stop}</div>
                    {stopData?.min_price && (
                      <div className="tj-stop-pill-price">
                        from ₹{Math.round(stopData.min_price).toLocaleString('en-IN')}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>

      {filtersMeta?.returnSpecial && filtersMeta.returnSpecial.length > 0 && (
        <div className="tj-filter-section">
          <div className="tj-filter-section-header" onClick={() => toggleSection('returnSpecial')}>
            <span className="tj-filter-section-title">Return Special</span>
            {expandedSections.returnSpecial ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
          </div>
          {expandedSections.returnSpecial && (
            <div className="tj-filter-section-body">
              {filtersMeta.returnSpecial.map((special, idx) => (
                <div key={idx} className="tj-return-special-card">
                  <img src={special.logo} alt={special.airline} className="tj-airline-logo-sm" />
                  <span className="tj-return-special-price">
                    ₹{Number(special.price).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      <div className="tj-filter-section">
        <div className="tj-filter-section-header" onClick={() => toggleSection('departureFrom')}>
          <span className="tj-filter-section-title">Departure From {fromCity}</span>
          {expandedSections.departureFrom ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
        </div>
        {expandedSections.departureFrom && (
          <div className="tj-filter-section-body">
            <div className="tj-time-slots">
              {timeSlots.map(slot => {
                const IconComponent = slot.icon;
                return (
                  <div
                    key={slot.value}
                    className={`tj-time-slot ${filters.departure_time.includes(slot.value) ? 'active' : ''}`}
                    onClick={() => onFilterChange('departure_time', slot.value)}
                  >
                    <div className="tj-time-slot-icon">
                      <IconComponent size={18} />
                    </div>
                    <div className="tj-time-slot-label">{slot.label}</div>
                  </div>
                );
              })}
            </div>
            <div className="tj-time-link">Select Specific Timeframe</div>
          </div>
        )}
      </div>

      <div className="tj-filter-section">
        <div className="tj-filter-section-header" onClick={() => toggleSection('arrivalFrom')}>
          <span className="tj-filter-section-title">Arrival From {toCity}</span>
          {expandedSections.arrivalFrom ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
        </div>
        {expandedSections.arrivalFrom && (
          <div className="tj-filter-section-body">
            <div className="tj-time-slots">
              {timeSlots.map(slot => {
                const IconComponent = slot.icon;
                return (
                  <div
                    key={slot.value}
                    className={`tj-time-slot ${filters.arrival_time?.includes(slot.value) ? 'active' : ''}`}
                    onClick={() => onFilterChange('arrival_time', slot.value)}
                  >
                    <div className="tj-time-slot-icon">
                      <IconComponent size={18} />
                    </div>
                    <div className="tj-time-slot-label">{slot.label}</div>
                  </div>
                );
              })}
            </div>
            <div className="tj-time-link">Select Specific Timeframe</div>
          </div>
        )}
      </div>

      {isRoundTrip && (
        <>
          <div className="tj-filter-section">
            <div className="tj-filter-section-header" onClick={() => toggleSection('departureReturn')}>
              <span className="tj-filter-section-title">Departure From {toCity}</span>
              {expandedSections.departureReturn ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
            </div>
            {expandedSections.departureReturn && (
              <div className="tj-filter-section-body">
                <div className="tj-time-slots">
                  {timeSlots.map(slot => {
                    const IconComponent = slot.icon;
                    return (
                      <div
                        key={slot.value}
                        className={`tj-time-slot ${filters.departure_return_time?.includes(slot.value) ? 'active' : ''}`}
                        onClick={() => onFilterChange('departure_return_time', slot.value)}
                      >
                        <div className="tj-time-slot-icon">
                          <IconComponent size={18} />
                        </div>
                        <div className="tj-time-slot-label">{slot.label}</div>
                      </div>
                    );
                  })}
                </div>
                <div className="tj-time-link">Select Specific Timeframe</div>
              </div>
            )}
          </div>

          <div className="tj-filter-section">
            <div className="tj-filter-section-header" onClick={() => toggleSection('arrivalReturn')}>
              <span className="tj-filter-section-title">Arrival From {fromCity}</span>
              {expandedSections.arrivalReturn ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
            </div>
            {expandedSections.arrivalReturn && (
              <div className="tj-filter-section-body">
                <div className="tj-time-slots">
                  {timeSlots.map(slot => {
                    const IconComponent = slot.icon;
                    return (
                      <div
                        key={slot.value}
                        className={`tj-time-slot ${filters.arrival_return_time?.includes(slot.value) ? 'active' : ''}`}
                        onClick={() => onFilterChange('arrival_return_time', slot.value)}
                      >
                        <div className="tj-time-slot-icon">
                          <IconComponent size={18} />
                        </div>
                        <div className="tj-time-slot-label">{slot.label}</div>
                      </div>
                    );
                  })}
                </div>
                <div className="tj-time-link">Select Specific Timeframe</div>
              </div>
            )}
          </div>
        </>
      )}

      {filtersMeta?.baggage && filtersMeta.baggage.length > 0 && (
        <div className="tj-filter-section">
          <div className="tj-filter-section-header" onClick={() => toggleSection('baggage')}>
            <span className="tj-filter-section-title">Baggage</span>
            {expandedSections.baggage ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
          </div>
          {expandedSections.baggage && (
            <div className="tj-filter-section-body">
              {filtersMeta.baggage.map((bag, idx) => (
                <label key={idx} className="tj-checkbox-label">
                  <input
                    type="checkbox"
                    checked={filters.baggage?.includes(bag.value)}
                    onChange={() => onFilterChange('baggage', bag.value)}
                  />
                  <span>{bag.label} ({bag.count})</span>
                </label>
              ))}
            </div>
          )}
        </div>
      )}

      {filtersMeta?.airlines && filtersMeta.airlines.length > 0 && (
        <div className="tj-filter-section">
          <div className="tj-filter-section-header" onClick={() => toggleSection('airlines')}>
            <span className="tj-filter-section-title">Airlines</span>
            {expandedSections.airlines ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
          </div>
          {expandedSections.airlines && (
            <div className="tj-filter-section-body">
              {filtersMeta.airlines.map((airline) => (
                <label key={airline.code} className="tj-airline-checkbox">
                  <input
                    type="checkbox"
                    checked={filters.airlines.includes(airline.code)}
                    onChange={() => onFilterChange('airlines', airline.code)}
                  />
                  <img
                    src={airline.logo || `https://airlines.airhex.com/airlines-logo/${airline.code.toLowerCase()}.png`}
                    alt={airline.name}
                    className="tj-airline-logo-xs"
                    onError={(e) => { e.target.style.display = 'none'; }}
                  />
                  <span className="tj-airline-name">{airline.name}</span>
                  <span className="tj-airline-count">({airline.count})</span>
                  {airline.min_price && (
                    <span className="tj-airline-price">
                      from ₹{Number(airline.min_price).toLocaleString('en-IN')}
                    </span>
                  )}
                </label>
              ))}
            </div>
          )}
        </div>
      )}

      <div className="tj-filter-section">
        <div className="tj-filter-section-header">
          <span className="tj-filter-section-title">Price Range</span>
        </div>
        <div className="tj-filter-section-body">
          <div className="tj-price-range">
            <input
              type="number"
              placeholder="Min"
              value={filters.price_min || ''}
              onChange={(e) => onFilterChange('price_min', e.target.value ? parseInt(e.target.value) : null)}
              className="tj-price-input"
            />
            <span className="tj-price-separator">-</span>
            <input
              type="number"
              placeholder="Max"
              value={filters.price_max || ''}
              onChange={(e) => onFilterChange('price_max', e.target.value ? parseInt(e.target.value) : null)}
              className="tj-price-input"
            />
          </div>
        </div>
      </div>
    </div>
  );
}

