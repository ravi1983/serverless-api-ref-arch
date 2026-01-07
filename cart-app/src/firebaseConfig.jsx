import { initializeApp } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth";

const firebaseConfig = {
    apiKey: import.meta.env.VITE_IP_API_KEY,
    authDomain: import.meta.env.VITE_IP_AUTH_DOMAIN,
    projectId: import.meta.env.VITE_PROJECT_ID
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const googleProvider = new GoogleAuthProvider();