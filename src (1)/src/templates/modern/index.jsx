import React from "react";
// import Couple from "../components/couple";
import PreviewHero from "../components/hero2";
import Story from "../components/story";
// import Welcome from "../components/welcome-area";
import People from "../components/people";
import Location from "../components/location";
import Gallery from "../components/gallery";
import Rsvp from "../components/rsvp";
// import Getting from "../components/getting";
import Gift from "../components/gift";
import Navbar from "../components/Navbar";
import Saveday from "../components/countdown";
import Footer from "../components/footer";
import ModernCouple from "../components/Modern Couple/Index";
import RsvpComponent from "../components/Modern Rsvp/RsvpComponent";
import WeddingPartyComponent from "../components/Modern People/WeddingPartyComponent";

const Homepage2 = ({ data }) => {
  return (
    <div>
      <Navbar brideData={data?.brideData} groomData={data?.groomData} />
      <PreviewHero
        images={data?.sliderImages}
        coupleNames={{
          bride: data?.brideData?.title,
          groom: data?.groomData?.title,
        }}
        weddingDate={data?.weddingDate}
      />
      <Saveday saveday={"s2"} weddingDate={data?.weddingDate} />
      <ModernCouple brideData={data?.brideData} groomData={data?.groomData} />
      {/* <Welcome /> */}
      <Story loveStory={data?.loveStory} />
      {/* <People guest={"guest-style"} weddingParty={data?.weddingParty} /> */}
      <WeddingPartyComponent
        weddingParty={data?.weddingParty}
        guest={"guest-style"}
      />
      <Location whenWhere={data?.whenWhere} />
      <Gallery galleryImages={data?.galleryImages} />
      {/* <Rsvp /> */}
      <RsvpComponent />
      {/* <Getting /> */}
      {/* <Gift /> */}
      <Footer sliderImages={data?.sliderImages} />
    </div>
  );
};

export default Homepage2;
