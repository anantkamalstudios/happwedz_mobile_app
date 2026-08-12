import { IMAGE_BASE_URL } from "../config/constants";

export const getImageUrl = (imagePath) => {
    if (!imagePath) return "";
    if (imagePath.startsWith("http://") || imagePath.startsWith("https://")) {
        if (imagePath.includes("happywedz.com/uploads")) {
            return imagePath.replace(
                /https?:\/\/happywedz\.com/,
                IMAGE_BASE_URL.replace(/\/$/, "")
            );
        }
        return imagePath;
    }
    const cleanPath = imagePath.replace(/^\/+/, "");
    return `${IMAGE_BASE_URL.replace(/\/+$/, "")}/${cleanPath}`;
};

export const handleImageError = (e, imagePath) => {
    if (!imagePath) return;
    const target = e.target;
    if (target.src.includes(IMAGE_BASE_URL)) return;
    const fallbackUrl = getImageUrl(imagePath);
    if (fallbackUrl !== target.src) {
        target.src = fallbackUrl;
    }
};
