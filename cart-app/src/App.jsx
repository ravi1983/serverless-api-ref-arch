import React, { useState, useEffect } from "react";

const BASE_URL = "https://ivt81dwo5l.execute-api.us-east-2.amazonaws.com/cart";
const COGNITO_DOMAIN = "https://serverless-cart-idp.auth.us-east-2.amazoncognito.com";
const CLIENT_ID = "51l5d5p052lqho4bnu9080k8ti";
const REDIRECT_URI = "http://localhost:5173/";

function CartManager({ user }) {
    const [itemId, setItemId] = useState("");
    const [cart, setCart] = useState(null);
    const [message, setMessage] = useState("");
    const [loading, setLoading] = useState(false);

    // Extract userId from the ID Token payload (sub claim)
    const userId = user?.profile?.sub || "Unknown";
    const API_URL = `${BASE_URL}?userId=${userId}`;

    const viewCart = async () => {
        setLoading(true);
        try {
            const response = await fetch(API_URL, {
                method: "GET",
                headers: {
                    "Authorization": `Bearer ${user.id_token}`,
                    "Content-Type": "application/json"
                }
            });
            const data = await response.json();
            setCart(data);
            setMessage("Cart loaded successfully.");
        } catch (err) {
            setMessage("Failed to load cart.");
        } finally {
            setLoading(false);
        }
    };

    const addItem = async () => {
        if (!itemId) return;
        setLoading(true);
        try {
            const response = await fetch(API_URL, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${user.id_token}`
                },
                body: JSON.stringify({ itemId: itemId })
            });

            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(errorText);
            }

            const data = await response.json();
            setCart(data.cart);
            setItemId("");
            setMessage(`Added item ${itemId}`);
        } catch (err) {
            console.error("Add Error:", err);
            setMessage(`Error: ${err.message}`);
        } finally {
            setLoading(false);
        }
    };

    const removeItem = async (itemToRemoveId) => {
        setLoading(true);
        try {
            const response = await fetch(API_URL, {
                method: "DELETE",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${user.id_token}`
                },
                body: JSON.stringify({ itemId: itemToRemoveId })
            });

            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(errorText);
            }

            const data = await response.json();
            setCart(data.cart); // Update state with the new cart returned by Lambda
            setMessage(`Removed item ${itemToRemoveId}`);
        } catch (err) {
            console.error("Remove Error:", err);
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
                    className="border p-2 rounded w-full focus:ring-2 focus:ring-blue-500 outline-none"
                    placeholder="Enter Product ID (e.g. 101)"
                    value={itemId}
                    onChange={(e) => setItemId(e.target.value)}
                />
                <button
                    onClick={addItem}
                    disabled={loading}
                    className="bg-blue-600 text-white px-6 py-2 rounded font-semibold hover:bg-blue-700 disabled:opacity-50 transition-colors"
                >
                    {loading ? "Adding..." : "Add"}
                </button>
            </div>

            <button
                onClick={viewCart}
                className="w-full bg-gray-100 py-2 rounded hover:bg-gray-200 text-gray-700 font-semibold transition-colors"
            >
                Refresh / View Cart
            </button>

            {message && (
                <div className={`p-3 rounded text-sm animate-pulse ${message.includes('Error') ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}`}>
                    {message}
                </div>
            )}

            {cart && (
                <div className="mt-4 border-t pt-4">
                    <div className="flex justify-between items-center mb-4">
                        <h3 className="font-semibold text-gray-700">Items in Cart ({cart.itemCount || 0})</h3>
                    </div>
                    {cart.items.map((item, index) => (
                        <li key={index} className="py-3 flex justify-between items-center group">
                            <div>
                                <p className="font-medium text-gray-800">{item.description || `Product ${item.itemId}`}</p>
                                <p className="text-xs text-gray-400 font-mono">ID: {item.itemId}</p>
                            </div>
                            <div className="flex items-center space-x-4">
                                <span className="font-mono font-bold text-blue-600">${item.price}</span>
                                <button
                                    onClick={() => removeItem(item.itemId)}
                                    className="text-red-400 hover:text-red-600 p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                                    title="Remove Item"
                                >
                                    <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                                        <path fillRule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clipRule="evenodd" />
                                    </svg>
                                </button>
                            </div>
                        </li>
                    ))}
                </div>
            )}
        </div>
    );
}

