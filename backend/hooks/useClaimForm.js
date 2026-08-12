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

  const [expandedSections, setExpandedSections] = useState({
    policyholder: true,
    owner: true,
    proof: true,
    additional: true,
    declaration: true,
  });

  const [formData, setFormData] = useState({
    businessName: "",
    registeredAddress: "",
    phoneNumber: "",
    emailAddress: "",
    website: "",
    category: "",
    registrationNumber: "",
    claimantFullName: "",
    claimantRole: "",
    claimantMobile: "",
    claimantEmail: "",
    businessDescription: "",
    facebookLink: "",
    instagramLink: "",
    linkedinLink: "",
    contactMethod: "",
    dateSigned: "",
    agreed: false,
  });

  const [files, setFiles] = useState({
    aadharCard: null,
    panCard: null,
    shopLicense: null,
    udyamCertificate: null,
    gstCertificate: null,
    addressProof: null,
    businessPhoto: null,
    signature: null,
    additionalDocuments: [],
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
      businessDescription: attributes?.about_us?.replace(/<[^>]*>/g, "") || "",
      facebookLink: "",
      instagramLink: "",
      linkedinLink: "",
    }));
  };

  const toggleSection = (section) => {
    setExpandedSections((prev) => ({
      ...prev,
      [section]: !prev[section],
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

    const textFields = [
      "businessName",
      "registeredAddress",
      "claimantFullName",
      "claimantRole",
      "category",
    ];
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

    const phoneFields = ["phoneNumber", "claimantMobile"];
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

  const handleFileChange = (e, fileKey) => {
    const file = e.target.files[0];

    if (file && file.size > 50 * 1024 * 1024) {
      toast.error("File size should not exceed 50MB");
      return;
    }

    if (fileKey === "additionalDocuments") {
      const filesArray = Array.from(e.target.files);
      setFiles((prev) => ({
        ...prev,
        [fileKey]: filesArray,
      }));
    } else if (fileKey === "signature") {
      if (file && !file.type.startsWith("image/")) {
        toast.error("Signature must be an image file");
        return;
      }
      setFiles((prev) => ({
        ...prev,
        [fileKey]: file,
      }));
    } else {
      setFiles((prev) => ({
        ...prev,
        [fileKey]: file,
      }));
    }
  };

  const validateForm = () => {
    const requiredFields = {
      businessName: "Business Name",
      registeredAddress: "Registered Address",
      phoneNumber: "Business Phone Number",
      emailAddress: "Business Email",
      claimantFullName: "Claimant Full Name",
      claimantMobile: "Claimant Mobile Number",
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

    if (formData.claimantMobile.length !== 10) {
      toast.error("Claimant Mobile Number must be exactly 10 digits");
      return false;
    }

    if (!validateEmail(formData.emailAddress)) {
      toast.error("Please enter a valid business email address");
      return false;
    }

    if (formData.claimantEmail && !validateEmail(formData.claimantEmail)) {
      toast.error("Please enter a valid claimant email address");
      return false;
    }

    if (!formData.agreed) {
      toast.error("Please agree to the declaration");
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
      const formDataToSend = new FormData();

      // Append all form fields
      Object.keys(formData).forEach((key) => {
        formDataToSend.append(key, formData[key]);
      });

      // Append vendor IDs if available
      if (vendorData) {
        console.log("Appending vendor IDs:", {
          vendor_id: vendorData.vendor_id,
          vendor_subcategory_data_id: vendorData.id,
        });
        formDataToSend.append("vendor_id", vendorData.vendor_id);
        formDataToSend.append("vendor_subcategory_data_id", vendorData.id);
      } else {
        console.warn("No vendorData available - IDs will not be appended");
      }

      // Append files
      Object.keys(files).forEach((key) => {
        if (files[key]) {
          if (key === "additionalDocuments" && Array.isArray(files[key])) {
            files[key].forEach((file) => {
              formDataToSend.append("additionalDocuments", file);
            });
          } else if (key !== "signature") {
            // Skip signature field as backend doesn't support it yet
            formDataToSend.append(key, files[key]);
          }
        }
      });

      const result = await submitBusinessClaim(formDataToSend);

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
      claimantFullName: "",
      claimantRole: "",
      claimantMobile: "",
      claimantEmail: "",
      businessDescription: "",
      facebookLink: "",
      instagramLink: "",
      linkedinLink: "",
      contactMethod: "",
      dateSigned: "",
      agreed: false,
    });
    setFiles({
      aadharCard: null,
      panCard: null,
      shopLicense: null,
      udyamCertificate: null,
      gstCertificate: null,
      addressProof: null,
      businessPhoto: null,
      signature: null,
      additionalDocuments: [],
    });
  };

  return {
    formData,
    files,
    setFiles,
    expandedSections,
    loading,
    submitting,
    vendorData,
    handleInputChange,
    handleFileChange,
    handleSubmit,
    toggleSection,
    resetForm,
  };
};

export default useClaimForm;
