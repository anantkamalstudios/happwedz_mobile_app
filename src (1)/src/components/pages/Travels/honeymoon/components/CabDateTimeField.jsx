import { useState, useRef, useEffect } from 'react';
import { Calendar, ChevronLeft, ChevronRight, XCircle } from 'lucide-react';
import './CabControls.css';

/**
 * The portal's combined date-and-time control: one field reading
 * "Sat, 29 Aug'26, 12:00 AM" that opens a month grid, and — the moment a day is
 * picked — swaps straight to the time step rather than making the traveller
 * open a second field. Cancel backs out without committing either half.
 */

const WEEK = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December'];
const SHORT = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

const iso = (d) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

const startOfDay = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());

/** "Sat, 29 Aug'26, 12:00 AM" */
const formatDateTime = (dateIso, time24) => {
  if (!dateIso) return '';
  const d = new Date(`${dateIso}T00:00:00`);
  if (Number.isNaN(d.getTime())) return '';
  const stamp = `${DAYS[d.getDay()]}, ${d.getDate()} ${SHORT[d.getMonth()]}'${String(d.getFullYear()).slice(2)}`;
  if (!time24) return stamp;
  const [h, m] = time24.split(':').map(Number);
  const suffix = h >= 12 ? 'PM' : 'AM';
  return `${stamp}, ${String(h % 12 || 12).padStart(2, '0')}:${String(m).padStart(2, '0')} ${suffix}`;
};

