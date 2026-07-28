#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""이커머스 합성 데이터 (pandas) — Iceberg Lab 적재용 Parquet."""
import argparse
import sys
from pathlib import Path

if sys.version_info < (3, 8):
    sys.exit(
        "Python 3.8+ 가 필요합니다 (현재: {}.{})".format(
            sys.version_info[0], sys.version_info[1]
        )
        + ". edge에서 python3 generators/generate_ecommerce_data.py 로 실행하세요."
    )

import numpy as np
import pandas as pd


def main():
    parser = argparse.ArgumentParser(description="합성 ecommerce Parquet 생성")
    parser.add_argument("--rows-customers", type=int, default=1000)
    parser.add_argument("--rows-products", type=int, default=200)
    parser.add_argument("--rows-orders", type=int, default=5000)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "samples",
    )
    args = parser.parse_args()
    rng = np.random.default_rng(args.seed)
    args.out_dir.mkdir(parents=True, exist_ok=True)

    countries = ["KR", "US", "JP", "DE", "FR"]
    genders = ["M", "F", "O"]
    categories = ["Electronics", "Clothing", "Food", "Books", "Home"]
    statuses = ["PENDING", "SHIPPED", "DELIVERED", "CANCELLED"]

    customers = pd.DataFrame(
        {
            "customer_id": np.arange(1, args.rows_customers + 1),
            "name": [f"user_{i}" for i in range(1, args.rows_customers + 1)],
            "email": [f"user_{i}@example.com" for i in range(1, args.rows_customers + 1)],
            "registration_date": pd.to_datetime("2020-01-01")
            + pd.to_timedelta(rng.integers(0, 365 * 3, args.rows_customers), unit="D"),
            "country": rng.choice(countries, args.rows_customers),
            "age": rng.integers(18, 81, args.rows_customers),
            "gender": rng.choice(genders, args.rows_customers),
            "vip_status": rng.choice([True, False], args.rows_customers),
        }
    )

    products = pd.DataFrame(
        {
            "product_id": np.arange(1, args.rows_products + 1),
            "product_name": [f"product_{i}" for i in range(1, args.rows_products + 1)],
            "category": rng.choice(categories, args.rows_products),
            "price": rng.uniform(10, 1000, args.rows_products).round(2),
            "stock_quantity": rng.integers(0, 500, args.rows_products),
            "supplier_id": rng.integers(1, 50, args.rows_products),
        }
    )

    order_dates = pd.Series(
        pd.to_datetime("2020-01-01")
        + pd.to_timedelta(rng.integers(0, 365 * 6, args.rows_orders), unit="D")
    )
    customer_ids = rng.integers(1, args.rows_customers + 1, args.rows_orders)
    product_ids = rng.integers(1, args.rows_products + 1, args.rows_orders)
    quantities = rng.integers(1, 11, args.rows_orders)
    prices = products.set_index("product_id").loc[product_ids, "price"].values
    total = (prices * quantities * rng.uniform(0.95, 1.05, args.rows_orders)).round(2)

    reg_map = customers.set_index("customer_id")["registration_date"]
    for i, cid in enumerate(customer_ids):
        reg = reg_map[cid]
        if order_dates.iat[i] < reg:
            order_dates.iat[i] = reg + pd.Timedelta(days=1)

    orders = pd.DataFrame(
        {
            "order_id": np.arange(1, args.rows_orders + 1),
            "customer_id": customer_ids,
            "product_id": product_ids,
            "order_date": order_dates,
            "quantity": quantities,
            "total_amount": total,
            "status": rng.choice(statuses, args.rows_orders),
            "shipping_address": [f"addr_{i}" for i in range(1, args.rows_orders + 1)],
        }
    )

    customers.to_parquet(args.out_dir / "customers.parquet", index=False)
    products.to_parquet(args.out_dir / "products.parquet", index=False)
    orders.to_parquet(args.out_dir / "orders.parquet", index=False)
    print(f"Wrote parquet to {args.out_dir}")


if __name__ == "__main__":
    main()
