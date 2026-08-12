import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  VENDOR_TYPE_RENTAL,
  SERVICE_MODE,
  DELIVERY_COVERAGE,
  JEWELLERY_TYPES_RENTAL,
  YES_NO,
  COMPLETE_SET_INCLUDES,
  JEWELLERY_STYLE,
  BEST_KNOWN_FOR_RENTAL,
  SUITABLE_FOR,
  STYLING_CONSULTATION,
  BASE_MATERIAL,
  FINISH_QUALITY,
  REAL_VS_IMITATION,
  RENTAL_DURATION,
  RENTAL_PRICE_RANGE,
  SECURITY_DEPOSIT,
  DEPOSIT_AMOUNT_RANGE,
  LATE_RETURN_CHARGES,
  ADVANCE_BOOKING_REQUIRED,
  INVENTORY_SIZE,
  MULTIPLE_PIECES,
  AVAILABILITY_TRACKING,
  HOME_DELIVERY,
  PICKUP_REQUIRED,
  SHIPPING_CHARGES,
  TRY_AT_HOME,
  SANITIZATION_PROCESS,
  DAMAGE_POLICY,
  REPLACEMENT_AVAILABLE,
  FUNCTIONS_SUITABLE_FOR_RENTAL,
  BEST_FOR_RENTAL,
  ADVANCE_PERCENTAGE,
  CANCELLATION_POLICY,
  REFUND_TIMELINE,
  AI_FAQ_BRIDAL_SETS,
  AI_FAQ_RENTAL_DURATION,
  AI_FAQ_SECURITY_DEPOSIT,
  AI_FAQ_DEPOSIT_AMOUNT,
  AI_FAQ_HOME_DELIVERY,
  AI_FAQ_TRY_AT_HOME,
  AI_FAQ_STYLING,
  AI_FAQ_JEWELLERY_TYPES,
  AI_FAQ_OCCASIONS,
  AI_FAQ_INVENTORY_SIZE,
  AI_FAQ_REPLACEMENT,
  AI_FAQ_DAMAGE_POLICY,
  AI_FAQ_ADVANCE,
  AI_FAQ_CANCELLATION,
  AI_FAQ_BEST_FOR,
  emptyJewelleryRentalMaster,
} from "./jewelleryRentalMasterConstants";

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

