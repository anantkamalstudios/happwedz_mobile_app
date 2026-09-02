import React from "react";

const GuestsAccess = () => {
  return (
    <div className="p-4">
      <h2 className="mb-4 fw-bold" style={{ color: "#2c3e50" }}>
        Guests Access
      </h2>
      <div className="card border-0 shadow-sm">
        <div className="card-body p-4">
          <h5 className="card-title mb-3">
            Manage guest access and permissions
          </h5>
          <p className="text-muted mb-0">
            Control who can access your content and manage guest permissions.
            Invite guests and set access levels for different users.
          </p>
        </div>
      </div>
    </div>
  );
};

export default GuestsAccess;
