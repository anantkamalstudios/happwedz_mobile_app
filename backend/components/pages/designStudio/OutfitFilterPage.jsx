// import React, { useEffect, useRef, useState } from "react";
// import { useNavigate } from "react-router-dom";
// import Swal from "sweetalert2";
// import { FaHome } from "react-icons/fa";
// import { IoClose } from "react-icons/io5";
// import { Download, Heart, Loader, Share } from "lucide-react";
// import { MdRestartAlt } from "react-icons/md";
// import {
//   ReactCompareSlider,
//   ReactCompareSliderImage,
// } from "react-compare-slider";
// import axios from "axios";

// const buttons = ["Shades", "Compare", "Complete Look"];
// const BASE_API = "https://www.happywedz.com/ai";
// const CATALOG_API = `${BASE_API}/api/catalog/items`;
// const TRYON_CLOTHES_API = `${BASE_API}/api/tryon/clothes`;
// const TRYON_JEWELRY_API = `${BASE_API}/api/tryon/jewelry`;

// export default function FiltersPageOutfit() {
//   const navigate = useNavigate();
//   const [appliedOutfit, setAppliedOutfit] = useState(null);

//   const selfieInputRef = useRef(null);

//   const [originalUrl, setOriginalUrl] = useState(null);
//   const [previewUrl, setPreviewUrl] = useState(null);
//   const [isCompareMode, setIsCompareMode] = useState(false);
//   const [isApplying, setIsApplying] = useState(false);
//   const [activeBtn, setActiveBtn] = useState(buttons[0]);
//   const [showShareMenu, setShowShareMenu] = useState(false);
//   const [errorMsg, setErrorMsg] = useState("");
//   const [productList, setProductList] = useState([]);
//   const [selectedProduct, setSelectedProduct] = useState(null);
//   const [isLoading, setIsLoading] = useState(false);
//   const [tryOnResult, setTryOnResult] = useState(null);
//   const [tryOnError, setTryOnError] = useState(null);

//   const pollRef = useRef(null);
//   const lastBlobUrlRef = useRef(null);
//   const originalImageRef = useRef(null);

//   const clearPoll = () => {
//     if (pollRef.current) {
//       clearInterval(pollRef.current);
//       pollRef.current = null;
//     }
//   };

//   const getCategoryFromStorage = () => {
//     try {
//       const userInfoStr = localStorage.getItem("userInfo");
//       if (userInfoStr) {
//         const userInfo = JSON.parse(userInfoStr);
//         return userInfo?.type || null;
//       }
//     } catch (error) {
//       console.error("Error parsing userInfo from localStorage:", error);
//     }
//     return null;
//   };

//   const fetchProducts = async () => {
//     try {
//       let category = getCategoryFromStorage();
//       console.log("Fetching products for category:", category);

//       if (!category) {
//         console.warn(
//           "No category found in localStorage. Defaulting to 'outfit'"
//         );
//         category = "outfit";
//       }

//       // Map 'jewellary' to 'jewelry' for the API call
//       const apiCategory = category === "jewellary" ? "jewelry" : category;
//       console.log("Calling API with category:", apiCategory);

//       const response = await axios.get(CATALOG_API, {
//         params: { category: apiCategory },
//       });

//       console.log("API Response:", response.data);

//       if (response.data?.ok && Array.isArray(response.data.items)) {
//         setProductList(response.data.items);
//         console.log("Products loaded:", response.data.items.length);
//       } else {
//         console.error("Invalid response format:", response.data);
//         setProductList([]);
//       }
//     } catch (error) {
//       console.error("Error fetching products:", error);
//       if (error.response) {
//         console.error(
//           "Response error:",
//           error.response.status,
//           error.response.data
//         );
//       } else if (error.request) {
//         console.error("Request error - no response received:", error.request);
//       } else {
//         console.error("Error setting up request:", error.message);
//       }
//       setProductList([]);
//     }
//   };

//   useEffect(() => {
//     fetchProducts();
//     return () => {
//       clearPoll();
//       if (lastBlobUrlRef.current) {
//         try {
//           URL.revokeObjectURL(lastBlobUrlRef.current);
//         } catch {}
//         lastBlobUrlRef.current = null;
//       }
//     };
//   }, []);
//   const pollForResult = async (
//     sessionId,
//     apiUrl,
//     maxAttempts = 30,
//     interval = 2000
//   ) => {
//     let attempts = 0;
//     let pollInterval = null;

//     return new Promise((resolve, reject) => {
//       const checkStatus = async () => {
//         try {
//           attempts++;
//           const response = await axios.get(`${apiUrl}?session_id=${sessionId}`);
//           const data = response.data;

//           if (data.status === "completed" && data.ok) {
//             if (pollInterval) clearInterval(pollInterval);
//             resolve(data);
//           } else if (data.status === "failed" || attempts >= maxAttempts) {
//             if (pollInterval) clearInterval(pollInterval);
//             reject(new Error(data.message || "Try-on processing failed"));
//           }
//         } catch (error) {
//           if (pollInterval) clearInterval(pollInterval);
//           reject(error);
//         }
//       };

//       pollInterval = setInterval(checkStatus, interval);
//       checkStatus();
//     });
//   };

//   const startTryon = async (person, selectedItem) => {
//     const form = new FormData();
//     const category = getCategoryFromStorage();
//     // const isJewelry = category === "jewellary" ? "jewelry" : "outfit";
//     let isJewelry;
//     if (category === "jewellary") {
//       isJewelry = "jewelry";
//     }
//     const apiUrl = isJewelry ? TRYON_JEWELRY_API : TRYON_CLOTHES_API;
//     console.log("Using API:", apiUrl);
//     form.append("model_photo", person);
//     form.append("item_id", selectedItem.id);
//     form.append("item_url", selectedItem.image_url);
//     form.append("clothing_type", "onepiece");

//     try {
//       setIsLoading(true);
//       setTryOnError(null);
//       const response = await axios.post(apiUrl, form, {
//         headers: {
//           "Content-Type": "multipart/form-data",
//         },
//       });

//       const responseData = response.data;

