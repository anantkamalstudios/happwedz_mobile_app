import { useState, useEffect, useRef, useMemo } from "react";
import {
  FaCheck,
  FaPlus,
  FaDownload,
  FaPrint,
  FaCalendarAlt,
  FaHeart,
  FaTimes,
  FaEdit,
} from "react-icons/fa";
import { FiCheck, FiTrash, FiLink, FiEdit, FiClock } from "react-icons/fi";
import { FaChevronDown, FaSpinner } from "react-icons/fa6";
import axiosInstance from "../../../../services/api/axiosInstance";
import axios from "axios";
import { useSelector, useDispatch } from "react-redux";
import { updateUserProfile } from "../../../../redux/authSlice";
import { Link } from "react-router-dom";
import Swal from "sweetalert2";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";
import dayjs from "dayjs";
import { pdf } from "@react-pdf/renderer";
import ChecklistPDF from "./ChecklistPDF";
import { formatDate } from "../../../../utils/dateFormat";
import { Dropdown } from "react-bootstrap";
import "./Checklist.css";

const CATEGORY_API =
  "http://localhost:4000/api/vendor-types/with-subcategories/all";

const Check = () => {
  const dispatch = useDispatch();
  const { user, token } = useSelector((state) => state.auth);
  const userId = user?.id || user?.user_id || user?._id;

  const [checklists, setChecklists] = useState([]);
  const [categories, setCategories] = useState([]);
  const [startDate, setStartDate] = useState(() => {
    return (
      localStorage.getItem("saved_start_date") ||
      (userId && localStorage.getItem(`saved_start_date_${userId}`)) ||
      dayjs().format("YYYY-MM-DD")
    );
  });
  const [weddingDate, setWeddingDate] = useState(() => {
    return (
      localStorage.getItem("saved_wedding_date") ||
      (userId && localStorage.getItem(`saved_wedding_date_${userId}`)) ||
      (user?.weddingDate ? String(user.weddingDate).slice(0, 10) : "")
    );
  });
  const [text, setText] = useState("");
  const [vendorSubId, setVendorSubId] = useState("");
  const [loading, setLoading] = useState(false);

  const hasUserEditedDate = useRef(false);

  const parsedStartDate = useMemo(() => (startDate ? dayjs(startDate) : null), [startDate]);
  const parsedWeddingDate = useMemo(() => (weddingDate ? dayjs(weddingDate) : null), [weddingDate]);

  // Handler for start date change
  const handleStartDateChange = async (newDate) => {
    const formattedDate = newDate ? dayjs(newDate).format("YYYY-MM-DD") : "";
    hasUserEditedDate.current = true;
    setStartDate(formattedDate);
    localStorage.setItem("saved_start_date", formattedDate);
    if (userId) {
      localStorage.setItem(`saved_start_date_${userId}`, formattedDate);
    }
    if (userId && formattedDate) {
      try {
        await axiosInstance.put(`/new-checklist/update-wedding-date`, {
          userId,
          weddingDate,
          startDate: formattedDate,
        });
      } catch (e) {
        console.warn("Could not save start date to backend:", e);
      }
    }
  };

  // Handler for wedding date change
  const handleWeddingDateChange = async (newDate) => {
    const formattedDate = newDate ? dayjs(newDate).format("YYYY-MM-DD") : "";
    hasUserEditedDate.current = true;
    setWeddingDate(formattedDate);
    localStorage.setItem("saved_wedding_date", formattedDate);
    if (userId) {
      localStorage.setItem(`saved_wedding_date_${userId}`, formattedDate);
    }
    dispatch(updateUserProfile({ weddingDate: formattedDate }));
    if (userId && formattedDate) {
      try {
        await axiosInstance.put(`/new-checklist/update-wedding-date`, {
          userId,
          weddingDate: formattedDate,
          startDate,
        });
      } catch (e) {
        console.warn("Could not save wedding date to backend:", e);
      }
    }
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
  const [editingDays, setEditingDays] = useState(1);
  const [customTaskDays, setCustomTaskDays] = useState({});
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
      if (res.data?.data?.length > 0 && !hasUserEditedDate.current) {
        const firstTask = res.data.data[0];
        const localSavedStart = userId ? localStorage.getItem(`saved_start_date_${userId}`) : null;
        const localSavedWedding = userId ? localStorage.getItem(`saved_wedding_date_${userId}`) : null;
        if (!localSavedStart && firstTask.start_date && !startDate)
          setStartDate(firstTask.start_date.split("T")[0]);
        if (!localSavedWedding && firstTask.wedding_date && !weddingDate)
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

  // Sync dates when userId loads or rehydrates from Redux
  useEffect(() => {
    const savedStart = (userId && localStorage.getItem(`saved_start_date_${userId}`)) || localStorage.getItem("saved_start_date");
    const savedWedding = (userId && localStorage.getItem(`saved_wedding_date_${userId}`)) || localStorage.getItem("saved_wedding_date");

    if (savedStart) setStartDate(savedStart);
    if (savedWedding) setWeddingDate(savedWedding);
  }, [userId]);

  const [countdown, setCountdown] = useState(null);

  useEffect(() => {
    if (!weddingDate) {
      setDaysLeft(null);
      setCountdown(null);
      return;
    }

    const calculateCountdown = () => {
      const now = new Date();
      const target = new Date(weddingDate);
      const diff = target.getTime() - now.getTime();

      if (diff > 0) {
        const days = Math.floor(diff / (1000 * 60 * 60 * 24));
        const hours = Math.floor(
          (diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)
        );
        const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((diff % (1000 * 60)) / 1000);
        setDaysLeft(days);
        setCountdown({ days, hours, minutes, seconds, hasPassed: false });
      } else {
        const diffDays = Math.ceil(Math.abs(diff) / (1000 * 60 * 60 * 24));
        setDaysLeft(-diffDays);
        setCountdown({
          days: diffDays,
          hours: 0,
          minutes: 0,
          seconds: 0,
          hasPassed: true,
        });
      }
    };

    calculateCountdown();
    const timer = setInterval(calculateCountdown, 1000);
    return () => clearInterval(timer);
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

  const totalRemainingDaysCount = daysLeft !== null && daysLeft > 0 ? daysLeft : 0;
  const baseDaysAllocated = checklists.length > 0 ? Math.floor(totalRemainingDaysCount / checklists.length) : 0;
  const totalAllocatedDays = baseDaysAllocated * checklists.length;
  const unallocatedBufferDays = Math.max(0, totalRemainingDaysCount - totalAllocatedDays);

  useEffect(() => {
    if (weddingDate) {
      const remainingDaysCount = daysLeft !== null && daysLeft >= 0 ? daysLeft : 0;

      const s = startDate ? new Date(startDate) : new Date();
      const endDate = new Date(weddingDate);

      setTimeOptions([
        `Start: ${formatDate(s)}`,
        `End: ${formatDate(endDate)}`,
        `Remaining countdown: ${remainingDaysCount} days`,
        `Unallocated buffer: ${unallocatedBufferDays} day${unallocatedBufferDays === 1 ? "" : "s"} (${totalAllocatedDays} days allocated across ${checklists.length} task${checklists.length === 1 ? "" : "s"})`,
      ]);
    }
  }, [startDate, weddingDate, requiredDays, daysLeft, unallocatedBufferDays, totalAllocatedDays, checklists.length]);

  const [distributedTasks, setDistributedTasks] = useState([]);

  useEffect(() => {
    if (!weddingDate || checklists.length === 0) {
      setDistributedTasks([]);
      return;
    }

    const totalRemainingDays = daysLeft !== null && daysLeft > 0 ? daysLeft : 1;
    const totalTasks = checklists.length;
    const baseDays = Math.floor(totalRemainingDays / totalTasks);
    const remainder = totalRemainingDays % totalTasks;

    const temp = [];
    let current = startDate ? new Date(startDate) : new Date();

    for (let i = 0; i < totalTasks; i++) {
      const item = checklists[i];
      // Equal distribution to all tasks
      const taskDays = baseDays;
      const validDays = Math.max(1, taskDays);
      const taskStart = new Date(current);
      const taskEnd = new Date(current);
      taskEnd.setDate(taskEnd.getDate() + validDays - 1);

      temp.push({
        ...item,
        days_assigned: validDays,
        distributed_start_date: formatDate(taskStart),
        distributed_end_date: formatDate(taskEnd),
      });
      current.setDate(current.getDate() + validDays);
    }
    setDistributedTasks(temp);
  }, [checklists, startDate, weddingDate, daysLeft]);

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

  const getMaxDaysForTask = (taskId) => {
    const totalRemaining = daysLeft !== null && daysLeft > 0 ? daysLeft : 1;
    const baseDays = checklists.length > 0 ? Math.floor(totalRemaining / checklists.length) : 1;
    const otherTasksAllocated = checklists.reduce((acc, item) => {
      if (item.id === taskId) return acc;
      const days = customTaskDays[item.id] !== undefined ? customTaskDays[item.id] : baseDays;
      return acc + days;
    }, 0);
    return Math.max(1, totalRemaining - otherTasksAllocated);
  };

  const handleEdit = (id, currentText, currentDays) => {
    setEditingId(id);
    setEditingText(currentText);
    setEditingDays(currentDays || 1);
  };

  const saveEdit = async () => {
    if (!editingText.trim()) {
      setError("Task name cannot be empty.");
      return;
    }

    const maxAllowed = getMaxDaysForTask(editingId);
    const validDays = Math.min(maxAllowed, Math.max(1, editingDays));

    setUpdateLoading(true);
    try {
      await axiosInstance.put(`/new-checklist/update/${editingId}`, {
        text: editingText,
      });
      setCustomTaskDays((prev) => ({
        ...prev,
        [editingId]: validDays,
      }));
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

  const updateStatus = async (id, newStatus) => {
    setError(null);
    setChecklists((prev) =>
      prev.map((item) => (item.id === id ? { ...item, status: newStatus } : item))
    );
    setDistributedTasks((prev) =>
      prev.map((item) => (item.id === id ? { ...item, status: newStatus } : item))
    );

    try {
      await axiosInstance.put(`/new-checklist/update/${id}`, {
        status: newStatus,
      });
    } catch (err) {
      console.warn("Status save warning:", err);
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
                      value={parsedStartDate}
                      format="DD/MM/YYYY"
                      onChange={handleStartDateChange}
                      className="fs-14"
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
                    Wedding Date (End Date)
                  </label>
                  <LocalizationProvider dateAdapter={AdapterDayjs}>
                    <DatePicker
                      value={parsedWeddingDate}
                      format="DD/MM/YYYY"
                      onChange={handleWeddingDateChange}
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

                {countdown && (
                  <div className="hw-countdown-card">
                    <div className="hw-countdown-header">
                      <FaHeart className="hw-countdown-icon" />
                      <span className="hw-countdown-title">
                        {countdown.hasPassed
                          ? "Wedding Milestone"
                          : "Countdown to The Big Day"}
                      </span>
                    </div>

                    {!countdown.hasPassed ? (
                      <div className="hw-countdown-grid">
                        <div className="hw-countdown-box">
                          <div className="hw-countdown-num">
                            {String(countdown.days).padStart(2, "0")}
                          </div>
                          <div className="hw-countdown-unit">DAYS</div>
                        </div>
                        <div className="hw-countdown-colon">:</div>
                        <div className="hw-countdown-box">
                          <div className="hw-countdown-num">
                            {String(countdown.hours).padStart(2, "0")}
                          </div>
                          <div className="hw-countdown-unit">HOURS</div>
                        </div>
                        <div className="hw-countdown-colon">:</div>
                        <div className="hw-countdown-box">
                          <div className="hw-countdown-num">
                            {String(countdown.minutes).padStart(2, "0")}
                          </div>
                          <div className="hw-countdown-unit">MINS</div>
                        </div>
                        <div className="hw-countdown-colon">:</div>
                        <div className="hw-countdown-box">
                          <div className="hw-countdown-num">
                            {String(countdown.seconds).padStart(2, "0")}
                          </div>
                          <div className="hw-countdown-unit">SECS</div>
                        </div>
                      </div>
                    ) : (
                      <div className="hw-countdown-grid">
                        <div className="hw-countdown-box" style={{ minWidth: "120px" }}>
                          <div className="hw-countdown-num" style={{ color: "#ed1173" }}>
                            {countdown.days}
                          </div>
                          <div className="hw-countdown-unit">DAYS AGO</div>
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>

            {/* Main Content */}
            <div className="col-lg-8">
              <div className="hw-checklist-container">
                <div className="hw-checklist-header">
                  <h5 className="hw-checklist-title">
                    <FaHeart />
                    Wedding Checklist & Planning Tasks
                  </h5>
                  <div className="d-flex gap-2">
                    {(distributedTasks && distributedTasks.length > 0) ||
                      (checklists && checklists.length > 0) ? (
                      <button
                        className="hw-download-btn"
                        onClick={handleDownloadPDF}
                      >
                        <FaDownload size={12} />
                        Download PDF
                      </button>
                    ) : (
                      <button
                        className="hw-download-btn"
                        disabled
                        title="No tasks to download"
                      >
                        <FaDownload size={12} />
                        Download PDF
                      </button>
                    )}
                  </div>
                </div>

                <div className="p-4">
                  {/* Overall Progress Card */}
                  <div className="hw-progress-card">
                    <div className="hw-progress-header">
                      <h6 className="hw-progress-title">Overall Task Completion</h6>
                      <span className="hw-progress-badge">
                        {Math.round(progressPercentage)}% Complete
                      </span>
                    </div>
                    <div className="hw-progress-track">
                      <div
                        className="hw-progress-fill"
                        style={{ width: `${progressPercentage}%` }}
                      />
                    </div>
                    <div className="hw-progress-stats">
                      <div className="hw-stat-pill">
                        <span className="hw-stat-num" style={{ color: "#10b981" }}>{completedCount}</span>
                        <span className="hw-stat-label">Tasks Completed</span>
                      </div>
                      <div className="hw-stat-pill">
                        <span className="hw-stat-num" style={{ color: "#0f172a" }}>{checklists.length}</span>
                        <span className="hw-stat-label">Total Tasks</span>
                      </div>
                      <div className="hw-stat-pill">
                        <span className="hw-stat-num" style={{ color: "#ed1173" }}>{Math.max(0, checklists.length - completedCount)}</span>
                        <span className="hw-stat-label">Tasks Remaining</span>
                      </div>
                      <div className="hw-stat-pill">
                        <span className="hw-stat-num" style={{ color: "#3b82f6" }}>{unallocatedBufferDays}</span>
                        <span className="hw-stat-label">Unallocated Buffer</span>
                      </div>
                    </div>
                  </div>

                  {error && (
                    <div
                      className="alert alert-danger alert-custom alert-dismissible fade show fs-14 fw-bold mb-4"
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
                  <div className="hw-add-task-card">
                    <div className="hw-add-task-header">
                      <FaPlus style={{ color: "#ed1173", fontSize: "14px" }} />
                      <h6 className="hw-add-task-title">Add New Task</h6>
                    </div>
                    <div className="row align-items-end g-3">
                      <div className="col-12 col-md-5">
                        <label className="hw-form-label">Vendor Category</label>
                        <Dropdown drop="down" autoClose="outside">
                          <Dropdown.Toggle className="hw-dropdown-toggle">
                            <span>
                              {vendorSubId
                                ? categories.find((c) => c.id == vendorSubId)?.name
                                : "Select Vendor Category"}
                            </span>
                            <FaChevronDown size={11} style={{ color: "#94a3b8" }} />
                          </Dropdown.Toggle>

                          <Dropdown.Menu
                            className="w-100 shadow-lg border-0"
                            style={{
                              maxHeight: "220px",
                              overflowY: "auto",
                              borderRadius: "12px",
                              padding: "6px",
                              zIndex: 9999,
                            }}
                          >
                            {categories.map((sub) => (
                              <Dropdown.Item
                                key={sub.id}
                                onClick={() => setVendorSubId(sub.id)}
                                style={{
                                  borderRadius: "8px",
                                  fontSize: "13.5px",
                                  fontWeight: "500",
                                  padding: "8px 12px",
                                }}
                              >
                                {sub.name}
                              </Dropdown.Item>
                            ))}
                          </Dropdown.Menu>
                        </Dropdown>
                      </div>

                      <div className="col-12 col-md-5">
                        <label className="hw-form-label">Task Description</label>
                        <input
                          type="text"
                          className="hw-input"
                          placeholder="e.g., Shortlist & Book Photographer"
                          value={text}
                          onChange={(e) => setText(e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === "Enter") addChecklist();
                          }}
                        />
                      </div>

                      <div className="col-12 col-md-2">
                        <button
                          className="hw-btn-add w-100"
                          onClick={addChecklist}
                        >
                          <FaPlus size={12} />
                          <span>Add Task</span>
                        </button>
                      </div>
                    </div>

                    {timeOptions.length > 0 && (
                      <div className="time-info mt-3">
                        <label>⏱ Estimated Time Allocation</label>
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
                      <div className="hw-table-card">
                        <div className="table-responsive">
                          <table className="hw-task-table">
                            <thead>
                              <tr>
                                <th style={{ width: "90px", textAlign: "center" }}>Status</th>
                                <th>Task Details</th>
                                <th>Category & Lead Time</th>
                                <th style={{ width: "170px" }}>Allocated Timeline</th>
                                <th style={{ width: "110px", textAlign: "center" }}>Actions</th>
                              </tr>
                            </thead>
                            <tbody>
                              {currentItems.map((item) => (
                                <tr key={item.id}>
                                  <td className="text-center">
                                      <select
                                        className="form-select form-select-sm shadow-none"
                                        style={{
                                          fontSize: "12px",
                                          fontWeight: "600",
                                          borderRadius: "20px",
                                          padding: "4px 10px",
                                          cursor: "pointer",
                                          width: "115px",
                                          margin: "0 auto",
                                          backgroundColor:
                                            item.status === "completed" || item.status === "done"
                                              ? "#dcfce7"
                                              : item.status === "in_progress" || item.status === "in progress"
                                              ? "#e0f2fe"
                                              : "#fef3c7",
                                          color:
                                            item.status === "completed" || item.status === "done"
                                              ? "#15803d"
                                              : item.status === "in_progress" || item.status === "in progress"
                                              ? "#0369a1"
                                              : "#92400e",
                                          borderColor:
                                            item.status === "completed" || item.status === "done"
                                              ? "#86efac"
                                              : item.status === "in_progress" || item.status === "in progress"
                                              ? "#93c5fd"
                                              : "#fde047",
                                        }}
                                        value={
                                          item.status === "done"
                                            ? "completed"
                                            : item.status === "in progress"
                                            ? "in_progress"
                                            : item.status || "pending"
                                        }
                                        onChange={(e) => updateStatus(item.id, e.target.value)}
                                      >
                                        <option value="pending" style={{ backgroundColor: "#ffffff", color: "#92400e" }}>
                                          Pending
                                        </option>
                                        <option value="in_progress" style={{ backgroundColor: "#ffffff", color: "#0369a1" }}>
                                          In Progress
                                        </option>
                                        <option value="completed" style={{ backgroundColor: "#ffffff", color: "#15803d" }}>
                                          Done
                                        </option>
                                      </select>
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
                                        className={`hw-task-name ${
                                          item.status === "completed"
                                            ? "is-completed"
                                            : ""
                                        }`}
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
                                        <div className="hw-category-wrapper">
                                          <span className="hw-category-title">
                                            {subcategory?.name || "General"}
                                          </span>
                                        </div>
                                      );
                                    })()}
                                   </td>
                                   <td>
                                     {editingId === item.id ? (
                                       <div className="d-flex align-items-center gap-1">
                                         <input
                                           type="number"
                                           min="1"
                                           max={getMaxDaysForTask(item.id)}
                                           className="form-control form-control-sm text-center shadow-none"
                                           style={{ width: "55px", fontSize: "12px", fontWeight: "600" }}
                                           value={editingDays}
                                           onChange={(e) => {
                                             const maxLimit = getMaxDaysForTask(item.id);
                                             const val = parseInt(e.target.value) || 1;
                                             setEditingDays(Math.min(maxLimit, Math.max(1, val)));
                                           }}
                                           title={`Maximum ${getMaxDaysForTask(item.id)} days available to allocate`}
                                         />
                                         <span style={{ fontSize: "11px", color: "#64748b", fontWeight: "600" }}>
                                           / {getMaxDaysForTask(item.id)} Days Max
                                         </span>
                                       </div>
                                     ) : (
                                       <span
                                         className="hw-timeline-badge"
                                         title="Days allocated in your wedding planning schedule"
                                       >
                                         <FaCalendarAlt size={11} style={{ color: "#3b82f6" }} />
                                         {item.days_assigned || "—"}{" "}
                                         {item.days_assigned ? "Days Allocated" : ""}
                                       </span>
                                     )}
                                   </td>
                                  <td>
                                    <div className="d-flex gap-2 justify-content-center">
                                      {editingId === item.id ? (
                                        <>
                                          <button
                                            className="hw-action-btn"
                                            style={{
                                              background: "#ecfdf5",
                                              color: "#059669",
                                              borderColor: "#a7f3d0",
                                            }}
                                            onClick={saveEdit}
                                            disabled={updateLoading}
                                            title="Save Changes"
                                          >
                                            {updateLoading ? (
                                              <FaSpinner
                                                size={12}
                                                className="spin"
                                              />
                                            ) : (
                                              <FaCheck size={12} />
                                            )}
                                          </button>
                                          <button
                                            className="hw-action-btn"
                                            style={{
                                              background: "#fef2f2",
                                              color: "#dc2626",
                                              borderColor: "#fecaca",
                                            }}
                                            onClick={cancelEdit}
                                            title="Cancel"
                                          >
                                            <FaTimes size={12} />
                                          </button>
                                        </>
                                      ) : (
                                        <>
                                          <button
                                            className="hw-action-btn"
                                            onClick={() => handleEdit(item.id, item.text, item.days_assigned)}
                                            title="Edit Task & Days"
                                          >
                                            <FaEdit size={12} />
                                          </button>
                                          <button
                                            className="hw-action-btn delete-btn"
                                            onClick={() =>
                                              deleteChecklist(item.id)
                                            }
                                            title="Delete Task"
                                          >
                                            <FiTrash size={14} />
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
