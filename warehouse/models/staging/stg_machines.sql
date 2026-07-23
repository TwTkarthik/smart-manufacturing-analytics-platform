with source as (
    select * from {{ source('smap_silver', 'machines') }}
),

staged as (
    select
        machine_id,
        machine_name,
        machine_type_code,
        line_code,
        is_active,
        created_at,
        updated_at
    from source
)

select * from staged
