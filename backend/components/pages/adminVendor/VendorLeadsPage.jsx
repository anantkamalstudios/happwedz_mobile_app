import React, { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import { useToast } from "../../layouts/toasts/Toast";
import QuotationModal from "./QuotationModal";
import axiosInstance from "../../../services/api/axiosInstance";
import { PiUsersLight } from "react-icons/pi";
import { CiCalendarDate, CiTimer } from "react-icons/ci";
import { IoAnalytics } from "react-icons/io5";

export default function VendorLeadsPage() {
  const [rows, setRows] = useState([]);
  const [exporting, setExporting] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showQuoteModal, setShowQuoteModal] = useState(false);
  const [selectedLead, setSelectedLead] = useState(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [viewMode, setViewMode] = useState("list");
  const { token: vendorToken } = useSelector((state) => state.vendorAuth);
  const { addToast } = useToast();

  useEffect(() => {
    if (!vendorToken) {
      setError("Authentication token not found. Please log in.");
      setLoading(false);
      setRows([]);
      return;
    }

    const params = new URLSearchParams(window.location.search);
    const dateFilterParam = params.get("dateFilter");
    const customStartParam = params.get("customStart");
    const customEndParam = params.get("customEnd");

    const computeRange = () => {
      const now = new Date();
      let start = null;
      let end = null;

      if (dateFilterParam === "this_week") {
        const day = now.getDay();
        const diff = day === 0 ? 6 : day - 1;
        start = new Date(now);
        start.setDate(now.getDate() - diff);
        start.setHours(0, 0, 0, 0);
        end = new Date(now);
        end.setHours(23, 59, 59, 999);
      } else if (dateFilterParam === "this_month") {
        start = new Date(now.getFullYear(), now.getMonth(), 1);
        start.setHours(0, 0, 0, 0);
        end = new Date(now);
        end.setHours(23, 59, 59, 999);
      } else if (dateFilterParam === "last_month") {
        const firstOfThisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const lastMonthEnd = new Date(firstOfThisMonth.getTime() - 1);
        start = new Date(
          lastMonthEnd.getFullYear(),
          lastMonthEnd.getMonth(),
          1
        );
        start.setHours(0, 0, 0, 0);
        end = new Date(
          lastMonthEnd.getFullYear(),
          lastMonthEnd.getMonth(),
          lastMonthEnd.getDate()
        );
        end.setHours(23, 59, 59, 999);
      } else if (
        dateFilterParam === "custom" &&
        customStartParam &&
        customEndParam
      ) {
        start = new Date(customStartParam);
        start.setHours(0, 0, 0, 0);
        end = new Date(customEndParam);
        end.setHours(23, 59, 59, 999);
      }

      return { start, end };
    };

    const getRowDateValue = (row) => {
      return (
        row.createdAt ||
        row.created_at ||
        row.eventDate ||
        row.event_date ||
        row.date ||
        row.addedAt ||
        null
      );
    };

    const fetchLeads = async () => {
      try {
        setLoading(true);
        setError(null);
        const response = await axiosInstance.get(
          "/request-pricing/vendor/dashboard",
          {
            headers: { Authorization: `Bearer ${vendorToken}` },
          }
        );

        const data = response.data || {};
        let items = [];
        if (data && Array.isArray(data.requests)) {
          items = data.requests;
        } else if (data && Array.isArray(data.leads)) {
          items = data.leads;
        } else if (data && Array.isArray(data.data)) {
          items = data.data;
        } else if (data && Array.isArray(data.inbox)) {
          // Handle the inbox array from your API response
          items = data.inbox.map((item) => item.request);
        } else if (Array.isArray(data)) {
          items = data;
        }

        const { start, end } = computeRange();
        if (start && end) {
          const filtered = items.filter((r) => {
            const dVal = getRowDateValue(r);
            if (!dVal) return false;
            const t = new Date(dVal).getTime();
            return t >= start.getTime() && t <= end.getTime();
          });
          setRows(filtered);
        } else {
          setRows(items);
        }
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };
    fetchLeads();
  }, [vendorToken]);

  const filteredRows = rows.filter((row) => {
    const searchLower = searchQuery.toLowerCase();
    return (
      `${row.firstName || ""} ${row.lastName || ""}`
        .toLowerCase()
        .includes(searchLower) ||
      (row.email || "").toLowerCase().includes(searchLower) ||
      (row.phone || "").includes(searchLower)
    );
  });

  const openModal = (row) => {
    const mapped = {
      id: row.id,
      request: {
        id: row.id,
        user: { id: row.userId },
      },
    };
    setSelectedLead(mapped);
    setShowQuoteModal(true);
  };

  const closeQuoteModal = () => {
    setShowQuoteModal(false);
    setSelectedLead(null);
  };

  const exportToCSV = () => {
    if (!rows || rows.length === 0) {
      addToast("No leads to export", "error");
      return;
    }
    setExporting(true);
    try {
      const headers = [
        "firstName",
        "lastName",
        "email",
        "phone",
        "eventDate",
        "message",
      ];
      const csvRows = [headers.join(",")];
      for (const r of rows) {
        const vals = headers.map((h) => {
          const v = r[h] ?? "";
          const s = String(v).replace(/"/g, '""');
          return s.includes(",") || s.includes("\n") ? `"${s}"` : s;
        });
        csvRows.push(vals.join(","));
      }
      const csvString = csvRows.join("\r\n");
      const blob = new Blob([csvString], { type: "text/csv;charset=utf-8;" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      const ts = new Date().toISOString().slice(0, 19).replace(/[:T]/g, "-");
      a.href = url;
      a.download = `leads-${ts}.csv`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
      addToast(`Exported ${rows.length} leads as CSV`, "success");
    } catch (err) {
      console.error("CSV export error:", err);
      addToast(`Export failed: ${err?.message || err}`, "error");
    } finally {
      setExporting(false);
    }
  };

  const exportToExcel = async () => {
    if (!rows || rows.length === 0) {
      addToast("No leads to export", "error");
      return;
    }
    setExporting(true);
    try {
      const XLSX = await import("xlsx");
      const headers = [
        "First Name",
        "Last Name",
        "Email",
        "Phone",
        "Event Date",
        "Message",
      ];
      const data = rows.map((r) => ({
        [headers[0]]: r.firstName || "",
        [headers[1]]: r.lastName || "",
        [headers[2]]: r.email || "",
        [headers[3]]: r.phone || "",
        [headers[4]]: r.eventDate || "",
        [headers[5]]: r.message || "",
      }));
      const ws = XLSX.utils.json_to_sheet(data);
      const wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, ws, "Leads");
      const ts = new Date().toISOString().slice(0, 19).replace(/[:T]/g, "-");
      XLSX.writeFile(wb, `leads-${ts}.xlsx`);
      addToast(`Exported ${rows.length} leads as Excel`, "success");
    } catch (err) {
      console.error("Excel export error:", err);
      addToast(`Excel export failed: ${err?.message || err}`, "error");
    } finally {
      setExporting(false);
    }
  };

  const getInitials = (firstName, lastName) => {
    return `${firstName?.charAt(0) || ""}${
      lastName?.charAt(0) || ""
    }`.toUpperCase();
  };

  const getAvatarColor = (id) => {
    const colors = [
      "#4A90E2",
      "#7B68EE",
      "#FF6B9D",
      "#20C997",
      "#FFA500",
      "#E74C3C",
      "#9B59B6",
      "#3498DB",
    ];
    return colors[id % colors.length];
  };

  return (
    <>
      <style>{`
        .vendor-leads-container {
          padding: 2rem;
          max-width: 1400px;
          margin: 0 auto;
        }

        .stats-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: 1.5rem;
          margin-bottom: 2rem;
        }

        .stat-card {
          background: white;
          border-radius: 12px;
          padding: 1.5rem;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
          border: 1px solid #e9ecef;
        }

        .stat-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          margin-bottom: 0.75rem;
        }

        .stat-label {
          color: #6c757d;
          font-size: 0.875rem;
          font-weight: 500;
        }

        .stat-icon {
          width: 40px;
          height: 40px;
          border-radius: 10px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: #f8f9fa;
        }

        .stat-value {
          font-size: 2rem;
          font-weight: 700;
          color: #212529;
          margin-bottom: 0.25rem;
        }

        .stat-change {
          font-size: 0.875rem;
          color: #6c757d;
        }

        .stat-change.positive {
          color: #28a745;
        }

        .controls-bar {
          background: white;
          border-radius: 12px;
          padding: 1.25rem;
          margin-bottom: 1.5rem;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
          border: 1px solid #e9ecef;
        }

        .controls-row {
          display: flex;
          flex-wrap: wrap;
          gap: 1rem;
          align-items: center;
          justify-content: space-between;
        }

        .controls-left {
          display: flex;
          gap: 0.75rem;
          flex-wrap: wrap;
          align-items: center;
        }

        .controls-right {
          display: flex;
          gap: 0.75rem;
          align-items: center;
        }

        .view-toggle {
          display: flex;
          background: #f8f9fa;
          border-radius: 8px;
          padding: 0.25rem;
        }

        .view-btn {
          border: none;
          background: transparent;
          padding: 0.5rem 0.75rem;
          border-radius: 6px;
          cursor: pointer;
          transition: all 0.2s;
          color: #6c757d;
        }

        .view-btn.active {
          background: white;
          color: #212529;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .search-box {
          position: relative;
          width: 300px;
        }

        .search-input {
          width: 100%;
          padding: 0.625rem 1rem 0.625rem 2.5rem;
          border: 1px solid #dee2e6;
          border-radius: 8px;
          font-size: 0.875rem;
          transition: all 0.2s;
        }

        .search-input:focus {
          outline: none;
          border-color: #0d6efd;
          box-shadow: 0 0 0 3px rgba(13, 110, 253, 0.1);
        }

        .search-icon {
          position: absolute;
          left: 0.875rem;
          top: 50%;
          transform: translateY(-50%);
          color: #6c757d;
          pointer-events: none;
        }

        .export-btn {
          padding: 0.625rem 1.25rem;
          border-radius: 8px;
          font-size: 0.875rem;
          font-weight: 500;
          border: 1px solid;
          cursor: pointer;
          transition: all 0.2s;
          background: white;
        }

        .export-btn:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }

        .export-btn.csv {
          color: #0d6efd;
          border-color: #0d6efd;
        }

        .export-btn.csv:hover:not(:disabled) {
          background: #0d6efd;
          color: white;
        }

        .export-btn.excel {
          color: #198754;
          border-color: #198754;
        }

        .export-btn.excel:hover:not(:disabled) {
          background: #198754;
          color: white;
        }

        .table-container {
          background: white;
          border-radius: 12px;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
          border: 1px solid #e9ecef;
          overflow: hidden;
        }

        .table-responsive {
          overflow-x: auto;
        }

        .custom-table {
          width: 100%;
          border-collapse: collapse;
          font-size: 0.875rem;
        }

        .custom-table thead {
          background: #f8f9fa;
          border-bottom: 1px solid #e9ecef;
        }

        .custom-table th {
          padding: 1rem;
          text-align: left;
          font-weight: 600;
          color: #495057;
          font-size: 0.8125rem;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .custom-table td {
          padding: 1rem;
          border-bottom: 1px solid #f1f3f5;
          vertical-align: middle;
        }

        .custom-table tbody tr {
          transition: background-color 0.2s;
        }

        .custom-table tbody tr:hover {
          background: #f8f9fa;
        }

        .custom-table tbody tr:last-child td {
          border-bottom: none;
        }

        .checkbox-cell {
          width: 40px;
        }

        .custom-checkbox {
          width: 18px;
          height: 18px;
          border: 2px solid #dee2e6;
          border-radius: 4px;
          cursor: pointer;
          accent-color: #0d6efd;
        }

        .user-cell {
          display: flex;
          align-items: center;
          gap: 0.75rem;
        }

        .avatar {
          width: 40px;
          height: 40px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 600;
          font-size: 0.875rem;
          color: white;
          flex-shrink: 0;
        }

        .user-info {
          display: flex;
          flex-direction: column;
        }

        .user-name {
          font-weight: 500;
          color: #212529;
          margin-bottom: 0.125rem;
        }

        .user-email {
          color: #6c757d;
          font-size: 0.8125rem;
        }

        .badge {
          display: inline-block;
          padding: 0.375rem 0.75rem;
          border-radius: 6px;
          font-weight: 500;
          font-size: 0.8125rem;
        }

        .badge.pending {
          background: #fff3cd;
          color: #856404;
        }

        .badge.approved {
          background: #d1e7dd;
          color: #0f5132;
        }

        .badge.declined {
          background: #f8d7da;
          color: #842029;
        }

        .action-btn {
          width: 100%;
          padding: 0.5rem 1rem;
          border-radius: 6px;
          border: none;
          background: #e91e63;
          color: white;
          font-weight: 500;
          font-size: 0.875rem;
          cursor: pointer;
          transition: all 0.2s;
        }

        .action-btn:hover {
          background: #c2185b;
          transform: translateY(-1px);
          box-shadow: 0 2px 4px rgba(233, 30, 99, 0.3);
        }

        .empty-state {
          text-align: center;
          padding: 3rem 1rem;
          color: #6c757d;
        }

        .empty-icon {
          font-size: 3rem;
          margin-bottom: 1rem;
          opacity: 0.5;
        }

        .loading-state {
          text-align: center;
          padding: 3rem 1rem;
        }

        .spinner {
          width: 40px;
          height: 40px;
          border: 4px solid #f3f3f3;
          border-top: 4px solid #0d6efd;
          border-radius: 50%;
          animation: spin 1s linear infinite;
          margin: 0 auto 1rem;
        }

        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }

        @media (max-width: 768px) {
          .vendor-leads-container {
            padding: 1rem;
          }

          .controls-row {
            flex-direction: column;
            align-items: stretch;
          }

          .controls-left,
          .controls-right {
            width: 100%;
            justify-content: space-between;
          }

          .search-box {
            width: 100%;
          }

          .custom-table {
            min-width: 800px;
          }
        }
      `}</style>

      <div className="vendor-leads-container">
        {/* Stats Cards */}
        <div className="stats-grid">
          <div className="stat-card">
            <div className="stat-header">
              <span className="stat-label">Total Leads</span>
              <div className="stat-icon border border-dark-subtle">
                <PiUsersLight size={30} />
              </div>
            </div>
            <div className="stat-value">{rows.length}</div>
            <div className="stat-change positive">Active leads</div>
          </div>

          <div className="stat-card">
            <div className="stat-header">
              <span className="stat-label">Pending</span>
              <div className="stat-icon border border-dark-subtle">
                <CiTimer size={30} />
              </div>
            </div>
            <div className="stat-value">
              {rows.filter((r) => r.status === "pending").length}
            </div>
            <div className="stat-change">Awaiting response</div>
          </div>

          <div className="stat-card">
            <div className="stat-header">
              <span className="stat-label">This Month</span>
              <div className="stat-icon border border-dark-subtle">
                <CiCalendarDate size={30} />
              </div>
            </div>
            <div className="stat-value">{rows.length}</div>
            <div className="stat-change positive">New leads</div>
          </div>

          <div className="stat-card">
            <div className="stat-header">
              <span className="stat-label">Response Rate</span>
              <div className="stat-icon border border-dark-subtle">
                <IoAnalytics size={30} />
              </div>
            </div>
            <div className="stat-value">
              {rows.length > 0
                ? Math.round(
                    (rows.filter((r) => r.status !== "pending").length /
                      rows.length) *
                      100
                  )
                : 0}
              %
            </div>
            <div className="stat-change positive">Replied leads</div>
          </div>
        </div>

        {/* Controls Bar */}
        <div className="controls-bar">
          <div className="controls-row">
            <div className="controls-left">
              <button
                className="export-btn csv"
                onClick={exportToCSV}
                disabled={exporting || rows.length === 0}
              >
                {exporting ? "Exporting..." : "Export CSV"}
              </button>
              <button
                className="export-btn excel"
                onClick={exportToExcel}
                disabled={exporting || rows.length === 0}
              >
                {exporting ? "Exporting..." : "Export Excel"}
              </button>
            </div>

            <div className="controls-right">
              <div className="search-box">
                <svg
                  className="search-icon"
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                >
                  <circle cx="11" cy="11" r="8"></circle>
                  <path d="m21 21-4.35-4.35"></path>
                </svg>
                <input
                  type="text"
                  className="search-input"
                  placeholder="Search leads..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>
            </div>
          </div>
        </div>

        {/* Table */}
        <div className="table-container">
          <div className="table-responsive">
            {loading ? (
              <div className="loading-state">
                <div className="spinner"></div>
                <p>Loading leads...</p>
              </div>
            ) : error ? (
              <div className="empty-state">
                <div className="empty-icon">⚠️</div>
                <h4>Error Loading Leads</h4>
                <p>{error}</p>
              </div>
            ) : filteredRows.length === 0 ? (
              <div className="empty-state">
                <div className="empty-icon">📭</div>
                <h4>No Leads Found</h4>
                <p>You don't have any leads yet. Check back later!</p>
              </div>
            ) : (
              <table className="custom-table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Phone</th>
                    <th>Event Date</th>
                    <th>Status</th>
                    <th>Message</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {filteredRows.map((row) => (
                    <tr key={row.id}>
                      <td>
                        <div className="user-cell">
                          <div
                            className="avatar"
                            style={{ backgroundColor: getAvatarColor(row.id) }}
                          >
                            {getInitials(row.firstName, row.lastName)}
                          </div>
                          <div className="user-info">
                            <div className="user-name">
                              {row.firstName} {row.lastName}
                            </div>
                            <div className="user-email">{row.email}</div>
                          </div>
                        </div>
                      </td>
                      <td>{row.phone}</td>
                      <td>
                        {new Date(row.eventDate).toLocaleDateString("en-US", {
                          year: "numeric",
                          month: "short",
                          day: "numeric",
                        })}
                      </td>
                      <td>
                        <span
                          className={`badge text-black border border-dark-subtle ${
                            row.status || "pending"
                          }`}
                        >
                          {(row.status || "pending").charAt(0).toUpperCase() +
                            (row.status || "pending").slice(1)}
                        </span>
                      </td>
                      <td style={{ maxWidth: "250px" }}>
                        <div
                          style={{
                            overflow: "hidden",
                            textOverflow: "ellipsis",
                            whiteSpace: "nowrap",
                          }}
                        >
                          {row.message}
                        </div>
                      </td>
                      <td>
                        <button
                          className="action-btn"
                          onClick={() => openModal(row)}
                        >
                          Send Quotation
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>

      {selectedLead && (
        <QuotationModal
          show={showQuoteModal}
          onClose={closeQuoteModal}
          lead={selectedLead}
          vendorToken={vendorToken}
        />
      )}
    </>
  );
}
