import React, { useState, useEffect, useRef } from "react";
import { useSelector } from "react-redux";
import {
  Upload,
  X,
  CheckCircle,
  AlertCircle,
  Image,
  Video,
  HardDrive,
  Copy,
  Eye,
  Share2,
  Clock,
  Key,
  Calendar,
  EyeOff,
  RefreshCw,
  Trash2,
} from "lucide-react";
import { toast } from "react-toastify";
import axiosInstance from "../../../../services/api/axiosInstance";
import "./tokens-sharing.css";

const FilePreview = ({ file, index, onReplace, onRemove, disabled }) => {
  const [preview, setPreview] = useState(null);

  useEffect(() => {
    if (file.type.startsWith("image/")) {
      const url = URL.createObjectURL(file);
      setPreview(url);
      return () => URL.revokeObjectURL(url);
    }
  }, [file]);

  return (
    <div className="preview-card">
      <div className="preview-image-wrapper">
        {file.type.startsWith("image/") ? (
          <img src={preview} alt={file.name} className="preview-image" />
        ) : (
          <div className="d-flex flex-column align-items-center">
            <Video size={48} className="text-muted mb-2" />
            <span
              className="small text-muted text-truncate"
              style={{ maxWidth: "120px" }}
            >
              {file.name}
            </span>
          </div>
        )}
      </div>
      <div className="preview-actions">
        <button
          className="preview-btn replace"
          onClick={() => onReplace(index)}
          disabled={disabled}
        >
          <RefreshCw size={14} /> Replace
        </button>
        <button
          className="preview-btn remove"
          onClick={() => onRemove(index)}
          disabled={disabled}
        >
          <Trash2 size={14} /> Remove
        </button>
      </div>
    </div>
  );
};

