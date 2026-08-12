import React, { useState, useEffect, useCallback, useRef } from "react";
import { useSelector } from "react-redux";
import axiosInstance from "../../../../services/api/axiosInstance";
import {
  FaSearch,
  FaDownload,
  FaPrint,
  FaEnvelope,
  FaUserPlus,
  FaUsers,
  FaChevronDown,
  FaTrash,
  FaWhatsapp,
} from "react-icons/fa";
import Swal from "sweetalert2";
import EmailModal from "../../../ui/EmailModal";
import { pdf } from "@react-pdf/renderer";
import GuestListPDF from "./GuestListPDF";
import { useNavigate } from "react-router-dom";

const initialGuestFormState = {
  name: "",
  email: "",
  phone_number: "",
  groupId: "",

  type: "Adult",
  companions: 0,
  seat_number: "",
  menu: "Veg",
};

const Guests = () => {
  const token = useSelector((state) => state.auth.token);
  const userId = useSelector((state) => state.auth.user?.id);
  const userEmail = useSelector((state) => state.auth.user?.email) || "";
  const userName = useSelector((state) => state.auth.user?.name) || "";
  const userPhone = useSelector((state) => state.auth.user?.phone) || "";
  const [guests, setGuests] = useState([]);
  const [newGuestForm, setNewGuestForm] = useState(initialGuestFormState);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedGroup, setSelectedGroup] = useState("All");
  const [selectedStatus, setSelectedStatus] = useState("All");
  const [showAddGuestForm, setShowAddGuestForm] = useState(false);
  const [showAddGroupForm, setShowAddGroupForm] = useState(false);
  const [showMessageOptions, setShowMessageOptions] = useState(false);
  const [loading, setLoading] = useState(true);
  const [, setCurrentPage] = useState(1);
  const printRef = useRef();
  const navigate = useNavigate();

  const [formError, setFormError] = useState("");
  const [refresh, setRefresh] = useState(false);
  const [availableGroups, setAvailableGroups] = useState([]);
  const [newGroupName, setNewGroupName] = useState("");
  const [showEmailModal, setShowEmailModal] = useState(false);
  const [sendingEmail, setSendingEmail] = useState(false);
  const [showWhatsAppModal, setShowWhatsAppModal] = useState(false);
  const [whatsappMessage, setWhatsappMessage] = useState("");
  const [groupsLoading, setGroupsLoading] = useState(false);
  const [selectedGuestIds, setSelectedGuestIds] = useState(new Set());
  const [whatsappRecipients, setWhatsappRecipients] = useState(null);

  const statusOptions = ["Attending", "Not Attending", "Pending"];
  const typeOptions = ["Adult", "Child"];
  const menuOptions = ["Veg", "NonVeg", "All"];

  const _handlePrint = () => {
    if (!printRef.current) {
      Swal.fire({
        icon: "error",
        text: "No content available to print",
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
      return;
    }
    const printContents = printRef.current.innerHTML;
    const printWindow = window.open("", "", "height=600,width=800");
    if (!printWindow) {
      Swal.fire({
        icon: "error",
        text: "Please allow popups to print",
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
      return;
    }
    printWindow.document.write("<html><head><title>Guest List</title>");
    printWindow.document.write(`
      <style>
        body { font-family: Arial; padding: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
        th { background-color: #f4f4f4; }
      </style>
    `);
    printWindow.document.write("</head><body>");
    printWindow.document.write(printContents);
    printWindow.document.write("</body></html>");
    printWindow.document.close();
    printWindow.print();
  };

  const fetchGuests = useCallback(async () => {
    if (!userId) {
      setLoading(false);
      return;
    }
    setLoading(true);
    try {
      const userIdToSend = isNaN(userId) ? userId : parseInt(userId, 10);

      const res = await axiosInstance.get(
        `https://happywedz.com/api/guestlist/user/${userIdToSend}`
      );

      if (res.data?.success && Array.isArray(res.data?.guests)) {
        setGuests(res.data.guests);
      } else {
        setGuests([]);
      }
    } catch (err) {
      console.error("Fetch Guests Error:", err);
      setGuests([]);
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    fetchGuests();
  }, [refresh, fetchGuests]);

  const fetchGroups = useCallback(async () => {
    if (!userId) {
      return;
    }
    setGroupsLoading(true);
    try {
      const res = await axiosInstance.get("https://happywedz.com/api/groups");

      if (res.data?.success && Array.isArray(res.data?.groups)) {
        setAvailableGroups(res.data.groups);
      } else {
        setAvailableGroups([]);
      }
    } catch (err) {
      console.error("Fetch Groups Error:", err);
      setAvailableGroups([]);
    } finally {
      setGroupsLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    fetchGroups();
  }, [fetchGroups]);

  // Get unique group names from guests for filtering
  const _uniqueGroups = React.useMemo(() => {
    const groupNames = new Set();
    guests.forEach((g) => {
      if (g.group) {
        groupNames.add(g.group);
      } else if (g.groupId) {
        // If guest has groupId, find the group name
        const group = availableGroups.find((gr) => gr.id === g.groupId);
        if (group) {
          groupNames.add(group.name);
        } else {
          groupNames.add("Other");
        }
      } else {
        groupNames.add("Other");
      }
    });
    return ["All", ...Array.from(groupNames)];
  }, [guests, availableGroups]);

  const filteredAndGroupedGuests = React.useMemo(() => {
    const filtered = guests.filter((g) => {
      if (!g) return false;

      // Get group name for filtering
      let guestGroupName = "Other";
      if (g.group) {
        guestGroupName = g.group;
      } else if (g.groupId) {
        const group = availableGroups.find((gr) => gr.id === g.groupId);
        guestGroupName = group ? group.name : "Other";
      }

      return (
        (selectedGroup === "All" || guestGroupName === selectedGroup) &&
        (selectedStatus === "All" || g.status === selectedStatus) &&
        g.name.toLowerCase().includes(searchTerm.toLowerCase())
      );
    });

    return filtered.reduce((acc, guest) => {
      let groupName = "Other";
      if (guest.group) {
        groupName = guest.group;
      } else if (guest.groupId) {
        const group = availableGroups.find((gr) => gr.id === guest.groupId);
        groupName = group ? group.name : "Other";
      }
      if (!acc[groupName]) {
        acc[groupName] = [];
      }
      acc[groupName].push(guest);
      return acc;
    }, {});
  }, [guests, selectedGroup, selectedStatus, searchTerm, availableGroups]);

  const toggleGuestSelection = (id) => {
    setSelectedGuestIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setNewGuestForm((prev) => ({ ...prev, [name]: value }));
  };

  const addGuestAPI = async () => {
    setFormError("");
    if (!newGuestForm.name.trim()) {
      setFormError("Guest name is required.");
      return;
    }

    if (!newGuestForm.email || !newGuestForm.email.trim()) {
      setFormError("Email is required.");
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(newGuestForm.email.trim())) {
      setFormError("Please enter a valid email address.");
      return;
    }

    if (!userId) {
      setFormError("User not identified. Please log in again.");
      return;
    }

    try {
      const userIdToSend = isNaN(userId) ? userId : parseInt(userId, 10);

      // Prepare payload with groupId (convert to number if it's a string)
      const payload = {
        name: newGuestForm.name.trim(),
        email: newGuestForm.email.trim(),
        phone_number: newGuestForm.phone_number?.trim() || null,
        userId: userIdToSend,
        status: "Pending",
        type: newGuestForm.type,
        menu: newGuestForm.menu,
        companions: parseInt(newGuestForm.companions, 10) || 0,
        seat_number: newGuestForm.seat_number || null,
      };

      // Add groupId only if it's selected (not empty)
      if (newGuestForm.groupId) {
        payload.groupId = isNaN(newGuestForm.groupId)
          ? newGuestForm.groupId
          : parseInt(newGuestForm.groupId, 10);
      }

      const res = await axiosInstance.post(
        "https://happywedz.com/api/guestlist",
        payload
      );
      if (res.data?.success && res.data.guest) {
        setGuests((prev) => [res.data.guest, ...prev]);
      }
      setNewGuestForm(initialGuestFormState);
      setShowAddGuestForm(false);
      setSelectedGuestIds(new Set());
    } catch (err) {
      const errorMessage =
        err.response?.data?.message ||
        "An error occurred while adding the guest.";
      if (
        errorMessage.includes("Token invalid") ||
        errorMessage.includes("token")
      ) {
        setFormError("Authentication error. Please try logging in again.");
        console.error(
          "Token validation failed. User may need to re-authenticate."
        );
      } else {
        setFormError(errorMessage);
      }

      console.error("Add Guest Error:", err.response || err);
    }
  };

  const updateGuestField = async (id, field, value) => {
    try {
      await axiosInstance.put(`https://happywedz.com/api/guestlist/${id}`, {
        [field]: value,
      });
      setRefresh((prev) => !prev);
    } catch (err) {
      console.error("Update Guest Error:", err);
    }
  };

  const deleteGuestAPI = async (id) => {
    if (!window.confirm("Are you sure?")) return;
    setGuests((prevGuests) => prevGuests.filter((guest) => guest.id !== id));
    try {
      await axiosInstance.delete(`https://happywedz.com/api/guestlist/${id}`);
    } catch (err) {
      console.error("Delete Guest Error:", err);
      setRefresh((prev) => !prev);
    }
  };

  const attendingCount = guests.filter(
    (g) => g && g.status === "Attending"
  ).length;
  const pendingCount = guests.filter((g) => g && g.status === "Pending").length;
  const declinedCount = guests.filter(
    (g) => g && g.status === "Not Attending"
  ).length;
  const adultsCount = guests.filter((g) => g && g.type === "Adult").length;
  const childrenCount = guests.filter((g) => g && g.type === "Child").length;

  const formatGuestListForWhatsApp = () => {
    if (guests.length === 0) {
      return "No guests in the list.";
    }

    // Send custom wedding invitation template only
    let message = `We, the family of [Family Name],\n`;
    message += `warmly invite you to the wedding of\n`;
    message += `[Bride Name] & [Groom Name]\n\n`;
    message += `Date: [Date]\n`;
    message += `Venue: [Venue]\n\n`;
    message += `Your presence means a lot to us.`;

    return message;
  };

  const sanitizePhone = (raw) => {
    if (!raw) return "";
    let phone = String(raw)
      .replace(/\s+/g, "")
      .replace(/-/g, "")
      .replace(/\+/g, "")
      .replace(/\(/g, "")
      .replace(/\)/g, "")
      .replace(/\./g, "");
    if (phone.startsWith("0")) phone = phone.substring(1);
    return phone;
  };

  const sendMessage = (type) => {
    if (type === "Email") {
      setShowEmailModal(true);
      setShowMessageOptions(false);
    } else if (type === "WhatsApp") {
      // Open WhatsApp modal with pre-filled message
      if (!userPhone) {
        Swal.fire({
          icon: "error",
          text: "Phone number not found. Please update your profile with a phone number.",
          confirmButtonText: "OK",
          confirmButtonColor: "#C31162",
        });
        setShowMessageOptions(false);
        return;
      }

      if (guests.length === 0) {
        Swal.fire({
          icon: "info",
          text: "No guests to share.",
          confirmButtonText: "OK",
          confirmButtonColor: "#C31162",
        });
        setShowMessageOptions(false);
        return;
      }

      // Set pre-filled message and show modal
      const templateMessage = formatGuestListForWhatsApp();
      setWhatsappMessage(templateMessage);
      setShowWhatsAppModal(true);
      setShowMessageOptions(false);
    }
  };

  const handleSendWhatsAppMessage = () => {
    if (!whatsappMessage.trim()) {
      Swal.fire({
        icon: "error",
        text: "Please enter a message",
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
      return;
    }
    const encodedMessage = encodeURIComponent(whatsappMessage);

    if (Array.isArray(whatsappRecipients) && whatsappRecipients.length > 0) {
      const invalids = [];
      whatsappRecipients.forEach((raw) => {
        const phone = sanitizePhone(raw);
        if (!/^\d+$/.test(phone)) {
          invalids.push(raw);
          return;
        }
        const whatsappUrl = `https://wa.me/${phone}?text=${encodedMessage}`;
        window.open(whatsappUrl, "_blank");
      });
      if (invalids.length > 0) {
        Swal.fire({
          icon: "warning",
          text: `Some numbers were invalid and skipped: ${invalids.join(", ")}`,
          confirmButtonText: "OK",
          confirmButtonColor: "#C31162",
        });
      }
      setShowWhatsAppModal(false);
      setWhatsappMessage("");
      setWhatsappRecipients(null);
      return;
    }

    let phoneNumber = sanitizePhone(userPhone);
    if (!/^\d+$/.test(phoneNumber)) {
      Swal.fire({
        icon: "error",
        text: "Invalid phone number format. Please update your profile with a valid phone number.",
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
      return;
    }
    const whatsappUrl = `https://wa.me/${phoneNumber}?text=${encodedMessage}`;
    window.open(whatsappUrl, "_blank");
    setShowWhatsAppModal(false);
    setWhatsappMessage("");
  };

  const redirectToEinviteCards = () => {
    navigate(`/einvites/my-cards`);
  };

  const handleSendGuestListEmail = async (emailData) => {
    if (!emailData || !emailData.toEmail || emailData.toEmail.length === 0) {
      Swal.fire({
        icon: "error",
        text: "Please add at least one recipient email",
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
      return;
    }

    if (!userId) {
      Swal.fire({
        icon: "error",
        text: "Authentication error. Please log in again.",
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
      return;
    }

    setSendingEmail(true);
    try {
      const userIdToSend = isNaN(userId) ? userId : parseInt(userId, 10);

      const payload = {
        userId: userIdToSend,
        toEmail: emailData.toEmail,
        ...(emailData.ccEmail &&
          emailData.ccEmail.length > 0 && { ccEmail: emailData.ccEmail }),
        ...(emailData.bccEmail &&
          emailData.bccEmail.length > 0 && { bccEmail: emailData.bccEmail }),
        subject: emailData.subject || "Guest List",
        message: emailData.message || "",
      };

      const response = await axiosInstance.post(
        "https://happywedz.com/api/guestlist/send-guestlist-email",
        payload
      );

      if (response.data?.success) {
        Swal.fire({
          icon: "success",
          text: "Guest list sent successfully!",
          timer: 3000,
          confirmButtonText: "OK",
          confirmButtonColor: "#C31162",
        });
        setShowEmailModal(false);
      } else {
        throw new Error(response.data?.message || "Failed to send email");
      }
    } catch (err) {
      const errorMessage =
        err.response?.data?.message ||
        err.message ||
        "An error occurred while sending the email.";
      Swal.fire({
        icon: "error",
        text: errorMessage,
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
      console.error("Send Email Error:", err.response || err);
    } finally {
      setSendingEmail(false);
    }
  };

  if (loading) {
    return (
      <div className="wgl-container">
        <p>Loading guests...</p>
      </div>
    );
  }

  const handleDownload = async () => {
    if (guests.length === 0) {
      Swal.fire({
        icon: "info",
        text: "No guests to download.",
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
      return;
    }

    try {
      // Show loading message
      Swal.fire({
        title: "Generating PDF...",
        allowOutsideClick: false,
        didOpen: () => {
          Swal.showLoading();
        },
      });

      // Generate PDF
      const doc = (
        <GuestListPDF
          guests={guests}
          meta={{
            userName: userName || "",
            generatedAt: new Date(),
          }}
        />
      );

      const asPdf = pdf(doc);
      const blob = await asPdf.toBlob();

      // Create download link
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.setAttribute("download", "guest-list.pdf");
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);

      // Close loading and show success
      Swal.close();
      Swal.fire({
        icon: "success",
        text: "Guest list downloaded successfully!",
        timer: 2000,
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
    } catch (err) {
      console.error("Download Error:", err);
      Swal.close();
      Swal.fire({
        icon: "error",
        text: "Could not download the guest list.",
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
    }
  };

  return (
    <div className="wgl-container">
      <div className="row">
        <div className="col-md-2">
          <div className="d-flex flex-column gap-3">
            <div className="position-relative">
              <label className="form-label fw-medium text-black mb-1 fs-16 py-3">
                Group
              </label>
              <select
                className="form-select form-select-sm border-2 py-2 primary-text fs-14"
                style={{
                  cursor: "pointer",
                  borderRadius: "0px",
                  borderColor: "#ed1173",
                }}
                value={selectedGroup}
                onChange={(e) => {
                  setSelectedGroup(e.target.value);
                  setCurrentPage(1);
                }}
              >
                <option value="All">All Groups</option>
                <option value="Other">Other</option>
                {availableGroups.map((group) => (
                  <option key={group.id} value={group.name}>
                    {group.name}
                  </option>
                ))}
              </select>
            </div>
            <div className="position-relative">
              <label className="form-label fw-medium text-black mb-1 fs-16 py-3">
                Status
              </label>
              <select
                className="form-select form-select-sm border-2 py-2 primary-text fs-14"
                style={{
                  cursor: "pointer",
                  borderRadius: "0px",
                  borderColor: "#ed1173",
                }}
                value={selectedStatus}
                onChange={(e) => {
                  setSelectedStatus(e.target.value);
                  setCurrentPage(1);
                }}
              >
                <option value="All">All Statuses</option>
                {statusOptions.map((s) => (
                  <option key={s}>{s}</option>
                ))}
              </select>
            </div>
          </div>
        </div>

        <div className="col-md-10">
          <div className="wgl-header">
            <h4 className="wgl-title">Guest List</h4>
            <div className="wgl-stats-container">
              <div className="wgl-stat-card">
                <h2 className="wgl-stat-number">{guests.length}</h2>
                <p className="wgl-stat-label">Guests</p>
              </div>

              <div className="wgl-stat-card">
                <h2 className="wgl-stat-number">{adultsCount}</h2>
                <p className="wgl-stat-label">Adults</p>
                <p className="wgl-stat-sublabel">Children: {childrenCount}</p>
              </div>
              <div className="wgl-stat-card">
                <h2 className="wgl-stat-number">{attendingCount}</h2>
                <p className="wgl-stat-label">Attending</p>
                <div className="wgl-status-sublabels">
                  <span className="wgl-status-sublabel">
                    Pending: {pendingCount}
                  </span>
                  <span className="wgl-status-sublabel">
                    Not Attending: {declinedCount}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div className="wgl-controls">
            <div className="wgl-search-container fs-14">
              <FaSearch className="wgl-search-icon" />
              <input
                type="text"
                className="wgl-search-input fs-14"
                placeholder="Search guests..."
                value={searchTerm}
                onChange={(e) => {
                  setSearchTerm(e.target.value);
                  setCurrentPage(1);
                }}
              />
            </div>
            <div className="wgl-button-group">
              <button
                className="wgl-button wgl-button-primary"
                onClick={() => {
                  setShowAddGuestForm(!showAddGuestForm);
                  setShowAddGroupForm(false);
                  setShowMessageOptions(false);
                }}
              >
                <span className="fs-14 d-flex align-items-center gap-1">
                  <FaUserPlus className="wgl-button-icon" /> Add Guest
                </span>
              </button>
              <button
                className="wgl-button wgl-button-secondary"
                onClick={() => {
                  setShowAddGroupForm(!showAddGroupForm);
                  setShowAddGuestForm(false);
                  setShowMessageOptions(false);
                }}
              >
                <span className="fs-14 d-flex align-items-center gap-1">
                  <FaUsers className="wgl-button-icon" /> Create Group
                </span>
              </button>
              <div className="wgl-message-dropdown">
                <button
                  className="wgl-button wgl-button-secondary"
                  onClick={() => {
                    setShowMessageOptions(!showMessageOptions);
                    setShowAddGuestForm(false);
                    setShowAddGroupForm(false);
                  }}
                >
                  <span className="fs-14 d-flex align-items-center gap-1">
                    <FaEnvelope className="wgl-button-icon" /> Send Message
                  </span>
                  <FaChevronDown className="wgl-dropdown-icon" />
                </button>
                {showMessageOptions && (
                  <div className="wgl-dropdown-menu">
                    <button
                      className="fs-14"
                      onClick={() => sendMessage("Email")}
                    >
                      Email
                    </button>
                    <button
                      className="fs-14"
                      onClick={() => redirectToEinviteCards()}
                    >
                      Einvite Cards
                    </button>
                    <button
                      className="fs-14"
                      onClick={() => sendMessage("WhatsApp")}
                    >
                      WhatsApp
                    </button>
                  </div>
                )}
              </div>

              {/* WhatsApp Modal */}
              {showWhatsAppModal && (
                <div
                  className="modal d-block"
                  style={{ backgroundColor: "rgba(0,0,0,0.5)" }}
                >
                  <div className="modal-dialog modal-lg">
                    <div className="modal-content">
                      <div className="modal-header">
                        <h5 className="modal-title">
                          Customize WhatsApp Message
                        </h5>
                        <button
                          type="button"
                          className="btn-close"
                          onClick={() => {
                            setShowWhatsAppModal(false);
                            setWhatsappMessage("");
                          }}
                        ></button>
                      </div>
                      <div className="modal-body">
                        <label className="form-label fw-bold mb-2">
                          Message
                        </label>
                        <textarea
                          className="form-control"
                          rows="8"
                          placeholder="Edit your message here..."
                          value={whatsappMessage}
                          onChange={(e) => setWhatsappMessage(e.target.value)}
                          style={{
                            fontFamily: "monospace",
                            fontSize: "12px",
                            resize: "vertical",
                          }}
                        />
                        <small className="text-muted d-block mt-2">
                          You can edit the message before sending. Line breaks
                          will be preserved.
                        </small>
                      </div>
                      <div className="modal-footer">
                        <button
                          type="button"
                          className="btn btn-secondary"
                          onClick={() => {
                            setShowWhatsAppModal(false);
                            setWhatsappMessage("");
                          }}
                        >
                          Cancel
                        </button>
                        <button
                          type="button"
                          className="btn btn-success"
                          onClick={handleSendWhatsAppMessage}
                        >
                          Send on WhatsApp
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* Email Modal */}
              <EmailModal
                show={showEmailModal}
                onClose={() => setShowEmailModal(false)}
                onSend={handleSendGuestListEmail}
                sending={sendingEmail}
                userEmail={userEmail}
                userName={userName}
              />
              <button
                className="wgl-button wgl-button-secondary"
                onClick={handleDownload}
              >
                <span className="fs-14 d-flex align-items-center gap-1">
                  {" "}
                  <FaDownload className="wgl-button-icon" /> Download{" "}
                </span>
              </button>
            </div>
          </div>

          {showAddGuestForm && (
            <div className="wgl-add-form card shadow-sm mb-4">
              <div className="card-body p-4">
                <h3 className="wgl-form-title card-title mb-4">
                  Add New Guest
                </h3>
                {formError && (
                  <div className="alert alert-danger small p-2">
                    {formError}
                  </div>
                )}
                <div className="row g-3">
                  <div className="col-md-4">
                    <label className="form-label">Guest Name</label>
                    <input
                      name="name"
                      className="form-control"
                      placeholder="e.g., John Doe"
                      value={newGuestForm.name}
                      onChange={handleFormChange}
                    />
                  </div>
                  <div className="col-md-4">
                    <label className="form-label">Guest Email</label>
                    <input
                      name="email"
                      type="email"
                      className="form-control"
                      placeholder=""
                      value={newGuestForm.email}
                      onChange={handleFormChange}
                    />
                  </div>
                  <div className="col-md-4">
                    <label className="form-label">Phone Number</label>
                    <input
                      name="phone_number"
                      type="tel"
                      className="form-control"
                      placeholder="e.g., +91 9876543210"
                      value={newGuestForm.phone_number}
                      onChange={handleFormChange}
                    />
                  </div>
                  <div className="col-md-4">
                    <label className="form-label">Companions</label>
                    <input
                      name="companions"
                      type="number"
                      className="form-control"
                      placeholder="e.g., 2"
                      value={newGuestForm.companions}
                      onChange={handleFormChange}
                    />
                  </div>
                  <div className="col-md-4">
                    <label className="form-label">Group</label>
                    <select
                      name="groupId"
                      className="form-select"
                      value={newGuestForm.groupId}
                      onChange={handleFormChange}
                    >
                      <option value="">Select a group (optional)</option>
                      {availableGroups.map((group) => (
                        <option key={group.id} value={group.id}>
                          {group.name}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="col-md-4">
                    <label className="form-label">Type</label>
                    <select
                      name="type"
                      className="form-select"
                      value={newGuestForm.type}
                      onChange={handleFormChange}
                    >
                      {typeOptions.map((t) => (
                        <option key={t} value={t}>
                          {t}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="col-md-4">
                    <label className="form-label">Menu Preference</label>
                    <select
                      name="menu"
                      className="form-select"
                      value={newGuestForm.menu}
                      onChange={handleFormChange}
                    >
                      {menuOptions.map((m) => (
                        <option key={m} value={m}>
                          {m}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="col-md-4">
                    <label className="form-label">Seat Number</label>
                    <input
                      name="seat_number"
                      className="form-control"
                      placeholder="e.g., A12"
                      value={newGuestForm.seat_number}
                      onChange={handleFormChange}
                    />
                  </div>
                </div>
                <div className="wgl-form-actions mt-4 d-flex justify-content-end gap-2">
                  <button
                    className="btn btn-light"
                    onClick={() => setShowAddGuestForm(false)}
                  >
                    Cancel
                  </button>
                  <button className="btn btn-primary" onClick={addGuestAPI}>
                    Save Guest
                  </button>
                </div>
              </div>
            </div>
          )}

          {showAddGroupForm && (
            <div className="wgl-add-form">
              <h4 className="wgl-form-title">Create New Group</h4>
              <input
                name="newGroupName"
                className="wgl-form-input"
                placeholder="Group Name"
                value={newGroupName}
                onChange={(e) => setNewGroupName(e.target.value)}
              />
              <div className="wgl-form-actions">
                <button
                  className="wgl-button wgl-button-cancel"
                  onClick={() => setShowAddGroupForm(false)}
                >
                  Cancel
                </button>
                <button
                  className="wgl-button wgl-button-save"
                  onClick={async () => {
                    if (!newGroupName.trim()) {
                      Swal.fire({
                        icon: "error",
                        text: "Please enter a group name",
                        confirmButtonColor: "#C31162",
                      });
                      return;
                    }

                    try {
                      const res = await axiosInstance.post(
                        "https://happywedz.com/api/groups/add",
                        {
                          name: newGroupName.trim(),
                        }
                      );

                      if (res.data?.success && res.data?.group) {
                        // Refresh groups list
                        await fetchGroups();

                        Swal.fire({
                          icon: "success",
                          text: `Group "${newGroupName}" created successfully`,
                          timer: 3000,
                          confirmButtonText: "OK",
                          confirmButtonColor: "#C31162",
                        });

                        setShowAddGroupForm(false);
                        setNewGroupName("");
                      } else {
                        throw new Error("Failed to create group");
                      }
                    } catch (err) {
                      const errorMessage =
                        err.response?.data?.message ||
                        err.message ||
                        "An error occurred while creating the group.";
                      Swal.fire({
                        icon: "error",
                        text: errorMessage,
                        confirmButtonText: "OK",
                        confirmButtonColor: "#C31162",
                      });
                      console.error("Create Group Error:", err.response || err);
                    }
                  }}
                >
                  Create Group
                </button>
              </div>
            </div>
          )}

          <div className="wgl-guest-list" ref={printRef}>
            {Object.keys(filteredAndGroupedGuests).length > 0 ? (
              Object.entries(filteredAndGroupedGuests).map(
                ([groupName, groupGuests]) => (
                  <div key={groupName} className="wgl-guest-group-section mb-5">
                    <h4 className="wgl-group-title p-2">
                      {groupName} ({groupGuests.length})
                    </h4>

                    <table className="wgl-guest-table">
                      <thead>
                        <tr>
                          {/* <th className="wgl-table-header fs-16">Select</th> */}
                          <th className="wgl-table-header fs-16">Guest</th>
                          <th className="wgl-table-header fs-16">Status</th>
                          <th className="wgl-table-header fs-16">Companions</th>
                          <th className="wgl-table-header fs-16">Seat</th>
                          <th className="wgl-table-header fs-16">Type</th>
                          <th className="wgl-table-header fs-16">Menu</th>
                          <th className="wgl-table-header fs-16">Phone</th>
                          <th className="wgl-table-header fs-16">Actions</th>
                        </tr>
                      </thead>

                      <tbody>
                        {groupGuests.map((g) => (
                          <tr key={g.id} className="wgl-guest-row">
                            {/* <td className="fs-14 text-center">
                              <input
                                type="checkbox"
                                checked={selectedGuestIds.has(g.id)}
                                onChange={() => toggleGuestSelection(g.id)}
                              />
                            </td> */}
                            <td className="wgl-guest-name fs-14 text-center">
                              {g.name}
                            </td>

                            <td className="wgl-guest-status fs-14 text-center">
                              <select
                                className={`wgl-status-select wgl-status-${g.status.toLowerCase()}`}
                                value={g.status}
                                onChange={(e) =>
                                  updateGuestField(
                                    g.id,
                                    "status",
                                    e.target.value
                                  )
                                }
                              >
                                {statusOptions.map((s) => (
                                  <option key={s}>{s}</option>
                                ))}
                              </select>
                            </td>

                            <td className="wgl-guest-companions fs-14 text-center">
                              {g.companions}
                            </td>

                            <td className="wgl-guest-seat fs-14 text-center">
                              {g.seat_number}
                            </td>

                            <td className="wgl-guest-type fs-14 text-center">
                              <select
                                value={g.type}
                                onChange={(e) =>
                                  updateGuestField(g.id, "type", e.target.value)
                                }
                              >
                                {typeOptions.map((t) => (
                                  <option key={t}>{t}</option>
                                ))}
                              </select>
                            </td>

                            <td className="wgl-guest-menu fs-14 text-center">
                              <select
                                value={g.menu}
                                onChange={(e) =>
                                  updateGuestField(g.id, "menu", e.target.value)
                                }
                              >
                                {menuOptions.map((m) => (
                                  <option key={m}>{m}</option>
                                ))}
                              </select>
                            </td>

                            <td className="fs-14 text-center">
                              {g.phone_number || "-"}
                            </td>

                            <td className="wgl-guest-actions fs-14 text-center">
                              <button
                                className="wgl-action-button"
                                title="WhatsApp"
                                onClick={() => {
                                  if (!g.phone_number) {
                                    Swal.fire({
                                      icon: "info",
                                      text: "No phone number for this guest.",
                                      confirmButtonText: "OK",
                                      confirmButtonColor: "#C31162",
                                    });
                                    return;
                                  }
                                  const msg = encodeURIComponent(
                                    whatsappMessage ||
                                    formatGuestListForWhatsApp()
                                  );
                                  const phone = sanitizePhone(g.phone_number);
                                  if (!/^\d+$/.test(phone)) {
                                    Swal.fire({
                                      icon: "error",
                                      text: "Invalid phone number for this guest.",
                                      confirmButtonText: "OK",
                                      confirmButtonColor: "#C31162",
                                    });
                                    return;
                                  }
                                  window.open(
                                    `https://wa.me/${phone}?text=${msg}`,
                                    "_blank"
                                  );
                                }}
                              >
                                <FaWhatsapp />
                              </button>
                              <button
                                className="wgl-action-button wgl-action-delete"
                                onClick={() => deleteGuestAPI(g.id)}
                              >
                                <FaTrash />
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )
              )
            ) : (
              <div className="wgl-empty-state">
                <p className="fs-14">No guests found matching your criteria</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Guests;
