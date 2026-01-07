import React, { useState, useEffect } from 'react';
import { auth, googleProvider } from './firebaseConfig';
import { signInWithPopup, onAuthStateChanged, signOut } from 'firebase/auth';

function App() {
    const [user, setUser] = useState(null);

    // Listen for changes in auth state (login/logout)
    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
            setUser(currentUser);
        });
        return () => unsubscribe();
    }, []);

    const login = async () => {
        try {
            await signInWithPopup(auth, googleProvider);
        } catch (error) {
            console.error("Login failed", error);
        }
    };

    const logout = () => signOut(auth);

    return (
        <div style={{ textAlign: 'center', marginTop: '50px' }}>
            {user ? (
                <div>
                    <h1>Hello World, {user.displayName}!</h1>
                    <p>Email: {user.email}</p>
                    <button onClick={logout}>Logout</button>
                </div>
            ) : (
                <div>
                    <h1>Welcome</h1>
                    <p>Please log in to see the message.</p>
                    <button onClick={login}>Login with Google</button>
                </div>
            )}
        </div>
    );
}

export default App;