import React from "react";
import VenueSearch from "../../components/layouts/venus/VenuesSearch";
import VenuesHeroSection from "../../components/layouts/venus/VenuesHeroSection";

import VenuesByRegion from "../../components/layouts/venus/VenuesByRegion";
import Findvenue from "../../components/layouts/venus/Findvenue";
import FactorsList from "../../components/layouts/venus/FactorsList";
import FaqsSection from "../../components/layouts/venus/FaqsSection";

function Venus() {
  return (
    <>
      <VenueSearch />
      <VenuesByRegion />
      <Findvenue />
      <VenuesHeroSection loc={"Mumbai"} />
      <VenuesHeroSection loc={"Nashik"} />
      <VenuesHeroSection loc={"Pune"} />
      <FactorsList />
      <FaqsSection />
    </>
  );
}

export default Venus;
