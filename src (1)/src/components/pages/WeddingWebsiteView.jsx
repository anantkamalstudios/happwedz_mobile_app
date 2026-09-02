// import React, { useState, useEffect } from "react";
// import { useParams, useNavigate } from "react-router-dom";
// import { useSelector } from "react-redux";
// import { FiEdit, FiShare, FiArrowLeft } from "react-icons/fi";
// import { icons } from "lucide-react";
// import { TEMPLATE_LIST } from "../../templates";
// import Swal from "sweetalert2";
// import { weddingWebsiteApi } from "../../services/api/weddingWebsiteApi";
// import { API_BASE_URL } from "../../config/constants";
// const WeddingWebsiteView = () => {
//   const { id } = useParams();
//   const navigate = useNavigate();
//   const [websiteData, setWebsiteData] = useState(null);
//   const [loading, setLoading] = useState(true);
//   const [error, setError] = useState("");
//   const token = useSelector((state) => state.auth.token);
//   const [TemplateComponent, setTemplateComponent] = useState(null);
//   const [templateLoadError, setTemplateLoadError] = useState("");
//   // Expected response fields (example payload structure sent by the form):
//   // const formPayload = buildFormData({
//   //   userId,
//   //   templateId,
//   //   weddingDate,
//   //   brideData: { name, description },
//   //   groomData: { name, description },
//   //   loveStory: [{ title, date, description }],
//   //   weddingParty: [{ name, relation }],
//   //   whenWhere: [{ title, location, description, date }],
//   //   sliderImages, brideImage, groomImage, loveStoryImages, weddingPartyImages, whenWhereImages, galleryFiles
//   // });
//   useEffect(() => {
//     const fetchWebsiteData = async () => {
//       setLoading(true);
//       setError("");
//       try {
//         const data = await weddingWebsiteApi.getWebsiteById(id, token);
//         setWebsiteData(data);
//       } catch (err) {
//         setError("Error loading wedding website");
//       } finally {
//         setLoading(false);
//       }
//     };
//     if (id) fetchWebsiteData();
//   }, [token, id]);
//   // Load the template component dynamically once websiteData is available
//   useEffect(() => {
//     if (!websiteData?.templateId) return;
//     setTemplateLoadError("");
//     setTemplateComponent(null);
//     const selected = TEMPLATE_LIST.find(
//       (t) =>
//         String(t.id).toLowerCase() ===
//         String(websiteData.templateId).toLowerCase()
//     );
//     if (!selected) {
//       setTemplateLoadError(`Unknown template: ${websiteData.templateId}`);
//       return;
//     }
//     selected
//       .load()
//       .then((mod) => {
//         setTemplateComponent(() => mod.default || mod);
//       })
//       .catch(() => {
//         setTemplateLoadError("Failed to load selected template");
//       });
//   }, [websiteData]);
//   if (loading) {
//     return (
//       <div className="d-flex justify-content-center align-items-center min-vh-100">
//         <div className="spinner-border text-primary" role="status">
//           <span className="visually-hidden">Loading...</span>
//         </div>
//       </div>
//     );
//   }
//   if (error || !websiteData) {
//     return (
//       <div className="container py-5">
//         <div className="text-center">
//           <h2 className="text-danger">Error</h2>
//           <p>{error || "Wedding website not found"}</p>
//           <button
//             className="btn btn-primary"
//             onClick={() => navigate("/choose-template")}
//           >
//             <FiArrowLeft className="me-2" />
//             Back to Templates
//           </button>
//         </div>
//       </div>
//     );
//   }
//   const normalizeWebsiteData = (data) => {
//     if (!data) return data;
//     const sliderArr =
//       Array.isArray(data.slider) && data.slider.length > 0
//         ? data.slider
//         : Array.isArray(data.sliderImages)
//         ? data.sliderImages
//         : [];
//     const galleryArr =
//       Array.isArray(data.gallery) && data.gallery.length > 0
//         ? data.gallery
//         : Array.isArray(data.galleryImages)
//         ? data.galleryImages
//         : [];
//     const toImageUrl = (obj) =>
//       obj?.imageUrl || obj?.image_url || obj?.image || null;
//     const bride = {
//       name:
//         data.brideName ||
//         data?.bride?.name ||
//         data?.bride?.title ||
//         data?.brideData?.name ||
//         data?.brideData?.title ||
//         "",
//       description:
//         data?.brideDescription ||
//         data?.bride?.description ||
//         data?.brideData?.description ||
//         "",
//       imageUrl:
//         data.brideImageUrl ||
//         toImageUrl(data.bride) ||
//         toImageUrl(data.brideData) ||
//         null,
//     };
//     const groom = {
//       name:
//         data.groomName ||
//         data?.groom?.name ||
//         data?.groom?.title ||
//         data?.groomData?.name ||
//         data?.groomData?.title ||
//         "",
//       description:
//         data?.groomDescription ||
//         data?.groom?.description ||
//         data?.groomData?.description ||
//         "",
//       imageUrl:
//         data.groomImageUrl ||
//         toImageUrl(data.groom) ||
//         toImageUrl(data.groomData) ||
//         null,
//     };
//     const loveStory =
//       Array.isArray(data.loveStory) &&
//       data.loveStory.map((s) => ({
//         title: s.title || "",
//         date: s.date || "",
//         description: s.description || "",
//         imageUrl: toImageUrl(s),
//       }));
//     const weddingParty =
//       Array.isArray(data.weddingParty) &&
//       data.weddingParty.map((m) => ({
//         name: m.name || m.title || "",
//         relation: m.relation || m.role || "",
//         role: m.relation || m.role || "",
//         imageUrl: toImageUrl(m),
//       }));
//     const whenWhere =
//       Array.isArray(data.whenWhere) &&
//       data.whenWhere.map((w) => ({
//         title: w.title || "",
//         location: w.location || "",
//         description: w.description || "",
//         date: w.date || "",
//         time: w.time || "",
//         imageUrl: toImageUrl(w),
//       }));
//     return {
//       ...data,
//       // Provide both aliases so templates depending on either won't break
//       slider: sliderArr,
//       sliderImages: sliderArr,
//       gallery: galleryArr,
//       galleryImages: galleryArr,
//       bride,
//       groom,
//       loveStory: loveStory || [],
//       weddingParty: weddingParty || [],
//       whenWhere: whenWhere || [],
//     };
//   };

