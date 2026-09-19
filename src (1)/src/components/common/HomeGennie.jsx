import React, { Suspense, lazy, useEffect, useRef, useState } from "react";
import { History, Minimize2, Plus, SendHorizonal, Trash2 } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { FaMagic } from "react-icons/fa";
import useShaadiAI, { STARTER_PROMPTS } from "../shaadiai/useShaadiAI";
import styles from "./HomeGennie.module.css";

// MessageBody carries the four guided-feature forms and the whole /shaadi-ai
// stylesheet — ~71KB that only matters once there is a reply to draw. This
// component mounts on idle on every page of the site, so importing it eagerly
// would put all of that back in the idle-load budget the launcher was tuned to
// keep small. It is fetched when the panel opens instead (see handleOpenClick),
// which is well before the first response can arrive.
const MessageBody = lazy(() => import("../shaadiai/MessageBody"));

// The corner assistant used to be a second, separate AI: it posted to
// shaadiai.happywedz.com/api/user_chat and could only ever render a summary
// plus generic name/location cards. It now runs the same engine as /shaadi-ai
// — POST /ai/chat, the four guided features, vendor/product/order/budget cards
// and the shared chat history — so an answer is the same answer in both places.

// /ai/chat is optionalAuthenticate: it answers anyone and only personalises for
// a signed-in visitor, which is exactly how the full page behaves. The widget
// used to bounce visitors to /customer-login before they could even open it.
// Flip this back to true to restore that gate.
const REQUIRE_LOGIN = false;

