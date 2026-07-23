# 📡 API Specification — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Last Updated:** 2026-07-20
**Base URL:** `http://localhost:8000/api/v1`
**API Format:** REST / JSON
**Auth:** API Key (header: `X-API-Key`)
**Status:** Draft — Endpoints Under Design

---

## 📋 Table of Contents

1. [Overview](#1-overview)
2. [Authentication](#2-authentication)
3. [Request & Response Conventions](#3-request--response-conventions)
4. [Error Handling](#4-error-handling)
5. [Rate Limiting](#5-rate-limiting)
6. [Endpoints — Health](#6-endpoints--health)
7. [Endpoints — Production](#7-endpoints--production)
8. [Endpoints — Quality](#8-endpoints--quality)
9. [Endpoints — Maintenance](#9-endpoints--maintenance)
10. [Endpoints — OEE / KPIs](#10-endpoints--oee--kpis)
11. [Endpoints — Machine Learning](#11-endpoints--machine-learning)
12. [Endpoints — Sensors](#12-endpoints--sensors)
13. [Pagination](#13-pagination)
14. [Filtering & Date Ranges](#14-filtering--date-ranges)
15. [API Versioning](#15-api-versioning)
16. [OpenAPI / Swagger Documentation](#16-openapi--swagger-documentation)

---

## 1. Overview

The SMAP REST API is built with **FastAPI** and provides structured access to all manufacturing analytics data stored in the data warehouse. It serves as the single interface between the data layer and all consuming applications (React dashboard, Jupyter notebooks, external tools).

### Design Goals
- **RESTful** — Resources are nouns; actions are HTTP verbs
- **Consistent** — Uniform response envelopes across all endpoints
- **Documented** — Auto-generated Swagger UI at `/docs`; ReDoc at `/redoc`
- **Versioned** — All endpoints under `/api/v1/`; non-breaking

---

## 2. Authentication

> **Placeholder** — Describe authentication mechanism:

All API requests must include the following header:

```http
X-API-Key: <your-api-key>
```

| Scenario | Response |
|---|---|
| Valid key | `200 OK` |
| Missing key | `401 Unauthorized` |
| Invalid key | `403 Forbidden` |

> **Placeholder** — For portfolio demo purposes, a fixed development key is used. Production would implement proper key management.

---

## 3. Request & Response Conventions

### 3.1 Content Type
All requests and responses use `application/json`.

### 3.2 Standard Response Envelope

All successful responses follow this envelope:

```json
{
  "status": "success",
  "data": { ... },
  "meta": {
    "timestamp": "2024-07-20T12:00:00Z",
    "request_id": "req_abc123",
    "version": "1.0.0"
  }
}
```

### 3.3 Paginated Response Envelope

```json
{
  "status": "success",
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "page_size": 50,
    "total_records": 1250,
    "total_pages": 25,
    "has_next": true,
    "has_previous": false
  },
  "meta": {
    "timestamp": "2024-07-20T12:00:00Z",
    "request_id": "req_abc123"
  }
}
```

### 3.4 Date Format
All dates and timestamps use **ISO 8601 / RFC 3339**: `YYYY-MM-DDTHH:MM:SSZ`

### 3.5 Numeric Precision
- Percentages returned as decimals (e.g., `0.9521` = 95.21%)
- Monetary values returned as strings to avoid floating-point issues
- Counts returned as integers

---

## 4. Error Handling

### 4.1 Error Response Format

```json
{
  "status": "error",
  "error": {
    "code": "MACHINE_NOT_FOUND",
    "message": "Machine with ID 'MCH-999' does not exist.",
    "details": null,
    "request_id": "req_abc123"
  }
}
```

### 4.2 HTTP Status Codes

| Code | Meaning | When Used |
|---|---|---|
| `200 OK` | Success | Successful GET, PUT |
| `201 Created` | Created | Successful POST |
| `204 No Content` | No Content | Successful DELETE |
| `400 Bad Request` | Invalid input | Validation errors, malformed request |
| `401 Unauthorized` | Not authenticated | Missing API key |
| `403 Forbidden` | Not authorized | Invalid API key |
| `404 Not Found` | Resource missing | ID does not exist |
| `422 Unprocessable Entity` | Validation error | Query parameter type mismatch |
| `429 Too Many Requests` | Rate limit exceeded | Slow down requests |
| `500 Internal Server Error` | Server error | Unexpected failure |
| `503 Service Unavailable` | Service down | Database unreachable |

### 4.3 Error Codes

> **Placeholder** — Define application-level error codes:

| Error Code | HTTP Status | Description |
|---|---|---|
| `MACHINE_NOT_FOUND` | 404 | Machine ID does not exist |
| `INVALID_DATE_RANGE` | 400 | Start date is after end date |
| `DATE_RANGE_TOO_LARGE` | 400 | Requested range exceeds 365 days |
| `INSUFFICIENT_DATA` | 200 | Not enough data to compute metric |
| `MODEL_UNAVAILABLE` | 503 | ML model not loaded |
| `VALIDATION_ERROR` | 422 | Request body fails validation |

---

## 5. Rate Limiting

> **Placeholder** — Describe rate limiting:
> - **Default limit:** 100 requests per minute per API key
> - **Headers returned:** `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
> - **Exceeded:** `429 Too Many Requests` with `Retry-After` header

---

## 6. Endpoints — Health

### `GET /health`

Returns API health status and component connectivity.

**Authentication:** None required

**Response `200`:**
```json
{
  "status": "healthy",
  "components": {
    "database": "connected",
    "ml_models": "loaded",
    "version": "1.0.0",
    "uptime_seconds": 3600
  }
}
```

---

## 7. Endpoints — Production

### `GET /production/summary`

Returns production summary metrics for a date range.

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `start_date` | `date` | Yes | — | Start date (YYYY-MM-DD) |
| `end_date` | `date` | Yes | — | End date (YYYY-MM-DD) |
| `machine_id` | `string` | No | All | Filter by machine ID |
| `product_code` | `string` | No | All | Filter by product |
| `shift_code` | `string` | No | All | Filter by shift |

**Response `200`:**
```json
{
  "status": "success",
  "data": {
    "period": {
      "start_date": "2024-07-01",
      "end_date": "2024-07-20"
    },
    "total_planned_units": 125000,
    "total_actual_units": 118540,
    "total_good_units": 115200,
    "total_scrap_units": 3340,
    "overall_yield_pct": 0.9719,
    "scrap_rate_pct": 0.0281,
    "total_production_orders": 480
  },
  "meta": { ... }
}
```

---

### `GET /production/by-machine`

> **Placeholder** — Returns production breakdown grouped by machine.

**Query Parameters:** `start_date`, `end_date`, `product_code`, `shift_code`

**Response `200`:** Array of machine-level production metrics

---

### `GET /production/by-shift`

> **Placeholder** — Returns production breakdown grouped by shift.

---

### `GET /production/trend`

> **Placeholder** — Returns daily production trend data for time-series charting.

**Query Parameters:** `start_date`, `end_date`, `machine_id`, `granularity` (day/week/month)

---

### `GET /production/orders`

> **Placeholder** — Returns paginated list of individual production orders.

---

## 8. Endpoints — Quality

### `GET /quality/summary`

> **Placeholder** — Returns quality inspection summary for a date range.

**Response includes:** `total_inspections`, `total_defects`, `defect_rate_pct`, `pass_rate_pct`, `top_defect_types[]`

---

### `GET /quality/pareto`

> **Placeholder** — Returns defect data sorted for Pareto chart visualization.

**Response:** Array of defect types with count and cumulative percentage, sorted descending.

---

### `GET /quality/control-chart`

> **Placeholder** — Returns data for Statistical Process Control (SPC) charts.

**Query Parameters:** `machine_id`, `measurement_type`, `start_date`, `end_date`

**Response:** Data points with UCL, LCL, and centerline values.

---

### `GET /quality/trend`

> **Placeholder** — Returns defect rate trend over time.

---

## 9. Endpoints — Maintenance

### `GET /maintenance/summary`

> **Placeholder** — Returns maintenance KPI summary.

**Response includes:** `total_downtime_hours`, `mtbf_hours`, `mttr_hours`, `planned_vs_unplanned_ratio`, `top_failure_modes[]`

---

### `GET /maintenance/events`

> **Placeholder** — Returns paginated list of maintenance/downtime events.

---

### `GET /maintenance/downtime-by-machine`

> **Placeholder** — Returns downtime breakdown per machine, sortable.

---

### `GET /maintenance/reliability-trend`

> **Placeholder** — Returns MTBF trend over time for reliability analysis.

---

## 10. Endpoints — OEE / KPIs

### `GET /kpis/oee`

Returns Overall Equipment Effectiveness (OEE) breakdown.

**Query Parameters:** `start_date`, `end_date`, `machine_id`, `shift_code`

**Response `200`:**
```json
{
  "status": "success",
  "data": {
    "machine_id": "MCH-001",
    "period": { "start_date": "2024-07-01", "end_date": "2024-07-20" },
    "oee": {
      "overall": 0.7823,
      "availability": 0.9150,
      "performance": 0.8860,
      "quality": 0.9650
    },
    "world_class_benchmark": 0.85,
    "gap_to_benchmark": -0.0677
  },
  "meta": { ... }
}
```

---

### `GET /kpis/oee/by-machine`

> **Placeholder** — Returns OEE comparison across all machines for a period.

---

### `GET /kpis/oee/trend`

> **Placeholder** — Returns OEE trend with availability, performance, quality components over time.

---

### `GET /kpis/dashboard-summary`

> **Placeholder** — Aggregated endpoint returning all top-level KPIs for dashboard hero section.

**Response:** Single response containing production, quality, maintenance, and OEE headline numbers.

---

## 11. Endpoints — Machine Learning

### `POST /ml/predict/maintenance`

Predict failure probability for a machine.

**Request Body:**
```json
{
  "machine_id": "MCH-001",
  "horizon_days": 7
}
```

**Response `200`:**
```json
{
  "status": "success",
  "data": {
    "machine_id": "MCH-001",
    "prediction_horizon_days": 7,
    "failure_probability": 0.342,
    "risk_level": "MEDIUM",
    "top_contributing_features": [
      { "feature": "vibration_trend_7d", "importance": 0.42 },
      { "feature": "days_since_last_maintenance", "importance": 0.31 },
      { "feature": "temperature_variance_7d", "importance": 0.18 }
    ],
    "model_version": "v1.2.0",
    "prediction_timestamp": "2024-07-20T12:00:00Z"
  }
}
```

---

### `POST /ml/detect/anomaly`

> **Placeholder** — Detect anomalies in recent sensor readings for a machine.

**Request Body:** `{ "machine_id": "MCH-001", "lookback_hours": 24 }`

**Response:** Anomaly score, flag, and detected anomalous readings.

---

### `POST /ml/predict/quality`

> **Placeholder** — Predict expected defect rate given current process parameters.

**Request Body:** Process parameter values for target machine.

**Response:** Predicted defect rate and confidence interval.

---

### `GET /ml/models`

> **Placeholder** — Returns inventory of all loaded ML models with version and performance metrics.

---

## 12. Endpoints — Sensors

### `GET /sensors/latest`

> **Placeholder** — Returns the most recent sensor reading for each sensor on a machine.

**Query Parameters:** `machine_id`

---

### `GET /sensors/history`

> **Placeholder** — Returns paginated sensor reading history for a machine and time range.

**Query Parameters:** `machine_id`, `sensor_type`, `start_datetime`, `end_datetime`, `page`, `page_size`

---

### `GET /sensors/anomalies`

> **Placeholder** — Returns sensor readings flagged as anomalies.

---

## 13. Pagination

All list endpoints support cursor-based or offset pagination:

**Query Parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `page` | `integer` | `1` | Page number (1-indexed) |
| `page_size` | `integer` | `50` | Records per page (max: 500) |

---

## 14. Filtering & Date Ranges

**Standard Date Query Pattern:**

```
GET /production/summary?start_date=2024-07-01&end_date=2024-07-31
```

**Date Range Constraints:**
- Maximum range: 365 days
- `start_date` must be ≤ `end_date`
- Future dates will return empty data (not an error)

---

## 15. API Versioning

The API uses URL-based versioning:

| Version | Path Prefix | Status |
|---|---|---|
| v1 | `/api/v1/` | 🟢 Current |
| v2 | `/api/v2/` | 🔮 Planned |

Non-breaking changes (new optional fields, new endpoints) are added to the current version. Breaking changes (removed fields, changed types) require a new version.

---

## 16. OpenAPI / Swagger Documentation

When the FastAPI server is running, interactive API documentation is available at:

| Interface | URL |
|---|---|
| **Swagger UI** | `http://localhost:8000/docs` |
| **ReDoc** | `http://localhost:8000/redoc` |
| **OpenAPI JSON** | `http://localhost:8000/openapi.json` |

> **Placeholder** — Screenshots of the Swagger UI will be added to `assets/images/` once the API is implemented.

---

*This specification is the source of truth for API design. All implementation must conform to the contracts defined here. Deviations require updating this document first.*
