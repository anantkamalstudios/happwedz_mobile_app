import React, { useCallback, useMemo } from "react";
import { Accordion, Form, Button, Row, Col } from "react-bootstrap";
import { FiCheck, FiX } from "react-icons/fi";
import "./VenueMasterProfile.css";
import {
  VENUE_CATEGORY_GROUPS,
  PROPERTY_OWNERSHIP_TYPES,
  LOCATION_TYPES,
  CHAIN_BRAND_CATEGORIES,
  SPACE_TYPES,
  INDOOR_OUTDOOR_HYBRID,
  ROOM_TYPE_OPTIONS,
  ROOM_PRICE_RANGE,
  CATERING_POLICY,
  CUISINE_OPTIONS,
  VEG_NON_VEG,
  PER_PLATE_COST_RANGE,
  OUTSIDE_CATERING_CHARGES,
  ALCOHOL_POLICY,
  CORKAGE_CHARGES,
  BAR_SETUP,
  DECOR_POLICY,
  DECOR_CAPABILITIES,
  TIERED_SETUP,
  LIGHTING_SETUP,
  SOUND_SYSTEM,
  OUTSIDE_DECOR_CHARGES,
  DJ_POLICY,
  NOISE_RESTRICTIONS,
  FIREWORKS_ALLOWED,
  ENTERTAINMENT_SUPPORTED,
  POWER_BACKUP,
  AIR_CONDITIONING,
  WASHROOM_QUALITY,
  SECURITY_SERVICES,
  ADDITIONAL_FACILITIES,
  PRICING_MODEL,
  ADVANCE_PAYMENT_RANGE,
  MINIMUM_BOOKING_DURATION,
  CANCELLATION_POLICY,
  REFUND_TIMELINE,
  SUITABLE_FOR,
  BEST_FOR,
  IDEAL_GUEST_RANGE,
  IMAGE_FUNCTION_TYPES,
  IMAGE_THEME_TYPES,
  IMAGE_COLOR_PALETTE,
  IMAGE_SETUP_TYPE,
  IMAGE_BUDGET_RANGE,
  emptyVenueMaster,
  SHOW_VENUE_IMAGE_INTELLIGENCE,
} from "./venueMasterConstants";

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
    <div className="vm-checkbox-group">
      {label && (
        <div className="vm-checkbox-group-title">
          <span className="group-label">
            <span className="group-dot"></span>
            {label}
          </span>
          <span
            className={`vm-selected-count ${
              selected.length > 0 ? "has-selected" : ""
            }`}
          >
            {selected.length} of {options.length} selected
          </span>
        </div>
      )}
      <div className="vm-checkbox-grid">
        {options.map((opt) => {
          const isSelected = selected.includes(opt);
          return (
            <div
              key={opt}
              className={`vm-checkbox-card ${isSelected ? "selected" : ""}`}
              onClick={() => toggle(opt)}
            >
              <div className="vm-checkbox-indicator">
                {isSelected && <FiCheck size={12} strokeWidth={3.5} />}
              </div>
              <span className="vm-checkbox-label">{opt}</span>
            </div>
          );
        })}
      </div>
      {onOtherChange != null && (
        <div className="mt-3">
          <Form.Control
            className="vm-input fs-14"
            placeholder="Other (type details)"
            value={otherValue || ""}
            onChange={(e) => onOtherChange(e.target.value)}
          />
        </div>
      )}
    </div>
  );
}

function SelectField({ label, options, value, onChange, otherValue, onOtherChange }) {
  return (
    <div className="vm-form-group">
      <label className="vm-form-label">{label}</label>
      <Form.Select
        className="vm-select fs-14"
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
          className="vm-input mt-2 fs-14"
          placeholder="Please specify"
          value={otherValue || ""}
          onChange={(e) => onOtherChange(e.target.value)}
        />
      )}
    </div>
  );
}

function YesNoField({ label, value, onChange, groupName }) {
  return (
    <div className="vm-yesno-group">
      <label className="vm-yesno-label">{label}</label>
      <div className="vm-yesno-options">
        <button
          type="button"
          className={`vm-yesno-btn ${value === "Yes" ? "active-yes" : ""}`}
          onClick={() => onChange("Yes")}
        >
          <FiCheck size={14} /> Yes
        </button>
        <button
          type="button"
          className={`vm-yesno-btn ${value === "No" ? "active-no" : ""}`}
          onClick={() => onChange("No")}
        >
          <FiX size={14} /> No
        </button>
      </div>
    </div>
  );
}

const VenueMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const vm = useMemo(() => {
    const raw = formData.venue_master || formData.attributes?.venue_master;
    if (raw && typeof raw === "object") {
      return mergeDeep(emptyVenueMaster(), raw);
    }
    return emptyVenueMaster();
  }, [formData.venue_master, formData.attributes?.venue_master]);

  const patchVm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const current =
          prev.venue_master ||
          prev.attributes?.venue_master ||
          emptyVenueMaster();
        const next = mergeDeep(current, partial);
        return {
          ...prev,
          venue_master: next,
          attributes: {
            ...(prev.attributes || {}),
            venue_master: next,
          },
        };
      });
    },
    [setFormData]
  );

  const handleSave = async () => {
    if (onSave) await onSave();
    if (onShowSuccess) onShowSuccess();
  };

  const emptySpace = () => ({
    space_name: "",
    space_type: "",
    indoor_outdoor: "",
    seating: "",
    floating: "",
    ac: "",
    dedicated_kitchen: "",
    attached_rooms: "",
    notes: "",
  });

  const addSpaceRow = () => {
    const spaces = [...(vm.space_capacity.spaces || []), emptySpace()];
    patchVm({ space_capacity: { ...vm.space_capacity, spaces } });
  };

  const updateSpaceRow = (index, field, val) => {
    const spaces = [...(vm.space_capacity.spaces || [])];
    spaces[index] = { ...spaces[index], [field]: val };
    patchVm({ space_capacity: { ...vm.space_capacity, spaces } });
  };

  const removeSpaceRow = (index) => {
    const spaces = (vm.space_capacity.spaces || []).filter((_, i) => i !== index);
    patchVm({ space_capacity: { ...vm.space_capacity, spaces } });
  };

  const setRoomCount = (type, count) => {
    const room_type_counts = { ...(vm.rooms.room_type_counts || {}) };
    if (count === "" || count == null) delete room_type_counts[type];
    else room_type_counts[type] = count;
    patchVm({ rooms: { ...vm.rooms, room_type_counts } });
  };

  const inner = (
    <>
        {!embedded && (
          <>
            <h4 className="mb-2 fw-bold">Venue master profile</h4>
            <p className="text-muted fs-14 mb-4">
              Structured venue data for search, filters, and AI FAQ.
            </p>
          </>
        )}

        <Accordion defaultActiveKey={["0", "1"]} alwaysOpen className="venue-master-accordion">
          <Accordion.Item eventKey="0">
            <Accordion.Header>
              <span className="vm-section-badge">Section 1</span>
              <span>Identity & Categories</span>
            </Accordion.Header>
            <Accordion.Body>
              {VENUE_CATEGORY_GROUPS.map((group) => (
                <CheckboxGroup
                  key={group.key}
                  label={group.title}
                  options={group.options}
                  value={vm.categories[group.key]}
                  onChange={(next) =>
                    patchVm({ categories: { ...vm.categories, [group.key]: next } })
                  }
                />
              ))}
              <hr />
              <Row>
                <Col md={6}>
                  <SelectField
                    label="Property ownership type"
                    options={PROPERTY_OWNERSHIP_TYPES}
                    value={vm.identity.property_ownership}
                    onChange={(v) =>
                      patchVm({ identity: { ...vm.identity, property_ownership: v } })
                    }
                    otherValue={vm.identity.property_ownership_other}
                    onOtherChange={(v) =>
                      patchVm({
                        identity: { ...vm.identity, property_ownership_other: v },
                      })
                    }
                  />
                </Col>
                <Col md={6}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Years of operation</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.identity.years_of_operation}
                      onChange={(e) =>
                        patchVm({
                          identity: {
                            ...vm.identity,
                            years_of_operation: e.target.value,
                          },
                        })
                      }
                    />
                  </div>
                </Col>
                <Col md={6}>
                  <SelectField
                    label="Location type"
                    options={LOCATION_TYPES}
                    value={vm.identity.location_type}
                    onChange={(v) =>
                      patchVm({ identity: { ...vm.identity, location_type: v } })
                    }
                    otherValue={vm.identity.location_type_other}
                    onOtherChange={(v) =>
                      patchVm({
                        identity: { ...vm.identity, location_type_other: v },
                      })
                    }
                  />
                </Col>
                <Col md={12}>
                  <YesNoField
                    label="Property belongs to chain?"
                    value={vm.identity.chain_property}
                    onChange={(v) =>
                      patchVm({ identity: { ...vm.identity, chain_property: v } })
                    }
                  />
                </Col>
                {vm.identity.chain_property === "Yes" && (
                  <>
                    <Col md={6}>
                      <div className="mb-3">
                        <label className="form-label fw-semibold">Brand name</label>
                        <Form.Control
                          className="fs-14"
                          value={vm.identity.chain_brand_name}
                          onChange={(e) =>
                            patchVm({
                              identity: {
                                ...vm.identity,
                                chain_brand_name: e.target.value,
                              },
                            })
                          }
                        />
                      </div>
                    </Col>
                    <Col md={6}>
                      <SelectField
                        label="Brand category"
                        options={CHAIN_BRAND_CATEGORIES}
                        value={vm.identity.chain_brand_category}
                        onChange={(v) =>
                          patchVm({
                            identity: { ...vm.identity, chain_brand_category: v },
                          })
                        }
                        otherValue={vm.identity.chain_brand_category_other}
                        onOtherChange={(v) =>
                          patchVm({
                            identity: {
                              ...vm.identity,
                              chain_brand_category_other: v,
                            },
                          })
                        }
                      />
                    </Col>
                  </>
                )}
              </Row>
            </Accordion.Body>
          </Accordion.Item>

          <Accordion.Item eventKey="1">
            <Accordion.Header>
              <span className="vm-section-badge">Section 2</span>
              <span>Space & Capacity</span>
            </Accordion.Header>
            <Accordion.Body>
              <CheckboxGroup
                label="Space types available"
                options={SPACE_TYPES}
                value={vm.space_capacity.space_types}
                onChange={(next) =>
                  patchVm({ space_capacity: { ...vm.space_capacity, space_types: next } })
                }
                otherValue={vm.space_capacity.space_types_other}
                onOtherChange={(v) =>
                  patchVm({
                    space_capacity: { ...vm.space_capacity, space_types_other: v },
                  })
                }
              />
              <Row>
                <Col md={4}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">
                      Number of distinct event spaces
                    </label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.space_capacity.num_event_spaces}
                      onChange={(e) =>
                        patchVm({
                          space_capacity: {
                            ...vm.space_capacity,
                            num_event_spaces: e.target.value,
                          },
                        })
                      }
                    />
                  </div>
                </Col>
                <Col md={4}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Indoor spaces count</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.space_capacity.indoor_spaces_count}
                      onChange={(e) =>
                        patchVm({
                          space_capacity: {
                            ...vm.space_capacity,
                            indoor_spaces_count: e.target.value,
                          },
                        })
                      }
                    />
                  </div>
                </Col>
                <Col md={4}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Outdoor spaces count</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.space_capacity.outdoor_spaces_count}
                      onChange={(e) =>
                        patchVm({
                          space_capacity: {
                            ...vm.space_capacity,
                            outdoor_spaces_count: e.target.value,
                          },
                        })
                      }
                    />
                  </div>
                </Col>
                <Col md={3}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Indoor seating</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.space_capacity.indoor_seating}
                      onChange={(e) =>
                        patchVm({
                          space_capacity: {
                            ...vm.space_capacity,
                            indoor_seating: e.target.value,
                          },
                        })
                      }
                    />
                  </div>
                </Col>
                <Col md={3}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Indoor floating</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.space_capacity.indoor_floating}
                      onChange={(e) =>
                        patchVm({
                          space_capacity: {
                            ...vm.space_capacity,
                            indoor_floating: e.target.value,
                          },
                        })
                      }
                    />
                  </div>
                </Col>
                <Col md={3}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Outdoor seating</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.space_capacity.outdoor_seating}
                      onChange={(e) =>
                        patchVm({
                          space_capacity: {
                            ...vm.space_capacity,
                            outdoor_seating: e.target.value,
                          },
                        })
                      }
                    />
                  </div>
                </Col>
                <Col md={3}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Outdoor floating</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.space_capacity.outdoor_floating}
                      onChange={(e) =>
                        patchVm({
                          space_capacity: {
                            ...vm.space_capacity,
                            outdoor_floating: e.target.value,
                          },
                        })
                      }
                    />
                  </div>
                </Col>
                <Col md={4}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Minimum guests</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.space_capacity.min_guests}
                      onChange={(e) =>
                        patchVm({
                          space_capacity: {
                            ...vm.space_capacity,
                            min_guests: e.target.value,
                          },
                        })
                      }
                    />
                  </div>
                </Col>
                <Col md={4}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Maximum guests</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.space_capacity.max_guests}
                      onChange={(e) =>
                        patchVm({
                          space_capacity: {
                            ...vm.space_capacity,
                            max_guests: e.target.value,
                          },
                        })
                      }
                    />
                  </div>
                </Col>
                <Col md={4}>
                  <YesNoField
                    label="Separate function areas available?"
                    value={vm.space_capacity.separate_function_areas}
                    onChange={(v) =>
                      patchVm({
                        space_capacity: {
                          ...vm.space_capacity,
                          separate_function_areas: v,
                        },
                      })
                    }
                  />
                </Col>
                <Col md={6}>
                  <YesNoField
                    label="Can host multiple events simultaneously?"
                    value={vm.space_capacity.multiple_events_simultaneous}
                    onChange={(v) =>
                      patchVm({
                        space_capacity: {
                          ...vm.space_capacity,
                          multiple_events_simultaneous: v,
                        },
                      })
                    }
                  />
                </Col>
                <Col md={6}>
                  <YesNoField
                    label="Exclusive venue booking available?"
                    value={vm.space_capacity.exclusive_booking}
                    onChange={(v) =>
                      patchVm({
                        space_capacity: {
                          ...vm.space_capacity,
                          exclusive_booking: v,
                        },
                      })
                    }
                  />
                </Col>
              </Row>
              <div className="mb-3">
                <label className="form-label fw-semibold d-block mb-2">
                  Space-wise configuration
                </label>
                <Button
                  variant="outline-primary"
                  size="sm"
                  type="button"
                  className="venue-add-space-btn"
                  onClick={addSpaceRow}
                >
                  Add space
                </Button>
              </div>
              {(vm.space_capacity.spaces || []).map((row, idx) => (
                <div key={idx} className="border rounded p-3 mb-3 bg-light">
                  <Row>
                    <Col md={4}>
                      <Form.Control
                        className="fs-14 mb-2"
                        placeholder="Space name"
                        value={row.space_name}
                        onChange={(e) =>
                          updateSpaceRow(idx, "space_name", e.target.value)
                        }
                      />
                    </Col>
                    <Col md={4}>
                      <Form.Select
                        className="fs-14 mb-2"
                        value={row.space_type}
                        onChange={(e) =>
                          updateSpaceRow(idx, "space_type", e.target.value)
                        }
                      >
                        <option value="">Space type</option>
                        {SPACE_TYPES.map((s) => (
                          <option key={s} value={s}>
                            {s}
                          </option>
                        ))}
                      </Form.Select>
                    </Col>
                    <Col md={4}>
                      <Form.Select
                        className="fs-14 mb-2"
                        value={row.indoor_outdoor}
                        onChange={(e) =>
                          updateSpaceRow(idx, "indoor_outdoor", e.target.value)
                        }
                      >
                        <option value="">Indoor / Outdoor / Hybrid</option>
                        {INDOOR_OUTDOOR_HYBRID.map((s) => (
                          <option key={s} value={s}>
                            {s}
                          </option>
                        ))}
                      </Form.Select>
                    </Col>
                    <Col md={3}>
                      <Form.Control
                        className="fs-14 mb-2"
                        type="number"
                        placeholder="Seating"
                        value={row.seating}
                        onChange={(e) =>
                          updateSpaceRow(idx, "seating", e.target.value)
                        }
                      />
                    </Col>
                    <Col md={3}>
                      <Form.Control
                        className="fs-14 mb-2"
                        type="number"
                        placeholder="Floating"
                        value={row.floating}
                        onChange={(e) =>
                          updateSpaceRow(idx, "floating", e.target.value)
                        }
                      />
                    </Col>
                    <Col md={2}>
                      <YesNoField
                        label="AC"
                        groupName={`space_${idx}_ac`}
                        value={row.ac}
                        onChange={(v) => updateSpaceRow(idx, "ac", v)}
                      />
                    </Col>
                    <Col md={2}>
                      <YesNoField
                        label="Dedicated kitchen"
                        groupName={`space_${idx}_kitchen`}
                        value={row.dedicated_kitchen}
                        onChange={(v) => updateSpaceRow(idx, "dedicated_kitchen", v)}
                      />
                    </Col>
                    <Col md={2}>
                      <YesNoField
                        label="Attached rooms"
                        groupName={`space_${idx}_rooms`}
                        value={row.attached_rooms}
                        onChange={(v) => updateSpaceRow(idx, "attached_rooms", v)}
                      />
                    </Col>
                    <Col md={12}>
                      <Form.Control
                        className="fs-14"
                        placeholder="Other notes"
                        value={row.notes}
                        onChange={(e) => updateSpaceRow(idx, "notes", e.target.value)}
                      />
                    </Col>
                    <Col xs={12} className="mt-2">
                      <Button
                        variant="outline-danger"
                        size="sm"
                        type="button"
                        className="venue-remove-space-btn"
                        onClick={() => removeSpaceRow(idx)}
                      >
                        Remove
                      </Button>
                    </Col>
                  </Row>
                </div>
              ))}
            </Accordion.Body>
          </Accordion.Item>

          <Accordion.Item eventKey="2">
            <Accordion.Header>
              <span className="vm-section-badge">Section 3</span>
              <span>Rooms & Accommodation</span>
            </Accordion.Header>
            <Accordion.Body>
              <Row>
                <Col md={4}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Number of rooms</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.rooms.num_rooms}
                      onChange={(e) =>
                        patchVm({ rooms: { ...vm.rooms, num_rooms: e.target.value } })
                      }
                    />
                  </div>
                </Col>
                <Col md={4}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Max occupancy / room</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.rooms.max_occupancy_per_room}
                      onChange={(e) =>
                        patchVm({
                          rooms: { ...vm.rooms, max_occupancy_per_room: e.target.value },
                        })
                      }
                    />
                  </div>
                </Col>
                <Col md={4}>
                  <YesNoField
                    label="Extra bed available?"
                    value={vm.rooms.extra_bed}
                    onChange={(v) => patchVm({ rooms: { ...vm.rooms, extra_bed: v } })}
                  />
                </Col>
                <Col md={6}>
                  <SelectField
                    label="Room price range"
                    options={ROOM_PRICE_RANGE}
                    value={vm.rooms.room_price_range}
                    onChange={(v) =>
                      patchVm({ rooms: { ...vm.rooms, room_price_range: v } })
                    }
                    otherValue={vm.rooms.room_price_range_other}
                    onOtherChange={(v) =>
                      patchVm({ rooms: { ...vm.rooms, room_price_range_other: v } })
                    }
                  />
                </Col>
                <Col md={3}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Complimentary rooms</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.rooms.complimentary_rooms}
                      onChange={(e) =>
                        patchVm({
                          rooms: { ...vm.rooms, complimentary_rooms: e.target.value },
                        })
                      }
                    />
                  </div>
                </Col>
                <Col md={3}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Total stay capacity</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.rooms.total_stay_capacity}
                      onChange={(e) =>
                        patchVm({
                          rooms: { ...vm.rooms, total_stay_capacity: e.target.value },
                        })
                      }
                    />
                  </div>
                </Col>
              </Row>
              <label className="form-label fw-semibold">Room types (select + count)</label>
              <div className="row">
                {ROOM_TYPE_OPTIONS.map((rt) => {
                  const checked = (vm.rooms.room_types || []).includes(rt);
                  const count = vm.rooms.room_type_counts?.[rt] ?? "";
                  return (
                    <Col md={6} key={rt} className="mb-2">
                      <div className="d-flex align-items-center gap-2">
                        <Form.Check
                          type="checkbox"
                          label={rt}
                          checked={checked}
                          onChange={() => {
                            const cur = vm.rooms.room_types || [];
                            const next = checked
                              ? cur.filter((x) => x !== rt)
                              : [...cur, rt];
                            patchVm({ rooms: { ...vm.rooms, room_types: next } });
                            if (checked) setRoomCount(rt, "");
                          }}
                          className="fs-14 flex-shrink-0"
                          style={{ minWidth: 140 }}
                        />
                        {checked && (
                          <Form.Control
                            type="number"
                            className="fs-14"
                            placeholder="Count"
                            value={count}
                            onChange={(e) => setRoomCount(rt, e.target.value)}
                            style={{ maxWidth: 120 }}
                          />
                        )}
                      </div>
                    </Col>
                  );
                })}
              </div>
              <Form.Control
                className="fs-14 mt-2"
                placeholder="Other room types + counts (free text)"
                value={vm.rooms.room_types_other}
                onChange={(e) =>
                  patchVm({ rooms: { ...vm.rooms, room_types_other: e.target.value } })
                }
              />
            </Accordion.Body>
          </Accordion.Item>

          <Accordion.Item eventKey="3">
            <Accordion.Header>
              <span className="vm-section-badge">Section 4</span>
              <span>Food & Catering</span>
            </Accordion.Header>
            <Accordion.Body>
              <SelectField
                label="Catering policy"
                options={CATERING_POLICY}
                value={vm.food.catering_policy}
                onChange={(v) =>
                  patchVm({ food: { ...vm.food, catering_policy: v } })
                }
                otherValue={vm.food.catering_policy_other}
                onOtherChange={(v) =>
                  patchVm({ food: { ...vm.food, catering_policy_other: v } })
                }
              />
              <CheckboxGroup
                label="Cuisine options"
                options={CUISINE_OPTIONS}
                value={vm.food.cuisines}
                onChange={(next) => patchVm({ food: { ...vm.food, cuisines: next } })}
                otherValue={vm.food.cuisines_other}
                onOtherChange={(v) =>
                  patchVm({ food: { ...vm.food, cuisines_other: v } })
                }
              />
              <Row>
                <Col md={6}>
                  <SelectField
                    label="Veg / Non-Veg"
                    options={VEG_NON_VEG}
                    value={vm.food.veg_non_veg}
                    onChange={(v) => patchVm({ food: { ...vm.food, veg_non_veg: v } })}
                    otherValue={vm.food.veg_non_veg_other}
                    onOtherChange={(v) =>
                      patchVm({ food: { ...vm.food, veg_non_veg_other: v } })
                    }
                  />
                </Col>
                <Col md={6}>
                  <YesNoField
                    label="Jain food available?"
                    value={vm.food.jain_food}
                    onChange={(v) => patchVm({ food: { ...vm.food, jain_food: v } })}
                  />
                </Col>
                <Col md={6}>
                  <SelectField
                    label="Per plate cost range"
                    options={PER_PLATE_COST_RANGE}
                    value={vm.food.per_plate_cost_range}
                    onChange={(v) =>
                      patchVm({ food: { ...vm.food, per_plate_cost_range: v } })
                    }
                    otherValue={vm.food.per_plate_cost_range_other}
                    onOtherChange={(v) =>
                      patchVm({ food: { ...vm.food, per_plate_cost_range_other: v } })
                    }
                  />
                </Col>
                <Col md={6}>
                  <SelectField
                    label="Outside catering charges"
                    options={OUTSIDE_CATERING_CHARGES}
                    value={vm.food.outside_catering_charges}
                    onChange={(v) =>
                      patchVm({ food: { ...vm.food, outside_catering_charges: v } })
                    }
                    otherValue={vm.food.outside_catering_charges_other}
                    onOtherChange={(v) =>
                      patchVm({
                        food: { ...vm.food, outside_catering_charges_other: v },
                      })
                    }
                  />
                </Col>
                <Col md={6}>
                  <YesNoField
                    label="Kitchen available for external caterers?"
                    value={vm.food.kitchen_for_external}
                    onChange={(v) =>
                      patchVm({ food: { ...vm.food, kitchen_for_external: v } })
                    }
                  />
                </Col>
              </Row>
            </Accordion.Body>
          </Accordion.Item>

          <Accordion.Item eventKey="4">
            <Accordion.Header>
              <span className="vm-section-badge">Section 5</span>
              <span>Alcohol Policy & Bar</span>
            </Accordion.Header>
            <Accordion.Body>
              <SelectField
                label="Alcohol policy"
                options={ALCOHOL_POLICY}
                value={vm.alcohol.policy}
                onChange={(v) => patchVm({ alcohol: { ...vm.alcohol, policy: v } })}
                otherValue={vm.alcohol.policy_other}
                onOtherChange={(v) =>
                  patchVm({ alcohol: { ...vm.alcohol, policy_other: v } })
                }
              />
              <SelectField
                label="Corkage charges"
                options={CORKAGE_CHARGES}
                value={vm.alcohol.corkage}
                onChange={(v) => patchVm({ alcohol: { ...vm.alcohol, corkage: v } })}
                otherValue={vm.alcohol.corkage_other}
                onOtherChange={(v) =>
                  patchVm({ alcohol: { ...vm.alcohol, corkage_other: v } })
                }
              />
              <CheckboxGroup
                label="Bar setup provided"
                options={BAR_SETUP}
                value={vm.alcohol.bar_setup}
                onChange={(next) =>
                  patchVm({ alcohol: { ...vm.alcohol, bar_setup: next } })
                }
                otherValue={vm.alcohol.bar_setup_other}
                onOtherChange={(v) =>
                  patchVm({ alcohol: { ...vm.alcohol, bar_setup_other: v } })
                }
              />
            </Accordion.Body>
          </Accordion.Item>

          <Accordion.Item eventKey="5">
            <Accordion.Header>
              <span className="vm-section-badge">Section 6</span>
              <span>Decor & Production</span>
            </Accordion.Header>
            <Accordion.Body>
              <SelectField
                label="Decor policy"
                options={DECOR_POLICY}
                value={vm.decor.policy}
                onChange={(v) => patchVm({ decor: { ...vm.decor, policy: v } })}
                otherValue={vm.decor.policy_other}
                onOtherChange={(v) =>
                  patchVm({ decor: { ...vm.decor, policy_other: v } })
                }
              />
              <CheckboxGroup
                label="Decor capabilities"
                options={DECOR_CAPABILITIES}
                value={vm.decor.capabilities}
                onChange={(next) =>
                  patchVm({ decor: { ...vm.decor, capabilities: next } })
                }
                otherValue={vm.decor.capabilities_other}
                onOtherChange={(v) =>
                  patchVm({ decor: { ...vm.decor, capabilities_other: v } })
                }
              />
              <CheckboxGroup
                label="Stage setup"
                options={TIERED_SETUP}
                value={vm.decor.stage}
                onChange={(next) => patchVm({ decor: { ...vm.decor, stage: next } })}
                otherValue={vm.decor.stage_other}
                onOtherChange={(v) =>
                  patchVm({ decor: { ...vm.decor, stage_other: v } })
                }
              />
              <CheckboxGroup
                label="Mandap setup"
                options={TIERED_SETUP}
                value={vm.decor.mandap}
                onChange={(next) => patchVm({ decor: { ...vm.decor, mandap: next } })}
                otherValue={vm.decor.mandap_other}
                onOtherChange={(v) =>
                  patchVm({ decor: { ...vm.decor, mandap_other: v } })
                }
              />
              <CheckboxGroup
                label="Lighting setup"
                options={LIGHTING_SETUP}
                value={vm.decor.lighting}
                onChange={(next) =>
                  patchVm({ decor: { ...vm.decor, lighting: next } })
                }
                otherValue={vm.decor.lighting_other}
                onOtherChange={(v) =>
                  patchVm({ decor: { ...vm.decor, lighting_other: v } })
                }
              />
              <CheckboxGroup
                label="Sound system"
                options={SOUND_SYSTEM}
                value={vm.decor.sound}
                onChange={(next) => patchVm({ decor: { ...vm.decor, sound: next } })}
                otherValue={vm.decor.sound_other}
                onOtherChange={(v) =>
                  patchVm({ decor: { ...vm.decor, sound_other: v } })
                }
              />
              <SelectField
                label="Outside decor charges"
                options={OUTSIDE_DECOR_CHARGES}
                value={vm.decor.outside_charges}
                onChange={(v) =>
                  patchVm({ decor: { ...vm.decor, outside_charges: v } })
                }
                otherValue={vm.decor.outside_charges_other}
                onOtherChange={(v) =>
                  patchVm({ decor: { ...vm.decor, outside_charges_other: v } })
                }
              />
            </Accordion.Body>
          </Accordion.Item>

          <Accordion.Item eventKey="6">
            <Accordion.Header>
              <span className="vm-section-badge">Section 7</span>
              <span>Entertainment & DJ</span>
            </Accordion.Header>
            <Accordion.Body>
              <SelectField
                label="DJ policy"
                options={DJ_POLICY}
                value={vm.entertainment.dj_policy}
                onChange={(v) =>
                  patchVm({ entertainment: { ...vm.entertainment, dj_policy: v } })
                }
                otherValue={vm.entertainment.dj_policy_other}
                onOtherChange={(v) =>
                  patchVm({
                    entertainment: { ...vm.entertainment, dj_policy_other: v },
                  })
                }
              />
              <SelectField
                label="Noise restrictions"
                options={NOISE_RESTRICTIONS}
                value={vm.entertainment.noise}
                onChange={(v) =>
                  patchVm({ entertainment: { ...vm.entertainment, noise: v } })
                }
                otherValue={vm.entertainment.noise_other}
                onOtherChange={(v) =>
                  patchVm({ entertainment: { ...vm.entertainment, noise_other: v } })
                }
              />
              <YesNoField
                label="Live band allowed?"
                value={vm.entertainment.live_band}
                onChange={(v) =>
                  patchVm({ entertainment: { ...vm.entertainment, live_band: v } })
                }
              />
              <SelectField
                label="Fireworks allowed"
                options={FIREWORKS_ALLOWED}
                value={vm.entertainment.fireworks}
                onChange={(v) =>
                  patchVm({ entertainment: { ...vm.entertainment, fireworks: v } })
                }
                otherValue={vm.entertainment.fireworks_other}
                onOtherChange={(v) =>
                  patchVm({
                    entertainment: { ...vm.entertainment, fireworks_other: v },
                  })
                }
              />
              <CheckboxGroup
                label="Entertainment supported"
                options={ENTERTAINMENT_SUPPORTED}
                value={vm.entertainment.supported}
                onChange={(next) =>
                  patchVm({ entertainment: { ...vm.entertainment, supported: next } })
                }
                otherValue={vm.entertainment.supported_other}
                onOtherChange={(v) =>
                  patchVm({
                    entertainment: { ...vm.entertainment, supported_other: v },
                  })
                }
              />
            </Accordion.Body>
          </Accordion.Item>

          <Accordion.Item eventKey="7">
            <Accordion.Header>
              <span className="vm-section-badge">Section 8</span>
              <span>Facilities & Amenities</span>
            </Accordion.Header>
            <Accordion.Body>
              <Row>
                <Col md={4}>
                  <YesNoField
                    label="Parking available?"
                    value={vm.facilities.parking}
                    onChange={(v) =>
                      patchVm({ facilities: { ...vm.facilities, parking: v } })
                    }
                  />
                </Col>
                <Col md={4}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Parking capacity</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.facilities.parking_capacity}
                      onChange={(e) =>
                        patchVm({
                          facilities: {
                            ...vm.facilities,
                            parking_capacity: e.target.value,
                          },
                        })
                      }
                    />
                  </div>
                </Col>
                <Col md={4}>
                  <YesNoField
                    label="Valet parking?"
                    value={vm.facilities.valet}
                    onChange={(v) =>
                      patchVm({ facilities: { ...vm.facilities, valet: v } })
                    }
                  />
                </Col>
              </Row>
              <CheckboxGroup
                label="Power backup"
                options={POWER_BACKUP}
                value={vm.facilities.power_backup}
                onChange={(next) =>
                  patchVm({ facilities: { ...vm.facilities, power_backup: next } })
                }
                otherValue={vm.facilities.power_backup_other}
                onOtherChange={(v) =>
                  patchVm({
                    facilities: { ...vm.facilities, power_backup_other: v },
                  })
                }
              />
              <SelectField
                label="Air conditioning"
                options={AIR_CONDITIONING}
                value={vm.facilities.ac}
                onChange={(v) => patchVm({ facilities: { ...vm.facilities, ac: v } })}
                otherValue={vm.facilities.ac_other}
                onOtherChange={(v) =>
                  patchVm({ facilities: { ...vm.facilities, ac_other: v } })
                }
              />
              <Row>
                <Col md={4}>
                  <YesNoField
                    label="Bridal room?"
                    value={vm.facilities.bridal_room}
                    onChange={(v) =>
                      patchVm({ facilities: { ...vm.facilities, bridal_room: v } })
                    }
                  />
                </Col>
                <Col md={4}>
                  <YesNoField
                    label="Groom room?"
                    value={vm.facilities.groom_room}
                    onChange={(v) =>
                      patchVm({ facilities: { ...vm.facilities, groom_room: v } })
                    }
                  />
                </Col>
                <Col md={4}>
                  <YesNoField
                    label="Wheelchair accessibility?"
                    value={vm.facilities.wheelchair}
                    onChange={(v) =>
                      patchVm({ facilities: { ...vm.facilities, wheelchair: v } })
                    }
                  />
                </Col>
                <Col md={6}>
                  <SelectField
                    label="Washroom quality"
                    options={WASHROOM_QUALITY}
                    value={vm.facilities.washroom}
                    onChange={(v) =>
                      patchVm({ facilities: { ...vm.facilities, washroom: v } })
                    }
                    otherValue={vm.facilities.washroom_other}
                    onOtherChange={(v) =>
                      patchVm({ facilities: { ...vm.facilities, washroom_other: v } })
                    }
                  />
                </Col>
                <Col md={3}>
                  <YesNoField
                    label="Lift access?"
                    value={vm.facilities.lift}
                    onChange={(v) =>
                      patchVm({ facilities: { ...vm.facilities, lift: v } })
                    }
                  />
                </Col>
                <Col md={3}>
                  <SelectField
                    label="Security services"
                    options={SECURITY_SERVICES}
                    value={vm.facilities.security}
                    onChange={(v) =>
                      patchVm({ facilities: { ...vm.facilities, security: v } })
                    }
                    otherValue={vm.facilities.security_other}
                    onOtherChange={(v) =>
                      patchVm({
                        facilities: { ...vm.facilities, security_other: v },
                      })
                    }
                  />
                </Col>
              </Row>
              <CheckboxGroup
                label="Additional facilities"
                options={ADDITIONAL_FACILITIES}
                value={vm.facilities.additional}
                onChange={(next) =>
                  patchVm({ facilities: { ...vm.facilities, additional: next } })
                }
                otherValue={vm.facilities.additional_other}
                onOtherChange={(v) =>
                  patchVm({
                    facilities: { ...vm.facilities, additional_other: v },
                  })
                }
              />
            </Accordion.Body>
          </Accordion.Item>

          <Accordion.Item eventKey="8">
            <Accordion.Header>
              <span className="vm-section-badge">Section 9</span>
              <span>Pricing & Booking Policies</span>
            </Accordion.Header>
            <Accordion.Body>
              <CheckboxGroup
                label="Pricing model"
                options={PRICING_MODEL}
                value={vm.pricing_booking.pricing_model}
                onChange={(next) =>
                  patchVm({
                    pricing_booking: { ...vm.pricing_booking, pricing_model: next },
                  })
                }
                otherValue={vm.pricing_booking.pricing_model_other}
                onOtherChange={(v) =>
                  patchVm({
                    pricing_booking: {
                      ...vm.pricing_booking,
                      pricing_model_other: v,
                    },
                  })
                }
              />
              <Row>
                <Col md={4}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Starting venue price</label>
                    <Form.Control
                      type="number"
                      className="fs-14"
                      value={vm.pricing_booking.starting_venue_price}
                      onChange={(e) =>
                        patchVm({
                          pricing_booking: {
                            ...vm.pricing_booking,
                            starting_venue_price: e.target.value,
                          },
                        })
                      }
                    />
                  </div>
                </Col>
                <Col md={4}>
                  <YesNoField
                    label="Peak season pricing?"
                    value={vm.pricing_booking.peak_season_pricing}
                    onChange={(v) =>
                      patchVm({
                        pricing_booking: {
                          ...vm.pricing_booking,
                          peak_season_pricing: v,
                        },
                      })
                    }
                  />
                </Col>
                <Col md={4}>
                  <YesNoField
                    label="Advance booking required?"
                    value={vm.pricing_booking.advance_booking_required}
                    onChange={(v) =>
                      patchVm({
                        pricing_booking: {
                          ...vm.pricing_booking,
                          advance_booking_required: v,
                        },
                      })
                    }
                  />
                </Col>
                <Col md={6}>
                  <SelectField
                    label="Advance payment range"
                    options={ADVANCE_PAYMENT_RANGE}
                    value={vm.pricing_booking.advance_payment_range}
                    onChange={(v) =>
                      patchVm({
                        pricing_booking: {
                          ...vm.pricing_booking,
                          advance_payment_range: v,
                        },
                      })
                    }
                    otherValue={vm.pricing_booking.advance_payment_range_other}
                    onOtherChange={(v) =>
                      patchVm({
                        pricing_booking: {
                          ...vm.pricing_booking,
                          advance_payment_range_other: v,
                        },
                      })
                    }
                  />
                </Col>
                <Col md={6}>
                  <CheckboxGroup
                    label="Minimum booking duration"
                    options={MINIMUM_BOOKING_DURATION}
                    value={vm.pricing_booking.min_booking_duration}
                    onChange={(next) =>
                      patchVm({
                        pricing_booking: {
                          ...vm.pricing_booking,
                          min_booking_duration: next,
                        },
                      })
                    }
                    otherValue={vm.pricing_booking.min_booking_duration_other}
                    onOtherChange={(v) =>
                      patchVm({
                        pricing_booking: {
                          ...vm.pricing_booking,
                          min_booking_duration_other: v,
                        },
                      })
                    }
                  />
                </Col>
                <Col md={6}>
                  <SelectField
                    label="Cancellation policy"
                    options={CANCELLATION_POLICY}
                    value={vm.pricing_booking.cancellation}
                    onChange={(v) =>
                      patchVm({
                        pricing_booking: { ...vm.pricing_booking, cancellation: v },
                      })
                    }
                    otherValue={vm.pricing_booking.cancellation_other}
                    onOtherChange={(v) =>
                      patchVm({
                        pricing_booking: {
                          ...vm.pricing_booking,
                          cancellation_other: v,
                        },
                      })
                    }
                  />
                </Col>
                <Col md={6}>
                  <SelectField
                    label="Refund timeline"
                    options={REFUND_TIMELINE}
                    value={vm.pricing_booking.refund_timeline}
                    onChange={(v) =>
                      patchVm({
                        pricing_booking: {
                          ...vm.pricing_booking,
                          refund_timeline: v,
                        },
                      })
                    }
                    otherValue={vm.pricing_booking.refund_timeline_other}
                    onOtherChange={(v) =>
                      patchVm({
                        pricing_booking: {
                          ...vm.pricing_booking,
                          refund_timeline_other: v,
                        },
                      })
                    }
                  />
                </Col>
              </Row>
            </Accordion.Body>
          </Accordion.Item>

          <Accordion.Item eventKey="9">
            <Accordion.Header>
              <span className="vm-section-badge">Section 10</span>
              <span>Event Suitability</span>
            </Accordion.Header>
            <Accordion.Body>
              <CheckboxGroup
                label="Suitable for"
                options={SUITABLE_FOR}
                value={vm.suitability.suitable_for}
                onChange={(next) =>
                  patchVm({ suitability: { ...vm.suitability, suitable_for: next } })
                }
                otherValue={vm.suitability.suitable_for_other}
                onOtherChange={(v) =>
                  patchVm({
                    suitability: { ...vm.suitability, suitable_for_other: v },
                  })
                }
              />
              <CheckboxGroup
                label="Best for"
                options={BEST_FOR}
                value={vm.suitability.best_for}
                onChange={(next) =>
                  patchVm({ suitability: { ...vm.suitability, best_for: next } })
                }
                otherValue={vm.suitability.best_for_other}
                onOtherChange={(v) =>
                  patchVm({ suitability: { ...vm.suitability, best_for_other: v } })
                }
              />
              <CheckboxGroup
                label="Ideal guest range"
                options={IDEAL_GUEST_RANGE}
                value={vm.suitability.ideal_guest_range}
                onChange={(next) =>
                  patchVm({
                    suitability: { ...vm.suitability, ideal_guest_range: next },
                  })
                }
                otherValue={vm.suitability.ideal_guest_range_other}
                onOtherChange={(v) =>
                  patchVm({
                    suitability: { ...vm.suitability, ideal_guest_range_other: v },
                  })
                }
              />
            </Accordion.Body>
          </Accordion.Item>

          {SHOW_VENUE_IMAGE_INTELLIGENCE && (
          <Accordion.Item eventKey="10">
            <Accordion.Header>
              <span className="vm-section-badge">Section 11</span>
              <span>Image Intelligence (Tagging)</span>
            </Accordion.Header>
            <Accordion.Body>
              <p className="fs-14 text-muted">
                Upload photos in the Photos tab. Use this block for default tags /
                notes applied to gallery images (per-image tagging can be added later).
              </p>
              <Row>
                <Col md={6}>
                  <SelectField
                    label="Default function type"
                    options={IMAGE_FUNCTION_TYPES}
                    value={vm.image_intelligence.default_function_type}
                    onChange={(v) =>
                      patchVm({
                        image_intelligence: {
                          ...vm.image_intelligence,
                          default_function_type: v,
                        },
                      })
                    }
                  />
                </Col>
                <Col md={6}>
                  <SelectField
                    label="Default theme type"
                    options={IMAGE_THEME_TYPES}
                    value={vm.image_intelligence.default_theme}
                    onChange={(v) =>
                      patchVm({
                        image_intelligence: {
                          ...vm.image_intelligence,
                          default_theme: v,
                        },
                      })
                    }
                  />
                </Col>
                <Col md={6}>
                  <SelectField
                    label="Default color palette"
                    options={IMAGE_COLOR_PALETTE}
                    value={vm.image_intelligence.default_palette}
                    onChange={(v) =>
                      patchVm({
                        image_intelligence: {
                          ...vm.image_intelligence,
                          default_palette: v,
                        },
                      })
                    }
                  />
                </Col>
                <Col md={6}>
                  <SelectField
                    label="Default setup type"
                    options={IMAGE_SETUP_TYPE}
                    value={vm.image_intelligence.default_setup}
                    onChange={(v) =>
                      patchVm({
                        image_intelligence: {
                          ...vm.image_intelligence,
                          default_setup: v,
                        },
                      })
                    }
                  />
                </Col>
                <Col md={6}>
                  <SelectField
                    label="Default budget range (for shots)"
                    options={IMAGE_BUDGET_RANGE}
                    value={vm.image_intelligence.default_budget_range}
                    onChange={(v) =>
                      patchVm({
                        image_intelligence: {
                          ...vm.image_intelligence,
                          default_budget_range: v,
                        },
                      })
                    }
                  />
                </Col>
                <Col md={12}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Other typeable tags</label>
                    <Form.Control
                      className="fs-14"
                      value={vm.image_intelligence.other_tags}
                      onChange={(e) =>
                        patchVm({
                          image_intelligence: {
                            ...vm.image_intelligence,
                            other_tags: e.target.value,
                          },
                        })
                      }
                      placeholder="Comma-separated tags"
                    />
                  </div>
                </Col>
                <Col md={12}>
                  <div className="mb-3">
                    <label className="form-label fw-semibold">Notes for editors / AI</label>
                    <Form.Control
                      as="textarea"
                      rows={3}
                      className="fs-14"
                      value={vm.image_intelligence.notes}
                      onChange={(e) =>
                        patchVm({
                          image_intelligence: {
                            ...vm.image_intelligence,
                            notes: e.target.value,
                          },
                        })
                      }
                    />
                  </div>
                </Col>
              </Row>
            </Accordion.Body>
          </Accordion.Item>
          )}
        </Accordion>

        {!embedded && (
          <button
            className="btn btn-primary mt-4 fs-14"
            type="button"
            onClick={handleSave}
          >
            Save venue master profile
          </button>
        )}
    </>
  );

  const styleBlock = (
    <style>{`
      .venue-master-embedded .venue-add-space-btn,
      .venue-master-embedded .venue-remove-space-btn {
        width: auto;
        max-width: 9rem;
        white-space: nowrap;
      }

      /* Accordion */
      .venue-master-accordion .accordion-item {
        border: 1px solid #f3d9e6;
        border-radius: 14px;
        overflow: hidden;
        margin-bottom: 16px;
        box-shadow: 0 1px 4px rgba(0, 0, 0, 0.05);
      }
      .venue-master-accordion .accordion-item:last-child {
        margin-bottom: 0;
      }
      .venue-master-accordion .accordion-button {
        font-weight: 700;
        font-size: 15.5px;
        color: #1f2937;
        background: #fdf2f8;
        padding: 16px 20px;
      }
      .venue-master-accordion .accordion-button:not(.collapsed) {
        background: linear-gradient(135deg, #ff6b9d 0%, #e91e63 100%);
        color: #fff;
        box-shadow: none;
      }
      .venue-master-accordion .accordion-button:focus {
        box-shadow: 0 0 0 3px rgba(233, 30, 99, 0.2);
        z-index: 1;
      }
      .venue-master-accordion .accordion-button:not(.collapsed)::after {
        filter: brightness(0) invert(1);
      }
      .venue-master-accordion .accordion-body {
        padding: 22px 22px 10px;
        background: #fff;
      }
      .venue-master-accordion hr {
        margin: 24px 0;
        opacity: 0.15;
      }
    `}</style>
  );

  if (embedded) {
    return (
      <>
        {styleBlock}
        <div className="venue-master-embedded">{inner}</div>
      </>
    );
  }
  return (
    <div className="my-5">
      {styleBlock}
      <div className="p-3 border rounded bg-white">{inner}</div>
    </div>
  );
};

export default VenueMasterProfile;
