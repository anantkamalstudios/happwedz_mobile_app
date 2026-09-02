import { useEffect, useMemo, useState, useCallback } from "react";
import { useDispatch, useSelector } from "react-redux";
import {
  setActiveFilters,
  toggleFilter as toggleFilterAction,
  clearFilters as clearFiltersAction,
  selectActiveFilters,
} from "../redux/filterSlice";
import FILTER_CONFIG, { DEFAULT_FILTERS } from "../data/filtersConfig";

// Backend-ready hook to retrieve filters dynamically per section/subcategory.
// Manages both filter options and active selections.
// Now uses Redux to persist filter state
const useFilters = ({ section, slug }) => {
  const dispatch = useDispatch();
  const [filters, setFilters] = useState(DEFAULT_FILTERS);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const key = useMemo(() => {
    // Normalize the key so query params like `?vendorType=Photographers`
    // match the keys in `filtersConfig` (e.g. `photographers`).
    if (section === "venues" && !slug) return "venues";
    const raw = slug || section || "";
    // lowercase, trim, replace spaces with hyphens to match FILTER_CONFIG keys
    return String(raw).toLowerCase().trim().replace(/\s+/g, "-");
  }, [section, slug]);

  // Get active filters from Redux
  const activeFilters = useSelector((state) => selectActiveFilters(state, key));

  useEffect(() => {
    let isMounted = true;
    const load = async () => {
      setLoading(true);
      setError(null);
      try {
        // Placeholder for backend-driven filters.
        // Example future endpoint:
        // const qs = new URLSearchParams({ section, slug }).toString();
        // const res = await fetch(`https://happywedz.com/api/filters?${qs}`);
        // if (res.ok) {
        //   const data = await res.json();
        //   if (isMounted) setFilters(data);
        //   return;
        // }

        const local = FILTER_CONFIG[key] || DEFAULT_FILTERS;
        if (isMounted) {
          setFilters(local);
          // Filters are now stored in Redux, so they persist automatically
          // No need to manually preserve/restore them
        }
      } catch (e) {
        if (isMounted) {
          setError(e);
          setFilters(FILTER_CONFIG[key] || DEFAULT_FILTERS);
        }
      } finally {
        if (isMounted) setLoading(false);
      }
    };
    load();
    return () => {
      isMounted = false;
    };
  }, [key, section, slug]);

  // Toggle a filter value - uses Redux action
  const toggleFilter = useCallback(
    (group, value) => {
      dispatch(toggleFilterAction({ key, group, value }));
    },
    [dispatch, key]
  );

  // Clear all filters - uses Redux action
  const clearFilters = useCallback(() => {
    dispatch(clearFiltersAction({ key }));
  }, [dispatch, key]);

  // Clear specific filter group
  const clearFilterGroup = useCallback(
    (group) => {
      const currentFilters = { ...activeFilters };
      delete currentFilters[group];
      dispatch(setActiveFilters({ key, filters: currentFilters }));
    },
    [dispatch, key, activeFilters]
  );

  // Check if a filter is active
  const isFilterActive = useCallback(
    (group, value) => {
      return activeFilters[group]?.includes(value) || false;
    },
    [activeFilters]
  );

  // Get count of active filters in a group
  const getActiveCount = useCallback(
    (group) => {
      return activeFilters[group]?.length || 0;
    },
    [activeFilters]
  );

  // Get total active filter count
  const totalActiveCount = useMemo(() => {
    return Object.values(activeFilters).reduce(
      (sum, arr) => sum + arr.length,
      0
    );
  }, [activeFilters]);

  return {
    filters,
    activeFilters,
    loading,
    error,
    toggleFilter,
    clearFilters,
    clearFilterGroup,
    isFilterActive,
    getActiveCount,
    totalActiveCount,
  };
};

export default useFilters;
