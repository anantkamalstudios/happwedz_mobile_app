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
  table: {
    marginTop: 4,
    borderWidth: 1,
    borderColor: "#E2E8F0",
    borderRadius: 3,
  },
  row: {
    flexDirection: "row",
    borderBottomWidth: 1,
    borderBottomColor: "#F1F5F9",
    alignItems: "center",
  },
  lastRow: {
    borderBottomWidth: 0,
  },
  cellHeader: {
    paddingVertical: 6,
    paddingHorizontal: 8,
    backgroundColor: "#F8FAFC",
    borderRightWidth: 1,
    borderRightColor: "#E2E8F0",
    fontWeight: "bold",
    fontSize: 8.5,
    color: "#334155",
    textTransform: "uppercase",
    letterSpacing: 0.3,
  },
  cell: {
    paddingVertical: 6,
    paddingHorizontal: 8,
    borderRightWidth: 1,
    borderRightColor: "#F1F5F9",
    fontSize: 8.5,
    color: "#1e293b",
  },
  wStatus: { width: "16%" },
  wTask: { width: "42%" },
  wCategory: { width: "24%" },
  wDays: { width: "18%" },
  statusCompleted: {
    color: "#059669",
    fontWeight: "bold",
  },
  statusPending: {
    color: "#D97706",
    fontWeight: "bold",
  },
  taskCompleted: {
    textDecoration: "line-through",
    color: "#94A3B8",
  },
  taskActive: {
    color: "#0F172A",
  },
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
      : formatDateTime(generatedAt);

  const completedCount = safeItems.filter((i) => i.status === "completed").length;
  const pendingCount = safeItems.length - completedCount;

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
            <Text style={styles.reportTitle}>Wedding Checklist</Text>
            {userName ? (
              <Text style={styles.reportMetaText}>Planner: {userName}</Text>
            ) : null}
            <Text style={styles.reportMetaText}>Generated: {dateStr}</Text>
          </View>
        </View>

        {/* Summary Metrics Bar */}
        <View style={styles.summaryBar}>
          <Text style={styles.summaryText}>Total Tasks: {safeItems.length}</Text>
          <Text style={styles.summaryItem}>Completed: {completedCount}</Text>
          <Text style={styles.summaryItem}>Pending: {pendingCount}</Text>
          <Text style={styles.summaryItem}>
            Progress: {safeItems.length > 0 ? Math.round((completedCount / safeItems.length) * 100) : 0}%
          </Text>
        </View>

        {/* Tasks Table */}
        {safeItems.length > 0 ? (
          <View style={styles.table}>
            <View style={styles.row}>
              <Text style={[styles.cellHeader, styles.wStatus]}>Status</Text>
              <Text style={[styles.cellHeader, styles.wTask]}>Task</Text>
              <Text style={[styles.cellHeader, styles.wCategory]}>Category</Text>
              <Text style={[styles.cellHeader, styles.wDays]}>Days Assigned</Text>
            </View>

            {safeItems.map((item, index) => {
              const isCompleted = item.status === "completed";
              return (
                <View
                  key={item.id || `item-${index}`}
                  style={[
                    styles.row,
                    index === safeItems.length - 1 ? styles.lastRow : null,
                  ]}
                  wrap={false}
                >
                  <Text
                    style={[
                      styles.cell,
                      styles.wStatus,
                      isCompleted ? styles.statusCompleted : styles.statusPending,
                    ]}
                  >
                    {isCompleted ? "Completed" : "Pending"}
                  </Text>
                  <Text
                    style={[
                      styles.cell,
                      styles.wTask,
                      isCompleted ? styles.taskCompleted : styles.taskActive,
                    ]}
                  >
                    {String(item.text || "")}
                  </Text>
                  <Text style={[styles.cell, styles.wCategory]}>
                    {
                      getCategoryMeta(
                        Array.isArray(categories) ? categories : [],
                        item.vendor_subcategory_id
                      ).name
                    }
                  </Text>
                  <Text style={[styles.cell, styles.wDays]}>
                    {item.days_assigned !== null &&
                    item.days_assigned !== undefined &&
                    typeof item.days_assigned === "number"
                      ? `${item.days_assigned} days`
                      : "N/A"}
                  </Text>
                </View>
              );
            })}
          </View>
        ) : (
          <View style={{ marginTop: 20, padding: 15, textAlign: "center" }}>
            <Text style={{ fontSize: 11, color: "#6b7280" }}>
              No tasks found in this wedding checklist.
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

export default ChecklistPDF;
