import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import {
  MapPin,
  Building2,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  X,
  Search,
  Users,
} from "lucide-react";
import { fetchHotelCityRegions, searchHotels } from "../../../../services/api/hotelApi";
import { formatDate as fmtDate, formatDateWithWeekday } from "../../../../utils/dateFormat";
import {
  createCorrelationId,
  defaultFilters,
} from "./hotelbedsDetailHelpers";
import "./HotelSearchBar.css";

// Country list with codes
const COUNTRIES = [
  { code: "106", name: "India" },
  { code: "1", name: "Afghanistan" },
  { code: "2", name: "Albania" },
  { code: "3", name: "Algeria" },
  { code: "4", name: "Andorra" },
  { code: "5", name: "Angola" },
  { code: "6", name: "Argentina" },
  { code: "7", name: "Armenia" },
  { code: "8", name: "Aruba" },
  { code: "9", name: "Australia" },
  { code: "10", name: "Austria" },
  { code: "11", name: "Azerbaijan" },
  { code: "12", name: "Bahamas" },
  { code: "13", name: "Bahrain" },
  { code: "14", name: "Bangladesh" },
  { code: "15", name: "Barbados" },
  { code: "16", name: "Belarus" },
  { code: "17", name: "Belgium" },
  { code: "18", name: "Belize" },
  { code: "19", name: "Benin" },
  { code: "20", name: "Bermuda" },
  { code: "21", name: "Bhutan" },
  { code: "22", name: "Bolivia" },
  { code: "23", name: "Bosnia and Herzegovina" },
  { code: "24", name: "Botswana" },
  { code: "25", name: "Brazil" },
  { code: "26", name: "British Virgin Islands" },
  { code: "27", name: "Brunei" },
  { code: "28", name: "Bulgaria" },
  { code: "29", name: "Burkina Faso" },
  { code: "30", name: "Burundi" },
  { code: "31", name: "Cambodia" },
  { code: "32", name: "Cameroon" },
  { code: "33", name: "Canada" },
  { code: "34", name: "Cape Verde" },
  { code: "35", name: "Cayman Islands" },
  { code: "36", name: "Central African Republic" },
  { code: "37", name: "Chad" },
  { code: "38", name: "Chile" },
  { code: "39", name: "China" },
  { code: "40", name: "Colombia" },
  { code: "41", name: "Comoros" },
  { code: "42", name: "Costa Rica" },
  { code: "43", name: "Croatia" },
  { code: "44", name: "Cuba" },
  { code: "45", name: "Cyprus" },
  { code: "46", name: "Czech Republic" },
  { code: "47", name: "Democratic Republic of the Congo" },
  { code: "48", name: "Denmark" },
  { code: "49", name: "Djibouti" },
  { code: "50", name: "Dominica" },
  { code: "51", name: "Dominican Republic" },
  { code: "52", name: "Ecuador" },
  { code: "53", name: "Egypt" },
  { code: "54", name: "El Salvador" },
  { code: "55", name: "Equatorial Guinea" },
  { code: "56", name: "Eritrea" },
  { code: "57", name: "Estonia" },
  { code: "58", name: "Ethiopia" },
  { code: "59", name: "Falkland Islands" },
  { code: "60", name: "Fiji" },
  { code: "61", name: "Finland" },
  { code: "62", name: "France" },
  { code: "63", name: "French Guiana" },
  { code: "64", name: "French Polynesia" },
  { code: "65", name: "Gabon" },
  { code: "66", name: "Gambia" },
  { code: "67", name: "Georgia" },
  { code: "68", name: "Germany" },
  { code: "69", name: "Ghana" },
  { code: "70", name: "Gibraltar" },
  { code: "71", name: "Greece" },
  { code: "72", name: "Greenland" },
  { code: "73", name: "Grenada" },
  { code: "74", name: "Guadeloupe" },
  { code: "75", name: "Guam" },
  { code: "76", name: "Guatemala" },
  { code: "77", name: "Guinea" },
  { code: "78", name: "Guinea-Bissau" },
  { code: "79", name: "Guyana" },
  { code: "80", name: "Haiti" },
  { code: "81", name: "Honduras" },
  { code: "82", name: "Hong Kong" },
  { code: "83", name: "Hungary" },
  { code: "84", name: "Iceland" },
  { code: "85", name: "Indonesia" },
  { code: "86", name: "Iran" },
  { code: "87", name: "Iraq" },
  { code: "88", name: "Ireland" },
  { code: "89", name: "Isle of Man" },
  { code: "90", name: "Israel" },
  { code: "91", name: "Italy" },
  { code: "92", name: "Ivory Coast" },
  { code: "93", name: "Jamaica" },
  { code: "94", name: "Japan" },
  { code: "95", name: "Jersey" },
  { code: "96", name: "Jordan" },
  { code: "97", name: "Kazakhstan" },
  { code: "98", name: "Kenya" },
  { code: "99", name: "Kiribati" },
  { code: "100", name: "Kuwait" },
  { code: "101", name: "Kyrgyzstan" },
  { code: "102", name: "Laos" },
  { code: "103", name: "Latvia" },
  { code: "104", name: "Lebanon" },
  { code: "105", name: "Lesotho" },
  { code: "107", name: "Liberia" },
  { code: "108", name: "Libya" },
  { code: "109", name: "Liechtenstein" },
  { code: "110", name: "Lithuania" },
  { code: "111", name: "Luxembourg" },
  { code: "112", name: "Macau" },
  { code: "113", name: "Macedonia" },
  { code: "114", name: "Madagascar" },
  { code: "115", name: "Malawi" },
  { code: "116", name: "Malaysia" },
  { code: "117", name: "Maldives" },
  { code: "118", name: "Mali" },
  { code: "119", name: "Malta" },
  { code: "120", name: "Marshall Islands" },
  { code: "121", name: "Martinique" },
  { code: "122", name: "Mauritania" },
  { code: "123", name: "Mauritius" },
  { code: "124", name: "Mexico" },
  { code: "125", name: "Micronesia" },
  { code: "126", name: "Moldova" },
  { code: "127", name: "Monaco" },
  { code: "128", name: "Mongolia" },
  { code: "129", name: "Montenegro" },
  { code: "130", name: "Montserrat" },
  { code: "131", name: "Morocco" },
  { code: "132", name: "Mozambique" },
  { code: "133", name: "Namibia" },
  { code: "134", name: "Nepal" },
  { code: "135", name: "Netherlands" },
  { code: "136", name: "New Caledonia" },
  { code: "137", name: "New Zealand" },
  { code: "138", name: "Nicaragua" },
  { code: "139", name: "Niger" },
  { code: "140", name: "Nigeria" },
  { code: "141", name: "North Korea" },
  { code: "142", name: "Norway" },
  { code: "143", name: "Oman" },
  { code: "144", name: "Palestine" },
  { code: "145", name: "Panama" },
  { code: "146", name: "Papua New Guinea" },
  { code: "147", name: "Paraguay" },
  { code: "148", name: "Peru" },
  { code: "149", name: "Philippines" },
  { code: "150", name: "Poland" },
  { code: "151", name: "Portugal" },
  { code: "152", name: "Puerto Rico" },
  { code: "153", name: "Qatar" },
  { code: "154", name: "Republic of the Congo" },
  { code: "155", name: "Romania" },
  { code: "156", name: "Russia" },
  { code: "157", name: "Rwanda" },
  { code: "158", name: "Samoa" },
  { code: "159", name: "San Marino" },
  { code: "160", name: "Saint kitts and Nevis" },
  { code: "161", name: "Sao Tome and Principe" },
  { code: "162", name: "Saudi Arabia" },
  { code: "163", name: "Senegal" },
  { code: "164", name: "Serbia" },
  { code: "165", name: "Seychelles" },
  { code: "166", name: "Sierra Leone" },
  { code: "167", name: "Singapore" },
  { code: "168", name: "Slovakia" },
  { code: "169", name: "Slovenia" },
  { code: "170", name: "Solomon Islands" },
  { code: "171", name: "Somalia" },
  { code: "172", name: "South Africa" },
  { code: "173", name: "South Korea" },
  { code: "174", name: "Spain" },
  { code: "175", name: "Sri Lanka" },
  { code: "176", name: "Sudan" },
  { code: "177", name: "Suriname" },
  { code: "178", name: "Swaziland" },
  { code: "179", name: "Sweden" },
  { code: "180", name: "Switzerland" },
  { code: "181", name: "Syria" },
  { code: "182", name: "Taiwan" },
  { code: "183", name: "Tajikistan" },
  { code: "184", name: "Tanzania" },
  { code: "185", name: "Thailand" },
  { code: "186", name: "Togo" },
  { code: "187", name: "Trinidad and Tobago" },
  { code: "188", name: "Tunisia" },
  { code: "189", name: "Turkey" },
  { code: "190", name: "Turkmenistan" },
  { code: "191", name: "Tuvalu" },
  { code: "192", name: "Uganda" },
  { code: "193", name: "Ukraine" },
  { code: "194", name: "United Arab Emirates" },
  { code: "195", name: "United Kingdom" },
  { code: "196", name: "United States" },
  { code: "197", name: "Uruguay" },
  { code: "198", name: "Uzbekistan" },
  { code: "199", name: "Vanuatu" },
  { code: "200", name: "Venezuela" },
  { code: "201", name: "Vietnam" },
  { code: "202", name: "Wallis and Futuna" },
  { code: "203", name: "Western Sahara" },
  { code: "204", name: "Yemen" },
  { code: "205", name: "Zambia" },
  { code: "206", name: "Zimbabwe" },
];