const HomeGennie = () => {
  const navigate = useNavigate();
  const [isChatOpen, setIsChatOpen] = useState(false);
  const [showRecent, setShowRecent] = useState(false);

  const {
    messages,
    input,
    setInput,
    loading,
    chatList,
    activeChatId,
    isInitialState,
    handleSend,
    handleFeatureComplete,
    handleNewChat,
    handleLoadChat,
    handleDeleteChat,
  } = useShaadiAI();

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

  useEffect(() => {
    const el = messageContainerRef.current;
    if (!el) return;
    requestAnimationFrame(() => {
      el.scrollTo({ top: el.scrollHeight, behavior: "smooth" });
    });
  }, [messages, loading]);

  const handleOpenClick = () => {
    if (!REQUIRE_LOGIN || localStorage.getItem("token")) {
      setIsChatOpen(true);
      // Warm the reply renderer while the visitor is still reading the openers,
      // so it is never the thing a first answer waits on. Vite dedupes this
      // against the lazy() import above.
      import("../shaadiai/MessageBody");
    } else {
      navigate("/customer-login", { state: { from: "/shaadi-ai" } });
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      if (!loading) handleSend();
    }
  };

  const openRecentChat = (chatId) => {
    handleLoadChat(chatId);
    setShowRecent(false);
  };

  const startNewChat = () => {
    handleNewChat();
    setShowRecent(false);
  };

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
        <div className={styles.panel}>
          <div className={styles.header}>
            <div className={styles.headerMain}>
              <div className={styles.headerLogo}>
                <img src="/shaadi.jpg" alt="" />
              </div>
              <h5 className={styles.headerTitle}>Ask our AI anything</h5>
            </div>

            <button
              className={`${styles.iconBtn} ${showRecent ? styles.iconBtnActive : ""}`}
              onClick={() => setShowRecent((v) => !v)}
              aria-label="Recent chats"
              aria-expanded={showRecent}
            >
              <History size={17} />
            </button>

            {/* Collapses the panel back to the launcher. The conversation is
                kept — reopening resumes it, and it is saved to the shared
                history either way. */}
            <button
              className={styles.iconBtn}
              onClick={() => setIsChatOpen(false)}
              aria-label="Minimize chat"
            >
              <Minimize2 size={16} />
            </button>
          </div>

          {showRecent && (
            <div className={styles.recentDrawer}>
              <span className={styles.recentLabel}>Recent</span>
              {chatList.length === 0 && (
                <p className={styles.recentEmpty}>No saved chats yet</p>
              )}
              {chatList.map((chat) => (
                <div
                  key={chat.id}
                  className={`${styles.recentItem} ${
                    activeChatId === chat.id ? styles.recentItemActive : ""
                  }`}
                  onClick={() => openRecentChat(chat.id)}
                >
                  <span className={styles.recentTitle}>{chat.title}</span>
                  <button
                    className={styles.recentDelete}
                    onClick={(e) => handleDeleteChat(e, chat.id)}
                    aria-label="Delete chat"
                  >
                    <Trash2 size={14} />
                  </button>
                </div>
              ))}
            </div>
          )}

          <div ref={messageContainerRef} className={styles.messages}>
            {isInitialState && !loading && (
              <div>
                <div className={styles.welcome}>
                  <div className={styles.welcomeLogo}>
                    <img src="/shaadi.jpg" alt="" />
                  </div>
                  <h3 className={styles.welcomeTitle}>
                    Welcome to Wedding ShaadiAI! ✨
                  </h3>
                  <p className={styles.welcomeSub}>
                    Let&apos;s plan your dream wedding together
                  </p>
                </div>

                {/* The same openers the full page offers — the last four open a
                    guided feature inline rather than calling the model. */}
                <div className={styles.startersLabel}>
                  <FaMagic /> Try Shaadi AI
                </div>
                <div className={styles.starterGrid}>
                  {STARTER_PROMPTS.map((prompt) => (
                    <button
                      key={prompt.send}
                      className={styles.starterPill}
                      onClick={() => handleSend(prompt.send)}
                    >
                      <span className={styles.starterTitle}>
                        {prompt.icon} {prompt.title}
                      </span>
                      <p className={styles.starterSub}>{prompt.subtitle}</p>
                    </button>
                  ))}
                </div>
              </div>
            )}

            {messages.map((msg, index) => {
              // index 0 is the greeting the empty state already covers.
              if (index === 0) return null;

              return (
                <div
                  key={index}
                  className={`${styles.row} ${
                    msg.role === "user" ? styles.rowUser : styles.rowAi
                  }`}
                >
                  {msg.role === "ai" && (
                    <div className={styles.avatar}>
                      <img src="/shaadi.jpg" alt="" />
                    </div>
                  )}
                  <div
                    className={`${styles.bubble} ${
                      msg.role === "user" ? styles.bubbleUser : styles.bubbleAi
                    }`}
                  >
                    {msg.role === "user" ? (
                      msg.content
                    ) : (
                      <Suspense fallback={<div className={styles.typingDots}><span /><span /><span /></div>}>
                        <MessageBody
                          msg={msg}
                          compact
                          onFeatureComplete={handleFeatureComplete}
                        />
                      </Suspense>
                    )}
                  </div>
                </div>
              );
            })}

            {loading && (
              <div className={`${styles.row} ${styles.rowAi}`}>
                <div className={styles.avatar}>
                  <img src="/shaadi.jpg" alt="" />
                </div>
                <div className={styles.typingBubble}>
                  <div className={styles.typingDots}>
                    <span />
                    <span />
                    <span />
                  </div>
                </div>
              </div>
            )}
          </div>

          <div className={styles.composer}>
            <button
              className={styles.newChatBtn}
              onClick={startNewChat}
              aria-label="New chat"
            >
              <Plus size={20} />
            </button>
            <div className={styles.inputWrap}>
              <input
                type="text"
                className={styles.input}
                placeholder="Ask anything about your wedding..."
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={handleKeyDown}
                disabled={loading}
              />
              <button
                className={styles.sendBtn}
                onClick={() => handleSend()}
                disabled={!input.trim() || loading}
                aria-label="Send"
              >
                <SendHorizonal size={16} />
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default HomeGennie;
