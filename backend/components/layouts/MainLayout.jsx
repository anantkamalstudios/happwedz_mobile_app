import React, { Suspense, lazy, useEffect, useState } from "react";
import { Outlet, useParams } from "react-router-dom";
import Header from "./Header";
import Footer from "./Footer";
import { MyProvider } from "../../context/useContext";
import { FilterProvider } from "../../context/realWedding.context.jsx";
import SEO from "../common/SEO";

// The Gennie chat widget is a floating button in the bottom-right corner — it is
// never part of first paint, but its ~33KB of source (plus the lucide-react icon
// pack it pulls in) sat in the entry chunk and had to be parsed before the page
// could render. Code-split it and mount it once the browser is idle.
const HomeGennie = lazy(() => import("../common/HomeGennie"));

function useIdle() {
  const [idle, setIdle] = useState(false);

  useEffect(() => {
    if (typeof window === "undefined") return;

    if (!("requestIdleCallback" in window)) {
      const timer = setTimeout(() => setIdle(true), 2000);
      return () => clearTimeout(timer);
    }

    const handle = window.requestIdleCallback(() => setIdle(true), {
      timeout: 3000,
    });
    return () => window.cancelIdleCallback(handle);
  }, []);

  return idle;
}

export default function MainLayout() {
  const params = useParams();
  const idle = useIdle();
  const isShaadiAi = params.section === "shaadi-ai";

  return (
    <>
      <SEO />
      <MyProvider>
        <FilterProvider>
          {!isShaadiAi && <Header />}
          <main style={{ minHeight: "70vh" }}>
            <Outlet />
          </main>
          {!isShaadiAi && idle && (
            <div
              style={{
                position: "fixed",
                bottom: "10vh",
                right: "60px",
                zIndex: "99",
              }}
            >
              <Suspense fallback={null}>
                <HomeGennie />
              </Suspense>
            </div>
          )}
          {!isShaadiAi && <Footer />}
        </FilterProvider>
      </MyProvider>
    </>
  );
}