const UploadMedia = ({ initialParams }) => {
  const { vendor } = useSelector((state) => state.vendorAuth);
  const [tokens, setTokens] = useState([]);
  const [events, setEvents] = useState([]);
  const [analytics, setAnalytics] = useState(null);
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState({});
  const [formData, setFormData] = useState({
    event_id: initialParams?.eventId || "",
    collection: "",
    visibility: "",
    token: "",
  });

  useEffect(() => {
    if (initialParams?.eventId) {
      setFormData((prev) => ({ ...prev, event_id: initialParams.eventId }));
      // Scroll to upload section if navigated with eventId
      setTimeout(() => {
        document
          .getElementById("upload-section")
          ?.scrollIntoView({ behavior: "smooth" });
      }, 500);
    }
  }, [initialParams]);
  const [uploadSuccess, setUploadSuccess] = useState(null);
  const [errors, setErrors] = useState({});
  const [isDragging, setIsDragging] = useState(false);
  const [replacingIndex, setReplacingIndex] = useState(null);
  const fileInputRef = useRef(null);
  const replaceInputRef = useRef(null);

  useEffect(() => {
    if (vendor?.id) {
      fetchTokens();
    }
    fetchEvents();
    fetchAnalytics();
  }, [vendor?.id]);

  const fetchEvents = async () => {
    try {
      const response = await axiosInstance.get("/events");
      if (response.data.success) {
        setEvents(response.data.events);
      }
    } catch (error) {
      console.error("Error fetching events:", error);
      toast.error("Failed to load events");
    }
  };

  const fetchTokens = async () => {
    if (!vendor?.id) return;
    try {
      const response = await axiosInstance.get(`/token/vendor/${vendor.id}`);
      console.log("Res", response.data);
      if (response.data.success) {
        setTokens(response.data.tokens);
      }
    } catch (error) {
      console.error("Error fetching tokens:", error);
      toast.error("Failed to load tokens");
    }
  };

  const fetchAnalytics = async () => {
    try {
      const response = await axiosInstance.get("/vendor/dashboard/analytics");
      if (response.data.success) {
        setAnalytics(response.data);
      }
    } catch (error) {
      console.error("Error fetching analytics:", error);
      toast.error("Failed to load storage information");
    }
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setIsDragging(false);
    const files = Array.from(e.dataTransfer.files);
    handleFileSelection(files);
  };

  const handleFileInput = (e) => {
    const files = Array.from(e.target.files);
    handleFileSelection(files);
  };

  const handleReplaceClick = (index) => {
    setReplacingIndex(index);
    replaceInputRef.current?.click();
  };

  const handleReplaceInput = (e) => {
    const file = e.target.files[0];
    if (file && replacingIndex !== null) {
      const isImage = file.type.startsWith("image/");
      const isVideo = file.type.startsWith("video/");
      const sizeMB = file.size / (1024 * 1024);

      if ((isImage || isVideo) && sizeMB <= 100) {
        setSelectedFiles((prev) => {
          const newFiles = [...prev];
          newFiles[replacingIndex] = file;
          return newFiles;
        });
      } else {
        toast.warning("Invalid file type or size > 100MB");
      }
    }
    setReplacingIndex(null);
    e.target.value = "";
  };

  const handleFileSelection = (files) => {
    const validFiles = [];
    const invalidFiles = [];

    files.forEach((file) => {
      const isImage = file.type.startsWith("image/");
      const isVideo = file.type.startsWith("video/");
      const sizeMB = file.size / (1024 * 1024);

      if ((isImage || isVideo) && sizeMB <= 100) {
        validFiles.push(file);
      } else {
        invalidFiles.push(file.name);
      }
    });

    if (invalidFiles.length > 0) {
      toast.warning(`Some files were skipped (invalid type or > 100MB)`);
    }

    const totalSize =
      [...selectedFiles, ...validFiles].reduce((acc, f) => acc + f.size, 0) /
      (1024 * 1024);

    if (analytics && totalSize > analytics.package.remainingMB) {
      setErrors({ storage: "Not enough storage space for these files" });
      toast.error("Storage limit exceeded");
      return;
    }

    setSelectedFiles((prev) => [...prev, ...validFiles]);
    setErrors((prev) => ({ ...prev, storage: "" }));
  };

  const removeFile = (index) => {
    setSelectedFiles((prev) => prev.filter((_, i) => i !== index));
    setUploadProgress((prev) => {
      const newProgress = { ...prev };
      delete newProgress[index];
      return newProgress;
    });
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    setErrors((prev) => ({ ...prev, [name]: "" }));
  };

  const validateForm = () => {
    const newErrors = {};
    if (!formData.event_id) newErrors.event_id = "Event ID is required";
    if (!formData.collection) newErrors.collection = "Collection is required";
    if (!formData.visibility) newErrors.visibility = "Visibility is required";
    if (!formData.token) newErrors.token = "Token is required";
    if (selectedFiles.length === 0)
      newErrors.files = "Please select at least one file";

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleUpload = async () => {
    if (!validateForm()) {
      toast.error("Please fill all required fields");
      return;
    }

    if (!analytics?.usage?.canUpload) {
      toast.error("Storage limit reached. Cannot upload files.");
      return;
    }

    setUploading(true);
    setUploadSuccess(null);

    const uploadData = new FormData();
    uploadData.append("vendorId", vendor?.id || "");
    uploadData.append("event_id", formData.event_id);
    uploadData.append("collection", formData.collection);
    uploadData.append("visibility", formData.visibility);
    uploadData.append("token", formData.token);

    selectedFiles.forEach((file, index) => {
      uploadData.append("files", file);
    });

    try {
      const response = await axiosInstance.post(
        "/vendor/upload-media",
        uploadData,
        {
          headers: {
            "Content-Type": "multipart/form-data",
          },
          onUploadProgress: (progressEvent) => {
            const percentCompleted = Math.round(
              (progressEvent.loaded * 100) / progressEvent.total,
            );
            setUploadProgress({ overall: percentCompleted });
          },
        },
      );

      if (response.data.success) {
        setUploadSuccess({
          count: selectedFiles.length,
          totalSize: (
            selectedFiles.reduce((acc, f) => acc + f.size, 0) /
            (1024 * 1024)
          ).toFixed(2),
        });
        toast.success(`Successfully uploaded ${selectedFiles.length} file(s)`);

        // Reset form
        setSelectedFiles([]);
        setFormData({
          event_id: "",
          collection: "",
          visibility: "",
          token: "",
        });
        setUploadProgress({});

        // Refresh analytics
        fetchAnalytics();
      }
    } catch (error) {
      console.error("Upload error:", error);
      toast.error(
        error.response?.data?.message || "Upload failed. Please try again.",
      );
    } finally {
      setUploading(false);
    }
  };

  const getFileIcon = (file) => {
    return file.type.startsWith("image/") ? (
      <Image size={16} />
    ) : (
      <Video size={16} />
    );
  };

  const formatFileSize = (bytes) => {
    return (bytes / (1024 * 1024)).toFixed(2);
  };

  const totalSelectedSize =
    selectedFiles.reduce((acc, f) => acc + f.size, 0) / (1024 * 1024);
  const canUpload =
    analytics?.usage?.canUpload && selectedFiles.length > 0 && !uploading;

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text);
    toast.success("Token copied to clipboard!");
  };

  const formatDate = (dateString) => {
    if (!dateString) return "N/A";
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const getStatusBadge = (status) => {
    switch (status) {
      case "active":
        return (
          <span className="status-badge status-active">
            <CheckCircle size={14} /> Active
          </span>
        );
      case "disabled":
        return (
          <span className="status-badge status-disabled">
            <EyeOff size={14} /> Disabled
          </span>
        );
      case "expired":
        return (
          <span className="status-badge status-inactive">
            <AlertCircle size={14} /> Expired
          </span>
        );
      default:
        return <span className="status-badge status-inactive">{status}</span>;
    }
  };

  return (
    <div className="tokens-container">
      {/* Header */}
      <div className="tokens-header">
        <div>
          <h3 className="page-title inter">Upload Media</h3>
          <p className="page-subtitle inter">
            Select a token and upload media to your event collections
          </p>
        </div>
      </div>

      {/* Storage Info Cards */}
      {analytics && (
        <div className="stats-row">
          <div className="stat-box">
            <div className="stat-icon-wrapper inter">
              <HardDrive size={20} />
            </div>
            <div>
              <p className="stat-box-label text-start inter">Storage Used</p>
              <h3 className="stat-box-value inter">
                {analytics.package.usedMB}{" "}
                <span className="fs-6 text-muted inter">MB</span>
              </h3>
            </div>
          </div>
          <div className="stat-box">
            <div className="stat-icon-wrapper inter">
              <CheckCircle size={20} />
            </div>
            <div>
              <p className="stat-box-label text-start inter">Remaining</p>
              <h3
                className={`stat-box-value ${
                  analytics.package.remainingMB < 100
                    ? "text-danger inter"
                    : "text-success inter"
                }`}
              >
                {analytics.package.remainingMB.toFixed(2)}{" "}
                <span className="fs-6 text-success inter">MB</span>
              </h3>
            </div>
          </div>
          <div className="stat-box">
            <div className="stat-icon-wrapper inter">
              <Video size={20} />
            </div>
            <div>
              <p className="stat-box-label text-start inter">Limit</p>
              <h3 className="stat-box-value inter">
                {analytics.package.limitMB}{" "}
                <span className="fs-6 text-muted inter">MB</span>
              </h3>
            </div>
          </div>
        </div>
      )}

      {/* Token List */}
      <div className="table-card mb-4">
        <div className="p-3 border-bottom bg-light inter">
          <h3 className="mb-0 fw-bold inter">Select a Token to Upload</h3>
        </div>
        <div className="table-responsive inter">
          <table className="tokens-table">
            <thead>
              <tr>
                <th>Token Code</th>
                <th>Type</th>
                <th>Event ID</th>
                <th>Status</th>
                <th>Created At</th>
                <th>Expires At</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody className="inter">
              {tokens.length > 0 ? (
                tokens.map((token) => (
                  <tr key={token.id} className="token-row">
                    <td>
                      <div className="token-code-cell">
                        <Key size={16} />
                        <code className="token-code inter">{token.token}</code>
                      </div>
                    </td>
                    <td>
                      <span className={`inter badge badge-${token.type}`}>
                        {token.type}
                      </span>
                    </td>
                    <td>
                      <div className="event-cell inter">
                        <Calendar size={14} className="me-1 inter" />
                        Event #{token.event_id}
                      </div>
                    </td>
                    <td className="inter">{getStatusBadge(token.status)}</td>
                    <td>
                      <div className="created-cell inter">
                        {formatDate(token.created_at)}
                      </div>
                    </td>
                    <td>
                      <div className="expiry-cell inter">
                        {token.expires_at ? (
                          <div className="d-flex align-items-center gap-1 inter">
                            <Clock size={14} />
                            {formatDate(token.expires_at)}
                          </div>
                        ) : (
                          <span className="text-muted inter">No expiry</span>
                        )}
                      </div>
                    </td>
                    <td>
                      <button
                        className="btn-primary py-1 px-3 fs-6 inter"
                        onClick={() => {
                          setFormData((prev) => ({
                            ...prev,
                            token: token.token,
                            event_id: token.event_id || "",
                          }));
                          document
                            .getElementById("upload-section")
                            ?.scrollIntoView({ behavior: "smooth" });
                        }}
                        disabled={token.status !== "active"}
                      >
                        Use for Upload
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="7" className="text-center py-5">
                    <div className="empty-state-content">
                      <AlertCircle size={48} className="text-muted mb-3" />
                      <h4 className="text-muted">No tokens found</h4>
                      <p className="text-muted">
                        Create a token in the Tokens & Sharing page first.
                      </p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Mobile View for Tokens */}
        <div className="mobile-tokens">
          {tokens.map((token) => (
            <div key={token.id} className="mobile-token-card">
              <div className="mobile-token-header">
                <div className="token-code-cell">
                  <Key className="me-2" />
                  <code className="token-code">{token.token}</code>
                </div>
                {getStatusBadge(token.status)}
              </div>

              <div className="mobile-token-body">
                <div className="mobile-info-row">
                  <span className="mobile-label">Type:</span>
                  <span className={`badge badge-${token.type}`}>
                    {token.type}
                  </span>
                </div>
                <div className="mobile-info-row">
                  <span className="mobile-label">Event:</span>
                  <span>Event #{token.event_id}</span>
                </div>
                <div className="mobile-info-row">
                  <span className="mobile-label">Created:</span>
                  <span>{formatDate(token.created_at)}</span>
                </div>
                <div className="mobile-info-row">
                  <span className="mobile-label">Expires:</span>
                  <span>
                    {token.expires_at
                      ? formatDate(token.expires_at)
                      : "No expiry"}
                  </span>
                </div>
              </div>

              <div className="mobile-token-actions">
                <button
                  className="action-btn-mobile w-100 justify-content-center text-primary border-primary inter"
                  onClick={() => {
                    setFormData((prev) => ({
                      ...prev,
                      token: token.token,
                      event_id: token.event_id || "",
                    }));
                    document
                      .getElementById("upload-section")
                      ?.scrollIntoView({ behavior: "smooth" });
                  }}
                  disabled={token.status !== "active"}
                >
                  Use for Upload
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Success Message */}
      {uploadSuccess && (
        <div className="row mb-4 inter">
          <div className="col-12">
            <div
              className="alert alert-success border d-flex align-items-center"
              role="alert"
            >
              <CheckCircle size={20} className="me-2" />
              <div>
                Successfully uploaded <strong>{uploadSuccess.count}</strong>{" "}
                file(s) ({uploadSuccess.totalSize} MB)
              </div>
            </div>
          </div>
        </div>
      )}

      <div id="upload-section" className="table-card">
        <div className="p-3 border-bottom bg-light">
          <h3 className="mb-0 fw-bold inter">Upload Files</h3>
        </div>
        <div className="p-4">
          {/* Form Fields */}
          <div className="row g-4 mb-4">
            <div className="col-md-6">
              <label className="form-label fw-bold inter">
                Event <span className="text-danger">*</span>
              </label>
              <div className="input-group">
                <span className="input-group-text bg-white inter">
                  <Calendar size={18} className="text-muted" />
                </span>
                <select
                  className={`form-select inter ${
                    errors.event_id ? "is-invalid" : ""
                  }`}
                  name="event_id"
                  value={formData.event_id}
                  onChange={(e) => {
                    handleInputChange(e);
                    // Clear token when event changes
                    setFormData((prev) => ({ ...prev, token: "" }));
                  }}
                >
                  <option value="">Select Event</option>
                  {events.map((event) => (
                    <option key={event.id} value={event.id}>
                      {event.name} (
                      {new Date(event.event_date).toLocaleDateString()})
                    </option>
                  ))}
                </select>
              </div>
              {errors.event_id && (
                <div className="text-danger small mt-1">{errors.event_id}</div>
              )}
            </div>

            <div className="col-md-6">
              <label className="form-label fw-bold inter">
                Collection <span className="text-danger">*</span>
              </label>
              <input
                type="text"
                className={`form-control inter ${
                  errors.collection ? "is-invalid" : ""
                }`}
                name="collection"
                value={formData.collection}
                onChange={handleInputChange}
                placeholder="Enter collection name"
              />
              {errors.collection && (
                <div className="text-danger small mt-1">
                  {errors.collection}
                </div>
              )}
            </div>

            <div className="col-md-6">
              <label className="form-label fw-bold inter">
                Visibility <span className="text-danger">*</span>
              </label>
              <select
                className={`form-select inter ${
                  errors.visibility ? "is-invalid" : ""
                }`}
                name="visibility"
                value={formData.visibility}
                onChange={handleInputChange}
              >
                <option value="">Select visibility</option>
                <option value="public">Public</option>
                <option value="private">Private</option>
              </select>
              {errors.visibility && (
                <div className="text-danger small mt-1">
                  {errors.visibility}
                </div>
              )}
            </div>

            <div className="col-md-6">
              <label className="form-label fw-bold inter">
                Token <span className="text-danger">*</span>
              </label>
              <div className="input-group">
                <span className="input-group-text bg-white inter">
                  <Key size={18} className="text-muted" />
                </span>
                <select
                  className={`form-select inter ${
                    errors.token ? "is-invalid" : ""
                  }`}
                  name="token"
                  value={formData.token}
                  onChange={handleInputChange}
                >
                  <option value="">Select token</option>
                  {tokens
                    .filter(
                      (t) =>
                        !formData.event_id ||
                        t.event_id?.toString() === formData.event_id.toString(),
                    )
                    .map((token) => (
                      <option key={token.id} value={token.token}>
                        {token.token} ({token.type})
                      </option>
                    ))}
                </select>
              </div>
              {errors.token && (
                <div className="text-danger small mt-1">{errors.token}</div>
              )}
              <div className="form-text">
                You can also select a token from the table above.
              </div>
            </div>
          </div>

          {/* Hidden Replace Input */}
          <input
            ref={replaceInputRef}
            type="file"
            accept="image/*,video/*"
            onChange={handleReplaceInput}
            className="d-none"
          />

          {/* Drag and Drop Area */}
          <div
            className={`upload-zone ${isDragging ? "active" : ""} ${
              errors.files ? "border-danger" : ""
            } ${!analytics?.usage?.canUpload ? "opacity-50" : ""}`}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
            onClick={() =>
              analytics?.usage?.canUpload && fileInputRef.current?.click()
            }
            style={{
              cursor: analytics?.usage?.canUpload ? "pointer" : "not-allowed",
            }}
          >
            <input
              ref={fileInputRef}
              type="file"
              multiple
              accept="image/*,video/*"
              onChange={handleFileInput}
              className="d-none"
              disabled={!analytics?.usage?.canUpload}
            />
            <div className="upload-content text-center">
              <div className="upload-icon-wrapper mb-3">
                <Upload size={32} className="text-primary" />
              </div>
              <h5 className="mb-2">Click or drag files to upload</h5>
              <p className="text-muted small mb-0">
                Supported: Images and Videos (max 100MB each)
              </p>
              {!analytics?.usage?.canUpload && (
                <div className="mt-2">
                  <small className="text-danger fw-semibold">
                    Storage limit reached
                  </small>
                </div>
              )}
            </div>
          </div>

          {errors.files && (
            <div className="text-danger small mt-2">{errors.files}</div>
          )}

          {errors.storage && (
            <div
              className="alert alert-danger border mt-3 d-flex align-items-center"
              role="alert"
            >
              <AlertCircle size={20} className="me-2" />
              {errors.storage}
            </div>
          )}

          {/* Selected Files Grid */}
          {selectedFiles.length > 0 && (
            <div className="mt-4">
              <div className="d-flex justify-content-between align-items-center mb-3">
                <h6 className="fw-bold mb-0">
                  Selected Files ({selectedFiles.length})
                </h6>
                <div className="d-flex align-items-center gap-3">
                  <small className="text-muted">
                    Total: {totalSelectedSize.toFixed(2)} MB
                  </small>
                  <button
                    className="btn btn-sm btn-outline-danger"
                    onClick={() => setSelectedFiles([])}
                    disabled={uploading}
                  >
                    Clear All
                  </button>
                </div>
              </div>

              <div className="upload-preview-grid">
                {selectedFiles.map((file, index) => (
                  <FilePreview
                    key={`${file.name}-${index}`}
                    file={file}
                    index={index}
                    onReplace={handleReplaceClick}
                    onRemove={removeFile}
                    disabled={uploading}
                  />
                ))}
              </div>

              {/* Upload Progress */}
              {uploading && uploadProgress.overall !== undefined && (
                <div className="mt-4">
                  <div className="d-flex justify-content-between mb-1">
                    <span className="small fw-bold">Uploading...</span>
                    <span className="small">{uploadProgress.overall}%</span>
                  </div>
                  <div className="progress" style={{ height: "8px" }}>
                    <div
                      className="progress-bar progress-bar-striped progress-bar-animated"
                      role="progressbar"
                      style={{ width: `${uploadProgress.overall}%` }}
                    ></div>
                  </div>
                </div>
              )}

              <div className="mt-4 text-end">
                <button
                  className="btn btn-primary px-4 py-2"
                  onClick={handleUpload}
                  disabled={!canUpload}
                >
                  {uploading ? (
                    <>
                      <span
                        className="spinter-border spinter-border-sm me-2"
                        role="status"
                        aria-hidden="true"
                      ></span>
                      Uploading...
                    </>
                  ) : (
                    <>
                      <Upload size={18} className="me-2" />
                      Upload {selectedFiles.length} Files
                    </>
                  )}
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default UploadMedia;
