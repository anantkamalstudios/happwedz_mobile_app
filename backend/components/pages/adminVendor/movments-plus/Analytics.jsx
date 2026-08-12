import React, { useState, useEffect } from "react";
import {
  Container,
  Row,
  Col,
  Card,
  ProgressBar,
  Spinner,
  Alert,
  Button,
} from "react-bootstrap";
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import {
  FiHardDrive,
  FiImage,
  FiEye,
  FiShare2,
  FiActivity,
  FiClock,
  FiDownload,
} from "react-icons/fi";
import axiosInstance from "../../../../services/api/axiosInstance";
import { toast } from "react-toastify";
import "./analytics.css";

const COLORS = [
  "#FF6384",
  "#36A2EB",
  "#FFCE56",
  "#4BC0C0",
  "#9966FF",
  "#FF9F40",
];

const Analytics = () => {
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);

  // Token Analytics State
  const [tokenList, setTokenList] = useState([]);
  const [selectedTokenId, setSelectedTokenId] = useState("");
  const [tokenAnalytics, setTokenAnalytics] = useState(null);
  const [tokenLoading, setTokenLoading] = useState(false);

  useEffect(() => {
    fetchAnalytics();
    fetchTokens();
  }, []);

  const fetchTokens = async () => {
    try {
      const storedVendorId = localStorage.getItem("vendorId") || 75075;
      const response = await axiosInstance.get(
        `/token/vendor/${storedVendorId}`
      );
      if (response.data.success) {
        setTokenList(response.data.tokens);
      }
    } catch (err) {
      console.error("Error fetching tokens:", err);
    }
  };

  const fetchTokenAnalytics = async (tokenId) => {
    if (!tokenId) {
      setTokenAnalytics(null);
      return;
    }

    try {
      setTokenLoading(true);
      const response = await axiosInstance.get(`/token/${tokenId}/analytics`);
      if (response.data.success) {
        setTokenAnalytics(response.data.analytics);
      }
    } catch (err) {
      console.error("Error fetching token analytics:", err);
      // Mock data for development
      if (process.env.NODE_ENV === "development") {
        setTokenAnalytics({
          id: 1,
          token: "ec3da2f7c0ad",
          type: "public",
          status: "disabled",
          view_count: 0,
          unique_views: 0,
          email_sent_count: 0,
          last_viewed_at: null,
          last_shared_at: null,
        });
      } else {
        toast.error("Failed to load token analytics");
      }
    } finally {
      setTokenLoading(false);
    }
  };

  const handleTokenChange = (e) => {
    const tokenId = e.target.value;
    setSelectedTokenId(tokenId);
    fetchTokenAnalytics(tokenId);
  };

  const handleGenerateReport = async () => {
    try {
      const storedVendorId = localStorage.getItem("vendorId") || 75075;
      const response = await axiosInstance.get(
        `/analytics/report/${storedVendorId}`
      );
      if (response.data.success) {
        toast.success("Report generated successfully");
      } else {
        toast.error("Failed to generate report");
      }
    } catch (err) {
      console.error("Error generating report:", err);
      toast.error("Failed to generate report");
    }
  };

  const fetchAnalytics = async () => {
    try {
      setLoading(true);
      const response = await axiosInstance.get("/vendor/dashboard/analytics");
      if (response.data.success) {
        setData(response.data);
      } else {
        setError("Failed to load analytics data");
      }
    } catch (err) {
      console.error("Error fetching analytics:", err);
      // Use mock data if API fails for demonstration/development purposes
      if (process.env.NODE_ENV === "development") {
        console.warn("Using mock data due to API error");
        setData({
          success: true,
          package: {
            name: "Premium",
            limitMB: 10240,
            usedMB: 4.52,
            remainingMB: 10235.48,
            usagePercent: 0,
            startedAt: "2025-12-25T12:27:34.617Z",
          },
          media: {
            total: 20,
            byCollection: [
              { collection: "Engagement", count: "6" },
              { collection: "Haldi", count: "10" },
              { collection: "wedding", count: "4" },
            ],
            visibility: [
              { visibility: "private", count: "7" },
              { visibility: "public", count: "13" },
            ],
          },
          tokens: {
            total: 5,
            active: 4,
            byType: [
              { type: "public", count: "1" },
              { type: "private", count: "4" },
            ],
          },
          reach: {
            totalViews: 0,
            uniqueViews: 0,
          },
          activity: {
            lastUploadAt: "2025-12-26T10:13:29.597Z",
            lastTokenCreatedAt: "2025-12-27T13:02:47.300Z",
          },
          usage: {
            canUpload: true,
            storageWarning: false,
          },
        });
      } else {
        setError("An error occurred while loading analytics");
        toast.error("Failed to load analytics data");
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAnalytics();
    fetchTokens();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (loading) {
    return (
      <div className="analytics-loader">
        <Spinner animation="border" variant="primary" />
      </div>
    );
  }

  if (error || !data) {
    return (
      <Container className="p-4">
        <Alert variant="danger">{error || "No data available"}</Alert>
      </Container>
    );
  }

  const { package: pkg, media, tokens, reach, activity } = data;

  // Prepare data for Recharts
  const mediaCollectionData = media.byCollection.map((item) => ({
    name: item.collection,
    value: parseInt(item.count),
  }));

  const mediaVisibilityData = media.visibility.map((item) => ({
    name: item.visibility,
    value: parseInt(item.count),
  }));

  const tokenTypeData = tokens.byType.map((item) => ({
    name: item.type,
    value: parseInt(item.count),
  }));

  const CustomTooltip = ({ active, payload }) => {
    if (active && payload && payload.length) {
      return (
        <div className="custom-tooltip bg-white p-2 border shadow-sm rounded">
          <p className="mb-0 fw-bold">{`${payload[0].name} : ${payload[0].value}`}</p>
        </div>
      );
    }
    return null;
  };

  return (
    <div className="analytics-container p-4">
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h2 className="fw-bold text-dark inter mb-0">Analytics Dashboard</h2>
      </div>

      {/* Storage Usage Card */}
      <Card className="mb-4 shadow-sm border-0 analytics-card">
        <Card.Body>
          <div className="d-flex justify-content-between align-items-center mb-3">
            <h5 className="card-title mb-0 inter">
              <FiHardDrive className="me-2 text-primary" />
              Storage Usage ({pkg.name} Package)
            </h5>
            <span className="text-muted small inter">
              {pkg.usedMB.toFixed(2)} MB used of {pkg.limitMB} MB
            </span>
          </div>
          <ProgressBar
            now={pkg.usagePercent || (pkg.usedMB / pkg.limitMB) * 100}
            label={`${(
              pkg.usagePercent || (pkg.usedMB / pkg.limitMB) * 100
            ).toFixed(1)}%`}
            variant={pkg.usagePercent > 90 ? "danger" : "primary"}
            className="mb-2"
            style={{ height: "20px" }}
          />
          <small className="text-muted inter">
            Started at: {new Date(pkg.startedAt).toLocaleDateString()}
          </small>
        </Card.Body>
      </Card>

      {/* Key Metrics Row */}
      <Row className="g-4 mb-4">
        <Col md={4}>
          <Card className="shadow-sm border-0 h-100 analytics-stat-card">
            <Card.Body className="d-flex align-items-center">
              <div className="stat-icon-wrapper bg-light-primary text-primary">
                <FiImage size={24} color="black" />
              </div>
              <div className="ms-3">
                <h6 className="text-muted mb-1 inter">Total Media</h6>
                <h3 className="mb-0 fw-bold inter">{media.total}</h3>
              </div>
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card className="shadow-sm border-0 h-100 analytics-stat-card">
            <Card.Body className="d-flex align-items-center">
              <div className="stat-icon-wrapper bg-light-success text-success">
                <FiShare2 size={24} color="black" />
              </div>
              <div className="ms-3">
                <h6 className="text-muted mb-1 inter">Active Tokens</h6>
                <h3 className="mb-0 fw-bold inter">
                  {tokens.active}{" "}
                  <span className="text-muted fs-6">/ {tokens.total}</span>
                </h3>
              </div>
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card className="shadow-sm border-0 h-100 analytics-stat-card">
            <Card.Body className="d-flex align-items-center">
              <div className="stat-icon-wrapper bg-light-info text-info">
                <FiEye size={24} color="black" />
              </div>
              <div className="ms-3">
                <h6 className="text-muted mb-1 inter">Total Views</h6>
                <h3 className="mb-0 fw-bold inter">{reach.totalViews}</h3>
                <small className="text-muted inter">
                  Unique: {reach.uniqueViews}
                </small>
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Charts Row */}
      <Row className="g-4 mb-4">
        <Col md={4}>
          <Card className="shadow-sm border-0 h-100 analytics-card">
            <Card.Body>
              <h5 className="card-title mb-4 inter">Media by Collection</h5>
              <div className="movement-chart-container" style={{ height: "300px" }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={mediaCollectionData}
                      cx="50%"
                      cy="50%"
                      innerRadius={60}
                      outerRadius={80}
                      paddingAngle={5}
                      dataKey="value"
                    >
                      {mediaCollectionData.map((entry, index) => (
                        <Cell
                          key={`cell-${index}`}
                          fill={COLORS[index % COLORS.length]}
                        />
                      ))}
                    </Pie>
                    <Tooltip content={<CustomTooltip />} />
                    <Legend
                      layout="horizontal"
                      verticalAlign="bottom"
                      align="center"
                    />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card className="shadow-sm border-0 h-100 analytics-card">
            <Card.Body>
              <h5 className="card-title mb-4 inter">Media Visibility</h5>
              <div className="movement-chart-container" style={{ height: "300px" }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={mediaVisibilityData}
                      cx="50%"
                      cy="50%"
                      innerRadius={60}
                      outerRadius={80}
                      paddingAngle={5}
                      dataKey="value"
                    >
                      {mediaVisibilityData.map((entry, index) => (
                        <Cell
                          key={`cell-${index}`}
                          fill={COLORS[index % 2 === 0 ? 3 : 0]}
                        />
                      ))}
                    </Pie>
                    <Tooltip content={<CustomTooltip />} />
                    <Legend
                      layout="horizontal"
                      verticalAlign="bottom"
                      align="center"
                    />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card className="shadow-sm border-0 h-100 analytics-card">
            <Card.Body>
              <h5 className="card-title mb-4 inter">Tokens by Type</h5>
              <div className="movement-chart-container" style={{ height: "300px" }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={tokenTypeData}
                      cx="50%"
                      cy="50%"
                      innerRadius={60}
                      outerRadius={80}
                      paddingAngle={5}
                      dataKey="value"
                    >
                      {tokenTypeData.map((entry, index) => (
                        <Cell
                          key={`cell-${index}`}
                          fill={COLORS[index % 2 === 0 ? 1 : 2]}
                        />
                      ))}
                    </Pie>
                    <Tooltip content={<CustomTooltip />} />
                    <Legend
                      layout="horizontal"
                      verticalAlign="bottom"
                      align="center"
                    />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Activity Section */}
      <Row>
        <Col md={12}>
          <Card className="shadow-sm border-0 analytics-card">
            <Card.Body>
              <h5 className="card-title mb-3 inter">
                <FiActivity className="me-2" /> Recent Activity
              </h5>
              <div className="activity-list">
                <div className="activity-item d-flex align-items-center py-3 border-bottom">
                  <FiClock className="text-muted me-3" size={20} />
                  <div>
                    <strong className="inter">Last Upload</strong>
                    <br />
                    <span className="text-muted inter">
                      {activity.lastUploadAt
                        ? new Date(activity.lastUploadAt).toLocaleString()
                        : "Never"}
                    </span>
                  </div>
                </div>
                <div className="activity-item d-flex align-items-center py-3">
                  <FiShare2 className="text-muted me-3" size={20} />
                  <div>
                    <strong className="inter">Last Token Created</strong>
                    <br />
                    <span className="text-muted inter">
                      {activity.lastTokenCreatedAt
                        ? new Date(activity.lastTokenCreatedAt).toLocaleString()
                        : "Never"}
                    </span>
                  </div>
                </div>
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </div>
  );
};

export default Analytics;
