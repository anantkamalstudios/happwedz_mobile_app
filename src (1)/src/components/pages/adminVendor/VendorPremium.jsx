import React from "react";
import Swal from "sweetalert2";
import { FiTarget, FiUsers, FiTrendingUp, FiShield } from "react-icons/fi";
import PlanCards, { planSubtitle } from "./subscription/PlanCards";
import useSubscriptionPlans from "../../../hooks/useSubscriptionPlans";
import useRazorpayCheckout from "../../../hooks/useRazorpayCheckout";

/**
 * The vendor Upgrade page.
 *
 * Rebuilt from the template it shipped as: giant uppercase orange headings, orange
 * gradient plan headers and cards that scaled to 2x on hover. It now reads as part of
 * HappyWedz — a light neutral page where the only saturated colour is the pink on the
 * buttons and the recommended plan's edge.
 */

const PINK = "#c2185b";
const INK = "#1d1117";
const MUTED = "#6f5c66";
const LINE = "#e9e1e5";

const BENEFITS = [
  {
    icon: FiTarget,
    title: "Be found first",
    text: "Appear in front of couples actively searching for your service in your city.",
  },
  {
    icon: FiUsers,
    title: "Complete leads",
    text: "Enquiries arrive with full contact details, so you can reply while interest is high.",
  },
  {
    icon: FiTrendingUp,
    title: "More bookings",
    text: "A complete storefront — photos, pricing, availability — turns browsers into bookings.",
  },
];

const css = `
.hw-up { background:#faf8f9; min-height:100vh; padding:52px 0 72px; }
.hw-up__eyebrow {
  font-size:.74rem; font-weight:700; letter-spacing:.14em; text-transform:uppercase;
  color:${PINK}; margin-bottom:12px;
}
.hw-up__h1 {
  font-size:clamp(1.75rem,3.4vw,2.5rem); font-weight:700; letter-spacing:-.025em;
  color:${INK}; margin:0 0 12px; line-height:1.12; text-wrap:balance;
}
.hw-up__lede { color:${MUTED}; font-size:1.02rem; max-width:56ch; margin:0 auto; line-height:1.6; }
.hw-ben { background:#fff; border:1px solid ${LINE}; border-radius:14px; padding:24px 22px; height:100%; }
.hw-ben__icon {
  width:42px; height:42px; border-radius:11px; background:#fce7f0; color:${PINK};
  display:flex; align-items:center; justify-content:center; margin-bottom:14px;
}
.hw-ben__t { font-size:1rem; font-weight:700; color:${INK}; margin:0 0 6px; }
.hw-ben__p { font-size:.9rem; color:${MUTED}; line-height:1.6; margin:0; }
.hw-sec-h { font-size:1.5rem; font-weight:700; color:${INK}; letter-spacing:-.02em; margin:0 0 8px; }
.hw-sec-p { color:${MUTED}; margin:0 0 26px; }
.hw-note {
  display:flex; align-items:flex-start; gap:11px; background:#fff; border:1px solid ${LINE};
  border-radius:12px; padding:16px 20px; color:${MUTED}; font-size:.88rem; line-height:1.6;
}
`;

const VendorPremium = () => {
  const {
    visiblePlans,
    access,
    cycle,
    setCycle,
    showCycleTabs,
    loading,
    error,
    reload,
    storefrontTabs,
    trialAvailable,
  } = useSubscriptionPlans(true);

  const { startCheckout, startTrial, processing, status, activePlanId } =
    useRazorpayCheckout({
    onSuccess: async () => {
      await Swal.fire({
        icon: "success",
        title: "Payment successful",
        text: "Your storefront is unlocked. A receipt is on its way to your email.",
        confirmButtonColor: PINK,
        confirmButtonText: "Go to my storefront",
      });
      window.location.assign("/vendor-dashboard/vendor-store-front");
    },
    onError: (message) => {
      Swal.fire({ icon: "info", title: "Payment not completed", text: message });
      reload();
    },
  });

  return (
    <div className="hw-up">
      <style>{css}</style>

      <div className="container">
        <div className="text-center mb-5">
          <div className="hw-up__eyebrow">Grow your business</div>
          <h1 className="hw-up__h1">Get in front of couples ready to book</h1>
          <p className="hw-up__lede">
            A plan unlocks your full storefront and puts your business in front of couples
            planning their wedding in your area.
          </p>
        </div>

        <div className="row g-3 g-lg-4 mb-5">
          {BENEFITS.map(({ icon: Icon, title, text }) => (
            <div className="col-lg-4 col-md-6" key={title}>
              <div className="hw-ben">
                <div className="hw-ben__icon">
                  <Icon size={19} />
                </div>
                <h3 className="hw-ben__t">{title}</h3>
                <p className="hw-ben__p">{text}</p>
              </div>
            </div>
          ))}
        </div>

        <div className="text-center mb-4">
          <h2 className="hw-sec-h">Choose your plan</h2>
          <p className="hw-sec-p">{planSubtitle(visiblePlans, storefrontTabs)}</p>
        </div>

        {loading && (
          <div className="text-center py-5">
            <div className="spinner-border" style={{ color: PINK }} role="status">
              <span className="visually-hidden">Loading plans</span>
            </div>
          </div>
        )}

        {!loading && error && (
          <div className="alert alert-danger d-flex justify-content-between align-items-center">
            <span>{error}</span>
            <button className="btn btn-sm btn-outline-danger" onClick={reload}>
              Retry
            </button>
          </div>
        )}

        {!loading && !error && visiblePlans.length === 0 && (
          <div className="text-center py-5">
            <p className="fw-bold mb-1" style={{ color: INK }}>
              No plans available right now
            </p>
            <p className="mb-0" style={{ color: MUTED }}>
              Please check back shortly, or contact us and we will help you get set up.
            </p>
          </div>
        )}

        {!loading && !error && visiblePlans.length > 0 && (
          <>
            <PlanCards
              plans={visiblePlans}
              storefrontTabs={storefrontTabs}
              onStartTrial={startTrial}
              trialAvailable={trialAvailable}
              cycle={cycle}
              onCycleChange={setCycle}
              showCycleTabs={showCycleTabs}
              onChoose={startCheckout}
              processing={processing}
              processingLabel={status}
              processingPlanId={activePlanId}
              currentPlanId={access.subscription?.planId ?? null}
              canPurchase={access.canPurchase !== false}
              disabledReason="Complete your business verification first"
            />

            <div className="row justify-content-center mt-4">
              <div className="col-lg-8">
                <div className="hw-note">
                  <FiShield size={18} style={{ color: PINK, flex: "0 0 auto", marginTop: 1 }} />
                  <span>
                    Payments are processed securely by Razorpay. You will receive an
                    invoice by email, and your full payment history is available under{" "}
                    <strong style={{ color: INK }}>
                      Settings → Payments &amp; Subscription
                    </strong>
                    .
                  </span>
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default VendorPremium;
