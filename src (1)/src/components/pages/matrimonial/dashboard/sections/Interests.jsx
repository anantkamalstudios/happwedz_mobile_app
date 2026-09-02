import React, { useState } from "react";

const Interests = () => {
  const [sent] = useState([
    { id: 1, name: "Priya Sharma", status: "Pending" },
    { id: 2, name: "Anjali Patel", status: "Accepted" },
  ]);
  const [received] = useState([{ id: 3, name: "Ravi Kumar", status: "New" }]);

  return (
    <div className="matrimonial-dashboard__section">
      <div className="matrimonial-dashboard__content-header">
        <h1 className="matrimonial-dashboard__page-title">Interests</h1>
      </div>

      <div className="matrimonial-dashboard__two-col">
        <div>
          <h3>Sent</h3>
          <div className="matrimonial-dashboard__list">
            {sent.map((i) => (
              <div key={i.id} className="matrimonial-dashboard__list-item">
                <span>{i.name}</span>
                <span className="matrimonial-dashboard__badge">{i.status}</span>
              </div>
            ))}
          </div>
        </div>
        <div>
          <h3>Received</h3>
          <div className="matrimonial-dashboard__list">
            {received.map((i) => (
              <div key={i.id} className="matrimonial-dashboard__list-item">
                <span>{i.name}</span>
                <div>
                  <button className="matrimonial-dashboard__btn matrimonial-dashboard__btn-primary">
                    Accept
                  </button>
                  <button className="matrimonial-dashboard__btn matrimonial-dashboard__btn-secondary">
                    Decline
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Interests;
