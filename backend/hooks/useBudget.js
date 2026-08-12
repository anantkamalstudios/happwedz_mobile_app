import { useEffect, useMemo, useState, useCallback } from "react";
import { useSelector } from "react-redux";

const apiFetch = async (url, options = {}, token) => {
  const headers = {
    "Content-Type": "application/json",
    ...(options.headers || {}),
  };
  if (token) headers.Authorization = `Bearer ${token}`;
  const response = await fetch(url, { ...options, headers });
  return response;
};

export function useBudget() {
  const { user, token } = useSelector((state) => state.auth);

  const [estimated, setEstimated] = useState(0);
  const [categories, setCategories] = useState([]);
  const [selectedCategoryId, setSelectedCategoryId] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [subcategoryNameById, setSubcategoryNameById] = useState({});

  useEffect(() => {
    let isMounted = true;
    const loadVendorTypes = async () => {
      try {
        const response = await fetch(
          "https://happywedz.com/api/vendor-types/with-subcategories/all"
        );
        const data = await response.json();

        if (!isMounted) return;

        const subcatMap = {};
        const initialCategories = (data || []).map((cat) => ({
          id: cat.id,
          name: cat.name,
          amount: 0,
          subcategories: (cat.subcategories || []).map((sub) => {
            subcatMap[sub.id] = sub.name;
            return {
              id: sub.id,
              name: sub.name,
            };
          }),

          budgets: [],
        }));

        setSubcategoryNameById(subcatMap);
        setCategories(initialCategories);
        setError(null);
      } catch (err) {
        console.error("Error loading vendor types:", err);
        setError("Could not load vendor categories. Please try again later.");
      } finally {
        if (isMounted) setLoading(false);
      }
    };

    loadVendorTypes();
    return () => {
      isMounted = false;
    };
  }, []);

  useEffect(() => {
    if (!user?.id || categories.length === 0) return;

    let isMounted = true;
    const loadUserBudgets = async () => {
      try {
        const response = await apiFetch(
          `https://happywedz.com/api/budgets/user/${user.id}`,
          {},
          token
        );

        if (response.status === 404) {
          if (!isMounted) return;
          setError(null);
          setCategories((prev) =>
            prev.map((c) => ({ ...c, budgets: [], amount: 0 }))
          );
          return;
        }

        const result = await response.json();
        if (!isMounted) return;

        if (result?.success) {
          const items = Array.isArray(result.data) ? result.data : [];

          const grouped = categories.map((category) => {
            const budgetsForCategory = items.filter(
              (b) => b.vendor_type_id === category.id
            );
            const mappedRows = budgetsForCategory.map((b) => ({
              id: b.id,
              vendor_type_id: b.vendor_type_id,
              vendor_subcategory_id: b.vendor_subcategory_id,
              name: subcategoryNameById[b.vendor_subcategory_id] || "Expense",
              estimated: Number(b.estimated_budget || 0),
              final: Number(b.final_cost || 0),
              paid: Number(b.paid_amount || 0),
            }));

            const newAmount = mappedRows.reduce(
              (sum, row) => sum + Number(row.estimated || 0),
              0
            );

            return {
              ...category,
              budgets: mappedRows,
              amount: newAmount,
            };
          });

          setCategories(grouped);
          setError(null);
        } else {
          if (
            typeof result?.message === "string" &&
            result.message.toLowerCase().includes("no budgets found")
          ) {
            setError(null);
            setCategories((prev) =>
              prev.map((c) => ({ ...c, budgets: [], amount: 0 }))
            );
          } else {
            setError(
              "Could not load your saved budget. Please try again later."
            );
          }
        }
      } catch (err) {
        console.error("Error loading user budgets:", err);
        setError("Could not load your saved budget. Please try again later.");
      }
    };

    loadUserBudgets();
  }, [user?.id, token, categories.length]);

  const { totalSpent, totalFinalCost, remainingBudget, estimatedTotal } =
    useMemo(() => {
      const spent = categories.reduce(
        (total, cat) =>
          total +
          (cat.budgets || []).reduce((s, r) => s + Number(r.paid || 0), 0),
        0
      );
      const finalCost = categories.reduce(
        (total, cat) =>
          total +
          (cat.budgets || []).reduce((s, r) => s + Number(r.final || 0), 0),
        0
      );
      const estimatedSum = categories.reduce(
        (total, cat) =>
          total +
          (cat.budgets || []).reduce((s, r) => s + Number(r.estimated || 0), 0),
        0
      );
      const remaining = estimatedSum - spent;
      return {
        totalSpent: spent,
        totalFinalCost: finalCost,
        remainingBudget: remaining,
        estimatedTotal: estimatedSum,
      };
    }, [categories]);

  const addBudget = useCallback(
    async ({
      vendorTypeId,
      vendorSubcategoryId,
      estimatedBudget,
      finalCost = 0,
      paidAmount = 0,
    }) => {
      if (!user?.id) return null;

      const payload = {
        userId: user.id,
        vendor_type_id: vendorTypeId,
        vendor_subcategory_id: vendorSubcategoryId,
        estimated_budget: Number(estimatedBudget || 0),
        final_cost: Number(finalCost || 0),
        paid_amount: Number(paidAmount || 0),
      };

      const response = await apiFetch(
        `https://happywedz.com/api/budgets/`,
        {
          method: "POST",
          body: JSON.stringify(payload),
        },
        token
      );
      const result = await response.json();

      if (result?.success && result?.data) {
        const newRow = result.data;
        const name =
          subcategoryNameById[newRow.vendor_subcategory_id] || "Expense";

        setCategories((prev) =>
          prev.map((cat) => {
            if (cat.id !== vendorTypeId) return cat;
            const row = {
              id: newRow.id,
              vendor_type_id: newRow.vendor_type_id,
              vendor_subcategory_id: newRow.vendor_subcategory_id,
              name,
              estimated: Number(newRow.estimated_budget || 0),
              final: Number(newRow.final_cost || 0),
              paid: Number(newRow.paid_amount || 0),
            };
            const amount = (cat.amount || 0) + row.estimated;
            return { ...cat, budgets: [...(cat.budgets || []), row], amount };
          })
        );
        return newRow;
      }
      return null;
    },
    [token, user?.id, subcategoryNameById]
  );

  const updateBudget = useCallback(
    async ({
      id,
      vendorTypeId,
      vendorSubcategoryId,
      estimated,
      final,
      paid,
    }) => {
      if (!id) return false;
      const payload = {
        userId: user?.id,
        vendor_type_id: vendorTypeId,
        vendor_subcategory_id: vendorSubcategoryId,
        estimated_budget: Number(estimated || 0),
        final_cost: Number(final || 0),
        paid_amount: Number(paid || 0),
      };

      const response = await apiFetch(
        `https://happywedz.com/api/budgets/${id}`,
        { method: "PUT", body: JSON.stringify(payload) },
        token
      );
      if (!response.ok) return false;
      const result = await response.json();
      if (!result?.success) return false;

      setCategories((prev) =>
        prev.map((cat) => {
          if (cat.id !== vendorTypeId) return cat;
          const updatedBudgets = (cat.budgets || []).map((row) => {
            if (row.id !== id) return row;
            const updated = {
              ...row,
              estimated: Number(estimated || 0),
              final: Number(final || 0),
              paid: Number(paid || 0),
            };
            return updated;
          });
          const newAmount = updatedBudgets.reduce(
            (sum, r) => sum + Number(r.estimated || 0),
            0
          );
          return { ...cat, budgets: updatedBudgets, amount: newAmount };
        })
      );
      return true;
    },
    [token, user?.id]
  );

  const deleteBudget = useCallback(
    async ({ id, vendorTypeId }) => {
      if (!id) return false;
      const response = await apiFetch(
        `https://happywedz.com/api/budgets/${id}`,
        { method: "DELETE" },
        token
      );
      if (!response.ok) return false;

      setCategories((prev) =>
        prev.map((cat) => {
          if (cat.id !== vendorTypeId) return cat;
          const existing = cat.budgets || [];
          const row = existing.find((r) => r.id === id);
          const filtered = existing.filter((r) => r.id !== id);
          const newAmount = (cat.amount || 0) - Number(row?.estimated || 0);
          return { ...cat, budgets: filtered, amount: Math.max(0, newAmount) };
        })
      );
      return true;
    },
    [token]
  );

  return {
    loading,
    error,
    estimated,
    categories,
    selectedCategoryId,
    subcategoryNameById,
    isAuthenticated: Boolean(token && user?.id),

    totalSpent,
    totalFinalCost,
    remainingBudget,
    estimatedTotal,

    setEstimated,
    setSelectedCategoryId,

    addBudget,
    updateBudget,
    deleteBudget,
  };
}

export default useBudget;
