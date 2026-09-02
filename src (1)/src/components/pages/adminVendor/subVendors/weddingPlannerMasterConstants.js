export const PLANNER_TYPES = [
  "Individual Planner",
  "Boutique Agency",
  "Full-Service Agency",
  "Luxury Wedding Planner",
  "Other"
];

export const SERVICE_COVERAGE = [
  "Local Only",
  "Pan India",
  "International",
  "Other"
];

export const TEAM_SIZE = [
  "1-3",
  "4-10",
  "10-25",
  "25+",
  "Other"
];

export const SERVICES_OFFERED = [
  "End-to-End Wedding Planning",
  "Partial Planning",
  "Wedding Day Coordination",
  "Destination Wedding Planning",
  "Vendor Management",
  "Budget Planning",
  "Guest Management",
  "RSVP Management",
  "Hospitality Management",
  "Logistics & Travel Planning",
  "Theme Planning",
  "Decor Coordination",
  "Entertainment Planning",
  "Other"
];

export const PLANNING_TYPE = [
  "Full Planning",
  "Partial Planning",
  "Execution Only",
  "Other"
];

export const VENDOR_SOURCING = [
  "Own Vendor Network",
  "Open to Client Vendors",
  "Both",
  "Other"
];

export const EVENTS_MANAGED_PER_YEAR = [
  "0-10",
  "10-25",
  "25-50",
  "50+",
  "Other"
];

export const GUEST_HANDLING_CAPACITY = [
  "Up to 100",
  "100-300",
  "300-500",
  "500-1000",
  "1000+",
  "Other"
];

export const EXPERTISE_IN = [
  "Destination Weddings",
  "Luxury Weddings",
  "Budget Weddings",
  "Intimate Weddings",
  "Big Fat Weddings",
  "Cross-Cultural Weddings",
  "Other"
];

export const FUNCTIONS_MANAGED = [
  "Haldi",
  "Mehendi",
  "Sangeet",
  "Wedding",
  "Reception",
  "Cocktail",
  "Engagement",
  "Other"
];

export const DESTINATION_WEDDING_SUPPORT = ["Yes", "No", "Other"];

export const DESTINATIONS_COVERED = [
  "Mumbai", "Pune", "Goa", "Udaipur", "Jaipur", "Delhi",
  "Bengaluru", "Hyderabad", "Nashik", "Ahmedabad", "Nagpur",
  "Jodhpur", "Chennai", "Kolkata", "Aurangabad", "Jaisalmer",
  "All Over India", "International", "Other"
];

export const MINIMUM_BUDGET_HANDLED = [
  "Below ₹5L",
  "₹5L-₹10L",
  "₹10L-₹25L",
  "₹25L-₹50L",
  "₹50L+",
  "Other"
];

export const MAXIMUM_BUDGET_HANDLED = [
  "₹10L",
  "₹25L",
  "₹50L",
  "₹1Cr",
  "₹1Cr+",
  "Other"
];

export const PRICING_MODEL = [
  "Fixed Fee",
  "Percentage of Budget",
  "Per Event",
  "Other"
];

export const PLANNING_FEES_RANGE = [
  "Below ₹50K",
  "₹50K-₹1L",
  "₹1L-13L",
  "₹3L-₹5L",
  "₹5L+",
  "Other"
];

export const COMMISSION_FROM_VENDORS = ["Yes", "No", "Depends", "Other"];

export const THEMES_EXPERTISE = [
  "Royal",
  "Minimal",
  "Floral",
  "Bohemian",
  "Bollywood",
  "Destination Theme",
  "Traditional",
  "Other"
];

export const VENDOR_CATEGORIES_MANAGED = [
  "Venue",
  "Decor",
  "Catering",
  "Photography",
  "Makeup",
  "Entertainment",
  "Logistics",
  "Other"
];

export const ADVANCE_PERCENTAGE = ["25%", "50%", "75%", "Other"];
export const BOOKING_TIMELINE = ["1 Month Before", "3 Months Before", "6 Months Before", "Other"];
export const REVISION_FLEXIBILITY = ["High", "Medium", "Limited", "Other"];
export const CANCELLATION_POLICY = ["Non Refundable", "Partial Refund", "Flexible", "Other"];

export const BEST_FOR = [
  "Budget Weddings",
  "Luxury Weddings",
  "Destination Weddings",
  "Intimate Weddings",
  "Large Weddings",
  "Other"
];

export const IDEAL_CLIENT_TYPE = [
  "Hands-On Clients",
  "Fully Managed Clients",
  "NRI Clients",
  "Destination Clients",
  "Other"
];

export function emptyWeddingPlannerMaster() {
  return {
    identity: {
      company_name: "",
      planner_type: "",
      planner_type_other: "",
      years_of_experience: "",
      city: "",
      service_coverage: "",
      service_coverage_other: "",
      team_size: "",
      team_size_other: ""
    },
    services: {
      services_offered: [],
      services_offered_other: "",
      planning_type: [],
      planning_type_other: "",
      vendor_sourcing: "",
      vendor_sourcing_other: ""
    },
    scale: {
      events_managed_per_year: "",
      events_managed_per_year_other: "",
      guest_handling_capacity: "",
      guest_handling_capacity_other: "",
      expertise_in: [],
      expertise_in_other: "",
      functions_managed: [],
      functions_managed_other: ""
    },
    logistics: {
      destination_wedding_support: "",
      destinations_covered: [],
      destinations_covered_other: "",
      travel_logistics_management: "",
      guest_accommodation_management: "",
      transportation_management: ""
    },
    budget: {
      minimum_budget_handled: "",
      minimum_budget_handled_other: "",
      maximum_budget_handled: "",
      maximum_budget_handled_other: "",
      pricing_model: "",
      pricing_model_other: "",
      planning_fees_range: "",
      planning_fees_range_other: "",
      commission_from_vendors: "",
      commission_from_vendors_other: ""
    },
    design: {
      theme_planning_support: "",
      themes_expertise: [],
      themes_expertise_other: "",
      moodboard_creation: "",
      custom_concept_design: ""
    },
    vendor_management: {
      vendor_categories_managed: [],
      vendor_categories_managed_other: "",
      vendor_negotiation_support: "",
      vendor_bundling: ""
    },
    technology: {
      digital_planning_tools: "",
      real_time_coordination_team: "",
      timeline_planning: "",
      checklist_management: "",
      on_ground_execution_team: ""
    },
    workflow: {
      advance_required: "",
      advance_percentage: "",
      advance_percentage_other: "",
      booking_timeline: "",
      booking_timeline_other: "",
      cancellation_policy: "",
      cancellation_policy_other: "",
      revision_flexibility: "",
      revision_flexibility_other: ""
    },
    suitability: {
      best_for: [],
      best_for_other: "",
      ideal_client_type: [],
      ideal_client_type_other: ""
    }
  };
}
