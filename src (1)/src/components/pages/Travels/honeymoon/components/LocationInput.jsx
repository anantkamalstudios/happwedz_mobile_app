import { useRef, useEffect } from "react";
import { Loader2 } from "lucide-react";

export default function LocationInput({
  label,
  icon: Icon,
  placeholder,
  value,
  onChange,
  onSelect,
  suggestions,
  loading,
  showSuggestions,
  onFocus,
  onBlur,
}) {
  const inputRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (inputRef.current && !inputRef.current.contains(event.target)) {
        if (onBlur) onBlur();
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [onBlur]);

  return (
    <div className="field-box" ref={inputRef}>
      <div className="field-label">
        <span className="field-label-content">
          <Icon size={14} /> {label}
        </span>
      </div>
      <div className="field-wrapper">
        <input
          className="field-input"
          placeholder={placeholder}
          value={value}
          onChange={onChange}
          onFocus={onFocus}
        />
        {loading && (
          <div className="airport-suggestions">
            <div className="suggestion-item suggestion-loading">
              <Loader2 size={16} className="spin" />
              Searching locations...
            </div>
          </div>
        )}
        {!loading && showSuggestions && suggestions.length > 0 && (
          <div className="airport-suggestions">
            {suggestions.map((location, index) => (
              <div
                key={location.id || index}
                className="suggestion-item"
                onClick={() => onSelect(location)}
              >
                <div className="suggestion-main">
                  <span className="suggestion-iata">{location.iata}</span>
                  <span className="suggestion-name">{location.name}</span>
                </div>
                <div className="suggestion-city">
                  {location.city && `${location.city}, `}
                  {location.country}
                  {location.countryCode && ` (${location.countryCode})`}
                </div>
              </div>
            ))}
          </div>
        )}
        {!loading &&
          showSuggestions &&
          value.length >= 2 &&
          suggestions.length === 0 && (
            <div className="airport-suggestions">
              <div className="suggestion-item suggestion-empty">
                No locations found
              </div>
            </div>
          )}
      </div>
      <div className="field-sub">All airports & cities</div>
    </div>
  );
}
