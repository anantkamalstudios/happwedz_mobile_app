import { FaCheck, FaFileAlt, FaUser, FaClipboardCheck, FaCreditCard } from 'react-icons/fa';

export default function BookingSteps({ currentStep }) {
  const steps = [
    { 
      number: 1, 
      label: 'Flight Itinerary', 
      shortLabel: 'FIRST STEP',
      icon: FaFileAlt 
    },
    { 
      number: 2, 
      label: 'Passenger Details', 
      shortLabel: 'SECOND STEP',
      icon: FaUser 
    },
    { 
      number: 3, 
      label: 'Review', 
      shortLabel: 'THIRD STEP',
      icon: FaClipboardCheck 
    },
    { 
      number: 4, 
      label: 'Payments', 
      shortLabel: 'FOURTH STEP',
      icon: FaCreditCard 
    },
  ];

  return (
    <div className="tj-stepper-wrapper">
      <div className="tj-stepper-container">
        {steps.map((step, index) => {
          const isCompleted = currentStep > step.number;
          const isActive = currentStep === step.number;
          const StepIcon = step.icon;
          
          return (
            <div key={step.number} className="tj-step-wrapper">
              <div className={`tj-step-item ${isActive ? 'active' : ''} ${isCompleted ? 'completed' : ''}`}>
                <div className="tj-step-icon-circle">
                  {isCompleted ? (
                    <FaCheck size={16} />
                  ) : (
                    <StepIcon size={16} />
                  )}
                </div>
                <div className="tj-step-text">
                  <div className="tj-step-label">{step.shortLabel}</div>
                  <div className="tj-step-title">{step.label}</div>
                </div>
              </div>
              {index < steps.length - 1 && (
                <div className={`tj-step-line ${isCompleted ? 'completed' : ''}`} />
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
