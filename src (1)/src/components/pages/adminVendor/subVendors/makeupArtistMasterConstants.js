/**
 * Bridal makeup artist master profile — persisted as `makeup_artist_master` on vendor service attributes.
 */

export const ARTIST_TYPE = [
  "Individual Freelancer",
  "Studio Owner",
  "Salon Based",
  "Celebrity Makeup Artist",
];

export const SERVICES_OFFERED_MUA = [
  "Bridal Makeup",
  "Groom Makeup",
  "Family / Siders Makeup",
  "Engagement Makeup",
  "Reception Makeup",
  "Party Makeup",
  "Hairstyling",
  "Draping",
];

export const CATEGORIES_COVERED_MUA = [
  "Bridal",
  "Groom",
  "Bridesmaids",
  "Family Members",
];

export const MAKEUP_ARTIST_CITIES = [
  "Mumbai",
  "Delhi NCR",
  "Bengaluru",
  "Hyderabad",
  "Chennai",
  "Kolkata",
  "Pune",
  "Ahmedabad",
  "Jaipur",
  "Lucknow",
  "Chandigarh",
  "Indore",
  "Nagpur",
  "Surat",
  "Vadodara",
  "Kochi",
  "Goa",
  "Udaipur",
  "Jodhpur",
  "Nashik",
  "Visakhapatnam",
  "Patna",
  "Bhopal",
  "Kanpur",
  "Agra",
  "Other",
];

export const TRAVEL_AVAILABILITY_MUA = [
  "Local Only",
  "Pan India",
  "International",
];

export const SIGNATURE_MAKEUP_STYLE = [
  "HD Makeup",
  "Airbrush Makeup",
  "Natural Makeup",
  "Glam Makeup",
  "Minimal Makeup",
  "Matte Finish",
  "Dewy Finish",
];

export const EXPERTISE_IN_MUA = [
  "Bridal Looks",
  "Editorial Looks",
  "Traditional Looks",
  "Contemporary Looks",
  "Celebrity Style Looks",
];

export const BEST_KNOWN_FOR_MUA = [
  "Natural Skin Finish",
  "Long-Lasting Makeup",
  "Glam Transformations",
  "Subtle Bridal Looks",
  "Bold Makeup Looks",
];

export const IDEAL_CLIENT_TYPE_MUA = [
  "Budget Brides",
  "Luxury Brides",
  "Destination Brides",
  "Minimalist Brides",
  "Glam Brides",
];

export const SKIN_TYPES_HANDLED = [
  "Dry Skin",
  "Oily Skin",
  "Combination Skin",
  "Sensitive Skin",
  "Acne-Prone Skin",
];

export const SKIN_TONE_EXPERTISE = [
  "Fair",
  "Medium",
  "Dusky",
  "Deep",
];

export const YES_NO_EXTRA_CHARGES = ["Yes", "No", "Extra Charges"];

export const PRODUCT_CATEGORY_MUA = [
  "Luxury Brands",
  "Premium Brands",
  "Mixed Brands",
];

export const BRANDS_LUXURY = [
  "Dior",
  "Chanel",
  "Charlotte Tilbury",
  "Estée Lauder",
  "NARS",
  "MAC Cosmetics",
  "Bobbi Brown",
  "Pat McGrath Labs",
  "Tom Ford Beauty",
  "Giorgio Armani Beauty",
  "YSL Beauty",
  "Fenty Beauty",
  "Laura Mercier",
  "Clé de Peau Beauté",
  "Sisley Paris",
  "Valentino Beauty",
  "Hourglass",
];

export const BRANDS_PREMIUM = [
  "Kryolan",
  "Make Up For Ever",
  "Smashbox",
  "Too Faced",
  "Benefit Cosmetics",
  "Anastasia Beverly Hills",
  "Huda Beauty",
  "Kiko Milano",
  "Inglot",
  "Sephora Collection",
  "Kay Beauty",
  "Colorbar",
  "Rare Beauty",
  "Tarte Cosmetics",
  "Forever52",
];

export const BRANDS_BASIC = [
  "Maybelline New York",
  "L'Oréal Paris",
  "Lakmé",
  "Nykaa Cosmetics",
  "SUGAR Cosmetics",
  "Swiss Beauty",
  "Insight Cosmetics",
  "Faces Canada",
  "Wet n Wild",
  "e.l.f. Cosmetics",
  "Essence",
  "NYX Professional Makeup",
  "Revlon",
];

