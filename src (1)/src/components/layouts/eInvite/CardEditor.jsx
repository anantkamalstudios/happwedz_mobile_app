import React, { useEffect, useRef, useState } from 'react';
import { fabric } from 'fabric';
import { Type, ZoomIn, ZoomOut, Save, Download, ArrowLeft, RotateCcw } from "lucide-react";
import Swal from "sweetalert2";

const CardEditor = ({ template, onBack }) => {
  const canvasRef = useRef(null);
  const [canvas, setCanvas] = useState(null);
  const [activeObject, setActiveObject] = useState(null);

  useEffect(() => {
    if (!canvasRef.current) return;
    
    // Initialize Fabric Canvas
    const initCanvas = new fabric.Canvas(canvasRef.current, {
      width: 500,
      height: 700,
      backgroundColor: '#f0f0f0'
    });

    setCanvas(initCanvas);

    // Set Background
    if (template?.backgroundUrl) {
      fabric.Image.fromURL(template.backgroundUrl, (img) => {
        img.scaleToWidth(initCanvas.width);
        img.scaleToHeight(initCanvas.height);
        initCanvas.setBackgroundImage(img, initCanvas.renderAll.bind(initCanvas));
      }, { crossOrigin: 'anonymous' });
    }

    // Add Initial Texts based on template fields
    if (template?.editableFields) {
      template.editableFields.forEach((field) => {
        const textObj = new fabric.IText(field.defaultText || field.label, {
          left: field.x || initCanvas.width / 2,
          top: field.y || 100,
          fontFamily: field.fontFamily || 'Arial',
          fontSize: field.fontSize || 30,
          fill: field.color || '#000000',
          originX: 'center',
          id: field.id
        });
        initCanvas.add(textObj);
      });
    }

    // Event listener for object selection
    initCanvas.on('selection:created', (e) => setActiveObject(e.selected[0]));
    initCanvas.on('selection:updated', (e) => setActiveObject(e.selected[0]));
    initCanvas.on('selection:cleared', () => setActiveObject(null));

    // Handle object modified (like scaled) to update properties panel
    initCanvas.on('object:modified', (e) => {
      setActiveObject(initCanvas.getActiveObject());
    });

    return () => {
      initCanvas.dispose();
    };
  }, [template]);

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

  const handleColorChange = (e) => {
    if (!activeObject || !canvas) return;
    activeObject.set('fill', e.target.value);
    canvas.renderAll();
    setActiveObject(canvas.getActiveObject());
  };

  const handleFontChange = (e) => {
    if (!activeObject || activeObject.type !== 'i-text' || !canvas) return;
    activeObject.set('fontFamily', e.target.value);
    canvas.renderAll();
    setActiveObject(canvas.getActiveObject());
  };

  const handleAddSticker = () => {
    if (!canvas) return;
    // Adding a generic shape (circle)
    const sticker = new fabric.Circle({
      radius: 40,
      fill: '#ff5722',
      left: canvas.width / 2,
      top: canvas.height / 2,
      originX: 'center',
      originY: 'center',
    });
    canvas.add(sticker);
    canvas.setActiveObject(sticker);
  };
  
  const handleDelete = () => {
      if(!activeObject || !canvas) return;
      canvas.remove(activeObject);
      canvas.discardActiveObject();
      canvas.renderAll();
  }

  const exportAsImage = () => {
    if (!canvas) return;
    const dataURL = canvas.toDataURL({
      format: 'png',
      quality: 1
    });
    
    // Create a download link
    const link = document.createElement('a');
    link.href = dataURL;
    link.download = `${template?.name?.replace(/\s+/g, "-") || 'wedding-card'}-customized.png`;
    link.click();
  };

  const saveCustomization = () => {
    Swal.fire({
      icon: "success",
      title: "Saved!",
      text: "Your card customization has been saved.",
      timer: 1500,
    });
  };

  return (
    <div className="min-vh-100 bg-light">
      {/* Header */}
      <nav className="navbar navbar-dark bg-primary shadow-sm">
        <div className="container-fluid">
          <span className="navbar-brand mb-0 h4 d-flex align-items-center">
            {onBack && (
              <button className="btn btn-link text-white me-2 p-0" onClick={onBack}>
                <ArrowLeft size={24} />
              </button>
            )}
            <Type className="me-2" size={24} />
            Advanced Card Editor
          </span>
          <div className="d-flex gap-2">
            <button className="btn btn-success btn-sm d-flex align-items-center" onClick={saveCustomization}>
              <Save size={16} className="me-1" /> Save
            </button>
            <button className="btn btn-warning btn-sm d-flex align-items-center" onClick={exportAsImage}>
              <Download size={16} className="me-1" /> Download
            </button>
          </div>
        </div>
      </nav>

      <div className="container-fluid py-4">
        <div className="row">
          {/* Left Panel - Toolbar */}
          <div className="col-lg-4 mb-4">
            <div className="card shadow-sm mb-4">
              <div className="card-header bg-white">
                <h5 className="mb-0">Tools</h5>
              </div>
              <div className="card-body">
                <button className="btn btn-outline-primary w-100 mb-2" onClick={handleAddText}>
                  <Type size={16} className="me-2" /> Add Text
                </button>
                <button className="btn btn-outline-secondary w-100" onClick={handleAddSticker}>
                  Add Shape / Sticker
                </button>
              </div>
            </div>

            {activeObject && (
              <div className="card shadow-sm">
                <div className="card-header bg-white">
                  <h5 className="mb-0">Properties</h5>
                </div>
                <div className="card-body">
                  <div className="mb-3">
                    <label className="form-label">Color</label>
                    <input 
                      type="color" 
                      className="form-control form-control-color w-100"
                      onChange={handleColorChange}
                      value={activeObject.fill || '#000000'}
                      title="Choose your color"
                    />
                  </div>

                  {activeObject.type === 'i-text' && (
                    <div className="mb-3">
                      <label className="form-label">Font Family</label>
                      <select 
                        className="form-select" 
                        onChange={handleFontChange} 
                        value={activeObject.fontFamily}
                      >
                        <option value="Arial">Arial</option>
                        <option value="Times New Roman">Times New Roman</option>
                        <option value="Courier New">Courier New</option>
                        <option value="Georgia">Georgia</option>
                        <option value="Verdana">Verdana</option>
                        <option value="Brush Script MT">Brush Script MT</option>
                        <option value="serif">Serif</option>
                      </select>
                    </div>
                  )}
                  
                  <button className="btn btn-outline-danger w-100 mt-2" onClick={handleDelete}>
                    Delete Selected
                  </button>
                </div>
              </div>
            )}
            
            <div className="alert alert-info small mt-4">
              <strong>💡 Tips:</strong>
              <ul className="mb-0 mt-2">
                <li>Double-click text on canvas to edit content</li>
                <li>Drag text/shapes to move position</li>
                <li>Drag corners to scale</li>
              </ul>
            </div>
          </div>

          {/* Right Panel - Canvas Preview */}
          <div className="col-lg-8">
            <div className="card shadow-sm border-0 bg-transparent">
              <div className="card-body d-flex justify-content-center p-0">
                <div className="canvas-wrapper bg-white shadow-lg overflow-hidden" style={{border: '1px solid #ddd'}}>
                  <canvas ref={canvasRef} />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CardEditor;
