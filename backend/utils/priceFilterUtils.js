// export const parsePriceRange = (rangeString) => {
//     if (!rangeString || typeof rangeString !== "string") {
//         return null;
//     }

//     // Remove commas and convert to lowercase
//     const cleanRange = rangeString.replace(/,/g, "").trim().toLowerCase();

//     // Handle "less than" or "under" ranges
//     if (cleanRange.startsWith("<") || cleanRange.startsWith("under")) {
//         const value = parseInt(cleanRange.replace(/[^0-9]/g, ""));
//         if (!isNaN(value) && value > 0) {
//             return { min: null, max: value - 1 }; // max is exclusive, so subtract 1
//         }
//         return null;
//     }

//     // Handle "greater than" ranges with +
//     if (cleanRange.includes("+")) {
//         const value = parseInt(cleanRange.replace(/[^0-9]/g, ""));
//         if (!isNaN(value) && value > 0) {
//             return { min: value, max: null };
//         }
//         return null;
//     }

//     // Handle range with dash or hyphen
//     if (cleanRange.includes("-")) {
//         const parts = cleanRange.split("-").map((p) => {
//             // Handle cases like "1,00,000-2,00,000" or "1,20,000"
//             const cleaned = p.trim().replace(/[^0-9]/g, "");
//             return parseInt(cleaned);
//         });

//         if (parts.length >= 2 && !isNaN(parts[0]) && !isNaN(parts[1])) {
//             // Ensure min <= max
//             const min = Math.min(parts[0], parts[1]);
//             const max = Math.max(parts[0], parts[1]);
//             return { min, max };
//         }

//         // Try to parse as single value if split didn't work well
//         const singleValue = parseInt(cleanRange.replace(/[^0-9]/g, ""));
//         if (!isNaN(singleValue) && singleValue > 0) {
//             return { min: null, max: singleValue };
//         }

//         return null;
//     }

//     // Handle single value (treated as max)
//     const value = parseInt(cleanRange.replace(/[^0-9]/g, ""));
//     if (!isNaN(value) && value > 0) {
//         return { min: null, max: value };
//     }

//     return null;
// };

// /**
//  * Extract price filters from activeFilters and calculate overall min/max
//  * @param {Object} activeFilters - Active filters object from useFilters hook
//  * @returns {Object} - { minPrice: number | null, maxPrice: number | null }
//  */
// export const extractPriceFilters = (activeFilters) => {
//     if (!activeFilters || typeof activeFilters !== "object") {
//         return { minPrice: null, maxPrice: null };
//     }

//     const priceRanges = [];

//     // Find all price-related filter keys
//     const priceKeys = Object.keys(activeFilters).filter((key) => {
//         const lowerKey = key.toLowerCase();
//         return (
//             lowerKey.includes("price") ||
//             lowerKey === "prices" ||
//             lowerKey === "pricing" ||
//             lowerKey.includes("bridal price") ||
//             lowerKey.includes("package price") ||
//             lowerKey.includes("price per plate") ||
//             lowerKey.includes("price per kg") ||
//             lowerKey.includes("price range") ||
//             lowerKey.includes("starting price") ||
//             lowerKey.includes("decor price") ||
//             lowerKey.includes("home function decor") ||
//             lowerKey.includes("physical invite price") ||
//             lowerKey.includes("pricing for 200 guests")
//         );
//     });

//     // Parse all price range values
//     priceKeys.forEach((key) => {
//         const values = activeFilters[key];
//         if (Array.isArray(values)) {
//             values.forEach((value) => {
//                 const parsed = parsePriceRange(value);
//                 if (parsed) {
//                     priceRanges.push(parsed);
//                 }
//             });
//         }
//     });

//     if (priceRanges.length === 0) {
//         return { minPrice: null, maxPrice: null };
//     }

//     // Calculate overall min and max from all selected ranges
//     // When multiple ranges are selected, we use UNION logic (bounding box)
//     // that covers all selected ranges. This allows vendors matching any of the ranges.
//     let minPrice = null;
//     let maxPrice = null;

//     const validMins = priceRanges
//         .map((r) => r.min)
//         .filter((m) => m !== null && m !== undefined);
//     const validMaxs = priceRanges
//         .map((r) => r.max)
//         .filter((m) => m !== null && m !== undefined);

