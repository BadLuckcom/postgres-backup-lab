CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    salary NUMERIC(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO employees (full_name, department, salary)
SELECT
    'Employee ' || i,
    CASE
        WHEN i % 3 = 0 THEN 'IT'
        WHEN i % 3 = 1 THEN 'Production'
        ELSE 'Finance'
    END,
    3000000 + (i * 10000)
FROM generate_series(1, 100) AS i;


CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    quantity INTEGER NOT NULL
);

INSERT INTO products (product_name, quantity)
VALUES
    ('Spring A', 500),
    ('Spring B', 750),
    ('Metal Part C', 300),
    ('Rubber Hose D', 1000),
    ('Filter E', 250);
