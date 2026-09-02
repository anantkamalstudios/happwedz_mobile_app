import React from "react";

const VendorPricing = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  onSubmit,
  vendorTypeName,
}) => {
  const handleNestedInputChange = (subSection, field, value) => {
    setFormData((prev) => ({
      ...prev,
      [subSection]: {
        ...(prev[subSection] || {}),
        [field]: value,
      },
    }));
  };

  const handleSave = async () => {
    if (onSave) await onSave();
    if (onShowSuccess) onShowSuccess();
  };

  return (
    <div className="my-5">
      <div className="p-3 border rounded bg-white">
        <h4 className="mb-3 fw-bold">Pricing & Packages</h4>
        <div className="row">
          {/* Starting Price */}
          <div className="col-md-4 mb-3">
            <label className="form-label fs-16 fw-semibold">
              Starting Price
            </label>
            <input
              type="number"
              className="form-control fs-14"
              value={formData.startingPrice || ""}
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  startingPrice: e.target.value,
                }))
              }
              placeholder="Enter starting price"
            />
          </div>

          {/* Price Range */}
          <div className="col-md-6 mb-3">
            <label className="form-label fs-16 fw-semibold">Price Range</label>
            <div className="d-flex gap-2">
              <input
                type="number"
                className="form-control fs-14"
                value={formData.priceRange?.min || ""}
                onChange={(e) =>
                  handleNestedInputChange("priceRange", "min", e.target.value)
                }
                placeholder="Min"
              />
              <span className="d-flex align-items-center">-</span>
              <input
                type="number"
                className="form-control fs-14"
                value={formData.priceRange?.max || ""}
                onChange={(e) =>
                  handleNestedInputChange("priceRange", "max", e.target.value)
                }
                placeholder="Max"
              />
            </div>
          </div>

          {/* Photo Package Price */}
          {(vendorTypeName === "Photographers" ||
            vendorTypeName === "Pre Wedding Shoot") && (
            <>
              <div className="col-md-6 mb-3">
                <label className="form-label fs-16 fw-semibold">
                  Photo Package Price
                </label>
                <input
                  type="number"
                  className="form-control fs-14"
                  value={formData.photo_package_price || ""}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      photo_package_price: e.target.value,
                    }))
                  }
                  placeholder="e.g. 24000"
                />
              </div>

              {/* Photo + Video Package Price */}
              <div className="col-md-6 mb-3">
                <label className="form-label fs-16 fw-semibold">
                  Photo + Video Package Price
                </label>
                <input
                  type="number"
                  className="form-control fs-14"
                  value={formData.photo_video_package_price || ""}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      photo_video_package_price: e.target.value,
                    }))
                  }
                  placeholder="e.g. 40000"
                />
              </div>
            </>
          )}
        </div>

        {/* <div className="row g-2 mt-2">
          <div className="col-12 col-md-2">
            <button className="btn btn-primary w-100" onClick={handleSave}>
              Save Pricing Details
            </button>
          </div>
          <div className="col-12 col-md-2">
            <button className="btn btn-primary w-100" onClick={onSubmit}>
              Submit All Details
            </button>
          </div>
        </div> */}
        <div className="row g-3 mt-3 justify-content-start">
          <div className="col-12 col-sm-6 col-md-4">
            <button
              className="btn btn-primary w-100 py-2 fs-14"
              onClick={handleSave}
            >
              Save Pricing Details
            </button>
          </div>

          <div className="col-12 col-sm-6 col-md-4">
            <button
              className="btn btn-primary w-100 py-2 fs-14"
              onClick={onSubmit}
            >
              Submit All Details
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VendorPricing;
