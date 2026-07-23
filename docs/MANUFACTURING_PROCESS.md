# Manufacturing Process — PrecisionEdge Manufacturing Ltd.

**Document Version:** 1.0.0
**Last Updated:** 2026-07-22
**Status:** Approved — Business Domain Baseline
**Owner:** Business Analysis Lead
**Related Documents:** [COMPANY_PROFILE.md](./COMPANY_PROFILE.md) · [DATA_SOURCES.md](./DATA_SOURCES.md) · [KPI_DEFINITIONS.md](./KPI_DEFINITIONS.md)

---

## Table of Contents

1. [End-to-End Production Workflow](#1-end-to-end-production-workflow)
2. [Production Lines](#2-production-lines)
3. [Machines & Equipment](#3-machines--equipment)
4. [Operators](#4-operators)
5. [Sensors & Telemetry](#5-sensors--telemetry)
6. [Maintenance Workflow](#6-maintenance-workflow)
7. [Quality Inspection Process](#7-quality-inspection-process)

---

## 1. End-to-End Production Workflow

The PLT-DET (Detroit Main Plant) production workflow spans nine sequential stages from customer order receipt to finished goods shipment. The workflow is governed by the Manufacturing Execution System (MES) and the ERP system, with real-time sensor telemetry generated at every stage on the production floor.

### 1.1 High-Level Workflow

```
[Customer Order] → [Production Planning] → [Material Release] → [Machining / Forming]
    → [In-Process QC] → [Final Inspection] → [Assembly / Sub-assembly] → [Packaging] → [Shipment]
```

### 1.2 Detailed Stage Descriptions

#### Stage 1 — Order Receipt & Scheduling

**Owner:** DEPT-PLN (Production Planning)

A customer purchase order (PO) is received by the Sales team and entered into the ERP system. Production Planning converts the PO into one or more **Production Orders** (internal work orders), assigns each production order to a specific production line and shift, and sequences the orders into the weekly Master Production Schedule (MPS).

**Key data generated:** Production order record, planned start/end times, target unit quantity, product code, machine assignment.

**Key constraints:** Machine capacity, tooling availability, raw material stock on hand, shift capacity.

#### Stage 2 — Material Release & Setup

**Owner:** DEPT-SCM, DEPT-OPS

Raw material (steel billets, castings, bar stock) is pulled from the raw material warehouse and staged at the designated machine cell. A machine operator receives the production order on the machine's HMI (Human-Machine Interface) or paper traveler and performs the **setup**: installing the correct tooling, fixtures, and jaws; loading the part program (CNC code); and verifying setup with first-article inspection.

**Key data generated:** Material lot number, setup start time, tool change records, first-article inspection result.

**Typical setup time:** 20–90 minutes depending on product complexity and last-run product changeover.

#### Stage 3 — Production Run (Machining / Forming)

**Owner:** DEPT-OPS (Operators on the floor)

The machine executes the production run autonomously (for CNC machines) or semi-autonomously (for press and assembly operations with operator-assisted loading). The machine cycles continuously, producing parts at the target cycle time.

During the production run, IoT sensors mounted on the machine continuously capture:
- Temperature (spindle, coolant, hydraulic oil)
- Vibration (spindle, gearbox, tool holder)
- Spindle RPM and feed rate
- Hydraulic and pneumatic pressure
- Cutting force (on equipped machines)
- Power consumption (kWh per cycle)

Sensor readings are written to the source database every **30 seconds** during active machining.

**Key data generated:** Sensor telemetry (high-volume), actual units counter (incremented per cycle), cycle time per unit, spindle load logs.

#### Stage 4 — In-Process Quality Control

**Owner:** DEPT-QA (Quality Technicians) and automated gauging systems

During the production run, quality checks are performed at a defined **inspection frequency** (e.g., every 10th part, or triggered by a statistically defined control interval). In-process inspection results are logged against the active production order.

Two inspection methods are used:
- **Manual gauging:** Quality technician uses calibrated hand gauges (micrometers, bore gauges, CMM spot checks) for dimensional measurement
- **Automated in-process gauging:** On-machine probing or post-machine gauging cells that automatically measure and feed results back to the MES

**Key data generated:** Inspection record per sample (sample size, defects found, measurement value, pass/fail, defect type code, inspector ID).

#### Stage 5 — Machine Stop Events (Planned and Unplanned)

During any production run, the machine may stop due to:

| Stop Category | Type       | Examples                                              |
|---------------|------------|-------------------------------------------------------|
| **Planned**   | Scheduled  | Shift end, tooling change at interval, PM window      |
| **Unplanned** | Breakdown  | Mechanical failure, electrical fault, hydraulic leak  |
| **Unplanned** | Process    | Tool breakage, coolant fault, part jam in fixture     |
| **Minor**     | Short stop | Chip accumulation, part loading error (<5 min)        |

All stop events are recorded by the operator via the MES touchscreen or automatically by the machine controller. Stop duration and stop reason code are logged for each event.

**Key data generated:** Downtime event record (start, end, duration, reason code, machine ID, operator ID).

#### Stage 6 — Final Inspection

**Owner:** DEPT-QA

Completed production lots undergo a final quality inspection before release to finished goods. Final inspection involves:
- **100% inspection** for safety-critical or high-tolerance features (e.g., bearing journal diameter, brake caliper bore)
- **Sampling inspection** per AQL (Acceptance Quality Level) plan for non-critical features
- **Functional testing** where applicable (pressure test for brake calipers, leak test for steering housings)

The pass/fail result for the entire production order is recorded in the MES Quality module. Failed lots are placed on **material hold** pending disposition (rework, scrap, or customer deviation).

#### Stage 7 — Assembly / Sub-assembly (where applicable)

**Owner:** DEPT-OPS (Assembly operators)

Some product lines require assembly operations after machining: pressing in bearings, installing seals, torquing fasteners, or building up sub-assemblies. These operations are performed at dedicated assembly cells on LINE-D.

Assembly operations generate their own cycle time, operator ID, and quality records.

#### Stage 8 — Packaging & Labeling

**Owner:** DEPT-OPS

Finished, inspected parts are packaged per customer packaging specification (rack, dunnage tray, bulk container). Labels are printed from the ERP system with traceability data (production order, date of manufacture, material lot, plant code).

#### Stage 9 — Shipment

**Owner:** DEPT-SCM

Packaged goods are transferred to the finished goods warehouse, confirmed against the shipping order in ERP, and loaded for outbound shipment. Shipment confirmation triggers an inventory transaction and closes the production order in ERP.

### 1.3 Workflow Data Flow

```
ERP System               MES (MachineLink MES)          Sensor Network (SCADA)
    │                          │                                │
    │ Production Order         │ Order dispatched to machine    │ Continuous telemetry
    │ (planned qty, schedule)  │ Start/stop events              │ (temp, vibration, RPM,
    │                          │ Actual unit count              │  pressure, power)
    │                          │ Downtime reason codes          │
    │                          │ Quality inspection results     │
    ▼                          ▼                                ▼
                    [Source Database — Operational Layer]
                           ↓
                    [SMAP ETL Pipeline]
                           ↓
                    [Data Warehouse — Analytics Layer]
                           ↓
                    [Dashboards / API / ML Models]
```

---

## 2. Production Lines

The PLT-DET facility operates four production lines. Each line is a dedicated grouping of machines, tooling, and operator cells configured for a family of related operations.

### 2.1 Production Line Summary

| Line Code | Line Name                  | Primary Operation         | Products               | Machines | Shift Pattern              |
|-----------|----------------------------|---------------------------|------------------------|----------|----------------------------|
| **LINE-A** | Powertrain Turning Cell   | CNC Turning & Grinding    | PRD-001, PRD-002       | 12       | 3-shift, 6 days/week       |
| **LINE-B** | Brake Components Cell     | CNC Milling & Boring      | PRD-003, PRD-004       | 10       | 3-shift, 6 days/week       |
| **LINE-C** | Steering & Suspension Cell | CNC Turning, Boring       | PRD-005, PRD-006       | 9        | 3-shift, 5 days/week       |
| **LINE-D** | Multi-Process / Assembly  | Mixed machining + assembly | PRD-007, PRD-008 + assembly | 17  | 2-shift, 5 days/week       |

### 2.2 Production Line Configuration

#### LINE-A — Powertrain Turning Cell

LINE-A is the highest-volume line in the plant, producing crankshaft bearing journals and transmission gear blanks. It runs as close to lights-out as possible with robotic part loading on 6 of its 12 machines.

- **Flow:** Bar stock → CNC turning center → In-process gauging → OD grinding → CMM spot check → Material transfer to warehouse
- **Bottleneck station:** OD grinding — longest cycle time, highest maintenance sensitivity
- **Takt time target:** 2.5 minutes per unit (across the line)
- **Planned OEE target:** 81%

#### LINE-B — Brake Components Cell

LINE-B produces safety-critical brake components subject to 100% pressure testing. The line is configured in a U-cell layout for efficient operator material handling.

- **Flow:** Casting blank → CNC milling center → Deburring → Pressure test (100%) → CMM → Washing → Assembly (seals/boots) → Final inspection
- **Bottleneck station:** CMM (Coordinate Measuring Machine) — throughput-limited by measurement cycle time
- **Takt time target:** 3.8 minutes per unit
- **Planned OEE target:** 78%

#### LINE-C — Steering & Suspension Cell

LINE-C produces steering and suspension components requiring tight positional tolerances and multi-stage turning operations.

- **Flow:** Forging blank → CNC lathe → Drill/tap center → Leak test (steering housings) → CMM → Surface finish verification
- **Takt time target:** 4.2 minutes per unit
- **Planned OEE target:** 76%

#### LINE-D — Multi-Process / Assembly

LINE-D is the most complex and flexible line, handling a mix of industrial components and all assembly operations for the plant.

- **Flow (machining):** Raw material → CNC machining center → Inspection → Packaging
- **Flow (assembly):** Machined components from all lines → Assembly cell → Functional test → Packaging
- **Takt time target:** Varies by product (3.0–8.5 minutes/unit)
- **Planned OEE target:** 72%

---

## 3. Machines & Equipment

### 3.1 Machine Types

| Machine Type Code | Machine Type           | Count (PLT-DET) | Typical Application                        | Sensor-Equipped |
|-------------------|------------------------|------------------|--------------------------------------------|-----------------|
| **MCH-LATHE**     | CNC Turning Center     | 14               | Crankshafts, gear blanks, cylinder barrels | Yes             |
| **MCH-MILL**      | CNC Machining Center   | 11               | Housings, brackets, flanges                | Yes             |
| **MCH-GRIND**     | CNC Grinding Machine   | 6                | Bearing journals, OD/ID grinding           | Yes             |
| **MCH-PRESS**     | Hydraulic Press        | 4                | Bearing press-in, seal installation        | Yes             |
| **MCH-CMM**       | CMM (Inspection)       | 3                | Dimensional verification                   | Partial          |
| **MCH-CONV**      | Conveyor System        | 6                | Inter-process material transfer            | Partial          |
| **MCH-ASSY**      | Assembly Station       | 4                | Manual/semi-auto assembly                  | No              |

### 3.2 Machine Naming Convention

Each machine has a unique identifier following the pattern: `{TYPE}-{SEQUENCE}-{PLANT}`

Examples:
- `MCH-LATHE-001-DET` — First CNC turning center at PLT-DET
- `MCH-MILL-003-DET` — Third CNC machining center at PLT-DET
- `MCH-GRIND-001-DET` — First grinding machine at PLT-DET

In the SMAP data model, machines are identified by the simplified `machine_id` field (e.g., `MCH-001` through `MCH-048`), with full details stored in the `dim_machine` dimension table.

### 3.3 Machine Performance Profile

| Machine Type    | Rated Capacity (units/hr) | Typical OEE | MTBF (days) | Common Failure Modes                        |
|-----------------|---------------------------|-------------|-------------|---------------------------------------------|
| CNC Turning     | 14–22 units/hr            | 79%         | 28          | Tool breakage, spindle bearing wear, coolant issues |
| CNC Milling     | 8–15 units/hr             | 76%         | 35          | Spindle overload, toolholder wear, axis drive fault |
| CNC Grinding    | 5–10 units/hr             | 74%         | 21          | Wheel dressing frequency, coolant filtration, vibration |
| Hydraulic Press | 20–45 units/hr            | 82%         | 45          | Hydraulic seal failure, die wear, overload trip |
| Conveyor        | Continuous flow           | 91%         | 60          | Belt wear, sensor fault, jam                 |

---

## 4. Operators

### 4.1 Operator Roles

The production floor is staffed by four distinct operator role types, each with defined responsibilities and data touchpoints.

| Role Code    | Role Title              | Responsibilities                                                               | Data Interactions                          |
|--------------|-------------------------|--------------------------------------------------------------------------------|--------------------------------------------|
| **OPR-MCH**  | Machine Operator        | Load/unload parts, monitor machine during run, respond to machine faults, perform minor adjustments | Production order start/stop, downtime reason codes, unit counts |
| **OPR-SET**  | Setup Technician        | Perform tooling changes, machine setup, first-article inspection               | Setup records, first-article results, tool change events |
| **OPR-QC**   | Quality Control Technician | In-process inspection, final inspection, CMM operation, SPC chart maintenance | Inspection records, measurement values, defect logs |
| **OPR-MNT**  | Maintenance Technician  | Respond to breakdowns, execute PM tasks, complete work orders                  | Work order records, parts used, MTTR data  |

### 4.2 Shift Structure

PLT-DET operates three production shifts. All shifts generate data that is captured by the MES and attributed to the correct shift and operator.

| Shift Code  | Shift Name    | Hours                  | Days Active         | Supervisor Role         |
|-------------|---------------|------------------------|---------------------|-------------------------|
| **SHIFT-A** | Day Shift     | 06:00 – 14:00 (8 hrs)  | Monday – Saturday   | Day Shift Production Supervisor |
| **SHIFT-B** | Afternoon Shift | 14:00 – 22:00 (8 hrs) | Monday – Saturday   | Afternoon Shift Supervisor |
| **SHIFT-C** | Night Shift   | 22:00 – 06:00 (8 hrs)  | Monday – Friday (5 nights) | Night Shift Supervisor |

**Overlap windows:** Each shift has a 15-minute handover overlap for operational briefing and issue escalation. This overlap time is excluded from the OEE planned production time calculation.

### 4.3 Operator Data Attribution

Every production event is attributed to the operator on duty at the time of the event. Operator IDs follow the pattern `EMP-XXXX` (e.g., `EMP-0142`). Operator identity is used in SMAP for:

- Shift-level and operator-level performance analysis (aggregated — no personal performance scoring)
- Quality inspection traceability (inspector attribution on each inspection record)
- Maintenance work order assignment and MTTR accountability
- Workforce training needs analysis (correlation between operator experience level and quality outcomes)

---

## 5. Sensors & Telemetry

### 5.1 Sensor Network Overview

PLT-DET operates a network of **384 IoT sensors** distributed across all 48 production machines. Sensors are connected via an industrial ethernet (Profinet) network to a SCADA system (Siemens WinCC) that writes sensor readings to the operational source database.

### 5.2 Sensor Types

| Sensor Type Code | Measurement       | Unit   | Sampling Rate | Machines Equipped              | Normal Operating Range         |
|------------------|-------------------|--------|---------------|-------------------------------|-------------------------------|
| **SEN-TEMP**     | Temperature       | °C     | Every 30 sec  | All 48 machines               | Spindle: 20–65°C; Coolant: 15–35°C; Oil: 30–70°C |
| **SEN-VIB**      | Vibration         | mm/s   | Every 30 sec  | CNC lathes, mills, grinders (31) | 0.5–4.5 mm/s RMS (ISO 10816) |
| **SEN-RPM**      | Spindle Speed     | RPM    | Every 30 sec  | CNC lathes, mills, grinders (31) | 200–8,000 RPM (product-dependent) |
| **SEN-PRES**     | Hydraulic Pressure | PSI   | Every 30 sec  | Presses, hydraulic systems (12) | 1,500–3,000 PSI              |
| **SEN-POWER**    | Power Consumption | kWh    | Every 60 sec  | All 48 machines               | 2–85 kW (machine-dependent)   |
| **SEN-FORCE**    | Cutting Force     | N      | Every 30 sec  | CNC turning centers (8 equipped) | 200–2,500 N                 |
| **SEN-FLOW**     | Coolant Flow Rate | L/min  | Every 60 sec  | CNC machines (31)             | 8–40 L/min                   |

### 5.3 Sensor Data Volumes

| Metric                          | Value                                   |
|---------------------------------|-----------------------------------------|
| **Total sensors**               | 384 sensors across PLT-DET              |
| **Reading frequency**           | 30–60 seconds per sensor                |
| **Readings per sensor per day** | ~1,440–2,880 readings                   |
| **Total readings per day**      | ~554,000–1,105,000 readings             |
| **Total readings per year**     | ~200–400 million readings               |
| **Data volume (Parquet, compressed)** | ~8–15 GB/year for PLT-DET         |

### 5.4 Sensor Anomaly Thresholds

The SCADA system flags sensor readings that exceed pre-configured control limits. These flags are written directly to the `is_anomaly_flagged` field in the source database. SMAP's ML anomaly detection model provides a more sophisticated multivariate anomaly score that accounts for inter-sensor correlations.

| Sensor Type | Anomaly Trigger Condition                                    | Escalation Action                          |
|-------------|--------------------------------------------------------------|--------------------------------------------|
| Temperature | > 80°C (spindle) or > 45°C (coolant)                        | Operator warning on HMI; auto-stop at critical limit |
| Vibration   | > 7.1 mm/s RMS (ISO 10816 Zone D)                           | Operator alert; production quality hold pending inspection |
| Hydraulic Pressure | Outside ±15% of set-point for > 60 seconds            | Machine fault; operator investigation required |
| Power       | > 120% of rated power for > 30 seconds                      | Overload protection trip                   |

### 5.5 Sensor-to-Maintenance Correlation

Sensor telemetry is the primary input feature for SMAP's **Predictive Maintenance** model. The following sensor signatures have been identified through maintenance history analysis as precursors to specific failure modes:

| Failure Mode                | Precursor Sensor Pattern                                   | Typical Lead Time Before Failure |
|-----------------------------|------------------------------------------------------------|----------------------------------|
| Spindle bearing failure     | Progressive vibration increase (>15% over 7 days) + temperature rise | 14–21 days                  |
| Coolant pump failure        | Coolant flow rate decline + coolant temperature increase    | 7–14 days                        |
| Hydraulic seal failure      | Pressure instability (increasing variance) + micro-leaks   | 3–10 days                        |
| Tool wear (catastrophic)    | Cutting force spike + vibration increase                   | <1 shift (rapid onset)           |
| Gearbox wear                | Vibration signature change (frequency domain shift)         | 21–45 days                       |

---

## 6. Maintenance Workflow

### 6.1 Maintenance Strategy

PrecisionEdge operates a blended maintenance strategy combining three approaches:

| Maintenance Strategy       | Description                                                | Current Share of Total Maintenance Events |
|----------------------------|------------------------------------------------------------|------------------------------------------|
| **Reactive / Corrective**  | Repair after failure; machine is down when maintenance begins | 42% (target: <20%)                  |
| **Preventive (PM)**        | Time-based or cycle-count-based scheduled maintenance       | 38%                                      |
| **Predictive (PdM)**       | Condition-based maintenance triggered by sensor anomaly or ML model alert | 20% (target: >50% with SMAP) |

The high reactive maintenance share (42%) is the primary driver of excessive unplanned downtime. SMAP's predictive maintenance capability is intended to shift this balance toward condition-based and preventive intervention.

### 6.2 Maintenance Event Types

| Event Type Code | Event Type        | Description                                                              | MES/ERP Record Created |
|-----------------|-------------------|--------------------------------------------------------------------------|------------------------|
| **EVT-PM**      | Planned Maintenance | Scheduled PM per maintenance calendar; machine taken out of production intentionally | Work Order (type: Planned) |
| **EVT-CM**      | Corrective Maintenance | Unplanned repair in response to machine breakdown or fault alarm          | Work Order (type: Unplanned) |
| **EVT-PdM**     | Predictive Maintenance | Maintenance triggered by SMAP alert or sensor anomaly threshold breach   | Work Order (type: Predictive) |
| **EVT-EM**      | Emergency Maintenance | Critical breakdown requiring immediate response; all other work stopped  | Work Order (type: Emergency) |
| **EVT-TOOL**    | Tooling Change    | Planned tool replacement at end-of-life interval                         | Tool Change Record      |

### 6.3 Maintenance Workflow Steps

```
[Failure / Alert / Schedule Trigger]
    │
    ▼
[Maintenance Request Created in ERP]
    │
    ├─ (Unplanned) → [Emergency Work Order opened; technician dispatched immediately]
    │
    └─ (Planned / PdM) → [Work Order scheduled for next available PM window]
                                │
                                ▼
                    [Technician assigned; parts/tools kitted]
                                │
                                ▼
                    [Machine isolated (LOTO — Lock Out/Tag Out)]
                                │
                                ▼
                    [Repair / PM task executed]
                                │
                                ▼
                    [Machine returned to service; technician signs off work order]
                                │
                                ▼
                    [Work Order closed in ERP — downtime_end recorded]
                                │
                                ▼
                    [Root cause and parts used documented]
                                │
                                ▼
                    [Work Order data flows to SMAP via nightly ETL]
```

### 6.4 Maintenance Data Captured

Each work order record captures the following data, which flows into the SMAP `fct_maintenance_event` fact table:

| Data Field          | Description                                              |
|---------------------|----------------------------------------------------------|
| `work_order_id`     | Unique work order identifier                             |
| `machine_id`        | Machine that required maintenance                        |
| `event_type`        | Planned / Unplanned / Emergency / Predictive             |
| `failure_code`      | Standardized failure category (see table below)          |
| `downtime_start`    | Timestamp when machine stopped for maintenance           |
| `downtime_end`      | Timestamp when machine returned to production            |
| `downtime_minutes`  | Calculated total downtime duration                       |
| `technician_id`     | Assigned maintenance technician                          |
| `repair_cost`       | Labor + parts cost of the maintenance event              |
| `parts_replaced`    | JSON array of replaced spare parts with part numbers     |
| `root_cause`        | Free-text root cause analysis (completed post-repair)    |

### 6.5 Failure Code Taxonomy

| Failure Code | Category              | Examples                                            |
|--------------|-----------------------|-----------------------------------------------------|
| **FC-MECH**  | Mechanical            | Bearing failure, gear wear, shaft breakage           |
| **FC-ELEC**  | Electrical            | Motor burn-out, sensor fault, wiring fault           |
| **FC-HYD**   | Hydraulic             | Seal failure, pump failure, contamination            |
| **FC-TOOL**  | Tooling / Consumable  | Tool breakage, insert wear, fixture wear             |
| **FC-COOL**  | Coolant / Lubrication | Coolant pump, contamination, flow blockage           |
| **FC-CTRL**  | Control System        | PLC fault, CNC program error, communication fault    |
| **FC-OPR**   | Operator-Induced      | Incorrect setup, collision, part loading error       |
| **FC-OTHER** | Other / Unknown       | Root cause not yet determined                        |

### 6.6 Preventive Maintenance Schedule

PM intervals are defined per machine type and are tracked in the ERP maintenance module. PM events are scheduled at fixed intervals based on operating hours or calendar time:

| Machine Type    | PM Interval         | PM Duration | Tasks Performed                                      |
|-----------------|---------------------|-------------|------------------------------------------------------|
| CNC Turning     | Every 500 op. hours | 4 hours     | Lubrication, spindle check, tool probe calibration, coolant change |
| CNC Milling     | Every 500 op. hours | 4 hours     | Lubrication, axis backlash check, coolant, filter replacement |
| CNC Grinding    | Every 300 op. hours | 6 hours     | Wheel balance, dresser check, coolant system, slideways |
| Hydraulic Press | Every 1,000 hours   | 3 hours     | Hydraulic fluid change, seal inspection, pressure calibration |
| Conveyor        | Monthly             | 2 hours     | Belt tension, roller inspection, sensor verification  |

---

## 7. Quality Inspection Process

### 7.1 Quality Management Framework

PrecisionEdge's quality management system is certified to **IATF 16949** (International Automotive Task Force), the global quality management standard for automotive production. The quality inspection process at PLT-DET is governed by:

- **Control Plans** — Document-controlled inspection instructions specifying what to measure, how often, with what gauge, and to what tolerance for each product
- **Measurement System Analysis (MSA)** — Gauge repeatability and reproducibility (GR&R) studies validated for all critical gauges
- **Statistical Process Control (SPC)** — Real-time SPC charts maintained for all critical-to-quality (CTQ) characteristics
- **Corrective Action (8D)** — Eight-discipline problem-solving process for all quality escapes

### 7.2 Inspection Types

| Inspection Type    | Trigger                          | Sample Method        | Owner         |
|--------------------|----------------------------------|----------------------|---------------|
| **First Article**  | Machine setup / product changeover | 100% of first 3–5 pieces | Setup Technician + QC |
| **In-Process**     | Periodic during production run   | Every 10th piece (or per control plan interval) | QC Technician / Automated gauge |
| **Final Inspection** | End of production order        | AQL sampling or 100% for critical features | QC Technician |
| **Incoming Inspection** | Receipt of raw material / castings | AQL per material type | QC Technician |
| **Dock Audit**     | Pre-shipment (random)            | Random sample from finished goods | Quality Auditor |

### 7.3 Defect Classification

All defects detected during inspection are classified into one of four severity levels and one of nine defect type categories.

**Defect Severity Levels:**

| Severity Level | Code | Definition                                                                   |
|----------------|------|------------------------------------------------------------------------------|
| Critical       | S1   | Safety-critical defect; potential for injury or major system failure in the field |
| Major          | S2   | Non-conformance that would prevent the part from functioning as intended      |
| Minor          | S3   | Departure from specification that is unlikely to affect function but would be rejected by customer |
| Cosmetic       | S4   | Visual non-conformance with no functional impact                             |

**Defect Type Categories:**

| Defect Type Code | Defect Category     | Examples                                                   |
|------------------|---------------------|------------------------------------------------------------|
| **DFT-DIM**      | Dimensional         | Out-of-tolerance diameter, length, bore, or positional tolerance |
| **DFT-SURF**     | Surface Finish      | Roughness Ra exceeds spec, machining marks, chatter marks   |
| **DFT-CRACK**    | Crack / Fracture    | Grinding crack, material crack, stress fracture             |
| **DFT-BURR**     | Burr / Sharp Edge   | Un-removed burrs at intersecting bores or edges             |
| **DFT-CHIP**     | Chips / Inclusions  | Material inclusions, embedded chips in surface              |
| **DFT-COAT**     | Coating Defect      | Plating thickness out of spec, adhesion failure             |
| **DFT-GEOM**     | Geometry Error      | Out-of-round, non-parallel, angular deviation               |
| **DFT-COMP**     | Component Error     | Wrong material, wrong part number, mixed lots               |
| **DFT-OTHER**    | Other               | Defects not fitting standard categories                     |

### 7.4 Disposition Workflow

When a defect is detected, the lot is placed on **Quality Hold** and a disposition decision is required:

```
[Defect Detected]
    │
    ▼
[Quality Hold Applied to Lot]
    │
    ├─ (S1 Critical) → [Immediate escalation to Quality Manager + Engineering]
    │                  [Production stopped pending investigation]
    │
    ├─ (S2 Major) → [Lot segregated] → [Engineering review] → [Rework? Scrap? Deviation?]
    │
    ├─ (S3 Minor) → [QC decision] → [Rework? Scrap? Customer deviation request?]
    │
    └─ (S4 Cosmetic) → [QC decision] → [Accept-as-is? Cosmetic rework?]
                                │
                                ▼
            [Disposition recorded: REWORK / SCRAP / ACCEPT-AS-IS / DEVIATION]
                                │
                                ▼
            [Quality inspection record updated in MES]
                                │
                                ▼
            [Scrap/rework data flows to SMAP for defect rate and scrap cost reporting]
```

### 7.5 SPC (Statistical Process Control) Monitoring

SMAP's Quality Dashboard provides real-time SPC charting for all critical-to-quality (CTQ) characteristics. SPC charts display:

- **X-bar chart:** Average of each subgroup measurement — detects shifts in process mean
- **R chart:** Range within each subgroup — detects changes in process variation
- **Control Limits:** UCL (Upper Control Limit) and LCL (Lower Control Limit) at ±3σ from the process mean
- **Specification Limits:** USL (Upper Specification Limit) and LSL (Lower Specification Limit) from the engineering drawing

**Key SPC metrics tracked in SMAP:**

| Metric | Description                                               | Target           |
|--------|-----------------------------------------------------------|------------------|
| Cp     | Process Capability Index — spread relative to specification | ≥ 1.33           |
| Cpk    | Process Capability Index — spread + centering             | ≥ 1.33 (≥ 1.67 for safety-critical) |
| PPM    | Parts per million defective (estimated from process data) | < 500 PPM (customer target) |

### 7.6 Quality-to-Production Traceability

Every quality inspection record in SMAP is traceable to:

- The specific **production order** being inspected
- The **machine** that produced the parts
- The **operator** who produced (or inspected) the parts
- The **shift** during which production occurred
- The **sensor readings** recorded during production (enabling correlation analysis between process parameters and quality outcomes)

This full traceability chain is the foundation for SMAP's **Quality Prediction** ML model, which uses process parameters (machine conditions, sensor values, shift, operator experience) as input features to predict the expected defect rate for a production order.

---

*This document describes the manufacturing process as it exists at PLT-DET and serves as the business context for all SMAP data models, KPI definitions, and analytical use cases. Last reviewed: 2026-07-22.*
