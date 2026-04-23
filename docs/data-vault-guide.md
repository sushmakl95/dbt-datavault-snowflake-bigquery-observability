# Data Vault 2.0 Modelling Guide

This project implements the Raw Vault + Business Vault pattern from the Data Vault 2.0 standard ([Linstedt & Olschimke, 2015](https://amzn.eu/d/dataVault)).

## Terminology recap

| Term | Meaning | Example in this repo |
|---|---|---|
| **Hub** | Unique list of business keys for a concept | `hub_customer` — one row per `customer_id` |
| **Link** | Association between two or more hubs | `link_order_customer` |
| **Satellite** | Descriptive / contextual attributes of a hub or link, tracked over time | `sat_customer_details` |
| **Hash Key (`hk_*`)** | Deterministic MD5 over business keys | `md5(coalesce(upper(trim(customer_id)),'^^'))` |
| **Hash Diff (`hd_*`)** | Deterministic MD5 over descriptive attributes — used to detect change | — |
| **PIT** | Point-in-time table — precomputed join from hub to the latest satellite row | `pit_customer` |
| **Bridge** | Multi-way denormalised join used for performance | `bridge_order_lines` |

## Why Raw Vault / Business Vault?

- **Raw Vault** is a lossless, history-preserving landing layer: inserts only, never updates. Auditable.
- **Business Vault** adds consumer-friendly derived structures (PITs, bridges, business rules) while leaving Raw Vault untouched.
- **Marts** reshape the Business Vault into dimensional grain for BI consumption.

## How change detection works here

Every staging row computes a `hash_diff` (MD5 over sorted descriptive columns). Satellites insert a new row whenever the `hash_diff` for a hub key differs from the most recent satellite row. This gives you a full SCD Type-2 history without a vendor package.

Pseudocode from `sat_customer_details.sql`:

```sql
changed as (
    select s.*
    from stage s
    left join latest l on s.hk_customer = l.hk_customer
    where l.hd_customer_details is null
       or s.hd_customer_details <> l.hd_customer_details
)
```

## Naming conventions used

| Prefix | Meaning |
|---|---|
| `stg_` | staging view |
| `hub_` | hub table |
| `link_` | link table |
| `sat_` | satellite table |
| `pit_` | point-in-time table |
| `bridge_` | bridge table |
| `fct_` | fact table (marts) |
| `dim_` | dimension table (marts) |

## Further reading

- Dan Linstedt's book "Building a Scalable Data Warehouse with Data Vault 2.0"
- AutomateDV docs — good reference even if we don't use the package here
