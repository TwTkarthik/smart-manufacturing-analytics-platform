-- =============================================================================
-- schema.sql
-- SMAP Operational Database — Schema Scaffolding
-- PostgreSQL 16 compatible.
--
-- Execution order: 2 of 9
-- Run AFTER extensions.sql; BEFORE tables.sql.
--
-- Creates:
--   - trg_set_updated_at()  : trigger function applied to all mutable tables
--
-- Canonical numbered source: database/sql/03_schema.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- trg_set_updated_at()
-- Automatically stamps updated_at = now() on every UPDATE.
-- Applied via BEFORE UPDATE trigger to every table that has an updated_at column.
--
-- Tables using this trigger (applied in tables.sql):
--   machines, products, employees, production_orders, pm_schedules
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_set_updated_at()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION trg_set_updated_at() IS
    'Trigger function: automatically sets updated_at = now() on every UPDATE. '
    'Applied to all operational tables with an updated_at column. '
    'Do not call directly — attach via CREATE TRIGGER ... BEFORE UPDATE.';
