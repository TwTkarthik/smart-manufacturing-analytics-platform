{{ config(
    materialized='incremental',
    unique_key='reading_id'
) }}

with telemetry as (
    select * from {{ source('smap_silver', 'sensor_readings') }}
    {% if is_incremental() %}
    where reading_timestamp > (select max(reading_timestamp) from {{ this }})
    {% endif %}
),

dim_machine as (
    select machine_key, machine_id from {{ ref('dim_machine') }}
)

select
    t.reading_id,
    cast(to_char(t.reading_timestamp, 'YYYYMMDD') as int) as date_key,
    cast(to_char(t.reading_timestamp, 'HH24MI') as int) as time_key,
    m.machine_key,
    t.sensor_type,
    t.value as reading_value,
    t.reading_timestamp
from telemetry t
left join dim_machine m on t.machine_id = m.machine_id
