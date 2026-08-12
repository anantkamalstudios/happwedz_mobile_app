import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  VENDOR_TYPE,
  STORE_PRESENCE,
  STORE_ACCESS_TYPE,
  YEARS_OF_EXPERIENCE,
  INVENTORY_SPECIALIZATION,
  RENTAL_TYPES,
  TRIAL_AVAILABILITY,
  CUSTOMIZATION_ALTERATION,
  YES_NO,
  ACCESSORY_RENTAL,
  LEHENGA_STYLES,
  OCCASION_SUITABILITY,
  WORK_TYPE,
  FABRIC_OPTIONS,
  COLOR_PALETTE,
  DESIGNER_AVAILABILITY,
  DUPATTA_STYLES,
  SIZE_RANGE,
  ADJUSTABILITY_RANGE,
  LEHENGA_WEIGHT,
  BLOUSE_TYPE,
  DUPATTA_LENGTH,
  CONDITION_QUALITY,
  RENTAL_PRICE_RANGE,
  DEPOSIT_AMOUNT_RANGE,
  DAMAGE_POLICY,
  CLEANING_CHARGES,
  TRIAL_CHARGES,
  INVENTORY_SIZE,
  DAILY_TRIAL_CAPACITY,
  SIMULTANEOUS_RENTALS,
  BOOKING_WINDOW,
  FITTING_TIMELINE,
  PICKUP_TIMING,
  RETURN_TIMELINE,
  PAYMENT_MODES,
  ADVANCE_PAYMENT_PERCENTAGE,
  STYLE_TAGS,
  AUDIENCE_TAGS,
  USAGE_TAGS,
  PRICE_SEGMENT_TAGS,
  emptyRentalOutfitMaster,
} from "./rentalOutfitMasterConstants";

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