//       // If the response already has the result and is completed, return it directly
//       if (
//         responseData.ok &&
//         responseData.status === "completed" &&
//         responseData.result
//       ) {
//         setTryOnResult(responseData.result);
//         return responseData.result;
//       }

//       // Otherwise, poll for the result
//       const { session_id: sessionId } = responseData;
//       if (!sessionId) {
//         throw new Error("No session ID received from the server");
//       }

//       const result = await pollForResult(sessionId, apiUrl);

//       if (result.ok && result.result) {
//         setTryOnResult(result.result);
//         return result.result;
//       } else {
//         throw new Error(result.message || "Try-on failed");
//       }
//     } catch (error) {
//       console.error("Try-on error:", error);
//       setTryOnError(error.message || "Failed to process try-on");
//       throw error;
//     } finally {
//       setIsLoading(false);
//     }
//   };

//   const handleSelfieSelect = (e) => {
//     const file = e.target.files?.[0];
//     if (!file) return;

//     const reader = new FileReader();
//     reader.onload = (event) => {
//       setOriginalUrl(event.target.result);
//       originalImageRef.current = file;
//       setPreviewUrl(null);
//       setSelectedProduct(null);
//       setTryOnError(null);
//     };
//     reader.readAsDataURL(file);
//   };

//   const handleProductSelect = async (product) => {
//     if (!originalImageRef.current) {
//       Swal.fire({
//         icon: "info",
//         title: "Selfie required",
//         text: "Please upload your selfie first.",
//       }).then(() => {
//         selfieInputRef.current?.click();
//       });
//       return;
//     }

//     setErrorMsg("");
//     setIsApplying(true);
//     setSelectedProduct(product);
//     setAppliedOutfit(product);

//     try {
//       const result = await startTryon(originalImageRef.current, product);
//       setPreviewUrl(result);
//       setTryOnError(null);
//       setIsApplying(false);
//     } catch (error) {
//       console.error("Error trying on product:", error);
//       setTryOnError(
//         error.message || "Failed to apply the product. Please try again."
//       );
//       setErrorMsg(
//         error.message || "Failed to apply the product. Please try again."
//       );
//       setIsApplying(false);
//     }
//   };

//   const handleReset = () => {
//     setPreviewUrl(originalUrl);
//     setAppliedOutfit(null);
//     setSelectedProduct(null);
//     setTryOnError(null);
//   };
//   // const handleDelete = async () => {
//   //   const confirmed = await Swal.fire({
//   //     title: "Remove images?",
//   //     text: "This will reset the preview and clear the selected product.",
//   //     icon: "warning",
//   //     showCancelButton: true,
//   //     confirmButtonColor: "#ed1173",
//   //     cancelButtonColor: "#aaa",
//   //     confirmButtonText: "Yes, clear",
//   //   });

//   //   if (confirmed.isConfirmed) {
//   //     if (lastBlobUrlRef.current) {
//   //       try {
//   //         URL.revokeObjectURL(lastBlobUrlRef.current);
//   //       } catch {}
//   //       lastBlobUrlRef.current = null;
//   //     }
//   //     clearPoll();
//   //     setAppliedOutfit(null);
//   //     setSelectedProduct(null);
//   //     setPreviewUrl(originalUrl);
//   //     Swal.fire({
//   //       title: "Cleared",
//   //       text: "Preview reset.",
//   //       icon: "success",
//   //       confirmButtonColor: "#ed1173",
//   //     });
//   //   }
//   // };

//   const handleDelete = async () => {
//     try {
//       const confirmed = await Swal.fire({
//         title: "Remove images?",
//         text: "This will reset the preview and clear the selected product.",
//         icon: "warning",
//         showCancelButton: true,
//         confirmButtonColor: "#C31162",
//         cancelButtonColor: "#6c757d",
//         confirmButtonText: "Yes, remove it!",
//       });

//       if (confirmed.isConfirmed) {
//         // Clear all image-related states
//         setOriginalUrl(null);
//         setPreviewUrl(null);
//         setTryOnResult(null);
//         setTryOnError(null);
//         setSelectedProduct(null);
//         setAppliedOutfit(null);
//         setIsCompareMode(false);
//         setActiveBtn(buttons[0]);

//         // Clear any existing intervals
//         clearPoll();

//         // Clear the file input value to allow reselecting the same file
//         if (selfieInputRef.current) {
//           selfieInputRef.current.value = "";
//         }

//         // Clear any blob URLs to free memory
//         if (lastBlobUrlRef.current) {
//           URL.revokeObjectURL(lastBlobUrlRef.current);
//           lastBlobUrlRef.current = null;
//         }

//         // Show success message
//         Swal.fire("Deleted!", "The image has been removed.", "success");
//       }
//     } catch (error) {
//       console.error("Error in handleDelete:", error);
//       Swal.fire(
//         "Error",
//         "An error occurred while trying to remove the image.",
//         "error"
//       );
//     }
//   };
//   const handleShare = async () => {
//     if (!previewUrl) return;
//     if (navigator.share) {
//       try {
//         await navigator.share({
//           title: "My Outfit Try-on",
//           text: "Check out my try-on",
//           url: previewUrl,
//         });
//         setShowShareMenu(false);
//       } catch (err) {}
//     } else {
//       navigator.clipboard?.writeText(previewUrl);
//       Swal.fire({
//         text: "Link copied to clipboard!",
//         icon: "success",
//         timer: 1200,
//         confirmButtonColor: "#ed1173",
//       });
//     }
//   };
//   const handleDownload = async () => {
//     if (!previewUrl) return;
//     try {
//       const res = await fetch(previewUrl);
//       const blob = await res.blob();
//       const url = URL.createObjectURL(blob);
//       const a = document.createElement("a");
//       a.href = url;
//       a.download = "final_outfit.png";
//       document.body.appendChild(a);
//       a.click();
//       a.remove();
//       URL.revokeObjectURL(url);
//     } catch (err) {
//       console.error("Download failed", err);
//       Swal.fire({
//         icon: "error",
//         title: "Download Failed",
//         text: "Could not download the image.",
//       });
//     }
//   };
//   useEffect(() => {
//     if (originalUrl && !appliedOutfit) setPreviewUrl(originalUrl);
//   }, [originalUrl, appliedOutfit]);

