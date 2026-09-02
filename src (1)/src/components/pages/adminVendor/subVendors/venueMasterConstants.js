/**
 * Venue master profile — static option lists (aligned with product spec).
 * Persisted under service attributes as `venue_master` (JSON object).
 *
 * Location fields (edited on Location tab, synced into `identity`):
 * - exact_location_text — Exact location (text)
 * - map_pin_url — Google Map link / pin URL
 */

/** Section 11 (image intelligence) hidden in vendor UI until per-image tagging ships. */
export const SHOW_VENUE_IMAGE_INTELLIGENCE = false;

export const VENUE_CATEGORY_GROUPS = [
  {
    key: "premium",
    title: "Premium & experience-based",
    options: [
      "Palace Wedding Venue",
      "Heritage Property",
      "Fort / Haveli Venue",
      "Luxury Resort Venue",
      "Island / Private Property Venue",
      "Vineyard / Winery Venue",
      "Golf Course Venue",
    ],
  },
  {
    key: "locationBased",
    title: "Location-based",
    options: [
      "Beach Wedding Venue",
      "Mountain / Hilltop Venue",
      "Lake View Venue",
      "Riverside Venue",
      "Forest / Nature Venue",
      "Highway Venue",
      "City Center Venue",
      "Suburban Venue",
    ],
  },
  {
    key: "capacityBased",
    title: "Capacity-based",
    options: [
      "Intimate Wedding Venues (0-100)",
      "Mid-Size Wedding Venues (100-300)",
      "Large Wedding Venues (300-500)",
      "Mega Wedding Venues (500-1000)",
      "Ultra Large Wedding Venues (1000+)",
    ],
  },
  {
    key: "budgetBased",
    title: "Budget-based",
    options: [
      "Budget Wedding Venues",
      "Mid-Range Wedding Venues",
      "Premium Wedding Venues",
      "Luxury Wedding Venues",
    ],
  },
  {
    key: "functionSpecific",
    title: "Function-specific",
    options: [
      "Haldi Venues",
      "Mehendi Venues",
      "Sangeet Venues",
      "Engagement Venues",
      "Reception Venues",
      "Cocktail Party Venues",
      "Corporate Event Venues",
      "Birthday / Private Party Venues",
    ],
  },
  {
    key: "facilityBased",
    title: "Facility-based",
    options: [
      "Venues with Rooms",
      "Venues with Large Parking",
      "Venues with Poolside Setup",
      "Venues with In-house Catering",
      "Pure Veg Venues",
      "Venues Allowing Alcohol",
      "Venues with Outdoor Space",
      "Venues with Indoor + Outdoor Combo",
    ],
  },
  {
    key: "bookingFlex",
    title: "Booking & usage flexibility",
    options: [
      "One-Day Wedding Venues",
      "Multi-Day Wedding Venues",
      "Exclusive Property Booking Venues",
      "Shared Venue Spaces",
    ],
  },
  {
    key: "trendModern",
    title: "Trend & modern formats",
    options: [
      "Pre-Wedding Shoot Venues",
      "Instagrammable Venues",
      "Minimalist Wedding Venues",
      "Theme Wedding Venues",
      "Eco-Friendly / Sustainable Venues",
      "Glamping / Tent Wedding Venues",
    ],
  },
];

export const PROPERTY_OWNERSHIP_TYPES = [
  "Owned",
  "Leased",
  "Managed Property",
  "Franchise",
  "Other",
];

export const LOCATION_TYPES = [
  "Central City",
  "Suburban",
  "Highway",
  "Remote / Destination",
  "Other",
];

export const CHAIN_BRAND_CATEGORIES = [
  "Luxury",
  "Premium",
  "Mid-Range",
  "Budget",
  "Other",
];

export const SPACE_TYPES = [
  "Indoor",
  "Outdoor",
  "Poolside",
  "Terrace",
  "Garden",
  "Ballroom",
  "Rooftop",
  "Waterfront",
  "Amphitheatre",
  "Courtyard",
  "Other",
];

export const INDOOR_OUTDOOR_HYBRID = ["Indoor", "Outdoor", "Hybrid"];

export const ROOM_TYPE_OPTIONS = [
  "Deluxe",
  "Executive",
  "Suite",
  "Junior Suite",
  "Presidential Suite",
  "Villa",
  "Cottage",
  "Dormitory",
  "Family Room",
  "Tent / Glamping",
  "Other",
];

export const ROOM_PRICE_RANGE = [
  "Below Rs.3000",
  "Rs.3000-Rs.5000",
  "Rs.5000-Rs.8000",
  "Rs.8000-Rs.12000",
  "Rs.12000+",
  "Other",
];

export const CATERING_POLICY = [
  "In-house Only",
  "Outside Allowed",
  "Both",
  "Other",
];

