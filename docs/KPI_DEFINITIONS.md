# KPI Definitions — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Last Updated:** 2026-07-22
**Status:** Approved — Business Domain Baseline
**Owner:** Business Analysis Lead
**Related Documents:** [COMPANY_PROFILE.md](./COMPANY_PROFILE.md) · [BUSINESS_PROBLEMS.md](./BUSINESS_PROBLEMS.md) · [MANUFACTURING_PROCESS.md](./MANUFACTURING_PROCESS.md)

---

## Table of Contents

1. [KPI Framework Overview](#1-kpi-framework-overview)
2. [OEE — Overall Equipment Effectiveness](#2-oee--overall-equipment-effectiveness)
3. [Availability](#3-availability)
4. [Performance](#4-performance)
5. [Quality (OEE Component)](#5-quality-oee-component)
6. [Defect Rate](#6-defect-rate)
7. [MTBF — Mean Time Between Failures](#7-mtbf--mean-time-between-failures)
8. [MTTR — Mean Time to Repair](#8-mttr--mean-time-to-repair)
9. [Throughput](#9-throughput)
10. [Cycle Time](#10-cycle-time)
11. [Energy Consumption](#11-energy-consumption)
12. [Production Efficiency](#12-production-efficiency)
13. [Additional Supporting KPIs](#13-additional-supporting-kpis)
14. [KPI Hierarchy and Dashboard Mapping](#14-kpi-hierarchy-and-dashboard-mapping)
15. [KPI Targets Summary](#15-kpi-targets-summary)

---

## 1. KPI Framework Overview

PrecisionEdge Manufacturing uses a four-tier KPI hierarchy aligned with the strategic business goals defined in [COMPANY_PROFILE.md §6](./COMPANY_PROFILE.md#6-business-goals).

```
Level 1 — Strategic KPIs
    (OEE, Scrap Cost, Energy Cost/Unit, Reporting Latency)
    Audience: Operations Director, Plant Manager, Finance

Level 2 — Operational KPIs
    (Availability, Performance, Quality, MTBF, MTTR, Throughput, Production Efficiency)
    Audience: Production Supervisor, Maintenance Manager, Quality Engineer

Level 3 — Diagnostic KPIs
    (Defect Rate by Type, Downtime by Reason, Cycle Time vs. Standard, Machine-Level OEE)
    Audience: Process Engineer, Line Supervisor, Maintenance Technician

Level 4 — Data / Signal
    (Raw sensor readings, per-cycle counts, individual inspection results)
    Audience: Analytical layer, ML models, ad-hoc analysis
```

All KPIs in this document are defined with:
- **Formula** — the exact calculation
- **Grain** — the lowest level of aggregation at which the KPI is calculated
- **Data Sources** — which source systems feed the KPI
- **Owner** — the department accountable for this KPI
- **Target** — the performance target for PrecisionEdge PLT-DET
- **Benchmark** — industry reference point
- **SMAP Calculation Layer** — where in the data pipeline this KPI is computed

---

## 2. OEE — Overall Equipment Effectiveness

### 2.1 Definition

**Overall Equipment Effectiveness (OEE)** is the gold-standard KPI for measuring the productive efficiency of a manufacturing asset. It quantifies the proportion of scheduled manufacturing time that is truly productive — producing good parts at the expected speed.

OEE integrates three independent performance dimensions — Availability, Performance, and Quality — into a single composite score.

### 2.2 Formula

```
OEE = Availability × Performance × Quality

Where:
  Availability = (Planned Production Time − Downtime) / Planned Production Time
  Performance  = (Actual Units Produced × Standard Cycle Time) / (Run Time × 60)
  Quality      = Good Units / Total Units Produced
```

> **Important:** All three components are expressed as decimal values (0.0 to 1.0). OEE is their product, also expressed as a decimal or percentage.

### 2.3 Worked Example

| Input                       | Value                       |
|-----------------------------|-----------------------------|
| Planned Production Time     | 480 minutes (8-hour shift)  |
| Unplanned Downtime          | 60 minutes                  |
| Run Time                    | 420 minutes                 |
| Standard Cycle Time         | 2.5 minutes/unit            |
| Actual Units Produced       | 152 units                   |
| Good Units (passed QC)      | 146 units                   |

| KPI         | Calculation                           | Result  |
|-------------|---------------------------------------|---------|
| Availability | (480 − 60) / 480                     | 87.5%   |
| Performance  | (152 × 2.5) / (420) = 380 / 420      | 90.5%   |
| Quality      | 146 / 152                             | 96.1%   |
| **OEE**      | 87.5% × 90.5% × 96.1%               | **76.1%** |

### 2.4 OEE Interpretation Scale

| OEE Score    | World-Class? | Interpretation                                         |
|--------------|--------------|--------------------------------------------------------|
| ≥ 85%        | World-Class  | Highly optimized; used as an aspirational benchmark     |
| 75–85%       | Good         | Typical for high-performing automotive supplier         |
| 60–75%       | Acceptable   | Room for significant improvement; common in job-shop    |
| < 60%        | Poor         | Major losses present; immediate improvement action needed |

**PrecisionEdge current baseline:** 68% (below industry benchmark)
**PrecisionEdge target (Q4 2027):** 82%

### 2.5 KPI Metadata

| Attribute               | Detail                                              |
|-------------------------|-----------------------------------------------------|
| **Grain**               | Per production order; aggregated to machine/shift/day |
| **Data Sources**        | MES (production orders, downtime events), ERP (planned schedule) |
| **Owner**               | DEPT-OPS (Manufacturing Operations)                 |
| **Target (PLT-DET)**    | 82% fleet average by Q4 2027                        |
| **Industry Benchmark**  | 75–85% (automotive Tier-2)                          |
| **SMAP Layer**          | `int_oee_calculation` → `fct_production` (dbt intermediate + fact) |
| **Dashboard View**      | OEE Overview — primary KPI gauge                   |

---

## 3. Availability

### 3.1 Definition

**Availability** measures the proportion of scheduled production time that the machine is actually available to run — i.e., not stopped due to breakdowns, tooling changes, setup, or other downtime events. It is the OEE component most directly impacted by maintenance effectiveness.

Availability only measures **unplanned stops** if the intent is to exclude planned maintenance from the calculation. PrecisionEdge uses **total availability** (including planned stops) as the primary OEE input, and reports **unplanned availability loss** as a separate diagnostic KPI.

### 3.2 Formula

```
Availability = (Planned Production Time − Total Downtime) / Planned Production Time

Unplanned Availability = (Planned Production Time − Unplanned Downtime) / Planned Production Time
```

### 3.3 Availability Loss Categories

| Loss Category            | Description                                         | Example                              |
|--------------------------|-----------------------------------------------------|--------------------------------------|
| Unplanned Downtime       | Unexpected machine failure or process fault          | Spindle bearing failure              |
| Planned Maintenance Stop | Scheduled PM window; machine intentionally offline   | Lubrication change, filter service   |
| Setup & Changeover       | Time to change from one product to the next          | Tool change, fixture swap            |
| Waiting (No Operator)    | Machine ready but no operator assigned               | Break coverage gap                   |
| Waiting (No Material)    | Machine ready but material not available             | Raw material stock-out               |

### 3.4 KPI Metadata

| Attribute               | Detail                                              |
|-------------------------|-----------------------------------------------------|
| **Grain**               | Per production order; aggregated to machine/shift/day |
| **Data Sources**        | MES (downtime events with reason codes, shift schedule) |
| **Owner**               | DEPT-MNT (Maintenance); DEPT-OPS (Operational stops)|
| **Target (PLT-DET)**    | 88% (from 78% current baseline)                     |
| **Industry Benchmark**  | 85–92%                                              |
| **SMAP Layer**          | `int_oee_calculation` → `fct_production`            |
| **Dashboard View**      | OEE Overview — Availability component bar           |

---

## 4. Performance

### 4.1 Definition

**Performance** measures how fast the machine is running compared to its maximum designed speed. It captures speed losses: the machine is running but producing below its rated capacity due to micro-stops, reduced speed settings, or process parameter changes.

Performance = 1.0 (100%) only when the machine produces every unit in exactly the standard cycle time with no pauses.

### 4.2 Formula

```
Performance = (Actual Units Produced × Standard Cycle Time) / Run Time

Or equivalently:
Performance = Actual Cycle Time / Standard Cycle Time
```

> **Note:** `Run Time` is the time the machine was actually running (Planned Production Time minus Downtime). Standard Cycle Time is sourced from the ERP routing or the product master in the MES.

### 4.3 Performance Loss Categories

| Loss Category      | Description                                                         |
|--------------------|---------------------------------------------------------------------|
| Reduced Speed      | Machine running slower than standard to avoid quality issues or due to condition |
| Minor Stops        | Short stops < 5 minutes (chip clearing, part loading error, coolant check) — too brief to log as downtime |
| Idling             | Machine spinning but not actively cutting / forming                  |

### 4.4 KPI Metadata

| Attribute               | Detail                                              |
|-------------------------|-----------------------------------------------------|
| **Grain**               | Per production order; aggregated to machine/shift/day |
| **Data Sources**        | MES (actual units, actual timestamps), ERP (standard cycle time per product) |
| **Owner**               | DEPT-OPS (Manufacturing Operations)                 |
| **Target (PLT-DET)**    | 91% (from 84% current baseline)                     |
| **Industry Benchmark**  | 88–95%                                              |
| **SMAP Layer**          | `int_oee_calculation` → `fct_production`            |
| **Dashboard View**      | OEE Overview — Performance component bar            |

---

## 5. Quality (OEE Component)

### 5.1 Definition

**Quality** (as an OEE component) measures the proportion of total units produced that meet quality standards on the **first pass** — i.e., good parts as a fraction of all parts produced, including scrap and rework.

This is distinct from the **Defect Rate** KPI (Section 6), which measures the fraction of parts that are defective.

### 5.2 Formula

```
Quality (OEE) = Good Units / Total Units Produced

Where:
  Good Units = Total Units Produced − Scrap Units − Rework Units
  Total Units = All units counted by machine, including defective and reworked
```

> **Rework treatment:** Per standard OEE methodology, reworked units are **not** counted as good units in the Quality OEE component, even if they ultimately pass inspection. They are a quality loss because they required additional processing time not accounted for in the standard cycle time.

### 5.3 KPI Metadata

| Attribute               | Detail                                              |
|-------------------------|-----------------------------------------------------|
| **Grain**               | Per production order; aggregated to machine/shift/day |
| **Data Sources**        | MES (actual units, good units, scrap units from quality inspection results) |
| **Owner**               | DEPT-QA (Quality Assurance)                         |
| **Target (PLT-DET)**    | 99.1% (from 97.2% current baseline)                 |
| **Industry Benchmark**  | 98–99.5%                                            |
| **SMAP Layer**          | `int_oee_calculation` → `fct_production`            |
| **Dashboard View**      | OEE Overview — Quality component bar                |

---

## 6. Defect Rate

### 6.1 Definition

**Defect Rate** measures the proportion of units inspected that are found to be non-conforming (defective). Unlike the Quality OEE component (which references all units produced), Defect Rate is calculated from the quality inspection records and is reported at multiple grains: by product, by machine, by defect type, by shift.

### 6.2 Formulas

```
Defect Rate (%) = (Defects Found / Units Inspected) × 100

PPM Defect Rate = (Defects Found / Units Inspected) × 1,000,000

First Pass Yield (FPY) = 1 − Defect Rate = (Units Passing on First Inspection / Total Inspected) × 100
```

### 6.3 Defect Rate Reporting Hierarchy

| Grain                    | Description                                          | Typical Use Case                       |
|--------------------------|------------------------------------------------------|----------------------------------------|
| Per inspection event     | Defect rate for a single sampling event              | SPC chart data point                   |
| Per production order     | Aggregate defect rate for the full order             | Quality release decision               |
| Per machine / shift      | Defect rate attributed to a machine or operator team | Root cause identification              |
| Per product              | Defect rate by product code                          | Product-level quality trend            |
| Per defect type          | Defect rate broken down by defect category           | Pareto analysis — top defect categories|
| Monthly fleet-wide       | Rolled up across all machines and products           | Customer scorecard, management review  |

### 6.4 KPI Metadata

| Attribute               | Detail                                              |
|-------------------------|-----------------------------------------------------|
| **Grain**               | Per inspection event; rolled up by multiple dimensions |
| **Data Sources**        | MES Quality module (inspection records)              |
| **Owner**               | DEPT-QA (Quality Assurance)                         |
| **Target (PLT-DET)**    | <1.5% overall; <500 PPM customer escape             |
| **Industry Benchmark**  | <1% for high-precision automotive suppliers         |
| **SMAP Layer**          | `fct_quality_inspection` (fact table); Pareto in mart |
| **Dashboard View**      | Quality Control — Defect rate trend, Pareto chart   |

---

## 7. MTBF — Mean Time Between Failures

### 7.1 Definition

**Mean Time Between Failures (MTBF)** measures the average operating time between unplanned machine failures. A higher MTBF indicates better machine reliability and more effective preventive maintenance. MTBF is the primary measure of equipment reliability.

MTBF is calculated **per machine** over a rolling time window (e.g., 30-day, 90-day) and is also reported as a fleet average.

### 7.2 Formula

```
MTBF = Total Operating Hours / Number of Unplanned Failures

Where:
  Total Operating Hours = Scheduled production time − Planned downtime (excludes PM windows)
  Number of Unplanned Failures = Count of unplanned downtime events (event_type = 'Unplanned' or 'Emergency')
```

### 7.3 Interpretation

| MTBF Trend         | Interpretation                                              | Action                                     |
|--------------------|-------------------------------------------------------------|--------------------------------------------|
| Increasing         | Machine becoming more reliable; PM strategy effective        | Maintain current PM intervals               |
| Stable             | Reliability steady; no deterioration                         | Monitor; no change required                |
| Decreasing         | Machine reliability degrading; failure rate increasing       | Review PM plan; check sensor trends; escalate |
| Step-down change   | Significant event changed reliability baseline               | Investigate specific failure; check repair quality |

### 7.4 KPI Metadata

| Attribute               | Detail                                              |
|-------------------------|-----------------------------------------------------|
| **Grain**               | Per machine; 30-day and 90-day rolling windows      |
| **Data Sources**        | MES Maintenance module (work orders, event types, timestamps) |
| **Owner**               | DEPT-MNT (Maintenance & Reliability)                |
| **Target (PLT-DET)**    | 38+ days (CNC fleet average; from 21-day baseline) |
| **Industry Benchmark**  | 30–60 days (varies significantly by machine type)   |
| **SMAP Layer**          | `int_reliability_metrics` → `fct_maintenance_event` |
| **Dashboard View**      | Maintenance & Reliability — MTBF trend chart        |

---

## 8. MTTR — Mean Time to Repair

### 8.1 Definition

**Mean Time to Repair (MTTR)** measures the average time taken to restore a machine to operational status after an unplanned failure — from the moment the machine stops to the moment it is running production again. MTTR reflects the effectiveness and speed of the maintenance response.

A lower MTTR indicates faster diagnosis, efficient parts access, and skilled repair execution.

### 8.2 Formula

```
MTTR = Total Unplanned Downtime Minutes / Number of Unplanned Failures

Per Event:
MTTR (event) = downtime_end − downtime_start   (for unplanned events only)
```

### 8.3 MTTR Component Breakdown

| MTTR Component            | Description                                          |
|---------------------------|------------------------------------------------------|
| Response time             | Time from failure event to technician arrival        |
| Diagnosis time            | Time to identify root cause and required repair       |
| Parts retrieval time      | Time to obtain required spare parts from storeroom   |
| Active repair time        | Actual hands-on repair duration                      |
| Testing & verification    | Time to test machine and confirm return to spec       |

**Insight:** If spare parts are unavailable (wait for emergency order), parts retrieval time can dominate MTTR — sometimes exceeding 24 hours. SMAP's inventory integration and maintenance prediction are designed to eliminate this component by ensuring parts are pre-positioned before failure occurs.

### 8.4 KPI Metadata

| Attribute               | Detail                                              |
|-------------------------|-----------------------------------------------------|
| **Grain**               | Per unplanned maintenance event; aggregated per machine, per month |
| **Data Sources**        | MES Maintenance module (work order timestamps)       |
| **Owner**               | DEPT-MNT (Maintenance & Reliability)                |
| **Target (PLT-DET)**    | <1.5 hours (from 4.8-hour unplanned MTTR baseline) |
| **Industry Benchmark**  | 1–4 hours (varies by machine complexity)             |
| **SMAP Layer**          | `int_reliability_metrics` → `fct_maintenance_event` |
| **Dashboard View**      | Maintenance & Reliability — MTTR trend; downtime log |

---

## 9. Throughput

### 9.1 Definition

**Throughput** measures the volume of output a machine, line, or plant produces in a defined time period. It is expressed in units per hour, units per shift, or units per day. Throughput is the most fundamental production output metric — it answers "how much did we make?"

Throughput is always qualified by whether it refers to **total units produced** or **good units produced** (first-pass yield throughput).

### 9.2 Formulas

```
Throughput (gross) = Total Units Produced / Time Period

Throughput (good) = Good Units Produced / Time Period

Throughput Rate (units/hr) = Good Units / (Run Time in hours)

Throughput vs. Plan (%) = (Actual Good Units / Planned Units) × 100
```

### 9.3 Throughput Reporting Dimensions

| Dimension        | Use Case                                              |
|------------------|-------------------------------------------------------|
| By machine        | Machine-level capacity utilization                   |
| By production line| Line-level output vs. plan                           |
| By shift          | Shift-level performance comparison (Day vs. Night)   |
| By product        | Volume by product code vs. customer schedule          |
| By day/week/month | Period-level trend analysis for planning adjustments  |

### 9.4 KPI Metadata

| Attribute               | Detail                                              |
|-------------------------|-----------------------------------------------------|
| **Grain**               | Per production order; aggregated by machine/line/shift/day |
| **Data Sources**        | MES (actual units, good units, timestamps)           |
| **Owner**               | DEPT-OPS (Manufacturing Operations)                 |
| **Target (PLT-DET)**    | ≥98% Throughput vs. Plan (fleet average)            |
| **Industry Benchmark**  | 95–98% on-schedule throughput for high-volume manufacturing |
| **SMAP Layer**          | `fct_production` (actual and good units, timestamps) |
| **Dashboard View**      | Production Throughput — planned vs. actual chart     |

---

## 10. Cycle Time

### 10.1 Definition

**Cycle Time** is the elapsed time from the start of one unit's production to the start of the next — the actual time taken to produce one part. It is compared against the **Standard Cycle Time** (the engineered target time for producing one unit at full efficiency) to identify performance losses.

Cycle time analysis is central to Performance calculation and is the primary diagnostic for identifying speed losses in the production process.

### 10.2 Formulas

```
Actual Cycle Time (per unit) = (Run Time) / Actual Units Produced

Standard Cycle Time = Engineered design time per unit (from ERP routing)

Cycle Time Efficiency = Standard Cycle Time / Actual Cycle Time

Cycle Time Variance = Actual Cycle Time − Standard Cycle Time
  (positive = slower than standard; negative = faster than standard)
```

### 10.3 Cycle Time Drivers

| Factor                     | Effect on Cycle Time                                      |
|----------------------------|-----------------------------------------------------------|
| Machine speed (RPM, feed)  | Reduced speed → longer cycle time; primary operator-controlled variable |
| Tool wear                  | As tool wears, feed rate reduced → cycle time increases  |
| Part geometry complexity   | More complex parts have longer standard cycle times       |
| Setup quality              | Poor setup → operator intervention mid-cycle → longer actual cycle time |
| Machine condition          | Vibration/wear → reduced speed → longer cycle time        |

### 10.4 KPI Metadata

| Attribute               | Detail                                              |
|-------------------------|-----------------------------------------------------|
| **Grain**               | Per production order; averaged across units in the order |
| **Data Sources**        | MES (actual units produced, run time), ERP (standard cycle time from routing) |
| **Owner**               | DEPT-OPS; DEPT-ENG for standard cycle time definition |
| **Target (PLT-DET)**    | Cycle Time Efficiency ≥ 95% (actual CT within 5% of standard) |
| **Industry Benchmark**  | High-performers achieve 95–100% of standard         |
| **SMAP Layer**          | `int_oee_calculation` (derived) → `fct_production` |
| **Dashboard View**      | Production Throughput — cycle time efficiency chart  |

---

## 11. Energy Consumption

### 11.1 Definition

**Energy Consumption** tracks the electrical energy used by production machines, normalized to a per-unit-produced basis to enable fair comparison across products, machines, and time periods. This KPI is the primary measure for PrecisionEdge's energy reduction goal.

### 11.2 Formulas

```
Energy per Unit = Total kWh Consumed by Machine / Good Units Produced
  (during the same time window)

Energy per Production Order = Sum of kWh readings during order run time

Idle Energy Consumption (%) = (Energy during idle periods / Total energy) × 100

Energy Cost per Unit = Energy per Unit × Energy Unit Cost ($/kWh)

Energy Intensity = Total kWh / Total Good Units  (fleet-wide; used for target tracking)
```

### 11.3 Energy Consumption Benchmarks

| Machine Type    | Typical kWh Range (active machining) | Energy Reduction Opportunity |
|-----------------|---------------------------------------|------------------------------|
| CNC Turning     | 8–25 kWh/hour                         | 15–20% (idle reduction)      |
| CNC Milling     | 12–45 kWh/hour                        | 15–25% (idle reduction)      |
| CNC Grinding    | 15–35 kWh/hour                        | 10–15% (speed optimization)  |
| Hydraulic Press | 18–85 kWh/hour (peak)                 | 20–30% (standby reduction)   |

**Fleet-wide current baseline (PLT-DET):** ~4.2 kWh per good unit produced
**Target:** <3.6 kWh per good unit (−15% by end of FY2027)

### 11.4 KPI Metadata

| Attribute               | Detail                                              |
|-------------------------|-----------------------------------------------------|
| **Grain**               | Per production order; aggregated per machine/shift/day |
| **Data Sources**        | SCADA (`SEN-POWER` sensor readings), MES (good units, order timing) |
| **Owner**               | DEPT-ENG (Process Engineering); DEPT-OPS            |
| **Target (PLT-DET)**    | <3.6 kWh per good unit (−15% from 4.2 kWh baseline)|
| **Industry Benchmark**  | 3.0–5.0 kWh/unit (varies widely by product complexity) |
| **SMAP Layer**          | `int_energy_metrics` (derived from sensor + production join) → `fct_production` |
| **Dashboard View**      | Production Throughput — energy per unit trend        |

---

## 12. Production Efficiency

### 12.1 Definition

**Production Efficiency** is a broad composite KPI that measures how well the production plan (what was scheduled) was executed (what was actually produced). It encompasses both volume achievement and the utilization of scheduled capacity. Production Efficiency is the executive-level summary KPI for operations performance.

### 12.2 Formulas

```
Production Volume Efficiency = Actual Good Units / Planned Units (for a period)

Schedule Attainment = Production Orders Completed on Time / Total Production Orders Scheduled

Yield Efficiency = Good Units / Total Units (First Pass Yield)

Labor Efficiency = Standard Hours of Work Produced / Actual Hours Worked × 100
```

### 12.3 Production Efficiency vs. OEE

| KPI                   | What it Measures                                     | Scope           |
|-----------------------|------------------------------------------------------|-----------------|
| OEE                   | Machine-level productive time utilization            | Machine-centric |
| Production Efficiency | Plan vs. actual volume achievement                   | Order/plan-centric |
| Throughput            | Physical output rate                                 | Volume-centric  |

> **Key distinction:** OEE can be 100% on a machine that produced nothing in a shift if there were no planned orders. Production Efficiency captures the business reality: did we make what was planned?

### 12.4 KPI Metadata

| Attribute               | Detail                                              |
|-------------------------|-----------------------------------------------------|
| **Grain**               | Per production order; aggregated by line/shift/day/month |
| **Data Sources**        | ERP (planned units from production schedule), MES (actual good units) |
| **Owner**               | DEPT-PLN (Production Planning); DEPT-OPS            |
| **Target (PLT-DET)**    | ≥97% Production Volume Efficiency; ≥95% Schedule Attainment |
| **Industry Benchmark**  | 95–99% for high-performing discrete manufacturers  |
| **SMAP Layer**          | `fct_production` (planned vs. actual comparison)    |
| **Dashboard View**      | Production Throughput — planned vs. actual chart; OEE Overview |

---

## 13. Additional Supporting KPIs

The following KPIs are calculated and tracked in SMAP as supporting diagnostic metrics alongside the primary KPIs above.

### 13.1 Planned vs. Unplanned Maintenance Ratio

```
Planned Maintenance Ratio = Planned Maintenance Events / Total Maintenance Events
```

**Target:** ≥70% planned (currently ~58%)
**Significance:** A higher planned ratio indicates a maturing maintenance culture. As SMAP's predictive maintenance converts unplanned events to proactive planned events, this ratio improves.

### 13.2 Schedule Attainment

```
Schedule Attainment = Production Orders Completed on Schedule / Total Scheduled Orders × 100
```

**Target:** ≥95%

### 13.3 First Pass Yield (FPY)

```
FPY = (Units Passing First Inspection) / Total Units Inspected × 100
```

**Target:** ≥98.5% (complementary to Quality OEE component)

### 13.4 Scrap Rate

```
Scrap Rate = Scrap Units / Total Units Produced × 100
Scrap Cost = Scrap Units × Standard Material Cost Per Unit
```

**Target:** <1.5% overall scrap rate; <$5M scrap cost per year

### 13.5 On-Time Delivery (OTD)

```
OTD = Shipments Delivered on or Before Requested Date / Total Shipments × 100
```

**Target:** ≥98% OTD

### 13.6 Capacity Utilization

```
Capacity Utilization = Actual Operating Hours / Total Available Hours × 100
```

**Target:** 80–90% (below 90% to preserve scheduled maintenance windows)

---

## 14. KPI Hierarchy and Dashboard Mapping

```
OEE Overview Dashboard
├── OEE (Overall) ─── primary KPI
│   ├── Availability ─── OEE component
│   │   └── Downtime by Reason Code ─── diagnostic
│   ├── Performance ─── OEE component
│   │   └── Cycle Time vs. Standard ─── diagnostic
│   └── Quality (OEE) ─── OEE component
│       └── First Pass Yield ─── supporting
│
Production Throughput Dashboard
├── Throughput (planned vs. actual) ─── primary KPI
├── Production Efficiency ─── primary KPI
├── Cycle Time ─── operational KPI
├── Schedule Attainment ─── supporting
└── Energy Consumption per Unit ─── operational KPI
│
Quality Control Dashboard
├── Defect Rate ─── primary KPI
├── First Pass Yield ─── supporting
├── Scrap Rate ─── operational KPI
├── Defect Pareto (by type) ─── diagnostic
└── SPC Charts (Cp, Cpk) ─── diagnostic
│
Maintenance & Reliability Dashboard
├── MTBF ─── primary KPI
├── MTTR ─── primary KPI
├── Planned vs. Unplanned Ratio ─── operational KPI
├── Downtime by Machine ─── diagnostic
└── Top Failure Modes ─── diagnostic
```

---

## 15. KPI Targets Summary

| KPI                        | Current Baseline | Target              | Target Date | Owner       |
|----------------------------|------------------|---------------------|-------------|-------------|
| OEE (Overall)              | 68%              | 82%                 | Q4 2027     | DEPT-OPS    |
| Availability               | 78%              | 88%                 | Q4 2027     | DEPT-MNT    |
| Performance                | 84%              | 91%                 | Q4 2027     | DEPT-OPS    |
| Quality (OEE Component)    | 97.2%            | 99.1%               | Q4 2027     | DEPT-QA     |
| Defect Rate                | 2.8%             | <1.5%               | Q2 2027     | DEPT-QA     |
| MTBF (CNC fleet avg)       | 21 days          | 38+ days            | Q4 2026     | DEPT-MNT    |
| MTTR (unplanned avg)       | 4.8 hours        | <1.5 hours          | Q4 2026     | DEPT-MNT    |
| Throughput vs. Plan        | ~91%             | ≥98%                | Q2 2027     | DEPT-OPS    |
| Cycle Time Efficiency      | ~88%             | ≥95%                | Q4 2027     | DEPT-OPS    |
| Energy per Good Unit       | 4.2 kWh/unit     | <3.6 kWh/unit       | Q4 2027     | DEPT-ENG    |
| Production Efficiency      | ~89%             | ≥97%                | Q4 2027     | DEPT-PLN    |
| Scrap Rate                 | 2.8%             | <1.5%               | Q2 2027     | DEPT-QA     |
| Planned Maintenance Ratio  | 58%              | ≥70%                | Q2 2026     | DEPT-MNT    |
| Reporting Latency          | 24–48 hours      | <2 hours            | Q1 2026     | DEPT-IT     |

---

*This document is the authoritative definition of all KPIs tracked and reported within the SMAP platform. All dbt model logic, dashboard metric cards, and ML model targets must align with the formulas and targets defined here. Changes to any KPI formula require a documented ADR and an update to this document. Last reviewed: 2026-07-22.*
