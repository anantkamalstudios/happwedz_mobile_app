import React from "react";
import Sectiontitle from "../section-title";

const styles = `
  .wedding-party-main-section {
    background: linear-gradient(180deg, #ffffff 0%, #f8f9fa 100%);
    position: relative;
    padding: 0 0 60px 0;
  }

  .wedding-party-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 15px;
  }

  .wedding-party-section-header {
    text-align: center;
    margin-bottom: 70px;
    position: relative;
  }

  .wedding-party-section-header h2 {
    font-size: 48px;
    font-weight: 700;
    color: #1a1a1a;
    margin-bottom: 20px;
    font-family: 'Georgia', serif;
    letter-spacing: -0.5px;
  }

  .wedding-party-section-header p {
    font-size: 18px;
    color: #6c757d;
    max-width: 600px;
    margin: 0 auto;
    line-height: 1.6;
  }

  .wedding-party-divider {
    width: 80px;
    height: 4px;
    background: linear-gradient(90deg, #667eea, #764ba2);
    margin: 20px auto;
    border-radius: 2px;
  }

  .wedding-party-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 30px;
    margin-top: 50px;
  }

  .wedding-party-card {
    background: #ffffff;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
    transition: all 0.4s cubic-bezier(0.165, 0.84, 0.44, 1);
    position: relative;
  }

  .wedding-party-card:hover {
    transform: translateY(-12px);
    box-shadow: 0 12px 40px rgba(0, 0, 0, 0.15);
  }

  .wedding-party-card:before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, #667eea, #764ba2);
    transform: scaleX(0);
    transition: transform 0.4s ease;
  }

  .wedding-party-card:hover:before {
    transform: scaleX(1);
  }

  .wedding-party-image-wrapper {
    position: relative;
    width: 100%;
    padding-top: 120%;
    overflow: hidden;
    background: #e9ecef;
  }

  .wedding-party-image {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.6s cubic-bezier(0.165, 0.84, 0.44, 1);
  }

  .wedding-party-card:hover .wedding-party-image {
    transform: scale(1.08);
  }

  .wedding-party-image-overlay {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: linear-gradient(180deg, transparent 0%, rgba(0, 0, 0, 0.3) 100%);
    opacity: 0;
    transition: opacity 0.4s ease;
  }

  .wedding-party-card:hover .wedding-party-image-overlay {
    opacity: 1;
  }

  .wedding-party-info {
    padding: 25px 20px;
    text-align: center;
    background: #ffffff;
  }

  .wedding-party-name {
    font-size: 20px;
    font-weight: 700;
    color: #212529;
    margin-bottom: 8px;
    letter-spacing: -0.3px;
  }

  .wedding-party-role {
    font-size: 15px;
    color: #6c757d;
    font-weight: 400;
    text-transform: capitalize;
    letter-spacing: 0.5px;
  }

  .wedding-party-role-badge {
    display: inline-block;
    padding: 6px 16px;
    background: linear-gradient(135deg, #667eea15, #764ba215);
    color: #667eea;
    border-radius: 20px;
    font-size: 13px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.8px;
    margin-top: 5px;
  }

  /* Empty State */
  .wedding-party-empty {
    text-align: center;
    padding: 80px 20px;
    color: #6c757d;
  }

  .wedding-party-empty h3 {
    font-size: 24px;
    font-weight: 600;
    margin-bottom: 15px;
    color: #495057;
  }

  .wedding-party-empty p {
    font-size: 16px;
    color: #6c757d;
  }

  /* Responsive Design */
  @media (max-width: 1199px) {
    .wedding-party-grid {
      grid-template-columns: repeat(3, 1fr);
      gap: 25px;
    }
  }

  @media (max-width: 991px) {
    .wedding-party-main-section {
      padding: 80px 0;
    }

    .wedding-party-section-header h2 {
      font-size: 40px;
    }

    .wedding-party-grid {
      grid-template-columns: repeat(2, 1fr);
      gap: 25px;
    }
  }

  @media (max-width: 767px) {
    .wedding-party-main-section {
      padding: 60px 0;
    }

    .wedding-party-section-header {
      margin-bottom: 50px;
    }

    .wedding-party-section-header h2 {
      font-size: 32px;
    }

    .wedding-party-section-header p {
      font-size: 16px;
    }

    .wedding-party-grid {
      gap: 20px;
    }

    .wedding-party-info {
      padding: 20px 15px;
    }

    .wedding-party-name {
      font-size: 18px;
    }

    .wedding-party-role {
      font-size: 14px;
    }
  }

  @media (max-width: 575px) {
    .wedding-party-grid {
      grid-template-columns: 1fr;
      max-width: 400px;
      margin: 0 auto;
    }

    .wedding-party-card {
      max-width: 100%;
    }
  }

  /* Animation for cards on load */
  @keyframes wedding-party-fadeInUp {
    from {
      opacity: 0;
      transform: translateY(30px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .wedding-party-card {
    animation: wedding-party-fadeInUp 0.6s ease forwards;
    opacity: 0;
  }

  .wedding-party-card:nth-child(1) { animation-delay: 0.1s; }
  .wedding-party-card:nth-child(2) { animation-delay: 0.2s; }
  .wedding-party-card:nth-child(3) { animation-delay: 0.3s; }
  .wedding-party-card:nth-child(4) { animation-delay: 0.4s; }
  .wedding-party-card:nth-child(5) { animation-delay: 0.5s; }
  .wedding-party-card:nth-child(6) { animation-delay: 0.6s; }
  .wedding-party-card:nth-child(7) { animation-delay: 0.7s; }
  .wedding-party-card:nth-child(8) { animation-delay: 0.8s; }
`;

const WeddingPartyComponent = ({ weddingParty, guest }) => {
  return (
    <>
      <style>{styles}</style>
      <section
        id="people"
        className={`wedding-party-main-section ${guest || ""}`}
      >
        <div className="wedding-party-container">
          {/* <div className="wedding-party-section-header">
            <h2>Groomsmen & Bridesmaid</h2>
            <div className="wedding-party-divider"></div>
            <p>
              Meet the amazing people who will stand beside us as we celebrate
              the beginning of our journey together
            </p>
          </div> */}
          <Sectiontitle section={"Groomsmen & Bridesmaid"} />

          {weddingParty && weddingParty.length > 0 ? (
            <div className="wedding-party-grid">
              {weddingParty.map((wp, index) => (
                <div className="wedding-party-card" key={index}>
                  <div className="wedding-party-image-wrapper">
                    <img
                      src={wp.image_url || wp.image || wp.imageUrl}
                      alt={wp.name}
                      className="wedding-party-image"
                    />
                    <div className="wedding-party-image-overlay"></div>
                  </div>
                  <div className="wedding-party-info">
                    <h4 className="wedding-party-name">{wp.name}</h4>
                    <div className="wedding-party-role-badge">
                      {wp.relation}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="wedding-party-empty">
              <h3>No Wedding Party Members Yet</h3>
              <p>
                Check back soon to see who will be standing with us on our
                special day
              </p>
            </div>
          )}
        </div>
      </section>
    </>
  );
};

export default WeddingPartyComponent;
