import { useEffect, useMemo, useState } from "react";
import { Modal } from "react-bootstrap";
import { useLocation, useNavigate, useParams } from "react-router-dom";

const mapHotelFromApi = (hotel) => {
  const images = Array.isArray(hotel.images) ? hotel.images : [];
  const rooms = Array.isArray(hotel.Rooms) ? hotel.Rooms : [];
  const roomImages = rooms.flatMap((room) =>
    Array.isArray(room.RoomImages)
      ? room.RoomImages.map((img) => img.image_url)
      : [],
  );
  const gallerySources = [...images, ...roomImages].filter(Boolean);
  const gallery = [];
  gallerySources.forEach((url) => {
    if (!gallery.includes(url)) {
      gallery.push(url);
    }
  });

  const mainImage = gallery[0] || "";
  const facilities = Array.isArray(hotel.facilities) ? hotel.facilities : [];
  const ratingScore = parseFloat(hotel.review_score || "0") || 0;

  let ratingLabel;
  if (ratingScore >= 4.5) ratingLabel = "Excellent";
  else if (ratingScore >= 4.0) ratingLabel = "Very good";
  else if (ratingScore >= 3.5) ratingLabel = "Good";
  else if (ratingScore > 0) ratingLabel = "Pleasant";
  else ratingLabel = "No reviews";

  const firstRoom = rooms[0];
  const basePrice = firstRoom?.base_price || firstRoom?.total_price;
  const numericPrice = basePrice ? parseFloat(basePrice) : null;
  const priceFrom = numericPrice
    ? `₹ ${numericPrice.toLocaleString("en-IN")}`
    : "Price not available";

  const breakfastInfo =
    firstRoom && firstRoom.breakfast_included ? "Breakfast included" : null;

  const overview = [];
  if (hotel.description) {
    overview.push(hotel.description);
  }
  if (firstRoom?.view_type) {
    overview.push(`Room view: ${firstRoom.view_type}`);
  }
  if (firstRoom?.amenities && firstRoom.amenities.length) {
    overview.push(
      `Room amenities: ${firstRoom.amenities.slice(0, 4).join(", ")}`,
    );
  }
  if (hotel.airport_distance_km) {
    overview.push(`Distance from airport: ${hotel.airport_distance_km} km`);
  }

  const tags = [];
  if (facilities.includes("Private Beach")) {
    tags.push("Beachfront");
  }
  if (facilities.includes("Spa")) {
    tags.push("Spa and wellness");
  }
  if (facilities.includes("Pool")) {
    tags.push("Pool");
  }
  if (tags.length === 0 && facilities.length > 0) {
    tags.push(...facilities.slice(0, 3));
  }

  const propertyHighlights = [];
  if (hotel.city) {
    propertyHighlights.push(`Located in ${hotel.city}`);
  }
  if (hotel.policies && (hotel.policies.checkin || hotel.policies.checkout)) {
    propertyHighlights.push(
      `Check-in: ${hotel.policies.checkin || hotel.check_in_time} · Check-out: ${hotel.policies.checkout || hotel.check_out_time}`,
    );
  }

  const locationParts = [
    hotel.address,
    hotel.city,
    hotel.state,
    hotel.country,
  ].filter(Boolean);

  return {
    id: String(hotel.id),
    name: hotel.name,
    location: locationParts.join(", "),
    rating: ratingScore || 0,
    ratingLabel,
    reviews: hotel.review_count || 0,
    locationScore: undefined,
    priceFrom,
    image: mainImage,
    gallery: gallery.length ? gallery : [mainImage],
    tags,
    shortDescription: hotel.description || "",
    overview,
    breakfastInfo,
    facilities,
    propertyHighlights,
    rooms:
      rooms.length > 0
        ? rooms.map((room) => {
            const roomImages = Array.isArray(room.RoomImages)
              ? room.RoomImages
              : [];
            const mainRoomImage =
              roomImages.find((img) => img.is_main)?.image_url ||
              roomImages[0]?.image_url ||
              mainImage;
            return {
              id: String(room.id),
              name: room.room_name,
              description: room.description,
              sizeSqm: room.room_size_sqm,
              bedType: room.bed_type,
              maxAdults: room.max_adults,
              maxChildren: room.max_children,
              viewType: room.view_type,
              basePrice: room.base_price,
              totalPrice: room.total_price,
              breakfastIncluded: room.breakfast_included,
              dinnerIncluded: room.dinner_included,
              refundable: room.refundable,
              amenities: Array.isArray(room.amenities) ? room.amenities : [],
              image: mainRoomImage,
            };
          })
        : undefined,
  };
};

