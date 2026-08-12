import React, { useState, useEffect } from "react";
import {
  FiUser,
  FiPhone,
  FiMail,
  FiLock,
  FiSearch,
  FiHeart,
  FiChevronDown,
  FiChevronRight,
} from "react-icons/fi";
import "../../../Matrimonial.css";
import { Link } from "react-router-dom";
import { FiEye, FiEyeOff } from "react-icons/fi";

const MatrimonialHome = () => {
  const [isLoginOpen, setIsLoginOpen] = useState(false);
  const [activeDropdown, setActiveDropdown] = useState(null);
  const [activeSubmenu, setActiveSubmenu] = useState(null);
  const [showPassword, setShowPassword] = useState(false);

  const toggleLogin = () => {
    setIsLoginOpen(!isLoginOpen);
  };

  const handleDropdownHover = (menu) => {
    setActiveDropdown(menu);
    setActiveSubmenu(null);
  };
  const handleSubmenuHover = (submenu) => {
    setActiveSubmenu(submenu);
  };
  const closeMenus = () => {
    setActiveDropdown(null);
    setActiveSubmenu(null);
  };

  const successStories = [
    { id: 1, name: "Raj & Priya", date: "Mar 2023", img: "couple1" },
    { id: 2, name: "Amit & Neha", date: "Jan 2023", img: "couple2" },
    { id: 3, name: "Vikram & Anjali", date: "Dec 2022", img: "couple3" },
    { id: 4, name: "Sanjay & Meera", date: "Oct 2022", img: "couple4" },
    { id: 5, name: "Rahul & Shreya", date: "Aug 2022", img: "couple5" },
    { id: 6, name: "Arjun & Pooja", date: "Jun 2022", img: "couple6" },
  ];

  // Membership plans
  const plans = [
    {
      id: 1,
      name: "Free",
      price: "₹0",
      duration: "Forever",
      features: ["Basic profile", "Limited searches", "10 interest requests"],
    },
    {
      id: 2,
      name: "Gold",
      price: "₹3,999",
      duration: "3 Months",
      features: [
        "Unlimited searches",
        "Unlimited interests",
        "Priority listing",
        "Profile highlight",
      ],
    },
    {
      id: 3,
      name: "Platinum",
      price: "₹6,999",
      duration: "6 Months",
      features: [
        "All Gold features",
        "Verified badge",
        "Profile boost",
        "Matchmaking assistance",
        "Privacy control",
      ],
    },
  ];

  // Auto-scroll for success stories
  useEffect(() => {
    const scrollContainer = document.querySelector(
      ".success-stories-container"
    );
    let scrollAmount = 0;

    const autoScroll = setInterval(() => {
      if (scrollContainer) {
        scrollAmount += 1;
        if (scrollAmount >= scrollContainer.scrollWidth / 2) {
          scrollAmount = 0;
        }
        scrollContainer.scrollTo({
          left: scrollAmount,
          behavior: "smooth",
        });
      }
    }, 50);

    return () => clearInterval(autoScroll);
  }, []);

  return (
    <div className="matrimonial">
      <div className="matrimonial-container">
        {/* Navigation Bar */}
        <nav className="navbar">
          <div className="container">
            <div className="logo"></div>

            <div className="nav-menu">
              <div
                className="nav-item"
                onMouseEnter={() => handleDropdownHover("matches")}
              >
                <span>
                  <div classname="dropdown"></div>
                </span>
                <span>
                  Matches <FiChevronDown />
                </span>
                {activeDropdown === "matches" && (
                  <div className="dropdown">
                    <div className="dropdown-content">
                      <div className="submenu-column">
                        <h4>By Preference</h4>
                        <Link to="/ProfileMatrimonial">New Matches</Link>
                        <a href="/">Premium Matches</a>
                        <a href="/">Matches Near You</a>
                      </div>
                      <div className="submenu-column">
                        <h4>By Community</h4>
                        <a href="/">Hindu Matches</a>
                        <a href="/">Muslim Matches</a>
                        <a href="/">Christian Matches</a>
                        <a href="/">Sikh Matches</a>
                      </div>
                      <div className="submenu-column">
                        <h4>By Profession</h4>
                        <a href="/">Doctor Matches</a>
                        <a href="/">Engineer Matches</a>
                        <a href="/">CA/CS Matches</a>
                        <a href="/">Govt. Employee</a>
                      </div>
                    </div>
                  </div>
                )}
              </div>
              <div
                className="nav-item"
                onMouseEnter={() => handleDropdownHover("community")}
              >
                <span>
                  Community <FiChevronDown />
                </span>
                {activeDropdown === "community" && (
                  <div className="dropdown">
                    <div className="dropdown-content">
                      <div
                        className="submenu-column"
                        onMouseEnter={() => handleSubmenuHover("religion")}
                      >
                        <h4>Religion</h4>
                        <a href="/">
                          Hindu <FiChevronRight />
                        </a>
                        <a href="/">
                          Muslim <FiChevronRight />
                        </a>
                        <a href="/">
                          Christian <FiChevronRight />
                        </a>
                        <a href="/">
                          Sikh <FiChevronRight />
                        </a>

                        {activeSubmenu === "religion" && (
                          <div className="submenu-panel">
                            <div className="submenu-content">
                              <h5>Hindu</h5>
                              <a href="/">Brahmin</a>
                              <a href="/">Rajput</a>
                              <a href="/">Maratha</a>
                              <a href="/">Baniya</a>
                              <a href="/">Kayastha</a>
                              <a href="/">All Castes</a>
                            </div>
                            <div className="submenu-content">
                              <h5>Muslim</h5>
                              <a href="/">Sunni</a>
                              <a href="/">Shia</a>
                              <a href="/">Pathan</a>
                              <a href="/">Mughal</a>
                              <a href="/">All Sects</a>
                            </div>
                            <div className="submenu-content">
                              <h5>Christian</h5>
                              <a href="/">Catholic</a>
                              <a href="/">Protestant</a>
                              <a href="/">Orthodox</a>
                              <a href="/">All Denominations</a>
                            </div>
                            <div className="submenu-content">
                              <h5>Sikh</h5>
                              <a href="/">Jat</a>
                              <a href="/">Khatri</a>
                              <a href="/">Arora</a>
                              <a href="/">Ramgarhia</a>
                              <a href="/">All Castes</a>
                            </div>
                          </div>
                        )}
                      </div>

                      <div className="submenu-column">
                        <h4>Regional</h4>
                        <a href="/">North Indian</a>
                        <a href="/">South Indian</a>
                        <a href="/">Bengali</a>
                        <a href="/">Marathi</a>
                      </div>

                      <div className="submenu-column">
                        <h4>NRI</h4>
                        <a href="/">USA Matches</a>
                        <a href="/">UK Matches</a>
                        <a href="/">Canada Matches</a>
                        <a href="/">Australia Matches</a>
                      </div>
                    </div>
                  </div>
                )}
              </div>

              <div className="nav-item">
                <a href="/">Horoscope</a>
              </div>
              <div className="nav-item">
                <a href="/">Blog</a>
              </div>
              <div className="nav-item">
                <a href="/">Success Stories</a>
              </div>
            </div>

            <div className="nav-actions">
              {/* <div className="search-box">
              <FiSearch className="search-icon" />
              <input type="text" placeholder="Search profiles..." />
            </div> */}
              <button
                className="login-btn"
                onClick={(e) => {
                  e.stopPropagation();
                  toggleLogin();
                }}
              >
                Login / Register
              </button>
            </div>
          </div>
        </nav>
        {isLoginOpen && (
          <div className="login-modal">
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2>Login to Your Account</h2>
                <button className="close-btn" onClick={toggleLogin}>
                  ×
                </button>
              </div>
              <div className="modal-body">
                <div className="form-group">
                  <FiUser className="input-icon" />
                  <input type="text" placeholder="Email or Mobile" />
                </div>
                <div className="form-group password-group">
                  <FiLock className="input-icon" />
                  <input
                    type={showPassword ? "text" : "password"}
                    placeholder="Password"
                  />
                  <span
                    className="toggle-password"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? <FiEyeOff /> : <FiEye />}
                  </span>
                </div>
                <div className="remember-forgot">
                  <label>
                    <input type="checkbox" /> Remember me
                  </label>
                  <a href="/">Forgot Password?</a>
                </div>
                <button className="login-button">Login</button>
                <div className="divider">or</div>
                <button className="signup-button">Create New Account</button>
              </div>
              <div className="modal-footer">
                <p>
                  By logging in, you agree to our{" "}
                  <a href="/">Terms & Conditions</a> and{" "}
                  <a href="/">Privacy Policy</a>
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Hero Section */}
        <div className="hero-section">
          <div className="container">
            <div className="hero-content">
              <div className="hero-text">
                <h1>Find Your Perfect Life Partner</h1>
                <p>
                  Trusted by millions of families to discover meaningful
                  connections
                </p>
                <div className="stats">
                  <div className="stat-item">
                    <h3>10M+</h3>
                    <p>Registered Users</p>
                  </div>
                  <div className="stat-item">
                    <h3>500K+</h3>
                    <p>Success Stories</p>
                  </div>
                  <div className="stat-item">
                    <h3>20+</h3>
                    <p>Years of Experience</p>
                  </div>
                </div>
              </div>

              <div className="registration-form">
                <h2>Register for Free</h2>
                <form>
                  <div className="form-group">
                    <label>I am looking for</label>
                    <div className="radio-group">
                      <label>
                        <input type="radio" name="gender" defaultChecked />{" "}
                        Bride
                      </label>
                      <label>
                        <input type="radio" name="gender" /> Groom
                      </label>
                    </div>
                  </div>

                  <div className="form-row">
                    <div className="form-group">
                      <label>Name</label>
                      <input type="text" placeholder="Your Full Name" />
                    </div>
                    <div className="form-group">
                      <label>Phone</label>
                      <input type="tel" placeholder="Mobile Number" />
                    </div>
                  </div>

                  <div className="form-group">
                    <label>Email</label>
                    <input type="email" placeholder="Email Address" />
                  </div>

                  <div className="form-row">
                    <div className="form-group">
                      <label>Religion</label>
                      <select>
                        <option>Hindu</option>
                        <option>Muslim</option>
                        <option>Christian</option>
                        <option>Sikh</option>
                        <option>Other</option>
                      </select>
                    </div>
                    <div className="form-group">
                      <label>Community</label>
                      <select>
                        <option>Brahmin</option>
                        <option>Rajput</option>
                        <option>Maratha</option>
                        <option>Baniya</option>
                        <option>Other</option>
                      </select>
                    </div>
                  </div>

                  <div className="form-group">
                    <label>Password</label>
                    <input type="password" placeholder="Create Password" />
                  </div>

                  <button type="submit" className="register-btn">
                    Register Now
                  </button>

                  <p className="terms">
                    By registering, you agree to our <a href="/">Terms</a> and{" "}
                    <a href="/">Privacy Policy</a>
                  </p>
                </form>
              </div>
            </div>
          </div>
        </div>

        {/* Membership Plans */}
        <div className="membership-section">
          <div className="container">
            <h2>Choose Your Membership Plan</h2>
            <p className="subtitle">
              Find the perfect plan to meet your matchmaking needs
            </p>

            <div className="plans-container">
              {plans.map((plan) => (
                <div
                  key={plan.id}
                  className={`plan-card ${
                    plan.name === "Gold" ? "recommended" : ""
                  }`}
                >
                  {plan.name === "Gold" && (
                    <div className="recommended-badge">Most Popular</div>
                  )}
                  <h3>{plan.name} Plan</h3>
                  <div className="price">
                    {plan.price} <span>/{plan.duration}</span>
                  </div>
                  <ul className="features">
                    {plan.features.map((feature, index) => (
                      <li key={index}>
                        <FiChevronRight className="feature-icon" size={20} />{" "}
                        {feature}
                      </li>
                    ))}
                  </ul>
                  <button className="select-plan-btn">Select Plan</button>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Success Stories */}
        <div className="success-section">
          <div className="container">
            <h2>Successful Matches</h2>
            <p className="subtitle">
              Join thousands of happy couples who found their life partners
            </p>

            <div className="success-stories-container">
              {successStories.map((story) => (
                <div key={story.id} className="success-card">
                  <div className={`couple-img ${story.img}`}></div>
                  <h4>{story.name}</h4>
                  <p>Married: {story.date}</p>
                </div>
              ))}
              {successStories.map((story) => (
                <div key={`${story.id}-clone`} className="success-card">
                  <div className={`couple-img ${story.img}`}></div>
                  <h4>{story.name}</h4>
                  <p>Married: {story.date}</p>
                </div>
              ))}
            </div>

            <div className="view-all-stories">
              <button className="view-stories-btn">
                View All Success Stories
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MatrimonialHome;
