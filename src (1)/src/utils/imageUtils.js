import { IMAGE_BASE_URL } from "../config/constants";

export const getImageUrl = (imagePath) => {
    if (!imagePath) return "";
    
    // Extract everything from /uploads/ onwards if it exists, to fix corrupted DB URLs
    const uploadsMatch = imagePath.match(/\/uploads\/.*/);
    if (uploadsMatch) {
        return `${IMAGE_BASE_URL.replace(/\/+$/, "")}${uploadsMatch[0]}`;
    }

    if (imagePath.startsWith("http://") || imagePath.startsWith("https://")) {
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
