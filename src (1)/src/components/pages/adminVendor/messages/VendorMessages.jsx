import React, { useEffect, useMemo, useRef, useState } from "react";
import { useSelector } from "react-redux";
import { FiSend, FiSmile, FiSearch, FiMessageSquare } from "react-icons/fi";
import vendorMessagesApi from "../../../../services/api/vendorMessagesApi";
import { vendorsApi } from "../../../../services/api/vendorAuthApi";
import axiosInstance from "../../../../services/api/axiosInstance";
import { formatDate, formatDateTime } from "../../../../utils/dateFormat";
import "./VendorMessages.css";

const ONLINE_WINDOW_MS = 60 * 1000;

function isOnline(lastActiveAtIso) {
  if (!lastActiveAtIso) return false;
  return Date.now() - new Date(lastActiveAtIso).getTime() <= ONLINE_WINDOW_MS;
}

function formatTime(iso) {
  if (!iso) return "";
  try {
    const d = new Date(iso);
    return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  } catch {
    return formatDateTime(iso);
  }
}

// Resilient Avatar component that displays user logo/image or initial
const UserAvatar = ({ name, imageUrl, size = 42, className = "conv-avatar" }) => {
  const [hasError, setHasError] = useState(false);
  const initial = (name?.charAt(0) || "C").toUpperCase();

  if (imageUrl && !hasError) {
    return (
      <img
        src={imageUrl}
        alt={name || "Avatar"}
        className={className}
        onError={() => setHasError(true)}
        style={{
          width: size,
          height: size,
          borderRadius: "50%",
          objectFit: "cover",
          border: "1px solid #fce7f3",
          flexShrink: 0,
        }}
      />
    );
  }

  return (
    <div
      className={className}
      style={{
        width: size,
        height: size,
        borderRadius: "50%",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontWeight: "700",
        fontSize: size > 40 ? "1rem" : "0.85rem",
        background: "#fff1f6",
        color: "#ed1173",
        border: "1px solid #fce7f3",
        flexShrink: 0,
      }}
    >
      {initial}
    </div>
  );
};

