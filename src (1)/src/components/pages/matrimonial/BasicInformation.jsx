import React, { useState } from "react";

const BasicInformation = ({
  formData,
  updateFormData,
  onNext,
  onPrev,
  isFirstStep,
}) => {
  const [passwordStrength, setPasswordStrength] = useState({
    strength: 0,
    text: "Weak",
    class: "strength-weak",
  });

  const checkPasswordStrength = (password) => {
    let strength = 0;
    if (password.length >= 8) strength++;
    if (/[a-z]/.test(password)) strength++;
    if (/[A-Z]/.test(password)) strength++;
    if (/[0-9]/.test(password)) strength++;
    if (/[^A-Za-z0-9]/.test(password)) strength++;

    const strengthLevels = {
      0: { strength: 0, text: "Weak", class: "strength-weak" },
      1: { strength: 20, text: "Weak", class: "strength-weak" },
      2: { strength: 40, text: "Fair", class: "strength-medium" },
      3: { strength: 60, text: "Good", class: "strength-medium" },
      4: { strength: 80, text: "Strong", class: "strength-strong" },
      5: { strength: 100, text: "Very Strong", class: "strength-strong" },
    };

    setPasswordStrength(strengthLevels[strength]);
  };

  const handleInputChange = (field, value) => {
    if (field === "phone") {
      const numericValue = value.replace(/[^0-9]/g, "").slice(0, 10);
      updateFormData(field, numericValue);
    } else {
      updateFormData(field, value);
    }

    if (field === "password") {
      checkPasswordStrength(value);
    }
  };

  const validateStep = () => {
    const required = [
      "profileFor",
      "firstName",
      "lastName",
      "email",
      "phone",
      "password",
    ];
    return required.every(
      (field) => formData[field] && formData[field].toString().trim()
    );
  };

  return (
    <div className="Matrimonial">
      <div className="form-step-content">
        <div className="info-box">
          <h4>📱 100% Phone verified profiles</h4>
          <p>
            To have a secure user experience & genuine members, phone
            verification is mandatory for all.
          </p>
        </div>

        <div className="form-group">
          <label>
            Profile Created For <span className="required">*</span>
          </label>
          <div className="radio-group">
            {["self", "son", "daughter", "brother", "sister", "friend"].map(
              (option) => (
                <div
                  key={option}
                  className={`radio-item ${
                    formData.profileFor === option ? "selected" : ""
                  }`}
                >
                  <input
                    type="radio"
                    name="profileFor"
                    value={option}
                    id={option}
                    checked={formData.profileFor === option}
                    onChange={(e) =>
                      handleInputChange("profileFor", e.target.value)
                    }
                  />
                  <label htmlFor={option}>
                    {option.charAt(0).toUpperCase() + option.slice(1)}
                  </label>
                </div>
              )
            )}
          </div>
        </div>

        <div className="grid-2">
          <div className="form-group">
            <label htmlFor="firstName">
              First Name <span className="required">*</span>
            </label>
            <input
              type="text"
              id="firstName"
              className="form-control"
              value={formData.firstName || ""}
              onChange={(e) => handleInputChange("firstName", e.target.value)}
              required
            />
          </div>
          <div className="form-group">
            <label htmlFor="lastName">
              Last Name <span className="required">*</span>
            </label>
            <input
              type="text"
              id="lastName"
              className="form-control"
              value={formData.lastName || ""}
              onChange={(e) => handleInputChange("lastName", e.target.value)}
              required
            />
          </div>
        </div>

        <div className="form-group">
          <label htmlFor="email">
            Email Address <span className="required">*</span>
          </label>
          <input
            type="email"
            id="email"
            className="form-control"
            value={formData.email || ""}
            onChange={(e) => handleInputChange("email", e.target.value)}
            required
          />
        </div>

        <div className="form-group">
          <label htmlFor="phone">
            Mobile Number <span className="required">*</span>
          </label>
          <div className="phone-input">
            <div className="country-code">+91</div>
            <input
              type="tel"
              id="phone"
              className="form-control"
              placeholder="Enter 10-digit mobile number"
              value={formData.phone || ""}
              onChange={(e) => handleInputChange("phone", e.target.value)}
              maxLength="10"
              required
            />
          </div>
          <div className="privacy-settings">
            <h4>Contact Privacy Settings</h4>
            <div className="radio-group">
              {[
                { value: "all", label: "Show to all" },
                { value: "none", label: "Hide from all" },
                { value: "interested", label: "Show to interested members" },
              ].map((option) => (
                <div
                  key={option.value}
                  className={`radio-item ${
                    formData.phonePrivacy === option.value ? "selected" : ""
                  }`}
                >
                  <input
                    type="radio"
                    name="phonePrivacy"
                    value={option.value}
                    id={`show${option.value}`}
                    checked={formData.phonePrivacy === option.value}
                    onChange={(e) =>
                      handleInputChange("phonePrivacy", e.target.value)
                    }
                  />
                  <label htmlFor={`show${option.value}`}>{option.label}</label>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="form-group">
          <label htmlFor="password">
            Password <span className="required">*</span>
          </label>
          <input
            type="password"
            id="password"
            className="form-control"
            placeholder="Use 8 or more characters with a mix of letters & numbers"
            value={formData.password || ""}
            onChange={(e) => handleInputChange("password", e.target.value)}
            required
          />
          <div className="password-strength">
            <div className="strength-bar">
              <div
                className={`strength-fill ${passwordStrength.class}`}
                style={{ width: `${passwordStrength.strength}%` }}
              ></div>
            </div>
            <small>Password strength: {passwordStrength.text}</small>
          </div>
        </div>

        <div className="btn-group">
          <button
            type="button"
            className="btn btn-secondary"
            disabled={isFirstStep}
            onClick={onPrev}
          >
            Previous
          </button>
          <button
            type="button"
            className="btn btn-primary"
            onClick={onNext}
            disabled={!validateStep()}
          >
            Continue
          </button>
        </div>
      </div>
    </div>
  );
};

export default BasicInformation;
