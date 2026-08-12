import { createSlice } from "@reduxjs/toolkit";

const initialState = {
  role: "",
  type: "",
};

const roleSlice = createSlice({
  name: "role",
  initialState,
  reducers: {
    setRoleType: (state, action) => {
      if (action.payload.role !== undefined) state.role = action.payload.role;
      if (action.payload.type !== undefined) state.type = action.payload.type;
    },

    clearRoleType: (state) => {
      state.role = "";
      state.type = "";
    },
  },
});

export const { setRoleType, clearRoleType } = roleSlice.actions;
export default roleSlice.reducer;
