with maintenance as (
    select * from {{ source('smap_silver', 'maintenance_logs') }}
),

dim_machine as (
    select machine_key, machine_id from {{ ref('dim_machine') }}
),

dim_employee as (
    select employee_key, employee_id from {{ ref('dim_employee') }} where is_current = true
)

select
    ml.log_id,
    cast(to_char(ml.maintenance_start, 'YYYYMMDD') as int) as date_key,
    m.machine_key,
    e.employee_key as technician_key,
    ml.downtime_minutes,
    ml.maintenance_type,
    ml.parts_cost
from maintenance ml
left join dim_machine m on ml.machine_id = m.machine_id
left join dim_employee e on ml.technician_id = e.employee_id
