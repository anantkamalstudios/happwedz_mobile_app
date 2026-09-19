import React, { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import { useSearchParams } from "react-router-dom";
import axiosInstance from "../../../services/api/axiosInstance";
import {
  Container,
  Row,
  Col,
  Card,
  Form,
  Button,
  Nav,
  Tab,
  Alert,
} from "react-bootstrap";
import {
  FiUser,
  FiBell,
  FiShield,
  FiClock,
  FiCreditCard,
  FiEye,
  FiSave,
  FiEdit3,
  FiLink,
} from "react-icons/fi";
import InstagramConnect from "./subVendors/InstagramConnect";
import SubscriptionSettings from "./subscription/SubscriptionSettings";

const Settings = () => {
  // ?tab=integrations lets other pages (e.g. the Instagram page) open a section directly.
  const [searchParams] = useSearchParams();
  const [activeTab, setActiveTab] = useState(() => {
    const requested = searchParams.get("tab");
    return ["notifications", "billing", "integrations"].includes(requested)
      ? requested
      : "notifications";
  });
  const [showSuccess, setShowSuccess] = useState(false);
  const { vendor, token } = useSelector((state) => state.vendorAuth || {});
  const [enquiryNotificationEnabled, setEnquiryNotificationEnabled] =
    useState(true);
  const [showEnquiryIcon, setShowEnquiryIcon] = useState(() => {
    const stored = localStorage.getItem("showEnquiryCountBadge");
    return stored !== null ? stored === "true" : true;
  });

  const [profileData, setProfileData] = useState({
    businessName: "",
    contactPerson: "",
    email: "",
    phone: "",
    address: "",
  });

  useEffect(() => {
    if (vendor) {
      setProfileData({
        businessName: vendor.businessName || "",
        contactPerson: `${vendor.firstName || ""} ${
          vendor.lastName || ""
        }`.trim(),
        email: vendor.email || "",
        phone: vendor.phone || "",
        address: vendor.city || "",
      });
    }
  }, [vendor]);

  // Toggle notifications on/off (sends review_notifications flag)
  const toggleNotifications = async (enabled) => {
    try {
      await axiosInstance.put(
        "/vendor/notification-settings",
        { review_notifications: enabled },
        {
          headers: {
            "Content-Type": "application/json",
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
          },
        }
      );
      setShowSuccess(true);
      setTimeout(() => setShowSuccess(false), 2000);
    } catch (err) {
      console.error("Failed to toggle notifications:", err);
    }
  };

  const handleSave = () => {
    setShowSuccess(true);
    setTimeout(() => setShowSuccess(false), 3000); // You can add API call logic here
  };

  return (
    <div
      className="settings-page"
      style={{ backgroundColor: "#f8f9fa", minHeight: "100vh" }}
    >
      <Container fluid>
        <Row>
          <Col lg={3} md={4}>
            <Card className="settings-card">
              <Card.Body className="p-0">
                <Nav className="flex-column settings-nav p-3">
                  {/* <Nav.Item>
                    <Nav.Link
                      active={activeTab === "profile"}
                      onClick={() => setActiveTab("profile")}
                    >
                      <FiUser className="me-2" />
                      Profile Settings
                    </Nav.Link>
                  </Nav.Item> */}
                  <Nav.Item>
                    <Nav.Link
                      active={activeTab === "notifications"}
                      onClick={() => setActiveTab("notifications")}
                    >
                      <FiBell className="me-2" />
                      Notifications
                    </Nav.Link>
                  </Nav.Item>
                  <Nav.Item>
                    <Nav.Link
                      active={activeTab === "billing"}
                      onClick={() => setActiveTab("billing")}
                    >
                      <FiCreditCard className="me-2" />
                      Payments &amp; Subscription
                    </Nav.Link>
                  </Nav.Item>
                  <Nav.Item>
                    <Nav.Link
                      active={activeTab === "integrations"}
                      onClick={() => setActiveTab("integrations")}
                    >
                      <FiLink className="me-2" />
                      Integrations
                    </Nav.Link>
                  </Nav.Item>
                  {/* <Nav.Item>
                    <Nav.Link
                      active={activeTab === "security"}
                      onClick={() => setActiveTab("security")}
                    >
                      <FiShield className="me-2" />
                      Security
                    </Nav.Link>
                  </Nav.Item>
                  <Nav.Item>
                    <Nav.Link
                      active={activeTab === "business"}
                      onClick={() => setActiveTab("business")}
                    >
                      <FiClock className="me-2" />
                      Business Hours
                    </Nav.Link>
                  </Nav.Item>
                  <Nav.Item>
                    <Nav.Link
                      active={activeTab === "privacy"}
                      onClick={() => setActiveTab("privacy")}
                    >
                      <FiEye className="me-2" />
                      Privacy
                    </Nav.Link>
                  </Nav.Item> */}
                </Nav>
              </Card.Body>
            </Card>
          </Col>

          <Col lg={9} md={8}>
            {showSuccess && (
              <Alert
                variant="success"
                dismissible
                onClose={() => setShowSuccess(false)}
              >
                Settings saved successfully!
              </Alert>
            )}

            {/* Profile Settings */}
            {activeTab === "profile" && (
              <Card className="settings-card">
                <Card.Header>
                  <div className="d-flex align-items-center">
                    <div className="setting-icon-wrapper">
                      <FiUser size={20} />
                    </div>
                    <h5 className="card-title mb-0 text-black">
                      Profile Settings
                    </h5>
                  </div>
                </Card.Header>
                <Card.Body className="p-4">
                  <Row>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Business Name</Form.Label>
                        <Form.Control
                          type="text"
                          value={profileData.businessName}
                          onChange={(e) =>
                            setProfileData({
                              ...profileData,
                              businessName: e.target.value,
                            })
                          }
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Contact Person</Form.Label>
                        <Form.Control
                          type="text"
                          value={profileData.contactPerson}
                          onChange={(e) =>
                            setProfileData({
                              ...profileData,
                              contactPerson: e.target.value,
                            })
                          }
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Email</Form.Label>
                        <Form.Control
                          type="email"
                          value={profileData.email}
                          onChange={(e) =>
                            setProfileData({
                              ...profileData,
                              email: e.target.value,
                            })
                          }
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Phone</Form.Label>
                        <Form.Control
                          type="tel"
                          value={profileData.phone}
                          onChange={(e) =>
                            setProfileData({
                              ...profileData,
                              phone: e.target.value,
                            })
                          }
                        />
                      </Form.Group>
                    </Col>
                    <Col md={12}>
                      <Form.Group className="mb-3">
                        <Form.Label>Business Address</Form.Label>
                        <Form.Control
                          as="textarea"
                          rows={3}
                          value={profileData.address}
                          onChange={(e) =>
                            setProfileData({
                              ...profileData,
                              address: e.target.value,
                            })
                          }
                          placeholder="City, State"
                        />
                      </Form.Group>
                    </Col>
                  </Row>
                  <div className="d-flex justify-content-end">
                    <Button
                      variant="primary"
                      className="folder-item"
                      onClick={handleSave}
                    >
                      <FiSave className="me-2" />
                      Save Changes
                    </Button>
                  </div>
                </Card.Body>
              </Card>
            )}

            {/* Payments & Subscription */}
            {activeTab === "billing" && <SubscriptionSettings />}

            {/* Notifications */}
            {activeTab === "notifications" && (
              <Card className="settings-card">
                <Card.Header>
                  <div className="d-flex align-items-center">
                    <div className="setting-icon-wrapper">
                      <FiBell size={20} />
                    </div>
                    <h5 className="card-title mb-0 text-black">
                      Notification Preferences
                    </h5>
                  </div>
                </Card.Header>
                <Card.Body className="p-4">
                  {/* <div className="notification-item">
                    <div className="switch-wrapper">
                      <div>
                        <h6 className="mb-1">New Review Notifications</h6>
                        <small className="text-muted">
                          Get notified when someone leaves a review
                        </small>
                      </div>
                      <Form.Check
                        type="switch"
                        defaultChecked
                        onChange={(e) => toggleNotifications(e.target.checked)}
                      />
                    </div>
                  </div> */}
                  <div className="notification-item">
                    <div className="switch-wrapper">
                      <div>
                        <h6 className="mb-1">Show Enquiry Count Badge</h6>
                        <small className="text-muted">
                          Display unread enquiry count on the enquiry icon in
                          navbar
                        </small>
                      </div>
                      <Form.Check
                        type="switch"
                        checked={showEnquiryIcon}
                        onChange={(e) => {
                          const enabled = e.target.checked;
                          setShowEnquiryIcon(enabled);
                          localStorage.setItem(
                            "showEnquiryCountBadge",
                            enabled.toString()
                          );
                          // Dispatch custom event to notify Navbar
                          window.dispatchEvent(
                            new Event("enquiryBadgeSettingChanged")
                          );
                          setShowSuccess(true);
                          setTimeout(() => setShowSuccess(false), 2000);
                        }}
                      />
                    </div>
                  </div>
                  {/* <div className="notification-item">
                    <div className="switch-wrapper">
                      <div>
                        <h6 className="mb-1">Booking Requests</h6>
                        <small className="text-muted">
                          Receive alerts for new booking inquiries
                        </small>
                      </div>
                      <Form.Check type="switch" defaultChecked />
                    </div>
                  </div> */}
                  {/* <div className="notification-item">
                    <div className="switch-wrapper">
                      <div>
                        <h6 className="mb-1">Payment Confirmations</h6>
                        <small className="text-muted">
                          Get notified about successful payments
                        </small>
                      </div>
                      <Form.Check type="switch" defaultChecked />
                    </div>
                  </div> */}
                  {/* <div className="notification-item">
                    <div className="switch-wrapper">
                      <div>
                        <h6 className="mb-1">Marketing Updates</h6>
                        <small className="text-muted">
                          Receive tips and industry updates
                        </small>
                      </div>
                      <Form.Check type="switch" />
                    </div>
                  </div> */}
                  <div className="d-flex justify-content-end">
                    {/* <Button
                      variant="primary"
                      className="folder-item"
                      onClick={handleSave}
                    >
                      <FiSave className="me-2" />
                      Save Preferences
                    </Button> */}
                  </div>
                </Card.Body>
              </Card>
            )}

            {/* Integrations */}
            {activeTab === "integrations" && (
              <Card className="settings-card">
                <Card.Header>
                  <div className="d-flex align-items-center">
                    <div className="setting-icon-wrapper">
                      <FiLink size={20} />
                    </div>
                    <h5 className="card-title mb-0 text-black">
                      Integrations
                    </h5>
                  </div>
                </Card.Header>
                <Card.Body className="p-4">
                  <h6 className="mb-3">Instagram</h6>
                  <p className="text-muted small mb-3">
                    Connect your Instagram Business account to enable direct
                    messages, comments, and publishing from your dashboard.
                  </p>
                  <InstagramConnect />
                </Card.Body>
              </Card>
            )}

            {/* Security */}
            {activeTab === "security" && (
              <Card className="settings-card">
                <Card.Header>
                  <div className="d-flex align-items-center">
                    <div className="setting-icon-wrapper">
                      <FiShield size={20} />
                    </div>
                    <h5 className="card-title mb-0 text-black">
                      Security Settings
                    </h5>
                  </div>
                </Card.Header>
                <Card.Body className="p-4">
                  <Row>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Current Password</Form.Label>
                        <Form.Control
                          type="password"
                          placeholder="Enter current password"
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>New Password</Form.Label>
                        <Form.Control
                          type="password"
                          placeholder="Enter new password"
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Confirm New Password</Form.Label>
                        <Form.Control
                          type="password"
                          placeholder="Confirm new password"
                        />
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Two-Factor Authentication</Form.Label>
                        <div className="d-flex align-items-center">
                          <Form.Check type="switch" className="me-3" />
                          <span className="text-muted">
                            Enable 2FA for extra security
                          </span>
                        </div>
                      </Form.Group>
                    </Col>
                  </Row>
                  <div className="d-flex justify-content-end">
                    <Button
                      variant="primary"
                      className="folder-item"
                      onClick={handleSave}
                    >
                      <FiSave className="me-2" />
                      Update Security
                    </Button>
                  </div>
                </Card.Body>
              </Card>
            )}

            {/* Business Hours */}
            {activeTab === "business" && (
              <Card className="settings-card">
                <Card.Header>
                  <div className="d-flex align-items-center">
                    <div className="setting-icon-wrapper">
                      <FiClock size={20} />
                    </div>
                    <h5 className="card-title mb-0 text-black">
                      Business Hours
                    </h5>
                  </div>
                </Card.Header>
                <Card.Body className="p-4">
                  <Row>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Monday - Friday</Form.Label>
                        <div className="d-flex gap-2">
                          <Form.Control type="time" defaultValue="09:00" />
                          <span className="d-flex align-items-center">to</span>
                          <Form.Control type="time" defaultValue="18:00" />
                        </div>
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Saturday</Form.Label>
                        <div className="d-flex gap-2">
                          <Form.Control type="time" defaultValue="10:00" />
                          <span className="d-flex align-items-center">to</span>
                          <Form.Control type="time" defaultValue="16:00" />
                        </div>
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Sunday</Form.Label>
                        <div className="d-flex gap-2">
                          <Form.Control type="time" defaultValue="12:00" />
                          <span className="d-flex align-items-center">to</span>
                          <Form.Control type="time" defaultValue="18:00" />
                        </div>
                      </Form.Group>
                    </Col>
                    <Col md={6}>
                      <Form.Group className="mb-3">
                        <Form.Label>Emergency Availability</Form.Label>
                        <div className="d-flex align-items-center">
                          <Form.Check
                            type="switch"
                            defaultChecked
                            className="me-3"
                          />
                          <span className="text-muted">
                            Available for urgent bookings
                          </span>
                        </div>
                      </Form.Group>
                    </Col>
                  </Row>
                  <div className="d-flex justify-content-end">
                    <Button
                      variant="primary"
                      className="folder-item"
                      onClick={handleSave}
                    >
                      <FiSave className="me-2" />
                      Save Hours
                    </Button>
                  </div>
                </Card.Body>
              </Card>
            )}

            {/* The template shipped a hardcoded billing panel here — a fake "Premium
                Vendor Plan - $29/month", a masked card ending 1234 and an Upgrade
                button that did nothing. It rendered on this same tab alongside the real
                one above, showing every vendor an invented plan they had not bought. */}

            {/* Privacy */}
            {activeTab === "privacy" && (
              <Card className="settings-card">
                <Card.Header>
                  <div className="d-flex align-items-center">
                    <div className="setting-icon-wrapper">
                      <FiEye size={20} />
                    </div>
                    <h5 className="card-title mb-0 text-black">
                      Privacy Settings
                    </h5>
                  </div>
                </Card.Header>
                <Card.Body className="p-4">
                  <div className="notification-item">
                    <div className="switch-wrapper">
                      <div>
                        <h6 className="mb-1">Profile Visibility</h6>
                        <small className="text-muted">
                          Make your profile visible to potential clients
                        </small>
                      </div>
                      <Form.Check type="switch" defaultChecked />
                    </div>
                  </div>
                  <div className="notification-item">
                    <div className="switch-wrapper">
                      <div>
                        <h6 className="mb-1">Contact Information</h6>
                        <small className="text-muted">
                          Show contact details on your profile
                        </small>
                      </div>
                      <Form.Check type="switch" defaultChecked />
                    </div>
                  </div>
                  <div className="notification-item">
                    <div className="switch-wrapper">
                      <div>
                        <h6 className="mb-1">Analytics Sharing</h6>
                        <small className="text-muted">
                          Share anonymous usage data to improve our service
                        </small>
                      </div>
                      <Form.Check type="switch" />
                    </div>
                  </div>
                  <div className="d-flex justify-content-end">
                    <Button
                      variant="primary"
                      className="folder-item"
                      onClick={handleSave}
                    >
                      <FiSave className="me-2" />
                      Save Privacy Settings
                    </Button>
                  </div>
                </Card.Body>
              </Card>
            )}
          </Col>
        </Row>
      </Container>
    </div>
  );
};

export default Settings;
