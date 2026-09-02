import { useState, useMemo, useRef, useEffect } from 'react';

/**
 * The portal's `.historybox__wrapper`: a type-ahead over travellers this
 * account has booked for before, so a repeat passenger can be filled in
 * without retyping their name and document details.
 *
 * The list is derived from past bookings, so the panel's "Add this to My
 * Travellers List" checkbox works as a suppression switch — unticking it
 * keeps that person out of the picker on later bookings. That preference is
 * per browser; it is a convenience, not booking data.
 */
export default function TravellerPicker({ travellers = [], paxType, onPick }) {
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(-1);
  const boxRef = useRef(null);

  // Only offer people of the right kind: an infant's row cannot be filled
  // from an adult's saved details.
  const pool = useMemo(
    () => travellers.filter((t) => !paxType || t.pt === paxType),
    [travellers, paxType],
  );

  const matches = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return pool.slice(0, 8);
    return pool
      .filter((t) => `${t.fN} ${t.lN}`.toLowerCase().includes(q))
      .slice(0, 8);
  }, [pool, query]);

  useEffect(() => {
    const onDocClick = (e) => {
      if (boxRef.current && !boxRef.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener('mousedown', onDocClick);
    return () => document.removeEventListener('mousedown', onDocClick);
  }, []);

  const choose = (t) => {
    onPick(t);
    setQuery(`${t.fN} ${t.lN}`);
    setOpen(false);
    setActive(-1);
  };

  const onKeyDown = (e) => {
    if (!open) return;
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setActive((i) => Math.min(i + 1, matches.length - 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setActive((i) => Math.max(i - 1, 0));
    } else if (e.key === 'Enter' && active >= 0 && matches[active]) {
      e.preventDefault();
      choose(matches[active]);
    } else if (e.key === 'Escape') {
      setOpen(false);
    }
  };

  return (
    <div className="historybox__wrapper" ref={boxRef}>
      <div className="historybox">
        <label className="historybox__label">Traveller List</label>
        <div className="historybox__input">
          <span className="historybox__icon" aria-hidden="true" />
          <input
            type="text"
            value={query}
            placeholder="Search from Travellers List"
            onChange={(e) => { setQuery(e.target.value); setOpen(true); setActive(-1); }}
            onFocus={() => setOpen(true)}
            onKeyDown={onKeyDown}
            aria-expanded={open}
            role="combobox"
            aria-controls="traveller-suggestions"
          />
        </div>

        {open && !matches.length && (
          <div className="historybox__empty">
            No saved travellers yet — everyone you book for will appear here.
          </div>
        )}

        {open && matches.length > 0 && (
          <ul className="historybox__list" id="traveller-suggestions" role="listbox">
            {matches.map((t, i) => (
              <li key={t.key} role="option" aria-selected={i === active}>
                <button
                  type="button"
                  className={i === active ? 'is-active' : ''}
                  onMouseEnter={() => setActive(i)}
                  onClick={() => choose(t)}
                >
                  <span className="historybox__name">{t.ti} {t.fN} {t.lN}</span>
                  {t.dob ? <span className="historybox__meta">{t.dob}</span> : null}
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
