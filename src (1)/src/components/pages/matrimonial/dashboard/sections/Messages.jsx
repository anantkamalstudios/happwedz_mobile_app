import React from "react";

const Messages = () => {
  const threads = [
    {
      id: 1,
      name: "Priya Sharma",
      last: "Hi! I'd like to connect.",
      time: "1m",
    },
    {
      id: 2,
      name: "Ravi Kumar",
      last: "Let's talk this weekend.",
      time: "10m",
    },
    {
      id: 3,
      name: "Anjali Patel",
      last: "Thanks for your interest!",
      time: "2h",
    },
  ];

  return (
    <div className="matrimonial-dashboard__section">
      <div className="matrimonial-dashboard__content-header">
        <h1 className="matrimonial-dashboard__page-title">Messages</h1>
      </div>

      <div className="matrimonial-dashboard__messages">
        {/* {threads.map((t) => (
          <div key={t.id} className="matrimonial-dashboard__message-item">
            <div className="matrimonial-dashboard__message-avatar">
              {t.name.charAt(0)}
            </div>
            <div className="matrimonial-dashboard__message-body">
              <div className="matrimonial-dashboard__message-top">
                <span className="matrimonial-dashboard__message-name">
                  {t.name}
                </span>
                <span className="matrimonial-dashboard__message-time">
                  {t.time}
                </span>
              </div>
              <div className="matrimonial-dashboard__message-preview">
                {t.last}
              </div>
            </div>
          </div>
        ))} */}

        <div className="text-center my-5">
          <div className="d-flex justify-content-center mb-4">
            <svg
              width="80"
              height="80"
              fill="none"
              viewBox="0 0 80 80"
              xmlns="http://www.w3.org/2000/svg"
            >
              <circle
                cx="40"
                cy="40"
                r="38"
                fill="#f8d7da"
                stroke="#f5c2c7"
                strokeWidth="4"
              />
              <path
                d="M40 24v20"
                stroke="#dc3545"
                strokeWidth="4"
                strokeLinecap="round"
              />
              <circle cx="40" cy="54" r="2.5" fill="#dc3545" />
            </svg>
          </div>
          <h3 className="mb-2 text-danger">Service Unavailable</h3>
          <p className="text-muted mb-3">
            Sorry, the messaging service is temporarily unavailable.
            <br />
            Please try again later.
          </p>
        </div>
      </div>
    </div>
  );
};

export default Messages;
