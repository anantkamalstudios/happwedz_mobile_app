import React, { useState, useEffect, useRef } from "react";
import dayjs from "dayjs";
import "dayjs/locale/en";
import { Check, X, Clock } from "lucide-react";

// Helper to get all days from current month to December
const getMonthsDays = (initialAvailableDates = []) => {
  const today = dayjs();
  const months = [];

  for (let month = today.month(); month <= 11; month++) {
    const monthStart = today.month(month).startOf("month");
    const daysInMonth = monthStart.daysInMonth();
    const firstDayOfWeek = monthStart.day();
    const days = [];

    for (let i = 0; i < firstDayOfWeek; i++) {
      days.push(null);
    }

    for (let day = 1; day <= daysInMonth; day++) {
      const date = dayjs(new Date(today.year(), month, day));
      const isToday = date.isSame(dayjs(), "day");
      const isPast = date.isBefore(dayjs(), "day");
      const isInitiallyAvailable = initialAvailableDates.includes(
        date.format("YYYY-MM-DD")
      );

      days.push({
        date: date,
        available: !isPast && isInitiallyAvailable,
        isToday: isToday,
        isPast: isPast,
        dayNumber: day,
      });
    }

    months.push({
      month,
      days,
      monthName: monthStart.format("MMMM YYYY"),
      shortName: monthStart.format("MMM"),
    });
  }

  return months;
};

