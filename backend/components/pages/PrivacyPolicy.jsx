import React from "react";
import { Shield, Mail, Globe, CheckCircle } from "lucide-react";

export default function PrivacyPolicy() {
  return (
    <div style={{ minHeight: "100vh", background: "#f8f9fa" }}>
      {/* Header */}
      <div
        style={{
          background: "white",
          boxShadow: "0 2px 10px rgba(0,0,0,0.08)",
          position: "sticky",
          top: 0,
          zIndex: 1000,
        }}
      >
        <div className="container py-3">
          <div className="d-flex align-items-center justify-content-between">
            <div className="d-flex align-items-center">
              <Shield
                size={32}
                style={{ color: "#ED1173", marginRight: "12px" }}
              />
              <h1
                style={{
                  margin: 0,
                  fontSize: "24px",
                  fontWeight: "700",
                  color: "#1a1a1a",
                }}
              >
                HappyWedz Business
              </h1>
            </div>
            <a
              href="https://www.happywedz.com"
              style={{
                color: "#ED1173",
                textDecoration: "none",
                fontWeight: "600",
              }}
            >
              <Globe
                size={20}
                style={{ marginRight: "6px", verticalAlign: "middle" }}
              />
              Visit Website
            </a>
          </div>
        </div>
      </div>

      {/* Hero Section */}
      <div style={{ background: "#ED1173", color: "white", padding: "60px 0" }}>
        <div className="container">
          <div className="text-center">
            <Shield size={64} style={{ marginBottom: "20px", opacity: 0.9 }} />
            <h1
              style={{
                fontSize: "48px",
                fontWeight: "800",
                marginBottom: "16px",
              }}
            >
              Privacy Policy
            </h1>
            <p
              style={{
                fontSize: "18px",
                maxWidth: "800px",
                margin: "0 auto 24px",
                opacity: 0.95,
                lineHeight: "1.6",
              }}
            >
              This Privacy Policy explains how HappyWedz Business collects,
              uses, discloses, and protects your personal data when you use our
              Vendor App and website.
            </p>
            <div
              style={{
                display: "inline-block",
                padding: "12px 32px",
                background: "rgba(255,255,255,0.2)",
                borderRadius: "30px",
                fontSize: "14px",
                fontWeight: "600",
                backdropFilter: "blur(10px)",
              }}
            >
              <strong>Effective Date:</strong> January 1, 2025 |{" "}
              <strong>Last Updated:</strong> January 1, 2025
            </div>
          </div>
        </div>
      </div>

      {/* Compliance Badge */}
      <div
        className="container"
        style={{ marginTop: "-30px", marginBottom: "40px" }}
      >
        <div
          style={{
            background: "white",
            borderRadius: "16px",
            padding: "20px",
            boxShadow: "0 4px 20px rgba(195,17,98,0.15)",
            textAlign: "center",
            border: "2px solid #ED1173",
          }}
        >
          <div className="d-flex align-items-center justify-content-center flex-wrap">
            <CheckCircle
              size={24}
              style={{ color: "#ED1173", marginRight: "12px" }}
            />
            <span
              style={{ fontSize: "16px", fontWeight: "600", color: "#1a1a1a" }}
            >
              Compliant with DPDP Act 2023, IT Act 2000 & GDPR
            </span>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="container pb-5">
        <div
          style={{
            background: "white",
            borderRadius: "16px",
            padding: "50px",
            boxShadow: "0 4px 20px rgba(0,0,0,0.08)",
          }}
        >
          {/* Section 1 */}
          <div style={{ marginBottom: "50px" }}>
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "700",
                color: "#ED1173",
                marginBottom: "20px",
                borderBottom: "3px solid #ED1173",
                paddingBottom: "12px",
                display: "inline-block",
              }}
            >
              Purpose of Data Collection
            </h2>
            <p
              style={{
                fontSize: "16px",
                lineHeight: "1.8",
                color: "#333",
                marginBottom: "16px",
              }}
            >
              We collect and process your personal data for{" "}
              <strong>lawful purposes</strong>, including:
            </p>
            <ul
              style={{
                fontSize: "16px",
                lineHeight: "2",
                color: "#444",
                paddingLeft: "24px",
              }}
            >
              <li>Creating and managing your vendor account</li>
              <li>
                Displaying your profile, products, and services on HappyWedz
                Business
              </li>
              <li>Facilitating client-vendor communication and bookings</li>
              <li>Processing payments and invoices</li>
              <li>Providing technical support and customer service</li>
              <li>
                Sending updates, notifications, and promotional messages (with
                your consent)
              </li>
              <li>Ensuring security, fraud prevention, and legal compliance</li>
            </ul>
          </div>

          {/* Section 2 */}
          <div style={{ marginBottom: "50px" }}>
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "700",
                color: "#ED1173",
                marginBottom: "20px",
                borderBottom: "3px solid #ED1173",
                paddingBottom: "12px",
                display: "inline-block",
              }}
            >
              Personal Data We Collect
            </h2>
            <p
              style={{
                fontSize: "16px",
                lineHeight: "1.8",
                color: "#333",
                marginBottom: "20px",
              }}
            >
              We may collect the following categories of personal data:
            </p>

            <div style={{ marginBottom: "24px" }}>
              <h3
                style={{
                  fontSize: "20px",
                  fontWeight: "700",
                  color: "#1a1a1a",
                  marginBottom: "12px",
                }}
              >
                a. Identification & Contact Data
              </h3>
              <ul
                style={{
                  fontSize: "16px",
                  lineHeight: "1.9",
                  color: "#444",
                  paddingLeft: "24px",
                }}
              >
                <li>Name, business name</li>
                <li>Mobile number, email address</li>
                <li>Business address or service location</li>
              </ul>
            </div>

            <div style={{ marginBottom: "24px" }}>
              <h3
                style={{
                  fontSize: "20px",
                  fontWeight: "700",
                  color: "#1a1a1a",
                  marginBottom: "12px",
                }}
              >
                b. Business & Financial Information
              </h3>
              <ul
                style={{
                  fontSize: "16px",
                  lineHeight: "1.9",
                  color: "#444",
                  paddingLeft: "24px",
                }}
              >
                <li>Bank details or payment information</li>
                <li>GST, PAN or business registration number</li>
              </ul>
            </div>

            <div style={{ marginBottom: "24px" }}>
              <h3
                style={{
                  fontSize: "20px",
                  fontWeight: "700",
                  color: "#1a1a1a",
                  marginBottom: "12px",
                }}
              >
                c. Usage & Device Data
              </h3>
              <ul
                style={{
                  fontSize: "16px",
                  lineHeight: "1.9",
                  color: "#444",
                  paddingLeft: "24px",
                }}
              >
                <li>Device identifiers (IMEI, IP address, browser type)</li>
                <li>Location data (with permission)</li>
                <li>Log files and analytics data</li>
              </ul>
            </div>

            <div style={{ marginBottom: "24px" }}>
              <h3
                style={{
                  fontSize: "20px",
                  fontWeight: "700",
                  color: "#1a1a1a",
                  marginBottom: "12px",
                }}
              >
                d. Uploaded Content
              </h3>
              <ul
                style={{
                  fontSize: "16px",
                  lineHeight: "1.9",
                  color: "#444",
                  paddingLeft: "24px",
                }}
              >
                <li>
                  Photos, videos, logos, and other media you upload to your
                  profile
                </li>
              </ul>
            </div>
          </div>

          {/* Section 3 */}
          <div style={{ marginBottom: "50px" }}>
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "700",
                color: "#ED1173",
                marginBottom: "20px",
                borderBottom: "3px solid #ED1173",
                paddingBottom: "12px",
                display: "inline-block",
              }}
            >
              Legal Basis for Processing
            </h2>
            <p
              style={{
                fontSize: "16px",
                lineHeight: "1.8",
                color: "#333",
                marginBottom: "16px",
              }}
            >
              We process your data under the following legal bases:
            </p>
            <ul
              style={{
                fontSize: "16px",
                lineHeight: "2",
                color: "#444",
                paddingLeft: "24px",
              }}
            >
              <li>
                <strong>Consent:</strong> You have given consent to process your
                data (e.g., for marketing, notifications)
              </li>
              <li>
                <strong>Contractual necessity:</strong> To perform our service
                obligations (e.g., managing vendor listings, payments)
              </li>
              <li>
                <strong>Legal obligation:</strong> To comply with applicable
                laws
              </li>
              <li>
                <strong>Legitimate interests:</strong> To improve our platform
                and prevent misuse or fraud
              </li>
            </ul>
          </div>

          {/* Section 4 */}
          <div style={{ marginBottom: "50px" }}>
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "700",
                color: "#ED1173",
                marginBottom: "20px",
                borderBottom: "3px solid #ED1173",
                paddingBottom: "12px",
                display: "inline-block",
              }}
            >
              Data Sharing and Disclosure
            </h2>
            <p
              style={{
                fontSize: "16px",
                lineHeight: "1.8",
                color: "#333",
                marginBottom: "16px",
              }}
            >
              We <strong>do not sell</strong> your data. However, we may share
              it with:
            </p>
            <ul
              style={{
                fontSize: "16px",
                lineHeight: "2",
                color: "#444",
                paddingLeft: "24px",
                marginBottom: "20px",
              }}
            >
              <li>
                <strong>Clients:</strong> So they can view vendor profiles and
                contact you
              </li>
              <li>
                <strong>Service providers:</strong> For hosting, payment
                gateways, analytics, communication, and marketing
              </li>
              <li>
                <strong>Legal authorities:</strong> When required to comply with
                applicable law or legal processes
              </li>
            </ul>
            <div
              style={{
                padding: "16px",
                background: "#fff3cd",
                borderLeft: "4px solid #ffc107",
                borderRadius: "8px",
              }}
            >
              <p
                style={{
                  margin: 0,
                  fontSize: "16px",
                  color: "#856404",
                  lineHeight: "1.7",
                }}
              >
                <strong>Note:</strong> All third parties handling your data are
                bound by confidentiality and data protection agreements.
              </p>
            </div>
          </div>

          {/* Section 5 */}
          <div style={{ marginBottom: "50px" }}>
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "700",
                color: "#ED1173",
                marginBottom: "20px",
                borderBottom: "3px solid #ED1173",
                paddingBottom: "12px",
                display: "inline-block",
              }}
            >
              Data Storage and Retention
            </h2>
            <p
              style={{
                fontSize: "16px",
                lineHeight: "1.8",
                color: "#333",
                marginBottom: "16px",
              }}
            >
              Your personal data is securely stored on servers located in{" "}
              <strong>India</strong> and/or other jurisdictions compliant with
              Indian law.
            </p>
            <p
              style={{
                fontSize: "16px",
                lineHeight: "1.8",
                color: "#333",
                marginBottom: "16px",
              }}
            >
              We retain data:
            </p>
            <ul
              style={{
                fontSize: "16px",
                lineHeight: "2",
                color: "#444",
                paddingLeft: "24px",
                marginBottom: "16px",
              }}
            >
              <li>As long as your vendor account is active</li>
              <li>
                Or as required by applicable tax, accounting, or legal
                regulations
              </li>
            </ul>
            <p style={{ fontSize: "16px", lineHeight: "1.8", color: "#333" }}>
              When data is no longer required, it will be{" "}
              <strong>safely deleted or anonymized</strong>.
            </p>
          </div>

          {/* Section 6 */}
          <div style={{ marginBottom: "50px" }}>
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "700",
                color: "#ED1173",
                marginBottom: "20px",
                borderBottom: "3px solid #ED1173",
                paddingBottom: "12px",
                display: "inline-block",
              }}
            >
              Security Measures
            </h2>
            <p
              style={{
                fontSize: "16px",
                lineHeight: "1.8",
                color: "#333",
                marginBottom: "16px",
              }}
            >
              We implement <strong>reasonable security practices</strong> under
              Section 43A of the <strong>IT Act, 2000</strong>, including:
            </p>
            <ul
              style={{
                fontSize: "16px",
                lineHeight: "2",
                color: "#444",
                paddingLeft: "24px",
                marginBottom: "16px",
              }}
            >
              <li>Data encryption during transmission and storage</li>
              <li>Restricted access to personal data</li>
              <li>Regular audits and firewalls</li>
            </ul>
            <div
              style={{
                padding: "16px",
                background: "#d1ecf1",
                borderLeft: "4px solid #17a2b8",
                borderRadius: "8px",
              }}
            >
              <p
                style={{
                  margin: 0,
                  fontSize: "16px",
                  color: "#0c5460",
                  lineHeight: "1.7",
                }}
              >
                However, no system is completely secure, and we cannot guarantee
                absolute protection.
              </p>
            </div>
          </div>

          {/* Section 7 */}
          <div style={{ marginBottom: "50px" }}>
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "700",
                color: "#ED1173",
                marginBottom: "20px",
                borderBottom: "3px solid #ED1173",
                paddingBottom: "12px",
                display: "inline-block",
              }}
            >
              Your Rights (Under DPDP Act, 2023)
            </h2>
            <p
              style={{
                fontSize: "16px",
                lineHeight: "1.8",
                color: "#333",
                marginBottom: "16px",
              }}
            >
              You have the following rights:
            </p>
            <ul
              style={{
                fontSize: "16px",
                lineHeight: "2",
                color: "#444",
                paddingLeft: "24px",
                marginBottom: "16px",
              }}
            >
              <li>
                <strong>Right to Access:</strong> Request a copy of your data
              </li>
              <li>
                <strong>Right to Correction:</strong> Request corrections or
                updates
              </li>
              <li>
                <strong>Right to Erasure:</strong> Request deletion of your data
              </li>
              <li>
                <strong>Right to Withdraw Consent:</strong> Stop receiving
                marketing or other non-essential communications
              </li>
              <li>
                <strong>Right to Grievance Redressal:</strong> File a complaint
                regarding data handling
              </li>
            </ul>
            <div
              style={{
                padding: "20px",
                background: "#f8f9fa",
                borderRadius: "12px",
                border: "2px solid #ED1173",
              }}
            >
              <p
                style={{
                  margin: 0,
                  fontSize: "16px",
                  color: "#333",
                  lineHeight: "1.7",
                }}
              >
                To exercise these rights, contact our{" "}
                <strong>Data Protection Officer (DPO)</strong> at:{" "}
                <a
                  href="mailto:privacy@happywedz.com"
                  style={{
                    color: "#ED1173",
                    textDecoration: "none",
                    fontWeight: "600",
                  }}
                >
                  privacy@happywedz.com
                </a>
              </p>
              <p
                style={{
                  margin: "12px 0 0 0",
                  fontSize: "16px",
                  color: "#333",
                }}
              >
                We will respond within <strong>30 days</strong> of receiving
                your request.
              </p>
            </div>
          </div>

          {/* Section 8 */}
          <div style={{ marginBottom: "50px" }}>
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "700",
                color: "#ED1173",
                marginBottom: "20px",
                borderBottom: "3px solid #ED1173",
                paddingBottom: "12px",
                display: "inline-block",
              }}
            >
              Children's Data
            </h2>
            <p
              style={{
                fontSize: "16px",
                lineHeight: "1.8",
                color: "#333",
                marginBottom: "16px",
              }}
            >
              HappyWedz Business does not knowingly collect data from
              individuals under <strong>18 years of age</strong>. If such data
              is identified, it will be deleted immediately.
            </p>
          </div>

          {/* Section 9 */}
          <div style={{ marginBottom: "50px" }}>
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "700",
                color: "#ED1173",
                marginBottom: "20px",
                borderBottom: "3px solid #ED1173",
                paddingBottom: "12px",
                display: "inline-block",
              }}
            >
              International Data Transfer
            </h2>
            <p
              style={{
                fontSize: "16px",
                lineHeight: "1.8",
                color: "#333",
                marginBottom: "16px",
              }}
            >
              If data is transferred outside India, it will be done in
              accordance with <strong>Section 16 of the DPDP Act</strong> and
              only to jurisdictions ensuring{" "}
              <strong>adequate data protection standards</strong>.
            </p>
          </div>

          {/* Section 10 */}
          <div style={{ marginBottom: "50px" }}>
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "700",
                color: "#ED1173",
                marginBottom: "20px",
                borderBottom: "3px solid #ED1173",
                paddingBottom: "12px",
                display: "inline-block",
              }}
            >
              Cookies and Tracking
            </h2>
            <p
              style={{
                fontSize: "16px",
                lineHeight: "1.8",
                color: "#333",
                marginBottom: "16px",
              }}
            >
              Our website and app may use cookies and similar technologies to:
            </p>
            <ul
              style={{
                fontSize: "16px",
                lineHeight: "2",
                color: "#444",
                paddingLeft: "24px",
                marginBottom: "16px",
              }}
            >
              <li>Personalize user experience</li>
              <li>Analyze traffic and improve functionality</li>
            </ul>
            <p style={{ fontSize: "16px", lineHeight: "1.8", color: "#333" }}>
              You may choose to disable cookies in your browser settings, though
              some features may not function properly.
            </p>
          </div>

          {/* Section 11 */}
          <div style={{ marginBottom: "50px" }}>
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "700",
                color: "#ED1173",
                marginBottom: "20px",
                borderBottom: "3px solid #ED1173",
                paddingBottom: "12px",
                display: "inline-block",
              }}
            >
              App Permissions (for Vendor App)
            </h2>
            <p
              style={{
                fontSize: "16px",
                lineHeight: "1.8",
                color: "#333",
                marginBottom: "16px",
              }}
            >
              To provide full functionality, the app may request access to:
            </p>
            <ul
              style={{
                fontSize: "16px",
                lineHeight: "2",
                color: "#444",
                paddingLeft: "24px",
                marginBottom: "16px",
              }}
            >
              <li>
                <strong>Camera & Photos:</strong> For uploading vendor images
              </li>
              <li>
                <strong>Storage:</strong> To save and upload business-related
                media
              </li>
              <li>
                <strong>Location:</strong> To show your service areas
              </li>
              <li>
                <strong>Notifications:</strong> To send booking updates and
                alerts
              </li>
            </ul>
            <p style={{ fontSize: "16px", lineHeight: "1.8", color: "#333" }}>
              You may manage these permissions in your phone's settings.
            </p>
          </div>

          {/* Grievance Officer Section */}
          <div
            style={{
              marginBottom: "50px",
              padding: "30px",
              background: "#ED1173",
              borderRadius: "16px",
              color: "white",
            }}
          >
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "700",
                marginBottom: "20px",
              }}
            >
              Grievance Officer / Data Protection Officer
            </h2>
            <p
              style={{ marginBottom: "20px", lineHeight: "1.8", opacity: 0.95 }}
            >
              In compliance with the{" "}
              <strong>
                IT (Reasonable Security Practices and Procedures and Sensitive
                Personal Data or Information) Rules, 2011
              </strong>
              , and the <strong>DPDP Act, 2023</strong>, our Grievance Officer
              is:
            </p>
            <div
              style={{
                background: "rgba(255,255,255,0.15)",
                padding: "24px",
                borderRadius: "12px",
                backdropFilter: "blur(10px)",
              }}
            >
              <p style={{ margin: "0 0 12px 0", fontSize: "16px" }}>
                <strong>Designation:</strong> Data Protection Officer
              </p>
              <p style={{ margin: "0 0 12px 0", fontSize: "16px" }}>
                <strong>Email:</strong>{" "}
                <a
                  href="mailto:privacy@happywedz.com"
                  style={{ color: "white", textDecoration: "underline" }}
                >
                  privacy@happywedz.com
                </a>
              </p>
              <p style={{ margin: "0", fontSize: "16px" }}>
                <strong>Company:</strong> HappyWedz Technologies Pvt. Ltd.
              </p>
            </div>
          </div>

          {/* Section 13 */}
          <div style={{ marginBottom: "50px" }}>
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "700",
                color: "#ED1173",
                marginBottom: "20px",
                borderBottom: "3px solid #ED1173",
                paddingBottom: "12px",
                display: "inline-block",
              }}
            >
              Updates to This Policy
            </h2>
            <p style={{ fontSize: "16px", lineHeight: "1.8", color: "#333" }}>
              We may revise this Privacy Policy periodically to comply with new
              laws or improve transparency. Updated versions will be published
              on our website and app with a revised "Last Updated" date.
            </p>
          </div>

          {/* Contact Section */}
          <div
            style={{
              padding: "40px",
              background: "#f8f9fa",
              borderRadius: "16px",
              border: "2px solid #ED1173",
            }}
          >
            <h2
              style={{
                fontSize: "28px",
                fontWeight: "700",
                color: "#ED1173",
                marginBottom: "24px",
                textAlign: "center",
              }}
            >
              Contact Us
            </h2>
            <p
              style={{
                fontSize: "16px",
                color: "#333",
                marginBottom: "30px",
                textAlign: "center",
                lineHeight: "1.8",
              }}
            >
              For any privacy-related questions or requests, contact us at:
            </p>
            <div className="row justify-content-center">
              <div className="col-md-6 mb-3">
                <div
                  style={{
                    padding: "24px",
                    background: "white",
                    borderRadius: "12px",
                    textAlign: "center",
                    boxShadow: "0 2px 10px rgba(195,17,98,0.1)",
                  }}
                >
                  <Mail
                    size={32}
                    style={{ color: "#ED1173", marginBottom: "12px" }}
                  />
                  <p
                    style={{
                      margin: "0 0 8px 0",
                      fontWeight: "600",
                      color: "#1a1a1a",
                      fontSize: "16px",
                    }}
                  >
                    Email
                  </p>
                  <a
                    href="mailto:support@happywedz.com"
                    style={{
                      color: "#ED1173",
                      textDecoration: "none",
                      fontSize: "16px",
                      fontWeight: "600",
                    }}
                  >
                    support@happywedz.com
                  </a>
                </div>
              </div>
              <div className="col-md-6 mb-3">
                <div
                  style={{
                    padding: "24px",
                    background: "white",
                    borderRadius: "12px",
                    textAlign: "center",
                    boxShadow: "0 2px 10px rgba(195,17,98,0.1)",
                  }}
                >
                  <Globe
                    size={32}
                    style={{ color: "#ED1173", marginBottom: "12px" }}
                  />
                  <p
                    style={{
                      margin: "0 0 8px 0",
                      fontWeight: "600",
                      color: "#1a1a1a",
                      fontSize: "16px",
                    }}
                  >
                    Website
                  </p>
                  <a
                    href="https://www.happywedz.com"
                    style={{
                      color: "#ED1173",
                      textDecoration: "none",
                      fontSize: "16px",
                      fontWeight: "600",
                    }}
                  >
                    www.happywedz.com
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div
          style={{
            textAlign: "center",
            marginTop: "40px",
            paddingBottom: "20px",
          }}
        >
          <p style={{ fontSize: "14px", color: "#666" }}>
            © 2025 HappyWedz Technologies Pvt. Ltd. All rights reserved.
          </p>
        </div>
      </div>
    </div>
  );
}
