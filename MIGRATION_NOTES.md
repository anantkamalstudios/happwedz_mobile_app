# React → Flutter migration notes

Working notes for porting the `src/src` React web client into this Flutter
mobile app. Written for whoever picks this up next.

---

## 1. Where things stand

The React project under `src/src` is the **reference implementation** (~606
files). This Flutter app is the product. Nothing in `src/` is compiled or
shipped — it is read, not built.

### `backend/` is not a backend

The `backend/` folder at the repo root is an **older (12 Aug) copy of the same
React `src` tree**, not a server. There is no backend source in this
repository, so backend changes cannot be made here. Every API is remote:

| Base URL | Used for |
|---|---|
| `https://happywedz.com/api` | everything below unless noted |
| `https://www.happywedz.com/ai/api` | AI features (not yet ported) |
| `https://shaadiai.happywedz.com/api` | Shaadi AI (not yet ported) |
| `https://happywedzbackend.happywedz.com/` | image host (`IMAGE_BASE_URL`) |

Where an endpoint is missing or misbehaving, this file records it rather than
inventing a substitute. **No mock data ships in any of the code below.**

---

## 2. Module status

| React module | Flutter | Notes |
|---|---|---|
| Home, Venues, Vendors, Photography | ✅ exists | pre-dates this work |
| Design Studio / try-on | ✅ exists | |
| E-Invites | ✅ exists | |
| Movment Plus | ✅ exists | |
| **Honeymoon / Travels** | ✅ **search + booking** | this pass — see §3 |
| User dashboard (budget, checklist, guests, wishlist…) | ⚠️ partial | screens exist but are not unified into one dashboard |
| Wedding Websites | ❌ missing | 6.2k React lines + 37 template files |
| Matrimonial | ❌ missing | 23 files / 8k lines |
| Vendor dashboard (`adminVendor`) | ❌ out of scope | 106 files / 47k lines; couple-facing app only, by decision |
| Destination Wedding, Blog pages, AI hub | ❌ missing | |

---

## 3. Honeymoon booking — what was built

Before this pass, all four Honeymoon verticals dead-ended at the same place:

```
lib/honeymoon/ui/flight_results_page.dart   "Flight checkout is not connected…"
lib/honeymoon/ui/hotel_detail_page.dart     "Checkout is not connected…"
lib/honeymoon/ui/cab_results_page.dart      "Transfer checkout is not connected…"
lib/honeymoon/ui/insurance_results_page.dart "Insurance checkout is not connected…"
```

All four now complete end to end.

### New files

```
lib/honeymoon/
  models/booking_models.dart          traveller/contact/fare/payment/booking models
  payment/razorpay_checkout.dart      Razorpay checkout hosted in a WebView
  ui/booking/
    booking_widgets.dart              mobile booking kit (step bar, action bar, sheets)
    booking_confirmation_page.dart    shared confirmation screen
    flight_booking_page.dart          flight funnel shell + payment
    flight_traveller_step.dart        passenger / contact / GST / emergency form
    hotel_booking_page.dart           hotel funnel
    cab_booking_page.dart             transfer funnel
    insurance_booking_page.dart       insurance funnel
  ui/bookings/
    my_trips_page.dart                four-tab bookings list
    trip_detail_page.dart             detail + cancel + email ticket
test/honeymoon_booking_layout_test.dart   layout + logic tests
test/honeymoon_api_test.dart              API-shape tests (mock client)
```

### Flows

```
flights    search → pick leg(s) → review (re-price) → travellers → review
                  → hold OR pay → verify_and_book → confirmation
hotels     search → detail → pick room → review → guests → pay
                  → verify-payment-and-book → confirmation
cabs       search → pick vehicle → passenger → book → pay → verify → confirmation
insurance  search → pick plan → review → travellers → book (wallet) → confirmation
```

### Endpoints now consumed

Flights (`services/api/flightApi.js`)
- `POST /tj/fms/review`, `POST /tj/oms/booking-details`
- `POST /flight_payment/create_order`, `/hold`, `/verify_and_book`, `/email-ticket`
- `POST /tj/oms/cancel-charges`, `/cancel`, `/release-hold`
- `GET /tj/my-bookings`, `GET /Flight_booking/travellers`

