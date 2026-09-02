import React, { useState } from "react";
import { Outlet, useLocation, Link } from "react-router-dom";
import { Container, Navbar, Nav, Button, Offcanvas } from "react-bootstrap";
import { RiHome5Line } from "react-icons/ri";
import {
  FiHome,
  FiStar,
  FiShoppingBag,
  FiSettings,
  FiMenu,
  FiX,
  FiCheckCircle,
  FiImage,
  FiCalendar,
  FiDollarSign,
  FiMessageSquare,
} from "react-icons/fi";

const VendorDashboard = () => {
  const [showMobileMenu, setShowMobileMenu] = useState(false);
  const location = useLocation();

  const isActive = (path) => {
    return (
      location.pathname === path ||
      (path !== "/" && location.pathname.startsWith(path))
    );
  };

  const mainNavItems = [
    { id: "home", path: "/", icon: <RiHome5Line size={24} />, label: "Home" },
    {
      id: "reviews",
      path: "/reviews",
      icon: <FiStar size={24} />,
      label: "Reviews",
    },
    {
      id: "storefront",
      path: "/storefront",
      icon: <FiShoppingBag size={24} />,
      label: "Storefront",
    },
    {
      id: "settings",
      path: "/settings",
      icon: <FiSettings size={24} />,
      label: "Settings",
    },
  ];

  const storefrontNavItems = [
    {
      id: "checklist",
      path: "/storefront",
      icon: <FiCheckCircle size={20} />,
      label: "Checklist",
    },
    {
      id: "portfolio",
      path: "/storefront/portfolio",
      icon: <FiImage size={20} />,
      label: "Portfolio",
    },
    {
      id: "services",
      path: "/storefront/services",
      icon: <FiDollarSign size={20} />,
      label: "Services",
    },
    {
      id: "availability",
      path: "/storefront/availability",
      icon: <FiCalendar size={20} />,
      label: "Availability",
    },
    {
      id: "messages",
      path: "/storefront/messages",
      icon: <FiMessageSquare size={20} />,
      label: "Messages",
    },
  ];

  return (
    <div className="vendor-dashboard">
      <Navbar bg="white" expand="lg" className="top-navbar shadow-sm">
        <Container fluid>
          <Navbar.Brand className="d-flex align-items-center">
            <div className="logo me-3">
              <span className="text-primary">Wedding</span>
              <span className="text-warning">Vendor</span>
            </div>
          </Navbar.Brand>

          <div className="d-none d-lg-flex ms-auto">
            <Button variant="outline-secondary" className="me-2">
              <FiCalendar className="me-1" /> Calendar
            </Button>
            <Button variant="outline-secondary" className="me-2">
              <FiMessageSquare className="me-1" /> Messages{" "}
              <span className="badge bg-danger ms-1">3</span>
            </Button>
            <Button variant="primary">
              <FiDollarSign className="me-1" /> Upgrade Plan
            </Button>
          </div>

          <Button
            variant="link"
            className="d-lg-none ms-auto"
            onClick={() => setShowMobileMenu(true)}
          >
            <FiMenu size={24} />
          </Button>
        </Container>
      </Navbar>

      {/* Secondary Navigation Bar */}
      <Navbar bg="light" expand="lg" className="secondary-navbar py-0">
        <Container fluid>
          <Navbar.Toggle aria-controls="secondary-nav" className="d-lg-none" />
          <Navbar.Collapse id="secondary-nav">
            <Nav className="me-auto">
              {mainNavItems.map((item) => (
                <Nav.Item key={item.id}>
                  <Nav.Link
                    as={Link}
                    to={item.path}
                    className={`nav-link-main ${
                      isActive(item.path) ? "primary-bg" : ""
                    }`}
                  >
                    <span className="nav-icon">{item.icon}</span>
                    <span className="nav-label">{item.label}</span>
                  </Nav.Link>
                </Nav.Item>
              ))}
            </Nav>
          </Navbar.Collapse>

          <div className="d-flex align-items-center ms-auto">
            <div className="user-info d-flex align-items-center">
              <div className="avatar me-2">JD</div>
              <div>
                <div className="user-name">John Doe</div>
                <div className="user-role small text-muted">Premium Vendor</div>
              </div>
            </div>
          </div>
        </Container>
      </Navbar>

      {/* Storefront Sub-Navigation */}
      {location.pathname.startsWith("/storefront") && (
        <div className="storefront-subnav bg-white shadow-sm">
          <Container fluid>
            <Nav className="sub-nav">
              {storefrontNavItems.map((item) => (
                <Nav.Item key={item.id}>
                  <Nav.Link
                    as={Link}
                    to={item.path}
                    className={`nav-link-sub ${
                      location.pathname === item.path ? "active" : ""
                    }`}
                  >
                    <span className="nav-icon">{item.icon}</span>
                    <span className="nav-label">{item.label}</span>
                  </Nav.Link>
                </Nav.Item>
              ))}
            </Nav>
          </Container>
        </div>
      )}

      {/* Main Content */}
      <Container fluid className="main-content">
        <Outlet />
      </Container>

      {/* Mobile Menu Offcanvas */}
      <Offcanvas
        show={showMobileMenu}
        onHide={() => setShowMobileMenu(false)}
        placement="end"
      >
        <Offcanvas.Header className="border-bottom">
          <Offcanvas.Title>Menu</Offcanvas.Title>
          <Button variant="link" onClick={() => setShowMobileMenu(false)}>
            <FiX size={24} />
          </Button>
        </Offcanvas.Header>
        <Offcanvas.Body>
          <Nav className="flex-column">
            {mainNavItems.map((item) => (
              <Nav.Item key={item.id}>
                <Nav.Link
                  as={Link}
                  to={item.path}
                  className={`nav-link-main ${
                    isActive(item.path) ? "active" : ""
                  }`}
                  onClick={() => setShowMobileMenu(false)}
                >
                  <span className="nav-icon">{item.icon}</span>
                  <span className="nav-label">{item.label}</span>
                </Nav.Link>
              </Nav.Item>
            ))}
            <div className="mt-4">
              <Button variant="outline-secondary" className="w-100 mb-2">
                <FiCalendar className="me-2" /> Calendar
              </Button>
              <Button variant="outline-secondary" className="w-100 mb-2">
                <FiMessageSquare className="me-2" /> Messages{" "}
                <span className="badge bg-danger ms-1">3</span>
              </Button>
              <Button variant="primary" className="w-100">
                <FiDollarSign className="me-2" /> Upgrade Plan
              </Button>
            </div>
          </Nav>
        </Offcanvas.Body>
      </Offcanvas>
    </div>
  );
};

export default VendorDashboard;
