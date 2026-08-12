import React, { useEffect, useRef, useState } from "react";
import "./SectionTabs.css";

const SectionTabs = ({ scrollToSection }) => {
  const [active, setActive] = useState("");
  const sectionIds = ["about", "venue-faq", "reviews", "map"];
  const isProgrammaticScroll = useRef(false);
  const scrollTimer = useRef(null);
  const [stuck, setStuck] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const sentinelRef = useRef(null);

  const handleClick = (section) => {
    // Immediately highlight clicked tab
    setActive(section);
    // Pause observer updates during smooth scroll
    isProgrammaticScroll.current = true;
    if (scrollTimer.current) clearTimeout(scrollTimer.current);
    if (typeof scrollToSection === "function") {
      scrollToSection(section);
    }
    // Resume observer after smooth scroll likely completed
    scrollTimer.current = setTimeout(() => {
      isProgrammaticScroll.current = false;
    }, 700);
  };

  // Auto-activate tab based on section visibility while scrolling
  useEffect(() => {
    const targets = sectionIds
      .map((id) => document.getElementById(id))
      .filter(Boolean);
    if (targets.length === 0) return;

    // Account for sticky header/tabs by shifting the top root margin
    const observer = new IntersectionObserver(
      (entries) => {
        if (isProgrammaticScroll.current) return; // keep clicked tab active during smooth scroll
        // Find the most visible intersecting section
        const visible = entries
          .filter((e) => e.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio);
        if (visible.length > 0) {
          const id = visible[0].target.id;
          if (id && id !== active) setActive(id);
          return;
        }
        // Fallback: pick the section closest to top when none intersect (rare)
        const byTop = entries
          .slice()
          .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);
        const nearTop =
          byTop.find((e) => e.boundingClientRect.top >= 0) || byTop[0];
        if (nearTop) {
          const id = nearTop.target.id;
          if (id && id !== active) setActive(id);
        }
      },
      {
        // Shift viewport to trigger earlier/later as needed
        root: null,
        rootMargin: "-110px 0px -60% 0px", // top offset for header/tabs; favor upper sections
        threshold: [0.15, 0.35, 0.55, 0.75],
      },
    );

    targets.forEach((el) => observer.observe(el));
    return () => {
      observer.disconnect();
      if (scrollTimer.current) clearTimeout(scrollTimer.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sectionIds.join("|")]);

  useEffect(() => {
    const mq = window.matchMedia("(max-width: 576px)");
    const apply = () => setIsMobile(!!mq.matches);
    apply();
    if (mq.addEventListener) {
      mq.addEventListener("change", apply);
      return () => mq.removeEventListener("change", apply);
    } else if (mq.addListener) {
      mq.addListener(apply);
      return () => mq.removeListener(apply);
    }
  }, []);

  useEffect(() => {
    const el = sentinelRef.current;
    if (!el) return;
    const obs = new IntersectionObserver(([entry]) => {
      setStuck(!entry.isIntersecting);
    });
    obs.observe(el);
    return () => obs.disconnect();
  }, []);

  return (
    <>
      <div ref={sentinelRef} style={{ height: 1 }} />
      <div
        className="section-tabs-sticky"
        style={isMobile ? { zIndex: stuck ? 1020 : "auto" } : undefined}
      >
        <div className="d-flex flex-wrap gap-2 mb-0">
          {["about", "FAQ", "reviews", "map"].map((item) => (
            <button
              key={item}
              type="button"
              className={`section-tab btn btn-sm ${active === item ? "active" : ""}`}
              onClick={() => handleClick(item)}
            >
              {item.charAt(0).toUpperCase() + item.slice(1)}
            </button>
          ))}
        </div>
      </div>
    </>
  );
};

export default SectionTabs;
