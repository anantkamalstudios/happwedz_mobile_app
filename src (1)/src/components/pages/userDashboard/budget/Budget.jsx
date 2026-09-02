import React, { useState } from "react";
import { FaEdit, FaTrash } from "react-icons/fa";
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import Swal from "sweetalert2";
import { FcOk } from "react-icons/fc";
import { MdCancel } from "react-icons/md";
import { FaBookOpenReader, FaCheck, FaMinus, FaPlus } from "react-icons/fa6";
import useBudget from "../../../../hooks/useBudget";

const Budget = () => {
  const {
    loading,
    error,
    estimated,
    categories,
    selectedCategoryId,
    totalSpent,
    totalFinalCost,
    remainingBudget,
    setSelectedCategoryId,
    addBudget,
    updateBudget,
    deleteBudget,
    isAuthenticated,
    estimatedTotal,
  } = useBudget();

  const COLORS = [
    "#0088FE",
    "#00C49F",
    "#FFBB28",
    "#FF8042",
    "#A28DFF",
    "#FF6B6B",
    "#4FD1C5",
    "#F687B3",
  ];

  const getPieChartData = () => {
    return categories.map((category) => ({
      name: category.name,
      value: category.amount,
    }));
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency: "INR",
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const toggleCategory = (categoryId) => {
    if (selectedCategoryId === categoryId) {
      setSelectedCategoryId(null);
    } else {
      setSelectedCategoryId(categoryId);
    }
  };

  // Mobile-friendly category click: toggle selection and scroll expense details into view
  const handleCategoryClick = (categoryId) => {
    if (selectedCategoryId === categoryId) {
      setSelectedCategoryId(null);
    } else {
      setSelectedCategoryId(categoryId);
    }

    // On small screens, scroll the expense details into view so user sees the details immediately
    try {
      if (typeof window !== "undefined" && window.innerWidth <= 768) {
        setTimeout(() => {
          const el = document.querySelector(".wb-expense-details");
          if (el && typeof el.scrollIntoView === "function") {
            el.scrollIntoView({ behavior: "smooth", block: "start" });
          }
        }, 120);
      }
    } catch (err) {
      // ignore
    }
  };

  const [newCategoryId, setNewCategoryId] = useState("");
  const [newSubcategoryId, setNewSubcategoryId] = useState("");
  const [newEstimated, setNewEstimated] = useState("");
  const [newFinal, setNewFinal] = useState("");
  const [newPaid, setNewPaid] = useState("");

  const handleAddExpense = async () => {
    if (!isAuthenticated) {
      Swal.fire("Sign in required", "Please log in to add expenses.", "info");
      return;
    }
    const catId = newCategoryId || selectedCategoryId;
    const vendorSubcategoryId = Number(newSubcategoryId);
    const estimatedBudget = Number(newEstimated || 0);
    const finalCost = Number(newFinal || 0);
    const paidAmount = Number(newPaid || 0);

    if (!catId || !vendorSubcategoryId || estimatedBudget <= 0) {
      Swal.fire(
        "Validation",
        "Please select Category, Subcategory and enter estimated budget.",
        "warning"
      );
      return;
    }

    const created = await addBudget({
      vendorTypeId: catId,
      vendorSubcategoryId,
      estimatedBudget,
      finalCost,
      paidAmount,
    });
    if (created) {
      setNewCategoryId("");
      setNewSubcategoryId("");
      setNewEstimated("");
      setNewFinal("");
      setNewPaid("");
    } else {
      Swal.fire("Error", "Failed to add expense. Please try again.", "error");
    }
  };

  const updateExpense = async (categoryId, expenseId, field, value) => {
    const category = categories.find((c) => c.id === categoryId);
    if (!category) return;
    const row = (category.budgets || []).find((r) => r.id === expenseId);
    if (!row) return;

    const next = {
      id: row.id,
      vendorTypeId: categoryId,
      vendorSubcategoryId: row.vendor_subcategory_id,
      estimated: field === "estimated" ? Number(value) : row.estimated,
      final: field === "final" ? Number(value) : row.final,
      paid: field === "paid" ? Number(value) : row.paid,
    };
    const ok = await updateBudget(next);
    if (!ok) {
      Swal.fire(
        "Error",
        "Failed to update expense. Please try again.",
        "error"
      );
    }
  };

  const deleteExpense = async (categoryId, expenseId) => {
    const ok = await deleteBudget({ id: expenseId, vendorTypeId: categoryId });
    if (!ok) Swal.fire("Error", "Failed to delete expense.", "error");
  };

  if (loading) {
    return <div className="container text-center py-5">Loading budget...</div>;
  }

  if (error) {
    return (
      <div className="container text-center py-5 text-danger">{error}</div>
    );
  }

  return (
    <div className="wb-container">
      <div className="wb-header">
        <h3 className="wb-title">Budget</h3>

        <div className="wb-budget-summary">
          <div className="wb-budget-card">
            <div className="wb-budget-label fs-14">ESTIMATED BUDGET</div>
            <div className="wb-budget-amount">
              {formatCurrency(estimatedTotal)}
            </div>
          </div>

          <div className="wb-budget-card">
            <div className="wb-budget-label">TOTAL SPENT (PAID)</div>
            <div className="wb-budget-amount">{formatCurrency(totalSpent)}</div>
          </div>

          <div className="wb-budget-card">
            <div className="wb-budget-label">REMAINING (TO BE PAID)</div>
            <div
              className={`wb-budget-amount ${
                remainingBudget < 0 ? "wb-over-budget" : ""
              }`}
            >
              {formatCurrency(remainingBudget)}
            </div>
          </div>

          <div className="wb-budget-card">
            <div className="wb-budget-label">FINAL COST (expenditure)</div>
            <div className="wb-budget-amount">
              {formatCurrency(totalFinalCost)}
            </div>
          </div>
        </div>
      </div>

      <div className="wb-categories-container">
        <div className="wb-categories-list" style={{ flex: "0 0 300px", maxWidth: "300px", width: "300px" }}>
          <h2 className="wb-section-title fs-16">Categories</h2>
          <button
            type="button"
            className="wb-category-header fs-14 btn btn-transparent w-100 text-start d-flex justify-content-between align-items-center mb-2"
            onClick={() => setSelectedCategoryId(null)}
            style={{
              fontWeight: "bold",
              backgroundColor: selectedCategoryId === null ? "#fce7f3" : "transparent",
              color: selectedCategoryId === null ? "#ed1173" : "inherit",
              borderRadius: "8px",
              padding: "10px 14px",
              whiteSpace: "nowrap",
            }}
          >
            <span>All Categories</span>
            <span className="ms-2">{formatCurrency(estimatedTotal)}</span>
          </button>
          {categories.map((category) => (
            <div key={category.id} className="wb-category-item fs-14">
              <button
                type="button"
                className="wb-category-header fs-14 btn btn-transparent w-100 text-start d-flex justify-content-between align-items-center"
                onClick={() => handleCategoryClick(category.id)}
                aria-pressed={selectedCategoryId === category.id}
                style={{ padding: "10px 14px" }}
              >
                <div className="wb-category-name fs-14 d-flex align-items-center gap-2" style={{ whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                  {selectedCategoryId === category.id ? (
                    <FaBookOpenReader className="wb-category-icon flex-shrink-0" />
                  ) : (
                    <FaMinus className="wb-category-icon flex-shrink-0" />
                  )}
                  <span className="text-truncate">{category.name}</span>
                </div>
                <div className="wb-category-amount fs-14 ms-2 flex-shrink-0">
                  {formatCurrency(category.amount)}
                </div>
              </button>
            </div>
          ))}
        </div>

        <div className="wb-expense-details p-3 border rounded shadow-sm bg-white table-responsive flex-grow-1">
          <div className="d-flex justify-content-between align-items-center mb-3 pb-2 border-bottom">
            <h3 className="fw-bold m-0 fs-20" style={{ color: "#ed1173" }}>
              {selectedCategoryId
                ? categories.find((c) => String(c.id) === String(selectedCategoryId))?.name
                : "All Categories"}
            </h3>
            <div className="fw-bold fs-15 text-muted">
              Total:{" "}
              <span style={{ color: "#ed1173" }}>
                {formatCurrency(
                  selectedCategoryId
                    ? categories.find((c) => String(c.id) === String(selectedCategoryId))?.amount || 0
                    : estimatedTotal
                )}
              </span>
            </div>
          </div>
          <table className="wb-expense-table w-100">
            <thead>
              <tr>
                <th style={{ width: "24%" }}>CATEGORY</th>
                <th style={{ width: "32%" }}>SUB CATEGORY</th>
                <th style={{ width: "12%" }}>ESTIMATED BUDGET</th>
                <th style={{ width: "12%" }}>FINAL COST (expenditure)</th>
                <th style={{ width: "12%" }}>PAID</th>
                <th style={{ width: "8%", textAlign: "center" }}>ACTIONS</th>
              </tr>
            </thead>
            <tbody>
              {categories
                .filter((c) => !selectedCategoryId || c.id === selectedCategoryId)
                .flatMap((cat) =>
                  (cat.budgets || []).map((expense) => ({
                    ...expense,
                    catId: cat.id,
                    catName: cat.name,
                  }))
                )
                .sort((a, b) => Number(a.id || 0) - Number(b.id || 0))
                .map((expense) => (
                  <tr key={expense.id}>
                    <td className="fw-bold" style={{ color: "#ed1173" }}>{expense.catName}</td>
                    <td>{expense.name}</td>
                    <td>
                      <div className="wb-currency-input">
                        <span>₹</span>
                        <input
                          type="number"
                          value={expense.estimated}
                          onChange={(e) =>
                            updateExpense(
                              expense.catId,
                              expense.id,
                              "estimated",
                              e.target.value
                            )
                          }
                          className="wb-input wb-table-input fs-14"
                          style={{ width: "85px", padding: "4px 8px" }}
                        />
                      </div>
                    </td>
                    <td>
                      <div className="wb-currency-input">
                        <span>₹</span>
                        <input
                          type="number"
                          value={expense.final}
                          onChange={(e) =>
                            updateExpense(
                              expense.catId,
                              expense.id,
                              "final",
                              e.target.value
                            )
                          }
                          className="wb-input wb-table-input"
                          style={{ width: "85px", padding: "4px 8px" }}
                        />
                      </div>
                    </td>
                    <td>
                      <div className="wb-currency-input">
                        <span>₹</span>
                        <input
                          type="number"
                          value={expense.paid}
                          onChange={(e) =>
                            updateExpense(
                              expense.catId,
                              expense.id,
                              "paid",
                              e.target.value
                            )
                          }
                          className="wb-input wb-table-input"
                          style={{ width: "85px", padding: "4px 8px" }}
                        />
                      </div>
                    </td>
                    <td style={{ textAlign: "center" }}>
                      <button
                        className="wb-delete-button"
                        onClick={() => deleteExpense(expense.catId, expense.id)}
                      >
                        <FaTrash />
                      </button>
                    </td>
                  </tr>
                ))}
              {/* Add New Expense Row */}
              <tr>
                <td>
                  {selectedCategoryId ? (
                    <span className="fw-bold" style={{ color: "#ed1173" }}>
                      {categories.find((c) => String(c.id) === String(selectedCategoryId))?.name}
                    </span>
                  ) : (
                    <select
                      className="form-select wb-input w-100"
                      style={{ fontSize: "12px", padding: "5px 6px" }}
                      value={newCategoryId}
                      onChange={(e) => {
                        setNewCategoryId(e.target.value);
                        setNewSubcategoryId("");
                      }}
                    >
                      <option value="">Select Category</option>
                      {categories.map((c) => (
                        <option key={c.id} value={c.id}>
                          {c.name}
                        </option>
                      ))}
                    </select>
                  )}
                </td>
                <td>
                  <select
                    className="form-select wb-input w-100"
                    style={{ fontSize: "12px", padding: "5px 6px" }}
                    value={newSubcategoryId}
                    onChange={(e) => setNewSubcategoryId(e.target.value)}
                  >
                    <option value="">Select Subcategory</option>
                    {(
                      categories.find(
                        (c) =>
                          String(c.id) ===
                          String(selectedCategoryId || newCategoryId)
                      )?.subcategories || []
                    ).map((sub) => (
                      <option key={sub.id} value={sub.id}>
                        {sub.name}
                      </option>
                    ))}
                  </select>
                </td>
                <td>
                  <div className="wb-currency-input">
                    <span>₹</span>
                    <input
                      type="number"
                      value={newEstimated}
                      onChange={(e) => setNewEstimated(e.target.value)}
                      className="wb-input wb-table-input"
                      placeholder="0"
                      style={{ width: "85px", padding: "4px 8px" }}
                    />
                  </div>
                </td>
                <td>
                  <div className="wb-currency-input">
                    <span>₹</span>
                    <input
                      type="number"
                      value={newFinal}
                      onChange={(e) => setNewFinal(e.target.value)}
                      className="wb-input wb-table-input"
                      placeholder="0"
                      style={{ width: "85px", padding: "4px 8px" }}
                    />
                  </div>
                </td>
                <td>
                  <div className="wb-currency-input">
                    <span>₹</span>
                    <input
                      type="number"
                      value={newPaid}
                      onChange={(e) => setNewPaid(e.target.value)}
                      className="wb-input wb-table-input"
                      placeholder="0"
                      style={{ width: "85px", padding: "4px 8px" }}
                    />
                  </div>
                </td>
                <td>
                  <button
                    className="wb-button wb-add-button"
                    onClick={handleAddExpense}
                  >
                    <FaPlus />
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
export default Budget;
