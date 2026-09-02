import React, { useState, useRef, useEffect, useCallback } from "react";
import { fabric } from "fabric";

const VideoCanvas = ({ 
  videoElement, 
  elements = [], 
  onElementAdd, 
  onElementUpdate, 
  onElementDelete,
  onElementSelect,
  selectedElement,
  isPlaying = false,
  currentTime = 0,
  duration = 0
}) => {
  const canvasRef = useRef(null);
  const [canvas, setCanvas] = useState(null);
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const [isResizing, setIsResizing] = useState(false);
  const [resizeHandle, setResizeHandle] = useState(null);

  // Initialize fabric canvas
  useEffect(() => {
    if (canvasRef.current && !canvas) {
      const fabricCanvas = new fabric.Canvas(canvasRef.current, {
        width: 800,
        height: 600,
        backgroundColor: "transparent",
        preserveObjectStacking: true,
        selection: true,
        allowTouchScrolling: true,
      });

      // Configure canvas events
      fabricCanvas.on("selection:created", handleSelection);
      fabricCanvas.on("selection:updated", handleSelection);
      fabricCanvas.on("selection:cleared", handleDeselection);
      fabricCanvas.on("object:modified", handleObjectModified);
      fabricCanvas.on("object:moving", handleObjectMoving);
      fabricCanvas.on("object:scaling", handleObjectScaling);
      fabricCanvas.on("object:rotating", handleObjectRotating);

      setCanvas(fabricCanvas);
    }

    return () => {
      if (canvas) {
        canvas.dispose();
      }
    };
  }, []);

  // Update canvas when elements change
  useEffect(() => {
    if (canvas && elements) {
      // Clear existing objects
      canvas.clear();
      
      // Add elements to canvas
      elements.forEach((element) => {
        addElementToCanvas(element);
      });
      
      canvas.renderAll();
    }
  }, [canvas, elements]);

  // Handle video element changes
  useEffect(() => {
    if (canvas && videoElement) {
      // Set video as background
      const video = document.createElement("video");
      video.src = videoElement.src;
      video.crossOrigin = "anonymous";
      video.muted = true;
      video.loop = true;
      
      const fabricVideo = new fabric.Image(video, {
        left: 0,
        top: 0,
        selectable: false,
        evented: false,
        originX: "left",
        originY: "top",
      });

      // Scale video to fit canvas
      const scaleX = canvas.width / videoElement.videoWidth;
      const scaleY = canvas.height / videoElement.videoHeight;
      const scale = Math.min(scaleX, scaleY);
      
      fabricVideo.scale(scale);
      fabricVideo.set({
        left: (canvas.width - fabricVideo.getScaledWidth()) / 2,
        top: (canvas.height - fabricVideo.getScaledHeight()) / 2,
      });

      canvas.setBackgroundImage(fabricVideo, canvas.renderAll.bind(canvas));
    }
  }, [canvas, videoElement]);

  const addElementToCanvas = (element) => {
    if (!canvas) return;

    let fabricObject;

    switch (element.type) {
      case "text":
        fabricObject = new fabric.IText(element.text, {
          left: element.x,
          top: element.y,
          fontSize: element.fontSize || 30,
          fontFamily: element.fontFamily || "Arial",
          fill: element.color || "#ffffff",
          fontWeight: element.fontWeight || "normal",
          fontStyle: element.fontStyle || "normal",
          stroke: element.stroke || "#000000",
          strokeWidth: element.strokeWidth || 2,
          textAlign: element.textAlign || "center",
          originX: "center",
          originY: "center",
          selectable: true,
          evented: true,
        });
        break;

      case "image":
        fabric.Image.fromURL(element.src, (img) => {
          img.set({
            left: element.x,
            top: element.y,
            scaleX: element.scaleX || 1,
            scaleY: element.scaleY || 1,
            angle: element.angle || 0,
            originX: "center",
            originY: "center",
            selectable: true,
            evented: true,
          });
          canvas.add(img);
          canvas.renderAll();
        });
        return;

      case "shape":
        if (element.shapeType === "rectangle") {
          fabricObject = new fabric.Rect({
            left: element.x,
            top: element.y,
            width: element.width || 100,
            height: element.height || 100,
            fill: element.fill || "transparent",
            stroke: element.stroke || "#000000",
            strokeWidth: element.strokeWidth || 2,
            originX: "center",
            originY: "center",
            selectable: true,
            evented: true,
          });
        } else if (element.shapeType === "circle") {
          fabricObject = new fabric.Circle({
            left: element.x,
            top: element.y,
            radius: element.radius || 50,
            fill: element.fill || "transparent",
            stroke: element.stroke || "#000000",
            strokeWidth: element.strokeWidth || 2,
            originX: "center",
            originY: "center",
            selectable: true,
            evented: true,
          });
        }
        break;

      default:
        return;
    }

    if (fabricObject) {
      // Add custom properties
      fabricObject.set({
        id: element.id,
        startTime: element.startTime || 0,
        endTime: element.endTime || duration,
        opacity: element.opacity || 1,
      });

      canvas.add(fabricObject);
    }
  };

  const handleSelection = (e) => {
    const activeObject = e.selected[0];
    if (activeObject && onElementSelect) {
      const element = elements.find(el => el.id === activeObject.id);
      if (element) {
        onElementSelect(element);
      }
    }
  };

  const handleDeselection = () => {
    if (onElementSelect) {
      onElementSelect(null);
    }
  };

  const handleObjectModified = (e) => {
    const object = e.target;
    if (object && onElementUpdate) {
      const element = {
        id: object.id,
        x: object.left,
        y: object.top,
        scaleX: object.scaleX,
        scaleY: object.scaleY,
        angle: object.angle,
        opacity: object.opacity,
      };

      if (object.type === "i-text") {
        element.text = object.text;
        element.fontSize = object.fontSize;
        element.fontFamily = object.fontFamily;
        element.fill = object.fill;
        element.fontWeight = object.fontWeight;
        element.fontStyle = object.fontStyle;
        element.stroke = object.stroke;
        element.strokeWidth = object.strokeWidth;
      }

      onElementUpdate(element);
    }
  };

  const handleObjectMoving = (e) => {
    const object = e.target;
    if (object) {
      // Constrain to canvas bounds
      const canvasWidth = canvas.width;
      const canvasHeight = canvas.height;
      const objectWidth = object.getScaledWidth();
      const objectHeight = object.getScaledHeight();

      if (object.left < 0) object.left = 0;
      if (object.top < 0) object.top = 0;
      if (object.left + objectWidth > canvasWidth) {
        object.left = canvasWidth - objectWidth;
      }
      if (object.top + objectHeight > canvasHeight) {
        object.top = canvasHeight - objectHeight;
      }
    }
  };

  const handleObjectScaling = (e) => {
    const object = e.target;
    if (object) {
      // Maintain aspect ratio for images
      if (object.type === "image") {
        const scaleX = object.scaleX;
        const scaleY = object.scaleY;
        const scale = Math.min(scaleX, scaleY);
        object.set({ scaleX: scale, scaleY: scale });
      }
    }
  };

  const handleObjectRotating = (e) => {
    // Handle rotation if needed
  };

  const addText = (text = "New Text") => {
    if (!canvas) return;

    const textObject = new fabric.IText(text, {
      left: canvas.width / 2,
      top: canvas.height / 2,
      fontSize: 30,
      fontFamily: "Arial",
      fill: "#ffffff",
      stroke: "#000000",
      strokeWidth: 2,
      textAlign: "center",
      originX: "center",
      originY: "center",
      selectable: true,
      evented: true,
    });

    const element = {
      id: Date.now(),
      type: "text",
      text: text,
      x: textObject.left,
      y: textObject.top,
      fontSize: 30,
      fontFamily: "Arial",
      color: "#ffffff",
      stroke: "#000000",
      strokeWidth: 2,
      startTime: currentTime,
      endTime: currentTime + 5,
    };

    textObject.set({ id: element.id });
    canvas.add(textObject);
    canvas.setActiveObject(textObject);
    canvas.renderAll();

    if (onElementAdd) {
      onElementAdd(element);
    }
  };

  const addImage = (src) => {
    if (!canvas) return;

    fabric.Image.fromURL(src, (img) => {
      const element = {
        id: Date.now(),
        type: "image",
        src: src,
        x: canvas.width / 2,
        y: canvas.height / 2,
        scaleX: 1,
        scaleY: 1,
        angle: 0,
        startTime: currentTime,
        endTime: currentTime + 5,
      };

      img.set({
        left: element.x,
        top: element.y,
        originX: "center",
        originY: "center",
        selectable: true,
        evented: true,
        id: element.id,
      });

      canvas.add(img);
      canvas.setActiveObject(img);
      canvas.renderAll();

      if (onElementAdd) {
        onElementAdd(element);
      }
    });
  };

  const addShape = (shapeType, options = {}) => {
    if (!canvas) return;

    let shape;
    const element = {
      id: Date.now(),
      type: "shape",
      shapeType: shapeType,
      x: canvas.width / 2,
      y: canvas.height / 2,
      startTime: currentTime,
      endTime: currentTime + 5,
      ...options,
    };

    switch (shapeType) {
      case "rectangle":
        shape = new fabric.Rect({
          left: element.x,
          top: element.y,
          width: element.width || 100,
          height: element.height || 100,
          fill: element.fill || "transparent",
          stroke: element.stroke || "#000000",
          strokeWidth: element.strokeWidth || 2,
          originX: "center",
          originY: "center",
          selectable: true,
          evented: true,
        });
        break;

      case "circle":
        shape = new fabric.Circle({
          left: element.x,
          top: element.y,
          radius: element.radius || 50,
          fill: element.fill || "transparent",
          stroke: element.stroke || "#000000",
          strokeWidth: element.strokeWidth || 2,
          originX: "center",
          originY: "center",
          selectable: true,
          evented: true,
        });
        break;

      default:
        return;
    }

    shape.set({ id: element.id });
    canvas.add(shape);
    canvas.setActiveObject(shape);
    canvas.renderAll();

    if (onElementAdd) {
      onElementAdd(element);
    }
  };

  const deleteSelected = () => {
    if (canvas) {
      const activeObject = canvas.getActiveObject();
      if (activeObject && onElementDelete) {
        onElementDelete(activeObject.id);
        canvas.remove(activeObject);
        canvas.renderAll();
      }
    }
  };

  const duplicateSelected = () => {
    if (canvas) {
      const activeObject = canvas.getActiveObject();
      if (activeObject) {
        activeObject.clone((cloned) => {
          cloned.set({
            left: cloned.left + 20,
            top: cloned.top + 20,
            id: Date.now(),
          });
          canvas.add(cloned);
          canvas.setActiveObject(cloned);
          canvas.renderAll();

          const element = {
            id: cloned.id,
            type: activeObject.type === "i-text" ? "text" : activeObject.type,
            x: cloned.left,
            y: cloned.top,
            scaleX: cloned.scaleX,
            scaleY: cloned.scaleY,
            angle: cloned.angle,
            opacity: cloned.opacity,
            startTime: currentTime,
            endTime: currentTime + 5,
          };

          if (activeObject.type === "i-text") {
            element.text = cloned.text;
            element.fontSize = cloned.fontSize;
            element.fontFamily = cloned.fontFamily;
            element.fill = cloned.fill;
            element.stroke = cloned.stroke;
            element.strokeWidth = cloned.strokeWidth;
          }

          if (onElementAdd) {
            onElementAdd(element);
          }
        });
      }
    }
  };

  const bringToFront = () => {
    if (canvas) {
      const activeObject = canvas.getActiveObject();
      if (activeObject) {
        canvas.bringToFront(activeObject);
        canvas.renderAll();
      }
    }
  };

  const sendToBack = () => {
    if (canvas) {
      const activeObject = canvas.getActiveObject();
      if (activeObject) {
        canvas.sendToBack(activeObject);
        canvas.renderAll();
      }
    }
  };

  const alignToCenter = () => {
    if (canvas) {
      const activeObject = canvas.getActiveObject();
      if (activeObject) {
        activeObject.set({
          left: canvas.width / 2,
          top: canvas.height / 2,
        });
        canvas.renderAll();
      }
    }
  };

  const flipHorizontal = () => {
    if (canvas) {
      const activeObject = canvas.getActiveObject();
      if (activeObject) {
        activeObject.set({
          flipX: !activeObject.flipX,
        });
        canvas.renderAll();
      }
    }
  };

  const flipVertical = () => {
    if (canvas) {
      const activeObject = canvas.getActiveObject();
      if (activeObject) {
        activeObject.set({
          flipY: !activeObject.flipY,
        });
        canvas.renderAll();
      }
    }
  };

  const resetTransform = () => {
    if (canvas) {
      const activeObject = canvas.getActiveObject();
      if (activeObject) {
        activeObject.set({
          scaleX: 1,
          scaleY: 1,
          angle: 0,
          flipX: false,
          flipY: false,
        });
        canvas.renderAll();
      }
    }
  };

  // Expose methods to parent component
  React.useImperativeHandle(React.forwardRef(() => {}), () => ({
    addText,
    addImage,
    addShape,
    deleteSelected,
    duplicateSelected,
    bringToFront,
    sendToBack,
    alignToCenter,
    flipHorizontal,
    flipVertical,
    resetTransform,
    getCanvas: () => canvas,
  }));

  return (
    <div className="video-canvas-container position-relative">
      <canvas
        ref={canvasRef}
        className="border rounded shadow"
        style={{
          maxWidth: "100%",
          height: "auto",
          cursor: "crosshair",
        }}
      />
      
      {/* Canvas overlay for additional controls */}
      <div className="video-canvas-overlay">
        {/* Time indicator */}
        <div className="position-absolute top-0 start-0 m-2">
          <div className="badge bg-dark bg-opacity-75 text-white">
            {Math.floor(currentTime / 60)}:{(currentTime % 60).toFixed(1).padStart(4, "0")}
          </div>
        </div>

        {/* Element count indicator */}
        <div className="position-absolute top-0 end-0 m-2">
          <div className="badge bg-primary bg-opacity-75 text-white">
            {elements.length} Elements
          </div>
        </div>

        {/* Play/Pause indicator */}
        {isPlaying && (
          <div className="position-absolute top-50 start-50 translate-middle">
            <div className="badge bg-success bg-opacity-75 text-white fs-6">
              <i className="fas fa-play me-1"></i>
              Playing
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default VideoCanvas;
