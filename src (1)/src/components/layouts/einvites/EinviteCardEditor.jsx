import React, { useMemo, useState, useRef, useEffect, useImperativeHandle } from "react";
import { getImageUrl, handleImageError } from "../../../utils/imageUtils";
import { fabric } from "fabric";
import { MdDeleteOutline, MdOutlineFileDownload } from "react-icons/md";
import { IoIosClose } from "react-icons/io";
import { FiEdit2 } from "react-icons/fi";
import { TbTextResize } from "react-icons/tb";
import { AiOutlineUndo } from "react-icons/ai";
import { useSelector } from "react-redux";
import { FaCopy, FaWhatsapp, FaDownload } from "react-icons/fa";
import Swal from "sweetalert2";

const EinviteCardEditor = React.forwardRef(({ card, onSave, onCancel, onSaveDraft }, ref) => {
  const [editedCard, setEditedCard] = useState(card || {});
  const [canvas, setCanvas] = useState(null);
  const [activeObject, setActiveObject] = useState(null);
  const [history, setHistory] = useState([]);
  const [isPreview, setIsPreview] = useState(false);
  const [isPublishing, setIsPublishing] = useState(false);
  const [updateTrigger, setUpdateTrigger] = useState(0);
  const [isFontDropdownOpen, setIsFontDropdownOpen] = useState(false);
  const [isStickerDropdownOpen, setIsStickerDropdownOpen] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const isEditModeRef = useRef(false);
  const [originalFont, setOriginalFont] = useState(null);
  const [recentColors, setRecentColors] = useState([]);
  const canvasRef = useRef(null);

  useImperativeHandle(ref, () => ({
    handleSave,
    handleSaveDraft
  }));

  // Sync state to ref for canvas event handlers
  useEffect(() => {
    isEditModeRef.current = isEditMode;
    if (canvas) canvas.requestRenderAll();
  }, [isEditMode, canvas]);

  const DUMMY_STICKERS = [
    { type: 'image', value: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PGNpcmNsZSBjeD0iMjgiIGN5PSIzOCIgcj0iMTQiIGZpbGw9Im5vbmUiIHN0cm9rZT0iI0ZGRDcwMCIgc3Ryb2tlLXdpZHRoPSI0Ii8+PGNpcmNsZSBjeD0iNDIiIGN5PSIyOCIgcj0iMTQiIGZpbGw9Im5vbmUiIHN0cm9rZT0iI0ZGRDcwMCIgc3Ryb2tlLXdpZHRoPSI0Ii8+PHBvbHlnb24gcG9pbnRzPSI0MiwxNCA0OCw2IDM2LDYiIGZpbGw9IiMwMEZGRkYiLz48L3N2Zz4=" }, // Rings
    { type: 'image', value: "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA2NCA2NCI+PHBhdGggZD0iTTMyIDU4IEMtMTAgMzIgMTAgLTYgMzIgMTggQzU0IC02IDc0IDMyIDMyIDU4IFoiIGZpbGw9IiNGRjE0OTMiLz48L3N2Zz4=" }, // Heart
    { type: 'emoji', value: "🐘" }, // Elephant (Ganpati representation)
    { type: 'emoji', value: "🕉️" }, // Om
    { type: 'emoji', value: "✨" }, // Sparkles
    { type: 'emoji', value: "🌹" } // Rose
  ];

  const FONT_FAMILIES = [
    "Arial",
    "Times New Roman",
    "Courier New",
    "Georgia",
    "Verdana",
    "Brush Script MT",
    "serif",
    "Dancing Script",
    "Great Vibes",
    "Pacifico",
    "Playfair Display",
    "Lobster",
    "Caveat",
    "Cinzel"
  ];

  const pushHistory = () => {
    // Canvas history not fully implemented, just a stub
  };

  const bgUrl = getImageUrl(editedCard.backgroundUrl || editedCard.background_url);
  const [scale, setScale] = useState(1);

  // Responsive scale
  useEffect(() => {
    const handleResize = () => {
      const containerWidth = window.innerWidth;
      const availableWidth = Math.min(containerWidth - 30, 450);

      if (availableWidth < 414) {
        setScale(availableWidth / 414);
      } else {
        setScale(1);
      }
    };
    handleResize();
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  // Initialize Fabric Canvas
  useEffect(() => {
    if (!canvasRef.current) return;

    // Setup custom controls and selection styling
    fabric.Object.prototype.set({
      transparentCorners: false,
      cornerColor: '#007bff',
      cornerStrokeColor: '#007bff',
      borderColor: '#007bff',
      cornerSize: 10,
      padding: 5,
    });

    // Hide standard corners (scaling/rotation) and only keep border
    fabric.Object.prototype.setControlsVisibility({
      tl: false,
      tr: false,
      bl: false,
      br: false,
      ml: false,
      mt: false,
      mr: false,
      mb: false,
      mtr: false,
    });

    // Add a custom delete control icon at top left
    const deleteIcon = "data:image/svg+xml,%3C%3Fxml version='1.0' encoding='utf-8'%3F%3E%3Csvg version='1.1' id='Layer_1' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' x='0px' y='0px' viewBox='0 0 512 512' style='enable-background:new 0 0 512 512;' xml:space='preserve'%3E%3Cpath d='M341,128V96c0-17.6-14.4-32-32-32H203c-17.6,0-32,14.4-32,32v32H53.4c-4.6,0-8.4,3.8-8.4,8.4v15.2c0,4.6,3.8,8.4,8.4,8.4h37.5 l27,303.4c1.2,13.8,12.8,24.6,26.7,24.6h223c13.9,0,25.4-10.8,26.7-24.6l27-303.4h37.5c4.6,0,8.4-3.8,8.4-8.4v-15.2 c0-4.6-3.8-8.4-8.4-8.4H341z M203,96h106v32H203V96z M353.4,456H158.6l-24.2-272h243.2L353.4,456z' fill='%23666666'/%3E%3C/svg%3E";
    const img = document.createElement('img');
    img.src = deleteIcon;
    
    fabric.Object.prototype.controls.deleteControl = new fabric.Control({
      x: -0.5,
      y: -0.5,
      offsetY: -16,
      offsetX: -16,
      cursorStyle: 'pointer',
      mouseUpHandler: (eventData, transform) => {
        const target = transform.target;
        const canvas = target.canvas;
        canvas.remove(target);
        canvas.discardActiveObject();
        canvas.requestRenderAll();
        return true;
      },
      render: function(ctx, left, top, styleOverride, fabricObject) {
        const size = this.cornerSize || 24;
        ctx.save();
        ctx.translate(left, top);
        ctx.beginPath();
        ctx.arc(0, 0, size/2, 0, 2 * Math.PI);
        ctx.fillStyle = "white";
        ctx.shadowColor = "rgba(0,0,0,0.3)";
        ctx.shadowBlur = 4;
        ctx.fill();
        ctx.closePath();
        ctx.shadowBlur = 0;
        ctx.drawImage(img, -size/2 + 4, -size/2 + 4, size - 8, size - 8);
        ctx.restore();
      },
      cornerSize: 28
    });

    const initCanvas = new fabric.Canvas(canvasRef.current, {
      width: 414,
      height: 659.288,
      preserveObjectStacking: true,
    });
    setCanvas(initCanvas);

    // Draw dashed borders for unselected text objects ONLY in edit mode
    initCanvas.on('after:render', function() {
      if (!isEditModeRef.current) return;
      
      initCanvas.contextContainer.strokeStyle = '#007bff';
      initCanvas.contextContainer.setLineDash([4, 4]);
      initCanvas.contextContainer.lineWidth = 1;
      
      initCanvas.getObjects().forEach(obj => {
        if (obj.type === 'i-text' && obj !== initCanvas.getActiveObject()) {
          const bound = obj.getBoundingRect();
          initCanvas.contextContainer.strokeRect(
            bound.left,
            bound.top,
            bound.width,
            bound.height
          );
        }
      });
      initCanvas.contextContainer.setLineDash([]);
    });

    // Add Fields
    if (editedCard.editableFields) {
      const initialColors = new Set();
      editedCard.editableFields.forEach((field) => {
        if (field.src) {
           fabric.Image.fromURL(field.src, (img) => {
             if (!img) return;
             img.set({
               left: field.x || initCanvas.width / 2,
               top: field.y || initCanvas.height / 2,
               scaleX: field.scaleX || 1,
               scaleY: field.scaleY || 1,
               angle: field.angle || 0,
               originX: field.originX || 'left',
               originY: field.originY || 'top',
               id: field.id
             });
             initCanvas.add(img);
           }, { crossOrigin: 'anonymous' });
        } else {
           if (field.color) initialColors.add(field.color);
           const textObj = new fabric.IText(field.defaultText || field.label, {
             left: field.x || initCanvas.width / 2,
             top: field.y || 100,
             fontFamily: field.fontFamily || 'Arial',
             fontSize: field.fontSize || 30,
             fill: field.color || '#000000',
             textAlign: field.textAlign || 'left',
             fontWeight: field.fontWeight || 'normal',
             fontStyle: field.fontStyle || 'normal',
             scaleX: field.scaleX || 1,
             scaleY: field.scaleY || 1,
             angle: field.angle || 0,
             originX: field.originX || 'left',
             originY: field.originY || 'top',
             id: field.id
           });
           initCanvas.add(textObj);
        }
      });
      setRecentColors(Array.from(initialColors));
    }

    // Keyboard events for deletion
    const handleKeyDown = (e) => {
      // Don't intercept if user is typing in a React input field
      if (document.activeElement && ['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName)) {
        return;
      }

      if (e.key === 'Delete' || e.key === 'Backspace') {
        const activeObj = initCanvas.getActiveObject();
        // Prevent backspace from navigating back or deleting canvas if we are editing text on canvas
        if (activeObj && !activeObj.isEditing) {
          e.preventDefault();
          initCanvas.remove(activeObj);
          initCanvas.discardActiveObject();
          initCanvas.renderAll();
          setActiveObject(null);
        }
      }
    };
    
    // Use window listener for keyboard shortcuts to ensure it captures events
    window.addEventListener('keydown', handleKeyDown);

    // Events
    initCanvas.on('selection:created', (e) => setActiveObject(e.selected[0]));
    initCanvas.on('selection:updated', (e) => setActiveObject(e.selected[0]));
    initCanvas.on('selection:cleared', () => setActiveObject(null));
    initCanvas.on('object:modified', (e) => {
      setActiveObject(initCanvas.getActiveObject());
      saveHistory();
    });
    initCanvas.on('object:scaling', (e) => {
      if (e.target && e.target.type === 'i-text') {
        setUpdateTrigger(prev => prev + 1); // Trigger UI update for font size input
      }
    });
    initCanvas.on('object:added', (e) => {
      // Don't save history for the background image
      if (e.target && e.target.type !== 'image') {
        saveHistory();
      }
    });

    const saveHistory = () => {
      const json = initCanvas.toJSON(['id', 'name', 'cardType']);
      setHistory(prev => {
        const newHistory = [...prev, JSON.stringify(json)];
        return newHistory.slice(-20); // Keep last 20 states
      });
    };

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      initCanvas.dispose();
    };
  }, [editedCard.id, bgUrl]); // Re-init on card change

  const handleAddText = () => {
    if (!canvas) return;
    const text = new fabric.IText('New Text', {
      left: canvas.width / 2,
      top: canvas.height / 2,
      fontFamily: 'Arial',
      fontSize: 24,
      fill: '#000000',
      originX: 'center',
      originY: 'center',
    });
    canvas.add(text);
    canvas.setActiveObject(text);
  };

  const handleAddSticker = (sticker) => {
    if (!canvas) return;

    if (sticker.type === 'emoji') {
      const text = new fabric.IText(sticker.value, {
        left: canvas.width / 2,
        top: canvas.height / 2,
        fontFamily: 'Arial',
        fontSize: 60,
        fill: '#000000',
        originX: 'center',
        originY: 'center',
      });
      canvas.add(text);
      canvas.setActiveObject(text);
      setIsStickerDropdownOpen(false);
    } else if (sticker.type === 'image') {
      fabric.Image.fromURL(sticker.value, (img) => {
        if (!img) return;
        if (img.width > 150) img.scaleToWidth(150);
        img.set({
          left: canvas.width / 2,
          top: canvas.height / 2,
          originX: 'center',
          originY: 'center',
        });
        canvas.add(img);
        canvas.setActiveObject(img);
        setIsStickerDropdownOpen(false);
      }, { crossOrigin: 'anonymous' });
    }
  };

  const handleAddImage = (e) => {
    const file = e.target.files[0];
    if (!file || !canvas) return;

    const reader = new FileReader();
    reader.onload = (f) => {
      const data = f.target.result;
      fabric.Image.fromURL(data, (img) => {
        // scale image down if it's too big
        if (img.width > 200) {
           img.scaleToWidth(200);
        }
        img.set({
          left: canvas.width / 2,
          top: canvas.height / 2,
          originX: 'center',
          originY: 'center',
        });
        canvas.add(img);
        canvas.setActiveObject(img);
      });
    };
    reader.readAsDataURL(file);
    // reset input value so the same file can be uploaded again if needed
    e.target.value = null;
  };

  const handleColorChange = (e) => {
    if (!activeObject || !canvas) return;
    const newColor = e.target.value;
    activeObject.set('fill', newColor);
    canvas.renderAll();
    setActiveObject(canvas.getActiveObject());
    
    setRecentColors(prev => {
      const updated = [newColor, ...prev.filter(c => c !== newColor)];
      return updated.slice(0, 10);
    });
  };

  const handleTextChange = (e) => {
    if (!activeObject || activeObject.type !== 'i-text' || !canvas) return;
    activeObject.set('text', e.target.value);
    canvas.renderAll();
    setUpdateTrigger(prev => prev + 1); // trigger re-render to reflect input value
  };

  const handleFontChange = (fontName) => {
    if (!activeObject || activeObject.type !== 'i-text' || !canvas) return;
    activeObject.set('fontFamily', fontName);
    canvas.renderAll();
    setUpdateTrigger(prev => prev + 1);
    setIsFontDropdownOpen(false);
    setOriginalFont(null);
  };

  const handleFontSizeChange = (e) => {
    if (!activeObject || activeObject.type !== 'i-text' || !canvas) return;
    const size = parseInt(e.target.value, 10);
    if (!isNaN(size) && size > 0) {
      activeObject.set('fontSize', size);
      // Reset scale since we are explicitly setting font size
      activeObject.set('scaleX', 1);
      activeObject.set('scaleY', 1);
      canvas.renderAll();
      setUpdateTrigger(prev => prev + 1);
    }
  };

  const handleFontHover = (fontName) => {
    if (!activeObject || activeObject.type !== 'i-text' || !canvas) return;
    if (!originalFont) {
       setOriginalFont(activeObject.fontFamily);
    }
    activeObject.set('fontFamily', fontName);
    canvas.renderAll();
  };

  const handleFontHoverOut = () => {
    if (!activeObject || activeObject.type !== 'i-text' || !canvas || !originalFont) return;
    // only reset if the dropdown is still open (meaning they haven't clicked one)
    if (isFontDropdownOpen) {
      activeObject.set('fontFamily', originalFont);
      canvas.renderAll();
    }
  };

  const handleDelete = () => {
    if(!activeObject || !canvas) return;
    canvas.remove(activeObject);
    canvas.discardActiveObject();
    canvas.renderAll();
  };

  const stripDomain = (url) => {
    if (!url) return url;
    return url.replace(/^(https?:\/\/[^\/]+)+/, "");
  };

  const buildCleanPayload = () => {
    if (!canvas) return null;
    
    // Extract editable fields from canvas objects
    const objects = canvas.getObjects();
    const editableFields = objects.map((obj, i) => {
      if (obj.type === 'i-text') {
        return {
          id: obj.id || `field_${i}`,
          label: obj.text,
          defaultText: obj.text,
          color: obj.fill,
          fontFamily: obj.fontFamily,
          fontSize: Math.round(obj.fontSize * (obj.scaleX || 1)),
          textAlign: obj.textAlign,
          fontWeight: obj.fontWeight,
          fontStyle: obj.fontStyle,
          x: Math.round(obj.left),
          y: Math.round(obj.top),
          scaleX: 1,
          scaleY: 1,
          angle: obj.angle,
          originX: obj.originX,
          originY: obj.originY,
        };
      } else if (obj.type === 'image') {
        return {
           id: obj.id || `image_${i}`,
           label: 'image',
           defaultText: 'image',
           fontSize: 30, // satisfy backend validation
           src: obj.getSrc(),
           x: Math.round(obj.left),
           y: Math.round(obj.top),
           scaleX: obj.scaleX,
           scaleY: obj.scaleY,
           angle: obj.angle,
           originX: obj.originX,
           originY: obj.originY,
        };
      } else {
        return {
           id: obj.id || `sticker_${i}`,
           label: obj.type, // 'circle'
           defaultText: obj.type,
           color: obj.fill,
           fontSize: 16, // dummy
           x: Math.round(obj.left),
           y: Math.round(obj.top),
           scaleX: obj.scaleX,
           scaleY: obj.scaleY,
           angle: obj.angle,
           originX: obj.originX,
           originY: obj.originY,
        };
      }
    });

    return {
      id: editedCard.id || editedCard._id,
      name: editedCard.name,
      cardType: editedCard.cardType,
      backgroundUrl: stripDomain(editedCard.backgroundUrl || editedCard.background_url),
      thumbnailUrl: stripDomain(editedCard.thumbnailUrl || editedCard.thumbnail_url),
      editableFields: JSON.stringify(editableFields),
    };
  };

  const handleSave = async () => {
    const cleanedCard = buildCleanPayload();
    if(!cleanedCard) return;
    try {
      setIsPublishing(true);
      await Promise.resolve(onSave(cleanedCard));
    } finally {
      setIsPublishing(false);
    }
  };

  const handleSaveDraft = () => {
    const cleanedCard = buildCleanPayload();
    if(!cleanedCard) return;
    try {
      const key = "einviteDrafts";
      const existing = JSON.parse(localStorage.getItem(key) || "[]");
      const draftId = cleanedCard.id ? `draft:${cleanedCard.id}` : `draft:${Date.now()}`;
      const draft = {
        ...cleanedCard,
        id: draftId,
        isActive: false,
        isDraft: true,
        source: "local",
        savedAt: Date.now(),
      };
      const idx = existing.findIndex((d) => d.id === draftId);
      if (idx >= 0) {
        existing[idx] = draft;
      } else {
        existing.unshift(draft);
      }
      localStorage.setItem(key, JSON.stringify(existing));
    } catch {}
    onSaveDraft?.(cleanedCard);
    Swal.fire({ text: "Draft saved successfully!", timer: 1500, icon: "success" });
  };

  const handleUndo = () => {
    if (!canvas || history.length <= 1) return;
    
    // The current state is the last item in history. We want the one before it.
    const previousState = history[history.length - 2];
    
    // Remove current state from history
    setHistory(prev => prev.slice(0, -1));
    
    canvas.loadFromJSON(previousState, () => {
      canvas.renderAll();
      setActiveObject(null);
      setUpdateTrigger(prev => prev + 1);
    });
  };

  return (
    <div className="einvite-editor py-4" style={{ backgroundColor: '#f8f9fa', minHeight: '100vh' }}>
      <div className="container">
        <div className="row justify-content-center gap-lg-4">
          
          {/* Add Text Panel */}
          <div className="col-md-4 col-lg-3 mb-4">
            <div className="card shadow-sm mb-4 border-0 rounded-3">
              <div className="card-body p-4">
                <h6 className="mb-1 d-flex align-items-center fw-bold" style={{ fontSize: '15px' }}>
                  <span className="badge rounded-circle me-2 text-white" style={{backgroundColor: '#ec4899', width: '24px', height: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center'}}>1</span> Add Text
                </h6>
                <small className="text-muted mb-3 d-block" style={{ fontSize: '12px', marginLeft: '32px' }}>Click on card to add or edit text</small>
                <button className="btn w-100 fw-medium bg-transparent mt-1" style={{color: '#ec4899', border: '1px solid #ec4899', borderRadius: '6px'}} onClick={handleAddText}>
                  + Add Text
                </button>
              </div>
            </div>
          </div>

          {/* Properties Panel */}
          <div className="col-md-4 col-lg-3 mb-4" style={{ opacity: activeObject ? 1 : 0.5, pointerEvents: activeObject ? 'auto' : 'none', transition: 'opacity 0.2s' }}>
            <div className="card shadow-sm border-0 rounded-3 mb-4">
              <div className="card-body p-4">
                    <div className="d-flex justify-content-between align-items-center mb-4">
                      <h6 className="mb-0 d-flex align-items-center fw-bold" style={{ fontSize: '15px' }}>
                        <span className="badge rounded-circle me-2 text-white" style={{backgroundColor: '#ec4899', width: '24px', height: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center'}}>2</span> Properties
                      </h6>
                      <span className="text-muted" style={{ transform: 'rotate(180deg)' }}>^</span>
                    </div>

                    <div className="mb-4">
                        <label className="form-label fw-bold" style={{ fontSize: '12px', color: '#333' }}>Color</label>
                        <div className="d-flex align-items-center mb-3">
                          <input 
                            type="color" 
                            className="form-control form-control-color border-0 p-0 shadow-sm"
                            style={{ width: '100%', height: '36px', borderRadius: '6px', flex: 1 }}
                            onChange={handleColorChange}
                            value={activeObject?.fill || '#A6731C'}
                          />
                          <span className="ms-3 text-muted fw-bold" style={{ fontSize: '12px', minWidth: '70px' }}>
                            {(activeObject?.fill || '#A6731C').toUpperCase()}
                          </span>
                        </div>
                        
                        {/* Recent Colors */}
                        <div className="mt-3">
                          <label className="form-label fw-bold" style={{ fontSize: '12px', color: '#333' }}>Recent Colors</label>
                          <div className="d-flex flex-wrap gap-2 align-items-center">
                            {recentColors.map((color, idx) => (
                              <div 
                                key={idx}
                                onClick={() => {
                                  if (activeObject) {
                                    activeObject.set('fill', color);
                                    canvas.renderAll();
                                    setUpdateTrigger(prev => prev + 1);
                                    setRecentColors(prev => {
                                      const updated = [color, ...prev.filter(c => c !== color)];
                                      return updated.slice(0, 10);
                                    });
                                  }
                                }}
                                style={{
                                  width: '24px',
                                  height: '24px',
                                  backgroundColor: color,
                                  borderRadius: '4px',
                                  cursor: 'pointer',
                                  border: activeObject?.fill === color ? '2px solid #000' : '1px solid #dee2e6'
                                }}
                                title={color}
                              />
                            ))}
                            <button className="btn btn-sm btn-outline-secondary rounded-2 d-flex align-items-center justify-content-center bg-transparent" style={{ width: '24px', height: '24px', borderStyle: 'dashed', padding: 0 }}>
                              <span style={{ fontSize: '16px', lineHeight: '1', color: '#6c757d' }}>+</span>
                            </button>
                          </div>
                        </div>
                    </div>

                    {(!activeObject || activeObject?.type === 'i-text') && (
                      <>
                        <div className="mb-4">
                          <label className="form-label fw-bold" style={{ fontSize: '12px', color: '#333' }}>Text</label>
                          <div className="position-relative">
                            <input 
                              type="text" 
                              className="form-control pe-4 text-muted"
                              style={{ fontSize: '13px', borderRadius: '6px' }}
                              onChange={handleTextChange}
                              value={activeObject?.text || 'Engagement Ceremony'}
                            />
                              <span className="position-absolute top-50 end-0 translate-middle-y me-3 fw-bold text-muted" style={{ fontSize: '14px' }}>T</span>
                            </div>
                          </div>

                        <div className="mb-4 position-relative">
                          <label className="form-label fw-bold" style={{ fontSize: '12px', color: '#333' }}>Font Family</label>
                          <div 
                            className="form-control d-flex justify-content-between align-items-center text-muted" 
                            style={{ cursor: 'pointer', fontFamily: activeObject?.fontFamily || 'Pacifico', fontSize: '13px', borderRadius: '6px' }}
                            onClick={() => setIsFontDropdownOpen(!isFontDropdownOpen)}
                          >
                            <span>{activeObject?.fontFamily || 'Pacifico'}</span>
                              <span style={{ fontSize: '10px' }}>▼</span>
                            </div>
                            
                            {isFontDropdownOpen && (
                              <div 
                                className="w-100 bg-white border rounded shadow-sm mt-1 position-absolute" 
                                style={{ maxHeight: '200px', overflowY: 'auto', zIndex: 1000, top: '100%' }}
                                onMouseLeave={handleFontHoverOut}
                              >
                                {FONT_FAMILIES.map((font) => (
                                  <div 
                                  key={font} 
                                  className="px-3 py-2 border-bottom"
                                  style={{ fontFamily: font, cursor: 'pointer', backgroundColor: (activeObject?.fontFamily || 'Pacifico') === font ? '#f8f9fa' : 'white' }}
                                    onMouseEnter={() => handleFontHover(font)}
                                    onClick={() => handleFontChange(font)}
                                  >
                                    {font}
                                  </div>
                                ))}
                              </div>
                            )}
                          </div>
                          
                          <div className="mb-2">
                            <label className="form-label fw-bold" style={{ fontSize: '12px', color: '#333' }}>Font Size</label>
                            <div className="d-flex align-items-center mt-1">
                              <input 
                                type="range" 
                                className="form-range"
                                min="8"
                                max="200"
                                value={Math.round((activeObject?.fontSize || 30) * (activeObject?.scaleX || 1))}
                                onChange={handleFontSizeChange}
                                style={{ flex: 1, accentColor: '#ec4899' }}
                              />
                              <div className="ms-3 border rounded text-center fw-bold text-muted" style={{ minWidth: '40px', fontSize: '13px', padding: '4px' }}>
                                {Math.round((activeObject?.fontSize || 30) * (activeObject?.scaleX || 1))}
                              </div>
                            </div>
                          </div>
                        </>
                      )}
                  </div>

                  <div className="card shadow-sm border-0 rounded-3 mt-3">
                    <div className="card-body p-4">
                      <h6 className="mb-3 d-flex align-items-center fw-bold" style={{ fontSize: '15px' }}>
                        <span className="badge rounded-circle me-2 text-white" style={{backgroundColor: '#ec4899', width: '24px', height: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center'}}>3</span> Actions
                      </h6>
                      <button className="btn w-100 fw-medium d-flex justify-content-center align-items-center gap-2 bg-transparent mt-1" style={{color: '#ef4444', border: '1px solid #ef4444', borderRadius: '6px'}} onClick={handleDelete}>
                        <MdDeleteOutline size={18} />
                        Delete Selected
                      </button>
                    </div>
                  </div>
                </div>
              </div>

          {/* Canvas Section */}
          <div className="col-md-auto d-flex flex-column align-items-center">
            <div
              className="einvite-canvas-wrapper shadow-sm border rounded"
              style={{
                width: `${414 * scale}px`,
                height: `${659.288 * scale}px`,
                position: "relative",
                overflow: "hidden",
                background: "#fff"
              }}
            >
              <div
                style={{
                  width: "414px",
                  height: "659.288px",
                  transform: `scale(${scale})`,
                  transformOrigin: "top left",
                  position: "absolute",
                  left: 0,
                  top: 0,
                }}
              >
                {bgUrl && (
                  <img
                    src={bgUrl}
                    alt="Card Background"
                    className="d-block"
                    style={{
                      width: "414px",
                      height: "659.288px",
                      position: 'absolute',
                      left: 0,
                      top: 0,
                      pointerEvents: 'none',
                      zIndex: 0
                    }}
                    onError={(e) =>
                      handleImageError(
                        e,
                        editedCard.backgroundUrl || editedCard.background_url
                      )
                    }
                  />
                )}
                <div style={{ position: 'absolute', left: 0, top: 0, zIndex: 1, width: '100%', height: '100%' }}>
                  <canvas ref={canvasRef} />
                </div>
              </div>
            </div>

            {/* Bottom Toolbar */}
            <div className="d-flex align-items-center justify-content-center bg-white mt-3 shadow-sm border-0 rounded-3 p-3 px-4" style={{ width: `${414 * scale}px`, maxWidth: '100%', minHeight: '84px' }}>
              <div className="d-flex gap-5 text-secondary">
                <div 
                  className="d-flex flex-column align-items-center" 
                  style={{ cursor: 'pointer', color: isEditMode ? '#ec4899' : '#4a4a4a' }} 
                  onClick={() => setIsEditMode(!isEditMode)}
                >
                  <FiEdit2 size={22} className="mb-1" />
                  <span style={{ fontSize: '13px', fontWeight: 600 }}>Edit</span>
                </div>
                <div 
                  className="d-flex flex-column align-items-center" 
                  style={{ cursor: 'pointer', color: '#4a4a4a' }}
                  onClick={() => {
                    if (activeObject && activeObject.type === 'i-text') {
                      const newSize = Math.min(200, Math.round(activeObject.fontSize * 1.1));
                      activeObject.set('fontSize', newSize);
                      canvas.renderAll();
                      setUpdateTrigger(prev => prev + 1);
                    }
                  }}
                >
                  <TbTextResize size={22} className="mb-1" />
                  <span style={{ fontSize: '13px', fontWeight: 600 }}>Size</span>
                </div>
                <div 
                  className="d-flex flex-column align-items-center" 
                  style={{ cursor: history.length > 1 ? 'pointer' : 'not-allowed', color: history.length > 1 ? '#4a4a4a' : '#ccc' }} 
                  onClick={handleUndo}
                >
                  <AiOutlineUndo size={22} className="mb-1" />
                  <span style={{ fontSize: '13px', fontWeight: 600 }}>Undo</span>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>


    </div>
  );
});

export default EinviteCardEditor;
