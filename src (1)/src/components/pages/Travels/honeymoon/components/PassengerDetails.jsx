import { useState, useEffect } from 'react';
import { ChevronDown, ChevronUp } from 'lucide-react';

/** TripJack accepts Mr/Mrs/Ms for adults and Master/Miss for the young. */
const titleOptions = (paxType) =>
  paxType === 'ADULT' ? ['Mr', 'Mrs', 'Ms'] : ['Master', 'Miss'];

/** Dialling codes for the markets this route set actually serves. */
const COUNTRY_CODES = [
  { code: '+91', name: 'India' },
  { code: '+971', name: 'UAE' },
  { code: '+966', name: 'Saudi Arabia' },
  { code: '+974', name: 'Qatar' },
  { code: '+968', name: 'Oman' },
  { code: '+973', name: 'Bahrain' },
  { code: '+965', name: 'Kuwait' },
  { code: '+65', name: 'Singapore' },
  { code: '+66', name: 'Thailand' },
  { code: '+60', name: 'Malaysia' },
  { code: '+94', name: 'Sri Lanka' },
  { code: '+977', name: 'Nepal' },
  { code: '+880', name: 'Bangladesh' },
  { code: '+44', name: 'United Kingdom' },
  { code: '+1', name: 'USA / Canada' },
  { code: '+61', name: 'Australia' },
  { code: '+64', name: 'New Zealand' },
  { code: '+49', name: 'Germany' },
  { code: '+33', name: 'France' },
  { code: '+81', name: 'Japan' },
];
import { FaUser, FaPhone, FaEnvelope } from 'react-icons/fa';
import TripSummaryStrip from './TripSummaryStrip';
import FareSummary from './FareSummary';
import FlightAddOn, { addOnBreakdown } from './FlightAddOn';
import { FloatField, FloatSelect } from './FloatField';
import TravellerPicker from './TravellerPicker';
import { loadSuppressed, saveSuppressed, travellerKey } from './travellerStore';
import { getSavedTravellers } from '../../../../../services/api/flightApi';

