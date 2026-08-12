import React, { useEffect, useState } from "react";
import { useSelector } from "react-redux";
import axiosInstance from "../../../../services/api/axiosInstance";
import {
  Row,
  Col,
  Card,
  Spinner,
  Dropdown,
  Badge,
  Button,
} from "react-bootstrap";
import {
  FaUser,
  FaEnvelope,
  FaPhone,
  FaCalendarAlt,
  FaMapMarkerAlt,
  FaCheckCircle,
  FaClock,
  FaTimesCircle,
  FaBan,
  FaChevronDown,
  FaChevronUp,
  FaCalendarCheck
} from "react-icons/fa";
import { CiBookmarkCheck } from "react-icons/ci";
import Swal from "sweetalert2";
import Loader from "../../../ui/Loader";

const Booking = () => {
  const { user } = useSelector((state) => state.auth);
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState("all");
  const [expandedCards, setExpandedCards] = useState({});
  const [cancelling, setCancelling] = useState({});

  useEffect(() => {
    const fetchBookings = async () => {
      try {
        const res = await axiosInstance.get(
          "https://happywedz.com/api/request-pricing/user/quotations"
        );
        if (res.data.success) {
          setBookings(res.data.quotations);
        }
      } catch (err) {
        console.error("Error fetching bookings:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchBookings();
  }, []);

  const handleActionChange = (id, newStatus) => {
    setBookings((prev) =>
      prev.map((b) => (b.id === id ? { ...b, localStatus: newStatus } : b))
    );
  };

  const toggleCardExpansion = (cardId) => {
    setExpandedCards((prev) => ({
      ...prev,
      [cardId]: !prev[cardId],
    }));
  };

  const handleCancelRequest = async (requestId) => {
    const result = await Swal.fire({
      title: "Cancel Quotation?",
      text: "Are you sure you want to cancel this quotation request? This action cannot be undone.",
      icon: "warning",
      showCancelButton: true,
      confirmButtonColor: "#d33",
      cancelButtonColor: "#3085d6",
      confirmButtonText: "Yes, cancel it",
      cancelButtonText: "No, keep it",
    });

    if (!result.isConfirmed) return;

    setCancelling((prev) => ({ ...prev, [requestId]: true }));

    try {
      const res = await axiosInstance.delete(
        `https://happywedz.com/api/request-pricing/user/quotations/${requestId}`
      );

      if (res.data.success) {
        setBookings((prev) =>
          prev.map((b) =>
            (b.requestId || b.id) === requestId
              ? { ...b, status: "cancelled" }
              : b
          )
        );
        Swal.fire(
          "Cancelled!",
          "Your quotation request has been cancelled.",
          "success"
        );
      } else {
        throw new Error(res.data.message || "Failed to cancel quotation");
      }
    } catch (err) {
      console.error("Error cancelling booking:", err);
      Swal.fire(
        "Error",
        err.response?.data?.message ||
        "Failed to cancel quotation. Please try again.",
        "error"
      );
    } finally {
      setCancelling((prev) => ({ ...prev, [requestId]: false }));
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case "replied":
        return <FaCheckCircle />;
      case "pending":
        return <FaClock />;
      case "cancelled":
        return <FaBan />;
      case "booked":
        return <FaCalendarCheck />;

      default:
        return <FaTimesCircle />;
    }
  };

  const filteredBookings =
    filterStatus === "all"
      ? bookings
      : bookings.filter((b) => b.status === filterStatus);
  return (
    <div className="user-booking-container">
      <div className="user-booking-header">
        <div className="user-booking-header-content">
          <div className="user-booking-title-section">
            <h3 className="user-booking-main-title">My Bookings</h3>
            <p className="user-booking-subtitle fs-16">
              Manage and track all your service bookings
            </p>
          </div>

          <div className="user-booking-filter-section">
            <div className="user-booking-filter-tabs">
              <button
                className={`user-booking-filter-tab fs-16 ${filterStatus === "all" ? "active" : ""
                  }`}
                onClick={() => setFilterStatus("all")}
              >
                All ({bookings.length})
              </button>
              <button
                className={`user-booking-filter-tab fs-16 ${filterStatus === "replied" ? "active" : ""
                  }`}
                onClick={() => setFilterStatus("replied")}
              >
                Replied ({bookings.filter((b) => b.status === "replied").length}
                )
              </button>
              <button
                className={`user-booking-filter-tab fs-16 ${filterStatus === "pending" ? "active" : ""
                  }`}
                onClick={() => setFilterStatus("pending")}
              >
                Pending ({bookings.filter((b) => b.status === "pending").length}
                )
              </button>
              <button
                className={`user-booking-filter-tab fs-16 ${filterStatus === "cancelled" ? "active" : ""
                  }`}
                onClick={() => setFilterStatus("cancelled")}
              >
                Cancelled (
                {bookings.filter((b) => b.status === "cancelled").length})
              </button>
            </div>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="user-booking-loading">
          <Loader />
        </div>
      ) : filteredBookings.length === 0 ? (
        <div className="user-booking-empty">
          <div className="user-booking-empty-icon">
            <img
              src="/images/no-booking.png"
              alt=""
              className="img-fluid"
              width={200}
              height={200}
            />
          </div>
          <h3 className="user-booking-empty-title">No Bookings Found</h3>
          <p className="user-booking-empty-text">
            {filterStatus === "all"
              ? "You haven't made any bookings yet. Start exploring services!"
              : `No ${filterStatus} bookings at the moment.`}
          </p>
        </div>
      ) : (
        <div className="user-booking-grid-container">
          <Row className="g-4">
            {filteredBookings.map((item) => {
              const isExpanded = expandedCards[item.id];
              const isCancelled = item.status === "cancelled";

              return (
                <Col md={6} xl={4} key={item.id}>
                  <Card className="user-booking-card">
                    <Card.Body className="user-booking-card-body rounded-5">
                      <div className="user-booking-card-compact rounded-5">
                        <div className="user-booking-card-profile-section">
                          <div className="user-booking-card-profile-image-wrapper rounded-5">
                            <img
                              src={
                                item.vendor?.profileImage ||
                                "/images/imageNotFound.jpg"
                              }
                              alt={item.vendor?.businessName}
                              className="user-booking-card-profile-image"
                            />
                            <Badge
                              bg="none"
                              className={`fs-10 user-booking-status-badge user-booking-status-${item.status}`}
                            >
                              {getStatusIcon(item.status)}
                              <span className="ms-1">{item.status}</span>
                            </Badge>
                          </div>
                          <div className="user-booking-card-vendor-info">
                            <h3 className="user-booking-vendor-name fs-16">
                              {item.vendor?.businessName || "Unknown Vendor"}
                            </h3>
                            <p className="user-booking-vendor-location fs-14">
                              <FaMapMarkerAlt size={14} />
                              <span className="fs-14">
                                {item.vendor?.city || "Unknown"},{" "}
                                {item.vendor?.state || ""}
                              </span>
                            </p>
                          </div>
                        </div>

                        {isExpanded && (
                          <div className="user-booking-card-expanded">
                            <div className="user-booking-info-section">
                              <p className="user-booking-section-title fs-16">
                                Booking Details
                              </p>
                              <div className="user-booking-info-grid">
                                <div className="user-booking-info-item">
                                  <FaUser className="user-booking-info-icon fs-14" />
                                  <span className="user-booking-info-text fs-14">
                                    {item.firstName} {item.lastName}
                                  </span>
                                </div>
                                <div className="user-booking-info-item">
                                  <FaEnvelope className="user-booking-info-icon fs-14" />
                                  <span className="user-booking-info-text fs-14">
                                    {item.email}
                                  </span>
                                </div>
                                <div className="user-booking-info-item">
                                  <FaPhone className="user-booking-info-icon fs-14" />
                                  <span className="user-booking-info-text fs-14">
                                    {item.phone}
                                  </span>
                                </div>
                                <div className="user-booking-info-item">
                                  <FaCalendarAlt className="user-booking-info-icon fs-14" />
                                  <span className="user-booking-info-text fs-14">
                                    <strong>{item.eventDate}</strong>
                                  </span>
                                </div>
                              </div>
                            </div>

                            <div className="user-booking-quote-section">
                              <p className="user-booking-section-title fs-16">
                                Quotation Details
                              </p>
                              <div className="user-booking-quote-card">
                                <div className="user-booking-quote-item">
                                  <span className="user-booking-quote-label fs-14">
                                    Quote Price
                                  </span>
                                  <span className="user-booking-quote-value user-booking-quote-price fs-14">
                                    {item.quote?.price
                                      ? `₹ ${item.quote.price}`
                                      : "Not provided"}
                                  </span>
                                </div>
                                <div className="user-booking-quote-item">
                                  <span className="user-booking-quote-label fs-14">
                                    Valid Till
                                  </span>
                                  <span className="user-booking-quote-value fs-14">
                                    {item.quote?.validTill || "N/A"}
                                  </span>
                                </div>
                                {item.quote?.message && (
                                  <div className="user-booking-quote-message">
                                    <span className="user-booking-quote-label fs-14">
                                      Message
                                    </span>
                                    <p className="user-booking-quote-message-text fs-14">
                                      {item.quote.message}
                                    </p>
                                  </div>
                                )}
                              </div>
                            </div>
                          </div>
                        )}

                        <div className="user-booking-card-actions">
                          <Button
                            variant="link"
                            className="user-booking-show-more-btn fs-14"
                            onClick={() => toggleCardExpansion(item.id)}
                          >
                            {isExpanded ? (
                              <>
                                <FaChevronUp size={14} className="me-1" />
                                <span className="fs-14"> Show Less</span>
                              </>
                            ) : (
                              <>
                                <FaChevronDown size={14} className="me-1" />
                                <span className="fs-14"> Show More</span>
                              </>
                            )}
                          </Button>
                          {!isCancelled && (
                            <Button
                              variant="danger"
                              size="sm"
                              className="user-booking-cancel-btn fs-14"
                              onClick={() =>
                                handleCancelRequest(item.requestId || item.id)
                              }
                              disabled={cancelling[item.requestId || item.id]}
                            >
                              {cancelling[item.requestId || item.id] ? (
                                <>
                                  <Spinner
                                    animation="border"
                                    size="sm"
                                    className="me-1"
                                  />
                                  Cancelling...
                                </>
                              ) : (
                                <>
                                  <FaBan className="me-1" />
                                  <span className="fs-14">Cancel</span>
                                </>
                              )}
                            </Button>
                          )}
                        </div>
                      </div>
                    </Card.Body>
                  </Card>
                </Col>
              );
            })}
          </Row>
        </div>
      )}
    </div>
  );
};

export default Booking;
