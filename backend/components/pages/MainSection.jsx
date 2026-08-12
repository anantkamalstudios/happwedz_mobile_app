import React, { useContext, useEffect, useState } from "react";
import { useParams, useLocation, useNavigate } from "react-router-dom";
import { useSelector, useDispatch } from "react-redux";
import { setLocation } from "../../redux/locationSlice";
import InfiniteScroll from "react-infinite-scroll-component";
import VendorsSearch from "../layouts/vendors/VendorsSearch";
import VenuesSearch from "../layouts/venus/VenuesSearch";
import NotFound from "./NotFound";
import MainByRegion from "../layouts/Main/MainByRegion";
import FindMain from "../layouts/Main/FindMain";
import MainHeroSection from "../layouts/Main/MainHeroSection";
import FactorsList from "../layouts/Main/FactorsList";
import FaqsSection from "../layouts/Main/FaqsSection";
import TopSlider from "../layouts/photography/TopSlider";
import SortSection from "../layouts/photography/SortSection";
import MainEInvites from "../layouts/eInvite/MainEInvites";
import GridImages from "../layouts/photography/GridImages";
import GroomeSlider from "../layouts/twoSoul/GroomeSlider";
import BrideSlider from "../layouts/twoSoul/BrideSlider";
import MainPhotages from "../layouts/twoSoul/MainPhotages";
import PricingModal from "../layouts/PricingModal";
import WeddingCardDesigns from "../layouts/eInvite/WeddingCardDesigns";
import MainSearch from "../layouts/Main/MainSearch";
import RealWedding from "./RealWedding";
import Genie from "./Genie";
import AllCategories from "../layouts/AllCategories";
import WeddingCategories from "../home/WeddingCategories";
import VenueInfoSection from "../layouts/Main/VenueInfoSection";
import GridView from "../layouts/Main/GridView";
import LoadingState from "../LoadingState";
import EmptyState from "../EmptyState";
import useInfiniteScroll from "../../hooks/useInfiniteScroll";
import { MyContext } from "../../context/useContext";
import axios from "axios";
import ViewSwitcher from "../layouts/Main/ViewSwitcher";
import ListView from "../layouts/Main/ListView";
import UserPrivateRoute from "../routes/UserPrivateRoute";
import DynamicAside from "../layouts/aside/DynamicAside";
import { useMemo } from "react";
import MapView from "../layouts/Main/MapView";
import SEO from "../common/SEO";

const formatCityName = (cityStr) => {
  if (!cityStr) return "";
  const decoded = decodeURIComponent(cityStr);
  return decoded
    .split(/[\s-]+/)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(" ");
};

const VENUE_CATEGORY_MAP = {
  "banquet-halls": { id: 2, name: "Banquet Halls" },
  "marriage-garden-lawns": { id: 3, name: "Marriage Garden / Lawns" },
  "marriage-garden--lawns": { id: 3, name: "Marriage Garden / Lawns" },
  "marriage-gardens": { id: 3, name: "Marriage Garden / Lawns" },
  "wedding-resorts": { id: 33, name: "Wedding Resorts" },
  "small-functions-party-halls": { id: 34, name: "Small Functions / Party Halls" },
  "small-function-party-halls": { id: 34, name: "Small Functions / Party Halls" },
  "small-function--party-halls": { id: 34, name: "Small Functions / Party Halls" },
  "party-halls": { id: 34, name: "Small Functions / Party Halls" },
  "destination-wedding-venues": { id: 35, name: "Destination Wedding Venues" },
  "4-star-and-above-wedding-hotels": { id: 37, name: "4 Star And Above Wedding Hotels" },
  "4-star--above-wedding-hotels": { id: 37, name: "4 Star And Above Wedding Hotels" },
  "4-star-above-wedding-hotels": { id: 37, name: "4 Star And Above Wedding Hotels" },
  "wedding-farmhouses": { id: 38, name: "Wedding Farmhouses" },
  "kalyana-mandapams": { id: 39, name: "Kalyana Mandapams" },
  "wedding-suites": { id: 30, name: "Wedding Suites" }
};

