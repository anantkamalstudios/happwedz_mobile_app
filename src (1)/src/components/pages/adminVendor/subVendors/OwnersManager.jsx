import React, { useState } from "react";
import { Modal, Button, Form, Card, Row, Col } from "react-bootstrap";

export default function OwnersManager() {
  const [show, setShow] = useState(false);
  const [owners, setOwners] = useState([]);
  const [form, setForm] = useState({
    username: "",
    lastName: "",
    email: "",
    position: "",
    bio: "",
    image: null,
  });

  const openModal = () => {
    setForm({
      username: "",
      lastName: "",
      email: "",
      position: "",
      bio: "",
      image: null,
    });
    setShow(true);
  };

  const handleChange = (e) => {
    const { name, value, files } = e.target;
    setForm((prev) => ({
      ...prev,
      [name]: files ? files[0] : value,
    }));
  };

  const handleSave = () => {
    setOwners([...owners, { id: Date.now(), ...form }]);
    setShow(false);
  };

  return (
    <div className="p-4">
      <Button
        variant="primary"
        style={{
          background: "linear-gradient(to right, #ff6a88, #ff99ac)",
          border: "1px solid white",
        }}
        onClick={openModal}
      >
        Create New Event
      </Button>

      {/* Modal */}
      <Modal show={show} onHide={() => setShow(false)} size="lg" centered>
        <Modal.Header closeButton>
          <Modal.Title>Add New Member</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Form.Group className="mb-3">
              <Form.Label>Username *</Form.Label>
              <Form.Control
                name="username"
                value={form.username}
                onChange={handleChange}
                placeholder="Enter username"
                required
              />
            </Form.Group>

            <Form.Group className="mb-3">
              <Form.Label>Last Name</Form.Label>
              <Form.Control
                name="lastName"
                value={form.lastName}
                onChange={handleChange}
                placeholder="Enter last name"
              />
            </Form.Group>

            <Form.Group className="mb-3">
              <Form.Label>Email</Form.Label>
              <Form.Control
                type="email"
                name="email"
                value={form.email}
                onChange={handleChange}
                placeholder="Enter email"
              />
            </Form.Group>

            <Form.Group className="mb-3">
              <Form.Label>Position *</Form.Label>
              <Form.Control
                name="position"
                value={form.position}
                onChange={handleChange}
                placeholder="Enter position"
                required
              />
            </Form.Group>

            <Form.Group className="mb-3">
              <Form.Label>Bio *</Form.Label>
              <Form.Control
                as="textarea"
                rows={3}
                name="bio"
                value={form.bio}
                onChange={handleChange}
                placeholder="Enter bio"
                required
              />
            </Form.Group>

            <Form.Group className="mb-3">
              <Form.Label>Image</Form.Label>
              <Form.Control
                type="file"
                name="image"
                accept="image/*"
                onChange={handleChange}
              />
            </Form.Group>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={() => setShow(false)}>
            Cancel
          </Button>
          <Button variant="primary" onClick={handleSave}>
            Save Member
          </Button>
        </Modal.Footer>
      </Modal>

      {/* Preview */}
      <div className="mt-4">
        {owners.map((owner) => (
          <Card key={owner.id} className="mb-3 shadow-sm">
            <Card.Body className="d-flex justify-content-between align-items-center">
              <div>
                <h6 className="mb-1">
                  {owner.username} {owner.lastName}
                </h6>
                <small className="text-muted">{owner.position}</small>
                <div>{owner.email}</div>
                <p className="mb-0">{owner.bio}</p>
              </div>
              {owner.image && (
                <img
                  src={URL.createObjectURL(owner.image)}
                  alt="preview"
                  style={{
                    width: "60px",
                    height: "60px",
                    objectFit: "cover",
                    borderRadius: "6px",
                  }}
                />
              )}
            </Card.Body>
          </Card>
        ))}
      </div>
    </div>
  );
}
