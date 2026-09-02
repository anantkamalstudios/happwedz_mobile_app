import React, { useState } from "react";
import { FaFileDownload, FaSpinner } from "react-icons/fa";
import axiosInstance from "../../services/api/axiosInstance";

export default function InvoiceDownloadButton({
  paymentId,
  invoiceNumber,
  bookingType = "flight",
  className = "btn btn-sm btn-outline-secondary",
  label = "Download Invoice",
}) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleDownload = async () => {
    try {
      setLoading(true);
      setError(null);

      // Construct endpoint based on booking type
      let endpoint;
      if (bookingType === "cabs") {
        endpoint = `/tripjack-cabs/invoice/${paymentId}`;
      } else {
        endpoint = `/${bookingType}_payment/invoice/${paymentId}`;
      }

      const response = await axiosInstance.get(endpoint, {
        responseType: "blob",
      });

      // Create a blob URL and trigger download
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement("a");
      link.href = url;
      link.setAttribute(
        "download",
        `${bookingType.toUpperCase()}_Invoice_${invoiceNumber || paymentId}.pdf`
      );
      document.body.appendChild(link);
      link.click();
      link.parentNode.removeChild(link);
      window.URL.revokeObjectURL(url);
    } catch (err) {
      console.error("Invoice download error:", err);
      setError(err.response?.data?.message || "Failed to download invoice");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="invoice-download-button-wrapper">
      <button
        className={className}
        onClick={handleDownload}
        disabled={loading}
        title={error || "Download invoice PDF"}
      >
        {loading ? (
          <>
            <FaSpinner className="me-2 spinner-border-sm" />
            Downloading...
          </>
        ) : (
          <>
            <FaFileDownload className="me-2" />
            {label}
          </>
        )}
      </button>
      {error && (
        <small className="text-danger d-block mt-1">
          {error}
        </small>
      )}
    </div>
  );
}
