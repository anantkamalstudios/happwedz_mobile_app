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
} from "react-icons/fi";
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
} from "chart.js";
import axiosInstance from "../../../services/api/axiosInstance";

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend
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
            labels: labels.map((d) =>
              new Date(d).toLocaleDateString("en-US", {
                month: "short",
                day: "numeric",
              })
            ),
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
      title: "Total Leads",
      value: leadCount,
      change: "+12%",
      trend: "up",
      // daily_avg: 4.7,
      icon: <FiUsers size={24} />,
    },

    profile_views: {
      title: "Profile Views",
      value: stats.profileViews.toLocaleString(),
      change: "+5.2%",
      trend: "up",
      icon: <FiEye size={24} />,
    },
    wishlist: {
      title: "impressions",
      value: stats.wishlistCount?.toLocaleString?.() ?? 0,
      change: "+0%",
      trend: "up",
      icon: <FiHeart size={24} />,
    },
  };

  // Chart data - Enhanced styling
  const leadsChartData = {
    labels: stats.chartData.labels,
    datasets: [
      {
        label: "Leads",
        data: stats.chartData.leads,
        borderColor: "#8b5cf6",
        backgroundColor: "rgba(139, 92, 246, 0.1)",
        tension: 0.4,
        fill: true,
        yAxisID: "y",
        borderWidth: 3,
        pointRadius: 4,
        pointHoverRadius: 6,
        pointBackgroundColor: "#8b5cf6",
        pointBorderColor: "#fff",
        pointBorderWidth: 2,
        pointHoverBackgroundColor: "#8b5cf6",
        pointHoverBorderColor: "#fff",
      },
      {
        label: "Impressions",
        data: stats.chartData.wishlist,
        borderColor: "#ec4899",
        backgroundColor: "rgba(236, 72, 153, 0.1)",
        tension: 0.4,
        yAxisID: "y3",
        fill: true,
        borderWidth: 3,
        pointRadius: 4,
        pointHoverRadius: 6,
        pointBackgroundColor: "#ec4899",
        pointBorderColor: "#fff",
        pointBorderWidth: 2,
        pointHoverBackgroundColor: "#ec4899",
        pointHoverBorderColor: "#fff",
      },
      {
        label: "Profile Views",
        data: stats.chartData.profileViews,
        borderColor: "#10b981",
        backgroundColor: "rgba(16, 185, 129, 0.1)",
        tension: 0.4,
        yAxisID: "y2",
        fill: true,
        borderWidth: 3,
        pointRadius: 4,
        pointHoverRadius: 6,
        pointBackgroundColor: "#10b981",
        pointBorderColor: "#fff",
        pointBorderWidth: 2,
        pointHoverBackgroundColor: "#10b981",
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
        position: "top",
        align: "end",
        labels: {
          usePointStyle: true,
          pointStyle: "circle",
          padding: 20,
          font: {
            size: 13,
            weight: "500",
            family: "'Inter', 'Segoe UI', sans-serif",
          },
          color: "#4a5568",
          boxWidth: 8,
          boxHeight: 8,
        },
      },
      tooltip: {
        enabled: true,
        backgroundColor: "rgba(0, 0, 0, 0.85)",
        titleColor: "#fff",
        bodyColor: "#fff",
        borderColor: "rgba(255, 255, 255, 0.2)",
        borderWidth: 1,
        padding: 12,
        displayColors: true,
        cornerRadius: 8,
        titleFont: {
          size: 14,
          weight: "bold",
        },
        bodyFont: {
          size: 13,
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
          color: "#718096",
          maxRotation: 45,
          minRotation: 0,
        },
      },
      y: {
        type: "linear",
        display: true,
        position: "left",
        grid: {
          color: "rgba(0, 0, 0, 0.05)",
          drawBorder: false,
        },
        ticks: {
          font: {
            size: 11,
            weight: "500",
          },
          color: "#718096",
          padding: 8,
        },
        title: {
          display: true,
          text: "Leads",
          font: {
            size: 12,
            weight: "600",
          },
          color: "#4a5568",
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
          color: "#718096",
          padding: 8,
        },
        title: {
          display: true,
          text: "Profile Views",
          font: {
            size: 12,
            weight: "600",
          },
          color: "#4a5568",
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
          color: "#4a5568",
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

  return (
    <Container className="leads-dashboard-page">
      <div className="page-header mb-4">
        <div className="d-flex flex-column flex-md-row justify-content-between align-items-md-center align-items-start gap-3">
          {/* Title */}
          <div>
            <h4 className="page-title">
              Leads, Impressions & Profile Views Dashboard
            </h4>
            <p className="text-muted mb-0">
              Track your business growth and engagement
            </p>
          </div>
          <div
            className="d-flex flex-column gap-2 w-100"
            style={{ maxWidth: "200px" }}
          >
            <Dropdown autoClose="outside">
              <Dropdown.Toggle
                variant="outline-secondary"
                className="d-flex align-items-center w-100 justify-content-between"
              >
                <FiCalendar className="me-2" />
                {dateFilter === "this_week"
                  ? "This Week"
                  : dateFilter === "this_month"
                    ? "This Month"
                    : dateFilter === "last_month"
                      ? "Last Month"
                      : dateFilter === "custom"
                        ? "Custom Range"
                        : "All Data"}
              </Dropdown.Toggle>

              <Dropdown.Menu>
                <Dropdown.Item onClick={() => setDateFilter("this_week")}>
                  This Week
                </Dropdown.Item>
                <Dropdown.Item onClick={() => setDateFilter("this_month")}>
                  This Month
                </Dropdown.Item>
                <Dropdown.Item onClick={() => setDateFilter("last_month")}>
                  Last Month
                </Dropdown.Item>
                <Dropdown.Item onClick={() => setDateFilter("custom")}>
                  Custom Range
                </Dropdown.Item>
                <Dropdown.Item onClick={() => setDateFilter("all_time")}>
                  All Data
                </Dropdown.Item>
                {/* Desktop-only inline custom range inside dropdown to avoid layout shift */}
                {dateFilter === "custom" && (
                  <div className="d-none d-md-block">
                    <Dropdown.Divider />
                    <div className="px-3 py-2" style={{ minWidth: "280px" }}>
                      <div className="d-flex flex-column gap-2">
                        <Form.Control
                          type="date"
                          value={customStart}
                          onChange={(e) => setCustomStart(e.target.value)}
                        />
                        <Form.Control
                          type="date"
                          value={customEnd}
                          onChange={(e) => setCustomEnd(e.target.value)}
                        />
                        <Button
                          variant="primary"
                          className="w-100 btn-outline-primary"
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
                          Apply
                        </Button>
                      </div>
                    </div>
                  </div>
                )}
              </Dropdown.Menu>
            </Dropdown>

            {/* Mobile-only custom range below dropdown (hidden on md and up) */}
            {dateFilter === "custom" && (
              <div className="d-block d-md-none">
                <div className="d-flex flex-column gap-2">
                  <Form.Control
                    type="date"
                    value={customStart}
                    onChange={(e) => setCustomStart(e.target.value)}
                  />
                  <Form.Text muted>Format: dd-mm-yyyy</Form.Text>

                  <Form.Control
                    type="date"
                    value={customEnd}
                    onChange={(e) => setCustomEnd(e.target.value)}
                  />
                  <Form.Text muted>Format: dd-mm-yyyy</Form.Text>
                </div>
                <Button
                  variant="primary"
                  className="w-100 btn-outline-primary"
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
                  Apply
                </Button>
              </div>
            )}

            <Button
              variant="outline-danger"
              className="ms-2"
              onClick={() => {
                setDateFilter("all_time");
                setCustomStart("");
                setCustomEnd("");
              }}
            >
              Reset Filter
            </Button>
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      <Row className="mb-4">
        {Object.entries(statsData).map(([key, data]) => {
          const cardContent = (
            <Card className="stat-card h-90">
              <Card.Body>
                <div className="d-flex justify-content-between align-items-start">
                  <div>
                    <span className="text-uppercase text-muted mb-1">
                      {data.title}
                    </span>
                    <h5 className="pt-4">{data.value}</h5>
                  </div>
                  <div
                    className={`icon-circle bg-${data.trend === "up" ? "success" : "danger"
                      }-light`}
                  >
                    {data.icon}
                  </div>
                </div>
              </Card.Body>
            </Card>
          );

          return (
            <Col xl={3} md={6} key={key} className="mb-4">
              {key === "leads" ? (
                <Link
                  to={`/vendor-dashboard/total-leads?dateFilter=${dateFilter}${dateFilter === "custom" && customStart && customEnd
                      ? `&customStart=${encodeURIComponent(
                        customStart
                      )}&customEnd=${encodeURIComponent(customEnd)}`
                      : ""
                    }`}
                  style={{ textDecoration: "none" }}
                >
                  {cardContent}
                </Link>
              ) : (
                cardContent
              )}
            </Col>
          );
        })}
      </Row>

      {/* Charts - Modern Design */}
      <Row className="mb-4">
        <Col lg={12} className="mb-4 mb-lg-0">
          <Card
            className="modern-chart-card border-0 shadow-sm"
            style={{
              backgroundColor: "#ffffff",
              borderRadius: "16px",
              overflow: "hidden",
              border: "1px solid #e5e7eb",
            }}
          >
            <Card.Body className="p-4">
              {/* Header Section */}
              <div
                className="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center mb-4 pb-3"
                style={{ borderBottom: "2px solid #f3f4f6" }}
              >
                <div>
                  <h4
                    className="mb-1 fw-bold"
                    style={{ color: "#111827", fontSize: "1.5rem" }}
                  >
                    Performance Analytics
                  </h4>
                  <p
                    className="mb-0"
                    style={{ color: "#6b7280", fontSize: "0.9rem" }}
                  >
                    Track your leads, impressions, and profile views over time
                  </p>
                </div>
              </div>

              {/* Chart Container */}
              <div
                className="chart-container p-4"
                style={{
                  backgroundColor: "#fafbfc",
                  borderRadius: "12px",
                  border: "1px solid #e5e7eb",
                }}
              >
                <div style={{ height: "400px", position: "relative" }}>
                  <Line data={leadsChartData} options={leadsChartOptions} />
                </div>
              </div>

              {/* Stats Summary Row */}
              <Row className="mt-4 g-3">
                <Col md={4}>
                  <div
                    className="p-3 text-center"
                    style={{
                      backgroundColor: "#f9fafb",
                      borderRadius: "10px",
                      border: "1px solid #e5e7eb",
                    }}
                  >
                    <div className="d-flex align-items-center justify-content-center gap-2 mb-1">
                      <FiUsers size={18} style={{ color: "#6b7280" }} />
                      <span
                        style={{
                          color: "#6b7280",
                          fontSize: "0.85rem",
                          fontWeight: "500",
                        }}
                      >
                        Total Leads
                      </span>
                    </div>
                    <h5
                      className="mb-0 fw-bold"
                      style={{ color: "#111827", fontSize: "1.5rem" }}
                    >
                      {leadCount}
                    </h5>
                  </div>
                </Col>
                <Col md={4}>
                  <div
                    className="p-3 text-center"
                    style={{
                      backgroundColor: "#f9fafb",
                      borderRadius: "10px",
                      border: "1px solid #e5e7eb",
                    }}
                  >
                    <div className="d-flex align-items-center justify-content-center gap-2 mb-1">
                      <FiEye size={18} style={{ color: "#6b7280" }} />
                      <span
                        style={{
                          color: "#6b7280",
                          fontSize: "0.85rem",
                          fontWeight: "500",
                        }}
                      >
                        Profile Views
                      </span>
                    </div>
                    <h5
                      className="mb-0 fw-bold"
                      style={{ color: "#111827", fontSize: "1.5rem" }}
                    >
                      {stats.profileViews.toLocaleString()}
                    </h5>
                  </div>
                </Col>
                <Col md={4}>
                  <div
                    className="p-3 text-center"
                    style={{
                      backgroundColor: "#f9fafb",
                      borderRadius: "10px",
                      border: "1px solid #e5e7eb",
                    }}
                  >
                    <div className="d-flex align-items-center justify-content-center gap-2 mb-1">
                      <FiHeart size={18} style={{ color: "#6b7280" }} />
                      <span
                        style={{
                          color: "#6b7280",
                          fontSize: "0.85rem",
                          fontWeight: "500",
                        }}
                      >
                        Impressions
                      </span>
                    </div>
                    <h5
                      className="mb-0 fw-bold"
                      style={{ color: "#111827", fontSize: "1.5rem" }}
                    >
                      {stats.wishlistCount?.toLocaleString?.() ?? 0}
                    </h5>
                  </div>
                </Col>
              </Row>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
};

export default HomeAdmin;
