import { useState } from "react";
import axiosInstance from "../services/api/axiosInstance";

export const useContact = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const submitContact = async (formData) => {
    try {
      setLoading(true);
      setError(null);

      const response = await axiosInstance.post("/contact", {
        firstName: formData.firstName,
        lastName: formData.lastName,
        email: formData.email,
        phone: formData.phone,
        message: formData.message,
      });

      return response.data;
    } catch (err) {
      const errorMessage =
        err.response?.data?.message ||
        err.message ||
        "Failed to submit contact form";
      setError(errorMessage);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return {
    submitContact,
    loading,
    error,
  };
};

