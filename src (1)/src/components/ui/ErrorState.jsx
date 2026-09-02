import React from "react";
import { FiAlertTriangle, FiRefreshCw } from "react-icons/fi";

const ErrorState = ({
  title = "We couldn’t load the data",
  message = "Something went wrong. Please try again later.",
  onRetry,
  retryLabel = "Retry",
}) => {
  return (
    <div className="container py-5 d-flex justify-content-center">
      <div
        className="text-center p-4 p-md-5 shadow-sm border rounded-4"
        style={{ maxWidth: 480, width: "100%", background: "#fff" }}
      >
        <div
          className="mx-auto d-flex align-items-center justify-content-center rounded-circle mb-3"
          style={{
            width: 64,
            height: 64,
            backgroundColor: "rgba(195,17,98,0.08)",
            color: "#C31162",
          }}
        >
          <FiAlertTriangle size={28} />
        </div>
        <h5 className="fw-bold mb-2">{title}</h5>
        <p className="text-muted mb-4">{message}</p>
        {onRetry && (
          <button
            type="button"
            className="btn btn-outline-primary d-inline-flex align-items-center gap-2 px-4 py-2"
            onClick={onRetry}
          >
            <FiRefreshCw size={18} />
            {retryLabel}
          </button>
        )}
      </div>
    </div>
  );
};

export default ErrorState;
