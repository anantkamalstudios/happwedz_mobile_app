import React from "react";
import { Link } from "react-router-dom";
import Sectiontitle from "../section-title";
import bride1 from "../../images/groomsmen-bridesmaid/1.jpg";
import bride2 from "../../images/groomsmen-bridesmaid/2.jpg";
import bride3 from "../../images/groomsmen-bridesmaid/3.jpg";
import bride4 from "../../images/groomsmen-bridesmaid/4.jpg";
import bride5 from "../../images/groomsmen-bridesmaid/5.jpg";
import bride6 from "../../images/groomsmen-bridesmaid/6.jpg";
import bride7 from "../../images/groomsmen-bridesmaid/7.jpg";
import bride8 from "../../images/groomsmen-bridesmaid/8.jpg";

import "./style.css";

const People = (props) => {
  return (
    <section id="people">
      <div
        className={`groomsmen-bridesmaid-area section-padding ${
          props.guest || ""
        }`}
      >
        <Sectiontitle section={"Groomsmen & Bridesmaid"} />
        <div className="container">
          <div className="groomsmen-bridesmaid-area-menu">
            <div className="Groomsman-wrap">
              <div className="row">
                {props.weddingParty &&
                  props.weddingParty.map((wp, index) => (
                    <div
                      className="col-lg-3 col-md-6 col-sm-6 grid"
                      key={index}
                    >
                      <div className="groomsmen-bridesmaid-wrap">
                        <div className="groomsmen-bridesmaid-img">
                          <img
                            src={wp.image_url || wp.image || wp.imageUrl}
                            alt="bride"
                            style={{ objectFit: "cover", width: "100%" }}
                          />
                          {/* <div className="social-list">
                            <ul className="d-flex">
                              <li>
                                <Link to="/">
                                  <span className="fa fa-facebook"></span>
                                </Link>
                              </li>
                              <li>
                                <Link to="/">
                                  <span className="fa fa-twitter"></span>
                                </Link>
                              </li>
                              <li>
                                <Link to="/">
                                  <span className="fa fa-linkedin"></span>
                                </Link>
                              </li>
                              <li>
                                <Link to="/">
                                  <span className="fa fa-pinterest"></span>
                                </Link>
                              </li>
                            </ul>
                          </div> */}
                        </div>
                        <div className="groomsmen-bridesmaid-content">
                          <h4>{wp.name}</h4>
                          <span>{wp.relation}</span>
                        </div>
                      </div>
                    </div>
                  ))}
                {/* <div className="col-lg-3 col-md-6 col-sm-6 grid">
                                    <div className="groomsmen-bridesmaid-wrap groomsmen-bridesmaid-wrap-2">
                                        <div className="groomsmen-bridesmaid-img">
                                        <img src={bride2 } alt="bride"/>
                                            <div className="social-list">
                                                <ul className="d-flex">
                                                    <li><Link to='/'><span className="fa fa-facebook"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-twitter"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-linkedin"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-pinterest"></span></Link></li>
                                                </ul>
                                            </div>
                                        </div>
                                        <div className="groomsmen-bridesmaid-content">
                                            <h4>{wp.name}</h4>
                                            <span>{wp.relation}</span>
                                        </div>
                                    </div>
                                </div>
                                <div className="col-lg-3 col-md-6 col-sm-6 grid">
                                    <div className="groomsmen-bridesmaid-wrap">
                                        <div className="groomsmen-bridesmaid-img">
                                        <img src={bride3 } alt="bride"/>
                                            <div className="social-list">
                                                <ul className="d-flex">
                                                    <li><Link to='/'><span className="fa fa-facebook"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-twitter"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-linkedin"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-pinterest"></span></Link></li>
                                                </ul>
                                            </div>
                                        </div>
                                        <div className="groomsmen-bridesmaid-content">
                                            <h4>Ema Aliana</h4>
                                            <span>Friend</span>
                                        </div>
                                    </div>
                                </div>
                                <div className="col-lg-3 col-md-6 col-sm-6 grid">
                                    <div className="groomsmen-bridesmaid-wrap groomsmen-bridesmaid-wrap-2">
                                        <div className="groomsmen-bridesmaid-img">
                                        <img src={bride4 } alt="bride"/>
                                            <div className="social-list">
                                                <ul className="d-flex">
                                                    <li><Link to='/'><span className="fa fa-facebook"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-twitter"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-linkedin"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-pinterest"></span></Link></li>
                                                </ul>
                                            </div>
                                        </div>
                                        <div className="groomsmen-bridesmaid-content">
                                            <h4>Joey Famira</h4>
                                            <span>Friend</span>
                                        </div>
                                    </div>
                                </div>
                                <div className="col-lg-3 col-md-6 col-sm-6 grid">
                                    <div className="groomsmen-bridesmaid-wrap groomsmen-bridesmaid-wrap-2">
                                        <div className="groomsmen-bridesmaid-img">
                                        <img src={bride5 } alt="bride"/>
                                            <div className="social-list">
                                                <ul className="d-flex">
                                                    <li><Link to='/'><span className="fa fa-facebook"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-twitter"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-linkedin"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-pinterest"></span></Link></li>
                                                </ul>
                                            </div>
                                        </div>
                                        <div className="groomsmen-bridesmaid-content">
                                            <h4>Criys stone</h4>
                                            <span>Made Of Honor</span>
                                        </div>
                                    </div>
                                </div>
                                <div className="col-lg-3 col-md-6 col-sm-6 grid">
                                    <div className="groomsmen-bridesmaid-wrap">
                                        <div className="groomsmen-bridesmaid-img">
                                        <img src={bride6 } alt="bride"/>
                                            <div className="social-list">
                                                <ul className="d-flex">
                                                    <li><Link to='/'><span className="fa fa-facebook"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-twitter"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-linkedin"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-pinterest"></span></Link></li>
                                                </ul>
                                            </div>
                                        </div>
                                        <div className="groomsmen-bridesmaid-content">
                                            <h4>Watson Lyn</h4>
                                            <span>best-friend</span>
                                        </div>
                                    </div>
                                </div>
                                <div className="col-lg-3 col-md-6 col-sm-6 grid">
                                    <div className="groomsmen-bridesmaid-wrap groomsmen-bridesmaid-wrap-2">
                                        <div className="groomsmen-bridesmaid-img">
                                        <img src={bride7 } alt="bride"/>
                                            <div className="social-list">
                                                <ul className="d-flex">
                                                    <li><Link to='/'><span className="fa fa-facebook"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-twitter"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-linkedin"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-pinterest"></span></Link></li>
                                                </ul>
                                            </div>
                                        </div>
                                        <div className="groomsmen-bridesmaid-content">
                                            <h4>Chris Fletcher</h4>
                                            <span>Friend</span>
                                        </div>
                                    </div>
                                </div>
                                <div className="col-lg-3 col-md-6 col-sm-6 grid">
                                    <div className="groomsmen-bridesmaid-wrap mb-0">
                                        <div className="groomsmen-bridesmaid-img">
                                        <img src={bride8 } alt="bride"/>
                                            <div className="social-list">
                                                <ul className="d-flex">
                                                    <li><Link to='/'><span className="fa fa-facebook"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-twitter"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-linkedin"></span></Link></li>
                                                    <li><Link to='/'><span className="fa fa-pinterest"></span></Link></li>
                                                </ul>
                                            </div>
                                        </div>
                                        <div className="groomsmen-bridesmaid-content">
                                            <h4>John Clyne</h4>
                                            <span>Friend</span>
                                        </div>
                                    </div>
                                </div> */}
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default People;