const VendorAvailabilityCalendar = ({
  initialAvailableDates = [],
  onAvailabilityChange,
}) => {
  const [monthsDays, setMonthsDays] = useState(() =>
    getMonthsDays(initialAvailableDates)
  );
  const [stats, setStats] = useState({
    available: 0,
    unavailable: 0,
    total: 0,
  });
  const lastSentSelectedRef = useRef(null);

  // Calculate summary stats
  useEffect(() => {
    let available = 0;
    let unavailable = 0;
    let total = 0;

    monthsDays.forEach((monthData) => {
      monthData.days.forEach((day) => {
        if (day && !day.isPast) {
          total++;
          if (day.available) available++;
          else unavailable++;
        }
      });
    });

    setStats({ available, unavailable, total });
  }, [monthsDays]);

  // Notify parent when selected dates actually change
  useEffect(() => {
    const selectedDates = [];
    monthsDays.forEach((m) =>
      m.days.forEach((d) => {
        if (d && !d.isPast && d.available)
          selectedDates.push(d.date.format("YYYY-MM-DD"));
      })
    );
    const signature = JSON.stringify(selectedDates);
    if (lastSentSelectedRef.current !== signature) {
      lastSentSelectedRef.current = signature;
      if (onAvailabilityChange) onAvailabilityChange(selectedDates);
    }
  }, [monthsDays, onAvailabilityChange]);

  useEffect(() => {
    setMonthsDays(getMonthsDays(initialAvailableDates));
  }, [initialAvailableDates]);

  // Toggle single date
  const toggleAvailability = (monthIndex, dayIndex) => {
    const day = monthsDays[monthIndex].days[dayIndex];
    if (!day || day.isPast) return;

    const updated = [...monthsDays];
    updated[monthIndex].days[dayIndex].available =
      !updated[monthIndex].days[dayIndex].available;
    setMonthsDays(updated);
  };

  // Toggle entire month
  const setMonthAvailability = (monthIndex, available) => {
    const updated = [...monthsDays];
    updated[monthIndex].days = updated[monthIndex].days.map((day) =>
      day && !day.isPast ? { ...day, available } : day
    );
    setMonthsDays(updated);
  };

  const weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  return (
    <div className="container-fluid py-4">
      {/* Header with Statistics */}
      <div className="row mb-4">
        <div className="col-12">
          <div className="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-3 mb-4">
            <div>
              <h4 className="mb-1 fw-semibold">Availability Calendar</h4>
              <p className="text-muted mb-0" style={{ fontSize: "0.9rem" }}>
                Manage your availability for upcoming months
              </p>
            </div>

            {/* Stats Cards */}
            <div className="d-flex gap-3 flex-wrap">
              <div className="text-center">
                <div
                  className="d-flex align-items-center justify-content-center bg-success bg-opacity-10 text-success rounded px-3 py-2"
                  style={{ minWidth: "90px" }}
                >
                  <Check size={16} className="me-1" />
                  <span className="fw-bold">{stats.available}</span>
                </div>
                <small
                  className="d-block text-muted mt-1"
                  style={{ fontSize: "0.75rem" }}
                >
                  Available
                </small>
              </div>
              <div className="text-center">
                <div
                  className="d-flex align-items-center justify-content-center bg-danger bg-opacity-10 text-danger rounded px-3 py-2"
                  style={{ minWidth: "90px" }}
                >
                  <X size={16} className="me-1" />
                  <span className="fw-bold">{stats.unavailable}</span>
                </div>
                <small
                  className="d-block text-muted mt-1"
                  style={{ fontSize: "0.75rem" }}
                >
                  Unavailable
                </small>
              </div>
              <div className="text-center">
                <div
                  className="d-flex align-items-center justify-content-center bg-primary bg-opacity-10 text-primary rounded px-3 py-2"
                  style={{ minWidth: "90px" }}
                >
                  <Clock size={16} className="me-1" />
                  <span className="fw-bold">{stats.total}</span>
                </div>
                <small
                  className="d-block text-muted mt-1"
                  style={{ fontSize: "0.75rem" }}
                >
                  Total Days
                </small>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Calendar Grid */}
      <div className="row g-3">
        {monthsDays.map((monthData, monthIndex) => (
          <div key={monthData.month} className="col-12 col-md-6 col-xl-4">
            <div className="card h-100 shadow-sm border">
              {/* Month Header */}
              <div className="card-header bg-white border-bottom d-flex justify-content-between align-items-center py-3">
                <h6 className="mb-0 fw-semibold">{monthData.monthName}</h6>
                <div className="dropdown">
                  <button
                    className="btn btn-sm btn-outline-secondary dropdown-toggle"
                    type="button"
                    data-bs-toggle="dropdown"
                    style={{ fontSize: "0.8rem", padding: "0.25rem 0.75rem" }}
                  >
                    Actions
                  </button>
                  <ul className="dropdown-menu dropdown-menu-end shadow-sm">
                    <li>
                      <button
                        className="dropdown-item d-flex align-items-center"
                        onClick={() => setMonthAvailability(monthIndex, true)}
                        style={{ fontSize: "0.85rem" }}
                      >
                        <Check size={14} className="me-2 text-success" />
                        Mark All Available
                      </button>
                    </li>
                    <li>
                      <button
                        className="dropdown-item d-flex align-items-center"
                        onClick={() => setMonthAvailability(monthIndex, false)}
                        style={{ fontSize: "0.85rem" }}
                      >
                        <X size={14} className="me-2 text-danger" />
                        Mark All Unavailable
                      </button>
                    </li>
                  </ul>
                </div>
              </div>

              {/* Month Days */}
              <div className="card-body p-3">
                {/* Weekdays header */}
                <div className="row g-1 mb-2">
                  {weekDays.map((day) => (
                    <div key={day} className="col">
                      <div className="text-center">
                        <small
                          className="fw-semibold text-secondary"
                          style={{ fontSize: "0.7rem" }}
                        >
                          {day}
                        </small>
                      </div>
                    </div>
                  ))}
                </div>

                {/* Days Grid */}
                <div>
                  {Array.from(
                    { length: Math.ceil(monthData.days.length / 7) },
                    (_, weekIndex) => (
                      <div key={weekIndex} className="row g-1 mb-1">
                        {monthData.days
                          .slice(weekIndex * 7, (weekIndex + 1) * 7)
                          .map((day, dayIndex) => {
                            const actualDayIndex = weekIndex * 7 + dayIndex;
                            return (
                              <div key={dayIndex} className="col">
                                {day ? (
                                  <button
                                    type="button"
                                    onClick={() =>
                                      toggleAvailability(
                                        monthIndex,
                                        actualDayIndex
                                      )
                                    }
                                    disabled={day.isPast}
                                    className={`btn w-100 p-0 border d-flex align-items-center justify-content-center fw-semibold transition-all ${
                                      day.isPast
                                        ? "bg-light text-muted border-light"
                                        : day.available
                                        ? "btn-success border-success"
                                        : "btn-danger border-danger"
                                    } ${
                                      day.isToday
                                        ? "border-3 border-primary"
                                        : ""
                                    }`}
                                    style={{
                                      height: "40px",
                                      width: "100%",
                                      fontSize: "0.85rem",
                                      cursor: day.isPast
                                        ? "not-allowed"
                                        : "pointer",
                                      opacity: day.isPast ? 0.5 : 1,
                                      position: "relative",
                                    }}
                                  >
                                    {day.dayNumber}
                                    {day.isToday && (
                                      <span
                                        className="position-absolute bottom-0 start-50 translate-middle-x"
                                        style={{
                                          width: "4px",
                                          height: "4px",
                                          backgroundColor: "currentColor",
                                          borderRadius: "50%",
                                          marginBottom: "2px",
                                        }}
                                      ></span>
                                    )}
                                  </button>
                                ) : (
                                  <div
                                    style={{ height: "40px", width: "100%" }}
                                  ></div>
                                )}
                              </div>
                            );
                          })}
                      </div>
                    )
                  )}
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default VendorAvailabilityCalendar;
