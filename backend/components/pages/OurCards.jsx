import React, { useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { einviteApi } from "../../services/api/einviteApi";
import { getImageUrl, handleImageError } from "../../utils/imageUtils";
import EinviteCardGrid from "../layouts/einvites/EinviteCardGrid";

const OurCards = () => {
    const navigate = useNavigate();
    const authUser = useSelector((s) => s.auth?.user);
    const currentUserId = authUser?.id || authUser?._id || authUser?.userId;

    const [cards, setCards] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        if (!currentUserId) return;
        (async () => {
            try {
                setLoading(true);
                const all = await einviteApi.getAllEinvites();
                const instances = Array.isArray(all)
                    ? all.filter((c) => c.ownerUserId === currentUserId && c.isTemplate === false)
                    : [];
                setCards(instances);
            } catch (e) {
                console.error(e);
                setError("Failed to load your cards");
            } finally {
                setLoading(false);
            }
        })();
    }, [currentUserId]);

    const drafts = useMemo(
        () => cards.filter((c) => c.status === "draft" || c.isPublished === false),
        [cards]
    );
    const published = useMemo(
        () => cards.filter((c) => c.status === "published" || c.isPublished === true),
        [cards]
    );

    const DraftsGrid = () => (
        <EinviteCardGrid cards={drafts} loading={false} showActions={true} onCardClickEdit={true} fixedImageHeight={220} />
    );
    const PublishedGrid = () => (
        <EinviteCardGrid cards={published} loading={false} showActions={true} onCardClickEdit={true} fixedImageHeight={220} />
    );

    if (!currentUserId) {
        return (
            <div className="container py-5">
                <div className="text-center">
                    <h4>Please log in to view your cards</h4>
                    <Link className="btn btn-primary mt-3" to="/customer-login">Login</Link>
                </div>
            </div>
        );
    }

    return (
        <div className="container py-5">
            <div className="d-flex align-items-center justify-content-between mb-4">
                <h3 className="mb-0">My Cards</h3>
                <Link className="btn btn-outline-primary" to="/einvites">Browse Templates</Link>
            </div>

            {loading && (
                <div className="text-center py-5">
                    <div className="spinner-border text-primary" role="status">
                        <span className="visually-hidden">Loading...</span>
                    </div>
                </div>
            )}

            {error && (
                <div className="alert alert-danger" role="alert">
                    {error}
                </div>
            )}

            {!loading && !error && (
                <>
                    <div className="mb-4">
                        <div className="d-flex align-items-center mb-2">
                            <h5 className="mb-0">Drafts</h5>
                            <span className="badge bg-secondary ms-2">{drafts.length}</span>
                        </div>
                        <div className="row">
                            {drafts.length === 0 ? (
                                <div className="col-12 text-muted">No drafts yet.</div>
                            ) : (
                                <DraftsGrid />
                            )}
                        </div>
                    </div>

                    <div className="mb-4">
                        <div className="d-flex align-items-center mb-2">
                            <h5 className="mb-0">Published</h5>
                            <span className="badge bg-success ms-2">{published.length}</span>
                        </div>
                        <div className="row">
                            {published.length === 0 ? (
                                <div className="col-12 text-muted">No published cards yet.</div>
                            ) : (
                                <PublishedGrid />
                            )}
                        </div>
                    </div>
                </>
            )}
        </div>
    );
};

export default OurCards;


