// ─────────────────────────────────────────────────────────────────────────────
// PRE-WEDDING SHOOT LOCATION — constants & empty state
// ─────────────────────────────────────────────────────────────────────────────

export const PWL_LOCATION_TYPE = [
  "Private Property",
  "Resort / Hotel",
  "Studio (Indoor)",
  "Outdoor Public Location",
  "Farmhouse",
  "Heritage Property",
];

export const PWL_OWNERSHIP_TYPE = [
  "Private Owned",
  "Government / Public",
  "Commercial Venue",
];

export const PWL_ACCESSIBILITY_TYPE = [
  "Easy Access (Roadside)",
  "Moderate Access",
  "Remote Location",
];

export const PWL_YEARS_OF_OPERATION = ["0–2", "3–5", "6–10", "10+"];

export const PWL_BOOKING_TYPE = [
  "Hourly Booking",
  "Half-Day Booking",
  "Full-Day Booking",
];

export const PWL_PROPS_AVAILABLE = [
  "Vintage Props",
  "Floral Setups",
  "Furniture",
  "Vehicles",
  "None",
];

export const PWL_LOCATION_THEMES = [
  "Royal / Palace",
  "Nature / Greenery",
  "Beach / Waterfront",
  "Urban / Modern",
  "Rustic / Village",
  "Studio Backdrop",
  "Luxury Resort",
];

export const PWL_BEST_SHOOT_TIME = [
  "Sunrise",
  "Daylight",
  "Sunset",
  "Night",
];

export const PWL_LIGHTING_CONDITIONS = [
  "Natural Light Dominant",
  "Artificial Lighting Available",
  "Mixed",
];

export const PWL_WEATHER_SUITABILITY = [
  "Summer Friendly",
  "Winter Friendly",
  "Monsoon Friendly",
  "All Weather",
];

export const PWL_PRIVACY_LEVEL = [
  "Exclusive Private",
  "Semi-Private",
  "Public Shared",
];

export const PWL_NOISE_LEVEL = ["Low", "Moderate", "High"];

export const PWL_AREA_SIZE = [
  "<1 Acre",
  "1–5 Acres",
  "5–10 Acres",
  "10+ Acres",
];

export const PWL_SHOOTING_SPOTS = ["1–3", "3–7", "7–15", "15+"];

export const PWL_TERRAIN_TYPE = [
  "Garden",
  "Water Body",
  "Architecture",
  "Open Land",
  "Hills",
];

export const PWL_PRICE_RANGE = [
  "0–5K",
  "5K–15K",
  "15K–30K",
  "30K–75K",
  "75K+",
];

export const PWL_PRICING_MODEL = [
  "Per Hour",
  "Half Day",
  "Full Day",
  "Package Based",
];

export const PWL_OUTFITS_ON_RENT = [
  "Yes - Included in the venue charge",
  "Not Available",
  "Available on Extra Charge",
];

export const PWL_CANCELLATION_POLICY = [
  "Refundable",
  "Partially Refundable",
  "Non-Refundable",
];

export const PWL_MAX_CREW_SIZE = ["2–5", "5–10", "10–20", "20+"];

export const PWL_SIMULTANEOUS_SHOOTS = [
  "1 (Exclusive)",
  "2–3",
  "3–5",
  "5+",
];

export const PWL_PARKING_CAPACITY = [
  "0–5 Vehicles",
  "5–15",
  "15–30",
  "30+",
];

export const PWL_BOOKING_WINDOW = [
  "Same Day",
  "1–7 days",
  "7–30 days",
  "1+ month",
];

export const PWL_TIME_SLOT_ALLOCATION = ["Fixed Slots", "Flexible"];

export const PWL_PAYMENT_MODES = ["UPI", "Cash", "Card", "Bank Transfer"];

export const PWL_ADVANCE_PAYMENT = ["0%", "25%", "50%", "100%"];

export const PWL_VISUAL_STYLE_TAGS = [
  "Cinematic",
  "Natural",
  "Luxury",
  "Rustic",
  "Minimal",
];

export const PWL_AUDIENCE_TAGS = [
  "Couple",
  "Pre-Wedding Shoot",
  "Engagement Shoot",
];

export const PWL_USAGE_TAGS = [
  "Pre-Wedding Photos",
  "Pre-Wedding Video",
  "Reel Shoot",
];

