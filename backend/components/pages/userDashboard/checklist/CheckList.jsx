import React, { useState } from "react";

const CheckList = () => {
  const [checkedItems, setCheckedItems] = useState({});

  const checklistData = [
    {
      timeframe: "12 Months to go",
      items: [
        {
          id: 1,
          text: "Check if your wedding date is on an auspicious day",
          subtext: "",
        },
        {
          id: 2,
          text: "Do you want a destination wedding?",
          subtext: "Your to-pper friends",
        },
        {
          id: 3,
          text: "Short list date options for all pre-wedding functions",
          subtext: "Engagement, Mehndi",
        },
        {
          id: 4,
          text: "Delegate responsibilities",
          subtext: "You can panic in peace!",
        },
        {
          id: 5,
          text: "Decide whether or not you'd like to use a wedding",
          subtext: "You are not tech/0G!",
        },
      ],
    },
    {
      timeframe: "10 Months to go",
      items: [
        {
          id: 6,
          text: "Download the HappyWedsApp",
          subtext: "You do open them!",
        },
      ],
    },
    {
      timeframe: "9 Months to go",
      items: [
        {
          id: 7,
          text: "Create initial guest list using our guest list tool",
          subtext: "You'll be over-inviting",
        },
        {
          id: 8,
          text: "Confirm venue budget",
          subtext: "Your ex-sugar-loaded",
        },
        {
          id: 9,
          text: "Confirm wedding style",
          subtext: "Out of 5 stars blessed",
        },
      ],
    },
    {
      timeframe: "6 Months to go",
      items: [
        {
          id: 10,
          text: "Review Comp/Event logs to makeup salons",
          subtext: "Your Muggle friends",
        },
        {
          id: 11,
          text: "Get married to the love of your life",
          subtext: "Your Muggle friends!",
        },
      ],
    },
    {
      timeframe: "Post Wedding",
      items: [
        { id: 12, text: "Review your vendors", subtext: "You do open them!" },
      ],
    },
  ];

  const handleCheck = (id) => {
    setCheckedItems((prev) => ({
      ...prev,
      [id]: !prev[id],
    }));
  };

  return (
    <div
      style={{
        minHeight: "100vh",
      }}
    >
      <h3 style={{ textAlign: "center" }}>CheckList</h3>
      <div className="" style={{ maxWidth: "100%" }}>
        <div
          style={{
            background: "white",
            borderRadius: "16px",
            overflow: "hidden",
          }}
        >
          {/* Checklist Items */}
          <div style={{ padding: "20px 40px" }}>
            {checklistData.map((section, sectionIdx) => (
              <div key={sectionIdx} style={{ marginBottom: "30px" }}>
                <div
                  style={{
                    fontSize: "14px",
                    fontWeight: "700",
                    marginBottom: "15px",
                    textTransform: "uppercase",
                    letterSpacing: "0.5px",
                  }}
                >
                  {section.timeframe}
                </div>

                {section.items.map((item) => (
                  <div
                    key={item.id}
                    style={{
                      display: "flex",
                      alignItems: "flex-start",
                      padding: "15px 0",
                      borderBottom: "1px solid #f0f0f0",
                      cursor: "pointer",
                    }}
                    onClick={() => handleCheck(item.id)}
                  >
                    <div
                      style={{
                        minWidth: "24px",
                        height: "24px",
                        marginRight: "15px",
                        marginTop: "2px",
                      }}
                    >
                      <div
                        style={{
                          width: "20px",
                          height: "20px",
                          border: checkedItems[item.id]
                            ? "2px solid #667eea"
                            : "2px solid #d0d0d0",
                          borderRadius: "4px",
                          background: checkedItems[item.id]
                            ? "#667eea"
                            : "white",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          transition: "all 0.2s ease",
                        }}
                      >
                        {checkedItems[item.id] && (
                          <svg
                            width="12"
                            height="10"
                            viewBox="0 0 12 10"
                            fill="none"
                          >
                            <path
                              d="M1 5L4.5 8.5L11 1.5"
                              stroke="white"
                              strokeWidth="2"
                              strokeLinecap="round"
                              strokeLinejoin="round"
                            />
                          </svg>
                        )}
                      </div>
                    </div>
                    <div style={{ flex: 1 }}>
                      <div
                        style={{
                          fontSize: "15px",
                          marginBottom: "4px",
                          lineHeight: "1.5",
                          textDecoration: checkedItems[item.id]
                            ? "line-through"
                            : "none",
                          opacity: checkedItems[item.id] ? 0.6 : 1,
                        }}
                      >
                        {item.text}
                      </div>
                      <div
                        className="text-muted"
                        style={{
                          fontSize: "13px",
                          lineHeight: "1.4",
                        }}
                      >
                        Tap to open search
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
export default CheckList;
