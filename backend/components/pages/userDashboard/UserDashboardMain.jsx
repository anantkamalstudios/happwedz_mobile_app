import React, { useEffect } from "react";
import { useParams } from "react-router-dom";
import { useSelector } from "react-redux";

import UserDashboardNavbar from "../../layouts/UserDashboardNavbar";
import Wedding from "./wedding/Wedding";
import Vendors from "./vendors/Vendors";
import Budget from "./budget/Budget";
import Check from "./checklist/Check";
import Guests from "./guests/Guests";
import WishList from "./wishlist/WishList";
import Booking from "./booking/Booking";
import Messages from "./messages/Messages";
import RealWeddingForm from "./realWeddingForm/RealWeddingForm";
import UserProfile from "./userProfile/UserProfile";
import FlightBookings from "./flightBookings/FlightBookings";

const UserDashboardMain = () => {
  const { slug } = useParams();
  const { user, token } = useSelector((state) => state.auth);
  const currentSlug = slug || "my-wedding";

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [currentSlug]);

  return (
    <div>
      <UserDashboardNavbar user={user} />
      {currentSlug === "my-wedding" && <Wedding user={user} token={token} />}
      {currentSlug === "checklist" && <Check user={user} token={token} />}
      {currentSlug === "vendor" && <Vendors user={user} token={token} />}
      {currentSlug === "guest-list" && <Guests user={user} token={token} />}
      {currentSlug === "budget" && <Budget user={user} token={token} />}
      {currentSlug === "wishlist" && <WishList user={user} token={token} />}
      {currentSlug === "user-profile" && (
        <UserProfile user={user} token={token} />
      )}
      {currentSlug === "booking" && <Booking user={user} token={token} />}
      {currentSlug === "message" && <Messages user={user} token={token} />}
      {currentSlug === "real-wedding" && (
        <RealWeddingForm user={user} token={token} />
      )}
      {currentSlug === "my-bookings" && <FlightBookings />}
    </div>
  );
};

export default UserDashboardMain;
