import React from "react";
import { Swiper, SwiperSlide } from "swiper/react";
import { Autoplay, Navigation } from "swiper/modules";
import { useNavigate } from "react-router-dom";
import { useDispatch } from "react-redux";
import { setLocation } from "../../../redux/locationSlice";
import "swiper/css";
import useRegions from "../../../hooks/useRegions";
import ShimmerRegion from "../../ui/ShimmerRegion";
import ErrorState from "../../ui/ErrorState";

const MainByRegion = ({ type }) => {
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { regions, loading, error, refetch } = useRegions(
    type === "venues" ? "venues" : null
  );

  const handleRegionClick = (regionName) => {
    dispatch(setLocation(regionName));

    const cityParam = `city=${encodeURIComponent(regionName)}`;
    if (type === "venues") {
      navigate(`/venues/all?vendorType=venues&${cityParam}`);
    } else {
      navigate(`/vendors/all?${cityParam}`);
    }
  };

  if (loading) return <ShimmerRegion />;
  if (error)
    return (
      <ErrorState
        title="We couldn’t load popular regions"
        message={error.message || "Please try again later."}
        onRetry={refetch}
      />
    );
  if (!regions || regions.length === 0) {
    return null;
  }

  return (
    <div className="container">
      <div className="venue-region-section px-4 my-5">
        <h3 className="fw-bold mb-0 text-dark mb-3">
          {type === "Venues" ? "Venues" : "Vendors"} By Region
        </h3>

        <Swiper
          modules={[Navigation, Autoplay]}
          spaceBetween={10}
          slidesPerView={6.2}
          autoplay={{
            delay: 3000,
            disableOnInteraction: false,
          }}
          loop={true}
          breakpoints={{
            320: { slidesPerView: 2.5, spaceBetween: 6 },
            576: { slidesPerView: 3.5, spaceBetween: 6 },
            768: { slidesPerView: 4.5, spaceBetween: 6 },
            992: { slidesPerView: 5.5, spaceBetween: 8 },
            1200: { slidesPerView: 6.2, spaceBetween: 8 },
          }}
        >
          {regions.map((region) => (
            <SwiperSlide key={region.id}>
              <div
                className="text-center region-slide-card cursor-pointer"
                onClick={() => handleRegionClick(region.name)}
                style={{ cursor: "pointer" }}
              >
                <div className="region-slide-card">
                  <div className="region-img-wrapper mb-2">
                    <img
                      src={region.image}
                      alt={region.name}
                      className="region-img"
                    />
                  </div>
                </div>
                <div className="region-title fw-medium fs-16">
                  {region.name}
                </div>
                <div className="text-muted fs-14">
                  {region.venueCount} {type === "venues" ? "Venues" : "Vendors"}
                </div>
              </div>
            </SwiperSlide>
          ))}
        </Swiper>
      </div>
    </div>
  );
};

export default MainByRegion;
