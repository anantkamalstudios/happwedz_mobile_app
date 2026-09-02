import React, { useEffect, useState } from "react";
import { useParams, useNavigate, useLocation } from "react-router-dom";
import axiosInstance from "../../../../services/api/axiosInstance";
import { FaTaxi, FaArrowLeft, FaMapMarkerAlt, FaClock, FaUser, FaPhone, FaEnvelope } from "react-icons/fa";
import Loader from "../../../ui/Loader";
import InvoiceDownloadButton from "../../../ui/InvoiceDownloadButton";
import { formatDateTime } from "../../../../utils/dateFormat";

const fmt = (dateStr) => {
  if (!dateStr) return "—";
  return formatDateTime(dateStr, { fallback: "—" });
};

export default function CabBookingDetail() {
  const navigate = useNavigate();
  const location = useLocation();
  const { id } = useParams();
  const [booking, setBooking] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    setLoading(true);
    setError(null);

    axiosInstance
      .get(`/tripjack-cabs/invoice/${id}/details`)
      .then((res) => {
        console.log("API Response:", res.data);
        if (res.data?.status && res.data?.invoice) {
          setBooking(res.data.invoice);
        } else {
          setError("Invalid booking data received");
        }
      })
      .catch((err) => {
        console.error("Error fetching booking details:", err);
        setError(err.response?.data?.message || "Could not load booking details");
      })
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) {
    return (
      <div className="container-fluid py-4">
        <div className="text-center">
          <Loader />
        </div>
      </div>
    );
  }

  if (error || !booking) {
    return (
      <div className="container-fluid py-4">
        <button className="btn btn-outline-primary mb-3" onClick={() => navigate("/user-dashboard/booking/travel/cabs")}>
          <FaArrowLeft className="me-2" />
          Back to Bookings
        </button>
        <div className="alert alert-danger">
          <h4>Error Loading Booking</h4>
          <p>{error || "Booking not found"}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="container-fluid py-4">
      {/* Back Button */}
      <button className="btn btn-outline-primary mb-4" onClick={() => navigate("/user-dashboard/booking/travel/cabs")}>
        <FaArrowLeft className="me-2" />
        Back to Bookings
      </button>

      {/* Header */}
      <div className="mb-4">
        <h2 className="fw-bold mb-2">
          <FaTaxi className="me-2 text-primary" />
          Booking Details
        </h2>
        <p className="text-muted">Booking ID: {booking.invoiceNumber || booking.bookingId}</p>
      </div>

      <div className="row g-4">
        {/* Journey Details */}
        <div className="col-lg-6">
          <div className="card h-100">
            <div className="card-header bg-light">
              <h5 className="mb-0">Journey Details</h5>
            </div>
            <div className="card-body">
              <div className="mb-3">
                <div className="d-flex align-items-start gap-2 mb-2">
                  <FaMapMarkerAlt className="mt-1 text-primary" />
                  <div>
                    <small className="text-muted d-block">Pickup Location</small>
                    <strong>{booking.journey?.pickupLocation || "—"}</strong>
                  </div>
                </div>
              </div>

              <div className="mb-3">
                <div className="d-flex align-items-start gap-2 mb-2">
                  <FaMapMarkerAlt className="mt-1 text-success" />
                  <div>
                    <small className="text-muted d-block">Dropoff Location</small>
                    <strong>{booking.journey?.dropoffLocation || "—"}</strong>
                  </div>
                </div>
              </div>

              <div className="mb-3">
                <div className="d-flex align-items-start gap-2">
                  <FaClock className="mt-1 text-info" />
                  <div>
                    <small className="text-muted d-block">Pickup Time</small>
                    <strong>{fmt(booking.journey?.pickupTime)}</strong>
                  </div>
                </div>
              </div>

              {booking.journey?.distance && (
                <div>
                  <small className="text-muted d-block">Distance</small>
                  <strong>{booking.journey.distance}</strong>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Passenger Details */}
        <div className="col-lg-6">
          <div className="card h-100">
            <div className="card-header bg-light">
              <h5 className="mb-0">Passenger Details</h5>
            </div>
            <div className="card-body">
              <div className="mb-3">
                <div className="d-flex align-items-start gap-2">
                  <FaUser className="mt-1 text-primary" />
                  <div>
                    <small className="text-muted d-block">Name</small>
                    <strong>{booking.passenger?.name || "—"}</strong>
                  </div>
                </div>
              </div>

              <div className="mb-3">
                <div className="d-flex align-items-start gap-2">
                  <FaEnvelope className="mt-1 text-primary" />
                  <div>
                    <small className="text-muted d-block">Email</small>
                    <strong>{booking.passenger?.email || "—"}</strong>
                  </div>
                </div>
              </div>

              <div>
                <div className="d-flex align-items-start gap-2">
                  <FaPhone className="mt-1 text-primary" />
                  <div>
                    <small className="text-muted d-block">Phone</small>
                    <strong>{booking.passenger?.phone || "—"}</strong>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Pricing & Status */}
      <div className="row g-4 mt-2">
        <div className="col-lg-6">
          <div className="card">
            <div className="card-header bg-light">
              <h5 className="mb-0">Pricing</h5>
            </div>
            <div className="card-body">
              <div className="d-flex justify-content-between mb-2">
                <span>Base Fare:</span>
                <strong>₹{Number(booking.pricing?.baseFare || 0).toLocaleString("en-IN")}</strong>
              </div>
              <div className="d-flex justify-content-between mb-2">
                <span>Taxes:</span>
                <strong>₹{Number(booking.pricing?.taxes || 0).toLocaleString("en-IN")}</strong>
              </div>
              <hr />
              <div className="d-flex justify-content-between">
                <span className="fw-bold">Total:</span>
                <strong className="text-primary fs-5">₹{Number(booking.pricing?.total || 0).toLocaleString("en-IN")}</strong>
              </div>
            </div>
          </div>
        </div>

        <div className="col-lg-6">
          <div className="card">
            <div className="card-header bg-light">
              <h5 className="mb-0">Status</h5>
            </div>
            <div className="card-body">
              <div className="mb-3">
                <small className="text-muted d-block">Booking Status</small>
                <span className="badge bg-success fs-6">{booking.booking?.status || "—"}</span>
              </div>
              <div className="mb-3">
                <small className="text-muted d-block">Payment Status</small>
                <span className="badge bg-success fs-6">{booking.payment?.status || "—"}</span>
              </div>
              <div>
                <small className="text-muted d-block">Booked On</small>
                <strong>{fmt(booking.createdAt)}</strong>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Invoice */}
      <div className="row mt-4">
        <div className="col-12">
          <div className="card">
            <div className="card-header bg-light">
              <h5 className="mb-0">Invoice</h5>
            </div>
            <div className="card-body">
              <p className="text-muted mb-3">Invoice Number: <strong>{booking.invoiceNumber}</strong></p>
              {booking.orderId && (
                <InvoiceDownloadButton
                  paymentId={booking.orderId}
                  invoiceNumber={booking.invoiceNumber}
                  bookingType="cabs"
                  className="btn btn-primary"
                  label="Download Invoice PDF"
                />
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
