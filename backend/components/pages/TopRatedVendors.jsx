import React from "react";
import { Link } from "react-router-dom";

const TopRatedVendors = () => {
  const weddingLists = [
    {
      title: "20 Best Banquet halls in Chattarpur",
      subCategory: "Banquet Halls",
      city: "Chattarpur",
    },
    {
      title: "10 Best Farmhouses in Chattarpur",
      subCategory: "Farmhouses",
      city: "Chattarpur",
    },
    {
      title: "Best 20 Wedding Resorts in Gurgaon",
      subCategory: "Wedding Resorts",
      city: "Gurgaon",
    },
    {
      title: "10 Best poolside wedding venues in Delhi NCR",
      subCategory: "Poolside Wedding Venues",
      city: "Delhi NCR",
    },
    {
      title: "10 Best pre wedding venues in Delhi NCR",
      subCategory: "Pre Wedding Venues",
      city: "Delhi NCR",
    },
    {
      title: "20 Best banquet halls in Delhi NCR",
      subCategory: "Banquet Halls",
      city: "Delhi NCR",
    },
    {
      title: "10 Best 5 Star hotels in Delhi NCR for Weddings",
      subCategory: "5 Star Wedding Hotels",
      city: "Delhi NCR",
    },
    {
      title: "Best marriage halls in Bangalore",
      subCategory: "Marriage Halls",
      city: "Bangalore",
    },
    {
      title: "20 Best banquet halls in Mumbai",
      subCategory: "Banquet Halls",
      city: "Mumbai",
    },
    {
      title: "10 Best Terrace Wedding Venues in Delhi NCR",
      subCategory: "Terrace Wedding Venues",
      city: "Delhi NCR",
    },
    {
      title: "15 Best banquet halls in South delhi",
      subCategory: "Banquet Halls",
      city: "South Delhi",
    },
    {
      title: "Best Pre-wedding venues in Bangalore (Engagement / Sangeet)",
      subCategory: "Pre Wedding Venues",
      city: "Bangalore",
    },
  ];

  return (
    <div
      style={{
        padding: "40px",
      }}
    >
      <h4 className="fs-16">Top Rated Vendors Page</h4>
      <p className="fs-14" style={{ color: "gray" }}>
        Meet our top vendors famous in the various cities
      </p>
      <div
        style={{
          marginTop: "20px",
        }}
      >
        {weddingLists.map((item, index) => {
          const slugified = item.subCategory
            .toLowerCase()
            .replace(/\s+/g, "-")
            .replace(/[^a-z0-9-]/g, "");
          const to = `/venues/${slugified}`;
          return (
            <div
              key={index}
              style={{
                marginBottom: "10px",
              }}
            >
              <Link
                className="fs-14"
                to={to}
                state={{ city: item.city, minRating: 4 }}
                style={{ textDecoration: "none", color: "#C31162" }}
              >
                {item.title}
              </Link>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default TopRatedVendors;
