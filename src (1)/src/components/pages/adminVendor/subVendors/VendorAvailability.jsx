import React, { useState, useEffect } from "react";
import VendorAvailabilityCalendar from "./VendorAvailabilityCalendar";

const VendorAvailability = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
}) => {
  const [availableDates, setAvailableDates] = useState(
    (
      (Array.isArray(formData?.availableSlots)
        ? formData.availableSlots
        : null) ||
      formData?.attributes?.availableSlots ||
      formData?.attributes?.available_slots ||
      []
    ).map((item) => item.date)
  );

  useEffect(() => {
    const slots =
      (Array.isArray(formData?.availableSlots)
        ? formData.availableSlots
        : null) ||
      formData?.attributes?.availableSlots ||
      formData?.attributes?.available_slots ||
      [];
    const next = Array.isArray(slots) ? slots.map((s) => s.date) : [];
    // Only update if different to avoid loop/reset
    setAvailableDates((prev) => {
      const prevStr = JSON.stringify(prev.sort());
      const nextStr = JSON.stringify(next.sort());
      return prevStr === nextStr ? prev : next;
    });
  }, [
    formData?.availableSlots,
    formData?.attributes?.availableSlots,
    formData?.attributes?.available_slots,
  ]);

  // Sync selected dates to formData.availableSlots automatically
  useEffect(() => {
    setFormData((prev) => {
      const next = availableDates.map((d) => ({ date: d }));
      const prevDates = Array.isArray(prev?.availableSlots)
        ? prev.availableSlots.map((s) => s.date)
        : [];
      const a = new Set(prevDates);
      const b = new Set(availableDates);
      let equal = a.size === b.size;
      if (equal) {
        for (const v of a)
          if (!b.has(v)) {
            equal = false;
            break;
          }
      }
      if (equal) return prev; // no change
      return { ...prev, availableSlots: next };
    });
  }, [availableDates, setFormData]);

  const handleNestedInputChange = (subSection, field, value) => {
    setFormData((prev) => ({
      ...prev,
      [subSection]: {
        ...((prev && prev[subSection]) || {}),
        [field]: value,
      },
    }));
  };

  // Manual save button handler (optional)
  const handleSaveAndShow = async () => {
    if (onSave) await onSave();
    if (onShowSuccess) onShowSuccess();
  };

  const isActive = formData?.availabilityActive !== false;

  const handleToggleActive = () => {
    setFormData((prev) => ({
      ...prev,
      availabilityActive: !(prev?.availabilityActive !== false),
    }));
  };

  return (
    <div className="my-5">
      <div className="p-3 border rounded bg-white">
        <div className="d-flex align-items-center justify-content-between mb-3">
          <h4 className="mb-0 fw-bold">Availability & Slots</h4>
          <div className="form-check form-switch mb-0">
            <input
              className="form-check-input"
              type="checkbox"
              role="switch"
              id="availabilityActiveSwitch"
              checked={isActive}
              onChange={handleToggleActive}
            />
            <label
              className="form-check-label fs-14 fw-semibold"
              htmlFor="availabilityActiveSwitch"
            >
              {isActive ? "Active" : "Inactive"}
            </label>
          </div>
        </div>

        {isActive ? (
          /* Calendar Section */
          <div className="mb-4">
            <VendorAvailabilityCalendar
              initialAvailableDates={availableDates}
              onAvailabilityChange={setAvailableDates}
            />
          </div>
        ) : (
          <div className="alert alert-warning fs-14" role="alert">
            Availability & Slots is turned off, so couples won't see a
            calendar on your listing. Switch it back on to manage dates.
          </div>
        )}

        <button
          className="btn btn-primary mt-2 fs-14"
          onClick={handleSaveAndShow}
        >
          Save Availability Details
        </button>
      </div>
    </div>
  );
};

export default VendorAvailability;
