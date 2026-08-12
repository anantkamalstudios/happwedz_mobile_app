import axiosInstance from "./axiosInstance";

export const movmentPlusApi = {
  getGalleryByToken: async (token) => {
    const response = await axiosInstance.get(`/gallery/${token}`);
    return response.data;
  },

  uploadFile: async (token, collectionName, file) => {
    const formData = new FormData();
    formData.append("file", file);
    formData.append("collection", collectionName);

    // Placeholder endpoint - verify with backend team
    const response = await axiosInstance.post(
      `/gallery/${token}/upload`,
      formData,
      {
        headers: {
          "Content-Type": "multipart/form-data",
        },
      },
    );
    return response.data;
  },
};
