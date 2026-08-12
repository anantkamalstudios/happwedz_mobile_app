import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { BsPlusLg } from "react-icons/bs";
import { GoChecklist } from "react-icons/go";
import { useSelector } from "react-redux";
import axiosInstance from "../../../../services/api/axiosInstance";

const UpComingTask = () => {
  const [tasks, setTasks] = useState([]);
  const [completedTasks, setCompletedTasks] = useState({});
  const [loading, setLoading] = useState(true);
  const [animatingTasks, setAnimatingTasks] = useState({});
  const [removingTasks, setRemovingTasks] = useState({});
  const [statusMessage, setStatusMessage] = useState("");
  const [messageType, setMessageType] = useState("success");

  const user = useSelector((state) => state.auth.user);
  const userId = user?.id || user?.user_id || user?._id;
  const [refresh, setRefresh] = useState(false);

  useEffect(() => {
    if (!userId) {
      setLoading(false);
      return;
    }

    const fetchTasks = async () => {
      setLoading(true);
      try {
        const res = await axiosInstance.get(
          `https://happywedz.com/api/new-checklist/newChecklist/user/${userId}`
        );
        const allTasks = res.data?.data || [];
        const pending = allTasks.filter((task) => task.status === "pending");
        setTasks(pending);

        const completed = {};
        allTasks.forEach((task) => {
          if (task.status === "completed") {
            completed[task.id] = true;
          }
        });
        setCompletedTasks(completed);
      } catch (error) {
        console.error("Failed to fetch upcoming tasks:", error);
        setTasks([]);
      } finally {
        setLoading(false);
      }
    };

    fetchTasks();
  }, [userId, refresh]);

  const handleCheckboxChange = async (event) => {
    const { name: taskId, checked } = event.target;

    if (!checked) return;

    const taskIdNum = parseInt(taskId);

    // Start tick animation
    setAnimatingTasks((prev) => ({ ...prev, [taskIdNum]: true }));

    // After tick animation (500ms), start swipe-out animation
    setTimeout(() => {
      setRemovingTasks((prev) => ({ ...prev, [taskIdNum]: true }));

      // After swipe-out animation (600ms), remove from UI
      setTimeout(() => {
        setTasks((prevTasks) =>
          prevTasks.filter((task) => task.id !== taskIdNum)
        );
        setAnimatingTasks((prev) => {
          const newState = { ...prev };
          delete newState[taskIdNum];
          return newState;
        });
        setRemovingTasks((prev) => {
          const newState = { ...prev };
          delete newState[taskIdNum];
          return newState;
        });
      }, 600);
    }, 500);

    try {
      const newStatus = "completed";
      await axiosInstance.put(
        `https://happywedz.com/api/new-checklist/update/${taskId}`,
        { status: newStatus }
      );
      setStatusMessage("✓ Task marked as completed!");
      setMessageType("success");
      setTimeout(() => setStatusMessage(""), 3000);
      setRefresh((prev) => !prev);
    } catch (error) {
      console.error("Failed to update task status:", error);
      setStatusMessage("✗ Failed to update task. Please try again.");
      setMessageType("error");
      setTimeout(() => setStatusMessage(""), 3000);
      setRefresh((prev) => !prev);
    }
  };

  const pendingTasksCount = tasks.length;

  if (loading) {
    return (
      <div style={{ padding: "2rem" }}>
        <h1 style={{ marginBottom: "1.5rem" }}>Upcoming tasks</h1>
        <p className="text-muted">Loading your checklist...</p>
      </div>
    );
  }

  if (
    !loading &&
    tasks.length === 0 &&
    Object.keys(completedTasks).length === 0
  ) {
    return (
      <div style={{ padding: "2rem", textAlign: "center" }}>
        <h3 className="mb-3 fw-bold dark-pink-text">Start Your Planning</h3>
        <div className="bg-light p-4 p-md-5 rounded-4 d-flex flex-column align-items-center">
          <GoChecklist size={50} />
          <h6 className="fw-bold text-dark my-2">
            Your Wedding Checklist is Empty
          </h6>
          <p className="text-muted mb-4 fs-14">
            Create a personalized checklist to stay organized and on track.
          </p>
          <Link
            to="/user-dashboard/checklist"
            className="btn rounded-3 px-4 fs-14"
            style={{ background: "#C31162", color: "#fff" }}
          >
            <BsPlusLg className="me-2 fs-14" /> Create Your Checklist
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div style={{ padding: "2rem" }}>
      <h1 style={{ marginBottom: "1.5rem" }}>Upcoming tasks</h1>
      {statusMessage && (
        <div
          className={`alert alert-${messageType === "success" ? "success" : "danger"
            } alert-dismissible fade show`}
          role="alert"
          style={{ marginBottom: "1.5rem" }}
        >
          {statusMessage}
          <button
            type="button"
            className="btn-close"
            onClick={() => setStatusMessage("")}
          />
        </div>
      )}
      <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
        {tasks.slice(0, 3).map((task, index) => (
          <div
            key={task.id || index}
            className={`task-item ${animatingTasks[task.id] ? "task-checking" : ""
              } ${removingTasks[task.id] ? "task-removing" : ""}`}
            style={{
              display: "flex",
              justifyContent: "flex-start",
              padding: "10px",
              boxShadow:
                "rgba(0, 0, 0, 0.12) 0px 1px 3px, rgba(0, 0, 0, 0.24) 0px 1px 2px",
              position: "relative",
              overflow: "hidden",
            }}
          >
            <div className="checkbox-wrapper">
              <input
                type="checkbox"
                name={`${task.id}`}
                onChange={handleCheckboxChange}
                checked={animatingTasks[task.id] || false}
                className="task-checkbox"
                id={`task-${task.id}`}
              />
              <label
                htmlFor={`task-${task.id}`}
                className="checkbox-label"
              ></label>
            </div>
            <div style={{ marginLeft: "10px", flex: 1 }}>
              <p className="mb-1">{task.text}</p>
              <p className="text-muted" style={{ fontSize: "12px" }}>
                Tap to open Search
              </p>
            </div>
          </div>
        ))}
      </div>
      <div
        style={{
          display: "flex",
          justifyContent: "flex-end",
          margin: "1rem 0",
          color: "#C31162",
        }}
      >
        <Link
          to="/user-dashboard/checklist"
          className="text-decoration-none"
          style={{ borderBottom: "2px solid #C31162", color: "#C31162" }}
        >
          {pendingTasksCount} PENDING TASKS{" "}
          <i className="fa-solid fa-arrow-right"></i>
        </Link>
      </div>
    </div>
  );
};

export default UpComingTask;
