import React, { useState, useEffect } from "react";
import {
  X,
  Paperclip,
  Smile,
  Link2,
  Image,
  Bold,
  Italic,
  Underline,
  List,
  ListOrdered,
  User,
} from "lucide-react";

const EmailModal = ({
  show = false,
  onClose,
  onSend,
  sending = false,
  userEmail = "",
  userName = "",
}) => {
  const [toEmails, setToEmails] = useState([]);
  const [currentInput, setCurrentInput] = useState("");
  const [subject, setSubject] = useState("");
  const [message, setMessage] = useState("");
  const [showCC, setShowCC] = useState(false);
  const [showBCC, setShowBCC] = useState(false);
  const [ccEmails, setCcEmails] = useState([]);
  const [bccEmails, setBccEmails] = useState([]);
  const [ccInput, setCcInput] = useState("");
  const [bccInput, setBccInput] = useState("");
  const [emailError, setEmailError] = useState("");

  useEffect(() => {
    if (!show) {
      setToEmails([]);
      setCurrentInput("");
      setSubject("");
      setMessage("");
      setShowCC(false);
      setShowBCC(false);
      setCcEmails([]);
      setBccEmails([]);
      setCcInput("");
      setBccInput("");
      setEmailError("");
    } else {
      // Set default subject when modal opens
      setSubject((prev) => prev || "Guest List");
    }
  }, [show]);

  const validateEmail = (email) => {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  };

  const addEmailsFromText = (text, type = "to") => {
    // Split by comma, semicolon, space, or newline and filter out empty strings
    const emailList = text
      .split(/[,;\s\n]+/)
      .map((email) => email.trim())
      .filter((email) => email.length > 0);

    const validEmails = [];
    const invalidEmails = [];
    const duplicateEmails = [];

    emailList.forEach((email) => {
      if (!validateEmail(email)) {
        invalidEmails.push(email);
        return;
      }

      if (type === "to") {
        if (toEmails.includes(email)) {
          duplicateEmails.push(email);
          return;
        }
        validEmails.push(email);
      } else if (type === "cc") {
        if (ccEmails.includes(email)) {
          duplicateEmails.push(email);
          return;
        }
        validEmails.push(email);
      } else if (type === "bcc") {
        if (bccEmails.includes(email)) {
          duplicateEmails.push(email);
          return;
        }
        validEmails.push(email);
      }
    });

    // Add valid emails
    if (validEmails.length > 0) {
      if (type === "to") {
        setToEmails([...toEmails, ...validEmails]);
        setCurrentInput("");
      } else if (type === "cc") {
        setCcEmails([...ccEmails, ...validEmails]);
        setCcInput("");
      } else if (type === "bcc") {
        setBccEmails([...bccEmails, ...validEmails]);
        setBccInput("");
      }
    }

    // Show error messages
    if (invalidEmails.length > 0) {
      setEmailError(
        `Invalid email${
          invalidEmails.length > 1 ? "s" : ""
        }: ${invalidEmails.join(", ")}`
      );
    } else if (duplicateEmails.length > 0) {
      setEmailError(
        `Email${
          duplicateEmails.length > 1 ? "s" : ""
        } already added: ${duplicateEmails.join(", ")}`
      );
    } else if (validEmails.length === 0 && emailList.length > 0) {
      setEmailError("No valid emails to add");
    } else {
      setEmailError("");
    }
  };

  const handleAddEmail = (e, type = "to") => {
    if (e.key === "Enter" || e.key === ",") {
      e.preventDefault();
      const inputValue =
        type === "to" ? currentInput : type === "cc" ? ccInput : bccInput;

      if (!inputValue.trim()) {
        return;
      }

      // Check if input contains multiple emails (comma, semicolon, or space separated)
      if (
        inputValue.includes(",") ||
        inputValue.includes(";") ||
        inputValue.includes(" ")
      ) {
        addEmailsFromText(inputValue, type);
      } else {
        // Single email
        const email = inputValue.trim();
        setEmailError("");

        if (!email) {
          setEmailError("Please enter an email address");
          return;
        }

        if (!validateEmail(email)) {
          setEmailError("Please enter a valid email address");
          return;
        }

        if (type === "to") {
          if (toEmails.includes(email)) {
            setEmailError("This email is already added");
            return;
          }
          setToEmails([...toEmails, email]);
          setCurrentInput("");
        } else if (type === "cc") {
          if (ccEmails.includes(email)) {
            setEmailError("This email is already added");
            return;
          }
          setCcEmails([...ccEmails, email]);
          setCcInput("");
        } else if (type === "bcc") {
          if (bccEmails.includes(email)) {
            setEmailError("This email is already added");
            return;
          }
          setBccEmails([...bccEmails, email]);
          setBccInput("");
        }
        setEmailError("");
      }
    }
  };

  const handlePaste = (e, type = "to") => {
    e.preventDefault();
    const pastedText = e.clipboardData.getData("text");

    if (
      pastedText.includes(",") ||
      pastedText.includes(";") ||
      pastedText.includes("\n") ||
      pastedText.includes(" ")
    ) {
      // Multiple emails pasted
      addEmailsFromText(pastedText, type);
    } else {
      // Single email - let default paste behavior happen
      const input = e.target;
      const start = input.selectionStart;
      const end = input.selectionEnd;
      const value = input.value;
      const newValue =
        value.substring(0, start) + pastedText + value.substring(end);

      if (type === "to") {
        setCurrentInput(newValue);
      } else if (type === "cc") {
        setCcInput(newValue);
      } else if (type === "bcc") {
        setBccInput(newValue);
      }
    }
  };

  const handleAddEmailButton = (type = "to") => {
    const inputValue =
      type === "to" ? currentInput : type === "cc" ? ccInput : bccInput;

    if (!inputValue.trim()) {
      setEmailError("Please enter an email address");
      return;
    }

    // Check if input contains multiple emails
    if (
      inputValue.includes(",") ||
      inputValue.includes(";") ||
      inputValue.includes(" ")
    ) {
      addEmailsFromText(inputValue, type);
    } else {
      // Single email
      const email = inputValue.trim();
      setEmailError("");

      if (!validateEmail(email)) {
        setEmailError("Please enter a valid email address");
        return;
      }

      if (type === "to") {
        if (toEmails.includes(email)) {
          setEmailError("This email is already added");
          return;
        }
        setToEmails([...toEmails, email]);
        setCurrentInput("");
      } else if (type === "cc") {
        if (ccEmails.includes(email)) {
          setEmailError("This email is already added");
          return;
        }
        setCcEmails([...ccEmails, email]);
        setCcInput("");
      } else if (type === "bcc") {
        if (bccEmails.includes(email)) {
          setEmailError("This email is already added");
          return;
        }
        setBccEmails([...bccEmails, email]);
        setBccInput("");
      }
      setEmailError("");
    }
  };

  const removeEmail = (email, type = "to") => {
    if (type === "to") {
      setToEmails(toEmails.filter((e) => e !== email));
    } else if (type === "cc") {
      setCcEmails(ccEmails.filter((e) => e !== email));
    } else if (type === "bcc") {
      setBccEmails(bccEmails.filter((e) => e !== email));
    }
  };

  const handleSend = () => {
    if (toEmails.length === 0) {
      setEmailError("Please add at least one recipient email");
      return;
    }

    if (!subject.trim()) {
      setEmailError("Please enter a subject");
      return;
    }

    const payload = {
      toEmail: toEmails,
      ccEmail: ccEmails.length > 0 ? ccEmails : undefined,
      bccEmail: bccEmails.length > 0 ? bccEmails : undefined,
      subject: subject.trim(),
      message: message.trim(),
    };

    if (onSend) {
      onSend(payload);
    }
  };

  if (!show) return null;

  return (
    <div
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: "rgba(0, 0, 0, 0.5)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 1050,
        padding: "20px",
      }}
    >
      <div
        style={{
          backgroundColor: "white",
          width: "100%",
          maxWidth: "800px",
          maxHeight: "90vh",
          display: "flex",
          flexDirection: "column",
          boxShadow: "0 10px 40px rgba(0, 0, 0, 0.2)",
          borderRadius: "20px",
          overflow: "hidden",
        }}
      >
        <div
          style={{
            padding: "20px 24px",
            borderBottom: "1px solid #e5e7eb",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            backgroundColor: "#f9fafb",
          }}
        >
          <h3
            style={{
              margin: 0,
              fontSize: "18px",
              fontWeight: "600",
              color: "#111827",
            }}
          >
            New mail
          </h3>
          <div style={{ display: "flex", gap: "8px" }}>
            <button
              onClick={onClose}
              style={{
                background: "none",
                border: "none",
                padding: "8px",
                cursor: "pointer",
                color: "#6b7280",
              }}
            >
              <X size={20} />
            </button>
          </div>
        </div>

        {/* Body */}
        <div
          style={{
            flex: 1,
            overflowY: "auto",
            padding: "24px",
          }}
        >
          {/* From */}
          <div style={{ marginBottom: "16px" }}>
            <label
              style={{
                fontSize: "14px",
                color: "#6b7280",
                marginBottom: "8px",
                display: "block",
              }}
            >
              From
            </label>
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: "8px",
                padding: "8px 0",
              }}
            >
              <div
                style={{
                  width: "32px",
                  height: "32px",
                  borderRadius: "50%",
                  backgroundColor: "#C31162",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: "white",
                  fontWeight: "600",
                  fontSize: "14px",
                }}
              >
                <User size={18} />
              </div>
              <span
                style={{
                  fontSize: "14px",
                  color: "#111827",
                  fontWeight: "500",
                }}
              >
                {userName || "User"}{" "}
                <span style={{ color: "#6b7280", fontWeight: "400" }}>
                  {userEmail ? `(${userEmail})` : "(me)"}
                </span>
              </span>
            </div>
          </div>

          {/* To */}
          <div style={{ marginBottom: "16px" }}>
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                marginBottom: "8px",
              }}
            >
              <label
                style={{
                  fontSize: "14px",
                  color: "#6b7280",
                }}
              >
                To
              </label>
              <div style={{ display: "flex", gap: "12px" }}>
                <button
                  onClick={() => setShowCC(!showCC)}
                  style={{
                    background: "none",
                    border: "none",
                    fontSize: "13px",
                    color: "#6b7280",
                    cursor: "pointer",
                    fontWeight: showCC ? "600" : "400",
                  }}
                >
                  CC
                </button>
                <button
                  onClick={() => setShowBCC(!showBCC)}
                  style={{
                    background: "none",
                    border: "none",
                    fontSize: "13px",
                    color: "#6b7280",
                    cursor: "pointer",
                    fontWeight: showBCC ? "600" : "400",
                  }}
                >
                  BCC
                </button>
              </div>
            </div>
            <div
              style={{
                display: "flex",
                flexWrap: "wrap",
                gap: "8px",
                padding: "8px 12px",
                border: "1px solid #e5e7eb",
                borderRadius: "8px",
                minHeight: "44px",
                alignItems: "center",
                backgroundColor: "white",
              }}
            >
              {toEmails.map((email, index) => (
                <span
                  key={index}
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: "6px",
                    padding: "4px 10px",
                    backgroundColor: "#f3f4f6",
                    borderRadius: "16px",
                    fontSize: "13px",
                    color: "#111827",
                  }}
                >
                  <div
                    style={{
                      width: "24px",
                      height: "24px",
                      borderRadius: "50%",
                      backgroundColor: index === 0 ? "#10b981" : "#06b6d4",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      color: "white",
                      fontSize: "11px",
                      fontWeight: "600",
                    }}
                  >
                    {email.charAt(0).toUpperCase()}
                  </div>
                  {email.split("@")[0]}
                  <button
                    onClick={() => removeEmail(email, "to")}
                    style={{
                      background: "none",
                      border: "none",
                      padding: "0",
                      cursor: "pointer",
                      color: "#6b7280",
                      display: "flex",
                      alignItems: "center",
                    }}
                  >
                    <X size={14} />
                  </button>
                </span>
              ))}
              <input
                type="text"
                value={currentInput}
                onChange={(e) => {
                  setCurrentInput(e.target.value);
                  setEmailError("");
                }}
                onKeyDown={(e) => handleAddEmail(e, "to")}
                onPaste={(e) => handlePaste(e, "to")}
                placeholder={
                  toEmails.length === 0
                    ? "Enter email address(es) - separate with comma, semicolon, or space"
                    : ""
                }
                style={{
                  border: "none",
                  outline: "none",
                  flex: 1,
                  minWidth: "120px",
                  fontSize: "14px",
                  padding: "4px",
                }}
              />
              <button
                onClick={() => handleAddEmailButton("to")}
                disabled={!currentInput.trim()}
                style={{
                  marginLeft: "8px",
                  padding: "6px 10px",
                  backgroundColor: currentInput.trim() ? "#C31162" : "#e5e7eb",
                  color: currentInput.trim() ? "#fff" : "#6b7280",
                  border: "none",
                  borderRadius: "6px",
                  cursor: currentInput.trim() ? "pointer" : "not-allowed",
                  fontSize: "13px",
                  fontWeight: 600,
                }}
                title="Add email"
              >
                Add
              </button>
            </div>
            {emailError && toEmails.length === 0 && (
              <div
                style={{
                  color: "#dc2626",
                  fontSize: "12px",
                  marginTop: "4px",
                  paddingLeft: "4px",
                }}
              >
                {emailError}
              </div>
            )}
          </div>

          {/* CC */}
          {showCC && (
            <div style={{ marginBottom: "16px" }}>
              <label
                style={{
                  fontSize: "14px",
                  color: "#6b7280",
                  marginBottom: "8px",
                  display: "block",
                }}
              >
                CC
              </label>
              <div
                style={{
                  display: "flex",
                  flexWrap: "wrap",
                  gap: "8px",
                  padding: "8px 12px",
                  border: "1px solid #e5e7eb",
                  borderRadius: "8px",
                  minHeight: "44px",
                  alignItems: "center",
                  backgroundColor: "white",
                }}
              >
                {ccEmails.map((email, index) => (
                  <span
                    key={index}
                    style={{
                      display: "inline-flex",
                      alignItems: "center",
                      gap: "6px",
                      padding: "4px 10px",
                      backgroundColor: "#f3f4f6",
                      borderRadius: "16px",
                      fontSize: "13px",
                      color: "#111827",
                    }}
                  >
                    {email}
                    <button
                      onClick={() => removeEmail(email, "cc")}
                      style={{
                        background: "none",
                        border: "none",
                        padding: "0",
                        cursor: "pointer",
                        color: "#6b7280",
                      }}
                    >
                      <X size={14} />
                    </button>
                  </span>
                ))}
                <input
                  type="text"
                  value={ccInput}
                  onChange={(e) => {
                    setCcInput(e.target.value);
                    setEmailError("");
                  }}
                  onKeyDown={(e) => handleAddEmail(e, "cc")}
                  onPaste={(e) => handlePaste(e, "cc")}
                  placeholder="Add CC recipients (separate with comma, semicolon, or space)"
                  style={{
                    border: "none",
                    outline: "none",
                    flex: 1,
                    minWidth: "120px",
                    fontSize: "14px",
                    padding: "4px",
                  }}
                />
              </div>
            </div>
          )}

          {/* BCC */}
          {showBCC && (
            <div style={{ marginBottom: "16px" }}>
              <label
                style={{
                  fontSize: "14px",
                  color: "#6b7280",
                  marginBottom: "8px",
                  display: "block",
                }}
              >
                BCC
              </label>
              <div
                style={{
                  display: "flex",
                  flexWrap: "wrap",
                  gap: "8px",
                  padding: "8px 12px",
                  border: "1px solid #e5e7eb",
                  borderRadius: "8px",
                  minHeight: "44px",
                  alignItems: "center",
                  backgroundColor: "white",
                }}
              >
                {bccEmails.map((email, index) => (
                  <span
                    key={index}
                    style={{
                      display: "inline-flex",
                      alignItems: "center",
                      gap: "6px",
                      padding: "4px 10px",
                      backgroundColor: "#f3f4f6",
                      borderRadius: "16px",
                      fontSize: "13px",
                      color: "#111827",
                    }}
                  >
                    {email}
                    <button
                      onClick={() => removeEmail(email, "bcc")}
                      style={{
                        background: "none",
                        border: "none",
                        padding: "0",
                        cursor: "pointer",
                        color: "#6b7280",
                      }}
                    >
                      <X size={14} />
                    </button>
                  </span>
                ))}
                <input
                  type="text"
                  value={bccInput}
                  onChange={(e) => {
                    setBccInput(e.target.value);
                    setEmailError("");
                  }}
                  onKeyDown={(e) => handleAddEmail(e, "bcc")}
                  onPaste={(e) => handlePaste(e, "bcc")}
                  placeholder="Add BCC recipients (separate with comma, semicolon, or space)"
                  style={{
                    border: "none",
                    outline: "none",
                    flex: 1,
                    minWidth: "120px",
                    fontSize: "14px",
                    padding: "4px",
                  }}
                />
              </div>
            </div>
          )}

          {/* Subject */}
          <div style={{ marginBottom: "16px" }}>
            <label
              style={{
                fontSize: "14px",
                color: "#6b7280",
                marginBottom: "8px",
                display: "block",
              }}
            >
              Subject <span style={{ color: "#dc2626" }}>*</span>
            </label>
            <input
              type="text"
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              placeholder="Enter email subject (required)"
              style={{
                width: "100%",
                padding: "10px 12px",
                border: subject.trim()
                  ? "1px solid #e5e7eb"
                  : "1px solid #dc2626",
                borderRadius: "8px",
                fontSize: "14px",
                outline: "none",
                transition: "border-color 0.2s",
              }}
              onFocus={(e) => (e.target.style.borderColor = "#C31162")}
              onBlur={(e) =>
                (e.target.style.borderColor = subject.trim()
                  ? "#e5e7eb"
                  : "#dc2626")
              }
            />
            {!subject.trim() && (
              <div
                style={{ color: "#dc2626", fontSize: "12px", marginTop: "4px" }}
              >
                Subject is required
              </div>
            )}
          </div>

          {/* Message */}
          <div style={{ marginBottom: "16px" }}>
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Type your message here..."
              style={{
                width: "100%",
                minHeight: "180px",
                padding: "12px",
                border: "1px solid #e5e7eb",
                borderRadius: "8px",
                fontSize: "14px",
                outline: "none",
                resize: "vertical",
                fontFamily: "inherit",
                transition: "border-color 0.2s",
              }}
              onFocus={(e) => (e.target.style.borderColor = "#C31162")}
              onBlur={(e) => (e.target.style.borderColor = "#e5e7eb")}
            />
          </div>
        </div>

        {/* Footer */}
        <div
          style={{
            padding: "16px 24px",
            borderTop: "1px solid #e5e7eb",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            backgroundColor: "#f9fafb",
          }}
        >
          <div style={{ display: "flex", gap: "8px" }}>
            {/* <button
              style={{
                padding: "8px",
                background: "none",
                border: "none",
                cursor: "pointer",
                color: "#6b7280",
                borderRadius: "6px",
              }}
              title="Attach file"
            >
              <Paperclip size={18} />
            </button>
            <button
              style={{
                padding: "8px",
                background: "none",
                border: "none",
                cursor: "pointer",
                color: "#6b7280",
                borderRadius: "6px",
              }}
              title="Insert emoji"
            >
              <Smile size={18} />
            </button>
            <button
              style={{
                padding: "8px",
                background: "none",
                border: "none",
                cursor: "pointer",
                color: "#6b7280",
                borderRadius: "6px",
              }}
              title="Insert link"
            >
              <Link2 size={18} />
            </button>
            <button
              style={{
                padding: "8px",
                background: "none",
                border: "none",
                cursor: "pointer",
                color: "#6b7280",
                borderRadius: "6px",
              }}
              title="Insert image"
            >
              <Image size={18} />
            </button>
            <div
              style={{
                width: "1px",
                backgroundColor: "#e5e7eb",
                margin: "0 4px",
              }}
            />
            <button
              style={{
                padding: "8px",
                background: "none",
                border: "none",
                cursor: "pointer",
                color: "#6b7280",
                fontWeight: "600",
                borderRadius: "6px",
              }}
              title="Bold"
            >
              <Bold size={18} />
            </button>
            <button
              style={{
                padding: "8px",
                background: "none",
                border: "none",
                cursor: "pointer",
                color: "#6b7280",
                fontStyle: "italic",
                borderRadius: "6px",
              }}
              title="Italic"
            >
              <Italic size={18} />
            </button>
            <button
              style={{
                padding: "8px",
                background: "none",
                border: "none",
                cursor: "pointer",
                color: "#6b7280",
                textDecoration: "underline",
                borderRadius: "6px",
              }}
              title="Underline"
            >
              <Underline size={18} />
            </button>
            <button
              style={{
                padding: "8px",
                background: "none",
                border: "none",
                cursor: "pointer",
                color: "#6b7280",
                borderRadius: "6px",
              }}
              title="Bulleted list"
            >
              <List size={18} />
            </button>
            <button
              style={{
                padding: "8px",
                background: "none",
                border: "none",
                cursor: "pointer",
                color: "#6b7280",
                borderRadius: "6px",
              }}
              title="Numbered list"
            >
              <ListOrdered size={18} />
            </button> */}
          </div>

          <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
            <button
              onClick={onClose}
              disabled={sending}
              style={{
                padding: "10px 20px",
                backgroundColor: "white",
                border: "1px solid #e5e7eb",
                borderRadius: "8px",
                fontSize: "14px",
                fontWeight: "500",
                cursor: sending ? "not-allowed" : "pointer",
                color: "#374151",
                opacity: sending ? 0.6 : 1,
              }}
            >
              Discard
            </button>
            <button
              onClick={handleSend}
              disabled={sending || toEmails.length === 0 || !subject.trim()}
              style={{
                padding: "10px 24px",
                backgroundColor:
                  sending || toEmails.length === 0 || !subject.trim()
                    ? "#9ca3af"
                    : "#C31162",
                color: "white",
                border: "none",
                borderRadius: "8px",
                fontSize: "14px",
                fontWeight: "600",
                cursor:
                  sending || toEmails.length === 0 || !subject.trim()
                    ? "not-allowed"
                    : "pointer",
                boxShadow:
                  sending || toEmails.length === 0 || !subject.trim()
                    ? "none"
                    : "0 2px 4px rgba(195, 17, 98, 0.2)",
                display: "flex",
                alignItems: "center",
                gap: "8px",
              }}
            >
              {sending ? (
                <>
                  <span
                    style={{
                      width: "14px",
                      height: "14px",
                      border: "2px solid white",
                      borderTop: "2px solid transparent",
                      borderRadius: "50%",
                      animation: "spin 0.8s linear infinite",
                    }}
                  />
                  Sending...
                </>
              ) : (
                "Send email"
              )}
            </button>
          </div>
        </div>
      </div>
      <style>{`
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
};

export default EmailModal;
