// Utility to normalize image URLs
// Utility to normalize image URLs
const getImageUrl = (imageData) => {
  const baseUrl = "https://happywedzbackend.happywedz.com/";

  const replacePrefix = (url) => {
    if (typeof url === "string") {
      // Replace old domain with new base URL
      url = url.replace(/^https:\/\/happywedz\.com:4000\/?/, baseUrl);

      // Replace 'photography' with 'blogs' in the path
      url = url.replace(/\/uploads\/photography\//g, "/uploads/blogs/");
      return url;
    }
    return url;
  };

  if (!imageData) return "https://via.placeholder.com/800x400";

  if (typeof imageData === "string") {
    if (imageData.startsWith("http")) {
      return replacePrefix(imageData);
    }
    // Replace 'photography' with 'blogs' for relative paths
    const path = imageData.replace(
      /\/uploads\/photography\//g,
      "/uploads/blogs/"
    );
    return baseUrl + path;
  }

  if (Array.isArray(imageData) && imageData.length > 0) {
    if (imageData[0].startsWith("http")) {
      return replacePrefix(imageData[0]);
    }
    // Replace 'photography' with 'blogs' for relative paths
    const path = imageData[0].replace(
      /\/uploads\/photography\//g,
      "/uploads/blogs/"
    );
    return baseUrl + path;
  }

  return "https://via.placeholder.com/800x400";
};

import React, { useEffect, useState } from "react";
import { FaChevronLeft } from "react-icons/fa";

import { User, Calendar, Clock, Heart } from "lucide-react";
import { useLoader } from "../context/LoaderContext";
import DOMPurify from "dompurify";
import SEO from "../common/SEO";
import { Helmet } from "react-helmet-async";
import { formatDate as fmtDate } from "../../utils/dateFormat";

const BlogDetails = ({ blogId, onBackClick }) => {
  const [blogData, setBlogData] = React.useState(null);
  const [loading, setLoading] = React.useState(true);
  const [liked, setLiked] = React.useState(false);
  const { showLoader, hideLoader } = useLoader();

  React.useEffect(() => {
    const fetchBlogDetail = async () => {
      try {
        showLoader();
        const response = await fetch(
          `https://happywedz.com/api/blogs/${blogId}`
        );
        const result = await response.json();

        if (result.success) {
          setBlogData(result.data);
        }
      } catch (err) {
        console.error("Error fetching blog details:", err);
      } finally {
        hideLoader();
      }
    };

    if (blogId) {
      fetchBlogDetail();
    }
  }, [blogId]);

  const formatDate = (dateString) => fmtDate(dateString);

  if (!blogData) {
    return (
      <div className="container text-center" style={{ paddingTop: "3rem" }}>
        <h3>Blog not found</h3>
        <button onClick={onBackClick} className="btn btn-primary mt-3">
          Back to Blogs
        </button>
      </div>
    );
  }

  return (
    <div
      style={{
        fontFamily: "system-ui, -apple-system, sans-serif",
        backgroundColor: "#fff",
      }}
    >
      <SEO
        title={`${blogData.title} | HappyWedz Blog`}
        description={blogData.shortDescription || `Read ${blogData.title} on the HappyWedz wedding planning blog.`}
        image={blogData.images && blogData.images.length > 0 ? getImageUrl(blogData.images[0]) : undefined}
        imageAlt={blogData.title}
        type="article"
      />

      {/* BlogPosting JSON-LD structured data */}
      {import.meta.env.VITE_ENABLE_SEO === "true" && (
        <Helmet>
          <script type="application/ld+json">
            {JSON.stringify({
              "@context": "https://schema.org",
              "@type": "BlogPosting",
              "mainEntityOfPage": {
                "@type": "WebPage",
                "@id": `https://happywedz.com/blog/${blogId}`
              },
              "headline": blogData.title,
              "description": blogData.shortDescription || `Read ${blogData.title} on the HappyWedz wedding planning blog.`,
              "image": blogData.images && blogData.images.length > 0
                ? blogData.images.map(img => getImageUrl(img))
                : ["https://happywedz.com/images/og-default.jpg"],
              "author": {
                "@type": "Person",
                "name": blogData.author || "HappyWedz Team"
              },
              "publisher": {
                "@type": "Organization",
                "name": "HappyWedz",
                "logo": {
                  "@type": "ImageObject",
                  "url": "https://happywedz.com/logo-no-bg.png"
                }
              },
              "datePublished": blogData.createdDate || blogData.createdAt,
              "dateModified": blogData.updatedAt || blogData.createdDate || blogData.createdAt,
              "keywords": Array.isArray(blogData.tags) ? blogData.tags.join(", ") : blogData.tags,
              "articleSection": blogData.category || "Weddings",
              "url": `https://happywedz.com/blog/${blogId}`
            })}
          </script>
        </Helmet>
      )}
      <div
        className="container"
        style={{ paddingTop: "2rem", paddingBottom: "1rem" }}
      >
        <button
          onClick={onBackClick}
          className="btn btn-outline-dark"
          style={{ borderRadius: "25px", padding: "8px 24px" }}
        >
          ← Back to Blogs
        </button>
      </div>

      <div className="container">
        {blogData.category && (
          <div className="text-center mb-3">
            <span
              className="badge"
              style={{
                backgroundColor: "#ff1493",
                fontSize: "0.75rem",
                padding: "6px 16px",
                borderRadius: "20px",
                fontWeight: "500",
                letterSpacing: "0.5px",
              }}
            >
              {blogData.category.toUpperCase()}
            </span>
          </div>
        )}
      </div>

      <div
        className="container"
        style={{ maxWidth: "700px", paddingBottom: "4rem" }}
      >
        <h1
          className="text-center mb-4"
          style={{
            fontFamily: '"Playfair Display", serif',
            fontSize: "2.2rem",
            fontWeight: "700",
            color: "#2c3e50",
            lineHeight: "1.3",
            padding: "0 1rem",
          }}
        >
          {blogData.title}
        </h1>

        <div
          className="text-center mb-4"
          style={{ fontSize: "0.9rem", color: "#666" }}
        >
          <span className="me-3">
            <User size={16} className="me-1" style={{ marginTop: "-3px" }} />
            BY {blogData.author || "Admin"}
          </span>
          <span className="me-3">|</span>
          <span className="me-3">
            <Calendar
              size={16}
              className="me-1"
              style={{ marginTop: "-3px" }}
            />
            {formatDate(blogData.createdDate)}
          </span>
          <span className="me-3">|</span>
          <span>
            <Clock size={16} className="me-1" style={{ marginTop: "-3px" }} />
            {blogData.readTime || "5 min"} read
          </span>
        </div>

        <p
          className="text-center mb-4"
          style={{
            fontSize: "1.1rem",
            color: "#555",
            fontStyle: "italic",
            padding: "0 2rem",
          }}
        >
          {blogData.shortDescription}
        </p>

        {blogData.fullDescription &&
          blogData.fullDescription.map((paragraph, index) => (
            <div key={index}>
              {/* Show image before each paragraph */}
              {blogData.images && blogData.images[index] && (
                <div className="mb-4 text-center">
                  <img
                    src={getImageUrl(blogData.images[index])}
                    alt={`${blogData.title} - Image ${index + 1}`}
                    className="img-fluid rounded"
                    style={{
                      width: "100%",
                      maxHeight: "500px",
                      objectFit: "contain",
                      boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
                    }}
                  />
                </div>
              )}

              {/* Paragraph content (Summernote HTML) */}
              <div
                style={{
                  fontSize: "1.05rem",
                  lineHeight: "1.8",
                  color: "#333",
                  textAlign: "justify",
                  marginBottom: "2rem",
                }}
                dangerouslySetInnerHTML={{
                  __html: DOMPurify.sanitize(paragraph),
                }}
              ></div>
            </div>
          ))}

        {blogData.images &&
          blogData.images.length > (blogData.fullDescription?.length || 0) && (
            <div className="mt-4">
              {blogData.images
                .slice(blogData.fullDescription?.length || 0)
                .map((img, idx) => (
                  <div key={idx} className="mb-4 text-center">
                    <img
                      src={getImageUrl(img)}
                      alt={`${blogData.title} - Additional ${idx + 1}`}
                      className="img-fluid rounded"
                      style={{
                        width: "100%",
                        maxHeight: "500px",
                        objectFit: "cover",
                        boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
                      }}
                    />
                  </div>
                ))}
            </div>
          )}

        <div className="text-center my-5">
          <Heart
            size={28}
            style={{ color: "#ff69b4", fill: "#ff69b4", marginRight: "12px" }}
          />
          <Heart size={28} style={{ color: "#ff1493", fill: "#ff1493" }} />
          <Heart
            size={28}
            style={{ color: "#ff69b4", fill: "#ff69b4", marginLeft: "12px" }}
          />
        </div>

        {blogData.tags && blogData.tags.length > 0 && (
          <div className="text-center mb-4">
            <h6
              className="mb-3"
              style={{
                fontSize: "0.85rem",
                color: "#999",
                textTransform: "uppercase",
                letterSpacing: "1px",
              }}
            >
              Related Tags
            </h6>
            <div>
              {blogData.tags.map((tag, idx) => (
                <span
                  key={idx}
                  className="badge me-2 mb-2"
                  style={{
                    backgroundColor: "#fff",
                    color: "#666",
                    fontSize: "0.85rem",
                    padding: "8px 16px",
                    borderRadius: "20px",
                    fontWeight: "normal",
                    border: "1px solid #ddd",
                  }}
                >
                  #{tag}
                </span>
              ))}
            </div>
          </div>
        )}

        <div className="text-center mt-4">
          <button
            className="btn"
            onClick={() => setLiked(!liked)}
            style={{
              backgroundColor: liked ? "#ff1493" : "#fff",
              color: liked ? "#fff" : "#ff1493",
              border: "2px solid #ff1493",
              borderRadius: "25px",
              padding: "10px 30px",
              fontSize: "0.95rem",
              fontWeight: "500",
              transition: "all 0.3s",
            }}
          >
            <Heart
              size={18}
              className="me-2"
              style={{
                marginTop: "-3px",
                fill: liked ? "#fff" : "none",
              }}
            />
            {liked ? "Liked!" : "Love this wedding?"}
          </button>
        </div>

        <div
          className="mt-5 pt-4 text-center"
          style={{ borderTop: "1px solid #eee" }}
        >
          <p
            style={{ fontSize: "0.9rem", color: "#666", marginBottom: "1rem" }}
          >
            Share this beautiful wedding story
          </p>

          {(() => {
            const blogUrl = `https://happywedz.com/blog/${blogId}`;
            const blogTitle = encodeURIComponent(
              blogData.title || "Beautiful Wedding Story"
            );
            const encodedUrl = encodeURIComponent(blogUrl);

            const shareLinks = {
              facebook: `https://www.facebook.com/sharer/sharer.php?u=${encodedUrl}`,
              twitter: `https://twitter.com/intent/tweet?text=${blogTitle}&url=${encodedUrl}`,
              pinterest: `https://pinterest.com/pin/create/button/?url=${encodedUrl}&description=${blogTitle}`,
              whatsapp: `https://api.whatsapp.com/send?text=${blogTitle}%20${encodedUrl}`,
            };

            return (
              <div>
                <button
                  onClick={() => window.open(shareLinks.facebook, "_blank")}
                  className="btn btn-sm me-2 mb-2"
                  style={{
                    backgroundColor: "#3b5998",
                    color: "white",
                    borderRadius: "20px",
                    padding: "8px 20px",
                    border: "none",
                  }}
                >
                  Facebook
                </button>

                <button
                  onClick={() => window.open(shareLinks.twitter, "_blank")}
                  className="btn btn-sm me-2 mb-2"
                  style={{
                    backgroundColor: "#1DA1F2",
                    color: "white",
                    borderRadius: "20px",
                    padding: "8px 20px",
                    border: "none",
                  }}
                >
                  Twitter
                </button>

                <button
                  onClick={() => window.open(shareLinks.pinterest, "_blank")}
                  className="btn btn-sm me-2 mb-2"
                  style={{
                    backgroundColor: "#E60023",
                    color: "white",
                    borderRadius: "20px",
                    padding: "8px 20px",
                    border: "none",
                  }}
                >
                  Pinterest
                </button>

                <button
                  onClick={() => window.open(shareLinks.whatsapp, "_blank")}
                  className="btn btn-sm mb-2"
                  style={{
                    backgroundColor: "#25D366",
                    color: "white",
                    borderRadius: "20px",
                    padding: "8px 20px",
                    border: "none",
                  }}
                >
                  WhatsApp
                </button>
              </div>
            );
          })()}
        </div>

        <div
          className="mt-5 p-4 text-center"
          style={{ backgroundColor: "#fef5f8", borderRadius: "15px" }}
        >
          <div className="mb-3">
            <div
              style={{
                width: "80px",
                height: "80px",
                borderRadius: "50%",
                backgroundColor: "#ff1493",
                color: "white",
                display: "inline-flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: "2rem",
                fontWeight: "bold",
              }}
            >
              {blogData.author ? blogData.author.charAt(0).toUpperCase() : "A"}
            </div>
          </div>
          <h5
            style={{
              fontFamily: '"Playfair Display", serif',
              marginBottom: "0.5rem",
            }}
          >
            Written by {blogData.author || "Admin"}
          </h5>
          <p style={{ fontSize: "0.9rem", color: "#666", marginBottom: 0 }}>
            Wedding Story Curator at HappyWedz
          </p>
        </div>
      </div>
    </div>
  );
};
export default BlogDetails;