//     // For UNION: use the lowest min and highest max to cover all ranges
//     if (validMins.length > 0) {
//         // Use the lowest min (least restrictive lower bound to cover all ranges)
//         minPrice = Math.min(...validMins);
//     }

//     if (validMaxs.length > 0) {
//         // Use the highest max (least restrictive upper bound to cover all ranges)
//         maxPrice = Math.max(...validMaxs);
//     }

//     // Special case: if we have ranges with only max (e.g., "<40,000") and ranges with only min (e.g., "1,60,000+")
//     // We should include both, so minPrice can be 0 if we have any max-only ranges
//     const hasMaxOnlyRanges = priceRanges.some(
//         (r) => r.min === null && r.max !== null
//     );
//     const hasMinOnlyRanges = priceRanges.some(
//         (r) => r.min !== null && r.max === null
//     );

//     // If we have both max-only and min-only ranges, we want everything, so don't filter
//     if (
//         hasMaxOnlyRanges &&
//         hasMinOnlyRanges &&
//         validMins.length > 0 &&
//         validMaxs.length > 0
//     ) {
//         // Check if the ranges overlap
//         const lowestMax = Math.min(...validMaxs);
//         const highestMin = Math.max(...validMins);

//         // If they don't overlap (e.g., max=40000 and min=160000), return null to show all
//         if (lowestMax < highestMin) {
//             return { minPrice: null, maxPrice: null };
//         }
//     }

//     // If we have both min and max, ensure min <= max
//     if (minPrice !== null && maxPrice !== null && minPrice > maxPrice) {
//         // Invalid range, return null to skip price filtering
//         return { minPrice: null, maxPrice: null };
//     }

//     return { minPrice, maxPrice };
// };

// // ---------------- Additional Venue helpers ----------------

// // Parse a capacity range string like "<100", "100-200", "500-1000", "1000+"
// export const parseCapacityRange = (rangeString) => {
//     if (!rangeString || typeof rangeString !== "string") return null;
//     const clean = rangeString.replace(/,/g, "").trim().toLowerCase();

//     if (clean.startsWith("<") || clean.startsWith("under")) {
//         const v = parseInt(clean.replace(/[^0-9]/g, ""));
//         if (!isNaN(v) && v > 0) return { min: null, max: v - 1 };
//         return null;
//     }

//     if (clean.includes("+")) {
//         const v = parseInt(clean.replace(/[^0-9]/g, ""));
//         if (!isNaN(v) && v > 0) return { min: v, max: null };
//         return null;
//     }

//     if (clean.includes("-")) {
//         const [a, b] = clean.split("-").map((p) => parseInt(p.replace(/[^0-9]/g, "")));
//         if (!isNaN(a) && !isNaN(b)) {
//             const min = Math.min(a, b);
//             const max = Math.max(a, b);
//             return { min, max };
//         }
//     }

//     const v = parseInt(clean.replace(/[^0-9]/g, ""));
//     if (!isNaN(v) && v > 0) return { min: null, max: v };
//     return null;
// };

// // Extract capacity min/max from active filters (UNION bounding box)
// export const extractCapacityFilters = (activeFilters) => {
//     if (!activeFilters || typeof activeFilters !== "object") {
//         return { minCapacity: null, maxCapacity: null };
//     }
//     const capacityKey = Object.keys(activeFilters).find(
//         (k) => k.toLowerCase() === "capacity"
//     );
//     if (!capacityKey) return { minCapacity: null, maxCapacity: null };

//     const ranges = (activeFilters[capacityKey] || [])
//         .map((v) => parseCapacityRange(v))
//         .filter(Boolean);
//     if (ranges.length === 0) return { minCapacity: null, maxCapacity: null };

//     const mins = ranges.map((r) => r.min).filter((x) => x !== null && x !== undefined);
//     const maxs = ranges.map((r) => r.max).filter((x) => x !== null && x !== undefined);

//     let minCapacity = null;
//     let maxCapacity = null;
//     if (mins.length > 0) minCapacity = Math.min(...mins);
//     if (maxs.length > 0) maxCapacity = Math.max(...maxs);

