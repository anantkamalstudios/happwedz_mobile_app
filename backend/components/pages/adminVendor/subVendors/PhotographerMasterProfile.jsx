import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  SERVICES_OFFERED,
  ALSO_AVAILABLE_FOR,
  TRAVEL_AVAILABILITY,
  PHOTOGRAPHY_STYLE,
  EDITING_STYLE,
  BEST_KNOWN_FOR,
  IDEAL_WEDDING_TYPE,
  TEAM_SIZE,
  PHOTOS_DELIVERED,
  VIDEOS_DELIVERED,
  ALBUM_TYPE,
  DELIVERY_TIME,
  PRICING_TYPE,
  PRE_WEDDING_COST,
  TRAVEL_CHARGES,
  CAMERA_TYPE,
  LIGHTING_SETUP,
  PRE_WEDDING_LOCATIONS,
  ADVANCE_PERCENTAGE,
  CANCELLATION_POLICY,
  NUMBER_OF_REVISIONS,
  FUNCTIONS_COVERED,
  BEST_FOR,
  emptyPhotographerMaster,
} from "./photographerMasterConstants";

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
    } else out[k] = pv;
  });
  return out;
}

const SelectField = ({ label, options, value, onChange }) => (
  <div className="mb-3">
    <label className="form-label fw-semibold">{label}</label>
    <Form.Select className="fs-14" value={value || ""} onChange={(e) => onChange(e.target.value)}>
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
    onChange(selected.includes(opt) ? selected.filter((x) => x !== opt) : [...selected, opt]);
  return (
    <div className="mb-3">
      <label className="form-label fw-semibold">{label}</label>
      <div className="d-flex flex-wrap gap-2">
        {options.map((opt) => (
          <Form.Check key={opt} type="checkbox" label={opt} checked={selected.includes(opt)} onChange={() => toggle(opt)} className="fs-14" />
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
        <Form.Check key={y} type="radio" name={groupName} label={y} checked={value === y} onChange={() => onChange(y)} />
      ))}
    </div>
  </div>
);

const PhotographerMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const pm = useMemo(() => {
    const raw = formData.photographer_master || formData.attributes?.photographer_master;
    if (raw && typeof raw === "object") return mergeDeep(emptyPhotographerMaster(), raw);
    return emptyPhotographerMaster();
  }, [formData.photographer_master, formData.attributes?.photographer_master]);

  const patchPm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(
          prev.photographer_master || prev.attributes?.photographer_master || emptyPhotographerMaster(),
          partial
        );
        return {
          ...prev,
          photographer_master: next,
          attributes: { ...(prev.attributes || {}), photographer_master: next },
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
        <h4 className="mb-2 fw-bold">Wedding photographer master profile</h4>
        <p className="text-muted fs-14 mb-4">Structured photographer attributes for storefront and AI FAQ matching.</p>
        <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
          <Accordion.Item eventKey="0">
            <Accordion.Header>Section 1 — Basic identity</Accordion.Header>
            <Accordion.Body>
              <MultiCheck label="Services offered" options={SERVICES_OFFERED} value={pm.identity.services_offered} onChange={(v) => patchPm({ identity: { ...pm.identity, services_offered: v } })} />
              <SelectField label="Also available for" options={ALSO_AVAILABLE_FOR} value={pm.identity.also_available_for} onChange={(v) => patchPm({ identity: { ...pm.identity, also_available_for: v } })} />
              <div className="mb-3">
                <label className="form-label fw-semibold">Years of experience</label>
                <Form.Control type="number" value={pm.identity.years_of_experience} onChange={(e) => patchPm({ identity: { ...pm.identity, years_of_experience: e.target.value } })} />
              </div>
              <SelectField label="Travel availability" options={TRAVEL_AVAILABILITY} value={pm.identity.travel_availability} onChange={(v) => patchPm({ identity: { ...pm.identity, travel_availability: v } })} />
            </Accordion.Body>
          </Accordion.Item>
          <Accordion.Item eventKey="1">
            <Accordion.Header>Section 2 — Style intelligence</Accordion.Header>
            <Accordion.Body>
              <MultiCheck label="Photography style" options={PHOTOGRAPHY_STYLE} value={pm.style_intelligence.photography_style} onChange={(v) => patchPm({ style_intelligence: { ...pm.style_intelligence, photography_style: v } })} />
              <SelectField label="Editing style" options={EDITING_STYLE} value={pm.style_intelligence.editing_style} onChange={(v) => patchPm({ style_intelligence: { ...pm.style_intelligence, editing_style: v } })} />
              <MultiCheck label="Best known for" options={BEST_KNOWN_FOR} value={pm.style_intelligence.best_known_for} onChange={(v) => patchPm({ style_intelligence: { ...pm.style_intelligence, best_known_for: v } })} />
              <MultiCheck label="Ideal wedding type" options={IDEAL_WEDDING_TYPE} value={pm.style_intelligence.ideal_wedding_type} onChange={(v) => patchPm({ style_intelligence: { ...pm.style_intelligence, ideal_wedding_type: v } })} />
            </Accordion.Body>
          </Accordion.Item>
          <Accordion.Item eventKey="2">
            <Accordion.Header>Section 3–9 — Team, deliverables, pricing, equipment, workflow & suitability</Accordion.Header>
            <Accordion.Body>
              <SelectField label="Team size" options={TEAM_SIZE} value={pm.team_coverage.team_size} onChange={(v) => patchPm({ team_coverage: { ...pm.team_coverage, team_size: v } })} />
              <div className="mb-3"><label className="form-label fw-semibold">Max events covered per day</label><Form.Control type="number" value={pm.team_coverage.max_events_per_day} onChange={(e) => patchPm({ team_coverage: { ...pm.team_coverage, max_events_per_day: e.target.value } })} /></div>
              <YesNoField groupName="backupTeam" label="Backup team available" value={pm.team_coverage.backup_team_available} onChange={(v) => patchPm({ team_coverage: { ...pm.team_coverage, backup_team_available: v } })} />
              <YesNoField groupName="femalePhotographer" label="Female photographer available" value={pm.team_coverage.female_photographer_available} onChange={(v) => patchPm({ team_coverage: { ...pm.team_coverage, female_photographer_available: v } })} />

              <SelectField label="Photos delivered" options={PHOTOS_DELIVERED} value={pm.deliverables.photos_delivered} onChange={(v) => patchPm({ deliverables: { ...pm.deliverables, photos_delivered: v } })} />
              <MultiCheck label="Videos delivered" options={VIDEOS_DELIVERED} value={pm.deliverables.videos_delivered} onChange={(v) => patchPm({ deliverables: { ...pm.deliverables, videos_delivered: v } })} />
              <YesNoField groupName="rawData" label="Raw data provided" value={pm.deliverables.raw_data_provided} onChange={(v) => patchPm({ deliverables: { ...pm.deliverables, raw_data_provided: v } })} />
              <YesNoField groupName="albumIncluded" label="Album included" value={pm.deliverables.album_included} onChange={(v) => patchPm({ deliverables: { ...pm.deliverables, album_included: v } })} />
              <SelectField label="Album type" options={ALBUM_TYPE} value={pm.deliverables.album_type} onChange={(v) => patchPm({ deliverables: { ...pm.deliverables, album_type: v } })} />
              <SelectField label="Delivery time" options={DELIVERY_TIME} value={pm.deliverables.delivery_time} onChange={(v) => patchPm({ deliverables: { ...pm.deliverables, delivery_time: v } })} />
              <YesNoField groupName="expressDelivery" label="Express delivery available" value={pm.deliverables.express_delivery_available} onChange={(v) => patchPm({ deliverables: { ...pm.deliverables, express_delivery_available: v } })} />

              <div className="mb-3"><label className="form-label fw-semibold">Starting price</label><Form.Control type="number" value={pm.pricing.starting_price} onChange={(e) => patchPm({ pricing: { ...pm.pricing, starting_price: e.target.value } })} /></div>
              <SelectField label="Pricing type" options={PRICING_TYPE} value={pm.pricing.pricing_type} onChange={(v) => patchPm({ pricing: { ...pm.pricing, pricing_type: v } })} />
              <SelectField label="Pre-wedding shoot cost" options={PRE_WEDDING_COST} value={pm.pricing.pre_wedding_shoot_cost} onChange={(v) => patchPm({ pricing: { ...pm.pricing, pre_wedding_shoot_cost: v } })} />
              <SelectField label="Travel charges" options={TRAVEL_CHARGES} value={pm.pricing.travel_charges} onChange={(v) => patchPm({ pricing: { ...pm.pricing, travel_charges: v } })} />
              <YesNoField groupName="accomodationReq" label="Accommodation required" value={pm.pricing.accommodation_required} onChange={(v) => patchPm({ pricing: { ...pm.pricing, accommodation_required: v } })} />

              <SelectField label="Camera type" options={CAMERA_TYPE} value={pm.equipment.camera_type} onChange={(v) => patchPm({ equipment: { ...pm.equipment, camera_type: v } })} />
              <YesNoField groupName="drone" label="Drone available" value={pm.equipment.drone_available} onChange={(v) => patchPm({ equipment: { ...pm.equipment, drone_available: v } })} />
              <SelectField label="Lighting setup" options={LIGHTING_SETUP} value={pm.equipment.lighting_setup} onChange={(v) => patchPm({ equipment: { ...pm.equipment, lighting_setup: v } })} />
              <YesNoField groupName="liveStreaming" label="Live streaming setup" value={pm.equipment.live_streaming_setup} onChange={(v) => patchPm({ equipment: { ...pm.equipment, live_streaming_setup: v } })} />

              <SelectField label="Pre-wedding shoot locations supported" options={PRE_WEDDING_LOCATIONS} value={pm.prewedding_specialization.locations_supported} onChange={(v) => patchPm({ prewedding_specialization: { ...pm.prewedding_specialization, locations_supported: v } })} />
              <YesNoField groupName="conceptShoot" label="Concept shoot available" value={pm.prewedding_specialization.concept_shoot_available} onChange={(v) => patchPm({ prewedding_specialization: { ...pm.prewedding_specialization, concept_shoot_available: v } })} />
              <YesNoField groupName="propsProvided" label="Props provided" value={pm.prewedding_specialization.props_provided} onChange={(v) => patchPm({ prewedding_specialization: { ...pm.prewedding_specialization, props_provided: v } })} />
              <YesNoField groupName="locationScout" label="Location scouting support" value={pm.prewedding_specialization.location_scouting_support} onChange={(v) => patchPm({ prewedding_specialization: { ...pm.prewedding_specialization, location_scouting_support: v } })} />

              <YesNoField groupName="advanceReq" label="Booking advance required" value={pm.workflow.booking_advance_required} onChange={(v) => patchPm({ workflow: { ...pm.workflow, booking_advance_required: v } })} />
              <SelectField label="Advance percentage" options={ADVANCE_PERCENTAGE} value={pm.workflow.advance_percentage} onChange={(v) => patchPm({ workflow: { ...pm.workflow, advance_percentage: v } })} />
              <SelectField label="Cancellation policy" options={CANCELLATION_POLICY} value={pm.workflow.cancellation_policy} onChange={(v) => patchPm({ workflow: { ...pm.workflow, cancellation_policy: v } })} />
              <YesNoField groupName="revisionAllowed" label="Revision allowed" value={pm.workflow.revision_allowed} onChange={(v) => patchPm({ workflow: { ...pm.workflow, revision_allowed: v } })} />
              <SelectField label="Number of revisions" options={NUMBER_OF_REVISIONS} value={pm.workflow.number_of_revisions} onChange={(v) => patchPm({ workflow: { ...pm.workflow, number_of_revisions: v } })} />

              <MultiCheck label="Functions covered" options={FUNCTIONS_COVERED} value={pm.event_suitability.functions_covered} onChange={(v) => patchPm({ event_suitability: { ...pm.event_suitability, functions_covered: v } })} />
              <MultiCheck label="Best for" options={BEST_FOR} value={pm.event_suitability.best_for} onChange={(v) => patchPm({ event_suitability: { ...pm.event_suitability, best_for: v } })} />
            </Accordion.Body>
          </Accordion.Item>
          <Accordion.Item eventKey="3">
            <Accordion.Header>Section 10 — Image & video intelligence tagging</Accordion.Header>
            <Accordion.Body>
              <p className="text-muted fs-14">Upload portfolio in Photos/Videos tabs. Use this block for default tagging metadata.</p>
              <div className="mb-3">
                <label className="form-label fw-semibold">Default tags</label>
                <Form.Control value={pm.image_video_tagging.tags} onChange={(e) => patchPm({ image_video_tagging: { ...pm.image_video_tagging, tags: e.target.value } })} />
              </div>
              <div className="mb-3">
                <label className="form-label fw-semibold">Notes</label>
                <Form.Control as="textarea" rows={3} value={pm.image_video_tagging.notes} onChange={(e) => patchPm({ image_video_tagging: { ...pm.image_video_tagging, notes: e.target.value } })} />
              </div>
            </Accordion.Body>
          </Accordion.Item>
        </Accordion>
        {!embedded && (
          <button type="button" className="btn btn-primary mt-3 fs-14" onClick={save}>
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
      <div className="p-3 border rounded bg-white">{inner}</div>
    </div>
  );
};

export default PhotographerMasterProfile;