export const BRANDS_ALL_MUA = [
  ...BRANDS_LUXURY,
  ...BRANDS_PREMIUM,
  ...BRANDS_BASIC,
];

export const HYGIENE_PRACTICES = [
  "Disposable Applicators",
  "Brush Sanitization",
  "Fresh Sponges",
  "Individual Kits",
];

export const BRIDAL_PACKAGE_INCLUDES = [
  "Makeup",
  "Hairstyling",
  "Draping",
  "Nail Prep",
  "Touch-Up Kit",
];

export const NUMBER_OF_LOOKS_INCLUDED = [
  "1 Look",
  "2 Looks",
  "3 Looks",
  "4+ Looks",
];

export const TRIAL_COST_OPTIONS = [
  "Free",
  "Paid",
  "Adjustable in final booking",
];

export const TOUCH_UP_SERVICE = [
  "Included",
  "Extra Cost",
  "Not Available",
];

export const PRICING_TYPE_MUA = ["Per Function", "Package Based"];

export const GROOM_MAKEUP_COST = [
  "Included",
  "Extra Charge",
  "Not Offered",
];

export const FAMILY_MAKEUP_COST = [
  "Per Person",
  "Package",
  "Not Offered",
];

export const TRAVEL_CHARGES_MUA = [
  "Included",
  "Extra",
  "Depends on Location",
];

export const STAY_REQUIRED_MUA = ["Yes", "No", "Depends on Location"];

export const ADVANCE_PERCENTAGE_MUA = ["25%", "50%", "75%"];

export const BOOKING_TIMELINE_MUA = [
  "1 Month Before",
  "3 Months Before",
  "6 Months Before",
];

export const CANCELLATION_POLICY_MUA = [
  "Non Refundable",
  "Partial Refund",
  "Flexible",
];

export const DELAY_HANDLING = ["Flexible", "Extra Charges Apply"];

export const FUNCTIONS_COVERED_MUA = [
  "Engagement",
  "Mehendi",
  "Haldi",
  "Sangeet",
  "Wedding",
  "Reception",
];

export const BEST_FOR_MUA = [
  "Day Weddings",
  "Night Weddings",
  "Destination Weddings",
  "Indoor Events",
  "Outdoor Events",
];

export const AI_FAQ_CANCELLATION = ["Cancellable", "Non-Cancellable"];

export function emptyMakeupArtistMaster() {
  return {
    identity: {
      brand_artist_name: "",
      artist_type: "",
      services_offered: [],
      categories_covered: [],
      years_of_experience: "",
      cities: [],
      travel_availability: "",
    },
    makeup_style_intelligence: {
      signature_makeup_style: [],
      expertise_in: [],
      best_known_for: [],
      ideal_client_type: [],
    },
    skin_hair_expertise: {
      skin_types_handled: [],
      skin_tone_expertise: [],
      skin_care_consultation: "",
      hairstyling_included: "",
      hair_extensions: "",
      draping_included: "",
      lashes_lenses_included: "",
      outfit_styling_guidance: "",
    },
    products_brands: {
      product_category: "",
      brands_luxury: [],
      brands_premium: [],
      brands_basic: [],
      hygiene_practices: [],
    },
    bridal_package: {
      package_includes: [],
      number_of_looks: "",
      trial_makeup_available: "",
      trial_cost: "",
      touch_up_service: "",
    },
    pricing_structure: {
      bridal_makeup_starting_price: "",
      pricing_type: "",
      groom_makeup_cost: "",
      family_makeup_cost: "",
      family_price_note: "",
      travel_charges: "",
      stay_required: "",
    },
    workflow_process: {
      advance_required: "",
      advance_percentage: "",
      booking_timeline: "",
      cancellation_policy: "",
      delay_handling: "",
    },
    event_suitability: {
      functions_covered: [],
      best_for: [],
    },
    portfolio_intelligence: {
      tagging_guidance:
        "Skin Tone, Makeup Style, Function Type, Lighting Condition, Outfit Color",
      notes: "",
    },
    ai_faq: {
      hd_makeup: "",
      airbrush_makeup: "",
      hairstyling_included: "",
      draping_included: "",
      trial_available: "",
      trial_cost: "",
      travel_available: "",
      touchup_included: "",
      skin_prep_included: "",
      brands_used: [],
      suitable_skin_types: [],
      suitable_skin_tones: [],
      groom_makeup_offered: "",
      advance_required: "",
      cancellation_policy: "",
    },
  };
}
