// Rental Outfit Master Profile Constants

export const VENDOR_TYPE = [
  "Rental Boutique",
  "Designer Rental Studio",
  "Multi-Designer Rental Platform",
  "Home-Based Rental Vendor",
];

export const STORE_PRESENCE = [
  "Physical Store",
  "Online Rental Platform",
  "Both",
];

export const STORE_ACCESS_TYPE = [
  "Walk-in Store",
  "Appointment Only",
  "Hybrid",
];

export const YEARS_OF_EXPERIENCE = ["0–2", "3–5", "6–10", "10+"];

export const INVENTORY_SPECIALIZATION = [
  "Bridal Lehenga",
  "Reception Lehenga",
  "Cocktail Lehenga",
  "Pre-Wedding Lehenga",
];

export const RENTAL_TYPES = [
  "Single Event Rental",
  "Multi-Day Rental",
  "Try-at-Home Rental",
];

export const TRIAL_AVAILABILITY = [
  "In-store Only",
  "Home Trial",
  "Both",
  "Not Available",
];

export const CUSTOMIZATION_ALTERATION = [
  "Minor Alterations Only",
  "Full Custom Fit",
  "Not Available",
];

export const YES_NO = ["Yes", "No"];

export const ACCESSORY_RENTAL = [
  "Dupatta",
  "Jewellery",
  "Veil",
  "Can-Can",
  "Blouse",
];

export const LEHENGA_STYLES = [
  "A-Line",
  "Circular / Flared",
  "Mermaid",
  "Panelled",
  "Jacket Lehenga",
  "Indo-Western",
];

export const OCCASION_SUITABILITY = [
  "Wedding Ceremony",
  "Reception",
  "Engagement",
  "Cocktail",
  "Sangeet",
];

export const WORK_TYPE = [
  "Zari",
  "Zardozi",
  "Sequins",
  "Thread Work",
  "Mirror Work",
  "Minimal",
];

export const FABRIC_OPTIONS = [
  "Velvet",
  "Silk",
  "Net",
  "Organza",
  "Georgette",
  "Raw Silk",
];

export const COLOR_PALETTE = [
  "Red / Maroon",
  "Pastels",
  "Jewel Tones",
  "Ivory / White",
  "Dual Tone",
];

export const DESIGNER_AVAILABILITY = [
  "In-house Designs",
  "Multi-Designer",
  "Replica Designer Wear",
];

export const DUPATTA_STYLES = [
  "Single Dupatta",
  "Double Dupatta",
  "Veil Style",
];

export const SIZE_RANGE = ["XS–S", "M–L", "XL–XXL", "Custom Fit"];

export const ADJUSTABILITY_RANGE = ["±1 Size", "±2 Sizes", "Not Adjustable"];

export const LEHENGA_WEIGHT = ["Lightweight", "Medium", "Heavy Bridal"];

export const BLOUSE_TYPE = ["Padded", "Non-Padded", "Custom Fit"];

export const DUPATTA_LENGTH = ["Standard", "Extended Bridal"];

export const CONDITION_QUALITY = ["Like New", "Lightly Used", "Moderate Wear"];

export const RENTAL_PRICE_RANGE = [
  "2K–10K",
  "10K–25K",
  "25K–50K",
  "50K–1L",
  "1L+",
];

export const DEPOSIT_AMOUNT_RANGE = ["0–5K", "5K–20K", "20K–50K", "50K+"];

export const DAMAGE_POLICY = [
  "Minor Damage Fee",
  "Full Replacement Cost",
  "Case-by-case",
];

export const CLEANING_CHARGES = ["Included", "Extra"];

export const TRIAL_CHARGES = [
  "Free",
  "Adjustable in Final Bill",
  "Paid Non-Adjustable",
];

export const INVENTORY_SIZE = ["<50", "50–150", "150–300", "300+"];

export const DAILY_TRIAL_CAPACITY = ["1–5", "5–10", "10–20", "20+"];

export const SIMULTANEOUS_RENTALS = ["<20", "20–50", "50–100", "100+"];

export const BOOKING_WINDOW = [
  "0–7 days prior",
  "7–30 days",
  "1–3 months",
  "3+ months",
];

export const FITTING_TIMELINE = [
  "Same Day",
  "1–3 days prior",
  "3–7 days prior",
];

export const PICKUP_TIMING = ["1 day before event", "Same day", "Flexible"];

export const RETURN_TIMELINE = ["Next Day", "Within 2 days", "Within 3 days"];

export const PAYMENT_MODES = [
  "UPI",
  "Cash",
  "Card",
  "Bank Transfer",
];

export const ADVANCE_PAYMENT_PERCENTAGE = ["25%", "50%", "75%", "100%"];

export const STYLE_TAGS = [
  "Royal Bridal",
  "Modern Bride",
  "Minimal Bride",
  "Bollywood Inspired",
];

export const AUDIENCE_TAGS = ["Bride", "Sister of Bride", "Bridesmaid"];

export const USAGE_TAGS = ["Wedding", "Reception", "Cocktail", "Pre-Wedding"];

export const PRICE_SEGMENT_TAGS = [
  "Budget Rental",
  "Mid-range Rental",
  "Premium Rental",
  "Luxury Rental",
];

export const emptyRentalOutfitMaster = () => ({
  identity: {
    vendor_type: "",
    brand_name: "",
    store_presence: [],
    city: "",
    store_access_type: "",
    years_of_experience: "",
    inventory_specialization: [],
  },
  services: {
    rental_types: [],
    trial_availability: "",
    customization_alteration: "",
    styling_assistance: "",
    accessory_rental: [],
    dry_cleaning_included: "",
    pickup_delivery_service: "",
    urgent_rental_availability: "",
  },
  core_intelligence: {
    lehenga_styles: [],
    occasion_suitability: [],
    work_type: [],
    fabric_options: [],
    color_palette: [],
    designer_availability: [],
    dupatta_styles: [],
  },
  technical: {
    size_range: [],
    adjustability_range: "",
    lehenga_weight: "",
    blouse_type: [],
    can_can_included: "",
    dupatta_length: "",
    condition_quality: "",
  },
  pricing: {
    rental_price_range: "",
    security_deposit_required: "",
    deposit_amount_range: "",
    late_return_charges: "",
    damage_policy: "",
    cleaning_charges: "",
    trial_charges: "",
  },
  scale: {
    inventory_size: "",
    daily_trial_capacity: "",
    simultaneous_rentals: "",
  },
  workflow: {
    advance_booking_required: "",
    booking_window: "",
    trial_appointment_required: "",
    fitting_timeline: "",
    pickup_timing: "",
    return_timeline: "",
    payment_modes: [],
    advance_payment_percentage: "",
  },
  portfolio: {
    style_tags: [],
    audience_tags: [],
    usage_tags: [],
    price_segment_tags: [],
  },
  ai_faq: {
    bridal_lehengas_on_rent: "",
    alteration_included: "",
    designer_lehengas: "",
    security_deposit: "",
    under_10k: "",
    home_trials: "",
    dry_cleaning_included: "",
    plus_sizes: "",
    multi_day_rental: "",
    accessories_included: "",
    urgent_rental: "",
    size_adjustments: "",
    pickup_delivery: "",
    heavy_bridal: "",
    trial_mandatory: "",
  },
});
