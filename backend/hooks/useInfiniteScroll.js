import { useState, useEffect, useCallback, useRef } from "react";
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

const useInfiniteScroll = (
  section,
  slug,
  city = null,
  vendorType = null,
  initialLimit = 9,
  filters = {}
) => {
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

  const [data, setData] = useState([]);
  /** Start true so listing pages never flash "empty" before the first fetch runs. */
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [hasMore, setHasMore] = useState(true);
  const [page, setPage] = useState(1);

  const abortRef = useRef(null);
  const cacheRef = useRef(new Map());
  const loadedPagesRef = useRef(new Set());
  const debounceTimerRef = useRef(null);
  const filtersRef = useRef(filters);

  // Update filters ref when filters change
  useEffect(() => {
    filtersRef.current = filters;
  }, [filters]);

  // Transform API data
  const transformApiData = useCallback((items) => {
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

      // Parse latitude and longitude from attributes
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
          attributes.vendor_name ||
          attributes.Name ||
          vendor.businessName ||
          "Unknown Vendor",
        lat: hasValidCoordinates ? latitude : null,
        lng: hasValidCoordinates ? longitude : null,
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
          vendor.businessName ||
          attributes.vendor_name ||
          attributes.Name ||
          "",
        url: attributes.Website || attributes.URL || null,
      };
    }).filter((item) => item && item.image && String(item.image).trim() !== "");
  }, []);

  // Fetch data with caching
  const fetchData = useCallback(
    async (pageNum, limit = initialLimit) => {
      if (!section || (!slug && !vendorType)) {
        setData([]);
        setLoading(false);
        return;
      }

      // Check if page already loaded
      if (loadedPagesRef.current.has(pageNum)) {
        return;
      }

      setLoading(true);
      setError(null);

      /** When true, `finally` must not call setLoading(false) — avoids races when navigation aborts the previous request while a new one is loading. */
      let skipLoadingComplete = false;

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
        const selectedSubcats = extractVenueSubCategories(filtersRef.current);
        if (selectedSubcats && selectedSubcats.trim().length > 0) {
          params.append("subCategory", selectedSubcats);
        } else if (
          subCategory &&
          subCategory.toLowerCase() !== "all"
        ) {
          params.append("subCategory", subCategory);
        }

        params.append("page", pageNum.toString());
        params.append("limit", limit.toString());

        if (filtersRef.current?.search) {
          params.append("search", filtersRef.current.search);
        }

        // Extract price filters and add as minPrice/maxPrice query params
        const { minPrice, maxPrice } = extractPriceFilters(filtersRef.current);
        if (minPrice !== null && minPrice !== undefined) {
          params.append("minPrice", minPrice.toString());
        }
        if (maxPrice !== null && maxPrice !== undefined) {
          params.append("maxPrice", maxPrice.toString());
        }

        // Extract capacity filters and add as minCapacity/maxCapacity
        const { minCapacity, maxCapacity } = extractCapacityFilters(
          filtersRef.current
        );
        if (minCapacity !== null && minCapacity !== undefined) {
          params.append("minCapacity", minCapacity.toString());
        }
        if (maxCapacity !== null && maxCapacity !== undefined) {
          params.append("maxCapacity", maxCapacity.toString());
        }

        // Extract food price per plate
        const { minFoodPrice, maxFoodPrice } = extractFoodPriceFilters(
          filtersRef.current
        );
        if (minFoodPrice !== null && minFoodPrice !== undefined) {
          params.append("minFoodPrice", minFoodPrice.toString());
        }
        if (maxFoodPrice !== null && maxFoodPrice !== undefined) {
          params.append("maxFoodPrice", maxFoodPrice.toString());
        }

        // Extract rooms
        const { minRooms, maxRooms } = extractRoomsFilters(filtersRef.current);
        if (minRooms !== null && minRooms !== undefined) {
          params.append("minRooms", minRooms.toString());
        }
        if (maxRooms !== null && maxRooms !== undefined) {
          params.append("maxRooms", maxRooms.toString());
        }

        // Extract rating
        const { minRating, maxRating } = extractRatingFilters(
          filtersRef.current
        );
        if (minRating !== null && minRating !== undefined) {
          params.append("minRating", minRating.toString());
        }
        if (maxRating !== null && maxRating !== undefined) {
          params.append("maxRating", maxRating.toString());
        }

        // Extract reviews
        const { minReviews, maxReviews } = extractReviewFilters(
          filtersRef.current
        );
        if (minReviews !== null && minReviews !== undefined) {
          params.append("minReviews", minReviews.toString());
        }
        if (maxReviews !== null && maxReviews !== undefined) {
          params.append("maxReviews", maxReviews.toString());
        }

        // Add other filters as JSON (excluding price filters)
        const nonPriceFilters = { ...filtersRef.current };
        // Remove search and price/capacity/venue-type/food price/rooms/rating/reviews keys from filters JSON
        Object.keys(nonPriceFilters).forEach((key) => {
          const lowerKey = key.toLowerCase();
          if (
            lowerKey === "search" ||
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

        // Only return vendors whose first media image is confirmed to exist in S3.
        // The batch job (verify-vendor-images.js) sets image_exists = TRUE after verification.
        params.append("image_exists", "true");

        const apiBaseUrl = import.meta.env.VITE_API_URL || "http://localhost:4000/api";
        const apiUrl = `${apiBaseUrl}/vendor-services?${params.toString()}`;
        const cacheKey = apiUrl;

        // Check cache first
        if (cacheRef.current.has(cacheKey)) {
          const cached = cacheRef.current.get(cacheKey);
          if (pageNum === 1) {
            setData(cached.data);
          } else {
            setData((prevData) => {
              const existingIds = new Set(prevData.map((item) => item.id));
              const newItems = cached.data.filter(
                (item) => !existingIds.has(item.id)
              );
              return [...prevData, ...newItems];
            });
          }
          setHasMore(cached.hasMore);
          loadedPagesRef.current.add(pageNum);
          return;
        }

        // Abort any previous request
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

        const transformed = transformApiData(itemsRaw).filter((item) => {
          if (!item.image) return false;
          const imgStr = String(item.image).toLowerCase();
          if (
            imgStr.includes("placeholder") ||
            imgStr.includes("not_found") ||
            imgStr.includes("image_not_found")
          ) {
            return false;
          }
          return true;
        });

        // Determine if there are more pages
        let hasMorePages = true;
        if (result.pagination) {
          hasMorePages = result.pagination.page < result.pagination.totalPages;
        } else if (Array.isArray(result)) {
          // If no pagination info, check if we got a full page
          hasMorePages = transformed.length >= limit;
        }

        // Cache the result
        cacheRef.current.set(cacheKey, {
          data: transformed,
          hasMore: hasMorePages,
        });

        // Add to loaded pages
        loadedPagesRef.current.add(pageNum);

        if (pageNum === 1) {
          setData(transformed);
        } else {
          setData((prevData) => {
            const existingIds = new Set(prevData.map((item) => item.id));
            const newItems = transformed.filter(
              (item) => !existingIds.has(item.id)
            );
            return [...prevData, ...newItems];
          });
        }

        setHasMore(hasMorePages);
      } catch (err) {
        if (err.name === "AbortError") {
          skipLoadingComplete = true;
          return;
        }
        console.error(`❌ Error loading ${section} data:`, err);
        setError(`Failed to load ${section} data from API: ${err.message}`);
        setHasMore(false);
      } finally {
        if (!skipLoadingComplete) {
          setLoading(false);
        }
      }
    },
    [section, slug, city, vendorType, initialLimit, transformApiData]
  );

  // Debounced load more function
  const loadMore = useCallback(() => {
    if (loading || !hasMore) return;

    // Clear existing debounce timer
    if (debounceTimerRef.current) {
      clearTimeout(debounceTimerRef.current);
    }

    // Debounce the API call by 300ms
    debounceTimerRef.current = setTimeout(() => {
      setPage((prevPage) => {
        const nextPage = prevPage + 1;
        fetchData(nextPage, initialLimit);
        return nextPage;
      });
    }, 300);
  }, [loading, hasMore, fetchData, initialLimit]);

  // Reset when dependencies change
  const reset = useCallback(() => {
    setData([]);
    setPage(1);
    setHasMore(true);
    setError(null);
    loadedPagesRef.current.clear();
    setLoading(true);
  }, []);

  // Initial load - reset and fetch when section, slug, city, vendorType, or filters change
  useEffect(() => {
    reset();
    fetchData(1, initialLimit);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [section, slug, city, vendorType, JSON.stringify(filters)]);

  // Cleanup
  useEffect(() => {
    return () => {
      if (abortRef.current) {
        abortRef.current.abort();
      }
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current);
      }
    };
  }, []);

  return {
    data,
    loading,
    error,
    hasMore,
    loadMore,
    reset,
  };
};

export default useInfiniteScroll;
