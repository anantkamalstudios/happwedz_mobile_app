import React from "react";
import VenueCard from "../venus/VenueCard";
import { Container, Row, Col, Form, Button } from "react-bootstrap";
import { IoIosArrowForward } from "react-icons/io";

const VendorsHeroSection = ({ loc }) => {
  const venues = [
    {
      id: 1,
      name: "Taj Krishna",
      location: "Banjara Hills, Hyderabad",
      capacity: 500,
      price: "1,50,000",
      image:
        "https://cdn0.weddingwire.in/vendor/5401/3_2/640/jpg/a7c44b20-d031-484c-93ea-5ec86b69e7d8-768x576_15_485401-175084621555758.webp",
    },
    {
      id: 2,
      name: "Falaknuma Palace",
      location: "Falaknuma, Hyderabad",
      capacity: 1000,
      price: "5,00,000",
      image:
        "https://cdn0.weddingwire.in/vendor/8156/3_2/640/jpg/dsc00517_15_488156-174713425574582.webp",
    },
    {
      id: 3,
      name: "Novotel Hyderabad",
      location: "HITEC City, Hyderabad",
      capacity: 800,
      price: "2,00,000",
      image:
        "https://cdn0.weddingwire.in/vendor/0545/3_2/640/jpeg/img-6487_15_480545-172717340473463.webp",
    },
  ];

  return (
    <Container className="my-5">
      <h1 className="mb-4 text-center text-dark fw-bold">
        Wedding Venues in {loc}
      </h1>

      <Row xs={1} md={2} lg={3} className="g-4">
        {venues.map((venue) => (
          <Col key={venue.id}>
            <VenueCard venue={venue} />
          </Col>
        ))}
      </Row>

      <div className="text-center mt-5">
        <button className="btn border border-secondary rounded wedding-btn">
          Discover 758 venues in Bangalore <IoIosArrowForward />
        </button>
      </div>
    </Container>
  );
};

export default VendorsHeroSection;
