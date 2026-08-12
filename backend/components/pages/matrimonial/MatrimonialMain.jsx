import React from "react";
import Navbar from "../../layouts/matrimonial/Navbar";
import Hero from "./Home/Hero";
import MembersPlan from "./Home/MembersPlan";
import HomeSlider from "./Home/HomeSlider";
import SEO from "../../common/SEO";
// import MatrimonialDashboard from "./dashboard/MatrimonialDashboard";

const MatrimonialMain = () => {
  return (
    <div>
      <SEO
        title="Matrimonial | Find Your Perfect Match | HappyWedz"
        description="Browse verified matrimonial profiles on HappyWedz. Find your ideal life partner with advanced search filters, caste, religion, and location preferences."
      />

      <Hero />
      <MembersPlan />
      <HomeSlider />
      {/* <MatrimonialDashboard /> */}
    </div>
  );
};

export default MatrimonialMain;
