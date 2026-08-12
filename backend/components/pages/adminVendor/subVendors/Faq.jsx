import React, { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import { FaqQuestions } from "./FaqData.js";

function Faq({ formData, setFormData, onSave }) {
  const { vendor } = useSelector((state) => state.vendorAuth);
  const [questions, setQuestions] = useState([]);
  const [answers, setAnswers] = useState(formData.faqs || {});
  const [subcategories, setSubcategories] = useState([]);
  const vendorTypeId = Number(vendor?.vendor_type_id || vendor?.vendorType?.id) || null;
  const [isSaving, setIsSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [saveError, setSaveError] = useState(null);

  useEffect(() => {
    if (!vendor?.id) return;

    async function fetchAnswers() {
      try {
        const res = await fetch(
          `https://happywedz.com/api/faq-answers/${vendor.id}`
        );
        if (!res.ok) return;
        const data = await res.json();
        const answerMap = {};
        (Array.isArray(data) ? data : []).forEach((a) => {
          const qid = a.faqQuestionId ?? a.faq_question_id ?? a.faq_questionid;
          if (qid == null) return;

          let val = a.answer;
          if (typeof val === "string") {
            const s = val.trim();
            if (
              (s.startsWith("{") && s.endsWith("}")) ||
              (s.startsWith("[") && s.endsWith("]"))
            ) {
              try {
                val = JSON.parse(s);
              } catch {}
            }
          }
          answerMap[qid] = val;
        });
        setAnswers(answerMap);
      } catch (err) {
        // silent fail
      }
    }

    fetchAnswers();
  }, [vendor?.id]);

  const [subcatName, setSubcatName] = useState("");

  useEffect(() => {
    const fetchSubcategory = async () => {
      if (vendor?.vendor_type_id) {
        try {
          const res = await fetch(`https://happywedz.com/api/vendor-types/${vendor.vendor_type_id}`);
          if (!res.ok) return;
          const typeData = await res.json();
          const subcategoryId = formData.vendor_subcategory_id || vendor?.vendor_subcategory_id;
          const subcats = typeData.subcategories || [];
          const subcat = subcats.find(s => s.id == subcategoryId);
          if (subcat && subcat.name) {
            setSubcatName(subcat.name);
          } else {
            setSubcatName(typeData.name || "");
          }
        } catch (err) {
          console.error("Error fetching subcategory for FAQs:", err);
        }
      }
    };
    fetchSubcategory();
  }, [vendor?.vendor_type_id, formData.vendor_subcategory_id, vendor?.vendor_subcategory_id]);

  useEffect(() => {
    async function fetchVendorType() {
      if (vendor?.vendor_type_id) {
        try {
          const res = await fetch(`https://happywedz.com/api/vendor-types/${vendor.vendor_type_id}`);
          if (res.ok) {
            const data = await res.json();
            setSubcategories(data?.subcategories || []);
          }
        } catch (err) {
          console.error("Error fetching vendor type:", err);
        }
      }
    }
    fetchVendorType();
  }, [vendor?.vendor_type_id]);

  useEffect(() => {
    let vendorTypeKey = null;

    const activeSubcategoryId = formData?.vendor_subcategory_id || vendor?.vendor_subcategory_id;
    const resolvedSubcategoryName = subcategories.find(
      (s) => String(s.id) === String(activeSubcategoryId)
    )?.name || subcatName || formData?.vendor_subcategory_name || formData?.attributes?.vendor_subcategory_name || "";
    const normalizedSub = resolvedSubcategoryName.toLowerCase();

    // Direct subcategory-based matching first
    // Priority: Sherwani-on-rent (vendor_type_id 22) FIRST before generic rent patterns
    const isSherwaniVendor = normalizedSub.includes("sherwani") || 
      (formData?.vendor_subcategory_name || "").toLowerCase().includes("sherwani") ||
      (formData?.attributes?.vendor_subcategory_name || "").toLowerCase().includes("sherwani") ||
      (formData?.name || "").toLowerCase().includes("sherwani");
    
    if (vendorTypeId === 22 && isSherwaniVendor) {
      vendorTypeKey = "groomwear";
    } else if (normalizedSub.includes("flower jewellery") || normalizedSub.includes("floral jewellery") || normalizedSub.includes("flower jewelry") || normalizedSub.includes("floral jewelry")) {
      vendorTypeKey = "flowerjewellery";
    } else if (normalizedSub.includes("kanjeevaram") || normalizedSub.includes("silk saree")) {
      vendorTypeKey = "kanjeevaramsilksaree";
    } else if (normalizedSub.includes("rental outfit") || normalizedSub.includes("lehenga on rent") || normalizedSub.includes("on rent") || normalizedSub.includes("rent")) {
      if (normalizedSub.includes("jewel")) {
        vendorTypeKey = "jewelleryrental";
      } else {
        vendorTypeKey = "rentaloutfit";
      }
    } else if (normalizedSub.includes("accessories")) {
      vendorTypeKey = "accessories";
    } else if (normalizedSub.includes("jewellery rental") || normalizedSub.includes("jewel rental") || (normalizedSub.includes("jewell") && normalizedSub.includes("rent"))) {
      vendorTypeKey = "jewelleryrental";
    } else if (normalizedSub.includes("cocktail gown") || normalizedSub.includes("gowns")) {
      vendorTypeKey = "cocktailgowns";
    } else if (normalizedSub.includes("trousseau packer") || normalizedSub.includes("trousseau pack")) {
      vendorTypeKey = "trousseaupacker";
    } else if (normalizedSub.includes("trousseau sarees") || normalizedSub.includes("trousseau saree")) {
      vendorTypeKey = "trousseausarees";
    } else if (normalizedSub.includes("lehenga") || normalizedSub.includes("bridal outfit") || normalizedSub.includes("trousseau")) {
      vendorTypeKey = "bridaloutfit";
    } else if (normalizedSub.includes("favor") || normalizedSub.includes("favour")) {
      vendorTypeKey = "gifts";
    }

    // 1. Fallback to Sakshi's subcategory overrides based on active master profiles
    if (!vendorTypeKey) {
      // Special: If Sherwani-on-rent (vendor_type_id 22), prioritize groomwear over rental_outfit_master
      if (vendorTypeId === 22 && (normalizedSub.includes("sherwani") || formData?.vendor_subcategory_name?.toLowerCase().includes("sherwani") || formData?.attributes?.vendor_subcategory_name?.toLowerCase().includes("sherwani"))) {
        vendorTypeKey = "groomwear";
      } else if (formData?.accessories_master && Object.keys(formData.accessories_master).length > 0) {
        vendorTypeKey = "accessories";
      } else if (formData?.jewellery_rental_master && Object.keys(formData.jewellery_rental_master).length > 0) {
        vendorTypeKey = "jewelleryrental";
      } else if (formData?.flower_jewellery_master && Object.keys(formData.flower_jewellery_master).length > 0) {
        vendorTypeKey = "flowerjewellery";
      } else if (formData?.rental_outfit_master && Object.keys(formData.rental_outfit_master).length > 0 && vendorTypeId !== 22) {
        vendorTypeKey = "rentaloutfit";
      } else if (formData?.rental_outfit_master && Object.keys(formData.rental_outfit_master).length > 0) {
        // If vendor_type_id is 22 but we're here, it's sherwani - use groomwear
        vendorTypeKey = "groomwear";
      } else if (formData?.trousseau_master && Object.keys(formData.trousseau_master).length > 0) {
        vendorTypeKey = "trousseaupacker";
      } else if (formData?.gift_master && Object.keys(formData.gift_master).length > 0) {
        vendorTypeKey = "gifts";
      } else if (formData?.favor_master && Object.keys(formData.favor_master).length > 0) {
        vendorTypeKey = "gifts";
      } else if (formData?.invitation_master && Object.keys(formData.invitation_master).length > 0) {
        vendorTypeKey = "gifts";
      } else if (formData?.bridal_outfit_master && Object.keys(formData.bridal_outfit_master).length > 0) {
        // Detect Kanjeevaram Silk Saree vs generic Bridal Outfit
        const subcatNameVal = (
          formData?.vendor_subcategory_name ||
          formData?.attributes?.vendor_subcategory_name ||
          ""
        ).toLowerCase();
        const vendorNameVal = (
          formData?.name ||
          formData?.attributes?.name ||
          ""
        ).toLowerCase();
        const isKanjeevaram =
          subcatNameVal.includes("kanjeevaram") ||
          subcatNameVal.includes("silk saree") ||
          subcatNameVal.includes("silk") ||
          vendorNameVal.includes("kanjeevaram") ||
          vendorNameVal.includes("silk saree");
        vendorTypeKey = isKanjeevaram ? "kanjeevaramsilksaree" : "bridaloutfit";
      }
    }

    // 2. If still not matched, use HEAD's subcategory detection logic
    if (!vendorTypeKey) {
      const isLocMaster = formData?.pre_wedding_location_master && Object.keys(formData.pre_wedding_location_master).length > 0;
      const isPhotoMaster = formData?.pre_wedding_photographer_master && Object.keys(formData.pre_wedding_photographer_master).length > 0;
      const isDjMaster = formData?.dj_master && Object.keys(formData.dj_master).length > 0;
      const isChoreoMaster = formData?.sangeet_choreographer_master && Object.keys(formData.sangeet_choreographer_master).length > 0;
      const isEntMaster = formData?.wedding_entertainer_master && Object.keys(formData.wedding_entertainer_master).length > 0;

      vendorTypeKey = Object.keys(FaqQuestions).find((key) => {
        const entry = FaqQuestions[key];
        if (entry.vendor_type_id !== vendorTypeId) return false;
        if (entry.subcategory_keyword === "location") {
          return normalizedSub.includes("location") || isLocMaster;
        }
        if (entry.subcategory_keyword === "photographer") {
          return normalizedSub.includes("photographer") || isPhotoMaster;
        }
        if (entry.subcategory_keyword === "dj") {
          return normalizedSub.includes("dj") || isDjMaster;
        }
        if (entry.subcategory_keyword === "choreographer") {
          return normalizedSub.includes("choreographer") || isChoreoMaster;
        }
        if (entry.subcategory_keyword === "entertainer") {
          return normalizedSub.includes("entertainment") || normalizedSub.includes("entertainer") || isEntMaster;
        }
        return true;
      });
    }

    // 3. Fallback: if still no vendorTypeKey but we have a matching vendor_type_id
    if (!vendorTypeKey) {
      vendorTypeKey = Object.keys(FaqQuestions).find(
        (key) => FaqQuestions[key].vendor_type_id === vendorTypeId
      );
    }

      if (vendorTypeKey && FaqQuestions[vendorTypeKey]) {
        const allQuestions = FaqQuestions[vendorTypeKey].questions || [];
        const normSubcat = (subcatName || "").trim().toLowerCase();

        // 3a. Groomwear (vendor_type_id: 11 or Sherwani rental under type 22)
        if (vendorTypeId === 11 || (vendorTypeId === 22 && vendorTypeKey === "groomwear")) {
          const isSherwani = normSubcat.includes("sherwani");
          const isWeddingSuit = normSubcat.includes("suit") || normSubcat.includes("wedding suite");

          const filtered = allQuestions.filter(q => {
            const qid = q.id;
            if (qid >= 401 && qid <= 410) return true;
            if (qid >= 411 && qid <= 425) return isSherwani;
            if (qid >= 426 && qid <= 435) return isWeddingSuit;
            return true;
          });
          setQuestions(filtered);
        }
        // 3b. Decorators (vendor_type_id: 4) filter questions
        else if (vendorTypeId === 4) {
          const isDecorator = normSubcat.includes("decorator") || normSubcat.includes("decor") || normSubcat.includes("event styling");
          const filtered = allQuestions.filter(q => {
            const qid = q.id;
            if (qid >= 1201 && qid <= 1212) return true;
            if (qid >= 1213 && qid <= 1225) return isDecorator;
            return true;
          });
          setQuestions(filtered);
        }
        // 3c. Invites & Gifts (vendor_type_id: 9) filter questions
        else if (vendorTypeId === 9) {
          // Check master profiles first (priority)
          const hasTrousseauMaster = formData?.trousseau_master && Object.keys(formData.trousseau_master).length > 0;
          const hasGiftMaster = formData?.gift_master && Object.keys(formData.gift_master).length > 0;
          const hasFavorMaster = formData?.favor_master && Object.keys(formData.favor_master).length > 0;
          const hasInvitationMaster = formData?.invitation_master && Object.keys(formData.invitation_master).length > 0;

          // Determine vendor type with priority: master profile > subcategory name
          const isTrousseauPacker = hasTrousseauMaster || (!hasGiftMaster && !hasFavorMaster && !hasInvitationMaster && (normSubcat.includes("trousseau packer") || normSubcat.includes("trousseau pack")));
          const isGift = hasGiftMaster || (!hasFavorMaster && !hasInvitationMaster && !hasTrousseauMaster && (normSubcat === "gifts" || normSubcat === "gift" || normSubcat.includes("gifting") || (normSubcat.includes("invitation") && normSubcat.includes("gift"))));
          const isFavor = hasFavorMaster || (!hasGiftMaster && !hasInvitationMaster && !hasTrousseauMaster && (normSubcat.includes("favor") || normSubcat.includes("favour")));
          const isInvitation = hasInvitationMaster || (!hasGiftMaster && !hasFavorMaster && !hasTrousseauMaster && ((normSubcat.includes("invitation") || normSubcat.includes("invite")) && !normSubcat.includes("gift")));

          const filtered = allQuestions.filter(q => {
            const qid = q.id;
            // Show general questions (2101-2115) ONLY if no specific master profile exists
            if (qid >= 2101 && qid <= 2115) {
              return !hasTrousseauMaster && !hasGiftMaster && !hasFavorMaster && !hasInvitationMaster;
            }
            if (qid >= 2116 && qid <= 2129) return isTrousseauPacker;
            if (qid >= 2130 && qid <= 2144) return isGift;
            if (qid >= 2145 && qid <= 2159) return isFavor;
            if (qid >= 2160 && qid <= 2172) return isInvitation;
            return false;
          });
          setQuestions(filtered);
        }
        else {
          setQuestions(allQuestions);
        }
      } else {
        setQuestions([]);
      }
  }, [
    vendor?.vendor_type_id,
    subcatName,
    formData?.vendor_subcategory_id,
    vendor?.vendor_subcategory_id,
    subcategories,
    formData?.accessories_master,
    formData?.jewellery_rental_master,
    formData?.flower_jewellery_master,
    formData?.rental_outfit_master,
    formData?.bridal_outfit_master,
    formData?.vendor_subcategory_name,
    formData?.attributes?.vendor_subcategory_name,
    formData?.name,
  ]);

  useEffect(() => {
    setFormData((prev) => ({ ...prev, faqs: answers }));
  }, [answers, setFormData]);

  const handleAnswerChange = (questionId, value) => {
    setAnswers((prev) => ({
      ...prev,
      [questionId]: value,
    }));
  };

  const flattenOtherRadioAnswers = (raw) => {
    const out = { ...raw };
    const suffix = "_other";
    Object.keys(raw).forEach((key) => {
      if (!String(key).endsWith(suffix)) return;
      const baseId = String(key).slice(0, -suffix.length);
      const detail = raw[key];
      if (out[baseId] === "Other" && detail && String(detail).trim()) {
        out[baseId] = `Other: ${String(detail).trim()}`;
      }
      delete out[key];
    });
    return out;
  };

  // Save answers to backend
  const handleSave = async () => {
    if (!vendor?.id || !vendor?.vendor_type_id) {
      setSaveError("Cannot save: Vendor ID or Vendor Type ID is missing.");
      return;
    }
    setIsSaving(true);
    setSaveSuccess(false);
    setSaveError(null);

    const mergedAnswers = flattenOtherRadioAnswers(answers);
    const payload = {
      vendorId: vendor.id,
      vendorTypeId: vendor.vendor_type_id,
      answers: Object.entries(mergedAnswers).map(([faqQuestionId, answer]) => ({
        faqQuestionId,
        answer,
      })),
    };
    try {
      const res = await fetch("https://happywedz.com/api/faq-answers/save", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      if (res.ok) {
        setSaveSuccess(true);
        if (onSave) onSave();
        setTimeout(() => setSaveSuccess(false), 5000);
      } else {
        const errData = await res.json().catch(() => ({}));
        setSaveError(errData.details || errData.error || "Failed to save FAQ answers. Please try again.");
      }
    } catch (err) {
      setSaveError("Network error: Could not connect to server to save FAQ answers.");
    } finally {
      setIsSaving(false);
    }
  };

  if (!vendor) {
    return (
      <div className="p-3 border rounded bg-white text-muted">
        Loading vendor information...
      </div>
    );
  }

  if (questions.length === 0) {
    return (
      <div className="p-3 border rounded bg-white text-muted">
        No FAQ questions are available for this vendor type.
      </div>
    );
  }

  const checkboxAnswerHandler = (questionId, value) => {
    const prevResponses = answers[questionId] || [];
    let newResponses;
    if (prevResponses.includes(value)) {
      newResponses = prevResponses.filter((item) => item !== value);
    } else {
      newResponses = [...prevResponses, value];
    }
    handleAnswerChange(questionId, newResponses);
  };

  const renderQuestionInput = (q) => {
    switch (q.type) {
      case "text":
        return (
          <div className="mb-2">
            {q.label && q.label.length > 0 ? (
              q.label.map((label, index) => (
                <div key={index} className="mb-2">
                  <label className="form-label fw-semibold fs-16">
                    {label}
                  </label>
                  <input
                    type="text"
                    className="form-control fs-14"
                    value={answers[q.id] || ""}
                    onChange={(e) => handleAnswerChange(q.id, e.target.value)}
                  />
                </div>
              ))
            ) : (
              <div className="mb-2">
                <input
                  type="text"
                  className="form-control fs-14"
                  value={answers[q.id] || ""}
                  onChange={(e) => handleAnswerChange(q.id, e.target.value)}
                />
              </div>
            )}
          </div>
        );
      case "textarea":
        return (
          <div>
            <textarea
              className="form-control fs-14"
              rows={3}
              value={answers[q.id] || ""}
              onChange={(e) => handleAnswerChange(q.id, e.target.value)}
            />
          </div>
        );
      case "range":
        return (
          <div>
            <input
              type="range"
              min={q.min || 0}
              max={q.max || 100}
              className="form-range slider-range-input"
              value={answers[q.id] || 0}
              onChange={(e) => handleAnswerChange(q.id, e.target.value)}
            />
            <div className="d-flex justify-content-between fs-14">
              <span>₹ {answers[q.id] || 0}</span>
              <span>₹ {q.max}+</span>
            </div>
          </div>
        );
      case "radio":
        return (
          <div>
            <div className="d-flex flex-wrap gap-2">
              {q.options.map((option, index) => (
                <label
                  key={index}
                  className="form-check d-flex align-items-center gap-2 fs-14 me-3"
                >
                  <input
                    type="radio"
                    name={`radio_${q.id}`}
                    value={option}
                    checked={answers[q.id] === option}
                    onChange={() => handleAnswerChange(q.id, option)}
                    className="form-check-input me-1"
                  />
                  {option}
                </label>
              ))}
            </div>
            {q.allowOther && answers[q.id] === "Other" && (
              <input
                type="text"
                className="form-control fs-14 mt-2"
                placeholder="Please specify"
                value={answers[`${q.id}_other`] || ""}
                onChange={(e) =>
                  handleAnswerChange(`${q.id}_other`, e.target.value)
                }
              />
            )}
          </div>
        );
      case "checkbox":
        return (
          <div>
            <div className="d-flex flex-wrap gap-2">
              {q.options.map((option, index) => (
                <label
                  key={index}
                  className="form-check d-flex align-items-center gap-2 fs-14 me-3"
                >
                  <input
                    type="checkbox"
                    name={q.id}
                    value={option}
                    checked={
                      Array.isArray(answers[q.id]) &&
                      answers[q.id].includes(option)
                    }
                    onChange={() => checkboxAnswerHandler(q.id, option)}
                    className="form-check-input me-1"
                  />
                  {option}
                </label>
              ))}
            </div>
          </div>
        );
      case "number":
        return (
          <div className="mb-2">
            {q.label && q.label.length > 0 ? (
              q.label.map((label, index) => (
                <div key={index} className="mb-2">
                  <label className="form-label fw-semibold fs-16">
                    {label}
                  </label>
                  <input
                    inputMode="numeric"
                    min="0"
                    type="number"
                    className="form-control fs-14"
                    value={(answers[q.id] && answers[q.id][index]) || ""}
                    onChange={(e) => {
                      const newAnswer = { ...(answers[q.id] || {}) };
                      newAnswer[index] = e.target.value;
                      handleAnswerChange(q.id, newAnswer);
                    }}
                  />
                </div>
              ))
            ) : (
              <div className="mb-2">
                <input
                  type="number"
                  className="form-control fs-14"
                  value={answers[q.id] || ""}
                  onChange={(e) => handleAnswerChange(q.id, e.target.value)}
                />
              </div>
            )}
          </div>
        );
      default:
        return null;
    }
  };

  return (
    <div className="container my-5">
      <div className="faq-intro-card mb-4 primary-light-bg">
        <div className="intro-inner p-0">
          <div className="d-flex px-3 pt-3 pb-2">
            <div className="col-1">
              <img
                src="/images/vendorsDashboard/faq.png"
                alt="FAQ"
                width={30}
                height={30}
                className="img-fluid faq-image d-block mb-2"
                style={{ marginLeft: 0 }}
              />
            </div>
            <div className="">
              <h5 className="intro-title fs-16 px-2" style={{ color: "red" }}>
                Please provide details about your services.
              </h5>
              <p className="intro-sub fs-14 px-2" style={{ color: "black" }}>
                Add responses to frequently asked questions about your business
                to give couples a better understanding of your offering before
                deciding whether to contact you.
              </p>
            </div>
          </div>
        </div>
      </div>

      {questions.map((q, idx) => (
        <div className="card shadow-sm mb-3 faq-card" key={q.id}>
          <div className="card-body">
            <div className="qa-top">
              {/* <div className="faq-number">{idx + 1}</div> */}
              <p className="question-text fs-16">{q.text}</p>
            </div>
            <div>
              {q.description && (
                <p className="text-muted fs-14">{q.description}</p>
              )}
              <div className="mh-100 mt-3 fs-14">{renderQuestionInput(q)}</div>
            </div>
          </div>
        </div>
      ))}
      {saveSuccess && (
        <div className="alert alert-success text-center mb-3 fs-14 shadow-sm" role="alert">
          FAQ answers saved successfully!
        </div>
      )}
      {saveError && (
        <div className="alert alert-danger text-center mb-3 fs-14 shadow-sm" role="alert">
          {saveError}
        </div>
      )}
      <div className="w-100 fs-14 d-flex justify-content-center align-content-center">
        <button
          type="submit"
          onClick={handleSave}
          disabled={isSaving}
          className="px-4 py-2 rounded btn-primary"
        >
          {isSaving ? "Saving..." : "Submit"}
        </button>
      </div>
    </div>
  );
}

export default Faq;
