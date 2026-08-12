import React, { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import {
  FaRing,
  FaClipboardList,
  FaStore,
  FaUsers,
  FaPiggyBank,
  FaHeart,
  FaShoppingCart,
  FaEnvelopeOpenText,
  FaUserFriends,
  FaUser,
} from "react-icons/fa";

const tabs = [
  {
    id: "wedding",
    slug: "my-wedding",
    label: "My Wedding",
    icon: <FaRing />,
    img: "/images/userDashboard/mywedding-img.svg",
  },
  {
    id: "checklist",
    slug: "checklist",
    label: "Checklist",
    icon: <FaClipboardList />,
    img: "/images/userDashboard/checklist-img.svg",
  },
  {
    id: "vendors",
    slug: "vendor",
    label: "Vendor",
    icon: <FaStore />,
    img: "/images/userDashboard/vendor-img.svg",
  },
  {
    id: "guest-list",
    slug: "guest-list",
    label: "Guest list",
    icon: <FaUsers />,
    img: "/images/userDashboard/guestlist-img.svg",
  },
  {
    id: "budget",
    slug: "budget",
    label: "Budget",
    icon: <FaPiggyBank />,
    img: "/images/userDashboard/budget-img.svg",
  },
  {
    id: "wishlist",
    slug: "wishlist",
    label: "Wishlist",
    icon: <FaHeart />,
    img: "/images/userDashboard/wishlist-img.svg",
  },
  {
    id: "booking",
    slug: "booking",
    label: "Booking",
    icon: <FaShoppingCart />,
    img: "/images/userDashboard/booking-img.svg",
  },
  {
    id: "message",
    slug: "message",
    label: "Message",
    icon: <FaEnvelopeOpenText />,
    img: "/images/userDashboard/message-img.svg",
  },
  {
    id: "real-wedding",
    slug: "real-wedding",
    label: "Real wedding",
    icon: <FaUserFriends />,
    img: "/images/userDashboard/real-wedding-img1.png",
  },
  {
    id: "user-profile",
    slug: "user-profile",
    label: "Profile",
    img: "/images/userDashboard/userProfile-img.svg",
  },
];

const UserDashboardNavbar = () => {
  const { slug } = useParams();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState("wedding");

  useEffect(() => {
    const foundTab = tabs.find((tab) => tab.slug === slug);
    if (foundTab) {
      setActiveTab(foundTab.id);
    } else {
      setActiveTab("wedding");
    }
  }, [slug]);

  const handleTabClick = (tab) => {
    setActiveTab(tab.id);
    navigate(`/user-dashboard/${tab.slug}`);
  };

  return (
    <div className="container border-bottom py-3 px-3 mt-3">
      <div
        className="d-flex gap-3 flex-nowrap justify-content-md-center"
        style={{
          overflowX: "auto",
          WebkitOverflowScrolling: "touch",
          scrollBehavior: "smooth",
          scrollbarWidth: "thin",
          scrollbarColor: "#ed1173 #fff",
        }}
        role="tablist"
        aria-label="User dashboard navigation"
      >
        {tabs.map((tab) => (
          <button
            key={tab.id}
            className="btn border-0 d-flex flex-column align-items-center p-0"
            style={{
              background: "transparent",
              fontSize: "19px",
              minWidth: "72px",
              color: activeTab === tab.id ? "#ed1173" : "#212529",
            }}
            onClick={() => handleTabClick(tab)}
          >
            <div
              className="d-flex align-items-center justify-content-center"
              style={{
                width: "56px",
                height: "56px",
                borderRadius: "50%",
                backgroundColor: "#ed1173",
                color: "#fff",
                fontSize: "22px",
              }}
            >
              {/* {tab.icon} */}
              <div
                style={{
                  height: "52px",
                  width: "52px",
                  padding: "4px",
                  border: "none",
                }}
              >
                <img
                  src={tab.img}
                  alt=""
                  style={{
                    height: "100%",
                    width: "100%",
                    objectFit: "contain",
                    borderRadius: "50%",
                  }}
                />
              </div>
            </div>
            <span
              className="mt-2 fs-16"
              style={{
                fontWeight: activeTab === tab.id ? "600" : "400",
              }}
            >
              {tab.label}
            </span>
            {activeTab === tab.id && (
              <div
                style={{
                  marginTop: "4px",
                  height: "3px",
                  width: "40px",
                  backgroundColor: "#ed1173",
                  borderRadius: "2px",
                }}
              />
            )}
          </button>
        ))}
      </div>
    </div>
  );
};

export default UserDashboardNavbar;
