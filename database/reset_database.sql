-- =============================================================================
-- reset_database.sql
-- SMAP Operational Database — Development Reset Script
-- PostgreSQL 16 compatible.
--
-- !! WARNING: DESTRUCTIVE OPERATION !!
-- This script drops ALL SMAP tables, views, triggers, and functions and
-- then rebuilds the complete schema from scratch using the numbered scripts.
--
-- FOR DEVELOPMENT AND TESTING ENVIRONMENTS ONLY.
-- NEVER run against a production database.
--
-- Execution: 9 of 9 (utility script — not part of normal deployment sequence)
-- Run as superuser from the database/sql/ directory:
--   psql -d smap_dev -f ../reset_database.sql
-- Or from the database/ directory:
--   psql -d smap_dev -f reset_database.sql
--
-- Canonical numbered source: database/sql/09_reset_database.sql
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- Safety Guard
-- Abort immediately if not connected to a known development database.
-- This prevents accidental execution against production or staging.
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
    IF current_database() NOT IN ('smap_source', 'smap_dev', 'smap_test') THEN
        RAISE EXCEPTION
            E'ABORT: reset_database.sql may only run against: smap_source, smap_dev, or smap_test.\n'
            'Current database: %. Aborting immediately.', current_database();
    END IF;
    RAISE NOTICE 'Safety check passed — connected to: %', current_database();
END
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- Step 1: Drop all views
-- Drop views first to avoid dependency errors when dropping tables.
-- ─────────────────────────────────────────────────────────────────────────────
DO $$ BEGIN RAISE NOTICE 'Step 1/5 — Dropping views...'; END $$;

DROP VIEW IF EXISTS v_pm_compliance_status        CASCADE;
DROP VIEW IF EXISTS v_quality_defect_summary      CASCADE;
DROP VIEW IF EXISTS v_sensor_anomaly_alerts       CASCADE;
DROP VIEW IF EXISTS v_machine_downtime_summary    CASCADE;
DROP VIEW IF EXISTS v_active_production_orders    CASCADE;


-- ─────────────────────────────────────────────────────────────────────────────
-- Step 2: Drop all tables in reverse dependency order
-- CASCADE handles any remaining constraint dependencies.
-- ─────────────────────────────────────────────────────────────────────────────
DO $$ BEGIN RAISE NOTICE 'Step 2/5 — Dropping tables...'; END $$;

-- Domain 5: Maintenance (transaction tables first, catalog last)
DROP TABLE IF EXISTS material_movements     CASCADE;
DROP TABLE IF EXISTS maintenance_logs       CASCADE;
DROP TABLE IF EXISTS pm_schedules           CASCADE;

-- Domain 4: Quality (transaction table, then reference)
DROP TABLE IF EXISTS quality_inspections    CASCADE;
DROP TABLE IF EXISTS defect_types           CASCADE;

-- Domain 3: Sensor Telemetry (parent table drops all partitions automatically)
DROP TABLE IF EXISTS sensor_readings        CASCADE;

-- Domain 2: Production Operations
DROP TABLE IF EXISTS downtime_events        CASCADE;
DROP TABLE IF EXISTS production_orders      CASCADE;

-- Domain 5: Spare parts catalog
DROP TABLE IF EXISTS spare_parts            CASCADE;

-- Domain 1: Reference / Master Data
DROP TABLE IF EXISTS employees              CASCADE;
DROP TABLE IF EXISTS products               CASCADE;
DROP TABLE IF EXISTS machines               CASCADE;
DROP TABLE IF EXISTS shifts                 CASCADE;
DROP TABLE IF EXISTS production_lines       CASCADE;


-- ─────────────────────────────────────────────────────────────────────────────
-- Step 3: Drop trigger function
-- ─────────────────────────────────────────────────────────────────────────────
DO $$ BEGIN RAISE NOTICE 'Step 3/5 — Dropping trigger functions...'; END $$;

DROP FUNCTION IF EXISTS trg_set_updated_at() CASCADE;


-- ─────────────────────────────────────────────────────────────────────────────
-- Step 4: Re-create everything
-- Runs the numbered scripts in the canonical execution order.
-- Paths are relative to the database/sql/ directory — run psql from there.
-- ─────────────────────────────────────────────────────────────────────────────
DO $$ BEGIN RAISE NOTICE 'Step 4/5 — Re-creating schema from numbered scripts...'; END $$;

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
-- Print a summary of all tables and their sizes/column counts.
-- ─────────────────────────────────────────────────────────────────────────────
DO $$ BEGIN RAISE NOTICE 'Step 5/5 — Running verification summary...'; END $$;

SELECT
    t.tablename                                                    AS table_name,
    pg_size_pretty(
        pg_total_relation_size(t.schemaname || '.' || t.tablename)
    )                                                              AS total_size,
    (
        SELECT COUNT(*)
        FROM information_schema.columns c
        WHERE c.table_schema = t.schemaname
          AND c.table_name   = t.tablename
    )                                                              AS column_count,
    (
        SELECT COUNT(*)
        FROM information_schema.table_constraints tc
        WHERE tc.table_schema = t.schemaname
          AND tc.table_name   = t.tablename
          AND tc.constraint_type = 'FOREIGN KEY'
    )                                                              AS fk_count
FROM pg_tables t
WHERE t.schemaname = 'public'
  -- Exclude partition child tables from the summary
  AND NOT EXISTS (
      SELECT 1
      FROM pg_inherits i
      JOIN pg_class pc ON pc.oid = i.inhrelid
      WHERE pc.relname = t.tablename
  )
ORDER BY t.tablename;

-- Count total indexes created
SELECT COUNT(*) AS total_indexes_created
FROM pg_indexes
WHERE schemaname = 'public';

-- Count total views created
SELECT COUNT(*) AS total_views_created
FROM information_schema.views
WHERE table_schema = 'public';

DO $$
BEGIN
    RAISE NOTICE
        'SMAP database reset complete. '
        'All 14 operational tables, constraints, indexes, 5 views, and reference data have been re-created. '
        'Database: %', current_database();
END
$$;
