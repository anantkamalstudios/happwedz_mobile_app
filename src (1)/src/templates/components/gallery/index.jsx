import React, { Component } from "react";
import ReactFancyBox from "react-fancybox";
import "react-fancybox/lib/fancybox.css";
import Sectiontitle from "../section-title";
import "./style.css";

class Gallery extends Component {
  render() {
    const { galleryImages = [] } = this.props;
    return (
      <div id="gallery" className="Gallery-section section-padding">
        <Sectiontitle section={"Our Gellary"} />
        <div className="container">
          <div className="row">
            {galleryImages.map((img, index) => (
              <div className="col-lg-4 col-md-6 col-sm-6 col-12" key={index}>
                <div className="gallery-img">
                  {/* <ReactFancyBox
                    thumbnail={img}
                    image={img}
                    style={{
                      innerWidth: "100%",
                      objectFit: "cover",
                    }}
                  /> */}
                  <img
                    src={img}
                    alt="image"
                    style={{ width: "100%", height: "400px" }}
                  />
                </div>
              </div>
            ))}
            {/* <div className="col-lg-4 col-md-6 col-sm-6 col-12">
                      <div className="gallery-img">
                        <ReactFancyBox
                            thumbnail={galimg2}
                            image={galimg2}/>
                      </div>
                  </div>
                  <div className="col-lg-4 col-md-6 col-sm-6 col-12">
                      <div className="gallery-img">
                        <ReactFancyBox
                            thumbnail={galimg3}
                            image={galimg3}/>
                      </div>
                  </div>
                  <div className="col-lg-4 col-md-6 col-sm-6 col-12">
                      <div className="gallery-img">
                        <ReactFancyBox
                            thumbnail={galimg4}
                            image={galimg4}/>
                      </div>
                  </div>
                  <div className="col-lg-4 col-md-6 col-sm-6 col-12">
                      <div className="gallery-img">
                        <ReactFancyBox
                            thumbnail={galimg5}
                            image={galimg5}/>
                      </div>
                  </div>
                  <div className="col-lg-4 col-md-6 col-sm-6 col-12">
                      <div className="gallery-img">
                        <ReactFancyBox
                            thumbnail={galimg6}
                            image={galimg6}/>
                      </div>
                  </div> */}
          </div>
        </div>
      </div>
    );
  }
}

export default Gallery;
