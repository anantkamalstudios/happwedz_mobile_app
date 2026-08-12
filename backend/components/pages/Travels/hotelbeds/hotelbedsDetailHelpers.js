const createCorrelationId = () => {
  if (typeof globalThis.crypto?.randomUUID === "function") {
    return globalThis.crypto.randomUUID();
  }
  return `corr-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
};

const parseDateInput = (value) => {
  if (!value) return null;
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value;
  }

  const normalized = String(value).trim();
  const match = normalized.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (match) {
    const [, year, month, day] = match;
    const date = new Date(Number(year), Number(month) - 1, Number(day));
    return Number.isNaN(date.getTime()) ? null : date;
  }

  const fallback = new Date(normalized);
  return Number.isNaN(fallback.getTime()) ? null : fallback;
};

const formatMoney = (value, currency = "INR", compact = false) => {
  const amount = Number(value);
  if (!Number.isFinite(amount)) return "Price not available";
  const localeCurrency = currency === "INR" ? "INR" : currency;
  const formatted = new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: localeCurrency,
    maximumFractionDigits: 0,
  }).format(amount);
  return compact ? formatted.replace("₹", "₹") : formatted;
};

const formatDate = (value) => {
  if (!value) return "Select date";
  const date = parseDateInput(value);
  if (!date) return value;
  return date.toLocaleDateString("en-GB", {
    weekday: "short",
    day: "numeric",
    month: "short",
    year: "numeric",
  });
};

const parseJsonSafely = (value) => {
  if (!value || typeof value !== "string") return null;
  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
};

const dedupeStrings = (values) => {
  const seen = new Set();
  return values.filter((value) => {
    const normalized = String(value || "").trim();
    if (!normalized) return false;
    const key = normalized.toLowerCase();
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
};

const dedupeImages = (values) => {
  const seen = new Set();
  return values.filter((item) => {
    const url = String(item?.url || item || "").trim();
    if (!url) return false;
    if (seen.has(url)) return false;
    seen.add(url);
    return true;
  });
};

const normalizeImageItems = (items) =>
  dedupeImages(
    (Array.isArray(items) ? items : [])
      .map(
        (item) =>
          item?.url ||
          item?.imageUrl ||
          item?.path ||
          item?.links?.original?.href ||
          item?.links?.Original?.href ||
          item?.links?.Standard?.href ||
          item?.links?.XXL?.href ||
          item?.links?.XL?.href ||
          item?.links?.L?.href ||
          item?.links?.[0]?.url ||
          item,
      )
      .filter(Boolean)
      .map((url) => ({ url })),
  );

const escapeRegExp = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const parseJsonObjectSafely = (value) => {
  const parsed = parseJsonSafely(value);
  return parsed && typeof parsed === "object" ? parsed : {};
};

// TripJack policy fields (special_instructions, know_before_you_go, mandatory_fees)
// arrive as a stringified JSON object of { label: text }. Normalize them into a
// flat list of { label, text } entries for display. Plain strings are also handled.
const parsePolicyEntries = (value) => {
  if (!value) return [];
  const parsed = parseJsonSafely(value);
  if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
    return Object.entries(parsed)
      .map(([label, text]) => ({
        label: String(label || "").replace(/_/g, " ").trim(),
        text: String(text || "").replace(/\s+/g, " ").trim(),
      }))
      .filter((entry) => entry.text);
  }
  const text = String(value).replace(/\s+/g, " ").trim();
  return text ? [{ label: "", text }] : [];
};

const buildAddressParts = (address = {}) =>
  [
    address?.adr,
    address?.adr2,
    address?.ctn || address?.city?.name,
    address?.sn || address?.state?.name,
    address?.postalCode,
    address?.cn || address?.country?.name,
  ].filter(Boolean);

const buildAddressLabel = (address = {}) => buildAddressParts(address).join(", ");

const normalizeLookupKey = (value) => String(value || "").trim().toLowerCase();

const getRoomIdentity = (roomInfo = {}, roomMeta = {}) => ({
  roomId: String(roomInfo?.id || roomInfo?.rid || roomInfo?.roomId || roomMeta?.rid || "").trim(),
  roomName: String(roomInfo?.srn || roomInfo?.rt || roomInfo?.rc || roomInfo?.name || roomMeta?.name || "").trim(),
});

const getRoomMetadata = (hotelInfo, roomInfo) => {
  const roomId = String(roomInfo?.id || roomInfo?.rid || roomInfo?.roomId || "").trim();
  const roomMetaMap = hotelInfo?.oprmd || hotelInfo?.roomMeta || {};
  if (roomId && roomMetaMap?.[roomId]) {
    return roomMetaMap[roomId];
  }

  if (roomId && roomMetaMap && typeof roomMetaMap === "object") {
    const matchedEntry = Object.values(roomMetaMap).find((roomMeta) => {
      const metaRoomId = String(roomMeta?.rid || roomMeta?.id || roomMeta?.roomId || "").trim();
      if (metaRoomId && metaRoomId === roomId) return true;
      return Array.isArray(roomMeta?.imgs)
        ? roomMeta.imgs.some((image) =>
            (Array.isArray(image?.rids) ? image.rids : []).map(String).includes(roomId)
          )
        : false;
    });
    if (matchedEntry) return matchedEntry;
  }

  return roomInfo || {};
};

const getRoomBedSummary = (roomMeta) => {
  const beds = Array.isArray(roomMeta?.bds)
    ? roomMeta.bds
    : Array.isArray(roomMeta?.radi?.bds)
      ? roomMeta.radi.bds
      : [];

  if (beds.length === 0) return "";

  return beds
    .map((bed) => `${bed?.bc || 1} ${bed?.bt || "Bed"}`.trim())
    .filter(Boolean)
    .join(", ");
};

const getRoomGuestSummary = (roomMeta, roomInfo) => {
  const maxGuests = Number(roomMeta?.mga ?? roomMeta?.radi?.mga ?? roomInfo?.mga ?? 0);
  const maxAdults = Number(roomMeta?.maa ?? roomMeta?.radi?.maa ?? roomInfo?.adt ?? 0);
  const maxChildren = Number(roomMeta?.mca ?? roomMeta?.radi?.mca ?? roomInfo?.chd ?? 0);

  if (!maxGuests && !maxAdults && !maxChildren) return "";

  const parts = [];
  if (maxGuests) parts.push(`Fits max. ${maxGuests} guest${maxGuests > 1 ? "s" : ""}`);
  else if (maxAdults) parts.push(`${maxAdults} adult${maxAdults > 1 ? "s" : ""}`);
  if (maxChildren) parts.push(`${maxChildren} child${maxChildren > 1 ? "ren" : ""}`);
  return parts.join(" • ");
};

const getCancellationLabel = (cnp) => {
  if (cnp?.ifra === true) return "Refundable";
  if (cnp?.inra === true) return "Non-refundable";
  if (cnp?.isRefundable === true) return "Refundable";
  return "Cancellation policy";
};

const getCancellationPenalties = (cnp) =>
  Array.isArray(cnp?.pd)
    ? cnp.pd.map((penalty) => ({
        from: penalty?.fdt || penalty?.from || "",
        to: penalty?.tdt || penalty?.to || "",
        amount: penalty?.am ?? penalty?.amount ?? "",
      }))
    : Array.isArray(cnp?.penalties)
      ? cnp.penalties
      : [];

const getNightCount = (searchPayload) => {
  const checkin = parseDateInput(searchPayload?.searchQuery?.checkinDate || searchPayload?.searchQuery?.checkInDate);
  const checkout = parseDateInput(searchPayload?.searchQuery?.checkoutDate || searchPayload?.searchQuery?.checkOutDate);
  if (!checkin || !checkout) return 1;
  const diff = Math.round((checkout.getTime() - checkin.getTime()) / 86400000);
  return diff > 0 ? diff : 1;
};

const getRoomImages = (roomMeta) =>
  normalizeImageItems([
    ...(Array.isArray(roomMeta?.img) ? roomMeta.img.flatMap((item) => item?.links || item) : []),
    ...(Array.isArray(roomMeta?.imgs) ? roomMeta.imgs : []),
  ]);

const getStaticRoomEntries = (staticHotel = {}) => {
  const rooms = staticHotel?.rooms;
  if (Array.isArray(rooms)) return rooms;
  if (rooms && typeof rooms === "object") return Object.values(rooms);
  return [];
};

const getStaticRoomImages = (staticRoom = {}) =>
  normalizeImageItems([
    ...(Array.isArray(staticRoom?.images) ? staticRoom.images : []),
    ...(Array.isArray(staticRoom?.img) ? staticRoom.img : []),
  ]);

const getStaticRoomAmenities = (staticRoom = {}) =>
  dedupeStrings([
    ...Object.values(staticRoom?.amenities || {}).map((item) => item?.name || item),
    ...(Array.isArray(staticRoom?.facilities) ? staticRoom.facilities.map((item) => item?.name || item) : []),
  ]);

const getStaticRoomBedSummary = (staticRoom = {}) => {
  const bedConfig = staticRoom?.bed_config || {};

  // Preferred: human-readable summary supplied by TripJack (docs: bed_config.description).
  const description = String(bedConfig?.description || "").trim();
  if (description) return description;

  // v3 shape: configuration is a map of { type, size, quantity }.
  const configuration = bedConfig?.configuration;
  if (configuration && typeof configuration === "object" && !Array.isArray(configuration)) {
    const summary = Object.values(configuration)
      .map((bed) => {
        const quantity = Number(bed?.quantity || bed?.count || bed?.bed_count || 0);
        const rawLabel = String(bed?.type || bed?.name || bed?.size || "").trim();
        // "KingBed" -> "King Bed"
        const label = rawLabel.replace(/([a-z])([A-Z])/g, "$1 $2").trim();
        if (!label && quantity <= 0) return "";
        if (quantity <= 0) return label;
        return `${quantity} ${label || "Bed"}`;
      })
      .filter(Boolean)
      .join(", ");
    if (summary) return summary;
  }

  // Legacy shape.
  const bedTypes = Array.isArray(bedConfig?.bed_types) ? bedConfig.bed_types : [];
  if (bedTypes.length === 0) return "";
  return bedTypes
    .map((bed) => `${bed?.count || bed?.bed_count || 1} ${bed?.name || bed?.type || "Bed"}`.trim())
    .filter(Boolean)
    .join(", ");
};

const getStaticRoomGuestSummary = (staticRoom = {}) => {
  const max = staticRoom?.occupancy?.max_allowed || {};
  const total = Number(max?.total || 0);
  const adults = Number(max?.adults || 0);
  const children = Number(max?.children || 0);
  if (!total && !adults && !children) return "";

  const parts = [];
  if (total) parts.push(`Fits max. ${total} guest${total > 1 ? "s" : ""}`);
  else if (adults) parts.push(`${adults} adult${adults > 1 ? "s" : ""}`);
  if (children) parts.push(`${children} child${children > 1 ? "ren" : ""}`);
  return parts.join(" • ");
};

// Loose key for room-name matching: lowercase, drop generic words ("room",
// "double", "twin", etc.) and punctuation so "Royal Deluxe Room" matches the
// static content's "Royal Deluxe".
const normalizeRoomNameKey = (value) =>
  String(value || "")
    .toLowerCase()
    .replace(/\b(room|rooms|double|twin|king|queen|single|bed|non-?smoking|smoking|with|or)\b/g, " ")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();

const findStaticRoomMatch = (staticHotel, roomInfo, roomMeta = {}) => {
  const staticRooms = getStaticRoomEntries(staticHotel);
  if (staticRooms.length === 0) return null;

  const { roomId, roomName } = getRoomIdentity(roomInfo, roomMeta);
  const roomNameKey = normalizeLookupKey(roomName);
  const looseKey = normalizeRoomNameKey(roomName);

  return (
    // 1. Exact id match.
    staticRooms.find((room) => roomId && String(room?.id || room?.rid || room?.roomId || "").trim() === roomId) ||
    // 2. Exact (lowercased) name match.
    staticRooms.find((room) => normalizeLookupKey(room?.name) === roomNameKey) ||
    // 3. Loose name match (ignores generic words / suffixes), only if it has amenities to offer.
    (looseKey
      ? staticRooms.find((room) => {
          const staticKey = normalizeRoomNameKey(room?.name);
          if (!staticKey) return false;
          return staticKey === looseKey || staticKey.includes(looseKey) || looseKey.includes(staticKey);
        })
      : null) ||
    null
  );
};

const ROOM_DESCRIPTION_SECTION_LABELS = [
  "Layout",
  "Internet",
  "Entertainment",
  "Food & Drink",
  "Sleep",
  "Bathroom",
  "Practical",
  "Comfort",
  "Need to Know",
  "Accessibility",
];

const normalizeRoomAmenityText = (value) => {
  const text = String(value || "").replace(/\s+/g, " ").trim().replace(/[.]+$/, "");
  if (!text) return "";
  if (/^cable channels$/i.test(text)) return "Television";
  if (/^climate-controlled air conditioning$/i.test(text)) {
    return "In-room climate control (air conditioning)";
  }
  return text;
};

const parseRoomDescriptionAmenities = (description) => {
  const raw = String(description || "").replace(/\s+/g, " ").trim();
  if (!raw) return [];

  let normalized = raw;
  ROOM_DESCRIPTION_SECTION_LABELS.forEach((label) => {
    normalized = normalized.replace(
      new RegExp(`\\s*${escapeRegExp(label)}\\s*-\\s*`, "gi"),
      `|||${label}:::`,
    );
  });
  normalized = normalized.replace(/\s+(Non-Smoking|Smoking)\b/gi, "|||$1");

  return normalized
    .split("|||")
    .slice(1)
    .flatMap((section) => {
      const [label, body = ""] = section.split(":::");
      const normalizedLabel = normalizeRoomAmenityText(label);
      if (!body && /^(non-smoking|smoking)$/i.test(normalizedLabel)) {
        return [normalizedLabel];
      }
      return body
        .split(/,|;|\band\b/gi)
        .map(normalizeRoomAmenityText)
        .filter(Boolean);
    });
};

const getRoomAmenities = (roomMeta, roomInfo = {}) =>
  dedupeStrings([
    ...(Array.isArray(roomMeta?.fcs) ? roomMeta.fcs : []),
    ...(Array.isArray(roomMeta?.am) ? roomMeta.am.map((item) => item?.name || item) : []),
    ...(Array.isArray(roomMeta?.rexb?.BENEFIT)
      ? roomMeta.rexb.BENEFIT.flatMap((item) => item?.values || [])
      : []),
    ...parseRoomDescriptionAmenities(roomMeta?.des || roomInfo?.des || roomMeta?.radi?.des || ""),
  ]);

const getRoomMealBasis = (option, roomInfo) => option?.mb || roomInfo?.mb || "Room Only";

const getOptionPanRequired = (hotelInfo, option, optionIndex) => {
  if (hotelInfo?.panRequired === true) return true;
  if (Array.isArray(hotelInfo?.filters?.panRequired)) {
    return hotelInfo.filters.panRequired.includes(optionIndex) ||
      hotelInfo.filters.panRequired.includes(option?.id)
      ? true
      : false;
  }
  return false;
};

const getOptionPanOptional = (hotelInfo, option, optionIndex) => {
  if (Array.isArray(hotelInfo?.filters?.panNotRequired)) {
    return hotelInfo.filters.panNotRequired.includes(optionIndex) ||
      hotelInfo.filters.panNotRequired.includes(option?.id)
      ? true
      : false;
  }
  return !getOptionPanRequired(hotelInfo, option, optionIndex);
};

const getOptionTotalPrice = (option, roomInfo) =>
  Number(
    option?.totalPrice ??
      option?.tp ??
      option?.pricing?.totalPrice ??
      roomInfo?.totalPrice ??
      roomInfo?.tp ??
      0,
  );

const getOptionNightlyPrice = (option, roomInfo, nights) => {
  const direct = Number(option?.nightlyPrice ?? roomInfo?.nightlyPrice ?? 0);
  if (Number.isFinite(direct) && direct > 0) return direct;
  const total = getOptionTotalPrice(option, roomInfo);
  return total > 0 ? total / Math.max(1, nights) : 0;
};

const normalizeRoomOption = (
  option,
  optionIndex,
  hotelInfo,
  nights,
  staticHotel = {},
  fallbackRoomImages = [],
) => {
  const roomInfo = option?.roomInfos?.[0] || option?.ris?.[0] || option?.roomInfo?.[0] || {};
  const roomMeta = getRoomMetadata(hotelInfo, roomInfo);
  const staticRoom = findStaticRoomMatch(staticHotel, roomInfo, roomMeta);
  const roomSpecificImages = dedupeImages([...getRoomImages(roomMeta), ...getStaticRoomImages(staticRoom)]);
  const images = roomSpecificImages.length > 0 ? roomSpecificImages : dedupeImages(fallbackRoomImages);
  const amenities = dedupeStrings([
    ...getRoomAmenities(roomMeta, roomInfo),
    ...getStaticRoomAmenities(staticRoom),
  ]);
  const totalPrice = getOptionTotalPrice(option, roomInfo);
  const nightlyPrice = getOptionNightlyPrice(option, roomInfo, nights);
  const mealBasis = getRoomMealBasis(option, roomInfo);
  const cancellation = option?.cnp || option?.cancellation || roomInfo?.cnp || {};
  const roomName = roomInfo?.srn || roomInfo?.rt || roomInfo?.rc || roomInfo?.name || "Room";
  const supplierRoomType = roomInfo?.rc || roomInfo?.rt || roomName;
  const staticBedSummary = getStaticRoomBedSummary(staticRoom);

  return {
    id: String(option?.id || option?.optionId || `${optionIndex}`),
    optionIndex,
    roomId: String(roomInfo?.id || roomInfo?.rid || roomMeta?.rid || `${optionIndex}`),
    roomName,
    supplierRoomType,
    mealBasis,
    totalPrice: Number.isFinite(totalPrice) && totalPrice > 0 ? totalPrice : null,
    nightlyPrice: Number.isFinite(nightlyPrice) && nightlyPrice > 0 ? nightlyPrice : null,
    currency: option?.currency || option?.sc || option?.pricing?.currency || roomInfo?.currency || "INR",
    cancellation,
    cancellationLabel: getCancellationLabel(cancellation),
    cancellationPenalties: getCancellationPenalties(cancellation),
    refundable: cancellation?.ifra === true || cancellation?.isRefundable === true,
    nonRefundable: cancellation?.inra === true,
    panRequired: getOptionPanRequired(hotelInfo, option, optionIndex),
    panOptional: getOptionPanOptional(hotelInfo, option, optionIndex),
    passportRequired: Boolean(option?.compliance?.passportRequired ?? hotelInfo?.passportRequired),
    adults: Number(roomInfo?.adt || roomInfo?.adults || 0),
    children: Number(roomInfo?.chd || roomInfo?.children || 0),
    bedSummary: getRoomBedSummary(roomMeta) || staticBedSummary,
    guestSummary:
      getRoomGuestSummary(roomMeta, roomInfo) || getStaticRoomGuestSummary(staticRoom),
    images,
    image: images[0]?.url || "",
    amenities,
    view: Array.isArray(roomMeta?.vw)
      ? roomMeta.vw.join(", ")
      : Array.isArray(roomMeta?.radi?.vi)
        ? roomMeta.radi.vi.join(", ")
        : "",
    raw: option,
    roomInfo,
    roomMeta,
    staticRoom,
  };
};

const extractDetailHotelRoot = (payload) =>
  (Array.isArray(payload?.options)
    ? {
        id: String(payload?.hotelId || payload?.tjHotelId || ""),
        tjid: String(payload?.hotelId || payload?.tjHotelId || ""),
        tjHotelId: String(payload?.hotelId || payload?.tjHotelId || ""),
        name: payload?.hotelName || "",
        panRequired: Array.isArray(payload?.options)
          ? payload.options.some((opt) => opt?.compliance?.panRequired === true)
          : false,
        passportRequired: Array.isArray(payload?.options)
          ? payload.options.some((opt) => opt?.compliance?.passportRequired === true)
          : false,
        ops: payload.options.map((opt) => ({
          id: opt?.optionId,
          optionId: opt?.optionId,
          optionType: opt?.optionType,
          roomInfos: Array.isArray(opt?.roomInfo)
            ? opt.roomInfo.map((ri) => ({
                id: ri?.id || null,
                name: ri?.name || "",
                rt: ri?.name || "",
                rc: ri?.name || "",
                srn: ri?.name || "",
                adt: Number(ri?.adults || 0),
                chd: Number(ri?.children || 0),
              }))
            : [],
          ris: Array.isArray(opt?.roomInfo)
            ? opt.roomInfo.map((ri) => ({
                id: ri?.id || null,
                name: ri?.name || "",
                rt: ri?.name || "",
                rc: ri?.name || "",
                srn: ri?.name || "",
                adt: Number(ri?.adults || 0),
                chd: Number(ri?.children || 0),
              }))
            : [],
          inclusions: Array.isArray(opt?.inclusions) ? opt.inclusions : [],
          mb: opt?.mealBasis || "Room Only",
          mealBasis: opt?.mealBasis || "Room Only",
          tp: Number(opt?.pricing?.totalPrice || 0),
          totalPrice: Number(opt?.pricing?.totalPrice || 0),
          pricing: opt?.pricing || {},
          sc: opt?.pricing?.currency || "INR",
          currency: opt?.pricing?.currency || "INR",
          commercial: opt?.commercial || {},
          compliance: opt?.compliance || {},
          cnp: {
            isRefundable: Boolean(opt?.cancellation?.isRefundable),
            ifra: Boolean(opt?.cancellation?.isRefundable),
            inra: !Boolean(opt?.cancellation?.isRefundable),
            penalties: Array.isArray(opt?.cancellation?.penalties) ? opt.cancellation.penalties : [],
            pd: Array.isArray(opt?.cancellation?.penalties)
              ? opt.cancellation.penalties.map((p) => ({
                  fdt: p?.from || "",
                  tdt: p?.to || "",
                  am: Number(p?.amount || 0),
                }))
              : [],
          },
          cancellation: opt?.cancellation || {},
          raw: opt,
        })),
      }
    : null) ||
  payload?.hotelInfo ||
  payload?.searchResult?.hotelInfos?.[0] ||
  payload?.data?.searchResult?.hotelInfos?.[0] ||
  payload?.hotel ||
  payload?.data?.hotel ||
  payload?.searchResult?.hotel ||
  payload?.hotelInfos?.[0] ||
  null;

const extractDetailMeta = (payload) => ({
  correlationId:
    payload?.correlationId ||
    payload?.metaData?.correlationId ||
    payload?.data?.metaData?.correlationId ||
    "",
  searchId:
    payload?.metaData?.searchId ||
    payload?.data?.metaData?.searchId ||
    payload?.searchQuery?.searchId ||
    payload?.id ||
    "",
  requestId:
    payload?.metaData?.requestId ||
    payload?.data?.metaData?.requestId ||
    payload?.reviewHash ||
    payload?.requestId ||
    payload?.id ||
    "",
  reviewHash:
    payload?.metaData?.reviewHash ||
    payload?.data?.metaData?.reviewHash ||
    payload?.reviewHash ||
    payload?.requestId ||
    "",
  flow:
    payload?.metaData?.flow ||
    payload?.data?.metaData?.flow ||
    "",
});

const normalizeHotelDetails = ({
  detailResponse,
  selectedHotel,
  searchPayload,
  selectedSuggestion,
  staticContentResponse,
}) => {
  const hotelInfo = extractDetailHotelRoot(detailResponse) || {};
  const staticHotels = Array.isArray(staticContentResponse)
    ? staticContentResponse
    : Array.isArray(staticContentResponse?.hotels)
      ? staticContentResponse.hotels
      : [];
  // Prefer the static entry whose id matches the detail hotel; fall back to first.
  const detailHotelId = String(
    hotelInfo?.tjid || hotelInfo?.id || selectedHotel?.id || selectedHotel?.raw?.tjid || ""
  ).trim();
  const staticHotel =
    (detailHotelId &&
      staticHotels.find(
        (item) =>
          String(item?.tjHotelId || item?.tjHotelID || item?.hotelId || item?.id || "").trim() ===
          detailHotelId
      )) ||
    staticHotels[0] ||
    {};
  const description =
    parseJsonSafely(
      staticHotel?.descriptions?.default ||
      staticHotel?.description ||
      hotelInfo?.des ||
      hotelInfo?.description ||
      "",
    ) || {};
  const aboutSections = {
    headline:
      staticHotel?.descriptions?.headline ||
      description?.headline ||
      "",
    location:
      staticHotel?.descriptions?.location ||
      description?.location ||
      "",
    amenities:
      staticHotel?.descriptions?.amenities ||
      description?.amenities ||
      "",
    rooms:
      staticHotel?.descriptions?.rooms ||
      description?.rooms ||
      "",
    dining:
      staticHotel?.descriptions?.dining ||
      description?.dining ||
      "",
    businessAmenities:
      staticHotel?.descriptions?.business_amenities ||
      description?.business_amenities ||
      "",
    attractions:
      staticHotel?.descriptions?.attractions ||
      description?.attractions ||
      "",
    onsitePayments:
      staticHotel?.descriptions?.onsite_payments ||
      description?.onsite_payments ||
      "",
    spokenLanguages:
      staticHotel?.descriptions?.spoken_languages ||
      description?.spoken_languages ||
      "",
  };
  const nights = getNightCount(searchPayload);
  const listImages = normalizeImageItems(selectedHotel?.images || []);
  const hotelImages = normalizeImageItems(hotelInfo?.img || hotelInfo?.images || []);
  const staticImages = normalizeImageItems(staticHotel?.images || []);
  const roomImageFallbackPool =
    staticImages.length > 0
      ? staticImages
      : listImages.length > 0
        ? listImages
        : hotelImages;
  const options = (Array.isArray(hotelInfo?.ops) ? hotelInfo.ops : [])
    .map((option, index) =>
      normalizeRoomOption(option, index, hotelInfo, nights, staticHotel, roomImageFallbackPool)
    )
    .filter((option) => option.id);
  const sortedOptions = [...options].sort((a, b) => (a.totalPrice || Infinity) - (b.totalPrice || Infinity));
  const cheapestOption = sortedOptions[0] || null;
  
  // Extract amenities from hotel facilities (fl field)
  const hotelFacilities = Array.isArray(hotelInfo?.fl) 
    ? hotelInfo.fl.map((item) => {
        if (typeof item === 'string') {
          return item;
        }
        if (typeof item === 'object' && item !== null) {
          return item.name || item.nm || item.label || '';
        }
        return String(item || '');
      }).filter(Boolean)
    : [];

  const amenityGroupsFromLegacy = Array.isArray(staticHotel?.tja)
    ? staticHotel.tja
        .map((group) => ({
          title: String(group?.catg || "").trim(),
          items: Array.isArray(group?.am)
            ? group.am
                .map((item) => ({
                  id: item?.id || "",
                  name: String(item?.name || "").trim(),
                  subtext: String(item?.subA || "").trim(),
                  icon: item?.icn || "",
                }))
                .filter((item) => item.name)
            : [],
        }))
        .filter((group) => group.title && group.items.length > 0)
    : [];
  const staticAmenityItems = Object.values(staticHotel?.amenities || {})
    .map((item) => ({
      id: item?.id || "",
      name: String(item?.name || "").trim(),
      subtext: "",
      icon: "",
    }))
    .filter((item) => item.name);
  const amenityGroups = amenityGroupsFromLegacy.length > 0
    ? amenityGroupsFromLegacy
    : staticAmenityItems.length > 0
      ? [{ title: "Hotel amenities", items: staticAmenityItems }]
      : [];
  
  const amenitySet = dedupeStrings([
    ...amenityGroups.flatMap((group) =>
      group.items.map((item) => (item.subtext ? `${item.name} (${item.subtext})` : item.name)),
    ),
    ...(Array.isArray(staticHotel?.facilities) ? staticHotel.facilities : []),
    ...staticAmenityItems.map((item) => item.name),
    ...hotelFacilities,
    ...options.flatMap((option) => option.amenities),
  ]);
  
  const images = staticImages.length > 0
    ? dedupeImages([...staticImages, ...listImages, ...hotelImages, ...options.flatMap((option) => option.images)])
    : listImages.length > 0
      ? dedupeImages([...listImages, ...hotelImages])
      : dedupeImages([...hotelImages, ...options.flatMap((option) => option.images)]);
  const staticAddress = staticHotel?.locale?.address || {};
  const address =
    staticHotel?.ad ||
    {
      adr: staticAddress?.line_1 || "",
      adr2: staticAddress?.line_2 || "",
      ctn: staticAddress?.city || "",
      sn: staticAddress?.statename || "",
      postalCode: staticAddress?.postal_code || "",
      cn: staticAddress?.countryname || "",
    } ||
    hotelInfo?.ad ||
    {};
  const cityName =
    address?.ctn ||
    staticHotel?.hai?.regions?.[0]?.name ||
    address?.city?.name ||
    searchPayload?.searchQuery?.searchCriteria?.searchRegionName ||
    selectedSuggestion?.displayName ||
    selectedHotel?.location ||
    "";
  const fullAddress = buildAddressLabel(address);
  const staticLat = staticHotel?.locale?.coordinates?.lat;
  const staticLong = staticHotel?.locale?.coordinates?.long;
  const mapSource = (staticLat && staticLong)
    ? `${staticLat},${staticLong}`
    : hotelInfo?.gl?.lt && hotelInfo?.gl?.ln
    ? `${hotelInfo.gl.lt},${hotelInfo.gl.ln}`
    : fullAddress || cityName || hotelInfo?.name || selectedHotel?.name || "Hotel";
  const filterData = hotelInfo?.filters || {};

  const roomTypeSummary = dedupeStrings(
    options.map((option) => option.roomName || option.supplierRoomType).filter(Boolean),
  );
  const mealPlanSummary = dedupeStrings(options.map((option) => option.mealBasis).filter(Boolean));

  // Extract about text from inst (instructions) field or description
  const instructionsArray = Array.isArray(hotelInfo?.inst) ? hotelInfo.inst : [];
  const aboutTextFromInst = instructionsArray.join(" ").trim();
  const aboutTextFromDesc =
    staticHotel?.descriptions?.location ||
    description?.location ||
    staticHotel?.displayDescription ||
    staticHotel?.descriptions?.default ||
    staticHotel?.descriptions?.headline ||
    description?.amenities ||
    description?.rooms ||
    description?.headline ||
    "";
  const aboutTextFromApi =
    typeof staticHotel?.displayDescription === "string"
      ? staticHotel.displayDescription.trim()
      : typeof hotelInfo?.about === "string"
        ? hotelInfo.about.trim()
        : "";
  const fallbackSegments = [
    fullAddress
      ? `${hotelInfo?.name || "This hotel"} is located at ${fullAddress}.`
      : cityName
        ? `${hotelInfo?.name || "This hotel"} is located in ${cityName}.`
        : "",
    roomTypeSummary.length > 0
      ? `Available room categories include ${roomTypeSummary.join(", ")}.`
      : "",
    mealPlanSummary.length > 0
      ? `Meal plans include ${mealPlanSummary.join(" and ")}.`
      : "",
    amenitySet.length > 0
      ? `Popular amenities include ${amenitySet.slice(0, 5).join(", ")}.`
      : "",
  ]
    .filter(Boolean)
    .join(" ");
  const finalAboutText =
    aboutTextFromDesc ||
    aboutTextFromInst ||
    aboutTextFromApi ||
    fallbackSegments ||
    `With a stay at ${hotelInfo?.name || "this hotel"} in ${cityName}, you'll be within easy reach of local attractions and amenities.`;

  return {
    meta: extractDetailMeta(detailResponse),
    id: String(hotelInfo?.tjid || hotelInfo?.id || selectedHotel?.id || ""),
    name: hotelInfo?.name || selectedHotel?.name || "Hotel",
    starRating: Number(staticHotel?.star_rating || hotelInfo?.rt || selectedHotel?.starRating || 0),
    address,
    cityName,
    fullAddress,
    mapInfo: {
      displayLocation: fullAddress || cityName || hotelInfo?.name || "Hotel",
      mapSrc: `https://maps.google.com/maps?q=${encodeURIComponent(mapSource)}&t=&z=13&ie=UTF8&iwloc=&output=embed`,
      openMapsHref: `https://www.google.com/maps?q=${encodeURIComponent(mapSource)}`,
    },
    description,
    headline:
      staticHotel?.descriptions?.headline ||
      staticHotel?.headline ||
      description?.headline ||
      hotelInfo?.name ||
      "",
    aboutText: finalAboutText,
    aboutSections,
    amenities: amenitySet,
    amenityGroups,
    images,
    hotelInfo,
    staticHotel,
    options,
    cheapestOption,
    filters: filterData,
    passportRequired: Boolean(hotelInfo?.passportRequired),
    panRequired: Boolean(hotelInfo?.panRequired),
    listHotel: selectedHotel,
    nights,
    importantInformation: {
      // TripJack v3 nests these under `policies` as stringified JSON objects.
      // (Older/legacy top-level keys kept as a fallback.)
      specialInstructions: parsePolicyEntries(
        staticHotel?.policies?.special_instructions ?? staticHotel?.checkInInstructions
      ),
      knowBeforeYouGo: parsePolicyEntries(
        staticHotel?.policies?.know_before_you_go ?? staticHotel?.knowBeforeYouGo
      ),
      mandatoryFees: parsePolicyEntries(
        staticHotel?.policies?.mandatory_fees ?? staticHotel?.mandatoryFees
      ),
    },
    propertyInfo: {
      propertyType:
        staticHotel?.property_type?.name ||
        hotelInfo?.propertyType ||
        "",
      checkInFrom: staticHotel?.policies?.checkInCheckOut?.checkin_from || "",
      checkInTill: staticHotel?.policies?.checkInCheckOut?.checkin_till || "",
      checkOutFrom: staticHotel?.policies?.checkInCheckOut?.checkout_from || "",
      checkOutTill: staticHotel?.policies?.checkInCheckOut?.checkout_till || "",
      checkInMinAge: staticHotel?.policies?.checkInCheckOut?.checkin_min_age || "",
      phone: Array.isArray(staticHotel?.locale?.phone) ? staticHotel.locale.phone[0] || "" : "",
      fax: Array.isArray(staticHotel?.locale?.fax) ? staticHotel.locale.fax[0] || "" : "",
      chain: staticHotel?.chain?.name || "",
      brand: staticHotel?.chain?.brand?.name || "",
    },
  };
};