//   return (
//     <div style={{ margin: "15px auto 0 auto", maxWidth: 380 }}>
//       <style>{`
//         .hwz-scrollbar {
//           scrollbar-color: #C31162 transparent;
//           scrollbar-width: auto;
//         }
//         .hwz-scrollbar::-webkit-scrollbar {
//           height: 10px;
//           width: 10px;
//         }
//         .hwz-scrollbar::-webkit-scrollbar-track {
//           background: transparent;
//         }
//         .hwz-scrollbar::-webkit-scrollbar-thumb {
//           background-color: #C31162;
//           border-radius: 8px;
//         }
//         @keyframes spin {
//           from { transform: rotate(0deg); }
//           to { transform: rotate(360deg); }
//         }
//       `}</style>
//       <div
//         style={{
//           display: "flex",
//           flexDirection: "column",
//           alignItems: "center",
//         }}
//       >
//         <div style={{ width: "100%" }}>
//           <div
//             style={{
//               display: "flex",
//               alignItems: "center",
//               justifyContent: "center",
//               position: "relative",
//             }}
//           >
//             <div
//               style={{
//                 position: "absolute",
//                 top: 16,
//                 left: 16,
//                 zIndex: 30,
//                 cursor: "pointer",
//                 padding: 8,
//               }}
//               title="Home"
//               onClick={() => navigate("/try", { replace: true })}
//             >
//               <FaHome
//                 size={30}
//                 style={{
//                   color: "#fff",
//                   backgroundColor: "#C31162",
//                   borderRadius: "100%",
//                   padding: "5px",
//                 }}
//               />
//             </div>
//             <div
//               style={{
//                 position: "absolute",
//                 top: 10,
//                 right: 0,
//                 zIndex: 30,
//                 padding: 8,
//                 display: "flex",
//                 alignItems: "center",
//                 gap: 8,
//                 width: activeBtn === "Complete Look" ? "55%" : "33%",
//               }}
//             >
//               {activeBtn === "Complete Look" && (
//                 <div>
//                   <Share
//                     size={30}
//                     style={{
//                       color: "#fff",
//                       backgroundColor: "#C31162",
//                       borderRadius: "100%",
//                       padding: "5px",
//                     }}
//                     title="Share Image"
//                     onClick={() => setShowShareMenu(true)}
//                   />
//                 </div>
//               )}

//               {showShareMenu && (
//                 <div
//                   onClick={() => setShowShareMenu(false)}
//                   style={{
//                     position: "fixed",
//                     top: 0,
//                     left: 0,
//                     width: "100vw",
//                     height: "100vh",
//                     backgroundColor: "rgba(0,0,0,0.5)",
//                     display: "flex",
//                     justifyContent: "center",
//                     alignItems: "center",
//                     zIndex: 9999,
//                   }}
//                 >
//                   <div
//                     onClick={(e) => e.stopPropagation()}
//                     style={{
//                       background: "#fff",
//                       padding: "24px 32px",
//                       borderRadius: 12,
//                       minWidth: 320,
//                     }}
//                   >
//                     <h4 style={{ marginBottom: 12 }}>Share your look</h4>
//                     <div style={{ display: "flex", gap: 16 }}>
//                       <button
//                         onClick={handleShare}
//                         style={{
//                           background: "#C31162",
//                           color: "#fff",
//                           border: "none",
//                           borderRadius: 8,
//                           padding: "10px 24px",
//                           cursor: "pointer",
//                         }}
//                       >
//                         Share
//                       </button>
//                       <button
//                         onClick={() => setShowShareMenu(false)}
//                         style={{
//                           background: "#eee",
//                           color: "#C31162",
//                           border: "none",
//                           borderRadius: 8,
//                           padding: "8px 18px",
//                           cursor: "pointer",
//                         }}
//                       >
//                         Close
//                       </button>
//                     </div>
//                   </div>
//                 </div>
//               )}

//               {activeBtn === "Complete Look" && (
//                 <div title="Download" onClick={handleDownload}>
//                   <Download
//                     size={30}
//                     style={{
//                       color: "#fff",
//                       backgroundColor: "#C31162",
//                       borderRadius: "100%",
//                       padding: "5px",
//                     }}
//                   />
//                 </div>
//               )}

//               <div onClick={handleReset}>
//                 <MdRestartAlt
//                   size={30}
//                   style={{
//                     color: "#fff",
//                     backgroundColor: "#C31162",
//                     borderRadius: "100%",
//                     padding: "5px",
//                   }}
//                 />
//               </div>

//               <div title="Delete" onClick={handleDelete}>
//                 <IoClose
//                   size={30}
//                   style={{
//                     color: "#fff",
//                     backgroundColor: "#C31162",
//                     borderRadius: "100%",
//                     padding: "5px",
//                   }}
//                 />
//               </div>
//             </div>

//             <div
//               className="compare-container"
//               style={{
//                 width: "100%",
//                 overflow: "hidden",
//                 // borderRadius: 12,
//                 // aspectRatio: "3 / 4",
//                 maxHeight: "90vh",
//                 minHeight: 400,
//               }}
//             >
//               {isCompareMode && originalUrl && previewUrl ? (
//                 <div
//                   style={{
//                     width: "100%",
//                     height: "100%",
//                     borderRadius: 12,
//                     overflow: "hidden",
//                   }}
//                 >
//                   <ReactCompareSlider
//                     itemOne={
//                       <ReactCompareSliderImage
//                         src={originalUrl}
//                         alt="Original"
//                         style={{
//                           height: "100%",
//                           width: "100%",
//                           objectFit: "contain",
//                         }}
//                       />
//                     }
//                     itemTwo={
//                       <ReactCompareSliderImage
//                         src={previewUrl}
//                         alt="Preview"
//                         style={{
//                           height: "100%",
//                           width: "100%",
//                           objectFit: "contain",
//                         }}
//                       />
//                     }
//                     style={{ width: "100%", height: "100%" }}
//                   />
//                 </div>
//               ) : (
//                 <div style={{ overflow: "hidden", borderRadius: 12 }}>
//                   {previewUrl ? (
//                     <img
//                       src={previewUrl}
//                       alt="preview"
//                       style={{
//                         width: "100%",
//                         height: "100%",
//                         objectFit: "contain",
//                         display: "block",
//                       }}
//                     />
//                   ) : originalUrl ? (
//                     <img
//                       src={originalUrl}
//                       alt="original"
//                       style={{
//                         width: "100%",
//                         height: "100%",
//                         objectFit: "contain",
//                         display: "block",
//                       }}
//                     />
//                   ) : (
//                     <div
//                       style={{
//                         width: "100%",
//                         height: 400,
//                         display: "flex",
//                         alignItems: "center",
//                         justifyContent: "center",
//                         background: "#f7f7f7",
//                         color: "#555",
//                       }}
//                     >
//                       <div style={{ textAlign: "center" }}>
//                         <p>No selfie found. Please upload a selfie.</p>
//                         <button
//                           onClick={() => selfieInputRef.current?.click()}
//                           style={{
//                             background: "#C31162",
//                             color: "#fff",
//                             border: "none",
//                             padding: "8px 14px",
//                             borderRadius: 8,
//                           }}
//                         >
//                           Upload Selfie
//                         </button>
//                       </div>
//                     </div>
//                   )}

