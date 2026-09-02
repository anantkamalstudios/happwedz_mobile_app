import { useState, useRef, useEffect } from 'react';
import { User, ChevronDown } from 'lucide-react';
import './CabControls.css';

/**
 * The portal's "2 Passengers, 1 Bag" control: a summary that opens a small
 * panel with a stepper for each count and a Done button.
 *
 * Edits land immediately rather than on Done — Done just closes the panel, so
 * dismissing by clicking away keeps what was set instead of silently discarding
 * it.
 */

function Stepper({ label, value, min, max, onChange }) {
  return (
    <div className="cab-pax-row">
      <span>{label}</span>
      <div className="cab-pax-stepper">
        <button
          type="button"
          onClick={() => onChange(Math.max(min, value - 1))}
          disabled={value <= min}
          aria-label={`Fewer ${label}`}
        >
          &minus;
        </button>
        <span className="cab-pax-count">{value}</span>
        <button
          type="button"
          onClick={() => onChange(Math.min(max, value + 1))}
          disabled={value >= max}
          aria-label={`More ${label}`}
        >
          +
        </button>
      </div>
    </div>
  );
}

const plural = (n, word) => `${n} ${word}${n === 1 ? '' : 's'}`;

export default function CabPaxField({
  passengers,
  bags,
  onPassengersChange,
  onBagsChange,
  maxPassengers = 10,
  maxBags = 10,
  variant,
}) {
  const [open, setOpen] = useState(false);
  const boxRef = useRef(null);

  useEffect(() => {
    if (!open) return undefined;
    const close = (e) => {
      if (boxRef.current && !boxRef.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, [open]);

  return (
    <div className={`cab-pax${variant === 'bar' ? ' is-bar' : ''}`} ref={boxRef}>
      <button
        type="button"
        className="cab-pax-trigger"
        onClick={() => setOpen((v) => !v)}
        aria-expanded={open}
      >
        {variant !== 'bar' && <User size={15} className="cab-pax-icon" />}
        <span>
          {variant === 'bar'
            ? `${passengers} Pax, ${plural(bags, 'Bag')}`
            : `${plural(passengers, 'Passenger')}, ${plural(bags, 'Bag')}`}
        </span>
        <ChevronDown size={15} className="cab-pax-caret" />
      </button>

      {open && (
        <div className="cab-pax-pop">
          <Stepper
            label="Passenger"
            value={passengers}
            min={1}
            max={maxPassengers}
            onChange={onPassengersChange}
          />
          <Stepper
            label="Bags"
            value={bags}
            min={0}
            max={maxBags}
            onChange={onBagsChange}
          />
          <button type="button" className="cab-pax-done" onClick={() => setOpen(false)}>
            Done
          </button>
        </div>
      )}
    </div>
  );
}
