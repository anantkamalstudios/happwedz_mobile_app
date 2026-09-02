/**
 * Shown when the TripJack booking session lapses.
 *
 * The priced session is only held for `conditions.st` seconds. Past that every
 * downstream call fails with 2503, so rather than let the traveller discover
 * that at payment, this offers the same choice the portal does: re-price and
 * carry on, or go back and pick again.
 */
export default function SessionExpiredModal({ elapsedMinutes, busy, failed, onContinue, onBack }) {
  return (
    <div className="session-modal-backdrop" role="dialog" aria-modal="true">
      <div className="session-modal">
        <h5 className="session-modal-title">CONFIRM TO PROCEED</h5>
        {failed ? (
          <p className="session-modal-body">
            This fare is no longer available at the quoted price. Search again to see live
            fares for your dates.
          </p>
        ) : (
          <p className="session-modal-body">
            It has been over <strong>{elapsedMinutes} minutes</strong> since the price was last
            updated. Click on Continue to view the latest price and availability.
          </p>
        )}
        <div className="session-modal-actions">
          <button
            type="button"
            className={`session-btn ${failed ? 'session-btn-go' : 'session-btn-back'}`}
            onClick={onBack}
            disabled={busy}
          >
            BACK TO FLIGHT LIST
          </button>
          {!failed && (
            <button type="button" className="session-btn session-btn-go" onClick={onContinue} disabled={busy}>
              {busy ? 'CHECKING…' : 'CONTINUE'}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
