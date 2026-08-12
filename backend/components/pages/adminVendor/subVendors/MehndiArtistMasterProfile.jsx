import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  ARTIST_TYPE,
  TRAVEL_AVAILABILITY,
  TEAM_SIZE,
  SERVICES_OFFERED,
  COVERAGE_TYPE,
  MEHENDI_STYLE,
  DESIGN_COMPLEXITY,
  BEST_KNOWN_FOR,
  PERSONALIZATION_OPTIONS,
  BRIDAL_COVERAGE,
  BRIDAL_DURATION,
  GUESTS_PER_HOUR,
  MAX_GUESTS_COVERED,
  GUEST_PRICING_MODEL,
  MEHENDI_TYPE,
  COLOR_GUARANTEE,
  FUNCTIONS_COVERED,
  BEST_FOR,
  APPLICATION_SPEED,
  TRAVEL_CHARGES,
  MINIMUM_BOOKING_VALUE,
  ADVANCE_PERCENTAGE,
  BOOKING_TIMELINE,
  CANCELLATION_POLICY,
  FAQ_MAX_GUESTS_COVERED,
  FAQ_MEHENDI_TYPE,
  FAQ_BRIDAL_COVERAGE,
  FAQ_BRIDAL_DURATION,
  FAQ_PRICING_MODEL,
  FAQ_CANCELLATION_POLICY,
  emptyMehndiArtistMaster,
} from "./mehndiArtistMasterConstants";

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
    } else {
      out[k] = pv;
    }
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
          className="fs-14"
        />
      ))}
    </div>
  </div>
);

const MehndiArtistMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const mm = useMemo(() => {
    const raw =
      formData.mehndi_artist_master ||
      formData.attributes?.mehndi_artist_master;
    if (raw && typeof raw === "object")
      return mergeDeep(emptyMehndiArtistMaster(), raw);
    return emptyMehndiArtistMaster();
  }, [formData.mehndi_artist_master, formData.attributes?.mehndi_artist_master]);

  const patchMm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(
          prev.mehndi_artist_master ||
          prev.attributes?.mehndi_artist_master ||
          emptyMehndiArtistMaster(),
          partial
        );
        return {
          ...prev,
          mehndi_artist_master: next,
          attributes: { ...(prev.attributes || {}), mehndi_artist_master: next },
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
      <h4 className="mb-2 fw-bold">Mehndi artist master profile</h4>
      <p className="text-muted fs-14 mb-4">
        Structured mehndi artist attributes for storefront and AI FAQ matching.
      </p>

      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        {/* ── Section 1 — Basic Identity ── */}
        <Accordion.Item eventKey="0">
          <Accordion.Header>Section 1 — Basic identity</Accordion.Header>
          <Accordion.Body>
            {/* <div className="mb-3">
              <label className="form-label fw-semibold">Artist / Brand name</label>
              <Form.Control
                className="fs-14"
                placeholder="e.g. Priya Mehendi Art"
                value={mm.identity.artist_brand_name}
                onChange={(e) =>
                  patchMm({ identity: { ...mm.identity, artist_brand_name: e.target.value } })
                }
              />
            </div> */}
            <SelectField
              label="Artist type"
              options={ARTIST_TYPE}
              value={mm.identity.artist_type}
              onChange={(v) => patchMm({ identity: { ...mm.identity, artist_type: v } })}
            />
            <div className="mb-3">
              <label className="form-label fw-semibold">Years of experience</label>
              <Form.Control
                type="number"
                className="fs-14"
                value={mm.identity.years_of_experience}
                onChange={(e) =>
                  patchMm({ identity: { ...mm.identity, years_of_experience: e.target.value } })
                }
              />
            </div>
            <div className="mb-3">
              <label className="form-label fw-semibold">City</label>
              <Form.Control
                className="fs-14"
                value={mm.identity.city}
                onChange={(e) =>
                  patchMm({ identity: { ...mm.identity, city: e.target.value } })
                }
              />
            </div>
            <SelectField
              label="Travel availability"
              options={TRAVEL_AVAILABILITY}
              value={mm.identity.travel_availability}
              onChange={(v) =>
                patchMm({ identity: { ...mm.identity, travel_availability: v } })
              }
            />
            <SelectField
              label="Team size"
              options={TEAM_SIZE}
              value={mm.identity.team_size}
              onChange={(v) => patchMm({ identity: { ...mm.identity, team_size: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* ── Section 2 — Services Offered ── */}
        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Services offered</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Services offered"
              options={SERVICES_OFFERED}
              value={mm.services.services_offered}
              onChange={(v) =>
                patchMm({ services: { ...mm.services, services_offered: v } })
              }
            />
            <MultiCheck
              label="Coverage type"
              options={COVERAGE_TYPE}
              value={mm.services.coverage_type}
              onChange={(v) =>
                patchMm({ services: { ...mm.services, coverage_type: v } })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* ── Section 3 — Design Style Intelligence ── */}
        <Accordion.Item eventKey="2">
          <Accordion.Header>Section 3 — Design style intelligence</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Mehendi style"
              options={MEHENDI_STYLE}
              value={mm.style_intelligence.mehendi_style}
              onChange={(v) =>
                patchMm({ style_intelligence: { ...mm.style_intelligence, mehendi_style: v } })
              }
            />
            <SelectField
              label="Design complexity"
              options={DESIGN_COMPLEXITY}
              value={mm.style_intelligence.design_complexity}
              onChange={(v) =>
                patchMm({ style_intelligence: { ...mm.style_intelligence, design_complexity: v } })
              }
            />
            <MultiCheck
              label="Best known for"
              options={BEST_KNOWN_FOR}
              value={mm.style_intelligence.best_known_for}
              onChange={(v) =>
                patchMm({ style_intelligence: { ...mm.style_intelligence, best_known_for: v } })
              }
            />
            <YesNoField
              groupName="customDesigns"
              label="Custom designs available"
              value={mm.style_intelligence.custom_designs_available}
              onChange={(v) =>
                patchMm({
                  style_intelligence: {
                    ...mm.style_intelligence,
                    custom_designs_available: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Personalization options"
              options={PERSONALIZATION_OPTIONS}
              value={mm.style_intelligence.personalization_options}
              onChange={(v) =>
                patchMm({
                  style_intelligence: {
                    ...mm.style_intelligence,
                    personalization_options: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* ── Section 4 — Bridal Mehendi Details ── */}
        <Accordion.Item eventKey="3">
          <Accordion.Header>Section 4 — Bridal mehendi details</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Bridal mehendi coverage"
              options={BRIDAL_COVERAGE}
              value={mm.bridal_details.bridal_coverage}
              onChange={(v) =>
                patchMm({ bridal_details: { ...mm.bridal_details, bridal_coverage: v } })
              }
            />
            <SelectField
              label="Bridal mehendi duration"
              options={BRIDAL_DURATION}
              value={mm.bridal_details.bridal_duration}
              onChange={(v) =>
                patchMm({ bridal_details: { ...mm.bridal_details, bridal_duration: v } })
              }
            />
            <div className="mb-3">
              <label className="form-label fw-semibold">Bridal mehendi starting price (₹)</label>
              <Form.Control
                type="number"
                className="fs-14"
                value={mm.bridal_details.bridal_starting_price}
                onChange={(e) =>
                  patchMm({
                    bridal_details: {
                      ...mm.bridal_details,
                      bridal_starting_price: e.target.value,
                    },
                  })
                }
              />
            </div>
          </Accordion.Body>
        </Accordion.Item>

        {/* ── Section 5 — Guest Handling Capacity ── */}
        <Accordion.Item eventKey="4">
          <Accordion.Header>Section 5 — Guest handling capacity</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Guests covered per hour"
              options={GUESTS_PER_HOUR}
              value={mm.guest_capacity.guests_per_hour}
              onChange={(v) =>
                patchMm({ guest_capacity: { ...mm.guest_capacity, guests_per_hour: v } })
              }
            />
            <SelectField
              label="Max guests covered"
              options={MAX_GUESTS_COVERED}
              value={mm.guest_capacity.max_guests_covered}
              onChange={(v) =>
                patchMm({ guest_capacity: { ...mm.guest_capacity, max_guests_covered: v } })
              }
            />
            <SelectField
              label="Guest mehendi pricing"
              options={GUEST_PRICING_MODEL}
              value={mm.guest_capacity.guest_pricing_model}
              onChange={(v) =>
                patchMm({ guest_capacity: { ...mm.guest_capacity, guest_pricing_model: v } })
              }
            />
            <YesNoField
              groupName="teamSupportGuests"
              label="Team support for guests"
              value={mm.guest_capacity.team_support_for_guests}
              onChange={(v) =>
                patchMm({
                  guest_capacity: { ...mm.guest_capacity, team_support_for_guests: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* ── Section 6 — Material & Quality ── */}
        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Material &amp; quality</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Mehendi type"
              options={MEHENDI_TYPE}
              value={mm.material_quality.mehendi_type}
              onChange={(v) =>
                patchMm({ material_quality: { ...mm.material_quality, mehendi_type: v } })
              }
            />
            <SelectField
              label="Color guarantee"
              options={COLOR_GUARANTEE}
              value={mm.material_quality.color_guarantee}
              onChange={(v) =>
                patchMm({ material_quality: { ...mm.material_quality, color_guarantee: v } })
              }
            />
            <YesNoField
              groupName="aftercareInstructions"
              label="Aftercare instructions provided"
              value={mm.material_quality.aftercare_instructions_provided}
              onChange={(v) =>
                patchMm({
                  material_quality: {
                    ...mm.material_quality,
                    aftercare_instructions_provided: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="allergiesConsideration"
              label="Allergies consideration"
              value={mm.material_quality.allergies_consideration}
              onChange={(v) =>
                patchMm({
                  material_quality: {
                    ...mm.material_quality,
                    allergies_consideration: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* ── Section 7 — Event Suitability ── */}
        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Event suitability</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Functions covered"
              options={FUNCTIONS_COVERED}
              value={mm.event_suitability.functions_covered}
              onChange={(v) =>
                patchMm({
                  event_suitability: { ...mm.event_suitability, functions_covered: v },
                })
              }
            />
            <MultiCheck
              label="Best for"
              options={BEST_FOR}
              value={mm.event_suitability.best_for}
              onChange={(v) =>
                patchMm({ event_suitability: { ...mm.event_suitability, best_for: v } })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* ── Section 8 — Speed & Execution ── */}
        <Accordion.Item eventKey="7">
          <Accordion.Header>Section 8 — Speed &amp; execution intelligence</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Application speed"
              options={APPLICATION_SPEED}
              value={mm.speed_execution.application_speed}
              onChange={(v) =>
                patchMm({ speed_execution: { ...mm.speed_execution, application_speed: v } })
              }
            />
            <YesNoField
              groupName="parallelArtists"
              label="Parallel artists available"
              value={mm.speed_execution.parallel_artists_available}
              onChange={(v) =>
                patchMm({
                  speed_execution: {
                    ...mm.speed_execution,
                    parallel_artists_available: v,
                  },
                })
              }
            />
            <YesNoField
              groupName="multipleEvents"
              label="Multiple events handling"
              value={mm.speed_execution.multiple_events_handling}
              onChange={(v) =>
                patchMm({
                  speed_execution: {
                    ...mm.speed_execution,
                    multiple_events_handling: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* ── Section 9 — Pricing & Travel ── */}
        <Accordion.Item eventKey="8">
          <Accordion.Header>Section 9 — Pricing &amp; travel</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Travel charges"
              options={TRAVEL_CHARGES}
              value={mm.pricing_travel.travel_charges}
              onChange={(v) =>
                patchMm({ pricing_travel: { ...mm.pricing_travel, travel_charges: v } })
              }
            />
            <YesNoField
              groupName="stayRequirement"
              label="Stay requirement"
              value={mm.pricing_travel.stay_requirement}
              onChange={(v) =>
                patchMm({ pricing_travel: { ...mm.pricing_travel, stay_requirement: v } })
              }
            />
            <SelectField
              label="Minimum booking value"
              options={MINIMUM_BOOKING_VALUE}
              value={mm.pricing_travel.minimum_booking_value}
              onChange={(v) =>
                patchMm({
                  pricing_travel: { ...mm.pricing_travel, minimum_booking_value: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* ── Section 10 — Workflow & Booking ── */}
        <Accordion.Item eventKey="9">
          <Accordion.Header>Section 10 — Workflow &amp; booking</Accordion.Header>
          <Accordion.Body>
            <YesNoField
              groupName="advanceRequired"
              label="Advance required"
              value={mm.workflow.advance_required}
              onChange={(v) =>
                patchMm({ workflow: { ...mm.workflow, advance_required: v } })
              }
            />
            <SelectField
              label="Advance percentage"
              options={ADVANCE_PERCENTAGE}
              value={mm.workflow.advance_percentage}
              onChange={(v) =>
                patchMm({ workflow: { ...mm.workflow, advance_percentage: v } })
              }
            />
            <SelectField
              label="Booking timeline"
              options={BOOKING_TIMELINE}
              value={mm.workflow.booking_timeline}
              onChange={(v) =>
                patchMm({ workflow: { ...mm.workflow, booking_timeline: v } })
              }
            />
            <SelectField
              label="Cancellation policy"
              options={CANCELLATION_POLICY}
              value={mm.workflow.cancellation_policy}
              onChange={(v) =>
                patchMm({ workflow: { ...mm.workflow, cancellation_policy: v } })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        {/* ── Section 11 — Portfolio Intelligence ── */}
        <Accordion.Item eventKey="10">
          <Accordion.Header>Section 11 — Portfolio intelligence tagging</Accordion.Header>
          <Accordion.Body>
            <p className="text-muted fs-14">
              Upload mehendi designs in the Photos tab. Use this block for default tagging
              metadata — enables AI queries like "Show me intricate bridal mehendi with
              portrait design".
            </p>
            <div className="mb-3">
              <label className="form-label fw-semibold">Default tags</label>
              <Form.Control
                className="fs-14"
                value={mm.portfolio_tagging.tags}
                onChange={(e) =>
                  patchMm({
                    portfolio_tagging: { ...mm.portfolio_tagging, tags: e.target.value },
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
                value={mm.portfolio_tagging.notes}
                onChange={(e) =>
                  patchMm({
                    portfolio_tagging: { ...mm.portfolio_tagging, notes: e.target.value },
                  })
                }
              />
            </div>
          </Accordion.Body>
        </Accordion.Item>

      </Accordion>

      {!embedded && (
        <button type="button" className="btn btn-primary mt-3 fs-14" onClick={save}>
          Save mehndi artist master profile
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

export default MehndiArtistMasterProfile;