const getMealPlanOptions = (roomOptions) =>
  dedupeStrings(roomOptions.map((option) => option.mealBasis)).map((value) => ({
    label: value,
    value,
  }));

const getReviewPayloadFields = (hotelInfo, selectedHotel, detailMeta, searchPayload, searchResponse) => {
  const correlationIdCandidates = [
    detailMeta?.correlationId,
    searchResponse?.correlationId,
    searchPayload?.correlationId,
  ]
    .filter(Boolean)
    .map((value) => String(value));

  const searchIdCandidates = [
    detailMeta?.searchId,
    searchResponse?.metaData?.searchId,
    searchResponse?.searchId,
    searchPayload?.searchId,
    selectedHotel?.raw?.searchId,
  ]
    .filter(Boolean)
    .map((value) => String(value));

  const detailRequestIdCandidates = [
    detailMeta?.requestId,
    detailMeta?.reviewHash,
    searchResponse?.metaData?.requestId,
    searchResponse?.requestId,
    hotelInfo?.requestId,
    hotelInfo?.detailRequestId,
    selectedHotel?.raw?.requestId,
  ]
    .filter(Boolean)
    .map((value) => String(value));

  const tjHotelIdCandidates = [
    hotelInfo?.tjid,
    hotelInfo?.tjHotelId,
    selectedHotel?.raw?.tjid,
    selectedHotel?.raw?.tjHotelId,
    selectedHotel?.raw?.hotelId,
  ]
    .filter(Boolean)
    .map((value) => String(value));

  return {
    correlationId: correlationIdCandidates[0] || "",
    searchId: searchIdCandidates[0] || "",
    detailRequestId: detailRequestIdCandidates[0] || "",
    reviewHash: detailRequestIdCandidates[0] || "",
    tjHotelId: tjHotelIdCandidates[0] || "",
    hid: tjHotelIdCandidates[0] || "",
    usingOfficialShape: Boolean(
      correlationIdCandidates[0] &&
      detailRequestIdCandidates[0] &&
      tjHotelIdCandidates[0]
    ),
    candidates: {
      correlationIdCandidates,
      searchIdCandidates,
      detailRequestIdCandidates,
      tjHotelIdCandidates,
    },
  };
};