//   const normalizedData = normalizeWebsiteData(websiteData);
//   return (
//     <div className="wedding-website-view">
//       <style>{`
//                 .wedding-website-view {
//                     min-height: 100vh;
//                     background: linear-gradient(135deg, #fdfbfb 0%, #f8f4f1 100%);
//                 }

//                 .website-header {
//                     background: white;
//                     box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
//                     padding: 20px 0;
//                     position: sticky;
//                     top: 0;
//                     z-index: 1000;
//                 }

//                 .action-buttons {
//                     display: flex;
//                     gap: 10px;
//                     align-items: center;
//                 }

//                 .btn-action {
//                     background: linear-gradient(135deg, #ff6b9d 0%, #e91e63 100%);
//                     border: none;
//                     color: white;
//                     padding: 8px 16px;
//                     border-radius: 20px;
//                     font-weight: 600;
//                     transition: all 0.3s ease;
//                 }

//                 .btn-action:hover {
//                     transform: translateY(-2px);
//                     box-shadow: 0 4px 15px rgba(255, 107, 157, 0.4);
//                     color: white;
//                 }

//                 .btn-secondary-action {
//                     background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
//                     border: none;
//                     color: white;
//                     padding: 8px 16px;
//                     border-radius: 20px;
//                     font-weight: 600;
//                     transition: all 0.3s ease;
//                 }

//                 .btn-secondary-action:hover {
//                     transform: translateY(-2px);
//                     box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
//                     color: white;
//                 }

//                 .website-preview {
//                     background: white;
//                     border-radius: 20px;
//                     box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
//                     margin: 30px 0;
//                     overflow: hidden;
//                 }

//                 .preview-frame {
//                     width: 100%;
//                     height: 80vh;
//                     border: none;
//                     border-radius: 20px;
//                 }

//                 .website-info {
//                     background: white;
//                     border-radius: 15px;
//                     padding: 30px;
//                     margin: 20px 0;
//                     box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
//                 }

//                 .info-item {
//                     display: flex;
//                     justify-content: space-between;
//                     align-items: center;
//                     padding: 10px 0;
//                     border-bottom: 1px solid #eee;
//                 }

//                 .info-item:last-child {
//                     border-bottom: none;
//                 }

//                 .info-label {
//                     font-weight: 600;
//                     color: #333;
//                 }

//                 .info-value {
//                     color: #666;
//                 }

