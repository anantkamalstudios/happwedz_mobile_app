import React from "react";

const EInviteCard = ({ image, title, price, zoom }) => {
  return (
    <div className={`invitation-card ${zoom ? "zoomed" : ""}`}>
      <img src={image} alt={title} />
      <div className="invitation-info">
        <h4>{title}</h4>
        <p>Starts from ₹{price}</p>
      </div>
    </div>
  );
};

export default EInviteCard;
