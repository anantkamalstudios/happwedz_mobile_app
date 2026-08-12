// import React from "react";
// import { Link } from "react-router-dom";
// import Sectiontitle from "../section-title";
// import strory1 from "../../images/story/img-1.jpg";
// import strory2 from "../../images/story/img-2.jpg";
// import strory3 from "../../images/story/img-3.jpg";
// import strory4 from "../../images/story/img-4.jpg";
// import "./style.css";

// const Story = ({ loveStory }) => {
//   return (
//     <div id="story" className="story-area section-padding">
//       <Sectiontitle section={"Our Love Story"} />
//       <div className="container">
//         <div className="story-wrap">
//           <div className="row">
//             {loveStory &&
//               loveStory.map((story, index) => (
//                 <>
//                   <div className="col-lg-6 col-md-12 col-12 pr-n">
//                     <div className="story-img">
//                       <img
//                         src={story.image_url || story.imageUrl || story.image}
//                         alt=""
//                       />
//                     </div>
//                   </div>
//                   <div className="col-lg-6 col-md-12 col-12">
//                     <div className="story-text left-align-text">
//                       <h3>{story.title}</h3>
//                       <span className="date">{story.date}</span>
//                       <p>{story.description}</p>
//                       <div className="story-button">
//                         <Link className="theme-btn" to="/">
//                           Read More
//                         </Link>
//                       </div>
//                     </div>
//                   </div>
//                 </>
//               ))}
//             {/* <div className="col-lg-6 col-md-12 col-12">
//                             <div className="story-text right-align-text">
//                                 <h3>Our First Date</h3>
//                                 <span className="date">Dec 25, 2017</span>
//                                 <p>A wonderful serenity has taken possession of my entire soul, like these sweet mornings of spring which I enjoy with my whole heart. I am alone, and feel the charm of existence in this spot, which was created for the bliss of souls like mine. I am so happy, my dear friend, </p>
//                                 <div className="story-button">
//                                    <Link className="theme-btn" to='/'>Read More</Link>
//                                 </div>
//                             </div>
//                         </div>
//                         <div className="col-lg-6 col-md-12 col-12 pl-n">
//                             <div className="story-img">
//                                 <img src={strory2} alt=""/>
//                             </div>
//                         </div>
//                         <div className="col-lg-6 col-md-12 col-12 pr-n">
//                             <div className="story-img">
//                                 <img src={strory3} alt=""/>
//                             </div>
//                         </div>
//                         <div className="col-lg-6 col-md-12 col-12">
//                             <div className="story-text left-align-text">
//                                 <h3>Our Marriage Proposal</h3>
//                                 <span className="date">Jan 10, 2018</span>
//                                 <p>A wonderful serenity has taken possession of my entire soul, like these sweet mornings of spring which I enjoy with my whole heart. I am alone, and feel the charm of existence in this spot, which was created for the bliss of souls like mine. I am so happy, my dear friend, </p>
//                                 <div className="story-button">
//                                    <Link className="theme-btn" to='/'>Read More</Link>
//                                 </div>
//                             </div>
//                         </div>
//                         <div className="col-lg-6 col-md-12 col-12">
//                             <div className="story-text right-align-text">
//                                 <h3>Our Engagement</h3>
//                                 <span className="date">Jan 22, 2018</span>
//                                 <p>A wonderful serenity has taken possession of my entire soul, like these sweet mornings of spring which I enjoy with my whole heart. I am alone, and feel the charm of existence in this spot, which was created for the bliss of souls like mine. I am so happy, my dear friend, </p>
//                                 <div className="story-button">
//                                    <Link className="theme-btn" to='/'>Read More</Link>
//                                 </div>
//                             </div>
//                         </div>
//                         <div className="col-lg-6 col-md-12 col-12 pl-n">
//                             <div className="story-img">
//                                 <img src={strory4} alt=""/>
//                             </div>
//                         </div> */}
//           </div>
//         </div>
//       </div>
//     </div>
//   );
// };

// export default Story;

import React from "react";
import { Link } from "react-router-dom";
import Sectiontitle from "../section-title";
import "./style.css";

const Story = ({ loveStory }) => {
  return (
    <div id="story" className="story-area section-padding">
      <Sectiontitle section={"Our Love Story"} />
      <div className="container">
        <div className="story-wrap">
          {loveStory &&
            loveStory.map((story, index) => (
              <div className="story-item" key={index}>
                <div className="row align-items-center">
                  {index % 2 === 0 ? (
                    <>
                      <div className="col-lg-6 col-md-12 col-12">
                        <div className="story-img">
                          <div className="img-overlay"></div>
                          <img
                            src={
                              story.image_url || story.imageUrl || story.image
                            }
                            alt={story.title}
                          />
                        </div>
                      </div>
                      <div className="col-lg-6 col-md-12 col-12">
                        <div className="story-text left-align-text">
                          <div className="story-content">
                            <h3>{story.title}</h3>
                            <span className="date">{story.date}</span>
                            <p>{story.description}</p>
                            <div className="story-button">
                              <Link className="theme-btn" to="/">
                                <span>Read More</span>
                                <i className="arrow">→</i>
                              </Link>
                            </div>
                          </div>
                        </div>
                      </div>
                    </>
                  ) : (
                    <>
                      <div className="col-lg-6 col-md-12 col-12 order-lg-2">
                        <div className="story-img">
                          <div className="img-overlay"></div>
                          <img
                            src={
                              story.image_url || story.imageUrl || story.image
                            }
                            alt={story.title}
                          />
                        </div>
                      </div>
                      <div className="col-lg-6 col-md-12 col-12 order-lg-1">
                        <div className="story-text right-align-text">
                          <div className="story-content">
                            <h3>{story.title}</h3>
                            <span className="date">{story.date}</span>
                            <p>{story.description}</p>
                            <div className="story-button">
                              <Link className="theme-btn" to="/">
                                <span>Read More</span>
                                <i className="arrow">→</i>
                              </Link>
                            </div>
                          </div>
                        </div>
                      </div>
                    </>
                  )}
                </div>
              </div>
            ))}
        </div>
      </div>
    </div>
  );
};

export default Story;
