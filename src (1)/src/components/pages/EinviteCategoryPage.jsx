import React, { useEffect } from "react";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import SEO from "../common/SEO";
import EinviteCatalog from "../layouts/einvites/EinviteCatalog";
import { CARD_TYPES } from "../layouts/einvites/design/einviteDesign";

const EinviteCategoryPage = () => {
  const { category } = useParams();
  const navigate = useNavigate();
  const location = useLocation();

  const typeInfo = CARD_TYPES.find((type) => type.value === category);

  useEffect(() => {
    if (!typeInfo) navigate("/einvites/category/wedding_einvite", { replace: true });
  }, [typeInfo, navigate]);

  if (!typeInfo) return null;

  return (
    <>
      <SEO
        title={`${typeInfo.title} – Online Wedding Invitation Designs | HappyWedz`}
        description={`Browse beautiful ${typeInfo.title.toLowerCase()} and personalise every page with your names, dates and venue. Download in HD or share on WhatsApp.`}
      />
      <EinviteCatalog
        cardType={typeInfo.value}
        onCardTypeChange={(type) =>
          navigate({ pathname: `/einvites/category/${type}`, search: location.search })
        }
      />
    </>
  );
};

export default EinviteCategoryPage;
