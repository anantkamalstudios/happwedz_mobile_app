import React, { useState, useEffect } from "react";
import { toast } from "react-toastify";
import { Modal, Button, Form } from "react-bootstrap";
import { FiCalendar, FiMapPin, FiPlus, FiClock } from "react-icons/fi";
import { IoCloudUploadOutline } from "react-icons/io5";
import axiosInstance from "../../../../services/api/axiosInstance";
import Loader from "../../../ui/Loader";

import dayjs from "dayjs";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";

const Events = ({ onNavigate }) => {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    event_date: "",
    venue: "",
  });

  useEffect(() => {
    fetchEvents();
  }, []);

  const fetchEvents = async () => {
    try {
      setLoading(true);
      const response = await axiosInstance.get("/events");
      if (response.data.success) {
        setEvents(response.data.events);
      }
    } catch (error) {
      console.error("Error fetching events:", error);
      toast.error("Failed to load events");
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name || !formData.event_date || !formData.venue) {
      toast.error("Please fill all required fields");
      return;
    }

    try {
      setSubmitting(true);
      const response = await axiosInstance.post("/events", formData);
      if (response.data.success) {
        toast.success("Event created successfully");
        setShowModal(false);
        setFormData({ name: "", event_date: "", venue: "" });
        fetchEvents(); // Refresh list
      }
    } catch (error) {
      console.error("Error creating event:", error);
      toast.error(error.response?.data?.message || "Failed to create event");
    } finally {
      setSubmitting(false);
    }
  };

  const formatDate = (dateString) => {
    if (!dateString) return "N/A";
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  };

  if (loading) {
    return <Loader />;
  }

  return (
    <div className="events-container">
      <div className="d-flex justify-content-between align-items-center mb-4">
        <div className="w-75">
          <h3 className="fw-bold mb-1 inter">Events Management</h3>
          <p className="text-muted mb-0 inter">Create and manage your events</p>
        </div>
        <Button
          variant="primary"
          className="d-flex align-items-center gap-2 col-2 inter"
          onClick={() => setShowModal(true)}
          style={{
            background: "linear-gradient(135deg, #ed1173 0%, #ff4d9a 100%)",
            border: "none",
          }}
        >
          <FiPlus size={20} />
          Create Event
        </Button>
      </div>

      <div className="row g-4">
        {events.length > 0 ? (
          events.map((event) => (
            <div key={event.id} className="col-md-6 col-lg-4">
              <div className="card h-100 border-0 shadow-sm rounded-3">
                <div className="card-body p-4">
                  <h5 className="card-title fw-bold mb-3 inter">
                    {event.name}
                  </h5>
                  <div className="d-flex align-items-center text-muted mb-2">
                    <FiCalendar className="me-2" />
                    <span className="inter">
                      {formatDate(event.event_date)}
                    </span>
                  </div>
                  <div className="d-flex align-items-center text-muted inter">
                    <FiMapPin className="me-2" />
                    <span>{event.venue || "No venue specified"}</span>
                  </div>
                </div>
                <div className="card-footer bg-transparent border-top-0 p-4 pt-0 d-flex justify-content-between align-items-center">
                  <small className="text-muted inter">#{event.id}</small>
                  <Button
                    variant="outline-primary"
                    size="sm"
                    className="d-flex align-items-center gap-2 col-5 inter"
                    onClick={() =>
                      onNavigate &&
                      onNavigate("upload-media", { eventId: event.id })
                    }
                  >
                    <IoCloudUploadOutline size={16} />
                    Upload Media
                  </Button>
                </div>
              </div>
            </div>
          ))
        ) : (
          <div className="col-12 text-center py-5 inter">
            <div className="text-muted">
              <FiCalendar size={48} className="mb-3 opacity-50" />
              <h5>No events found</h5>
              <p>Create your first event to get started</p>
            </div>
          </div>
        )}
      </div>

      {/* Create Event Modal */}
      <Modal show={showModal} onHide={() => setShowModal(false)} centered>
        <Modal.Header closeButton>
          <Modal.Title className="fw-bold">Create New Event</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form onSubmit={handleSubmit}>
            <Form.Group className="mb-3">
              <Form.Label className="fw-semibold inter">
                Event Name <span className="text-danger">*</span>
              </Form.Label>
              <Form.Control
                type="text"
                name="name"
                value={formData.name}
                onChange={handleInputChange}
                placeholder="e.g. Rimesh wedz Disha"
                required
                className="inter"
              />
            </Form.Group>

            <Form.Group className="mb-3">
              <Form.Label className="fw-semibold inter">
                Event Date <span className="text-danger">*</span>
              </Form.Label>
              <LocalizationProvider dateAdapter={AdapterDayjs}>
                <DatePicker
                  value={
                    formData.event_date ? dayjs(formData.event_date) : null
                  }
                  onChange={(newValue) => {
                    const dateString = newValue
                      ? dayjs(newValue).format("YYYY-MM-DD")
                      : "";
                    handleInputChange({
                      target: { name: "event_date", value: dateString },
                    });
                  }}
                  slotProps={{
                    textField: {
                      className: "inter",
                      fullWidth: true,
                      size: "small",
                      placeholder: "Select event date",
                      InputProps: { style: { fontSize: 14 } },
                      inputProps: { style: { fontSize: 14 } },
                    },
                  }}
                />
              </LocalizationProvider>
            </Form.Group>

            <Form.Group className="mb-3 inter">
              <Form.Label className="fw-semibold inter">
                Venue <span className="text-danger">*</span>
              </Form.Label>
              <Form.Control
                type="text"
                name="venue"
                value={formData.venue}
                onChange={handleInputChange}
                placeholder="e.g. Taj Palace"
                required
                className="inter"
              />
            </Form.Group>

            <div className="d-flex justify-content-end gap-2 mt-4 inter">
              <Button variant="light" onClick={() => setShowModal(false)}>
                Cancel
              </Button>
              <Button
                type="submit"
                variant="primary"
                disabled={submitting}
                style={{
                  background:
                    "linear-gradient(135deg, #ed1173 0%, #ff4d9a 100%)",
                  border: "none",
                }}
              >
                {submitting ? "Creating..." : "Create Event"}
              </Button>
            </div>
          </Form>
        </Modal.Body>
      </Modal>
    </div>
  );
};

export default Events;
