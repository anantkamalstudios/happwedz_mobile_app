import React, { useState } from "react";
import { Modal, Button, Form } from "react-bootstrap";

export default function Event() {
  const [events, setEvents] = useState([]);
  const [show, setShow] = useState(false);
  const [editingIndex, setEditingIndex] = useState(null);
  const [formData, setFormData] = useState({
    name: "",
    type: "",
    startDate: "",
    startTime: "",
    endDate: "",
    endTime: "",
    city: "",
    address: "",
    description: "",
    image: null,
    imagePreview: "",
  });

  const handleClose = () => setShow(false);
  const handleShow = () => setShow(true);

  const handleChange = (e) => {
    const { name, value, files } = e.target;
    if (name === "image" && files.length > 0) {
      setFormData({
        ...formData,
        image: files[0],
        imagePreview: URL.createObjectURL(files[0]),
      });
    } else {
      setFormData({ ...formData, [name]: value });
    }
  };

  const handleAddEvent = () => {
    setEditingIndex(null); // New event
    setFormData({
      name: "",
      type: "",
      startDate: "",
      startTime: "",
      endDate: "",
      endTime: "",
      city: "",
      address: "",
      description: "",
      image: null,
      imagePreview: "",
    });
    setShow(true);
  };

  const handleEditEvent = (index) => {
    setEditingIndex(index);
    setFormData(events[index]);
    setShow(true);
  };

  const handleDeleteEvent = (index) => {
    setEvents(events.filter((_, i) => i !== index));
  };

  const handleSaveEvent = () => {
    if (editingIndex !== null) {
      const updatedEvents = [...events];
      updatedEvents[editingIndex] = formData;
      setEvents(updatedEvents);
    } else {
      setEvents([...events, formData]);
    }
    setShow(false);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setEvents([...events, formData]);
    setFormData({
      name: "",
      type: "",
      startDate: "",
      startTime: "",
      endDate: "",
      endTime: "",
      city: "",
      address: "",
      description: "",
      image: null,
      imagePreview: "",
    });
    handleClose();
  };
  return (
    <>
      <Button
        variant="primary"
        style={{
          background: "linear-gradient(to right, #ff6a88, #ff99ac)",
          border: "1px solid white",
        }}
        onClick={() => setShow(true)}
      >
        Create New Event
      </Button>

      <Modal show={show} onHide={() => setShow(false)} size="xl" centered>
        <Modal.Header closeButton>
          <Modal.Title>
            {editingIndex !== null ? "Edit Event" : "Create New Event"}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form onSubmit={handleSubmit}>
            {/* Event Name */}
            <Form.Group className="mb-3">
              <Form.Label>Event name *</Form.Label>
              <Form.Control
                type="text"
                name="name"
                value={formData.name}
                onChange={handleChange}
                required
              />
            </Form.Group>

            {/* Type */}
            <Form.Group className="mb-3">
              <Form.Label>Type of event *</Form.Label>
              <Form.Control
                type="text"
                name="type"
                value={formData.type}
                onChange={handleChange}
                required
              />
            </Form.Group>

            {/* Start Date & Time */}
            <div className="mb-3">
              <Form.Label>Start date *</Form.Label>
              <Form.Control
                type="date"
                name="startDate"
                value={formData.startDate}
                onChange={handleChange}
                required
              />
            </div>
            <div className="mb-3">
              <Form.Label>At *</Form.Label>
              <Form.Control
                type="time"
                name="startTime"
                value={formData.startTime}
                onChange={handleChange}
                required
              />
            </div>

            {/* End Date & Time */}
            <div className="mb-3">
              <Form.Label>End date *</Form.Label>
              <Form.Control
                type="date"
                name="endDate"
                value={formData.endDate}
                onChange={handleChange}
                required
              />
            </div>
            <div className="mb-3">
              <Form.Label>At *</Form.Label>
              <Form.Control
                type="time"
                name="endTime"
                value={formData.endTime}
                onChange={handleChange}
                required
              />
            </div>

            {/* City */}
            <Form.Group className="mb-3">
              <Form.Label>City</Form.Label>
              <Form.Control
                type="text"
                name="city"
                value={formData.city}
                onChange={handleChange}
                disabled
              />
            </Form.Group>

            {/* Address + Map */}
            <Form.Group className="mb-3">
              <Form.Label>Address</Form.Label>
              <Form.Control
                type="text"
                name="address"
                value={formData.address}
                onChange={handleChange}
              />
              <Button variant="link" className="p-0 mt-1">
                Update Map
              </Button>
            </Form.Group>

            {/* Description */}
            <Form.Group className="mb-3">
              <Form.Label>Event description *</Form.Label>
              <Form.Control
                as="textarea"
                rows={4}
                name="description"
                value={formData.description}
                onChange={handleChange}
                required
              />
            </Form.Group>

            {/* Image */}
            <Form.Group className="mb-3">
              <Form.Label>Image</Form.Label>
              <Form.Control
                type="file"
                name="image"
                accept="image/*"
                onChange={handleChange}
              />
              <Form.Text className="text-muted">Add image (optional)</Form.Text>
            </Form.Group>

            <div className="text-end">
              <Button
                variant="secondary"
                onClick={() => setShow(false)}
                className="me-2"
              >
                Cancel
              </Button>
              <Button
                variant="primary"
                type="submit"
                style={{
                  background: "linear-gradient(to right, #ff6a88, #ff99ac)",
                  border: "1px solid white",
                }}
              >
                Save Event
              </Button>
            </div>
          </Form>
        </Modal.Body>
      </Modal>

      <div className="mt-4">
        {events.length > 0 && <h4>My Events</h4>}
        {events.map((event, idx) => (
          <div key={idx} className="card p-3 mt-3 shadow-sm">
            <h5>{event.name}</h5>
            <p>
              <b>Type:</b> {event.type}
            </p>
            <p>
              <b>From:</b> {event.startDate} {event.startTime} <br />
              <b>To:</b> {event.endDate} {event.endTime}
            </p>
            <p>
              <b>City:</b> {event.city}
            </p>
            <p>
              <b>Address:</b> {event.address}
            </p>
            <p>{event.description}</p>
            {event.imagePreview && (
              <img
                src={event.imagePreview}
                alt="Event"
                className="img-thumbnail"
                width="150"
              />
            )}
            <div className="mt-2">
              <Button
                variant="outline-primary"
                size="sm"
                onClick={() => handleEditEvent(idx)}
              >
                Edit
              </Button>{" "}
              <Button
                variant="outline-danger"
                size="sm"
                onClick={() => handleDeleteEvent(idx)}
              >
                Delete
              </Button>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
