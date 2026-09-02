import { useState } from 'react';
import { Search, Clock, Plus, Minus } from 'lucide-react';
import AppliedFilters from './components/AppliedFilters';
import { WiMoonAltNew } from 'react-icons/wi';
import { TbSunrise, TbSun, TbSunset2 } from 'react-icons/tb';
import { formatMinutes, TIME_OPTIONS, parseKey } from '../../../../utils/flightFilters';

const TIME_SLOTS = [
  { value: '00-06', label: '00-06', icon: WiMoonAltNew },
  { value: '06-12', label: '06-12', icon: TbSunrise },
  { value: '12-18', label: '12-18', icon: TbSun },
  { value: '18-24', label: '18-24', icon: TbSunset2 },
];

export default function FlightFiltersSidebar({
  filtersMeta,
  filters,
  onFilterChange,
  onClearFilters,
  onClearSection,
  onRemoveChip,
  searchParams,
  priceView,
  onPriceViewChange,
}) {
  const [expanded, setExpanded] = useState({
    popularFilters: true,
    stops: true,
    departureFrom: true,
    arrivalFrom: true,
    departureReturn: true,
    arrivalReturn: true,
    baggage: true,
    fareType: true,
    flightNumber: true,
    airlines: true,
    cancellationType: false,
    terminal: false,
    airport: false,
    layoverAirport: false,
    duration: false,
    layoverDuration: false,
  });
  const [airlineQuery, setAirlineQuery] = useState('');
  const [timeframeOpen, setTimeframeOpen] = useState({ departure: false, arrival: false });
  // The price range is a draft until Apply is pressed, so dragging a handle or
  // typing a bound does not re-filter the list on every keystroke.
  const [draft, setDraft] = useState({ min: null, max: null });

  const bandMin = filtersMeta?.priceMin ?? 0;
  const bandMax = filtersMeta?.priceMax ?? 0;
  const draftMin = draft.min ?? filters.price_min ?? bandMin;
  const draftMax = draft.max ?? filters.price_max ?? bandMax;
  const pct = (v) => (bandMax > bandMin ? ((v - bandMin) / (bandMax - bandMin)) * 100 : 0);
  const applyPrice = () => {
    onFilterChange('price_min', draftMin > bandMin ? draftMin : null);
    onFilterChange('price_max', draftMax < bandMax ? draftMax : null);
  };

  const toggle = (section) => setExpanded((p) => ({ ...p, [section]: !p[section] }));

  const isActive = (key, value) => {
    const current = filters?.[key];
    return Array.isArray(current) ? current.includes(value) : current === value;
  };

  const hasSelection = (key) => {
    if (key === 'timeframe') {
      return !!(
        filters.departure_from || filters.departure_to ||
        filters.arrival_from || filters.arrival_to
      );
    }
    const v = filters?.[key];
    return Array.isArray(v) ? v.filter(Boolean).length > 0 : v != null && v !== false;
  };

  // Prefer the city name the results carry ('Mumbai'), falling back to the code.
  const fromCity = filtersMeta?.fromCity || searchParams?.from || 'Origin';
  const toCity = filtersMeta?.toCity || searchParams?.to || 'Destination';
  const isRoundTrip = searchParams?.tripType === 'round';

  const Header = ({ id, title, clearKey, alwaysOpen = false }) => (
    <div className="tj-filter-section-header" onClick={() => !alwaysOpen && toggle(id)}>
      <span className="tj-filter-section-title">{title}</span>
      <span className="tj-filter-header-right">
        {clearKey && onClearSection && hasSelection(clearKey) && (
          <button
            type="button"
            className="tj-section-clear"
            onClick={(e) => { e.stopPropagation(); onClearSection(clearKey); }}
          >
            CLEAR
          </button>
        )}
        {!alwaysOpen && (expanded[id] ? <Minus size={15} /> : <Plus size={15} />)}
      </span>
    </div>
  );

  const CheckRow = ({ checked, onChange, label, count, price }) => (
    <label className="tj-checkbox-label">
      <input type="checkbox" checked={!!checked} onChange={onChange} />
      <span className="tj-facet-label">{label}</span>
      {count != null && <span className="tj-facet-count">{count}</span>}
      {price ? (
        <span className="tj-facet-price">
          ₹{Number(price).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
        </span>
      ) : null}
    </label>
  );

  // Grouped blocks matching the portal's DEPARTURE / ARRIVAL layout. Terminals
  // nest under their airport code; airports show code plus full name.
  const Grouped = ({ list, heading, filterKey, showNames }) => {
    if (!list?.length) return null;
    const byCode = new Map();
    for (const item of list) {
      const { code } = parseKey(item.value);
      if (!byCode.has(code)) byCode.set(code, []);
      byCode.get(code).push(item);
    }
    return (
      <>
        <div className="tj-group-heading">{heading}</div>
        <div className="tj-facet-list">
          {[...byCode.entries()].map(([code, items]) => (
            <div key={code} className="tj-group">
              <div className="tj-group-sub">{code}</div>
              {items.map((item) => (
                <CheckRow
                  key={item.value}
                  checked={filters?.[filterKey]?.includes(item.value)}
                  onChange={() => onFilterChange(filterKey, item.value)}
                  label={showNames ? `${item.code} – ${item.name || item.city || item.code}` : item.terminal}
                  count={item.count}
                />
              ))}
            </div>
          ))}
        </div>
      </>
    );
  };

  // "Select Specific Timeframe" — an exact From/To window, shown inline under
  // the button the way the portal does rather than hidden behind a toggle.
  const Timeframe = ({ which }) => {
    const fromKey = `${which}_from`;
    const toKey = `${which}_to`;
    const open = timeframeOpen[which] || !!filters[fromKey] || !!filters[toKey];
    return (
      <>
        <button
          type="button"
          className={`tj-timeframe-btn ${open ? 'is-open' : ''}`}
          onClick={() => setTimeframeOpen((p) => ({ ...p, [which]: !open }))}
        >
          Select Specific Timeframe <Clock size={13} />
        </button>
        {open && (
          <div className="tj-timeframe-row">
            <label>
              <span>From</span>
              <select
                value={filters[fromKey] || ''}
                onChange={(e) => onFilterChange(fromKey, e.target.value || null)}
              >
                <option value="">hh:mm</option>
                {TIME_OPTIONS.map((t) => <option key={t} value={t}>{t}</option>)}
              </select>
            </label>
            <span className="tj-timeframe-dash">—</span>
            <label>
              <span>To</span>
              <select
                value={filters[toKey] || ''}
                onChange={(e) => onFilterChange(toKey, e.target.value || null)}
              >
                <option value="">hh:mm</option>
                {TIME_OPTIONS.map((t) => <option key={t} value={t}>{t}</option>)}
              </select>
            </label>
          </div>
        )}
      </>
    );
  };

  const SlotRow = ({ filterKey }) => (
    <div className="tj-time-slots">
      {TIME_SLOTS.map((slot) => {
        const Icon = slot.icon;
        return (
          <div
            key={slot.value}
            className={`tj-time-slot ${filters[filterKey]?.includes(slot.value) ? 'active' : ''}`}
            onClick={() => onFilterChange(filterKey, slot.value)}
          >
            <div className="tj-time-slot-icon"><Icon size={18} /></div>
            <div className="tj-time-slot-label">{slot.label}</div>
          </div>
        );
      })}
    </div>
  );

  // Free-text flight numbers, add/remove rows like the portal.
  const flightNumberRows = filters.flightNumbers?.length ? filters.flightNumbers : [''];
  const setFlightNumber = (index, value) => {
    const next = [...flightNumberRows];
    next[index] = value;
    onFilterChange('flightNumbers', next);
  };

  return (
    <div className="tj-filters-sidebar">
      <AppliedFilters
        filters={filters}
        filtersMeta={filtersMeta}
        onRemove={onRemoveChip}
        onClearAll={onClearFilters}
      />

      {/* Price leads the rail, as it does on the portal. */}
      <div className="tj-filter-section">
        <Header id="price" title="Price" alwaysOpen />
        <div className="tj-filter-section-body">
          {filtersMeta?.priceMax > 0 && (
            <>
              <div className="tj-dual-range">
                <div className="tj-range-track">
                  <div
                    className="tj-range-fill"
                    style={{
                      left: `${pct(draftMin)}%`,
                      width: `${Math.max(0, pct(draftMax) - pct(draftMin))}%`,
                    }}
                  />
                </div>
                <input
                  type="range" min={filtersMeta.priceMin} max={filtersMeta.priceMax}
                  value={draftMin}
                  onChange={(e) => setDraft((d) => ({
                    ...d, min: Math.min(Number(e.target.value), draftMax),
                  }))}
                  aria-label="Minimum price"
                />
                <input
                  type="range" min={filtersMeta.priceMin} max={filtersMeta.priceMax}
                  value={draftMax}
                  onChange={(e) => setDraft((d) => ({
                    ...d, max: Math.max(Number(e.target.value), draftMin),
                  }))}
                  aria-label="Maximum price"
                />
              </div>
              <div className="tj-price-bounds">
                <span>₹{Number(draftMin).toLocaleString('en-IN')}.00</span>
                <span>₹{Number(draftMax).toLocaleString('en-IN')}.00</span>
              </div>
              <div className="tj-price-range">
                <label className="tj-price-field">
                  <span>Min</span>
                  <div className="tj-price-input-wrap">
                    <span className="tj-price-prefix">₹</span>
                  <input
                    type="number" className="tj-price-input"
                    value={draftMin}
                    onChange={(e) => setDraft((d) => ({ ...d, min: Number(e.target.value) || 0 }))}
                  />
                  </div>
                </label>
                <span className="tj-price-separator">—</span>
                <label className="tj-price-field">
                  <span>Max</span>
                  <div className="tj-price-input-wrap">
                    <span className="tj-price-prefix">₹</span>
                  <input
                    type="number" className="tj-price-input"
                    value={draftMax}
                    onChange={(e) => setDraft((d) => ({ ...d, max: Number(e.target.value) || 0 }))}
                  />
                  </div>
                </label>
                <button type="button" className="tj-price-apply" onClick={applyPrice}>
                  Apply
                </button>
              </div>
            </>
          )}
          <div className="tj-price-checkboxes">
            <label className="tj-checkbox-inline">
              <input type="checkbox" checked={!!priceView?.incv}
                onChange={(e) => onPriceViewChange?.('incv', e.target.checked)} />
              <span>Show Incv</span>
            </label>
            <label className="tj-checkbox-inline">
              <input type="checkbox" checked={!!priceView?.net}
                onChange={(e) => onPriceViewChange?.('net', e.target.checked)} />
              <span>Show Net</span>
            </label>
            <label className="tj-checkbox-inline">
              <input type="checkbox" checked={!!filters.hideNearbyAirports}
                onChange={(e) => onFilterChange('hideNearbyAirports', e.target.checked)} />
              <span>Hide Nearby Airports</span>
            </label>
          </div>
        </div>
      </div>

      <div className="tj-filter-section">
        <Header id="popularFilters" title="Popular Filters" />
        {expanded.popularFilters && (
          <div className="tj-filter-section-body">
            <div className="tj-route-pills">
              {(filtersMeta?.popular || []).map((chip) => (
                <div
                  key={`${chip.key}-${chip.value}`}
                  className={`tj-route-pill ${isActive(chip.key, chip.value) ? 'active' : ''}`}
                  onClick={() => onFilterChange(chip.key, chip.value)}
                >
                  {chip.label}
                </div>
              ))}
              {!filtersMeta?.popular?.length && (
                <div className="tj-route-pill">{fromCity}-{toCity}</div>
              )}
            </div>
          </div>
        )}
      </div>

      <div className="tj-filter-section">
        <Header id="stops" title="Stops" clearKey="stops" />
        {expanded.stops && (
          <div className="tj-filter-section-body">
            <div className="tj-stop-pills">
              {[0, 1, 2, 3].map((stop) => {
                return (
                  <div
                    key={stop}
                    className={`tj-stop-pill ${filters.stops.includes(stop) ? 'active' : ''}`}
                    onClick={() => onFilterChange('stops', stop)}
                  >
                    <div className="tj-stop-pill-label">{stop === 3 ? '3+' : stop}</div>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>

      <div className="tj-filter-section">
        <Header id="departureFrom" title={`Departure From ${fromCity}`} clearKey="departure_time" />
        {expanded.departureFrom && (
          <div className="tj-filter-section-body">
            <SlotRow filterKey="departure_time" />
            <Timeframe which="departure" />
          </div>
        )}
      </div>

      <div className="tj-filter-section">
        <Header id="arrivalFrom" title={`Arrival From ${toCity}`} clearKey="arrival_time" />
        {expanded.arrivalFrom && (
          <div className="tj-filter-section-body">
            <SlotRow filterKey="arrival_time" />
            <Timeframe which="arrival" />
          </div>
        )}
      </div>

      {isRoundTrip && (
        <>
          <div className="tj-filter-section">
            <Header id="departureReturn" title={`Departure From ${toCity}`} clearKey="departure_return_time" />
            {expanded.departureReturn && (
              <div className="tj-filter-section-body">
                <SlotRow filterKey="departure_return_time" />
              </div>
            )}
          </div>
          <div className="tj-filter-section">
            <Header id="arrivalReturn" title={`Arrival From ${fromCity}`} clearKey="arrival_return_time" />
            {expanded.arrivalReturn && (
              <div className="tj-filter-section-body">
                <SlotRow filterKey="arrival_return_time" />
              </div>
            )}
          </div>
        </>
      )}

      {filtersMeta?.baggage?.count > 0 && (
        <div className="tj-filter-section">
          <Header id="baggage" title="Baggage" />
          {expanded.baggage && (
            <div className="tj-filter-section-body">
              <CheckRow
                checked={filters.baggageOnly}
                onChange={(e) => onFilterChange('baggageOnly', e.target.checked)}
                label="Show CheckIn Baggage"
                count={filtersMeta.baggage.count}
              />
            </div>
          )}
        </div>
      )}

      {filtersMeta?.fareTypes?.length > 0 && (
        <div className="tj-filter-section">
          <Header id="fareType" title="Fare Type" clearKey="fareTypes" />
          {expanded.fareType && (
            <div className="tj-filter-section-body">
              {filtersMeta.fareTypes.map((ft) => (
                <CheckRow key={ft.value}
                  checked={filters.fareTypes?.includes(ft.value)}
                  onChange={() => onFilterChange('fareTypes', ft.value)}
                  label={ft.label} count={ft.count} />
              ))}
            </div>
          )}
        </div>
      )}

      <div className="tj-filter-section">
        <Header id="flightNumber" title="Flight Number" clearKey="flightNumbers" />
        {expanded.flightNumber && (
          <div className="tj-filter-section-body">
            {flightNumberRows.map((value, i) => (
              <div key={i} className="tj-flightno-row">
                <input
                  type="text"
                  className="tj-flightno-input"
                  placeholder="Eg. 123 Or 6E-123"
                  value={value}
                  onChange={(e) => setFlightNumber(i, e.target.value)}
                />
                {i === flightNumberRows.length - 1 && (
                  <button type="button" className="tj-flightno-btn"
                    onClick={() => onFilterChange('flightNumbers', [...flightNumberRows, ''])}
                    aria-label="Add flight number">
                    <Plus size={14} />
                  </button>
                )}
                {flightNumberRows.length > 1 && (
                  <button type="button" className="tj-flightno-btn"
                    onClick={() => onFilterChange('flightNumbers', flightNumberRows.filter((_, j) => j !== i))}
                    aria-label="Remove flight number">
                    <Minus size={14} />
                  </button>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {filtersMeta?.airlines?.length > 0 && (
        <div className="tj-filter-section">
          <Header id="airlines" title="Airlines" clearKey="airlines" />
          {expanded.airlines && (
            <div className="tj-filter-section-body">
              <div className="tj-facet-search-wrap">
                <Search size={13} className="tj-facet-search-icon" />
                <input
                  type="text"
                  className="tj-facet-search"
                  placeholder="Search Airline Name"
                  value={airlineQuery}
                  onChange={(e) => setAirlineQuery(e.target.value)}
                />
              </div>
              <div className="tj-facet-list">
                {filtersMeta.airlines
                  .filter((a) => !airlineQuery ||
                    `${a.name} ${a.code}`.toLowerCase().includes(airlineQuery.toLowerCase()))
                  .map((airline) => (
                    <CheckRow key={airline.code}
                      checked={filters.airlines.includes(airline.code)}
                      onChange={() => onFilterChange('airlines', airline.code)}
                      label={airline.name} count={airline.count} price={airline.min_price} />
                  ))}
              </div>
            </div>
          )}
        </div>
      )}

      {filtersMeta?.cancellationTypes?.length > 0 && (
        <div className="tj-filter-section">
          <Header id="cancellationType" title="Cancellation Type" clearKey="cancellationTypes" />
          {expanded.cancellationType && (
            <div className="tj-filter-section-body">
              {filtersMeta.cancellationTypes.map((c) => (
                <CheckRow key={c.value}
                  checked={filters.cancellationTypes?.includes(c.value)}
                  onChange={() => onFilterChange('cancellationTypes', c.value)}
                  label={c.label} count={c.count} />
              ))}
            </div>
          )}
        </div>
      )}

      {(filtersMeta?.departureTerminals?.length > 0 || filtersMeta?.arrivalTerminals?.length > 0) && (
        <div className="tj-filter-section">
          <Header id="terminal" title="Terminal" clearKey="terminals" />
          {expanded.terminal && (
            <div className="tj-filter-section-body">
              <Grouped list={filtersMeta.departureTerminals} heading="DEPARTURE" filterKey="terminals" />
              <Grouped list={filtersMeta.arrivalTerminals} heading="ARRIVAL" filterKey="terminals" />
            </div>
          )}
        </div>
      )}

      {(filtersMeta?.departureAirports?.length > 0 || filtersMeta?.arrivalAirports?.length > 0) && (
        <div className="tj-filter-section">
          <Header id="airport" title="Airport" clearKey="airports" />
          {expanded.airport && (
            <div className="tj-filter-section-body">
              <Grouped list={filtersMeta.departureAirports} heading="DEPARTURE" filterKey="airports" showNames />
              <Grouped list={filtersMeta.arrivalAirports} heading="ARRIVAL" filterKey="airports" showNames />
            </div>
          )}
        </div>
      )}

      {filtersMeta?.layoverAirports?.length > 0 && (
        <div className="tj-filter-section">
          <Header id="layoverAirport" title="Layover Airport" clearKey="layoverAirports" />
          {expanded.layoverAirport && (
            <div className="tj-filter-section-body">
              {filtersMeta.route && <div className="tj-group-sub">{filtersMeta.route}</div>}
              <div className="tj-facet-list">
                {filtersMeta.layoverAirports.map((a) => (
                  <CheckRow key={a.value}
                    checked={filters.layoverAirports?.includes(a.value)}
                    onChange={() => onFilterChange('layoverAirports', a.value)}
                    label={`${a.code} – ${a.name || a.code}`} count={a.count} />
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {filtersMeta?.durationMax > 0 && (
        <div className="tj-filter-section">
          <Header id="duration" title="Duration" clearKey="duration_max" />
          {expanded.duration && (
            <div className="tj-filter-section-body">
              <div className="tj-price-bounds">
                <span>{formatMinutes(filtersMeta.durationMin)}</span>
                <span>Up to {formatMinutes(filters.duration_max ?? filtersMeta.durationMax)}</span>
              </div>
              <input type="range" className="tj-price-slider" step={5}
                min={filtersMeta.durationMin} max={filtersMeta.durationMax}
                value={filters.duration_max ?? filtersMeta.durationMax}
                onChange={(e) => onFilterChange('duration_max', Number(e.target.value))} />
            </div>
          )}
        </div>
      )}

      {filtersMeta?.layoverMax > 0 && (
        <div className="tj-filter-section">
          <Header id="layoverDuration" title="Layover Duration" clearKey="layover_max" />
          {expanded.layoverDuration && (
            <div className="tj-filter-section-body">
              <div className="tj-price-bounds">
                <span>{formatMinutes(filtersMeta.layoverMin)}</span>
                <span>Up to {formatMinutes(filters.layover_max ?? filtersMeta.layoverMax)}</span>
              </div>
              <input type="range" className="tj-price-slider" step={5}
                min={filtersMeta.layoverMin} max={filtersMeta.layoverMax}
                value={filters.layover_max ?? filtersMeta.layoverMax}
                onChange={(e) => onFilterChange('layover_max', Number(e.target.value))} />
            </div>
          )}
        </div>
      )}
    </div>
  );
}
