import React from "react";
import { Link } from "react-router-dom";
import { Helmet } from "react-helmet-async";

export default function Breadcrumbs({ items }) {
  if (!items || !Array.isArray(items) || items.length === 0) return null;

  // Schema.org BreadcrumbList payload
  const schemaPayload = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    "itemListElement": items.map((item, idx) => ({
      "@type": "ListItem",
      "position": idx + 1,
      "name": item.label,
      "item": item.url ? `https://happywedz.com${item.url}` : undefined
    }))
  };

  return (
    <nav aria-label="breadcrumb" className="my-2">
      {import.meta.env.VITE_ENABLE_SEO === "true" && (
        <Helmet>
          <script type="application/ld+json">
            {JSON.stringify(schemaPayload)}
          </script>
        </Helmet>
      )}

      <ol
        className="breadcrumb mb-0"
        style={{
          backgroundColor: "transparent",
          padding: 0,
          fontSize: "0.875rem",
          display: "flex",
          flexWrap: "wrap",
          listStyle: "none"
        }}
      >
        {items.map((item, idx) => {
          const isLast = idx === items.length - 1;
          return (
            <li
              key={idx}
              className={`breadcrumb-item ${isLast ? "active" : ""}`}
              aria-current={isLast ? "page" : undefined}
              style={{ display: "flex", alignItems: "center" }}
            >
              {isLast || !item.url ? (
                <span className="text-muted" style={{ fontWeight: isLast ? 600 : 400 }}>
                  {item.label}
                </span>
              ) : (
                <Link
                  to={item.url}
                  className="text-decoration-none text-primary"
                  style={{ fontWeight: 400 }}
                >
                  {item.label}
                </Link>
              )}
            </li>
          );
        })}
      </ol>
    </nav>
  );
}