//     if (minCapacity !== null && maxCapacity !== null && minCapacity > maxCapacity) {
//         return { minCapacity: null, maxCapacity: null };
//     }
//     return { minCapacity, maxCapacity };
// };

// // Extract selected venue subcategories from "venue Type" group and join comma-separated
// export const extractVenueSubCategories = (activeFilters) => {
//     if (!activeFilters || typeof activeFilters !== "object") return null;
//     const key = Object.keys(activeFilters).find(
//         (k) => k.toLowerCase() === "venue type"
//     );
//     if (!key) return null;
//     const values = activeFilters[key];
//     if (!Array.isArray(values) || values.length === 0) return null;
//     // API accepts comma-separated subCategory list; use as-is
//     return values.join(",");
// };

// // ---------------- Venues: Price Per Plate (Food) ----------------
// export const extractFoodPriceFilters = (activeFilters) => {
//     if (!activeFilters || typeof activeFilters !== "object") {
//         return { minFoodPrice: null, maxFoodPrice: null };
//     }
//     const key = Object.keys(activeFilters).find(
//         (k) => k.toLowerCase() === "price per plate"
//     );
//     if (!key) return { minFoodPrice: null, maxFoodPrice: null };
//     const ranges = (activeFilters[key] || [])
//         .map((v) => parsePriceRange(v))
//         .filter(Boolean);
//     if (ranges.length === 0) return { minFoodPrice: null, maxFoodPrice: null };

//     const mins = ranges.map((r) => r.min).filter((x) => x !== null && x !== undefined);
//     const maxs = ranges.map((r) => r.max).filter((x) => x !== null && x !== undefined);
//     let minFoodPrice = null;
//     let maxFoodPrice = null;
//     if (mins.length > 0) minFoodPrice = Math.min(...mins);
//     if (maxs.length > 0) maxFoodPrice = Math.max(...maxs);
//     if (
//         minFoodPrice !== null &&
//         maxFoodPrice !== null &&
//         minFoodPrice > maxFoodPrice
//     ) {
//         return { minFoodPrice: null, maxFoodPrice: null };
//     }
//     return { minFoodPrice, maxFoodPrice };
// };

// // ---------------- Venues: Rooms ----------------
// export const extractRoomsFilters = (activeFilters) => {
//     if (!activeFilters || typeof activeFilters !== "object") {
//         return { minRooms: null, maxRooms: null };
//     }
//     const key = Object.keys(activeFilters).find((k) => k.toLowerCase() === "rooms");
//     if (!key) return { minRooms: null, maxRooms: null };
//     const ranges = (activeFilters[key] || [])
//         .map((v) => parseCapacityRange(v))
//         .filter(Boolean);
//     if (ranges.length === 0) return { minRooms: null, maxRooms: null };
//     const mins = ranges.map((r) => r.min).filter((x) => x !== null && x !== undefined);
//     const maxs = ranges.map((r) => r.max).filter((x) => x !== null && x !== undefined);
//     let minRooms = null;
//     let maxRooms = null;
//     if (mins.length > 0) minRooms = Math.min(...mins);
//     if (maxs.length > 0) maxRooms = Math.max(...maxs);
//     if (minRooms !== null && maxRooms !== null && minRooms > maxRooms) {
//         return { minRooms: null, maxRooms: null };
//     }
//     return { minRooms, maxRooms };
// };

// // ---------------- Rating ----------------
// const parseRatingToken = (token) => {
//     const t = token.toLowerCase();
//     if (t.includes("all")) return { min: null, max: null };
//     // forms: "rated <4", "rated 4+", "rated 4.5+", "4+", "<4", "rated 4"
//     const num = parseFloat(t.replace(/[^0-9.]/g, ""));
//     if (isNaN(num)) return null;
//     if (t.includes("<")) return { min: null, max: num };
//     if (t.includes("+")) return { min: num, max: null };
//     // exact value fallback -> treat as min
//     return { min: num, max: null };
// };

