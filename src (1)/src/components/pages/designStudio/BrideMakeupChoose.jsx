import React from "react";
import { useDispatch } from "react-redux";
import { useLocation, useNavigate } from "react-router-dom";
import { setRoleType } from "../../../redux/roleSlice";

const SectionCard = ({ title, subtitle, image, onTry, comingSoon }) => {
  return (
    <div
      className="position-relative rounded-0 overflow-hidden mb-4"
      style={{
        pointerEvents: comingSoon ? "none" : "auto",
      }}
    >
      <img
        src={image}
        alt={title}
        className="w-100"
        style={{
          objectFit: "cover",
          filter: comingSoon ? "brightness(0.6)" : "brightness(1)",
          height: "90vh",
        }}
      />
      <div className="row position-absolute bottom-50 end-0 p-4 text-center text-white w-100 d-flex justify-content-end">
        <div className="col-md-6"></div>
        <div className="col-md-4 justify-content-end">
          <h1 className="fw-semibold mb-2 ">{title}</h1>
          <p className="mb-3 fs-20" style={{ opacity: 0.9 }}>
            {subtitle}
          </p>
          <button
            className="rounded-4 w-75 mt-2"
            style={{
              padding: "10px 0",
              background: "linear-gradient(to right, #E83580, #821E48)",
              color: "#fff",
              border: "none",
              fontSize: "20px",
            }}
            onClick={onTry}
          >
            Get Started
          </button>
        </div>
      </div>

      {comingSoon && (
        <div
          className="position-absolute top-0 start-0 w-100 h-100 d-flex justify-content-center align-items-center"
          style={{
            background: "rgba(0,0,0,0.5)",
            zIndex: 10,
          }}
        >
          <h1
            style={{
              fontSize: "3rem",
              fontWeight: "900",
              color: "#fff",
              letterSpacing: "2px",
            }}
          >
            Coming Soon
          </h1>
        </div>
      )}
    </div>
  );
};

const BrideMakeupChoose = () => {
  const navigate = useNavigate();
  const dispatch = useDispatch();

  return (
    <div className="">
      <SectionCard
        title="Makeup"
        subtitle="Instantly Try On Makeup Looks And Find Your Perfect Shades."
        image="/images/try/makeup1.png"
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
        subtitle="Instantly Try On Jewellery Looks And Find Your Perfect Piece."
        image="/images/try/jewellaryImage.png"
        onTry={() => {
          navigate("/try/makeup");
          dispatch(setRoleType({ type: "jewellary" }));
          const userInfo = JSON.parse(localStorage.getItem("userInfo"));
          userInfo.type = "jewellary";
          localStorage.setItem("userInfo", JSON.stringify(userInfo));
        }}
      />

      <SectionCard
        title="Outfit"
        subtitle="Instantly Try On Outfits And Find Your Perfect Look."
        image="/images/try/BrideOutfitImage.png"
        onTry={() => {
          navigate("/try/makeup");
          dispatch(setRoleType({ type: "outfit" }));
          const userInfo = JSON.parse(localStorage.getItem("userInfo"));
          userInfo.type = "outfit";
          localStorage.setItem("userInfo", JSON.stringify(userInfo));
        }}
      />
    </div>
  );
};

export default BrideMakeupChoose;
