import { useState } from 'react';
import { FaUser, FaPhone, FaEnvelope } from 'react-icons/fa';

export default function PassengerDetails({ searchParams, reviewData, onBack, onContinue }) {
  const adults = searchParams.adults || 1;
  const children = searchParams.children || 0;
  const infants = searchParams.infants || 0;

  // Drive required fields from the TripJack review conditions instead of hardcoding.
  const conditions = reviewData?.conditions || {};
  const pcs = conditions.pcs || null; // passport conditions (international only)
  const isDomestic = reviewData?.searchQuery?.isDomestic !== false && !pcs;
  const passportMandatory = !isDomestic && (pcs?.pm !== false); // require passport for international
  const passportIssueDateReq = !!pcs?.pid;
  // Document id (student / senior citizen fares)
  const docIdApplicable = !!conditions?.dc?.ida || (searchParams.paxType && searchParams.paxType !== 'REGULAR');
  const docIdMandatory = !!conditions?.dc?.idm;
  // PAN required for this fare (docs: conditions.ipa — Is PAN Applicable)
  const panRequired = !!conditions?.ipa;
  // Emergency contact required (docs: conditions.iecr)
  const emergencyRequired = !!conditions?.iecr;
  // DOB requirements per pax type
  const adultDobReq = conditions?.dob?.adobr !== false;

  const [passengers, setPassengers] = useState(
    Array.from({ length: adults + children + infants }, (_, i) => ({
      title: 'Mr',
      firstName: '',
      lastName: '',
      dob: '',
      gender: 'Male',
      nationality: 'IN',
      passportNumber: '',
      passportExpiry: '',
      passportIssueDate: '',
      documentId: '',
      pan: '',
      type: i < adults ? 'ADULT' : i < adults + children ? 'CHILD' : 'INFANT',
    }))
  );

  const [contact, setContact] = useState({
    countryCode: '+91',
    mobile: '',
    email: '',
  });

  // Emergency contact (only collected when conditions.iecr is true)
  const [emergency, setEmergency] = useState({ name: '', email: '', mobile: '' });
  
  const [gst, setGst] = useState({
    enabled: false,
    companyName: '',
    gstNumber: '',
    companyEmail: '',
  });
  
  const [errors, setErrors] = useState({});

  const handlePassengerChange = (index, field, value) => {
    const updated = [...passengers];
    updated[index][field] = value;
    setPassengers(updated);
    
    if (errors[`passenger_${index}_${field}`]) {
      const newErrors = { ...errors };
      delete newErrors[`passenger_${index}_${field}`];
      setErrors(newErrors);
    }
  };

  const validateAge = (dob, type) => {
    const birthDate = new Date(dob);
    const today = new Date();
    const age = Math.floor((today - birthDate) / (365.25 * 24 * 60 * 60 * 1000));
    
    if (type === 'ADULT' && age < 12) return 'Adult must be 12 years or older';
    if (type === 'CHILD' && (age < 2 || age >= 12)) return 'Child must be between 2-12 years';
    if (type === 'INFANT' && age >= 2) return 'Infant must be under 2 years';
    
    return null;
  };

  const validateForm = () => {
    const newErrors = {};
    
    passengers.forEach((passenger, index) => {
      if (!passenger.firstName.trim()) {
        newErrors[`passenger_${index}_firstName`] = 'First name is required';
      }
      if (!passenger.lastName.trim()) {
        newErrors[`passenger_${index}_lastName`] = 'Last name is required';
      }
      if (!passenger.dob) {
        newErrors[`passenger_${index}_dob`] = 'Date of birth is required';
      } else {
        const ageError = validateAge(passenger.dob, passenger.type);
        if (ageError) {
          newErrors[`passenger_${index}_dob`] = ageError;
        }
      }
      
      if (passportMandatory) {
        if (!passenger.passportNumber.trim()) {
          newErrors[`passenger_${index}_passportNumber`] = 'Passport number is required';
        }
        if (!passenger.passportExpiry) {
          newErrors[`passenger_${index}_passportExpiry`] = 'Passport expiry is required';
        } else {
          const expiryDate = new Date(passenger.passportExpiry);
          const sixMonthsFromNow = new Date();
          sixMonthsFromNow.setMonth(sixMonthsFromNow.getMonth() + 6);
          if (expiryDate < sixMonthsFromNow) {
            newErrors[`passenger_${index}_passportExpiry`] = 'Passport must be valid for at least 6 months';
          }
        }
        if (passportIssueDateReq && !passenger.passportIssueDate) {
          newErrors[`passenger_${index}_passportIssueDate`] = 'Passport issue date is required';
        }
      }

      if (docIdMandatory && !passenger.documentId.trim()) {
        newErrors[`passenger_${index}_documentId`] = 'Document ID is required for this fare';
      }

      if (panRequired) {
        const pan = (passenger.pan || '').trim().toUpperCase();
        if (!/^[A-Z]{5}[0-9]{4}[A-Z]$/.test(pan)) {
          newErrors[`passenger_${index}_pan`] = 'Valid 10-character PAN is required (e.g. ABCDE1234F)';
        }
      }
    });

    if (!contact.mobile.trim() || contact.mobile.length < 10) {
      newErrors.mobile = 'Valid mobile number is required';
    }
    if (!contact.email.trim() || !contact.email.includes('@')) {
      newErrors.email = 'Valid email is required';
    }

    if (emergencyRequired) {
      if (!emergency.name.trim()) newErrors.emergencyName = 'Emergency contact name is required';
      if (!emergency.email.trim() || !emergency.email.includes('@')) newErrors.emergencyEmail = 'Valid emergency email is required';
      if (!emergency.mobile.trim() || emergency.mobile.length < 10) newErrors.emergencyMobile = 'Valid emergency mobile is required';
    }

    if (gst.enabled) {
      if (!gst.companyName.trim()) {
        newErrors.gstCompanyName = 'Company name is required';
      }
      if (!gst.gstNumber.trim() || gst.gstNumber.length !== 15) {
        newErrors.gstNumber = 'Valid GST number is required (15 characters)';
      }
      if (!gst.companyEmail.trim() || !gst.companyEmail.includes('@')) {
        newErrors.gstEmail = 'Valid company email is required';
      }
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    
    if (!validateForm()) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
      return;
    }
    
    const travellerInfo = passengers.map(p => ({
      ti: p.title,
      fN: p.firstName,
      lN: p.lastName,
      pt: p.type,
      dob: p.dob,
      ...(passportMandatory && {
        pNat: p.nationality,
        pNum: p.passportNumber,
        eD: p.passportExpiry,
        ...(p.passportIssueDate && { pid: p.passportIssueDate }),
      }),
      ...(docIdApplicable && p.documentId && { di: p.documentId }),
      ...(panRequired && p.pan && { pan: p.pan.trim().toUpperCase() }),
    }));

    // Emergency contact (contactInfo) — only when the fare requires it (iecr).
    const emergencyContact = emergencyRequired
      ? {
          name: emergency.name.trim(),
          email: emergency.email.trim(),
          mobile: `${contact.countryCode.replace(/^\+/, '')}${emergency.mobile.trim()}`,
        }
      : null;

    onContinue(travellerInfo, contact, gst.enabled ? gst : null, emergencyContact);
  };

  const renderPassengerForm = (passenger, index) => {
    const passengerLabel = passenger.type === 'ADULT' 
      ? `Adult ${index + 1}` 
      : passenger.type === 'CHILD' 
      ? `Child ${index - adults + 1}` 
      : `Infant ${index - adults - children + 1}`;
    
    return (
      <div key={index} className="passenger-form-card mb-3">
        <h6 className="passenger-form-title">
          <FaUser className="me-2" />
          {passengerLabel}
        </h6>
        
        <div className="row g-3">
          <div className="col-md-2">
            <label className="form-label">Title *</label>
            <select
              className="form-select"
              value={passenger.title}
              onChange={(e) => handlePassengerChange(index, 'title', e.target.value)}
            >
              <option value="Mr">Mr</option>
              <option value="Mrs">Mrs</option>
              <option value="Ms">Ms</option>
              <option value="Master">Master</option>
            </select>
          </div>
          
          <div className="col-md-5">
            <label className="form-label">First Name *</label>
            <input
              type="text"
              className={`form-control ${errors[`passenger_${index}_firstName`] ? 'is-invalid' : ''}`}
              value={passenger.firstName}
              onChange={(e) => handlePassengerChange(index, 'firstName', e.target.value)}
              placeholder="As per passport/ID"
            />
            {errors[`passenger_${index}_firstName`] && (
              <div className="invalid-feedback">{errors[`passenger_${index}_firstName`]}</div>
            )}
          </div>
          
          <div className="col-md-5">
            <label className="form-label">Last Name *</label>
            <input
              type="text"
              className={`form-control ${errors[`passenger_${index}_lastName`] ? 'is-invalid' : ''}`}
              value={passenger.lastName}
              onChange={(e) => handlePassengerChange(index, 'lastName', e.target.value)}
              placeholder="As per passport/ID"
            />
            {errors[`passenger_${index}_lastName`] && (
              <div className="invalid-feedback">{errors[`passenger_${index}_lastName`]}</div>
            )}
          </div>
          
          <div className="col-md-4">
            <label className="form-label">Date of Birth *</label>
            <input
              type="date"
              className={`form-control ${errors[`passenger_${index}_dob`] ? 'is-invalid' : ''}`}
              value={passenger.dob}
              onChange={(e) => handlePassengerChange(index, 'dob', e.target.value)}
              max={new Date().toISOString().split('T')[0]}
            />
            {errors[`passenger_${index}_dob`] && (
              <div className="invalid-feedback">{errors[`passenger_${index}_dob`]}</div>
            )}
          </div>
          
          <div className="col-md-4">
            <label className="form-label">Gender *</label>
            <select
              className="form-select"
              value={passenger.gender}
              onChange={(e) => handlePassengerChange(index, 'gender', e.target.value)}
            >
              <option value="Male">Male</option>
              <option value="Female">Female</option>
            </select>
          </div>
          
          {passportMandatory && (
            <>
              <div className="col-md-4">
                <label className="form-label">Nationality *</label>
                <input
                  type="text"
                  className="form-control"
                  value={passenger.nationality}
                  onChange={(e) => handlePassengerChange(index, 'nationality', e.target.value.toUpperCase())}
                  placeholder="IN"
                  maxLength={2}
                />
              </div>

              <div className="col-md-4">
                <label className="form-label">Passport Number *</label>
                <input
                  type="text"
                  className={`form-control ${errors[`passenger_${index}_passportNumber`] ? 'is-invalid' : ''}`}
                  value={passenger.passportNumber}
                  onChange={(e) => handlePassengerChange(index, 'passportNumber', e.target.value.toUpperCase())}
                  placeholder="PASS1234"
                />
                {errors[`passenger_${index}_passportNumber`] && (
                  <div className="invalid-feedback">{errors[`passenger_${index}_passportNumber`]}</div>
                )}
              </div>

              <div className="col-md-4">
                <label className="form-label">Passport Expiry *</label>
                <input
                  type="date"
                  className={`form-control ${errors[`passenger_${index}_passportExpiry`] ? 'is-invalid' : ''}`}
                  value={passenger.passportExpiry}
                  onChange={(e) => handlePassengerChange(index, 'passportExpiry', e.target.value)}
                  min={new Date().toISOString().split('T')[0]}
                />
                {errors[`passenger_${index}_passportExpiry`] && (
                  <div className="invalid-feedback">{errors[`passenger_${index}_passportExpiry`]}</div>
                )}
              </div>

              {passportIssueDateReq && (
                <div className="col-md-4">
                  <label className="form-label">Passport Issue Date *</label>
                  <input
                    type="date"
                    className={`form-control ${errors[`passenger_${index}_passportIssueDate`] ? 'is-invalid' : ''}`}
                    value={passenger.passportIssueDate}
                    onChange={(e) => handlePassengerChange(index, 'passportIssueDate', e.target.value)}
                    max={new Date().toISOString().split('T')[0]}
                  />
                  {errors[`passenger_${index}_passportIssueDate`] && (
                    <div className="invalid-feedback">{errors[`passenger_${index}_passportIssueDate`]}</div>
                  )}
                </div>
              )}
            </>
          )}

          {docIdApplicable && (
            <div className="col-md-6">
              <label className="form-label">
                Document ID {docIdMandatory ? '*' : '(Student/Senior ID)'}
              </label>
              <input
                type="text"
                className={`form-control ${errors[`passenger_${index}_documentId`] ? 'is-invalid' : ''}`}
                value={passenger.documentId}
                onChange={(e) => handlePassengerChange(index, 'documentId', e.target.value)}
                placeholder="Student / Senior Citizen ID"
              />
              {errors[`passenger_${index}_documentId`] && (
                <div className="invalid-feedback">{errors[`passenger_${index}_documentId`]}</div>
              )}
            </div>
          )}

          {panRequired && (
            <div className="col-md-6">
              <label className="form-label">PAN Number *</label>
              <input
                type="text"
                className={`form-control ${errors[`passenger_${index}_pan`] ? 'is-invalid' : ''}`}
                value={passenger.pan}
                onChange={(e) => handlePassengerChange(index, 'pan', e.target.value.toUpperCase())}
                placeholder="ABCDE1234F"
                maxLength={10}
              />
              {errors[`passenger_${index}_pan`] && (
                <div className="invalid-feedback">{errors[`passenger_${index}_pan`]}</div>
              )}
            </div>
          )}
        </div>
      </div>
    );
  };

  return (
    <form onSubmit={handleSubmit}>
      <div className="row">
        <div className="col-lg-8">
          <div className="booking-card">
            <h4 className="booking-card-title">Passenger Details</h4>
            
            {passengers.map((passenger, index) => renderPassengerForm(passenger, index))}
            
            <div className="contact-details-card mt-4">
              <h5 className="section-title">
                <FaPhone className="me-2" />
                Contact Details
              </h5>
              
              <div className="row g-3">
                <div className="col-md-6">
                  <label className="form-label">Mobile Number *</label>
                  <div className="input-group">
                    <select
                      className="form-select"
                      style={{ maxWidth: '100px' }}
                      value={contact.countryCode}
                      onChange={(e) => setContact({ ...contact, countryCode: e.target.value })}
                    >
                      <option value="+91">+91</option>
                      <option value="+1">+1</option>
                      <option value="+44">+44</option>
                    </select>
                    <input
                      type="tel"
                      className={`form-control ${errors.mobile ? 'is-invalid' : ''}`}
                      value={contact.mobile}
                      onChange={(e) => setContact({ ...contact, mobile: e.target.value })}
                      placeholder="9876543210"
                    />
                    {errors.mobile && (
                      <div className="invalid-feedback">{errors.mobile}</div>
                    )}
                  </div>
                </div>
                
                <div className="col-md-6">
                  <label className="form-label">Email Address *</label>
                  <input
                    type="email"
                    className={`form-control ${errors.email ? 'is-invalid' : ''}`}
                    value={contact.email}
                    onChange={(e) => setContact({ ...contact, email: e.target.value })}
                    placeholder="email@example.com"
                  />
                  {errors.email && (
                    <div className="invalid-feedback">{errors.email}</div>
                  )}
                </div>
              </div>
            </div>

            {emergencyRequired && (
              <div className="contact-details-card mt-4">
                <h5 className="section-title">
                  <FaPhone className="me-2" />
                  Emergency Contact <small className="text-muted">(required by airline)</small>
                </h5>
                <div className="row g-3">
                  <div className="col-md-4">
                    <label className="form-label">Contact Name *</label>
                    <input
                      type="text"
                      className={`form-control ${errors.emergencyName ? 'is-invalid' : ''}`}
                      value={emergency.name}
                      onChange={(e) => setEmergency({ ...emergency, name: e.target.value })}
                      placeholder="Full name"
                    />
                    {errors.emergencyName && <div className="invalid-feedback">{errors.emergencyName}</div>}
                  </div>
                  <div className="col-md-4">
                    <label className="form-label">Email *</label>
                    <input
                      type="email"
                      className={`form-control ${errors.emergencyEmail ? 'is-invalid' : ''}`}
                      value={emergency.email}
                      onChange={(e) => setEmergency({ ...emergency, email: e.target.value })}
                      placeholder="email@example.com"
                    />
                    {errors.emergencyEmail && <div className="invalid-feedback">{errors.emergencyEmail}</div>}
                  </div>
                  <div className="col-md-4">
                    <label className="form-label">Mobile *</label>
                    <input
                      type="tel"
                      className={`form-control ${errors.emergencyMobile ? 'is-invalid' : ''}`}
                      value={emergency.mobile}
                      onChange={(e) => setEmergency({ ...emergency, mobile: e.target.value })}
                      placeholder="9876543210"
                    />
                    {errors.emergencyMobile && <div className="invalid-feedback">{errors.emergencyMobile}</div>}
                  </div>
                </div>
              </div>
            )}

            <div className="gst-section mt-4">
              <div className="form-check mb-3">
                <input
                  type="checkbox"
                  className="form-check-input"
                  id="gstCheck"
                  checked={gst.enabled}
                  onChange={(e) => setGst({ ...gst, enabled: e.target.checked })}
                />
                <label className="form-check-label" htmlFor="gstCheck">
                  I have a GST number (Optional)
                </label>
              </div>
              
              {gst.enabled && (
                <div className="gst-form-card">
                  <div className="row g-3">
                    <div className="col-md-6">
                      <label className="form-label">Company Name *</label>
                      <input
                        type="text"
                        className={`form-control ${errors.gstCompanyName ? 'is-invalid' : ''}`}
                        value={gst.companyName}
                        onChange={(e) => setGst({ ...gst, companyName: e.target.value })}
                      />
                      {errors.gstCompanyName && (
                        <div className="invalid-feedback">{errors.gstCompanyName}</div>
                      )}
                    </div>
                    
                    <div className="col-md-6">
                      <label className="form-label">GST Number *</label>
                      <input
                        type="text"
                        className={`form-control ${errors.gstNumber ? 'is-invalid' : ''}`}
                        value={gst.gstNumber}
                        onChange={(e) => setGst({ ...gst, gstNumber: e.target.value.toUpperCase() })}
                        placeholder="22AAAAA0000A1Z5"
                        maxLength={15}
                      />
                      {errors.gstNumber && (
                        <div className="invalid-feedback">{errors.gstNumber}</div>
                      )}
                    </div>
                    
                    <div className="col-12">
                      <label className="form-label">Company Email *</label>
                      <input
                        type="email"
                        className={`form-control ${errors.gstEmail ? 'is-invalid' : ''}`}
                        value={gst.companyEmail}
                        onChange={(e) => setGst({ ...gst, companyEmail: e.target.value })}
                      />
                      {errors.gstEmail && (
                        <div className="invalid-feedback">{errors.gstEmail}</div>
                      )}
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
        
        <div className="col-lg-4">
          <div className="booking-card sticky-summary">
            <h5 className="booking-card-title">Important Information</h5>
            
            <div className="info-list">
              <div className="info-item">
                <strong>Name Accuracy:</strong> Ensure passenger names match exactly as per government ID/passport.
              </div>
              <div className="info-item">
                <strong>Age Validation:</strong> Adult (12+), Child (2-12), Infant (0-2).
              </div>
              <div className="info-item">
                <strong>Contact Details:</strong> Booking confirmation will be sent to the provided email and mobile.
              </div>
              {passportMandatory && (
                <div className="info-item">
                  <strong>Passport:</strong> Must be valid for at least 6 months from travel date.
                </div>
              )}
            </div>
            
            <div className="d-flex gap-2 mt-4">
              <button type="button" className="btn btn-outline-secondary flex-grow-1" onClick={onBack}>
                Back
              </button>
              <button type="submit" className="btn btn-primary flex-grow-1">
                Continue
              </button>
            </div>
          </div>
        </div>
      </div>
    </form>
  );
}
