# Full src → Flutter audit matrix

Complete, function-level comparison of every module in the React reference tree
(`src (1)/src`) against the existing Flutter app (`lib/`). Started 2026-09-18 per
an explicit directive to re-audit **everything**, including modules previously
assumed correct because "it already exists."

Format per item: **SRC → Existing App → SAME / DIFFERENT / MISSING / NEW /
OBSOLETE / NOT VERIFIED → REQUIRED ACTION**.

## Executive summary

All 21 module rows below are complete. This audit found the app to be in
better shape than the original brief assumed in some areas (Honeymoon, Cabs,
Wedding Websites' backend are all faithfully ported) and worse in others
(several real, confirmed functional bugs — not stylistic gaps — below).

### Confirmed real bugs (not style/parity gaps — actual broken functionality)
1. ✅ **FIXED (2026-09-18): Guests: `seat_number` was silently dropped on every re-fetch** — a data-loss bug. Added `seatNumber` to the live `Guest` model (`lib/guestlist/guestlist.dart`) and surfaced it as an info chip on the guest card. (§11)
2. ✅ **FIXED (2026-09-18): Messages inbox (`lib/InboxScreen.dart`) was completely non-functional** — hardcoded "No messages yet", never called any API. Added `ChatService.fetchConversations()` (`lib/chat_page_new.dart`, new `GET messages/user/conversations` call + vendor-detail enrichment + dedup, mirroring the source's `normalizeConversation`/`deduplicateConversations`) and rebuilt `InboxScreen` to load, search, and open real conversations, with loading/error/empty states. Pre-existing dead no-op buttons (Start Chatting, New Group, Find People, Scan QR, New Chat) were removed from the live UI and preserved commented-out per the project's dead-code convention, since this app has no "start a chat without an existing vendor" flow to wire them to. (§11)
3. ✅ **FIXED (2026-09-18): Review photos were silently discarded** — `ReviewData` now carries the picked images across screens, and `_submitReview` (`lib/Review.dart`) sends a real multipart request with a `media` file per image when any are attached, falling back to the original JSON path when there are none. (§17)
4. ✅ **FIXED (2026-09-18): Movment Plus consent checkboxes didn't actually gate the button** — `MomentPrivacyDialog` (`lib/movment_plus/upload_selfie_screen.dart`) is now stateful with two real checkboxes; "I Consent" is disabled until both are checked, matching the web's `allAgreed` gate. (§9)
5. ✅ **FIXED (2026-09-18): RealWeddingForm's "Save Draft" showed a fake success message and persisted nothing** — `lib/RealWedding/share_ur_story.dart` now genuinely saves a local (SharedPreferences) draft of every text/selection field on tap, restores it on next visit, and clears it after a successful submit. Images are intentionally excluded from the draft (not reliably restorable across sessions) — a documented scope cut, not a silent gap.
6. **NOT FIXED — needs a live/product decision, not a code change: Business Claim's payload-shape mismatch.** Flutter's multipart submission (claimant info + 7 documents) is already the more complete, presumably-working implementation in production; the audit's concern was whether the *backend* accepts it correctly, which can't be safely tested by sending more real claims to production. Left as-is; flagging to product/backend rather than guessing at a change that could regress a working feature. (§17)
7. **NOT FIXABLE from this repo: AI Hub's 4-of-5 live HTTP 500s.** Confirmed via direct `curl` to be a deprecated Groq model ID on the backend (`llama-3.3-70b-versatile`) — there is no backend source in this repository (see `MIGRATION_NOTES.md` §1), so this needs the team that owns the AI service. (§14)

### Missing entirely (real, user-facing gaps)
- **All static/legal pages** (Privacy Policy, Terms, Contact Us) have zero presence in the Flutter app — no screen, no menu entry. Likely an app-store compliance issue. (§8/17-19)
- **Blog detail page never fetches the full article** — only shows the short list-excerpt; no rich body, images, tags, or reading time. (§16)
- **UserProfile is missing name edit, country field, photo upload, and any password-change flow.** (§11)
- **Booking dashboard cards have no tap/cancel/download actions at all** — a working detail+cancel screen exists elsewhere in the app and just isn't linked. (§11)
- **Destination Wedding and a real Photography inspiration-gallery feature don't exist at all** (Flutter's "Photography" is actually a vendor-listing screen, a different feature wearing the same name). (§15, §3-5)
- **Guests: no bulk import, no PDF export, no persisted guest groups, only RSVP status is editable after creation.**
- E-Invites drafts are **local-only** (lost on uninstall) — the backend save/fetch endpoints already exist in dead Flutter code and just need rewiring, not new backend work. (§6-7)

### Scope/architecture findings requiring a decision, not a fix
- **`adminVendor` (119 files) is confirmed correctly out of scope** — genuine separate B2B vendor console, different auth/role entirely. Vendor login/register screens are correctly absent from Flutter (no valid destination exists for them).
- **Wedding Websites now has two competing entry points** — the new native module built this session, and an older card in `lib/einvite1/einvite.dart` linking to a web builder. Needs reconciling.
- **Design Studio and much of Venues/Vendors' src reference code is either self-disabled or dead/orphaned (unreachable from any route)** — Flutter is often the *only working implementation*, so "parity with src" isn't meaningful for those specific comparisons; a follow-up audit of the actually-live `layouts/Main/*` tree (not audited this pass) is recommended for Venues/Vendors specifically.
- **E-Invites' live src pipeline is broken as committed** (imports files that don't exist in the repo) — this resolved an apparent architecture mismatch found independently in the API audit.
- One item outside Flutter's scope entirely: **uncommitted changes in `src (1)` currently break the web build** (missing imports in `ShaadiAI.jsx`/`HomeGennie.jsx`) — flagged for whoever owns that working tree.

### NOT VERIFIED (need a live device or backend access, listed exhaustively per-section below)
Roughly 20 items across sections need either a live authenticated device session or a direct backend check to confirm — these are called out individually in each module's section rather than summarized here, since guessing at them would violate the audit's own ground rules.

This file is a work in progress and is being filled in module by module. Do
not treat an absent section as "checked and fine" — see the status table.

## Module status

| # | Module | src scope | Status |
|---|---|---|---|
| 1 | Auth (customer + vendor login/register/forgot) | `components/auth/*` | **Done** — real gaps found (no forgot-password, orphaned register screen) |
| 2 | Home page & marketing sections | `components/home/*`, `pages/Home.jsx`, `MainSection`, `SubSection` | **Done** |
| 3 | Venues | `Venus.jsx`, `SubVenues.jsx`, `layouts/venus` | **Done** — src trees found to be dead/orphaned routes; live route (`layouts/Main/*`) needs a follow-up pass |
| 4 | Vendors (browse/detail/360/top-rated/verified) | `Vendors.jsx`, `SubVendors.jsx`, `Vendor360View.jsx`, `TopRatedVendors.jsx`, `VerifiedVendors.jsx`, `layouts/vendors` | **Done** (same dead-route caveat) |
| 5 | Photography | `PhotographyDetails.jsx`, `layouts/photography` | **Done** — fundamental feature mismatch found (photo-inspiration gallery vs vendor listing) |
| 6 | Design Studio | `pages/designStudio/*`, `FinalLookPage.jsx`, `ProfileImageSelector.jsx` | **Done** — src version is self-disabled; Flutter is the only working implementation |
| 7 | E-Invites | `EinviteHomePage/EditorPage/CategoryPage/SharePage/ViewPage`, `layouts/eInvite`, `layouts/einvites`, `pages/cardEditor`, `OurCards.jsx` | **Done** — src's live pipeline is broken (missing files); resolves the E-Invites divergence flagged in §21 |
| 8 | Real Weddings | `RealWedding.jsx`, `layouts/realWedding` | **Done** — mostly parity, 2 real gaps (dropdown filters, vendor-tag navigation) |
| 9 | Movment Plus | `components/movment-plus/*`, `pages/movments-plus/*` | **Done** — 1 real bug found (consent gate) |
| 10 | Honeymoon/Travels | `pages/Travels/honeymoon`, `hotelbeds`, `CityDetails` | **Done** — prior doc confirmed accurate except one mischaracterization (Hotelbeds); CityDetails is src-side dead code |
| 11 | User Dashboard (all sub-tabs) | `pages/userDashboard/*` (booking, budget, cabBookings, checklist, flightBookings, guests, messages, realWeddingForm, userProfile, vendors, wedding, wishlist) | **Done** — real data-loss bug found (guest seat numbers), broken Messages inbox found, hired-vendors question resolved |
| 12 | Wedding Websites | `MyWeddingWebsites`, `WeddingWebsiteForm/View`, `WeddingPublicView`, `templates/*` | **Done** — built and independently spot-checked earlier this session (see §12) |
| 13 | Matrimonial | `pages/matrimonial/*` | **Done** — built and independently spot-checked earlier this session (see §13) |
| 14 | AI Hub | `AIFeaturesHub.jsx`, `ChatFeatures.jsx`, `Genie.jsx`, `ShaadiAI.jsx`, `PersonalityQuiz/ConflictResolver/CultureBlender/TimelineGenerator` | **Done** — backend outage found (4 of 5 AI features 500 on a deprecated model id), plus an unrelated src build-breaker |
| 15 | Destination Wedding | `DestinationWedding.jsx` + 5 related files | **Done** — confirmed missing, full build spec produced |
| 16 | Blog | `Blog.jsx`, `BlogDetails.jsx`, `BlogLists.jsx` | **Done** — real feature exists (as "Interesting Reads"), several real gaps found |
| 17 | Reviews | `ReviewSection.jsx`, `ReviewWidgetPage.jsx`, `WriteReviewPage.jsx` | **Done** — 1 real functional bug (photos silently dropped on submit) |
| 18 | Business Claim | `BusinessClaimForm.jsx` | **Done** — high-priority payload-shape mismatch flagged |
| 19 | Static/legal pages | `PrivacyPolicy`, `TermsCondition`, `CancellationPolicy`, `Contactus`, `CareersPage`, `SiteMap`, `NotFound` | **Done** — entire category missing from Flutter |
| 20 | Vendor dashboard (`adminVendor`) | `pages/adminVendor/*` (119 files) | **Done** — out-of-scope classification confirmed correct |
| 21 | Cross-cutting: every API endpoint | `services/api/*.js` (18 files) | **Done** — 136 endpoints checked, 78 called, 58 not (E-Invites divergence flagged as a real issue) |

