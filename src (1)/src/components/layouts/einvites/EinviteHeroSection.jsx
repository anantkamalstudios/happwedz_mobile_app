import React from "react";

const EinviteHeroSection = () => {
  return (
    <section className="einvite-hero-section">
      <div className="einvite-hero-overlay">
        {/* <div className="container">
                    <div className="row align-items-center">
                        <div className="col-lg-8 mx-auto text-center">
                            <h1 className="einvite-hero-title">
                                Beautiful Wedding <br /> E-Invitations
                            </h1>
                        </div>
                    </div>
                </div> */}
      </div>

      {/* Floral decorations */}
      <div className="einvite-floral-decoration top-left">
        <i className="fas fa-seedling"></i>
      </div>
      <div className="einvite-floral-decoration top-right">
        <i className="fas fa-leaf"></i>
      </div>
      <div className="einvite-floral-decoration bottom-left">
        <i className="fas fa-flower"></i>
      </div>
      <div className="einvite-floral-decoration bottom-right">
        <i className="fas fa-seedling"></i>
      </div>
    </section>
  );
};

export default EinviteHeroSection;
