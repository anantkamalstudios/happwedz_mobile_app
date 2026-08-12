import { useEffect } from "react";
import { useLocation } from "react-router-dom";

export default function ScrollToTop() {
    const { pathname, search } = useLocation();

    useEffect(() => {
        // iOS Safari fix – prevent it restoring old scroll
        if ("scrollRestoration" in window.history) {
            window.history.scrollRestoration = "manual";
        }

        // Automatic scroll to top AFTER route change
        setTimeout(() => {
            window.scrollTo({
                top: 0,
                left: 0,
                behavior: "auto", // IMPORTANT for iPhone
            });
        }, 0);
    }, [pathname, search]);

    return null;
}
