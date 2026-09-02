import { useState, useEffect } from 'react';
import { Clock } from 'lucide-react';

/**
 * Booking-session countdown, as the portal shows along the bottom of checkout.
 *
 * TripJack holds a priced session for `conditions.st` seconds from
 * `conditions.sct` (840s or 1800s in practice). Once it lapses every follow-up
 * call fails with 2503, so the traveller needs to see the clock rather than
 * discover it at payment.
 */
export default function SessionTimer({ reviewData, onExpire }) {
  const startedAt = reviewData?.conditions?.sct;
  const lifetime = Number(reviewData?.conditions?.st || 0);

  const remainingFrom = () => {
    if (!startedAt || !lifetime) return null;
    // `sct` has no timezone marker and is server-local; treat it as local time.
    const started = new Date(startedAt).getTime();
    if (Number.isNaN(started)) return null;
    return Math.max(0, Math.round((started + lifetime * 1000 - Date.now()) / 1000));
  };

  const [left, setLeft] = useState(remainingFrom);

  useEffect(() => {
    setLeft(remainingFrom());
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [startedAt, lifetime]);

  useEffect(() => {
    if (left == null) return undefined;
    if (left <= 0) {
      onExpire?.();
      return undefined;
    }
    const id = setInterval(() => {
      setLeft((prev) => {
        const next = (prev ?? 0) - 1;
        if (next <= 0) onExpire?.();
        return Math.max(0, next);
      });
    }, 1000);
    return () => clearInterval(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [left === null, left <= 0]);

  // Nothing to show when the review response carried no session window.
  if (left == null) return null;

  const mins = Math.floor(left / 60);
  const secs = left % 60;
  const urgent = left <= 120;

  return (
    <div className={`fc-session-bar ${urgent ? 'is-urgent' : ''} ${left === 0 ? 'is-expired' : ''}`}>
      <Clock size={14} />
      {left === 0 ? (
        <span>Your session has expired — please search again to get live fares.</span>
      ) : (
        <span>
          Your Session will expire in {mins} min{mins === 1 ? '' : 's'} :{' '}
          {String(secs).padStart(2, '0')} secs
        </span>
      )}
    </div>
  );
}
