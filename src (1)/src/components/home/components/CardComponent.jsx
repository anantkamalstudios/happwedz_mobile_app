import { Link } from "react-router-dom";

const CardComponent = ({ data }) => {

  return (
    <div
      className="card border-0 shadow-sm rounded-4 overflow-hidden p-2"
      style={{ maxWidth: "400px" }}
    >
      <div>
        <img loading="lazy" decoding="async"
          src="https://images.unsplash.com/photo-1759528278887-71c168973ad1?q=80&w=1076&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
          className="card-img-top w-100"
          alt="Banquet Hall"
          style={{ height: "220px", objectFit: "cover", borderRadius: "5%" }}
        />
      </div>
      <div className="card-body">
        <div className="d-flex justify-content-between align-items-center mb-2">
          <h5 className="card-title mb-0">Name</h5>
          <p className="rating text-warning small mb-0 mt-1">
            ★<span className="text-muted">5.0 (2 Reviews)</span>
          </p>
        </div>
        <p
          className=" mb-3"
          style={{
            color: "black",
            fontSize: "12px",
          }}
        >
          location, state
        </p>

        <div className="d-flex gap-4 mb-3">
          <div>
            <small className="text-muted" style={{ fontSize: "10px" }}>
              Veg
            </small>
            <div className="price">
              ₹ 899 <small className="text-muted">per plate</small>
            </div>
          </div>
          <div>
            <small className="text-muted" style={{ fontSize: "10px" }}>
              Non Veg
            </small>
            <div className="price">
              ₹ 899 <small className="text-muted">per plate</small>
            </div>
          </div>
        </div>

        <div className="d-flex justify-content-between gap-2">
          <div className="d-flex justify-content-center align-items-center gap-2">
            <p
              style={{
                backgroundColor: "#fdc2daff",
                fontSize: "12px",
                padding: "0.25rem 1.25rem",
                color: "#C31162",
              }}
            >
              600 - 1500 pax
            </p>
            <p
              style={{
                backgroundColor: "#fdc2daff",
                fontSize: "12px",
                padding: "0.25rem 1.25rem",
                color: "#C31162",
              }}
            >
              rooms
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CardComponent;
