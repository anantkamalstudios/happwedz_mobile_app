import React, { createContext, useContext, useState } from "react";
import Loader from "../ui/Loader";

const LoaderContext = createContext();

export const useLoader = () => useContext(LoaderContext);

const LoaderProvider = ({ children }) => {
  const [loading, setLoading] = useState(true);

  const showLoader = () => setLoading(true);
  const hideLoader = () => setLoading(false);

  // Keep the loading screen visible for exactly 2.5 seconds on initial load
  React.useEffect(() => {
    const timer = setTimeout(() => {
      setLoading(false);
    }, 2500);
    return () => clearTimeout(timer);
  }, []);

  return (
    <LoaderContext.Provider value={{ showLoader, hideLoader }}>
      {children}
      {loading && <Loader />}
    </LoaderContext.Provider>
  );
};

export default LoaderProvider;
