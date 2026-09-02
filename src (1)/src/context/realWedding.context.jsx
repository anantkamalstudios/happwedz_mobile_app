import { createContext, useContext, useState, useEffect, useMemo } from "react";
import axios from "axios";
import { API_BASE_URL } from "../config/constants";

const FilterContext = createContext();

export const FilterProvider = ({ children }) => {
  const [searchTerm, setSearchTerm] = useState("");
  const [selectCity, setSelectCity] = useState("All Cities");
  const [selectedCulture, setSelectedCulture] = useState("All Cultures");
  const [selectedTheme, setSelectedTheme] = useState("All Themes");

  const [cities, setCities] = useState([]);
  const [cultures, setCultures] = useState([]);

  const themes = [
    "Destination",
    "Grand & Luxurious",
    "Pocket Friendly Stunners",
    "Intimate & Minimalist",
    "Modern & Stylish",
    "International",
    "Classic",
    "Others",
  ];

  const fetchCities = useMemo(
    () => async () => {
      try {
        if (cities.length === 0) {
          const res = await axios.post(
            "https://countriesnow.space/api/v0.1/countries/cities",
            { country: "India" }
          );

          if (res.data?.data) {
            const sorted = res.data.data.sort((a, b) => a.localeCompare(b));
            setCities(sorted);
          }
        }
      } catch (err) {
        console.error("Error fetching cities:", err);
      }
    },
    [cities.length]
  );

  useEffect(() => {
    fetchCities();
  }, [fetchCities]);

  useEffect(() => {
    const fetchCultures = async () => {
      try {
        const cleanBaseUrl = API_BASE_URL.replace(/\/api$/, "");
        const res = await axios
          .get(`${API_BASE_URL}/real-wedding-culture/public`)
          .catch(() => axios.get(`${cleanBaseUrl}/real-wedding-culture/public`));
        if (res?.data?.cultures) {
          setCultures(res.data.cultures);
        }
      } catch (err) {
        console.warn("Notice: wedding cultures data not available:", err.message);
      }
    };
    fetchCultures();
  }, []);

  const clearFilters = () => {
    setSearchTerm("");
    setSelectCity("All Cities");
    setSelectedCulture("All Cultures");
    setSelectedTheme("All Themes");
  };

  return (
    <FilterContext.Provider
      value={{
        searchTerm,
        setSearchTerm,

        selectCity,
        setSelectCity,

        selectedCulture,
        setSelectedCulture,

        selectedTheme,
        setSelectedTheme,

        cities,
        cultures,
        themes,

        clearFilters,
      }}
    >
      {children}
    </FilterContext.Provider>
  );
};

export const useFilter = () => useContext(FilterContext);
