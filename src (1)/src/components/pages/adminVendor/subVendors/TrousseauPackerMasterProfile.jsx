import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  TROUSSEAU_VENDOR_TYPE,
  YEARS_OF_EXPERIENCE,
  SERVICE_MODE,
  TRAVEL_POLICY,
  PACKAGING_TYPES,
  PRODUCT_FORMATS,
  OCCASION_COVERAGE,
  DESIGN_STYLE_TROUSSEAU,
  CUSTOMIZATION_LEVEL,
  MATERIAL_TYPES,
  COLOR_PALETTE,
  PERSONALIZATION_OPTIONS_TROUSSEAU,
  EMBELLISHMENTS,
  MIN_ORDER_QTY,
  MAX_ORDER_HANDLING,
  TURNAROUND_TIME,
  DELIVERY_OPTIONS,
  PACKAGING_ASSEMBLY,
  PRICING_MODEL_TROUSSEAU,
  PRICE_RANGE_TROUSSEAU,
  INCLUDES_TROUSSEAU,
  ADDONS_TROUSSEAU,
  NEGOTIATION,
  ORDERS_PER_DAY,
  TEAM_SIZE,
  ADVANCE_BOOKING_TIME,
  BOOKING_ADVANCE,
  CANCELLATION_POLICY,
  CLIENT_COORDINATION,
  emptyTrousseauMaster,
} from "./trousseauPackerMasterConstants";

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

const TrousseauPackerMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const dm = useMemo(() => {
    const raw = formData.trousseau_master || formData.attributes?.trousseau_master;
    if (raw && typeof raw === "object") return mergeDeep(emptyTrousseauMaster(), raw);
    return emptyTrousseauMaster();
  }, [formData.trousseau_master, formData.attributes?.trousseau_master]);

  const patchDm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const current =
          prev.trousseau_master ||
          prev.attributes?.trousseau_master ||
          emptyTrousseauMaster();
        const next = mergeDeep(current, partial);
        return {
          ...prev,
          trousseau_master: next,
          attributes: { ...(prev.attributes || {}), trousseau_master: next },
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
      <h4 className="mb-2 fw-bold">Trousseau Packer Master Profile</h4>
      <p className="text-muted fs-14 mb-4">Structured trousseau packer data for search, filters, and AI FAQ.</p>
      
      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        <Accordion.Item eventKey="0">
          <Accordion.Header>Section 1 — Basic Identity</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Years of Experience" options={YEARS_OF_EXPERIENCE} value={dm.identity.years_of_experience} onChange={(v) => patchDm({ identity: { ...dm.identity, years_of_experience: v } })} />
            <div className="mb-3">
              <label className="form-label fw-semibold">Primary City</label>
              <Form.Control className="fs-14" value={dm.identity.primary_city} onChange={(e) => patchDm({ identity: { ...dm.identity, primary_city: e.target.value } })} />
            </div>
            <div className="mb-3">
              <label className="form-label fw-semibold">Service Cities (Comma Separated)</label>
              <Form.Control className="fs-14" value={dm.identity.service_cities?.join(', ') || ""} onChange={(e) => patchDm({ identity: { ...dm.identity, service_cities: e.target.value.split(',').map(s=>s.trim()).filter(Boolean) } })} />
            </div>
            <SelectField label="Service Mode" options={SERVICE_MODE} value={dm.identity.service_mode} onChange={(v) => patchDm({ identity: { ...dm.identity, service_mode: v } })} />
            <SelectField label="Travel Policy" options={TRAVEL_POLICY} value={dm.identity.travel_policy} onChange={(v) => patchDm({ identity: { ...dm.identity, travel_policy: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Services Offered</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Packaging Types" options={PACKAGING_TYPES} value={dm.services.packaging_types} onChange={(v) => patchDm({ services: { ...dm.services, packaging_types: v } })} />
            <MultiCheck label="Product Formats" options={PRODUCT_FORMATS} value={dm.services.product_formats} onChange={(v) => patchDm({ services: { ...dm.services, product_formats: v } })} />
            <MultiCheck label="Occasion Coverage" options={OCCASION_COVERAGE} value={dm.services.occasion_coverage} onChange={(v) => patchDm({ services: { ...dm.services, occasion_coverage: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="2">
          <Accordion.Header>Section 3 — Core Intelligence</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Design Style" options={DESIGN_STYLE_TROUSSEAU} value={dm.intelligence.design_style} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, design_style: v } })} />
            <SelectField label="Customization Level" options={CUSTOMIZATION_LEVEL} value={dm.intelligence.customization_level} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, customization_level: v } })} />
            <MultiCheck label="Material Types" options={MATERIAL_TYPES} value={dm.intelligence.material_types} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, material_types: v } })} />
            <SelectField label="Color Palette Options" options={COLOR_PALETTE} value={dm.intelligence.color_palette} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, color_palette: v } })} />
            <MultiCheck label="Personalization Options" options={PERSONALIZATION_OPTIONS_TROUSSEAU} value={dm.intelligence.personalization_options} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, personalization_options: v } })} />
            <MultiCheck label="Embellishments" options={EMBELLISHMENTS} value={dm.intelligence.embellishments} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, embellishments: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="3">
          <Accordion.Header>Section 4 — Product & Capacity</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Minimum Order Quantity" options={MIN_ORDER_QTY} value={dm.capacity.minimum_order_quantity} onChange={(v) => patchDm({ capacity: { ...dm.capacity, minimum_order_quantity: v } })} />
            <SelectField label="Maximum Order Handling" options={MAX_ORDER_HANDLING} value={dm.capacity.maximum_order_handling} onChange={(v) => patchDm({ capacity: { ...dm.capacity, maximum_order_handling: v } })} />
            <YesNoField groupName="tpBulk" label="Bulk Order Capability" value={dm.capacity.bulk_order_capability} onChange={(v) => patchDm({ capacity: { ...dm.capacity, bulk_order_capability: v } })} />
            <YesNoField groupName="tpReady" label="Ready Stock Availability" value={dm.capacity.ready_stock_availability} onChange={(v) => patchDm({ capacity: { ...dm.capacity, ready_stock_availability: v } })} />
            <SelectField label="Customization Turnaround Time" options={TURNAROUND_TIME} value={dm.capacity.customization_turnaround} onChange={(v) => patchDm({ capacity: { ...dm.capacity, customization_turnaround: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="4">
          <Accordion.Header>Section 5 — Logistics & Execution</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Delivery Options" options={DELIVERY_OPTIONS} value={dm.logistics.delivery_options} onChange={(v) => patchDm({ logistics: { ...dm.logistics, delivery_options: v } })} />
            <SelectField label="Packaging Assembly" options={PACKAGING_ASSEMBLY} value={dm.logistics.packaging_assembly} onChange={(v) => patchDm({ logistics: { ...dm.logistics, packaging_assembly: v } })} />
            <YesNoField groupName="tpFragile" label="Fragile Handling" value={dm.logistics.fragile_handling} onChange={(v) => patchDm({ logistics: { ...dm.logistics, fragile_handling: v } })} />
            <YesNoField groupName="tpStorage" label="Storage Support" value={dm.logistics.storage_support} onChange={(v) => patchDm({ logistics: { ...dm.logistics, storage_support: v } })} />
            <YesNoField groupName="tpUrgent" label="Urgent Order Handling" value={dm.logistics.urgent_order_handling} onChange={(v) => patchDm({ logistics: { ...dm.logistics, urgent_order_handling: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Pricing Logic</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Pricing Model" options={PRICING_MODEL_TROUSSEAU} value={dm.pricing.pricing_model} onChange={(v) => patchDm({ pricing: { ...dm.pricing, pricing_model: v } })} />
            <SelectField label="Starting Price Range (Per Unit)" options={PRICE_RANGE_TROUSSEAU} value={dm.pricing.starting_price_range} onChange={(v) => patchDm({ pricing: { ...dm.pricing, starting_price_range: v } })} />
            <MultiCheck label="Includes" options={INCLUDES_TROUSSEAU} value={dm.pricing.includes} onChange={(v) => patchDm({ pricing: { ...dm.pricing, includes: v } })} />
            <MultiCheck label="Add-ons" options={ADDONS_TROUSSEAU} value={dm.pricing.add_ons} onChange={(v) => patchDm({ pricing: { ...dm.pricing, add_ons: v } })} />
            <SelectField label="Negotiation Flexibility" options={NEGOTIATION} value={dm.pricing.negotiation_flexibility} onChange={(v) => patchDm({ pricing: { ...dm.pricing, negotiation_flexibility: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Scale & Operations</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Orders Per Day Capacity" options={ORDERS_PER_DAY} value={dm.scale.orders_per_day_capacity} onChange={(v) => patchDm({ scale: { ...dm.scale, orders_per_day_capacity: v } })} />
            <SelectField label="Team Size" options={TEAM_SIZE} value={dm.scale.team_size} onChange={(v) => patchDm({ scale: { ...dm.scale, team_size: v } })} />
            <YesNoField groupName="tpParallel" label="Parallel Order Handling" value={dm.scale.parallel_order_handling} onChange={(v) => patchDm({ scale: { ...dm.scale, parallel_order_handling: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="7">
          <Accordion.Header>Section 8 — Workflow & Booking</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Advance Booking Time" options={ADVANCE_BOOKING_TIME} value={dm.workflow.advance_booking_time} onChange={(v) => patchDm({ workflow: { ...dm.workflow, advance_booking_time: v } })} />
            <SelectField label="Booking Advance %" options={BOOKING_ADVANCE} value={dm.workflow.booking_advance_percent} onChange={(v) => patchDm({ workflow: { ...dm.workflow, booking_advance_percent: v } })} />
            <SelectField label="Cancellation Policy" options={CANCELLATION_POLICY} value={dm.workflow.cancellation_policy} onChange={(v) => patchDm({ workflow: { ...dm.workflow, cancellation_policy: v } })} />
            <SelectField label="Client Coordination" options={CLIENT_COORDINATION} value={dm.workflow.client_coordination} onChange={(v) => patchDm({ workflow: { ...dm.workflow, client_coordination: v } })} />
            <YesNoField groupName="tpSample" label="Sample Availability" value={dm.workflow.sample_availability} onChange={(v) => patchDm({ workflow: { ...dm.workflow, sample_availability: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="8">
          <Accordion.Header>Section 9 — Portfolio Tagging</Accordion.Header>
          <Accordion.Body>
            <div className="mb-3">
              <label className="form-label fw-semibold">Packaging Tags</label>
              <Form.Control className="fs-14" value={dm.portfolio.packaging_tags} onChange={(e) => patchDm({ portfolio: { ...dm.portfolio, packaging_tags: e.target.value } })} />
            </div>
            <div className="mb-3">
              <label className="form-label fw-semibold">Occasion Tags</label>
              <Form.Control className="fs-14" value={dm.portfolio.occasion_tags} onChange={(e) => patchDm({ portfolio: { ...dm.portfolio, occasion_tags: e.target.value } })} />
            </div>
            <div className="mb-3">
              <label className="form-label fw-semibold">Style Tags</label>
              <Form.Control className="fs-14" value={dm.portfolio.style_tags} onChange={(e) => patchDm({ portfolio: { ...dm.portfolio, style_tags: e.target.value } })} />
            </div>
          </Accordion.Body>
        </Accordion.Item>
      </Accordion>

      {!embedded && (
        <button type="button" className="btn btn-primary mt-3 fs-14" onClick={save}>
          Save Trousseau Packer Master Profile
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

export default TrousseauPackerMasterProfile;
