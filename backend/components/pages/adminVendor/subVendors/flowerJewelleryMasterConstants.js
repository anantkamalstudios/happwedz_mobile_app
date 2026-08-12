export const VENDOR_TYPE = [
    "Individual Designer",
    "Home-Based Business",
    "Studio",
    "Boutique Brand"
];

export const SERVICE_COVERAGE = ["Local Only", "Pan India", "International"];

export const DELIVERY_MODE = ["Pickup Only", "Home Delivery", "Both"];

export const JEWELLERY_ITEMS = [
    "Necklace",
    "Earrings",
    "Maang Tikka",
    "Matha Patti",
    "Bracelet",
    "Bangles",
    "Anklets",
    "Waist Belt (Kamarbandh)",
    "Hair Accessories",
    "Kaleere"
];

export const JEWELLERY_ITEMS_OFFERED = JEWELLERY_ITEMS;

export const YES_NO = ["Yes", "No"];

export const COMPLETE_SET_INCLUDES = [
    "Necklace",
    "Earrings",
    "Maang Tikka",
    "Bangles",
    "Kaleere",
    "Customisable"
];

export const FLOWER_TYPE = ["Fresh Flowers", "Artificial Flowers", "Both"];

export const FRESH_FLOWER_TYPES = [
    "Roses",
    "Marigold",
    "Orchids",
    "Jasmine",
    "Baby’s Breath",
    "Mixed Flowers",
    "Tagar",
    "Mogra"
];

export const ARTIFICIAL_MATERIAL = ["Fabric Flowers", "Foam Flowers", "Paper Flowers"];

export const DURABILITY = ["6–8 Hours", "8–12 Hours", "12–24 Hours", "Multi-Day"];

export const STYLE_CATEGORIES = [
    "Traditional",
    "Minimal",
    "Floral Heavy",
    "Pastel Theme",
    "Vibrant Theme",
    "Contemporary"
];

export const BEST_KNOWN_FOR = [
    "Haldi Jewellery",
    "Mehendi Jewellery",
    "Fresh Flower Designs",
    "Lightweight Jewellery",
    "Custom Designs"
];

export const SUITABLE_FOR = ["Bride", "Bridesmaids", "Family Members", "Guests"];

export const CUSTOM_DESIGN_INPUTS = ["Outfit Color", "Theme", "Function Type", "Personal Preference"];

export const FUNCTIONS_SUITABLE_FOR = ["Haldi", "Mehendi", "Pre-Wedding Shoot", "Engagement", "Baby Shower"];

export const BEST_FUNCTION = ["Haldi", "Mehendi", "Both"];

export const PRICING_TYPE = ["Per Piece", "Per Set", "Package"];

export const BRIDAL_SET_PRICE_RANGE = ["Below ₹1000", "₹1000–₹3000", "₹3000–₹5000", "₹5000+", "All Ranges Available"];

export const BULK_PRICING = ["Discount Available", "No Discount"];

export const ORDER_PREP_TIME = ["Same Day", "1 Day", "2–3 Days", "5+ Days"];

export const DELIVERY_TIMING = ["Same Day", "Next Day", "Scheduled Delivery"];

export const DAMAGE_HANDLING = ["Replacement", "No Replacement", "Case-by-Case"];

export const DAILY_ORDER_CAPACITY = ["0–10 Orders", "10–30 Orders", "30–50 Orders", "50+ Orders"];

export const PEAK_SEASON_AVAILABILITY = ["Limited", "Moderate", "High"];

export const ADVANCE_PERCENTAGE = ["25%", "50%", "75%"];

export const CANCELLATION_POLICY = ["Non Refundable", "Partial Refund", "Flexible"];

export const REFUND_TIMELINE = ["1 Day", "3 Days", "7 Days"];

export const STORAGE_FACILITIES = ["Climate Control", "Refrigeration", "Standard Storage"];

export const CUSTOMIZATION_CAPABILITIES = ["Design Consultation", "Outfit Matching", "Personal Preference"];

export const DELIVERY_FEATURES = ["Same-Day Delivery", "Gift Wrapping", "Premium Packaging"];

export const emptyFlowerJewelleryMaster = () => ({
    identity: {
        brand_name: "",
        vendor_type: "",
        years_of_experience: "",
        city: "",
        service_coverage: "",
        delivery_mode: ""
    },
    product_categories: {
        jewellery_items: [],
        bridal_set_available: "",
        set_includes: []
    },
    material_type: {
        flower_type: "",
        fresh_flower_types: [],
        artificial_material: [],
        durability: ""
    },
    style_design: {
        style_categories: [],
        best_known_for: [],
        suitable_for: [],
        outfit_matching_support: "",
        customization_available: "",
        custom_design_inputs: []
    },
    function_specific: {
        functions_suitable_for: [],
        best_function: ""
    },
    facilities: {
        storage_facilities: "",
        customization_capabilities: [],
        delivery_features: []
    },
    pricing_logic: {
        starting_price: "",
        pricing_type: "",
        bridal_set_price_range: "",
        bulk_orders_supported: "",
        bulk_pricing: ""
    },
    delivery_timing: {
        order_prep_time: "",
        delivery_timing: "",
        time_slot_delivery: "",
        early_morning_delivery: ""
    },
    storage_handling: {
        storage_instructions: "",
        replacement_policy: "",
        damage_handling: ""
    },
    inventory_availability: {
        daily_order_capacity: "",
        advance_booking_required: "",
        peak_season_availability: ""
    },
    workflow_booking: {
        advance_required: "",
        advance_percentage: "",
        cancellation_policy: "",
        refund_timeline: ""
    },
    ai_faq: {
        bridal_flower_jewellery: "",
        flower_type: "",
        customization_available: "",
        suitable_function: "",
        delivery_available: "",
        same_day_delivery: "",
        durability: "",
        bulk_orders_supported: "",
        outfit_matching_support: "",
        preparation_time: "",
        replacement_policy: "",
        advance_required: "",
        cancellation_policy: "",
        price_range: "",
        best_known_for: ""
    }
});

export const AI_FAQ_FLOWER_TYPE = ["Fresh Flowers", "Artificial Flowers", "Both"];
export const AI_FAQ_CUSTOMIZATION = ["Yes", "No"];
export const AI_FAQ_SUITABLE_FUNCTION = ["Haldi", "Mehendi", "Pre-Wedding Shoot", "Engagement", "Baby Shower"];
export const AI_FAQ_DELIVERY_AVAILABLE = ["Yes", "No"];
export const AI_FAQ_SAME_DAY_DELIVERY = ["Yes", "No"];
export const AI_FAQ_DURABILITY = ["6–8 Hours", "8–12 Hours", "12–24 Hours", "Multi-Day"];
export const AI_FAQ_BULK_ORDERS = ["Yes", "No"];
export const AI_FAQ_OUTFIT_MATCHING = ["Yes", "No"];
export const AI_FAQ_PREPARATION_TIME = ["Same Day", "1 Day", "2–3 Days", "5+ Days"];
export const AI_FAQ_REPLACEMENT_POLICY = ["Yes", "No"];
export const AI_FAQ_ADVANCE_REQUIRED = ["Yes", "No"];
export const AI_FAQ_CANCELLATION = ["Non Refundable", "Partial Refund", "Flexible"];
export const AI_FAQ_PRICE_RANGE = ["Below ₹1000", "₹1000–₹3000", "₹3000–₹5000", "₹5000+", "All Ranges Available"];
export const AI_FAQ_BEST_KNOWN_FOR = ["Haldi Jewellery", "Mehendi Jewellery", "Fresh Flower Designs", "Lightweight Jewellery", "Custom Designs"];
