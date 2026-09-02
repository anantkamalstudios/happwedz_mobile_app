import React from "react";

/** Status filter row. Built by buildStatusFilters() so zero-count pills stay put. */
export function StatusPills({ filters, active, onChange }) {
  if (!filters.length) return null;

  return (
    <div className="hw-bk-pills" role="tablist" aria-label="Filter by status">
      {filters.map((filter) => (
        <button
          key={filter.key}
          type="button"
          role="tab"
          aria-selected={active === filter.key}
          className={`hw-bk-pill ${active === filter.key ? "active" : ""}`}
          onClick={() => onChange(filter.key)}
        >
          {filter.label} ({filter.count})
        </button>
      ))}
    </div>
  );
}

/**
 * Inline spinner. Deliberately not the shared <Loader />, which is a
 * position: fixed full-screen overlay — switching sub-tabs would flash the
 * whole page white.
 */
export function PanelLoading({ label = "Loading your bookings…" }) {
  return (
    <div className="hw-bk-loading">
      <div className="hw-bk-spinner" aria-hidden="true" />
      <span>{label}</span>
    </div>
  );
}

export function PanelEmpty({ icon, title, text, ctaLabel, onCta }) {
  return (
    <div className="hw-bk-empty">
      <div className="hw-bk-empty-icon">{icon}</div>
      <h3>{title}</h3>
      <p>{text}</p>
      {ctaLabel && onCta && (
        <button type="button" className="hw-bk-empty-cta" onClick={onCta}>
          {ctaLabel}
        </button>
      )}
    </div>
  );
}

export function PanelError({ message, onRetry }) {
  return (
    <div className="hw-bk-error">
      <span>{message}</span>
      {onRetry && (
        <button type="button" onClick={onRetry}>
          Try again
        </button>
      )}
    </div>
  );
}
