import React, { useState } from "react";
import {
  FaGavel,
  FaUserShield,
  FaCookieBite,
  FaCopyright,
  FaExclamationTriangle,
  FaChevronRight,
  FaAngleRight,
} from "react-icons/fa";

const TermsCondition = () => {
  const [activeSection, setActiveSection] = useState("terms");
  const primaryColor = "var(--primary-color)";

  const legalSections = {
    terms: {
      title: "Terms of Service",
      icon: <FaGavel />,
      content: `
Last Updated: 04 Oct 2025

By accessing or using Happywedz.com (the "Platform" / "Website"), you agree to these Terms. If you do not agree, please discontinue use immediately.

1. Acceptance of Terms
These Terms govern your access and use of Happywedz.com. By using the Website, creating an account, or communicating with vendors, you confirm that you have read, understood, and agreed to these Terms.
Happywedz reserves the right to modify these Terms at any time. Updates become effective once published.

2. Nature of the Platform
Happywedz.com is a wedding planning marketplace connecting:
• Couples / Users seeking wedding services
• Vendors / Service Providers offering wedding-related services

Happywedz is a digital intermediary only and does not provide or control vendor services.
All bookings, payments, cancellations, and service delivery are contracts solely between Users and Vendors.

3. User Eligibility
You confirm that you:
• Are at least 18 years old
• Have legal capacity to enter binding agreements
• Will use the platform lawfully

4. User Responsibilities
You agree not to:
• Provide false or misleading information
• Create fake or multiple accounts
• Post abusive, unlawful, or harmful content
• Infringe intellectual property
• Hack, disrupt, or misuse the platform
• Use bots or scrapers without permission

Accounts may be suspended or terminated for violations.

5. Vendor Responsibilities
Vendors must:
• Provide accurate business information
• Publish genuine pricing and media
• Deliver services professionally
• Honor commitments
• Respond to users in a timely manner

Happywedz is not responsible for vendor behavior or service quality.

6. Booking & Payments
Happywedz is not involved in pricing, payment collection, refunds, or disputes.
All service contracts are between Users and Vendors.

7. Account Termination
Accounts may be terminated due to fraud, violations, harmful content, or legal reasons.
Users may request account deletion via support.

8. Third-Party Links
Happywedz is not responsible for third-party content or policies.

9. Governing Law
These Terms are governed by Indian law.
Jurisdiction: Courts of [City/State – e.g., Pune, Maharashtra].
`,
    },

    privacy: {
      title: "Privacy Policy",
      icon: <FaUserShield />,
      content: `
Your privacy is important to us.

1. Information We Collect

a) Information You Provide
• Name, email, phone number
• Wedding details (date, location, budget)
• Vendor profile information
• Reviews, chats, photos, inquiries

b) Information Collected Automatically
• IP address
• Device & browser details
• Pages visited & activity logs
• Cookies & analytics data

c) Information from Vendors
Vendors may share booking details and quotations.

2. How We Use Information
• Platform functionality
• Vendor-user connections
• Communication & inquiries
• Personalization
• Security & fraud prevention
• Legal compliance

3. Information Sharing
We do not sell personal data.
Information may be shared with vendors, service providers, legal authorities, or in business transfers.

4. Data Protection & Retention
• Secure servers & restricted access
• Data retained only as required
• No system is 100% secure

5. Your Rights
You may request access, correction, deletion, or withdrawal of consent.
Contact: [Support Email]
`,
    },

    cookies: {
      title: "Cookie Policy",
      icon: <FaCookieBite />,
      content: `
Happywedz uses cookies to enhance user experience.

1. Types of Cookies

• Essential Cookies
Required for login, navigation, and security.

• Analytics Cookies
Used to analyze usage and improve performance.

• Functional Cookies
Store preferences like language and filters.

• Advertising Cookies
(If enabled) Used for remarketing and ads.

2. Third-Party Cookies
Services like Google Analytics or ad networks may set cookies.
You can disable cookies via browser settings, but some features may not work properly.
`,
    },

    intellectual: {
      title: "Intellectual Property Policy",
      icon: <FaCopyright />,
      content: `
1. Ownership
All content on Happywedz.com including text, logos, graphics, videos, databases, and code is owned by or licensed to Happywedz and protected by IP laws.

2. User & Vendor Content
By uploading content, you grant Happywedz a worldwide, royalty-free license to display, publish, format, distribute, and promote the content.

Content remains yours and can be removed unless required for legal, review, or past marketing purposes.

3. Copyright Infringement
If you believe your copyrighted work is misused:
Email: [Your Email]
Subject: Copyright Infringement Notice
`,
    },

    disclaimer: {
      title: "Disclaimer of Liability",
      icon: <FaExclamationTriangle />,
      content: `
1. Platform Disclaimer
Happywedz is a listing and discovery platform only.
We do not guarantee vendor quality, pricing, availability, or legality.

2. User-Vendor Interaction
All dealings are at your own risk.
Happywedz is not responsible for:
• Financial loss
• Service delays or cancellations
• Fraud or disputes
• Misrepresentation
• Vendor or user misconduct

3. No Warranty
The platform is provided "as is" and "as available".
We do not guarantee uninterrupted service, error-free content, or accuracy of listings.
`,
    },
  };

  // Helper to format content with bold headings and lists
  const formatContent = (content) => {
    return content
      .trim()
      .split("\n")
      .map((line, index) => {
        const trimmedLine = line.trim();
        if (!trimmedLine) return <br key={index} />;

        // Check for numbered headings (e.g., "1. Title")
        if (/^\d+\.\s/.test(trimmedLine) || /^[a-z]\)\s/.test(trimmedLine)) {
          return (
            <h5 key={index} className="fw-bold mt-4 mb-2 text-dark">
              {trimmedLine}
            </h5>
          );
        }

        // Check for bullet points
        if (trimmedLine.startsWith("•")) {
          return (
            <div key={index} className="d-flex align-items-start mb-2 ms-3">
              <span className="me-2" style={{ color: primaryColor }}>
                •
              </span>
              <span className="text-muted">
                {trimmedLine.substring(1).trim()}
              </span>
            </div>
          );
        }

        // Regular paragraph
        return (
          <p key={index} className="text-muted mb-2 leading-relaxed">
            {trimmedLine}
          </p>
        );
      });
  };

  return (
    <div className="terms-condition-page bg-light min-vh-100 py-5">
      <div className="container">
        {/* Hero Section */}
        <div className="text-center mb-5 mx-auto" style={{ maxWidth: "800px" }}>
          <h3 className="display-5 fw-bold text-dark mb-3">
            Legal Terms & Policies
          </h3>
          <div className="d-flex justify-content-center mb-3">
            <div
              style={{
                height: "4px",
                width: "80px",
                borderRadius: "2px",
                backgroundColor: primaryColor,
              }}
            ></div>
          </div>
          <p className="text-muted fs-18">
            Please review our policies carefully before using the platform.
          </p>
        </div>

        <div className="row">
          {/* Sidebar Navigation */}
          <div className="col-lg-3 mb-4 mb-lg-0">
            {/* Desktop Sidebar */}
            <div
              className="card border-0 shadow-sm rounded-4 sticky-lg-top d-none d-lg-block"
              style={{ top: "100px", zIndex: 1 }}
            >
              <div className="card-body p-2">
                <div className="list-group list-group-flush rounded-3">
                  {Object.keys(legalSections).map((key) => (
                    <button
                      key={key}
                      className={`list-group-item list-group-item-action d-flex align-items-center justify-content-between p-3 border-0 rounded-3 mb-1 transition-all ${
                        activeSection === key
                          ? "text-white shadow-sm"
                          : "bg-transparent text-secondary hover-bg-light"
                      }`}
                      onClick={() => {
                        setActiveSection(key);
                        window.scrollTo({ top: 0, behavior: "smooth" });
                      }}
                      style={{
                        transition: "all 0.2s ease",
                        backgroundColor:
                          activeSection === key ? primaryColor : "transparent",
                      }}
                    >
                      <div className="d-flex align-items-center">
                        <span
                          className={`me-3 ${
                            activeSection === key ? "text-white" : ""
                          }`}
                          style={{
                            color:
                              activeSection === key ? "white" : primaryColor,
                          }}
                        >
                          {legalSections[key].icon}
                        </span>
                        <span className="fw-semibold fs-14">
                          {legalSections[key].title}
                        </span>
                      </div>
                      {activeSection === key && <FaAngleRight />}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Mobile Dropdown */}
            <div className="d-lg-none mb-3">
              <select
                className="form-select form-select-lg shadow-sm border-0"
                value={activeSection}
                onChange={(e) => setActiveSection(e.target.value)}
                style={{
                  color: primaryColor,
                  fontWeight: "600",
                }}
              >
                {Object.keys(legalSections).map((key) => (
                  <option key={key} value={key}>
                    {legalSections[key].title}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Main Content Area */}
          <div className="col-lg-9">
            <div className="card border-0 shadow-lg rounded-4 overflow-hidden">
              <div className="card-header bg-white border-0 p-4 pb-0">
                <div className="d-flex align-items-center">
                  <div
                    className="p-3 rounded-circle me-3"
                    style={{
                      backgroundColor: "rgba(237, 17, 115, 0.1)", // Light pink opacity
                      color: primaryColor,
                    }}
                  >
                    {legalSections[activeSection].icon}
                  </div>
                  <h4 className="fw-bold mb-0 text-dark">
                    {legalSections[activeSection].title}
                  </h4>
                </div>
                <hr className="mt-4 mb-0 text-muted opacity-25" />
              </div>

              <div className="card-body p-4 p-md-5">
                <div className="legal-content-wrapper">
                  {formatContent(legalSections[activeSection].content)}
                </div>
              </div>

              <div className="card-footer bg-light border-0 p-4 text-center">
                <p className="text-muted small mb-0">
                  Have questions about our{" "}
                  {legalSections[activeSection].title.toLowerCase()}?
                  <a
                    href="/contact-us"
                    className="text-decoration-none fw-bold ms-1"
                    style={{ color: primaryColor }}
                  >
                    Contact Support
                  </a>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TermsCondition;