export const CUISINE_OPTIONS = [
  "North Indian",
  "South Indian",
  "Jain",
  "Gujarati",
  "Rajasthani",
  "Continental",
  "Chinese",
  "Italian",
  "Mexican",
  "Thai",
  "Mediterranean",
  "Vegan",
  "Live Counters",
  "Fusion",
  "Other",
];

export const VEG_NON_VEG = ["Pure Veg", "Veg + Non-Veg", "Other"];

export const PER_PLATE_COST_RANGE = [
  "Below Rs.500",
  "Rs.500-Rs.1000",
  "Rs.1000-Rs.1500",
  "Rs.1500-Rs.2500",
  "Rs.2500-Rs.4000",
  "Rs.4000+",
  "Other",
];

export const OUTSIDE_CATERING_CHARGES = [
  "Free",
  "Rs.0-Rs.25K",
  "Rs.25K-Rs.50K",
  "Rs.50K+",
  "Not Allowed",
  "Other",
];

export const ALCOHOL_POLICY = [
  "Not Allowed",
  "Allowed with License",
  "In-house Only",
  "Outside Allowed",
  "Both",
  "Other",
];

export const CORKAGE_CHARGES = [
  "No",
  "Rs.0-Rs.10K",
  "Rs.10K-Rs.25K",
  "Rs.25K+",
  "Add from Vendor",
  "Other",
];

export const BAR_SETUP = [
  "Not Available",
  "Basic",
  "Premium",
  "Custom",
  "Add from Vendor",
  "Other",
];

export const DECOR_POLICY = [
  "In-house Only",
  "Panel Only",
  "Outside Allowed",
  "Both",
  "Other",
];

export const DECOR_CAPABILITIES = [
  "Floral Decor",
  "Theme Decor",
  "Luxury Installations",
  "LED Walls",
  "Entry Concepts",
  "Stage Concepts",
  "Mandap Design",
  "Other",
];

export const TIERED_SETUP = [
  "Not Available",
  "Basic",
  "Premium",
  "Custom",
  "Add from Vendor",
  "Other",
];

export const LIGHTING_SETUP = [
  "Basic",
  "Advanced",
  "Premium",
  "Custom",
  "Add from Vendor",
  "Other",
];

export const SOUND_SYSTEM = [
  "Not Available",
  "Basic",
  "Professional",
  "Add from Vendor",
  "Other",
];

export const OUTSIDE_DECOR_CHARGES = [
  "Free",
  "Rs.0-Rs.25K",
  "Rs.25K-Rs.50K",
  "Rs.50K+",
  "Not Allowed",
  "Other",
];

export const DJ_POLICY = [
  "In-house Only",
  "Outside Allowed",
  "Both",
  "Other",
];

export const NOISE_RESTRICTIONS = [
  "No Restriction",
  "Till 10 PM",
  "Till 12 AM",
  "As per Government Rules",
  "Other",
];

export const FIREWORKS_ALLOWED = ["Yes", "No", "With Permission", "Other"];

export const ENTERTAINMENT_SUPPORTED = [
  "DJ",
  "Live Band",
  "Dhol",
  "Celebrity Performance",
  "Anchors / Hosts",
  "Fireworks",
  "Baraat Entry Concepts",
  "Other",
];

export const POWER_BACKUP = [
  "Full",
  "Partial",
  "None",
  "Only Venue (Does not cover Decor)",
  "Other",
];

export const AIR_CONDITIONING = [
  "Full Venue",
  "Partial",
  "None",
  "Other",
];

export const WASHROOM_QUALITY = ["Basic", "Premium", "Luxury", "Other"];

export const SECURITY_SERVICES = [
  "Not Available",
  "Basic",
  "Professional",
  "Other",
];

export const ADDITIONAL_FACILITIES = [
  "Swimming Pool",
  "Spa",
  "Gym",
  "Kids Play Area",
  "Helipad",
  "Golf Course",
  "Private Beach",
  "Lake View",
  "Mountain View",
  "Other",
];

export const PRICING_MODEL = [
  "Per Plate",
  "Per Day Rental",
  "Per Function",
  "Per Hour",
  "Package Based",
  "Dynamic Pricing",
  "Other",
];

export const ADVANCE_PAYMENT_RANGE = [
  "0-25%",
  "25-50%",
  "50-75%",
  "75-100%",
  "Other",
];

export const MINIMUM_BOOKING_DURATION = [
  "2 Hours",
  "4 Hours",
  "6 Hours",
  "Full Day",
  "Shift Wise",
  "Multiple Days",
  "Other",
];

export const CANCELLATION_POLICY = [
  "Non Refundable",
  "Partial Refund",
  "Flexible",
  "Other",
];

export const REFUND_TIMELINE = [
  "0-7 Days",
  "7-15 Days",
  "15-30 Days",
  "30+ Days",
  "Other",
];

export const SUITABLE_FOR = [
  "Wedding",
  "Reception",
  "Haldi",
  "Mehendi",
  "Sangeet",
  "Engagement",
  "Cocktail",
  "Corporate Events",
  "Birthday / Private Events",
  "Other",
];

