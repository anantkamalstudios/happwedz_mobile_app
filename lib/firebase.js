import { initializeApp } from "firebase/app";
import { getAuth, GoogleAuthProvider, signInWithPopup, signOut } from "firebase/auth";
import { getAnalytics } from "firebase/analytics";

const firebaseConfig = {
    apiKey: "AIzaSyAin8M2id_ScSISx_yaXp6p09lAuGYuu6E",
    authDomain: "happywedz-90467.firebaseapp.com",
    projectId: "happywedz-90467",
    storageBucket: "happywedz-90467.firebasestorage.app",
    messagingSenderId: "820659775924",
    appId: "1:820659775924:web:66dfb5f432e90528e8eae1",
    measurementId: "G-CJJY9XGW69"
};

const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

const auth = getAuth(app);
const provider = new GoogleAuthProvider();

export { app, analytics, auth, provider, signInWithPopup, signOut };
