import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  VENDOR_TYPE,
  YEARS_OF_EXPERIENCE,
  STORE_PRESENCE,
  SERVICE_CITIES,
  APPOINTMENT_REQUIREMENT,
  GOWN_TYPES,
  COLLECTION_TYPE,
  DESIGN_STYLE,
  COLOR_PALETTE,
  SILHOUETTE_TYPES,
  NECKLINE_TYPES,
  SLEEVE_TYPES,
  FABRIC_OPTIONS,
  EMBELLISHMENT_TYPES,
  TRAIN_LENGTH,
  WEIGHT_CATEGORY,
  SIZE_RANGE,
  BODY_TYPE_STYLING,
  FIT_TYPE,
  YES_NO,
  ALTERATION_SUPPORT,
  OCCASION_SUITABILITY,
  REUSABILITY,
  COMFORT_LEVEL,
  SEASON_SUITABILITY,
  PRICING_MODEL,
  PRICE_RANGE,
  INCLUDES,
  ADD_ONS,
  NEGOTIATION_FLEXIBILITY,
  PRODUCTION_TIME,
  DELIVERY_OPTIONS,
  PACKAGING,
  ORDERS_PER_MONTH,
  TEAM_SIZE,
  ADVANCE_BOOKING_TIME,
  BOOKING_ADVANCE,
  CANCELLATION_POLICY,
  CLIENT_COORDINATION,
  GOWN_TAGS,
  STYLE_TAGS,
  BRIDE_TYPE_TAGS,
  emptyCocktailGownMaster,
} from "./cocktailGownMasterConstants";

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
      {YES_NO.map((y) => (
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

const CocktailGownMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const jm = useMemo(() => {
    const raw =
      formData.cocktail_gown_master || formData.attributes?.cocktail_gown_master;
    if (raw && typeof raw === "object")
      return mergeDeep(emptyCocktailGownMaster(), raw);
    return emptyCocktailGownMaster();
  }, [formData.cocktail_gown_master, formData.attributes?.cocktail_gown_master]);

  const patchJm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(
          prev.cocktail_gown_master ||
            prev.attributes?.cocktail_gown_master ||
            emptyCocktailGownMaster(),
          partial
        );
        return {
          ...prev,
          cocktail_gown_master: next,
          attributes: { ...(prev.attributes || {}), cocktail_gown_master: next },
        };
      });
    },
    [setFormData]
  );

  return (
    <>
      <h4 className="mb-2 fw-bold">Cocktail Gowns Master Profile</h4>
      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        <Accordion.Item eventKey="0">
          <Accordion.Header>Section 1 — Basic Identity</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Vendor Type" options={VENDOR_TYPE} value={jm.identity.vendor_type} onChange={(v) => patchJm({ identity: { ...jm.identity, vendor_type: v } })} />
            <div className="mb-3">
              <label className="form-label fw-semibold">Brand Name</label>
              <Form.Control className="fs-14" value={jm.identity.brand_name} onChange={(e) => patchJm({ identity: { ...jm.identity, brand_name: e.target.value } })} />
            </div>
            <SelectField label="Years of Experience" options={YEARS_OF_EXPERIENCE} value={jm.identity.years_of_experience} onChange={(v) => patchJm({ identity: { ...jm.identity, years_of_experience: v } })} />
            <SelectField label="Store Presence" options={STORE_PRESENCE} value={jm.identity.store_presence} onChange={(v) => patchJm({ identity: { ...jm.identity, store_presence: v } })} />
            <MultiCheck label="Service Cities" options={SERVICE_CITIES} value={jm.identity.service_cities} onChange={(v) => patchJm({ identity: { ...jm.identity, service_cities: v } })} />
            <SelectField label="Appointment Requirement" options={APPOINTMENT_REQUIREMENT} value={jm.identity.appointment_requirement} onChange={(v) => patchJm({ identity: { ...jm.identity, appointment_requirement: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Product Catalog</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Gown Types" options={GOWN_TYPES} value={jm.product_catalog.gown_types} onChange={(v) => patchJm({ product_catalog: { ...jm.product_catalog, gown_types: v } })} />
            <SelectField label="Collection Type" options={COLLECTION_TYPE} value={jm.product_catalog.collection_type} onChange={(v) => patchJm({ product_catalog: { ...jm.product_catalog, collection_type: v } })} />
            <MultiCheck label="Design Style" options={DESIGN_STYLE} value={jm.product_catalog.design_style} onChange={(v) => patchJm({ product_catalog: { ...jm.product_catalog, design_style: v } })} />
            <MultiCheck label="Color Palette" options={COLOR_PALETTE} value={jm.product_catalog.color_palette} onChange={(v) => patchJm({ product_catalog: { ...jm.product_catalog, color_palette: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="2">
          <Accordion.Header>Section 3 — Core Intelligence</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Silhouette Types" options={SILHOUETTE_TYPES} value={jm.core_intelligence.silhouette_types} onChange={(v) => patchJm({ core_intelligence: { ...jm.core_intelligence, silhouette_types: v } })} />
            <MultiCheck label="Neckline Types" options={NECKLINE_TYPES} value={jm.core_intelligence.neckline_types} onChange={(v) => patchJm({ core_intelligence: { ...jm.core_intelligence, neckline_types: v } })} />
            <SelectField label="Sleeve Types" options={SLEEVE_TYPES} value={jm.core_intelligence.sleeve_types} onChange={(v) => patchJm({ core_intelligence: { ...jm.core_intelligence, sleeve_types: v } })} />
            <MultiCheck label="Fabric Options" options={FABRIC_OPTIONS} value={jm.core_intelligence.fabric_options} onChange={(v) => patchJm({ core_intelligence: { ...jm.core_intelligence, fabric_options: v } })} />
            <MultiCheck label="Embellishment Types" options={EMBELLISHMENT_TYPES} value={jm.core_intelligence.embellishment_types} onChange={(v) => patchJm({ core_intelligence: { ...jm.core_intelligence, embellishment_types: v } })} />
            <SelectField label="Train Length" options={TRAIN_LENGTH} value={jm.core_intelligence.train_length} onChange={(v) => patchJm({ core_intelligence: { ...jm.core_intelligence, train_length: v } })} />
            <SelectField label="Weight Category" options={WEIGHT_CATEGORY} value={jm.core_intelligence.weight_category} onChange={(v) => patchJm({ core_intelligence: { ...jm.core_intelligence, weight_category: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="3">
          <Accordion.Header>Section 4 — Fit & Styling Intelligence</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Size Range" options={SIZE_RANGE} value={jm.fit_styling.size_range} onChange={(v) => patchJm({ fit_styling: { ...jm.fit_styling, size_range: v } })} />
            <MultiCheck label="Body Type Styling Support" options={BODY_TYPE_STYLING} value={jm.fit_styling.body_type_styling} onChange={(v) => patchJm({ fit_styling: { ...jm.fit_styling, body_type_styling: v } })} />
            <SelectField label="Fit Type" options={FIT_TYPE} value={jm.fit_styling.fit_type} onChange={(v) => patchJm({ fit_styling: { ...jm.fit_styling, fit_type: v } })} />
            <YesNoField label="Trial Availability" value={jm.fit_styling.trial_availability} onChange={(v) => patchJm({ fit_styling: { ...jm.fit_styling, trial_availability: v } })} groupName="cg_trial"/>
            <SelectField label="Alteration Support" options={ALTERATION_SUPPORT} value={jm.fit_styling.alteration_support} onChange={(v) => patchJm({ fit_styling: { ...jm.fit_styling, alteration_support: v } })} />
            <YesNoField label="Styling Consultation" value={jm.fit_styling.styling_consultation} onChange={(v) => patchJm({ fit_styling: { ...jm.fit_styling, styling_consultation: v } })} groupName="cg_style"/>
            <YesNoField label="Accessory Styling Support" value={jm.fit_styling.accessory_styling_support} onChange={(v) => patchJm({ fit_styling: { ...jm.fit_styling, accessory_styling_support: v } })} groupName="cg_acc_style"/>
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="4">
          <Accordion.Header>Section 5 — Occasion & Usage Layer</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Primary Occasion Suitability" options={OCCASION_SUITABILITY} value={jm.occasion_usage.occasion_suitability} onChange={(v) => patchJm({ occasion_usage: { ...jm.occasion_usage, occasion_suitability: v } })} />
            <SelectField label="Reusability" options={REUSABILITY} value={jm.occasion_usage.reusability} onChange={(v) => patchJm({ occasion_usage: { ...jm.occasion_usage, reusability: v } })} />
            <SelectField label="Comfort Level" options={COMFORT_LEVEL} value={jm.occasion_usage.comfort_level} onChange={(v) => patchJm({ occasion_usage: { ...jm.occasion_usage, comfort_level: v } })} />
            <SelectField label="Season Suitability" options={SEASON_SUITABILITY} value={jm.occasion_usage.season_suitability} onChange={(v) => patchJm({ occasion_usage: { ...jm.occasion_usage, season_suitability: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Pricing Logic</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Pricing Model" options={PRICING_MODEL} value={jm.pricing_logic.pricing_model} onChange={(v) => patchJm({ pricing_logic: { ...jm.pricing_logic, pricing_model: v } })} />
            <SelectField label="Starting Price Range" options={PRICE_RANGE} value={jm.pricing_logic.starting_price_range} onChange={(v) => patchJm({ pricing_logic: { ...jm.pricing_logic, starting_price_range: v } })} />
            <MultiCheck label="Includes" options={INCLUDES} value={jm.pricing_logic.includes} onChange={(v) => patchJm({ pricing_logic: { ...jm.pricing_logic, includes: v } })} />
            <MultiCheck label="Add-ons" options={ADD_ONS} value={jm.pricing_logic.add_ons} onChange={(v) => patchJm({ pricing_logic: { ...jm.pricing_logic, add_ons: v } })} />
            <SelectField label="Negotiation Flexibility" options={NEGOTIATION_FLEXIBILITY} value={jm.pricing_logic.negotiation_flexibility} onChange={(v) => patchJm({ pricing_logic: { ...jm.pricing_logic, negotiation_flexibility: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Production & Delivery</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Production Time" options={PRODUCTION_TIME} value={jm.production_delivery.production_time} onChange={(v) => patchJm({ production_delivery: { ...jm.production_delivery, production_time: v } })} />
            <YesNoField label="Urgent Orders" value={jm.production_delivery.urgent_orders} onChange={(v) => patchJm({ production_delivery: { ...jm.production_delivery, urgent_orders: v } })} groupName="cg_urgent"/>
            <MultiCheck label="Delivery Options" options={DELIVERY_OPTIONS} value={jm.production_delivery.delivery_options} onChange={(v) => patchJm({ production_delivery: { ...jm.production_delivery, delivery_options: v } })} />
            <SelectField label="Packaging" options={PACKAGING} value={jm.production_delivery.packaging} onChange={(v) => patchJm({ production_delivery: { ...jm.production_delivery, packaging: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="7">
          <Accordion.Header>Section 8 — Scale & Operations</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Orders Per Month" options={ORDERS_PER_MONTH} value={jm.scale_operations.orders_per_month} onChange={(v) => patchJm({ scale_operations: { ...jm.scale_operations, orders_per_month: v } })} />
            <SelectField label="Team Size" options={TEAM_SIZE} value={jm.scale_operations.team_size} onChange={(v) => patchJm({ scale_operations: { ...jm.scale_operations, team_size: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="8">
          <Accordion.Header>Section 9 — Workflow & Booking</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Advance Booking Time" options={ADVANCE_BOOKING_TIME} value={jm.workflow_booking.advance_booking_time} onChange={(v) => patchJm({ workflow_booking: { ...jm.workflow_booking, advance_booking_time: v } })} />
            <SelectField label="Booking Advance %" options={BOOKING_ADVANCE} value={jm.workflow_booking.booking_advance_percent} onChange={(v) => patchJm({ workflow_booking: { ...jm.workflow_booking, booking_advance_percent: v } })} />
            <SelectField label="Cancellation Policy" options={CANCELLATION_POLICY} value={jm.workflow_booking.cancellation_policy} onChange={(v) => patchJm({ workflow_booking: { ...jm.workflow_booking, cancellation_policy: v } })} />
            <MultiCheck label="Client Coordination" options={CLIENT_COORDINATION} value={jm.workflow_booking.client_coordination} onChange={(v) => patchJm({ workflow_booking: { ...jm.workflow_booking, client_coordination: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="9">
          <Accordion.Header>Section 10 — Portfolio Tagging (AI Layer)</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Gown Tags" options={GOWN_TAGS} value={jm.ai_tags.gown_tags} onChange={(v) => patchJm({ ai_tags: { ...jm.ai_tags, gown_tags: v } })} />
            <MultiCheck label="Style Tags" options={STYLE_TAGS} value={jm.ai_tags.style_tags} onChange={(v) => patchJm({ ai_tags: { ...jm.ai_tags, style_tags: v } })} />
            <MultiCheck label="Bride Type Tags" options={BRIDE_TYPE_TAGS} value={jm.ai_tags.bride_type_tags} onChange={(v) => patchJm({ ai_tags: { ...jm.ai_tags, bride_type_tags: v } })} />
          </Accordion.Body>
        </Accordion.Item>
      </Accordion>
    </>
  );
};

export default CocktailGownMasterProfile;
