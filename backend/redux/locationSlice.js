import { createSlice } from "@reduxjs/toolkit";

const invalidKeywords = [
  "hotel", "banquet", "lawn", "resort", "hall", "planner", 
  "photographer", "makeup", "decorator", "mehendi", "mandapam", 
  "vendor", "star", "venue", "catering", "chaat", "jewellery", 
  "lehenga", "sherwani", "invitation", "favor", "sangeet", "dj", "suite"
];

const isInvalidCity = (val) => {
  if (!val || typeof val !== "string") return true;
  const lower = val.toLowerCase();
  return invalidKeywords.some((kw) => lower.includes(kw));
};

const getInitialLocation = () => {
  const saved = localStorage.getItem("location");
  if (saved && !isInvalidCity(saved)) {
    return saved;
  }
  if (saved) {
    localStorage.removeItem("location");
  }
  return null;
};

const initialState = {
  selectedLocation: getInitialLocation(),
};

const locationSlice = createSlice({
  name: "location",
  initialState,
  reducers: {
    setLocation: (state, action) => {
      if (action.payload && !isInvalidCity(action.payload)) {
        state.selectedLocation = action.payload;
        localStorage.setItem("location", action.payload);
      } else if (!action.payload) {
        state.selectedLocation = null;
        localStorage.removeItem("location");
      }
    },
    clearLocation: (state) => {
      state.selectedLocation = null;
      localStorage.removeItem("location");
    },
  },
});

export const { setLocation, clearLocation } = locationSlice.actions;
export default locationSlice.reducer;
