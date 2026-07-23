-- We mock a customer dimension since the operational database doesn't track it explicitly
-- In a real scenario, this would come from a CRM via the ETL pipeline.

select
    1 as customer_key,
    'CUST-1001' as customer_id,
    'Global Auto Parts Inc.' as customer_name,
    'North America' as region
union all
select
    2 as customer_key,
    'CUST-1002' as customer_id,
    'EuroMotors Ltd.' as customer_name,
    'Europe' as region
union all
select
    -1 as customer_key,
    'UNKNOWN' as customer_id,
    'Unknown Customer' as customer_name,
    'Unknown' as region
