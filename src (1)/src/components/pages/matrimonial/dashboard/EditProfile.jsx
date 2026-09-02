import React, { useState } from "react";
import {
  Container,
  Row,
  Col,
  Form,
  Button,
  Card,
  Tab,
  Tabs,
  Image,
} from "react-bootstrap";
import {
  FiEdit2,
  FiCamera,
  FiSave,
  FiUser,
  FiMail,
  FiPhone,
  FiMapPin,
  FiCalendar,
  FiCheck,
  FiX,
} from "react-icons/fi";

const EditProfile = () => {
  const [key, setKey] = useState("basic");
  const [profilePic, setProfilePic] = useState(
    "https://images.unsplash.com/photo-1511367461989-f85a21fda167?w=80&h=80&fit=crop&crop=center&auto=format&q=60"
  );
  const [formData, setFormData] = useState({
    name: "Priya Sharma",
    email: "priya.sharma@example.com",
    phone: "+91 9876543210",
    dob: "1990-05-15",
    height: "5 ft 4 in",
    maritalStatus: "Never Married",
    religion: "Hindu",
    caste: "Brahmin",
    motherTongue: "Hindi",
    location: "Mumbai, India",
    education: "MBA",
    profession: "Marketing Manager",
    income: "15-20 Lakhs",
    about:
      "I am a fun-loving person who enjoys traveling and trying new cuisines. Family means everything to me and I value honesty and loyalty in relationships.",
    hobbies: "Reading, Dancing, Cooking",
  });
  const [editingField, setEditingField] = useState(null);
  const [tempValue, setTempValue] = useState("");

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleImageChange = (e) => {
    if (e.target.files && e.target.files[0]) {
      const reader = new FileReader();
      reader.onload = (event) => {
        setProfilePic(event.target.result);
      };
      reader.readAsDataURL(e.target.files[0]);
    }
  };

  const startEditing = (fieldName) => {
    setEditingField(fieldName);
    setTempValue(formData[fieldName]);
  };

  const cancelEditing = () => {
    setEditingField(null);
    setTempValue("");
  };

  const saveEditing = () => {
    setFormData((prev) => ({
      ...prev,
      [editingField]: tempValue,
    }));
    setEditingField(null);
    setTempValue("");
  };

  const renderEditableField = (
    fieldName,
    label,
    icon,
    type = "text",
    options = null
  ) => {
    return (
      <div className="matrimony-edit-profile__editable-field">
        <Form.Group className="form-group matrimony-edit-profile__form-group">
          <Form.Label className="matrimony-edit-profile__form-label">
            {icon} {label}
          </Form.Label>
          <div className="matrimony-edit-profile__editable-container">
            {editingField === fieldName ? (
              <div className="matrimony-edit-profile__editing-controls">
                {type === "select" ? (
                  <Form.Control
                    as="select"
                    value={tempValue}
                    onChange={(e) => setTempValue(e.target.value)}
                    autoFocus
                    className="matrimony-edit-profile__form-control"
                  >
                    {options.map((option) => (
                      <option key={option} value={option}>
                        {option}
                      </option>
                    ))}
                  </Form.Control>
                ) : type === "textarea" ? (
                  <Form.Control
                    as="textarea"
                    rows={3}
                    value={tempValue}
                    onChange={(e) => setTempValue(e.target.value)}
                    autoFocus
                    className="matrimony-edit-profile__form-control"
                  />
                ) : (
                  <Form.Control
                    type={type}
                    value={tempValue}
                    onChange={(e) => setTempValue(e.target.value)}
                    autoFocus
                    className="matrimony-edit-profile__form-control"
                  />
                )}
                <div className="matrimony-edit-profile__edit-actions">
                  <Button
                    variant="link"
                    onClick={saveEditing}
                    className="matrimony-edit-profile__save-btn"
                  >
                    <FiCheck />
                  </Button>
                  <Button
                    variant="link"
                    onClick={cancelEditing}
                    className="matrimony-edit-profile__cancel-btn"
                  >
                    <FiX />
                  </Button>
                </div>
              </div>
            ) : (
              <div className="matrimony-edit-profile__display-value">
                <span>{formData[fieldName]}</span>
                <Button
                  variant="link"
                  className="matrimony-edit-profile__edit-btn"
                  onClick={() => startEditing(fieldName)}
                >
                  <FiEdit2 size={14} />
                </Button>
              </div>
            )}
          </div>
        </Form.Group>
      </div>
    );
  };

  return (
    <Container fluid className="matrimony-edit-profile">
      <Row className="justify-content-center">
        <Col lg={10} xl={8}>
          <Card className="matrimony-edit-profile__card">
            <div className="matrimony-edit-profile__header">
              <h2 className="matrimony-edit-profile__title">Edit Profile</h2>
              <p className="matrimony-edit-profile__subtitle">
                Complete your profile to get better matches
              </p>
            </div>

            <Card.Body className="matrimony-edit-profile__body">
              <Row>
                <Col
                  md={4}
                  className="text-center matrimony-edit-profile__sidebar"
                >
                  <div className="matrimony-edit-profile__pic-container">
                    <Image
                      src={profilePic}
                      roundedCircle
                      className="matrimony-edit-profile__pic"
                    />
                    <label
                      htmlFor="profile-upload"
                      className="matrimony-edit-profile__upload-btn"
                    >
                      <FiCamera /> Change Photo
                    </label>
                    <input
                      id="profile-upload"
                      type="file"
                      accept="image/*"
                      onChange={handleImageChange}
                      style={{ display: "none" }}
                    />
                  </div>
                  <div className="matrimony-edit-profile__completion mt-3">
                    <div className="matrimony-edit-profile__completion-bar">
                      <div
                        className="matrimony-edit-profile__progress"
                        style={{ width: "75%" }}
                      ></div>
                    </div>
                    <p className="matrimony-edit-profile__completion-text">
                      Profile 75% complete
                    </p>
                  </div>
                </Col>

                <Col md={8} className="matrimony-edit-profile__main-content">
                  <Tabs
                    activeKey={key}
                    onSelect={(k) => setKey(k)}
                    className="matrimony-edit-profile__tabs"
                  >
                    <Tab
                      eventKey="basic"
                      title="Basic Details"
                      className="matrimony-edit-profile__tab"
                    >
                      <Form className="matrimony-edit-profile__form">
                        {renderEditableField("name", "Full Name", <FiUser />)}

                        <Row>
                          <Col md={6}>
                            {renderEditableField(
                              "email",
                              "Email",
                              <FiMail />,
                              "email"
                            )}
                          </Col>
                          <Col md={6}>
                            {renderEditableField(
                              "phone",
                              "Phone",
                              <FiPhone />,
                              "tel"
                            )}
                          </Col>
                        </Row>

                        <Row>
                          <Col md={6}>
                            {renderEditableField(
                              "dob",
                              "Date of Birth",
                              <FiCalendar />,
                              "date"
                            )}
                          </Col>
                          <Col md={6}>
                            {renderEditableField(
                              "height",
                              "Height",
                              null,
                              "select",
                              [
                                "Select Height",
                                "5 ft 0 in",
                                "5 ft 2 in",
                                "5 ft 4 in",
                                "5 ft 6 in",
                                "5 ft 8 in",
                              ]
                            )}
                          </Col>
                        </Row>

                        {renderEditableField(
                          "location",
                          "Location",
                          <FiMapPin />
                        )}
                      </Form>
                    </Tab>

                    <Tab
                      eventKey="religious"
                      title="Religious Background"
                      className="matrimony-edit-profile__tab"
                    >
                      <Form className="matrimony-edit-profile__form">
                        <Row>
                          <Col md={6}>
                            {renderEditableField(
                              "religion",
                              "Religion",
                              null,
                              "select",
                              ["Hindu", "Muslim", "Christian", "Sikh", "Other"]
                            )}
                          </Col>
                          <Col md={6}>
                            {renderEditableField(
                              "caste",
                              "Caste",
                              null,
                              "select",
                              ["Brahmin", "Rajput", "Baniya", "Other"]
                            )}
                          </Col>
                        </Row>

                        {renderEditableField(
                          "motherTongue",
                          "Mother Tongue",
                          null,
                          "select",
                          ["Hindi", "English", "Marathi", "Bengali", "Other"]
                        )}
                      </Form>
                    </Tab>

                    <Tab
                      eventKey="professional"
                      title="Professional Details"
                      className="matrimony-edit-profile__tab"
                    >
                      <Form className="matrimony-edit-profile__form">
                        {renderEditableField(
                          "education",
                          "Education",
                          null,
                          "select",
                          [
                            "Select Education",
                            "B.Tech",
                            "MBA",
                            "MBBS",
                            "B.Com",
                            "Other",
                          ]
                        )}

                        {renderEditableField("profession", "Profession", null)}

                        {renderEditableField(
                          "income",
                          "Annual Income",
                          null,
                          "select",
                          [
                            "Select Income",
                            "5-10 Lakhs",
                            "10-15 Lakhs",
                            "15-20 Lakhs",
                            "20-25 Lakhs",
                            "25+ Lakhs",
                          ]
                        )}
                      </Form>
                    </Tab>

                    <Tab
                      eventKey="personal"
                      title="Personal Info"
                      className="matrimony-edit-profile__tab"
                    >
                      <Form className="matrimony-edit-profile__form">
                        {renderEditableField(
                          "about",
                          "About Me",
                          null,
                          "textarea"
                        )}

                        {renderEditableField(
                          "hobbies",
                          "Hobbies & Interests",
                          null
                        )}
                      </Form>
                    </Tab>
                  </Tabs>

                  <div className="matrimony-edit-profile__actions">
                    <Button
                      variant="outline-secondary"
                      className="matrimony-edit-profile__cancel-btn"
                    >
                      Cancel
                    </Button>
                    <Button
                      variant="primary"
                      className="matrimony-edit-profile__save-btn"
                    >
                      <FiSave /> Save Changes
                    </Button>
                  </div>
                </Col>
              </Row>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
};

export default EditProfile;
