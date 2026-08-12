import React from "react";
import { Document, Page, Text, View, StyleSheet } from "@react-pdf/renderer";

const styles = StyleSheet.create({
  page: {
    padding: 30,
    fontSize: 10,
    color: "#1f2937",
    fontFamily: "Helvetica",
  },
  header: {
    marginBottom: 20,
    paddingBottom: 12,
    borderBottomWidth: 2,
    borderBottomColor: "#d1d5db",
  },
  title: {
    fontSize: 20,
    fontWeight: "bold",
    marginBottom: 4,
    color: "#111827",
  },
  subtitle: {
    fontSize: 10,
    color: "#6b7280",
    marginTop: 4,
  },
  table: {
    marginTop: 12,
    borderWidth: 1,
    borderColor: "#E5E7EB",
  },
  row: {
    flexDirection: "row",
    borderBottomWidth: 1,
    borderBottomColor: "#E5E7EB",
  },
  cellHeader: {
    padding: 8,
    backgroundColor: "#F3F4F6",
    borderRightWidth: 1,
    borderRightColor: "#E5E7EB",
    fontWeight: "bold",
    fontSize: 10,
  },
  cell: {
    padding: 8,
    borderRightWidth: 1,
    borderRightColor: "#E5E7EB",
    fontSize: 9,
  },
  wGuest: { width: "30%" },
  wStatus: { width: "18%" },
  wCompanions: { width: "12%" },
  wSeat: { width: "12%" },
  wType: { width: "14%" },
  wMenu: { width: "14%" },
  groupHeader: {
    backgroundColor: "#F9FAFB",
    padding: 8,
    marginTop: 12,
    marginBottom: 4,
    fontWeight: "bold",
    fontSize: 11,
    borderWidth: 1,
    borderColor: "#E5E7EB",
  },
});

const GuestListPDF = ({ guests = [], meta = {} }) => {
  const { userName = "", generatedAt = new Date() } = meta;
  const dateStr =
    typeof generatedAt === "string"
      ? generatedAt
      : new Date(generatedAt).toLocaleString();

  // Group guests by group
  const groupedGuests = guests.reduce((acc, guest) => {
    const groupName = guest.group || "Other";
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
        <View style={styles.header}>
          <Text style={styles.title}>Guest List</Text>
          <Text style={styles.subtitle}>
            {userName ? `User: ${userName} · ` : ""}
            Generated: {dateStr}
          </Text>
          <Text style={styles.subtitle}>
            Total: {guests.length} | Attending: {attendingCount} | Pending:{" "}
            {pendingCount} | Not Attending: {declinedCount} | Adults:{" "}
            {adultsCount} | Children: {childrenCount}
          </Text>
        </View>

        {Object.entries(groupedGuests).map(([groupName, groupGuests]) => (
          <View key={groupName}>
            <Text style={styles.groupHeader}>
              {groupName} ({groupGuests.length})
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
          <View style={{ marginTop: 20 }}>
            <Text style={{ fontSize: 12, color: "#6b7280" }}>
              No guests found
            </Text>
          </View>
        )}
      </Page>
    </Document>
  );
};

export default GuestListPDF;
