// ACCESSORIES VENDORS - Master Constants

export const VENDOR_TYPE = [
    "Retail Store",
    "Online Store",
    "Rental Boutique",
    "Designer Studio",
    "Multi-Brand Store"
];

export const SERVICE_MODE = ["Store Visit", "Online", "Both"];

export const DELIVERY_COVERAGE = ["Local Only", "Pan India", "International"];

export const ACCESSORIES_TYPES = [
    "Clutches / Potlis",
    "Footwear (Heels / Juttis / Mojris)",
    "Hair Accessories",
    "Veils",
    "Belts",
    "Dupatta Accessories",
    "Brooches",
    "Cufflinks",
    "Pocket Squares",
    "Safa / Pagdi",
    "Sunglasses",
    "Bridal Chooda",
    "Kaleere"
];

export const GENDER_FOCUS = ["Women", "Men", "Unisex"];

export const YES_NO = ["Yes", "No"];

export const STYLE_CATEGORIES = [
    "Traditional",
    "Contemporary",
    "Fusion",
    "Minimal",
    "Statement",
    "Luxury",
    "Budget"
];

export const BEST_KNOWN_FOR = [
    "Bridal Accessories",
    "Groom Styling",
    "Budget Products",
    "Luxury Pieces",
    "Custom Designs"
];

export const SUITABLE_FOR = [
    "Bridal",
    "Groom",
    "Bridesmaids",
    "Family Members",
    "Guests"
];

export const MATERIALS_USED = [
    "Fabric",
    "Leather",
    "Metal",
    "Artificial",
    "Mixed"
];

export const QUALITY_TIER = ["Budget", "Premium", "Luxury"];

export const PRODUCT_MODE = ["Sale Only", "Rental Only", "Both"];

export const RENTAL_DURATION = ["1 Day", "2 Days", "3 Days", "Custom"];

export const PRICE_RANGE = [
    "Below ₹500",
    "₹500–₹1000",
    "₹1000–₹3000",
    "₹3000–₹5000",
    "₹5000+"
];

export const CUSTOMIZATION_TIME = [
    "2–3 Days",
    "1 Week",
    "2 Weeks",
    "1 Month"
];

export const INVENTORY_SIZE = [
    "0–50 Products",
    "50–200 Products",
    "200–500 Products",
    "500+ Products"
];

export const SHIPPING_CHARGES = [
    "Included",
    "Extra",
    "Depends on Location"
];

export const FUNCTIONS_SUITABLE_FOR = [
    "Haldi",
    "Mehendi",
    "Sangeet",
    "Wedding",
    "Reception",
    "Cocktail"
];

export const BEST_FOR = [
    "Bridal Styling",
    "Groom Styling",
    "Budget Weddings",
    "Luxury Weddings",
    "Destination Weddings"
];

export const ADVANCE_PERCENTAGE = ["25%", "50%", "75%"];

export const CANCELLATION_POLICY = ["Non Refundable", "Partial Refund", "Flexible"];

export const RETURN_POLICY = [
    "No Return",
    "Return Within 24 Hours",
    "Return Within 48 Hours"
];

export const AI_FAQ_PRODUCT_MODE = ["Sale Only", "Rental Only", "Both"];

export const AI_FAQ_PRICE_RANGE = [
    "Below ₹500",
    "₹500–₹1000",
    "₹1000–₹3000",
    "₹3000–₹5000",
    "₹5000+"
];

export const AI_FAQ_CUSTOMIZATION = ["Yes", "No"];

export const AI_FAQ_RENTAL_DURATION = ["1 Day", "2 Days", "3 Days", "Custom"];

export const AI_FAQ_INVENTORY_SIZE = [
    "0–50 Products",
    "50–200 Products",
    "200–500 Products",
    "500+ Products"
];

export const AI_FAQ_CANCELLATION = ["Non Refundable", "Partial Refund", "Flexible"];

export const AI_FAQ_RETURN_POLICY = [
    "No Return",
    "Return Within 24 Hours",
    "Return Within 48 Hours"
];

export const emptyAccessoriesMaster = () => ({
    identity: {
        brand_name: "",
        vendor_type: "",
        years_of_experience: "",
        city: "",
        service_mode: "",
        delivery_coverage: ""
    },
    product_categories: {
        accessories_types: [],
        gender_focus: "",
        bridal_accessories: "",
        groom_accessories: ""
    },
    style_intelligence: {
        style_categories: [],
        best_known_for: [],
        suitable_for: [],
        outfit_matching: "",
        styling_consultation: ""
    },
    material_quality: {
        materials_used: [],
        quality_tier: "",
        handmade_products: ""
    },
    sales_rental_logic: {
        product_mode: "",
        rental_duration: "",
        price_range: "",
        security_deposit: "",
        custom_orders: "",
        customization_time: ""
    },
    inventory: {
        inventory_size: "",
        multiple_pieces: "",
        real_time_tracking: ""
    },
    logistics: {
        home_delivery: "",
        store_pickup: "",
        shipping_charges: "",
        try_at_home: ""
    },
    event_suitability: {
        functions_suitable_for: [],
        best_for: []
    },
    workflow: {
        advance_required: "",
        advance_percentage: "",
        cancellation_policy: "",
        return_policy: ""
    },
    ai_faq: {
        bridal_accessories: "",
        groom_accessories: "",
        product_mode: "",
        customization_available: "",
        price_range: "",
        try_at_home_available: "",
        styling_consultation_available: "",
        outfit_matching_support: "",
        delivery_available: "",
        return_policy: "",
        rental_duration: "",
        inventory_size: "",
        advance_required: "",
        cancellation_policy: "",
        best_known_for: ""
    }
});
