import React from "react";
import "bootstrap/dist/css/bootstrap.min.css";

export default function WeddingHero() {
  return (
    <div className="container-fluid p-0">
      <style>{`
        .hero-section {
          position: relative;
          height: 100vh;
          min-height: 500px;
          background-image: url('https://images.unsplash.com/photo-1519741497674-611481863552?w=1600');
          background-size: cover;
          background-position: center;
          background-repeat: no-repeat;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        
        .hero-overlay {
          position: absolute;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          background: linear-gradient(to bottom, rgba(0,0,0,0.3), rgba(0,0,0,0.5));
        }
        
        .hero-content {
          position: relative;
          z-index: 2;
          text-align: center;
          color: white;
          padding: 20px;
          max-width: 900px;
          margin: 0 auto;
        }
        
        .hero-subtitle {
          font-size: 1.2rem;
          font-weight: 300;
          letter-spacing: 3px;
          text-transform: uppercase;
          margin-bottom: 1rem;
          opacity: 0.95;
        }
        
        .hero-title {
          font-size: 3.5rem;
          font-weight: 700;
          line-height: 1.2;
          margin-bottom: 1.5rem;
          text-shadow: 2px 2px 8px rgba(0,0,0,0.3);
        }
        
        .hero-description {
          font-size: 1.1rem;
          font-weight: 300;
          line-height: 1.6;
          margin-bottom: 2rem;
          opacity: 0.9;
        }
        
        .btn-wedding {
          padding: 12px 40px;
          font-size: 1rem;
          font-weight: 500;
          letter-spacing: 1px;
          text-transform: uppercase;
          border-radius: 30px;
          transition: all 0.3s ease;
          margin: 0 10px;
        }
        
        .btn-primary-wedding {
          background-color: #d4af37;
          border: 2px solid #d4af37;
          color: white;
        }
        
        .btn-primary-wedding:hover {
          background-color: transparent;
          border: 2px solid #d4af37;
          color: #d4af37;
          transform: translateY(-2px);
        }
        
        .btn-outline-wedding {
          background-color: transparent;
          border: 2px solid white;
          color: white;
        }
        
        .btn-outline-wedding:hover {
          background-color: white;
          color: #333;
          transform: translateY(-2px);
        }
        
        @media (max-width: 768px) {
          .hero-section {
            height: 80vh;
            min-height: 400px;
          }
          
          .hero-subtitle {
            font-size: 0.9rem;
            letter-spacing: 2px;
          }
          
          .hero-title {
            font-size: 2rem;
          }
          
          .hero-description {
            font-size: 1rem;
          }
          
          .btn-wedding {
            padding: 10px 30px;
            font-size: 0.9rem;
            margin: 5px;
          }
        }
        
        @media (max-width: 576px) {
          .hero-title {
            font-size: 1.75rem;
          }
          
          .btn-wedding {
            display: block;
            width: 100%;
            margin: 10px 0;
          }
        }
      `}</style>

      <section className="hero-section">
        <div className="hero-overlay"></div>

        <div className="hero-content">
          <h2 className="hero-title fw-bold">
            Crafting Unforgettable Destination Weddings for Your Happy Day
          </h2>
        </div>
      </section>
    </div>
  );
}
