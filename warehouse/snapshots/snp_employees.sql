{% snapshot snp_employees %}

{{
    config(
      target_schema='snapshots',
      unique_key='employee_id',
      strategy='timestamp',
      updated_at='updated_at'
    )
}}

select * from {{ ref('stg_employees') }}

{% endsnapshot %}
