import React, { useState } from "react";
import { useParams } from "react-router-dom";
import GridView from "../layouts/vendors/GridView";
import ListView from "../layouts/vendors/ListView";
import ViewSwitcher from "../layouts/vendors/ViewSwitcher";
import MapView from "../layouts/vendors/MapView";
import VendorsSearch from "../layouts/vendors/VendorsSearch";
import { useVendors } from "../../hooks/useVendors";

const SubVendors = () => {
  const { slug } = useParams();
  const [view, setView] = useState("images");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState(null);

  const toTitleCase = (slug) => {
    return slug
      .replace(/-/g, " ")
      .replace(/\b\w/g, (char) => char.toUpperCase());
  };

  const title = slug ? toTitleCase(slug) : "Wedding Vendors";

  const {
    vendors,
    loading,
    error,
    pagination,
    fetchVendors,
    refreshVendors,
    loadMore,
    hasMore,
  } = useVendors({
    search: searchQuery,
    categoryId: selectedCategory,
    limit: 20,
  });

  const handleSearch = (query) => {
    setSearchQuery(query);
  };

  const handleCategoryChange = (categoryId) => {
    setSelectedCategory(categoryId);
  };

  const handleRefresh = () => {
    refreshVendors();
  };

  if (loading && vendors.length === 0) {
    return (
      <div className="container-fluid">
        <div
          className="d-flex justify-content-center align-items-center"
          style={{ minHeight: "400px" }}
        >
          <div className="spinner-border text-primary" role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container-fluid">
        <div className="alert alert-danger" role="alert">
          <h4 className="alert-heading">Error Loading Vendors</h4>
          <p>{error}</p>
          <hr />
          <button className="btn btn-outline-danger" onClick={handleRefresh}>
            Try Again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="container-fluid">
      <div className="container-fluid">
        <VendorsSearch
          title={title}
          onSearch={handleSearch}
          onCategoryChange={handleCategoryChange}
        />
        <ViewSwitcher view={view} setView={setView} />
        {view === "list" && (
          <ListView
            subVendorsData={vendors}
            loading={loading}
            onLoadMore={loadMore}
            hasMore={hasMore}
          />
        )}
        {view === "images" && (
          <GridView
            subVendorsData={vendors}
            loading={loading}
            onLoadMore={loadMore}
            hasMore={hasMore}
          />
        )}
        {view === "map" && (
          <MapView subVendorsData={vendors} loading={loading} />
        )}
      </div>
    </div>
  );
};

export default SubVendors;
