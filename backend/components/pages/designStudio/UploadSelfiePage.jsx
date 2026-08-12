import React, { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import * as faceapi from "face-api.js";
import { beautyApi } from "../../../services/api";
import Swal from "sweetalert2";
import { IoClose } from "react-icons/io5";
import { FaHome, FaTimes } from "react-icons/fa";
import { useSelector } from "react-redux";
// import { getErrorMessage } from "./Services";

const UploadSelfiePage = () => {
  const navigate = useNavigate();
  const fileRef = useRef(null);
  const videoRef = useRef(null);
  const canvasRef = useRef(null);
  const [showGuide, setShowGuide] = useState(false);
  const [stream, setStream] = useState(null);
  const [countdown, setCountdown] = useState(null);
  const [cameraError, setCameraError] = useState(null);
  const [isCameraReady, setIsCameraReady] = useState(false);
  const [uploading, setUploading] = useState(false);

  const userInfo = JSON.parse(localStorage.getItem("userInfo")) || {};
  const { role, type } = userInfo;
  const controllerRef = useRef(null);

  const getErrorMessage = (err) => {
    try {
      if (!err) return "Upload failed. Please try again.";

      const resp = err.response || err?.request?.response;
      if (resp) {
        const data =
          typeof resp.data === "string"
            ? (() => {
                try {
                  return JSON.parse(resp.data);
                } catch {
                  return null;
                }
              })()
            : resp.data;
        if (data?.error) return String(data.error);
        if (data?.message) return String(data.message);
        if (typeof resp.statusText === "string" && resp.statusText)
          return resp.statusText;
      }

      if (typeof err.message === "string") {
        const jsonMatch = err.message.match(/{[\s\S]*}/);
        if (jsonMatch) {
          try {
            const parsed = JSON.parse(jsonMatch[0]);
            if (parsed?.error) return String(parsed.error);
            if (parsed?.message) return String(parsed.message);
          } catch {}
        }
        const colonIdx = err.message.indexOf(":");
        if (colonIdx !== -1 && colonIdx + 1 < err.message.length) {
          const after = err.message.slice(colonIdx + 1).trim();
          if (after && !after.startsWith("{")) return after;
        }
        return err.message;
      }

      if (typeof err === "string") return err;
      return "Upload failed. Please try again.";
    } catch {
      return "Upload failed. Please try again.";
    }
  };

  let image;
  switch (role) {
    case "bride":
      if (type === "makeup") image = "/images/try/bride-makeup.png";
      else if (type === "jewellary") image = "/images/try/bride-jewellery.png";
      else if (type === "outfit") image = "/images/try/bride-outfit.png";
      break;
    case "groom":
      if (type === "makeup") image = "/images/try/upload-groome-default.png";
      else if (type === "jewellary")
        image = "/images/try/upload-groome-default.png";
      else if (type === "outfit")
        image = "/images/try/upload-groome-default.png";
      break;

    default:
      break;
  }

  useEffect(() => {
    const loadModels = async () => {
      const MODEL_URL = "/models";
      await faceapi.nets.tinyFaceDetector.loadFromUri(MODEL_URL);
      await faceapi.nets.faceLandmark68Net.loadFromUri(MODEL_URL);
    };
    loadModels();
  }, []);

  useEffect(() => {
    if (showGuide) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "auto";
    }
    

    return () => {
      document.body.style.overflow = "auto";
    };
  }, [showGuide]);

  const handlePick = () => setShowGuide(true);

  const instructionSets = {
    bride: {
      makeup: [
        {
          src: "/images/try/staightFace.png",
          text: "Look straight at the camera",
        },
        { src: "/images/try/putHairBack.png", text: "Put hair back" },
        { src: "/images/try/removeGlasses.png", text: "Remove Glasses" },
        { src: "/images/try/planeBg.png", text: "Use plain background" },
      ],
      jewellary: [
        {
          src: "/images/try/staightFace.png",
          text: "Look straight at the camera",
        },
        { src: "/images/try/putHairBack.png", text: "Put hair back" },
        { src: "/images/try/removeGlasses.png", text: "Remove Glasses" },
        { src: "/images/try/planeBg.png", text: "Use plain background" },
      ],
      outfit: [
        {
          src: "/images/try/fullBodyImage.png",
          text: "Capture a full-body image showing the person from head to toe.",
        },
        {
          src: "/images/try/standStraight.png",
          text: "The person should stand staright in a natural, relaxed pose.",
        },
        {
          src: "/images/try/lookStraight.png",
          text: "The person should look staright at the camera with a calm expression.",
        },
        {
          src: "/images/try/flaredDesign.png",
          text: "The outfit should have a flared design (like a gown or dress with flow.)",
        },
      ],
    },
    groom: {
      makeup: [
        {
          src: "/images/try/straightFace.png",
          text: "Look straight at the camera",
        },
        { src: "/images/try/hairBack.png", text: "Put hair back" },
        { src: "/images/try/straightFace.png", text: "Remove glasses" },
        { src: "/images/try/straightFace.png", text: "Plain background" },
      ],
      outfit: [],
      jewellaery: [],
    },
    others: {
      makeup: [
        { src: "", text: "Face the camera" },
        { src: "", text: "Avoid shadows" },
        { src: "", text: "Remove accessories" },
        { src: "", text: "Use plain background" },
      ],
      outfit: [],
      jewellaery: [],
    },
  };

  // const validateFace = async (imageDataUrl) => {
  //   const img = new window.Image();
  //   img.src = imageDataUrl;
  //   await new Promise((r) => (img.onload = r));
  //   const detection = await faceapi
  //     .detectSingleFace(img, new faceapi.TinyFaceDetectorOptions())
  //     .withFaceLandmarks();
  //   return !!detection;
  // };

  const handleFile = async (e) => {
    setUploading(true);
    const file = e.target.files?.[0];
    if (!file) {
      setUploading(false);
      if (fileRef.current) fileRef.current.value = "";
      return;
    }
    if (!file.type.startsWith("image/")) {
      Swal.fire({
        icon: "error",
        title: "Oops...",
        text: "Please select an image file",
      });
      setUploading(false);
      if (fileRef.current) fileRef.current.value = "";
      return;
    }
    const reader = new FileReader();
    reader.onload = async (ev) => {
      // const dataUrl = ev.target.result;
      // const ok = await validateFace(dataUrl);
      // if (!ok) {
      //   Swal.fire({
      //     icon: "error",
      //     title: "Oops...",
      //     text: "No face detected. Please choose a clear frontal photo.",
      //   });
      //   setUploading(false);
      //   if (fileRef.current) fileRef.current.value = "";
      //   return;
      // }
      try {
        if (type === "outfit" || type === "jewellary") {
          setShowGuide(false);
          setUploading(true);
          const localUrl = URL.createObjectURL(file);
          sessionStorage.setItem("try_uploaded_outfit_image_url", localUrl);
          setUploading(false);
          navigate("/try/outfit-filters");
          return;
        }
        controllerRef.current = new AbortController();
        const res = await beautyApi.uploadImage(
          file,
          "ORIGINAL",
          controllerRef.current.signal
        );
        const imageId = res?.data?.id || res?.id || res?.image_id;
        sessionStorage.setItem("try_uploaded_image_id", imageId);
        setShowGuide(false);
        setUploading(false);
        navigate("/try/filters");
      } catch (err) {
        const message = getErrorMessage(err);

        Swal.fire({
          icon: "error",
          title: "Upload failed",
          text: message || "Internal Server Error",
          timer: 3000,
          confirmButtonText: "OK",
          confirmButtonColor: "#ed1173",
        });
      } finally {
        setUploading(false);
        if (fileRef.current) fileRef.current.value = "";
      }
    };
    reader.readAsDataURL(file);
  };

  const handleCancelUpload = () => {
    if (controllerRef.current) {
      controllerRef.current.abort();
      return;
    }
  };

  const startCamera = async () => {
    try {
      const streamLocal = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: "user",
          width: { ideal: 1280 },
          height: { ideal: 720 },
        },
        audio: false,
      });
      if (videoRef.current) {
        videoRef.current.srcObject = streamLocal;
        await videoRef.current.play();
        setStream(streamLocal);
        setIsCameraReady(true);
      }
    } catch (e) {
      console.error(e);
      setCameraError("Unable to access camera. Check permissions.");
    }
  };

  const stopCamera = () => {
    stream?.getTracks()?.forEach((t) => t.stop());
    setStream(null);
    setIsCameraReady(false);
  };

  const capture = async () => {
    const video = videoRef.current;
    const canvas = canvasRef.current;
    if (!video || !canvas) return;
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const ctx = canvas.getContext("2d");
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    const dataUrl = canvas.toDataURL("image/jpeg", 0.95);
    // const ok = await validateFace(dataUrl);
    // if (!ok) {
    //   // alert("No face detected. Please look straight.");
    //   Swal.fire({
    //     icon: "error",
    //     title: "Oops...",
    //     text: "No face detected. Please look straight.",
    //     confirmButtonText: "OK",
    //     confirmButtonColor: "#ed1173",
    //   });

    //   return;
    // }
    // Convert dataURL to Blob for upload
    const blob = await (await fetch(dataUrl)).blob();
    const file = new File([blob], "selfie.jpg", { type: "image/jpeg" });
    try {
      if (type === "outfit" || type === "jewellary") {
        setShowGuide(false);
        navigate("/try/outfit-filters");
        return;
      }
      const res = await beautyApi.uploadImage(file, "ORIGINAL");
      const imageId = res?.data?.id || res?.id || res?.image_id;
      sessionStorage.setItem("try_uploaded_image_id", imageId);
      setShowGuide(false);
      navigate(
        type === "outfit" || type === "jewellary"
          ? "/try/outfit-filters"
          : "/try/filters"
      );
    } catch (e) {
      console.error("Camera upload error:", e);
      const msg = getErrorMessage(e);
      Swal.fire({
        icon: "error",
        title: "Upload failed",
        text: msg,
        timer: 3000,
        confirmButtonText: "OK",
        confirmButtonColor: "#ed1173",
      });
    } finally {
      stopCamera();
    }
  };

  const startCountdown = () => {
    setCountdown(3);
    const timer = setInterval(() => {
      setCountdown((p) => {
        if (p <= 1) {
          clearInterval(timer);
          capture();
          return null;
        }
        return p - 1;
      });
    }, 1000);
  };

  const triggerModalUpload = () => {
    if (fileRef.current) fileRef.current.value = "";
    fileRef.current?.click();
  };

  return (
    <div className="container py-1">
      <div className="row g-4">
        {/* <div className="col-12 text-center">
          <h2 className="fw-semibold">Upload your image or take a selfie</h2>
          <p className="text-muted">We will guide you for best results</p>
        </div> */}

        <div className="py-2 d-flex flex-column align-items-center justify-content-center">
          <div
            className="card shadow-sm border-0 text-center"
            style={{ maxWidth: 450, width: "100%", overflow: "hidden" }}
          >
            <div className="mb-3">
              <div
                style={{
                  position: "absolute",
                  top: 14,
                  left: 14,
                  width: 36,
                  height: 36,
                  borderRadius: "50%",
                  background: "#E0006C",
                  color: "#fff",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  boxShadow: "0 3px 10px rgba(0,0,0,0.25)",
                  cursor: "pointer",
                  zIndex: 10,
                }}
                title="Home"
                onClick={() => navigate("/try")}
              >
                <FaHome size={18} />
              </div>
              <div
                style={{
                  position: "absolute",
                  top: 14,
                  right: 14,
                  width: 36,
                  height: 36,
                  borderRadius: "50%",
                  background: "#E0006C",
                  color: "#fff",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  boxShadow: "0 3px 10px rgba(0,0,0,0.25)",
                  cursor: "pointer",
                  zIndex: 10,
                }}
                onClick={() => navigate(-1)}
              >
                <FaTimes size={18} />
              </div>
              <div>
                <img
                  src={image}
                  alt="placeholder"
                  className="img-fluid"
                  style={{
                    width: "100%",
                    height: "380px",
                    objectFit: "cover",
                  }}
                />
              </div>
            </div>

            <div className="w-100 d-flex flex-column justify-content-center align-items-center mb-4">
              <div className="col-12 text-start w-75">
                <h3 className="fw-semibold">Virtual Try - On</h3>
                <p className="text-muted">We will guide you for best results</p>
              </div>

              <div className="d-flex gap-3 flex-column justify-content-center w-75">
                {/* <button
                  className="btn w-100"
                  style={{
                    background: "linear-gradient(to right, #E83580, #821E48)",
                    color: "#fff",
                    padding: "10px 0",
                  }}
                >
                  Selfie Mode
                </button> */}
                <button
                  className="btn w-100"
                  onClick={handlePick}
                  style={{
                    background: "linear-gradient(to right, #E83580, #821E48)",
                    color: "#fff",
                    padding: "10px 0",
                  }}
                >
                  Upload Image
                </button>
              </div>
            </div>
          </div>

          {/* Hidden file input */}
          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            className="d-none"
            onChange={handleFile}
          />
        </div>
      </div>

      <canvas ref={canvasRef} className="d-none" />

      {showGuide && (
        <>
          {/* Backdrop */}
          <div
            className="modal-backdrop show"
            style={{
              backdropFilter: "blur(10px)",
              backgroundColor: "rgba(255,255,255,1)",
            }}
          />

          <div
            className="modal fade show d-block"
            tabIndex="-1"
            role="dialog"
            aria-modal="true"
            style={{ overflow: "hidden" }}
          >
            <div className="modal-dialog modal-dialog-centered rounded-0">
              <div className="modal-content rounded-0 relative">
                <div className="modal-header border-0 position-relative">
                  <div className="d-flex flex-column">
                    <h4 className="modal-title text-danger fw-bold">
                      Photo Instruction
                    </h4>
                    <p className="modal-title text-dark">
                      For accurate results, please follow these guidelines:
                    </p>
                  </div>
                  <button
                    type="button"
                    className="position-absolute"
                    onClick={() => {
                      setShowGuide(false);
                      handleCancelUpload();
                    }}
                    style={{
                      color: "#C31162",
                      top: 10,
                      right: 10,
                      border: "none",
                      background: "transparent",
                    }}
                  >
                    <IoClose size={30} />
                  </button>
                </div>
                <div className="modal-body">
                  <ul className="list-unstyled mb-4">
                    {instructionSets[role][type]?.map((item, i) => (
                      <React.Fragment key={i}>
                        <li className="d-flex align-items-center mb-3 py-2">
                          <img
                            src={item.src}
                            alt={item.text}
                            style={{
                              width: 70,
                              height: 70,
                              objectFit: "contain",
                              // border: "1px solid #ddd",
                              // borderRadius: "10px",
                              padding: 4,
                              marginRight: 12,
                            }}
                          />
                          <span>{item.text}</span>
                        </li>
                        {i !== instructionSets[role].length - 1 && <hr />}
                      </React.Fragment>
                    ))}
                  </ul>

                  {type === "makeup" && (
                    <div className="d-grid">
                      <button
                        className="btn w-100"
                        onClick={triggerModalUpload}
                        disabled={uploading}
                        style={{
                          background:
                            "linear-gradient(to right, #E83580, #821E48)",
                          color: "#fff",
                          padding: "10px 0",
                        }}
                      >
                        {uploading ? "Uploading..." : "Upload Photo"}
                      </button>
                    </div>
                  )}
                  {(type === "outfit" || type === "jewellary") && (
                    <div className="d-grid">
                      <button
                        className="btn w-100"
                        onClick={() => navigate("/try/outfit-filters")}
                        style={{
                          background:
                            "linear-gradient(to right, #E83580, #821E48)",
                          color: "#fff",
                          padding: "10px 0",
                        }}
                      >
                        Continue
                      </button>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default UploadSelfiePage;
