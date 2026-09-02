import React, { useState } from "react";
import { Form, Row, Col } from "react-bootstrap";

const LocationForm = () => {
  const [formData, setFormData] = useState({
    pincode: "",
    city: "",
    country: "",
    address: "",
  });

  // Build full address string
  const fullAddress =
    `${formData.address} ${formData.city} ${formData.pincode} ${formData.country}`.trim();

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  return (
    <div className="container py-4">
      <h4 className="mb-4 fw-bold">Location & Map</h4>

      <Form className="bg-white p-4 rounded shadow-sm border">
        <Row className="mb-3">
          <Col md={6}>
            <Form.Group>
              <Form.Label className="fw-semibold fs-16">Pin Code *</Form.Label>
              <Form.Control
                type="text"
                name="pincode"
                placeholder="Enter pin code"
                value={formData.pincode}
                onChange={handleChange}
                className="py-2 fs-14"
              />
            </Form.Group>
          </Col>

          <Col md={6}>
            <Form.Group>
              <Form.Label className="fw-semibold fs-16">
                City / Town *
              </Form.Label>
              <Form.Control
                type="text"
                name="city"
                placeholder="Enter city or town"
                value={formData.city}
                onChange={handleChange}
                className="py-2 fs-14"
              />
            </Form.Group>
          </Col>
        </Row>

        <Row className="mb-3">
          <Col md={6}>
            <Form.Group>
              <Form.Label className="fw-semibold fs-16">Country *</Form.Label>
              <Form.Control
                type="text"
                name="country"
                placeholder="Enter country"
                value={formData.country}
                onChange={handleChange}
                className="py-2 fs-14"
              />
            </Form.Group>
          </Col>

          <Col md={6}>
            <Form.Group>
              <Form.Label className="fw-semibold fs-16">Address *</Form.Label>
              <Form.Control
                type="text"
                name="address"
                placeholder="Enter full address"
                value={formData.address}
                onChange={handleChange}
                className="py-2 fs-14"
              />
            </Form.Group>
          </Col>
        </Row>
      </Form>

      {/* Map Section */}
      {fullAddress && (
        <div className="mt-4">
          <h6 className="fw-semibold fs-16 mb-3">Map Preview</h6>
          <div
            className="border rounded overflow-hidden"
            style={{ height: "350px" }}
          >
            <iframe
              src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d154819.57911786763!2d73.72108005921297!3d19.991105338148124!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3bddd290b09914b3%3A0xcb07845d9d28215c!2sNashik%2C%20Maharashtra!5e1!3m2!1sen!2sin!4v1754995966557!5m2!1sen!2sin"
              title="Google Map"
              width="100%"
              height="100%"
              style={{ border: 0 }}
              loading="lazy"
              allowFullScreen
              referrerpolicy="no-referrer-when-downgrade"
            ></iframe>
            {/* <iframe
              title="Google Map"
              width="100%"
              height="100%"
              style={{ border: 0 }}
              loading="lazy"
              allowFullScreen
              src={`https://www.google.com/maps/embed/v1/place?key=YOUR_GOOGLE_MAPS_API_KEY&q=${encodeURIComponent(
                fullAddress
              )}`}
            ></iframe> */}
          </div>
        </div>
      )}
      <button className="btn btn-primary mt-2 folder-item fs-14">Submit</button>
    </div>
  );
};

export default LocationForm;
