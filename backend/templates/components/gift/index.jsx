import React, { Component } from "react";
import Slider from "react-slick";
import "slick-carousel/slick/slick.css";
import "slick-carousel/slick/slick-theme.css";
import gift1 from '../../images/gift/img-1.jpg'
import gift2 from '../../images/gift/img-2.jpg'
import gift3 from '../../images/gift/img-3.jpg'
import gift4 from '../../images/gift/img-4.jpg'
import './style.css'


class Gift extends Component {
    render() {
      var settings = {
        dots: false,
        arrows: false,
        speed: 500,
        slidesToShow: 4,
        slidesToScroll: 1,
        autoplay:true,
        autoplaySpeed:1500,
        responsive: [
            {
              breakpoint: 1024,
              settings: {
                slidesToShow: 3,
                slidesToScroll: 3,
                infinite: true,
              }
            },
            {
              breakpoint: 600,
              settings: {
                slidesToShow: 2,
                slidesToScroll: 2
              }
            },
            {
              breakpoint: 480,
              settings: {
                slidesToShow: 2,
                slidesToScroll: 1
              }
            }
          ]
      };
      return (
          <div className="gift-area">
              <div className="container">
                  <div className="row">
                      <div className="col-lg-12">
                        <Slider {...settings}>
                            <div className="item">
                                <img src={gift1} alt=""/>
                            </div>
                            <div className="item">
                                <img src={gift2} alt=""/>
                            </div>
                            <div className="item">
                                <img src={gift3} alt=""/>
                            </div>
                            <div className="item">
                                <img src={gift4} alt=""/>
                            </div>
                            <div className="item">
                                <img src={gift1} alt=""/>
                            </div>
                            <div className="item">
                                <img src={gift2} alt=""/>
                            </div>
                            <div className="item">
                                <img src={gift3} alt=""/>
                            </div>
                            <div className="item">
                                <img src={gift4} alt=""/>
                            </div>
                            </Slider>
                      </div>
                  </div>
              </div>
          </div>
      );
    }
  }

export default Gift;