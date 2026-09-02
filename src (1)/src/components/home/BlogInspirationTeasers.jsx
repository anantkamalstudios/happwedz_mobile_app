import React, { useState, useEffect } from "react";
import { Swiper, SwiperSlide } from "swiper/react";
import { Navigation, Autoplay } from "swiper/modules";
import "swiper/css";
import "swiper/css/navigation";
import axios from "axios";
import { FiArrowUpRight } from "react-icons/fi";
import { Link, useNavigate } from "react-router-dom";
import { formatDate } from "../../utils/dateFormat";

const BlogsCarousel = () => {
  const [blogs, setBlogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeIndex, setActiveIndex] = useState(0);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchBlogs = async () => {
      try {
        const apiBase = import.meta.env.VITE_API_URL || "https://happywedz.com/api";
        const response = await fetch(`${apiBase}/blogs/all`);
        const result = await response.json();

        // Map API fields to component fields
        const mappedBlogs = result.data.map((blog) => {
          const cleanedImageUrl = blog.image.replace(
            "https://happywedz.com:4000",
            "https://happywedzbackend.happywedz.com/"
          );

          return {
            id: blog.id,
            title: blog.title,
            desc: blog.shortDescription,
            category: "Blog",
            img: cleanedImageUrl,
            author: blog.author,
            authorImg: "./images/no-image.png",
            date: formatDate(blog.postDate),
            tags: [],
          };
        });

        setBlogs(mappedBlogs);
        setLoading(false);
      } catch (error) {
        console.error("Error fetching blog details:", error);
        setLoading(false);
      }
    };

    fetchBlogs();
  }, []);

  return (
    <div className="blogs-carousel-wrapper py-5 px-3">
      <div className="container position-relative">
        <div className="text-center mb-1">
          <img loading="lazy" decoding="async"
            src="/images/home/inspiredTeaser.png"
            alt="inspiredTeaser"
            className="w-20 h-20"
          />
          <h3 className="blogs-carousel-heading fw-bold mb-2 fs-26 primary-text">
            Inspiration Teasers
          </h3>
          <h6 className=" mb-3" data-aos="fade-up" data-aos-delay="50">
            Discover the latest trends, tips, and real wedding stories
          </h6>
        </div>

        <Swiper
          slidesPerView={1}
          spaceBetween={24}
          navigation={{
            nextEl: ".blogs-carousel-next",
            prevEl: ".blogs-carousel-prev",
          }}
          modules={[Navigation, Autoplay]}
          autoplay={{ delay: 5000, disableOnInteraction: false }}
          breakpoints={{
            576: { slidesPerView: 2 },
            992: { slidesPerView: 3 },
          }}
          onSlideChange={(swiper) => setActiveIndex(swiper.realIndex)}
          className="blogs-swiper"
        >
          {blogs.map((blog, i) => (
            <SwiperSlide key={i}>
              <div
                className="blogs-card p-2 m-2"
                style={{
                  height: "550px",
                  borderRadius: "0",
                  cursor: "pointer",
                }}
                onClick={() => navigate(`/blog/${blog.id}`)}
              >
                {/* Image */}
                <div className="blogs-card-image p-2">
                  <img loading="lazy" decoding="async"
                    src={blog.img}
                    alt={blog.title}
                    style={{
                      width: "100%",
                      maxHeight: "500px",
                      objectFit: "contain",
                    }}
                  />
                </div>

                {/* Content */}
                <div className="blogs-card-content">
                  <div className="d-flex align-items-center justify-content-between">
                    <span className="blogs-category">{blog.category}</span>
                    <FiArrowUpRight size={20} className="blogs-title-icon" />
                  </div>
                  <h5 className="blogs-title fs-16">{blog.title}</h5>
                  <p className="blogs-desc fs-14">
                    {blog.desc && blog.desc.length > 120
                      ? blog.desc.slice(0, 120) + "..."
                      : blog.desc}
                  </p>

                  <div className="mt-auto">
                    <div className="d-flex align-items-center">
                      <img loading="lazy" decoding="async"
                        src={
                          blog.authorImg && blog.authorImg.trim() !== ""
                            ? blog.authorImg
                            : "./images/no-image.png"
                        }
                        alt={blog.author}
                        className="rounded-circle me-3"
                        width="40"
                        height="40"
                      />
                      <div className="d-flex flex-column">
                        <span className="fw-semibold text-dark fs-14">
                          {blog.author}
                        </span>
                        <small className="text-muted fs-12">{blog.date}</small>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </SwiperSlide>
          ))}
        </Swiper>
      </div>
    </div>
  );
};

export default BlogsCarousel;
