import { useState } from 'react';
import './App.css';

function App() {
    const [itemId, setItemId] = useState('');
    const [cart, setCart] = useState(null);
    const [message, setMessage] = useState('');

    // Hardcoded UserID for all requests
    const USER_ID = "123456";
    const BASE_URL = "https://4pbp0anjc3.execute-api.us-east-2.amazonaws.com/cart";

    // Construct the URL with the query parameter
    const API_URL = `${BASE_URL}?userId=${USER_ID}`;

    // 1. GET: View Cart
    const viewCart = async () => {
        try {
            const response = await fetch(API_URL);
            const data = await response.json();
            setCart(data);
            setMessage('Cart loaded successfully.');
        } catch (err) {
            setMessage('Error viewing cart.');
        }
    };

    // 2. POST: Add Item
    const addItem = async () => {
        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ itemId })
            });
            const data = await response.json();

            // Update the cart state with the new list returned from Lambda
            setCart(data.cart);
            setMessage(`Added item ${itemId}`);
            setItemId('');
        } catch (err) {
            setMessage('Error adding item.');
        }
    };

    // 3. DELETE: Remove Item
    const removeItem = async () => {
        try {
            const response = await fetch(API_URL, {
                method: 'DELETE',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ itemId })
            });
            const data = await response.json();

            // Update the cart state with the new list returned from Lambda
            setCart(data.cart);
            setMessage(`Removed item ${itemId}`);
            setItemId('');
        } catch (err) {
            setMessage('Error removing item.');
        }
    };

    return (
        <div className="App">
            <h1>Serverless Cart Service</h1>
            <p>Acting as User: <strong>{USER_ID}</strong></p>

            <div className="card">
                <input
                    type="text"
                    placeholder="Enter Item ID"
                    value={itemId}
                    onChange={(e) => setItemId(e.target.value)}
                />
                <br />
                <button onClick={addItem}>Add to Cart</button>
                <button onClick={removeItem}>Remove from Cart</button>
                <button onClick={viewCart} style={{ backgroundColor: '#646cff' }}>
                    View Cart Contents
                </button>
            </div>

            {message && <p className="status-msg">{message}</p>}

            {cart && (
                <div className="cart-display">
                    <h3>Your Items ({cart.itemCount || 0}):</h3>
                    <pre>{JSON.stringify(cart.items, null, 2)}</pre>
                </div>
            )}
        </div>
    );
}

export default App;