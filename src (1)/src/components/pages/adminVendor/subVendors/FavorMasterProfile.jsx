import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  FAVOR_VENDOR_TYPE,
  YEARS_OF_EXPERIENCE,
  BUSINESS_MODEL,
  FAVOR_CATEGORIES,
  OCCASION_MAPPING,
  AUDIENCE_TARGET,
  FAVOR_TYPE_CLASSIFICATION,
  CUSTOMIZATION_OPTIONS_FAVOR,
  THEME_COMPATIBILITY_FAVOR,
  SHELF_LIFE_FAVOR,
  PACKAGING_TYPE,
  MIN_ORDER_QTY,
  MAX_ORDER_CAPACITY,
  TURNAROUND_TIME,
  DELIVERY_OPTIONS,
  SHIPPING_COVERAGE,
  PRICING_MODEL_FAVOR,
  PRICE_RANGE_FAVOR,
  INCLUDES_FAVOR,
  ADDONS_FAVOR,
  NEGOTIATION,
  ORDERS_PER_DAY,
  TEAM_SIZE,
  ADVANCE_BOOKING_TIME,
  BOOKING_ADVANCE,
  CANCELLATION_POLICY,
  CLIENT_COORDINATION,
  emptyFavorMaster,
} from "./favorMasterConstants";

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

const FavorMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const dm = useMemo(() => {
    const raw = formData.favor_master || formData.attributes?.favor_master;
    if (raw && typeof raw === "object") return mergeDeep(emptyFavorMaster(), raw);
    return emptyFavorMaster();
  }, [formData.favor_master, formData.attributes?.favor_master]);

  const patchDm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const current =
          prev.favor_master ||
          prev.attributes?.favor_master ||
          emptyFavorMaster();
        const next = mergeDeep(current, partial);
        return {
          ...prev,
          favor_master: next,
          attributes: { ...(prev.attributes || {}), favor_master: next },
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
      <h4 className="mb-2 fw-bold">Favor Master Profile</h4>
      <p className="text-muted fs-14 mb-4">Structured favor vendor data for search, filters, and AI FAQ.</p>
      
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
            <SelectField label="Business Model" options={BUSINESS_MODEL} value={dm.identity.business_model} onChange={(v) => patchDm({ identity: { ...dm.identity, business_model: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Product Catalog (Core Offering)</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Favor Categories" options={FAVOR_CATEGORIES} value={dm.catalog.favor_categories} onChange={(v) => patchDm({ catalog: { ...dm.catalog, favor_categories: v } })} />
            <MultiCheck label="Occasion Mapping" options={OCCASION_MAPPING} value={dm.catalog.occasion_mapping} onChange={(v) => patchDm({ catalog: { ...dm.catalog, occasion_mapping: v } })} />
            <SelectField label="Audience Target" options={AUDIENCE_TARGET} value={dm.catalog.audience_target} onChange={(v) => patchDm({ catalog: { ...dm.catalog, audience_target: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="2">
          <Accordion.Header>Section 3 — Core Intelligence</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Favor Type Classification" options={FAVOR_TYPE_CLASSIFICATION} value={dm.intelligence.favor_type_classification} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, favor_type_classification: v } })} />
            <MultiCheck label="Customization Options" options={CUSTOMIZATION_OPTIONS_FAVOR} value={dm.intelligence.customization_options} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, customization_options: v } })} />
            <SelectField label="Theme Compatibility" options={THEME_COMPATIBILITY_FAVOR} value={dm.intelligence.theme_compatibility} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, theme_compatibility: v } })} />
            <SelectField label="Shelf Life (if edible)" options={SHELF_LIFE_FAVOR} value={dm.intelligence.shelf_life} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, shelf_life: v } })} />
            <MultiCheck label="Packaging Type" options={PACKAGING_TYPE} value={dm.intelligence.packaging_type} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, packaging_type: v } })} />
            <YesNoField groupName="fvEco" label="Eco-Friendly Option" value={dm.intelligence.eco_friendly_option} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, eco_friendly_option: v } })} />
            <YesNoField groupName="fvReu" label="Reusability" value={dm.intelligence.reusability} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, reusability: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="3">
          <Accordion.Header>Section 4 — Product & Capacity</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Minimum Order Quantity" options={MIN_ORDER_QTY} value={dm.capacity.minimum_order_quantity} onChange={(v) => patchDm({ capacity: { ...dm.capacity, minimum_order_quantity: v } })} />
            <SelectField label="Maximum Order Capacity" options={MAX_ORDER_CAPACITY} value={dm.capacity.maximum_order_capacity} onChange={(v) => patchDm({ capacity: { ...dm.capacity, maximum_order_capacity: v } })} />
            <YesNoField groupName="fvBulk" label="Bulk Handling" value={dm.capacity.bulk_handling} onChange={(v) => patchDm({ capacity: { ...dm.capacity, bulk_handling: v } })} />
            <YesNoField groupName="fvReady" label="Ready Stock" value={dm.capacity.ready_stock} onChange={(v) => patchDm({ capacity: { ...dm.capacity, ready_stock: v } })} />
            <SelectField label="Customization Turnaround" options={TURNAROUND_TIME} value={dm.capacity.customization_turnaround} onChange={(v) => patchDm({ capacity: { ...dm.capacity, customization_turnaround: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="4">
          <Accordion.Header>Section 5 — Logistics & Fulfillment</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Delivery Options" options={DELIVERY_OPTIONS} value={dm.logistics.delivery_options} onChange={(v) => patchDm({ logistics: { ...dm.logistics, delivery_options: v } })} />
            <SelectField label="Shipping Coverage" options={SHIPPING_COVERAGE} value={dm.logistics.shipping_coverage} onChange={(v) => patchDm({ logistics: { ...dm.logistics, shipping_coverage: v } })} />
            <YesNoField groupName="fvFragile" label="Fragile Handling" value={dm.logistics.fragile_handling} onChange={(v) => patchDm({ logistics: { ...dm.logistics, fragile_handling: v } })} />
            <YesNoField groupName="fvTemp" label="Temperature Sensitivity Handling" value={dm.logistics.temperature_sensitivity_handling} onChange={(v) => patchDm({ logistics: { ...dm.logistics, temperature_sensitivity_handling: v } })} />
            <YesNoField groupName="fvUrg" label="Urgent Orders" value={dm.logistics.urgent_orders} onChange={(v) => patchDm({ logistics: { ...dm.logistics, urgent_orders: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Pricing Logic</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Pricing Model" options={PRICING_MODEL_FAVOR} value={dm.pricing.pricing_model} onChange={(v) => patchDm({ pricing: { ...dm.pricing, pricing_model: v } })} />
            <SelectField label="Starting Price Range (Per Unit)" options={PRICE_RANGE_FAVOR} value={dm.pricing.starting_price_range} onChange={(v) => patchDm({ pricing: { ...dm.pricing, starting_price_range: v } })} />
            <MultiCheck label="Includes" options={INCLUDES_FAVOR} value={dm.pricing.includes} onChange={(v) => patchDm({ pricing: { ...dm.pricing, includes: v } })} />
            <MultiCheck label="Add-ons" options={ADDONS_FAVOR} value={dm.pricing.add_ons} onChange={(v) => patchDm({ pricing: { ...dm.pricing, add_ons: v } })} />
            <SelectField label="Negotiation Flexibility" options={NEGOTIATION} value={dm.pricing.negotiation_flexibility} onChange={(v) => patchDm({ pricing: { ...dm.pricing, negotiation_flexibility: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Scale & Operations</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Orders Per Day Capacity" options={ORDERS_PER_DAY} value={dm.scale.orders_per_day_capacity} onChange={(v) => patchDm({ scale: { ...dm.scale, orders_per_day_capacity: v } })} />
            <SelectField label="Team Size" options={TEAM_SIZE} value={dm.scale.team_size} onChange={(v) => patchDm({ scale: { ...dm.scale, team_size: v } })} />
            <YesNoField groupName="fvParallel" label="Parallel Orders" value={dm.scale.parallel_orders} onChange={(v) => patchDm({ scale: { ...dm.scale, parallel_orders: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="7">
          <Accordion.Header>Section 8 — Workflow & Booking</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Advance Booking Time" options={ADVANCE_BOOKING_TIME} value={dm.workflow.advance_booking_time} onChange={(v) => patchDm({ workflow: { ...dm.workflow, advance_booking_time: v } })} />
            <SelectField label="Booking Advance %" options={BOOKING_ADVANCE} value={dm.workflow.booking_advance_percent} onChange={(v) => patchDm({ workflow: { ...dm.workflow, booking_advance_percent: v } })} />
            <SelectField label="Cancellation Policy" options={CANCELLATION_POLICY} value={dm.workflow.cancellation_policy} onChange={(v) => patchDm({ workflow: { ...dm.workflow, cancellation_policy: v } })} />
            <SelectField label="Client Coordination" options={CLIENT_COORDINATION} value={dm.workflow.client_coordination} onChange={(v) => patchDm({ workflow: { ...dm.workflow, client_coordination: v } })} />
            <YesNoField groupName="fvSample" label="Sample Availability" value={dm.workflow.sample_availability} onChange={(v) => patchDm({ workflow: { ...dm.workflow, sample_availability: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="8">
          <Accordion.Header>Section 9 — Portfolio Tagging</Accordion.Header>
          <Accordion.Body>
            <div className="mb-3">
              <label className="form-label fw-semibold">Favor Tags</label>
              <Form.Control className="fs-14" value={dm.portfolio.favor_tags} onChange={(e) => patchDm({ portfolio: { ...dm.portfolio, favor_tags: e.target.value } })} />
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
          Save Favor Master Profile
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

export default FavorMasterProfile;
