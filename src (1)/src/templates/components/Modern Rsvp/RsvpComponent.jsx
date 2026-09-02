import React, { Component } from "react";
import Sectiontitle from "../section-title";

const styles = `
  /* RSVP Section Styles */
  .rsvp-main-section {
    padding: 80px 0;
    background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
    position: relative;
    overflow: hidden;
  }

  .rsvp-section-title {
    text-align: center;
    margin-bottom: 60px;
    position: relative;
  }

  .rsvp-section-title h2 {
    font-size: 48px;
    font-weight: 700;
    color: #2c3e50;
    margin-bottom: 15px;
    font-family: 'Georgia', serif;
    text-transform: capitalize;
    position: relative;
    display: inline-block;
  }

  .rsvp-section-title h2:after {
    content: '';
    position: absolute;
    bottom: -15px;
    left: 50%;
    transform: translateX(-50%);
    width: 100px;
    height: 4px;
    background: linear-gradient(90deg, transparent, #ff6b6b, transparent);
    border-radius: 2px;
  }

  .rsvp-section-title p {
    font-size: 16px;
    color: #7f8c8d;
    margin-top: 25px;
    font-style: italic;
  }

  .rsvp-container {
    max-width: 1140px;
    margin: 0 auto;
    padding: 0 15px;
  }

  .rsvp-form-wrapper {
    background: rgba(255, 255, 255, 0.95);
    padding: 60px;
    border-radius: 25px;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.8);
    max-width: 800px;
    margin: 0 auto;
    // position: relative;
  }

  // .rsvp-form-wrapper:before {
  //   content: '';
  //   position: absolute;
  //   top: -40px;
  //   left: 50%;
  //   transform: translateX(-50%);
  //   font-size: 60px;
  //   background: white;
  //   width: 100px;
  //   height: 100px;
  //   border-radius: 50%;
  //   display: flex;
  //   align-items: center;
  //   justify-content: center;
  //   box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
  // }

  .rsvp-form-group {
    margin-bottom: 30px;
    position: relative;
  }

  .rsvp-form-label {
    display: block;
    font-size: 14px;
    font-weight: 600;
    color: #34495e;
    margin-bottom: 10px;
    text-transform: uppercase;
    letter-spacing: 1px;
  }

  .rsvp-input,
  .rsvp-select,
  .rsvp-textarea {
    width: 100%;
    padding: 16px 20px;
    font-size: 16px;
    border: 2px solid #e0e6ed;
    border-radius: 12px;
    background: #f8f9fa;
    color: #2c3e50;
    transition: all 0.3s ease;
    font-family: inherit;
  }

  .rsvp-input:focus,
  .rsvp-select:focus,
  .rsvp-textarea:focus {
    outline: none;
    border-color: #667eea;
    background: #ffffff;
    box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.1);
    transform: translateY(-2px);
  }

  .rsvp-input::placeholder,
  .rsvp-textarea::placeholder {
    color: #95a5a6;
    font-style: italic;
  }

  .rsvp-select {
    cursor: pointer;
    appearance: none;
    background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%23667eea' d='M6 9L1 4h10z'/%3E%3C/svg%3E");
    background-repeat: no-repeat;
    background-position: right 20px center;
    padding-right: 50px;
  }

  .rsvp-select option {
    padding: 10px;
    background: white;
    color: #2c3e50;
  }

  .rsvp-textarea {
    min-height: 150px;
    resize: vertical;
    font-family: inherit;
  }

  .rsvp-error-message {
    color: #e74c3c;
    font-size: 13px;
    margin-top: 8px;
    display: block;
    font-weight: 500;
    animation: rsvp-shake 0.3s ease;
  }

  @keyframes rsvp-shake {
    0%, 100% { transform: translateX(0); }
    25% { transform: translateX(-5px); }
    75% { transform: translateX(5px); }
  }

  .rsvp-submit-wrapper {
    text-align: center;
    margin-top: 40px;
  }

 .rsvp-submit-btn {
 font-size: 16px;
  background: none;
  border: none;
  padding: 10px 30px;
  background: #bcdae8;
  color: #333;
  border-radius: 5px;
  margin-top: 20px;
  cursor: pointer;
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 40px;
}
.rsvp-submit-btn:focus {
  outline: none;
}

.rsvp-submit-btn:hover {
  background: #b2c9d3;
}

  // .rsvp-submit-btn {
  //   background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  //   border: none;
  //   padding: 18px 60px;
  //   color: #ffffff;
  //   font-size: 16px;
  //   font-weight: 700;
  //   border-radius: 50px;
  //   cursor: pointer;
  //   transition: all 0.4s ease;
  //   text-transform: uppercase;
  //   letter-spacing: 2px;
  //   box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
  //   position: relative;
  //   overflow: hidden;
  // }

  // .rsvp-submit-btn:before {
  //   content: '';
  //   position: absolute;
  //   top: 0;
  //   left: -100%;
  //   width: 100%;
  //   height: 100%;
  //   background: linear-gradient(90deg, transparent, rgba(255,255,255,0.3), transparent);
  //   transition: left 0.5s ease;
  // }

  // .rsvp-submit-btn:hover:before {
  //   left: 100%;
  // }

  // .rsvp-submit-btn:hover {
  //   transform: translateY(-3px);
  //   box-shadow: 0 15px 40px rgba(102, 126, 234, 0.5);
  // }

  // .rsvp-submit-btn:active {
  //   transform: translateY(-1px);
  // }

  .rsvp-success-message {
    background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%);
    border: 2px solid #28a745;
    color: #155724;
    padding: 20px 30px;
    border-radius: 15px;
    margin-bottom: 30px;
    text-align: center;
    font-weight: 600;
    font-size: 16px;
    animation: rsvp-slideDown 0.5s ease;
    box-shadow: 0 5px 20px rgba(40, 167, 69, 0.2);
  }

  @keyframes rsvp-slideDown {
    from {
      opacity: 0;
      transform: translateY(-20px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .rsvp-input-icon {
    position: absolute;
    right: 20px;
    top: 50%;
    transform: translateY(-50%);
    color: #95a5a6;
    font-size: 18px;
    pointer-events: none;
  }

  .rsvp-form-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
  }

  /* Decorative Elements */
  .rsvp-decoration {
    position: absolute;
    pointer-events: none;
    opacity: 0.1;
  }

  .rsvp-decoration-1 {
    top: 10%;
    left: 5%;
    font-size: 100px;
    transform: rotate(-15deg);
  }

  .rsvp-decoration-2 {
    bottom: 10%;
    right: 5%;
    font-size: 100px;
    transform: rotate(15deg);
  }

  /* Responsive Design */
  @media (max-width: 991px) {
    .rsvp-section-title h2 {
      font-size: 40px;
    }

    .rsvp-form-wrapper {
      padding: 50px 40px;
    }

    .rsvp-form-row {
      grid-template-columns: 1fr;
    }
  }

  @media (max-width: 767px) {
    .rsvp-main-section {
      padding: 60px 0;
    }

    .rsvp-section-title h2 {
      font-size: 32px;
    }

    .rsvp-section-title p {
      font-size: 14px;
    }

    .rsvp-form-wrapper {
      padding: 40px 25px;
      border-radius: 20px;
    }

    .rsvp-form-wrapper:before {
      width: 80px;
      height: 80px;
      font-size: 50px;
      top: -35px;
    }

    .rsvp-input,
    .rsvp-select,
    .rsvp-textarea {
      padding: 14px 16px;
      font-size: 15px;
    }

    .rsvp-submit-btn {
      padding: 16px 45px;
      font-size: 14px;
    }

    .rsvp-decoration {
      display: none;
    }
  }

  @media (max-width: 480px) {
    .rsvp-form-wrapper {
      padding: 30px 20px;
    }

    .rsvp-submit-btn {
      width: 100%;
      padding: 16px 30px;
    }
  }
`;

