import React, { useEffect, useState } from "react";
import { Container, Button } from "react-bootstrap";
import { useNavigate } from "react-router-dom";
import GridView from "./Main/GridView";
// import { transformApiData } from "../../hooks/useApiData";

const IMAGE_BASE_URL = "https://happywedzbackend.happywedz.com";

const transformApiData = (items) => {
  return items.map((item) => {
    // If item is already transformed (has flat structure), return it as is
    if (item.name && item.vendor_type && !item.attributes) {
      return item;
    }

    // ... rest of transformation logic ...
    const id = item.id;
    const media = Array.isArray(item.media) ? item.media : [];
    const vendor = item.vendor || {};
    const subcategory = item.subcategory || {};
    // Handle both direct attributes and nested attributes (API response format)
    const attributes = item.attributes || {};

    // Check if attributes are flattened (from controller logic: plain.attributes = { ...plain.attributes, rating: ... })
    // The controller returns: { id, vendor_id, attributes: { ... }, vendor: {...} }
    // We need to map this to the structure expected by GridView

    // Extract rating from attributes (controller puts formatted rating there)
    const rating = attributes.rating || 0;

    const portfolioUrls = attributes.Portfolio
      ? attributes.Portfolio.split("|")
          .map((url) => url.trim())
          .filter((url) => url)
      : [];
    const normalizeUrl = (u) => {
      if (!u) return null;
      if (/^https?:\/\//i.test(u)) return u;
      return `${IMAGE_BASE_URL}${u.startsWith("/") ? u : "/" + u}`;
    };
    const gallery = (media.length > 0 ? media : portfolioUrls)
      .map(normalizeUrl)
      .filter(Boolean);
    const firstImage = gallery.length > 0 ? gallery[0] : null;

    const vendorTypeName =
      attributes.vendor_type ||
      vendor?.vendorType?.name ||
      subcategory?.vendorType?.name ||
      "";
    const isVenue = vendorTypeName.toLowerCase().includes("venue");

    const photoPackage =
      attributes.photo_package_price ||
      attributes.PhotoPackage_Price ||
      attributes.PhotoPackage ||
      attributes.PhotoPackage_price ||
      attributes.PhotoPackagePrice ||
      attributes.PhotoPackage_price_inr;
    const photoVideoPackage =
      attributes.photo_video_package_price ||
      attributes.Photo_video_Price ||
      attributes.Photo_video ||
      attributes.PhotoVideo_Price ||
      attributes.PhotoVideoPackage;

    const rawRooms =
      attributes.rooms ??
      attributes.Rooms ??
      attributes.room_count ??
      attributes.RoomCount ??
      attributes.NoOfRooms ??
      attributes.no_of_rooms ??
      attributes.No_Of_Rooms;
    let roomsParsed = null;
    if (rawRooms !== undefined && rawRooms !== null) {
      const onlyDigits = String(rawRooms).match(/\d+/);
      const n = onlyDigits ? parseInt(onlyDigits[0], 10) : NaN;
      roomsParsed = Number.isNaN(n) ? null : n;
    }

    const latitude = parseFloat(
      attributes.latitude || attributes.Latitude || ""
    );
    const longitude = parseFloat(
      attributes.longitude || attributes.Longitude || ""
    );
    const hasValidCoordinates = !isNaN(latitude) && !isNaN(longitude);

    return {
      id,
      vendor_id: item.vendor_id || vendor.id || null,
      name:
        attributes.name ||
        vendor.businessName ||
        attributes.Name ||
        "Unknown Vendor",
      subtitle: attributes.subtitle || "",
      tagline: attributes.tagline || "",
      description:
        attributes.about_us ||
        attributes.Aboutus ||
        attributes.description ||
        "",
      slug: attributes.slug || "",
      lat: hasValidCoordinates ? latitude : null,
      lng: hasValidCoordinates ? longitude : null,
      image: firstImage,
      gallery,
      videos: [],

      vegPrice: isVenue
        ? attributes.veg_price || attributes.VegPrice || null
        : null,
      nonVegPrice: isVenue
        ? attributes.non_veg_price || attributes.NonVegPrice || null
        : null,
      starting_price: !isVenue
        ? photoPackage ||
          photoVideoPackage ||
          attributes.PriceRange ||
          attributes.price ||
          null
        : null,

      address: attributes.address || attributes.Address || "",
      area: attributes.area || "",
      city: attributes.city || vendor.city || "",
      location: attributes.city || vendor.city || "",
      rooms: roomsParsed,

      rating: rating,
      review_count:
        attributes.review_count ||
        parseInt(attributes.review?.toString?.() || "0", 10) ||
        0,
      reviews:
        attributes.review_count ||
        parseInt(attributes.review?.toString?.() || "0", 10) ||
        0,

      vendor_type: vendorTypeName,
      subcategory_name: subcategory?.name || "",

      call: attributes.Phone || vendor.phone || null,
      whatsapp: attributes.Whatsapp || null,
      website: attributes.Website || null,

      about_us: attributes.about_us || attributes.Aboutus || "",
      vendor_name:
        vendor.businessName || attributes.vendor_name || attributes.Name || "",
      url: attributes.Website || attributes.URL || null,
    };
  }).filter((item) => item && item.image && String(item.image).trim() !== "");
};

const SimilarServices = ({ venueData, currentId }) => {
  const navigate = useNavigate();

  const type =
    venueData?.attributes?.vendor_type ||
    venueData?.vendor?.vendor_type ||
    venueData?.vendor?.vendorType?.name ||
    venueData?.subcategory?.vendorType?.name;

  const subCategory =
    venueData?.attributes?.sub_category ||
    venueData?.attributes?.subCategory ||
    venueData?.vendor?.sub_category ||
    venueData?.vendor?.subCategory ||
    venueData?.subcategory?.name;

  const currentCity = (
    venueData?.attributes?.city ||
    venueData?.attributes?.location?.city ||
    venueData?.vendor?.city ||
    ""
  ).toLowerCase();

  const [similarVendors, setSimilarVendors] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchSimilarServices = async () => {
      if (!currentId) return;

      setLoading(true);
      try {
        const apiBaseUrl = import.meta.env.VITE_API_URL || "https://happywedz.com/api";
        const response = await fetch(
          `${apiBaseUrl}/vendor-services/${currentId}/similar?limit=4`
        );

        if (!response.ok) {
          throw new Error("Failed to fetch similar services");
        }

        const result = await response.json();
        if (result.success && Array.isArray(result.data)) {
          const transformed = transformApiData(result.data);
          setSimilarVendors(transformed);
        } else {
          setSimilarVendors([]);
        }
      } catch (error) {
        console.error("Error fetching similar services:", error);
        setSimilarVendors([]);
      } finally {
        setLoading(false);
      }
    };

    fetchSimilarServices();
  }, [currentId]);

  if (similarVendors.length < 3 && !loading) return null;

  const displaySubCategory =
    subCategory || similarVendors?.[0]?.subcategory_name;

  return (
    <section className="similar-venues py-5 bg-light">
      <Container>
        <div className="d-flex justify-content-between align-items-center mb-4">
          <h4 className="details-section-title fw-bold m-0">
            Similar {displaySubCategory || "Vendors"} You Might Like
          </h4>
        </div>

        {loading ? (
          <div className="text-center py-5">
            <div className="spinner-border text-primary" role="status">
              <span className="visually-hidden">Loading...</span>
            </div>
          </div>
        ) : (
          <GridView subVenuesData={similarVendors} colLg={3} />
        )}

        <div className="text-center mt-4">
          <Button
            variant="outline-primary"
            className="px-5 rounded-pill"
            onClick={() => {
              const vendorTypeRaw =
                venueData?.attributes?.vendor_type ||
                venueData?.vendor?.vendor_type ||
                venueData?.vendor?.vendorType?.name ||
                venueData?.subcategory?.vendorType?.name ||
                "";
              const typeLower = vendorTypeRaw.toLowerCase();
              let section = "vendors";
              if (typeLower && typeLower.includes("venue")) {
                section = "venues";
              }

              const slug = displaySubCategory
                ? displaySubCategory
                    .toLowerCase()
                    .replace(/[^a-z0-9\s-]/g, "")
                    .replace(/\s+/g, "-")
                    .replace(/-+/g, "-")
                    .replace(/^-+|-+$/g, "")
                : "";

              const citySlug = currentCity
                ? currentCity
                    .toLowerCase()
                    .replace(/[^a-z0-9\s-]/g, "")
                    .replace(/\s+/g, "-")
                    .replace(/-+/g, "-")
                    .replace(/^-+|-+$/g, "")
                : "all";

              if (slug) {
                navigate(`/vendors/${slug}/${citySlug}`);
              } else if (section === "venues") {
                const params = new URLSearchParams();
                if (currentCity) params.append("city", currentCity);
                navigate(`/venues?${params.toString()}`);
              } else {
                const params = new URLSearchParams();
                if (currentCity) params.append("city", currentCity);
                if (vendorTypeRaw) params.append("vendorType", vendorTypeRaw);
                navigate(`/vendors/all?${params.toString()}`);
              }
              window.scrollTo(0, 0);
            }}
          >
            View All Similar
          </Button>
        </div>
      </Container>
    </section>
  );
};

export default SimilarServices;
