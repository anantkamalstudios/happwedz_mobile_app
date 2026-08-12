import React, { useState } from "react";
import { useParams } from "react-router-dom";
import GridView from "../layouts/venus/GridView";
import ListView from "../layouts/venus/ListView";
import { subVenuesData } from "../../data/subVenuesData";
import { Button } from "react-bootstrap";
import ViewSwitcher from "../layouts/venus/ViewSwitcher";
import VenuesSearch from "../layouts/venus/VenuesSearch";
import MapView from "../layouts/venus/MapView";

const SubVenues = () => {
  const { slug } = useParams();
  const toTitleCase = (slug) => {
    return slug
      .replace(/-/g, " ")
      .replace(/\b\w/g, (char) => char.toUpperCase());
  };

  const [view, setView] = useState("images");

  const toggleView = () => {
    setToggleSwitch(toggleSwitch === "grid" ? "list" : "grid");
  };

  const title = slug ? toTitleCase(slug) : "Wedding Venues";

  return (
    <div className="container-fluid">
      <VenuesSearch title={title} />
      <ViewSwitcher view={view} setView={setView} />
      {view === "list" && <ListView subVenuesData={subVenuesData} />}
      {view === "images" && <GridView subVenuesData={subVenuesData} />}
      {view === "map" && <MapView subVenuesData={subVenuesData} />}
    </div>
  );
};

export default SubVenues;
