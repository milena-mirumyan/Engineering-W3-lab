SET search_path TO shop;

INSERT INTO category (name)
SELECT 'Category ' || g FROM generate_series(1, 50) g;

INSERT INTO product (category_id, name, unit_price)
SELECT
    ((g - 1) % 50) + 1,
    'Product ' || g,
    ROUND((random() * 200 + 5)::numeric, 2)
FROM generate_series(1, 1000) g;

INSERT INTO customer (email, first_name, last_name)
SELECT
    'cust' || g || '@example.com',
    'First' || g,
    'Last' || g
FROM generate_series(1, 10000) g;

INSERT INTO orders (customer_id, order_date, status, total)
SELECT
    ((g - 1) % 10000) + 1,
    NOW() - (random() * INTERVAL '730 days'),
    (ARRAY['new','paid','shipped','delivered','cancelled'])[ceil(random()*5)],
    ROUND((random() * 500 + 10)::numeric, 2)
FROM generate_series(1, 100000) g;

INSERT INTO order_item (order_id, product_id, quantity, unit_price_at_sale)
SELECT
    ((g - 1) % 100000) + 1,
    ((g - 1) % 1000) + 1,
    ceil(random() * 5)::int,
    ROUND((random() * 200 + 5)::numeric, 2)
FROM generate_series(1, 500000) g;

ANALYZE;
