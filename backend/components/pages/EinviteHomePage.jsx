import React from "react";
import { useNavigate } from "react-router-dom";
import EinviteHeroSection from "../layouts/einvites/EinviteHeroSection";
import ChooseTemplate from "./ChooseTemplate";
import FaqsSection from "../layouts/Main/FaqsSection";
import { useToast } from "../layouts/toasts/Toast";
import { LuSmartphone } from "react-icons/lu";
import { IoSparklesOutline } from "react-icons/io5";

const EinviteHomePage = () => {
  const navigate = useNavigate();
  const { addToast } = useToast();

  const categories = [
    {
      id: "wedding_einvite",
      title: "Wedding E-Invitations",
      description: "Beautiful digital wedding invitation cards",
      color: "#ff6b9d",
      image: "./images/einvite/invite.jpg",
    },
    {
      id: "video",
      title: "Video Invitations",
      description: "Dynamic video invitation templates",
      color: "#6366f1",
      image: "./images/commingsoon.jpg",
    },
    {
      id: "save_the_date",
      title: "Save the Date",
      description: "Save the date card templates",
      color: "#10b981",
      image: "./images/einvite/std.jpg",
    },
  ];

  const handleCategoryClick = (categoryId) => {
    if (categoryId === "video") {
      addToast("Video invitations coming soon!", "info");
      return;
    }

    navigate(`/einvites/category/${categoryId}`);
  };

  return (
    <div className="einvite-home-page">
      <EinviteHeroSection />

      <main className="py-5 bg-light">
        <div className="container">
          <div className="text-center mb-5">
            <h3 className="display-5 fw-bold mb-3">
              Choose Your Invitation Type
            </h3>
            <p className="text-muted fs-18 mt-3">
              Select from our beautiful collection of invitation templates
            </p>
          </div>

          <div className="row g-4">
            {categories.map((category) => (
              <div key={category.id} className="col-lg-4 col-md-6 col-12">
                <div
                  className="main-category-card rounded-3"
                  onClick={() => handleCategoryClick(category.id)}
                >
                  <img
                    src={category.image}
                    alt={category.title}
                    className="category-image rounded-3"
                  />
                  <div className="category-info">
                    <h4 className="category-title">{category.title}</h4>
                    <p className="category-description">
                      {category.description}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </main>

      <ChooseTemplate />

      <section className="py-5 bg-white">
        <div className="container">
          <div className="row justify-content-center">
            <div className="col-lg-12 text-start">
              <h4 className="fw-bold mb-4" style={{ color: "#e83581" }}>
                Create Beautiful E-Invites, E-Cards & Wedding Websites on
                HappyWedz
              </h4>
              <span
                className="mb-4 fs-14"
                style={{ fontSize: "1.1rem", lineHeight: "1.8", color: "#444" }}
              >
                Make your wedding announcement unforgettable with{" "}
                <strong>personalized digital invitations</strong> designed to
                match your style, theme, and story. Whether you want a{" "}
                <strong>
                  classic wedding e-card, a modern digital invitation, or a
                  fully customized wedding website
                </strong>
                , HappyWedz helps you create it in minutes — beautifully,
                effortlessly, and with zero design skills needed.
              </span>
              <h6
                className="mb-4"
                style={{ fontSize: "1.1rem", lineHeight: "1.8", color: "#444" }}
              >
                Choose from <strong>hundreds of templates</strong> for Save the
                Date, Wedding Cards, Reception Cards, Haldi, Mehendi, Sangeet,
                Engagement, Anniversary, and more. Customize everything —
                colours, fonts, music, photos, your love story, location maps,
                RSVP, and family details.
              </h6>
              <h6
                className="mb-4"
                style={{ fontSize: "1.1rem", lineHeight: "1.8", color: "#444" }}
              >
                Share your invite instantly via{" "}
                <strong>WhatsApp, Email, Instagram, or QR Code</strong> —
                simple, elegant, and eco-friendly.
              </h6>
              <h6 className="fw-bold text-success mt-4">
                With HappyWedz E-Invites, your first impression becomes truly
                magical.
              </h6>
            </div>
          </div>

          <div className="row mt-5">
            <div className="col-lg-6 mb-4">
              <h4 className="fw-bold mb-3" style={{ color: "#e83581" }}>
                {/* <IoSparklesOutline /> */}
                Why Choose HappyWedz E-Invites?
              </h4>
              <ul
                className="list-unstyled fs-14"
                style={{ fontSize: "1.1rem", lineHeight: "1.8", color: "#444" }}
              >
                <li>• Easy drag-and-drop editor</li>
                <li>• Stylish & modern templates</li>
                <li>• Add photos, music, & wedding details</li>
                <li>• Instant share options</li>
                <li>• Download in HD</li>
                <li>• Eco-friendly & cost-effective</li>
                <li>
                  • Perfect for destination, traditional, and modern weddings
                </li>
                <li>
                  • Create matching sets (Save the Date + Wedding Card +
                  Itinerary + Website)
                </li>
              </ul>
            </div>
            <div className="col-lg-6 mb-4">
              <h4 className="fw-bold mb-3" style={{ color: "#e83581" }}>
                {/* <LuSmartphone /> */}
                Create Your Own Wedding Website
              </h4>
              <p
                style={{ fontSize: "1.1rem", lineHeight: "1.8", color: "#444" }}
              >
                Tell your love story beautifully with:
              </p>
              <ul
                className="list-unstyled fs-14"
                style={{ fontSize: "1.1rem", lineHeight: "1.8", color: "#444" }}
              >
                <li>✔ Couple story section</li>
                <li>✔ Event timeline</li>
                <li>✔ Venue maps</li>
                <li>✔ RSVP form</li>
                <li>✔ Photo gallery</li>
                <li>✔ Countdown timer</li>
                <li>✔ Guest information & travel details</li>
                <li>✔ Premium themes</li>
                <li>✔ Custom domain options</li>
              </ul>
              <p
                className="mt-3 fs-14"
                style={{ fontSize: "1.1rem", lineHeight: "1.8", color: "#444" }}
              >
                A wedding website makes communication simple and creates a
                memorable digital experience for your guests.
              </p>
            </div>
          </div>

          <div className="row mt-5">
            <div className="col-12">
              <FaqsSection
                customFaqs={[
                  {
                    question: "Can I create my wedding e-invite for free?",
                    answer:
                      "Yes, basic templates may be free. Premium templates may have additional upgrade options for advanced designs.",
                  },
                  {
                    question:
                      "Do I need graphic design skills to make an e-invite?",
                    answer:
                      "Not at all! HappyWedz offers an easy editor where you simply choose a template and customize it in minutes.",
                  },
                  {
                    question:
                      "Can I add music, photos, and custom text to my e-card?",
                    answer:
                      "Yes. You can add background music, photos, videos, couple stories, family names, and all your event details.",
                  },
                  {
                    question:
                      "Can I create invitations for multiple wedding events?",
                    answer:
                      "Absolutely! We support Haldi, Mehendi, Sangeet, Cocktail, Wedding, Reception, Engagement, and more.",
                  },
                  {
                    question: "How do I share my e-invite with guests?",
                    answer:
                      "You can share it instantly via WhatsApp, Email, Instagram, or download it as an image, video, or PDF.",
                  },
                  {
                    question: "Do you offer wedding website templates as well?",
                    answer:
                      "Yes! You can build a full wedding website with photos, event details, RSVP, location maps, and more.",
                  },
                  {
                    question: "Can I customize the colours, fonts, and layout?",
                    answer:
                      "Yes, every element can be personalized to match your wedding theme.",
                  },
                  {
                    question: "Is the wedding website mobile-friendly?",
                    answer:
                      "Yes, all templates are fully responsive and work smoothly on mobiles, tablets, and desktops.",
                  },
                  {
                    question:
                      "Can I edit my invitation or website after publishing?",
                    answer:
                      "Yes! You can update or change details anytime — date, venue, photos, etc.",
                  },
                  {
                    question: "Are the digital wedding cards eco-friendly?",
                    answer:
                      "Yes, e-invites are completely eco-friendly and eliminate the need for printed cards.",
                  },
                  {
                    question: "Can guests RSVP through the website?",
                    answer:
                      "Yes, guests can confirm attendance instantly using the built-in RSVP form.",
                  },
                  {
                    question: "Can I add multiple languages to my invite?",
                    answer:
                      "Yes, many templates support multilingual designs (English, Hindi, Marathi, etc.).",
                  },
                ]}
              />
            </div>
          </div>
        </div>
      </section>

      <style jsx>{`
        .einvite-home-page {
          min-height: 100vh;
        }

        .main-category-card {
          overflow: hidden;
          cursor: pointer;
          transition: all 0.3s ease;
        }

        .main-category-card:hover {
          transform: translateY(-6px);
        }

        .category-image {
          width: 100%;
          height: 450px;
          object-fit: cover;
          transition: transform 0.4s ease;
        }

        .main-category-card:hover .category-image {
          transform: scale(1.01);
        }

        .category-info {
          padding: 1.25rem;
          text-align: center;
        }

        .category-title {
          font-size: 1.5rem;
          font-weight: 700;
          color: #1a1a1a;
          margin-bottom: 0.5rem;
        }

        .category-description {
          font-size: 1rem;
          color: #666;
          margin-bottom: 0;
          line-height: 1.5;
        }

        @media (max-width: 1199px) {
          .category-image {
            height: 380px;
          }
        }

        @media (max-width: 991px) {
          .category-image {
            height: 340px;
          }
          .category-title {
            font-size: 1.375rem;
          }
        }

        @media (max-width: 767px) {
          .category-image {
            height: 300px;
          }
          .category-title {
            font-size: 1.25rem;
          }
          .category-description {
            font-size: 0.95rem;
          }
        }

        @media (max-width: 575px) {
          .category-image {
            height: 260px;
          }
        }
      `}</style>
    </div>
  );
};

export default EinviteHomePage;
