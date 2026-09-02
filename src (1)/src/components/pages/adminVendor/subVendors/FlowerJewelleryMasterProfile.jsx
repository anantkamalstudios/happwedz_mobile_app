import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  VENDOR_TYPE,
  SERVICE_COVERAGE,
  DELIVERY_MODE,
  JEWELLERY_ITEMS_OFFERED,
  YES_NO,
  FLOWER_TYPE,
  FRESH_FLOWER_TYPES,
  ARTIFICIAL_MATERIAL,
  DURABILITY,
  STYLE_CATEGORIES,
  BEST_KNOWN_FOR,
  SUITABLE_FOR,
  CUSTOM_DESIGN_INPUTS,
  FUNCTIONS_SUITABLE_FOR,
  BEST_FUNCTION,
  STORAGE_FACILITIES,
  CUSTOMIZATION_CAPABILITIES,
  DELIVERY_FEATURES,
  PRICING_TYPE,
  BRIDAL_SET_PRICE_RANGE,
  BULK_PRICING,
  ORDER_PREP_TIME,
  DELIVERY_TIMING,
  DAILY_ORDER_CAPACITY,
  PEAK_SEASON_AVAILABILITY,
  ADVANCE_PERCENTAGE,
  CANCELLATION_POLICY,
  REFUND_TIMELINE,
  DAMAGE_HANDLING,
  AI_FAQ_FLOWER_TYPE,
  AI_FAQ_CUSTOMIZATION,
  AI_FAQ_SUITABLE_FUNCTION,
  AI_FAQ_DELIVERY_AVAILABLE,
  AI_FAQ_SAME_DAY_DELIVERY,
  AI_FAQ_DURABILITY,
  AI_FAQ_BULK_ORDERS,
  AI_FAQ_OUTFIT_MATCHING,
  AI_FAQ_PREPARATION_TIME,
  AI_FAQ_REPLACEMENT_POLICY,
  AI_FAQ_ADVANCE_REQUIRED,
  AI_FAQ_CANCELLATION,
  AI_FAQ_PRICE_RANGE,
  AI_FAQ_BEST_KNOWN_FOR,
  emptyFlowerJewelleryMaster,
} from "./flowerJewelleryMasterConstants";

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

