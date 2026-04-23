{#
  Emits a load_datetime expression suitable for the current adapter.
  Overridable via the `snapshot_timestamp` project var.
#}

{% macro load_datetime() %}
    {{ var('snapshot_timestamp', 'current_timestamp') }}
{% endmacro %}

{% macro record_source(override=none) %}
    '{{ override if override is not none else var('record_source_default', 'dbt_seed') }}'
{% endmacro %}
