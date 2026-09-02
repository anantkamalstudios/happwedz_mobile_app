import { initializeApp } from "firebase/app";
import {
  getAuth,
  GoogleAuthProvider,
  signInWithPopup,
  signOut,
} from "firebase/auth";
import { getAnalytics } from "firebase/analytics";

const firebaseConfig = {
  apiKey: "AIzaSyB8hWBBMSOqv0nUumrWFSFKsWwRFn29Sd8",
  authDomain: "happywedz-6b074.firebaseapp.com",
  projectId: "happywedz-6b074",
  storageBucket: "happywedz-6b074.firebasestorage.app",
  messagingSenderId: "307393487593",
  appId: "1:307393487593:web:78b7ac927557ce0c0bc678",
  measurementId: "G-P9S2ENYWSW",
};

const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

const auth = getAuth(app);
const provider = new GoogleAuthProvider();

export { app, analytics, auth, provider, signInWithPopup, signOut };
