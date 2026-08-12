import React, { Suspense, lazy, useEffect } from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import MainLayout from "./components/layouts/MainLayout";
import Loader from "./components/ui/Loader";
import Home from "./components/pages/Home";
// App.css was a single 388KB stylesheet covering every page in the app, and
// because it was imported here it landed in the entry stylesheet — 79.6KB gzipped
// of render-blocking CSS on every visit. It is now split in two:
//   App.critical.css — base styles plus everything the layout and home page can
//                      reference; still blocking, because it is what first paint
//                      needs and deferring it would cause a flash of unstyled
//                      content and layout shift.
//   App.deferred.css — the ~74% that only matches page-specific components behind
//                      lazy routes; fetched right after, off the critical path.
// Rules were partitioned by selector, preserving source order within each file,
// so the cascade still resolves the same way.
import "./App.critical.css";

import { useDispatch } from "react-redux";
import { setCredentials, logout } from "./redux/authSlice";
import { setVendorCredentials } from "./redux/vendorAuthSlice";
import "./services/api/axiosInstance";
import ToastProvider from "./components/layouts/toasts/Toast";
import LoaderProvider from "./components/context/LoaderContext";
import VendorPrivateRoute from "./components/routes/VendorPrivateRoute";
import UserPrivateRoute from "./components/routes/UserPrivateRoute";
import { ToastContainer } from "react-toastify";
import ScrollToTop from "./components/ScrollToTop";
import UserPreference from "./components/ui/UserPreference";

// Pull in the page-specific half of the old App.css without blocking first paint.
// On the home page it can wait for idle; on any other entry URL that page's own
// styles live in there, so fetch immediately and race it against the route's
// lazy chunk. Either way a user interaction forces it, so a client-side
// navigation never renders against missing styles.
if (typeof window !== "undefined") {
  let loaded = false;
  const loadDeferredStyles = () => {
    if (loaded) return;
    loaded = true;
    import("./App.deferred.css");
  };

  if (window.location.pathname === "/" && "requestIdleCallback" in window) {
    window.requestIdleCallback(loadDeferredStyles, { timeout: 2000 });
    ["pointerdown", "keydown", "touchstart"].forEach((event) =>
      window.addEventListener(event, loadDeferredStyles, {
        once: true,
        passive: true,
      })
    );
  } else {
    loadDeferredStyles();
  }
}

// Every route below is rendered inside the <Suspense> in this file, so these are
// code-split rather than statically imported. They used to be eager imports, which
// pulled ~4MB of page code (plus Matrimonial.css, framer-motion, react-icons packs)
// into the initial bundle on every page load, including "/".
const MovmentPlusLayout = lazy(
  () => import("./components/layouts/MovmentPlusLayout"),
);
const MatrimonialLayout = lazy(
  () => import("./components/layouts/MatrimonialLayout"),
);
const NotFound = lazy(() => import("./components/pages/NotFound"));
const BlogDetails = lazy(() => import("./components/pages/BlogDetails"));
const VendorLeadsPage = lazy(
  () => import("./components/pages/adminVendor/VendorLeadsPage"),
);
const ReviewsPage = lazy(() => import("./components/pages/WriteReviewPage"));
const AboutUs = lazy(() => import("./components/layouts/AboutUs"));
const DestinationWedding = lazy(
  () => import("./components/pages/DestinationWedding"),
);
const SiteMap = lazy(() => import("./components/pages/SiteMap"));
const TopRatedVendors = lazy(
  () => import("./components/pages/TopRatedVendors"),
);
const CareersPage = lazy(() => import("./components/pages/CareersPage"));
const DestinationWeddingDetailPage = lazy(
  () => import("./components/pages/DestinationWeddingDetailPage"),
);
const BusinessClaimForm = lazy(
  () => import("./components/pages/BusinessClaimForm"),
);
const PublicWeddingView = lazy(
  () => import("./components/pages/WeddingPublicView"),
);
const MovementPlusHome = lazy(
  () => import("./components/pages/movments-plus/MovementPlusHome"),
);
const MovmentPlusGuestToken = lazy(
  () => import("./components/pages/movments-plus/MovmentPlusGuestToken"),
);
const MovmentPlusUploadSelfie = lazy(
  () => import("./components/pages/movments-plus/MovmentPlusUploadSelfie"),
);
const MovmentPlusGalleryPage = lazy(
  () => import("./components/pages/movments-plus/MovmentPlusGalleryPage"),
);

