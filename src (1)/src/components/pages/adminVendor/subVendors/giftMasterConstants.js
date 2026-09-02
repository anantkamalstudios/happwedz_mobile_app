export const GIFT_VENDOR_TYPE = [
  "Retail Brand",
  "Custom Gift Studio",
  "Bulk Supplier",
  "Luxury Gift Curator",
  "Marketplace Aggregator",
];
export const YEARS_OF_EXPERIENCE = ["0–1", "1–3", "3–5", "5–10", "10+"];
export const BUSINESS_MODEL = [
  "Ready Stock",
  "Made-to-Order",
  "Hybrid",
];
export const GIFT_CATEGORIES = [
  "Dry Fruits",
  "Chocolates",
  "Gourmet Hampers",
  "Home Decor",
  "Utility Gifts",
  "Kitchenware",
  "Apparel Gifts",
  "Wellness Products",
  "Religious Items",
  "Luxury Items",
];
export const OCCASION_SUITABILITY = [
  "Wedding Return Gifts",
  "Mehendi Gifts",
  "Haldi Gifts",
  "Engagement Gifts",
  "Corporate Gifting",
  "Festive Gifting",
];
export const TARGET_AUDIENCE = [
  "Guests",
  "Close Family",
  "VIP Guests",
  "Corporate Guests",
  "Kids",
];
export const GIFT_TYPE_CLASSIFICATION = [
  "Consumable",
  "Non-Consumable",
  "Experience-Based",
  "Personalized",
];
export const CUSTOMIZATION_OPTIONS_GIFT = [
  "Name Personalization",
  "Initials / Monogram",
  "Photo Printing",
  "Custom Message",
  "Branding (for corporate)",
];
export const THEME_COMPATIBILITY = [
  "Royal Wedding",
  "Minimal Elegant",
  "Traditional",
  "Modern Luxury",
  "Eco-friendly",
  "Destination Wedding",
];
export const SHELF_LIFE = [
  "<7 days",
  "7–15 days",
  "15–30 days",
  "30–90 days",
  "90+ days",
];
export const PREMIUM_LUXURY_TAG = [
  "Budget",
  "Mid-range",
  "Premium",
  "Ultra Luxury",
];
export const MIN_ORDER_QTY = ["1–50", "50–100", "100–300", "300–500", "500+"];
export const MAX_ORDER_CAPACITY = ["100", "100–500", "500–1000", "1000+"];
export const TURNAROUND_TIME = ["1–3 days", "3–7 days", "7–14 days", "14+ days"];
export const DELIVERY_OPTIONS = ["Pickup", "Home Delivery", "Courier"];
export const SHIPPING_COVERAGE = ["Local", "Pan-India", "International"];
export const PRICING_MODEL_GIFT = [
  "Per Unit",
  "Per Hamper",
  "Bulk Pricing",
  "Package",
];
export const PRICE_RANGE_GIFT = [
  "₹100–₹300",
  "₹300–₹700",
  "₹700–₹1500",
  "₹1500–₹5000",
  "₹5000+",
];
export const INCLUDES_GIFT = [
  "Product",
  "Packaging",
  "Personalization",
  "Delivery",
];
export const ADDONS_GIFT = [
  "Premium Packaging",
  "Custom Branding",
  "Express Delivery",
  "Gift Wrapping",
];
export const NEGOTIATION = ["Fixed", "Moderate", "Flexible"];
export const ORDERS_PER_DAY = ["1–50", "50–200", "200–500", "500+"];
export const TEAM_SIZE = ["Solo", "2–5", "5–10", "10+"];
export const ADVANCE_BOOKING_TIME = ["<1 week", "1–2 weeks", "2–4 weeks", "1–2 months"];
export const BOOKING_ADVANCE = ["25%", "50%", "75%", "100%"];
export const CANCELLATION_POLICY = ["Non-refundable", "Partial refund", "Flexible"];
export const CLIENT_COORDINATION = ["WhatsApp", "Call", "Email", "App-based"];

export const emptyGiftMaster = () => ({
  identity: {
    vendor_type: "",
    brand_name: "",
    years_of_experience: "",
    primary_city: "",
    service_cities: [],
    business_model: "",
  },
  catalog: {
    gift_categories: [],
    occasion_suitability: [],
    target_audience: "",
  },
  intelligence: {
    gift_type_classification: "",
    customization_options: [],
    theme_compatibility: "",
    shelf_life: "",
    packaging_included: "",
    eco_friendly_options: "",
    premium_luxury_tag: "",
  },
  capacity: {
    minimum_order_quantity: "",
    maximum_order_capacity: "",
    bulk_order_handling: "",
    ready_stock_availability: "",
    customization_turnaround: "",
  },
  logistics: {
    delivery_options: "",
    shipping_coverage: "",
    fragile_handling: "",
    temperature_control: "",
    storage_support: "",
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
    gift_tags: "",
    occasion_tags: "",
    style_tags: "",
  },
  ai_faq: {
    handle_bulk_orders: "",
    gifts_customizable: "",
    packaging_included_in_pricing: "",
    eco_friendly_gift_options: "",
    deliver_across_india: "",
    consumable_gifts_available: "",
    shelf_life_of_consumables: "",
    luxury_gift_options: "",
    handle_urgent_orders: "",
    samples_available_before_order: "",
    gifts_branded_corporate: "",
    minimum_order_quantity_required: "",
    fragile_items_safely_handled: "",
    temperature_controlled_delivery: "",
    suitable_for_all_guest_categories: "",
  },
});
