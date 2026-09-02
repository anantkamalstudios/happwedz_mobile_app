import { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { bookFlight, getBookingDetails } from '../../../../services/api/flightApi';
import './tripjack-styles.css';

export default function FlightBooking() {
  const location = useLocation();
  const navigate = useNavigate();
  
  const { outbound, return: returnFlight, searchParams, reviewData, bookingId } = location.state || {};
  
  const [loading, setLoading] = useState(false);
  const [travellers, setTravellers] = useState([]);
  const [contactEmail, setContactEmail] = useState('');
  const [contactPhone, setContactPhone] = useState('');
  const [gstInfo, setGstInfo] = useState({
    enabled: false,
    gstNumber: '',
    email: '',
    registeredName: '',
    mobile: '',
    address: '',
  });

  useEffect(() => {
    if (!outbound || !bookingId) {
      alert('Invalid booking session. Please search for flights again.');
      navigate('/honeymoon');
      return;
    }

    // Initialize travellers based on search params
    const adults = searchParams?.adults || 1;
    const children = searchParams?.children || 0;
    
    const initialTravellers = [];
    
    for (let i = 0; i < adults; i++) {
      initialTravellers.push({
        ti: 'Mr',
        fN: '',
        lN: '',
        pt: 'ADULT',
        dob: '',
        pNat: 'IN',
        pNum: '',
        eD: '',
      });
    }
    
    for (let i = 0; i < children; i++) {
      initialTravellers.push({
        ti: 'Master',
        fN: '',
        lN: '',
        pt: 'CHILD',
        dob: '',
        pNat: 'IN',
        pNum: '',
        eD: '',
      });
    }
    
    setTravellers(initialTravellers);
  }, [outbound, bookingId, searchParams, navigate]);

  const handleTravellerChange = (index, field, value) => {
    setTravellers(prev => {
      const updated = [...prev];
      updated[index] = { ...updated[index], [field]: value };
      return updated;
    });
  };

  const handleSubmitBooking = async (e) => {
    e.preventDefault();
    
    // Validate travellers
    for (let i = 0; i < travellers.length; i++) {
      const t = travellers[i];
      if (!t.fN || !t.lN || !t.dob) {
        alert(`Please fill all required fields for traveller ${i + 1}`);
        return;
      }
    }
    
    if (!contactEmail || !contactPhone) {
      alert('Please provide contact email and phone');
      return;
    }

    setLoading(true);
    
    try {
      const totalPrice = (outbound?.totalPriceList[0]?.fd?.ADULT?.fC?.TF || 0) + 
                         (returnFlight?.totalPriceList[0]?.fd?.ADULT?.fC?.TF || 0);
      
      const bookingPayload = {
        bookingId,
        paymentInfos: [{ amount: totalPrice }],
        travellerInfo: travellers,
        deliveryInfo: {
          emails: [contactEmail],
          contacts: [contactPhone],
        },
      };
      
      // Add GST info if enabled
      if (gstInfo.enabled && gstInfo.gstNumber) {
        bookingPayload.gstInfo = {
          gstNumber: gstInfo.gstNumber,
          email: gstInfo.email,
          registeredName: gstInfo.registeredName,
          mobile: gstInfo.mobile,
          address: gstInfo.address,
        };
      }
      
      const bookingResponse = await bookFlight(bookingPayload);
      
      if (bookingResponse?.status?.success) {
        alert('Booking successful! Booking ID: ' + bookingResponse.bookingId);
        
        // Navigate to booking confirmation page
        navigate('/honeymoon/flights/confirmation', {
          state: {
            bookingData: bookingResponse,
            outbound,
            return: returnFlight,
          },
        });
      } else {
        alert(bookingResponse?.status?.message || 'Booking failed. Please try again.');
      }
    } catch (error) {
      console.error('Booking error:', error);
      alert(error.response?.data?.message || 'Booking failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const formatPrice = (price) => {
    return `₹${Number(price).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
  };

  const totalPrice = (outbound?.totalPriceList[0]?.fd?.ADULT?.fC?.TF || 0) + 
                     (returnFlight?.totalPriceList[0]?.fd?.ADULT?.fC?.TF || 0);

  return (
    <div className="tj-booking-page">
      <div className="container mt-4">
        <div className="row">
          <div className="col-lg-8">
            <div className="tj-booking-card">
              <h3 className="tj-booking-title">Traveller Details</h3>
              
              <form onSubmit={handleSubmitBooking}>
                {travellers.map((traveller, index) => (
                  <div key={index} className="tj-traveller-form">
                    <h5>Traveller {index + 1} ({traveller.pt})</h5>
                    
                    <div className="row">
                      <div className="col-md-2">
                        <label>Title</label>
                        <select
                          className="form-control"
                          value={traveller.ti}
                          onChange={(e) => handleTravellerChange(index, 'ti', e.target.value)}
                          required
                        >
                          <option value="Mr">Mr</option>
                          <option value="Ms">Ms</option>
                          <option value="Mrs">Mrs</option>
                          <option value="Master">Master</option>
                          <option value="Miss">Miss</option>
                        </select>
                      </div>
                      
                      <div className="col-md-5">
                        <label>First Name *</label>
                        <input
                          type="text"
                          className="form-control"
                          value={traveller.fN}
                          onChange={(e) => handleTravellerChange(index, 'fN', e.target.value)}
                          required
                        />
                      </div>
                      
                      <div className="col-md-5">
                        <label>Last Name *</label>
                        <input
                          type="text"
                          className="form-control"
                          value={traveller.lN}
                          onChange={(e) => handleTravellerChange(index, 'lN', e.target.value)}
                          required
                        />
                      </div>
                    </div>
                    
                    <div className="row mt-3">
                      <div className="col-md-4">
                        <label>Date of Birth *</label>
                        <input
                          type="date"
                          className="form-control"
                          value={traveller.dob}
                          onChange={(e) => handleTravellerChange(index, 'dob', e.target.value)}
                          required
                        />
                      </div>
                      
                      <div className="col-md-4">
                        <label>Passport Number</label>
                        <input
                          type="text"
                          className="form-control"
                          value={traveller.pNum}
                          onChange={(e) => handleTravellerChange(index, 'pNum', e.target.value)}
                        />
                      </div>
                      
                      <div className="col-md-4">
                        <label>Passport Expiry</label>
                        <input
                          type="date"
                          className="form-control"
                          value={traveller.eD}
                          onChange={(e) => handleTravellerChange(index, 'eD', e.target.value)}
                        />
                      </div>
                    </div>
                  </div>
                ))}
                
                <div className="tj-contact-form mt-4">
                  <h5>Contact Information</h5>
                  
                  <div className="row">
                    <div className="col-md-6">
                      <label>Email *</label>
                      <input
                        type="email"
                        className="form-control"
                        value={contactEmail}
                        onChange={(e) => setContactEmail(e.target.value)}
                        required
                      />
                    </div>
                    
                    <div className="col-md-6">
                      <label>Phone *</label>
                      <input
                        type="tel"
                        className="form-control"
                        value={contactPhone}
                        onChange={(e) => setContactPhone(e.target.value)}
                        required
                      />
                    </div>
                  </div>
                </div>
                
                <div className="tj-gst-form mt-4">
                  <div className="form-check">
                    <input
                      type="checkbox"
                      className="form-check-input"
                      id="gstEnabled"
                      checked={gstInfo.enabled}
                      onChange={(e) => setGstInfo(prev => ({ ...prev, enabled: e.target.checked }))}
                    />
                    <label className="form-check-label" htmlFor="gstEnabled">
                      I have a GST number (Optional)
                    </label>
                  </div>
                  
                  {gstInfo.enabled && (
                    <div className="row mt-3">
                      <div className="col-md-6">
                        <label>GST Number</label>
                        <input
                          type="text"
                          className="form-control"
                          value={gstInfo.gstNumber}
                          onChange={(e) => setGstInfo(prev => ({ ...prev, gstNumber: e.target.value }))}
                        />
                      </div>
                      
                      <div className="col-md-6">
                        <label>Registered Name</label>
                        <input
                          type="text"
                          className="form-control"
                          value={gstInfo.registeredName}
                          onChange={(e) => setGstInfo(prev => ({ ...prev, registeredName: e.target.value }))}
                        />
                      </div>
                      
                      <div className="col-md-12 mt-2">
                        <label>Address</label>
                        <input
                          type="text"
                          className="form-control"
                          value={gstInfo.address}
                          onChange={(e) => setGstInfo(prev => ({ ...prev, address: e.target.value }))}
                        />
                      </div>
                    </div>
                  )}
                </div>
                
                <button 
                  type="submit" 
                  className="tj-book-btn mt-4 w-100"
                  disabled={loading}
                >
                  {loading ? 'Processing...' : `Pay ${formatPrice(totalPrice)}`}
                </button>
              </form>
            </div>
          </div>
          
          <div className="col-lg-4">
            <div className="tj-booking-summary">
              <h4>Booking Summary</h4>
              
              {outbound && (
                <div className="tj-summary-flight">
                  <h6>Outbound Flight</h6>
                  <div>{outbound.sI[0].fD.aI.name} {outbound.sI[0].fD.fN}</div>
                  <div>{outbound.sI[0].da.code} → {outbound.sI[outbound.sI.length - 1].aa.code}</div>
                  <div className="tj-summary-price">
                    {formatPrice(outbound.totalPriceList[0]?.fd?.ADULT?.fC?.TF)}
                  </div>
                </div>
              )}
              
              {returnFlight && (
                <div className="tj-summary-flight mt-3">
                  <h6>Return Flight</h6>
                  <div>{returnFlight.sI[0].fD.aI.name} {returnFlight.sI[0].fD.fN}</div>
                  <div>{returnFlight.sI[0].da.code} → {returnFlight.sI[returnFlight.sI.length - 1].aa.code}</div>
                  <div className="tj-summary-price">
                    {formatPrice(returnFlight.totalPriceList[0]?.fd?.ADULT?.fC?.TF)}
                  </div>
                </div>
              )}
              
              <div className="tj-summary-total mt-4">
                <strong>Total Amount:</strong>
                <strong>{formatPrice(totalPrice)}</strong>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