//                   {isApplying && (
//                     <div
//                       className="processing-overlay"
//                       style={{
//                         position: "absolute",
//                         inset: 0,
//                         display: "flex",
//                         flexDirection: "column",
//                         alignItems: "center",
//                         justifyContent: "center",
//                         zIndex: 20,
//                       }}
//                     >
//                       {/* <Loader /> */}
//                       <div style={{ padding: 12 }}>Applying Outfit...</div>
//                     </div>
//                   )}
//                 </div>
//               )}
//             </div>
//           </div>
//         </div>

//         <input
//           ref={selfieInputRef}
//           type="file"
//           accept="image/*"
//           onChange={handleSelfieSelect}
//           style={{ display: "none" }}
//         />

//         <div style={{ width: "100%" }}>
//           {(() => {
//             switch (activeBtn) {
//               case "Shades":
//                 return (
//                   <div style={{ position: "relative", width: "100%" }}>
//                     <div
//                       style={{
//                         overflowX: "auto",
//                         whiteSpace: "nowrap",
//                         width: "100%",
//                         padding: "0 10px",
//                       }}
//                       className="hwz-scrollbar"
//                     >
//                       <div
//                         style={{ display: "inline-block", minWidth: "100%" }}
//                       >
//                         <div
//                           style={{
//                             display: "flex",
//                             gap: 8,
//                             padding: "8px 0",
//                             minWidth: "max-content",
//                           }}
//                         >
//                           {isLoading && (
//                             <div
//                               style={{
//                                 display: "flex",
//                                 alignItems: "center",
//                                 justifyContent: "center",
//                                 width: 100,
//                                 height: 100,
//                               }}
//                             >
//                               <Loader
//                                 size={24}
//                                 style={{ animation: "spin 1s linear infinite" }}
//                               />
//                             </div>
//                           )}
//                           {productList.length === 0 && !isLoading && (
//                             <div
//                               style={{
//                                 display: "flex",
//                                 alignItems: "center",
//                                 justifyContent: "center",
//                                 width: "100%",
//                                 padding: "20px",
//                                 color: "#666",
//                                 fontSize: 14,
//                               }}
//                             >
//                               No products available. Please check the category.
//                             </div>
//                           )}
//                           {productList.map((product, idx) => (
//                             <button
//                               key={product.id || idx}
//                               type="button"
//                               onClick={() => handleProductSelect(product)}
//                               disabled={isApplying || isLoading}
//                               style={{
//                                 cursor:
//                                   isApplying || isLoading
//                                     ? "not-allowed"
//                                     : "pointer",
//                                 width: 100,
//                                 height: 100,
//                                 flexShrink: 0,
//                                 background:
//                                   selectedProduct?.id === product.id
//                                     ? "#f0f0f0"
//                                     : "white",
//                                 border:
//                                   selectedProduct?.id === product.id
//                                     ? "2px solid #C31162"
//                                     : "none",
//                                 borderRadius: 5,
//                                 opacity: isApplying || isLoading ? 0.6 : 1,
//                               }}
//                             >
//                               <img
//                                 src={product.image_url}
//                                 alt={product.name || `Product_${idx + 1}`}
//                                 style={{
//                                   width: "100%",
//                                   height: 60,
//                                   objectFit: "cover",
//                                   borderRadius: 6,
//                                 }}
//                               />
//                               <p style={{ fontSize: 10, fontWeight: 500 }}>
//                                 {(product.name || `Product_${idx + 1}`).slice(
//                                   0,
//                                   10
//                                 )}
//                               </p>
//                             </button>
//                           ))}
//                         </div>
//                       </div>
//                     </div>
//                     {tryOnError && (
//                       <div
//                         style={{
//                           marginTop: 8,
//                           padding: 8,
//                           background: "#fee",
//                           color: "#c33",
//                           borderRadius: 4,
//                           fontSize: 12,
//                           textAlign: "center",
//                         }}
//                       >
//                         {tryOnError}
//                       </div>
//                     )}
//                   </div>
//                 );

//               case "Compare":
//                 return (
//                   <div
//                     style={{
//                       textAlign: "center",
//                       marginTop: 5,
//                       display: "flex",
//                       flexDirection: "column",
//                       alignItems: "center",
//                       justifyContent: "center",
//                     }}
//                   >
//                     <div
//                       style={{
//                         width: 55,
//                         height: 55,
//                         backgroundColor: "black",
//                         borderRadius: 4,
//                         display: "flex",
//                         alignItems: "center",
//                         justifyContent: "center",
//                       }}
//                     >
//                       <div
//                         style={{
//                           width: 2,
//                           height: "100%",
//                           backgroundColor: "white",
//                         }}
//                       />
//                     </div>
//                     <p
//                       style={{
//                         color: "black",
//                         fontWeight: 500,
//                         marginTop: 5,
//                         fontSize: 12,
//                       }}
//                     >
//                       Before/After
//                     </p>
//                   </div>
//                 );

