import React from "react";
import { Container, Row, Col } from "react-bootstrap";

const cityParagraphs = {
  nashik: `Wedding venues in Nashik cluster around three areas. Gangapur Road has the larger banquet halls and hotel ballrooms, mostly ₹800–1,500 per plate. College Road suits mid-size functions of 300–500 guests. Out toward Nashik Road and the vineyards, you'll find lawns and farmhouses that work well for winter weddings, though most don't allow non-veg. Peak season runs November to February and the better venues book six to eight months ahead. Expect ₹15,000–25,000 as the standard booking advance.`,
  mumbai: `Mumbai wedding venues cover a vast range of localities, from South Mumbai heritage hotels to Suburban halls. Western suburbs like Andheri and Juhu are hotspots for elegant banquet halls and beachfront lawns, generally ranging between ₹1,500–3,500 per plate. Central locations like Dadar and Chembur host classic AC banquet halls, whereas Thane and Navi Mumbai offer spacious lawns and resorts for large gatherings of over 1,000 guests at more competitive rates. The city's peak wedding dates see intense demand, requiring bookings 9–12 months in advance.`,
  pune: `In Pune, wedding venues are highly concentrated in areas like Koregaon Park, Kalyani Nagar, and Baner. High-end star hotels in Koregaon Park and Shivajinagar cater to luxury celebrations with plates starting from ₹1,200–2,200. For outdoor lawns and spacious resorts, couples look toward Hinjawadi, Sinhagad Road, and the scenic Lonavala hills. Pune's venues frequently host multiple functions, and outdoor lawn bookings require early reservation, particularly for dates between November and February when Pune's winter climate is ideal.`,
  bangalore: `Bangalore, the garden city, offers a vibrant selection of traditional Kalyana Mandapams and modern open-air wedding lawns. Traditional halls in Jayanagar, Malleshwaram, and Basavanagudi suit classic ceremonies, while ECR-style green lawns and villa resorts in Whitefield, Electronic City, and Kanakapura Road are popular for contemporary celebrations. Per-plate rates range from ₹800 to ₹2,500. Given the city's pleasant year-round weather, outdoor wedding spaces book out fast during the main muhurtham seasons.`,
  jaipur: `Jaipur is world-renowned for its heritage wedding venues, palace hotels, and royal lawns. Key areas like Kukas, Tonk Road, and Mansarovar offer everything from grand forts to modern banquet halls. Kukas and Delhi Highway are famous for massive palace-style resorts suitable for multi-day destination weddings, with rates starting from ₹2,000–5,000 per plate. For budget-friendly local weddings, banquet halls and marriage gardens in Vaishali Nagar and Malviya Nagar are preferred. Peak winter season (November to February) bookings should be finalized at least 8–10 months early.`
};

