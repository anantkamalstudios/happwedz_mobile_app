// DJ Master Profile Constants — Category #12

export const DJ_VENDOR_TYPE = [
  "Solo DJ",
  "DJ + Console Setup",
  "DJ + Full Sound & Light Team",
  "DJ Agency / Collective",
];

export const DJ_EVENT_TYPES = [
  "Wedding Sangeet",
  "Cocktail Night",
  "Reception",
  "Baraat",
  "After Party",
  "Engagement",
  "Haldi",
  "Mehendi",
  "Corporate",
  "Private Party",
];

export const DJ_FORMATS = [
  "Club Style",
  "Wedding Style",
  "Bollywood Specialist",
  "Open Format",
  "Regional Specialist",
];

export const DJ_ADDITIONAL_SERVICES = [
  "Live Dhol Integration",
  "Saxophone with DJ",
  "LED Dance Floor",
  "Cold Pyros Sync",
  "CO2 Guns",
  "Smoke Effects",
  "Laser Show",
  "Visual LED Screen Sync",
  "Live Mashups",
  "Custom Entry Tracks",
];

export const DJ_MUSIC_GENRES = [
  "Bollywood",
  "Punjabi",
  "EDM",
  "House",
  "Commercial",
  "Hip-Hop",
  "Retro",
  "Techno",
  "Regional Folk",
  "Sufi",
  "International Pop",
];

export const DJ_CROWD_HANDLING = [
  "<100 guests",
  "100–300",
  "300–700",
  "700–1500",
  "1500+",
];

export const DJ_SPECIALIZATION_STYLE = [
  "High Energy",
  "Classy / Lounge",
  "Fusion / Mashups",
  "Cultural Weddings",
  "Youth-centric",
];

export const DJ_LIVE_MIXING = [
  "Basic",
  "Advanced",
  "Professional Club-Level",
];

export const DJ_SONG_REQUEST = ["Real-time", "Curated only", "Restricted"];

export const DJ_ENTRY_SYNC = [
  "Bride Entry Sync",
  "Groom Entry Sync",
  "Couple Entry Sync",
  "Dance Performances Sync",
];

export const DJ_EQUIPMENT_OWNERSHIP = ["Own Equipment", "Rental Based", "Hybrid"];

export const DJ_SOUND_SETUP = [
  "Basic (up to 100 pax)",
  "Medium (100–500 pax)",
  "Large (500–1500 pax)",
  "Stadium Scale",
];

export const DJ_LIGHTING_SETUP = [
  "Basic Lights",
  "Intelligent Moving Heads",
  "Full Production Lighting",
];

export const DJ_CONSOLE_TYPES = ["Pioneer", "Denon", "Numark", "Others"];

export const DJ_SETUP_TIME = ["<1 hour", "1–3 hours", "3–6 hours"];

export const DJ_TECH_TEAM_SIZE = ["1–2", "3–5", "5–10", "10+"];

export const DJ_PRICING_MODEL = ["Per Event", "Per Hour", "Per Day", "Package Based"];

export const DJ_STARTING_PRICE = [
  "₹10k–₹25k",
  "₹25k–₹50k",
  "₹50k–₹1L",
  "₹1L–₹2L",
  "₹2L+",
];

export const DJ_INCLUDES = [
  "DJ Only",
  "Console",
  "Sound",
  "Lights",
  "Setup & Dismantle",
  "Travel",
];

export const DJ_ADDONS = ["Travel", "Accommodation", "Extra Hours", "Special Effects"];

export const DJ_MAX_EVENTS_PER_DAY = ["1", "2", "3+"];

export const DJ_ADVANCE_BOOKING = ["<1 week", "1–4 weeks", "1–3 months", "3–6 months"];

export const DJ_ADVANCE_PERCENT = ["10%", "25%", "50%", "75%"];

export const DJ_CANCELLATION_POLICY = ["Non-refundable", "Partial refund", "Flexible"];

export const DJ_COORDINATION_MODE = ["WhatsApp", "Call", "In-person", "App-based"];

export const DJ_EVENT_MOOD_TAGS = [
  "Royal",
  "Minimal",
  "High Energy",
  "Luxury",
  "Intimate",
  "Cultural",
];

