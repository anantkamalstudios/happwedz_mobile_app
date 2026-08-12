import React from "react";
import VendorsSearch from "../layouts/vendors/VendorsSearch";
import VendorsByRegion from "../layouts/vendors/VendorsByRegion";
import FindVendors from "../layouts/vendors/FindVendors";
import FactorsList from "../layouts/vendors/FactorsList";
import FaqsSection from "../layouts/vendors/FaqsSection";
import VendorsHeroSection from "../layouts/vendors/VendorsHeroSection";

const Vendors = () => {
  return (
    <>
      <VendorsSearch />
      <VendorsByRegion />
      <FindVendors />
      <VendorsHeroSection loc={"Panjab"} />
      <VendorsHeroSection loc={"Karela "} />
      <VendorsHeroSection loc={"Goa"} />
      <FactorsList />
      <FaqsSection />
    </>
  );
};

export default Vendors;
