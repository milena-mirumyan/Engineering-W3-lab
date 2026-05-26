-- Q1: Monthly revenue trend
SELECT
    date_trunc('month', order_date) AS month,
    COUNT(*)                        AS orders,
    SUM(total)                      AS revenue
FROM shop.orders
GROUP BY date_trunc('month', order_date)
ORDER BY month;

-- Q2: Top 10 products by revenue
SELECT
    p.name                                        AS product_name,
    SUM(oi.quantity)                              AS total_qty,
    SUM(oi.quantity * oi.unit_price_at_sale)      AS revenue
FROM shop.order_item oi
JOIN shop.product p USING (product_id)
GROUP BY p.name
ORDER BY revenue DESC
LIMIT 10;

-- Q3: Average and median order value by status
SELECT
    status,
    COUNT(*)                                                    AS order_count,
    ROUND(AVG(total), 2)                                        AS avg_total,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total)          AS median_total
FROM shop.orders
GROUP BY status
ORDER BY order_count DESC;

-- Q4: Dormant customers (no order in last 90 days)
SELECT
    c.email,
    MAX(o.order_date)                                           AS last_order_date,
    EXTRACT(DAY FROM NOW() - MAX(o.order_date))::INT            AS days_dormant
FROM shop.customer c
LEFT JOIN shop.orders o USING (customer_id)
GROUP BY c.customer_id, c.email
HAVING MAX(o.order_date) < NOW() - INTERVAL '90 days'
    OR MAX(o.order_date) IS NULL
ORDER BY days_dormant DESC NULLS LAST;

-- Q5: Top 20 customers by lifetime spend with rank and gap
SELECT
    RANK() OVER (ORDER BY SUM(total) DESC)                          AS rank,
    c.email,
    SUM(o.total)                                                    AS lifetime_spend,
    SUM(o.total) - LAG(SUM(o.total)) OVER (ORDER BY SUM(o.total) DESC) AS gap_to_previous
FROM shop.customer c
JOIN shop.orders o USING (customer_id)
GROUP BY c.customer_id, c.email
ORDER BY lifetime_spend DESC
LIMIT 20;
