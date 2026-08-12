import React, { useState, useEffect, useRef } from "react";
import { Download, Type, ZoomIn, ZoomOut, Save, RotateCcw } from "lucide-react";
import Swal from "sweetalert2";

// Sample template data (comes from your backend)
const SAMPLE_TEMPLATE = {
  id: "template_001",
  name: "Elegant Wedding Invitation",
  backgroundUrl:
    "https://images.unsplash.com/photo-1519741497674-611481863552?w=500&h=700&fit=crop",
  editableFields: [
    {
      id: "field_1",
      label: "Couple Names",
      defaultText: "John & Priya",
      x: 175,
      y: 150,
      fontSize: 36,
      color: "#ffffff",
      fontFamily: "serif",
      minFontSize: 20,
      maxFontSize: 60,
    },
    {
      id: "field_2",
      label: "Wedding Date",
      defaultText: "December 25, 2024",
      x: 175,
      y: 300,
      fontSize: 24,
      color: "#f0e6d2",
      fontFamily: "Georgia",
      minFontSize: 14,
      maxFontSize: 40,
    },
    {
      id: "field_3",
      label: "Venue",
      defaultText: "The Grand Palace, Mumbai",
      x: 175,
      y: 500,
      fontSize: 20,
      color: "#ffffff",
      fontFamily: "Arial",
      minFontSize: 12,
      maxFontSize: 32,
    },
  ],
};

