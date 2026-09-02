import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  INVITATION_VENDOR_TYPE,
  YEARS_OF_EXPERIENCE,
  SERVICE_MODE,
  DELIVERY_MODEL,
  INVITATION_TYPES,
  EVENT_COVERAGE,
  DESIGN_FORMATS,
  LANGUAGE_OPTIONS,
  DESIGN_STYLE_INVITATION,
  CUSTOMIZATION_LEVEL,
  THEME_MATCHING,
  PERSONALIZATION_OPTIONS_INVITATION,
  PRINT_MATERIAL_OPTIONS,
  SPECIAL_FEATURES,
  E_INVITE_FORMATS,
  WEBSITE_INVITE_FEATURES,
  MIN_ORDER_QTY,
  MAX_ORDER_CAPACITY,
  TURNAROUND_TIME,
  PROOFING_PROCESS,
  PACKAGING_OPTIONS,
  PRICING_MODEL_INVITATION,
  STARTING_PRICE_RANGE,
  DIGITAL_INVITE_PRICING,
  INCLUDES_INVITATION,
  ADDONS_INVITATION,
  NEGOTIATION,
  ORDERS_PER_MONTH,
  TEAM_SIZE,
  ADVANCE_BOOKING_TIME,
  BOOKING_ADVANCE,
  CANCELLATION_POLICY,
  CLIENT_COORDINATION,
  emptyInvitationMaster,
} from "./invitationMasterConstants";

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

const InvitationMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const dm = useMemo(() => {
    const raw = formData.invitation_master || formData.attributes?.invitation_master;
    if (raw && typeof raw === "object") return mergeDeep(emptyInvitationMaster(), raw);
    return emptyInvitationMaster();
  }, [formData.invitation_master, formData.attributes?.invitation_master]);

  const patchDm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const current =
          prev.invitation_master ||
          prev.attributes?.invitation_master ||
          emptyInvitationMaster();
        const next = mergeDeep(current, partial);
        return {
          ...prev,
          invitation_master: next,
          attributes: { ...(prev.attributes || {}), invitation_master: next },
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
      <h4 className="mb-2 fw-bold">Invitation Master Profile</h4>
      <p className="text-muted fs-14 mb-4">Structured invitation vendor data for search, filters, and AI FAQ.</p>
      
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
            <SelectField label="Delivery Model" options={DELIVERY_MODEL} value={dm.identity.delivery_model} onChange={(v) => patchDm({ identity: { ...dm.identity, delivery_model: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Services Offered</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Invitation Types" options={INVITATION_TYPES} value={dm.services.invitation_types} onChange={(v) => patchDm({ services: { ...dm.services, invitation_types: v } })} />
            <MultiCheck label="Event Coverage" options={EVENT_COVERAGE} value={dm.services.event_coverage} onChange={(v) => patchDm({ services: { ...dm.services, event_coverage: v } })} />
            <SelectField label="Design Formats" options={DESIGN_FORMATS} value={dm.services.design_formats} onChange={(v) => patchDm({ services: { ...dm.services, design_formats: v } })} />
            <MultiCheck label="Language Options" options={LANGUAGE_OPTIONS} value={dm.services.language_options} onChange={(v) => patchDm({ services: { ...dm.services, language_options: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="2">
          <Accordion.Header>Section 3 — Core Intelligence</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Design Style" options={DESIGN_STYLE_INVITATION} value={dm.intelligence.design_style} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, design_style: v } })} />
            <SelectField label="Customization Level" options={CUSTOMIZATION_LEVEL} value={dm.intelligence.customization_level} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, customization_level: v } })} />
            <SelectField label="Theme Matching Capability" options={THEME_MATCHING} value={dm.intelligence.theme_matching_capability} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, theme_matching_capability: v } })} />
            <MultiCheck label="Personalization Options" options={PERSONALIZATION_OPTIONS_INVITATION} value={dm.intelligence.personalization_options} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, personalization_options: v } })} />
            <MultiCheck label="Print Material Options" options={PRINT_MATERIAL_OPTIONS} value={dm.intelligence.print_material_options} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, print_material_options: v } })} />
            <MultiCheck label="Special Features" options={SPECIAL_FEATURES} value={dm.intelligence.special_features} onChange={(v) => patchDm({ intelligence: { ...dm.intelligence, special_features: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="3">
          <Accordion.Header>Section 4 — Digital Intelligence</Accordion.Header>
          <Accordion.Body>
            <SelectField label="E-Invite Formats" options={E_INVITE_FORMATS} value={dm.digital_intelligence.e_invite_formats} onChange={(v) => patchDm({ digital_intelligence: { ...dm.digital_intelligence, e_invite_formats: v } })} />
            <MultiCheck label="Website Invite Features" options={WEBSITE_INVITE_FEATURES} value={dm.digital_intelligence.website_invite_features} onChange={(v) => patchDm({ digital_intelligence: { ...dm.digital_intelligence, website_invite_features: v } })} />
            <YesNoField groupName="invRsvp" label="RSVP Tracking" value={dm.digital_intelligence.rsvp_tracking} onChange={(v) => patchDm({ digital_intelligence: { ...dm.digital_intelligence, rsvp_tracking: v } })} />
            <YesNoField groupName="invWa" label="WhatsApp Integration" value={dm.digital_intelligence.whatsapp_integration} onChange={(v) => patchDm({ digital_intelligence: { ...dm.digital_intelligence, whatsapp_integration: v } })} />
            <YesNoField groupName="invQr" label="QR Code Integration" value={dm.digital_intelligence.qr_code_integration} onChange={(v) => patchDm({ digital_intelligence: { ...dm.digital_intelligence, qr_code_integration: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="4">
          <Accordion.Header>Section 5 — Production & Logistics</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Minimum Order Quantity (Physical)" options={MIN_ORDER_QTY} value={dm.production.minimum_order_quantity} onChange={(v) => patchDm({ production: { ...dm.production, minimum_order_quantity: v } })} />
            <SelectField label="Maximum Order Capacity" options={MAX_ORDER_CAPACITY} value={dm.production.maximum_order_capacity} onChange={(v) => patchDm({ production: { ...dm.production, maximum_order_capacity: v } })} />
            <SelectField label="Turnaround Time" options={TURNAROUND_TIME} value={dm.production.turnaround_time} onChange={(v) => patchDm({ production: { ...dm.production, turnaround_time: v } })} />
            <YesNoField groupName="invSample" label="Sample Availability" value={dm.production.sample_availability} onChange={(v) => patchDm({ production: { ...dm.production, sample_availability: v } })} />
            <SelectField label="Proofing Process" options={PROOFING_PROCESS} value={dm.production.proofing_process} onChange={(v) => patchDm({ production: { ...dm.production, proofing_process: v } })} />
            <SelectField label="Packaging Options" options={PACKAGING_OPTIONS} value={dm.production.packaging_options} onChange={(v) => patchDm({ production: { ...dm.production, packaging_options: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Pricing Logic</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Pricing Model" options={PRICING_MODEL_INVITATION} value={dm.pricing.pricing_model} onChange={(v) => patchDm({ pricing: { ...dm.pricing, pricing_model: v } })} />
            <SelectField label="Starting Price Range" options={STARTING_PRICE_RANGE} value={dm.pricing.starting_price_range} onChange={(v) => patchDm({ pricing: { ...dm.pricing, starting_price_range: v } })} />
            <SelectField label="Digital Invite Pricing" options={DIGITAL_INVITE_PRICING} value={dm.pricing.digital_invite_pricing} onChange={(v) => patchDm({ pricing: { ...dm.pricing, digital_invite_pricing: v } })} />
            <MultiCheck label="Includes" options={INCLUDES_INVITATION} value={dm.pricing.includes} onChange={(v) => patchDm({ pricing: { ...dm.pricing, includes: v } })} />
            <MultiCheck label="Add-ons" options={ADDONS_INVITATION} value={dm.pricing.add_ons} onChange={(v) => patchDm({ pricing: { ...dm.pricing, add_ons: v } })} />
            <SelectField label="Negotiation Flexibility" options={NEGOTIATION} value={dm.pricing.negotiation_flexibility} onChange={(v) => patchDm({ pricing: { ...dm.pricing, negotiation_flexibility: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Scale & Operations</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Orders Per Month Capacity" options={ORDERS_PER_MONTH} value={dm.scale.orders_per_month_capacity} onChange={(v) => patchDm({ scale: { ...dm.scale, orders_per_month_capacity: v } })} />
            <SelectField label="Team Size" options={TEAM_SIZE} value={dm.scale.team_size} onChange={(v) => patchDm({ scale: { ...dm.scale, team_size: v } })} />
            <YesNoField groupName="invParallel" label="Parallel Order Handling" value={dm.scale.parallel_order_handling} onChange={(v) => patchDm({ scale: { ...dm.scale, parallel_order_handling: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="7">
          <Accordion.Header>Section 8 — Workflow & Booking</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Advance Booking Time" options={ADVANCE_BOOKING_TIME} value={dm.workflow.advance_booking_time} onChange={(v) => patchDm({ workflow: { ...dm.workflow, advance_booking_time: v } })} />
            <SelectField label="Booking Advance %" options={BOOKING_ADVANCE} value={dm.workflow.booking_advance_percent} onChange={(v) => patchDm({ workflow: { ...dm.workflow, booking_advance_percent: v } })} />
            <SelectField label="Cancellation Policy" options={CANCELLATION_POLICY} value={dm.workflow.cancellation_policy} onChange={(v) => patchDm({ workflow: { ...dm.workflow, cancellation_policy: v } })} />
            <SelectField label="Client Coordination" options={CLIENT_COORDINATION} value={dm.workflow.client_coordination} onChange={(v) => patchDm({ workflow: { ...dm.workflow, client_coordination: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="8">
          <Accordion.Header>Section 9 — Portfolio Tagging</Accordion.Header>
          <Accordion.Body>
            <div className="mb-3">
              <label className="form-label fw-semibold">Design Tags</label>
              <Form.Control className="fs-14" value={dm.portfolio.design_tags} onChange={(e) => patchDm({ portfolio: { ...dm.portfolio, design_tags: e.target.value } })} />
            </div>
            <div className="mb-3">
              <label className="form-label fw-semibold">Format Tags</label>
              <Form.Control className="fs-14" value={dm.portfolio.format_tags} onChange={(e) => patchDm({ portfolio: { ...dm.portfolio, format_tags: e.target.value } })} />
            </div>
            <div className="mb-3">
              <label className="form-label fw-semibold">Event Tags</label>
              <Form.Control className="fs-14" value={dm.portfolio.event_tags} onChange={(e) => patchDm({ portfolio: { ...dm.portfolio, event_tags: e.target.value } })} />
            </div>
          </Accordion.Body>
        </Accordion.Item>
      </Accordion>

      {!embedded && (
        <button type="button" className="btn btn-primary mt-3 fs-14" onClick={save}>
          Save Invitation Master Profile
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

export default InvitationMasterProfile;
