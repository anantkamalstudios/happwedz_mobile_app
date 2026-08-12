// import React from "react";
// import Particles from "react-tsparticles";

// import { Animated } from "react-animated-css";
// // shape
// import star5 from "../../images/hero/5star.svg";
// import roundShape from "../../images/hero/round_shape.svg";
// import shape1 from "../../images/hero/shape1.svg";
// import shape2 from "../../images/hero/shape2.svg";
// import shape3 from "../../images/hero/shape3.svg";
// import star from "../../images/hero/star.svg";
// import starStock from "../../images/hero/star_stock.svg";
// import stockShape from "../../images/hero/stock_shape.svg";

// import "./style.css";

// const PreviewHero = (props) => {
//   return (
//     <div className={`previewHeroArea item1 ${props.preview}`} id="home">
//       <div className="container">
//         <div className="slide-content">
//           <div className="slide-subtitle">
//             <h4>WERE GETTING MARRIED</h4>
//           </div>
//           <div className="slide-title">
//             <h2>Save Our Date</h2>
//           </div>
//           <div className="slide-text">
//             <p>25 December 2019</p>
//           </div>
//           <Animated>
//             <div className="animated-circle"></div>
//           </Animated>
//         </div>
//       </div>

//       <Particles
//         className="particaleWrapper"
//         params={{
//           particles: {
//             number: {
//               value: 20,
//               density: {
//                 enable: true,
//                 value_area: 800,
//               },
//             },
//             line_linked: {
//               enable: false,
//             },
//             move: {
//               speed: 1.5,
//               out_mode: "in",
//             },
//             shape: {
//               type: ["images", "circle"],
//               images: [
//                 {
//                   src: `${star5}`,
//                   height: 13,
//                   width: 15,
//                 },
//                 {
//                   src: `${roundShape}`,
//                   height: 20,
//                   width: 20,
//                 },
//                 {
//                   src: `${shape1}`,
//                   height: 2,
//                   width: 46,
//                 },
//                 {
//                   src: `${shape2}`,
//                   height: 29,
//                   width: 33,
//                 },
//                 {
//                   src: `${shape3}`,
//                   height: 10,
//                   width: 12,
//                 },
//                 {
//                   src: `${star}`,
//                   height: 21,
//                   width: 22,
//                 },
//                 {
//                   src: `${starStock}`,
//                   height: 21,
//                   width: 22,
//                 },
//                 {
//                   src: `${stockShape}`,
//                   height: 5,
//                   width: 7,
//                 },
//               ],
//             },
//             color: {
//               value: "#85aaba",
//             },
//             size: {
//               value: 20,
//               random: true,
//               anim: {
//                 enable: true,
//                 speed: 2,
//                 size_min: 10,
//                 sync: true,
//               },
//             },
//           },
//           opacity: {
//             value: 0.4008530152163807,
//             random: false,
//             anim: {
//               enable: false,
//               speed: 1,
//               opacity_min: 0.1,
//               sync: false,
//             },
//           },
//           interactivity: {
//             detect_on: "window",
//             events: {
//               onhover: {
//                 enable: true,
//                 mode: "repulse",
//               },
//               onclick: {
//                 enable: false,
//                 mode: "bubble",
//               },
//               resize: true,
//             },
//             modes: {
//               grab: {
//                 distance: 400,
//                 line_linked: {
//                   opacity: 1,
//                 },
//               },
//               bubble: {
//                 distance: 400,
//                 size: 40,
//                 duration: 2,
//                 opacity: 8,
//                 speed: 3,
//               },
//               repulse: {
//                 distance: 100,
//                 duration: 0.4,
//               },
//               push: {
//                 particles_nb: 4,
//               },
//               remove: {
//                 particles_nb: 2,
//               },
//             },
//           },
//           retina_detect: false,
//         }}
//       />
//     </div>
//   );
// };
// export default PreviewHero;

import React, { useState, useEffect } from "react";
import Particles from "react-tsparticles";
import "./style.css";

// Import your shape images
import star5 from "../../images/hero/5star.svg";
import roundShape from "../../images/hero/round_shape.svg";
import shape1 from "../../images/hero/shape1.svg";
import shape2 from "../../images/hero/shape2.svg";
import shape3 from "../../images/hero/shape3.svg";
import star from "../../images/hero/star.svg";
import starStock from "../../images/hero/star_stock.svg";
import stockShape from "../../images/hero/stock_shape.svg";

