import React, { useEffect, useRef, useState } from "react";
import { BsStars } from "react-icons/bs";
import { FaAngleRight } from "react-icons/fa6";
import { FaTimes, FaEdit } from "react-icons/fa";
import { LuSendHorizontal } from "react-icons/lu";
import { MdChatBubbleOutline } from "react-icons/md";
import { useSelector } from "react-redux";
import { axiosInstance } from "../../services/api/axiosInstance";

const Genie = () => {
  const [messages, setMessages] = useState([
    {
      type: "ai",
      text: "Hey there! I'm your Wedding ShaadiAI. Ask me anything!",
    },
  ]);
  const [inputValue, setInputValue] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const [showSidebar, setShowSidebar] = useState(true);
  const [sessionId, setSessionId] = useState(null);
  const [sessions, setSessions] = useState([]);
  const [loadingSessions, setLoadingSessions] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");

  const messagesContainerRef = useRef(null);
  const { user } = useSelector((store) => store.auth);
  const token = localStorage.getItem("token");
  const userName = user?.name || "User";

  function getIdFromToken(t) {
    if (!t) return null;

    try {
      const payload = JSON.parse(atob(t.split(".")[1])); // decode payload
      return payload.id || payload._id || payload.userId || null;
    } catch (error) {
      console.error("Invalid token:", error);
      return null;
    }
  }

  const userId = getIdFromToken(token);

  // Fetch user sessions list
  useEffect(() => {
    const fetchSessions = async () => {
      if (!userId) return;
      setLoadingSessions(true);
      try {
        const res = await fetch(
          `https://shaadiai.happywedz.com/api/sessions/${userId}`,
          {
            method: "GET",
            headers: {
              "Content-Type": "application/json",
              Accept: "application/json",
              ...(token ? { Authorization: `Bearer ${token}` } : {}),
            },
          },
        );
        const raw = await res.json();
        const wrapped = raw?.data ? raw.data : raw;
        const data = Array.isArray(wrapped) ? wrapped : [];
        setSessions(data);
      } catch (err) {
        console.error(err);
        setSessions([]);
      } finally {
        setLoadingSessions(false);
      }
    };
    fetchSessions();
  }, [userId, token]);

  const loadChatHistory = async (sid) => {
    try {
      const res = await fetch(
        `https://shaadiai.happywedz.com/api/chat_history?session_id=${sid}`,
        {
          method: "GET",
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
            ...(token ? { Authorization: `Bearer ${token}` } : {}),
          },
        },
      );
      const raw = await res.json();
      const wrapped = raw?.data ? raw.data : raw;
      const items = Array.isArray(wrapped) ? wrapped : [];
      const mapped = items.map((it) => {
        if (it.role === "user") {
          return { type: "user", text: String(it.content || "") };
        }
        const c = it.content || {};
        const summary =
          typeof c === "string" ? c : c.summary || c.message || "";
        const results =
          typeof c === "object" && Array.isArray(c.results) ? c.results : null;
        return { type: "ai", text: summary, results };
      });
      setMessages(mapped);
    } catch (err) {
      console.error(err);
      // ignore
    }
  };

  useEffect(() => {
    const savedSessionId = localStorage.getItem("genie_session_id");
    if (savedSessionId) {
      setSessionId(savedSessionId);
      loadChatHistory(savedSessionId);
    }
  }, []);

  // Save session to localStorage whenever it changes
  useEffect(() => {
    if (sessionId) {
      localStorage.setItem("genie_session_id", sessionId);
    }
  }, [sessionId]);

  const callChatApi = async (query) => {
    if (!query) return;

    setIsLoading(true);

    try {
      const payload = { user_query: query, user_id: userId };
      if (sessionId) payload.session_id = sessionId;

      const res = await fetch("https://shaadiai.happywedz.com/api/user_chat", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify(payload),
      });

      const raw = await res.json();
      const wrapped = raw?.data ? raw.data : raw;

      if (wrapped?.session_id) setSessionId(wrapped.session_id);

      const responseData = wrapped?.response || {};
      return {
        summary: responseData?.summary || "No response received.",
        results: Array.isArray(responseData?.results)
          ? responseData.results
          : null,
      };
    } catch (err) {
      console.error("API ERROR:", err);
      return {
        summary: "⚠️ Server not responding. Try again later.",
        results: null,
      };
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    const checkMobile = () => {
      const mobile = window.innerWidth < 768;
      setIsMobile(mobile);
      if (!mobile) {
        setShowSidebar(true);
      } else {
        setShowSidebar(false);
      }
    };

    checkMobile();
    window.addEventListener("resize", checkMobile);
    return () => window.removeEventListener("resize", checkMobile);
  }, []);

  useEffect(() => {
    const el = messagesContainerRef.current;
    if (el) {
      setTimeout(() => {
        el.scrollTo({ top: el.scrollHeight, behavior: "smooth" });
      }, 100);
    }
  }, [messages]);

  // Handle keyboard visibility on mobile
  useEffect(() => {
    if (!isMobile) return;

    const handleResize = () => {
      const el = messagesContainerRef.current;
      if (el) {
        setTimeout(() => {
          el.scrollTo({ top: el.scrollHeight, behavior: "auto" });
        }, 100);
      }
    };

    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, [isMobile]);

  // Prevent body scroll when mobile sidebar is open
  useEffect(() => {
    if (isMobile && showSidebar) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "auto";
    }
    return () => {
      document.body.style.overflow = "auto";
    };
  }, [isMobile, showSidebar]);

  const handleSendMessage = async () => {
    if (!inputValue.trim() || isLoading) return;

    const userMsg = inputValue.trim();
    setMessages((prev) => [...prev, { type: "user", text: userMsg }]);
    setInputValue("");

    const apiResponse = await callChatApi(userMsg);

    setMessages((prev) => [
      ...prev,
      {
        type: "ai",
        text: apiResponse.summary,
        results: apiResponse.results,
      },
    ]);
  };

  const handleKeyPress = (e) => {
    if (e.key === "Enter") handleSendMessage();
  };

  const handleNewChat = () => {
    localStorage.removeItem("genie_session_id");
    setSessionId(null);
    setMessages([
      {
        type: "ai",
        text: "Hey there! I'm your Wedding ShaadiAI. Ask me anything!",
      },
    ]);
    setInputValue("");
    if (isMobile) setShowSidebar(false);
  };

  const headerHeight = "clamp(60px, 10vw, 200px)";
  const contentHeight = `calc(100vh - ${headerHeight})`;

  // Mobile keyboard viewport fix
  const chatSectionStyle = isMobile
    ? {
        height: contentHeight,
        overflowY: "auto",
        display: "flex",
        flexDirection: "column",
        position: "relative",
      }
    : {
        height: contentHeight,
        overflowY: "auto",
      };

  return (
    <div>
      <div className="container-fluid">
        <div className="row" style={{ minHeight: contentHeight }}>
          {/* SIDEBAR */}
          <div
            className="col-12 col-md-3 p-4"
            style={{
              backgroundColor: "#fff",
              boxShadow: "2px 0 10px rgba(0,0,0,0.05)",
              minHeight: "100vh",
              overflowY: "auto",
              // Only apply mobile-specific styles when isMobile is true
              ...(isMobile && {
                position: "fixed",
                top: headerHeight,
                left: 0,
                width: "min(80vw, 350px)",
                height: contentHeight,
                zIndex: 1000,
                transform: showSidebar ? "translateX(0)" : "translateX(-100%)",
                transition: "transform 0.3s ease-in-out",
                boxShadow: "4px 0 10px rgba(0,0,0,0.1)",
              }),
            }}
          >
            {/* Close button - only visible on mobile */}
            {isMobile && (
              <div
                style={{
                  position: "absolute",
                  top: "10px",
                  right: "10px",
                  cursor: "pointer",
                  zIndex: 10,
                }}
                onClick={() => setShowSidebar(false)}
              >
                <FaTimes size={24} style={{ color: "#d63384" }} />
              </div>
            )}

            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                marginBottom: "20px",
              }}
            >
              <div
                style={{
                  width: "50px",
                  height: "50px",
                  borderRadius: "50%",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                <img
                  src="/shaadi.jpg"
                  alt="shaadi-logo"
                  style={{ height: "100%" }}
                />
              </div>

              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "8px",
                  fontSize: "16px",
                  color: "#d63384",
                  cursor: "pointer",
                  padding: "8px 12px",
                  borderRadius: "20px",
                  backgroundColor: "rgba(214, 51, 132, 0.1)",
                }}
                onClick={handleNewChat}
              >
                <FaEdit size={14} style={{ marginRight: "4px" }} />
                <span style={{ fontWeight: "600" }}>New Chat</span>
              </div>
            </div>

            <div
              style={{
                marginTop: "20px",
                padding: "12px 8px",
                fontSize: "14px",
                cursor: "pointer",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                borderBottom: "1px solid #C31162",
              }}
            >
              <div
                style={{ display: "flex", alignItems: "center", gap: "8px" }}
              >
                <span>
                  <MdChatBubbleOutline size={24} />
                </span>
                <span>Plan my dream destination wedding</span>
              </div>
              <span>
                <FaAngleRight size={24} />
              </span>
            </div>
            {/* Sessions List */}
            <div style={{ marginTop: "20px" }}>
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "8px",
                  justifyContent: "space-between",
                }}
              >
                <h6
                  style={{
                    color: "#d63384",
                    fontSize: "16px",
                    fontWeight: "600",
                    display: "flex",
                    alignItems: "center",
                    gap: "8px",
                    margin: 0,
                  }}
                >
                  <span>Previous history</span>
                </h6>
              </div>
              <div style={{ maxHeight: "40vh", overflowY: "auto" }}>
                {loadingSessions ? (
                  <div className="text-muted small">Loading sessions...</div>
                ) : sessions.length === 0 ? (
                  <div className="text-muted small">No sessions yet</div>
                ) : (
                  sessions.map((s) => (
                    <div
                      key={s.session_id}
                      onClick={() => {
                        setSessionId(s.session_id);
                        loadChatHistory(s.session_id);
                        if (isMobile) setShowSidebar(false);
                      }}
                      style={{
                        padding: "10px 8px",
                        borderBottom: "1px solid #f1f1f1",
                        cursor: "pointer",
                      }}
                    >
                      <div style={{ fontWeight: 600, fontSize: "14px" }}>
                        {s.title || "Untitled Session"}
                      </div>
                      <div className="text-muted" style={{ fontSize: "12px" }}>
                        {new Date(s.updated_at).toLocaleString()}
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>

            {/* Summary & Checklist sections removed as requested */}
          </div>

          {/* BACKDROP OVERLAY - only on mobile when sidebar is open */}
          {isMobile && showSidebar && (
            <div
              style={{
                position: "fixed",
                top: headerHeight,
                left: 0,
                width: "100vw",
                height: contentHeight,
                backgroundColor: "rgba(0, 0, 0, 0.5)",
                zIndex: 999,
              }}
              onClick={() => setShowSidebar(false)}
            />
          )}

          {/* CHAT SECTION */}
          <div className="col-12 col-md-9 p-0" style={chatSectionStyle}>
            <div
              style={{
                height: "100%",
                display: "flex",
                flexDirection: "column",
                minHeight: contentHeight,
                position: "relative",
              }}
            >
              {/* Hamburger menu - only on mobile */}
              {isMobile && (
                <div
                  style={{
                    padding: "10px 20px",
                    display: "flex",
                    justifyContent: "flex-start",
                  }}
                >
                  <button
                    onClick={() => setShowSidebar(!showSidebar)}
                    style={{
                      background: "none",
                      border: "none",
                      cursor: "pointer",
                      display: "flex",
                      flexDirection: "column",
                      justifyContent: "space-around",
                      width: 24,
                      height: 24,
                      padding: 0,
                    }}
                  >
                    <span
                      style={{
                        width: "100%",
                        height: 3,
                        backgroundColor: "#C31162",
                        borderRadius: 2,
                      }}
                    ></span>
                    <span
                      style={{
                        width: "100%",
                        height: 3,
                        backgroundColor: "#C31162",
                        borderRadius: 2,
                      }}
                    ></span>
                    <span
                      style={{
                        width: "100%",
                        height: 3,
                        backgroundColor: "#C31162",
                        borderRadius: 2,
                      }}
                    ></span>
                  </button>
                </div>
              )}

              <div
                style={{
                  padding: "10px 30px",
                  textAlign: "center",
                }}
              >
                {/* <p>
                  <BsStars size={30} style={{ color: "#C31162" }} />
                </p>
                <h3 style={{ color: "#C31162", fontWeight: "600" }}>
                  Ask our AI anything
                </h3> */}
              </div>

              <div
                ref={messagesContainerRef}
                className="no-scrollbar"
                style={{
                  flex: 1,
                  overflowY: "auto",
                  padding: "20px 40px",
                  display: "flex",
                  flexDirection: "column",
                  gap: "20px",
                }}
              >
                {messages.map((msg, index) => (
                  <div
                    key={index}
                    style={{
                      display: "flex",
                      justifyContent:
                        msg.type === "user" ? "flex-end" : "flex-start",
                      marginBottom: "5px",
                      gap: "5px",
                      alignItems: "flex-start",
                    }}
                  >
                    {msg.type === "ai" && (
                      // <div
                      //   style={{
                      //     width: "40px",
                      //     height: "40px",
                      //     borderRadius: "50%",
                      //     display: "flex",
                      //     alignItems: "center",
                      //     justifyContent: "center",
                      //     flexShrink: 0,
                      //     alignSelf: "flex-end",
                      //   }}
                      // >
                      //   <BsStars size={30} style={{ color: "#C31162" }} />
                      // </div>
                      <div
                        style={{
                          width: "40px",
                          height: "40px",
                          borderRadius: "50%",
                          overflow: "hidden", // important to keep image inside circle
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          flexShrink: 0,
                        }}
                      >
                        <img
                          src="/shaadi.jpg"
                          alt="logo"
                          style={{
                            height: "100%",
                            width: "100%",
                            objectFit: "cover",
                          }}
                        />
                      </div>
                    )}
                    <div
                      style={{
                        width: "auto",
                      }}
                    >
                      <div
                        style={{
                          background: "#fff",
                          padding: "8px 16px",
                          borderRadius:
                            msg.type === "user"
                              ? "18px 18px 0 18px"
                              : "18px 18px 18px 0",
                          color: "#1f2937",
                          whiteSpace: "pre-line",
                          fontSize: "15px",
                          lineHeight: "1.6",
                        }}
                      >
                        {msg.text}
                      </div>

                      {msg.results && msg.results.length > 0 && (
                        <div
                          style={{
                            marginTop: "20px",
                            display: "grid",
                            gridTemplateColumns: isMobile
                              ? "1fr"
                              : window.innerWidth < 992
                                ? "repeat(2, 1fr)"
                                : "repeat(3, 1fr)",
                            gap: "16px",
                            maxWidth: "100%",
                          }}
                        >
                          {msg.results.map((result, idx) => (
                            <div
                              key={idx}
                              style={{
                                background: "#ffffff",
                                padding: "20px",
                                borderRadius: "12px",
                                border: "1px solid #e5e7eb",
                                boxShadow: "0 1px 3px rgba(0,0,0,0.08)",
                                transition: "all 0.2s ease",
                                cursor: "pointer",
                                maxWidth: "380px",
                                width: "100%",
                              }}
                              onMouseEnter={(e) => {
                                e.currentTarget.style.boxShadow =
                                  "0 4px 12px rgba(0,0,0,0.12)";
                                e.currentTarget.style.transform =
                                  "translateY(-2px)";
                              }}
                              onMouseLeave={(e) => {
                                e.currentTarget.style.boxShadow =
                                  "0 1px 3px rgba(0,0,0,0.08)";
                                e.currentTarget.style.transform =
                                  "translateY(0)";
                              }}
                            >
                              <div
                                style={{
                                  fontWeight: "600",
                                  fontSize: "17px",
                                  color: "#1f2937",
                                  marginBottom: "10px",
                                  lineHeight: "1.4",
                                }}
                              >
                                {result.name}
                              </div>
                              <div
                                style={{
                                  fontSize: "14px",
                                  color: "#6b7280",
                                  marginBottom: "6px",
                                  fontWeight: "500",
                                }}
                              >
                                {result.location}
                              </div>
                              <div
                                style={{
                                  fontSize: "13px",
                                  color: "#9ca3af",
                                  marginBottom: "10px",
                                  letterSpacing: "0.3px",
                                }}
                              >
                                {result.type}
                              </div>
                              {result.rating > 0 && (
                                <div
                                  style={{
                                    display: "inline-block",
                                    fontSize: "13px",
                                    fontWeight: "600",
                                    color: "#d97706",
                                    backgroundColor: "#fef3c7",
                                    padding: "4px 10px",
                                    borderRadius: "6px",
                                    marginBottom: "14px",
                                  }}
                                >
                                  {result.rating} Rating
                                </div>
                              )}
                              {result.why_consider &&
                                result.why_consider.length > 0 && (
                                  <div
                                    style={{
                                      marginTop: "14px",
                                      paddingTop: "14px",
                                      borderTop: "1px solid #f3f4f6",
                                    }}
                                  >
                                    <div
                                      style={{
                                        fontSize: "12px",
                                        fontWeight: "600",
                                        color: "#374151",
                                        marginBottom: "8px",
                                        textTransform: "uppercase",
                                        letterSpacing: "0.5px",
                                      }}
                                    >
                                      Why Consider
                                    </div>
                                    <ul
                                      style={{
                                        margin: "0",
                                        paddingLeft: "18px",
                                        fontSize: "13px",
                                        color: "#4b5563",
                                        lineHeight: "1.6",
                                        listStyleType: "disc",
                                      }}
                                    >
                                      {result.why_consider.map((reason, i) => (
                                        <li
                                          key={i}
                                          style={{
                                            marginBottom: "6px",
                                            paddingLeft: "2px",
                                          }}
                                        >
                                          {reason}
                                        </li>
                                      ))}
                                    </ul>
                                  </div>
                                )}
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                    {msg.type === "user" && (
                      <div
                        style={{
                          width: "40px",
                          height: "40px",
                          borderRadius: "50%",
                          background: "#6b7280",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          flexShrink: 0,
                          color: "#fff",
                          fontWeight: "600",
                          fontSize: "16px",
                          alignSelf: "flex-end",
                        }}
                      >
                        {userName.slice(0, 1)}
                      </div>
                    )}
                  </div>
                ))}

                {isLoading && (
                  <div
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "10px",
                    }}
                  >
                    {/* <div
                      style={{
                        width: "40px",
                        height: "40px",
                        borderRadius: "50%",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        flexShrink: 0,
                      }}
                    >
                      <BsStars size={30} style={{ color: "#C31162" }} />
                    </div> */}
                    <div
                      style={{
                        width: "40px",
                        height: "40px",
                        borderRadius: "50%",
                        overflow: "hidden", // important to keep image inside circle
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        flexShrink: 0,
                      }}
                    >
                      <img
                        src="/shaadi.jpg"
                        alt="logo"
                        style={{
                          height: "100%",
                          width: "100%",
                          objectFit: "cover",
                        }}
                      />
                    </div>

                    <div
                      style={{
                        display: "inline-flex",
                        alignItems: "center",
                        gap: "6px",
                        background: "#fff",
                        padding: "12px 12px",
                        borderRadius: "18px",
                        boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
                        width: "fit-content",
                      }}
                    >
                      <div style={{ display: "flex", gap: "4px" }}>
                        <span
                          style={{
                            width: "6px",
                            height: "6px",
                            background: "#C31162",
                            borderRadius: "50%",
                            animation: "blink 1.4s infinite both",
                            animationDelay: "0s",
                          }}
                        ></span>
                        <span
                          style={{
                            width: "6px",
                            height: "6px",
                            background: "#C31162",
                            borderRadius: "50%",
                            animation: "blink 1.4s infinite both",
                            animationDelay: "0.2s",
                          }}
                        ></span>
                        <span
                          style={{
                            width: "6px",
                            height: "6px",
                            background: "#C31162",
                            borderRadius: "50%",
                            animation: "blink 1.4s infinite both",
                            animationDelay: "0.4s",
                          }}
                        ></span>
                      </div>

                      <style>
                        {`
                    @keyframes blink {
                      0% { opacity: .2; transform: translateY(0); }
                      20% { opacity: 1; transform: translateY(-3px); }
                      100% { opacity: .2; transform: translateY(0); }
                    }
                    `}
                      </style>
                    </div>
                  </div>
                )}
              </div>

              <div
                style={{ padding: "20px 40px 0px" }}
                className="genie-input-area"
              >
                <div
                  style={{
                    maxWidth: "900px",
                    margin: "0 auto",
                    paddingBottom: isMobile ? "20px" : "0px",
                    scrollMarginBottom: "20px",
                  }}
                >
                  <div style={{ position: "relative" }}>
                    <input
                      type="text"
                      value={inputValue}
                      onChange={(e) => setInputValue(e.target.value)}
                      onKeyDown={handleKeyPress}
                      placeholder="Ask me anything..."
                      className="form-control"
                      style={{
                        padding: "15px 60px 15px 20px",
                        fontSize: "15px",
                        boxShadow: "0 4px 15px rgba(217, 70, 239, 0.15)",
                        borderRadius: "50px",
                      }}
                    />
                    <button
                      onClick={handleSendMessage}
                      style={{
                        position: "absolute",
                        right: "10px",
                        top: "50%",
                        transform: "translateY(-50%)",
                        background: "transparent",
                        border: "none",
                        cursor: "pointer",
                        zIndex: 101,
                      }}
                    >
                      <LuSendHorizontal
                        size={24}
                        style={{ color: "#ed1147" }}
                      />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Genie;
