import React from "react";
import { Outlet } from "react-router-dom";
import Header from "./Header";
import Footer from "./Footer";
import Navbar from "./matrimonial/Navbar";
import SEO from "../common/SEO";

export default function MatrimonialLayout() {
  return (
    <>
      <SEO />
      <Navbar />
      <main style={{ minHeight: "70vh" }}>
        <Outlet />
      </main>
      <Footer />
    </>
  );
}
