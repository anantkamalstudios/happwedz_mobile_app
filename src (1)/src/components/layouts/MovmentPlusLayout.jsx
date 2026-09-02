import React from "react";
import { Outlet, useParams } from "react-router-dom";
import Footer from "./Footer";
import { MyProvider } from "../../context/useContext";
import { FilterProvider } from "../../context/realWedding.context.jsx";
import MovmentPlusHeader from "./MovmentPlusHeader.jsx";
import SEO from "../common/SEO";

export default function MovmentPlusLayout() {
  const params = useParams();

  return (
    <>
      <SEO />
      <MyProvider>
        <FilterProvider>
          <MovmentPlusHeader />
          <main style={{ minHeight: "70vh" }}>
            <Outlet />
          </main>
          <Footer />
        </FilterProvider>
      </MyProvider>
    </>
  );
}
