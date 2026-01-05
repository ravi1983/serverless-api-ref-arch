import React, { useState, useEffect } from "react";
import { PublicClientApplication } from "@azure/msal-browser";
import { MsalProvider, useMsal, AuthenticatedTemplate, UnauthenticatedTemplate } from "@azure/msal-react";

// 1. Configuration - Use VITE_ variables
const msalConfig = {
    auth: {
        clientId: import.meta.env.VITE_AZURE_CLIENT_ID,
        authority: `https://login.microsoftonline.com/${import.meta.env.VITE_AZURE_TENANT_ID}`,
        redirectUri: "http://localhost:5173/",
    },
    cache: {
        cacheLocation: "sessionStorage",
        storeAuthStateInCookie: false,
    }
};

const loginRequest = {
    scopes: [import.meta.env.VITE_AZURE_API_SCOPE]
};

// 2. Create the instance OUTSIDE the component so it doesn't re-render
const pca = new PublicClientApplication(msalConfig);

export default function AppAzure() {
    const [isInitialized, setIsInitialized] = useState(false);

    useEffect(() => {
        const initializeMsal = async () => {
            try {
                // 1. Initialize the engine
                await pca.initialize();

                // 2. IMPORTANT: Handle the redirect result (this clears the code from the URL)
                const result = await pca.handleRedirectPromise();

                // 3. If we just logged in, set that account as active
                if (result) {
                    pca.setActiveAccount(result.account);
                } else {
                    // If no result, check if we already have an account in session
                    const currentAccounts = pca.getAllAccounts();
                    if (currentAccounts.length > 0) {
                        pca.setActiveAccount(currentAccounts[0]);
                    }
                }

                setIsInitialized(true);
            } catch (error) {
                console.error("MSAL initialization failed:", error);
            }
        };

        initializeMsal();
    }, []);

    // 4. Do NOT render the Provider or any MSAL hooks until isInitialized is true
    if (!isInitialized) {
        return (
            <div className="flex items-center justify-center min-h-screen">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
                <span className="ml-3 text-gray-600">Verifying session...</span>
            </div>
        );
    }

    return (
        <MsalProvider instance={pca}>
            <AuthenticatedTemplate>
                <NavBar />
                <CartManager />
            </AuthenticatedTemplate>
            <UnauthenticatedTemplate>
                <LoginPage />
            </UnauthenticatedTemplate>
        </MsalProvider>
    );
}
// --- CartManager Component ---
function CartManager() {
    const { instance, accounts } = useMsal();
    const [itemId, setItemId] = useState("");
    const [cart, setCart] = useState(null);
    const [message, setMessage] = useState("");
    const [loading, setLoading] = useState(false);

    const userAccount = accounts[0];
    const userId = userAccount?.localAccountId || "Unknown";
    const APIM_URL = `${import.meta.env.VITE_APIM_BASE_URL}/cart`;

    const getAccessToken = async () => {
        const response = await instance.acquireTokenSilent({
            ...loginRequest,
            account: userAccount
        });
        return response.accessToken;
    };

    const callApi = async (method, body = null) => {
        setLoading(true);
        try {
            const token = await getAccessToken();
            const response = await fetch(`${APIM_URL}?userId=${userId}`, {
                method: method,
                headers: {
                    "Authorization": `Bearer ${token}`,
                    "Content-Type": "application/json"
                },
                body: body ? JSON.stringify(body) : null
            });
            const data = await response.json();
            if (method === "GET") {
                setCart(data);
                setMessage("Cart loaded.");
            } else {
                setCart(data.cart);
                setMessage("Operation successful.");
            }
        } catch (err) {
            setMessage(`Error: ${err.message}`);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="p-6 max-w-2xl mx-auto bg-white rounded-xl shadow mt-10 space-y-4">
            <h2 className="text-2xl font-bold">Azure Cart</h2>
            <p className="text-xs bg-gray-50 p-2 rounded">User ID: {userId}</p>
            <div className="flex space-x-2">
                <input
                    type="text"
                    className="border p-2 w-full rounded"
                    placeholder="Product ID"
                    value={itemId}
                    onChange={(e) => setItemId(e.target.value)}
                />
                <button onClick={() => callApi("POST", { itemId })} className="bg-blue-600 text-white px-4 py-2 rounded">Add</button>
            </div>
            <button onClick={() => callApi("GET")} className="w-full bg-gray-100 py-2 rounded">Refresh Cart</button>
            {message && <p className="p-2 text-sm bg-blue-50 text-blue-700">{message}</p>}
            {cart && (
                <ul className="divide-y">
                    {cart.items.map((item, i) => (
                        <li key={i} className="py-2 flex justify-between">
                            <span>Product {item.itemId}</span>
                            <button onClick={() => callApi("DELETE", { itemId: item.itemId })} className="text-red-500">Remove</button>
                        </li>
                    ))}
                </ul>
            )}
        </div>
    );
}



function NavBar() {
    const { instance, accounts } = useMsal();
    return (
        <nav className="bg-white shadow p-4 flex justify-between max-w-4xl mx-auto">
            <span>{accounts[0]?.username}</span>
            <button onClick={() => instance.logoutRedirect()} className="text-red-500">Sign Out</button>
        </nav>
    );
}

function LoginPage() {
    const { instance } = useMsal();
    return (
        <div className="flex items-center justify-center min-h-screen">
            <button
                onClick={() => instance.loginRedirect(loginRequest)}
                className="bg-blue-600 text-white px-8 py-4 rounded-xl font-bold"
            >
                Sign in with Microsoft Entra
            </button>
        </div>
    );
}