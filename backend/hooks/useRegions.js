import { useCallback, useEffect, useState } from "react";
import axios from "axios";
import cityImages from "../data/cityImages";

const useRegions = (vendorType = null) => {
  const [regions, setRegions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchVendors = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const baseUrl = "https://happywedz.com/api/vendor-services/";

      const initialUrl = vendorType
        ? `${baseUrl}?vendorType=${encodeURIComponent(vendorType)}&limit=100`
        : `${baseUrl}?limit=100`;

      const { data } = await axios.get(initialUrl);
      const items = data.data || [];

      const uniqueCities = new Set();
      items.forEach((item) => {
        let city = null;
        if (item?.attributes?.city) {
          city = String(item.attributes.city).trim();
        } else if (item?.attributes?.location?.city) {
          city = String(item.attributes.location.city).trim();
        } else if (item?.vendor?.city) {
          city = String(item.vendor.city).trim();
        }
        if (!city) return;

        const matchedKey = Object.keys(cityImages).find((k) => {
          const cityLower = city.toLowerCase();
          const keyLower = k.toLowerCase();
          return cityLower.includes(keyLower) || keyLower.includes(cityLower);
        });

        if (matchedKey) {
          uniqueCities.add(matchedKey);
        }
      });

      const cityMap = {};
      const cityCountPromises = Array.from(uniqueCities).map(
        async (cityName) => {
          try {
            const cityUrl = vendorType
              ? `${baseUrl}?vendorType=${encodeURIComponent(
                  vendorType
                )}&city=${encodeURIComponent(cityName)}&limit=1`
              : `${baseUrl}?city=${encodeURIComponent(cityName)}&limit=1`;

            const response = await axios.get(cityUrl);
            const totalCount = response.data?.pagination?.total || 0;

            return {
              name: cityName,
              count: totalCount,
            };
          } catch (err) {
            console.error(`Error fetching count for ${cityName}:`, err);
            return {
              name: cityName,
              count: 0,
            };
          }
        }
      );

      const cityCounts = await Promise.all(cityCountPromises);

      cityCounts.forEach((cityData, index) => {
        cityMap[cityData.name] = {
          id: index + 1,
          name: cityData.name,
          venueCount: cityData.count,
          image: cityImages[cityData.name],
        };
      });

      const finalRegions = Object.values(cityMap);
      setRegions(finalRegions);
    } catch (err) {
      console.error("Error fetching vendors:", err);
      setError(err);
    } finally {
      setLoading(false);
    }
  }, [vendorType]);

  useEffect(() => {
    fetchVendors();
  }, [fetchVendors]);

  return { regions, loading, error, refetch: fetchVendors };
};

export default useRegions;
