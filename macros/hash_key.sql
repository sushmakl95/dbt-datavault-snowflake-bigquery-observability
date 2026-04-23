{#
  hash_key: returns a deterministic MD5 hash over one or more business-key columns.

  - NULL-safe via coalesce to '^^' sentinel (Data Vault 2.0 convention).
  - Uppercases and trims each input for case-insensitive hub keys.
  - Works on DuckDB, Postgres, BigQuery, Snowflake (all support md5()).
#}

{% macro hash_key(cols) %}
    {%- if cols is string -%}
        {% set cols = [cols] %}
    {%- endif -%}

    {%- set parts = [] -%}
    {%- for c in cols -%}
        {%- do parts.append("coalesce(upper(trim(cast(" ~ c ~ " as varchar))), '^^')") -%}
    {%- endfor -%}

    md5(
        {{ parts | join(" || '||' || ") }}
    )
{% endmacro %}
