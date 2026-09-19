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
| **Honeymoon / Travels** | ✅ **search + booking** | see §3; §6 corrected 2026-09-18, most of it was already built and undocumented |
| User dashboard (budget, checklist, guests, wishlist…) | ✅ **summary cards on Home** | 2026-09-18 — see §10 |
| **Wedding Websites** | ✅ **built** | 2026-09-18 — see §11 |
| **Matrimonial** | ⚠️ **built as a non-functional preview** | 2026-09-18 — see §12. UI only; no backend exists to connect it to |
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

The web client loads Razorpay's `checkout.js` in the page. On Android/iOS
`lib/honeymoon/payment/razorpay_checkout.dart` now opens Razorpay's **native
SDK** (`razorpay_flutter`) with the same options object, field-for-field what
the web builds, so a payment reaches the backend identically.

The first version hosted `checkout.js` in a `WebView`. That broke netbanking
and card-OTP payments: Razorpay opens those bank pages in a pop-up that
reports back to its opener, and `webview_flutter` loads a pop-up into the same
view, replacing the checkout ("payment could not be completed"). The WebView
checkout remains only as the fallback for other platforms. Adding the native
plugin needs a full rebuild (`flutter run`), not a hot restart.

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
| ~~2~~ | ~~**Insurance cancellation is not exposed.**~~ **Resolved (2026-09-17 pass):** `tripsafe/amendment/raise` and `/amendment/confirm-cancellation` are both implemented in `honeymoon_api.dart` (lines ~1436, ~1462) and wired into `trip_detail_page.dart`'s `_cancelPolicy`/`_cancel()` flow for `TravelProduct.insurance`. | — (resolved) | Not yet verified against a live policy on-device. |
| ~~3~~ | ~~**Hotel receipt / voucher PDFs.**~~ **Resolved (2026-09-17 pass):** `honeymoon_api.dart` implements both voucher (~line 1357) and receipt (~line 1365) fetch-and-save-to-temp-file. | — (resolved) | Not yet verified on-device that the saved file opens correctly. |
| 4 | **No honeymoon destination / statistics endpoint.** The hero figures in `honeymoon_config.dart` are configuration, not data. | Hero numbers are static. | Pre-existing; unchanged by this pass. |
| 5 | **Saved GST profiles have no store.** The web keeps GST history in `localStorage`. | GST details are re-typed each booking. | Still open as of 2026-09-17 — `flight_traveller_step.dart` has the GST form fields but `honeymoon_api.dart` has no fetch/save-GST endpoint. Needs a table + endpoint, or a local Hive box. |
| ~~6~~ | ~~**Traveller "don't save this person" list**~~ **Resolved (2026-09-17 pass):** `fetchSavedTravellers()` (`honeymoon_api.dart` ~line 784) is called from `flight_traveller_step.dart` and used in the UI. | — (resolved) | — |

---

## 6. Deliberately deferred (works without them)

**Built in the 2026-09-17 pass** (this section previously listed these as deferred —
corrected; all six are now wired and reachable from the live UI, confirmed by tracing
imports/navigation, not just file presence):

- **Seat / meal / baggage selection** — `lib/honeymoon/models/addon_models.dart` +
  `lib/honeymoon/ui/booking/flight_addon_step.dart` (897 lines), step 2 of
  `flight_booking_page.dart` (~line 679). The SSR-total-folding into
  `paymentInfos.amount` this doc used to flag as a prerequisite is present
  (`flight_booking_page.dart` ~line 258, `ssrForTraveller`).
- **Flight filters** (`FlightFiltersSidebar.jsx`) — `lib/honeymoon/data/flight_filters.dart`
  (1402 lines) + `ui/widgets/flight_filter_sheet.dart` (1024 lines), invoked from
  `flight_results_page.dart` (~line 1102).
- **Multi-city flights** (`MultiCityResults.jsx`) — `ui/multi_city_results_page.dart`
  (755 lines), reachable from `flight_results_page.dart` (~line 472).
- **Hotel filters and sorting** — `data/hotel_filters.dart` +
  `ui/widgets/hotel_filter_sheet.dart`, invoked from `hotel_results_page.dart` (~line 240).
