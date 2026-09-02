import React, { useState, useEffect, useRef } from "react";
import {
  X,
  ChevronLeft,
  ChevronRight,
  RotateCw,
  ZoomIn,
  ZoomOut,
  Maximize2,
} from "lucide-react";

// This will be our custom hook to load Pannellum
const usePannellum = () => {
  const [pannellum, setPannellum] = useState(null);

  useEffect(() => {
    // Load Pannellum script
    const script = document.createElement("script");
    script.src =
      "https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.js";
    script.async = true;
    script.onload = () => {
      setPannellum(window.pannellum);
    };
    document.body.appendChild(script);

    // Load Pannellum CSS
    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href =
      "https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.css";
    document.head.appendChild(link);

    return () => {
      document.body.removeChild(script);
      document.head.removeChild(link);
    };
  }, []);

  return pannellum;
};

const Image360Modal = ({ images, onClose, title }) => {
  const [currentIndex, setCurrentIndex] = useState(0);
  const pannellumRef = useRef(null);
  const viewerRef = useRef(null);
  const pannellum = usePannellum();

  const normalizedImages = React.useMemo(
    () =>
      (Array.isArray(images) ? images : [])
        .filter(Boolean)
        .map((s) => s.toString().trim()),
    [images]
  );

  // Initialize and update Pannellum viewer
  useEffect(() => {
    if (!pannellum || !pannellumRef.current || normalizedImages.length === 0)
      return;

    const config = {
      type: "equirectangular",
      panorama: normalizedImages[currentIndex],
      autoLoad: true,
      autoRotate: -2,
      compass: true,
      showZoomCtrl: false,
      showFullscreenCtrl: false,
    };

    // Initialize viewer
    try {
      if (viewerRef.current) {
        try {
          viewerRef.current.destroy();
        } catch (e) {
          console.error("Error destroying previous viewer:", e);
        }
      }

      viewerRef.current = pannellum.viewer(pannellumRef.current, config);
    } catch (error) {
      console.error("Error initializing Pannellum:", error);
    }

    return () => {
      if (viewerRef.current) {
        try {
          viewerRef.current.destroy();
        } catch (e) {
          console.error("Error cleaning up Pannellum:", e);
        }
      }
    };
  }, [pannellum, normalizedImages, currentIndex]);

  const handleZoomIn = () => {
    if (viewerRef.current) {
      const currentHfov = viewerRef.current.getHfov();
      viewerRef.current.setHfov(Math.max(30, currentHfov - 10));
    }
  };

  const handleZoomOut = () => {
    if (viewerRef.current) {
      const currentHfov = viewerRef.current.getHfov();
      viewerRef.current.setHfov(Math.min(120, currentHfov + 10));
    }
  };

  const handleReset = () => {
    if (viewerRef.current) {
      viewerRef.current.setYaw(0);
      viewerRef.current.setPitch(0);
      viewerRef.current.setHfov(100);
    }
  };

  const handleFullscreen = () => {
    const container = pannellumRef.current;
    if (!document.fullscreenElement) {
      container.requestFullscreen?.() ||
        container.webkitRequestFullscreen?.() ||
        container.msRequestFullscreen?.();
    } else {
      document.exitFullscreen?.() ||
        document.webkitExitFullscreen?.() ||
        document.msExitFullscreen?.();
    }
  };

  const goToNext = () => {
    if (currentIndex < normalizedImages.length - 1) {
      setCurrentIndex(currentIndex + 1);
    }
  };

  const goToPrev = () => {
    if (currentIndex > 0) {
      setCurrentIndex(currentIndex - 1);
    }
  };

  if (normalizedImages.length === 0) {
    return (
      <div
        style={{
          padding: "20px",
          textAlign: "center",
          color: "#666",
        }}
      >
        No 360° images available
      </div>
    );
  }

  return (
    <div
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: "#000",
        zIndex: 1000,
      }}
    >
      {/* Header */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          zIndex: 10,
          background:
            "linear-gradient(to bottom, rgba(0,0,0,0.8), transparent)",
          padding: "16px 24px",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
          }}
        >
          <div style={{ color: "white" }}>
            <h2 style={{ fontSize: "24px", fontWeight: "bold", margin: 0 }}>
              {title}
            </h2>
            {normalizedImages.length > 1 && (
              <p
                style={{
                  fontSize: "14px",
                  color: "#d1d5db",
                  margin: "4px 0 0 0",
                }}
              >
                Image {currentIndex + 1} of {normalizedImages.length}
              </p>
            )}
          </div>
          <button
            onClick={(e) => {
              e.stopPropagation();
              onClose();
            }}
            style={{
              backgroundColor: "rgba(255,255,255,0.2)",
              color: "white",
              padding: "8px",
              borderRadius: "50%",
              border: "none",
              cursor: "pointer",
              zIndex: 20,
            }}
            aria-label="Close"
          >
            <X size={20} />
          </button>
        </div>
      </div>

      {/* Pannellum Viewer */}
      <div
        ref={pannellumRef}
        style={{
          width: "100%",
          height: "100%",
          position: "relative",
        }}
      />

      {/* Navigation Arrows */}
      {normalizedImages.length > 1 && (
        <>
          {currentIndex > 0 && (
            <button
              onClick={goToPrev}
              style={{
                position: "absolute",
                left: "20px",
                top: "50%",
                transform: "translateY(-50%)",
                backgroundColor: "rgba(0,0,0,0.5)",
                color: "white",
                width: "40px",
                height: "40px",
                borderRadius: "50%",
                border: "none",
                cursor: "pointer",
                zIndex: 10,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <ChevronLeft size={24} />
            </button>
          )}
          {currentIndex < normalizedImages.length - 1 && (
            <button
              onClick={goToNext}
              style={{
                position: "absolute",
                right: "20px",
                top: "50%",
                transform: "translateY(-50%)",
                backgroundColor: "rgba(0,0,0,0.5)",
                color: "white",
                width: "40px",
                height: "40px",
                borderRadius: "50%",
                border: "none",
                cursor: "pointer",
                zIndex: 10,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <ChevronRight size={24} />
            </button>
          )}
        </>
      )}

      {/* Controls */}
      <div
        style={{
          position: "absolute",
          bottom: "20px",
          left: 0,
          right: 0,
          display: "flex",
          justifyContent: "center",
          gap: "10px",
          zIndex: 10,
        }}
      >
        <button
          onClick={handleReset}
          style={{
            backgroundColor: "rgba(0,0,0,0.5)",
            color: "white",
            width: "40px",
            height: "40px",
            borderRadius: "50%",
            border: "none",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
          title="Reset View"
        >
          <RotateCw size={20} />
        </button>
        <button
          onClick={handleZoomOut}
          style={{
            backgroundColor: "rgba(0,0,0,0.5)",
            color: "white",
            width: "40px",
            height: "40px",
            borderRadius: "50%",
            border: "none",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
          title="Zoom Out"
        >
          <ZoomOut size={20} />
        </button>
        <button
          onClick={handleZoomIn}
          style={{
            backgroundColor: "rgba(0,0,0,0.5)",
            color: "white",
            width: "40px",
            height: "40px",
            borderRadius: "50%",
            border: "none",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
          title="Zoom In"
        >
          <ZoomIn size={20} />
        </button>
        <button
          onClick={handleFullscreen}
          style={{
            backgroundColor: "rgba(0,0,0,0.5)",
            color: "white",
            width: "40px",
            height: "40px",
            borderRadius: "50%",
            border: "none",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
          title="Fullscreen"
        >
          <Maximize2 size={20} />
        </button>
      </div>
    </div>
  );
};

export default Image360Modal;
