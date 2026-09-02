import { useEffect, useRef, useState } from "react";

/**
 * Reads the shopping cart that lives on the store subdomain.
 *
 * The store (store.happywedz.com) keeps its cart entirely client-side, in
 * localStorage under the "react-use-cart" key — it is never sent to any server,
 * so there is no API to call for it. localStorage is scoped per origin, and the
 * store is a different origin from this app, so the only way to read it is to
 * run code on the store's origin: a hidden iframe pointing at a small bridge
 * page there, which reads its own localStorage and posts the value back.
 *
 * This works because both hosts sit under the same registrable domain
 * (happywedz.com). Browser storage partitioning applies to *cross-site* embeds
 * and partitions by that domain, so a same-site subdomain iframe still sees the
 * real, unpartitioned localStorage.
 *
 * Consequences worth knowing at the call site:
 *   - Same browser only. The cart is local to the device that added the items,
 *     so this legitimately returns empty on a different phone or laptop.
 *   - Read-only. Editing the cart from here would need the bridge to accept
 *     writes and would introduce two-way sync to get wrong.
 *
 * The bridge also reports the email of the customer logged in to the store (or
 * null when nobody is), so the caller can refuse to show a basket that belongs
 * to a different person — a browser is shared more often than an account is.
 *
 * Returns { items, totalItems, cartTotal, email, status }, where status is one
 * of "loading" | "ready" | "unavailable".
 */

const STORE_ORIGIN =
  import.meta.env.VITE_STORE_ORIGIN || "https://store.happywedz.com";

const BRIDGE_URL = `${STORE_ORIGIN}/cart-bridge.html`;

/**
 * Off unless cart-bridge.html is actually deployed on the store.
 *
 * The bridge has to be served from the store's own origin, and that codebase is
 * not ours to deploy to. Until someone with access puts the file there, every
 * mount would fire an iframe request at a 404 and then sit through the timeout
 * for nothing. Flip VITE_STORE_CART_BRIDGE to "true" once the file responds 200
 * at BRIDGE_URL — nothing else needs changing.
 */
const BRIDGE_ENABLED =
  String(import.meta.env.VITE_STORE_CART_BRIDGE || "").toLowerCase() === "true";

// If the bridge never answers (file not deployed yet, store down, the iframe
// blocked) the UI must not hang on a spinner forever.
const TIMEOUT_MS = 6000;

const EMPTY = { items: [], totalItems: 0, cartTotal: 0, email: null };

function normaliseEmail(value) {
  return typeof value === "string" && value.includes("@")
    ? value.trim().toLowerCase()
    : null;
}

function parseCart(raw, email) {
  const account = normaliseEmail(email);
  if (!raw) return { ...EMPTY, email: account };
  try {
    const parsed = JSON.parse(raw);
    return {
      items: Array.isArray(parsed.items) ? parsed.items : [],
      totalItems: Number(parsed.totalItems) || 0,
      cartTotal: Number(parsed.cartTotal) || 0,
      email: account,
    };
  } catch {
    return { ...EMPTY, email: account };
  }
}

export function useStoreCart() {
  const [cart, setCart] = useState(EMPTY);
  const [status, setStatus] = useState(BRIDGE_ENABLED ? "loading" : "unavailable");
  const frameRef = useRef(null);

  useEffect(() => {
    if (!BRIDGE_ENABLED) return;
    let settled = false;

    const iframe = document.createElement("iframe");
    iframe.src = BRIDGE_URL;
    iframe.setAttribute("aria-hidden", "true");
    iframe.setAttribute("tabindex", "-1");
    iframe.title = "HappyWedz Store cart bridge";
    // Scripts only — the bridge needs no form, popup or navigation rights.
    iframe.setAttribute("sandbox", "allow-scripts allow-same-origin");
    iframe.style.cssText =
      "position:absolute;width:0;height:0;border:0;visibility:hidden;";
    frameRef.current = iframe;

    const finish = (next, nextStatus) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      setCart(next);
      setStatus(nextStatus);
    };

    const onMessage = (event) => {
      // Only the store may answer, and only through our own iframe — without
      // both checks any page that can post to this window could inject a cart.
      if (event.origin !== STORE_ORIGIN) return;
      if (event.source !== iframe.contentWindow) return;

      const data = event.data;
      if (!data || typeof data !== "object") return;

      if (data.type === "ready") {
        iframe.contentWindow.postMessage("get-cart", STORE_ORIGIN);
        return;
      }
      if (data.type === "cart") {
        finish(parseCart(data.cart, data.email), "ready");
      }
    };

    const timer = setTimeout(() => finish(EMPTY, "unavailable"), TIMEOUT_MS);

    // Some browsers fire load before the bridge's own "ready" post lands, so ask
    // again on load rather than relying on a single handshake direction.
    iframe.addEventListener("load", () => {
      try {
        iframe.contentWindow?.postMessage("get-cart", STORE_ORIGIN);
      } catch {
        /* cross-origin throw is expected in some engines; the timeout covers us */
      }
    });
    iframe.addEventListener("error", () => finish(EMPTY, "unavailable"));

    window.addEventListener("message", onMessage);
    document.body.appendChild(iframe);

    return () => {
      settled = true;
      clearTimeout(timer);
      window.removeEventListener("message", onMessage);
      iframe.remove();
    };
  }, []);

  return { ...cart, status, storeOrigin: STORE_ORIGIN };
}

export default useStoreCart;