//               case "Complete Look":
//                 return (
//                   <div
//                     style={{
//                       marginTop: 10,
//                       display: "flex",
//                       flexWrap: "wrap",
//                       gap: 12,
//                       justifyContent: "start",
//                       height: 100,
//                     }}
//                   >
//                     {appliedOutfit && (
//                       <div
//                         style={{
//                           height: 120,
//                           overflowX: "auto",
//                           whiteSpace: "nowrap",
//                           width: "100%",
//                         }}
//                       >
//                         <div style={{ display: "flex", gap: 8 }}>
//                           <div
//                             style={{
//                               padding: 8,
//                               background: "#fff",
//                               borderRadius: 8,
//                               display: "flex",
//                               flexDirection: "column",
//                               alignItems: "flex-start",
//                             }}
//                           >
//                             <img
//                               src={appliedOutfit.image_url}
//                               alt={appliedOutfit.name || "Applied Product"}
//                               style={{
//                                 width: 80,
//                                 height: 60,
//                                 objectFit: "cover",
//                                 borderRadius: 4,
//                               }}
//                             />
//                             <p
//                               style={{
//                                 color: "#000",
//                                 fontSize: 12,
//                                 textAlign: "center",
//                               }}
//                             >
//                               {appliedOutfit.name || "Product"}
//                             </p>
//                           </div>
//                         </div>
//                       </div>
//                     )}
//                   </div>
//                 );
//               default:
//                 return null;
//             }
//           })()}
//         </div>
//       </div>
//       <div className="w-100 py-2" style={{ background: "#ffb3d3ff" }}>
//         <div className="d-flex justify-content-evenly">
//           {buttons.map((button, index) => (
//             <button
//               key={index}
//               style={{
//                 height: "100%",
//                 background: activeBtn === button ? "#C31162" : "none",
//                 color: activeBtn === button ? "#fff" : "#C31162",
//                 padding: "4px clamp(0.6rem, 2vw, 2rem)",
//                 border: "none",
//                 borderRadius: "10px",
//                 fontWeight: "400",
//                 cursor: "pointer",
//                 transition: "all 0.3s ease",
//                 fontSize: "clamp(8px, 1.5vw, 12px)",
//               }}
//               onClick={() => {
//                 setActiveBtn(button);
//                 switch (button) {
//                   case "Complete Look":
//                     setIsCompareMode(false);
//                     break;
//                   case "Compare":
//                     setIsCompareMode((prev) => !prev);
//                     break;
//                   default:
//                     setIsCompareMode(false);
//                     break;
//                 }
//               }}
//             >
//               {button}
//             </button>
//           ))}
//         </div>
//       </div>

//       <style jsx>{`
//         .processing-overlay {
//           background: rgba(255, 255, 255, 0.9);
//         }
//       `}</style>
//     </div>
//   );
// }

