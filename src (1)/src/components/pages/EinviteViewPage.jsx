import React, { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { FaHeart } from "react-icons/fa";
import { einviteApi } from "../../services/api/einviteApi";
import EinvitePage from "../layouts/einvites/design/EinvitePage";
import {
  cardFonts,
  cardPath,
  getCardPages,
  loadFonts,
} from "../layouts/einvites/design/einviteDesign";
import "../layouts/einvites/einviteStudio.css";

// What guests see when they open a shared invitation link.
const EinviteViewPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [card, setCard] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showRsvpForm, setShowRsvpForm] = useState(false);
  const [guestName, setGuestName] = useState("");
  const [rsvpStatus, setRsvpStatus] = useState("");
  const [guestComment, setGuestComment] = useState("");

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    einviteApi
      .getCard(id)
      .then((data) => {
        if (cancelled) return;
        if (data?.isTemplate) {
          navigate(cardPath(data), { replace: true });
          return;
        }
        setCard(data);
      })
      .catch((err) => {
        if (!cancelled) setError(err.message || "This invitation could not be found.");
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

  const submitRsvp = (event) => {
    event.preventDefault();
    alert(`Thank you ${guestName}! Your RSVP has been recorded.`);
    setShowRsvpForm(false);
    setGuestName("");
    setGuestComment("");
    setRsvpStatus("");
  };

  if (loading) {
    return (
      <div className="eiv">
        <div className="container py-5 text-center">
          <div className="spinner-border" style={{ color: "#ed1173" }} role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
          <p className="eiv-status mt-3">Loading your invitation...</p>
        </div>
      </div>
    );
  }

  if (error || !card || pages.length === 0) {
    return (
      <div className="eiv">
        <div className="eiv-empty">
          <h3>Invitation not found</h3>
          <p>{error || "This invitation is no longer available."}</p>
          <Link className="eiv-outline-btn" to="/">Go to HappyWedz</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="eiv">
      <div className="container py-4 py-md-5">
        <div className="mx-auto" style={{ maxWidth: 460 }}>
          {pages.map((page, index) => (
            <div key={page.id} className="mb-4">
              <EinvitePage
                page={page}
                style={{ boxShadow: "0 16px 40px rgba(0,0,0,0.16)", borderRadius: 4 }}
              />
              {pages.length > 1 && (
                <p className="eiv-status text-center mt-2 mb-0">Page {index + 1} of {pages.length}</p>
              )}
            </div>
          ))}

          <div className="eiv-info text-center">
            <h1 className="eiv-info-title mb-2">{card.name || "Wedding Invitation"}</h1>
            <p className="eiv-status mb-4">You're invited to celebrate this special occasion with us!</p>
            <button type="button" className="eiv-primary-btn" onClick={() => setShowRsvpForm((open) => !open)}>
              <FaHeart /> RSVP
            </button>

            {showRsvpForm && (
              <form className="text-start mt-4" onSubmit={submitRsvp}>
                <div className="mb-3">
                  <label className="form-label fw-semibold" htmlFor="rsvp-name">Your name</label>
                  <input id="rsvp-name" type="text" className="form-control" required
                    value={guestName} onChange={(e) => setGuestName(e.target.value)} />
                </div>
                <div className="mb-3">
                  <label className="form-label fw-semibold" htmlFor="rsvp-status">Will you attend?</label>
                  <select id="rsvp-status" className="form-select" required
                    value={rsvpStatus} onChange={(e) => setRsvpStatus(e.target.value)}>
                    <option value="">Select your response...</option>
                    <option value="yes">Yes, I'll be there!</option>
                    <option value="no">Sorry, can't make it</option>
                    <option value="maybe">Maybe</option>
                  </select>
                </div>
                <div className="mb-3">
                  <label className="form-label fw-semibold" htmlFor="rsvp-message">Message (optional)</label>
                  <textarea id="rsvp-message" className="form-control" rows={3}
                    value={guestComment} onChange={(e) => setGuestComment(e.target.value)} />
                </div>
                <div className="d-flex gap-2">
                  <button type="submit" className="eiv-primary-btn flex-grow-1">Submit RSVP</button>
                  <button type="button" className="eiv-outline-btn" onClick={() => setShowRsvpForm(false)}>Cancel</button>
                </div>
              </form>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default EinviteViewPage;