## Sections

## 9. Movment Plus

**Feature identity**: AI-powered wedding photo sharing between a photographer/vendor and their client's guests. Not a loyalty/points/subscription product — no tiers, no pricing, no payment flow of any kind on either platform. A guest enters an access token (given by their photographer) to view an event's photo gallery, optionally uploads a selfie, and an AI service (`happywedzai`/`samaroai`) face-matches it against the gallery so the guest can see only their own photos.

| SRC item | Existing App item | Status | Required action |
|---|---|---|---|
| `movmentPlusApi.getGalleryByToken` → `GET /gallery/:token` | `guest_token_screen.dart` `fetchGallery()` → `GET {apiBase}/gallery/$token` | SAME | None — same endpoint/shape, both parse `success`/`collections`. |
| `movmentPlusApi.uploadFile` → `POST /gallery/:token/upload` (comment: "Placeholder endpoint — verify with backend team") | No Flutter equivalent (no vendor/guest direct-upload UI exists) | NOT VERIFIED | Endpoint is explicitly unconfirmed even on the web side; needs a live call to the backend team before any Flutter parity work is considered. Not a missing-feature gap by itself. |
| `movmentPlusApi.uploadSelfie` → `POST {AI}/events/selfie`, `X-User-ID` header, 120s timeout | `MovmentPlusApi.uploadSelfie` → same path/host, same header, 2‑min timeout | SAME | None. |
| `movmentPlusApi.getMyPhotos` → `GET {AI}/events/my-photos`, `X-User-ID`, 240s timeout | `MovmentPlusApi.getMyPhotos` → same, 4‑min timeout | SAME | None. |
| Guest Token screen (`GuestTokenPage.jsx`) — token input, verify, redirect, remembers last token in Redux/localStorage, help text "Try: ABC123 or XYZ789" | `guest_token_screen.dart` — token input, verify, `GuestTokenStore` (SharedPreferences) | SAME | Cosmetic only: web shows example tokens/help text guests can copy; Flutter has an "info" caption ("tokens are case-sensitive") but no example. Low priority copy sync. |
| Gallery view — folder/collection grid → open collection → lightbox with prev/next/keyboard nav, "Find My Photos" CTA | `MomentGalleryHome` — folder grid → `FullImageViewer` (pinch-zoom, download button) via `InteractiveViewer`, no folder-open intermediate lightbox counter/arrows | DIFFERENT | Flutter's `FullImageViewer` opens one image directly (no left/right arrow nav or "X / Y" counter inside the viewer, no keyboard support — expected, mobile). Functionally acceptable; not a defect, just a different but equivalent interaction model. No action required unless product wants swipe-between-photos parity. |
| Gallery "empty collection" state ("No images in this collection yet.") | No literal equivalent found (Flutter renders whatever grid it gets; empty state not explicitly styled) | MISSING | Low-priority: add an empty-state message in `MomentGalleryHome`'s collection grid for parity. |
| "My Photos" flow: policy/consent modal (2 checkboxes: 18+, AI consent) → selfie or file upload → poll for matches → loading/error/empty/success states with exact copy ("Looking for you in this gallery...", "This can take a minute or two", retry) | `MomentPrivacyDialog` (2 checkboxes, same copy) → `MomentFindPhotos`/`MomentCaptureSelfie`/`MomentUploadSelfie` → `MomentMyPhotos` (`_StatusCard` loading/error/empty states, same "This can take a minute or two" copy) | SAME, except one real bug — see next row | None for the flow shape/copy. |
| Consent checkboxes gate the button on web (`allAgreed` disables submit until both checked) | `MomentPrivacyDialog`'s `_checkRow` renders pre-checked static icons — not real checkbox state | **DIFFERENT — real bug** | "I Consent" is not actually gated on agreement in Flutter, unlike the web's legal/consent enforcement. **Fix: make the two checkboxes real, interactive state and disable the consent button until both are checked.** |
| Selfie capture — web: in-page `getUserMedia` camera preview + capture, or file picker, both in one modal | Flutter: native camera via `image_picker` (`ImageSource.camera`) or native gallery picker, no in-app live preview | SAME (equivalent, platform-idiomatic) | None — correct mobile pattern. |
| Payment / points / rewards | None on either side | SAME (N/A) | Confirmed no payment or loyalty mechanic exists on either platform despite the "Plus" branding. No action. |
| Landing/marketing page: `MovementPlusHome.jsx` = Hero + `Brands` marquee + `HomeGridImages` (9 static images) + `EventCreationTabs` (4 interactive tabs, distinct content each) + CMS testimonials + `SmartPhotoSharing` promo + CMS `RealWeddings` | `movment_plus_dashboard.dart` — static hero carousel (3 local images), static "Recent Wedding Moments" row, non-interactive `_StepsRow` (labels only, no tap-to-switch, always shows tab-1 content), one static promo card, real testimonial API call | DIFFERENT | Web's page targets B2B photographer visitors, not guests; the guest app has no vendor-signup flow. Recommend marking this landing content **OBSOLETE for parity purposes** rather than building out the 4-way tab switcher — confirm with product whether photographer-facing marketing belongs in the guest app at all before investing further here. |
| CMS testimonial route (`cmsApi.whatCouplesSays.getData()`) vs Flutter's `GET {apiBase}/what-couples-says-route` | — | NOT VERIFIED | Same field shape used on both sides, but the exact route string wasn't diffed since the web wrapper resolves it internally — low risk. |
| `lib/movment_plus/login_screen.dart` (placeholder text, unused) | Excluded from `CustomBottomBar._screens` already | OBSOLETE (dead code) | Already correctly excluded from the live nav; leave commented/unused per the project's dead-code-stays-commented convention. |
| Guest "Exit Gallery" (clears token, on web sidebar) | No explicit "clear/exit gallery" button found in the files read | NOT VERIFIED / possibly MISSING | Needs a wider `lib/` search beyond `movment_plus/` (e.g. a settings screen) before concluding it's actually missing. |

### Required actions
1. **Fix the consent-gating bug** — real checkbox state needed in `MomentPrivacyDialog`, gating the "I Consent" button, to match the web's legal/consent enforcement.
2. Confirm with product whether the photographer-facing marketing landing content is in scope for the guest app; if not, stop tracking it as a gap.
3. Two NOT VERIFIED items need a live backend check, not more code reading: the `/gallery/:token/upload` endpoint's legitimacy, and the exact CMS testimonial route.
4. Confirm whether an explicit "exit/clear gallery" action exists anywhere else in the Flutter app before calling it missing.

## 1. Auth

**Top-line finding**: Flutter's *live* auth surface is Google + Apple sign-in only (`SignInScreen` in `lib/main.dart`, reached via `AuthGate`). There is no live email/password login, no live customer register form, no forgot-password flow, and no vendor auth of any kind in Flutter. A full email/password register screen (`SignUpScreen`, `lib/registration.dart`) exists but is **never imported or navigated to from anywhere** — orphaned dead code, not commented out per this project's dead-code convention (should be, or wired in). `lib/login.dart`/`lib/newauth.dart` are already fully commented out (compliant). Vendor auth is confirmed **intentionally** absent — `SignInScreen._openVendorApp()` deep-links to a separate Play Store app (`com.happy.happy_weds_vendors`).

### Customer Login — SRC (`CustomerLogin.jsx`) vs Flutter (`SignInScreen`)
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| Email + password fields, no client regex | No email/password fields exist | MISSING | Confirm mobile is intentionally social-login-only; undocumented anywhere today. |
| "Remember me" checkbox (tracked but never read in submit — dead UI on src) | N/A | N/A | src-side bug, unrelated to Flutter parity. |
| "Forgot Password?" → `/user-forgot-password` | No forgot-password screen/route anywhere | MISSING | Add if email/password ever ships on mobile; else document as out of scope. |
| Google Sign-In → `POST /user/google-auth {tokenId}` | Google Sign-In → `POST {baseUrl}/user/google-auth {email, name, tokenId}` | DIFFERENT | Flutter sends extra fields. **NOT VERIFIED** whether backend ignores or requires them. |
| Apple Sign-In | Flutter-only, `POST /user/apple-auth {id_token}`, iOS-only | NEW (Flutter-only) | Confirm mobile/iOS-only is deliberate. |
| Session expiry: `localStorage`, 2-day rolling | `SharedPreferences`, 2-day rolling (`AuthSession._isExpired`) | SAME | None — policy genuinely matches. |
| Post-login redirect resumes the page/booking the user came from | `AuthGate` always lands on Home, no "resume where I was" | DIFFERENT | **NOT VERIFIED** — trace every "please sign in" entry point to confirm users aren't dropped back to Home mid-task. |
| CMS-driven login copy (`/login-cms`) | Hardcoded "Welcome to HappyWedz" | MISSING | Likely intentional for mobile; confirm and document. |
| "I am a vendor" → `/vendor-login` | Deep-links to separate vendor Play Store app | DIFFERENT by design | Documented architecture, no action. |
| Hardcoded `captchaToken: "test-captcha-token"` | N/A | N/A | src-side: looks like an unfinished/disabled CAPTCHA, flag independently. |

