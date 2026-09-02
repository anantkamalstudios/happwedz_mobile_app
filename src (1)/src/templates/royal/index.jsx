import React from "react";

import Couple from "../components/couple";
import HeroMain from "../components/HeroMain";
import SimpleSlider from "../components/hero";
import Story from "../components/story";
import Welcome from "../components/welcome-area";
import People from "../components/people";
import Location from "../components/location";
import Gallery from "../components/gallery";
import Rsvp from "../components/rsvp";
import Getting from "../components/getting";
import Gift from "../components/gift";
import Navbar from "../components/Navbar";
import Saveday from "../components/countdown";
import Footer from "../components/footer";

const Homepage = ({ data }) => {
  return (
    <div>
      <Navbar brideData={data?.brideData} groomData={data?.groomData} />
      <HeroMain
        sliderImages={data?.sliderImages}
        weddingDate={data?.weddingDate}
      />
      <Saveday saveday={"s2"} weddingDate={data?.weddingDate} />
      <Couple
        couple={"s2"}
        brideData={data?.brideData}
        groomData={data?.groomData}
      />
      <Story loveStory={data?.loveStory} />
      <People guest={"guest-style"} weddingParty={data?.weddingParty} />
      <Location whenWhere={data?.whenWhere} />
      <Gallery galleryImages={data?.galleryImages} />
      <Rsvp />
      {/* <Gift /> */}
      <Footer sliderImages={data?.sliderImages} />
    </div>
  );
};

export default Homepage;
