with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2020-01-01' as date)",
        end_date="cast('2030-01-01' as date)"
    )
    }} if dbt_utils is available, but for simplicity without external packages, we can use a raw SQL generator for Postgres:
    -- We'll use a Postgres generate_series fallback since we didn't specify dbt_utils in packages.yml
)

select
    to_char(d, 'YYYYMMDD')::int as date_key,
    d::date as full_date,
    extract(year from d) as year,
    extract(quarter from d) as quarter,
    extract(month from d) as month,
    extract(day from d) as day_of_month,
    extract(isodow from d) as day_of_week,
    case when extract(isodow from d) in (6, 7) then true else false end as is_weekend
from generate_series(
    '2020-01-01'::timestamp,
    '2030-01-01'::timestamp,
    '1 day'::interval
) d
