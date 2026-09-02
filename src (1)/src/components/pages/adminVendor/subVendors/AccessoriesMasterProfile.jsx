import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  VENDOR_TYPE,
  SERVICE_MODE,
  DELIVERY_COVERAGE,
  ACCESSORIES_TYPES,
  GENDER_FOCUS,
  YES_NO,
  STYLE_CATEGORIES,
  BEST_KNOWN_FOR,
  SUITABLE_FOR,
  MATERIALS_USED,
  QUALITY_TIER,
  PRODUCT_MODE,
  RENTAL_DURATION,
  PRICE_RANGE,
  CUSTOMIZATION_TIME,
  INVENTORY_SIZE,
  SHIPPING_CHARGES,
  FUNCTIONS_SUITABLE_FOR,
  BEST_FOR,
  ADVANCE_PERCENTAGE,
  CANCELLATION_POLICY,
  RETURN_POLICY,
  AI_FAQ_PRODUCT_MODE,
  AI_FAQ_PRICE_RANGE,
  AI_FAQ_CUSTOMIZATION,
  AI_FAQ_RENTAL_DURATION,
  AI_FAQ_INVENTORY_SIZE,
  AI_FAQ_CANCELLATION,
  AI_FAQ_RETURN_POLICY,
  emptyAccessoriesMaster,
} from "./accessoriesMasterConstants";

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
          />
        ))}
      </div>
    </div>
  );
};

const TextField = ({ label, value, onChange, type = "text" }) => (
  <div className="mb-3">
    <label className="form-label fw-semibold">{label}</label>
    <Form.Control
      type={type}
      value={value || ""}
      onChange={(e) => onChange(e.target.value)}
      className="fs-14"
    />
  </div>
);

