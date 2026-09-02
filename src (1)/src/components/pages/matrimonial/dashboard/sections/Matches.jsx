import React from "react";

const Matches = ({ profiles = [], onSelectProfile }) => {
  return (
    <div className="matrimonial-dashboard__section">
      <div className="matrimonial-dashboard__content-header">
        <h1 className="matrimonial-dashboard__page-title">My Matches</h1>
      </div>

      <div className="matrimonial-dashboard__profiles-grid">
        {profiles.map((profile) => (
          <div key={profile.id} className="matrimonial-dashboard__profile-card">
            <div className="matrimonial-dashboard__profile-image-container">
              <img
                src={profile.image}
                alt={profile.name}
                className="matrimonial-dashboard__profile-image"
              />
              <span
                className={`matrimonial-dashboard__profile-status ${profile.status}`}
              >
                {profile.status}
              </span>
            </div>
            <div className="matrimonial-dashboard__profile-content">
              <h3 className="matrimonial-dashboard__profile-name">
                {profile.name}
              </h3>
              <div className="matrimonial-dashboard__profile-details">
                <p>{profile.location}</p>
                <p>{profile.age} years</p>
                <p>{profile.profession}</p>
              </div>
              <div className="matrimonial-dashboard__profile-actions">
                <button
                  className="matrimonial-dashboard__btn matrimonial-dashboard__btn-primary"
                  onClick={() => onSelectProfile?.(profile)}
                >
                  View Profile
                </button>
                <button className="matrimonial-dashboard__btn matrimonial-dashboard__btn-secondary">
                  Send Interest
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Matches;
