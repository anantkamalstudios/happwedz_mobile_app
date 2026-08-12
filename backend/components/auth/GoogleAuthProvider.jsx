import React from "react";
import { GoogleOAuthProvider } from "@react-oauth/google";

export const GOOGLE_CLIENT_ID =
  "5404414440-02ttfd1mvhk62e5bubrkcipdjhdrrabv.apps.googleusercontent.com";

/**
 * Wrap only the subtrees that actually sign in with Google.
 *
 * Mounting GoogleOAuthProvider injects https://accounts.google.com/gsi/client,
 * which Lighthouse measured at 97KB transfer and ~268ms of main-thread time —
 * the single largest contributor to Total Blocking Time. At the app root that
 * cost was paid by every visitor on every page; here it is paid only when a
 * login screen renders, and those screens are behind lazy route chunks.
 */
export default function GoogleAuthProvider({ children }) {
  return (
    <GoogleOAuthProvider clientId={GOOGLE_CLIENT_ID}>
      {children}
    </GoogleOAuthProvider>
  );
}
