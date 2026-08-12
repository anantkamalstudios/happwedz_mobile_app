import React from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import "./LocationCard.css";
import { useNavigate } from "react-router-dom";
import RomeImg from "../../../assets/travelsCity/Rome.webp";
import ParisImg from "../../../assets/travelsCity/Paris.webp";
import LondonImg from "../../../assets/travelsCity/London.webp";
import NewYorkImg from "../../../assets/travelsCity/New York City.webp";
import DubaiImg from "../../../assets/travelsCity/Dubai.webp";
import BarcelonaImg from "../../../assets/travelsCity/Barcelona.webp";

const TravelCards = () => {
  const navigate = useNavigate();

  const handleCityClick = (cityName) => {
    navigate(`/travels/${cityName}`);
  };

  const destinations = [
    {
      id: 1,
      name: "Rome",
      image: RomeImg,
    },
    {
      id: 2,
      name: "Paris",
      image: ParisImg,
    },
    {
      id: 3,
      name: "London",
      image: LondonImg,
    },
    {
      id: 4,
      name: "New York City",
      image: NewYorkImg,
    },
    {
      id: 5,
      name: "Dubai",
      image: DubaiImg,
    },
    {
      id: 6,
      name: "Barcelona",
      image: BarcelonaImg,
    },
  ];

  return (
    <div className="container-fluid py-5 bg-light">
      <div className="container">
        <h2
          className="mb-5 fw-bold"
          style={{ fontSize: "16px", color: "#0a1f3b" }}
        >
          Things to do wherever you're going
        </h2>

        <div className="row g-4">
          {destinations.map((destination) => (
            <div
              key={destination.id}
              className="col-lg-2 col-md-3 col-sm-4 col-6"
            >
              <div
                className="travel-card h-100"
                onClick={() => handleCityClick(destination.name)}
              >
                <img
                  src={destination.image}
                  alt={destination.name}
                  className="travel-card-image"
                />

                <div className="travel-card-label">
                  <span className="badge-text">{destination.name}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default TravelCards;
