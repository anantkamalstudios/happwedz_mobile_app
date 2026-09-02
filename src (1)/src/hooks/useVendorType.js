import { useEffect, useState } from "react";
import { fetchVendorTypesWithSubcategoriesApi } from "../services/api/vendorTypesWithSubcategoriesApi";

export const useVendorType = () => {
  const [loading, setLoading] = useState(true);
  const [vendorTypes, setVendorTypes] = useState([]);

  useEffect(() => {
    const loadVendorTypes = async () => {
      const response = await fetchVendorTypesWithSubcategoriesApi();
      setVendorTypes(response);
      setLoading(false);
    };
    loadVendorTypes();
  }, []);

  return {
    vendorTypes,
    loading,
  };
};
