import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  ENT_VENDOR_TYPE,
  ENT_PERFORMER_CATEGORY,
  ENT_EVENT_TYPES,
  ENT_PERFORMANCE_TYPES,
  ENT_AUDIENCE_TYPE,
  ENT_ENGAGEMENT_STYLE,
  ENT_PERFORMANCE_DURATION,
  ENT_PERFORMANCE_SLOTS,
  ENT_CONTENT_CUSTOMIZATION,
  ENT_THEME_COMPATIBILITY,
  ENT_ENERGY_LEVEL,
  ENT_EQUIPMENT_OWNERSHIP,
  ENT_SETUP_TIME,
  ENT_TEAM_SIZE,
  ENT_AUDIENCE_SIZE,
  ENT_PRICING_MODEL,
  ENT_STARTING_PRICE,
  ENT_INCLUDES,
  ENT_ADDONS,
  ENT_ADVANCE_BOOKING,
  ENT_ADVANCE_PERCENT,
  ENT_CANCELLATION_POLICY,
  ENT_COORDINATION_MODE,
  ENT_ENTERTAINMENT_TAGS,
  ENT_PERFORMER_TAGS,
  ENT_EVENT_FIT_TAGS,
  ENT_NEGOTIATION,
  ENT_LANGUAGES,
  emptyWeddingEntertainerMaster,
} from "./weddingEntertainerMasterConstants";

const yesNo = ["Yes", "No"];

function mergeDeep(base, patch) {
  const out = { ...base };
  Object.keys(patch || {}).forEach((k) => {
    const pv = patch[k];
    const bv = base[k];
    if (
      pv &&
      typeof pv === "object" &&
      !Array.isArray(pv) &&
      bv &&
      typeof bv === "object" &&
      !Array.isArray(bv)
    ) {
      out[k] = mergeDeep(bv, pv);
    } else {
      out[k] = pv;
    }
  });
  return out;
}

const SelectField = ({ label, options, value, onChange }) => (
  <div className="mb-3">
    <label className="form-label fw-semibold">{label}</label>
    <Form.Select
      className="fs-14"
      value={value || ""}
      onChange={(e) => onChange(e.target.value)}
    >
      <option value="">Select...</option>
      {options.map((o) => (
        <option key={o} value={o}>
          {o}
        </option>
      ))}
    </Form.Select>
  </div>
);

const MultiCheck = ({ label, options, value, onChange }) => {
  const selected = Array.isArray(value) ? value : [];
  const toggle = (opt) =>
    onChange(
      selected.includes(opt)
        ? selected.filter((x) => x !== opt)
        : [...selected, opt]
    );
  return (
    <div className="mb-3">
      <label className="form-label fw-semibold">{label}</label>
      <div className="d-flex flex-wrap gap-2">
        {options.map((opt) => (
          <Form.Check
            key={opt}
            type="checkbox"
            label={opt}
            checked={selected.includes(opt)}
            onChange={() => toggle(opt)}
            className="fs-14"
          />
        ))}
      </div>
    </div>
  );
};

const YesNoField = ({ label, value, onChange, groupName }) => (
  <div className="mb-3">
    <label className="form-label fw-semibold">{label}</label>
    <div className="d-flex gap-3">
      {yesNo.map((y) => (
        <Form.Check
          key={y}
          type="radio"
          name={groupName}
          label={y}
          checked={value === y}
          onChange={() => onChange(y)}
        />
      ))}
    </div>
  </div>
);

const WeddingEntertainerMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const we = useMemo(() => {
    const raw =
      formData.wedding_entertainer_master ||
      formData.attributes?.wedding_entertainer_master;
    if (raw && typeof raw === "object")
      return mergeDeep(emptyWeddingEntertainerMaster(), raw);
    return emptyWeddingEntertainerMaster();
  }, [
    formData.wedding_entertainer_master,
    formData.attributes?.wedding_entertainer_master,
  ]);

  const patchWe = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(
          prev.wedding_entertainer_master ||
          prev.attributes?.wedding_entertainer_master ||
          emptyWeddingEntertainerMaster(),
          partial
        );
        return {
          ...prev,
          wedding_entertainer_master: next,
          attributes: {
            ...(prev.attributes || {}),
            wedding_entertainer_master: next,
          },
        };
      });
    },
    [setFormData]
  );

  const save = async () => {
    if (onSave) await onSave();
    if (onShowSuccess) onShowSuccess();
  };

  const inner = (
    <>
      <h4 className="mb-2 fw-bold">Wedding entertainer master profile</h4>
      <p className="text-muted fs-14 mb-4">
        Structured entertainer attributes for storefront and AI FAQ matching.
      </p>

      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        {/* Section 1 — Basic Identity */}
        <Accordion.Item eventKey="0">
          <Accordion.Header>Section 1 — Basic identity</Accordion.Header>
          <Accordion.Body>
            {/* <div className="mb-3">
              <label className="form-label fw-semibold">
                Brand / Stage Name
              </label>
              <Form.Control
                type="text"
                className="fs-14"
                value={we.identity.brand_name || ""}
                onChange={(e) =>
                  patchWe({
                    identity: { ...we.identity, brand_name: e.target.value },
                  })
                }
                placeholder="Enter Brand / Stage Name"
              />
            </div> */}
            <SelectField
              label="Primary City"
              options={[
                "Delhi NCR",
                "Mumbai",
                "Bangalore",
                "Hyderabad",
                "Chennai",
                "Kolkata",
                "Pune",
                "Ahmedabad",
                "Jaipur",
                "Chandigarh",
                "Lucknow",
                "Goa",
                "Other",
              ]}
              value={we.identity.primary_city}
              onChange={(v) =>
                patchWe({ identity: { ...we.identity, primary_city: v } })
              }
            />
            <MultiCheck
              label="Service Cities"
              options={[
                "Pan-India",
                "International",
                "Delhi NCR",
                "Mumbai",
                "Bangalore",
                "Hyderabad",
                "Chennai",
                "Kolkata",
                "Pune",
                "Ahmedabad",
                "Jaipur",
                "Chandigarh",
                "Lucknow",
                "Goa",
                "Other",
              ]}
              value={we.identity.service_cities}
              onChange={(v) =>
                patchWe({ identity: { ...we.identity, service_cities: v } })
              }
            />
            <SelectField
              label="Vendor type"
              options={ENT_VENDOR_TYPE}
              value={we.identity.vendor_type}
              onChange={(v) =>
                patchWe({ identity: { ...we.identity, vendor_type: v } })
              }
            />
            <SelectField
              label="Performer category (primary)"
              options={ENT_PERFORMER_CATEGORY}
              value={we.identity.performer_category}
              onChange={(v) =>
                patchWe({
                  identity: { ...we.identity, performer_category: v },
                })
              }
            />
            {we.identity.performer_category === "Other" && (
              <div className="mb-3">
                <label className="form-label fw-semibold">
                  Performer category (specify)
                </label>
                <Form.Control
                  type="text"
                  className="fs-14"
                  placeholder="Enter performer category"
                  value={we.identity.performer_category_other}
                  onChange={(e) =>
                    patchWe({
                      identity: {
                        ...we.identity,
                        performer_category_other: e.target.value,
                      },
                    })
                  }
                />
              </div>
            )}
            <div className="mb-3">
              <label className="form-label fw-semibold">
                Years of experience
              </label>
              <Form.Control
                type="number"
                className="fs-14"
                value={we.identity.years_of_experience}
                onChange={(e) =>
                  patchWe({
                    identity: {
                      ...we.identity,
                      years_of_experience: e.target.value,
                    },
                  })
                }
              />
            </div>
            <SelectField
              label="Travel policy"
              options={[
                "Included (local)",
                "Fixed Cost",
                "Per Km",
                "Case-by-case",
              ]}
              value={we.identity.travel_policy}
              onChange={(v) =>
                patchWe({ identity: { ...we.identity, travel_policy: v } })
              }
            />
            <MultiCheck
              label="Languages"
              options={ENT_LANGUAGES}
              value={we.identity.languages}
              onChange={(v) =>
                patchWe({ identity: { ...we.identity, languages: v } })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 2 — Services Offered */}
        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Services offered</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Event types"
              options={ENT_EVENT_TYPES}
              value={we.services.event_types}
              onChange={(v) =>
                patchWe({ services: { ...we.services, event_types: v } })
              }
            />
            <MultiCheck
              label="Performance types"
              options={ENT_PERFORMANCE_TYPES}
              value={we.services.performance_types}
              onChange={(v) =>
                patchWe({
                  services: { ...we.services, performance_types: v },
                })
              }
            />
            <MultiCheck
              label="Audience type handling"
              options={ENT_AUDIENCE_TYPE}
              value={we.services.audience_type_handling}
              onChange={(v) =>
                patchWe({
                  services: { ...we.services, audience_type_handling: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 3 — Core Intelligence */}
        <Accordion.Item eventKey="2">
          <Accordion.Header>
            Section 3 — Core intelligence (entertainment-specific)
          </Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Engagement style"
              options={ENT_ENGAGEMENT_STYLE}
              value={we.core_intelligence.engagement_style}
              onChange={(v) =>
                patchWe({
                  core_intelligence: {
                    ...we.core_intelligence,
                    engagement_style: v,
                  },
                })
              }
            />
            <SelectField
              label="Performance duration options"
              options={ENT_PERFORMANCE_DURATION}
              value={we.core_intelligence.performance_duration}
              onChange={(v) =>
                patchWe({
                  core_intelligence: {
                    ...we.core_intelligence,
                    performance_duration: v,
                  },
                })
              }
            />
            <SelectField
              label="Performance slots"
              options={ENT_PERFORMANCE_SLOTS}
              value={we.core_intelligence.performance_slots}
              onChange={(v) =>
                patchWe({
                  core_intelligence: {
                    ...we.core_intelligence,
                    performance_slots: v,
                  },
                })
              }
            />
            <SelectField
              label="Content customization"
              options={ENT_CONTENT_CUSTOMIZATION}
              value={we.core_intelligence.content_customization}
              onChange={(v) =>
                patchWe({
                  core_intelligence: {
                    ...we.core_intelligence,
                    content_customization: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Theme compatibility"
              options={ENT_THEME_COMPATIBILITY}
              value={we.core_intelligence.theme_compatibility}
              onChange={(v) =>
                patchWe({
                  core_intelligence: {
                    ...we.core_intelligence,
                    theme_compatibility: v,
                  },
                })
              }
            />
            <SelectField
              label="Energy level"
              options={ENT_ENERGY_LEVEL}
              value={we.core_intelligence.energy_level}
              onChange={(v) =>
                patchWe({
                  core_intelligence: {
                    ...we.core_intelligence,
                    energy_level: v,
                  },
                })
              }
            />
            <SelectField
              label="Stage requirement"
              options={["Required", "Optional", "Not Required"]}
              value={we.core_intelligence.stage_requirement}
              onChange={(v) =>
                patchWe({
                  core_intelligence: {
                    ...we.core_intelligence,
                    stage_requirement: v,
                  },
                })
              }
            />
            <SelectField
              label="Sound requirement"
              options={["Required", "Optional", "Not Required"]}
              value={we.core_intelligence.sound_requirement}
              onChange={(v) =>
                patchWe({
                  core_intelligence: {
                    ...we.core_intelligence,
                    sound_requirement: v,
                  },
                })
              }
            />
            <SelectField
              label="Lighting requirement"
              options={["Basic", "Advanced", "Custom Production"]}
              value={we.core_intelligence.lighting_requirement}
              onChange={(v) =>
                patchWe({
                  core_intelligence: {
                    ...we.core_intelligence,
                    lighting_requirement: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 4 — Technical Setup */}
        <Accordion.Item eventKey="3">
          <Accordion.Header>
            Section 4 — Technical & setup requirements
          </Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Equipment ownership"
              options={ENT_EQUIPMENT_OWNERSHIP}
              value={we.technical_setup.equipment_ownership}
              onChange={(v) =>
                patchWe({
                  technical_setup: {
                    ...we.technical_setup,
                    equipment_ownership: v,
                  },
                })
              }
            />
            <SelectField
              label="Setup time"
              options={ENT_SETUP_TIME}
              value={we.technical_setup.setup_time}
              onChange={(v) =>
                patchWe({
                  technical_setup: { ...we.technical_setup, setup_time: v },
                })
              }
            />
            <SelectField
              label="Team size"
              options={ENT_TEAM_SIZE}
              value={we.technical_setup.team_size}
              onChange={(v) =>
                patchWe({
                  technical_setup: { ...we.technical_setup, team_size: v },
                })
              }
            />
            <YesNoField
              groupName="ent_power"
              label="Power requirement"
              value={we.technical_setup.power_requirement}
              onChange={(v) =>
                patchWe({
                  technical_setup: {
                    ...we.technical_setup,
                    power_requirement: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="ent_green_room"
              label="Green room requirement"
              value={we.technical_setup.green_room_requirement}
              onChange={(v) =>
                patchWe({
                  technical_setup: {
                    ...we.technical_setup,
                    green_room_requirement: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="ent_outdoor"
              label="Outdoor suitability"
              value={we.technical_setup.outdoor_suitability}
              onChange={(v) =>
                patchWe({
                  technical_setup: {
                    ...we.technical_setup,
                    outdoor_suitability: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="ent_indoor"
              label="Indoor suitability"
              value={we.technical_setup.indoor_suitability}
              onChange={(v) =>
                patchWe({
                  technical_setup: {
                    ...we.technical_setup,
                    indoor_suitability: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 5 — Pricing */}
        <Accordion.Item eventKey="4">
          <Accordion.Header>Section 5 — Pricing logic</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Pricing model"
              options={ENT_PRICING_MODEL}
              value={we.pricing.pricing_model}
              onChange={(v) =>
                patchWe({ pricing: { ...we.pricing, pricing_model: v } })
              }
            />
            <SelectField
              label="Starting price range"
              options={ENT_STARTING_PRICE}
              value={we.pricing.starting_price_range}
              onChange={(v) =>
                patchWe({
                  pricing: { ...we.pricing, starting_price_range: v },
                })
              }
            />
            <MultiCheck
              label="Includes"
              options={ENT_INCLUDES}
              value={we.pricing.includes}
              onChange={(v) =>
                patchWe({ pricing: { ...we.pricing, includes: v } })
              }
            />
            <MultiCheck
              label="Add-ons"
              options={ENT_ADDONS}
              value={we.pricing.addons}
              onChange={(v) =>
                patchWe({ pricing: { ...we.pricing, addons: v } })
              }
            />
            <YesNoField
              groupName="ent_peak_pricing"
              label="Peak pricing"
              value={we.pricing.peak_pricing}
              onChange={(v) =>
                patchWe({ pricing: { ...we.pricing, peak_pricing: v } })
              }
            />
            <SelectField
              label="Negotiation flexibility"
              options={ENT_NEGOTIATION}
              value={we.pricing.negotiation_flexibility}
              onChange={(v) =>
                patchWe({
                  pricing: { ...we.pricing, negotiation_flexibility: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 6 — Scale & Capacity */}
        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Scale & capacity</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Audience size capability"
              options={ENT_AUDIENCE_SIZE}
              value={we.scale_capacity.audience_size_capability}
              onChange={(v) =>
                patchWe({
                  scale_capacity: {
                    ...we.scale_capacity,
                    audience_size_capability: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="ent_multi_event"
              label="Multiple event handling"
              value={we.scale_capacity.multiple_event_handling}
              onChange={(v) =>
                patchWe({
                  scale_capacity: {
                    ...we.scale_capacity,
                    multiple_event_handling: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="ent_parallel"
              label="Parallel performances"
              value={we.scale_capacity.parallel_performances}
              onChange={(v) =>
                patchWe({
                  scale_capacity: {
                    ...we.scale_capacity,
                    parallel_performances: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 7 — Workflow & Booking */}
        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Workflow & booking</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Advance booking time"
              options={ENT_ADVANCE_BOOKING}
              value={we.workflow.advance_booking_time}
              onChange={(v) =>
                patchWe({
                  workflow: { ...we.workflow, advance_booking_time: v },
                })
              }
            />
            <SelectField
              label="Booking advance %"
              options={ENT_ADVANCE_PERCENT}
              value={we.workflow.booking_advance_percent}
              onChange={(v) =>
                patchWe({
                  workflow: { ...we.workflow, booking_advance_percent: v },
                })
              }
            />
            <SelectField
              label="Cancellation policy"
              options={ENT_CANCELLATION_POLICY}
              value={we.workflow.cancellation_policy}
              onChange={(v) =>
                patchWe({
                  workflow: { ...we.workflow, cancellation_policy: v },
                })
              }
            />
            <SelectField
              label="Client coordination"
              options={ENT_COORDINATION_MODE}
              value={we.workflow.coordination_mode}
              onChange={(v) =>
                patchWe({
                  workflow: { ...we.workflow, coordination_mode: v },
                })
              }
            />
            <YesNoField
              groupName="ent_pre_briefing"
              label="Pre-event briefing"
              value={we.workflow.pre_event_briefing}
              onChange={(v) =>
                patchWe({
                  workflow: { ...we.workflow, pre_event_briefing: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 8 — Portfolio Tagging */}
        <Accordion.Item eventKey="7">
          <Accordion.Header>
            Section 8 — Portfolio tagging (AI layer)
          </Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Entertainment tags"
              options={ENT_ENTERTAINMENT_TAGS}
              value={we.portfolio_tagging.entertainment_tags}
              onChange={(v) =>
                patchWe({
                  portfolio_tagging: {
                    ...we.portfolio_tagging,
                    entertainment_tags: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Performer tags"
              options={ENT_PERFORMER_TAGS}
              value={we.portfolio_tagging.performer_tags}
              onChange={(v) =>
                patchWe({
                  portfolio_tagging: {
                    ...we.portfolio_tagging,
                    performer_tags: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Event fit tags"
              options={ENT_EVENT_FIT_TAGS}
              value={we.portfolio_tagging.event_fit_tags}
              onChange={(v) =>
                patchWe({
                  portfolio_tagging: {
                    ...we.portfolio_tagging,
                    event_fit_tags: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

      </Accordion>

      {!embedded && (
        <button
          type="button"
          className="btn btn-primary mt-3 fs-14"
          onClick={save}
        >
          Save entertainer master profile
        </button>
      )}
    </>
  );

  if (embedded) {
    return <div className="pt-4 mt-3 border-top">{inner}</div>;
  }
  return (
    <div className="my-5">
      <div className="p-3 border rounded bg-white">{inner}</div>
    </div>
  );
};

export default WeddingEntertainerMasterProfile;
