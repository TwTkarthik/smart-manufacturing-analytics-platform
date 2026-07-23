with machines as (
    select * from {{ ref('stg_machines') }}
),

lines as (
    -- Assuming a stg_production_lines exists, we can join to it for line names.
    -- If not, we'll just use line_code from machines.
    -- Here we'll just use machines as the grain.
    select * from {{ ref('stg_machines') }}
)

select
    -- surrogate key
    row_number() over (order by machine_id) as machine_key,
    machine_id,
    machine_name,
    machine_type_code,
    line_code,
    is_active
from machines
