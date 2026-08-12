import React, { useState, useEffect, useMemo, useRef } from "react";
import { Alert } from "react-bootstrap";
import {
  Inbox,
  MailOpen,
  Archive,
  Calendar,
  Clock,
  MessageCircleReply,
  Settings,
  FileText,
  Crown,
  Download,
  Search,
  User,
  Mail,
  Phone,
  ChevronRight,
  TrendingUp,
  BarChart3,
  SearchIcon,
} from "lucide-react";

import { useSelector } from "react-redux";
import QuotationModal from "./QuotationModal";
import { useToast } from "../../layouts/toasts/Toast";
import axiosInstance from "../../../services/api/axiosInstance";

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
  const [dateFromText, setDateFromText] = useState("");
  const [dateToText, setDateToText] = useState("");
  const [isMobile, setIsMobile] = useState(false);
  const detailRef = useRef(null);

  const [globalStats, setGlobalStats] = useState({
    pending: 0,
    booked: 0,
    declined: 0,
  });
  const [stats, setStats] = useState({ pending: 0, booked: 0, declined: 0 });

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

      setStats({
        booked: fetchedLeads.filter((l) => l.request?.status === "booked")
          .length,
        declined: fetchedLeads.filter((l) => l.request?.status === "declined")
          .length,
        pending: fetchedLeads.filter((l) => l.request?.status === "pending")
          .length,
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
        declined: allLeads.filter((l) => l.request?.status === "declined")
          .length,
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
    const mq = window.matchMedia("(max-width: 576px)");
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

  const parseDMY = (s) => {
    if (!s) return null;
    const m = s.match(/^(\d{1,2})-(\d{1,2})-(\d{4})$/);
    if (!m) return null;
    const d = parseInt(m[1], 10);
    const mo = parseInt(m[2], 10) - 1;
    const y = parseInt(m[3], 10);
    const dt = new Date(y, mo, d);
    return Number.isNaN(dt.getTime()) ? null : dt;
  };

  // Recompute filteredLeads when search or date range changes
  useEffect(() => {
    let base = leads;
    const s = (searchMail || "").toLowerCase().trim();
    if (s) {
      base = base.filter(
        (lead) =>
          lead.request?.user?.name?.toLowerCase().includes(s) ||
          lead.request?.user?.email?.toLowerCase().includes(s) ||
          lead.request?.service?.name?.toLowerCase().includes(s)
      );
    }

    const from = parseDMY(dateFromText);
    const to = parseDMY(dateToText);
    if (from || to) {
      base = base.filter((lead) => {
        const ev = lead.request?.eventDate
          ? new Date(lead.request.eventDate)
          : null;
        if (!ev || Number.isNaN(ev.getTime())) return false;
        if (from && ev < from) return false;
        if (to) {
          // include the entire 'to' day
          const toEnd = new Date(
            to.getFullYear(),
            to.getMonth(),
            to.getDate(),
            23,
            59,
            59,
            999
          );
          if (ev > toEnd) return false;
        }
        return true;
      });
    }
    setFilteredLeads(base);
  }, [leads, searchMail, dateFromText, dateToText]);

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
          console.error("No request ID found for this lead:", lead);
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
      const res = await axiosInstance.patch(
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
    } catch (err) {
      console.error(`Error on action '${action}':`, err);
      setError(err.message);
    }
  };

  const handleDeleteEmail = async (id) => {
    try {
      await axiosInstance.delete(`${API_BASE_URL}/inbox/${id}`, {
        headers: { Authorization: `Bearer ${vendorToken} ` },
      });
      fetchInbox();
    } catch (e) {
      console.log(e);
    }
  };

  const handleLeadClick = (lead) => {
    setSelectedLead(lead);
    if (!lead.isRead) {
      handleAction(lead, "read");
    }
    // On mobile, scroll to detail section
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
        icon: <Inbox size={18} />,
      },
      {
        id: "unread",
        name: "Unread",
        count: counts.unread,
        icon: <MailOpen size={18} />,
      },
      {
        id: "archived",
        name: "Archived",
        count: counts.archived,
        icon: <Archive size={18} />,
      },
    ],
    [counts]
  );

  const statuses = useMemo(
    () => [
      { id: "pending", name: "Pending", color: "#f39c12" },
      { id: "booked", name: "Booked", color: "#27ae60" },
      { id: "declined", name: "Declined", color: "#e74c3c" },
    ],
    []
  );

  return (
    <div
      style={{ background: "#f8f9fa", minHeight: "100vh" }}
      className="py-3 py-md-4 px-2 px-md-4"
    >
      <div className="container-fluid">
        {/* Header */}
        <div className="row mb-3 mb-md-4">
          <div className="col-12">
            <h3 className="mb-1 fw-bold">Enquiry Management</h3>
            <p className="text-muted mb-0 fs-14">
              Manage your wedding enquiries efficiently
            </p>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="row mb-3 mb-md-4 g-2 g-md-3">
          <div className="col-12 col-sm-6 col-lg-4">
            <div className="card border-0 shadow-sm rounded-3">
              <div className="card-body p-3">
                <div className="d-flex justify-content-between align-items-start">
                  <div>
                    <p className="mb-1 fs-16 fw-bold">Pending</p>
                    <h4 className="mb-0 fw-bold">{globalStats.pending}</h4>
                  </div>
                  <div className="bg-warning bg-opacity-10 p-2 rounded">
                    <MessageCircleReply size={20} className="text-warning" />
                  </div>
                </div>
                <div className="mt-2">
                  <small className="text-muted fs-12 d-flex align-items-center gap-1">
                    <TrendingUp size={12} /> This month
                  </small>
                </div>
              </div>
            </div>
          </div>

          <div className="col-12 col-sm-6 col-lg-4">
            <div className="card border-0 shadow-sm rounded-3">
              <div className="card-body p-3">
                <div className="d-flex justify-content-between align-items-start">
                  <div>
                    <p className="mb-1 fs-12 fs-16 fw-bold">Booked</p>
                    <h4 className="mb-0 fw-bold">{globalStats.booked}</h4>
                  </div>
                  <div className="bg-success bg-opacity-10 p-2 rounded">
                    <Calendar size={20} className="text-success" />
                  </div>
                </div>
                <div className="mt-2">
                  <small className="text-muted fs-12 d-flex align-items-center gap-1">
                    <TrendingUp size={12} /> This month
                  </small>
                </div>
              </div>
            </div>
          </div>

          <div className="col-12 col-sm-6 col-lg-4">
            <div className="card border-0 shadow-sm rounded-3">
              <div className="card-body p-3">
                <div className="d-flex justify-content-between align-items-start">
                  <div>
                    <p className="mb-1 fs-12 fs-16 fw-bold">Declined</p>
                    <h4 className="mb-0 fw-bold">{globalStats.declined}</h4>
                  </div>
                  <div className="bg-danger bg-opacity-10 p-2 rounded">
                    <Archive size={20} className="text-danger" />
                  </div>
                </div>
                <div className="mt-2">
                  <small className="text-muted fs-12 d-flex align-items-center gap-1">
                    <TrendingUp size={12} /> This month
                  </small>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="row">
          <div className="col-12">
            <div className="card border-0 shadow-sm rounded-3">
              <div className="row g-0">
                {/* Sidebar */}
                <div
                  className="col-12 col-md-3 col-lg-2 border-end"
                  style={{ background: "#fafafa" }}
                >
                  <div className="p-3">
                    {/* Folders */}
                    <div className="mb-4">
                      <h6
                        className="text-uppercase text-muted fw-semibold mb-3 fs-10"
                        style={{ letterSpacing: "0.5px" }}
                      >
                        Folders
                      </h6>
                      {folders.map((folder) => (
                        <div
                          key={folder.id}
                          className={`d-flex align-items-center p-2 mb-2 rounded-2 ${
                            filter === folder.id ? "bg-white shadow-sm" : ""
                          }`}
                          role="button"
                          onClick={() => setFilter(folder.id)}
                          style={{
                            transition: "all 0.2s ease",
                          }}
                        >
                          <span className="me-2 text-muted">{folder.icon}</span>
                          <span className="flex-grow-1 fs-14 fw-medium">
                            {folder.name}
                          </span>
                          <span className="badge bg-light text-dark rounded-pill fs-12">
                            {folder.count}
                          </span>
                        </div>
                      ))}
                    </div>

                    {/* Status Filters */}
                    <div className="mb-3">
                      <h6
                        className="text-uppercase text-muted fw-semibold mb-3 fs-10"
                        style={{ letterSpacing: "0.5px" }}
                      >
                        Status
                      </h6>
                      {statuses.map((status) => (
                        <div
                          key={status.id}
                          className={`d-flex align-items-center p-2 mb-2 rounded-2 ${
                            filter === status.id ? "bg-white shadow-sm" : ""
                          }`}
                          role="button"
                          onClick={() => setFilter(status.id)}
                          style={{
                            transition: "all 0.2s ease",
                          }}
                        >
                          <span
                            style={{
                              width: "8px",
                              height: "8px",
                              borderRadius: "50%",
                              backgroundColor: status.color,
                              marginRight: "10px",
                            }}
                          ></span>
                          <span className="flex-grow-1 fs-14">
                            {status.name}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>

                {/* Leads List */}
                <div
                  className="col-12 col-md-4 col-lg-4 border-end"
                  style={{ background: "#ffffff" }}
                >
                  <div className="p-3">
                    <div className="d-flex justify-content-between align-items-center mb-3">
                      <h5 className="mb-0 fw-semibold fs-16">
                        {folders.find((f) => f.id === filter)?.name ||
                          statuses.find((s) => s.id === filter)?.name ||
                          "Enquiries"}
                      </h5>
                    </div>

                    {/* Search Bar */}
                    <div className="mb-3">
                      <div className="input-group">
                        <span className="input-group-text bg-white border-end-0">
                          <SearchIcon size={16} className="text-muted" />
                        </span>
                        <input
                          type="text"
                          className="form-control border-start-0 fs-14"
                          placeholder="Search enquiries..."
                          value={searchMail}
                          onChange={handleSearchMail}
                        />
                      </div>
                    </div>

                    {/* Date Range Filters */}
                    {/* <div className="row g-2 mb-2">
                      <div className="col-6">
                        <input
                          type={isMobile ? "text" : "date"}
                          className="form-control form-control-sm fs-14"
                          placeholder={isMobile ? "dd-mm-yyyy" : "From"}
                          inputMode={isMobile ? "numeric" : undefined}
                          pattern={isMobile ? "^(0?[1-9]|[12][0-9]|3[01])-(0?[1-9]|1[012])-(\\d{4})$" : undefined}
                          maxLength={isMobile ? 10 : undefined}
                          value={dateFromText}
                          onChange={(e) => setDateFromText(e.target.value)}
                          aria-label="From date"
                        />
                      </div>
                      <div className="col-6">
                        <input
                          type={isMobile ? "text" : "date"}
                          className="form-control form-control-sm fs-14"
                          placeholder={isMobile ? "dd-mm-yyyy" : "To"}
                          inputMode={isMobile ? "numeric" : undefined}
                          pattern={isMobile ? "^(0?[1-9]|[12][0-9]|3[01])-(0?[1-9]|1[012])-(\\d{4})$" : undefined}
                          maxLength={isMobile ? 10 : undefined}
                          value={dateToText}
                          onChange={(e) => setDateToText(e.target.value)}
                          aria-label="To date"
                        />
                      </div>
                    </div> */}

                    {loading ? (
                      <div className="text-center py-5">
                        <div
                          className="spinner-border text-primary"
                          role="status"
                        >
                          <span className="visually-hidden">Loading...</span>
                        </div>
                      </div>
                    ) : error ? (
                      <Alert variant="danger" className="fs-14">
                        {error}
                      </Alert>
                    ) : filteredLeads.length === 0 ? (
                      <div className="text-center py-5">
                        <Inbox className="text-muted mb-3" size={40} />
                        <div className="fw-semibold mb-1 fs-16">
                          No messages found
                        </div>
                        <div className="text-muted fs-14">
                          No messages in this folder.
                        </div>
                      </div>
                    ) : (
                      <div
                        style={{
                          maxHeight: "calc(100vh - 300px)",
                          overflowY: "auto",
                        }}
                      >
                        {filteredLeads.map((lead) => {
                          const statusObj = statuses.find(
                            (s) => s.id === lead.request?.status
                          );
                          return (
                            <div
                              key={lead.id}
                              className={`card mb-2 border ${
                                selectedLead?.id === lead.id
                                  ? "border-primary"
                                  : "border-light"
                              }`}
                              role="button"
                              onClick={() => handleLeadClick(lead)}
                              style={{
                                borderLeft: `3px solid ${
                                  statusObj?.color || "#95a5a6"
                                }`,
                                background:
                                  selectedLead?.id === lead.id
                                    ? "#f8f9fa"
                                    : "#fff",
                                transition: "all 0.2s ease",
                              }}
                            >
                              <div className="card-body p-3">
                                <div className="d-flex align-items-start justify-content-between mb-2">
                                  <div className="d-flex align-items-center gap-2">
                                    <div
                                      className="bg-white text-black rounded-circle border border-dark d-flex align-items-center justify-content-center fw-semibold shadow-lg"
                                      style={{
                                        width: "32px",
                                        height: "32px",
                                        fontSize: "14px",
                                      }}
                                    >
                                      {lead.request?.firstName?.charAt(0) ||
                                        "?"}
                                    </div>
                                    <div>
                                      <h6
                                        className={`mb-0 fs-14 ${
                                          !lead.isRead ? "fw-bold" : "fw-medium"
                                        }`}
                                      >
                                        {`${lead.request?.firstName || ""} ${
                                          lead.request?.lastName || ""
                                        }`.trim() || "No Name"}
                                      </h6>
                                      <p className="mb-0 text-muted fs-12">
                                        {lead.request?.user?.email}
                                      </p>
                                    </div>
                                  </div>
                                  {!lead.isRead && (
                                    <span className="badge bg-primary fs-10">
                                      New
                                    </span>
                                  )}
                                </div>

                                <p
                                  className="mb-2 text-muted fs-14"
                                  style={{
                                    overflow: "hidden",
                                    textOverflow: "ellipsis",
                                    display: "-webkit-box",
                                    WebkitLineClamp: 2,
                                    WebkitBoxOrient: "vertical",
                                  }}
                                >
                                  {lead.request?.message || "No message"}
                                </p>

                                <div className="d-flex justify-content-between align-items-center">
                                  <span
                                    className="badge rounded-pill fs-10"
                                    style={{
                                      backgroundColor: `${statusObj?.color}20`,
                                      color: statusObj?.color,
                                    }}
                                  >
                                    {statusObj?.name}
                                  </span>
                                  <div className="text-muted fs-12 d-flex align-items-center gap-1">
                                    <Calendar size={12} />
                                    {new Date(
                                      lead.request?.eventDate
                                    ).toLocaleDateString("en-IN", {
                                      month: "short",
                                      day: "numeric",
                                    })}
                                  </div>
                                </div>
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                </div>

                {/* Lead Detail */}
                <div className="col-12 col-md-5 col-lg-6" ref={detailRef}>
                  <div className="p-3 p-md-4 h-100">
                    {selectedLead ? (
                      <>
                        {/* Header Section */}
                        <div className="mb-4">
                          <div className="d-flex align-items-start gap-3 mb-3 flex-wrap">
                            <div
                              className="bg-white text-black rounded-circle border border-dark d-flex align-items-center justify-content-center fw-semibold shadow-sm"
                              style={{
                                width: "48px",
                                height: "48px",
                                fontSize: "20px",
                              }}
                            >
                              {selectedLead.request?.user?.name?.charAt(0) ||
                                "?"}
                            </div>

                            <div className="flex-grow-1">
                              <h5 className="mb-1 fw-bold fs-16">
                                {/* {selectedLead.request?.user?.name} */}
                                {`${selectedLead.request?.firstName || ""} ${
                                  selectedLead.request?.lastName || ""
                                }`.trim() || "No Name"}
                              </h5>
                              <div className="d-flex flex-column gap-1">
                                <div className="d-flex align-items-center gap-2 fs-14">
                                  <Mail size={14} className="text-muted" />
                                  <a
                                    href={`mailto:${selectedLead.request?.user?.email}`}
                                    className="text-decoration-none text-muted"
                                  >
                                    {selectedLead.request?.user?.email}
                                  </a>
                                </div>
                                <div className="d-flex align-items-center gap-2 fs-14 text-muted">
                                  <Phone size={14} />
                                  <span>
                                    {selectedLead.request?.user?.phone}
                                  </span>
                                </div>
                              </div>
                            </div>

                            <div className="d-flex gap-2 flex-wrap">
                              <button
                                className="btn btn-outline-secondary btn-sm fs-14"
                                onClick={() =>
                                  handleAction(
                                    selectedLead,
                                    selectedLead.isArchived
                                      ? "unarchive"
                                      : "archive"
                                  )
                                }
                              >
                                {selectedLead.isArchived
                                  ? "Unarchive"
                                  : "Archive"}
                              </button>
                              <button
                                className="btn btn-outline-danger btn-sm fs-14"
                                onClick={() =>
                                  handleDeleteEmail(selectedLead.id)
                                }
                              >
                                Delete
                              </button>
                            </div>
                          </div>

                          {/* Meta Cards */}
                          <div className="row g-2">
                            <div className="col-6">
                              <div className="card border-0 bg-light">
                                <div className="card-body p-3">
                                  <div className="d-flex align-items-center gap-2 mb-1">
                                    <Calendar
                                      size={16}
                                      className="text-primary"
                                    />
                                    <small className="text-muted fs-12">
                                      Event Date
                                    </small>
                                  </div>
                                  <div className="fw-semibold fs-14">
                                    {new Date(
                                      selectedLead.request.eventDate
                                    ).toLocaleDateString("en-IN", {
                                      day: "numeric",
                                      month: "long",
                                      year: "numeric",
                                    })}
                                  </div>
                                </div>
                              </div>
                            </div>
                            <div className="col-6">
                              <div className="card border-0 bg-light">
                                <div className="card-body p-3">
                                  <div className="d-flex align-items-center gap-2 mb-1">
                                    <Clock size={16} className="text-info" />
                                    <small className="text-muted fs-12">
                                      Received
                                    </small>
                                  </div>
                                  <div className="fw-semibold fs-14">
                                    {new Date(
                                      selectedLead.createdAt
                                    ).toLocaleDateString("en-IN", {
                                      day: "numeric",
                                      month: "short",
                                    })}
                                  </div>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>

                        <div className="mb-4">
                          <span
                            className="badge rounded-pill px-3 py-2 fs-14"
                            style={{
                              backgroundColor: statuses.find(
                                (s) => s.id === selectedLead.request.status
                              )?.color,
                              color: "white",
                            }}
                          >
                            {
                              statuses.find(
                                (s) => s.id === selectedLead.request.status
                              )?.name
                            }
                          </span>
                        </div>
                        <div className="mb-4">
                          <h6 className="fw-semibold mb-2 fs-16">Message</h6>
                          <div className="card border-0 bg-light">
                            <div className="card-body p-3">
                              <p
                                className="mb-0 fs-14"
                                style={{ lineHeight: "1.6" }}
                              >
                                {selectedLead.request.message ||
                                  "No message provided."}
                              </p>
                            </div>
                          </div>
                        </div>

                        <div>
                          <h6 className="fw-semibold mb-3 fs-16">
                            Update Status
                          </h6>
                          <div className="d-flex flex-wrap gap-2 mb-3">
                            {statuses.map((status) => (
                              <button
                                key={status.id}
                                className={`btn btn-sm rounded-pill fs-14 ${
                                  selectedLead.request.status === status.id
                                    ? "btn-danger"
                                    : "btn-outline-secondary"
                                }`}
                                onClick={() =>
                                  handleAction(selectedLead, status.id)
                                }
                              >
                                {status.name}
                              </button>
                            ))}
                          </div>

                          <button
                            className="btn btn-primary w-100 fs-14 p-2 rounded-pill fw-semibold d-flex align-items-center justify-content-center gap-2"
                            onClick={() => {
                              if (selectedLead) setShowQuoteModal(true);
                              else
                                addToast(
                                  "Please select a lead to reply to.",
                                  "warning"
                                );
                            }}
                          >
                            <MessageCircleReply size={18} />
                            Reply to Enquiry
                          </button>
                        </div>
                      </>
                    ) : (
                      !loading && (
                        <div className="h-100 d-flex flex-column align-items-center justify-content-center text-center">
                          <MailOpen size={48} className="text-muted mb-3" />
                          <h5 className="fw-semibold mb-2 fs-16">
                            Select an Enquiry
                          </h5>
                          <p className="text-muted fs-14">
                            Choose a lead from the list to view details
                          </p>
                        </div>
                      )
                    )}
                  </div>
                </div>
              </div>
            </div>
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
