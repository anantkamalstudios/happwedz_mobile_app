import React, { useState, useMemo, useEffect } from "react";
import { useSelector } from "react-redux";
import { useParams, useLocation, useNavigate } from "react-router-dom";
import InfiniteScroll from "react-infinite-scroll-component";
import ListView from "../layouts/Main/ListView";
import GridView from "../layouts/Main/GridView";
import MapView from "../layouts/Main/MapView";
import MainSearch from "../layouts/Main/MainSearch";
import PricingModal from "../layouts/PricingModal";
import Photos from "../layouts/photography/Photos";
import DynamicAside from "../layouts/aside/DynamicAside";
import useInfiniteScroll from "../../hooks/useInfiniteScroll";
import usePhotography from "../../hooks/usePhotography";
import EmptyState from "../EmptyState";
import LoadingState from "../LoadingState";
import ErrorState from "../ErrorState";
import Loader from "../ui/Loader";
import SEO from "../common/SEO";
const toTitleCase = (str) =>
  str.replace(/-/g, " ").replace(/\b\w/g, (l) => l.toUpperCase());

const normalizeServiceStatus = (value) => {
  const normalized = String(value || "").trim().toLowerCase();
  if (normalized === "publish" || normalized === "published") return "publish";
  if (
    normalized === "hide" ||
    normalized === "draft" ||
    normalized === "archived"
  )
    return "hide";
  return "hide";
};

