// Sangeet Choreographer Master Profile Constants — Category #13

export const CHOREO_VENDOR_TYPE = [
  "Solo Choreographer",
  "Choreographer + Assistant Team",
  "Dance Company",
  "Celebrity Choreography Team",
];

export const CHOREO_EVENT_TYPES = [
  "Sangeet",
  "Cocktail Dance Night",
  "Engagement",
  "Wedding Performances",
  "Reception Performances",
  "Haldi Fun Performances",
  "Family Dance Acts",
];

export const CHOREO_DANCE_FORMATS = [
  "Solo Performances",
  "Couple Performances",
  "Group Performances",
  "Family Acts",
  "Thematic Acts",
];

export const CHOREO_SPECIAL_OFFERINGS = [
  "Bride Solo Performance",
  "Groom Solo Performance",
  "Couple Love Story Act",
  "Family Mashup",
  "Kids Performances",
  "Flash Mob",
  "Surprise Entries",
];

export const CHOREO_DANCE_STYLES = [
  "Bollywood",
  "Semi-Classical",
  "Classical (Kathak / Bharatnatyam)",
  "Hip-Hop",
  "Contemporary",
  "Bhangra",
  "Garba / Dandiya",
  "Freestyle",
  "Fusion",
];

export const CHOREO_SKILL_LEVEL = [
  "Beginner Friendly",
  "Intermediate",
  "Advanced Dancers",
];

export const CHOREO_AGE_GROUP = ["Kids", "Teens", "Adults", "Seniors"];

export const CHOREO_MAX_PARTICIPANTS = ["1–5", "5–10", "10–20", "20–50", "50+"];

export const CHOREO_CUSTOMIZATION = [
  "Fully Customized",
  "Semi-Customized",
  "Template-Based",
];

export const CHOREO_REHEARSAL_MODE = ["In-person", "Online", "Hybrid"];

export const CHOREO_POLISH_LEVEL = [
  "Basic",
  "Stage-Ready",
  "Professional Show-Level",
];

export const CHOREO_REHEARSAL_SESSIONS = [
  "1–2 sessions",
  "3–5 sessions",
  "5–10 sessions",
  "10+ sessions",
];

export const CHOREO_SESSION_DURATION = ["1 hour", "2 hours", "3+ hours"];

export const CHOREO_PRACTICE_LOCATION = [
  "Client Venue",
  "Choreographer Studio",
  "Both",
];

export const CHOREO_ON_EVENT_PRESENCE = [
  "Full-time coordination",
  "Limited presence",
  "Not required",
];

export const CHOREO_MUSIC_EDITING = ["Included", "Chargeable", "Not Provided"];

export const CHOREO_PRICING_MODEL = [
  "Per Performance",
  "Per Person",
  "Per Session",
  "Full Package",
];

export const CHOREO_STARTING_PRICE = [
  "₹5k–₹15k",
  "₹15k–₹30k",
  "₹30k–₹60k",
  "₹60k–₹1L",
  "₹1L+",
];

export const CHOREO_INCLUDES = [
  "Choreography",
  "Practice Sessions",
  "Music Editing",
  "Event Day Coordination",
  "Assistants",
];

export const CHOREO_ADDONS = ["Travel", "Extra Sessions", "Props", "Costumes"];

export const CHOREO_MAX_EVENTS_PER_DAY = ["1", "2", "3+"];

export const CHOREO_TEAM_SIZE = ["Solo", "2–5", "5–10", "10+"];

export const CHOREO_ADVANCE_BOOKING = [
  "<1 week",
  "1–4 weeks",
  "1–3 months",
  "3–6 months",
];

export const CHOREO_ADVANCE_PERCENT = ["10%", "25%", "50%", "75%"];

export const CHOREO_CANCELLATION_POLICY = [
  "Non-refundable",
  "Partial refund",
  "Flexible",
];

export const CHOREO_COORDINATION_MODE = [
  "WhatsApp",
  "Call",
  "In-person",
  "App-based",
];

export const CHOREO_PERFORMANCE_STYLE_TAGS = [
  "Romantic",
  "High Energy",
  "Emotional",
  "Fun & Quirky",
  "Traditional",
  "Filmy",
];

export const CHOREO_EVENT_SCALE_TAGS = ["Intimate", "Mid-size", "Grand"];

export const CHOREO_CHOREOGRAPHY_STYLE_TAGS = [
  "Storytelling",
  "Beat-based",
  "Expression-driven",
  "Performance-heavy",
];

export const CHOREO_NEGOTIATION = [
  "Fixed",
  "Slightly Flexible",
  "Highly Flexible",
];

export const CHOREO_LANGUAGES = [
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

export function emptySangeetChoreographerMaster() {
  return {
    identity: {
      brand_name: "",
      primary_city: "",
      service_cities: [],
      vendor_type: "",
      years_of_experience: "",
      travel_policy: "",
      languages: [],
    },
    services: {
      event_types: [],
      dance_formats: [],
      special_offerings: [],
    },
    core_intelligence: {
      dance_styles: [],
      skill_level_handling: "",
      age_group_handling: [],
      max_participants_per_act: "",
      story_based_choreography: "",
      customization_level: "",
      music_selection_support: "",
      rehearsal_mode: "",
      performance_polish_level: "",
    },
    rehearsal_logistics: {
      rehearsal_sessions_per_act: "",
      session_duration: "",
      practice_location: "",
      travel_for_practice: "",
      assistant_availability: "",
      last_minute_practice_support: "",
    },
    performance_execution: {
      on_event_presence: "",
      backstage_coordination: "",
      entry_transition_planning: "",
      music_editing_mixing: "",
      props_support: "",
      costume_guidance: "",
    },
    pricing: {
      pricing_model: "",
      starting_price_range: "",
      includes: [],
      addon_charges: [],
      peak_season_pricing: "",
      negotiation_flexibility: "",
    },
    scale_capacity: {
      max_events_per_day: "",
      parallel_event_handling: "",
      team_size: "",
    },
    workflow: {
      advance_booking_time: "",
      booking_advance_percent: "",
      cancellation_policy: "",
      coordination_mode: "",
      trial_session_availability: "",
    },
    portfolio_tagging: {
      performance_style_tags: [],
      event_scale_tags: [],
      choreography_style_tags: [],
    },
    ai_faq_layer: {
      handle_non_dancers: "",
      teach_kids_seniors: "",
      couple_performances: "",
      music_editing_included: "",
      rehearsal_flexible: "",
      online_rehearsals: "",
      present_on_event_day: "",
      story_based_performances: "",
      provide_assistants: "",
      handle_large_groups: "",
      props_included: "",
      help_with_costumes: "",
      last_minute_choreography: "",
      multiple_performances: "",
      beginner_friendly: "",
    },
  };
}