// Home is the landing route for effectively all traffic, so lazy()-ing it only
// bought a serialised round trip: entry chunk → Home chunk → hero paint, with
// nothing to modulepreload the second hop. Importing it statically folds the
// hero into the entry graph that Vite already emits <link rel="modulepreload">
// for. The below-the-fold half of Home is still code-split inside Home.jsx, so
// the entry only grows by the hero, the category row and the first CTA.
const CustomerLogin = lazy(() => import("./components/auth/CustomerLogin"));
const CustomerRegister = lazy(
  () => import("./components/auth/CustomerRegister"),
);
const VendorLogin = lazy(() => import("./components/auth/VendorLogin"));
const VendorRegister = lazy(() => import("./components/auth/VendorRegister"));
const ForgotPassword = lazy(() => import("./components/auth/ForgotPassword"));
const VendorForgotPassword = lazy(
  () => import("./components/auth/VendorForgotPassword"),
);
const Vendor360View = lazy(() => import("./components/pages/Vendor360View"));
const MainSection = lazy(() => import("./components/pages/MainSection"));
const SubSection = lazy(() => import("./components/pages/SubSection"));
const TestInteractionsPage = lazy(() => import("./pages/TestInteractionsPage"));
const DemoRecentlyViewed = lazy(() => import("./pages/DemoRecentlyViewed"));
const Detailed = lazy(() => import("./components/layouts/Detailed"));
const Main = lazy(() => import("./components/pages/adminVendor/Main"));
const Search = lazy(() => import("./components/pages/matrimonial/Search"));
const MatrimonialMain = lazy(
  () => import("./components/pages/matrimonial/MatrimonialMain"),
);
const ProfileMatrimonial = lazy(
  () => import("./components/pages/matrimonial/ProfileMatrimonial"),
);
const PrivacyPolicy = lazy(() => import("./components/pages/PrivacyPolicy"));

const MatrimonialRegister = lazy(
  () => import("./components/pages/matrimonial/MatrimonialRegistration"),
);
const UserDashboardMain = lazy(
  () => import("./components/pages/userDashboard/UserDashboardMain"),
);
const MatrimonialDashboard = lazy(
  () => import("./components/pages/matrimonial/dashboard/MatrimonialDashboard"),
);
const EditProfile = lazy(
  () => import("./components/pages/matrimonial/dashboard/EditProfile"),
);

const TermsCondition = lazy(() => import("./components/pages/TermsCondition"));
const Blog = lazy(() => import("./components/pages/Blog"));
const CancellationPolicy = lazy(
  () => import("./components/pages/CancellationPolicy"),
);
const CardEditorPage = lazy(() => import("./components/CardEditorPage"));

const PhotographyDetails = lazy(
  () => import("./components/pages/PhotographyDetails"),
);
const VideoEditorPage = lazy(() => import("./components/VideoEditorPage"));
const VideoTemplates = lazy(
  () => import("./components/layouts/eInvite/VideoTemplates"),
);
const VideoEditorDemo = lazy(
  () => import("./components/layouts/eInvite/VideoEditorDemo"),
);
const ProfileImageSelector = lazy(
  () => import("./components/pages/ProfileImageSelector"),
);

// E-Invite Pages
const EinviteHomePage = lazy(
  () => import("./components/pages/EinviteHomePage"),
);
const EinviteCategoryPage = lazy(
  () => import("./components/pages/EinviteCategoryPage"),
);
const EinviteEditorPage = lazy(
  () => import("./components/pages/EinviteEditorPage"),
);
const EinviteSharePage = lazy(
  () => import("./components/pages/EinviteSharePage"),
);
const EinviteMyCards = lazy(
  () => import("./components/layouts/einvites/EinviteMyCards"),
);
const EinviteViewPage = lazy(
  () => import("./components/pages/EinviteViewPage"),
);
const OurCards = lazy(() => import("./components/pages/OurCards"));
const TryLanding = lazy(
  () => import("./components/pages/designStudio/TryLanding"),
);
const ChooseTemplate = lazy(() => import("./components/pages/ChooseTemplate"));
const TemplatePreviewPage = lazy(
  () => import("./components/pages/TemplatePreviewPage"),
);
const TemplateCustomizePage = lazy(
  () => import("./components/pages/TemplateCustomizePage"),
);

