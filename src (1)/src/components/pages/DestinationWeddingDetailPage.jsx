import React from "react";
import { Container, Row, Col, Form, Button } from "react-bootstrap";
import { useParams, useNavigate, Link } from "react-router-dom";
import {
  destinationWeddingData,
  getDestinationBySlug,
} from "../../data/designationWedding";

const DestinationWeddingDetailPage = () => {
  const { name } = useParams();
  const navigate = useNavigate();
  const destination = getDestinationBySlug(name) || destinationWeddingData[0];

  if (!destination) {
    return (
      <Container className="py-5 text-center">
        <h2 className="mb-3">Destination not found</h2>
        <p className="text-muted">
          We couldn’t find details for this location. Please explore our other
          destinations.
        </p>
        <Button
          variant="primary"
          className="mt-3"
          onClick={() => navigate("/destination-wedding")}
        >
          Back to destinations
        </Button>
      </Container>
    );
  }

  const heroImage =
    destination.heroImage || destination.cardImage || destination.url;

  const primaryHighlights = [
    { label: "Best Season", value: destination.bestSeason },
    { label: "Average Cost", value: destination.averageCost },
    {
      label: "Wedding Styles",
      value: (destination.weddingStyles || []).join(", "),
    },
  ];

  return (
    <div>
      <div
        style={{
          backgroundImage: `url('${heroImage}')`,
          backgroundSize: "cover",
          backgroundPosition: "center",
          height: "50vh",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          color: "#fff",
          textAlign: "center",
          position: "relative",
        }}
      >
        <div
          style={{
            backgroundColor: "rgba(0,0,0,0.4)",
            padding: "2rem",
            borderRadius: "10px",
            width: "80%",
          }}
        >
          <h1 style={{ fontWeight: "600", marginBottom: "0.5rem" }}>
            Destination Weddings {destination.title}
          </h1>
          <div
            style={{
              width: "40px",
              height: "2px",
              backgroundColor: "#fff",
              margin: "0.5rem auto",
            }}
          ></div>
        </div>
      </div>

      <Container className="dw-detail-container" style={{ padding: "4rem 0" }}>
        <h4
          style={{
            textAlign: "center",
            fontWeight: "600",
            marginBottom: "1rem",
          }}
        >
          Everything You Need To Know To Organize A Destination Wedding In{" "}
          {destination.title}
        </h4>

        <div
          style={{
            width: "60px",
            height: "2px",
            backgroundColor: "#f6a5c0",
            margin: "0 auto 2rem",
          }}
        ></div>

        <Row>
          <Col md={6}>
            <h5
              style={{
                fontWeight: "600",
                color: "#c31162",
                marginBottom: "1rem",
              }}
            >
              Why {destination.title} works for dream celebrations
            </h5>

            <p
              style={{
                color: "#555",
                lineHeight: "1.7",
                fontSize: "0.95rem",
              }}
            >
              {destination.overview || destination.description}
            </p>

            <div className="d-flex flex-wrap gap-3 my-4">
              {primaryHighlights.map(
                (stat) =>
                  stat.value && (
                    <div
                      key={stat.label}
                      style={{
                        border: "1px solid #f6a5c0",
                        borderRadius: "10px",
                        padding: "12px 18px",
                        minWidth: "160px",
                      }}
                    >
                      <p
                        className="mb-1 text-uppercase"
                        style={{
                          fontSize: "0.75rem",
                          letterSpacing: "1px",
                          color: "#c31162",
                        }}
                      >
                        {stat.label}
                      </p>
                      <p className="mb-0 fw-semibold">{stat.value}</p>
                    </div>
                  )
              )}
            </div>

            <section style={{ marginBottom: "2rem" }}>
              <h6 className="fw-bold text-uppercase text-muted mb-3">
                Signature Experiences
              </h6>
              <div className="d-flex flex-wrap gap-2">
                {(destination.weddingStyles || []).map((style) => (
                  <span
                    key={style}
                    className="badge bg-light text-dark border"
                    style={{ borderColor: "#f3c0d6", padding: "10px 14px" }}
                  >
                    {style}
                  </span>
                ))}
              </div>
            </section>

            {!!destination.topVenues?.length && (
              <section style={{ marginBottom: "2rem" }}>
                <h6 className="fw-bold text-uppercase text-muted mb-3">
                  Top Venues We Love
                </h6>
                <ul style={{ color: "#c31162", fontSize: "0.95rem" }}>
                  {destination.topVenues.map((venue) => (
                    <li key={venue}>{venue}</li>
                  ))}
                </ul>
              </section>
            )}

            {!!destination.travelTips?.length && (
              <section style={{ marginBottom: "2rem" }}>
                <h6 className="fw-bold text-uppercase text-muted mb-3">
                  Planner Tips
                </h6>
                <ul style={{ color: "#555", fontSize: "0.95rem" }}>
                  {destination.travelTips.map((tip) => (
                    <li key={tip}>{tip}</li>
                  ))}
                </ul>
              </section>
            )}

            {!!destination.checklist?.length && (
              <section style={{ marginBottom: "2rem" }}>
                <h6 className="fw-bold text-uppercase text-muted mb-3">
                  Quick Checklist
                </h6>
                <div style={{ display: "flex", flexWrap: "wrap", gap: "10px" }}>
                  {destination.checklist.map((item) => (
                    <span
                      key={item}
                      style={{
                        display: "inline-block",
                        border: "1px dashed #aaa",
                        borderRadius: "6px",
                        padding: "4px 10px",
                        fontSize: "0.85rem",
                      }}
                    >
                      {item}
                    </span>
                  ))}
                </div>
              </section>
            )}

            {!!destination.faqs?.length && (
              <section>
                <h6 className="fw-bold text-uppercase text-muted mb-3">
                  FAQs Couples Ask
                </h6>
                {destination.faqs.map((faq) => (
                  <div key={faq.question} className="mb-3">
                    <p className="mb-1 fw-semibold">{faq.question}</p>
                    <p className="mb-0 text-muted">{faq.answer}</p>
                  </div>
                ))}
              </section>
            )}
          </Col>

          <Col md={6}>
            {destination.snapshotImages?.length >= 4 && (
              <div
                style={{
                  backgroundColor: "#fff",
                  border: "1px solid #ddd",
                  padding: "1.5rem",
                  marginBottom: "1.5rem",
                }}
              >
                <h6 style={{ fontWeight: "600", marginBottom: "1rem" }}>
                  Snapshot
                </h6>
                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "repeat(2, 1fr)",
                    gridTemplateRows: "repeat(2, 200px)",
                    gap: "0.75rem",
                  }}
                >
                  <div
                    style={{
                      gridColumn: "1",
                      gridRow: "1 / 3",
                      overflow: "hidden",
                      borderRadius: "8px",
                    }}
                  >
                    <img
                      src={destination.snapshotImages[0]}
                      alt="Venue snapshot 1"
                      style={{
                        width: "100%",
                        height: "100%",
                        objectFit: "cover",
                      }}
                    />
                  </div>

                  <div
                    style={{
                      gridColumn: "2",
                      gridRow: "1",
                      overflow: "hidden",
                      borderRadius: "8px",
                    }}
                  >
                    <img
                      src={destination.snapshotImages[1]}
                      alt="Venue snapshot 2"
                      style={{
                        width: "100%",
                        height: "100%",
                        objectFit: "cover",
                      }}
                    />
                  </div>

                  <div
                    style={{
                      gridColumn: "2",
                      gridRow: "2",
                      display: "grid",
                      gridTemplateColumns: "repeat(2, 1fr)",
                      gap: "0.75rem",
                    }}
                  >
                    <div
                      style={{
                        overflow: "hidden",
                        borderRadius: "8px",
                      }}
                    >
                      <img
                        src={destination.snapshotImages[2]}
                        alt="Venue snapshot 3"
                        style={{
                          width: "100%",
                          height: "100%",
                          objectFit: "cover",
                        }}
                      />
                    </div>
                    <div
                      style={{
                        overflow: "hidden",
                        borderRadius: "8px",
                      }}
                    >
                      <img
                        src={destination.snapshotImages[3]}
                        alt="Venue snapshot 4"
                        style={{
                          width: "100%",
                          height: "100%",
                          objectFit: "cover",
                        }}
                      />
                    </div>
                  </div>
                </div>
              </div>
            )}
            {destination.highlights?.length > 0 && (
              <div
                style={{
                  backgroundColor: "#fff",
                  border: "1px solid #ddd",
                  padding: "1.5rem",
                }}
              >
                <h6 style={{ fontWeight: "600", marginBottom: "1rem" }}>
                  Quick Facts
                </h6>
                {destination.highlights.map((highlight) => (
                  <div
                    key={highlight.label}
                    className="d-flex justify-content-between align-items-center border-bottom py-2"
                  >
                    <span className="text-muted">{highlight.label}</span>
                    <span className="fw-semibold text-dark text-end">
                      {highlight.value}
                    </span>
                  </div>
                ))}

                <div
                  className="d-flex justify-content-center mt-3"
                  style={{ width: "100%" }}
                >
                  <div style={{ width: "50%" }}>
                    <Link
                      to="contact-us"
                      className="btn btn-outline-primary w-100"
                      style={{ display: "block", margin: "0 auto" }}
                    >
                      Contact US
                    </Link>
                  </div>
                </div>
              </div>
            )}
          </Col>

         
        </Row>
      </Container>
      <style jsx>{`
        @media (max-width: 576px) {
          .dw-detail-container {
            padding: 2rem 1rem !important;
          }
        }
      `}</style>
    </div>
  );
};

export default DestinationWeddingDetailPage;
