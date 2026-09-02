import React from "react";
import { Link, useNavigate } from "react-router-dom";

const NotFound = () => {
  const navigate = useNavigate();

  const handleGoBack = () => {
    navigate(-1);
  };

  return (
    <div className="not-found-container">
      <div className="not-found-content text-center">
        <img
          src="/images/notfound.jpg"
          alt="404 Not Found"
          width={500}
          className="img-fluid mx-auto d-block mb-4 not-found-img"
        />
        <h1 className="display-5 fw-bold text-dark mb-3">
          404 - Page Not Found
        </h1>
        <p className="text-muted mb-4">
          Oops! The page you are looking for doesn’t exist or has been moved.
        </p>
        <button onClick={handleGoBack} className="btn btn-primary">
          Go Back
        </button>
      </div>
    </div>
  );
};

export default NotFound;
