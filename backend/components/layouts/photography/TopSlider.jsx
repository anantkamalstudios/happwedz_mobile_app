import React, { useContext, useEffect, useState } from "react";
import { Swiper, SwiperSlide } from "swiper/react";
import { Autoplay, Navigation } from "swiper/modules";
import "swiper/css";
import "swiper/css/navigation";
import { IMAGE_BASE_URL } from "../../../config/constants";
import usePhotography from "../../../hooks/usePhotography";
import { MyContext } from "../../../context/useContext";

const TopSlider = ({ onCategorySelect, onPhotosFetched }) => {
  const {
    types,
    fetchTypes,
    fetchAllPhotos,
    fetchPhotosByType,
    loading,
    error,
  } = usePhotography();

  const [categories, setCategories] = useState([]);
  const { setSelectedCategory, setSelectedCategoryName } =
    useContext(MyContext);

  useEffect(() => {
    const loadCategories = async () => {
      await fetchTypes();
    };
    loadCategories();
  }, []);

  useEffect(() => {
    if (types && Array.isArray(types)) {
      setCategories(types);
    }
  }, [types]);

  const handleCategoryClick = async (category) => {
    onCategorySelect?.(category.id || "all", category.name || "All");

    if (category.name === "all") {
      const data = await fetchAllPhotos();
      onPhotosFetched?.(data);
    } else {
      const data = await fetchPhotosByType(category.id);
      onPhotosFetched?.(data);
    }
  };

  if (loading)
    return (
      <div className="text-center my-5">
        <p>Loading categories...</p>
      </div>
    );

  if (error)
    return (
      <div className="text-center my-5 text-danger">
        <p>Failed to load categories.</p>
      </div>
    );

  return (
    <div className="container px-3 py-2 my-5">
      <Swiper
        slidesPerView="auto"
        spaceBetween={10}
        navigation={true}
        loop={true}
        autoplay={{
          delay: 2500,
          disableOnInteraction: false,
        }}
        modules={[Navigation, Autoplay]}
        className="category-swiper"
      >
        <SwiperSlide style={{ width: "auto" }}>
          <div
            className="category-wrapper"
            onClick={() => handleCategoryClick({ name: "all" })}
            style={{ cursor: "pointer" }}
          >
            <img
              src="./images/photography-all.png"
              alt="All"
              className="category-image mx-auto d-block mb-2"
              style={{
                width: "150px",
                height: "80px",
                objectFit: "cover",
                borderRadius: "0.25rem",
              }}
            />
          </div>
          <span
            className="d-flex justify-content-around text-center"
            style={{ fontSize: "14px" }}
          >
            All
          </span>
        </SwiperSlide>

        {categories.map((cat) => (
          <SwiperSlide key={cat.id} style={{ width: "auto" }}>
            <div
              className="category-wrapper"
              onClick={() => handleCategoryClick(cat)}
              style={{ cursor: "pointer" }}
            >
              <img
                src={`${IMAGE_BASE_URL}${cat.hero_image}`}
                alt={cat.name}
                className="category-image mx-auto d-block mb-2"
                style={{
                  width: "150px",
                  height: "80px",
                  objectFit: "cover",
                  borderRadius: "0.25rem",
                }}
              />
            </div>
            <span
              className="d-flex justify-content-around text-center"
              style={{ fontSize: "14px" }}
            >
              {cat.name}
            </span>
          </SwiperSlide>
        ))}
      </Swiper>
    </div>
  );
};

export default TopSlider;
