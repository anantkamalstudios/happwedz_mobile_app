import React from "react";
import { Link } from "react-router-dom";

const AboutUs = () => {
  return (
    <div>
      <section className="py-3 py-md-5 py-xl-8">
        <div className="container">
          <div className="text-center mb-5">
            <h4 className="display-5 fw-bold primary-text mb-3">
              About HappyWedz
            </h4>
            <p className="fs-14">
              Your Complete Online Wedding Planning Destination HappyWedz is a
              modern, easy-to-use wedding planning platform in India that helps
              couples plan their special day effortlessly. From discovering
              wedding themes, décor ideas, bridal fashion, groom styling, venue
              inspiration, to finding trusted wedding vendors in your city —
              everything you need is right here. Search and compare
              photographers, makeup artists, decorators, caterers, wedding
              venues, mehandi artists, and more based on your budget, style, and
              location. Every vendor listed on HappyWedz is verified to ensure
              reliable and professional service. Whether you’re planning a
              traditional ceremony or a modern destination wedding, HappyWedz
              helps you create a celebration filled with joy, beauty, and
              personal meaning — without stress. Start planning the wedding of
              your dreams with HappyWedz — simple, smart, and beautifully
              organized.
            </p>
          </div>

          <hr className="w-50 mx-auto border-dark-subtle mb-5" />

          {/* Make Planning Decisions */}
          <div className="mb-5">
            <h4 className="fw-bold mb-3 primary-text text-center">
              Make Planning Decisions
            </h4>

            <div className="row gy-4">
              {/* Vendors */}
              <div className="col-md-6">
                <div className="p-4 border rounded shadow-sm bg-white h-100">
                  <p className="fw-bold mb-2 text-dark fs-16">Vendors</p>
                  <p className=" fs-14">
                    Discover thousands of trusted wedding vendors all in one
                    place at HappyWedz! From expert wedding photographers and
                    creative decorators to experienced makeup artists, caterers,
                    and wedding priests, we’ve got every service you need to
                    make your big day perfect.
                  </p>
                </div>
              </div>

              {/* Bridal Gallery / Shop */}
              <div className="col-md-6">
                <div className="p-4 border rounded shadow-sm bg-white h-100">
                  <p className="fw-bold mb-2 fs-16">
                    HappyWedz Bridal Gallery – Find Your Dream Bridal Look
                  </p>
                  <p className="fs-14">
                    Discover your perfect wedding outfit at HappyWedz Bridal Gallery.
                    Explore designer lehengas, sarees, gowns, and fusion styles.
                    Connect directly with designers to customize your dream look.
                    Enjoy a smooth online shopping experience from home.
                    Elegance, style, and the perfect bridal outfit—all in one place.
                  </p>
                </div>
              </div>

              {/* Genie */}
              <div className="col-md-6">
                <div className="p-4 border rounded shadow-sm bg-white h-100">
                  <p className="fw-bold mb-2 fs-16">Shaadi AI</p>
                  <p className="fs-14">
                    Not sure where to begin your wedding planning?
                    Let ShadiAi, your AI-powered wedding planner, make it effortless.
                    It understands your style, budget, and preferences instantly.
                    Get perfect vendor matches in seconds—smart, simple, stress-free
                  </p>
                </div>
              </div>

              {/* Mynt */}
              <div className="col-md-6">
                <div className="p-4 border rounded shadow-sm bg-white h-100">
                  <p className="fw-bold mb-2 text-dark fs-16">HappyWedz Mynt</p>
                  <p className="fs-14">
                    An exclusive loyalty program for brides and grooms-to-be,
                    offering <strong>special offers and rewards</strong> from
                    100+ premium brands in bridal wear, travel, jewellery,
                    beauty, and more!
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Inspiration Section */}
          <div className="my-5">
            <h4 className="fw-bold mb-3 primary-text text-center">
              Still early in your journey? Get inspired with HappyWedz
            </h4>

            <div className="row gy-4">
              {/* Photos */}
              <div className="col-md-6">
                <div className="p-4 border rounded shadow-sm bg-white h-100">
                  <p className="fw-bold mb-2 text-dark fs-16">Photos</p>
                  <p className="fs-14">
                    Dive into a world of stunning wedding inspiration with the
                    HappyWedz Photo Gallery. Discover beautiful ideas for bridal
                    lehengas, groom outfits, wedding décor, pre-wedding shoots,
                    and more — all curated to spark your creativity and help you
                    shape your dream celebration. From timeless traditions to
                    trending styles, explore thousands of real wedding photos
                    shared by couples and professionals across India. Get
                    inspired, save your favorite looks, and bring your wedding
                    vision to life with HappyWedz.
                  </p>
                </div>
              </div>

              {/* Real Weddings */}
              <div className="col-md-6">
                <div className="p-4 border rounded shadow-sm bg-white h-100">
                  <p className="fw-bold mb-2 text-dark fs-16">
                    Real Weddings – Where Love Stories Come to Life 💍
                  </p>
                  <p className="fs-14">
                    Every love story is special, and at HappyWedz, we celebrate
                    them all. Explore real weddings shared by couples from
                    across India — each filled with heartfelt moments, creative
                    themes, stunning décor, and unforgettable celebrations. Get
                    inspired by true wedding stories, browse beautiful photos,
                    and discover fresh ideas for your own big day. From intimate
                    ceremonies to grand destination weddings, find endless
                    inspiration and real experiences only on HappyWedz.
                  </p>
                </div>
              </div>

              {/* Blog */}
              <div className="col-md-12">
                <div className="p-4 border rounded shadow-sm bg-white h-100">
                  <p className="fw-bold mb-2 text-dark fs-16">
                    HappyWedz Blog – Your Ultimate Wedding Inspiration Hub ✨
                  </p>
                  <p className="fs-14">
                    Step into the HappyWedz Blog, your go-to space for
                    everything wedding! Discover the latest bridal fashion
                    trends, decor inspirations, planning tips, and creative
                    ideas to make your celebration truly one of a kind. Whether
                    you’re exploring timeless traditions or modern wedding
                    styles, our blog brings you expert advice, trend updates,
                    and real stories to help you plan with confidence. Stay
                    inspired and plan smarter with the HappyWedz Blog — your
                    trusted guide to all things wedding!
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Additional Features */}
          <div className="my-5">
            <h4 className="fw-bold mb-3 primary-text text-center">
              Our Exclusive Features
            </h4>

            <div className="row gy-4">
              {/* Design Studio */}
              <div className="col-md-6">
                <div className="p-4 border rounded shadow-sm bg-white h-100">
                  <p className="fw-bold mb-2 text-dark fs-16">
                    Design Studio
                  </p>
                  <p className="fs-14">
      Personalize your wedding look with our smart Design Studio.
