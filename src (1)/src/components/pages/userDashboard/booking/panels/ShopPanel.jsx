import React, { useCallback, useMemo, useState } from "react";
import { FaShoppingBag, FaBoxOpen, FaChevronDown, FaExternalLinkAlt } from "react-icons/fa";
import { normalizeStatus, buildStatusFilters } from "../../../../../utils/bookingStatus";
import BookingCard from "../BookingCard";
import { StatusPills, PanelLoading, PanelEmpty, PanelError } from "./PanelChrome";
import { money, day } from "./format";

const STORE_URL = import.meta.env.VITE_STORE_URL || "https://store.happywedz.com";

// "Rose Gold Garland +2 more" — names the thing the person actually recognises,
// then says how much else is in the box.
const itemSummary = (items = []) => {
  if (!items.length) return "No items";
  const [first, ...rest] = items;
  return rest.length ? `${first.title} +${rest.length} more` : first.title;
};

export default function ShopPanel({ rows, loading, error, onRetry }) {
  const [filter, setFilter] = useState("all");
  const [expanded, setExpanded] = useState(() => new Set());

  const statusOf = useCallback((order) => normalizeStatus(order.status, "shop"), []);

  const filters = useMemo(
    () => buildStatusFilters("shop", rows, (o) => statusOf(o).key),
    [rows, statusOf]
  );

  const visible = useMemo(
    () => (filter === "all" ? rows : rows.filter((o) => statusOf(o).key === filter)),
    [rows, filter, statusOf]
  );

  const toggle = useCallback((id) => {
    setExpanded((prev) => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  }, []);

  if (loading) return <PanelLoading label="Loading your shop orders…" />;

  return (
    <>
      {error && <PanelError message={error} onRetry={onRetry} />}
      <StatusPills filters={filters} active={filter} onChange={setFilter} />

      {visible.length === 0 ? (
        <PanelEmpty
          icon={<FaShoppingBag />}
          title="No Shop Orders Found"
          text={
            filter === "all"
              ? "You haven't ordered anything from the HappyWedz store yet."
              : `No ${filter} orders at the moment.`
          }
          ctaLabel="Browse the Store"
          // A full page load, not navigate(): the store is a separate app on its
          // own domain, not a route in this one.
          onCta={() => window.open(STORE_URL, "_blank", "noopener")}
        />
      ) : (
        <div className="hw-bk-grid">
          {visible.map((order) => {
            const isOpen = expanded.has(order.id);
            const firstImage = order.items?.[0]?.image;

            return (
              <BookingCard
                key={order.id}
                typeIcon={<FaShoppingBag size={10} />}
                typeLabel="Shop"
                status={statusOf(order)}
                thumb={firstImage}
                thumbFallback={!firstImage ? <FaBoxOpen size={22} /> : null}
                title={order.invoice ? `Order #${order.invoice}` : "Shop Order"}
                subtitle={itemSummary(order.items)}
                rows={[
                  {
                    label: "Items",
                    value: `${order.itemCount} item${order.itemCount === 1 ? "" : "s"}`,
                  },
                  { label: "Payment", value: order.paymentMethod || "—" },
                  { label: "Ship to", value: order.shipTo || "—" },
                  { label: "Placed", value: day(order.placedAt) },
                ]}
                price={money(order.total, order.currency)}
                priceNote={
                  order.discount > 0
                    ? `${money(order.discount, order.currency)} off`
                    : null
                }
                actions={
                  <>
                    <button
                      type="button"
                      className="hw-bk-btn"
                      aria-expanded={isOpen}
                      onClick={() => toggle(order.id)}
                    >
                      <FaChevronDown
                        size={12}
                        style={{
                          transform: isOpen ? "rotate(180deg)" : "none",
                          transition: "transform .15s ease",
                        }}
                      />
                      {isOpen ? "Hide Items" : "View Items"}
                    </button>
                    <a
                      className="hw-bk-btn hw-bk-btn--ghost"
                      href={STORE_URL}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      <FaExternalLinkAlt size={11} />
                      Visit Store
                    </a>
                  </>
                }
              >
                {isOpen && (
                  <ul className="hw-bk-items">
                    {order.items.map((item) => (
                      <li className="hw-bk-item" key={item.id || item.title}>
                        {item.image ? (
                          <img src={item.image} alt="" loading="lazy" />
                        ) : (
                          <span className="hw-bk-item-noimg">
                            <FaBoxOpen size={14} />
                          </span>
                        )}
                        <div className="hw-bk-item-text">
                          <span className="hw-bk-item-title">{item.title}</span>
                          <span className="hw-bk-item-meta">
                            {item.quantity} × {money(item.price, order.currency)}
                          </span>
                        </div>
                        <span className="hw-bk-item-total">
                          {money(item.lineTotal, order.currency)}
                        </span>
                      </li>
                    ))}
                  </ul>
                )}
              </BookingCard>
            );
          })}
        </div>
      )}
    </>
  );
}
