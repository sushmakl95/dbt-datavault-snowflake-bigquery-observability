"""Generate realistic multi-table seed fixtures (customers, orders, products, order-lines).

Uses PySpark in local mode; outputs CSVs compatible with dbt seed. Designed for
developers who want larger-than-committed fixture sets for performance testing.

Run:
    pip install pyspark==3.5.1
    python spark/generate_seeds.py --rows 100000 --out seeds/
"""

from __future__ import annotations

import argparse
import random
from datetime import datetime, timedelta
from pathlib import Path


def _argparse() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--rows", type=int, default=10_000)
    p.add_argument("--out", type=Path, default=Path("seeds"))
    p.add_argument("--seed", type=int, default=42)
    return p.parse_args()


COUNTRIES = ["US", "GB", "IN", "DE", "FR"]
CURRENCIES = {"US": "USD", "GB": "GBP", "IN": "INR", "DE": "EUR", "FR": "EUR"}
TIERS = ["gold", "silver", "bronze"]
STATUSES = ["PLACED", "SHIPPED", "DELIVERED", "CANCELLED"]
CATEGORIES = ["electronics", "apparel", "fitness", "home", "books", "stationery"]


def _gen_customers(n: int, rng: random.Random) -> list[dict]:
    out = []
    start = datetime(2024, 1, 1)
    for i in range(n):
        country = rng.choice(COUNTRIES)
        out.append(
            {
                "customer_id": f"c-{i:06d}",
                "email": f"user{i}@example.com",
                "first_name": f"First{i}",
                "last_name": f"Last{i}",
                "country": country,
                "signup_ts": (start + timedelta(days=rng.randint(0, 800))).isoformat(sep=" "),
                "tier": rng.choice(TIERS),
            }
        )
    return out


def _gen_products(n: int, rng: random.Random) -> list[dict]:
    return [
        {
            "product_id": f"p-{i}",
            "sku": f"SKU-{i:04d}",
            "name": f"Product {i}",
            "category": rng.choice(CATEGORIES),
            "unit_price": round(rng.uniform(5, 499), 2),
            "active": rng.random() > 0.05,
        }
        for i in range(1, n + 1)
    ]


def _gen_orders(n: int, customer_ids: list[str], rng: random.Random) -> list[dict]:
    start = datetime(2026, 1, 1)
    out = []
    for i in range(n):
        cid = rng.choice(customer_ids)
        country = rng.choice(COUNTRIES)
        out.append(
            {
                "order_id": f"o-{i + 10000}",
                "customer_id": cid,
                "placed_at": (start + timedelta(minutes=rng.randint(0, 365 * 24 * 60))).isoformat(
                    sep=" "
                ),
                "country": country,
                "currency": CURRENCIES[country],
                "total": round(rng.uniform(5, 5000), 2),
                "status": rng.choice(STATUSES),
            }
        )
    return out


def _gen_lines(orders: list[dict], products: list[dict], rng: random.Random) -> list[dict]:
    lines: list[dict] = []
    for o in orders:
        for _ in range(rng.randint(1, 4)):
            p = rng.choice(products)
            lines.append(
                {
                    "order_id": o["order_id"],
                    "product_id": p["product_id"],
                    "qty": rng.randint(1, 5),
                    "unit_price": p["unit_price"],
                }
            )
    return lines


def _write_csv(rows: list[dict], path: Path) -> None:
    import csv

    if not rows:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)


def main() -> None:
    args = _argparse()
    rng = random.Random(args.seed)

    customers = _gen_customers(max(100, args.rows // 100), rng)
    products = _gen_products(max(20, args.rows // 500), rng)
    orders = _gen_orders(args.rows, [c["customer_id"] for c in customers], rng)
    lines = _gen_lines(orders, products, rng)

    _write_csv(customers, args.out / "seed_raw_customers.csv")
    _write_csv(products, args.out / "seed_raw_products.csv")
    _write_csv(orders, args.out / "seed_raw_orders.csv")
    _write_csv(lines, args.out / "seed_raw_order_lines.csv")

    print(
        f"Wrote customers={len(customers)} products={len(products)} "
        f"orders={len(orders)} lines={len(lines)} to {args.out}/"
    )


if __name__ == "__main__":
    main()
