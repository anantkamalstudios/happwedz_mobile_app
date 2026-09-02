import React from "react";
import "./style.css";

const Footer = (props) => {
  return (
    <div
      className={`site-footer`}
      style={{
        background: `url(${props.sliderImages[0]})`,
        backgroundRepeat: "no-repeat",
        backgroundPosition: "center",
        backgroundSize: "100% 100%",
      }}
    >
      <div className="container">
        <div className="row">
          <div className="text">
            <h2>David & Aliza</h2>
            <p>Thank you</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Footer;
