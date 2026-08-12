import React, { useState, useEffect } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import { useLoader } from "../context/LoaderContext";

const BlogCardsSection = () => {
  const [blogPosts, setBlogPosts] = useState([]);
  const { showLoader, hideLoader } = useLoader();

  useEffect(() => {
    const fetchBlogs = async () => {
      try {
        showLoader();
        const response = await fetch("https://happywedz.com/api/blogs/all");
        const result = await response.json();

        // Map API fields to component fields
        const mappedBlogs = result.data.map((blog) => {
          const cleanedImageUrl = blog.image.replace(
            "https://happywedz.com:4000",
            "https://happywedzbackend.happywedz.com/"
          );

          return {
            id: blog.id,
            image: cleanedImageUrl,
            category: "Design",
            title: blog.title,
            excerpt: blog.shortDescription || "",
            author: {
              name: blog.author || "Admin",
              avatar: "./images/no-image.png",
              date: new Date(blog.postDate).toLocaleDateString(),
            },
          };
        });

        // Only show 2 blogs
        setBlogPosts(mappedBlogs.slice(0, 2));
      } catch (error) {
        console.error("Error fetching blog details:", error);
        setBlogPosts([]);
      } finally {
        hideLoader();
      }
    };

    fetchBlogs();
  }, []);

  return (
    <section style={styles.section}>
      <div className="container">
        {/* Section Header */}
        <div style={styles.headerContainer}>
          <div>
            <p className="fs-16" style={styles.subtitle}>
              Our Blog
            </p>
            <h3 style={styles.title}>Latest Articles & Stories</h3>
            <p className="fs-14" style={styles.description}>
              Discover inspiring wedding stories, tips, and destination guides
              from our expert team
            </p>
          </div>
        </div>

        {/* Blog Cards Grid */}
        <div className="row g-4">
          {blogPosts.map((post) => (
            <div key={post.id} className="col-12 col-md-6 col-lg-6 rounded-0">
              <div style={styles.card} className="blog-card rounded-0">
                {/* Card Image */}
                <div style={styles.imageContainer}>
                  <img src={post.image} alt={post.title} style={styles.image} />
                  <div style={styles.bookmark}>
                    <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
                      <path
                        d="M5 3C5 2.44772 5.44772 2 6 2H14C14.5523 2 15 2.44772 15 3V17.5L10 14.5L5 17.5V3Z"
                        stroke="white"
                        strokeWidth={1.5}
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      />
                    </svg>
                  </div>
                </div>

                {/* Card Content */}
                <div style={styles.cardContent}>
                  <span className="fs-12" style={styles.category}>
                    {post.category}
                  </span>

                  <p className="fs-22" style={styles.cardTitle}>
                    {post.title}
                    <svg
                      width="20"
                      height="20"
                      viewBox="0 0 20 20"
                      fill="none"
                      style={styles.titleIcon}
                    >
                      <path
                        d="M7 13L13 7M13 7H7M13 7V13"
                        stroke="currentColor"
                        strokeWidth={2}
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      />
                    </svg>
                  </p>

                  <p className="fs-14" style={styles.excerpt}>
                    {post.excerpt}
                  </p>

                  {/* Author Info */}
                  <div style={styles.authorSection}>
                    <img
                      src={post.author.avatar}
                      alt={post.author.name}
                      style={styles.avatar}
                    />
                    <div>
                      <p className="fs-14" style={styles.authorName}>
                        {post.author.name}
                      </p>
                      <p className="fs-10" style={styles.date}>
                        {post.author.date}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

        * {
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        }

        .blog-card {
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
          cursor: pointer;
        }

        .blog-card:hover {
          transform: translateY(-8px);
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.12) !important;
        }

        .blog-card:hover img {
          transform: scale(1.05);
        }

        .view-all-btn {
          transition: all 0.3s ease;
        }

        .view-all-btn:hover {
          background-color: #A01847 !important;
          transform: translateX(4px);
          box-shadow: 0 8px 24px rgba(196, 30, 86, 0.25);
        }

        @media (max-width: 768px) {
          .view-all-btn {
            width: 100%;
            justify-content: center;
            margin-top: 24px;
          }
        }
      `}</style>
    </section>
  );
};

const styles = {
  section: {
    padding: "80px 0",
    backgroundColor: "#FAFBFC",
  },
  headerContainer: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "flex-start",
    marginBottom: "48px",
    flexWrap: "wrap",
    gap: "24px",
  },
  subtitle: {
    fontSize: "0.875rem",
    fontWeight: "600",
    color: "#C91F56",
    textTransform: "uppercase",
    letterSpacing: "0.05em",
    marginBottom: "8px",
  },
  title: {
    fontSize: "2.5rem",
    fontWeight: "700",
    color: "#1F2937",
    marginBottom: "12px",
    letterSpacing: "-0.02em",
    lineHeight: "1.2",
  },
  description: {
    fontSize: "1.125rem",
    color: "#6B7280",
    lineHeight: "1.6",
    maxWidth: "600px",
    margin: 0,
  },
  viewAllBtn: {
    display: "inline-flex",
    alignItems: "center",
    gap: "8px",
    padding: "12px 24px",
    backgroundColor: "#C91F56",
    color: "white",
    border: "none",
    borderRadius: "8px",
    fontSize: "0.9375rem",
    fontWeight: "600",
    cursor: "pointer",
    whiteSpace: "nowrap",
    outline: "none",
  },
  btnIcon: {
    transition: "transform 0.3s ease",
  },
  card: {
    backgroundColor: "white",
    borderRadius: "16px",
    overflow: "hidden",
    boxShadow: "0 4px 24px rgba(0, 0, 0, 0.06)",
    height: "100%",
    display: "flex",
    flexDirection: "column",
  },
  imageContainer: {
    position: "relative",
    width: "100%",
    height: "240px",
    overflow: "hidden",
    backgroundColor: "#F3F4F6",
  },
  image: {
    width: "100%",
    height: "100%",
    objectFit: "contain",
    transition: "transform 0.6s ease",
  },
  bookmark: {
    position: "absolute",
    top: "16px",
    right: "16px",
    width: "40px",
    height: "40px",
    backgroundColor: "rgba(0, 0, 0, 0.5)",
    borderRadius: "50%",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    backdropFilter: "blur(8px)",
    cursor: "pointer",
    transition: "all 0.3s ease",
  },
  cardContent: {
    padding: "24px",
    display: "flex",
    flexDirection: "column",
    flex: 1,
  },
  category: {
    fontSize: "0.8125rem",
    fontWeight: "600",
    color: "#7C3AED",
    marginBottom: "12px",
    display: "inline-block",
  },
  cardTitle: {
    fontSize: "1.25rem",
    fontWeight: "700",
    color: "#1F2937",
    marginBottom: "12px",
    lineHeight: "1.4",
    display: "flex",
    alignItems: "flex-start",
    justifyContent: "space-between",
    gap: "8px",
  },
  titleIcon: {
    flexShrink: 0,
    color: "#9CA3AF",
    transition: "all 0.3s ease",
  },
  excerpt: {
    fontSize: "0.9375rem",
    color: "#6B7280",
    lineHeight: "1.6",
    marginBottom: "24px",
    flex: 1,
  },
  authorSection: {
    display: "flex",
    alignItems: "center",
    gap: "12px",
    paddingTop: "16px",
    borderTop: "1px solid #F3F4F6",
  },
  avatar: {
    width: "40px",
    height: "40px",
    borderRadius: "50%",
    objectFit: "cover",
    border: "2px solid #F3F4F6",
  },
  authorName: {
    fontSize: "0.875rem",
    fontWeight: "600",
    color: "#1F2937",
    margin: "0 0 2px 0",
  },
  date: {
    fontSize: "0.8125rem",
    color: "#9CA3AF",
    margin: 0,
  },
};

export default BlogCardsSection;
