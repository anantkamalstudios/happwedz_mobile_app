// import React, { useState } from "react";
// import { Button, Modal, ModalHeader, ModalBody } from "reactstrap";
// import Sectiontitle from "../section-title";

// import "./style.css";

// const Location = (props) => {
//   const { className } = props;

//   const [modal, setModal] = useState(false);

//   const toggle = () => setModal(!modal);

//   console.log("location data ", props);

//   return (
//     <div id="event" className="event-section section-padding">
//       <Sectiontitle section={"When & Where"} />
//       <div className="container">
//         <div className="row">
//           <div className="col-12">
//             <div className="tabs-site-button">
//               <div className="event-tabs">
//                 <div className="col-md-12 col-12">
//                   {props.whenWhere &&
//                     props.whenWhere.map((ww, index) => (
//                       <div className="event-wrap" key={index}>
//                         <div className="row">
//                           <div className="col-lg-5 col-md-12 col-12">
//                             <div className="event-img">
//                               <img
//                                 src={ww.image || ww.image_url || ww.imageUrl}
//                                 alt=""
//                               />
//                             </div>
//                           </div>
//                           <div className="col-lg-7 col-md-12 col-12">
//                             <div className="event-text">
//                               <h3>{ww.title}</h3>
//                               <span>{ww.date}</span>
//                               <span>{ww.location}</span>
//                               <p>{ww.description}</p>
//                               <Button className="btn" onClick={toggle}>
//                                 Location
//                               </Button>
//                               <Modal
//                                 isOpen={modal}
//                                 toggle={toggle}
//                                 className={className}
//                               >
//                                 <ModalHeader toggle={toggle}>
//                                   Location
//                                 </ModalHeader>
//                                 <ModalBody>
//                                   <div className="location-map">
//                                     <iframe src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d57763.58882182253!2d55.38442113562169!3d25.195692423227655!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3e5f43496ad9c645%3A0xbde66e5084295162!2z4Kam4KeB4Kas4Ka-4KaHIC0g4Kam4KeB4Kas4Ka-4KaHIOCmhuCmruCmv-CmsOCmvuCmpCAtIOCmuOCmguCmr-CngeCmleCnjeCmpCDgpobgprDgpqwg4KaG4Kau4Ka_4Kaw4Ka-4Kak!5e0!3m2!1sbn!2sbd!4v1540725271741" />
//                                   </div>
//                                 </ModalBody>
//                               </Modal>
//                             </div>
//                           </div>
//                         </div>
//                       </div>
//                     ))}
//                   {/* <div className="event-wrap">
//                                         <div className="row">
//                                             <div className="col-lg-7 col-md-12 col-12">
//                                                 <div className="event-text event-text-2">
//                                                     <h3>Wedding Party</h3>
//                                                     <span>Sunday, 25 July 18, 9.00 AM-5.00 PM</span>
//                                                     <span>256 Apay Road,Califonia Bong, London</span>
//                                                     <p>It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal </p>
//                                                     <Button className="btn" onClick={toggle}>Location</Button>
//                                                     <Modal isOpen={modal} toggle={toggle} className={className}>
//                                                         <ModalHeader toggle={toggle}>Location</ModalHeader>
//                                                         <ModalBody>
//                                                             <div className="location-map">
//                                                                 <iframe src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d57763.58882182253!2d55.38442113562169!3d25.195692423227655!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3e5f43496ad9c645%3A0xbde66e5084295162!2z4Kam4KeB4Kas4Ka-4KaHIC0g4Kam4KeB4Kas4Ka-4KaHIOCmhuCmruCmv-CmsOCmvuCmpCAtIOCmuOCmguCmr-CngeCmleCnjeCmpCDgpobgprDgpqwg4KaG4Kau4Ka_4Kaw4Ka-4Kak!5e0!3m2!1sbn!2sbd!4v1540725271741" />
//                                                             </div>
//                                                         </ModalBody>
//                                                     </Modal>
//                                                 </div>
//                                             </div>
//                                             <div className="col-lg-5 col-md-12 col-12">
//                                                 <div className="event-img">
//                                                     <img src={strory2} alt="" />
//                                                 </div>
//                                             </div>
//                                         </div>
//                                     </div>
//                                     <div className="event-wrap">
//                                         <div className="row">
//                                             <div className="col-lg-5 col-md-12 col-12">
//                                                 <div className="event-img">
//                                                     <img src={strory3} alt="" />
//                                                 </div>
//                                             </div>
//                                             <div className="col-lg-7 col-md-12 col-12">
//                                                 <div className="event-text">
//                                                     <h3>Wedding Dinner</h3>
//                                                     <span>Sunday, 25 July 18, 9.00 AM-5.00 PM</span>
//                                                     <span>256 Apay Road,Califonia Bong, London</span>
//                                                     <p>It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal </p>
//                                                     <Button className="btn" onClick={toggle}>Location</Button>
//                                                     <Modal isOpen={modal} toggle={toggle} className={className}>
//                                                         <ModalHeader toggle={toggle}>Location</ModalHeader>
//                                                         <ModalBody>
//                                                             <div className="location-map">
//                                                                 <iframe src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d57763.58882182253!2d55.38442113562169!3d25.195692423227655!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3e5f43496ad9c645%3A0xbde66e5084295162!2z4Kam4KeB4Kas4Ka-4KaHIC0g4Kam4KeB4Kas4Ka-4KaHIOCmhuCmruCmv-CmsOCmvuCmpCAtIOCmuOCmguCmr-CngeCmleCnjeCmpCDgpobgprDgpqwg4KaG4Kau4Ka_4Kaw4Ka-4Kak!5e0!3m2!1sbn!2sbd!4v1540725271741" />
//                                                             </div>
//                                                         </ModalBody>
//                                                     </Modal>
//                                                 </div>
//                                             </div>
//                                         </div>
//                                     </div> */}
//                 </div>
//               </div>
//             </div>
//           </div>
//         </div>
//       </div>
//     </div>
//   );
// };
// export default Location;