- **Cab policy panel** — `ui/widgets/cab_policy_sheet.dart`, invoked from
  `cab_results_page.dart` (lines ~537, ~556).
- **Insurance benefits sheet** — invoked from `insurance_results_page.dart` (~line 455).

None of these six have a recorded on-device test yet — see §8.

**Still genuinely deferred:**

- **Fare rules panel** (`POST /tj/fms/farerule`).
- **Flight amendments** beyond cancellation (`/tj/oms/amendment/*`).
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

**Not yet verified on device (added 2026-09-17, no device pass recorded):** seat/baggage
add-ons, flight filters, hotel filters, multi-city search, cab policy panel, insurance
benefits sheet, insurance cancellation (raise → confirm-cancellation), hotel voucher/receipt
download. All eight compile clean and are wired into their screens per the code trace in §6
and §5, but none have been exercised against the live backend on a real device yet.

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
6. **Verify the eight Sep-17 surfaces on a live device** — see the "Not yet verified on
   device" note in §8.
7. **Verify seat/baggage add-on totals reconcile with the payment amount** on a live fare
   (the folding logic exists per §6, but hasn't been checked against a real supplier
   response with add-ons selected).
8. **Verify the insurance cancellation raise → confirm-cancellation sequence** against a
   live policy end to end (§5 gap #2).

**On-device verification attempted 2026-09-18, blocked**: the app on the connected test
device had no persisted login and no test credentials were available in that session, so
none of items 6-8 above could be exercised (every target screen sits behind auth, and the
sign-in gate has no guest/skip path). Needs a real account signed in on-device before this
can be completed.

---

## 10. Dashboard unification + GST profile store (2026-09-18)

**GST profile persistence (§5 gap #5 — resolved).** New `lib/honeymoon/data/gst_profile_store.dart`
(`GstProfileStore`, `GstProfile`), a `SharedPreferences`-backed local history capped at 8
entries, mirroring `PassengerDetails.jsx`'s `hw_gst_history` `localStorage` list exactly
(same cap, same dedup-by-GST-number, same "save must never block a booking" swallow-errors
behavior) rather than inventing a backend table — there genuinely isn't one, same as the
source. `GstDetails` (`lib/honeymoon/models/booking_models.dart`) gained `phone`/`address`
fields for the history entry; the actual booking payload (`toJson`) is unchanged — it still
hardcodes `address: ''` and uses the booking contact's number for `mobile`, matching
`BookingReview.jsx`'s real submit payload (the richer fields only ever fed the web's local
history, never the API). `flight_traveller_step.dart`'s GST section gained a "select from
history" dropdown, a "save details" checkbox (default on, matching source), and the two new
fields — wired to save on successful step submit.

**Home dashboard summary cards.** Ports React's `Wedding.jsx` dashboard-home tab as three
new cards in `lib/Bottombars/HomeScreen.dart` (`_WeddingHomePageState` — the live home class;
note the file also contains a dead, superseded `_HomeScreenState` earlier in the same file,
per the `AUDIT NOTE` at the top — do not confuse the two), placed right after the existing
checklist card:
- **Budget left** — `_loadBudgetSummary()` hits the same `GET budgets/user/:id` endpoint
  `BudgetPage` uses, totals `estimated_budget`/`paid_amount` across items.
- **Guests** — `_loadGuestSummary()` hits the same `GET guestlist/user/:id` endpoint
  `GuestListDashboard` uses, counts total + `status == 'Attending'`.
- **Wishlist** — `_loadWishlistSummary()` hits the same `GET wishlist` endpoint
  `FavouritesPage` uses, just the count (skips that screen's per-item vendor-detail lookups,
  not needed for a badge).

Each card navigates into its existing real screen and re-fetches its own summary on return,
same pattern as the pre-existing checklist card. No new APIs, no new screens, no shared state
introduced between the four cards or their target screens.

**Deliberately not ported**: the source's own dead/fake dashboard bits — its Budget card
state is initialized but never fetched (always shows ₹0 in the React app), and "Service
Hired: 0 of 25" (`Wedding.jsx:295`) is a hardcoded literal. Neither was replicated.

**Deferred**: `VenueVendorComponent` (hired-vendors summary) and `EInviteCard` equivalents
from the same dashboard tab — checked `lib/vendor/` for an existing "hired vendors" summary
source to reuse and found none, so adding these would mean a new API integration rather than
reusing existing screens/data, out of scope for this low-risk pass. Revisit if/when such a
summary source exists.

Verified: `flutter analyze` clean (no new issues; whole-project count unchanged at 290,
matching the pre-existing lint baseline), `flutter test` — all 105 existing tests pass.
Not yet verified on a live device (same credentials blocker as §8/§9 above).

---

## 11. Wedding Websites (2026-09-18)

Ported from `src/components/pages/{MyWeddingWebsites,WeddingWebsiteForm,WeddingWebsiteView,
WeddingPublicView}.jsx`, `src/services/api/weddingWebsiteApi.js` and the three template trees
under `src/templates/{royal,floral,modern}/` + their shared `src/templates/components/`.

### New files

```
lib/wedding_website/
  data/wedding_website_api.dart        all 7 endpoints, single HTTP boundary
  models/wedding_website_models.dart   display models (from GET) + draft models (for POST/PUT)
  ui/
    my_wedding_websites_page.dart      list + create/edit/preview/publish/delete/share
    wedding_website_form_page.dart     multi-section create/edit form
    wedding_website_preview_page.dart  owner preview (authenticated GET by id) + publish
    wedding_public_view_page.dart      guest-facing, no auth, fetched by slug
    templates/
      royal_template.dart / floral_template.dart / modern_template.dart
      wedding_template_view.dart       picks the right template for a record's templateId
      widgets/wedding_section_widgets.dart   shared section widgets (hero, countdown, couple,
                                              story, party, location, gallery, rsvp, footer)
test/wedding_website_api_test.dart     API-shape tests (mock client), 20 tests
test/wedding_website_layout_test.dart  320/360/375/390/414px + 1.2x text-scale, 17 tests
```

Navigation: `lib/Bottombars/morescreen.dart` gained a "Wedding Website" menu item (next to
E-Invites), following the same `_buildMenuItem`/`_handleMenuTap` pattern as every other entry.

### The 7 endpoints

| Endpoint | Source | Status |
|---|---|---|
| `POST weddingwebsite/wedding-websites` | `weddingWebsiteApi.js` `createWebsite` | ✅ wired (multipart) |
| `GET weddingwebsite/wedding-websites` | `getMyWebsites` | ✅ wired |
| `GET weddingwebsite/wedding-websites/:id` | `getWebsiteById` | ✅ wired |
| `PUT weddingwebsite/wedding-websites/:id` | `updateWebsite` | ✅ wired (multipart) |
| `DELETE weddingwebsite/wedding-websites/:id` | `deleteWebsite` | ✅ wired |
| `POST weddingwebsite/wedding-websites/:id/publish` | `publishWebsite` | ✅ wired |
| `GET weddingwebsite/wedding/:websiteUrl` | `viewPublicWebsite` | ✅ wired, public (no auth header sent) |

### API-path inconsistency (found and resolved)

`weddingWebsiteApi.js` calls every endpoint under `weddingwebsite/wedding-websites...`, but
`MyWeddingWebsites.jsx` in the same source tree calls raw `fetch('/api/wedding-websites'...)` —
a shorter, different prefix, for list/delete/publish. Verified live against production before
picking one:

```
GET https://api.happywedz.com/wedding-websites               -> 404 "Route not found"
GET https://api.happywedz.com/weddingwebsite/wedding-websites -> 401 "No token provided"
```

The second is a real, auth-gated route; the first does not exist. `lib/wedding_website/data/
wedding_website_api.dart` uses `weddingWebsiteApi.js`'s prefix throughout — `MyWeddingWebsites
.jsx`'s raw `fetch` calls are the stale ones in the source itself. Only its UI/behaviour
(list, publish, share, delete flow) was ported, not its request path.

### Exact fields sent to the API (from `buildFormData` in `WeddingWebsiteForm.jsx`)

`userId`, `templateId`, `weddingDate`; `brideData`/`groomData` (JSON: `name`/`title`/
`description`/`image_url` when no new photo); `loveStory`/`weddingParty`/`whenWhere` (JSON
arrays, entries with a new photo reordered first — `reorderWithFilesFirst` — to stay aligned
with the same-order file uploads under the `loveStory`/`weddingParty`/`whenWhere` field names);
`galleryImages` (JSON array of kept URLs) + `gallery` files; `sliderImages` (repeated text
parts, one per kept URL) + `slider` files; `bride`/`groom` single photo fields. All reproduced
field-for-field in `WeddingWebsiteApi._buildMultipartParts`, including the files-first reorder,
verified by `test/wedding_website_api_test.dart`.

### Templates

`src/templates/{royal,floral,modern}/index.jsx` differ in colour/typography only — all three
render the same section order (Navbar → Hero → Countdown → Couple → Story → People → Location
→ Gallery → Rsvp → Footer). Reproduced the same way: one shared widget per section in
`ui/templates/widgets/wedding_section_widgets.dart`, themed by a `WeddingTemplateTheme` each of
the three thin template files supplies. The countdown is the source's live
`src/templates/components/countdown/index.jsx` (days/hours/minutes/seconds to `weddingDate`,
"It's the wedding day!" once passed) — ported as a real ticking countdown, not a static value.

**Deliberately not ported:** the "Gift" section (`src/templates/components/gift/index.jsx`) —
a static stock-photo carousel with no wedding data behind it. Two of the three source templates
(royal, modern) already comment it out of their own render; only floral renders it, and even
there it carries nothing user-entered. Skipped as decorative dead weight, not a real gap.

### Known gap: RSVP has no backend (matches the source exactly)

`src/templates/components/rsvp/index.jsx` and `.../Modern Rsvp/RsvpComponent.jsx` both validate
the RSVP form and then just clear it on submit — there is no `weddingWebsiteApi` call, and no
other endpoint anywhere in the source for RSVP submission. Confirmed by reading both files in
full; no fetch/axios call for RSVP exists in `src/services/api/` either.

Per this app's rule against fabricating success responses, `WeddingRsvpSection` in
`lib/wedding_website/ui/templates/widgets/wedding_section_widgets.dart` (see
`_WeddingRsvpSectionState.build`, the `_submitted` branch) shows an honest message —
*"RSVP isn't connected yet — please contact the couple directly to confirm."* — instead of a
fake "you're confirmed". This is a genuine source-side gap, not something introduced here; no
suggested fix beyond "add a real RSVP endpoint" if the product ever wants one.

### Other notes

- Mobile adaptation: no drag-drop editor, rich text, colour picker or image cropper (none exist
  on mobile and the source's own versions have no equivalent here) — plain sectioned form with
  `image_picker` (already a dependency) for single and multi-image fields, matching how
  `lib/ClaimBusiness.dart` already uses it in this app.
- Multipart uploads follow the existing `http.MultipartRequest` pattern from
  `lib/ClaimBusiness.dart` — one exception: this module sends the request through
  `_client.send(request)` rather than the bare `request.send()` ClaimBusiness uses, because the
  latter silently spins up its own throwaway `http.Client()` (see `BaseRequest.send()` in the
  `http` package), which would have bypassed the injected client and made the multipart calls
  unmockable in tests.
- No payment/paywall gating exists in the source for this feature; none was added.
- `lib/einvite1/einvite.dart` already has an unrelated `weddingWebsiteTemplates`/
  `WeddingWebsiteCard` widget that links out to `${ApiConfig.baseUrl}/wedding-form/<template>`
  in a browser — a pre-existing, separate entry point into the *web* builder, left untouched
  here since the task scope was the E-Invites-adjacent `morescreen.dart` menu item, not
  E-Invites itself. Worth revisiting later so both entry points lead to the same native flow.

Verified: `flutter analyze` clean (no new issues; whole-project count unchanged at 290),
`flutter test` — all existing tests plus 20 new API tests and 17 new layout tests pass (153
total). Not yet verified on a live device — no test account with a stored session was available
in this pass (same blocker as §8/§9).

---

## 12. Matrimonial (2026-09-18) — built, but a deliberate non-functional preview

**This is the one module in the whole migration that intentionally ships without a
working backend.** Every other module (Honeymoon, Wedding Websites, the Home dashboard
cards) either has real endpoints or was scoped down until it did. Matrimonial is
different: a full read of the source found **zero API calls anywhere in the entire
matrimonial React tree** (`src/components/pages/matrimonial/**`, ~26 files once the
`Home/` and `dashboard/sections/` subfolders are counted, ~4,600 lines). Specific,
file-and-line findings from that read:

- `MatrimonialRegistration.jsx` — `handleSubmit` calls `Swal.fire({...})` on the final
  step, but `Swal` (SweetAlert2) is **never imported** in the file. It would throw a
  `ReferenceError` at runtime. There is no `fetch`/`axios` call anywhere in the file.
- `MatrimonialRegistration.jsx` — `verifyPhone()` sets `phoneVerified: true`
  unconditionally, with the comment *"In a real app, you would send OTP here."* No OTP
  is ever sent.
- `dashboard/sections/Messages.jsx` — the real thread-list markup is commented out
  (`{/* {threads.map(...)} */}`) and replaced by a static "Service Unavailable" SVG + copy.
  This is the source's *own* honest admission that messaging doesn't work — reproduced
  here, not invented.
- `dashboard/sections/Interests.jsx` — renders hardcoded `sent`/`received` arrays
  (`useState([{ id: 1, name: "Priya Sharma", ... }])`); the Accept/Decline buttons on
  received interests have no `onClick` at all.
- `dashboard/sections/AdvancedSearch.jsx` — wraps `<Search />` and builds a `filters`
  object via `onApply`, but `MatrimonialDashboard.jsx`'s `renderContent()` only ever
  filters the same hardcoded `sampleProfiles` array client-side — there is no search API.
- `dashboard/sections/Activity.jsx` — renders a hardcoded `mockData` map (interest
  received/sent/accepted/shortlisted/declined/blocked), each with 0-2 invented people.
- `dashboard/MatrimonialDashboard.jsx` — `stats` (`totalProfiles`, `activeProfiles`,
  `newMatches`, `messages`) starts at hardcoded numbers and **auto-increments every 10s**
  via `setInterval(() => ... + Math.floor(Math.random() * 5))`. Fabricated metrics with
  literally nothing behind them.
- `dashboard/EditProfile.jsx` — the entire form is pre-filled with a hardcoded fake
  person: `name: "Priya Sharma"`, `email: "priya.sharma@example.com"`, a stock Unsplash
  headshot, `"Profile 75% complete"` with a hardcoded `width: "75%"` bar.
- `ProfileMatrimonial.jsx` (route `/ProfileMatrimonial/:matchType`, the "browse
  grooms/brides" page) — a real "Refine Search" filter panel sits in front of a
  hardcoded `profiles.grooms` / `profiles.brides` array of invented people with stock
  photos (one entry, "Shruti Nair", is even copy-pasted three times).
- `Search.jsx` — the top-level advanced search form; `Reset`/`Search` buttons have no
  submit handler. Its `motherTongues` option list also contains two junk placeholder
  strings — `"hdhgjhs"`, `"dfeff"` — an authoring mistake, not real data.
- No shared chat infrastructure exists for this — this app's `lib/chat_page_new.dart`
  was checked and has nothing Matrimonial messaging could plug into, so no attempt was
  made to wire the Messages tab to it.

Per this app's rule against fabricated data, fake success states and fake metrics, the
decision (made by the app's owner, executed here) was: **build every screen and field
faithfully from the source — the field/layout definitions are real and worth porting —
but never wire a non-functional path to a fake success, and never carry forward a
fabricated number.** Every screen renders; every button that can't really do anything
says so out loud instead of silently doing nothing.

### New files

```
lib/matrimonial/
  models/matrimonial_profile.dart            registration/search/browse/edit field sets
                                              + option lists (religion, caste, mother
                                              tongue, education, profession, income, …)
  ui/
    matrimonial_landing_page.dart            hero, membership plans, success stories
    matrimonial_registration_page.dart       4-step wizard (Profile/Family/About/Phone)
    matrimonial_search_page.dart             Profile-ID / Category advanced search form
    matrimonial_profile_page.dart            browse grooms/brides + filter panel
    dashboard/
      matrimonial_dashboard_page.dart        tab shell (Matches/Activity/Messages/
                                              Interests/Advanced Search/Profile)
      matrimonial_edit_profile_page.dart     blank tabbed profile editor