// export const extractRatingFilters = (activeFilters) => {
//     if (!activeFilters || typeof activeFilters !== "object") {
//         return { minRating: null, maxRating: null };
//     }
//     const key = Object.keys(activeFilters).find((k) => k.toLowerCase() === "rating");
//     if (!key) return { minRating: null, maxRating: null };
//     const parts = (activeFilters[key] || [])
//         .map((v) => parseRatingToken(v))
//         .filter(Boolean);
//     if (parts.length === 0) return { minRating: null, maxRating: null };
//     const mins = parts.map((r) => r.min).filter((x) => x !== null && x !== undefined);
//     const maxs = parts.map((r) => r.max).filter((x) => x !== null && x !== undefined);
//     let minRating = null;
//     let maxRating = null;
//     if (mins.length > 0) minRating = Math.min(...mins);
//     if (maxs.length > 0) maxRating = Math.max(...maxs);
//     if (minRating !== null && maxRating !== null && minRating > maxRating) {
//         return { minRating: null, maxRating: null };
//     }
//     return { minRating, maxRating };
// };

// // ---------------- Reviews ----------------
// const parseReviewToken = (token) => {
//     const t = token.toLowerCase();
//     const num = parseInt(t.replace(/[^0-9]/g, ""));
//     if (isNaN(num)) return null;
//     if (t.includes("<")) return { min: null, max: num };
//     if (t.includes("+")) return { min: num, max: null };
//     return { min: num, max: null };
// };

// export const extractReviewFilters = (activeFilters) => {
//     if (!activeFilters || typeof activeFilters !== "object") {
//         return { minReviews: null, maxReviews: null };
//     }
//     const key = Object.keys(activeFilters).find(
//         (k) => k.toLowerCase() === "review count"
//     );
//     if (!key) return { minReviews: null, maxReviews: null };
//     const parts = (activeFilters[key] || [])
//         .map((v) => parseReviewToken(v))
//         .filter(Boolean);
//     if (parts.length === 0) return { minReviews: null, maxReviews: null };
//     const mins = parts.map((r) => r.min).filter((x) => x !== null && x !== undefined);
//     const maxs = parts.map((r) => r.max).filter((x) => x !== null && x !== undefined);
//     let minReviews = null;
//     let maxReviews = null;
//     if (mins.length > 0) minReviews = Math.min(...mins);
//     if (maxs.length > 0) maxReviews = Math.max(...maxs);
//     if (minReviews !== null && maxReviews !== null && minReviews > maxReviews) {
//         return { minReviews: null, maxReviews: null };
//     }
//     return { minReviews, maxReviews };
// };


export const parsePriceRange = (rangeString) => {
    if (!rangeString || typeof rangeString !== "string") {
        return null;
    }

    // Remove commas and convert to lowercase
    const cleanRange = rangeString.replace(/,/g, "").trim().toLowerCase();

    // Handle "less than" or "under" ranges
    if (cleanRange.startsWith("<") || cleanRange.startsWith("under")) {
        const value = parseInt(cleanRange.replace(/[^0-9]/g, ""));
        if (!isNaN(value) && value > 0) {
            return { min: null, max: value - 1 }; // max is exclusive, so subtract 1
        }
        return null;
    }

    // Handle "greater than" ranges with +
    if (cleanRange.includes("+")) {
        const value = parseInt(cleanRange.replace(/[^0-9]/g, ""));
        if (!isNaN(value) && value > 0) {
            return { min: value, max: null };
        }
        return null;
    }

    // Handle range with dash or hyphen
    if (cleanRange.includes("-")) {
        const parts = cleanRange.split("-").map((p) => {
            // Handle cases like "1,00,000-2,00,000" or "1,20,000"
            const cleaned = p.trim().replace(/[^0-9]/g, "");
            return parseInt(cleaned);
        });

        if (parts.length >= 2 && !isNaN(parts[0]) && !isNaN(parts[1])) {
            // Ensure min <= max
            const min = Math.min(parts[0], parts[1]);
            const max = Math.max(parts[0], parts[1]);
            return { min, max };
        }

        // Try to parse as single value if split didn't work well
        const singleValue = parseInt(cleanRange.replace(/[^0-9]/g, ""));
        if (!isNaN(singleValue) && singleValue > 0) {
            return { min: null, max: singleValue };
        }

        return null;
    }

    // Handle single value (treated as max)
    const value = parseInt(cleanRange.replace(/[^0-9]/g, ""));
    if (!isNaN(value) && value > 0) {
        return { min: null, max: value };
    }

    return null;
};

