import React, { useState, useEffect } from "react";
import { useParams } from "react-router-dom";
import { FiHeart, FiShare2, FiCheck } from "react-icons/fi";
import { TEMPLATE_LIST } from "../../templates";
import { weddingWebsiteApi } from "../../services/api/weddingWebsiteApi";
import Swal from "sweetalert2";
import SEO from "../common/SEO";

const PublicWeddingView = () => {
  const { websiteUrl } = useParams();
  const [websiteData, setWebsiteData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [TemplateComponent, setTemplateComponent] = useState(null);
  const [templateLoadError, setTemplateLoadError] = useState("");
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    const fetchPublicWebsite = async () => {
      setLoading(true);
      setError("");
      try {
        const data = await weddingWebsiteApi.viewPublicWebsite(websiteUrl);
        setWebsiteData(data);
      } catch (err) {
        setError(
          "This wedding website is not available or hasn't been published yet."
        );
      } finally {
        setLoading(false);
      }
    };

    if (websiteUrl) fetchPublicWebsite();
  }, [websiteUrl]);

  // Load template component
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
      setTemplateLoadError(`Template not found: ${websiteData.templateId}`);
      return;
    }

    selected
      .load()
      .then((mod) => {
        setTemplateComponent(() => mod.default || mod);
      })
      .catch(() => {
        setTemplateLoadError("Failed to load template");
      });
  }, [websiteData]);

  const handleShare = async () => {
    const shareUrl = window.location.href;

    // Try native share API first (mobile devices)
    if (navigator.share) {
      try {
        await navigator.share({
          title: `${websiteData?.bride?.name || ""} & ${
            websiteData?.groom?.name || ""
          }'s Wedding`,
          text: "Join us in celebrating our special day!",
          url: shareUrl,
        });
        return;
      } catch (err) {
        // User cancelled or error occurred, fall back to copy
      }
    }

    // Fallback to clipboard
    try {
      await navigator.clipboard.writeText(shareUrl);
      setCopied(true);
      Swal.fire({
        icon: "success",
        title: "Link Copied!",
        text: "Wedding website link copied to clipboard",
        timer: 2000,
        showConfirmButton: false,
      });
      setTimeout(() => setCopied(false), 3000);
    } catch (err) {
      Swal.fire({
        icon: "error",
        title: "Failed to copy",
        text: "Please copy the URL from your browser's address bar",
      });
    }
  };

  if (loading) {
    return (
      <div
        style={{
          minHeight: "100vh",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "linear-gradient(135deg, #fdfbfb 0%, #f8f4f1 100%)",
        }}
      >
        <div style={{ textAlign: "center" }}>
          <div
            className="spinner-border text-primary"
            role="status"
            style={{ width: "3rem", height: "3rem" }}
          >
            <span className="visually-hidden">Loading...</span>
          </div>
          <p style={{ marginTop: "20px", color: "#666", fontSize: "18px" }}>
            Loading wedding website...
          </p>
        </div>
      </div>
    );
  }

  if (error || !websiteData) {
    return (
      <div
        style={{
          minHeight: "100vh",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "linear-gradient(135deg, #fdfbfb 0%, #f8f4f1 100%)",
          padding: "20px",
        }}
      >
        <div
          style={{
            textAlign: "center",
            background: "white",
            padding: "60px 40px",
            borderRadius: "30px",
            boxShadow: "0 20px 60px rgba(0,0,0,0.1)",
            maxWidth: "500px",
          }}
        >
          <div
            style={{
              width: "80px",
              height: "80px",
              margin: "0 auto 30px",
              borderRadius: "50%",
              background:
                "linear-gradient(135deg, #ff6b9d20 0%, #c2185b20 100%)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <FiHeart style={{ fontSize: "40px", color: "#ff6b9d" }} />
          </div>
          <h2
            style={{
              fontSize: "28px",
              fontWeight: "700",
              color: "#333",
              marginBottom: "15px",
            }}
          >
            Website Not Found
          </h2>
          <p style={{ color: "#666", fontSize: "16px", lineHeight: "1.6" }}>
            {error || "This wedding website is not available."}
          </p>
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

  return (
    <div style={{ minHeight: "100vh", position: "relative" }}>
      <SEO
        title={
          websiteData?.brideName && websiteData?.groomName
            ? `${websiteData.brideName} & ${websiteData.groomName}'s Wedding | HappyWedz`
            : "Wedding Website | HappyWedz"
        }
        description={
          websiteData?.brideName && websiteData?.groomName
            ? `Celebrate the wedding of ${websiteData.brideName} & ${websiteData.groomName}. View their love story, wedding events and gallery.`
            : "View this beautiful wedding website created on HappyWedz."
        }
      />
      {/* Floating Share Button */}
      <button
        onClick={handleShare}
        style={{
          position: "fixed",
          bottom: "30px",
          right: "30px",
          width: "60px",
          height: "60px",
          borderRadius: "50%",
          background: copied
            ? "linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)"
            : "linear-gradient(135deg, #ff6b9d 0%, #c2185b 100%)",
          border: "none",
          boxShadow: "0 8px 25px rgba(255,107,157,0.4)",
          color: "white",
          cursor: "pointer",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: "24px",
          transition: "all 0.3s ease",
          zIndex: 1000,
        }}
        onMouseEnter={(e) => {
          e.currentTarget.style.transform = "scale(1.1)";
          e.currentTarget.style.boxShadow = "0 12px 35px rgba(255,107,157,0.5)";
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.transform = "scale(1)";
          e.currentTarget.style.boxShadow = "0 8px 25px rgba(255,107,157,0.4)";
        }}
        title={copied ? "Link Copied!" : "Share Wedding Website"}
      >
        {copied ? <FiCheck /> : <FiShare2 />}
      </button>

      {/* Template Content */}
      {templateLoadError && (
        <div
          style={{
            padding: "40px",
            textAlign: "center",
            color: "#dc3545",
            background: "white",
          }}
        >
          <p style={{ fontSize: "18px" }}>{templateLoadError}</p>
        </div>
      )}

      {!templateLoadError && !TemplateComponent && (
        <div
          style={{
            minHeight: "100vh",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <div className="spinner-border text-primary" role="status">
            <span className="visually-hidden">Loading template...</span>
          </div>
        </div>
      )}

      {TemplateComponent && (
        <div style={{ minHeight: "100vh", width: "100%" }}>
          <TemplateComponent data={normalizedData} />
        </div>
      )}
    </div>
  );
};

export default PublicWeddingView;
