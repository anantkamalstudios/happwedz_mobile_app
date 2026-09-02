import React, { useEffect, useState } from "react";
import "./guest-token.css";
import useMovmentPlus from "../../hooks/useMovmentPlus";
import { toast } from "react-toastify";
import { useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { setGuestToken, removeGuestToken } from "../../redux/guestToken";

const GuestTokenPage = () => {
  const [tokenInput, setTokenInput] = useState("");
  const { fetchGalleryByToken, loading } = useMovmentPlus();
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const { guestToken } = useSelector((state) => state.guestToken);

  useEffect(() => {
    if (guestToken) {
      setTokenInput(guestToken);
      verifyToken(guestToken);
    }
  }, [guestToken]);

  const verifyToken = async (token) => {
    try {
      const response = await fetchGalleryByToken(token);
      if (response && response.success) {
        // Token is valid, redirect
        navigate(`/movment-plus/gallery/${token}`, {
          state: { galleryData: response },
        });
      } else {
        // Token invalid, remove it
        dispatch(removeGuestToken());
      }
    } catch (error) {
      dispatch(removeGuestToken());
    }
  };

  const handleSubmit = async () => {
    if (!tokenInput.trim()) {
      toast.error("Please enter a valid token");
      return;
    }

    try {
      const response = await fetchGalleryByToken(tokenInput);
      if (response && response.success) {
        dispatch(setGuestToken(tokenInput));
        toast.success("Gallery accessed successfully!");
        navigate(`/movment-plus/gallery/${tokenInput}`, {
          state: { galleryData: response },
        });
      } else {
        toast.error("Invalid token or no gallery found.");
      }
    } catch (error) {
      toast.error(error?.response?.data?.message || "An error occurred");
    }
  };

  return (
    <section className="guest_token_page_9k3m7">
      <div className="container px-3 px-md-4 px-lg-5">
        <div className="row justify-content-center align-items-center min-vh-100 py-5">
          <div className="col-12 col-lg-10 col-xl-8">
            <div className="token_card_5j8m2">
              {/* Lock Icon */}
              <div className="icon_wrapper_3k7n9">
                <div className="icon_background_8m2p4">
                  <svg
                    className="lock_icon_6j9w3"
                    width="64"
                    height="64"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                  >
                    <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zM9 6c0-1.66 1.34-3 3-3s3 1.34 3 3v2H9V6zm9 14H6V10h12v10zm-6-3c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2z" />
                  </svg>
                </div>
              </div>

              {/* Heading */}
              <h1 className="page_title_4n8k6">Access Private Gallery</h1>

              {/* Description */}
              <p className="page_description_7k2m9">
                Enter your unique access code to view your private wedding
                photos
              </p>

              {/* Input Section */}
              <div className="token_form_2n5k8">
                <div className="form_group_8k3m7">
                  <input
                    type="text"
                    className="token_input_5j7n2"
                    placeholder="Enter Token Eg, ABC#S45dr"
                    value={tokenInput}
                    onChange={(e) => setTokenInput(e.target.value)}
                  />
                </div>

                <button
                  onClick={handleSubmit}
                  className="view_gallery_btn_9m2k4"
                  disabled={loading}
                >
                  {loading ? "Verifying..." : "View Gallery"}
                </button>
              </div>

              {/* Divider Line */}
              <div className="divider_line_3k8n5"></div>

              {/* Help Text */}
              <div className="help_text_section_6j9m2">
                <p className="help_text_7k3p8">
                  Your access code was provided by your photographer on Gmail or
                  WhatsApp.
                </p>
                <p className="help_text_example_4m5n9">Try: ABC123 or XYZ789</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default GuestTokenPage;
