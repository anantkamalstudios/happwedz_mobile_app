import React, { useEffect } from "react";

// Referenced by URL rather than imported. Importing out of /public made Vite
// bundle a second copy into /assets, so the 9.3KB PNG shipped twice and landed
// on the critical path via the entry chunk. The WebP is 3.4KB.
const logo = "/logo-no-bg.png";

const Loader = () => {
  useEffect(() => {
    // Save current overflow style to restore later
    const originalOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    return () => {
      document.body.style.overflow = originalOverflow || "";
    };
  }, []);

  return (
    <div
      className="position-fixed top-0 start-0 w-100 h-100 bg-white d-flex justify-content-center align-items-center"
      style={{ zIndex: 2000, overflow: "hidden" }}
    >
      <img
        src={logo}
        alt="Loading..."
        style={{
          width: "100px",
          height: "100px",
          animation: "flipScale 2s ease-in-out infinite",
        }}
      />
      <style>
        {`
          body {
            overscroll-behavior: none !important;
          }
          @keyframes flipScale {
            0% { 
              transform: scale(1) rotateY(0deg);
            }
            50% { 
              transform: scale(1.5) rotateY(180deg);
            }
            100% { 
              transform: scale(1) rotateY(360deg);
            }
          }
        `}
      </style>
    </div>
  );
};

export default Loader;