const WeddingWebsiteForm = lazy(
  () => import("./components/pages/WeddingWebsiteForm"),
);

const WeddingWebsiteView = lazy(
  () => import("./components/pages/WeddingWebsiteView"),
);

const MyWeddingWebsites = lazy(
  () => import("./components/pages/MyWeddingWebsites"),
);

const BrideMakeupChoose = lazy(
  () => import("./components/pages/designStudio/BrideMakeupChoose"),
);
const GroomeMakeupChoose = lazy(
  () => import("./components/pages/designStudio/GroomeMakeupChoose"),
);
const TryMakeupLanding = lazy(
  () => import("./components/pages/designStudio/TryMakeupLanding"),
);
const UploadSelfiePage = lazy(
  () => import("./components/pages/designStudio/UploadSelfiePage"),
);
const FiltersPage = lazy(
  () => import("./components/pages/designStudio/FiltersPage"),
);

const OutfitFilterPage = lazy(
  () => import("./components/pages/designStudio/OutfitFilterPage"),
);

const ContactUs = lazy(() => import("./components/pages/Contactus"));

const FinalLookPage = lazy(() => import("./components/pages/FinalLookPage"));
// const WeddingWebsiteForm = lazy(() =>
//   import("./components/pages/WeddingWebsiteForm")
// );
// const MyWeddingWebsites = lazy(() =>
//   import("./components/pages/MyWeddingWebsites")
// );

// const WeddingWebsiteView = lazy(() =>
//   // const WeddingWebsiteView = lazy(() =>
//   import("./components/pages/WeddingWebsiteView")
// );

const VendorPremium = lazy(
  () => import("./components/pages/adminVendor/VendorPremium"),
);

const RecommandPage = lazy(() => import("./components/home/RecommandedPage"));
const WriteReviewPage = lazy(
  () => import("./components/pages/WriteReviewPage"),
);
const ShaadiAI = lazy(() => import("./components/pages/ShaadiAI"));
const AIFeaturesHub = lazy(() => import("./components/pages/AIFeaturesHub"));
const CultureBlender = lazy(() => import("./components/pages/CultureBlender"));
const PersonalityQuiz = lazy(() => import("./components/pages/PersonalityQuiz"));
const ConflictResolver = lazy(() => import("./components/pages/ConflictResolver"));
const TimelineGenerator = lazy(() => import("./components/pages/TimelineGenerator"));

const Travels = lazy(() => import("./components/pages/Travels/Travel"));
const CityActivities = lazy(
  () => import("./components/pages/Travels/CityDetails/CityActivities"),
);
const HoneymoonHeroPage = lazy(
  () => import("./components/pages/Travels/honeymoon/HeroPage"),
);
const HoneymoonHotelsPage = lazy(
  () => import("./components/pages/Travels/honeymoon/HoneymoonHotelsPage"),
);
const CabSearchResults = lazy(
  () => import("./components/pages/Travels/honeymoon/CabSearchResults"),
);
const CabBookingPage = lazy(
  () => import("./components/pages/Travels/honeymoon/CabBookingPage"),
);
const HotelbedsHotelsPage = lazy(
  () => import("./components/pages/Travels/hotelbeds/HotelbedsHotelsPage"),
);
const HotelBookingsPage = lazy(
  () => import("./components/pages/Travels/hotelbeds/HotelBookingsPage"),
);
const HotelBookingDetailsPage = lazy(
  () => import("./components/pages/Travels/hotelbeds/HotelBookingDetailsPage"),
);
const FlightSearchResults = lazy(
  () => import("./components/pages/Travels/honeymoon/FlightSearchResults"),
);
const TravelInsuranceResults = lazy(
  () => import("./components/pages/Travels/honeymoon/TravelInsuranceResults"),
);
const InsuranceBookingPage = lazy(
  () => import("./components/pages/Travels/honeymoon/InsuranceBookingPage"),
);
const InsuranceBookingDetailsPage = lazy(
  () => import("./components/pages/Travels/honeymoon/InsuranceBookingDetailsPage"),
);
const FlightBooking = lazy(
  () => import("./components/pages/Travels/honeymoon/FlightBooking"),
);
const FlightBookingPage = lazy(
  () => import("./components/pages/Travels/honeymoon/FlightBookingPage"),
);
const MultiCityResults = lazy(
  () => import("./components/pages/Travels/honeymoon/MultiCityResults"),
);
const BookingDetailPage = lazy(
  () => import("./components/pages/Travels/honeymoon/BookingDetailPage"),
);
const FlightBookingDetail = lazy(
  () => import("./components/pages/userDashboard/flightBookings/FlightBookingDetail"),
);

