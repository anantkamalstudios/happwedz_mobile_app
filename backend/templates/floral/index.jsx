import React from "react";

// components
import Couple from "../components/couple";
import BackgroundVideo from "../components/hero3";
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
import couple1 from "../images/couple/img-2.jpg";
import couple2 from "../images/couple/img-1.jpg";

const Homepage3 = ({ data }) => {
  return (
    <div>
      <Navbar brideData={data?.brideData} groomData={data?.groomData} />
      <BackgroundVideo
        images={data?.sliderImages}
        weddingDate={data?.weddingDate}
        coupleNames={{
          bride: data?.brideData?.title,
          groom: data?.groomData?.title,
        }}
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
      {/* <Getting /> */}
      <Gift />
      <Footer sliderImages={data?.sliderImages} />
    </div>
  );
};

export default Homepage3;
