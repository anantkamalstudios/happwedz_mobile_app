import React, { useState, useEffect } from "react";
import {
  Search,
  Calendar,
  User,
  Clock,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";

const BlogLists = ({ onPostClick }) => {
  const [blogs, setBlogs] = useState([]);
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedBlog, setSelectedBlog] = useState(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedVendor, setSelectedVendor] = useState("");
  const [selectedDate, setSelectedDate] = useState(null);
  const [selectedCity, setSelectedCity] = useState("");
  const [imageErrors, setImageErrors] = useState({});
  const [searchResults, setSearchResults] = useState([]);
  const [isSearching, setIsSearching] = useState(false);
  const [allBlogs, setAllBlogs] = useState([]);
  const blogsPerPage = 6;

  useEffect(() => {
    const fetchBlogs = async () => {
      try {
        const response = await fetch("https://happywedz.com/api/blogs/all");
        const data = await response.json();

        let apiBlogs = [];
        if (data.success && Array.isArray(data.data)) {
          apiBlogs = data.data.map((b) => ({
            ...b,
            title: b.title || "Untitled",
            category: b.category || "",
            shortDescription: b.shortDescription || "",
            image: b.image || "",
            tags: b.tags || [],
            postDate: b.postDate || "",
            createdDate: b.createdDate || "",
            featured: b.featured || false,
            trending: b.trending || false,
            views: b.views || 0,
            likes: b.likes || 0,
            author: b.author || "",
            readTime: b.readTime || "5 min read",
          }));
        }
        setBlogs(apiBlogs);
        setAllBlogs(apiBlogs);
      } catch (err) {
        console.error("Error fetching blogs:", err);
      }
    };

    fetchBlogs();
  }, []);

  useEffect(() => {
    const q = searchTerm.trim();
    if (q.length < 2) {
      setSearchResults([]);
      setIsSearching(false);
      return;
    }
    setIsSearching(true);
    const controller = new AbortController();
    const timer = setTimeout(async () => {
      try {
        const params = new URLSearchParams({ q, limit: "10", offset: "0" });
        const res = await fetch(
          `https://happywedz.com/api/blogs/search?${params.toString()}`,
          { signal: controller.signal }
        );
        const json = await res.json();
        const results = Array.isArray(json?.data?.results)
          ? json.data.results
          : [];
        const mapped = results.map((b) => ({
          id: b.id,
          title: b.title || "Untitled",
          shortDescription: b.shortDescription || "",
          image:
            typeof b.image === "string"
              ? b.image.replace(/`/g, "").trim()
              : b.image,
          author: b.author || "",
          postDate: b.postDate || "",
          readTime: "5 min read",
        }));
        setSearchResults(mapped);
      } catch (e) {
        setSearchResults([]);
      } finally {
        setIsSearching(false);
      }
    }, 300);
    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [searchTerm]);

  const filteredBlogs = blogs.filter((blog) => {
    const titleMatch = blog.title
      .toLowerCase()
      .includes(searchTerm.toLowerCase());
    const vendorMatch =
      !selectedVendor ||
      (blog.author &&
        blog.author
          .toLowerCase()
          .split(" ")
          .some((word) => word.startsWith(selectedVendor.toLowerCase())));
    const dateMatch =
      !selectedDate ||
      (blog.postDate &&
        new Date(blog.postDate).toDateString() ===
          new Date(selectedDate).toDateString());

    return titleMatch && vendorMatch && dateMatch;
  });

  const indexOfLastBlog = currentPage * blogsPerPage;
  const indexOfFirstBlog = indexOfLastBlog - blogsPerPage;
  const currentBlogs = filteredBlogs.slice(indexOfFirstBlog, indexOfLastBlog);
  const totalPages = Math.ceil(filteredBlogs.length / blogsPerPage);

  const formatDate = (dateString) => {
    if (!dateString) return "";
    const date = new Date(dateString);
    return date.toLocaleDateString("en-US", {
      day: "2-digit",
      month: "short",
      year: "numeric",
    });
  };

  const getImageUrl = (imageData, useFallback = false) => {
    const baseUrl = "https://happywedzbackend.happywedz.com/";
    const replacePrefix = (url, shouldFallback) => {
      if (typeof url === "string") {
        url = url.replace(/^https:\/\/happywedz\.com:4000\/?/, baseUrl);
        // Replace 'blogs' with 'photography' in the path
        url = url.replace(/\/uploads\/blogs\//g, "/uploads/blogs/");
        if (!shouldFallback) {
          url = url.replace(/\/uploads\/blogs\//g, "/uploads/photography/");
        }
        return url;
      }
      return url;
    };

    if (!imageData) return "./images/noimage.jpeg";

    if (typeof imageData === "string") {
      if (imageData.startsWith("http")) {
        return replacePrefix(imageData, useFallback);
      }
      let path = imageData;
      if (!useFallback) {
        path = imageData.replace(
          /\/uploads\/blogs\//g,
          "/uploads/photography/"
        );
      }
      return baseUrl + path;
    }

    if (Array.isArray(imageData) && imageData.length > 0) {
      if (imageData[0].startsWith("http")) {
        return replacePrefix(imageData[0], useFallback);
      }
      let path = imageData[0];
      if (!useFallback) {
        path = imageData[0].replace(
          /\/uploads\/blogs\//g,
          "/uploads/photography/"
        );
      }
      return baseUrl + path;
    }

    return "./images/noimage.jpeg";
  };

  const handleImageError = (e, imageKey, imageData) => {
    if (!imageErrors[imageKey]) {
      setImageErrors((prev) => ({ ...prev, [imageKey]: true }));
      e.target.src = getImageUrl(imageData, true);
    } else {
      e.target.src = "./images/noimage.jpeg";
    }
  };

  const createSlug = (title) => {
    return title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/(^-|-$)/g, "");
  };

  const incrementSearch = async (id) => {
    const blogId = parseInt(id, 10);
    if (Number.isNaN(blogId)) return;
    try {
      await fetch(
        `https://happywedz.com/api/blogs/${blogId}/increment-search`,
        {
          method: "POST",
        }
      );
    } catch {}
  };

  return (
    <div
      style={{
        fontFamily: "system-ui, -apple-system, sans-serif",
        backgroundColor: "#f8f9fa",
        minHeight: "100vh",
        paddingTop: "2rem",
        paddingBottom: "3rem",
      }}
    >
      <div className="container">
        <div className="row">
          <div className="col-md-8">
            {/* Search Bar */}
            <div className="mb-4">
              <div
                className="input-group"
                style={{ boxShadow: "0 2px 8px rgba(0,0,0,0.1)" }}
              >
                <span className="input-group-text bg-white border-end-0">
                  <Search size={20} color="#999" />
                </span>
                <input
                  type="text"
                  className="form-control border-start-0 ps-0"
                  placeholder="Search Wedding Articles"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  style={{ fontSize: "15px", padding: "12px" }}
                />
              </div>
            </div>

            {/* Blog Cards */}
            <div className="row g-4">
              {(searchResults.length > 0 ? searchResults : currentBlogs).map(
                (blog) => (
                  <div key={blog.id} className="col-md-6">
                    <div
                      className="card h-100 border-0"
                      style={{
                        cursor: "pointer",
                        transition: "transform 0.3s, box-shadow 0.3s",
                        boxShadow: "0 2px 12px rgba(0,0,0,0.08)",
                      }}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.transform = "translateY(-5px)";
                        e.currentTarget.style.boxShadow =
                          "0 4px 20px rgba(0,0,0,0.15)";
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.transform = "translateY(0)";
                        e.currentTarget.style.boxShadow =
                          "0 2px 12px rgba(0,0,0,0.08)";
                      }}
                      onClick={() => {
                        if (
                          searchResults.length > 0 &&
                          searchTerm.trim().length >= 2
                        )
                          incrementSearch(blog.id);
                        onPostClick(blog.id);
                      }}
                    >
                      {/* Image Section */}
                      <div
                        style={{
                          height: "240px",
                          overflow: "hidden",
                          position: "relative",
                        }}
                      >
                        {Array.isArray(blog.image) && blog.image.length > 1 ? (
                          <div className="row g-0" style={{ height: "100%" }}>
                            <div className="col-6">
                              <img
                                src={getImageUrl(
                                  blog.image[0],
                                  imageErrors[`${blog.id}-0`]
                                )}
                                alt={blog.title}
                                onError={(e) =>
                                  handleImageError(
                                    e,
                                    `${blog.id}-0`,
                                    blog.image[0]
                                  )
                                }
                                style={{
                                  width: "100%",
                                  height: "240px",
                                  objectFit: "cover",
                                }}
                              />
                            </div>
                            <div className="col-6">
                              <img
                                src={getImageUrl(
                                  blog.image[1],
                                  imageErrors[`${blog.id}-1`]
                                )}
                                alt={blog.title}
                                onError={(e) =>
                                  handleImageError(
                                    e,
                                    `${blog.id}-1`,
                                    blog.image[1]
                                  )
                                }
                                style={{
                                  width: "100%",
                                  height: "240px",
                                  objectFit: "cover",
                                }}
                              />
                            </div>
                          </div>
                        ) : (
                          <img
                            src={getImageUrl(
                              blog.image,
                              imageErrors[`${blog.id}-main`]
                            )}
                            className="card-img-top"
                            alt={blog.title}
                            onError={(e) =>
                              handleImageError(e, `${blog.id}-main`, blog.image)
                            }
                            style={{
                              width: "100%",
                              height: "240px",
                              objectFit: "contain",
                            }}
                          />
                        )}
                      </div>

                      <div className="card-body d-flex flex-column">
                        {/* Title */}
                        <h5
                          className="card-title mb-3"
                          style={{
                            fontFamily: '"Playfair Display", serif',
                            fontSize: "1.25rem",
                            fontWeight: "600",
                            lineHeight: "1.4",
                            color: "#2c3e50",
                          }}
                        >
                          {blog.title}
                        </h5>

                        {/* Meta Info - Centered */}
                        <div
                          className="text-center mb-3"
                          style={{ fontSize: "0.85rem", color: "#666" }}
                        >
                          <span className="me-2">
                            <User
                              size={14}
                              className="me-1"
                              style={{ marginTop: "-2px" }}
                            />
                            BY {blog.author || "Admin"}
                          </span>
                          <span className="me-2">|</span>
                          <span className="me-2">
                            <Calendar
                              size={14}
                              className="me-1"
                              style={{ marginTop: "-2px" }}
                            />
                            {formatDate(blog.postDate)}
                          </span>
                          <span className="me-2">|</span>
                          <span>
                            <Clock
                              size={14}
                              className="me-1"
                              style={{ marginTop: "-2px" }}
                            />
                            {blog.readTime}
                          </span>
                        </div>

                        {/* Description */}
                        <p
                          className="card-text text-muted flex-grow-1"
                          style={{
                            fontSize: "0.9rem",
                            lineHeight: "1.6",
                          }}
                        >
                          {blog.shortDescription?.substring(0, 120)}...
                        </p>
                      </div>
                    </div>
                  </div>
                )
              )}
            </div>

            {/* Pagination */}
            {searchResults.length === 0 && totalPages > 1 && (
              <nav className="mt-5">
                <ul className="pagination justify-content-center">
                  <li
                    className={`page-item ${
                      currentPage === 1 ? "disabled" : ""
                    }`}
                  >
                    <button
                      className="page-link"
                      onClick={() =>
                        setCurrentPage((prev) => Math.max(prev - 1, 1))
                      }
                      style={{ border: "none", color: "#d946a6" }}
                    >
                      <ChevronLeft size={18} />
                    </button>
                  </li>
                  {[...Array(totalPages)].map((_, idx) => (
                    <li
                      key={idx}
                      className={`page-item ${
                        currentPage === idx + 1 ? "active" : ""
                      }`}
                    >
                      <button
                        className="page-link"
                        onClick={() => setCurrentPage(idx + 1)}
                        style={{
                          border: "none",
                          backgroundColor:
                            currentPage === idx + 1 ? "#d946a6" : "transparent",
                          color: currentPage === idx + 1 ? "white" : "#d946a6",
                        }}
                      >
                        {idx + 1}
                      </button>
                    </li>
                  ))}
                  <li
                    className={`page-item ${
                      currentPage === totalPages ? "disabled" : ""
                    }`}
                  >
                    <button
                      className="page-link"
                      onClick={() =>
                        setCurrentPage((prev) => Math.min(prev + 1, totalPages))
                      }
                      style={{ border: "none", color: "#d946a6" }}
                    >
                      <ChevronRight size={18} />
                    </button>
                  </li>
                </ul>
              </nav>
            )}
          </div>

          {/* Sidebar */}
          <div className="col-md-4">
            <div
              className="card border-0 p-4"
              style={{
                position: "sticky",
                top: "20px",
                boxShadow: "0 2px 12px rgba(0,0,0,0.08)",
              }}
            >
              <h4
                className="text-center mb-4"
                style={{
                  fontFamily: '"Playfair Display", serif',
                  fontSize: "1.5rem",
                  color: "#2c3e50",
                }}
              >
                I am looking for
              </h4>

              <div className="mb-3">
                <input
                  type="text"
                  className="form-control"
                  placeholder="Wedding Vendors"
                  value={selectedVendor}
                  onChange={(e) => setSelectedVendor(e.target.value)}
                  style={{ padding: "8px", fontSize: "15px" }}
                />
              </div>

              <div className="mb-3">
                <DatePicker
                  className="form-control"
                  placeholderText="Select Date"
                  selected={selectedDate}
                  onChange={(date) => setSelectedDate(date)}
                  style={{ padding: "12px", fontSize: "15px" }}
                />
              </div>

              <button
                className="btn w-100"
                style={{
                  backgroundColor: "#d946a6",
                  color: "white",
                  padding: "12px",
                  fontSize: "16px",
                  fontWeight: "500",
                  border: "none",
                  borderRadius: "8px",
                }}
              >
                Search
              </button>

              {/* Featured Image */}
              <div className="mt-4">
                <img
                  src="https://images.unsplash.com/photo-1519741497674-611481863552?w=600"
                  alt="Wedding Venues"
                  className="img-fluid rounded"
                  style={{ width: "100%" }}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default BlogLists;
