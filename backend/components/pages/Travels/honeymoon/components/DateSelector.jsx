import { useRef } from "react";
import { CalendarSearch } from "lucide-react";

export default function DateSelector({
  label,
  value,
  onChange,
  min,
  placeholder,
}) {
  const dateRef = useRef(null);

  return (
    <div className="field-box">
      <div
        className="field-label field-label-clickable"
        onClick={() => dateRef.current?.focus()}
      >
        <span className="field-label-content">
          <CalendarSearch size={14} /> {label}
        </span>
      </div>
      <input
        ref={dateRef}
        className="field-input"
        type="text"
        placeholder={placeholder}
        value={value}
        onChange={onChange}
        onFocus={(e) => (e.target.type = "date")}
        onBlur={(e) => {
          if (!e.target.value) e.target.type = "text";
        }}
        min={min}
      />
    </div>
  );
}
