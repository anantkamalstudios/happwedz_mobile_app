export const INVITATION_VENDOR_TYPE = [
  "Invitation Designer (Digital)",
  "Invitation Printer (Physical)",
  "Full-Service Invitation Studio",
  "Luxury Invitation Brand",
  "DIY Template Provider",
];
export const YEARS_OF_EXPERIENCE = ["0–1", "1–3", "3–5", "5–10", "10+"];
export const SERVICE_MODE = [
  "Digital Only",
  "Physical Only",
  "Hybrid",
];
export const DELIVERY_MODEL = [
  "Courier",
  "Pickup",
  "Pan-India Shipping",
  "International Shipping",
];
export const INVITATION_TYPES = [
  "Save the Date",
  "Wedding Invite Card",
  "E-Invite",
  "Video Invite",
  "WhatsApp Invite",
  "Website Invite",
  "Box Invitations",
];
export const EVENT_COVERAGE = [
  "Engagement",
  "Mehendi",
  "Haldi",
  "Sangeet",
  "Wedding",
  "Reception",
  "Multi-day Wedding Suite",
];
export const DESIGN_FORMATS = [
  "Static Design",
  "Animated Invite",
  "Video Invite",
  "Interactive Website",
];
export const LANGUAGE_OPTIONS = [
  "English",
  "Hindi",
  "Marathi",
  "Gujarati",
  "Punjabi",
  "Tamil",
  "Telugu",
  "Bengali",
  "Multi-language",
];
export const DESIGN_STYLE_INVITATION = [
  "Royal / Regal",
  "Minimal / Elegant",
  "Floral / Pastel",
  "Modern / Contemporary",
  "Traditional / Cultural",
  "Illustrated / Caricature",
];
export const CUSTOMIZATION_LEVEL = [
  "Fully Custom",
  "Semi-Custom",
  "Template-Based",
];
export const THEME_MATCHING = [
  "Yes (Full wedding theme sync)",
  "Partial",
  "No",
];
export const PERSONALIZATION_OPTIONS_INVITATION = [
  "Names",
  "Monogram",
  "Couple Story",
  "Photos",
  "Venue Illustration",
  "Custom Artwork",
];
export const PRINT_MATERIAL_OPTIONS = [
  "Paper (Matte / Gloss)",
  "Handmade Paper",
  "Acrylic",
  "Fabric (Silk)",
  "Wood",
  "Metal",
];
export const SPECIAL_FEATURES = [
  "Laser Cut",
  "Foil Printing",
  "Embossing / Debossing",
  "UV Print",
  "Scented Invites",
  "LED / Music Box Invites",
];
export const E_INVITE_FORMATS = [
  "PDF",
  "GIF",
  "MP4 Video",
  "Interactive Link",
];
export const WEBSITE_INVITE_FEATURES = [
  "RSVP Management",
  "Event Schedule",
  "Google Maps Integration",
  "Photo Gallery",
  "Countdown Timer",
  "Guest Messaging",
];
export const MIN_ORDER_QTY = ["1–50", "50–100", "100–300", "300+"];
export const MAX_ORDER_CAPACITY = ["100", "100–500", "500–1000", "1000+"];
export const TURNAROUND_TIME = ["2–5 days (Digital)", "5–10 days", "10–20 days", "20+ days"];
export const PROOFING_PROCESS = ["Digital Proof", "Physical Sample", "Both"];
export const PACKAGING_OPTIONS = ["Basic Packaging", "Premium Boxes", "Customized Boxes"];
export const PRICING_MODEL_INVITATION = [
  "Per Card",
  "Per Design",
  "Per Video",
  "Package",
];
export const STARTING_PRICE_RANGE = [
  "₹20–₹50/card",
  "₹50–₹150/card",
  "₹150–₹500/card",
  "₹500–₹2000/card",
  "₹2000+ (Luxury)",
];
export const DIGITAL_INVITE_PRICING = [
  "₹500–₹2k",
  "₹2k–₹5k",
  "₹5k–₹15k",
  "₹15k+",
];
export const INCLUDES_INVITATION = [
  "Design",
  "Printing",
  "Packaging",
  "Delivery",
  "Revisions",
];
export const ADDONS_INVITATION = [
  "Extra Revisions",
  "Express Delivery",
  "Premium Materials",
  "Custom Artwork",
];
export const NEGOTIATION = ["Fixed", "Moderate", "Flexible"];
export const ORDERS_PER_MONTH = ["<50", "50–200", "200–500", "500+"];
export const TEAM_SIZE = ["Solo", "2–5", "5–10", "10+"];
export const ADVANCE_BOOKING_TIME = ["<1 week", "1–2 weeks", "2–4 weeks", "1–2 months"];
export const BOOKING_ADVANCE = ["25%", "50%", "75%", "100%"];
export const CANCELLATION_POLICY = ["Non-refundable", "Partial refund", "Flexible"];
export const CLIENT_COORDINATION = ["WhatsApp", "Call", "Email", "App-based"];

export const emptyInvitationMaster = () => ({
  identity: {
    vendor_type: "",
    brand_name: "",
    years_of_experience: "",
    primary_city: "",
    service_cities: [],
    service_mode: "",
    delivery_model: "",
  },
  services: {
    invitation_types: [],
    event_coverage: [],
    design_formats: "",
    language_options: [],
  },
  intelligence: {
    design_style: [],
    customization_level: "",
    theme_matching_capability: "",
    personalization_options: [],
    print_material_options: [],
    special_features: [],
  },
  digital_intelligence: {
    e_invite_formats: "",
    website_invite_features: [],
    rsvp_tracking: "",
    whatsapp_integration: "",
    qr_code_integration: "",
  },
  production: {
    minimum_order_quantity: "",
    maximum_order_capacity: "",
    turnaround_time: "",
    sample_availability: "",
    proofing_process: "",
    packaging_options: "",
  },
  pricing: {
    pricing_model: "",
    starting_price_range: "",
    digital_invite_pricing: "",
    includes: [],
    add_ons: [],
    negotiation_flexibility: "",
  },
  scale: {
    orders_per_month_capacity: "",
    team_size: "",
    parallel_order_handling: "",
  },
  workflow: {
    advance_booking_time: "",
    booking_advance_percent: "",
    cancellation_policy: "",
    client_coordination: "",
  },
  portfolio: {
    design_tags: "",
    format_tags: "",
    event_tags: "",
  },
  ai_faq: {
    create_digital_invites: "",
    print_physical_cards: "",
    invitations_customizable: "",
    match_wedding_theme: "",
    rsvp_tracking_available: "",
    deliver_across_india: "",
    luxury_materials_available: "",
    include_couple_story: "",
    whatsapp_invite_supported: "",
    create_website_invites: "",
    samples_available_before_order: "",
    handle_bulk_orders: "",
    express_delivery_available: "",
  },
});
