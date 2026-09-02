import React, { useEffect, useState } from "react";
import { Container, Button } from "react-bootstrap";
import { useNavigate, useParams } from "react-router-dom";
import GridView from "./Main/GridView";
import { hasView360 } from "../../utils/view360Helper";
import { subVenuesData } from "../../data/subVenuesData";
import { subVendorsData } from "../../data/subVendorsData";

const IMAGE_BASE_URL = "https://happywedzbackend.happywedz.com";

const formatCityTitle = (cityStr) => {
  if (!cityStr) return "";
  return cityStr
    .replace(/-/g, " ")
    .split(/\s+/)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
    .join(" ");
};

const slugify = (text) => {
  if (!text) return "all";
  return text
    .toString()
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-+|-+$/g, "");
};

const isValidImg = (url) => {
  if (!url || typeof url !== "string") return false;
  const lower = url.toLowerCase().trim();
  if (
    !lower ||
    lower === "null" ||
    lower === "undefined" ||
    lower.includes("imagenotfound") ||
    lower.includes("image_not_found") ||
    lower.includes("no-image") ||
    lower.includes("no_image") ||
    lower.includes("placeholder")
  ) {
    return false;
  }
  return true;
};

const transformApiData = (items) => {
  return items.map((item) => {
    if (item.name && item.vendor_type && !item.attributes) {
      return item;
    }

    const id = item.id;
    const media = Array.isArray(item.media) ? item.media : [];
    const vendor = item.vendor || {};
    const subcategory = item.subcategory || {};
    const attributes = item.attributes || {};

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

    return {
      id,
      vendor_id: item.vendor_id || vendor.id || null,
      name:
        attributes.vendor_name ||
        attributes.Name ||
        vendor.businessName ||
        "Venue",
      subtitle: attributes.subtitle || "",
      tagline: attributes.tagline || "",
      description:
        attributes.about_us ||
        attributes.Aboutus ||
        attributes.description ||
        "",
      slug: item.slug || attributes.slug || "",
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

      address:
        attributes.address && attributes.address.toLowerCase() !== "unknown"
          ? attributes.address
          : attributes.Address && attributes.Address.toLowerCase() !== "unknown"
          ? attributes.Address
          : "",
      area:
        attributes.area && attributes.area.toLowerCase() !== "unknown"
          ? attributes.area
          : "",
      city:
        attributes.city && attributes.city.toLowerCase() !== "unknown"
          ? attributes.city
          : vendor.city && vendor.city.toLowerCase() !== "unknown"
          ? vendor.city
          : "",
      location:
        attributes.city && attributes.city.toLowerCase() !== "unknown"
          ? attributes.city
          : vendor.city && vendor.city.toLowerCase() !== "unknown"
          ? vendor.city
          : "",
      rooms: roomsParsed,

      rating: attributes.rating || 0,
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
      has360: hasView360(item),
    };
  }).filter((item) => item && isValidImg(item.image));
};

