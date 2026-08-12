import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  GIFT_VENDOR_TYPE,
  YEARS_OF_EXPERIENCE,
  BUSINESS_MODEL,
  GIFT_CATEGORIES,
  OCCASION_SUITABILITY,
  TARGET_AUDIENCE,
  GIFT_TYPE_CLASSIFICATION,
  CUSTOMIZATION_OPTIONS_GIFT,
  THEME_COMPATIBILITY,
  SHELF_LIFE,
  PREMIUM_LUXURY_TAG,
  MIN_ORDER_QTY,
  MAX_ORDER_CAPACITY,
  TURNAROUND_TIME,
  DELIVERY_OPTIONS,
  SHIPPING_COVERAGE,
  PRICING_MODEL_GIFT,
  PRICE_RANGE_GIFT,
  INCLUDES_GIFT,
  ADDONS_GIFT,
  NEGOTIATION,
  ORDERS_PER_DAY,
  TEAM_SIZE,
  ADVANCE_BOOKING_TIME,
  BOOKING_ADVANCE,
  CANCELLATION_POLICY,
  CLIENT_COORDINATION,
  emptyGiftMaster,
} from "./giftMasterConstants";

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

const GiftMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const dm = useMemo(() => {
    const raw = formData.gift_master || formData.attributes?.gift_master;
    if (raw && typeof raw === "object") return mergeDeep(emptyGiftMaster(), raw);
    return emptyGiftMaster();
  }, [formData.gift_master, formData.attributes?.gift_master]);

  const patchDm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const current =
          prev.gift_master ||
          prev.attributes?.gift_master ||
          emptyGiftMaster();
        const next = mergeDeep(current, partial);
        return {
          ...prev,
          gift_master: next,
          attributes: { ...(prev.attributes || {}), gift_master: next },
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
      <h4 className="mb-2 fw-bold">Gift Master Profile</h4>
      <p className="text-muted fs-14 mb-4">Structured gift vendor data for search, filters, and AI FAQ.</p>
      
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
            <MultiCheck label="Gift Categories" options={GIFT_CATEGORIES} value={dm.catalog.gift_categories} onChange={(v) => patchDm({ catalog: { ...dm.catalog, gift_categories: v } })} />
            <MultiCheck label="Occasion Suitability" options={OCCASION_SUITABILITY} value={dm.catalog.occasion_suitability} onChange={(v) => patchDm({ catalog: { ...dm.catalog, occasion_suitability: v } })} />
            <SelectField label="Target Audience" options={TARGET_AUDIENCE} value={dm.catalog.target_audience} onChange={(v) => patchDm({ catalog: { ...dm.catalog, target_audience: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="2">
          <Accordion.Header>Section 3 — Core Intelligence</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Gift Type Classification" options={GIFT_TYPE_CLASSIFICATION} value={dm.intelligence.gift_type_classification} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, gift_type_classification: v } })} />
            <MultiCheck label="Customization Options" options={CUSTOMIZATION_OPTIONS_GIFT} value={dm.intelligence.customization_options} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, customization_options: v } })} />
            <SelectField label="Theme Compatibility" options={THEME_COMPATIBILITY} value={dm.intelligence.theme_compatibility} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, theme_compatibility: v } })} />
            <SelectField label="Shelf Life (for consumables)" options={SHELF_LIFE} value={dm.intelligence.shelf_life} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, shelf_life: v } })} />
            <YesNoField groupName="gtPack" label="Packaging Included" value={dm.intelligence.packaging_included} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, packaging_included: v } })} />
            <YesNoField groupName="gtEco" label="Eco-Friendly Options" value={dm.intelligence.eco_friendly_options} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, eco_friendly_options: v } })} />
            <SelectField label="Premium / Luxury Tag" options={PREMIUM_LUXURY_TAG} value={dm.intelligence.premium_luxury_tag} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, premium_luxury_tag: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="3">
          <Accordion.Header>Section 4 — Product & Capacity</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Minimum Order Quantity" options={MIN_ORDER_QTY} value={dm.capacity.minimum_order_quantity} onChange={(v) => patchDm({ capacity: { ...dm.capacity, minimum_order_quantity: v } })} />
            <SelectField label="Maximum Order Capacity" options={MAX_ORDER_CAPACITY} value={dm.capacity.maximum_order_capacity} onChange={(v) => patchDm({ capacity: { ...dm.capacity, maximum_order_capacity: v } })} />
            <YesNoField groupName="gtBulk" label="Bulk Order Handling" value={dm.capacity.bulk_order_handling} onChange={(v) => patchDm({ capacity: { ...dm.capacity, bulk_order_handling: v } })} />
            <YesNoField groupName="gtReady" label="Ready Stock Availability" value={dm.capacity.ready_stock_availability} onChange={(v) => patchDm({ capacity: { ...dm.capacity, ready_stock_availability: v } })} />
            <SelectField label="Customization Turnaround Time" options={TURNAROUND_TIME} value={dm.capacity.customization_turnaround} onChange={(v) => patchDm({ capacity: { ...dm.capacity, customization_turnaround: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="4">
          <Accordion.Header>Section 5 — Logistics & Fulfillment</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Delivery Options" options={DELIVERY_OPTIONS} value={dm.logistics.delivery_options} onChange={(v) => patchDm({ logistics: { ...dm.logistics, delivery_options: v } })} />
            <SelectField label="Shipping Coverage" options={SHIPPING_COVERAGE} value={dm.logistics.shipping_coverage} onChange={(v) => patchDm({ logistics: { ...dm.logistics, shipping_coverage: v } })} />
            <YesNoField groupName="gtFragile" label="Fragile Handling" value={dm.logistics.fragile_handling} onChange={(v) => patchDm({ logistics: { ...dm.logistics, fragile_handling: v } })} />
            <YesNoField groupName="gtTemp" label="Temperature-Control (if required)" value={dm.logistics.temperature_control} onChange={(v) => patchDm({ logistics: { ...dm.logistics, temperature_control: v } })} />
            <YesNoField groupName="gtStorage" label="Storage Support" value={dm.logistics.storage_support} onChange={(v) => patchDm({ logistics: { ...dm.logistics, storage_support: v } })} />
            <YesNoField groupName="gtUrgent" label="Urgent Orders" value={dm.logistics.urgent_orders} onChange={(v) => patchDm({ logistics: { ...dm.logistics, urgent_orders: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Pricing Logic</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Pricing Model" options={PRICING_MODEL_GIFT} value={dm.pricing.pricing_model} onChange={(v) => patchDm({ pricing: { ...dm.pricing, pricing_model: v } })} />
            <SelectField label="Starting Price Range (Per Unit)" options={PRICE_RANGE_GIFT} value={dm.pricing.starting_price_range} onChange={(v) => patchDm({ pricing: { ...dm.pricing, starting_price_range: v } })} />
            <MultiCheck label="Includes" options={INCLUDES_GIFT} value={dm.pricing.includes} onChange={(v) => patchDm({ pricing: { ...dm.pricing, includes: v } })} />
            <MultiCheck label="Add-ons" options={ADDONS_GIFT} value={dm.pricing.add_ons} onChange={(v) => patchDm({ pricing: { ...dm.pricing, add_ons: v } })} />
            <SelectField label="Negotiation Flexibility" options={NEGOTIATION} value={dm.pricing.negotiation_flexibility} onChange={(v) => patchDm({ pricing: { ...dm.pricing, negotiation_flexibility: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Scale & Operations</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Orders Per Day Capacity" options={ORDERS_PER_DAY} value={dm.scale.orders_per_day_capacity} onChange={(v) => patchDm({ scale: { ...dm.scale, orders_per_day_capacity: v } })} />
            <SelectField label="Team Size" options={TEAM_SIZE} value={dm.scale.team_size} onChange={(v) => patchDm({ scale: { ...dm.scale, team_size: v } })} />
            <YesNoField groupName="gtParallel" label="Parallel Orders" value={dm.scale.parallel_orders} onChange={(v) => patchDm({ scale: { ...dm.scale, parallel_orders: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="7">
          <Accordion.Header>Section 8 — Workflow & Booking</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Advance Booking Time" options={ADVANCE_BOOKING_TIME} value={dm.workflow.advance_booking_time} onChange={(v) => patchDm({ workflow: { ...dm.workflow, advance_booking_time: v } })} />
            <SelectField label="Booking Advance %" options={BOOKING_ADVANCE} value={dm.workflow.booking_advance_percent} onChange={(v) => patchDm({ workflow: { ...dm.workflow, booking_advance_percent: v } })} />
            <SelectField label="Cancellation Policy" options={CANCELLATION_POLICY} value={dm.workflow.cancellation_policy} onChange={(v) => patchDm({ workflow: { ...dm.workflow, cancellation_policy: v } })} />
            <SelectField label="Client Coordination" options={CLIENT_COORDINATION} value={dm.workflow.client_coordination} onChange={(v) => patchDm({ workflow: { ...dm.workflow, client_coordination: v } })} />
            <YesNoField groupName="gtSample" label="Sample Availability" value={dm.workflow.sample_availability} onChange={(v) => patchDm({ workflow: { ...dm.workflow, sample_availability: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="8">
          <Accordion.Header>Section 9 — Portfolio Tagging</Accordion.Header>
          <Accordion.Body>
            <div className="mb-3">
              <label className="form-label fw-semibold">Gift Tags</label>
              <Form.Control className="fs-14" value={dm.portfolio.gift_tags} onChange={(e) => patchDm({ portfolio: { ...dm.portfolio, gift_tags: e.target.value } })} />
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
          Save Gift Master Profile
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

export default GiftMasterProfile;
