import React, { useEffect } from "react";
import { Link, useParams } from "react-router-dom";
import usePhotography from "../../../hooks/usePhotography";

const GridImages = ({ category, searchQuery, photos }) => {
  const { typesWithCategories, fetchTypesWithCategories } = usePhotography();
  useEffect(() => {
    fetchTypesWithCategories();
  }, []);
  const { subcategory, city } = useParams();
  const filteredImages = photos
    .map((img) => {
      let url = img.images?.[0]?.trim();
      let fallbackUrl = null;

      if (url?.startsWith("http://happywedz.com/uploads/photography/")) {
        url = url.replace(
          "http://happywedz.com",
          "https://happywedzbackend.happywedz.com"
        );
        // Extract filename and create fallback URL for blogs folder
        const filename = url.split("/").pop();
        fallbackUrl = `https://happywedzbackend.happywedz.com/uploads/blogs/${filename}`;
      }
      if (url?.startsWith("https://happywedz.com/uploads/photography/")) {
        url = url.replace(
          "https://happywedz.com",
          "https://happywedzbackend.happywedz.com"
        );
        // Extract filename and create fallback URL for blogs folder
        const filename = url.split("/").pop();
        fallbackUrl = `https://happywedzbackend.happywedz.com/uploads/blogs/${filename}`;
      }
      if (url?.startsWith("https://happywedz.com/uploads/blogs/")) {
        url = url.replace(
          "https://happywedz.com",
          "https://happywedzbackend.happywedz.com"
        );
      }

      return { ...img, url, fallbackUrl };
    })
    .filter((img) => {
      const matchesCategory =
        category === "all" ||
        img.photography_type_id === category ||
        img.photography_type_id === Number(category);

      const searchLower = searchQuery?.toLowerCase() || "";
      const matchesSearch =
        !searchQuery ||
        img.title?.toLowerCase().includes(searchLower) ||
        img.description?.toLowerCase().includes(searchLower) ||
        img.photographer_name?.toLowerCase().includes(searchLower) ||
        img.city_name?.toLowerCase().includes(searchLower) ||
        img.tags?.some((tag) => tag.toLowerCase().includes(searchLower));

      return matchesCategory && matchesSearch;
    });

  const formattedCategory = category && category !== "all" ? category : (subcategory && subcategory !== "all" ? subcategory.replace(/-/g, " ") : "Wedding");
  const formattedCity = city && city !== "all" ? city.replace(/-/g, " ").replace(/\b\w/g, (c) => c.toUpperCase()) : "";
  const pageHeading = formattedCity ? `${formattedCategory} Photography in ${formattedCity}` : `${formattedCategory} Photography Gallery`;

  return (
    <div className="py-5 container">
      <h1 className="fw-bold mb-4 fs-28 text-dark">{pageHeading}</h1>
      <div className="masonry">
        {filteredImages.length === 0 && (
          <div className="text-center text-muted">No images found.</div>
        )}
        {filteredImages
          .filter((img) => img.status === "active")
          .map((img, index) => {
            const getCategoryName = (catId) => {
              for (const t of typesWithCategories) {
                if (Array.isArray(t.categories)) {
                  const found = t.categories.find((c) => c.id === catId);
                  if (found) return found.name;
                }
              }
              return "";
            };
            const resolvedCategory = img.category_name || img.type_name || img.type || getCategoryName(img.photography_category_id) || "";

            const toSlug = (str) =>
              (str || "")
                .toLowerCase()
                .replace(/\s+/g, "-")
                .replace(/[^a-z0-9\-]/g, "");

            const categorySlug = toSlug(resolvedCategory) || subcategory || "all";
            const citySlug = toSlug(img.city_name || img.location || city) || "all";

            const tagsStr = Array.isArray(img.tags) ? img.tags.join("-") : (img.tags || "");
            const descriptivePrefix = toSlug(img.title || resolvedCategory || "photo");
            const tagsSlug = toSlug(tagsStr);

            let combinedParts = [descriptivePrefix, tagsSlug].filter(Boolean).join("-").split("-");
            let uniqueParts = Array.from(new Set(combinedParts));
            const photoSlug = `${uniqueParts.join("-")}-${img.id}`;

            return (
              <div key={index} className="masonry-item">
                <Link
                  to={`/photography/${categorySlug}/${citySlug}/${photoSlug}`}
                className="text-decoration-none"
                style={{ cursor: "pointer" }}
              >
                <div className="card border-0 shadow-sm">
                  <img
                    src={
                      img.url ||
                      "https://via.placeholder.com/300x200?text=No+Image"
                    }
                    alt={
                      resolvedCategory && tagsStr
                        ? `${resolvedCategory} - ${tagsStr}`
                        : img.title || resolvedCategory || "Wedding Photography"
                    }
                    className="card-img-top"
                    loading="lazy"
                    onError={(e) => {
                      if (img.fallbackUrl && e.target.src !== img.fallbackUrl) {
                        e.target.src = img.fallbackUrl;
                      } else {
                        e.target.src =
                          "https://via.placeholder.com/300x200?text=No+Image";
                      }
                    }}
                  />
                  <div className="card-body p-2">
                    <h2 className="mb-1 fs-16 fw-semibold text-dark">{img.title || "No Title"}</h2>
                    <small className="text-muted fs-14">
                      {img.city_name || "No City"}
                    </small>
                  </div>
                </div>
              </Link>
            </div>
            );
          })}
      </div>
    </div>
  );
};

export default GridImages;
