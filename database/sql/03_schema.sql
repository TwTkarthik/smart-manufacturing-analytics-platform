-- =============================================================================
-- 03_schema.sql
-- SMAP Operational Database — Schema Scaffolding
-- Creates the updated_at trigger function used by all mutable tables.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- updated_at auto-maintenance trigger function
-- Applied to any table with an updated_at column.
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
    'Applied to all operational tables with an updated_at column.';
