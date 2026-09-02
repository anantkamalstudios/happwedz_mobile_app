import React, { useCallback, useMemo } from "react";
import { Accordion, Form } from "react-bootstrap";
import {
  ARTIST_TYPE,
  SERVICES_OFFERED_MUA,
  CATEGORIES_COVERED_MUA,
  MAKEUP_ARTIST_CITIES,
  TRAVEL_AVAILABILITY_MUA,
  SIGNATURE_MAKEUP_STYLE,
  EXPERTISE_IN_MUA,
  BEST_KNOWN_FOR_MUA,
  IDEAL_CLIENT_TYPE_MUA,
  SKIN_TYPES_HANDLED,
  SKIN_TONE_EXPERTISE,
  YES_NO_EXTRA_CHARGES,
  PRODUCT_CATEGORY_MUA,
  BRANDS_LUXURY,
  BRANDS_PREMIUM,
  BRANDS_BASIC,
  HYGIENE_PRACTICES,
  BRIDAL_PACKAGE_INCLUDES,
  NUMBER_OF_LOOKS_INCLUDED,
  TRIAL_COST_OPTIONS,
  TOUCH_UP_SERVICE,
  PRICING_TYPE_MUA,
  GROOM_MAKEUP_COST,
  FAMILY_MAKEUP_COST,
  TRAVEL_CHARGES_MUA,
  STAY_REQUIRED_MUA,
  ADVANCE_PERCENTAGE_MUA,
  BOOKING_TIMELINE_MUA,
  CANCELLATION_POLICY_MUA,
  DELAY_HANDLING,
  FUNCTIONS_COVERED_MUA,
  BEST_FOR_MUA,
  BRANDS_ALL_MUA,
  AI_FAQ_CANCELLATION,
  emptyMakeupArtistMaster,
} from "./makeupArtistMasterConstants";

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

