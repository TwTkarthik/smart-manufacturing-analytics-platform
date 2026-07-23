# Company Profile — PrecisionEdge Manufacturing Ltd.

**Document Version:** 1.0.0
**Last Updated:** 2026-07-22
**Status:** Approved — Business Domain Baseline
**Owner:** Business Analysis Lead
**Related Documents:** [MANUFACTURING_PROCESS.md](./MANUFACTURING_PROCESS.md) · [BUSINESS_PROBLEMS.md](./BUSINESS_PROBLEMS.md) · [KPI_DEFINITIONS.md](./KPI_DEFINITIONS.md)

---

## Table of Contents

1. [Company Overview](#1-company-overview)
2. [Industry Context](#2-industry-context)
3. [Factory Locations](#3-factory-locations)
4. [Products Manufactured](#4-products-manufactured)
5. [Organizational Departments](#5-organizational-departments)
6. [Business Goals](#6-business-goals)
7. [Competitive Position](#7-competitive-position)

---

## 1. Company Overview

**PrecisionEdge Manufacturing Ltd.** is a mid-sized discrete manufacturing company specializing in high-precision industrial components for the automotive and industrial machinery sectors. Founded in 1998 and headquartered in Detroit, Michigan, PrecisionEdge employs approximately 2,400 people across three manufacturing facilities in the United States and one finishing plant in Mexico.

| Attribute              | Detail                                              |
|------------------------|-----------------------------------------------------|
| **Legal Name**         | PrecisionEdge Manufacturing Ltd.                    |
| **Founded**            | 1998                                                |
| **Headquarters**       | Detroit, Michigan, USA                              |
| **Industry**           | Discrete Manufacturing — Industrial Components      |
| **Sector**             | Automotive Tier-2 Supplier & Industrial Machinery   |
| **Annual Revenue**     | ~$480 million USD (FY2025)                          |
| **Employees**          | ~2,400 full-time across all facilities              |
| **Production Volume**  | ~3.2 million components per year                   |
| **Customer Base**      | OEM automotive assemblers, heavy equipment OEMs, and industrial machinery integrators |
| **Certifications**     | IATF 16949 (Automotive Quality), ISO 9001:2015, ISO 14001:2015 (Environmental) |

> **Note:** PrecisionEdge Manufacturing Ltd. is the **fictional company** that anchors the SMAP platform. All data, operational metrics, and business scenarios described throughout this documentation are synthetic and designed to reflect realistic manufacturing industry patterns.

---

## 2. Industry Context

PrecisionEdge operates in the **discrete manufacturing** segment of the broader manufacturing industry. Discrete manufacturing produces distinct, countable items — components, assemblies, and finished goods — as opposed to process manufacturing (chemicals, food, refining), which produces continuous flows of bulk product.

### 2.1 Industry Characteristics

| Characteristic              | Description                                                                                    |
|-----------------------------|-----------------------------------------------------------------------------------------------|
| **Production Model**        | Make-to-Order (MTO) for custom components; Make-to-Stock (MTS) for standard catalog parts     |
| **Quality Standard**        | IATF 16949 — automotive quality management; requires documented process control and traceability |
| **Regulatory Environment**  | OSHA workplace safety, EPA environmental compliance, customer-mandated supplier audits          |
| **Technology Trend**        | Industry 4.0 adoption — IoT sensors, predictive analytics, digital twin initiatives            |
| **Competitive Pressures**   | Cost-per-part reduction, shorter lead times, zero-defect delivery expectations from OEM customers |

### 2.2 Market Position

PrecisionEdge holds a Tier-2 supplier position in the automotive supply chain, meaning it supplies machined components directly to Tier-1 suppliers (e.g., major brake system or drivetrain assemblers) who in turn supply to OEM vehicle manufacturers. This position subjects PrecisionEdge to strict quality agreements (PPM targets, APQP processes) and cost reduction roadmaps demanded annually by its Tier-1 customers.

---

## 3. Factory Locations

PrecisionEdge operates four facilities across two countries. Each facility has a distinct production focus and capability profile.

### 3.1 Facility Summary

| Facility Code | Facility Name                  | Location                   | Type                      | Year Opened | Headcount |
|---------------|--------------------------------|----------------------------|---------------------------|-------------|-----------|
| **PLT-DET**   | Detroit Main Plant             | Detroit, Michigan, USA     | Primary machining & assembly | 1998     | 980       |
| **PLT-CLV**   | Cleveland Precision Center     | Cleveland, Ohio, USA       | High-volume CNC machining  | 2004        | 620       |
| **PLT-CHI**   | Chicago Components Facility    | Rockford, Illinois, USA    | Stamping & forming         | 2011        | 490       |
| **PLT-MTY**   | Monterrey Finishing Plant      | Monterrey, Nuevo León, MX  | Surface finishing & sub-assembly | 2017  | 310       |

### 3.2 Facility Detail

#### PLT-DET — Detroit Main Plant (Primary Facility)

The flagship facility and corporate headquarters location. PLT-DET houses the most complex CNC machining operations, the central quality laboratory, the engineering and R&D function, and the corporate data center. This facility is the primary source system generating the operational data that SMAP ingests and analyzes.

| Attribute              | Detail                                            |
|------------------------|---------------------------------------------------|
| **Floor Area**         | 185,000 sq ft (machining, assembly, warehouse)    |
| **Production Lines**   | 4 active production lines (LINE-A through LINE-D) |
| **Shift Pattern**      | Three 8-hour shifts, 6 days per week              |
| **Primary Capability** | CNC turning, milling, grinding, precision assembly |
| **Machines**           | 48 production machines (CNC, press, conveyor, assembly) |

#### PLT-CLV — Cleveland Precision Center

High-volume, lights-out machining facility optimized for large batch runs of standardized components. Heavily automated with robotic part loading and in-process gauging.

| Attribute              | Detail                                              |
|------------------------|-----------------------------------------------------|
| **Floor Area**         | 120,000 sq ft                                       |
| **Production Lines**   | 3 active production lines (LINE-E through LINE-G)   |
| **Shift Pattern**      | Three 8-hour shifts, 7 days per week (continuous)   |
| **Primary Capability** | High-volume CNC turning, automated gauging           |

#### PLT-CHI — Chicago Components Facility

Stamping and metal forming operations producing blanks and formed components that feed both PLT-DET and PLT-CLV. Houses heavy presses ranging from 400 to 2,000 tons.

| Attribute              | Detail                                              |
|------------------------|-----------------------------------------------------|
| **Floor Area**         | 98,000 sq ft                                        |
| **Production Lines**   | 2 active production lines (LINE-H through LINE-I)   |
| **Shift Pattern**      | Two 10-hour shifts, 5 days per week                 |
| **Primary Capability** | Progressive die stamping, deep drawing, roll forming |

#### PLT-MTY — Monterrey Finishing Plant

Handles electroplating, powder coating, heat treatment, and sub-assembly operations. Receives components from all US facilities and ships finished goods directly to customer warehouses in Mexico.

| Attribute              | Detail                                              |
|------------------------|-----------------------------------------------------|
| **Floor Area**         | 75,000 sq ft                                        |
| **Production Lines**   | 2 active lines (LINE-J through LINE-K)              |
| **Shift Pattern**      | Two 8-hour shifts, 5 days per week                  |
| **Primary Capability** | Electroplating, heat treatment, powder coating, sub-assembly |

> **SMAP Scope:** The Smart Manufacturing Analytics Platform is initially scoped to the **PLT-DET (Detroit Main Plant)** facility, which is the highest-volume, highest-complexity operation and represents the greatest opportunity for analytics-driven improvement. Future phases will extend the platform to all four facilities.

---

## 4. Products Manufactured

PrecisionEdge produces four primary product families, each serving distinct customer market segments.

### 4.1 Product Families

| Product Family Code | Product Family Name         | Customer Segment            | Annual Volume    | Primary Process      |
|---------------------|-----------------------------|-----------------------------|------------------|----------------------|
| **PF-PWR**          | Powertrain Components       | Automotive OEM/Tier-1       | ~1,400,000 units | CNC turning, grinding |
| **PF-BRK**          | Brake System Components     | Automotive OEM/Tier-1       | ~880,000 units   | CNC milling, assembly |
| **PF-STR**          | Steering & Suspension Parts | Automotive OEM/Tier-1       | ~560,000 units   | CNC turning, forming  |
| **PF-IND**          | Industrial Machinery Parts  | Industrial OEM              | ~360,000 units   | Multi-process         |

### 4.2 Key Product Lines (PLT-DET focus)

| Product Code    | Product Name                  | Family    | Standard Cycle Time | Quality Spec        | Key Customer Requirement          |
|-----------------|-------------------------------|-----------|---------------------|---------------------|-----------------------------------|
| **PRD-001**     | Crankshaft Bearing Journals   | PF-PWR    | 4.2 min/unit        | ±0.005mm tolerance  | PPAP Level 3, Cpk ≥ 1.67          |
| **PRD-002**     | Transmission Gear Blanks      | PF-PWR    | 2.8 min/unit        | ±0.010mm tolerance  | 100% dimensional verification     |
| **PRD-003**     | Brake Caliper Housings        | PF-BRK    | 6.1 min/unit        | ±0.008mm tolerance  | Pressure test on 100% of output   |
| **PRD-004**     | Brake Disc Hubs               | PF-BRK    | 3.5 min/unit        | ±0.012mm tolerance  | Surface finish Ra ≤ 0.8 μm        |
| **PRD-005**     | Steering Rack Housings        | PF-STR    | 8.4 min/unit        | ±0.006mm tolerance  | Leak test, PPAP Level 3           |
| **PRD-006**     | Ball Joint Components         | PF-STR    | 1.9 min/unit        | ±0.015mm tolerance  | Hardness verification             |
| **PRD-007**     | Hydraulic Cylinder Barrels    | PF-IND    | 5.6 min/unit        | ±0.010mm tolerance  | Surface honing spec               |
| **PRD-008**     | Industrial Coupling Flanges   | PF-IND    | 3.2 min/unit        | ±0.020mm tolerance  | Bolt pattern true position spec   |

### 4.3 Product Hierarchy

```
Product Category
└── Product Family (PF-PWR, PF-BRK, PF-STR, PF-IND)
    └── Product Line (e.g., Brake System Components)
        └── Product (PRD-001 through PRD-008)
            └── Variant (material grade, surface finish, customer-specific print)
```

---

## 5. Organizational Departments

PrecisionEdge is organized into eight functional departments. Each department has a defined role in the production ecosystem and generates or consumes data relevant to SMAP.

### 5.1 Department Summary

| Dept Code | Department Name            | Head Count (PLT-DET) | Primary Data Role                                      |
|-----------|----------------------------|----------------------|--------------------------------------------------------|
| **DEPT-OPS** | Manufacturing Operations | 420                  | **Generates:** production orders, shift logs, cycle time records |
| **DEPT-QA**  | Quality Assurance        | 75                   | **Generates:** inspection records, defect logs, PPAP documentation |
| **DEPT-MNT** | Maintenance & Reliability | 62                   | **Generates:** work orders, downtime events, PM schedules |
| **DEPT-ENG** | Process Engineering      | 55                   | **Consumes:** sensor data, quality trends; **Generates:** process change records |
| **DEPT-PLN** | Production Planning      | 38                   | **Generates:** production schedules; **Consumes:** OEE, throughput KPIs |
| **DEPT-SCM** | Supply Chain Management  | 44                   | **Generates:** inventory transactions; **Consumes:** production demand |
| **DEPT-FIN** | Finance                  | 30                   | **Consumes:** cost-per-part, scrap value, labor efficiency |
| **DEPT-IT**  | Information Technology   | 18                   | **Operates:** ERP, MES, SCADA infrastructure          |

### 5.2 Department Roles in Analytics

| Department          | Primary KPIs Consumed                         | Dashboard Views Used             |
|---------------------|-----------------------------------------------|----------------------------------|
| Manufacturing Ops   | OEE, Throughput, Cycle Time, Production Efficiency | OEE Overview, Production Throughput |
| Quality Assurance   | Defect Rate, First Pass Yield, Cpk            | Quality Control Dashboard        |
| Maintenance         | MTBF, MTTR, Downtime, Planned vs. Unplanned   | Maintenance & Reliability        |
| Process Engineering | Sensor trends, Anomaly alerts, SPC charts     | Quality Control, Sensor Monitor  |
| Production Planning | OEE gap, Throughput vs. plan, Shift performance | OEE Overview, Production Throughput |
| Finance             | Scrap cost, Labor efficiency, Energy cost     | All dashboards (cost dimensions) |

---

## 6. Business Goals

PrecisionEdge has defined five strategic business goals for the 2025–2027 planning horizon. These goals directly inform the analytical requirements and KPI targets built into SMAP.

### 6.1 Strategic Goals

#### Goal 1 — Achieve 82% Fleet-Wide OEE by Q4 2027

**Current Baseline:** 68% OEE (industry benchmark for automotive Tier-2: 75–85%)

PrecisionEdge's OEE is below the industry benchmark primarily due to high unplanned downtime (availability losses) and above-average scrap rates (quality losses). The SMAP platform's OEE dashboard and predictive maintenance models directly support this goal by surfacing the root causes of availability and quality losses in real time.

| OEE Component  | Current (FY2025) | Target (Q4 2027) | Gap   |
|----------------|------------------|------------------|-------|
| Availability   | 78%              | 88%              | −10%  |
| Performance    | 84%              | 91%              | −7%   |
| Quality        | 97.2%            | 99.1%            | −1.9% |
| **OEE Overall**| **68%**          | **82%**          | **−14%** |

#### Goal 2 — Reduce Unplanned Downtime by 40% by End of FY2026

**Current Baseline:** ~12.4% of scheduled production time lost to unplanned stops

Unplanned downtime is the single largest contributor to the OEE gap. SMAP's predictive maintenance model is the primary digital enabler for this goal: by forecasting failure risk 7+ days in advance, maintenance teams can schedule preventive intervention during planned stops rather than reacting to breakdowns.

#### Goal 3 — Reduce Scrap Rate to Below 1.5% by Q2 2027

**Current Baseline:** 2.8% overall scrap rate (value: ~$8.4M/year in scrapped material)

Scrap directly impacts material cost, delivery reliability, and customer scorecard performance. SMAP's quality prediction model and real-time SPC charting enable process engineers to intervene before defect-producing conditions persist through a full production run.

#### Goal 4 — Reduce Reporting Cycle from 48 Hours to Under 2 Hours

**Current Baseline:** Shift-level KPI reports take 24–48 hours to compile manually in Excel

Operational decision-making is currently based on data that is at least one full shift old. SMAP's automated ETL pipeline and near-real-time dashboards compress the reporting cycle to under 2 hours for shift-level data, enabling supervisors and managers to course-correct within the same production period.

#### Goal 5 — Reduce Energy Consumption per Unit by 15% by End of FY2027

**Current Baseline:** ~4.2 kWh per good unit produced (PLT-DET)

Energy cost represents 6.8% of PrecisionEdge's total cost of goods. SMAP's energy monitoring through IoT sensor data enables visibility into idle machine energy consumption, peak demand patterns, and energy cost per production order — providing the foundation for targeted energy reduction initiatives.

### 6.2 Goal-to-Platform Capability Mapping

| Business Goal                         | SMAP Capability                              | Expected Impact                          |
|---------------------------------------|----------------------------------------------|------------------------------------------|
| 82% OEE by Q4 2027                    | OEE Dashboard, Predictive Maintenance model  | Identify and close availability & quality gaps |
| −40% unplanned downtime               | Predictive Maintenance model, Anomaly Detection | Prevent failures; optimize PM scheduling |
| Scrap < 1.5%                          | Quality Prediction model, SPC charts         | Early process correction; defect prevention |
| Reporting cycle < 2 hours             | Automated ETL pipeline, near-real-time dashboards | Eliminate manual spreadsheet reporting   |
| −15% energy per unit                  | IoT energy sensors, Production Efficiency KPI | Idle-time visibility, energy per order   |

---

## 7. Competitive Position

PrecisionEdge operates in a highly competitive automotive supplier market. Its primary competitive differentiators are:

1. **Precision capability** — Tolerances down to ±0.005mm on complex geometries, supported by advanced metrology equipment
2. **Quality reliability** — Sub-2,000 PPM defect history with key Tier-1 customers (target: sub-500 PPM)
3. **Delivery performance** — 96.8% on-time delivery (OTD) record over the past 24 months
4. **Manufacturing agility** — Ability to run low-volume, high-mix production alongside high-volume commodity runs

The SMAP platform is positioned as a strategic enabler of competitive differentiation: enabling PrecisionEdge to achieve world-class OEE and quality metrics that translate directly into better pricing, preferred supplier status, and new customer wins.

---

*This document is the foundational business context for all SMAP analytics, KPI definitions, and domain modeling. All subsequent documentation builds upon the company profile established here. Last reviewed: 2026-07-22.*
