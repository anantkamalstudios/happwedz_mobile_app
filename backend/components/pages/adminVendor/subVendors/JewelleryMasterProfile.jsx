import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  VENDOR_TYPE,
  JEWELLERY_CITIES,
  SERVICE_MODE,
  DELIVERY_COVERAGE,
  JEWELLERY_TYPES_OFFERED,
  YES_NO,
  COMPLETE_SET_INCLUDES,
  JEWELLERY_STYLE,
  BEST_KNOWN_FOR,
  SUITABLE_FOR,
  BASE_MATERIAL,
  FINISH_QUALITY,
  REAL_VS_IMITATION,
  RENTAL_DURATION,
  RENTAL_PRICE_RANGE,
  DEPOSIT_AMOUNT_RANGE,
  INVENTORY_SIZE,
  SHIPPING_CHARGES,
  DAMAGE_POLICY,
  FUNCTIONS_SUITABLE_FOR,
  BEST_FOR,
  ADVANCE_PERCENTAGE,
  CANCELLATION_POLICY,
  REFUND_TIMELINE,
  AI_FAQ_RENTAL_DURATION,
  AI_FAQ_DEPOSIT_AMOUNT,
  AI_FAQ_INVENTORY_SIZE,
  AI_FAQ_DAMAGE_POLICY,
  AI_FAQ_CANCELLATION,
  AI_FAQ_BEST_KNOWN_FOR,
  emptyJewelleryMaster,
} from "./jewelleryMasterConstants";

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
      selected.includes(opt) ? selected.filter((x) => x !== opt) : [...selected, opt]
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

const JewelleryMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const jm = useMemo(() => {
    const raw =
      formData.jewellery_master || formData.attributes?.jewellery_master;
    if (raw && typeof raw === "object")
      return mergeDeep(emptyJewelleryMaster(), raw);
    return emptyJewelleryMaster();
  }, [formData.jewellery_master, formData.attributes?.jewellery_master]);

  const patchJm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(
          prev.jewellery_master ||
          prev.attributes?.jewellery_master ||
          emptyJewelleryMaster(),
          partial
        );
        return {
          ...prev,
          jewellery_master: next,
          attributes: { ...(prev.attributes || {}), jewellery_master: next },
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
      <h4 className="mb-2 fw-bold">Jewellery & Accessories rental master profile</h4>
      <p className="text-muted fs-14 mb-4">
        Structured jewellery rental data for search, filters, portfolio tagging, and AI
        FAQ matching.
      </p>
      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        {/* SECTION 1: BASIC IDENTITY */}
        <Accordion.Item eventKey="0">
          <Accordion.Header>Section 1 — Basic identity</Accordion.Header>
          <Accordion.Body>
            <div className="mb-3">
              <label className="form-label fw-semibold">Brand / Store name</label>
              <Form.Control
                className="fs-14"
                value={jm.identity.brand_store_name}
                onChange={(e) =>
                  patchJm({
                    identity: { ...jm.identity, brand_store_name: e.target.value },
                  })
                }
              />
            </div>
            <SelectField
              label="Vendor type"
              options={VENDOR_TYPE}
              value={jm.identity.vendor_type}
              onChange={(v) => patchJm({ identity: { ...jm.identity, vendor_type: v } })}
            />
            <div className="mb-3">
              <label className="form-label fw-semibold">Years of experience</label>
              <Form.Control
                type="number"
                className="fs-14"
                value={jm.identity.years_of_experience}
                onChange={(e) =>
                  patchJm({
                    identity: {
                      ...jm.identity,
                      years_of_experience: e.target.value,
                    },
                  })
                }
              />
            </div>
            <MultiCheck
              label="City (multi select)"
              options={JEWELLERY_CITIES}
              value={jm.identity.cities}
              onChange={(v) => patchJm({ identity: { ...jm.identity, cities: v } })}
            />
            <SelectField
              label="Service mode"
              options={SERVICE_MODE}
              value={jm.identity.service_mode}
              onChange={(v) =>
                patchJm({ identity: { ...jm.identity, service_mode: v } })
              }
            />
            <SelectField
              label="Delivery coverage"
              options={DELIVERY_COVERAGE}
              value={jm.identity.delivery_coverage}
              onChange={(v) =>
                patchJm({ identity: { ...jm.identity, delivery_coverage: v } })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 2: PRODUCT CATEGORIES */}
        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Product categories (Core inventory)</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Jewellery types offered"
              options={JEWELLERY_TYPES_OFFERED}
              value={jm.product_categories.jewellery_types_offered}
              onChange={(v) =>
                patchJm({
                  product_categories: {
                    ...jm.product_categories,
                    jewellery_types_offered: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="bridalPackage"
              label="Bridal package available"
              value={jm.product_categories.bridal_package_available}
              onChange={(v) =>
                patchJm({
                  product_categories: {
                    ...jm.product_categories,
                    bridal_package_available: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Complete set includes"
              options={COMPLETE_SET_INCLUDES}
              value={jm.product_categories.complete_set_includes}
              onChange={(v) =>
                patchJm({
                  product_categories: {
                    ...jm.product_categories,
                    complete_set_includes: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 3: STYLE & DESIGN INTELLIGENCE */}
        <Accordion.Item eventKey="2">
          <Accordion.Header>Section 3 — Style & design intelligence</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Jewellery style"
              options={JEWELLERY_STYLE}
              value={jm.style_design_intelligence.jewellery_style}
              onChange={(v) =>
                patchJm({
                  style_design_intelligence: {
                    ...jm.style_design_intelligence,
                    jewellery_style: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Best known for"
              options={BEST_KNOWN_FOR}
              value={jm.style_design_intelligence.best_known_for}
              onChange={(v) =>
                patchJm({
                  style_design_intelligence: {
                    ...jm.style_design_intelligence,
                    best_known_for: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Suitable for"
              options={SUITABLE_FOR}
              value={jm.style_design_intelligence.suitable_for}
              onChange={(v) =>
                patchJm({
                  style_design_intelligence: {
                    ...jm.style_design_intelligence,
                    suitable_for: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="outfitMatching"
              label="Outfit matching support"
              value={jm.style_design_intelligence.outfit_matching_support}
              onChange={(v) =>
                patchJm({
                  style_design_intelligence: {
                    ...jm.style_design_intelligence,
                    outfit_matching_support: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="stylingConsultation"
              label="Styling consultation"
              value={jm.style_design_intelligence.styling_consultation}
              onChange={(v) =>
                patchJm({
                  style_design_intelligence: {
                    ...jm.style_design_intelligence,
                    styling_consultation: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 4: MATERIAL & QUALITY */}
        <Accordion.Item eventKey="3">
          <Accordion.Header>Section 4 — Material & quality</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Base material"
              options={BASE_MATERIAL}
              value={jm.material_quality.base_material}
              onChange={(v) =>
                patchJm({
                  material_quality: { ...jm.material_quality, base_material: v },
                })
              }
            />
            <SelectField
              label="Finish quality"
              options={FINISH_QUALITY}
              value={jm.material_quality.finish_quality}
              onChange={(v) =>
                patchJm({
                  material_quality: { ...jm.material_quality, finish_quality: v },
                })
              }
            />
            <SelectField
              label="Real vs Imitation"
              options={REAL_VS_IMITATION}
              value={jm.material_quality.real_vs_imitation}
              onChange={(v) =>
                patchJm({
                  material_quality: {
                    ...jm.material_quality,
                    real_vs_imitation: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 5: RENTAL LOGIC */}
        <Accordion.Item eventKey="4">
          <Accordion.Header>Section 5 — Rental logic (Very important)</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Rental duration"
              options={RENTAL_DURATION}
              value={jm.rental_logic.rental_duration}
              onChange={(v) =>
                patchJm({ rental_logic: { ...jm.rental_logic, rental_duration: v } })
              }
            />
            <SelectField
              label="Rental price range"
              options={RENTAL_PRICE_RANGE}
              value={jm.rental_logic.rental_price_range}
              onChange={(v) =>
                patchJm({
                  rental_logic: { ...jm.rental_logic, rental_price_range: v },
                })
              }
            />
            <YesNoField
              groupName="securityDeposit"
              label="Security deposit"
              value={jm.rental_logic.security_deposit}
              onChange={(v) =>
                patchJm({
                  rental_logic: { ...jm.rental_logic, security_deposit: v },
                })
              }
            />
            <SelectField
              label="Deposit amount range"
              options={DEPOSIT_AMOUNT_RANGE}
              value={jm.rental_logic.deposit_amount_range}
              onChange={(v) =>
                patchJm({
                  rental_logic: { ...jm.rental_logic, deposit_amount_range: v },
                })
              }
            />
            <YesNoField
              groupName="lateReturnCharges"
              label="Late return charges"
              value={jm.rental_logic.late_return_charges}
              onChange={(v) =>
                patchJm({
                  rental_logic: { ...jm.rental_logic, late_return_charges: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 6: AVAILABILITY & INVENTORY */}
        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Availability & inventory management</Accordion.Header>
          <Accordion.Body>
            <YesNoField
              groupName="advanceBooking"
              label="Advance booking required"
              value={jm.availability_inventory.advance_booking_required}
              onChange={(v) =>
                patchJm({
                  availability_inventory: {
                    ...jm.availability_inventory,
                    advance_booking_required: v,
                  },
                })
              }
            />
            <SelectField
              label="Inventory size"
              options={INVENTORY_SIZE}
              value={jm.availability_inventory.inventory_size}
              onChange={(v) =>
                patchJm({
                  availability_inventory: {
                    ...jm.availability_inventory,
                    inventory_size: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="multiplePieces"
              label="Multiple pieces available"
              value={jm.availability_inventory.multiple_pieces_available}
              onChange={(v) =>
                patchJm({
                  availability_inventory: {
                    ...jm.availability_inventory,
                    multiple_pieces_available: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="realtimeTracking"
              label="Real-time availability tracking"
              value={jm.availability_inventory.realtime_availability_tracking}
              onChange={(v) =>
                patchJm({
                  availability_inventory: {
                    ...jm.availability_inventory,
                    realtime_availability_tracking: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 7: DELIVERY & LOGISTICS */}
        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Delivery & logistics</Accordion.Header>
          <Accordion.Body>
            <YesNoField
              groupName="homeDelivery"
              label="Home delivery available"
              value={jm.delivery_logistics.home_delivery_available}
              onChange={(v) =>
                patchJm({
                  delivery_logistics: {
                    ...jm.delivery_logistics,
                    home_delivery_available: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="pickupRequired"
              label="Pickup required"
              value={jm.delivery_logistics.pickup_required}
              onChange={(v) =>
                patchJm({
                  delivery_logistics: {
                    ...jm.delivery_logistics,
                    pickup_required: v,
                  },
                })
              }
            />
            <SelectField
              label="Shipping charges"
              options={SHIPPING_CHARGES}
              value={jm.delivery_logistics.shipping_charges}
              onChange={(v) =>
                patchJm({
                  delivery_logistics: {
                    ...jm.delivery_logistics,
                    shipping_charges: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="tryAtHome"
              label="Try-at-home service"
              value={jm.delivery_logistics.try_at_home_service}
              onChange={(v) =>
                patchJm({
                  delivery_logistics: {
                    ...jm.delivery_logistics,
                    try_at_home_service: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 8: HYGIENE & QUALITY ASSURANCE */}
        <Accordion.Item eventKey="7">
          <Accordion.Header>Section 8 — Hygiene & quality assurance</Accordion.Header>
          <Accordion.Body>
            <YesNoField
              groupName="sanitization"
              label="Sanitization process"
              value={jm.hygiene_quality.sanitization_process}
              onChange={(v) =>
                patchJm({
                  hygiene_quality: {
                    ...jm.hygiene_quality,
                    sanitization_process: v,
                  },
                })
              }
            />
            <SelectField
              label="Damage policy"
              options={DAMAGE_POLICY}
              value={jm.hygiene_quality.damage_policy}
              onChange={(v) =>
                patchJm({
                  hygiene_quality: { ...jm.hygiene_quality, damage_policy: v },
                })
              }
            />
            <YesNoField
              groupName="replacement"
              label="Replacement available"
              value={jm.hygiene_quality.replacement_available}
              onChange={(v) =>
                patchJm({
                  hygiene_quality: {
                    ...jm.hygiene_quality,
                    replacement_available: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 9: EVENT SUITABILITY */}
        <Accordion.Item eventKey="8">
          <Accordion.Header>Section 9 — Event suitability</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Functions suitable for"
              options={FUNCTIONS_SUITABLE_FOR}
              value={jm.event_suitability.functions_suitable_for}
              onChange={(v) =>
                patchJm({
                  event_suitability: {
                    ...jm.event_suitability,
                    functions_suitable_for: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Best for"
              options={BEST_FOR}
              value={jm.event_suitability.best_for}
              onChange={(v) =>
                patchJm({
                  event_suitability: { ...jm.event_suitability, best_for: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 10: WORKFLOW & BOOKING */}
        <Accordion.Item eventKey="9">
          <Accordion.Header>Section 10 — Workflow & booking</Accordion.Header>
          <Accordion.Body>
            <YesNoField
              groupName="advanceRequired"
              label="Advance required"
              value={jm.workflow_booking.advance_required}
              onChange={(v) =>
                patchJm({
                  workflow_booking: { ...jm.workflow_booking, advance_required: v },
                })
              }
            />
            <SelectField
              label="Advance percentage"
              options={ADVANCE_PERCENTAGE}
              value={jm.workflow_booking.advance_percentage}
              onChange={(v) =>
                patchJm({
                  workflow_booking: {
                    ...jm.workflow_booking,
                    advance_percentage: v,
                  },
                })
              }
            />
            <SelectField
              label="Cancellation policy"
              options={CANCELLATION_POLICY}
              value={jm.workflow_booking.cancellation_policy}
              onChange={(v) =>
                patchJm({
                  workflow_booking: {
                    ...jm.workflow_booking,
                    cancellation_policy: v,
                  },
                })
              }
            />
            <SelectField
              label="Refund timeline"
              options={REFUND_TIMELINE}
              value={jm.workflow_booking.refund_timeline}
              onChange={(v) =>
                patchJm({
                  workflow_booking: { ...jm.workflow_booking, refund_timeline: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 11: PORTFOLIO & PRODUCT TAGGING */}
        <Accordion.Item eventKey="10">
          <Accordion.Header>Section 11 — Portfolio & product tagging (Critical)</Accordion.Header>
          <Accordion.Body>
            <p className="text-muted fs-14">
              Upload jewellery catalog in the Photos tab (mandatory for go-live). Tag each
              product with: Jewellery Type, Style, Occasion, Outfit Color Match, Budget
              Range. This enables queries like "Show me kundan bridal set for red lehenga
              under ₹5K".
            </p>
            <div className="mb-3">
              <label className="form-label fw-semibold">Default tagging guidance</label>
              <Form.Control
                className="fs-14"
                value={jm.portfolio_tagging.tagging_guidance}
                onChange={(e) =>
                  patchJm({
                    portfolio_tagging: {
                      ...jm.portfolio_tagging,
                      tagging_guidance: e.target.value,
                    },
                  })
                }
              />
            </div>
            <div className="mb-3">
              <label className="form-label fw-semibold">Notes</label>
              <Form.Control
                as="textarea"
                rows={3}
                className="fs-14"
                value={jm.portfolio_tagging.notes}
                onChange={(e) =>
                  patchJm({
                    portfolio_tagging: {
                      ...jm.portfolio_tagging,
                      notes: e.target.value,
                    },
                  })
                }
              />
            </div>
          </Accordion.Body>
        </Accordion.Item>
      </Accordion>
      {!embedded && (
        <button type="button" className="btn btn-primary mt-3 fs-14" onClick={save}>
          Save jewellery master profile
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

export default JewelleryMasterProfile;
