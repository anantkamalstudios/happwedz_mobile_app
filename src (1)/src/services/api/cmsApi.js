import axios from "axios";

const API_BASE_URL =
  import.meta.env.VITE_API_URL || "https://happywedz.com/api/";

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
  },
});

export const designStudioBannerApi = {
  getBanner: async () => {
    const response = await api.get("/design-studio-banner");
    return response.data;
  },
};

export const einviteBannerApi = {
  getBanner: async () => {
    const response = await api.get("/einvite-banner");
    return response.data;
  },
};

export const realWeddingPhotoApi = {
  getData: async () => {
    const response = await api.get("/real-wedding-photo-cms");
    return response.data;
  },
};

export const whatCouplesSaysApi = {
  getData: async () => {
    const response = await api.get("/what-couples-says-route");
    return response.data;
  },
};

export const loginCmsApi = {
  getLoginCms: async () => {
    const response = await api.get("/login-cms");
    return response.data;
  },
};

export const signInCmsApi = {
  getSignInCms: async () => {
    const response = await api.get("/sign-in-cms");
    return response.data;
  },
};

export const cmsApi = {
  designStudioBanner: designStudioBannerApi,
  einviteBanner: einviteBannerApi,
  realWeddingPhoto: realWeddingPhotoApi,
  whatCouplesSays: whatCouplesSaysApi,
  loginCms: loginCmsApi,
  signInCms: signInCmsApi,
};

export default cmsApi;
