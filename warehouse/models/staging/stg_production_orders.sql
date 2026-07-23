with source as (
    select * from {{ source('smap_silver', 'production_orders') }}
),

staged as (
    select
        order_id,
        product_id,
        machine_id,
        planned_start,
        planned_end,
        actual_start,
        actual_end,
        planned_units,
        actual_units,
        good_units,
        scrap_units,
        status,
        yield_pct,
        created_at,
        updated_at
    from source
)

select * from staged
