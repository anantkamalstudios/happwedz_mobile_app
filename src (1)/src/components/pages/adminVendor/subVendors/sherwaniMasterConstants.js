export const SHERWANI_VENDOR_TYPE = [
  "Designer Sherwani Studio",
  "Multi-Brand Retailer",
  "Bespoke Tailor",
  "Rental + Retail Hybrid",
  "Online Sherwani Brand",
];
export const STORE_PRESENCE = ["Physical Store", "Online Store", "Both"];
export const STORE_ACCESS_TYPE = ["Walk-in", "Appointment Only", "Hybrid"];
export const YEARS_OF_EXPERIENCE = ["0–2", "3–5", "6–10", "10+"];
export const SPECIALIZATION = [
  "Groom Sherwani",
  "Reception Sherwani",
  "Indo-Western Sherwani",
  "Prince Coat Sets",
  "Achkan",
];

export const SERVICE_MODES = [
  "Bespoke (Custom Tailored)",
  "Made-to-Measure",
  "Ready-to-Wear",
  "Rental Available",
];
export const ACCESSORY_ADD_ONS = [
  "Safa / Turban",
  "Stole / Dupatta",
  "Mojari",
  "Brooch",
  "Mala",
];

export const SHERWANI_TYPES = [
  "Traditional Sherwani",
  "Indo-Western Sherwani",
  "Jacket Style Sherwani",
  "Achkan",
  "Angrakha Style",
];
export const OCCASION_SUITABILITY = [
  "Wedding Ceremony",
  "Reception",
  "Engagement",
  "Sangeet",
  "Baraat",
];
export const WORK_TYPE = [
  "Zari",
  "Zardozi",
  "Thread Work",
  "Mirror Work",
  "Sequins",
  "Minimal",
];
export const FABRIC_OPTIONS = [
  "Silk",
  "Velvet",
  "Brocade",
  "Jacquard",
  "Cotton Silk",
  "Linen Blend",
];
export const COLOR_PALETTE = [
  "Ivory / Cream",
  "Gold",
  "Pastel",
  "Maroon",
  "Navy",
  "Jewel Tones",
];
export const DESIGN_STYLE = [
  "Heavy Bridal",
  "Semi-Bridal",
  "Minimal Elegant",
  "Royal Heritage",
];
export const LAYERING_OPTIONS = [
  "With Dupatta",
  "Without Dupatta",
  "With Jacket Layer",
];

export const FIT_TYPE = ["Slim Fit", "Regular Fit", "Custom Fit"];
export const CLOSURE_TYPE = ["Buttoned", "Hook", "Hidden Placket"];
export const LENGTH_TYPE = ["Knee Length", "Below Knee", "Ankle Length"];
export const BOTTOM_WEAR_OPTIONS = [
  "Churidar",
  "Straight Pants",
  "Dhoti Pants",
  "Salwar",
];
export const EMBROIDERY_DENSITY = ["Light", "Medium", "Heavy"];
export const DURABILITY_LEVEL = ["Occasion Wear", "Premium Heirloom"];

export const PRICE_RANGE = [
  "5K–20K",
  "20K–50K",
  "50K–1L",
  "1L–2L",
  "2L+",
];
export const PRICING_OPTIONS = ["Included", "Extra"];
export const RENTAL_PRICING_OPTION = ["Available", "Not Available"];
export const ACCESSORY_BUNDLE_PRICING = ["Included", "Optional Add-on"];

export const DAILY_CLIENT_CAPACITY = ["1–5", "5–10", "10–20", "20+"];
export const MONTHLY_PRODUCTION_CAPACITY = ["<20", "20–50", "50–100", "100+"];

export const MEASUREMENT_PROCESS = [
  "In-store Measurement",
  "Home Visit",
  "Standard Size",
];
export const LEAD_TIME = ["3–7 days", "7–15 days", "15–30 days", "30+ days"];
export const TRIAL_ROUNDS = ["0", "1", "2", "3+"];
export const ALTERATION_TIMELINE = ["Same Day", "1–3 days", "3–7 days"];
export const PAYMENT_MODES = ["UPI", "Cash", "Card", "Bank Transfer"];
export const ADVANCE_PAYMENT = ["25%", "50%", "75%", "100%"];

export const STYLE_TAGS = ["Royal Groom", "Traditional Groom", "Modern Groom", "Minimal Groom"];
export const AUDIENCE_TAGS = ["Groom", "Brother of Groom/Bride", "Wedding Party"];
export const USAGE_TAGS = ["Wedding Ceremony", "Reception", "Baraat", "Sangeet"];
export const PRICE_SEGMENT_TAGS = ["Budget", "Mid-range", "Premium", "Luxury"];

export const emptySherwaniMaster = () => ({
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
    home_measurement_service: "",
    alteration_services: "",
    express_delivery_available: "",
    accessory_add_ons: [],
  },
  intelligence: {
    sherwani_types: [],
    occasion_suitability: [],
    work_type: [],
    fabric_options: [],
    color_palette: [],
    design_style: [],
    layering_options: [],
  },
  technical: {
    fit_type: [],
    closure_type: [],
    length_type: "",
    inner_layer_included: "",
    bottom_wear_options: [],
    embroidery_density: "",
    durability_level: "",
  },
  pricing: {
    price_range: "",
    customization_charges: "",
    rental_pricing_option: "",
    accessory_bundle_pricing: "",
    bulk_discounts: "",
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
    sherwanis_for_groom: "",
    customization_available: "",
    rental_sherwanis: "",
    heavy_embroidered_sherwanis: "",
    indo_western_sherwanis: "",
    trial_available_before_purchase: "",
    safa_and_accessories: "",
    sherwani_within_7_days: "",
    plus_sizes_available: "",
    home_measurement_services: "",
    alteration_included: "",
    groom_squad_outfits: "",
    velvet_sherwanis: "",
    complete_set_top_bottom: "",
    express_delivery: "",
  },
});
