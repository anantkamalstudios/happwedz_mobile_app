import React, { useCallback, useMemo, useEffect } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  CHOREO_VENDOR_TYPE,
  CHOREO_EVENT_TYPES,
  CHOREO_DANCE_FORMATS,
  CHOREO_SPECIAL_OFFERINGS,
  CHOREO_DANCE_STYLES,
  CHOREO_SKILL_LEVEL,
  CHOREO_AGE_GROUP,
  CHOREO_MAX_PARTICIPANTS,
  CHOREO_CUSTOMIZATION,
  CHOREO_REHEARSAL_MODE,
  CHOREO_POLISH_LEVEL,
  CHOREO_REHEARSAL_SESSIONS,
  CHOREO_SESSION_DURATION,
  CHOREO_PRACTICE_LOCATION,
  CHOREO_ON_EVENT_PRESENCE,
  CHOREO_MUSIC_EDITING,
  CHOREO_PRICING_MODEL,
  CHOREO_STARTING_PRICE,
  CHOREO_INCLUDES,
  CHOREO_ADDONS,
  CHOREO_MAX_EVENTS_PER_DAY,
  CHOREO_TEAM_SIZE,
  CHOREO_ADVANCE_BOOKING,
  CHOREO_ADVANCE_PERCENT,
  CHOREO_CANCELLATION_POLICY,
  CHOREO_COORDINATION_MODE,
  CHOREO_PERFORMANCE_STYLE_TAGS,
  CHOREO_EVENT_SCALE_TAGS,
  CHOREO_CHOREOGRAPHY_STYLE_TAGS,
  CHOREO_NEGOTIATION,
  CHOREO_LANGUAGES,
  emptySangeetChoreographerMaster,
} from "./sangeetChoreographerMasterConstants";

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

const SangeetChoreographerMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const sc = useMemo(() => {
    const raw = formData.sangeet_choreographer_master || formData.attributes?.sangeet_choreographer_master;
    const base = emptySangeetChoreographerMaster();

    if (raw && typeof raw === "object") {
      const migrated = mergeDeep(base, raw);

      // Migrate identity
      if (raw.brand_name && !raw.identity?.brand_name) migrated.identity.brand_name = raw.brand_name;
      if (raw.primary_city && !raw.identity?.primary_city) migrated.identity.primary_city = raw.primary_city;
      if (raw.service_cities && !raw.identity?.service_cities) migrated.identity.service_cities = raw.service_cities;
      if (raw.vendor_type && !raw.identity?.vendor_type) migrated.identity.vendor_type = raw.vendor_type;
      if (raw.years_of_experience && !raw.identity?.years_of_experience) migrated.identity.years_of_experience = raw.years_of_experience;
      if (raw.travel_policy && !raw.identity?.travel_policy) migrated.identity.travel_policy = raw.travel_policy;
      if (raw.languages && !raw.identity?.languages) migrated.identity.languages = raw.languages;

      return migrated;
    }
    return base;
  }, [formData.sangeet_choreographer_master, formData.attributes?.sangeet_choreographer_master]);

  const patchSc = useCallback(
    (partial, replace = false) => {
      setFormData((prev) => {
        const base = replace ? emptySangeetChoreographerMaster() : (
          prev.sangeet_choreographer_master ||
          prev.attributes?.sangeet_choreographer_master ||
          emptySangeetChoreographerMaster()
        );
        const next = mergeDeep(base, partial);
        return {
          ...prev,
          sangeet_choreographer_master: next,
          attributes: {
            ...(prev.attributes || {}),
            sangeet_choreographer_master: next,
          },
        };
      });
    },
    [setFormData]
  );

  useEffect(() => {
    const raw = formData.sangeet_choreographer_master || formData.attributes?.sangeet_choreographer_master;
    if (raw && typeof raw === "object") {
      if (raw.brand_name && !raw.identity?.brand_name) {
        patchSc(sc, true);
      } else if (raw.event_types && !raw.services?.event_types) {
        patchSc(sc, true);
      }
    }
  }, [sc, formData.sangeet_choreographer_master, formData.attributes?.sangeet_choreographer_master, patchSc]);

  const save = async () => {
    if (onSave) await onSave();
    if (onShowSuccess) onShowSuccess();
  };

  const inner = (
    <>
      <h4 className="mb-2 fw-bold">Sangeet choreographer master profile</h4>
      <p className="text-muted fs-14 mb-4">
        Structured choreographer attributes for storefront and AI FAQ matching.
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
                value={sc.identity.brand_name || ""}
                onChange={(e) =>
                  patchSc({
                    identity: { ...sc.identity, brand_name: e.target.value },
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
              value={sc.identity.primary_city}
              onChange={(v) =>
                patchSc({ identity: { ...sc.identity, primary_city: v } })
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
              value={sc.identity.service_cities}
              onChange={(v) =>
                patchSc({ identity: { ...sc.identity, service_cities: v } })
              }
            />
            <SelectField
              label="Vendor type"
              options={CHOREO_VENDOR_TYPE}
              value={sc.identity.vendor_type}
              onChange={(v) =>
                patchSc({ identity: { ...sc.identity, vendor_type: v } })
              }
            />
            <div className="mb-3">
              <label className="form-label fw-semibold">
                Years of experience
              </label>
              <Form.Control
                type="number"
                className="fs-14"
                value={sc.identity.years_of_experience}
                onChange={(e) =>
                  patchSc({
                    identity: {
                      ...sc.identity,
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
                "Extra (fixed)",
                "Extra (per km)",
                "Case-by-case",
              ]}
              value={sc.identity.travel_policy}
              onChange={(v) =>
                patchSc({ identity: { ...sc.identity, travel_policy: v } })
              }
            />
            <MultiCheck
              label="Languages comfortable"
              options={CHOREO_LANGUAGES}
              value={sc.identity.languages}
              onChange={(v) =>
                patchSc({ identity: { ...sc.identity, languages: v } })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 2 — Services Offered */}
        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Services offered</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Event types covered"
              options={CHOREO_EVENT_TYPES}
              value={sc.services.event_types}
              onChange={(v) =>
                patchSc({ services: { ...sc.services, event_types: v } })
              }
            />
            <MultiCheck
              label="Dance formats"
              options={CHOREO_DANCE_FORMATS}
              value={sc.services.dance_formats}
              onChange={(v) =>
                patchSc({ services: { ...sc.services, dance_formats: v } })
              }
            />
            <MultiCheck
              label="Special offerings"
              options={CHOREO_SPECIAL_OFFERINGS}
              value={sc.services.special_offerings}
              onChange={(v) =>
                patchSc({
                  services: { ...sc.services, special_offerings: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 3 — Core Intelligence */}
        <Accordion.Item eventKey="2">
          <Accordion.Header>
            Section 3 — Core intelligence (choreography-specific)
          </Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Dance styles expertise"
              options={CHOREO_DANCE_STYLES}
              value={sc.core_intelligence.dance_styles}
              onChange={(v) =>
                patchSc({
                  core_intelligence: {
                    ...sc.core_intelligence,
                    dance_styles: v,
                  },
                })
              }
            />
            <SelectField
              label="Skill level handling"
              options={CHOREO_SKILL_LEVEL}
              value={sc.core_intelligence.skill_level_handling}
              onChange={(v) =>
                patchSc({
                  core_intelligence: {
                    ...sc.core_intelligence,
                    skill_level_handling: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Age group handling"
              options={CHOREO_AGE_GROUP}
              value={sc.core_intelligence.age_group_handling}
              onChange={(v) =>
                patchSc({
                  core_intelligence: {
                    ...sc.core_intelligence,
                    age_group_handling: v,
                  },
                })
              }
            />
            <SelectField
              label="Max participants per act"
              options={CHOREO_MAX_PARTICIPANTS}
              value={sc.core_intelligence.max_participants_per_act}
              onChange={(v) =>
                patchSc({
                  core_intelligence: {
                    ...sc.core_intelligence,
                    max_participants_per_act: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="sc_story_choreo"
              label="Story-based choreography"
              value={sc.core_intelligence.story_based_choreography}
              onChange={(v) =>
                patchSc({
                  core_intelligence: {
                    ...sc.core_intelligence,
                    story_based_choreography: v,
                  },
                })
              }
            />
            <SelectField
              label="Customization level"
              options={CHOREO_CUSTOMIZATION}
              value={sc.core_intelligence.customization_level}
              onChange={(v) =>
                patchSc({
                  core_intelligence: {
                    ...sc.core_intelligence,
                    customization_level: v,
                  },
                })
              }
            />
            <SelectField
              label="Music selection support"
              options={[
                "Yes (Full curation)",
                "Yes (Partial)",
                "No",
              ]}
              value={sc.core_intelligence.music_selection_support}
              onChange={(v) =>
                patchSc({
                  core_intelligence: {
                    ...sc.core_intelligence,
                    music_selection_support: v,
                  },
                })
              }
            />
            <SelectField
              label="Rehearsal mode"
              options={CHOREO_REHEARSAL_MODE}
              value={sc.core_intelligence.rehearsal_mode}
              onChange={(v) =>
                patchSc({
                  core_intelligence: {
                    ...sc.core_intelligence,
                    rehearsal_mode: v,
                  },
                })
              }
            />
            <SelectField
              label="Performance polish level"
              options={CHOREO_POLISH_LEVEL}
              value={sc.core_intelligence.performance_polish_level}
              onChange={(v) =>
                patchSc({
                  core_intelligence: {
                    ...sc.core_intelligence,
                    performance_polish_level: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 4 — Rehearsal Logistics */}
        <Accordion.Item eventKey="3">
          <Accordion.Header>
            Section 4 — Training & rehearsal logistics
          </Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Rehearsal sessions per act"
              options={CHOREO_REHEARSAL_SESSIONS}
              value={sc.rehearsal_logistics.rehearsal_sessions_per_act}
              onChange={(v) =>
                patchSc({
                  rehearsal_logistics: {
                    ...sc.rehearsal_logistics,
                    rehearsal_sessions_per_act: v,
                  },
                })
              }
            />
            <SelectField
              label="Session duration"
              options={CHOREO_SESSION_DURATION}
              value={sc.rehearsal_logistics.session_duration}
              onChange={(v) =>
                patchSc({
                  rehearsal_logistics: {
                    ...sc.rehearsal_logistics,
                    session_duration: v,
                  },
                })
              }
            />
            <SelectField
              label="Practice location"
              options={CHOREO_PRACTICE_LOCATION}
              value={sc.rehearsal_logistics.practice_location}
              onChange={(v) =>
                patchSc({
                  rehearsal_logistics: {
                    ...sc.rehearsal_logistics,
                    practice_location: v,
                  },
                })
              }
            />
            <SelectField
              label="Travel for practice"
              options={["Included", "Chargeable"]}
              value={sc.rehearsal_logistics.travel_for_practice}
              onChange={(v) =>
                patchSc({
                  rehearsal_logistics: {
                    ...sc.rehearsal_logistics,
                    travel_for_practice: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="sc_assistant"
              label="Assistant availability"
              value={sc.rehearsal_logistics.assistant_availability}
              onChange={(v) =>
                patchSc({
                  rehearsal_logistics: {
                    ...sc.rehearsal_logistics,
                    assistant_availability: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="sc_last_min_practice"
              label="Last-minute practice support"
              value={sc.rehearsal_logistics.last_minute_practice_support}
              onChange={(v) =>
                patchSc({
                  rehearsal_logistics: {
                    ...sc.rehearsal_logistics,
                    last_minute_practice_support: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 5 — Performance Execution */}
        <Accordion.Item eventKey="4">
          <Accordion.Header>
            Section 5 — Performance execution layer
          </Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="On-event presence"
              options={CHOREO_ON_EVENT_PRESENCE}
              value={sc.performance_execution.on_event_presence}
              onChange={(v) =>
                patchSc({
                  performance_execution: {
                    ...sc.performance_execution,
                    on_event_presence: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="sc_backstage"
              label="Backstage coordination"
              value={sc.performance_execution.backstage_coordination}
              onChange={(v) =>
                patchSc({
                  performance_execution: {
                    ...sc.performance_execution,
                    backstage_coordination: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="sc_entry_transition"
              label="Entry & transition planning"
              value={sc.performance_execution.entry_transition_planning}
              onChange={(v) =>
                patchSc({
                  performance_execution: {
                    ...sc.performance_execution,
                    entry_transition_planning: v,
                  },
                })
              }
            />
            <SelectField
              label="Music editing & mixing"
              options={CHOREO_MUSIC_EDITING}
              value={sc.performance_execution.music_editing_mixing}
              onChange={(v) =>
                patchSc({
                  performance_execution: {
                    ...sc.performance_execution,
                    music_editing_mixing: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="sc_props"
              label="Props support"
              value={sc.performance_execution.props_support}
              onChange={(v) =>
                patchSc({
                  performance_execution: {
                    ...sc.performance_execution,
                    props_support: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="sc_costume"
              label="Costume guidance"
              value={sc.performance_execution.costume_guidance}
              onChange={(v) =>
                patchSc({
                  performance_execution: {
                    ...sc.performance_execution,
                    costume_guidance: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 6 — Pricing */}
        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Pricing logic</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Pricing model"
              options={CHOREO_PRICING_MODEL}
              value={sc.pricing.pricing_model}
              onChange={(v) =>
                patchSc({ pricing: { ...sc.pricing, pricing_model: v } })
              }
            />
            <SelectField
              label="Starting price range"
              options={CHOREO_STARTING_PRICE}
              value={sc.pricing.starting_price_range}
              onChange={(v) =>
                patchSc({
                  pricing: { ...sc.pricing, starting_price_range: v },
                })
              }
            />
            <MultiCheck
              label="Includes"
              options={CHOREO_INCLUDES}
              value={sc.pricing.includes}
              onChange={(v) =>
                patchSc({ pricing: { ...sc.pricing, includes: v } })
              }
            />
            <MultiCheck
              label="Add-on charges"
              options={CHOREO_ADDONS}
              value={sc.pricing.addon_charges}
              onChange={(v) =>
                patchSc({ pricing: { ...sc.pricing, addon_charges: v } })
              }
            />
            <YesNoField
              groupName="sc_peak_pricing"
              label="Peak season pricing"
              value={sc.pricing.peak_season_pricing}
              onChange={(v) =>
                patchSc({
                  pricing: { ...sc.pricing, peak_season_pricing: v },
                })
              }
            />
            <SelectField
              label="Negotiation flexibility"
              options={CHOREO_NEGOTIATION}
              value={sc.pricing.negotiation_flexibility}
              onChange={(v) =>
                patchSc({
                  pricing: { ...sc.pricing, negotiation_flexibility: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 7 — Scale & Capacity */}
        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Scale & capacity</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Max events per day"
              options={CHOREO_MAX_EVENTS_PER_DAY}
              value={sc.scale_capacity.max_events_per_day}
              onChange={(v) =>
                patchSc({
                  scale_capacity: {
                    ...sc.scale_capacity,
                    max_events_per_day: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="sc_parallel"
              label="Parallel event handling"
              value={sc.scale_capacity.parallel_event_handling}
              onChange={(v) =>
                patchSc({
                  scale_capacity: {
                    ...sc.scale_capacity,
                    parallel_event_handling: v,
                  },
                })
              }
            />
            <SelectField
              label="Team size"
              options={CHOREO_TEAM_SIZE}
              value={sc.scale_capacity.team_size}
              onChange={(v) =>
                patchSc({
                  scale_capacity: { ...sc.scale_capacity, team_size: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 8 — Workflow & Booking */}
        <Accordion.Item eventKey="7">
          <Accordion.Header>Section 8 — Workflow & booking</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Advance booking time"
              options={CHOREO_ADVANCE_BOOKING}
              value={sc.workflow.advance_booking_time}
              onChange={(v) =>
                patchSc({
                  workflow: { ...sc.workflow, advance_booking_time: v },
                })
              }
            />
            <SelectField
              label="Booking advance %"
              options={CHOREO_ADVANCE_PERCENT}
              value={sc.workflow.booking_advance_percent}
              onChange={(v) =>
                patchSc({
                  workflow: { ...sc.workflow, booking_advance_percent: v },
                })
              }
            />
            <SelectField
              label="Cancellation policy"
              options={CHOREO_CANCELLATION_POLICY}
              value={sc.workflow.cancellation_policy}
              onChange={(v) =>
                patchSc({
                  workflow: { ...sc.workflow, cancellation_policy: v },
                })
              }
            />
            <SelectField
              label="Client coordination mode"
              options={CHOREO_COORDINATION_MODE}
              value={sc.workflow.coordination_mode}
              onChange={(v) =>
                patchSc({
                  workflow: { ...sc.workflow, coordination_mode: v },
                })
              }
            />
            <YesNoField
              groupName="sc_trial_session"
              label="Trial session availability"
              value={sc.workflow.trial_session_availability}
              onChange={(v) =>
                patchSc({
                  workflow: { ...sc.workflow, trial_session_availability: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 9 — Portfolio Tagging */}
        <Accordion.Item eventKey="8">
          <Accordion.Header>
            Section 9 — Portfolio tagging (AI layer)
          </Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Performance style tags"
              options={CHOREO_PERFORMANCE_STYLE_TAGS}
              value={sc.portfolio_tagging.performance_style_tags}
              onChange={(v) =>
                patchSc({
                  portfolio_tagging: {
                    ...sc.portfolio_tagging,
                    performance_style_tags: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Event scale tags"
              options={CHOREO_EVENT_SCALE_TAGS}
              value={sc.portfolio_tagging.event_scale_tags}
              onChange={(v) =>
                patchSc({
                  portfolio_tagging: {
                    ...sc.portfolio_tagging,
                    event_scale_tags: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Choreography style tags"
              options={CHOREO_CHOREOGRAPHY_STYLE_TAGS}
              value={sc.portfolio_tagging.choreography_style_tags}
              onChange={(v) =>
                patchSc({
                  portfolio_tagging: {
                    ...sc.portfolio_tagging,
                    choreography_style_tags: v,
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
          Save choreographer master profile
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

export default SangeetChoreographerMasterProfile;