### Customer Register — SRC (`CustomerRegister.jsx`) vs Flutter (`SignUpScreen`, unreachable)
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| Entire form (name/email/password/phone/venue/country/city/date), `POST /user/register`, auto-login | Full equivalent form exists in `lib/registration.dart` but is **never navigated to from anywhere** | MISSING (effectively) | Wire `SignUpScreen` into the app, or comment it out per project convention — it's live code with no caller today. |
| Password regex: needs upper+lower+digit+8 chars, but **error text incorrectly claims a special char is also required** | Orphaned screen: length ≥ 8 only | DIFFERENT + src bug | Fix misleading src error copy regardless of Flutter status. |
| Country/City from live `countriesnow.space` API | Orphaned screen: hardcoded 5-country list + hardcoded city map | DIFFERENT | Moot while unreachable; align if revived. |
| Static `captchaToken: "test-captcha-token"` | Orphaned screen: real WebView reCAPTCHA v3, but server-side verification stubbed to `return token.isNotEmpty` per an in-code "AUDIT FIX" comment (hardcoded secret had leaked in shipped APKs) | DIFFERENT, both non-functional | **NOT VERIFIED** whether backend independently validates the token. |
| On success: persists session, logs user in | Orphaned screen: shows success popup only, does **not** persist a session or navigate in | DIFFERENT | Moot while unreachable; must fix if revived. |
| Welcome email via SMTP | Already disabled in Flutter with an explicit "AUDIT FIX (CRITICAL security)" comment (leaked Gmail credential) | OBSOLETE (handled) | **NOT VERIFIED** that the leaked password was rotated outside this repo — infra action. |
| Registration collects role/wedding-date/city in one form | Flutter collects the same via `UserRoleScreen`/`WeddingDateScreen`/`WeddingCityScreen` post-first-login | NOT VERIFIED | No confirmed `http.post` call syncing this to the backend's fields in the ranges sampled — needs a deeper trace. |

### Forgot Password (Customer) — SRC (`ForgotPassword.jsx`) vs Flutter (none)
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| Email → OTP → new/confirm password, two endpoints | No forgot-password screen or route anywhere (confirmed via repo-wide grep) | MISSING | Confirm this is an intentional consequence of social-login-only mobile; if any legacy password account exists, mobile users have no recovery path. |
| Backend returns raw `otp` in the response ("for testing") | N/A | N/A | src/backend security concern — OTP appears returned to client rather than only via email/SMS. **NOT VERIFIED** without live backend inspection. |
| UI copy says "reset link" but flow is actually 6-digit OTP | N/A | N/A | src-side copy bug, fix regardless of Flutter parity. |

### Vendor Login / Register / Forgot Password
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| Full vendor auth surface (`VendorLogin/Register/ForgotPassword.jsx`) | None — confirmed no vendor auth exists anywhere in `lib/`; `SignInScreen._openVendorApp()` explicitly hands off to a separate app | OBSOLETE / not applicable here | Appears to be a deliberate, documented architecture split (separate vendor app), not an oversight — confirm with product owner it's still intended, and record it so future audits stop re-flagging it. |

**Required actions from this section**: (1) decide the fate of the orphaned `SignUpScreen` — wire it in or comment it out; (2) confirm the Google-auth payload mismatch is harmless; (3) confirm whether mobile needs a forgot-password path at all; (4) trace whether post-first-login onboarding screens actually sync to the backend.

## 2. Home page & marketing sections

Live class confirmed: `_WeddingHomePageState` (`HomeScreen.dart` lines 957-3807); the dead `_HomeScreenState` (lines 59-948) was excluded per its own AUDIT NOTE.

| SRC section | Existing App section | Verdict | Required action |
|---|---|---|---|
| Hero search (`Herosection.jsx`) — CMS hero banner + category dropdown + vendor live-search (limit=30, 400ms debounce) + city filter | Plain gradient header + inline search (same endpoint, limit=8, 400ms debounce) + `_CitySearchDelegate` | DIFFERENT | No CMS hero banner in Flutter at all; search result limit differs (8 vs 30). Confirm intentional (mobile header vs desktop hero) or align. |
| Explore by Category (`WeddingCategories.jsx`) — capped to 6, tap expands subcategory pills, "Explore X" → full category listing | `_buildCategorySection` — shows **all** categories, tap jumps straight to the *first* subcategory only, no chooser | DIFFERENT | Real UX divergence: React lands on the whole category; Flutter lands on only the first subcategory. Confirm intentional or fix. |
| Planning Tools CTA — data-driven: Budget Planner, Wedding Checklist, Guestlist Manager | `_buildPlanningToolsSection` — 3 hardcoded cards: Digital E-Invites, Shortlisted vendors, Favourite blogs | DIFFERENT | Entirely different tool set in the same slot. Flutter has Budget/Guestlist screens already — just not linked from here. |
| Wedding Gallery / Masonry (`MansoryImageSection.jsx`) — live photography feed | none | MISSING | No equivalent rail in Flutter home. |
| Venue Slider — Swiper w/ autoplay + filter tabs (Top Rated/Banquet/Recommendation) | `_buildVenuesSection` — static horizontal list, no autoplay, no filter tabs | DIFFERENT | Carousel behavior and filter tabs both diverge. |
| Real Weddings section — React: single CMS-driven banner (curated images, hardcoded Unsplash fallback if CMS empty) | Flutter: **actual live listing** rail from `GET /realwedding/public`, real records | DIFFERENT (Flutter likely more correct) | React's version is a CMS banner, not real listings, with hardcoded fallback images if empty — flag as src-side mock content. Confirm Flutter's live-listing approach is the intended direction. |
| Testimonials (`MainTestimonial.jsx`, CMS-driven with hardcoded Unsplash+Lorem-ipsum fallback) | none | MISSING | No testimonials rail in Flutter home at all. **NOT VERIFIED** whether the CMS endpoint currently returns real content. |
| Blog Inspiration Teasers — same `GET /blogs/all` endpoint/fields, Swiper autoplay, no "view all" link | `_buildInterestingReadsSection` — same API/fields, static list, has a "View all" button | SAME (data) / DIFFERENT (UX) | Minor: React has no "view all" where Flutter does; carousel autoplay differs. |
| How It Works, Metro Cities, Statistics Section, Popular Searches, Featured Vendors, Newsletter, CardComponent.jsx | none | OBSOLETE (mostly dead/commented-out or 100% hardcoded fake data even in src) | Confirmed dead or fully mock on the src side itself (e.g. Statistics Section is unimported, "50,000+ Happy Couples" fake numbers) — no action needed beyond noting these were never real. |
| — (no src equivalent) | Wedding Checklist progress card, Budget/Guests/Wishlist summary cards | NEW (Flutter-only) | Flutter is ahead here — real, live-data widgets with no src equivalent. Not a defect. |
| `_buildTrendingTodaySection`, `_buildHappyWedsServicesSection`, `_buildWeddingIdeasSection`, `_buildFeaturedVideoSection` | — | OBSOLETE (Flutter) | Defined but hardcoded/dead, call sites already commented out — correctly disabled already. |

**Cross-cutting**: both apps' city pickers hit the same third-party `countriesnow.space` API, not the HappyWedz backend — shared external dependency, not a parity bug. Image fallback/placeholder handling is consistent on both sides. **NOT VERIFIED**: current real-vs-fallback content of `/what-couples-says-route`, `/einvite-banner`, `/real-wedding-photo-cms` — needs live API checks.

## 15. Destination Wedding

**Confirmed MISSING** — `MIGRATION_NOTES.md`'s prior "❌ missing" classification is accurate. Full build spec:

### Screens (src)
| File | Purpose | Lines |
|---|---|---|
| `DestinationWedding.jsx` | Listing/landing, composes all sections | 59 |
| `DestinationHero.jsx` (`WeddingHero`) | Static hero banner | 151 |
| `DestinationWeddingDetailPage.jsx` | Per-destination detail (slug route): overview, best season/cost/styles, top venues, travel tips, checklist, FAQs, snapshot gallery | 396 |
| `DestinationWeddingLocation.jsx` (`DestinationWeddingLayout`) | Browse carousel/grid, "See Details" → detail by slug | 505 |
| `DestinationWeddingPlanningIdeas.jsx` (`BlogCardsSection`) | **Generic blog teaser** — not destination-specific at all, just fetches `/blogs/all` | 339 |
| `DestinationWeddingRealStories.jsx` (`RealWeddingsStatic`) | **Generic real-wedding teaser** — fetches `/realwedding/public/`, no destination filter | 205 |

