import React, { useMemo } from "react";

const VendorMenus = ({ formData, setFormData, onSave, onShowSuccess }) => {
  // Extract existing menus or initialize
  const existingMenus = useMemo(() => {
    return Array.isArray(formData.attributes?.menus)
      ? formData.attributes.menus
      : [];
  }, [formData.attributes?.menus]);

  // Veg data
  const vegMenu = useMemo(() => {
    return existingMenus.find((m) => m.type === "veg") || existingMenus[0] || {};
  }, [existingMenus]);

  // Non-Veg data
  const nonVegMenu = useMemo(() => {
    return (
      existingMenus.find((m) => m.type === "non-veg") ||
      (existingMenus.length > 1 ? existingMenus[1] : {})
    );
  }, [existingMenus]);

  const vegPrice = formData.veg_price ?? formData.attributes?.veg_price ?? vegMenu.price ?? "";
  const nonVegPrice = formData.non_veg_price ?? formData.attributes?.non_veg_price ?? nonVegMenu.price ?? "";

  const vegDescription =
    formData.veg_description ??
    formData.attributes?.veg_description ??
    vegMenu.description ??
    formData.menu_description ??
    formData.attributes?.menu_description ??
    "";

  const nonVegDescription =
    formData.non_veg_description ??
    formData.attributes?.non_veg_description ??
    nonVegMenu.description ??
    "";

  const vegItems = Array.isArray(vegMenu.items) && vegMenu.items.length > 0 ? vegMenu.items : [""];
  const nonVegItems = Array.isArray(nonVegMenu.items) && nonVegMenu.items.length > 0 ? nonVegMenu.items : [""];

  // Helper to update Veg and Non-Veg states into formData
  const updateMenusState = (vegUpdates = {}, nonVegUpdates = {}) => {
    setFormData((prev) => {
      const prevExisting = Array.isArray(prev.attributes?.menus) ? prev.attributes.menus : [];
      const currentVeg = prevExisting.find((m) => m.type === "veg") || prevExisting[0] || {};
      const currentNonVeg =
        prevExisting.find((m) => m.type === "non-veg") ||
        (prevExisting.length > 1 ? prevExisting[1] : {});

      const updatedVeg = {
        title: "Veg Menu",
        type: "veg",
        price: vegUpdates.price !== undefined ? vegUpdates.price : (prev.veg_price ?? currentVeg.price ?? ""),
        description:
          vegUpdates.description !== undefined
            ? vegUpdates.description
            : (prev.veg_description ?? currentVeg.description ?? prev.menu_description ?? ""),
        items: vegUpdates.items !== undefined ? vegUpdates.items : (currentVeg.items || [""]),
      };

      const updatedNonVeg = {
        title: "Non-Veg Menu",
        type: "non-veg",
        price:
          nonVegUpdates.price !== undefined ? nonVegUpdates.price : (prev.non_veg_price ?? currentNonVeg.price ?? ""),
        description:
          nonVegUpdates.description !== undefined
            ? nonVegUpdates.description
            : (prev.non_veg_description ?? currentNonVeg.description ?? ""),
        items: nonVegUpdates.items !== undefined ? nonVegUpdates.items : (currentNonVeg.items || [""]),
      };

      const nextVegPrice = updatedVeg.price;
      const nextNonVegPrice = updatedNonVeg.price;
      const nextVegDesc = updatedVeg.description;
      const nextNonVegDesc = updatedNonVeg.description;

      return {
        ...prev,
        veg_price: nextVegPrice,
        non_veg_price: nextNonVegPrice,
        veg_description: nextVegDesc,
        non_veg_description: nextNonVegDesc,
        menu_description: nextVegDesc || nextNonVegDesc || "",
        attributes: {
          ...prev.attributes,
          veg_price: nextVegPrice,
          non_veg_price: nextNonVegPrice,
          veg_description: nextVegDesc,
          non_veg_description: nextNonVegDesc,
          menu_description: nextVegDesc || nextNonVegDesc || "",
          menus: [updatedVeg, updatedNonVeg],
        },
      };
    });
  };

  // Veg field handlers
  const handleVegPriceChange = (val) => updateMenusState({ price: val });
  const handleVegDescChange = (val) => updateMenusState({ description: val });

  const handleVegItemChange = (idx, val) => {
    const nextItems = (vegItems || [""]).map((it, j) => (j === idx ? val : it));
    updateMenusState({ items: nextItems });
  };

  const addVegItem = () => {
    const nextItems = [...(vegItems || []), ""];
    updateMenusState({ items: nextItems });
  };

  const removeVegItem = (idx) => {
    const nextItems = (vegItems || [""]).filter((_, j) => j !== idx);
    updateMenusState({ items: nextItems.length > 0 ? nextItems : [""] });
  };

  // Non-Veg field handlers
  const handleNonVegPriceChange = (val) => updateMenusState({}, { price: val });
  const handleNonVegDescChange = (val) => updateMenusState({}, { description: val });

  const handleNonVegItemChange = (idx, val) => {
    const nextItems = (nonVegItems || [""]).map((it, j) => (j === idx ? val : it));
    updateMenusState({}, { items: nextItems });
  };

  const addNonVegItem = () => {
    const nextItems = [...(nonVegItems || []), ""];
    updateMenusState({}, { items: nextItems });
  };

  const removeNonVegItem = (idx) => {
    const nextItems = (nonVegItems || [""]).filter((_, j) => j !== idx);
    updateMenusState({}, { items: nextItems.length > 0 ? nextItems : [""] });
  };

  const handleSaveMenus = () => {
    setFormData((prev) => {
      const vPrice = prev.veg_price ?? vegPrice ?? "";
      const nvPrice = prev.non_veg_price ?? nonVegPrice ?? "";
      const vDesc = prev.veg_description ?? vegDescription ?? "";
      const nvDesc = prev.non_veg_description ?? nonVegDescription ?? "";

      const cleanedMenus = [
        {
          title: "Veg Menu",
          type: "veg",
          price: vPrice,
          description: vDesc,
          items: vegItems.filter((it) => typeof it === "string" && it.trim() !== ""),
        },
        {
          title: "Non-Veg Menu",
          type: "non-veg",
          price: nvPrice,
          description: nvDesc,
          items: nonVegItems.filter((it) => typeof it === "string" && it.trim() !== ""),
        },
      ];

      return {
        ...prev,
        veg_price: vPrice,
        non_veg_price: nvPrice,
        veg_description: vDesc,
        non_veg_description: nvDesc,
        menu_description: vDesc || nvDesc || "",
        attributes: {
          ...prev.attributes,
          veg_price: vPrice,
          non_veg_price: nvPrice,
          veg_description: vDesc,
          non_veg_description: nvDesc,
          menu_description: vDesc || nvDesc || "",
          menus: cleanedMenus,
        },
      };
    });

    if (onSave) onSave();
    if (onShowSuccess) onShowSuccess();
  };

  return (
    <div className="my-5">
      <div className="p-3 border rounded bg-white">
        <h4 className="mb-4 fw-bold">Menus (for Caterers)</h4>

        {/* Veg Menu Card */}
        <div className="border rounded p-3 mb-4 bg-light">
          <div className="d-flex align-items-center gap-2 mb-3">
            <span className="badge bg-success fs-13 px-2 py-1">Veg</span>
            <h5 className="fw-bold mb-0 text-success">Veg Menu</h5>
          </div>

          <div className="row">
            {/* Veg Price */}
            <div className="col-md-6 mb-3">
              <label className="form-label fs-14 fw-semibold">
                Veg Price Per Plate (for Venues)
              </label>
              <input
                type="text"
                className="form-control fs-14"
                value={vegPrice}
                onChange={(e) => handleVegPriceChange(e.target.value)}
                placeholder="e.g. 565"
              />
            </div>

            {/* Veg Description */}
            <div className="col-12 mb-3">
              <label className="form-label fs-14 fw-semibold">
                Veg Menu Description
              </label>
              <textarea
                className="form-control fs-14"
                rows={3}
                value={vegDescription}
                onChange={(e) => handleVegDescChange(e.target.value)}
                placeholder="Enter description for vegetarian menu, cuisine offerings, specialties, courses included..."
              />
            </div>
          </div>

          {/* Veg Items */}
          <div className="mb-2 fw-semibold fs-14">Veg Menu Items</div>
          {vegItems.map((it, itemIdx) => (
            <div className="row mb-2" key={itemIdx}>
              <div className="col-md-10 col-9">
                <input
                  type="text"
                  className="form-control fs-14"
                  value={it}
                  onChange={(e) => handleVegItemChange(itemIdx, e.target.value)}
                  placeholder="e.g., Paneer Butter Masala, Dal Makhani, Gulab Jamun"
                />
              </div>
              <div className="col-md-2 col-3">
                <button
                  type="button"
                  className="btn btn-outline-danger w-100 fs-14"
                  onClick={() => removeVegItem(itemIdx)}
                >
                  Remove
                </button>
              </div>
            </div>
          ))}

          <button
            type="button"
            className="btn btn-sm btn-outline-success mt-1"
            onClick={addVegItem}
          >
            + Add Veg Item
          </button>
        </div>

        {/* Non-Veg Menu Card */}
        <div className="border rounded p-3 mb-4 bg-light">
          <div className="d-flex align-items-center gap-2 mb-3">
            <span className="badge bg-danger fs-13 px-2 py-1">Non-Veg</span>
            <h5 className="fw-bold mb-0 text-danger">Non-Veg Menu</h5>
          </div>

          <div className="row">
            {/* Non-Veg Price */}
            <div className="col-md-6 mb-3">
              <label className="form-label fs-14 fw-semibold">
                Non-Veg Price Per Plate (for Venues)
              </label>
              <input
                type="text"
                className="form-control fs-14"
                value={nonVegPrice}
                onChange={(e) => handleNonVegPriceChange(e.target.value)}
                placeholder="e.g. 665"
              />
            </div>

            {/* Non-Veg Description */}
            <div className="col-12 mb-3">
              <label className="form-label fs-14 fw-semibold">
                Non-Veg Menu Description
              </label>
              <textarea
                className="form-control fs-14"
                rows={3}
                value={nonVegDescription}
                onChange={(e) => handleNonVegDescChange(e.target.value)}
                placeholder="Enter description for non-vegetarian menu, chicken/mutton dishes, seafood, courses included..."
              />
            </div>
          </div>

          {/* Non-Veg Items */}
          <div className="mb-2 fw-semibold fs-14">Non-Veg Menu Items</div>
          {nonVegItems.map((it, itemIdx) => (
            <div className="row mb-2" key={itemIdx}>
              <div className="col-md-10 col-9">
                <input
                  type="text"
                  className="form-control fs-14"
                  value={it}
                  onChange={(e) => handleNonVegItemChange(itemIdx, e.target.value)}
                  placeholder="e.g., Chicken Tikka, Mutton Rogan Josh, Biryani"
                />
              </div>
              <div className="col-md-2 col-3">
                <button
                  type="button"
                  className="btn btn-outline-danger w-100 fs-14"
                  onClick={() => removeNonVegItem(itemIdx)}
                >
                  Remove
                </button>
              </div>
            </div>
          ))}

          <button
            type="button"
            className="btn btn-sm btn-outline-danger mt-1"
            onClick={addNonVegItem}
          >
            + Add Non-Veg Item
          </button>
        </div>

        {/* Save Button */}
        <div className="d-flex gap-2 mt-4">
          <button
            type="button"
            className="btn btn-primary fs-14"
            onClick={handleSaveMenus}
          >
            Save Menus
          </button>
        </div>
      </div>
    </div>
  );
};

export default VendorMenus;



