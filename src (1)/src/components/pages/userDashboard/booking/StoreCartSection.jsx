import React from "react";
import { useSelector } from "react-redux";
import { Card, Badge } from "react-bootstrap";
import { FaShoppingBag, FaExternalLinkAlt } from "react-icons/fa";
import useStoreCart from "../../../../hooks/useStoreCart";

/**
 * Shows what the user currently has in their HappyWedz Store basket.
 *
 * Kept visually separate from the quotations below it: a store basket and a
 * vendor booking are different things, and merging them into one list would
 * make the counts in the filter tabs mean two things at once.
 *
 * The cart is read from the store's own localStorage via useStoreCart, so it is
 * per-browser. "Nothing here" on a phone does not mean the basket is empty on
 * the laptop — the copy below says so rather than implying the basket is empty.
 *
 * Being per-browser also means the basket is not necessarily this user's: a
 * shared laptop can hold a basket someone else filled. When the store reports
 * who is logged in there, a mismatch against the dashboard account hides the
 * basket entirely. Set REQUIRE_MATCHING_ACCOUNT to hide anonymous baskets too —
 * safer, at the cost of showing nothing for the common case where the user
 * shopped without signing in to the store.
 */

const REQUIRE_MATCHING_ACCOUNT = false;

const money = (n) =>
  `₹${Number(n || 0).toLocaleString("en-IN", { minimumFractionDigits: 2 })}`;

const StoreCartSection = () => {
  const { items, totalItems, cartTotal, email, status, storeOrigin } =
    useStoreCart();
  const { user } = useSelector((state) => state.auth);

  const dashboardEmail = user?.email ? String(user.email).trim().toLowerCase() : null;
  // email is null when nobody is signed in to the store, which is not a
  // mismatch — just an unattributed basket.
  const belongsToSomeoneElse = !!email && !!dashboardEmail && email !== dashboardEmail;
  const unattributed = !email;

  // While the bridge is still handshaking there is nothing useful to show, and
  // a spinner above the bookings list would just look like the page is stuck.
  if (status === "loading") return null;

  // Bridge missing or unreachable. Staying silent is right: the store basket is
  // supplementary here, and an error box about an iframe helps nobody.
  if (status === "unavailable") return null;

  // Signed in to the store as somebody else — never show one customer's basket
  // to another. Shared computers make this a real case, not a theoretical one.
  if (belongsToSomeoneElse) return null;
  if (REQUIRE_MATCHING_ACCOUNT && unattributed) return null;

  const isEmpty = !items.length;

  return (
    <Card className="mb-4 border-0 shadow-sm">
      <Card.Body>
        <div className="d-flex align-items-center justify-content-between flex-wrap gap-2 mb-3">
          <div className="d-flex align-items-center gap-2">
            <FaShoppingBag style={{ color: "#c2185b" }} />
            <span className="fw-bold fs-16">In your Store basket</span>
            {!isEmpty && (
              <Badge bg="danger" pill>
                {totalItems}
              </Badge>
            )}
          </div>
          <a
            href={storeOrigin}
            target="_blank"
            rel="noopener noreferrer"
            className="text-decoration-none fs-14 d-flex align-items-center gap-1"
            style={{ color: "#c2185b" }}
          >
            {isEmpty ? "Visit the store" : "Go to checkout"}
            <FaExternalLinkAlt size={11} />
          </a>
        </div>

        {isEmpty ? (
          <p className="fs-14 text-muted mb-0">
            Nothing in your basket on this device. Items you add on the store are
            saved in the browser you added them from, so a basket started on
            another phone or laptop will not show here.
          </p>
        ) : (
          <>
            <div className="d-flex flex-column gap-2">
              {items.map((item) => (
                <div
                  key={item.id}
                  className="d-flex align-items-center gap-3 p-2 rounded"
                  style={{ background: "#fff5f9" }}
                >
                  {item.image ? (
                    <img
                      src={item.image}
                      alt=""
                      width="48"
                      height="48"
                      loading="lazy"
                      decoding="async"
                      style={{
                        objectFit: "cover",
                        borderRadius: 8,
                        flexShrink: 0,
                      }}
                    />
                  ) : (
                    <div
                      style={{
                        width: 48,
                        height: 48,
                        borderRadius: 8,
                        background: "#f3e6ee",
                        flexShrink: 0,
                      }}
                    />
                  )}
                  <div className="flex-grow-1 min-width-0">
                    <div className="fs-14 fw-semibold text-truncate">
                      {item.title || item.name || "Item"}
                    </div>
                    <div className="fs-14 text-muted">
                      Qty {item.quantity} · {money(item.price)}
                    </div>
                  </div>
                  <div className="fs-14 fw-semibold text-nowrap">
                    {money(item.itemTotal ?? item.price * item.quantity)}
                  </div>
                </div>
              ))}
            </div>

            <div className="d-flex justify-content-between align-items-center border-top mt-3 pt-3">
              <span className="fs-14 text-muted">Basket total</span>
              <span className="fw-bold fs-16" style={{ color: "#c2185b" }}>
                {money(cartTotal)}
              </span>
            </div>
          </>
        )}
      </Card.Body>
    </Card>
  );
};

export default StoreCartSection;
