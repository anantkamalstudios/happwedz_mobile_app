import React from "react";
import { Outlet } from "react-router-dom";
import Header from "./Header";
import Footer from "./Footer";
import { MyProvider } from "../../context/useContext";
import { FilterProvider } from "../../context/realWedding.context.jsx";
import MovmentPlusHeader from "./MovmentPlusHeader.jsx";
import SEO from "../common/SEO";

export default function MovmentPlusLayout() {

  return (
    <>
      <SEO />
      <MyProvider>
        <FilterProvider>
          {/* Movments Plus right sidebar navbar */}
          <MovmentPlusHeader />
          {/* Homepage navbar stays full width; the sidebar starts below it */}
          <Header />
          {/* Page content is pushed left on desktop so it never sits under the permanent sidebar */}
          <div className="movment_plus_page_content">
            <main style={{ minHeight: "70vh" }}>
              <Outlet />
            </main>
            <Footer />
          </div>
        </FilterProvider>
      </MyProvider>
    </>
  );
}