**Key finding**: this is a static/hardcoded-content feature at its core (all destination data comes from a static array in `data/designationWedding.js` [sic, typo in src filename] — no CMS, no API), wrapped by two components that reuse generic Blog/Real-Wedding data with zero actual destination-specific filtering despite their names.

### Data model (static, from `designationWedding.js`)
Per destination: `id`, `slug`, `title`, `subtitle`, `heroImage`, `cardImage`, `description`, `overview`, `bestSeason`, `averageCost`, `weddingStyles[]`, `highlights[]`, `topVenues[]`, `travelTips[]`, `faqs[]`, `snapshotImages[]`, `checklist[]`. Stock/Unsplash images, not real vendor data.

### Business logic
No filtering/search/sort on the browse grid. No booking/enquiry flow — detail page has only a generic "Contact US" link, no quote form. **No linkage to the Honeymoon module at all** — fully separate route trees despite conceptual overlap; do not conflate the two.

### Flutter side — confirmed nothing real exists
Grepped "destination" case-insensitively: only false positives (honeymoon flight origin/destination terminology, a single hardcoded "Goa Destination Wedding" package-card screen in `lib/packages.dart` with two fixed price cards — not data-driven or browsable, a dropdown filter option inside `VenuesScreen.dart`, and unrelated text fields elsewhere). None constitute a real module.

### Scope verdict
Small-to-medium, **not monolithic**: build ~2-3 new screens (hero/listing/detail) + a Dart data model for the 4 genuinely destination-specific files; for the other 2 files (planning-ideas, real-stories), **reuse/link the existing Blog and Real Wedding modules** once those are themselves audited/ported, rather than duplicating them.

| SRC item | Existing App | Status | Action |
|---|---|---|---|
| Listing/Hero/Detail/Browse (4 files) | none | MISSING | Build new: ~2-3 screens + data model |
| Planning Ideas (blog teaser) | existing Blog module (see §16) | MISSING as destination-scoped | Reuse/link, don't duplicate |
| Real Stories teaser | `lib/RealWedding/` | MISSING as destination-scoped | Reuse/link, don't duplicate |

## 3-5. Venues, Vendors, Photography

**Single biggest finding**: `Venus.jsx`, `SubVenues.jsx`, `Vendors.jsx`, `SubVendors.jsx`, `VerifiedVendors.jsx`, and the entire `layouts/venus/*` + `layouts/vendors/*` component trees are **not reachable from any route in `App.jsx`** — dead/orphaned src code. The real live routes (`/venues`, `/wedding-venues`, `/vendors/:subcategory/:city`, `/:section`) resolve to `MainSection.jsx` + `layouts/Main/*` + `hooks/useInfiniteScroll` instead, which were **not** in this audit's file list and need their own follow-up pass — treat every "OBSOLETE" row below as "compared against dead code," not as "compared against what real website users actually see."

### Venues
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| `Venus.jsx`/`SubVenues.jsx`/`layouts/venus/*` (GridView, ListView, Asideview, VenuesSearch, MapView, ViewSwitcher, VenueCard, etc.) | — | **OBSOLETE (dead src route)** | Comment out per dead-code policy; audit the live `layouts/Main/*` tree instead in a follow-up. |
| Venue search box — src inputs have no `onChange`/state at all (fully decorative) | `VenuesScreen.dart` — real 500ms-debounced server search | DIFFERENT | Flutter is already the more complete implementation. |
| Venue filters (type, deals/award-winner, capacity) — checkboxes update state that `GridView`/`ListView` never consume (cosmetic only) | `VenuesScreen.dart` filter sheet — type/capacity/price-per-plate/price range/rating, all live-wired | DIFFERENT | Flutter is richer and functional; src's filters were decorative even when live. |
| View switcher (List/Grid/Map) — active-tab CSS check can never be true (real src bug) | List/Grid toggle only, no Map | DIFFERENT + bug (src-side) | Flutter has no Map option; src's Map view is a literal `<div>MapView</div>` stub — **MISSING on both sides**, not a Flutter gap specifically. |
| Venue card "Request Pricing" button — no `onClick` handler at all (dead button) | Wishlist toggle persists via `SharedPreferences` + `POST /wishlist/toggle` | DIFFERENT | Flutter's wishlist is the more complete, actually-persisted implementation. |
| Pagination — `SubVenues.jsx` renders static mock data, no real paging | Real infinite scroll, `limit=20`, 200px threshold | DIFFERENT | Flutter ahead. |
| Static marketing blocks (FactorsList, FaqsSection, VenuesByRegion, VenuesHeroSection) | none | MISSING (low priority — src copies are dead too) | No action needed. |
| Venue 360°/virtual tour | `open360Viewer()` in `vendordetailsscreen.dart`, generic to any vendor-service | NOT VERIFIED | Unclear if venues actually surface the 360 entry point in the Flutter venue detail flow — needs a live check. |

### Vendors
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| `Vendors.jsx` (static hero landing) | — | OBSOLETE (dead route) | No action. |
| `SubVendors.jsx` — genuinely API-wired (search, pagination, category filter) but orphaned (no live route) | `VendorServicesScreen` — real, live, search debounce, city/price/rating filters, pagination | OBSOLETE (src) but comparable feature set where it matters | src also supports `categoryId` Flutter doesn't expose; low priority. |
| `layouts/vendors/ListView.jsx` — Quick-Inquiry button references an undefined variable `v` (`ReferenceError` if ever re-wired) | N/A | N/A | src-side bug in dead code; no Flutter action. |
| `QuickInquiryModal.jsx` (name, phone ≥10 digits, event date; `POST /request-pricing` then `/conversations`) | `lib/vendor/request_pricing_sheet.dart` | NOT VERIFIED | Exists but wasn't compared field-by-field; needs a direct pass. |
| `Vendor360View.jsx` — deep-linkable route, supports 360 images, 360 **video**, and an external virtual-tour URL (sandboxed iframe + fallback) | `open360Viewer()` — `imageview360` package, embedded modally, image-list only | DIFFERENT | No standalone/deep-linkable 360 screen; **NOT VERIFIED** whether video/tour-URL handling exists — needs a full read of the viewer block (~line 2698 in `vendordetailsscreen.dart`). |
| `TopRatedVendors.jsx` (routed `/top-rated`) — actually a static hardcoded list of 12 links into venue searches with `minRating: 4`, not a real API-backed feature | none | MISSING (but src itself is mislabeled/static) | Low priority given src's own version isn't real either. |
| `VerifiedVendors.jsx` — real, working: paginated grid, city filter, `GET /vendor-services/verified-images`, but **orphaned (no live route)** | none | OBSOLETE (src) + MISSING (Flutter, independent of routing) | Decide whether Flutter needs a "Verified Vendors" curated view; src's version, if revived, is a legitimate feature to port. |
| Sort by price/rating/popularity | absent in every file audited | MISSING (both sides) | Not a discrepancy — neither side has it here. |
| Reviews (read/write) | `vendordetailsscreen.dart`'s `_buildReviewsSection` (average + 5-category breakdown + tiles) | Separate module, not re-audited here | Cross-reference §17 (Reviews); worth checking whether src's own vendor detail page matches Flutter's depth (out of this task's scope). |

### Photography
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| `TopSlider.jsx` + `SortSection.jsx` + `GridImages.jsx` — a browsable **photo-inspiration gallery** (tagged portfolio images, category/city/tags, independent of any single vendor), wired live inside `MainSection.jsx` | `lib/vendor/photographer.dart` — a **vendor listing/detail screen for photographer vendors** (`subCategory=photographers`) | **MISSING — fundamental mismatch** | These are two different concepts wearing the same name. Flutter has no photo-inspiration browser at all; it only has "browse photographer vendors," the Vendors module scoped to one category. |
| `PhotographyDetails.jsx` — hero+thumbnails, zoom lightbox, tags, share, like (local-only, not persisted), "Browse Similar Photos" | none — `PhotographerDetailsScreen` is a vendor profile, not a photo-detail page | MISSING | No tags/similar-photos/share/like screen for individual inspiration photos exists. (Correctly, src's version has no pricing/booking/map/reviews either — it's an inspiration photo, not a vendor profile; not a gap.) |
| Photography API family (`getPhotographyTypes/Categories/ById/All/ByType/ByCategory`) | Confirmed via grep: **no Flutter code calls any `/photography*` endpoint** — `photographer.dart` only hits `/vendor-services?subCategory=photographers`, a different endpoint family entirely | MISSING | Genuine backend-integration gap, not just UI. |
| Search within photography (client-side, title/description/photographer/city/tags) | none | MISSING | No equivalent screen exists. |

### Cross-cutting
- Map view is non-functional/absent identically on both platforms for Venues and Vendors — one shared MISSING item, not per-platform gaps.
- Wishlist/favorite in the dead src trees is local-state-only with zero persistence; Flutter's implementation (SharedPreferences + API, optimistic update with revert) is the more complete reference.
- **Recommended follow-up**: audit the actually-live `layouts/Main/*` tree (GridView, ListView, MapView, DynamicAside, ViewSwitcher) + `hooks/useInfiniteScroll.js` + `SubSection.jsx`/`Detailed.jsx`, since those — not `layouts/venus`/`layouts/vendors` — are what real website users hit today.

## 8, 17-19. Real Weddings, Reviews, Business Claim, Static pages

