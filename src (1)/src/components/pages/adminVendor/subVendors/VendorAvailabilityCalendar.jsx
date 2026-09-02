import React, { useState, useEffect, useRef } from "react";
import dayjs from "dayjs";
import "dayjs/locale/en";
import { Check, X, Zap } from "lucide-react";
import "./VendorAvailability.css";

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
      const isWeekend = [0, 5, 6].includes(date.day()); // Fri (5), Sat (6), Sun (0)
      const isInitiallyAvailable = initialAvailableDates.includes(
        date.format("YYYY-MM-DD")
      );

      days.push({
        date: date,
        available: !isPast && isInitiallyAvailable,
        isToday: isToday,
        isPast: isPast,
        isWeekend: isWeekend,
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
  const [activeTab, setActiveTab] = useState("all");
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

  // Smart action: Open all weekends (Fri, Sat, Sun) for a month or all months
  const openAllWeekends = (targetMonthIndex = null) => {
    const updated = monthsDays.map((m, mIdx) => {
      if (targetMonthIndex !== null && mIdx !== targetMonthIndex) return m;
      return {
        ...m,
        days: m.days.map((day) => {
          if (day && !day.isPast && day.isWeekend) {
            return { ...day, available: true };
          }
          return day;
        }),
      };
    });
    setMonthsDays(updated);
  };

  const weekDays = [
    { name: "Sun", isWeekend: true },
    { name: "Mon", isWeekend: false },
    { name: "Tue", isWeekend: false },
    { name: "Wed", isWeekend: false },
    { name: "Thu", isWeekend: false },
    { name: "Fri", isWeekend: true },
    { name: "Sat", isWeekend: true },
  ];

  // Filter months to display based on active tab
  const displayedMonths =
    activeTab === "all"
      ? monthsDays
      : monthsDays.filter((m) => m.month === Number(activeTab));

  return (
    <div className="vendor-avail-studio">
      {/* Clean Single-Row Top Bar */}
      <div className="avail-clean-topbar">
        <div className="avail-pills-group">
          <span className="avail-pill available">
            <Check size={14} />
            <span>{stats.available} Available</span>
          </span>
          <span className="avail-pill closed">
            <X size={14} />
            <span>{stats.unavailable} Closed</span>
          </span>
        </div>

        <button
          type="button"
          className="avail-action-btn"
          onClick={() =>
            openAllWeekends(
              activeTab === "all"
                ? null
                : monthsDays.findIndex((m) => m.month === Number(activeTab))
            )
          }
          title="Open all Friday, Saturday & Sunday dates"
        >
          <Zap size={14} style={{ color: "#ed1173" }} />
          <span>Open Weekends (Fri - Sun)</span>
        </button>
      </div>

      {/* Month Filter Tabs */}
      <div className="avail-tabs-strip">
        <button
          type="button"
          className={`avail-tab-pill ${activeTab === "all" ? "active" : ""}`}
          onClick={() => setActiveTab("all")}
        >
          <span>All Months</span>
        </button>

        {monthsDays.map((m) => {
          const openInMonth = m.days.filter(
            (d) => d && !d.isPast && d.available
          ).length;
          const isSelected = activeTab === m.month;

          return (
            <button
              key={m.month}
              type="button"
              className={`avail-tab-pill ${isSelected ? "active" : ""}`}
              onClick={() => setActiveTab(m.month)}
            >
              <span>{m.shortName}</span>
              {openInMonth > 0 && (
                <span className="avail-tab-count">{openInMonth}</span>
              )}
            </button>
          );
        })}
      </div>

      {/* Months Calendar Grid */}
      <div
        className={`avail-months-container ${
          activeTab !== "all" ? "single-focus" : ""
        }`}
      >
        {displayedMonths.map((monthData) => {
          const originalMonthIndex = monthsDays.findIndex(
            (m) => m.month === monthData.month
          );
          const availableInMonth = monthData.days.filter(
            (d) => d && !d.isPast && d.available
          ).length;

          return (
            <div key={monthData.month} className="avail-month-card">
              {/* Card Header */}
              <div className="avail-month-header">
                <h6 className="avail-month-name">
                  <span>{monthData.monthName}</span>
                  {availableInMonth > 0 && (
                    <span className="avail-open-counter">
                      {availableInMonth} Open
                    </span>
                  )}
                </h6>

                <div className="dropdown">
                  <button
                    className="btn btn-sm btn-outline-secondary dropdown-toggle py-1 px-2"
                    type="button"
                    data-bs-toggle="dropdown"
                    style={{ fontSize: "0.78rem", borderRadius: "6px" }}
                  >
                    Quick Set
                  </button>
                  <ul className="dropdown-menu dropdown-menu-end shadow-sm">
                    <li>
                      <button
                        className="dropdown-item d-flex align-items-center fs-13 py-1"
                        onClick={() => openAllWeekends(originalMonthIndex)}
                      >
                        <Zap size={14} className="me-2 text-warning" />
                        Open All Weekends
                      </button>
                    </li>
                    <li>
                      <button
                        className="dropdown-item d-flex align-items-center fs-13 py-1"
                        onClick={() =>
                          setMonthAvailability(originalMonthIndex, true)
                        }
                      >
                        <Check size={14} className="me-2 text-success" />
                        Mark Entire Month Open
                      </button>
                    </li>
                    <li>
                      <button
                        className="dropdown-item d-flex align-items-center fs-13 py-1"
                        onClick={() =>
                          setMonthAvailability(originalMonthIndex, false)
                        }
                      >
                        <X size={14} className="me-2 text-danger" />
                        Block Entire Month
                      </button>
                    </li>
                  </ul>
                </div>
              </div>

              {/* Weekdays Row */}
              <div className="avail-weekdays-strip">
                {weekDays.map((day) => (
                  <span
                    key={day.name}
                    className={`avail-weekday-title ${
                      day.isWeekend ? "is-weekend" : ""
                    }`}
                  >
                    {day.name}
                  </span>
                ))}
              </div>

              {/* 7-Column Days Matrix */}
              <div className="avail-days-matrix">
                {monthData.days.map((day, dayIndex) => {
                  if (!day) {
                    return (
                      <div
                        key={`empty-${dayIndex}`}
                        className="avail-empty-cell"
                      ></div>
                    );
                  }

                  return (
                    <button
                      key={`day-${day.dayNumber}`}
                      type="button"
                      onClick={() =>
                        toggleAvailability(originalMonthIndex, dayIndex)
                      }
                      disabled={day.isPast}
                      className={`avail-day-tile ${
                        day.isPast
                          ? "is-past"
                          : day.available
                          ? "is-available"
                          : "is-unavailable"
                      } ${day.isToday ? "is-today" : ""}`}
                      title={
                        day.isPast
                          ? "Past date"
                          : day.available
                          ? `${day.date.format("ddd, D MMM YYYY")} — Open (Click to block)`
                          : `${day.date.format("ddd, D MMM YYYY")} — Closed (Click to open)`
                      }
                    >
                      <span>{day.dayNumber}</span>
                      {day.isToday && <span className="avail-today-dot"></span>}
                    </button>
                  );
                })}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default VendorAvailabilityCalendar;
