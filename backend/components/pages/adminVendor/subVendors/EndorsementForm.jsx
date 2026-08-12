import React, { useState } from "react";
import { Button, Card, Form, ListGroup } from "react-bootstrap";
export default function EndorsementForm() {
  const allVendors = [
    {
      name: "Music Lovers Musical Group, Kanpur",
      category: "Wedding Music",
      location: "Barra",
    },
    {
      name: "Royal Beats Orchestra, Delhi",
      category: "Wedding Music",
      location: "Connaught Place",
    },
    {
      name: "Golden Strings Band, Mumbai",
      category: "Wedding Music",
      location: "Andheri",
    },
    {
      name: "Elegant Decorators, Jaipur",
      category: "Wedding Decor",
      location: "Bapu Bazaar",
    },
    {
      name: "Delight Caterers, Pune",
      category: "Wedding Catering",
      location: "Shivaji Nagar",
    },
  ];

  const [vendors, setVendors] = useState([]);
  const [vendorInput, setVendorInput] = useState("");
  const [suggestions, setSuggestions] = useState([]);

  // Handle typing → show suggestions
  const handleInputChange = (e) => {
    const value = e.target.value;
    setVendorInput(value);

    if (value.trim()) {
      const filtered = allVendors.filter((v) =>
        v.name.toLowerCase().includes(value.toLowerCase())
      );
      setSuggestions(filtered);
    } else {
      setSuggestions([]);
    }
  };

  // Add vendor from suggestion click
  const handleAddVendor = (vendor) => {
    setVendors([...vendors, { id: Date.now(), ...vendor }]);
    setVendorInput("");
    setSuggestions([]);
  };

  const handleRemove = (id) => {
    setVendors(vendors.filter((v) => v.id !== id));
  };

  return (
    <div style={{ maxWidth: "600px", margin: "auto" }}>
      {/* Input Field */}
      <Form className="mb-3 position-relative">
        <Form.Control
          type="text"
          placeholder="Enter vendor name"
          value={vendorInput}
          onChange={handleInputChange}
        />
        {/* Suggestions Dropdown */}
        {suggestions.length > 0 && (
          <ListGroup
            style={{
              position: "absolute",
              width: "100%",
              zIndex: 1000,
            }}
          >
            {suggestions.map((v, i) => (
              <ListGroup.Item key={i} action onClick={() => handleAddVendor(v)}>
                <strong>{v.name}</strong>
                <br />
                <small className="text-muted">
                  {v.category} • {v.location}
                </small>
              </ListGroup.Item>
            ))}
          </ListGroup>
        )}
      </Form>

      {/* Preview Cards */}
      {vendors.map((vendor) => (
        <Card key={vendor.id} className="mb-2 shadow-sm">
          <Card.Body className="d-flex justify-content-between align-items-center">
            <div>
              <h6 className="mb-1">{vendor.name}</h6>
              <small className="text-muted">{vendor.category}</small>
              <div>{vendor.location}</div>
            </div>
            <Button
              variant="outline-danger"
              size="sm"
              onClick={() => handleRemove(vendor.id)}
            >
              Remove
            </Button>
          </Card.Body>
        </Card>
      ))}
    </div>
  );
}
