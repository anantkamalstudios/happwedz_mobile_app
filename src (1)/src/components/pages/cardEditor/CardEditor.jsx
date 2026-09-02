import React, { useEffect, useRef, useState } from 'react';
import { fabric } from 'fabric';
import { Button, Container, Row, Col, Form } from 'react-bootstrap';
import './CardEditor.css';

const CardEditor = ({ initialData, backgroundUrl, onSave }) => {
  const canvasRef = useRef(null);
  const [canvas, setCanvas] = useState(null);
  const [activeObject, setActiveObject] = useState(null);

  useEffect(() => {
    if (!canvasRef.current) return;
    
    // Initialize Fabric Canvas
    const initCanvas = new fabric.Canvas(canvasRef.current, {
      width: 600,
      height: 800,
      backgroundColor: '#fefefe'
    });

    setCanvas(initCanvas);

    // Set Background
    if (backgroundUrl) {
      fabric.Image.fromURL(backgroundUrl, (img) => {
        img.scaleToWidth(initCanvas.width);
        initCanvas.setBackgroundImage(img, initCanvas.renderAll.bind(initCanvas));
      });
    }

    // Add Initial Texts based on data
    if (initialData) {
      const topOffset = 100;
      
      const addText = (text, top, fontSize = 30) => {
        if (!text) return;
        const textObj = new fabric.IText(text, {
          left: initCanvas.width / 2,
          top: top,
          fontFamily: 'Arial',
          fontSize: fontSize,
          fill: '#000000',
          originX: 'center',
        });
        initCanvas.add(textObj);
      };

      addText(initialData.bride || 'Bride', topOffset, 40);
      addText("&", topOffset + 60, 40);
      addText(initialData.groom || 'Groom', topOffset + 120, 40);
      addText(`${initialData.day || 'Day'} ${initialData.date || 'Date'} ${initialData.year || 'Year'}`, topOffset + 200, 24);
      addText(initialData.time || 'Time', topOffset + 250, 24);
      addText(initialData.venue || 'Venue', topOffset + 300, 24);
    }

    // Event listener for object selection
    initCanvas.on('selection:created', (e) => setActiveObject(e.selected[0]));
    initCanvas.on('selection:updated', (e) => setActiveObject(e.selected[0]));
    initCanvas.on('selection:cleared', () => setActiveObject(null));

    return () => {
      initCanvas.dispose();
    };
  }, [backgroundUrl, initialData]);

  const handleAddText = () => {
    if (!canvas) return;
    const text = new fabric.IText('New Text', {
      left: 100,
      top: 100,
      fontFamily: 'Arial',
      fontSize: 24,
      fill: '#000'
    });
    canvas.add(text);
    canvas.setActiveObject(text);
  };

  const handleColorChange = (e) => {
    if (!activeObject || !canvas) return;
    activeObject.set('fill', e.target.value);
    canvas.renderAll();
  };

  const handleFontChange = (e) => {
    if (!activeObject || activeObject.type !== 'i-text' || !canvas) return;
    activeObject.set('fontFamily', e.target.value);
    canvas.renderAll();
  };

  const handleAddSticker = () => {
    if (!canvas) return;
    // Adding a generic placeholder sticker (star shape as path for example)
    // We'll use a basic circle for simplicity if not loading SVG
    const sticker = new fabric.Circle({
      radius: 30,
      fill: '#ffc107',
      left: 150,
      top: 150
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

  const exportCard = () => {
    if (!canvas) return;
    const dataURL = canvas.toDataURL({
      format: 'png',
      quality: 1
    });
    
    // Create a download link
    const link = document.createElement('a');
    link.href = dataURL;
    link.download = 'wedding-card.png';
    link.click();
    
    if (onSave) onSave(dataURL);
  };

  return (
    <Container fluid className="card-editor-container py-4">
      <Row>
        <Col md={3}>
          <div className="editor-toolbar p-3 bg-white rounded shadow-sm border">
            <h4 className="mb-4">Design Tools</h4>
            
            <div className="mb-4">
              <Button variant="outline-primary" className="w-100 mb-2" onClick={handleAddText}>
                <i className="bi bi-fonts me-2"></i> Add Text
              </Button>
              <Button variant="outline-secondary" className="w-100" onClick={handleAddSticker}>
                <i className="bi bi-star me-2"></i> Add Shape
              </Button>
            </div>

            {activeObject && (
              <div className="properties-panel mt-4 p-3 bg-light rounded border">
                <h5 className="mb-3">Properties</h5>
                
                <Form.Group className="mb-3">
                  <Form.Label>Color</Form.Label>
                  <Form.Control 
                    type="color" 
                    onChange={handleColorChange}
                    value={activeObject.fill || '#000000'}
                  />
                </Form.Group>

                {activeObject.type === 'i-text' && (
                  <Form.Group className="mb-3">
                    <Form.Label>Font Family</Form.Label>
                    <Form.Select onChange={handleFontChange} value={activeObject.fontFamily}>
                      <option value="Arial">Arial</option>
                      <option value="Times New Roman">Times New Roman</option>
                      <option value="Courier New">Courier New</option>
                      <option value="Georgia">Georgia</option>
                      <option value="Verdana">Verdana</option>
                      <option value="Brush Script MT">Brush Script MT</option>
                    </Form.Select>
                  </Form.Group>
                )}
                
                <Button variant="outline-danger" size="sm" className="w-100 mt-2" onClick={handleDelete}>
                    <i className="bi bi-trash me-2"></i> Delete Selected
                </Button>
              </div>
            )}
            
            <div className="mt-4 pt-3 border-top">
                <Button variant="success" className="w-100" onClick={exportCard}>
                    Download Card
                </Button>
            </div>
          </div>
        </Col>
        
        <Col md={9} className="d-flex justify-content-center align-items-start">
          <div className="canvas-wrapper shadow-lg bg-white overflow-hidden" style={{border: '1px solid #ddd'}}>
            <canvas ref={canvasRef} />
          </div>
        </Col>
      </Row>
    </Container>
  );
};

export default CardEditor;
