import React from "react";
import "../../../Matrimonial.css";
const Footer = () => {
  return (
    <div className="matrimonial-container">
      <footer className="footer">
        <div className="container">
          <div className="footer-content">
            <div className="footer-col">
              <h3>ShaadiSathi</h3>
              <p>
                India's most trusted matrimony service since 2000. Helping
                millions find their perfect life partners.
              </p>
              <div className="social-icons">
                <a href="/" className="social-icon fb">
                  f
                </a>
                <a href="/" className="social-icon tw">
                  t
                </a>
                <a href="/" className="social-icon in">
                  in
                </a>
                <a href="/" className="social-icon ig">
                  ig
                </a>
              </div>
            </div>

            <div className="footer-col">
              <h4>Quick Links</h4>
              <ul>
                <li>
                  <a href="/">Home</a>
                </li>
                <li>
                  <a href="/">Search</a>
                </li>
                <li>
                  <a href="/">Matches</a>
                </li>
                <li>
                  <a href="/">Membership</a>
                </li>
                <li>
                  <a href="/">Success Stories</a>
                </li>
              </ul>
            </div>

            <div className="footer-col">
              <h4>Help & Support</h4>
              <ul>
                <li>
                  <a href="/">Contact Us</a>
                </li>
                <li>
                  <a href="/">FAQs</a>
                </li>
                <li>
                  <a href="/">Safety Tips</a>
                </li>
                <li>
                  <a href="/">Feedback</a>
                </li>
                <li>
                  <a href="/">Customer Care</a>
                </li>
              </ul>
            </div>

            <div className="footer-col">
              <h4>Legal</h4>
              <ul>
                <li>
                  <a href="/">Terms of Use</a>
                </li>
                <li>
                  <a href="/">Privacy Policy</a>
                </li>
                <li>
                  <a href="/">Grievance Redressal</a>
                </li>
                <li>
                  <a href="/">Report Misuse</a>
                </li>
              </ul>
            </div>
          </div>

          <div className="footer-bottom">
            <p>© 2023 ShaadiSathi.com - All Rights Reserved</p>
            <div className="footer-links">
              <a href="/">About Us</a>
              <a href="/">Careers</a>
              <a href="/">Media</a>
              <a href="/">Sitemap</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Footer;
