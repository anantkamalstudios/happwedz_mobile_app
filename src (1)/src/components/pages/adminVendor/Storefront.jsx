import { IMAGE_BASE_URL } from "../../../config/constants.js";
import React, { useMemo, useState, useEffect, useCallback, useRef } from "react";
import { useSelector } from "react-redux";
import { Nav } from "react-bootstrap";
import "./Storefront.css";
import {
  CiBullhorn,
  CiCircleQuestion,
  CiLocationOn,
  CiShoppingTag,
} from "react-icons/ci";
import BusinessDetails from "./subVendors/BusinessDetails";
import PromoForm from "./subVendors/PromoForm";
import PhotoGallery from "./subVendors/PhotoGallery";
import VideoGallery from "./subVendors/VideoGallery";
// import SocialDetails from "./subVendors/SocialDetails";
// Vendor Form Sections
import VendorBasicInfo from "./subVendors/VendorBasicInfo";
import VendorContact from "./subVendors/VendorContact";
import VendorLocation from "./subVendors/VendorLocation";
import VendorMedia from "./subVendors/VendorMedia";
import VendorPricing from "./subVendors/VendorPricing";
import VendorFacilities from "./subVendors/VendorFacilities";
import VendorPolicies from "./subVendors/VendorPolicies";
import VendorAvailability from "./subVendors/VendorAvailability";
import VendorMarketing from "./subVendors/VendorMarketing";
import SuccessModal from "../../ui/SuccessModal";
import { PiForkKnife, PiPhoneCall } from "react-icons/pi";
import { IoIosInformationCircleOutline } from "react-icons/io";
import { HiOutlineDocument } from "react-icons/hi2";
import {
  MdCurrencyRupee,
  MdOutlineAccountBalance,
  MdOutlineEventAvailable,
  MdOutlineFiberNew,
} from "react-icons/md";

import { PiShareNetworkDuotone } from "react-icons/pi";

import {
  IoCameraOutline,
  IoCheckmarkCircleOutline,
  IoVideocamOutline,
} from "react-icons/io5";
import Faq from "./subVendors/Faq.jsx";
import { GoGift } from "react-icons/go";
import VendorMenus from "./subVendors/VendorMenus";
import vendorServicesApi from "../../../services/api/vendorServicesApi";
import { name } from "dayjs/locale/en.js";
import Swal from "sweetalert2";
import PreferredVendors from "./subVendors/PreferredVendors";
import SocialDetails from "./subVendors/SocialDetails";
import axiosInstance from "../../../services/api/axiosInstance";
import { TbView360Number } from "react-icons/tb";
import View360 from "./subVendors/View360";
// Reusable New Tag component
const NewTag = () => (
  <span
    style={{
      background: "none",
      fontWeight: "600",
      marginLeft: "8px",
      display: "inline-flex",
      alignItems: "center",
      height: "16px",
      lineHeight: "12px",
      whiteSpace: "nowrap",
    }}
  >
    <MdOutlineFiberNew size={25} color="red" />
  </span>
);

const normalizeServiceStatus = (value) => {
  const normalized = String(value || "").trim().toLowerCase();
  if (normalized === "publish" || normalized === "published") return "publish";
  if (
    normalized === "hide" ||
    normalized === "draft" ||
    normalized === "archived"
  )
    return "hide";
  return "";
};

/** Ignore React click events mistakenly passed as onClick={onSave} */
const isFormSavePayload = (payload) =>
  payload &&
  typeof payload === "object" &&
  !Array.isArray(payload) &&
  !payload.nativeEvent &&
  !(payload instanceof Event);

const safeStringifyFormData = (value) => {
  try {
    return JSON.stringify(value);
  } catch {
    return "{}";
  }
};

