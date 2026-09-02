import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  PWP_VENDOR_TYPE,
  PWP_SERVICE_PRESENCE,
  PWP_YEARS_OF_EXPERIENCE,
  PWP_TEAM_SIZE,
  PWP_SHOOT_TYPES,
  PWP_PHOTOGRAPHY_COVERAGE,
  PWP_PHOTOGRAPHY_STYLE,
  PWP_SHOOT_STYLE_THEMES,
  PWP_LIGHTING_STYLE,
  PWP_EDITING_STYLE,
  PWP_REEL_STYLE,
  PWP_BEST_TIME_PREFERENCE,
  PWP_CAMERA_TYPE,
  PWP_DRONE_EQUIPMENT_LEVEL,
  PWP_VIDEO_RESOLUTION,
  PWP_STABILIZATION_EQUIPMENT,
  PWP_PRICE_RANGE,
  PWP_PRICING_MODEL,
  PWP_SHOOTS_PER_MONTH,
  PWP_SIMULTANEOUS_PROJECTS,
  PWP_TEAM_SCALABILITY,
  PWP_BOOKING_WINDOW,
  PWP_CONCEPT_FINALIZATION,
  PWP_SHOOT_DURATION,
  PWP_EDITED_PHOTOS_DELIVERY,
  PWP_VIDEO_DELIVERY,
  PWP_PAYMENT_MODES,
  PWP_VISUAL_STYLE_TAGS,
  PWP_AUDIENCE_TAGS,
  PWP_USAGE_TAGS,
  PWP_PRICE_SEGMENT_TAGS,
  PWP_ADVANCE_PAYMENT,
  emptyPreWeddingPhotographerMaster,
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

const PreWeddingPhotographerMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const pm = useMemo(() => {
    const raw =
      formData.pre_wedding_photographer_master ||
      formData.attributes?.pre_wedding_photographer_master;
    if (raw && typeof raw === "object")
      return mergeDeep(emptyPreWeddingPhotographerMaster(), raw);
    return emptyPreWeddingPhotographerMaster();
  }, [
    formData.pre_wedding_photographer_master,
    formData.attributes?.pre_wedding_photographer_master,
  ]);

  const patchPm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(
          prev.pre_wedding_photographer_master ||
          prev.attributes?.pre_wedding_photographer_master ||
          emptyPreWeddingPhotographerMaster(),
          partial
        );
        return {
          ...prev,
          pre_wedding_photographer_master: next,
          attributes: {
            ...(prev.attributes || {}),
            pre_wedding_photographer_master: next,
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
      <h4 className="mb-2 fw-bold">Pre-wedding photographer master profile</h4>
      <p className="text-muted fs-14 mb-4">
        Structured photographer attributes for storefront and AI FAQ matching.
      </p>

      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        {/* Section 1 — Basic Identity */}
        <Accordion.Item eventKey="0">
          <Accordion.Header>Section 1 — Basic identity</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Vendor type"
              options={PWP_VENDOR_TYPE}
              value={pm.identity.vendor_type}
              onChange={(v) =>
                patchPm({ identity: { ...pm.identity, vendor_type: v } })
              }
            />
            {/* <div className="mb-3">
              <label className="form-label fw-semibold">Brand name</label>
              <Form.Control
                type="text"
                className="fs-14"
                value={pm.identity.brand_name}
                onChange={(e) =>
                  patchPm({
                    identity: { ...pm.identity, brand_name: e.target.value },
                  })
                }
                placeholder="Enter brand / studio name"
              />
            </div> */}
            <MultiCheck
              label="Service presence"
              options={PWP_SERVICE_PRESENCE}
              value={pm.identity.service_presence}
              onChange={(v) =>
                patchPm({ identity: { ...pm.identity, service_presence: v } })
              }
            />
            <div className="mb-3">
              <label className="form-label fw-semibold">City</label>
              <Form.Control
                type="text"
                className="fs-14"
                value={pm.identity.city}
                onChange={(e) =>
                  patchPm({
                    identity: { ...pm.identity, city: e.target.value },
                  })
                }
                placeholder="Enter city"
              />
            </div>
            <SelectField
              label="Years of experience"
              options={PWP_YEARS_OF_EXPERIENCE}
              value={pm.identity.years_of_experience}
              onChange={(v) =>
                patchPm({
                  identity: { ...pm.identity, years_of_experience: v },
                })
              }
            />
            <SelectField
              label="Team size"
              options={PWP_TEAM_SIZE}
              value={pm.identity.team_size}
              onChange={(v) =>
                patchPm({ identity: { ...pm.identity, team_size: v } })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 2 — Services Offered */}
        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Services offered</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Shoot types"
              options={PWP_SHOOT_TYPES}
              value={pm.services.shoot_types}
              onChange={(v) =>
                patchPm({ services: { ...pm.services, shoot_types: v } })
              }
            />
            <MultiCheck
              label="Photography coverage"
              options={PWP_PHOTOGRAPHY_COVERAGE}
              value={pm.services.photography_coverage}
              onChange={(v) =>
                patchPm({
                  services: { ...pm.services, photography_coverage: v },
                })
              }
            />
            <YesNoField
              groupName="pwp_drone"
              label="Drone shooting"
              value={pm.services.drone_shooting}
              onChange={(v) =>
                patchPm({ services: { ...pm.services, drone_shooting: v } })
              }
            />
            <YesNoField
              groupName="pwp_cinematic"
              label="Cinematic videography"
              value={pm.services.cinematic_videography}
              onChange={(v) =>
                patchPm({
                  services: { ...pm.services, cinematic_videography: v },
                })
              }
            />
            <YesNoField
              groupName="pwp_concept_planning"
              label="Concept planning support"
              value={pm.services.concept_planning_support}
              onChange={(v) =>
                patchPm({
                  services: { ...pm.services, concept_planning_support: v },
                })
              }
            />
            <YesNoField
              groupName="pwp_location_assistance"
              label="Location assistance"
              value={pm.services.location_assistance}
              onChange={(v) =>
                patchPm({
                  services: { ...pm.services, location_assistance: v },
                })
              }
            />
            <YesNoField
              groupName="pwp_styling"
              label="Styling assistance"
              value={pm.services.styling_assistance}
              onChange={(v) =>
                patchPm({
                  services: { ...pm.services, styling_assistance: v },
                })
              }
            />
            <YesNoField
              groupName="pwp_outfit_coord"
              label="Outfit coordination support"
              value={pm.services.outfit_coordination_support}
              onChange={(v) =>
                patchPm({
                  services: { ...pm.services, outfit_coordination_support: v },
                })
              }
            />
            <YesNoField
              groupName="pwp_travel_included"
              label="Travel included"
              value={pm.services.travel_included}
              onChange={(v) =>
                patchPm({ services: { ...pm.services, travel_included: v } })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 3 — Core Intelligence */}
        <Accordion.Item eventKey="2">
          <Accordion.Header>
            Section 3 — Core intelligence (photographer-specific)
          </Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Photography style"
              options={PWP_PHOTOGRAPHY_STYLE}
              value={pm.core_intelligence.photography_style}
              onChange={(v) =>
                patchPm({
                  core_intelligence: {
                    ...pm.core_intelligence,
                    photography_style: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Shoot style themes"
              options={PWP_SHOOT_STYLE_THEMES}
              value={pm.core_intelligence.shoot_style_themes}
              onChange={(v) =>
                patchPm({
                  core_intelligence: {
                    ...pm.core_intelligence,
                    shoot_style_themes: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Lighting style"
              options={PWP_LIGHTING_STYLE}
              value={pm.core_intelligence.lighting_style}
              onChange={(v) =>
                patchPm({
                  core_intelligence: {
                    ...pm.core_intelligence,
                    lighting_style: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Editing style"
              options={PWP_EDITING_STYLE}
              value={pm.core_intelligence.editing_style}
              onChange={(v) =>
                patchPm({
                  core_intelligence: {
                    ...pm.core_intelligence,
                    editing_style: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Reel style capability"
              options={PWP_REEL_STYLE}
              value={pm.core_intelligence.reel_style_capability}
              onChange={(v) =>
                patchPm({
                  core_intelligence: {
                    ...pm.core_intelligence,
                    reel_style_capability: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Best time preference"
              options={PWP_BEST_TIME_PREFERENCE}
              value={pm.core_intelligence.best_time_preference}
              onChange={(v) =>
                patchPm({
                  core_intelligence: {
                    ...pm.core_intelligence,
                    best_time_preference: v,
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
            <MultiCheck
              label="Camera type used"
              options={PWP_CAMERA_TYPE}
              value={pm.technical.camera_type}
              onChange={(v) =>
                patchPm({ technical: { ...pm.technical, camera_type: v } })
              }
            />
            <SelectField
              label="Drone equipment level"
              options={PWP_DRONE_EQUIPMENT_LEVEL}
              value={pm.technical.drone_equipment_level}
              onChange={(v) =>
                patchPm({
                  technical: { ...pm.technical, drone_equipment_level: v },
                })
              }
            />
            <SelectField
              label="Video resolution"
              options={PWP_VIDEO_RESOLUTION}
              value={pm.technical.video_resolution}
              onChange={(v) =>
                patchPm({
                  technical: { ...pm.technical, video_resolution: v },
                })
              }
            />
            <MultiCheck
              label="Stabilization equipment"
              options={PWP_STABILIZATION_EQUIPMENT}
              value={pm.technical.stabilization_equipment}
              onChange={(v) =>
                patchPm({
                  technical: { ...pm.technical, stabilization_equipment: v },
                })
              }
            />
            <YesNoField
              groupName="pwp_audio_capture"
              label="Audio capture (for video)"
              value={pm.technical.audio_capture}
              onChange={(v) =>
                patchPm({ technical: { ...pm.technical, audio_capture: v } })
              }
            />
            <YesNoField
              groupName="pwp_backup_equipment"
              label="Backup equipment available"
              value={pm.technical.backup_equipment_available}
              onChange={(v) =>
                patchPm({
                  technical: {
                    ...pm.technical,
                    backup_equipment_available: v,
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
              label="Price range (INR)"
              options={PWP_PRICE_RANGE}
              value={pm.pricing.price_range}
              onChange={(v) =>
                patchPm({ pricing: { ...pm.pricing, price_range: v } })
              }
            />
            <SelectField
              label="Pricing model"
              options={PWP_PRICING_MODEL}
              value={pm.pricing.pricing_model}
              onChange={(v) =>
                patchPm({ pricing: { ...pm.pricing, pricing_model: v } })
              }
            />
            <SelectField
              label="Travel charges"
              options={["Included", "Extra"]}
              value={pm.pricing.travel_charges}
              onChange={(v) =>
                patchPm({ pricing: { ...pm.pricing, travel_charges: v } })
              }
            />
            <SelectField
              label="Stay charges"
              options={["Included", "Extra"]}
              value={pm.pricing.stay_charges}
              onChange={(v) =>
                patchPm({ pricing: { ...pm.pricing, stay_charges: v } })
              }
            />
            <SelectField
              label="Drone charges"
              options={["Included", "Extra"]}
              value={pm.pricing.drone_charges}
              onChange={(v) =>
                patchPm({ pricing: { ...pm.pricing, drone_charges: v } })
              }
            />
            <SelectField
              label="Editing charges"
              options={["Included", "Extra"]}
              value={pm.pricing.editing_charges}
              onChange={(v) =>
                patchPm({ pricing: { ...pm.pricing, editing_charges: v } })
              }
            />
            <SelectField
              label="Advance payment percentage"
              options={PWP_ADVANCE_PAYMENT}
              value={pm.pricing.advance_payment_percentage}
              onChange={(v) =>
                patchPm({
                  pricing: { ...pm.pricing, advance_payment_percentage: v },
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
              label="Shoots per month capacity"
              options={PWP_SHOOTS_PER_MONTH}
              value={pm.scale_capacity.shoots_per_month}
              onChange={(v) =>
                patchPm({
                  scale_capacity: {
                    ...pm.scale_capacity,
                    shoots_per_month: v,
                  },
                })
              }
            />
            <SelectField
              label="Simultaneous projects capacity"
              options={PWP_SIMULTANEOUS_PROJECTS}
              value={pm.scale_capacity.simultaneous_projects}
              onChange={(v) =>
                patchPm({
                  scale_capacity: {
                    ...pm.scale_capacity,
                    simultaneous_projects: v,
                  },
                })
              }
            />
            <SelectField
              label="Team scalability"
              options={PWP_TEAM_SCALABILITY}
              value={pm.scale_capacity.team_scalability}
              onChange={(v) =>
                patchPm({
                  scale_capacity: {
                    ...pm.scale_capacity,
                    team_scalability: v,
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
            <SelectField
              label="Booking window"
              options={PWP_BOOKING_WINDOW}
              value={pm.workflow.booking_window}
              onChange={(v) =>
                patchPm({ workflow: { ...pm.workflow, booking_window: v } })
              }
            />
            <SelectField
              label="Concept finalization timeline"
              options={PWP_CONCEPT_FINALIZATION}
              value={pm.workflow.concept_finalization_timeline}
              onChange={(v) =>
                patchPm({
                  workflow: {
                    ...pm.workflow,
                    concept_finalization_timeline: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Shoot duration options"
              options={PWP_SHOOT_DURATION}
              value={pm.workflow.shoot_duration_options}
              onChange={(v) =>
                patchPm({
                  workflow: { ...pm.workflow, shoot_duration_options: v },
                })
              }
            />
            <YesNoField
              groupName="pwp_raw_data"
              label="Raw data delivery"
              value={pm.workflow.raw_data_delivery}
              onChange={(v) =>
                patchPm({ workflow: { ...pm.workflow, raw_data_delivery: v } })
              }
            />
            <SelectField
              label="Edited photos delivery timeline"
              options={PWP_EDITED_PHOTOS_DELIVERY}
              value={pm.workflow.edited_photos_delivery_timeline}
              onChange={(v) =>
                patchPm({
                  workflow: {
                    ...pm.workflow,
                    edited_photos_delivery_timeline: v,
                  },
                })
              }
            />
            <SelectField
              label="Video delivery timeline"
              options={PWP_VIDEO_DELIVERY}
              value={pm.workflow.video_delivery_timeline}
              onChange={(v) =>
                patchPm({
                  workflow: { ...pm.workflow, video_delivery_timeline: v },
                })
              }
            />
            <MultiCheck
              label="Payment modes"
              options={PWP_PAYMENT_MODES}
              value={pm.workflow.payment_modes}
              onChange={(v) =>
                patchPm({ workflow: { ...pm.workflow, payment_modes: v } })
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
              options={PWP_VISUAL_STYLE_TAGS}
              value={pm.portfolio_tagging.visual_style_tags}
              onChange={(v) =>
                patchPm({
                  portfolio_tagging: {
                    ...pm.portfolio_tagging,
                    visual_style_tags: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Audience tags"
              options={PWP_AUDIENCE_TAGS}
              value={pm.portfolio_tagging.audience_tags}
              onChange={(v) =>
                patchPm({
                  portfolio_tagging: {
                    ...pm.portfolio_tagging,
                    audience_tags: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Usage tags"
              options={PWP_USAGE_TAGS}
              value={pm.portfolio_tagging.usage_tags}
              onChange={(v) =>
                patchPm({
                  portfolio_tagging: {
                    ...pm.portfolio_tagging,
                    usage_tags: v,
                  },
                })
              }
            />
            <SelectField
              label="Price segment tags"
              options={PWP_PRICE_SEGMENT_TAGS}
              value={pm.portfolio_tagging.price_segment_tags}
              onChange={(v) =>
                patchPm({
                  portfolio_tagging: {
                    ...pm.portfolio_tagging,
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
          Save photographer master profile
        </button>
      )}
    </>
  );

  if (embedded) {
    return <div className="pt-4 mt-3 border-top">{inner}</div>;
  }

  return (
    <div className="my-5">
      <div className="p-3 border rounded bg-white">
        {Array.from({ length: copies }).map((_, i) => (
          <div key={i} className="mb-4 position-relative">
            <div className="position-absolute" style={{ right: 12, top: -8 }}>
              <a
                href="#"
                onClick={(e) => {
                  e.preventDefault();
                  handleDelete(i);
                }}
                className="text-danger me-2"
              >
                Delete
              </a>
              <a
                href="/register-as-wedding-photographer"
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary me-2"
              >
                Register
              </a>
              <a
                href={`mailto:?subject=Register%20as%20Wedding%20Photographer&body=Register%20here:%20${encodeURI(
                  "/register-as-wedding-photographer"
                )}`}
                className="text-secondary"
              >
                Send
              </a>
            </div>
            {inner}
          </div>
        ))}
      </div>
    </div>
  );
};

export default PreWeddingPhotographerMasterProfile;