const buildDefaultTraveller = (passengerType, bookingRequirements) => {
  const isAdult = passengerType === "ADULT";

  return {
    // TripJack OMS expects ti (title) and pt (ADULT/CHILD)
    ti: isAdult ? "Mr" : "Master",
    pt: passengerType,

    // TripJack uses fN / lN for names
    fN: "",
    lN: "",

    // Optional compliance fields (include only when required)
    ...(bookingRequirements?.panRequired && isAdult ? { pan: "" } : {}),
    ...(bookingRequirements?.passportRequired && isAdult ? { pNum: "" } : {}),
  };
};

const getReviewRoomInfos = (reviewResponse) => {
  const selectedOption = reviewResponse?.selectedOption || {};
  const selectedRoomInfos = Array.isArray(selectedOption?.roomInfos) && selectedOption.roomInfos.length > 0
    ? selectedOption.roomInfos
    : Array.isArray(selectedOption?.ris) && selectedOption.ris.length > 0
      ? selectedOption.ris
      : [];
  const requestedRooms = Array.isArray(reviewResponse?.searchQuery?.roomInfo)
    ? reviewResponse.searchQuery.roomInfo
    : [];

  if (requestedRooms.length > 0) {
    return requestedRooms.map((requestedRoom, index) => {
      const selectedRoom = selectedRoomInfos[index] || selectedRoomInfos[0] || {};
      return {
        ...selectedRoom,
        adt: Number(
          selectedRoom?.adt ??
            selectedRoom?.adults ??
            requestedRoom?.numberOfAdults ??
            requestedRoom?.adults ??
            1
        ),
        chd: Number(
          selectedRoom?.chd ??
            selectedRoom?.children ??
            requestedRoom?.numberOfChild ??
            requestedRoom?.children ??
            (Array.isArray(requestedRoom?.childAge) ? requestedRoom.childAge.length : 0) ??
            0
        ),
      };
    });
  }

  if (selectedRoomInfos.length > 0) {
    return selectedRoomInfos;
  }

  const fallbackAdults = Number(reviewResponse?.roomSummary?.adults || 1);
  const fallbackChildren = Number(reviewResponse?.roomSummary?.children || 0);
  return [
    {
      adt: fallbackAdults,
      chd: fallbackChildren,
    },
  ];
};

