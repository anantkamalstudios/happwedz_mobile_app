export const VENDOR_TYPE = [
    "Designer Boutique",
    "Multi-Designer Store",
    "Custom Lehenga Studio",
    "Retail Brand",
    "Luxury Couture House"
];

export const YEARS_OF_EXPERIENCE = ["0–1", "1–3", "3–5", "5–10", "10+"];

export const STORE_PRESENCE = ["Studio Only", "Retail Store", "Both"];

export const SERVICE_CITIES = ["Pan-India Shipping", "International Shipping"];

export const APPOINTMENT_REQUIREMENT = ["Mandatory", "Optional", "Walk-in Allowed"];

export const LEHENGA_TYPES = [
    "Bridal Wedding Lehenga",
    "Reception Lehenga",
    "Engagement Lehenga",
    "Sangeet Lehenga",
    "Pre-Wedding Shoot Lehenga"
];

export const COLLECTION_TYPE = [
    "Ready-to-Wear",
    "Made-to-Order",
    "Custom Designed",
    "Hybrid"
];

export const DESIGN_STYLE = [
    "Royal / Traditional",
    "Mughal Inspired",
    "Minimal / Elegant",
    "Contemporary / Modern",
    "Indo-Western",
    "Fusion"
];

export const COLOR_OPTIONS = ["Red", "Maroon", "Pink", "Pastels", "Ivory / White", "Gold", "Custom"];

export const SILHOUETTE_TYPES = [
    "A-line",
    "Circular / Flared",
    "Panelled",
    "Mermaid / Fish Cut",
    "Straight Cut"
];

export const FABRIC_OPTIONS = ["Silk", "Velvet", "Net", "Georgette", "Organza", "Satin", "Tissue"];

export const WORK_TYPES = ["Zari", "Zardozi", "Mirror Work", "Sequins", "Thread Work", "Resham", "Gota Patti", "Stone Work"];

export const WEIGHT_CATEGORY = ["Lightweight", "Medium", "Heavy", "Very Heavy"];

export const DUPATTA_OPTIONS = ["Single Dupatta", "Double Dupatta", "Custom Styling"];

export const CUSTOMIZATION_DEPTH = ["Full Custom Design", "Semi Custom", "Size Alterations Only"];

export const SIZE_RANGE = ["XS", "S", "M", "L", "XL", "XXL", "Custom Size"];

export const BODY_TYPE_STYLING = ["Petite", "Tall", "Plus Size", "Hourglass", "Pear Shape", "Rectangle"];

export const YES_NO = ["Yes", "No"];

export const ALTERATION_SUPPORT = ["Included", "Chargeable", "Not Available"];

export const OCCASION_SUITABILITY = ["Wedding", "Reception", "Engagement", "Sangeet"];

export const REUSABILITY = ["High", "Medium", "Low"];

export const COMFORT_LEVEL = ["High", "Moderate", "Heavy Wear"];

export const SEASON_SUITABILITY = ["Summer", "Winter", "All Season"];

export const PRICING_MODEL = ["Per Outfit", "Custom Pricing", "Designer Tier Pricing"];

export const PRICE_RANGE = ["₹20k–₹50k", "₹50k–₹1L", "₹1L–₹3L", "₹3L–₹7L", "₹7L+"];

export const INCLUDES = ["Lehenga", "Blouse", "Dupatta", "Customization", "Alterations"];

export const ADD_ONS = ["Extra Dupatta", "Premium Fabric", "Rush Orders", "Styling"];

export const NEGOTIATION_FLEXIBILITY = ["Fixed", "Moderate", "Flexible"];

export const PRODUCTION_TIME = ["Ready Stock", "2–4 weeks", "4–8 weeks", "8–12 weeks"];

export const DELIVERY_OPTIONS = ["Store Pickup", "Home Delivery", "International Shipping"];

export const PACKAGING = ["Basic", "Premium Box", "Luxury Packaging"];

export const ORDERS_PER_MONTH = ["<20", "20–50", "50–100", "100+"];

export const TEAM_SIZE = ["Solo Designer", "2–5", "5–10", "10+"];

export const ADVANCE_BOOKING_TIME = ["<2 weeks", "2–4 weeks", "1–3 months", "3–6 months"];

export const BOOKING_ADVANCE = ["25%", "50%", "75%", "100%"];

export const CANCELLATION_POLICY = ["Non-refundable", "Partial refund", "Flexible"];

export const CLIENT_COORDINATION = ["WhatsApp", "Call", "In-person", "App-based"];

export const LEHENGA_TAGS = ["Luxury Bridal", "Budget Bridal", "Designer Couture", "Custom Bridal"];

export const STYLE_TAGS = ["Royal", "Minimal", "Modern", "Traditional"];

export const BRIDE_TYPE_TAGS = ["Classic Bride", "Modern Bride", "Experimental Bride"];

export const emptyBridalOutfitMaster = () => ({
    identity: {
        vendor_type: "",
        brand_name: "",
        ecommerce_on_button: false,
        contact_team: false,
        years_of_experience: "",
        primary_city: "",
        store_presence: "",
        service_cities: [],
        appointment_requirement: ""
    },
    product_catalog: {
        lehenga_types: [],
        collection_type: "",
        design_style: [],
        color_options: []
    },
    core_intelligence: {
        silhouette_types: [],
        fabric_options: [],
        work_types: [],
        weight_category: "",
        dupatta_options: "",
        customization_depth: ""
    },
    fit_styling: {
        size_range: "",
        body_type_styling: [],
        trial_availability: "",
        alteration_support: "",
        styling_consultation: "",
        blouse_customization: ""
    },
    occasion_usage: {
        occasion_suitability: [],
        reusability: "",
        comfort_level: "",
        season_suitability: ""
    },
    pricing_logic: {
        pricing_model: "",
        starting_price_range: "",
        includes: [],
        add_ons: [],
        negotiation_flexibility: ""
    },
    production_delivery: {
        production_time: "",
        urgent_orders: "",
        delivery_options: [],
        packaging: ""
    },
    scale_operations: {
        orders_per_month: "",
        team_size: ""
    },
    workflow_booking: {
        advance_booking_time: "",
        booking_advance_percent: "",
        cancellation_policy: "",
        client_coordination: []
    },
    ai_tags: {
        lehenga_tags: [],
        style_tags: [],
        bride_type_tags: []
    },
    ai_faq: {
        customization_available: "",
        body_measurements: "",
        trial_fittings: "",
        styling_consultation: "",
        plus_size: "",
        delivery_outside_city: "",
        alterations_included: "",
        urgent_order: "",
        premium_designer: "",
        blouse_dupatta_included: "",
        custom_color_fabric: "",
        comfortable_long_wear: "",
        lightweight_options: "",
        appointment_required: "",
        reusable_after_wedding: ""
    }
});
