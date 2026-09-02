import React, { useCallback, useMemo } from "react";
import { Accordion, Form, Button, Row, Col } from "react-bootstrap";
import {
  PLANNER_TYPES,
  SERVICE_COVERAGE,
  TEAM_SIZE,
  SERVICES_OFFERED,
  PLANNING_TYPE,
  VENDOR_SOURCING,
  EVENTS_MANAGED_PER_YEAR,
  GUEST_HANDLING_CAPACITY,
  EXPERTISE_IN,
  FUNCTIONS_MANAGED,
  DESTINATION_WEDDING_SUPPORT,
  DESTINATIONS_COVERED,
  MINIMUM_BUDGET_HANDLED,
  MAXIMUM_BUDGET_HANDLED,
  PRICING_MODEL,
  PLANNING_FEES_RANGE,
  COMMISSION_FROM_VENDORS,
  THEMES_EXPERTISE,
  VENDOR_CATEGORIES_MANAGED,
  ADVANCE_PERCENTAGE,
  BOOKING_TIMELINE,
  REVISION_FLEXIBILITY,
  CANCELLATION_POLICY,
  BEST_FOR,
  IDEAL_CLIENT_TYPE,
  emptyWeddingPlannerMaster
} from "./weddingPlannerMasterConstants";

const yesNo = ["Yes", "No"];