const createInitialBookingForm = (reviewResponse) => {
  const bookingRequirements = reviewResponse?.bookingRequirements || {};
  const roomTravellerInfo = getReviewRoomInfos(reviewResponse).map((roomInfo) => {
    const adultCount = Math.max(Number(roomInfo?.adt || 0), 1);
    const childCount = Math.max(Number(roomInfo?.chd || 0), 0);
    const travellerInfo = [
      ...Array.from({ length: adultCount }, () => buildDefaultTraveller("ADULT", bookingRequirements)),
      ...Array.from({ length: childCount }, () => buildDefaultTraveller("CHILD", bookingRequirements)),
    ];

    return { travellerInfo };
  });

  return {
    roomTravellerInfo,
    deliveryInfo: {
      emails: [""],
      contacts: [""],
      code: ["+91"],
    },
    termsAccepted: false,
  };
};

const resolveRoomInfoFromSearchPayload = (searchPayload = {}) => {
  const searchQuery = searchPayload?.searchQuery || {};
  const directRoomInfo = Array.isArray(searchQuery?.roomInfo) ? searchQuery.roomInfo : [];
  if (directRoomInfo.length > 0) {
    return directRoomInfo;
  }

  const roomCandidates = [
    ...(Array.isArray(searchQuery?.rooms) ? searchQuery.rooms : []),
    ...(Array.isArray(searchQuery?.searchCriteria?.rooms) ? searchQuery.searchCriteria.rooms : []),
    ...(Array.isArray(searchPayload?.rooms) ? searchPayload.rooms : []),
  ];

  return roomCandidates.map((room) => ({
    numberOfAdults: Number(room?.numberOfAdults || room?.adults || 1),
    numberOfChild: Number(room?.numberOfChild || room?.children || 0),
    childAge: Array.isArray(room?.childAge) ? room.childAge : [],
  }));
};

