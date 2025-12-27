import {addItemToCart, getCart, removeFromCart} from "./cart_actions/cart_actions";

export const handler = async (event) => {
    const method = event.requestContext.http.method; // Or event.httpMethod for REST API
    const userId = event.queryStringParameters?.userId;
    const body = event.body ? JSON.parse(event.body) : {};

    try {
        let result;
        switch (method) {
            case 'POST':
                result = await addItemToCart(userId, body.itemId);
                break;
            case 'GET':
                result = await getCart(userId);
                break;
            case 'DELETE':
                result = await removeFromCart(userId, body.itemId);
                break;
            default:
                return { statusCode: 405, body: "Method Not Allowed" };
        }

        return {
            statusCode: 200,
            headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            body: JSON.stringify(result)
        };
    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message })
        };
    }
};