export const BEST_FOR = [
  "Budget Weddings",
  "Mid-Range Weddings",
  "Luxury Weddings",
  "Destination Weddings",
  "Intimate Weddings",
  "Large Weddings",
  "Other",
];

export const IDEAL_GUEST_RANGE = [
  "0-100",
  "100-300",
  "300-500",
  "500-1000",
  "1000+",
  "Other",
];

export const IMAGE_FUNCTION_TYPES = [
  "Wedding",
  "Reception",
  "Haldi",
  "Mehendi",
  "Sangeet",
  "Engagement",
  "Cocktail",
  "Corporate",
  "Other",
];

export const IMAGE_THEME_TYPES = [
  "Traditional",
  "Modern",
  "Minimalist",
  "Royal / Heritage",
  "Beach",
  "Garden",
  "Other",
];

export const IMAGE_COLOR_PALETTE = [
  "Pastel",
  "Jewel Tones",
  "Neutrals",
  "Red & Gold",
  "White & Green",
  "Other",
];

export const IMAGE_SETUP_TYPE = [
  "Mandap",
  "Stage",
  "Dining",
  "Lawn",
  "Poolside",
  "Indoor Hall",
  "Other",
];

export const IMAGE_BUDGET_RANGE = [
  "Budget",
  "Mid-Range",
  "Premium",
  "Luxury",
  "Other",
];

export function emptyVenueMaster() {
  return {
    categories: Object.fromEntries(
      VENUE_CATEGORY_GROUPS.map((g) => [g.key, []])
    ),
    identity: {
      property_ownership: "",
      property_ownership_other: "",
      years_of_operation: "",
      exact_location_text: "",
      map_pin_url: "",
      location_type: "",
      location_type_other: "",
      chain_property: "",
      chain_brand_name: "",
      chain_brand_category: "",
      chain_brand_category_other: "",
    },
    space_capacity: {
      space_types: [],
      space_types_other: "",
      num_event_spaces: "",
      spaces: [],
      indoor_spaces_count: "",
      outdoor_spaces_count: "",
      indoor_seating: "",
      indoor_floating: "",
      outdoor_seating: "",
      outdoor_floating: "",
      min_guests: "",
      max_guests: "",
      separate_function_areas: "",
      multiple_events_simultaneous: "",
      exclusive_booking: "",
    },
    rooms: {
      num_rooms: "",
      room_types: [],
      room_type_counts: {},
      room_types_other: "",
      max_occupancy_per_room: "",
      extra_bed: "",
      room_price_range: "",
      room_price_range_other: "",
      complimentary_rooms: "",
      total_stay_capacity: "",
    },
    food: {
      catering_policy: "",
      catering_policy_other: "",
      cuisines: [],
      cuisines_other: "",
      veg_non_veg: "",
      veg_non_veg_other: "",
      jain_food: "",
      per_plate_cost_range: "",
      per_plate_cost_range_other: "",
      outside_catering_charges: "",
      outside_catering_charges_other: "",
      kitchen_for_external: "",
    },
    alcohol: {
      policy: "",
      policy_other: "",
      corkage: "",
      corkage_other: "",
      bar_setup: [],
      bar_setup_other: "",
    },
    decor: {
      policy: "",
      policy_other: "",
      capabilities: [],
      capabilities_other: "",
      stage: [],
      stage_other: "",
      mandap: [],
      mandap_other: "",
      lighting: [],
      lighting_other: "",
      sound: [],
      sound_other: "",
      outside_charges: "",
      outside_charges_other: "",
    },
    entertainment: {
      dj_policy: "",
      dj_policy_other: "",
      noise: "",
      noise_other: "",
      live_band: "",
      fireworks: "",
      fireworks_other: "",
      supported: [],
      supported_other: "",
    },
    facilities: {
      parking: "",
      parking_capacity: "",
      valet: "",
      power_backup: [],
      power_backup_other: "",
      ac: "",
      ac_other: "",
      bridal_room: "",
      groom_room: "",
      wheelchair: "",
      washroom: "",
      washroom_other: "",
      lift: "",
      security: "",
      security_other: "",
      additional: [],
      additional_other: "",
    },
    pricing_booking: {
      pricing_model: [],
      pricing_model_other: "",
      starting_venue_price: "",
      peak_season_pricing: "",
      advance_booking_required: "",
      advance_payment_range: "",
      advance_payment_range_other: "",
      min_booking_duration: [],
      min_booking_duration_other: "",
      cancellation: "",
      cancellation_other: "",
      refund_timeline: "",
      refund_timeline_other: "",
    },
    suitability: {
      suitable_for: [],
      suitable_for_other: "",
      best_for: [],
      best_for_other: "",
      ideal_guest_range: [],
      ideal_guest_range_other: "",
    },
    image_intelligence: {
      notes: "",
      default_function_type: "",
      default_theme: "",
      default_palette: "",
      default_setup: "",
      default_budget_range: "",
      other_tags: "",
    },
  };
}