const Storefront = ({ setCompletion }) => {
  const [active, setActive] = useState("business");
  const [showModal, setShowModal] = useState(false);
  const { token, vendor } = useSelector((state) => state.vendorAuth || {});
  const [formData, setFormData] = useState({ attributes: vendor || {} });
  const formDataRef = useRef(formData);
  useEffect(() => {
    formDataRef.current = formData;
  }, [formData]);
  const [photoDrafts, setPhotoDrafts] = useState([]);
  const [videoDrafts, setVideoDrafts] = useState([]);
  const [view360Images, setView360Images] = useState([]);
  const [view360Videos, setView360Videos] = useState([]);
  const [vendorTypeName, setVendorTypeName] = useState("");
  // Persist active tab per-vendor so refresh/navigation keeps you on the same section
  const storageKey = React.useMemo(
    () =>
      vendor?.id ? `storefrontActiveTab_${vendor.id}` : "storefrontActiveTab",
    [vendor?.id]
  );

  const fetchServiceData = useCallback(async () => {
    if (vendor?.id && token) {
      try {
        const lastVendorId = localStorage.getItem("lastVendorId");
        if (lastVendorId && lastVendorId !== vendor.id.toString()) {
          localStorage.removeItem("vendorFormData");
          localStorage.removeItem("photoDraftsMeta");
          localStorage.removeItem("videoDraftsMeta");
          localStorage.removeItem("vendorServiceId");
          setFormData({});
          setPhotoDrafts([]);
          setVideoDrafts([]);
        }
        localStorage.setItem("lastVendorId", vendor.id.toString());

        const serviceData = await vendorServicesApi.getVendorServiceByVendorId(
          vendor.id,
          token
        );
        
        const actualData = serviceData 
          ? (Array.isArray(serviceData) ? serviceData[0] : serviceData) 
          : null;

        // Fetch vendor type name from API (like VendorBasicInfo)
        if (vendor.vendor_type_id) {
          try {
            const response = await axiosInstance.get(
              `/vendor-types/${vendor.vendor_type_id}`
            );
            const vendorTypeData = response.data || {};
            const subcategoryId = actualData?.vendor_subcategory_id || vendor.vendor_subcategory_id;
            const subcats = vendorTypeData.subcategories || [];
            const subcat = subcats.find(s => s.id == subcategoryId);
            
            if (subcat && subcat.name) {
              setVendorTypeName(subcat.name);
            } else {
              setVendorTypeName(vendorTypeData.name || "");
            }
          } catch (err) {
            console.error(err);
          }
        }

        // If data exists, merge it into formData.
        if (serviceData) {
          if (actualData) {
            let gallery = [];
            let videos = [];
            let panoImages = [];
            let panoVideos = [];

            if (actualData.media) {
              if (Array.isArray(actualData.media)) {
                gallery = actualData.media.map((item) =>
                  typeof item === "string"
                    ? item
                    : item.url || item.path || null
                );
              } else if (
                actualData.media &&
                typeof actualData.media === "object"
              ) {
                // legacy shape: { gallery: [...], videos: [...] }
                gallery = Array.isArray(actualData.media.gallery)
                  ? actualData.media.gallery.map((g) =>
                    typeof g === "string" ? g : g.url || g.path || null
                  )
                  : [];
                videos = Array.isArray(actualData.media.videos)
                  ? actualData.media.videos.map((v) =>
                    typeof v === "string" ? v : v.url || v.path || null
                  )
                  : [];
              }
            }

            if (actualData.attributes) {
              const videosFromAttr =
                actualData.attributes.video ||
                actualData.attributes.vedio ||
                [];
              if (Array.isArray(videosFromAttr)) {
                const normalizedVideos = videosFromAttr
                  .map((v) =>
                    typeof v === "string" ? v : v.url || v.path || null
                  )
                  .filter(Boolean);
                videos = [...new Set([...videos, ...normalizedVideos])];
              }

              // Prefer whichever source is actually present rather than merging both:
              // a union can only grow, so a stale entry left behind in either location
              // (e.g. after a removal that only updated one of the two) would otherwise
              // resurrect forever.
              const toUrlList = (val) => {
                if (Array.isArray(val)) {
                  return val
                    .map((v) =>
                      typeof v === "string" ? v : v.url || v.path || null
                    )
                    .filter(Boolean);
                }
                if (typeof val === "string" && val.trim()) return [val];
                return null; // not provided by this source
              };

              const topImages = toUrlList(
                actualData.view360_images ?? actualData.view360_image
              );
              const attrImages = toUrlList(
                actualData.attributes.view360_images
              );
              panoImages = topImages ?? attrImages ?? [];

              const topVideos = toUrlList(
                actualData.view360_video ?? actualData.view360Videos
              );
              const attrVideos = toUrlList(
                actualData.attributes.view360_video
              );
              panoVideos = topVideos ?? attrVideos ?? [];
            }

            // Deduplicate 360 media
            panoImages = [...new Set(panoImages)];
            panoVideos = [...new Set(panoVideos)];

            // Normalize gallery and videos: prefix relative paths and build draft objects
            const cleanUrl = (s) =>
              s && typeof s === "string"
                ? s.replace(/^\s*`|`\s*$/g, "").trim()
                : s;

            const photoDraftsData = Array.isArray(gallery)
              ? gallery.map((item, index) => {
                let preview = cleanUrl(item || "");
                if (preview && preview.startsWith("/uploads/"))
                  preview = IMAGE_BASE_URL + preview;
                return {
                  preview,
                  file: null,
                };
              })
              : [];
            setPhotoDrafts(photoDraftsData.filter((p) => p.preview));

            const videoDraftsData = Array.isArray(videos)
              ? videos.map((item, index) => {
                let preview = cleanUrl(item || "");
                if (preview && preview.startsWith("/uploads/"))
                  preview = IMAGE_BASE_URL + preview;
                return {
                  id: `video_${index}`,
                  title: "",
                  type: "video",
                  preview,
                  file: null,
                };
              })
              : [];
            setVideoDrafts(videoDraftsData.filter((v) => v.preview));
            const panoImageDrafts = Array.isArray(panoImages)
              ? panoImages.map((item, index) => {
                let preview = cleanUrl(item || "");
                if (preview && preview.startsWith("/uploads/"))
                  preview = IMAGE_BASE_URL + preview;
                return {
                  id: `pano_${index}`,
                  preview,
                  file: null,
                };
              })
              : [];
            setView360Images(panoImageDrafts.filter((v) => v.preview));
            const panoVideoDrafts = Array.isArray(panoVideos)
              ? panoVideos.map((item, index) => {
                let preview = cleanUrl(item || "");
                if (preview && preview.startsWith("/uploads/"))
                  preview = IMAGE_BASE_URL + preview;
                return {
                  id: `pano_video_${index}`,
                  preview,
                  file: null,
                };
              })
              : [];
            setView360Videos(panoVideoDrafts.filter((v) => v.preview));

            if (actualData) {
              const attrs = actualData.attributes || {};
              setFormData((prev) => ({
                ...prev,
                ...actualData,
                // Prioritize API response, as it reflects successful updates, then local state, then Redux
                vendor_subcategory_id: actualData.vendor_subcategory_id || prev.vendor_subcategory_id || vendor.vendor_subcategory_id,
                id: actualData.id ?? prev.id,
                status: normalizeServiceStatus(actualData.status),
                availabilityActive: attrs.availability_active !== false,
                deals: attrs.deals || [],
                contact: attrs.contact
                  ? {
                    contactName: attrs.contact.name || "",
                    phone: attrs.contact.phone || "",
                    altPhone: attrs.contact.altPhone || "",
                    email: attrs.contact.email || "",
                    website: attrs.contact.website || "",
                    whatsappNumber: attrs.contact.whatsapp || "",
                    inquiryEmail: attrs.contact.inquiryEmail || "",
                  }
                  : {},
                city: attrs.city || "",

                location: attrs.location
                  ? {
                    address: attrs.address || "",
                    city: attrs.city || "",
                    state: attrs.location.state || "",
                    country: attrs.location.country || "India",
                    pincode: attrs.location.pincode || "",
                    latitude: attrs.latitude || "",
                    longitude: attrs.longitude || "",
                    exact_location_text:
                      attrs.venue_master?.identity?.exact_location_text || "",
                    map_pin_url:
                      attrs.venue_master?.identity?.map_pin_url || "",
                    serviceAreas: attrs.location.serviceAreas || [],
                  }
                  : {},

                // Pricing fields mapping
                startingPrice: attrs.starting_price || "",
                priceRange: attrs.price_range || {
                  min: "",
                  max: "",
                },
                PriceRange: attrs.PriceRange || "",

                capacity: attrs.capacity || {
                  min: "",
                  max: "",
                },
                // indoorOutdoor: attrs.indoor_outdoor || "",
                // alcoholPolicy: attrs.alcohol_policy || "",
                outside_alcohol: attrs.outside_alcohol || "",
                cateringPolicy: attrs.catering_policy || "",
                rooms: attrs.rooms || "",
                cancellationPolicy: attrs.cancellation_policy || "",
                refundPolicy: attrs.refund_policy || "",

                payment_terms: attrs.payment_terms || "",
                parking: attrs.parking || "",

                // tnc: actualData.attributes.tnc || "",

                // isFeatureAvailable: actualData.attributes.is_feature_available,
                // within24HrAvailable:
                //   actualData.attributes.within_24hr_available,
                // djPolicy: actualData.attributes.dj_policy || "",
                // primaryCTA: actualData.attributes.primary_cta || "enquire",
                // sortWeight: actualData.attributes.sort_weight || "",
                timing: attrs.timing || {
                  open: "",
                  close: "",
                  lastEntry: "",
                },
                // ctaUrl: attrs.cta_url || "",
                // ctaPhone: attrs.cta_phone || "",
                // autoReply: attrs.auto_reply || "",

                veg_price: attrs.veg_price || "",
                non_veg_price: attrs.non_veg_price || "",
                photo_package_price: attrs.photo_package_price || "",
                photo_video_package_price: attrs.photo_video_package_price || "",
                happywedz_since: attrs.happywedz_since || attrs.HappyWedz || "",
                travel_info: attrs.travel_info || "",
                offerings: attrs.offerings || "",
                delivery_time: attrs.delivery_time || "",
                decorPolicy: attrs.decor_policy || "",
                area: attrs.area || "",
                start_venue: attrs.start_venue || "",
                space: attrs.space || "",
                dJ_policy: attrs.dJ_policy || "",
                video: attrs.video || [],
                availableSlots: attrs.available_slots || [],
                // Master Profiles from both branches
                venue_master: attrs.venue_master || {},
                caterer_master: attrs.caterer_master || {},
                photographer_master: attrs.photographer_master || {},
                makeup_artist_master: attrs.makeup_artist_master || {},
                jewellery_master: attrs.jewellery_master || {},
                jewellery_rental_master: attrs.jewellery_rental_master || {},
                bridal_outfit_master: attrs.bridal_outfit_master || {},
                rental_outfit_master: attrs.rental_outfit_master || {},
                cocktail_gown_master: attrs.cocktail_gown_master || {},
                accessories_master: attrs.accessories_master || {},
                flower_jewellery_master: attrs.flower_jewellery_master || {},
                wedding_planner_master: attrs.wedding_planner_master || {},
                decorator_master: attrs.decorator_master || {},
                trousseau_master: attrs.trousseau_master || {},
                gift_master: attrs.gift_master || {},
                favor_master: attrs.favor_master || {},
                invitation_master: attrs.invitation_master || {},
                wedding_suit_master: attrs.wedding_suit_master || {},
                sherwani_master: attrs.sherwani_master || {},
                mehndi_artist_master: attrs.mehndi_artist_master || {},
                florist_master: attrs.florist_master || {},
                pandit_master: attrs.pandit_master || {},
                dj_master: attrs.dj_master || actualData.dj_master || {},
                sangeet_choreographer_master: attrs.sangeet_choreographer_master || actualData.sangeet_choreographer_master || {},
                wedding_entertainer_master: attrs.wedding_entertainer_master || actualData.wedding_entertainer_master || {},
                pre_wedding_location_master: attrs.pre_wedding_location_master || null,
                pre_wedding_photographer_master: attrs.pre_wedding_photographer_master || null,
                

                attributes: {
                  ...prev.attributes,
                  ...attrs,
                  email: attrs.contact?.email || prev.attributes?.email,
                },
              }));

              if (actualData.id) {
                localStorage.setItem(
                  "vendorServiceId",
                  actualData.id.toString()
                );
              }
            }
          }
        }
      } catch (error) {
        console.error("Failed to fetch vendor service data:", error);
      }
    }
  }, [vendor?.id, vendor?.vendor_type_id, token]);

  useEffect(() => {
    fetchServiceData();
  }, [fetchServiceData]);

  // Fetch and load storefront completion from backend
  useEffect(() => {
    const fetchStorefrontCompletion = async () => {
      if (!formData.id || !token) return;

      try {
        const response = await axiosInstance.get(
          `/vendor-services/${formData.id}/storefront-completion`,
          {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          }
        );

        const data = response.data;
        console.log("Storefront completion response:", data);

        if (data?.service?.storefront_completion !== undefined) {
          const completion = data.service.storefront_completion;
          localStorage.setItem("storefrontCompletion", completion.toString());
          console.log("Stored storefrontCompletion:", completion);
        }
      } catch (error) {
        console.error("Error fetching storefront completion:", error);
      }
    };

    fetchStorefrontCompletion();
  }, [formData.id, token]);

  // Persist service ID to localStorage so Navbar can access it
  useEffect(() => {
    if (formData.id) {
      localStorage.setItem("vendorServiceId", formData.id.toString());
    }
  }, [formData.id]);


  const MASTER_PROFILE_KEYS = [
    "venue_master",
    "caterer_master",
    "photographer_master",
    "makeup_artist_master",
    "jewellery_master",
    "jewellery_rental_master",
    "bridal_outfit_master",
    "rental_outfit_master",
    "cocktail_gown_master",
    "accessories_master",
    "flower_jewellery_master",
    "wedding_planner_master",
    "decorator_master",
    "trousseau_master",
    "gift_master",
    "favor_master",
    "invitation_master",
    "wedding_suit_master",
    "sherwani_master",
    "mehndi_artist_master",
    "florist_master",
    "pandit_master",
    "dj_master",
    "sangeet_choreographer_master",
    "wedding_entertainer_master",
    "pre_wedding_location_master",
    "pre_wedding_photographer_master",
  ];

  const applyMasterProfilesToAttributes = (attrs, data) => {
    const vendorName =
      data.attributes?.businessName ||
      data.attributes?.name ||
      data.attributes?.Name ||
      "";

    const injectBrandName = (masterObj, fieldName) => {
      if (!masterObj) return undefined;
      const newObj = JSON.parse(JSON.stringify(masterObj));
      if (!newObj.identity) newObj.identity = {};
      newObj.identity[fieldName] = vendorName;
      return newObj;
    };

    MASTER_PROFILE_KEYS.forEach((key) => {
      let master = data?.[key] ?? data?.attributes?.[key];
      if (master && typeof master === "object" && !Array.isArray(master) && Object.keys(master).length > 0) {
        // Inject brand/company names for specific categories for backward compatibility/consistency
        if (key === "venue_master") {
          master = injectBrandName(master, "chain_brand_name");
        } else if (key === "caterer_master" || key === "trousseau_master" || key === "gift_master" || key === "favor_master" || key === "invitation_master" || key === "wedding_suit_master" || key === "sherwani_master" || key === "mehndi_artist_master" || key === "florist_master" || key === "pandit_master") {
          master = injectBrandName(master, "brand_name");
        } else if (key === "makeup_artist_master") {
          master = injectBrandName(master, "brand_artist_name");
        } else if (key === "wedding_planner_master") {
          master = injectBrandName(master, "company_name");
        } else if (key === "decorator_master") {
          master = injectBrandName(master, "brand_company_name");
        }
        
        attrs[key] = master;
      }
    });
    return attrs;
  };

  /** Merge vendor account + jewellery identity so API required fields are present on any tab save */
  const enrichSaveData = useCallback(
    (data) => {
      const base = isFormSavePayload(data)
        ? data
        : formDataRef.current || formData;

      const jm = base?.jewellery_master || base?.attributes?.jewellery_master;
      const ji = jm?.identity || {};
      
      const bo = base?.bridal_outfit_master || base?.attributes?.bridal_outfit_master;
      const boi = bo?.identity || {};

      const ro = base?.rental_outfit_master || base?.attributes?.rental_outfit_master;
      const roi = ro?.identity || {};

      const cg = base?.cocktail_gown_master || base?.attributes?.cocktail_gown_master;
      const cgi = cg?.identity || {};

      const am = base?.accessories_master || base?.attributes?.accessories_master;
      const ami = am?.identity || {};
      
      const fjm = base?.flower_jewellery_master || base?.attributes?.flower_jewellery_master;
      const fjmi = fjm?.identity || {};

      const jrm = base?.jewellery_rental_master || base?.attributes?.jewellery_rental_master;
      const jrmi = jrm?.identity || {};

      const jCities = Array.isArray(ji.cities)
        ? ji.cities.filter(Boolean)
        : ji.cities
          ? [ji.cities]
          : [];

      const businessName =
        base?.attributes?.businessName ||
        base?.attributes?.name ||
        base?.attributes?.Name ||
        ji.brand_store_name ||
        jrmi.brand_name ||
        boi.brand_name ||
        roi.brand_name ||
        cgi.brand_name ||
        ami.brand_name ||
        fjmi.brand_name ||
        vendor?.businessName ||
        "";

      const city =
        base?.location?.city ||
        base?.attributes?.city ||
        base?.city ||
        fjmi.city ||
        jrmi.city ||
        jCities[0] ||
        vendor?.city ||
        "";

      const phone =
        base?.contact?.phone || vendor?.phone || base?.attributes?.phone || "";

      const email =
        base?.contact?.email ||
        vendor?.email ||
        base?.attributes?.email ||
        "";

      const slugBase = businessName
        .toLowerCase()
        .trim()
        .replace(/\s+/g, "-")
        .replace(/[^a-z0-9-]/g, "");

      return {
        ...base,
        vendor_subcategory_id:
          base?.vendor_subcategory_id || vendor?.vendor_subcategory_id || "",
        vendor_type_id: base?.vendor_type_id || vendor?.vendor_type_id,
        status: normalizeServiceStatus(base?.status) || "hide",
        contact: {
          ...(base?.contact || {}),
          contactName:
            base?.contact?.contactName ||
            businessName ||
            vendor?.businessName ||
            "",
          phone,
          email,
        },
        location: {
          ...(base?.location || {}),
          city,
          country: base?.location?.country || "India",
        },
        attributes: {
          ...(base?.attributes || {}),
          businessName,
          name: businessName,
          Name: businessName,
          vendor_name: businessName,
          slug: base?.attributes?.slug || slugBase || "",
          city,
          email,
          phone,
        },
      };
    },
    [vendor]
  );

  const getMissingRequiredStorefrontFields = (data) => {
    const missing = [];
    const name =
      data?.attributes?.businessName ||
      data?.attributes?.name ||
      data?.attributes?.Name;
    if (!name || !String(name).trim()) missing.push("Business / store name");
    if (!data?.location?.city && !data?.attributes?.city) {
      missing.push("City");
    }
    if (!data?.vendor_subcategory_id) {
      missing.push("Subcategory (Store Info → Basic Info)");
    }
    const phone =
      data?.contact?.phone || data?.attributes?.phone || vendor?.phone;
    if (!phone || !String(phone).trim()) missing.push("Phone number");
    return missing;
  };

  const resolveServiceId = async () => {
    if (!vendor?.id || !token) return null;

    try {
      const serviceData = await vendorServicesApi.getVendorServiceByVendorId(
        vendor.id,
        token
      );
      const actual = Array.isArray(serviceData)
        ? serviceData[0]
        : serviceData;
      if (actual?.id) {
        localStorage.setItem("vendorServiceId", actual.id.toString());
        return actual.id;
      }
    } catch (error) {
      console.error("Failed to resolve vendor service id:", error);
    }

    return null;
  };

  const handleSave = async (saveData) => {
    const isPayload = isFormSavePayload(saveData);
    const raw = isPayload
      ? { ...(formDataRef.current || formData), ...saveData }
      : formDataRef.current || formData;

    const data = enrichSaveData(raw);
    localStorage.setItem("vendorFormData", safeStringifyFormData(data));

    const missingRequired = getMissingRequiredStorefrontFields(data);
    if (missingRequired.length > 0) {
      Swal.fire({
        icon: "warning",
        title: "Required storefront fields missing",
        html: `The server needs these before Facilities can be saved:<br/><br/><b>${missingRequired.join("<br/>")}</b><br/><br/>Add them under <b>Store Info → Basic Info</b> (or Jewellery Section 1: Brand name & City), then save again.`,
        confirmButtonColor: "#C31162",
      });
      return;
    }

    let serviceId = await resolveServiceId();

    try {
      const fd = buildFormData({ ...data, id: serviceId || data.id });

      if (!serviceId) {
        // First save: create vendor-services listing (POST), same as Pricing → Submit All Details
        const created = await vendorServicesApi.createOrUpdateService(fd, token);
        serviceId = created?.id || null;
        if (!serviceId) {
          Swal.fire({
            icon: "warning",
            title: "Could not create listing",
            text: "Please fill Store Info → Basic Info (business name, city) and try again, or use Pricing → Submit All Details once.",
            confirmButtonColor: "#C31162",
          });
          return;
        }
        localStorage.setItem("vendorServiceId", serviceId.toString());
        setFormData((prev) => ({ ...prev, id: serviceId }));
      } else {
        await vendorServicesApi.createOrUpdateService(fd, token, serviceId);
        setFormData((prev) => ({ ...prev, id: serviceId }));
      }

      await fetchServiceData();
      setShowModal(true);
    } catch (e) {
      const status = e?.status;
      let message =
        typeof e === "string"
          ? e
          : e?.message || e?.error || "Unknown error";

      if (status === 403) {
        message =
          "You do not have permission to update this listing. Please log out, log in again, and retry. If the issue continues, contact support.";
        localStorage.removeItem("vendorServiceId");
      }

      Swal.fire({
        icon: "error",
        title: "Oops...",
        text: `Failed to update. ${message}`,
        timer: "3000",
        confirmButtonText: "OK",
        confirmButtonColor: "#ed1173",
      });
      return; // Do not show success modal on failure
    }
  };

  // Expose show success modal to subcomponents
  const showSuccessModal = useMemo(() => () => setShowModal(true), []);

  // This effect is removed since we now load data from API instead of localStorage

  // Persist lightweight drafts (no File blobs) whenever they change
  useEffect(() => {
    const meta = photoDrafts.map(({ preview }) => ({ preview }));
    localStorage.setItem("photoDraftsMeta", JSON.stringify(meta));
  }, [photoDrafts]);

  useEffect(() => {
    // Persist only lightweight preview URLs for videos (avoid storing internal ids/titles)
    const meta = videoDrafts.map(({ preview, url }) => ({
      preview: preview || url,
    }));
    localStorage.setItem("videoDraftsMeta", JSON.stringify(meta));
  }, [videoDrafts]);

  const buildAttributes = (sourceData) => {
    const data = enrichSaveData(
      sourceData || formDataRef.current || formData
    );
    const jm = data.jewellery_master || data.attributes?.jewellery_master;
    const ji = jm?.identity || {};
    const jCities = Array.isArray(ji.cities) ? ji.cities : [];
    
    const bo = data.bridal_outfit_master || data.attributes?.bridal_outfit_master;
    const boi = bo?.identity || {};

    const ro = data.rental_outfit_master || data.attributes?.rental_outfit_master;
    const roi = ro?.identity || {};

    const cg = data.cocktail_gown_master || data.attributes?.cocktail_gown_master;
    const cgi = cg?.identity || {};

    const am = data.accessories_master || data.attributes?.accessories_master;
    const ami = am?.identity || {};

    const fjm = data.flower_jewellery_master || data.attributes?.flower_jewellery_master;
    const fjmi = fjm?.identity || {};

    const attrs = {
      // tnc: formData.tnc,
      name:
        data.attributes?.businessName ||
        data.attributes?.name ||
        data.attributes?.Name ||
        ji.brand_store_name ||
        boi?.brand_name ||
        roi?.brand_name ||
        cgi?.brand_name ||
        ami?.brand_name ||
        fjmi?.brand_name ||
        vendor?.businessName ||
        "",
      vendor_name:
        data.attributes?.vendor_name ||
        data.attributes?.businessName ||
        data.attributes?.name ||
        data.attributes?.Name ||
        ji.brand_store_name ||
        boi?.brand_name ||
        roi?.brand_name ||
        cgi?.brand_name ||
        ami?.brand_name ||
        fjmi?.brand_name ||
        vendor?.businessName ||
        "",
      slug: data.attributes?.slug || "",
      // tags: data.tags || [],
      deals: data.deals || [],
      email: data.contact?.email || "",
      rooms: data.rooms ? Number(data.rooms) : undefined,
      // badges: data.badges || {},
      rating: data.rating ? Number(data.rating) : undefined,
      contact: {
        name: data.contact?.contactName || "",
        phone: data.contact?.phone || "",
        // website: data.contact?.website || "",
        whatsapp: data.contact?.whatsappNumber || "",
        altPhone: data.contact?.altPhone || "",
        email: data.contact?.email || "",
        // contactName: formData.contact?.contactName || "",
      },
      // cta_url: formData.ctaUrl || "",
      // tagline: formData.attributes?.tagline || "",
      // currency: formData.currency || "INR",
      city:
        data.location?.city ||
        data.attributes?.city ||
        fjmi?.city ||
        jCities[0] ||
        vendor?.city ||
        "",
      latitude: data.location?.latitude || "",
      longitude: data.location?.longitude || "",
      address: data.location?.address || "",

      location: {
        state: data.location?.state || "",
        // address: data.location?.addressLine1 || "",
        country: data.location?.country || "India",
        pincode: data.location?.pincode || "",
      },
      // packages: formData.packages || [],
      // subtitle: formData.attributes?.subtitle || "",
      // cta_phone: formData.ctaPhone || "",
      // dj_policy: formData.djPolicy || "",
      // auto_reply: formData.autoReply || "",
      // price_unit: formData.priceUnit || "",
      parking: data.parking || "",
      // deco_policy: data.decoPolicy || "",
      about_us: data.attributes?.about_us || "",
      is_featured: !!data.isFeatured,
      price_range: data.priceRange || { min: "", max: "" },
      PriceRange:
        data.priceRange?.min && data.priceRange?.max
          ? `${data.priceRange.min} - ${data.priceRange.max}`
          : data.PriceRange || "",
      // primary_cta: formData.primaryCTA || "enquire",
      // sort_weight: formData.sortWeight
      //   ? Number(formData.sortWeight)
      //   : undefined,
      // timing_open: formData.timing?.open || "",
      capacity_max: data.capacity?.max
        ? Number(data.capacity?.max)
        : undefined,
      capacity_min: data.capacity?.min
        ? Number(data.capacity?.min)
        : undefined,
      // timing_close: formData.timing?.close || "",

      payment_terms: data.payment_terms || "",

      refund_policy: data.refundPolicy || "",
      reviews_count: data.reviewsCount
        ? Number(data.reviewsCount)
        : undefined,
      alcohol_policy: data.alcoholPolicy || "",
      outside_alcohol: data.outside_alcohol || "",
      // blackout_dates: data.blackoutDates || [],
      indoor_outdoor: data.indoorOutdoor || "",
      starting_price: data.startingPrice
        ? Number(data.startingPrice)
        : undefined,
      available_slots: Array.isArray(data.availableSlots)
        ? data.availableSlots.map((s) => ({
          date: s.date,
          // slots:
          //   s.slots ||
          //   (s.timeFrom && s.timeTo ? [`${s.timeFrom}-${s.timeTo}`] : []),
        }))
        : [],
      catering_policy: data.cateringPolicy || "",
      // hall_types_note: data.hallTypesNote || "",
      // timing_last_entry: data.timing?.lastEntry || "",
      cancellation_policy: data.cancellationPolicy || "",
      // is_feature_available:
      //   (formData.isFeatureAvailable || "No").toString().toLowerCase() ===
      //   "yes",
      // within_24hr_available:
      //   (formData.within24HrAvailable || "No").toString().toLowerCase() ===
      //   "yes",
      // New attributes from Detailed.jsx
      vendor_type: data.vendorTypeName || vendorTypeName || "",
      veg_price: data.veg_price || "",
      non_veg_price: data.non_veg_price || "",
      photo_package_price: data.photo_package_price || "",
      photo_video_package_price: data.photo_video_package_price || "",
      happywedz_since: data.happywedz_since || "",
      travel_info: data.travel_info || "",
      offerings: data.offerings || "",
      delivery_time: data.delivery_time || "",
      decor_policy: data.decorPolicy || "",
      area: data.area || "",
      // Social links
      facebook_link: data.attributes?.facebook_link || "",
      instagram_link: data.attributes?.instagram_link || "",
      twitter_link: data.attributes?.twitter_link || "",
      pinterest_link: data.attributes?.pinterest_link || "",
      website: data.attributes?.website || "",
      // Always include menus if present in attributes
      ...(Array.isArray(data.attributes?.menus)
        ? { menus: data.attributes.menus }
        : {}),

      video: Array.isArray(videoDrafts)
        ? videoDrafts
          .map((v) => v.url || v.preview || "")
          .filter(
            (url) =>
              url &&
              typeof url === "string" &&
              !url.startsWith("blob:") &&
              !url.startsWith("data:")
          )
          .map((url) =>
            url.startsWith("/uploads/") ? IMAGE_BASE_URL + url : url
          )
        : data.attributes?.video || [],
      view360_images: Array.isArray(view360Images)
        ? view360Images
          .map((v) => v.url || v.preview || "")
          .filter(
            (url) =>
              url &&
              typeof url === "string" &&
              !url.startsWith("blob:") &&
              !url.startsWith("data:")
          )
          .map((url) =>
            url.startsWith("/uploads/") ? IMAGE_BASE_URL + url : url
          )
        : [],
      view360_video: Array.isArray(view360Videos)
        ? view360Videos
          .map((v) => v.url || v.preview || "")
          .filter(
            (url) =>
              url &&
              typeof url === "string" &&
              !url.startsWith("blob:") &&
              !url.startsWith("data:")
          )
          .map((url) =>
            url.startsWith("/uploads/") ? IMAGE_BASE_URL + url : url
          )
        : [],
      // Preferred vendors selection
      preferred_vendors:
        data.attributes?.preferred_vendors ||
        data.preferredVendors ||
        data.preferred_vendor_ids ||
        [],
      start_venue: data.start_venue || "",
      space: data.space || "",
      dJ_policy: data.dJ_policy || "",
      availability_active: data.availabilityActive !== false,
    };

    applyMasterProfilesToAttributes(attrs, data);

    // Remove undefined keys
    Object.keys(attrs).forEach(
      (k) => attrs[k] === undefined && delete attrs[k]
    );
    return attrs;
  };

  const buildMedia = () => {
    const gallery = Array.isArray(photoDrafts)
      ? photoDrafts
        .map((p) => {
          const preview = p.preview || p.url || p.path || "";
          return preview || null;
        })
        .filter(Boolean)
      : Array.isArray(formData.media?.gallery)
        ? formData.media.gallery
          .map((g) => (typeof g === "string" ? g : g.url || g.path || null))
          .filter(Boolean)
        : Array.isArray(formData.gallery)
          ? formData.gallery.filter((g) => typeof g === "string")
          : [];
    const media = {
      gallery,
      coverImage: formData.media?.coverImage || formData.coverImage || "",
    };

    return media;
  };

  // Build a flat media array (strings) suitable for sending as `media: [...]`
  const buildMediaArray = () => {
    const m = buildMedia();
    const normalizeUrl = (u) => {
      if (!u || typeof u !== "string") return null;
      // ignore local blob/object URLs (these are client-side previews and should not be sent)
      if (u.startsWith("blob:") || u.startsWith("data:")) return null;
      // prefix relative uploads
      if (u.startsWith("/uploads/")) return IMAGE_BASE_URL + u;
      return u;
    };

    const gallery = Array.isArray(m.gallery)
      ? m.gallery.map(normalizeUrl).filter(Boolean)
      : [];

    // Only include gallery images in the flat media array. Videos are sent under attributes.video
    return gallery;
  };

  const buildFormData = (sourceData) => {
    const data = enrichSaveData(
      sourceData || formDataRef.current || formData
    );
    const fd = new FormData();
    const vendorId = vendor?.id || data.vendor_id;
    if (vendorId) fd.append("vendor_id", `${vendorId}`);
    const subcategoryId =
      data.vendor_subcategory_id || vendor?.vendor_subcategory_id;
    if (subcategoryId) {
      fd.append("vendor_subcategory_id", `${subcategoryId}`);
    }
    const normalizedStatus =
      normalizeServiceStatus(data.status) || "hide";
    fd.append("status", normalizedStatus);

    const attrs = buildAttributes(data);
    // Ensure attributes do not accidentally include a media key
    if (attrs && Object.prototype.hasOwnProperty.call(attrs, "media")) {
      delete attrs.media;
    }

    const mediaArray = buildMediaArray();
    // Ensure mediaArray is a plain array of strings (no blob/data URLs or objects)
    const safeMedia = Array.isArray(mediaArray)
      ? mediaArray.filter((u) => typeof u === "string" && u.trim())
      : [];

    fd.append("attributes", JSON.stringify(attrs));

    // Append social links as root fields for backend compatibility
    const socialFields = [
      "facebook_link",
      "instagram_link",
      "twitter_link",
      "pinterest_link",
      "website",
    ];
    socialFields.forEach((field) => {
      if (attrs[field]) {
        fd.append(field, attrs[field]);
      }
    });

    if (attrs.contact?.phone) {
      fd.append("phone", attrs.contact.phone);
    }
    if (attrs.contact?.email) {
      fd.append("email", attrs.contact.email);
    }
    if (attrs.name) {
      fd.append("name", attrs.name);
    }
    if (attrs.city) {
      fd.append("city", attrs.city);
    }

    // Send `media` as a flat array of URL strings as requested by the frontend contract
    fd.append("media", JSON.stringify(safeMedia));

    // Append media files so backend can store actual uploads
    if (Array.isArray(photoDrafts)) {
      photoDrafts.forEach((p, index) => {
        if (p && p.file instanceof File) {
          fd.append("gallery", p.file, p.file.name || `image_${index}`);
        }
      });
    }
    if (Array.isArray(videoDrafts)) {
      videoDrafts.forEach((v, index) => {
        if (v && v.file instanceof File) {
          fd.append("videos", v.file, v.file.name || `video_${index}`);
        }
      });
    }
    if (Array.isArray(view360Images)) {
      view360Images.forEach((img, index) => {
        if (img && img.file instanceof File) {
          fd.append(
            "view360_images",
            img.file,
            img.file.name || `pano_${index}`
          );
        }
      });
    }
    if (Array.isArray(view360Videos)) {
      view360Videos.forEach((vid, index) => {
        if (vid && vid.file instanceof File) {
          fd.append(
            "view360_video",
            vid.file,
            vid.file.name || `pano_video_${index}`
          );
        }
      });
    }

    // Preserve existing 360 assets outside attributes as URL lists
    const existingPanoImages = Array.isArray(view360Images)
      ? view360Images
        .map((i) => i.preview)
        .filter(
          (u) =>
            typeof u === "string" &&
            u.trim() &&
            !u.startsWith("blob:") &&
            !u.startsWith("data:")
        )
      : [];
    const existingPanoVideos = Array.isArray(view360Videos)
      ? view360Videos
        .map((v) => v.preview)
        .filter(
          (u) =>
            typeof u === "string" &&
            u.trim() &&
            !u.startsWith("blob:") &&
            !u.startsWith("data:")
        )
      : [];

    fd.append("view360_images_urls", JSON.stringify(existingPanoImages));
    fd.append("view360_video_urls", JSON.stringify(existingPanoVideos));

    // Menus are now included only inside attributes for backend compatibility
    return fd;
  };

  const handleSubmit = async () => {
    try {
      const fd = buildFormData();
      let created;
      if (formData.id) {
        created = await vendorServicesApi.createOrUpdateService(
          fd,
          token,
          formData.id
        );
      } else {
        created = await vendorServicesApi.createOrUpdateService(fd, token);
        // If POST succeeded and response has id, update formData with new id for future PUTs
        if (created?.id) {
          setFormData((prev) => ({ ...prev, id: created.id }));
        }
      }
      // On success, persist and show modal
      localStorage.setItem("vendorFormData", JSON.stringify(formData));
      // If API returns media URLs, hydrate previews and clear File blobs
      if (created?.media) {
        // Normalize created.media into an array of URLs
        let normalized = [];
        if (Array.isArray(created.media)) {
          normalized = created.media.filter((x) => typeof x === "string");
        } else if (
          created.media.gallery &&
          Array.isArray(created.media.gallery)
        ) {
          normalized = created.media.gallery.map((g) =>
            typeof g === "string" ? g : g.url || g.path || null
          );
          // also include videos returned under created.media.videos if any
          if (created.media.videos && Array.isArray(created.media.videos)) {
            normalized.push(
              ...created.media.videos.map((v) =>
                typeof v === "string" ? v : v.url || v.path || null
              )
            );
          }
          normalized = normalized.filter(Boolean);
        } else if (created.media && typeof created.media === "object") {
          // fallback: try to extract any string URLs from the object
          const vals = Object.values(created.media).flat();
          normalized = vals.filter((v) => typeof v === "string");
        }

        // Hydrate previews for photos and videos from normalized array (strings)
        if (normalized.length) {
          setPhotoDrafts((prev) =>
            prev.map((p, i) => ({
              ...p,
              preview: normalized[i] || p.preview,
              file: null,
            }))
          );
          setVideoDrafts((prev) =>
            prev.map((v, i) => ({
              ...v,
              preview: normalized[prev.length + i] || v.preview,
              file: null,
            }))
          );
        }
      }
      setShowModal(true);
    } catch (e) {
      // alert(
      //   `Failed to submit. ${
      //     typeof e === "string" ? e : e?.message || "Unknown error"
      //   }`
      // );
      Swal.fire({
        icon: "error",
        title: "Oops...",
        text: `Failed to submit. ${typeof e === "string" ? e : e?.message || "Unknown error"
          }`,
        timer: "3000",
        confirmButtonText: "OK",
        confirmButtonColor: "#C31162",
      });
    }
  };

  // Only show Menus sidebar for vendorTypeName 'Venues' or 'Caterers' (case-insensitive)
  const isCatererType = useMemo(() => {
    const typeLower = (vendorTypeName || "").toLowerCase();
    return (
      typeLower.includes("cater") ||
      typeLower.includes("food") ||
      typeLower.includes("tiffin") ||
      typeLower.includes("kitchen") ||
      typeLower.includes("meal") ||
      typeLower.includes("cake") ||
      typeLower.includes("bakery")
    );
  }, [vendorTypeName]);

  const isVenueType = useMemo(() => {
    const typeLower = (vendorTypeName || "").toLowerCase();
    return (
      typeLower.includes("venue") ||
      typeLower.includes("marriage garden") ||
      typeLower.includes("banquet") ||
      typeLower.includes("resort") ||
      typeLower.includes("hotel") ||
      typeLower.includes("lawn") ||
      typeLower.includes("palace") ||
      typeLower.includes("fort")
    );
  }, [vendorTypeName]);

  const allowedMenuTypes = React.useMemo(() => ["venues", "caterers"], []);
  const showMenusTab = isVenueType || isCatererType;
  const normalizedVendorTypeName = (vendorTypeName || "").trim().toLowerCase();

  // Calculate completion percentage
  const calculateCompletion = useCallback(() => {
    const sections = [
      { id: "business", fields: ["attributes.Name", "attributes.about_us"] },
      {
        id: "vendor-basic",
        fields: ["attributes.vendor_name", "attributes.tagline"],
      },
      // FAQ handled specially below
      { id: "faq", fields: [] },
      {
        id: "vendor-contact",
        fields: ["contact.contactName", "contact.phone", "contact.email"],
      },
      {
        id: "vendor-location",
        fields: ["location.city", "location.state", "location.addressLine1"],
      },
      { id: "photos", fields: ["photoDrafts"] },
      { id: "videos", fields: ["videoDrafts"] },
      {
        id: "vendor-pricing",
        fields: ["startingPrice", "priceRange.min", "priceRange.max"],
      },
      { id: "vendor-facilities", fields: [] },
      { id: "promotions", fields: ["deals"] },
      {
        id: "vendor-policies",
        fields: ["tnc", "cancellationPolicy", "refundPolicy"],
      },
      // { id: "vendor-availability", fields: ["timing.open", "timing.close"] },
      { id: "vendor-availability", fields: ["attributes.available_slots"] },
      { id: "vendor-marketing", fields: ["primaryCTA"] },
    ];

    if (showMenusTab) {
      sections.push({ id: "vendor-menus", fields: ["attributes.menus"] });
    }

    const venueMasterHasData = (vm) => {
      if (!vm || typeof vm !== "object") return false;
      const walk = (obj) => {
        for (const v of Object.values(obj)) {
          if (v == null) continue;
          if (typeof v === "string" && v.trim()) return true;
          if (typeof v === "number" && !Number.isNaN(v)) return true;
          if (Array.isArray(v)) {
            for (const item of v) {
              if (item == null) continue;
              if (typeof item === "object" && walk(item)) return true;
              if (typeof item === "string" && item.trim()) return true;
              if (typeof item === "number" && !Number.isNaN(item)) return true;
            }
          } else if (typeof v === "object" && walk(v)) return true;
        }
        return false;
      };
      return walk(vm);
    };

    let completed = 0;
    sections.forEach((section) => {
      let hasData = false;
      if (section.id === "vendor-facilities") {
        if (isVenueType) {
          const vm =
            formData.venue_master || formData.attributes?.venue_master;
          hasData = venueMasterHasData(vm);
        } else if (isCatererType) {
          const cm =
            formData.caterer_master || formData.attributes?.caterer_master;
          hasData = venueMasterHasData(cm);
        } else if (normalizedVendorTypeName.includes("photograph")) {
          const pm =
            formData.photographer_master ||
            formData.attributes?.photographer_master;
          hasData = venueMasterHasData(pm);
        } else if (
          normalizedVendorTypeName.includes("makeup") ||
          (normalizedVendorTypeName.includes("bridal") &&
            normalizedVendorTypeName.includes("artist")) ||
          normalizedVendorTypeName.includes("mua")
        ) {
          const mum =
            formData.makeup_artist_master ||
            formData.attributes?.makeup_artist_master;
          hasData = venueMasterHasData(mum);
        } else if (
          normalizedVendorTypeName.includes("jewell") ||
          normalizedVendorTypeName.includes("jewelry") ||
          normalizedVendorTypeName.includes("accessor")
        ) {
          const jm =
            formData.jewellery_master ||
            formData.accessories_master ||
            formData.flower_jewellery_master ||
            formData.attributes?.jewellery_master ||
            formData.attributes?.accessories_master ||
            formData.attributes?.flower_jewellery_master;
          hasData = venueMasterHasData(jm);
        } else {
          hasData = !!(
            formData.happywedz_since ||
            formData.offerings ||
            formData.travel_info ||
            formData.delivery_time
          );
        }
      } else if (section.id === "faq") {
        // Count FAQ completed only if at least one non-empty answer exists
        const faqs = formData?.faqs;
        if (faqs && typeof faqs === "object") {
          hasData = Object.values(faqs).some((ans) => {
            if (ans == null) return false;
            if (Array.isArray(ans)) return ans.filter(Boolean).length > 0;
            if (typeof ans === "object") return Object.keys(ans).length > 0;
            const s = String(ans).trim();
            return s.length > 0;
          });
        }
      } else {
        hasData = section.fields.some((field) => {
          if (field === "photoDrafts") return photoDrafts.length > 0;
          if (field === "videoDrafts") return videoDrafts.length > 0;
          const keys = field.split(".");
          let value = formData;
          for (const key of keys) {
            value = value?.[key];
          }
          return value && value !== "" && value !== null && value !== undefined;
        });
      }
      if (hasData) completed++;
    });

    const percentage = Math.round((completed / sections.length) * 100);
    return percentage;
  }, [
    formData,
    photoDrafts,
    videoDrafts,
    normalizedVendorTypeName,
    allowedMenuTypes,
  ]);

  useEffect(() => {
    const percentage = calculateCompletion();
    if (setCompletion) setCompletion(percentage);
    // Also save to localStorage so it persists across navigation
    localStorage.setItem("storefrontCompletion", percentage.toString());

    // Send completion percentage to backend API
    const sendCompletionToBackend = async () => {
      if (!formData.id || !token) return;
      try {
        await axiosInstance.put(
          `/vendor-services/${formData.id}/storefront-completion`,
          { completion: percentage },
          {
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${token}`,
            },
          }
        );
      } catch (error) {
        console.error("Error sending storefront completion to backend:", error);
      }
    };

    sendCompletionToBackend();
  }, [calculateCompletion, setCompletion, formData.id, token]);

  const contentRef = React.useRef(null);
  // Helper to set active tab and persist selection
  const handleSetActive = useCallback(
    (id) => {
      setActive(id);
      try {
        localStorage.setItem(storageKey, id);
      } catch (_) { }
      // Always scroll to top when any left section is clicked
      window.scrollTo({
        top: 0,
        left: 0,
        behavior: "smooth",
      });
    },
    [storageKey]
  );

  const menuItems = [
    {
      id: "business",
      label: "Business details",
      icon: <MdOutlineAccountBalance size={20} />,
    },
    {
      id: "vendor-basic",
      label: "Basic Information",
      icon: <IoIosInformationCircleOutline size={20} />,
    },
    { id: "faq", label: "FAQ", icon: <CiCircleQuestion size={20} /> },
    {
      id: "vendor-contact",
      label: "Contact Details",
      icon: <PiPhoneCall size={20} />,
    },
    {
      id: "vendor-location",
      label: "Location & Service Areas",
      icon: <CiLocationOn size={20} />,
    },
    { id: "photos", label: "Photos", icon: <IoCameraOutline size={20} /> },
    ...(isVenueType
      ? [
        {
          id: "vendor-360-view",
          label: (
            <div className="d-flex align-items-center">
              <span>360° View</span>
              <span className="ms-2">
                <NewTag />
              </span>
            </div>
          ),
          icon: <TbView360Number size={20} />,
        },
      ]
      : []),
    { id: "videos", label: "Videos", icon: <IoVideocamOutline size={20} /> },

    {
      id: "preferred-vendors",
      label: "Preferred Vendors",
      icon: <IoCheckmarkCircleOutline size={20} />,
    },
    {
      id: "social",
      label: "Social Network",
      icon: <PiShareNetworkDuotone size={20} />,
    },

    {
      id: "vendor-facilities",
      label: "Facilities & Features",
      icon: <IoCheckmarkCircleOutline size={20} />,
    },
    ...(showMenusTab
      ? [
        {
          id: "vendor-menus",
          label: "Menus",
          icon: <PiForkKnife size={20} />,
        },
      ]
      : []),

    { id: "promotions", label: "Promotions", icon: <CiBullhorn size={20} /> },
    {
      id: "vendor-policies",
      label: "Policies & Terms",
      icon: <HiOutlineDocument size={20} />,
    },
    {
      id: "vendor-availability",
      label: "Availability & Slots",
      icon: <MdOutlineEventAvailable size={20} />,
    },

    // {
    //   id: "social",
    //   label: "Social Media",
    //   icon: <FaShareAlt size={20} />,
    // },

    // {
    //   id: "vendor-marketing",
    //   label: "Marketing & CTA",
    //   icon: <GoGift size={20} />,
    // },
    {
      id: "vendor-pricing",
      label: "Pricing & Packages",
      icon: <MdCurrencyRupee size={20} />,
    },
  ];

  // Scroll to top on mount
  useEffect(() => {
    window.scrollTo({ top: 0, left: 0, behavior: "instant" });
  }, []);

  // Restore stored active tab once menu items are known/updated
  useEffect(() => {
    try {
      let stored = localStorage.getItem(storageKey);
      const legacyMasterTabs = new Set([
        "venue-master",
        "caterer-master",
        "photographer-master",
      ]);
      if (stored && legacyMasterTabs.has(stored)) {
        stored = "vendor-facilities";
        localStorage.setItem(storageKey, stored);
      }
      const ids = new Set(menuItems.map((m) => m.id));
      if (stored && ids.has(stored)) {
        if (active !== stored) setActive(stored);
      } else if (!ids.has(active)) {
        setActive("business");
      }
    } catch (_) {
      if (active !== "business") setActive("business");
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [storageKey, normalizedVendorTypeName]);

  const renderContent = () => {
    switch (active) {
      case "business":
        return (
          <BusinessDetails
            formData={formData}
            setFormData={setFormData}
            onShowSuccess={showSuccessModal}
            onSaveSuccess={fetchServiceData}
          />
        );
      case "faq":
        return (
          <Faq
            formData={formData}
            setFormData={setFormData}
            onSave={handleSave}
            onShowSuccess={showSuccessModal}
          />
        );
      case "vendor-basic":
        return (
          <VendorBasicInfo
            formData={formData}
            setFormData={setFormData}
            onSave={handleSave}
            onSaveSuccess={fetchServiceData}
            onShowSuccess={showSuccessModal}
          />
        );
      case "vendor-contact":
        return (
          <VendorContact
            formData={formData}
            setFormData={setFormData}
            onSave={handleSave}
            onShowSuccess={showSuccessModal}
          />
        );
      case "vendor-location":
        return (
          <VendorLocation
            formData={formData}
            setFormData={setFormData}
            onSave={handleSave}
            onShowSuccess={showSuccessModal}
            vendorTypeName={vendorTypeName}
          />
        );
      case "photos":
        return (
          <PhotoGallery
            images={photoDrafts}
            onImagesChange={setPhotoDrafts}
            onShowSuccess={showSuccessModal}
            // onSave={(media) => {
            //   const drafts = (media || []).map((m) => {
            //     if (m instanceof File) {
            //       return {
            //         file: m,
            //         preview: URL.createObjectURL(m),
            //       };
            //     }
            //     if (typeof m === "string") {
            //       let preview = m;
            //       if (preview.startsWith("/uploads/"))
            //         preview = IMAGE_BASE_URL + preview;
            //       return { preview, file: null };
            //     }
            //     return {
            //       preview: m.preview || m.url || "",
            //       file: m.file || null,
            //     };
            //   });
            //   setPhotoDrafts(drafts.filter((d) => d.preview));
            // }}
            onSave={handleSave}
          />
        );
      case "videos":
        return (
          <VideoGallery
            videos={videoDrafts}
            onVideosChange={setVideoDrafts}
            onShowSuccess={showSuccessModal}
            onSave={handleSave}
          />
        );
      case "vendor-360-view":
        return (
          <View360
            images={view360Images}
            setImages={setView360Images}
            videos={view360Videos}
            setVideos={setView360Videos}
            onSave={handleSave}
            onShowSuccess={showSuccessModal}
          />
        );
      case "promotions":
        return (
          <PromoForm
            formData={formData}
            setFormData={setFormData}
            onSave={handleSave}
            onShowSuccess={showSuccessModal}
          />
        );
      case "vendor-pricing":
        return (
          <VendorPricing
            formData={formData}
            setFormData={setFormData}
            onSave={handleSave}
            onShowSuccess={showSuccessModal}
            onSubmit={handleSubmit}
            vendorTypeName={vendorTypeName}
          />
        );
      case "vendor-facilities": {
        return (
          <VendorFacilities
            formData={formData}
            setFormData={setFormData}
            onSave={handleSave}
            onShowSuccess={showSuccessModal}
            vendorTypeName={vendorTypeName}
            isVenue={isVenueType}
            isCaterer={isCatererType}
          />
        );
      }
      case "vendor-policies":
        return (
          <VendorPolicies
            formData={formData}
            setFormData={setFormData}
            onSave={handleSave}
            onShowSuccess={showSuccessModal}
          />
        );
      case "social":
        return (
          <SocialDetails
            formData={formData}
            setFormData={setFormData}
            onSave={handleSave}
            onShowSuccess={showSuccessModal}
          />
        );
      case "preferred-vendors":
        return (
          <PreferredVendors
            formData={formData}
            setFormData={setFormData}
            onSave={handleSave}
            onShowSuccess={showSuccessModal}
          />
        );
      case "vendor-availability":
        return (
          <VendorAvailability
            formData={formData}
            setFormData={setFormData}
            onSave={handleSave}
            onShowSuccess={showSuccessModal}
          />
        );
      case "vendor-menus":
        return (
          <VendorMenus
            formData={formData}
            setFormData={setFormData}
            onSave={handleSave}
            onShowSuccess={showSuccessModal}
          />
        );
      // case "social":
      //   return (
      //     <SocialDetails
      //       formData={formData}
      //       setFormData={setFormData}
      //       onSave={handleSave}
      //       onShowSuccess={showSuccessModal}
      //     />
      //   );
      // case "vendor-marketing":
      //   return (
      //     <VendorMarketing
      //       formData={formData}
      //       setFormData={setFormData}
      //       onSave={handleSave}
      //       onShowSuccess={showSuccessModal}
      //       onSubmit={handleSubmit}
      //     />
      //   );
      default:
        return (
          <div className="p-3 border rounded bg-white">
            <p>Content for {active}</p>
          </div>
        );
    }
  };

  const completionPercentage = calculateCompletion();

  return (
    <div className="container py-3 store-front-navbar">
      <div className="row g-4">
        <div className="col-lg-3 col-md-4">
          <div className="storefront-sidebar-card">
            <Nav className="flex-column custom-sidebar">
              {menuItems.map((item) => (
                <Nav.Link
                  key={item.id}
                  onClick={() => handleSetActive(item.id)}
                  className={`sidebar-nav-item ${
                    active === item.id ? "active" : ""
                  }`}
                >
                  {item.icon}
                  <span>{item.label}</span>
                </Nav.Link>
              ))}
            </Nav>
          </div>
        </div>

        <div className="col-lg-9 col-md-8 storefront-content-area" ref={contentRef}>
          {renderContent()}
        </div>
      </div>

      <SuccessModal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        message="Your details have been saved successfully!"
      />
    </div>
  );
};

export default Storefront;
