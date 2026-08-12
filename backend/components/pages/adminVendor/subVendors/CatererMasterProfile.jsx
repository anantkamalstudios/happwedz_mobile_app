import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  CATERER_TYPES,
  SERVICE_COVERAGE,
  TEAM_SIZE,
  SERVICE_LOCATIONS,
  CATERING_STYLE,
  EVENT_TYPES,
  VEG_NON_VEG,
  SPECIAL_DIETARY,
  CUISINE_TYPES,
  BEST_KNOWN_FOR,
  TASTING_CHARGES,
  MENU_ITEMS_OFFERED,
  LIVE_COUNTERS,
  MAX_PAX,
  EVENTS_PER_DAY,
  PRICE_RANGE,
  PRICING_TYPE,
  EXTRA_CHARGES,
  KITCHEN_SETUP,
  SERVING_STYLE,
  CROCKERY,
  HYGIENE_STANDARDS,
  FOOD_QUALITY_ASSURANCE,
  TRAVEL_CHARGES,
  FUNCTIONS_SUITABLE,
  BEST_FOR,
  ADVANCE_PERCENTAGE,
  BOOKING_TIMELINE,
  CANCELLATION_POLICY,
  REFUND_TIMELINE,
  emptyCatererMaster,
} from "./catererMasterConstants";

const yesNo = ["Yes", "No"];

function mergeDeep(base, patch) {
  const out = { ...base };
  Object.keys(patch || {}).forEach((k) => {
    const pv = patch[k];
    const bv = base[k];
    if (pv && typeof pv === "object" && !Array.isArray(pv) && bv && typeof bv === "object" && !Array.isArray(bv)) {
      out[k] = mergeDeep(bv, pv);
    } else out[k] = pv;
  });
  return out;
}

