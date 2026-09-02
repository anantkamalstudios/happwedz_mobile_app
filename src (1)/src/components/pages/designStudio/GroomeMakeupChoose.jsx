import React from "react";
import { useDispatch } from "react-redux";
import { useNavigate } from "react-router-dom";
import { setRoleType } from "../../../redux/roleSlice";

const SectionCard = ({ title, subtitle, image, onTry, comingSoon }) => {
  return (
    <div
      className="position-relative overflow-hidden mb-4"
      style={{ pointerEvents: comingSoon ? "none" : "auto" }}
    >
      {/* Background Image */}
      <img
        src={image}
        alt={title}
        className="w-100"
        style={{
          objectFit: "cover",
          height: "75vh", // better for mobile
          maxHeight: "820px", // keeps desktop clean
          filter: comingSoon ? "brightness(0.6)" : "brightness(1)",
        }}
      />

      {/* Text Container */}
      <div
        className="
          position-absolute top-50 start-50 translate-middle
          text-center text-md-end text-white
          p-3 p-md-4
          w-100 d-flex justify-content-center justify-content-md-end
        "
      >
        <div className="col-10 col-md-4">
          <h1 className="fw-semibold mb-2">{title}</h1>
          <p className="mb-3 fs-6 fs-md-5" style={{ opacity: 0.9 }}>
            {subtitle}
          </p>

          <button
            onClick={onTry}
            className="btn w-100 rounded-4 mt-2"
            style={{
              padding: "12px 0",
              background: "linear-gradient(to right, #E83580, #821E48)",
              color: "#fff",
              fontSize: "18px",
              border: "none",
            }}
          >
            Get Started
          </button>
        </div>
      </div>

      {/* Coming Soon */}
      {comingSoon && (
        <div
          className="
            position-absolute top-0 start-0 
            w-100 h-100 d-flex justify-content-center align-items-center
          "
          style={{ background: "rgba(0,0,0,0.5)", zIndex: 10 }}
        >
          <h3
            className="fw-bold text-white"
            style={{ fontSize: "2.5rem", letterSpacing: "2px" }}
          >
            Coming Soon
          </h3>
        </div>
      )}
    </div>
  );
};

const GroomeMakeupChoose = () => {
  const navigate = useNavigate();
  const dispatch = useDispatch();

  return (
    <>
      <SectionCard
        title="Makeup"
        subtitle="Explore stunning groome makeup looks curated by professionals."
        image="/images/try/groomMakeup.png"
        onTry={() => {
          navigate("/try/makeup");
          dispatch(setRoleType({ type: "makeup" }));
          const userInfo = JSON.parse(localStorage.getItem("userInfo"));
          userInfo.type = "makeup";
          localStorage.setItem("userInfo", JSON.stringify(userInfo));
        }}
      />

      <SectionCard
        title="Jewellery"
        subtitle="Try elegant jewellery pieces that complement your groome style."
        image="/images/try/groomJewellary.png"
        onTry={() => {
          navigate("/try/makeup");
          dispatch(setRoleType({ type: "jewellary" }));
          const userInfo = JSON.parse(localStorage.getItem("userInfo"));
          userInfo.type = "jewellary";
          localStorage.setItem("userInfo", JSON.stringify(userInfo));
        }}
        comingSoon
      />

      <SectionCard
        title="Outfit"
        subtitle="Visualize outfits to complete your perfect groome look."
        image="/images/try/groomOutfit.png"
        onTry={() => {
          navigate("/try/makeup");
          dispatch(setRoleType({ type: "outfit" }));
          const userInfo = JSON.parse(localStorage.getItem("userInfo"));
          userInfo.type = "outfit";
          localStorage.setItem("userInfo", JSON.stringify(userInfo));
        }}
        comingSoon
      />
    </>
  );
};

export default GroomeMakeupChoose;
