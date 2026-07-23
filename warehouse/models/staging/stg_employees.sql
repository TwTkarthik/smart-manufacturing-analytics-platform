with source as (
    select * from {{ source('smap_silver', 'employees') }}
),

staged as (
    select
        employee_id,
        first_name,
        last_name,
        role,
        shift_code,
        hire_date,
        is_active,
        created_at,
        updated_at
    from source
)

select * from staged
