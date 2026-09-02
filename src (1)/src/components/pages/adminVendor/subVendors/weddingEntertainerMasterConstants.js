// Wedding Entertainer Master Profile Constants — Category #14

export const ENT_VENDOR_TYPE = [
  "Solo Performer",
  "Performer + Team",
  "Entertainment Agency",
  "Celebrity Act",
];

export const ENT_PERFORMER_CATEGORY = [
  "Magician",
  "Live Band",
  "Singer",
  "Instrumentalist",
  "Stand-up Comedian",
  "Dance Troupe",
  "Fire Performer",
  "LED Performer",
  "Illusionist",
  "Mentalist",
  "Kids Entertainer",
  "Celebrity Artist",
  "Other",
];

export const ENT_EVENT_TYPES = [
  "Sangeet",
  "Cocktail",
  "Reception",
  "Mehendi",
  "Haldi",
  "Baraat",
  "After Party",
  "Kids Party",
  "Corporate",
];

export const ENT_PERFORMANCE_TYPES = [
  "Live Singing",
  "Band Performance",
  "Instrumental",
  "Magic Show",
  "Comedy Act",
  "Dance Performance",
  "Interactive Games",
  "Roaming Acts",
  "Stage Show",
];

export const ENT_AUDIENCE_TYPE = [
  "Kids",
  "Family Audience",
  "Youth Crowd",
  "Mixed Audience",
  "Premium / Luxury Audience",
];

export const ENT_ENGAGEMENT_STYLE = [
  "Interactive",
  "Passive Performance",
  "Crowd Participation Heavy",
  "Stage-Centric",
];

export const ENT_PERFORMANCE_DURATION = [
  "10–15 mins",
  "15–30 mins",
  "30–60 mins",
  "60–120 mins",
  "Custom",
];

export const ENT_PERFORMANCE_SLOTS = [
  "Single Slot",
  "Multiple Slots",
  "Roaming Throughout Event",
];

export const ENT_CONTENT_CUSTOMIZATION = [
  "Fully Customizable",
  "Semi-Custom",
  "Fixed Script",
];

export const ENT_THEME_COMPATIBILITY = [
  "Royal Wedding",
  "Bollywood Theme",
  "Retro Night",
  "Carnival",
  "Modern Luxury",
  "Cultural Traditional",
];

export const ENT_ENERGY_LEVEL = [
  "Low-key",
  "Balanced",
  "High Energy",
  "Ultra High Energy",
];

export const ENT_EQUIPMENT_OWNERSHIP = ["Own", "Rental", "Hybrid"];

export const ENT_SETUP_TIME = [
  "<30 mins",
  "30–60 mins",
  "1–3 hours",
  "3+ hours",
];

export const ENT_TEAM_SIZE = ["Solo", "2–5", "5–10", "10+"];

export const ENT_AUDIENCE_SIZE = [
  "<50",
  "50–150",
  "150–500",
  "500–1000",
  "1000+",
];

export const ENT_PRICING_MODEL = [
  "Per Act",
  "Per Hour",
  "Per Event",
  "Package",
];

export const ENT_STARTING_PRICE = [
  "₹5k–₹15k",
  "₹15k–₹30k",
  "₹30k–₹75k",
  "₹75k–₹1.5L",
  "₹1.5L+",
];

export const ENT_INCLUDES = [
  "Performance",
  "Equipment",
  "Travel",
  "Setup",
  "Assistants",
];

export const ENT_ADDONS = [
  "Extra Duration",
  "Special Effects",
  "Costume Changes",
  "Custom Script",
];

export const ENT_ADVANCE_BOOKING = [
  "<1 week",
  "1–4 weeks",
  "1–3 months",
  "3–6 months",
];

export const ENT_ADVANCE_PERCENT = ["10%", "25%", "50%", "75%"];

export const ENT_CANCELLATION_POLICY = [
  "Non-refundable",
  "Partial refund",
  "Flexible",
];

export const ENT_COORDINATION_MODE = [
  "WhatsApp",
  "Call",
  "In-person",
  "App-based",
];

export const ENT_ENTERTAINMENT_TAGS = [
  "Luxury Experience",
  "Interactive Fun",
  "Family Friendly",
  "High Energy Show",
  "Cultural Act",
  "Unique / Novelty",
];

export const ENT_PERFORMER_TAGS = [
  "Celebrity",
  "Viral Performer",
  "Premium Artist",
  "Budget Friendly",
];

export const ENT_EVENT_FIT_TAGS = [
  "Sangeet Highlight",
  "Cocktail Feature",
  "Kids Engagement",
  "Reception Entertainment",
];

export const ENT_NEGOTIATION = ["Fixed", "Moderate", "Flexible"];

export const ENT_LANGUAGES = [
  "English",
  "Hindi",
  "Marathi",
  "Punjabi",
  "Gujarati",
  "Tamil",
  "Telugu",
  "Bengali",
  "Multi-language",
];

export function emptyWeddingEntertainerMaster() {
  return {
    identity: {
      brand_name: "",
      primary_city: "",
      service_cities: [],
      vendor_type: "",
      performer_category: "",
      performer_category_other: "",
      years_of_experience: "",
      travel_policy: "",
      languages: [],
    },
    services: {
      event_types: [],
      performance_types: [],
      audience_type_handling: [],
    },
    core_intelligence: {
      engagement_style: "",
      performance_duration: "",
      performance_slots: "",
      content_customization: "",
      theme_compatibility: [],
      energy_level: "",
      stage_requirement: "",
      sound_requirement: "",
      lighting_requirement: "",
    },
    technical_setup: {
      equipment_ownership: "",
      setup_time: "",
      team_size: "",
      power_requirement: "",
      green_room_requirement: "",
      outdoor_suitability: "",
      indoor_suitability: "",
    },
    pricing: {
      pricing_model: "",
      starting_price_range: "",
      includes: [],
      addons: [],
      peak_pricing: "",
      negotiation_flexibility: "",
    },
    scale_capacity: {
      audience_size_capability: "",
      multiple_event_handling: "",
      parallel_performances: "",
    },
    workflow: {
      advance_booking_time: "",
      booking_advance_percent: "",
      cancellation_policy: "",
      coordination_mode: "",
      pre_event_briefing: "",
    },
    portfolio_tagging: {
      entertainment_tags: [],
      performer_tags: [],
      event_fit_tags: [],
    },
    ai_faq_layer: {
      suitable_for_kids: "",
      engage_large_crowds: "",
      performance_interactive: "",
      require_stage_setup: "",
      provide_own_equipment: "",
      performance_customized: "",
      suitable_cocktail_events: "",
      perform_multiple_slots: "",
      high_energy_act: "",
      travel_outside_city: "",
      sound_system_required: "",
      handle_mixed_audience: "",
      costume_changes_included: "",
      suitable_outdoor_venues: "",
      handle_last_minute: "",
    },
  };
}
