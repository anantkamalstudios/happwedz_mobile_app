// import React, { Component } from 'react';
// import CountDown from 'reactjs-countdown';
// import './style.css'

// class Saveday extends Component {

//     render() {
//         const { weddingDate, saveday } = this.props;
//         let safeDeadline = null;
//         if (weddingDate) {
//             const d = new Date(weddingDate);
//             if (!isNaN(d.getTime())) {
//                 safeDeadline = d.toISOString();
//             }
//         }

//         return(
//             <div className={`saveday ${saveday}`}>
//                 <div className="container">
//                     <div className="row">
//                         <div className="col-12">
//                             <div className="countdownwrap">
//                                 {safeDeadline && (
//                                     <CountDown deadline={safeDeadline} />
//                                 )}
//                             </div>
//                         </div>
//                     </div>
//                 </div>
//             </div>

//         );
//     }
// }

// export default Saveday;

// import React, { Component } from "react";
// import CountDown from "reactjs-countdown";
// import "./style.css";

// class Saveday extends Component {
//   render() {
//     const { weddingDate, saveday } = this.props;

//     let safeDeadline = null;

//     if (weddingDate) {
//       // ✅ Add full time to ensure correct countdown (end of the given day)
//       const fullDateString = `${weddingDate} 23:59:59`;
//       const d = new Date(fullDateString);

//       if (!isNaN(d.getTime())) {
//         // Format for reactjs-countdown
//         safeDeadline = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(
//           2,
//           "0"
//         )}-${String(d.getDate()).padStart(2, "0")} ${String(
//           d.getHours()
//         ).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}:${String(
//           d.getSeconds()
//         ).padStart(2, "0")}`;
//       }
//     }

//     return (
//       <div className={`saveday ${saveday}`}>
//         <div className="container">
//           <div className="row">
//             <div className="col-12">
//               <div className="countdownwrap">
//                 {safeDeadline ? (
//                   <CountDown deadline={safeDeadline} showDays={true} />
//                 ) : (
//                   <p>No wedding date set</p>
//                 )}
//               </div>
//             </div>
//           </div>
//         </div>
//       </div>
//     );
//   }
// }

// export default Saveday;

// import React, { Component } from "react";
// import Countdown from "react-countdown";
// import "./style.css";

// class Saveday extends Component {
//   renderer = ({ days, hours, minutes, seconds, completed }) => {
//     if (completed) {
//       return <span>It's the wedding day! 🎉</span>;
//     } else {
//       return (
//         <span>
//           {days}d {hours}h {minutes}m {seconds}s
//         </span>
//       );
//     }
//   };

//   render() {
//     const { weddingDate, saveday } = this.props;

//     // Handle missing or invalid date
//     if (!weddingDate) {
//       return <p>No wedding date set</p>;
//     }
//     const targetDate = new Date(`${weddingDate}T23:59:59`);

//     return (
//       <div className={`saveday ${saveday}`}>
//         <div className="container">
//           <div className="row">
//             <div className="col-12">
//               <div className="countdownwrap">
//                 <Countdown date={targetDate} renderer={this.renderer} />
//               </div>
//             </div>
//           </div>
//         </div>
//       </div>
//     );
//   }
// }

// export default Saveday;

import React, { Component } from "react";
import Countdown from "react-countdown";
import Sectiontitle from "../section-title";

class Saveday extends Component {
  // custom renderer
  renderer = ({ days, hours, minutes, seconds, completed }) => {
    const pad = (n) => String(n).padStart(2, "0");

    const circleStyle = {
      width: "100px",
      height: "100px",
      border: "4px solid #ff6b6b",
      borderRadius: "50%",
      background: "#fff5f5",
      display: "flex",
      justifyContent: "center",
      alignItems: "center",
      fontSize: "28px",
      fontWeight: "700",
      color: "#d9534f",
      marginBottom: "8px",
      boxShadow: "0 4px 12px rgba(255, 107, 107, 0.3)",
      transition: "all 0.3s ease",
    };

    const labelStyle = {
      fontSize: "14px",
      fontWeight: "500",
      color: "#444",
      textTransform: "uppercase",
    };

    const circleBoxStyle = {
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      textAlign: "center",
      margin: "0 10px",
    };

    const containerStyle = {
      display: "flex",
      justifyContent: "center",
      alignItems: "center",
      flexWrap: "wrap",
      gap: "20px",
      marginTop: "20px",
    };

    const completeStyle = {
      fontSize: "20px",
      fontWeight: "600",
      color: "#1e7d3d",
      textAlign: "center",
      padding: "12px 20px",
      background: "#e6f8ed",
      borderRadius: "12px",
      border: "1px solid #c8efd7",
    };

    if (completed) {
      return <div style={completeStyle}>It's the wedding day! 🎉</div>;
    }

    return (
      <div style={containerStyle}>
        <div style={circleBoxStyle}>
          <div style={circleStyle}>{pad(days)}</div>
          <span style={labelStyle}>Days</span>
        </div>
        <div style={circleBoxStyle}>
          <div style={circleStyle}>{pad(hours)}</div>
          <span style={labelStyle}>Hours</span>
        </div>
        <div style={circleBoxStyle}>
          <div style={circleStyle}>{pad(minutes)}</div>
          <span style={labelStyle}>Minutes</span>
        </div>
        <div style={circleBoxStyle}>
          <div style={circleStyle}>{pad(seconds)}</div>
          <span style={labelStyle}>Seconds</span>
        </div>
      </div>
    );
  };

  render() {
    const { weddingDate, saveday } = this.props;

    if (!weddingDate) {
      return (
        <div className={`saveday ${saveday || ""}`}>
          <p style={{ textAlign: "center", color: "#888" }}>
            No wedding date set
          </p>
        </div>
      );
    }

    const targetDate = new Date(`${weddingDate}T23:59:59`);
    if (isNaN(targetDate.getTime())) {
      return (
        <div className={`saveday ${saveday || ""}`}>
          <p style={{ textAlign: "center", color: "#888" }}>
            Invalid wedding date
          </p>
        </div>
      );
    }

    const wrapperStyle = {
      padding: "40px 0",
      display: "flex",
      justifyContent: "center",
      alignItems: "center",
      flexDirection: "column",
      background: "#fff",
    };

    const titleStyle = {
      fontSize: "22px",
      fontWeight: "600",
      color: "#333",
      marginBottom: "10px",
      textAlign: "center",
    };

    return (
      <div className={`saveday ${saveday || ""}`} style={wrapperStyle}>
        {/* <h3 style={titleStyle}>Countdown to Our Special Day</h3> */}
        <Sectiontitle section={"Countdown to Our Special Day"} />
        <Countdown date={targetDate} renderer={this.renderer} />
      </div>
    );
  }
}

export default Saveday;
