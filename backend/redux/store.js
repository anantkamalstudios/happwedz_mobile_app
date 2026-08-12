import { configureStore } from "@reduxjs/toolkit";
import authReducer from "./authSlice";
import vendorAuthReducer from "./vendorAuthSlice";
import locationReducer from "./locationSlice";
import wishlistReducer from "./wishlistSlice";
import roleReducer from "./roleSlice";
import favoriteReducer from "./favoriteSlice";
import filterReducer from "./filterSlice";
import guestTokenReducer from "./guestToken";
import weddingProfileReducer from "./weddingProfileSlice";

const store = configureStore({
  reducer: {
    auth: authReducer,
    vendorAuth: vendorAuthReducer,
    location: locationReducer,
    wishlist: wishlistReducer,
    role: roleReducer,
    favorites: favoriteReducer,
    filters: filterReducer,
    guestToken: guestTokenReducer,
    weddingProfile: weddingProfileReducer,
  },
});

export default store;
