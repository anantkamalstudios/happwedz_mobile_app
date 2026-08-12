// DynamicAside.jsx
import React, { useMemo, useEffect, useRef } from "react";
import { useParams } from "react-router-dom";
import { useSelector, useDispatch } from "react-redux";
import {
  selectAppliedFilters,
  setAppliedFilters,
  clearFiltersByKey,
} from "../../../redux/filterSlice";
import TopFilter from "./TopFilter";
import useFilters from "../../../hooks/useFilters";
import { Container } from "react-bootstrap";

const DynamicAside = ({
  view,
  setView,
  section,
  onFiltersChange,
  vendorType,
}) => {
  const dispatch = useDispatch();
  const { slug } = useParams();
  const {
    filters,
    activeFilters,
    toggleFilter,
    clearFilters,
    isFilterActive,
    getActiveCount,
  } = useFilters({ section, slug: vendorType || slug });

  const filterKey = useMemo(() => {
    if (section === "venues" && !slug) return "venues";
    if (slug) return slug;
    return section || "";
  }, [section, slug]);

  const appliedFilters = useSelector((state) =>
    selectAppliedFilters(state, filterKey)
  );

  const prevFilterKeyRef = useRef(filterKey);

  useEffect(() => {
    if (
      prevFilterKeyRef.current !== null &&
      prevFilterKeyRef.current !== filterKey
    ) {
      dispatch(clearFiltersByKey({ key: prevFilterKeyRef.current }));

      if (onFiltersChange) {
        onFiltersChange({});
      }
    }
    prevFilterKeyRef.current = filterKey;
  }, [filterKey, dispatch, onFiltersChange]);

  const handleToggleFilter = (group, value) => {
    toggleFilter(group, value);
  };

  const handleApplyFilters = () => {
    const currentFilters = { ...activeFilters };

    dispatch(setAppliedFilters({ key: filterKey, filters: currentFilters }));

    if (onFiltersChange) {
      onFiltersChange(currentFilters);
    }
  };

  const handleClearFilters = () => {
    clearFilters();
    if (onFiltersChange) {
      onFiltersChange({});
    }
  };

  const hasPendingChanges =
    JSON.stringify(activeFilters) !== JSON.stringify(appliedFilters);

  return (
    <Container>
      <TopFilter
        view={view}
        setView={setView}
        filters={filters}
        activeFilters={activeFilters}
        appliedFilters={appliedFilters}
        onToggleFilter={handleToggleFilter}
        onClearFilters={handleClearFilters}
        onApplyFilters={handleApplyFilters}
        isFilterActive={isFilterActive}
        getActiveCount={getActiveCount}
        hasPendingChanges={hasPendingChanges}
      />
    </Container>
  );
};

export default DynamicAside;
