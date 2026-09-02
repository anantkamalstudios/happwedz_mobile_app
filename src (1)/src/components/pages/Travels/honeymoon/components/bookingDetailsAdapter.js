/**
 * Maps a `/oms/v1/booking-details` response onto the props the confirmation
 * screen already expects from the in-memory booking flow.
 *
 * The two shapes differ in one important way: a review response carries the
 * fare at `tripInfos[].totalPriceList[].fd.ADULT`, keyed by passenger type,
 * whereas booking-details leaves `totalPriceList` empty and hangs a *flat* `fd`
 * off each traveller instead. Grouping those by `pt` rebuilds the keyed shape
 * the components read.
 */

/** tripInfos comes back as a list here and as an ONWARD/RETURN map elsewhere. */
const tripList = (air) => {
  const ti = air?.tripInfos;
  if (Array.isArray(ti)) return ti;
  return Object.values(ti || {}).flat();
};

/**
 * Rebuild `{ fd: { ADULT: {...}, CHILD: {...} } }` from the travellers' flat
 * `fd`. One fare per passenger type is enough — every traveller of a type is on
 * the same fare.
 */
const fareFromTravellers = (travellers = []) => {
  const fd = {};
  for (const t of travellers) {
    const type = t?.pt || 'ADULT';
    if (!fd[type] && t?.fd) fd[type] = t.fd;
  }
  return Object.keys(fd).length ? { fd } : null;
};

/** True once the airline has issued a PNR for at least one traveller. */
export const hasPnrs = (travellers = []) =>
  travellers.some((t) => Object.keys(t?.pnrDetails || {}).length > 0);

/**
 * A booking sits at PENDING until the airline answers with a PNR; it then
 * moves to ON_HOLD or SUCCESS. Across the certification set every PENDING
 * booking has no PNR and every ON_HOLD/SUCCESS one has them, so this is the
 * signal to stop polling on.
 */
export const isAwaitingPnr = (details) => {
  const air = details?.itemInfos?.AIR;
  if (!air) return false;
  const status = String(details?.order?.status || '').toUpperCase();
  if (status === 'PENDING') return true;
  return !hasPnrs(air.travellerInfos || []);
};

/** Everything the confirmation screen needs, or null if the payload is unusable. */
export const adaptBookingDetails = (details) => {
  const air = details?.itemInfos?.AIR;
  if (!air) return null;

  const trips = tripList(air);
  const travellers = air.travellerInfos || [];
  const order = details.order || {};

  return {
    trip: trips[0] || null,
    returnTrip: trips[1] || null,
    fare: fareFromTravellers(travellers),
    returnFare: fareFromTravellers(travellers),
    travellerInfo: travellers.map((t) => ({
      ti: t.ti || '',
      fN: t.fN || '',
      lN: t.lN || '',
      pt: t.pt || 'ADULT',
      dob: t.dob || '',
      pNum: t.pNum || '',
    })),
    paxInfos: travellers,
    status: String(order.status || '').toUpperCase(),
    bookingData: {
      order_id: order.bookingId || null,
      on_hold: String(order.status || '').toUpperCase() === 'ON_HOLD',
      created_at: order.createdOn || null,
      amount_paid: order.amount ?? 0,
      contact_email: order.deliveryInfo?.emails?.[0] || '',
      contact_phone: order.deliveryInfo?.contacts?.[0] || '',
      raw_order: details,
    },
    totalPriceInfo: air.totalPriceInfo || null,
  };
};

export default adaptBookingDetails;
