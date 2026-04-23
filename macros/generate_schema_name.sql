{#
  Environment-aware schema naming:
    - CI (DuckDB): flatten into `main_<layer>` so single-file DuckDB works without cross-schema refs.
    - Non-CI: use standard `{target_schema}_{custom_schema_name}` concat.
#}

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if target.name == 'ci' and custom_schema_name is not none -%}
        main_{{ custom_schema_name | trim }}
    {%- elif custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