//                 .status-badge {
//                     padding: 4px 12px;
//                     border-radius: 20px;
//                     font-size: 12px;
//                     font-weight: 600;
//                 }

//                 .status-published {
//                     background: #d4edda;
//                     color: #155724;
//                 }

//                 .status-draft {
//                     background: #fff3cd;
//                     color: #856404;
//                 }
//             `}</style>
//       <div className="website-header">
//         <div className="container">
//           <div className="d-flex justify-content-between align-items-center w-100">
//             <div>
//               <h3 className="mb-1">
//                 {normalizedData?.bride?.name || ""} &{" "}
//                 {normalizedData?.groom?.name || ""}
//               </h3>
//               <p className="text-muted mb-0">Wedding Website</p>
//             </div>
//             <div className="action-buttons">
//               <button
//                 className="btn btn-action"
//                 onClick={() =>
//                   navigate(`/wedding-form/${websiteData.templateId}?edit=${id}`)
//                 }
//               >
//                 <FiEdit className="me-1" />
//                 Edit Website
//               </button>
//               <button
//                 className="btn btn-secondary-action"
//                 onClick={() => {
//                   if (websiteData.isPublished) {
//                     navigator.clipboard.writeText(
//                       `${API_BASE_URL}/weddingwebsite/wedding/${websiteData.websiteUrl}`
//                     );
//                     // alert('Website link copied to clipboard!');
//                     Swal.fire({
//                       icon: "success",
//                       text: "Website link copied to clipboard!",
//                       confirmButtonText: "OK",
//                       timer: "3000",
//                     });
//                   } else {
//                     // alert('Please publish your website first to share it.');
//                     Swal.fire({
//                       icon: "warning",
//                       text: "Please publish your website first to share it.",
//                       confirmButtonText: "OK",
//                       timer: "3000",
//                     });
//                   }
//                 }}
//               >
//                 <FiShare className="me-1" />
//                 Share
//               </button>
//             </div>
//           </div>
//         </div>
//       </div>
//       <div className="container py-4">
//         <div className="row">
//           <div className="col-lg-12">
//             <div className="website-preview">
//               {templateLoadError && (
//                 <div className="p-4 text-center text-danger">
//                   {templateLoadError}
//                 </div>
//               )}
//               {!templateLoadError && !TemplateComponent && (
//                 <div className="d-flex justify-content-center align-items-center preview-frame">
//                   <div className="spinner-border text-primary" role="status">
//                     <span className="visually-hidden">Loading template...</span>
//                   </div>
//                 </div>
//               )}
//               {TemplateComponent && (
//                 <div
//                   style={{
//                     minHeight: "80vh",
//                     minWidth: "100%",
//                     position: "relative",
//                   }}
//                 >
//                   <TemplateComponent data={normalizedData} />
//                 </div>
//               )}
//             </div>
//           </div>
//           {/* <div className="col-lg-4">
//             <div className="website-info">
//               <h5 className="mb-4">Website Information</h5>
//               <div className="info-item">
//                 <span className="info-label">Template:</span>
//                 <span className="info-value">{websiteData.templateId}</span>
//               </div>
//               <div className="info-item">
//                 <span className="info-label">Wedding Date:</span>
//                 <span className="info-value">
//                   {new Date(websiteData.weddingDate).toLocaleDateString()}
//                 </span>
//               </div>
//               <div className="info-item">
//                 <span className="info-label">Status:</span>
//                 <span
//                   className={`status-badge ${
//                     websiteData.isPublished
//                       ? "status-published"
//                       : "status-draft"
//                   }`}
//                 >
//                   {websiteData.isPublished ? "Published" : "Draft"}
//                 </span>
//               </div>
//               <div className="info-item">
//                 <span className="info-label">Created:</span>
//                 <span className="info-value">
//                   {new Date(websiteData.createdAt).toLocaleDateString()}
//                 </span>
//               </div>
//               <div className="info-item">
//                 <span className="info-label">Last Updated:</span>
//                 <span className="info-value">
//                   {new Date(websiteData.updatedAt).toLocaleDateString()}
//                 </span>
//               </div>
//               {websiteData.isPublished && (
//                 <div className="info-item">
//                   <span className="info-label">Public URL:</span>
//                   <span className="info-value">
//                     <a
//                       href={`/api/wedding/${websiteData.websiteUrl}`}
//                       target="_blank"
//                       rel="noopener noreferrer"
//                       className="text-decoration-none"
//                     >
//                       View Website
//                     </a>
//                   </span>
//                 </div>
//               )}
//             </div>
//             <div className="website-info">
//               <h6 className="mb-3">Quick Actions</h6>
//               <div className="d-grid gap-2">
//                 <button
//                   className="btn btn-outline-primary"
//                   onClick={() => navigate("/choose-template")}
//                 >
//                   Create Another Website
//                 </button>
//                 <button
//                   className="btn btn-outline-secondary"
//                   onClick={() => {
//                     // Navigate to user dashboard
//                     navigate("/user-dashboard");
//                   }}
//                 >
//                   Back to Dashboard
//                 </button>
//               </div>
//             </div>
//           </div> */}
//         </div>
//       </div>
//     </div>
//   );
// };
// export default WeddingWebsiteView;

