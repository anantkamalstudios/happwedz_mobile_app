import { useEffect, useRef, useState } from "react";
import { Loader2, MapPin } from "lucide-react";
import { searchCabLocations } from "../../../../../services/api/cabApi";
import './CabControls.css';

/** Autocomplete input backed by /tripjack-cabs/search-locations. */
export default function CabLocationField({
  icon,
  label,
  placeholder,
  value,
  selected,
  onChange,
  onSelect,
  variant,
}) {
  const [suggestions, setSuggestions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [open, setOpen] = useState(false);
  const wrapperRef = useRef(null);
  const skipNextFetchRef = useRef(false);
  // The results page seeds these fields from the current search, and the fetch
  // below opens the dropdown on every completed lookup — so both fields popped
  // open on load. Only a value the user actually typed should search.
  const typedRef = useRef(false);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  useEffect(() => {
    if (skipNextFetchRef.current) {
      skipNextFetchRef.current = false;
      return undefined;
    }
    if (!typedRef.current) return undefined;
    const query = value.trim();
    if (query.length < 2) {
      setSuggestions([]);
      return undefined;
    }

    const controller = new AbortController();
    const timer = setTimeout(() => {
      setLoading(true);
      searchCabLocations(query, { signal: controller.signal })
        .then((places) => {
          setSuggestions(places);
          setOpen(true);
        })
        .catch(() => setSuggestions([]))
        .finally(() => setLoading(false));
    }, 350);

    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [value]);

  return (
    <div className={`cab-loc${variant === 'bar' ? ' is-bar' : ''}`} ref={wrapperRef}>
      {variant === 'bar' ? (
        <span className="cab-loc-label">{icon} {label}</span>
      ) : (
        <span className="cab-loc-icon">{icon}</span>
      )}
      <div className="cab-loc-wrap">
        <input
          className="cab-loc-input"
          type="text"
          placeholder={placeholder}
          autoComplete="off"
          value={value}
          onChange={(event) => {
            typedRef.current = true;
            onChange(event.target.value);
            onSelect(null);
          }}
          onFocus={() => suggestions.length && setOpen(true)}
        />
        {value ? (
          <button
            type="button"
            className="cab-loc-clear"
            onClick={() => { onChange(""); onSelect(null); }}
            aria-label={`Clear ${label || "location"}`}
          >
            &times;
          </button>
        ) : null}
        {open && (
          <div className="cab-loc-list">
            {loading ? (
              <div className="cab-loc-item is-note">
                <Loader2 size={14} className="spin" /> Searching…
              </div>
            ) : suggestions.length ? (
              suggestions.map((place) => (
                <button
                  type="button"
                  key={place.id}
                  className="cab-loc-item"
                  onClick={() => {
                    skipNextFetchRef.current = true;
                    onChange(place.displayLabel || place.name);
                    onSelect(place);
                    setOpen(false);
                  }}
                >
                  <MapPin size={14} className="cab-loc-pin" />
                  <span className="cab-loc-text">
                    <strong>{place.name || place.displayLabel}</strong>
                    {(() => {
                      const full = place.displayLabel || '';
                      const head = place.name || '';
                      const rest = head && full.startsWith(head)
                        ? full.slice(head.length).replace(/^[,\s]+/, '')
                        : full === head ? '' : full;
                      return rest ? <small>{rest}</small> : null;
                    })()}
                  </span>
                </button>
              ))
            ) : (
              <div className="cab-loc-item is-note">No locations found</div>
            )}
          </div>
        )}
      </div>
      {!selected && value.trim() ? (
        <span className="cab-loc-hint">Pick a suggestion</span>
      ) : null}
    </div>
  );
}
