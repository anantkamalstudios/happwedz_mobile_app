import React from "react";
import { Document, Page, Text, View, Image, StyleSheet } from "@react-pdf/renderer";
import { formatDateTime } from "../../../../utils/dateFormat";

const styles = StyleSheet.create({
  page: {
    paddingTop: 24,
    paddingBottom: 28,
    paddingHorizontal: 28,
    fontSize: 9.5,
    color: "#1f2937",
    fontFamily: "Helvetica",
  },
  headerRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingBottom: 12,
    borderBottomWidth: 2,
    borderBottomColor: "#ED1173",
    marginBottom: 12,
  },
  brandContainer: {
    flexDirection: "row",
    alignItems: "center",
  },
  logo: {
    width: 65,
    height: 65,
    marginRight: 10,
    objectFit: "contain",
  },
  brandName: {
    fontSize: 22,
    fontWeight: "bold",
    color: "#ED1173",
    letterSpacing: 0.5,
  },
  brandTagline: {
    fontSize: 8.5,
    color: "#6b7280",
    marginTop: 2,
  },
  brandUrl: {
    fontSize: 8,
    color: "#ED1173",
    marginTop: 2,
    fontWeight: "bold",
  },
  reportMetaBox: {
    alignItems: "flex-end",
  },
  reportTitle: {
    fontSize: 14,
    fontWeight: "bold",
    color: "#111827",
    marginBottom: 3,
  },
  reportMetaText: {
    fontSize: 8,
    color: "#6b7280",
    marginTop: 1,
  },
  summaryBar: {
    backgroundColor: "#FFF5F8",
    borderWidth: 1,
    borderColor: "#FCE7F3",
    borderRadius: 4,
    paddingVertical: 6,
    paddingHorizontal: 10,
    marginBottom: 12,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  summaryText: {
    fontSize: 8,
    color: "#831843",
    fontWeight: "bold",
  },
  summaryItem: {
    fontSize: 8,
    color: "#475569",
  },
  groupHeader: {
    backgroundColor: "#FFF0F6",
    paddingVertical: 5,
    paddingHorizontal: 8,
    marginTop: 10,
    marginBottom: 4,
    fontWeight: "bold",
    fontSize: 10,
    color: "#1e293b",
    borderLeftWidth: 3,
    borderLeftColor: "#ED1173",
    borderRadius: 2,
  },
  table: {
    marginTop: 2,
    borderWidth: 1,
    borderColor: "#E2E8F0",
    borderRadius: 2,
  },
  row: {
    flexDirection: "row",
    borderBottomWidth: 1,
    borderBottomColor: "#F1F5F9",
    alignItems: "center",
  },
  cellHeader: {
    paddingVertical: 5,
    paddingHorizontal: 6,
    backgroundColor: "#F8FAFC",
    borderRightWidth: 1,
    borderRightColor: "#E2E8F0",
    fontWeight: "bold",
    fontSize: 8.5,
    color: "#334155",
  },
  cell: {
    paddingVertical: 5,
    paddingHorizontal: 6,
    borderRightWidth: 1,
    borderRightColor: "#F1F5F9",
    fontSize: 8,
    color: "#1e293b",
  },
  wGuest: { width: "28%" },
  wStatus: { width: "16%" },
  wCompanions: { width: "12%" },
  wSeat: { width: "12%" },
  wType: { width: "16%" },
  wMenu: { width: "16%" },
  aboutBox: {
    marginTop: 18,
    padding: 10,
    backgroundColor: "#FAFAFA",
    borderWidth: 1,
    borderColor: "#E5E7EB",
    borderTopWidth: 2,
    borderTopColor: "#ED1173",
    borderRadius: 4,
  },
  aboutTitle: {
    fontSize: 9,
    fontWeight: "bold",
    color: "#ED1173",
    marginBottom: 3,
  },
  aboutDescription: {
    fontSize: 7.5,
    color: "#4B5563",
    lineHeight: 1.35,
  },
  footerRow: {
    marginTop: 10,
    paddingTop: 6,
    borderTopWidth: 1,
    borderTopColor: "#F3F4F6",
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  footerText: {
    fontSize: 7,
    color: "#9CA3AF",
  },
});

const GuestListPDF = ({ guests = [], meta = {} }) => {
  const { userName = "", availableGroups = [], generatedAt = new Date() } = meta;
  const dateStr =
    typeof generatedAt === "string"
      ? generatedAt
      : formatDateTime(generatedAt);

  // Helper to resolve group name
  const getGroupName = (guest) => {
    if (guest.city && String(guest.city).trim()) return String(guest.city).trim();
    if (guest.group && String(guest.group).trim()) return String(guest.group).trim();
    if (guest.groupData?.name && String(guest.groupData.name).trim()) return String(guest.groupData.name).trim();
    if (guest.groupId && Array.isArray(availableGroups)) {
      const match = availableGroups.find((g) => g.id === guest.groupId);
      if (match?.name) return match.name;
    }
    return "Other";
  };

  // Group guests by group/city
  const groupedGuests = guests.reduce((acc, guest) => {
    const groupName = getGroupName(guest);
    if (!acc[groupName]) {
      acc[groupName] = [];
    }
    acc[groupName].push(guest);
    return acc;
  }, {});

  const attendingCount = guests.filter((g) => g?.status === "Attending").length;
  const pendingCount = guests.filter((g) => g?.status === "Pending").length;
  const declinedCount = guests.filter(
    (g) => g?.status === "Not Attending"
  ).length;
  const adultsCount = guests.filter((g) => g?.type === "Adult").length;
  const childrenCount = guests.filter((g) => g?.type === "Child").length;

  return (
    <Document>
      <Page size="A4" style={styles.page}>
        {/* Top Header */}
        <View style={styles.headerRow}>
          <View style={styles.brandContainer}>
            <Image
              src={`${typeof window !== "undefined" ? window.location.origin : ""}/happywedzLogo.png`}
              style={styles.logo}
            />
            <View>
              <Text style={styles.brandName}>HappyWedz</Text>
              <Text style={styles.brandTagline}>India's Most Loved Wedding Planning Platform</Text>
              <Text style={styles.brandUrl}>www.happywedz.com</Text>
            </View>
          </View>
          <View style={styles.reportMetaBox}>
            <Text style={styles.reportTitle}>Wedding Guest List</Text>
            {userName ? (
              <Text style={styles.reportMetaText}>Planner: {userName}</Text>
            ) : null}
            <Text style={styles.reportMetaText}>Generated: {dateStr}</Text>
          </View>
        </View>

        {/* Summary Metrics Bar */}
        <View style={styles.summaryBar}>
          <Text style={styles.summaryText}>Total Guests: {guests.length}</Text>
          <Text style={styles.summaryItem}>Attending: {attendingCount}</Text>
          <Text style={styles.summaryItem}>Pending: {pendingCount}</Text>
          <Text style={styles.summaryItem}>Not Attending: {declinedCount}</Text>
          <Text style={styles.summaryItem}>Adults: {adultsCount}</Text>
          <Text style={styles.summaryItem}>Children: {childrenCount}</Text>
        </View>

        {/* Groups & Guest Tables */}
        {Object.entries(groupedGuests).map(([groupName, groupGuests]) => (
          <View key={groupName} wrap={false}>
            <Text style={styles.groupHeader}>
              {groupName} ({groupGuests.length} {groupGuests.length === 1 ? "Guest" : "Guests"})
            </Text>
            <View style={styles.table}>
              {/* Table Header */}
              <View style={styles.row}>
                <Text style={[styles.cellHeader, styles.wGuest]}>Guest</Text>
                <Text style={[styles.cellHeader, styles.wStatus]}>Status</Text>
                <Text style={[styles.cellHeader, styles.wCompanions]}>
                  Companions
                </Text>
                <Text style={[styles.cellHeader, styles.wSeat]}>Seat</Text>
                <Text style={[styles.cellHeader, styles.wType]}>Type</Text>
                <Text style={[styles.cellHeader, styles.wMenu]}>Menu</Text>
              </View>

              {/* Table Rows */}
              {groupGuests.map((guest, index) => (
                <View key={index} style={styles.row}>
                  <Text style={[styles.cell, styles.wGuest]}>
                    {guest.name || "N/A"}
                  </Text>
                  <Text style={[styles.cell, styles.wStatus]}>
                    {guest.status || "Pending"}
                  </Text>
                  <Text style={[styles.cell, styles.wCompanions]}>
                    {guest.companions || 0}
                  </Text>
                  <Text style={[styles.cell, styles.wSeat]}>
                    {guest.seat_number || "-"}
                  </Text>
                  <Text style={[styles.cell, styles.wType]}>
                    {guest.type || "Adult"}
                  </Text>
                  <Text style={[styles.cell, styles.wMenu]}>
                    {guest.menu || "Veg"}
                  </Text>
                </View>
              ))}
            </View>
          </View>
        ))}

        {guests.length === 0 && (
          <View style={{ marginTop: 20, padding: 15, textAlign: "center" }}>
            <Text style={{ fontSize: 11, color: "#6b7280" }}>
              No guests found in this wedding guest list.
            </Text>
          </View>
        )}

        {/* About HappyWedz Section */}
        <View style={styles.aboutBox} wrap={false}>
          <Text style={styles.aboutTitle}>About HappyWedz</Text>
          <Text style={styles.aboutDescription}>
            HappyWedz is India's favourite one-stop wedding planning platform. From discovering verified venues, photographers, makeup artists, and decorators to managing digital guest lists, RSVPs, e-invitations, checklists, and wedding budgets — HappyWedz simplifies wedding planning from start to finish.
          </Text>
        </View>

        {/* Footer */}
        <View style={styles.footerRow} wrap={false}>
          <Text style={styles.footerText}>
            Plan your dream wedding at www.happywedz.com | Contact: support@happywedz.com
          </Text>
          <Text style={styles.footerText}>
            HappyWedz Wedding Planner
          </Text>
        </View>
      </Page>
    </Document>
  );
};

export default GuestListPDF;
