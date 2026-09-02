import React, { useCallback, useMemo, useEffect } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  DJ_VENDOR_TYPE,
  DJ_EVENT_TYPES,
  DJ_FORMATS,
  DJ_ADDITIONAL_SERVICES,
  DJ_MUSIC_GENRES,
  DJ_CROWD_HANDLING,
  DJ_SPECIALIZATION_STYLE,
  DJ_LIVE_MIXING,
  DJ_SONG_REQUEST,
  DJ_ENTRY_SYNC,
  DJ_EQUIPMENT_OWNERSHIP,
  DJ_SOUND_SETUP,
  DJ_LIGHTING_SETUP,
  DJ_CONSOLE_TYPES,
  DJ_SETUP_TIME,
  DJ_TECH_TEAM_SIZE,
  DJ_PRICING_MODEL,
  DJ_STARTING_PRICE,
  DJ_INCLUDES,
  DJ_ADDONS,
  DJ_MAX_EVENTS_PER_DAY,
  DJ_ADVANCE_BOOKING,
  DJ_ADVANCE_PERCENT,
  DJ_CANCELLATION_POLICY,
  DJ_COORDINATION_MODE,
  DJ_EVENT_MOOD_TAGS,
  DJ_MUSIC_STYLE_TAGS,
  DJ_NEGOTIATION,
  DJ_LANGUAGES,
  DJ_FAQ_QUESTIONS,
  DJ_FAQ_YES_NO,
  DJ_FAQ_SONG_REQUEST_OPTIONS,
  DJ_FAQ_SKILL_LEVEL,
  emptyDjMaster,
} from "./djMasterConstants";

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

// Reusable FAQ radio row — supports any options array
const FaqRadioField = ({ label, options, value, onChange, groupName }) => (
  <div className="mb-3 p-3 bg-light rounded">
    <label className="form-label fw-semibold mb-2 d-block">{label}</label>
    <div className="d-flex gap-3 flex-wrap">
      {options.map((opt) => (
        <Form.Check
          key={opt}
          type="radio"
          name={groupName}
          label={opt}
          checked={value === opt}
          onChange={() => onChange(opt)}
          className="fs-14"
        />
      ))}
    </div>
  </div>
);

const DjMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const dm = useMemo(() => {
    const raw = formData.dj_master || formData.attributes?.dj_master;
    const base = emptyDjMaster();

    if (raw && typeof raw === "object") {
      // If the data already has the new nested structure, mergeDeep will handle it.
      // But we also need to migrate any old flat data into the nested structure.
      const migrated = mergeDeep(base, raw);

      // Migrate identity
      if (raw.brand_name && !raw.identity?.brand_name) migrated.identity.brand_name = raw.brand_name;
      if (raw.primary_city && !raw.identity?.primary_city) migrated.identity.primary_city = raw.primary_city;
      if (raw.service_cities && !raw.identity?.service_cities) migrated.identity.service_cities = raw.service_cities;
      if (raw.vendor_type && !raw.identity?.vendor_type) migrated.identity.vendor_type = raw.vendor_type;
      if (raw.years_of_experience && !raw.identity?.years_of_experience) migrated.identity.years_of_experience = raw.years_of_experience;
      if (raw.travel_policy && !raw.identity?.travel_policy) migrated.identity.travel_policy = raw.travel_policy;
      if (raw.languages && !raw.identity?.languages) migrated.identity.languages = raw.languages;

      // Migrate services
      if (raw.event_types && !raw.services?.event_types) migrated.services.event_types = raw.event_types;
      if (raw.dj_formats && !raw.services?.dj_formats) migrated.services.dj_formats = raw.dj_formats;
      if (raw.additional_services && !raw.services?.additional_services) migrated.services.additional_services = raw.additional_services;

      // Migrate core_intelligence
      if (raw.music_genres && !raw.core_intelligence?.music_genres) migrated.core_intelligence.music_genres = raw.music_genres;
      if (raw.crowd_handling && !raw.core_intelligence?.crowd_handling) migrated.core_intelligence.crowd_handling = raw.crowd_handling;
      if (raw.specialization_style && !raw.core_intelligence?.specialization_style) migrated.core_intelligence.specialization_style = raw.specialization_style;
      if (raw.live_mixing_capability && !raw.core_intelligence?.live_mixing_capability) migrated.core_intelligence.live_mixing_capability = raw.live_mixing_capability;
      if (raw.custom_playlist_support && !raw.core_intelligence?.custom_playlist_support) migrated.core_intelligence.custom_playlist_support = raw.custom_playlist_support;
      if (raw.song_request_handling && !raw.core_intelligence?.song_request_handling) migrated.core_intelligence.song_request_handling = raw.song_request_handling;
      if (raw.entry_sync && !raw.core_intelligence?.entry_sync) migrated.core_intelligence.entry_sync = raw.entry_sync;
      if (raw.baraat_dj_setup && !raw.core_intelligence?.baraat_dj_setup) migrated.core_intelligence.baraat_dj_setup = raw.baraat_dj_setup;
      if (raw.backup_dj_available && !raw.core_intelligence?.backup_dj_available) migrated.core_intelligence.backup_dj_available = raw.backup_dj_available;

      // Migrate technical_setup
      if (raw.equipment_ownership && !raw.technical_setup?.equipment_ownership) migrated.technical_setup.equipment_ownership = raw.equipment_ownership;
      if (raw.sound_setup_capability && !raw.technical_setup?.sound_setup_capability) migrated.technical_setup.sound_setup_capability = raw.sound_setup_capability;
      if (raw.lighting_setup && !raw.technical_setup?.lighting_setup) migrated.technical_setup.lighting_setup = raw.lighting_setup;
      if (raw.console_types && !raw.technical_setup?.console_types) migrated.technical_setup.console_types = raw.console_types;
      if (raw.power_backup && !raw.technical_setup?.power_backup) migrated.technical_setup.power_backup = raw.power_backup;
      if (raw.setup_time_required && !raw.technical_setup?.setup_time_required) migrated.technical_setup.setup_time_required = raw.setup_time_required;
      if (raw.technical_team_size && !raw.technical_setup?.technical_team_size) migrated.technical_setup.technical_team_size = raw.technical_team_size;

      // Migrate pricing
      if (raw.pricing_model && !raw.pricing?.pricing_model) migrated.pricing.pricing_model = raw.pricing_model;
      if (raw.starting_price_range && !raw.pricing?.starting_price_range) migrated.pricing.starting_price_range = raw.starting_price_range;
      if (raw.includes && !raw.pricing?.includes) migrated.pricing.includes = raw.includes;
      if (raw.addon_charges && !raw.pricing?.addon_charges) migrated.pricing.addon_charges = raw.addon_charges;
      if (raw.peak_season_pricing && !raw.pricing?.peak_season_pricing) migrated.pricing.peak_season_pricing = raw.peak_season_pricing;
      if (raw.negotiation_flexibility && !raw.pricing?.negotiation_flexibility) migrated.pricing.negotiation_flexibility = raw.negotiation_flexibility;

      // Migrate scale_capacity
      if (raw.max_events_per_day && !raw.scale_capacity?.max_events_per_day) migrated.scale_capacity.max_events_per_day = raw.max_events_per_day;
      if (raw.concurrent_events && !raw.scale_capacity?.concurrent_events) migrated.scale_capacity.concurrent_events = raw.concurrent_events;
      if (raw.team_multi_event && !raw.scale_capacity?.team_multi_event) migrated.scale_capacity.team_multi_event = raw.team_multi_event;

      // Migrate workflow
      if (raw.advance_booking_time && !raw.workflow?.advance_booking_time) migrated.workflow.advance_booking_time = raw.advance_booking_time;
      if (raw.booking_advance_percent && !raw.workflow?.booking_advance_percent) migrated.workflow.booking_advance_percent = raw.booking_advance_percent;
      if (raw.cancellation_policy && !raw.workflow?.cancellation_policy) migrated.workflow.cancellation_policy = raw.cancellation_policy;
      if (raw.coordination_mode && !raw.workflow?.coordination_mode) migrated.workflow.coordination_mode = raw.coordination_mode;
      if (raw.pre_event_planning_call && !raw.workflow?.pre_event_planning_call) migrated.workflow.pre_event_planning_call = raw.pre_event_planning_call;

      // Migrate portfolio_tagging
      if (raw.event_mood_tags && !raw.portfolio_tagging?.event_mood_tags) migrated.portfolio_tagging.event_mood_tags = raw.event_mood_tags;
      if (raw.music_style_tags && !raw.portfolio_tagging?.music_style_tags) migrated.portfolio_tagging.music_style_tags = raw.music_style_tags;
      if (raw.celebrity_big_event_experience && !raw.portfolio_tagging?.celebrity_big_event_experience) migrated.portfolio_tagging.celebrity_big_event_experience = raw.celebrity_big_event_experience;

      return migrated;
    }
    return base;
  }, [formData.dj_master, formData.attributes?.dj_master]);

  const patchDm = useCallback(
    (partial, replace = false) => {
      setFormData((prev) => {
        const base = replace ? emptyDjMaster() : (prev.dj_master || prev.attributes?.dj_master || emptyDjMaster());
        const next = mergeDeep(base, partial);
        return {
          ...prev,
          dj_master: next,
          attributes: { ...(prev.attributes || {}), dj_master: next },
        };
      });
    },
    [setFormData]
  );

  // Sync migrated data back to formData so that hitting "Save" without editing
  // still saves the newly structured data correctly.
  useEffect(() => {
    const raw = formData.dj_master || formData.attributes?.dj_master;
    if (raw && typeof raw === "object") {
      // Check if it's the old flat format by looking for a root property
      // that should be nested (e.g. brand_name without identity.brand_name)
      if (raw.brand_name && !raw.identity?.brand_name) {
        patchDm(dm, true); // replace with the fully migrated 'dm'
      } else if (raw.event_types && !raw.services?.event_types) {
        patchDm(dm, true);
      }
    }
  }, [dm, formData.dj_master, formData.attributes?.dj_master, patchDm]);

  const save = async () => {
    if (onSave) await onSave();
    if (onShowSuccess) onShowSuccess();
  };

  const inner = (
    <>
      <h4 className="mb-2 fw-bold">DJ master profile</h4>
      <p className="text-muted fs-14 mb-4">
        Structured DJ attributes for storefront and AI FAQ matching.
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
                value={dm.identity.brand_name || ""}
                onChange={(e) =>
                  patchDm({
                    identity: { ...dm.identity, brand_name: e.target.value },
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
              value={dm.identity.primary_city}
              onChange={(v) =>
                patchDm({ identity: { ...dm.identity, primary_city: v } })
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
              value={dm.identity.service_cities}
              onChange={(v) =>
                patchDm({ identity: { ...dm.identity, service_cities: v } })
              }
            />
            <SelectField
              label="Vendor type"
              options={DJ_VENDOR_TYPE}
              value={dm.identity.vendor_type}
              onChange={(v) =>
                patchDm({ identity: { ...dm.identity, vendor_type: v } })
              }
            />
            <div className="mb-3">
              <label className="form-label fw-semibold">
                Years of experience
              </label>
              <Form.Control
                type="number"
                className="fs-14"
                value={dm.identity.years_of_experience}
                onChange={(e) =>
                  patchDm({
                    identity: {
                      ...dm.identity,
                      years_of_experience: e.target.value,
                    },
                  })
                }
              />
            </div>
            <SelectField
              label="Travel policy"
              options={[
                "Included within city",
                "Extra (fixed cost)",
                "Extra (per km)",
                "Case-by-case",
              ]}
              value={dm.identity.travel_policy}
              onChange={(v) =>
                patchDm({ identity: { ...dm.identity, travel_policy: v } })
              }
            />
            <MultiCheck
              label="Languages comfortable"
              options={DJ_LANGUAGES}
              value={dm.identity.languages}
              onChange={(v) =>
                patchDm({ identity: { ...dm.identity, languages: v } })
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
              options={DJ_EVENT_TYPES}
              value={dm.services.event_types}
              onChange={(v) =>
                patchDm({ services: { ...dm.services, event_types: v } })
              }
            />
            <MultiCheck
              label="DJ formats"
              options={DJ_FORMATS}
              value={dm.services.dj_formats}
              onChange={(v) =>
                patchDm({ services: { ...dm.services, dj_formats: v } })
              }
            />
            <MultiCheck
              label="Additional services"
              options={DJ_ADDITIONAL_SERVICES}
              value={dm.services.additional_services}
              onChange={(v) =>
                patchDm({
                  services: { ...dm.services, additional_services: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 3 — Core Intelligence */}
        <Accordion.Item eventKey="2">
          <Accordion.Header>
            Section 3 — Core intelligence (DJ-specific)
          </Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Music genres expertise"
              options={DJ_MUSIC_GENRES}
              value={dm.core_intelligence.music_genres}
              onChange={(v) =>
                patchDm({
                  core_intelligence: {
                    ...dm.core_intelligence,
                    music_genres: v,
                  },
                })
              }
            />
            <SelectField
              label="Crowd handling capability"
              options={DJ_CROWD_HANDLING}
              value={dm.core_intelligence.crowd_handling}
              onChange={(v) =>
                patchDm({
                  core_intelligence: {
                    ...dm.core_intelligence,
                    crowd_handling: v,
                  },
                })
              }
            />
            <SelectField
              label="Specialization style"
              options={DJ_SPECIALIZATION_STYLE}
              value={dm.core_intelligence.specialization_style}
              onChange={(v) =>
                patchDm({
                  core_intelligence: {
                    ...dm.core_intelligence,
                    specialization_style: v,
                  },
                })
              }
            />
            <SelectField
              label="Live mixing capability"
              options={DJ_LIVE_MIXING}
              value={dm.core_intelligence.live_mixing_capability}
              onChange={(v) =>
                patchDm({
                  core_intelligence: {
                    ...dm.core_intelligence,
                    live_mixing_capability: v,
                  },
                })
              }
            />
            <SelectField
              label="Custom playlist support"
              options={[
                "Yes (Full customization)",
                "Partial",
                "No",
              ]}
              value={dm.core_intelligence.custom_playlist_support}
              onChange={(v) =>
                patchDm({
                  core_intelligence: {
                    ...dm.core_intelligence,
                    custom_playlist_support: v,
                  },
                })
              }
            />
            <SelectField
              label="Song request handling"
              options={DJ_SONG_REQUEST}
              value={dm.core_intelligence.song_request_handling}
              onChange={(v) =>
                patchDm({
                  core_intelligence: {
                    ...dm.core_intelligence,
                    song_request_handling: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Entry & performance sync"
              options={DJ_ENTRY_SYNC}
              value={dm.core_intelligence.entry_sync}
              onChange={(v) =>
                patchDm({
                  core_intelligence: {
                    ...dm.core_intelligence,
                    entry_sync: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="dj_baraat"
              label="Baraat DJ setup"
              value={dm.core_intelligence.baraat_dj_setup}
              onChange={(v) =>
                patchDm({
                  core_intelligence: {
                    ...dm.core_intelligence,
                    baraat_dj_setup: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="dj_backup"
              label="Backup DJ available"
              value={dm.core_intelligence.backup_dj_available}
              onChange={(v) =>
                patchDm({
                  core_intelligence: {
                    ...dm.core_intelligence,
                    backup_dj_available: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 4 — Technical Setup */}
        <Accordion.Item eventKey="3">
          <Accordion.Header>
            Section 4 — Technical setup & infrastructure
          </Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Equipment ownership"
              options={DJ_EQUIPMENT_OWNERSHIP}
              value={dm.technical_setup.equipment_ownership}
              onChange={(v) =>
                patchDm({
                  technical_setup: {
                    ...dm.technical_setup,
                    equipment_ownership: v,
                  },
                })
              }
            />
            <SelectField
              label="Sound setup capability"
              options={DJ_SOUND_SETUP}
              value={dm.technical_setup.sound_setup_capability}
              onChange={(v) =>
                patchDm({
                  technical_setup: {
                    ...dm.technical_setup,
                    sound_setup_capability: v,
                  },
                })
              }
            />
            <SelectField
              label="Lighting setup"
              options={DJ_LIGHTING_SETUP}
              value={dm.technical_setup.lighting_setup}
              onChange={(v) =>
                patchDm({
                  technical_setup: {
                    ...dm.technical_setup,
                    lighting_setup: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Console types"
              options={DJ_CONSOLE_TYPES}
              value={dm.technical_setup.console_types}
              onChange={(v) =>
                patchDm({
                  technical_setup: {
                    ...dm.technical_setup,
                    console_types: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="dj_power_backup"
              label="Power backup"
              value={dm.technical_setup.power_backup}
              onChange={(v) =>
                patchDm({
                  technical_setup: {
                    ...dm.technical_setup,
                    power_backup: v,
                  },
                })
              }
            />
            <SelectField
              label="Setup time required"
              options={DJ_SETUP_TIME}
              value={dm.technical_setup.setup_time_required}
              onChange={(v) =>
                patchDm({
                  technical_setup: {
                    ...dm.technical_setup,
                    setup_time_required: v,
                  },
                })
              }
            />
            <SelectField
              label="Technical team size"
              options={DJ_TECH_TEAM_SIZE}
              value={dm.technical_setup.technical_team_size}
              onChange={(v) =>
                patchDm({
                  technical_setup: {
                    ...dm.technical_setup,
                    technical_team_size: v,
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
              options={DJ_PRICING_MODEL}
              value={dm.pricing.pricing_model}
              onChange={(v) =>
                patchDm({ pricing: { ...dm.pricing, pricing_model: v } })
              }
            />
            <SelectField
              label="Starting price range"
              options={DJ_STARTING_PRICE}
              value={dm.pricing.starting_price_range}
              onChange={(v) =>
                patchDm({
                  pricing: { ...dm.pricing, starting_price_range: v },
                })
              }
            />
            <MultiCheck
              label="Includes"
              options={DJ_INCLUDES}
              value={dm.pricing.includes}
              onChange={(v) =>
                patchDm({ pricing: { ...dm.pricing, includes: v } })
              }
            />
            <MultiCheck
              label="Add-on charges"
              options={DJ_ADDONS}
              value={dm.pricing.addon_charges}
              onChange={(v) =>
                patchDm({ pricing: { ...dm.pricing, addon_charges: v } })
              }
            />
            <YesNoField
              groupName="dj_peak_pricing"
              label="Peak season pricing"
              value={dm.pricing.peak_season_pricing}
              onChange={(v) =>
                patchDm({
                  pricing: { ...dm.pricing, peak_season_pricing: v },
                })
              }
            />
            <SelectField
              label="Negotiation flexibility"
              options={DJ_NEGOTIATION}
              value={dm.pricing.negotiation_flexibility}
              onChange={(v) =>
                patchDm({
                  pricing: { ...dm.pricing, negotiation_flexibility: v },
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
              label="Max events per day"
              options={DJ_MAX_EVENTS_PER_DAY}
              value={dm.scale_capacity.max_events_per_day}
              onChange={(v) =>
                patchDm({
                  scale_capacity: {
                    ...dm.scale_capacity,
                    max_events_per_day: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="dj_concurrent"
              label="Concurrent events capability"
              value={dm.scale_capacity.concurrent_events}
              onChange={(v) =>
                patchDm({
                  scale_capacity: {
                    ...dm.scale_capacity,
                    concurrent_events: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="dj_team_multi"
              label="Team-based multi-event handling"
              value={dm.scale_capacity.team_multi_event}
              onChange={(v) =>
                patchDm({
                  scale_capacity: {
                    ...dm.scale_capacity,
                    team_multi_event: v,
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
              options={DJ_ADVANCE_BOOKING}
              value={dm.workflow.advance_booking_time}
              onChange={(v) =>
                patchDm({
                  workflow: { ...dm.workflow, advance_booking_time: v },
                })
              }
            />
            <SelectField
              label="Booking advance %"
              options={DJ_ADVANCE_PERCENT}
              value={dm.workflow.booking_advance_percent}
              onChange={(v) =>
                patchDm({
                  workflow: { ...dm.workflow, booking_advance_percent: v },
                })
              }
            />
            <SelectField
              label="Cancellation policy"
              options={DJ_CANCELLATION_POLICY}
              value={dm.workflow.cancellation_policy}
              onChange={(v) =>
                patchDm({
                  workflow: { ...dm.workflow, cancellation_policy: v },
                })
              }
            />
            <SelectField
              label="Client coordination mode"
              options={DJ_COORDINATION_MODE}
              value={dm.workflow.coordination_mode}
              onChange={(v) =>
                patchDm({
                  workflow: { ...dm.workflow, coordination_mode: v },
                })
              }
            />
            <YesNoField
              groupName="dj_pre_event_call"
              label="Pre-event planning call"
              value={dm.workflow.pre_event_planning_call}
              onChange={(v) =>
                patchDm({
                  workflow: { ...dm.workflow, pre_event_planning_call: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 8 — Portfolio Tagging */}
        <Accordion.Item eventKey="7">
          <Accordion.Header>
            Section 8 — Portfolio tagging (AI search layer)
          </Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Event mood tags"
              options={DJ_EVENT_MOOD_TAGS}
              value={dm.portfolio_tagging.event_mood_tags}
              onChange={(v) =>
                patchDm({
                  portfolio_tagging: {
                    ...dm.portfolio_tagging,
                    event_mood_tags: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Music style tags"
              options={DJ_MUSIC_STYLE_TAGS}
              value={dm.portfolio_tagging.music_style_tags}
              onChange={(v) =>
                patchDm({
                  portfolio_tagging: {
                    ...dm.portfolio_tagging,
                    music_style_tags: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="dj_celebrity_exp"
              label="Celebrity / big event experience"
              value={dm.portfolio_tagging.celebrity_big_event_experience}
              onChange={(v) =>
                patchDm({
                  portfolio_tagging: {
                    ...dm.portfolio_tagging,
                    celebrity_big_event_experience: v,
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
          Save DJ master profile
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

export default DjMasterProfile;