### Real Weddings
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| `RealWeddings.jsx` browse — search box, City/Culture/Theme dropdown filters, pagination (6/page), `status==="published"` filter | `lib/ideas.dart`'s Real Weddings tab — free-text search only, no dropdown filters, no pagination (loads full list), `status` filter not visibly applied client-side | DIFFERENT | Add City/Culture/Theme filters and pagination; **verify the server already filters to published-only**, else unpublished drafts could leak into the app. |
| `RealWeddingDetails.jsx` — tagged vendors are **clickable**, navigate to vendor profile | `RealWeddingDetailPage` — vendors rendered as static, non-tappable `Chip` widgets | **DIFFERENT — real gap** | Add tap-to-search-vendor navigation to match; src's vendor-credit-to-profile link is a real feature Flutter lacks entirely. |
| `RealWeddingForm.jsx` — 7-step wizard, rich-text (Summernote) story editor, draft-save to `localStorage`, multipart submit | `ShareWeddingStory` (`lib/RealWedding/share_ur_story.dart`) — 8-step wizard, plain-text story editor (bold/italic/underline buttons update local bools but are never applied to rendered text), "Save Draft" shows a snackbar but doesn't actually persist anything | DIFFERENT (minor/cosmetic) | Low priority: fix the fake "Save Draft" (not backed by any storage write) and either implement real rich-text or remove the non-functional formatting buttons. |
| Moderation: both send `status: "pending"` on create, no in-app admin UI either side | same | SAME | None. |

### Reviews
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| `WriteReviewPage.jsx` — multipart `POST /reviews/:vendorId` with rating fields + `media` files | `lib/Review.dart` — user can pick review photos, but `_submitReview()` sends plain JSON with **no file attachment at all** | **DIFFERENT — real functional bug** | Picked review photos are silently discarded and never uploaded. Fix: switch `_submitReview` to multipart and attach the images. |
| Star ratings + required-field validation | Same gating (`allRated`/`isValid`) | SAME | None. |
| Review submit endpoint path assembly: `API_BASE_URL` (already includes `/api`) vs Flutter's `ApiConfig.baseUrl + "/api/reviews/:id"` | — | NOT VERIFIED | Confirm both resolve to the identical final URL — if they diverge, one client silently 404s. |
| Review display on vendor page | Embedded in vendor detail screens | NOT VERIFIED | Out of this task's scope; cross-reference the Vendors audit (§3-5) which already flagged Flutter's review-display depth as comparable. |

### Business Claim
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| `BusinessClaimForm.jsx` — **intentionally trimmed** per its own inline comment: single-step, only 7 business-info fields, JSON POST to `/business/claims`, explicitly no files | `lib/ClaimBusiness.dart` — full 5-step wizard incl. claimant info, 7 required + 1 optional document uploads, multipart POST to the **same** `/business/claims` path | **DIFFERENT — high priority** | Same endpoint, completely different payload shapes (JSON vs multipart-with-files). **NOT VERIFIED** whether the backend controller correctly accepts both — real cross-platform risk, not just a UI gap. This reads like a deliberate src simplification Flutter was never updated to mirror; flag to product owner. |
| No claim-status tracking anywhere in src | `vendordetailsscreen.dart`'s `checkClaimStatus()` + status-aware `claimButton()` | NEW (Flutter ahead) | None required. |
| `Swal` success alert only, no local record | Generates a local PDF summary of the submitted claim | NEW (Flutter ahead) | None required. |

### Static/legal pages
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| `PrivacyPolicy.jsx` (1009 lines, real content) | No screen, route, or menu entry anywhere | **MISSING** | Add a screen (native or WebView) + menu entry — likely required for app-store compliance. |
| `TermsCondition.jsx` (379 lines, real content) | Only a non-tappable disclaimer string in `registration.dart` | **MISSING** | No way to actually read Terms in-app. |
| `CancellationPolicy.jsx` (226 lines) | Not found anywhere | **MISSING** | Add screen/menu entry. |
| `Contactus.jsx` — real form (name/email/phone/message) posting to `/contact` | Not found anywhere; no `/contact` API usage in Flutter | **MISSING** | Add a Contact Us screen with the same fields. |
| `CareersPage.jsx` (static) | Not found | MISSING (low priority, src is static too) | Optional. |
| `SiteMap.jsx` | Not present | OBSOLETE for mobile | A sitemap doesn't map to native app UX — exclude from parity requirements. |
| `NotFound.jsx` | N/A | N/A | Not applicable to native app architecture. |
| Navigation to all of the above | **None** — `morescreen.dart`'s menu has no Legal/Settings/Help section at all | **MISSING (core finding)** | Add at minimum Privacy Policy, Terms, and Contact Us — likely required for Play Store/App Store compliance — even as simple WebViews pointing at the existing website pages. |

**Cross-cutting NOT VERIFIED (need live API calls)**: (1) `/realwedding/public` vs `/realwedding/public/` trailing-slash routing difference; (2) Reviews endpoint base-path assembly match; (3) whether `/business/claims` backend accepts both the JSON-only and multipart-with-documents shapes without silently dropping fields.

## 16. Blog

**Net assessment: Flutter has a genuine, working blog feature under the name "Interesting Reads"** — confirmed by tracing `_buildInterestingReadsSection()`/`_buildViewAllInterestingReadsButton()` in `HomeScreen.dart`, which hits the same `GET /blogs/all` backend and navigates to a real "Stories" tab in `lib/ideas.dart`, not a stub. This is not a missing module — it's a partial one with specific real gaps.

| Aspect | src | Flutter | Status |
|---|---|---|---|
| List data source | `GET /blogs/all` | `GET /blogs/all` — same endpoint | SAME |
| Home teaser rail | `BlogInspirationTeasers.jsx` | `_buildInterestingReadsSection()` | SAME |
| Full listing screen | `BlogLists.jsx` at `/blog` | `Ideas` "Stories" tab, vertical list | PARTIAL |
| Pagination | Client-side, 6/page | None — renders entire list at once | **MISSING** |
| Search | Debounced server search `GET /blogs/search` + client filter | Search bar exists but wired to state that's never populated for the Stories subtab — **dead/non-functional** | **MISSING (broken)** |
| Category/tag filter | `?categoryId=&type=` support | None | MISSING |
| Detail screen | `BlogDetails.jsx` via `GET /blogs/:id`, full rich-text body (sanitized HTML) with interleaved images, tags, reading time, share buttons | `BlogDetailPage` — **makes no network call at all**, only shows fields already in the list item (short excerpt as plain text) | **DIFFERENT/MISSING — real gap** | 
| Reading time, share buttons, like button | Present | Absent | MISSING |
| Loading/empty/error | Present | Present (skeletons, error/empty text) | SAME |

**Required action**: build a real `GET /blogs/:id` detail fetch with HTML-body rendering (e.g. `flutter_html`), add pagination/infinite scroll to the Stories tab, wire the existing (currently dead) search bar to `GET /blogs/search`, and add share-button parity.

## 20. Vendor dashboard (adminVendor)

**Verdict: the prior "out of scope" classification is CONFIRMED correct**, with one coordination loose end.

`adminVendor` (119 files) is a genuine B2B vendor-business-management console — dashboard/analytics, lead/enquiry management, ~30 storefront/listing-editing files (one per business category), review moderation, a vendor-side inbox for couple messages, Razorpay-integrated subscription/plan management, and the vendor-side admin tooling for Movment Plus (already covered under item #9's couple-facing counterpart). It has its own auth (`vendorAuthApi.js`, `vendorAuthSlice`, separate `vendorToken`), its own route guard (`VendorPrivateRoute`), and its own account/session type entirely separate from customer auth. Porting any of this into a couple-facing mobile app would be architecturally wrong.

| SRC item | Existing App | Status | Action |
|---|---|---|---|
| `adminVendor/*` (119 files) + vendor auth/CRUD | None (by design) | **OBSOLETE / NOT-APPLICABLE** | Leave fully out of scope. |
| `VendorLogin.jsx`/`VendorRegister.jsx`/`VendorForgotPassword.jsx` | No Flutter files exist anywhere | NOT-APPLICABLE | A login screen with no valid destination in this app would itself be a dead end — confirmed the Auth audit (§1) already classified these correctly as OBSOLETE/not-applicable rather than something to port standalone. No conflict between the two audits. |
| "Claim Your Business" flow (the correct couple→vendor-onboarding bridge) | `lib/ClaimBusiness.dart`, linked from `vendordetailsscreen.dart` | SAME — already implemented correctly | None. |

## 10. Honeymoon/Travels (fresh re-verification)

**Independently re-confirmed accurate** against actual code (not just the doc) for all previously-claimed bug fixes: `InsurancePlan.fromSearchResponse` (`honeymoon_models.dart:908-966`), `CabQuote.flatten` (`:1064`), the ONWARD/RETURN split (`:1277`), `pickBookableFare`'s PUBLISHED-first logic (`:565-582`), the price→amount payment rename (`honeymoon_api.dart:803-825`), the `PhoneField.onChanged` fix (`flight_traveller_step.dart:569`), the controller-based traveller summary (`:713-716`), the GST profile store (this session's work, `gst_profile_store.dart`, 88 lines — confirmed real), and the insurance-cancellation/hotel-voucher wiring. `flutter analyze lib/honeymoon` re-ran clean, 0 issues.

