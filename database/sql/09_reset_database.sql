-- =============================================================================
-- 09_reset_database.sql
-- SMAP Operational Database — Development Reset Script
--
-- WARNING: DESTRUCTIVE. Drops all SMAP tables and re-seeds static data.
-- FOR DEVELOPMENT AND TESTING ENVIRONMENTS ONLY.
-- NEVER run against a production database.
-- =============================================================================

-- Guard: abort immediately if not in a known dev database
DO $$
BEGIN
    IF current_database() NOT IN ('smap_source', 'smap_dev', 'smap_test') THEN
        RAISE EXCEPTION
            'ABORT: reset_database.sql may only run against smap_source, smap_dev, or smap_test. '
            'Current database: %', current_database();
    END IF;
END
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 1: Drop all views (to avoid dependency errors)
-- ─────────────────────────────────────────────────────────────────────────────
DROP VIEW IF EXISTS v_pm_compliance_status        CASCADE;
DROP VIEW IF EXISTS v_quality_defect_summary      CASCADE;
DROP VIEW IF EXISTS v_sensor_anomaly_alerts       CASCADE;
DROP VIEW IF EXISTS v_machine_downtime_summary    CASCADE;
DROP VIEW IF EXISTS v_active_production_orders    CASCADE;

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 2: Drop all tables in reverse dependency order
-- ─────────────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS material_movements     CASCADE;
DROP TABLE IF EXISTS maintenance_logs       CASCADE;
DROP TABLE IF EXISTS pm_schedules           CASCADE;
DROP TABLE IF EXISTS quality_inspections    CASCADE;
DROP TABLE IF EXISTS sensor_readings        CASCADE;
DROP TABLE IF EXISTS downtime_events        CASCADE;
DROP TABLE IF EXISTS production_orders      CASCADE;
DROP TABLE IF EXISTS spare_parts            CASCADE;
DROP TABLE IF EXISTS defect_types           CASCADE;
DROP TABLE IF EXISTS employees              CASCADE;
DROP TABLE IF EXISTS products               CASCADE;
DROP TABLE IF EXISTS machines               CASCADE;
DROP TABLE IF EXISTS shifts                 CASCADE;
DROP TABLE IF EXISTS production_lines       CASCADE;

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 3: Drop trigger function
-- ─────────────────────────────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS trg_set_updated_at() CASCADE;

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 4: Re-create everything
-- ─────────────────────────────────────────────────────────────────────────────
\i 01_extensions.sql
\i 02_roles.sql
\i 03_schema.sql
\i 04_tables.sql
\i 05_constraints.sql
\i 06_indexes.sql
\i 07_views.sql
\i 08_seed.sql

-- ─────────────────────────────────────────────────────────────────────────────
-- Step 5: Verification summary
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) AS size,
    (SELECT COUNT(*) FROM information_schema.columns
     WHERE table_schema = schemaname AND table_name = tablename) AS column_count
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

DO $$
BEGIN
    RAISE NOTICE 'SMAP database reset complete. All tables re-created and seeded.';
END
$$;