const SubSection = () => {
  const navigate = useNavigate();
  const { section: routeSection, slug: routeSlug, subcategory, city } = useParams();
  const location = useLocation();
  const searchParams = new URLSearchParams(location.search);
  const vendorType = searchParams.get("vendorType");
  const stateCity = location.state?.city;
  const stateMinRating = location.state?.minRating;

  const isNestedVendor = location.pathname.startsWith("/vendors/");
  const isNestedPhotography = location.pathname.startsWith("/photography/");

  const section = isNestedVendor ? "vendors" : isNestedPhotography ? "photography" : routeSection;
  const slug = (isNestedVendor || isNestedPhotography) ? (subcategory || routeSlug) : routeSlug;

  const formatCityName = (cityStr) => {
    if (!cityStr) return "";
    const decoded = decodeURIComponent(cityStr);
    return decoded
      .split(/[\s-]+/)
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join(" ");
  };

  const cityFromQuery = stateCity || (city ? formatCityName(city) : (searchParams.get("city") ? formatCityName(searchParams.get("city")) : null));
  const minRatingFromQuery =
    stateMinRating !== undefined && stateMinRating !== null
      ? String(stateMinRating)
      : searchParams.get("minRating");
  let title = slug ? toTitleCase(slug) : "";
  if (slug === "all") {
    if (section === "vendors") {
      title = "All Vendors";
    } else if (section === "photography") {
      title = "All Photography";
    }
  }

  const [show, setShow] = useState(false);
  const [selectedId, setSelectedId] = useState(null);

  const storageKey = useMemo(
    () => `viewMode:${section}:${slug || "all"}`,
    [section, slug]
  );

  const [view, setView] = useState(() => {
    const saved =
      typeof window !== "undefined" ? localStorage.getItem(storageKey) : null;
    return saved || "images";
  });
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState(null);
  const [activeFilters, setActiveFilters] = useState(() => {
    if (minRatingFromQuery) {
      return { Rating: [`${minRatingFromQuery}+`] };
    }
    return {};
  });

  const {
    typesWithCategories,
    photosByCategory,
    allPhotos,
    loading: photographyLoading,
    error: photographyError,
    fetchTypesWithCategories,
    fetchPhotosByCategory,
    fetchAllPhotos,
  } = usePhotography();

  const reduxLocation = useSelector((state) => state.location.selectedLocation);
  const [selectedCity, setSelectedCity] = useState(
    cityFromQuery || reduxLocation
  );

  useEffect(() => {
    const queryCity = searchParams.get("city");
    if (queryCity && isNestedVendor) {
      const cleanCitySlug = queryCity
        .toLowerCase()
        .replace(/[^a-z0-9\s-]/g, "")
        .replace(/\s+/g, "-")
        .replace(/-+/g, "-")
        .replace(/^-+|-+$/g, "");
      const activeSubcat = subcategory || "all";
      navigate(`/vendors/${activeSubcat}/${cleanCitySlug}`, { replace: true });
    }
  }, [location.search, isNestedVendor, subcategory, navigate]);

  const mergedFilters = useMemo(() => {
    const merged = { ...activeFilters };
    if (searchQuery) {
      merged.search = searchQuery;
    }
    return merged;
  }, [activeFilters, searchQuery]);

  const {
    data: apiData,
    loading,
    error,
    hasMore,
    loadMore,
  } = useInfiniteScroll(
    section,
    slug,
    selectedCity,
    vendorType,
    9,
    mergedFilters
  );

  const handleClose = () => {
    setShow(false);
    setSelectedId(null);
  };

  const handleShow = (id) => {
    setSelectedId(id);
    setShow(true);
  };

  const handleSearch = (query) => {
    const searchVal = typeof query === "object" ? query?.keyword : query;
    setSearchQuery(searchVal || "");
  };

  const handleCategoryChange = (categoryId) => {
    setSelectedCategory(categoryId);
  };

  const handleCityChange = (city) => {
    setSelectedCity(city);
  };

  const handleFiltersChange = (filters) => {
    setActiveFilters(filters);
  };

  useEffect(() => {
    if (minRatingFromQuery) {
      setActiveFilters({ Rating: [`${minRatingFromQuery}+`] });
    } else {
      setActiveFilters({});
    }
  }, [section, slug, minRatingFromQuery]);

  useEffect(() => {
    if (cityFromQuery && cityFromQuery !== "all") {
      setSelectedCity(cityFromQuery);
      return;
    }
    setSelectedCity(reduxLocation);
  }, [cityFromQuery, reduxLocation]);

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

  useEffect(() => {
    if (!loading && isNestedVendor && city && apiData && apiData.length === 0) {
      const knownCities = [
        "mumbai", "pune", "nashik", "nagpur", "raigad", "gurgaon", "delhi", "noida", 
        "faridabad", "ghaziabad", "lucknow", "agra", "varanasi", "bangalore", "mysore", 
        "chennai", "coimbatore", "madurai", "hyderabad", "warangal", "ahmedabad", 
        "gandhinagar", "dehradun", "nainital", "haridwar", "goa", "ludhiana", "amritsar", 
        "jalandhar", "patiala", "zirakpur", "chandigarh", "panchkula", "kochi", 
        "thiruvananthapuram", "ernakulam", "alappuzha", "kozikode", "patna", "gaya", 
        "muzaffarpur", "bhagalpur", "shimla", "solan", "kangra", "kullu", "chamba", 
        "udaipur", "jaipur", "all"
      ];
      const normalizedCity = String(city).toLowerCase().trim();
      if (!knownCities.includes(normalizedCity)) {
        navigate(`/vendors/${subcategory || "all"}/all/${city}`, { replace: true });
      }
    }
  }, [loading, isNestedVendor, city, apiData, subcategory, navigate]);

  const dataToSend = useMemo(() => {
    if (section === "photography") {
      return [];
    }

    if (error || !apiData || apiData.length === 0) {
      return [];
    }

    return apiData.filter(
      (item) => normalizeServiceStatus(item?.status) === "publish"
    );
  }, [section, apiData, error]);

  useEffect(() => {
    if (section === "photography") {
      fetchTypesWithCategories();
      if (slug) {
        const findCategoryBySlug = () => {
          for (const type of typesWithCategories) {
            if (Array.isArray(type.categories)) {
              const category = type.categories.find(
                (cat) =>
                  cat.name
                    .toLowerCase()
                    .replace(/\s+/g, "-")
                    .replace(/[^a-z0-9\-]/g, "") === slug
              );
              if (category) return category.id;
            }
          }
          return null;
        };

        const categoryId = findCategoryBySlug();
        if (categoryId) {
          fetchPhotosByCategory(categoryId, selectedCity);
        }
      } else {
        fetchAllPhotos();
      }
    }
  }, [section, slug, selectedCity, typesWithCategories.length]);

  useEffect(() => {}, [
    section,
    slug,
    title,
    selectedCity,
    apiData,
    loading,
    error,
    dataToSend,
  ]);

  const displayTitle = `Best ${title}${selectedCity ? ` in ${selectedCity}` : ""} — Prices & Reviews | HappyWedz`;
  const displayDescription = `Find & book the best verified ${title.toLowerCase()}${selectedCity ? ` in ${selectedCity}` : ""}. Compare packages, check prices, view photos, read real reviews and check availability on HappyWedz.`;

  if (section === "photography") {
    const photographyData = slug ? photosByCategory : allPhotos;

    return (
      <div className="container-fluid">
        <SEO title={displayTitle} description={displayDescription} />
        <MainSearch
          title={title}
          onSearch={handleSearch}
          onCategoryChange={handleCategoryChange}
          onCityChange={handleCityChange}
        />
        {photographyLoading ? (
          <LoadingState title={title} />
        ) : photographyError ? (
          <ErrorState error={photographyError} />
        ) : (
          <Photos
            title={title}
            images={photographyData}
            loading={photographyLoading}
            typesWithCategories={typesWithCategories}
          />
        )}
      </div>
    );
  }

  if (view === "map") {
    return (
      <>
        <SEO title={displayTitle} description={displayDescription} />
        <MapView
          subVenuesData={dataToSend}
          section={section}
          onClose={() => setView("images")}
        />
      </>
    );
  }

  return (
    <div className="container-fluid">
      <SEO title={displayTitle} description={displayDescription} />
      <MainSearch
        title={title}
        onSearch={handleSearch}
        onCategoryChange={handleCategoryChange}
        onCityChange={handleCityChange}
      />

      {error ? (
        <ErrorState error={error} />
      ) : loading && dataToSend.length === 0 ? (
        <Loader />
      ) : !loading && dataToSend.length === 0 ? (
        <EmptyState section={section} title={title} />
      ) : (
        <>
          <DynamicAside
            section={section}
            view={view}
            setView={setView}
            onFiltersChange={handleFiltersChange}
            vendorType={vendorType}
          />

          <InfiniteScroll
            dataLength={dataToSend.length}
            next={loadMore}
            hasMore={hasMore}
            loader={
              <div className="text-center my-4">
                <div className="scroll-down-loader mx-auto"></div>
                <p className="text-muted mt-2 small fw-medium">
                  Scroll Down to Load More {title}
                </p>
              </div>
            }
            endMessage={
              <div className="text-center my-5">
                <p className="text-muted fw-medium">
                  You've seen all available {title.toLowerCase()}!
                </p>
              </div>
            }
            scrollThreshold={0.7}
            style={{ overflow: "visible" }}
          >
            {view === "images" && (
              <GridView
                subVenuesData={dataToSend}
                section={section}
                handleShow={handleShow}
                currentCity={selectedCity}
              />
            )}

            {view === "list" && (
              <ListView
                subVenuesData={dataToSend}
                section={section}
                handleShow={handleShow}
                currentCity={selectedCity}
              />
            )}
            {view === "map" && (
              <MapView
                subVenuesData={dataToSend}
                section={section}
                currentCity={selectedCity}
              />
            )}
          </InfiniteScroll>

          <PricingModal
            show={show}
            handleClose={handleClose}
            vendorId={selectedId}
          />
        </>
      )}
    </div>
  );
};

export default SubSection;
