import React, { useState, useEffect } from "react";
import {
  FiFilter,
  FiHeart,
  FiMapPin,
  FiBookmark,
  FiShare2,
  FiEye,
  FiChevronDown,
  FiChevronRight,
  FiChevronUp,
  FiX,
  FiSearch,
} from "react-icons/fi";
import "../../../Matrimonial.css";
import { useParams } from "react-router-dom";

const FilterSection = ({ title, children, defaultOpen = true }) => {
  const [isOpen, setIsOpen] = useState(defaultOpen);

  return (
    <div className="filter-section">
      <div className="filter-header" onClick={() => setIsOpen(!isOpen)}>
        <h4>{title}</h4>
        {isOpen ? <FiChevronUp size={18} /> : <FiChevronDown size={18} />}
      </div>
      {isOpen && <div className="filter-content">{children}</div>}
    </div>
  );
};

const ProfileMatrimonial = () => {
  const { matchType } = useParams();
  const [activeTab, setActiveTab] = useState("grooms");
  const [sortBy, setSortBy] = useState("recent");
  const [showMoreFilters, setShowMoreFilters] = useState(false);

  // Filter states
  const [selectedCities, setSelectedCities] = useState(["All Cities"]);
  const [ageRange, setAgeRange] = useState({ min: 25, max: 35 });
  const [heightRange, setHeightRange] = useState({
    min: "5'4\"",
    max: "6'0\"",
  });
  const [maritalStatus, setMaritalStatus] = useState(["Never Married"]);
  const [education, setEducation] = useState("");
  const [profession, setProfession] = useState("");
  const [income, setIncome] = useState("");
  const [diet, setDiet] = useState(["Vegetarian"]);
  const [motherTongue, setMotherTongue] = useState("");
  const [community, setCommunity] = useState("");

  const cities = [
    "All Cities",
    "Mumbai",
    "Delhi",
    "Bangalore",
    "Chennai",
    "Hyderabad",
    "Pune",
    "Kolkata",
    "Ahmedabad",
    "Surat",
    "Jaipur",
    "Lucknow",
  ];

  const subCommunities = [
    "Iyer",
    "Iyengar",
    "Namboothiri",
    "Saraswat",
    "Kanyakubj",
    "Kulin",
    "Niyogi",
    "Havyaka",
    "Kota",
    "Kashmiri Pandit",
  ];

  const profiles = {
    grooms: [
      {
        id: 1,
        name: "Rajesh Sharma",
        age: 32,
        height: "5'10\"",
        education: "MBA, IIM Ahmedabad",
        profession: "Senior Manager at Deloitte",
        location: "Mumbai, India",
        income: "₹25-30 LPA",
        family: "Brahmin, Iyer, Vegetarian",
        image:
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8NHx8cG9ydHJhaXR8ZW58MHx8MHx8&auto=format&fit=crop&w=500&q=60",
      },
      {
        id: 2,
        name: "Vikram Iyer",
        age: 29,
        height: "5'9\"",
        education: "MS in Computer Science",
        profession: "Software Engineer at Google",
        location: "Bangalore, India",
        income: "₹35-40 LPA",
        family: "Brahmin, Iyer, Vegetarian",
        image:
          "https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8OHx8cG9ydHJhaXR8ZW58MHx8MHx8&auto=format&fit=crop&w=500&q=60",
      },
      {
        id: 3,
        name: "Arun Kumar",
        age: 34,
        height: "5'11\"",
        education: "CA, CFA",
        profession: "Finance Director at HDFC",
        location: "Delhi, India",
        income: "₹45-50 LPA",
        family: "Brahmin, Iyengar, Vegetarian",
        image:
          "https://images.unsplash.com/photo-1560250097-0b93528c311a?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8NXx8cG9ydHJhaXR8ZW58MHx8MHx8&auto=format&fit=crop&w=500&q=60",
      },
      {
        id: 4,
        name: "Suresh Menon",
        age: 31,
        height: "5'8\"",
        education: "B.Tech, IIT Bombay",
        profession: "Product Manager at Amazon",
        location: "Hyderabad, India",
        income: "₹30-35 LPA",
        family: "Brahmin, Namboothiri, Vegetarian",
        image:
          "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8MTB8fHBvcnRyYWl0fGVufDB8fDB8fA%3D%3D&auto=format&fit=crop&w=500&q=60",
      },
    ],
    brides: [
      {
        id: 1,
        name: "Priya Sharma",
        age: 26,
        height: "5'4\"",
        education: "M.Sc Biotechnology",
        profession: "Research Scientist",
        location: "Chennai, India",
        income: "₹8-10 LPA",
        family: "Brahmin, Iyer, Vegetarian",
        image:
          "https://images.unsplash.com/photo-1554151228-14d9def656e4?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8MTd8fHBvcnRyYWl0fGVufDB8fDB8fA%3D%3D&auto=format&fit=crop&w=500&q=60",
      },
      {
        id: 2,
        name: "Ananya Iyer",
        age: 28,
        height: "5'5\"",
        education: "MBA, Symbiosis",
        profession: "Marketing Manager",
        location: "Pune, India",
        income: "₹12-15 LPA",
        family: "Brahmin, Iyengar, Vegetarian",
        image:
          "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8MTR8fHBvcnRyYWl0fGVufDB8fDB8fA%3D%3D&auto=format&fit=crop&w=500&q=60",
      },
      {
        id: 3,
        name: "Divya Kumar",
        age: 25,
        height: "5'3\"",
        education: "B.Com, CA Inter",
        profession: "Chartered Accountant",
        location: "Kolkata, India",
        income: "₹15-18 LPA",
        family: "Brahmin, Niyogi, Vegetarian",
        image:
          "https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8MjB8fHBvcnRyYWl0fGVufDB8fDB8fA%3D%3D&auto=format&fit=crop&w=500&q=60",
      },
      {
        id: 4,
        name: "Shruti Nair",
        age: 27,
        height: "5'6\"",
        education: "M.Tech Computer Science",
        profession: "Data Scientist",
        location: "Bangalore, India",
        income: "₹18-20 LPA",
        family: "Brahmin, Saraswat, Vegetarian",
        image:
          "https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8OHx8cG9ydHJhaXR8ZW58MHx8MHx8&auto=format&fit=crop&w=500&q=60",
      },
      {
        id: 5,
        name: "Shruti Nair",
        age: 27,
        height: "5'6\"",
        education: "M.Tech Computer Science",
        profession: "Data Scientist",
        location: "Bangalore, India",
        income: "₹18-20 LPA",
        family: "Brahmin, Saraswat, Vegetarian",
        image:
          "https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8OHx8cG9ydHJhaXR8ZW58MHx8MHx8&auto=format&fit=crop&w=500&q=60",
      },
      {
        id: 6,
        name: "Shruti Nair",
        age: 27,
        height: "5'6\"",
        education: "M.Tech Computer Science",
        profession: "Data Scientist",
        location: "Bangalore, India",
        income: "₹18-20 LPA",
        family: "Brahmin, Saraswat, Vegetarian",
        image:
          "https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8OHx8cG9ydHJhaXR8ZW58MHx8MHx8&auto=format&fit=crop&w=500&q=60",
      },
    ],
  };

  const handleCityToggle = (city) => {
    if (city === "All Cities") {
      setSelectedCities(["All Cities"]);
    } else {
      if (selectedCities.includes(city)) {
        setSelectedCities(selectedCities.filter((c) => c !== city));
      } else {
        setSelectedCities(
          selectedCities.filter((c) => c !== "All Cities").concat(city)
        );
      }
    }
  };

  const resetAllFilters = () => {
    setSelectedCities(["All Cities"]);
    setAgeRange({ min: 25, max: 35 });
    setHeightRange({ min: "5'4\"", max: "6'0\"" });
    setMaritalStatus(["Never Married"]);
    setEducation("");
    setProfession("");
    setIncome("");
    setDiet(["Vegetarian"]);
    setMotherTongue("");
    setCommunity("");
  };

  return (
    <>
      <div className="matrimonial">
        <div className="brahmin-matrimonial-page">
          {/* Page Header - Keep existing */}
          <div className="brahmin-page-header">
            <div className="container">
              <h1>{matchType} Matrimony</h1>
              <p>
                Find your perfect Brahmin life partner from thousands of
                verified profiles
              </p>
              <div className="brahmin-stats">
                <div className="stat-item">
                  <strong>10,000+</strong>
                  <span>Active Profiles</span>
                </div>
                <div className="stat-item">
                  <strong>5,000+</strong>
                  <span>Success Stories</span>
                </div>
                <div className="stat-item">
                  <strong>20+</strong>
                  <span>Years Experience</span>
                </div>
              </div>
            </div>
          </div>

          <div className="container brahmin-main-content">
            <div className="brahmin-content-wrapper">
              {/* Profiles Column - Keep existing */}
              <div className="brahmin-profiles-column">
                <div className="brahmin-profile-tabs">
                  <button
                    className={`brahmin-tab-btn ${
                      activeTab === "grooms" ? "active" : ""
                    }`}
                    onClick={() => setActiveTab("grooms")}
                  >
                    Grooms
                  </button>
                  <button
                    className={`brahmin-tab-btn ${
                      activeTab === "brides" ? "active" : ""
                    }`}
                    onClick={() => setActiveTab("brides")}
                  >
                    Brides
                  </button>
                </div>

                <div className="row">
                  <div className="profiles-col info-card col-md-9 h-100">
                    <div className="col-md-12">
                      <div className="community-list">
                        <div className="brahmin-profiles-grid">
                          {profiles[activeTab].map((profile) => (
                            <div
                              key={profile.id}
                              className="brahmin-profile-card"
                            >
                              <div className="brahmin-profile-badge">
                                Premium
                              </div>
                              <div className="brahmin-profile-image">
                                <img
                                  src={profile.image}
                                  alt={profile.name}
                                  className="brahmin-profile-img"
                                />
                                <div className="brahmin-profile-actions">
                                  <button className="brahmin-action-btn">
                                    <FiHeart />
                                  </button>
                                  <button className="brahmin-action-btn">
                                    <FiBookmark />
                                  </button>
                                  <button className="brahmin-action-btn">
                                    <FiShare2 />
                                  </button>
                                </div>
                              </div>
                              <div className="brahmin-profile-info">
                                <h3>{profile.name}</h3>
                                <div className="brahmin-profile-details">
                                  <p>
                                    {profile.age} yrs, {profile.height}
                                  </p>
                                  <p>{profile.education}</p>
                                  <p>{profile.profession}</p>
                                  <p>
                                    <FiMapPin className="brahmin-icon" />{" "}
                                    {profile.location}
                                  </p>
                                  <p>Annual Income: {profile.income}</p>
                                  <p>Family: {profile.family}</p>
                                </div>
                                <div className="brahmin-profile-cta">
                                  <button className="brahmin-view-btn">
                                    <FiEye className="brahmin-icon" />
                                  </button>
                                  <button className="brahmin-express-btn">
                                    <FiHeart className="brahmin-icon" />
                                  </button>
                                </div>
                              </div>
                            </div>
                          ))}
                        </div>

                        <div className="brahmin-pagination">
                          <button className="brahmin-page-btn active">1</button>
                          <button className="brahmin-page-btn">2</button>
                          <button className="brahmin-page-btn">3</button>
                          <button className="brahmin-page-btn">4</button>
                          <button className="brahmin-page-btn next">
                            Next →
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div className="filters-col col-md-3">
                    {/* Filters Column - Updated with new design */}
                    <div className="brahmin-filters-column">
                      <div className="filter-panel">
                        <div className="filter-panel-header">
                          <h3>Refine Search</h3>
                          <button
                            className="reset-all"
                            onClick={resetAllFilters}
                          >
                            <FiX size={16} /> Reset All
                          </button>
                        </div>

                        <FilterSection title="City">
                          <div className="search-box">
                            <FiSearch className="search-icon" />
                            <input type="text" placeholder="Search city..." />
                          </div>
                          <div className="filter-options">
                            {cities.map((city) => (
                              <label key={city} className="filter-option">
                                <input
                                  type="checkbox"
                                  checked={selectedCities.includes(city)}
                                  onChange={() => handleCityToggle(city)}
                                />
                                <span className="checkmark"></span>
                                <span className="option-label">{city}</span>
                              </label>
                            ))}
                          </div>
                        </FilterSection>

                        <FilterSection title="Age">
                          <div className="range-filter">
                            <div className="range-values">
                              <span>{ageRange.min} yrs</span>
                              <span>to</span>
                              <span>{ageRange.max} yrs</span>
                            </div>
                            <div className="range-slider">
                              <input
                                type="range"
                                min="16"
                                max="60"
                                value={ageRange.min}
                                onChange={(e) =>
                                  setAgeRange({
                                    ...ageRange,
                                    min: e.target.value,
                                  })
                                }
                              />
                              <input
                                type="range"
                                min="16"
                                max="60"
                                value={ageRange.max}
                                onChange={(e) =>
                                  setAgeRange({
                                    ...ageRange,
                                    max: e.target.value,
                                  })
                                }
                              />
                            </div>
                          </div>
                        </FilterSection>

                        <FilterSection title="Height">
                          <div className="height-filter">
                            <select
                              value={heightRange.min}
                              onChange={(e) =>
                                setHeightRange({
                                  ...heightRange,
                                  min: e.target.value,
                                })
                              }
                            >
                              {[
                                "3'2\"",
                                "3'6\"",
                                "3'8\"",
                                "4'0\"",
                                "4'2\"",
                                "4'8\"",
                                "5'0\"",
                                "5'2\"",
                                "5'4\"",
                                "5'6\"",
                                "5'8\"",
                                "5'10\"",
                              ].map((h) => (
                                <option key={h} value={h}>
                                  {h}
                                </option>
                              ))}
                            </select>
                            <span>to</span>
                            <select
                              value={heightRange.max}
                              onChange={(e) =>
                                setHeightRange({
                                  ...heightRange,
                                  max: e.target.value,
                                })
                              }
                            >
                              {[
                                "5'4\"",
                                "5'6\"",
                                "5'8\"",
                                "5'10\"",
                                "6'0\"",
                                "6'2\"",
                                "6'4\"",
                                "6'6\"",
                                "6'8\"",
                                "7'2\"",
                                "7'4\"",
                                "7'6\"",
                              ].map((h) => (
                                <option key={h} value={h}>
                                  {h}
                                </option>
                              ))}
                            </select>
                          </div>
                        </FilterSection>

                        <FilterSection title="Marital Status">
                          <div className="filter-options">
                            {[
                              "Never Married",
                              "Divorced",
                              "Widowed",
                              "Separated",
                            ].map((status) => (
                              <label key={status} className="filter-option">
                                <input
                                  type="checkbox"
                                  checked={maritalStatus.includes(status)}
                                  onChange={() => {
                                    if (maritalStatus.includes(status)) {
                                      setMaritalStatus(
                                        maritalStatus.filter(
                                          (s) => s !== status
                                        )
                                      );
                                    } else {
                                      setMaritalStatus([
                                        ...maritalStatus,
                                        status,
                                      ]);
                                    }
                                  }}
                                />
                                <span className="checkmark"></span>
                                <span className="option-label">{status}</span>
                              </label>
                            ))}
                          </div>
                        </FilterSection>

                        <FilterSection title="Education">
                          <select
                            value={education}
                            onChange={(e) => setEducation(e.target.value)}
                            className="filter-select"
                          >
                            <option value="">Any Education</option>
                            <option value="B.Tech">B.Tech/B.E.</option>
                            <option value="MBA">MBA/PGDM</option>
                            <option value="M.Tech">M.Tech</option>
                            <option value="CA">CA</option>
                            <option value="Medical">Medical</option>
                            <option value="Ph.D">Ph.D</option>
                          </select>
                        </FilterSection>

                        <FilterSection title="Profession">
                          <select
                            value={profession}
                            onChange={(e) => setProfession(e.target.value)}
                            className="filter-select"
                          >
                            <option value="">Any Profession</option>
                            <option value="Software">
                              Software Professional
                            </option>
                            <option value="Doctor">Doctor</option>
                            <option value="Civil">Civil Services</option>
                            <option value="Business">Business</option>
                            <option value="Teacher">Teacher</option>
                          </select>
                        </FilterSection>

                        <FilterSection title="Annual Income">
                          <select
                            value={income}
                            onChange={(e) => setIncome(e.target.value)}
                            className="filter-select"
                          >
                            <option value="">Any Income</option>
                            <option value="0-5">Below ₹5 Lakhs</option>
                            <option value="5-10">₹5-10 Lakhs</option>
                            <option value="10-20">₹10-20 Lakhs</option>
                            <option value="20+">₹20+ Lakhs</option>
                          </select>
                        </FilterSection>

                        <FilterSection title="Diet">
                          <div className="filter-options">
                            {[
                              "Vegetarian",
                              "Non-Vegetarian",
                              "Eggetarian",
                              "Jain",
                            ].map((d) => (
                              <label key={d} className="filter-option">
                                <input
                                  type="checkbox"
                                  checked={diet.includes(d)}
                                  onChange={() => {
                                    if (diet.includes(d)) {
                                      setDiet(
                                        diet.filter((item) => item !== d)
                                      );
                                    } else {
                                      setDiet([...diet, d]);
                                    }
                                  }}
                                />
                                <span className="checkmark"></span>
                                <span className="option-label">{d}</span>
                              </label>
                            ))}
                          </div>
                        </FilterSection>

                        <FilterSection title="Mother Tongue">
                          <select
                            value={motherTongue}
                            onChange={(e) => setMotherTongue(e.target.value)}
                            className="filter-select"
                          >
                            <option value="">Any Language</option>
                            <option value="Hindi">Hindi</option>
                            <option value="Marathi">Marathi</option>
                            <option value="Tamil">Tamil</option>
                            <option value="Telugu">Telugu</option>
                            <option value="Bengali">Bengali</option>
                          </select>
                        </FilterSection>

                        <FilterSection title="Community">
                          <select
                            value={community}
                            onChange={(e) => setCommunity(e.target.value)}
                            className="filter-select"
                          >
                            <option value="">Any Community</option>
                            {subCommunities.map((comm) => (
                              <option key={comm} value={comm}>
                                {comm}
                              </option>
                            ))}
                          </select>
                        </FilterSection>

                        <button className="apply-filters-btn">
                          Apply Filters
                        </button>
                      </div>

                      <div className="info-card">
                        <h3>Brahmin Matrimony</h3>
                        <p>
                          Find your perfect Brahmin life partner from thousands
                          of verified profiles. Our platform specializes in
                          connecting Brahmin brides and grooms who value
                          tradition, education, and compatibility.
                        </p>
                        <div className="community-list">
                          <h4>Popular Sub-Communities</h4>
                          <ul>
                            {subCommunities.map((community) => (
                              <li key={community}>
                                <a href="#">{community}</a>
                              </li>
                            ))}
                          </ul>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default ProfileMatrimonial;