function App() {
  const dispatch = useDispatch();

  useEffect(() => {
    const user = localStorage.getItem("user");
    const token = localStorage.getItem("token");
    const tokenTimestamp = localStorage.getItem("tokenTimestamp");

    if (user && token) {
      if (tokenTimestamp) {
        const now = Date.now();
        const elapsed = now - parseInt(tokenTimestamp, 10);
        const TOKEN_EXPIRATION_TIME = 2 * 24 * 60 * 60 * 1000;

        if (elapsed >= TOKEN_EXPIRATION_TIME) {
          // Token expired — clear auth in both localStorage and Redux so
          // UserPrivateRoute doesn't keep treating the user as logged in.
          dispatch(logout());
        } else {
          // Token still valid, set credentials
          dispatch(setCredentials({ user: JSON.parse(user), token }));
        }
      } else {
        // No timestamp means old token, consider it expired
        dispatch(logout());
      }
    }

    // Vendor tokens don't have expiration tracking yet, but we'll set them
    const vendor = localStorage.getItem("vendor");
    const vendorToken = localStorage.getItem("vendorToken");
    if (vendor && vendorToken) {
      dispatch(
        setVendorCredentials({
          vendor: JSON.parse(vendor),
          token: vendorToken,
        }),
      );
    }
  }, [dispatch]);

  // useEffect(() => {
  //   window.scrollTo(0, 0);
  // }, [location.pathname]);

  return (
    <LoaderProvider>
      <ScrollToTop />
      <UserPreference />
      <Suspense fallback={<Loader />}>
        <ToastContainer />
        <ToastProvider>
          <Routes>
            <Route path="/preview/:id" element={<TemplatePreviewPage />} />
            <Route path="/customize/:id" element={<TemplateCustomizePage />} />
            <Route
              path="/wedding-form/:templateId"
              element={
                <UserPrivateRoute>
                  <WeddingWebsiteForm />
                </UserPrivateRoute>
              }
            />
            <Route
              path="/wedding-website/:id"
              element={<WeddingWebsiteView />}
            />

            <Route
              path="/wedding/:websiteUrl"
              element={<PublicWeddingView />}
            />

            <Route element={<MainLayout />}>
              <Route path="/wedding-venues/:city" element={<MainSection />} />
              <Route path="/wedding-venues/:city/:slug" element={<Detailed />} />
              <Route path="/wedding-venues" element={<MainSection />} />
              <Route path="/venues/:city" element={<MainSection />} />
              <Route path="/venues/:city/:slug" element={<Detailed />} />
              <Route path="/venues" element={<MainSection />} />
              <Route path="/vendors/:subcategory/:city" element={<SubSection />} />
              <Route path="/vendors/:subcategory/:city/:slug" element={<Detailed />} />
              <Route path="/photography/:subcategory/:city" element={<SubSection />} />
              <Route path="/" element={<Home />} />
              <Route
                path="/photos/details/:slug"
                element={<PhotographyDetails />}
              />
              <Route path="/privacy" element={<PrivacyPolicy />} />
              <Route
                path="/photography/details/:id"
                element={<PhotographyDetails />}
              />
              <Route
                path="/photography/:subcategory/:city/:slug"
                element={<PhotographyDetails />}
              />
              <Route path="/:section" element={<MainSection />} />
              <Route path="/:section/:slug" element={<SubSection />} />
              <Route path="/details/:section/:slug" element={<Detailed />} />
              <Route path="/vendor-360/:id" element={<Vendor360View />} />
              <Route
                path="/ai-recommandation"
                element={
                  <UserPrivateRoute>
                    <RecommandPage />
                  </UserPrivateRoute>
                }
              />
              <Route path="/ai-features" element={<AIFeaturesHub />} />
              <Route path="/shaadi-ai" element={<ShaadiAI />} />
              <Route path="/culture-blender" element={<CultureBlender />} />
              <Route path="/personality-quiz" element={<PersonalityQuiz />} />
              <Route path="/conflict-resolver" element={<ConflictResolver />} />
              <Route path="/timeline-generator" element={<TimelineGenerator />} />
              <Route path="/customer-login" element={<CustomerLogin />} />
              <Route path="/customer-register" element={<CustomerRegister />} />
              <Route path="/contact-us" element={<ContactUs />} />
              <Route path="/vendor-login" element={<VendorLogin />} />
              <Route path="/vendor-register" element={<VendorRegister />} />
              <Route
                path="/user-forgot-password"
                element={<ForgotPassword />}
              />
              <Route
                path="/vendor-forgot-password"
                element={<VendorForgotPassword />}
              />
              <Route
                path="/claim-your-buisness"
                element={<BusinessClaimForm />}
              />
              <Route path="/blog" element={<Blog />} />
              <Route path="/blog/:blogId" element={<Blog />} />
              <Route path="/blog-details" element={<BlogDetails />} />
              <Route path="/terms" element={<TermsCondition />} />
              <Route path="/cancellation" element={<CancellationPolicy />} />
              <Route
                path="/destination-wedding"
                element={<DestinationWedding />}
              />
              <Route
                path="/destination-wedding/:name"
                element={<DestinationWeddingDetailPage />}
              />
              <Route path="/sitemap" element={<SiteMap />} />
              <Route path="/top-rated" element={<TopRatedVendors />} />
              <Route path="/careers" element={<CareersPage />} />
              <Route path="/honeymoon" element={<HoneymoonHeroPage />} />
              <Route
                path="/honeymoon/flights"
                element={<FlightSearchResults />}
              />
              <Route path="/honeymoon/cabs" element={<CabSearchResults />} />
              <Route path="/honeymoon/cabs/book" element={<CabBookingPage />} />
              <Route
                path="/honeymoon/insurance"
                element={<TravelInsuranceResults />}
              />
              <Route
                path="/honeymoon/insurance/book"
                element={<InsuranceBookingPage />}
              />
              <Route
                path="/honeymoon/insurance/booking/:bookingId"
                element={<InsuranceBookingDetailsPage />}
              />
              <Route
                path="/honeymoon/flights/multicity"
                element={<MultiCityResults />}
              />
              <Route
                path="/honeymoon/flights/my-booking/:orderId"
                element={
                  <UserPrivateRoute>
                    <BookingDetailPage />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/honeymoon/flights/booking"
                element={
                  <UserPrivateRoute>
                    <FlightBooking />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/honeymoon/flights/book"
                element={
                  <UserPrivateRoute>
                    <FlightBookingPage />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/honeymoon/flights/confirmation"
                element={
                  <UserPrivateRoute>
                    <FlightBookingPage />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/honeymoon/hotels"
                element={<HoneymoonHotelsPage />}
              />
              <Route
                path="/honeymoon/hotels/:hotelId"
                element={<HoneymoonHotelsPage />}
              />
              <Route
                path="/hotels"
                element={<HotelbedsHotelsPage />}
              />
              <Route
                path="/hotels/:hotelId"
                element={<HotelbedsHotelsPage />}
              />
              <Route
                path="/hotelbeds/hotels"
                element={<HotelbedsHotelsPage />}
              />
              <Route
                path="/hotelbeds/hotels/:hotelId"
                element={<HotelbedsHotelsPage />}
              />
              <Route
                path="/hotels/all-booking"
                element={
                  <UserPrivateRoute>
                    <HotelBookingsPage />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/hotels/booking/:bookingId"
                element={
                  <UserPrivateRoute>
                    <HotelBookingDetailsPage />
                  </UserPrivateRoute>
                }
              />
              {/* Try Flow */}
              <Route path="/try" element={<TryLanding />} />
              <Route
                path="/try/bride"
                element={
                  <UserPrivateRoute>
                    <BrideMakeupChoose />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/try/groom"
                element={
                  <UserPrivateRoute>
                    <GroomeMakeupChoose />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/try/upload"
                element={
                  <UserPrivateRoute>
                    <UploadSelfiePage />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/try/filters"
                element={
                  <UserPrivateRoute>
                    <FiltersPage />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/try/outfit-filters"
                element={
                  <UserPrivateRoute>
                    <OutfitFilterPage />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/try/makeup"
                element={
                  <UserPrivateRoute>
                    <TryMakeupLanding />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/finallook"
                element={
                  <UserPrivateRoute>
                    <FinalLookPage />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/vendor-dashboard/total-leads"
                element={<VendorLeadsPage />}
              />
              <Route path="/write-review/:vendorId" element={<ReviewsPage />} />
              <Route path="/editor" element={<CardEditorPage />} />
              <Route path="/editor/:templateId" element={<CardEditorPage />} />
              <Route path="/video-templates" element={<VideoTemplates />} />
              <Route path="/video-editor" element={<VideoEditorPage />} />
              <Route
                path="/video-editor/:templateId"
                element={<VideoEditorPage />}
              />
              <Route path="/video-demo" element={<VideoEditorDemo />} />
              <Route path="/einvites" element={<EinviteHomePage />} />
              <Route
                path="/einvites/category/:category"
                element={<EinviteCategoryPage />}
              />
              <Route
                path="/einvites/editor/:id"
                element={
                  <UserPrivateRoute>
                    <EinviteEditorPage />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/einvites/preview/:id"
                element={<EinviteSharePage />}
              />
              <Route
                path="/einvites/share/:id"
                element={<EinviteSharePage />}
              />
              <Route path="/einvites/view/:id" element={<EinviteViewPage />} />
              <Route
                path="/einvites/my-cards"
                element={
                  <UserPrivateRoute>
                    <EinviteMyCards />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/einvites/our-cards"
                element={
                  <UserPrivateRoute>
                    <OurCards />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/choose-template"
                element={
                  <UserPrivateRoute>
                    <ChooseTemplate />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/my-wedding-websites"
                element={
                  <UserPrivateRoute>
                    <MyWeddingWebsites />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/user-dashboard"
                element={
                  <UserPrivateRoute>
                    <UserDashboardMain />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/user-dashboard/:slug"
                element={
                  <UserPrivateRoute>
                    <UserDashboardMain />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/user-dashboard/my-bookings/:orderId"
                element={
                  <UserPrivateRoute>
                    <FlightBookingDetail />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/vendor-dashboard"
                element={
                  <VendorPrivateRoute>
                    <Navigate to="/vendor-dashboard/vendor-home" />
                  </VendorPrivateRoute>
                }
              />
              <Route
                path="/vendor-dashboard/:slug"
                element={
                  <VendorPrivateRoute>
                    <Main />
                  </VendorPrivateRoute>
                }
              />
              <Route
                path="/vendor-dashboard/upgrade/vendor-plan"
                element={
                  <VendorPrivateRoute>
                    <VendorPremium />
                  </VendorPrivateRoute>
                }
              />

              <Route path="/about-us" element={<AboutUs />} />
              
              {/* Test Interactions Page */}
              <Route path="/test-interactions" element={<TestInteractionsPage />} />
              
              {/* Demo Recently Viewed - Add sample data */}
              <Route path="/demo-recently-viewed" element={<DemoRecentlyViewed />} />

              <Route path="*" element={<NotFound />} />
              <Route path="/travels" element={<Travels />} />
              <Route path="/travels/:cityName" element={<CityActivities />} />
            </Route>

            <Route element={<MatrimonialLayout />}>
              <Route path="/matrimonial" element={<MatrimonialMain />} />
              <Route
                path="/ProfileMatrimonial/:matchType"
                element={<ProfileMatrimonial />}
              />
              <Route path="/matrimonial-search" element={<Search />} />
              <Route
                path="/matrimonial-register"
                element={<MatrimonialRegister />}
              />
              <Route
                path="/matrimonial-Dashboard"
                element={<MatrimonialDashboard />}
              />
              <Route path="/edit-profile" element={<EditProfile />} />
            </Route>

            <Route element={<MovmentPlusLayout />}>
              <Route path="/movment-plus/home" element={<MovementPlusHome />} />
              <Route
                path="/movment-plus/guest-token"
                element={
                  <UserPrivateRoute>
                    <MovmentPlusGuestToken />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/movment-plus/upload-selfie"
                element={
                  <UserPrivateRoute>
                    <MovmentPlusUploadSelfie />
                  </UserPrivateRoute>
                }
              />
              <Route
                path="/movment-plus/gallery/:token"
                element={
                  <UserPrivateRoute>
                    <MovmentPlusGalleryPage />
                  </UserPrivateRoute>
                }
              />
            </Route>
          </Routes>
        </ToastProvider>
      </Suspense>
    </LoaderProvider>
  );
}

export default App;