Hotels (`hotelApi.js`)
- `POST hotels/review`, `hotels/cancellation-policy`
- `POST hotels/create-payment-order`, `hotels/verify-payment-and-book`
- `POST hotels/booking-details`, `hotels/cancel-booking/:id`
- `GET hotels/all-bookings`

Cabs (`cabApi.js`)
- `POST tripjack-cabs/book`, `tripjack-cabs/payment/create-order`,
  `tripjack-cabs/payment/verify`
- `GET tripjack-cabs/booking/details`

Insurance (`tripSafeApi.js`)
- `POST tripsafe/review`, `tripsafe/book`, `tripsafe/booking-details`
- `GET /insurance_payment/bookings`

### Payments

The web client loads Razorpay's `checkout.js` in the page. Rather than add a
plugin, `lib/honeymoon/payment/razorpay_checkout.dart` hosts the **same script**
in a `WebView` (`webview_flutter`, already a dependency) and bridges the
callbacks over one JavaScript channel. The options object is field-for-field
what the web builds, so a payment started on either surface reaches the backend
identically.

- UPI / bank-app deep links (`upi:`, `intent:`) are handed to the OS through
  `url_launcher`, since a WebView cannot load them.
- Backing out is confirmed, never silent.
- **Not yet verified against a live Razorpay key.** Test with `rzp_test_…`
  before release; see §9.

---

## 4. Bugs found and fixed on the way

These were pre-existing defects in the Flutter module, not regressions:

1. **Insurance search always returned nothing.** The response nests plans at
   `isr.iinfo.pli[].pi[]`; the parser read a flat `{ data: [...] }` list, which
   never matched. Rewritten (`InsurancePlan.fromSearchResponse`), including the
   two premium shapes — a flat per-traveller rate that must be multiplied by
   the party, versus a banded rate whose highest key already covers the party.
   Multiplying a banded rate would have charged several times over.

2. **Cab search always returned nothing.** `quotesInfo` is a list of *vehicle
   groups*, each holding *quotes*; the parser read a group as if it were a
   quote, found no fare, and the `price > 0` filter then dropped every option.
   Rewritten as `CabQuote.flatten`, mirroring `flattenCabQuotes` in the web.

3. **Round-trip flight results were unusable.** `tripInfos.{ONWARD, RETURN}`
   were flattened into one list, so outbound and return cards were mixed with
   no way to tell them apart. Now split (`FlightSearchResult`) and picked one
   leg at a time.

4. **Handled failures read as empty results.** Several endpoints report an
   upstream failure as HTTP 200 with `status: false`. Without a check the UI
   showed an "empty" state for what was actually an error. Added
   `_throwIfHandledFailure`.

The next four were found by **running the app on a device**, not by reading
code — each one is invisible until a real response comes back:

5. **The airport picker was permanently empty**, which made flight search
   unreachable. `tj/meta/locations` is the one endpoint that answers in the
   supplier's own envelope — `{ payload: { suggestions: [...] } }` — while the
   rest answer under `data`. Found by running the app, not by reading code.

6. **A supplier outage read as "no results".** During a TripJack outage the
   backend passed a Cloudflare 502 page through as HTTP **200** with
   `status: { success: false }`. Parsed as data that is an empty list, so the
   picker said "No airports found" while the supplier was down — which makes a
   traveller retype instead of retry. `_throwIfHandledFailure` now recognises
   the nested flag, and maps an upstream 5xx to "our travel partner is busy,
   try again in a minute" rather than showing Cloudflare's own prose.

7. **Round trips were unbookable.** A trip lists several fares and
   `totalPriceList[0]` is often a `SPECIAL_RETURN` one — a discounted round
   trip valid only when *both* legs come from that same pairing. Combining it
   with a leg the traveller picked independently is refused outright:

       1080 — All Segments Must be selected if Special Return fare.

   `FlightResult.pickBookableFare` now prefers `PUBLISHED`, then anything not
   return-coupled, and only falls back to a coupled fare when a trip has
   nothing else. Verified against the live API: two `PUBLISHED` fares review
   cleanly where the coupled pairing 400s. Note the **web client has the same
   bug** — it also sends `totalPriceList[0]` for both legs.