const normalizeReviewResponseForUi = (

  reviewResponse = {},
  fallbackOption = null,
  fallbackHotel = null,
  fallbackSearchPayload = null,
) => {
  if (!reviewResponse || typeof reviewResponse !== "object") return reviewResponse;

  const hasCompleteUiShape = Boolean(
    reviewResponse?.selectedOption &&
    reviewResponse?.bookingRequirements &&
    reviewResponse?.priceSummary?.amount &&
    reviewResponse?.searchQuery &&
    reviewResponse?.hotelSummary
  );

  if (hasCompleteUiShape) {
    return reviewResponse;
  }

  // Preserve existing priceSummary from backend if it has a valid amount
  const existingPriceSummary = reviewResponse?.priceSummary;
  const hasValidExistingAmount = existingPriceSummary && normalizeAmount(existingPriceSummary.amount) > 0;

  const option = reviewResponse?.option || fallbackOption || {};
  const optionId = String(option?.optionId || option?.id || "");
  const roomInfo = Array.isArray(option?.roomInfo) ? option.roomInfo : [];
  const firstRoom = roomInfo[0] || {};
  const compliance = option?.compliance || {};
  const cancellation = option?.cancellation || {};
  const pricing = option?.pricing || {};
  const tjHotelId = String(reviewResponse?.tjHotelId || reviewResponse?.hotelId || fallbackHotel?.id || "");
  const hotelName = reviewResponse?.hotelName || fallbackHotel?.name || "Selected hotel";
  const searchQuery = fallbackSearchPayload?.searchQuery || {};
  const checkInDate = searchQuery?.checkInDate || searchQuery?.checkinDate || searchQuery?.checkIn || null;
  const checkOutDate =
    searchQuery?.checkoutDate || searchQuery?.checkOutDate || searchQuery?.checkOut || null;
  const roomInfoFromSearch = resolveRoomInfoFromSearchPayload(fallbackSearchPayload);
  const roomInfoForUi =
    roomInfoFromSearch.length > 0
      ? roomInfoFromSearch
      : [{ numberOfAdults: Number(firstRoom?.adults || 1), numberOfChild: Number(firstRoom?.children || 0), childAge: [] }];

  return {
    ...reviewResponse,
    searchQuery: {
      checkInDate,
      checkoutDate: checkOutDate,
      roomInfo: roomInfoForUi.map((room) => ({
        numberOfAdults: Number(room?.numberOfAdults || room?.adults || 1),
        numberOfChild: Number(room?.numberOfChild || room?.children || 0),
        childAge: Array.isArray(room?.childAge) ? room.childAge : [],
      })),
    },
    hotelInfo: {
      id: tjHotelId,
      tjid: tjHotelId,
      tjHotelId,
      name: hotelName,
      ad: fallbackHotel?.address || {},
      images: Array.isArray(fallbackHotel?.images) ? fallbackHotel.images : [],
      img: Array.isArray(fallbackHotel?.img) ? fallbackHotel.img : [],
      rt: Number(fallbackHotel?.starRating || fallbackHotel?.rt || 0),
    },
    selectedOption: {
      id: optionId,
      optionId,
      optionType: option?.optionType || null,
      roomInfos: roomInfo.map((room, index) => {
        const fallbackRoom = roomInfoForUi[index] || roomInfoForUi[0] || {};
        return {
          id: room?.id || null,
          name: room?.name || "",
          rt: room?.name || "",
          rc: room?.name || "",
          srn: room?.name || "",
          adt: Number(room?.adults || fallbackRoom?.numberOfAdults || 1),
          chd: Number(room?.children || fallbackRoom?.numberOfChild || 0),
        };
      }),
      ris: roomInfo.map((room, index) => {
        const fallbackRoom = roomInfoForUi[index] || roomInfoForUi[0] || {};
        return {
          id: room?.id || null,
          name: room?.name || "",
          rt: room?.name || "",
          rc: room?.name || "",
          srn: room?.name || "",
          adt: Number(room?.adults || fallbackRoom?.numberOfAdults || 1),
          chd: Number(room?.children || fallbackRoom?.numberOfChild || 0),
        };
      }),
      mb: option?.mealBasis || "Room Only",
      mealBasis: option?.mealBasis || "Room Only",
      tp: Number(pricing?.totalPrice || 0),
      totalPrice: Number(pricing?.totalPrice || 0),
      pricing,
      compliance,
      commercial: option?.commercial || {},
      cnp: {
        isRefundable: Boolean(cancellation?.isRefundable),
        ifra: Boolean(cancellation?.isRefundable),
        inra: !Boolean(cancellation?.isRefundable),
        penalties: Array.isArray(cancellation?.penalties) ? cancellation.penalties : [],
        pd: Array.isArray(cancellation?.penalties)
          ? cancellation.penalties.map((p) => ({
              fdt: p?.from || "",
              tdt: p?.to || "",
              am: Number(p?.amount || 0),
            }))
          : [],
      },
      cancellation,
      ipr: Boolean(compliance?.panRequired),
      ipm: Boolean(compliance?.passportRequired),
      sc: pricing?.currency || "INR",
      currency: pricing?.currency || "INR",
      raw: option,
    },
    bookingRequirements: {
      panRequired: Boolean(compliance?.panRequired),
      passportRequired: Boolean(compliance?.passportRequired),
      deadlineDatetime: option?.deadlineDateTime || null,
      isRefundable: Boolean(cancellation?.isRefundable),
      isNonRefundable: !Boolean(cancellation?.isRefundable),
      cancellationPolicy: {
        isRefundable: Boolean(cancellation?.isRefundable),
        ifra: Boolean(cancellation?.isRefundable),
        inra: !Boolean(cancellation?.isRefundable),
        penalties: Array.isArray(cancellation?.penalties) ? cancellation.penalties : [],
        pd: Array.isArray(cancellation?.penalties)
          ? cancellation.penalties.map((p) => ({
              fdt: p?.from || "",
              tdt: p?.to || "",
              am: Number(p?.amount || 0),
            }))
          : [],
      },
      gstType: compliance?.gstType || "NA",
      onholdAllowed: Boolean(reviewResponse?.onholdAllowed),
    },
    priceSummary: hasValidExistingAmount
      ? existingPriceSummary
      : {
          amount: normalizeAmount(pricing?.totalPrice),
          baseFare: normalizeAmount(pricing?.basePrice),
          taxesAndFees: normalizeAmount(pricing?.taxes),
          currency: pricing?.currency || "INR",
          managementFee: normalizeAmount(pricing?.mf),
          managementFeeTax: normalizeAmount(pricing?.mft),
        },
    roomSummary: {
      roomName: firstRoom?.name || fallbackOption?.roomName || null,
      mealBasis: option?.mealBasis || fallbackOption?.mealBasis || null,
      adults: Number(firstRoom?.adults || 1),
      children: Number(firstRoom?.children || 0),
    },
    hotelSummary: {
      id: tjHotelId,
      tjid: tjHotelId,
      tjHotelId,
      name: hotelName,
      rating: fallbackHotel?.starRating || null,
      address: fallbackHotel?.address || null,
      images: fallbackHotel?.images || [],
      checkInTime: fallbackHotel?.checkInTime || null,
      checkOutTime: fallbackHotel?.checkOutTime || null,
    },
    raw: reviewResponse,
  };
};

