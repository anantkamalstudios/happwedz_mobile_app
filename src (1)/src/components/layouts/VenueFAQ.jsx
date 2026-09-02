import React from "react";
import { Accordion } from "react-bootstrap";
import { Helmet } from "react-helmet-async";

export default function VenueFAQ({ venueData, activeVendor }) {
  if (!venueData) return null;

  const venueName =
    activeVendor?.name ||
    venueData.attributes?.name ||
    venueData.attributes?.vendor_name ||
    "this venue";
  const venueCity = activeVendor?.location || venueData.attributes?.city || "";

  const attrs = venueData.attributes || {};
  const vm = attrs.venue_master || {};
  const vFood = vm.food || {};
  const vSpace = vm.space_capacity || {};
  const vEnt = vm.entertainment || {};
  const vRooms = vm.rooms || {};
  const vFac = vm.facilities || {};
  const vPricing = vm.pricing_booking || {};

  const faqs = [];

  // 1. Price per plate / Starting price
  const vegStartingPrice =
    attrs.veg_starting_price || vFood.per_plate_cost_range;
  const generalStartingPrice =
    attrs.starting_price || vPricing.starting_venue_price;
  if (vegStartingPrice || generalStartingPrice) {
    const priceText = vegStartingPrice
      ? `₹${vegStartingPrice} per plate for vegetarian menus`
      : `starting price of ₹${generalStartingPrice}`;
    faqs.push({
      q: `What is the price per plate at ${venueName}?`,
      a: `${venueName}${venueCity ? ` in ${venueCity}` : ""} starts at ${priceText}.`,
    });
  }

  // 2. Guest capacity
  const seatingCap = vSpace.indoor_seating || attrs.area;
  const maxGuests = vSpace.max_guests;
  if (seatingCap || maxGuests) {
    let capText = "";
    if (seatingCap && maxGuests) {
      capText = `accommodate seating for ${seatingCap} and up to ${maxGuests} total guests`;
    } else if (seatingCap) {
      capText = `accommodate ${seatingCap}`;
    } else {
      capText = `accommodate up to ${maxGuests} guests`;
    }
    faqs.push({
      q: `How many guests can ${venueName} accommodate?`,
      a: `${venueName} can ${capText}.`,
    });
  }

  // 3. Non-veg food policy
  const vegNonVeg = vFood.veg_non_veg || attrs.veg_non_veg;
  if (vegNonVeg) {
    const isPureVeg =
      vegNonVeg.toLowerCase().includes("pure veg") ||
      vegNonVeg.toLowerCase() === "veg";
    faqs.push({
      q: `Is non-veg food allowed at ${venueName}?`,
      a: isPureVeg
        ? `No, ${venueName} is a pure vegetarian venue.`
        : `Yes, non-vegetarian food options are available at ${venueName} (${vegNonVeg}).`,
    });
  }

  // 4. Outside catering policy
  const cateringPolicy = vFood.catering_policy || attrs.catering_policy;
  if (cateringPolicy) {
    faqs.push({
      q: `Is outside catering allowed at ${venueName}?`,
      a: `Catering policy at ${venueName}: ${cateringPolicy}.`,
    });
  }

  // 5. Outside DJ policy
  const djPolicy = vEnt.dj_policy || attrs.dJ_policy || attrs.dj_policy;
  if (djPolicy) {
    faqs.push({
      q: `Is outside DJ allowed at ${venueName}?`,
      a: `DJ policy at ${venueName}: ${djPolicy}.`,
    });
  }

  // 6. Rooms available
  const roomCount = vRooms.num_rooms || attrs.rooms;
  if (roomCount && roomCount !== "0" && roomCount !== 0) {
    faqs.push({
      q: `Are rooms available at ${venueName}?`,
      a: `Yes, ${venueName} offers ${roomCount} rooms for guests and bridal party stay.`,
    });
  }

  // 7. Parking available
  const parkingInfo = vFac.parking || attrs.parking;
  const parkingCap = vFac.parking_capacity;
  if (parkingInfo || parkingCap) {
    const parkDetails = parkingCap
      ? `${parkingInfo || "Available"} (Capacity: ${parkingCap} vehicles)`
      : parkingInfo;
    faqs.push({
      q: `Is parking available at ${venueName}?`,
      a: `Parking at ${venueName}: ${parkDetails}.`,
    });
  }

  // 8. Time slots
  const slots = attrs.slots || vPricing.min_booking_duration;
  if (slots) {
    faqs.push({
      q: `What are the available time slots at ${venueName}?`,
      a: `Available booking slots/duration at ${venueName}: ${Array.isArray(slots) ? slots.join(", ") : slots}.`,
    });
  }

  // 9. Booking advance amount
  const advance = vPricing.advance_payment_range || attrs.advance_booking;
  if (advance) {
    faqs.push({
      q: `How much is the booking advance at ${venueName}?`,
      a: `The advance payment required for booking ${venueName} is ${advance}.`,
    });
  }

  // Require at least 2 questions to avoid rendering a thin or lonely 1-question FAQ block
  if (faqs.length < 2) return null;

  // Schema.org FAQPage JSON-LD payload
  const schemaPayload = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: faqs.map((faq) => ({
      "@type": "Question",
      name: faq.q,
      acceptedAnswer: {
        "@type": "Answer",
        text: faq.a,
      },
    })),
  };

  return (
    <div
      className="venue-faq-section my-4 p-4 bg-white rounded shadow-sm"
      id="venue-faq"
    >
      {import.meta.env.VITE_ENABLE_SEO === "true" && (
        <Helmet>
          <script type="application/ld+json">
            {JSON.stringify(schemaPayload)}
          </script>
        </Helmet>
      )}

      <h4
        className="mb-3 font-weight-bold"
        style={{ fontSize: "1.4rem", color: "#333" }}
      >
        Frequently Asked Questions about {venueName}
      </h4>

      <Accordion defaultActiveKey="0" flush>
        {faqs.map((faq, idx) => (
          <Accordion.Item eventKey={String(idx)} key={idx}>
            <Accordion.Header>
              <strong>{faq.q}</strong>
            </Accordion.Header>
            <Accordion.Body style={{ color: "#555", lineHeight: "1.6" }}>
              {faq.a}
            </Accordion.Body>
          </Accordion.Item>
        ))}
      </Accordion>
    </div>
  );
}
