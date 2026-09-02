import { useState, useEffect, useCallback, useRef, useMemo } from "react";
import {
  extractPriceFilters,
  extractCapacityFilters,
  extractVenueSubCategories,
  extractFoodPriceFilters,
  extractRoomsFilters,
  extractRatingFilters,
  extractReviewFilters,
} from "../utils/priceFilterUtils";

const IMAGE_BASE_URL = "https://happywedzbackend.happywedz.com";
const normalizeServiceStatus = (value) => {
  const normalized = String(value || "").trim().toLowerCase();
  if (normalized === "publish" || normalized === "published") return "publish";
  if (
    normalized === "hide" ||
    normalized === "draft" ||
    normalized === "archived"
  )
    return "hide";
  return "hide";
};

const useApiData = (
  section,
  slug,
  city = null,
  vendorType = null,
  initialPage = 1,
  initialLimit = 9,
  filters = {}
) => {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [pagination, setPagination] = useState({
    page: initialPage,
    limit: initialLimit,
    total: 0,
    totalPages: 0,
  });

  const abortRef = useRef(null);
  const cacheRef = useRef(new Map());

  const memoizedFilters = useMemo(() => filters, [JSON.stringify(filters)]);

  const fetchData = useCallback(
    async (page = initialPage, limit = initialLimit) => {
      if (!section || (!slug && !vendorType)) {
        setData([]);
        setLoading(false);
        return;
      }

      setLoading(true);
      setError(null);

      try {
        const subCategory = slug
          ? slug
            .replace(/-{2,}/g, " / ")
            .replace(/-/g, " ")
            .replace(/\s*\/\s*/g, " / ")
            .replace(/\s{2,}/g, " ")
            .replace(/\b\w/g, (l) => l.toUpperCase())
            .trim()
          : null;

        const params = new URLSearchParams();
        if (vendorType) {
          params.append("vendorType", vendorType);
        }
        if (city && city !== "all") {
          params.append("city", city);
        }

        // Prefer selected venue types for venues; otherwise use slug-derived subCategory
        const selectedSubcats = extractVenueSubCategories(memoizedFilters);
        if (selectedSubcats && selectedSubcats.trim().length > 0) {
          params.append("subCategory", selectedSubcats);
        } else if (
          !vendorType &&
          subCategory &&
          subCategory.toLowerCase() !== "all"
        ) {
          params.append("subCategory", subCategory);
        }

        params.append("page", page.toString());
        params.append("limit", limit.toString());

        // Extract price filters and add as minPrice/maxPrice query params
        const { minPrice, maxPrice } = extractPriceFilters(memoizedFilters);
        if (minPrice !== null && minPrice !== undefined) {
          params.append("minPrice", minPrice.toString());
        }
        if (maxPrice !== null && maxPrice !== undefined) {
          params.append("maxPrice", maxPrice.toString());
        }

        // Extract capacity filters and add as minCapacity/maxCapacity
        const { minCapacity, maxCapacity } =
          extractCapacityFilters(memoizedFilters);
        if (minCapacity !== null && minCapacity !== undefined) {
          params.append("minCapacity", minCapacity.toString());
        }
        if (maxCapacity !== null && maxCapacity !== undefined) {
          params.append("maxCapacity", maxCapacity.toString());
        }

        // Extract food price per plate
        const { minFoodPrice, maxFoodPrice } =
          extractFoodPriceFilters(memoizedFilters);
        if (minFoodPrice !== null && minFoodPrice !== undefined) {
          params.append("minFoodPrice", minFoodPrice.toString());
        }
        if (maxFoodPrice !== null && maxFoodPrice !== undefined) {
          params.append("maxFoodPrice", maxFoodPrice.toString());
        }

        // Extract rooms
        const { minRooms, maxRooms } = extractRoomsFilters(memoizedFilters);
        if (minRooms !== null && minRooms !== undefined) {
          params.append("minRooms", minRooms.toString());
        }
        if (maxRooms !== null && maxRooms !== undefined) {
          params.append("maxRooms", maxRooms.toString());
        }

        // Extract rating
        const { minRating, maxRating } = extractRatingFilters(memoizedFilters);
        if (minRating !== null && minRating !== undefined) {
          params.append("minRating", minRating.toString());
        }
        if (maxRating !== null && maxRating !== undefined) {
          params.append("maxRating", maxRating.toString());
        }

        // Extract reviews
        const { minReviews, maxReviews } =
          extractReviewFilters(memoizedFilters);
        if (minReviews !== null && minReviews !== undefined) {
          params.append("minReviews", minReviews.toString());
        }
        if (maxReviews !== null && maxReviews !== undefined) {
          params.append("maxReviews", maxReviews.toString());
        }

        // Add other filters as JSON (excluding price filters)
        const nonPriceFilters = { ...memoizedFilters };
        // Remove price/capacity/venue-type/food price/rooms/rating/reviews keys from filters JSON
        Object.keys(nonPriceFilters).forEach((key) => {
          const lowerKey = key.toLowerCase();
          if (
            lowerKey.includes("price") ||
            lowerKey === "prices" ||
            lowerKey === "pricing" ||
            lowerKey.includes("bridal price") ||
            lowerKey.includes("package price") ||
            lowerKey.includes("price per plate") ||
            lowerKey.includes("price per kg") ||
            lowerKey.includes("price range") ||
            lowerKey.includes("starting price") ||
            lowerKey.includes("decor price") ||
            lowerKey.includes("home function decor") ||
            lowerKey.includes("physical invite price") ||
            lowerKey.includes("pricing for 200 guests") ||
            lowerKey === "capacity" ||
            lowerKey === "venue type" ||
            lowerKey === "rooms" ||
            lowerKey === "rating" ||
            lowerKey === "review count"
          ) {
            delete nonPriceFilters[key];
          }
        });

        if (nonPriceFilters && Object.keys(nonPriceFilters).length > 0) {
          params.append("filters", JSON.stringify(nonPriceFilters));
        }

        const apiBaseUrl = import.meta.env.VITE_API_URL || "http://localhost:4000/api";
        const apiUrl = `${apiBaseUrl}/vendor-services?${params.toString()}`;

        const cacheKey = apiUrl;
        if (cacheRef.current.has(cacheKey)) {
          const cached = cacheRef.current.get(cacheKey);
          setData(cached.data);
          setPagination(cached.pagination);
          setLoading(false);
          return;
        }

        if (abortRef.current) {
          abortRef.current.abort();
        }
        const controller = new AbortController();
        abortRef.current = controller;
        const timeoutId = setTimeout(() => controller.abort(), 20000);
        const response = await fetch(apiUrl, { signal: controller.signal });
        clearTimeout(timeoutId);

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const result = await response.json();

        const itemsRaw = Array.isArray(result)
          ? result
          : Array.isArray(result.data)
            ? result.data
            : [];

        const VENUE_FALLBACK_IMG = "/images/imageNotFound.jpg";

        const transformed = transformApiData(itemsRaw).map((item) => {
          if (!item) return null;
          if (!item.image || String(item.image).trim() === "") {
            item.image = VENUE_FALLBACK_IMG;
          }
          return item;
        }).filter(Boolean);

        if (Array.isArray(result)) {
          const total = itemsRaw.length;
          const start = (page - 1) * limit;
          const pagedItems = itemsRaw.slice(start, start + limit);
          const transformed = transformApiData(pagedItems).map((item) => {
            if (!item) return null;
            if (!item.image || String(item.image).trim() === "") {
              item.image = VENUE_FALLBACK_IMG;
            }
            return item;
          }).filter(Boolean);
          setData(transformed);
          const nextPagination = {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit),
          };
          setPagination(nextPagination);
          cacheRef.current.set(cacheKey, {
            data: transformed,
            pagination: nextPagination,
          });
        } else {
          const transformed = transformApiData(itemsRaw).map((item) => {
            if (!item) return null;
            if (!item.image || String(item.image).trim() === "") {
              item.image = VENUE_FALLBACK_IMG;
            }
            return item;
          }).filter(Boolean);
          setData(transformed);
          if (result.pagination) {
            const nextPagination = {
              page: result.pagination.page || page,
              limit: result.pagination.limit || limit,
              total: result.pagination.total || 0,
              totalPages: result.pagination.totalPages || 0,
            };
            const paginationData = {
              page: result.pagination.page || page,
              limit: result.pagination.limit || limit,
              total: result.pagination.total || 0,
              totalPages: result.pagination.totalPages || 0,
            };
            "useApiData - Pagination data:", paginationData;
            setPagination(nextPagination);
            cacheRef.current.set(cacheKey, {
              data: transformed,
              pagination: nextPagination,
            });
          }
        }
      } catch (err) {
        if (err.name === "AbortError") {
          return;
        }
        setError(`Failed to load ${section} data from API: ${err.message}`);
        setData([]);
      } finally {
        setLoading(false);
      }
    },
    [
      section,
      slug,
      city,
      vendorType,
      initialPage,
      initialLimit,
      memoizedFilters,
    ]
  );

  const refetch = useCallback(() => {
    fetchData(pagination.page, pagination.limit);
  }, [fetchData, pagination.page, pagination.limit]);

  const goToPage = useCallback(
    (page) => {
      if (page < 1 || page > pagination.totalPages) {
        return;
      }
      fetchData(page);
    },
    [fetchData, pagination.totalPages]
  );

  const nextPage = useCallback(() => {
    if (pagination.page < pagination.totalPages) {
      goToPage(pagination.page + 1);
    }
  }, [pagination.page, pagination.totalPages, goToPage]);

  const prevPage = useCallback(() => {
    if (pagination.page > 1) {
      goToPage(pagination.page - 1);
    }
  }, [pagination.page, goToPage]);

  const loadMore = useCallback(() => {
    if (pagination.page < pagination.totalPages) {
      nextPage();
    }
  }, [pagination.page, pagination.totalPages, nextPage]);

  useEffect(() => {
    fetchData(initialPage, initialLimit);
  }, [fetchData, initialPage, initialLimit]);

  return {
    data,
    loading,
    error,
    pagination,
    refetch,
    goToPage,
    nextPage,
    prevPage,
    loadMore,
    hasMore: pagination.page < pagination.totalPages,
  };
};

const transformApiData = (items) => {
  return items.map((item) => {
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

    const priceOrZero = (v) => (v === null || v === undefined ? 0 : v);

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
      status: normalizeServiceStatus(item.status),
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

      address: (attributes.address && attributes.address.toLowerCase() !== "unknown") ? attributes.address : (attributes.Address && attributes.Address.toLowerCase() !== "unknown") ? attributes.Address : "",
      area: (attributes.area && attributes.area.toLowerCase() !== "unknown") ? attributes.area : "",
      city: (attributes.city && attributes.city.toLowerCase() !== "unknown") ? attributes.city : (vendor.city && vendor.city.toLowerCase() !== "unknown") ? vendor.city : "",
      location: (attributes.city && attributes.city.toLowerCase() !== "unknown") ? attributes.city : (vendor.city && vendor.city.toLowerCase() !== "unknown") ? vendor.city : "",
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
    };
  }).filter((item) => item && item.image && String(item.image).trim() !== "");
};

export default useApiData;
