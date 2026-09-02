import React from "react";

export const Separator = ({ className = "", orientation = "horizontal" }) => {
  const style =
    orientation === "vertical"
      ? { width: "1px", height: "100%" }
      : { height: "1px", width: "100%" };

  return <div className={`separator-custom ${className}`} style={style}></div>;
};