const VenueInfoSection = ({ city }) => {
  const normalizedCity = String(city || "").trim().toLowerCase();
  const citySpecificText = cityParagraphs[normalizedCity];

  return (
    <section className="venue-info-section py-5">
      <Container>
        {/* Intro */}
        <Row className="mb-4">
          <Col lg={10} className="mx-auto">
            <h4 className="fw-bold mb-4">
              Find the Perfect Wedding Venue {city ? `in ${city}` : "with HappyWedz"}
            </h4>
            
            {citySpecificText && (
              <div className="city-specific-description p-3 mb-4 rounded-3 border-start border-4 border-primary bg-light">
                <p className="fw-medium mb-2 fs-15 text-dark">Local Wedding Insights for {city}:</p>
                <p className="fs-14 m-0 text-muted" style={{ fontStyle: "italic", textJustify: "auto" }}>
                  {citySpecificText}
                </p>
              </div>
            )}

            <p className="fs-14">
              Every bride dreams of saying “I do” in the perfect setting —
              whether it’s a romantic outdoor lawn, a luxurious 5-star banquet,
              a cozy boutique resort, or a breathtaking destination venue. At
              HappyWedz, we help you discover the best wedding venues across
              India, tailored to your style, budget, and guest preferences.
            </p>
            <p className="fs-14">
              Whether you're planning a grand reception in Jaipur, a beachside
              ceremony in Goa, an intimate celebration in your own city, or a
              dreamy destination wedding from Kashmir to Kanyakumari, HappyWedz
              brings you thousands of verified venues to choose from.
            </p>
            <p className="fs-14">
              From poolside mehendi spots to lush green lawns, open-air
              terraces, royal palaces, ballrooms, and elegant banquet halls —
              venue hunting becomes effortless with HappyWedz.
            </p>
          </Col>
        </Row>

        {/* Key Points */}
        <Row className="mb-5">
          <Col lg={10} className="mx-auto">
            <h4 className="fw-semibold mb-3">
              Things to Keep in Mind While Booking Your Wedding Venue
            </h4>
            <ol>
              <li>
                <strong>Budget</strong>
                <br />
                Choose a venue that fits your budget while offering good
                amenities. Compare prices, inclusions, and package details to
                get maximum value.
              </li>
              <li>
                <strong>Location</strong>
                <br />
                For hometown weddings, pick a venue with easy accessibility for
                guests.
                <br />
                For destination weddings, check hotel photos, banquet areas,
                surroundings, and reviews before finalizing.
              </li>
              <li>
                <strong>Services & Facilities</strong>
                <br />
                Look for quality hospitality, catering options, décor support,
                24/7 assistance, valet parking, Wi-Fi, and accommodation if
                required.
              </li>
              <li>
                <strong>Banquet Type & Capacity</strong>
                <br />
                Ensure the venue comfortably fits your guest list and aligns
                with your preferred wedding style — indoor, outdoor, or hybrid.
              </li>
              <li>
                <strong>In-house Vendors</strong>
                <br />
                Many venues include catering, décor, DJs, sound, and support
                staff. This saves time, effort, and often lowers the total cost.
              </li>
              <li>
                <strong>Payment Terms & Policies</strong>
                <br />
                Always check advance payments, cancellation rules, and
                settlement timelines to avoid last-minute issues.
              </li>
            </ol>
            <p className="mt-4">
              A well-selected venue sets the entire mood for your celebration.
              The right venue elevates your wedding, while the wrong choice can
              add stress — so choose wisely with HappyWedz!
            </p>
          </Col>
        </Row>

        {/* More Than Venues */}
        <Row className="mb-5">
          <Col lg={10} className="mx-auto">
            <h4 className="fw-semibold mb-3">
              More Than Just Venues – Your Complete Wedding Marketplace
            </h4>
            <p className="fs-16">
              At HappyWedz, you can plan your entire wedding in one place.
            </p>
            <p>Explore and book:</p>
            <ul className="list-unstyled">
              <li>✔ Wedding photographers</li>
              <li>✔ Bridal makeup artists</li>
              <li>✔ Mehendi artists</li>
              <li>✔ Decorators & floral stylists</li>
              <li>✔ Wedding planners & event managers</li>
              <li>✔ Caterers, DJs, choreographers & more</li>
            </ul>
            <p className="fs-14">
              Browse real photos, view verified reviews, compare prices, and
              contact your shortlisted vendors instantly — all on one trusted
              platform.
            </p>
          </Col>
        </Row>

        {/* App Section */}
        <Row>
          <Col lg={10} className="mx-auto">
            <h4 className="fw-semibold mb-3">
              Plan Anytime, Anywhere with the HappyWedz App
            </h4>
            <p className="fs-14">
              Take complete control of your wedding planning with the HappyWedz
              Wedding Planning App (Android & iOS).
            </p>
            <p className="fs-14">
              Search vendors, shortlist venues, track bookings, compare
              packages, and manage your entire wedding journey on the go.
            </p>
            <p className="fw-bold text-success mt-3 fs-14">
              With HappyWedz, planning your dream wedding has never been this
              simple — or this beautiful.
            </p>
          </Col>
        </Row>
      </Container>

      <style>{`
        .venue-info-section p,
        .venue-info-section li {
          text-align: justify;
          font-size: 1rem;
          line-height: 1.7;
          color: #444;
        }
        .venue-info-section ol {
          padding-left: 1.2rem;
          font-size: 16px;
        }
        .venue-info-section ol li {
          margin-bottom: 1.5rem;
          font-size: 14px;
        }
        .venue-info-section h2 {
          color: #e83581;
          font-size: 2.5rem;
        }
        .venue-info-section h3 {
          color: #e83581;
          font-size: 1.75rem;
          margin-top: 1.5rem;
        }
        .venue-info-section strong {
          color: #333;
          font-weight: 600;
        }
        .list-unstyled li {
          margin-bottom: 0.5rem;
          padding-left: 0.5rem;
          font-size: 14px;
        }
        @media (max-width: 767px) {
          .venue-info-section h2 {
            font-size: 1.8rem;
          }
          .venue-info-section h3 {
            font-size: 1.4rem;
          }
        }
      `}</style>
    </section>
  );
};

export default VenueInfoSection;