8. **Supplier refusals were reduced to boilerplate.** The reason arrives as
   `{errors: [{errCode, message}]}`, which the error extractor did not read, so
   a 400 always showed "Some of those search details look off". It now surfaces
   the supplier's own sentence, which is the only thing that tells a traveller
   what to change.

9. **No payment order could ever be created.** `flightApi.js` renames
   `price` → `amount` *inside* `createFlightPaymentOrder`; the Dart port passed
   the caller's payload straight through, so the endpoint answered
   *"Missing offer_id/provider/amount"*. The same rename applies to
   `/flight_payment/hold`, which additionally omits `offer_id`. Both now go
   through `_flightPaymentBody`, which keeps the translation in the API layer
   exactly as the web does.

10. **A corrected mobile number kept its error.** `PhoneField` had no
    `onChanged`, so "enter a valid mobile number" sat under a perfectly valid
    number until the next submit, unlike every other field on the form.

11. **A filled-in traveller panel collapsed to just "Mr".** The collapsed
    summary read the traveller *model*, which is only written on a successful
    submit, rather than the controllers holding what was typed.

---

## 5. Known gaps — needs backend or product input

| # | Gap | Impact | Suggested fix |
|---|---|---|---|
| ~~1~~ | ~~**No "list my cab bookings" endpoint.**~~ **Corrected (2026-09-02):** this was wrong — it only checked `cabApi.js`, which indeed exports no listing call. But `useBookingData.js` (the web booking dashboard) calls `GET tripjack-cabs/invoices` directly via `axiosInstance`, bypassing `cabApi.js` entirely. Confirmed live against production (401 unauthenticated, not 404). | — (resolved) | Ported as `HoneymoonApi.fetchCabInvoices()` / `TravelBooking.fromCabInvoiceRow` in `lib/honeymoon/`; the Transfers tab in My trips now lists cabs the same way as the other three products. The old "looked up by reference" notice (`_CabLookupNotice` in `my_trips_page.dart`) is commented out, not deleted, in case this endpoint is ever pulled again. |
| 2 | **Insurance cancellation is not exposed.** `tripsafe/amendment/raise` and `/amendment/confirm-cancellation` exist in `tripSafeApi.js` but were never surfaced. | A policy cannot be cancelled in the app. | Two-step flow (raise → confirm) once the refund quote shape is confirmed. |
| 3 | **Hotel receipt / voucher PDFs.** `GET hotels/:id/receipt` and `/voucher` return blobs; the web triggers a browser download. | No in-app download. | Needs `path_provider` + `open_filex` (both already dependencies) and a save-then-open step. |
| 4 | **No honeymoon destination / statistics endpoint.** The hero figures in `honeymoon_config.dart` are configuration, not data. | Hero numbers are static. | Pre-existing; unchanged by this pass. |
| 5 | **Saved GST profiles have no store.** The web keeps GST history in `localStorage`. | GST details are re-typed each booking. | Needs a table + endpoint, or a local Hive box. |
| 6 | **Traveller "don't save this person" list** is browser-local in the web (`travellerStore.js`). | Not ported. | Same decision as #5. |

---

## 6. Deliberately deferred (works without them)

Everything here exists in the React client and is **not** in the Flutter
funnels yet. None of them block a booking.

- **Seat / meal / baggage selection** (`SeatSelection.jsx`, `FlightAddOn.jsx`).
  Add-ons change `paymentInfos.amount`, which the supplier validates; omitting
  them keeps that amount exactly equal to the quoted fare, which is valid. When
  they are added, `_bookingPayload` in `flight_booking_page.dart` must fold the
  SSR total into the amount, as `ssrForTraveller` does in the web.
- **Fare rules panel** (`POST /tj/fms/farerule`) and **flight filters**
  (`FlightFiltersSidebar.jsx`).
