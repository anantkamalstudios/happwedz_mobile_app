
import React from 'react';
import { Container, Row, Col } from 'react-bootstrap';
import { FaCheck } from 'react-icons/fa';
import { factors, findfactors } from '../../../data/FactorsList';

const FactorsList = () => {
    return (
        <Container className="my-5">
            <h4 className="fw-semibold mb-4">12 Factors to consider before choosing the venue for your wedding</h4>
            <p className="mb-4">
                Finding the most fitting venue for your wedding ceremonies and celebrations can be a daunting task,
                but we're going to help you narrow your search and guide you through the first steps. Are you ready?
            </p>
            <Row>
                {factors.map((item, index) => (
                    <Col key={index} md={12} className="mb-3 d-flex">
                        <FaCheck className="text-dark me-2 mt-1" />
                        <div>
                            <strong>{item.title}.</strong> {item.content}
                        </div>
                    </Col>
                ))}
            </Row>
            <h4 className="fw-semibold mb-4 mt-3">How to find the right wedding venue near you</h4>
            <Row>
                {findfactors.map((item, index) => (
                    <Col key={index} md={12} className="mb-3 d-flex">
                        <div>
                            {item.content}
                        </div>
                    </Col>
                ))}
            </Row>
        </Container>
    );
};

export default FactorsList;
