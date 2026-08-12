export const SUIT_VENDOR_TYPE = [
  "Tailor / Bespoke Studio",
  "Ready-to-Wear Retailer",
  "Designer Studio",
  "Multi-Brand Store",
  "Online Suit Brand",
];
export const STORE_PRESENCE = ["Physical Store", "Online Store", "Both"];
export const STORE_ACCESS_TYPE = ["Walk-in", "Appointment Only", "Hybrid"];
export const YEARS_OF_EXPERIENCE = ["0–2", "3–5", "6–10", "10+"];
export const SPECIALIZATION = [
  "Groom Wedding Suits",
  "Reception Suits",
  "Cocktail Suits",
  "Indo-Western Suits",
  "Formal Suits",
];

export const SERVICE_MODES = [
  "Bespoke (Custom Tailored)",
  "Made-to-Measure",
  "Ready-to-Wear",
];
export const ACCESSORY_ADD_ONS = [
  "Shirt",
  "Tie / Bow Tie",
  "Pocket Square",
  "Belt",
  "Shoes",
];

export const SUIT_TYPES = [
  "Tuxedo",
  "Two-Piece Suit",
  "Three-Piece Suit",
  "Bandhgala Suit",
  "Jodhpuri Suit",
  "Indo-Western Suit",
];
export const OCCASION_SUITABILITY = [
  "Wedding Ceremony",
  "Reception",
  "Engagement",
  "Cocktail",
  "Formal Events",
];
export const FIT_TYPE = [
  "Slim Fit",
  "Regular Fit",
  "Relaxed Fit",
  "Custom Fit",
];
export const FABRIC_OPTIONS = [
  "Wool",
  "Terry Rayon",
  "Velvet",
  "Linen",
  "Cotton",
  "Silk Blend",
];
export const SEASON_SUITABILITY = ["Summer", "Winter", "All-Season"];
export const DESIGN_STYLE = ["Plain", "Textured", "Patterned", "Embroidered"];
export const COLOR_PALETTE = [
  "Black",
  "Navy",
  "Grey",
  "Beige",
  "Pastel",
  "Jewel Tones",
];

export const STITCHING_TYPE = [
  "Machine Stitch",
  "Hand Finished",
  "Fully Handcrafted",
];
export const CANVAS_CONSTRUCTION = ["Full Canvas", "Half Canvas", "Fused"];
export const CUSTOMIZATION_DEPTH = [
  "Lapel Style Selection",
  "Button Customization",
  "Lining Customization",
  "Monogramming",
];
export const LAPEL_TYPES = ["Notch Lapel", "Peak Lapel", "Shawl Lapel"];
export const CLOSURE_TYPE = ["Single Breasted", "Double Breasted"];
export const NUMBER_OF_BUTTONS = ["1", "2", "3"];
export const DURABILITY_LEVEL = ["Occasion Wear", "Premium Long-Term"];

export const PRICE_RANGE = [
  "5K–15K",
  "15K–30K",
  "30K–75K",
  "75K–1.5L",
  "1.5L+",
];
export const PRICING_OPTIONS = ["Included", "Extra"];
export const FABRIC_COST_STRUCTURE = ["Included", "Separate"];
export const ACCESSORY_BUNDLE_PRICING = ["Included", "Optional Add-on"];

export const DAILY_CLIENT_CAPACITY = ["1–5", "5–10", "10–20", "20+"];
export const MONTHLY_PRODUCTION_CAPACITY = ["<20 Suits", "20–50", "50–100", "100+"];

export const MEASUREMENT_PROCESS = [
  "In-store Measurement",
  "Home Visit Measurement",
  "Standard Size Selection",
];
export const LEAD_TIME = ["3–7 days", "7–15 days", "15–30 days", "30+ days"];
export const TRIAL_ROUNDS = ["0", "1", "2", "3+"];
export const ALTERATION_TIMELINE = ["Same Day", "1–3 days", "3–7 days"];
export const PAYMENT_MODES = ["UPI", "Cash", "Card", "Bank Transfer"];
export const ADVANCE_PAYMENT = ["25%", "50%", "75%", "100%"];

export const STYLE_TAGS = ["Classic Groom", "Modern Groom", "Royal Groom", "Minimal Groom"];
export const AUDIENCE_TAGS = ["Groom", "Best Man", "Family Members"];
export const USAGE_TAGS = ["Wedding", "Reception", "Cocktail", "Formal"];
export const PRICE_SEGMENT_TAGS = ["Budget", "Mid-range", "Premium", "Luxury"];

export const emptyWeddingSuitMaster = () => ({
  identity: {
    vendor_type: "",
    brand_name: "",
    sell_on_ecommerce: false,
    store_presence: [],
    city: "",
    store_access_type: "",
    years_of_experience: "",
    specialization: [],
  },
  services: {
    service_modes: [],
    trial_availability: "",
    styling_consultation: "",
    fabric_selection_assistance: "",
    home_measurement_service: "",
    alteration_services: "",
    express_delivery_available: "",
    accessory_add_ons: [],
  },
  intelligence: {
    suit_types: [],
    occasion_suitability: [],
    fit_type: [],
    fabric_options: [],
    season_suitability: [],
    design_style: [],
    color_palette: [],
  },
  technical: {
    stitching_type: "",
    canvas_construction: "",
    customization_depth: [],
    lapel_types: [],
    closure_type: [],
    number_of_buttons: "",
    durability_level: "",
  },
  pricing: {
    price_range: "",
    customization_charges: "",
    fabric_cost_structure: "",
    accessory_bundle_pricing: "",
    bulk_order_discounts: "",
  },
  capacity: {
    daily_client_capacity: "",
    monthly_production_capacity: "",
    trial_room_availability: "",
  },
  workflow: {
    appointment_required: "",
    measurement_process: [],
    lead_time: "",
    trial_rounds: "",
    alteration_timeline: "",
    payment_modes: [],
    advance_payment: "",
  },
  portfolio: {
    style_tags: [],
    audience_tags: [],
    usage_tags: [],
    price_segment_tags: "",
  },
  ai_faq: {
    custom_tailored_suits: "",
    tuxedos_available: "",
    home_measurement_services: "",
    trial_available: "",
    suit_within_7_days: "",
    three_piece_suits: "",
    fabric_included_pricing: "",
    accessories_with_suits: "",
    slim_fit_suits: "",
    indo_western_suits: "",
    alteration_included: "",
    premium_hand_stitched: "",
    group_bulk_suits: "",
    express_delivery: "",
    winter_specific_suits: "",
  },
});
