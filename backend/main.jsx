import React from "react";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import axios from "axios";
import App from "./App.jsx";

// Dev-only: redirect live API calls at a locally running backend. Guarded by
// import.meta.env.DEV so Rollup drops the whole block from production builds —
// unguarded, a production bundle would rewrite every request to localhost:4000.
if (import.meta.env.DEV) {
  const LIVE_API = "https://happywedz.com/api";
  const LOCAL_API = "http://127.0.0.1:4000/api";

  axios.interceptors.request.use((config) => {
    if (config.url && config.url.startsWith(LIVE_API)) {
      config.url = config.url.replace(LIVE_API, LOCAL_API);
    }
    return config;
  });

  const originalFetch = window.fetch;
  window.fetch = function (input, init) {
    if (typeof input === "string" && input.startsWith(LIVE_API)) {
      input = input.replace(LIVE_API, LOCAL_API);
    }
    return originalFetch(input, init);
  };
}

import { Provider } from "react-redux";
import store from "./redux/store.js";
import { BrowserRouter } from "react-router-dom";
import "bootstrap/dist/css/bootstrap.min.css";
import LoaderProvider from "./components/context/LoaderContext";

import { HelmetProvider } from "react-helmet-async";

// Bootstrap's JS bundle (~80KB) only powers `data-bs-*` widgets, none of which
// appear above the fold. Importing it here statically put it in the entry chunk
// where it was parsed and executed before first paint; loading it after the
// browser goes idle keeps it off the critical path.
const loadBootstrapJs = () => import("bootstrap/dist/js/bootstrap.bundle.min.js");
if (typeof window !== "undefined") {
  if ("requestIdleCallback" in window) {
    window.requestIdleCallback(loadBootstrapJs, { timeout: 3000 });
  } else {
    window.addEventListener("load", () => setTimeout(loadBootstrapJs, 1000), {
      once: true,
    });
  }
}

// Two providers used to wrap the tree here and have been removed:
//
// - GoogleOAuthProvider made every visitor download and execute
//   accounts.google.com/gsi/client (97KB, ~268ms of main-thread time). It now
//   lives in src/components/auth/GoogleAuthProvider.jsx, mounted only by the
//   login screens that need it.
//
// - MUI's ThemeProvider pulled @mui/material/styles and emotion into the entry
//   chunk on every page load. The theme it supplied (src/theme/muiTheme.js) did
//   exactly one thing — set font-family: var(--rubik-font) on MUI components —
//   which App.critical.css now does directly, with no JS. No component reads
//   anything else off the theme; WriteReviewPage brings its own ThemeProvider.
createRoot(document.getElementById("root")).render(
  <StrictMode>
    <LoaderProvider>
      <Provider store={store}>
        <HelmetProvider>
          <BrowserRouter>
            <App />
          </BrowserRouter>
        </HelmetProvider>
      </Provider>
    </LoaderProvider>
  </StrictMode>
);
