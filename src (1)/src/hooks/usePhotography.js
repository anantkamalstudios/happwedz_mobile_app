import { useState, useEffect } from "react";
import {
  getPhotographyTypes,
  getPhotographyCategories,
  getPhotographyTypesWithCategories,
  getPhotographyById,
  getAllPhotography,
  getPhotographyByType,
  getPhotographyByCategory,
} from "../services/api/photographyApi";

const usePhotography = () => {
  const [types, setTypes] = useState([]);
  const [categories, setCategories] = useState([]);
  const [typesWithCategories, setTypesWithCategories] = useState([]);
  const [photo, setPhoto] = useState(null);
  const [allPhotos, setAllPhotos] = useState([]);
  const [photosByType, setPhotosByType] = useState([]);
  const [photosByCategory, setPhotosByCategory] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetchTypes = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await getPhotographyTypes();
      setTypes(data);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchCategories = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await getPhotographyCategories();
      setCategories(data);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchTypesWithCategories = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await getPhotographyTypesWithCategories();
      setTypesWithCategories(data);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchPhotoById = async (id) => {
    setLoading(true);
    setError(null);
    try {
      const data = await getPhotographyById(id);
      setPhoto(data);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchAllPhotos = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await getAllPhotography();
      setAllPhotos(data.data);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  return {
    types,
    categories,
    typesWithCategories,
    photo,
    allPhotos,
    photosByType,
    photosByCategory,
    loading,
    error,
    fetchTypes,
    fetchCategories,
    fetchTypesWithCategories,
    fetchPhotoById,
    fetchAllPhotos,
    fetchPhotosByType: async (id) => {
      setLoading(true);
      setError(null);
      try {
        const data = await getPhotographyByType(id);
        setPhotosByType(data.data);
      } catch (err) {
        setError(err);
      } finally {
        setLoading(false);
      }
    },
    fetchPhotosByCategory: async (id, city) => {
      setLoading(true);
      setError(null);
      try {
        const data = await getPhotographyByCategory(id, city);
        setPhotosByCategory(data.data || data);
      } catch (err) {
        setError(err);
      } finally {
        setLoading(false);
      }
    },
  };
};

export default usePhotography;