const SimilarServices = ({ venueData, currentId, currentCity: propCity }) => {
  const navigate = useNavigate();
  const routeParams = useParams();

  const subCategory =
    venueData?.attributes?.sub_category ||
    venueData?.attributes?.subCategory ||
    venueData?.vendor?.sub_category ||
    venueData?.vendor?.subCategory ||
    venueData?.subcategory?.name;

  const resolvedCity = (
    propCity ||
    routeParams.city ||
    venueData?.attributes?.city ||
    venueData?.attributes?.location?.city ||
    venueData?.vendor?.city ||
    "Lucknow"
  ).trim();

  const displayCity = formatCityTitle(resolvedCity);
  const [similarVendors, setSimilarVendors] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;

    const fetchSimilar = async () => {
      setLoading(true);
      try {
        const apiBaseUrl =
          import.meta.env.VITE_API_BASE_URL ||
          import.meta.env.VITE_API_URL ||
          "https://happywedz.com/api";
        const cleanApiBase = apiBaseUrl.replace(/\/api$/, "");

        let candidateList = [];

        if (currentId) {
          try {
            const res = await fetch(
              `${cleanApiBase}/api/vendor-services/${currentId}/similar?limit=8&city=${encodeURIComponent(resolvedCity)}`
            );
            if (res.ok) {
              const resData = await res.json();
              if (resData.success && Array.isArray(resData.data)) {
                candidateList = transformApiData(resData.data);
              }
            }
          } catch {}
        }

        if (candidateList.length < 4) {
          try {
            const res = await fetch(
              `${cleanApiBase}/api/vendor-services?city=${encodeURIComponent(resolvedCity)}&limit=12`
            );
            if (res.ok) {
              const resData = await res.json();
              const items = resData.data || (Array.isArray(resData) ? resData : []);
              const transformed = transformApiData(items);
              candidateList = [...candidateList, ...transformed];
            }
          } catch {}
        }

        const currentName = String(
          venueData?.attributes?.name ||
            venueData?.attributes?.vendor_name ||
            venueData?.name ||
            ""
        ).toLowerCase().trim();

        const seenIds = new Set();
        let cityMatched = [];

        for (const item of candidateList) {
          if (
            item.id &&
            item.id !== currentId &&
            !seenIds.has(item.id) &&
            String(item.name).toLowerCase().trim() !== currentName &&
            isValidImg(item.image)
          ) {
            seenIds.add(item.id);
            cityMatched.push({
              ...item,
              city: displayCity,
              location: item.address ? `${item.address}, ${displayCity}` : displayCity,
            });
          }
        }

        if (cityMatched.length < 4) {
          const staticPool = [...subVenuesData, ...subVendorsData];
          for (const item of staticPool) {
            if (
              !seenIds.has(item.id) &&
              String(item.name).toLowerCase().trim() !== currentName &&
              isValidImg(item.image)
            ) {
              seenIds.add(item.id);
              cityMatched.push({
                ...item,
                city: displayCity,
                location: `${displayCity}`,
              });
              if (cityMatched.length >= 4) break;
            }
          }
        }

        if (isMounted) {
          setSimilarVendors(cityMatched.slice(0, 4));
        }
      } catch (err) {
        console.error("Error fetching similar venues:", err);
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    };

    fetchSimilar();

    return () => {
      isMounted = false;
    };
  }, [currentId, resolvedCity, venueData]);

  if (!loading && similarVendors.length === 0) return null;

  const displaySubCategory =
    subCategory || similarVendors?.[0]?.subcategory_name || "Venues";

  return (
    <section className="similar-venues py-5" style={{ background: "#fbfbfb" }}>
      <Container>
        <div className="d-flex justify-content-between align-items-center mb-4">
          <h4 className="details-section-title fw-bold m-0" style={{ color: "#222" }}>
            Similar {displaySubCategory} in {displayCity}
          </h4>
        </div>

        {loading ? (
          <div className="text-center py-5">
            <div className="spinner-border text-primary" role="status">
              <span className="visually-hidden">Loading...</span>
            </div>
          </div>
        ) : (
          <GridView subVenuesData={similarVendors} colLg={3} currentCity={resolvedCity} />
        )}

        <div className="text-center mt-4">
          <Button
            variant="outline-primary"
            className="px-5 rounded-pill fw-semibold"
            style={{
              borderColor: "#ed1173",
              color: "#ed1173",
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.backgroundColor = "#ed1173";
              e.currentTarget.style.color = "#fff";
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.backgroundColor = "transparent";
              e.currentTarget.style.color = "#ed1173";
            }}
            onClick={() => {
              const citySlug = slugify(resolvedCity);
              const subSlug = slugify(displaySubCategory);
              if (subSlug && subSlug !== "venues" && subSlug !== "all") {
                navigate(`/vendors/${subSlug}/${citySlug}`);
              } else {
                navigate(`/wedding-venues/${citySlug}`);
              }
              window.scrollTo(0, 0);
            }}
          >
            View All Similar in {displayCity}
          </Button>
        </div>
      </Container>
    </section>
  );
};

export default SimilarServices;