/**
 * Extract price filters from activeFilters and calculate overall min/max
 * EXCLUDES "Price Per Plate" to avoid conflict with food price filters
 * @param {Object} activeFilters - Active filters object from useFilters hook
 * @returns {Object} - { minPrice: number | null, maxPrice: number | null }
 */
export const extractPriceFilters = (activeFilters) => {
    if (!activeFilters || typeof activeFilters !== "object") {
        return { minPrice: null, maxPrice: null };
    }

    const priceRanges = [];

    // Find all price-related filter keys
    // IMPORTANT: Exclude "price per plate" - it's handled separately
    const priceKeys = Object.keys(activeFilters).filter((key) => {
        const lowerKey = key.toLowerCase();
        return (
            (lowerKey.includes("price") ||
                lowerKey === "prices" ||
                lowerKey === "pricing" ||
                lowerKey.includes("bridal price") ||
                lowerKey.includes("package price") ||
                lowerKey.includes("price range") ||
                lowerKey.includes("starting price") ||
                lowerKey.includes("decor price") ||
                lowerKey.includes("home function decor") ||
                lowerKey.includes("physical invite price") ||
                lowerKey.includes("pricing for 200 guests")) &&
            // EXCLUDE price per plate and price per kg - they have dedicated extractors
            !lowerKey.includes("price per plate") &&
            !lowerKey.includes("price per kg")
        );
    });

    // Parse all price range values
    priceKeys.forEach((key) => {
        const values = activeFilters[key];
        if (Array.isArray(values)) {
            values.forEach((value) => {
                const parsed = parsePriceRange(value);
                if (parsed) {
                    priceRanges.push(parsed);
                }
            });
        }
    });

    if (priceRanges.length === 0) {
        return { minPrice: null, maxPrice: null };
    }

    // Calculate overall min and max from all selected ranges
    // When multiple ranges are selected, we use UNION logic (bounding box)
    // that covers all selected ranges. This allows vendors matching any of the ranges.
    let minPrice = null;
    let maxPrice = null;

    const validMins = priceRanges
        .map((r) => r.min)
        .filter((m) => m !== null && m !== undefined);
    const validMaxs = priceRanges
        .map((r) => r.max)
        .filter((m) => m !== null && m !== undefined);

    // For UNION: use the lowest min and highest max to cover all ranges
    if (validMins.length > 0) {
        // Use the lowest min (least restrictive lower bound to cover all ranges)
        minPrice = Math.min(...validMins);
    }

    if (validMaxs.length > 0) {
        // Use the highest max (least restrictive upper bound to cover all ranges)
        maxPrice = Math.max(...validMaxs);
    }

    // Special case: if we have ranges with only max (e.g., "<40,000") and ranges with only min (e.g., "1,60,000+")
    // We should include both, so minPrice can be 0 if we have any max-only ranges
    const hasMaxOnlyRanges = priceRanges.some(
        (r) => r.min === null && r.max !== null
    );
    const hasMinOnlyRanges = priceRanges.some(
        (r) => r.min !== null && r.max === null
    );

    // If we have both max-only and min-only ranges, we want everything, so don't filter
    if (
        hasMaxOnlyRanges &&
        hasMinOnlyRanges &&
        validMins.length > 0 &&
        validMaxs.length > 0
    ) {
        // Check if the ranges overlap
        const lowestMax = Math.min(...validMaxs);
        const highestMin = Math.max(...validMins);

        // If they don't overlap (e.g., max=40000 and min=160000), return null to show all
        if (lowestMax < highestMin) {
            return { minPrice: null, maxPrice: null };
        }
    }

    // If we have both min and max, ensure min <= max
    if (minPrice !== null && maxPrice !== null && minPrice > maxPrice) {
        // Invalid range, return null to skip price filtering
        return { minPrice: null, maxPrice: null };
    }

    return { minPrice, maxPrice };
};

// ---------------- Additional Venue helpers ----------------

