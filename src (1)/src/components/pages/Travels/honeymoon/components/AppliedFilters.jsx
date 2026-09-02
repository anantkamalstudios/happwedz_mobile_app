import { X } from 'lucide-react';
import { describeFilters } from '../../../../../utils/flightFilters';

/**
 * "Applied Filters" rail at the top of the sidebar — one removable chip per
 * active selection, so a filter can be dropped without hunting for the section
 * that set it. Renders nothing when no filters are active.
 */
export default function AppliedFilters({ filters, filtersMeta, onRemove, onClearAll }) {
  const chips = describeFilters(filters, filtersMeta);
  if (!chips.length) return null;

  return (
    <div className="tj-filter-section tj-applied">
      <div className="tj-filter-section-header">
        <span className="tj-filter-section-title">Applied Filters</span>
        <span className="tj-filter-header-right">
          <button type="button" className="tj-section-clear" onClick={onClearAll}>
            RESET ALL
          </button>
        </span>
      </div>
      <div className="tj-filter-section-body">
        <div className="tj-applied-chips">
          {chips.map((chip) => (
            <button
              key={chip.id}
              type="button"
              className="tj-applied-chip"
              onClick={() => onRemove(chip)}
              title={`Remove ${chip.label}`}
            >
              <span>{chip.label}</span>
              <X size={12} />
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
