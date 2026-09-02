import React, { useMemo } from "react";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import { PickersDay } from "@mui/x-date-pickers/PickersDay";
import dayjs from "dayjs";

function EventDatePicker({ formData, setFormData, availableSlots = [] }) {
  // Normalize slots into an array of "YYYY-MM-DD" strings
  const normalizedSlots = useMemo(() => {
    if (!Array.isArray(availableSlots)) return [];
    return availableSlots
      .map((s) => {
        if (!s) return null;
        if (typeof s === "string") return s.split("T")[0].trim();
        if (s.date) return String(s.date).split("T")[0].trim();
        return null;
      })
      .filter(Boolean);
  }, [availableSlots]);

  const selectedDateStr = formData.eventDate
    ? dayjs(formData.eventDate).format("YYYY-MM-DD")
    : null;

  const isSelectedAvailable =
    selectedDateStr && normalizedSlots.includes(selectedDateStr);

  // Auto-focus calendar on the month containing available slots
  const firstAvailableDayjs = useMemo(() => {
    if (formData.eventDate) return dayjs(formData.eventDate);
    if (normalizedSlots.length > 0) {
      const sorted = [...normalizedSlots].sort();
      return dayjs(sorted[0]);
    }
    return dayjs();
  }, [formData.eventDate, normalizedSlots]);

  // Clean, elegant Day Component matching HappyWedz Theme
  const CustomDay = useMemo(() => {
    return function DayComponent(props) {
      const { day, outsideCurrentMonth, selected, disabled, ...other } = props;
      const dayFormatted = day.format("YYYY-MM-DD");
      const isAvailable =
        !outsideCurrentMonth && normalizedSlots.includes(dayFormatted);

      return (
        <PickersDay
          {...other}
          day={day}
          outsideCurrentMonth={outsideCurrentMonth}
          selected={selected}
          disabled={disabled}
          sx={{
            margin: "2px",
            ...(isAvailable &&
              !selected && {
                backgroundColor: "#fff0f5 !important",
                color: "#ED1173 !important",
                fontWeight: "700 !important",
                border: "1.5px solid #ED1173 !important",
                borderRadius: "50%",
                "&:hover": {
                  backgroundColor: "#fce7f3 !important",
                  transform: "scale(1.06)",
                },
              }),
            ...(selected && {
              backgroundColor: "#ED1173 !important",
              color: "#ffffff !important",
              fontWeight: "bold !important",
              borderRadius: "50%",
            }),
            ...(disabled && {
              color: "#64748b !important",
              opacity: 0.75,
              fontWeight: "500",
              cursor: "not-allowed !important",
            }),
          }}
        />
      );
    };
  }, [normalizedSlots]);

  return (
    <div className="form-group mb-3">
      <div className="d-flex justify-content-between align-items-center mb-1">
        <label className="form-label mb-0">Event Date *</label>
        {normalizedSlots.length > 0 && (
          <small className="text-muted" style={{ fontSize: "11.5px" }}>
            Only available dates are selectable
          </small>
        )}
      </div>

      <LocalizationProvider dateAdapter={AdapterDayjs}>
        <DatePicker
          value={formData.eventDate ? dayjs(formData.eventDate) : null}
          format="DD/MM/YYYY"
          referenceDate={firstAvailableDayjs}
          minDate={dayjs()}
          shouldDisableDate={(day) => {
            if (!normalizedSlots || normalizedSlots.length === 0) return false;
            const dayStr = day.format("YYYY-MM-DD");
            return !normalizedSlots.includes(dayStr);
          }}
          onChange={(newDate) =>
            setFormData({
              ...formData,
              eventDate: newDate ? newDate.toDate() : null,
            })
          }
          slots={{
            day: CustomDay,
          }}
          slotProps={{
            textField: {
              fullWidth: true,
              variant: "outlined",
              size: "small",
              placeholder: "DD/MM/YYYY",
              sx: {
                "& .MuiOutlinedInput-root": {
                  borderRadius: "6px",
                  fontSize: "14px",
                  "& fieldset": {
                    borderColor: "#dee2e6",
                  },
                  "&:hover fieldset": {
                    borderColor: "#ced4da",
                  },
                  "&.Mui-focused fieldset": {
                    borderColor: "#ED1173",
                    borderWidth: "1px",
                  },
                },
              },
            },
            popper: {
              sx: {
                "& .MuiPaper-root": {
                  borderRadius: "10px",
                  boxShadow: "0 8px 24px rgba(0, 0, 0, 0.12)",
                  border: "1px solid #f0f0f0",
                },
                "& .MuiPickersCalendarHeader-root": {
                  color: "#333",
                  fontWeight: "600",
                },
                "& .MuiDayCalendar-weekDayLabel": {
                  color: "#666",
                  fontWeight: "500",
                },
              },
            },
          }}
        />
      </LocalizationProvider>

      {/* Confirmation feedback */}
      {formData.eventDate && (
        <div className="mt-1" style={{ fontSize: "12px" }}>
          {isSelectedAvailable ? (
            <span style={{ color: "#ED1173", fontWeight: "500" }}>
              ✓ Confirmed available date with vendor
            </span>
          ) : (
            <span className="text-muted">
              Custom date selected
            </span>
          )}
        </div>
      )}
    </div>
  );
}

export default EventDatePicker;
