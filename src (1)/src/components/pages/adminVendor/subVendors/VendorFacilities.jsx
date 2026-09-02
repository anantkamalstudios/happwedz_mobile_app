import React, { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import axios from "axios";
import VenueMasterProfile from "./VenueMasterProfile";
import CatererMasterProfile from "./CatererMasterProfile";
import PhotographerMasterProfile from "./PhotographerMasterProfile";
import MakeupArtistMasterProfile from "./MakeupArtistMasterProfile";
import WeddingPlannerMasterProfile from "./WeddingPlannerMasterProfile";
import DecoratorMasterProfile from "./DecoratorMasterProfile";
import TrousseauPackerMasterProfile from "./TrousseauPackerMasterProfile";
import GiftMasterProfile from "./GiftMasterProfile";
import FavorMasterProfile from "./FavorMasterProfile";
import InvitationMasterProfile from "./InvitationMasterProfile";
import WeddingSuitMasterProfile from "./WeddingSuitMasterProfile";
import SherwaniMasterProfile from "./SherwaniMasterProfile";
import MehndiArtistMasterProfile from "./MehndiArtistMasterProfile";
import FloristMasterProfile from "./FloristMasterProfile";
import PanditMasterProfile from "./PanditMasterProfile";
import DjMasterProfile from "./DjMasterProfile";
import SangeetChoreographerMasterProfile from "./SangeetChoreographerMasterProfile";
import WeddingEntertainerMasterProfile from "./WeddingEntertainerMasterProfile";
import PreWeddingLocationMasterProfile from "./PreWeddingLocationMasterProfile";
import PreWeddingPhotographerMasterProfile from "./PreWeddingPhotographerMasterProfile";
import JewelleryMasterProfile from "./JewelleryMasterProfile";
import JewelleryRentalMasterProfile from "./JewelleryRentalMasterProfile";
import AccessoriesMasterProfile from "./AccessoriesMasterProfile";
import FlowerJewelleryMasterProfile from "./FlowerJewelleryMasterProfile";
import BridalOutfitMasterProfile from "./BridalOutfitMasterProfile";
import RentalOutfitMasterProfile from "./RentalOutfitMasterProfile";
import CocktailGownMasterProfile from "./CocktailGownMasterProfile";

const VendorFacilities = ({
  formData,
  setFormData,
  onSave,
  onShowSuccess,
  vendorTypeName: propVendorTypeName,
  isVenue: propIsVenue,
  isCaterer: propIsCaterer,
}) => {
  const { vendor } = useSelector((state) => state.vendorAuth || {});
  const [fetchedVendorTypeName, setFetchedVendorTypeName] = useState("");
  const [fetchedSubcategoryName, setFetchedSubcategoryName] = useState("");

  useEffect(() => {
    const fetchVendorTypeAndSubcat = async () => {
      try {
        if (vendor?.vendor_type_id) {
          const response = await axios.get(
            `https://happywedz.com/api/vendor-types/${vendor.vendor_type_id}`,
          );
          const typeData = response.data || {};
          setFetchedVendorTypeName(typeData.name || "");

          // Fetch subcategories to map the current subcatId to a name
          const subcats = typeData.subcategories || [];
          const curSubcatId = formData?.vendor_subcategory_id || vendor?.vendor_subcategory_id;

          if (curSubcatId && subcats.length > 0) {
            const matched = subcats.find(s => String(s.id) === String(curSubcatId));
            if (matched) {
              setFetchedSubcategoryName(matched.name || "");
            }
          }
        }
      } catch (err) {
        console.error("Error fetching vendor type references:", err);
      }
    };
    fetchVendorTypeAndSubcat();
  }, [vendor?.vendor_type_id, formData?.vendor_subcategory_id, vendor?.vendor_subcategory_id]);

  const finalVendorTypeName = `${propVendorTypeName || fetchedVendorTypeName} ${fetchedSubcategoryName}`;
  const normalizedType = finalVendorTypeName.toLowerCase();
  const isVenue =
    propIsVenue ||
    normalizedType.includes("venue") ||
    normalizedType.includes("marriage garden") ||
    normalizedType.includes("banquet") ||
    normalizedType.includes("resort") ||
    normalizedType.includes("hotel") ||
    normalizedType.includes("lawn") ||
    normalizedType.includes("palace") ||
    normalizedType.includes("fort");

  const isCaterer =
    propIsCaterer ||
    normalizedType.includes("cater") ||
    normalizedType.includes("food") ||
    normalizedType.includes("tiffin") ||
    normalizedType.includes("kitchen") ||
    normalizedType.includes("meal") ||
    normalizedType.includes("cake") ||
    normalizedType.includes("bakery");
  const isPhotographer = normalizedType.includes("photograph");
  const isMakeupArtist =
    normalizedType.includes("makeup") ||
    (normalizedType.includes("bridal") && normalizedType.includes("artist")) ||
    normalizedType.includes("mua");

  const isWeddingPlanner =
    normalizedType.includes("planner") ||
    normalizedType.includes("event management") ||
    normalizedType.includes("wedding planning") ||
    normalizedType.includes("planning");

  const isDecorator =
    normalizedType.includes("decorator") ||
    normalizedType.includes("decor") ||
    normalizedType.includes("event styling");

  const isTrousseauPacker = normalizedType.includes("trousseau packer") || normalizedType.includes("trousseau pack");
  const isGift = normalizedType === "gifts" || normalizedType === "gift" || normalizedType.includes("gifting") || (normalizedType.includes("invitation") && normalizedType.includes("gift"));
  const isFavor = normalizedType.includes("favor") || normalizedType.includes("favour");
  const isInvitation = (normalizedType.includes("invitation") || normalizedType.includes("invite")) && !isGift;
  
  const isWeddingSuit = normalizedType.includes("wedding suit") || normalizedType.includes("suit");
  const isSherwani = normalizedType.includes("sherwani");

  const isMehndi = normalizedType.includes("mehndi") || normalizedType.includes("mehendi") || normalizedType.includes("henna");
  const isFlorist = normalizedType.includes("florist") && !normalizedType.includes("jewel");
  const isPandit = normalizedType.includes("pandit") || normalizedType.includes("purohit") || normalizedType.includes("priest");
  const isDj = normalizedType.includes("dj") || normalizedType.includes("disc jockey");
  const isSangeetChoreographer = normalizedType.includes("choreograph");
  const isWeddingEntertainer = normalizedType.includes("entertainer") || normalizedType.includes("entertainment") || normalizedType.includes("performer");
  const isPreWeddingLocation = normalizedType.includes("location") && (normalizedType.includes("pre-wedding") || normalizedType.includes("pre wedding"));
  const isPreWeddingPhotographer = normalizedType.includes("photographer") && (normalizedType.includes("pre-wedding") || normalizedType.includes("pre wedding"));

  // Sakshi's categories detection
  const normalizedSubcat = (fetchedSubcategoryName || "").toLowerCase();

  const isCocktailGown =
    normalizedType.includes("cocktail") ||
    normalizedType.includes("gown");

  const isBridalOutfitRent =
    normalizedType.includes("bridal outfit on rent") ||
    normalizedType.includes("bridal lehenga on rent") ||
    normalizedType.includes("bridal rental") ||
    normalizedType.includes("rental outfit") ||
    normalizedType.includes("lehenga on rent") ||
    (!isCocktailGown && normalizedType.includes("wear") && normalizedType.includes("rent"));

  const isBridalOutfit =
    !isCocktailGown &&
    !isBridalOutfitRent &&
    !isTrousseauPacker &&
    (normalizedType.includes("bridal") ||
      normalizedType.includes("outfit") ||
      normalizedType.includes("lehenga") ||
      normalizedType.includes("clothing") ||
      normalizedType.includes("apparel") ||
      normalizedType.includes("boutique") ||
      normalizedType.includes("fashion") ||
      normalizedType.includes("designer") ||
      normalizedType.includes("wear") ||
      normalizedType.includes("trousseau") ||
      normalizedType.includes("kanjeevaram") ||
      normalizedType.includes("saree") ||
      normalizedType.includes("silk"));

  const isAnyBridalOutfit = isBridalOutfit || isBridalOutfitRent || isCocktailGown;

  // Jewellery Detection Logic
  const hasJewellKeyword = normalizedType.includes("jewell") || normalizedType.includes("jewelry");
  const hasFloralKeyword = normalizedType.includes("flower") || normalizedType.includes("floral");
  const hasAccessorKeyword = normalizedType.includes("accessor");
  const isRent = normalizedType.includes("rent");

  const isVendorJewelleryContext = (hasJewellKeyword || hasFloralKeyword || hasAccessorKeyword) && !isAnyBridalOutfit && !isFlorist;

  const isJewelleryRental = isVendorJewelleryContext && isRent;
  const isFlowerJewellery = isVendorJewelleryContext && !isJewelleryRental && hasFloralKeyword;
  const isAccessories = isVendorJewelleryContext && !isJewelleryRental && !isFlowerJewellery && (normalizedSubcat.includes("accessor") || normalizedType.includes("accessor"));
  const isJewellery = isVendorJewelleryContext && !isJewelleryRental && !isFlowerJewellery && !isAccessories;

  const hasMasterProfile =
    isVenue ||
    isCaterer ||
    isPhotographer ||
    isMakeupArtist ||
    isWeddingPlanner ||
    isDecorator ||
    isTrousseauPacker ||
    isGift ||
    isFavor ||
    isInvitation ||
    isWeddingSuit ||
    isSherwani ||
    isMehndi ||
    isFlorist ||
    isPandit ||
    isDj ||
    isSangeetChoreographer ||
    isWeddingEntertainer ||
    isPreWeddingLocation ||
    isPreWeddingPhotographer ||
    isJewellery ||
    isAccessories ||
    isFlowerJewellery ||
    isJewelleryRental ||
    isBridalOutfit ||
    isBridalOutfitRent ||
    isCocktailGown;

  const handleSave = async () => {
    if (onSave) await onSave(formData);
  };

  return (
    <div className="facilities-features-wrapper">
      <div className="storefront-content-card">
    <div className="my-5">
      <div
        className="p-4 border-0 rounded-4 bg-white"
        style={{ boxShadow: "0 2px 16px rgba(0, 0, 0, 0.06)" }}
      >
        {hasMasterProfile ? (
          <>
            <div className="d-flex align-items-center justify-content-between mb-4 pb-2 border-bottom">
              <div>
                <h4 className="fw-bold mb-1" style={{ color: "#0f172a" }}>
                  Facilities &amp; Features
                </h4>
                <p className="text-muted small mb-0">
                  Select available amenities, services, and venue features
                </p>
              </div>
              <span
                className="badge px-3 py-2"
                style={{
                  backgroundColor: "#fff1f6",
                  color: "#ed1173",
                  border: "1px solid #fce7f3",
                  fontSize: "0.82rem",
                  fontWeight: 600,
                  borderRadius: "20px",
                }}
              >
                Facilities
              </span>
            </div>
            <h4 className="mb-1 fw-bold">Facilities &amp; Features</h4>
            <p className="text-muted fs-14 mb-4">
              Select everything that applies — these help couples filter and find your listing.
            </p>
            {isVenue && (
              <VenueMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isCaterer && (
              <CatererMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isPhotographer && !isPreWeddingPhotographer && (
              <PhotographerMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isMakeupArtist && (
              <MakeupArtistMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isWeddingPlanner && (
              <WeddingPlannerMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isDecorator && (
              <DecoratorMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isTrousseauPacker && (
              <TrousseauPackerMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isGift && (
              <GiftMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isFavor && (
              <FavorMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isInvitation && (
              <InvitationMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isWeddingSuit && (
              <WeddingSuitMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isSherwani && (
              <SherwaniMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isMehndi && (
              <MehndiArtistMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isFlorist && (
              <FloristMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isPandit && (
              <PanditMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isDj && (
              <DjMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isSangeetChoreographer && (
              <SangeetChoreographerMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isWeddingEntertainer && (
              <WeddingEntertainerMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isPreWeddingLocation && (
              <PreWeddingLocationMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isPreWeddingPhotographer && (
              <PreWeddingPhotographerMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isJewellery && (
              <JewelleryMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isAccessories && (
              <AccessoriesMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isFlowerJewellery && (
              <FlowerJewelleryMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isJewelleryRental && (
              <JewelleryRentalMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isBridalOutfit && !isBridalOutfitRent && !isCocktailGown && (
              <BridalOutfitMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isBridalOutfitRent && (
              <RentalOutfitMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
            {isCocktailGown && (
              <CocktailGownMasterProfile
                formData={formData}
                setFormData={setFormData}
                onSave={onSave}
                onShowSuccess={onShowSuccess}
                embedded
              />
            )}
          </>
        ) : (
          <>
            <h4 className="mb-3 fw-bold">Vendor details</h4>
            <div className="row">
              <div className="col-md-6 mb-3">
                <label className="form-label fw-semibold">
                  Offerings (comma-separated)
                </label>
                <input
                  type="text"
                  className="form-control"
                  value={formData.offerings || ""}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      offerings: e.target.value,
                    }))
                  }
                  placeholder="e.g. Wedding, Pre-Wedding, Portrait"
                />
              </div>
              <div className="col-md-6 mb-3">
                <label className="form-label fw-semibold">Delivery Time</label>
                <input
                  type="text"
                  className="form-control"
                  value={formData.delivery_time || ""}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      delivery_time: e.target.value,
                    }))
                  }
                  placeholder="e.g. 2-3 weeks"
                />
              </div>
              <div className="col-md-6 mb-3">
                <label className="form-label fw-semibold">Travel Info</label>
                <input
                  type="text"
                  className="form-control"
                  value={formData.travel_info || ""}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      travel_info: e.target.value,
                    }))
                  }
                  placeholder="e.g. Travel within city, All over India"
                />
              </div>
              <div className="col-md-6 mb-3">
                <label className="form-label fs-16 fw-semibold">
                  HappyWedz Since
                </label>
                <input
                  type="text"
                  className="form-control fs-14"
                  value={formData.happywedz_since || ""}
                  onChange={(e) =>
                    setFormData((prev) => ({
                      ...prev,
                      happywedz_since: e.target.value,
                    }))
                  }
                  placeholder="e.g. 2020"
                />
              </div>
            </div>
          </>
        )}

        <button className="btn btn-primary mt-4 fs-14" type="button" onClick={handleSave}>
          {hasMasterProfile ? "Save facilities & features" : "Save profile"}
        </button>
      </div>
    </div>
      </div>
    </div>
  );
};

export default VendorFacilities;