import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import {
  FiEdit,
  FiShare2,
  FiArrowLeft,
  FiEye,
  FiSend,
  FiCopy,
} from "react-icons/fi";
import { TEMPLATE_LIST } from "../../templates";
import Swal from "sweetalert2";
import { weddingWebsiteApi } from "../../services/api/weddingWebsiteApi";
import NoIndex from "../common/NoIndex";

const WeddingWebsiteView = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [websiteData, setWebsiteData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const token = useSelector((state) => state.auth.token);

  const [TemplateComponent, setTemplateComponent] = useState(null);
  const [templateLoadError, setTemplateLoadError] = useState("");
  const [showShareModal, setShowShareModal] = useState(false);
  const [publishing, setPublishing] = useState(false);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    const fetchWebsiteData = async () => {
      setLoading(true);
      setError("");
      try {
        const data = await weddingWebsiteApi.getWebsiteById(id, token);
        setWebsiteData(data);
      } catch (err) {
        setError("Error loading wedding website");
      } finally {
        setLoading(false);
      }
    };
    if (id) fetchWebsiteData();
  }, [token, id]);

  useEffect(() => {
    if (!websiteData?.templateId) return;
    setTemplateLoadError("");
    setTemplateComponent(null);
    const selected = TEMPLATE_LIST.find(
      (t) =>
        String(t.id).toLowerCase() ===
        String(websiteData.templateId).toLowerCase()
    );
    if (!selected) {
      setTemplateLoadError(`Unknown template: ${websiteData.templateId}`);
      return;
    }
    selected
      .load()
      .then((mod) => {
        setTemplateComponent(() => mod.default || mod);
      })
      .catch(() => {
        setTemplateLoadError("Failed to load selected template");
      });
  }, [websiteData]);

  const handlePublish = async () => {
    try {
      setPublishing(true);
      const result = await weddingWebsiteApi.publishWebsite(id, token);

      // Update local state
      setWebsiteData((prev) => ({
        ...prev,
        isPublished: true,
        websiteUrl: result.publicUrl?.split("/wedding/")[1] || prev.websiteUrl,
      }));

      Swal.fire({
        icon: "success",
        title: "Published!",
        text: "Your wedding website is now live and ready to share!",
        confirmButtonText: "Share Now",
        showCancelButton: true,
        cancelButtonText: "Later",
      }).then((result) => {
        if (result.isConfirmed) {
          setShowShareModal(true);
        }
      });
    } catch (err) {
      Swal.fire({
        icon: "error",
        title: "Publishing Failed",
        text: "Failed to publish your wedding website. Please try again.",
      });
    } finally {
      setPublishing(false);
    }
  };

  const handleShare = async () => {
    if (!websiteData.isPublished) {
      Swal.fire({
        icon: "warning",
        title: "Publish First",
        text: "Please publish your website before sharing it.",
        showCancelButton: true,
        confirmButtonText: "Publish Now",
        cancelButtonText: "Cancel",
      }).then((result) => {
        if (result.isConfirmed) {
          handlePublish();
        }
      });
      return;
    }

    setShowShareModal(true);
  };

  const copyToClipboard = async (text) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error("Copy failed:", err);
    }
  };

  const shareViaEmail = () => {
    const publicUrl = weddingWebsiteApi.getPublicUrl(websiteData.websiteUrl);

    const subject = encodeURIComponent(
      `${websiteData?.bride?.name || ""} & ${
        websiteData?.groom?.name || ""
      }'s Wedding`
    );
    const body = encodeURIComponent(
      `You're invited! Check out our wedding website: ${publicUrl}`
    );
    const gmailUrl = `https://mail.google.com/mail/?view=cm&fs=1&tf=1&su=${subject}&body=${body}`;
    window.open(gmailUrl, "_blank");
  };

  const shareViaSocial = (platform) => {
    const publicUrl = weddingWebsiteApi.getPublicUrl(websiteData.websiteUrl);
    const text = encodeURIComponent(
      `Join us in celebrating ${websiteData?.bride?.name || ""} & ${
        websiteData?.groom?.name || ""
      }'s wedding!`
    );

    const urls = {
      whatsapp: `https://wa.me/?text=${text}%20${encodeURIComponent(
        publicUrl
      )}`,
      facebook: `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(
        publicUrl
      )}`,
      twitter: `https://twitter.com/intent/tweet?text=${text}&url=${encodeURIComponent(
        publicUrl
      )}`,
    };

    window.open(urls[platform], "_blank", "width=600,height=400");
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

  if (error || !websiteData) {
    return (
      <div className="container py-5">
        <div className="text-center">
          <h2 className="text-danger">Error</h2>
          <p>{error || "Wedding website not found"}</p>
          <button
            className="btn btn-primary"
            onClick={() => navigate("/choose-template")}
          >
            <FiArrowLeft className="me-2" />
            Back to Templates
          </button>
        </div>
      </div>
    );
  }

  const normalizeWebsiteData = (data) => {
    if (!data) return data;
    const sliderArr =
      Array.isArray(data.slider) && data.slider.length > 0
        ? data.slider
        : Array.isArray(data.sliderImages)
        ? data.sliderImages
        : [];
    const galleryArr =
      Array.isArray(data.gallery) && data.gallery.length > 0
        ? data.gallery
        : Array.isArray(data.galleryImages)
        ? data.galleryImages
        : [];
    const toImageUrl = (obj) =>
      obj?.imageUrl || obj?.image_url || obj?.image || null;
    const bride = {
      name:
        data.brideName ||
        data?.bride?.name ||
        data?.bride?.title ||
        data?.brideData?.name ||
        data?.brideData?.title ||
        "",
      description:
        data?.brideDescription ||
        data?.bride?.description ||
        data?.brideData?.description ||
        "",
      imageUrl:
        data.brideImageUrl ||
        toImageUrl(data.bride) ||
        toImageUrl(data.brideData) ||
        null,
    };
    const groom = {
      name:
        data.groomName ||
        data?.groom?.name ||
        data?.groom?.title ||
        data?.groomData?.name ||
        data?.groomData?.title ||
        "",
      description:
        data?.groomDescription ||
        data?.groom?.description ||
        data?.groomData?.description ||
        "",
      imageUrl:
        data.groomImageUrl ||
        toImageUrl(data.groom) ||
        toImageUrl(data.groomData) ||
        null,
    };
    const loveStory =
      Array.isArray(data.loveStory) &&
      data.loveStory.map((s) => ({
        title: s.title || "",
        date: s.date || "",
        description: s.description || "",
        imageUrl: toImageUrl(s),
      }));
    const weddingParty =
      Array.isArray(data.weddingParty) &&
      data.weddingParty.map((m) => ({
        name: m.name || m.title || "",
        relation: m.relation || m.role || "",
        role: m.relation || m.role || "",
        imageUrl: toImageUrl(m),
      }));
    const whenWhere =
      Array.isArray(data.whenWhere) &&
      data.whenWhere.map((w) => ({
        title: w.title || "",
        location: w.location || "",
        description: w.description || "",
        date: w.date || "",
        time: w.time || "",
        imageUrl: toImageUrl(w),
      }));
    return {
      ...data,
      slider: sliderArr,
      sliderImages: sliderArr,
      gallery: galleryArr,
      galleryImages: galleryArr,
      bride,
      groom,
      loveStory: loveStory || [],
      weddingParty: weddingParty || [],
      whenWhere: whenWhere || [],
    };
  };

  const normalizedData = normalizeWebsiteData(websiteData);
  const publicUrl = websiteData.websiteUrl
    ? weddingWebsiteApi.getPublicUrl(websiteData.websiteUrl)
    : "";

  return (
    <div className="wedding-website-view">
      <NoIndex />
      <style>{`
        .wedding-website-view {
          min-height: 100vh;
          background: linear-gradient(135deg, #fdfbfb 0%, #f8f4f1 100%);
        }
        .website-header {
          background: white;
          box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
          padding: 20px 0;
          position: sticky;
          top: 0;
          z-index: 1000;
        }
        .action-buttons {
          display: flex;
          gap: 10px;
          align-items: center;
          flex-wrap: wrap;
        }
        .btn-action {
          background: linear-gradient(135deg, #ff6b9d 0%, #e91e63 100%);
          border: none;
          color: white;
          padding: 10px 20px;
          border-radius: 25px;
          font-weight: 600;
          transition: all 0.3s ease;
          display: inline-flex;
          align-items: center;
          gap: 8px;
        }
        .btn-action:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 15px rgba(255, 107, 157, 0.4);
          color: white;
        }
        .btn-secondary-action {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border: none;
          color: white;
          padding: 10px 20px;
          border-radius: 25px;
          font-weight: 600;
          transition: all 0.3s ease;
          display: inline-flex;
          align-items: center;
          gap: 8px;
        }
        .btn-secondary-action:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
          color: white;
        }
        .btn-publish {
          background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
          border: none;
          color: white;
          padding: 10px 20px;
          border-radius: 25px;
          font-weight: 600;
          transition: all 0.3s ease;
          display: inline-flex;
          align-items: center;
          gap: 8px;
        }
        .btn-publish:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 15px rgba(67, 233, 123, 0.4);
          color: white;
        }
        .share-modal-overlay {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.7);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 2000;
          padding: 20px;
        }
        .share-modal {
          background: white;
          border-radius: 30px;
          padding: 40px;
          max-width: 500px;
          width: 100%;
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
        }
        .share-url-box {
          background: #f8f9fa;
          border: 2px solid #e9ecef;
          border-radius: 15px;
          padding: 15px;
          display: flex;
          align-items: center;
          gap: 10px;
          margin: 20px 0;
        }
        .share-url-text {
          flex: 1;
          font-size: 14px;
          color: #666;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
        .share-options {
          display: grid;
          grid-template-columns: repeat(2, 1fr);
          gap: 15px;
          margin-top: 25px;
        }
        .share-option-btn {
          background: white;
          border: 2px solid #e9ecef;
          border-radius: 15px;
          padding: 20px;
          cursor: pointer;
          transition: all 0.3s ease;
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 10px;
        }
        .share-option-btn:hover {
          border-color: #ff6b9d;
          background: #fff5f8;
          transform: translateY(-2px);
        }
        .share-option-icon {
          font-size: 32px;
          color: #ff6b9d;
        }
        .status-badge {
          padding: 6px 14px;
          border-radius: 20px;
          font-size: 13px;
          font-weight: 600;
        }
        .status-published {
          background: #d4edda;
          color: #155724;
        }
        .status-draft {
          background: #fff3cd;
          color: #856404;
        }
      `}</style>

      <div className="website-header">
        <div className="container">
          <div className="d-flex justify-content-between align-items-center flex-wrap gap-3">
            <div>
              <h3 className="mb-1">
                {normalizedData?.bride?.name || ""} &{" "}
                {normalizedData?.groom?.name || ""}
              </h3>
              <p className="text-muted mb-0 d-flex align-items-center gap-2">
                Wedding Website
                <span
                  className={`status-badge ${
                    websiteData.isPublished
                      ? "status-published"
                      : "status-draft"
                  }`}
                >
                  {websiteData.isPublished ? "Published" : "Draft"}
                </span>
              </p>
            </div>
            <div className="action-buttons">
              <button
                className="btn btn-action"
                onClick={() =>
                  navigate(`/wedding-form/${websiteData.templateId}?edit=${id}`)
                }
              >
                <FiEdit />
                Edit
              </button>

              {!websiteData.isPublished && (
                <button
                  className="btn btn-publish"
                  onClick={handlePublish}
                  disabled={publishing}
                >
                  <FiEye />
                  {publishing ? "Publishing..." : "Publish"}
                </button>
              )}

              <button
                className="btn btn-secondary-action"
                onClick={handleShare}
              >
                <FiShare2 />
                Share
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="container py-4">
        <div className="website-preview">
          {templateLoadError && (
            <div className="p-4 text-center text-danger">
              {templateLoadError}
            </div>
          )}
          {!templateLoadError && !TemplateComponent && (
            <div
              className="d-flex justify-content-center align-items-center"
              style={{ minHeight: "500px" }}
            >
              <div className="spinner-border text-primary" role="status">
                <span className="visually-hidden">Loading template...</span>
              </div>
            </div>
          )}
          {TemplateComponent && (
            <div
              style={{
                minHeight: "80vh",
                minWidth: "100%",
                position: "relative",
              }}
            >
              <TemplateComponent data={normalizedData} />
            </div>
          )}
        </div>
      </div>

      {/* Share Modal */}
      {showShareModal && (
        <div
          className="share-modal-overlay"
          onClick={() => setShowShareModal(false)}
        >
          <div className="share-modal" onClick={(e) => e.stopPropagation()}>
            <div style={{ marginBottom: "32px" }}>
              <h3
                style={{
                  fontSize: "20px",
                  fontWeight: "600",
                  color: "#1a1a1a",
                  marginBottom: "6px",
                }}
              >
                Share Your Wedding Website
              </h3>
              <p style={{ color: "#6b7280", margin: 0, fontSize: "14px" }}>
                Share your website with friends and family
              </p>
            </div>

            {/* URL Box */}
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: "12px",
                padding: "12px 16px",
                background: "#f9fafb",
                border: "1px solid #e5e7eb",
                borderRadius: "8px",
                marginBottom: "24px",
              }}
            >
              <span
                style={{
                  flex: 1,
                  color: "#374151",
                  fontSize: "14px",
                  overflow: "hidden",
                  textOverflow: "ellipsis",
                  whiteSpace: "nowrap",
                }}
              >
                {publicUrl}
              </span>
              <button
                onClick={() => copyToClipboard(publicUrl)}
                style={{
                  background: "#1a1a1a",
                  border: "none",
                  borderRadius: "6px",
                  padding: "8px 16px",
                  color: "white",
                  cursor: "pointer",
                  display: "flex",
                  alignItems: "center",
                  gap: "6px",
                  fontSize: "14px",
                  fontWeight: "500",
                  transition: "background 0.2s",
                }}
                onMouseOver={(e) => (e.currentTarget.style.background = "#333")}
                onMouseOut={(e) =>
                  (e.currentTarget.style.background = "#1a1a1a")
                }
              >
                <FiCopy size={16} />
                {copied ? "Copied!" : "Copy"}
              </button>
            </div>

            {/* Share Options */}
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(2, 1fr)",
                gap: "12px",
                marginBottom: "24px",
              }}
            >
              <button
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "8px",
                  padding: "12px 16px",
                  background: "white",
                  border: "1px solid #e5e7eb",
                  borderRadius: "6px",
                  cursor: "pointer",
                  fontSize: "14px",
                  fontWeight: "500",
                  color: "#374151",
                  transition: "border-color 0.2s, background 0.2s",
                }}
                onClick={() => shareViaSocial("whatsapp")}
                onMouseOver={(e) => {
                  e.currentTarget.style.background = "#f9fafb";
                  e.currentTarget.style.borderColor = "#d1d5db";
                }}
                onMouseOut={(e) => {
                  e.currentTarget.style.background = "white";
                  e.currentTarget.style.borderColor = "#e5e7eb";
                }}
              >
                <svg
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path d="M20.52 3.48A11.86 11.86 0 0012 .75C6.2.75 1.5 5.45 1.5 11.25c0 1.98.52 3.84 1.5 5.5L.75 23.25l6.7-2.2a11.3 11.3 0 005.8 1.5c5.8 0 10.5-4.7 10.5-10.5 0-3-1.17-5.75-3.23-7.8zM12 21.5c-1.8 0-3.54-.43-5.08-1.25l-.36-.2-3.98 1.3 1.3-3.86-.23-.38A8.5 8.5 0 013.5 11.25C3.5 6.78 7.53 3.75 12 3.75c2.28 0 4.45.88 6.07 2.5a8.5 8.5 0 01-6.07 15.25z" />
                  <path d="M17.1 14.1c-.2-.1-1.18-.58-1.36-.65-.18-.07-.31-.1-.44.1-.13.2-.5.65-.62.78-.12.13-.24.14-.44.05-.2-.1-.84-.31-1.6-.98-.59-.52-.99-1.17-1.11-1.37-.12-.2-.01-.31.09-.41.09-.09.2-.24.3-.36.1-.12.13-.2.2-.33.09-.13.05-.25-.02-.36-.07-.11-.44-1.06-.6-1.45-.16-.38-.33-.33-.44-.34l-.37-.01c-.12 0-.31.04-.48.24-.17.2-.65.63-.65 1.55s.67 1.8.77 1.93c.1.13 1.33 2.1 3.22 2.95 1.9.85 1.9.57 2.25.54.35-.02 1.15-.46 1.31-.9.16-.43.16-.8.11-.9-.05-.09-.18-.15-.38-.26z" />
                </svg>
                WhatsApp
              </button>

              <button
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "8px",
                  padding: "12px 16px",
                  background: "white",
                  border: "1px solid #e5e7eb",
                  borderRadius: "6px",
                  cursor: "pointer",
                  fontSize: "14px",
                  fontWeight: "500",
                  color: "#374151",
                  transition: "border-color 0.2s, background 0.2s",
                }}
                onClick={shareViaEmail}
                onMouseOver={(e) => {
                  e.currentTarget.style.background = "#f9fafb";
                  e.currentTarget.style.borderColor = "#d1d5db";
                }}
                onMouseOut={(e) => {
                  e.currentTarget.style.background = "white";
                  e.currentTarget.style.borderColor = "#e5e7eb";
                }}
              >
                <svg
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path d="M20 6H4c-1.1 0-2 .9-2 2v8c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2zm0 2v.8l-8 5-8-5V8h16zM4 18V9.2l7.2 4.5c.5.32 1.1.32 1.6 0L20 9.2V18H4z" />
                </svg>
                Email
              </button>

              <button
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "8px",
                  padding: "12px 16px",
                  background: "white",
                  border: "1px solid #e5e7eb",
                  borderRadius: "6px",
                  cursor: "pointer",
                  fontSize: "14px",
                  fontWeight: "500",
                  color: "#374151",
                  transition: "border-color 0.2s, background 0.2s",
                }}
                onClick={() => shareViaSocial("facebook")}
                onMouseOver={(e) => {
                  e.currentTarget.style.background = "#f9fafb";
                  e.currentTarget.style.borderColor = "#d1d5db";
                }}
                onMouseOut={(e) => {
                  e.currentTarget.style.background = "white";
                  e.currentTarget.style.borderColor = "#e5e7eb";
                }}
              >
                <svg
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path d="M22 12c0-5.52-4.48-10-10-10S2 6.48 2 12c0 4.99 3.66 9.12 8.44 9.88v-6.99H8.9v-2.9h1.54V9.8c0-1.52.9-2.36 2.29-2.36.66 0 1.35.12 1.35.12v1.49h-.76c-.75 0-.98.47-.98.95v1.15h1.66l-.27 2.9h-1.39V21.9C18.34 21.12 22 16.99 22 12z" />
                </svg>
                Facebook
              </button>

              <button
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "8px",
                  padding: "12px 16px",
                  background: "white",
                  border: "1px solid #e5e7eb",
                  borderRadius: "6px",
                  cursor: "pointer",
                  fontSize: "14px",
                  fontWeight: "500",
                  color: "#374151",
                  transition: "border-color 0.2s, background 0.2s",
                }}
                onClick={() => shareViaSocial("twitter")}
                onMouseOver={(e) => {
                  e.currentTarget.style.background = "#f9fafb";
                  e.currentTarget.style.borderColor = "#d1d5db";
                }}
                onMouseOut={(e) => {
                  e.currentTarget.style.background = "white";
                  e.currentTarget.style.borderColor = "#e5e7eb";
                }}
              >
                <svg
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  aria-hidden="true"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path d="M17.53 6.47a.75.75 0 00-1.06 0L12 10.94 7.53 6.47a.75.75 0 10-1.06 1.06L10.94 12l-4.47 4.47a.75.75 0 101.06 1.06L12 13.06l4.47 4.47a.75.75 0 101.06-1.06L13.06 12l4.47-4.47a.75.75 0 000-1.06z" />
                </svg>
                Twitter
              </button>
            </div>

            <button
              onClick={() => setShowShareModal(false)}
              style={{
                width: "100%",
                background: "white",
                border: "1px solid #e5e7eb",
                borderRadius: "6px",
                padding: "12px",
                color: "#6b7280",
                fontWeight: "500",
                cursor: "pointer",
                fontSize: "14px",
                transition: "background 0.2s",
              }}
              onMouseOver={(e) =>
                (e.currentTarget.style.background = "#f9fafb")
              }
              onMouseOut={(e) => (e.currentTarget.style.background = "white")}
            >
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default WeddingWebsiteView;