const VendorMessages = () => {
  const { token: vendorToken } = useSelector((s) => s.vendorAuth || {});
  const [conversations, setConversations] = useState([]);
  const [activeConversationId, setActiveConversationId] = useState(null);
  const [messages, setMessages] = useState([]);
  const [loadingConversations, setLoadingConversations] = useState(false);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [error, setError] = useState(null);
  const [input, setInput] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [quickReplies] = useState([
    "Hello 👋",
    "Thanks for reaching out!",
    "Yes, I am available for your date.",
    "Can you please share more details?",
  ]);
  const [vendorImage, setVendorImage] = useState(null);
  const [userImages, setUserImages] = useState({});
  const [userNames, setUserNames] = useState({});
  const [userLastActive, setUserLastActive] = useState({});
  const scrollRef = useRef(null);

  const activeConversation = useMemo(
    () => conversations.find((c) => c.id === activeConversationId),
    [conversations, activeConversationId]
  );

  const selectConversation = (id) => {
    setActiveConversationId(id);
    setConversations((prev) =>
      prev.map((c) => (c.id === id ? { ...c, vendorUnreadCount: 0 } : c))
    );
  };

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages.length, activeConversationId]);

  // Presence heartbeat for vendor
  useEffect(() => {
    if (!vendorToken) return;
    let stopped = false;
    let timer;
    const send = async () => {
      try {
        if (document.visibilityState === "visible") {
          await axiosInstance.post("/presence/heartbeat", null, {
            headers: { Authorization: `Bearer ${vendorToken}` },
          });
        }
      } catch {}
      if (!stopped) timer = setTimeout(send, 45000);
    };
    send();
    const onVis = () => {
      if (document.visibilityState === "visible") {
        axiosInstance
          .post("/presence/heartbeat", null, {
            headers: { Authorization: `Bearer ${vendorToken}` },
          })
          .catch(() => {});
      }
    };
    document.addEventListener("visibilitychange", onVis);
    return () => {
      stopped = true;
      if (timer) clearTimeout(timer);
      document.removeEventListener("visibilitychange", onVis);
    };
  }, [vendorToken]);

  // Load conversations
  useEffect(() => {
    let isMounted = true;
    const load = async () => {
      setLoadingConversations(true);
      setError(null);
      try {
        const res = await vendorMessagesApi.getConversations();
        let list = Array.isArray(res)
          ? res
          : res?.data || res?.conversations || [];

        // Deduplicate: ensure one conversation per user, preferring most recent
        list.sort(
          (a, b) =>
            new Date(b.lastMessageAt || 0) - new Date(a.lastMessageAt || 0)
        );
        const seenUsers = new Set();
        list = list.filter((c) => {
          if (!c.userId) return true;
          if (seenUsers.has(c.userId)) return false;
          seenUsers.add(c.userId);
          return true;
        });

        // Fetch vendor self profile image
        const first = list?.[0];
        if (first?.vendorId) {
          try {
            const v = await vendorsApi.getVendorById(first.vendorId);
            const vendorData = v?.data || v;
            setVendorImage(
              vendorData?.profileImage || vendorData?.image || null
            );
          } catch {}
        }

        // Fetch each user's profile info
        const userIds = [...new Set(list.map((c) => c.userId).filter(Boolean))];
        const fetched = await Promise.all(
          userIds.map((id) =>
            axiosInstance
              .get(`/user/${id}`, {
                headers: vendorToken
                  ? { Authorization: `Bearer ${vendorToken}` }
                  : {},
              })
              .then((r) => ({
                id,
                data: r.data?.user || r.data?.data || r.data,
              }))
              .catch(() => ({ id, data: null }))
          )
        );

        const map = {};
        const nameMap = {};
        const lastActiveMap = {};
        fetched.forEach(({ id, data }) => {
          if (data) {
            map[id] =
              data.profileImage ||
              data.avatar ||
              data.image ||
              data.picture ||
              data.logo ||
              null;
            nameMap[id] =
              data.name ||
              data.fullName ||
              data.username ||
              data.email ||
              "Customer";
            lastActiveMap[id] = data.lastActiveAt || null;
          }
        });

        if (!isMounted) return;
        setUserImages(map);
        setUserNames(nameMap);
        setUserLastActive(lastActiveMap);
        setConversations(list);

        if (list.length > 0 && !activeConversationId) {
          setActiveConversationId(list[0].id);
        }
      } catch (e) {
        if (!isMounted) return;
        setError(e.message || "Failed to load conversations");
      } finally {
        if (isMounted) setLoadingConversations(false);
      }
    };

    if (vendorToken) load();
    return () => {
      isMounted = false;
    };
  }, [vendorToken]);

  // Load messages for active conversation
  useEffect(() => {
    let isMounted = true;
    const loadMsgs = async () => {
      if (!activeConversationId) return;
      setLoadingMessages(true);
      setError(null);
      try {
        const res = await vendorMessagesApi.getMessages(activeConversationId, {
          page: 1,
          limit: 50,
        });
        const list = Array.isArray(res)
          ? res
          : res?.data || res?.messages || [];

        const mapped = list.map((m) => {
          const isVendor = (m.senderType || "").toLowerCase() === "vendor";
          return {
            id: m.id,
            sender: isVendor ? "vendor" : "user",
            name: isVendor ? "You" : "Customer",
            text: m.message || "",
            time: m.createdAt || new Date().toISOString(),
            userId: isVendor ? null : m.senderId,
          };
        });

        if (!isMounted) return;
        setMessages(mapped);
      } catch (e) {
        if (!isMounted) return;
        setError(e.message || "Failed to load messages");
      } finally {
        if (isMounted) setLoadingMessages(false);
      }
    };

    if (vendorToken && activeConversationId) loadMsgs();
    return () => {
      isMounted = false;
    };
  }, [vendorToken, activeConversationId]);

  // Polling: conversations (10s)
  useEffect(() => {
    if (!vendorToken) return;
    const interval = setInterval(async () => {
      try {
        const res = await vendorMessagesApi.getConversations();
        let list = Array.isArray(res)
          ? res
          : res?.data || res?.conversations || [];

        list.sort(
          (a, b) =>
            new Date(b.lastMessageAt || 0) - new Date(a.lastMessageAt || 0)
        );
        const seenUsersPoll = new Set();
        list = list.filter((c) => {
          if (!c.userId) return true;
          if (seenUsersPoll.has(c.userId)) return false;
          seenUsersPoll.add(c.userId);
          return true;
        });

        setConversations((prev) => {
          const byId = new Map(prev.map((c) => [c.id, c]));
          return list.map((c) => {
            const old = byId.get(c.id);
            return old
              ? {
                  ...c,
                  vendorUnreadCount:
                    activeConversationId === c.id ? 0 : c.vendorUnreadCount,
                }
              : c;
          });
        });
      } catch {}
    }, 10000);
    return () => clearInterval(interval);
  }, [vendorToken, activeConversationId]);

  // Polling: messages (4s)
  useEffect(() => {
    if (!vendorToken || !activeConversationId) return;
    const interval = setInterval(async () => {
      try {
        const res = await vendorMessagesApi.getMessages(activeConversationId, {
          page: 1,
          limit: 50,
        });
        const list = Array.isArray(res)
          ? res
          : res?.data || res?.messages || [];
        const mapped = list.map((m) => {
          const isVendor = (m.senderType || "").toLowerCase() === "vendor";
          return {
            id: m.id,
            sender: isVendor ? "vendor" : "user",
            name: isVendor ? "You" : "Customer",
            text: m.message || "",
            time: m.createdAt || new Date().toISOString(),
            userId: isVendor ? null : m.senderId,
          };
        });
        setMessages(mapped);
      } catch {}
    }, 4000);
    return () => clearInterval(interval);
  }, [vendorToken, activeConversationId]);

  const sendMessage = async (text) => {
    if (!text || !text.trim() || !activeConversationId) return;
    const optimistic = {
      id: `tmp-${Date.now()}`,
      sender: "vendor",
      name: "You",
      text: text.trim(),
      time: new Date().toISOString(),
    };
    setMessages((m) => [...m, optimistic]);
    setInput("");
    try {
      const res = await vendorMessagesApi.sendMessage(activeConversationId, {
        message: text.trim(),
      });
      const saved = res && typeof res === "object" ? res : null;
      if (saved) {
        const normalized = {
          id: saved.id,
          sender: "vendor",
          name: "You",
          text: saved.message || text.trim(),
          time: saved.createdAt || optimistic.time,
        };
        setMessages((m) =>
          m.map((x) => (x.id === optimistic.id ? normalized : x))
        );
        setConversations((prev) =>
          prev.map((c) =>
            c.id === activeConversationId
              ? {
                  ...c,
                  lastMessagePreview: saved.message || text.trim(),
                  lastMessageAt: saved.createdAt || new Date().toISOString(),
                }
              : c
          )
        );
      }
    } catch (e) {
      setError(e.message || "Failed to send message");
      setMessages((m) => m.filter((x) => x.id !== optimistic.id));
    }
  };

  const handleQuick = (label) => sendMessage(label);

  // Filter conversations
  const filteredConversations = useMemo(() => {
    if (!searchQuery.trim()) return conversations;
    const q = searchQuery.toLowerCase();
    return conversations.filter((c) => {
      const name = (userNames[c.userId] || "").toLowerCase();
      const preview = (c.lastMessagePreview || "").toLowerCase();
      return name.includes(q) || preview.includes(q);
    });
  }, [conversations, searchQuery, userNames]);

  const currentChatUser = activeConversation?.userId;
  const currentCustomerName = userNames[currentChatUser] || "Customer";
  const currentCustomerImage = userImages[currentChatUser];
  const customerOnline = currentChatUser ? isOnline(userLastActive[currentChatUser]) : false;

  return (
    <div className="messages-page-wrapper">
      <div className="messages-unified-container">
        {/* Left: Conversations List */}
        <div className="messages-conv-panel">
          <div className="messages-conv-header">
            <h6 className="messages-conv-title">
              <span>Conversations</span>
              <span className="badge bg-light text-muted border">
                {conversations.length}
              </span>
            </h6>
            <div className="messages-conv-search">
              <FiSearch />
              <input
                type="text"
                placeholder="Search conversations..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          </div>

          <div className="messages-conv-list">
            {loadingConversations ? (
              <div className="p-3 text-muted small text-center">
                Loading conversations...
              </div>
            ) : filteredConversations.length === 0 ? (
              <div className="p-4 text-muted small text-center">
                <FiMessageSquare size={24} className="mb-2 text-muted" />
                <p className="mb-0">No conversations found</p>
              </div>
            ) : (
              filteredConversations.map((c) => {
                const name = userNames[c.userId] || "Customer";
                const img = userImages[c.userId];
                const isActive = activeConversationId === c.id;
                const online = isOnline(userLastActive[c.userId]);

                return (
                  <div
                    key={c.id}
                    className={`conv-item ${isActive ? "active" : ""}`}
                    onClick={() => selectConversation(c.id)}
                  >
                    <div className="conv-avatar-wrap">
                      <UserAvatar
                        name={name}
                        imageUrl={img}
                        size={42}
                        className="conv-avatar"
                      />
                      {online && <span className="conv-online-badge"></span>}
                    </div>

                    <div className="conv-info">
                      <div className="conv-name-row">
                        <h6 className="conv-name">{name}</h6>
                        <span className="conv-time">
                          {c.lastMessageAt ? formatTime(c.lastMessageAt) : ""}
                        </span>
                      </div>
                      <div className="d-flex align-items-center justify-content-between">
                        <p className="conv-preview">
                          {c.lastMessagePreview || "No messages yet"}
                        </p>
                        {c.vendorUnreadCount > 0 && (
                          <span className="conv-unread-pill">
                            {c.vendorUnreadCount}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* Right: Chat Panel */}
        <div className="messages-chat-panel">
          {activeConversation ? (
            <>
              {/* Header */}
              <div className="chat-header">
                <div className="chat-header-user">
                  <div className="chat-header-avatar-wrap">
                    <UserAvatar
                      name={currentCustomerName}
                      imageUrl={currentCustomerImage}
                      size={44}
                      className="chat-header-avatar"
                    />
                  </div>
                  <div>
                    <h6 className="chat-header-name">{currentCustomerName}</h6>
                    <div
                      className={`chat-header-status ${
                        customerOnline ? "online" : ""
                      }`}
                    >
                      {customerOnline ? (
                        <>
                          <span className="chat-status-dot"></span>
                          <span>Online</span>
                        </>
                      ) : (
                        <span>
                          {userLastActive[currentChatUser]
                            ? `Last seen ${formatDateTime(userLastActive[currentChatUser])}`
                            : "Active recently"}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="text-muted small">
                  {formatDate(new Date())}
                </div>
              </div>

              {/* Chat Body */}
              <div className="chat-body-scroll" ref={scrollRef}>
                {error && !loadingMessages && (
                  <div className="alert alert-danger py-2 px-3 small mb-2">
                    {error}
                  </div>
                )}

                {loadingMessages ? (
                  <div className="text-muted small text-center my-4">
                    Loading messages...
                  </div>
                ) : messages.length === 0 ? (
                  <div className="text-center text-muted small my-auto">
                    <p className="mb-0">No messages yet. Send a greeting to begin!</p>
                  </div>
                ) : (
                  messages.map((m) => {
                    const isSent = m.sender === "vendor";
                    return (
                      <div
                        key={m.id}
                        className={`chat-msg-row ${isSent ? "sent" : "received"}`}
                      >
                        <div className="chat-msg-bubble">{m.text}</div>
                        <span className="chat-msg-time">
                          {formatTime(m.time)}
                        </span>
                      </div>
                    );
                  })
                )}
              </div>

              {/* Quick Replies */}
              <div className="chat-quick-replies">
                {quickReplies.map((q) => (
                  <button
                    key={q}
                    type="button"
                    className="chat-quick-chip"
                    onClick={() => handleQuick(q)}
                  >
                    {q}
                  </button>
                ))}
              </div>

              {/* Input Bar */}
              <div className="chat-input-bar">
                <button
                  type="button"
                  className="chat-emoji-btn"
                  onClick={() => setInput((prev) => prev + " 😊")}
                  title="Add emoji"
                >
                  <FiSmile />
                </button>
                <input
                  type="text"
                  className="chat-input-field"
                  placeholder="Type your message..."
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && sendMessage(input)}
                />
                <button
                  type="button"
                  className="chat-send-btn"
                  onClick={() => sendMessage(input)}
                  title="Send message"
                >
                  <FiSend size={16} />
                </button>
              </div>
            </>
          ) : (
            <div className="h-100 d-flex flex-column align-items-center justify-content-center text-center p-4">
              <FiMessageSquare size={44} className="text-muted mb-2" />
              <h6 className="fw-bold text-dark mb-1">Select a Conversation</h6>
              <p className="text-muted small">
                Choose a conversation on the left to view messages and chat.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default VendorMessages;
