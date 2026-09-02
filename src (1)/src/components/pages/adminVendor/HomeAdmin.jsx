import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { useSelector } from "react-redux";
import {
  Container,
  Row,
  Col,
  Card,
  Button,
  Form,
  Table,
  Tabs,
  Tab,
  Badge,
  ProgressBar,
  Dropdown,
  Nav,
} from "react-bootstrap";
import {
  FiFilter,
  FiCalendar,
  FiEye,
  FiMail,
  FiPhone,
  FiStar,
  FiDollarSign,
  FiDownload,
  FiChevronDown,
  FiChevronUp,
  FiSearch,
  FiBarChart2,
  FiUsers,
  FiTrendingUp,
  FiPercent,
  FiHeart,
  FiActivity,
  FiArrowRight,
  FiRotateCcw,
  FiShoppingBag,
} from "react-icons/fi";
import "./HomeAdmin.css";
import { Bar, Line } from "react-chartjs-2";
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  Filler,
} from "chart.js";
import axiosInstance from "../../../services/api/axiosInstance";
import { formatDate } from "../../../utils/dateFormat";

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  Filler
);

const HomeAdmin = () => {
  const [dateFilter, setDateFilter] = useState("all_time");
  const [customStart, setCustomStart] = useState("");
  const [customEnd, setCustomEnd] = useState("");
  const [customApplyToggle, setCustomApplyToggle] = useState(false);
  const [showFilter, setShowFilter] = useState(false);
  const [activeTab, setActiveTab] = useState("leads");
  const [sortConfig, setSortConfig] = useState({
    key: "date",
    direction: "desc",
  });
  const [leadCount, setLeadCount] = useState(0);
  const [loadingLeads, setLoadingLeads] = useState(true);
  const [stats, setStats] = useState({
    impressions: 0,
    profileViews: 0,
    wishlistCount: 0,
    chartData: {
      labels: [],
      leads: [],
      impressions: [],
      profileViews: [],
      wishlist: [],
    },
  });
  const [loadingStats, setLoadingStats] = useState(true);
  const [storefrontCompletion, setStorefrontCompletion] = useState(0);
  const { token: vendorToken, vendor } = useSelector(
    (state) => state.vendorAuth || {}
  );

  useEffect(() => {
    const stored = localStorage.getItem("storefrontCompletion");
    if (stored) {
      setStorefrontCompletion(parseInt(stored, 10));
    }
  }, []);

  // Persist dashboard filter state so selections survive navigation
  const FILTER_KEY = "homeAdmin_filters_v1";

  // Load saved filters on mount
  useEffect(() => {
    try {
      const raw = localStorage.getItem(FILTER_KEY);
      if (raw) {
        const obj = JSON.parse(raw);
        // restore custom dates first
        if (obj.customStart) setCustomStart(obj.customStart);
        if (obj.customEnd) setCustomEnd(obj.customEnd);
        if (obj.dateFilter) setDateFilter(obj.dateFilter);

        // If the saved filter was a custom range, trigger the apply toggle
        // so the data-fetching effect runs with the restored dates.
        if (obj.dateFilter === "custom") {
          // toggle after a tick to ensure state restored
          setTimeout(() => setCustomApplyToggle((t) => !t), 0);
        }
      }
    } catch (err) {
      console.error("Failed to load saved dashboard filters:", err);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Save filters whenever they change
  useEffect(() => {
    try {
      const payload = {
        dateFilter,
        customStart,
        customEnd,
      };
      localStorage.setItem(FILTER_KEY, JSON.stringify(payload));
    } catch (err) {
      console.error("Failed to save dashboard filters:", err);
    }
  }, [dateFilter, customStart, customEnd]);

  // No mobile conversion helpers needed when using native date inputs

  useEffect(() => {
    if (!vendorToken) {
      setLoadingLeads(false);
      return;
    }
    // compute start and end dates based on dateFilter
    const computeRange = () => {
      const now = new Date();
      let start = null;
      let end = null;

      if (dateFilter === "this_week") {
        // start of current week (Monday)
        const day = now.getDay();
        const diff = day === 0 ? 6 : day - 1; // days since Monday
        start = new Date(now);
        start.setDate(now.getDate() - diff);
        start.setHours(0, 0, 0, 0);
        end = new Date(now);
        end.setHours(23, 59, 59, 999);
      } else if (dateFilter === "this_month") {
        start = new Date(now.getFullYear(), now.getMonth(), 1);
        start.setHours(0, 0, 0, 0);
        end = new Date(now);
        end.setHours(23, 59, 59, 999);
      } else if (dateFilter === "last_month") {
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
      } else if (dateFilter === "custom") {
        if (customStart && customEnd) {
          start = new Date(customStart);
          start.setHours(0, 0, 0, 0);
          end = new Date(customEnd);
          end.setHours(23, 59, 59, 999);
        } else {
          return null;
        }
      } else if (dateFilter === "all_time") {
        start = new Date(0); // 1970-01-01
        end = new Date();
        end.setHours(23, 59, 59, 999);
      } else {
        // default to last 30 days
        end = new Date();
        end.setHours(23, 59, 59, 999);
        start = new Date();
        start.setDate(end.getDate() - 29);
        start.setHours(0, 0, 0, 0);
      }

      return { start, end };
    };
    const fetchDashboardData = async () => {
      try {
        const range = computeRange();
        if (!range) return;

        setLoadingLeads(true);
        setLoadingStats(true);

        const response = await axiosInstance.get(
          "/request-pricing/vendor/dashboard",
          {
            headers: { Authorization: `Bearer ${vendorToken}` },
          }
        );
        const data = response.data || {};
        const leads = data?.requests || [];

        // compute date range from filter
        const { start, end } = range;

        // filter leads within range
        const leadsInRange = leads.filter((lead) => {
          if (!lead.createdAt) return false;
          const t = new Date(lead.createdAt).getTime();
          return t >= start.getTime() && t <= end.getTime();
        });

        // 1. Set total lead count for the selected range
        setLeadCount(leadsInRange.length);

        // build labels per day between start and end
        const labels = [];
        const dayMs = 24 * 60 * 60 * 1000;
        const maxDays = 90;
        const days = Math.min(
          Math.ceil((end.getTime() - start.getTime()) / dayMs) + 1,
          maxDays
        );
        for (let i = 0; i < days; i++) {
          const d = new Date(start.getTime() + i * dayMs);
          labels.push(d.toISOString().split("T")[0]);
        }

        const leadsByDate = leadsInRange.reduce((acc, lead) => {
          const date = new Date(lead.createdAt).toISOString().split("T")[0];
          acc[date] = (acc[date] || 0) + 1;
          return acc;
        }, {});

        const leadChartValues = labels.map((label) => leadsByDate[label] || 0);

        // 3. Update stats state with new chart data
        setStats((prev) => ({
          ...prev,
          chartData: {
            labels: labels.map((d) => formatDate(d)),
            leads: leadChartValues,
            impressions: prev.chartData.impressions,
            profileViews: prev.chartData.totalViews || [],
          },
        }));

        console.log("stats", stats);

        // 4. Fetch profile views and wishlist stats for the vendor (if vendor id available)
        if (vendor?.id) {
          // helper to build per-day series from event lists
          const buildSeriesFromEvents = (events, dateKeys, labels) => {
            const map = {};
            if (!Array.isArray(events)) return labels.map(() => 0);
            for (const ev of events) {
              // if event is aggregated already
              if (ev && (ev.date || ev.day) && typeof ev.count === "number") {
                const d = new Date(ev.date || ev.day)
                  .toISOString()
                  .split("T")[0];
                map[d] = (map[d] || 0) + ev.count;
                continue;
              }

              // otherwise find a date-like field
              let found = null;
              for (const k of dateKeys) {
                if (ev && ev[k]) {
                  const parsed = new Date(ev[k]);
                  if (!isNaN(parsed)) {
                    found = parsed.toISOString().split("T")[0];
                    break;
                  }
                }
              }
              if (found) {
                map[found] = (map[found] || 0) + 1;
              }
            }
            return labels.map((lbl) => map[lbl] || 0);
          };

          // Profile views
          try {
            const pvRes = await axiosInstance.get(
              `/vendor/profile-views/${vendor.id}`,
              { headers: { Authorization: `Bearer ${vendorToken}` } }
            );
            if (pvRes?.data) {
              const pvData = pvRes.data;
              const allViews = pvData.views || [];

              // Filter views by date range
              const { start, end } = range;
              const viewsInRange = allViews.filter((view) => {
                const dateStr = view.createdAt || view.view_date;
                if (!dateStr) return false;
                const t = new Date(dateStr).getTime();
                return t >= start.getTime() && t <= end.getTime();
              });

              const pvCount = viewsInRange.length;

              // Build timeseries from filtered views
              const pvSeries = buildSeriesFromEvents(
                viewsInRange,
                ["createdAt", "view_date", "date"],
                labels.map((d) => new Date(d).toISOString().split("T")[0])
              );

              setStats((prev) => ({
                ...prev,
                profileViews: pvCount,
                chartData: {
                  ...prev.chartData,
                  profileViews: pvSeries,
                },
              }));
            }
          } catch (pvErr) {
            console.error("Failed to fetch profile views:", pvErr);
          }

          // Wishlist stats (returns wishlistCount in data[0].wishlistCount)
          try {
            const wlRes = await axiosInstance.get(
              `/wishlist/vendor/stats/${vendor.id}`,
              { headers: { Authorization: `Bearer ${vendorToken}` } }
            );
            if (wlRes?.data) {
              const wlData = wlRes.data;
              const wlRaw = wlData?.data?.[0] || {};
              const allUsers = wlRaw.users || [];

              // Filter users by date range (addedAt field)
              const { start, end } = range;
              const usersInRange = allUsers.filter((user) => {
                if (!user.addedAt) return false;
                const t = new Date(user.addedAt).getTime();
                return t >= start.getTime() && t <= end.getTime();
              });

              const wlCount = usersInRange.length; // count of wishlist adds in range

              // Build per-day series from filtered users
              let wlSeries = null;
              if (usersInRange && usersInRange.length > 0) {
                wlSeries = buildSeriesFromEvents(
                  usersInRange,
                  ["addedAt", "createdAt", "date"],
                  labels.map((d) => new Date(d).toISOString().split("T")[0])
                );
              }

              setStats((prev) => ({
                ...prev,
                wishlistCount: wlCount,
                chartData: {
                  ...prev.chartData,
                  wishlist: wlSeries || labels.map(() => wlCount),
                },
              }));
            }
          } catch (wlErr) {
            console.error("Failed to fetch wishlist stats:", wlErr);
          }
        }
      } catch (err) {
        console.error("Error fetching leads count:", err);
        setLeadCount(0); // Set to 0 on error
      } finally {
        setLoadingLeads(false);
      }
    };

    fetchDashboardData();
  }, [vendorToken, vendor?.id, dateFilter, customApplyToggle]);

  // Stats data
  const statsData = {
    leads: {
      type: "leads",
      title: "Total Leads",
      label: "TOTAL LEADS",
      value: leadCount,
      subtext: "Direct inquiries from interested couples",
      link: `/vendor-dashboard/total-leads?dateFilter=${dateFilter}${
        dateFilter === "custom" && customStart && customEnd
          ? `&customStart=${encodeURIComponent(
              customStart
            )}&customEnd=${encodeURIComponent(customEnd)}`
          : ""
      }`,
      icon: <FiUsers size={22} />,
    },
    profile_views: {
      type: "views",
      title: "Profile Views",
      label: "PROFILE VIEWS",
      value: stats.profileViews.toLocaleString(),
      subtext: "Storefront visits & profile clicks",
      icon: <FiEye size={22} />,
    },
    wishlist: {
      type: "impressions",
      title: "Impressions",
      label: "TOTAL IMPRESSIONS",
      value: stats.wishlistCount?.toLocaleString?.() ?? 0,
      subtext: "Wishlist saves & discovery reach",
      icon: <FiHeart size={22} />,
    },
  };

  // Chart data - Enhanced styling (Brand UI Theme)
  const leadsChartData = {
    labels: stats.chartData.labels,
    datasets: [
      {
        label: "Leads",
        data: stats.chartData.leads,
        borderColor: "#ed1173",
        backgroundColor: "rgba(237, 17, 115, 0.12)",
        tension: 0.4,
        fill: true,
        yAxisID: "y",
        borderWidth: 3,
        pointRadius: 4,
        pointHoverRadius: 6,
        pointBackgroundColor: "#ed1173",
        pointBorderColor: "#fff",
        pointBorderWidth: 2,
        pointHoverBackgroundColor: "#ed1173",
        pointHoverBorderColor: "#fff",
      },
      {
        label: "Impressions",
        data: stats.chartData.wishlist,
        borderColor: "#db2777",
        backgroundColor: "rgba(219, 39, 119, 0.08)",
        tension: 0.4,
        yAxisID: "y3",
        fill: true,
        borderWidth: 3,
        pointRadius: 4,
        pointHoverRadius: 6,
        pointBackgroundColor: "#db2777",
        pointBorderColor: "#fff",
        pointBorderWidth: 2,
        pointHoverBackgroundColor: "#db2777",
        pointHoverBorderColor: "#fff",
      },
      {
        label: "Profile Views",
        data: stats.chartData.profileViews,
        borderColor: "#be185d",
        backgroundColor: "rgba(190, 24, 93, 0.08)",
        tension: 0.4,
        yAxisID: "y2",
        fill: true,
        borderWidth: 3,
        pointRadius: 4,
        pointHoverRadius: 6,
        pointBackgroundColor: "#be185d",
        pointBorderColor: "#fff",
        pointBorderWidth: 2,
        pointHoverBackgroundColor: "#be185d",
        pointHoverBorderColor: "#fff",
      },
    ],
  };

  const _sourcesChartData = {
    labels: ["HappyWedz", "Website", "Google", "Social Media", "Referrals"],
    datasets: [
      {
        label: "Leads by Source",
        data: [42, 28, 18, 8, 4],
        backgroundColor: [
          "#8e44ad",
          "#3498db",
          "#2ecc71",
          "#f1c40f",
          "#e74c3c",
        ],
        borderColor: "#fff",
        borderWidth: 2,
      },
    ],
  };

  // Chart options - Enhanced for modern UI
  const leadsChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    interaction: {
      mode: "index",
      intersect: false,
    },
    animation: {
      duration: 1000,
      easing: "easeInOutQuart",
    },
    plugins: {
      legend: {
        display: false, // We render a custom modern legend above the chart
      },
      tooltip: {
        enabled: true,
        backgroundColor: "rgba(15, 23, 42, 0.92)",
        titleColor: "#ffffff",
        bodyColor: "#f8fafc",
        borderColor: "rgba(255, 255, 255, 0.12)",
        borderWidth: 1,
        padding: 12,
        displayColors: true,
        cornerRadius: 10,
        titleFont: {
          size: 13,
          weight: "700",
          family: "'Outfit', 'Inter', sans-serif",
        },
        bodyFont: {
          size: 12,
          weight: "500",
          family: "'Outfit', 'Inter', sans-serif",
        },
        callbacks: {
          label: function (context) {
            let label = context.dataset.label || "";
            if (label) {
              label += ": ";
            }
            if (context.parsed.y !== null) {
              label += context.parsed.y.toLocaleString();
            }
            return label;
          },
        },
      },
    },
    scales: {
      x: {
        grid: {
          display: false,
        },
        ticks: {
          font: {
            size: 11,
            weight: "500",
          },
          color: "#94a3b8",
          maxRotation: 45,
          minRotation: 0,
        },
      },
      y: {
        type: "linear",
        display: true,
        position: "left",
        grid: {
          color: "rgba(226, 232, 240, 0.6)",
          drawBorder: false,
        },
        ticks: {
          font: {
            size: 11,
            weight: "500",
          },
          color: "#94a3b8",
          padding: 8,
        },
        title: {
          display: true,
          text: "Leads",
          font: {
            size: 12,
            weight: "600",
          },
          color: "#64748b",
        },
      },
      y2: {
        type: "linear",
        display: true,
        position: "right",
        grid: {
          drawOnChartArea: false,
          drawBorder: false,
        },
        ticks: {
          font: {
            size: 11,
            weight: "500",
          },
          color: "#94a3b8",
          padding: 8,
        },
        title: {
          display: true,
          text: "Profile Views",
          font: {
            size: 12,
            weight: "600",
          },
          color: "#64748b",
        },
      },
      y3: {
        type: "linear",
        display: false,
        position: "right",
        grid: {
          drawOnChartArea: false,
          drawBorder: false,
        },
        title: {
          display: true,
          text: "Impressions",
          font: {
            size: 12,
            weight: "600",
          },
          color: "#64748b",
        },
      },
    },
  };

  const _sourcesChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: "top",
      },
    },
  };

