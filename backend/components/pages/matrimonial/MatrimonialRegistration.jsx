import React, { useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import {
  FaUser,
  FaBirthdayCake,
  FaLanguage,
  FaVenusMars,
  FaPhone,
  FaCheck,
  FaHeart,
  FaUsers,
  FaCheckCircle,
  FaLock,
  FaShieldAlt,
  FaQuestionCircle,
  FaBriefcase,
  FaHome,
} from "react-icons/fa";

const MatrimonialRegistration = () => {
  const [step, setStep] = useState(1);
  const [errors, setErrors] = useState({});
  const [formData, setFormData] = useState({
    profileFor: "",
    profileType: "",
    name: "",
    showName: true,
    dob: "",
    motherTongue: "",
    religion: "",
    caste: "",
    casteNoBar: false,
    manglik: "non-manglik",
    phone: "",
    phoneVerified: false,
    familyType: "",
    brothers: 0,
    marriedBrothers: 0,
    unmarriedBrothers: 0,
    sisters: 0,
    marriedSisters: 0,
    unmarriedSisters: 0,
    fatherOccupation: "",
    motherOccupation: "",
    aboutYourself: "",
    hobbies: "",
    partnerExpectations: "",
  });

  const validateStep = (step) => {
    const newErrors = {};

    if (step === 1) {
      if (!formData.profileFor.trim())
        newErrors.profileFor = "Profile for is required";
      if (!formData.profileType.trim())
        newErrors.profileType = "Profile type is required";
      if (!formData.name.trim()) newErrors.name = "Name is required";
      if (!formData.dob) newErrors.dob = "Date of birth is required";
    }

    if (step === 4 && !formData.phoneVerified) {
      if (!formData.phone) newErrors.phone = "Phone number is required";
      else if (!/^\d{10}$/.test(formData.phone))
        newErrors.phone = "Phone number must be exactly 10 digits";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));

    // Update married/unmarried counts when total siblings change
    if (name === "brothers") {
      const brothersCount = parseInt(value) || 0;
      setFormData((prev) => ({
        ...prev,
        brothers: brothersCount,
        marriedBrothers: Math.min(prev.marriedBrothers, brothersCount),
        unmarriedBrothers: Math.min(prev.unmarriedBrothers, brothersCount),
      }));
    } else if (name === "sisters") {
      const sistersCount = parseInt(value) || 0;
      setFormData((prev) => ({
        ...prev,
        sisters: sistersCount,
        marriedSisters: Math.min(prev.marriedSisters, sistersCount),
        unmarriedSisters: Math.min(prev.unmarriedSisters, sistersCount),
      }));
    }

    // Clear error when field is changed
    if (errors[name]) {
      setErrors((prev) => {
        const newErrors = { ...prev };
        delete newErrors[name];
        return newErrors;
      });
    }
  };

  const nextStep = () => {
    if (validateStep(step)) {
      setStep(step + 1);
      window.scrollTo(0, 0);
    }
  };

  const prevStep = () => {
    setStep(step - 1);
    window.scrollTo(0, 0);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (validateStep(step)) {
      Swal.fire({
        icon: "success",
        text: "Registration successfull",
        timer: "3000",
        confirmeButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
    }
  };

  const verifyPhone = () => {
    if (!formData.phone) {
      setErrors({ phone: "Phone number is required" });
      return;
    }
    if (!/^\d{10}$/.test(formData.phone)) {
      setErrors({ phone: "Phone number must be exactly 10 digits" });
      return;
    }

    // In a real app, you would send OTP here
    setFormData((prev) => ({ ...prev, phoneVerified: true }));
  };

  const getNameLabel = () => {
    if (formData.profileType === "bride") return "Bride's Name";
    if (formData.profileType === "groom") return "Groom's Name";
    return "Name";
  };

  return (
    <div className="matrimonial">
      <div className="matrimonial-registration">
        <div className="container py-4 py-md-5">
          <div className="card shadow-sm">
            <div className="card-header bg-white">
              <ul className="nav nav-tabs card-header-tabs flex-nowrap overflow-auto">
                <li className="nav-item flex-shrink-0">
                  <button
                    className={`nav-link ${step === 1 ? "active" : ""}`}
                    onClick={() => setStep(1)}
                  >
                    Profile Details
                  </button>
                </li>
                <li className="nav-item flex-shrink-0">
                  <button
                    className={`nav-link ${step === 2 ? "active" : ""}`}
                    onClick={() => setStep(2)}
                    disabled={step < 2}
                  >
                    Family Details
                  </button>
                </li>
                <li className="nav-item flex-shrink-0">
                  <button
                    className={`nav-link ${step === 3 ? "active" : ""}`}
                    onClick={() => setStep(3)}
                    disabled={step < 3}
                  >
                    About Yourself
                  </button>
                </li>
                <li className="nav-item flex-shrink-0">
                  <button
                    className={`nav-link ${step === 4 ? "active" : ""}`}
                    onClick={() => setStep(4)}
                    disabled={step < 4}
                  >
                    Phone Verification
                  </button>
                </li>
              </ul>
            </div>

            <div className="card-body p-3 p-md-4">
              <h4 className="mb-4" style={{ color: "#d63384" }}>
                Hi! You are joining the Best Matchmaking Experience.
              </h4>

              {step === 1 && (
                <div className="profile-details">
                  <div className="row">
                    <div className="col-md-6 mb-3">
                      <label className="form-label">
                        <FaUser className="me-2" />
                        Creating Profile For *
                      </label>
                      <select
                        className={`form-select ${
                          errors.profileFor ? "is-invalid" : ""
                        }`}
                        name="profileFor"
                        value={formData.profileFor}
                        onChange={handleChange}
                        required
                      >
                        <option value="">Select</option>
                        <option value="self">Self</option>
                        <option value="son">Son</option>
                        <option value="daughter">Daughter</option>
                        <option value="brother">Brother</option>
                        <option value="sister">Sister</option>
                      </select>
                      {errors.profileFor && (
                        <div className="invalid-feedback">
                          {errors.profileFor}
                        </div>
                      )}
                    </div>

                    <div className="col-md-6 mb-3">
                      <label className="form-label">
                        <FaVenusMars className="me-2" />
                        Profile Type *
                      </label>
                      <select
                        className={`form-select ${
                          errors.profileType ? "is-invalid" : ""
                        }`}
                        name="profileType"
                        value={formData.profileType}
                        onChange={handleChange}
                        required
                      >
                        <option value="">Select</option>
                        <option value="bride">Bride</option>
                        <option value="groom">Groom</option>
                      </select>
                      {errors.profileType && (
                        <div className="invalid-feedback">
                          {errors.profileType}
                        </div>
                      )}
                    </div>
                  </div>
                  <div className="mb-3">
                    <label
                      style={{
                        display: "block",
                        marginBottom: "5px",
                        fontWeight: "500",
                        color: "#333",
                      }}
                    >
                      <FaUser style={{ marginRight: "8px" }} />
                      {getNameLabel()}{" "}
                      <span style={{ color: "#ed1173" }}>*</span>
                    </label>
                    <div
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: "10px",
                        marginBottom: "5px",
                      }}
                    >
                      <input
                        type="text"
                        style={{
                          flex: 1,
                          padding: "10px",
                          border: `1px solid ${
                            errors.name ? "#f44336" : "#ddd"
                          }`,
                          borderRadius: "4px",
                          fontSize: "14px",
                        }}
                        name="name"
                        value={formData.name}
                        onChange={handleChange}
                        required
                      />
                      <div
                        style={{
                          display: "flex",
                          alignItems: "center",
                          gap: "5px",
                          padding: "0 10px",
                        }}
                      >
                        <input
                          type="checkbox"
                          id="showNameToggle"
                          name="showName"
                          checked={formData.showName}
                          onChange={handleChange}
                          style={{
                            width: "16px",
                            height: "16px",
                            margin: 0,
                          }}
                        />
                        <label
                          htmlFor="showNameToggle"
                          style={{
                            fontSize: "14px",
                            margin: 0,
                            cursor: "pointer",
                          }}
                        >
                          Show to All
                        </label>
                      </div>
                    </div>
                    {errors.name && (
                      <div
                        style={{
                          color: "#f44336",
                          fontSize: "12px",
                          marginTop: "5px",
                        }}
                      >
                        {errors.name}
                      </div>
                    )}
                    <p
                      style={{
                        fontSize: "12px",
                        color: "#666",
                        margin: "5px 0 0",
                        fontStyle: "italic",
                      }}
                    >
                      If you wish to hide your name from others, click on
                      settings icon and choose the setting
                    </p>
                  </div>
                  <div className="row">
                    <div className="col-md-6 mb-3">
                      <label className="form-label">
                        <FaBirthdayCake className="me-2" />
                        Date of Birth *
                      </label>
                      <input
                        type="date"
                        className={`form-control ${
                          errors.dob ? "is-invalid" : ""
                        }`}
                        name="dob"
                        value={formData.dob}
                        onChange={handleChange}
                        required
                      />
                      {errors.dob && (
                        <div className="invalid-feedback">{errors.dob}</div>
                      )}
                    </div>

                    <div className="col-md-6 mb-3">
                      <label className="form-label">
                        <FaLanguage className="me-2" />
                        Mother tongue
                      </label>
                      <select
                        className="form-select"
                        name="motherTongue"
                        value={formData.motherTongue}
                        onChange={handleChange}
                      >
                        <option value="">Select</option>
                        <option value="hindi">Hindi</option>
                        <option value="english">English</option>
                        <option value="bengali">Bengali</option>
                        <option value="tamil">Tamil</option>
                        <option value="telugu">Telugu</option>
                        <option value="marathi">Marathi</option>
                      </select>
                    </div>
                  </div>

                  <div className="row">
                    <div className="col-md-6 mb-3">
                      <label className="form-label">
                        <FaVenusMars className="me-2" />
                        Religion
                      </label>
                      <select
                        className="form-select"
                        name="religion"
                        value={formData.religion}
                        onChange={handleChange}
                      >
                        <option value="">Select</option>
                        <option value="hindu">Hindu</option>
                        <option value="muslim">Muslim</option>
                        <option value="christian">Christian</option>
                        <option value="sikh">Sikh</option>
                        <option value="jain">Jain</option>
                      </select>
                    </div>

                    <div className="col-md-6 mb-3">
                      <label className="form-label">
                        <FaUsers className="me-2" />
                        Caste
                      </label>
                      <select
                        className="form-select"
                        name="caste"
                        value={formData.caste}
                        onChange={handleChange}
                        disabled={!formData.religion}
                      >
                        <option value="">Select</option>
                        {formData.religion === "hindu" && (
                          <>
                            <option value="brahmin">Brahmin</option>
                            <option value="maratha">Maratha</option>
                            <option value="rajput">Rajput</option>
                          </>
                        )}
                        {formData.religion === "muslim" && (
                          <>
                            <option value="sunni">Sunni</option>
                            <option value="shia">Shia</option>
                          </>
                        )}
                      </select>
                    </div>
                  </div>

                  <div className="mb-3 form-check">
                    <input
                      type="checkbox"
                      className="form-check-input"
                      name="casteNoBar"
                      checked={formData.casteNoBar}
                      onChange={handleChange}
                    />
                    <label className="form-check-label">
                      Caste no bar (I am open to marry people of all castes)
                    </label>
                  </div>

                  <div className="mb-4">
                    <label className="form-label">
                      <i className="fas fa-star me-2"></i>
                      Are you manglik?
                    </label>
                    <div>
                      <div className="form-check form-check-inline">
                        <input
                          className="form-check-input"
                          type="radio"
                          name="manglik"
                          value="manglik"
                          checked={formData.manglik === "manglik"}
                          onChange={handleChange}
                        />
                        <label className="form-check-label">Manglik</label>
                      </div>
                      <div className="form-check form-check-inline">
                        <input
                          className="form-check-input"
                          type="radio"
                          name="manglik"
                          value="non-manglik"
                          checked={formData.manglik === "non-manglik"}
                          onChange={handleChange}
                        />
                        <label className="form-check-label">Non-manglik</label>
                      </div>
                      <div className="form-check form-check-inline">
                        <input
                          className="form-check-input"
                          type="radio"
                          name="manglik"
                          value="dont-know"
                          checked={formData.manglik === "dont-know"}
                          onChange={handleChange}
                        />
                        <label className="form-check-label">Don't know</label>
                      </div>
                    </div>
                  </div>

                  <div className="d-flex justify-content-between">
                    <button className="btn btn-light" disabled>
                      Back
                    </button>
                    <button className="btn btn-primary" onClick={nextStep}>
                      Next
                    </button>
                  </div>
                </div>
              )}

              {step === 2 && (
                <div className="family-details">
                  <div className="mb-4">
                    <label className="form-label">
                      <FaHome className="me-2" />
                      Family Type
                    </label>
                    <select
                      className="form-select"
                      name="familyType"
                      value={formData.familyType}
                      onChange={handleChange}
                    >
                      <option value="">Select</option>
                      <option value="joint">Joint Family</option>
                      <option value="nuclear">Nuclear Family</option>
                      <option value="separate">Separate Family</option>
                    </select>
                  </div>

                  <h5 className="mb-3">Brothers</h5>
                  <div className="row mb-4">
                    <div className="col-md-4">
                      <label className="form-label">How many brothers?</label>
                      <div className="btn-group w-100">
                        {[0, 1, 2, 3].map((num) => (
                          <button
                            key={`brothers-${num}`}
                            type="button"
                            className={`btn ${
                              formData.brothers === num
                                ? "btn-primary"
                                : "btn-outline-primary"
                            }`}
                            onClick={() =>
                              setFormData((prev) => ({
                                ...prev,
                                brothers: num,
                              }))
                            }
                          >
                            {num === 3 ? "3+" : num}
                          </button>
                        ))}
                      </div>
                    </div>
                    {formData.brothers > 0 && (
                      <>
                        <div className="col-md-4">
                          <label className="form-label">
                            How many married?
                          </label>
                          <div className="btn-group w-100">
                            {[0, 1, 2, 3].map((num) => (
                              <button
                                key={`married-brothers-${num}`}
                                type="button"
                                className={`btn ${
                                  formData.marriedBrothers === num
                                    ? "btn-primary"
                                    : "btn-outline-primary"
                                }`}
                                onClick={() =>
                                  setFormData((prev) => ({
                                    ...prev,
                                    marriedBrothers: num,
                                  }))
                                }
                                disabled={num > formData.brothers}
                              >
                                {num === 3 ? "3+" : num}
                              </button>
                            ))}
                          </div>
                        </div>
                        <div className="col-md-4">
                          <label className="form-label">
                            How many unmarried?
                          </label>
                          <div className="btn-group w-100">
                            {[0, 1, 2, 3].map((num) => (
                              <button
                                key={`unmarried-brothers-${num}`}
                                type="button"
                                className={`btn ${
                                  formData.unmarriedBrothers === num
                                    ? "btn-primary"
                                    : "btn-outline-primary"
                                }`}
                                onClick={() =>
                                  setFormData((prev) => ({
                                    ...prev,
                                    unmarriedBrothers: num,
                                  }))
                                }
                                disabled={num > formData.brothers}
                              >
                                {num === 3 ? "3+" : num}
                              </button>
                            ))}
                          </div>
                        </div>
                      </>
                    )}
                  </div>

                  <h5 className="mb-3">Sisters</h5>
                  <div className="row mb-4">
                    <div className="col-md-4">
                      <label className="form-label">How many sisters?</label>
                      <div className="btn-group w-100">
                        {[0, 1, 2, 3].map((num) => (
                          <button
                            key={`sisters-${num}`}
                            type="button"
                            className={`btn ${
                              formData.sisters === num
                                ? "btn-primary"
                                : "btn-outline-primary"
                            }`}
                            onClick={() =>
                              setFormData((prev) => ({ ...prev, sisters: num }))
                            }
                          >
                            {num === 3 ? "3+" : num}
                          </button>
                        ))}
                      </div>
                    </div>
                    {formData.sisters > 0 && (
                      <>
                        <div className="col-md-4">
                          <label className="form-label">
                            How many married?
                          </label>
                          <div className="btn-group w-100">
                            {[0, 1, 2, 3].map((num) => (
                              <button
                                key={`married-sisters-${num}`}
                                type="button"
                                className={`btn ${
                                  formData.marriedSisters === num
                                    ? "btn-primary"
                                    : "btn-outline-primary"
                                }`}
                                onClick={() =>
                                  setFormData((prev) => ({
                                    ...prev,
                                    marriedSisters: num,
                                  }))
                                }
                                disabled={num > formData.sisters}
                              >
                                {num === 3 ? "3+" : num}
                              </button>
                            ))}
                          </div>
                        </div>
                        <div className="col-md-4">
                          <label className="form-label">
                            How many unmarried?
                          </label>
                          <div className="btn-group w-100">
                            {[0, 1, 2, 3].map((num) => (
                              <button
                                key={`unmarried-sisters-${num}`}
                                type="button"
                                className={`btn ${
                                  formData.unmarriedSisters === num
                                    ? "btn-primary"
                                    : "btn-outline-primary"
                                }`}
                                onClick={() =>
                                  setFormData((prev) => ({
                                    ...prev,
                                    unmarriedSisters: num,
                                  }))
                                }
                                disabled={num > formData.sisters}
                              >
                                {num === 3 ? "3+" : num}
                              </button>
                            ))}
                          </div>
                        </div>
                      </>
                    )}
                  </div>

                  <div className="row mb-4">
                    <div className="col-md-6">
                      <label className="form-label">
                        <FaBriefcase className="me-2" />
                        Father's Occupation
                      </label>
                      <input
                        type="text"
                        className="form-control"
                        name="fatherOccupation"
                        value={formData.fatherOccupation}
                        onChange={handleChange}
                        placeholder="Enter father's occupation"
                      />
                    </div>
                    <div className="col-md-6">
                      <label className="form-label">
                        <FaBriefcase className="me-2" />
                        Mother's Occupation
                      </label>
                      <input
                        type="text"
                        className="form-control"
                        name="motherOccupation"
                        value={formData.motherOccupation}
                        onChange={handleChange}
                        placeholder="Enter mother's occupation"
                      />
                    </div>
                  </div>

                  <div className="d-flex justify-content-between">
                    <button className="btn btn-light" onClick={prevStep}>
                      Back
                    </button>
                    <button className="btn btn-primary" onClick={nextStep}>
                      Next
                    </button>
                  </div>
                </div>
              )}

              {step === 3 && (
                <div className="about-yourself">
                  <div className="mb-4">
                    <h5>Here is your chance to make your profile stand out!</h5>
                    <p className="text-muted">
                      Write about yourself, your family, your expectations from
                      partner, etc.
                    </p>
                    <textarea
                      className="form-control mb-3"
                      rows="6"
                      name="aboutYourself"
                      value={formData.aboutYourself}
                      onChange={handleChange}
                      placeholder="Tell about yourself, your family background, education, career, hobbies, and what you're looking for in a partner..."
                    ></textarea>
                    <div className="form-text">
                      <a href="#">
                        <FaQuestionCircle className="me-1" /> Need help writing?
                      </a>
                    </div>
                  </div>

                  <div className="row mb-4">
                    <div className="col-md-6">
                      <label className="form-label">
                        <FaHeart className="me-2" />
                        Hobbies & Interests
                      </label>
                      <textarea
                        className="form-control"
                        rows="4"
                        name="hobbies"
                        value={formData.hobbies}
                        onChange={handleChange}
                        placeholder="Reading, traveling, cooking, sports, music, etc."
                      ></textarea>
                    </div>
                    <div className="col-md-6">
                      <label className="form-label">
                        <FaUsers className="me-2" />
                        Partner Expectations
                      </label>
                      <textarea
                        className="form-control"
                        rows="4"
                        name="partnerExpectations"
                        value={formData.partnerExpectations}
                        onChange={handleChange}
                        placeholder="What are you looking for in your ideal partner?"
                      ></textarea>
                    </div>
                  </div>

                  <div className="d-flex justify-content-between">
                    <button className="btn btn-light" onClick={prevStep}>
                      Back
                    </button>
                    <button className="btn btn-primary" onClick={nextStep}>
                      Next
                    </button>
                  </div>
                </div>
              )}

              {step === 4 && (
                <div className="phone-verification text-center">
                  {!formData.phoneVerified ? (
                    <>
                      <h4 className="mb-4">Phone Verification</h4>
                      <div className="mb-4">
                        <FaPhone
                          className="text-primary mb-3"
                          style={{ fontSize: "3rem" }}
                        />
                        <p>We'll send an OTP to verify your mobile number</p>
                      </div>
                      <div
                        className="mb-4 mx-auto"
                        style={{ maxWidth: "400px" }}
                      >
                        <label className="form-label">Mobile Number *</label>
                        <div className="input-group">
                          <span className="input-group-text">+91</span>
                          <input
                            type="tel"
                            className={`form-control ${
                              errors.phone ? "is-invalid" : ""
                            }`}
                            name="phone"
                            value={formData.phone}
                            onChange={(e) => {
                              // Only allow digits and limit to 10 characters
                              const value = e.target.value
                                .replace(/\D/g, "")
                                .slice(0, 10);
                              setFormData((prev) => ({
                                ...prev,
                                phone: value,
                              }));
                            }}
                            maxLength="10"
                            pattern="\d{10}"
                            placeholder="Enter 10 digit mobile number"
                            required
                          />
                          {errors.phone && (
                            <div className="invalid-feedback">
                              {errors.phone}
                            </div>
                          )}
                        </div>
                      </div>
                      <button className="btn btn-primary" onClick={verifyPhone}>
                        Send OTP
                      </button>
                    </>
                  ) : (
                    <>
                      <div className="mb-4">
                        <div
                          className="bg-success text-white rounded-circle d-inline-flex align-items-center justify-content-center"
                          style={{ width: "80px", height: "80px" }}
                        >
                          <FaCheck style={{ fontSize: "2rem" }} />
                        </div>
                        <h4 className="my-3">Congratulations!</h4>
                        <p>
                          Your number +91 {formData.phone} is verified
                          successfully.
                        </p>
                      </div>
                      <button
                        className="btn btn-primary"
                        onClick={handleSubmit}
                      >
                        Complete Registration
                      </button>
                    </>
                  )}
                </div>
              )}

              {step < 4 && (
                <div className="mt-5 pt-4 border-top">
                  <h5 className="text-center mb-3">WHY REGISTER</h5>
                  <div className="row text-center">
                    <div className="col-6 col-md-3 mb-3">
                      <div className="p-3 bg-light rounded h-100">
                        <FaUsers className="text-primary mb-2 fs-4" />
                        <h6 className="mb-0">Lakhs of Genuine Profiles</h6>
                      </div>
                    </div>
                    <div className="col-6 col-md-3 mb-3">
                      <div className="p-3 bg-light rounded h-100">
                        <FaCheckCircle className="text-primary mb-2 fs-4" />
                        <h6 className="mb-0">
                          Many Verified by Personal Visit
                        </h6>
                      </div>
                    </div>
                    <div className="col-6 col-md-3 mb-3">
                      <div className="p-3 bg-light rounded h-100">
                        <FaLock className="text-primary mb-2 fs-4" />
                        <h6 className="mb-0">Secure & Family Friendly</h6>
                      </div>
                    </div>
                    <div className="col-6 col-md-3 mb-3">
                      <div className="p-3 bg-light rounded h-100">
                        <FaShieldAlt className="text-primary mb-2 fs-4" />
                        <h6 className="mb-0">Strict Privacy Control</h6>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MatrimonialRegistration;