// Analytics tracking function
const trackAnalyticsEvent = async (eventData) => {
  try {
    await fetch("https://apitest.tripjack.com/xms/v1/analytics/events", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(eventData),
    });
  } catch (error) {
    console.error("Analytics tracking error:", error);
  }
};

// Utility functions
const normalizeHotelSuggestion = (suggestion) => {
  if (!suggestion) return null;

  const rawSearchType =
    suggestion?.searchType ||
    suggestion?.searchRegionType ||
    suggestion?.regionType ||
    suggestion?.type ||
    "CITY";
  const normalizedSearchType = String(rawSearchType || "CITY").toUpperCase();

  const city =
    suggestion?.city ||
    suggestion?.cityId ||
    suggestion?.cId ||
    suggestion?.cid ||
    suggestion?.raw?.city ||
    suggestion?.raw?.cityId ||
    suggestion?.raw?.cId ||
    suggestion?.raw?.cid ||
    suggestion?.regionId ||
    suggestion?.searchRegionId ||
    (normalizedSearchType !== "HOTEL" ? suggestion?.id : "") ||
    "";

  const displayName =
    suggestion?.name ||
    suggestion?.displayName ||
    suggestion?.label ||
    suggestion?.searchRegionName ||
    suggestion?.cityName ||
    suggestion?.keyword ||
    "";

  const rawTjids =
    suggestion?.tjids ||
    suggestion?.hids ||
    suggestion?.hotelIds ||
    suggestion?.tjid ||
    suggestion?.tjHotelId ||
    suggestion?.hotelCode ||
    suggestion?.raw?.tjid ||
    suggestion?.raw?.tjHotelId ||
    suggestion?.raw?.hotelCode ||
    [];
  const tjids = Array.isArray(rawTjids)
    ? rawTjids.map((item) => String(item || "").trim()).filter(Boolean)
    : typeof rawTjids === "string"
      ? rawTjids
          .split(",")
          .map((item) => item.trim())
          .filter(Boolean)
      : rawTjids
        ? [String(rawTjids).trim()].filter(Boolean)
        : [];
  const hid =
    suggestion?.hid ||
    suggestion?.hotelId ||
    suggestion?.hotelid ||
    suggestion?.tjid ||
    suggestion?.tjHotelId ||
    suggestion?.hotelCode ||
    suggestion?.raw?.tjid ||
    suggestion?.raw?.tjHotelId ||
    suggestion?.raw?.hotelCode ||
    "";
  const normalizedHid = String(hid || "").trim();
  const normalizedTjids = tjids.length ? tjids : normalizedHid ? [normalizedHid] : [];
  const rawRegionIds = [
    suggestion?.cityRegionId,
    suggestion?.searchRegionId,
    suggestion?.regionId,
    suggestion?.raw?.cityRegionId,
    suggestion?.raw?.searchRegionId,
    suggestion?.raw?.regionId,
  ]
    .flat()
    .filter(Boolean)
    .map((value) => String(value || "").trim())
    .filter(Boolean);
  const normalizedRegionIds = Array.from(new Set(rawRegionIds));

  return {
    id: String(city || displayName || ""),
    city: String(city || ""),
    searchType: normalizedSearchType,
    searchRegionType: normalizedSearchType,
    searchRegionName: String(displayName || "").trim(),
    displayName: String(displayName || "").trim(),
    tjids: normalizedTjids,
    cityRegionIds: normalizedRegionIds,
    regionIds: normalizedRegionIds,
    hid: normalizedHid,
    raw: suggestion,
  };
};

