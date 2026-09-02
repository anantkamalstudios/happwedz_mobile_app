import React from "react";
import { Helmet } from "react-helmet-async";

/**
 * StructuredData component supporting:
 * - EventVenue (for wedding venues)
 * - LocalBusiness (for general vendors)
 * - Organization & WebSite (for homepage)
 *
 * CRITICAL RULE: aggregateRating is ONLY emitted if reviewCount > 0 AND rating > 0.
 * Emitting zero ratings or fake ratings is a manual-action risk.
 */
export default function StructuredData({ type, data }) {
  if (import.meta.env.VITE_ENABLE_SEO !== "true") return null;
  if (!type) return null;

  let schemaPayload = null;

  if (type === "homepage") {
    schemaPayload = [
      {
        "@context": "https://schema.org",
        "@type": "Organization",
        "name": "HappyWedz",
        "url": "https://happywedz.com",
        "logo": "https://happywedz.com/logo-no-bg.png",
        "description": "Discover top-rated wedding vendors, venues, and planning tools for your perfect wedding.",
        "sameAs": [
          "https://www.facebook.com/happywedz",
          "https://www.instagram.com/happywedz"
        ]
      },
      {
        "@context": "https://schema.org",
        "@type": "WebSite",
        "name": "HappyWedz",
        "url": "https://happywedz.com",
        "potentialAction": {
          "@type": "SearchAction",
          "target": "https://happywedz.com/wedding-venues/{search_term_string}",
          "query-input": "required name=search_term_string"
        }
      }
    ];
  } else if ((type === "venue" || type === "vendor") && data) {
    const schemaType = type === "venue" ? "EventVenue" : "LocalBusiness";
    const name = data.name || "Vendor";
    const description = data.description || `Book ${name} on HappyWedz.`;
    const image = data.image ? [data.image] : undefined;
    const url = data.url || window.location.href;
    const address = (data.address || data.city) ? {
      "@type": "PostalAddress",
      "streetAddress": (data.address && data.address !== data.city && !data.address.toLowerCase().includes("location not specified")) ? data.address : undefined,
      "addressLocality": data.city || undefined,
      "addressCountry": "IN"
    } : undefined;

    const ratingVal = parseFloat(data.rating);
    const reviewCountVal = parseInt(data.reviewCount || data.reviews, 10);
    
    // STRICT RULE: Only emit aggregateRating if there are actual reviews (> 0) and rating > 0
    const hasValidReviews = Number.isFinite(ratingVal) && ratingVal > 0 && Number.isFinite(reviewCountVal) && reviewCountVal > 0;

    const telephone = (typeof data.phone === "string" && data.phone.trim().length > 0) ? data.phone.trim() : undefined;
    const maxCapacity = data.capacity ? parseInt(data.capacity, 10) : undefined;

    schemaPayload = {
      "@context": "https://schema.org",
      "@type": schemaType,
      "name": name,
      "description": description,
      "image": image,
      "url": url,
      "address": address,
      ...(telephone ? { "telephone": telephone } : {}),
      ...(type === "venue" && Number.isInteger(maxCapacity) && maxCapacity > 0 ? { "maximumAttendeeCapacity": maxCapacity } : {}),
      "priceRange": data.priceRange || undefined,
      ...(hasValidReviews ? {
        "aggregateRating": {
          "@type": "AggregateRating",
          "ratingValue": ratingVal.toFixed(1),
          "reviewCount": reviewCountVal
        }
      } : {})
    };
  }

  if (!schemaPayload) return null;

  return (
    <Helmet>
      <script type="application/ld+json">
        {JSON.stringify(schemaPayload)}
      </script>
    </Helmet>
  );
}
