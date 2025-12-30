CREATE TABLE products (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    description TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL
);

INSERT INTO products (description, price) VALUES
    ('Wireless Mouse', 25.99),
    ('Mechanical Keyboard', 75.50),
    ('USB-C Hub', 42.00),
    ('27-inch Monitor', 299.99),
    ('Noise Cancelling Headphones', 199.00);