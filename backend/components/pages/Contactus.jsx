import React, { useState } from "react";
import { FiMail, FiPhone, FiMapPin } from "react-icons/fi";
import Swal from "sweetalert2";
import { Briefcase, Heart, Mail, TrendingUp, Users } from "lucide-react";
import { useContact } from "../../hooks/useContact";

const Contactus = () => {
  const { submitContact, loading, error } = useContact();
  const [formData, setFormData] = useState({
    firstName: "",
    lastName: "",
    email: "",
    phone: "",
    message: "",
  });

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async () => {
    const { firstName, lastName, email, phone, message } = formData;

    // Basic validation
    if (
      !firstName.trim() ||
      !lastName.trim() ||
      !email.trim() ||
      !phone.trim() ||
      !message.trim()
    ) {
      Swal.fire({
        icon: "error",
        title: "Incomplete Form",
        text: "Please fill out all fields.",
      });
      return;
    }

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      Swal.fire({
        icon: "error",
        title: "Invalid Email",
        text: "Please enter a valid email address.",
      });
      return;
    }

    // Phone validation (simple 10-digit check)
    if (!/^\d{10}$/.test(phone)) {
      Swal.fire({
        icon: "error",
        text: "Please enter a valid 10-digit phone number.",
      });
      return;
    }

    try {
      await submitContact(formData);
      Swal.fire({
        icon: "success",
        text: "Form submitted successfully!",
        timer: 1500,
      });
      setFormData({
        firstName: "",
        lastName: "",
        email: "",
        phone: "",
        message: "",
      });
    } catch (err) {
      Swal.fire({
        icon: "error",
        title: "Error",
        text: error || "Failed to submit form. Please try again.",
      });
    }
  };

  const styles = {
    mainContainer: {
      backgroundColor: "#fff",
      minHeight: "100vh",
      padding: "40px 20px",
      fontFamily: "Arial, sans-serif",
    },
    mainWrapper: {
      maxWidth: "1200px",
      margin: "0 auto",
    },
    row: {
      display: "flex",
      flexWrap: "wrap",
      margin: "0 -15px",
    },
    leftCol: {
      flex: "0 0 60%",
      maxWidth: "60%",
      padding: "0 15px",
    },
    rightCol: {
      flex: "0 0 40%",
      maxWidth: "40%",
      padding: "0 15px",
    },
    formCard: {
      backgroundColor: "white",
      boxShadow:
        "rgba(17, 17, 26, 0.1) 0px 4px 16px, rgba(17, 17, 26, 0.1) 0px 8px 24px, rgba(17, 17, 26, 0.1) 0px 16px 56px",
      borderRadius: "8px",
      padding: "30px",
      marginBottom: "20px",
    },
    heading: {
      color: "#d63384",
      fontWeight: "bold",
      fontSize: "24px",
      marginBottom: "25px",
      marginTop: "0",
    },
    formRow: {
      display: "flex",
      gap: "15px",
      marginBottom: "20px",
    },
    formGroup: {
      flex: "1",
      marginBottom: "20px",
    },
    label: {
      fontSize: "13px",
      color: "#666",
      marginBottom: "5px",
      display: "block",
    },
    input: {
      width: "100%",
      padding: "16px 16px",
      borderRadius: "0px",
      backgroundColor: "#fce4ec",
      border: "none",
      fontSize: "14px",
      boxSizing: "border-box",
      outline: "none",
    },
    textarea: {
      width: "100%",
      padding: "10px 12px",
      borderRadius: "4px",
      backgroundColor: "#fce4ec",
      border: "1px solid #f8bbd0",
      fontSize: "14px",
      minHeight: "80px",
      resize: "vertical",
      boxSizing: "border-box",
      outline: "none",
    },
    button: {
      width: "100%",
      backgroundColor: "#d63384",
      color: "white",
      borderRadius: "4px",
      padding: "12px",
      fontWeight: "bold",
      border: "none",
      cursor: "pointer",
      fontSize: "14px",
    },
    sectionHeading: {
      color: "#d63384",
      fontSize: "18px",
      fontWeight: "bold",
      marginBottom: "15px",
      marginTop: "0",
    },
    contactBox: {
      backgroundColor: "white",
      borderRadius: "3px",
      boxShadow:
        "rgba(17, 17, 26, 0.1) 0px 4px 16px, rgba(17, 17, 26, 0.1) 0px 8px 24px, rgba(17, 17, 26, 0.1) 0px 10px 30px",
      padding: "20px",
      marginBottom: "15px",
    },
    contactTitle: {
      fontSize: "16px",
      color: "#d63384",
      marginBottom: "10px",
      marginTop: "0",
      fontWeight: "bold",
    },
    contactTitleSmall: {
      fontSize: "12px",
      color: "#999",
      marginBottom: "10px",
      marginTop: "0",
    },
    contactInfo: {
      color: "#333",
      marginBottom: "8px",
      fontSize: "14px",
      display: "flex",
      alignItems: "center",
      gap: "8px",
    },
    icon: {
      color: "#d63384",
      fontSize: "16px",
    },
    addressBox: {
      backgroundColor: "white",
      border: "1px solid #e5e5e5",
      borderRadius: "8px",
      padding: "20px",
      marginBottom: "15px",
    },
    locationTitle: {
      color: "#d63384",
      fontWeight: "bold",
      marginBottom: "8px",
      fontSize: "14px",
      display: "flex",
      alignItems: "center",
      gap: "8px",
    },
    addressText: {
      fontSize: "13px",
      color: "#666",
      marginBottom: "15px",
      lineHeight: "1.6",
    },
    categorySection: {
      textAlign: "center",
      padding: "25px",
      marginBottom: "15px",
    },
    categoryHeading: {
      color: "#d63384",
      fontWeight: "bold",
      marginBottom: "10px",
      fontSize: "30px",
      marginTop: "0",
    },
    categoryText: {
      fontSize: "20px",
      color: "#000",
      lineHeight: "1.7",
      marginBottom: "0",
    },
    appButtons: {
      marginTop: "15px",
    },
    appButton: {
      display: "block",
      width: "140px",
      marginBottom: "10px",
    },
    appImg: {
      width: "100%",
      height: "auto",
    },
    contactCardsContainer: {
      width: "100%",
      maxWidth: "1200px",
      margin: "0 auto",
      padding: "40px 24px",
    },
    header: {
      textAlign: "center",
      marginBottom: "48px",
    },
    mainTitle: {
      fontSize: "36px",
      fontWeight: "bold",
      color: "#1f2937",
      marginBottom: "12px",
    },
    subtitle: {
      fontSize: "16px",
      color: "#6b7280",
    },
    grid: {
      display: "grid",
      gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
      gap: "24px",
      marginBottom: "40px",
    },
    contactCard: {
      backgroundColor: "white",
      borderRadius: "2px",
      padding: "24px",
      boxShadow: "0 4px 6px rgba(0, 0, 0, 0.07)",
      border: "1px solid #f3f4f6",
      transition: "all 0.3s ease",
      cursor: "pointer",
    },
    iconWrapper: {
      width: "56px",
      height: "56px",
      borderRadius: "12px",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      color: "white",
      marginBottom: "16px",
      transition: "transform 0.3s ease",
    },
    cardTitle: {
      fontSize: "20px",
      fontWeight: "bold",
      color: "#1f2937",
      marginBottom: "8px",
    },
    cardText: {
      fontSize: "14px",
      color: "#6b7280",
      lineHeight: "1.6",
      marginBottom: "16px",
    },
    emailLink: {
      display: "inline-flex",
      alignItems: "center",
      gap: "6px",
      color: "#e41f81",
      fontSize: "14px",
      fontWeight: "500",
      textDecoration: "none",
      transition: "color 0.2s ease",
    },
    footer: {
      textAlign: "center",
      marginTop: "40px",
    },
    footerText: {
      fontSize: "14px",
      color: "#9ca3af",
    },
    footerLink: {
      color: "#e41f81",
      fontWeight: "500",
      textDecoration: "none",
    },
  };

  const contactCards = [
    {
      icon: <Briefcase size={24} />,
      title: "Vendors",
      description:
        "Are you an expert vendor eager to expand your business opportunities? Connect with us and discover the ideal platform to grow.",
      email: "support@happywedz.com",
      gradient: "linear-gradient(135deg, #ec4899 0%, #f43f5e 100%)",
    },

    {
      icon: <TrendingUp size={24} />,
      title: "Marketing Collaborations",
      description:
        "For direct collaborations—including promotional events, shoots, or paid opportunities—reach out to us.",
      email: "support@happywedz.com",
      gradient: "linear-gradient(135deg, #ec4899 0%, #f43f5e 100%)",
    },
    {
      icon: <Heart size={24} />,
      title: "Wedding Submissions",
      description:
        "We're passionate about celebrating weddings on happywedz.com! Share your wedding story, photos, and vendor details with us.",
      email: "support@happywedz.com",
      gradient: "linear-gradient(135deg, #ec4899 0%, #f43f5e 100%)",
    },
    {
      icon: <Users size={24} />,
      title: "Careers",
      description:
        "We have a team of dedicated professionals on the network, and we're always on the lookout for new talent. Join us today!",
      email: "support@happywedz.com",
      gradient: "linear-gradient(135deg, #ec4899 0%, #f43f5e 100%)",
    },
    {
      icon: <Mail size={24} />,
      title: "Customers",
      description:
        "We aim to connect you with the very best in premium vendors. Share your feedback or concerns to help us improve.",
      email: "support@happywedz.com",
      gradient: "linear-gradient(135deg, #ec4899 0%, #f43f5e 100%)",
    },
  ];

  const mobileStyles = `
    @media (max-width: 768px) {
      .left-col, .right-col {
        flex: 0 0 100% !important;
        max-width: 100% !important;
      }
      .form-row {
        flex-direction: column;
        gap: 0 !important;
      }
    }
  `;

  const handleCardHover = (e, isHovering) => {
    if (isHovering) {
      e.currentTarget.style.transform = "translateY(-8px)";
      e.currentTarget.style.boxShadow = "0 20px 25px rgba(0, 0, 0, 0.1)";
      const icon = e.currentTarget.querySelector(".icon-wrapper");
      if (icon) icon.style.transform = "scale(1.1)";
    } else {
      e.currentTarget.style.transform = "translateY(0)";
      e.currentTarget.style.boxShadow = "0 4px 6px rgba(0, 0, 0, 0.07)";
      const icon = e.currentTarget.querySelector(".icon-wrapper");
      if (icon) icon.style.transform = "scale(1)";
    }
  };

  const handleLinkHover = (e, isHovering) => {
    e.currentTarget.style.color = isHovering ? "#c7185e" : "#e41f81";
  };

  return (
    <div style={styles.mainContainer}>
      <style>{mobileStyles}</style>
      <div style={styles.mainWrapper}>
        <div style={styles.row}>
          {/* Left Column - Contact Form */}
          <div style={styles.leftCol} className="left-col">
            <div style={styles.formCard}>
              <h4 className="fw-bold dark-pink-text text-center d-flex justify-content-center mb-4">
                CONTACT US
              </h4>
              <div>
                <div style={styles.formRow} className="form-row">
                  <div style={styles.formGroup}>
                    <label style={styles.label}>First Name</label>
                    <input
                      type="text"
                      name="firstName"
                      placeholder="First Name"
                      value={formData.firstName}
                      onChange={handleChange}
                      style={styles.input}
                      className="fs-12"
                    />
                  </div>
                  <div style={styles.formGroup}>
                    <label style={styles.label}>Last Name</label>
                    <input
                      type="text"
                      name="lastName"
                      placeholder="Last Name"
                      value={formData.lastName}
                      onChange={handleChange}
                      style={styles.input}
                      className="fs-12"
                    />
                  </div>
                </div>

                <div style={styles.formRow} className="form-row">
                  <div style={styles.formGroup}>
                    <label style={styles.label}>Email</label>
                    <input
                      type="email"
                      name="email"
                      placeholder="Email"
                      value={formData.email}
                      onChange={handleChange}
                      style={styles.input}
                      className="fs-12"
                    />
                  </div>
                  <div style={styles.formGroup}>
                    <label style={styles.label}>Phone</label>
                    <input
                      type="tel"
                      name="phone"
                      placeholder="Phone"
                      value={formData.phone}
                      onChange={handleChange}
                      style={styles.input}
                      className="fs-12"
                    />
                  </div>
                </div>

                <div style={styles.formGroup}>
                  <label style={styles.label}>Message</label>
                  <textarea
                    name="message"
                    placeholder="Message"
                    value={formData.message}
                    onChange={handleChange}
                    style={styles.textarea}
                    className="fs-12"
                  ></textarea>
                </div>

                <button
                  onClick={handleSubmit}
                  style={styles.button}
                  disabled={loading}
                >
                  {loading ? "SUBMITTING..." : "SUBMIT"}
                </button>
              </div>
            </div>

            {/* Vendors Section */}
            <div style={styles.contactCardsContainer}>
              <div style={styles.header}>
                <h4 style={styles.mainTitle}>Get In Touch</h4>
                <p className="fs-14" style={styles.subtitle}>
                  We'd love to hear from you
                </p>
              </div>

              <div style={styles.grid}>
                {contactCards.map((card, index) => (
                  <div
                    key={index}
                    style={styles.contactCard}
                    onMouseEnter={(e) => handleCardHover(e, true)}
                    onMouseLeave={(e) => handleCardHover(e, false)}
                  >
                    <div
                      className="icon-wrapper "
                      style={{
                        ...styles.iconWrapper,
                        background: card.gradient,
                      }}
                    >
                      {card.icon}
                    </div>

                    <span className="fs-16" style={styles.cardTitle}>
                      {card.title}
                    </span>

                    <p className="fs-14" style={styles.cardText}>
                      {card.description}
                    </p>

                    <a
                      href={`mailto:${card.email}`}
                      style={styles.emailLink}
                      onMouseEnter={(e) => handleLinkHover(e, true)}
                      onMouseLeave={(e) => handleLinkHover(e, false)}
                    >
                      <Mail size={16} />
                      {card.email}
                    </a>
                  </div>
                ))}
              </div>

              {/* <div style={styles.footer}>
                <p style={styles.footerText}>
                  Or reach out to us on{" "}
                  <a
                    href="#"
                    style={styles.footerLink}
                    onMouseEnter={(e) => handleLinkHover(e, true)}
                    onMouseLeave={(e) => handleLinkHover(e, false)}
                  >
                    Instagram
                  </a>
                </p>
              </div> */}
            </div>
          </div>

          {/* Right Column - Contact Info */}
          <div style={styles.rightCol} className="right-col">
            {/* For Vendors */}
            <p className="fs-22 dark-pink-text fw-medium">
              Connect us to get best Deals
            </p>
            <div style={styles.contactBox}>
              <p
                style={{
                  ...styles.contactTitle,
                  marginTop: "15px",
                  borderBottom: "1px solid #ec4c9cff", // line below heading
                  display: "inline-block",
                  paddingBottom: "5px",
                  marginBottom: "15px",
                }}
              >
                For Vendors
              </p>
              <div style={styles.contactInfo} className="mt-3">
                <FiMail size={25} className="primary-text" />
                <span className="fs-14 fw-bold">support@happywedz.com</span>
              </div>
              <div style={styles.contactInfo} className="mt-5">
                <FiPhone size={25} className="primary-text" />
                <span className="fs-14 fw-bold">+91 456 700</span>
              </div>
            </div>

            <div style={styles.contactBox}>
              <p
                style={{
                  ...styles.contactTitle,
                  marginTop: "15px",
                  borderBottom: "1px solid #ec4c9cff", // line below heading
                  display: "inline-block",
                  paddingBottom: "5px",
                  marginBottom: "15px",
                }}
              >
                For Users
              </p>
              <div style={styles.contactInfo} className="mt-3">
                <FiMail size={25} className="primary-text" />
                <span className="fs-14 fw-bold">support@happywedz.com</span>
              </div>
              <div style={styles.contactInfo} className="mt-5">
                <FiPhone size={25} className="primary-text" />
                <span className="fs-14 fw-bold">+91 456 700</span>
              </div>
            </div>

            <div style={styles.contactBox}>
              <p
                style={{
                  ...styles.contactTitle,
                  marginTop: "15px",
                  borderBottom: "1px solid #ec4c9cff", // line below heading
                  display: "inline-block",
                  paddingBottom: "5px",
                  marginBottom: "15px",
                }}
              >
                Registered Address
              </p>
              <div style={styles.contactInfo} className="mt-2">
                <FiMapPin size={25} className="primary-text" />
                <div className="d-flex flex-column">
                  <span className="fs-14 fw-bold">
                    29/1B, Sinhgad Rd, next to Vidya Sahakri Bank,
                    <br /> Near Veer Baji Pasalkar Chowk,
                    <br /> Kirti Nagar, Vadgaon Budruk,
                    <br /> Pune, Maharashtra 411041
                  </span>
                </div>
              </div>
            </div>

            <div style={styles.contactBox}>
              <div className="d-flex flex-wrap justify-content-center gap-4">
                <a
                  href="https://play.google.com/store/apps/details?id=com.happy.happy_weds_vendors"
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label="Download HappyWedz App on Google Play Store"
                >
                  <img
                    src="/images/cta/playstore.svg"
                    alt="Google Play Store"
                    style={{
                      width: "120px",
                      height: "120px",
                      objectFit: "contain",
                    }}
                  />
                </a>
                <a
                  href="https://apps.apple.com/app/happywedz/id123456789"
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label="Download HappyWedz App on Apple App Store"
                >
                  <img
                    src="/images/cta/appstore.svg"
                    alt="Apple App Store"
                    style={{
                      width: "120px",
                      height: "120px",
                      objectFit: "contain",
                    }}
                  />
                </a>
              </div>
              <p
                style={{ fontSize: "16px", color: "#000" }}
                className="text-center"
              >
                {" "}
                Gets the Happywedz App
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Contactus;
