import React from "react";
import EinviteCardItem from "./EinviteCardItem";

const EinviteCardGrid = ({
  cards = [],
  loading = false,
  showActions = true,
  showEditButton = true,
  showShareButton = false,
  onCardClickEdit = false,
  fixedImageHeight,
}) => {
  if (loading) {
    return (
      <div className="row">
        {[...Array(6)].map((_, index) => (
          <div key={index} className="col-lg-3 col-md-6 mb-4">
            <div className="card h-100 shadow-sm">
              <div className="einvite-card-skeleton">
                <div className="skeleton-image"></div>
                <div className="skeleton-content">
                  <div className="skeleton-title"></div>
                  <div className="skeleton-text"></div>
                  <div className="skeleton-text short"></div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (cards.length === 0) {
    return (
      <div className="text-center py-5">
        <i className="fas fa-heart fa-4x text-muted mb-4"></i>
        <h4>No cards found</h4>
        <p className="text-muted">
          Try adjusting your search or filter criteria
        </p>
      </div>
    );
  }

  return (
    <div className="row">
      {cards.map((card) => (
        <div key={card.id} className="col-lg-4 col-md-6 mb-4">
          <EinviteCardItem
            card={card}
            showActions={showActions}
            showEditButton={showEditButton}
            showShareButton={showShareButton}
            onCardClickEdit={onCardClickEdit}
            fixedImageHeight={fixedImageHeight}
          />
        </div>
      ))}
    </div>
  );
};

export default EinviteCardGrid;
