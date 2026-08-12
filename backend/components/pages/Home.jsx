import { lazy, Suspense, useEffect, useState } from "react";
import Herosection from "../home/Herosection";
import WeddingCategories from "../home/WeddingCategories";
import CtaPanel from "../home/CtaPanel";
import cmsApi from "../../services/api/cmsApi";
import SEO from "../common/SEO";
import StructuredData from "../common/StructuredData";
import DeferUntilNearViewport from "../common/DeferUntilNearViewport";

// Below-the-fold sections are code-split so the initial Home chunk only carries
// what is needed to paint the hero and the first category row.
const PlanningToolsCTA = lazy(() => import("../home/PlanningToolsCTA"));
const MansoryImageSection = lazy(() => import("../home/MansoryImageSection"));
const VenueSlider = lazy(() => import("../home/VenueSlider"));
const RealWeddings = lazy(() => import("../home/RealWeddings"));
const MainTestimonial = lazy(() => import("../home/MainTestimonial"));
const BlogInspirationTeasers = lazy(
  () => import("../home/BlogInspirationTeasers"),
);
const HowItWorksSection = lazy(() => import("../home/HowItWorksSection"));
const AppDownloadSection = lazy(() => import("../home/AppDownloadSection"));
const MetroCities = lazy(() => import("../home/MetroCities"));

// Served straight from /public as pre-compressed WebP rather than being pulled
// through the bundler as multi-hundred-KB PNG/JPG.
const logo = "/happywed_white.png";
const image = "/images/home/1.webp";
const einviteImage = "/images/home/einvite.webp";
const bigleafcta1 = "/images/home/bigleafcta1.webp";
const bigleafcta5 = "/images/home/bigleafcta5.webp";

const Home = () => {
  const [designBanner, setDesignBanner] = useState(null);
  const [einviteBanner, setEinviteBanner] = useState(null);
  const [realWeddingData, setRealWeddingData] = useState(null);
  const [couplesSaysData, setCouplesSaysData] = useState(null);
  const normalizeUrl = (u) => {
    if (!u || typeof u !== "string") return null;
    const cleaned = u.replace(/`/g, "").trim();
    try {
      return encodeURI(cleaned);
    } catch {
      return cleaned;
    }
  };
  useEffect(() => {
    // These four are independent; awaiting them in series cost four sequential
    // round trips (~5s on the trace) before any banner could render.
    let cancelled = false;
    const value = (r) => (r.status === "fulfilled" ? r.value : null);

    Promise.allSettled([
      cmsApi.designStudioBanner.getBanner(),
      cmsApi.einviteBanner.getBanner(),
      cmsApi.realWeddingPhoto.getData(),
      cmsApi.whatCouplesSays.getData(),
    ]).then(([ds, ei, rw, cs]) => {
      if (cancelled) return;
      setDesignBanner(value(ds)?.data || null);
      setEinviteBanner(value(ei)?.data || null);
      setRealWeddingData(value(rw) || null);
      setCouplesSaysData(value(cs)?.data || null);
    });

    return () => {
      cancelled = true;
    };
  }, []);
  return (
    <div style={{ position: "relative" }}>
      <SEO />
      <StructuredData type="homepage" />
      <Herosection />
      <WeddingCategories />
      <CtaPanel
        logo={normalizeUrl(designBanner?.logo) || logo}
        img={normalizeUrl(designBanner?.mainImage) || image}
        heading={designBanner?.heading || "Design Studio"}
        subHeading={
          designBanner?.subheading ||
          "Try Virtual Makeup & Grooming Looks for Your Big Day_"
        }
        link={`/${(designBanner?.btnRedirect || "try").replace(/^\/+/, "")}`}
        title={designBanner?.title || "Create Your Look !"}
        subtitle={
          designBanner?.description ||
          "Experience How You'll Look in Your Wedding Day with AI-Powered Virtual Makeover."
        }
        btnName={designBanner?.btnName || "Try Virtual Look"}
        background={normalizeUrl(designBanner?.bgImage) || bigleafcta1}
      />
      {/* Local boundary: without it, a suspending section below would fall through
          to App's <Suspense> and replace the already-painted hero with the loader.

          Each group is additionally gated on DeferUntilNearViewport. lazy() by
          itself kept these sections out of the entry chunk but still fetched and
          executed every one of them during initial load — swiper alone cost
          ~610ms of main-thread time before the user had scrolled a pixel. */}
      <Suspense fallback={null}>
      <DeferUntilNearViewport minHeight={600}>
      <PlanningToolsCTA />
      <MansoryImageSection />
      <VenueSlider />
      </DeferUntilNearViewport>
      <DeferUntilNearViewport minHeight={500}>
      <CtaPanel
        logo={normalizeUrl(einviteBanner?.logo) || logo}
        img={normalizeUrl(einviteBanner?.mainImage) || einviteImage}
        heading={einviteBanner?.heading || "E-INVITES"}
        subHeading={
          einviteBanner?.subheading ||
          "Create Stunning Digital Wedding Invitations That Wow"
        }
        title={
          einviteBanner?.title ||
          "Design Beautiful E-Invites with Our Easy-to-Use Editor !"
        }
        subtitle={
          einviteBanner?.description ||
          "Discover curated options that fit your style, budget and location. Search and compare instantly."
        }
        link={`/${(einviteBanner?.btnRedirect || "einvites").replace(
          /^\/+/,
          "",
        )}`}
        btnName={einviteBanner?.btnName || "Create Your E-Invite"}
        background={normalizeUrl(einviteBanner?.bgImage) || bigleafcta5}
      />
      <RealWeddings
        icon={normalizeUrl(realWeddingData?.icon)}
        title={realWeddingData?.title}
        subtitle={realWeddingData?.subtitle}
        btnName={realWeddingData?.btnName}
        redirectUrl={realWeddingData?.redirectUrl}
        images={(Array.isArray(realWeddingData?.images)
          ? realWeddingData.images
          : []
        ).map(normalizeUrl)}
      />
      </DeferUntilNearViewport>
      {/* <FeaturedVendorsSection /> */}

      {/* <TestimonialsSection /> */}
      {/* <CtaPanel
        logo={logo}
        img={image}
        heading="Matrimonial Services"
        subHeading="Connecting Hearts Across Communities"
        title="Find Your Perfect Match with Our Trusted Matrimonial Services"
        subtitle="Bringing Hearts Together for a Lifetime of Happiness. Explore verified profiles, personalized matches, and start your journey towards a meaningful relationship."
        link="/matrimonial"
        btnName="Start Your Journey"
      /> */}
      <DeferUntilNearViewport minHeight={600}>
      <MainTestimonial
        heading={couplesSaysData?.heading}
        subHeading={couplesSaysData?.subHeading}
        mainImage={normalizeUrl(couplesSaysData?.mainImage)}
        sections={
          Array.isArray(couplesSaysData?.sections)
            ? couplesSaysData.sections.map((s) => ({
                ...s,
                img: normalizeUrl(s.img),
              }))
            : []
        }
      />
      <BlogInspirationTeasers />
      {/* <NewsletterSection /> */}
      <HowItWorksSection />
      <AppDownloadSection />
      <MetroCities />
      </DeferUntilNearViewport>
      </Suspense>
      {/* <div
        style={{
          position: "fixed",
          bottom: "10vh",
          right: "60px",
          zIndex: "99",
        }}
      >
        <HomeGennie />
      </div> */}
    </div>
  );
};

export default Home;
