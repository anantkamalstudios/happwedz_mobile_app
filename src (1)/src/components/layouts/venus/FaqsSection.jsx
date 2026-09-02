import React, { useState } from 'react';
import { Container, Row, Col } from 'react-bootstrap';
import { FaChevronDown, FaChevronUp } from 'react-icons/fa';
import { faqssection } from '../../../data/faqssection';

const FaqsSection = () => {
    const [activeIndex, setActiveIndex] = useState(null);

    const toggleFAQ = (index) => {
        setActiveIndex(activeIndex === index ? null : index);
    };

    return (
        <div className="my-5 py-4 faq-section">
            <Container>
                <Col lg={12} className="text-center faqs-content">
                    <h3 className="mb-3  text-semibold text-start">
                        Frequently asked questions regarding Wedding Venues
                    </h3>

                    <div className="accordion">
                        {faqssection.map((faq, index) => (
                            <div
                                key={index}
                                className={`accordion-item ${activeIndex === index ? "active" : ""
                                    }`}
                                onClick={() => toggleFAQ(index)}
                            >
                                <div className="accordion-header">
                                    <div className="d-flex align-items-center">
                                        <span className="faq-icon me-3">{faq.icon}</span>
                                        <h5 className="mb-0">{faq.question}</h5>
                                        <span className="ms-auto">
                                            {activeIndex === index ? (
                                                <FaChevronUp />
                                            ) : (
                                                <FaChevronDown />
                                            )}
                                        </span>
                                    </div>
                                </div>
                                <div
                                    className="accordion-content"
                                    style={{
                                        maxHeight: activeIndex === index ? "200px" : "0",
                                        opacity: activeIndex === index ? "1" : "0",
                                    }}
                                >
                                    <div className="py-3 ps-5">{faq.answer}</div>
                                </div>
                            </div>
                        ))}
                    </div>
                </Col>
            </Container>
        </div>
    );
};

export default FaqsSection;
