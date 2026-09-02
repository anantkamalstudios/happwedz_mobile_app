import React from "react";

const LoadingState = ({ title }) => (
  <div className="container my-5">
    <div className="row justify-content-center">
      <div className="col-md-8 text-center">
        <div className="bg-light rounded-4 p-5">
          <div className="mb-4">
            <div className="spinner-border text-primary" role="status">
              <span className="visually-hidden">Loading...</span>
            </div>
          </div>
          <h4 className="text-muted mb-3">Loading...</h4>
          <p className="text-muted mb-4">
            Please wait while we fetch{" "}
            {title ? title.toLowerCase() : "the data"}.
          </p>
        </div>
      </div>
    </div>
  </div>
);

export default LoadingState;
