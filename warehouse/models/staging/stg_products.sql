with source as (
    select * from {{ source('smap_silver', 'products') }}
),

staged as (
    select
        product_id,
        product_name,
        category,
        unit_price,
        created_at,
        updated_at
    from source
)

select * from staged
