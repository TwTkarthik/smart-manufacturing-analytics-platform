-- =============================================================================
-- 02_roles.sql
-- SMAP Operational Database — Database Roles and Permissions
-- Run as superuser.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Application role: used by the FastAPI backend and ETL pipeline
-- Read + Write on all operational tables; no DDL.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'smap_source_app') THEN
        CREATE ROLE smap_source_app WITH LOGIN PASSWORD 'CHANGE_IN_PRODUCTION';
    END IF;
END
$$;

COMMENT ON ROLE smap_source_app IS 'Application role for SMAP backend and ETL pipeline — DML only';

-- ---------------------------------------------------------------------------
-- Read-only role: used by BI dashboards and read replicas
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'smap_readonly') THEN
        CREATE ROLE smap_readonly WITH LOGIN PASSWORD 'CHANGE_IN_PRODUCTION';
    END IF;
END
$$;

COMMENT ON ROLE smap_readonly IS 'Read-only role for BI tools and dashboard consumers';

-- ---------------------------------------------------------------------------
-- Admin role: used by Alembic migrations and the DBA team
-- Full privileges; no login — must GRANT to a named user.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'smap_admin') THEN
        CREATE ROLE smap_admin NOLOGIN;
    END IF;
END
$$;

COMMENT ON ROLE smap_admin IS 'Administrative role for schema migrations and DBA operations — no direct login';

-- ---------------------------------------------------------------------------
-- Grant schema usage
-- ---------------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO smap_source_app, smap_readonly;

-- Grant DML to application role (extended to all future tables via DEFAULT PRIVILEGES)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO smap_source_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO smap_source_app;

-- Grant SELECT only to read-only role
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO smap_readonly;

-- Grant full DDL + DML to admin role
GRANT ALL PRIVILEGES ON SCHEMA public TO smap_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON TABLES TO smap_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON SEQUENCES TO smap_admin;
