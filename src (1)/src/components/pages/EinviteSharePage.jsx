import React, { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import Swal from "sweetalert2";
import {
  FaArrowLeft,
  FaCheckCircle,
  FaDownload,
  FaEdit,
  FaEnvelope,
  FaLink,
  FaShareAlt,
  FaWhatsapp,
} from "react-icons/fa";
import { FiChevronLeft, FiChevronRight } from "react-icons/fi";
import { einviteApi } from "../../services/api/einviteApi";
import EinvitePage from "../layouts/einvites/design/EinvitePage";
import {
  cardFonts,
  cardPath,
  cardTypeLabel,
  getCardPages,
  loadFonts,
} from "../layouts/einvites/design/einviteDesign";
import { downloadCardPages } from "../layouts/einvites/design/exportCard";
import "../layouts/einvites/einviteStudio.css";

const EinviteSharePage = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const authUser = useSelector((state) => state.auth?.user);
  const currentUserId = authUser?.id || authUser?._id || authUser?.userId;

  const [card, setCard] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [pageIndex, setPageIndex] = useState(0);
  const [copied, setCopied] = useState(false);
  const [downloading, setDownloading] = useState(false);

  const shareUrl = `${window.location.origin}/einvites/view/${id}`;

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    einviteApi
      .getCard(id)
      .then((data) => {
        if (cancelled) return;
        if (data?.isTemplate) {
          // Templates are previewed on their design page.
          navigate(cardPath(data), { replace: true });
          return;
        }
        setCard(data);
      })
      .catch((err) => {
        if (!cancelled) setError(err.message || "Failed to load the invitation.");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [id, navigate]);

  const pages = useMemo(() => getCardPages(card), [card]);
  useEffect(() => {
    if (pages.length) loadFonts(cardFonts(pages));
  }, [pages]);

  const isOwner =
    Boolean(card?.ownerUserId && currentUserId) &&
    String(card.ownerUserId) === String(currentUserId);

  const shareOnWhatsApp = () => {
    const message = `You're invited! View our wedding invitation: ${shareUrl}`;
    window.open(`https://wa.me/?text=${encodeURIComponent(message)}`, "_blank", "noopener");
  };

  const shareByEmail = () => {
    const subject = card?.name || "Wedding Invitation";
    const body = `You're invited to our wedding! View the invitation here: ${shareUrl}`;
    window.location.href = `mailto:?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
  };

  const copyLink = async () => {
    try {
      await navigator.clipboard.writeText(shareUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      Swal.fire({ text: "Couldn't copy the link. Please copy it from the address bar.", icon: "error" });
    }
  };

  const downloadAll = async () => {
    setDownloading(true);
    try {
      await downloadCardPages(card.name, pages);
    } catch (err) {
      console.error("Error downloading invitation:", err);
      Swal.fire({ text: "Couldn't create the images. Please try again.", icon: "error" });
    } finally {
      setDownloading(false);
    }
  };

  if (loading) {
    return (
      <div className="eiv">
        <div className="container py-5 text-center">
          <div className="spinner-border" style={{ color: "#ed1173" }} role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
        </div>
      </div>
    );
  }

  if (error || !card || pages.length === 0) {
    return (
      <div className="eiv">
        <div className="eiv-empty">
          <h3>Invitation not found</h3>
          <p>{error || "The requested invitation could not be found."}</p>
          <Link className="eiv-outline-btn" to="/einvites">
            <FaArrowLeft /> Back to e-invites
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="eiv">
      <div className="container py-4">
        <Link to={isOwner ? "/einvites/my-cards" : "/einvites"} className="eiv-outline-btn mb-4">
          <FaArrowLeft /> {isOwner ? "Your Cards" : "Back"}
        </Link>

        <div className="row g-4 g-lg-5 align-items-start">
          <div className="col-lg-7">
            {pages.length > 1 && (
              <div className="eiv-page-pills">
                {pages.map((page, index) => (
                  <button key={page.id} type="button"
                    className={`eiv-page-pill ${index === pageIndex ? "is-active" : ""}`}
                    onClick={() => setPageIndex(index)}>
                    Page {index + 1}
                  </button>
                ))}
              </div>
            )}
            <div className="eiv-stage">
              {pages.length > 1 && (
                <button type="button" className="eiv-arrow" aria-label="Previous page"
                  disabled={pageIndex === 0} onClick={() => setPageIndex(pageIndex - 1)}>
                  <FiChevronLeft size={22} />
                </button>
              )}
              <div className="eiv-stage-card">
                <EinvitePage page={pages[pageIndex]} />
              </div>
              {pages.length > 1 && (
                <button type="button" className="eiv-arrow" aria-label="Next page"
                  disabled={pageIndex === pages.length - 1} onClick={() => setPageIndex(pageIndex + 1)}>
                  <FiChevronRight size={22} />
                </button>
              )}
            </div>
          </div>

          <div className="col-lg-5">
            <div className="eiv-info">
              <div className="d-flex align-items-center gap-3 mb-4">
                <span
                  className="d-inline-flex align-items-center justify-content-center rounded-circle text-white"
                  style={{ width: 52, height: 52, background: "#ed1173", flexShrink: 0 }}
                >
                  <FaShareAlt size={22} />
                </span>
                <div>
                  <h1 className="eiv-info-title mb-1">Share your invitation</h1>
                  <p className="eiv-status mb-0">Spread the joy with friends and family</p>
                </div>
              </div>

              <div className="row g-2 mb-4">
                <div className="col-sm-6">
                  <button type="button" className="btn btn-success w-100 py-2 d-flex align-items-center justify-content-center gap-2" onClick={shareOnWhatsApp}>
                    <FaWhatsapp size={18} /> WhatsApp
                  </button>
                </div>
                <div className="col-sm-6">
                  <button type="button" className="eiv-primary-btn w-100 py-2" style={{ fontSize: 15 }} onClick={shareByEmail}>
                    <FaEnvelope size={16} /> Email
                  </button>
                </div>
                <div className="col-12">
                  <button type="button" className="eiv-outline-btn w-100 justify-content-center py-2" onClick={copyLink}>
                    {copied ? (<><FaCheckCircle className="text-success" /> Link copied</>) : (<><FaLink /> Copy link</>)}
                  </button>
                </div>
                <div className="col-12">
                  <button type="button" className="eiv-outline-btn w-100 justify-content-center py-2" onClick={downloadAll} disabled={downloading}>
                    <FaDownload /> {downloading ? "Preparing images..." : pages.length > 1 ? `Download all ${pages.length} pages` : "Download"}
                  </button>
                </div>
              </div>

              <div className="border rounded p-3 mb-3 small">
                <div className="d-flex justify-content-between py-1">
                  <span className="eiv-status">Name</span>
                  <span className="fw-semibold text-end">{card.name}</span>
                </div>
                <div className="d-flex justify-content-between py-1">
                  <span className="eiv-status">Type</span>
                  <span className="fw-semibold">{cardTypeLabel(card.cardType)}</span>
                </div>
                <div className="d-flex justify-content-between py-1">
                  <span className="eiv-status">Pages</span>
                  <span className="fw-semibold">{pages.length}</span>
                </div>
              </div>

              {isOwner && (
                <Link className="eiv-outline-btn w-100 justify-content-center py-2" to={`/einvites/editor/${card.id}`}>
                  <FaEdit /> Edit invitation
                </Link>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EinviteSharePage;
