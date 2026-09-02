// src/components/pages/matrimonial/home/MatrimonialHome.jsx
import { FcGoogle } from "react-icons/fc";
import React, { useState, useEffect } from "react";
import { FiUser, FiLock, FiChevronDown, FiChevronRight } from "react-icons/fi";
import { Link, useNavigate } from "react-router-dom";
import "../../../Matrimonial.css";
import { FiEye, FiEyeOff } from "react-icons/fi";
import { RiMenuFill } from "react-icons/ri";

const Navbar = () => {
  const [isLoginOpen, setIsLoginOpen] = useState(false);
  const [activeDropdown, setActiveDropdown] = useState(null);
  const [activeSubmenu, setActiveSubmenu] = useState(null);
  const [showPassword, setShowPassword] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const navigate = useNavigate();

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
        <nav className="navbar">
          <div className="container px-2">
            <button
              className="d-lg-none navbar-toggler"
              type="button"
              onClick={() => setMenuOpen(!menuOpen)}
              aria-label="Toggle navigation"
            >
              <RiMenuFill color="white" size={35} />
            </button>
            {/* <div className="logo"></div> */}

            <div className={`nav-menu ${menuOpen ? "active" : ""}`}>
              <div className="nav-item">
                <Link className="navbar-brand-logo" to="/">
                  <img
                    src="logo-no-bg.png"
                    alt="HappyWedz"
                    height="30"
                    className="mx-auto d-block"
                  />
                </Link>
              </div>
              <div className="nav-item">
                <Link to="/matrimonial">Home</Link>
              </div>

              <div
                className="nav-item"
                onMouseEnter={() => handleDropdownHover("matches")}
              >
                <span>
                  Matches <FiChevronDown />
                </span>
                {activeDropdown === "matches" && (
                  <div className="dropdown">
                    <div className="dropdown-content">
                      <div className="submenu-column">
                        <h4>By Preference</h4>
                        <Link to="/ProfileMatrimonial/Brahmin">
                          New Matches
                        </Link>
                        <Link to="/ProfileMatrimonial/premium">
                          Premium Matches
                        </Link>
                        <Link to="/ProfileMatrimonial/near-me">
                          Matches Near You
                        </Link>
                      </div>
                      <div className="submenu-column">
                        <Link to="/ProfileMatrimonial/Hindu">
                          Hindu Matches
                        </Link>
                        <Link to="/ProfileMatrimonial/Muslim">
                          Muslim Matches
                        </Link>
                        <Link to="/ProfileMatrimonial/Christian">
                          Christian Matches
                        </Link>
                        <Link to="/ProfileMatrimonial/Sikh">Sikh Matches</Link>
                      </div>
                      <div className="submenu-column">
                        <h4>By Profession</h4>
                        <Link to="/ProfileMatrimonial/Doctor">
                          Doctor Matches
                        </Link>
                        <Link to="/ProfileMatrimonial/Engineer">
                          Engineer Matches
                        </Link>
                        <Link to="/ProfileMatrimonial/Engineer">
                          CA/CS Matches
                        </Link>
                        <Link to="/ProfileMatrimonial/Gov">Govt. Employee</Link>
                      </div>
                    </div>
                  </div>
                )}
              </div>

              <div className="nav-item">
                <Link to="/matrimonial-search">Search</Link>
              </div>
              <div className="nav-item">
                <Link to="/matrimonial-dashboard">Dashboard</Link>
              </div>
              <div className="nav-item">
                <Link to="/edit-profile">Edit-profile</Link>
              </div>
            </div>

            <div className="nav-actions">
              <button
                className="login-btn"
                onClick={(e) => {
                  e.stopPropagation();
                  toggleLogin();
                }}
              >
                Login
              </button>
              <button
                className="login-btn "
                onClick={(e) => {
                  e.stopPropagation();
                  navigate("/matrimonial-register");
                }}
              >
                Register
              </button>
            </div>
          </div>
        </nav>

        {/* Login Modal */}
        {isLoginOpen && (
          <div className="login-modal" onClick={toggleLogin}>
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
                  <Link to="/user-forgot-password">Forgot Password?</Link>
                </div>
                <button
                  className="login-button"
                  onClick={() => {
                    toggleLogin();
                  }}
                >
                  Login
                </button>

                {/* Added divider and Google sign-in */}
                <div className="or-divider">or</div>
                <button
                  className="google-login-btn"
                  onClick={() => {
                    /* Add Google login logic */
                  }}
                >
                  <FcGoogle size={18} style={{ marginRight: "10px" }} />
                  Sign in with Google
                </button>
              </div>
              <div className="modal-footer">
                <p className="create-account-link">
                  Don't have an account?{" "}
                  <Link to="/matrimonial-register" onClick={toggleLogin}>
                    Create new account
                  </Link>
                </p>
                <p>
                  By logging in, you agree to our{" "}
                  <a href="/">Terms & Conditions</a> and{" "}
                  <a href="/">Privacy Policy</a>
                </p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Navbar;
