import React, { Component } from "react";
import Sectiontitle from "../section-title";
import "./style.css";

class Rsvp extends Component {
  state = {
    name: "",
    email: "",
    rsvp: "",
    events: "",
    notes: "",
    error: {},
  };

  changeHandler = (e) => {
    const error = this.state.error;
    error[e.target.name] = "";

    this.setState({
      [e.target.name]: e.target.value,
      error,
    });
  };

  subimtHandler = (e) => {
    e.preventDefault();

    const { name, email, rsvp, events, notes, error } = this.state;

    if (name === "") {
      error.name = "Please enter your name";
    }
    if (email === "") {
      error.email = "Please enter your email";
    }
    if (rsvp === "") {
      error.rsvp = "Select your number of rsvp";
    }
    if (events === "") {
      error.events = "Select your event list";
    }
    if (notes === "") {
      error.notes = "Please enter your note";
    }

    if (error) {
      this.setState({
        error,
      });
    }
    if (
      error.name === "" &&
      error.email === "" &&
      error.email === "" &&
      error.rsvp === "" &&
      error.events === "" &&
      error.notes === ""
    ) {
      this.setState({
        name: "",
        email: "",
        rsvp: "",
        events: "",
        notes: "",
        error: {},
      });
    }
  };

  render() {
    const { name, email, rsvp, events, notes, error } = this.state;
    return (
      <div id="rsvp" className="rsvp-area go-rsvp-area section-padding">
        <Sectiontitle section={"Be Our Guest"} />
        <div className="container">
          <div className="row">
            <div className="col-lg-8 offset-lg-2 col-md-10 offset-md-1">
              <div className="rsvp-wrap">
                <form onSubmit={this.subimtHandler}>
                  <div className="contact-form form-style">
                    <div className="col-12 col-sm-12">
                      <input
                        type="text"
                        value={name}
                        onChange={this.changeHandler}
                        placeholder="Your Name*"
                        id="fname"
                        name="name"
                      />
                      <p>{error.name ? error.name : ""}</p>
                    </div>
                    <div className="col-12  col-sm-12">
                      <input
                        type="text"
                        placeholder="Your Email*"
                        onChange={this.changeHandler}
                        value={email}
                        id="email"
                        name="email"
                      />
                      <p>{error.email ? error.email : ""}</p>
                    </div>
                    <div className="col col-sm-12">
                      <select
                        className="form-control"
                        onChange={this.changeHandler}
                        value={rsvp}
                        name="rsvp"
                      >
                        <option disabled value="">
                          Number Of rsvp*
                        </option>
                        <option value="1">1</option>
                        <option value="2">2</option>
                        <option value="3">3</option>
                        <option value="4">4</option>
                      </select>
                      <p>{error.rsvp ? error.rsvp : ""}</p>
                    </div>
                    <div className="col col-sm-12">
                      <select
                        className="form-control"
                        onChange={this.changeHandler}
                        value={events}
                        name="events"
                      >
                        <option disabled value="">
                          I Am Attending*
                        </option>
                        <option value="1">Al events</option>
                        <option value="2">Wedding ceremony</option>
                        <option value="3">Reception party</option>
                      </select>
                      <p>{error.events ? error.events : ""}</p>
                    </div>
                    <div className="col-12 col-sm-12">
                      <textarea
                        className="contact-textarea"
                        value={notes}
                        onChange={this.changeHandler}
                        placeholder="Message"
                        name="notes"
                      ></textarea>
                      <p>{error.notes ? error.notes : ""}</p>
                    </div>
                    <div className="col-12 text-center">
                      <button id="submit" type="submit" className="submit">
                        Send Invitation
                      </button>
                    </div>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
}

export default Rsvp;
