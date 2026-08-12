export const DECORATOR_TYPE = [
  "Individual",
  "Boutique Decor Studio",
  "Full-Service Decor Company",
  "Luxury Decor Specialist"
];

export const SERVICE_COVERAGE_DECORATOR = [
  "Local Only",
  "Pan India",
  "International"
];

export const TEAM_SIZE = ["1–5", "5–15", "15–30", "30+"];

export const SERVICES_OFFERED_DECORATOR = [
  "Wedding Decor",
  "Haldi Setup",
  "Mehendi Setup",
  "Sangeet Stage",
  "Reception Stage",
  "Mandap Decor",
  "Entry Decor",
  "Photo Booth",
  "Thematic Decor",
  "Lighting Decor",
  "Floral Decor"
];

export const DECOR_SCOPE = [
  "Full Venue Decor",
  "Stage Only",
  "Mandap Only",
  "Entry Decor Only",
  "Custom Setup"
];

export const THEMES_EXPERTISE = [
  "Royal",
  "Minimal",
  "Floral",
  "Bohemian",
  "Vintage",
  "Bollywood",
  "Rustic",
  "Contemporary",
  "Traditional",
  "Destination Theme"
];

export const DECOR_STYLE = [
  "Luxury",
  "Budget-Friendly",
  "Premium",
  "Designer",
  "Minimalistic"
];

export const BEST_KNOWN_FOR_DECORATOR = [
  "Floral Installations",
  "Grand Stage Designs",
  "Minimal Decor",
  "Unique Concepts",
  "Luxury Weddings",
  "Budget Transformations"
];

export const IDEAL_WEDDING_TYPE = [
  "Budget Weddings",
  "Luxury Weddings",
  "Destination Weddings",
  "Intimate Weddings",
  "Large Weddings"
];

export const MATERIALS_USED = [
  "Fresh Flowers",
  "Artificial Flowers",
  "Fabric Drapes",
  "Wooden Structures",
  "Metal Structures",
  "LED Elements",
  "Props & Installations"
];

export const FLORAL_EXPERTISE = ["Fresh Only", "Artificial Only", "Both"];

export const MAX_GUEST_CAPACITY = [
  "Up to 100",
  "100–300",
  "300–500",
  "500–1000",
  "1000+"
];

export const SETUP_TIME_REQUIRED = ["Same Day", "1 Day", "2 Days", "3+ Days"];

export const FUNCTIONS_COVERED_DECORATOR = [
  "Haldi",
  "Mehendi",
  "Sangeet",
  "Wedding",
  "Reception",
  "Engagement",
  "Cocktail"
];

export const BEST_FUNCTION_EXPERTISE = [
  "Haldi Decor",
  "Mandap Decor",
  "Sangeet Stage",
  "Reception Stage",
  "Entry Decor"
];

export const PRICING_TYPE_DECORATOR = [
  "Per Event",
  "Package Based",
  "Custom Quote"
];

export const BUDGET_RANGE_HANDLED = [
  "Below ₹50K",
  "₹50K–₹1L",
  "₹1L–₹3L",
  "₹3L–₹5L",
  "₹5L+"
];

export const FRESH_FLOWER_COST = ["Included", "Extra", "Depends on Design"];
export const TRANSPORTATION_CHARGES = ["Included", "Extra", "Depends on Location"];

export const LIGHTING_PROVIDED = ["Basic", "Advanced", "Full Production"];

export const SPECIAL_EFFECTS = [
  "Cold Pyro",
  "Smoke Effects",
  "Bubble Machine",
  "Fireworks"
];

export const ADVANCE_PERCENTAGE = ["25%", "50%", "75%"];
export const BOOKING_TIMELINE = ["1 Month Before", "3 Months Before", "6 Months Before"];
export const CANCELLATION_POLICY_DECORATOR = ["Non Refundable", "Partial Refund", "Flexible"];
export const REVISION_FLEXIBILITY = ["High", "Medium", "Limited"];

export function emptyDecoratorMaster() {
  return {
    identity: {
      brand_company_name: "",
      decorator_type: "",
      years_of_experience: "",
      city: "",
      service_coverage: "",
      team_size: ""
    },
    services: {
      services_offered: [],
      decor_scope: []
    },
    theme_style: {
      themes_expertise: [],
      decor_style: [],
      best_known_for: [],
      ideal_wedding_type: []
    },
    material_design: {
      materials_used: [],
      floral_expertise: "",
      custom_fabrication: "",
      mockup_provided: "",
      moodboard_support: ""
    },
    execution: {
      max_guest_capacity: "",
      setup_time_required: "",
      dismantling_included: "",
      multiple_functions_capability: ""
    },
    function_expertise: {
      functions_covered: [],
      best_function_expertise: []
    },
    pricing: {
      starting_decor_price: "",
      pricing_type: "",
      budget_range_handled: "",
      fresh_flower_cost: "",
      transportation_charges: ""
    },
    logistics: {
      indoor_setup: "",
      outdoor_setup: "",
      destination_wedding_support: "",
      travel_stay_requirement: ""
    },
    lighting_tech: {
      lighting_provided: "",
      led_wall_setup: "",
      special_effects: []
    },
    workflow: {
      advance_required: "",
      advance_percentage: "",
      booking_timeline: "",
      cancellation_policy: "",
      revision_flexibility: ""
    },
    portfolio: {
      tags: "",
      notes: ""
    },
    ai_faq: {
      full_venue_decor: "",
      fresh_flowers_used: "",
      custom_themes: "",
      moodboard_provided: "",
      three_d_design: "",
      outdoor_supported: "",
      destination_weddings: "",
      lighting_included: "",
      special_effects_available: "",
      setup_time_required: "",
      budget_range: "",
      multiple_events: "",
      advance_required: "",
      cancellation_policy: "",
      best_known_for: ""
    }
  };
}
