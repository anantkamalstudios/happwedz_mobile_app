import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  VENDOR_TYPE,
  SERVICE_PRESENCE,
  LANGUAGES_SPOKEN,
  YEARS_OF_EXPERIENCE,
  RELIGIOUS_TRADITION,
  CEREMONY_TYPES,
  SAMAGRI_PROVIDED,
  RITUAL_DURATION,
  RITUAL_COMPLEXITY,
  RITUAL_LANGUAGE_PREFERENCE,
  SETUP_TIME_REQUIRED,
  PRICE_RANGE,
  PRICING_MODEL,
  TRAVEL_CHARGES,
  SAMAGRI_CHARGES,
  DAKSHINA_FLEXIBILITY,
  EVENTS_PER_DAY,
  TEAM_SIZE,
  BOOKING_WINDOW,
  ARRIVAL_TIMING,
  PAYMENT_MODES,
  ADVANCE_PAYMENT_PERCENTAGE,
  STYLE_TAGS,
  AUDIENCE_TAGS,
  USAGE_TAGS,
  PRICE_SEGMENT_TAGS,
  emptyPanditMaster,
} from "./panditMasterConstants";

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

const PanditMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const pm = useMemo(() => {
    const raw = formData.pandit_master || formData.attributes?.pandit_master;
    if (raw && typeof raw === "object") return mergeDeep(emptyPanditMaster(), raw);
    return emptyPanditMaster();
  }, [formData.pandit_master, formData.attributes?.pandit_master]);

  const patchPm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(
          prev.pandit_master || prev.attributes?.pandit_master || emptyPanditMaster(),
          partial
        );
        return {
          ...prev,
          pandit_master: next,
          attributes: { ...(prev.attributes || {}), pandit_master: next },
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
      <h4 className="mb-2 fw-bold">Wedding pandit master profile</h4>
      <p className="text-muted fs-14 mb-4">
        Structured pandit attributes for storefront and AI FAQ matching.
      </p>

      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        {/* Section 1 — Basic Identity */}
        <Accordion.Item eventKey="0">
          <Accordion.Header>Section 1 — Basic identity</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Vendor type"
              options={VENDOR_TYPE}
              value={pm.identity.vendor_type}
              onChange={(v) => patchPm({ identity: { ...pm.identity, vendor_type: v } })}
            />
            {/* <div className="mb-3">
              <label className="form-label fw-semibold">Pandit name</label>
              <Form.Control
                type="text"
                className="fs-14"
                value={pm.identity.pandit_name}
                onChange={(e) => patchPm({ identity: { ...pm.identity, pandit_name: e.target.value } })}
              />
            </div> */}
            <MultiCheck
              label="Service presence"
              options={SERVICE_PRESENCE}
              value={pm.identity.service_presence}
              onChange={(v) => patchPm({ identity: { ...pm.identity, service_presence: v } })}
            />
            <div className="mb-3">
              <label className="form-label fw-semibold">City base</label>
              <Form.Control
                type="text"
                className="fs-14"
                value={pm.identity.city_base}
                onChange={(e) => patchPm({ identity: { ...pm.identity, city_base: e.target.value } })}
              />
            </div>
            <MultiCheck
              label="Languages spoken"
              options={LANGUAGES_SPOKEN}
              value={pm.identity.languages_spoken}
              onChange={(v) => patchPm({ identity: { ...pm.identity, languages_spoken: v } })}
            />
            <SelectField
              label="Years of experience"
              options={YEARS_OF_EXPERIENCE}
              value={pm.identity.years_of_experience}
              onChange={(v) => patchPm({ identity: { ...pm.identity, years_of_experience: v } })}
            />
            <MultiCheck
              label="Religious tradition"
              options={RELIGIOUS_TRADITION}
              value={pm.identity.religious_tradition}
              onChange={(v) => patchPm({ identity: { ...pm.identity, religious_tradition: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 2 — Services Offered */}
        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Services offered</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Ceremony types"
              options={CEREMONY_TYPES}
              value={pm.services_offered.ceremony_types}
              onChange={(v) => patchPm({ services_offered: { ...pm.services_offered, ceremony_types: v } })}
            />
            <YesNoField
              groupName="destinationWeddingServices"
              label="Destination wedding services"
              value={pm.services_offered.destination_wedding_services}
              onChange={(v) => patchPm({ services_offered: { ...pm.services_offered, destination_wedding_services: v } })}
            />
            <YesNoField
              groupName="virtualCeremonySupport"
              label="Virtual ceremony support"
              value={pm.services_offered.virtual_ceremony_support}
              onChange={(v) => patchPm({ services_offered: { ...pm.services_offered, virtual_ceremony_support: v } })}
            />
            <YesNoField
              groupName="ritualExplanationProvided"
              label="Ritual explanation provided"
              value={pm.services_offered.ritual_explanation_provided}
              onChange={(v) => patchPm({ services_offered: { ...pm.services_offered, ritual_explanation_provided: v } })}
            />
            <YesNoField
              groupName="customizedRituals"
              label="Customized rituals based on culture"
              value={pm.services_offered.customized_rituals}
              onChange={(v) => patchPm({ services_offered: { ...pm.services_offered, customized_rituals: v } })}
            />
            <SelectField
              label="Samagri (pooja items) provided"
              options={SAMAGRI_PROVIDED}
              value={pm.services_offered.samagri_provided}
              onChange={(v) => patchPm({ services_offered: { ...pm.services_offered, samagri_provided: v } })}
            />
            <YesNoField
              groupName="assistantPanditsIncluded"
              label="Assistant pandits included"
              value={pm.services_offered.assistant_pandits_included}
              onChange={(v) => patchPm({ services_offered: { ...pm.services_offered, assistant_pandits_included: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 3 — Core Intelligence */}
        <Accordion.Item eventKey="2">
          <Accordion.Header>Section 3 — Core intelligence</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Ritual duration options"
              options={RITUAL_DURATION}
              value={pm.core_intelligence.ritual_duration_options}
              onChange={(v) => patchPm({ core_intelligence: { ...pm.core_intelligence, ritual_duration_options: v } })}
            />
            <SelectField
              label="Ritual complexity level"
              options={RITUAL_COMPLEXITY}
              value={pm.core_intelligence.ritual_complexity_level}
              onChange={(v) => patchPm({ core_intelligence: { ...pm.core_intelligence, ritual_complexity_level: v } })}
            />
            <YesNoField
              groupName="muhuratGuidanceProvided"
              label="Muhurat guidance provided"
              value={pm.core_intelligence.muhurat_guidance_provided}
              onChange={(v) => patchPm({ core_intelligence: { ...pm.core_intelligence, muhurat_guidance_provided: v } })}
            />
            <YesNoField
              groupName="horoscopeMatching"
              label="Horoscope matching (Kundli Milan)"
              value={pm.core_intelligence.horoscope_matching}
              onChange={(v) => patchPm({ core_intelligence: { ...pm.core_intelligence, horoscope_matching: v } })}
            />
            <MultiCheck
              label="Ritual language preference"
              options={RITUAL_LANGUAGE_PREFERENCE}
              value={pm.core_intelligence.ritual_language_preference}
              onChange={(v) => patchPm({ core_intelligence: { ...pm.core_intelligence, ritual_language_preference: v } })}
            />
            <YesNoField
              groupName="fireRitualHavanIncluded"
              label="Fire ritual (Havan) included"
              value={pm.core_intelligence.fire_ritual_havan_included}
              onChange={(v) => patchPm({ core_intelligence: { ...pm.core_intelligence, fire_ritual_havan_included: v } })}
            />
            <YesNoField
              groupName="interfaithCustomCeremonies"
              label="Interfaith / custom ceremonies"
              value={pm.core_intelligence.interfaith_custom_ceremonies}
              onChange={(v) => patchPm({ core_intelligence: { ...pm.core_intelligence, interfaith_custom_ceremonies: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 4 — Technical / Product / Skill */}
        <Accordion.Item eventKey="3">
          <Accordion.Header>Section 4 — Technical / product / skill</Accordion.Header>
          <Accordion.Body>
            <YesNoField
              groupName="audioSetupRequirement"
              label="Audio setup requirement"
              value={pm.technical.audio_setup_requirement}
              onChange={(v) => patchPm({ technical: { ...pm.technical, audio_setup_requirement: v } })}
            />
            <YesNoField
              groupName="microphoneUsage"
              label="Microphone usage"
              value={pm.technical.microphone_usage}
              onChange={(v) => patchPm({ technical: { ...pm.technical, microphone_usage: v } })}
            />
            <YesNoField
              groupName="samagriListProvidedInAdvance"
              label="Samagri list provided in advance"
              value={pm.technical.samagri_list_provided_in_advance}
              onChange={(v) => patchPm({ technical: { ...pm.technical, samagri_list_provided_in_advance: v } })}
            />
            <SelectField
              label="Setup time required before ceremony"
              options={SETUP_TIME_REQUIRED}
              value={pm.technical.setup_time_required}
              onChange={(v) => patchPm({ technical: { ...pm.technical, setup_time_required: v } })}
            />
            <YesNoField
              groupName="dressCodeProvided"
              label="Dress code provided"
              value={pm.technical.dress_code_provided}
              onChange={(v) => patchPm({ technical: { ...pm.technical, dress_code_provided: v } })}
            />
            <YesNoField
              groupName="documentationRitualBooklet"
              label="Documentation / ritual booklet provided"
              value={pm.technical.documentation_ritual_booklet}
              onChange={(v) => patchPm({ technical: { ...pm.technical, documentation_ritual_booklet: v } })}
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
              value={pm.pricing.price_range}
              onChange={(v) => patchPm({ pricing: { ...pm.pricing, price_range: v } })}
            />
            <SelectField
              label="Pricing model"
              options={PRICING_MODEL}
              value={pm.pricing.pricing_model}
              onChange={(v) => patchPm({ pricing: { ...pm.pricing, pricing_model: v } })}
            />
            <SelectField
              label="Travel charges"
              options={TRAVEL_CHARGES}
              value={pm.pricing.travel_charges}
              onChange={(v) => patchPm({ pricing: { ...pm.pricing, travel_charges: v } })}
            />
            <SelectField
              label="Samagri charges"
              options={SAMAGRI_CHARGES}
              value={pm.pricing.samagri_charges}
              onChange={(v) => patchPm({ pricing: { ...pm.pricing, samagri_charges: v } })}
            />
            <SelectField
              label="Dakshina flexibility"
              options={DAKSHINA_FLEXIBILITY}
              value={pm.pricing.dakshina_flexibility}
              onChange={(v) => patchPm({ pricing: { ...pm.pricing, dakshina_flexibility: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* Section 6 — Scale & Capacity */}
        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Scale &amp; capacity</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Events per day capacity"
              options={EVENTS_PER_DAY}
              value={pm.scale_capacity.events_per_day}
              onChange={(v) => patchPm({ scale_capacity: { ...pm.scale_capacity, events_per_day: v } })}
            />
            <SelectField
              label="Team size (assistants)"
              options={TEAM_SIZE}
              value={pm.scale_capacity.team_size}
              onChange={(v) => patchPm({ scale_capacity: { ...pm.scale_capacity, team_size: v } })}
            />
            <YesNoField
              groupName="multiLocationHandling"
              label="Multi-location handling"
              value={pm.scale_capacity.multi_location_handling}
              onChange={(v) => patchPm({ scale_capacity: { ...pm.scale_capacity, multi_location_handling: v } })}
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
              value={pm.workflow.advance_booking_required}
              onChange={(v) => patchPm({ workflow: { ...pm.workflow, advance_booking_required: v } })}
            />
            <SelectField
              label="Booking window"
              options={BOOKING_WINDOW}
              value={pm.workflow.booking_window}
              onChange={(v) => patchPm({ workflow: { ...pm.workflow, booking_window: v } })}
            />
            <YesNoField
              groupName="preCeremonyConsultation"
              label="Pre-ceremony consultation"
              value={pm.workflow.pre_ceremony_consultation}
              onChange={(v) => patchPm({ workflow: { ...pm.workflow, pre_ceremony_consultation: v } })}
            />
            <YesNoField
              groupName="ritualCustomizationDiscussion"
              label="Ritual customization discussion"
              value={pm.workflow.ritual_customization_discussion}
              onChange={(v) => patchPm({ workflow: { ...pm.workflow, ritual_customization_discussion: v } })}
            />
            <SelectField
              label="Arrival timing before ceremony"
              options={ARRIVAL_TIMING}
              value={pm.workflow.arrival_timing}
              onChange={(v) => patchPm({ workflow: { ...pm.workflow, arrival_timing: v } })}
            />
            <MultiCheck
              label="Payment modes"
              options={PAYMENT_MODES}
              value={pm.workflow.payment_modes}
              onChange={(v) => patchPm({ workflow: { ...pm.workflow, payment_modes: v } })}
            />
            <SelectField
              label="Advance payment percentage"
              options={ADVANCE_PAYMENT_PERCENTAGE}
              value={pm.workflow.advance_payment_percentage}
              onChange={(v) => patchPm({ workflow: { ...pm.workflow, advance_payment_percentage: v } })}
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
              value={pm.portfolio_tagging.style_tags}
              onChange={(v) => patchPm({ portfolio_tagging: { ...pm.portfolio_tagging, style_tags: v } })}
            />
            <MultiCheck
              label="Audience tags"
              options={AUDIENCE_TAGS}
              value={pm.portfolio_tagging.audience_tags}
              onChange={(v) => patchPm({ portfolio_tagging: { ...pm.portfolio_tagging, audience_tags: v } })}
            />
            <MultiCheck
              label="Usage tags"
              options={USAGE_TAGS}
              value={pm.portfolio_tagging.usage_tags}
              onChange={(v) => patchPm({ portfolio_tagging: { ...pm.portfolio_tagging, usage_tags: v } })}
            />
            <SelectField
              label="Price segment tags"
              options={PRICE_SEGMENT_TAGS}
              value={pm.portfolio_tagging.price_segment_tags}
              onChange={(v) => patchPm({ portfolio_tagging: { ...pm.portfolio_tagging, price_segment_tags: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

      </Accordion>

      {!embedded && (
        <button type="button" className="btn btn-primary mt-3 fs-14" onClick={save}>
          Save pandit master profile
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

export default PanditMasterProfile;
