-- =============================================================================
-- roles.sql
-- SMAP Operational Database — Database Roles and Permissions
-- PostgreSQL 16 compatible.
--
-- Execution order: 7 of 9
-- Run AFTER views.sql; BEFORE seed.sql.
-- Must be run as a superuser (e.g., postgres).
--
-- Roles created:
--   smap_source_app  — application role (FastAPI backend, ETL pipeline): DML only
--   smap_readonly    — read-only role (BI dashboards, reporting tools, read replicas)
--   smap_admin       — administrative role (Alembic migrations, DBA): full DDL + DML, no login
--
-- IMPORTANT: Change passwords before deploying to any non-local environment.
--            Use environment variables or a secrets manager — never hardcode in CI/CD.
--
-- Canonical numbered source: database/sql/02_roles.sql
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- smap_source_app
-- Used by the FastAPI backend and ETL pipeline.
-- Permissions: SELECT, INSERT, UPDATE, DELETE on all tables; USAGE on sequences.
-- No CREATE, DROP, or TRUNCATE privileges.
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'smap_source_app') THEN
        CREATE ROLE smap_source_app
            WITH LOGIN
            PASSWORD 'CHANGE_IN_PRODUCTION'
            CONNECTION LIMIT 50;
    END IF;
END
$$;

COMMENT ON ROLE smap_source_app IS
    'Application role for the SMAP FastAPI backend and ETL pipeline. '
    'DML only (SELECT, INSERT, UPDATE, DELETE). No DDL privileges. '
    'Connection limit: 50. Change password via secrets manager before production deployment.';


-- ─────────────────────────────────────────────────────────────────────────────
-- smap_readonly
-- Used by BI dashboards (Grafana, Metabase), read replicas, and data consumers.
-- Permissions: SELECT only on all tables and views.
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'smap_readonly') THEN
        CREATE ROLE smap_readonly
            WITH LOGIN
            PASSWORD 'CHANGE_IN_PRODUCTION'
            CONNECTION LIMIT 20;
    END IF;
END
$$;

COMMENT ON ROLE smap_readonly IS
    'Read-only role for BI tools, dashboard consumers, and analytical queries. '
    'SELECT only. No INSERT, UPDATE, DELETE, or DDL. '
    'Connection limit: 20. Change password via secrets manager before production deployment.';


-- ─────────────────────────────────────────────────────────────────────────────
-- smap_admin
-- Used by Alembic database migrations and the DBA team.
-- Full DDL + DML privileges on the public schema.
-- NOLOGIN: must be granted to a specific named user (e.g., SET ROLE smap_admin).
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'smap_admin') THEN
        CREATE ROLE smap_admin
            NOLOGIN;
    END IF;
END
$$;

COMMENT ON ROLE smap_admin IS
    'Administrative role for schema migrations (Alembic) and DBA operations. '
    'Full DDL + DML. No direct login — must GRANT smap_admin TO a named user. '
    'Usage: SET ROLE smap_admin; before running migration scripts.';


-- ─────────────────────────────────────────────────────────────────────────────
-- Schema-level grants
-- ─────────────────────────────────────────────────────────────────────────────

-- Allow application and read-only roles to see objects in the public schema
GRANT USAGE ON SCHEMA public TO smap_source_app, smap_readonly;

-- Admin role gets full schema ownership
GRANT ALL PRIVILEGES ON SCHEMA public TO smap_admin;


-- ─────────────────────────────────────────────────────────────────────────────
-- Table-level grants (existing tables)
-- ─────────────────────────────────────────────────────────────────────────────

-- Application role: DML on all existing tables
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO smap_source_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO smap_source_app;

-- Read-only role: SELECT on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO smap_readonly;

-- Admin role: full privileges on all existing tables
GRANT ALL ON ALL TABLES IN SCHEMA public TO smap_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO smap_admin;


-- ─────────────────────────────────────────────────────────────────────────────
-- Default privileges (future tables created by smap_admin or superuser)
-- Ensures roles automatically receive appropriate privileges on new tables
-- created by Alembic migrations without requiring manual GRANT statements.
-- ─────────────────────────────────────────────────────────────────────────────

-- Application role: DML on all future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO smap_source_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO smap_source_app;

-- Read-only role: SELECT on all future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO smap_readonly;

-- Admin role: full privileges on all future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON TABLES TO smap_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON SEQUENCES TO smap_admin;