export default function PassengerDetails({
  searchParams,
  reviewData,
  trip,
  returnTrip,
  fare,
  returnFare,
  markup = 0,
  onMarkupChange,
  bookingId,
  addOns,
  onAddOnsChange,
  onBack,
  onContinue,
  saved,
}) {
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
  // Emergency contact required (docs: conditions.iecr)
  const emergencyRequired = !!conditions?.iecr;
  // DOB requirements per pax type — TripJack states these per fare.
  const dobRequired = {
    ADULT: conditions?.dob?.adobr !== false,
    CHILD: conditions?.dob?.cdobr !== false,
    INFANT: conditions?.dob?.idobr !== false,
  };
  // anlm carries the airline's own name limits: max length and minimum length
  // per field, plus a combined cap. The portal's "0/50" counter is this value —
  // it is per fare, so it reads 0/32 on carriers that allow less.
  const nameLimits = {
    firstMax: Number(conditions?.anlm?.fN || 50),
    lastMax: Number(conditions?.anlm?.lN || 50),
    firstMin: Number(conditions?.anlm?.finml || 1),
    lastMin: Number(conditions?.anlm?.lnml || 1),
    combinedMax: Number(conditions?.anlm?.n || 0),
  };
  /**
   * Age is assessed on the travel date, not today — TripJack's own picker on a
   * 28 Aug 2026 departure allows 28 Aug 2014 as the last adult DOB and greys
   * out everything after it, which is departure minus twelve years to the day.
   * Anchoring on today would pass a child who turns twelve before the flight
   * and have them refused at check-in.
   */
  const departureDate = trip?.sI?.[0]?.dt || null;

  const shiftYears = (iso, years) => {
    const d = iso ? new Date(iso) : new Date();
    if (Number.isNaN(d.getTime())) return null;
    d.setFullYear(d.getFullYear() - years);
    return d;
  };
  const asISO = (d) => (d ? `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` : undefined);
  const dayAfter = (d) => {
    if (!d) return null;
    const x = new Date(d);
    x.setDate(x.getDate() + 1);
    return x;
  };

  /**
   * ADULT  12+ on the travel date        -> dob <= departure - 12y
   * CHILD  2 to under 12 on that date    -> departure - 12y < dob <= departure - 2y
   * INFANT under 2 on that date          -> dob > departure - 2y (and already born)
   */
  const dobBounds = (type) => {
    const twelve = shiftYears(departureDate, 12);
    const two = shiftYears(departureDate, 2);
    const today = asISO(new Date());
    if (type === 'CHILD') return { min: asISO(dayAfter(twelve)), max: asISO(two) };
    if (type === 'INFANT') return { min: asISO(dayAfter(two)), max: today };
    return { min: undefined, max: asISO(twelve) };
  };

  // Airlines on this itinerary that accept a frequent-flier number.
  const ffAirlines = Array.isArray(conditions?.ffas) ? conditions.ffas : [];

  // `saved` is the snapshot handed up on the last submit. Seeding from it is
  // what makes Back from Review return a filled form instead of a blank one.
  const [passengers, setPassengers] = useState(() =>
    saved?.passengers?.length === adults + children + infants
      ? saved.passengers
      : Array.from({ length: adults + children + infants }, (_, i) => ({
      title: i < adults ? 'Mr' : 'Master',
      firstName: '',
      lastName: '',
      dob: '',
      nationality: 'IN',
      passportNumber: '',
      passportExpiry: '',
      passportIssueDate: '',
      documentId: '',
      ffAirline: ffAirlines[0] || '',
      ffNumber: '',
      type: i < adults ? 'ADULT' : i < adults + children ? 'CHILD' : 'INFANT',
    })),
  );

  const [contact, setContact] = useState(
    saved?.contact || { countryCode: '+91', mobile: '', email: '' },
  );

  // Emergency contact (only collected when conditions.iecr is true)
  const [emergency, setEmergency] = useState(
    saved?.emergency || { name: '', email: '', mobile: '' },
  );
  
  const [gst, setGst] = useState(saved?.gst || {
    enabled: false,
    companyName: '',
    gstNumber: '',
    companyEmail: '',
    phone: '',
    address: '',
    save: true,
  });
  const [note, setNote] = useState(saved?.note || '');
  const [noteOpen, setNoteOpen] = useState(!!saved?.note);

  // TripJack has no endpoint for saved GST profiles — it is their own CRM — so
  // the history lives in this browser until we add a table for it.
  const GST_STORE = 'hw_gst_history';
  const [gstHistory, setGstHistory] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem(GST_STORE) || '[]');
    } catch {
      return [];
    }
  });

  const applyGstFromHistory = (gstNumber) => {
    const saved = gstHistory.find((g) => g.gstNumber === gstNumber);
    if (saved) setGst((p) => ({ ...p, ...saved, enabled: true }));
  };

  const persistGst = () => {
    if (!gst.enabled || !gst.save || !gst.gstNumber.trim()) return;
    const entry = {
      gstNumber: gst.gstNumber.trim().toUpperCase(),
      companyName: gst.companyName.trim(),
      companyEmail: gst.companyEmail.trim(),
      phone: gst.phone.trim(),
      address: gst.address.trim(),
    };
    const next = [entry, ...gstHistory.filter((g) => g.gstNumber !== entry.gstNumber)].slice(0, 8);
    setGstHistory(next);
    try {
      localStorage.setItem(GST_STORE, JSON.stringify(next));
    } catch {
      // Storage can be unavailable (private windows, blocked site data) —
      // the booking must not fail because a convenience feature could not save.
    }
  };
  
  // Travellers this account has booked for before, for the picker at the top
  // of each panel. A failed lookup yields [] and the picker hides itself.
  const [savedTravellers, setSavedTravellers] = useState([]);
  const [suppressed, setSuppressed] = useState(loadSuppressed);

  useEffect(() => {
    const controller = new AbortController();
    getSavedTravellers(controller.signal).then(setSavedTravellers);
    return () => controller.abort();
  }, []);

  const visibleTravellers = savedTravellers.filter((t) => !suppressed.has(t.key));

  /** Fill a panel from a previously booked traveller. */
  const applyTraveller = (index, t) => {
    setPassengers((prev) => {
      const next = [...prev];
      next[index] = {
        ...next[index],
        title: t.ti || next[index].title,
        firstName: t.fN || '',
        lastName: t.lN || '',
        dob: t.dob || '',
        nationality: t.pNat || next[index].nationality,
        passportNumber: t.pNum || '',
        passportExpiry: t.eD || '',
        passportIssueDate: t.pid || '',
      };
      return next;
    });
    setErrors((prev) => {
      const next = { ...prev };
      for (const f of ['firstName', 'lastName', 'dob', 'passportNumber', 'passportExpiry']) {
        delete next[`passenger_${index}_${f}`];
      }
      return next;
    });
  };

  /**
   * Kept per row rather than per name. Every panel starts blank, so a
   * name-based key is "||" for all of them and unticking one passenger would
   * untick every other. The real keys are written on submit, once the names
   * that identify these people actually exist.
   */
  const [saveTraveller, setSaveTraveller] = useState(saved?.saveTraveller || {});
  const toggleSaveTraveller = (index, keep) =>
    setSaveTraveller((prev) => ({ ...prev, [index]: keep }));

  const [errors, setErrors] = useState({});
  const [openPax, setOpenPax] = useState(saved?.openPax || { 0: true });
  const [openFf, setOpenFf] = useState({});
  const toggleFf = (i) => setOpenFf((p) => ({ ...p, [i]: p[i] === false }));
  const togglePax = (i) => setOpenPax((p) => ({ ...p, [i]: !p[i] }));

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

  /**
   * Checked against the same bounds the picker enforces, so a typed date cannot
   * pass where a picked one would be greyed out. Compares ISO strings rather
   * than dividing by 365.25 days, which drifted around birthdays.
   */
  const validateAge = (dob, type) => {
    if (!dob) return null;
    const { min, max } = dobBounds(type);
    const label = { ADULT: 'Adult', CHILD: 'Child', INFANT: 'Infant' }[type] || 'Passenger';
    if (max && dob > max) {
      if (type === 'ADULT') return `An adult must be 12 or older on the travel date (born on or before ${max})`;
      if (type === 'CHILD') return `A child must be at least 2 on the travel date (born on or before ${max})`;
      return `${label} date of birth cannot be in the future`;
    }
    if (min && dob < min) {
      if (type === 'CHILD') return `A child must be under 12 on the travel date (born after ${min})`;
      if (type === 'INFANT') return `An infant must be under 2 on the travel date (born after ${min})`;
    }
    return null;
  };

  const validateForm = () => {
    const newErrors = {};
    
    passengers.forEach((passenger, index) => {
      const first = passenger.firstName.trim();
      const last = passenger.lastName.trim();
      if (!first) {
        newErrors[`passenger_${index}_firstName`] = 'First name is required';
      } else if (first.length < nameLimits.firstMin) {
        newErrors[`passenger_${index}_firstName`] =
          `First name needs at least ${nameLimits.firstMin} character${nameLimits.firstMin > 1 ? 's' : ''}`;
      } else if (first.length > nameLimits.firstMax) {
        newErrors[`passenger_${index}_firstName`] =
          `This airline allows up to ${nameLimits.firstMax} characters`;
      }
      if (!last) {
        newErrors[`passenger_${index}_lastName`] = 'Last name is required';
      } else if (last.length < nameLimits.lastMin) {
        newErrors[`passenger_${index}_lastName`] =
          `Last name needs at least ${nameLimits.lastMin} character${nameLimits.lastMin > 1 ? 's' : ''}`;
      } else if (last.length > nameLimits.lastMax) {
        newErrors[`passenger_${index}_lastName`] =
          `This airline allows up to ${nameLimits.lastMax} characters`;
      }
      // Some carriers cap the full name too, not just each field.
      if (nameLimits.combinedMax && first && last &&
          `${first} ${last}`.length > nameLimits.combinedMax) {
        newErrors[`passenger_${index}_lastName`] =
          `Full name must be ${nameLimits.combinedMax} characters or fewer`;
      }

      const needsDob = dobRequired[passenger.type] !== false;
      if (needsDob && !passenger.dob) {
        newErrors[`passenger_${index}_dob`] = 'Date of birth is required';
      } else if (passenger.dob) {
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
      ...(p.ffNumber?.trim() && {
        fFNumber: p.ffNumber.trim(),
        fFAirline: p.ffAirline || undefined,
      }),
    }));

    // Emergency contact (contactInfo) — only when the fare requires it (iecr).
    const emergencyContact = emergencyRequired
      ? {
          name: emergency.name.trim(),
          email: emergency.email.trim(),
          mobile: `${contact.countryCode.replace(/^\+/, '')}${emergency.mobile.trim()}`,
        }
      : null;

    // Names are filled in by now, so each row's choice can be recorded
    // against the key the picker will actually look it up by.
    const nextSuppressed = new Set(suppressed);
    passengers.forEach((p, i) => {
      const key = travellerKey(p.firstName, p.lastName, p.dob);
      if (saveTraveller[i] === false) nextSuppressed.add(key);
      else nextSuppressed.delete(key);
    });
    setSuppressed(nextSuppressed);
    saveSuppressed(nextSuppressed);

    persistGst();
    onContinue(travellerInfo, contact, gst.enabled ? gst : null, emergencyContact, note.trim(), {
      passengers,
      contact,
      gst,
      note,
      emergency,
      saveTraveller,
      openPax,
    });
  };

  const renderPassengerForm = (passenger, index) => {
    const passengerLabel = passenger.type === 'ADULT' 
      ? `Adult ${index + 1}` 
      : passenger.type === 'CHILD' 
      ? `Child ${index - adults + 1}` 
      : `Infant ${index - adults - children + 1}`;
    
    const ageBand =
      passenger.type === 'ADULT' ? '(12 + yrs)'
        : passenger.type === 'CHILD' ? '(2 - 12 yrs)'
        : '(0 - 2 yrs)';
    const isOpen = openPax[index] !== false;

    return (
      <div key={index} className="passenger-form-card mb-3">
        <button
          type="button"
          className="passenger-form-title"
          onClick={() => togglePax(index)}
          aria-expanded={isOpen}
        >
          <span>
            <FaUser className="me-2" />
            {passengerLabel.toUpperCase()}: <small>{ageBand}</small>
          </span>
          {isOpen ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
        </button>

        {!isOpen ? null : (
        <>
        <TravellerPicker
          travellers={visibleTravellers}
          paxType={passenger.type}
          onPick={(t) => applyTraveller(index, t)}
        />

        <div className="paxlist-box">
          <div className="pax-col-title">
            <FloatSelect
              id={`pax${index}_ti`}
              label="Title"
              value={passenger.title}
              onChange={(e) => handlePassengerChange(index, 'title', e.target.value)}
              options={titleOptions(passenger.type)}
            />
          </div>

          <div className="pax-col-name">
            <FloatField
              id={`pax${index}_fN`}
              label="First Name"
              value={passenger.firstName}
              maxLength={nameLimits.firstMax}
              counter
              uppercase
              info="Enter the given name exactly as printed on the passenger's passport or photo ID."
              error={errors[`passenger_${index}_firstName`]}
              onChange={(e) => handlePassengerChange(index, 'firstName', e.target.value)}
            />
          </div>

          <div className="pax-col-name">
            <FloatField
              id={`pax${index}_lN`}
              label="Last Name"
              value={passenger.lastName}
              maxLength={nameLimits.lastMax}
              counter
              uppercase
              info="Enter the surname exactly as printed on the passenger's passport or photo ID."
              error={errors[`passenger_${index}_lastName`]}
              onChange={(e) => handlePassengerChange(index, 'lastName', e.target.value)}
            />
          </div>
          
          <div className="pax-col-dob">
            <FloatField
              id={`pax${index}_dob`}
              type="date"
              alwaysFloat
              label={`Date of Birth ${dobRequired[passenger.type] !== false ? '*' : '(optional)'}`}
              value={passenger.dob}
              min={dobBounds(passenger.type).min}
              max={dobBounds(passenger.type).max}
              error={errors[`passenger_${index}_dob`]}
              onChange={(e) => handlePassengerChange(index, 'dob', e.target.value)}
            />
          </div>
          
          {passportMandatory && (
            <>
              <div className="pax-col-half">
                <FloatField
                  id={`pax${index}_pNat`}
                  label="Nationality"
                  value={passenger.nationality}
                  maxLength={2}
                  uppercase
                  onChange={(e) => handlePassengerChange(index, 'nationality', e.target.value.toUpperCase())}
                />
              </div>

              <div className="pax-col-half">
                <FloatField
                  id={`pax${index}_pNum`}
                  label="Passport Number"
                  value={passenger.passportNumber}
                  uppercase
                  error={errors[`passenger_${index}_passportNumber`]}
                  onChange={(e) => handlePassengerChange(index, 'passportNumber', e.target.value.toUpperCase())}
                />
              </div>

              <div className="pax-col-half">
                <FloatField
                  id={`pax${index}_eD`}
                  type="date"
                  alwaysFloat
                  label="Passport Expiry"
                  value={passenger.passportExpiry}
                  error={errors[`passenger_${index}_passportExpiry`]}
                  onChange={(e) => handlePassengerChange(index, 'passportExpiry', e.target.value)}
                />
              </div>

              {passportIssueDateReq && (
                <div className="pax-col-half">
                  <FloatField
                    id={`pax${index}_pid`}
                    type="date"
                    alwaysFloat
                    label="Passport Issue Date"
                    value={passenger.passportIssueDate}
                    error={errors[`passenger_${index}_passportIssueDate`]}
                    onChange={(e) => handlePassengerChange(index, 'passportIssueDate', e.target.value)}
                  />
                </div>
              )}
            </>
          )}

          {docIdApplicable && (
            <div className="pax-col-half">
              <FloatField
                id={`pax${index}_di`}
                label={docIdMandatory ? 'Document ID' : 'Document ID (Student/Senior)'}
                value={passenger.documentId}
                uppercase
                error={errors[`passenger_${index}_documentId`]}
                onChange={(e) => handlePassengerChange(index, 'documentId', e.target.value.toUpperCase())}
              />
            </div>
          )}
        </div>

        {/* Only offered for carriers this fare says accept a FF number. */}
        {ffAirlines.length > 0 && passenger.type !== 'INFANT' && (
          <div className="ff-block">
            <button
              type="button"
              className="ff-title"
              onClick={() => toggleFf(index)}
              aria-expanded={openFf[index] !== false}
            >
              FREQUENT FLIER NUMBER <small>(OPTIONAL)</small>
              <i className={`ff-caret${openFf[index] === false ? '' : ' is-open'}`} aria-hidden="true" />
            </button>
            {openFf[index] === false ? null : (
            <div className="paxlist-box">
              <div className="pax-col-ff">
                <FloatSelect
                  id={`pax${index}_ffAirline`}
                  label="Airline"
                  value={passenger.ffAirline}
                  onChange={(e) => handlePassengerChange(index, 'ffAirline', e.target.value)}
                  options={ffAirlines}
                />
              </div>
              <div className="pax-col-ff">
                <FloatField
                  id={`pax${index}_ffNumber`}
                  label="FF Number"
                  value={passenger.ffNumber}
                  uppercase
                  onChange={(e) => handlePassengerChange(index, 'ffNumber', e.target.value.toUpperCase())}
                />
              </div>
            </div>
            )}
          </div>
        )}

        <div className="saveDetails_wrapper">
          <label className="tj-checkbox-label">
            <input
              type="checkbox"
              checked={saveTraveller[index] !== false}
              onChange={(e) => toggleSaveTraveller(index, e.target.checked)}
            />
            <span className="save-pax__label">
              Add this to My Travellers List
              <span className="save-pax__sub-label">
                (Saves retyping their details on your next booking)
              </span>
            </span>
          </label>
        </div>
        </>
        )}
      </div>
    );
  };

  return (
    <form onSubmit={handleSubmit}>
      <div className="row">
        <div className="col-lg-8">
          <div className="booking-card">
            <h4 className="booking-card-title">Passenger Details</h4>

            <TripSummaryStrip
              trip={trip}
              fare={fare}
              returnTrip={returnTrip}
              tripType={searchParams?.tripType}
            />
            
            {passengers.map((passenger, index) => renderPassengerForm(passenger, index))}
            
            <div className="contact-details-card mt-4">
              <h5 className="section-title">
                <FaPhone className="me-2" />
                Contact Details
              </h5>
              
              <div className="paxlist-box">
                <div className="pax-col-title">
                  <FloatSelect
                    id="contact_cc"
                    label="Code"
                    value={contact.countryCode}
                    onChange={(e) => setContact({ ...contact, countryCode: e.target.value })}
                    options={COUNTRY_CODES.map((c) => ({ value: c.code, label: `${c.code} ${c.name}` }))}
                  />
                </div>
                <div className="pax-col-half">
                  <FloatField
                    id="contact_mobile"
                    type="tel"
                    label="Mobile Number *"
                    value={contact.mobile}
                    error={errors.mobile}
                    onChange={(e) => setContact({ ...contact, mobile: e.target.value })}
                  />
                </div>
                <div className="pax-col-half">
                  <FloatField
                    id="contact_email"
                    type="email"
                    label="Email ID *"
                    value={contact.email}
                    error={errors.email}
                    onChange={(e) => setContact({ ...contact, email: e.target.value })}
                  />
                </div>
              </div>
            </div>

            {emergencyRequired && (
              <div className="contact-details-card mt-4">
                <h5 className="section-title">
                  <FaPhone className="me-2" />
                  Emergency Contact <small className="text-muted">(required by airline)</small>
                </h5>
                <div className="paxlist-box">
                  <div className="pax-col-half">
                    <FloatField
                      id="em_name"
                      label="Contact Name *"
                      value={emergency.name}
                      error={errors.emergencyName}
                      onChange={(e) => setEmergency({ ...emergency, name: e.target.value })}
                    />
                  </div>
                  <div className="pax-col-half">
                    <FloatField
                      id="em_email"
                      type="email"
                      label="Email *"
                      value={emergency.email}
                      error={errors.emergencyEmail}
                      onChange={(e) => setEmergency({ ...emergency, email: e.target.value })}
                    />
                  </div>
                  <div className="pax-col-half">
                    <FloatField
                      id="em_mobile"
                      type="tel"
                      label="Mobile *"
                      value={emergency.mobile}
                      error={errors.emergencyMobile}
                      onChange={(e) => setEmergency({ ...emergency, mobile: e.target.value })}
                    />
                  </div>
                </div>
              </div>
            )}

            <div className="addon-toggles mt-4">
              <button
                type="button"
                className={`addon-toggle-btn ${noteOpen ? 'is-open' : ''}`}
                onClick={() => setNoteOpen((v) => !v)}
              >
                {noteOpen ? '−' : '+'} Add notes (Optional)
              </button>
              <button
                type="button"
                className={`addon-toggle-btn ${gst.enabled ? 'is-open' : ''}`}
                onClick={() => setGst((p) => ({ ...p, enabled: !p.enabled }))}
              >
                {gst.enabled ? '−' : '+'} Add GST Details (Optional)
              </button>
            </div>

            {noteOpen && (
              <div className="addon-panel">
                <div className="addon-panel-head">Agent Note (Optional)</div>
                <div className="addon-panel-body">
                  <FloatField
                    id="agent_note"
                    label="Add Notes"
                    value={note}
                    maxLength={200}
                    counter
                    onChange={(e) => setNote(e.target.value)}
                  />
                  <p className="addon-panel-hint">
                    *These notes are for agent reference only, no action will be taken against this.
                  </p>
                </div>
              </div>
            )}

            {gst.enabled && (
              <div className="addon-panel">
                <div className="addon-panel-head">GST Number for Business Travel (Optional)</div>
                <div className="addon-panel-body">
                  {gstHistory.length > 0 && (
                    <div className="gst-history">
                      <select
                        className="form-select"
                        value=""
                        onChange={(e) => applyGstFromHistory(e.target.value)}
                      >
                        <option value="">Select from History</option>
                        {gstHistory.map((g) => (
                          <option key={g.gstNumber} value={g.gstNumber}>
                            {g.gstNumber} — {g.companyName}
                          </option>
                        ))}
                      </select>
                      <button
                        type="button"
                        className="gst-clear"
                        onClick={() =>
                          setGst((p) => ({
                            ...p,
                            companyName: '',
                            gstNumber: '',
                            companyEmail: '',
                            phone: '',
                            address: '',
                          }))
                        }
                      >
                        Clear
                      </button>
                    </div>
                  )}

                  <p className="addon-panel-hint mb-3">
                    To claim credit of GST charged by airlines, please enter your company&apos;s GST number.
                  </p>

                  <div className="paxlist-box">
                    <div className="pax-col-half">
                      <FloatField
                        id="gst_number"
                        label="Registration Number *"
                        value={gst.gstNumber}
                        maxLength={15}
                        uppercase
                        error={errors.gstNumber}
                        onChange={(e) => setGst({ ...gst, gstNumber: e.target.value.toUpperCase() })}
                      />
                    </div>
                    <div className="pax-col-half">
                      <FloatField
                        id="gst_company"
                        label="Registered Company Name *"
                        value={gst.companyName}
                        error={errors.gstCompanyName}
                        onChange={(e) => setGst({ ...gst, companyName: e.target.value })}
                      />
                    </div>
                    <div className="pax-col-half">
                      <FloatField
                        id="gst_email"
                        type="email"
                        label="Registered Email *"
                        value={gst.companyEmail}
                        error={errors.gstEmail}
                        onChange={(e) => setGst({ ...gst, companyEmail: e.target.value })}
                      />
                    </div>
                    <div className="pax-col-half">
                      <FloatField
                        id="gst_phone"
                        type="tel"
                        label="Registered Phone"
                        value={gst.phone}
                        onChange={(e) => setGst({ ...gst, phone: e.target.value })}
                      />
                    </div>
                    <div className="pax-col-full">
                      <FloatField
                        id="gst_address"
                        label="Registered Address"
                        value={gst.address}
                        onChange={(e) => setGst({ ...gst, address: e.target.value })}
                      />
                    </div>
                  </div>

                  <label className="tj-checkbox-label mt-3">
                    <input
                      type="checkbox"
                      checked={gst.save}
                      onChange={(e) => setGst({ ...gst, save: e.target.checked })}
                    />
                    <span>Save GST Details</span>
                  </label>
                </div>
              </div>
            )}
          </div>

          <FlightAddOn
            reviewData={reviewData}
            bookingId={bookingId}
            passengers={passengers}
            value={addOns}
            onChange={onAddOnsChange}
          />

          <div className="itinerary-actions">
            <button type="button" className="itin-btn itin-btn-back" onClick={onBack}>
              « Back
            </button>
            <button type="submit" className="itin-btn itin-btn-next">
              PROCEED TO REVIEW »
            </button>
          </div>
        </div>
        
        <div className="col-lg-4">
          <FareSummary
            fare={fare}
            returnFare={returnFare}
            searchParams={searchParams}
            markup={markup}
            onMarkupChange={onMarkupChange}
            extras={Object.entries(addOnBreakdown(addOns)).map(([label, amount]) => ({
              label,
              amount,
            }))}
          >
          </FareSummary>
        </div>
      </div>
    </form>
  );
}