class RsvpComponent extends Component {
  state = {
    name: "",
    email: "",
    rsvp: "",
    events: "",
    notes: "",
    error: {},
    submitted: false,
  };

  changeHandler = (e) => {
    const error = { ...this.state.error };
    error[e.target.name] = "";

    this.setState({
      [e.target.name]: e.target.value,
      error,
      submitted: false,
    });
  };

  submitHandler = () => {
    const { name, email, rsvp, events, notes } = this.state;
    const error = {};

    // Validation
    if (!name.trim()) {
      error.name = "Please enter your name";
    }

    if (!email.trim()) {
      error.email = "Please enter your email";
    } else if (!/\S+@\S+\.\S+/.test(email)) {
      error.email = "Please enter a valid email address";
    }

    if (!rsvp) {
      error.rsvp = "Please select number of guests";
    }

    if (!events) {
      error.events = "Please select which events you'll attend";
    }

    if (!notes.trim()) {
      error.notes = "Please enter a message";
    }

    if (Object.keys(error).length > 0) {
      this.setState({ error });
      return;
    }

    // Success - reset form
    this.setState({
      name: "",
      email: "",
      rsvp: "",
      events: "",
      notes: "",
      error: {},
      submitted: true,
    });

    // Hide success message after 5 seconds
    setTimeout(() => {
      this.setState({ submitted: false });
    }, 5000);
  };

