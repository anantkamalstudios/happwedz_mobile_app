import React, { useState } from "react";
import { FaRegHandPointRight } from "react-icons/fa6";
import "./event-creation-tabs.css";
const EventCreationTabs = () => {
  const [activeTab, setActiveTab] = useState(0);

  // Mock data for all tabs
  const tabsData = [
    {
      id: 1,
      number: "1",
      title: "Create Event",
      subtitle: "Create & Setup Event",
      content: {
        heading: "Event Creation Made Easy",
        subheading:
          "Host any event on Samaro and manage everything in one place.",
        points: [
          "Set up your main event",
          "Organize sub-events and schedules",
          "Invite co-hosts and assign admin access",
        ],
        buttonText: "Try Now",
        image:
          "https://images.unsplash.com/photo-1511578314322-379afb476865?w=600&h=700&fit=crop",
      },
    },
    {
      id: 2,
      number: "2",
      title: "Share Event",
      subtitle: "Share Event & Add Guests",
      content: {
        heading: "Share Your Special Day",
        subheading:
          "Easily share your event with friends and family in just a few clicks.",
        points: [
          "Generate unique event links",
          "Send invitations via email or social media",
          "Track RSVPs and guest confirmations",
        ],
        buttonText: "Share Now",
        image:
          "https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=600&h=700&fit=crop",
      },
    },
    {
      id: 3,
      number: "3",
      title: "Media Uploads",
      subtitle: "Collect Media from Guest",
      content: {
        heading: "Capture Every Memory",
        subheading:
          "Let your guests contribute their photos and videos to your event album.",
        points: [
          "Enable guest photo uploads",
          "Automatic organization by date and time",
          "Download all media in one click",
        ],
        buttonText: "Start Collecting",
        image:
          "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=600&h=700&fit=crop",
      },
    },
    {
      id: 4,
      number: "4",
      title: "Upload Selfie",
      subtitle: "Guests upload selfie to see their photos",
      content: {
        heading: "AI-Powered Photo Recognition",
        subheading:
          "Guests upload a selfie and instantly see all their photos from the event.",
        points: [
          "Facial recognition technology",
          "Instant photo matching",
          "Private and secure photo delivery",
        ],
        buttonText: "Try Feature",
        image:
          "https://images.unsplash.com/photo-1519741497674-611481863552?w=600&h=700&fit=crop",
      },
    },
  ];

  return (
    <section className="event_creation_section_9k2m7">
      <div className="container px-3 px-md-4 px-lg-5">
        <div className="row mb-4 mb-md-5">
          <div className="col-12">
            <h2 className="main_section_title_4n8x3">
              Instant photos, powered by AI
            </h2>
          </div>
        </div>

        <div className="row">
          {/* Left Side - Tabs Navigation */}
          <div className="col-lg-4 col-xl-3 mb-4 mb-lg-0">
            <div className="tabs_navigation_5j7k2">
              {tabsData.map((tab, index) => (
                <div key={tab.id}>
                  <div
                    className={`tab_item_3m9w8 ${activeTab === index ? "active_tab_6p2k4" : ""}`}
                    onClick={() => setActiveTab(index)}
                  >
                    <div className="tab_number_circle_8k3n1">{tab.number}</div>
                    <div className="tab_text_content_2w7j5">
                      <h6 className="tab_title_9m2k6">{tab.title}</h6>
                      <p className="tab_subtitle_7n4p8">{tab.subtitle}</p>
                    </div>
                  </div>
                  {index < tabsData.length - 1 && (
                    <div
                      className={`tab_connector_line_4k8m3 ${activeTab > index ? "active_line_5p9w2" : ""}`}
                    ></div>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Right Side - Tab Content */}
          <div className="col-lg-8 col-xl-9">
            <div className="tab_content_wrapper_6n2k9">
              <div className="content_inner_box_8j4m7">
                <div className="row align-items-start">
                  {/* Content Text */}
                  <div className="col-md-7 mb-4 mb-md-0">
                    <div className="content_text_section_3k7p2">
                      <h3 className="content_heading_5m8w4">
                        {tabsData[activeTab].content.heading}
                      </h3>
                      <p className="content_subheading_9j2n6">
                        {tabsData[activeTab].content.subheading}
                      </p>
                      <ul className="content_points_list_7k4m9">
                        {tabsData[activeTab].content.points.map(
                          (point, index) => (
                            <li key={index} className="point_item_2n8k5">
                              <FaRegHandPointRight size={20} />
                              <span>{point}</span>
                            </li>
                          ),
                        )}
                      </ul>
                      <button className="cta_button_4k9m2">
                        {tabsData[activeTab].content.buttonText}
                      </button>
                    </div>
                  </div>

                  {/* Content Image */}
                  <div className="col-md-5">
                    <div className="content_image_wrapper_8n5k3">
                      <img
                        src={tabsData[activeTab].content.image}
                        alt={tabsData[activeTab].title}
                        className="content_image_7j2m9"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default EventCreationTabs;
