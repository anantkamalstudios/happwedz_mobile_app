import React from "react";
import { FaCheckCircle, FaClock, FaBan, FaHourglassHalf, FaTimesCircle } from "react-icons/fa";

const TONE_ICON = {
  ok: FaCheckCircle,
  warn: FaClock,
  info: FaHourglassHalf,
  stop: FaBan,
  muted: FaTimesCircle,
};

/**
 * One card shell for all five booking types.
 *
 * Every card shares the same frame — type chip top-left, status pill top-right,
 * title, detail rows, price, actions. Only `rows` differs per booking type,
 * which is what lets the grid scan as one list instead of five pasted together.
 */
export default function BookingCard({
  typeIcon,
  typeLabel,
  status,          // { key, label, tone } from normalizeStatus()
  thumb,           // optional image url
  thumbFallback,   // node rendered when no image
  title,
  subtitle,
  rows = [],       // [{ label, value }]
  price,
  priceNote,
  children,        // expanded content, rendered above the actions
  actions,
}) {
  const StatusIcon = TONE_ICON[status?.tone] || FaClock;

  return (
    <article className="hw-bk-card">
      <header className="hw-bk-card-top">
        <span className="hw-bk-chip">
          {typeIcon}
          <span>{typeLabel}</span>
        </span>
        <span className={`hw-bk-status hw-bk-status--${status?.tone || "muted"}`}>
          <StatusIcon size={11} />
          <span>{status?.label}</span>
        </span>
      </header>

      <div className={thumb || thumbFallback ? "hw-bk-head hw-bk-head--media" : "hw-bk-head"}>
        {(thumb || thumbFallback) && (
          <div className="hw-bk-thumb">
            {thumb ? <img src={thumb} alt="" loading="lazy" /> : thumbFallback}
          </div>
        )}
        <div className="hw-bk-head-text">
          <h3 className="hw-bk-title">{title}</h3>
          {subtitle && <p className="hw-bk-subtitle">{subtitle}</p>}
        </div>
      </div>

      {rows.length > 0 && (
        <dl className="hw-bk-rows">
          {rows.map((row) => (
            <div className="hw-bk-row" key={row.label}>
              <dt>{row.label}</dt>
              <dd>{row.value}</dd>
            </div>
          ))}
        </dl>
      )}

      {price != null && (
        <div className="hw-bk-price">
          {price}
          {priceNote && <span className="hw-bk-price-note">{priceNote}</span>}
        </div>
      )}

      {children}

      {actions && <footer className="hw-bk-actions">{actions}</footer>}
    </article>
  );
}
