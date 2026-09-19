import { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import { toast } from "react-toastify";
import {
  submitBusinessClaim,
  fetchVendorServiceDetails,
} from "../services/api/claimFormApi";

const validateEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

const validateText = (value) => {
  return value === "" || /^[a-zA-Z\s.,'-]*$/.test(value);
};

const validateNumber = (value) => {
  return value === "" || /^\d*$/.test(value);
};

const useClaimForm = (vendorServiceId = null) => {
  const { user, userToken: token } = useSelector((state) => state.auth);


  // Only Business Information survives the form trim. Claimant details, social links,
  // the contact-method field and the declaration block are no longer collected here.
  const [formData, setFormData] = useState({
    businessName: "",
    registeredAddress: "",
    phoneNumber: "",
    emailAddress: "",
    website: "",
    category: "",
    registrationNumber: "",
  });


  const [vendorData, setVendorData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (vendorServiceId) {
      fetchVendorDetails();
    }
  }, [vendorServiceId]);

  const fetchVendorDetails = async () => {
    setLoading(true);
    const result = await fetchVendorServiceDetails(vendorServiceId);
    if (result.success) {
      console.log("Vendor details fetched:", {
        id: result.data.id,
        vendor_id: result.data.vendor_id,
        vendor_name: result.data.attributes?.vendor_name,
      });
      setVendorData(result.data);
      prefillFormData(result.data);
    } else {
      toast.error(result.error || "Failed to load vendor details");
    }
    setLoading(false);
  };

  const prefillFormData = (data) => {
    if (!data) return;

    const vendor = data.vendor;
    const attributes = data.attributes;

    setFormData((prev) => ({
      ...prev,
      businessName: attributes?.vendor_name || vendor?.businessName || "",
      registeredAddress: attributes?.location?.address || "",
      phoneNumber: vendor?.phone || "",
      emailAddress: vendor?.email || attributes?.email || "",
      website: attributes?.cta_url || "",
      category: vendor?.vendorType?.name || attributes?.vendor_type || "",
      registrationNumber: prev.registrationNumber || "",
    }));
  };


  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;

    if (type === "checkbox") {
      setFormData((prev) => ({
        ...prev,
        [name]: checked,
      }));
      return;
    }

    let isValid = true;
    let errorMessage = "";

    const textFields = ["businessName", "registeredAddress", "category"];
    if (textFields.includes(name)) {
      isValid = validateText(value);
      if (!isValid) {
        errorMessage = "This field should only contain letters";
      }
    }

    const numberFields = ["registrationNumber"];
    if (numberFields.includes(name)) {
      isValid = validateNumber(value);
      if (!isValid) {
        errorMessage = "This field should only contain numbers";
      }
    }

    const phoneFields = ["phoneNumber"];
    if (phoneFields.includes(name)) {
      isValid = validateNumber(value) && value.length <= 10;
      if (!isValid) {
        errorMessage = "Please enter a valid 10-digit number";
      }
    }

    if (isValid || value === "") {
      setFormData((prev) => ({
        ...prev,
        [name]: value,
      }));
    } else if (errorMessage) {
      toast.error(errorMessage);
    }
  };

  const validateForm = () => {
    const requiredFields = {
      businessName: "Business Name",
      registeredAddress: "Registered Address",
      phoneNumber: "Business Phone Number",
      emailAddress: "Business Email",
      category: "Business Category",
    };

    for (const [field, label] of Object.entries(requiredFields)) {
      if (!formData[field] || formData[field].trim() === "") {
        toast.error(`${label} is required`);
        return false;
      }
    }

    if (formData.phoneNumber.length !== 10) {
      toast.error("Business Phone Number must be exactly 10 digits");
      return false;
    }

    if (!validateEmail(formData.emailAddress)) {
      toast.error("Please enter a valid business email address");
      return false;
    }

    return true;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    setSubmitting(true);

    try {
      // Plain JSON now that there are no files to carry.
      const payload = {
        ...formData,
        vendor_id: vendorData?.vendor_id,
        vendor_subcategory_data_id: vendorData?.id,
      };

      if (!vendorData) {
        toast.error("We could not identify this business. Please reopen the form.");
        return { success: false, error: "Missing vendor context" };
      }

      const result = await submitBusinessClaim(payload);

      if (result.success) {
        toast.success("Claim form submitted successfully!");
        resetForm();
        return { success: true, data: result.data };
      } else {
        toast.error(result.error || "Failed to submit form");
        return { success: false, error: result.error };
      }
    } catch (error) {
      console.error("Error submitting form:", error);
      toast.error("An error occurred. Please try again.");
      return { success: false, error: error.message };
    } finally {
      setSubmitting(false);
    }
  };

  const resetForm = () => {
    setFormData({
      businessName: "",
      registeredAddress: "",
      phoneNumber: "",
      emailAddress: "",
      website: "",
      category: "",
      registrationNumber: "",
    });
  };

  return {
    formData,
    loading,
    submitting,
    vendorData,
    handleInputChange,
    handleSubmit,
    resetForm,
  };
};

export default useClaimForm;
