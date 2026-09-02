import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  DECORATOR_TYPE,
  SERVICE_COVERAGE_DECORATOR,
  TEAM_SIZE,
  SERVICES_OFFERED_DECORATOR,
  DECOR_SCOPE,
  THEMES_EXPERTISE,
  DECOR_STYLE,
  BEST_KNOWN_FOR_DECORATOR,
  IDEAL_WEDDING_TYPE,
  MATERIALS_USED,
  FLORAL_EXPERTISE,
  MAX_GUEST_CAPACITY,
  SETUP_TIME_REQUIRED,
  FUNCTIONS_COVERED_DECORATOR,
  BEST_FUNCTION_EXPERTISE,
  PRICING_TYPE_DECORATOR,
  BUDGET_RANGE_HANDLED,
  FRESH_FLOWER_COST,
  TRANSPORTATION_CHARGES,
  LIGHTING_PROVIDED,
  SPECIAL_EFFECTS,
  ADVANCE_PERCENTAGE,
  BOOKING_TIMELINE,
  CANCELLATION_POLICY_DECORATOR,
  REVISION_FLEXIBILITY,
  emptyDecoratorMaster,
} from "./decoratorMasterConstants";

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

const DecoratorMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const dm = useMemo(() => {
    const raw = formData.decorator_master || formData.attributes?.decorator_master;
    if (raw && typeof raw === "object") return mergeDeep(emptyDecoratorMaster(), raw);
    return emptyDecoratorMaster();
  }, [formData.decorator_master, formData.attributes?.decorator_master]);

  const patchDm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const current =
          prev.decorator_master ||
          prev.attributes?.decorator_master ||
          emptyDecoratorMaster();
        const next = mergeDeep(current, partial);
        return {
          ...prev,
          decorator_master: next,
          attributes: { ...(prev.attributes || {}), decorator_master: next },
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
      <h4 className="mb-2 fw-bold">Decorator Master Profile</h4>
      <p className="text-muted fs-14 mb-4">Structured decorator data for search, filters, portfolio tagging, and AI FAQ.</p>
      
      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        <Accordion.Item eventKey="0">
          <Accordion.Header>Section 1 — Basic Identity</Accordion.Header>
          <Accordion.Body>
            <div className="mb-3">
              <label className="form-label fw-semibold">Years of Experience</label>
              <Form.Control type="number" className="fs-14" value={dm.identity.years_of_experience} onChange={(e) => patchDm({ identity: { ...dm.identity, years_of_experience: e.target.value } })} />
            </div>
            <div className="mb-3">
              <label className="form-label fw-semibold">City</label>
              <Form.Control className="fs-14" value={dm.identity.city} onChange={(e) => patchDm({ identity: { ...dm.identity, city: e.target.value } })} />
            </div>
            <SelectField label="Service Coverage" options={SERVICE_COVERAGE_DECORATOR} value={dm.identity.service_coverage} onChange={(v) => patchDm({ identity: { ...dm.identity, service_coverage: v } })} />
            <SelectField label="Team Size" options={TEAM_SIZE} value={dm.identity.team_size} onChange={(v) => patchDm({ identity: { ...dm.identity, team_size: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Services Offered</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Services Offered" options={SERVICES_OFFERED_DECORATOR} value={dm.services.services_offered} onChange={(v) => patchDm({ services: { ...dm.services, services_offered: v } })} />
            <MultiCheck label="Decor Scope" options={DECOR_SCOPE} value={dm.services.decor_scope} onChange={(v) => patchDm({ services: { ...dm.services, decor_scope: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="2">
          <Accordion.Header>Section 3 — Theme & Style Intelligence</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Themes Expertise" options={THEMES_EXPERTISE} value={dm.theme_style.themes_expertise} onChange={(v) => patchDm({ theme_style: { ...dm.theme_style, themes_expertise: v } })} />
            <MultiCheck label="Decor Style" options={DECOR_STYLE} value={dm.theme_style.decor_style} onChange={(v) => patchDm({ theme_style: { ...dm.theme_style, decor_style: v } })} />
            <MultiCheck label="Best Known For" options={BEST_KNOWN_FOR_DECORATOR} value={dm.theme_style.best_known_for} onChange={(v) => patchDm({ theme_style: { ...dm.theme_style, best_known_for: v } })} />
            <MultiCheck label="Ideal Wedding Type" options={IDEAL_WEDDING_TYPE} value={dm.theme_style.ideal_wedding_type} onChange={(v) => patchDm({ theme_style: { ...dm.theme_style, ideal_wedding_type: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="3">
          <Accordion.Header>Section 4 — Material & Design Capability</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Materials Used" options={MATERIALS_USED} value={dm.material_design.materials_used} onChange={(v) => patchDm({ material_design: { ...dm.material_design, materials_used: v } })} />
            <SelectField label="Floral Expertise" options={FLORAL_EXPERTISE} value={dm.material_design.floral_expertise} onChange={(v) => patchDm({ material_design: { ...dm.material_design, floral_expertise: v } })} />
            <YesNoField groupName="decCustomFab" label="Custom Fabrication" value={dm.material_design.custom_fabrication} onChange={(v) => patchDm({ material_design: { ...dm.material_design, custom_fabrication: v } })} />
            <YesNoField groupName="dec3dDesign" label="3D Design / Mockup Provided" value={dm.material_design.mockup_provided} onChange={(v) => patchDm({ material_design: { ...dm.material_design, mockup_provided: v } })} />
            <YesNoField groupName="decMoodboard" label="Moodboard Support" value={dm.material_design.moodboard_support} onChange={(v) => patchDm({ material_design: { ...dm.material_design, moodboard_support: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="4">
          <Accordion.Header>Section 5 — Event Scale & Execution</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Max Guest Capacity Handled" options={MAX_GUEST_CAPACITY} value={dm.execution.max_guest_capacity} onChange={(v) => patchDm({ execution: { ...dm.execution, max_guest_capacity: v } })} />
            <SelectField label="Setup Time Required" options={SETUP_TIME_REQUIRED} value={dm.execution.setup_time_required} onChange={(v) => patchDm({ execution: { ...dm.execution, setup_time_required: v } })} />
            <YesNoField groupName="decDismantle" label="Dismantling Included" value={dm.execution.dismantling_included} onChange={(v) => patchDm({ execution: { ...dm.execution, dismantling_included: v } })} />
            <YesNoField groupName="decMultipleFunctions" label="Multiple Functions Setup Capability" value={dm.execution.multiple_functions_capability} onChange={(v) => patchDm({ execution: { ...dm.execution, multiple_functions_capability: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Function-Wise Expertise</Accordion.Header>
          <Accordion.Body>
            <MultiCheck label="Functions Covered" options={FUNCTIONS_COVERED_DECORATOR} value={dm.function_expertise.functions_covered} onChange={(v) => patchDm({ function_expertise: { ...dm.function_expertise, functions_covered: v } })} />
            <MultiCheck label="Best Function Expertise" options={BEST_FUNCTION_EXPERTISE} value={dm.function_expertise.best_function_expertise} onChange={(v) => patchDm({ function_expertise: { ...dm.function_expertise, best_function_expertise: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Pricing & Budget Logic</Accordion.Header>
          <Accordion.Body>
            <div className="mb-3">
              <label className="form-label fw-semibold">Starting Decor Price</label>
              <Form.Control type="number" className="fs-14" value={dm.pricing.starting_decor_price} onChange={(e) => patchDm({ pricing: { ...dm.pricing, starting_decor_price: e.target.value } })} />
            </div>
            <SelectField label="Pricing Type" options={PRICING_TYPE_DECORATOR} value={dm.pricing.pricing_type} onChange={(v) => patchDm({ pricing: { ...dm.pricing, pricing_type: v } })} />
            <SelectField label="Budget Range Handled" options={BUDGET_RANGE_HANDLED} value={dm.pricing.budget_range_handled} onChange={(v) => patchDm({ pricing: { ...dm.pricing, budget_range_handled: v } })} />
            <SelectField label="Fresh Flower Cost" options={FRESH_FLOWER_COST} value={dm.pricing.fresh_flower_cost} onChange={(v) => patchDm({ pricing: { ...dm.pricing, fresh_flower_cost: v } })} />
            <SelectField label="Transportation Charges" options={TRANSPORTATION_CHARGES} value={dm.pricing.transportation_charges} onChange={(v) => patchDm({ pricing: { ...dm.pricing, transportation_charges: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="7">
          <Accordion.Header>Section 8 — Venue & Logistics Compatibility</Accordion.Header>
          <Accordion.Body>
            <YesNoField groupName="decIndoor" label="Indoor Setup Capability" value={dm.logistics.indoor_setup} onChange={(v) => patchDm({ logistics: { ...dm.logistics, indoor_setup: v } })} />
            <YesNoField groupName="decOutdoor" label="Outdoor Setup Capability" value={dm.logistics.outdoor_setup} onChange={(v) => patchDm({ logistics: { ...dm.logistics, outdoor_setup: v } })} />
            <YesNoField groupName="decDestination" label="Destination Wedding Support" value={dm.logistics.destination_wedding_support} onChange={(v) => patchDm({ logistics: { ...dm.logistics, destination_wedding_support: v } })} />
            <YesNoField groupName="decTravelStay" label="Travel & Stay Requirement" value={dm.logistics.travel_stay_requirement} onChange={(v) => patchDm({ logistics: { ...dm.logistics, travel_stay_requirement: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="8">
          <Accordion.Header>Section 9 — Lighting & Tech Elements</Accordion.Header>
          <Accordion.Body>
            <SelectField label="Lighting Provided" options={LIGHTING_PROVIDED} value={dm.lighting_tech.lighting_provided} onChange={(v) => patchDm({ lighting_tech: { ...dm.lighting_tech, lighting_provided: v } })} />
            <YesNoField groupName="decLedWall" label="LED Wall Setup" value={dm.lighting_tech.led_wall_setup} onChange={(v) => patchDm({ lighting_tech: { ...dm.lighting_tech, led_wall_setup: v } })} />
            <MultiCheck label="Special Effects" options={SPECIAL_EFFECTS} value={dm.lighting_tech.special_effects} onChange={(v) => patchDm({ lighting_tech: { ...dm.lighting_tech, special_effects: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="9">
          <Accordion.Header>Section 10 — Workflow & Booking</Accordion.Header>
          <Accordion.Body>
            <YesNoField groupName="decAdvanceReq" label="Advance Required" value={dm.workflow.advance_required} onChange={(v) => patchDm({ workflow: { ...dm.workflow, advance_required: v } })} />
            <SelectField label="Advance Percentage" options={ADVANCE_PERCENTAGE} value={dm.workflow.advance_percentage} onChange={(v) => patchDm({ workflow: { ...dm.workflow, advance_percentage: v } })} />
            <SelectField label="Booking Timeline" options={BOOKING_TIMELINE} value={dm.workflow.booking_timeline} onChange={(v) => patchDm({ workflow: { ...dm.workflow, booking_timeline: v } })} />
            <SelectField label="Cancellation Policy" options={CANCELLATION_POLICY_DECORATOR} value={dm.workflow.cancellation_policy} onChange={(v) => patchDm({ workflow: { ...dm.workflow, cancellation_policy: v } })} />
            <SelectField label="Revision Flexibility" options={REVISION_FLEXIBILITY} value={dm.workflow.revision_flexibility} onChange={(v) => patchDm({ workflow: { ...dm.workflow, revision_flexibility: v } })} />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="10">
          <Accordion.Header>Section 11 — Portfolio Intelligence</Accordion.Header>
          <Accordion.Body>
            <p className="text-muted fs-14">Upload Decor Portfolio (Mandatory). Each setup tagged with: Function Type, Theme, Budget Range, Guest Count, Venue Type, Color Palette.</p>
            <div className="mb-3">
              <label className="form-label fw-semibold">Default Tags</label>
              <Form.Control className="fs-14" value={dm.portfolio.tags} onChange={(e) => patchDm({ portfolio: { ...dm.portfolio, tags: e.target.value } })} />
            </div>
            <div className="mb-3">
              <label className="form-label fw-semibold">Notes</label>
              <Form.Control as="textarea" rows={3} className="fs-14" value={dm.portfolio.notes} onChange={(e) => patchDm({ portfolio: { ...dm.portfolio, notes: e.target.value } })} />
            </div>
          </Accordion.Body>
          </Accordion.Item>

      </Accordion>

      {!embedded && (
        <button type="button" className="btn btn-primary mt-3 fs-14" onClick={save}>
          Save Decorator Master Profile
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

export default DecoratorMasterProfile;
