import React from "react";
import { CheckIcon } from "lucide-react";

export const Checkbox = React.forwardRef(
  ({ checked, onChange, className = "" }, ref) => {
    return (
      <label className="d-inline-flex align-items-center gap-2">
        <input
          ref={ref}
          type="checkbox"
          className={`checkbox-custom ${className}`}
          checked={checked}
          onChange={onChange}
        />
        {checked && <CheckIcon size={14} />}
      </label>
    );
  }
);
