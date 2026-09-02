import React, { useState } from "react";
import {
  User,
  Calendar,
  MapPin,
  Briefcase,
  GraduationCap,
  Heart,
  Phone,
  Mail,
  Camera,
  Edit3,
  Save,
  X,
  Check,
} from "lucide-react";

const BasicInformation = () => {
  const [isEditing, setIsEditing] = useState(false);
  const [profileData, setProfileData] = useState({
    personalInfo: {
      firstName: "Priya",
      lastName: "Sharma",
      dateOfBirth: "1997-06-15",
      age: 26,
      gender: "Female",
      maritalStatus: "Never Married",
      religion: "Hindu",
      caste: "Sharma",
      motherTongue: "Hindi",
      physicalStatus: "Normal",
      height: "5'4\"",
      weight: "55 kg",
      bodyType: "Slim",
      complexion: "Fair",
    },
    contactInfo: {
      email: "priya.sharma@email.com",
      phone: "+91 98765 43210",
      alternatePhone: "+91 87654 32109",
      address: "Bandra West, Mumbai",
      city: "Mumbai",
      state: "Maharashtra",
      country: "India",
      pincode: "400050",
    },
    professionalInfo: {
      education: "MBA Finance",
      educationDetails:
        "Master of Business Administration in Finance from Mumbai University",
      occupation: "Software Engineer",
      company: "TechCorp Solutions Pvt Ltd",
      annualIncome: "₹8-10 Lakhs",
      workLocation: "Mumbai, Maharashtra",
    },
    familyInfo: {
      fatherName: "Rajesh Sharma",
      fatherOccupation: "Business Owner",
      motherName: "Sunita Sharma",
      motherOccupation: "Homemaker",
      siblings: "1 Sister (Younger)",
      familyType: "Nuclear Family",
      familyStatus: "Middle Class",
      familyValues: "Traditional",
    },
    lifestyle: {
      diet: "Vegetarian",
      smoking: "No",
      drinking: "No",
      hobbies: "Reading, Yoga, Cooking, Travelling",
      interests: "Technology, Health & Fitness, Spirituality",
      music: "Classical, Bollywood",
      movies: "Drama, Romance, Comedy",
      sports: "Badminton, Swimming",
    },
    partnerPreferences: {
      ageRange: "26-32 years",
      heightRange: "5'6\" - 6'2\"",
      maritalStatus: "Never Married",
      education: "Graduate or above",
      occupation: "Any",
      income: "₹5+ Lakhs",
      location: "Mumbai, Pune, Delhi",
      religion: "Hindu",
      caste: "Any",
      diet: "Vegetarian preferred",
    },
    aboutMe:
      "I'm a software engineer who believes in balancing career and personal life. I enjoy reading books, practicing yoga, and exploring new cuisines. I'm looking for a life partner who shares similar values and is ready for a committed relationship. Family is very important to me, and I believe in maintaining strong relationships with loved ones.",
    profilePicture:
      "https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=300&h=300&fit=crop&crop=face",
    gallery: [
      "https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=200&h=200&fit=crop&crop=face",
      "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop",
      "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200&h=200&fit=crop",
    ],
  });

  const [editData, setEditData] = useState(profileData);

  const handleEdit = () => {
    setEditData(profileData);
    setIsEditing(true);
  };

  const handleSave = () => {
    setProfileData(editData);
    setIsEditing(false);
  };

  const handleCancel = () => {
    setEditData(profileData);
    setIsEditing(false);
  };

  const handleInputChange = (section, field, value) => {
    setEditData((prev) => ({
      ...prev,
      [section]: {
        ...prev[section],
        [field]: value,
      },
    }));
  };

  const InfoSection = ({ title, icon: Icon, children, sectionKey }) => (
    <div className="matrimony-profile-section">
      <div className="matrimony-section-header">
        <h3 className="matrimony-section-title">
          <Icon className="matrimony-section-icon" />
          {title}
        </h3>
        {!isEditing && sectionKey && (
          <button
            onClick={handleEdit}
            className="matrimony-btn matrimony-btn-edit"
          >
            <Edit3 className="matrimony-btn-icon" />
            Edit
          </button>
        )}
      </div>
      {children}
    </div>
  );

  const InfoField = ({
    label,
    value,
    field,
    section,
    type = "text",
    options = [],
  }) => (
    <div className="matrimony-info-field">
      <label className="matrimony-field-label">{label}</label>
      {isEditing ? (
        type === "select" ? (
          <select
            className="matrimony-form-select"
            value={editData[section]?.[field] || ""}
            onChange={(e) => handleInputChange(section, field, e.target.value)}
          >
            {options.map((option) => (
              <option key={option} value={option}>
                {option}
              </option>
            ))}
          </select>
        ) : type === "textarea" ? (
          <textarea
            className="matrimony-form-input matrimony-textarea"
            value={editData[section]?.[field] || editData[field] || ""}
            onChange={(e) => handleInputChange(section, field, e.target.value)}
            rows={4}
          />
        ) : (
          <input
            type={type}
            className="matrimony-form-input"
            value={editData[section]?.[field] || editData[field] || ""}
            onChange={(e) => handleInputChange(section, field, e.target.value)}
          />
        )
      ) : (
        <p className="matrimony-field-value">{value || "Not specified"}</p>
      )}
    </div>
  );

  return (
    <div className="matrimony-profile">
      <div className="matrimony-container">
        {/* Header */}
        <div className="matrimony-header">
          <h1 className="matrimony-page-title">
            <User className="matrimony-title-icon" />
            Profile Information
          </h1>
          <div className="matrimony-breadcrumb">
            Home <span className="matrimony-breadcrumb-separator"></span>{" "}
            Profile <span className="matrimony-breadcrumb-separator"></span>{" "}
            Basic Information
          </div>
        </div>

        {/* Action Buttons */}
        {isEditing && (
          <div className="matrimony-action-buttons">
            <button
              onClick={handleCancel}
              className="matrimony-btn matrimony-btn-cancel"
            >
              <X className="matrimony-btn-icon" />
              Cancel
            </button>
            <button
              onClick={handleSave}
              className="matrimony-btn matrimony-btn-save"
            >
              <Save className="matrimony-btn-icon" />
              Save Changes
            </button>
          </div>
        )}

        {/* Profile Picture Section */}
        <InfoSection title="Profile Picture" icon={Camera}>
          <div className="matrimony-profile-pic-container">
            <div className="matrimony-profile-pic-wrapper">
              <img
                src={profileData.profilePicture}
                alt="Profile"
                className="matrimony-profile-pic"
              />
              {isEditing && (
                <button className="matrimony-upload-btn">
                  <Camera className="matrimony-upload-icon" />
                </button>
              )}
            </div>
            <div className="matrimony-profile-info">
              <h4 className="matrimony-profile-name">
                {profileData.personalInfo.firstName}{" "}
                {profileData.personalInfo.lastName}
              </h4>
              <p className="matrimony-profile-location">
                {profileData.personalInfo.age} years •{" "}
                {profileData.contactInfo.city}, {profileData.contactInfo.state}
              </p>
              {isEditing && (
                <button className="matrimony-btn matrimony-btn-primary">
                  <Camera className="matrimony-btn-icon" />
                  Change Photo
                </button>
              )}
            </div>
          </div>

          {/* Photo Gallery */}
          <div className="matrimony-gallery-section">
            <h4 className="matrimony-gallery-title">Photo Gallery</h4>
            <div className="matrimony-gallery-grid">
              {profileData.gallery.map((photo, index) => (
                <div key={index} className="matrimony-gallery-item">
                  <img
                    src={photo}
                    alt={`Gallery ${index + 1}`}
                    className="matrimony-gallery-image"
                  />
                  {isEditing && (
                    <button className="matrimony-delete-photo-btn"></button>
                  )}
                </div>
              ))}
              {isEditing && (
                <div className="matrimony-add-photo-btn">
                  <Camera className="matrimony-add-photo-icon" />
                </div>
              )}
            </div>
          </div>
        </InfoSection>

        {/* Personal Information */}
        <InfoSection
          title="Personal Information"
          icon={User}
          sectionKey="personalInfo"
        >
          <div className="matrimony-info-grid">
            <InfoField
              label="First Name"
              value={profileData.personalInfo.firstName}
              field="firstName"
              section="personalInfo"
            />
            <InfoField
              label="Last Name"
              value={profileData.personalInfo.lastName}
              field="lastName"
              section="personalInfo"
            />
            <InfoField
              label="Date of Birth"
              value={profileData.personalInfo.dateOfBirth}
              field="dateOfBirth"
              section="personalInfo"
              type="date"
            />
            <InfoField
              label="Gender"
              value={profileData.personalInfo.gender}
              field="gender"
              section="personalInfo"
              type="select"
              options={["Male", "Female"]}
            />
            <InfoField
              label="Marital Status"
              value={profileData.personalInfo.maritalStatus}
              field="maritalStatus"
              section="personalInfo"
              type="select"
              options={["Never Married", "Divorced", "Widowed"]}
            />
            <InfoField
              label="Religion"
              value={profileData.personalInfo.religion}
              field="religion"
              section="personalInfo"
            />
            <InfoField
              label="Caste"
              value={profileData.personalInfo.caste}
              field="caste"
              section="personalInfo"
            />
            <InfoField
              label="Mother Tongue"
              value={profileData.personalInfo.motherTongue}
              field="motherTongue"
              section="personalInfo"
            />
            <InfoField
              label="Height"
              value={profileData.personalInfo.height}
              field="height"
              section="personalInfo"
            />
            <InfoField
              label="Weight"
              value={profileData.personalInfo.weight}
              field="weight"
              section="personalInfo"
            />
            <InfoField
              label="Body Type"
              value={profileData.personalInfo.bodyType}
              field="bodyType"
              section="personalInfo"
              type="select"
              options={["Slim", "Athletic", "Average", "Heavy"]}
            />
            <InfoField
              label="Complexion"
              value={profileData.personalInfo.complexion}
              field="complexion"
              section="personalInfo"
              type="select"
              options={["Fair", "Wheatish", "Dark"]}
            />
          </div>
        </InfoSection>

        {/* Contact Information */}
        <InfoSection
          title="Contact Information"
          icon={Phone}
          sectionKey="contactInfo"
        >
          <div className="matrimony-info-grid">
            <InfoField
              label="Email Address"
              value={profileData.contactInfo.email}
              field="email"
              section="contactInfo"
              type="email"
            />
            <InfoField
              label="Phone Number"
              value={profileData.contactInfo.phone}
              field="phone"
              section="contactInfo"
            />
            <InfoField
              label="Alternate Phone"
              value={profileData.contactInfo.alternatePhone}
              field="alternatePhone"
              section="contactInfo"
            />
            <InfoField
              label="Address"
              value={profileData.contactInfo.address}
              field="address"
              section="contactInfo"
            />
            <InfoField
              label="City"
              value={profileData.contactInfo.city}
              field="city"
              section="contactInfo"
            />
            <InfoField
              label="State"
              value={profileData.contactInfo.state}
              field="state"
              section="contactInfo"
            />
            <InfoField
              label="Country"
              value={profileData.contactInfo.country}
              field="country"
              section="contactInfo"
            />
            <InfoField
              label="Pin Code"
              value={profileData.contactInfo.pincode}
              field="pincode"
              section="contactInfo"
            />
          </div>
        </InfoSection>

        {/* Professional Information */}
        <InfoSection
          title="Professional Information"
          icon={Briefcase}
          sectionKey="professionalInfo"
        >
          <div className="matrimony-info-grid">
            <InfoField
              label="Education"
              value={profileData.professionalInfo.education}
              field="education"
              section="professionalInfo"
            />
            <InfoField
              label="Occupation"
              value={profileData.professionalInfo.occupation}
              field="occupation"
              section="professionalInfo"
            />
            <InfoField
              label="Company"
              value={profileData.professionalInfo.company}
              field="company"
              section="professionalInfo"
            />
            <InfoField
              label="Annual Income"
              value={profileData.professionalInfo.annualIncome}
              field="annualIncome"
              section="professionalInfo"
            />
            <InfoField
              label="Work Location"
              value={profileData.professionalInfo.workLocation}
              field="workLocation"
              section="professionalInfo"
            />
          </div>
          <InfoField
            label="Education Details"
            value={profileData.professionalInfo.educationDetails}
            field="educationDetails"
            section="professionalInfo"
            type="textarea"
          />
        </InfoSection>

        {/* About Me Section */}
        <InfoSection title="About Me" icon={Heart}>
          <InfoField
            label="Tell us about yourself"
            value={profileData.aboutMe}
            field="aboutMe"
            section=""
            type="textarea"
          />
        </InfoSection>

        {/* Family Information */}
        <InfoSection
          title="Family Information"
          icon={User}
          sectionKey="familyInfo"
        >
          <div className="matrimony-info-grid">
            <InfoField
              label="Father's Name"
              value={profileData.familyInfo.fatherName}
              field="fatherName"
              section="familyInfo"
            />
            <InfoField
              label="Father's Occupation"
              value={profileData.familyInfo.fatherOccupation}
              field="fatherOccupation"
              section="familyInfo"
            />
            <InfoField
              label="Mother's Name"
              value={profileData.familyInfo.motherName}
              field="motherName"
              section="familyInfo"
            />
            <InfoField
              label="Mother's Occupation"
              value={profileData.familyInfo.motherOccupation}
              field="motherOccupation"
              section="familyInfo"
            />
            <InfoField
              label="Siblings"
              value={profileData.familyInfo.siblings}
              field="siblings"
              section="familyInfo"
            />
            <InfoField
              label="Family Type"
              value={profileData.familyInfo.familyType}
              field="familyType"
              section="familyInfo"
              type="select"
              options={["Nuclear Family", "Joint Family"]}
            />
            <InfoField
              label="Family Status"
              value={profileData.familyInfo.familyStatus}
              field="familyStatus"
              section="familyInfo"
              type="select"
              options={[
                "Lower Middle Class",
                "Middle Class",
                "Upper Middle Class",
                "Rich",
                "Affluent",
              ]}
            />
            <InfoField
              label="Family Values"
              value={profileData.familyInfo.familyValues}
              field="familyValues"
              section="familyInfo"
              type="select"
              options={["Traditional", "Moderate", "Liberal"]}
            />
          </div>
        </InfoSection>

        {/* Lifestyle Information */}
        <InfoSection
          title="Lifestyle & Interests"
          icon={Heart}
          sectionKey="lifestyle"
        >
          <div className="matrimony-info-grid">
            <InfoField
              label="Diet"
              value={profileData.lifestyle.diet}
              field="diet"
              section="lifestyle"
              type="select"
              options={["Vegetarian", "Non-Vegetarian", "Eggetarian", "Vegan"]}
            />
            <InfoField
              label="Smoking"
              value={profileData.lifestyle.smoking}
              field="smoking"
              section="lifestyle"
              type="select"
              options={["No", "Occasionally", "Yes"]}
            />
            <InfoField
              label="Drinking"
              value={profileData.lifestyle.drinking}
              field="drinking"
              section="lifestyle"
              type="select"
              options={["No", "Socially", "Occasionally", "Yes"]}
            />
            <InfoField
              label="Music Preferences"
              value={profileData.lifestyle.music}
              field="music"
              section="lifestyle"
            />
            <InfoField
              label="Movie Preferences"
              value={profileData.lifestyle.movies}
              field="movies"
              section="lifestyle"
            />
            <InfoField
              label="Sports"
              value={profileData.lifestyle.sports}
              field="sports"
              section="lifestyle"
            />
          </div>
          <div className="matrimony-textarea-grid">
            <InfoField
              label="Hobbies"
              value={profileData.lifestyle.hobbies}
              field="hobbies"
              section="lifestyle"
              type="textarea"
            />
            <InfoField
              label="Interests"
              value={profileData.lifestyle.interests}
              field="interests"
              section="lifestyle"
              type="textarea"
            />
          </div>
        </InfoSection>

        {/* Partner Preferences */}
        <InfoSection
          title="Partner Preferences"
          icon={Heart}
          sectionKey="partnerPreferences"
        >
          <div className="matrimony-info-grid">
            <InfoField
              label="Age Range"
              value={profileData.partnerPreferences.ageRange}
              field="ageRange"
              section="partnerPreferences"
            />
            <InfoField
              label="Height Range"
              value={profileData.partnerPreferences.heightRange}
              field="heightRange"
              section="partnerPreferences"
            />
            <InfoField
              label="Marital Status"
              value={profileData.partnerPreferences.maritalStatus}
              field="maritalStatus"
              section="partnerPreferences"
              type="select"
              options={["Never Married", "Divorced", "Widowed", "Any"]}
            />
            <InfoField
              label="Education"
              value={profileData.partnerPreferences.education}
              field="education"
              section="partnerPreferences"
            />
            <InfoField
              label="Occupation"
              value={profileData.partnerPreferences.occupation}
              field="occupation"
              section="partnerPreferences"
            />
            <InfoField
              label="Income"
              value={profileData.partnerPreferences.income}
              field="income"
              section="partnerPreferences"
            />
            <InfoField
              label="Location"
              value={profileData.partnerPreferences.location}
              field="location"
              section="partnerPreferences"
            />
            <InfoField
              label="Religion"
              value={profileData.partnerPreferences.religion}
              field="religion"
              section="partnerPreferences"
            />
            <InfoField
              label="Caste"
              value={profileData.partnerPreferences.caste}
              field="caste"
              section="partnerPreferences"
            />
            <InfoField
              label="Diet Preference"
              value={profileData.partnerPreferences.diet}
              field="diet"
              section="partnerPreferences"
              type="select"
              options={[
                "Vegetarian preferred",
                "Non-Vegetarian preferred",
                "No Preference",
              ]}
            />
          </div>
        </InfoSection>

        {/* Profile Completion Status */}
        <div className="matrimony-profile-section">
          <h3 className="matrimony-section-title">
            <Check className="matrimony-section-icon" />
            Profile Completion Status
          </h3>

          <div className="matrimony-completion-status">
            <div className="matrimony-completion-header">
              <span className="matrimony-completion-label">
                Profile Completion
              </span>
              <span className="matrimony-completion-percent">85%</span>
            </div>
            <div className="matrimony-completion-bar">
              <div className="matrimony-completion-progress"></div>
            </div>
          </div>

          <div className="matrimony-completion-grid">
            {[
              { label: "Basic Information", completed: true },
              { label: "Contact Details", completed: true },
              { label: "Professional Info", completed: true },
              { label: "Family Details", completed: true },
              { label: "Lifestyle", completed: true },
              { label: "Partner Preferences", completed: true },
              { label: "Photo Gallery", completed: false },
              { label: "Horoscope Details", completed: false },
            ].map((item, index) => (
              <div
                key={index}
                className={`matrimony-completion-item ${
                  item.completed ? "completed" : ""
                }`}
              >
                <div
                  className={`matrimony-completion-badge ${
                    item.completed ? "completed" : ""
                  }`}
                >
                  {item.completed ? "✓" : "•"}
                </div>
                <span className="matrimony-completion-item-label">
                  {item.label}
                </span>
              </div>
            ))}
          </div>

          <div className="matrimony-completion-cta">
            <h4 className="matrimony-cta-title">Complete Your Profile</h4>
            <p className="matrimony-cta-description">
              Add more photos and horoscope details to increase your profile
              visibility by 40%
            </p>
            <div className="matrimony-cta-buttons">
              <button className="matrimony-btn matrimony-btn-primary">
                <Camera className="matrimony-btn-icon" />
                Add Photos
              </button>
              <button className="matrimony-btn matrimony-btn-secondary">
                Add Horoscope
              </button>
            </div>
          </div>
        </div>

        {/* Privacy Settings */}
        <div className="matrimony-profile-section">
          <h3 className="matrimony-section-title">
            <User className="matrimony-section-icon" />
            Privacy Settings
          </h3>

          <div className="matrimony-privacy-grid">
            {[
              {
                label: "Show contact number",
                description: "Allow members to see your contact number",
                enabled: false,
              },
              {
                label: "Show photo to all",
                description: "Make your photos visible to all members",
                enabled: true,
              },
              {
                label: "Show horoscope details",
                description: "Display astrological information",
                enabled: true,
              },
              {
                label: "Allow photo requests",
                description: "Let members request for more photos",
                enabled: true,
              },
            ].map((setting, index) => (
              <div key={index} className="matrimony-privacy-item">
                <div>
                  <h4 className="matrimony-privacy-label">{setting.label}</h4>
                  <p className="matrimony-privacy-description">
                    {setting.description}
                  </p>
                </div>
                <label className="matrimony-switch">
                  <input
                    type="checkbox"
                    defaultChecked={setting.enabled}
                    className="matrimony-switch-input"
                  />
                  <span
                    className={`matrimony-switch-slider ${
                      setting.enabled ? "enabled" : ""
                    }`}
                  >
                    <span className="matrimony-switch-thumb"></span>
                  </span>
                </label>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default BasicInformation;
