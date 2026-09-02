import React from "react";

export const Label = ({ children, htmlFor, className = "" }) => {
  return (
    <label htmlFor={htmlFor} className={`label-custom ${className}`}>
      {children}
    </label>
  );
};