function FlowerJewelleryMasterProfile({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) {
  const fjm = useMemo(() => {
    const raw =
      formData.flower_jewellery_master || formData.attributes?.flower_jewellery_master;
    if (raw && typeof raw === "object")
      return mergeDeep(emptyFlowerJewelleryMaster(), raw);
    return emptyFlowerJewelleryMaster();
  }, [
    formData.flower_jewellery_master,
    formData.attributes?.flower_jewellery_master,
  ]);

  const patchFjm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(
          prev.flower_jewellery_master ||
            prev.attributes?.flower_jewellery_master ||
            emptyFlowerJewelleryMaster(),
          partial
        );
        return {
          ...prev,
          flower_jewellery_master: next,
          attributes: {
            ...(prev.attributes || {}),
            flower_jewellery_master: next,
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
      <h4 className="mb-2 fw-bold">Flower Jewellery vendor master profile</h4>
      <p className="text-muted fs-14 mb-4">
        Structured flower jewellery rental data for search, filters, portfolio tagging, and AI FAQ matching.
      </p>
      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        {/* SECTION 1: BASIC IDENTITY */}
        <Accordion.Item eventKey="0">
          <Accordion.Header>Basic Identity</Accordion.Header>
          <Accordion.Body>
            <TextField
              label="Brand / Vendor Name"
              value={fjm.identity.brand_name}
              onChange={(v) =>
                patchFjm({ identity: { ...fjm.identity, brand_name: v } })
              }
            />
            <SelectField
              label="Vendor Type"
              options={VENDOR_TYPE}
              value={fjm.identity.vendor_type}
              onChange={(v) =>
                patchFjm({ identity: { ...fjm.identity, vendor_type: v } })
              }
            />
            <TextField
              label="Years of Experience"
              type="number"
              value={fjm.identity.years_of_experience}
              onChange={(v) =>
                patchFjm({
                  identity: { ...fjm.identity, years_of_experience: v },
                })
              }
            />
            <TextField
              label="City"
              value={fjm.identity.city}
              onChange={(v) =>
                patchFjm({ identity: { ...fjm.identity, city: v } })
              }
            />
            <SelectField
              label="Service Coverage"
              options={SERVICE_COVERAGE}
              value={fjm.identity.service_coverage}
              onChange={(v) =>
                patchFjm({
                  identity: { ...fjm.identity, service_coverage: v },
                })
              }
            />
            <SelectField
              label="Delivery Mode"
              options={DELIVERY_MODE}
              value={fjm.identity.delivery_mode}
              onChange={(v) =>
                patchFjm({ identity: { ...fjm.identity, delivery_mode: v } })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 2: PRODUCT CATEGORIES */}
        <Accordion.Item eventKey="1">
          <Accordion.Header>Product Categories</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Jewellery Items Offered"
              options={JEWELLERY_ITEMS_OFFERED}
              value={fjm.product_categories.jewellery_items}
              onChange={(v) =>
                patchFjm({
                  product_categories: {
                    ...fjm.product_categories,
                    jewellery_items: v,
                  },
                })
              }
            />
            <SelectField
              label="Bridal Flower Jewellery Set"
              options={YES_NO}
              value={fjm.product_categories.bridal_set_available}
              onChange={(v) =>
                patchFjm({
                  product_categories: {
                    ...fjm.product_categories,
                    bridal_set_available: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 3: MATERIAL & TYPE */}
        <Accordion.Item eventKey="2">
          <Accordion.Header>Material & Type</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Flower Type"
              options={FLOWER_TYPE}
              value={fjm.material_type.flower_type}
              onChange={(v) =>
                patchFjm({
                  material_type: { ...fjm.material_type, flower_type: v },
                })
              }
            />
            <MultiCheck
              label="Fresh Flower Types"
              options={FRESH_FLOWER_TYPES}
              value={fjm.material_type.fresh_flower_types}
              onChange={(v) =>
                patchFjm({
                  material_type: {
                    ...fjm.material_type,
                    fresh_flower_types: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Artificial Material"
              options={ARTIFICIAL_MATERIAL}
              value={fjm.material_type.artificial_material}
              onChange={(v) =>
                patchFjm({
                  material_type: {
                    ...fjm.material_type,
                    artificial_material: v,
                  },
                })
              }
            />
            <SelectField
              label="Durability"
              options={DURABILITY}
              value={fjm.material_type.durability}
              onChange={(v) =>
                patchFjm({
                  material_type: { ...fjm.material_type, durability: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 4: STYLE & DESIGN INTELLIGENCE */}
        <Accordion.Item eventKey="3">
          <Accordion.Header>Style & Design Intelligence</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Style Categories"
              options={STYLE_CATEGORIES}
              value={fjm.style_design.style_categories}
              onChange={(v) =>
                patchFjm({
                  style_design: {
                    ...fjm.style_design,
                    style_categories: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Best Known For"
              options={BEST_KNOWN_FOR}
              value={fjm.style_design.best_known_for}
              onChange={(v) =>
                patchFjm({
                  style_design: {
                    ...fjm.style_design,
                    best_known_for: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Suitable For"
              options={SUITABLE_FOR}
              value={fjm.style_design.suitable_for}
              onChange={(v) =>
                patchFjm({
                  style_design: {
                    ...fjm.style_design,
                    suitable_for: v,
                  },
                })
              }
            />
            <SelectField
              label="Outfit Matching Support"
              options={YES_NO}
              value={fjm.style_design.outfit_matching_support}
              onChange={(v) =>
                patchFjm({
                  style_design: {
                    ...fjm.style_design,
                    outfit_matching_support: v,
                  },
                })
              }
            />
            <SelectField
              label="Customization Available"
              options={YES_NO}
              value={fjm.style_design.customization_available}
              onChange={(v) =>
                patchFjm({
                  style_design: {
                    ...fjm.style_design,
                    customization_available: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Custom Design Inputs"
              options={CUSTOM_DESIGN_INPUTS}
              value={fjm.style_design.custom_design_inputs}
              onChange={(v) =>
                patchFjm({
                  style_design: {
                    ...fjm.style_design,
                    custom_design_inputs: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 5: FUNCTION-SPECIFIC INTELLIGENCE */}
        <Accordion.Item eventKey="4">
          <Accordion.Header>Function-Specific Intelligence</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Functions Suitable For"
              options={FUNCTIONS_SUITABLE_FOR}
              value={fjm.function_specific.functions_suitable_for}
              onChange={(v) =>
                patchFjm({
                  function_specific: {
                    ...fjm.function_specific,
                    functions_suitable_for: v,
                  },
                })
              }
            />
            <SelectField
              label="Best Function"
              options={BEST_FUNCTION}
              value={fjm.function_specific.best_function}
              onChange={(v) =>
                patchFjm({
                  function_specific: {
                    ...fjm.function_specific,
                    best_function: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 5: FACILITIES & FEATURES */}
        <Accordion.Item eventKey="5">
          <Accordion.Header>Facilities & Features</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Storage Facilities"
              options={STORAGE_FACILITIES}
              value={fjm.facilities.storage_facilities}
              onChange={(v) =>
                patchFjm({
                  facilities: { ...fjm.facilities, storage_facilities: v },
                })
              }
            />
            <MultiCheck
              label="Customization Capabilities"
              options={CUSTOMIZATION_CAPABILITIES}
              value={fjm.facilities.customization_capabilities}
              onChange={(v) =>
                patchFjm({
                  facilities: {
                    ...fjm.facilities,
                    customization_capabilities: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Delivery Features"
              options={DELIVERY_FEATURES}
              value={fjm.facilities.delivery_features}
              onChange={(v) =>
                patchFjm({
                  facilities: { ...fjm.facilities, delivery_features: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 7: PRICING & PACKAGE LOGIC */}
        <Accordion.Item eventKey="7">
          <Accordion.Header>Pricing & Package Logic</Accordion.Header>
          <Accordion.Body>
            <TextField
              label="Starting Price"
              type="number"
              value={fjm.pricing_logic.starting_price}
              onChange={(v) =>
                patchFjm({
                  pricing_logic: { ...fjm.pricing_logic, starting_price: v },
                })
              }
            />
            <SelectField
              label="Pricing Type"
              options={PRICING_TYPE}
              value={fjm.pricing_logic.pricing_type}
              onChange={(v) =>
                patchFjm({
                  pricing_logic: { ...fjm.pricing_logic, pricing_type: v },
                })
              }
            />
            <SelectField
              label="Bridal Set Price Range"
              options={BRIDAL_SET_PRICE_RANGE}
              value={fjm.pricing_logic.bridal_set_price_range}
              onChange={(v) =>
                patchFjm({
                  pricing_logic: {
                    ...fjm.pricing_logic,
                    bridal_set_price_range: v,
                  },
                })
              }
            />
            <SelectField
              label="Bulk Orders Supported"
              options={YES_NO}
              value={fjm.pricing_logic.bulk_orders_supported}
              onChange={(v) =>
                patchFjm({
                  pricing_logic: {
                    ...fjm.pricing_logic,
                    bulk_orders_supported: v,
                  },
                })
              }
            />
            <SelectField
              label="Bulk Pricing"
              options={BULK_PRICING}
              value={fjm.pricing_logic.bulk_pricing}
              onChange={(v) =>
                patchFjm({
                  pricing_logic: { ...fjm.pricing_logic, bulk_pricing: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 8: DELIVERY & TIMING */}
        <Accordion.Item eventKey="8">
          <Accordion.Header>Delivery & Timing</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Order Preparation Time"
              options={ORDER_PREP_TIME}
              value={fjm.delivery_timing.order_prep_time}
              onChange={(v) =>
                patchFjm({
                  delivery_timing: {
                    ...fjm.delivery_timing,
                    order_prep_time: v,
                  },
                })
              }
            />
            <SelectField
              label="Delivery Timing"
              options={DELIVERY_TIMING}
              value={fjm.delivery_timing.delivery_timing}
              onChange={(v) =>
                patchFjm({
                  delivery_timing: { ...fjm.delivery_timing, delivery_timing: v },
                })
              }
            />
            <SelectField
              label="Time Slot Delivery"
              options={YES_NO}
              value={fjm.delivery_timing.time_slot_delivery}
              onChange={(v) =>
                patchFjm({
                  delivery_timing: {
                    ...fjm.delivery_timing,
                    time_slot_delivery: v,
                  },
                })
              }
            />
            <SelectField
              label="Early Morning Delivery"
              options={YES_NO}
              value={fjm.delivery_timing.early_morning_delivery}
              onChange={(v) =>
                patchFjm({
                  delivery_timing: {
                    ...fjm.delivery_timing,
                    early_morning_delivery: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 9: STORAGE & HANDLING */}
        <Accordion.Item eventKey="9">
          <Accordion.Header>Storage & Handling</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Storage Instructions Provided"
              options={YES_NO}
              value={fjm.storage_handling.storage_instructions}
              onChange={(v) =>
                patchFjm({
                  storage_handling: {
                    ...fjm.storage_handling,
                    storage_instructions: v,
                  },
                })
              }
            />
            <SelectField
              label="Replacement Policy"
              options={YES_NO}
              value={fjm.storage_handling.replacement_policy}
              onChange={(v) =>
                patchFjm({
                  storage_handling: {
                    ...fjm.storage_handling,
                    replacement_policy: v,
                  },
                })
              }
            />
            <SelectField
              label="Damage Handling"
              options={DAMAGE_HANDLING}
              value={fjm.storage_handling.damage_handling}
              onChange={(v) =>
                patchFjm({
                  storage_handling: {
                    ...fjm.storage_handling,
                    damage_handling: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 10: INVENTORY & AVAILABILITY */}
        <Accordion.Item eventKey="10">
          <Accordion.Header>Inventory & Availability</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Daily Order Capacity"
              options={DAILY_ORDER_CAPACITY}
              value={fjm.inventory_availability.daily_order_capacity}
              onChange={(v) =>
                patchFjm({
                  inventory_availability: {
                    ...fjm.inventory_availability,
                    daily_order_capacity: v,
                  },
                })
              }
            />
            <SelectField
              label="Advance Booking Required"
              options={YES_NO}
              value={fjm.inventory_availability.advance_booking_required}
              onChange={(v) =>
                patchFjm({
                  inventory_availability: {
                    ...fjm.inventory_availability,
                    advance_booking_required: v,
                  },
                })
              }
            />
            <SelectField
              label="Peak Season Availability"
              options={PEAK_SEASON_AVAILABILITY}
              value={fjm.inventory_availability.peak_season_availability}
              onChange={(v) =>
                patchFjm({
                  inventory_availability: {
                    ...fjm.inventory_availability,
                    peak_season_availability: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 11: WORKFLOW & BOOKING */}
        <Accordion.Item eventKey="11">
          <Accordion.Header>Workflow & Booking</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Advance Required"
              options={YES_NO}
              value={fjm.workflow_booking.advance_required}
              onChange={(v) =>
                patchFjm({
                  workflow_booking: {
                    ...fjm.workflow_booking,
                    advance_required: v,
                  },
                })
              }
            />
            <SelectField
              label="Advance Percentage"
              options={ADVANCE_PERCENTAGE}
              value={fjm.workflow_booking.advance_percentage}
              onChange={(v) =>
                patchFjm({
                  workflow_booking: {
                    ...fjm.workflow_booking,
                    advance_percentage: v,
                  },
                })
              }
            />
            <SelectField
              label="Cancellation Policy"
              options={CANCELLATION_POLICY}
              value={fjm.workflow_booking.cancellation_policy}
              onChange={(v) =>
                patchFjm({
                  workflow_booking: {
                    ...fjm.workflow_booking,
                    cancellation_policy: v,
                  },
                })
              }
            />
            <SelectField
              label="Refund Timeline"
              options={REFUND_TIMELINE}
              value={fjm.workflow_booking.refund_timeline}
              onChange={(v) =>
                patchFjm({
                  workflow_booking: {
                    ...fjm.workflow_booking,
                    refund_timeline: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

      </Accordion>

      {!embedded && (
        <button type="button" className="btn btn-primary mt-3 fs-14" onClick={save}>
          Save flower jewellery master profile
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

export default FlowerJewelleryMasterProfile;
