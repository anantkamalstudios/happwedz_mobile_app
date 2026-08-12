export const VENDOR_TYPE = [
    "Individual Curator",
    "Rental Boutique",
    "Designer Rental Studio",
    "Online Rental Platform"
];

export const SERVICE_MODE = ["Store Visit", "Online Rental", "Both"];

export const JEWELLERY_CITIES = ["Delhi", "Mumbai", "Bangalore", "Hyderabad", "Chennai", "Kolkata", "Pune", "Ahmedabad"];

export const DELIVERY_COVERAGE = ["Local Only", "Pan India", "International"];

export const JEWELLERY_TYPES = [
    "Bridal Sets",
    "Necklace Sets",
    "Choker Sets",
    "Long Haar",
    "Earrings",
    "Maang Tikka",
    "Matha Patti",
    "Nath",
    "Bangles",
    "Finger Ring",
    "Hath phool",
    "Kada",
    "Anklets",
    "Waist Belt (Kamarbandh)"
];

export const JEWELLERY_TYPES_OFFERED = [
    "Bridal Sets",
    "Necklace Sets",
    "Choker Sets",
    "Long Haar",
    "Earrings",
    "Maang Tikka",
    "Matha Patti",
    "Nath",
    "Bangles",
    "Finger Ring",
    "Hath phool",
    "Kada",
    "Anklets",
    "Waist Belt (Kamarbandh)"
];

export const YES_NO = ["Yes", "No"];

export const COMPLETE_SET_INCLUDES = [
    "Necklace",
    "Earrings",
    "Maang Tikka",
    "Nath",
    "Bangles",
    "Waist Belt"
];

export const JEWELLERY_STYLE = [
    "Traditional",
    "Contemporary",
    "Temple Jewellery",
    "Polki",
    "Kundan",
    "Moti (Pearl)",
    "American Diamond",
    "Oxidized",
    "Antique Finish",
    "Minimal",
    "Statement"
];

export const BEST_KNOWN_FOR = [
    "Bridal Sets",
    "Luxury Jewellery",
    "Budget Rentals",
    "Statement Pieces",
    "Custom Styling"
];

export const SUITABLE_FOR = [
    "Bridal",
    "Bridesmaids",
    "Family",
    "Reception Looks",
    "Cocktail Looks"
];

export const BASE_MATERIAL = [
    "Gold Plated",
    "Silver Based",
    "Alloy",
    "Mixed"
];

export const FINISH_QUALITY = ["Premium Finish", "Standard Finish"];

export const REAL_VS_IMITATION = ["Imitation Jewellery", "Semi-Precious", "Both"];

export const RENTAL_DURATION = ["1 Day", "2 Days", "3 Days", "Custom"];

export const RENTAL_PRICE_RANGE = ["Below ₹1K", "₹1K–₹3K", "₹3K–₹5K", "₹5K–₹10K", "₹10K+"];

export const SECURITY_DEPOSIT_RANGE = ["Below ₹5K", "₹5K–₹10K", "₹10K–₹20K", "₹20K+"];

export const DEPOSIT_AMOUNT_RANGE = ["Below ₹5K", "₹5K–₹10K", "₹10K–₹20K", "₹20K+"];

export const INVENTORY_SIZE = ["0–50 Pieces", "50–200 Pieces", "200–500 Pieces", "500+ Pieces"];

export const SHIPPING_CHARGES = ["Included", "Extra", "Depends on Location"];

export const DAMAGE_POLICY = ["Full Charge", "Partial Charge", "Case-by-Case"];

export const FUNCTIONS_SUITABLE_FOR = ["Haldi", "Mehendi", "Sangeet", "Wedding", "Reception", "Cocktail"];

export const BEST_FOR = ["Bridal Looks", "Budget Weddings", "Luxury Weddings", "Destination Weddings"];

export const ADVANCE_PERCENTAGE = ["25%", "50%", "75%"];

export const CANCELLATION_POLICY = ["Non Refundable", "Partial Refund", "Flexible"];

export const REFUND_TIMELINE = ["3 Days", "7 Days", "15 Days"];

export const AI_FAQ_RENTAL_DURATION = ["1 Day", "2 Days", "3 Days", "Custom"];

export const AI_FAQ_DEPOSIT_AMOUNT = ["Below ₹5K", "₹5K–₹10K", "₹10K–₹20K", "₹20K+"];

export const AI_FAQ_INVENTORY_SIZE = ["0–50 Pieces", "50–200 Pieces", "200–500 Pieces", "500+ Pieces"];

export const AI_FAQ_DAMAGE_POLICY = ["Full Charge", "Partial Charge", "Case-by-Case"];

export const AI_FAQ_CANCELLATION = ["Non Refundable", "Partial Refund", "Flexible"];

export const AI_FAQ_BEST_KNOWN_FOR = ["Bridal Sets", "Luxury Jewellery", "Budget Rentals", "Statement Pieces", "Custom Styling"];

export const emptyJewelleryMaster = () => ({
    identity: {
        brand_store_name: "",
        vendor_type: "",
        years_of_experience: "",
        cities: [],
        service_mode: "",
        delivery_coverage: ""
    },
    product_categories: {
        jewellery_types_offered: [],
        bridal_package_available: "",
        complete_set_includes: []
    },
    style_design_intelligence: {
        jewellery_style: [],
        best_known_for: [],
        suitable_for: [],
        outfit_matching_support: "",
        styling_consultation: ""
    },
    material_quality: {
        base_material: [],
        finish_quality: "",
        real_vs_imitation: ""
    },
    rental_logic: {
        rental_duration: "",
        rental_price_range: "",
        security_deposit: "",
        deposit_amount_range: "",
        late_return_charges: ""
    },
    availability_inventory: {
        advance_booking_required: "",
        inventory_size: "",
        multiple_pieces_available: "",
        realtime_availability_tracking: ""
    },
    delivery_logistics: {
        home_delivery_available: "",
        pickup_required: "",
        shipping_charges: "",
        try_at_home_service: ""
    },
    hygiene_quality: {
        sanitization_process: "",
        damage_policy: "",
        replacement_available: ""
    },
    event_suitability: {
        functions_suitable_for: [],
        best_for: []
    },
    workflow_booking: {
        advance_required: "",
        advance_percentage: "",
        cancellation_policy: "",
        refund_timeline: ""
    },
    portfolio_tagging: {
        tagging_guidance: "",
        notes: ""
    },
    ai_faq: {
        bridal_jewellery_sets: "",
        rental_duration: "",
        security_deposit_required: "",
        deposit_amount: "",
        home_delivery_available: "",
        try_at_home_service: "",
        styling_consultation_available: "",
        jewellery_types_offered: [],
        suitable_occasions: [],
        inventory_size: "",
        replacement_available: "",
        damage_policy: "",
        advance_required: "",
        cancellation_policy: "",
        best_known_for: ""
    }
});
