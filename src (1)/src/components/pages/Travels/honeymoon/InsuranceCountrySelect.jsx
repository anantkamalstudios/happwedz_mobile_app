import { useEffect, useMemo, useRef, useState } from 'react';
import { Search, ChevronDown, Globe } from 'lucide-react';
import {
  INSURANCE_COUNTRIES,
  countryToDestination,
} from '../../../../config/insuranceCountries';

const InsuranceCountrySelect = ({ value, onChange, className = '' }) => {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const wrapRef = useRef(null);

  const selected = useMemo(() => {
    const match = INSURANCE_COUNTRIES.find((c) => c.code === value?.rkey);
    if (match) return match;
    if (value?.rkey && value?.label) {
      return { code: value.rkey, name: value.label, rt: value.rt };
    }
    return INSURANCE_COUNTRIES[0] || null;
  }, [value]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return INSURANCE_COUNTRIES;
    return INSURANCE_COUNTRIES.filter(
      (c) =>
        c.name.toLowerCase().includes(q) || c.code.toLowerCase().includes(q)
    );
  }, [query]);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (wrapRef.current && !wrapRef.current.contains(e.target)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const pickCountry = (country) => {
    onChange(countryToDestination(country));
    setOpen(false);
    setQuery('');
  };

  return (
    <div className={`ins-country-select-wrap ${className}`} ref={wrapRef}>
      <label className="insurance-section-label">
        <Globe size={16} />
        Where are you travelling?
      </label>
      <button
        type="button"
        className="ins-country-select-trigger"
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
        aria-haspopup="listbox"
      >
        <Globe size={18} aria-hidden />
        <span className="ins-country-select-value">
          {selected ? (
            <>
              <strong>{selected.name}</strong>
              <small className="text-muted ms-2">({selected.code})</small>
            </>
          ) : (
            <span className="text-muted">Select country</span>
          )}
        </span>
        <ChevronDown size={18} className={`ins-country-chevron ${open ? 'open' : ''}`} />
      </button>

      {open && (
        <div className="ins-country-dropdown">
          <div className="ins-country-search">
            <Search size={16} />
            <input
              type="text"
              placeholder="Search country…"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              autoFocus
            />
          </div>
          <ul className="ins-country-list" role="listbox">
            {filtered.length === 0 ? (
              <li className="ins-country-empty">No country found</li>
            ) : (
              filtered.map((country) => (
                <li key={country.code}>
                  <button
                    type="button"
                    role="option"
                    aria-selected={value?.rkey === country.code}
                    className={
                      value?.rkey === country.code ? 'active' : ''
                    }
                    onClick={() => pickCountry(country)}
                  >
                    <span>{country.name}</span>
                    <span className="ins-country-code">{country.code}</span>
                  </button>
                </li>
              ))
            )}
          </ul>
        </div>
      )}

    </div>
  );
};

export default InsuranceCountrySelect;
