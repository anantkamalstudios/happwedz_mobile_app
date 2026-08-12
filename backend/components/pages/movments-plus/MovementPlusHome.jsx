import React, { useState, useEffect } from "react";
import MovmentPlusHero from "../../movment-plus/MovmentPlusHero";
import Brands from "../../movment-plus/Brands";
import HomeGridImages from "../../movment-plus/HomeGridImages";
import "./movment-plus.css";
import EventCreationTabs from "../../movment-plus/EventCreationTabs";
import SmartPhotoSharing from "../../movment-plus/SmartPhotoSharing";
import RealWeddings from "../../home/RealWeddings";
import cmsApi from "../../../services/api/cmsApi";
import MainTestimonial from "../../home/MainTestimonial";
import SEO from "../../common/SEO";
const MovementPlusHome = () => {
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
    const run = async () => {
      try {
        const rw = await cmsApi.realWeddingPhoto.getData();
        setRealWeddingData(rw || null);
      } catch {}
      try {
        const cs = await cmsApi.whatCouplesSays.getData();
        setCouplesSaysData(cs?.data || null);
      } catch {}
    };
    run();
  }, []);

  return (
    <div className="app_wrapper_2k7m3">
      <SEO
        title="Movment+ | Smart Wedding Photo Sharing | HappyWedz"
        description="Share and relive your wedding moments with Movment+ by HappyWedz. AI-powered face recognition lets guests instantly find their own photos from your wedding gallery."
      />
      <MovmentPlusHero />
      <Brands />
      <HomeGridImages />
      <EventCreationTabs />

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
      <SmartPhotoSharing />
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
    </div>
  );
};

export default MovementPlusHome;
