import React, { useState } from "react";
import { IoClose } from "react-icons/io5";

const EinviteFilterBar = ({ onSearch, onFilterChange, categories = [] }) => {
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("all");
  const [selectedTheme, setSelectedTheme] = useState("all");

  const handleSearchChange = (e) => {
    const value = e.target.value;
    setSearchTerm(value);
    onSearch(value);
  };

  const handleCategoryChange = (e) => {
    const value = e.target.value;
    setSelectedCategory(value);
    onFilterChange({ category: value, theme: selectedTheme });
  };

  const handleThemeChange = (e) => {
    const value = e.target.value;
    setSelectedTheme(value);
    onFilterChange({ category: selectedCategory, theme: value });
  };

  const clearFilters = () => {
    setSearchTerm("");
    setSelectedCategory("all");
    setSelectedTheme("all");
    onSearch("");
    onFilterChange({ category: "all", theme: "all" });
  };

  return (
    <div className="einvite-filter-bar bg-light py-4">
      <div className="container">
        <div className="row align-items-center">
          <div className="col-md-6 mb-3 mb-md-0">
            <div className="input-group">
              <span className="input-group-text">
                <i className="fas fa-search"></i>
              </span>
              <input
                type="text"
                className="form-control"
                placeholder="Search cards..."
                value={searchTerm}
                onChange={handleSearchChange}
              />
            </div>
          </div>

          {/* <div className="col-md-3 mb-3 mb-md-0">
                        <select
                            className="form-select"
                            value={selectedCategory}
                            onChange={handleCategoryChange}
                        >
                            <option value="all">All Categories</option>
                            {categories.map((category, index) => (
                                <option key={index} value={category.value}>
                                    {category.label}
                                </option>
                            ))}
                        </select>
                    </div> */}

          {/* <div className="col-md-4 mb-3 mb-md-0">
                        <select
                            className="form-select"
                            value={selectedTheme}
                            onChange={handleThemeChange}
                        >
                            <option value="all">All Themes</option>
                            <option value="traditional">Traditional</option>
                            <option value="modern">Modern</option>
                            <option value="vintage">Vintage</option>
                            <option value="floral">Floral</option>
                        </select>
                    </div> */}

          <div className="col-md-2 text-center">
            <button className="btn btn-primary w-100" onClick={clearFilters}>
              <IoClose className="me-2" size={20} />
              Clear
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EinviteFilterBar;
