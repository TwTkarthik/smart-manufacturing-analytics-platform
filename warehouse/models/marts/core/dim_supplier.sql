-- We mock a supplier dimension since the operational DB doesn't track it explicitly yet.

select
    1 as supplier_key,
    'SUPP-9001' as supplier_id,
    'MetalWorks Primary' as supplier_name,
    'Raw Materials' as supplier_category
union all
select
    2 as supplier_key,
    'SUPP-9002' as supplier_id,
    'Precision Electronics' as supplier_name,
    'Components' as supplier_category
union all
select
    -1 as supplier_key,
    'UNKNOWN' as supplier_id,
    'Unknown Supplier' as supplier_name,
    'Unknown' as supplier_category
