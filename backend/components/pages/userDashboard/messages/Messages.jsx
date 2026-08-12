import React, { useState, useRef, useEffect } from "react";
import { FiSend, FiSmile, FiClock } from "react-icons/fi";
import { FaUserCircle } from "react-icons/fa";
import { useSelector } from "react-redux";
import messagesApi from "../../../../services/api/messagesApi";
import { vendorsApi } from "../../../../services/api/vendorAuthApi";
import axiosInstance from "../../../../services/api/axiosInstance";
import EmojiPicker from "emoji-picker-react";

const ONLINE_WINDOW_MS = 60 * 1000;
function isOnline(lastActiveAtIso) {
  if (!lastActiveAtIso) return false;
  return Date.now() - new Date(lastActiveAtIso).getTime() <= ONLINE_WINDOW_MS;
}

const normalizeConversation = (c) => {
  const vendor = c.vendor || {};
  return {
    id: c.id,
    vendorId: c.vendorId,
    vendorName: vendor.businessName || vendor.name || "Vendor",
    vendorImage: vendor.profileImage || vendor.image || null,
    vendorLastActiveAt: vendor.lastActiveAt || null,
    vendorDescription: vendor.description || "",
    lastMessagePreview: c.lastMessagePreview || "",
    lastMessageAt: c.lastMessageAt || c.updatedAt || c.createdAt,
    unreadCount: c.userUnreadCount || 0,
  };
};


const deduplicateConversations = (conversations) => {
  const vendorMap = new Map();

  conversations.forEach((conv) => {
    if (!conv.vendorId) return;

    const existing = vendorMap.get(conv.vendorId);

    if (!existing) {
      vendorMap.set(conv.vendorId, { ...conv });
    } else {

      const existingTime = existing.lastMessageAt || existing.updatedAt || existing.createdAt;
      const currentTime = conv.lastMessageAt || conv.updatedAt || conv.createdAt;


      const combinedUnread = (existing.unreadCount || 0) + (conv.unreadCount || 0);


      if (new Date(currentTime) > new Date(existingTime)) {
        vendorMap.set(conv.vendorId, {
          ...conv,
          unreadCount: combinedUnread,
        });
      } else {

        existing.unreadCount = combinedUnread;
      }
    }
  });

  return Array.from(vendorMap.values());
};

const normalizeMessage = (m, selfUserId) => {
  const isUser = (m.senderType || "").toLowerCase() === "user";
  return {
    id: m.id,
    sender: isUser ? "user" : "vendor",
    name: isUser ? "You" : m.senderName || "Vendor",
    text: m.message || m.text || "",
    time: m.createdAt || new Date().toISOString(),
  };
};

