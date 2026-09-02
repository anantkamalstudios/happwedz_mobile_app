import React, { useState, useRef } from "react";
import * as XLSX from "xlsx";
import {
  FaCloudUploadAlt,
  FaFileCsv,
  FaFileExcel,
  FaPaste,
  FaDownload,
  FaTimes,
  FaTrash,
  FaCheck,
  FaSpinner,
  FaUsers,
} from "react-icons/fa";
import Swal from "sweetalert2";
import axiosInstance from "../../../../services/api/axiosInstance";
import "./BulkImportModal.css";

const BulkImportModal = ({
  isOpen,
  onClose,
  onSuccess,
  availableGroups = [],
  userId,
}) => {
  const [activeTab, setActiveTab] = useState("file"); // 'file' | 'paste'
  const [dragOver, setDragOver] = useState(false);
  const [fileName, setFileName] = useState("");
  const [rawPastedText, setRawPastedText] = useState("");
  const [parsedGuests, setParsedGuests] = useState([]);
  const [selectedGlobalGroup, setSelectedGlobalGroup] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState("");
  const fileInputRef = useRef(null);

  if (!isOpen) return null;

  // Helper to normalize column names from Excel/CSV
  const normalizeKey = (key) => {
    return String(key || "")
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]/g, "");
  };

  // Convert raw row objects into normalized guest objects
  const processRawData = (rows) => {
    setErrorMsg("");
    if (!Array.isArray(rows) || rows.length === 0) {
      setErrorMsg("No data found in the selected file or text.");
      setParsedGuests([]);
      return;
    }

    const processed = [];

    rows.forEach((row, index) => {
      // Find matching keys
      const rowKeys = Object.keys(row);
      const getVal = (possibleKeys) => {
        for (const pk of possibleKeys) {
          const matchKey = rowKeys.find(
            (k) => normalizeKey(k) === normalizeKey(pk)
          );
          if (matchKey && row[matchKey] !== undefined && row[matchKey] !== null) {
            const val = String(row[matchKey]).trim();
            if (val) return val;
          }
        }
        return "";
      };

      const name = getVal(["name", "guestname", "fullname", "firstname", "guest", "attendee"]);
      if (!name) return; // Skip empty rows

      const email = getVal(["email", "emailaddress", "mail", "gmail", "e-mail"]);
      const phone_number = getVal(["phone", "phonenumber", "mobile", "mobilenumber", "contact", "cell"]);
      const city = getVal(["city", "location", "town", "place", "native", "nativeplace"]);
      const groupName = getVal(["group", "groupname", "category", "relation", "relationgroup"]) || city;
      const rawType = getVal(["type", "guesttype", "categorytype"]);
      const rawMenu = getVal(["menu", "food", "diet", "dietary", "menupreference"]);
      const rawCompanions = getVal(["companions", "plusones", "extra", "additionalguests", "count"]);
      const seat_number = getVal(["seat", "seatnumber", "table", "tablenumber", "seat_number"]);
      const rawStatus = getVal(["status", "rsvp", "attendance"]);

      // Normalize Type
      let type = "Adult";
      if (rawType && rawType.toLowerCase().includes("child")) {
        type = "Child";
      }

      // Normalize Menu
      let menu = "Veg";
      if (rawMenu) {
        const lm = rawMenu.toLowerCase();
        if (lm.includes("jain")) menu = "Jain";
        else if (lm.includes("vegan")) menu = "Vegan";
        else if (lm.includes("egg")) menu = "Eggetarian";
        else if (lm.includes("non") || lm.includes("nv")) menu = "NonVeg";
        else if (lm.includes("all")) menu = "All";
        else if (lm.includes("veg")) menu = "Veg";
      }

      // Normalize Status
      let status = "Pending";
      if (rawStatus) {
        const ls = rawStatus.toLowerCase();
        if (ls.includes("not") || ls.includes("declin")) status = "Not Attending";
        else if (ls.includes("attend") || ls.includes("yes") || ls.includes("confirm")) status = "Attending";
        else status = "Pending";
      }

      // Resolve Group ID if group name exists
      let groupId = null;
      let matchedGroupName = groupName || city || "";
      if (groupName && availableGroups.length > 0) {
        const matched = availableGroups.find(
          (g) => g.name?.toLowerCase().trim() === groupName.toLowerCase().trim()
        );
        if (matched) {
          groupId = matched.id;
          matchedGroupName = matched.name;
        }
      }

      processed.push({
        _tempId: `guest_${index}_${Date.now()}`,
        name,
        email: email || "",
        phone_number: phone_number || "",
        city: city || groupName || "",
        groupId,
        groupName: matchedGroupName,
        type,
        menu,
        companions: parseInt(rawCompanions, 10) || 0,
        seat_number: seat_number || "",
        status,
      });
    });

    if (processed.length === 0) {
      setErrorMsg("Could not detect any valid guest names in the uploaded data. Please ensure the file has a 'Name' column.");
      setParsedGuests([]);
    } else {
      setParsedGuests(processed);
    }
  };

  // Handle File Parsing (Excel / CSV)
  const handleFile = (file) => {
    if (!file) return;
    setFileName(file.name);
    setErrorMsg("");

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = new Uint8Array(e.target.result);
        const workbook = XLSX.read(data, { type: "array" });
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        const json = XLSX.utils.sheet_to_json(worksheet, { defval: "" });
        processRawData(json);
      } catch (err) {
        console.error("Error reading file:", err);
        setErrorMsg("Failed to read file. Please ensure it is a valid .xlsx, .xls, or .csv file.");
      }
    };
    reader.readAsArrayBuffer(file);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setDragOver(false);
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFile(e.dataTransfer.files[0]);
    }
  };

  // Handle Pasted Text Parsing
  const handleParsePastedText = () => {
    if (!rawPastedText.trim()) {
      setErrorMsg("Please paste some text or tabular rows to import.");
      return;
    }

    try {
      // Use XLSX to read CSV / TSV text
      const workbook = XLSX.read(rawPastedText, { type: "string" });
      const sheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[sheetName];
      const json = XLSX.utils.sheet_to_json(worksheet, { defval: "" });
      processRawData(json);
    } catch (err) {
      console.error("Error parsing text:", err);
      // Fallback simple line-by-line split
      const lines = rawPastedText
        .split(/\r?\n/)
        .map((l) => l.trim())
        .filter(Boolean);

      if (lines.length === 0) {
        setErrorMsg("No text found to parse.");
        return;
      }

      const rows = lines.map((line) => {
        const parts = line.split(/[,\t|]/).map((p) => p.trim());
        return {
          name: parts[0] || "",
          email: parts[1] || "",
          phone: parts[2] || "",
          group: parts[3] || "",
          type: parts[4] || "Adult",
          menu: parts[5] || "Veg",
          companions: parts[6] || 0,
        };
      });

      processRawData(rows);
    }
  };

  // Download Sample CSV Template
  const downloadSampleTemplate = () => {
    const csvContent =
      "Name,City,Email,Phone,Type,Menu,Companions,Seat Number,Status\n" +
      "Rahul Sharma,Nashik,rahul.sharma@example.com,+919876543210,Adult,Veg,1,Table-1,Attending\n" +
      "Pooja Patel,Pune,pooja.patel@example.com,+919876543211,Adult,NonVeg,0,Table-2,Pending\n" +
      "Aarav Verma,Mumbai,aarav.verma@example.com,+919876543212,Child,Veg,0,Table-1,Attending\n";

    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.setAttribute("download", "happywedz_guest_template.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // Remove individual row from preview
  const removeRow = (tempId) => {
    setParsedGuests((prev) => prev.filter((g) => g._tempId !== tempId));
  };

  // Submit bulk guests to API
  const handleSubmitBulk = async () => {
    if (parsedGuests.length === 0) {
      Swal.fire({
        icon: "warning",
        text: "Please upload or paste guests data first.",
        confirmButtonColor: "#ed1173",
      });
      return;
    }

    if (!userId) {
      Swal.fire({
        icon: "error",
        text: "User session not found. Please log in again.",
        confirmButtonColor: "#ed1173",
      });
      return;
    }

    setIsSubmitting(true);

    const userIdToSend = isNaN(userId) ? userId : parseInt(userId, 10);

    try {
      // 1. Build a map of existing groups (name -> id)
      const groupMap = new Map();
      availableGroups.forEach((ag) => {
        if (ag.name && ag.id) {
          groupMap.set(String(ag.name).toLowerCase().trim(), ag.id);
        }
      });

      // 2. Identify distinct cities/groups from the parsed rows that don't exist yet
      const missingGroupNames = new Set();
      parsedGuests.forEach((g) => {
        const rawGroup = selectedGlobalGroup ? "" : (g.city || g.groupName || "").trim();
        if (rawGroup && !groupMap.has(rawGroup.toLowerCase())) {
          missingGroupNames.add(rawGroup);
        }
      });

      // 3. Auto-create any missing groups on the backend
      for (const newGrpName of missingGroupNames) {
        try {
          const createRes = await axiosInstance.post(
            "https://happywedz.com/api/groups/add",
            { name: newGrpName }
          );
          if (createRes.data?.success && createRes.data?.group?.id) {
            groupMap.set(newGrpName.toLowerCase(), createRes.data.group.id);
          }
        } catch (grpErr) {
          console.warn(`Could not create group "${newGrpName}":`, grpErr);
        }
      }

      // 4. Construct guest payloads with valid groupIds
      const payloadGuests = parsedGuests.map((g) => {
        let finalCityOrGroup = (g.city || g.groupName || "").trim();
        let finalGroupId = g.groupId;

        if (selectedGlobalGroup) {
          finalGroupId = isNaN(selectedGlobalGroup)
            ? selectedGlobalGroup
            : parseInt(selectedGlobalGroup, 10);
          const found = availableGroups.find((gr) => String(gr.id) === String(selectedGlobalGroup));
          if (found?.name) finalCityOrGroup = found.name;
        } else if (finalCityOrGroup) {
          finalGroupId = groupMap.get(finalCityOrGroup.toLowerCase()) || finalGroupId || null;
        }

        return {
          name: g.name.trim(),
          email: g.email ? g.email.trim() : null,
          phone_number: g.phone_number ? g.phone_number.trim() : null,
          city: finalCityOrGroup || null,
          group: finalCityOrGroup || null,
          groupId: finalGroupId,
          type: g.type || "Adult",
          menu: g.menu || "Veg",
          companions: parseInt(g.companions, 10) || 0,
          seat_number: g.seat_number ? String(g.seat_number).trim() : null,
          status: g.status || "Pending",
        };
      });
      // 1. Try batch bulk endpoint first
      let successCount = 0;
      try {
        const bulkRes = await axiosInstance.post(
          "https://happywedz.com/api/guestlist/bulk",
          {
            userId: userIdToSend,
            guests: payloadGuests,
          }
        );

        if (bulkRes.data?.success) {
          successCount = bulkRes.data.count || payloadGuests.length;
        }
      } catch (bulkErr) {
        console.warn("Bulk endpoint failed, falling back to iterative addition...", bulkErr);
        // Fallback: batch individual calls
        const results = await Promise.allSettled(
          payloadGuests.map((guestPayload) =>
            axiosInstance.post("https://happywedz.com/api/guestlist", {
              ...guestPayload,
              userId: userIdToSend,
            })
          )
        );

        successCount = results.filter((r) => r.status === "fulfilled").length;
      }

      setIsSubmitting(false);

      if (successCount > 0) {
        Swal.fire({
          icon: "success",
          title: "Import Successful!",
          text: `Successfully imported ${successCount} guest${successCount > 1 ? "s" : ""} to your wedding guest list.`,
          confirmButtonColor: "#ed1173",
        });

        if (onSuccess) onSuccess();
        handleClose();
      } else {
        Swal.fire({
          icon: "error",
          title: "Import Failed",
          text: "Failed to import guests. Please check your data and try again.",
          confirmButtonColor: "#ed1173",
        });
      }
    } catch (err) {
      console.error("Bulk Import Error:", err);
      setIsSubmitting(false);
      Swal.fire({
        icon: "error",
        title: "Import Error",
        text: err.response?.data?.message || err.message || "An error occurred during import.",
        confirmButtonColor: "#ed1173",
      });
    }
  };

  const handleClose = () => {
    setParsedGuests([]);
    setFileName("");
    setRawPastedText("");
    setErrorMsg("");
    setSelectedGlobalGroup("");
    onClose();
  };

  return (
    <div className="hw-bulk-overlay" onClick={handleClose}>
      <div className="hw-bulk-modal" onClick={(e) => e.stopPropagation()}>
        {/* Header */}
        <div className="hw-bulk-header">
          <div className="hw-bulk-header-left">
            <div className="hw-bulk-header-icon">
              <FaUsers />
            </div>
            <div>
              <h3 className="hw-bulk-title">Bulk Import Guests</h3>
              <p className="hw-bulk-subtitle">
                Add multiple guests at once using an Excel/CSV file or text
              </p>
            </div>
          </div>
          <button className="hw-bulk-close" onClick={handleClose} aria-label="Close">
            <FaTimes />
          </button>
        </div>

        {/* Body */}
        <div className="hw-bulk-body">
          {/* Action Bar: Tabs & Download Sample */}
          <div className="hw-bulk-actions-bar">
            <div className="hw-bulk-tabs">
              <button
                type="button"
                className={`hw-bulk-tab ${activeTab === "file" ? "active" : ""}`}
                onClick={() => setActiveTab("file")}
              >
                <FaFileExcel /> Upload Excel / CSV
              </button>
              <button
                type="button"
                className={`hw-bulk-tab ${activeTab === "paste" ? "active" : ""}`}
                onClick={() => setActiveTab("paste")}
              >
                <FaPaste /> Copy-Paste Data
              </button>
            </div>

            <button
              type="button"
              className="hw-bulk-template-btn"
              onClick={downloadSampleTemplate}
              title="Download a ready-to-fill CSV template"
            >
              <FaDownload /> Download Sample CSV
            </button>
          </div>

          {/* Tab 1: Upload File */}
          {activeTab === "file" && (
            <div>
              <div
                className={`hw-bulk-dropzone ${dragOver ? "dragover" : ""}`}
                onDragOver={(e) => {
                  e.preventDefault();
                  setDragOver(true);
                }}
                onDragLeave={() => setDragOver(false)}
                onDrop={handleDrop}
                onClick={() => fileInputRef.current?.click()}
              >
                <FaCloudUploadAlt className="hw-bulk-drop-icon" />
                <div className="hw-bulk-drop-title">
                  {fileName ? `Selected: ${fileName}` : "Drag & Drop your Excel or CSV file here"}
                </div>
                <div className="hw-bulk-drop-sub">
                  Supports .xlsx, .xls, and .csv files
                </div>
                <span className="hw-bulk-browse-btn">
                  {fileName ? "Change File" : "Browse Computer"}
                </span>
                <input
                  type="file"
                  ref={fileInputRef}
                  style={{ display: "none" }}
                  accept=".xlsx, .xls, .csv, text/csv, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/vnd.ms-excel"
                  onChange={(e) => {
                    if (e.target.files && e.target.files[0]) {
                      handleFile(e.target.files[0]);
                    }
                  }}
                />
              </div>
            </div>
          )}

          {/* Tab 2: Copy-Paste Data */}
          {activeTab === "paste" && (
            <div className="hw-bulk-textarea-wrap">
              <label>Paste Rows from Excel / Spreadsheet / CSV:</label>
              <textarea
                className="hw-bulk-textarea"
                placeholder="Name, Email, Phone, Group, Type, Menu, Companions&#10;Rahul Sharma, rahul@example.com, 9876543210, Groom Family, Adult, Veg, 1&#10;Pooja Patel, pooja@example.com, 9876543211, Bride Friends, Adult, NonVeg, 0"
                value={rawPastedText}
                onChange={(e) => setRawPastedText(e.target.value)}
              />
              <div className="d-flex justify-content-between align-items-center mt-2">
                <span className="hw-bulk-textarea-hint">
                  Header row is optional. Separate columns with commas or tabs.
                </span>
                <button
                  type="button"
                  className="hw-bulk-template-btn"
                  style={{ background: "#fff0f6", color: "#ed1173", borderColor: "#f9b6d6" }}
                  onClick={handleParsePastedText}
                >
                  <FaCheck /> Parse Pasted Text
                </button>
              </div>
            </div>
          )}

          {/* Error Message */}
          {errorMsg && (
            <div className="alert alert-danger mt-3 py-2 px-3 fs-13 d-flex align-items-center gap-2">
              <FaTimes /> {errorMsg}
            </div>
          )}

          {/* Preview Table */}
          {parsedGuests.length > 0 && (
            <div className="hw-bulk-preview-wrap">
              <div className="hw-bulk-preview-header">
                <div className="hw-bulk-preview-title">
                  <span>Guest Preview</span>
                  <span className="hw-bulk-count-badge">
                    {parsedGuests.length} Guests Ready
                  </span>
                </div>

                {availableGroups.length > 0 && (
                  <div className="hw-bulk-group-select-wrap">
                    <span>Assign All to Group:</span>
                    <select
                      className="hw-bulk-group-select"
                      value={selectedGlobalGroup}
                      onChange={(e) => setSelectedGlobalGroup(e.target.value)}
                    >
                      <option value="">Use file groups / No Group</option>
                      {availableGroups.map((g) => (
                        <option key={g.id} value={g.id}>
                          {g.name}
                        </option>
                      ))}
                    </select>
                  </div>
                )}
              </div>

              <div className="hw-bulk-table-wrap">
                <table className="hw-bulk-table">
                  <thead>
                    <tr>
                      <th>#</th>
                      <th>Guest Name</th>
                      <th>City / Group</th>
                      <th>Email</th>
                      <th>Phone</th>
                      <th>Type</th>
                      <th>Menu</th>
                      <th>+1s</th>
                      <th>Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    {parsedGuests.map((guest, idx) => (
                      <tr key={guest._tempId}>
                        <td style={{ color: "#94a3b8" }}>{idx + 1}</td>
                        <td style={{ fontWeight: 600 }}>{guest.name}</td>
                        <td style={{ fontWeight: 500, color: "#ed1173" }}>
                          {selectedGlobalGroup
                            ? availableGroups.find(
                                (g) => String(g.id) === String(selectedGlobalGroup)
                              )?.name || "—"
                            : guest.city || guest.groupName || "—"}
                        </td>
                        <td>{guest.email || "—"}</td>
                        <td>{guest.phone_number || "—"}</td>
                        <td>
                          <span
                            className="hw-bulk-pill"
                            style={{
                              background: guest.type === "Child" ? "#e0f2fe" : "#f1f5f9",
                              color: guest.type === "Child" ? "#0369a1" : "#475569",
                            }}
                          >
                            {guest.type}
                          </span>
                        </td>
                        <td>
                          <span
                            className={`hw-bulk-pill ${
                              guest.menu === "NonVeg"
                                ? "hw-bulk-pill-nonveg"
                                : "hw-bulk-pill-veg"
                            }`}
                          >
                            {guest.menu}
                          </span>
                        </td>
                        <td>{guest.companions || 0}</td>
                        <td>
                          <button
                            type="button"
                            className="hw-bulk-remove-row"
                            title="Remove guest"
                            onClick={() => removeRow(guest._tempId)}
                          >
                            <FaTrash />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="hw-bulk-footer">
          <button
            type="button"
            className="hw-bulk-btn-cancel"
            onClick={handleClose}
            disabled={isSubmitting}
          >
            Cancel
          </button>
          <button
            type="button"
            className="hw-bulk-btn-submit"
            onClick={handleSubmitBulk}
            disabled={isSubmitting || parsedGuests.length === 0}
          >
            {isSubmitting ? (
              <>
                <FaSpinner className="fa-spin" /> Importing Guests...
              </>
            ) : (
              <>
                <FaCheck /> Import {parsedGuests.length} Guest{parsedGuests.length === 1 ? "" : "s"}
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};

export default BulkImportModal;
