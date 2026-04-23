{% test not_null_hash_diff(model, column_name) %}

select *
from {{ model }}
where {{ column_name }} is null

{% endtest %}