export default function App() {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const handleCallback = async () => {
            const urlParams = new URLSearchParams(window.location.search);
            const code = urlParams.get("code");

            if (code) {
                // Remove code from URL to keep it clean
                window.history.replaceState({}, document.title, "/");

                try {
                    setLoading(true);
                    // Exchange authorization code for tokens
                    const response = await fetch(`${COGNITO_DOMAIN}/oauth2/token`, {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/x-www-form-urlencoded",
                        },
                        body: new URLSearchParams({
                            grant_type: "authorization_code",
                            client_id: CLIENT_ID,
                            code: code,
                            redirect_uri: REDIRECT_URI,
                        }),
                    });

                    if (!response.ok) {
                        const errData = await response.json();
                        throw new Error(errData.error || "Failed to exchange code for tokens");
                    }

                    const tokens = await response.json();

                    // Decode ID Token (JWT) to get profile info
                    // Note: In production, use a library like jwt-decode
                    const payloadBase64 = tokens.id_token.split('.')[1];
                    const decodedPayload = JSON.parse(atob(payloadBase64));

                    setUser({
                        id_token: tokens.id_token,
                        access_token: tokens.access_token,
                        profile: decodedPayload
                    });
                } catch (err) {
                    console.error("Auth Error:", err);
                    setError(err.message);
                } finally {
                    setLoading(false);
                }
            } else {
                setLoading(false);
            }
        };

        handleCallback();
    }, []);

    const handleLogin = () => {
        const loginUrl = `${COGNITO_DOMAIN}/oauth2/authorize?client_id=${CLIENT_ID}&response_type=code&scope=email+openid+profile&redirect_uri=${encodeURIComponent(REDIRECT_URI)}`;
        window.location.href = loginUrl;
    };

    const handleLogout = () => {
        setUser(null);
        const logoutUrl = `${COGNITO_DOMAIN}/logout?client_id=${CLIENT_ID}&logout_uri=${encodeURIComponent(REDIRECT_URI)}`;
        window.location.href = logoutUrl;
    };

    if (loading) {
        return (
            <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50">
                <div className="w-12 h-12 border-4 border-blue-600 border-t-transparent rounded-full animate-spin mb-4"></div>
                <p className="text-gray-600 font-medium">Authenticating...</p>
            </div>
        );
    }

    if (error) {
        return (
            <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50 p-4">
                <div className="bg-white p-8 rounded-2xl shadow-xl text-center max-w-md">
                    <div className="text-red-500 text-5xl mb-4">⚠️</div>
                    <h2 className="text-xl font-bold text-gray-800 mb-2">Authentication Failed</h2>
                    <p className="text-gray-600 mb-6">{error}</p>
                    <button onClick={() => window.location.href = "/"} className="bg-blue-600 text-white px-6 py-2 rounded-lg">Try Again</button>
                </div>
            </div>
        );
    }

    if (user) {
        return (
            <div className="min-h-screen bg-gray-50 pb-12">
                <nav className="bg-white shadow-sm mb-8">
                    <div className="max-w-4xl mx-auto px-4 h-16 flex justify-between items-center">
                        <div className="flex flex-col">
                            <span className="text-xs text-gray-400 uppercase font-bold tracking-wider">Logged in as </span>
                            <span className="text-gray-700 font-medium">{user.profile.email}</span>
                        </div>
                        <button
                            onClick={handleLogout}
                            className="text-sm font-semibold text-red-500 hover:bg-red-50 px-4 py-2 rounded-lg transition-colors"
                        >
                            Sign Out
                        </button>
                    </div>
                </nav>
                <CartManager user={user} />
            </div>
        );
    }

    return (
        <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
            <div className="bg-white p-10 rounded-3xl shadow-2xl text-center max-w-md w-full border border-white/50 backdrop-blur-sm">
                <div className="w-20 h-20 bg-blue-600 rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-lg shadow-blue-200">
                    <svg xmlns="http://www.w3.org/2000/svg" className="h-10 w-10 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                    </svg>
                </div>
                <h1 className="text-4xl font-extrabold mb-2 text-gray-900">Serverless Cart</h1>
                <p className="mb-10 text-gray-500 leading-relaxed">A fully authenticated serverless shopping experience powered by AWS Cognito.</p>
                <button
                    onClick={handleLogin}
                    className="w-full bg-blue-600 text-white px-8 py-4 rounded-xl font-bold hover:bg-blue-700 transition-all shadow-xl shadow-blue-200 active:scale-95"
                >
                    Sign in with Cognito
                </button>
                <p className="mt-6 text-xs text-gray-400">Securely sign in to sync your cart across all your devices.</p>
            </div>
        </div>
    );
}