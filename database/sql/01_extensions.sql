-- =============================================================================
-- 01_extensions.sql
-- SMAP Operational Database — PostgreSQL Extensions
-- Run as superuser before all other DDL scripts.
-- =============================================================================

-- Enable UUID generation (used for id validation utilities)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enable query statistics collection (used by Grafana postgres_exporter)
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Enable btree_gist (supports exclusion constraints on ranges — future use)
CREATE EXTENSION IF NOT EXISTS "btree_gist";

COMMENT ON EXTENSION pgcrypto        IS 'Cryptographic functions — used for hash-based ID generation utilities';
COMMENT ON EXTENSION pg_stat_statements IS 'Query statistics collection — used by monitoring stack';
COMMENT ON EXTENSION btree_gist      IS 'GiST support for btree types — used for future exclusion constraints';
