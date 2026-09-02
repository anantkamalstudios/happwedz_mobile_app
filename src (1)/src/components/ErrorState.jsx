import React from "react";

const ErrorState = ({ error, onRetry }) => (
  <div className="container-fluid">
    <div className="alert alert-danger" role="alert">
      <h4 className="alert-heading">Error Loading Data</h4>
      <p>{error?.message || error?.toString() || "An unexpected error occurred."}</p>
      <hr />
      <button className="btn btn-outline-danger" onClick={onRetry}>
        Try Again
      </button>
    </div>
  </div>
);

export default ErrorState;
