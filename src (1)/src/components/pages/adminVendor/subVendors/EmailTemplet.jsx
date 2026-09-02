import React, { useState } from "react";
import "bootstrap/dist/css/bootstrap.min.css";
import {
  Bold,
  Italic,
  Link,
  Scissors,
  List,
  ListOrdered,
  Undo,
  Redo,
  Paperclip,
} from "lucide-react";
export default function EmailTemplateForm() {
  const [templateName, setTemplateName] = useState("");
  const [subject, setSubject] = useState("");
  const [message, setMessage] = useState("");
  const [attachedFiles, setAttachedFiles] = useState([]);
  const handleFileAttach = (e) => {
    const files = Array.from(e.target.files);
    setAttachedFiles([...attachedFiles, ...files]);
  };
  const handleAddTemplate = () => {
    if (!templateName.trim()) {
      alert("Please enter a template name");
      return;
    }
    if (!subject.trim()) {
      alert("Please enter a subject");
      return;
    }
    alert("Template added successfully!");
  };
  const handleCancel = () => {
    setTemplateName("");
    setSubject("");
    setMessage("");
    setAttachedFiles([]);
  };
  const toolbarButtons = [
    { icon: Bold, title: "Bold" },
    { icon: Italic, title: "Italic" },
    { icon: Link, title: "Insert Link" },
    { icon: Scissors, title: "Remove Formatting" },
    { icon: List, title: "Bullet List" },
    { icon: ListOrdered, title: "Numbered List" },
    { icon: Undo, title: "Undo" },
    { icon: Redo, title: "Redo" },
  ];
  return (
    <div className="container py-4" style={{ maxWidth: "1200px" }}>
      {" "}
      <div className="card shadow-sm">
        {" "}
        <div className="card-body p-4">
          {" "}
          <div className="mb-4">
            {" "}
            <label
              className="form-label fw-semibold text-uppercase"
              style={{ fontSize: "0.875rem", letterSpacing: "0.5px" }}
            >
              {" "}
              TEMPLATE NAME{" "}
            </label>{" "}
            <input
              type="text"
              className="form-control"
              value={templateName}
              onChange={(e) => setTemplateName(e.target.value)}
              style={{ maxWidth: "500px" }}
            />{" "}
          </div>{" "}
          <div className="mb-4">
            {" "}
            <label
              className="form-label fw-semibold text-uppercase"
              style={{ fontSize: "0.875rem", letterSpacing: "0.5px" }}
            >
              {" "}
              SUBJECT{" "}
            </label>{" "}
            <input
              type="text"
              className="form-control"
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              style={{ maxWidth: "500px" }}
            />{" "}
          </div>{" "}
          <div className="mb-4">
            {" "}
            <label
              className="form-label fw-semibold text-uppercase"
              style={{ fontSize: "0.875rem", letterSpacing: "0.5px" }}
            >
              {" "}
              MESSAGE{" "}
            </label>{" "}
            <div className="border rounded">
              {" "}
              <div
                className="d-flex border-bottom bg-light"
                style={{
                  borderTopLeftRadius: "0.375rem",
                  borderTopRightRadius: "0.375rem",
                }}
              >
                {" "}
                {toolbarButtons.map((button, index) => (
                  <button
                    key={index}
                    className="btn btn-light border-0 rounded-0"
                    title={button.title}
                    style={{
                      padding: "0.5rem 0.75rem",
                      borderRight:
                        index < toolbarButtons.length - 1
                          ? "1px solid #dee2e6"
                          : "none",
                    }}
                  >
                    {" "}
                    <button.icon size={18} color="#6c757d" />{" "}
                  </button>
                ))}{" "}
              </div>{" "}
              <textarea
                className="form-control border-0 rounded-0"
                rows="12"
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                style={{
                  resize: "vertical",
                  borderBottomLeftRadius: "0.375rem",
                  borderBottomRightRadius: "0.375rem",
                  minHeight: "350px",
                }}
                placeholder="Type your message here..."
              />{" "}
            </div>{" "}
          </div>{" "}
          <div className="mb-4">
            {" "}
            <label htmlFor="fileInput" className="btn btn-outline-secondary">
              {" "}
              <Paperclip size={18} className="me-2" /> Attach files{" "}
            </label>{" "}
            <input
              id="fileInput"
              type="file"
              multiple
              className="d-none"
              onChange={handleFileAttach}
            />{" "}
            {attachedFiles.length > 0 && (
              <div className="mt-2">
                {" "}
                <small className="text-muted">
                  {" "}
                  {attachedFiles.length} file(s) attached:{" "}
                  {attachedFiles.map((f) => f.name).join(", ")}{" "}
                </small>{" "}
              </div>
            )}{" "}
          </div>{" "}
          <div className="d-flex gap-2">
            {" "}
            <button className="btn btn-danger px-4" onClick={handleAddTemplate}>
              {" "}
              Add template{" "}
            </button>{" "}
            <button className="btn btn-light px-4" onClick={handleCancel}>
              {" "}
              Cancel{" "}
            </button>{" "}
          </div>{" "}
        </div>{" "}
      </div>{" "}
    </div>
  );
}
