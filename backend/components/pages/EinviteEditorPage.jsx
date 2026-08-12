import React, { useState, useEffect, useMemo } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import EinviteCardEditor from "../layouts/einvites/EinviteCardEditor";
import EinviteShareModal from "../layouts/einvites/EinviteShareModal";
import { einviteApi } from "../../services/api/einviteApi";
import { useSelector } from "react-redux";
import Swal from "sweetalert2";

const EinviteEditorPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [card, setCard] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showShareModal, setShowShareModal] = useState(false);
  const authUser = useSelector((s) => s.auth?.user);
  const currentUserId = authUser?.id || authUser?._id || authUser?.userId;

  useEffect(() => {
    if (id) {
      fetchCard();
    }
  }, [id]);

  const fetchCard = async () => {
    try {
      setLoading(true);
      const data = await einviteApi.getEinviteById(id);
      setCard(data.data);
    } catch (err) {
      setError("Failed to load card");
      console.error("Error fetching card:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (updatedPayload) => {
    try {
      const isTemplate = card?.isTemplate === true || !card?.ownerUserId;

      if (isTemplate) {
        if (!currentUserId) {
          Swal.fire({
            text: "Please log in to customize this card.",
            timer: 1500,
            icon: "error",
          });
          return;
        }

        const createBody = {
          originalTemplateId: card.id,
          ownerUserId: currentUserId,
          name: updatedPayload.name || card.name,
          cardType: updatedPayload.cardType || card.cardType,
          backgroundUrl: updatedPayload.backgroundUrl || card.backgroundUrl,
          thumbnailUrl: updatedPayload.thumbnailUrl || card.thumbnailUrl,
          editableFields: updatedPayload.editableFields,
        };

        const created = await einviteApi.createInstance(createBody);
        const newCard = created?.data || created;
        if (!newCard?.id) {
          throw new Error("Failed to create instance");
        }
        setCard(newCard);
        // Navigate to new instance id so subsequent edits target the instance
        navigate(`/einvites/editor/${newCard.id}`);
        // alert("Your personal copy has been created. You can continue editing.");
        Swal.fire({
          text: "Your personal copy has been created. You can continue editing.",
          timer: 1500,
          icon: "success",
        });
        return;
      }

      // Otherwise, update existing user-owned instance
      const updateRes = await einviteApi.updateInstance(
        card.id,
        updatedPayload
      );
      const saved = updateRes?.data || updateRes;
      setCard(saved);
      // alert("Card saved successfully!");
      Swal.fire({
        text: "Card saved successfully!",
        timer: 1500,
        icon: "success",
      });
    } catch (err) {
      console.error("Error saving card:", err);
      // alert("Failed to save card");
      Swal.fire({
        text: "Failed to save card",
        timer: 1500,
        icon: "error",
      });
    }
  };

  const handleCancel = () => {
    navigate("/einvites");
  };

  const handlePublish = (shareData) => {
    // Here you would implement the actual publishing logic
    navigate(`/einvites/share/${id}`);
  };

  if (loading) {
    return (
      <div className="container py-5">
        <div className="text-center">
          <div className="spinner-border text-primary" role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
          <p className="mt-3">Loading editor...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container py-5">
        <div className="alert alert-danger" role="alert">
          <i className="fas fa-exclamation-triangle me-2"></i>
          {error}
        </div>
        <button
          className="btn btn-primary"
          onClick={() => navigate("/einvites")}
        >
          Back to Browse
        </button>
      </div>
    );
  }

  if (!card) {
    return (
      <div className="container py-5">
        <div className="text-center">
          <h4>Card not found</h4>
          <p className="text-muted">The requested card could not be found.</p>
          <button
            className="btn btn-primary"
            onClick={() => navigate("/einvites")}
          >
            Back to Browse
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="einvite-editor-page">
      <div className="einvite-editor-header">
        <div className="container">
          <div className="row align-items-center mt-3">
            <div className="col-md-6">
              <h4 className="mb-0">Editing: {card.name}</h4>
            </div>
            <div className="col-md-6 text-end">
              <div className="einvite-editor-actions">
                <button
                  className="btn btn-outline-secondary me-2"
                  onClick={handleCancel}
                >
                  Cancel
                </button>
                <Link
                  className="btn btn-outline-primary me-2"
                  to={`/einvites/my-cards`}
                >
                  My Cards
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>

      <EinviteCardEditor
        card={card}
        onSave={handleSave}
        onCancel={handleCancel}
      />

      <EinviteShareModal
        show={showShareModal}
        onHide={() => setShowShareModal(false)}
        card={card}
        onPublish={handlePublish}
      />
    </div>
  );
};

export default EinviteEditorPage;