// Parse a capacity range string like "<100", "100-200", "500-1000", "1000+"
export const parseCapacityRange = (rangeString) => {
    if (!rangeString || typeof rangeString !== "string") return null;
    const clean = rangeString.replace(/,/g, "").trim().toLowerCase();

    if (clean.startsWith("<") || clean.startsWith("under")) {
        const v = parseInt(clean.replace(/[^0-9]/g, ""));
        if (!isNaN(v) && v > 0) return { min: null, max: v - 1 };
        return null;
    }

    if (clean.includes("+")) {
        const v = parseInt(clean.replace(/[^0-9]/g, ""));
        if (!isNaN(v) && v > 0) return { min: v, max: null };
        return null;
    }

    if (clean.includes("-")) {
        const [a, b] = clean.split("-").map((p) => parseInt(p.replace(/[^0-9]/g, "")));
        if (!isNaN(a) && !isNaN(b)) {
            const min = Math.min(a, b);
            const max = Math.max(a, b);
            return { min, max };
        }
    }

    const v = parseInt(clean.replace(/[^0-9]/g, ""));
    if (!isNaN(v) && v > 0) return { min: null, max: v };
    return null;
};

// Extract capacity min/max from active filters (UNION bounding box)
export const extractCapacityFilters = (activeFilters) => {
    if (!activeFilters || typeof activeFilters !== "object") {
        return { minCapacity: null, maxCapacity: null };
    }
    const capacityKey = Object.keys(activeFilters).find(
        (k) => k.toLowerCase() === "capacity"
    );
    if (!capacityKey) return { minCapacity: null, maxCapacity: null };

    const ranges = (activeFilters[capacityKey] || [])
        .map((v) => parseCapacityRange(v))
        .filter(Boolean);
    if (ranges.length === 0) return { minCapacity: null, maxCapacity: null };

    const mins = ranges.map((r) => r.min).filter((x) => x !== null && x !== undefined);
    const maxs = ranges.map((r) => r.max).filter((x) => x !== null && x !== undefined);

    let minCapacity = null;
    let maxCapacity = null;
    if (mins.length > 0) minCapacity = Math.min(...mins);
    if (maxs.length > 0) maxCapacity = Math.max(...maxs);

    if (minCapacity !== null && maxCapacity !== null && minCapacity > maxCapacity) {
        return { minCapacity: null, maxCapacity: null };
    }
    return { minCapacity, maxCapacity };
};

// Extract selected venue subcategories from "venue Type" group and join comma-separated
export const extractVenueSubCategories = (activeFilters) => {
    if (!activeFilters || typeof activeFilters !== "object") return null;
    const key = Object.keys(activeFilters).find(
        (k) => k.toLowerCase() === "venue type"
    );
    if (!key) return null;
    const values = activeFilters[key];
    if (!Array.isArray(values) || values.length === 0) return null;
    // API accepts comma-separated subCategory list; use as-is
    return values.join(",");
};

// ---------------- Venues: Price Per Plate (Food) ----------------
export const extractFoodPriceFilters = (activeFilters) => {
    if (!activeFilters || typeof activeFilters !== "object") {
        return { minFoodPrice: null, maxFoodPrice: null };
    }
    const key = Object.keys(activeFilters).find(
        (k) => k.toLowerCase() === "price per plate"
    );
    if (!key) return { minFoodPrice: null, maxFoodPrice: null };
    const ranges = (activeFilters[key] || [])
        .map((v) => parsePriceRange(v))
        .filter(Boolean);
    if (ranges.length === 0) return { minFoodPrice: null, maxFoodPrice: null };

    const mins = ranges.map((r) => r.min).filter((x) => x !== null && x !== undefined);
    const maxs = ranges.map((r) => r.max).filter((x) => x !== null && x !== undefined);
    let minFoodPrice = null;
    let maxFoodPrice = null;
    if (mins.length > 0) minFoodPrice = Math.min(...mins);
    if (maxs.length > 0) maxFoodPrice = Math.max(...maxs);
    if (
        minFoodPrice !== null &&
        maxFoodPrice !== null &&
        minFoodPrice > maxFoodPrice
    ) {
        return { minFoodPrice: null, maxFoodPrice: null };
    }
    return { minFoodPrice, maxFoodPrice };
};