const extractSuggestionList = (response) => {
  if (Array.isArray(response)) return response;
  if (Array.isArray(response?.suggestions)) return response.suggestions;
  if (Array.isArray(response?.data?.suggestions)) return response.data.suggestions;
  if (Array.isArray(response?.data)) return response.data;

  const fromObject = (value) => {
    if (!value || Array.isArray(value) || typeof value !== "object") return [];
    return Object.values(value).filter(
      (item) =>
        item &&
        typeof item === "object" &&
        (item.displayName || item.name || item.searchRegionName),
    );
  };

  const topLevel = fromObject(response);
  if (topLevel.length) return topLevel;
  return fromObject(response?.data);
};

const buildRoomInfoFromCounts = ({ rooms, adults, children }) => {
  const roomCount = Math.max(1, Number(rooms) || 1);
  let adultsRemaining = Math.max(roomCount, Number(adults) || 1);
  let childrenRemaining = Math.max(0, Number(children) || 0);

  return Array.from({ length: roomCount }, (_, index) => {
    const roomsLeft = roomCount - index;
    const adultsForRoom = Math.max(1, Math.floor(adultsRemaining / roomsLeft));
    adultsRemaining -= adultsForRoom;

    const childrenForRoom = Math.floor(childrenRemaining / roomsLeft);
    childrenRemaining -= childrenForRoom;

    return {
      numberOfAdults: adultsForRoom,
      numberOfChild: childrenForRoom,
      childAge: Array.from({ length: childrenForRoom }, () => 6),
    };
  });
};

const normalizeRoomWithChildAges = (room = {}) => {
  const adults = Math.max(1, Number(room?.adults || room?.numberOfAdults || 1));
  const children = Math.max(0, Number(room?.children || room?.numberOfChild || 0));
  const incomingAges = Array.isArray(room?.childAge)
    ? room.childAge
        .map((age) => Number(age))
        .filter((age) => Number.isFinite(age))
        .map((age) => Math.max(0, Math.min(9, age)))
    : [];
  const childAge = Array.from({ length: children }, (_, index) =>
    Number.isFinite(incomingAges[index]) ? Math.max(1, incomingAges[index]) : 1
  );
  return { adults, children, childAge };
};

const buildRoomInfoFromRooms = (rooms = []) =>
  rooms.map((room) => {
    const normalized = normalizeRoomWithChildAges(room);
    return {
      numberOfAdults: normalized.adults,
      numberOfChild: normalized.children,
      childAge: normalized.childAge,
    };
  });

const parseDateInput = (value) => {
  if (!value) return null;
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value;
  }

  const normalized = String(value).trim();
  const match = normalized.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (match) {
    const [, year, month, day] = match;
    const date = new Date(Number(year), Number(month) - 1, Number(day));
    return Number.isNaN(date.getTime()) ? null : date;
  }

  const fallback = new Date(normalized);
  return Number.isNaN(fallback.getTime()) ? null : fallback;
};

const formatDateForInput = (date) => {
  if (!(date instanceof Date) || Number.isNaN(date.getTime())) return "";
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
};

const formatDateDisplay = (dateString) => {
  if (!dateString) return "Select date";
  const date = parseDateInput(dateString);
  if (!date) return "Select date";
  return formatDateWithWeekday(date);
};

const calculateNights = (checkIn, checkOut) => {
  if (!checkIn || !checkOut) return 1;
  const start = parseDateInput(checkIn);
  const end = parseDateInput(checkOut);
  if (!start || !end) return 1;
  const diff = Math.round((end.getTime() - start.getTime()) / 86400000);
  return diff > 0 ? diff : 1;
};