const MainSection = () => {
  const { section: rawSection, city: urlCity } = useParams();
  const location = useLocation();
  const dispatch = useDispatch();
  const reduxLocation = useSelector((state) => state.location.selectedLocation);

  const section = useMemo(() => {
    if (location.pathname.startsWith("/wedding-venues") || location.pathname.startsWith("/venues")) {
      return "venues";
    }
    return rawSection;
  }, [rawSection, location.pathname]);

  const categoryInfo = useMemo(() => {
    if (urlCity && VENUE_CATEGORY_MAP[urlCity.toLowerCase()]) {
      return VENUE_CATEGORY_MAP[urlCity.toLowerCase()];
    }
    return null;
  }, [urlCity]);

  const [selectedCity, setSelectedCity] = useState(() => {
    if (categoryInfo) {
      return reduxLocation || null;
    }
    if ((location.pathname.startsWith("/wedding-venues") || location.pathname.startsWith("/venues")) && urlCity) {
      return formatCityName(urlCity);
    }
    return reduxLocation;
  });

  useEffect(() => {
    if (categoryInfo) {
      setSelectedCity(reduxLocation || null);
    } else if ((location.pathname.startsWith("/wedding-venues") || location.pathname.startsWith("/venues")) && urlCity) {
      const formatted = formatCityName(urlCity);
      setSelectedCity(formatted);
      dispatch(setLocation(formatted));
    } else {
      setSelectedCity(reduxLocation);
    }
  }, [reduxLocation, urlCity, location.pathname, categoryInfo, dispatch]);

  const navigate = useNavigate();

  useEffect(() => {
    const searchParams = new URLSearchParams(location.search);
    const queryCity = searchParams.get("city");
    if (queryCity && (location.pathname === "/venues" || location.pathname === "/wedding-venues")) {
      const cleanCitySlug = queryCity
        .toLowerCase()
        .replace(/[^a-z0-9\s-]/g, "")
        .replace(/\s+/g, "-")
        .replace(/-+/g, "-")
        .replace(/^-+|-+$/g, "");
      navigate(`/wedding-venues/${cleanCitySlug}`, { replace: true });
    }
  }, [location.search, location.pathname, navigate]);

  const displayTitle = useMemo(() => {
    switch (section) {
      case "venues":
        if (categoryInfo) {
          return `${categoryInfo.name}${selectedCity ? ` in ${selectedCity}` : ""} | HappyWedz`;
        }
        return `Wedding Venues${selectedCity ? ` in ${selectedCity}` : ""} | HappyWedz`;
      case "vendors":
        return `Wedding Vendors${selectedCity ? ` in ${selectedCity}` : ""} | HappyWedz`;
      case "photography":
        return "Wedding Photography & Inspiration | HappyWedz";
      case "real-wedding":
        return "Real Weddings & Stories | HappyWedz";
      case "e-invites":
        return "Digital E-Invitations & Wedding Cards | HappyWedz";
      case "e-invite-wedding-card-designs":
        return "E-Invite Wedding Card Designs | HappyWedz";
      case "twosoul":
        return "Two Soul Matrimonial | HappyWedz";
      case "latest-real-weddings":
        return "Latest Real Weddings | HappyWedz";
      case "shaadi-ai":
        return "Shaadi AI - Your AI Wedding Planner | HappyWedz";
      default:
        return "HappyWedz - Find Top Wedding Vendors, Venues & Planning Tools";
    }
  }, [section, selectedCity, categoryInfo]);

  const displayDescription = useMemo(() => {
    switch (section) {
      case "venues":
        return `Find and book top rated wedding venues${selectedCity ? ` in ${selectedCity}` : ""}. Compare options, check pricing, reviews, and availability at HappyWedz.`;
      case "vendors":
        return `Discover top-rated wedding vendors${selectedCity ? ` in ${selectedCity}` : ""} including photographers, makeup artists, caterers, and decorators on HappyWedz.`;
      case "photography":
        return "Browse wedding photography ideas, pre-wedding shoot inspiration, couples portraits, and get ideas from real Indian weddings.";
      case "real-wedding":
        return "Explore real wedding stories, pictures, decorations, wedding outfits, and ideas from real couples around India.";
      case "e-invites":
        return "Create beautiful, customized digital wedding invitations and e-cards online with our easy wedding card creator tool.";
      case "e-invite-wedding-card-designs":
        return "Browse hundreds of customizable electronic wedding invitation designs and templates for your special day.";
      case "twosoul":
        return "Find your soulmate and begin your beautiful journey with HappyWedz Two Soul matrimonial matches and verified profiles.";
      case "latest-real-weddings":
        return "See the latest weddings planning and celebration galleries. Get inspired by trending decor and bridal attire.";
      case "shaadi-ai":
        return "Plan your wedding with Shaadi AI, our smart assistant helping you find vendors, plan budgets, schedules, and answer wedding queries.";
      default:
        return "Discover top-rated wedding vendors, venues, and planning tools for your perfect wedding. Explore real weddings, inspiration, and expert advice with HappyWedz.";
    }
  }, [section, selectedCity]);

  const [show, setShow] = useState(false);
  const [selectedId, setSelectedId] = useState(null);

  const storageKey = useMemo(() => `viewMode:${section}:main`, [section]);

  const [view, setView] = useState(() => {
    const saved =
      typeof window !== "undefined" ? localStorage.getItem(storageKey) : null;
    return saved || "images";
  });

  const [photos, setPhotos] = useState([]);
  const [heroInfo, setHeroInfo] = useState([]);
  const [venueFilters, setVenueFilters] = useState({});

  const { data, loading, error, hasMore, loadMore } = useInfiniteScroll(
    "venues",
    categoryInfo ? categoryInfo.name : null,
    selectedCity,
    "Venues",
    9,
    venueFilters
  );
  const [searchQuery, setSearchQuery] = useState("");
  const {
    selectedCategory,
    setSelectedCategory,
    selectedCategoryName,
    setSelectedCategoryName,
    displayPhotos,
    loading: photosLoading,
    sortBy,
    setSortBy,
  } = useContext(MyContext);



  useEffect(() => {
    const saved =
      typeof window !== "undefined" ? localStorage.getItem(storageKey) : null;
    if (saved && saved !== view) {
      setView(saved);
    }
  }, [storageKey]);

  useEffect(() => {
    try {
      if (typeof window !== "undefined") {
        localStorage.setItem(storageKey, view);
      }
    } catch (e) {}
  }, [view, storageKey]);

  const handleShow = (id) => {
    setSelectedId(id);
    setShow(true);
  };

  const handleClose = () => {
    setShow(false);
    setSelectedId(null);
  };

  if (section === "venues") {
    return (
      <>
        <SEO title={displayTitle} description={displayDescription} />
        <MainSearch />
        {!reduxLocation && <MainByRegion type="Venues" />}

        <DynamicAside
          section="venues"
          view={view}
          setView={setView}
          onFiltersChange={setVenueFilters}
        />

        {loading && data.length === 0 && <LoadingState title="Venues" />}

        {!loading && data.length === 0 && (
          <EmptyState section="venues" title="Venues" />
        )}

        {view === "map" && (
          <MapView
            subVenuesData={data}
            section="venues"
            onClose={() => setView("images")}
          />
        )}

        {data.length > 0 && (
          <div className="container-fluid">
            <InfiniteScroll
              dataLength={data.length}
              next={loadMore}
              hasMore={hasMore}
              loader={
                <div className="text-center my-4">
                  <div className="scroll-down-loader mx-auto"></div>
                  <p className="text-muted mt-2 small fw-medium">
                    Scroll Down to Load More Venues
                  </p>
                </div>
              }
              endMessage={
                <div className="text-center my-5">
                  <p className="text-muted fw-medium">
                    You've seen all available venues!
                  </p>
                </div>
              }
              scrollThreshold={0.7}
              style={{ overflow: "visible" }}
            >
              {view === "images" && (
                <GridView
                  subVenuesData={data}
                  section="venues"
                  handleShow={handleShow}
                  currentCity={selectedCity}
                />
              )}
              {view === "list" && (
                <ListView
                  subVenuesData={data}
                  section="venues"
                  handleShow={handleShow}
                  currentCity={selectedCity}
                />
              )}
            </InfiniteScroll>
            <PricingModal
              show={show}
              handleClose={handleClose}
              vendorId={selectedId}
            />
          </div>
        )}
        <VenueInfoSection city={selectedCity} />
      </>
    );
  }

  if (section === "vendors") {
    return (
      <>
        <SEO title={displayTitle} description={displayDescription} />
        <MainSearch title="Wedding Vendor" />
        {!reduxLocation && <MainByRegion type="vendors" />}
        <AllCategories />
        {/* <FindMain /> */}
        <FaqsSection />
      </>
    );
  }

  if (section === "photography") {
    return (
      <div className="container">
        <SEO title={displayTitle} description={displayDescription} />
        <h3 className="mt-5 fw-bold primary-text h2">
          Every Smile, Every Tear, Every Moment — Perfectly Captured
        </h3>
        <h6>
          Find the latest trends and heartfelt inspiration to shape your perfect
          wedding story
        </h6>
        <TopSlider
          onCategorySelect={(id, name) => {
            setSelectedCategory(id);
            setSelectedCategoryName(name);
          }}
        />

        <SortSection
          category={selectedCategoryName}
          onCategoryChange={setSelectedCategory}
          onSearchChange={setSearchQuery}
          sortBy={sortBy}
          onSortChange={setSortBy}
        />

        {photosLoading ? (
          <p className="text-center my-5">Loading photos...</p>
        ) : (
          <GridImages
            photos={displayPhotos}
            category={selectedCategory}
            searchQuery={searchQuery}
          />
        )}
      </div>
    );
  }

  if (section === "real-wedding") {
    return (
      <>
        <SEO title={displayTitle} description={displayDescription} />
        <RealWedding />
      </>
    );
  }

  if (section === "e-invites") {
    return (
      <>
        <SEO title={displayTitle} description={displayDescription} />
        <MainSearch title="E Invites" />
        <WeddingCardDesigns />
        <FaqsSection />
      </>
    );
  }
  if (section === "e-invite-wedding-card-designs") {
    return (
      <>
        <SEO title={displayTitle} description={displayDescription} />
        <WeddingCardDesigns />
        <FactorsList />
        <FaqsSection />
      </>
    );
  }

  if (section === "twosoul") {
    return (
      <>
        <SEO title={displayTitle} description={displayDescription} />
        <MainSearch title="Two Soul" />
        {!reduxLocation && <MainByRegion />}
        <GroomeSlider />
        <MainPhotages />
        <BrideSlider />
      </>
    );
  }

  if (section === "latest-real-weddings") {
    return (
      <>
        <SEO title={displayTitle} description={displayDescription} />
        <MainSearch title="latest Real Weddings" />
        {!reduxLocation && <MainByRegion />}
        <FindMain />
        <MainHeroSection loc={"Panjab"} />
        <MainHeroSection loc={"Karela "} />
        <MainHeroSection loc={"Goa"} />
        <FactorsList />
        <FaqsSection />
      </>
    );
  }

  // if (section === "matrimonial") {
  //   return (
  //     <>
  //       <VenuesSearch title="Matrimonial" />
  //       <MainByRegion />
  //       <FindMain />
  //       <MainHeroSection loc={"Panjab"} />
  //       <MainHeroSection loc={"Karela "} />
  //       <MainHeroSection loc={"Goa"} />
  //       <FactorsList />
  //       <FaqsSection />
  //     </>
  //   );
  // }

  if (section === "shaadi-ai") {
    return (
      <>
        <SEO title={displayTitle} description={displayDescription} />
        <UserPrivateRoute>
          <Genie />
        </UserPrivateRoute>
      </>
    );
  }

  return <NotFound />;
};

export default MainSection;
