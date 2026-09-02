import React from "react";

/**
 * Confirmation shown when a vendor is added to / removed from the wishlist.
 *
 * Render this *inside* the heart <button>. Every heart in the app is already
 * absolutely positioned, so the button is its own containing block and
 * `right: 100%` parks the bubble immediately to the left of the icon without
 * any per-screen offset maths.
 *
 * It stays mounted while hidden so the fade can play in both directions, and
 * is pointer-events: none so it can never swallow a click meant for the heart.
 */
const WishlistBubble = ({ show, added }) => (
  <span
    className={[
      "wishlist-bubble",
      show ? "wishlist-bubble--visible" : "",
      added ? "" : "wishlist-bubble--removed",
    ]
      .filter(Boolean)
      .join(" ")}
    role="status"
    aria-live="polite"
  >
    <span className="wishlist-bubble__icon" aria-hidden="true" />
    {added ? "Added to wishlist" : "Removed from wishlist"}
  </span>
);

export default WishlistBubble;
