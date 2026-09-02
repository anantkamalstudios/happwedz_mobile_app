// SECTION 1: BASIC IDENTITY
export const VENDOR_TYPE_RENTAL = [
  "Individual Curator",
  "Rental Boutique",
  "Designer Rental Studio",
  "Online Rental Platform"
];

export const SERVICE_MODE = ["Store Visit", "Online Rental", "Both"];
export const DELIVERY_COVERAGE = ["Local Only", "Pan India", "International"];

// SECTION 2: PRODUCT CATEGORIES
export const JEWELLERY_TYPES_RENTAL = [
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

// SECTION 3: STYLE & DESIGN INTELLIGENCE
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

export const BEST_KNOWN_FOR_RENTAL = [
  "Bridal Sets",
  "Luxury Jewellery",
  "Budget Rentals",
  "Statement Pieces",
  "Custom Styling"
];

export const SUITABLE_FOR = ["Bridal", "Bridesmaids", "Family", "Reception Looks", "Cocktail Looks"];

export const STYLING_CONSULTATION = YES_NO;

// SECTION 4: MATERIAL & QUALITY
export const BASE_MATERIAL = ["Gold Plated", "Silver Based", "Alloy", "Mixed"];
export const FINISH_QUALITY = ["Premium Finish", "Standard Finish"];
export const REAL_VS_IMITATION = ["Imitation Jewellery", "Semi-Precious", "Both"];

// SECTION 5: RENTAL LOGIC
export const RENTAL_DURATION = ["1 Day", "2 Days", "3 Days", "Custom"];
export const RENTAL_PRICE_RANGE = [
  "Below ₹1K",
  "₹1K–₹3K",
  "₹3K–₹5K",
  "₹5K–₹10K",
  "₹10K+"
];

export const SECURITY_DEPOSIT = YES_NO;
export const DEPOSIT_AMOUNT_RANGE = [
  "Below ₹5K",
  "₹5K–₹10K",
  "₹10K–₹20K",
  "₹20K+"
];

export const LATE_RETURN_CHARGES = YES_NO;

// SECTION 6: AVAILABILITY & INVENTORY MANAGEMENT
export const ADVANCE_BOOKING_REQUIRED = YES_NO;
export const INVENTORY_SIZE = [
  "0–50 Pieces",
  "50–200 Pieces",
  "200–500 Pieces",
  "500+ Pieces"
];

export const MULTIPLE_PIECES = YES_NO;
export const AVAILABILITY_TRACKING = YES_NO;

// SECTION 7: DELIVERY & LOGISTICS
export const HOME_DELIVERY = YES_NO;
export const PICKUP_REQUIRED = YES_NO;
export const SHIPPING_CHARGES = [
  "Included",
  "Extra",
  "Depends on Location"
];

export const TRY_AT_HOME = YES_NO;

// SECTION 8: HYGIENE & QUALITY ASSURANCE
export const SANITIZATION_PROCESS = YES_NO;
export const DAMAGE_POLICY = [
  "Full Charge",
  "Partial Charge",
  "Case-by-Case"
];

export const REPLACEMENT_AVAILABLE = YES_NO;

// SECTION 9: EVENT SUITABILITY
export const FUNCTIONS_SUITABLE_FOR_RENTAL = [
  "Haldi",
  "Mehendi",
  "Sangeet",
  "Wedding",
  "Reception",
  "Cocktail"
];

export const BEST_FOR_RENTAL = [
  "Bridal Looks",
  "Budget Weddings",
  "Luxury Weddings",
  "Destination Weddings"
];

// SECTION 10: WORKFLOW & BOOKING
export const ADVANCE_PERCENTAGE = ["25%", "50%", "75%"];
export const CANCELLATION_POLICY = ["Non Refundable", "Partial Refund", "Flexible"];
export const REFUND_TIMELINE = ["3 Days", "7 Days", "15 Days"];

// AI FAQ Constants
export const AI_FAQ_BRIDAL_SETS = "Do you offer bridal jewellery sets?";
export const AI_FAQ_RENTAL_DURATION = "What is the rental duration?";
export const AI_FAQ_SECURITY_DEPOSIT = "Is security deposit required?";
export const AI_FAQ_DEPOSIT_AMOUNT = "What is the deposit amount?";
export const AI_FAQ_HOME_DELIVERY = "Is home delivery available?";
export const AI_FAQ_TRY_AT_HOME = "Is try-at-home service available?";
export const AI_FAQ_STYLING = "Is styling consultation available?";
export const AI_FAQ_JEWELLERY_TYPES = "What jewellery types are offered?";
export const AI_FAQ_OCCASIONS = "Suitable for which occasions?";
export const AI_FAQ_INVENTORY_SIZE = "What is the inventory size?";
export const AI_FAQ_REPLACEMENT = "Is replacement available?";
export const AI_FAQ_DAMAGE_POLICY = "What is the damage policy?";
export const AI_FAQ_ADVANCE = "Is advance required?";
export const AI_FAQ_CANCELLATION = "What is the cancellation policy?";
export const AI_FAQ_BEST_FOR = "What are you best known for?";

export const emptyJewelleryRentalMaster = () => ({
  identity: {
    brand_name: "",
    vendor_type: "",
    years_of_experience: "",
    city: "",
    service_mode: "",
    delivery_coverage: ""
  },
  product_categories: {
    jewellery_types: [],
    bridal_package: "",
    set_includes: []
  },
  style_design: {
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
  availability: {
    advance_booking_required: "",
    inventory_size: "",
    multiple_pieces_available: "",
    availability_tracking: ""
  },
  delivery_logistics: {
    home_delivery: "",
    pickup_required: "",
    shipping_charges: "",
    try_at_home: ""
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
  ai_faq: {
    bridal_sets: "",
    rental_duration: "",
    security_deposit: "",
    deposit_amount: "",
    home_delivery: "",
    try_at_home: "",
    styling_consultation: "",
    jewellery_types: "",
    occasions: "",
    inventory_size: "",
    replacement: "",
    damage_policy: "",
    advance_required: "",
    cancellation: "",
    best_known_for: ""
  }
});