function SelectField({ label, options, value, onChange }) {
  return (
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
}

function YesNoField({ label, value, onChange, groupName }) {
  return (
    <div className="mb-3">
      <label className="form-label fw-semibold">{label}</label>
      <div className="d-flex gap-3">
        {yesNo.map((y) => (
          <Form.Check key={y} type="radio" name={groupName} label={y} checked={value === y} onChange={() => onChange(y)} />
        ))}
      </div>
    </div>
  );
}

function MultiCheck({ label, options, value, onChange }) {
  const selected = Array.isArray(value) ? value : [];
  const toggle = (opt) => onChange(selected.includes(opt) ? selected.filter((x) => x !== opt) : [...selected, opt]);
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
}

const CatererMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const cm = useMemo(() => {
    const raw = formData.caterer_master || formData.attributes?.caterer_master;
    if (raw && typeof raw === "object") return mergeDeep(emptyCatererMaster(), raw);
    return emptyCatererMaster();
  }, [formData.caterer_master, formData.attributes?.caterer_master]);

  const patchCm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(prev.caterer_master || prev.attributes?.caterer_master || emptyCatererMaster(), partial);
        return { ...prev, caterer_master: next, attributes: { ...(prev.attributes || {}), caterer_master: next } };
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
        <h4 className="mb-2 fw-bold">Caterer master profile</h4>
        <p className="text-muted fs-14 mb-4">Structured caterer attributes for storefront filters and AI FAQ.</p>
        <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
          <Accordion.Item eventKey="0">
            <Accordion.Header>Section 1 — Basic identity</Accordion.Header>
            <Accordion.Body>
              {/* <div className="mb-3">
                <label className="form-label fw-semibold">Brand / Catering company name</label>
                <Form.Control value={cm.identity.brand_name} onChange={(e) => patchCm({ identity: { ...cm.identity, brand_name: e.target.value } })} />
              </div> */}
              <SelectField label="Caterer type" options={CATERER_TYPES} value={cm.identity.caterer_type} onChange={(v) => patchCm({ identity: { ...cm.identity, caterer_type: v } })} />
              <div className="mb-3">
                <label className="form-label fw-semibold">Years of experience</label>
                <Form.Control type="number" value={cm.identity.years_experience} onChange={(e) => patchCm({ identity: { ...cm.identity, years_experience: e.target.value } })} />
              </div>
              <SelectField label="Service coverage" options={SERVICE_COVERAGE} value={cm.identity.service_coverage} onChange={(v) => patchCm({ identity: { ...cm.identity, service_coverage: v } })} />
              <SelectField label="Team size" options={TEAM_SIZE} value={cm.identity.team_size} onChange={(v) => patchCm({ identity: { ...cm.identity, team_size: v } })} />
              <MultiCheck label="Service locations" options={SERVICE_LOCATIONS} value={cm.identity.service_locations} onChange={(v) => patchCm({ identity: { ...cm.identity, service_locations: v } })} />
            </Accordion.Body>
          </Accordion.Item>
          <Accordion.Item eventKey="1">
            <Accordion.Header>Section 2 — Service type</Accordion.Header>
            <Accordion.Body>
              <MultiCheck label="Catering style" options={CATERING_STYLE} value={cm.service_type.catering_style} onChange={(v) => patchCm({ service_type: { ...cm.service_type, catering_style: v } })} />
              <MultiCheck label="Event types covered" options={EVENT_TYPES} value={cm.service_type.event_types_covered} onChange={(v) => patchCm({ service_type: { ...cm.service_type, event_types_covered: v } })} />
              <SelectField label="Veg / Non-Veg" options={VEG_NON_VEG} value={cm.service_type.veg_non_veg} onChange={(v) => patchCm({ service_type: { ...cm.service_type, veg_non_veg: v } })} />
              <YesNoField groupName="jainFood" label="Jain food available" value={cm.service_type.jain_food} onChange={(v) => patchCm({ service_type: { ...cm.service_type, jain_food: v } })} />
              <MultiCheck label="Special dietary options" options={SPECIAL_DIETARY} value={cm.service_type.special_dietary_options} onChange={(v) => patchCm({ service_type: { ...cm.service_type, special_dietary_options: v } })} />
            </Accordion.Body>
          </Accordion.Item>
          <Accordion.Item eventKey="2">
            <Accordion.Header>Section 3 — Cuisine intelligence</Accordion.Header>
            <Accordion.Body>
              <MultiCheck label="Cuisine types" options={CUISINE_TYPES} value={cm.cuisine_intelligence.cuisine_types} onChange={(v) => patchCm({ cuisine_intelligence: { ...cm.cuisine_intelligence, cuisine_types: v } })} />
              <div className="mb-3">
                <label className="form-label fw-semibold">Signature dishes</label>
                <Form.Control value={cm.cuisine_intelligence.signature_dishes} onChange={(e) => patchCm({ cuisine_intelligence: { ...cm.cuisine_intelligence, signature_dishes: e.target.value } })} />
              </div>
              <MultiCheck label="Best known for" options={BEST_KNOWN_FOR} value={cm.cuisine_intelligence.best_known_for} onChange={(v) => patchCm({ cuisine_intelligence: { ...cm.cuisine_intelligence, best_known_for: v } })} />
            </Accordion.Body>
          </Accordion.Item>
          <Accordion.Item eventKey="3">
            <Accordion.Header>Section 4 — Menu & customization</Accordion.Header>
            <Accordion.Body>
              <YesNoField groupName="customMenu" label="Custom menu available" value={cm.menu_customization.custom_menu_available} onChange={(v) => patchCm({ menu_customization: { ...cm.menu_customization, custom_menu_available: v } })} />
              <YesNoField groupName="menuTasting" label="Menu tasting available" value={cm.menu_customization.menu_tasting_available} onChange={(v) => patchCm({ menu_customization: { ...cm.menu_customization, menu_tasting_available: v } })} />
              <SelectField label="Tasting charges" options={TASTING_CHARGES} value={cm.menu_customization.tasting_charges} onChange={(v) => patchCm({ menu_customization: { ...cm.menu_customization, tasting_charges: v } })} />
              <SelectField label="Number of menu items offered" options={MENU_ITEMS_OFFERED} value={cm.menu_customization.menu_items_offered} onChange={(v) => patchCm({ menu_customization: { ...cm.menu_customization, menu_items_offered: v } })} />
              <YesNoField groupName="liveCtr" label="Live counters available" value={cm.menu_customization.live_counters_available} onChange={(v) => patchCm({ menu_customization: { ...cm.menu_customization, live_counters_available: v } })} />
              <MultiCheck label="Popular live counters" options={LIVE_COUNTERS} value={cm.menu_customization.popular_live_counters} onChange={(v) => patchCm({ menu_customization: { ...cm.menu_customization, popular_live_counters: v } })} />
            </Accordion.Body>
          </Accordion.Item>
          <Accordion.Item eventKey="4">
            <Accordion.Header>Section 5–11 — Scale, pricing, infra, hygiene, logistics, suitability, workflow</Accordion.Header>
            <Accordion.Body>
              <div className="mb-3"><label className="form-label fw-semibold">Minimum pax</label><Form.Control type="number" value={cm.scale_execution.minimum_pax} onChange={(e) => patchCm({ scale_execution: { ...cm.scale_execution, minimum_pax: e.target.value } })} /></div>
              <SelectField label="Maximum pax" options={MAX_PAX} value={cm.scale_execution.maximum_pax} onChange={(v) => patchCm({ scale_execution: { ...cm.scale_execution, maximum_pax: v } })} />
              <SelectField label="Events handled per day" options={EVENTS_PER_DAY} value={cm.scale_execution.events_per_day} onChange={(v) => patchCm({ scale_execution: { ...cm.scale_execution, events_per_day: v } })} />
              <YesNoField groupName="multiEvent" label="Multiple event handling" value={cm.scale_execution.multiple_event_handling} onChange={(v) => patchCm({ scale_execution: { ...cm.scale_execution, multiple_event_handling: v } })} />

              <div className="mb-3"><label className="form-label fw-semibold">Per plate starting price</label><Form.Control type="number" value={cm.pricing_structure.per_plate_starting_price} onChange={(e) => patchCm({ pricing_structure: { ...cm.pricing_structure, per_plate_starting_price: e.target.value } })} /></div>
              <SelectField label="Price range" options={PRICE_RANGE} value={cm.pricing_structure.price_range} onChange={(v) => patchCm({ pricing_structure: { ...cm.pricing_structure, price_range: v } })} />
              <SelectField label="Pricing type" options={PRICING_TYPE} value={cm.pricing_structure.pricing_type} onChange={(v) => patchCm({ pricing_structure: { ...cm.pricing_structure, pricing_type: v } })} />
              <MultiCheck label="Extra charges" options={EXTRA_CHARGES} value={cm.pricing_structure.extra_charges} onChange={(v) => patchCm({ pricing_structure: { ...cm.pricing_structure, extra_charges: v } })} />

              <SelectField label="Kitchen setup" options={KITCHEN_SETUP} value={cm.infrastructure_equipment.kitchen_setup} onChange={(v) => patchCm({ infrastructure_equipment: { ...cm.infrastructure_equipment, kitchen_setup: v } })} />
              <YesNoField groupName="servingStaff" label="Serving staff included" value={cm.infrastructure_equipment.serving_staff_included} onChange={(v) => patchCm({ infrastructure_equipment: { ...cm.infrastructure_equipment, serving_staff_included: v } })} />
              <SelectField label="Serving style" options={SERVING_STYLE} value={cm.infrastructure_equipment.serving_style} onChange={(v) => patchCm({ infrastructure_equipment: { ...cm.infrastructure_equipment, serving_style: v } })} />
              <SelectField label="Utensils & crockery" options={CROCKERY} value={cm.infrastructure_equipment.utensils_crockery} onChange={(v) => patchCm({ infrastructure_equipment: { ...cm.infrastructure_equipment, utensils_crockery: v } })} />
              <YesNoField groupName="ecoFriendly" label="Disposable / Eco-Friendly options" value={cm.infrastructure_equipment.eco_friendly_options} onChange={(v) => patchCm({ infrastructure_equipment: { ...cm.infrastructure_equipment, eco_friendly_options: v } })} />

              <MultiCheck label="Hygiene standards" options={HYGIENE_STANDARDS} value={cm.hygiene_quality.hygiene_standards} onChange={(v) => patchCm({ hygiene_quality: { ...cm.hygiene_quality, hygiene_standards: v } })} />
              <SelectField label="Food quality assurance" options={FOOD_QUALITY_ASSURANCE} value={cm.hygiene_quality.food_quality_assurance} onChange={(v) => patchCm({ hygiene_quality: { ...cm.hygiene_quality, food_quality_assurance: v } })} />

              <YesNoField groupName="outdoorCat" label="Outdoor catering supported" value={cm.venue_logistics.outdoor_catering_supported} onChange={(v) => patchCm({ venue_logistics: { ...cm.venue_logistics, outdoor_catering_supported: v } })} />
              <YesNoField groupName="destWedding" label="Destination weddings supported" value={cm.venue_logistics.destination_weddings_supported} onChange={(v) => patchCm({ venue_logistics: { ...cm.venue_logistics, destination_weddings_supported: v } })} />
              <SelectField label="Travel charges" options={TRAVEL_CHARGES} value={cm.venue_logistics.travel_charges} onChange={(v) => patchCm({ venue_logistics: { ...cm.venue_logistics, travel_charges: v } })} />
              <YesNoField groupName="stayReq" label="Stay requirement" value={cm.venue_logistics.stay_requirement} onChange={(v) => patchCm({ venue_logistics: { ...cm.venue_logistics, stay_requirement: v } })} />

              <MultiCheck label="Functions suitable for" options={FUNCTIONS_SUITABLE} value={cm.event_suitability.functions_suitable_for} onChange={(v) => patchCm({ event_suitability: { ...cm.event_suitability, functions_suitable_for: v } })} />
              <MultiCheck label="Best for" options={BEST_FOR} value={cm.event_suitability.best_for} onChange={(v) => patchCm({ event_suitability: { ...cm.event_suitability, best_for: v } })} />

              <YesNoField groupName="advReq" label="Advance required" value={cm.workflow_booking.advance_required} onChange={(v) => patchCm({ workflow_booking: { ...cm.workflow_booking, advance_required: v } })} />
              <SelectField label="Advance percentage" options={ADVANCE_PERCENTAGE} value={cm.workflow_booking.advance_percentage} onChange={(v) => patchCm({ workflow_booking: { ...cm.workflow_booking, advance_percentage: v } })} />
              <SelectField label="Booking timeline" options={BOOKING_TIMELINE} value={cm.workflow_booking.booking_timeline} onChange={(v) => patchCm({ workflow_booking: { ...cm.workflow_booking, booking_timeline: v } })} />
              <SelectField label="Cancellation policy" options={CANCELLATION_POLICY} value={cm.workflow_booking.cancellation_policy} onChange={(v) => patchCm({ workflow_booking: { ...cm.workflow_booking, cancellation_policy: v } })} />
              <SelectField label="Refund timeline" options={REFUND_TIMELINE} value={cm.workflow_booking.refund_timeline} onChange={(v) => patchCm({ workflow_booking: { ...cm.workflow_booking, refund_timeline: v } })} />
            </Accordion.Body>
          </Accordion.Item>
          <Accordion.Item eventKey="5">
            <Accordion.Header>Section 12 — Menu & event tagging</Accordion.Header>
            <Accordion.Body>
              <p className="text-muted fs-14">Upload menu/event photos in Photos tab. Use tags below as default tagging metadata.</p>
              <div className="mb-3">
                <label className="form-label fw-semibold">Tagging notes</label>
                <Form.Control as="textarea" rows={3} value={cm.menu_event_tagging.notes} onChange={(e) => patchCm({ menu_event_tagging: { ...cm.menu_event_tagging, notes: e.target.value } })} />
              </div>
              <div className="mb-3">
                <label className="form-label fw-semibold">Default tags</label>
                <Form.Control value={cm.menu_event_tagging.tags} onChange={(e) => patchCm({ menu_event_tagging: { ...cm.menu_event_tagging, tags: e.target.value } })} />
              </div>
            </Accordion.Body>
          </Accordion.Item>
        </Accordion>
        {!embedded && (
          <button type="button" className="btn btn-primary mt-3 fs-14" onClick={save}>
            Save caterer master profile
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

export default CatererMasterProfile;