import React, { useState } from "react";
import { Button, Modal, ModalHeader, ModalBody } from "reactstrap";
import Sectiontitle from "../section-title";

import "./style.css";

const Location = (props) => {
  const { className } = props;

  const [activeModal, setActiveModal] = useState(null);

  const toggle = (index) => {
    setActiveModal(activeModal === index ? null : index);
  };

  return (
    <div id="event" className="event-section section-padding">
      <Sectiontitle section={"When & Where"} />
      <div className="container">
        <div className="row">
          <div className="col-12">
            <div className="tabs-site-button">
              <div className="event-tabs">
                <div className="col-md-12 col-12">
                  {props.whenWhere &&
                    props.whenWhere.map((ww, index) => (
                      <div className="event-wrap" key={index}>
                        <div className="row align-items-center">
                          <div
                            className={`col-lg-5 col-md-12 col-12 ${
                              index % 2 === 1 ? "order-lg-2" : ""
                            }`}
                          >
                            <div className="event-img">
                              <img
                                src={ww.image || ww.image_url || ww.imageUrl}
                                alt={ww.title}
                              />
                            </div>
                          </div>
                          <div
                            className={`col-lg-7 col-md-12 col-12 ${
                              index % 2 === 1 ? "order-lg-1" : ""
                            }`}
                          >
                            <div className="event-text">
                              <h3>{ww.title}</h3>
                              <div className="event-details">
                                <span className="event-date">
                                  <i className="date-icon">📅</i> {ww.date}
                                </span>
                                {ww.time && (
                                  <span className="event-time">
                                    <i className="time-icon">🕐</i> {ww.time}
                                  </span>
                                )}
                                <span className="event-location">
                                  <i className="location-icon">📍</i>{" "}
                                  {ww.location}
                                </span>
                              </div>
                              <p>{ww.description}</p>
                              <Button
                                className="btn location-btn"
                                onClick={() => toggle(index)}
                              >
                                <span className="btn-icon">📍</span> View
                                Location
                              </Button>
                              <Modal
                                isOpen={activeModal === index}
                                toggle={() => toggle(index)}
                                className={className}
                                size="lg"
                              >
                                <ModalHeader toggle={() => toggle(index)}>
                                  {ww.title} - Location
                                </ModalHeader>
                                <ModalBody>
                                  <div className="location-map">
                                    <iframe
                                      src={
                                        ww.mapUrl ||
                                        `https://www.google.com/maps?q=${encodeURIComponent(
                                          ww.location
                                        )}&z=15&output=embed`
                                      }
                                      title={`Map for ${ww.title}`}
                                      frameBorder="0"
                                      allowFullScreen
                                    />
                                  </div>
                                </ModalBody>
                              </Modal>
                            </div>
                          </div>
                        </div>
                      </div>
                    ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
export default Location;
