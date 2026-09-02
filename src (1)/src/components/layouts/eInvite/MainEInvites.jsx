import React, { useState } from "react";
import { Swiper, SwiperSlide } from "swiper/react";
import { Autoplay } from "swiper/modules";
import "swiper/css";

import EInviteCard from "./EInviteCard";

const sampleData = [
  {
    image:
      "https://image.wedmegood.com/e-invite-images/ec553b5f-80da-4228-8ff5-7ead0cd50b73-Cover.JPEG",
    title: "Royal Garden",
    price: 499,
  },
  {
    image:
      "https://image.wedmegood.com/e-invite-images/ec553b5f-80da-4228-8ff5-7ead0cd50b73-Cover.JPEG",
    title: "Palace Theme",
    price: 599,
  },
  {
    image:
      "https://image.wedmegood.com/e-invite-images/ec553b5f-80da-4228-8ff5-7ead0cd50b73-Cover.JPEG",
    title: "Floral Mandap",
    price: 399,
  },
  {
    image:
      "https://image.wedmegood.com/e-invite-images/ec553b5f-80da-4228-8ff5-7ead0cd50b73-Cover.JPEG",
    title: "Pink Curtain",
    price: 499,
  },
  {
    image:
      "https://image.wedmegood.com/e-invite-images/ec553b5f-80da-4228-8ff5-7ead0cd50b73-Cover.JPEG",
    title: "Fairy Night",
    price: 699,
  },
];

const CardSlider = ({ title, data }) => {
  const [activeIndex, setActiveIndex] = useState(0);

  return (
    <div className="wrapper-einvites my-5">
      <h1 className="einvite-title">{title}</h1>

      <Swiper
        spaceBetween={30}
        loop={true}
        autoplay={{
          delay: 2500,
          disableOnInteraction: false,
        }}
        onSwiper={(swiper) => setActiveIndex(swiper.activeIndex)}
        onSlideChange={(swiper) => setActiveIndex(swiper.activeIndex)}
        breakpoints={{
          0: { slidesPerView: 1 },
          576: { slidesPerView: 2 },
          768: { slidesPerView: 3 },
          992: { slidesPerView: 4 },
        }}
        modules={[Autoplay]}
      >
        {data.map((item, idx) => (
          <SwiperSlide key={idx}>
            <EInviteCard {...item} zoom={idx === activeIndex} />
          </SwiperSlide>
        ))}
      </Swiper>

      <div className="view-all-wrapper">
        <button className="view-all-button detailed-btn-hover-pink">
          View All
        </button>
      </div>
    </div>
  );
};

const MainEInvites = () => {
  return (
    <div className="container">
      <CardSlider title="Wedding E-Invitations" data={sampleData} />
      <CardSlider title="Save The Date" data={sampleData} />
      <CardSlider title="Wedding Videos" data={sampleData} />
    </div>
  );
};

export default MainEInvites;
