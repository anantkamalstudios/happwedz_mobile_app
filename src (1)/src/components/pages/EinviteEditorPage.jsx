import React, { useEffect, useRef, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useSelector } from "react-redux";
import Swal from "sweetalert2";
import {
  FiArrowLeft,
  FiChevronLeft,
  FiChevronRight,
  FiDownload,
  FiShare2,
} from "react-icons/fi";
import { einviteApi } from "../../services/api/einviteApi";
import EinvitePage from "../layouts/einvites/design/EinvitePage";
import {
  cardFonts,
  cardPath,
  getCardPages,
  loadFonts,
} from "../layouts/einvites/design/einviteDesign";
import { downloadCardPages } from "../layouts/einvites/design/exportCard";
import "../layouts/einvites/einviteStudio.css";

const notify = (text, icon = "success") =>
  Swal.fire({ text, icon, timer: 1600, showConfirmButton: false });

const EinviteEditorPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const authUser = useSelector((state) => state.auth?.user);
  const currentUserId = authUser?.id || authUser?._id || authUser?.userId;

  const [card, setCard] = useState(null);
  const [pages, setPages] = useState([]);
  const [name, setName] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [pageIndex, setPageIndex] = useState(0);
  const [focusedFieldId, setFocusedFieldId] = useState(null);
  const [saving, setSaving] = useState(false);
  const [downloading, setDownloading] = useState(false);
  const [dirty, setDirty] = useState(false);

  const fieldRefs = useRef({});
  const loadedIdRef = useRef(null);

  useEffect(() => {
    // After the first save of a template the URL moves to the new copy's id;
    // that copy is already on screen, so there is nothing to reload.
    if (loadedIdRef.current === id) return undefined;

    let cancelled = false;
    setLoading(true);
    setError(null);
    einviteApi
      .getCard(id)
      .then((data) => {
        if (cancelled) return;
        if (!data) throw new Error("This invitation could not be found.");
        if (
          data.isTemplate === false &&
          data.ownerUserId &&
          currentUserId &&
          String(data.ownerUserId) !== String(currentUserId)
        ) {
          throw new Error("This invitation belongs to another account.");
        }
        loadedIdRef.current = data.id;
        setCard(data);
        setPages(getCardPages(data));
        setName(data.name || "");
        setPageIndex(0);
        setFocusedFieldId(null);
        setDirty(false);
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
  }, [id, currentUserId]);

  // Fonts depend on the design, not on the text being typed.
  useEffect(() => {
    if (card) loadFonts(cardFonts(getCardPages(card)));
  }, [card]);

  useEffect(() => {
    if (!dirty) return undefined;
    const warn = (event) => {
      event.preventDefault();
      event.returnValue = "";
    };
    window.addEventListener("beforeunload", warn);
    return () => window.removeEventListener("beforeunload", warn);
  }, [dirty]);

  const page = pages[pageIndex];

  const updateField = (fieldId, patch) => {
    setPages((prev) =>
      prev.map((p, index) =>
        index !== pageIndex
          ? p
          : { ...p, fields: p.fields.map((f) => (f.id === fieldId ? { ...f, ...patch } : f)) }
      )
    );
    setDirty(true);
  };

  const resizeField = (field, factor) =>
    updateField(field.id, {
      fontSize: Math.min(400, Math.max(4, Math.round(field.fontSize * factor * 10) / 10)),
    });

  const focusField = (fieldId) => {
    setFocusedFieldId(fieldId);
    const input = fieldRefs.current[fieldId];
    if (input) {
      input.focus({ preventScroll: true });
      input.scrollIntoView({ behavior: "smooth", block: "center" });
    }
  };

  const showPage = (index) => {
    setPageIndex(index);
    setFocusedFieldId(null);
  };

  const save = async () => {
    if (!currentUserId) {
      notify("Please log in to save your invitation.", "error");
      return null;
    }

    const payload = {
      name: name.trim() || card.name,
      pages: pages.map((p) => ({
        id: p.id,
        name: p.name,
        backgroundUrl: p.backgroundUrl,
        fields: p.fields,
      })),
    };

    setSaving(true);
    try {
      if (card.isTemplate) {
        const created = await einviteApi.createInstance({
          ...payload,
          originalTemplateId: card.id,
          ownerUserId: currentUserId,
        });
        const saved = created?.data || created;
        if (!saved?.id) throw new Error("Failed to save your invitation.");
        loadedIdRef.current = saved.id;
        setCard(saved);
        setDirty(false);
        navigate(`/einvites/editor/${saved.id}`, { replace: true });
        notify("Saved to Your Cards");
        return saved;
      }

      const updated = await einviteApi.updateInstance(card.id, payload);
      const saved = updated?.data || updated;
      setCard(saved);
      setDirty(false);
      notify("Invitation saved");
      return saved;
    } catch (err) {
      console.error("Error saving invitation:", err);
      notify(err.message || "Failed to save your invitation.", "error");
      return null;
    } finally {
      setSaving(false);
    }
  };

  const saveAndShare = async () => {
    const saved = dirty || card.isTemplate ? await save() : card;
    if (saved?.id) navigate(`/einvites/share/${saved.id}`);
  };

  const download = async (allPages) => {
    setDownloading(true);
    try {
      await downloadCardPages(name.trim() || card.name, pages, allPages ? undefined : [pageIndex]);
    } catch (err) {
      console.error("Error downloading invitation:", err);
      notify("Couldn't create the image. Please try again.", "error");
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
          <p className="eiv-status mt-3">Loading your invitation...</p>
        </div>
      </div>
    );
  }

  if (error || !card || !page) {
    return (
      <div className="eiv">
        <div className="eiv-empty">
          <h3>Can't open this invitation</h3>
          <p>{error || "This invitation has no pages."}</p>
          <Link to="/einvites/category/wedding_einvite" className="eiv-outline-btn">
            Browse designs
          </Link>
        </div>
      </div>
    );
  }

  const status = saving
    ? "Saving..."
    : dirty
    ? "Unsaved changes"
    : card.isTemplate
    ? "Not saved yet"
    : "All changes saved";

  return (
    <div className="eiv">
      <div className="eiv-editor-bar">
        <div className="container eiv-editor-bar-inner">
          <Link
            to={card.isTemplate ? cardPath(card) : "/einvites/my-cards"}
            className="eiv-outline-btn"
            aria-label="Back"
          >
            <FiArrowLeft size={16} />
            <span className="d-none d-sm-inline">Back</span>
          </Link>
          <input
            className="eiv-name-input"
            value={name}
            maxLength={120}
            aria-label="Invitation name"
            onChange={(e) => {
              setName(e.target.value);
              setDirty(true);
            }}
          />
          <span className="eiv-status">{status}</span>
          <div className="d-flex flex-wrap gap-2 ms-auto">
            <button type="button" className="eiv-outline-btn" onClick={() => download(false)} disabled={downloading}>
              <FiDownload size={16} />
              {downloading ? "Preparing..." : pages.length > 1 ? "Download page" : "Download"}
            </button>
            {pages.length > 1 && (
              <button type="button" className="eiv-outline-btn" onClick={() => download(true)} disabled={downloading}>
                All pages
              </button>
            )}
            <button
              type="button"
              className="eiv-outline-btn"
              onClick={save}
              disabled={saving || (!dirty && !card.isTemplate)}
            >
              Save
            </button>
            <button
              type="button"
              className="eiv-primary-btn"
              style={{ padding: "9px 18px", fontSize: 15 }}
              onClick={saveAndShare}
              disabled={saving}
            >
              <FiShare2 size={16} /> Save &amp; share
            </button>
          </div>
        </div>
      </div>

      <div className="container py-4">
        <div className="row g-4">
          {pages.length > 1 && (
            <div className="col-lg-1 order-2 order-lg-1">
              <div className="eiv-page-list">
                {pages.map((p, index) => (
                  <button
                    key={p.id}
                    type="button"
                    className={`eiv-page-item ${index === pageIndex ? "is-active" : ""}`}
                    onClick={() => showPage(index)}
                  >
                    <div>
                      <EinvitePage page={p} />
                    </div>
                    Page {index + 1}
                  </button>
                ))}
              </div>
            </div>
          )}

          <div className={`${pages.length > 1 ? "col-lg-6" : "col-lg-7"} order-1 order-lg-2`}>
            <div className="eiv-stage">
              {pages.length > 1 && (
                <button type="button" className="eiv-arrow" aria-label="Previous page"
                  disabled={pageIndex === 0} onClick={() => showPage(pageIndex - 1)}>
                  <FiChevronLeft size={22} />
                </button>
              )}
              <div className="eiv-stage-card">
                <EinvitePage
                  page={page}
                  selectedFieldId={focusedFieldId}
                  onFieldPointerDown={focusField}
                  fieldCursor="text"
                />
              </div>
              {pages.length > 1 && (
                <button type="button" className="eiv-arrow" aria-label="Next page"
                  disabled={pageIndex === pages.length - 1} onClick={() => showPage(pageIndex + 1)}>
                  <FiChevronRight size={22} />
                </button>
              )}
            </div>
            <p className="eiv-status text-center mt-3 mb-0">Tap any text on the card to edit it.</p>
          </div>

          <div className="col-lg-5 order-3">
            <div className="eiv-panel">
              <h2 className="eiv-panel-title mb-1">
                {pages.length > 1 ? `Page ${pageIndex + 1} of ${pages.length}` : "Your details"}
              </h2>
              <p className="eiv-status mb-2">Change the text below. The card updates as you type.</p>

              {page.fields.length === 0 ? (
                <p className="eiv-status mb-0">This page has no text to edit.</p>
              ) : (
                page.fields.map((field) => (
                  <div key={field.id} className={`eiv-field ${field.id === focusedFieldId ? "is-focused" : ""}`}>
                    <div className="d-flex justify-content-between align-items-center gap-2">
                      <label htmlFor={`eiv-field-${field.id}`}>{field.label}</label>
                      <div className="eiv-size-btns">
                        <button type="button" aria-label={`Smaller text for ${field.label}`} onClick={() => resizeField(field, 0.92)}>
                          A−
                        </button>
                        <button type="button" aria-label={`Larger text for ${field.label}`} onClick={() => resizeField(field, 1.08)}>
                          A+
                        </button>
                      </div>
                    </div>
                    <textarea
                      id={`eiv-field-${field.id}`}
                      ref={(element) => {
                        fieldRefs.current[field.id] = element;
                      }}
                      rows={Math.min(6, Math.max(1, field.defaultText.split("\n").length))}
                      value={field.defaultText}
                      maxLength={1000}
                      onFocus={() => setFocusedFieldId(field.id)}
                      onChange={(e) => updateField(field.id, { defaultText: e.target.value })}
                    />
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EinviteEditorPage;
