import React, { useState } from "react";
import { Container, Row, Col } from "react-bootstrap";
import { FaChevronDown, FaChevronUp } from "react-icons/fa";
import { useFaqFrontend } from "../../../hooks/useFaq";
import ShimmerAccordian from "../../ui/ShimmerAccordian";
import ErrorState from "../../ui/ErrorState";

const FaqsSection = ({ navbarId = null, customFaqs = null }) => {
  const [activeIndex, setActiveIndex] = useState(null);
  const {
    faqs: fetchedFaqs,
    loading,
    error,
    refetch,
  } = useFaqFrontend(navbarId);

  const faqs = customFaqs || fetchedFaqs;

  const toggleFAQ = (index) => {
    setActiveIndex(activeIndex === index ? null : index);
  };

  if (!customFaqs && loading) {
    return (
      <div className="faq-section container my-5">
        <h3 className="text-center mb-4 faq-heading">
          Frequently Asked Questions
        </h3>
        <ShimmerAccordian count={2} />
      </div>
    );
  }

  if (!customFaqs && error) {
    return (
      <ErrorState
        title="We couldn’t load FAQ something went wrong."
        message={error.message || "Please try again later."}
        onRetry={refetch}
      />
    );
  }

  return (
    <div className="faq-section container my-5">
      <h3 className="text-center mb-4 faq-heading">
        Frequently Asked Questions
      </h3>
      <div className="accordion">
        {faqs.map((faq, index) => (
          <div
            key={faq.id || index}
            className={`faq-card ${activeIndex === index ? "active" : ""}`}
            onClick={() => toggleFAQ(index)}
          >
            <div
              className="faq-header d-flex justify-content-between align-items-center"
              style={{ gap: "8px", minWidth: 0 }}
            >
              <h5
                className="faq-question fs-16 mb-0 flex-grow-1 me-2"
                style={{ minWidth: 0, wordBreak: "break-word" }}
              >{`${index + 1}. ${faq.question}`}</h5>
              <span
                className="faq-icon fs-16 flex-shrink-0"
                style={{
                  display: "inline-flex",
                  width: "28px",
                  height: "28px",
                  border: "none",
                  borderRadius: "4px",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                {activeIndex === index ? "−" : "+"}
              </span>
            </div>
            {activeIndex === index && (
              <p className="faq-answer fs-14">{faq.answer}</p>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default FaqsSection;
