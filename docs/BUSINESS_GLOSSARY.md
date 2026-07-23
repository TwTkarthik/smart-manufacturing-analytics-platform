# Business Glossary — Smart Manufacturing Analytics Platform (SMAP)

**Document Version:** 1.0.0
**Last Updated:** 2026-07-22
**Status:** Approved — Business Domain Baseline
**Owner:** Business Analysis Lead
**Related Documents:** [COMPANY_PROFILE.md](./COMPANY_PROFILE.md) · [MANUFACTURING_PROCESS.md](./MANUFACTURING_PROCESS.md) · [KPI_DEFINITIONS.md](./KPI_DEFINITIONS.md) · [DATA_SOURCES.md](./DATA_SOURCES.md)

---

## Purpose

This glossary defines every important business term used throughout the SMAP project documentation, data models, dashboards, and ML models. Terms are organized alphabetically within thematic sections.

All terms defined here are considered **canonical** within the SMAP project. When the same concept appears in source system documentation, engineering drawings, or customer agreements under a different label, this glossary defines the preferred SMAP term and notes the synonym.

---

## Table of Contents

1. [Manufacturing Operations Terms](#1-manufacturing-operations-terms)
2. [Quality Management Terms](#2-quality-management-terms)
3. [Maintenance & Reliability Terms](#3-maintenance--reliability-terms)
4. [KPI & Metrics Terms](#4-kpi--metrics-terms)
5. [Data & Technology Terms](#5-data--technology-terms)
6. [Organizational Terms](#6-organizational-terms)
7. [Industry Standards & Certifications](#7-industry-standards--certifications)
8. [Acronym Reference](#8-acronym-reference)

---

## 1. Manufacturing Operations Terms

### Actual Cycle Time
The elapsed time from the start of producing one unit to the start of the next, as observed during the actual production run. Calculated as: `Run Time / Actual Units Produced`. Compared against Standard Cycle Time to derive the Performance OEE component. See also: **Standard Cycle Time**, **Performance**.

### Actual Units
The total number of parts produced by a machine during a production order, regardless of quality status. Includes good units, scrap units, and rework units. Captured by the MES unit counter.

### Availability
One of the three components of OEE. Measures the fraction of Planned Production Time during which the machine was actually running (not stopped due to downtime). **Formula:** `(Planned Production Time − Total Downtime) / Planned Production Time`. See: [KPI_DEFINITIONS.md §3](./KPI_DEFINITIONS.md#3-availability).

### Bar Stock
Raw material in cylindrical bar form (steel, aluminum), fed into CNC turning centers as the starting material for turned components. A key raw material type at PLT-DET.

### Batch
A discrete quantity of parts produced together in a single production run, sharing the same material lot, setup, and process parameters. Also called a **lot** or **production order**.

### Billet
A semi-finished metal product (typically steel) that is the starting raw material for forging or heavy machining operations. Distinct from bar stock in that billets are typically larger cross-section and not precision-ground.

### Bottleneck
The production step, machine, or station with the lowest throughput rate in a value stream. The bottleneck constrains the overall output rate of the line, regardless of how fast upstream or downstream steps operate.

### Casting Blank
A component produced by a casting process (sand casting, die casting, investment casting) used as the raw material input for subsequent machining operations. For example, brake caliper housings at PLT-DET begin as aluminum die castings.

### Changeover
The process of converting a machine or production line from producing one product to producing another. Includes removing tooling, fixtures, and programs and installing those required for the new product. Also called **setup** or **product changeover**. Changeover time is a direct contributor to Availability losses in OEE.

### Continuous Improvement (CI)
A systematic, ongoing effort to improve production processes, quality, and efficiency. At PrecisionEdge, CI is driven through OEE reporting, Pareto analysis, and 8D corrective action processes.

### CNC (Computer Numerical Control)
A manufacturing method in which pre-programmed computer software controls the movement of machine tools (lathes, mills, grinders). CNC machines are the primary production asset at PLT-DET. Synonyms: **machining center**, **CNC machine**.

### Feed Rate
The rate at which the cutting tool advances through the workpiece material during machining, expressed in millimeters per revolution (mm/rev) or millimeters per minute (mm/min). A key controllable process parameter influencing cycle time, surface finish, and cutting force.

### First Article
The first part (or first few parts) produced after a machine setup, inspected 100% to verify the setup is correct before the full production run begins. Also called **First Article Inspection (FAI)** or **first-piece check**.

### Forging Blank
A component produced by a forging process (closed-die or open-die), used as a near-net-shape raw material input for precision machining. Forging produces superior grain structure compared to machined-from-bar stock, making it preferred for high-stress components.

### Good Units
Units produced during a production order that pass quality inspection on the first attempt, without requiring rework. The numerator of the Quality OEE component. Synonym: **conforming units**, **accepted units**.

### Idle Time
Time during which a machine is energized and available but not actively producing parts. Idle time is not classified as downtime (the machine has not failed), but it represents a Performance loss and unnecessary energy consumption. Sources include: waiting for an operator, waiting for material, minor stops between parts.

### Make-to-Order (MTO)
A production strategy in which manufacturing begins only after a confirmed customer order is received. Used at PrecisionEdge for custom, low-volume, or customer-specific component configurations.

### Make-to-Stock (MTS)
A production strategy in which parts are manufactured in advance based on a demand forecast and held in finished goods inventory. Used at PrecisionEdge for high-volume standard catalog components.

### Minor Stop
A machine interruption lasting less than 5 minutes that is too brief to be logged as a downtime event in the MES. Minor stops are a Performance loss in OEE, not an Availability loss. Common causes: chip accumulation, part loading error, brief sensor fault. Synonym: **micro-stop**.

### Operator
A production floor employee responsible for operating, loading/unloading, and monitoring production machines during a shift. Categorized in SMAP by role code (OPR-MCH = machine operator, OPR-SET = setup technician).

### Part Number
A unique identifier assigned to a specific product design. In PrecisionEdge's ERP system, the part number is the **Material Code**. In the MES, it is the **product_code**. In SMAP, it is normalized to `product_code` in the `dim_product` dimension.

### Planned Production Time
The total duration of a production shift or order during which the machine is *scheduled* to be producing. Calculated as: `Shift Duration − Scheduled Maintenance Stops`. This is the denominator of the Availability OEE component. Planned breaks (e.g., 30-minute lunch) are typically excluded. Synonym: **available time**, **scheduled operating time**.

### Production Line
A physical grouping of machines, conveyors, and operator stations arranged to produce a family of related products. At PLT-DET: LINE-A, LINE-B, LINE-C, LINE-D. Each line is a distinct business entity with its own OEE, throughput, and quality tracking.

### Production Order
A business document (originating in ERP, dispatched to MES) authorizing the manufacture of a specific quantity of a specific product on a specific machine during a specific shift. The fundamental unit of production tracking in SMAP. Synonym: **work order** (in some MES terminology), **shop order**.

### Rated Capacity
The maximum number of units a machine can produce per hour under ideal conditions (100% OEE). Defined in the ERP routing/work center master. Used as the denominator for Performance calculation.

### Rework
Non-conforming parts that are returned to the production process for additional operations to bring them into conformance with specifications. Rework parts are not counted as Good Units in OEE Quality calculation, even if they ultimately pass inspection. Synonym: **repair**, **remediation**.

### Run Time
The actual time a machine was actively producing during a production order. Calculated as: `Planned Production Time − Total Downtime`. This is the time base used for Performance calculation.

### Scrap
Non-conforming parts that cannot be reworked to meet specifications and are discarded. Scrap has a direct material cost impact and is the primary driver of the Quality OEE component loss. Synonym: **reject**, **waste**.

### Setup Time
The elapsed time to prepare a machine for a production run: installing tooling and fixtures, loading the CNC program, and verifying the setup with first-article inspection. Setup time is classified as a planned downtime (Availability loss) if it occurs between scheduled production orders.

### Shift
A defined working period within a 24-hour day during which a crew of operators staffs the production floor. At PLT-DET: SHIFT-A (Day: 06:00–14:00), SHIFT-B (Afternoon: 14:00–22:00), SHIFT-C (Night: 22:00–06:00).

### Spindle
The rotating component of a CNC machine that holds and drives the cutting tool (in a milling machine) or the workpiece (in a turning center). Spindle speed (RPM) and spindle load are key sensor parameters in SMAP's predictive maintenance model.

### Standard Cycle Time
The engineered design time to produce one unit at full rated machine speed, as defined in the ERP routing. This is the theoretical minimum cycle time; actual cycle time is typically longer. Used as the numerator in Performance calculation. Also called **ideal cycle time** or **theoretical cycle time**.

### Takt Time
The rate at which finished products must be produced to meet customer demand. Calculated as: `Available Production Time / Customer Demand Rate`. Takt time is the heartbeat of a production line — machines and operators must cycle at or faster than takt time to meet the production schedule.

### Throughput
The volume of output (units) produced by a machine, line, or plant in a given time period. Distinguished from OEE in that throughput is a volume measure, not an efficiency ratio. See: [KPI_DEFINITIONS.md §9](./KPI_DEFINITIONS.md#9-throughput).

### Tolerance
The permissible range of variation in a manufactured dimension. Expressed as ± value (e.g., ±0.005mm). Parts with dimensions outside the tolerance are non-conforming (defective). At PrecisionEdge, tolerances are defined on engineering drawings and enforced through inspection.

### Work-in-Process (WIP)
Parts that have been started but not yet completed — they are somewhere between raw material and finished goods. WIP represents tied-up capital and is a key inventory management metric.

---

## 2. Quality Management Terms

### 8D (Eight Disciplines)
A structured problem-solving methodology used at PrecisionEdge for responding to quality escapes and customer complaints. The eight disciplines address: problem definition, containment, root cause analysis, corrective action, preventive action, and closure. Required response for all S1/S2 defect escapes.

### AQL (Acceptance Quality Level)
A statistical sampling standard that defines the maximum acceptable defect rate in a batch. AQL sampling tables specify the sample size and acceptance/rejection numbers based on lot size. PrecisionEdge uses AQL 1.0 as the default for non-critical features.

### APQP (Advanced Product Quality Planning)
A structured framework required by automotive OEM customers for managing the quality planning process during new product introduction. Part of the IATF 16949 quality management system. Produces the **Control Plan** and **PPAP** as deliverables.

### Control Limit
A statistically derived boundary on an SPC chart (UCL — Upper Control Limit; LCL — Lower Control Limit) set at ±3 standard deviations from the process mean. Data points outside control limits indicate a statistically significant process shift. Distinct from Specification Limits, which are customer-defined tolerances.

### Control Plan
A document mandated by IATF 16949 that specifies, for each product, every quality characteristic to be controlled, the process step where it is controlled, the inspection method, the measurement device, the control frequency, and the reaction plan if control is lost. Controls Plans are the basis for SMAP's quality inspection data structure.

### Cp (Process Capability Index)
A measure of process spread relative to the specification tolerance bandwidth. `Cp = (USL − LSL) / (6σ)`. Cp measures potential capability assuming the process is perfectly centered; it does not account for process mean offset. **Target: ≥ 1.33**.

### Cpk (Process Capability Index — Centered)
A measure of process capability that accounts for both spread and centering relative to the specification. `Cpk = min[(USL − µ) / 3σ, (µ − LSL) / 3σ]`. Cpk is the primary capability index used in customer quality agreements. **Target: ≥ 1.33** (≥ 1.67 for safety-critical features per IATF 16949).

### CTQ (Critical to Quality)
A product characteristic that is most important to the customer's definition of quality. CTQ characteristics have the tightest tolerances, the most frequent inspection, and are subject to SPC monitoring. Identified during APQP through the Voice of Customer process.

### Defect
Any non-conformance of a manufactured unit to its engineering specification. Defects are classified by type (dimensional, surface, crack, burr, etc.) and severity (S1 Critical through S4 Cosmetic). See: [MANUFACTURING_PROCESS.md §7.3](./MANUFACTURING_PROCESS.md#73-defect-classification).

### Defect Rate
The proportion of units inspected that are found to be non-conforming. **Formula:** `(Defects Found / Units Inspected) × 100`. Expressed as a percentage or in PPM. See: [KPI_DEFINITIONS.md §6](./KPI_DEFINITIONS.md#6-defect-rate).

### First Pass Yield (FPY)
The proportion of units that pass quality inspection the first time, without rework or scrap. **Formula:** `Good Units / Total Units Inspected`. Complement of Defect Rate: `FPY = 1 − Defect Rate`. Synonym: **first time right**, **first time through**.

### GR&R (Gauge Repeatability & Reproducibility)
A statistical study that quantifies how much of the observed measurement variation is due to the measurement system (gauge and operators) versus the actual part-to-part variation. Required by IATF 16949 for all gauges used on CTQ characteristics. Gauge R&R results inform the reliability of SMAP's quality data.

### IATF 16949
The international quality management system standard for automotive production and relevant service part organizations. Replaces the older TS 16949 and QS-9000 standards. PrecisionEdge is certified to IATF 16949:2016.

### Inspection Frequency
The rate at which quality inspections are performed during a production run. Defined in the Control Plan. Common patterns: every Nth part (e.g., every 10th), time-based (every 30 minutes), event-triggered (after each tool change).

### LSL / USL (Lower / Upper Specification Limit)
The engineering-defined boundaries within which a dimension must fall to be conforming. Set by the customer or engineering drawing. Parts with measurements outside [LSL, USL] are non-conforming (defective). Distinct from Control Limits, which are statistically derived.

### Non-Conformance
A state in which a product or process fails to meet a specified requirement. Non-conformances are documented in the MES quality module and trigger the disposition workflow (rework, scrap, or customer deviation). Synonym: **defect**, **rejection**.

### Pareto Analysis
A quality improvement technique based on the Pareto Principle (80/20 rule): identifying the vital few defect types that account for the majority of total defects. SMAP's Quality Dashboard includes a Pareto chart of defects by type. Named after economist Vilfredo Pareto.

### PPM (Parts Per Million)
A unit for expressing defect rates at very low levels: `(Defects / Total Units) × 1,000,000`. Used in customer quality agreements as the target defect level for shipped product. PrecisionEdge's contractual target with key customers: **< 500 PPM**.

### PPAP (Production Part Approval Process)
A formal customer approval process required before mass production of a new or changed automotive component can begin. PPAP Level 3 (most common) requires submission of a control plan, dimensional report, material certifications, and capability study results.

### Quality Hold
A status applied to a production lot that prevents it from moving to the next production step or shipment until a quality disposition decision is made. Lots on hold are physically segregated (yellow/red tag or quarantine area) to prevent inadvertent use.

### SPC (Statistical Process Control)
A method of using statistical techniques (control charts) to monitor and control a manufacturing process. SPC enables early detection of process shifts before they result in defects, enabling corrective action while the process is still producing conforming parts. SMAP's Quality Dashboard provides real-time SPC charting. See: [MANUFACTURING_PROCESS.md §7.5](./MANUFACTURING_PROCESS.md#75-spc-statistical-process-control-monitoring).

### Specification Limit
See: **LSL / USL**.

---

## 3. Maintenance & Reliability Terms

### Asset Tag
A physical tag affixed to a machine with a unique identifier, used by the maintenance department to identify assets in work orders and PM records. At PrecisionEdge, asset tags follow the format `AT-XXXX`. Mapped to MES `machine_id` in the SMAP ETL pipeline.

### CMMS (Computerized Maintenance Management System)
Software used to manage maintenance operations: scheduling PM work orders, tracking breakdowns, recording parts used, and managing technician assignments. PrecisionEdge uses the maintenance module of MachineLink as its CMMS.

### Condition Monitoring
Continuous or periodic monitoring of machine health indicators (vibration, temperature, oil quality) to detect degradation before failure occurs. The sensor data captured by SCADA and ingested by SMAP is the foundation of PrecisionEdge's condition monitoring program.

### Corrective Maintenance
Maintenance performed after a failure has occurred, to restore the machine to operating condition. Also called **reactive maintenance** or **breakdown maintenance**. Currently the dominant maintenance type at PrecisionEdge (42% of all events). The target is to reduce this to <20%.

### Downtime
Any period during which a machine is not producing due to a stop event. Classified as Planned (scheduled maintenance, tooling change) or Unplanned (breakdown, process fault). Total downtime during a production period is the key driver of Availability loss in OEE.

### Emergency Maintenance
An urgent, unplanned maintenance event requiring immediate response — typically because the machine failure is causing major production disruption, safety risk, or imminent customer delivery failure. Emergency events have the highest priority in SMAP's maintenance dashboard.

### Failure Code
A standardized code assigned to a maintenance work order to categorize the type of failure that caused the downtime. PrecisionEdge failure codes: FC-MECH, FC-ELEC, FC-HYD, FC-TOOL, FC-COOL, FC-CTRL, FC-OPR, FC-OTHER. Failure codes are the basis for Pareto analysis of top failure modes.

### FMEA (Failure Mode and Effects Analysis)
A systematic risk assessment tool used to identify potential failure modes of a machine or process, their effects, and their causes — before failures occur. FMEA outputs inform PM schedules and sensor alert thresholds. Required by IATF 16949 for new product introductions.

### LOTO (Lock Out / Tag Out)
A safety procedure mandated by OSHA that ensures hazardous energy sources are isolated and locked before maintenance work begins on a machine. LOTO is always applied before any corrective or preventive maintenance at PrecisionEdge.

### MTBF (Mean Time Between Failures)
The average operating time between unplanned failure events for a machine. A higher MTBF indicates greater reliability. See: [KPI_DEFINITIONS.md §7](./KPI_DEFINITIONS.md#7-mtbf--mean-time-between-failures).

### MTTR (Mean Time to Repair)
The average time to restore a machine to operating condition after an unplanned failure, from the moment the machine stops to the moment it resumes production. A lower MTTR indicates a more efficient maintenance response. See: [KPI_DEFINITIONS.md §8](./KPI_DEFINITIONS.md#8-mttr--mean-time-to-repair).

### OEE (Overall Equipment Effectiveness)
See Section 4 and [KPI_DEFINITIONS.md §2](./KPI_DEFINITIONS.md#2-oee--overall-equipment-effectiveness).

### Planned Maintenance (PM)
Scheduled maintenance activities carried out at predetermined intervals (time-based or usage-based) to prevent failure before it occurs. Also called **preventive maintenance**. Planned stops for PM are recorded as downtime but are classified separately from unplanned breakdowns in SMAP.

### Predictive Maintenance (PdM)
A condition-based maintenance strategy that uses real-time sensor data, trend analysis, and ML models to predict when equipment failure is likely to occur — enabling maintenance to be scheduled proactively, before the failure, during a convenient planned window. The primary value proposition of SMAP's ML layer.

### Reliability
The probability that a machine will perform its intended function without failure for a specified period under defined operating conditions. MTBF is the primary quantitative measure of reliability in SMAP.

### Root Cause Analysis (RCA)
A systematic investigation to identify the fundamental, underlying cause of a failure or quality problem — not just the immediate symptom. Documented in the `root_cause` field of maintenance work orders. Required for all S1/S2 quality events and all critical machine failures.

### Spare Parts
Components held in inventory specifically for use in machine repairs. Spare parts availability is a key factor in MTTR. SMAP's predictive maintenance model is intended to enable **proactive spare parts pre-positioning** — having the right parts available before the failure occurs.

### Unplanned Downtime
Machine downtime resulting from an unexpected failure, fault, or stoppage that was not scheduled in advance. Unplanned downtime is the most damaging form of downtime — it causes production disruption, overtime, and customer delivery risk. The primary target for improvement through SMAP's predictive maintenance capability.

### Work Order
A document authorizing and tracking a maintenance task. Contains: machine ID, event type, failure description, assigned technician, start/end times, parts used, and root cause. The fundamental record in the CMMS and the grain of the `fct_maintenance_event` fact table in SMAP.

---

## 4. KPI & Metrics Terms

### Baseline
The measured current-state value of a KPI before an improvement initiative is implemented. Used to quantify the starting point and to measure the impact of changes. All SMAP KPI targets are expressed relative to the established baseline in [KPI_DEFINITIONS.md §15](./KPI_DEFINITIONS.md#15-kpi-targets-summary).

### Benchmark
An external reference value from industry studies, trade associations, or peer companies used to evaluate whether a company's KPI performance is competitive. For example, world-class OEE benchmark = 85%. Industry average for automotive Tier-2: 75–85%.

### Capacity Utilization
The ratio of actual machine operating hours to total available hours. Distinct from OEE: a machine can have 100% capacity utilization but low OEE (running the whole time, but slowly and with defects).

### Cycle Time
See Section 1. From a KPI perspective: the elapsed time to produce one unit. Two types: **Standard Cycle Time** (engineered target) and **Actual Cycle Time** (observed). Cycle Time Efficiency = Standard / Actual. See: [KPI_DEFINITIONS.md §10](./KPI_DEFINITIONS.md#10-cycle-time).

### Energy Consumption per Unit
The kilowatt-hours of electricity consumed per good unit produced. Used to track energy efficiency improvements. See: [KPI_DEFINITIONS.md §11](./KPI_DEFINITIONS.md#11-energy-consumption).

### KPI (Key Performance Indicator)
A quantifiable measure used to evaluate the success of an organization, department, or process in achieving defined objectives. KPIs at PrecisionEdge are organized in a four-tier hierarchy: Strategic → Operational → Diagnostic → Data/Signal.

### OEE (Overall Equipment Effectiveness)
The gold-standard manufacturing KPI that measures the percentage of planned production time that is truly productive. OEE = Availability × Performance × Quality. See: [KPI_DEFINITIONS.md §2](./KPI_DEFINITIONS.md#2-oee--overall-equipment-effectiveness).

### On-Time Delivery (OTD)
The percentage of customer shipments delivered on or before the customer's requested date. OTD is a key customer scorecard metric. **Target: ≥ 98%**.

### Planned vs. Unplanned Maintenance Ratio
The proportion of total maintenance events that are planned (preventive + predictive) vs. unplanned (corrective + emergency). A higher planned ratio indicates a more proactive maintenance culture. **Target: ≥ 70% planned**.

### Production Efficiency
The comparison of actual production output to planned production output. Answers: "Did we make what we planned to make?" Distinct from OEE. See: [KPI_DEFINITIONS.md §12](./KPI_DEFINITIONS.md#12-production-efficiency).

### Schedule Attainment
The percentage of production orders completed on their scheduled date. Measures the reliability of production planning and execution. **Target: ≥ 95%**.

### Scrap Rate
The percentage of units produced that are scrapped (discarded as non-conforming and not reworkable). **Formula:** `Scrap Units / Total Units Produced × 100`. See also: **Defect Rate**.

### Throughput vs. Plan
Actual good units produced as a percentage of planned units. **Formula:** `Actual Good Units / Planned Units × 100`. Measures volume execution. **Target: ≥ 98%**.

---

## 5. Data & Technology Terms

### Anomaly Detection
An ML technique used to identify data points or patterns that deviate significantly from expected behavior. In SMAP, the Isolation Forest model detects multivariate sensor reading anomalies that are potential precursors to machine failure. See: [../SYSTEM_ARCHITECTURE.md §10](../SYSTEM_ARCHITECTURE.md#10-machine-learning-architecture).

### Bronze Zone
The raw data layer in SMAP's medallion data lake architecture. Bronze zone contains unmodified, immutable data exactly as received from source systems in Parquet format. No transformations are applied in the Bronze zone. Stored in MinIO: `smap-data-lake/bronze/`.

### dbt (Data Build Tool)
An open-source transformation framework that enables analytics engineers to write warehouse transformations in SQL with software engineering best practices: version control, testing, documentation, and modular composition. SMAP uses dbt Core for all Silver → Gold transformations.

### Degenerate Dimension
A dimension attribute stored directly in a fact table rather than in a separate dimension table. In SMAP's `fct_production`, the `order_id` (production order number) is a degenerate dimension — useful for drill-down but not worth a separate dimension table.

### Dimension Table (dim_*)
A table in a star schema data warehouse that stores descriptive attributes for entities referenced by fact tables. Examples: `dim_machine`, `dim_product`, `dim_employee`, `dim_date`, `dim_shift`. Used to add context to fact table measures.

### ETL (Extract, Transform, Load)
The process of extracting data from source systems, transforming it (cleaning, standardizing, deriving metrics), and loading it into the data warehouse. SMAP's ETL pipeline is orchestrated by Apache Airflow and processes all seven source systems. See: [../SYSTEM_ARCHITECTURE.md §5.2](../SYSTEM_ARCHITECTURE.md#52-ingestion-layer).

### Fact Table (fct_*)
A table in a star schema data warehouse that stores quantitative, measurable events at a defined grain. Examples: `fct_production` (one row per production order), `fct_sensor_reading` (one row per sensor reading). Contains foreign keys to dimension tables and numeric measure columns.

### Feature Engineering
The process of transforming raw data into features (input variables) that ML models use for prediction. In SMAP, feature engineering for the predictive maintenance model includes: rolling 7/14/30-day sensor averages, days since last PM, vibration trend slope, and historical failure rate per machine.

### Gold Zone
The serving layer in SMAP's medallion architecture. Gold zone contains the fully modeled, dbt-managed star schema tables in the PostgreSQL data warehouse (`marts` schema). The Gold zone is the source for all dashboards, API responses, and ML model training.

### Great Expectations
An open-source Python library for defining, validating, and documenting data quality expectations. SMAP uses Great Expectations to validate all source data at the Bronze → Silver transition. Records failing validation are quarantined and not advanced.

### Incremental Extraction
An ETL extraction strategy that retrieves only records that have changed since the last extraction run, using a watermark (maximum `updated_at` or `reading_timestamp` from the previous run). Contrasted with full extraction (extract all records every run). SMAP uses incremental extraction for all source systems.

### Medallion Architecture
A data lake design pattern with three zones — Bronze (raw), Silver (cleaned), Gold (serving) — representing progressively higher data quality and transformation. Named for its progression from raw to refined. SMAP implements the medallion pattern in MinIO (Bronze/Silver) and PostgreSQL (Gold).

### ML Model
A mathematical model trained on historical data that can make predictions on new, unseen data. SMAP includes three ML models: Predictive Maintenance (XGBoost Classifier), Anomaly Detection (Isolation Forest), and Quality Prediction (XGBoost Regressor).

### MLflow
An open-source platform for managing the ML lifecycle: experiment tracking, model versioning, and model serving. SMAP uses MLflow to log all training experiments and register production-ready models. See: [../TECH_STACK.md §8](../TECH_STACK.md).

### ORM (Object-Relational Mapper)
A software layer that maps database tables to programming language objects, enabling database interaction without writing raw SQL. SMAP's FastAPI backend uses SQLAlchemy as its ORM for all warehouse queries.

### Parquet
A columnar file format optimized for analytical workloads. SMAP uses Parquet (Snappy-compressed) for all Bronze and Silver zone data in MinIO. Parquet is significantly more efficient than CSV for read-heavy analytical operations.

### Predictive Maintenance Model
The XGBoost Classifier model in SMAP that predicts the probability of machine failure within a configurable horizon (default: 7 days), based on rolling sensor aggregate features and maintenance history. Target metric: ≥ 85% recall. See: [../SYSTEM_ARCHITECTURE.md §10](../SYSTEM_ARCHITECTURE.md#10-machine-learning-architecture).

### Silver Zone
The cleaned and validated data layer in SMAP's medallion architecture. Silver zone contains schema-normalized, null-handled, and validated records in Parquet format. Records that fail Great Expectations validation in Bronze are quarantined and do not advance to Silver.

### Star Schema
A dimensional data model design in which a central fact table is surrounded by dimension tables, connected by surrogate key relationships. Named for its star-like diagram. SMAP's data warehouse uses a star schema. See: [../DATABASE_DESIGN.md §4](../DATABASE_DESIGN.md#4-data-warehouse-schema).

### Surrogate Key
An auto-generated, system-assigned integer key used as the primary key in warehouse dimension tables (e.g., `machine_sk`). Surrogate keys decouple the warehouse data model from source system key changes and enable Slowly Changing Dimension (SCD) management.

### Watermark
A stored checkpoint value (typically the maximum `updated_at` or `reading_timestamp` from the previous ETL run) used to implement incremental extraction. On the next run, only records with timestamps greater than the watermark are extracted. SMAP stores watermarks as Airflow Variables.

---

## 6. Organizational Terms

### DEPT-ENG (Process Engineering)
The department responsible for defining and maintaining machining processes (speeds, feeds, tooling), Standard Cycle Times, and process change management. A key consumer of SMAP's sensor trend data and quality analytics.

### DEPT-FIN (Finance)
The department responsible for financial reporting, cost accounting, and budget management. Consumes SMAP's scrap cost, energy cost, and labor efficiency data.

### DEPT-IT (Information Technology)
The department responsible for ERP, MES, SCADA infrastructure, and network operations. The enabler of SMAP's data access; also a key internal customer (SMAP reduces IT's ad-hoc reporting burden).

### DEPT-MNT (Maintenance & Reliability)
The department responsible for all machine maintenance activities — preventive, corrective, and predictive. The primary internal customer for SMAP's Maintenance & Reliability dashboard and predictive maintenance ML model.

### DEPT-OPS (Manufacturing Operations)
The department responsible for running the production floor — managing operators, production schedules, and shift performance. The primary customer for SMAP's OEE and Production Throughput dashboards.

### DEPT-PLN (Production Planning)
The department responsible for creating the Master Production Schedule and managing capacity planning. Consumes SMAP's OEE, throughput, and production efficiency data to adjust planning parameters.

### DEPT-QA (Quality Assurance)
The department responsible for all quality management activities: inspection, non-conformance management, SPC, PPAP, and IATF 16949 compliance. The primary customer for SMAP's Quality Control dashboard and Quality Prediction model.

### DEPT-SCM (Supply Chain Management)
The department responsible for raw material procurement, inventory management, and logistics. Consumes SMAP's inventory analytics and production demand signals.

### OEM (Original Equipment Manufacturer)
A company that designs and produces end products (e.g., vehicles, machinery) incorporating components from suppliers. PrecisionEdge's customers include automotive OEMs (vehicle manufacturers) and industrial machinery OEMs. At PrecisionEdge, OEMs are Tier-1 or direct customers.

### Tier-1 Supplier
A supplier that sells directly to an OEM. Tier-1 suppliers typically produce systems or major assemblies (e.g., brake systems, transmission assemblies).

### Tier-2 Supplier
A supplier that sells components to Tier-1 suppliers. PrecisionEdge is a Tier-2 supplier — it provides machined components to Tier-1 brake and drivetrain assemblers who in turn supply automotive OEMs.

---

## 7. Industry Standards & Certifications

### IATF 16949
The global quality management system standard for the automotive industry. Incorporates ISO 9001 requirements plus automotive-specific requirements for production process control, FMEA, APQP, and PPAP. PrecisionEdge is IATF 16949:2016 certified.

### ISO 9001:2015
The international standard for quality management systems. A superset of IATF 16949 in terms of broader industry applicability. PrecisionEdge maintains dual certification.

### ISO 14001:2015
The international standard for environmental management systems. PrecisionEdge's ISO 14001 certification is relevant to SMAP's energy monitoring capability — energy consumption reporting supports environmental compliance reporting requirements.

### ISO 10816
The international standard for mechanical vibration measurement and evaluation of machine vibration severity. Provides vibration velocity threshold zones (A = new machine, B = acceptable, C = monitor, D = danger). Used in SMAP to interpret `SEN-VIB` sensor readings and configure anomaly alert thresholds.

### OSHA
The Occupational Safety and Health Administration — the U.S. federal agency that sets and enforces standards for workplace safety. OSHA regulations govern machine guarding, lockout/tagout (LOTO), hazardous materials, and ergonomics at PrecisionEdge facilities.

---

## 8. Acronym Reference

| Acronym    | Full Form                                      | Context                      |
|------------|------------------------------------------------|------------------------------|
| APQP       | Advanced Product Quality Planning              | Quality / Automotive         |
| AQL        | Acceptance Quality Level                       | Quality                      |
| CMMS       | Computerized Maintenance Management System     | Maintenance                  |
| CNC        | Computer Numerical Control                     | Manufacturing                |
| CTQ        | Critical to Quality                            | Quality                      |
| dbt        | Data Build Tool                                | Data Engineering             |
| ETL        | Extract, Transform, Load                       | Data Engineering             |
| FAI        | First Article Inspection                       | Quality                      |
| FMEA       | Failure Mode and Effects Analysis              | Quality / Maintenance        |
| FPY        | First Pass Yield                               | Quality KPI                  |
| GR&R       | Gauge Repeatability & Reproducibility          | Quality                      |
| IATF       | International Automotive Task Force            | Quality Standard             |
| IoT        | Internet of Things                             | Technology                   |
| KPI        | Key Performance Indicator                      | Business Analytics           |
| LOTO       | Lock Out / Tag Out                             | Safety / Maintenance         |
| MES        | Manufacturing Execution System                 | Operational System           |
| ML         | Machine Learning                               | Technology                   |
| MTBF       | Mean Time Between Failures                     | Reliability KPI              |
| MTTR       | Mean Time to Repair                            | Maintenance KPI              |
| MTO        | Make to Order                                  | Production Strategy          |
| MTS        | Make to Stock                                  | Production Strategy          |
| OEE        | Overall Equipment Effectiveness                | Manufacturing KPI            |
| OEM        | Original Equipment Manufacturer               | Customer / Industry          |
| OSHA       | Occupational Safety and Health Administration  | Regulation                   |
| OTD        | On-Time Delivery                               | Supply Chain KPI             |
| PdM        | Predictive Maintenance                         | Maintenance Strategy         |
| PM         | Planned / Preventive Maintenance               | Maintenance                  |
| PPAP       | Production Part Approval Process               | Quality / Automotive         |
| PPM        | Parts Per Million                              | Quality KPI                  |
| RCA        | Root Cause Analysis                            | Quality / Maintenance        |
| SCADA      | Supervisory Control and Data Acquisition       | Operational Technology       |
| SCD        | Slowly Changing Dimension                      | Data Warehousing             |
| SKU        | Stock Keeping Unit                             | Product Identification       |
| SMAP       | Smart Manufacturing Analytics Platform         | This Project                 |
| SPC        | Statistical Process Control                    | Quality                      |
| UCL / LCL  | Upper / Lower Control Limit                    | SPC / Quality                |
| USL / LSL  | Upper / Lower Specification Limit              | Quality / Engineering        |
| WIP        | Work in Process                                | Inventory / Production       |
| WO         | Work Order                                     | Maintenance / Production     |

---

*This glossary is a living document maintained by the Business Analysis Lead. Any new business term introduced in SMAP documentation, data models, dashboards, or ML model features must be added here before use. Last reviewed: 2026-07-22.*
