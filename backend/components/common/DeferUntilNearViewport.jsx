import { useEffect, useRef, useState } from "react";

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
 */
export default function DeferUntilNearViewport({
  children,
  rootMargin = "600px",
  fallbackDelay = 3500,
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

    const timer = setTimeout(reveal, fallbackDelay);

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
  }, [show, rootMargin, fallbackDelay]);

  if (show) return children;

  // Reserves space so the scrollbar doesn't jump when the real content arrives.
  return <div ref={sentinelRef} style={{ minHeight }} aria-hidden="true" />;
}
