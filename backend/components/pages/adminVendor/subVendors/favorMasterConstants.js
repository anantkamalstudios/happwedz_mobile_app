export const FAVOR_VENDOR_TYPE = [
  "Favor Specialist",
  "Gift Studio (Favors Focus)",
  "Bulk Supplier",
  "Luxury Favor Curator",
  "Eco-friendly Favor Brand",
];
export const YEARS_OF_EXPERIENCE = ["0–1", "1–3", "3–5", "5–10", "10+"];
export const BUSINESS_MODEL = [
  "Ready Stock",
  "Made-to-Order",
  "Hybrid",
];
export const FAVOR_CATEGORIES = [
  "Edible Favors",
  "Mini Hampers",
  "Scented Candles",
  "Soaps / Skincare Minis",
  "Seed / Plant Kits",
  "Religious Tokens",
  "Utility Items",
  "Decorative Items",
  "Personalized Keepsakes",
];
export const OCCASION_MAPPING = [
  "Mehendi Favors",
  "Haldi Favors",
  "Sangeet Favors",
  "Wedding Favors",
  "Reception Favors",
  "Kids Favors",
];
export const AUDIENCE_TARGET = [
  "All Guests",
  "Ladies Only",
  "Kids Only",
  "VIP Guests",
  "Family",
];
export const FAVOR_TYPE_CLASSIFICATION = [
  "Consumable",
  "Non-Consumable",
  "Eco-friendly",
  "Personalized",
  "Thematic",
];
export const CUSTOMIZATION_OPTIONS_FAVOR = [
  "Name Tags",
  "Initials",
  "Event Name",
  "Date Print",
  "Custom Message",
  "Color Matching",
];
export const THEME_COMPATIBILITY_FAVOR = [
  "Floral",
  "Royal",
  "Minimal",
  "Rustic",
  "Modern Luxury",
  "Cultural Traditional",
];
export const SHELF_LIFE_FAVOR = [
  "<7 days",
  "7–15 days",
  "15–30 days",
  "30+ days",
];
export const PACKAGING_TYPE = [
  "Boxes",
  "Jars",
  "Bottles",
  "Pouches",
  "Baskets",
  "Trays",
];
export const MIN_ORDER_QTY = ["10–50", "50–100", "100–300", "300–500", "500+"];
export const MAX_ORDER_CAPACITY = ["100", "100–500", "500–1000", "1000+"];
export const TURNAROUND_TIME = ["1–3 days", "3–7 days", "7–14 days", "14+ days"];
export const DELIVERY_OPTIONS = ["Pickup", "Home Delivery", "Courier"];
export const SHIPPING_COVERAGE = ["Local", "Pan-India", "International"];
export const PRICING_MODEL_FAVOR = [
  "Per Unit",
  "Bulk Pricing",
  "Per Set",
  "Package",
];
export const PRICE_RANGE_FAVOR = [
  "₹50–₹150",
  "₹150–₹300",
  "₹300–₹700",
  "₹700–₹1500",
  "₹1500+",
];
export const INCLUDES_FAVOR = [
  "Product",
  "Packaging",
  "Tagging / Personalization",
  "Delivery",
];
export const ADDONS_FAVOR = [
  "Premium Packaging",
  "Custom Tags",
  "Express Delivery",
  "Special Materials",
];
export const NEGOTIATION = ["Fixed", "Moderate", "Flexible"];
export const ORDERS_PER_DAY = ["50–100", "100–300", "300–700", "700+"];
export const TEAM_SIZE = ["Solo", "2–5", "5–10", "10+"];
export const ADVANCE_BOOKING_TIME = ["<1 week", "1–2 weeks", "2–4 weeks", "1–2 months"];
export const BOOKING_ADVANCE = ["25%", "50%", "75%", "100%"];
export const CANCELLATION_POLICY = ["Non-refundable", "Partial refund", "Flexible"];
export const CLIENT_COORDINATION = ["WhatsApp", "Call", "Email", "App-based"];

export const emptyFavorMaster = () => ({
  identity: {
    vendor_type: "",
    brand_name: "",
    years_of_experience: "",
    primary_city: "",
    service_cities: [],
    business_model: "",
  },
  catalog: {
    favor_categories: [],
    occasion_mapping: [],
    audience_target: "",
  },
  intelligence: {
    favor_type_classification: "",
    customization_options: [],
    theme_compatibility: "",
    shelf_life: "",
    packaging_type: [],
    eco_friendly_option: "",
    reusability: "",
  },
  capacity: {
    minimum_order_quantity: "",
    maximum_order_capacity: "",
    bulk_handling: "",
    ready_stock: "",
    customization_turnaround: "",
  },
  logistics: {
    delivery_options: "",
    shipping_coverage: "",
    fragile_handling: "",
    temperature_sensitivity_handling: "",
    urgent_orders: "",
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
    parallel_orders: "",
  },
  workflow: {
    advance_booking_time: "",
    booking_advance_percent: "",
    cancellation_policy: "",
    client_coordination: "",
    sample_availability: "",
  },
  portfolio: {
    favor_tags: "",
    occasion_tags: "",
    style_tags: "",
  },
  ai_faq: {
    handle_bulk_orders: "",
    favors_customizable: "",
    edible_favors_available: "",
    shelf_life_of_edible: "",
    eco_friendly_favors: "",
    personalized_with_names: "",
    provide_packaging: "",
    deliver_across_india: "",
    favors_reusable: "",
    minimum_order_quantity_required: "",
    handle_urgent_orders: "",
    fragile_items_safely_packed: "",
    match_wedding_theme: "",
    suitable_for_kids: "",
    premium_luxury_favors_available: "",
  },
});
