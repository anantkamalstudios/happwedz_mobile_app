export const SERVICES_OFFERED = [
  "Wedding Photography",
  "Pre-Wedding Shoot",
  "Candid Photography",
  "Traditional Photography",
  "Cinematic Videography",
  "Drone Shoot",
  "Reel",
  "Short Content",
  "Live Streaming",
];
export const ALSO_AVAILABLE_FOR = ["Pre-Wedding Only", "Wedding Only", "Both"];
export const TRAVEL_AVAILABILITY = ["Local Only", "Pan India", "International"];

export const PHOTOGRAPHY_STYLE = [
  "Candid",
  "Traditional",
  "Documentary",
  "Editorial",
  "Fine Art",
  "Cinematic",
  "Luxury",
  "Minimal",
  "Dramatic",
];
export const EDITING_STYLE = [
  "Light & Airy",
  "Dark & Moody",
  "Vibrant",
  "Natural Tone",
  "Matte Finish",
];
export const BEST_KNOWN_FOR = [
  "Candid Moments",
  "Couple Portraits",
  "Bridal Shots",
  "Family Coverage",
  "Cinematic Films",
  "Creative Concepts",
];
export const IDEAL_WEDDING_TYPE = [
  "Budget Weddings",
  "Luxury Weddings",
  "Destination Weddings",
  "Intimate Weddings",
  "Big Fat Weddings",
];

export const TEAM_SIZE = ["Solo", "2-3 Members", "4-6 Members", "6+ Members"];
export const PHOTOS_DELIVERED = ["100-300", "300-500", "500-1000", "1000+"];
export const VIDEOS_DELIVERED = [
  "Highlight Video",
  "Full Wedding Film",
  "Instagram Reel",
  "Teaser",
];
export const ALBUM_TYPE = [
  "Premium Album",
  "Coffee Table Book",
  "Magazine Style",
];
export const DELIVERY_TIME = ["7 Days", "15 Days", "30 Days", "45+ Days"];

export const PRICING_TYPE = ["Per Day", "Per Event", "Package Based"];
export const PRE_WEDDING_COST = ["Included", "Extra Charge", "Not Offered"];
export const TRAVEL_CHARGES = ["Included", "Extra", "Depends on Location"];

export const CAMERA_TYPE = ["DSLR", "Mirrorless", "Cinema Camera"];
export const LIGHTING_SETUP = ["Basic", "Advanced", "Cinematic"];

export const PRE_WEDDING_LOCATIONS = ["Local", "Outstation", "International"];
export const ADVANCE_PERCENTAGE = ["25%", "50%", "75%"];
export const CANCELLATION_POLICY = [
  "Non Refundable",
  "Partial Refund",
  "Flexible",
];
export const NUMBER_OF_REVISIONS = ["1", "2", "Unlimited"];
export const FUNCTIONS_COVERED = [
  "Haldi",
  "Mehendi",
  "Sangeet",
  "Wedding",
  "Reception",
  "Engagement",
  "Cocktail",
];
export const BEST_FOR = [
  "Couple Shoots",
  "Big Weddings",
  "Intimate Weddings",
  "Destination Weddings",
];

export function emptyPhotographerMaster() {
  return {
    identity: {
      services_offered: [],
      also_available_for: "",
      years_of_experience: "",
      travel_availability: "",
    },
    style_intelligence: {
      photography_style: [],
      editing_style: "",
      best_known_for: [],
      ideal_wedding_type: [],
    },
    team_coverage: {
      team_size: "",
      max_events_per_day: "",
      backup_team_available: "",
      female_photographer_available: "",
    },
    deliverables: {
      photos_delivered: "",
      videos_delivered: [],
      raw_data_provided: "",
      album_included: "",
      album_type: "",
      delivery_time: "",
      express_delivery_available: "",
    },
    pricing: {
      starting_price: "",
      pricing_type: "",
      pre_wedding_shoot_cost: "",
      travel_charges: "",
      accommodation_required: "",
    },
    equipment: {
      camera_type: "",
      drone_available: "",
      lighting_setup: "",
      live_streaming_setup: "",
    },
    prewedding_specialization: {
      locations_supported: "",
      concept_shoot_available: "",
      props_provided: "",
      location_scouting_support: "",
    },
    workflow: {
      booking_advance_required: "",
      advance_percentage: "",
      cancellation_policy: "",
      revision_allowed: "",
      number_of_revisions: "",
    },
    event_suitability: {
      functions_covered: [],
      best_for: [],
    },
    image_video_tagging: {
      notes: "",
      tags: "Function Type, Shot Type, Lighting Type, Mood, Location Type",
    },
  };
}
