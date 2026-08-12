import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import axios from "axios";

const API_URL = "https://happywedz.com/api/wishlist/toggle";

export const addToWishlist = createAsyncThunk(
  "wishlist/add",
  async ({ userId, vendorId }) => {
    const res = await axios.post(`${API_URL}`, { userId, vendorId });
    return res.data;
  }
);

export const getUserWishlist = createAsyncThunk(
  "wishlist/getUser",
  async (userId) => {
    const res = await axios.get(`${API_URL}/user/${userId}`);
    return res.data;
  }
);

export const updateWishlist = createAsyncThunk(
  "wishlist/update",
  async ({ id, rating, description }) => {
    const res = await axios.put(`${API_URL}/${id}`, { rating, description });
    return res.data;
  }
);

export const removeFromWishlist = createAsyncThunk(
  "wishlist/remove",
  async (id) => {
    await axios.delete(`${API_URL}/${id}`);
    return id;
  }
);

const wishlistSlice = createSlice({
  name: "wishlist",
  initialState: {
    items: [],
    loading: false,
    error: null,
  },
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(getUserWishlist.pending, (state) => {
        state.loading = true;
      })
      .addCase(getUserWishlist.fulfilled, (state, action) => {
        state.loading = false;
        state.items = action.payload;
      })
      .addCase(getUserWishlist.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message;
      })

      .addCase(addToWishlist.fulfilled, (state, action) => {
        state.items.push(action.payload);
      })

      .addCase(updateWishlist.fulfilled, (state, action) => {
        const idx = state.items.findIndex((i) => i._id === action.payload._id);
        if (idx !== -1) {
          state.items[idx] = action.payload;
        }
      })

      .addCase(removeFromWishlist.fulfilled, (state, action) => {
        state.items = state.items.filter((i) => i._id !== action.payload);
      });
  },
});

export default wishlistSlice.reducer;