export const DJ_MUSIC_STYLE_TAGS = [
  "Bollywood Night",
  "EDM Night",
  "Punjabi Night",
  "Retro Night",
  "Fusion Night",
];

export const DJ_FAQ_YES_NO = ["Yes", "No"];
export const DJ_FAQ_SONG_REQUEST_OPTIONS = ["Yes", "No", "Limited"];
export const DJ_FAQ_SKILL_LEVEL = ["Beginner", "Intermediate", "Expert"];

export const DJ_FAQ_QUESTIONS = [
  { key: "q1_handle_500_guests",       label: "Q1. Can DJ handle 500+ guests?",                        options: "yesno" },
  { key: "q2_provide_sound_system",    label: "Q2. Does DJ provide sound system?",                     options: "yesno" },
  { key: "q3_provide_lighting",        label: "Q3. Does DJ provide lighting setup?",                   options: "yesno" },
  { key: "q4_sync_entry_music",        label: "Q4. Can DJ sync music with bride/groom entry?",         options: "yesno" },
  { key: "q5_custom_playlists",        label: "Q5. Can DJ create custom playlists?",                   options: "yesno" },
  { key: "q6_live_song_requests",      label: "Q6. Does DJ take live song requests?",                  options: "song_request" },
  { key: "q7_suitable_baraat",         label: "Q7. Is DJ suitable for baraat?",                        options: "yesno" },
  { key: "q8_travel_outside_city",     label: "Q8. Does DJ travel outside city?",                      options: "yesno" },
  { key: "q9_special_effects",         label: "Q9. Are special effects like CO2 / pyros available?",   options: "yesno" },
  { key: "q10_backup_equipment",       label: "Q10. Does DJ bring backup equipment?",                  options: "yesno" },
  { key: "q11_multiple_events",        label: "Q11. Can DJ handle multiple events same day?",          options: "yesno" },
  { key: "q12_high_energy_sangeet",    label: "Q12. Is DJ suitable for high-energy sangeet nights?",   options: "yesno" },
  { key: "q13_integrate_live_performers", label: "Q13. Can DJ integrate with live performers?",        options: "yesno" },
  { key: "q14_generator_backup",       label: "Q14. Does DJ require generator backup?",                options: "yesno" },
  { key: "q15_skill_level",            label: "Q15. Is DJ beginner / intermediate / expert level?",    options: "skill_level" },
];

export const DJ_NEGOTIATION = ["Fixed", "Slightly Flexible", "Highly Flexible"];

export const DJ_LANGUAGES = [
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

export function emptyDjMaster() {
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
      dj_formats: [],
      additional_services: [],
    },
    core_intelligence: {
      music_genres: [],
      crowd_handling: "",
      specialization_style: "",
      live_mixing_capability: "",
      custom_playlist_support: "",
      song_request_handling: "",
      entry_sync: [],
      baraat_dj_setup: "",
      backup_dj_available: "",
    },
    technical_setup: {
      equipment_ownership: "",
      sound_setup_capability: "",
      lighting_setup: "",
      console_types: [],
      power_backup: "",
      setup_time_required: "",
      technical_team_size: "",
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
      concurrent_events: "",
      team_multi_event: "",
    },
    workflow: {
      advance_booking_time: "",
      booking_advance_percent: "",
      cancellation_policy: "",
      coordination_mode: "",
      pre_event_planning_call: "",
    },
    portfolio_tagging: {
      event_mood_tags: [],
      music_style_tags: [],
      celebrity_big_event_experience: "",
    },
    ai_faq: {
      q1_handle_500_guests: "",
      q2_provide_sound_system: "",
      q3_provide_lighting: "",
      q4_sync_entry_music: "",
      q5_custom_playlists: "",
      q6_live_song_requests: "",
      q7_suitable_baraat: "",
      q8_travel_outside_city: "",
      q9_special_effects: "",
      q10_backup_equipment: "",
      q11_multiple_events: "",
      q12_high_energy_sangeet: "",
      q13_integrate_live_performers: "",
      q14_generator_backup: "",
      q15_skill_level: "",
    },
  };
}
