import React from "react";

const ProfileCard = ({ profile }) => {
  return (
    <div className="matrimonial-dashboard">
      <div className="matrimonial-dashboard-profile-card">
        {/* Header */}
        <div className="matrimonial-dashboard-profile-header">
          <div>
            <h3 className="matrimonial-dashboard-profile-name">
              {profile.name}, {profile.age}
            </h3>
            <p className="matrimonial-dashboard-profile-meta">
              Last seen at {profile.lastSeen} • ID: {profile.id}
            </p>
          </div>
          <div className="matrimonial-dashboard-profile-id">{profile.id}</div>
        </div>

        {/* Details */}
        <div className="matrimonial-dashboard-profile-details">
          <span className="matrimonial-dashboard-profile-detail">
            <i className="fas fa-ruler"></i> {profile.height}
          </span>
          <span className="matrimonial-dashboard-profile-detail">
            <i className="fas fa-map-marker-alt"></i> {profile.location}
          </span>
          <span className="matrimonial-dashboard-profile-detail">
            {profile.caste}
          </span>
          <span className="matrimonial-dashboard-profile-detail">
            <i className="fas fa-briefcase"></i> {profile.profession}
          </span>
          <span className="matrimonial-dashboard-profile-detail">
            {profile.income}
          </span>
          <span className="matrimonial-dashboard-profile-detail">
            {profile.education}
          </span>
          <span className="matrimonial-dashboard-profile-detail">
            {profile.maritalStatus}
          </span>
        </div>

        {/* Actions */}
        <div className="matrimonial-dashboard-profile-actions">
          <button className="matrimonial-dashboard-btn matrimonial-dashboard-btn-primary">
            <i className="fas fa-heart"></i> Super Interest
          </button>
          <button className="matrimonial-dashboard-btn matrimonial-dashboard-btn-outline">
            <i className="fas fa-bookmark"></i> Shortlist
          </button>
          <button className="matrimonial-dashboard-btn matrimonial-dashboard-btn-outline">
            <i className="fas fa-comment"></i> Chat
          </button>
        </div>
      </div>
    </div>
  );
};

export default ProfileCard;
