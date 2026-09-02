// Section 1 — Basic Identity
export const VENDOR_TYPE = [
  "Independent Pandit",
  "Pandit Agency / Group",
  "Temple-Associated Pandit",
  "Online Ritual Service Provider",
];

export const SERVICE_PRESENCE = [
  "Local",
  "Outstation",
  "Pan-India",
  "International",
];

export const LANGUAGES_SPOKEN = [
  "Sanskrit",
  "Hindi",
  "Marathi",
  "Gujarati",
  "Tamil",
  "Telugu",
  "Kannada",
  "English",
];

export const YEARS_OF_EXPERIENCE = ["0–2", "3–5", "6–10", "10+"];

export const RELIGIOUS_TRADITION = [
  "North Indian (Hindi Rituals)",
  "South Indian (Tamil/Telugu/Kannada)",
  "Maharashtrian",
  "Gujarati",
  "Bengali",
  "Jain Rituals",
];

// Section 2 — Services Offered
export const CEREMONY_TYPES = [
  "Wedding Ceremony (Vivah)",
  "Engagement (Sakharpuda / Ring Ceremony)",
  "Haldi",
  "Mehendi Rituals",
  "Griha Pravesh",
  "Satyanarayan Pooja",
];

export const SAMAGRI_PROVIDED = ["Full Kit", "Partial", "Not Provided"];

// Section 3 — Core Intelligence
export const RITUAL_DURATION = [
  "30–60 mins",
  "1–2 hours",
  "2–4 hours",
  "4+ hours",
];

export const RITUAL_COMPLEXITY = ["Basic", "Standard", "Detailed Traditional"];

export const RITUAL_LANGUAGE_PREFERENCE = [
  "Sanskrit Only",
  "Sanskrit + Regional Language",
  "Fully Explained in Local Language",
];

// Section 4 — Technical / Product / Skill
export const SETUP_TIME_REQUIRED = ["<30 mins", "30–60 mins", "60+ mins"];

// Section 5 — Pricing
export const PRICE_RANGE = ["2K–5K", "5K–10K", "10K–25K", "25K–50K", "50K+"];

export const PRICING_MODEL = ["Per Ceremony", "Per Day", "Package Based"];

export const TRAVEL_CHARGES = ["Included", "Extra"];

export const SAMAGRI_CHARGES = ["Included", "Extra", "Not Applicable"];

export const DAKSHINA_FLEXIBILITY = ["Fixed", "Flexible"];

// Section 6 — Scale & Capacity
export const EVENTS_PER_DAY = ["1", "2–3", "3–5", "5+"];

export const TEAM_SIZE = ["Solo", "1–2", "3–5", "5+"];

// Section 7 — Workflow & Booking
export const BOOKING_WINDOW = [
  "Same Day",
  "1–7 Days",
  "7–30 Days",
  "1+ Month",
];

export const ARRIVAL_TIMING = ["On Time", "30 mins Early", "1 hour Early"];

export const PAYMENT_MODES = ["UPI", "Cash", "Bank Transfer"];

export const ADVANCE_PAYMENT_PERCENTAGE = ["0%", "25%", "50%", "100%"];

// Section 8 — Portfolio Tagging
export const STYLE_TAGS = [
  "Traditional",
  "Modern Simplified",
  "Ritual Explainer",
  "Premium Ceremony",
];

export const AUDIENCE_TAGS = ["Bride & Groom", "Family", "Destination Weddings"];

export const USAGE_TAGS = ["Wedding Ceremony", "Engagement", "House Rituals"];

export const PRICE_SEGMENT_TAGS = ["Budget", "Mid-range", "Premium", "Luxury"];

export function emptyPanditMaster() {
  return {
    identity: {
      vendor_type: "",
      pandit_name: "",
      service_presence: [],
      city_base: "",
      languages_spoken: [],
      years_of_experience: "",
      religious_tradition: [],
    },
    services_offered: {
      ceremony_types: [],
      destination_wedding_services: "",
      virtual_ceremony_support: "",
      ritual_explanation_provided: "",
      customized_rituals: "",
      samagri_provided: "",
      assistant_pandits_included: "",
    },
    core_intelligence: {
      ritual_duration_options: "",
      ritual_complexity_level: "",
      muhurat_guidance_provided: "",
      horoscope_matching: "",
      ritual_language_preference: [],
      fire_ritual_havan_included: "",
      interfaith_custom_ceremonies: "",
    },
    technical: {
      audio_setup_requirement: "",
      microphone_usage: "",
      samagri_list_provided_in_advance: "",
      setup_time_required: "",
      dress_code_provided: "",
      documentation_ritual_booklet: "",
    },
    pricing: {
      price_range: "",
      pricing_model: "",
      travel_charges: "",
      samagri_charges: "",
      dakshina_flexibility: "",
    },
    scale_capacity: {
      events_per_day: "",
      team_size: "",
      multi_location_handling: "",
    },
    workflow: {
      advance_booking_required: "",
      booking_window: "",
      pre_ceremony_consultation: "",
      ritual_customization_discussion: "",
      arrival_timing: "",
      payment_modes: [],
      advance_payment_percentage: "",
    },
    portfolio_tagging: {
      style_tags: [],
      audience_tags: [],
      usage_tags: [],
      price_segment_tags: "",
    },
    ai_faq: {
      performs_full_wedding_rituals: "",
      provides_pooja_samagri: "",
      conducts_destination_weddings: "",
      explains_rituals_during_ceremony: "",
      kundli_matching_available: "",
      rituals_customized_by_family_tradition: "",
      performs_interfaith_weddings: "",
      havan_included: "",
      provides_assistant_pandits: "",
      advance_booking_required: "",
      ceremony_in_regional_language: "",
      travels_outstation: "",
      same_day_booking_possible: "",
      provides_muhurat_guidance: "",
      microphone_audio_setup_required: "",
    },
  };
}
