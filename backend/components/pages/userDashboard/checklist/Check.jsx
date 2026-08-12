import { useState, useEffect } from "react";
import {
  FaCheck,
  FaPlus,
  FaDownload,
  FaPrint,
  FaCalendarAlt,
  FaHeart,
  FaTimes,
} from "react-icons/fa";
import { FiCheck, FiTrash, FiLink, FiEdit, FiClock } from "react-icons/fi";
import axiosInstance from "../../../../services/api/axiosInstance";
import axios from "axios";
import { useSelector } from "react-redux";
import { Link } from "react-router-dom";
import Swal from "sweetalert2";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";
import dayjs from "dayjs";
import { pdf } from "@react-pdf/renderer";
import ChecklistPDF from "./ChecklistPDF";
import { FaSpinner } from "react-icons/fa6";
import { Dropdown } from "react-bootstrap";

const CATEGORY_API =
  "https://happywedz.com/api/vendor-types/with-subcategories/all";

const Check = () => {
  const user = useSelector((state) => state.auth.user);
  const token = useSelector((state) => state.auth.token);
  const userId = user?.id || user?.user_id || user?._id;

  const [checklists, setChecklists] = useState([]);
  const [text, setText] = useState("");
  const [vendorSubId, setVendorSubId] = useState("");
  const [categories, setCategories] = useState([]);
  const [startDate, setStartDate] = useState("");
  // Initialize wedding date from Redux user data
  const [weddingDate, setWeddingDate] = useState(
    user?.weddingDate ? String(user.weddingDate).slice(0, 10) : ""
  );
  const [loading, setLoading] = useState(false);

  // Handler for start date change
  const handleStartDateChange = (newDate) => {
    const formattedDate = newDate ? dayjs(newDate).format("YYYY-MM-DD") : "";
    setStartDate(formattedDate);
  };

  // Handler for wedding date change
  const handleWeddingDateChange = (newDate) => {
    const formattedDate = newDate ? dayjs(newDate).format("YYYY-MM-DD") : "";
    setWeddingDate(formattedDate);
  };
  const [refresh, setRefresh] = useState(false);
  const [error, setError] = useState(null);
  const [daysLeft, setDaysLeft] = useState(null);
  const [requiredDays, setRequiredDays] = useState(0);
  const [timeOptions, setTimeOptions] = useState([]);
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;
  const [editingId, setEditingId] = useState(null);
  const [editingText, setEditingText] = useState("");
  const [updateLoading, setUpdateLoading] = useState(false);

  const fetchChecklists = async () => {
    if (!userId || !token) return;
    setLoading(true);
    try {
      const res = await axiosInstance.get(
        `/new-checklist/newChecklist/user/${userId}`
      );
      const fetchedChecklists = res.data?.data || [];
      setChecklists(fetchedChecklists);
      if (res.data?.data?.length > 0) {
        const firstTask = res.data.data[0];
        if (firstTask.start_date)
          setStartDate(firstTask.start_date.split("T")[0]);
        if (firstTask.wedding_date)
          setWeddingDate(firstTask.wedding_date.split("T")[0]);
      }
    } catch (err) {
      console.error("Error fetching checklists:", err);
      setError("Failed to load checklist data");
    } finally {
      setLoading(false);
    }
  };

  const fetchCategories = async () => {
    try {
      const res = await axios.get(CATEGORY_API);
      const allSubs = res.data.flatMap((cat) =>
        cat.subcategories.map((sub) => ({
          id: sub.id,
          name: sub.name,
          required_days: sub.required_days || 2,
          category: { id: cat.id, name: cat.name },
        }))
      );
      setCategories(allSubs);
    } catch (err) {
      console.error("Error fetching categories:", err);
    }
  };

  // Sync wedding date from Redux when user data changes
  useEffect(() => {
    if (user?.weddingDate) {
      const formattedDate = String(user.weddingDate).slice(0, 10);
      setWeddingDate(formattedDate);
    }
  }, [user?.weddingDate]);

  useEffect(() => {
    if (weddingDate) {
      const today = new Date();
      const wedding = new Date(weddingDate);
      const diffTime = wedding - today;
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
      setDaysLeft(diffDays);
    }
  }, [weddingDate]);

  useEffect(() => {
    fetchChecklists();
    fetchCategories();
  }, [userId, refresh]);

  useEffect(() => {
    if (vendorSubId && categories.length) {
      const selected = categories.find((c) => c.id === parseInt(vendorSubId));
      setRequiredDays(selected?.required_days || 0);
    }
  }, [vendorSubId, categories]);

  useEffect(() => {
    if (startDate && weddingDate && requiredDays > 0) {
      const s = new Date(startDate);
      const w = new Date(weddingDate);
      const totalDays = Math.ceil((w - s) / (1000 * 60 * 60 * 24));

      if (totalDays < 8) {
        setTimeOptions(["Wedding too near (<8 days)"]);
        return;
      }

      const endDate = new Date(s);
      endDate.setDate(endDate.getDate() + requiredDays);

      setTimeOptions([
        `${requiredDays} days required`,
        `Start: ${s.toLocaleDateString()}`,
        `End: ${endDate.toLocaleDateString()}`,
        `Remaining buffer: ${totalDays - requiredDays} days`,
      ]);
    }
  }, [startDate, weddingDate, requiredDays]);

  const [distributedTasks, setDistributedTasks] = useState([]);

  useEffect(() => {
    if (!startDate || !weddingDate || checklists.length === 0) {
      setDistributedTasks([]);
      return;
    }

    const start = new Date(startDate);
    const end = new Date(weddingDate);
    const totalDays = Math.max(
      1,
      Math.ceil((end - start) / (1000 * 60 * 60 * 24))
    );
    const perTaskDays = Math.max(1, Math.floor(totalDays / checklists.length));

    const temp = [];
    let current = new Date(start);

    for (let i = 0; i < checklists.length; i++) {
      const taskStart = new Date(current);
      const taskEnd = new Date(current);
      taskEnd.setDate(taskEnd.getDate() + perTaskDays - 1);
      temp.push({
        ...checklists[i],
        days_assigned: perTaskDays,
        distributed_start_date: taskStart.toLocaleDateString(),
        distributed_end_date: taskEnd.toLocaleDateString(),
      });
      current.setDate(current.getDate() + perTaskDays);
    }
    setDistributedTasks(temp);
  }, [checklists, startDate, weddingDate]);

  const addChecklist = async () => {
    setError(null);

    if (!text || !vendorSubId) {
      setError("Please fill all fields before adding a task.");
      return;
    }

    if (!startDate || !weddingDate) {
      setError("Please select start and wedding dates first.");
      return;
    }

    const sDate = new Date(startDate);
    const wDate = new Date(weddingDate);
    if (wDate < sDate) {
      setError("Wedding date cannot be before start date.");
      return;
    }

    const today = new Date();
    const wedding = new Date(weddingDate);
    const diffDays = Math.ceil((wedding - today) / (1000 * 60 * 60 * 24));

    if (diffDays < 8) {
      setError(
        "Your wedding is near! Checklist cannot be created (less than 8 days left)."
      );
      return;
    }

    const payload = {
      userId,
      vendor_subcategory_id: vendorSubId,
      text,
      start_date: startDate,
      wedding_date: weddingDate,
      status: "pending",
    };

    try {
      await axiosInstance.post(`/new-checklist/create`, payload);
      setText("");
      setVendorSubId("");
      setRefresh((prev) => !prev);
    } catch (err) {
      console.error("Error adding checklist:", err);
      setError("Failed to create checklist.");
    }
  };

  const handleEdit = (id, currentText) => {
    setEditingId(id);
    setEditingText(currentText);
  };

  const saveEdit = async () => {
    if (!editingText.trim()) {
      setError("Task name cannot be empty.");
      return;
    }

    setUpdateLoading(true);
    try {
      await axiosInstance.put(`/new-checklist/update/${editingId}`, {
        text: editingText,
      });
      setEditingId(null);
      setEditingText("");
      setRefresh((prev) => !prev);
    } catch (err) {
      console.error("Error updating checklist:", err);
      setError("Failed to update task.");
    } finally {
      setUpdateLoading(false);
    }
  };

  const cancelEdit = () => {
    setEditingId(null);
    setEditingText("");
  };

  const toggleStatus = async (id, currentStatus) => {
    try {
      const newStatus = currentStatus === "completed" ? "pending" : "completed";
      await axiosInstance.put(`/new-checklist/update/${id}`, {
        status: newStatus,
      });
      setRefresh((prev) => !prev);
    } catch (err) {
      setError("Failed to update checklist.");
    }
  };

  const deleteChecklist = async (id) => {
    try {
      await axiosInstance.delete(`/new-checklist/delete/${id}`);
      setRefresh((prev) => !prev);
    } catch (err) {
      setError("Failed to delete checklist.");
    }
  };

  const handleDownloadPDF = async () => {
    const itemsToDownload =
      Array.isArray(distributedTasks) && distributedTasks.length > 0
        ? distributedTasks
        : Array.isArray(checklists)
          ? checklists
          : [];

    if (itemsToDownload.length === 0) {
      Swal.fire({
        icon: "info",
        text: "No tasks to download.",
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
      return;
    }

    try {
      Swal.fire({
        title: "Generating PDF...",
        allowOutsideClick: false,
        didOpen: () => {
          Swal.showLoading();
        },
      });

      const doc = (
        <ChecklistPDF
          items={itemsToDownload}
          categories={Array.isArray(categories) ? categories : []}
          meta={{
            userName: user?.name || user?.email || "User",
            generatedAt: new Date(),
          }}
        />
      );

      const asPdf = pdf(doc);
      const blob = await asPdf.toBlob();

      const url = window.URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.setAttribute("download", `checklist-${userId || "user"}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);

      Swal.close();
      Swal.fire({
        icon: "success",
        text: "Checklist downloaded successfully!",
        timer: 2000,
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
    } catch (err) {
      console.error("Download Error:", err);
      Swal.close();
      Swal.fire({
        icon: "error",
        text: "Could not download the checklist. Please try again.",
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
    }
  };

  const completedCount = checklists.filter(
    (c) => c.status === "completed"
  ).length;
  const progressPercentage =
    checklists.length > 0 ? (completedCount / checklists.length) * 100 : 0;

  const currentTasks =
    distributedTasks.length > 0 ? distributedTasks : checklists;
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  const currentItems = currentTasks.slice(indexOfFirstItem, indexOfLastItem);
  const totalPages = Math.ceil(currentTasks.length / itemsPerPage);
  const paginate = (pageNumber) => setCurrentPage(pageNumber);

  return (
    <>
      <div className="checklist-container">
        <div className="container">
          <div className="row">
            {/* Sidebar */}
            <div className="col-lg-4 mb-4">
              <div className="stat-card border border-black">
                <div className="stat-card-header fs-16">
                  <FiClock size={20} />
                  <span>Task Status</span>
                </div>
                <div className="status-item d-flex justify-content-between align-items-center fs-14">
                  <span style={{ fontWeight: "600", color: "#374151" }}>
                    Pending Tasks
                  </span>
                  <span className="status-badge text-danger">
                    {checklists.filter((c) => c.status === "pending").length}
                  </span>
                </div>
                <div className="status-item d-flex justify-content-between align-items-center fs-14">
                  <span style={{ fontWeight: "600", color: "#374151" }}>
                    Completed Tasks
                  </span>
                  <span className="status-badge">{completedCount}</span>
                </div>
              </div>

              {/* Wedding Dates Card */}
              <div className="stat-card border border-black">
                <div className="stat-card-header fs-16">
                  <FaCalendarAlt size={18} />
                  <span>Wedding Timeline</span>
                </div>
                <div className="date-input-group fs-16">
                  <label>
                    <FaCalendarAlt size={14} />
                    Start Date
                  </label>
                  <LocalizationProvider
                    className="fs-14"
                    dateAdapter={AdapterDayjs}
                  >
                    <DatePicker
                      value={startDate ? dayjs(startDate) : null}
                      onChange={handleStartDateChange}
                      className="fs-14"
                      disabled={checklists.length > 0 && !!startDate}
                      slotProps={{
                        textField: {
                          fullWidth: true,
                          size: "small",
                          placeholder: "Select start date",
                          className: "fs-14",
                          InputProps: { style: { fontSize: 14 } },
                          inputProps: { style: { fontSize: 14 } },
                        },
                      }}
                    />
                  </LocalizationProvider>
                </div>
                <div className="date-input-group fs-14">
                  <label>
                    <FaHeart size={14} />
                    Wedding Date
                  </label>
                  <LocalizationProvider dateAdapter={AdapterDayjs}>
                    <DatePicker
                      value={weddingDate ? dayjs(weddingDate) : null}
                      onChange={handleWeddingDateChange}
                      disabled={checklists.length > 0 && !!weddingDate}
                      slotProps={{
                        textField: {
                          fullWidth: true,
                          size: "small",
                          placeholder: "Select wedding date",
                          InputProps: { style: { fontSize: 14 } },
                          inputProps: { style: { fontSize: 14 } },
                        },
                      }}
                    />
                  </LocalizationProvider>
                </div>

                {daysLeft !== null && (
                  <div className="days-countdown">
                    <h3 className="days-number">{Math.abs(daysLeft)}</h3>
                    <span className="days-text fs-16 fw-bold">
                      {daysLeft > 0
                        ? "Days Until Wedding"
                        : daysLeft === 0
                          ? "Wedding Day!"
                          : "Days Since Wedding"}
                    </span>
                  </div>
                )}
              </div>
            </div>

            {/* Main Content */}
            <div className="col-lg-8">
              <div className="main-card">
                <div className="main-card-header d-flex justify-content-between align-items-center flex-wrap">
                  <h5>
                    <FaHeart />
                    Wedding Checklist
                  </h5>
                  <div className="header-actions d-flex gap-2 fs-14 my-4">
                    {(distributedTasks && distributedTasks.length > 0) ||
                      (checklists && checklists.length > 0) ? (
                      <button
                        className="btn fs-14"
                        onClick={handleDownloadPDF}
                      >
                        <FaDownload className="me-1" size={12} />
                        Download
                      </button>
                    ) : (
                      <button
                        className="btn fs-14"
                        disabled
                        title="No tasks to download"
                      >
                        <FaDownload className="me-1" />
                        Download
                      </button>
                    )}
                  </div>
                </div>

                <div className="card-body p-4">
                  {/* Progress Section */}
                  <div className="progress-section">
                    <h6>Overall Progress</h6>
                    <div className="progress-bar-wrapper">
                      <div
                        className="progress-bar-fill"
                        style={{ width: `${progressPercentage}%` }}
                      />
                    </div>
                    <div className="progress-stats">
                      <span>
                        <strong>{completedCount}</strong> completed
                      </span>
                      <span>
                        <strong>{checklists.length}</strong> total tasks
                      </span>
                      <span>
                        <strong>{Math.round(progressPercentage)}%</strong>{" "}
                        complete
                      </span>
                    </div>
                  </div>

                  {error && (
                    <div
                      className="alert alert-danger alert-custom alert-dismissible fade show fs-14 fw-bold"
                      role="alert"
                    >
                      {error}
                      <button
                        type="button"
                        className="btn-close"
                        onClick={() => setError(null)}
                      />
                    </div>
                  )}

                  {/* Add Task Form */}
                  <div className="add-task-card">
                    <h6 className="fs-16">Add New Task</h6>
                    <div className="row align-items-end gy-3">
                      <div className="col-12 col-md-11">
                        <div className="row gy-3">
                          <div className="col-12 col-md-6">
                            <label
                              className="form-label fs-14"
                              style={{ fontWeight: "600", color: "#374151" }}
                            >
                              Category
                            </label>
                            <Dropdown
                              drop="down"
                              autoClose="outside"
                            >
                              <Dropdown.Toggle className="w-100 fs-14 bg-white text-black text-start d-flex justify-content-between align-items-center">
                                {vendorSubId
                                  ? categories.find((c) => c.id == vendorSubId)
                                    ?.name
                                  : "Select Category"}
                              </Dropdown.Toggle>

                              <Dropdown.Menu
                                className="w-100"
                                style={{
                                  position: "absolute",
                                  inset: "0 auto auto 0",
                                  transform: "translateY(100%) !important",
                                  maxHeight: "200px",
                                  overflowY: "auto",
                                  background: "#fff",
                                  zIndex: 9999,
                                }}
                              >
                                {categories.map((sub) => (
                                  <Dropdown.Item
                                    key={sub.id}
                                    onClick={() => setVendorSubId(sub.id)}
                                    className="fs-14"
                                  >
                                    {sub.name}
                                  </Dropdown.Item>
                                ))}
                              </Dropdown.Menu>
                            </Dropdown>
                          </div>
                          <div className="col-12 col-md-6">
                            <label
                              className="form-label fs-14"
                              style={{ fontWeight: "600", color: "#374151" }}
                            >
                              Task Name
                            </label>
                            <input
                              type="text"
                              className="form-control fs-14"
                              placeholder="Enter task description"
                              value={text}
                              onChange={(e) => setText(e.target.value)}
                            />
                          </div>
                        </div>
                      </div>
                      <div className="col-12 col-md-1 d-flex align-items-center justify-content-center">
                        <button
                          className="btn btn-outline-primary fs-14 w-100 w-md-auto d-flex align-items-center justify-content-center"
                          onClick={addChecklist}
                        >
                          <span className="d-inline d-md-none">Add</span>
                          <FaPlus className="d-none d-md-inline" />
                        </button>
                      </div>
                    </div>
                    {timeOptions.length > 0 && (
                      <div className="time-info">
                        <label>Time Allocation</label>
                        <ul>
                          {timeOptions.map((t, i) => (
                            <li key={i}>{t}</li>
                          ))}
                        </ul>
                      </div>
                    )}
                  </div>

                  {loading ? (
                    <div className="text-center py-5">
                      <div
                        className="spinner-border spinner-custom"
                        role="status"
                      >
                        <span className="visually-hidden">Loading...</span>
                      </div>
                    </div>
                  ) : checklists.length > 0 ? (
                    <>
                      <div className="table-responsive">
                        <table className="table checklist-table">
                          <thead>
                            <tr>
                              <th style={{ width: "80px" }}>Status</th>
                              <th>Task</th>
                              <th>Category</th>
                              <th style={{ width: "140px" }}>Days Assigned</th>
                              <th style={{ width: "120px" }}>Actions</th>
                            </tr>
                          </thead>
                          <tbody>
                            {currentItems.map((item) => (
                              <tr key={item.id}>
                                <td className="text-center">
                                  <div
                                    className={`status-icon ${item.status === "completed"
                                      ? "completed"
                                      : "pending"
                                      }`}
                                    onClick={() =>
                                      toggleStatus(item.id, item.status)
                                    }
                                  >
                                    {item.status === "completed" ? (
                                      <FaCheck size={16} />
                                    ) : (
                                      <FiCheck size={16} />
                                    )}
                                  </div>
                                </td>
                                <td>
                                  {editingId === item.id ? (
                                    <input
                                      type="text"
                                      className="form-control form-control-sm"
                                      value={editingText}
                                      onChange={(e) =>
                                        setEditingText(e.target.value)
                                      }
                                      autoFocus
                                    />
                                  ) : (
                                    <span
                                      style={{
                                        textDecoration:
                                          item.status === "completed"
                                            ? "line-through"
                                            : "none",
                                        color:
                                          item.status === "completed"
                                            ? "#9ca3af"
                                            : "#374151",
                                        fontWeight:
                                          item.status === "completed"
                                            ? "400"
                                            : "600",
                                      }}
                                    >
                                      {item.text}
                                    </span>
                                  )}
                                </td>
                                <td>
                                  {(() => {
                                    const subcategory = categories.find(
                                      (c) => c.id === item.vendor_subcategory_id
                                    );
                                    return (
                                      <div className="d-flex align-items-center gap-2 flex-wrap">
                                        {subcategory?.name || "N/A"}
                                        {subcategory?.required_days && (
                                          <span className="days-badge">
                                            <FiClock size={12} />
                                            {subcategory.required_days}d
                                          </span>
                                        )}
                                      </div>
                                    );
                                  })()}
                                </td>
                                <td>
                                  <span
                                    style={{
                                      fontWeight: "600",
                                      color: "#6b7280",
                                    }}
                                  >
                                    {item.days_assigned || "N/A"}{" "}
                                    {item.days_assigned ? "days" : ""}
                                  </span>
                                </td>
                                <td>
                                  <div className="d-flex gap-2 justify-content-center">
                                    {editingId === item.id ? (
                                      <>
                                        <button
                                          className="btn btn-success btn-sm d-flex align-items-center justify-content-center"
                                          onClick={saveEdit}
                                          disabled={updateLoading}
                                          style={{ width: 32, height: 32 }}
                                        >
                                          {updateLoading ? (
                                            <FaSpinner
                                              className="spin"
                                              size={14}
                                            />
                                          ) : (
                                            <FaCheck size={14} />
                                          )}
                                        </button>

                                        <button
                                          className="btn btn-secondary btn-sm d-flex align-items-center justify-content-center"
                                          onClick={cancelEdit}
                                          disabled={updateLoading}
                                          style={{ width: 32, height: 32 }}
                                        >
                                          <FaTimes size={14} />
                                        </button>
                                      </>
                                    ) : (
                                      <>
                                        <button
                                          className="btn p-2 w-25 border rounded-circle"
                                          onClick={() =>
                                            handleEdit(item.id, item.text)
                                          }
                                        >
                                          <FiEdit size={15} />
                                        </button>
                                        <button
                                          className="btn p-2 w-25 border rounded-circle"
                                          onClick={() =>
                                            deleteChecklist(item.id)
                                          }
                                        >
                                          <FiTrash size={15} />
                                        </button>
                                      </>
                                    )}
                                  </div>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>

                      {totalPages > 1 && (
                        <nav>
                          <ul className="pagination justify-content-center">
                            {Array.from({ length: totalPages }, (_, i) => (
                              <li
                                key={i + 1}
                                className={`page-item ${currentPage === i + 1 ? "active" : ""
                                  }`}
                              >
                                <button
                                  onClick={() => paginate(i + 1)}
                                  className="page-link"
                                >
                                  {i + 1}
                                </button>
                              </li>
                            ))}
                          </ul>
                        </nav>
                      )}
                    </>
                  ) : (
                    <div className="empty-state text-center py-4">
                      <img
                        src="/images/userDashboard/no-task-available.png"
                        alt="No tasks"
                        style={{
                          width: "100%",
                          maxWidth: "220px",
                          opacity: 0.7,
                        }}
                      />
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Check;