export default function CabDateTimeField({
  label,
  placeholder = 'Select date and time',
  date,
  time,
  minDate,
  onApply,
  onClear,
  clearable = false,
  validate,
  variant,
}) {
  const [open, setOpen] = useState(false);
  const [step, setStep] = useState('date'); // date | time
  const [draftDate, setDraftDate] = useState(date || '');
  const [hour, setHour] = useState('12');
  const [minute, setMinute] = useState('00');
  const [meridiem, setMeridiem] = useState('AM');
  const [cursor, setCursor] = useState(() => {
    const base = date ? new Date(`${date}T00:00:00`) : new Date();
    return new Date(base.getFullYear(), base.getMonth(), 1);
  });
  const boxRef = useRef(null);

  useEffect(() => {
    if (!open) return undefined;
    const close = (e) => {
      if (boxRef.current && !boxRef.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, [open]);

  // Seed the time step from whatever is already committed, so reopening the
  // field does not silently reset a chosen time to midnight.
  const openPicker = () => {
    setDraftDate(date || '');
    if (time) {
      const [h, m] = time.split(':').map(Number);
      setHour(String(h % 12 || 12).padStart(2, '0'));
      setMinute(String(m).padStart(2, '0'));
      setMeridiem(h >= 12 ? 'PM' : 'AM');
    }
    setStep('date');
    setOpen(true);
  };

  const min = minDate ? startOfDay(new Date(`${minDate}T00:00:00`)) : startOfDay(new Date());

  const grid = (() => {
    const first = new Date(cursor.getFullYear(), cursor.getMonth(), 1);
    const days = new Date(cursor.getFullYear(), cursor.getMonth() + 1, 0).getDate();
    const cells = Array.from({ length: first.getDay() }, () => null);
    for (let d = 1; d <= days; d += 1) {
      cells.push(new Date(cursor.getFullYear(), cursor.getMonth(), d));
    }
    return cells;
  })();

  const pickDay = (d) => {
    setDraftDate(iso(d));
    setStep('time'); // the portal chains straight into the time step
  };

  /** The 24h time currently dialled in on the time step. */
  const draftTime = (() => {
    const h = (Number(hour) || 12) % 12 + (meridiem === 'PM' ? 12 : 0);
    return `${String(h).padStart(2, '0')}:${String(Number(minute) || 0).padStart(2, '0')}`;
  })();

  // Recomputed on every render, so the message appears and clears as the clock
  // is changed rather than only when Apply is pressed.
  const invalid = validate && draftDate ? validate(draftDate, draftTime) : null;

  const apply = () => {
    if (invalid) return;
    onApply(draftDate, draftTime);
    setOpen(false);
  };

  const shownValue = formatDateTime(date, time);

  /** "30 Aug 2026" and "09:00 AM" as their own segments, as the bar shows them.
   *  The year is written in full here — the abbreviated "'26" the trigger uses
   *  saves nothing once the label sits on its own line. */
  const datePart = (() => {
    if (!date) return '';
    const d = new Date(`${date}T00:00:00`);
    if (Number.isNaN(d.getTime())) return '';
    return `${d.getDate()} ${SHORT[d.getMonth()]} ${d.getFullYear()}`;
  })();
  const timePart = date && time ? formatDateTime(date, time).split(', ').pop() : '';

  return (
    <div className={`cab-dt${variant === 'bar' ? ' is-bar' : ''}`} ref={boxRef}>
      {variant === 'bar' ? (
        <div className="cab-dt-bar">
          <span className="cab-dt-bar-label">
            <Calendar size={12} /> {label}
          </span>
          <div className="cab-dt-bar-row">
            <span className="cab-dt-seg">
              <button type="button" onClick={() => { openPicker(); setStep('date'); }}>
                <span className={datePart ? '' : 'is-placeholder'}>{datePart || 'DD-MM-YYYY'}</span>
              </button>
              {datePart && (
                <button
                  type="button"
                  className="cab-dt-seg-x"
                  onClick={onClear}
                  aria-label={`Clear ${label || 'date'}`}
                >
                  &times;
                </button>
              )}
            </span>

            <span className="cab-dt-seg">
              <button type="button" onClick={() => { openPicker(); if (date) setStep('time'); }}>
                <span className={timePart ? '' : 'is-placeholder'}>{timePart || '00:00 PM'}</span>
              </button>
              {timePart && (
                <button
                  type="button"
                  className="cab-dt-seg-x"
                  onClick={onClear}
                  aria-label={`Clear ${label || 'time'}`}
                >
                  &times;
                </button>
              )}
            </span>
          </div>
        </div>
      ) : (
        <>
          <button type="button" className="cab-dt-trigger" onClick={openPicker}>
            <Calendar size={15} className="cab-dt-icon" />
            <span className="cab-dt-text">
              {label && <small>{label}</small>}
              <span className={shownValue ? '' : 'is-placeholder'}>{shownValue || placeholder}</span>
            </span>
          </button>

          {clearable && date && (
            <button type="button" className="cab-dt-clear" onClick={onClear} aria-label="Clear return">
              &times;
            </button>
          )}
        </>
      )}

      {open && (
        <div className="cab-dt-pop">
          {step === 'date' ? (
            <>
              <div className="cab-dt-nav">
                <button
                  type="button"
                  onClick={() => setCursor(new Date(cursor.getFullYear(), cursor.getMonth() - 1, 1))}
                  aria-label="Previous month"
                >
                  <ChevronLeft size={16} />
                </button>
                <strong>{MONTHS[cursor.getMonth()]} {cursor.getFullYear()}</strong>
                <button
                  type="button"
                  onClick={() => setCursor(new Date(cursor.getFullYear(), cursor.getMonth() + 1, 1))}
                  aria-label="Next month"
                >
                  <ChevronRight size={16} />
                </button>
              </div>

              <div className="cab-dt-grid">
                {WEEK.map((w) => <span key={w} className="cab-dt-wd">{w}</span>)}
                {grid.map((d, i) => {
                  if (!d) return <span key={`pad-${i}`} />;
                  const disabled = d < min;
                  const isToday = iso(d) === iso(new Date());
                  const isPicked = iso(d) === draftDate;
                  return (
                    <button
                      key={iso(d)}
                      type="button"
                      disabled={disabled}
                      onClick={() => pickDay(d)}
                      className={[
                        'cab-dt-day',
                        isPicked ? 'is-picked' : '',
                        !isPicked && isToday ? 'is-today' : '',
                      ].filter(Boolean).join(' ')}
                    >
                      {d.getDate()}
                    </button>
                  );
                })}
              </div>
            </>
          ) : (
            <div className="cab-dt-time">
              <div className="cab-dt-time-head">Select Date and Time</div>
              <div className="cab-dt-chosen">
                <span><Calendar size={13} /> {formatDateTime(draftDate)}</span>
                <button type="button" onClick={() => setStep('date')}>Edit date</button>
              </div>

              <div className="cab-dt-clock">
                <input
                  type="number"
                  min="1"
                  max="12"
                  value={hour}
                  onChange={(e) => setHour(e.target.value)}
                  aria-label="Hour"
                />
                <span>:</span>
                <input
                  type="number"
                  min="0"
                  max="59"
                  value={minute}
                  onChange={(e) => setMinute(e.target.value)}
                  aria-label="Minute"
                />
                <div className="cab-dt-mer">
                  {['AM', 'PM'].map((m) => (
                    <button
                      key={m}
                      type="button"
                      className={meridiem === m ? 'is-on' : ''}
                      onClick={() => setMeridiem(m)}
                    >
                      {m}
                    </button>
                  ))}
                </div>
              </div>

              {invalid && (
                <p className="cab-dt-error" role="alert">
                  <XCircle size={14} />
                  <span>{invalid}</span>
                </p>
              )}

              <div className="cab-dt-actions">
                <button type="button" className="cab-dt-cancel" onClick={() => setOpen(false)}>
                  Cancel
                </button>
                <button
                  type="button"
                  className="cab-dt-apply"
                  onClick={apply}
                  disabled={Boolean(invalid)}
                >
                  Apply
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
