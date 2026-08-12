// Section 1 — Basic Identity
export const ARTIST_TYPE = ["Individual", "Team / Group", "Studio"];
export const TRAVEL_AVAILABILITY = ["Local Only", "Pan India", "International"];
export const TEAM_SIZE = ["Solo", "2–5 Artists", "5–10 Artists", "10+ Artists"];

// Section 2 — Services Offered
export const SERVICES_OFFERED = [
  "Bridal Mehendi",
  "Guest Mehendi",
  "Engagement Mehendi",
  "Baby Shower Mehendi",
  "Festive Mehendi",
];
export const COVERAGE_TYPE = ["Bridal Only", "Guests Only", "Both"];

// Section 3 — Design Style Intelligence
export const MEHENDI_STYLE = [
  "Traditional",
  "Arabic",
  "Indo-Arabic",
  "Moroccan",
  "Rajasthani",
  "Minimal",
  "Modern",
  "Portrait Mehendi",
];
export const DESIGN_COMPLEXITY = ["Simple", "Moderate", "Intricate", "Highly Detailed"];
export const BEST_KNOWN_FOR = [
  "Intricate Bridal Designs",
  "Fast Guest Application",
  "Unique Concepts",
  "Portrait Mehendi",
  "Minimal Designs",
];
export const PERSONALIZATION_OPTIONS = [
  "Couple Names",
  "Wedding Dates",
  "Story-Based Designs",
  "Portrait Designs",
];

// Section 4 — Bridal Mehendi Details
export const BRIDAL_COVERAGE = ["Hands Only", "Hands + Feet", "Full Arms + Feet"];
export const BRIDAL_DURATION = ["2–4 Hours", "4–6 Hours", "6–8 Hours", "8+ Hours"];

// Section 5 — Guest Handling Capacity
export const GUESTS_PER_HOUR = ["5–10", "10–20", "20–40", "40+"];
export const MAX_GUESTS_COVERED = ["Up to 20", "20–50", "50–100", "100+"];
export const GUEST_PRICING_MODEL = ["Per Hand", "Per Hour", "Package Based"];

// Section 6 — Material & Quality
export const MEHENDI_TYPE = ["Natural Henna", "Organic Henna", "Chemical-Based"];
export const COLOR_GUARANTEE = ["Dark Color Guaranteed", "No Guarantee"];

// Section 7 — Event Suitability
export const FUNCTIONS_COVERED = [
  "Mehendi Ceremony",
  "Engagement",
  "Haldi",
  "Pre-Wedding Events",
];
export const BEST_FOR = [
  "Bridal Mehendi",
  "Large Guest Mehendi",
  "Intimate Functions",
  "Destination Weddings",
];

// Section 8 — Speed & Execution
export const APPLICATION_SPEED = ["Fast", "Moderate", "Detailed (Time Intensive)"];

// Section 9 — Pricing & Travel
export const TRAVEL_CHARGES = ["Included", "Extra", "Depends on Location"];
export const MINIMUM_BOOKING_VALUE = [
  "Below ₹5K",
  "₹5K–₹10K",
  "₹10K–₹20K",
  "₹20K+",
];

// Section 10 — Workflow & Booking
export const ADVANCE_PERCENTAGE = ["25%", "50%", "75%"];
export const BOOKING_TIMELINE = ["1 Week Before", "1 Month Before", "3 Months Before"];
export const CANCELLATION_POLICY = ["Non Refundable", "Partial Refund", "Flexible"];

// Section 12 — AI FAQ dropdowns (reuse existing constants where possible)
export const FAQ_MAX_GUESTS_COVERED = ["Up to 20", "20–50", "50–100", "100+"];
export const FAQ_MEHENDI_TYPE = ["Natural Henna", "Organic Henna", "Chemical-Based"];
export const FAQ_BRIDAL_COVERAGE = ["Hands Only", "Hands + Feet", "Full Arms + Feet"];
export const FAQ_BRIDAL_DURATION = ["2–4 Hours", "4–6 Hours", "6–8 Hours", "8+ Hours"];
export const FAQ_PRICING_MODEL = ["Per Hand", "Per Hour", "Package Based"];
export const FAQ_CANCELLATION_POLICY = ["Non Refundable", "Partial Refund", "Flexible"];

export function emptyMehndiArtistMaster() {
  return {
    identity: {
      artist_brand_name: "",
      artist_type: "",
      years_of_experience: "",
      city: "",
      travel_availability: "",
      team_size: "",
    },
    services: {
      services_offered: [],
      coverage_type: [],
    },
    style_intelligence: {
      mehendi_style: [],
      design_complexity: "",
      best_known_for: [],
      custom_designs_available: "",
      personalization_options: [],
    },
    bridal_details: {
      bridal_coverage: "",
      bridal_duration: "",
      bridal_starting_price: "",
    },
    guest_capacity: {
      guests_per_hour: "",
      max_guests_covered: "",
      guest_pricing_model: "",
      team_support_for_guests: "",
    },
    material_quality: {
      mehendi_type: "",
      color_guarantee: "",
      aftercare_instructions_provided: "",
      allergies_consideration: "",
    },
    event_suitability: {
      functions_covered: [],
      best_for: [],
    },
    speed_execution: {
      application_speed: "",
      parallel_artists_available: "",
      multiple_events_handling: "",
    },
    pricing_travel: {
      travel_charges: "",
      stay_requirement: "",
      minimum_booking_value: "",
    },
    workflow: {
      advance_required: "",
      advance_percentage: "",
      booking_timeline: "",
      cancellation_policy: "",
    },
    portfolio_tagging: {
      tags: "Style, Complexity, Bridal / Guest, Coverage Type, Time Taken",
      notes: "",
    },
    ai_faq: {
      bridal_mehendi_provided: "",
      guest_mehendi_available: "",
      max_guests_covered: "",
      mehendi_type_used: "",
      custom_designs_available: "",
      portrait_mehendi_available: "",
      bridal_coverage_type: "",
      duration_required: "",
      color_guarantee: "",
      aftercare_instructions_provided: "",
      travel_available: "",
      team_available: "",
      pricing_model: "",
      advance_required: "",
      cancellation_policy: "",
    },
  };
}
