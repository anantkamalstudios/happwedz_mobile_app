// import React from "react";

// const ModernCouple = ({ brideData, groomData }) => {
//   return (
//     <>
//       <style>{`
//         .couple-section {
//           background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
//           padding: 80px 0;
//           position: relative;
//           overflow: hidden;
//         }

//         .couple-section::before {
//           content: '';
//           position: absolute;
//           top: 0;
//           left: 0;
//           right: 0;
//           bottom: 0;
//           background-image: radial-gradient(circle, rgba(178, 201, 211, 0.1) 1px, transparent 1px);
//           background-size: 30px 30px;
//           pointer-events: none;
//         }

//         .section-title {
//           text-align: center;
//           margin-bottom: 60px;
//           position: relative;
//           z-index: 1;
//         }

//         .section-title h2 {
//           font-size: 48px;
//           font-weight: 700;
//           color: #2c3e50;
//           margin-bottom: 15px;
//           font-family: 'Georgia', serif;
//         }

//         .section-title p {
//           font-size: 18px;
//           color: #7f8c8d;
//           font-style: italic;
//         }

//         .couple-container {
//           position: relative;
//           max-width: 1200px;
//           margin: 0 auto;
//           padding: 0 15px;
//         }

//         .couple-card {
//           background: white;
//           border-radius: 20px;
//           padding: 40px;
//           box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
//           transition: transform 0.3s ease, box-shadow 0.3s ease;
//           height: 100%;
//           position: relative;
//         }

//         .couple-card:hover {
//           transform: translateY(-10px);
//           box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
//         }

//         .couple-image-wrapper {
//           position: relative;
//           width: 280px;
//           height: 280px;
//           margin: 0 auto 30px;
//         }

//         .couple-image {
//           width: 100%;
//           height: 100%;
//           object-fit: cover;
//           border-radius: 50%;
//           border: 6px solid #b2c9d3;
//           transition: all 0.4s ease;
//           filter: grayscale(0%);
//         }

//         .couple-card:hover .couple-image {
//           filter: grayscale(20%);
//           border-color: #8fb3c7;
//         }

//         .image-decoration {
//           position: absolute;
//           bottom: 10px;
//           right: 10px;
//           width: 60px;
//           height: 60px;
//           background: linear-gradient(135deg, #b2c9d3, #8fb3c7);
//           border-radius: 50%;
//           display: flex;
//           align-items: center;
//           justify-content: center;
//           box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
//           z-index: 2;
//         }

//         .image-decoration svg {
//           width: 30px;
//           height: 30px;
//           fill: white;
//         }

//         .couple-info {
//           text-align: center;
//         }

//         .couple-name {
//           font-size: 32px;
//           font-weight: 700;
//           color: #2c3e50;
//           margin-bottom: 15px;
//           font-family: 'Georgia', serif;
//         }

//         .couple-description {
//           font-size: 16px;
//           color: #5a6c7d;
//           line-height: 1.8;
//           margin: 0;
//         }

//         .heart-divider {
//           position: absolute;
//           left: 50%;
//           top: 50%;
//           transform: translate(-50%, -50%);
//           z-index: 10;
//           width: 80px;
//           height: 80px;
//           background: white;
//           border-radius: 50%;
//           display: flex;
//           align-items: center;
//           justify-content: center;
//           box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
//         }

//         .heart-divider svg {
//           width: 45px;
//           height: 45px;
//           fill: #e74c3c;
//           animation: heartbeat 1.5s ease-in-out infinite;
//         }

//         @keyframes heartbeat {
//           0%, 100% { transform: scale(1); }
//           10%, 30% { transform: scale(1.1); }
//           20% { transform: scale(1); }
//         }

