import React, { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { beautyApi } from "../../../services/api";
import DragScroll from "../../layouts/DragScroll";
import { BarLoader, ClipLoader } from "react-spinners";
import Swal from "sweetalert2";
import { IoClose } from "react-icons/io5";
import { FaHome } from "react-icons/fa";
import { IoIosArrowBack, IoIosArrowForward } from "react-icons/io";
import { Download, Heart, Home, Share } from "lucide-react";
import { MdRestartAlt } from "react-icons/md";
import ReactCompareImage from "react-compare-image";
import { useDispatch, useSelector } from "react-redux";
import { addFavorite, removeFavorite } from "../../../redux/favoriteSlice";
import FavouriteListPopup from "./FavoritesProduct";
import { AiFillHeart } from "react-icons/ai";
import { AiOutlineHeart } from "react-icons/ai";
import {
  ReactCompareSlider,
  ReactCompareSliderImage,
} from "react-compare-slider";
import {
  SLIDER_CATEGORIES,
  buttons,
  DEFAULT_INTENSITIES,
  getErrorMessage,
} from "./Services";

const DEBOUNCE_DELAY = 250;

const FiltersPage = () => {
  const navigate = useNavigate();
  const [categories, setCategories] = React.useState([]);
  const [expandedCatIdx, setExpandedCatIdx] = React.useState(null);
  const [expandedProductId, setExpandedProductId] = React.useState(null);
  const [isApplying, setIsApplying] = React.useState(false);
  const [appliedProducts, setAppliedProducts] = React.useState({});
  const [appliedOrder, setAppliedOrder] = React.useState([]);
  const [intensity, setIntensity] = useState(0.6);
  const [intensities, setIntensities] = useState(DEFAULT_INTENSITIES);
  const [isLoading, setIsLoading] = useState(true);
  const [activeBtn, setActiveBtn] = useState(buttons[0]);
  const debounceTimer = useRef();
  const filterBarRef = useRef(null);
  const [showCompleteLook, setShowCompleteLook] = useState(false);
  const dispatch = useDispatch();
  const [likedProduct, setLikedProduct] = useState(null);
  const [showPopup, setShowPopup] = useState(false);
  const [activeList, setActiveList] = useState(null);

  // Control concurrent apply requests and effect suppression
  const applyAbortRef = useRef(null);
  const applySeqRef = useRef(0);
  const suppressNextEffectRef = useRef(false);
  const lastPayloadRef = useRef("");

  const [showProductDetails, setShowProductDetails] = useState(true);

  const handleActiveList = (list) => {
    setActiveList(list);
    setShowPopup(true);
  };

  // const [isFavorited, setIsFavorited] = useState(false);
  const favorites = useSelector((store) => store.favorites.favorites);
  const isFavorited =
    likedProduct && favorites.some((fav) => fav.id === likedProduct.id);

  const handleClick = () => {
    if (!likedProduct) return;
    if (isFavorited) {
      dispatch(removeFavorite(likedProduct.id));
    } else {
      dispatch(addFavorite(likedProduct));
    }
  };

  const uploadedId = sessionStorage.getItem("try_uploaded_image_id") || null;
  const uploadedPreview = React.useMemo(() => {
    if (!uploadedId) return null;
    const base = import.meta.env.VITE_API_BASE_URL || "/ai/api";
    return `${base}/images/${uploadedId}`;
  }, [uploadedId]);

  const [previewUrl, setPreviewUrl] = React.useState(uploadedPreview);

  React.useEffect(() => {
    setPreviewUrl(uploadedPreview);
  }, [uploadedPreview]);

  React.useEffect(() => {
    const fetchProducts = async () => {
      setIsLoading(true);
      try {
        const response = await beautyApi.getFilteredProducts("MAKEUP");
        console.log(response);

        const items = Array.isArray(response)
          ? response
          : Array.isArray(response?.data)
          ? response.data
          : [];
        setCategories(items);
      } catch (e) {
        console.error("Failed to load products", e);
        const { message, status } = getErrorMessage(e);
        Swal.fire({
          icon: "error",
          title: "Oops...",
          text: message || "Failed to load products.",
        });
      } finally {
        setIsLoading(false);
      }
    };
    fetchProducts();
  }, []);

  const [isCompareMode, setIsCompareMode] = useState(false);
  const originalImageUrl = uploadedPreview;
  const [compareImageUrl, setCompareImageUrl] = useState(previewUrl);
  const [showBackButton, setShowBackButton] = useState(false);
  const [showShareMenu, setShowShareMenu] = useState(false);

  React.useEffect(() => {
    if (isCompareMode) {
      setCompareImageUrl(previewUrl);
    }
  }, [previewUrl, isCompareMode]);

  useEffect(() => {
    if (expandedCatIdx !== null || expandedProductId !== null) {
      setShowBackButton(true);
    } else {
      setShowBackButton(false);
    }
  }, [expandedCatIdx, expandedProductId]);

  const handleSelectCategory = (idx) => {
    setExpandedCatIdx((prev) => (prev === idx ? null : idx));
    setExpandedProductId(null);
  };

  const handleBackToMainFilters = () => {
    if (expandedProductId !== null) {
      setExpandedProductId(null);
    } else if (expandedCatIdx !== null) {
      setExpandedCatIdx(null);
      setExpandedProductId(null);
    }
  };

  const handleSelectProduct = (productId) => {
    setExpandedProductId((prev) => (prev === productId ? null : productId));
    const selectedProduct = categories[expandedCatIdx]?.products?.find(
      (p) => p.id === productId
    );
    if (selectedProduct) {
      setLikedProduct(selectedProduct);
    }
  };

  const handleApplyOne = async (productId, colorHex) => {
    if (!uploadedId) {
      Swal.fire({
        icon: "error",
        title: "Oops...",
        text: "Please upload an image first.",
      });
      navigate("/try/upload");
      return;
    }
    const activeCategoryName = (
      categories[expandedCatIdx]?.product_detailed_category_name || ""
    ).toLowerCase();

    const selected = categories[expandedCatIdx]?.products?.find(
      (p) => p.id === productId
    );

    const newAppliedProducts = {
      ...appliedProducts,
      [activeCategoryName]: {
        productId,
        colorHex,
        categoryName: activeCategoryName,
        product_real_image:
          selected?.product_real_image ||
          selected?.image ||
          selected?.thumbnail ||
          "",
        description:
          // selected?.discription ||
          // selected?.description ||
          selected?.product_name,
        price: selected?.price || "",
      },
    };
    setAppliedProducts(newAppliedProducts);
    setAppliedOrder((prev) => {
      const without = prev.filter((c) => c !== activeCategoryName);
      return [...without, activeCategoryName];
    });
    setShowProductDetails(true);

    suppressNextEffectRef.current = true;
    await applyAllProducts(newAppliedProducts);
  };

  const handleRemoveProduct = (categoryName) => {
    const newAppliedProducts = { ...appliedProducts };
    delete newAppliedProducts[categoryName];
    setAppliedProducts(newAppliedProducts);
    setAppliedOrder((prev) => prev.filter((c) => c !== categoryName));

    if (Object.keys(newAppliedProducts).length === 0) {
      setPreviewUrl(uploadedPreview);
    } else {
      applyAllProducts(newAppliedProducts);
    }
  };

  function findProductImageById(productId, categories) {
    for (const category of categories) {
      if (Array.isArray(category.products)) {
        const product = category.products.find((p) => p.id === productId);
        if (product && product.product_real_image) {
          return product.product_real_image;
        }
      }
    }
    return null;
  }

  const applyAllProducts = async (productsToApply) => {
    if (!uploadedId || Object.keys(productsToApply).length === 0) return;

    const payload = {
      image_id: Number(uploadedId),
      product_ids: Object.values(productsToApply).map((p) => p.productId),
    };

    Object.values(productsToApply).forEach((product) => {
      const { colorHex: hex, categoryName } = product;
      const intensityValue =
        intensities[categoryName] ?? DEFAULT_INTENSITIES[categoryName] ?? 0.6;

      switch (categoryName) {
        case "blush":
          payload.blush_color = hex;
          payload.blush_intensity = intensityValue;
          payload.blush_radius = 60;
          break;
        case "lipstick":
          payload.lipstick_color = hex;
          payload.lipstick_intensity = intensityValue;
          break;
        case "eyeshadow":
          payload.eyeshadow_color = hex;
          payload.eyeshadow_intensity = intensityValue;
          payload.eyeshadow_thickness = 30;
          break;
        case "contactlenses":
          payload.contactlenses_color = hex;
          payload.contactlenses_intensity = 0.2;
          payload.contactlenses_radius_scale = 1.3;
          break;
        case "foundation":
          payload.foundation_color = hex;
          payload.foundation_intensity = intensityValue;
          break;
        case "kajal":
          payload.kajal_color = hex;
          payload.kajal_intensity = intensityValue;
          break;
        case "concealer":
          payload.concealer_color = hex;
          payload.concealer_intensity = intensityValue;
          break;
        case "contour":
          payload.contour_color = hex;
          payload.contour_intensity = intensityValue;
          break;
        case "bindi":
          payload.bindi_color = hex;
          payload.bindi_size = intensityValue;
          break;
        case "mascara":
          payload.mascara_color = hex;
          payload.mascara_intensity = intensityValue;
          break;
        case "eyeliner":
          payload.eyeliner_color = hex;
          payload.eyeliner_intensity = intensityValue;
          break;
        default:
          // payload.lipstick_color = hex;
          // payload.lipstick_intensity = intensityValue;
          break;
      }
    });

    const payloadKey = JSON.stringify(payload);
    if (payloadKey === lastPayloadRef.current) {
      return;
    }

    if (applyAbortRef.current) {
      try {
        applyAbortRef.current.abort();
      } catch {}
    }
    const controller = new AbortController();
    applyAbortRef.current = controller;
    const mySeq = ++applySeqRef.current;

    try {
      setIsApplying(true);
      const res = await beautyApi.applyMakeup(payload, controller.signal);
      if (mySeq !== applySeqRef.current) return;

      lastPayloadRef.current = payloadKey;

      const processedUrl = res?.url || res?.data?.url || res?.image_url;
      const processedId =
        res?.processed_image_id || res?.data?.processed_image_id;

      if (processedUrl) {
        if (import.meta.env.DEV && processedUrl.includes("www.happywedz.com")) {
          const imageId = processedUrl.split("/").pop();
          const base = import.meta.env.VITE_API_BASE_URL || "/api";
          setPreviewUrl(`${base}/images/${imageId}`);
        } else {
          setPreviewUrl(processedUrl);
        }
      } else if (processedId) {
        const base = import.meta.env.VITE_API_BASE_URL || "/api";
        const fallbackUrl = `${base}/images/${processedId}`;
        setPreviewUrl(fallbackUrl);
      }
    } catch (e) {
      if (e?.name === "AbortError") return;
      const { message, status } = getErrorMessage(e);

      console.error("applyMakeup failed:", e?.message || e, payload);
      Swal.fire({
        icon: "error",
        title: "Oops...",
        text:
          status === 500
            ? "Internal Server Error"
            : message || "Failed to apply filter.",
      });
    } finally {
      if (mySeq === applySeqRef.current) {
        setIsApplying(false);
      }
    }
  };

  const safeArray = (arr) => (Array.isArray(arr) ? arr : []);

  // Re-apply makeup when intensity changes for any applied product
  useEffect(() => {
    if (Object.keys(appliedProducts).length > 0) {
      if (suppressNextEffectRef.current) {
        // Skip this effect cycle when we already applied immediately
        suppressNextEffectRef.current = false;
        return;
      }
      if (debounceTimer.current) clearTimeout(debounceTimer.current);

      debounceTimer.current = setTimeout(() => {
        applyAllProducts(appliedProducts);
      }, DEBOUNCE_DELAY);
    }
    return () => {
      if (debounceTimer.current) clearTimeout(debounceTimer.current);
    };
  }, [intensities, appliedProducts]);

  // Persist the full applied products object for the popup (always up-to-date)
  useEffect(() => {
    try {
      sessionStorage.setItem(
        "finalLookFilters",
        JSON.stringify(appliedProducts || {})
      );
    } catch {}
  }, [appliedProducts]);

  // Optionally persist order (helps future needs; harmless now)
  useEffect(() => {
    try {
      sessionStorage.setItem("finalLookOrder", JSON.stringify(appliedOrder));
    } catch {}
  }, [appliedOrder]);

  // Cleanup in-flight apply on unmount
  useEffect(() => {
    return () => {
      if (applyAbortRef.current) {
        try {
          applyAbortRef.current.abort();
        } catch {}
      }
    };
  }, []);

  if (isLoading) {
    return (
      <div
        className="filters-container my-5 d-flex align-items-center justify-content-center"
        style={{ minHeight: 400 }}
      >
        <ClipLoader size={60} color="#ed1173" />
      </div>
    );
  }
  // Share handler
  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: "My Filtered Look",
          text: "Check out my filtered look!",
          url: previewUrl,
        });
        setShowShareMenu(false);
      } catch (err) {
        console.log(err);
      }
    }
  };

  return (
    <div
      // className="filters-container my-5"
      style={{ margin: "15px auto 0 auto", maxWidth: 380 }}
    >
      <div
        className="preview-area"
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
        }}
      >
        <div
          className="single-image-container"
          style={{ width: "100%" }}
          // style={{ width: "100%", maxWidth: 400 }}
        >
          <div
            className="image-wrapper"
            style={{
              // maxHeight: "520px",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              position: "relative",
            }}
          >
            <div
              style={{
                position: "absolute",
                top: 10,
                left: 16,
                zIndex: 30,
                cursor: "pointer",
                padding: 8,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
              title="Home"
              onClick={() => navigate("/try", { replace: true })}
            >
              <FaHome
                // className="primary-text"
                size={30}
                style={{
                  color: "#fff",
                  backgroundColor: "#C31162",
                  borderRadius: "100%",
                  padding: "5px",
                }}
              />
            </div>
            <div
              className="d-flex gap-2 justify-content-end"
              style={{
                position: "absolute",
                top: 10,
                right: 16,
                zIndex: 30,
                cursor: "pointer",
                padding: 8,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                width: activeBtn === "Complete Look" ? "55%" : "33%",
              }}
            >
              {activeBtn === "Complete Look" && (
                <div>
                  <Share
                    size={30}
                    style={{
                      color: "#fff",
                      backgroundColor: "#C31162",
                      borderRadius: "100%",
                      padding: "5px",
                    }}
                    title="Share Image"
                    onClick={() => setShowShareMenu(true)}
                  />
                </div>
              )}
              {/* Share Menu/Modal */}
              {showShareMenu && (
                <div
                  onClick={() => setShowShareMenu(false)}
                  style={{
                    position: "fixed",
                    top: 0,
                    left: 0,
                    width: "100vw",
                    height: "100vh",
                    backgroundColor: "rgba(0, 0, 0, 0.5)",
                    display: "flex",
                    justifyContent: "center",
                    alignItems: "center",
                    zIndex: 9999,
                  }}
                >
                  <div
                    onClick={(e) => e.stopPropagation()}
                    style={{
                      background: "#fff",
                      padding: "24px 32px",
                      borderRadius: "12px",
                      minWidth: 320,
                      boxShadow: "0 4px 20px rgba(0,0,0,0.2)",
                      display: "flex",
                      flexDirection: "column",
                      gap: 16,
                      alignItems: "center",
                    }}
                  >
                    <h4 style={{ marginBottom: 12 }}>Share your look</h4>
                    {navigator.share ? (
                      <button
                        onClick={handleShare}
                        style={{
                          background: "#C31162",
                          color: "#fff",
                          border: "none",
                          borderRadius: 8,
                          padding: "10px 24px",
                          fontWeight: 600,
                          cursor: "pointer",
                          marginBottom: 8,
                        }}
                      >
                        Share via Apps
                      </button>
                    ) : null}
                    <div style={{ display: "flex", gap: 16, marginTop: 8 }}>
                      {/* Copy Link */}
                      <div
                        onClick={() => {
                          navigator.clipboard.writeText(previewUrl);
                          Swal.fire({
                            text: "Link copied to clipboard!",
                            icon: "success",
                            confirmButtonColor: "#ed1173",
                            timer: 1500,
                          });
                        }}
                        style={{
                          width: 48,
                          height: 48,
                          borderRadius: "50%",
                          backgroundColor: "#f0f0f0",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          cursor: "pointer",
                          boxShadow: "0 2px 6px rgba(0,0,0,0.15)",
                          transition:
                            "transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out",
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.transform = "scale(1.1)";
                          e.currentTarget.style.boxShadow =
                            "0 4px 10px rgba(0,0,0,0.2)";
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.transform = "scale(1)";
                          e.currentTarget.style.boxShadow =
                            "0 2px 6px rgba(0,0,0,0.15)";
                        }}
                      >
                        <img
                          src="https://img.icons8.com/ios-filled/24/000000/link.png"
                          alt="Copy Link"
                          style={{ width: 24, height: 24 }}
                        />
                      </div>

                      {/* WhatsApp */}
                      <a
                        href={`https://wa.me/?text=${encodeURIComponent(
                          "Check out my look! " + previewUrl
                        )}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{
                          width: 48,
                          height: 48,
                          borderRadius: "50%",
                          backgroundColor: "#25D366",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          textDecoration: "none",
                          boxShadow: "0 2px 6px rgba(0,0,0,0.15)",
                          transition:
                            "transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out",
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.transform = "scale(1.1)";
                          e.currentTarget.style.boxShadow =
                            "0 4px 10px rgba(0,0,0,0.2)";
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.transform = "scale(1)";
                          e.currentTarget.style.boxShadow =
                            "0 2px 6px rgba(0,0,0,0.15)";
                        }}
                      >
                        <img
                          src="https://img.icons8.com/ios-filled/24/ffffff/whatsapp.png"
                          alt="WhatsApp"
                          style={{ width: 24, height: 24 }}
                        />
                      </a>

                      {/* Instagram */}
                      <a
                        href={`https://www.instagram.com/?url=${encodeURIComponent(
                          previewUrl
                        )}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{
                          width: 48,
                          height: 48,
                          borderRadius: "50%",
                          background:
                            "radial-gradient(circle at 30% 107%, #fdf497 0%, #fdf497 5%, #fd5949 45%, #d6249f 60%, #285AEB 90%)",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          textDecoration: "none",
                          boxShadow: "0 2px 6px rgba(0,0,0,0.15)",
                          transition:
                            "transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out",
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.transform = "scale(1.1)";
                          e.currentTarget.style.boxShadow =
                            "0 4px 10px rgba(0,0,0,0.2)";
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.transform = "scale(1)";
                          e.currentTarget.style.boxShadow =
                            "0 2px 6px rgba(0,0,0,0.15)";
                        }}
                      >
                        <img
                          src="https://img.icons8.com/ios-filled/24/ffffff/instagram-new.png"
                          alt="Instagram"
                          style={{ width: 24, height: 24 }}
                        />
                      </a>

                      {/* Facebook */}
                      <a
                        href={`https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(
                          previewUrl
                        )}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{
                          width: 48,
                          height: 48,
                          borderRadius: "50%",
                          backgroundColor: "#1877F2",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          textDecoration: "none",
                          boxShadow: "0 2px 6px rgba(0,0,0,0.15)",
                          transition:
                            "transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out",
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.transform = "scale(1.1)";
                          e.currentTarget.style.boxShadow =
                            "0 4px 10px rgba(0,0,0,0.2)";
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.transform = "scale(1)";
                          e.currentTarget.style.boxShadow =
                            "0 2px 6px rgba(0,0,0,0.15)";
                        }}
                      >
                        <img
                          src="https://img.icons8.com/ios-filled/24/ffffff/facebook.png"
                          alt="Facebook"
                          style={{ width: 24, height: 24 }}
                        />
                      </a>

                      {/* X (Twitter) */}
                      <a
                        href={`https://x.com/intent/post?url=${encodeURIComponent(
                          previewUrl
                        )}&text=${encodeURIComponent(
                          "Check out my filtered look!"
                        )}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{
                          width: 48,
                          height: 48,
                          borderRadius: "50%",
                          backgroundColor: "#000",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          textDecoration: "none",
                          boxShadow: "0 2px 6px rgba(0,0,0,0.15)",
                          transition:
                            "transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out",
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.transform = "scale(1.1)";
                          e.currentTarget.style.boxShadow =
                            "0 4px 10px rgba(0,0,0,0.2)";
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.transform = "scale(1)";
                          e.currentTarget.style.boxShadow =
                            "0 2px 6px rgba(0,0,0,0.15)";
                        }}
                      >
                        <img
                          src="https://img.icons8.com/ios-filled/24/ffffff/x.png"
                          alt="X"
                          style={{ width: 24, height: 24 }}
                        />
                      </a>
                    </div>

                    <button
                      onClick={() => setShowShareMenu(false)}
                      style={{
                        marginTop: 16,
                        background: "#eee",
                        color: "#C31162",
                        border: "none",
                        borderRadius: 8,
                        padding: "8px 18px",
                        fontWeight: 500,
                        cursor: "pointer",
                      }}
                    >
                      Close
                    </button>
                  </div>
                </div>
              )}
              {activeBtn === "Complete Look" && (
                <div
                  title="Download Image"
                  onClick={async () => {
                    try {
                      const responase = await fetch(previewUrl, {
                        mode: "cors",
                      });
                      const blob = await responase.blob();
                      const url = URL.createObjectURL(blob);
                      const link = document.createElement("a");
                      link.href = url;
                      link.download = "final_look.png";
                      document.body.appendChild(link);
                      link.click();
                      document.body.removeChild(link);
                      URL.revokeObjectURL(url);
                    } catch (error) {
                      console.error("Image download failed:", error);
                      Swal.fire({
                        icon: "error",
                        title: "Download Failed",
                        text: "Could not download the image. Please try again.",
                      });
                    }
                  }}
                >
                  <Download
                    size={30}
                    style={{
                      color: "#fff",
                      backgroundColor: "#C31162",
                      borderRadius: "100%",
                      padding: "5px",
                    }}
                  />
                </div>
              )}

              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                }}
                onClick={() => handleActiveList("LikedProduct")}
              >
                <Heart
                  size={30}
                  style={{
                    color: "#fff",
                    backgroundColor: "#C31162",
                    borderRadius: "100%",
                    padding: "5px",
                  }}
                />
              </div>
              {activeBtn !== "Compare" && (
                <div
                  onClick={async () => {
                    if (activeBtn === "Shades") {
                      // Remove last applied in sequence
                      if (appliedOrder.length === 0) return;
                      const lastCat = appliedOrder[appliedOrder.length - 1];
                      handleRemoveProduct(lastCat);
                      return;
                    }
                    if (activeBtn === "Complete Look") {
                      Swal.fire({
                        title: "Warning",
                        text: "Are you sure you want to reset all applied Products ?",
                        icon: "warning",
                        showCancelButton: true,
                        confirmButtonColor: "#ed1173",
                        cancelButtonColor: "#ed1173",
                        cancelButtonText: "Cancel",
                        confirmButtonText: "Reset",
                      }).then((result) => {
                        if (result.isConfirmed) {
                          setPreviewUrl(uploadedPreview);

                          try {
                            sessionStorage.removeItem("finalLookImage");
                            sessionStorage.removeItem("finalLookFilters");
                          } catch {}
                          try {
                            setAppliedProducts && setAppliedProducts({});
                            setAppliedOrder && setAppliedOrder([]);
                          } catch {}
                          try {
                            setExpandedProductId && setExpandedProductId(null);
                          } catch {}
                          try {
                            setExpandedCatIdx && setExpandedCatIdx(null);
                          } catch {}
                          try {
                            setShowProductDetails &&
                              setShowProductDetails(false);
                          } catch {}

                          // Exit compare mode if active
                          try {
                            setIsCompareMode && setIsCompareMode(false);
                          } catch {}
                          try {
                            setCompareImageUrl && setCompareImageUrl(null);
                          } catch {}
                        }
                      });
                    }
                  }}
                >
                  <MdRestartAlt
                    size={30}
                    style={{
                      color: "#fff",
                      backgroundColor: "#C31162",
                      borderRadius: "100%",
                      padding: "5px",
                    }}
                  />
                </div>
              )}
              <div
                title="Delete"
                onClick={async () => {
                  const confirmed = await Swal.fire({
                    title: "Remove image?",
                    text: "Are you sure you want to delete this image and clear all try data?",
                    icon: "warning",
                    showCancelButton: true,
                    confirmButtonColor: "#ed1173",
                    cancelButtonColor: "#aaa",
                    confirmButtonText: "Yes, delete it",
                  });

                  if (confirmed.isConfirmed) {
                    sessionStorage.removeItem("try_uploaded_image_id");
                    sessionStorage.removeItem("finalLookImage");
                    sessionStorage.removeItem("finalLookFilters");
                    setPreviewUrl(null);
                    setAppliedProducts({});
                    // navigate("/try/upload");
                    navigate("/try/upload", { replace: true });

                    Swal.fire({
                      title: "Deleted!",
                      text: "Your image has been removed.",
                      icon: "success",
                      confirmButtonColor: "#ed1173",
                    });
                  }
                }}
              >
                <IoClose
                  size={30}
                  style={{
                    color: "#fff",
                    backgroundColor: "#C31162",
                    borderRadius: "100%",
                    padding: "5px",
                  }}
                />
              </div>
            </div>
            <div
              className="compare-container"
              style={{
                width: "100%",
                overflow: "hidden",
                borderRadius: "12px",
                aspectRatio: "3 / 4",
                maxHeight: "80vh",
                minHeight: 400,
                // position:"relative"
              }}
            >
              {isCompareMode && originalImageUrl && compareImageUrl ? (
                // <ReactCompareImage
                //   leftImage={originalImageUrl}
                //   rightImage={compareImageUrl}
                //   sliderLineColor="#ed1173"
                //   sliderLineWidth={3}
                //   handleSize={40}
                // />
                <div
                  className="compare-container"
                  style={{
                    width: "100%",
                    height: "100%",
                    maxWidth: "100%",
                    borderRadius: "12px",
                    overflow: "hidden",
                    margin: "0",
                  }}
                >
                  <ReactCompareSlider
                    itemOne={
                      <ReactCompareSliderImage
                        src={originalImageUrl}
                        alt="Image one"
                        style={{
                          height: "100%",
                          width: "100%",
                          objectFit: "cover",
                          display: "block",
                        }}
                      />
                    }
                    itemTwo={
                      <ReactCompareSliderImage
                        src={compareImageUrl}
                        alt="Image two"
                        style={{
                          height: "100%",
                          width: "100%",
                          objectFit: "cover",
                          display: "block",
                        }}
                      />
                    }
                    style={{
                      width: "100%",
                      height: "100%",
                    }}
                  />
                </div>
              ) : (
                <div
                  style={{
                    overflow: "hidden",
                    // position: "relative",
                    borderRadius: "12px",
                  }}
                >
                  <img
                    src={previewUrl}
                    alt="preview"
                    style={{
                      width: "100%",
                      height: "100%",
                      objectFit: "cover",
                      display: "block",
                    }}
                    className="img-fluid"
                  />
                  {Object.entries(appliedProducts).length > 0 &&
                    activeBtn !== "Complete Look" &&
                    showProductDetails && (
                      <div
                        className="product-details"
                        style={{
                          position: "absolute",
                          bottom: 5,
                          left: 0,
                          right: 0,
                          color: "white",
                        }}
                      >
                        <div
                          style={{
                            background: "rgba(195, 17, 98, 0.5)",
                            width: "80%",
                            position: "relative",
                            padding: "clamp(6px, 2vw, 12px)",
                            borderRadius: "8px",
                          }}
                        >
                          {/* Close button */}
                          <button
                            onClick={() => setShowProductDetails(false)}
                            style={{
                              position: "absolute",
                              top: "-5px",
                              right: "-2px",
                              width: "clamp(28px, 5vw, 32px)",
                              height: "clamp(28px, 5vw, 32px)",
                              fontWeight: "900",
                              display: "flex",
                              alignItems: "center",
                              justifyContent: "center",
                              background: "transparent",
                              cursor: "pointer",
                              color: "white",
                              border: "none",
                            }}
                          >
                            <svg
                              style={{
                                width: "clamp(12px, 3vw, 16px)",
                                height: "clamp(12px, 3vw, 16px)",
                              }}
                              fill="none"
                              stroke="currentColor"
                              viewBox="0 0 24 24"
                            >
                              <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth={2}
                                d="M6 18L18 6M6 6l12 12"
                              />
                            </svg>
                          </button>

                          {/* Main Content Row */}
                          <div
                            style={{
                              display: "flex",
                              alignItems: "flex-start",
                              gap: "clamp(8px, 2vw, 12px)",
                            }}
                          >
                            {/* Left: Product Image */}
                            <div
                              style={{
                                width: "clamp(50px, 15vw, 60px)",
                                height: "clamp(50px, 15vw, 60px)",
                                position: "relative",
                                backgroundColor: "white",
                                borderRadius: "8px",
                                overflow: "hidden",
                                flexShrink: 0,
                                boxShadow: "0 2px 6px rgba(0,0,0,0.15)",
                              }}
                            >
                              <img
                                src={likedProduct?.product_real_image}
                                alt="product"
                                style={{
                                  width: "100%",
                                  height: "100%",
                                  objectFit: "cover",
                                }}
                              />
                              {/* Heart Icon */}
                              <button
                                onClick={handleClick}
                                style={{
                                  position: "absolute",
                                  top: "0px",
                                  right: "0px",
                                  width: "clamp(20px, 4vw, 24px)",
                                  height: "clamp(20px, 4vw, 24px)",
                                  borderRadius: "50%",
                                  border: "none",
                                  backgroundColor: "rgba(255,255,255,0.8)",
                                  display: "flex",
                                  alignItems: "center",
                                  justifyContent: "center",
                                  cursor: "pointer",
                                  padding: 0,
                                }}
                              >
                                {isFavorited ? (
                                  <AiFillHeart color="red" size={16} />
                                ) : (
                                  <AiOutlineHeart color="#ccc" size={16} />
                                )}
                              </button>
                            </div>

                            {/* Right: Text and Button */}
                            <div
                              style={{
                                flex: 1,
                                display: "flex",
                                flexDirection: "column",
                                justifyContent: "space-between",
                              }}
                            >
                              {/* Description */}
                              <div>
                                <h3
                                  style={{
                                    color: "white",
                                    fontWeight: 600,
                                    fontSize: "clamp(12px, 2.5vw, 14px)",
                                    margin: "0 0 2px 0",
                                    lineHeight: "1.2",
                                    whiteSpace: "nowrap",
                                    overflow: "hidden",
                                    textOverflow: "ellipsis",
                                  }}
                                >
                                  {likedProduct?.discription}
                                </h3>
                                <p
                                  style={{
                                    color: "white",
                                    fontSize: "clamp(10px, 2vw, 12px)",
                                    opacity: 0.9,
                                    margin: 0,
                                  }}
                                >
                                  {likedProduct?.product_name}
                                </p>
                              </div>

                              {/* Bottom Row: Price + Button */}
                              <div
                                style={{
                                  display: "flex",
                                  justifyContent: "space-between",
                                  alignItems: "center",
                                  marginTop: "6px",
                                }}
                              >
                                <p
                                  style={{
                                    color: "white",
                                    fontWeight: 700,
                                    fontSize: "clamp(12px, 2.5vw, 14px)",
                                    margin: 0,
                                  }}
                                >
                                  {likedProduct?.price}
                                </p>
                                <button
                                  style={{
                                    backgroundColor: "white",
                                    color: "#db2777",
                                    padding:
                                      "clamp(6px, 1.5vw, 8px) clamp(10px, 2vw, 14px)",
                                    borderRadius: "8px",
                                    fontSize: "clamp(10px, 2vw, 12px)",
                                    fontWeight: "600",
                                    border: "none",
                                    cursor: "pointer",
                                    boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
                                    whiteSpace: "nowrap",
                                  }}
                                >
                                  VISIT SITE
                                </button>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    )}
                </div>
              )}
            </div>
            {isApplying && (
              <div className="processing-overlay">
                <BarLoader />
                <p>Processing</p>
              </div>
            )}
            {activeBtn !== "Complete Look" &&
              activeBtn !== "Compare" &&
              expandedCatIdx !== null &&
              SLIDER_CATEGORIES.includes(
                (
                  categories[expandedCatIdx]?.product_detailed_category_name ||
                  ""
                ).toLowerCase()
              ) &&
              expandedProductId !== null && (
                <div
                  style={{
                    position: "absolute",
                    top: "50%",
                    right: "clamp(-90px, -10vw, -80px)",
                    transform: "translateY(-50%) rotate(-90deg)",
                    zIndex: 20,
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    accentColor: "#C31162",
                    minWidth: "60%",
                  }}
                >
                  <label
                    style={{ fontSize: 13, marginBottom: 4, color: "#fff" }}
                  >
                    {(
                      categories[expandedCatIdx]
                        ?.product_detailed_category_name || ""
                    ).toLowerCase() === "bindi"
                      ? ""
                      : ""}
                  </label>
                  <input
                    type="range"
                    min={0}
                    max={100}
                    step={1}
                    value={(() => {
                      const categoryName = (
                        categories[expandedCatIdx]
                          ?.product_detailed_category_name || ""
                      ).toLowerCase();
                      const currentIntensity =
                        intensities[categoryName] ??
                        DEFAULT_INTENSITIES[categoryName] ??
                        0.6;
                      const maxIntensity =
                        DEFAULT_INTENSITIES[categoryName] ?? 1;

                      return Math.round(
                        (currentIntensity / maxIntensity) * 100
                      );
                    })()}
                    onChange={(e) => {
                      const categoryName = (
                        categories[expandedCatIdx]
                          ?.product_detailed_category_name || ""
                      ).toLowerCase();
                      const maxIntensity =
                        DEFAULT_INTENSITIES[categoryName] ?? 1;
                      const sliderValue = Number(e.target.value);

                      const actualIntensity =
                        (sliderValue / 100) * maxIntensity;

                      setIntensities({
                        ...intensities,
                        [categoryName]: actualIntensity,
                      });
                    }}
                    style={{ width: "100%" }}
                  />
                  <span style={{ fontSize: 12, color: "#fff" }}>
                    {(() => {
                      const categoryName = (
                        categories[expandedCatIdx]
                          ?.product_detailed_category_name || ""
                      ).toLowerCase();
                      const currentIntensity =
                        intensities[categoryName] ??
                        DEFAULT_INTENSITIES[categoryName] ??
                        0.6;
                      const maxIntensity =
                        DEFAULT_INTENSITIES[categoryName] ?? 1;

                      return Math.round(
                        (currentIntensity / maxIntensity) * 100
                      );
                    })()}
                  </span>
                </div>
              )}
          </div>
        </div>
        {/* {!previewUrl && (
          <div className="upload-placeholder">
            <p>No image found. Please upload a photo.</p>
            <button
              className="btn btn-primary"
              onClick={() => navigate("/try/upload")}
            >
              Upload
            </button>
          </div>
        )} */}
      </div>
      {/* Filter bar */}
      <>
        {(() => {
          switch (activeBtn) {
            case "Shades":
              return (
                <div style={{ position: "relative", width: "100%" }}>
                  {/* === Shades Section === */}
                  {showBackButton && (
                    <button
                      onClick={handleBackToMainFilters}
                      style={{
                        position: "absolute",
                        top: "50%",
                        left: 0,
                        transform: "translateY(-50%)",
                        border: "none",
                        cursor: "pointer",
                        zIndex: 10,
                        width: 38,
                        height: 38,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        background: "transparent",
                      }}
                    >
                      <IoIosArrowBack size={22} color="#000" />
                    </button>
                  )}

                  <div
                    style={{
                      overflowX: "auto",
                      whiteSpace: "nowrap",
                      width: "100%",
                      display: "block",
                      // marginBottom: "80px",
                      scrollbarWidth: "thin",
                      scrollbarColor: "#ed1173 #f1f1f1",
                      padding: "0 10px",
                      position: "relative",
                    }}
                    ref={filterBarRef}
                  >
                    <div style={{ display: "inline-block", minWidth: "100%" }}>
                      <DragScroll>
                        <div
                          style={{
                            display: "flex",
                            justifyContent:
                              categories.length <= 4 ? "center" : "flex-start",
                            alignItems: "flex-start",
                            gap: "8px",
                            minWidth: "max-content",
                            padding: "0 8px",
                          }}
                        >
                          <div
                            style={{
                              display: "inline-flex",
                              gap: 8,
                              flexWrap: "nowrap",
                              overflowX: "visible",
                              maxWidth: "none",
                            }}
                          >
                            {categories.map((cat, idx) => {
                              const categoryName = (
                                cat.product_detailed_category_name || ""
                              ).toLowerCase();
                              const isApplied = appliedProducts[categoryName];

                              if (
                                expandedCatIdx !== null &&
                                expandedCatIdx !== idx
                              ) {
                                return null;
                              }

                              return (
                                <React.Fragment
                                  key={`${
                                    cat.product_detailed_category_name || "cat"
                                  }-${idx}`}
                                >
                                  {!(
                                    expandedCatIdx === idx &&
                                    expandedProductId !== null
                                  ) && (
                                    <button
                                      type="button"
                                      // removed py-2 class from below
                                      className={`d-flex flex-column align-items-center px-2 border-0 border-end bg-white position-relative ${
                                        expandedCatIdx === idx
                                          ? "border-primary"
                                          : ""
                                      } ${isApplied ? "border-success" : ""}`}
                                      onClick={() => handleSelectCategory(idx)}
                                      style={{
                                        cursor: "pointer",
                                        minWidth: 70,
                                        transition: "all 0.3s ease",
                                        flexShrink: 0,
                                      }}
                                    >
                                      <img
                                        src={cat.product_detailed_image}
                                        alt={cat.product_detailed_category_name}
                                        style={{
                                          width: "100%",
                                          height: "55px",
                                          objectFit: "cover",
                                        }}
                                      />
                                      <p
                                        style={{
                                          fontSize: 11,
                                          fontWeight: 600,
                                        }}
                                      >
                                        {cat.product_detailed_category_name ||
                                          "Category"}
                                      </p>
                                      {isApplied && (
                                        <div
                                          className="position-absolute top-0 end-0 translate-middle rounded-circle"
                                          style={{
                                            width: 10,
                                            height: 10,
                                            // backgroundColor: isApplied.colorHex,
                                            border: "2px solid white",
                                            transform: "translate(50%, -50%)",
                                          }}
                                          title={`Applied: ${isApplied.colorHex}`}
                                        />
                                      )}
                                    </button>
                                  )}

                                  {expandedCatIdx === idx && (
                                    <div
                                      style={{
                                        display: "inline-block",
                                        minWidth: 220,
                                        maxWidth: 400,
                                        borderRadius: 8,
                                        whiteSpace: "normal",
                                        animation: "slideIn 0.3s ease-out",
                                      }}
                                    >
                                      <div
                                        style={{
                                          display: "inline-flex",
                                          alignItems: "flex-start",
                                          gap: 8,
                                          overflowX: "auto",
                                          maxWidth: "100%",
                                          height: 100,
                                          overflowY: "hidden",
                                          scrollbarWidth: "none",
                                          msOverflowStyle: "none",
                                        }}
                                      >
                                        {(expandedProductId
                                          ? safeArray(cat.products).filter(
                                              (pp) =>
                                                pp.id === expandedProductId
                                            )
                                          : safeArray(cat.products)
                                        ).map((p) => (
                                          <React.Fragment key={p.id}>
                                            <button
                                              type="button"
                                              onClick={() => {
                                                handleSelectProduct(p.id);
                                                setLikedProduct(p);
                                              }}
                                              className={` d-flex flex-column align-items-center px-2 border-0 rounded bg-white ${
                                                expandedProductId === p.id
                                                  ? "border-primary"
                                                  : ""
                                              }`}
                                              style={{
                                                cursor: "pointer",
                                                width: 100,
                                                height: 100,
                                                flexShrink: 0,
                                                flexGrow: 0,
                                              }}
                                            >
                                              <img
                                                src={p.product_real_image}
                                                alt={p.product_name}
                                                style={{
                                                  borderRadius: 10,
                                                  width: "100%",
                                                  height: "55px",
                                                  objectFit: "cover",
                                                }}
                                              />
                                              <p
                                                className="mt-1"
                                                style={{
                                                  fontSize: 10,
                                                  fontWeight: 500,
                                                }}
                                              >
                                                {p.product_name.slice(0, 10)}...
                                              </p>
                                            </button>
                                            {expandedProductId === p.id && (
                                              <div
                                                style={{
                                                  display: "inline-flex",
                                                  alignItems: "center",
                                                  justifyContent: "center",
                                                  height: 100,
                                                  gap: 12,
                                                  animation:
                                                    "fadeIn 0.3s ease-out",
                                                }}
                                              >
                                                <div
                                                  style={{
                                                    width: 2,
                                                    height: "100%",
                                                    background: "#e5e7eb",
                                                  }}
                                                />
                                                <div
                                                  className="px-3"
                                                  style={{
                                                    minWidth: 240,
                                                    maxWidth: 360,
                                                    height: "100%",
                                                    display: "flex",
                                                    alignItems: "center",
                                                    justifyContent: "center",
                                                  }}
                                                >
                                                  <div
                                                    style={{
                                                      display: "flex",
                                                      alignItems: "center",
                                                      justifyContent: "start",
                                                      gap: 14,
                                                      flexWrap: "wrap",
                                                    }}
                                                  >
                                                    {safeArray(p.product_colors)
                                                      .length > 0 ? (
                                                      safeArray(
                                                        p.product_colors
                                                      ).map((hex, i) => (
                                                        <button
                                                          key={`${p.id}-${hex}-${i}`}
                                                          type="button"
                                                          title={hex}
                                                          onClick={() => {
                                                            handleApplyOne(
                                                              p.id,
                                                              hex
                                                            );
                                                            // Don't auto-collapse - let user use back button
                                                          }}
                                                          disabled={isApplying}
                                                          className="border rounded-circle"
                                                          style={{
                                                            width: 40,
                                                            height: 40,
                                                            background: hex,
                                                            borderColor: "#ccc",
                                                          }}
                                                        />
                                                      ))
                                                    ) : (
                                                      <span className="small text-muted">
                                                        No colors
                                                      </span>
                                                    )}
                                                  </div>
                                                </div>
                                              </div>
                                            )}
                                          </React.Fragment>
                                        ))}
                                        {safeArray(cat.products).length ===
                                          0 && (
                                          <div className="text-muted small">
                                            No products
                                          </div>
                                        )}
                                      </div>
                                    </div>
                                  )}
                                </React.Fragment>
                              );
                            })}
                          </div>
                        </div>
                      </DragScroll>
                    </div>
                  </div>
                </div>
              );

            case "Compare":
              return (
                <div
                  style={{
                    textAlign: "center",
                    marginTop: "0px",
                    // height: "150px",
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    justifyContent: "center",
                  }}
                >
                  <div
                    style={{
                      width: "55px",
                      height: "55px",
                      backgroundColor: "black",
                      position: "relative",
                      borderRadius: "4px",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                  >
                    <div
                      style={{
                        width: "2px",
                        height: "100%",
                        backgroundColor: "white",
                      }}
                    ></div>
                  </div>
                  <p
                    style={{
                      color: "black",
                      fontWeight: "500",
                      marginTop: "5px",
                      fontSize: "12px",
                    }}
                  >
                    Before/After
                  </p>
                </div>
              );

            case "Complete Look":
              return (
                <div
                  style={{
                    marginTop: "10px",
                    width: "100%",
                    display: "flex",
                    alignItems: "center",
                    gap: "12px",
                    justifyContent: "center",
                    height: 100,
                  }}
                >
                  <div>
                    <button
                      style={{
                        background: "#C31162",
                        color: "#fff",
                        border: "none",
                        borderRadius: 8,
                        padding: "8px 12px",
                        fontSize: 12,
                        fontWeight: 600,
                        cursor: "pointer",
                      }}
                      onClick={() => {
                        try {
                          const list = [];
                          const allProducts = Array.isArray(categories)
                            ? categories.flatMap((c) =>
                                Array.isArray(c.products) ? c.products : []
                              )
                            : [];
                          Object.values(appliedProducts || {}).forEach((p) => {
                            const found = allProducts.find(
                              (ap) => ap?.id === p?.productId
                            );
                            if (found) {
                              list.push({
                                id: found.id,
                                product_real_image:
                                  found.product_real_image ||
                                  found.image ||
                                  found.thumbnail ||
                                  "",
                                description:
                                  found.discription ||
                                  found.description ||
                                  found.product_name ||
                                  "",
                                price: found.price || "",
                              });
                            }
                          });
                          sessionStorage.setItem(
                            "finalLookAppliedList",
                            JSON.stringify(list)
                          );
                        } catch {}
                        handleActiveList("Complete Look");
                      }}
                    >
                      View all products
                    </button>
                  </div>
                  {/* )} */}
                </div>
              );

            default:
              return null;
          }
        })()}
      </>
      <div className="w-100 py-2 mb-3" style={{ background: "#ffb3d3ff" }}>
        <div className="d-flex justify-content-evenly">
          {buttons.map((button, index) => (
            <button
              key={index}
              style={{
                height: "100%",
                background: activeBtn === button ? "#C31162" : "none",
                color: activeBtn === button ? "#fff" : "#C31162",
                padding: "4px clamp(0.6rem, 2vw, 2rem)",
                border: "none",
                borderRadius: "10px",
                fontWeight: "400",
                cursor: "pointer",
                transition: "all 0.3s ease",
                fontSize: "clamp(8px, 1.5vw, 12px)",
              }}
              onClick={() => {
                setActiveBtn(button);

                switch (button) {
                  case "Complete Look":
                    sessionStorage.setItem("finalLookImage", previewUrl);
                    sessionStorage.setItem(
                      "finalLookFilters",
                      JSON.stringify(appliedProducts)
                    );
                    // navigate("/finallook");
                    setIsCompareMode(false);
                    setShowCompleteLook(true);
                    break;
                  case "Compare":
                    // setCompareImageUrl(previewUrl);
                    setShowCompleteLook(false);
                    setIsCompareMode((prev) => !prev);
                    break;
                  default:
                    setIsCompareMode(false);
                    setShowCompleteLook(false);
                    break;
                }
              }}
            >
              {button}
            </button>
          ))}
        </div>
      </div>
      <style jsx>{`
        .preview-img {
          max-width: 100%;
          max-height: 100%;
          object-fit: contain;
          border-radius: 8px;
        }
        .processing-overlay {
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(255, 255, 255, 0.9);
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          z-index: 10;
        }
        .spinner {
          width: 40px;
          height: 40px;
          border: 4px solid #f3f3f3;
          border-top: 4px solid #ed1173;
          border-radius: 50%;
          animation: spin 1s linear infinite;
          margin-bottom: 10px;
        }
        @keyframes spin {
          0% {
            transform: rotate(0deg);
          }
          100% {
            transform: rotate(360deg);
          }
        }
        .upload-placeholder {
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          min-height: 200px;
          color: #6c757d;
          text-align: center;
          padding: 20px;
          background: #f8f9fa;
          border-radius: 12px;
          border: 2px dashed #dee2e6;
        }
        .upload-placeholder p {
          margin: 0 0 15px 0;
          font-size: 1.1rem;
        }
        @media (max-width: 768px) {
          .image-wrapper {
            min-height: 220px;
          }
        }
        @keyframes slideIn {
          from {
            opacity: 0;
            transform: translateX(-20px);
          }
          to {
            opacity: 1;
            transform: translateX(0);
          }
        }
        @keyframes fadeIn {
          from {
            opacity: 0;
            transform: scale(0.9);
          }
          to {
            opacity: 1;
            transform: scale(1);
          }
        }
        /* Custom scrollbar for filter bar */
        .filters-container ::-webkit-scrollbar {
          height: 6px;
        }
        .filters-container ::-webkit-scrollbar-track {
          background: #f1f1f1;
          border-radius: 3px;
        }
        .filters-container ::-webkit-scrollbar-thumb {
          background: #ed1173;
          border-radius: 3px;
        }
        .filters-container ::-webkit-scrollbar-thumb:hover {
          background: #c00e5f;
        }
      `}</style>

      {showPopup && (
        <div
          onClick={() => setShowPopup(false)}
          style={{
            position: "fixed",
            top: 0,
            left: 0,
            width: "100vw",
            height: "100vh",
            backgroundColor: "#ffffff",
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            zIndex: 9999,
          }}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{
              padding: "30px",
              minWidth: "550px",
              maxWidth: "650px",
            }}
          >
            {/* <FavouriteListPopup setShowPopup={setShowPopup} /> */}
            <FavouriteListPopup
              setShowPopup={setShowPopup}
              appliedProductsObj={appliedProducts}
              onRemoveApplied={handleRemoveProduct}
              activeList={activeList}
            />
          </div>
        </div>
      )}
    </div>
  );
};

export default FiltersPage;