function AccessoriesMasterProfile({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) {
  const am = useMemo(() => {
    const raw = formData.accessories_master || formData.attributes?.accessories_master;
    if (raw && typeof raw === "object")
      return mergeDeep(emptyAccessoriesMaster(), raw);
    return emptyAccessoriesMaster();
  }, [formData.accessories_master, formData.attributes?.accessories_master]);

  const patchAm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(
          prev.accessories_master ||
            prev.attributes?.accessories_master ||
            emptyAccessoriesMaster(),
          partial
        );
        return {
          ...prev,
          accessories_master: next,
          attributes: { ...(prev.attributes || {}), accessories_master: next },
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
      <h4 className="mb-2 fw-bold">Accessories vendor master profile</h4>
      <p className="text-muted fs-14 mb-4">
        Structured accessories data for search, filters, portfolio tagging, and AI FAQ matching.
      </p>
      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        {/* SECTION 1: BASIC IDENTITY */}
        <Accordion.Item eventKey="0">
          <Accordion.Header>Basic Identity</Accordion.Header>
          <Accordion.Body>
            <TextField
              label="Brand Name"
              value={am.identity.brand_name}
              onChange={(v) =>
                patchAm({ identity: { ...am.identity, brand_name: v } })
              }
            />
            <SelectField
              label="Vendor Type"
              options={VENDOR_TYPE}
              value={am.identity.vendor_type}
              onChange={(v) =>
                patchAm({ identity: { ...am.identity, vendor_type: v } })
              }
            />
            <TextField
              label="Years of Experience"
              type="number"
              value={am.identity.years_of_experience}
              onChange={(v) =>
                patchAm({
                  identity: { ...am.identity, years_of_experience: v },
                })
              }
            />
            <TextField
              label="City"
              value={am.identity.city}
              onChange={(v) =>
                patchAm({ identity: { ...am.identity, city: v } })
              }
            />
            <SelectField
              label="Service Mode"
              options={SERVICE_MODE}
              value={am.identity.service_mode}
              onChange={(v) =>
                patchAm({ identity: { ...am.identity, service_mode: v } })
              }
            />
            <SelectField
              label="Delivery Coverage"
              options={DELIVERY_COVERAGE}
              value={am.identity.delivery_coverage}
              onChange={(v) =>
                patchAm({
                  identity: { ...am.identity, delivery_coverage: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 2: PRODUCT CATEGORIES */}
        <Accordion.Item eventKey="1">
          <Accordion.Header>Product Categories</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Accessories Types"
              options={ACCESSORIES_TYPES}
              value={am.product_categories.accessories_types}
              onChange={(v) =>
                patchAm({
                  product_categories: {
                    ...am.product_categories,
                    accessories_types: v,
                  },
                })
              }
            />
            <SelectField
              label="Gender Focus"
              options={GENDER_FOCUS}
              value={am.product_categories.gender_focus}
              onChange={(v) =>
                patchAm({
                  product_categories: {
                    ...am.product_categories,
                    gender_focus: v,
                  },
                })
              }
            />
            <SelectField
              label="Bridal Accessories Available"
              options={YES_NO}
              value={am.product_categories.bridal_accessories}
              onChange={(v) =>
                patchAm({
                  product_categories: {
                    ...am.product_categories,
                    bridal_accessories: v,
                  },
                })
              }
            />
            <SelectField
              label="Groom Accessories Available"
              options={YES_NO}
              value={am.product_categories.groom_accessories}
              onChange={(v) =>
                patchAm({
                  product_categories: {
                    ...am.product_categories,
                    groom_accessories: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 3: STYLE & DESIGN INTELLIGENCE */}
        <Accordion.Item eventKey="2">
          <Accordion.Header>Style & Design Intelligence</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Style Categories"
              options={STYLE_CATEGORIES}
              value={am.style_intelligence.style_categories}
              onChange={(v) =>
                patchAm({
                  style_intelligence: {
                    ...am.style_intelligence,
                    style_categories: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Best Known For"
              options={BEST_KNOWN_FOR}
              value={am.style_intelligence.best_known_for}
              onChange={(v) =>
                patchAm({
                  style_intelligence: {
                    ...am.style_intelligence,
                    best_known_for: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Suitable For"
              options={SUITABLE_FOR}
              value={am.style_intelligence.suitable_for}
              onChange={(v) =>
                patchAm({
                  style_intelligence: {
                    ...am.style_intelligence,
                    suitable_for: v,
                  },
                })
              }
            />
            <SelectField
              label="Outfit Matching Support"
              options={YES_NO}
              value={am.style_intelligence.outfit_matching}
              onChange={(v) =>
                patchAm({
                  style_intelligence: {
                    ...am.style_intelligence,
                    outfit_matching: v,
                  },
                })
              }
            />
            <SelectField
              label="Styling Consultation"
              options={YES_NO}
              value={am.style_intelligence.styling_consultation}
              onChange={(v) =>
                patchAm({
                  style_intelligence: {
                    ...am.style_intelligence,
                    styling_consultation: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 4: MATERIAL & QUALITY */}
        <Accordion.Item eventKey="3">
          <Accordion.Header>Material & Quality</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Materials Used"
              options={MATERIALS_USED}
              value={am.material_quality.materials_used}
              onChange={(v) =>
                patchAm({
                  material_quality: { ...am.material_quality, materials_used: v },
                })
              }
            />
            <SelectField
              label="Quality Tier"
              options={QUALITY_TIER}
              value={am.material_quality.quality_tier}
              onChange={(v) =>
                patchAm({
                  material_quality: { ...am.material_quality, quality_tier: v },
                })
              }
            />
            <SelectField
              label="Handmade Products"
              options={YES_NO}
              value={am.material_quality.handmade_products}
              onChange={(v) =>
                patchAm({
                  material_quality: {
                    ...am.material_quality,
                    handmade_products: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 5: SALES & RENTAL LOGIC */}
        <Accordion.Item eventKey="4">
          <Accordion.Header>Sales & Rental Logic</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Product Mode"
              options={PRODUCT_MODE}
              value={am.sales_rental_logic.product_mode}
              onChange={(v) =>
                patchAm({
                  sales_rental_logic: {
                    ...am.sales_rental_logic,
                    product_mode: v,
                  },
                })
              }
            />
            <SelectField
              label="Rental Duration"
              options={RENTAL_DURATION}
              value={am.sales_rental_logic.rental_duration}
              onChange={(v) =>
                patchAm({
                  sales_rental_logic: {
                    ...am.sales_rental_logic,
                    rental_duration: v,
                  },
                })
              }
            />
            <SelectField
              label="Price Range"
              options={PRICE_RANGE}
              value={am.sales_rental_logic.price_range}
              onChange={(v) =>
                patchAm({
                  sales_rental_logic: {
                    ...am.sales_rental_logic,
                    price_range: v,
                  },
                })
              }
            />
            <SelectField
              label="Security Deposit"
              options={YES_NO}
              value={am.sales_rental_logic.security_deposit}
              onChange={(v) =>
                patchAm({
                  sales_rental_logic: {
                    ...am.sales_rental_logic,
                    security_deposit: v,
                  },
                })
              }
            />
            <SelectField
              label="Custom Orders"
              options={YES_NO}
              value={am.sales_rental_logic.custom_orders}
              onChange={(v) =>
                patchAm({
                  sales_rental_logic: {
                    ...am.sales_rental_logic,
                    custom_orders: v,
                  },
                })
              }
            />
            <SelectField
              label="Customization Time"
              options={CUSTOMIZATION_TIME}
              value={am.sales_rental_logic.customization_time}
              onChange={(v) =>
                patchAm({
                  sales_rental_logic: {
                    ...am.sales_rental_logic,
                    customization_time: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 6: INVENTORY & AVAILABILITY */}
        <Accordion.Item eventKey="5">
          <Accordion.Header>Inventory & Availability</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Inventory Size"
              options={INVENTORY_SIZE}
              value={am.inventory.inventory_size}
              onChange={(v) =>
                patchAm({
                  inventory: { ...am.inventory, inventory_size: v },
                })
              }
            />
            <SelectField
              label="Multiple Pieces Available"
              options={YES_NO}
              value={am.inventory.multiple_pieces}
              onChange={(v) =>
                patchAm({
                  inventory: { ...am.inventory, multiple_pieces: v },
                })
              }
            />
            <SelectField
              label="Real-Time Availability Tracking"
              options={YES_NO}
              value={am.inventory.real_time_tracking}
              onChange={(v) =>
                patchAm({
                  inventory: { ...am.inventory, real_time_tracking: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 7: DELIVERY & LOGISTICS */}
        <Accordion.Item eventKey="6">
          <Accordion.Header>Delivery & Logistics</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Home Delivery"
              options={YES_NO}
              value={am.logistics.home_delivery}
              onChange={(v) =>
                patchAm({
                  logistics: { ...am.logistics, home_delivery: v },
                })
              }
            />
            <SelectField
              label="Store Pickup"
              options={YES_NO}
              value={am.logistics.store_pickup}
              onChange={(v) =>
                patchAm({
                  logistics: { ...am.logistics, store_pickup: v },
                })
              }
            />
            <SelectField
              label="Shipping Charges"
              options={SHIPPING_CHARGES}
              value={am.logistics.shipping_charges}
              onChange={(v) =>
                patchAm({
                  logistics: { ...am.logistics, shipping_charges: v },
                })
              }
            />
            <SelectField
              label="Try-at-Home"
              options={YES_NO}
              value={am.logistics.try_at_home}
              onChange={(v) =>
                patchAm({
                  logistics: { ...am.logistics, try_at_home: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 8: EVENT SUITABILITY */}
        <Accordion.Item eventKey="7">
          <Accordion.Header>Event Suitability</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Functions Suitable For"
              options={FUNCTIONS_SUITABLE_FOR}
              value={am.event_suitability.functions_suitable_for}
              onChange={(v) =>
                patchAm({
                  event_suitability: {
                    ...am.event_suitability,
                    functions_suitable_for: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Best For"
              options={BEST_FOR}
              value={am.event_suitability.best_for}
              onChange={(v) =>
                patchAm({
                  event_suitability: { ...am.event_suitability, best_for: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 9: WORKFLOW & BOOKING */}
        <Accordion.Item eventKey="8">
          <Accordion.Header>Workflow & Booking</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Advance Required"
              options={YES_NO}
              value={am.workflow.advance_required}
              onChange={(v) =>
                patchAm({
                  workflow: { ...am.workflow, advance_required: v },
                })
              }
            />
            <SelectField
              label="Advance Percentage"
              options={ADVANCE_PERCENTAGE}
              value={am.workflow.advance_percentage}
              onChange={(v) =>
                patchAm({
                  workflow: { ...am.workflow, advance_percentage: v },
                })
              }
            />
            <SelectField
              label="Cancellation Policy"
              options={CANCELLATION_POLICY}
              value={am.workflow.cancellation_policy}
              onChange={(v) =>
                patchAm({
                  workflow: { ...am.workflow, cancellation_policy: v },
                })
              }
            />
            <SelectField
              label="Return Policy"
              options={RETURN_POLICY}
              value={am.workflow.return_policy}
              onChange={(v) =>
                patchAm({
                  workflow: { ...am.workflow, return_policy: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>
      </Accordion>

      {!embedded && (
        <button type="button" className="btn btn-primary mt-3 fs-14" onClick={save}>
          Save accessories master profile
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
}

export default AccessoriesMasterProfile;