function JewelleryRentalMasterProfile({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) {
  const jrm = useMemo(() => {
    const raw =
      formData.jewellery_rental_master || formData.attributes?.jewellery_rental_master;
    if (raw && typeof raw === "object")
      return mergeDeep(emptyJewelleryRentalMaster(), raw);
    return emptyJewelleryRentalMaster();
  }, [
    formData.jewellery_rental_master,
    formData.attributes?.jewellery_rental_master,
  ]);

  const patchJrm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(
          prev.jewellery_rental_master ||
            prev.attributes?.jewellery_rental_master ||
            emptyJewelleryRentalMaster(),
          partial
        );
        return {
          ...prev,
          jewellery_rental_master: next,
          attributes: { ...prev.attributes, jewellery_rental_master: next },
        };
      });
    },
    [setFormData]
  );

  const handleSave = async () => {
    if (onSave) await onSave(formData);
    if (onShowSuccess) onShowSuccess();
  };

  if (embedded) {
    return (
      <Accordion defaultActiveKey="0" className="mb-4">
        {/* SECTION 1: BASIC IDENTITY */}
        <Accordion.Item eventKey="0">
          <Accordion.Header>Basic Identity</Accordion.Header>
          <Accordion.Body>
            <TextField
              label="Brand / Store Name"
              value={jrm.identity.brand_name}
              onChange={(v) => patchJrm({ identity: { ...jrm.identity, brand_name: v } })}
            />
            <SelectField
              label="Vendor Type"
              options={VENDOR_TYPE_RENTAL}
              value={jrm.identity.vendor_type}
              onChange={(v) => patchJrm({ identity: { ...jrm.identity, vendor_type: v } })}
            />
            <TextField
              label="Years of Experience"
              type="number"
              value={jrm.identity.years_of_experience}
              onChange={(v) => patchJrm({ identity: { ...jrm.identity, years_of_experience: v } })}
            />
            <TextField
              label="City"
              value={jrm.identity.city}
              onChange={(v) => patchJrm({ identity: { ...jrm.identity, city: v } })}
            />
            <SelectField
              label="Service Mode"
              options={SERVICE_MODE}
              value={jrm.identity.service_mode}
              onChange={(v) => patchJrm({ identity: { ...jrm.identity, service_mode: v } })}
            />
            <SelectField
              label="Delivery Coverage"
              options={DELIVERY_COVERAGE}
              value={jrm.identity.delivery_coverage}
              onChange={(v) => patchJrm({ identity: { ...jrm.identity, delivery_coverage: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 2: PRODUCT CATEGORIES */}
        <Accordion.Item eventKey="1">
          <Accordion.Header>Product Categories</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Jewellery Types Offered"
              options={JEWELLERY_TYPES_RENTAL}
              value={jrm.product_categories.jewellery_types}
              onChange={(v) =>
                patchJrm({
                  product_categories: { ...jrm.product_categories, jewellery_types: v },
                })
              }
            />
            <SelectField
              label="Bridal Package Available"
              options={YES_NO}
              value={jrm.product_categories.bridal_package}
              onChange={(v) =>
                patchJrm({
                  product_categories: { ...jrm.product_categories, bridal_package: v },
                })
              }
            />
            <MultiCheck
              label="Complete Set Includes"
              options={COMPLETE_SET_INCLUDES}
              value={jrm.product_categories.set_includes}
              onChange={(v) =>
                patchJrm({
                  product_categories: { ...jrm.product_categories, set_includes: v },
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
              label="Jewellery Style"
              options={JEWELLERY_STYLE}
              value={jrm.style_design.jewellery_style}
              onChange={(v) =>
                patchJrm({
                  style_design: { ...jrm.style_design, jewellery_style: v },
                })
              }
            />
            <MultiCheck
              label="Best Known For"
              options={BEST_KNOWN_FOR_RENTAL}
              value={jrm.style_design.best_known_for}
              onChange={(v) =>
                patchJrm({
                  style_design: { ...jrm.style_design, best_known_for: v },
                })
              }
            />
            <MultiCheck
              label="Suitable For"
              options={SUITABLE_FOR}
              value={jrm.style_design.suitable_for}
              onChange={(v) =>
                patchJrm({
                  style_design: { ...jrm.style_design, suitable_for: v },
                })
              }
            />
            <SelectField
              label="Outfit Matching Support"
              options={YES_NO}
              value={jrm.style_design.outfit_matching_support}
              onChange={(v) =>
                patchJrm({
                  style_design: { ...jrm.style_design, outfit_matching_support: v },
                })
              }
            />
            <SelectField
              label="Styling Consultation"
              options={YES_NO}
              value={jrm.style_design.styling_consultation}
              onChange={(v) =>
                patchJrm({
                  style_design: { ...jrm.style_design, styling_consultation: v },
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
              label="Base Material"
              options={BASE_MATERIAL}
              value={jrm.material_quality.base_material}
              onChange={(v) =>
                patchJrm({
                  material_quality: { ...jrm.material_quality, base_material: v },
                })
              }
            />
            <SelectField
              label="Finish Quality"
              options={FINISH_QUALITY}
              value={jrm.material_quality.finish_quality}
              onChange={(v) =>
                patchJrm({
                  material_quality: { ...jrm.material_quality, finish_quality: v },
                })
              }
            />
            <SelectField
              label="Real vs Imitation"
              options={REAL_VS_IMITATION}
              value={jrm.material_quality.real_vs_imitation}
              onChange={(v) =>
                patchJrm({
                  material_quality: { ...jrm.material_quality, real_vs_imitation: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 5: RENTAL LOGIC */}
        <Accordion.Item eventKey="4">
          <Accordion.Header>Rental Logic</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Rental Duration"
              options={RENTAL_DURATION}
              value={jrm.rental_logic.rental_duration}
              onChange={(v) =>
                patchJrm({
                  rental_logic: { ...jrm.rental_logic, rental_duration: v },
                })
              }
            />
            <SelectField
              label="Rental Price Range"
              options={RENTAL_PRICE_RANGE}
              value={jrm.rental_logic.rental_price_range}
              onChange={(v) =>
                patchJrm({
                  rental_logic: { ...jrm.rental_logic, rental_price_range: v },
                })
              }
            />
            <SelectField
              label="Security Deposit"
              options={SECURITY_DEPOSIT}
              value={jrm.rental_logic.security_deposit}
              onChange={(v) =>
                patchJrm({
                  rental_logic: { ...jrm.rental_logic, security_deposit: v },
                })
              }
            />
            <SelectField
              label="Deposit Amount Range"
              options={DEPOSIT_AMOUNT_RANGE}
              value={jrm.rental_logic.deposit_amount_range}
              onChange={(v) =>
                patchJrm({
                  rental_logic: { ...jrm.rental_logic, deposit_amount_range: v },
                })
              }
            />
            <SelectField
              label="Late Return Charges"
              options={LATE_RETURN_CHARGES}
              value={jrm.rental_logic.late_return_charges}
              onChange={(v) =>
                patchJrm({
                  rental_logic: { ...jrm.rental_logic, late_return_charges: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 6: AVAILABILITY & INVENTORY */}
        <Accordion.Item eventKey="5">
          <Accordion.Header>Availability & Inventory</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Advance Booking Required"
              options={ADVANCE_BOOKING_REQUIRED}
              value={jrm.availability.advance_booking_required}
              onChange={(v) =>
                patchJrm({
                  availability: { ...jrm.availability, advance_booking_required: v },
                })
              }
            />
            <SelectField
              label="Inventory Size"
              options={INVENTORY_SIZE}
              value={jrm.availability.inventory_size}
              onChange={(v) =>
                patchJrm({
                  availability: { ...jrm.availability, inventory_size: v },
                })
              }
            />
            <SelectField
              label="Multiple Pieces Available"
              options={MULTIPLE_PIECES}
              value={jrm.availability.multiple_pieces_available}
              onChange={(v) =>
                patchJrm({
                  availability: { ...jrm.availability, multiple_pieces_available: v },
                })
              }
            />
            <SelectField
              label="Real-Time Availability Tracking"
              options={AVAILABILITY_TRACKING}
              value={jrm.availability.availability_tracking}
              onChange={(v) =>
                patchJrm({
                  availability: { ...jrm.availability, availability_tracking: v },
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
              label="Home Delivery Available"
              options={HOME_DELIVERY}
              value={jrm.delivery_logistics.home_delivery}
              onChange={(v) =>
                patchJrm({
                  delivery_logistics: { ...jrm.delivery_logistics, home_delivery: v },
                })
              }
            />
            <SelectField
              label="Pickup Required"
              options={PICKUP_REQUIRED}
              value={jrm.delivery_logistics.pickup_required}
              onChange={(v) =>
                patchJrm({
                  delivery_logistics: { ...jrm.delivery_logistics, pickup_required: v },
                })
              }
            />
            <SelectField
              label="Shipping Charges"
              options={SHIPPING_CHARGES}
              value={jrm.delivery_logistics.shipping_charges}
              onChange={(v) =>
                patchJrm({
                  delivery_logistics: { ...jrm.delivery_logistics, shipping_charges: v },
                })
              }
            />
            <SelectField
              label="Try-at-Home Service"
              options={TRY_AT_HOME}
              value={jrm.delivery_logistics.try_at_home}
              onChange={(v) =>
                patchJrm({
                  delivery_logistics: { ...jrm.delivery_logistics, try_at_home: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 8: HYGIENE & QUALITY ASSURANCE */}
        <Accordion.Item eventKey="7">
          <Accordion.Header>Hygiene & Quality Assurance</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Sanitization Process"
              options={SANITIZATION_PROCESS}
              value={jrm.hygiene_quality.sanitization_process}
              onChange={(v) =>
                patchJrm({
                  hygiene_quality: { ...jrm.hygiene_quality, sanitization_process: v },
                })
              }
            />
            <SelectField
              label="Damage Policy"
              options={DAMAGE_POLICY}
              value={jrm.hygiene_quality.damage_policy}
              onChange={(v) =>
                patchJrm({
                  hygiene_quality: { ...jrm.hygiene_quality, damage_policy: v },
                })
              }
            />
            <SelectField
              label="Replacement Available"
              options={REPLACEMENT_AVAILABLE}
              value={jrm.hygiene_quality.replacement_available}
              onChange={(v) =>
                patchJrm({
                  hygiene_quality: { ...jrm.hygiene_quality, replacement_available: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 9: EVENT SUITABILITY */}
        <Accordion.Item eventKey="8">
          <Accordion.Header>Event Suitability</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Functions Suitable For"
              options={FUNCTIONS_SUITABLE_FOR_RENTAL}
              value={jrm.event_suitability.functions_suitable_for}
              onChange={(v) =>
                patchJrm({
                  event_suitability: {
                    ...jrm.event_suitability,
                    functions_suitable_for: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Best For"
              options={BEST_FOR_RENTAL}
              value={jrm.event_suitability.best_for}
              onChange={(v) =>
                patchJrm({
                  event_suitability: { ...jrm.event_suitability, best_for: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 10: WORKFLOW & BOOKING */}
        <Accordion.Item eventKey="9">
          <Accordion.Header>Workflow & Booking</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Advance Required"
              options={YES_NO}
              value={jrm.workflow_booking.advance_required}
              onChange={(v) =>
                patchJrm({
                  workflow_booking: { ...jrm.workflow_booking, advance_required: v },
                })
              }
            />
            <SelectField
              label="Advance Percentage"
              options={ADVANCE_PERCENTAGE}
              value={jrm.workflow_booking.advance_percentage}
              onChange={(v) =>
                patchJrm({
                  workflow_booking: { ...jrm.workflow_booking, advance_percentage: v },
                })
              }
            />
            <SelectField
              label="Cancellation Policy"
              options={CANCELLATION_POLICY}
              value={jrm.workflow_booking.cancellation_policy}
              onChange={(v) =>
                patchJrm({
                  workflow_booking: { ...jrm.workflow_booking, cancellation_policy: v },
                })
              }
            />
            <SelectField
              label="Refund Timeline"
              options={REFUND_TIMELINE}
              value={jrm.workflow_booking.refund_timeline}
              onChange={(v) =>
                patchJrm({
                  workflow_booking: { ...jrm.workflow_booking, refund_timeline: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>
      </Accordion>
    );
  }

  return (
    <div className="my-5 p-4 border rounded bg-white">
      <h3 className="mb-4 fw-bold">Jewellery Rental Master Profile</h3>
      <button className="btn btn-primary mb-3" onClick={handleSave}>
        Save All
      </button>
      <Accordion defaultActiveKey="0">
        {/* Same sections as above - included for non-embedded view */}
        <Accordion.Item eventKey="0">
          <Accordion.Header>Basic Identity</Accordion.Header>
          <Accordion.Body>
            <TextField
              label="Brand / Store Name"
              value={jrm.identity.brand_name}
              onChange={(v) => patchJrm({ identity: { ...jrm.identity, brand_name: v } })}
            />
            <SelectField
              label="Vendor Type"
              options={VENDOR_TYPE_RENTAL}
              value={jrm.identity.vendor_type}
              onChange={(v) => patchJrm({ identity: { ...jrm.identity, vendor_type: v } })}
            />
            <TextField
              label="Years of Experience"
              type="number"
              value={jrm.identity.years_of_experience}
              onChange={(v) => patchJrm({ identity: { ...jrm.identity, years_of_experience: v } })}
            />
            <TextField
              label="City"
              value={jrm.identity.city}
              onChange={(v) => patchJrm({ identity: { ...jrm.identity, city: v } })}
            />
            <SelectField
              label="Service Mode"
              options={SERVICE_MODE}
              value={jrm.identity.service_mode}
              onChange={(v) => patchJrm({ identity: { ...jrm.identity, service_mode: v } })}
            />
            <SelectField
              label="Delivery Coverage"
              options={DELIVERY_COVERAGE}
              value={jrm.identity.delivery_coverage}
              onChange={(v) => patchJrm({ identity: { ...jrm.identity, delivery_coverage: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>
      </Accordion>
    </div>
  );
}

export default JewelleryRentalMasterProfile;
