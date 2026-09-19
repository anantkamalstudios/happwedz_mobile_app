import { Suspense, useEffect, useRef, useState } from "react";

/**
 * Delays mounting its children until they are close to the viewport.
 *
 * `React.lazy` alone only keeps a section out of the *entry chunk* — the moment
 * the section is rendered, React resolves its dynamic import, so every "lazy"
 * below-the-fold chunk (plus the images and third-party widgets inside it) still
 * lands in the initial load waterfall, competing with the LCP image for
 * bandwidth and with hydration for the main thread.
 *
 * Gating the mount on an IntersectionObserver is what actually removes that
 * cost. `rootMargin` is deliberately generous so a section is already mounted by
 * the time the user scrolls to it — nobody should ever see the placeholder.
 *
 * `fallbackDelay` is the safety net: a visitor (or a crawler) who never scrolls
 * still gets the full page, just after the critical window has closed. Without
 * it this pattern silently hides content from anything that renders without
 * scrolling.
 *
 * `stagger` offsets only that safety net. Every group on a page shares the same
 * `fallbackDelay`, so without it they all revealed on the same tick and the
 * document grew by thousands of pixels in one frame. It deliberately does not
 * touch the IntersectionObserver path — a section the user has scrolled to
 * should still mount immediately.
 *
 * Note on tuning: `rootMargin` (600px vs 150px) and delaying when the observer
 * attaches (requestIdleCallback, or waiting on a largest-contentful-paint
 * entry) were all measured against this page and changed LCP/FCP/TBT by
 * nothing. On a ~820px mobile viewport the sentinel sits below the fold at
 * scroll 0 either way, so these sections already mount via `fallbackDelay`
 * (3500ms) — well after LCP (~2650ms). They are not on the critical path;
 * don't re-tune this looking for a paint win.
 */
export default function DeferUntilNearViewport({
  children,
  rootMargin = "600px",
  fallbackDelay = 3500,
  stagger = 0,
  minHeight = 200,
}) {
  const sentinelRef = useRef(null);
  const [show, setShow] = useState(false);

  useEffect(() => {
    if (show) return;

    const reveal = () => setShow(true);

    // No IntersectionObserver (very old browsers, some crawlers) — render now
    // rather than risk never rendering.
    if (typeof IntersectionObserver === "undefined") {
      reveal();
      return;
    }

    const timer = setTimeout(reveal, fallbackDelay + stagger);

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) reveal();
      },
      { rootMargin },
    );
    if (sentinelRef.current) observer.observe(sentinelRef.current);

    return () => {
      clearTimeout(timer);
      observer.disconnect();
    };
  }, [show, rootMargin, fallbackDelay, stagger]);

  // Reserves space so the scrollbar doesn't jump when the real content arrives.
  const spacer = <div style={{ minHeight }} aria-hidden="true" />;

  // The children are React.lazy, so mounting them only *starts* the chunk
  // download — they suspend until it lands. Suspending against a `null`
  // fallback gave that space straight back: the placeholder unmounted and the
  // sections rendered 0px until the chunk arrived, collapsing the document by
  // the full reserved height (measured: 3989px -> 2289px) and forcing the
  // browser to clamp the scroll position of anyone already past that point.
  //
  // Owning the boundary here means the same box is held continuously —
  // placeholder, then fallback, then content — so the reserved height is only
  // ever handed over to the real section.
  if (show) return <Suspense fallback={spacer}>{children}</Suspense>;

  return <div ref={sentinelRef} style={{ minHeight }} aria-hidden="true" />;
}
