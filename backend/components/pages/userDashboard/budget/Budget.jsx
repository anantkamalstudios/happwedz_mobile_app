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

  const [newSubcategoryId, setNewSubcategoryId] = useState("");
  const [newEstimated, setNewEstimated] = useState("");
  const [newFinal, setNewFinal] = useState("");
  const [newPaid, setNewPaid] = useState("");

  const handleAddExpense = async () => {
    if (!isAuthenticated) {
      Swal.fire("Sign in required", "Please log in to add expenses.", "info");
      return;
    }
    const vendorTypeId = selectedCategoryId;
    const vendorSubcategoryId = Number(newSubcategoryId);
    const estimatedBudget = Number(newEstimated || 0);
    const finalCost = Number(newFinal || 0);
    const paidAmount = Number(newPaid || 0);

    if (!vendorTypeId || !vendorSubcategoryId || estimatedBudget <= 0) {
      Swal.fire(
        "Validation",
        "Select subcategory and enter estimated amount.",
        "warning"
      );
      return;
    }

    const created = await addBudget({
      vendorTypeId,
      vendorSubcategoryId,
      estimatedBudget,
      finalCost,
      paidAmount,
    });
    if (created) {
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
            <div className="wb-budget-label">TOTAL SPENT</div>
            <div className="wb-budget-amount">{formatCurrency(totalSpent)}</div>
          </div>

          <div className="wb-budget-card">
            <div className="wb-budget-label">REMAINING</div>
            <div
              className={`wb-budget-amount ${
                remainingBudget < 0 ? "wb-over-budget" : ""
              }`}
            >
              {formatCurrency(remainingBudget)}
            </div>
          </div>

          <div className="wb-budget-card">
            <div className="wb-budget-label">FINAL COST</div>
            <div className="wb-budget-amount">
              {formatCurrency(totalFinalCost)}
            </div>
          </div>
        </div>
      </div>

      <div className="wb-categories-container">
        <div className="wb-categories-list">
          <h2 className="wb-section-title fs-16">Categories</h2>
          {categories.map((category) => (
            <div key={category.id} className="wb-category-item fs-14">
              <button
                type="button"
                className="wb-category-header fs-14 btn btn-transparent w-100 text-start d-flex justify-content-between align-items-center"
                onClick={() => handleCategoryClick(category.id)}
                aria-pressed={selectedCategoryId === category.id}
              >
                <div className="wb-category-name fs-14 d-flex align-items-center gap-2">
                  {selectedCategoryId === category.id ? (
                    <FaBookOpenReader className="wb-category-icon" />
                  ) : (
                    <FaMinus className="wb-category-icon" />
                  )}
                  <span>{category.name}</span>
                </div>
                <div className="wb-category-amount fs-14">
                  {formatCurrency(category.amount)}
                </div>
              </button>
            </div>
          ))}
        </div>

        <div className="wb-expense-details">
          {selectedCategoryId ? (
            <>
              <div className="wb-category-summary align-content-center">
                <p className="wb-category-title m-0 fs-16 text-center align-content-center">
                  {categories.find((c) => c.id === selectedCategoryId)?.name}
                </p>
                <div className="wb-category-total">
                  {formatCurrency(
                    categories.find((c) => c.id === selectedCategoryId)?.amount
                  )}
                </div>
              </div>

              <table className="wb-expense-table">
                <thead>
                  <tr>
                    <th>EXPENSE</th>
                    <th>ESTIMATED BUDGET</th>
                    <th>FINAL COST</th>
                    <th>PAID</th>
                    <th>ACTIONS</th>
                  </tr>
                </thead>
                <tbody>
                  {categories
                    .find((c) => c.id === selectedCategoryId)
                    ?.budgets.map((expense) => (
                      <tr key={expense.id}>
                        <td>{expense.name}</td>
                        <td>
                          <div className="wb-currency-input">
                            <span>₹</span>
                            <input
                              type="number"
                              value={expense.estimated}
                              onChange={(e) =>
                                updateExpense(
                                  selectedCategoryId,
                                  expense.id,
                                  "estimated",
                                  e.target.value
                                )
                              }
                              className="wb-input wb-table-input fs-14"
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
                                  selectedCategoryId,
                                  expense.id,
                                  "final",
                                  e.target.value
                                )
                              }
                              className="wb-input wb-table-input"
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
                                  selectedCategoryId,
                                  expense.id,
                                  "paid",
                                  e.target.value
                                )
                              }
                              className="wb-input wb-table-input"
                            />
                          </div>
                        </td>
                        <td>
                          <button
                            className="wb-delete-button"
                            onClick={() =>
                              deleteExpense(selectedCategoryId, expense.id)
                            }
                          >
                            <FaTrash />
                          </button>
                        </td>
                      </tr>
                    ))}
                  {/* Add new expense row */}
                  <tr>
                    <td>
                      <select
                        className="form-select wb-input"
                        value={newSubcategoryId}
                        onChange={(e) => setNewSubcategoryId(e.target.value)}
                      >
                        <option value="">Select subcategory</option>
                        {categories
                          .find((c) => c.id === selectedCategoryId)
                          ?.subcategories?.map((sub) => (
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
            </>
          ) : (
            <>
              <h2 className="wb-section-title fs-16">Expense Details</h2>
              <div className="wb-pie-chart-container">
                {/* <div className="wb-pie-chart-message">
                  Select a category to view expense details
                </div> */}
                <div className="wb-pie-chart-wrapper">
                  <ResponsiveContainer width="100%" height={400}>
                    <PieChart>
                      <Pie
                        data={getPieChartData()}
                        cx="50%"
                        cy="50%"
                        outerRadius={120}
                        fill="#8884d8"
                        dataKey="value"
                        label={false}
                      >
                        {categories.map((entry, index) => (
                          <Cell
                            key={`cell-${index}`}
                            fill={COLORS[index % COLORS.length]}
                          />
                        ))}
                      </Pie>
                      <Tooltip
                        formatter={(value, name) => [
                          formatCurrency(value),
                          name,
                        ]}
                        contentStyle={{
                          backgroundColor: "#fff",
                          border: "1px solid #ffcdd2",
                          borderRadius: "8px",
                          padding: "10px",
                        }}
                      />
                      <Legend
                        wrapperStyle={{
                          paddingTop: "20px",
                          fontSize: "14px",
                        }}
                        formatter={(value) => value}
                      />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
};
export default Budget;
