import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { useSelector } from "react-redux";
import EinviteCardGrid from "./EinviteCardGrid";
import { einviteApi } from "../../../services/api/einviteApi";
import Swal from "sweetalert2";

const EinviteMyCards = () => {
  const [cards, setCards] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [isMobile, setIsMobile] = useState(window.innerWidth <= 768);
  const [filterType, setFilterType] = useState("all");

  const authUser = useSelector((state) => state.auth?.user);
  const currentUserId = authUser?.id || authUser?._id || authUser?.userId;

  useEffect(() => {
    if (currentUserId) {
      fetchUserCards();
    } else {
      setLoading(false);
    }
  }, [currentUserId]);

  useEffect(() => {
    const handleResize = () => {
      setIsMobile(window.innerWidth <= 768);
    };

    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  const fetchUserCards = async () => {
    try {
      setLoading(true);
      const data = await einviteApi.getUserEinvites(currentUserId);

      const userCards = Array.isArray(data) ? data : data?.data || [];

      let drafts = [];
      try {
        drafts = JSON.parse(localStorage.getItem("einviteDrafts") || "[]");
      } catch {}
      const merged = [...(Array.isArray(drafts) ? drafts : []), ...userCards];
      setCards(merged);
    } catch (err) {
      setError("Failed to load your cards");
      console.error("Error fetching user cards:", err);
    } finally {
      setLoading(false);
    }
  };

  const getFilteredCards = () => {
    if (filterType === "published") return cards.filter((c) => c.isActive);
    if (filterType === "drafts") return cards.filter((c) => !c.isActive);
    return cards;
  };

  const handleDeleteCard = async (cardId) => {
    if (!window.confirm("Are you sure you want to delete this card?")) return;
    try {
      const key = "einviteDrafts";
      const existing = JSON.parse(localStorage.getItem(key) || "[]");
      const next = existing.filter((d) => d.id !== cardId);
      localStorage.setItem(key, JSON.stringify(next));
      setCards((prev) => prev.filter((card) => card.id !== cardId));
    } catch (err) {
      console.error("Error deleting card:", err);
      Swal.fire({ text: "Failed to delete card", timer: 1500, icon: "error" });
    }
  };

  if (loading) {
    return (
      <div className="container py-5">
        <EinviteCardGrid cards={[]} loading={true} />
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
      </div>
    );
  }

  return (
    <div className="einvite-my-cards">
      <div
        className="row mb-4 light-pink-bg p-4"
        style={{ marginLeft: 0, marginRight: 0 }}
      >
        <div className={isMobile ? "col-12 ps-2 pe-2" : "col-12 container"}>
          <h2 className="einvite-page-title display-6 fw-medium primary-text mb-0 fs-22">
            Published Cards
          </h2>
        </div>
      </div>
      <div
        className={isMobile ? "container-fluid px-3 py-4" : "container py-5"}
      >
        {cards.length === 0 ? (
          <div className="text-center py-5">
            <i className="fas fa-heart fa-4x text-muted mb-4"></i>
            <h4>No cards yet</h4>
            <p className="text-muted">
              Create your first e-invitation to get started
            </p>
            <Link className="btn btn-primary" to="/einvites">
              Browse Templates
            </Link>
          </div>
        ) : (
          <>
            <div className="row mb-4 g-3">
              <div
                className={
                  isMobile ? "col-6 cursor-pointer" : "col-md-3 cursor-pointer"
                }
              >
                <div
                  className="einvite-stats-card"
                  onClick={() => setFilterType("all")}
                >
                  <div className="einvite-stats-number">{cards.length}</div>
                  <div className="einvite-stats-label">Total Cards</div>
                </div>
              </div>
              <div
                className={
                  isMobile ? "col-6 cursor-pointer" : "col-md-3 cursor-pointer"
                }
              >
                <div
                  className="einvite-stats-card"
                  onClick={() => setFilterType("published")}
                >
                  <div className="einvite-stats-number">
                    {cards.filter((card) => card.isActive).length}
                  </div>
                  <div className="einvite-stats-label">Published</div>
                </div>
              </div>
              <div
                className={
                  isMobile ? "col-6 cursor-pointer" : "col-md-3 cursor-pointer"
                }
              >
                <div
                  className="einvite-stats-card"
                  onClick={() => setFilterType("drafts")}
                >
                  <div className="einvite-stats-number">
                    {cards.filter((card) => !card.isActive).length}
                  </div>
                  <div className="einvite-stats-label">Drafts</div>
                </div>
              </div>
              {/* <div
                className={
                  isMobile ? "col-6 cursor-pointer" : "col-md-3 cursor-pointer"
                }
              >
                <div className="einvite-stats-card">
                  <div className="einvite-stats-number">0</div>
                  <div className="einvite-stats-label">Views</div>
                </div>
              </div> */}
            </div>

            <EinviteCardGrid
              cards={getFilteredCards()}
              loading={false}
              showActions={true}
              showEditButton={true}
              showShareButton={false}
              onDelete={handleDeleteCard}
            />
          </>
        )}
      </div>
    </div>
  );
};

export default EinviteMyCards;