const PreviewHero = (props) => {
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [transitionType, setTransitionType] = useState(0);
  const [sliceStates, setSliceStates] = useState([]);

  // Default images if none provided
  const defaultImages = [
    "https://images.unsplash.com/photo-1519741497674-611481863552?w=1920&q=80",
    "https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=1920&q=80",
    "https://images.unsplash.com/photo-1606800052052-a08af7148866?w=1920&q=80",
    "https://images.unsplash.com/photo-1583939003579-730e3918a45a?w=1920&q=80",
  ];

  const images = props.images || defaultImages;
  const coupleNames = props.coupleNames || { bride: "Sarah", groom: "John" };
  const weddingDate = props.weddingDate || "25 December 2024";

  // Create slices for unique transitions
  useEffect(() => {
    const slices = Array.from({ length: 20 }, (_, i) => ({
      id: i,
      delay: Math.random() * 0.8,
      direction: Math.random() > 0.5 ? 1 : -1,
    }));
    setSliceStates(slices);
  }, []);

  useEffect(() => {
    const interval = setInterval(() => {
      // Cycle through different transition types
      setTransitionType((prev) => (prev + 1) % 5);

      setTimeout(() => {
        setCurrentImageIndex((prev) => (prev + 1) % images.length);
      }, 100);
    }, 5000);

    return () => clearInterval(interval);
  }, [images.length]);

  return (
    <div className={`previewHeroArea item1 ${props.preview || ""}`} id="home">
      {/* Unique Image Transitions Container */}
      <div className="image-transition-container">
        {/* Spiral Transition */}
        {transitionType === 0 && (
          <div className="spiral-transition">
            {Array.from({ length: 12 }).map((_, i) => (
              <div
                key={i}
                className="spiral-piece"
                style={{
                  backgroundImage: `url(${images[currentImageIndex]})`,
                  animationDelay: `${i * 0.05}s`,
                  transform: `rotate(${i * 30}deg)`,
                }}
              />
            ))}
          </div>
        )}

        {/* Liquid Transition */}
        {transitionType === 1 && (
          <div className="liquid-transition">
            {Array.from({ length: 8 }).map((_, i) => (
              <div
                key={i}
                className="liquid-blob"
                style={{
                  backgroundImage: `url(${images[currentImageIndex]})`,
                  animationDelay: `${i * 0.1}s`,
                  left: `${i * 12.5}%`,
                }}
              />
            ))}
          </div>
        )}

        {/* Kaleidoscope Transition */}
        {transitionType === 2 && (
          <div className="kaleidoscope-transition">
            {Array.from({ length: 8 }).map((_, i) => (
              <div
                key={i}
                className="kaleidoscope-piece"
                style={{
                  backgroundImage: `url(${images[currentImageIndex]})`,
                  transform: `rotate(${i * 45}deg)`,
                  animationDelay: `${i * 0.08}s`,
                }}
              />
            ))}
          </div>
        )}

        {/* Shatter Transition */}
        {transitionType === 3 && (
          <div className="shatter-transition">
            {sliceStates.map((slice) => (
              <div
                key={slice.id}
                className="shatter-piece"
                style={{
                  backgroundImage: `url(${images[currentImageIndex]})`,
                  animationDelay: `${slice.delay}s`,
                  "--direction": slice.direction,
                }}
              />
            ))}
          </div>
        )}

        {/* Wave Transition */}
        {transitionType === 4 && (
          <div className="wave-transition">
            {Array.from({ length: 15 }).map((_, i) => (
              <div
                key={i}
                className="wave-strip"
                style={{
                  backgroundImage: `url(${images[currentImageIndex]})`,
                  animationDelay: `${i * 0.05}s`,
                  left: `${i * 6.66}%`,
                }}
              />
            ))}
          </div>
        )}

        {/* Base Image (always visible) */}
        <div
          className="base-image"
          style={{ backgroundImage: `url(${images[currentImageIndex]})` }}
        />
      </div>

      {/* Overlay */}
      <div className="hero-overlay"></div>

      {/* Content */}
      <div className="container">
        <div className="slide-content">
          <div className="slide-subtitle">
            <div className="subtitle-line"></div>
            <h4>WE'RE GETTING MARRIED</h4>
            <div className="subtitle-line"></div>
          </div>
          <div className="slide-title">
            <h2>
              <span className="name-animate">{coupleNames.bride}</span>
              <span className="ampersand">&</span>
              <span className="name-animate">{coupleNames.groom}</span>
            </h2>
          </div>
          <div className="slide-text">
            <p>{weddingDate}</p>
          </div>
          <div className="animated-circle-wrapper">
            <div className="animated-circle">
              <div className="circle-inner">
                <div className="heart-icon">❤</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Particles */}
      <Particles
        className="particaleWrapper"
        params={{
          particles: {
            number: {
              value: 20,
              density: {
                enable: true,
                value_area: 800,
              },
            },
            line_linked: {
              enable: false,
            },
            move: {
              speed: 1.5,
              out_mode: "in",
            },
            shape: {
              type: ["images", "circle"],
              images: [
                { src: star5, height: 13, width: 15 },
                { src: roundShape, height: 20, width: 20 },
                { src: shape1, height: 2, width: 46 },
                { src: shape2, height: 29, width: 33 },
                { src: shape3, height: 10, width: 12 },
                { src: star, height: 21, width: 22 },
                { src: starStock, height: 21, width: 22 },
                { src: stockShape, height: 5, width: 7 },
              ],
            },
            color: {
              value: "#85aaba",
            },
            size: {
              value: 20,
              random: true,
              anim: {
                enable: true,
                speed: 2,
                size_min: 10,
                sync: true,
              },
            },
          },
          opacity: {
            value: 0.4,
            random: false,
            anim: {
              enable: false,
              speed: 1,
              opacity_min: 0.1,
              sync: false,
            },
          },
          interactivity: {
            detect_on: "window",
            events: {
              onhover: {
                enable: true,
                mode: "repulse",
              },
              onclick: {
                enable: false,
                mode: "bubble",
              },
              resize: true,
            },
            modes: {
              repulse: {
                distance: 100,
                duration: 0.4,
              },
            },
          },
          retina_detect: false,
        }}
      />
    </div>
  );
};

export default PreviewHero;