export const PWL_PRICE_SEGMENT_TAGS = [
  "Budget",
  "Mid-range",
  "Premium",
  "Luxury",
];

export function emptyPreWeddingLocationMaster() {
  return {
    identity: {
      location_type: "",
      location_name: "",
      ownership_type: "",
      city: "",
      accessibility_type: "",
      years_of_operation: "",
    },
    services: {
      booking_type: [],
      photography_allowed: "",
      videography_allowed: "",
      drone_usage_allowed: "",
      permission_handling: "",
      changing_rooms_available: "",
      makeup_room_available: "",
      props_available: [],
      power_supply_available: "",
    },
    core_intelligence: {
      location_themes: [],
      best_shoot_time: [],
      lighting_conditions: "",
      weather_suitability: [],
      privacy_level: "",
      noise_level: "",
    },
    technical: {
      area_size: "",
      shooting_spots: "",
      indoor_availability: "",
      outdoor_availability: "",
      terrain_type: [],
      electric_backup: "",
    },
    pricing: {
      price_range: "",
      pricing_model: "",
      outfits_on_rent: "",
      security_deposit_required: "",
      permit_charges: "",
      cancellation_policy: "",
    },
    scale_capacity: {
      max_crew_size: "",
      simultaneous_shoots: "",
      parking_capacity: "",
    },
    workflow: {
      advance_booking_required: "",
      booking_window: "",
      time_slot_allocation: "",
      onsite_coordinator_available: "",
      payment_modes: [],
      advance_payment_percentage: "",
    },
    portfolio_tagging: {
      visual_style_tags: [],
      audience_tags: [],
      usage_tags: [],
      price_segment_tags: "",
    },
    ai_faq_layer: {
      photography_allowed: "",
      drone_shooting_permitted: "",
      changing_rooms_available: "",
      private_for_shoots: "",
      half_day_booking: "",
      props_available: "",
      power_supply_available: "",
      advance_booking_required: "",
      parking_available: "",
      large_crews_allowed: "",
      makeup_room_available: "",
      sunset_shoots_suitable: "",
      permits_included: "",
      indoor_shooting_available: "",
      accessible_by_car: "",
    },
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// PRE-WEDDING PHOTOGRAPHERS — constants & empty state
// ─────────────────────────────────────────────────────────────────────────────

export const PWP_VENDOR_TYPE = [
  "Solo Photographer",
  "Photographer + Team",
  "Studio Brand",
  "Boutique Photography Agency",
];

export const PWP_SERVICE_PRESENCE = ["Local", "Outstation", "International"];

export const PWP_YEARS_OF_EXPERIENCE = ["0–2", "3–5", "6–10", "10+"];

export const PWP_TEAM_SIZE = ["Solo", "2–3", "4–6", "6+"];

export const PWP_SHOOT_TYPES = [
  "Pre-Wedding Photoshoot",
  "Pre-Wedding Cinematic Video",
  "Save-the-Date Video",
  "Reel / Short Content",
];

export const PWP_PHOTOGRAPHY_COVERAGE = [
  "Photos Only",
  "Video Only",
  "Both",
  "Complete End to End Pre-wedding package with travel & photography team coverage",
];

export const PWP_PHOTOGRAPHY_STYLE = [
  "Candid",
  "Cinematic",
  "Traditional",
  "Fine Art",
  "Documentary",
];

export const PWP_SHOOT_STYLE_THEMES = [
  "Romantic",
  "Fun / Playful",
  "Royal",
  "Travel / Destination",
  "Minimal",
];

export const PWP_LIGHTING_STYLE = [
  "Natural Light",
  "Artificial Light",
  "Mixed",
];

export const PWP_EDITING_STYLE = [
  "Light & Airy",
  "Dark & Moody",
  "Vibrant",
  "Vintage",
];

export const PWP_REEL_STYLE = [
  "Instagram Reels",
  "Story Format",
  "Cinematic Highlights",
];

export const PWP_BEST_TIME_PREFERENCE = [
  "Sunrise",
  "Sunset",
  "Night",
  "Full Day",
];

export const PWP_CAMERA_TYPE = ["DSLR", "Mirrorless", "Cinema Camera"];

export const PWP_DRONE_EQUIPMENT_LEVEL = ["Basic", "Advanced", "Not Available"];

export const PWP_VIDEO_RESOLUTION = ["Full HD", "4K", "6K+"];

export const PWP_STABILIZATION_EQUIPMENT = [
  "Gimbal",
  "Slider",
  "Drone",
  "Handheld",
];

export const PWP_PRICE_RANGE = [
  "5K–15K",
  "15K–30K",
  "30K–60K",
  "60K–1.5L",
  "1.5L+",
];

export const PWP_PRICING_MODEL = ["Per Shoot", "Per Day", "Package Based"];

export const PWP_SHOOTS_PER_MONTH = ["<10", "10–20", "20–40", "40+"];

export const PWP_SIMULTANEOUS_PROJECTS = ["1", "2–3", "3–5", "5+"];

export const PWP_TEAM_SCALABILITY = ["Fixed Team", "Scalable Team"];

export const PWP_BOOKING_WINDOW = [
  "<7 days",
  "7–30 days",
  "1–3 months",
  "3+ months",
];

export const PWP_CONCEPT_FINALIZATION = [
  "Same Day",
  "1–3 days",
  "3–7 days",
];

export const PWP_SHOOT_DURATION = [
  "2–4 hours",
  "Half Day",
  "Full Day",
  "Multi-Day",
];

export const PWP_EDITED_PHOTOS_DELIVERY = [
  "1–3 days",
  "3–7 days",
  "7–15 days",
  "15+ days",
];

export const PWP_VIDEO_DELIVERY = [
  "3–7 days",
  "7–15 days",
  "15–30 days",
  "30+ days",
];

export const PWP_PAYMENT_MODES = ["UPI", "Cash", "Card", "Bank Transfer"];

export const PWP_VISUAL_STYLE_TAGS = [
  "Cinematic",
  "Romantic",
  "Travel Story",
  "Royal",
  "Minimal",
];

export const PWP_AUDIENCE_TAGS = ["Couple", "Engagement", "Save-the-Date"];

export const PWP_USAGE_TAGS = ["Instagram", "YouTube", "Wedding Invite Video"];

export const PWP_PRICE_SEGMENT_TAGS = [
  "Budget",
  "Mid-range",
  "Premium",
  "Luxury",
];

export const PWP_ADVANCE_PAYMENT = ["25%", "50%", "75%", "100%"];

export function emptyPreWeddingPhotographerMaster() {
  return {
    identity: {
      vendor_type: "",
      brand_name: "",
      service_presence: [],
      city: "",
      years_of_experience: "",
      team_size: "",
    },
    services: {
      shoot_types: [],
      photography_coverage: [],
      drone_shooting: "",
      cinematic_videography: "",
      concept_planning_support: "",
      location_assistance: "",
      styling_assistance: "",
      outfit_coordination_support: "",
      travel_included: "",
    },
    core_intelligence: {
      photography_style: [],
      shoot_style_themes: [],
      lighting_style: [],
      editing_style: [],
      reel_style_capability: [],
      best_time_preference: [],
    },
    technical: {
      camera_type: [],
      drone_equipment_level: "",
      video_resolution: "",
      stabilization_equipment: [],
      audio_capture: "",
      backup_equipment_available: "",
    },
    pricing: {
      price_range: "",
      pricing_model: "",
      travel_charges: "",
      stay_charges: "",
      drone_charges: "",
      editing_charges: "",
      advance_payment_percentage: "",
    },
    scale_capacity: {
      shoots_per_month: "",
      simultaneous_projects: "",
      team_scalability: "",
    },
    workflow: {
      booking_window: "",
      concept_finalization_timeline: "",
      shoot_duration_options: [],
      raw_data_delivery: "",
      edited_photos_delivery_timeline: "",
      video_delivery_timeline: "",
      payment_modes: [],
    },
    portfolio_tagging: {
      visual_style_tags: [],
      audience_tags: [],
      usage_tags: [],
      price_segment_tags: "",
    },
    ai_faq_layer: {
      provide_pre_wedding_photoshoots: "",
      offer_cinematic_video_shoots: "",
      drone_shooting_available: "",
      help_with_shoot_concepts: "",
      travel_included: "",
      reels_for_instagram: "",
      provide_raw_images: "",
      same_day_shoot_possible: "",
      offer_destination_shoots: "",
      edited_photos_within_7_days: "",
      provide_outfit_guidance: "",
      advance_booking_required: "",
      shoot_in_4k_video: "",
      handle_multi_day_shoots: "",
      provide_full_shoot_packages: "",
    },
  };
}