  render() {
    const { name, email, rsvp, events, notes, error, submitted } = this.state;

    return (
      <>
        <style>{styles}</style>
        <div id="rsvp" className="rsvp-main-section">
          <div className="rsvp-decoration rsvp-decoration-1">💐</div>
          <div className="rsvp-decoration rsvp-decoration-2">💍</div>

          <div className="rsvp-container">
            {/* <div className="rsvp-section-title">
              <h2>Be Our Guest</h2>
              <p>We would love to have you join us on our special day</p>
            </div> */}
            <Sectiontitle section={"Be Our Guest"} />

            <div className="rsvp-form-wrapper">
              {submitted && (
                <div className="rsvp-success-message">
                  Thank you! Your RSVP has been submitted successfully!
                </div>
              )}

              <div className="rsvp-form-row">
                <div className="rsvp-form-group">
                  <label className="rsvp-form-label">Your Name</label>
                  <input
                    type="text"
                    className="rsvp-input"
                    value={name}
                    onChange={this.changeHandler}
                    placeholder="Enter your full name"
                    name="name"
                  />
                  {error.name && (
                    <span className="rsvp-error-message">⚠ {error.name}</span>
                  )}
                </div>

                <div className="rsvp-form-group">
                  <label className="rsvp-form-label">Email Address</label>
                  <input
                    type="email"
                    className="rsvp-input"
                    placeholder="your.email@example.com"
                    onChange={this.changeHandler}
                    value={email}
                    name="email"
                  />
                  {error.email && (
                    <span className="rsvp-error-message">⚠ {error.email}</span>
                  )}
                </div>
              </div>

              <div className="rsvp-form-row">
                <div className="rsvp-form-group">
                  <label className="rsvp-form-label">Number of Guests</label>
                  <select
                    className="rsvp-select"
                    onChange={this.changeHandler}
                    value={rsvp}
                    name="rsvp"
                  >
                    <option value="">Select number of guests</option>
                    <option value="1">1 Guest</option>
                    <option value="2">2 Guests</option>
                    <option value="3">3 Guests</option>
                    <option value="4">4 Guests</option>
                    <option value="5">5+ Guests</option>
                  </select>
                  {error.rsvp && (
                    <span className="rsvp-error-message">⚠ {error.rsvp}</span>
                  )}
                </div>

                <div className="rsvp-form-group">
                  <label className="rsvp-form-label">Attending Events</label>
                  <select
                    className="rsvp-select"
                    onChange={this.changeHandler}
                    value={events}
                    name="events"
                  >
                    <option value="">Select events to attend</option>
                    <option value="all">All Events</option>
                    <option value="ceremony">Wedding Ceremony Only</option>
                    <option value="reception">Reception Party Only</option>
                  </select>
                  {error.events && (
                    <span className="rsvp-error-message">⚠ {error.events}</span>
                  )}
                </div>
              </div>
              {/* <div className="rsvp-form-row">
                <div className="rsvp-form-group">
                  <label className="rsvp-form-label">Number of Guests</label>
                  <input
                    type="number"
                    placeholder="Enter number of guests"
                    className="rsvp-input"
                    onChange={this.changeHandler}
                    value={rsvp}
                    name="rsvp"
                  />
                  {error.rsvp && (
                    <span className="rsvp-error-message">⚠ {error.rsvp}</span>
                  )}
                </div>

                <div className="rsvp-form-group">
                  <label className="rsvp-form-label">Attending Events</label>
                  <input
                    type="text"
                    placeholder="Enter event names (e.g., Ceremony, Reception)"
                    className="rsvp-input"
                    onChange={this.changeHandler}
                    value={events}
                    name="events"
                  />
                  {error.events && (
                    <span className="rsvp-error-message">⚠ {error.events}</span>
                  )}
                </div>
              </div> */}

              <div className="rsvp-form-group">
                <label className="rsvp-form-label">Special Message</label>
                <textarea
                  className="rsvp-textarea"
                  value={notes}
                  onChange={this.changeHandler}
                  placeholder="Share your wishes or any special requirements (dietary restrictions, accessibility needs, etc.)"
                  name="notes"
                ></textarea>
                {error.notes && (
                  <span className="rsvp-error-message">⚠ {error.notes}</span>
                )}
              </div>

              <div className="rsvp-submit-wrapper">
                <button
                  type="button"
                  onClick={this.submitHandler}
                  className="rsvp-submit-btn"
                >
                  Send Invitation
                </button>
              </div>
            </div>
          </div>
        </div>
      </>
    );
  }
}

export default RsvpComponent;
