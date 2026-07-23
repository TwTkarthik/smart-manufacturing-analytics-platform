# Business Problems — PrecisionEdge Manufacturing Ltd.

**Document Version:** 1.0.0
**Last Updated:** 2026-07-22
**Status:** Approved — Business Domain Baseline
**Owner:** Business Analysis Lead
**Related Documents:** [COMPANY_PROFILE.md](./COMPANY_PROFILE.md) · [KPI_DEFINITIONS.md](./KPI_DEFINITIONS.md) · [MANUFACTURING_PROCESS.md](./MANUFACTURING_PROCESS.md)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Problem 1 — Unplanned Machine Downtime](#2-problem-1--unplanned-machine-downtime)
3. [Problem 2 — Quality Defects and Hidden Yield Loss](#3-problem-2--quality-defects-and-hidden-yield-loss)
4. [Problem 3 — Energy Waste and Idle Consumption](#4-problem-3--energy-waste-and-idle-consumption)
5. [Problem 4 — Inventory Inefficiencies](#5-problem-4--inventory-inefficiencies)
6. [Problem 5 — Manual, Delayed Reporting](#6-problem-5--manual-delayed-reporting)
7. [Problem 6 — Siloed Data Systems](#7-problem-6--siloed-data-systems)
8. [Problem Impact Summary](#8-problem-impact-summary)
9. [How SMAP Addresses Each Problem](#9-how-smap-addresses-each-problem)

---

## 1. Overview

PrecisionEdge Manufacturing Ltd. faces a set of interconnected operational challenges that are common across mid-sized discrete manufacturers: data exists in large volumes but cannot be acted upon quickly or reliably. The root cause is not a shortage of data — it is a shortage of *usable, consolidated, timely* data.

This document enumerates the six major business problems that the Smart Manufacturing Analytics Platform (SMAP) is designed to address. Each problem is described with:
- The current state and root cause
- The observable symptoms and business impact
- Quantified cost or performance penalty where measurable
- The specific gap that SMAP closes

---

## 2. Problem 1 — Unplanned Machine Downtime

### 2.1 Description

Machine breakdowns are discovered only after they occur. When a machine fails unexpectedly, it halts production on the entire line segment it anchors, dispatches a maintenance technician (who must diagnose the fault before repair can begin), and triggers a cascade of downstream effects: operator idle time, production rescheduling, potential missed customer shipments, and overtime to recover lost output.

### 2.2 Root Cause

The primary root cause is **absence of predictive signal**. While machines are equipped with IoT sensors, the sensor data is currently:
- Monitored in real-time only by the SCADA system (for immediate safety alarms)
- Not analyzed for trending patterns that precede failure
- Not correlated with maintenance history to identify failure precursors
- Not surfaced to maintenance planners in a forward-looking format

The SCADA system's threshold-based alerts trigger only at the moment of or just before failure — too late to schedule a planned repair. There is no mechanism to detect the slow degradation patterns (e.g., gradually increasing spindle vibration over 14 days) that are reliable early indicators of impending failure.

### 2.3 Symptoms

| Symptom                                     | Observed Frequency / Magnitude              |
|---------------------------------------------|---------------------------------------------|
| Unplanned machine stops during active shifts | ~3.2 events per day across all 4 lines (PLT-DET) |
| Average time to repair (MTTR)               | 4.8 hours per unplanned event               |
| Emergency parts expediting                   | ~6 emergency purchase orders per month      |
| Production rescheduling events               | ~14 rescheduling events per month           |
| Overtime hours to recover downtime           | ~280 overtime hours per month               |

### 2.4 Business Impact

| Impact Category                   | Annual Cost / Magnitude                     |
|-----------------------------------|---------------------------------------------|
| Lost production (opportunity cost) | ~$3.6 million/year (based on margin lost per downtime hour) |
| Emergency maintenance labor        | ~$420,000/year                              |
| Emergency parts premium            | ~$280,000/year (expediting surcharges)      |
| Customer delivery penalties        | ~$180,000/year (contractual late delivery fines) |
| **Total estimated annual impact**  | **~$4.5 million/year**                      |

### 2.5 Current State vs. Desired State

| Dimension          | Current State                                     | Desired State (with SMAP)                         |
|--------------------|---------------------------------------------------|---------------------------------------------------|
| Detection          | Failure discovered at breakdown                   | Failure predicted 7+ days before occurrence       |
| Response           | Reactive; emergency dispatch                      | Proactive; scheduled during planned PM window     |
| MTBF               | 21 days (avg across CNC fleet)                    | 38+ days (target after predictive maintenance implementation) |
| MTTR               | 4.8 hours (unplanned)                             | 1.2 hours (planned, kitted repair)                |
| Unplanned downtime | 12.4% of scheduled production time                | <7% (target)                                      |

---

## 3. Problem 2 — Quality Defects and Hidden Yield Loss

### 3.1 Description

Quality defects are detected **after the production run**, not during it. By the time a quality technician completes a final inspection and identifies a defect pattern, the machine has already produced a full batch of potentially non-conforming parts. The entire batch must be sorted (100% inspection), reworked, or scrapped.

### 3.2 Root Cause

The root cause is a **disconnect between process parameters and quality outcomes**. Process parameters (spindle temperature, cutting force, feed rate, tool wear state) that directly influence part quality are captured by sensors, but this data is:
- Not correlated in real-time with incoming inspection results
- Not used to predict which production runs are at elevated defect risk
- Not fed into SPC control systems with sufficient speed to trigger corrective action before a run is complete

Additionally, in-process inspection is performed at a fixed sampling frequency (every 10th part) regardless of process stability. When a machine drifts into a non-conforming condition at part 15 of 500, the defect may not be detected until the next scheduled sample at part 20 — by which time 5–15 additional defective parts have been produced.

### 3.3 Symptoms

| Symptom                                       | Observed Frequency / Magnitude             |
|-----------------------------------------------|--------------------------------------------|
| Overall scrap rate                            | 2.8% of total units produced               |
| Overall rework rate                           | 1.4% of total units produced               |
| Defect escapes to customer (PPM)              | ~1,800 PPM (target: <500 PPM per contracts)|
| Customer quality complaints / 8D reports      | ~8 per month                               |
| Production lots placed on quality hold         | ~22 per month                              |
| Average hold resolution time                  | 18 hours per hold event                    |

### 3.4 Business Impact

| Impact Category                   | Annual Cost / Magnitude                     |
|-----------------------------------|---------------------------------------------|
| Scrapped material cost             | ~$8.4 million/year                          |
| Rework labor cost                  | ~$1.2 million/year                          |
| Quality hold overhead              | ~$640,000/year (labor for sorting, retesting, re-inspection) |
| Customer warranty and returns      | ~$320,000/year                              |
| Customer scorecard penalties (loss of preferred supplier status risk) | Unquantified strategic risk |
| **Total estimated annual impact**  | **~$10.6 million/year**                     |

### 3.5 Current State vs. Desired State

| Dimension          | Current State                                     | Desired State (with SMAP)                              |
|--------------------|---------------------------------------------------|---------------------------------------------------------|
| Defect detection   | End-of-run final inspection                        | In-process SPC alert + ML-predicted quality risk score  |
| Scrap rate         | 2.8%                                              | <1.5% (target)                                          |
| Customer PPM       | ~1,800 PPM                                        | <500 PPM (contractual target)                           |
| Quality visibility | 24–48 hr lag (manual report compilation)           | Real-time SPC charts; shift-level defect rate dashboard |
| Process control    | Reactive (correct after defect found)              | Proactive (correct when process parameters drift)       |

---

## 4. Problem 3 — Energy Waste and Idle Consumption

### 4.1 Description

Production machines consume significant electricity even when they are not producing parts. CNC machining centers, hydraulic systems, and conveyor systems remain energized during shift breaks, between production orders, and during unplanned downtime events. This idle energy consumption is currently invisible to operations management — there is no system that tracks energy consumption at the machine level or correlates energy cost with production output.

### 4.2 Root Cause

The root cause is a **lack of machine-level energy metering and visibility**. While PLT-DET pays for energy at the facility level (billed by the utility company on a monthly basis), there is no sub-metering data that breaks down consumption by:
- Machine or production line
- Production vs. idle state
- Shift or time-of-day
- Production order or product type

Power consumption sensors (`SEN-POWER`) are installed on all 48 machines but the data they generate is not currently analyzed or reported — it flows into the SCADA system and is overwritten.

### 4.3 Symptoms

| Symptom                                      | Observed Magnitude                         |
|----------------------------------------------|---------------------------------------------|
| Energy cost per good unit produced           | ~$1.26/unit (at $0.30/kWh blended rate)    |
| Estimated idle energy as % of total          | ~18–22% of total facility energy consumption |
| Shift changeover energy (machines left running) | ~45 minutes of idle consumption per machine per shift end |
| Overnight weekend idle consumption (LINE-D)  | Estimated ~280 kWh/weekend of avoidable idle consumption |
| Machine-level energy tracking capability     | Zero — no machine-level data available      |

### 4.4 Business Impact

| Impact Category                   | Annual Cost / Magnitude                     |
|-----------------------------------|---------------------------------------------|
| Total facility energy bill         | ~$6.8 million/year                          |
| Estimated avoidable idle energy cost | ~$1.1–1.4 million/year                    |
| Carbon footprint (reporting risk)  | ~4,200 tonnes CO2e/year; increasing customer ESG audit requirements |
| **Addressable annual savings (target −15%)** | **~$1.0 million/year**              |

### 4.5 Current State vs. Desired State

| Dimension            | Current State                              | Desired State (with SMAP)                        |
|----------------------|--------------------------------------------|--------------------------------------------------|
| Energy visibility    | Facility-level only; monthly billing       | Machine-level; real-time energy dashboard        |
| Energy per unit      | Unknown (estimated from billing)           | Calculated per production order                  |
| Idle detection       | None                                       | Automated idle detection from power sensor data  |
| Optimization trigger | None                                       | Operator/supervisor alerts for extended idle states |

---

## 5. Problem 4 — Inventory Inefficiencies

### 5.1 Description

PrecisionEdge maintains raw material, work-in-process (WIP), and spare parts inventories that are systematically over- or under-stocked. Raw material shortages cause production stoppages when a production order cannot start because stock is unavailable. Over-stocking ties up working capital and creates material handling complexity. Spare parts for maintenance are often unavailable when needed (causing extended downtime) or excess in the storeroom (tying up capital in rarely-used parts).

### 5.2 Root Cause

Two distinct root causes drive inventory inefficiency:

**1. Production demand signal latency:** The ERP system's material requirements planning (MRP) module calculates raw material replenishment needs based on the Master Production Schedule. However, when the MPS changes (due to customer order changes, production schedule revisions, or machine downtime-driven rescheduling), the MRP recalculation runs only nightly — creating a 24-hour lag before updated material requirements are reflected. This lag causes stock-outs when production needs change rapidly.

**2. Reactive spare parts management:** Spare parts for maintenance are ordered reactively after they are consumed, with no data-driven model for stock level optimization. Because the predictive maintenance capability does not yet exist, there is no way to anticipate which parts will be needed 7–14 days in advance — so parts are either over-stocked as safety stock or unavailable at the moment of need.

### 5.3 Symptoms

| Symptom                                         | Observed Frequency / Magnitude          |
|-------------------------------------------------|-----------------------------------------|
| Raw material stock-outs causing production stops | ~3.2 events per month                  |
| Excess raw material write-offs                   | ~$280,000/year                          |
| Spare part stock-outs during maintenance events  | ~4.6 events per month                   |
| Emergency spare part expediting orders           | ~6 per month (premium freight cost)     |
| Average WIP inventory holding time               | 3.8 days (target: <1.5 days)            |
| Spare parts storeroom value (excess)             | ~$1.4 million in slow-moving parts      |

### 5.4 Business Impact

| Impact Category                   | Annual Cost / Magnitude                     |
|-----------------------------------|---------------------------------------------|
| Production stops from material shortages | ~$480,000/year (downtime cost)        |
| Emergency expediting (raw materials)     | ~$140,000/year                        |
| Emergency expediting (spare parts)       | ~$280,000/year                        |
| Excess inventory carrying cost           | ~$210,000/year (interest + space)     |
| **Total estimated annual impact**  | **~$1.1 million/year**                      |

### 5.5 Current State vs. Desired State

| Dimension               | Current State                              | Desired State (with SMAP)                               |
|-------------------------|--------------------------------------------|----------------------------------------------------------|
| Raw material planning   | Nightly MRP batch; 24-hr lag              | Near-real-time demand signal from production actuals     |
| Spare parts planning    | Reactive; no predictive signal             | SMAP maintenance model predicts parts 7–14 days ahead    |
| WIP visibility          | Partial (ERP work-in-process tracking)     | Full WIP visibility correlated with production pace data  |
| Inventory reporting     | Monthly finance report                     | Daily inventory analytics dashboard                      |

---

## 6. Problem 5 — Manual, Delayed Reporting

### 6.1 Description

Every operational KPI report that reaches a manager or executive at PrecisionEdge is assembled manually. At the close of each shift, each production supervisor compiles a shift report by querying three separate systems (MES, ERP, and a SCADA-connected spreadsheet), copy-pasting data into a shared Excel template, and emailing it to their manager. The manager then consolidates shift reports into a daily report. The daily report is consolidated into a weekly report.

By the time a weekly KPI summary reaches the Operations Director, the data is between 3 and 7 days old.

### 6.2 Root Cause

The root cause is a **complete absence of an integrated reporting layer**. Each source system (ERP, MES, SCADA) has its own reporting interface, but:
- None of the systems share a common data model or key
- Cross-system analysis (e.g., correlating downtime events with quality outcomes) requires manual data extraction from multiple systems and manual VLOOKUP-style reconciliation
- There is no central data store where combined operational metrics can be queried
- IT does not have the bandwidth to build and maintain custom reports for each operational team

### 6.3 Symptoms

| Symptom                                         | Observed Frequency / Magnitude          |
|-------------------------------------------------|-----------------------------------------|
| Time from shift close to KPI report delivery    | 24–48 hours (target: <2 hours)          |
| Supervisor time spent on reporting per shift    | ~45–60 minutes                          |
| Frequency of data entry errors in manual reports | ~8–12% of report fields contain errors in any given week |
| Cross-system analysis capability                | None — requires IT engagement (3–5 day turnaround) |
| Dashboard / BI tool availability                | None for operational teams              |
| Ad-hoc data request backlog (IT queue)          | ~22 open requests, average 8-day resolution time |

### 6.4 Business Impact

| Impact Category                    | Annual Cost / Magnitude                     |
|------------------------------------|---------------------------------------------|
| Supervisor reporting labor cost     | ~$340,000/year (based on time × headcount across all lines) |
| Decisions made on stale data        | Unquantified; contributes to delayed response to quality and downtime events |
| Report error correction rework      | ~$60,000/year (time spent correcting and re-issuing reports) |
| IT ad-hoc request opportunity cost  | ~$140,000/year (IT labor diverted from development to data extraction) |
| **Total estimated annual impact**   | **~$540,000/year (direct); significant unquantified indirect cost** |

### 6.5 Current State vs. Desired State

| Dimension               | Current State                              | Desired State (with SMAP)                              |
|-------------------------|--------------------------------------------|--------------------------------------------------------|
| Reporting latency        | 24–48 hours                               | <2 hours (automated ETL refresh)                       |
| Report creation          | Manual; supervisor-assembled Excel         | Automated; always-on dashboard                         |
| Cross-system analysis    | Requires IT (3–5 day queue)               | Self-service in SMAP dashboard                         |
| Data accuracy            | 8–12% error rate (manual entry)            | Source-system accuracy; validated at ingestion by Great Expectations |
| Report frequency         | Shift → Daily → Weekly (escalating delays) | Real-time to hourly refresh; executive summary always current |

---

## 7. Problem 6 — Siloed Data Systems

### 7.1 Description

PrecisionEdge operates three primary operational systems — ERP (SAP S/4HANA), MES (MachineLink), and SCADA (Siemens WinCC) — that capture complementary operational data but have no integration layer connecting them. Each system captures one dimension of the same production event but with no shared key or common data model.

### 7.2 Root Cause

The systems were implemented at different points in the company's history by different vendors, without an enterprise integration architecture in place:

- **ERP (SAP S/4HANA):** Implemented in 2009; manages financial, supply chain, and production planning data. Its production order data is not synchronized with the MES in real-time.
- **MES (MachineLink):** Implemented in 2014; manages the shop floor execution — dispatches orders, captures actual counts and cycle times, records downtime events. Uses its own order numbering scheme with a mapping table to ERP order numbers.
- **SCADA (Siemens WinCC):** Upgraded in 2018; captures sensor telemetry at the machine level. References machines by their PLC tag name (not the same ID used in MES or ERP).

The result is that analyzing a question like *"What is the relationship between spindle temperature and defect rate for PRD-001 on LINE-A?"* requires joining three separate systems with three different identifiers — a task that is only achievable by IT staff with access to all three systems.

### 7.3 Impact on Analytics

| Analytical Question                                    | Silo Barrier                                              |
|--------------------------------------------------------|-----------------------------------------------------------|
| OEE calculation (planned qty from ERP × actual from MES) | Requires ERP + MES join across different order IDs        |
| Sensor anomaly → downtime correlation                  | SCADA machine tags ≠ MES machine IDs; no automatic join   |
| Quality defect rate by shift / operator                | MES quality data + ERP shift schedule + HR operator roster |
| Energy cost per production order                       | SCADA power readings + ERP order data + MES timing data   |
| Predictive maintenance feature engineering             | SCADA sensor history + MES maintenance records + ERP parts data |

### 7.4 Current State vs. Desired State

| Dimension             | Current State                              | Desired State (with SMAP)                              |
|-----------------------|--------------------------------------------|--------------------------------------------------------|
| Data integration      | None; three isolated systems               | Unified data warehouse with a single, joined analytical model |
| Cross-system analysis | IT-only; 3–5 day queue                    | Self-service; pre-joined in star schema                |
| Master data alignment | Three different ID schemes                 | SMAP ETL layer maps all source IDs to warehouse surrogate keys |
| Historical data        | Locked in source systems; no combined history | Persistent warehouse with 2+ years of cross-system history |

---

## 8. Problem Impact Summary

| Business Problem          | Est. Annual Cost / Impact            | SMAP Priority   |
|---------------------------|--------------------------------------|-----------------|
| Unplanned Downtime        | ~$4.5 million/year                   | **Critical**    |
| Quality Defects / Yield Loss | ~$10.6 million/year               | **Critical**    |
| Energy Waste              | ~$1.1–1.4 million/year (avoidable)   | High            |
| Inventory Inefficiencies  | ~$1.1 million/year                   | High            |
| Manual Reporting Delays   | ~$540,000/year (direct)              | Medium          |
| Siloed Data Systems       | Enabling root cause of all above     | **Foundation**  |
| **Total Addressable Impact** | **~$17.8–18.2 million/year**     |                 |

> The total addressable impact represents the theoretical maximum value if all problems are fully resolved. Realistic improvement targets — accounting for partial automation, change management, and implementation timelines — are documented in the KPI targets within [KPI_DEFINITIONS.md](./KPI_DEFINITIONS.md).

---

## 9. How SMAP Addresses Each Problem

| Business Problem          | SMAP Capability                                    | Expected Outcome                                    |
|---------------------------|----------------------------------------------------|-----------------------------------------------------|
| Unplanned Downtime        | Predictive Maintenance ML model + Anomaly Detection | 7-day advance failure warning; −40% unplanned stops |
| Quality Defects           | Quality Prediction ML model + Real-time SPC charts | In-run defect risk scoring; −46% scrap rate         |
| Energy Waste              | IoT energy sensor ingestion + Energy KPI dashboard  | Machine-level energy visibility; −15% energy/unit   |
| Inventory Inefficiencies  | Demand signal from production actuals + Maintenance forecast | Spare parts pre-positioning; stock-out reduction   |
| Reporting Delays          | Automated ETL pipeline + Near-real-time dashboards  | <2hr reporting latency; eliminate manual Excel reports |
| Siloed Data Systems       | Unified data warehouse + ETL integration layer      | Single source of truth; self-service cross-system analytics |

---

*This document defines the business problems that motivate the SMAP platform. All KPI targets, analytical use cases, and ML model objectives are traceable to one or more of the problems described here. Last reviewed: 2026-07-22.*
