// frontend
import React, { useState, useEffect } from "react";
import { useLocation, useParams, useNavigate } from "react-router-dom";
import CardEditor from "./layouts/eInvite/CardEditor";

const CardEditorPage = () => {
  const location = useLocation();
  const params = useParams();
  const navigate = useNavigate();
  const [template, setTemplate] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (location.state?.template) {
      setTemplate(location.state.template);
      setLoading(false);
    } else if (location.search) {
      const urlParams = new URLSearchParams(location.search);
      const templateData = urlParams.get("template");
      if (templateData) {
        try {
          const parsedTemplate = JSON.parse(decodeURIComponent(templateData));
          setTemplate(parsedTemplate);
          setLoading(false);
        } catch (error) {
          console.error("Error parsing template data:", error);
          navigate("/templates");
        }
      }
    } else if (params.templateId) {
      fetchTemplateById(params.templateId);
    } else {
      navigate("/templates");
    }
  }, [location, params, navigate]);

  const fetchTemplateById = async (templateId) => {
    try {
      const mockTemplate = {
        id: templateId,
        name: "Sample Template",
        theme: "traditional",
        image:
          "https://image.wedmegood.com/e-invite-images/5921489f-e0f7-411a-8b19-a85f2c11d2e9-1.JPEG",
        rating: 4.8,
      };

      setTemplate(mockTemplate);
      setLoading(false);
    } catch (error) {
      console.error("Error fetching template:", error);
      navigate("/templates");
    }
  };

  const handleBackToTemplates = () => {
    navigate("/templates");
  };

  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center min-vh-100">
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  if (!template) {
    return (
      <div className="d-flex justify-content-center align-items-center min-vh-100">
        <div className="text-center">
          <h3>Template not found</h3>
          <button
            className="btn btn-primary mt-3"
            onClick={handleBackToTemplates}
          >
            Back to Templates
          </button>
        </div>
      </div>
    );
  }

  return <CardEditor template={template} onBack={handleBackToTemplates} />;
};

export default CardEditorPage;
