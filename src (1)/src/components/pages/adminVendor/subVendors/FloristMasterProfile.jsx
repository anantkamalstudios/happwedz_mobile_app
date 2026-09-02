import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  VENDOR_TYPE,
  SERVICE_PRESENCE,
  STORE_PRESENCE,
  YEARS_OF_EXPERIENCE,
  SPECIALIZATION,
  SERVICE_TYPES,
  PACKAGING_OPTIONS,
  FLOWER_TYPES,
  USAGE_TYPES,
  FRAGRANCE_LEVEL,
  LONGEVITY_TYPE,
  COLOR_PALETTE,
  SEASONAL_AVAILABILITY,
  STORAGE_FACILITY,
  SOURCING_TYPE,
  ARRANGEMENT_TYPES,
  PRICE_RANGE,
  PRICING_MODEL,
  DELIVERY_CHARGES,
  SETUP_CHARGES,
  DAILY_ORDER_CAPACITY,
  EVENT_HANDLING_CAPACITY,
  TEAM_SIZE,
  BOOKING_WINDOW,
  CUSTOMIZATION_APPROVAL,
  DELIVERY_TIME_SLOTS,
  PAYMENT_MODES,
  ADVANCE_PAYMENT_PERCENTAGE,
  STYLE_TAGS,
  AUDIENCE_TAGS,
  USAGE_TAGS,
  PRICE_SEGMENT_TAGS,
  emptyFloristMaster,
} from "./floristMasterConstants";

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

const FloristMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const fm = useMemo(() => {
    const raw = formData.florist_master || formData.attributes?.florist_master;
    if (raw && typeof raw === "object") return mergeDeep(emptyFloristMaster(), raw);
    return emptyFloristMaster();
  }, [formData.florist_master, formData.attributes?.florist_master]);

  const patchFm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(
          prev.florist_master || prev.attributes?.florist_master || emptyFloristMaster(),
          partial
        );
        return {
          ...prev,
          florist_master: next,
          attributes: { ...(prev.attributes || {}), florist_master: next },
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
      <h4 className="mb-2 fw-bold">Florist master profile</h4>
      <p className="text-muted fs-14 mb-4">
        Structured florist attributes for storefront and AI FAQ matching.
      </p>

      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        {/* Section 1 — Basic Identity */}
        <Accordion.Item eventKey="0">
          <Accordion.Header>Section 1 — Basic identity</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Vendor type"
              options={VENDOR_TYPE}
              value={fm.identity.vendor_type}
              onChange={(v) => patchFm({ identity: { ...fm.identity, vendor_type: v } })}
            />
            {/* <div className="mb-3">
              <label className="form-label fw-semibold">Brand name</label>
              <Form.Control
                type="text"
                className="fs-14"
                value={fm.identity.brand_name}
                onChange={(e) => patchFm({ identity: { ...fm.identity, brand_name: e.target.value } })}
              />
            </div> */}
            <MultiCheck
              label="Service presence"
              options={SERVICE_PRESENCE}
              value={fm.identity.service_presence}
              onChange={(v) => patchFm({ identity: { ...fm.identity, service_presence: v } })}
            />
            <div className="mb-3">
              <label className="form-label fw-semibold">City</label>
              <Form.Control
                type="text"
                className="fs-14"
                value={fm.identity.city}
                onChange={(e) => patchFm({ identity: { ...fm.identity, city: e.target.value } })}
              />
            </div>
            <MultiCheck
              label="Store presence"
              options={STORE_PRESENCE}
              value={fm.identity.store_presence}
              onChange={(v) => patchFm({ identity: { ...fm.identity, store_presence: v } })}
            />
            <SelectField
              label="Years of experience"
              options={YEARS_OF_EXPERIENCE}
              value={fm.identity.years_of_experience}
              onChange={(v) => patchFm({ identity: { ...fm.identity, years_of_experience: v } })}
            />
            <MultiCheck
              label="Specialization"
              options={SPECIALIZATION}
              value={fm.identity.specialization}
              onChange={(v) => patchFm({ identity: { ...fm.identity, specialization: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 2 — Services Offered */}
        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Services offered</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Service types"
              options={SERVICE_TYPES}
              value={fm.services_offered.service_types}
              onChange={(v) => patchFm({ services_offered: { ...fm.services_offered, service_types: v } })}
            />
            <YesNoField
              groupName="customizationAvailable"
              label="Customization available"
              value={fm.services_offered.customization_available}
              onChange={(v) => patchFm({ services_offered: { ...fm.services_offered, customization_available: v } })}
            />
            <YesNoField
              groupName="sameDayDelivery"
              label="Same-day delivery"
              value={fm.services_offered.same_day_delivery}
              onChange={(v) => patchFm({ services_offered: { ...fm.services_offered, same_day_delivery: v } })}
            />
            <YesNoField
              groupName="subscriptionServices"
              label="Subscription services (daily/weekly)"
              value={fm.services_offered.subscription_services}
              onChange={(v) => patchFm({ services_offered: { ...fm.services_offered, subscription_services: v } })}
            />
            <YesNoField
              groupName="bulkOrderHandling"
              label="Bulk order handling"
              value={fm.services_offered.bulk_order_handling}
              onChange={(v) => patchFm({ services_offered: { ...fm.services_offered, bulk_order_handling: v } })}
            />
            <YesNoField
              groupName="eventSetupSupport"
              label="Event setup support"
              value={fm.services_offered.event_setup_support}
              onChange={(v) => patchFm({ services_offered: { ...fm.services_offered, event_setup_support: v } })}
            />
            <MultiCheck
              label="Packaging options"
              options={PACKAGING_OPTIONS}
              value={fm.services_offered.packaging_options}
              onChange={(v) => patchFm({ services_offered: { ...fm.services_offered, packaging_options: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 3 — Core Intelligence */}
        <Accordion.Item eventKey="2">
          <Accordion.Header>Section 3 — Core intelligence</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Flower types available"
              options={FLOWER_TYPES}
              value={fm.core_intelligence.flower_types_available}
              onChange={(v) => patchFm({ core_intelligence: { ...fm.core_intelligence, flower_types_available: v } })}
            />
            <MultiCheck
              label="Usage types"
              options={USAGE_TYPES}
              value={fm.core_intelligence.usage_types}
              onChange={(v) => patchFm({ core_intelligence: { ...fm.core_intelligence, usage_types: v } })}
            />
            <SelectField
              label="Fragrance level"
              options={FRAGRANCE_LEVEL}
              value={fm.core_intelligence.fragrance_level}
              onChange={(v) => patchFm({ core_intelligence: { ...fm.core_intelligence, fragrance_level: v } })}
            />
            <SelectField
              label="Longevity type"
              options={LONGEVITY_TYPE}
              value={fm.core_intelligence.longevity_type}
              onChange={(v) => patchFm({ core_intelligence: { ...fm.core_intelligence, longevity_type: v } })}
            />
            <MultiCheck
              label="Color palette"
              options={COLOR_PALETTE}
              value={fm.core_intelligence.color_palette}
              onChange={(v) => patchFm({ core_intelligence: { ...fm.core_intelligence, color_palette: v } })}
            />
            <SelectField
              label="Seasonal availability"
              options={SEASONAL_AVAILABILITY}
              value={fm.core_intelligence.seasonal_availability}
              onChange={(v) => patchFm({ core_intelligence: { ...fm.core_intelligence, seasonal_availability: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 4 — Technical / Product / Skill */}
        <Accordion.Item eventKey="3">
          <Accordion.Header>Section 4 — Technical / product / skill</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Storage facility"
              options={STORAGE_FACILITY}
              value={fm.technical.storage_facility}
              onChange={(v) => patchFm({ technical: { ...fm.technical, storage_facility: v } })}
            />
            <YesNoField
              groupName="flowerFreshnessGuarantee"
              label="Flower freshness guarantee"
              value={fm.technical.flower_freshness_guarantee}
              onChange={(v) => patchFm({ technical: { ...fm.technical, flower_freshness_guarantee: v } })}
            />
            <MultiCheck
              label="Sourcing type"
              options={SOURCING_TYPE}
              value={fm.technical.sourcing_type}
              onChange={(v) => patchFm({ technical: { ...fm.technical, sourcing_type: v } })}
            />
            <MultiCheck
              label="Arrangement types"
              options={ARRANGEMENT_TYPES}
              value={fm.technical.arrangement_types}
              onChange={(v) => patchFm({ technical: { ...fm.technical, arrangement_types: v } })}
            />
            <YesNoField
              groupName="ecoFriendlyOptions"
              label="Eco-friendly options"
              value={fm.technical.eco_friendly_options}
              onChange={(v) => patchFm({ technical: { ...fm.technical, eco_friendly_options: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 5 — Pricing */}
        <Accordion.Item eventKey="4">
          <Accordion.Header>Section 5 — Pricing logic</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Price range (INR)"
              options={PRICE_RANGE}
              value={fm.pricing.price_range}
              onChange={(v) => patchFm({ pricing: { ...fm.pricing, price_range: v } })}
            />
            <SelectField
              label="Pricing model"
              options={PRICING_MODEL}
              value={fm.pricing.pricing_model}
              onChange={(v) => patchFm({ pricing: { ...fm.pricing, pricing_model: v } })}
            />
            <SelectField
              label="Delivery charges"
              options={DELIVERY_CHARGES}
              value={fm.pricing.delivery_charges}
              onChange={(v) => patchFm({ pricing: { ...fm.pricing, delivery_charges: v } })}
            />
            <SelectField
              label="Setup charges (event)"
              options={SETUP_CHARGES}
              value={fm.pricing.setup_charges}
              onChange={(v) => patchFm({ pricing: { ...fm.pricing, setup_charges: v } })}
            />
            <YesNoField
              groupName="bulkDiscounts"
              label="Bulk discounts"
              value={fm.pricing.bulk_discounts}
              onChange={(v) => patchFm({ pricing: { ...fm.pricing, bulk_discounts: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 6 — Scale & Capacity */}
        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Scale &amp; capacity</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Daily order capacity"
              options={DAILY_ORDER_CAPACITY}
              value={fm.scale_capacity.daily_order_capacity}
              onChange={(v) => patchFm({ scale_capacity: { ...fm.scale_capacity, daily_order_capacity: v } })}
            />
            <SelectField
              label="Event handling capacity"
              options={EVENT_HANDLING_CAPACITY}
              value={fm.scale_capacity.event_handling_capacity}
              onChange={(v) => patchFm({ scale_capacity: { ...fm.scale_capacity, event_handling_capacity: v } })}
            />
            <SelectField
              label="Team size"
              options={TEAM_SIZE}
              value={fm.scale_capacity.team_size}
              onChange={(v) => patchFm({ scale_capacity: { ...fm.scale_capacity, team_size: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 7 — Workflow & Booking */}
        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Workflow &amp; booking</Accordion.Header>
          <Accordion.Body>
            <YesNoField
              groupName="advanceBookingRequired"
              label="Advance booking required"
              value={fm.workflow.advance_booking_required}
              onChange={(v) => patchFm({ workflow: { ...fm.workflow, advance_booking_required: v } })}
            />
            <SelectField
              label="Booking window"
              options={BOOKING_WINDOW}
              value={fm.workflow.booking_window}
              onChange={(v) => patchFm({ workflow: { ...fm.workflow, booking_window: v } })}
            />
            <SelectField
              label="Customization approval process"
              options={CUSTOMIZATION_APPROVAL}
              value={fm.workflow.customization_approval_process}
              onChange={(v) => patchFm({ workflow: { ...fm.workflow, customization_approval_process: v } })}
            />
            <SelectField
              label="Delivery time slots"
              options={DELIVERY_TIME_SLOTS}
              value={fm.workflow.delivery_time_slots}
              onChange={(v) => patchFm({ workflow: { ...fm.workflow, delivery_time_slots: v } })}
            />
            <MultiCheck
              label="Payment modes"
              options={PAYMENT_MODES}
              value={fm.workflow.payment_modes}
              onChange={(v) => patchFm({ workflow: { ...fm.workflow, payment_modes: v } })}
            />
            <SelectField
              label="Advance payment percentage"
              options={ADVANCE_PAYMENT_PERCENTAGE}
              value={fm.workflow.advance_payment_percentage}
              onChange={(v) => patchFm({ workflow: { ...fm.workflow, advance_payment_percentage: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 8 — Portfolio Tagging */}
        <Accordion.Item eventKey="7">
          <Accordion.Header>Section 8 — Portfolio tagging (AI layer)</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Style tags"
              options={STYLE_TAGS}
              value={fm.portfolio_tagging.style_tags}
              onChange={(v) => patchFm({ portfolio_tagging: { ...fm.portfolio_tagging, style_tags: v } })}
            />
            <MultiCheck
              label="Audience tags"
              options={AUDIENCE_TAGS}
              value={fm.portfolio_tagging.audience_tags}
              onChange={(v) => patchFm({ portfolio_tagging: { ...fm.portfolio_tagging, audience_tags: v } })}
            />
            <MultiCheck
              label="Usage tags"
              options={USAGE_TAGS}
              value={fm.portfolio_tagging.usage_tags}
              onChange={(v) => patchFm({ portfolio_tagging: { ...fm.portfolio_tagging, usage_tags: v } })}
            />
            <SelectField
              label="Price segment tags"
              options={PRICE_SEGMENT_TAGS}
              value={fm.portfolio_tagging.price_segment_tags}
              onChange={(v) => patchFm({ portfolio_tagging: { ...fm.portfolio_tagging, price_segment_tags: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

      </Accordion>

      {!embedded && (
        <button type="button" className="btn btn-primary mt-3 fs-14" onClick={save}>
          Save florist master profile
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

export default FloristMasterProfile;
