export const CATERER_TYPES = [
  "Individual Caterer",
  "Catering Company",
  "Luxury Catering Specialist",
  "Cloud Kitchen Caterer",
];

export const SERVICE_COVERAGE = ["Local Only", "Pan India", "International"];
export const TEAM_SIZE = ["1-10", "10-30", "30-100", "100+"];
export const SERVICE_LOCATIONS = [
  "All cities",
  "All Over India",
  "Western India",
  "Northern India",
  "Southern India",
  "Eastern India",
];

export const CATERING_STYLE = [
  "Buffet",
  "Plated Service",
  "Live Counters",
  "Food Stalls",
  "Fine Dining",
  "Traditional Service (Pangat)",
];
export const EVENT_TYPES = ["Breakfast", "Lunch", "Dinner", "Hi-Tea", "Cocktail"];
export const VEG_NON_VEG = ["Pure Veg", "Veg + Non-Veg"];
export const SPECIAL_DIETARY = ["Vegan", "Gluten-Free", "Satvik", "Jain"];

export const CUISINE_TYPES = [
  "North Indian",
  "South Indian",
  "Maharashtrian",
  "Gujarati",
  "Rajasthani",
  "Punjabi",
  "Continental",
  "Italian",
  "Chinese",
  "Thai",
  "Mexican",
  "Street Food",
  "Fusion",
];
export const BEST_KNOWN_FOR = [
  "Taste",
  "Presentation",
  "Live Counters",
  "Variety",
  "Budget Catering",
  "Luxury Catering",
];

export const TASTING_CHARGES = ["Free", "Paid", "Adjustable"];
export const MENU_ITEMS_OFFERED = ["10-20", "20-40", "40-60", "60+"];
export const LIVE_COUNTERS = [
  "Chaat",
  "Pasta",
  "Pizza",
  "Dosa",
  "Chinese",
  "Mocktails",
  "Desserts",
];

export const MAX_PAX = ["0-100", "100-300", "300-500", "500-1000", "1000+"];
export const EVENTS_PER_DAY = ["1", "2-3", "3+"];

export const PRICE_RANGE = [
  "Below ₹500",
  "₹500-₹1000",
  "₹1000-₹1500",
  "₹1500-₹2500",
  "₹2500+",
];
export const PRICING_TYPE = ["Per Plate", "Package Based", "Custom Quote"];
export const EXTRA_CHARGES = [
  "Service Charges",
  "GST",
  "Setup Charges",
  "Staff Charges",
];

export const KITCHEN_SETUP = ["In-House Kitchen", "On-Site Setup", "Both"];
export const SERVING_STYLE = [
  "Uniformed Staff",
  "Traditional Dress",
  "Custom Dress",
];
export const CROCKERY = ["Included", "Extra"];

export const HYGIENE_STANDARDS = [
  "Gloves & Caps",
  "Sanitized Kitchen",
  "Food Safety Certified",
  "FSSAI Licensed",
];
export const FOOD_QUALITY_ASSURANCE = ["High", "Premium", "Luxury"];

export const TRAVEL_CHARGES = ["Included", "Extra", "Depends"];

export const FUNCTIONS_SUITABLE = [
  "Haldi",
  "Mehendi",
  "Sangeet",
  "Wedding",
  "Reception",
  "Cocktail",
];
export const BEST_FOR = [
  "Budget Weddings",
  "Luxury Weddings",
  "Large Gatherings",
  "Intimate Weddings",
  "Destination Weddings",
];

export const ADVANCE_PERCENTAGE = ["25%", "50%", "75%"];
export const BOOKING_TIMELINE = ["1 Month Before", "3 Months Before", "6 Months Before"];
export const CANCELLATION_POLICY = ["Non Refundable", "Partial Refund", "Flexible"];
export const REFUND_TIMELINE = ["7 Days", "15 Days", "30 Days"];

export function emptyCatererMaster() {
  return {
    identity: {
      brand_name: "",
      caterer_type: "",
      years_experience: "",
      service_coverage: "",
      team_size: "",
      service_locations: [],
    },
    service_type: {
      catering_style: [],
      event_types_covered: [],
      veg_non_veg: "",
      jain_food: "",
      special_dietary_options: [],
    },
    cuisine_intelligence: {
      cuisine_types: [],
      signature_dishes: "",
      best_known_for: [],
    },
    menu_customization: {
      custom_menu_available: "",
      menu_tasting_available: "",
      tasting_charges: "",
      menu_items_offered: "",
      live_counters_available: "",
      popular_live_counters: [],
    },
    scale_execution: {
      minimum_pax: "",
      maximum_pax: "",
      events_per_day: "",
      multiple_event_handling: "",
    },
    pricing_structure: {
      per_plate_starting_price: "",
      price_range: "",
      pricing_type: "",
      extra_charges: [],
    },
    infrastructure_equipment: {
      kitchen_setup: "",
      serving_staff_included: "",
      serving_style: "",
      utensils_crockery: "",
      eco_friendly_options: "",
    },
    hygiene_quality: {
      hygiene_standards: [],
      food_quality_assurance: "",
    },
    venue_logistics: {
      outdoor_catering_supported: "",
      destination_weddings_supported: "",
      travel_charges: "",
      stay_requirement: "",
    },
    event_suitability: {
      functions_suitable_for: [],
      best_for: [],
    },
    workflow_booking: {
      advance_required: "",
      advance_percentage: "",
      booking_timeline: "",
      cancellation_policy: "",
      refund_timeline: "",
    },
    menu_event_tagging: {
      notes: "",
      tags: "Cuisine, Event Type, Guest Count, Price Range, Service Style",
    },
  };
}