- **Multi-city flights** (`MultiCityResults.jsx`).
- **Flight amendments** beyond cancellation (`/tj/oms/amendment/*`).
- **Hotel filters and sorting** (`POST hotels/filters`).
- **Hotelbeds hotel variant** (`Travels/hotelbeds/`, ~7k lines) — a second,
  parallel hotel implementation. Only the TripJack one is ported.
- **Insurance student and annual-multi-trip variants** — only the international
  single-trip `isq` envelope is exposed.
- **Frequent-flier numbers** on the passenger form (`conditions.ffas`).

---

## 7. Conventions to keep

- **`lib/honeymoon/data/honeymoon_api.dart` is the only place in the module
  that talks HTTP or touches JSON.** Screens never parse a response.
- Every endpoint is traceable to its React source; the doc comment names the
  file it came from. Do not invent endpoints.
- Supplier abbreviations (`fN`, `pt`, `iti`) live **only** at the JSON
  boundary. Dart-side names are real words.
- Requirements come from the supplier's own response, never from assumptions —
  passport, PAN, name limits and age bands are all read from `conditions` /
  `bookingRequirements`.
- Errors reaching a traveller are written for a traveller. `HoneymoonApiException`
  carries that copy; `bookingErrorText()` prefers it over the generic wording.
- **Layout budget:** 320 px wide at 1.2× text scale, keyboard open. The app
  clamps text scale to 1.2 in `main.dart`; `test/honeymoon_booking_layout_test.dart`
  asserts this across 320/360/375/390/414.

---

## 8. Verified on device

Run on a physical Android 15 handset (1080x2408, ~393 dp) against the live
backend, signed in as a real account:

| Step | Result |
|---|---|
| Honeymoon home, service tabs, My trips entry | ✅ |
| Airport lookup (BOM, DEL) | ✅ after fix #4 |
| Date range picker, past dates disabled | ✅ |
| Round-trip search, ONWARD/RETURN split | ✅ |
| Two-step leg selection ("Step 1 of 2" → "Departure selected · Change") | ✅ |
| Re-price (`/tj/fms/review`), 14-min fare countdown | ✅ after fix #7 |
| Step 2 form: fare-driven fields (no passport on a domestic fare), per-field validation, scroll-to-first-error | ✅ |
| Fare breakdown sheet — base + taxes priced for **both** adults | ✅ ₹8,464 + ₹5,790 = ₹14,254 |
| Step 3 review, incl. "Hold this fare" shown only when `isBA` | ✅ |
| `/flight_payment/create_order` | ✅ after fix #9 |
| Razorpay checkout in the WebView — branded, correct total, prefill | ✅ |
| Cancelling the payment returns to Review with state intact | ✅ |
| Error states (supplier 502, fare refusal, payload rejection) | ✅ shown with retry |

**Not done deliberately:** no payment was completed and no fare was held —
both create real commitments with the airline. Completing one against a
`rzp_test_…` key is the last outstanding check (§9.1).

Note: the device must be kept awake during a run (`adb shell svc power stayon
true`). When the screen sleeps, Wi-Fi drops and every request fails DNS —
which looks exactly like a backend outage in the logs and is not one.

## 9. Before release

1. **Run the funnels against a live `rzp_test_…` key.** The WebView checkout is
   fully implemented but has only been verified structurally, not against a
   real gateway session. Check specifically: UPI intent hand-off to an
   installed app, and the `ondismiss` path.
2. **Verify `GET /Flight_booking/travellers` exists in production.** It fails
   silently by design (the picker just hides), so a 404 is invisible.
3. **Confirm the hotel review payload.** `hotels/review` accepts two shapes —
   correlation-based and legacy search-based — and which ids come back depends
   on how the detail was fetched. Both are sent; watch for
   `"Missing review payload data"` in logs.
4. **Test a real cancellation** end to end, including the refund quote from
   `POST /tj/oms/cancel-charges`.
5. Confirm `INTERNET` permission and WebView availability on the minimum
   supported Android version.