const validateBookingForm = (bookingForm, reviewResponse) => {
  const errors = [];
  const bookingRequirements = reviewResponse?.bookingRequirements || {};
  const roomTravellerInfo = Array.isArray(bookingForm?.roomTravellerInfo) ? bookingForm.roomTravellerInfo : [];

  if (roomTravellerInfo.length === 0) {
    errors.push("At least one traveller is required.");
  }

  roomTravellerInfo.forEach((room, roomIndex) => {
    const travellerInfo = Array.isArray(room?.travellerInfo) ? room.travellerInfo : [];
    if (travellerInfo.length === 0) {
      errors.push(`Room ${roomIndex + 1} needs at least one traveller.`);
      return;
    }

    travellerInfo.forEach((traveller, travellerIndex) => {
      const isAdult = traveller?.pt === "ADULT";
      const validTitles = isAdult ? ["Mr", "Mrs", "Ms", "Miss"] : ["Master", "Miss"];
      if (!validTitles.includes(String(traveller?.ti || "").trim())) {
        errors.push(`Select a valid title for room ${roomIndex + 1}, traveller ${travellerIndex + 1}.`);
      }
      if (!traveller?.fN?.trim()) {
        errors.push(`Enter first name for room ${roomIndex + 1}, traveller ${travellerIndex + 1}.`);
      }
      if (!traveller?.lN?.trim()) {
        errors.push(`Enter last name for room ${roomIndex + 1}, traveller ${travellerIndex + 1}.`);
      }
      if (traveller?.pt === "ADULT" && bookingRequirements?.panRequired) {
        const normalizedPan = String(traveller?.pan || "")
          .toUpperCase()
          .replace(/[^A-Z0-9]/g, "");
        if (!/^[A-Z]{5}[0-9]{4}[A-Z]$/.test(normalizedPan)) {
          errors.push(`Enter a valid PAN for room ${roomIndex + 1}, traveller ${travellerIndex + 1}.`);
        }
      }
      if (traveller?.pt === "ADULT" && bookingRequirements?.passportRequired) {
        if (!/^[A-Z0-9]{6,20}$/i.test(String(traveller?.pNum || "").trim())) {
          errors.push(`Enter a valid passport number for room ${roomIndex + 1}, traveller ${travellerIndex + 1}.`);
        }
      }
    });
  });

  const email = String(bookingForm?.deliveryInfo?.emails?.[0] || "").trim();
  const phone = String(bookingForm?.deliveryInfo?.contacts?.[0] || "").trim();
  const code = String(bookingForm?.deliveryInfo?.code?.[0] || "").trim();

  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    errors.push("Enter a valid contact email address.");
  }
  if (!phone || !/^[0-9]{7,15}$/.test(phone)) {
    errors.push("Enter a valid contact phone number.");
  }
  if (!code || !/^\+?\d{1,4}$/.test(code)) {
    errors.push("Enter a valid phone country code.");
  }
  if (!bookingForm?.termsAccepted) {
    errors.push("Accept the booking terms before proceeding.");
  }

  return errors;
};

