import React, { useState, useRef } from "react";
import { IoCameraOutline, IoCloudUploadOutline } from "react-icons/io5";
import { useNavigate } from "react-router-dom";
import * as faceapi from "face-api.js";
import { beautyApi } from "../../services/api";
import Swal from "sweetalert2";

const ProfileImageSelector = () => {
  const navigate = useNavigate();

  // Refs for file inputs
  const fileInputRef = useRef(null);
  const editFileInputRef = useRef(null);

  // State variables for image selection
  const [selectedImage, setSelectedImage] = useState(null);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showInstructionsModal, setShowInstructionsModal] = useState(false);
  const [showCameraModal, setShowCameraModal] = useState(false);
  const [stream, setStream] = useState(null);
  const [isCameraReady, setIsCameraReady] = useState(false);
  const [countdown, setCountdown] = useState(null);
  const [cameraError, setCameraError] = useState(null);
  const [faceWarning, setFaceWarning] = useState("");
  const videoRef = useRef(null);
  const canvasRef = useRef(null);

  // State variables for makeup styling
  const [selectedCategory, setSelectedCategory] = useState("makeup");
  const [selectedProducts, setSelectedProducts] = useState({
    lipstick: null,
    blush: null,
    eyeshadow: null,
    foundation: null,
  });
  const [selectedDress, setSelectedDress] = useState(null);
  const [selectedLook, setSelectedLook] = useState(null);
  const [isLoadingProducts, setIsLoadingProducts] = useState(false);
  const [apiProducts, setApiProducts] = useState({
    lipstick: [],
    blush: [],
    eyeshadow: [],
    foundation: [],
  });
  const [uploadingImageId, setUploadingImageId] = useState(null);
  const [isApplying, setIsApplying] = useState(false);

  // Color scheme
  const colors = {
    primaryPink: "#ed1173",
    lightPink: "#fce4ec",
    mediumPink: "#f8bbd9",
    darkPink: "#ad1457",
    grey: "#62565b",
    white: "#ffffff",
    lightGrey: "#f8f4f6",
    darkGrey: "#333333",
    primary: "#ed1173",
    lightBg: "#fafafa",
    lightText: "#666666",
    border: "#e0e0e0",
  };

  // Fallback static products; UI prefers apiProducts when available
  const makeupProducts = {
    lipstick: [
      {
        id: 1,
        name: "Matte Red",
        color: "#dc3545",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/lipstick/red-lipstick.png",
      },
      {
        id: 2,
        name: "Pink Gloss",
        color: "#e91e63",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/lipstick/pink-lipstick.png",
      },
      {
        id: 3,
        name: "Coral Matte",
        color: "#ff5722",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/lipstick/coral-lipstick.png",
      },
      {
        id: 4,
        name: "Berry Bold",
        color: "#9c27b0",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/lipstick/berry-lipstick.png",
      },
    ],
    blush: [
      {
        id: 1,
        name: "Peachy Glow",
        color: "#ffab91",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/blush/peach-blush.png",
      },
      {
        id: 2,
        name: "Rose Blush",
        color: "#f8bbd9",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/blush/rose-blush.png",
      },
      {
        id: 3,
        name: "Coral Flush",
        color: "#ff8a65",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/blush/coral-blush.png",
      },
      {
        id: 4,
        name: "Pink Pop",
        color: "#f48fb1",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/blush/pink-blush.png",
      },
    ],
    eyeshadow: [
      {
        id: 1,
        name: "Smoky Gray",
        color: "#616161",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/eyeshadow/gray-eyeshadow.png",
      },
      {
        id: 2,
        name: "Gold Shimmer",
        color: "#ffd54f",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/eyeshadow/gold-eyeshadow.png",
      },
      {
        id: 3,
        name: "Rose Gold",
        color: "#ffab91",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/eyeshadow/rosegold-eyeshadow.png",
      },
      {
        id: 4,
        name: "Purple Haze",
        color: "#ba68c8",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/eyeshadow/purple-eyeshadow.png",
      },
    ],
    foundation: [
      {
        id: 1,
        name: "Light Beige",
        color: "#f5deb3",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/foundation/light-foundation.png",
      },
      {
        id: 2,
        name: "Medium Tan",
        color: "#deb887",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/foundation/medium-foundation.png",
      },
      {
        id: 3,
        name: "Warm Honey",
        color: "#d2691e",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/foundation/honey-foundation.png",
      },
      {
        id: 4,
        name: "Deep Caramel",
        color: "#a0522d",
        image:
          "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/foundation/deep-foundation.png",
      },
    ],
  };

  const dresses = [
    {
      id: 1,
      name: "Elegant Evening",
      color: "#000",
      image:
        "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/dresses/black-dress.png",
    },
    {
      id: 2,
      name: "Summer Dress",
      color: "#4caf50",
      image:
        "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/dresses/green-dress.png",
    },
    {
      id: 3,
      name: "Cocktail Dress",
      color: "#e91e63",
      image:
        "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/dresses/pink-dress.png",
    },
    {
      id: 4,
      name: "Blazer",
      color: "#3f51b5",
      image:
        "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/dresses/blazer.png",
    },
  ];

  const wholeLooks = [
    {
      id: 1,
      name: "Glamorous Night Out",
      image:
        "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/looks/night-out.png",
      description: "Bold makeup + Evening dress",
    },
    {
      id: 2,
      name: "Natural Day Look",
      image:
        "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/looks/day-look.png",
      description: "Subtle makeup + Casual wear",
    },
    {
      id: 3,
      name: "Professional Chic",
      image:
        "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/looks/professional.png",
      description: "Clean makeup + Business attire",
    },
    {
      id: 4,
      name: "Romantic Date",
      image:
        "https://cdn.jsdelivr.net/gh/afnizarnur/drawish@master/products/looks/romantic.png",
      description: "Soft makeup + Elegant dress",
    },
  ];

  // Load face-api.js models once and fetch makeup products
  React.useEffect(() => {
    const loadModels = async () => {
      const MODEL_URL = "/models"; // Place models in public/models
      await faceapi.nets.tinyFaceDetector.loadFromUri(MODEL_URL);
      await faceapi.nets.faceLandmark68Net.loadFromUri(MODEL_URL);
      await faceapi.nets.faceExpressionNet.loadFromUri(MODEL_URL);
      await faceapi.nets.ageGenderNet.loadFromUri(MODEL_URL);
      await faceapi.nets.faceRecognitionNet.loadFromUri(MODEL_URL);
    };
    loadModels();
  }, []);

  React.useEffect(() => {
    const fetchProducts = async () => {
      try {
        setIsLoadingProducts(true);
        const response = await beautyApi.getFilteredProducts("Makeup");
        const items = response?.data || response?.products || response || []; 
        // Group into expected categories using API fields
        const grouped = {
          lipstick: [],
          blush: [],
          eyeshadow: [],
          foundation: [],
        };
        const inferType = (p) => {
          const dc = (p.detailed_category || "").toString().toLowerCase();
          if (dc.includes("lip")) return "lipstick"; // LipStick
          if (dc.includes("blush")) return "blush";
          if (dc.includes("eye")) return "eyeshadow"; // EyeShadow
          if (dc.includes("foundation")) return "foundation";
          return null;
        };
        items.forEach((item) => {
          const id = item.id ?? item.product_id ?? item._id;
          const name =
            item.brand_name ||
            item.product_name ||
            item.name ||
            item.title ||
            `Product ${id}`;
          const colorRaw =
            item.product_color_hex || item.hex || item.tint || undefined;
          const imageRaw =
            item.product_real_image ||
            item.image ||
            item.thumbnail ||
            item.icon ||
            undefined;
          let color = typeof colorRaw === "string" ? colorRaw.trim() : colorRaw;
          if (
            typeof color === "string" &&
            color &&
            !color.startsWith("#") &&
            !color.startsWith("rgb")
          ) {
            color = `#${color}`;
          }
          let image = typeof imageRaw === "string" ? imageRaw.trim() : imageRaw;
          if (
            typeof image === "string" &&
            image &&
            !image.startsWith("data:") &&
            !image.startsWith("http")
          ) {
            image = `data:image/jpeg;base64,${image}`;
          }
          const normalized = { id, name, color, image, raw: item };
          const key = inferType(item);
          if (key && grouped[key]) grouped[key].push(normalized);
        });
        setApiProducts(grouped);
      } catch (e) {
        console.error("Failed to fetch products", e);
      } finally {
        setIsLoadingProducts(false);
      }
    };
    fetchProducts();
  }, []);

  // Image selection handlers
  const handleImageSelect = async (event) => {
    const file = event.target.files[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        // alert("Please select an image less than 5MB");
        Swal.fire({
          icon: "warning",
          text: "Please select an image less than 5MB",
          confirmButtonText: "OK",
          confirmButtonColor: "#ed1173",
        });
        return;
      }
      if (!file.type.startsWith("image/")) {
        // alert("Please select a valid image file");
        Swal.fire({
          icon: "warning",
          text: "Please select a valid image file",
          confirmButtonText: "OK",
          confirmButtonColor: "#ed1173",
        });
        return;
      }
      const reader = new FileReader();
      reader.onload = (e) => setSelectedImage(e.target.result);
      reader.readAsDataURL(file);
      // Upload to server to obtain image_id for processing
      try {
        const uploadRes = await beautyApi.uploadImage(file, "ORIGINAL");
        const imageId =
          uploadRes?.data?.id || uploadRes?.id || uploadRes?.image_id;
        if (imageId) setUploadingImageId(imageId);
      } catch (e) {
        console.error("Image upload failed", e);
      }
    }
  };

  const handleEditImage = async (event) => {
    const file = event.target.files[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        // alert("Please select an image less than 5MB");
        Swal.fire({
          icon: "warning",
          text: "Please select an image less than 5MB",
          confirmButtonText: "OK",
          confirmButtonColor: "#ed1173",
        });
        return;
      }
      if (!file.type.startsWith("image/")) {
        // alert("Please select a valid image file");
        Swal.fire({
          icon: "warning",
          text: "Please select a valid image file",
          confirmButtonText: "OK",
          confirmButtonColor: "#ed1173",
        });
        return;
      }
      const reader = new FileReader();
      reader.onload = (e) => {
        setSelectedImage(e.target.result);
        setShowEditModal(false);
      };
      reader.readAsDataURL(file);
      try {
        const uploadRes = await beautyApi.uploadImage(file, "original");
        const imageId =
          uploadRes?.data?.id || uploadRes?.id || uploadRes?.image_id;
        if (imageId) setUploadingImageId(imageId);
      } catch (e) {
        console.error("Image upload failed", e);
      }
    }
  };

  const triggerFileInput = () => {
    setShowInstructionsModal(false);
    fileInputRef.current.click();
  };

  const triggerEditFileInput = () => editFileInputRef.current.click();

  const openImageOptions = () => {
    setShowInstructionsModal(true);
  };

  const startCamera = async () => {
    try {
      setShowCameraModal(true);
      const constraints = {
        video: {
          facingMode: "user",
          width: { ideal: 1280 },
          height: { ideal: 720 },
          frameRate: { ideal: 30 },
        },
        audio: false,
      };

      const mediaStream = await navigator.mediaDevices.getUserMedia(
        constraints
      );
      if (videoRef.current) {
        videoRef.current.srcObject = mediaStream;
        await videoRef.current.play(); // Ensure video starts playing
        setStream(mediaStream);
        setIsCameraReady(true);
        setCameraError(null);
      }
    } catch (err) {
      console.error("Error accessing camera:", err);
      setCameraError(
        "Unable to access camera. Please make sure you have given camera permissions."
      );
    }
  };

  const stopCamera = () => {
    if (stream) {
      stream.getTracks().forEach((track) => track.stop());
      setStream(null);
    }
    setShowCameraModal(false);
  };

  // Capture the full video frame and set as preview
  const captureImage = async () => {
    if (videoRef.current && canvasRef.current) {
      const video = videoRef.current;
      const canvas = canvasRef.current;
      // Set canvas size to match the full video resolution
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      const ctx = canvas.getContext("2d");
      // Draw the full video frame (no cropping)
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
      // Get the image as a data URL
      const imageDataURL = canvas.toDataURL("image/jpeg", 0.95);
      const valid = await validateFace(imageDataURL);
      if (valid) {
        setSelectedImage(imageDataURL);
        stopCamera();
      }
    }
  };

  // Countdown before capturing an image
  const startCountdown = () => {
    setCountdown(3); // Start countdown from 3 seconds
    const timer = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
          clearInterval(timer); // Stop the timer
          captureImage(); // Capture the image
          return null; // Reset countdown
        }
        return prev - 1; // Decrease countdown
      });
    }, 1000); // Decrease every second
  };

  // Makeup styling handlers
  const handleCategorySelect = (category) => {
    setSelectedCategory(category);
    // Reset selections when switching categories
    if (category === "makeup") {
      setSelectedDress(null);
      setSelectedLook(null);
    } else if (category === "dress") {
      setSelectedProducts({
        lipstick: null,
        blush: null,
        eyeshadow: null,
        foundation: null,
      });
      setSelectedLook(null);
    } else if (category === "whole") {
      setSelectedProducts({
        lipstick: null,
        blush: null,
        eyeshadow: null,
        foundation: null,
      });
      setSelectedDress(null);
    }
  };

  const handleProductSelect = (productType, product) => {
    setSelectedProducts((prev) => ({
      ...prev,
      [productType]: prev[productType]?.id === product.id ? null : product,
    }));
  };

  const hasAnySelection = () => {
    if (selectedCategory === "makeup") {
      return Object.values(selectedProducts).some(
        (product) => product !== null
      );
    } else if (selectedCategory === "dress") {
      return selectedDress !== null;
    } else if (selectedCategory === "whole") {
      return selectedLook !== null;
    }
    return false;
  };

  const handleApply = async () => {
    if (selectedCategory === "makeup") {
      if (!uploadingImageId) {
        // alert("Please upload an image first.");
        Swal.fire({
          icon: "warning",
          text: "Please upload an image first.",
          confirmButtonText: "OK",
          confirmButtonColor: "#ed1173",
        })
        return;
      }
      const productIds = Object.values(selectedProducts)
        .filter(Boolean)
        .map((p) => p.id)
        .filter((v) => v !== undefined && v !== null);
      if (productIds.length === 0) {
        // alert("Please select at least one makeup product.");
        Swal.fire({
          icon: "warning",
          text: "Please select at least one makeup product.",
          confirmButtonText: "OK",
          confirmButtonColor: "#ed1173",
        })
        return;
      }
      const payload = {
        image_id: Number(uploadingImageId),
        product_ids: productIds,
        lipstick_intensity: 0.8,
        blush_intensity: 0.2,
        blush_radius: 60,
        eyeshadow_intensity: 0.7,
        eyeshadow_thickness: 20,
        lens_intensity: 0.02,
        lens_radius_scale: 4.8,
        primer_intensity: 0.7,
        primer_tint: "#f5e0d3",
        foundation_intensity: 0.3,
        foundation_tint: "#f5d6c6",
        mascara_intensity: 0.7,
        mascara_thickness: 1,
      };
      try {
        setIsApplying(true);
        const res = await beautyApi.applyMakeup(payload);
        const processedId =
          res?.data?.id ||
          res?.id ||
          res?.image_id ||
          res?.processed_image_id ||
          (Array.isArray(res?.applied_products) &&
            res.applied_products[0]?.processed_image_id);
        const processedUrl = res?.data?.url || res?.url;
        if (processedId || processedUrl) {
          const finalId =
            processedId ||
            (processedUrl
              ? Number((processedUrl.split("/").pop() || "").trim())
              : undefined);
          navigate("/finallook", {
            state: {
              processedImageId: finalId,
              processedImageUrl: processedUrl,
              selectedProducts,
            },
          });
        } else {
          // Fallback: if API returns a url or image data
          const url = res?.data?.url || res?.url || res?.image_url;
          navigate("/finallook", {
            state: {
              selectedImage: url || selectedImage,
              selectedProducts,
            },
          });
        }
      } catch (e) {
        console.error("Apply makeup failed", e);
        // alert("Failed to apply makeup. Please try again.");
        Swal.fire({
          icon: "error",
          text: "Failed to apply makeup. Please try again.",
          confirmButtonText: "OK",
          confirmButtonColor: "#ed1173",
        })
        
      } finally {
        setIsApplying(false);
      }
      return;
    }
    // Default behavior for other categories
    navigate("/finallook", {
      state: {
        selectedImage,
        selectedProducts,
        selectedDress,
        selectedLook,
      },
    });
  };

  // Face validation after capture
  const validateFace = async (imageDataUrl) => {
    setFaceWarning("");
    const img = new window.Image();
    img.src = imageDataUrl;
    await new Promise((resolve) => (img.onload = resolve));
    const detection = await faceapi
      .detectSingleFace(img, new faceapi.TinyFaceDetectorOptions())
      .withFaceLandmarks()
      .withFaceExpressions();
    if (!detection) {
      setFaceWarning("No face detected. Please look straight at the camera.");
      return false;
    }
    // Check face orientation (yaw/pitch/roll)
    const landmarks = detection.landmarks;
    const leftEye = landmarks.getLeftEye();
    const rightEye = landmarks.getRightEye();
    const nose = landmarks.getNose();
    if (leftEye && rightEye && nose) {
      const eyeDist = Math.abs(leftEye[0].x - rightEye[3].x);
      const noseToEye = Math.abs(
        nose[3].x - (leftEye[0].x + rightEye[3].x) / 2
      );
      if (noseToEye > eyeDist * 0.2) {
        setFaceWarning("Please look straight at the camera, not sideways.");
        return false;
      }
    }
    // Glasses/hat detection is advanced; here we just warn if eyes are not visible
    // (for demo, real detection would need a custom model)
    if (leftEye.length === 0 || rightEye.length === 0) {
      setFaceWarning("Please remove glasses or hats covering your eyes.");
      return false;
    }
    return true;
  };

  return (
    <>
      <div className="msp-container">
        <style>{`
          .msp-container {
            min-height: 100vh;
            background: ${colors.white};
            font-family: "Helvetica Neue", Arial, sans-serif;
            color: ${colors.darkGrey};
            line-height: 1.6;
          }

          .msp-main-wrapper {
            max-width: 1400px;
            margin: 0 auto;
            background: ${colors.white};
            box-shadow: 0 5px 25px rgba(0, 0, 0, 0.05);
          }

          .msp-header {
            background: ${colors.white};
            padding: 25px 30px;
            border-bottom: 1px solid rgba(0, 0, 0, 0.08);
            display: flex;
            justify-content: space-between;
            align-items: center;
          }

          .msp-header h2 {
            margin: 0;
            font-weight: 500;
            font-size: 1.8rem;
            color: ${colors.darkGrey};
          }

          .msp-content {
            display: flex;
            min-height: calc(100vh - 120px);
          }

          .msp-left-panel {
            flex: 0 0 380px;
            background: ${colors.lightGrey};
            padding: 30px;
            display: flex;
            flex-direction: column;
            align-items: center;
            border-right: 1px solid rgba(0, 0, 0, 0.05);
          }

          .msp-profile-container {
            width: 100%;
            position: relative;
            z-index: 1;
          }

          .msp-profile-image {
            width: 100%;
            height: 400px;
            border-radius: 20px;
            overflow: hidden;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            background: ${colors.white};
            position: relative;
            margin-bottom: 20px;
            transition: all 0.3s ease;
          }

          .msp-profile-image:hover {
            transform: translateY(-5px);
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.15);
          }

          .msp-profile-image::before {
            content: "";
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(
              to bottom,
              rgba(0, 0, 0, 0) 0%,
              rgba(0, 0, 0, 0.02) 50%,
              rgba(0, 0, 0, 0.1) 100%
            );
            z-index: 1;
            pointer-events: none;
          }

          .msp-profile-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transition: transform 0.3s ease;
          }

          .msp-profile-image:hover img {
            transform: scale(1.05);
          }

          .msp-edit-btn {
            position: absolute;
            top: 16px;
            right: 16px;
            background: ${colors.white};
            color: ${colors.primaryPink};
            border: none;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            z-index: 10;
            transition: all 0.2s ease;
          }

          .msp-edit-btn:hover {
            transform: scale(1.05);
          }

          .msp-profile-label {
            text-align: center;
            margin-top: 10px;
            color: ${colors.grey};
            font-weight: 500;
            font-size: 0.9rem;
            text-transform: uppercase;
            letter-spacing: 1px;
          }

          .msp-upload-options {
            margin-top: 30px;
            width: 100%;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 0 10px;
          }

          .msp-option-card {
            background: ${colors.white};
            border: 2px solid ${colors.border};
            border-radius: 16px;
            padding: 24px 20px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
            overflow: hidden;
          }

          .msp-option-card::before {
            content: "";
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(
              45deg,
              rgba(237, 17, 115, 0.05),
              rgba(237, 17, 115, 0.02)
            );
            opacity: 0;
            transition: opacity 0.3s ease;
          }

          .msp-option-card:hover {
            border-color: ${colors.primary};
            transform: translateY(-4px);
            box-shadow: 0 12px 24px rgba(237, 17, 115, 0.15);
          }

          .msp-option-card:hover::before {
            opacity: 1;
          }

          .msp-option-icon {
            font-size: 32px;
            margin-bottom: 16px;
            color: ${colors.primary};
            background: rgba(237, 17, 115, 0.1);
            width: 70px;
            height: 70px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            transition: all 0.3s ease;
          }

          .msp-option-card:hover .msp-option-icon {
            transform: scale(1.1) rotate(5deg);
            background: rgba(237, 17, 115, 0.15);
          }

          .msp-option-title {
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 8px;
            color: ${colors.darkText};
            position: relative;
          }

          .msp-option-desc {
            font-size: 14px;
            color: ${colors.lightText};
            line-height: 1.5;
            position: relative;
          }

          .msp-right-panel {
            flex: 1;
            display: flex;
            flex-direction: column;
            background: ${colors.white};
          }

          .msp-category-tabs {
            display: flex;
            border-bottom: 1px solid rgba(0, 0, 0, 0.08);
            background: ${colors.white};
            padding: 0 30px;
          }

          .msp-category-tab {
            padding: 20px 25px;
            text-align: center;
            background: none;
            border: none;
            cursor: pointer;
            font-weight: 500;
            font-size: 1rem;
            color: ${colors.grey};
            transition: all 0.2s ease;
            position: relative;
            border-bottom: 2px solid transparent;
          }

          .msp-category-tab:hover {
            color: ${colors.primaryPink};
          }

          .msp-category-tab.active {
            color: ${colors.primaryPink};
            border-bottom: 2px solid ${colors.primaryPink};
          }

          .msp-selection-area {
            flex: 1;
            padding: 30px;
            display: flex;
            flex-direction: column;
            max-height: calc(100vh - 180px);
            overflow-y: auto;
          }

          .msp-section-title {
            color: ${colors.darkGrey};
            font-weight: 500;
            font-size: 1.2rem;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid rgba(0, 0, 0, 0.08);
          }

          .msp-products-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
            gap: 25px;
            margin-bottom: 40px;
          }

          .msp-product-card {
            background: ${colors.white};
            border: 1px solid rgba(0, 0, 0, 0.08);
            border-radius: 8px;
            padding: 15px;
            display: flex;
            flex-direction: column;
            align-items: center;
            position: relative;
            cursor: pointer;
            transition: all 0.2s ease;
            text-align: center;
          }

          .msp-product-image {
            height: 120px;
            width: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 15px;
          }

          .msp-product-image img {
            max-height: 100%;
            max-width: 100%;
            object-fit: contain;
          }

          .msp-product-name {
            font-weight: 500;
            color: ${colors.darkGrey};
            font-size: 0.9rem;
            margin-bottom: 8px;
          }

          .msp-product-color {
            width: 18px;
            height: 18px;
            border-radius: 50%;
            border: 1px solid rgba(0, 0, 0, 0.1);
          }

          .msp-product-card:hover {
            border-color: ${colors.primaryPink};
            box-shadow: 0 5px 15px rgba(237, 17, 115, 0.1);
            transform: translateY(-2px);
          }

          .msp-product-card.selected {
            border-color: ${colors.primaryPink};
            background: rgba(237, 17, 115, 0.03);
            box-shadow: 0 5px 15px rgba(237, 17, 115, 0.1);
          }

          .msp-look-card {
            background: ${colors.white};
            border: 1px solid rgba(0, 0, 0, 0.08);
            border-radius: 8px;
            padding: 20px;
            display: flex;
            align-items: center;
            cursor: pointer;
            transition: all 0.2s ease;
            margin-bottom: 15px;
          }

          .msp-look-image {
            width: 80px;
            height: 80px;
            border-radius: 6px;
            overflow: hidden;
            margin-right: 20px;
            flex-shrink: 0;
          }

          .msp-look-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
          }

          .msp-look-info {
            flex: 1;
          }

          .msp-look-name {
            font-weight: 500;
            color: ${colors.darkGrey};
            font-size: 1rem;
            margin-bottom: 5px;
          }

          .msp-look-description {
            color: ${colors.grey};
            font-size: 0.9rem;
          }

          .msp-look-card:hover {
            border-color: ${colors.primaryPink};
            box-shadow: 0 5px 15px rgba(237, 17, 115, 0.1);
          }

          .msp-look-card.selected {
            border-color: ${colors.primaryPink};
            background: rgba(237, 17, 115, 0.03);
          }

          .msp-apply-button {
            position: fixed;
            bottom: 24px;
            left: 50%;
            transform: translateX(-50%);
            background: ${colors.primaryPink};
            border: none;
            color: ${colors.white};
            padding: 14px 30px;
            border-radius: 6px;
            font-size: 1rem;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.2s ease;
            z-index: 1001;
          }

          /* Apply button is conditionally rendered in React when there is a selection */

          .msp-apply-button:hover {
            background: ${colors.darkPink};
            box-shadow: 0 5px 15px rgba(237, 17, 115, 0.3);
          }

          .msp-apply-button:disabled {
            background: #ccc;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
          }

          /* Camera Modal Styles */
          .msp-camera-modal {
            background: #000;
            width: 100%;
            max-width: 800px;
            border-radius: 20px;
            overflow: hidden;
            position: relative;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
          }

          .msp-camera-content {
            position: relative;
            width: 100%;
            height: 600px;
            background: #000;
            overflow: hidden;
          }

          .msp-camera-header {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            padding: 20px;
            background: linear-gradient(
              to bottom,
              rgba(0, 0, 0, 0.8),
              transparent
            );
            display: flex;
            justify-content: space-between;
            align-items: center;
            z-index: 2;
          }

          .msp-camera-title {
            color: white;
            font-size: 1.2rem;
            font-weight: 500;
            margin: 0;
          }

          .msp-camera-video {
            width: 100%;
            height: 100%;
            object-fit: cover;
            background-color: #000;
            transform: scaleX(-1); /* Mirror effect */
          }

          .msp-guide-text {
            position: absolute;
            top: -30px;
            left: 50%;
            transform: translateX(-50%);
            color: white;
            font-size: 14px;
            background: rgba(0, 0, 0, 0.5);
            padding: 4px 12px;
            border-radius: 12px;
          }

          .msp-camera-overlay {
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            border: 2px solid rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            margin: 20px;
          }

          // .msp-camera-guide {
          //   position: absolute;
          //   top: 50%;
          //   left: 50%;
          //   transform: translate(-50%, -50%);
          //   width: 200px;
          //   height: 200px;
          //   border: 2px solid rgba(237, 17, 115, 0.5);
          //   border-radius: 50%;
          //   box-shadow: 0 0 0 9999px rgba(0, 0, 0, 0.5);
          // }

          .msp-camera-countdown {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            font-size: 120px;
            color: white;
            font-weight: bold;
            text-shadow: 0 0 20px rgba(0, 0, 0, 0.5);
            animation: pulse 1s infinite;
          }

          .msp-camera-controls {
            position: absolute;
            bottom: 30px;
            left: 0;
            right: 0;
            display: flex;
            justify-content: center;
            gap: 30px;
            padding: 0 20px;
            z-index: 2;
          }

          .msp-camera-button {
            background: rgba(255, 255, 255, 0.15);
            backdrop-filter: blur(10px);
            border: 2px solid rgba(255, 255, 255, 0.8);
            color: white;
            width: 70px;
            height: 70px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            font-size: 24px;
          }

          .msp-camera-button:hover {
            background: rgba(255, 255, 255, 0.25);
            transform: translateY(-2px);
            box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3);
          }

          .msp-camera-button.capture {
            background: ${colors.primaryPink};
            border-color: ${colors.primaryPink};
            width: 80px;
            height: 80px;
          }

          .msp-camera-button.capture:hover {
            background: ${colors.darkPink};
            transform: scale(1.1);
          }

          .msp-camera-error {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(0, 0, 0, 0.8);
            color: white;
            padding: 20px 30px;
            border-radius: 10px;
            text-align: center;
            max-width: 80%;
          }

          .msp-face-warning {
            color: #fff;
            background: #ed1173;
            padding: 12px 20px;
            border-radius: 10px;
            margin: 20px auto 0 auto;
            text-align: center;
            font-size: 1rem;
            max-width: 90%;
            box-shadow: 0 2px 8px rgba(237, 17, 115, 0.15);
            z-index: 10;
            position: relative;
          }

          @keyframes pulse {
            0% {
              transform: translate(-50%, -50%) scale(1);
              opacity: 1;
            }
            50% {
              transform: translate(-50%, -50%) scale(1.2);
              opacity: 0.8;
            }
            100% {
              transform: translate(-50%, -50%) scale(1);
              opacity: 1;
            }
          }

          /* Modal Styles */
          .msp-modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.5);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 1000;
          }

          .msp-modal {
            background: white;
            padding: 32px;
            border-radius: 12px;
            width: 400px;
            max-width: 90%;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
            text-align: center;
          }

          .msp-modal-title {
            font-size: 20px;
            font-weight: 600;
            margin-bottom: 16px;
            color: ${colors.darkGrey};
          }

          .msp-modal-text {
            color: ${colors.grey};
            margin-bottom: 24px;
            line-height: 1.6;
          }

          .msp-modal-buttons {
            display: flex;
            justify-content: center;
            gap: 16px;
          }

          .msp-btn-primary,
          .msp-btn-secondary {
            padding: 12px 24px;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            border: none;
            transition: all 0.2s ease;
            font-size: 14px;
          }

          .msp-btn-primary {
            background: ${colors.primaryPink};
            color: white;
          }

          .msp-btn-primary:hover {
            background: ${colors.darkPink};
          }

          .msp-btn-secondary {
            background: #f8f9fa;
            color: #495057;
            border: 1px solid #e9ecef;
          }

          .msp-btn-secondary:hover {
            background: #e9ecef;
          }

          .msp-instructions-modal {
            background: white;
            padding: 40px;
            border-radius: 12px;
            width: 90%;
            max-width: 800px;
            max-height: 80vh;
            overflow-y: auto;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
          }

          .msp-instructions-title {
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 24px;
            text-align: center;
            color: ${colors.darkText};
          }

          .msp-instructions-content {
            margin-bottom: 32px;
          }

          .msp-instructions-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
            margin-bottom: 32px;
          }

          .msp-instructions-buttons {
            display: flex;
            justify-content: center;
            gap: 16px;
            margin-top: 24px;
          }

          .msp-tip-item {
            display: flex;
            align-items: center;
            gap: 12px;
          }

          .msp-tip-icon {
            width: 24px;
            height: 24px;
            border-radius: 50%;
            background: #f0f0f0;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
          }

          .msp-tip-check {
            color: #28a745;
          }

          .msp-tip-cross {
            color: #dc3545;
          }

          .msp-tip-text {
            font-size: 14px;
            color: ${colors.darkText};
          }

          /* Responsive Design */
          @media (max-width: 1024px) {
            .msp-left-panel {
              flex: 0 0 320px;
              padding: 20px;
            }

            .msp-profile-image {
              height: 350px;
            }

            .msp-category-tabs {
              padding: 0 20px;
            }

            .msp-category-tab {
              padding: 18px 20px;
            }

            .msp-selection-area {
              padding: 20px;
            }

            .msp-products-grid {
              grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
              gap: 20px;
            }
          }

          @media (max-width: 768px) {
            .msp-content {
              flex-direction: column;
            }

            .msp-left-panel {
              flex: none;
              padding: 20px;
              border-right: none;
              border-bottom: 1px solid rgba(0, 0, 0, 0.05);
            }

            .msp-profile-image {
              width: 280px;
              height: 350px;
              margin: 0 auto;
            }

            .msp-category-tabs {
              flex-wrap: wrap;
              padding: 0;
            }

            .msp-category-tab {
              flex: 1;
              min-width: 120px;
              padding: 15px;
              font-size: 0.9rem;
            }

            .msp-products-grid {
              grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
              gap: 15px;
            }

            .msp-product-image {
              height: 100px;
            }
          }

          @media (max-width: 480px) {
            .msp-header {
              padding: 20px;
            }

            .msp-header h2 {
              font-size: 1.5rem;
            }

            .msp-profile-image {
              width: 100%;
              height: 280px;
            }

            .msp-category-tab {
              min-width: 100px;
              padding: 12px 10px;
              font-size: 0.85rem;
            }

            .msp-products-grid {
              grid-template-columns: repeat(2, 1fr);
              gap: 12px;
            }

            .msp-product-card {
              padding: 12px;
            }

            .msp-product-image {
              height: 90px;
            }

            .msp-look-card {
              flex-direction: column;
              text-align: center;
            }

            .msp-look-image {
              margin-right: 0;
              margin-bottom: 15px;
            }

            .msp-modal-buttons {
              flex-direction: column;
            }
          }
        `}</style>
        <div className="msp-main-wrapper">
          <div className="msp-header">
            <h2>Create Your Look</h2>
          </div>

          <div className="msp-content">
            <div className="msp-left-panel">
              <div className="msp-profile-container">
                <div className="msp-profile-image">
                  {selectedImage ? (
                    <>
                      <img src={selectedImage} alt="Profile" />
                      <button
                        className="msp-edit-btn"
                        onClick={() => setShowEditModal(true)}
                      >
                        ✏
                      </button>
                    </>
                  ) : (
                    <div
                      style={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        height: "100%",
                        flexDirection: "column",
                        padding: "20px",
                        textAlign: "center",
                      }}
                    >
                      <img
                        src="/images/npProfile.png"
                        alt="Default Profile"
                        style={{
                          width: "90px",
                          height: "90px",
                          objectFit: "cover",
                          borderRadius: "50%",
                          marginBottom: "16px",
                          background: "#eee",
                        }}
                      />
                      <p>Upload your photo to get started</p>
                    </div>
                  )}
                </div>

                <div className="msp-profile-label">Your Style Canvas</div>

                <div className="msp-upload-options">
                  <div className="msp-option-card" onClick={openImageOptions}>
                    <div className="msp-option-icon">
                      <IoCloudUploadOutline />
                    </div>
                    <div className="msp-option-title">Upload Photo</div>
                    <div className="msp-option-desc">
                      Select an image from your device
                    </div>
                  </div>

                  <div className="msp-option-card" onClick={startCamera}>
                    <div className="msp-option-icon">
                      <IoCameraOutline />
                    </div>
                    <div className="msp-option-title">Live Camera</div>
                    <div className="msp-option-desc">
                      Capture a new photo with your camera
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="msp-right-panel">
              <div className="msp-category-tabs">
                <button
                  className={`msp-category-tab ${
                    selectedCategory === "makeup" ? "active" : ""
                  }`}
                  onClick={() => handleCategorySelect("makeup")}
                >
                  Makeup
                </button>
                <button
                  className={`msp-category-tab ${
                    selectedCategory === "dress" ? "active" : ""
                  }`}
                  onClick={() => handleCategorySelect("dress")}
                >
                  Dress
                </button>
                <button
                  className={`msp-category-tab ${
                    selectedCategory === "whole" ? "active" : ""
                  }`}
                  onClick={() => handleCategorySelect("whole")}
                >
                  Complete Looks
                </button>
              </div>

              <div className="msp-selection-area">
                {selectedCategory === "makeup" && (
                  <>
                    <div className="msp-section-title">Lipstick</div>
                    <div className="msp-products-grid">
                      {(isLoadingProducts ? [] : apiProducts.lipstick).map(
                        (product) => (
                          <div
                            key={product.id}
                            className={`msp-product-card ${
                              selectedProducts.lipstick?.id === product.id
                                ? "selected"
                                : ""
                            }`}
                            onClick={() =>
                              handleProductSelect("lipstick", product)
                            }
                          >
                            <div className="msp-product-image">
                              <img src={product.image} alt={product.name} />
                            </div>
                            <div className="msp-product-name">
                              {product.name}
                            </div>
                            {product.color && (
                              <span
                                className="msp-product-color"
                                style={{ backgroundColor: product.color }}
                              ></span>
                            )}
                          </div>
                        )
                      )}
                      {!isLoadingProducts &&
                        apiProducts.lipstick.length === 0 && (
                          <div style={{ color: colors.grey }}>
                            No lipstick products.
                          </div>
                        )}
                    </div>

                    <div className="msp-section-title">Blush</div>
                    <div className="msp-products-grid">
                      {(isLoadingProducts ? [] : apiProducts.blush).map(
                        (product) => (
                          <div
                            key={product.id}
                            className={`msp-product-card ${
                              selectedProducts.blush?.id === product.id
                                ? "selected"
                                : ""
                            }`}
                            onClick={() =>
                              handleProductSelect("blush", product)
                            }
                          >
                            <div className="msp-product-image">
                              <img src={product.image} alt={product.name} />
                            </div>
                            <div className="msp-product-name">
                              {product.name}
                            </div>
                            {product.color && (
                              <span
                                className="msp-product-color"
                                style={{ backgroundColor: product.color }}
                              ></span>
                            )}
                          </div>
                        )
                      )}
                      {!isLoadingProducts && apiProducts.blush.length === 0 && (
                        <div style={{ color: colors.grey }}>
                          No blush products.
                        </div>
                      )}
                    </div>

                    <div className="msp-section-title">Eyeshadow</div>
                    <div className="msp-products-grid">
                      {(isLoadingProducts ? [] : apiProducts.eyeshadow).map(
                        (product) => (
                          <div
                            key={product.id}
                            className={`msp-product-card ${
                              selectedProducts.eyeshadow?.id === product.id
                                ? "selected"
                                : ""
                            }`}
                            onClick={() =>
                              handleProductSelect("eyeshadow", product)
                            }
                          >
                            <div className="msp-product-image">
                              <img src={product.image} alt={product.name} />
                            </div>
                            <div className="msp-product-name">
                              {product.name}
                            </div>
                            {product.color && (
                              <span
                                className="msp-product-color"
                                style={{ backgroundColor: product.color }}
                              ></span>
                            )}
                          </div>
                        )
                      )}
                      {!isLoadingProducts &&
                        apiProducts.eyeshadow.length === 0 && (
                          <div style={{ color: colors.grey }}>
                            No eyeshadow products.
                          </div>
                        )}
                    </div>

                    <div className="msp-section-title">Foundation</div>
                    <div className="msp-products-grid">
                      {(isLoadingProducts ? [] : apiProducts.foundation).map(
                        (product) => (
                          <div
                            key={product.id}
                            className={`msp-product-card ${
                              selectedProducts.foundation?.id === product.id
                                ? "selected"
                                : ""
                            }`}
                            onClick={() =>
                              handleProductSelect("foundation", product)
                            }
                          >
                            <div className="msp-product-image">
                              <img src={product.image} alt={product.name} />
                            </div>
                            <div className="msp-product-name">
                              {product.name}
                            </div>
                            {product.color && (
                              <span
                                className="msp-product-color"
                                style={{ backgroundColor: product.color }}
                              ></span>
                            )}
                          </div>
                        )
                      )}
                      {!isLoadingProducts &&
                        apiProducts.foundation.length === 0 && (
                          <div style={{ color: colors.grey }}>
                            No foundation products.
                          </div>
                        )}
                    </div>
                  </>
                )}

                {selectedCategory === "dress" && (
                  <>
                    <div className="msp-section-title">Select Dress</div>
                    <div className="msp-products-grid">
                      {dresses.map((dress) => (
                        <div
                          key={dress.id}
                          className={`msp-product-card ${
                            selectedDress?.id === dress.id ? "selected" : ""
                          }`}
                          onClick={() =>
                            setSelectedDress(
                              selectedDress?.id === dress.id ? null : dress
                            )
                          }
                        >
                          <div className="msp-product-image">
                            <img src={dress.image} alt={dress.name} />
                          </div>
                          <div className="msp-product-name">{dress.name}</div>
                          <span
                            className="msp-product-color"
                            style={{ backgroundColor: dress.color }}
                          ></span>
                        </div>
                      ))}
                    </div>
                  </>
                )}

                {selectedCategory === "whole" && (
                  <>
                    <div className="msp-section-title">Complete Looks</div>
                    {wholeLooks.map((look) => (
                      <div
                        key={look.id}
                        className={`msp-look-card ${
                          selectedLook?.id === look.id ? "selected" : ""
                        }`}
                        onClick={() =>
                          setSelectedLook(
                            selectedLook?.id === look.id ? null : look
                          )
                        }
                      >
                        <div className="msp-look-image">
                          <img src={look.image} alt={look.name} />
                        </div>
                        <div className="msp-look-info">
                          <div className="msp-look-name">{look.name}</div>
                          <div className="msp-look-description">
                            {look.description}
                          </div>
                        </div>
                      </div>
                    ))}
                  </>
                )}

                {selectedCategory && hasAnySelection() && (
                  <button className="msp-apply-button" onClick={handleApply}>
                    Apply
                    {selectedCategory === "makeup"
                      ? "Makeup"
                      : selectedCategory === "dress"
                      ? "Dress"
                      : "Look"}
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
        {/* Modals */}
        {showEditModal && (
          <div className="msp-modal-overlay">
            <div className="msp-modal">
              <h5 className="msp-modal-title">Edit Photo</h5>
              <p className="msp-modal-text">
                What would you like to do with this photo?
              </p>
              <div className="msp-modal-buttons">
                <button
                  className="msp-btn-primary"
                  onClick={triggerEditFileInput}
                >
                  Choose New Photo
                </button>
                <button
                  className="msp-btn-secondary"
                  onClick={() => setShowEditModal(false)}
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        )}
        {showInstructionsModal && (
          <div className="msp-modal-overlay">
            <div className="msp-instructions-modal">
              <h4 className="msp-instructions-title">Capture Your Face</h4>
              <div className="msp-instructions-content">
                <p className="msp-modal-text">
                  For accurate results, please follow these guidelines:
                </p>
                <div className="msp-instructions-grid">
                  <div className="msp-tip-item">
                    <span className="msp-tip-icon msp-tip-check">✅</span>
                    <span className="msp-tip-text">Good lighting</span>
                  </div>
                  <div className="msp-tip-item">
                    <span className="msp-tip-icon msp-tip-check">✅</span>
                    <span className="msp-tip-text">Remove glasses</span>
                  </div>
                  <div className="msp-tip-item">
                    <span className="msp-tip-icon msp-tip-check">✅</span>
                    <span className="msp-tip-text">Put hair back</span>
                  </div>
                  <div className="msp-tip-item">
                    <span className="msp-tip-icon msp-tip-check">✅</span>
                    <span className="msp-tip-text">No makeup face</span>
                  </div>
                  <div className="msp-tip-item">
                    <span className="msp-tip-icon msp-tip-check">✅</span>
                    <span className="msp-tip-text">
                      Look straight at camera
                    </span>
                  </div>
                  <div className="msp-tip-item">
                    <span className="msp-tip-icon msp-tip-check">✅</span>
                    <span className="msp-tip-text">Neutral expression</span>
                  </div>
                </div>
              </div>
              <div className="msp-instructions-buttons">
                <button className="msp-btn-primary" onClick={triggerFileInput}>
                  Upload Photo
                </button>
                <button
                  className="msp-btn-secondary"
                  onClick={() => setShowInstructionsModal(false)}
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        )}
        {/* Camera Modal */}
        {showCameraModal && (
          <div className="msp-modal-overlay">
            <div className="msp-camera-modal">
              <div className="msp-camera-header">
                <h3 className="msp-camera-title">Take Your Photo</h3>
                <button
                  className="msp-camera-button"
                  onClick={stopCamera}
                  aria-label="Close camera"
                >
                  ✕
                </button>
              </div>
              <div className="msp-camera-content">
                {cameraError ? (
                  <div className="msp-camera-error">
                    <p>{cameraError}</p>
                    <button
                      className="msp-btn-primary"
                      onClick={() => {
                        setCameraError(null);
                        startCamera();
                      }}
                    >
                      Try Again
                    </button>
                  </div>
                ) : (
                  <>
                    <video
                      ref={videoRef}
                      className="msp-camera-video"
                      autoPlay
                      playsInline
                      muted
                    />
                    <div className="msp-camera-overlay" />
                    <div className="msp-camera-guide" />
                    {countdown && (
                      <div className="msp-camera-countdown">{countdown}</div>
                    )}
                    {isCameraReady && (
                      <div className="msp-camera-controls">
                        <button
                          className="msp-camera-button"
                          onClick={() => {
                            if (videoRef.current.style.transform) {
                              videoRef.current.style.transform = "";
                            } else {
                              videoRef.current.style.transform = "scaleX(-1)";
                            }
                          }}
                          aria-label="Flip camera"
                        >
                          ⟲
                        </button>
                        <button
                          className="msp-camera-button capture"
                          onClick={startCountdown}
                          aria-label="Take photo"
                          disabled={!!countdown}
                        >
                          {countdown ? countdown : "📸"}
                        </button>
                      </div>
                    )}
                  </>
                )}
              </div>
              <canvas ref={canvasRef} style={{ display: "none" }} />
              {faceWarning && (
                <div className="msp-face-warning">{faceWarning}</div>
              )}
            </div>
          </div>
        )}{" "}
        {/* Hidden file inputs */}
        <input
          type="file"
          ref={fileInputRef}
          onChange={handleImageSelect}
          accept="image/*"
          style={{ display: "none" }}
        />
        <input
          type="file"
          ref={editFileInputRef}
          onChange={handleEditImage}
          accept="image/*"
          style={{ display: "none" }}
        />
      </div>
    </>
  );
};

export default ProfileImageSelector;
