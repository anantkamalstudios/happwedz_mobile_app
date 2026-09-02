export const TROUSSEAU_VENDOR_TYPE = [
  "Individual Artist",
  "Packaging Studio",
  "Luxury Packaging Brand",
  "Bulk Supplier + Customization",
];
export const YEARS_OF_EXPERIENCE = ["0–1", "1–3", "3–5", "5–10", "10+"];
export const SERVICE_MODE = [
  "On-site Packing",
  "Studio-based Packing",
  "Pickup & Delivery",
  "Courier Only",
];
export const TRAVEL_POLICY = [
  "Included (local)",
  "Fixed Cost",
  "Per Km",
  "Not Applicable",
];
export const PACKAGING_TYPES = [
  "Bridal Trousseau Packing",
  "Groom Trousseau Packing",
  "Saree Packing",
  "Lehenga Packing",
  "Jewelry Packing",
  "Gift Packing",
  "Dry Fruit Packing",
  "Return Gifts Packing",
];
export const PRODUCT_FORMATS = [
  "Boxes",
  "Trunks",
  "Suitcases",
  "Baskets",
  "Potlis",
  "Hampers",
  "Trays",
  "Envelopes",
];
export const OCCASION_COVERAGE = [
  "Wedding",
  "Engagement",
  "Mehendi",
  "Haldi",
  "Baby Shower",
  "Festive Gifting",
];
export const DESIGN_STYLE_TROUSSEAU = [
  "Royal Traditional",
  "Minimal Elegant",
  "Floral Theme",
  "Modern Luxury",
  "Customized Theme",
  "Cultural Regional",
];
export const CUSTOMIZATION_LEVEL = [
  "Fully Custom",
  "Semi-Custom",
  "Pre-designed Catalog",
];
export const MATERIAL_TYPES = [
  "Fabric (Silk, Velvet)",
  "MDF / Wood",
  "Acrylic",
  "Metal",
  "Paper / Cardboard",
  "Jute / Eco-friendly",
];
export const COLOR_PALETTE = [
  "Pastels",
  "Bright Traditional",
  "Metallic (Gold/Silver)",
  "Neutral Tones",
  "Custom",
];
export const PERSONALIZATION_OPTIONS_TROUSSEAU = [
  "Name Printing",
  "Initials / Monogram",
  "Photos",
  "Quotes / Messages",
  "Theme Matching",
];
export const EMBELLISHMENTS = [
  "Gota Patti",
  "Zari Work",
  "Mirror Work",
  "Floral Decor",
  "Lace",
  "Tassels",
  "Beads",
];
export const MIN_ORDER_QTY = ["1–10", "10–50", "50–100", "100+"];
export const MAX_ORDER_HANDLING = ["Up to 50", "50–200", "200–500", "500+"];
export const TURNAROUND_TIME = ["1–3 days", "3–7 days", "7–14 days", "14+ days"];
export const DELIVERY_OPTIONS = ["Pickup", "Home Delivery", "Courier"];
export const PACKAGING_ASSEMBLY = ["Vendor Studio", "On-site (Client Location)", "Hybrid"];
export const PRICING_MODEL_TROUSSEAU = [
  "Per Piece",
  "Per Set",
  "Bulk Pricing",
  "Package",
];
export const PRICE_RANGE_TROUSSEAU = [
  "₹200–₹500",
  "₹500–₹1000",
  "₹1000–₹3000",
  "₹3000–₹7000",
  "₹7000+",
];
export const INCLUDES_TROUSSEAU = [
  "Base Packaging",
  "Decoration",
  "Personalization",
  "Packing Service",
];
export const ADDONS_TROUSSEAU = [
  "Premium Materials",
  "Custom Design",
  "Urgent Delivery",
  "Logistics",
];
export const NEGOTIATION = ["Fixed", "Moderate", "Flexible"];
export const ORDERS_PER_DAY = ["1–10", "10–50", "50–100", "100+"];
export const TEAM_SIZE = ["Solo", "2–5", "5–10", "10+"];
export const ADVANCE_BOOKING_TIME = ["<1 week", "1–2 weeks", "2–4 weeks", "1–2 months"];
export const BOOKING_ADVANCE = ["25%", "50%", "75%", "100%"];
export const CANCELLATION_POLICY = ["Non-refundable", "Partial refund", "Flexible"];
export const CLIENT_COORDINATION = ["WhatsApp", "Call", "In-person", "App-based"];

export const emptyTrousseauMaster = () => ({
  identity: {
    vendor_type: "",
    brand_name: "",
    years_of_experience: "",
    primary_city: "",
    service_cities: [],
    service_mode: "",
    travel_policy: "",
  },
  services: {
    packaging_types: [],
    product_formats: [],
    occasion_coverage: [],
  },
  intelligence: {
    design_style: [],
    customization_level: "",
    material_types: [],
    color_palette: "",
    personalization_options: [],
    embellishments: [],
  },
  capacity: {
    minimum_order_quantity: "",
    maximum_order_handling: "",
    bulk_order_capability: "",
    ready_stock_availability: "",
    customization_turnaround: "",
  },
  logistics: {
    delivery_options: "",
    packaging_assembly: "",
    fragile_handling: "",
    storage_support: "",
    urgent_order_handling: "",
  },
  pricing: {
    pricing_model: "",
    starting_price_range: "",
    includes: [],
    add_ons: [],
    negotiation_flexibility: "",
  },
  scale: {
    orders_per_day_capacity: "",
    team_size: "",
    parallel_order_handling: "",
  },
  workflow: {
    advance_booking_time: "",
    booking_advance_percent: "",
    cancellation_policy: "",
    client_coordination: "",
    sample_availability: "",
  },
  portfolio: {
    packaging_tags: "",
    occasion_tags: "",
    style_tags: "",
  },
  ai_faq: {
    handle_bulk_orders: "",
    customization_available: "",
    personalized_with_names: "",
    eco_friendly_packaging: "",
    urgent_delivery_possible: "",
    deliver_across_cities: "",
    on_site_packing_available: "",
    materials_premium_quality: "",
    match_wedding_theme: "",
    samples_available_before_booking: "",
    handle_fragile_items: "",
    minimum_order_required: "",
    manage_last_minute_orders: "",
    delivery_charges_included: "",
    packaging_reusable: "",
  },
});