export default function HoneymoonHotelsPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { hotelId } = useParams();

  const [apiHotels, setApiHotels] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [roomModalOpen, setRoomModalOpen] = useState(false);
  const [activeRoom, setActiveRoom] = useState(null);

  useEffect(() => {
    const stateHotels = Array.isArray(location.state?.hotels)
      ? location.state.hotels
      : [];
    if (stateHotels.length > 0) {
      setApiHotels(stateHotels);
      setLoading(false);
      setError(null);
      return;
    }

    let active = true;
    setLoading(true);
    fetch("https://happywedz.com/api/manage/hotel")
      .then((res) => res.json())
      .then((data) => {
        if (!active) return;
        if (Array.isArray(data)) {
          const mapped = data.map(mapHotelFromApi);
          setApiHotels(mapped);
        } else {
          setApiHotels([]);
        }
      })
      .catch(() => {
        if (!active) return;
        setError("Unable to load honeymoon stays right now.");
      })
      .finally(() => {
        if (!active) return;
        setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [location.state]);

  const hotels = apiHotels;

  const selectedHotel = useMemo(
    () => hotels.find((hotel) => hotel.id === hotelId),
    [hotelId, hotels],
  );

  if (selectedHotel) {
    const safeTags = Array.isArray(selectedHotel.tags) ? selectedHotel.tags : [];
    const safeGallery = Array.isArray(selectedHotel.gallery)
      ? selectedHotel.gallery.filter(Boolean)
      : [];
    const safeFacilities = Array.isArray(selectedHotel.facilities)
      ? selectedHotel.facilities
      : [];
    const safeRooms = Array.isArray(selectedHotel.rooms) ? selectedHotel.rooms : [];

    return (
      <>
        <div className="container py-4 py-md-5">
          <div className="d-flex justify-content-between align-items-center mb-3">
            <button
              type="button"
              className="btn btn-link px-0 fs-14"
              onClick={() => navigate("/honeymoon/hotels")}
            >
              ← Back to all honeymoon stays
            </button>
            <div className="fs-12 text-muted">
              Check-in: {selectedHotel.checkIn || "2:00 PM"} · Check-out:{" "}
              {selectedHotel.checkOut || "12:00 PM"}
            </div>
          </div>

          <div className="row g-4">
            <div className="col-md-7">
              <div className="card border-0 shadow-sm rounded-4 overflow-hidden">
                <div className="row g-0">
                  <div className="col-8">
                    <div
                      style={{
                        height: 260,
                        backgroundImage: `url(${
                          selectedHotel.gallery?.[0] || selectedHotel.image
                        })`,
                        backgroundSize: "cover",
                        backgroundPosition: "center",
                      }}
                    />
                  </div>
                  <div className="col-4 d-none d-md-block">
                    <div
                      style={{
                        height: 130,
                        backgroundImage: `url(${
                          selectedHotel.gallery?.[1] || selectedHotel.image
                        })`,
                        backgroundSize: "cover",
                        backgroundPosition: "center",
                      }}
                    />
                    <div
                      style={{
                        height: 130,
                        backgroundImage: `url(${
                          selectedHotel.gallery?.[2] || selectedHotel.image
                        })`,
                        backgroundSize: "cover",
                        backgroundPosition: "center",
                      }}
                    />
                  </div>
                </div>
                <div className="card-body p-3 p-md-4">
                  <div className="d-flex justify-content-between align-items-start mb-2">
                    <div>
                      <h1 className="h4 mb-1 fs-16">{selectedHotel.name}</h1>
                      <div className="text-muted fs-14">
                        {selectedHotel.location}
                      </div>
                    {selectedHotel.meta?.categoryName && (
                      <div className="fs-13 text-muted mt-1">
                        {selectedHotel.meta.categoryName}
                        {selectedHotel.meta.destinationName
                          ? ` · ${selectedHotel.meta.destinationName}`
                          : ""}
                        {selectedHotel.meta.zoneName ? ` · ${selectedHotel.meta.zoneName}` : ""}
                      </div>
                    )}
                    {(selectedHotel.meta?.latitude || selectedHotel.meta?.longitude) && (
                      <div className="fs-12 text-muted mt-1">
                        Location: {selectedHotel.meta?.latitude ?? "—"},{" "}
                        {selectedHotel.meta?.longitude ?? "—"}
                      </div>
                    )}
                    </div>
                    <div className="text-end">
                      <div className="d-inline-flex flex-column align-items-end">
                        <div className="badge bg-success text-white px-2 py-1 rounded-3 mb-1">
                          <span className="fw-bold me-1">
                          {(Number(selectedHotel.rating) || 0).toFixed(1)}
                          </span>
                          <span className="fs-12">
                            {selectedHotel.ratingLabel}
                          </span>
                        </div>
                        <div className="fs-12 text-muted">
                          {selectedHotel.reviews} reviews
                        </div>
                      </div>
                      {selectedHotel.locationScore && (
                        <div className="mt-2 fs-12 text-muted">
                          Great location ·{" "}
                          {selectedHotel.locationScore.toFixed(1)} rating
                        </div>
                      )}
                    </div>
                  </div>

                  <p className="mb-3 fs-14 text-muted">
                    {selectedHotel.shortDescription}
                  </p>

                  <div className="d-flex flex-wrap gap-2 mb-3">
                    {safeTags.map((tag) => (
                      <span
                        key={tag}
                        className="badge rounded-pill bg-light text-dark border"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>

                  {selectedHotel.overview && (
                    <div className="mt-3">
                      <h2 className="h6 mb-2 fs-14">Overview</h2>
                      <ul className="mb-0 ps-3 fs-14 text-muted">
                        {selectedHotel.overview.map((item) => (
                          <li key={item}>{item}</li>
                        ))}
                      </ul>
                    </div>
                  )}

                  {selectedHotel.raw && (
                    <details className="mt-3">
                      <summary className="fs-14">Raw API payload</summary>
                      <pre className="mt-2 mb-0 fs-12 bg-light border rounded-3 p-2 overflow-auto">
                        {JSON.stringify(selectedHotel.raw, null, 2)}
                      </pre>
                    </details>
                  )}
                </div>
              </div>
            </div>

            <div className="col-md-5">
              <div className="card border-0 shadow-sm rounded-4">
                <div className="card-body p-3 p-md-4">
                  <div className="d-flex justify-content-between align-items-end mb-2">
                    <div>
                      <div className="fs-13 text-muted mb-1">
                        Price for your dates
                      </div>
                      <div className="h4 mb-0 primary-text">
                        {selectedHotel.priceFrom}
                      </div>
                      <div className="fs-12 text-muted">
                        per night · taxes extra
                      </div>
                    </div>
                    <div className="text-end">
                      <div className="badge bg-primary-subtle text-primary rounded-pill mb-1">
                        Honeymoon special
                      </div>
                      <div className="fs-12 text-muted">
                        Free cancellation on select rooms
                      </div>
                      {selectedHotel.breakfastInfo && (
                        <div className="mt-2 fs-13">
                          <strong>Breakfast:</strong>{" "}
                          {selectedHotel.breakfastInfo}
                        </div>
                      )}
                      {selectedHotel.propertyHighlights && (
                        <ul className="mt-3 mb-0 ps-3 fs-12 text-muted">
                          {selectedHotel.propertyHighlights.map((item) => (
                            <li key={item}>{item}</li>
                          ))}
                        </ul>
                      )}
                    </div>
                  </div>
                  <button
                    type="button"
                    className="btn btn-primary w-100 mt-3 rounded-3"
                  >
                    Check availability
                  </button>
                  <div className="fs-12 text-muted mt-2">
                    No booking fees · Instant confirmation
                  </div>
                </div>
              </div>

              {safeFacilities.length > 0 && (
                <div className="card border-0 shadow-sm rounded-4 mt-4">
                  <div className="card-body p-3 p-md-4">
                    <h2 className="h6 mb-3 fs-14">Most popular facilities</h2>
                    <div className="row g-2 fs-14 text-muted">
                      {safeFacilities.map((item) => (
                        <div
                          key={item}
                          className="col-6 d-flex align-items-center"
                        >
                          <span className="me-2">•</span>
                          <span>{item}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {safeRooms.length > 0 && (
                <div className="card border-0 shadow-sm rounded-4 mt-4">
                  <div className="card-body p-3 p-md-4">
                    <h2 className="h6 mb-3 fs-14">Rooms & rates</h2>
                    <div className="d-flex flex-column gap-3">
                      {safeRooms.map((room) => {
                        const firstRate = Array.isArray(room?.rates) ? room.rates[0] : null;
                        const priceValue =
                          room.totalPrice ||
                          room.basePrice ||
                          firstRate?.net ||
                          firstRate?.sellingRate;
                        const numericRoomPrice =
                          priceValue !== undefined && priceValue !== null
                            ? parseFloat(String(priceValue))
                            : null;
                        const formattedRoomPrice =
                          Number.isFinite(numericRoomPrice) && numericRoomPrice !== null
                            ? `₹ ${numericRoomPrice.toLocaleString("en-IN")}`
                            : null;
                        const maxGuests =
                          (room.maxAdults || 0) + (room.maxChildren || 0);
                        return (
                          <div
                            key={room.id}
                            className="d-flex"
                            style={{ minHeight: 80, cursor: "pointer" }}
                            onClick={() => {
                              setActiveRoom(room);
                              setRoomModalOpen(true);
                            }}
                          >
                            <div
                              style={{
                                width: 96,
                                height: 72,
                                borderRadius: 8,
                                backgroundImage: `url(${room.image || selectedHotel.image})`,
                                backgroundSize: "cover",
                                backgroundPosition: "center",
                                marginRight: 12,
                                flexShrink: 0,
                              }}
                            />
                            <div className="flex-grow-1">
                              <div className="d-flex justify-content-between align-items-start mb-1">
                                <div>
                                  <div className="fw-semibold fs-14">
                                    {room.name}
                                  </div>
                                  {room.viewType && (
                                    <div className="fs-12 text-muted">
                                      {room.viewType}
                                    </div>
                                  )}
                                  {firstRate?.boardName && (
                                    <div className="fs-12 text-muted">
                                      {firstRate.boardName}
                                    </div>
                                  )}
                                </div>
                                {formattedRoomPrice && (
                                  <div className="text-end">
                                    <div className="fs-11 text-muted">
                                      Per night
                                    </div>
                                    <div className="fw-bold fs-14">
                                      {formattedRoomPrice}
                                    </div>
                                  </div>
                                )}
                              </div>
                              {room.description && (
                                <div className="fs-12 text-muted mb-1">
                                  {room.description}
                                </div>
                              )}
                              <div className="d-flex flex-wrap gap-2 fs-11 text-muted">
                                {room.bedType && (
                                  <span>Bed: {room.bedType}</span>
                                )}
                                {maxGuests > 0 && (
                                  <span>Max guests: {maxGuests}</span>
                                )}
                                {room.breakfastIncluded && (
                                  <span>Breakfast included</span>
                                )}
                                {room.refundable && (
                                  <span>Free cancellation</span>
                                )}
                                {Array.isArray(room?.rates) && room.rates.length > 1 && (
                                  <span>{room.rates.length} rates</span>
                                )}
                              </div>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>

        {activeRoom && (
          <Modal
            show={roomModalOpen}
            onHide={() => setRoomModalOpen(false)}
            centered
            size="lg"
          >
            <div className="modal-content rounded-4">
              <div className="modal-header border-0 pb-0">
                <div>
                  <h5 className="modal-title fs-16">{activeRoom.name}</h5>
                  {activeRoom.viewType && (
                    <div className="fs-12 text-muted">
                      {activeRoom.viewType}
                    </div>
                  )}
                </div>
                <button
                  type="button"
                  className="btn-close"
                  onClick={() => setRoomModalOpen(false)}
                />
              </div>
              <div className="modal-body pt-2">
                <div className="row g-3">
                  <div className="col-md-5">
                    <div
                      style={{
                        width: "100%",
                        height: 220,
                        borderRadius: 12,
                        backgroundImage: `url(${activeRoom.image || selectedHotel.image})`,
                        backgroundSize: "cover",
                        backgroundPosition: "center",
                      }}
                    />
                  </div>
                  <div className="col-md-7">
                    <div className="d-flex justify-content-between align-items-start mb-2">
                      <div>
                        <div className="fs-13 text-muted mb-1">
                          Price per night
                        </div>
                        <div className="h5 mb-0 primary-text">
                          {(() => {
                            const priceValue =
                              activeRoom.totalPrice ||
                              activeRoom.basePrice ||
                              (Array.isArray(activeRoom?.rates) ? activeRoom.rates[0]?.net : null) ||
                              (Array.isArray(activeRoom?.rates)
                                ? activeRoom.rates[0]?.sellingRate
                                : null);
                            const numeric = priceValue
                              ? parseFloat(String(priceValue))
                              : null;
                            return numeric
                              ? `₹ ${numeric.toLocaleString("en-IN")}`
                              : "Price not available";
                          })()}
                        </div>
                      </div>
                      <div className="text-end fs-12 text-muted">
                        Max {activeRoom.maxAdults || 0} adults
                        {activeRoom.maxChildren
                          ? ` + ${activeRoom.maxChildren} children`
                          : ""}
                      </div>
                    </div>

                    {activeRoom.description && (
                      <div className="fs-13 text-muted mb-2">
                        {activeRoom.description}
                      </div>
                    )}

                    <div className="row g-2 fs-12 text-muted mb-2">
                      {activeRoom.sizeSqm && (
                        <div className="col-6">
                          Size: {activeRoom.sizeSqm} m²
                        </div>
                      )}
                      {activeRoom.bedType && (
                        <div className="col-6">Bed: {activeRoom.bedType}</div>
                      )}
                      {activeRoom.breakfastIncluded && (
                        <div className="col-6">Breakfast included</div>
                      )}
                      {activeRoom.dinnerIncluded && (
                        <div className="col-6">Dinner included</div>
                      )}
                      {activeRoom.refundable && (
                        <div className="col-6">Free cancellation</div>
                      )}
                    </div>

                    {activeRoom.amenities &&
                      activeRoom.amenities.length > 0 && (
                        <div className="mt-2">
                          <div className="fs-12 mb-1">Room amenities</div>
                          <div className="d-flex flex-wrap gap-2">
                            {activeRoom.amenities.map((a) => (
                              <span
                                key={a}
                                className="badge bg-light text-dark border rounded-pill fs-12"
                              >
                                {a}
                              </span>
                            ))}
                          </div>
                        </div>
                      )}

                    {Array.isArray(activeRoom?.rates) && activeRoom.rates.length > 0 && (
                      <div className="mt-3">
                        <div className="fs-12 mb-2">Available rates</div>
                        <div className="d-flex flex-column gap-2">
                          {activeRoom.rates.slice(0, 6).map((rate) => (
                            <div key={rate.rateKey || JSON.stringify(rate)} className="border rounded-3 p-2">
                              <div className="d-flex justify-content-between">
                                <div className="fw-semibold fs-13">
                                  {rate.boardName || rate.boardCode || "Rate"}
                                </div>
                                <div className="fw-bold fs-13">
                                  {rate.net !== null && rate.net !== undefined
                                    ? `${rate.currency || ""} ${rate.net}`
                                    : "—"}
                                </div>
                              </div>
                              <div className="fs-12 text-muted">
                                {rate.paymentType ? `Payment: ${rate.paymentType}` : ""}
                                {rate.rateType ? ` · Type: ${rate.rateType}` : ""}
                              </div>
                              {Array.isArray(rate.cancellationPolicies) &&
                                rate.cancellationPolicies.length > 0 && (
                                  <div className="fs-12 text-muted mt-1">
                                    Cancellation:{" "}
                                    {rate.cancellationPolicies
                                      .map((p) => `${p.from || "—"} (${p.amount ?? "—"} ${p.currency || ""})`)
                                      .slice(0, 2)
                                      .join(" · ")}
                                  </div>
                                )}
                              {Array.isArray(rate.taxes) && rate.taxes.length > 0 && (
                                <div className="fs-12 text-muted mt-1">
                                  Taxes: {rate.taxes.length} item(s)
                                </div>
                              )}
                              {Array.isArray(rate.promotions) &&
                                rate.promotions.length > 0 && (
                                  <div className="fs-12 text-muted mt-1">
                                    Promotions:{" "}
                                    {rate.promotions
                                      .map((p) => p.name || p.code)
                                      .filter(Boolean)
                                      .slice(0, 2)
                                      .join(", ")}
                                  </div>
                                )}
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          </Modal>
        )}
      </>
    );
  }

  return (
    <div className="container py-4 py-md-5">
      <div className="d-flex flex-wrap justify-content-between align-items-end mb-4">
        <div>
          <h1 className="h4 mb-1 fs-16">Romantic honeymoon stays</h1>
          <p className="text-muted fs-14 mb-0">
            Beachfront escapes and romantic getaways, curated from verified
            stays.
          </p>
        </div>
        <div className="fs-13 text-muted">
          Showing <strong>{hotels.length}</strong> handpicked stays
        </div>
      </div>

      <div className="row g-3 g-md-4">
        {!loading && hotels.length === 0 && (
          <div className="col-12">
            <div className="alert alert-light border rounded-3 mb-0">
              No hotels found for the selected filters. Try different dates or
              destination.
            </div>
          </div>
        )}
        {hotels.map((hotel) => (
          <div key={hotel.id} className="col-12">
            <div
              className="card border-0 shadow-sm rounded-4 overflow-hidden"
              style={{ cursor: "pointer" }}
              onClick={() => navigate(`/honeymoon/hotels/${hotel.id}`)}
            >
              <div className="row g-0">
                <div className="col-md-4">
                  <div
                    style={{
                      height: 160,
                      backgroundImage: `url(${hotel.image})`,
                      backgroundSize: "cover",
                      backgroundPosition: "center",
                    }}
                  />
                </div>
                <div className="col-md-8">
                  <div className="card-body p-3 p-md-4">
                    <div className="d-flex justify-content-between align-items-start mb-1">
                      <div>
                        <h2 className="h5 mb-1 fs-16">{hotel.name}</h2>
                        <div className="text-muted fs-14">{hotel.location}</div>
                        {hotel.meta?.categoryName && (
                          <div className="fs-12 text-muted mt-1">
                            {hotel.meta.categoryName}
                            {hotel.meta.destinationName
                              ? ` · ${hotel.meta.destinationName}`
                              : ""}
                          </div>
                        )}
                      </div>
                      <div className="text-end">
                        <div className="d-inline-flex flex-column align-items-end">
                          <div className="badge bg-success text-white px-2 py-1 rounded-3 mb-1">
                            <span className="fw-bold me-1">
                              {(Number(hotel.rating) || 0).toFixed(1)}
                            </span>
                            <span className="fs-12">{hotel.ratingLabel}</span>
                          </div>
                          <span className="fs-12 text-muted">
                            {hotel.reviews} reviews
                          </span>
                        </div>
                      </div>
                    </div>

                    <p className="mb-2 fs-14 text-muted">
                      {hotel.shortDescription}
                    </p>

                    <div className="d-flex flex-wrap gap-2 mb-2">
                      {(Array.isArray(hotel.tags) ? hotel.tags : []).map((tag) => (
                        <span
                          key={tag}
                          className="badge rounded-pill bg-light text-dark border"
                        >
                          {tag}
                        </span>
                      ))}
                    </div>

                    <div className="d-flex justify-content-between align-items-end">
                      <div className="fs-13 text-muted">
                        Perfect for a{" "}
                        <span className="fw-semibold">2-person trip</span>
                      </div>
                      <div className="text-end">
                        <div className="fs-13 text-muted">Starting from</div>
                        <div className="h5 mb-0">{hotel.priceFrom}</div>
                        <div className="fs-12 text-muted">per night</div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
