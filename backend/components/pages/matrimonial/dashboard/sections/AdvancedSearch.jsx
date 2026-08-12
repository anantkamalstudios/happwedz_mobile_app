import React, { useState } from "react";
import Search from "../../Search";

const AdvancedSearch = ({ onApply }) => {
  const [filters, setFilters] = useState({
    ageFrom: 21,
    ageTo: 35,
    location: "",
    education: "",
    profession: "",
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFilters((prev) => ({ ...prev, [name]: value }));
  };

  const apply = () => onApply?.(filters);

  return (
    <div className="matrimonial-dashboard__section">
      <Search />
    </div>
  );
};

export default AdvancedSearch;