Apply creative filters, edit styles, and see changes in real time.
Try on makeup, jewellery, and outfits virtually with stunning accuracy.
Create your perfect bridal look effortlessly.
                  </p>
                </div>
              </div>

              {/* Mobile Apps */}
              <div className="col-md-6">
                <div className="p-4 border rounded shadow-sm bg-white h-100">
                  <p className="fw-bold mb-2 text-dark fs-16">
                    Available on Android & iOS
                  </p>
                  <p className="fs-14">
                    Download the <strong>HappyWedz app</strong> from Google Play
                    or the Apple App Store for a seamless planning experience.
                    Plan, manage, and track your wedding anytime, anywhere!
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Final Section */}
          <div className="text-center mt-5">
            <h4 className="fw-bold mb-3 primary-text">
              Celebrating Responsibly with HappyWedz 🌿
            </h4>
            <p className="mb-4 fs-14">
              At HappyWedz, we believe every celebration can make a positive
              impact. Beyond creating unforgettable weddings, we are committed
              to environmental sustainability, social welfare, and community
              empowerment. From promoting eco-friendly wedding solutions to
              supporting local artisans and small vendors, our initiatives
              ensure that your special day is not only beautiful but also
              responsible. Celebrate love while making a meaningful
              difference with HappyWedz.
            </p>
          </div>
        </div>
        <div className="container">
          <div className="row gy-4 gy-lg-0 align-items-lg-center">
            <div className="col-12 col-lg-6">
              <img
                className="img-fluid rounded border border-dark"
                loading="lazy"
                src="./images/categories/venues.jpg"
                alt="About Us"
              />
            </div>
            <div className="col-12 col-lg-6 col-xxl-6">
              <div className="row justify-content-lg-end">
                <div className="col-12 col-lg-11">
                  <div className="about-wrapper">
                    <p className="fs-14 mb-4 mb-md-5">
                      At HappyWedz, we believe that celebrations should also
                      create a positive impact. Beyond weddings, we are
                      committed to supporting the communities we serve through
                      meaningful initiatives in environmental sustainability,
                      social welfare, and empowerment. From promoting
                      eco-friendly wedding solutions to collaborating with local
                      artisans and small vendors, our goal is to make every
                      celebration beautiful — and responsible.
                    </p>
                    <div className="row gy-4 mb-4 mb-md-5">
                      <div className="col-12 col-md-6">
                        <div className="card border border-dark">
                          <div className="card-body p-4">
                            <h3 className="display-5 fw-bold primary-text text-center mb-2 fs-20">
                              370+
                            </h3>
                            <p className="fw-bold text-center m-0 fs-14">
                              Qualified Experts
                            </p>
                          </div>
                        </div>
                      </div>
                      <div className="col-12 col-md-6">
                        <div className="card border border-dark">
                          <div className="card-body p-4">
                            <h3 className="display-5 fw-bold primary-text text-center mb-2 fs-20">
                              18k+
                            </h3>
                            <p className="fw-bold text-center m-0 fs-14">
                              Satisfied Clients
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>
                    {/* <Link to="/" className="btn btn-primary bsb-btn-2xl">
                                            Explore
                                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" className="bi bi-arrow-right-short" viewBox="0 0 16 16">
                                                <path fill-rule="evenodd" d="M4 8a.5.5 0 0 1 .5-.5h5.793L8.146 5.354a.5.5 0 1 1 .708-.708l3 3a.5.5 0 0 1 0 .708l-3 3a.5.5 0 0 1-.708-.708L10.293 8.5H4.5A.5.5 0 0 1 4 8" />
                                            </svg>
                                        </Link> */}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default AboutUs;
