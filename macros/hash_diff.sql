{#
  hash_diff: deterministic MD5 over descriptive columns for satellite change detection.

  - Sorts column list for stable ordering.
  - Coalesces NULLs to '^^'.
  - Strips/uppercases trimmed string representation.
#}

{% macro hash_diff(cols) %}
    {%- set sorted_cols = cols | sort -%}
    {%- set parts = [] -%}
    {%- for c in sorted_cols -%}
        {%- do parts.append("coalesce(cast(" ~ c ~ " as varchar), '^^')") -%}
    {%- endfor -%}

    md5(
        {{ parts | join(" || '||' || ") }}
    )
{% endmacro %}
