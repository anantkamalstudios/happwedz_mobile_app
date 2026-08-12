// Section 1 — Basic Identity
export const VENDOR_TYPE = [
  "Retail Florist",
  "Wedding Florist Specialist",
  "Wholesale Florist",
  "Floral Designer Studio",
  "Online Flower Brand",
];

export const SERVICE_PRESENCE = [
  "Local Delivery",
  "Outstation Delivery",
  "Pan-India Shipping",
];

export const STORE_PRESENCE = ["Physical Store", "Online Store", "Both"];

export const YEARS_OF_EXPERIENCE = ["0–2", "3–5", "6–10", "10+"];

export const SPECIALIZATION = [
  "Wedding Decor Florals",
  "Bouquets",
  "Garlands",
  "Floral Jewellery",
  "Car Decor Flowers",
];

// Section 2 — Services Offered
export const SERVICE_TYPES = [
  "Fresh Flowers",
  "Artificial Flowers",
  "Preserved Flowers",
  "Dry Flowers",
];

export const PACKAGING_OPTIONS = [
  "Basic Wrap",
  "Premium Packaging",
  "Luxury Boxes",
];

// Section 3 — Core Intelligence
export const FLOWER_TYPES = [
  "Roses",
  "Orchids",
  "Marigold",
  "Lilies",
  "Carnations",
  "Baby's Breath",
  "Exotic Imports",
];

export const USAGE_TYPES = [
  "Bridal Bouquet",
  "Var Mala",
  "Car Decor",
  "Mandap Decor",
  "Table Centerpieces",
  "Entry Decor",
];

export const FRAGRANCE_LEVEL = ["Mild", "Medium", "Strong"];

export const LONGEVITY_TYPE = [
  "1 Day",
  "2–3 Days",
  "3–7 Days",
  "Preserved (Weeks/Months)",
];

export const COLOR_PALETTE = [
  "Red",
  "White",
  "Yellow",
  "Pink",
  "Pastel Mix",
  "Custom Mix",
];

export const SEASONAL_AVAILABILITY = ["All Year", "Seasonal Only", "Mixed"];

// Section 4 — Technical / Product / Skill
export const STORAGE_FACILITY = ["Cold Storage Available", "No Cold Storage"];

export const SOURCING_TYPE = [
  "Local Farms",
  "Imported Flowers",
  "Wholesale Market",
];

export const ARRANGEMENT_TYPES = [
  "Hand-Tied",
  "Basket Arrangement",
  "Vase Arrangement",
  "Installation-Based",
];

// Section 5 — Pricing
export const PRICE_RANGE = ["500–2K", "2K–5K", "5K–15K", "15K–50K", "50K+"];

export const PRICING_MODEL = [
  "Per Piece",
  "Per Kg",
  "Per Event",
  "Custom Quote",
];

export const DELIVERY_CHARGES = ["Included", "Extra"];

export const SETUP_CHARGES = ["Included", "Extra"];

// Section 6 — Scale & Capacity
export const DAILY_ORDER_CAPACITY = ["<20", "20–50", "50–100", "100+"];

export const EVENT_HANDLING_CAPACITY = [
  "1 Event",
  "2–3 Events",
  "3–5 Events",
  "5+ Events",
];

export const TEAM_SIZE = ["1–2", "3–5", "6–10", "10+"];

// Section 7 — Workflow & Booking
export const BOOKING_WINDOW = [
  "Same Day",
  "1–3 Days",
  "3–7 Days",
  "7+ Days",
];

export const CUSTOMIZATION_APPROVAL = [
  "Catalog Selection",
  "Sample Preview",
  "Mock Setup",
];

export const DELIVERY_TIME_SLOTS = ["Fixed", "Flexible"];

export const PAYMENT_MODES = ["UPI", "Cash", "Card", "Bank Transfer"];

export const ADVANCE_PAYMENT_PERCENTAGE = ["0%", "25%", "50%", "100%"];

// Section 8 — Portfolio Tagging
export const STYLE_TAGS = [
  "Romantic",
  "Luxury Floral",
  "Traditional",
  "Minimal",
  "Exotic",
];

export const AUDIENCE_TAGS = [
  "Bride",
  "Groom",
  "Wedding Planner",
  "Decorator",
];

export const USAGE_TAGS = [
  "Wedding Decor",
  "Bouquets",
  "Gifting",
  "Car Decor",
];

export const PRICE_SEGMENT_TAGS = ["Budget", "Mid-range", "Premium", "Luxury"];

export function emptyFloristMaster() {
  return {
    identity: {
      vendor_type: "",
      brand_name: "",
      service_presence: [],
      city: "",
      store_presence: [],
      years_of_experience: "",
      specialization: [],
    },
    services_offered: {
      service_types: [],
      customization_available: "",
      same_day_delivery: "",
      subscription_services: "",
      bulk_order_handling: "",
      event_setup_support: "",
      packaging_options: [],
    },
    core_intelligence: {
      flower_types_available: [],
      usage_types: [],
      fragrance_level: "",
      longevity_type: "",
      color_palette: [],
      seasonal_availability: "",
    },
    technical: {
      storage_facility: "",
      flower_freshness_guarantee: "",
      sourcing_type: [],
      arrangement_types: [],
      eco_friendly_options: "",
    },
    pricing: {
      price_range: "",
      pricing_model: "",
      delivery_charges: "",
      setup_charges: "",
      bulk_discounts: "",
    },
    scale_capacity: {
      daily_order_capacity: "",
      event_handling_capacity: "",
      team_size: "",
    },
    workflow: {
      advance_booking_required: "",
      booking_window: "",
      customization_approval_process: "",
      delivery_time_slots: "",
      payment_modes: [],
      advance_payment_percentage: "",
    },
    portfolio_tagging: {
      style_tags: [],
      audience_tags: [],
      usage_tags: [],
      price_segment_tags: "",
    },
    ai_faq: {
      provides_fresh_flowers: "",
      handles_wedding_floral_decor: "",
      same_day_delivery_available: "",
      provides_bridal_bouquets: "",
      exotic_imported_flowers_available: "",
      offers_bulk_flower_supply: "",
      customization_available: "",
      provides_flower_garlands: "",
      setup_included_for_events: "",
      provides_car_decoration_flowers: "",
      preserved_flowers_available: "",
      delivery_included_in_pricing: "",
      eco_friendly_options: "",
      handles_large_wedding_orders: "",
      provides_premium_packaging: "",
    },
  };
}