| SRC item | Existing App | Status | Required action |
|---|---|---|---|
| `Travels/hotelbeds/` (~7k lines) — MIGRATION_NOTES.md calls this "a second, parallel hotel implementation" | none (only TripJack `/honeymoon/hotels` ported) | **MISCLASSIFIED in the doc, corrected here** | Verified false that this is a different supplier/inventory: `HotelbedsHotelsPage.jsx`/`HotelbedsDetailsPage.jsx` call the exact same `hotels/*` endpoints already ported (search/detail/filters/review/payment/booking/voucher/receipt) — "Hotelbeds" never appears in any payload/supplier field, only in file/folder names, and two internal files are literally named `TripJackBookingReview.jsx`/`TripJackBookingStatus.jsx`. **This is a legacy-named duplicate UI over identical backend inventory, not a parallel supplier.** Downgrade from "deferred integration gap" to "deferred alternate UI/UX" — low priority, since a user already gets identical inventory via the ported flow. **`MIGRATION_NOTES.md` §6 should be corrected to reflect this.** |
| `Travels/CityDetails/CityActivities.jsx` (729 lines) | none | **NEW — missed by all prior sessions, but not a real gap** | Not honeymoon city guides — a 100% static page of hardcoded Viator/GetYourGuide affiliate outbound links for 6 fixed cities, with **no internal navigation anywhere in src linking to this route**. Functionally orphaned/dead in the web app itself. `HomeTravels.jsx` (same folder) is likewise dead (its "search" button only does `console.log`). No action needed — nothing real to port. |
| `FlightBooking.jsx` route (`/honeymoon/flights/booking`, `SeatSelection.jsx`) | none | OBSOLETE (src-side dead code, not a Flutter gap) | Confirmed unreachable in src itself — all real navigation goes to `/honeymoon/flights/book` (the already-ported flow instead). No missed endpoint. |
| Reverse check: all 30 files under `lib/honeymoon/` | — | SAME | No orphaned/dead Flutter files found; every file maps to a real src feature. |
| Insurance student/annual-multi-trip variants, frequent-flier numbers (§6 deferred list) | not implemented | SAME (confirmed genuinely absent/deferred, not an oversight) | No action — correctly documented already. |

**No factually wrong claims found** in the prior doc — the one correction is a misleading framing (Hotelbeds), not a false one. **NOT VERIFIED (still needs live backend/device, same blocker as before)**: Razorpay live-key checkout, insurance cancellation against a real policy, hotel voucher/receipt file opening, seat/baggage add-on total reconciliation against a live fare, `GET /Flight_booking/travellers` existing in production.

## 14. AI Hub (fresh re-verification)

**⚠️ Unrelated but urgent, flagged separately**: `src (1)/src/components/pages/ShaadiAI.jsx` and `src (1)/src/components/common/HomeGennie.jsx` have **uncommitted changes** importing `../shaadiai/useShaadiAI` and `../shaadiai/MessageBody` — **neither file exists anywhere in the repo**, confirmed by a full-tree search. This breaks the web build right now; it's outside Flutter's scope but should be raised to whoever owns the `src (1)` working tree.

**`AIFeaturesHub.jsx` confirmed to link to exactly 5 features** — Shaadi AI Chat, Personality Quiz, Culture Blender, Conflict Resolver, Timeline Generator. No 6th feature exists. Each of the 4 non-chat features has **two different React implementations** in src: an orphaned inline version (`ChatFeatures.jsx`, confirmed unreferenced anywhere except its own file and a dead comment) and a reachable standalone page (`PersonalityQuiz.jsx` etc.) — Flutter was previously ported from the **orphaned** one, which is why it now diverges from what a real user actually sees.

| SRC item | Existing App | Status | Required action |
|---|---|---|---|
| `PersonalityQuiz.jsx` (standalone, live route) vs `ChatFeatures.jsx`'s inline version (orphaned, source of the Flutter port) | `personality_quiz_form.dart` | SAME on the 7 core questions; DIFFERENT on a secondary follow-up (standalone page fetches "Royal Wedding Venues" after quiz completion, Flutter has no equivalent) | Low priority — core quiz matches; follow-up feature missing. |
| `CultureBlender.jsx` (standalone) — **30 cultures**, working 1-4 priority sliders per field | `culture_blender_form.dart` — **21 cultures**, hardcoded `priorities=2` constant | **DIFFERENT — real gap** | Re-port from the standalone page, not the orphaned inline version, to reach real feature parity: 9 missing cultures, and priority sliders are a real interactive feature Flutter is missing entirely. |
| `ConflictResolver.jsx` (standalone) — adds a "Lock This Decision" button persisting to localStorage | `conflict_resolver_form.dart` | DIFFERENT (secondary, low priority) | 8 topics + 2 textareas match; the decision-lock feature is absent. |
| `TimelineGenerator.jsx` (standalone) — **completely different event list** (Bridal prep/Haldi/Mehendi/Baraat/Jaimala/Pheras/Church ceremony/etc.) + view-filter tabs + color legend | `timeline_generator_form.dart` — a different 14-event set entirely, no filter tabs | **DIFFERENT — real gap** | Re-port the event list from the standalone page; Flutter's current list doesn't match what the live site actually offers. |
| `Genie.jsx` (old floating widget) | `lib/Bottombars/GenieScreen.dart` | OBSOLETE both sides — confirmed dead | `Genie.jsx`'s backend host DNS no longer resolves (live web bug, unrelated to Flutter); `GenieScreen.dart`'s endpoint returns 404 and the screen isn't reachable from any live Flutter navigation either. Matching dead code on both sides — no action needed. |
| `HomeGennie.jsx` (maintained replacement widget) | `lib/ai_chat_screen/ai_chat_screen.dart` (`AiChatScreen`) | SAME, re-verified | Both call identical `POST /ai/chat`, same vendor-card rendering, same local-only history. The Sept-17 refactor of `ai_chat_screen.dart` is confirmed current, not stale. |

### Live endpoint results (tested just now)
| Endpoint | Result |
|---|---|
| `POST /ai/chat` | **200 OK** — the previously-reported "500 on every message" bug from an earlier session is **RESOLVED**. |
| `POST /ai/personality-quiz` | **500** — `"model 'llama-3.3-70b-versatile' does not exist or you do not have access to it"` |
| `POST /ai/culture-blender` | **500**, same dead-model error |
| `POST /ai/conflict-resolver` | **500**, same dead-model error |
| `POST /ai/timeline-generator` | **500**, same dead-model error |

**New finding**: all 4 guided-feature endpoints (quiz/blender/resolver/timeline) are broken **server-side** right now due to a deprecated Groq model id — this affects the React standalone pages and every Flutter form identically. This is a backend bug, not a client discrepancy, but means all 4 features are currently non-functional end-to-end regardless of the client-side content mismatches above. Flag to whoever owns the AI backend.

## 21. Cross-cutting: every API endpoint

~136 endpoints audited across all 18 `services/api/*.js` files (every exported function that issues an HTTP call). **78 called in Flutter, 58 not.** Biggest finding: the **E-Invites save/personalize/publish flow is entirely absent** — Flutter calls a parallel, apparently older endpoint pair (`/einvites/save_draft`, `/einvites/drafts/:userId`) that doesn't exist anywhere in the current React `einviteApi.js` — a real architectural divergence between two different backend flows for the same feature, not a simple missing call. Worth a dedicated follow-up (see also §6-7's E-Invites audit for the `lib/einvite` vs `lib/einvite1` dead-code question).

Base URLs: React `API_BASE_URL` = `https://api.happywedz.com`; React `AI_API_BASE_URL`/`BEAUTY_API_BASE_URL` = `https://www.happywedz.com/ai/api`; React `SHADI_AI_API_BASE_URL` = `https://shaadiai.happywedz.com/api` (confirmed dead, DNS doesn't resolve — see §14). Flutter `ApiConfig.apiBase` = `https://api.happywedz.com` (matches); `ApiConfig.aiChatBaseUrl` = `https://api.happywedz.com/ai` (**different host** than React's beauty/AI base — this pairing needs a closer look); `ApiConfig.movmentPlusAiBaseUrl` matches React's Movment Plus face-match host correctly.

### Not-found endpoints worth a closer look (not confidently "missing")
| Area | Endpoints | Note |
|---|---|---|
| **E-Invites** | 8 functions: create/update/delete a card, get-by-user, search, public-instance-view | Flutter uses a parallel `/einvites/save_draft` + `/einvites/drafts/:userId` pair not present in this React file at all — real divergence, not just unused. |
| **CMS banners** | 5 of 6 (design-studio banner, einvite banner, real-wedding-photo CMS, login-cms, sign-in-cms) | Could be intentionally web-only marketing content, or missing app banners — matches gaps already flagged independently in the Home-page audit (§2). |
| **Hotels** | `bookHotel`, `holdHotelBooking`, `confirmHotelBooking` | Flutter's flow goes straight from review → payment-order → verify-and-book with no hold option — confirm this is an intentional pay-only design, not an incomplete flow. |
| **Photography** | entire file, 7 endpoints | Photography vendors are instead browsed via generic `/vendor-services` — may be feature-equivalent rather than missing; cross-reference §3-5's finding that Flutter's "Photography" is a fundamentally different feature (vendor listing, not a photo-inspiration gallery) — this is likely the *same* gap seen from the API side. |
| **User auth** | `POST /user/login` (email/password) | Flutter's active auth path makes no REST call at all (Google/Apple only) — consistent with §1's Auth audit finding that email/password login doesn't exist live in Flutter. |
| **Flight marketing widgets** | `getPopularRoutes`, `getFlightDeals` | Possibly missing home-screen content, low priority. |
| **Beauty** | `getImageById` | Minor — Flutter only needs the derived image URL, not the JSON record. |
| **Movment Plus** | `uploadFile` | React's own comment marks this a placeholder never wired to a real backend route — likely dead on both sides, consistent with §9's finding. |

