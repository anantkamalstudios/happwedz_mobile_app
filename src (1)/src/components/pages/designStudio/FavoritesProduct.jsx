import React, { useState, useMemo, useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { addFavorite, removeFavorite } from "../../../redux/favoriteSlice";
import { IoClose } from "react-icons/io5";
import { AiFillHeart, AiOutlineHeart } from "react-icons/ai";

export default function FavouriteListPopup({
  setShowPopup,
  appliedProductsObj,
  onRemoveApplied,
  activeList,
}) {
  const dispatch = useDispatch();
  const favorites = useSelector((store) => store.favorites?.favorites) || [];
  const [activeTab, setActiveTab] = useState(
    activeList === "Complete Look" ? "current" : "favourite"
  );
  const [showEmailPopUp, setShowEmailPopUp] = useState(false);
  const [email, setEmail] = useState("");

  useEffect(() => {
    if (activeList === "Complete Look") {
      setActiveTab("current");
    }
  }, [activeList]);

  const appliedProducts = useMemo(() => {
    if (appliedProductsObj && typeof appliedProductsObj === "object") {
      return Object.values(appliedProductsObj);
    }
    try {
      const raw = sessionStorage.getItem("finalLookFilters");
      const parsed = raw ? JSON.parse(raw) : {};
      return Object.values(parsed || {});
    } catch (e) {
      return [];
    }
  }, [appliedProductsObj]);

  const currentData = activeTab === "current" ? appliedProducts : favorites;
  const showEmailButton = activeTab === "favourite" && favorites.length > 0;

  return (
    <div
      style={{
        background: "transparent",
        minHeight: "100vh",
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        padding: "20px",
        position: "relative",
      }}
    >
      <div
        style={{
          background: "#fce4ec",
          width: "80%", // responsive width
          maxWidth: "700px",
          margin: "0 auto", // center popup
          boxShadow: "0 10px 40px rgba(0, 0, 0, 0.2)",
          overflow: "hidden",
          position: "relative",
          borderRadius: "12px", // optional nicer UI
        }}
      >
        {/* Header with Tabs */}
        <div
          style={{
            background: "#d81b60",
            padding: "12px 40px",
            display: "flex",
            gap: "12px",
            alignItems: "center",
            position: "relative",
          }}
        >
          <button
            onClick={() => setActiveTab("current")}
            style={{
              flex: 1,
              background: activeTab === "current" ? "white" : "transparent",
              color: activeTab === "current" ? "#d81b60" : "white",
              border: "none",
              borderRadius: "8px",
              padding: "12px 15px",
              fontSize: "12px",
              fontWeight: "600",
              cursor: "pointer",
              textTransform: "uppercase",
              transition: "all 0.2s ease",
            }}
          >
            CURRENT LOOK
          </button>
          <button
            onClick={() => setActiveTab("favourite")}
            style={{
              flex: 1,
              background: activeTab === "favourite" ? "white" : "transparent",
              color: activeTab === "favourite" ? "#d81b60" : "white",
              border: "none",
              borderRadius: "8px",
              padding: "12px 15px",
              fontSize: "12px",
              fontWeight: "600",
              cursor: "pointer",
              textTransform: "uppercase",
              transition: "all 0.2s ease",
            }}
          >
            FAVOURITE LIST
          </button>

          {/* Close button */}
          <div
            onClick={() => setShowPopup(false)}
            style={{
              position: "absolute",
              right: "5px",
              top: "5px",
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <IoClose color="#fff" size={28} />
          </div>
        </div>

        <div
          style={{
            padding: "20px",
            maxHeight: "450px",
            overflowY: "auto",
            minHeight: "300px",
          }}
        >
          {activeList === "Complete Look" && currentData.length === 0 ? (
            <div
              style={{
                textAlign: "center",
                color: "#666",
                padding: "60px 20px",
                fontSize: "16px",
              }}
            >
              {activeTab === "current"
                ? "No products applied yet."
                : "No favorites yet. Start adding products to your favorites!"}
            </div>
          ) : (
            currentData.map((item) => {
              const isFavorited = favorites.some(
                (fav) => fav.id === (item?.id ?? item?.productId)
              );
              return (
                <div
                  key={item.productId || item.id}
                  style={{
                    display: "flex",
                    background: "#f8b4d4",
                    borderRadius: "12px",
                    marginBottom: "15px",
                    padding: "12px",
                    alignItems: "center",
                    position: "relative",
                  }}
                >
                  {/* Top-right cross button */}
                  <button
                    onClick={() => {
                      if (activeTab === "current") {
                        if (onRemoveApplied && item?.categoryName) {
                          onRemoveApplied(item.categoryName);
                        }
                      } else {
                        dispatch(removeFavorite(item.id));
                      }
                    }}
                    style={{
                      position: "absolute",
                      top: "8px",
                      right: "8px",
                      width: "24px",
                      height: "24px",
                      border: "none",
                      borderRadius: "50%",
                      background: "white",
                      color: "#d81b60",
                      cursor: "pointer",
                      fontWeight: "bold",
                      fontSize: "18px",
                      display: "flex",
                      justifyContent: "center",
                      alignItems: "center",
                      padding: 0,
                      lineHeight: 1,
                    }}
                  >
                    ×
                  </button>

                  <div
                    style={{
                      width: "clamp(50px, 15vw, 60px)",
                      height: "clamp(50px, 15vw, 60px)",
                      position: "relative",
                      backgroundColor: "white",
                      borderRadius: "8px",
                      overflow: "hidden",
                      flexShrink: 0,
                      boxShadow: "0 2px 6px rgba(0,0,0,0.15)",
                    }}
                  >
                    <img
                      src={item?.product_real_image}
                      alt="product"
                      style={{
                        width: "100%",
                        height: "100%",
                        objectFit: "cover",
                      }}
                    />
                    {/* Heart Icon */}
                    
                    <button
                      onClick={() => {
                        const favId = item?.id ?? item?.productId;
                        if (!favId) return;
                        if (isFavorited) {
                          dispatch(removeFavorite(favId));
                        } else {
                          const toAdd = item?.id
                            ? {
                                ...item,
                                product_name:
                                  item.product_name ||
                                  item.description ||
                                  item.name ||
                                  item.title ||
                                  "",
                                description:
                                  item.product_name ||
                                  item.description ||
                                  item.name ||
                                  item.title ||
                                  "",
                              }
                            : {
                                id: item.productId,
                                product_real_image: item.product_real_image,
                                product_name:
                                  item.product_name ||
                                  item.description ||
                                  item.name ||
                                  item.title ||
                                  "",
                                description:
                                  item.product_name ||
                                  item.description ||
                                  item.name ||
                                  item.title ||
                                  "",
                                price: item.price,
                              };
                          dispatch(addFavorite(toAdd));
                        }
                      }}
                      style={{
                        position: "absolute",
                        top: "0px",
                        right: "0px",
                        width: "clamp(20px, 4vw, 24px)",
                        height: "clamp(20px, 4vw, 24px)",
                        borderRadius: "50%",
                        border: "none",
                        backgroundColor: "rgba(255,255,255,0.8)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        cursor: "pointer",
                        padding: 0,
                      }}
                    >
                      {isFavorited ? (
                        <AiFillHeart color="red" size={16} />
                      ) : (
                        <AiOutlineHeart color="#ccc" size={16} />
                      )}
                    </button>
                  </div>

                  {/* Right Side */}
                  <div
                    style={{
                      flex: 1,
                      display: "flex",
                      flexDirection: "column",
                      marginTop: "4px",
                      marginLeft: "12px",
                      gap: "4px",
                    }}
                  >
                    {/* Details */}
                    <div
                      style={{
                        fontSize: "clamp(11px, 2.5vw, 13px)",
                        color: "#000",
                        fontWeight: "600",
                        marginBottom: "8px",
                        lineHeight: "1.3",
                        paddingRight: "30px",
                        wordBreak: "break-word",
                        overflowWrap: "anywhere",
                      }}
                    >
                      {item.product_name || item.description || ""}
                    </div>

                    <div
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                      }}
                    >
                      <div
                        style={{
                          fontSize: "16px",
                          fontWeight: "700",
                          color: "#000",
                        }}
                      >
                        {item.price}
                      </div>

                      {/* <button
                        style={{
                          background: "white",
                          color: "#d81b60",
                          border: "none",
                          borderRadius: "8px",
                          padding: "8px 16px",
                          fontSize: "13px",
                          fontWeight: "600",
                          cursor: "pointer",
                          textTransform: "uppercase",
                        }}
                      >
                        BUY NOW
                      </button> */}
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* {showEmailButton && (
          <div style={{ padding: "0 20px 20px 20px" }}>
            <button
              onClick={() => setShowEmailPopUp(true)}
              disabled={true}
              style={{
                width: "100%",
                background: "#d81b60",
                color: "white",
                border: "none",
                borderRadius: "12px",
                padding: "16px",
                fontSize: "16px",
                fontWeight: "600",
                cursor: "pointer",
                textTransform: "capitalize",
                opacity: 0.5,
              }}
            >
              Email Favourite
            </button>
          </div>
        )} */}
      </div>

      {/* Email Popup */}
      {showEmailPopUp && (
        <div
          onClick={() => setShowEmailPopUp(false)}
          style={{
            position: "fixed",
            top: 0,
            left: 0,
            width: "100vw",
            height: "100vh",
            backgroundColor: "rgba(0,0,0,0.5)",
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            zIndex: 9999,
            padding: "20px",
          }}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{
              width: "100%",
              maxWidth: "400px",
              background: "#fff",
              borderRadius: "16px",
              boxShadow: "0 8px 24px rgba(0,0,0,0.2)",
              padding: "24px 28px",
              display: "flex",
              flexDirection: "column",
              gap: "16px",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <h3
              style={{ color: "#d81b60", marginBottom: 8, textAlign: "center" }}
            >
              Enter your email
            </h3>
            <input
              type="email"
              placeholder="example@email.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              style={{
                border: "2px solid #f0f0f0b9",
                borderRadius: "10px",
                width: "100%",
                padding: "10px 12px",
                fontSize: "1rem",
                outline: "none",
              }}
            />
            <button
              style={{
                width: "100%",
                padding: "10px 0",
                background: "#d81b60",
                color: "#fff",
                fontWeight: 600,
                border: "none",
                borderRadius: "10px",
                cursor: "pointer",
                fontSize: "1rem",
                transition: "all 0.2s ease-in-out",
              }}
              onMouseEnter={(e) => (e.currentTarget.style.opacity = "0.9")}
              onMouseLeave={(e) => (e.currentTarget.style.opacity = "1")}
            >
              Send Email
            </button>
            <button
              onClick={() => setShowEmailPopUp(false)}
              style={{
                background: "transparent",
                color: "#999",
                border: "none",
                fontSize: "0.9rem",
                marginTop: "4px",
                cursor: "pointer",
              }}
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
