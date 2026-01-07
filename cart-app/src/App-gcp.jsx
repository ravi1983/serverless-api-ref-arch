import React, { useState, useEffect } from "react";
import { auth, googleProvider } from "./firebaseConfig";
import {
    signInWithRedirect,
    signInWithPopup,
    getRedirectResult,
    onAuthStateChanged,
    signOut
} from "firebase/auth";

const BASE_URL = "https://cart-gateway-cwc7wiu.uc.gateway.dev/cart";

function CartManager({ user, idToken }) {
    const [itemId, setItemId] = useState("");
    const [cart, setCart] = useState(null);
    const [message, setMessage] = useState("");
    const [loading, setLoading] = useState(false);

    const userId = user.uid;
    const API_URL = `${BASE_URL}?userId=${userId}`;

    const fetchWithAuth = async (method, body = null) => {
        setLoading(true);
        setMessage(""); // Clear previous messages
        try {
            const response = await fetch(API_URL, {
                method,
                headers: {
                    "Authorization": `Bearer ${idToken}`,
                    "Content-Type": "application/json"
                },
                body: body ? JSON.stringify(body) : null
            });

            if (!response.ok) {
                const errorBody = await response.text();
                throw new Error(`Status ${response.status}: ${errorBody}`);
            }

            const data = await response.json();
            console.log("API Response Data:", data);

            // Backend logic check: adjust based on your actual JSON structure
            setCart(method === "GET" ? data : data.cart);
            setMessage(`${method} request successful.`);
        } catch (err) {
            console.error("API Error:", err);
            setMessage(`Error: ${err.message}`);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="p-6 max-w-2xl mx-auto bg-white rounded-xl shadow-md space-y-4 mt-10">
            <h2 className="text-2xl font-bold text-gray-800">Shopping Cart</h2>
            <p className="text-sm text-gray-500 font-mono bg-gray-50 p-2 rounded">User ID: {userId}</p>

            <div className="flex space-x-2">
                <input
                    type="text"
                    className="border p-2 rounded w-full"
                    placeholder="Enter Product ID"
                    value={itemId}
                    onChange={(e) => setItemId(e.target.value)}
                />
                <button
                    onClick={() => fetchWithAuth("POST", { itemId })}
                    disabled={loading || !itemId}
                    className="bg-blue-600 text-white px-6 py-2 rounded disabled:opacity-50"
                >
                    {loading ? "Adding..." : "Add"}
                </button>
            </div>

            <button
                onClick={() => fetchWithAuth("GET")}
                disabled={loading}
                className="w-full bg-gray-100 py-2 rounded hover:bg-gray-200"
            >
                {loading ? "Refreshing..." : "Refresh Cart"}
            </button>

            {/* --- STATUS MESSAGE --- */}
            {message && (
                <div className={`p-3 rounded text-sm ${message.includes('Error') ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}`}>
                    {message}
                </div>
            )}

            {/* --- CART DISPLAY --- */}
            {cart && cart.items ? (
                <div className="mt-4 border-t pt-4">
                    <h3 className="font-semibold text-gray-700 mb-2">Items ({cart.items.length})</h3>
                    <ul className="divide-y divide-gray-100">
                        {cart.items.map((item, index) => (
                            <li key={index} className="py-2 flex justify-between items-center">
                                <span>Product {item.itemId}</span>
                                <span className="font-bold">${item.price || '0.00'}</span>
                            </li>
                        ))}
                    </ul>
                </div>
            ) : cart && (
                <p className="text-center text-gray-500 italic">Cart is empty or invalid data format.</p>
            )}
        </div>
    );
}

export default function App() {
    const [user, setUser] = useState(null);
    const [idToken, setIdToken] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // 1. First, check if we just returned from a redirect
        getRedirectResult(auth)
            .then((result) => {
                if (result) {
                    // User just logged in via redirect
                    console.log("User from redirect:", result.user);
                }
            })
            .catch((error) => {
                console.error("Redirect Error:", error);
            });

        // 2. Then, set up the persistent listener
        const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
            if (currentUser) {
                const token = await currentUser.getIdToken();
                setUser(currentUser);
                setIdToken(token);
            } else {
                setUser(null);
                setIdToken(null);
            }
            setLoading(false);
        });

        return () => unsubscribe();
    }, []);

    const handleLogin = () => signInWithPopup(auth, googleProvider);
    const handleLogout = () => signOut(auth);

    if (loading) return <div className="text-center mt-20">Loading Authentication...</div>;

    if (user) {
        return (
            <div className="min-h-screen bg-gray-50">
                <nav className="bg-white p-4 shadow flex justify-between">
                    <span>{user.email}</span>
                    <button onClick={handleLogout} className="text-red-500">Sign Out</button>
                </nav>
                <CartManager user={user} idToken={idToken} />
            </div>
        );
    }

    return (
        <div className="flex flex-col items-center justify-center min-h-screen bg-indigo-100">
            <button
                onClick={handleLogin}
                className="bg-blue-600 text-white px-10 py-4 rounded-xl font-bold shadow-lg"
            >
                Sign in with Google (GCP)
            </button>
        </div>
    );
}