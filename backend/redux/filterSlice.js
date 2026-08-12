import { createSlice } from "@reduxjs/toolkit";

const initialState = {
  // Store filters by key (section/slug combination)
  // Format: { "venues": { "venue Type": ["banquet-halls"], "capacity": ["100-200"] }, ... }
  filtersByKey: {},
  // Store applied filters separately (what's sent to API)
  appliedFiltersByKey: {},
};

const filterSlice = createSlice({
  name: "filters",
  initialState,
  reducers: {
    // Set active filters for a specific key (section/slug)
    setActiveFilters: (state, action) => {
      const { key, filters } = action.payload;
      state.filtersByKey[key] = filters || {};
    },

    // Toggle a single filter value
    toggleFilter: (state, action) => {
      const { key, group, value } = action.payload;
      if (!state.filtersByKey[key]) {
        state.filtersByKey[key] = {};
      }
      const groupFilters = state.filtersByKey[key][group] || [];
      const exists = groupFilters.includes(value);

      if (exists) {
        // Remove filter
        const updated = groupFilters.filter((v) => v !== value);
        if (updated.length === 0) {
          delete state.filtersByKey[key][group];
        } else {
          state.filtersByKey[key][group] = updated;
        }
      } else {
        // Add filter
        state.filtersByKey[key][group] = [...groupFilters, value];
      }
    },

    // Clear all filters for a specific key
    clearFilters: (state, action) => {
      const { key } = action.payload;
      state.filtersByKey[key] = {};
      state.appliedFiltersByKey[key] = {};
    },

    // Set applied filters (what's sent to API)
    setAppliedFilters: (state, action) => {
      const { key, filters } = action.payload;
      state.appliedFiltersByKey[key] = filters || {};
    },

    // Clear filters when navigating (key changes)
    clearFiltersByKey: (state, action) => {
      const { key } = action.payload;
      delete state.filtersByKey[key];
      delete state.appliedFiltersByKey[key];
    },
  },
});

export const {
  setActiveFilters,
  toggleFilter,
  clearFilters,
  setAppliedFilters,
  clearFiltersByKey,
} = filterSlice.actions;

// Selectors
// Shared empty-object fallback so useSelector gets a stable reference when a
// key has no entry yet, instead of a new {} on every call (which trips
// Redux's "Selector returned a different result" warning and forces
// unnecessary re-renders in every component reading this).
const EMPTY_FILTERS = {};

export const selectActiveFilters = (state, key) =>
  state.filters.filtersByKey[key] || EMPTY_FILTERS;

export const selectAppliedFilters = (state, key) =>
  state.filters.appliedFiltersByKey[key] || EMPTY_FILTERS;

export default filterSlice.reducer;

