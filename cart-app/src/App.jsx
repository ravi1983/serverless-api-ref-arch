import { useState } from 'react';
import './App.css';

function App() {
    const [itemId, setItemId] = useState('');
    const [cart, setCart] = useState(null);
    const [message, setMessage] = useState('');

    const API_URL = "YOUR_API_GATEWAY_URL/cart";

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
            await fetch(API_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ item_id: itemId })
            });
            setMessage(`Item ${itemId} added!`);
            setItemId('');
        } catch (err) {
            setMessage('Error adding item.');
        }
    };

    // 3. DELETE: Remove Item
    const removeItem = async () => {
        try {
            await fetch(API_URL, {
                method: 'DELETE',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ item_id: itemId })
            });
            setMessage(`Item ${itemId} removed!`);
            setItemId('');
        } catch (err) {
            setMessage('Error removing item.');
        }
    };

    return (
        <div className="App">
            <h1>Serverless Cart Service</h1>

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
                    <h3>Your Items:</h3>
                    <pre>{JSON.stringify(cart, null, 2)}</pre>
                </div>
            )}
        </div>
    );
}

export default App;