//         .divider-line {
//           position: absolute;
//           top: 50%;
//           width: 100%;
//           height: 2px;
//           background: linear-gradient(90deg,
//             transparent 0%,
//             rgba(178, 201, 211, 0.5) 20%,
//             rgba(178, 201, 211, 0.8) 50%,
//             rgba(178, 201, 211, 0.5) 80%,
//             transparent 100%);
//           z-index: 1;
//         }

//         .bride-side::after {
//           content: '';
//           position: absolute;
//           right: -30px;
//           top: 50%;
//           transform: translateY(-50%);
//           width: 30px;
//           height: 2px;
//           background: linear-gradient(90deg, rgba(178, 201, 211, 0.8), transparent);
//         }

//         .groom-side::before {
//           content: '';
//           position: absolute;
//           left: -30px;
//           top: 50%;
//           transform: translateY(-50%);
//           width: 30px;
//           height: 2px;
//           background: linear-gradient(90deg, transparent, rgba(178, 201, 211, 0.8));
//         }

//         @media (max-width: 991px) {
//           .heart-divider {
//             position: relative;
//             left: auto;
//             top: auto;
//             transform: none;
//             margin: 30px auto;
//           }

//           .divider-line {
//             display: none;
//           }

//           .bride-side::after,
//           .groom-side::before {
//             display: none;
//           }

//           .section-title h2 {
//             font-size: 36px;
//           }

//           .couple-card {
//             margin-bottom: 30px;
//           }
//         }

//         @media (max-width: 575px) {
//           .couple-section {
//             padding: 50px 0;
//           }

//           .couple-image-wrapper {
//             width: 220px;
//             height: 220px;
//           }

//           .couple-name {
//             font-size: 26px;
//           }

//           .couple-description {
//             font-size: 15px;
//           }
//         }
//       `}</style>

//       <div className="couple-section">
//         <div className="container">
//           <div className="section-title">
//             <h2>Happy Couple</h2>
//             <p>Two souls, one heart</p>
//           </div>

//           <div className="couple-container">
//             <div className="divider-line d-none d-lg-block"></div>

//             <div className="row align-items-center position-relative">
//               <div className="col-lg-6 col-md-12 bride-side">
//                 <div className="couple-card">
//                   <div className="couple-image-wrapper">
//                     <img
//                       src={
//                         brideData?.image_url ||
//                         brideData?.image ||
//                         "https://via.placeholder.com/280"
//                       }
//                       alt="Bride"
//                       className="couple-image"
//                     />
//                     <div className="image-decoration">
//                       <svg
//                         viewBox="0 0 24 24"
//                         xmlns="http://www.w3.org/2000/svg"
//                       >
//                         <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
//                       </svg>
//                     </div>
//                   </div>
//                   <div className="couple-info">
//                     <h3 className="couple-name">
//                       {brideData?.name || "The Bride"}
//                     </h3>
//                     <p className="couple-description">
//                       {brideData?.description ||
//                         "Something about bride information"}
//                     </p>
//                   </div>
//                 </div>
//               </div>

//               <div className="heart-divider d-none d-lg-flex">
//                 <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
//                   <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
//                 </svg>
//               </div>

//               <div className="col-lg-6 col-md-12 groom-side">
//                 <div className="couple-card">
//                   <div className="couple-image-wrapper">
//                     <img
//                       src={
//                         groomData?.image_url ||
//                         groomData?.image ||
//                         "https://via.placeholder.com/280"
//                       }
//                       alt="Groom"
//                       className="couple-image"
//                     />
//                     <div className="image-decoration">
//                       <svg
//                         viewBox="0 0 24 24"
//                         xmlns="http://www.w3.org/2000/svg"
//                       >
//                         <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
//                       </svg>
//                     </div>
//                   </div>
//                   <div className="couple-info">
//                     <h3 className="couple-name">
//                       {groomData?.name || "The Groom"}
//                     </h3>
//                     <p className="couple-description">
//                       {groomData?.description ||
//                         "Something about groom information"}
//                     </p>
//                   </div>
//                 </div>
//               </div>

