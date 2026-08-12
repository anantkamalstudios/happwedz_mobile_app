import { ClipLoader } from "react-spinners";

export const SLIDER_CATEGORIES = [
  "foundation",
  "concealer",
  "blush",
  "contour",
  "kajal",
  "eyeshadow",
  "lipstick",
  "bindi",
  "mascara",
  "eyeliner",
  // "mangtika",
  "contactlenses",
];

export const buttons = ["Shades", "Compare", "Complete Look"];

// Default intensity values for each category
export const DEFAULT_INTENSITIES = {
  foundation: 0.6,
  concealer: 0.9,
  blush: 0.2,
  contour: 0.3,
  kajal: 0.7,
  eyeshadow: 1.5,
  lipstick: 0.8,
  bindi: 6,
  mascara: 0.8,
  eyeliner: 0.5,
  // mangtika: 0.6,
  contactlenses: 0.2,
};

export const Loader = () => {
  return (
    <div
      className="filters-container my-5 d-flex align-items-center justify-content-center"
      style={{ minHeight: 400 }}
    >
      <ClipLoader size={60} color="#ed1173" />
    </div>
  );
};

// export const getErrorMessage = (err) => {
//   try {
//     let message = "Upload failed. Please try again.";
//     let status = err?.response?.status || null;

//     // Case 1: Backend JSON error message
//     if (err?.response?.data?.error) {
//       message = err.response.data.error;
//     }
//     // Case 2: Error message string contains JSON
//     else if (typeof err?.message === "string") {
//       const jsonMatch = err.message.match(/{.*}/);
//       if (jsonMatch) {
//         try {
//           const parsed = JSON.parse(jsonMatch[0]);
//           if (parsed.error) message = parsed.error;
//         } catch {
//           message = err.message;
//         }
//       } else {
//         message = err.message;
//       }
//     }
//     // Case 3: Direct string error
//     else if (typeof err === "string") {
//       message = err;
//     }

//     return { message, status };
//   } catch {
//     return { message: "Upload failed. Please try again.", status: null };
//   }
// };

export const getErrorMessage = (err) => {
  try {
    let message = "Upload failed. Please try again.";
    let status = err?.response?.status || null;

    // 1️⃣ If backend sent { error: "..." }
    if (err?.response?.data?.error) {
      message = err.response.data.error;
    }
    // 2️⃣ If backend sent plain string like "HTTP 400: { \"error\": \"file too large...\" }"
    else if (typeof err?.response?.data === "string") {
      // Try to find and parse JSON inside the string
      const jsonMatch = err.response.data.match(/{.*}/);
      if (jsonMatch) {
        try {
          const parsed = JSON.parse(jsonMatch[0]);
          if (parsed.error) message = parsed.error;
        } catch {
          message = err.response.data;
        }
      } else {
        message = err.response.data;
      }
    }
    // 3️⃣ If error.message exists and may contain JSON
    else if (typeof err?.message === "string") {
      const jsonMatch = err.message.match(/{.*}/);
      if (jsonMatch) {
        try {
          const parsed = JSON.parse(jsonMatch[0]);
          if (parsed.error) message = parsed.error;
        } catch {
          message = err.message;
        }
      } else {
        message = err.message;
      }
    }
    // 4️⃣ Direct string error
    else if (typeof err === "string") {
      message = err;
    }

    return { message, status };
  } catch {
    return { message: "Unexpected error occurred.", status: null };
  }
};