// Location Autocomplete Component
function LocationAutocomplete({ value, onChange, onSelect, placeholder }) {
  const [isOpen, setIsOpen] = useState(false);
  const [suggestions, setSuggestions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [inputValue, setInputValue] = useState(value || "");
  const dropdownRef = useRef(null);

  useEffect(() => {
    setInputValue(value || "");
  }, [value]);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  useEffect(() => {
    const query = inputValue.trim();
    if (!query || query.length < 3) {
      setSuggestions([]);
      return;
    }

    const timeoutId = setTimeout(async () => {
      try {
        setLoading(true);
        const response = await fetchHotelCityRegions({ keyword: query, limit: 500, countryName: "INDIA" });
        const rawSuggestions = extractSuggestionList(response);
        const normalized = rawSuggestions
          .map((item) => normalizeHotelSuggestion(item))
          .filter((item) => item?.displayName);
        if (import.meta.env.DEV) {
          console.log("[TripJack Suggestions UI]", {
            query,
            rawCount: rawSuggestions.length,
            normalizedCount: normalized.length,
            sample: normalized[0] || null,
          });
        }
        setSuggestions(normalized);
      } catch (error) {
        console.error("Unable to fetch hotel suggestions", error);
        setSuggestions([]);
      } finally {
        setLoading(false);
      }
    }, 300);

    return () => clearTimeout(timeoutId);
  }, [inputValue]);

  const handleInputChange = (e) => {
    const newValue = e.target.value;
    setInputValue(newValue);
    onChange?.(newValue);
    setIsOpen(true);
  };

  const handleSelectSuggestion = (suggestion) => {
    setInputValue(suggestion.displayName);
    onSelect?.(suggestion);
    setIsOpen(false);
  };

  const handleClear = () => {
    setInputValue("");
    onChange?.("");
    setSuggestions([]);
  };

  const getIcon = (type) => {
    return type === "HOTEL" ? <Building2 size={18} /> : <MapPin size={18} />;
  };

  return (
    <div className="tripjack-search-field tripjack-search-field--location" ref={dropdownRef}>
      <div className="tripjack-field-label">
        CITY, AREA OR PROPERTY
        <ChevronDown size={12} />
      </div>
      <input
        type="text"
        className="tripjack-field-input"
        value={inputValue}
        onChange={handleInputChange}
        onFocus={() => setIsOpen(true)}
        placeholder={placeholder || "Search destination"}
      />

      {isOpen && (suggestions.length > 0 || loading) && (
        <div className="tripjack-autocomplete-dropdown">
          <div className="tripjack-autocomplete-list">
            {loading ? (
              <div className="tripjack-autocomplete-loading">Searching...</div>
            ) : (
              suggestions.map((suggestion, index) => (
                <button
                  key={`${suggestion.id}-${index}`}
                  type="button"
                  className="tripjack-autocomplete-item"
                  onClick={() => handleSelectSuggestion(suggestion)}
                >
                  <div className="tripjack-autocomplete-icon">
                    {getIcon(suggestion.searchType)}
                  </div>
                  <div className="tripjack-autocomplete-content">
                    <div className="tripjack-autocomplete-title">
                      {suggestion.displayName}
                    </div>
                    <div className="tripjack-autocomplete-subtitle">
                      {suggestion.searchRegionType}
                    </div>
                  </div>
                </button>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// Date Range Picker Component
function DateRangePicker({ checkIn, checkOut, onCheckInChange, onCheckOutChange, onClose }) {
  const [currentMonth, setCurrentMonth] = useState(new Date());
  const [selectingCheckIn, setSelectingCheckIn] = useState(true);

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const getDaysInMonth = (date) => {
    const year = date.getFullYear();
    const month = date.getMonth();
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const daysInMonth = lastDay.getDate();
    const startingDayOfWeek = firstDay.getDay();

    const days = [];
    
    // Add empty cells for days before the first day of the month
    for (let i = 0; i < startingDayOfWeek; i++) {
      days.push(null);
    }

    // Add all days of the month
    for (let day = 1; day <= daysInMonth; day++) {
      days.push(new Date(year, month, day));
    }

    return days;
  };

  const handleDateClick = (date) => {
    if (!date || date < today) return;

    const dateString = formatDateForInput(date);

    if (selectingCheckIn) {
      onCheckInChange(dateString);
      setSelectingCheckIn(false);
      
      // If check-out is before new check-in, move it to the new check-in
      const currentCheckOut = parseDateInput(checkOut);
      if (currentCheckOut && currentCheckOut <= date) {
        onCheckOutChange(dateString);
      }
    } else {
      if (checkIn && dateString < checkIn) {
        onCheckOutChange(checkIn);
        onClose?.();
        return;
      }
      onCheckOutChange(dateString);
      onClose?.();
    }
  };

  const isDateInRange = (date) => {
    if (!date || !checkIn || !checkOut) return false;
    const checkInDate = parseDateInput(checkIn);
    const checkOutDate = parseDateInput(checkOut);
    if (!checkInDate || !checkOutDate) return false;
    return date > checkInDate && date < checkOutDate;
  };

  const isDateSelected = (date) => {
    if (!date) return false;
    const dateString = formatDateForInput(date);
    return dateString === checkIn || dateString === checkOut;
  };

  const nextMonth = () => {
    setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 1));
  };

  const prevMonth = () => {
    setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1, 1));
  };

  const renderMonth = (monthOffset = 0) => {
    const date = new Date(currentMonth.getFullYear(), currentMonth.getMonth() + monthOffset, 1);
    const days = getDaysInMonth(date);
    const monthName = date.toLocaleDateString("en-US", { month: "long", year: "numeric" });

    return (
      <div className="tripjack-datepicker-month">
        <div className="tripjack-datepicker-header">
          {monthOffset === 0 && (
            <button
              type="button"
              className="tripjack-datepicker-nav"
              onClick={prevMonth}
            >
              <ChevronLeft size={20} />
            </button>
          )}
          <div className="tripjack-datepicker-title">{monthName}</div>
          {monthOffset === 1 && (
            <button
              type="button"
              className="tripjack-datepicker-nav"
              onClick={nextMonth}
            >
              <ChevronRight size={20} />
            </button>
          )}
        </div>

        <div className="tripjack-datepicker-weekdays">
          {["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"].map((day) => (
            <div key={day} className="tripjack-datepicker-weekday">
              {day}
            </div>
          ))}
        </div>

        <div className="tripjack-datepicker-days">
          {days.map((day, index) => {
            if (!day) {
              return <div key={`empty-${index}`} className="tripjack-datepicker-day tripjack-datepicker-day--empty" />;
            }

            const isDisabled = day < today;
            const isSelected = isDateSelected(day);
            const inRange = isDateInRange(day);

            return (
              <button
                key={day.getTime()}
                type="button"
                className={`tripjack-datepicker-day ${
                  isSelected ? "tripjack-datepicker-day--selected" : ""
                } ${inRange ? "tripjack-datepicker-day--in-range" : ""}`}
                onClick={() => handleDateClick(day)}
                disabled={isDisabled}
              >
                {day.getDate()}
              </button>
            );
          })}
        </div>
      </div>
    );
  };

  return (
    <div className="tripjack-datepicker-overlay" onClick={onClose}>
      <div className="tripjack-datepicker-panel" onClick={(e) => e.stopPropagation()}>
        <div className="tripjack-datepicker-months">
          {renderMonth(0)}
          {renderMonth(1)}
        </div>
      </div>
    </div>
  );
}

// Country Dropdown Component
function CountryDropdown({ value, onChange, label, onClose }) {
  const [searchQuery, setSearchQuery] = useState("");
  const dropdownRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        onClose?.();
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [onClose]);

  const filteredCountries = COUNTRIES.filter((country) =>
    country.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const selectedCountry = COUNTRIES.find((c) => c.code === value);

  return (
    <div className="tripjack-country-dropdown" ref={dropdownRef}>
      <div className="tripjack-country-header">
        <div className="tripjack-country-title">{label}</div>
        <button
          type="button"
          className="tripjack-country-close"
          onClick={onClose}
        >
          <X size={16} />
        </button>
      </div>

      <div className="tripjack-country-search">
        <Search size={16} color="#999" />
        <input
          type="text"
          className="tripjack-country-search-input"
          placeholder="Search country..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          autoFocus
        />
      </div>

      <div className="tripjack-country-list">
        {filteredCountries.map((country) => (
          <button
            key={country.code}
            type="button"
            className={`tripjack-country-item ${
              country.code === value ? "tripjack-country-item--selected" : ""
            }`}
            onClick={() => {
              onChange(country.code, country.name);
              onClose?.();
            }}
          >
            <span className="tripjack-country-name">{country.name}</span>
            {country.code === value && (
              <span className="tripjack-country-check">✓</span>
            )}
          </button>
        ))}
      </div>
    </div>
  );
}

// Rooms & Guests Dropdown Component
function RoomsGuestsDropdown({ rooms, onApply, onClose }) {
  const [localRooms, setLocalRooms] = useState(
    Array.isArray(rooms) && rooms.length > 0
      ? rooms.map((room) => normalizeRoomWithChildAges(room))
      : [normalizeRoomWithChildAges({ adults: 1, children: 0, childAge: [] })]
  );
  const dropdownRef = useRef(null);

  useEffect(() => {
    setLocalRooms(
      Array.isArray(rooms) && rooms.length > 0
        ? rooms.map((room) => normalizeRoomWithChildAges(room))
        : [normalizeRoomWithChildAges({ adults: 1, children: 0, childAge: [] })]
    );
  }, [rooms]);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        onClose?.();
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [onClose]);

  const updateRoom = (roomIndex, field, value) => {
    const newRooms = [...localRooms];
    const current = normalizeRoomWithChildAges(newRooms[roomIndex] || {});
    if (field === "children") {
      const nextChildren = Math.max(0, Math.min(4, Number(value) || 0));
      const nextChildAge = Array.from({ length: nextChildren }, (_, index) =>
        Number.isFinite(current.childAge[index]) ? Math.max(1, current.childAge[index]) : 1
      );
      newRooms[roomIndex] = { ...current, children: nextChildren, childAge: nextChildAge };
      setLocalRooms(newRooms);
      return;
    }
    if (field === "childAge") {
      const childIndex = Number(value?.childIndex || 0);
      const age = Math.max(1, Math.min(9, Number(value?.age) || 1));
      const nextChildAge = [...current.childAge];
      nextChildAge[childIndex] = age;
      newRooms[roomIndex] = { ...current, childAge: nextChildAge };
      setLocalRooms(newRooms);
      return;
    }
    newRooms[roomIndex] = { ...current, [field]: value };
    setLocalRooms(newRooms);
  };

  const addRoom = () => {
    if (localRooms.length < 9) {
      setLocalRooms([...localRooms, normalizeRoomWithChildAges({ adults: 1, children: 0, childAge: [] })]);
    }
  };

  const removeRoom = (roomIndex) => {
    setLocalRooms((prev) => (prev.length === 1 ? prev : prev.filter((_, index) => index !== roomIndex)));
  };

  const handleApply = () => {
    onApply(localRooms);
    onClose?.();
  };

  return (
    <div className="tripjack-guests-dropdown" ref={dropdownRef}>
      <div className="tripjack-guests-header">
        <Users size={20} className="tripjack-guests-header-icon" />
        <div className="tripjack-guests-header-title">Rooms & Guests</div>
      </div>

      {localRooms.map((room, roomIndex) => (
        <div key={roomIndex} className="tripjack-guests-room">
          <div className="tripjack-guests-room-header">
            <div className="tripjack-guests-room-title">Room {roomIndex + 1}</div>
            {localRooms.length > 1 && (
              <button
                type="button"
                className="tripjack-guests-remove-room"
                onClick={() => removeRoom(roomIndex)}
              >
                Remove
              </button>
            )}
          </div>

          <div className="tripjack-guests-row">
            <div className="tripjack-guests-label">
              <div className="tripjack-guests-label-main">{room.adults} Adults</div>
            </div>
            <div className="tripjack-guests-counter">
              <button
                type="button"
                className="tripjack-guests-counter-btn"
                onClick={() => updateRoom(roomIndex, "adults", Math.max(1, room.adults - 1))}
                disabled={room.adults <= 1}
              >
                −
              </button>
              <div className="tripjack-guests-counter-value">{room.adults}</div>
              <button
                type="button"
                className="tripjack-guests-counter-btn"
                onClick={() => updateRoom(roomIndex, "adults", Math.min(8, room.adults + 1))}
                disabled={room.adults >= 8}
              >
                +
              </button>
            </div>
          </div>

          <div className="tripjack-guests-row">
            <div className="tripjack-guests-label">
              <div className="tripjack-guests-label-main">Children</div>
              <div className="tripjack-guests-label-sub">0-9 years old</div>
            </div>
            <div className="tripjack-guests-counter">
              <button
                type="button"
                className="tripjack-guests-counter-btn"
                onClick={() => updateRoom(roomIndex, "children", Math.max(0, room.children - 1))}
                disabled={room.children <= 0}
              >
                −
              </button>
              <div className="tripjack-guests-counter-value">{room.children}</div>
              <button
                type="button"
                className="tripjack-guests-counter-btn"
                onClick={() => updateRoom(roomIndex, "children", Math.min(4, room.children + 1))}
                disabled={room.children >= 4}
              >
                +
              </button>
            </div>
          </div>

          {room.children > 0 ? (
            <div className="tripjack-guests-row" style={{ alignItems: "flex-start" }}>
              <div className="tripjack-guests-label">
                <div className="tripjack-guests-label-main">Age of Child</div>
                <div className="tripjack-guests-label-sub">0-9 years old</div>
              </div>
              <div style={{ display: "flex", gap: 8, flexWrap: "wrap", justifyContent: "flex-end" }}>
                {Array.from({ length: room.children }, (_, childIndex) => (
                  <select
                    key={`room-${roomIndex}-child-age-${childIndex}`}
                    value={Number.isFinite(room.childAge?.[childIndex]) ? Math.max(1, room.childAge[childIndex]) : 1}
                    onChange={(event) =>
                      updateRoom(roomIndex, "childAge", {
                        childIndex,
                        age: Number(event.target.value),
                      })
                    }
                    style={{
                      minWidth: 56,
                      height: 32,
                      border: "1px solid #d1d5db",
                      borderRadius: 6,
                      padding: "0 6px",
                      background: "#fff",
                    }}
                  >
                    {Array.from({ length: 9 }, (_, index) => index + 1).map((age) => (
                      <option key={`age-${age}`} value={age}>
                        {age}
                      </option>
                    ))}
                  </select>
                ))}
              </div>
            </div>
          ) : null}
        </div>
      ))}

      <div className="tripjack-guests-footer">
        <button
          type="button"
          className="tripjack-guests-add-room"
          onClick={addRoom}
          disabled={localRooms.length >= 9}
        >
          + Add Room
        </button>
        <button
          type="button"
          className="tripjack-guests-apply"
          onClick={handleApply}
        >
          Apply
        </button>
      </div>
    </div>
  );
}

// Main Hotel Search Bar Component
export default function HotelSearchBar({ payload, suggestion, onSearch, editable = true }) {
  const navigate = useNavigate();
  
  // Extract initial values from payload
  const roomInfo = payload?.searchQuery?.roomInfo || [];
  const initialRooms = roomInfo.map(room => ({
    adults: room.numberOfAdults || 1,
    children: room.numberOfChild || 0,
    childAge: Array.isArray(room.childAge) ? room.childAge : [],
  }));

  const currentSuggestion = normalizeHotelSuggestion(suggestion) || normalizeHotelSuggestion({
    city: payload?.searchQuery?.searchCriteria?.city,
    tjids: payload?.searchQuery?.searchCriteria?.tjids,
    cityRegionIds: payload?.searchQuery?.searchCriteria?.cityRegionIds,
    regionIds: payload?.searchQuery?.searchCriteria?.regionIds,
    searchRegionName:
      payload?.searchQuery?.searchCriteria?.searchRegionName ||
      payload?.searchQuery?.searchCriteria?.city ||
      payload?.searchQuery?.searchCriteria?.regionIds?.[0] ||
      "",
    searchRegionType:
      payload?.searchQuery?.searchCriteria?.searchRegionType ||
      "CITY",
  });

  const [destinationQuery, setDestinationQuery] = useState(currentSuggestion?.displayName || "");
  const [selectedDestination, setSelectedDestination] = useState(currentSuggestion);
  const [checkInDate, setCheckInDate] = useState(payload?.searchQuery?.checkinDate || "");
  const [checkOutDate, setCheckOutDate] = useState(payload?.searchQuery?.checkoutDate || "");
  const [rooms, setRooms] = useState(
    initialRooms.length > 0
      ? initialRooms.map((room) => normalizeRoomWithChildAges(room))
      : [normalizeRoomWithChildAges({ adults: 1, children: 0, childAge: [] })]
  );
  const [nationality, setNationality] = useState(payload?.searchQuery?.searchCriteria?.nationality || "106");
  const [countryOfResidence, setCountryOfResidence] = useState(payload?.searchQuery?.searchCriteria?.countryOfResidence || "106");
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showGuestsDropdown, setShowGuestsDropdown] = useState(false);
  const [showMoreOptions, setShowMoreOptions] = useState(false);
  const [showNationalityDropdown, setShowNationalityDropdown] = useState(false);
  const [showResidenceDropdown, setShowResidenceDropdown] = useState(false);
  const [searching, setSearching] = useState(false);

  useEffect(() => {
    if (checkInDate && checkOutDate && checkOutDate < checkInDate) {
      setCheckOutDate(checkInDate);
    }
  }, [checkInDate, checkOutDate]);

  const nights = calculateNights(checkInDate, checkOutDate);
  const totalRooms = rooms.length;
  const totalAdults = rooms.reduce((sum, room) => sum + room.adults, 0);
  const totalChildren = rooms.reduce(
    (sum, room) => sum + Math.max(Number(room.children || room.childAge?.length || 0), 0),
    0
  );

  const nationalityName = COUNTRIES.find(c => c.code === nationality)?.name || "India";
  const residenceName = COUNTRIES.find(c => c.code === countryOfResidence)?.name || "India";

  // Track more options click
  const handleMoreOptionsClick = () => {
    const newValue = !showMoreOptions;
    setShowMoreOptions(newValue);

    // Track analytics
    trackAnalyticsEvent({
      event: "more_options_click",
      properties: {
        old_value: String(!newValue),
        new_value: String(newValue),
        Agent_Id: "313144", // You may want to get this from user context
        User_Role: "AGENT",
        Current_Page: window.location.href,
        Current_Path: window.location.pathname,
        Date: fmtDate(new Date()),
        Previous_Page: document.referrer || "",
        Previous_Path: new URL(document.referrer || window.location.href).pathname,
        Product: "HOTEL",
        TimeStamp: new Date().toISOString(),
        User_Email: "", // You may want to get this from user context
      },
    });
  };

  // Handle nationality change
  const handleNationalityChange = (code, name) => {
    setNationality(code);
    // You can add analytics tracking here if needed
  };

  // Handle residence change
  const handleResidenceChange = (code, name) => {
    setCountryOfResidence(code);
    // You can add analytics tracking here if needed
  };

  const handleCheckInDateChange = (value) => {
    setCheckInDate(value);
    if (value && checkOutDate && checkOutDate < value) {
      setCheckOutDate(value);
    }
  };

  const handleCheckOutDateChange = (value) => {
    if (checkInDate && value && value < checkInDate) {
      setCheckOutDate(checkInDate);
      return;
    }
    setCheckOutDate(value);
  };

  const handleSearch = async () => {
    const selectedHotelIds = Array.isArray(selectedDestination?.tjids)
      ? selectedDestination.tjids.map((item) => String(item || "").trim()).filter(Boolean)
      : [];
    const selectedHid = String(
      selectedDestination?.hid ||
        selectedDestination?.raw?.hid ||
        selectedDestination?.raw?.tjid ||
        selectedDestination?.raw?.tjHotelId ||
        selectedDestination?.raw?.hotelCode ||
        ""
    ).trim();
    const hasSelectedHotelIds = selectedHotelIds.length > 0 || Boolean(selectedHid);
    const hasDestinationCity = Boolean(
      selectedDestination?.city ||
      selectedDestination?.raw?.city ||
      selectedDestination?.raw?.cityId ||
      selectedDestination?.raw?.cId
    );

    if ((!hasDestinationCity && !hasSelectedHotelIds) || !selectedDestination?.displayName) {
      toast.error("Please select a destination from the suggestions.");
      return;
    }

    if (!checkInDate || !checkOutDate) {
      toast.error("Please select check-in and check-out dates.");
      return;
    }

    const fallbackCity =
      selectedDestination?.city ||
      selectedDestination?.raw?.city ||
      selectedDestination?.raw?.cityId ||
      selectedDestination?.raw?.cId ||
      selectedDestination?.displayName ||
      payload?.searchQuery?.searchCriteria?.city ||
      "";
    const normalizedTjids = selectedHotelIds;
    const normalizedHid = selectedHid;
    const effectiveTjids = normalizedTjids.length
      ? normalizedTjids
      : normalizedHid
        ? [normalizedHid]
        : [];
    const fallbackRegionIds = [
      ...(Array.isArray(selectedDestination?.cityRegionIds) ? selectedDestination.cityRegionIds : []),
      ...(Array.isArray(selectedDestination?.regionIds) ? selectedDestination.regionIds : []),
      ...(Array.isArray(payload?.searchQuery?.searchCriteria?.cityRegionIds) ? payload.searchQuery.searchCriteria.cityRegionIds : []),
      ...(Array.isArray(payload?.searchQuery?.searchCriteria?.regionIds) ? payload.searchQuery.searchCriteria.regionIds : []),
      selectedDestination?.raw?.cityRegionId,
      selectedDestination?.raw?.searchRegionId,
      selectedDestination?.raw?.regionId,
    ];
    const effectiveRegionIds = Array.from(
      new Set(
        fallbackRegionIds
          .flat()
          .map((item) => String(item || "").trim())
          .filter((value) => /^[0-9]+$/.test(value)),
      ),
    );
    const effectiveCity = String(fallbackCity || "").trim();
    const effectiveResolverRegionIds = effectiveRegionIds.length > 0 ? effectiveRegionIds : [];

    const nextPayload = {
      searchQuery: {
        checkinDate: checkInDate,
        checkoutDate: checkOutDate,
        roomInfo: buildRoomInfoFromRooms(rooms),
        searchCriteria: {
          city: String(
            effectiveCity ||
              selectedDestination?.city ||
              selectedDestination?.raw?.city ||
              selectedDestination?.displayName ||
              selectedDestination?.id ||
              "",
          ).trim(),
          tjids: effectiveTjids,
          cityRegionIds: effectiveResolverRegionIds,
          regionIds: effectiveResolverRegionIds,
          nationality: nationality,
          countryOfResidence: countryOfResidence,
          // Backend expects `countryName` as a string (ex: "INDIA")
          countryName:
            (COUNTRIES.find((c) => c.code === countryOfResidence)?.name || "India").toUpperCase(),
          currency: payload?.searchQuery?.searchCriteria?.currency || "INR",
          searchRegionName:
            selectedDestination?.searchRegionName ||
            selectedDestination?.displayName ||
            selectedDestination?.id ||
            "",
          searchRegionType:
            selectedDestination?.searchRegionType ||
            selectedDestination?.searchType ||
            "CITY",
        },
        searchType: selectedDestination.searchType || "CITY",
        gstApplied: Boolean(payload?.searchQuery?.gstApplied),
      },
      allOptions: true,
      appliedFilters: {
        ...defaultFilters(),
        onlyFavorites: false,
        hotelName: "",
      },
      pagination: {
        pageSize: 15,
        lastHotelId: "",
      },
      searchId: "",
      correlationId: createCorrelationId(),
      filterType: "BOTH",
      sortOrder: "popularity",
    };

    try {
      setSearching(true);
      const response = await searchHotels(nextPayload);
      
      if (onSearch) {
        onSearch(nextPayload, response, selectedDestination);
      } else {
        navigate("/hotels", {
          state: {
            hotelSearchPayload: nextPayload,
            hotelSearchResponse: response,
            selectedHotelSuggestion: selectedDestination,
          },
        });
      }
    } catch (error) {
      console.error("Unable to refresh hotel search", error);
      const backendError =
        error?.response?.data?.error ||
        error?.response?.data?.message ||
        error?.message ||
        "Unable to refresh hotels right now. Please try again.";
      toast.error(backendError);
    } finally {
      setSearching(false);
    }
  };

  if (!editable) {
    // Read-only view
    return (
      <div className="tripjack-search-container">
        <div className="tripjack-search-wrapper">
          <div className="tripjack-search-bar">
            <div className="tripjack-search-field tripjack-search-field--location">
              <div className="tripjack-field-label">CITY, AREA OR PROPERTY</div>
              <div className="tripjack-field-value">
                {selectedDestination?.displayName || "Destination"}
              </div>
            </div>

            <div className="tripjack-search-field tripjack-search-field--date">
              <div className="tripjack-field-label">CHECK-IN</div>
              <div className="tripjack-field-value">{formatDateDisplay(checkInDate)}</div>
            </div>

            <div className="tripjack-night-badge">{nights}N</div>

            <div className="tripjack-search-field tripjack-search-field--date">
              <div className="tripjack-field-label">CHECK-OUT</div>
              <div className="tripjack-field-value">{formatDateDisplay(checkOutDate)}</div>
            </div>

            <div className="tripjack-search-field tripjack-search-field--guests">
              <div className="tripjack-field-label">ROOMS & GUESTS</div>
              <div className="tripjack-field-value">
                {totalRooms} Room{totalRooms > 1 ? "s" : ""} {totalAdults} Adult{totalAdults > 1 ? "s" : ""}
              </div>
            </div>

            <button
              type="button"
              className="tripjack-search-button"
              onClick={handleSearch}
              disabled={searching}
            >
              {searching ? "Searching..." : "Search"}
            </button>
          </div>

          <div className="tripjack-more-options">
            <button
              type="button"
              className="tripjack-more-options-link"
              onClick={handleMoreOptionsClick}
            >
              More options ›
            </button>
            {showMoreOptions && (
              <div className="tripjack-more-options-meta">
                <div className="tripjack-more-options-item">
                  Nationality :{" "}
                  <button
                    type="button"
                    className="tripjack-more-options-value"
                    onClick={() => setShowNationalityDropdown(true)}
                  >
                    {nationalityName} <ChevronDown size={12} />
                  </button>
                  {showNationalityDropdown && (
                    <CountryDropdown
                      value={nationality}
                      onChange={handleNationalityChange}
                      label="Select Nationality"
                      onClose={() => setShowNationalityDropdown(false)}
                    />
                  )}
                </div>
                <div className="tripjack-more-options-item">
                  Country of Residence :{" "}
                  <button
                    type="button"
                    className="tripjack-more-options-value"
                    onClick={() => setShowResidenceDropdown(true)}
                  >
                    {residenceName} <ChevronDown size={12} />
                  </button>
                  {showResidenceDropdown && (
                    <CountryDropdown
                      value={countryOfResidence}
                      onChange={handleResidenceChange}
                      label="Select Country of Residence"
                      onClose={() => setShowResidenceDropdown(false)}
                    />
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    );
  }

  // Editable view
  return (
    <div className="tripjack-search-container">
      <div className="tripjack-search-wrapper">
        <div className="tripjack-search-bar">
          <LocationAutocomplete
            value={destinationQuery}
            onChange={setDestinationQuery}
            onSelect={(suggestion) => {
              setSelectedDestination(suggestion);
              setDestinationQuery(suggestion.displayName);
            }}
            placeholder="Search destination"
          />

          <div
            className="tripjack-search-field tripjack-search-field--date"
            onClick={() => setShowDatePicker(true)}
          >
            <div className="tripjack-field-label">
              CHECK-IN
              <ChevronDown size={12} />
            </div>
            <div className="tripjack-field-value">{formatDateDisplay(checkInDate)}</div>
          </div>

          <div className="tripjack-night-badge">{nights}N</div>

          <div
            className="tripjack-search-field tripjack-search-field--date"
            onClick={() => setShowDatePicker(true)}
          >
            <div className="tripjack-field-label">
              CHECK-OUT
              <ChevronDown size={12} />
            </div>
            <div className="tripjack-field-value">{formatDateDisplay(checkOutDate)}</div>
          </div>

          <div
            className="tripjack-search-field tripjack-search-field--guests"
            onClick={() => setShowGuestsDropdown(true)}
          >
            <div className="tripjack-field-label">
              ROOMS & GUESTS
              <ChevronDown size={12} />
            </div>
            <div className="tripjack-field-value">
              {totalRooms} Room{totalRooms > 1 ? "s" : ""} {totalAdults} Adult{totalAdults > 1 ? "s" : ""}
            </div>
          </div>

          <button
            type="button"
            className="tripjack-search-button"
            onClick={handleSearch}
            disabled={searching}
          >
            {searching ? "Searching..." : "Search"}
          </button>

          {showGuestsDropdown && (
            <RoomsGuestsDropdown
              rooms={rooms}
              onApply={setRooms}
              onClose={() => setShowGuestsDropdown(false)}
            />
          )}
        </div>

        <div className="tripjack-more-options">
          <button
            type="button"
            className="tripjack-more-options-link"
            onClick={handleMoreOptionsClick}
          >
            More options ›
          </button>
          {showMoreOptions && (
            <div className="tripjack-more-options-meta">
              <div className="tripjack-more-options-item">
                Nationality :{" "}
                <button
                  type="button"
                  className="tripjack-more-options-value"
                  onClick={() => setShowNationalityDropdown(true)}
                >
                  {nationalityName} <ChevronDown size={12} />
                </button>
                {showNationalityDropdown && (
                  <CountryDropdown
                    value={nationality}
                    onChange={handleNationalityChange}
                    label="Select Nationality"
                    onClose={() => setShowNationalityDropdown(false)}
                  />
                )}
              </div>
              <div className="tripjack-more-options-item">
                Country of Residence :{" "}
                <button
                  type="button"
                  className="tripjack-more-options-value"
                  onClick={() => setShowResidenceDropdown(true)}
                >
                  {residenceName} <ChevronDown size={12} />
                </button>
                {showResidenceDropdown && (
                  <CountryDropdown
                    value={countryOfResidence}
                    onChange={handleResidenceChange}
                    label="Select Country of Residence"
                    onClose={() => setShowResidenceDropdown(false)}
                  />
                )}
              </div>
            </div>
          )}
        </div>
      </div>

      {showDatePicker && (
        <DateRangePicker
          checkIn={checkInDate}
          checkOut={checkOutDate}
          onCheckInChange={handleCheckInDateChange}
          onCheckOutChange={handleCheckOutDateChange}
          onClose={() => setShowDatePicker(false)}
        />
      )}
    </div>
  );
}
