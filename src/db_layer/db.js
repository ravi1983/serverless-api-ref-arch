import pkg from 'pg';
const { Client } = pkg;
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";

// PostgreSQL Client Setup
export const getPsqlClient = async () => {
    const client = new Client({
        connectionString: process.env.DATABASE_URL, // e.g., postgres://user:password@host:5432/dbname
        ssl: { rejectUnauthorized: false }
    });
    await client.connect();
    return client;
};

// DynamoDB Document Client Setup (handles JSON mapping)
const ddbClient = new DynamoDBClient({});
export const docClient = DynamoDBDocumentClient.from(ddbClient);

export const CART_TABLE = process.env.CART_TABLE_NAME || "UserCarts";