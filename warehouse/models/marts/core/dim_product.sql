with snapshot as (
    select * from {{ ref('snp_products') }}
)

select
    -- surrogate key provided by snapshot is usually dbt_scd_id, but we can generate an integer one or use the hash
    dbt_scd_id as product_key,
    product_id,
    product_name,
    category,
    unit_price,
    dbt_valid_from,
    dbt_valid_to,
    case when dbt_valid_to is null then true else false end as is_current
from snapshot
