with inspections as (
    select * from {{ source('smap_silver', 'quality_inspections') }}
),

dim_machine as (
    select machine_key, machine_id from {{ ref('dim_machine') }}
),

dim_product as (
    select product_key, product_id from {{ ref('dim_product') }} where is_current = true
),

dim_employee as (
    select employee_key, employee_id from {{ ref('dim_employee') }} where is_current = true
)

select
    i.inspection_id,
    cast(to_char(i.inspection_time, 'YYYYMMDD') as int) as date_key,
    m.machine_key,
    p.product_key,
    e.employee_key as inspector_key,
    i.defect_type_code,
    i.inspection_passed
from inspections i
left join dim_machine m on i.machine_id = m.machine_id
left join dim_product p on i.product_id = p.product_id
left join dim_employee e on i.inspector_id = e.employee_id
