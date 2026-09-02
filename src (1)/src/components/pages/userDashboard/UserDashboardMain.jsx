import React, { useEffect } from "react";
import { Navigate, useParams } from "react-router-dom";
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
import CabBookingDetail from "./cabBookings/CabBookingDetail";

// The flight and cab lists are now panels inside the Booking tab. Their old
// standalone URLs still work — they redirect to the matching sub-tab, so
// bookmarks and links from the honeymoon flow keep resolving.
const REDIRECTS = {
  "my-bookings": "/user-dashboard/booking/travel/flights",
  "my-cab-bookings": "/user-dashboard/booking/travel/cabs",
};

const UserDashboardMain = () => {
  const { slug, id, category, sub } = useParams();
  const { user, token } = useSelector((state) => state.auth);

  // Only the /user-dashboard/booking/... routes carry :category.
  const isBookingRoute = category !== undefined;
  const currentSlug = isBookingRoute ? "booking" : slug || "my-wedding";

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [currentSlug]);

  if (!id && REDIRECTS[currentSlug]) {
    return <Navigate to={REDIRECTS[currentSlug]} replace />;
  }

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
      {currentSlug === "booking" && <Booking category={category} sub={sub} />}
      {currentSlug === "message" && <Messages user={user} token={token} />}
      {currentSlug === "real-wedding" && (
        <RealWeddingForm user={user} token={token} />
      )}
      {currentSlug === "cab-bookings" && id && <CabBookingDetail />}
    </div>
  );
};

export default UserDashboardMain;
