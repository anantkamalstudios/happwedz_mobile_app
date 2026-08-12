import React, { Component } from "react";
import AnchorLink from "react-anchor-link-smooth-scroll";
import { Collapse, CardBody, Card } from "reactstrap";
import { Link } from "react-router-dom";
import "./style.css";
import { IoClose } from "react-icons/io5";

export default class MobileMenu extends Component {
  state = {
    isMenuShow: false,
    isOpen: false,
  };

  menuHandler = () => {
    this.setState({
      isMenuShow: !this.state.isMenuShow,
    });
  };

  setIsOpen = () => {
    this.setState({
      isOpen: !this.state.isOpen,
    });
  };

  render() {
    const { isMenuShow, isOpen } = this.state;

    return (
      <div>
        <div className={`mobileMenu ${isMenuShow ? "show" : ""}`}>
          <div className="clox" onClick={this.menuHandler}>
            <IoClose size={24} />
          </div>
          <div className="logo2">
            <h2>
              <Link to="/home">David & Aliza</Link>
            </h2>
          </div>
          <ul className="responsivemenu">
            {/* <li><p onClick={this.setIsOpen}>Home<i className="fa fa-angle-right" aria-hidden="true"></i></p></li>
                        <Collapse isOpen={isOpen}>
                            <Card>
                                <CardBody>
                                    <li><Link to='/home'>Home style 1</Link></li>
                                    <li><Link to='/home2'>Home style 2</Link></li>
                                    <li><Link to='/home3'>Home style 3</Link></li>
                                    <li><Link to='/home4'>Home style 4</Link></li>
                                    <li><Link to='/home5'>Home video</Link></li>
                                </CardBody>
                            </Card>
                        </Collapse> */}
            <li>
              <AnchorLink href="#couple">Couple</AnchorLink>
            </li>
            <li>
              <AnchorLink href="#story">Story</AnchorLink>
            </li>
            <li>
              <AnchorLink href="#people">People</AnchorLink>
            </li>
            <li>
              <AnchorLink href="#event">Events</AnchorLink>
            </li>
            <li>
              <AnchorLink href="#gallery">Gallery</AnchorLink>
            </li>
            <li>
              <AnchorLink href="#rsvp">Rsvp</AnchorLink>
            </li>
            <li>
              <Link to="/blog">Blog</Link>
            </li>
            {/* <li>
              <Link to="/Blog-details">Blog Details</Link>
            </li> */}
          </ul>
        </div>

        <div className="showmenu" onClick={this.menuHandler}>
          <i className="fa fa-bars" aria-hidden="true"></i>
        </div>
      </div>
    );
  }
}
