import React, { useEffect, useState, useCallback, useRef } from "react";
import { useParams, useLocation, useNavigate, useSearchParams } from "react-router-dom";
import {
  FaArrowLeft,
  FaTimes,
  FaChevronLeft,
  FaChevronRight,
  FaCamera,
  FaUpload,
  FaRedo,
  FaCheck,
  FaImage,
  FaSignOutAlt,
} from "react-icons/fa";
import useMovmentPlus from "../../hooks/useMovmentPlus";
// Called directly rather than through useMovmentPlus: the hook returns a new
// function identity every render, which would re-trigger the effect below in a
// loop, and its shared `loading` flag would fight the gallery's own loader.
import { movmentPlusApi } from "../../services/api";
import Loader from "../ui/Loader";
import "./movment-plus-gallery.css";
import { useDispatch, useSelector } from "react-redux";
import { removeGuestToken } from "../../redux/guestToken";
import { formatDate } from "../../utils/dateFormat";

const MovmentPlusGallery = () => {
  const { token } = useParams();
  const location = useLocation();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { fetchGalleryByToken, loading, data, error } = useMovmentPlus();
  const [galleryData, setGalleryData] = useState(
    location.state?.galleryData || null,
  );

  // "My photos" — the subset of the gallery the guest's face appears in,
  // matched by the AI service against the selfie they uploaded.
  const [searchParams, setSearchParams] = useSearchParams();
  const showingMine = searchParams.get("view") === "mine";
  const user = useSelector((state) => state.auth.user);
  const [myPhotos, setMyPhotos] = useState(null);
  const [myPhotosState, setMyPhotosState] = useState("idle");
  const [myPhotosMessage, setMyPhotosMessage] = useState("");
  // Guards against overlapping requests; bumping myPhotosAttempt is how "Try
  // again" asks for a fresh one.
  const myPhotosRequest = useRef({ key: null, promise: null });
  const [myPhotosAttempt, setMyPhotosAttempt] = useState(0);

  const handleLogout = () => {
    dispatch(removeGuestToken());
    navigate("/movment-plus/guest-token");
  };

  // State for collection view and lightbox
  const [selectedCollection, setSelectedCollection] = useState(null);
  const [lightboxIndex, setLightboxIndex] = useState(null);
  const handleImgError = useCallback((e) => {
    e.currentTarget.src = "/images/default-vendor.jpg";
  }, []);

  useEffect(() => {
    if (!galleryData && token) {
      fetchGalleryByToken(token).then((res) => {
        if (res && res.success) {
          setGalleryData(res);
        }
      });
    }
  }, [token, galleryData, fetchGalleryByToken]);

  // Loads the guest's matched photos. Runs when they arrive with ?view=mine
  // straight after uploading a selfie, and again whenever they switch to the
  // tab, so newly encoded photos show up without a full reload.
  useEffect(() => {
    if (!showingMine || !token) return;

    const userId = user?.id;
    if (!userId) {
      setMyPhotosState("error");
      setMyPhotosMessage("Please log in again to see your photos.");
      return;
    }

    // Matching is slow and CPU-bound on the server, so overlapping calls pile
    // up and starve everything else — including a selfie upload issued while
    // they run. The in-flight promise is therefore shared rather than the
    // effect bailing out early: React's StrictMode mounts, unmounts and
    // remounts this component in development, and an early return would leave
    // the second run with no handler attached, so the response would arrive
    // with nothing left listening and the spinner would never stop.
    const requestKey = `${token}:${userId}:${myPhotosAttempt}`;

    if (myPhotosRequest.current.key !== requestKey) {
      myPhotosRequest.current = {
        key: requestKey,
        promise: movmentPlusApi.getMyPhotos({ token, userId }),
      };
    }

    let stale = false;
    setMyPhotosState("loading");

    myPhotosRequest.current.promise
      .then((res) => {
        if (stale) return;
        setMyPhotos(res?.matches || []);
        // An empty result is a normal answer, and the reason matters: no selfie
        // yet, no face found in it, or photos not encoded yet. The service
        // explains which in `message`.
        setMyPhotosMessage(res?.message || "");
        setMyPhotosState("done");
      })
      .catch((err) => {
        if (stale) return;
        setMyPhotosState("error");
        setMyPhotosMessage(
          err?.response?.data?.error ||
            "Could not load your photos. Please try again.",
        );
        // Let the next attempt issue a fresh request rather than replaying the
        // rejected one.
        myPhotosRequest.current = { key: null, promise: null };
      });

    return () => {
      stale = true;
    };
  }, [showingMine, token, user?.id, myPhotosAttempt]);

  // Lightbox Navigation Handlers
  const currentImages =
    selectedCollection && galleryData?.collections
      ? galleryData.collections[selectedCollection] || []
      : [];

  const closeLightbox = useCallback(() => {
    setLightboxIndex(null);
  }, []);

  const nextImage = useCallback(() => {
    setLightboxIndex((prev) =>
      prev !== null ? (prev + 1) % currentImages.length : null,
    );
  }, [currentImages.length]);

  const prevImage = useCallback(() => {
    setLightboxIndex((prev) =>
      prev !== null
        ? (prev - 1 + currentImages.length) % currentImages.length
        : null,
    );
  }, [currentImages.length]);

  // Keyboard support for Lightbox
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (lightboxIndex === null) return;

      switch (e.key) {
        case "ArrowLeft":
          prevImage();
          break;
        case "ArrowRight":
          nextImage();
          break;
        case "Escape":
          closeLightbox();
          break;
        default:
          break;
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [lightboxIndex, nextImage, prevImage, closeLightbox]);

  if (loading && !galleryData) {
    return <Loader />;
  }

  if (error || (!loading && !galleryData)) {
    return (
      <div className="text-center py-5">
        <h3>Gallery not found or access denied.</h3>
      </div>
    );
  }

  // Extract collections from data
  const collections = galleryData?.collections || {};
  const collectionNames = Object.keys(collections);

  // Placeholder data for header
  const eventName = "Wedding Gallery";

  // Try to find a date from the first available media item
  const firstCollectionKey =
    collectionNames.length > 0 ? collectionNames[0] : null;
  const firstMedia = firstCollectionKey
    ? collections[firstCollectionKey][0]
    : null;

  const eventDate = formatDate(firstMedia?.created_at, "Date not available");

  // Render "My Photos" — only the pictures the guest's face was matched in.
  if (showingMine) {
    const matches = myPhotos || [];

    return (
      <div className="gallery_page_container">
        <header className="gallery_header">
          <div className="container">
            <h1>My Photos</h1>
            <p>{eventDate}</p>
          </div>
        </header>

        <div className="gallery_grid_container">
          <div className="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
            <button
              className="btn btn-outline-secondary d-flex align-items-center gap-2"
              onClick={() => setSearchParams({})}
            >
              <FaArrowLeft /> All photos
            </button>

            <button
              className="btn btn-outline-secondary d-flex align-items-center gap-2"
              onClick={() => navigate("/movment-plus/upload-selfie")}
            >
              <FaCamera /> Use a different selfie
            </button>
          </div>

          {myPhotosState === "loading" && (
            <div className="text-center py-5 text-muted">
              <div className="spinner-border text-secondary mb-3" role="status">
                <span className="visually-hidden">Loading</span>
              </div>
              <p className="mb-1">Looking for you in this gallery...</p>
              {/* Matching re-reads the selfie and runs face detection over it
                  server-side, which takes over a minute. Without saying so the
                  wait reads as a hang. */}
              <p className="small mb-0">
                This can take a minute or two. You can leave this page open.
              </p>
            </div>
          )}

          {myPhotosState === "error" && (
            <div className="text-center py-5">
              <p className="text-danger mb-3">{myPhotosMessage}</p>
              <button
                className="btn btn-outline-secondary"
                onClick={() => setMyPhotosAttempt((n) => n + 1)}
              >
                <FaRedo className="me-2" /> Try again
              </button>
            </div>
          )}

          {myPhotosState === "done" && matches.length === 0 && (
            <div className="text-center py-5">
              <p className="text-muted mb-3">
                {myPhotosMessage || "We could not find you in these photos yet."}
              </p>
              <button
                className="btn btn-outline-secondary d-inline-flex align-items-center gap-2"
                onClick={() => navigate("/movment-plus/upload-selfie")}
              >
                <FaCamera /> Try another selfie
              </button>
            </div>
          )}

          {myPhotosState === "done" && matches.length > 0 && (
            <>
              <p className="text-muted mb-3">
                Found you in {matches.length}{" "}
                {matches.length === 1 ? "photo" : "photos"}.
              </p>
              <div className="gallery_grid">
                {matches.map((match) => (
                  <div key={match.photo_id} className="collection_card image_card">
                    <div className="card_image_wrapper">
                      <img
                        src={match.photo_url}
                        alt={match.function_name || "Matched photo"}
                        className="card_image"
                        loading="lazy"
                        onError={handleImgError}
                        referrerPolicy="no-referrer"
                      />
                    </div>
                  </div>
                ))}
              </div>
            </>
          )}
        </div>
      </div>
    );
  }

  // Render Collection View (Images in a folder)
  if (selectedCollection) {
    const images = collections[selectedCollection] || [];

    return (
      <div className="gallery_page_container">
        {/* Collection Header */}
        <header className="gallery_header">
          <div className="container">
            <h1>{eventName}</h1>
            <p>{eventDate}</p>
          </div>
        </header>

        {/* Images Grid */}
        <div className="gallery_grid_container">
          <div className="gallery_grid">
            {images.map((img, index) => (
              <div
                key={index}
                className="collection_card image_card"
                onClick={() => setLightboxIndex(index)}
                style={{ cursor: "pointer" }}
              >
                <div className="card_image_wrapper">
                  <img
                    src={img.url}
                    alt={`Item ${index}`}
                    className="card_image"
                    loading="lazy"
                    onError={handleImgError}
                    referrerPolicy="no-referrer"
                  />
                </div>
              </div>
            ))}
            {images.length === 0 && (
              <div className="text-center w-100 py-5 text-muted">
                No images in this collection yet.
              </div>
            )}
          </div>
        </div>

        {/* Lightbox Overlay */}
        {lightboxIndex !== null && (
          <div className="lightbox_overlay">
            <button className="lightbox_close" onClick={closeLightbox}>
              <FaTimes />
            </button>

            <button
              className="lightbox_nav prev"
              onClick={(e) => {
                e.stopPropagation();
                prevImage();
              }}
            >
              <FaChevronLeft />
            </button>

            <div className="lightbox_content">
              <img
                src={images[lightboxIndex].url}
                alt={`Full screen ${lightboxIndex}`}
                className="lightbox_image"
                onError={handleImgError}
                referrerPolicy="no-referrer"
              />
              <div className="lightbox_counter">
                {lightboxIndex + 1} / {images.length}
              </div>
            </div>

            <button
              className="lightbox_nav next"
              onClick={(e) => {
                e.stopPropagation();
                nextImage();
              }}
            >
              <FaChevronRight />
            </button>
          </div>
        )}
      </div>
    );
  }

  // Render Main Gallery View (List of Folders)
  return (
    <div className="gallery_page_container">
      {/* Header */}
      <header className="gallery_header">
        <div className="container">
          <h1>{eventName}</h1>
          <p>{eventDate}</p>
        </div>
      </header>

      {/* Gallery Grid */}
      <div className="gallery_grid_container">
        {/* Entry point into face matching. The selfie page stores the selfie,
            then sends the guest back here with ?view=mine. */}
        <div className="d-flex justify-content-end mb-4">
          <button
            className="btn d-flex align-items-center gap-2 fw-semibold"
            onClick={() => setSearchParams({ view: "mine" })}
            style={{
              backgroundColor: "#C31162",
              color: "#fff",
              borderRadius: "12px",
              padding: "10px 20px",
            }}
          >
            <FaCamera /> Find My Photos
          </button>
        </div>

        <div className="gallery_grid">
          {collectionNames.map((name, index) => {
            const images = collections[name];

            return (
              <div
                key={index}
                className="gallery-card folder-card"
                onClick={() => setSelectedCollection(name)}
              >
                <div className="folder-icon-wrapper">
                  <img src="/images/movments-plus/folder.png" alt="Folder" />
                </div>
                <div className="folder-info">
                  <p className="folder-name text-uppercase fw-bold fs-16 inter">
                    {name}
                  </p>
                  <p className="gallery-folder-count fs-14 inter">
                    {images?.length || 0} items
                  </p>
                </div>
              </div>
            );
          })}
        </div>

        {collectionNames.length === 0 && (
          <div className="text-center py-5">
            <p className="text-muted">No collections found in this gallery.</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default MovmentPlusGallery;