const MakeupArtistMasterProfile = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  embedded = false,
}) => {
  const mm = useMemo(() => {
    const raw =
      formData.makeup_artist_master || formData.attributes?.makeup_artist_master;
    if (raw && typeof raw === "object")
      return mergeDeep(emptyMakeupArtistMaster(), raw);
    return emptyMakeupArtistMaster();
  }, [formData.makeup_artist_master, formData.attributes?.makeup_artist_master]);

  const patchMm = useCallback(
    (partial) => {
      setFormData((prev) => {
        const next = mergeDeep(
          prev.makeup_artist_master ||
            prev.attributes?.makeup_artist_master ||
            emptyMakeupArtistMaster(),
          partial
        );
        return {
          ...prev,
          makeup_artist_master: next,
          attributes: { ...(prev.attributes || {}), makeup_artist_master: next },
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
      <h4 className="mb-2 fw-bold">Bridal makeup artist master profile</h4>
      <p className="text-muted fs-14 mb-4">
        Structured bridal makeup data for search, filters, portfolio tagging, and AI
        FAQ.
      </p>
      <Accordion alwaysOpen flush defaultActiveKey={["0", "1"]}>
        <Accordion.Item eventKey="0">
          <Accordion.Header>Section 1 — Basic identity</Accordion.Header>
          <Accordion.Body>
            <div className="mb-3">
              <label className="form-label fw-semibold">Brand / Artist name</label>
              <Form.Control
                className="fs-14"
                value={mm.identity.brand_artist_name}
                onChange={(e) =>
                  patchMm({
                    identity: { ...mm.identity, brand_artist_name: e.target.value },
                  })
                }
              />
            </div>
            <SelectField
              label="Artist type"
              options={ARTIST_TYPE}
              value={mm.identity.artist_type}
              onChange={(v) => patchMm({ identity: { ...mm.identity, artist_type: v } })}
            />
            <MultiCheck
              label="Services offered"
              options={SERVICES_OFFERED_MUA}
              value={mm.identity.services_offered}
              onChange={(v) =>
                patchMm({ identity: { ...mm.identity, services_offered: v } })
              }
            />
            <MultiCheck
              label="Categories covered"
              options={CATEGORIES_COVERED_MUA}
              value={mm.identity.categories_covered}
              onChange={(v) =>
                patchMm({ identity: { ...mm.identity, categories_covered: v } })
              }
            />
            <div className="mb-3">
              <label className="form-label fw-semibold">Years of experience</label>
              <Form.Control
                type="number"
                className="fs-14"
                value={mm.identity.years_of_experience}
                onChange={(e) =>
                  patchMm({
                    identity: {
                      ...mm.identity,
                      years_of_experience: e.target.value,
                    },
                  })
                }
              />
            </div>
            <MultiCheck
              label="City (multi select)"
              options={MAKEUP_ARTIST_CITIES}
              value={mm.identity.cities}
              onChange={(v) => patchMm({ identity: { ...mm.identity, cities: v } })}
            />
            <SelectField
              label="Travel availability"
              options={TRAVEL_AVAILABILITY_MUA}
              value={mm.identity.travel_availability}
              onChange={(v) =>
                patchMm({ identity: { ...mm.identity, travel_availability: v } })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="1">
          <Accordion.Header>Section 2 — Makeup style intelligence</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Signature makeup style"
              options={SIGNATURE_MAKEUP_STYLE}
              value={mm.makeup_style_intelligence.signature_makeup_style}
              onChange={(v) =>
                patchMm({
                  makeup_style_intelligence: {
                    ...mm.makeup_style_intelligence,
                    signature_makeup_style: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Expertise in"
              options={EXPERTISE_IN_MUA}
              value={mm.makeup_style_intelligence.expertise_in}
              onChange={(v) =>
                patchMm({
                  makeup_style_intelligence: {
                    ...mm.makeup_style_intelligence,
                    expertise_in: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Best known for"
              options={BEST_KNOWN_FOR_MUA}
              value={mm.makeup_style_intelligence.best_known_for}
              onChange={(v) =>
                patchMm({
                  makeup_style_intelligence: {
                    ...mm.makeup_style_intelligence,
                    best_known_for: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Ideal client type"
              options={IDEAL_CLIENT_TYPE_MUA}
              value={mm.makeup_style_intelligence.ideal_client_type}
              onChange={(v) =>
                patchMm({
                  makeup_style_intelligence: {
                    ...mm.makeup_style_intelligence,
                    ideal_client_type: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="2">
          <Accordion.Header>Section 3 — Skin & hair expertise</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Skin types handled"
              options={SKIN_TYPES_HANDLED}
              value={mm.skin_hair_expertise.skin_types_handled}
              onChange={(v) =>
                patchMm({
                  skin_hair_expertise: {
                    ...mm.skin_hair_expertise,
                    skin_types_handled: v,
                  },
                })
              }
            />
            <MultiCheck
              label="Skin tone expertise"
              options={SKIN_TONE_EXPERTISE}
              value={mm.skin_hair_expertise.skin_tone_expertise}
              onChange={(v) =>
                patchMm({
                  skin_hair_expertise: {
                    ...mm.skin_hair_expertise,
                    skin_tone_expertise: v,
                  },
                })
              }
            />
            <SelectField
              label="Skin care consultation included"
              options={YES_NO_EXTRA_CHARGES}
              value={mm.skin_hair_expertise.skin_care_consultation}
              onChange={(v) =>
                patchMm({
                  skin_hair_expertise: {
                    ...mm.skin_hair_expertise,
                    skin_care_consultation: v,
                  },
                })
              }
            />
            <SelectField
              label="Hairstyling included"
              options={YES_NO_EXTRA_CHARGES}
              value={mm.skin_hair_expertise.hairstyling_included}
              onChange={(v) =>
                patchMm({
                  skin_hair_expertise: {
                    ...mm.skin_hair_expertise,
                    hairstyling_included: v,
                  },
                })
              }
            />
            <SelectField
              label="Hair extensions provided"
              options={YES_NO_EXTRA_CHARGES}
              value={mm.skin_hair_expertise.hair_extensions}
              onChange={(v) =>
                patchMm({
                  skin_hair_expertise: { ...mm.skin_hair_expertise, hair_extensions: v },
                })
              }
            />
            <SelectField
              label="Draping included"
              options={YES_NO_EXTRA_CHARGES}
              value={mm.skin_hair_expertise.draping_included}
              onChange={(v) =>
                patchMm({
                  skin_hair_expertise: {
                    ...mm.skin_hair_expertise,
                    draping_included: v,
                  },
                })
              }
            />
            <SelectField
              label="Lashes & lenses included"
              options={YES_NO_EXTRA_CHARGES}
              value={mm.skin_hair_expertise.lashes_lenses_included}
              onChange={(v) =>
                patchMm({
                  skin_hair_expertise: {
                    ...mm.skin_hair_expertise,
                    lashes_lenses_included: v,
                  },
                })
              }
            />
            <SelectField
              label="Bridal outfit styling guidance included"
              options={YES_NO_EXTRA_CHARGES}
              value={mm.skin_hair_expertise.outfit_styling_guidance}
              onChange={(v) =>
                patchMm({
                  skin_hair_expertise: {
                    ...mm.skin_hair_expertise,
                    outfit_styling_guidance: v,
                  },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="3">
          <Accordion.Header>Section 4 — Products & brands</Accordion.Header>
          <Accordion.Body>
            <SelectField
              label="Product category"
              options={PRODUCT_CATEGORY_MUA}
              value={mm.products_brands.product_category}
              onChange={(v) =>
                patchMm({
                  products_brands: { ...mm.products_brands, product_category: v },
                })
              }
            />
            <MultiCheck
              label="Brands used — Luxury / high-end"
              options={BRANDS_LUXURY}
              value={mm.products_brands.brands_luxury}
              onChange={(v) =>
                patchMm({
                  products_brands: { ...mm.products_brands, brands_luxury: v },
                })
              }
            />
            <MultiCheck
              label="Brands used — Premium / mid-range"
              options={BRANDS_PREMIUM}
              value={mm.products_brands.brands_premium}
              onChange={(v) =>
                patchMm({
                  products_brands: { ...mm.products_brands, brands_premium: v },
                })
              }
            />
            <MultiCheck
              label="Brands used — Basic / economical"
              options={BRANDS_BASIC}
              value={mm.products_brands.brands_basic}
              onChange={(v) =>
                patchMm({
                  products_brands: { ...mm.products_brands, brands_basic: v },
                })
              }
            />
            <MultiCheck
              label="Hygiene practices"
              options={HYGIENE_PRACTICES}
              value={mm.products_brands.hygiene_practices}
              onChange={(v) =>
                patchMm({
                  products_brands: { ...mm.products_brands, hygiene_practices: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="4">
          <Accordion.Header>Section 5 — Bridal package structure</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Bridal package includes"
              options={BRIDAL_PACKAGE_INCLUDES}
              value={mm.bridal_package.package_includes}
              onChange={(v) =>
                patchMm({ bridal_package: { ...mm.bridal_package, package_includes: v } })
              }
            />
            <SelectField
              label="Number of looks included"
              options={NUMBER_OF_LOOKS_INCLUDED}
              value={mm.bridal_package.number_of_looks}
              onChange={(v) =>
                patchMm({ bridal_package: { ...mm.bridal_package, number_of_looks: v } })
              }
            />
            <YesNoField
              groupName="trialMakeup"
              label="Trial makeup available"
              value={mm.bridal_package.trial_makeup_available}
              onChange={(v) =>
                patchMm({
                  bridal_package: { ...mm.bridal_package, trial_makeup_available: v },
                })
              }
            />
            <SelectField
              label="Trial cost"
              options={TRIAL_COST_OPTIONS}
              value={mm.bridal_package.trial_cost}
              onChange={(v) =>
                patchMm({ bridal_package: { ...mm.bridal_package, trial_cost: v } })
              }
            />
            <SelectField
              label="Touch-up service"
              options={TOUCH_UP_SERVICE}
              value={mm.bridal_package.touch_up_service}
              onChange={(v) =>
                patchMm({
                  bridal_package: { ...mm.bridal_package, touch_up_service: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="5">
          <Accordion.Header>Section 6 — Pricing structure</Accordion.Header>
          <Accordion.Body>
            <div className="mb-3">
              <label className="form-label fw-semibold">
                Bridal makeup starting price
              </label>
              <Form.Control
                type="number"
                className="fs-14"
                value={mm.pricing_structure.bridal_makeup_starting_price}
                onChange={(e) =>
                  patchMm({
                    pricing_structure: {
                      ...mm.pricing_structure,
                      bridal_makeup_starting_price: e.target.value,
                    },
                  })
                }
              />
            </div>
            <SelectField
              label="Pricing type"
              options={PRICING_TYPE_MUA}
              value={mm.pricing_structure.pricing_type}
              onChange={(v) =>
                patchMm({
                  pricing_structure: { ...mm.pricing_structure, pricing_type: v },
                })
              }
            />
            <SelectField
              label="Groom makeup cost"
              options={GROOM_MAKEUP_COST}
              value={mm.pricing_structure.groom_makeup_cost}
              onChange={(v) =>
                patchMm({
                  pricing_structure: { ...mm.pricing_structure, groom_makeup_cost: v },
                })
              }
            />
            <SelectField
              label="Family makeup cost"
              options={FAMILY_MAKEUP_COST}
              value={mm.pricing_structure.family_makeup_cost}
              onChange={(v) =>
                patchMm({
                  pricing_structure: { ...mm.pricing_structure, family_makeup_cost: v },
                })
              }
            />
            <div className="mb-3">
              <label className="form-label fw-semibold">
                Family / package price note (starting from, if applicable)
              </label>
              <Form.Control
                className="fs-14"
                value={mm.pricing_structure.family_price_note}
                onChange={(e) =>
                  patchMm({
                    pricing_structure: {
                      ...mm.pricing_structure,
                      family_price_note: e.target.value,
                    },
                  })
                }
                placeholder="e.g. From ₹5000 per person"
              />
            </div>
            <SelectField
              label="Travel charges"
              options={TRAVEL_CHARGES_MUA}
              value={mm.pricing_structure.travel_charges}
              onChange={(v) =>
                patchMm({
                  pricing_structure: { ...mm.pricing_structure, travel_charges: v },
                })
              }
            />
            <SelectField
              label="Stay required"
              options={STAY_REQUIRED_MUA}
              value={mm.pricing_structure.stay_required}
              onChange={(v) =>
                patchMm({
                  pricing_structure: { ...mm.pricing_structure, stay_required: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="6">
          <Accordion.Header>Section 7 — Workflow & process</Accordion.Header>
          <Accordion.Body>
            <YesNoField
              groupName="advReqMua"
              label="Advance required"
              value={mm.workflow_process.advance_required}
              onChange={(v) =>
                patchMm({
                  workflow_process: { ...mm.workflow_process, advance_required: v },
                })
              }
            />
            <SelectField
              label="Advance percentage"
              options={ADVANCE_PERCENTAGE_MUA}
              value={mm.workflow_process.advance_percentage}
              onChange={(v) =>
                patchMm({
                  workflow_process: { ...mm.workflow_process, advance_percentage: v },
                })
              }
            />
            <SelectField
              label="Booking timeline"
              options={BOOKING_TIMELINE_MUA}
              value={mm.workflow_process.booking_timeline}
              onChange={(v) =>
                patchMm({
                  workflow_process: { ...mm.workflow_process, booking_timeline: v },
                })
              }
            />
            <SelectField
              label="Cancellation policy"
              options={CANCELLATION_POLICY_MUA}
              value={mm.workflow_process.cancellation_policy}
              onChange={(v) =>
                patchMm({
                  workflow_process: {
                    ...mm.workflow_process,
                    cancellation_policy: v,
                  },
                })
              }
            />
            <SelectField
              label="Delay handling"
              options={DELAY_HANDLING}
              value={mm.workflow_process.delay_handling}
              onChange={(v) =>
                patchMm({
                  workflow_process: { ...mm.workflow_process, delay_handling: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="7">
          <Accordion.Header>Section 8 — Event suitability</Accordion.Header>
          <Accordion.Body>
            <MultiCheck
              label="Functions covered"
              options={FUNCTIONS_COVERED_MUA}
              value={mm.event_suitability.functions_covered}
              onChange={(v) =>
                patchMm({
                  event_suitability: { ...mm.event_suitability, functions_covered: v },
                })
              }
            />
            <MultiCheck
              label="Best for"
              options={BEST_FOR_MUA}
              value={mm.event_suitability.best_for}
              onChange={(v) =>
                patchMm({
                  event_suitability: { ...mm.event_suitability, best_for: v },
                })
              }
            />
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="8">
          <Accordion.Header>Section 9 — Portfolio intelligence</Accordion.Header>
          <Accordion.Body>
            <p className="text-muted fs-14">
              Upload portfolio in the Photos tab (mandatory for go-live). Tag each
              image with: Skin Tone, Makeup Style, Function Type, Lighting Condition,
              Outfit Color.
            </p>
            <div className="mb-3">
              <label className="form-label fw-semibold">Default tagging guidance</label>
              <Form.Control
                className="fs-14"
                value={mm.portfolio_intelligence.tagging_guidance}
                onChange={(e) =>
                  patchMm({
                    portfolio_intelligence: {
                      ...mm.portfolio_intelligence,
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
                value={mm.portfolio_intelligence.notes}
                onChange={(e) =>
                  patchMm({
                    portfolio_intelligence: {
                      ...mm.portfolio_intelligence,
                      notes: e.target.value,
                    },
                  })
                }
              />
            </div>
          </Accordion.Body>
        </Accordion.Item>

        <Accordion.Item eventKey="9">
          <Accordion.Header>Section 10 — AI FAQ</Accordion.Header>
          <Accordion.Body>
            <YesNoField
              groupName="faqHd"
              label="Do you offer HD makeup?"
              value={mm.ai_faq.hd_makeup}
              onChange={(v) => patchMm({ ai_faq: { ...mm.ai_faq, hd_makeup: v } })}
            />
            <YesNoField
              groupName="faqAir"
              label="Do you offer airbrush makeup?"
              value={mm.ai_faq.airbrush_makeup}
              onChange={(v) =>
                patchMm({ ai_faq: { ...mm.ai_faq, airbrush_makeup: v } })
              }
            />
            <YesNoField
              groupName="faqHair"
              label="Is hairstyling included?"
              value={mm.ai_faq.hairstyling_included}
              onChange={(v) =>
                patchMm({ ai_faq: { ...mm.ai_faq, hairstyling_included: v } })
              }
            />
            <YesNoField
              groupName="faqDrape"
              label="Is draping included?"
              value={mm.ai_faq.draping_included}
              onChange={(v) =>
                patchMm({ ai_faq: { ...mm.ai_faq, draping_included: v } })
              }
            />
            <YesNoField
              groupName="faqTrial"
              label="Trial available?"
              value={mm.ai_faq.trial_available}
              onChange={(v) =>
                patchMm({ ai_faq: { ...mm.ai_faq, trial_available: v } })
              }
            />
            <SelectField
              label="Trial cost?"
              options={TRIAL_COST_OPTIONS}
              value={mm.ai_faq.trial_cost}
              onChange={(v) => patchMm({ ai_faq: { ...mm.ai_faq, trial_cost: v } })}
            />
            <YesNoField
              groupName="faqTravel"
              label="Travel available?"
              value={mm.ai_faq.travel_available}
              onChange={(v) =>
                patchMm({ ai_faq: { ...mm.ai_faq, travel_available: v } })
              }
            />
            <YesNoField
              groupName="faqTouch"
              label="Touch-up included?"
              value={mm.ai_faq.touchup_included}
              onChange={(v) =>
                patchMm({ ai_faq: { ...mm.ai_faq, touchup_included: v } })
              }
            />
            <YesNoField
              groupName="faqSkinPrep"
              label="Skin prep included?"
              value={mm.ai_faq.skin_prep_included}
              onChange={(v) =>
                patchMm({ ai_faq: { ...mm.ai_faq, skin_prep_included: v } })
              }
            />
            <MultiCheck
              label="Brands used? (multi)"
              options={BRANDS_ALL_MUA}
              value={mm.ai_faq.brands_used}
              onChange={(v) => patchMm({ ai_faq: { ...mm.ai_faq, brands_used: v } })}
            />
            <MultiCheck
              label="Suitable for skin type? (multi)"
              options={SKIN_TYPES_HANDLED}
              value={mm.ai_faq.suitable_skin_types}
              onChange={(v) =>
                patchMm({ ai_faq: { ...mm.ai_faq, suitable_skin_types: v } })
              }
            />
            <MultiCheck
              label="Suitable for skin tone? (multi)"
              options={SKIN_TONE_EXPERTISE}
              value={mm.ai_faq.suitable_skin_tones}
              onChange={(v) =>
                patchMm({ ai_faq: { ...mm.ai_faq, suitable_skin_tones: v } })
              }
            />
            <YesNoField
              groupName="faqGroom"
              label="Groom makeup offered?"
              value={mm.ai_faq.groom_makeup_offered}
              onChange={(v) =>
                patchMm({ ai_faq: { ...mm.ai_faq, groom_makeup_offered: v } })
              }
            />
            <YesNoField
              groupName="faqAdv"
              label="Advance required?"
              value={mm.ai_faq.advance_required}
              onChange={(v) =>
                patchMm({ ai_faq: { ...mm.ai_faq, advance_required: v } })
              }
            />
            <SelectField
              label="Cancellation policy?"
              options={AI_FAQ_CANCELLATION}
              value={mm.ai_faq.cancellation_policy}
              onChange={(v) =>
                patchMm({ ai_faq: { ...mm.ai_faq, cancellation_policy: v } })
              }
            />
          </Accordion.Body>
        </Accordion.Item>
      </Accordion>
      {!embedded && (
        <button type="button" className="btn btn-primary mt-3 fs-14" onClick={save}>
          Save makeup artist master profile
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

export default MakeupArtistMasterProfile;
