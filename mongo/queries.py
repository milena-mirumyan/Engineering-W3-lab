from pymongo import MongoClient
from pprint import pprint
import time

client = MongoClient("mongodb://itc6050:itc6050@localhost:27017/?authSource=admin")
db = client["shop_lab"]

def timed(label, func):
    t = time.time()
    result = list(func())
    print(f"{label:35s} {(time.time() - t) * 1000:7.1f} ms")
    return result

# ──────────────────────────────────────────────
# Q1: Monthly revenue trend
# ──────────────────────────────────────────────
print("\n--- Q1: Monthly revenue ---")
q1 = timed("Q1 monthly revenue", lambda: db.orders.aggregate([
    {"$group": {
        "_id": {
            "year":  {"$year":  "$order_date"},
            "month": {"$month": "$order_date"},
        },
        "orders":  {"$sum": 1},
        "revenue": {"$sum": "$total"},
    }},
    {"$sort": {"_id.year": 1, "_id.month": 1}},
]))
for row in q1[:3]:
    pprint(row)

# ──────────────────────────────────────────────
# Q2: Top 10 products by revenue
# ──────────────────────────────────────────────
print("\n--- Q2: Top 10 products ---")
q2 = timed("Q2 top products", lambda: db.orders_embedded.aggregate([
    {"$unwind": "$items"},
    {"$group": {
        "_id": "$items.product_id",
        "total_qty": {"$sum": "$items.quantity"},
        "revenue":   {"$sum": {"$multiply": ["$items.quantity", "$items.unit_price_at_sale"]}},
    }},
    {"$sort": {"revenue": -1}},
    {"$limit": 10},
]))
for row in q2[:3]:
    pprint(row)

# ──────────────────────────────────────────────
# Q3: Order count + avg + median by status
# ──────────────────────────────────────────────
print("\n--- Q3: Order stats by status ---")
q3 = timed("Q3 status stats", lambda: db.orders.aggregate([
    {"$group": {
        "_id":         "$status",
        "order_count": {"$sum": 1},
        "avg_total":   {"$avg": "$total"},
        "median_total":{"$median": {"input": "$total", "method": "approximate"}},
    }},
    {"$sort": {"order_count": -1}},
]))
for row in q3:
    pprint(row)

# ──────────────────────────────────────────────
# Q4: Dormant customers (no order in 90 days)
# ──────────────────────────────────────────────
print("\n--- Q4: Dormant customers ---")
from datetime import datetime, timedelta, timezone
cutoff = datetime.now(timezone.utc) - timedelta(days=90)

q4 = timed("Q4 dormant customers", lambda: db.orders.aggregate([
    {"$group": {
        "_id":            "$customer_id",
        "last_order_date": {"$max": "$order_date"},
    }},
    {"$match": {
        "last_order_date": {"$lt": cutoff}
    }},
    {"$lookup": {
        "from":         "customer",
        "localField":   "_id",
        "foreignField": "customer_id",
        "as":           "cust_info",
    }},
    {"$unwind": "$cust_info"},
    {"$project": {
        "email":           "$cust_info.email",
        "last_order_date": 1,
        "days_dormant": {
            "$dateDiff": {
                "startDate": "$last_order_date",
                "endDate":   "$$NOW",
                "unit":      "day",
            }
        },
    }},
    {"$sort": {"days_dormant": -1}},
    {"$limit": 10},
]))
for row in q4[:3]:
    pprint(row)

# ──────────────────────────────────────────────
# Q5: Top 20 customers by lifetime spend + rank + gap
# ──────────────────────────────────────────────
print("\n--- Q5: Top 20 customers by lifetime spend ---")
q5 = timed("Q5 top customers", lambda: db.orders.aggregate([
    {"$group": {
        "_id":          "$customer_id",
        "lifetime_spend": {"$sum": "$total"},
    }},
    {"$sort": {"lifetime_spend": -1}},
    {"$limit": 20},
    {"$lookup": {
        "from":         "customer",
        "localField":   "_id",
        "foreignField": "customer_id",
        "as":           "cust_info",
    }},
    {"$unwind": "$cust_info"},
    {"$setWindowFields": {
        "sortBy": {"lifetime_spend": -1},
        "output": {
            "rank": {
                "$rank": {}
            },
            "gap_to_previous": {
                "$shift": {
                    "output":   "$lifetime_spend",
                    "by":       -1,
                    "default":  None,
                }
            },
        },
    }},
    {"$project": {
        "rank":           1,
        "email":          "$cust_info.email",
        "lifetime_spend": 1,
        "gap_to_previous": {
            "$subtract": [
                {"$ifNull": ["$gap_to_previous", "$lifetime_spend"]},
                "$lifetime_spend"
            ]
        },
    }},
]))
for row in q5[:3]:
    pprint(row)

print("\nAll queries done!")
