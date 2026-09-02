import { createSlice } from "@reduxjs/toolkit";

const initialState = {
  profile: null,
  recommendationsLens: null,
};

// Load from localStorage on init
const savedProfile = localStorage.getItem('wedding_personality_profile');
if (savedProfile) {
  try {
    const parsed = JSON.parse(savedProfile);
    initialState.profile = parsed;
    initialState.recommendationsLens = parsed.recommendations_lens;
  } catch (err) {
    console.error("Failed to load wedding profile from localStorage:", err);
  }
}

const weddingProfileSlice = createSlice({
  name: "weddingProfile",
  initialState,
  reducers: {
    setWeddingProfile: (state, action) => {
      state.profile = action.payload;
      state.recommendationsLens = action.payload.recommendations_lens;
      
      // Save to localStorage
      localStorage.setItem('wedding_personality_profile', JSON.stringify(action.payload));
    },
    clearWeddingProfile: (state) => {
      state.profile = null;
      state.recommendationsLens = null;
      localStorage.removeItem('wedding_personality_profile');
    },
  },
});

export const { setWeddingProfile, clearWeddingProfile } = weddingProfileSlice.actions;
export default weddingProfileSlice.reducer;