### Confirmed out of scope (vendor/admin-side) — ~15 endpoints
All of `vendorAuthApi.js` (8 functions) and `vendorMessagesApi.js` (3), plus `vendorServicesApi.js`'s vendor-lookup/create/update functions (4). **No `vendorToken` reference exists anywhere in `lib/`** — confirms Flutter has no vendor-portal auth flow at all, consistent with §1 and §20's findings.

### Legacy/superseded on the React side itself — ~14 endpoints
Old `Flight_booking/*` legacy flight endpoints and granular `/tj/oms/*` booking/amendment steps that Flutter reaches indirectly through higher-level `flight_payment/*` wrapper endpoints instead, plus two analytics-beacon calls in `hotelApi.js` — low risk, not real gaps.

### Fully confirmed SAME (no gaps)
Cabs (8/8 endpoints), Wedding Websites (7/7), vendor-types-with-subcategories (1/1), messages (4/4), tripSafe/insurance (7/8, only an `/embedded` search variant unconfirmed), most of flights/hotels' core booking funnels (already deeply audited in §10).

## 6-7. Design Studio, E-Invites

**Headline findings:**
- Design Studio in src is **entirely self-disabled** — every `/try*` route and its lazy imports are commented out in `App.jsx`. Flutter is the only *working* implementation of this feature today. Treat src as a disabled feature-intent reference only, not ground truth.
- `lib/einvite/` is confirmed **fully dead** (zero references anywhere outside itself). `lib/einvite1/` is split: only `einvite1/einvite.dart` is live and reachable; the other 13 files in that folder are themselves an unused, richer parallel editor with backend draft save/fetch — the same duplicate-dead-code pattern already found once in `HomeScreen.dart`.
- src's E-Invites pipeline (category browse → editor → share → guest view) is **broken at the code level**: `EinviteCategoryPage.jsx`, `EinviteEditorPage.jsx`, `EinviteSharePage.jsx`, `EinviteViewPage.jsx`, `EinviteCardItem.jsx`, and `MainSection.jsx` all import files (`layouts/einvites/EinviteCatalog`, `design/EinvitePage`, `design/einviteDesign`, `design/exportCard`, `einviteStudio.css`) that **don't exist anywhere in the repo** — confirmed via `git ls-files` and full-tree search. This **resolves §21's E-Invites API-divergence flag**: Flutter's parallel `/einvites/save_draft` endpoint isn't a stray architectural fork, it's because src's own "correct" pipeline is currently non-functional as committed.
- Both platforms' E-Invite RSVP is fake: src's has a full RSVP form but `submitRsvp()` only calls `alert()` — no network request at all (worse than the previously-found broken Wedding Websites RSVP, which at least didn't exist as a UI promise). Flutter has no RSVP UI at all here.

### Design Studio
| SRC item | Existing App | Verdict | Required action |
|---|---|---|---|
| `/try*` route tree — commented out in `App.jsx` | `designstudio1.dart`→`designstudio22.dart`, reachable via bottom-nav | DIFFERENT | src is OBSOLETE (self-disabled); Flutter is the only working copy — use it as the reference for future comparisons, not src. |
| Role choice: Bride/Groom/Other, real Groom flow intended | Flutter blocks Groom entirely at step 1 ("coming soon") | DIFFERENT | src intended real Groom support Flutter never built. |
| Category: Makeup/Jewellery/Outfit | Flutter: Makeup only, others "Soon" | DIFFERENT | No backend integration exists for Jewellery/Outfit. |
| Shade apply: src renders makeup **locally in-browser** (face-api.js landmarks, explicitly not round-tripped through an API per its own comment) | Flutter POSTs to `/ai/api/images/apply-makeup` on **every** shade/intensity tweak, then re-fetches | DIFFERENT | Opposite rendering architecture. **NOT VERIFIED**: real-world latency of Flutter's per-tweak round trip — needs a live device test. |
| Complete Look: applied-products list **+ Download PNG + Share modal (WhatsApp/Instagram/Facebook/X/copy-link) + Favorites** | Flutter: read-only list of applied products only | **MISSING** | Build download/share/favorites to match even the disabled src's intended design. |
| Outfit/Jewellery try-on with real garment overlay (`/catalog/items`, `/tryon/clothes`, `/tryon/jewelry`) | Flutter never calls these | **MISSING** | Unbuilt integration, not just a UI gap. |
| `FinalLookPage.jsx`/`ProfileImageSelector.jsx` | — | OBSOLETE | Both orphaned in src (zero routes); `FinalLookPage.jsx` has real bugs even as dead code (uses `Swal` without importing it, a TDZ error). Comment out, don't use as reference. |

### E-Invites
| SRC item | Existing App | Verdict | Required action |
|---|---|---|---|
| `EinviteCategoryPage.jsx`/`EditorPage.jsx`/`SharePage.jsx`/`ViewPage.jsx`/`CardItem.jsx` → import 5 files that **don't exist anywhere in the repo** | `TemplateListByTypeScreen` (`einvite1/einvite.dart`) — live `GET /einvites/cards`, works today | **MISSING (src is broken)** | **Blocking bug in src, not a design gap.** Category browsing, editor, share, view, and "my/our cards" all fail as committed on the web side. Flutter's equivalent works. |
| Editor: src (pending its own fix) is textarea-only, no font/color picker, no drag, no stickers; `EinviteFilterBar.jsx`'s category/theme filters are commented out | Flutter's live `EditorScreen` — drag-to-reposition, font-size slider, color picker, Bold/Italic (font-family picker UI exists in the data model but is commented out) | DIFFERENT | Flutter's live editor is, as coded, *more* capable than src's broken one. Wire up the already-present font-family picker. |
| Save: `POST .../einvites/cards/instances` (create) / `PUT .../{id}/instance`, backend-persisted | `EditorScreen.saveDraft()` — **local only** (SharedPreferences + local PNG), no network call | **DIFFERENT — real gap** | Draft is lost on uninstall, no cross-device access. The already-present but dead `einvite1/einvities_api.dart` implements `POST /einvites/save_draft` + `GET /einvites/drafts/{userId}` — **rewire the live editor to that** instead of building new backend support. |
| Share: src shares a **live hosted link** (WhatsApp/mailto/copy-link to a guest-view page); Flutter shares a **static image file** via the OS share sheet, no hosted link | — | DIFFERENT | Architecturally different sharing models. Decide whether Flutter's editor should call the create/update-instance API to also produce a shareable hosted link. |
| RSVP: src has a full form but `submitRsvp()` only calls `alert()` — no persistence at all | No RSVP UI anywhere in Flutter | MISSING (Flutter) / non-functional (src) | Neither platform has a real RSVP here; don't present either as working. |
| Video Invitations: `EinviteHomePage.jsx` shows "coming soon" for the tile tap, but a separate, more complete video-editor cluster exists in src, reachable only via SiteMap, disconnected from the main flow | Flutter shows "Coming Soon!" because the filtered list is empty, but the API call is live | DIFFERENT/MISSING | If wanted, reconnect src's orphaned video cluster and build the Flutter equivalent from scratch — src's video editor's real-world functionality is **NOT VERIFIED** (never exercised live). |
| Image upload/crop to personalize a template with the couple's own photo | — | **MISSING (both platforms)** | Implied by marketing copy on both sides, built on neither. |
| Three separate CardEditor implementations in src, two fully orphaned | Single live editor in Flutter | OBSOLETE (2 of 3 src editors) | Comment out the two orphaned src editors; the third is routed but has no in-app link pointing to it either — treat as dead too pending a real entry point. |

## 11. User Dashboard (remaining sub-tabs)

Scope: everything under `userDashboard/` except `wedding/` (covered in §10). Confirmed dead/unrouted React code (not a Flutter gap): `checklist/CheckList.jsx`, `flightBookings/FlightBookings.jsx`, `cabBookings/CabBookings.jsx` — zero importers anywhere in the source tree.

### Booking dashboard aggregation — `booking/*` → `lib/my_bookings/*`
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| `useBookingData.js` (6 sources loaded in parallel) | `bookings_api.dart` | SAME | Endpoints verified identical byte-for-byte. |
| `bookingStatus.js` normalize/filter logic | `booking_status.dart` | SAME | Direct port, confirmed. |
| `Booking.jsx` tabs + travel rail | `my_bookings.dart` | SAME | Matching structure. |
| `BookingCard.jsx` actions (View Details, Invoice/Voucher/Policy download, Pay & Confirm, Cancel quotation, Shop-order expand) | Flutter's cards render data only | **MISSING — real gap** | No `onTap`/navigation/download/cancel wiring on these cards at all. A working detail+cancel screen already exists at `trip_detail_page.dart` — wire the dashboard cards to it instead of duplicating. Quotation-cancel and shop-order expand have no equivalent. |
| `StoreCartSection.jsx` (web iframe/localStorage bridge) | none | OBSOLETE for mobile | Inherently browser-only; no action. |

### Cancellation flow
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| `CancellationModal.jsx` — per-trip/passenger selection, mandatory categorized reason, `cancel-charges`→`cancel` with `{trips, remarks}`, amendment-ID success screen | Flutter's `_cancel()` calls the same two endpoints with only `{provider, order_id}` — no trips, no remarks, no reason, no amendment ID surfaced | **DIFFERENT** | Flutter can only cancel an entire booking with no captured reason. **NOT VERIFIED**: whether the backend requires the missing fields for correct refund accounting — needs a live call before ruling this a bug vs. acceptable simplification. |
| Insurance cancellation — React's panel is view/download only, no cancel button | Flutter's `_cancelPolicy()` (raise+confirm) | NOT VERIFIED (possible Flutter-only) | Confirm whether src's honeymoon/insurance module (outside this pass's scope) has an equivalent. |
| Cab cancellation | Absent on both platforms | SAME (shared gap) | No action. |

