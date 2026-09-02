import React, { useEffect, useRef, useState } from "react";
import { ArrowLeft, Menu, Plus, SendHorizonal } from "lucide-react";
import { Link, useNavigate, useLocation } from "react-router-dom";
import { FaChevronLeft } from "react-icons/fa6";
import { MdOutlineCancel } from "react-icons/md";

const HomeGennie = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [isChatOpen, setIsChatOpen] = useState(false);
  const [messages, setMessages] = useState([]);
  const [inputValue, setInputValue] = useState("");
  const [isTyping, setIsTyping] = useState(false);
  const [sessionId, setSessionId] = useState(null);

  const handleNewChat = () => {
    setSessionId(null);
    setMessages([
      {
        type: "ai",
        text: "Hi! I am ShaadiAI 👋\n\nHow can I help you plan your dream wedding today?",
      },
    ]);
    setInputValue("");
  };

  const messageContainerRef = useRef(null);

  // Gates the 401KB launcher video (see the <video> below) on real user
  // interaction, so it never lands in the page-load waterfall.
  const [showVideo, setShowVideo] = useState(false);
  useEffect(() => {
    const events = ["pointerdown", "keydown", "scroll", "touchstart"];
    const arm = () => setShowVideo(true);
    events.forEach((e) =>
      window.addEventListener(e, arm, { once: true, passive: true })
    );
    return () =>
      events.forEach((e) => window.removeEventListener(e, arm));
  }, []);

  // The launcher animation was a 160x160 GIF (160KB) for something shown at
  // 74x74 in a corner — the heaviest first-party download on the home page. It
  // is now /shadigif.webp: the same 49 frames and 4080ms loop re-encoded as
  // animated WebP at 148x148 (2x for retina), 56KB.
  // It is still held until the browser is idle rather than fetched during load;
  // until then the button shows /logo-no-bg.png, which index.html's
  // #initial-loader has already put in cache, so the placeholder costs no
  // request at all.
  const [showGif, setShowGif] = useState(false);
  useEffect(() => {
    if ("requestIdleCallback" in window) {
      const id = window.requestIdleCallback(() => setShowGif(true), {
        timeout: 3000,
      });
      return () => window.cancelIdleCallback(id);
    }
    const t = setTimeout(() => setShowGif(true), 1500);
    return () => clearTimeout(t);
  }, []);

  // Prevent body scroll when chat is open on mobile
  useEffect(() => {
    const isMobile = window.innerWidth <= 576;
    if (isChatOpen && isMobile) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "auto";
    }
    return () => {
      document.body.style.overflow = "auto";
    };
  }, [isChatOpen]);

  // Persist session ID for full page navigation
  useEffect(() => {
    if (sessionId) {
      localStorage.setItem("genie_session_id", sessionId);
    }
  }, [sessionId]);

  const getIdFromToken = (token) => {
    try {
      const payload = token.split(".")[1];
      const decoded = JSON.parse(atob(payload));
      return decoded.id || decoded.userId || null;
    } catch (_) {
      return null;
    }
  };
  const tokenId = localStorage.getItem("token");
  const userId = getIdFromToken(tokenId);

  const handleOpenClick = () => {
    if (tokenId) {
      setIsChatOpen(true);
    } else {
      navigate("/customer-login", { state: { from: "/shaadi-ai" } });
    }
  };

  const callChatApi = async (query) => {
    if (!query) return null;

    try {
      const payload = { user_query: query, user_id: userId };
      if (sessionId) payload.session_id = sessionId;

      const res = await fetch("https://shaadiai.happywedz.com/api/user_chat", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          ...(tokenId ? { Authorization: `Bearer ${tokenId}` } : {}),
        },
        body: JSON.stringify(payload),
      });

      const raw = await res.json();
      const wrapped = raw?.data ? raw.data : raw;
      if (wrapped?.session_id) setSessionId(wrapped.session_id);
      const response = wrapped?.response || {};
      return {
        summary: response?.summary || "No response received.",
        results: Array.isArray(response?.results) ? response.results : null,
      };
    } catch (err) {
      console.error("API ERROR:", err);
      return {
        summary: "⚠️ Server not responding. Try again later.",
        results: null,
      };
    }
  };

  useEffect(() => {
    const el = messageContainerRef.current;
    if (!el) return;
    requestAnimationFrame(() => {
      el.scrollTo({ top: el.scrollHeight, behavior: "smooth" });
    });
  }, [messages, isTyping]);

  useEffect(() => {
    if (isChatOpen && messages.length === 0) {
      setIsTyping(true);
      setTimeout(() => {
        setIsTyping(false);
        setMessages([
          {
            type: "ai",
            text: "Hi! I am ShaadiAI 👋\n\nHow can I help you plan your dream wedding today?",
          },
        ]);
      }, 800);
    }
  }, [isChatOpen]);

  const handleSendMessage = async () => {
    if (inputValue.trim() && !isTyping) {
      const userMessage = inputValue.trim();
      setMessages((prev) => [...prev, { type: "user", text: userMessage }]);
      setInputValue("");
      setIsTyping(true);
      const apiResponse = await callChatApi(userMessage);
      setIsTyping(false);

      if (apiResponse) {
        setMessages((prev) => [
          ...prev,
          {
            type: "ai",
            text: apiResponse.summary,
            results: apiResponse.results,
          },
        ]);
      }
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === "Enter") {
      handleSendMessage();
    }
  };

  const quickActions = [
    { icon: "💰", label: "Budget", action: "budget" },
    { icon: "🏛️", label: "Venues", action: "venues" },
    { icon: "📋", label: "Checklist", action: "checklist" },
    { icon: "🎨", label: "Themes", action: "themes" },
  ];

  const popularQuestions = [
    "Plan my dream destination wedding",
    "Show me the best wedding venues",
  ];

  return (
    <div
      style={{
        maxHeight: "90vh",
        position: "relative",
        overflow: "hidden",
        padding: "20px",
      }}
    >
      {!isChatOpen && (
        <button
          onClick={handleOpenClick}
          style={{
            position: "fixed",
            bottom: "32px",
            right: "32px",
            width: "74px",
            height: "74px",
            borderRadius: "50%",
            background: "white",
            border: "none",
            boxShadow:
              "0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            cursor: "pointer",
            zIndex: 999,
            transition: "transform 0.3s ease",
            overflow: "hidden",
          }}
          onMouseEnter={(e) => (e.currentTarget.style.transform = "scale(1.1)")}
          onMouseLeave={(e) => (e.currentTarget.style.transform = "scale(1)")}
        >
          {/* /shadi.mp4 is 401KB — the single heaviest request on the home page,
              for a 74px button. `autoPlay` overrides preload="none", so the only
              way to keep it off the load trace is to not mount the <video> until
              the visitor has actually interacted with the page. Until then the
              button shows the static logo, which is already in cache. */}
          <img
            src={showGif ? "/shadigif.webp" : "/logo-no-bg.png"}
            alt="ShaadiAI"
            width="74"
            height="74"
            decoding="async"
            fetchPriority="low"
            style={{
              height: "100%",
              width: "100%",
              objectFit: showGif ? "cover" : "contain",
              padding: showGif ? 0 : "10px",
              position: "absolute",
              inset: 0,
              opacity: showVideo ? 0 : 1,
              transition: "opacity 0.4s ease",
            }}
          />
          {showVideo && (
            <video
              src="/shadi.mp4"
              autoPlay
              loop
              muted
              playsInline
              style={{
                height: "100%",
                width: "100%",
                objectFit: "cover",
                position: "absolute",
                inset: 0,
              }}
            />
          )}
        </button>
      )}

      {isChatOpen && (
        <div
          style={{
            position: "fixed",
            bottom: window.innerWidth <= 576 ? "0" : "24px",
            right: window.innerWidth <= 576 ? "0" : "24px",
            width: window.innerWidth <= 576 ? "100vw" : "440px",
            height: window.innerWidth <= 576 ? "80dvh" : "650px",
            maxHeight: window.innerWidth <= 576 ? "80vh" : "650px",
            backgroundColor: "white",
            borderRadius: window.innerWidth <= 576 ? "0" : "24px",
            boxShadow:
              "0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)",
            display: "flex",
            flexDirection: "column",
            zIndex: 99999,
            overflowY: "visible",
            overflowX: "visible",
          }}
        >
          <div
            style={{
              padding: "16px 20px",
            }}
          >
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                marginTop: "10px",
                gap: "8px",
              }}
            >
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "8px",
                  flex: 1,
                  minWidth: 0,
                }}
              >
                <button
                  onClick={() => setIsChatOpen(false)}
                  style={{
                    width: window.innerWidth <= 576 ? "32px" : "36px",
                    height: window.innerWidth <= 576 ? "32px" : "36px",
                    borderRadius: "50%",
                    backgroundColor: "rgba(255, 255, 255, 0.2)",
                    backdropFilter: "blur(10px)",
                    border: "none",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    cursor: "pointer",
                    transition: "background-color 0.2s",
                    flexShrink: 0,
                  }}
                  onMouseEnter={(e) =>
                    (e.currentTarget.style.backgroundColor =
                      "rgba(255, 255, 255, 0.3)")
                  }
                  onMouseLeave={(e) =>
                    (e.currentTarget.style.backgroundColor =
                      "rgba(255, 255, 255, 0.2)")
                  }
                >
                  <MdOutlineCancel
                    style={{ width: "18px", height: "18px", color: "#ec4899" }}
                  />
                </button>
                <div
                  style={{
                    width: window.innerWidth <= 576 ? "32px" : "35px",
                    height: window.innerWidth <= 576 ? "32px" : "35px",
                    borderRadius: "50%",
                    backgroundColor: "white",
                    boxShadow: "0 4px 6px -1px rgba(0, 0, 0, 0.1)",
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
                <div style={{ flex: 1, minWidth: 0 }}>
                  <h5
                    style={{
                      fontWeight: 600,
                      fontSize: window.innerWidth <= 576 ? "16px" : "18px",
                      margin: 0,
                      color: "#ec4899",
                      whiteSpace: "nowrap",
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                    }}
                  >
                    Ask our AI anything
                  </h5>
                </div>
              </div>
              <Link
                to="/shaadi-ai"
                style={{
                  border: "none",
                  borderRadius: "50%",
                  width: window.innerWidth <= 576 ? "32px" : "35px",
                  height: window.innerWidth <= 576 ? "32px" : "35px",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  cursor: "pointer",
                  background: "rgba(255, 255, 255, 0.2)",
                  flexShrink: 0,
                }}
                onMouseOver={(e) =>
                  (e.currentTarget.style.background =
                    "rgba(255, 255, 255, 0.3)")
                }
                onMouseOut={(e) =>
                  (e.currentTarget.style.background =
                    "rgba(255, 255, 255, 0.2)")
                }
              >
                <Menu
                  style={{ width: "18px", height: "18px", color: "#ec4899" }}
                />
              </Link>
            </div>
          </div>

          <div
            ref={messageContainerRef}
            style={{
              flex: 1,
              overflowY: "auto",
              overflowX: "hidden",
              padding: window.innerWidth <= 576 ? "12px" : "16px",
              background:
                "linear-gradient(180deg, rgba(252, 231, 243, 0.3) 0%, white 100%)",
            }}
          >
            {messages.length === 0 && !isTyping && (
              <div>
                <div
                  style={{
                    textAlign: "center",
                    padding: window.innerWidth <= 576 ? "20px 0" : "32px 0",
                  }}
                >
                  <div
                    style={{
                      width: window.innerWidth <= 576 ? "64px" : "80px",
                      height: window.innerWidth <= 576 ? "64px" : "80px",
                      margin: "0 auto 16px",
                      borderRadius: "50%",
                      background:
                        "linear-gradient(135deg, #fce7f3 0%, #f3e8ff 100%)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
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
                  <h3
                    style={{
                      fontWeight: 600,
                      color: "#ec4899",
                      marginBottom: "8px",
                      fontSize: window.innerWidth <= 576 ? "16px" : "18px",
                    }}
                  >
                    Welcome to Wedding ShaadiAI! ✨
                  </h3>
                  <p
                    style={{
                      fontSize: window.innerWidth <= 576 ? "12px" : "14px",
                      color: "#ec4899",
                    }}
                  >
                    Let's plan your dream wedding together
                  </p>
                </div>

                <div className="row g-2 mb-4" style={{ padding: "0 8px" }}>
                  {quickActions.map((action, idx) => (
                    <div key={idx} className="col-3" style={{ minWidth: 0 }}>
                      <button
                        style={{
                          width: "100%",
                          display: "flex",
                          flexDirection: "column",
                          alignItems: "center",
                          gap: window.innerWidth <= 576 ? "4px" : "8px",
                          padding: window.innerWidth <= 576 ? "8px" : "12px",
                          borderRadius: "16px",
                          backgroundColor: "white",
                          border: "1px solid #fce7f3",
                          cursor: "pointer",
                          transition: "all 0.2s",
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.borderColor = "#fbcfe8";
                          e.currentTarget.style.boxShadow =
                            "0 4px 6px -1px rgba(0, 0, 0, 0.1)";
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.borderColor = "#fce7f3";
                          e.currentTarget.style.boxShadow = "none";
                        }}
                      >
                        <span
                          style={{
                            fontSize:
                              window.innerWidth <= 576 ? "20px" : "24px",
                          }}
                        >
                          {action.icon}
                        </span>
                        <span
                          style={{
                            fontSize:
                              window.innerWidth <= 576 ? "10px" : "12px",
                            fontWeight: 500,
                            color: "#374151",
                          }}
                        >
                          {action.label}
                        </span>
                      </button>
                    </div>
                  ))}
                </div>

                <div style={{ padding: "0 8px" }}>
                  <p
                    style={{
                      fontSize: window.innerWidth <= 576 ? "11px" : "12px",
                      fontWeight: 600,
                      color: "#6b7280",
                      padding: "0 4px",
                      marginBottom: "8px",
                    }}
                  >
                    Popular questions for you!
                  </p>
                  {popularQuestions.map((question, idx) => (
                    <button
                      key={idx}
                      onClick={() => setInputValue(question)}
                      style={{
                        width: "100%",
                        textAlign: "left",
                        padding: window.innerWidth <= 576 ? "12px" : "16px",
                        borderRadius: "16px",
                        backgroundColor: "white",
                        border: "1px solid #fce7f3",
                        cursor: "pointer",
                        marginBottom: "8px",
                        transition: "all 0.2s",
                      }}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.borderColor = "#fbcfe8";
                        e.currentTarget.style.boxShadow =
                          "0 4px 6px -1px rgba(0, 0, 0, 0.1)";
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.borderColor = "#fce7f3";
                        e.currentTarget.style.boxShadow = "none";
                      }}
                    >
                      <div
                        style={{
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "space-between",
                          gap: "8px",
                        }}
                      >
                        <span
                          style={{
                            fontSize:
                              window.innerWidth <= 576 ? "12px" : "14px",
                            color: "#374151",
                            fontWeight: 500,
                            overflow: "hidden",
                            textOverflow: "ellipsis",
                            display: "-webkit-box",
                            WebkitLineClamp: 2,
                            WebkitBoxOrient: "vertical",
                          }}
                        >
                          {question}
                        </span>
                        <ArrowLeft
                          style={{
                            width: "14px",
                            height: "14px",
                            color: "#ec4899",
                            transform: "rotate(180deg)",
                            flexShrink: 0,
                          }}
                        />
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            )}

            {messages.map((msg, index) => (
              <div
                key={index}
                style={{
                  display: "flex",
                  marginBottom: "16px",
                  justifyContent:
                    msg.type === "user" ? "flex-end" : "flex-start",
                  alignItems: "flex-end",
                }}
              >
                {msg.type === "ai" && (
                  <div
                    style={{
                      width: "32px",
                      height: "32px",
                      borderRadius: "50%",
                      display: "flex",
                      alignItems: "end",
                      justifyContent: "center",
                      marginRight: "2px",
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
                    maxWidth: "80%",
                    padding: "12px 16px",
                    borderRadius:
                      msg.type === "user"
                        ? "24px 24px 4px 24px"
                        : "24px 24px 24px 4px",
                    background: "white",
                    color: "#1f2937",
                    border: "1px solid #f3f4f6",
                    boxShadow: "0 1px 2px 0 rgba(0, 0, 0, 0.05)",
                  }}
                >
                  <p
                    style={{
                      fontSize: "14px",
                      lineHeight: "1.6",
                      margin: 0,
                      whiteSpace: "pre-line",
                    }}
                  >
                    {msg.text}
                  </p>

                  {msg.results && msg.results.length > 0 && (
                    <div
                      style={{
                        marginTop: "12px",
                        display: "flex",
                        flexDirection: "column",
                        gap: "10px",
                      }}
                    >
                      {msg.results.map((result, idx) => (
                        <div
                          key={idx}
                          style={{
                            background: "#f9fafb",
                            padding: "12px",
                            borderRadius: "12px",
                            border: "1px solid #e5e7eb",
                          }}
                        >
                          <div
                            style={{
                              fontWeight: "600",
                              color: "#ec4899",
                              marginBottom: "6px",
                              fontSize: "13px",
                            }}
                          >
                            {result.name}
                          </div>
                          <div
                            style={{
                              fontSize: "12px",
                              color: "#6b7280",
                              marginBottom: "4px",
                            }}
                          >
                            📍 {result.location}
                          </div>
                          <div
                            style={{
                              fontSize: "12px",
                              color: "#9ca3af",
                              marginBottom: "6px",
                            }}
                          >
                            {result.type}
                          </div>
                          {result.rating > 0 && (
                            <div
                              style={{
                                fontSize: "12px",
                                color: "#6b7280",
                                marginBottom: "8px",
                              }}
                            >
                              ⭐ {result.rating}
                            </div>
                          )}
                          {result.why_consider &&
                            result.why_consider.length > 0 && (
                              <div style={{ marginTop: "8px" }}>
                                <div
                                  style={{
                                    fontSize: "11px",
                                    fontWeight: "600",
                                    color: "#4b5563",
                                    marginBottom: "4px",
                                  }}
                                >
                                  Why consider:
                                </div>
                                <ul
                                  style={{
                                    margin: "0",
                                    paddingLeft: "16px",
                                    fontSize: "11px",
                                    color: "#6b7280",
                                    lineHeight: "1.4",
                                  }}
                                >
                                  {result.why_consider.map((reason, i) => (
                                    <li key={i} style={{ marginBottom: "3px" }}>
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
              </div>
            ))}

            {isTyping && (
              <div style={{ display: "flex", marginBottom: "16px" }}>
                <div
                  style={{
                    width: "32px",
                    height: "32px",
                    borderRadius: "50%",
                    background:
                      "linear-gradient(135deg, #ec4899 0%, #9333ea 100%)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    marginRight: "8px",
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
                    backgroundColor: "white",
                    border: "1px solid #f3f4f6",
                    borderRadius: "24px 24px 24px 4px",
                    boxShadow: "0 1px 2px 0 rgba(0, 0, 0, 0.05)",
                    padding: "12px 20px",
                  }}
                >
                  <div style={{ display: "flex", gap: "4px" }}>
                    <div
                      style={{
                        width: "8px",
                        height: "8px",
                        backgroundColor: "#9ca3af",
                        borderRadius: "50%",
                        animation: "bounce 1s infinite",
                      }}
                    ></div>
                    <div
                      style={{
                        width: "8px",
                        height: "8px",
                        backgroundColor: "#9ca3af",
                        borderRadius: "50%",
                        animation: "bounce 1s infinite 0.1s",
                      }}
                    ></div>
                    <div
                      style={{
                        width: "8px",
                        height: "8px",
                        backgroundColor: "#9ca3af",
                        borderRadius: "50%",
                        animation: "bounce 1s infinite 0.2s",
                      }}
                    ></div>
                  </div>
                </div>
              </div>
            )}
          </div>

          <div
            style={{
              borderTop: "1px solid #f3f4f6",
              padding: window.innerWidth <= 576 ? "12px" : "16px",
              backgroundColor: "white",
            }}
          >
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: window.innerWidth <= 576 ? "6px" : "8px",
              }}
            >
              <button
                style={{
                  width: window.innerWidth <= 576 ? "36px" : "40px",
                  height: window.innerWidth <= 576 ? "36px" : "40px",
                  borderRadius: "50%",
                  backgroundColor: "#fce7f3",
                  border: "none",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  cursor: "pointer",
                  flexShrink: 0,
                  transition: "background-color 0.2s",
                }}
                onClick={handleNewChat}
                onMouseEnter={(e) =>
                  (e.currentTarget.style.backgroundColor = "#fbcfe8")
                }
                onMouseLeave={(e) =>
                  (e.currentTarget.style.backgroundColor = "#fce7f3")
                }
              >
                <span
                  style={{
                    fontSize: window.innerWidth <= 576 ? "18px" : "20px",
                  }}
                >
                  <Plus style={{ color: "#ec4899" }} />
                </span>
              </button>
              <div style={{ flex: 1, position: "relative", minWidth: 0 }}>
                <input
                  type="text"
                  placeholder={
                    window.innerWidth <= 576 ? "Ask..." : "Ask me questions..."
                  }
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                  onKeyPress={handleKeyPress}
                  disabled={isTyping}
                  style={{
                    width: "100%",
                    padding:
                      window.innerWidth <= 576
                        ? "10px 40px 10px 14px"
                        : "12px 48px 12px 16px",
                    borderRadius: "50px",
                    border: "1px solid #e5e7eb",
                    fontSize: window.innerWidth <= 576 ? "12px" : "14px",
                    outline: "none",
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = "#fbcfe8";
                    e.target.style.boxShadow =
                      "0 0 0 3px rgba(252, 231, 243, 0.5)";
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = "#e5e7eb";
                    e.target.style.boxShadow = "none";
                  }}
                />
                <button
                  onClick={handleSendMessage}
                  disabled={!inputValue.trim() || isTyping}
                  style={{
                    position: "absolute",
                    right: "4px",
                    top: "50%",
                    transform: "translateY(-50%)",
                    width: window.innerWidth <= 576 ? "32px" : "36px",
                    height: window.innerWidth <= 576 ? "32px" : "36px",
                    borderRadius: "50%",
                    border: "none",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    cursor:
                      inputValue.trim() && !isTyping
                        ? "pointer"
                        : "not-allowed",
                    transition: "transform 0.2s",
                    opacity: inputValue.trim() && !isTyping ? 1 : 0.5,
                    background: "transparent",
                    flexShrink: 0,
                  }}
                  onMouseEnter={(e) =>
                    inputValue.trim() &&
                    !isTyping &&
                    (e.currentTarget.style.transform =
                      "translateY(-50%) scale(1.05)")
                  }
                  onMouseLeave={(e) =>
                    (e.currentTarget.style.transform =
                      "translateY(-50%) scale(1)")
                  }
                >
                  <SendHorizonal
                    style={{ width: "16px", height: "16px", color: "#ec4899" }}
                  />
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      <style>{`
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.5; }
        }
        @keyframes bounce {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-5px); }
        }
      `}</style>
    </div>
  );
};

export default HomeGennie;
