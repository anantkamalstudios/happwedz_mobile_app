import React, { useState, useEffect, useMemo, useRef } from "react";
import { Alert } from "react-bootstrap";
import {
  Inbox,
  MailOpen,
  Archive,
  Calendar,
  Clock,
  Mail,
  Phone,
  Search,
  Trash2,
  Send,
  Sparkles,
  MessageSquare,
  CheckCircle2,
  XCircle,
} from "lucide-react";
import { useSelector } from "react-redux";
import QuotationModal from "./QuotationModal";
import { useToast } from "../../layouts/toasts/Toast";
import axiosInstance from "../../../services/api/axiosInstance";
import { formatDate } from "../../../utils/dateFormat";
import "./EnquiryManagement.css";

const API_BASE_URL = "https://happywedz.com/api";

const EnquiryManagement = () => {
  const [activeFolder, setActiveFolder] = useState("all");
  const [leads, setLeads] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedLead, setSelectedLead] = useState(null);
  const [error, setError] = useState(null);
  const { token: vendorToken } = useSelector((state) => state.vendorAuth);
  const [counts, setCounts] = useState({ total: 0, unread: 0, archived: 0 });
  const [filter, setFilter] = useState("all");
  const [showQuoteModal, setShowQuoteModal] = useState(false);
  const { addToast } = useToast();
  const [searchMail, setSearchEmail] = useState("");
  const [filteredLeads, setFilteredLeads] = useState([]);
  const [isMobile, setIsMobile] = useState(false);
  const detailRef = useRef(null);

  const [globalStats, setGlobalStats] = useState({
    pending: 0,
    booked: 0,
    declined: 0,
  });

  const fetchInbox = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await axiosInstance.get("/inbox", {
        params: filter !== "all" ? { filter } : undefined,
        headers: { Authorization: `Bearer ${vendorToken}` },
      });

      const data = res.data;
      const fetchedLeads = Array.isArray(data.inbox) ? data.inbox : [];
      setLeads(fetchedLeads);

      setCounts({
        total: data.totalInbox || 0,
        unread: data.unreadCount || 0,
        archived: data.archivedCount || 0,
      });

      if (
        fetchedLeads.length > 0 &&
        (!selectedLead || !fetchedLeads.find((l) => l.id === selectedLead.id))
      ) {
        setSelectedLead(fetchedLeads[0]);
      } else if (fetchedLeads.length === 0) {
        setSelectedLead(null);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const fetchGlobalStats = async () => {
    try {
      const res = await axiosInstance.get("/inbox", {
        headers: { Authorization: `Bearer ${vendorToken}` },
      });
      const data = res.data;
      const allLeads = Array.isArray(data.inbox) ? data.inbox : [];
      setGlobalStats({
        booked: allLeads.filter((l) => l.request?.status === "booked").length,
        declined: allLeads.filter((l) => l.request?.status === "declined").length,
        pending: allLeads.filter((l) => l.request?.status === "pending").length,
      });
    } catch (_) {}
  };

  const handleSearchMail = (e) => {
    const searchValue = e.target.value;
    setSearchEmail(searchValue);

    if (!searchValue.trim()) {
      setFilteredLeads(leads);
      return;
    }

    const filtered = leads.filter(
      (lead) =>
        lead.request?.user?.name
          ?.toLowerCase()
          .includes(searchValue.toLowerCase()) ||
        lead.request?.user?.email
          ?.toLowerCase()
          .includes(searchValue.toLowerCase()) ||
        lead.request?.firstName
          ?.toLowerCase()
          .includes(searchValue.toLowerCase()) ||
        lead.request?.lastName
          ?.toLowerCase()
          .includes(searchValue.toLowerCase()) ||
        lead.request?.service?.name
          ?.toLowerCase()
          .includes(searchValue.toLowerCase())
    );

    setFilteredLeads(filtered);
  };

  useEffect(() => {
    if (vendorToken) {
      fetchInbox();
    }
  }, [vendorToken, filter]);

  useEffect(() => {
    if (vendorToken) {
      fetchGlobalStats();
    }
  }, [vendorToken]);

  useEffect(() => {
    setFilteredLeads(leads);
  }, [leads]);

  useEffect(() => {
    const mq = window.matchMedia("(max-width: 992px)");
    const update = () => setIsMobile(!!mq.matches);
    update();
    if (mq.addEventListener) {
      mq.addEventListener("change", update);
      return () => mq.removeEventListener("change", update);
    } else if (mq.addListener) {
      mq.addListener(update);
      return () => mq.removeListener(update);
    }
  }, []);

  const handleAction = async (lead, action) => {
    const inboxId = lead.id;
    const requestId = lead.request?.id;

    const isArchiveAction = action === "archive" || action === "unarchive";
    const isReadAction = action === "read";
    const isStatusAction = ["pending", "booked", "declined"].includes(action);

    try {
      const headers = { Authorization: `Bearer ${vendorToken}` };
      let url;
      let body = undefined;

      if (isStatusAction) {
        if (!requestId) {
          throw new Error("Cannot update status without a request ID.");
        }
        url = `${API_BASE_URL}/inbox/request/${requestId}/status`;
        headers["Content-Type"] = "application/json";
        body = { newStatus: action };
      } else if (isArchiveAction) {
        url = `${API_BASE_URL}/inbox/${inboxId}/archive`;
      } else {
        url = `${API_BASE_URL}/inbox/${inboxId}/${action}`;
      }
      await axiosInstance.patch(
        url.replace(API_BASE_URL, ""),
        body,
        { headers }
      );

      setLeads((prevLeads) =>
        prevLeads.map((l) => {
          if (l.id !== inboxId) return l;
          const updatedLead = { ...l };
          if (isReadAction) updatedLead.isRead = true;
          if (isArchiveAction) updatedLead.isArchived = action === "archive";
          if (isStatusAction) {
            updatedLead.request = { ...updatedLead.request, status: action };
          }
          return updatedLead;
        })
      );

      setSelectedLead((prev) => {
        if (!prev || prev.id !== inboxId) return prev;
        const next = { ...prev };
        if (isReadAction) next.isRead = true;
        if (isArchiveAction) next.isArchived = action === "archive";
        if (isStatusAction) {
          next.request = { ...next.request, status: action };
        }
        return next;
      });

      if (
        isArchiveAction &&
        selectedLead?.id === inboxId &&
        filter !== "archived"
      ) {
        setSelectedLead(null);
      }

      if (
        isStatusAction &&
        selectedLead?.id === inboxId &&
        filter !== "all" &&
        filter !== action
      ) {
        setSelectedLead(null);
      }

      fetchInbox();
      fetchGlobalStats();
    } catch (err) {
      console.error(`Error on action '${action}':`, err);
      setError(err.message);
    }
  };

  const handleDeleteEmail = async (id) => {
    try {
      await axiosInstance.delete(`${API_BASE_URL}/inbox/${id}`, {
        headers: { Authorization: `Bearer ${vendorToken}` },
      });
      fetchInbox();
      fetchGlobalStats();
    } catch (e) {
      console.log(e);
    }
  };

  const handleLeadClick = (lead) => {
    setSelectedLead(lead);
    if (!lead.isRead) {
      handleAction(lead, "read");
    }
    if (isMobile && detailRef.current) {
      setTimeout(() => {
        detailRef.current.scrollIntoView({
          behavior: "smooth",
          block: "start",
        });
      }, 50);
    }
  };

  const folders = useMemo(
    () => [
      {
        id: "all",
        name: "All Enquiries",
        count: counts.total,
        icon: <Inbox size={16} />,
      },
      {
        id: "unread",
        name: "Unread",
        count: counts.unread,
        icon: <MailOpen size={16} />,
      },
      {
        id: "archived",
        name: "Archived",
        count: counts.archived,
        icon: <Archive size={16} />,
      },
    ],
    [counts]
  );

  const statuses = useMemo(
    () => [
      { id: "pending", name: "Pending" },
      { id: "booked", name: "Booked" },
      { id: "declined", name: "Declined" },
    ],
    []
  );

  return (
    <div className="enquiry-dashboard py-3 py-md-4 px-2 px-md-4">
      <div className="container-fluid">
        {/* Header */}
        <div className="row mb-3">
          <div className="col-12">
            <h4 className="mb-1 fw-bold text-dark">Enquiry Management</h4>
            <p className="text-muted mb-0 fs-14">
              Track and respond to client inquiries and bookings seamlessly.
            </p>
          </div>
        </div>

        {/* Stats Summary Cards - Unified HappyWedz Theme */}
        <div className="row mb-4 g-3">
          <div className="col-12 col-md-4">
            <div className="enquiry-stat-card">
              <div className="d-flex justify-content-between align-items-center">
                <div>
                  <p className="text-muted mb-1 fs-13 fw-semibold">Pending Enquiries</p>
                  <h3 className="mb-0 fw-bold text-dark">{globalStats.pending}</h3>
                </div>
                <div className="enquiry-stat-icon">
                  <Clock size={20} />
                </div>
              </div>
              <div className="mt-2 text-muted fs-12 d-flex align-items-center gap-1">
                <span className="fw-semibold" style={{ color: "#ed1173" }}>●</span>
                <span>Requires response</span>
              </div>
            </div>
          </div>

          <div className="col-12 col-md-4">
            <div className="enquiry-stat-card">
              <div className="d-flex justify-content-between align-items-center">
                <div>
                  <p className="text-muted mb-1 fs-13 fw-semibold">Confirmed Bookings</p>
                  <h3 className="mb-0 fw-bold text-dark">{globalStats.booked}</h3>
                </div>
                <div className="enquiry-stat-icon">
                  <Calendar size={20} />
                </div>
              </div>
              <div className="mt-2 text-muted fs-12 d-flex align-items-center gap-1">
                <span className="fw-semibold" style={{ color: "#ed1173" }}>●</span>
                <span>Successfully booked</span>
              </div>
            </div>
          </div>

          <div className="col-12 col-md-4">
            <div className="enquiry-stat-card">
              <div className="d-flex justify-content-between align-items-center">
                <div>
                  <p className="text-muted mb-1 fs-13 fw-semibold">Declined / Closed</p>
                  <h3 className="mb-0 fw-bold text-dark">{globalStats.declined}</h3>
                </div>
                <div className="enquiry-stat-icon">
                  <Archive size={20} />
                </div>
              </div>
              <div className="mt-2 text-muted fs-12 d-flex align-items-center gap-1">
                <span className="fw-semibold" style={{ color: "#ed1173" }}>●</span>
                <span>Not available / closed</span>
              </div>
            </div>
          </div>
        </div>

        {/* 3-Column Unified Inbox Container */}
        <div className="enquiry-inbox-container">
          {/* Column 1: Sidebar Navigation */}
          <div className="enquiry-sidebar">
            <div>
              <div className="enquiry-nav-heading">Folders</div>
              {folders.map((folder) => (
                <div
                  key={folder.id}
                  className={`enquiry-nav-item ${filter === folder.id ? "active" : ""}`}
                  onClick={() => setFilter(folder.id)}
                >
                  <span>{folder.icon}</span>
                  <span>{folder.name}</span>
                  <span className="enquiry-nav-badge">{folder.count}</span>
                </div>
              ))}

              <div className="enquiry-nav-heading mt-4">Status Filters</div>
              {statuses.map((status) => (
                <div
                  key={status.id}
                  className={`enquiry-nav-item ${filter === status.id ? "active" : ""}`}
                  onClick={() => setFilter(status.id)}
                >
                  <span className="enquiry-status-dot"></span>
                  <span>{status.name}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Column 2: Lead List Pane */}
          <div className="enquiry-list-pane">
            <div className="enquiry-list-header">
              <div className="d-flex justify-content-between align-items-center">
                <h6 className="mb-0 fw-bold text-dark fs-15">
                  {folders.find((f) => f.id === filter)?.name ||
                    statuses.find((s) => s.id === filter)?.name ||
                    "All Enquiries"}
                </h6>
                <span className="badge bg-light text-muted border">
                  {filteredLeads.length} items
                </span>
              </div>

              {/* Search Bar */}
              <div className="enquiry-search-wrap">
                <Search size={15} className="enquiry-search-icon" />
                <input
                  type="text"
                  className="enquiry-search-input"
                  placeholder="Search inquiries..."
                  value={searchMail}
                  onChange={handleSearchMail}
                />
              </div>
            </div>

            {/* Scrollable Leads List */}
            <div className="enquiry-cards-scroll">
              {loading ? (
                <div className="text-center py-5">
                  <div className="spinner-border" style={{ color: "#ed1173" }} role="status">
                    <span className="visually-hidden">Loading...</span>
                  </div>
                </div>
              ) : error ? (
                <Alert variant="danger" className="fs-13 m-2">
                  {error}
                </Alert>
              ) : filteredLeads.length === 0 ? (
                <div className="text-center py-5 px-3">
                  <Inbox className="text-muted mb-2" size={36} />
                  <p className="fw-semibold mb-1 text-dark fs-14">No Enquiries Found</p>
                  <p className="text-muted fs-12 mb-0">No messages in this view.</p>
                </div>
              ) : (
                filteredLeads.map((lead) => {
                  const statusKey = lead.request?.status || "pending";
                  const fullName = `${lead.request?.firstName || ""} ${lead.request?.lastName || ""}`.trim() || "Client Inquiry";
                  const avatarInitial = fullName.charAt(0).toUpperCase() || "C";
                  const avatarUrl =
                    lead.request?.user?.profileImage ||
                    lead.request?.user?.avatar ||
                    lead.request?.user?.image ||
                    lead.request?.user?.logo ||
                    null;
                  const isSelected = selectedLead?.id === lead.id;

                  return (
                    <div
                      key={lead.id}
                      className={`enquiry-lead-card ${isSelected ? "selected" : ""}`}
                      onClick={() => handleLeadClick(lead)}
                    >
                      <div className="d-flex align-items-start gap-2 mb-1">
                        {avatarUrl ? (
                          <img
                            src={avatarUrl}
                            alt={fullName}
                            className="enquiry-avatar"
                            onError={(e) => {
                              e.currentTarget.style.display = "none";
                              if (e.currentTarget.nextSibling) {
                                e.currentTarget.nextSibling.style.display = "flex";
                              }
                            }}
                          />
                        ) : null}
                        <div
                          className="enquiry-avatar"
                          style={{ display: avatarUrl ? "none" : "flex" }}
                        >
                          {avatarInitial}
                        </div>
                        <div className="flex-grow-1 min-w-0">
                          <div className="d-flex align-items-center justify-content-between gap-1">
                            <h6 className="enquiry-lead-name">{fullName}</h6>
                            {!lead.isRead && (
                              <span className="enquiry-badge new">New</span>
                            )}
                          </div>
                          <p className="enquiry-lead-email">
                            {lead.request?.user?.email || "No email provided"}
                          </p>
                        </div>
                      </div>

                      <p className="enquiry-lead-preview">
                        {lead.request?.message || "Quick inquiry submitted from listing page."}
                      </p>

                      <div className="d-flex justify-content-between align-items-center pt-2 border-top" style={{ borderColor: "#f1f5f9" }}>
                        <span className="enquiry-badge">
                          {statusKey.charAt(0).toUpperCase() + statusKey.slice(1)}
                        </span>
                        <span className="text-muted fs-12 d-flex align-items-center gap-1">
                          <Calendar size={12} className="text-muted" />
                          {formatDate(lead.request?.eventDate)}
                        </span>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>

          {/* Column 3: Lead Detail Pane */}
          <div className="enquiry-detail-pane" ref={detailRef}>
            {selectedLead ? (
              <>
                {/* Customer Profile Header */}
                <div className="enquiry-detail-header-wrap">
                  <div className="d-flex align-items-center gap-3 flex-grow-1 min-w-0">
                    {(() => {
                      const detailName = `${selectedLead.request?.firstName || ""} ${selectedLead.request?.lastName || ""}`.trim() || "Client Inquiry";
                      const detailInitial = (detailName.charAt(0) || "C").toUpperCase();
                      const detailImg =
                        selectedLead.request?.user?.profileImage ||
                        selectedLead.request?.user?.avatar ||
                        selectedLead.request?.user?.image ||
                        selectedLead.request?.user?.logo ||
                        null;

                      return (
                        <div className="flex-shrink-0">
                          {detailImg ? (
                            <img
                              src={detailImg}
                              alt={detailName}
                              className="enquiry-detail-avatar"
                              onError={(e) => {
                                e.currentTarget.style.display = "none";
                                if (e.currentTarget.nextSibling) {
                                  e.currentTarget.nextSibling.style.display = "flex";
                                }
                              }}
                            />
                          ) : null}
                          <div
                            className="enquiry-detail-avatar"
                            style={{ display: detailImg ? "none" : "flex" }}
                          >
                            {detailInitial}
                          </div>
                        </div>
                      );
                    })()}
                    <div className="min-w-0">
                      <h5 className="mb-1 fw-bold text-dark text-truncate">
                        {`${selectedLead.request?.firstName || ""} ${selectedLead.request?.lastName || ""}`.trim() || "Client Inquiry"}
                      </h5>
                      <div className="d-flex flex-wrap gap-2 mt-1">
                        {selectedLead.request?.user?.email && (
                          <a
                            href={`mailto:${selectedLead.request.user.email}`}
                            className="enquiry-contact-chip"
                          >
                            <Mail size={13} className="text-muted" />
                            <span className="text-truncate">{selectedLead.request.user.email}</span>
                          </a>
                        )}
                        {selectedLead.request?.user?.phone && (
                          <a
                            href={`tel:${selectedLead.request.user.phone}`}
                            className="enquiry-contact-chip"
                          >
                            <Phone size={13} className="text-muted" />
                            <span>{selectedLead.request.user.phone}</span>
                          </a>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="d-flex align-items-center gap-2 flex-shrink-0">
                    <button
                      className="btn btn-outline-secondary btn-sm fs-13 d-flex align-items-center gap-1"
                      onClick={() =>
                        handleAction(
                          selectedLead,
                          selectedLead.isArchived ? "unarchive" : "archive"
                        )
                      }
                    >
                      <Archive size={14} />
                      <span>{selectedLead.isArchived ? "Unarchive" : "Archive"}</span>
                    </button>
                    <button
                      className="btn btn-outline-secondary btn-sm fs-13 d-flex align-items-center gap-1"
                      onClick={() => handleDeleteEmail(selectedLead.id)}
                    >
                      <Trash2 size={14} />
                      <span>Delete</span>
                    </button>
                  </div>
                </div>

                {/* Event Details 3-Tile Row */}
                <div className="row g-3 mb-4">
                  <div className="col-12 col-sm-4">
                    <div className="enquiry-info-tile">
                      <div className="enquiry-info-tile-label">
                        <Calendar size={13} style={{ color: "#ed1173" }} />
                        <span>Event Date</span>
                      </div>
                      <p className="enquiry-info-tile-val">
                        {formatDate(selectedLead.request?.eventDate)}
                      </p>
                    </div>
                  </div>

                  <div className="col-12 col-sm-4">
                    <div className="enquiry-info-tile">
                      <div className="enquiry-info-tile-label">
                        <Clock size={13} style={{ color: "#ed1173" }} />
                        <span>Received On</span>
                      </div>
                      <p className="enquiry-info-tile-val">
                        {formatDate(selectedLead.createdAt)}
                      </p>
                    </div>
                  </div>

                  <div className="col-12 col-sm-4">
                    <div className="enquiry-info-tile">
                      <div className="enquiry-info-tile-label">
                        <Sparkles size={13} style={{ color: "#ed1173" }} />
                        <span>Status</span>
                      </div>
                      <div className="mt-1">
                        <span className="enquiry-badge">
                          {(selectedLead.request?.status || "pending").toUpperCase()}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Message Box */}
                <div className="mb-4">
                  <h6 className="fw-bold text-dark mb-2 fs-14">Inquiry Message</h6>
                  <div className="enquiry-message-card">
                    <p className="mb-0 fs-14 text-dark" style={{ lineHeight: "1.6" }}>
                      {selectedLead.request?.message || "No message provided."}
                    </p>
                  </div>
                </div>

                {/* Update Status Buttons */}
                <div className="mb-4">
                  <h6 className="fw-bold text-dark mb-2 fs-14">Update Lead Status</h6>
                  <div className="enquiry-status-btn-group">
                    {statuses.map((status) => {
                      const isActive = selectedLead.request?.status === status.id;
                      return (
                        <button
                          key={status.id}
                          type="button"
                          className={`enquiry-status-btn ${isActive ? "active" : ""}`}
                          onClick={() => handleAction(selectedLead, status.id)}
                        >
                          {status.name}
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* Reply / Send Quotation Action */}
                <div className="mt-auto pt-2">
                  <button
                    className="enquiry-reply-btn"
                    onClick={() => {
                      if (selectedLead) setShowQuoteModal(true);
                      else addToast("Please select a lead to reply to.", "warning");
                    }}
                  >
                    <Send size={16} />
                    <span>Send Quotation & Reply</span>
                  </button>
                </div>
              </>
            ) : (
              !loading && (
                <div className="h-100 d-flex flex-column align-items-center justify-content-center text-center p-4">
                  <MailOpen size={48} className="text-muted mb-3" />
                  <h6 className="fw-bold text-dark mb-1">Select an Enquiry</h6>
                  <p className="text-muted fs-13">
                    Choose a lead from the list to view its details and respond.
                  </p>
                </div>
              )
            )}
          </div>
        </div>
      </div>

      {selectedLead && (
        <QuotationModal
          show={showQuoteModal}
          onClose={() => setShowQuoteModal(false)}
          lead={selectedLead}
          vendorToken={vendorToken}
        />
      )}
    </div>
  );
};

export default EnquiryManagement;
