import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  PWL_LOCATION_TYPE,
  PWL_OWNERSHIP_TYPE,
  PWL_ACCESSIBILITY_TYPE,
  PWL_YEARS_OF_OPERATION,
  PWL_BOOKING_TYPE,
  PWL_PROPS_AVAILABLE,
  PWL_LOCATION_THEMES,
  PWL_BEST_SHOOT_TIME,
  PWL_LIGHTING_CONDITIONS,
  PWL_WEATHER_SUITABILITY,
  PWL_PRIVACY_LEVEL,
  PWL_NOISE_LEVEL,
  PWL_AREA_SIZE,
  PWL_SHOOTING_SPOTS,
  PWL_TERRAIN_TYPE,
  PWL_PRICE_RANGE,
  PWL_PRICING_MODEL,
  PWL_OUTFITS_ON_RENT,
  PWL_CANCELLATION_POLICY,
  PWL_MAX_CREW_SIZE,
  PWL_SIMULTANEOUS_SHOOTS,
  PWL_PARKING_CAPACITY,
  PWL_BOOKING_WINDOW,
  PWL_TIME_SLOT_ALLOCATION,
  PWL_PAYMENT_MODES,
  PWL_ADVANCE_PAYMENT,
  PWL_VISUAL_STYLE_TAGS,
  PWL_AUDIENCE_TAGS,
  PWL_USAGE_TAGS,
  PWL_PRICE_SEGMENT_TAGS,
  emptyPreWeddingLocationMaster,
} from "./preWeddingMasterConstants";

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

const PreWeddingLocationMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const lm = useMemo(() => {
    const raw =
      formData.pre_wedding_location_master ||
      formData.attributes?.pre_wedding_location_master;
    if (raw && typeof raw === "object")
      return mergeDeep(emptyPreWeddingLocationMaster(), raw);
    return emptyPreWeddingLocationMaster();
  }, [
    formData.pre_wedding_location_master,
    formData.attributes?.pre_wedding_location_master,
  ]);

  const patchLm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(
          prev.pre_wedding_location_master ||
            prev.attributes?.pre_wedding_location_master ||
            emptyPreWeddingLocationMaster(),
          partial
        );
        return {
          ...prev,
          pre_wedding_location_master: next,
          attributes: {
            ...(prev.attributes || {}),
            pre_wedding_location_master: next,
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
      <h4 className="mb-2 fw-bold">Pre-wedding shoot location master profile</h4>
      <p className="text-muted fs-14 mb-4">
        Structured location attributes for storefront and AI FAQ matching.
      </p>

      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        {/* Section 1 — Basic Identity */}
        <Accordion.Item eventKey="0">
          <Accordion.Header>Section 1 — Basic identity</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Location type"
              options={PWL_LOCATION_TYPE}
              value={lm.identity.location_type}
              onChange={(v) =>
                patchLm({ identity: { ...lm.identity, location_type: v } })
              }
            />
            <div className="mb-3">
              <label className="form-label fw-semibold">Location name</label>
              <Form.Control
                type="text"
                className="fs-14"
                value={lm.identity.location_name}
                onChange={(e) =>
                  patchLm({
                    identity: { ...lm.identity, location_name: e.target.value },
                  })
                }
                placeholder="Enter location name"
              />
            </div>
            <SelectField
              label="Ownership type"
              options={PWL_OWNERSHIP_TYPE}
              value={lm.identity.ownership_type}
              onChange={(v) =>
                patchLm({ identity: { ...lm.identity, ownership_type: v } })
              }
            />
            <div className="mb-3">
              <label className="form-label fw-semibold">City</label>
              <Form.Control
                type="text"
                className="fs-14"
                value={lm.identity.city}
                onChange={(e) =>
                  patchLm({
                    identity: { ...lm.identity, city: e.target.value },
                  })
                }
                placeholder="Enter city"
              />
            </div>
            <SelectField
              label="Accessibility type"
              options={PWL_ACCESSIBILITY_TYPE}
              value={lm.identity.accessibility_type}
              onChange={(v) =>
                patchLm({ identity: { ...lm.identity, accessibility_type: v } })
              }
            />
            <SelectField
              label="Years of operation"
              options={PWL_YEARS_OF_OPERATION}
              value={lm.identity.years_of_operation}
              onChange={(v) =>
                patchLm({
                  identity: { ...lm.identity, years_of_operation: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 2 — Services Offered */}
        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Services offered</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Booking type"
              options={PWL_BOOKING_TYPE}
              value={lm.services.booking_type}
              onChange={(v) =>
                patchLm({ services: { ...lm.services, booking_type: v } })
              }
            />
            <YesNoField
              groupName="pwl_photography_allowed"
              label="Photography allowed"
              value={lm.services.photography_allowed}
              onChange={(v) =>
                patchLm({
                  services: { ...lm.services, photography_allowed: v },
                })
              }
            />
            <YesNoField
              groupName="pwl_videography_allowed"
              label="Videography allowed"
              value={lm.services.videography_allowed}
              onChange={(v) =>
                patchLm({
                  services: { ...lm.services, videography_allowed: v },
                })
              }
            />
            <YesNoField
              groupName="pwl_drone_allowed"
              label="Drone usage allowed"
              value={lm.services.drone_usage_allowed}
              onChange={(v) =>
                patchLm({
                  services: { ...lm.services, drone_usage_allowed: v },
                })
              }
            />
            <SelectField
              label="Permission handling"
              options={["Self-Managed", "Vendor Managed", "Not Required"]}
              value={lm.services.permission_handling}
              onChange={(v) =>
                patchLm({
                  services: { ...lm.services, permission_handling: v },
                })
              }
            />
            <YesNoField
              groupName="pwl_changing_rooms"
              label="Changing rooms available"
              value={lm.services.changing_rooms_available}
              onChange={(v) =>
                patchLm({
                  services: { ...lm.services, changing_rooms_available: v },
                })
              }
            />
            <YesNoField
              groupName="pwl_makeup_room"
              label="Makeup room available"
              value={lm.services.makeup_room_available}
              onChange={(v) =>
                patchLm({
                  services: { ...lm.services, makeup_room_available: v },
                })
              }
            />
            <MultiCheck
              label="Props available"
              options={PWL_PROPS_AVAILABLE}
              value={lm.services.props_available}
              onChange={(v) =>
                patchLm({ services: { ...lm.services, props_available: v } })
              }
            />
            <YesNoField
              groupName="pwl_power_supply"
              label="Power supply available"
              value={lm.services.power_supply_available}
              onChange={(v) =>
                patchLm({
                  services: { ...lm.services, power_supply_available: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 3 — Core Intelligence */}
        <Accordion.Item eventKey="2">
          <Accordion.Header>
            Section 3 — Core intelligence (location-specific)
          </Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Location themes"
              options={PWL_LOCATION_THEMES}
              value={lm.core_intelligence.location_themes}
              onChange={(v) =>
                patchLm({
                  core_intelligence: {
                    ...lm.core_intelligence,
                    location_themes: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Best shoot time"
              options={PWL_BEST_SHOOT_TIME}
              value={lm.core_intelligence.best_shoot_time}
              onChange={(v) =>
                patchLm({
                  core_intelligence: {
                    ...lm.core_intelligence,
                    best_shoot_time: v,
                  },
                })
              }
            />
            <SelectField
              label="Lighting conditions"
              options={PWL_LIGHTING_CONDITIONS}
              value={lm.core_intelligence.lighting_conditions}
              onChange={(v) =>
                patchLm({
                  core_intelligence: {
                    ...lm.core_intelligence,
                    lighting_conditions: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Weather suitability"
              options={PWL_WEATHER_SUITABILITY}
              value={lm.core_intelligence.weather_suitability}
              onChange={(v) =>
                patchLm({
                  core_intelligence: {
                    ...lm.core_intelligence,
                    weather_suitability: v,
                  },
                })
              }
            />
            <SelectField
              label="Privacy level"
              options={PWL_PRIVACY_LEVEL}
              value={lm.core_intelligence.privacy_level}
              onChange={(v) =>
                patchLm({
                  core_intelligence: {
                    ...lm.core_intelligence,
                    privacy_level: v,
                  },
                })
              }
            />
            <SelectField
              label="Noise level"
              options={PWL_NOISE_LEVEL}
              value={lm.core_intelligence.noise_level}
              onChange={(v) =>
                patchLm({
                  core_intelligence: {
                    ...lm.core_intelligence,
                    noise_level: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 4 — Technical */}
        <Accordion.Item eventKey="3">
          <Accordion.Header>
            Section 4 — Technical / product / skill layer
          </Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Area size"
              options={PWL_AREA_SIZE}
              value={lm.technical.area_size}
              onChange={(v) =>
                patchLm({ technical: { ...lm.technical, area_size: v } })
              }
            />
            <SelectField
              label="Number of shooting spots"
              options={PWL_SHOOTING_SPOTS}
              value={lm.technical.shooting_spots}
              onChange={(v) =>
                patchLm({ technical: { ...lm.technical, shooting_spots: v } })
              }
            />
            <YesNoField
              groupName="pwl_indoor"
              label="Indoor availability"
              value={lm.technical.indoor_availability}
              onChange={(v) =>
                patchLm({
                  technical: { ...lm.technical, indoor_availability: v },
                })
              }
            />
            <YesNoField
              groupName="pwl_outdoor"
              label="Outdoor availability"
              value={lm.technical.outdoor_availability}
              onChange={(v) =>
                patchLm({
                  technical: { ...lm.technical, outdoor_availability: v },
                })
              }
            />
            <MultiCheck
              label="Terrain type"
              options={PWL_TERRAIN_TYPE}
              value={lm.technical.terrain_type}
              onChange={(v) =>
                patchLm({ technical: { ...lm.technical, terrain_type: v } })
              }
            />
            <YesNoField
              groupName="pwl_electric_backup"
              label="Electric backup"
              value={lm.technical.electric_backup}
              onChange={(v) =>
                patchLm({ technical: { ...lm.technical, electric_backup: v } })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 5 — Pricing */}
        <Accordion.Item eventKey="4">
          <Accordion.Header>Section 5 — Pricing logic</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Price range (INR)"
              options={PWL_PRICE_RANGE}
              value={lm.pricing.price_range}
              onChange={(v) =>
                patchLm({ pricing: { ...lm.pricing, price_range: v } })
              }
            />
            <SelectField
              label="Pricing model"
              options={PWL_PRICING_MODEL}
              value={lm.pricing.pricing_model}
              onChange={(v) =>
                patchLm({ pricing: { ...lm.pricing, pricing_model: v } })
              }
            />
            <SelectField
              label="Outfits available on rent"
              options={PWL_OUTFITS_ON_RENT}
              value={lm.pricing.outfits_on_rent}
              onChange={(v) =>
                patchLm({ pricing: { ...lm.pricing, outfits_on_rent: v } })
              }
            />
            <YesNoField
              groupName="pwl_security_deposit"
              label="Security deposit required"
              value={lm.pricing.security_deposit_required}
              onChange={(v) =>
                patchLm({
                  pricing: { ...lm.pricing, security_deposit_required: v },
                })
              }
            />
            <SelectField
              label="Permit charges"
              options={["Included", "Extra", "Not Applicable"]}
              value={lm.pricing.permit_charges}
              onChange={(v) =>
                patchLm({ pricing: { ...lm.pricing, permit_charges: v } })
              }
            />
            <SelectField
              label="Cancellation policy"
              options={PWL_CANCELLATION_POLICY}
              value={lm.pricing.cancellation_policy}
              onChange={(v) =>
                patchLm({
                  pricing: { ...lm.pricing, cancellation_policy: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 6 — Scale & Capacity */}
        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Scale &amp; capacity</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Max crew size allowed"
              options={PWL_MAX_CREW_SIZE}
              value={lm.scale_capacity.max_crew_size}
              onChange={(v) =>
                patchLm({
                  scale_capacity: { ...lm.scale_capacity, max_crew_size: v },
                })
              }
            />
            <SelectField
              label="Simultaneous shoots allowed"
              options={PWL_SIMULTANEOUS_SHOOTS}
              value={lm.scale_capacity.simultaneous_shoots}
              onChange={(v) =>
                patchLm({
                  scale_capacity: {
                    ...lm.scale_capacity,
                    simultaneous_shoots: v,
                  },
                })
              }
            />
            <SelectField
              label="Parking capacity"
              options={PWL_PARKING_CAPACITY}
              value={lm.scale_capacity.parking_capacity}
              onChange={(v) =>
                patchLm({
                  scale_capacity: {
                    ...lm.scale_capacity,
                    parking_capacity: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 7 — Workflow & Booking */}
        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Workflow &amp; booking</Accordion.Header>
          <Accordion.Body>
            <YesNoField
              groupName="pwl_advance_booking"
              label="Advance booking required"
              value={lm.workflow.advance_booking_required}
              onChange={(v) =>
                patchLm({
                  workflow: { ...lm.workflow, advance_booking_required: v },
                })
              }
            />
            <SelectField
              label="Booking window"
              options={PWL_BOOKING_WINDOW}
              value={lm.workflow.booking_window}
              onChange={(v) =>
                patchLm({ workflow: { ...lm.workflow, booking_window: v } })
              }
            />
            <SelectField
              label="Time slot allocation"
              options={PWL_TIME_SLOT_ALLOCATION}
              value={lm.workflow.time_slot_allocation}
              onChange={(v) =>
                patchLm({
                  workflow: { ...lm.workflow, time_slot_allocation: v },
                })
              }
            />
            <YesNoField
              groupName="pwl_onsite_coordinator"
              label="On-site coordinator available"
              value={lm.workflow.onsite_coordinator_available}
              onChange={(v) =>
                patchLm({
                  workflow: {
                    ...lm.workflow,
                    onsite_coordinator_available: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Payment modes"
              options={PWL_PAYMENT_MODES}
              value={lm.workflow.payment_modes}
              onChange={(v) =>
                patchLm({ workflow: { ...lm.workflow, payment_modes: v } })
              }
            />
            <SelectField
              label="Advance payment percentage"
              options={PWL_ADVANCE_PAYMENT}
              value={lm.workflow.advance_payment_percentage}
              onChange={(v) =>
                patchLm({
                  workflow: { ...lm.workflow, advance_payment_percentage: v },
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
              label="Visual style tags"
              options={PWL_VISUAL_STYLE_TAGS}
              value={lm.portfolio_tagging.visual_style_tags}
              onChange={(v) =>
                patchLm({
                  portfolio_tagging: {
                    ...lm.portfolio_tagging,
                    visual_style_tags: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Audience tags"
              options={PWL_AUDIENCE_TAGS}
              value={lm.portfolio_tagging.audience_tags}
              onChange={(v) =>
                patchLm({
                  portfolio_tagging: {
                    ...lm.portfolio_tagging,
                    audience_tags: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Usage tags"
              options={PWL_USAGE_TAGS}
              value={lm.portfolio_tagging.usage_tags}
              onChange={(v) =>
                patchLm({
                  portfolio_tagging: {
                    ...lm.portfolio_tagging,
                    usage_tags: v,
                  },
                })
              }
            />
            <SelectField
              label="Price segment tags"
              options={PWL_PRICE_SEGMENT_TAGS}
              value={lm.portfolio_tagging.price_segment_tags}
              onChange={(v) =>
                patchLm({
                  portfolio_tagging: {
                    ...lm.portfolio_tagging,
                    price_segment_tags: v,
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
          Save location master profile
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

export default PreWeddingLocationMasterProfile;