const delay = (ms) => new Promise((resolve) => {
  window.setTimeout(resolve, ms);
});

const normalizeAmount = (value) => {
  const num = Number(value || 0);
  if (!Number.isFinite(num) || num <= 0) return 0;
  return Number(num.toFixed(2));
};

const defaultFilters = () => ({
  hotelName: "",
  ratings: [],
  userRating: [],
  propertyType: [],
  mealType: [],
  cancellationPolicy: [],
  suppliers: [],
  amenities: [],
  brand: [],
  distance: [],
  popularPlaces: [],
  roomViews: [],
  priceRange: [],
  ramadanMeal: [],
  gstApplicable: [],
  onlyFavorites: false,
});

export {
  createCorrelationId,
  formatMoney,
  formatDate,
  parseJsonSafely,
  parseJsonObjectSafely,
  dedupeStrings,
  dedupeImages,
  normalizeImageItems,
  buildAddressLabel,
  getRoomMetadata,
  getRoomBedSummary,
  getRoomGuestSummary,
  getCancellationLabel,
  getCancellationPenalties,
  getNightCount,
  getRoomImages,
  getRoomAmenities,
  getRoomMealBasis,
  getOptionPanRequired,
  getOptionPanOptional,
  getOptionTotalPrice,
  getOptionNightlyPrice,
  normalizeRoomOption,
  extractDetailHotelRoot,
  extractDetailMeta,
  normalizeHotelDetails,
  getMealPlanOptions,
  getReviewPayloadFields,
  createInitialBookingForm,
  normalizeReviewResponseForUi,
  validateBookingForm,
  delay,
  normalizeAmount,
  defaultFilters,
};