// Sparkline Wave Component
const SparklineWave = ({ color = "#3b82f6" }) => (
  <svg
    width="110"
    height="46"
    viewBox="0 0 110 46"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    className="admin-stat-sparkline"
  >
    <path
      d="M3 34C16 34 22 14 36 26C50 38 58 8 72 18C86 28 92 6 107 10"
      stroke={color}
      strokeWidth="2.75"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);

  return (
    <Container className="vendor-crm-dashboard">
      {/* Top Bar with Title and Breadcrumb */}
      <div className="vendor-crm-topbar">
        <h4 className="vendor-crm-page-title">Dashboard</h4>
        <div className="vendor-crm-breadcrumb">
          <Link to="/vendor-dashboard" className="vendor-crm-breadcrumb-link">
            Dashboard
          </Link>
          <span>-</span>
          <span>CRM</span>
        </div>
      </div>

      {/* 3 Symmetrical Admin Stat Cards */}
      <Row className="g-4 mb-4">
        {/* Card 1: Total Leads (Primary Pink) */}
        <Col lg={4} md={6} xs={12}>
          <Link
            to={`/vendor-dashboard/total-leads?dateFilter=${dateFilter}${
              dateFilter === "custom" && customStart && customEnd
                ? `&customStart=${encodeURIComponent(
                    customStart
                  )}&customEnd=${encodeURIComponent(customEnd)}`
                : ""
            }`}
            style={{ textDecoration: "none", display: "block", height: "100%" }}
          >
            <div className="admin-stat-card admin-stat-card--pink-1">
              <div className="admin-stat-card-header">
                <div className="admin-stat-left">
                  <div className="admin-stat-icon-circle admin-stat-icon-circle--pink-1">
                    <FiUsers />
                  </div>
                  <div>
                    <div className="admin-stat-title">New Users / Leads</div>
                    <h3 className="admin-stat-value">{leadCount}</h3>
                  </div>
                </div>
                <SparklineWave color="#ed1173" />
              </div>
              <div className="admin-stat-subtitle">Total registered leads</div>
            </div>
          </Link>
        </Col>

        {/* Card 2: Profile Views (Rose Pink) */}
        <Col lg={4} md={6} xs={12}>
          <div className="admin-stat-card admin-stat-card--pink-2">
            <div className="admin-stat-card-header">
              <div className="admin-stat-left">
                <div className="admin-stat-icon-circle admin-stat-icon-circle--pink-2">
                  <FiShoppingBag />
                </div>
                <div>
                  <div className="admin-stat-title">Profile Views</div>
                  <h3 className="admin-stat-value">
                    {stats.profileViews.toLocaleString()}
                  </h3>
                </div>
              </div>
              <SparklineWave color="#db2777" />
            </div>
            <div className="admin-stat-subtitle">Total storefront views</div>
          </div>
        </Col>

        {/* Card 3: Impressions (Ruby Pink) */}
        <Col lg={4} md={6} xs={12}>
          <div className="admin-stat-card admin-stat-card--pink-3">
            <div className="admin-stat-card-header">
              <div className="admin-stat-left">
                <div className="admin-stat-icon-circle admin-stat-icon-circle--pink-3">
                  <FiHeart />
                </div>
                <div>
                  <div className="admin-stat-title">Impressions</div>
                  <h3 className="admin-stat-value">
                    {stats.wishlistCount?.toLocaleString?.() ?? 0}
                  </h3>
                </div>
              </div>
              <SparklineWave color="#be185d" />
            </div>
            <div className="admin-stat-subtitle">Total leads & reach count</div>
          </div>
        </Col>
      </Row>

      {/* Analytics Chart Section (Earning / Performance Statistic) */}
      <div className="admin-chart-section-card">
        {/* Top Header */}
        <div className="admin-chart-top-header">
          <div>
            <h4 className="admin-chart-main-title">Performance Statistic</h4>
            <p className="admin-chart-sub-title">
              Yearly engagement and inquiries overview
            </p>
          </div>

          {/* Select Frequency Dropdown */}
          <div className="d-flex align-items-center gap-2">
            <Dropdown>
              <Dropdown.Toggle
                id="vendor-frequency-dropdown"
                className="admin-frequency-dropdown-toggle"
              >
                <FiCalendar size={15} style={{ color: "#ed1173" }} />
                <span>
                  {dateFilter === "all_time"
                    ? "All Time"
                    : dateFilter === "this_week"
                    ? "This Week"
                    : dateFilter === "this_month"
                    ? "This Month"
                    : dateFilter === "last_month"
                    ? "Last Month"
                    : dateFilter === "custom"
                    ? "Custom Range"
                    : "Select Frequency"}
                </span>
              </Dropdown.Toggle>

              <Dropdown.Menu className="vendor-filter-dropdown-menu">
                <Dropdown.Item
                  className={`vendor-filter-dropdown-item ${
                    dateFilter === "all_time" ? "active" : ""
                  }`}
                  onClick={() => setDateFilter("all_time")}
                >
                  All Data
                </Dropdown.Item>
                <Dropdown.Item
                  className={`vendor-filter-dropdown-item ${
                    dateFilter === "this_week" ? "active" : ""
                  }`}
                  onClick={() => setDateFilter("this_week")}
                >
                  This Week
                </Dropdown.Item>
                <Dropdown.Item
                  className={`vendor-filter-dropdown-item ${
                    dateFilter === "this_month" ? "active" : ""
                  }`}
                  onClick={() => setDateFilter("this_month")}
                >
                  This Month
                </Dropdown.Item>
                <Dropdown.Item
                  className={`vendor-filter-dropdown-item ${
                    dateFilter === "last_month" ? "active" : ""
                  }`}
                  onClick={() => setDateFilter("last_month")}
                >
                  Last Month
                </Dropdown.Item>
                <Dropdown.Item
                  className={`vendor-filter-dropdown-item ${
                    dateFilter === "custom" ? "active" : ""
                  }`}
                  onClick={() => setDateFilter("custom")}
                >
                  Custom Range
                </Dropdown.Item>

                {/* Inline custom range inside dropdown */}
                {dateFilter === "custom" && (
                  <>
                    <Dropdown.Divider />
                    <div className="admin-custom-date-popover">
                      <div className="d-flex flex-column gap-2">
                        <div className="small fw-semibold text-muted">
                          Start Date
                        </div>
                        <Form.Control
                          type="date"
                          value={customStart}
                          onChange={(e) => setCustomStart(e.target.value)}
                        />
                        <div className="small fw-semibold text-muted mt-1">
                          End Date
                        </div>
                        <Form.Control
                          type="date"
                          value={customEnd}
                          onChange={(e) => setCustomEnd(e.target.value)}
                        />
                        <Button
                          variant="primary"
                          className="w-100 mt-2 py-2 fw-semibold"
                          style={{
                            backgroundColor: "#ed1173",
                            borderColor: "#ed1173",
                            borderRadius: "8px",
                            fontSize: "0.85rem",
                          }}
                          onClick={() => {
                            if (!customStart || !customEnd) {
                              alert("Please select both start and end dates.");
                              return;
                            }
                            if (new Date(customStart) > new Date(customEnd)) {
                              alert("Start date must be before end date.");
                              return;
                            }
                            setCustomApplyToggle((t) => !t);
                          }}
                        >
                          Apply Filter
                        </Button>
                      </div>
                    </div>
                  </>
                )}
              </Dropdown.Menu>
            </Dropdown>

            {dateFilter !== "all_time" && (
              <button
                type="button"
                className="vendor-filter-reset-btn"
                onClick={() => {
                  setDateFilter("all_time");
                  setCustomStart("");
                  setCustomEnd("");
                }}
                title="Reset filter"
              >
                <FiRotateCcw size={13} />
                <span>Reset</span>
              </button>
            )}
          </div>
        </div>

        {/* Stat Pills Center Summary */}
        <div className="admin-stat-pills-row">
          <div className="admin-stat-pill-box">
            <div className="admin-stat-pill-icon" style={{ color: "#ed1173" }}>
              <FiUsers />
            </div>
            <div>
              <div className="admin-stat-pill-label">Leads</div>
              <h5 className="admin-stat-pill-value">{leadCount}</h5>
            </div>
          </div>

          <div className="admin-stat-pill-box">
            <div className="admin-stat-pill-icon" style={{ color: "#db2777" }}>
              <FiShoppingBag />
            </div>
            <div>
              <div className="admin-stat-pill-label">Views</div>
              <h5 className="admin-stat-pill-value">
                {stats.profileViews.toLocaleString()}
              </h5>
            </div>
          </div>

          <div className="admin-stat-pill-box">
            <div className="admin-stat-pill-icon" style={{ color: "#be185d" }}>
              <FiHeart />
            </div>
            <div>
              <div className="admin-stat-pill-label">Impressions</div>
              <h5 className="admin-stat-pill-value">
                {stats.wishlistCount?.toLocaleString?.() ?? 0}
              </h5>
            </div>
          </div>
        </div>

        {/* Chart Canvas */}
        <div className="admin-chart-canvas-container">
          <Line data={leadsChartData} options={leadsChartOptions} />
        </div>
      </div>
    </Container>
  );
};

export default HomeAdmin;
