// import React, { Component } from "react";
// import Slider from "react-slick";
// import {Animated} from "react-animated-css";
// import "slick-carousel/slick/slick.css";
// import "slick-carousel/slick/slick-theme.css";

// class HeroMain extends Component {
//     render() {
//       var settings = {
//         dots: false,
//         arrows: true,
//         speed: 1200,
//         slidesToShow: 1,
//         slidesToScroll: 1,
//         autoplay:true,
//         autoplaySpeed:2500,
//         fade:true
//       };
//       const images = Array.isArray(this.props.sliderImages) ? this.props.sliderImages : [];

//       return (
//         <Slider {...settings}>
//           {images.map((img, index) => {
//             // const url = (typeof img === 'string' ? img : img?.url) || '';
//             console.log(img);

//             return (
//               <div
//                 key={index}
//                 className="items1"
//                 style={{
//                   backgroundImage: `url(${img})`,
//                   height: '950px',
//                   display: 'flex',
//                   justifyContent: 'center',
//                   flexDirection: 'column',
//                   width: '100%',
//                   backgroundSize: 'cover',
//                   backgroundPosition: 'center',
//                   backgroundRepeat: 'no-repeat'
//                 }}
//               >
//                 <div className="container">
//                   <div className="slide-content">
//                     <div className="slide-subtitle">
//                       <h4>WERE GETTING MARRIED</h4>
//                     </div>
//                     <div className="slide-title">
//                       <h2>Save Our Date</h2>
//                     </div>
//                     <div className="slide-text">
//                       <p>25 December 2019</p>
//                     </div>
//                     <Animated>
//                       <div className="animated-circle"></div>
//                     </Animated>
//                   </div>
//                 </div>
//               </div>
//             );
//           })}
//         </Slider>
//       );
//     }
//   }

// export default HeroMain;

import React, { Component } from "react";
import Slider from "react-slick";
import { Animated } from "react-animated-css";
import "slick-carousel/slick/slick.css";
import "slick-carousel/slick/slick-theme.css";

class HeroMain extends Component {
  render() {
    const settings = {
      dots: false,
      arrows: true,
      speed: 1200,
      slidesToShow: 2,
      slidesToScroll: 2,
      autoplay: true,
      autoplaySpeed: 2500,
      fade: true,
    };

    const images = Array.isArray(this.props.sliderImages)
      ? this.props.sliderImages
      : [];

    const weddingDate = this.props.weddingDate;
    const formatted = new Date(weddingDate).toLocaleDateString("en-US", {
      day: "2-digit",
      month: "long",
      year: "numeric",
    });

    return (
      <Slider {...settings}>
        {images.map((img, index) => (
          <div
            key={index}
            className="items1 col-lg-12"
            style={{ position: "relative" }}
          >
            <img
              src={img}
              alt={`Slide ${index + 1}`}
              style={{
                position: "absolute",
                top: 0,
                left: 0,
                width: "100%",
                height: "100%",
                objectFit: "cover",
                zIndex: 0,
              }}
            />

            <div
              className="container"
              style={{
                position: "relative",
                zIndex: 2,
                height: "950px",
                display: "flex",
                justifyContent: "center",
                flexDirection: "column",
                alignItems: "center",
                color: "#fff",
              }}
            >
              <div className="slide-content">
                <div className="slide-subtitle">
                  <h4>WE'RE GETTING MARRIED</h4>
                </div>
                <div className="slide-title">
                  <h2>Save Our Date</h2>
                </div>
                <div className="slide-text">
                  <p>{formatted}</p>
                </div>
                <Animated>
                  <div className="animated-circle"></div>
                </Animated>
              </div>
            </div>

            <div
              style={{
                position: "absolute",
                top: 0,
                left: 0,
                width: "100%",
                height: "100%",
                backgroundColor: "rgba(0, 0, 0, 0.3)",
                zIndex: 1,
              }}
            ></div>
          </div>
        ))}
      </Slider>
    );
  }
}

export default HeroMain;
