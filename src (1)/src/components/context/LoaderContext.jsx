import React, { createContext, useContext, useState } from "react";
import Loader from "../ui/Loader";

const LoaderContext = createContext();

export const useLoader = () => useContext(LoaderContext);

// The first screen is #app-shell in index.html — a static, markup-only copy of
// the branded logo splash in ui/Loader.jsx, painted before React loads. It is
// what FCP measures; index.html carries the full reasoning, including why it is
// this and not the hero copy that used to live there.
//
// One thing this must never go back to doing: holding on a timer. It was pinned
// up for a fixed 1500ms after mount, which cost ~1.5s of a 4.2s Speed Index —
// an opaque overlay measures as 0% visually complete no matter what has
// rendered underneath it. If the splash needs a visible minimum duration,
// that is a deliberate Speed Index trade and belongs behind an explicit,
// documented constant, not a reinstated sleep.
//
// It goes on the first frame after the app shell commits. Being position: fixed
// it contributes no layout, so removing it cannot shift the page.
const removeInitialLoader = () => {
  const el = document.getElementById("app-shell");
  if (!el) return;
  el.style.opacity = "0";
  setTimeout(() => el.remove(), 250);
};

const LoaderProvider = ({ children }) => {
  const [loading, setLoading] = useState(false);

  const showLoader = () => setLoading(true);
  const hideLoader = () => setLoading(false);

  React.useEffect(() => {
    let inner;
    let poll;
    let cancelled = false;

    // The shell must outlive two things: this commit being painted, and the
    // main stylesheet being applied.
    //
    // The stylesheet is loaded non-render-blocking (media="print" flipped to
    // "all" on load — see vite.config.js), and there is no longer any inlined
    // critical CSS behind it, so between the shell going and the sheet applying
    // the page would render unstyled. In practice the sheet is always there
    // first — it is far smaller than the JS that has to arrive before React can
    // even run — but "in practice" is not a guarantee, so wait for the flag the
    // link's onload sets. The 3s ceiling means a stylesheet that never loads
    // costs a flash of unstyled content, not a permanently hidden page.
    //
    // __cssReady only exists in production builds: the link it hangs off is
    // rewritten by the inline-critical-css plugin in vite.config.js, which is
    // `apply: "build"`. In dev Vite serves CSS through the module graph instead
    // — App.critical.css is imported by App.jsx and is already applied as a
    // <style> tag before this effect can run — so there is nothing to wait for,
    // and waiting anyway pinned the shell over the app for the full 3s ceiling
    // on every single reload (white flash, then the bare pink nav band and hero
    // shell, then the real page). Skip the gate in dev.
    const shellCanGo = () => {
      if (cancelled) return;
      if (import.meta.env.DEV || window.__cssReady || performance.now() > 3000) {
        // Two frames: the first is scheduled before the browser has painted
        // this commit, the second runs once it has. Removing the shell any
        // earlier would expose whatever React had not drawn yet.
        inner = requestAnimationFrame(() =>
          requestAnimationFrame(removeInitialLoader)
        );
      } else {
        poll = setTimeout(shellCanGo, 50);
      }
    };
    shellCanGo();

    return () => {
      cancelled = true;
      if (inner) cancelAnimationFrame(inner);
      if (poll) clearTimeout(poll);
    };
  }, []);

  return (
    <LoaderContext.Provider value={{ showLoader, hideLoader }}>
      {children}
      {loading && <Loader />}
    </LoaderContext.Provider>
  );
};

export default LoaderProvider;
