-- =============================================================================
-- extensions.sql
-- SMAP Operational Database — PostgreSQL Extensions
-- PostgreSQL 16 compatible.
--
-- Execution order: 1 of 9
-- Run as superuser BEFORE all other DDL scripts.
--
-- Canonical numbered source: database/sql/01_extensions.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- pgcrypto
-- Provides gen_random_uuid() and cryptographic hash functions.
-- Used for ID generation utilities in the ETL pipeline.
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------------
-- pg_stat_statements
-- Enables query-level performance statistics collection.
-- Required by the Grafana postgres_exporter monitoring stack.
-- NOTE: Requires shared_preload_libraries = 'pg_stat_statements' in postgresql.conf.
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- ---------------------------------------------------------------------------
-- btree_gist
-- Adds GiST index support for standard btree data types.
-- Required for exclusion constraints on range columns (reserved for future use).
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "btree_gist";

COMMENT ON EXTENSION pgcrypto          IS 'Cryptographic functions — used for hash-based ID generation utilities in ETL';
COMMENT ON EXTENSION pg_stat_statements IS 'Query statistics collection — consumed by Grafana postgres_exporter monitoring';
COMMENT ON EXTENSION btree_gist        IS 'GiST support for btree types — reserved for future exclusion constraints on time ranges';