### Budget, Checklist — solid, faithful ports
Both confirmed SAME on nearly everything (categories, CRUD, charts, PDF export). Two notable findings: Budget's Flutter list is flat (no per-category grouping/headers the web sidebar has — minor UX gap); **Checklist's day-allocation math in Flutter is a bug-fix improvement** over the web's floor-division (which silently drops remainder days) — Flutter is ahead here, no action needed. Flutter's PDF export also adds native Print, which web lacks.

### Guests — `guests/*` → `lib/guestlist/guestlist.dart`
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| `BulkImportModal.jsx` (Excel/CSV, `/guestlist/bulk`) | Only a dead, commented-out menu item | **MISSING — real gap** | Port a file-picker + parser flow calling the same endpoint. |
| `GuestListPDF.jsx` + print | No PDF/print export anywhere | **MISSING — real gap** | |
| Menu preference (6 options: Veg/NonVeg/Jain/Vegan/Eggetarian/All) | Reduced set (Veg/NonVeg/All observed) | DIFFERENT | Add missing options. |
| `seat_number` sent on create | The live `Guest.fromJson` model has no `seat_number` field — **silently dropped on every re-fetch** | **DIFFERENT — real data-loss bug** | Add the field to the model; currently write-only, meaning any seat number a user enters is invisibly lost. |
| Persisted/reusable named groups (`/groups`) | No live `/groups` calls; group is a fixed dropdown or free text | **MISSING** | No persisted group entity. |
| Full "Edit Guest" (all fields) | Only RSVP status is editable after creation | **MISSING** | Add a real edit-guest flow. |
| Bulk Email/WhatsApp, "Einvite Cards" redirect | Functions exist but their only call sites are commented out — unreachable | NOT VERIFIED / MISSING | Confirm no other entry point reaches these. |
| Loading/empty/error states | Flutter has skeleton loaders + retry vs. web's plain text | DIFFERENT (Flutter ahead) | No action. |

### Messages (vendor conversations) — `messages/Messages.jsx` → `lib/InboxScreen.dart` + `lib/chat_page_new.dart`
Confirmed a **real, backend-connected feature on the web** — distinct from the matrimonial module's known non-functional stub.
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| Conversation list — real conversations, dedupe by vendor, previews/unread/online-last-seen | `InboxScreen.dart` — directly read: `build()` **unconditionally renders a static "No messages yet" empty state**, never calls any conversations API; every button (Start Chatting, New Group, Find People, Scan QR, New Chat) is a no-op | **MISSING — confirmed non-functional entry point** | This is the screen actually wired to the dashboard's "Messages" entry. Needs a real implementation calling the same conversations endpoint. |
| Per-vendor chat thread | `chat_page_new.dart`'s `ChatService`/`ChatPage` | SAME — functional and real | Only reachable by opening a specific vendor's page first — there is no aggregated inbox to return to a prior conversation from. This is the practical impact of the broken `InboxScreen`. |
| Quick-reply chips, emoji picker, presence heartbeat | Not confirmed present in Flutter | NOT VERIFIED | Lower priority than fixing the inbox list itself. |

### RealWeddingForm — close 1:1 port
Same endpoint, same field names, same multipart shape, same auxiliary calls — confirmed SAME on the substantial majority. Two real gaps: (1) story field is plain text in Flutter vs. real rich-text HTML on web (acceptable simplification, but formatting entered on web can't be reproduced in-app); (2) **"Save Draft" only shows a "Draft saved" snackbar and persists nothing** — a misleading success message for a feature that doesn't work, matching the "no fake success" concern raised elsewhere in this audit. Fix by implementing real local persistence or removing the false message.

### UserProfile — `userProfile/UserProfile.jsx` → `lib/profile.dart`
| SRC item | Existing App | Status | Action |
|---|---|---|---|
| Editable name, phone, weddingDate, country, city, venue, profile+cover photo (crop/zoom/rotate), password change with strength meter | Flutter (`ProfileSettingsScreen`) only exposes **phone, venue, weddingDate**. No name edit, no country field, no image upload of any kind, no password-change code found anywhere | **MISSING — significant gap** | Add name edit, country field, profile/cover photo upload, and a change-password flow. |
| Account deletion | Neither platform has this | SAME | No action. |

### Vendors (dashboard tab) — "hired vendors" question, resolved
Read `Vendors.jsx` directly: it is **not** a hired-vendors list — it's a static grid of vendor categories with a "Find X" button; the only "Booked" indicator is never actually assigned anywhere in the component or its API response. **This confirms `MIGRATION_NOTES.md` §10's finding was correct**: the gap exists identically on both platforms because the web reference itself never built a working hired-vendors feature — nothing was missed in the Flutter port. No hired-vendors screen exists anywhere in `lib/` either.

### Wishlist — mostly SAME
Endpoints verified identical; Flutter's parallel enrichment is even a minor efficiency improvement over web's sequential loop. Two minor gaps: no search box, and no one-tap "Contact" shortcut from the wishlist card (Flutter requires navigating into the full vendor detail screen first).

### Not independently verified (need a live API call or deeper pass)
Whether `/tj/oms/cancel` genuinely requires `trips`/`remarks`; whether Flutter's insurance cancellation has a real React counterpart outside this scope; `chat_page_new.dart` feature-by-feature parity; exact reachability of Guests' bulk email/WhatsApp; whether cab booking detail (`TripDetailPage` for `TravelProduct.cab`) might be a silent stub (one fork's spot-check raised this, unconfirmed).

## 12. Wedding Websites

Built new this session (`lib/wedding_website/`, all 7 endpoints from `weddingWebsiteApi.js`, 3 templates sharing section widgets). Independently spot-checked directly (not just trusting the build agent's self-report):
- Read `WeddingWebsiteForm.jsx`'s `buildFormData` directly and diffed every multipart field name (`userId`, `templateId`, `weddingDate`, `brideData`/`groomData`, `loveStory`/`weddingParty`/`whenWhere` as JSON+repeated file fields, `galleryImages`/`gallery`, `sliderImages`/`slider`, `bride`/`groom`) against `wedding_website_api.dart` — **exact match**.
- Read `reorderWithFilesFirst` in the source and confirmed the Dart port's `_reorderFilesFirst` mirrors it structurally.
- Confirmed the RSVP gating copy ("RSVP isn't connected yet — please contact the couple directly to confirm.") is real, wired to `_submitted` state, matching the source's own non-functional RSVP exactly (no fake success).
- Confirmed the `morescreen.dart` menu wiring (`'Wedding Website'` → `_handleMenuTap` → `MyWeddingWebsitesPage`) matches the established pattern.
- `flutter analyze`: 290 issues, unchanged from baseline. `flutter test`: 153 passing (105 pre-existing + 48 new).
- **Open item, flagged by the build agent, not yet resolved**: `lib/einvite1/einvite.dart` already has its own separate `WeddingWebsiteCard`/`weddingWebsiteTemplates` that link out to a *web* builder — never reconciled with this new native module. Two competing "wedding website" entry points now exist in the app; needs a decision on which one to keep or how to merge them.
- **Not verified on-device** — no test account available in this session (same blocker as Honeymoon).

## 13. Matrimonial

Built new this session (`lib/matrimonial/`) as a deliberate **UI-only preview** — the React source has zero real API endpoints anywhere in its ~26 files, a broken registration submit (unimported library), fake OTP, a hardcoded fake profile pre-fill, and `Math.random()`-driven fake dashboard stats. Independently spot-checked:
- Confirmed the registration/OTP/edit-profile gating copy is real and wired to actual button handlers ("Registration isn't available yet...", "OTP verification isn't available yet.") rather than silent no-ops.
- Confirmed `matrimonial_edit_profile_page.dart` starts genuinely blank — no "Priya Sharma" pre-fill anywhere, no fake completion bar.
- Confirmed the dashboard stats tile shows a static "Coming soon" with no numbers, not a `Math.random()`-style fake metric.
- Confirmed the `morescreen.dart` menu wiring (`'Matrimonial'` → `MatrimonialLandingPage`) matches the established pattern.
- `flutter analyze`: 290 issues, unchanged. `flutter test`: 167 passing (153 + 14 new).
- **This module needs real backend endpoints + product decisions (OTP delivery, messaging, matching) before it can become functional** — documented explicitly in `MIGRATION_NOTES.md` §12 as the one intentionally non-functional module in the whole migration.