const CardEditor = () => {
  const canvasRef = useRef(null);
  const backgroundImageRef = useRef(null);
  const [template, setTemplate] = useState(SAMPLE_TEMPLATE);
  const [userFields, setUserFields] = useState([]);
  const [selectedFieldIndex, setSelectedFieldIndex] = useState(null);
  const [isDragging, setIsDragging] = useState(false);
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });
  const [isResizing, setIsResizing] = useState(false);
  const [resizeStart, setResizeStart] = useState({ x: 0, fontSize: 0 });

  // Initialize user fields from template
  useEffect(() => {
    const fields = template.editableFields.map((field) => ({
      ...field,
      text: field.defaultText,
    }));
    setUserFields(fields);
  }, [template]);

  // Load background image
  useEffect(() => {
    if (!template.backgroundUrl) return;

    const img = new Image();
    img.crossOrigin = "anonymous";
    img.onload = () => {
      backgroundImageRef.current = img;
      renderCanvas();
    };
    img.src = template.backgroundUrl;
  }, [template.backgroundUrl]);

  // Render canvas whenever fields change
  useEffect(() => {
    renderCanvas();
  }, [userFields, selectedFieldIndex]);

  const renderCanvas = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw background
    if (backgroundImageRef.current) {
      ctx.drawImage(
        backgroundImageRef.current,
        0,
        0,
        canvas.width,
        canvas.height
      );
    } else {
      ctx.fillStyle = "#f0f0f0";
      ctx.fillRect(0, 0, canvas.width, canvas.height);
    }

    // Draw all text fields
    userFields.forEach((field, index) => {
      ctx.fillStyle = field.color;
      ctx.font = `${field.fontSize}px ${field.fontFamily}`;
      ctx.textAlign = "left";
      ctx.textBaseline = "top";

      // Draw text
      ctx.fillText(field.text, field.x, field.y);

      // Draw selection box if selected
      if (index === selectedFieldIndex) {
        const metrics = ctx.measureText(field.text);
        const textWidth = metrics.width;
        const textHeight = field.fontSize * 1.2;

        ctx.strokeStyle = "#3b82f6";
        ctx.lineWidth = 2;
        ctx.setLineDash([5, 5]);
        ctx.strokeRect(
          field.x - 5,
          field.y - 5,
          textWidth + 10,
          textHeight + 10
        );
        ctx.setLineDash([]);

        // Draw resize handle (bottom-right corner)
        ctx.fillStyle = "#3b82f6";
        ctx.fillRect(field.x + textWidth + 5, field.y + textHeight - 5, 10, 10);
      }
    });
  };

  const getMousePos = (e) => {
    const canvas = canvasRef.current;
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;
    return {
      x: (e.clientX - rect.left) * scaleX,
      y: (e.clientY - rect.top) * scaleY,
    };
  };

  const getFieldAtPosition = (x, y) => {
    const canvas = canvasRef.current;
    const ctx = canvas.getContext("2d");

    for (let i = userFields.length - 1; i >= 0; i--) {
      const field = userFields[i];
      ctx.font = `${field.fontSize}px ${field.fontFamily}`;
      const metrics = ctx.measureText(field.text);
      const textWidth = metrics.width;
      const textHeight = field.fontSize * 1.2;

      if (
        x >= field.x - 5 &&
        x <= field.x + textWidth + 10 &&
        y >= field.y - 5 &&
        y <= field.y + textHeight + 10
      ) {
        return i;
      }
    }
    return null;
  };

  const isOnResizeHandle = (x, y, fieldIndex) => {
    if (fieldIndex === null) return false;
    const field = userFields[fieldIndex];
    const canvas = canvasRef.current;
    const ctx = canvas.getContext("2d");

    ctx.font = `${field.fontSize}px ${field.fontFamily}`;
    const metrics = ctx.measureText(field.text);
    const textWidth = metrics.width;
    const textHeight = field.fontSize * 1.2;

    const handleX = field.x + textWidth + 5;
    const handleY = field.y + textHeight - 5;

    return (
      x >= handleX && x <= handleX + 10 && y >= handleY && y <= handleY + 10
    );
  };

  const handleMouseDown = (e) => {
    const pos = getMousePos(e);
    const fieldIndex = getFieldAtPosition(pos.x, pos.y);

    if (fieldIndex !== null) {
      setSelectedFieldIndex(fieldIndex);

      // Check if clicking on resize handle
      if (isOnResizeHandle(pos.x, pos.y, fieldIndex)) {
        setIsResizing(true);
        setResizeStart({
          x: pos.x,
          fontSize: userFields[fieldIndex].fontSize,
        });
      } else {
        // Start dragging
        setIsDragging(true);
        setDragOffset({
          x: pos.x - userFields[fieldIndex].x,
          y: pos.y - userFields[fieldIndex].y,
        });
      }
    } else {
      setSelectedFieldIndex(null);
    }
  };

  const handleMouseMove = (e) => {
    const pos = getMousePos(e);

    if (isResizing && selectedFieldIndex !== null) {
      const field = userFields[selectedFieldIndex];
      const deltaX = pos.x - resizeStart.x;
      const fontSizeChange = Math.round(deltaX / 5); // 5px mouse movement = 1px font size
      let newFontSize = resizeStart.fontSize + fontSizeChange;

      // Clamp to min/max
      newFontSize = Math.max(
        field.minFontSize,
        Math.min(field.maxFontSize, newFontSize)
      );

      const updated = [...userFields];
      updated[selectedFieldIndex] = { ...field, fontSize: newFontSize };
      setUserFields(updated);
    } else if (isDragging && selectedFieldIndex !== null) {
      const newX = pos.x - dragOffset.x;
      const newY = pos.y - dragOffset.y;

      const updated = [...userFields];
      updated[selectedFieldIndex] = {
        ...updated[selectedFieldIndex],
        x: Math.max(0, Math.min(canvasRef.current.width - 50, newX)),
        y: Math.max(0, Math.min(canvasRef.current.height - 50, newY)),
      };
      setUserFields(updated);
    }
  };

  const handleMouseUp = () => {
    setIsDragging(false);
    setIsResizing(false);
  };

  const updateFieldText = (index, newText) => {
    const updated = [...userFields];
    updated[index] = { ...updated[index], text: newText };
    setUserFields(updated);
  };

  const updateFieldFontSize = (index, delta) => {
    const field = userFields[index];
    let newSize = field.fontSize + delta;
    newSize = Math.max(field.minFontSize, Math.min(field.maxFontSize, newSize));

    const updated = [...userFields];
    updated[index] = { ...updated[index], fontSize: newSize };
    setUserFields(updated);
  };

  const resetToDefaults = () => {
    if (window.confirm("Reset all changes to default?")) {
      const fields = template.editableFields.map((field) => ({
        ...field,
        text: field.defaultText,
      }));
      setUserFields(fields);
      setSelectedFieldIndex(null);
    }
  };

  const exportAsImage = () => {
    const canvas = canvasRef.current;
    const dataURL = canvas.toDataURL("image/png", 1.0);

    const link = document.createElement("a");
    link.href = dataURL;
    link.download = `${template.name.replace(/\s+/g, "-")}-customized.png`;
    link.click();
  };

  const saveCustomization = () => {
    // This would send to your backend
    const customizationData = {
      templateId: template.id,
      customFields: userFields.map((f) => ({
        id: f.id,
        text: f.text,
        fontSize: f.fontSize,
        x: f.x,
        y: f.y,
      })),
    };

    // alert("Customization saved! (Check console for data)");
    Swal.fire({
      icon: "success",
      text: "Customization saved!",
      timer: 1500,
    });
  };

  return (
    <div className="min-vh-100 bg-light">
      {/* Header */}
      <nav className="navbar navbar-dark bg-primary shadow-sm">
        <div className="container-fluid">
          <span className="navbar-brand mb-0 h4">
            <Type className="me-2" size={24} />
            Customize Your Invitation
          </span>
          <div className="d-flex gap-2">
            <button className="btn btn-light btn-sm" onClick={resetToDefaults}>
              <RotateCcw size={16} className="me-1" />
              Reset
            </button>
            <button
              className="btn btn-success btn-sm"
              onClick={saveCustomization}
            >
              <Save size={16} className="me-1" />
              Save
            </button>
            <button className="btn btn-warning btn-sm" onClick={exportAsImage}>
              <Download size={16} className="me-1" />
              Download
            </button>
          </div>
        </div>
      </nav>

      <div className="container-fluid py-4">
        <div className="row">
          {/* Left Panel - Text Editor */}
          <div className="col-lg-4 mb-4">
            <div className="card shadow-sm">
              <div className="card-header bg-white">
                <h5 className="mb-0">Edit Text Fields</h5>
              </div>
              <div className="card-body">
                {userFields.map((field, index) => (
                  <div
                    key={field.id}
                    className={`mb-4 p-3 border rounded ${selectedFieldIndex === index
                      ? "border-primary bg-light"
                      : ""
                      }`}
                    onClick={() => setSelectedFieldIndex(index)}
                    style={{ cursor: "pointer" }}
                  >
                    <label className="form-label fw-bold">{field.label}</label>

                    <textarea
                      className="form-control mb-2"
                      rows="2"
                      value={field.text}
                      onChange={(e) => updateFieldText(index, e.target.value)}
                      placeholder={field.defaultText}
                    />

                    <div className="d-flex align-items-center gap-2">
                      <button
                        className="btn btn-sm btn-outline-secondary"
                        onClick={(e) => {
                          e.stopPropagation();
                          updateFieldFontSize(index, -2);
                        }}
                      >
                        <ZoomOut size={16} />
                      </button>

                      <span className="badge bg-secondary px-3">
                        {field.fontSize}px
                      </span>

                      <button
                        className="btn btn-sm btn-outline-secondary"
                        onClick={(e) => {
                          e.stopPropagation();
                          updateFieldFontSize(index, 2);
                        }}
                      >
                        <ZoomIn size={16} />
                      </button>

                      <input
                        type="range"
                        className="form-range flex-grow-1"
                        min={field.minFontSize}
                        max={field.maxFontSize}
                        value={field.fontSize}
                        onChange={(e) => {
                          const updated = [...userFields];
                          updated[index] = {
                            ...updated[index],
                            fontSize: parseInt(e.target.value),
                          };
                          setUserFields(updated);
                        }}
                        onClick={(e) => e.stopPropagation()}
                      />
                    </div>

                    <div className="mt-2 small text-muted">
                      Font: {field.fontFamily} | Color: {field.color}
                    </div>
                  </div>
                ))}

                <div className="alert alert-info small">
                  <strong>💡 Tips:</strong>
                  <ul className="mb-0 mt-2">
                    <li>Click text on canvas to select</li>
                    <li>Drag text to move position</li>
                    <li>Drag blue square to resize</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>

          {/* Right Panel - Canvas Preview */}
          <div className="col-lg-8">
            <div className="card shadow-sm">
              <div className="card-header bg-white">
                <h5 className="mb-0">Live Preview</h5>
              </div>
              <div className="card-body text-center">
                <canvas
                  ref={canvasRef}
                  width={500}
                  height={700}
                  className="border rounded shadow"
                  style={{
                    maxWidth: "100%",
                    height: "auto",
                    cursor: isDragging
                      ? "grabbing"
                      : isResizing
                        ? "nwse-resize"
                        : "grab",
                  }}
                  onMouseDown={handleMouseDown}
                  onMouseMove={handleMouseMove}
                  onMouseUp={handleMouseUp}
                  onMouseLeave={handleMouseUp}
                />

                {selectedFieldIndex !== null && (
                  <div className="alert alert-primary mt-3 text-start">
                    <strong>Selected:</strong>{" "}
                    {userFields[selectedFieldIndex].label}
                    <div className="mt-2 small">
                      Position: ({Math.round(userFields[selectedFieldIndex].x)},{" "}
                      {Math.round(userFields[selectedFieldIndex].y)}) | Size:{" "}
                      {userFields[selectedFieldIndex].fontSize}px
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CardEditor;
