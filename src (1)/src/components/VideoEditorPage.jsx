import React, { useState, useEffect } from "react";
import { useLocation, useParams, useNavigate } from "react-router-dom";
import VideoEditor from "./layouts/eInvite/VideoEditor";
import VideoPreview from "./layouts/eInvite/VideoPreview";
import Swal from "sweetalert2";

const VideoEditorPage = () => {
  const location = useLocation();
  const params = useParams();
  const navigate = useNavigate();
  const [template, setTemplate] = useState(null);
  const [loading, setLoading] = useState(true);
  const [currentView, setCurrentView] = useState("editor"); // editor, preview
  const [videoData, setVideoData] = useState(null);
  const [isExporting, setIsExporting] = useState(false);
  const [exportProgress, setExportProgress] = useState(0);

  useEffect(() => {
    // Method 1: From location state (navigate with state)
    if (location.state?.template) {
      setTemplate(location.state.template);
      setLoading(false);
    }
    // Method 2: From URL params (template data in URL)
    else if (location.search) {
      const urlParams = new URLSearchParams(location.search);
      const templateData = urlParams.get("template");
      if (templateData) {
        try {
          const parsedTemplate = JSON.parse(decodeURIComponent(templateData));
          setTemplate(parsedTemplate);
          setLoading(false);
        } catch (error) {
          console.error("Error parsing template data:", error);
          navigate("/video-templates");
        }
      }
    }
    // Method 3: From template ID (fetch from API/database)
    else if (params.templateId) {
      fetchTemplateById(params.templateId);
    } else {
      // No template data found, redirect to templates
      navigate("/video-templates");
    }
  }, [location, params, navigate]);

  const fetchTemplateById = async (templateId) => {
    try {
      // Replace with your actual API call
      const mockTemplate = {
        id: templateId,
        name: "Sample Video Template",
        theme: "romantic",
        category: "wedding",
        thumbnail:
          "https://image.happywedz.com/e-invite-images/5921489f-e0f7-411a-8b19-a85f2c11d2e9-1.JPEG",
        videoUrl:
          "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
        duration: "2:30",
        rating: 4.8,
        downloads: 1250,
        price: "Free",
        features: ["Text Overlay", "Music Sync", "Transitions"],
        colors: ["#FF6B9D", "#FFE4E1", "#FFFFFF"],
      };

      setTemplate(mockTemplate);
      setLoading(false);
    } catch (error) {
      console.error("Error fetching template:", error);
      navigate("/video-templates");
    }
  };

  const handleBackToTemplates = () => {
    navigate("/video-templates");
  };

  const handleVideoDataUpdate = (data) => {
    setVideoData(data);
  };

  const handleExport = async (exportOptions) => {
    setIsExporting(true);
    setExportProgress(0);

    try {
      // Simulate export process
      const interval = setInterval(() => {
        setExportProgress((prev) => {
          if (prev >= 100) {
            clearInterval(interval);
            setIsExporting(false);
            return 100;
          }
          return prev + 10;
        });
      }, 200);

      // In a real implementation, you would:
      // 1. Process the video with all elements
      // 2. Apply filters and effects
      // 3. Render the final video
      // 4. Generate download link

      // Simulate successful export
      setTimeout(() => {
        clearInterval(interval);
        setIsExporting(false);
        setExportProgress(100);

        // Create download link
        const link = document.createElement("a");
        link.href = template?.videoUrl || "#";
        link.download = `${exportOptions.name || "wedding-video"}.${
          exportOptions.format
        }`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      }, 2000);
    } catch (error) {
      console.error("Export failed:", error);
      setIsExporting(false);
      setExportProgress(0);
    }
  };

  const handleSave = () => {
    if (videoData) {
      const projectData = {
        template: template,
        videoData: videoData,
        savedAt: new Date().toISOString(),
        name: videoData.name || "Custom Video",
      };

      const projectId = `wedding-video-${Date.now()}`;
      localStorage.setItem(projectId, JSON.stringify(projectData));
      Swal.fire({
        icon: "success",
        title: "Project saved successfully!",
        showConfirmButton: false,
        timer: 1500,
      });
    }
  };

  const handlePreview = () => {
    setCurrentView("preview");
  };

  const handleBackToEditor = () => {
    setCurrentView("editor");
  };

  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center min-vh-100">
        <div className="text-center">
          <div className="spinner-border text-primary mb-3" role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
          <p>Loading video template...</p>
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

  if (currentView === "preview") {
    return (
      <VideoPreview
        videoData={videoData}
        onExport={handleExport}
        onSave={handleSave}
        onBack={handleBackToEditor}
        isExporting={isExporting}
        exportProgress={exportProgress}
      />
    );
  }

  return (
    <VideoEditor
      template={template}
      onBack={handleBackToTemplates}
      onVideoDataUpdate={handleVideoDataUpdate}
      onPreview={handlePreview}
    />
  );
};

export default VideoEditorPage;