// ---------------- Venues: Rooms ----------------
export const extractRoomsFilters = (activeFilters) => {
    if (!activeFilters || typeof activeFilters !== "object") {
        return { minRooms: null, maxRooms: null };
    }
    const key = Object.keys(activeFilters).find((k) => k.toLowerCase() === "rooms");
    if (!key) return { minRooms: null, maxRooms: null };
    const ranges = (activeFilters[key] || [])
        .map((v) => parseCapacityRange(v))
        .filter(Boolean);
    if (ranges.length === 0) return { minRooms: null, maxRooms: null };
    const mins = ranges.map((r) => r.min).filter((x) => x !== null && x !== undefined);
    const maxs = ranges.map((r) => r.max).filter((x) => x !== null && x !== undefined);
    let minRooms = null;
    let maxRooms = null;
    if (mins.length > 0) minRooms = Math.min(...mins);
    if (maxs.length > 0) maxRooms = Math.max(...maxs);
    if (minRooms !== null && maxRooms !== null && minRooms > maxRooms) {
        return { minRooms: null, maxRooms: null };
    }
    return { minRooms, maxRooms };
};

// ---------------- Rating ----------------
const parseRatingToken = (token) => {
    const t = token.toLowerCase();
    if (t.includes("all")) return { min: null, max: null };
    // forms: "rated <4", "rated 4+", "rated 4.5+", "4+", "<4", "rated 4"
    const num = parseFloat(t.replace(/[^0-9.]/g, ""));
    if (isNaN(num)) return null;
    if (t.includes("<")) return { min: null, max: num };
    if (t.includes("+")) return { min: num, max: null };
    // exact value fallback -> treat as min
    return { min: num, max: null };
};

export const extractRatingFilters = (activeFilters) => {
    if (!activeFilters || typeof activeFilters !== "object") {
        return { minRating: null, maxRating: null };
    }
    const key = Object.keys(activeFilters).find((k) => k.toLowerCase() === "rating");
    if (!key) return { minRating: null, maxRating: null };
    const parts = (activeFilters[key] || [])
        .map((v) => parseRatingToken(v))
        .filter(Boolean);
    if (parts.length === 0) return { minRating: null, maxRating: null };
    const mins = parts.map((r) => r.min).filter((x) => x !== null && x !== undefined);
    const maxs = parts.map((r) => r.max).filter((x) => x !== null && x !== undefined);
    let minRating = null;
    let maxRating = null;
    if (mins.length > 0) minRating = Math.min(...mins);
    if (maxs.length > 0) maxRating = Math.max(...maxs);
    if (minRating !== null && maxRating !== null && minRating > maxRating) {
        return { minRating: null, maxRating: null };
    }
    return { minRating, maxRating };
};

// ---------------- Reviews ----------------
const parseReviewToken = (token) => {
    const t = token.toLowerCase();
    const num = parseInt(t.replace(/[^0-9]/g, ""));
    if (isNaN(num)) return null;
    if (t.includes("<")) return { min: null, max: num };
    if (t.includes("+")) return { min: num, max: null };
    return { min: num, max: null };
};

export const extractReviewFilters = (activeFilters) => {
    if (!activeFilters || typeof activeFilters !== "object") {
        return { minReviews: null, maxReviews: null };
    }
    const key = Object.keys(activeFilters).find(
        (k) => k.toLowerCase() === "review count"
    );
    if (!key) return { minReviews: null, maxReviews: null };
    const parts = (activeFilters[key] || [])
        .map((v) => parseReviewToken(v))
        .filter(Boolean);
    if (parts.length === 0) return { minReviews: null, maxReviews: null };
    const mins = parts.map((r) => r.min).filter((x) => x !== null && x !== undefined);
    const maxs = parts.map((r) => r.max).filter((x) => x !== null && x !== undefined);
    let minReviews = null;
    let maxReviews = null;
    if (mins.length > 0) minReviews = Math.min(...mins);
    if (maxs.length > 0) maxReviews = Math.max(...maxs);
    if (minReviews !== null && maxReviews !== null && minReviews > maxReviews) {
        return { minReviews: null, maxReviews: null };
    }
    return { minReviews, maxReviews };
};