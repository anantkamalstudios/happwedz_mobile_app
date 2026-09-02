export const VENDOR_TYPE = [
    "Designer Boutique",
    "Multi-Designer Store",
    "Custom Gown Studio",
    "Retail Brand",
    "Luxury Couture House"
];

export const YEARS_OF_EXPERIENCE = ["0–1", "1–3", "3–5", "5–10", "10+"];

export const STORE_PRESENCE = ["Studio Only", "Retail Store", "Both"];

export const SERVICE_CITIES = ["Pan-India Shipping", "International Shipping"];

export const APPOINTMENT_REQUIREMENT = ["Mandatory", "Optional", "Walk-in Allowed"];

export const GOWN_TYPES = [
    "Cocktail Party Gown",
    "Reception Gown",
    "Engagement Gown",
    "After-Party Gown",
    "Pre-Wedding Shoot Gown"
];

export const COLLECTION_TYPE = ["Ready-to-Wear", "Made-to-Order", "Custom Designed", "Hybrid"];

export const DESIGN_STYLE = [
    "Minimal Elegant",
    "Glam / Sequined",
    "Indo-Western",
    "Western Formal",
    "Red Carpet Style",
    "Contemporary Fusion"
];

export const COLOR_PALETTE = ["Black", "Red", "Metallic (Gold/Silver)", "Pastels", "Jewel Tones", "Nude / Beige", "Custom"];

export const SILHOUETTE_TYPES = [
    "A-line",
    "Ball Gown",
    "Mermaid / Trumpet",
    "Sheath / Column",
    "Empire Waist",
    "High Slit"
];

export const NECKLINE_TYPES = [
    "Sweetheart",
    "Off-Shoulder",
    "Strapless",
    "Halter",
    "V-Neck",
    "High Neck",
    "One-Shoulder"
];

export const SLEEVE_TYPES = ["Sleeveless", "Cap Sleeves", "Full Sleeves", "Detachable Sleeves"];

export const FABRIC_OPTIONS = ["Satin", "Silk", "Tulle", "Net", "Organza", "Velvet", "Crepe"];

export const EMBELLISHMENT_TYPES = ["Sequins", "Beads", "Crystals", "Embroidery", "Feathers", "Minimal / Plain"];

export const TRAIN_LENGTH = ["No Train", "Sweep Train", "Chapel Train", "Custom"];

export const WEIGHT_CATEGORY = ["Lightweight", "Medium", "Heavy"];

export const SIZE_RANGE = ["XS", "S", "M", "L", "XL", "XXL", "Custom Size"];

export const BODY_TYPE_STYLING = ["Petite", "Tall", "Plus Size", "Hourglass", "Pear Shape", "Rectangle"];

export const FIT_TYPE = ["Body-hugging", "Relaxed Fit", "Structured Fit"];

export const YES_NO = ["Yes", "No"];

export const ALTERATION_SUPPORT = ["Included", "Chargeable", "Not Available"];

export const OCCASION_SUITABILITY = ["Cocktail Night", "Reception", "Engagement", "After Party"];

export const REUSABILITY = ["High", "Medium", "Low"];

export const COMFORT_LEVEL = ["High", "Moderate", "Heavy Wear"];

export const SEASON_SUITABILITY = ["Summer", "Winter", "All Season"];

export const PRICING_MODEL = ["Per Outfit", "Custom Pricing", "Designer Tier"];

export const PRICE_RANGE = ["₹10k–₹30k", "₹30k–₹70k", "₹70k–₹1.5L", "₹1.5L–₹3L", "₹3L+"];

export const INCLUDES = ["Gown", "Customization", "Alterations", "Styling"];

export const ADD_ONS = ["Accessories", "Rush Orders", "Premium Fabrics", "Extra Embellishments"];

export const NEGOTIATION_FLEXIBILITY = ["Fixed", "Moderate", "Flexible"];

export const PRODUCTION_TIME = ["Ready Stock", "1–3 weeks", "3–6 weeks", "6–10 weeks"];

export const DELIVERY_OPTIONS = ["Store Pickup", "Home Delivery", "International Shipping"];

export const PACKAGING = ["Basic", "Premium Box", "Luxury Packaging"];

export const ORDERS_PER_MONTH = ["<20", "20–50", "50–100", "100+"];

export const TEAM_SIZE = ["Solo Designer", "2–5", "5–10", "10+"];

export const ADVANCE_BOOKING_TIME = ["<1 week", "1–3 weeks", "1–2 months", "2–4 months"];

export const BOOKING_ADVANCE = ["25%", "50%", "75%", "100%"];

export const CANCELLATION_POLICY = ["Non-refundable", "Partial refund", "Flexible"];

export const CLIENT_COORDINATION = ["WhatsApp", "Call", "In-person", "App-based"];

export const GOWN_TAGS = ["Luxury Gowns", "Budget Gowns", "Designer Couture", "Custom Gowns"];

export const STYLE_TAGS = ["Glamorous", "Minimal", "Modern", "Red Carpet"];

export const BRIDE_TYPE_TAGS = ["Modern Bride", "Experimental Bride", "Elegant Bride"];

export const emptyCocktailGownMaster = () => ({
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
        gown_types: [],
        collection_type: "",
        design_style: [],
        color_palette: []
    },
    core_intelligence: {
        silhouette_types: [],
        neckline_types: [],
        sleeve_types: "",
        fabric_options: [],
        embellishment_types: [],
        train_length: "",
        weight_category: ""
    },
    fit_styling: {
        size_range: "",
        body_type_styling: [],
        fit_type: "",
        trial_availability: "",
        alteration_support: "",
        styling_consultation: "",
        accessory_styling_support: ""
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
        gown_tags: [],
        style_tags: [],
        bride_type_tags: []
    },
    ai_faq: {
        customizable: "",
        body_measurements: "",
        trial_fittings: "",
        styling_consultation: "",
        plus_size: "",
        delivery_outside_city: "",
        alterations_included: "",
        urgent_order: "",
        premium_designer: "",
        custom_color_fabric: "",
        comfortable_long_events: "",
        lightweight_options: "",
        appointment_required: "",
        reusable: "",
        accessory_styling: ""
    }
});
