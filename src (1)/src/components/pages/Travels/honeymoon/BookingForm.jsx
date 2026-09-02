import React, { useState } from 'react';
import { useSelector } from 'react-redux';
import { useNavigate, useLocation } from 'react-router-dom';
import { User, Phone, Mail, Calendar, Shield } from 'lucide-react';

const BookingForm = ({ flight, verifiedData, searchParams, onSubmit, loading, error }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const user = useSelector((state) => state.auth.user);
  const isAuthenticated = useSelector((state) => state.auth.isAuthenticated);
  const [passengers, setPassengers] = useState([
    {
      type: 'adult',
      first_name: '',
      last_name: '',
      dob: '',
      gender: 'MALE',
      nationality: 'IN',
      doc_type: 'PASSPORT',
      doc_number: '',
      doc_expiry: ''
    }
  ]);
  
  const [contact, setContact] = useState({
    email: '',
    phone: '',
    country_code: '91'
  });

  const handlePassengerChange = (index, field, value) => {
    const newPassengers = [...passengers];
    newPassengers[index][field] = value;
    setPassengers(newPassengers);
  };

  const handleContactChange = (field, value) => {
    setContact(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const addPassenger = () => {
    setPassengers([...passengers, {
      type: 'adult',
      first_name: '',
      last_name: '',
      dob: '',
      gender: 'MALE',
      nationality: 'IN',
      doc_type: 'PASSPORT',
      doc_number: '',
      doc_expiry: ''
    }]);
  };

  const removePassenger = (index) => {
    if (passengers.length > 1) {
      setPassengers(passengers.filter((_, i) => i !== index));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!user || !isAuthenticated) {
      navigate('/customer-login', { replace: false, state: { from: location } });
      return;
    }

    // Use original booking data structure for payment API
    const bookingData = {
      provider: flight.selectedFare.provider,
      offer_id: flight.selectedFare.offer_id,
      trip_type: flight.trip_type,
      from: flight.origin,
      to: flight.destination,
      departure: flight.departure,
      arrival: flight.arrival,
      flight_no: flight.flight_no,
      airline: flight.airline,
      cabin_class: flight.selectedFare.cabin_class,
      price: verifiedData?.price || flight.selectedFare.price,
      passengers: passengers.map(p => ({
        ...p,
        dob: p.dob || '1990-01-01', // Default if not provided
        doc_expiry: p.doc_expiry || '2030-12-31' // Default if not provided
      })),
      contact: {
        ...contact,
        phone: `${contact.country_code}${contact.phone}`
      }
    };

    console.log("selectedFare:", flight.selectedFare);
console.log("selectedFare.provider:", flight.selectedFare?.provider);
console.log("flight.airline:", flight.airline);
    // Call the parent onSubmit with booking data (for payment API)
    onSubmit(bookingData);
  };

  const isFormValid = () => {
    return passengers.every(p => 
      p.first_name && p.last_name && p.doc_number
    ) && contact.email && contact.phone;
  };

  return (
    <>
      <style jsx>{`
        .booking-form {
          max-width: 100%;
        }
        
        .form-section {
          margin-bottom: 24px;
        }
        
        .form-section h6 {
          color: #333;
          margin-bottom: 16px;
          font-weight: 600;
          display: flex;
          align-items: center;
          gap: 8px;
        }
        
        .passenger-card {
          background: #f8f9fa;
          border: 1px solid #e9ecef;
          border-radius: 12px;
          padding: 20px;
          margin-bottom: 16px;
          position: relative;
        }
        
        .form-row {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: 16px;
          margin-bottom: 16px;
        }
        
        .form-group {
          display: flex;
          flex-direction: column;
        }
        
        .form-group label {
          font-size: 12px;
          color: #666;
          margin-bottom: 4px;
          font-weight: 500;
        }
        
        .form-group input,
        .form-group select {
          padding: 10px 12px;
          border: 1px solid #ddd;
          border-radius: 8px;
          font-size: 14px;
          transition: border-color 0.3s ease;
        }
        
        .form-group input:focus,
        .form-group select:focus {
          outline: none;
          border-color: #ed1173;
          box-shadow: 0 0 0 3px rgba(237, 17, 115, 0.1);
        }
        
        .remove-passenger {
          position: absolute;
          top: 10px;
          right: 10px;
          background: #dc3545;
          color: white;
          border: none;
          border-radius: 50%;
          width: 24px;
          height: 24px;
          font-size: 12px;
          cursor: pointer;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        
        .add-passenger-btn {
          background: #28a745;
          color: white;
          border: none;
          padding: 10px 20px;
          border-radius: 8px;
          font-size: 14px;
          cursor: pointer;
          margin-bottom: 20px;
          display: flex;
          align-items: center;
          gap: 8px;
        }
        
        .add-passenger-btn:hover {
          background: #218838;
        }
        
        .submit-btn {
          background: linear-gradient(135deg, #ed1173, #ff6b9d);
          color: white;
          border: none;
          padding: 14px 28px;
          border-radius: 12px;
          font-size: 16px;
          font-weight: 600;
          cursor: pointer;
          width: 100%;
          transition: all 0.3s ease;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }
        
        .submit-btn:hover:not(:disabled) {
          transform: translateY(-2px);
          box-shadow: 0 8px 25px rgba(237, 17, 115, 0.4);
        }
        
        .submit-btn:disabled {
          opacity: 0.6;
          cursor: not-allowed;
          transform: none;
        }
        
        .error-message {
          background: #f8d7da;
          color: #721c24;
          padding: 12px;
          border-radius: 8px;
          margin-bottom: 16px;
          border: 1px solid #f5c6cb;
        }
        
        .price-summary {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 20px;
          border-radius: 12px;
          margin-bottom: 24px;
          text-align: center;
        }
        
        .price-summary .total-price {
          font-size: 24px;
          font-weight: 700;
          margin-bottom: 8px;
        }
        
        .price-summary .price-details {
          font-size: 14px;
          opacity: 0.9;
        }
      `}</style>
      
      <form className="booking-form" onSubmit={handleSubmit}>
      {error && (
        <div className="error-message">
          {error}
        </div>
      )}
      
      {/* Price Summary */}
      <div className="price-summary">
        <div className="total-price">
          Total: ₹{verifiedData?.price || flight.selectedFare?.price}
        </div>
        <div className="price-details">
          {passengers.length} {passengers.length === 1 ? 'Passenger' : 'Passengers'} × 
          ₹{verifiedData?.price || flight.selectedFare?.price}
        </div>
      </div>

      {/* Passengers Section */}
      <div className="form-section">
        <h6>
          <User size={16} />
          Passenger Details
        </h6>
        
        {passengers.map((passenger, index) => (
          <div key={index} className="passenger-card">
            {passengers.length > 1 && (
              <button 
                type="button" 
                className="remove-passenger"
                onClick={() => removePassenger(index)}
              >
                ×
              </button>
            )}
            
            <div className="form-row">
              <div className="form-group">
                <label>First Name *</label>
                <input
                  type="text"
                  value={passenger.first_name}
                  onChange={(e) => handlePassengerChange(index, 'first_name', e.target.value)}
                  required
                  placeholder="John"
                />
              </div>
              
              <div className="form-group">
                <label>Last Name *</label>
                <input
                  type="text"
                  value={passenger.last_name}
                  onChange={(e) => handlePassengerChange(index, 'last_name', e.target.value)}
                  required
                  placeholder="Doe"
                />
              </div>
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label>Date of Birth</label>
                <input
                  type="date"
                  value={passenger.dob}
                  onChange={(e) => handlePassengerChange(index, 'dob', e.target.value)}
                />
              </div>
              
              <div className="form-group">
                <label>Gender</label>
                <select
                  value={passenger.gender}
                  onChange={(e) => handlePassengerChange(index, 'gender', e.target.value)}
                >
                  <option value="MALE">Male</option>
                  <option value="FEMALE">Female</option>
                  <option value="OTHER">Other</option>
                </select>
              </div>
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label>Nationality</label>
                <input
                  type="text"
                  value={passenger.nationality}
                  onChange={(e) => handlePassengerChange(index, 'nationality', e.target.value)}
                  placeholder="IN"
                  maxLength={2}
                />
              </div>
              
              <div className="form-group">
                <label>Document Type</label>
                <select
                  value={passenger.doc_type}
                  onChange={(e) => handlePassengerChange(index, 'doc_type', e.target.value)}
                >
                  <option value="PASSPORT">Passport</option>
                  <option value="AADHAR">Aadhar</option>
                  <option value="DRIVING_LICENSE">Driving License</option>
                </select>
              </div>
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label>Document Number *</label>
                <input
                  type="text"
                  value={passenger.doc_number}
                  onChange={(e) => handlePassengerChange(index, 'doc_number', e.target.value)}
                  required
                  placeholder="P1234567"
                />
              </div>
              
              <div className="form-group">
                <label>Document Expiry</label>
                <input
                  type="date"
                  value={passenger.doc_expiry}
                  onChange={(e) => handlePassengerChange(index, 'doc_expiry', e.target.value)}
                />
              </div>
            </div>
          </div>
        ))}
        
        <button
          type="button"
          className="add-passenger-btn"
          onClick={addPassenger}
        >
          + Add Passenger
        </button>
      </div>

      {/* Contact Section */}
      <div className="form-section">
        <h6>
          <Phone size={16} />
          Contact Details
        </h6>
        
        <div className="form-row">
          <div className="form-group">
            <label>Email *</label>
            <input
              type="email"
              value={contact.email}
              onChange={(e) => handleContactChange('email', e.target.value)}
              required
              placeholder="john@example.com"
            />
          </div>
          
          <div className="form-group">
            <label>Phone *</label>
            <div style={{ display: 'flex', gap: '8px' }}>
              <input
                type="text"
                value={contact.country_code}
                onChange={(e) => handleContactChange('country_code', e.target.value)}
                placeholder="91"
                maxLength={3}
                style={{ width: '80px' }}
              />
              <input
                type="tel"
                value={contact.phone}
                onChange={(e) => handleContactChange('phone', e.target.value)}
                required
                placeholder="9876543210"
              />
            </div>
          </div>
        </div>
      </div>

      {/* Submit Button */}
      <button
        type="submit"
        className="submit-btn"
        disabled={loading || !isFormValid()}
      >
        {loading ? (
          <>
            <span className="spinner-border spinner-border-sm me-2" role="status"></span>
            Processing Booking...
          </>
        ) : (
          <>
            <Shield size={16} className="me-2" />
            Complete Booking
          </>
        )}
      </button>
      </form>
    </>
  );
};

export default BookingForm;