function formatTime(iso) {
  const d = new Date(iso);
  return d.toLocaleString([], {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

const Avatar = ({ name, size = 36, imageUrl }) => {
  const fallback = "/images/no-image.png";
  return (
    <img
      src={imageUrl || fallback}
      alt={name || "Avatar"}
      onError={(e) => {
        if (e.currentTarget.src !== fallback) {
          e.currentTarget.src = fallback;
        }
      }}
      style={{
        width: size,
        height: size,
        borderRadius: "50%",
        objectFit: "cover",
      }}
    />
  );
};

const QuickChip = ({ label, onClick }) => (
  <button
    type="button"
    onClick={() => onClick(label)}
    className="btn btn-sm border rounded-pill me-2 mb-2 text-truncate fw-medium inter"
    style={{
      minWidth: 120,
      background: "#f8f9fa",
      fontSize: "0.85rem",
    }}
  >
    {label}
  </button>
);

const Messages = () => {
  const { user, token } = useSelector((state) => state.auth);
  const [showEmoji, setShowEmoji] = useState(false);
  const [conversations, setConversations] = useState([]);
  const [activeConversationId, setActiveConversationId] = useState(null);
  const [messages, setMessages] = useState([]);
  const [loadingConversations, setLoadingConversations] = useState(false);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [error, setError] = useState(null);
  const [input, setInput] = useState("");
  const [userImageUrl, setUserImageUrl] = useState(null);
  const [quickReplies] = useState([
    "I'm Interested",
    "Still Thinking",
    "No Thanks",
  ]);
  const scrollRef = useRef(null);

  const activeConversation = conversations.find(
    (c) => c.id === activeConversationId
  );

  const selectConversation = (id) => {
    setActiveConversationId(id);
    // Optimistically reset unread count for this thread
    setConversations((prev) =>
      prev.map((c) => (c.id === id ? { ...c, unreadCount: 0 } : c))
    );
  };

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages, activeConversationId]);

  // Load current user's profile image (from Redux or API fallback)
  useEffect(() => {
    let isMounted = true;
    const loadUserImage = async () => {
      try {
        if (user?.profileImage) {
          setUserImageUrl(user.profileImage);
          return;
        }
        if (user?.id) {
          const res = await axiosInstance.get(`/user/${user.id}`);
          const u = res?.data?.user || res?.user || res?.data;
          if (!isMounted) return;
          setUserImageUrl(u?.profileImage || null);
        }
      } catch {
        // ignore
      }
    };
    loadUserImage();
    return () => {
      isMounted = false;
    };
  }, [user?.id, user?.profileImage]);

  // Presence heartbeat every ~45s when visible
  useEffect(() => {
    if (!token) return;
    let stopped = false;
    let timer;
    const send = async () => {
      try {
        if (document.visibilityState === "visible") {
          await axiosInstance.post("/presence/heartbeat");
        }
      } catch { }
      if (!stopped) timer = setTimeout(send, 45000);
    };
    send();
    const onVis = () => {
      if (document.visibilityState === "visible") {
        axiosInstance.post("/presence/heartbeat").catch(() => { });
      }
    };
    document.addEventListener("visibilitychange", onVis);
    return () => {
      stopped = true;
      if (timer) clearTimeout(timer);
      document.removeEventListener("visibilitychange", onVis);
    };
  }, [token]);

  // Load conversations
  useEffect(() => {
    let isMounted = true;
    const load = async () => {
      setLoadingConversations(true);
      setError(null);
      try {
        const res = await messagesApi.getConversations();
        const list = Array.isArray(res)
          ? res
          : res?.data || res?.conversations || [];
        const mapped = list.map(normalizeConversation);
        // Deduplicate by vendorId - keep most recent conversation per vendor
        const deduplicated = deduplicateConversations(mapped);
        if (!isMounted) return;
        setConversations(deduplicated);
        // Enrich with vendor details (name + profile image)
        try {
          const uniqueVendorIds = [
            ...new Set(mapped.map((c) => c.vendorId).filter(Boolean)),
          ];
          if (uniqueVendorIds.length > 0) {
            const details = await Promise.all(
              uniqueVendorIds.map((id) =>
                vendorsApi
                  .getVendorById(id)
                  .then((d) => ({ id, data: d }))
                  .catch(() => ({ id, data: null }))
              )
            );
            const idToVendor = new Map();
            details.forEach(({ id, data }) => {
              if (!data) return;
              const v = data?.data || data;
              idToVendor.set(id, {
                name: v.businessName || v.name || "Vendor",
                image: v.profileImage || v.image || null,
                lastActiveAt: v.lastActiveAt || null,
              });
            });
            if (!isMounted) return;
            setConversations((prev) => {
              const enriched = prev.map((c) => {
                const v = idToVendor.get(c.vendorId);
                return v
                  ? {
                    ...c,
                    vendorName: v.name || c.vendorName,
                    vendorImage: v.image || c.vendorImage,
                    vendorLastActiveAt:
                      v.lastActiveAt || c.vendorLastActiveAt,
                  }
                  : c;
              });
              // Re-deduplicate after enrichment to ensure no duplicates
              return deduplicateConversations(enriched);
            });
          }
        } catch {
          // ignore enrichment errors
        }
        if (deduplicated.length > 0 && !activeConversationId) {
          setActiveConversationId(deduplicated[0].id);
        }
      } catch (e) {
        if (!isMounted) return;
        setError(e.message || "Failed to load conversations");
      } finally {
        if (isMounted) setLoadingConversations(false);
      }
    };
    if (token) load();
    return () => {
      isMounted = false;
    };
  }, [token]);

  // Load messages when conversation changes
  useEffect(() => {
    let isMounted = true;
    const loadMsgs = async () => {
      if (!activeConversationId) return;
      setLoadingMessages(true);
      setError(null);
      try {
        const res = await messagesApi.getMessages(activeConversationId, {
          page: 1,
          limit: 50,
        });
        const list = Array.isArray(res)
          ? res
          : res?.data || res?.messages || [];
        const mapped = list.map((m) => normalizeMessage(m, user?.id));
        if (!isMounted) return;
        setMessages(mapped);
      } catch (e) {
        if (!isMounted) return;
        setError(e.message || "Failed to load messages");
      } finally {
        if (isMounted) setLoadingMessages(false);
      }
    };
    if (token) loadMsgs();
    return () => {
      isMounted = false;
    };
  }, [token, activeConversationId, user?.id]);

  // Removed continuous polling to prevent repeated API calls.

  const sendMessage = async (text) => {
    if (!text || !text.trim()) return;
    if (!activeConversationId) return;
    const optimistic = {
      id: `tmp-${Date.now()}`,
      sender: "user",
      name: "You",
      text: text.trim(),
      time: new Date().toISOString(),
    };
    setMessages((m) => [...m, optimistic]);
    setInput("");
    try {
      const res = await messagesApi.sendMessage(activeConversationId, {
        message: text.trim(),
        // Provide receiver info to satisfy backend NOT NULL receiverId
        receiverId: activeConversation?.vendorId,
        receiverType: "vendor",
      });
      // Backend returns created message object directly
      const saved = res && typeof res === "object" ? res : null;
      if (saved) {
        const normalized = normalizeMessage(saved, user?.id);
        setMessages((m) =>
          m.map((x) => (x.id === optimistic.id ? normalized : x))
        );
        // update conversation preview/time locally
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
      // rollback optimistic
      setMessages((m) => m.filter((x) => x.id !== optimistic.id));
    }
  };

  const handleQuick = (label) => sendMessage(label);

  return (
    <div className="container my-4 chat-wrapper">
      <style>{` 
        .chat-wrapper { font-size: 0.93rem; color: #1f2933; }
        .chat-card { min-height: 540px; max-height: 80vh; }
        .chat-section-title { letter-spacing: .2px; }
        .vendor-name { font-size: 1rem; }
        .vendor-preview { font-size: 0.875rem; }
        .chat-header-name { font-size: 1rem; }
        .chat-header-status { font-size: 0.875rem; }
        .msg-bubble { max-width: 100%; padding: .55rem .75rem; border-radius: 14px; line-height:1.25; font-size:0.93rem;}
        .msg-vendor { background: #fff; color: #212529; border-top-left-radius: 4px; border: 1px solid #e0e0e0; }
        .msg-user { background: rgb(237 17 115); color: #fff; border-top-right-radius: 4px; }
        .msg-time { font-size: .78rem; color: #6c757d; }
        .chat-scroll { overflow-y: auto; max-height: 58vh; padding-right: 8px; }
        .vendor-card { cursor: pointer; transition: background .2s; }
        .vendor-card:hover { background:#f8f9fa; }
        .chip-scroll { overflow-x:auto; -webkit-overflow-scrolling: touch; }
        .chip-scroll::-webkit-scrollbar { display: none; }
        .epr-emoji-category-label{ display: none; }
        .epr-emoji-category h2{display:none}
      `}</style>

      <div className="row g-3">
        {/* Left: Vendors List */}
        <div className="col-12 col-md-4">
          <div className="card border-0 rounded-4 shadow-sm p-3 h-100">
            <h6 className="fw-bold mb-3 chat-section-title text-dark fs-16">
              Vendors
            </h6>
            <div className="list-group">
              {loadingConversations ? (
                <div className="p-3 text-muted small">
                  Loading conversations…
                </div>
              ) : conversations.length === 0 ? (
                <div className="p-3 text-muted small">
                  No conversations yet.
                </div>
              ) : (
                conversations.map((c) => (
                  <div
                    key={c.id}
                    className={`list-group-item border-0 vendor-card rounded-3 mb-2 p-3 ${activeConversationId === c.id ? "bg-light" : ""
                      }`}
                    onClick={() => selectConversation(c.id)}
                  >
                    <div className="d-flex align-items-center overflow-hidden">
                      <Avatar
                        name={c.vendorName}
                        imageUrl={c.vendorImage}
                        size={40}
                      />
                      <div className="ms-3">
                        <div className="d-flex align-items-center">
                          <div className="fw-bold me-2 vendor-name fs-16 inter">
                            {c.vendorName}
                          </div>
                        </div>
                        <div className="text-muted text-truncate vendor-preview fs-14 inter">
                          {c.lastMessagePreview || c.vendorDescription || ""}
                        </div>
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>

        {/* Right: Chat Panel */}
        <div className="col-12 col-md-8">
          <div className="card border-0 rounded-4 shadow-sm chat-card d-flex flex-column">
            {/* Header */}
            <div className="card-body border-bottom py-3 d-flex align-items-center justify-content-between">
              <div className="d-flex align-items-center">
                <Avatar
                  name={activeConversation?.vendorName || "Vendor"}
                  imageUrl={activeConversation?.vendorImage}
                  size={44}
                />
                <div className="ms-3">
                  <div className="fw-bold chat-header-name text-dark fs-16 inter">
                    {activeConversation?.vendorName || "Select a conversation"}
                  </div>
                  <div className="text-muted chat-header-status fs-14 inter">
                    {isOnline(activeConversation?.vendorLastActiveAt)
                      ? "Online"
                      : `Last seen ${activeConversation?.vendorLastActiveAt
                        ? formatTime(activeConversation.vendorLastActiveAt)
                        : formatTime(new Date().toISOString())
                      }`}
                  </div>
                </div>
              </div>
              <div className="text-muted d-none d-md-block fs-14 inter">
                <FiClock className="me-1" /> {new Date().toLocaleDateString()}
              </div>
            </div>

            {/* Messages */}
            <div className="card-body chat-scroll" ref={scrollRef}>
              {error && !loadingMessages && activeConversationId ? (
                <div
                  className="alert alert-danger py-2 px-3 small"
                  role="alert"
                >
                  {error || "Failed to load messages."}
                </div>
              ) : loadingMessages ? (
                <div className="text-muted small inter">Loading messages…</div>
              ) : !activeConversationId ? (
                <div className="text-muted fs-14 inter">Select a conversation</div>
              ) : (
                <div className="d-flex flex-column gap-3">
                  {messages.map((m) => (
                    <div
                      key={m.id}
                      className={`d-flex ${m.sender === "user"
                        ? "justify-content-end"
                        : "justify-content-start"
                        }`}
                    >
                      {m.sender === "vendor" ? (
                        <div className="d-flex align-items-start">
                          <div className="me-2">
                            <Avatar
                              name={m.name}
                              imageUrl={activeConversation?.vendorImage}
                              size={36}
                            />
                          </div>
                          <div>
                            <div className="msg-time mb-1 fs-14 fw-bold  inter">
                              {m.name} • {formatTime(m.time)}
                            </div>
                            <div className="msg-bubble msg-vendor fs-14  inter">
                              {m.text}
                            </div>
                          </div>
                        </div>
                      ) : (
                        <div className="d-flex align-items-end">
                          <div
                            className="me-2 text-end"
                            style={{ marginRight: 8 }}
                          >
                            <div className="msg-time mb-1 fs-14 fw-bold inter">
                              {formatTime(m.time)}
                            </div>
                            <div className="msg-bubble msg-user fs-14 inter">
                              {m.text}
                            </div>
                          </div>
                          <Avatar
                            name="You"
                            imageUrl={userImageUrl}
                            size={36}
                          />
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Quick chips */}
            <div className="px-3 pt-2">
              <div className="chip-scroll d-flex align-items-center py-2">
                {quickReplies.map((q) => (
                  <QuickChip key={q} label={q} onClick={handleQuick} />
                ))}
              </div>
            </div>

            {/* Input */}
            <div className="card-body border-top py-3">
              <div className="d-flex align-items-center gap-2">
                <div style={{ position: "relative" }}>
                  <button
                    type="button"
                    className="btn btn-light inter"
                    onClick={() => setShowEmoji((prev) => !prev)}
                  >
                    <FiSmile />
                  </button>

                  {showEmoji && (
                    <div
                      style={{
                        position: "absolute",
                        bottom: "48px",
                        left: 0,
                        zIndex: 9999,
                      }}
                    >
                      <EmojiPicker
                        onEmojiClick={(emojiData) => {
                          setInput((prev) => prev + emojiData.emoji);
                          setShowEmoji(false);
                        }}
                        theme="light"
                      />
                    </div>
                  )}
                </div>
                <input
                  type="text"
                  className="form-control fs-14 inter"
                  placeholder="Type a message..."
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && sendMessage(input)}
                />
                <button
                  className="btn btn-primary d-flex align-items-center justify-content-center  inter"
                  onClick={() => sendMessage(input)}
                  style={{ height: "40px", width: "44px", borderRadius: 8 }}
                >
                  <FiSend color="white" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Messages;
