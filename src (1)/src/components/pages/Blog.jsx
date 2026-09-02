import React, { useState, useEffect } from "react";
import { useParams, useNavigate, useLocation } from "react-router-dom";
import BlogLists from "./BlogLists";
import BlogDetails from "./BlogDetails";
import { useLoader } from "../context/LoaderContext";
import SEO from "../common/SEO";

const Blog = () => {
  const { blogId } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const [currentView, setCurrentView] = useState("list");
  const [selectedBlogId, setSelectedBlogId] = useState(null);
  const [filterType, setFilterType] = useState(null);
  const [filterCategoryId, setFilterCategoryId] = useState(null);
  const [filteredBlogs, setFilteredBlogs] = useState([]);
  const { showLoader, hideLoader } = useLoader();
  useEffect(() => {
    showLoader();
    if (blogId) {
      setSelectedBlogId(blogId);
      setCurrentView("detail");
    } else {
      setCurrentView("list");
      setSelectedBlogId(null);
    }
    const params = new URLSearchParams(location.search);
    const t = params.get("type");
    const cId = params.get("categoryId");
    setFilterType(t);
    setFilterCategoryId(cId);
    if (t && cId && !blogId) {
      (async () => {
        try {
          const res = await fetch(
            `https://happywedz.com/api/blogs/all?categoryId=${cId}&type=${t}&limit=10`
          );
          const json = await res.json();
          setFilteredBlogs(Array.isArray(json.data) ? json.data : []);
        } catch (e) {
          setFilteredBlogs([]);
        } finally {
          hideLoader();
        }
      })();
    } else {
      setFilteredBlogs([]);
      hideLoader();
    }
  }, [blogId, location.search]);

  const handlePostClick = (blogId) => {
    navigate(`/blog/${blogId}`);
  };

  const handleBackClick = () => {
    navigate("/blog");
  };

  return (
    <div>
      {currentView === "list" && (
        <SEO
          title="Wedding Planning Blog & Inspiration | HappyWedz"
          description="Read top wedding tips, decor trends, bridal outfits ideas, photography inspiration, and planning guides on the HappyWedz wedding blog."
        />
      )}
      {currentView === "list" ? (
        filteredBlogs && filteredBlogs.length > 0 ? (
          <div className="container py-4">
            <h4 className="mb-3">
              Showing results for {filterType?.replace(/_/g, " ")}
            </h4>
            <div className="row g-4">
              {filteredBlogs.map((b) => (
                <div key={b.id} className="col-md-4">
                  <div className="card h-100 border-0 shadow-sm">
                    <div className="ratio ratio-16x9 rounded-3 overflow-hidden">
                      <img
                        src={
                          typeof b.image === "string"
                            ? b.image.startsWith("http")
                              ? b.image
                              : `https://happywedzbackend.happywedz.com/${b.image.replace(
                                  /^\/+/,
                                  ""
                                )}`
                            : Array.isArray(b.image)
                            ? b.image[0].startsWith("http")
                              ? b.image[0]
                              : `https://happywedzbackend.happywedz.com/${b.image[0].replace(
                                  /^\/+/,
                                  ""
                                )}`
                            : "/images/noimage.jpeg"
                        }
                        alt={b.title}
                        className="w-100 h-100 object-fit-cover"
                        onClick={() => handlePostClick(b.id)}
                        role="button"
                      />
                    </div>
                    <div className="card-body">
                      <h6 className="fw-semibold mb-1">{b.title}</h6>
                      <div className="text-muted small mb-2">
                        {b.author || "Admin"}
                      </div>
                      <button
                        className="btn btn-outline-primary btn-sm"
                        onClick={() => handlePostClick(b.id)}
                      >
                        Read More
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ) : (
          <BlogLists onPostClick={handlePostClick} />
        )
      ) : (
        <BlogDetails blogId={selectedBlogId} onBackClick={handleBackClick} />
      )}
    </div>
  );
};

export default Blog;
