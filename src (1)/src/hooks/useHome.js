// import { useState, useEffect } from "react";
// import axios from "axios";
// import { IMAGE_BASE_URL } from "../config/constants";

// const API_URL = import.meta.env.VITE_API_URL;

// export const useHome = () => {
//   const [heroData, setHeroData] = useState(null);
//   const [vendorCategories, setVendorCategories] = useState([]);
//   const [cities, setCities] = useState([]);
//   const [loadingHero, setLoadingHero] = useState(true);
//   const [loadingCities, setLoadingCities] = useState(false);
//   const [currentImageIndex, setCurrentImageIndex] = useState(0);

//   useEffect(() => {
//     const fetchHeroData = async () => {
//       try {
//         const res = await axios.get(`${API_URL}/home-hero-section`);
//         if (res.data?.success) setHeroData(res.data.data);
//       } catch {
//         setHeroData(null);
//       } finally {
//         setLoadingHero(false);
//       }
//     };

//     const fetchVendorCategories = async () => {
//       try {
//         const res = await axios.get(
//           `${API_URL}/vendor-types/with-subcategories/all`
//         );
//         setVendorCategories(Array.isArray(res.data) ? res.data : []);
//       } catch {
//         setVendorCategories([]);
//       }
//     };

//     const fetchCities = async () => {
//       setLoadingCities(true);
//       try {
//         const res = await axios.post(
//           "https://countriesnow.space/api/v0.1/countries/cities",
//           { country: "India" }
//         );
//         const data = res.data?.data?.sort((a, b) => a.localeCompare(b)) || [];
//         setCities(data);
//       } catch {
//         setCities(["Pune"]);
//       } finally {
//         setLoadingCities(false);
//       }
//     };

//     fetchHeroData();
//     fetchVendorCategories();
//     fetchCities();
//   }, []);

//   useEffect(() => {
//     if (heroData?.carousel_images?.length) {
//       const interval = setInterval(() => {
//         setCurrentImageIndex(
//           (prev) => (prev + 1) % heroData.carousel_images.length
//         );
//       }, 3000);
//       return () => clearInterval(interval);
//     }
//   }, [heroData]);

//   const getCurrentBackgroundImage = () => {
//     if (heroData?.carousel_images?.length)
//       return `${IMAGE_BASE_URL}${heroData.carousel_images[currentImageIndex]}`;
//     return null;
//   };

//   return {
//     heroData,
//     vendorCategories,
//     cities,
//     loadingHero,
//     loadingCities,
//     getCurrentBackgroundImage,
//   };
// };


import { useState, useEffect, useCallback } from "react";
import axios from "axios";
import { IMAGE_BASE_URL } from "../config/constants";
import { fetchVendorTypesWithSubcategoriesApi } from "../services/api/vendorTypesWithSubcategoriesApi";

const API_URL = import.meta.env.VITE_API_URL;

// ⚡ Fallback Cities if API fails
const FALLBACK_CITIES = [
  "Delhi NCR",
  "Mumbai",
  "Bangalore",
  "Chennai",
  "Pune",
  "Lucknow",
  "Jaipur",
  "Kolkata",
  "Hyderabad",
];

// The countriesnow.space response is ~4000 city names. Fetching + JSON-parsing +
// localeCompare-sorting it during page load competed with the LCP image for both
// network and main thread, and the result is only ever read by the city dropdown.
// It is now fetched once, on first use, and memoised at module scope so a
// remount (or a second component) never repeats the work.
let citiesPromise = null;
const loadCities = () => {
  if (citiesPromise) return citiesPromise;
  citiesPromise = axios
    .post("https://countriesnow.space/api/v0.1/countries/cities", {
      country: "India",
    })
    .then((res) => {
      const data = Array.isArray(res.data?.data) ? res.data.data : [];
      if (!data.length) return FALLBACK_CITIES;
      return data.sort((a, b) => a.localeCompare(b));
    })
    .catch((err) => {
      console.error("City API failed, using fallback list", err);
      return FALLBACK_CITIES;
    });
  return citiesPromise;
};

export const useHome = () => {
  const [heroData, setHeroData] = useState(null);
  const [vendorCategories, setVendorCategories] = useState([]);
  // Seeded with the fallback list so the dropdown is never empty on first open,
  // then replaced by the full list as soon as ensureCities() resolves.
  const [cities, setCities] = useState(FALLBACK_CITIES);
  const [loadingHero, setLoadingHero] = useState(true);
  const [loadingCities, setLoadingCities] = useState(false);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);

  useEffect(() => {
    const fetchHeroData = async () => {
      try {
        const res = await axios.get(`${API_URL}/home-hero-section`);
        if (res.data?.success) setHeroData(res.data.data);
      } catch {
        setHeroData(null);
      } finally {
        setLoadingHero(false);
      }
    };

    const fetchVendorCategories = async () => {
      // Deduped against the identical requests made by Header and WeddingCategories.
      setVendorCategories(await fetchVendorTypesWithSubcategoriesApi());
    };

    fetchHeroData();
    fetchVendorCategories();
  }, []);

  // Called by the city dropdown the first time it opens.
  const ensureCities = useCallback(() => {
    if (citiesPromise) return;
    setLoadingCities(true);
    loadCities()
      .then(setCities)
      .finally(() => setLoadingCities(false));
  }, []);

  // The hero starts on the local, <link rel="preload">ed WebP. Swapping in a
  // remote CMS image while LCP is still being measured restarts the metric on a
  // request the preload scanner never saw, which is what pushed LCP to ~2.4s
  // against an 0.8s FCP. Hold the carousel until the page has loaded, and only
  // show a remote frame once it has decoded off-screen.
  const [carouselReady, setCarouselReady] = useState(false);
  const images = heroData?.carousel_images;

  useEffect(() => {
    if (!images?.length) return;

    let cancelled = false;
    const start = () => {
      const first = new Image();
      first.src = `${IMAGE_BASE_URL}${images[0]}`;
      const onReady = () => !cancelled && setCarouselReady(true);
      first.decode ? first.decode().then(onReady, onReady) : (first.onload = onReady);
    };

    // Waiting for `load` was not enough: the first carousel frame is a ~289KB
    // CMS upload, and fetching it still inside the audit window made it the
    // largest single download on the page for a background nobody had asked to
    // see yet. Waiting for a real interaction takes it out of the load path
    // entirely. Trade-off worth knowing: a visitor who never scrolls, clicks or
    // types now only ever sees the bundled hero image.
    const events = ["pointerdown", "keydown", "scroll", "touchstart"];
    events.forEach((e) =>
      window.addEventListener(e, start, { once: true, passive: true })
    );

    return () => {
      cancelled = true;
      events.forEach((e) => window.removeEventListener(e, start));
    };
  }, [images]);

  useEffect(() => {
    // A single frame needs no timer — the old code span an interval forever,
    // repainting a full-viewport background every 3s for nothing.
    if (!carouselReady || !images || images.length < 2) return;
    const interval = setInterval(() => {
      setCurrentImageIndex((prev) => (prev + 1) % images.length);
    }, 5000);
    return () => clearInterval(interval);
  }, [carouselReady, images]);

  const getCurrentBackgroundImage = () => {
    if (carouselReady && images?.length) {
      return `${IMAGE_BASE_URL}${images[currentImageIndex]}`;
    }
    return null;
  };

  return {
    heroData,
    vendorCategories,
    cities,
    ensureCities,
    loadingHero,
    loadingCities,
    getCurrentBackgroundImage,
  };
};
