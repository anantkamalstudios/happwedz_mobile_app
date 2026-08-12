import React, { useState, useEffect } from "react";
import { CheckCircle, Clock, Users, DollarSign, Plus } from "lucide-react";
import { MdDinnerDining, MdGroups } from "react-icons/md";
import { BsTruck } from "react-icons/bs";
import { TbCards } from "react-icons/tb";
import { PiFlowerLotusThin } from "react-icons/pi";
import { GrPlan } from "react-icons/gr";
import { Camera, Music, Utensils, Gift } from "lucide-react";
import { Link } from "react-router-dom";
import { useSelector } from "react-redux";
import CtaPanel from "../../../../components/home/CtaPanel";
import logo from "../../../../../public/happywed_white.png";
import image from "../../../../../public/images/home/1.jpg";
import bigleafcta1 from "../../../../../public/images/home/bigleafcta1.jpg";
import VenueVendorComponent from "./VenueVendorComponent";
import UpComingTask from "../wedding/UpcomingTask";
import EInvites from "./EInviteCard";
import cmsApi from "../../../../services/api/cmsApi";
import axiosInstance from "../../../../services/api/axiosInstance";

const Wedding = () => {
  const [budget, setBudget] = useState({
    total: 0,
    spent: 0,
    remaining: 0,
  });
  const [guestStats, setGuestStats] = useState({ total: 0, attending: 0 });
  const [taskStats, setTaskStats] = useState({ total: 0, completed: 0 });

  const [user, setUser] = useState(null);
  const [loadingUser, setLoadingUser] = useState(true);

  const [countdown, setCountdown] = useState({
    days: 0,
    hours: 0,
    hasPassed: false,
  });

  const [vendorCategories, setVendorCategories] = useState([]);
  const [showAll, setShowAll] = useState(false);

  const [designBanner, setDesignBanner] = useState(null);
  const normalizeUrl = (u) => {
    if (!u || typeof u !== "string") return null;
    const cleaned = u.replace(/`/g, "").trim();
    try {
      return encodeURI(cleaned);
    } catch {
      return cleaned;
    }
  };

  useEffect(() => {
    const fetchBanner = async () => {
      try {
        const ds = await cmsApi.designStudioBanner.getBanner();
        setDesignBanner(ds?.data || null);
      } catch (e) {
        console.error("Failed to fetch banner", e);
      }
    };
    fetchBanner();
  }, []);

  const token = useSelector((state) => state.auth.token); // Keep for auth state
  const userId = useSelector((state) => state.auth.user?.id);

  const iconMapping = [
    <Camera size={24} />,
    <Utensils size={24} />,
    <Music size={24} />,
    <MdDinnerDining size={24} />,
    <BsTruck size={24} />,
    <TbCards size={24} />,
    <Gift size={24} />,
    <PiFlowerLotusThin size={24} />,
    <GrPlan size={24} />,
  ];

  const toSlug = (text) =>
    text
      ?.toLowerCase()
      .replace(/\s+/g, "-")
      .replace(/[^a-z0-9\-]/g, "") || "";

  useEffect(() => {
    const fetchCategories = async () => {
      try {
        const response = await fetch("https://happywedz.com/api/vendor-types");
        const data = await response.json();

        const mappedCategories = data.map((cat, index) => ({
          icon: iconMapping[index] || <Camera size={24} />,
          title: cat.name,
          subtitle: "Explore this category",
          count: 0,
        }));

        setVendorCategories(mappedCategories);
      } catch (error) {
        console.error("Error fetching vendor categories:", error);
      }
    };

    fetchCategories();
  }, []);

  useEffect(() => {
    const fetchUserData = async () => {
      try {
        if (!token) {
          console.error("No user token found.");
          setLoadingUser(false);
          return;
        }
        function parseJwt(token) {
          const base64Url = token.split(".")[1]; // payload part
          const base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
          const jsonPayload = decodeURIComponent(
            atob(base64)
              .split("")
              .map((c) => "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2))
              .join("")
          );

          return JSON.parse(jsonPayload);
        }

        let userInfo = parseJwt(token);

        const response = await axiosInstance.get(
          "https://happywedz.com/api/user/" + userInfo.id
        );

        const data = response.data;
        setUser(data.user);
      } catch (error) {
        console.error("Failed to fetch user data:", error);
      } finally {
        setLoadingUser(false);
      }
    };

    fetchUserData();
  }, [token]);

  useEffect(() => {
    if (!token || !userId) return;

    const fetchDashboardData = async () => {
      try {
        const guestsRes = await axiosInstance.get(
          `https://happywedz.com/api/guestlist/${userId}`
        );
        const guestsData = guestsRes.data;
        if (
          guestsData.success &&
          guestsData.data &&
          Array.isArray(guestsData.data)
        ) {
          const totalGuests = guestsData.data.length;
          const attendingGuests = guestsData.data.filter(
            (g) => g.status === "Attending"
          ).length;
          setGuestStats({ total: totalGuests, attending: attendingGuests });
        }

        const tasksRes = await axiosInstance.get(
          `https://happywedz.com/api/new-checklist/newChecklist/user/${userId}`
        );
        const tasksData = tasksRes.data;
        if (tasksData.success) {
          const allTasks = Array.isArray(tasksData.data) ? tasksData.data : [];
          const completedTasks = allTasks.filter(
            (t) => t.status === "completed"
          ).length;
          setTaskStats({
            total: allTasks.length,
            completed: completedTasks,
          });
        }
      } catch (error) {
        console.error("Failed to fetch dashboard data:", error);
      }
    };

    fetchDashboardData();
  }, [token, userId]);

  useEffect(() => {
    if (!user?.weddingDate) return;

    const weddingDate = new Date(user.weddingDate);

    const MILLISECONDS_IN_SECOND = 1000;
    const SECONDS_IN_MINUTE = 60;
    const MINUTES_IN_HOUR = 60;
    const HOURS_IN_DAY = 24;
    const MILLISECONDS_IN_HOUR =
      MILLISECONDS_IN_SECOND * SECONDS_IN_MINUTE * MINUTES_IN_HOUR;
    const MILLISECONDS_IN_DAY = MILLISECONDS_IN_HOUR * HOURS_IN_DAY;

    const calculateCountdown = () => {
      const now = new Date(Date.now());
      const difference = weddingDate - now;

      if (difference > 0) {
        const days = Math.floor(difference / MILLISECONDS_IN_DAY);
        const hours = Math.floor(
          (difference % MILLISECONDS_IN_DAY) / MILLISECONDS_IN_HOUR
        );
        setCountdown({ days, hours, hasPassed: false });
      } else {
        setCountdown({ days: 0, hours: 0, hasPassed: true });
      }
    };
    calculateCountdown();

    const interval = setInterval(calculateCountdown, 60000); // 60000ms = 1 minute

    return () => clearInterval(interval);
  }, [user?.weddingDate]);

  const formatDateWithOrdinal = (dateString) => {
    if (!dateString) return "";
    const date = new Date(dateString);
    const day = date.getDate();
    const month = date.toLocaleDateString("en-US", { month: "long" });
    const year = date.getFullYear();

    const getOrdinal = (d) => {
      if (d > 3 && d < 21) return "th";
      switch (d % 10) {
        case 1:
          return "st";
        case 2:
          return "nd";
        case 3:
          return "rd";
        default:
          return "th";
      }
    };

    return `${day}${getOrdinal(day)} of ${month} ${year}`;
  };

  const toggleShowAll = () => setShowAll(!showAll);
  const displayedCategories = showAll
    ? vendorCategories
    : vendorCategories.slice(0, 6);

  if (loadingUser) {
    return <div className="text-center py-5">Loading your dashboard...</div>;
  }

  return (
    <div className="wedding-dashboard">
      <div className="container py-4">
        <div className="card rounded-4 p-2 shadow-sm border-0 mb-4 overflow-hidden">
          <div className="row g-0">
            <div className="col-md-4 position-relative">
              <img
                src="/images/userDashboard/home-wedding-image.jpg"
                alt="Wedding"
                className="img-fluid h-100 w-100 rounded-5 object-fit-cover"
              />

              <div
                className="position-absolute bottom-0 end-0 p-2 m-2 rounded-4"
                style={{
                  background: "rgba(255, 192, 203, 0.85)",
                }}
              >
                <div className="d-flex text-center text-dark fw-bold">
                  <div className="px-3">
                    <h5 className="fw-bold">{countdown.days}</h5>
                    <small>Days</small>
                  </div>
                  <div className="px-3 border-start border-dark-subtle">
                    <h5 className="fw-bold">{countdown.hours}</h5>
                    <small>Hrs</small>
                  </div>
                </div>
              </div>
            </div>

            <div className="col-md-8 p-4 d-flex flex-column justify-content-center">
              <h3 className="fw-bold mb-2 text-dark">
                Welcome,{" "}
                {user?.name
                  .split(" ")
                  .map(
                    (word) =>
                      word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
                  )
                  .join(" ") || "User"}
                !
              </h3>

              <p className="text-muted mb-4 fs-16">
                {formatDateWithOrdinal(user?.weddingDate)}
              </p>

              <div className="card rounded-0 border-0 shadow-sm">
                <div className="row text-center g-0">
                  <div className="col py-3 border-end">
                    <span className="mb-1 fw-semibold text-dark fs-16 d-block">
                      Service Hired
                    </span>
                    <small className="text-muted fs-14">0 of 25</small>
                  </div>
                  <div className="col py-3 border-end">
                    <span className="mb-1 fw-semibold text-dark fs-16 d-block">
                      Task Complete
                    </span>
                    <small className="text-muted fs-14">
                      {taskStats.completed} of {taskStats.total || 20}
                    </small>
                  </div>
                  <div className="col py-3">
                    <span className="mb-1 fw-semibold text-dark fs-16 d-block">
                      Guest Attending
                    </span>
                    <small className="text-muted fs-14">
                      {guestStats.attending} of {guestStats.total || 100}
                    </small>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <section className="w-100">
          <div className="row g-4">
            <div className="col-12 col-md-6">
              <VenueVendorComponent type="venue" />
            </div>
            <div className="col-12 col-md-6">
              <VenueVendorComponent type="vendor" />
            </div>
          </div>
        </section>

        <section className="col-lg-12">
          <CtaPanel
            logo={normalizeUrl(designBanner?.logo) || logo}
            img={normalizeUrl(designBanner?.mainImage) || image}
            heading={designBanner?.heading || "Design Studio"}
            subHeading={
              designBanner?.subheading ||
              "Try Virtual Makeup & Grooming Looks for Your Big Day_"
            }
            link={`/${(designBanner?.btnRedirect || "try").replace(/^\/+/, "")}`}
            title={designBanner?.title || "Create Your Look !"}
            subtitle={
              designBanner?.description ||
              "Experience How You'll Look in Your Wedding Day with AI-Powered Virtual Makeover."
            }
            btnName={designBanner?.btnName || "Try Virtual Look"}
            background={normalizeUrl(designBanner?.bgImage) || bigleafcta1}
          />
        </section>

        <section className="mt-4">
          <div className="row g-4">
            {/* Upcoming tasks - primary wide card */}
            <div className="col-12 col-lg-8">
              <div className="shadow-lg h-100 p-3 p-md-4 rounded-3 bg-white">
                <UpComingTask />
              </div>
            </div>

            {/* E-Invites side card */}
            <div className="col-12 col-lg-4">
              <div className="shadow-lg h-100 rounded-3 bg-white">
                <EInvites />
              </div>
            </div>

            {/* Add Guest */}
            <div className="col-12 col-md-6 col-xl-4">
              <div className="shadow-lg h-100 rounded-3 p-3 p-md-4 bg-white d-flex flex-column">
                <h3 className="text-center fw-bold mt-2 mt-md-4 dark-pink-text">
                  Add Guest
                </h3>
                <div className="d-flex flex-column align-items-center justify-content-center flex-grow-1 gap-2 py-3">
                  <div
                    style={{
                      height: "60px",
                      width: "60px",
                      borderRadius: "50%",
                      backgroundColor: "#C31162",
                      display: "flex",
                      justifyContent: "center",
                      alignItems: "center",
                    }}
                  >
                    <MdGroups size={40} color="#fff" />
                  </div>

                  <p className="my-2 fs-16 text-center">
                    You haven't added any guest yet
                  </p>
                  <Link to="/user-dashboard/guest-list" className="fs-14">
                    <button
                      style={{
                        padding: "0.5rem 2rem",
                        backgroundColor: "#C31162",
                        color: "#fff",
                        border: "none",
                        borderRadius: "10px",
                        cursor: "pointer",
                        fontWeight: "bold",
                      }}
                    >
                      Add Guest
                    </button>
                  </Link>
                </div>
              </div>
            </div>

            {/* Wedding Budget */}
            <div className="col-12 col-md-6 col-xl-4">
              <div className="shadow-lg h-100 rounded-3 p-3 p-md-4 bg-white d-flex flex-column">
                <div className="text-center my-auto">
                  <h3 className="fw-bold dark-pink-text mb-4">
                    Wedding Budget
                  </h3>
                  <div className="mb-3">
                    <h3 className="display-6 fw-bold primary-text mb-1">
                      ₹{(budget.total / 100000).toFixed(1)}L
                    </h3>
                    <div className="text-muted fs-16">Total Budget</div>
                  </div>
                  <div className="d-flex justify-content-center gap-4 small text-muted mb-4 fs-16">
                    <span>Spent: ₹{(budget.spent / 100000).toFixed(1)}L</span>
                    <span>
                      Remaining: ₹{(budget.remaining / 100000).toFixed(1)}L
                    </span>
                  </div>
                  <div
                    className="progress mx-auto mb-2 fs-16"
                    style={{ height: "8px", maxWidth: "220px" }}
                  >
                    <div
                      className="progress-bar bg-primary"
                      role="progressbar"
                      style={{
                        width: `${budget.total > 0
                            ? (budget.spent / budget.total) * 100
                            : 0
                          }%`,
                      }}
                      aria-valuenow={
                        budget.total > 0
                          ? (budget.spent / budget.total) * 100
                          : 0
                      }
                      aria-valuemin="0"
                      aria-valuemax="100"
                    />
                  </div>
                  <small className="text-muted">
                    {Math.round(
                      budget.total > 0 ? (budget.spent / budget.total) * 100 : 0
                    )}
                    % used
                  </small>
                </div>
                <div className="text-center mt-3 mt-md-auto">
                  <Link
                    to="/user-dashboard/budget"
                    className="btn rounded-3 px-4 py-2 fs-14"
                    style={{ background: "#C31162", color: "#fff" }}
                  >
                    + Add Budget
                  </Link>
                </div>
              </div>
            </div>

            {/* Get the app */}
            <div className="col-12 col-xl-4">
              <div className="shadow-lg h-100 rounded-3 d-flex justify-content-center align-items-center bg-white p-3 p-md-4">
                <div className="text-center" style={{ padding: "10px" }}>
                  <div className="card-body">
                    <h6 className="fw-bold mb-2">Get the Happywedz app</h6>
                    <p
                      style={{
                        fontSize: "14px",
                        color: "#555",
                        marginBottom: "16px",
                      }}
                    >
                      Always bring the best wedding planner for iPhone and
                      Android with you.
                    </p>

                    <div className="d-flex justify-content-center gap-2 flex-wrap">
                      <a
                        href="#"
                        style={{
                          display: "inline-block",
                          width: "130px",
                        }}
                      >
                        <img
                          src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg"
                          alt="Download on App Store"
                          style={{ width: "100%" }}
                        />
                      </a>

                      <a
                        href="#"
                        style={{
                          display: "inline-block",
                          width: "140px",
                        }}
                      >
                        <img
                          src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg"
                          alt="Get it on Google Play"
                          style={{ width: "100%" }}
                        />
                      </a>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
};

export default Wedding;
