import React from "react";
import gta1 from "../../images/gta/img-1.jpg";
import gta2 from "../../images/gta/img-2.jpg";
import Sectiontitle from "../section-title";
import "./style.css";

const Getting = () => {
  return (
    <div className="gta-area section-padding">
      <Sectiontitle section={"Getting There"} />
      <div className="container">
        <div className="row">
          <div className="col col-lg-8 offset-lg-2 col-md-8 offset-md-2">
            <div className="row">
              <div className="heading col-md-12 col-sm-6">
                <h4>Transportation</h4>
                <div className="gta-content">
                  <p>
                    industry's standard dummy text ever since the 1500s, when an
                    unknown printer took a galley of type and scrambled it to
                    make a type specimen book. It has survived not only five
                    centuries, but also the leap into electronic typesetting,
                    remaining essentially unchanged. It was popularised in the
                    1960s
                  </p>
                </div>
                <div className="gta-img">
                  <img src={gta1} alt="" />
                </div>
              </div>
              <div className="heading heading-2 col-md-12 col-sm-6">
                <h4>Accommodations</h4>
                <div className="gta-content">
                  <p>
                    industry's standard dummy text ever since the 1500s, when an
                    unknown printer took a galley of type and scrambled it to
                    make a type specimen book. It has survived not only five
                    centuries, but also the leap into electronic typesetting,
                    remaining essentially unchanged. It was popularised in the
                    1960s
                  </p>
                </div>
                <div className="gta-img">
                  <img src={gta2} alt="" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Getting;
