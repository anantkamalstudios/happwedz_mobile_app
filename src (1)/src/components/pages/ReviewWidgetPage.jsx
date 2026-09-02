import React, { useEffect, useState } from "react";
import { useParams, useSearchParams } from "react-router-dom";
import axiosInstance from "../../services/api/axiosInstance";

const getInitials = (name = "") => {
  if (!name.trim()) return "U";
  const parts = name.trim().split(" ");
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  return name.slice(0, 2).toUpperCase();
};

const getAvatarBg = (name = "") => {
  const colors = ["#ed1173", "#6366f1", "#0ea5e9", "#10b981", "#f59e0b", "#8b5cf6"];
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return colors[Math.abs(hash) % colors.length];
};

const renderStars = (rating, size = 14) => {
  const full = Math.round(rating);
  return (
    <span style={{ whiteSpace: "nowrap" }}>
      {[1, 2, 3, 4, 5].map((star) => (
        <span
          key={star}
          style={{ color: star <= full ? "#f59e0b" : "#e2e8f0", fontSize: size }}
        >
          ★
        </span>
      ))}
    </span>
  );
};

const ReviewWidgetPage = () => {
  const { vendorId } = useParams();
  const [searchParams] = useSearchParams();
  const theme = searchParams.get("theme") === "dark" ? "dark" : "light";
  const limit = Math.max(1, Math.min(10, parseInt(searchParams.get("limit"), 10) || 3));

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [stats, setStats] = useState({ averageRating: 0, totalReviews: 0 });
  const [reviews, setReviews] = useState([]);

  useEffect(() => {
    if (!vendorId) return;
    let cancelled = false;

    (async () => {
      setLoading(true);
      setError(null);
      try {
        const [avgRes, listRes] = await Promise.all([
          axiosInstance.get(`/reviews/vendor/${vendorId}/average`),
          axiosInstance.get(`/reviews/vendor/${vendorId}`),
        ]);

        if (cancelled) return;

        setStats({
          averageRating: parseFloat(avgRes.data?.averageRating) || 0,
          totalReviews: parseInt(avgRes.data?.totalReviews, 10) || 0,
        });

        const mapped = (listRes.data?.reviews || []).map((r) => ({
          id: r.id,
          name: r.user?.name || "Verified Couple",
          rating:
            (r.rating_quality +
              r.rating_responsiveness +
              r.rating_professionalism +
              r.rating_value +
              r.rating_flexibility) /
            5,
          comment: r.comment,
        }));
        setReviews(mapped.slice(0, limit));
      } catch (err) {
        if (!cancelled) setError("Unable to load reviews.");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [vendorId, limit]);

  const isDark = theme === "dark";
  const colors = isDark
    ? { bg: "#0f172a", card: "#1e293b", text: "#f1f5f9", muted: "#94a3b8", border: "#334155" }
    : { bg: "#ffffff", card: "#ffffff", text: "#0f172a", muted: "#64748b", border: "#f1f5f9" };

  return (
    <div
      style={{
        fontFamily:
          "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
        backgroundColor: colors.bg,
        color: colors.text,
        padding: "16px",
        boxSizing: "border-box",
        minHeight: "100vh",
      }}
    >
      {loading ? (
        <div style={{ textAlign: "center", padding: "24px 0", color: colors.muted, fontSize: 14 }}>
          Loading reviews…
        </div>
      ) : error ? (
        <div style={{ textAlign: "center", padding: "24px 0", color: "#ef4444", fontSize: 14 }}>
          {error}
        </div>
      ) : (
        <>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 10,
              paddingBottom: 12,
              marginBottom: 12,
              borderBottom: `1px solid ${colors.border}`,
            }}
          >
            <span style={{ fontSize: 26, fontWeight: 700 }}>
              {stats.averageRating > 0 ? stats.averageRating.toFixed(1) : "0.0"}
            </span>
            <div>
              <div>{renderStars(stats.averageRating, 15)}</div>
              <div style={{ fontSize: 12, color: colors.muted, marginTop: 2 }}>
                {stats.totalReviews} {stats.totalReviews === 1 ? "review" : "reviews"}
              </div>
            </div>
          </div>

          {reviews.length === 0 ? (
            <div style={{ textAlign: "center", padding: "20px 0", color: colors.muted, fontSize: 13 }}>
              No reviews yet.
            </div>
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              {reviews.map((r) => (
                <div
                  key={r.id}
                  style={{
                    backgroundColor: colors.card,
                    border: `1px solid ${colors.border}`,
                    borderRadius: 10,
                    padding: "10px 12px",
                  }}
                >
                  <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
                    <div
                      style={{
                        width: 26,
                        height: 26,
                        borderRadius: "50%",
                        backgroundColor: getAvatarBg(r.name),
                        color: "#fff",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        fontSize: 11,
                        fontWeight: 700,
                        flexShrink: 0,
                      }}
                    >
                      {getInitials(r.name)}
                    </div>
                    <span style={{ fontSize: 13, fontWeight: 600 }}>{r.name}</span>
                    <span style={{ marginLeft: "auto" }}>{renderStars(r.rating, 12)}</span>
                  </div>
                  <p
                    style={{
                      margin: 0,
                      fontSize: 13,
                      lineHeight: 1.5,
                      color: colors.muted,
                      whiteSpace: "pre-wrap",
                      wordBreak: "break-word",
                    }}
                  >
                    {r.comment}
                  </p>
                </div>
              ))}
            </div>
          )}

          <div
            style={{
              textAlign: "center",
              marginTop: 14,
              paddingTop: 10,
              borderTop: `1px solid ${colors.border}`,
              fontSize: 11,
              color: colors.muted,
            }}
          >
            Reviews collected via{" "}
            <a
              href="https://www.happywedz.com"
              target="_blank"
              rel="noopener noreferrer"
              style={{ color: "#ed1173", fontWeight: 600, textDecoration: "none" }}
            >
              HappyWedz
            </a>
          </div>
        </>
      )}
    </div>
  );
};

export default ReviewWidgetPage;
