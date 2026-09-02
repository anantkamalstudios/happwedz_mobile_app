import { useState } from 'react';
import { X } from 'lucide-react';

/**
 * The portal's markup popover: a forward and a return field, with Update for
 * this quote and Update All to apply the same pair to every quote in the list.
 *
 * The return field only appears on a roundtrip — there is no return leg to
 * mark up otherwise, and showing a dead input invites confusion about whether
 * it is being charged.
 */
export default function CabMarkupPopover({ value, isRoundTrip, onApply, onApplyAll, onClose }) {
  const [forward, setForward] = useState(String(value?.forward ?? 0));
  const [back, setBack] = useState(String(value?.back ?? 0));

  const parsed = () => ({
    forward: Number(forward) || 0,
    back: isRoundTrip ? Number(back) || 0 : 0,
  });

  return (
    <div className="cabm">
      <div className="cabm-head">
        <strong>Markup</strong>
        <button type="button" onClick={onClose} aria-label="Close"><X size={15} /></button>
      </div>

      <label className="cabm-field">
        <span>Forward Markup</span>
        <input
          type="number"
          autoFocus
          value={forward}
          onChange={(e) => setForward(e.target.value)}
          onKeyDown={(e) => { if (e.key === 'Enter') onApply(parsed()); }}
        />
      </label>

      {isRoundTrip && (
        <label className="cabm-field">
          <span>Return Markup</span>
          <input
            type="number"
            value={back}
            onChange={(e) => setBack(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter') onApply(parsed()); }}
          />
        </label>
      )}

      <div className="cabm-actions">
        <button type="button" className="cabm-primary" onClick={() => onApply(parsed())}>
          Update
        </button>
        <button type="button" className="cabm-secondary" onClick={() => onApplyAll(parsed())}>
          Update All
        </button>
      </div>
    </div>
  );
}
