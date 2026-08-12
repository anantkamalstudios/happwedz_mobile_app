import React from "react";

const HomeGridImages = () => {
  const weddingData = [
    {
      id: 1,
      title: "Smith Wedding",
      image:
        "https://images.unsplash.com/photo-1606216794074-735e91aa2c92?w=1200&h=1200&fit=crop",
    },
    {
      id: 2,
      title: "Johnson Wedding",
      image:
        "https://images.unsplash.com/photo-1519741497674-611481863552?w=1200&h=1200&fit=crop",
    },
    {
      id: 3,
      title: "Williams Wedding",
      image:
        "https://images.unsplash.com/photo-1591604466107-ec97de577aff?w=1200&h=1200&fit=crop",
    },
    {
      id: 4,
      title: "Brown Wedding",
      image:
        "https://images.unsplash.com/photo-1537633552985-df8429e8048b?w=1200&h=1200&fit=crop",
    },
    {
      id: 5,
      title: "Davis Wedding",
      image:
        "https://images.unsplash.com/photo-1583939003579-730e3918a45a?w=1200&h=1200&fit=crop",
    },
    {
      id: 6,
      title: "Miller Wedding",
      image:
        "https://images.unsplash.com/photo-1594568284297-7c64464062b1?w=1200&h=1200&fit=crop",
    },
    {
      id: 7,
      title: "Wilson Wedding",
      image:
        "https://images.unsplash.com/photo-1460978812857-470ed1c77af0?w=1200&h=1200&fit=crop",
    },
    {
      id: 8,
      title: "Moore Wedding",
      image:
        "https://images.unsplash.com/photo-1522673607200-164d1b6ce486?w=1200&h=1200&fit=crop",
    },
    {
      id: 9,
      title: "Taylor Wedding",
      image:
        "https://images.unsplash.com/photo-1606800052052-a08af7148866?w=1200&h=1200&fit=crop",
    },
  ];

  return (
    <section className="wedding_moments_section_3k7m9">
      <div className="container-fluid px-5 px-md-4 px-lg-5">
        <div className="row mb-4 mb-md-5">
          <div className="col-12">
            <h2 className="section_title_8n2w4">Recent Wedding Moments</h2>
          </div>
        </div>

        <div className="row g-4 g-lg-5">
          {weddingData.map((wedding) => (
            <div key={wedding.id} className="col-12 col-md-6 col-lg-4">
              <div className="wedding_card_5j9p2">
                <div className="card_image_wrapper_7k3m1">
                  <img
                    src={wedding.image}
                    alt={wedding.title}
                    className="wedding_card_img_2n8x6"
                  />
                </div>
                <div className="card_content_4m7k9">
                  <h3 className="card_title_6p2w8">{wedding.title}</h3>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <style>{`
        .wedding_moments_section_3k7m9 {
          padding: 80px 5rem;
          background-color: #f5f5f5;
        }

        .section_title_8n2w4 {
          font-size: 36px;
          font-weight: 700;
          color: #1a1a1a;
          margin-bottom: 0;
        }

        .wedding_card_5j9p2 {
          background-color: #ffffff;
          overflow: hidden;
          transition: all 0.3s ease;
          cursor: pointer;
          height: 100%;
          display: flex;
          flex-direction: column;
          box-shadow: 0 4px 6px rgba(0,0,0,0.05);
        }

        .wedding_card_5j9p2:hover { 
          box-shadow: 0 15px 35px rgba(0, 0, 0, 0.15);
          transform: translateY(-5px);
        }

        .card_image_wrapper_7k3m1 {
          width: 100%;
          overflow: hidden;
          position: relative;
        }

        .wedding_card_img_2n8x6 {
          width: 100%;
          height: auto;
          object-fit: cover;
          display: block;
          transition: transform 0.6s cubic-bezier(0.25, 0.46, 0.45, 0.94);
        }

        .wedding_card_5j9p2:hover .wedding_card_img_2n8x6 {
          transform: scale(1.08);
        }

        .card_content_4m7k9 {
          padding: 28px 24px;
          text-align: center;
          background-color: #ffffff;
        }

        .card_title_6p2w8 {
          font-size: 22px;
          font-weight: 600;
          color: #2c3e50;
          margin: 0;
        }

        @media (max-width: 1199px) {
          .section_title_8n2w4 {
            font-size: 32px;
          }

          .wedding_card_img_2n8x6 {
            height: 400px;
          }

          .card_title_6p2w8 {
            font-size: 20px;
          }
        }

        @media (max-width: 991px) {
          .wedding_moments_section_3k7m9 {
            padding: 60px 0;
          }

          .section_title_8n2w4 {
            font-size: 30px;
          }

          .wedding_card_img_2n8x6 {
            height: 350px;
          }

          .card_content_4m7k9 {
            padding: 24px 20px;
          }

          .card_title_6p2w8 {
            font-size: 19px;
          }
        }

        @media (max-width: 767px) {
          .wedding_moments_section_3k7m9 {
            padding: 50px 0;
          }

          .section_title_8n2w4 {
            font-size: 28px;
          }

          .wedding_card_img_2n8x6 {
            height: 320px;
          }

          .card_content_4m7k9 {
            padding: 20px 16px;
          }

          .card_title_6p2w8 {
            font-size: 18px;
          }
        }

        @media (max-width: 575px) {
          .wedding_moments_section_3k7m9 {
            padding: 40px 0;
          }

          .section_title_8n2w4 {
            font-size: 26px;
          }

          .wedding_card_img_2n8x6 {
            height: 300px;
          }

          .card_content_4m7k9 {
            padding: 16px 12px;
          }

          .card_title_6p2w8 {
            font-size: 17px;
          }
        }
      `}</style>
    </section>
  );
};

export default HomeGridImages;