function mergeDeep(base, patch) {
  const out = { ...base };
  Object.keys(patch).forEach((k) => {
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

function CheckboxGroup({ label, options, value, onChange, otherValue, onOtherChange }) {
  const selected = Array.isArray(value) ? value : [];
  const toggle = (opt) => {
    if (selected.includes(opt)) onChange(selected.filter((x) => x !== opt));
    else onChange([...selected, opt]);
  };
  return (
    <div className="mb-3">
      {label && <label className="form-label fw-semibold">{label}</label>}
      <div className="d-flex flex-wrap gap-2">
        {options.map((opt) => (
          <Form.Check
            key={opt}
            type="checkbox"
            id={`cb_${label.replace(/\s+/g, "_")}_${opt}`}
            label={opt}
            checked={selected.includes(opt)}
            onChange={() => toggle(opt)}
            className="fs-14"
          />
        ))}
      </div>
      {selected.includes("Other") && onOtherChange != null && (
        <Form.Control
          className="mt-2 fs-14"
          placeholder="Other (type details)"
          value={otherValue || ""}
          onChange={(e) => onOtherChange(e.target.value)}
        />
      )}
    </div>
  );
}

function SelectField({ label, options, value, onChange, otherValue, onOtherChange }) {
  return (
    <div className="mb-3">
      <label className="form-label fw-semibold">{label}</label>
      <Form.Select
        className="fs-14"
        value={value || ""}
        onChange={(e) => onChange(e.target.value)}
      >
        <option value="">Select…</option>
        {options.map((o) => (
          <option key={o} value={o}>
            {o}
          </option>
        ))}
      </Form.Select>
      {value === "Other" && onOtherChange && (
        <Form.Control
          className="mt-2 fs-14"
          placeholder="Please specify"
          value={otherValue || ""}
          onChange={(e) => onOtherChange(e.target.value)}
        />
      )}
    </div>
  );
}

function YesNoField({ label, value, onChange, groupName }) {
  const name = groupName || `yn_${String(label).replace(/\s+/g, "_")}`;
  return (
    <div className="mb-3">
      <label className="form-label fw-semibold">{label}</label>
      <div className="d-flex gap-3">
        {yesNo.map((y) => (
          <Form.Check
            key={y}
            type="radio"
            name={name}
            id={`${name}_${y}`}
            label={y}
            checked={value === y}
            onChange={() => onChange(y)}
            className="fs-14"
          />
        ))}
      </div>
    </div>
  );
}

const WeddingPlannerMasterProfile = ({
  formData,
  setFormData,
  embedded = false,
}) => {
  const vm = useMemo(() => {
    const raw = formData.wedding_planner_master || formData.attributes?.wedding_planner_master;
    if (raw && typeof raw === "object") {
      return mergeDeep(emptyWeddingPlannerMaster(), raw);
    }
    return emptyWeddingPlannerMaster();
  }, [formData.wedding_planner_master, formData.attributes?.wedding_planner_master]);

  const patchVm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const current =
          prev.wedding_planner_master ||
          prev.attributes?.wedding_planner_master ||
          emptyWeddingPlannerMaster();
        const next = mergeDeep(current, partial);
        return {
          ...prev,
          wedding_planner_master: next,
          attributes: {
            ...(prev.attributes || {}),
            wedding_planner_master: next,
          },
        };
      });
    },
    [setFormData]
  );

  return (
    <>
      {!embedded && (
        <>
          <h4 className="mb-2 fw-bold">Wedding Planner Profile</h4>
          <p className="text-muted fs-14 mb-4">
            Structured data for your planner profile.
          </p>
        </>
      )}

      <Accordion defaultActiveKey={["0"]} alwaysOpen flush className="venue-master-accordion">
        
        <Accordion.Item eventKey="0">
          <Accordion.Header>Section 1 — Basic Identity</Accordion.Header>
          <Accordion.Body>
            <Row>
              {/* <Col md={12}>
                <div className="mb-3">
                  <label className="form-label fw-semibold">Company / Planner Name</label>
                  <Form.Control
                    type="text"
                    className="fs-14"
                    value={vm.identity.company_name}
                    onChange={(e) =>
                      patchVm({ identity: { ...vm.identity, company_name: e.target.value } })
                    }
                  />
                </div>
              </Col> */}
              <Col md={6}>
                <SelectField
                  label="Planner Type"
                  options={PLANNER_TYPES}
                  value={vm.identity.planner_type}
                  onChange={(v) => patchVm({ identity: { ...vm.identity, planner_type: v } })}
                  otherValue={vm.identity.planner_type_other}
                  onOtherChange={(v) => patchVm({ identity: { ...vm.identity, planner_type_other: v } })}
                />
              </Col>
              <Col md={6}>
                <div className="mb-3">
                  <label className="form-label fw-semibold">Years of Experience</label>
                  <Form.Control
                    type="number"
                    className="fs-14"
                    value={vm.identity.years_of_experience}
                    onChange={(e) =>
                      patchVm({ identity: { ...vm.identity, years_of_experience: e.target.value } })
                    }
                  />
                </div>
              </Col>
              <Col md={6}>
                <div className="mb-3">
                  <label className="form-label fw-semibold">City</label>
                  <Form.Control
                    type="text"
                    className="fs-14"
                    value={vm.identity.city}
                    onChange={(e) =>
                      patchVm({ identity: { ...vm.identity, city: e.target.value } })
                    }
                  />
                </div>
              </Col>
              <Col md={6}>
                <SelectField
                  label="Service Coverage"
                  options={SERVICE_COVERAGE}
                  value={vm.identity.service_coverage}
                  onChange={(v) => patchVm({ identity: { ...vm.identity, service_coverage: v } })}
                  otherValue={vm.identity.service_coverage_other}
                  onOtherChange={(v) => patchVm({ identity: { ...vm.identity, service_coverage_other: v } })}
                />
              </Col>
              <Col md={6}>
                <SelectField
                  label="Team Size"
                  options={TEAM_SIZE}
                  value={vm.identity.team_size}
                  onChange={(v) => patchVm({ identity: { ...vm.identity, team_size: v } })}
                  otherValue={vm.identity.team_size_other}
                  onOtherChange={(v) => patchVm({ identity: { ...vm.identity, team_size_other: v } })}
                />
              </Col>
            </Row>
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Services Offered</Accordion.Header>
          <Accordion.Body>
            <CheckboxGroup
              label="Services Offered"
              options={SERVICES_OFFERED}
              value={vm.services.services_offered}
              onChange={(next) => patchVm({ services: { ...vm.services, services_offered: next } })}
              otherValue={vm.services.services_offered_other}
              onOtherChange={(v) => patchVm({ services: { ...vm.services, services_offered_other: v } })}
            />
            <CheckboxGroup
              label="Planning Type"
              options={PLANNING_TYPE}
              value={vm.services.planning_type}
              onChange={(next) => patchVm({ services: { ...vm.services, planning_type: next } })}
              otherValue={vm.services.planning_type_other}
              onOtherChange={(v) => patchVm({ services: { ...vm.services, planning_type_other: v } })}
            />
            <SelectField
              label="Vendor Sourcing"
              options={VENDOR_SOURCING}
              value={vm.services.vendor_sourcing}
              onChange={(v) => patchVm({ services: { ...vm.services, vendor_sourcing: v } })}
              otherValue={vm.services.vendor_sourcing_other}
              onOtherChange={(v) => patchVm({ services: { ...vm.services, vendor_sourcing_other: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="2">
          <Accordion.Header>Section 3 — Event Scale & Expertise</Accordion.Header>
          <Accordion.Body>
            <Row>
              <Col md={6}>
                <SelectField
                  label="Events Managed Per Year"
                  options={EVENTS_MANAGED_PER_YEAR}
                  value={vm.scale.events_managed_per_year}
                  onChange={(v) => patchVm({ scale: { ...vm.scale, events_managed_per_year: v } })}
                  otherValue={vm.scale.events_managed_per_year_other}
                  onOtherChange={(v) => patchVm({ scale: { ...vm.scale, events_managed_per_year_other: v } })}
                />
              </Col>
              <Col md={6}>
                <SelectField
                  label="Guest Handling Capacity"
                  options={GUEST_HANDLING_CAPACITY}
                  value={vm.scale.guest_handling_capacity}
                  onChange={(v) => patchVm({ scale: { ...vm.scale, guest_handling_capacity: v } })}
                  otherValue={vm.scale.guest_handling_capacity_other}
                  onOtherChange={(v) => patchVm({ scale: { ...vm.scale, guest_handling_capacity_other: v } })}
                />
              </Col>
            </Row>
            <CheckboxGroup
              label="Expertise In"
              options={EXPERTISE_IN}
              value={vm.scale.expertise_in}
              onChange={(next) => patchVm({ scale: { ...vm.scale, expertise_in: next } })}
              otherValue={vm.scale.expertise_in_other}
              onOtherChange={(v) => patchVm({ scale: { ...vm.scale, expertise_in_other: v } })}
            />
            <CheckboxGroup
              label="Functions Managed"
              options={FUNCTIONS_MANAGED}
              value={vm.scale.functions_managed}
              onChange={(next) => patchVm({ scale: { ...vm.scale, functions_managed: next } })}
              otherValue={vm.scale.functions_managed_other}
              onOtherChange={(v) => patchVm({ scale: { ...vm.scale, functions_managed_other: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="3">
          <Accordion.Header>Section 4 — Destination & Logistics</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Destination Wedding Support"
              options={DESTINATION_WEDDING_SUPPORT}
              value={vm.logistics.destination_wedding_support}
              onChange={(v) => patchVm({ logistics: { ...vm.logistics, destination_wedding_support: v } })}
            />
            {vm.logistics.destination_wedding_support === "Yes" && (
              <CheckboxGroup
                label="Destinations Covered"
                options={DESTINATIONS_COVERED}
                value={vm.logistics.destinations_covered}
                onChange={(next) => patchVm({ logistics: { ...vm.logistics, destinations_covered: next } })}
                otherValue={vm.logistics.destinations_covered_other}
                onOtherChange={(v) => patchVm({ logistics: { ...vm.logistics, destinations_covered_other: v } })}
              />
            )}
            <Row>
              <Col md={4}>
                <YesNoField
                  label="Travel & Logistics Management"
                  value={vm.logistics.travel_logistics_management}
                  onChange={(v) => patchVm({ logistics: { ...vm.logistics, travel_logistics_management: v } })}
                />
              </Col>
              <Col md={4}>
                <YesNoField
                  label="Guest Accommodation Management"
                  value={vm.logistics.guest_accommodation_management}
                  onChange={(v) => patchVm({ logistics: { ...vm.logistics, guest_accommodation_management: v } })}
                />
              </Col>
              <Col md={4}>
                <YesNoField
                  label="Transportation Management"
                  value={vm.logistics.transportation_management}
                  onChange={(v) => patchVm({ logistics: { ...vm.logistics, transportation_management: v } })}
                />
              </Col>
            </Row>
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="4">
          <Accordion.Header>Section 5 — Budget & Pricing</Accordion.Header>
          <Accordion.Body>
            <Row>
              <Col md={6}>
                <SelectField
                  label="Minimum Budget Handled"
                  options={MINIMUM_BUDGET_HANDLED}
                  value={vm.budget.minimum_budget_handled}
                  onChange={(v) => patchVm({ budget: { ...vm.budget, minimum_budget_handled: v } })}
                  otherValue={vm.budget.minimum_budget_handled_other}
                  onOtherChange={(v) => patchVm({ budget: { ...vm.budget, minimum_budget_handled_other: v } })}
                />
              </Col>
              <Col md={6}>
                <SelectField
                  label="Maximum Budget Handled"
                  options={MAXIMUM_BUDGET_HANDLED}
                  value={vm.budget.maximum_budget_handled}
                  onChange={(v) => patchVm({ budget: { ...vm.budget, maximum_budget_handled: v } })}
                  otherValue={vm.budget.maximum_budget_handled_other}
                  onOtherChange={(v) => patchVm({ budget: { ...vm.budget, maximum_budget_handled_other: v } })}
                />
              </Col>
              <Col md={6}>
                <SelectField
                  label="Pricing Model"
                  options={PRICING_MODEL}
                  value={vm.budget.pricing_model}
                  onChange={(v) => patchVm({ budget: { ...vm.budget, pricing_model: v } })}
                  otherValue={vm.budget.pricing_model_other}
                  onOtherChange={(v) => patchVm({ budget: { ...vm.budget, pricing_model_other: v } })}
                />
              </Col>
              <Col md={6}>
                <SelectField
                  label="Planning Fees Range"
                  options={PLANNING_FEES_RANGE}
                  value={vm.budget.planning_fees_range}
                  onChange={(v) => patchVm({ budget: { ...vm.budget, planning_fees_range: v } })}
                  otherValue={vm.budget.planning_fees_range_other}
                  onOtherChange={(v) => patchVm({ budget: { ...vm.budget, planning_fees_range_other: v } })}
                />
              </Col>
              <Col md={6}>
                <SelectField
                  label="Commission from Vendors"
                  options={COMMISSION_FROM_VENDORS}
                  value={vm.budget.commission_from_vendors}
                  onChange={(v) => patchVm({ budget: { ...vm.budget, commission_from_vendors: v } })}
                  otherValue={vm.budget.commission_from_vendors_other}
                  onOtherChange={(v) => patchVm({ budget: { ...vm.budget, commission_from_vendors_other: v } })}
                />
              </Col>
            </Row>
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Design & Theme</Accordion.Header>
          <Accordion.Body>
            <YesNoField
              label="Theme Planning Support"
              value={vm.design.theme_planning_support}
              onChange={(v) => patchVm({ design: { ...vm.design, theme_planning_support: v } })}
            />
            {vm.design.theme_planning_support === "Yes" && (
              <CheckboxGroup
                label="Themes Expertise"
                options={THEMES_EXPERTISE}
                value={vm.design.themes_expertise}
                onChange={(next) => patchVm({ design: { ...vm.design, themes_expertise: next } })}
                otherValue={vm.design.themes_expertise_other}
                onOtherChange={(v) => patchVm({ design: { ...vm.design, themes_expertise_other: v } })}
              />
            )}
            <Row>
              <Col md={6}>
                <YesNoField
                  label="Moodboard Creation"
                  value={vm.design.moodboard_creation}
                  onChange={(v) => patchVm({ design: { ...vm.design, moodboard_creation: v } })}
                />
              </Col>
              <Col md={6}>
                <YesNoField
                  label="Custom Concept Design"
                  value={vm.design.custom_concept_design}
                  onChange={(v) => patchVm({ design: { ...vm.design, custom_concept_design: v } })}
                />
              </Col>
            </Row>
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Vendor Management</Accordion.Header>
          <Accordion.Body>
            <CheckboxGroup
              label="Vendor Categories Managed"
              options={VENDOR_CATEGORIES_MANAGED}
              value={vm.vendor_management.vendor_categories_managed}
              onChange={(next) => patchVm({ vendor_management: { ...vm.vendor_management, vendor_categories_managed: next } })}
              otherValue={vm.vendor_management.vendor_categories_managed_other}
              onOtherChange={(v) => patchVm({ vendor_management: { ...vm.vendor_management, vendor_categories_managed_other: v } })}
            />
            <Row>
              <Col md={6}>
                <YesNoField
                  label="Vendor Negotiation Support"
                  value={vm.vendor_management.vendor_negotiation_support}
                  onChange={(v) => patchVm({ vendor_management: { ...vm.vendor_management, vendor_negotiation_support: v } })}
                />
              </Col>
              <Col md={6}>
                <YesNoField
                  label="Vendor Bundling"
                  value={vm.vendor_management.vendor_bundling}
                  onChange={(v) => patchVm({ vendor_management: { ...vm.vendor_management, vendor_bundling: v } })}
                />
              </Col>
            </Row>
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="7">
          <Accordion.Header>Section 8 — Technology & Process</Accordion.Header>
          <Accordion.Body>
            <Row>
              <Col md={6}>
                <YesNoField
                  label="Digital Planning Tools"
                  value={vm.technology.digital_planning_tools}
                  onChange={(v) => patchVm({ technology: { ...vm.technology, digital_planning_tools: v } })}
                />
              </Col>
              <Col md={6}>
                <YesNoField
                  label="Real-Time Coordination Team"
                  value={vm.technology.real_time_coordination_team}
                  onChange={(v) => patchVm({ technology: { ...vm.technology, real_time_coordination_team: v } })}
                />
              </Col>
              <Col md={6}>
                <YesNoField
                  label="Timeline Planning"
                  value={vm.technology.timeline_planning}
                  onChange={(v) => patchVm({ technology: { ...vm.technology, timeline_planning: v } })}
                />
              </Col>
              <Col md={6}>
                <YesNoField
                  label="Checklist Management"
                  value={vm.technology.checklist_management}
                  onChange={(v) => patchVm({ technology: { ...vm.technology, checklist_management: v } })}
                />
              </Col>
              <Col md={6}>
                <YesNoField
                  label="On-Ground Execution Team"
                  value={vm.technology.on_ground_execution_team}
                  onChange={(v) => patchVm({ technology: { ...vm.technology, on_ground_execution_team: v } })}
                />
              </Col>
            </Row>
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="8">
          <Accordion.Header>Section 9 — Workflow & Booking</Accordion.Header>
          <Accordion.Body>
            <YesNoField
              label="Advance Required"
              value={vm.workflow.advance_required}
              onChange={(v) => patchVm({ workflow: { ...vm.workflow, advance_required: v } })}
            />
            {vm.workflow.advance_required === "Yes" && (
              <SelectField
                label="Advance Percentage"
                options={ADVANCE_PERCENTAGE}
                value={vm.workflow.advance_percentage}
                onChange={(v) => patchVm({ workflow: { ...vm.workflow, advance_percentage: v } })}
                otherValue={vm.workflow.advance_percentage_other}
                onOtherChange={(v) => patchVm({ workflow: { ...vm.workflow, advance_percentage_other: v } })}
              />
            )}
            <Row>
              <Col md={6}>
                <SelectField
                  label="Booking Timeline"
                  options={BOOKING_TIMELINE}
                  value={vm.workflow.booking_timeline}
                  onChange={(v) => patchVm({ workflow: { ...vm.workflow, booking_timeline: v } })}
                  otherValue={vm.workflow.booking_timeline_other}
                  onOtherChange={(v) => patchVm({ workflow: { ...vm.workflow, booking_timeline_other: v } })}
                />
              </Col>
              <Col md={6}>
                <SelectField
                  label="Cancellation Policy"
                  options={CANCELLATION_POLICY}
                  value={vm.workflow.cancellation_policy}
                  onChange={(v) => patchVm({ workflow: { ...vm.workflow, cancellation_policy: v } })}
                  otherValue={vm.workflow.cancellation_policy_other}
                  onOtherChange={(v) => patchVm({ workflow: { ...vm.workflow, cancellation_policy_other: v } })}
                />
              </Col>
              <Col md={6}>
                <SelectField
                  label="Revision Flexibility"
                  options={REVISION_FLEXIBILITY}
                  value={vm.workflow.revision_flexibility}
                  onChange={(v) => patchVm({ workflow: { ...vm.workflow, revision_flexibility: v } })}
                  otherValue={vm.workflow.revision_flexibility_other}
                  onOtherChange={(v) => patchVm({ workflow: { ...vm.workflow, revision_flexibility_other: v } })}
                />
              </Col>
            </Row>
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="9">
          <Accordion.Header>Section 10 — Event Suitability</Accordion.Header>
          <Accordion.Body>
            <CheckboxGroup
              label="Best For"
              options={BEST_FOR}
              value={vm.suitability.best_for}
              onChange={(next) => patchVm({ suitability: { ...vm.suitability, best_for: next } })}
              otherValue={vm.suitability.best_for_other}
              onOtherChange={(v) => patchVm({ suitability: { ...vm.suitability, best_for_other: v } })}
            />
            <CheckboxGroup
              label="Ideal Client Type"
              options={IDEAL_CLIENT_TYPE}
              value={vm.suitability.ideal_client_type}
              onChange={(next) => patchVm({ suitability: { ...vm.suitability, ideal_client_type: next } })}
              otherValue={vm.suitability.ideal_client_type_other}
              onOtherChange={(v) => patchVm({ suitability: { ...vm.suitability, ideal_client_type_other: v } })}
            />
          </Accordion.Body>
        </Accordion.Item>

      </Accordion>
    </>
  );
};

export default WeddingPlannerMasterProfile;
