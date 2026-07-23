with snapshot as (
    select * from {{ ref('snp_employees') }}
)

select
    dbt_scd_id as employee_key,
    employee_id,
    first_name,
    last_name,
    role,
    shift_code,
    dbt_valid_from,
    dbt_valid_to,
    case when dbt_valid_to is null then true else false end as is_current
from snapshot
