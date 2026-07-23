with shifts as (
    select * from {{ source('smap_silver', 'shifts') }}
)

select
    row_number() over (order by shift_code) as shift_key,
    shift_code,
    start_time,
    end_time
from shifts
