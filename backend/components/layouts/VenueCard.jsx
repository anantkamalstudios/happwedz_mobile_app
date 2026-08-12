const VenueCard = () => {
  const containerStyle = {
    maxWidth: 450,
    margin: "1rem auto",
  };

  const cardStyle = {
    borderRadius: 12,
    overflow: "hidden",
    boxShadow: "0 10px 30px rgba(0,0,0,0.08)",
    border: "1px solid rgba(0,0,0,0.04)",
    background: "#fff",
  };

  const imgStyle = {
    width: "100%",
    height: 220,
    objectFit: "cover",
    display: "block",
  };

  const titleStyle = {
    fontWeight: 700,
    fontSize: "1.75rem",
    marginBottom: ".25rem",
  };

  const subtitleStyle = {
    fontSize: "1.1rem",
    color: "#111",
    marginBottom: "1rem",
  };

  const tagStyle = {
    background: "#f4cfe0",
    color: "#6b213a",
    padding: "10px 18px",
    display: "inline-block",
    fontSize: "0.67rem",
    border: "none",
  };

  const exploreStyle = {
    background: "linear-gradient(90deg, #c81b68 0%, #b31c53ff 100%)",
    border: "none",
    color: "#fff",
    padding: "14px 24px",
    fontSize: "1.1rem",
    borderRadius: 10,
    boxShadow: "0 6px 18px rgba(200, 27, 104, 0.18)",
    width: "100%",
    fontWeight: 600,
  };

  return (
    <div style={containerStyle}>
      <div style={cardStyle} className="card">
        <img
          src="/Screenshot-2025-10-02-190818.png"
          alt="Venues"
          style={imgStyle}
        />

        <div className="card-body" style={{ padding: "1.5rem" }}>
          <h3 style={titleStyle}>Venues</h3>

          <div style={subtitleStyle}>
            Banquet Halls, Marriage Garden / Lawns
          </div>

          <div className="d-flex flex-wrap align-items-start gap-2">
            <button type="button" style={tagStyle}>
              Banquet Halls
            </button>
            <button type="button" style={tagStyle}>
              Marriage Garden / Lawns
            </button>
            <button type="button" style={tagStyle}>
              Small Function / Party Halls
            </button>
            <button type="button" style={tagStyle}>
              4 Star & Above Wedding Hotels
            </button>
          </div>

          <div className="mt-2 d-flex justify-content-end">
            <a
              href="#"
              style={{
                color: "#d81f6a",
                fontSize: "0.62rem",
              }}
            >
              + 5 more
            </a>
          </div>

          <div className="mt-4">
            <button style={exploreStyle}>Explore Wedding Venues</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VenueCard;
