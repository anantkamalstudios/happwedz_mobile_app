import React from "react";

const MainTestimonial = ({ heading, subHeading, mainImage, sections = [] }) => {
  const hasData = Array.isArray(sections) && sections.length > 0;
  const safeHeading = heading || "What Our Couples Say";
  const safeSubHeading =
    subHeading ||
    "Real stories from real couples who made their dream wedding come true";
  return (
    <div className="container my-5 custom-testimonial-section">
      <div className="row">
        <div className="col-md-6 d-flex align-items-center justify-content-center overflow-hidden">
          <div className="custom-testimonial-box text-start shadow p-4 overflow-hidden">
            <div className="p-3">
              <h3 className="custom-heading fw-bold">{safeHeading}</h3>
              <p className="custom-subtext fs-16">{safeSubHeading}</p>
            </div>
            <div className="custom-floral-graphic">
              {/* {mainImage && (
                <img loading="lazy" decoding="async"
                  src={mainImage.replace(/`/g, "").trim()}
                  alt="decor"
                  style={{ maxWidth: 160 }}
                />
              )} */}
            </div>
          </div>
        </div>

        {/* Right Side */}
        <div className="col-md-6 d-flex flex-column gap-5">
          {hasData ? (
            sections.slice(0, 2).map((s, idx) => (
              <div
                key={s.id || idx}
                className="custom-image-card-wrapper position-relative"
              >
                <img
                  src={(s.img || "").replace(/`/g, "").trim()}
                  alt={s.title || "Couple"}
                  className="custom-image real-image"
                />
                <div className="custom-testimonial-card shadow">
                  <div className="fw-semibold fs-16 mb-1 text-black">{s.title || "Happy Couple"}</div>
                  <div className="custom-stars">
                    {"★".repeat(Math.max(1, Math.min(5, s.stars || 5)))}
                  </div>
                  <p className="mb-0 small fs-14">{s.description || ""}</p>
                </div>
              </div>
            ))
          ) : (
            <>
              <div className="custom-image-card-wrapper position-relative">
                <img loading="lazy" decoding="async"
                  src="https://images.unsplash.com/photo-1597427681188-3ef80f2631ff?q=80&w=871&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
                  alt="Bride"
                  className="custom-image real-image"
                />
                <div className="custom-testimonial-card shadow">
                  <h5 className="mb-1">Daniella O’Niel</h5>
                  <div className="custom-stars">★★★★★</div>
                  <p className="mb-0 small">
                    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed
                    dapibus placerat velit. Donec in porttitor elit. Suspendisse
                    accumsan iaculis tincidunt.
                  </p>
                </div>
              </div>
              <div className="custom-image-card-wrapper position-relative">
                <img loading="lazy" decoding="async"
                  src="https://images.unsplash.com/photo-1743685102554-ef8e4eb11415?q=80&w=871&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
                  alt="Bride"
                  className="custom-image real-image"
                />
                <div className="custom-testimonial-card shadow">
                  <h5 className="mb-1">Daniella O’Niel</h5>
                  <div className="custom-stars">★★★★★</div>
                  <p className="mb-0 small">
                    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed
                    dapibus placerat velit. Donec in porttitor elit. Suspendisse
                    accumsan iaculis tincidunt.
                  </p>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default MainTestimonial;
