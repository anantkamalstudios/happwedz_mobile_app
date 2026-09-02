/**
 * Booking drafts and login round-trips.
 *
 * A logged-out user who reaches a booking form used to get a red toast and a
 * bounce to the homepage, losing everything they had typed. These helpers let a
 * flow park what the user entered, send them to login with a way back, and pick
 * up where they left off.
 *
 * Two rules the storage format enforces:
 *
 *   - PAN is never written. It is the one government identifier on the hotel
 *     form, and a draft that outlives the tab-close is not the place for it.
 *     The user re-enters that single field after logging in.
 *   - Nothing time-sensitive from the supplier is kept — no bookingId, fare,
 *     or cancellation policy. Those are re-fetched on restore, because paying
 *     against a stale bookingId either fails at the gateway or bills the wrong
 *     amount. The draft stores only what is needed to ask for them again.
 */

const STORAGE_KEY = "hw:bookingDraft";
const TTL_MS = 30 * 60 * 1000; // 30 minutes

/** sessionStorage throws in private modes and sandboxed frames. */
const safeStorage = () => {
  try {
    return window.sessionStorage;
  } catch {
    return null;
  }
};

/** Only same-origin paths; never "//evil.com" or "https://evil.com". */
export const isInternalPath = (value) =>
  typeof value === "string" && value.startsWith("/") && !value.startsWith("//");

/** Strips PAN from every traveller, leaving the field present but blank. */
const withoutPan = (form) => {
  if (!form) return form;
  const roomTravellerInfo = Array.isArray(form.roomTravellerInfo)
    ? form.roomTravellerInfo.map((room) => ({
        ...room,
        travellerInfo: Array.isArray(room?.travellerInfo)
          ? room.travellerInfo.map((traveller) =>
              "pan" in (traveller || {}) ? { ...traveller, pan: "" } : traveller,
            )
          : room?.travellerInfo,
      }))
    : form.roomTravellerInfo;

  return { ...form, roomTravellerInfo };
};

/**
 * @param {object} draft
 * @param {string} draft.kind      "hotel" | "hotelHold" | "cab"
 * @param {string} [draft.hotelId] scopes the draft so another hotel cannot read it
 * @param {string} [draft.optionId] the room option to re-review
 * @param {object} [draft.searchPayload] search context, for rebuilding the page
 * @param {object} [draft.form]    user-entered fields (PAN removed here)
 */
export const saveBookingDraft = ({ kind, hotelId, optionId, searchPayload, suggestion, form, meta }) => {
  const storage = safeStorage();
  if (!storage || !kind) return false;

  try {
    storage.setItem(
      STORAGE_KEY,
      JSON.stringify({
        kind,
        hotelId: hotelId ? String(hotelId) : "",
        optionId: optionId ? String(optionId) : "",
        searchPayload: searchPayload || null,
        suggestion: suggestion || null,
        form: withoutPan(form),
        meta: meta || null,
        savedAt: Date.now(),
      }),
    );
    return true;
  } catch (error) {
    console.error("Could not save booking draft", error);
    return false;
  }
};

/**
 * Reads the draft, or null. A draft past its TTL, of the wrong kind, or
 * belonging to a different hotel is removed rather than returned, so a stale
 * one can never be replayed into a booking.
 */
export const readBookingDraft = ({ kind, hotelId } = {}) => {
  const storage = safeStorage();
  if (!storage) return null;

  let draft;
  try {
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return null;
    draft = JSON.parse(raw);
  } catch {
    clearBookingDraft();
    return null;
  }

  if (!draft || typeof draft !== "object") {
    clearBookingDraft();
    return null;
  }

  if (!draft.savedAt || Date.now() - draft.savedAt > TTL_MS) {
    clearBookingDraft();
    return null;
  }

  if (kind && draft.kind !== kind) return null;
  if (hotelId && draft.hotelId && draft.hotelId !== String(hotelId)) return null;

  return draft;
};

export const clearBookingDraft = () => {
  const storage = safeStorage();
  if (!storage) return;
  try {
    storage.removeItem(STORAGE_KEY);
  } catch {
    /* nothing useful to do */
  }
};

/**
 * Merges a saved draft onto a freshly built form.
 *
 * The fresh form comes from the new review response, so room and traveller
 * counts follow current availability rather than what was saved. Saved values
 * are applied only where a matching slot still exists, and PAN stays blank.
 */
export const mergeBookingForm = (freshForm, savedForm) => {
  if (!freshForm) return freshForm;
  if (!savedForm) return freshForm;

  const savedRooms = Array.isArray(savedForm.roomTravellerInfo) ? savedForm.roomTravellerInfo : [];

  const roomTravellerInfo = (freshForm.roomTravellerInfo || []).map((room, roomIndex) => {
    const savedTravellers = Array.isArray(savedRooms[roomIndex]?.travellerInfo)
      ? savedRooms[roomIndex].travellerInfo
      : [];

    return {
      ...room,
      travellerInfo: (room?.travellerInfo || []).map((traveller, travellerIndex) => {
        const saved = savedTravellers[travellerIndex];
        if (!saved || saved.pt !== traveller.pt) return traveller;

        const merged = {
          ...traveller,
          ti: saved.ti || traveller.ti,
          fN: saved.fN || "",
          lN: saved.lN || "",
        };

        // Only carry a field the fresh requirements still ask for.
        if ("pNum" in traveller && saved.pNum) merged.pNum = saved.pNum;
        // PAN is intentionally not restored — it was never stored.
        if ("pan" in traveller) merged.pan = "";

        return merged;
      }),
    };
  });

  return {
    ...freshForm,
    roomTravellerInfo,
    deliveryInfo: {
      ...freshForm.deliveryInfo,
      emails: savedForm.deliveryInfo?.emails?.length
        ? savedForm.deliveryInfo.emails
        : freshForm.deliveryInfo?.emails,
      contacts: savedForm.deliveryInfo?.contacts?.length
        ? savedForm.deliveryInfo.contacts
        : freshForm.deliveryInfo?.contacts,
      code: savedForm.deliveryInfo?.code?.length
        ? savedForm.deliveryInfo.code
        : freshForm.deliveryInfo?.code,
    },
    // Re-consent: the fresh review may carry a different cancellation policy.
    termsAccepted: false,
  };
};

/** True when the form still needs a PAN the draft could not carry. */
export const draftNeedsPan = (form) =>
  (form?.roomTravellerInfo || []).some((room) =>
    (room?.travellerInfo || []).some((traveller) => "pan" in (traveller || {}) && !traveller.pan),
  );

/**
 * Arguments for navigate() that send someone to login and back again.
 *
 * `state.from` carries the whole location, so history state — which is where
 * the hotel search payload and response live — survives the round trip. The
 * `redirect` query param is the fallback for when that state does not: a hard
 * reload on the login page, or opening it in a new tab.
 */
export const loginRedirect = (location, reason) => {
  const path = `${location?.pathname || "/"}${location?.search || ""}${location?.hash || ""}`;
  const params = new URLSearchParams();
  if (isInternalPath(path)) params.set("redirect", path);
  if (reason) params.set("reason", reason);
  const query = params.toString();

  return [
    `/customer-login${query ? `?${query}` : ""}`,
    { state: { from: location } },
  ];
};

export const DRAFT_TTL_MS = TTL_MS;
