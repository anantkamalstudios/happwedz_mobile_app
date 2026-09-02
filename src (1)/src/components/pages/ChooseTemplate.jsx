import { TEMPLATE_LIST } from "../../templates";
import { useNavigate } from "react-router-dom";

export default function ChooseTemplate() {
  const navigate = useNavigate();

  const handleCardClick = (templateId) => {
    navigate(`/wedding-form/${templateId}`);
  };

  return (
    <>
      <style>{`
            .choose-template-container { 
                padding: 60px 0;
            }

            .choose-template-header {
                text-align: center;
                margin-bottom: 50px;
            }

            .choose-template-title {
                font-size: 2.8rem;
                font-weight: 700;
                color: #2d2d2d;
                margin-bottom: 15px; 
            }

            .choose-template-subtitle {
                font-size: 1.1rem;
                color: #666;
                font-weight: 300;
            }

            .choose-template-card {
                background: white;
                border-radius: 16px;
                overflow: hidden;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
                transition: all 0.3s ease;
                height: 100%;
                display: flex;
                flex-direction: column;
                cursor: pointer;
            }

            .choose-template-card:hover {
                transform: translateY(-8px);
                box-shadow: 0 12px 40px rgba(0, 0, 0, 0.15);
            }

            .choose-template-image-wrapper {
                position: relative;
                overflow: hidden;
                height: 280px;
            }

            .choose-template-image {
                width: 100%;
                height: 100%;
                object-fit: cover;
                transition: transform 0.4s ease;
            }

            .choose-template-card:hover .choose-template-image {
                transform: scale(1.08);
            }

            .choose-template-overlay {
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: linear-gradient(to bottom, transparent 0%, rgba(212, 87, 124, 0.3) 100%);
                opacity: 0;
                transition: opacity 0.3s ease;
                display: flex;
                align-items: center;
                justify-content: center;
            }

            .choose-template-card:hover .choose-template-overlay {
                opacity: 1;
            }

            .choose-template-overlay-text {
                color: white;
                font-size: 1.3rem;
                font-weight: 600;
                text-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
                opacity: 0;
                transform: translateY(10px);
                transition: all 0.3s ease;
            }

            .choose-template-card:hover .choose-template-overlay-text {
                opacity: 1;
                transform: translateY(0);
            }

            .choose-template-content {
                padding: 25px;
                flex-grow: 1;
                display: flex;
                flex-direction: column;
            }

            .choose-template-name {
                font-size: 1.5rem;
                font-weight: 600;
                color: #2d2d2d;
                margin-bottom: 10px; 
            }

            .choose-template-description {
                color: #666;
                font-size: 0.95rem;
                line-height: 1.6;
                margin-bottom: 0;
                flex-grow: 1;
            }

            @media (max-width: 768px) {
                .choose-template-title {
                    font-size: 2rem;
                }

                .choose-template-container {
                    padding: 40px 0;
                }

                .choose-template-image-wrapper {
                    height: 220px;
                }
            }

            @media (max-width: 576px) {
                .choose-template-title {
                    font-size: 1.6rem;
                }

                .choose-template-subtitle {
                    font-size: 1rem;
                }
            }
        `}</style>

      <div className="choose-template-container">
        <div className="container">
          <div className="choose-template-header">
            <h3 className="choose-template-title">
              Choose Your Wedding Website Template
            </h3>
            <p className="choose-template-subtitle fs-18">
              Select the perfect design to tell your love story
            </p>
          </div>

          <div className="row g-4">
            {TEMPLATE_LIST.map((tpl) => (
              <div key={tpl.id} className="col-12 col-md-6 col-lg-4">
                <div
                  className="choose-template-card"
                  onClick={() => handleCardClick(tpl.id)}
                >
                  <div className="choose-template-image-wrapper">
                    <img
                      src={tpl.previewImage}
                      alt={tpl.name}
                      className="choose-template-image"
                    />
                    <div className="choose-template-overlay">
                      <div className="choose-template-overlay-text">
                        Click to Select
                      </div>
                    </div>
                  </div>
                  <div className="choose-template-content">
                    <h4 className="choose-template-name">{tpl.name}</h4>
                    <p className="choose-template-description fs-16">
                      {tpl.description}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  );
}
