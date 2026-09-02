import React, { useState } from "react";
// import "./Search.css";

const Search = () => {
  const [searchType, setSearchType] = useState("category");
  const [showProfileTooltip, setShowProfileTooltip] = useState(false);
  const [showCategoryTooltip, setShowCategoryTooltip] = useState(false);
  const [profileId, setProfileId] = useState("");

  // Form state for category search
  const [formData, setFormData] = useState({
    basic: {
      minAge: "25",
      maxAge: "35",
      maritalStatus: "Any",
      religion: "Any",
      caste: "Any",
      motherTongue: "Any",
      country: "India",
      state: "Any",
      city: "Any",
    },
    education: {
      education: "Any",
      educationField: "Any",
      profession: "Any",
      income: "Any",
    },
    lifestyle: {
      diet: "Any",
      smoke: "Any",
      drink: "Any",
      bodyType: "Any",
    },
  });

  // Sample data for dropdowns
  const religions = ["Any", "Hindu", "Muslim", "Christian", "Sikh", "Jain"];
  const countries = ["India", "USA", "UK", "Canada", "Australia"];
  const states = ["Any", "Maharashtra", "Delhi", "Karnataka", "Tamil Nadu"];
  const cities = ["Any", "Mumbai", "Delhi", "Bangalore", "Chennai"];
  const maritalStatuses = [
    "Any",
    "Never Married",
    "Divorced",
    "Widowed",
    "Separated",
  ];
  const motherTongues = [
    "Any",
    "Hindi",
    "English",
    "Marathi",
    "Tamil",
    "Telugu",
    "hdhgjhs",
    "dfeff",
  ];
  const professions = [
    "Any",
    "Engineer",
    "Doctor",
    "Teacher",
    "Business",
    "Government Job",
  ];
  const incomes = [
    "Any",
    "No Income",
    "Below 1 Lakh",
    "1-2 Lakhs",
    "2-5 Lakhs",
    "5+ Lakhs",
  ];

  const handleInputChange = (section, field, value) => {
    setFormData((prev) => ({
      ...prev,
      [section]: {
        ...prev[section],
        [field]: value,
      },
    }));
  };

  const handleReset = () => {
    setProfileId("");
    setFormData({
      basic: {
        minAge: "25",
        maxAge: "35",
        maritalStatus: "Any",
        religion: "Any",
        caste: "Any",
        motherTongue: "Any",
        country: "India",
        state: "Any",
        city: "Any",
      },
      education: {
        education: "Any",
        educationField: "Any",
        profession: "Any",
        income: "Any",
      },
      lifestyle: {
        diet: "Any",
        smoke: "Any",
        drink: "Any",
        bodyType: "Any",
      },
    });
  };

  return (
    <div className="matrimonial">
      <div className="container my-5 shadow-lg rounded-3">
        <div className="search-header">
          <h2>Advanced Search</h2>
          <div className="search-toggle">
            <button
              className={`toggle-btn ${
                searchType === "profileId" ? "active" : ""
              }`}
              onClick={() => setSearchType("profileId")}
              onMouseEnter={() => setShowProfileTooltip(true)}
              onMouseLeave={() => setShowProfileTooltip(false)}
            >
              Search by Profile ID
              {showProfileTooltip && (
                <span className="tooltip">
                  Enter a specific profile ID to find someone directly
                </span>
              )}
            </button>
            <button
              className={`toggle-btn ${
                searchType === "category" ? "active" : ""
              }`}
              onClick={() => setSearchType("category")}
              onMouseEnter={() => setShowCategoryTooltip(true)}
              onMouseLeave={() => setShowCategoryTooltip(false)}
            >
              Search by Category
              {showCategoryTooltip && (
                <span className="tooltip">
                  Use filters to find matches based on your preferences
                </span>
              )}
            </button>
          </div>
        </div>

        <div className="search-form">
          {searchType === "profileId" ? (
            <div className="row align-items-center">
              <div className="col-12 col-md-9 mb-2 mb-md-0">
                <input
                  type="text"
                  placeholder="Enter Profile ID"
                  className="profile-input form-control"
                  value={profileId}
                  onChange={(e) => setProfileId(e.target.value)}
                />
              </div>
              <div className="col-12 col-md-3">
                <button
                  className="search-btn btn btn-primary w-100 mt-2 mt-md-0"
                  style={{ whiteSpace: "nowrap" }}
                >
                  Find Profile
                </button>
              </div>
            </div>
          ) : (
            <div className="category-search">
              <div className="form-section">
                <h3 className="section-title">Basic Information</h3>
                <div className="form-row">
                  <div className="form-group">
                    <label>Age</label>
                    <div className="age-range">
                      <select
                        value={formData.basic.minAge}
                        onChange={(e) =>
                          handleInputChange("basic", "minAge", e.target.value)
                        }
                      >
                        <option value="">Min</option>
                        {Array.from({ length: 48 }, (_, i) => i + 18).map(
                          (age) => (
                            <option key={age} value={age}>
                              {age}
                            </option>
                          )
                        )}
                      </select>
                      <span>to</span>
                      <select
                        value={formData.basic.maxAge}
                        onChange={(e) =>
                          handleInputChange("basic", "maxAge", e.target.value)
                        }
                      >
                        <option value="">Max</option>
                        {Array.from({ length: 33 }, (_, i) => i + 25).map(
                          (age) => (
                            <option key={age} value={age}>
                              {age}
                            </option>
                          )
                        )}
                      </select>
                    </div>
                  </div>

                  <div className="form-group">
                    <label>Marital Status</label>
                    <select
                      value={formData.basic.maritalStatus}
                      onChange={(e) =>
                        handleInputChange(
                          "basic",
                          "maritalStatus",
                          e.target.value
                        )
                      }
                    >
                      {maritalStatuses.map((status) => (
                        <option key={status} value={status}>
                          {status}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Religion</label>
                    <select
                      value={formData.basic.religion}
                      onChange={(e) =>
                        handleInputChange("basic", "religion", e.target.value)
                      }
                    >
                      {religions.map((religion) => (
                        <option key={religion} value={religion}>
                          {religion}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Caste</label>
                    <select
                      value={formData.basic.caste}
                      onChange={(e) =>
                        handleInputChange("basic", "caste", e.target.value)
                      }
                    >
                      <option value="Any">Any</option>
                      <option value="Brahmin">Brahmin</option>
                      <option value="Rajput">Rajput</option>
                      <option value="Maratha">Maratha</option>
                      <option value="Baniya">Baniya</option>
                    </select>
                  </div>
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Mother Tongue</label>
                    <select
                      value={formData.basic.motherTongue}
                      onChange={(e) =>
                        handleInputChange(
                          "basic",
                          "motherTongue",
                          e.target.value
                        )
                      }
                    >
                      {motherTongues.map((tongue) => (
                        <option key={tongue} value={tongue}>
                          {tongue}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Country</label>
                    <select
                      value={formData.basic.country}
                      onChange={(e) =>
                        handleInputChange("basic", "country", e.target.value)
                      }
                    >
                      {countries.map((country) => (
                        <option key={country} value={country}>
                          {country}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label>State</label>
                    <select
                      value={formData.basic.state}
                      onChange={(e) =>
                        handleInputChange("basic", "state", e.target.value)
                      }
                    >
                      {states.map((state) => (
                        <option key={state} value={state}>
                          {state}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label>City</label>
                    <select
                      value={formData.basic.city}
                      onChange={(e) =>
                        handleInputChange("basic", "city", e.target.value)
                      }
                    >
                      {cities.map((city) => (
                        <option key={city} value={city}>
                          {city}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              </div>

              <div className="form-section">
                <h3 className="section-title">Education & Career</h3>
                <div className="form-row">
                  <div className="form-group">
                    <label>Education</label>
                    <select
                      value={formData.education.education}
                      onChange={(e) =>
                        handleInputChange(
                          "education",
                          "education",
                          e.target.value
                        )
                      }
                    >
                      <option value="Any">Any</option>
                      <option value="B.Tech">B.Tech</option>
                      <option value="MBA">MBA</option>
                      <option value="B.Sc">B.Sc</option>
                      <option value="M.Sc">M.Sc</option>
                      <option value="Ph.D">Ph.D</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Education Field</label>
                    <select
                      value={formData.education.educationField}
                      onChange={(e) =>
                        handleInputChange(
                          "education",
                          "educationField",
                          e.target.value
                        )
                      }
                    >
                      <option value="Any">Any</option>
                      <option value="Engineering">Engineering</option>
                      <option value="Medicine">Medicine</option>
                      <option value="Arts">Arts</option>
                      <option value="Commerce">Commerce</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Profession</label>
                    <select
                      value={formData.education.profession}
                      onChange={(e) =>
                        handleInputChange(
                          "education",
                          "profession",
                          e.target.value
                        )
                      }
                    >
                      {professions.map((profession) => (
                        <option key={profession} value={profession}>
                          {profession}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Income</label>
                    <select
                      value={formData.education.income}
                      onChange={(e) =>
                        handleInputChange("education", "income", e.target.value)
                      }
                    >
                      {incomes.map((income) => (
                        <option key={income} value={income}>
                          {income}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              </div>

              <div className="form-section">
                <h3 className="section-title">Lifestyle</h3>
                <div className="form-row">
                  <div className="form-group">
                    <label>Diet</label>
                    <select
                      value={formData.lifestyle.diet}
                      onChange={(e) =>
                        handleInputChange("lifestyle", "diet", e.target.value)
                      }
                    >
                      <option value="Any">Any</option>
                      <option value="Vegetarian">Vegetarian</option>
                      <option value="Non-Vegetarian">Non-Vegetarian</option>
                      <option value="Eggetarian">Eggetarian</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Smoke</label>
                    <select
                      value={formData.lifestyle.smoke}
                      onChange={(e) =>
                        handleInputChange("lifestyle", "smoke", e.target.value)
                      }
                    >
                      <option value="Any">Any</option>
                      <option value="No">No</option>
                      <option value="Occasionally">Occasionally</option>
                      <option value="Yes">Yes</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Drink</label>
                    <select
                      value={formData.lifestyle.drink}
                      onChange={(e) =>
                        handleInputChange("lifestyle", "drink", e.target.value)
                      }
                    >
                      <option value="Any">Any</option>
                      <option value="No">No</option>
                      <option value="Occasionally">Occasionally</option>
                      <option value="Yes">Yes</option>
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Body Type</label>
                    <select
                      value={formData.lifestyle.bodyType}
                      onChange={(e) =>
                        handleInputChange(
                          "lifestyle",
                          "bodyType",
                          e.target.value
                        )
                      }
                    >
                      <option value="Any">Any</option>
                      <option value="Slim">Slim</option>
                      <option value="Average">Average</option>
                      <option value="Athletic">Athletic</option>
                      <option value="Heavy">Heavy</option>
                    </select>
                  </div>
                </div>
              </div>

              <div className="form-actions">
                <button className="reset-btn" onClick={handleReset}>
                  Reset
                </button>
                <button className="search-btn">Search</button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Search;
