# Contributing

## Dev setup

```bash
python -m venv .venv && source .venv/Scripts/activate
pip install -r requirements-dev.txt
dbt deps --profiles-dir profiles
```

## Before pushing

```bash
make ci
```

which runs the exact same sequence GitHub Actions runs: lint, `dbt deps`, `dbt build --target ci` (DuckDB).

## Adding a new hub

1. Add `models/raw_vault/hubs/hub_<entity>.sql` using `{{ hash_key(['<bkey>']) }}` and `{{ hash_diff(['<cols>']) }}` macros.
2. Document the hub in `models/raw_vault/schema.yml`.
3. Add seed data if the entity doesn't yet have one in `seeds/`.
4. Run `dbt build --select hub_<entity>` — tests must pass.

## Commit style

Conventional commits: `feat(models): …`, `fix(dq): …`, `docs: …`, `ci: …`, etc.
