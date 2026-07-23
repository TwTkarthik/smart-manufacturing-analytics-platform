with movements as (
    select * from {{ source('smap_silver', 'material_movements') }}
),

dim_product as (
    select product_key, product_id from {{ ref('dim_product') }} where is_current = true
)

select
    mv.movement_id,
    cast(to_char(mv.movement_time, 'YYYYMMDD') as int) as date_key,
    p.product_key,
    -- We assume the operational system has a supplier ID or similar; if not, we map it as unknown.
    -- (The synthetic data didn't strictly list a supplier_id in material movements, so mapping to mock for schema compliance)
    -1 as supplier_key,
    mv.movement_type,
    mv.quantity
from movements mv
left join dim_product p on mv.product_id = p.product_id
