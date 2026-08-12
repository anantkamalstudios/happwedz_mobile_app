import React from "react";
import { Document, Page, Text, View, StyleSheet } from "@react-pdf/renderer";

// const styles = StyleSheet.create({
//   page: { padding: 24, fontSize: 11, color: "#111827" },
//   header: { marginBottom: 12 },
//   title: { fontSize: 16, fontWeight: "bold", marginBottom: 4 },
//   subtitle: { fontSize: 10, color: "#6b7280" },
//   table: { marginTop: 12, borderWidth: 1, borderColor: "#E5E7EB" },
//   row: { flexDirection: "row" },
//   cellHeader: {
//     padding: 6,
//     backgroundColor: "#F3F4F6",
//     borderRightWidth: 1,
//     borderRightColor: "#E5E7EB",
//     fontWeight: "bold",
//   },
//   cell: {
//     padding: 6,
//     borderTopWidth: 1,
//     borderTopColor: "#E5E7EB",
//     borderRightWidth: 1,
//     borderRightColor: "#E5E7EB",
//   },
//   wStatus: { width: "12%" },
//   wTask: { width: "46%" },
//   wCategory: { width: "22%" },
//   wDays: { width: "20%" },
//   taskCompleted: { textDecoration: "line-through", color: "#9ca3af" },
//   taskActive: { fontWeight: "600", color: "#374151" },
//   categoryRow: { flexDirection: "row", alignItems: "center", gap: 4 },
//   badge: {
//     fontSize: 9,
//     color: "#6b7280",
//     marginLeft: 6,
//   },
// });

const styles = StyleSheet.create({
  page: {
    padding: 32,
    fontSize: 10,
    color: "#1f2937",
    fontFamily: "Helvetica",
  },
  header: {
    marginBottom: 20,
    paddingBottom: 16,
    borderBottomWidth: 2,
    borderBottomColor: "#d1d5db",
  },
  title: {
    fontSize: 24,
    fontWeight: "bold",
    marginBottom: 6,
    color: "#111827",
    letterSpacing: 0.5,
  },
  subtitle: { fontSize: 10, color: "#6b7280", fontFamily: "Helvetica" },
  table: {
    marginTop: 16,
    borderWidth: 1,
    borderColor: "#d1d5db",
    borderRadius: 4,
  },
  row: {
    flexDirection: "row",
    borderBottomWidth: 1,
    borderBottomColor: "#e5e7eb",
  },
  lastRow: { borderBottomWidth: 0 },
  cellHeader: {
    padding: 8,
    backgroundColor: "#f9fafb",
    borderRightWidth: 1,
    borderRightColor: "#d1d5db",
    fontWeight: "bold",
    fontSize: 9,
    textTransform: "uppercase",
    letterSpacing: 0.5,
    color: "#374151",
  },
  cell: {
    padding: 8,
    borderRightWidth: 1,
    borderRightColor: "#e5e7eb",
    fontSize: 10,
  },
  wStatus: { width: "15%" },
  wTask: { width: "40%" },
  wCategory: { width: "25%" },
  wDays: { width: "20%" },
  statusBadge: {
    paddingHorizontal: 6,
    paddingVertical: 3,
    borderRadius: 3,
    fontSize: 8,
    fontWeight: "bold",
    textTransform: "uppercase",
  },
  statusCompleted: {
    backgroundColor: "#d1fae5",
    color: "#065f46",
  },
  statusPending: {
    backgroundColor: "#fef3c7",
    color: "#92400e",
  },
  taskCompleted: { textDecoration: "line-through", color: "#9ca3af" },
  taskActive: { color: "#111827" },
  categoryRow: { flexDirection: "row", alignItems: "center" },
  footer: {
    position: "absolute",
    bottom: 20,
    left: 32,
    right: 32,
    textAlign: "center",
    color: "#9ca3af",
    fontSize: 8,
    borderTopWidth: 1,
    borderTopColor: "#e5e7eb",
    paddingTop: 8,
  },
});

const getCategoryMeta = (categories, vendor_subcategory_id) => {
  const sub = categories.find((c) => c.id === vendor_subcategory_id);
  if (!sub) return { name: "N/A", required_days: null };
  return { name: sub.name, required_days: sub.required_days ?? null };
};

const ChecklistPDF = ({ items = [], categories = [], meta = {} }) => {
  const safeItems = Array.isArray(items)
    ? items.filter((item) => item && typeof item === "object")
    : [];

  const { userName = "", generatedAt = new Date() } = meta;
  const dateStr =
    typeof generatedAt === "string"
      ? generatedAt
      : new Date(generatedAt).toLocaleString();

  return (
    <Document>
      <Page size="A4" style={styles.page}>
        <View style={styles.header}>
          <Text style={styles.title}>Wedding Checklist</Text>
          <Text style={styles.subtitle}>
            {userName ? `User: ${userName} · ` : ""}
            Generated: {dateStr}
          </Text>
        </View>

        {safeItems.length > 0 && (
          <View style={styles.table}>
            <View style={[styles.row]}>
              <Text style={[styles.cellHeader, styles.wStatus]}>Status</Text>
              <Text style={[styles.cellHeader, styles.wTask]}>Task</Text>
              <Text style={[styles.cellHeader, styles.wCategory]}>
                Category
              </Text>
              <Text style={[styles.cellHeader, styles.wDays]}>
                Days Assigned
              </Text>
            </View>

            {safeItems.map((item, index) => (
              <View
                key={item.id || `item-${index}`}
                style={[
                  styles.row,
                  index === safeItems.length - 1 ? styles.lastRow : null,
                ]}
              >
                <Text style={[styles.cell, styles.wStatus]}>
                  {item.status === "completed" ? "Completed" : "Pending"}
                </Text>
                <Text
                  style={[
                    styles.cell,
                    styles.wTask,
                    item.status === "completed"
                      ? styles.taskCompleted
                      : styles.taskActive,
                  ]}
                >
                  {String(item.text || "")}
                </Text>
                <View
                  style={[styles.cell, styles.wCategory, styles.categoryRow]}
                >
                  <Text>
                    {
                      getCategoryMeta(
                        Array.isArray(categories) ? categories : [],
                        item.vendor_subcategory_id
                      ).name
                    }
                  </Text>
                </View>
                <Text style={[styles.cell, styles.wDays]}>
                  {item.days_assigned !== null &&
                  item.days_assigned !== undefined &&
                  typeof item.days_assigned === "number"
                    ? `${item.days_assigned} days`
                    : "N/A"}
                </Text>
              </View>
            ))}
          </View>
        )}
      </Page>
    </Document>
  );
};

export default ChecklistPDF;
