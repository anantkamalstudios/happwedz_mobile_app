import { createContext, useState, useEffect } from "react";
import usePhotography from "../hooks/usePhotography";

export const MyContext = createContext(null);

export const MyProvider = ({ children }) => {
  const {
    fetchAllPhotos,
    fetchPhotosByType,
    allPhotos,
    photosByType,
    types,
    fetchTypes,
    loading,
  } = usePhotography();

  const [selectedCategory, setSelectedCategory] = useState("all");
  const [selectedCategoryName, setSelectedCategoryName] = useState("All");
  const [displayPhotos, setDisplayPhotos] = useState([]);
  const [sortBy, setSortBy] = useState("recent");

  useEffect(() => {
    fetchTypes();
  }, []);

  useEffect(() => {
    const loadPhotos = async () => {
      if (selectedCategory === "all") {
        await fetchAllPhotos();
      } else {
        await fetchPhotosByType(selectedCategory);
      }
    };
    loadPhotos();
  }, [selectedCategory]);

  useEffect(() => {
    let photos = [];
    if (selectedCategory === "all") {
      photos = allPhotos || [];
    } else {
      photos = photosByType || [];
    }

    if (sortBy === "recent" && photos.length > 0) {
      photos = [...photos].sort((a, b) => {
        const dateA = new Date(a.createdAt);
        const dateB = new Date(b.createdAt);
        return dateB - dateA;
      });
    }

    setDisplayPhotos(photos);
  }, [allPhotos, photosByType, selectedCategory, sortBy]);

  return (
    <MyContext.Provider
      value={{
        selectedCategory,
        setSelectedCategory,
        selectedCategoryName,
        setSelectedCategoryName,
        displayPhotos,
        types,
        loading,
        sortBy,
        setSortBy,
      }}
    >
      {children}
    </MyContext.Provider>
  );
};
