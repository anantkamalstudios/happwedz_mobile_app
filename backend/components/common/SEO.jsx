import React from "react";
import { Helmet } from "react-helmet-async";
import { useLocation } from "react-router-dom";
import {
  staticPagesMetadata,
  cityVenuesMetadata,
  vendorCategoriesMetadata,
  photographyCategoriesMetadata
} from "../../config/seoMetadata";

const toTitleCase = (str) =>
  (str || "")
    .toString()
    .replace(/-/g, " ")
    .replace(/\b\w/g, (l) => l.toUpperCase());

const getCategoryNoun = (path) => {
  const cat = vendorCategoriesMetadata[path];
  if (!cat) return "";
  const match = cat.description.match(/verified (.*?) across/i);
  if (match) return match[1].trim();
  return cat.label ? cat.label.toLowerCase() : "";
};

export default function SEO({
  title,
  description,
  image = "https://happywedz.com/logo-no-bg.png",
  type = "website",
  canonical,
}) {
  const { pathname } = useLocation();
  // Strip trailing slash once; use this for both canonical and metadata lookup
  const normalizedPath = pathname.length > 1 && pathname.endsWith("/")
    ? pathname.slice(0, -1)
    : pathname;
  const currentCanonical = canonical || `https://happywedz.com${normalizedPath}`;

  // Helper to resolve metadata dynamically
  const resolved = React.useMemo(() => {
    let path = normalizedPath;
    const pathLower = path.toLowerCase();

    // 1. Static Pages
    if (staticPagesMetadata[pathLower]) {
      return staticPagesMetadata[pathLower];
    }
    
    // 2. City Venues (e.g. /wedding-venues/mumbai)
    if (cityVenuesMetadata[pathLower]) {
      return cityVenuesMetadata[pathLower];
    }
    
    // 3. Vendor Categories (e.g. /vendors/photographers)
    if (vendorCategoriesMetadata[pathLower]) {
      return {
        title: vendorCategoriesMetadata[pathLower].title,
        description: vendorCategoriesMetadata[pathLower].description
      };
    }
    
    // 4. Photography Categories (e.g. /photography/bridal-lehenga)
    if (photographyCategoriesMetadata[pathLower]) {
      return {
        title: photographyCategoriesMetadata[pathLower].title,
        description: photographyCategoriesMetadata[pathLower].description
      };
    }

    // 5. Vendor Category x City (e.g. /vendors/photographers/pune)
    const vendorsPattern = /^\/vendors\/([a-z0-9-]+)\/([a-z0-9-]+)$/i;
    const matchVendors = path.match(vendorsPattern);
    if (matchVendors) {
      const subcat = matchVendors[1];
      const cityVal = matchVendors[2];
      
      const catPath = `/vendors/${subcat.toLowerCase()}`;
      const catObj = vendorCategoriesMetadata[catPath];
      const categoryLabel = catObj ? catObj.label : toTitleCase(subcat);
      const categoryNoun = getCategoryNoun(catPath) || categoryLabel.toLowerCase();
      const cityName = toTitleCase(cityVal);
      
      return {
        title: `Best ${categoryLabel} in ${cityName} — Prices & Reviews | HappyWedz`,
        description: `Find & book the best verified ${categoryNoun} in ${cityName}. Compare packages, check prices, view photos, read reviews, and check availability on HappyWedz.`
      };
    }

    return null;
  }, [normalizedPath]);

  const finalTitle = resolved?.title || title || "HappyWedz - Find Top Wedding Vendors, Venues & Planning Tools";
  const finalDescription = resolved?.description || description || "Discover top-rated wedding vendors, venues, and planning tools for your perfect wedding. Explore real weddings, inspiration, and expert advice with HappyWedz.";

  return (
    <Helmet>
      {/* Standard HTML Tags */}
      <title>{finalTitle}</title>
      <meta name="title" content={finalTitle} />
      <meta name="description" content={finalDescription} />
      <link rel="canonical" href={currentCanonical} />

      {/* Open Graph / Facebook */}
      <meta property="og:type" content={type} />
      <meta property="og:url" content={currentCanonical} />
      <meta property="og:title" content={finalTitle} />
      <meta property="og:description" content={finalDescription} />
      <meta property="og:image" content={image} />

      {/* Twitter */}
      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:url" content={currentCanonical} />
      <meta name="twitter:title" content={finalTitle} />
      <meta name="twitter:description" content={finalDescription} />
      <meta name="twitter:image" content={image} />
    </Helmet>
  );
}