//               <div className="heart-divider d-flex d-lg-none">
//                 <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
//                   <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
//                 </svg>
//               </div>
//             </div>
//           </div>
//         </div>
//       </div>
//     </>
//   );
// };
// export default ModernCouple;

import React from "react";
import Sectiontitle from "../section-title";

const ModernCouple = ({ brideData, groomData }) => {
  return (
    <>
      <style>{`
        .modern-couple-section {
          background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
          padding: 80px 0;
          position: relative;
          overflow: hidden;
        }

        .modern-couple-section::before {
          content: '';
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background-image: radial-gradient(circle, rgba(178, 201, 211, 0.1) 1px, transparent 1px);
          background-size: 30px 30px;
          pointer-events: none;
        }

        .modern-couple-title {
          text-align: center;
          // margin-bottom: 60px;
          position: relative;
          z-index: 1;
        }

        .modern-couple-title h2 {
          font-size: 48px;
          font-weight: 700;
          color: #2c3e50;
          // margin-bottom: 15px;
          font-family: 'Georgia', serif;
        }

        .modern-couple-title p {
          font-size: 18px;
          color: #7f8c8d;
          font-style: italic;
        }

        .modern-couple-container {
          position: relative;
          max-width: 1200px;
          margin: 0 auto;
          padding: 0 15px;
        }

        .modern-couple-card {
          background: white;
          border-radius: 20px;
          padding: 40px;
          box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
          transition: transform 0.3s ease, box-shadow 0.3s ease;
          height: 100%;
          position: relative;
        }

        .modern-couple-card:hover {
          transform: translateY(-10px);
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
        }

        .modern-couple-image-wrapper {
          position: relative;
          width: 280px;
          height: 280px;
          margin: 0 auto 30px;
        }

        .modern-couple-image {
          width: 100%;
          height: 100%;
          object-fit: cover;
          border-radius: 50%;
          border: 6px solid #b2c9d3;
          transition: all 0.4s ease;
          filter: grayscale(0%);
        }

        .modern-couple-card:hover .modern-couple-image {
          filter: grayscale(20%);
          border-color: #8fb3c7;
        }

        .modern-couple-image-decoration {
          position: absolute;
          bottom: 10px;
          right: 10px;
          width: 60px;
          height: 60px;
          background: linear-gradient(135deg, #b2c9d3, #8fb3c7);
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
          z-index: 2;
        }

        .modern-couple-image-decoration svg {
          width: 30px;
          height: 30px;
          fill: white;
        }

        .modern-couple-info {
          text-align: center;
        }

        .modern-couple-name {
          font-size: 32px;
          font-weight: 700;
          color: #2c3e50;
          margin-bottom: 15px;
          font-family: 'Georgia', serif;
        }

        .modern-couple-description {
          font-size: 16px;
          color: #5a6c7d;
          line-height: 1.8;
          margin: 0;
        }

        .modern-couple-heart-divider {
          position: absolute;
          left: 50%;
          top: 50%;
          transform: translate(-50%, -50%);
          z-index: 10;
          width: 80px;
          height: 80px;
          background: white;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
        }

        .modern-couple-heart-divider svg {
          width: 45px;
          height: 45px;
          fill: #e74c3c;
          animation: modern-couple-heartbeat 1.5s ease-in-out infinite;
        }

        @keyframes modern-couple-heartbeat {
          0%, 100% { transform: scale(1); }
          10%, 30% { transform: scale(1.1); }
          20% { transform: scale(1); }
        }

        .modern-couple-divider-line {
          position: absolute;
          top: 50%;
          width: 100%;
          height: 2px;
          background: linear-gradient(90deg, 
            transparent 0%, 
            rgba(178, 201, 211, 0.5) 20%, 
            rgba(178, 201, 211, 0.8) 50%, 
            rgba(178, 201, 211, 0.5) 80%, 
            transparent 100%);
          z-index: 1;
        }

        .modern-couple-bride-side::after {
          content: '';
          position: absolute;
          right: -30px;
          top: 50%;
          transform: translateY(-50%);
          width: 30px;
          height: 2px;
          background: linear-gradient(90deg, rgba(178, 201, 211, 0.8), transparent);
        }

        .modern-couple-groom-side::before {
          content: '';
          position: absolute;
          left: -30px;
          top: 50%;
          transform: translateY(-50%);
          width: 30px;
          height: 2px;
          background: linear-gradient(90deg, transparent, rgba(178, 201, 211, 0.8));
        }

        @media (max-width: 991px) {
          .modern-couple-heart-divider {
            position: relative;
            left: auto;
            top: auto;
            transform: none;
            margin: 30px auto;
          }

          .modern-couple-divider-line {
            display: none;
          }

          .modern-couple-bride-side::after,
          .modern-couple-groom-side::before {
            display: none;
          }

          .modern-couple-title h2 {
            font-size: 36px;
          }

          .modern-couple-card {
            margin-bottom: 30px;
          }
        }

        @media (max-width: 575px) {
          .modern-couple-section {
            padding: 50px 0;
          }

          .modern-couple-image-wrapper {
            width: 220px;
            height: 220px;
          }

          .modern-couple-name {
            font-size: 26px;
          }

          .modern-couple-description {
            font-size: 15px;
          }
        }
      `}</style>

      <div className="modern-couple-section " id="couple">
        <div className="row align-items-center justify-content-center">
          {/* <h2>Happy Couple</h2> */}{" "}
          <Sectiontitle section={"Happy Couple"} />
          <div className="modern-couple-title">
            <p>Two souls, one heart</p>
          </div>
          <div className="modern-couple-container">
            <div className="modern-couple-divider-line d-none d-lg-block"></div>

            <div className="row align-items-center position-relative">
              <div className="col-lg-6 col-md-12 modern-couple-bride-side">
                <div className="modern-couple-card">
                  <div className="modern-couple-image-wrapper">
                    <img
                      src={
                        brideData?.image_url ||
                        brideData?.image ||
                        "https://via.placeholder.com/280"
                      }
                      alt="Bride"
                      className="modern-couple-image"
                    />
                    <div className="modern-couple-image-decoration">
                      <svg
                        viewBox="0 0 24 24"
                        xmlns="http://www.w3.org/2000/svg"
                      >
                        <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
                      </svg>
                    </div>
                  </div>
                  <div className="modern-couple-info">
                    <h3 className="modern-couple-name">
                      {brideData?.name || "The Bride"}
                    </h3>
                    <p className="modern-couple-description">
                      {brideData?.description ||
                        "Something about bride information"}
                    </p>
                  </div>
                </div>
              </div>

              <div className="modern-couple-heart-divider d-none d-lg-flex">
                <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
                </svg>
              </div>
              <div className="modern-couple-heart-divider d-flex d-lg-none">
                <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
                </svg>
              </div>

              <div className="col-lg-6 col-md-12 modern-couple-groom-side">
                <div className="modern-couple-card">
                  <div className="modern-couple-image-wrapper">
                    <img
                      src={
                        groomData?.image_url ||
                        groomData?.image ||
                        "https://via.placeholder.com/280"
                      }
                      alt="Groom"
                      className="modern-couple-image"
                    />
                    <div className="modern-couple-image-decoration">
                      <svg
                        viewBox="0 0 24 24"
                        xmlns="http://www.w3.org/2000/svg"
                      >
                        <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
                      </svg>
                    </div>
                  </div>
                  <div className="modern-couple-info">
                    <h3 className="modern-couple-name">
                      {groomData?.name || "The Groom"}
                    </h3>
                    <p className="modern-couple-description">
                      {groomData?.description ||
                        "Something about groom information"}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default ModernCouple;
