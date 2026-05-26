DROP SCHEMA IF EXISTS shop CASCADE;
CREATE SCHEMA shop;
SET search_path TO shop;

CREATE TABLE customer (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email       VARCHAR(255) NOT NULL UNIQUE,
    first_name  VARCHAR(80)  NOT NULL,
    last_name   VARCHAR(80)  NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE category (
    category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(80)  NOT NULL UNIQUE
);

CREATE TABLE product (
    product_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(120) NOT NULL,
    category_id BIGINT NOT NULL REFERENCES category(category_id),
    unit_price  NUMERIC(10,2) NOT NULL CHECK (unit_price > 0)
);

CREATE TABLE orders (
    order_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customer(customer_id),
    order_date  TIMESTAMPTZ  NOT NULL,
    status      VARCHAR(20)  NOT NULL CHECK (status IN ('new','paid','shipped','delivered','cancelled')),
    total       NUMERIC(12,2) NOT NULL CHECK (total >= 0)
);

CREATE TABLE order_item (
    order_item_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id           BIGINT NOT NULL REFERENCES orders(order_id),
    product_id         BIGINT NOT NULL REFERENCES product(product_id),
    quantity           INT    NOT NULL CHECK (quantity > 0),
    unit_price_at_sale NUMERIC(10,2) NOT NULL CHECK (unit_price_at_sale > 0)
);
