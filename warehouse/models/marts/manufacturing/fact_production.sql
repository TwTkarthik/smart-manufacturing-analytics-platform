{{ config(
    materialized='incremental',
    unique_key='order_id'
) }}

with orders as (
    select * from {{ ref('stg_production_orders') }}
    {% if is_incremental() %}
    where updated_at > (select max(updated_at) from {{ this }})
    {% endif %}
),

dim_date as (
    select date_key, full_date from {{ ref('dim_date') }}
),

dim_machine as (
    select machine_key, machine_id from {{ ref('dim_machine') }}
),

dim_product as (
    select product_key, product_id from {{ ref('dim_product') }} where is_current = true
)

select
    o.order_id,
    cast(to_char(o.actual_start, 'YYYYMMDD') as int) as date_key,
    m.machine_key,
    p.product_key,
    o.planned_units,
    o.actual_units,
    o.good_units,
    o.scrap_units,
    o.yield_pct,
    o.updated_at
from orders o
left join dim_machine m on o.machine_id = m.machine_id
left join dim_product p on o.product_id = p.product_id