test/matrimonial_layout_test.dart            320/360/375/390/414px + 1.2x text-scale,
                                              14 tests (registration wizard + dashboard)
```

No `data/matrimonial_api.dart` exists, on purpose — there is nothing for it to call.
No API-shape test file exists either, for the same reason (unlike Honeymoon's
`honeymoon_api_test.dart` or Wedding Websites' `wedding_website_api_test.dart`).

Navigation: `lib/Bottombars/morescreen.dart` gained a "Matrimonial" menu item (next to
"Wedding Website"), following the same `_buildMenuItem`/`_handleMenuTap` pattern as
every other entry, routing to `MatrimonialLandingPage`.

### What's UI-only vs. gated

| Screen/feature | Built? | Behavior when tapped |
|---|---|---|
| Landing page, plan tiers, success stories | Full UI | Static marketing content, same as source. "Select Plan" and "View Profile" (which had **no** `onClick` at all in the source — silent no-ops) now show an honest gated snackbar instead of doing nothing. |
| Registration wizard, all 4 steps | Full UI, real validation ported from `validateStep()` | "Send OTP" → *"OTP verification isn't available yet."* Does **not** set a fake `phoneVerified` flag. "Complete Registration" (re-validates step 1) → *"Registration isn't available yet — please check back soon."* Neither a `Swal` popup nor any saved state. |
| Advanced Search (top-level and the dashboard's "Advanced Search" tab, which embeds the same form — matching how the source's `AdvancedSearch.jsx` wraps `<Search/>`) | Full filter form, both Profile-ID and Category modes | "Find Profile" / "Search" / "Reset" → Reset actually clears local filter state (harmless, no backend involved); Search/Find → *"Search isn't available yet."* |
| Browse grooms/brides (`matrimonial_profile_page.dart`) | Full "Refine Search" filter panel (age range, marital status, diet, …) | No hardcoded profile grid (source has one, with a person copy-pasted 3 times) — an `EmptyState` ("No profiles available yet") in its place. "Apply Filters" → gated message, not a fake filtered list. |
| Dashboard: Matches tab | Empty-state shell | *"No matches available yet"* — no hardcoded `sampleProfiles`. |
| Dashboard: Activity tab | Empty-state shell | *"Activity not available"* — no hardcoded `mockData`. |
| Dashboard: Messages tab | Empty-state shell | Reproduces the source's own honest "Service Unavailable" copy — this one was already disabled in the source, not something newly gated here. |
| Dashboard: Interests tab | Empty-state shell | *"Interests not available"* — no hardcoded sent/received lists, no no-op Accept/Decline buttons. One deviation from source: the source's own `sidebarItems` array comments out the Interests entry, making that tab unreachable from its sidebar even though the section component still exists. This port makes it reachable — there was no reason to reproduce that particular omission. |
| Dashboard stats (profile/match/message counts) | **Not built** | A static "Coming soon" tile with **no numbers at all**, replacing the source's `Math.random()`-incrementing counters outright — this is the fabricated-metric pattern the app's rule specifically forbids. |
| Dashboard: Profile tab | Empty-state shell (not in the original table, added for honesty) | Since registration never actually saves a profile anywhere, this tab can't show "your profile" — *"You haven't completed your profile yet"* with a link to Edit Profile, rather than the source's hardcoded "Tim Kook" fallback profile (`sections/Profile.jsx`'s default `user` prop). |
| Edit Profile | Full blank tabbed form (Basic Details / Religious Background / Professional Details / Personal Info) | Starts **completely empty** — the source pre-fills "Priya Sharma" and a stock photo. The source's hardcoded "Profile 75% complete" bar is dropped entirely (same fabricated-metric category as the dashboard stats), not replaced with a computed one. "Save Changes" → *"Saving isn't available yet — please check back soon."* Avatar picker is local-preview-only (via `image_picker`, same as `wedding_website_form_page.dart`'s convention) — nothing is uploaded, since there is nowhere to send it. |

### Data model field list (extracted from source, for spot-checking)

From `MatrimonialRegistration.jsx`'s `formData` (`MatrimonialRegistrationDraft`):
`profileFor`, `profileType`, `name`, `showName`, `dob`, `motherTongue`, `religion`,
`caste` (options depend on `religion` — only Hindu and Muslim have any in the source),
`casteNoBar`, `manglik` (manglik / non-manglik / dont-know), `phone`, `familyType`,
`brothers`/`marriedBrothers`/`unmarriedBrothers`, `sisters`/`marriedSisters`/
`unmarriedSisters`, `fatherOccupation`, `motherOccupation`, `aboutYourself`, `hobbies`,
`partnerExpectations`. (`phoneVerified` and `errors` are the source's own transient UI
state, not profile data — handled as page-local state here instead.)

From `Search.jsx`'s three-section `formData` (`MatrimonialSearchFilters`): basic —
`minAge`/`maxAge`, `maritalStatus`, `religion`, `caste`, `motherTongue`, `country`,
`state`, `city`; education — `education`, `educationField`, `profession`, `income`;
lifestyle — `diet`, `smoke`, `drink`, `bodyType`.

From `ProfileMatrimonial.jsx`'s filter panel (`MatrimonialBrowseFilters`, a second,
independent shape — the source keeps these as two unrelated forms): `selectedCities`,
`ageRange`, `heightRange` (min/max), `maritalStatus` (multi-select), `education`,
`profession`, `income`, `diet` (multi-select), `motherTongue`, `community`.

From `dashboard/EditProfile.jsx`'s `formData` (`MatrimonialEditProfileFields`): `name`,
`email`, `phone`, `dob`, `height`, `maritalStatus` (present in source state but never
actually rendered by any `renderEditableField` call — dead field, kept in the model for
fidelity but not given an editor here either), `religion`, `caste`, `motherTongue`,
`location`, `education`, `profession`, `income`, `about`, `hobbies`.

**Option-list decisions** (no existing religion/caste/mother-tongue dropdown was found
anywhere else in this app to reuse — checked and confirmed absent): the mother-tongue
list drops the source's two junk placeholder strings (`"hdhgjhs"`, `"dfeff"` from
`Search.jsx`) and extends the source's short list with the other major Indian
languages already implied by the caste/religion options, so the list reads as a real
option set rather than a truncated demo one.

**Not ported as literal content:** `Home/Hero.jsx`'s image carousel — `swiperImages` is
the same Unsplash URL repeated six times, a copy-paste bug, not content. Replaced with a
static decorative panel instead of inventing six different stock photos or reproducing
the bug.

### What this needs before it can become real

This module cannot become functional from the Flutter side alone. Before any of the
gates above can be lifted, the product needs:

1. **Real backend endpoints** — registration submit, profile fetch/save, search,
   matches, interests (send/accept/decline), and a stats endpoint. None exist today, in
   this repo or in the live `happywedz.com/api` surface (unlike Honeymoon/Wedding
   Websites, no endpoint was found or probed for this module — there was nothing to
   probe).
2. **A product decision on OTP delivery** — an SMS provider, a verify-code flow, and
   what happens if verification is skipped or fails.
3. **A product decision on messaging** — either a new backend for Matrimonial chat, or
   an explicit decision to reuse this app's existing `lib/chat_page_new.dart`
   infrastructure (checked: it currently has nothing Matrimonial-specific to hook into).
4. **A product decision on matching** — what "My Matches" actually means (mutual
   interest? algorithmic suggestion?) before that tab can show anything real.

Until then, this module should be treated as a **preview of the UI only**. Anyone
picking this up next should not wire any of the gated actions to a real endpoint
without first re-confirming the request/response shape against a live backend — none of
the shapes here are guesses, because there was nothing in the source to guess from.

Verified: `flutter analyze` — 290 issues, unchanged from the pre-existing baseline (zero
new issues). `flutter test` — all existing tests plus 14 new layout tests pass (167
total). Not verified on a live device — there is no backend behavior to verify; the
layout tests are the coverage for this module.
