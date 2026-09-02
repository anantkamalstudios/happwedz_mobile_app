import { useState } from 'react';
import { FaUtensils, FaSuitcase, FaChevronDown, FaChevronUp } from 'react-icons/fa';
import './FlightAddons.css';

/**
 * Optional Meal + Baggage (SSR) selection, per passenger per segment.
 * Options come from the review response segments (ssrInfo.MEAL / ssrInfo.BAGGAGE).
 *
 * @param {Array}  segments   [{ id, label, meals:[{code,amount,desc}], baggage:[...] }]
 * @param {Array}  travellers travellerInfo array
 * @param {Object} mealSel    `${paxIdx}_${segId}` -> { code, amount }
 * @param {Object} bagSel     same shape
 */
export default function FlightAddons({ segments, travellers, mealSel, bagSel, setMealSel, setBagSel }) {
  const [open, setOpen] = useState(false);

  const hasAddons = segments.some((s) => s.meals.length || s.baggage.length);
  if (!hasAddons) return null;

  const priceLabel = (amt) => (amt > 0 ? `+₹${Number(amt).toLocaleString('en-IN')}` : 'Free');

  const pick = (setter, options) => (paxIdx, segId, code) => {
    const opt = options(segId).find((o) => o.code === code);
    setter((prev) => {
      const next = { ...prev };
      const k = `${paxIdx}_${segId}`;
      if (code) next[k] = { code, amount: Number(opt?.amount) || 0 };
      else delete next[k];
      return next;
    });
  };
  const mealsOf = (segId) => segments.find((s) => s.id === segId)?.meals || [];
  const bagsOf = (segId) => segments.find((s) => s.id === segId)?.baggage || [];
  const pickMeal = pick(setMealSel, mealsOf);
  const pickBag = pick(setBagSel, bagsOf);

  return (
    <div className="review-section mt-4">
      <button
        type="button"
        className="addons-toggle"
        onClick={() => setOpen((o) => !o)}
      >
        <span><FaUtensils className="me-2" />Add Meals &amp; Baggage <small className="text-muted">(optional)</small></span>
        {open ? <FaChevronUp /> : <FaChevronDown />}
      </button>

      {open && (
        <div className="addons-body mt-3">
          {travellers.map((t, idx) => (
            <div key={idx} className="addon-pax">
              <div className="addon-pax-name">{t.ti} {t.fN} {t.lN}</div>
              {segments.map((seg) => (
                <div key={seg.id} className="addon-seg">
                  <div className="addon-seg-label">{seg.label}</div>
                  <div className="addon-seg-controls">
                    {seg.meals.length > 0 && (
                      <div className="addon-field">
                        <label><FaUtensils className="me-1" />Meal</label>
                        <select
                          value={mealSel[`${idx}_${seg.id}`]?.code || ''}
                          onChange={(e) => pickMeal(idx, seg.id, e.target.value)}
                        >
                          <option value="">No meal</option>
                          {seg.meals.map((m) => (
                            <option key={m.code} value={m.code}>{m.desc} ({priceLabel(m.amount)})</option>
                          ))}
                        </select>
                      </div>
                    )}
                    {seg.baggage.length > 0 && (
                      <div className="addon-field">
                        <label><FaSuitcase className="me-1" />Extra Baggage</label>
                        <select
                          value={bagSel[`${idx}_${seg.id}`]?.code || ''}
                          onChange={(e) => pickBag(idx, seg.id, e.target.value)}
                        >
                          <option value="">No extra baggage</option>
                          {seg.baggage.map((b) => (
                            <option key={b.code} value={b.code}>{b.desc} ({priceLabel(b.amount)})</option>
                          ))}
                        </select>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
