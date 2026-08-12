import React from "react";

export const Input = React.forwardRef(
  ({ type = "text", className = "", ...props }, ref) => {
    return (
      <input
        ref={ref}
        type={type}
        className={`form-control-custom ${className}`}
        {...props}
      />
    );
  }
);
