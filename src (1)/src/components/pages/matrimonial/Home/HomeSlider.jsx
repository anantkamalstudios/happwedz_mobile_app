import React from "react";
import "../../../../Matrimonial.css";
import { Swiper, SwiperSlide } from "swiper/react";
import { Autoplay, Navigation, Pagination } from "swiper/modules";
import "swiper/css";
import "swiper/css/navigation";
import "swiper/css/pagination";

const HomeSlider = () => {
  const successStories = [
    {
      id: 1,
      name: "Raj & Priya",
      date: "Mar 2023",
      location: "Mumbai, Maharashtra",
      img: "https://images.unsplash.com/photo-1519741497674-611481863552?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",
    },
    {
      id: 2,
      name: "Amit & Neha",
      date: "Jan 2023",
      location: "Delhi, NCR",
      img: "https://images.unsplash.com/photo-1684318552406-d2d9c0ca3525?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTB8fG1hdHJpbW9uaWFsfGVufDB8fDB8fHww",
    },
    {
      id: 3,
      name: "Vikram & Anjali",
      date: "Dec 2022",
      location: "Bangalore, Karnataka",
      img: "https://images.unsplash.com/photo-1519225421980-715cb0215aed?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",
    },
    {
      id: 4,
      name: "Sanjay & Meera",
      date: "Oct 2022",
      location: "Chennai, Tamil Nadu",
      img: "https://images.unsplash.com/photo-1519741497674-611481863552?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80",
    },
    {
      id: 5,
      name: "Rahul & Shreya",
      date: "Aug 2022",
      location: "Hyderabad, Telangana",
      img: "https://images.unsplash.com/photo-1654413285620-12c2a8e1f6dd?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTJ8fG1hdHJpbW9uaWFsfGVufDB8fDB8fHww",
    },
    {
      id: 6,
      name: "Arjun & Pooja",
      date: "Jun 2022",
      location: "Pune, Maharashtra",
      img: "https://images.unsplash.com/photo-1650919997970-7f512398bb66?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8bWF0cmltb25pYWx8ZW58MHx8MHx8fDA%3D",
    },
  ];

  return (
    <section className="success-stories-section">
      <div className="container">
        <div className="section-header text-center mb-5">
          <h2 className="section-title">Success Stories</h2>
          <p className="section-subtitle">
            Real couples who found their perfect match through our platform
          </p>
        </div>

        <div className="success-stories-slider">
          <Swiper
            modules={[Autoplay, Navigation, Pagination]}
            autoplay={{
              delay: 4000,
              disableOnInteraction: false,
              pauseOnMouseEnter: true,
            }}
            loop={true}
            spaceBetween={30}
            slidesPerView={3}
            centeredSlides={false}
            grabCursor={true}
            breakpoints={{
              320: {
                slidesPerView: 1,
                spaceBetween: 20,
              },
              640: {
                slidesPerView: 2,
                spaceBetween: 25,
              },
              1024: {
                slidesPerView: 3,
                spaceBetween: 30,
              },
            }}
            className="success-stories-swiper"
          >
            {successStories.map((story) => (
              <SwiperSlide key={story.id}>
                <div className="success-story-card">
                  <div className="card-image-container">
                    <img
                      src={story.img}
                      alt={`${story.name} wedding`}
                      className="card-image"
                    />
                    <div className="card-overlay">
                      <div className="overlay-content">
                        <span className="view-story">View Story</span>
                      </div>
                    </div>
                  </div>

                  <div className="card-content">
                    <div className="couple-info">
                      <h4 className="couple-name">{story.name}</h4>
                      <p className="wedding-date">Married: {story.date}</p>
                      <p className="wedding-location">{story.location}</p>
                    </div>

                    <div className="card-actions">
                      <button className="btn-view-profile">View Profile</button>
                      <button className="btn-send-wish">Send Wish</button>
                    </div>
                  </div>
                </div>
              </SwiperSlide>
            ))}
          </Swiper>
        </div>
      </div>
    </section>
  );
};

export default HomeSlider;