import React, { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import Swal from "sweetalert2";
import { FaHome } from "react-icons/fa";
import { IoClose } from "react-icons/io5";
import { Download, Heart, Loader, Share } from "lucide-react";
import { MdRestartAlt } from "react-icons/md";
import {
  ReactCompareSlider,
  ReactCompareSliderImage,
} from "react-compare-slider";
import axios from "axios";

const buttons = ["Outfit", "Compare", "Complete Look"];
const BASE_API = "https://www.happywedz.com/ai";
const CATALOG_API = `${BASE_API}/api/catalog/items`;
const TRYON_CLOTHES_API = `${BASE_API}/api/tryon/clothes`;
const TRYON_JEWELRY_API = `${BASE_API}/api/tryon/jewelry`;

export default function FiltersPageOutfit() {
  const navigate = useNavigate();
  const [appliedOutfit, setAppliedOutfit] = useState(null);

  const selfieInputRef = useRef(null);
  const originalBlobUrlRef = useRef(null);

  const typeOfCategory = getCategoryFromStorage();
  const buttons = [
    typeOfCategory === "outfit" ? "Outfit" : "Jewellery",
    "Compare",
    "Complete Look",
  ];

  const [originalUrl, setOriginalUrl] = useState(null);
  const [previewUrl, setPreviewUrl] = useState(null);
  const [isCompareMode, setIsCompareMode] = useState(false);
  const [isApplying, setIsApplying] = useState(false);
  const [activeBtn, setActiveBtn] = useState(buttons[0]);
  const [showShareMenu, setShowShareMenu] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");
  const [productList, setProductList] = useState([]);
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [tryOnResult, setTryOnResult] = useState(null);
  const [tryOnError, setTryOnError] = useState(null);

  const pollRef = useRef(null);
  const lastBlobUrlRef = useRef(null);
  const originalImageRef = useRef(null);

  const clearPoll = () => {
    if (pollRef.current) {
      clearInterval(pollRef.current);
      pollRef.current = null;
    }
  };

  const revokeOriginalBlobUrl = () => {
    if (originalBlobUrlRef.current) {
      try {
        URL.revokeObjectURL(originalBlobUrlRef.current);
      } catch (err) {
        console.warn("Error revoking blob URL:", err);
      }
      originalBlobUrlRef.current = null;
    }
  };

  function getCategoryFromStorage() {
    try {
      const userInfoStr = localStorage.getItem("userInfo");
      if (userInfoStr) {
        const userInfo = JSON.parse(userInfoStr);
        return userInfo?.type || null;
      }
    } catch (error) {
      console.error("Error parsing userInfo from localStorage:", error);
    }
    return null;
  }

  const fetchProducts = async () => {
    try {
      let category = getCategoryFromStorage();
      console.log("Fetching products for category:", category);

      if (!category) {
        console.warn(
          "No category found in localStorage. Defaulting to 'outfit'"
        );
        category = "outfit";
      }

      const apiCategory = category === "jewellary" ? "jewelry" : category;
      console.log("Calling API with category:", apiCategory);

      const response = await axios.get(CATALOG_API, {
        params: { category: apiCategory },
      });

      console.log("API Response:", response.data);

      if (Array.isArray(response.data.items)) {
        setProductList(response?.data?.items);
        console.log(productList, "product list from jewellary");

        console.log("Products loaded:", response.data.items.length);
      } else {
        console.error("Invalid response format:", response.data);
        setProductList([]);
      }
    } catch (error) {
      console.error("Error fetching products:", error);
      if (error.response) {
        console.error(
          "Response error:",
          error.response.status,
          error.response.data
        );
      } else if (error.request) {
        console.error("Request error - no response received:", error.request);
      } else {
        console.error("Error setting up request:", error.message);
      }
      setProductList([]);
    }
  };

  useEffect(() => {
    fetchProducts();
    return () => {
      clearPoll();
      revokeOriginalBlobUrl(); // Revoke on unmount
      if (lastBlobUrlRef.current) {
        try {
          URL.revokeObjectURL(lastBlobUrlRef.current);
        } catch {}
        lastBlobUrlRef.current = null;
      }
    };
  }, []);

  const pollForResult = async (
    sessionId,
    apiUrl,
    maxAttempts = 30,
    interval = 2000
  ) => {
    let attempts = 0;
    let pollInterval = null;

    return new Promise((resolve, reject) => {
      const checkStatus = async () => {
        try {
          attempts++;
          const response = await axios.get(`${apiUrl}?session_id=${sessionId}`);
          const data = response.data;

          if (data.status === "completed" && data.ok) {
            if (pollInterval) clearInterval(pollInterval);
            resolve(data);
          } else if (data.status === "failed" || attempts >= maxAttempts) {
            if (pollInterval) clearInterval(pollInterval);
            reject(new Error(data.message || "Try-on processing failed"));
          }
        } catch (error) {
          if (pollInterval) clearInterval(pollInterval);
          reject(error);
        }
      };

      pollInterval = setInterval(checkStatus, interval);
      checkStatus();
    });
  };

  const startTryon = async (person, selectedItem) => {
    const form = new FormData();
    const category = getCategoryFromStorage();
    // const isJewelry = category === "jewellary" ? "jewelry" : "outfit";
    let isJewelry;
    if (category === "jewellary") {
      isJewelry = "jewelry";
    }
    const apiUrl = isJewelry ? TRYON_JEWELRY_API : TRYON_CLOTHES_API;
    console.log("Using API:", apiUrl);
    form.append("model_photo", person);
    form.append("item_id", selectedItem.id);
    form.append("item_url", selectedItem.image_url);
    form.append("clothing_type", "onepiece");

    try {
      setIsLoading(true);
      setTryOnError(null);
      const response = await axios.post(apiUrl, form, {
        headers: {
          "Content-Type": "multipart/form-data",
        },
      });

      const responseData = response.data;

      // If the response already has the result and is completed, return it directly
      if (
        responseData.ok &&
        responseData.status === "completed" &&
        responseData.result
      ) {
        setTryOnResult(responseData.result);
        return responseData.result;
      }

      // Otherwise, poll for the result
      const { session_id: sessionId } = responseData;
      if (!sessionId) {
        throw new Error("No session ID received from the server");
      }

      const result = await pollForResult(sessionId, apiUrl);

      if (result.ok && result.result) {
        setTryOnResult(result.result);
        return result.result;
      } else {
        throw new Error(result.message || "Try-on failed");
      }
    } catch (error) {
      console.error("Try-on error:", error);
      setTryOnError(error.message || "Failed to process try-on");
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const handleSelfieSelect = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Revoke previous blob URL to free memory
    revokeOriginalBlobUrl();

    // Create new blob URL instead of dataURL to avoid large strings in state
    const url = URL.createObjectURL(file);
    setOriginalUrl(url);
    originalImageRef.current = file;
    originalBlobUrlRef.current = url; // Track for revocation
    setPreviewUrl(null);
    setSelectedProduct(null);
    // Reset applied outfit for consistency on new upload
    setAppliedOutfit(null);
    setTryOnError(null);
  };

  const handleProductSelect = async (product) => {
    if (!originalImageRef.current) {
      Swal.fire({
        icon: "info",
        title: "Image required",
        text: "Please upload your image first.",
      }).then(() => {
        selfieInputRef.current?.click();
      });
      return;
    }

    setErrorMsg("");
    setIsApplying(true);
    setSelectedProduct(product);
    setAppliedOutfit(product);

    try {
      const result = await startTryon(originalImageRef.current, product);
      setPreviewUrl(result);
      setTryOnError(null);
      setIsApplying(false);
    } catch (error) {
      console.error("Error trying on product:", error);
      setTryOnError(
        error.message || "Failed to apply the product. Please try again."
      );
      setErrorMsg(
        error.message || "Failed to apply the product. Please try again."
      );
      setIsApplying(false);
    }
  };

  const handleReset = () => {
    setPreviewUrl(originalUrl);
    setAppliedOutfit(null);
    setSelectedProduct(null);
    setTryOnError(null);
  };
  // const handleDelete = async () => {
  //   const confirmed = await Swal.fire({
  //     title: "Remove images?",
  //     text: "This will reset the preview and clear the selected product.",
  //     icon: "warning",
  //     showCancelButton: true,
  //     confirmButtonColor: "#ed1173",
  //     cancelButtonColor: "#aaa",
  //     confirmButtonText: "Yes, clear",
  //   });

  //   if (confirmed.isConfirmed) {
  //     if (lastBlobUrlRef.current) {
  //       try {
  //         URL.revokeObjectURL(lastBlobUrlRef.current);
  //       } catch {}
  //       lastBlobUrlRef.current = null;
  //     }
  //     clearPoll();
  //     setAppliedOutfit(null);
  //     setSelectedProduct(null);
  //     setPreviewUrl(originalUrl);
  //     Swal.fire({
  //       title: "Cleared",
  //       text: "Preview reset.",
  //       icon: "success",
  //       confirmButtonColor: "#ed1173",
  //     });
  //   }
  // };

  const handleDelete = async () => {
    try {
      const confirmed = await Swal.fire({
        title: "Remove images?",
        text: "This will reset the preview and clear the selected product.",
        icon: "warning",
        showCancelButton: true,
        confirmButtonColor: "#C31162",
        cancelButtonColor: "#6c757d",
        confirmButtonText: "Yes, remove it!",
      });

      if (confirmed.isConfirmed) {
        // Revoke blob URL before clearing
        revokeOriginalBlobUrl();

        // Clear all image-related states
        setOriginalUrl(null);
        setPreviewUrl(null);
        setTryOnResult(null);
        setTryOnError(null);
        setSelectedProduct(null);
        setAppliedOutfit(null);
        setIsCompareMode(false);
        setActiveBtn(buttons[0]);

        // Clear any existing intervals
        clearPoll();

        // Clear the file input value to allow reselecting the same file
        if (selfieInputRef.current) {
          selfieInputRef.current.value = "";
        }

        // Clear any blob URLs to free memory
        if (lastBlobUrlRef.current) {
          URL.revokeObjectURL(lastBlobUrlRef.current);
          lastBlobUrlRef.current = null;
        }

        // Show success message
        Swal.fire("Deleted!", "The image has been removed.", "success");
      }
    } catch (error) {
      console.error("Error in handleDelete:", error);
      Swal.fire(
        "Error",
        "An error occurred while trying to remove the image.",
        "error"
      );
    }
  };
  const handleShare = async () => {
    if (!previewUrl) return;
    if (navigator.share) {
      try {
        await navigator.share({
          title: "My Outfit Try-on",
          text: "Check out my try-on",
          url: previewUrl,
        });
        setShowShareMenu(false);
      } catch (err) {}
    } else {
      navigator.clipboard?.writeText(previewUrl);
      Swal.fire({
        text: "Link copied to clipboard!",
        icon: "success",
        timer: 1200,
        confirmButtonColor: "#ed1173",
      });
    }
  };
  const handleDownload = async () => {
    if (!previewUrl) return;
    try {
      const res = await fetch(previewUrl);
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "final_outfit.png";
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error("Download failed", err);
      Swal.fire({
        icon: "error",
        title: "Download Failed",
        text: "Could not download the image.",
      });
    }
  };
  useEffect(() => {
    if (originalUrl && !appliedOutfit) setPreviewUrl(originalUrl);
  }, [originalUrl, appliedOutfit]);

  return (
    <div style={{ margin: "15px auto 0 auto", maxWidth: 380 }}>
      <style>{`
        .hwz-scrollbar {
          scrollbar-color: #C31162 transparent;
          scrollbar-width: auto;
        }
        .hwz-scrollbar::-webkit-scrollbar {
          height: 10px;
          width: 10px;
        }
        .hwz-scrollbar::-webkit-scrollbar-track {
          background: transparent;
        }
        .hwz-scrollbar::-webkit-scrollbar-thumb {
          background-color: #C31162;
          border-radius: 8px;
        }
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
      `}</style>
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
        }}
      >
        <div style={{ width: "100%" }}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              position: "relative",
            }}
          >
            <div
              style={{
                position: "absolute",
                top: 16,
                left: 16,
                zIndex: 30,
                cursor: "pointer",
                padding: 8,
              }}
              title="Home"
              onClick={() => navigate("/try", { replace: true })}
            >
              <FaHome
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
              style={{
                position: "absolute",
                top: 10,
                right: 0,
                zIndex: 30,
                padding: 8,
                display: "flex",
                alignItems: "center",
                gap: 8,
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

              {showShareMenu && (
                <div
                  onClick={() => setShowShareMenu(false)}
                  style={{
                    position: "fixed",
                    top: 0,
                    left: 0,
                    width: "100vw",
                    height: "100vh",
                    backgroundColor: "rgba(0,0,0,0.5)",
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
                      borderRadius: 12,
                      minWidth: 320,
                    }}
                  >
                    <h4 style={{ marginBottom: 12 }}>Share your look</h4>
                    <div style={{ display: "flex", gap: 16 }}>
                      <button
                        onClick={handleShare}
                        style={{
                          background: "#C31162",
                          color: "#fff",
                          border: "none",
                          borderRadius: 8,
                          padding: "10px 24px",
                          cursor: "pointer",
                        }}
                      >
                        Share
                      </button>
                      <button
                        onClick={() => setShowShareMenu(false)}
                        style={{
                          background: "#eee",
                          color: "#C31162",
                          border: "none",
                          borderRadius: 8,
                          padding: "8px 18px",
                          cursor: "pointer",
                        }}
                      >
                        Close
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {activeBtn === "Complete Look" && (
                <div title="Download" onClick={handleDownload}>
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

              <div onClick={handleReset}>
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

              <div title="Delete" onClick={handleDelete}>
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
                // borderRadius: 12,
                // aspectRatio: "3 / 4",
                maxHeight: "90vh",
                minHeight: 400,
              }}
            >
              {isCompareMode && originalUrl && previewUrl ? (
                <div
                  style={{
                    width: "100%",
                    height: "100%",
                    borderRadius: 12,
                    overflow: "hidden",
                  }}
                >
                  <ReactCompareSlider
                    itemOne={
                      <ReactCompareSliderImage
                        src={originalUrl}
                        alt="Original"
                        style={{
                          height: "100%",
                          width: "100%",
                          objectFit: "contain",
                        }}
                      />
                    }
                    itemTwo={
                      <ReactCompareSliderImage
                        src={previewUrl}
                        alt="Preview"
                        style={{
                          height: "100%",
                          width: "100%",
                          objectFit: "contain",
                        }}
                      />
                    }
                    style={{ width: "100%", height: "100%" }}
                  />
                </div>
              ) : (
                <div style={{ overflow: "hidden", borderRadius: 12 }}>
                  {previewUrl ? (
                    <img
                      src={previewUrl}
                      alt="preview"
                      style={{
                        width: "100%",
                        height: "100%",
                        objectFit: "contain",
                        display: "block",
                      }}
                    />
                  ) : originalUrl ? (
                    <img
                      src={originalUrl}
                      alt="original"
                      style={{
                        width: "100%",
                        height: "100%",
                        objectFit: "contain",
                        display: "block",
                      }}
                    />
                  ) : (
                    <div
                      style={{
                        width: "100%",
                        height: 400,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        background: "#f7f7f7",
                        color: "#555",
                      }}
                    >
                      <div style={{ textAlign: "center" }}>
                        <p>No Image found. Please upload a Image.</p>
                        <button
                          onClick={() => selfieInputRef.current?.click()}
                          style={{
                            background: "#C31162",
                            color: "#fff",
                            border: "none",
                            padding: "8px 14px",
                            borderRadius: 8,
                          }}
                        >
                          Upload Image
                        </button>
                      </div>
                    </div>
                  )}

                  {isApplying && (
                    <div
                      className="processing-overlay"
                      style={{
                        position: "absolute",
                        inset: 0,
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "center",
                        justifyContent: "center",
                        zIndex: 20,
                      }}
                    >
                      {/* <Loader /> */}
                      {/* <div style={{ padding: 12 }}>Applying Outfit...</div> */}
                      <div style={{ padding: 12 }}>
  <div className="spinner"></div>
</div>

<style>
{`
.spinner {
  width: 22px;
  height: 22px;
  border: 3px solid #ccc;
  border-top-color: #000;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
`}
</style>

                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>

        <input
          ref={selfieInputRef}
          type="file"
          accept="image/*"
          onChange={handleSelfieSelect}
          style={{ display: "none" }}
        />

        <div style={{ width: "100%" }}>
          {(() => {
            switch (activeBtn) {
              case "Outfit":
              case "Jewellery":
                return (
                  <div style={{ position: "relative", width: "100%" }}>
                    <div
                      style={{
                        overflowX: "auto",
                        whiteSpace: "nowrap",
                        width: "100%",
                        padding: "0 10px",
                      }}
                      className="hwz-scrollbar"
                    >
                      <div
                        style={{ display: "inline-block", minWidth: "100%" }}
                      >
                        <div
                          style={{
                            display: "flex",
                            gap: 8,
                            padding: "8px 0",
                            minWidth: "max-content",
                          }}
                        >
                          {isLoading && (
                            <div
                              style={{
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                width: 100,
                                height: 100,
                              }}
                            >
                              <Loader
                                size={24}
                                style={{ animation: "spin 1s linear infinite" }}
                              />
                            </div>
                          )}
                          {productList.length === 0 && !isLoading && (
                            <div
                              style={{
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                width: "100%",
                                padding: "20px",
                                color: "#666",
                                fontSize: 14,
                              }}
                            >
                              No products available. Please check the category.
                            </div>
                          )}
                          {productList.map((product, idx) => (
                            <button
                              key={product.id || idx}
                              type="button"
                              onClick={() => handleProductSelect(product)}
                              disabled={isApplying || isLoading}
                              style={{
                                cursor:
                                  isApplying || isLoading
                                    ? "not-allowed"
                                    : "pointer",
                                width: 100,
                                height: 100,
                                flexShrink: 0,
                                background:
                                  selectedProduct?.id === product.id
                                    ? "#f0f0f0"
                                    : "white",
                                border:
                                  selectedProduct?.id === product.id
                                    ? "2px solid #C31162"
                                    : "none",
                                borderRadius: 5,
                                opacity: isApplying || isLoading ? 0.6 : 1,
                              }}
                            >
                              <img
                                src={product.image_url}
                                alt={product.name || `Product_${idx + 1}`}
                                style={{
                                  width: "100%",
                                  height: 60,
                                  objectFit: "cover",
                                  borderRadius: 6,
                                }}
                              />
                              <p style={{ fontSize: 10, fontWeight: 500 }}>
                                {(product.name || `Product_${idx + 1}`).slice(
                                  0,
                                  10
                                )}
                              </p>
                            </button>
                          ))}
                        </div>
                      </div>
                    </div>
                    {tryOnError && (
                      <div
                        style={{
                          marginTop: 8,
                          padding: 8,
                          background: "#fee",
                          color: "#c33",
                          borderRadius: 4,
                          fontSize: 12,
                          textAlign: "center",
                        }}
                      >
                        {tryOnError}
                      </div>
                    )}
                  </div>
                );

              case "Compare":
                return (
                  <div
                    style={{
                      textAlign: "center",
                      marginTop: 5,
                      display: "flex",
                      flexDirection: "column",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                  >
                    <div
                      style={{
                        width: 55,
                        height: 55,
                        backgroundColor: "black",
                        borderRadius: 4,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                      }}
                    >
                      <div
                        style={{
                          width: 2,
                          height: "100%",
                          backgroundColor: "white",
                        }}
                      />
                    </div>
                    <p
                      style={{
                        color: "black",
                        fontWeight: 500,
                        marginTop: 5,
                        fontSize: 12,
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
                      marginTop: 10,
                      display: "flex",
                      flexWrap: "wrap",
                      gap: 12,
                      justifyContent: "start",
                      height: 100,
                    }}
                  >
                    {appliedOutfit && (
                      <div
                        style={{
                          height: 120,
                          overflowX: "auto",
                          whiteSpace: "nowrap",
                          width: "100%",
                        }}
                      >
                        <div style={{ display: "flex", gap: 8 }}>
                          <div
                            style={{
                              padding: 8,
                              background: "#fff",
                              borderRadius: 8,
                              display: "flex",
                              flexDirection: "column",
                              alignItems: "flex-start",
                            }}
                          >
                            <img
                              src={appliedOutfit.image_url}
                              alt={appliedOutfit.name || "Applied Product"}
                              style={{
                                width: 80,
                                height: 60,
                                objectFit: "cover",
                                borderRadius: 4,
                              }}
                            />
                            <p
                              style={{
                                color: "#000",
                                fontSize: 12,
                                textAlign: "center",
                              }}
                            >
                              {appliedOutfit.name || "Product"}
                            </p>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                );
              default:
                return null;
            }
          })()}
        </div>
      </div>
      <div className="w-100 py-2" style={{ background: "#ffb3d3ff" }}>
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
                    setIsCompareMode(false);
                    break;
                  case "Compare":
                    setIsCompareMode((prev) => !prev);
                    break;
                  default:
                    setIsCompareMode(false);
                    break;
                }
              }}
            >
              {button}
            </button>
          ))}
        </div>
      </div>

      <style>{`
        .processing-overlay {
          background: rgba(255, 255, 255, 0.9);
        }
      `}</style>
    </div>
  );
}
