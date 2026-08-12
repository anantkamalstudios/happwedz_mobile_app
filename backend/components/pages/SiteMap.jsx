import React, { useContext } from "react";
import { Link, useNavigate } from "react-router-dom";
import { MyContext } from "../../context/useContext";
import { useDispatch } from "react-redux";
import { setLocation } from "../../redux/locationSlice";

const SiteMap = () => {
  const navigate = useNavigate();
  const dispatch = useDispatch();

  const { setSelectedCategory, setSelectedCategoryName, types } =
    useContext(MyContext);

  const findCategoryIdByName = (categoryName) => {
    if (!types || !Array.isArray(types)) return null;
    const category = types.find(
      (type) => type.name?.toLowerCase() === categoryName.toLowerCase()
    );
    return category ? category.id : null;
  };

  const handlePhotoCategoryClick = (categoryName) => {
    const categoryId = findCategoryIdByName(categoryName);
    if (categoryId) {
      setSelectedCategory(categoryId);
      setSelectedCategoryName(categoryName);
      navigate("/photography");
    }
  };

  const sitemapSections = [
    {
      title: "Main Navigation",
      badge: "Core",
      items: [
        { name: "Home Page", slug: "/" },
        { name: "Wedding Venues", slug: "/wedding-venues" },
        { name: "Wedding Vendors", slug: "/vendors" },
        { name: "Top Rated Vendors", slug: "/top-rated" },
        { name: "Destination Wedding", slug: "/destination-wedding" },
        { name: "Honeymoon & Travel", slug: "/honeymoon" },
        { name: "Wedding Blog", slug: "/blog" },
        { name: "Inspiration Gallery", slug: "/photography" },
      ],
    },
    {
      title: "Wedding Venues by Priority Cities",
      badge: "Venues",
      items: [
        { name: "Wedding Venues in Pune", slug: "/wedding-venues/pune" },
        { name: "Wedding Venues in Nashik", slug: "/wedding-venues/nashik" },
        { name: "Wedding Venues in Mumbai", slug: "/wedding-venues/mumbai" },
        { name: "Wedding Venues in Delhi NCR", slug: "/wedding-venues/delhi-ncr" },
        { name: "Wedding Venues in Bangalore", slug: "/wedding-venues/bangalore" },
        { name: "Wedding Venues in Jaipur", slug: "/wedding-venues/jaipur" },
        { name: "Wedding Venues in Hyderabad", slug: "/wedding-venues/hyderabad" },
        { name: "Wedding Venues in Kolkata", slug: "/wedding-venues/kolkata" },
        { name: "Wedding Venues in Lucknow", slug: "/wedding-venues/lucknow" },
        { name: "Wedding Venues in Chennai", slug: "/wedding-venues/chennai" },
      ],
    },
    {
      title: "Popular Vendor Categories",
      badge: "Vendors",
      items: [
        { name: "Wedding Photographers", slug: "/vendors/photographers/all" },
        { name: "Bridal Makeup Artists", slug: "/vendors/bridal-makeup/all" },
        { name: "Bridal Wear Designers", slug: "/vendors/bridal-wear/all" },
        { name: "Groom Wear", slug: "/vendors/groom-wear/all" },
        { name: "Wedding Decorators", slug: "/vendors/decorators/all" },
        { name: "Wedding Planners", slug: "/vendors/wedding-planners/all" },
        { name: "Catering Services", slug: "/vendors/catering-services/all" },
        { name: "Mehendi Artists", slug: "/vendors/mehendi-artists/all" },
        { name: "Invitation Cards & Gifts", slug: "/vendors/invitations/all" },
        { name: "Jewellery & Accessories", slug: "/vendors/jewellery-accessories/all" },
      ],
    },
    {
      title: "Destination Weddings",
      badge: "Popular Destinations",
      items: [
        { name: "Destination Wedding in Udaipur", slug: "/destination-wedding/udaipur" },
        { name: "Destination Wedding in Goa", slug: "/destination-wedding/goa" },
        { name: "Destination Wedding in Jaipur", slug: "/destination-wedding/jaipur" },
        { name: "Destination Wedding in Kerala", slug: "/destination-wedding/kerala" },
        { name: "Destination Wedding in Mussoorie", slug: "/destination-wedding/mussoorie" },
      ],
    },
    {
      title: "Honeymoon & Booking Services",
      badge: "Travel",
      items: [
        { name: "Honeymoon Packages & Ideas", slug: "/honeymoon" },
        { name: "Flight Bookings", slug: "/honeymoon/flights" },
        { name: "Hotel Bookings", slug: "/honeymoon/hotels" },
        { name: "Cab Rentals", slug: "/honeymoon/cabs" },
        { name: "Travel Insurance", slug: "/honeymoon/insurance" },
        { name: "Hotels Finder", slug: "/hotels" },
      ],
    },
    {
      title: "E-Invites & Design Tools",
      badge: "Digital Services",
      items: [
        { name: "E-Invites & Save the Date Cards", slug: "/einvites" },
        { name: "Video Invitation Templates", slug: "/video-templates" },
        { name: "Virtual Try-On Studio", slug: "/try" },
      ],
    },
    {
      title: "AI Wedding Assistant Tools",
      badge: "AI Powered",
      items: [
        { name: "AI Features Hub", slug: "/ai-features" },
        { name: "Shaadi AI Chatbot", slug: "/shaadi-ai" },
        { name: "Culture Blender", slug: "/culture-blender" },
        { name: "Wedding Personality Quiz", slug: "/personality-quiz" },
        { name: "Wedding Conflict Resolver", slug: "/conflict-resolver" },
        { name: "Wedding Day Timeline Generator", slug: "/timeline-generator" },
      ],
    },
    {
      title: "Matrimonial Services",
      badge: "Matchmaking",
      items: [
        { name: "Matrimonial Hub", slug: "/matrimonial" },
        { name: "Search Profiles", slug: "/matrimonial-search" },
      ],
    },
    {
      title: "Accounts, Company & Legal",
      badge: "Company",
      items: [
        { name: "About HappyWedz", slug: "/about-us" },
        { name: "Contact Us", slug: "/contact-us" },
        { name: "Careers", slug: "/careers" },
        { name: "Claim Your Business", slug: "/claim-your-buisness" },
        { name: "Customer Login", slug: "/customer-login" },
        { name: "Customer Sign Up", slug: "/customer-register" },
        { name: "Vendor Login", slug: "/vendor-login" },
        { name: "Vendor Registration", slug: "/vendor-register" },
        { name: "Terms & Conditions", slug: "/terms" },
        { name: "Privacy Policy", slug: "/privacy" },
        { name: "Cancellation Policy", slug: "/cancellation" },
      ],
    },
  ];

  const topCities = [
    "Pune",
    "Nashik",
    "Mumbai",
    "Delhi NCR",
    "Bangalore",
    "Chennai",
    "Lucknow",
    "Jaipur",
    "Kolkata",
    "Hyderabad",
  ];

  const vendorCategories = [
    { name: "Venues", slug: "/wedding-venues" },
    { name: "Photographers", slug: "/vendors/photographers/all" },
    { name: "Bridal Makeup Artists", slug: "/vendors/bridal-makeup/all" },
    { name: "Bridal Wear", slug: "/vendors/bridal-wear/all" },
    { name: "Groom Wear", slug: "/vendors/groom-wear/all" },
    { name: "Decorators", slug: "/vendors/decorators/all" },
    { name: "Wedding Planners", slug: "/vendors/wedding-planners/all" },
    { name: "Catering Services", slug: "/vendors/catering-services/all" },
    { name: "Mehendi Artists", slug: "/vendors/mehendi-artists/all" },
    { name: "Invitations & Favors", slug: "/vendors/invitations/all" },
    { name: "Jewellery & Accessories", slug: "/vendors/jewellery-accessories/all" },
  ];

  return (
    <div style={{ backgroundColor: "#f8f9fa", padding: "40px 16px", minHeight: "100vh" }}>
      <div style={{ maxWidth: "1240px", margin: "0 auto" }}>
        
        {/* Header Banner */}
        <div
          style={{
            textAlign: "center",
            marginBottom: "36px",
            background: "linear-gradient(135deg, #C31162 0%, #E83581 100%)",
            padding: "36px 20px",
            borderRadius: "16px",
            color: "#fff",
            boxShadow: "0 10px 25px rgba(195, 17, 98, 0.15)",
          }}
        >
          <h1 style={{ fontSize: "2.2rem", fontWeight: "700", marginBottom: "8px" }}>
            HappyWedz Site Map
          </h1>
          <p style={{ fontSize: "1.05rem", opacity: 0.9, maxWidth: "600px", margin: "0 auto" }}>
            Explore all priority sections, vendor categories, destination wedding guides, AI tools, and city services across HappyWedz.
          </p>
        </div>

        {/* Section Cards Grid */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(340px, 1fr))",
            gap: "24px",
            marginBottom: "40px",
          }}
        >
          {sitemapSections.map((section, idx) => (
            <div
              key={idx}
              style={{
                backgroundColor: "#fff",
                borderRadius: "12px",
                padding: "24px",
                border: "1px solid #eaeaea",
                boxShadow: "0 4px 12px rgba(0,0,0,0.03)",
                display: "flex",
                flexDirection: "column",
              }}
            >
              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  marginBottom: "16px",
                  paddingBottom: "12px",
                  borderBottom: "2px solid #f0f0f0",
                }}
              >
                <h2 style={{ fontSize: "1.15rem", fontWeight: "700", color: "#222", margin: 0 }}>
                  {section.title}
                </h2>
                <span
                  style={{
                    backgroundColor: "rgba(195, 17, 98, 0.08)",
                    color: "#C31162",
                    fontSize: "0.75rem",
                    fontWeight: "600",
                    padding: "4px 10px",
                    borderRadius: "12px",
                    textTransform: "uppercase",
                    letterSpacing: "0.5px",
                  }}
                >
                  {section.badge}
                </span>
              </div>

              <ul style={{ listStyle: "none", padding: 0, margin: 0, flexGrow: 1 }}>
                {section.items.map((item, itemIdx) => (
                  <li key={itemIdx} style={{ marginBottom: "10px" }}>
                    <Link
                      to={item.slug}
                      style={{
                        textDecoration: "none",
                        color: "#4a4a4a",
                        fontSize: "0.95rem",
                        display: "inline-flex",
                        alignItems: "center",
                        gap: "8px",
                        transition: "color 0.2s ease, transform 0.2s ease",
                      }}
                      onMouseOver={(e) => {
                        e.currentTarget.style.color = "#C31162";
                        e.currentTarget.style.transform = "translateX(3px)";
                      }}
                      onMouseOut={(e) => {
                        e.currentTarget.style.color = "#4a4a4a";
                        e.currentTarget.style.transform = "translateX(0)";
                      }}
                    >
                      <span style={{ color: "#C31162", fontSize: "0.8rem" }}>▸</span>
                      {item.name}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}

          {/* Dynamic Photo Categories Card */}
          {types && types.length > 0 && (
            <div
              style={{
                backgroundColor: "#fff",
                borderRadius: "12px",
                padding: "24px",
                border: "1px solid #eaeaea",
                boxShadow: "0 4px 12px rgba(0,0,0,0.03)",
                display: "flex",
                flexDirection: "column",
              }}
            >
              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  marginBottom: "16px",
                  paddingBottom: "12px",
                  borderBottom: "2px solid #f0f0f0",
                }}
              >
                <h2 style={{ fontSize: "1.15rem", fontWeight: "700", color: "#222", margin: 0 }}>
                  Photo & Inspiration Categories
                </h2>
                <span
                  style={{
                    backgroundColor: "rgba(195, 17, 98, 0.08)",
                    color: "#C31162",
                    fontSize: "0.75rem",
                    fontWeight: "600",
                    padding: "4px 10px",
                    borderRadius: "12px",
                    textTransform: "uppercase",
                    letterSpacing: "0.5px",
                  }}
                >
                  Gallery
                </span>
              </div>

              <ul style={{ listStyle: "none", padding: 0, margin: 0, flexGrow: 1 }}>
                {types.map((type) => (
                  <li key={type.id} style={{ marginBottom: "10px" }}>
                    <span
                      onClick={() => handlePhotoCategoryClick(type.name)}
                      style={{
                        cursor: "pointer",
                        color: "#4a4a4a",
                        fontSize: "0.95rem",
                        display: "inline-flex",
                        alignItems: "center",
                        gap: "8px",
                        transition: "color 0.2s ease, transform 0.2s ease",
                      }}
                      onMouseOver={(e) => {
                        e.currentTarget.style.color = "#C31162";
                        e.currentTarget.style.transform = "translateX(3px)";
                      }}
                      onMouseOut={(e) => {
                        e.currentTarget.style.color = "#4a4a4a";
                        e.currentTarget.style.transform = "translateX(0)";
                      }}
                    >
                      <span style={{ color: "#C31162", fontSize: "0.8rem" }}>▸</span>
                      {type.description || type.name}
                    </span>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>

        {/* Explore Vendors by City Section */}
        <div
          style={{
            backgroundColor: "#fff",
            borderRadius: "16px",
            padding: "32px 24px",
            border: "1px solid #eaeaea",
            boxShadow: "0 4px 12px rgba(0,0,0,0.03)",
          }}
        >
          <h2
            style={{
              fontSize: "1.35rem",
              fontWeight: "700",
              color: "#C31162",
              marginBottom: "24px",
              textAlign: "center",
            }}
          >
            Explore Vendors & Venues Across Major Cities
          </h2>

          <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
            {topCities.map((city, cIdx) => (
              <div
                key={cIdx}
                style={{
                  paddingBottom: "16px",
                  borderBottom: cIdx !== topCities.length - 1 ? "1px solid #f0f0f0" : "none",
                }}
              >
                <h3
                  style={{
                    fontSize: "1.05rem",
                    fontWeight: "600",
                    color: "#333",
                    marginBottom: "12px",
                    display: "flex",
                    alignItems: "center",
                    gap: "8px",
                  }}
                >
                  <span
                    style={{
                      width: "8px",
                      height: "8px",
                      borderRadius: "50%",
                      backgroundColor: "#C31162",
                      display: "inline-block",
                    }}
                  />
                  {city}
                </h3>

                <div style={{ display: "flex", flexWrap: "wrap", gap: "8px" }}>
                  {vendorCategories.map((cat, catIdx) => (
                    <button
                      key={catIdx}
                      onClick={() => {
                        dispatch(setLocation(city));
                        const formattedCity = city.toLowerCase().replace(/\s+/g, "-");
                        if (cat.slug === "/wedding-venues") {
                          navigate(`/wedding-venues/${formattedCity}`);
                        } else {
                          navigate(cat.slug);
                        }
                      }}
                      style={{
                        backgroundColor: "#fcfcfc",
                        border: "1px solid #e2e2e2",
                        borderRadius: "20px",
                        padding: "6px 14px",
                        fontSize: "0.85rem",
                        color: "#555",
                        cursor: "pointer",
                        transition: "all 0.2s ease",
                        fontWeight: "500",
                      }}
                      onMouseOver={(e) => {
                        e.currentTarget.style.backgroundColor = "#C31162";
                        e.currentTarget.style.color = "#fff";
                        e.currentTarget.style.borderColor = "#C31162";
                      }}
                      onMouseOut={(e) => {
                        e.currentTarget.style.backgroundColor = "#fcfcfc";
                        e.currentTarget.style.color = "#555";
                        e.currentTarget.style.borderColor = "#e2e2e2";
                      }}
                    >
                      {cat.name} in {city}
                    </button>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>

      </div>
    </div>
  );
};

export default SiteMap;
