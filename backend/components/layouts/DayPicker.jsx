import React from "react";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import { TextField } from "@mui/material";
import dayjs from "dayjs";

function EventDatePicker({ formData, setFormData }) {
  return (
    <div className="mb-3">
      <label className="form-label d-block mb-2">Event Date *</label>
      <LocalizationProvider dateAdapter={AdapterDayjs}>
        <DatePicker
          value={formData.eventDate ? dayjs(formData.eventDate) : null}
          onChange={(newDate) =>
            setFormData({
              ...formData,
              eventDate: newDate ? newDate.toDate() : null,
            })
          }
          minDate={dayjs()}
          format="DD/MM/YYYY"
          slotProps={{
            textField: {
              fullWidth: true,
              variant: "outlined",
              size: "small",
            },
          }}
        />
      </LocalizationProvider>
    </div>
  );
}

export default EventDatePicker;
