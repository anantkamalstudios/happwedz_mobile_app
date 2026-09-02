import React, { useMemo, useState } from "react";
import { useSelector } from "react-redux";
import { Code2, Copy, Check, LayoutTemplate } from "lucide-react";

export default function ReviewWidget() {
  const { vendor } = useSelector((state) => state.vendorAuth) || {};
  const vendorId = vendor?.id || vendor?.vendorId;
  const [theme, setTheme] = useState("light");
  const [copied, setCopied] = useState(false);

  const widgetSrc = useMemo(() => {
    if (!vendorId) return "";
    return `${window.location.origin}/widget/reviews/${vendorId}?theme=${theme}&limit=3`;
  }, [vendorId, theme]);

  const embedCode = useMemo(() => {
    if (!widgetSrc) return "";
    return `<iframe src="${widgetSrc}" width="100%" height="420" style="border:none;border-radius:12px;" loading="lazy" title="Our Reviews"></iframe>`;
  }, [widgetSrc]);

  const copyEmbed = async () => {
    try {
      await navigator.clipboard.writeText(embedCode);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error("Copy failed:", err);
    }
  };

  if (!vendorId) {
    return (
      <div className="alert alert-warning rounded-3" role="alert">
        Vendor not authenticated.
      </div>
    );
  }

  return (
    <div>
      <div
        className="card border-0 shadow-sm rounded-4 overflow-hidden"
        style={{ backgroundColor: "#ffffff", border: "1px solid #f1f5f9" }}
      >
        <div className="px-4 py-3 border-1">
          <div className="d-flex align-items-center gap-2">
            <Code2 size={20} />
            <h5 className="mb-0 text-black fw-semibold">Review Widget</h5>
          </div>
        </div>

        <div className="card-body p-4">
          <p className="text-muted mb-3" style={{ fontSize: "15px", lineHeight: "1.6" }}>
            Embed your HappyWedz reviews on your own website. Paste the code
            below anywhere in your site's HTML — it always shows your latest
            rating and reviews.
          </p>

          <div className="d-flex align-items-center gap-2 mb-3">
            <LayoutTemplate size={16} className="text-muted" />
            <span className="fs-14 fw-semibold text-dark me-2">Theme:</span>
            <div className="btn-group btn-group-sm" role="group">
              <button
                type="button"
                className={`btn ${theme === "light" ? "btn-primary" : "btn-outline-secondary"}`}
                style={theme === "light" ? { backgroundColor: "#ed1173", borderColor: "#ed1173" } : {}}
                onClick={() => setTheme("light")}
              >
                Light
              </button>
              <button
                type="button"
                className={`btn ${theme === "dark" ? "btn-primary" : "btn-outline-secondary"}`}
                style={theme === "dark" ? { backgroundColor: "#ed1173", borderColor: "#ed1173" } : {}}
                onClick={() => setTheme("dark")}
              >
                Dark
              </button>
            </div>
          </div>

          <label className="form-label fw-semibold text-dark fs-13 mb-2">
            Embed code
          </label>
          <div className="input-group mb-4">
            <textarea
              className="form-control"
              readOnly
              rows={2}
              value={embedCode}
              style={{
                fontSize: "13px",
                fontFamily: "monospace",
                backgroundColor: "#f8fafc",
                color: "#475569",
                border: "1px solid #e2e8f0",
                resize: "none",
              }}
              onFocus={(e) => e.target.select()}
            />
            <button
              type="button"
              className={`btn ${copied ? "btn-success" : "btn-outline-primary border-none"} d-flex align-items-center justify-content-center`}
              style={{ flex: "0 0 auto", width: 44, minWidth: 44, padding: 0 }}
              onClick={copyEmbed}
            >
              {copied ? <Check size={16} /> : <Copy size={16} />}
            </button>
          </div>

          <label className="form-label fw-semibold text-dark fs-13 mb-2">
            Live preview
          </label>
          <div
            style={{
              border: "1px solid #e2e8f0",
              borderRadius: "12px",
              overflow: "hidden",
              maxWidth: 420,
            }}
          >
            <iframe
              src={widgetSrc}
              width="100%"
              height="420"
              style={{ border: "none", display: "block" }}
              loading="lazy"
              title="Review widget preview"
            />
          </div>
        </div>
      </div>
    </div>
  );
}