function RentalOutfitMasterProfile({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) {
  const rom = useMemo(() => {
    const raw =
      formData.rental_outfit_master || formData.attributes?.rental_outfit_master;
    if (raw && typeof raw === "object")
      return mergeDeep(emptyRentalOutfitMaster(), raw);
    return emptyRentalOutfitMaster();
  }, [
    formData.rental_outfit_master,
    formData.attributes?.rental_outfit_master,
  ]);

  const patchRom = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(
          prev.rental_outfit_master ||
            prev.attributes?.rental_outfit_master ||
            emptyRentalOutfitMaster(),
          partial
        );
        return {
          ...prev,
          rental_outfit_master: next,
          attributes: {
            ...(prev.attributes || {}),
            rental_outfit_master: next,
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
      <h4 className="mb-2 fw-bold">Bridal Outfit on Rent - Master Profile</h4>
      <p className="text-muted fs-14 mb-4">
        Structured rental outfit data for search, filters, portfolio tagging, and FAQ matching.
      </p>
      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        {/* SECTION 1: BASIC IDENTITY */}
        <Accordion.Item eventKey="0">
          <Accordion.Header>Basic Identity</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Vendor Type"
              options={VENDOR_TYPE}
              value={rom.identity.vendor_type}
              onChange={(v) =>
                patchRom({ identity: { ...rom.identity, vendor_type: v } })
              }
            />
            <TextField
              label="Brand / Store Name"
              value={rom.identity.brand_name}
              onChange={(v) =>
                patchRom({ identity: { ...rom.identity, brand_name: v } })
              }
            />
            <MultiCheck
              label="Store Presence"
              options={STORE_PRESENCE}
              value={rom.identity.store_presence}
              onChange={(v) =>
                patchRom({ identity: { ...rom.identity, store_presence: v } })
              }
            />
            <TextField
              label="City"
              value={rom.identity.city}
              onChange={(v) =>
                patchRom({ identity: { ...rom.identity, city: v } })
              }
            />
            <SelectField
              label="Store Access Type"
              options={STORE_ACCESS_TYPE}
              value={rom.identity.store_access_type}
              onChange={(v) =>
                patchRom({ identity: { ...rom.identity, store_access_type: v } })
              }
            />
            <SelectField
              label="Years of Experience"
              options={YEARS_OF_EXPERIENCE}
              value={rom.identity.years_of_experience}
              onChange={(v) =>
                patchRom({
                  identity: { ...rom.identity, years_of_experience: v },
                })
              }
            />
            <MultiCheck
              label="Inventory Specialization"
              options={INVENTORY_SPECIALIZATION}
              value={rom.identity.inventory_specialization}
              onChange={(v) =>
                patchRom({
                  identity: { ...rom.identity, inventory_specialization: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 2: SERVICES OFFERED */}
        <Accordion.Item eventKey="1">
          <Accordion.Header>Services Offered</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Rental Types"
              options={RENTAL_TYPES}
              value={rom.services.rental_types}
              onChange={(v) =>
                patchRom({ services: { ...rom.services, rental_types: v } })
              }
            />
            <SelectField
              label="Trial Availability"
              options={TRIAL_AVAILABILITY}
              value={rom.services.trial_availability}
              onChange={(v) =>
                patchRom({
                  services: { ...rom.services, trial_availability: v },
                })
              }
            />
            <SelectField
              label="Customization / Alteration"
              options={CUSTOMIZATION_ALTERATION}
              value={rom.services.customization_alteration}
              onChange={(v) =>
                patchRom({
                  services: { ...rom.services, customization_alteration: v },
                })
              }
            />
            <SelectField
              label="Styling Assistance"
              options={YES_NO}
              value={rom.services.styling_assistance}
              onChange={(v) =>
                patchRom({
                  services: { ...rom.services, styling_assistance: v },
                })
              }
            />
            <MultiCheck
              label="Accessory Rental Available"
              options={ACCESSORY_RENTAL}
              value={rom.services.accessory_rental}
              onChange={(v) =>
                patchRom({ services: { ...rom.services, accessory_rental: v } })
              }
            />
            <SelectField
              label="Dry Cleaning Included"
              options={YES_NO}
              value={rom.services.dry_cleaning_included}
              onChange={(v) =>
                patchRom({
                  services: { ...rom.services, dry_cleaning_included: v },
                })
              }
            />
            <SelectField
              label="Pickup & Delivery Service"
              options={YES_NO}
              value={rom.services.pickup_delivery_service}
              onChange={(v) =>
                patchRom({
                  services: { ...rom.services, pickup_delivery_service: v },
                })
              }
            />
            <SelectField
              label="Urgent Rental Availability"
              options={YES_NO}
              value={rom.services.urgent_rental_availability}
              onChange={(v) =>
                patchRom({
                  services: { ...rom.services, urgent_rental_availability: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 3: CORE INTELLIGENCE */}
        <Accordion.Item eventKey="2">
          <Accordion.Header>Core Intelligence Layer</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Lehenga Styles Available"
              options={LEHENGA_STYLES}
              value={rom.core_intelligence.lehenga_styles}
              onChange={(v) =>
                patchRom({
                  core_intelligence: {
                    ...rom.core_intelligence,
                    lehenga_styles: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Occasion Suitability"
              options={OCCASION_SUITABILITY}
              value={rom.core_intelligence.occasion_suitability}
              onChange={(v) =>
                patchRom({
                  core_intelligence: {
                    ...rom.core_intelligence,
                    occasion_suitability: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Work Type"
              options={WORK_TYPE}
              value={rom.core_intelligence.work_type}
              onChange={(v) =>
                patchRom({
                  core_intelligence: { ...rom.core_intelligence, work_type: v },
                })
              }
            />
            <MultiCheck
              label="Fabric Options"
              options={FABRIC_OPTIONS}
              value={rom.core_intelligence.fabric_options}
              onChange={(v) =>
                patchRom({
                  core_intelligence: {
                    ...rom.core_intelligence,
                    fabric_options: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Color Palette"
              options={COLOR_PALETTE}
              value={rom.core_intelligence.color_palette}
              onChange={(v) =>
                patchRom({
                  core_intelligence: {
                    ...rom.core_intelligence,
                    color_palette: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Designer Availability"
              options={DESIGNER_AVAILABILITY}
              value={rom.core_intelligence.designer_availability}
              onChange={(v) =>
                patchRom({
                  core_intelligence: {
                    ...rom.core_intelligence,
                    designer_availability: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Dupatta Styles"
              options={DUPATTA_STYLES}
              value={rom.core_intelligence.dupatta_styles}
              onChange={(v) =>
                patchRom({
                  core_intelligence: {
                    ...rom.core_intelligence,
                    dupatta_styles: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 4: TECHNICAL / PRODUCT */}
        <Accordion.Item eventKey="3">
          <Accordion.Header>Technical / Product Layer</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Size Range Available"
              options={SIZE_RANGE}
              value={rom.technical.size_range}
              onChange={(v) =>
                patchRom({ technical: { ...rom.technical, size_range: v } })
              }
            />
            <SelectField
              label="Adjustability Range"
              options={ADJUSTABILITY_RANGE}
              value={rom.technical.adjustability_range}
              onChange={(v) =>
                patchRom({
                  technical: { ...rom.technical, adjustability_range: v },
                })
              }
            />
            <SelectField
              label="Lehenga Weight Category"
              options={LEHENGA_WEIGHT}
              value={rom.technical.lehenga_weight}
              onChange={(v) =>
                patchRom({ technical: { ...rom.technical, lehenga_weight: v } })
              }
            />
            <MultiCheck
              label="Blouse Type"
              options={BLOUSE_TYPE}
              value={rom.technical.blouse_type}
              onChange={(v) =>
                patchRom({ technical: { ...rom.technical, blouse_type: v } })
              }
            />
            <SelectField
              label="Can-Can Included"
              options={YES_NO}
              value={rom.technical.can_can_included}
              onChange={(v) =>
                patchRom({
                  technical: { ...rom.technical, can_can_included: v },
                })
              }
            />
            <SelectField
              label="Dupatta Length Options"
              options={DUPATTA_LENGTH}
              value={rom.technical.dupatta_length}
              onChange={(v) =>
                patchRom({ technical: { ...rom.technical, dupatta_length: v } })
              }
            />
            <SelectField
              label="Condition Quality"
              options={CONDITION_QUALITY}
              value={rom.technical.condition_quality}
              onChange={(v) =>
                patchRom({
                  technical: { ...rom.technical, condition_quality: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 5: PRICING LOGIC */}
        <Accordion.Item eventKey="4">
          <Accordion.Header>Pricing Logic</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Rental Price Range (INR)"
              options={RENTAL_PRICE_RANGE}
              value={rom.pricing.rental_price_range}
              onChange={(v) =>
                patchRom({ pricing: { ...rom.pricing, rental_price_range: v } })
              }
            />
            <SelectField
              label="Security Deposit Required"
              options={YES_NO}
              value={rom.pricing.security_deposit_required}
              onChange={(v) =>
                patchRom({
                  pricing: { ...rom.pricing, security_deposit_required: v },
                })
              }
            />
            <SelectField
              label="Deposit Amount Range"
              options={DEPOSIT_AMOUNT_RANGE}
              value={rom.pricing.deposit_amount_range}
              onChange={(v) =>
                patchRom({
                  pricing: { ...rom.pricing, deposit_amount_range: v },
                })
              }
            />
            <SelectField
              label="Late Return Charges"
              options={YES_NO}
              value={rom.pricing.late_return_charges}
              onChange={(v) =>
                patchRom({
                  pricing: { ...rom.pricing, late_return_charges: v },
                })
              }
            />
            <SelectField
              label="Damage Policy"
              options={DAMAGE_POLICY}
              value={rom.pricing.damage_policy}
              onChange={(v) =>
                patchRom({ pricing: { ...rom.pricing, damage_policy: v } })
              }
            />
            <SelectField
              label="Cleaning Charges"
              options={CLEANING_CHARGES}
              value={rom.pricing.cleaning_charges}
              onChange={(v) =>
                patchRom({ pricing: { ...rom.pricing, cleaning_charges: v } })
              }
            />
            <SelectField
              label="Trial Charges"
              options={TRIAL_CHARGES}
              value={rom.pricing.trial_charges}
              onChange={(v) =>
                patchRom({ pricing: { ...rom.pricing, trial_charges: v } })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 7: SCALE & CAPACITY */}
        <Accordion.Item eventKey="6">
          <Accordion.Header>Scale & Capacity</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Inventory Size"
              options={INVENTORY_SIZE}
              value={rom.scale.inventory_size}
              onChange={(v) =>
                patchRom({ scale: { ...rom.scale, inventory_size: v } })
              }
            />
            <SelectField
              label="Daily Trial Capacity"
              options={DAILY_TRIAL_CAPACITY}
              value={rom.scale.daily_trial_capacity}
              onChange={(v) =>
                patchRom({ scale: { ...rom.scale, daily_trial_capacity: v } })
              }
            />
            <SelectField
              label="Simultaneous Rentals Capacity"
              options={SIMULTANEOUS_RENTALS}
              value={rom.scale.simultaneous_rentals}
              onChange={(v) =>
                patchRom({ scale: { ...rom.scale, simultaneous_rentals: v } })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 8: WORKFLOW & BOOKING */}
        <Accordion.Item eventKey="7">
          <Accordion.Header>Workflow & Booking</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Advance Booking Required"
              options={YES_NO}
              value={rom.workflow.advance_booking_required}
              onChange={(v) =>
                patchRom({
                  workflow: { ...rom.workflow, advance_booking_required: v },
                })
              }
            />
            <SelectField
              label="Booking Window"
              options={BOOKING_WINDOW}
              value={rom.workflow.booking_window}
              onChange={(v) =>
                patchRom({ workflow: { ...rom.workflow, booking_window: v } })
              }
            />
            <SelectField
              label="Trial Appointment Required"
              options={YES_NO}
              value={rom.workflow.trial_appointment_required}
              onChange={(v) =>
                patchRom({
                  workflow: { ...rom.workflow, trial_appointment_required: v },
                })
              }
            />
            <SelectField
              label="Fitting Timeline Before Event"
              options={FITTING_TIMELINE}
              value={rom.workflow.fitting_timeline}
              onChange={(v) =>
                patchRom({ workflow: { ...rom.workflow, fitting_timeline: v } })
              }
            />
            <SelectField
              label="Pickup Timing"
              options={PICKUP_TIMING}
              value={rom.workflow.pickup_timing}
              onChange={(v) =>
                patchRom({ workflow: { ...rom.workflow, pickup_timing: v } })
              }
            />
            <SelectField
              label="Return Timeline"
              options={RETURN_TIMELINE}
              value={rom.workflow.return_timeline}
              onChange={(v) =>
                patchRom({ workflow: { ...rom.workflow, return_timeline: v } })
              }
            />
            <MultiCheck
              label="Payment Modes"
              options={PAYMENT_MODES}
              value={rom.workflow.payment_modes}
              onChange={(v) =>
                patchRom({ workflow: { ...rom.workflow, payment_modes: v } })
              }
            />
            <SelectField
              label="Advance Payment Percentage"
              options={ADVANCE_PAYMENT_PERCENTAGE}
              value={rom.workflow.advance_payment_percentage}
              onChange={(v) =>
                patchRom({
                  workflow: { ...rom.workflow, advance_payment_percentage: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* SECTION 9: PORTFOLIO TAGGING */}
        <Accordion.Item eventKey="8">
          <Accordion.Header>Portfolio Tagging</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Style Tags"
              options={STYLE_TAGS}
              value={rom.portfolio.style_tags}
              onChange={(v) =>
                patchRom({ portfolio: { ...rom.portfolio, style_tags: v } })
              }
            />
            <MultiCheck
              label="Audience Tags"
              options={AUDIENCE_TAGS}
              value={rom.portfolio.audience_tags}
              onChange={(v) =>
                patchRom({ portfolio: { ...rom.portfolio, audience_tags: v } })
              }
            />
            <MultiCheck
              label="Usage Tags"
              options={USAGE_TAGS}
              value={rom.portfolio.usage_tags}
              onChange={(v) =>
                patchRom({ portfolio: { ...rom.portfolio, usage_tags: v } })
              }
            />
            <MultiCheck
              label="Price Segment Tags"
              options={PRICE_SEGMENT_TAGS}
              value={rom.portfolio.price_segment_tags}
              onChange={(v) =>
                patchRom({
                  portfolio: { ...rom.portfolio, price_segment_tags: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>
      </Accordion>

      {!embedded && (
        <button type="button" className="btn btn-primary mt-3 fs-14" onClick={save}>
          Save rental outfit master profile
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

export default RentalOutfitMasterProfile;
