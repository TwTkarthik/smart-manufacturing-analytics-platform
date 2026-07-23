select
    to_char(t, 'HH24MI')::int as time_key,
    t::time as full_time,
    extract(hour from t) as hour,
    extract(minute from t) as minute
from generate_series(
    '2000-01-01 00:00:00'::timestamp,
    '2000-01-01 23:59:00'::timestamp,
    '1 minute'::interval
) t
