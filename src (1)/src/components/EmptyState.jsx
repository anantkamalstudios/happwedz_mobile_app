import React from "react";
import { Link } from "react-router-dom";

const EmptyState = ({ section, title }) => {
  const getSuggestions = (section) => {
    switch (section) {
      case "venues":
        return [
          "Banquet Halls",
          "Wedding Resorts",
          "Marriage Garden / Lawns",
          "Destination Wedding Venues",
        ];
      case "vendors":
        return [
          "Wedding Photographers",
          "Wedding Videography",
          "Caterers",
          "Wedding Planners",
        ];
      default:
        return [];
    }
  };

  const suggestions = getSuggestions(section);

  return (
    <div className="container my-5">
      <div className="row justify-content-center">
        <div className="col-md-8 text-center">
          <div className="bg-light rounded-4 p-5">
            <div className="mb-4">
              <img src="/logo-no-bg.png" alt="" />
            </div>
            <h4 className="text-muted mb-3">No {title} Available</h4>

            {suggestions.length > 0 && (
              <div className="mb-4">
                <h6 className="text-muted mb-3">
                  We couldn't find any {title.toLowerCase()} in our database at
                  the moment. Please try searching for a different category or
                  location.
                </h6>
                <div className="d-flex flex-wrap justify-content-center gap-2">
                  {suggestions.map((suggestion) => (
                    <Link
                      key={suggestion}
                      to={`/${section}/${suggestion
                        .toLowerCase()
                        .replace(/\s+/g, "-")
                        .replace(/[^a-z0-9-]/g, "")}`}
                      className="btn btn-outline-secondary btn-sm"
                    >
                      {suggestion}
                    </Link>
                  ))}
                </div>
              </div>
            )}

            <div className="d-flex flex-wrap justify-content-center gap-3">
              <button
                className="btn btn-outline-primary"
                onClick={() => window.history.back()}
              >
                <i className="bi bi-arrow-left me-2"></i>
                Go Back
              </button>
              <Link to="/" className="btn btn-primary">
                <i className="bi bi-house me-2"></i>
                Browse All
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EmptyState;
