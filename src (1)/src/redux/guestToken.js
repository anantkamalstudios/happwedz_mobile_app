import { createSlice } from "@reduxjs/toolkit";

const initialState = {
  guestToken: localStorage.getItem("guestToken") || null,
};

const guestTokenSlice = createSlice({
  name: "guestToken",
  initialState,
  reducers: {
    setGuestToken: (state, action) => {
      state.guestToken = action.payload;
      localStorage.setItem("guestToken", action.payload);
    },
    removeGuestToken: (state) => {
      state.guestToken = null;
      localStorage.removeItem("guestToken");
    },
  },
});

export const { setGuestToken, removeGuestToken } = guestTokenSlice.actions;
export default guestTokenSlice.reducer;
