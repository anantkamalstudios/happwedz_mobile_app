import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  SHERWANI_VENDOR_TYPE,
  STORE_PRESENCE,
  STORE_ACCESS_TYPE,
  YEARS_OF_EXPERIENCE,
  SPECIALIZATION,
  SERVICE_MODES,
  ACCESSORY_ADD_ONS,
  SHERWANI_TYPES,
  OCCASION_SUITABILITY,
  WORK_TYPE,
  FABRIC_OPTIONS,
  COLOR_PALETTE,
  DESIGN_STYLE,
  LAYERING_OPTIONS,
  FIT_TYPE,
  CLOSURE_TYPE,
  LENGTH_TYPE,
  BOTTOM_WEAR_OPTIONS,
  EMBROIDERY_DENSITY,
  DURABILITY_LEVEL,
  PRICE_RANGE,
  PRICING_OPTIONS,
  RENTAL_PRICING_OPTION,
  ACCESSORY_BUNDLE_PRICING,
  DAILY_CLIENT_CAPACITY,
  MONTHLY_PRODUCTION_CAPACITY,
  MEASUREMENT_PROCESS,
  LEAD_TIME,
  TRIAL_ROUNDS,
  ALTERATION_TIMELINE,
  PAYMENT_MODES,
  ADVANCE_PAYMENT,
  STYLE_TAGS,
  AUDIENCE_TAGS,
  USAGE_TAGS,
  PRICE_SEGMENT_TAGS,
  emptySherwaniMaster,
} from "./sherwaniMasterConstants";

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
        <option key={o} value={o}>{o}</option>
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

const SherwaniMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const dm = useMemo(() => {
    const raw = formData.sherwani_master || formData.attributes?.sherwani_master;
    if (raw && typeof raw === "object") return mergeDeep(emptySherwaniMaster(), raw);
    return emptySherwaniMaster();
  }, [formData.sherwani_master, formData.attributes?.sherwani_master]);

  const patchDm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const current =
          prev.sherwani_master ||
          prev.attributes?.sherwani_master ||
          emptySherwaniMaster();
        const next = mergeDeep(current, partial);
        return {
          ...prev,
          sherwani_master: next,
          attributes: { ...(prev.attributes || {}), sherwani_master: next },
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
      <h4 className="mb-2 fw-bold">Sherwani Master Profile</h4>
      <p className="text-muted fs-14 mb-4">Structured sherwani vendor data for search, filters, and AI FAQ.</p>
      
      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        <Accordion.Item eventKey="0">
          <Accordion.Header>Section 1 — Basic Identity</Accordion.Header>
          <Accordion.Body>
            <Form.Check
              type="switch"
              label="Sell on E-commerce"
              className="mb-3 fw-bold"
              checked={dm.identity.sell_on_ecommerce}
              onChange={(e) => patchDm({ identity: { ...dm.identity, sell_on_ecommerce: e.target.checked } })}
            />
            {dm.identity.sell_on_ecommerce && (
              <p className="text-primary fs-14 fw-bold">Contact our Team today!</p>
            )}
            <MultiCheck label="Store Presence" options={STORE_PRESENCE} value={dm.identity.store_presence} onChange={(v) => patchDm({ identity: { ...dm.identity, store_presence: v } })} />
            <div className="mb-3">
              <label className="form-label fw-semibold">City</label>
              <Form.Control className="fs-14" value={dm.identity.city} onChange={(e) => patchDm({ identity: { ...dm.identity, city: e.target.value } })} />
            </div>
            <SelectField label="Store Access Type" options={STORE_ACCESS_TYPE} value={dm.identity.store_access_type} onChange={(v) => patchDm({ identity: { ...dm.identity, store_access_type: v } })} />
            <SelectField label="Years of Experience" options={YEARS_OF_EXPERIENCE} value={dm.identity.years_of_experience} onChange={(v) => patchDm({ identity: { ...dm.identity, years_of_experience: v } })} />
            <MultiCheck label="Specialization" options={SPECIALIZATION} value={dm.identity.specialization} onChange={(v) => patchDm({ identity: { ...dm.identity, specialization: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Services Offered</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Service Modes" options={SERVICE_MODES} value={dm.services.service_modes} onChange={(v) => patchDm({ services: { ...dm.services, service_modes: v } })} />
            <YesNoField groupName="shTrial" label="Trial Availability" value={dm.services.trial_availability} onChange={(v) => patchDm({ services: { ...dm.services, trial_availability: v } })} />
            <YesNoField groupName="shStyle" label="Styling Consultation" value={dm.services.styling_consultation} onChange={(v) => patchDm({ services: { ...dm.services, styling_consultation: v } })} />
            <YesNoField groupName="shHome" label="Home Measurement Service" value={dm.services.home_measurement_service} onChange={(v) => patchDm({ services: { ...dm.services, home_measurement_service: v } })} />
            <YesNoField groupName="shAlt" label="Alteration Services" value={dm.services.alteration_services} onChange={(v) => patchDm({ services: { ...dm.services, alteration_services: v } })} />
            <YesNoField groupName="shExp" label="Express Delivery Available" value={dm.services.express_delivery_available} onChange={(v) => patchDm({ services: { ...dm.services, express_delivery_available: v } })} />
            <MultiCheck label="Accessory Add-ons" options={ACCESSORY_ADD_ONS} value={dm.services.accessory_add_ons} onChange={(v) => patchDm({ services: { ...dm.services, accessory_add_ons: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="2">
          <Accordion.Header>Section 3 — Core Intelligence</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Sherwani Types" options={SHERWANI_TYPES} value={dm.intelligence.sherwani_types} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, sherwani_types: v } })} />
            <MultiCheck label="Occasion Suitability" options={OCCASION_SUITABILITY} value={dm.intelligence.occasion_suitability} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, occasion_suitability: v } })} />
            <MultiCheck label="Work Type" options={WORK_TYPE} value={dm.intelligence.work_type} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, work_type: v } })} />
            <MultiCheck label="Fabric Options" options={FABRIC_OPTIONS} value={dm.intelligence.fabric_options} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, fabric_options: v } })} />
            <MultiCheck label="Color Palette" options={COLOR_PALETTE} value={dm.intelligence.color_palette} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, color_palette: v } })} />
            <MultiCheck label="Design Style" options={DESIGN_STYLE} value={dm.intelligence.design_style} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, design_style: v } })} />
            <MultiCheck label="Layering Options" options={LAYERING_OPTIONS} value={dm.intelligence.layering_options} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, layering_options: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="3">
          <Accordion.Header>Section 4 — Technical / Product / Skill Layer</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Fit Type" options={FIT_TYPE} value={dm.technical.fit_type} onChange={(v) => patchDm({ technical: { ...dm.technical, fit_type: v } })} />
            <MultiCheck label="Closure Type" options={CLOSURE_TYPE} value={dm.technical.closure_type} onChange={(v) => patchDm({ technical: { ...dm.technical, closure_type: v } })} />
            <SelectField label="Length Type" options={LENGTH_TYPE} value={dm.technical.length_type} onChange={(v) => patchDm({ technical: { ...dm.technical, length_type: v } })} />
            <YesNoField groupName="shInner" label="Inner Layer Included" value={dm.technical.inner_layer_included} onChange={(v) => patchDm({ technical: { ...dm.technical, inner_layer_included: v } })} />
            <MultiCheck label="Bottom Wear Options" options={BOTTOM_WEAR_OPTIONS} value={dm.technical.bottom_wear_options} onChange={(v) => patchDm({ technical: { ...dm.technical, bottom_wear_options: v } })} />
            <SelectField label="Embroidery Density" options={EMBROIDERY_DENSITY} value={dm.technical.embroidery_density} onChange={(v) => patchDm({ technical: { ...dm.technical, embroidery_density: v } })} />
            <SelectField label="Durability Level" options={DURABILITY_LEVEL} value={dm.technical.durability_level} onChange={(v) => patchDm({ technical: { ...dm.technical, durability_level: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="4">
          <Accordion.Header>Section 5 — Pricing Logic</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Price Range per Sherwani (INR)" options={PRICE_RANGE} value={dm.pricing.price_range} onChange={(v) => patchDm({ pricing: { ...dm.pricing, price_range: v } })} />
            <SelectField label="Customization Charges" options={PRICING_OPTIONS} value={dm.pricing.customization_charges} onChange={(v) => patchDm({ pricing: { ...dm.pricing, customization_charges: v } })} />
            <SelectField label="Rental Pricing Option" options={RENTAL_PRICING_OPTION} value={dm.pricing.rental_pricing_option} onChange={(v) => patchDm({ pricing: { ...dm.pricing, rental_pricing_option: v } })} />
            <SelectField label="Accessory Bundle Pricing" options={ACCESSORY_BUNDLE_PRICING} value={dm.pricing.accessory_bundle_pricing} onChange={(v) => patchDm({ pricing: { ...dm.pricing, accessory_bundle_pricing: v } })} />
            <YesNoField groupName="shBulkPrice" label="Bulk Discounts (Groom Squad)" value={dm.pricing.bulk_discounts} onChange={(v) => patchDm({ pricing: { ...dm.pricing, bulk_discounts: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Scale & Capacity</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Daily Client Handling Capacity" options={DAILY_CLIENT_CAPACITY} value={dm.capacity.daily_client_capacity} onChange={(v) => patchDm({ capacity: { ...dm.capacity, daily_client_capacity: v } })} />
            <SelectField label="Monthly Production Capacity" options={MONTHLY_PRODUCTION_CAPACITY} value={dm.capacity.monthly_production_capacity} onChange={(v) => patchDm({ capacity: { ...dm.capacity, monthly_production_capacity: v } })} />
            <YesNoField groupName="shTrialRoom" label="Trial Room Availability" value={dm.capacity.trial_room_availability} onChange={(v) => patchDm({ capacity: { ...dm.capacity, trial_room_availability: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Workflow & Booking</Accordion.Header>
          <Accordion.Body>
            <YesNoField groupName="shAppt" label="Appointment Required" value={dm.workflow.appointment_required} onChange={(v) => patchDm({ workflow: { ...dm.workflow, appointment_required: v } })} />
            <MultiCheck label="Measurement Process" options={MEASUREMENT_PROCESS} value={dm.workflow.measurement_process} onChange={(v) => patchDm({ workflow: { ...dm.workflow, measurement_process: v } })} />
            <SelectField label="Lead Time for Delivery" options={LEAD_TIME} value={dm.workflow.lead_time} onChange={(v) => patchDm({ workflow: { ...dm.workflow, lead_time: v } })} />
            <SelectField label="Trial Rounds" options={TRIAL_ROUNDS} value={dm.workflow.trial_rounds} onChange={(v) => patchDm({ workflow: { ...dm.workflow, trial_rounds: v } })} />
            <SelectField label="Alteration Timeline" options={ALTERATION_TIMELINE} value={dm.workflow.alteration_timeline} onChange={(v) => patchDm({ workflow: { ...dm.workflow, alteration_timeline: v } })} />
            <MultiCheck label="Payment Modes" options={PAYMENT_MODES} value={dm.workflow.payment_modes} onChange={(v) => patchDm({ workflow: { ...dm.workflow, payment_modes: v } })} />
            <SelectField label="Advance Payment Percentage" options={ADVANCE_PAYMENT} value={dm.workflow.advance_payment} onChange={(v) => patchDm({ workflow: { ...dm.workflow, advance_payment: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="7">
          <Accordion.Header>Section 8 — Portfolio Tagging</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Style Tags" options={STYLE_TAGS} value={dm.portfolio.style_tags} onChange={(v) => patchDm({ portfolio: { ...dm.portfolio, style_tags: v } })} />
            <MultiCheck label="Audience Tags" options={AUDIENCE_TAGS} value={dm.portfolio.audience_tags} onChange={(v) => patchDm({ portfolio: { ...dm.portfolio, audience_tags: v } })} />
            <MultiCheck label="Usage Tags" options={USAGE_TAGS} value={dm.portfolio.usage_tags} onChange={(v) => patchDm({ portfolio: { ...dm.portfolio, usage_tags: v } })} />
            <SelectField label="Price Segment Tags" options={PRICE_SEGMENT_TAGS} value={dm.portfolio.price_segment_tags} onChange={(v) => patchDm({ portfolio: { ...dm.portfolio, price_segment_tags: v } })} />
          </Accordion.Body>
        </Accordion.Item>

      </Accordion>

      {!embedded && (
        <button type="button" className="btn btn-primary mt-3 fs-14" onClick={save}>
          Save Sherwani Master Profile
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

export default SherwaniMasterProfile;
