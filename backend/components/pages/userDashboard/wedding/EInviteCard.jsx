import { Link } from "react-router-dom";

const EInviteCard = () => {
  return (
    <div
      style={{
        overflow: "hidden",
        maxWidth: "100%",
      }}
    >
      {/* Image */}
      <div style={{ width: "100%", height: "350px", overflow: "hidden" }}>
        <img
          src="/images/userDashboard/eInvite-img.jpg"
          alt="E-Invite"
          style={{
            width: "100%",
            height: "100%",
            objectFit: "cover",
          }}
        />
      </div>

      {/* Content */}
      <div className=" text-center p-4">
        <h3
          className="fw-bold mb-2"
          style={{
            color: "#C31162",
            letterSpacing: "1px",
          }}
        >
          E-INVITES
        </h3>
        <p
          className="fw-bold mb-3 fs-16 px-2"
          style={{
            color: "#C31162",
            fontSize: "1.1rem",
          }}
        >
          Create Stunning Digital Wedding Invitations That Wow
        </p>
        <p
          className="text-muted mb-4 mt-4 fs-14"
          style={{
            fontSize: "0.9rem",
            lineHeight: "1.5",
          }}
        >
          Discover curated options that fit your style, budget, and location.
          Search and compare instantly.
        </p>

        <Link to="/einvites">
          <button
            className="btn mt-4 rounded-3 fs-14"
            style={{
              backgroundColor: "#C31162",
              color: "#fff",
              padding: "10px 30px",
            }}
          >
            Get started
          </button>
        </Link>
      </div>
    </div>
  );
};

export default EInviteCard;
