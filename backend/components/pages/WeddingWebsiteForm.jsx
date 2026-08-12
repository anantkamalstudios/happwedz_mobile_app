import React, { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams, useSearchParams } from "react-router-dom";
import {
  FiImage,
  FiUpload,
  FiX,
  FiCalendar,
  FiHeart,
  FiUsers,
  FiMapPin,
  FiPlus,
  FiCamera,
} from "react-icons/fi";
import { useSelector } from "react-redux";
import { weddingWebsiteApi } from "../../services/api/weddingWebsiteApi";
import Swal from "sweetalert2";
import NoIndex from "../common/NoIndex";


const WeddingWebsiteForm = () => {
  const navigate = useNavigate();
  const { templateId } = useParams();
  const [searchParams] = useSearchParams();
  const editId = useMemo(() => searchParams.get("edit"), [searchParams]);

  const [formData, setFormData] = useState({
    sliderImages: [],
    weddingDate: "",
    bride: {
      image: null,
      name: "",
      description: "",
    },
    groom: {
      image: null,
      name: "",
      description: "",
    },
    loveStory: [],
    weddingParty: [],
    whenWhere: [],
    gallery: [],
  });

  const [loading, setLoading] = useState(false);
  const [initializing, setInitializing] = useState(true);
  const [existingId, setExistingId] = useState(editId || null);

  // File upload handlers
  const handleFileUpload = (e, section, index = null) => {
    const files = Array.from(e.target.files);

    files.forEach((file) => {
      if (file.type.startsWith("image/")) {
        const preview = URL.createObjectURL(file);

        if (index !== null) {
          setFormData((prev) => ({
            ...prev,
            [section]: prev[section].map((item, i) =>
              i === index ? { ...item, image: file, preview } : item
            ),
          }));
        } else {
          const newItem = {
            id: Date.now() + Math.random(),
            image: file,
            preview,
            ...(section === "loveStory" && {
              title: "",
              date: "",
              description: "",
            }),
            ...(section === "weddingParty" && { name: "", relation: "" }),
            ...(section === "whenWhere" && {
              title: "",
              location: "",
              description: "",
              date: "",
            }),
          };

          setFormData((prev) => ({
            ...prev,
            [section]: [...prev[section], newItem],
          }));
        }
      }
    });
  };

  const handleSliderImageUpload = (e) => {
    const files = Array.from(e.target.files);
    const newImages = files
      .filter((file) => file.type.startsWith("image/"))
      .map((file) => ({
        id: Date.now() + Math.random(),
        file,
        preview: URL.createObjectURL(file),
      }));

    setFormData((prev) => ({
      ...prev,
      sliderImages: [...prev.sliderImages, ...newImages],
    }));
  };

  const handleGalleryUpload = (e) => {
    const files = Array.from(e.target.files);
    const newImages = files
      .filter((file) => file.type.startsWith("image/"))
      .map((file) => ({
        id: Date.now() + Math.random(),
        file,
        preview: URL.createObjectURL(file),
      }));

    setFormData((prev) => ({
      ...prev,
      gallery: [...prev.gallery, ...newImages],
    }));
  };

  const removeImage = (section, id) => {
    setFormData((prev) => ({
      ...prev,
      [section]: prev[section].filter((item) => item.id !== id),
    }));
  };

  const updateField = (section, index, field, value) => {
    setFormData((prev) => ({
      ...prev,
      [section]: prev[section].map((item, i) =>
        i === index ? { ...item, [field]: value } : item
      ),
    }));
  };

  const addLoveStory = () => {
    setFormData((prev) => ({
      ...prev,
      loveStory: [
        ...prev.loveStory,
        {
          id: Date.now(),
          image: null,
          preview: null,
          title: "",
          date: "",
          description: "",
        },
      ],
    }));
  };

  const addWeddingParty = () => {
    setFormData((prev) => ({
      ...prev,
      weddingParty: [
        ...prev.weddingParty,
        {
          id: Date.now(),
          image: null,
          preview: null,
          name: "",
          relation: "",
        },
      ],
    }));
  };

  const addWhenWhere = () => {
    setFormData((prev) => ({
      ...prev,
      whenWhere: [
        ...prev.whenWhere,
        {
          id: Date.now(),
          image: null,
          preview: null,
          title: "",
          location: "",
          description: "",
          date: "",
        },
      ],
    }));
  };

  // Normalize API data into current form state shape
  const mapExistingToFormState = (data) => {
    const toPreviewItem = (src) => ({
      id: Date.now() + Math.random(),
      file: null,
      preview: src,
    });

    return {
      weddingDate: data.weddingDate
        ? String(data.weddingDate).slice(0, 10)
        : "",
      bride: {
        image: null,
        preview:
          data.brideImageUrl ||
          data?.bride?.imageUrl ||
          data?.bride?.image_url ||
          data?.brideData?.image ||
          null,
        name:
          data.brideName ||
          data?.bride?.name ||
          data?.brideData?.name ||
          data?.brideData?.title ||
          "",
        description:
          data?.brideDescription ||
          data?.bride?.description ||
          data?.brideData?.description ||
          "",
      },
      groom: {
        image: null,
        preview:
          data.groomImageUrl ||
          data?.groom?.imageUrl ||
          data?.groom?.image_url ||
          data?.groomData?.image ||
          null,
        name:
          data.groomName ||
          data?.groom?.name ||
          data?.groomData?.name ||
          data?.groomData?.title ||
          "",
        description:
          data?.groomDescription ||
          data?.groom?.description ||
          data?.groomData?.description ||
          "",
      },
      sliderImages: Array.isArray(data.slider)
        ? data.slider
            .map((u) => toPreviewItem(typeof u === "string" ? u : u?.url || ""))
            .filter((x) => x.preview)
        : Array.isArray(data.sliderImages)
        ? data.sliderImages
            .map((u) => toPreviewItem(typeof u === "string" ? u : u?.url || ""))
            .filter((x) => x.preview)
        : [],
      loveStory: Array.isArray(data.loveStory)
        ? data.loveStory.map((s) => ({
            id: Date.now() + Math.random(),
            image: null,
            preview: s.imageUrl || s.image_url || s.image || null,
            title: s.title || "",
            date: s.date || "",
            description: s.description || "",
          }))
        : [],
      weddingParty: Array.isArray(data.weddingParty)
        ? data.weddingParty.map((m) => ({
            id: Date.now() + Math.random(),
            image: null,
            preview: m.imageUrl || m.image_url || m.image || null,
            name: m.name || m.title || "",
            relation: m.relation || m.role || "",
          }))
        : [],
      whenWhere: Array.isArray(data.whenWhere)
        ? data.whenWhere.map((w) => {
            const datePart =
              (w.date && String(w.date).slice(0, 10)) ||
              (w.datetime && String(w.datetime).slice(0, 10)) ||
              "";
            const timePart =
              (w.time && String(w.time).slice(0, 5)) ||
              (w.datetime && String(w.datetime).includes("T")
                ? String(w.datetime).split("T")[1]?.slice(0, 5)
                : "") ||
              "";
            const datetimeLocal =
              datePart && timePart ? `${datePart}T${timePart}` : datePart;
            return {
              id: Date.now() + Math.random(),
              image: null,
              preview: w.imageUrl || w.image_url || w.image || null,
              title: w.title || "",
              location: w.location || "",
              description: w.description || "",
              date: datetimeLocal,
            };
          })
        : [],
      gallery: Array.isArray(data.gallery)
        ? data.gallery
            .map((u) => toPreviewItem(typeof u === "string" ? u : u?.url || ""))
            .filter((x) => x.preview)
        : Array.isArray(data.galleryImages)
        ? data.galleryImages
            .map((u) => toPreviewItem(typeof u === "string" ? u : u?.url || ""))
            .filter((x) => x.preview)
        : [],
    };
  };

  const { user, token: userToken } = useSelector((state) => state.auth);

  // ✅ Corrected version – matches backend multer field names exactly
  const buildFormData = (data) => {
    const formData = new FormData();

    // Basic info
    formData.append("userId", data.userId);
    formData.append("templateId", data.templateId);
    formData.append("weddingDate", data.weddingDate);

    // JSON data
    formData.append("brideData", JSON.stringify(data.brideData || {}));
    formData.append("groomData", JSON.stringify(data.groomData || {}));
    formData.append("loveStory", JSON.stringify(data.loveStory || []));
    formData.append("weddingParty", JSON.stringify(data.weddingParty || []));
    formData.append("whenWhere", JSON.stringify(data.whenWhere || []));
    formData.append("galleryImages", JSON.stringify(data.galleryImages || []));
    // Preserve existing slider URLs as array items (repeat field)
    (data.sliderImages || []).forEach((url) => {
      if (url) formData.append("sliderImages", url);
    });

    // ✅ File uploads (field names must match backend)
    // New slider files
    (data.sliderFiles || []).forEach((file) => {
      if (file) formData.append("slider", file); // backend: slider
    });

    if (data.brideImage) formData.append("bride", data.brideImage); // backend: bride
    if (data.groomImage) formData.append("groom", data.groomImage); // backend: groom

    (data.loveStoryImages || []).forEach((file) => {
      if (file) formData.append("loveStory", file); // backend: loveStory
    });

    (data.weddingPartyImages || []).forEach((file) => {
      if (file) formData.append("weddingParty", file); // backend: weddingParty
    });

    // Include whenWhere images if backend supports it
    (data.whenWhereImages || []).forEach((file) => {
      if (file) formData.append("whenWhere", file); // backend: whenWhere
    });

    (data.galleryFiles || []).forEach((file) => {
      if (file) formData.append("gallery", file); // backend: gallery
    });

    return formData;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Prepare JSON parts, including existing image URLs if no new file
      const bridePreview =
        typeof formData.bride.preview === "string"
          ? formData.bride.preview
          : "";
      const groomPreview =
        typeof formData.groom.preview === "string"
          ? formData.groom.preview
          : "";

      const brideDataJson = {
        name: formData.bride.name,
        title: formData.bride.name, // support backend expecting `title`
        description: formData.bride.description,
        ...(formData.bride.image
          ? {}
          : bridePreview
          ? { image: bridePreview, image_url: bridePreview }
          : {}),
      };

      const groomDataJson = {
        name: formData.groom.name,
        title: formData.groom.name, // support backend expecting `title`
        description: formData.groom.description,
        ...(formData.groom.image
          ? {}
          : groomPreview
          ? { image: groomPreview, image_url: groomPreview }
          : {}),
      };

      // Build arrays so items with new files come first to align index-based backends
      const reorderWithFilesFirst = (items, makeJson, getFile) => {
        const enriched = items.map((it) => ({
          json: makeJson(it),
          file: getFile(it),
        }));
        const withFile = enriched.filter((e) => !!e.file);
        const withoutFile = enriched.filter((e) => !e.file);
        return {
          json: [
            ...withFile.map((e) => e.json),
            ...withoutFile.map((e) => e.json),
          ],
          files: withFile.map((e) => e.file),
        };
      };

      const loveStoryBuilt = reorderWithFilesFirst(
        formData.loveStory,
        (s) => {
          const hasDate = s.date || "";
          return {
            title: s.title,
            description: s.description,
            date: hasDate,
            ...(s.image
              ? {}
              : typeof s.preview === "string" && s.preview
              ? { image_url: s.preview }
              : {}),
          };
        },
        (s) => s.image
      );

      const weddingPartyBuilt = reorderWithFilesFirst(
        formData.weddingParty,
        (m) => ({
          name: m.name || m.title || "",
          title: m.name || m.title || "",
          relation: m.relation || m.role || "",
          role: m.relation || m.role || "",
          ...(m.image
            ? {}
            : typeof m.preview === "string" && m.preview
            ? { image_url: m.preview }
            : {}),
        }),
        (m) => m.image
      );

      const whenWhereBuilt = reorderWithFilesFirst(
        formData.whenWhere,
        (w) => {
          let dateOnly = w.date || "";
          let timeOnly = "";
          if (dateOnly && dateOnly.includes("T")) {
            const [d, t] = dateOnly.split("T");
            dateOnly = d;
            timeOnly = t?.slice(0, 5) || "";
          }
          return {
            title: w.title,
            location: w.location,
            description: w.description,
            date: dateOnly,
            time: w.time || timeOnly || "",
            ...(w.image
              ? {}
              : typeof w.preview === "string" && w.preview
              ? { image_url: w.preview }
              : {}),
          };
        },
        (w) => w.image
      );

      // Build FormData from form inputs
      const formPayload = buildFormData({
        userId: user?.id,
        templateId: templateId || "royal",
        weddingDate: formData.weddingDate,
        brideData: brideDataJson,
        groomData: groomDataJson,
        loveStory: loveStoryBuilt.json,
        weddingParty: weddingPartyBuilt.json,
        whenWhere: whenWhereBuilt.json,
        // Preserve existing slider URLs and append only new files
        sliderImages: formData.sliderImages
          //  .filter((i) => typeof i.preview === "string" && i.preview)
          .filter((i) => !i.file && i.preview)
          .map((i) => i.preview),
        sliderFiles: formData.sliderImages.map((i) => i.file).filter(Boolean),
        brideImage: formData.bride.image,
        groomImage: formData.groom.image,
        loveStoryImages: loveStoryBuilt.files,
        weddingPartyImages: weddingPartyBuilt.files,
        whenWhereImages: whenWhereBuilt.files,
                galleryImages: formData.gallery.filter((g) => !g.file && g.preview).map((g) => g.preview),
        galleryFiles: formData.gallery.map((g) => g.file).filter(Boolean),
      });

      let result;
      if (existingId) {
        result = await weddingWebsiteApi.updateWebsite(
          existingId,
          formPayload,
          userToken
        );
        // alert("Wedding website updated successfully!");
        Swal.fire({
          icon: "success",
          text: "Wedding website updated successfully!",
          confirmButtonText: "OK",
          timer: "3000",
        });
      } else {
        result = await weddingWebsiteApi.createWebsite(formPayload, userToken);
        // alert("Wedding website created successfully!");
        Swal.fire({
          icon: "success",
          text: "Wedding website created successfully!",
          confirmButtonText: "OK",
          timer: "3000",
        });
      }

      if (result?.id) {
        navigate(`/wedding-website/${result.id}`);
      } else if (existingId) {
        navigate(`/wedding-website/${existingId}`);
      } else {
        navigate("/my-wedding-websites");
      }
    } catch (err) {
      console.error("Error saving wedding website:", err);
      //   alert(`Failed to save wedding website: ${err.message}`);
      Swal.fire({
        icon: "error",
        text: `Failed to save wedding website: ${err.message}`,
        confirmButtonText: "OK",
        timer: "3000",
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let isMounted = true;
    (async () => {
      try {
        // Priority 1: explicit editId in URL
        if (editId) {
          const data = await weddingWebsiteApi.getWebsiteById(
            editId,
            userToken
          );
          if (!isMounted) return;
          setExistingId(editId);
          setFormData((prev) => ({
            ...prev,
            ...mapExistingToFormState(data),
          }));
          return;
        }

        // Priority 2: auto-detect existing website by template for this user
        if (userToken) {
          const list = await weddingWebsiteApi.getMyWebsites(userToken);
          if (!isMounted) return;
          const match = Array.isArray(list)
            ? list.find(
                (w) =>
                  String(w.templateId).toLowerCase() ===
                  String(templateId || "").toLowerCase()
              )
            : null;

          if (match?.id) {
            const data = await weddingWebsiteApi.getWebsiteById(
              match.id,
              userToken
            );
            if (!isMounted) return;
            setExistingId(match.id);
            setFormData((prev) => ({
              ...prev,
              ...mapExistingToFormState(data),
            }));
          }
        }
      } catch (e) {
        console.error("Error initializing website form:", e);
        Swal.fire({
          icon: "error",
          text: "Failed to load existing website data",
          confirmButtonText: "OK",
          timer: "3000",
        });
      } finally {
        if (isMounted) setInitializing(false);
      }
    })();
    return () => {
      isMounted = false;
    };
  }, [editId, templateId, userToken]);

  if (initializing) {
    return (
      <div className="d-flex justify-content-center align-items-center min-vh-100">
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  return (
    <div
      style={{
        minHeight: "100vh",
        background:
          "linear-gradient(135deg, #ffeef8 0%, #fff5f0 50%, #f0f9ff 100%)",
        position: "relative",
      }}
    >
      <NoIndex />
      <div
        style={{
          position: "absolute",
          top: "-100px",
          right: "-100px",
          width: "300px",
          height: "300px",
          borderRadius: "50%",
          background:
            "linear-gradient(135deg, rgba(255,107,157,0.1) 0%, rgba(233,30,99,0.1) 100%)",
          filter: "blur(60px)",
          zIndex: 0,
        }}
      ></div>
      <div
        style={{
          position: "absolute",
          bottom: "-150px",
          left: "-150px",
          width: "400px",
          height: "400px",
          borderRadius: "50%",
          background:
            "linear-gradient(135deg, rgba(156,39,176,0.1) 0%, rgba(233,30,99,0.1) 100%)",
          filter: "blur(80px)",
          zIndex: 0,
        }}
      ></div>

      <div
        className="container py-5"
        style={{ position: "relative", zIndex: 1 }}
      >
        <div className="row justify-content-center">
          <div className="col-lg-10">
            {/* Header Section */}
            <div
              style={{
                background: "white",
                borderRadius: "30px",
                padding: "60px 40px",
                marginBottom: "30px",
                boxShadow: "0 20px 60px rgba(0,0,0,0.08)",
                textAlign: "center",
                position: "relative",
                overflow: "hidden",
              }}
            >
              <div
                style={{
                  position: "absolute",
                  top: 0,
                  left: 0,
                  right: 0,
                  height: "6px",
                  background:
                    "linear-gradient(90deg, #ff6b9d 0%, #c2185b 50%, #9c27b0 100%)",
                }}
              ></div>
              <div
                style={{
                  display: "inline-block",
                  padding: "15px 30px",
                  background:
                    "linear-gradient(135deg, #ff6b9d15 0%, #c2185b15 100%)",
                  borderRadius: "50px",
                  marginBottom: "20px",
                }}
              >
                <FiHeart style={{ fontSize: "32px", color: "#ff6b9d" }} />
              </div>
              <h1
                style={{
                  fontSize: "42px",
                  fontWeight: "700",
                  background:
                    "linear-gradient(135deg, #ff6b9d 0%, #c2185b 50%, #9c27b0 100%)",
                  WebkitBackgroundClip: "text",
                  WebkitTextFillColor: "transparent",
                  marginBottom: "15px",
                }}
              >
                Create Your Dream Wedding Website
              </h1>
              <p
                style={{
                  fontSize: "18px",
                  color: "#666",
                  maxWidth: "600px",
                  margin: "0 auto",
                  lineHeight: "1.6",
                }}
              >
                Share your beautiful love story with family and friends. Fill in
                the details below to craft a personalized wedding website that
                captures your special journey.
              </p>
            </div>

            <form onSubmit={handleSubmit}>
              {/* Slider Images Section */}
              <div
                style={{
                  background: "white",
                  borderRadius: "30px",
                  padding: "40px",
                  marginBottom: "30px",
                  boxShadow: "0 10px 40px rgba(0,0,0,0.06)",
                  border: "1px solid rgba(255,107,157,0.1)",
                }}
              >
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    marginBottom: "30px",
                    gap: "15px",
                  }}
                >
                  <div
                    style={{
                      width: "50px",
                      height: "50px",
                      borderRadius: "15px",
                      background:
                        "linear-gradient(135deg, #ff6b9d20 0%, #c2185b20 100%)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                  >
                    <FiImage style={{ fontSize: "24px", color: "#ff6b9d" }} />
                  </div>
                  <div>
                    <h3
                      style={{
                        margin: 0,
                        fontSize: "26px",
                        fontWeight: "600",
                        color: "#2d2d2d",
                      }}
                    >
                      Hero Slider Images
                    </h3>
                    <p style={{ margin: 0, fontSize: "14px", color: "#999" }}>
                      Add beautiful images that will appear on your homepage
                    </p>
                  </div>
                </div>

                <div
                  onClick={() =>
                    document.getElementById("slider-upload").click()
                  }
                  style={{
                    border: "3px dashed #e0e0e0",
                    borderRadius: "20px",
                    padding: "50px 30px",
                    textAlign: "center",
                    cursor: "pointer",
                    transition: "all 0.3s ease",
                    background:
                      formData.sliderImages.length > 0
                        ? "#fafafa"
                        : "linear-gradient(135deg, #fff5f8 0%, #f8f5ff 100%)",
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.borderColor = "#ff6b9d";
                    e.currentTarget.style.background =
                      "linear-gradient(135deg, #fff0f5 0%, #f5f0ff 100%)";
                    e.currentTarget.style.transform = "translateY(-2px)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.borderColor = "#e0e0e0";
                    e.currentTarget.style.background =
                      formData.sliderImages.length > 0
                        ? "#fafafa"
                        : "linear-gradient(135deg, #fff5f8 0%, #f8f5ff 100%)";
                    e.currentTarget.style.transform = "translateY(0)";
                  }}
                >
                  <div
                    style={{
                      width: "80px",
                      height: "80px",
                      margin: "0 auto 20px",
                      borderRadius: "20px",
                      background:
                        "linear-gradient(135deg, #ff6b9d15 0%, #c2185b15 100%)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                  >
                    <FiUpload style={{ fontSize: "36px", color: "#ff6b9d" }} />
                  </div>
                  <h5
                    style={{
                      fontSize: "20px",
                      fontWeight: "600",
                      color: "#333",
                      marginBottom: "10px",
                    }}
                  >
                    Click to Upload Images
                  </h5>
                  <p
                    style={{
                      color: "#999",
                      fontSize: "15px",
                      marginBottom: "10px",
                    }}
                  >
                    or drag and drop multiple images here
                  </p>
                  <p style={{ color: "#ccc", fontSize: "13px", margin: 0 }}>
                    PNG, JPG up to 10MB each
                  </p>
                  <input
                    type="file"
                    id="slider-upload"
                    multiple
                    accept="image/*"
                    onChange={handleSliderImageUpload}
                    style={{ display: "none" }}
                  />
                </div>

                {formData.sliderImages.length > 0 && (
                  <div
                    style={{
                      display: "grid",
                      gridTemplateColumns:
                        "repeat(auto-fill, minmax(180px, 1fr))",
                      gap: "20px",
                      marginTop: "30px",
                    }}
                  >
                    {formData.sliderImages.map((img) => (
                      <div
                        key={img.id}
                        style={{
                          position: "relative",
                          borderRadius: "15px",
                          overflow: "hidden",
                          boxShadow: "0 8px 25px rgba(0,0,0,0.1)",
                          transition: "transform 0.3s ease",
                        }}
                        onMouseEnter={(e) =>
                          (e.currentTarget.style.transform = "translateY(-5px)")
                        }
                        onMouseLeave={(e) =>
                          (e.currentTarget.style.transform = "translateY(0)")
                        }
                      >
                        <img
                          src={img.preview}
                          alt="Slider"
                          style={{
                            width: "100%",
                            height: "180px",
                            objectFit: "cover",
                          }}
                        />
                        <button
                          type="button"
                          onClick={() => removeImage("sliderImages", img.id)}
                          style={{
                            position: "absolute",
                            top: "10px",
                            right: "10px",
                            background: "rgba(255,255,255,0.95)",
                            border: "none",
                            borderRadius: "50%",
                            width: "35px",
                            height: "35px",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            cursor: "pointer",
                            transition: "all 0.3s ease",
                            boxShadow: "0 2px 8px rgba(0,0,0,0.15)",
                          }}
                          onMouseEnter={(e) => {
                            e.currentTarget.style.background = "#ff6b9d";
                            e.currentTarget.style.transform = "scale(1.1)";
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.background =
                              "rgba(255,255,255,0.95)";
                            e.currentTarget.style.transform = "scale(1)";
                          }}
                        >
                          <FiX style={{ fontSize: "18px", color: "#333" }} />
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Wedding Date Section */}
              <div
                style={{
                  background: "white",
                  borderRadius: "30px",
                  padding: "40px",
                  marginBottom: "30px",
                  boxShadow: "0 10px 40px rgba(0,0,0,0.06)",
                  border: "1px solid rgba(255,107,157,0.1)",
                }}
              >
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    marginBottom: "30px",
                    gap: "15px",
                  }}
                >
                  <div
                    style={{
                      width: "50px",
                      height: "50px",
                      borderRadius: "15px",
                      background:
                        "linear-gradient(135deg, #667eea20 0%, #764ba220 100%)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                  >
                    <FiCalendar
                      style={{ fontSize: "24px", color: "#667eea" }}
                    />
                  </div>
                  <div>
                    <h3
                      style={{
                        margin: 0,
                        fontSize: "26px",
                        fontWeight: "600",
                        color: "#2d2d2d",
                      }}
                    >
                      Wedding Date
                    </h3>
                    <p style={{ margin: 0, fontSize: "14px", color: "#999" }}>
                      When is your big day?
                    </p>
                  </div>
                </div>

                <div
                  style={{
                    background:
                      "linear-gradient(135deg, #f8f9ff 0%, #fff8fb 100%)",
                    padding: "30px",
                    borderRadius: "20px",
                    border: "2px solid rgba(102,126,234,0.1)",
                  }}
                >
                  <label
                    style={{
                      display: "block",
                      fontWeight: "600",
                      color: "#333",
                      marginBottom: "12px",
                      fontSize: "16px",
                    }}
                  >
                    Select Your Wedding Date
                  </label>
                  <input
                    type="date"
                    className="form-control"
                    value={formData.weddingDate}
                    onChange={(e) =>
                      setFormData((prev) => ({
                        ...prev,
                        weddingDate: e.target.value,
                      }))
                    }
                    required
                    style={{
                      border: "2px solid #e9ecef",
                      borderRadius: "15px",
                      padding: "15px 20px",
                      fontSize: "16px",
                      transition: "all 0.3s ease",
                      background: "white",
                    }}
                    onFocus={(e) => {
                      e.target.style.borderColor = "#667eea";
                      e.target.style.boxShadow =
                        "0 0 0 4px rgba(102,126,234,0.1)";
                    }}
                    onBlur={(e) => {
                      e.target.style.borderColor = "#e9ecef";
                      e.target.style.boxShadow = "none";
                    }}
                  />
                </div>
              </div>

              {/* Bride & Groom Section */}
              <div
                style={{
                  background: "white",
                  borderRadius: "30px",
                  padding: "40px",
                  marginBottom: "30px",
                  boxShadow: "0 10px 40px rgba(0,0,0,0.06)",
                  border: "1px solid rgba(255,107,157,0.1)",
                }}
              >
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    marginBottom: "30px",
                    gap: "15px",
                  }}
                >
                  <div
                    style={{
                      width: "50px",
                      height: "50px",
                      borderRadius: "15px",
                      background:
                        "linear-gradient(135deg, #ff6b9d20 0%, #c2185b20 100%)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                  >
                    <FiHeart style={{ fontSize: "24px", color: "#ff6b9d" }} />
                  </div>
                  <div>
                    <h3
                      style={{
                        margin: 0,
                        fontSize: "26px",
                        fontWeight: "600",
                        color: "#2d2d2d",
                      }}
                    >
                      The Happy Couple
                    </h3>
                    <p style={{ margin: 0, fontSize: "14px", color: "#999" }}>
                      Tell us about the bride and groom
                    </p>
                  </div>
                </div>

                <div className="row g-4">
                  {/* Bride */}
                  <div className="col-md-6">
                    <div
                      style={{
                        background:
                          "linear-gradient(135deg, #fff5f8 0%, #fffafc 100%)",
                        padding: "30px",
                        borderRadius: "20px",
                        border: "2px solid rgba(255,107,157,0.15)",
                        height: "100%",
                      }}
                    >
                      <h4
                        style={{
                          fontSize: "20px",
                          fontWeight: "600",
                          color: "#ff6b9d",
                          marginBottom: "25px",
                          display: "flex",
                          alignItems: "center",
                          gap: "10px",
                        }}
                      >
                        <span
                          style={{
                            display: "inline-block",
                            width: "8px",
                            height: "8px",
                            borderRadius: "50%",
                            background: "#667eea",
                          }}
                        ></span>
                        Bride Details
                      </h4>

                      <div className="mb-4">
                        <label
                          style={{
                            display: "block",
                            fontWeight: "600",
                            color: "#333",
                            marginBottom: "12px",
                            fontSize: "15px",
                          }}
                        >
                          Bride's Photo
                        </label>
                        <div style={{ position: "relative" }}>
                          {formData.bride.preview ? (
                            <div
                              style={{
                                position: "relative",
                                display: "inline-block",
                              }}
                            >
                              <img
                                src={formData.bride.preview}
                                alt="Bride"
                                style={{
                                  width: "120px",
                                  height: "120px",
                                  borderRadius: "15px",
                                  objectFit: "cover",
                                  border: "3px solid #667eea",
                                }}
                              />
                              <button
                                type="button"
                                onClick={() =>
                                  setFormData((prev) => ({
                                    ...prev,
                                    bride: {
                                      ...prev.bride,
                                      image: null,
                                      preview: null,
                                    },
                                  }))
                                }
                                style={{
                                  position: "absolute",
                                  top: "-10px",
                                  right: "-10px",
                                  background: "white",
                                  border: "2px solid #667eea",
                                  borderRadius: "50%",
                                  width: "30px",
                                  height: "30px",
                                  display: "flex",
                                  alignItems: "center",
                                  justifyContent: "center",
                                  cursor: "pointer",
                                }}
                              >
                                <FiX
                                  style={{ fontSize: "14px", color: "#667eea" }}
                                />
                              </button>
                            </div>
                          ) : (
                            <label
                              style={{
                                display: "inline-flex",
                                alignItems: "center",
                                justifyContent: "center",
                                width: "120px",
                                height: "120px",
                                borderRadius: "15px",
                                border: "3px dashed #b3c5ff",
                                background: "white",
                                cursor: "pointer",
                                transition: "all 0.3s ease",
                                flexDirection: "column",
                                gap: "8px",
                              }}
                              onMouseEnter={(e) => {
                                e.currentTarget.style.borderColor = "#667eea";
                                e.currentTarget.style.background = "#f0f4ff";
                              }}
                              onMouseLeave={(e) => {
                                e.currentTarget.style.borderColor = "#b3c5ff";
                                e.currentTarget.style.background = "white";
                              }}
                            >
                              <FiCamera
                                style={{ fontSize: "28px", color: "#667eea" }}
                              />
                              <span style={{ fontSize: "12px", color: "#999" }}>
                                Upload
                              </span>
                              <input
                                type="file"
                                accept="image/*"
                                onChange={(e) => {
                                  const file = e.target.files[0];
                                  if (file) {
                                    setFormData((prev) => ({
                                      ...prev,
                                      bride: {
                                        ...prev.bride,
                                        image: file,
                                        preview: URL.createObjectURL(file),
                                      },
                                    }));
                                  }
                                }}
                                style={{ display: "none" }}
                              />
                            </label>
                          )}
                        </div>
                      </div>

                      <div className="mb-4">
                        <label
                          style={{
                            display: "block",
                            fontWeight: "600",
                            color: "#333",
                            marginBottom: "12px",
                            fontSize: "15px",
                          }}
                        >
                          Bride's Name
                        </label>
                        <input
                          type="text"
                          className="form-control"
                          value={formData.bride.name}
                          onChange={(e) =>
                            setFormData((prev) => ({
                              ...prev,
                              bride: { ...prev.bride, name: e.target.value },
                            }))
                          }
                          placeholder="Enter bride's name"
                          required
                          style={{
                            border: "2px solid #e6edff",
                            borderRadius: "12px",
                            padding: "12px 18px",
                            fontSize: "15px",
                            background: "white",
                          }}
                          onFocus={(e) => {
                            e.target.style.borderColor = "#667eea";
                            e.target.style.boxShadow =
                              "0 0 0 4px rgba(102,126,234,0.1)";
                          }}
                          onBlur={(e) => {
                            e.target.style.borderColor = "#e6edff";
                            e.target.style.boxShadow = "none";
                          }}
                        />
                      </div>

                      <div>
                        <label
                          style={{
                            display: "block",
                            fontWeight: "600",
                            color: "#333",
                            marginBottom: "12px",
                            fontSize: "15px",
                          }}
                        >
                          About the Bride
                        </label>
                        <textarea
                          className="form-control"
                          rows="4"
                          value={formData.bride.description}
                          onChange={(e) =>
                            setFormData((prev) => ({
                              ...prev,
                              bride: {
                                ...prev.bride,
                                description: e.target.value,
                              },
                            }))
                          }
                          placeholder="Share something special about the bride..."
                          style={{
                            border: "2px solid #e6edff",
                            borderRadius: "12px",
                            padding: "12px 18px",
                            fontSize: "15px",
                            background: "white",
                            resize: "vertical",
                          }}
                          onFocus={(e) => {
                            e.target.style.borderColor = "#667eea";
                            e.target.style.boxShadow =
                              "0 0 0 4px rgba(102,126,234,0.1)";
                          }}
                          onBlur={(e) => {
                            e.target.style.borderColor = "#e6edff";
                            e.target.style.boxShadow = "none";
                          }}
                        />
                      </div>
                    </div>
                  </div>

                  <div className="col-md-6">
                    <div
                      style={{
                        background:
                          "linear-gradient(135deg, #f5f7ff 0%, #fafbff 100%)",
                        padding: "30px",
                        borderRadius: "20px",
                        border: "2px solid rgba(102,126,234,0.15)",
                        height: "100%",
                      }}
                    >
                      <h4
                        style={{
                          fontSize: "20px",
                          fontWeight: "600",
                          color: "#667eea",
                          marginBottom: "25px",
                          display: "flex",
                          alignItems: "center",
                          gap: "10px",
                        }}
                      >
                        <span
                          style={{
                            display: "inline-block",
                            width: "8px",
                            height: "8px",
                            borderRadius: "50%",
                            background: "#667eea",
                          }}
                        ></span>
                        Groom Details
                      </h4>

                      {/* Groom Photo Upload */}
                      <div className="mb-4">
                        <label
                          style={{
                            display: "block",
                            fontWeight: "600",
                            color: "#333",
                            marginBottom: "12px",
                            fontSize: "15px",
                          }}
                        >
                          Groom's Photo
                        </label>
                        <div style={{ position: "relative" }}>
                          {formData.groom.preview ? (
                            <div
                              style={{
                                position: "relative",
                                display: "inline-block",
                              }}
                            >
                              <img
                                src={formData.groom.preview}
                                alt="Groom"
                                style={{
                                  width: "120px",
                                  height: "120px",
                                  borderRadius: "15px",
                                  objectFit: "cover",
                                  border: "3px solid #667eea",
                                }}
                              />
                              <button
                                type="button"
                                onClick={() =>
                                  setFormData((prev) => ({
                                    ...prev,
                                    groom: {
                                      ...prev.groom,
                                      image: null,
                                      preview: null,
                                    },
                                  }))
                                }
                                style={{
                                  position: "absolute",
                                  top: "-10px",
                                  right: "-10px",
                                  background: "white",
                                  border: "2px solid #667eea",
                                  borderRadius: "50%",
                                  width: "30px",
                                  height: "30px",
                                  display: "flex",
                                  alignItems: "center",
                                  justifyContent: "center",
                                  cursor: "pointer",
                                }}
                              >
                                <FiX
                                  style={{ fontSize: "14px", color: "#667eea" }}
                                />
                              </button>
                            </div>
                          ) : (
                            <label
                              style={{
                                display: "inline-flex",
                                alignItems: "center",
                                justifyContent: "center",
                                width: "120px",
                                height: "120px",
                                borderRadius: "15px",
                                border: "3px dashed #b3c5ff",
                                background: "white",
                                cursor: "pointer",
                                transition: "all 0.3s ease",
                                flexDirection: "column",
                                gap: "8px",
                              }}
                              onMouseEnter={(e) => {
                                e.currentTarget.style.borderColor = "#667eea";
                                e.currentTarget.style.background = "#f0f4ff";
                              }}
                              onMouseLeave={(e) => {
                                e.currentTarget.style.borderColor = "#b3c5ff";
                                e.currentTarget.style.background = "white";
                              }}
                            >
                              <FiCamera
                                style={{ fontSize: "28px", color: "#667eea" }}
                              />
                              <span style={{ fontSize: "12px", color: "#999" }}>
                                Upload
                              </span>
                              <input
                                type="file"
                                accept="image/*"
                                onChange={(e) => {
                                  const file = e.target.files[0];
                                  if (file) {
                                    setFormData((prev) => ({
                                      ...prev,
                                      groom: {
                                        ...prev.groom,
                                        image: file,
                                        preview: URL.createObjectURL(file),
                                      },
                                    }));
                                  }
                                }}
                                style={{ display: "none" }}
                              />
                            </label>
                          )}
                        </div>
                      </div>

                      {/* Groom Name */}
                      <div className="mb-4">
                        <label
                          style={{
                            display: "block",
                            fontWeight: "600",
                            color: "#333",
                            marginBottom: "12px",
                            fontSize: "15px",
                          }}
                        >
                          Groom's Name
                        </label>
                        <input
                          type="text"
                          className="form-control"
                          value={formData.groom.name}
                          onChange={(e) =>
                            setFormData((prev) => ({
                              ...prev,
                              groom: { ...prev.groom, name: e.target.value },
                            }))
                          }
                          placeholder="Enter groom's name"
                          required
                          style={{
                            border: "2px solid #e6edff",
                            borderRadius: "12px",
                            padding: "12px 18px",
                            fontSize: "15px",
                            background: "white",
                          }}
                          onFocus={(e) => {
                            e.target.style.borderColor = "#667eea";
                            e.target.style.boxShadow =
                              "0 0 0 4px rgba(102,126,234,0.1)";
                          }}
                          onBlur={(e) => {
                            e.target.style.borderColor = "#e6edff";
                            e.target.style.boxShadow = "none";
                          }}
                        />
                      </div>

                      {/* Groom Description */}
                      <div>
                        <label
                          style={{
                            display: "block",
                            fontWeight: "600",
                            color: "#333",
                            marginBottom: "12px",
                            fontSize: "15px",
                          }}
                        >
                          About the Groom
                        </label>
                        <textarea
                          className="form-control"
                          rows="4"
                          value={formData.groom.description}
                          onChange={(e) =>
                            setFormData((prev) => ({
                              ...prev,
                              groom: {
                                ...prev.groom,
                                description: e.target.value,
                              },
                            }))
                          }
                          placeholder="Share something special about the groom..."
                          style={{
                            border: "2px solid #e6edff",
                            borderRadius: "12px",
                            padding: "12px 18px",
                            fontSize: "15px",
                            background: "white",
                            resize: "vertical",
                          }}
                          onFocus={(e) => {
                            e.target.style.borderColor = "#667eea";
                            e.target.style.boxShadow =
                              "0 0 0 4px rgba(102,126,234,0.1)";
                          }}
                          onBlur={(e) => {
                            e.target.style.borderColor = "#e6edff";
                            e.target.style.boxShadow = "none";
                          }}
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Love Story Section */}
              <div
                style={{
                  background: "white",
                  borderRadius: "30px",
                  padding: "40px",
                  marginBottom: "30px",
                  boxShadow: "0 10px 40px rgba(0,0,0,0.06)",
                  border: "1px solid rgba(255,107,157,0.1)",
                }}
              >
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    marginBottom: "30px",
                    gap: "15px",
                  }}
                >
                  <div
                    style={{
                      width: "50px",
                      height: "50px",
                      borderRadius: "15px",
                      background:
                        "linear-gradient(135deg, #f093fb20 0%, #f5576c20 100%)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                  >
                    <FiHeart style={{ fontSize: "24px", color: "#f5576c" }} />
                  </div>
                  <div>
                    <h3
                      style={{
                        margin: 0,
                        fontSize: "26px",
                        fontWeight: "600",
                        color: "#2d2d2d",
                      }}
                    >
                      Your Love Story
                    </h3>
                    <p style={{ margin: 0, fontSize: "14px", color: "#999" }}>
                      Share the special moments of your journey together
                    </p>
                  </div>
                </div>

                {formData.loveStory.length === 0 && (
                  <div
                    style={{
                      background:
                        "linear-gradient(135deg, #fff5f8 0%, #f8f5ff 100%)",
                      padding: "40px",
                      borderRadius: "20px",
                      textAlign: "center",
                      border: "2px dashed #e0e0e0",
                      marginBottom: "20px",
                    }}
                  >
                    <FiHeart
                      style={{
                        fontSize: "48px",
                        color: "#ddd",
                        marginBottom: "15px",
                      }}
                    />
                    <p style={{ color: "#999", fontSize: "16px", margin: 0 }}>
                      No love story moments added yet. Click below to start
                      adding your special memories!
                    </p>
                  </div>
                )}

                {formData.loveStory.map((story, index) => (
                  <div
                    key={story.id}
                    style={{
                      background:
                        "linear-gradient(135deg, #fff8fb 0%, #faf8ff 100%)",
                      padding: "30px",
                      borderRadius: "20px",
                      marginBottom: "20px",
                      border: "2px solid rgba(245,87,108,0.15)",
                      position: "relative",
                    }}
                  >
                    <div
                      style={{
                        position: "absolute",
                        top: "15px",
                        right: "15px",
                        background: "white",
                        padding: "8px 16px",
                        borderRadius: "20px",
                        fontSize: "13px",
                        fontWeight: "600",
                        color: "#f5576c",
                        border: "1px solid rgba(245,87,108,0.2)",
                      }}
                    >
                      Story #{index + 1}
                    </div>

                    <div className="row g-3">
                      <div className="col-md-4">
                        <label
                          style={{
                            display: "block",
                            fontWeight: "600",
                            color: "#333",
                            marginBottom: "12px",
                            fontSize: "14px",
                          }}
                        >
                          Story Image
                        </label>
                        {story.preview ? (
                          <div
                            style={{
                              position: "relative",
                              display: "inline-block",
                            }}
                          >
                            <img
                              src={story.preview}
                              alt="Story"
                              style={{
                                width: "100%",
                                height: "200px",
                                borderRadius: "15px",
                                objectFit: "cover",
                                border: "3px solid #f5576c",
                              }}
                            />
                          </div>
                        ) : (
                          <label
                            style={{
                              display: "flex",
                              alignItems: "center",
                              justifyContent: "center",
                              width: "100%",
                              height: "200px",
                              borderRadius: "15px",
                              border: "3px dashed #ffccd5",
                              background: "white",
                              cursor: "pointer",
                              transition: "all 0.3s ease",
                              flexDirection: "column",
                              gap: "10px",
                            }}
                            onMouseEnter={(e) => {
                              e.currentTarget.style.borderColor = "#f5576c";
                              e.currentTarget.style.background = "#fff5f8";
                            }}
                            onMouseLeave={(e) => {
                              e.currentTarget.style.borderColor = "#ffccd5";
                              e.currentTarget.style.background = "white";
                            }}
                          >
                            <FiCamera
                              style={{ fontSize: "32px", color: "#f5576c" }}
                            />
                            <span style={{ fontSize: "13px", color: "#999" }}>
                              Upload Image
                            </span>
                            <input
                              type="file"
                              accept="image/*"
                              onChange={(e) =>
                                handleFileUpload(e, "loveStory", index)
                              }
                              style={{ display: "none" }}
                            />
                          </label>
                        )}
                      </div>
                      <div className="col-md-8">
                        <div className="mb-3">
                          <label
                            style={{
                              display: "block",
                              fontWeight: "600",
                              color: "#333",
                              marginBottom: "10px",
                              fontSize: "14px",
                            }}
                          >
                            Story Title
                          </label>
                          <input
                            type="text"
                            className="form-control"
                            value={story.title}
                            onChange={(e) =>
                              updateField(
                                "loveStory",
                                index,
                                "title",
                                e.target.value
                              )
                            }
                            placeholder="e.g., First Date, The Proposal..."
                            style={{
                              border: "2px solid #ffe6f0",
                              borderRadius: "12px",
                              padding: "12px 18px",
                              fontSize: "15px",
                              background: "white",
                            }}
                            onFocus={(e) => {
                              e.target.style.borderColor = "#f5576c";
                              e.target.style.boxShadow =
                                "0 0 0 4px rgba(245,87,108,0.1)";
                            }}
                            onBlur={(e) => {
                              e.target.style.borderColor = "#ffe6f0";
                              e.target.style.boxShadow = "none";
                            }}
                          />
                        </div>
                        <div className="mb-3">
                          <label
                            style={{
                              display: "block",
                              fontWeight: "600",
                              color: "#333",
                              marginBottom: "10px",
                              fontSize: "14px",
                            }}
                          >
                            Date
                          </label>
                          <input
                            type="date"
                            className="form-control"
                            value={story.date}
                            onChange={(e) =>
                              updateField(
                                "loveStory",
                                index,
                                "date",
                                e.target.value
                              )
                            }
                            style={{
                              border: "2px solid #ffe6f0",
                              borderRadius: "12px",
                              padding: "12px 18px",
                              fontSize: "15px",
                              background: "white",
                            }}
                            onFocus={(e) => {
                              e.target.style.borderColor = "#f5576c";
                              e.target.style.boxShadow =
                                "0 0 0 4px rgba(245,87,108,0.1)";
                            }}
                            onBlur={(e) => {
                              e.target.style.borderColor = "#ffe6f0";
                              e.target.style.boxShadow = "none";
                            }}
                          />
                        </div>
                        <div>
                          <label
                            style={{
                              display: "block",
                              fontWeight: "600",
                              color: "#333",
                              marginBottom: "10px",
                              fontSize: "14px",
                            }}
                          >
                            Description
                          </label>
                          <textarea
                            className="form-control"
                            rows="3"
                            value={story.description}
                            onChange={(e) =>
                              updateField(
                                "loveStory",
                                index,
                                "description",
                                e.target.value
                              )
                            }
                            placeholder="Describe this special moment..."
                            style={{
                              border: "2px solid #ffe6f0",
                              borderRadius: "12px",
                              padding: "12px 18px",
                              fontSize: "15px",
                              background: "white",
                              resize: "vertical",
                            }}
                            onFocus={(e) => {
                              e.target.style.borderColor = "#f5576c";
                              e.target.style.boxShadow =
                                "0 0 0 4px rgba(245,87,108,0.1)";
                            }}
                            onBlur={(e) => {
                              e.target.style.borderColor = "#ffe6f0";
                              e.target.style.boxShadow = "none";
                            }}
                          />
                        </div>
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={() => removeImage("loveStory", story.id)}
                      style={{
                        marginTop: "15px",
                        background: "white",
                        border: "2px solid #ffccd5",
                        borderRadius: "12px",
                        padding: "10px 20px",
                        color: "#f5576c",
                        fontWeight: "600",
                        cursor: "pointer",
                        transition: "all 0.3s ease",
                        fontSize: "14px",
                      }}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.background = "#f5576c";
                        e.currentTarget.style.color = "white";
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.background = "white";
                        e.currentTarget.style.color = "#f5576c";
                      }}
                    >
                      <FiX style={{ marginRight: "5px" }} />
                      Remove Story
                    </button>
                  </div>
                ))}

                <button
                  type="button"
                  onClick={addLoveStory}
                  style={{
                    background:
                      "linear-gradient(135deg, #f093fb 0%, #f5576c 100%)",
                    border: "none",
                    borderRadius: "15px",
                    padding: "15px 30px",
                    color: "white",
                    fontWeight: "600",
                    display: "inline-flex",
                    alignItems: "center",
                    gap: "10px",
                    cursor: "pointer",
                    transition: "all 0.3s ease",
                    fontSize: "15px",
                    boxShadow: "0 5px 20px rgba(245,87,108,0.3)",
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.transform = "translateY(-2px)";
                    e.currentTarget.style.boxShadow =
                      "0 8px 25px rgba(245,87,108,0.4)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.transform = "translateY(0)";
                    e.currentTarget.style.boxShadow =
                      "0 5px 20px rgba(245,87,108,0.3)";
                  }}
                >
                  <FiPlus style={{ fontSize: "20px" }} />
                  Add Love Story Moment
                </button>
              </div>

              {/* Wedding Party Section */}
              <div
                style={{
                  background: "white",
                  borderRadius: "30px",
                  padding: "40px",
                  marginBottom: "30px",
                  boxShadow: "0 10px 40px rgba(0,0,0,0.06)",
                  border: "1px solid rgba(255,107,157,0.1)",
                }}
              >
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    marginBottom: "30px",
                    gap: "15px",
                  }}
                >
                  <div
                    style={{
                      width: "50px",
                      height: "50px",
                      borderRadius: "15px",
                      background:
                        "linear-gradient(135deg, #667eea20 0%, #764ba220 100%)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                  >
                    <FiUsers style={{ fontSize: "24px", color: "#667eea" }} />
                  </div>
                  <div>
                    <h3
                      style={{
                        margin: 0,
                        fontSize: "26px",
                        fontWeight: "600",
                        color: "#2d2d2d",
                      }}
                    >
                      Wedding Party
                    </h3>
                    <p style={{ margin: 0, fontSize: "14px", color: "#999" }}>
                      Introduce your bridesmaids, groomsmen, and special guests
                    </p>
                  </div>
                </div>

                {formData.weddingParty.length === 0 && (
                  <div
                    style={{
                      background:
                        "linear-gradient(135deg, #f0f4ff 0%, #f8f9ff 100%)",
                      padding: "40px",
                      borderRadius: "20px",
                      textAlign: "center",
                      border: "2px dashed #e0e0e0",
                      marginBottom: "20px",
                    }}
                  >
                    <FiUsers
                      style={{
                        fontSize: "48px",
                        color: "#ddd",
                        marginBottom: "15px",
                      }}
                    />
                    <p style={{ color: "#999", fontSize: "16px", margin: 0 }}>
                      No wedding party members added yet. Add your bridesmaids,
                      groomsmen, and special people!
                    </p>
                  </div>
                )}

                <div className="row g-4">
                  {formData.weddingParty.map((member, index) => (
                    <div key={member.id} className="col-md-6 col-lg-4">
                      <div
                        style={{
                          background:
                            "linear-gradient(135deg, #f8f9ff 0%, #fff8fb 100%)",
                          padding: "25px",
                          borderRadius: "20px",
                          border: "2px solid rgba(102,126,234,0.15)",
                          height: "100%",
                          position: "relative",
                        }}
                      >
                        <div
                          style={{
                            marginBottom: "20px",
                            textAlign: "center",
                          }}
                        >
                          {member.preview ? (
                            <div
                              style={{
                                position: "relative",
                                display: "inline-block",
                              }}
                            >
                              <img
                                src={member.preview}
                                alt="Member"
                                style={{
                                  width: "120px",
                                  height: "120px",
                                  borderRadius: "50%",
                                  objectFit: "cover",
                                  border: "4px solid #667eea",
                                }}
                              />
                            </div>
                          ) : (
                            <label
                              style={{
                                display: "inline-flex",
                                alignItems: "center",
                                justifyContent: "center",
                                width: "120px",
                                height: "120px",
                                borderRadius: "50%",
                                border: "4px dashed #b3c5ff",
                                background: "white",
                                cursor: "pointer",
                                transition: "all 0.3s ease",
                                flexDirection: "column",
                                gap: "8px",
                              }}
                              onMouseEnter={(e) => {
                                e.currentTarget.style.borderColor = "#667eea";
                                e.currentTarget.style.background = "#f0f4ff";
                              }}
                              onMouseLeave={(e) => {
                                e.currentTarget.style.borderColor = "#b3c5ff";
                                e.currentTarget.style.background = "white";
                              }}
                            >
                              <FiCamera
                                style={{ fontSize: "28px", color: "#667eea" }}
                              />
                              <span style={{ fontSize: "11px", color: "#999" }}>
                                Upload
                              </span>
                              <input
                                type="file"
                                accept="image/*"
                                onChange={(e) =>
                                  handleFileUpload(e, "weddingParty", index)
                                }
                                style={{ display: "none" }}
                              />
                            </label>
                          )}
                        </div>

                        <div className="mb-3">
                          <label
                            style={{
                              display: "block",
                              fontWeight: "600",
                              color: "#333",
                              marginBottom: "10px",
                              fontSize: "14px",
                            }}
                          >
                            Name
                          </label>
                          <input
                            type="text"
                            className="form-control"
                            value={member.name}
                            onChange={(e) =>
                              updateField(
                                "weddingParty",
                                index,
                                "name",
                                e.target.value
                              )
                            }
                            placeholder="Enter name"
                            style={{
                              border: "2px solid #e6edff",
                              borderRadius: "12px",
                              padding: "12px 15px",
                              fontSize: "14px",
                              background: "white",
                            }}
                            onFocus={(e) => {
                              e.target.style.borderColor = "#667eea";
                              e.target.style.boxShadow =
                                "0 0 0 3px rgba(102,126,234,0.1)";
                            }}
                            onBlur={(e) => {
                              e.target.style.borderColor = "#e6edff";
                              e.target.style.boxShadow = "none";
                            }}
                          />
                        </div>

                        <div className="mb-3">
                          <label
                            style={{
                              display: "block",
                              fontWeight: "600",
                              color: "#333",
                              marginBottom: "10px",
                              fontSize: "14px",
                            }}
                          >
                            Role/Relation
                          </label>
                          <input
                            type="text"
                            className="form-control"
                            value={member.relation}
                            onChange={(e) =>
                              updateField(
                                "weddingParty",
                                index,
                                "relation",
                                e.target.value
                              )
                            }
                            placeholder="e.g., Best Man, Maid of Honor"
                            style={{
                              border: "2px solid #e6edff",
                              borderRadius: "12px",
                              padding: "12px 15px",
                              fontSize: "14px",
                              background: "white",
                            }}
                            onFocus={(e) => {
                              e.target.style.borderColor = "#667eea";
                              e.target.style.boxShadow =
                                "0 0 0 3px rgba(102,126,234,0.1)";
                            }}
                            onBlur={(e) => {
                              e.target.style.borderColor = "#e6edff";
                              e.target.style.boxShadow = "none";
                            }}
                          />
                        </div>

                        <button
                          type="button"
                          onClick={() => removeImage("weddingParty", member.id)}
                          style={{
                            width: "100%",
                            background: "white",
                            border: "2px solid #e6edff",
                            borderRadius: "12px",
                            padding: "10px",
                            color: "#667eea",
                            fontWeight: "600",
                            cursor: "pointer",
                            transition: "all 0.3s ease",
                            fontSize: "13px",
                          }}
                          onMouseEnter={(e) => {
                            e.currentTarget.style.background = "#667eea";
                            e.currentTarget.style.color = "white";
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.background = "white";
                            e.currentTarget.style.color = "#667eea";
                          }}
                        >
                          <FiX style={{ marginRight: "5px" }} />
                          Remove
                        </button>
                      </div>
                    </div>
                  ))}
                </div>

                <button
                  type="button"
                  onClick={addWeddingParty}
                  style={{
                    background:
                      "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
                    border: "none",
                    borderRadius: "15px",
                    padding: "15px 30px",
                    color: "white",
                    fontWeight: "600",
                    display: "inline-flex",
                    alignItems: "center",
                    gap: "10px",
                    cursor: "pointer",
                    transition: "all 0.3s ease",
                    fontSize: "15px",
                    boxShadow: "0 5px 20px rgba(102,126,234,0.3)",
                    marginTop: "20px",
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.transform = "translateY(-2px)";
                    e.currentTarget.style.boxShadow =
                      "0 8px 25px rgba(102,126,234,0.4)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.transform = "translateY(0)";
                    e.currentTarget.style.boxShadow =
                      "0 5px 20px rgba(102,126,234,0.3)";
                  }}
                >
                  <FiPlus style={{ fontSize: "20px" }} />
                  Add Wedding Party Member
                </button>
              </div>

              {/* When & Where Section */}
              <div
                style={{
                  background: "white",
                  borderRadius: "30px",
                  padding: "40px",
                  marginBottom: "30px",
                  boxShadow: "0 10px 40px rgba(0,0,0,0.06)",
                  border: "1px solid rgba(255,107,157,0.1)",
                }}
              >
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    marginBottom: "30px",
                    gap: "15px",
                  }}
                >
                  <div
                    style={{
                      width: "50px",
                      height: "50px",
                      borderRadius: "15px",
                      background:
                        "linear-gradient(135deg, #43e97b20 0%, #38f9d720 100%)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                  >
                    <FiMapPin style={{ fontSize: "24px", color: "#43e97b" }} />
                  </div>
                  <div>
                    <h3
                      style={{
                        margin: 0,
                        fontSize: "26px",
                        fontWeight: "600",
                        color: "#2d2d2d",
                      }}
                    >
                      When & Where
                    </h3>
                    <p style={{ margin: 0, fontSize: "14px", color: "#999" }}>
                      Add ceremony, reception, and other event details
                    </p>
                  </div>
                </div>

                {formData.whenWhere.length === 0 && (
                  <div
                    style={{
                      background:
                        "linear-gradient(135deg, #f0fff4 0%, #f0ffff 100%)",
                      padding: "40px",
                      borderRadius: "20px",
                      textAlign: "center",
                      border: "2px dashed #e0e0e0",
                      marginBottom: "20px",
                    }}
                  >
                    <FiMapPin
                      style={{
                        fontSize: "48px",
                        color: "#ddd",
                        marginBottom: "15px",
                      }}
                    />
                    <p style={{ color: "#999", fontSize: "16px", margin: 0 }}>
                      No events added yet. Add your wedding ceremony, reception,
                      and other celebrations!
                    </p>
                  </div>
                )}

                {formData.whenWhere.map((event, index) => (
                  <div
                    key={event.id}
                    style={{
                      background:
                        "linear-gradient(135deg, #f0fff4 0%, #f0ffff 100%)",
                      padding: "30px",
                      borderRadius: "20px",
                      marginBottom: "20px",
                      border: "2px solid rgba(67,233,123,0.2)",
                      position: "relative",
                    }}
                  >
                    <div
                      style={{
                        position: "absolute",
                        top: "15px",
                        right: "15px",
                        background: "white",
                        padding: "8px 16px",
                        borderRadius: "20px",
                        fontSize: "13px",
                        fontWeight: "600",
                        color: "#43e97b",
                        border: "1px solid rgba(67,233,123,0.3)",
                      }}
                    >
                      Event #{index + 1}
                    </div>

                    <div className="row g-3">
                      <div className="col-md-4">
                        <label
                          style={{
                            display: "block",
                            fontWeight: "600",
                            color: "#333",
                            marginBottom: "12px",
                            fontSize: "14px",
                          }}
                        >
                          Event Image
                        </label>
                        {event.preview ? (
                          <div
                            style={{
                              position: "relative",
                              display: "inline-block",
                              width: "100%",
                            }}
                          >
                            <img
                              src={event.preview}
                              alt="Event"
                              style={{
                                width: "100%",
                                height: "200px",
                                borderRadius: "15px",
                                objectFit: "cover",
                                border: "3px solid #43e97b",
                              }}
                            />
                          </div>
                        ) : (
                          <label
                            style={{
                              display: "flex",
                              alignItems: "center",
                              justifyContent: "center",
                              width: "100%",
                              height: "200px",
                              borderRadius: "15px",
                              border: "3px dashed #b3f5cc",
                              background: "white",
                              cursor: "pointer",
                              transition: "all 0.3s ease",
                              flexDirection: "column",
                              gap: "10px",
                            }}
                            onMouseEnter={(e) => {
                              e.currentTarget.style.borderColor = "#43e97b";
                              e.currentTarget.style.background = "#f0fff4";
                            }}
                            onMouseLeave={(e) => {
                              e.currentTarget.style.borderColor = "#b3f5cc";
                              e.currentTarget.style.background = "white";
                            }}
                          >
                            <FiCamera
                              style={{ fontSize: "32px", color: "#43e97b" }}
                            />
                            <span style={{ fontSize: "13px", color: "#999" }}>
                              Upload Image
                            </span>
                            <input
                              type="file"
                              accept="image/*"
                              onChange={(e) =>
                                handleFileUpload(e, "whenWhere", index)
                              }
                              style={{ display: "none" }}
                            />
                          </label>
                        )}
                      </div>
                      <div className="col-md-8">
                        <div className="mb-3">
                          <label
                            style={{
                              display: "block",
                              fontWeight: "600",
                              color: "#333",
                              marginBottom: "10px",
                              fontSize: "14px",
                            }}
                          >
                            Event Title
                          </label>
                          <input
                            type="text"
                            className="form-control"
                            value={event.title}
                            onChange={(e) =>
                              updateField(
                                "whenWhere",
                                index,
                                "title",
                                e.target.value
                              )
                            }
                            placeholder="e.g., Wedding Ceremony, Reception"
                            style={{
                              border: "2px solid #e6fff0",
                              borderRadius: "12px",
                              padding: "12px 18px",
                              fontSize: "15px",
                              background: "white",
                            }}
                            onFocus={(e) => {
                              e.target.style.borderColor = "#43e97b";
                              e.target.style.boxShadow =
                                "0 0 0 4px rgba(67,233,123,0.1)";
                            }}
                            onBlur={(e) => {
                              e.target.style.borderColor = "#e6fff0";
                              e.target.style.boxShadow = "none";
                            }}
                          />
                        </div>
                        <div className="mb-3">
                          <label
                            style={{
                              display: "block",
                              fontWeight: "600",
                              color: "#333",
                              marginBottom: "10px",
                              fontSize: "14px",
                            }}
                          >
                            Location
                          </label>
                          <input
                            type="text"
                            className="form-control"
                            value={event.location}
                            onChange={(e) =>
                              updateField(
                                "whenWhere",
                                index,
                                "location",
                                e.target.value
                              )
                            }
                            placeholder="Enter venue name or address"
                            style={{
                              border: "2px solid #e6fff0",
                              borderRadius: "12px",
                              padding: "12px 18px",
                              fontSize: "15px",
                              background: "white",
                            }}
                            onFocus={(e) => {
                              e.target.style.borderColor = "#43e97b";
                              e.target.style.boxShadow =
                                "0 0 0 4px rgba(67,233,123,0.1)";
                            }}
                            onBlur={(e) => {
                              e.target.style.borderColor = "#e6fff0";
                              e.target.style.boxShadow = "none";
                            }}
                          />
                        </div>
                        <div className="mb-3">
                          <label
                            style={{
                              display: "block",
                              fontWeight: "600",
                              color: "#333",
                              marginBottom: "10px",
                              fontSize: "14px",
                            }}
                          >
                            Date & Time
                          </label>
                          <input
                            type="datetime-local"
                            className="form-control"
                            value={event.date}
                            onChange={(e) =>
                              updateField(
                                "whenWhere",
                                index,
                                "date",
                                e.target.value
                              )
                            }
                            style={{
                              border: "2px solid #e6fff0",
                              borderRadius: "12px",
                              padding: "12px 18px",
                              fontSize: "15px",
                              background: "white",
                            }}
                            onFocus={(e) => {
                              e.target.style.borderColor = "#43e97b";
                              e.target.style.boxShadow =
                                "0 0 0 4px rgba(67,233,123,0.1)";
                            }}
                            onBlur={(e) => {
                              e.target.style.borderColor = "#e6fff0";
                              e.target.style.boxShadow = "none";
                            }}
                          />
                        </div>
                        <div>
                          <label
                            style={{
                              display: "block",
                              fontWeight: "600",
                              color: "#333",
                              marginBottom: "10px",
                              fontSize: "14px",
                            }}
                          >
                            Description
                          </label>
                          <textarea
                            className="form-control"
                            rows="2"
                            value={event.description}
                            onChange={(e) =>
                              updateField(
                                "whenWhere",
                                index,
                                "description",
                                e.target.value
                              )
                            }
                            placeholder="Add any additional details..."
                            style={{
                              border: "2px solid #e6fff0",
                              borderRadius: "12px",
                              padding: "12px 18px",
                              fontSize: "15px",
                              background: "white",
                              resize: "vertical",
                            }}
                            onFocus={(e) => {
                              e.target.style.borderColor = "#43e97b";
                              e.target.style.boxShadow =
                                "0 0 0 4px rgba(67,233,123,0.1)";
                            }}
                            onBlur={(e) => {
                              e.target.style.borderColor = "#e6fff0";
                              e.target.style.boxShadow = "none";
                            }}
                          />
                        </div>
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={() => removeImage("whenWhere", event.id)}
                      style={{
                        marginTop: "15px",
                        background: "white",
                        border: "2px solid #b3f5cc",
                        borderRadius: "12px",
                        padding: "10px 20px",
                        color: "#43e97b",
                        fontWeight: "600",
                        cursor: "pointer",
                        transition: "all 0.3s ease",
                        fontSize: "14px",
                      }}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.background = "#43e97b";
                        e.currentTarget.style.color = "white";
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.background = "white";
                        e.currentTarget.style.color = "#43e97b";
                      }}
                    >
                      <FiX style={{ marginRight: "5px" }} />
                      Remove Event
                    </button>
                  </div>
                ))}

                <button
                  type="button"
                  onClick={addWhenWhere}
                  style={{
                    background:
                      "linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)",
                    border: "none",
                    borderRadius: "15px",
                    padding: "15px 30px",
                    color: "white",
                    fontWeight: "600",
                    display: "inline-flex",
                    alignItems: "center",
                    gap: "10px",
                    cursor: "pointer",
                    transition: "all 0.3s ease",
                    fontSize: "15px",
                    boxShadow: "0 5px 20px rgba(67,233,123,0.3)",
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.transform = "translateY(-2px)";
                    e.currentTarget.style.boxShadow =
                      "0 8px 25px rgba(67,233,123,0.4)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.transform = "translateY(0)";
                    e.currentTarget.style.boxShadow =
                      "0 5px 20px rgba(67,233,123,0.3)";
                  }}
                >
                  <FiPlus style={{ fontSize: "20px" }} />
                  Add Event
                </button>
              </div>

              {/* Gallery Section */}
              <div
                style={{
                  background: "white",
                  borderRadius: "30px",
                  padding: "40px",
                  marginBottom: "30px",
                  boxShadow: "0 10px 40px rgba(0,0,0,0.06)",
                  border: "1px solid rgba(255,107,157,0.1)",
                }}
              >
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    marginBottom: "30px",
                    gap: "15px",
                  }}
                >
                  <div
                    style={{
                      width: "50px",
                      height: "50px",
                      borderRadius: "15px",
                      background:
                        "linear-gradient(135deg, #fa709a20 0%, #fee14020 100%)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                  >
                    <FiImage style={{ fontSize: "24px", color: "#fa709a" }} />
                  </div>
                  <div>
                    <h3
                      style={{
                        margin: 0,
                        fontSize: "26px",
                        fontWeight: "600",
                        color: "#2d2d2d",
                      }}
                    >
                      Photo Gallery
                    </h3>
                    <p style={{ margin: 0, fontSize: "14px", color: "#999" }}>
                      Showcase your favorite photos and memories
                    </p>
                  </div>
                </div>

                <div
                  onClick={() =>
                    document.getElementById("gallery-upload").click()
                  }
                  style={{
                    border: "3px dashed #e0e0e0",
                    borderRadius: "20px",
                    padding: "50px 30px",
                    textAlign: "center",
                    cursor: "pointer",
                    transition: "all 0.3s ease",
                    background:
                      formData.gallery.length > 0
                        ? "#fafafa"
                        : "linear-gradient(135deg, #fff5f8 0%, #fffaf0 100%)",
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.borderColor = "#fa709a";
                    e.currentTarget.style.background =
                      "linear-gradient(135deg, #fff0f5 0%, #fff8f0 100%)";
                    e.currentTarget.style.transform = "translateY(-2px)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.borderColor = "#e0e0e0";
                    e.currentTarget.style.background =
                      formData.gallery.length > 0
                        ? "#fafafa"
                        : "linear-gradient(135deg, #fff5f8 0%, #fffaf0 100%)";
                    e.currentTarget.style.transform = "translateY(0)";
                  }}
                >
                  <div
                    style={{
                      width: "80px",
                      height: "80px",
                      margin: "0 auto 20px",
                      borderRadius: "20px",
                      background:
                        "linear-gradient(135deg, #fa709a15 0%, #fee14015 100%)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                  >
                    <FiUpload style={{ fontSize: "36px", color: "#fa709a" }} />
                  </div>
                  <h5
                    style={{
                      fontSize: "20px",
                      fontWeight: "600",
                      color: "#333",
                      marginBottom: "10px",
                    }}
                  >
                    Upload Gallery Images
                  </h5>
                  <p
                    style={{
                      color: "#999",
                      fontSize: "15px",
                      marginBottom: "10px",
                    }}
                  >
                    Add your beautiful wedding photos
                  </p>
                  <p style={{ color: "#ccc", fontSize: "13px", margin: 0 }}>
                    Multiple images supported
                  </p>
                  <input
                    type="file"
                    id="gallery-upload"
                    multiple
                    accept="image/*"
                    onChange={handleGalleryUpload}
                    style={{ display: "none" }}
                  />
                </div>

                {formData.gallery.length > 0 && (
                  <div
                    style={{
                      display: "grid",
                      gridTemplateColumns:
                        "repeat(auto-fill, minmax(180px, 1fr))",
                      gap: "20px",
                      marginTop: "30px",
                    }}
                  >
                    {formData.gallery.map((img) => (
                      <div
                        key={img.id}
                        style={{
                          position: "relative",
                          borderRadius: "15px",
                          overflow: "hidden",
                          boxShadow: "0 8px 25px rgba(0,0,0,0.1)",
                          transition: "transform 0.3s ease",
                        }}
                        onMouseEnter={(e) =>
                          (e.currentTarget.style.transform =
                            "translateY(-5px) rotate(2deg)")
                        }
                        onMouseLeave={(e) =>
                          (e.currentTarget.style.transform =
                            "translateY(0) rotate(0deg)")
                        }
                      >
                        <img
                          src={img.preview}
                          alt="Gallery"
                          style={{
                            width: "100%",
                            height: "180px",
                            objectFit: "cover",
                          }}
                        />
                        <button
                          type="button"
                          onClick={() => removeImage("gallery", img.id)}
                          style={{
                            position: "absolute",
                            top: "10px",
                            right: "10px",
                            background: "rgba(255,255,255,0.95)",
                            border: "none",
                            borderRadius: "50%",
                            width: "35px",
                            height: "35px",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            cursor: "pointer",
                            transition: "all 0.3s ease",
                            boxShadow: "0 2px 8px rgba(0,0,0,0.15)",
                          }}
                          onMouseEnter={(e) => {
                            e.currentTarget.style.background = "#fa709a";
                            e.currentTarget.style.transform = "scale(1.1)";
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.background =
                              "rgba(255,255,255,0.95)";
                            e.currentTarget.style.transform = "scale(1)";
                          }}
                        >
                          <FiX style={{ fontSize: "18px", color: "#333" }} />
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Submit Button */}
              <div
                style={{
                  background: "white",
                  borderRadius: "30px",
                  padding: "50px 40px",
                  textAlign: "center",
                  boxShadow: "0 10px 40px rgba(0,0,0,0.06)",
                  border: "1px solid rgba(255,107,157,0.1)",
                }}
              >
                <div
                  style={{
                    marginBottom: "25px",
                  }}
                >
                  <h4
                    style={{
                      fontSize: "24px",
                      fontWeight: "600",
                      color: "#2d2d2d",
                      marginBottom: "10px",
                    }}
                  >
                    Ready to Create Your Website?
                  </h4>
                  <p
                    style={{
                      color: "#999",
                      fontSize: "16px",
                      maxWidth: "500px",
                      margin: "0 auto",
                    }}
                  >
                    Review all your details and click the button below to
                    generate your beautiful wedding website
                  </p>
                </div>
                <button
                  type="submit"
                  disabled={loading}
                  style={{
                    background: loading
                      ? "#ccc"
                      : "linear-gradient(135deg, #ff6b9d 0%, #c2185b 50%, #9c27b0 100%)",
                    border: "none",
                    borderRadius: "25px",
                    padding: "18px 60px",
                    color: "white",
                    fontWeight: "700",
                    fontSize: "18px",
                    cursor: loading ? "not-allowed" : "pointer",
                    transition: "all 0.3s ease",
                    boxShadow: loading
                      ? "none"
                      : "0 10px 30px rgba(255,107,157,0.4)",
                    textTransform: "uppercase",
                    letterSpacing: "1px",
                  }}
                  onMouseEnter={(e) => {
                    if (!loading) {
                      e.currentTarget.style.transform = "translateY(-3px)";
                      e.currentTarget.style.boxShadow =
                        "0 15px 40px rgba(255,107,157,0.5)";
                    }
                  }}
                  onMouseLeave={(e) => {
                    if (!loading) {
                      e.currentTarget.style.transform = "translateY(0)";
                      e.currentTarget.style.boxShadow =
                        "0 10px 30px rgba(255,107,157,0.4)";
                    }
                  }}
                >
                  {loading ? (
                    <>
                      <span style={{ marginRight: "10px" }}>⏳</span>
                      Creating Your Website...
                    </>
                  ) : (
                    <>
                      <FiHeart
                        style={{ marginRight: "10px", display: "inline" }}
                      />
                      Create Wedding Website
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
};

export default WeddingWebsiteForm;
