import { useState } from "react";
import { movmentPlusApi } from "../services/api";

const useMovmentPlus = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [data, setData] = useState(null);

  const fetchGalleryByToken = async (token) => {
    setLoading(true);
    setError(null);
    try {
      const response = await movmentPlusApi.getGalleryByToken(token);
      setData(response);
      return response;
    } catch (err) {
      setError(err);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const uploadFile = async (token, collectionName, file) => {
    setLoading(true);
    setError(null);
    try {
      const response = await movmentPlusApi.uploadFile(
        token,
        collectionName,
        file,
      );
      // Optimistically update data or re-fetch?
      // For now, let's just return response. The caller can decide to re-fetch.
      return response;
    } catch (err) {
      setError(err);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const uploadSelfie = async ({ token, file, userId }) => {
    setLoading(true);
    setError(null);
    try {
      return await movmentPlusApi.uploadSelfie({ token, file, userId });
    } catch (err) {
      setError(err);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const fetchMyPhotos = async ({ token, userId }) => {
    setLoading(true);
    setError(null);
    try {
      return await movmentPlusApi.getMyPhotos({ token, userId });
    } catch (err) {
      setError(err);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return {
    fetchGalleryByToken,
    uploadFile,
    uploadSelfie,
    fetchMyPhotos,
    loading,
    error,
    data,
  };
};

export default useMovmentPlus;
