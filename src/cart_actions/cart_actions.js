import { getPsqlClient, docClient, CART_TABLE } from '/opt/nodejs/db.js';
import { PutCommand, QueryCommand, DeleteCommand } from "@aws-sdk/lib-dynamodb";

export const addItemToCart = async (userId, itemId) => {
    const psql = await getPsqlClient();
    try {
        // 1. Lookup item in RDS Postgres to ensure it's valid and get current price
        const res = await psql.query('SELECT id, description, price FROM products WHERE id = $1', [itemId]);
        if (res.rows.length === 0) throw new Error("Item not found in catalog");

        // 2. Add specific item to the user's collection in DynamoDB
        const product = res.rows[0];
        const ttl = Math.floor(Date.now() / 1000) + 3600; // 1 hour expiry
        const params = {
            TableName: CART_TABLE,
            Item: {
                userId,          // Partition Key (Hash)
                itemId,          // Sort Key (Range)
                description: product.description,
                price: product.price,
                ttl: ttl
            }
        };

        await docClient.send(new PutCommand(params));
        return { success: true, addedItem: params.Item };
    } finally {
        await psql.end();
    }
};

export const getCart = async (userId) => {
    const params = {
        TableName: CART_TABLE,
        KeyConditionExpression: "userId = :uid",
        ExpressionAttributeValues: {
            ":uid": userId
        }
    };

    // Use QueryCommand instead of GetCommand to fetch multiple rows for one PK
    const result = await docClient.send(new QueryCommand(params));
    return {
        userId,
        items: result.Items,
        itemCount: result.Count
    };
};

export const removeFromCart = async (userId, itemId) => {
    const params = {
        TableName: CART_TABLE,
        Key: {
            userId,
            itemId
        }
    };
    await docClient.send(new DeleteCommand(params));
    return { success: true, removedItemId: itemId };
};