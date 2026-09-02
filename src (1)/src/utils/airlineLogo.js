/**
 * Airline logo URL.
 *
 * Served from TripJack's own CDN — the same source their portal uses
 * (`//static.tripjack.com/img/airlineLogo/v1/QP.png`), so it covers every
 * carrier their search can return. The code must be UPPERCASE.
 *
 * This replaced two airhex hosts that had both stopped working:
 * `airlines.airhex.com` no longer resolves at all, and
 * `airhex.com/images/airline-logos/alt/` answers 403.
 */
export const airlineLogo = (code) =>
  `https://static.tripjack.com/img/airlineLogo/v1/${String(code || '').toUpperCase()}.png`;

/** Hide a logo that fails to load rather than showing a broken-image glyph. */
export const hideBrokenLogo = (e) => {
  e.target.style.visibility = 'hidden';
};

export default airlineLogo;
