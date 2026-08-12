import { useState, useEffect } from "react";
import axios from "axios";

export const useFaqFrontend = (navbarId = null) => {
  const [faqs, setFaqs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const loadFaqs = async () => {
    try {
      setLoading(true);
      setError(null);
      setLoading(true);
      const response = await axios.get("https://happywedz.com/api/faq");
      let data = response.data.faqs || [];

      if (navbarId) {
        data = data.filter((faq) => faq.navbarId === parseInt(navbarId));
      }

      setFaqs(data);
      setError(null);
    } catch (err) {
      console.error("Error fetching FAQs:", err);
      setError(err.message);
      setFaqs([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadFaqs();
  }, [navbarId]);

  return {
    faqs,
    loading,
    error,
    refetch: loadFaqs,
  };
};
