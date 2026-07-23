-- =============================================================================
-- seed.sql
-- SMAP Operational Database — Static Reference Data
-- PostgreSQL 16 compatible.
--
-- Execution order: 8 of 9
-- Run AFTER roles.sql (and AFTER constraints.sql is applied).
--
-- Seeds all static reference tables with canonical business data derived from:
--   - docs/COMPANY_PROFILE.md        §3.1 (plants and lines)
--   - docs/MANUFACTURING_PROCESS.md  §2.1 (products, shift patterns)
--   - docs/BUSINESS_GLOSSARY.md      (defect types and quality domain)
--   - docs/DB_DATA_DICTIONARY.md     (data types and field semantics)
--
-- Safe to re-run: all INSERTs use ON CONFLICT DO NOTHING (idempotent).
--
-- Seeding order (respects FK constraints):
--   1. production_lines   (no FK dependencies)
--   2. shifts             (no FK dependencies)
--   3. defect_types       (no FK dependencies)
--   4. products           (no FK dependencies)
--   5. spare_parts        (no FK dependencies)
--   6. employees          (FK → shifts — must come after shifts)
--
-- Tables NOT seeded here (populated by ETL pipeline from source systems):
--   machines, production_orders, downtime_events, sensor_readings,
--   quality_inspections, pm_schedules, maintenance_logs, material_movements
--
-- Canonical numbered source: database/sql/08_seed.sql
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- 1. production_lines
-- Source: COMPANY_PROFILE.md §3.1 + MANUFACTURING_PROCESS.md §2.1
-- 11 production lines across 4 plants.
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO production_lines (line_code, line_name, plant_code, primary_operation, shift_pattern, oee_target, is_active)
VALUES
    -- PLT-DET (Detroit — primary facility, focus of Sprint 1-2 analytics)
    ('LINE-A', 'Powertrain Turning Cell',       'PLT-DET', 'CNC Turning and Grinding',      '3-shift, 6 days/week', 0.8100, TRUE),
    ('LINE-B', 'Brake Components Cell',         'PLT-DET', 'CNC Milling and Boring',        '3-shift, 6 days/week', 0.7800, TRUE),
    ('LINE-C', 'Steering and Suspension Cell',  'PLT-DET', 'CNC Turning and Boring',        '3-shift, 5 days/week', 0.7600, TRUE),
    ('LINE-D', 'Multi-Process / Assembly',      'PLT-DET', 'Mixed Machining and Assembly',  '2-shift, 5 days/week', 0.7200, TRUE),
    -- PLT-CLV (Cleveland — continuous 7-day high-volume production)
    ('LINE-E', 'CLV High-Volume Turning A',     'PLT-CLV', 'High-Volume CNC Turning',       '3-shift, 7 days/week', 0.8400, TRUE),
    ('LINE-F', 'CLV High-Volume Turning B',     'PLT-CLV', 'High-Volume CNC Turning',       '3-shift, 7 days/week', 0.8400, TRUE),
    ('LINE-G', 'CLV Gauging and Finish',        'PLT-CLV', 'Automated Gauging and Finish',  '3-shift, 7 days/week', 0.8600, TRUE),
    -- PLT-CHI (Chicago — stamping and forming, 10-hour shifts)
    ('LINE-H', 'CHI Stamping Line A',           'PLT-CHI', 'Progressive Die Stamping',      '2-shift, 5 days/week', 0.7800, TRUE),
    ('LINE-I', 'CHI Forming Line B',            'PLT-CHI', 'Deep Drawing and Roll Forming', '2-shift, 5 days/week', 0.7500, TRUE),
    -- PLT-MTY (Monterrey — finishing and sub-assembly)
    ('LINE-J', 'MTY Finishing Line A',          'PLT-MTY', 'Electroplating and Coating',    '3-shift, 5 days/week', 0.8000, TRUE),
    ('LINE-K', 'MTY Sub-Assembly Line B',       'PLT-MTY', 'Sub-Assembly and Packaging',    '2-shift, 5 days/week', 0.7700, TRUE)
ON CONFLICT (line_code) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. shifts
-- Source: MANUFACTURING_PROCESS.md §4.2
-- 10 shift definitions: 3 for PLT-DET, 3 for PLT-CLV, 2 for PLT-CHI (10-hr), 2 for PLT-MTY.
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO shifts (shift_code, shift_name, shift_start_time, shift_end_time, shift_duration_hours, planned_production_hours, plant_code)
VALUES
    -- PLT-DET: three 8-hour shifts, 30-min break → 7.5 production hours
    ('SHIFT-A', 'Day Shift',       '06:00:00', '14:00:00', 8.00, 7.50, 'PLT-DET'),
    ('SHIFT-B', 'Afternoon Shift', '14:00:00', '22:00:00', 8.00, 7.50, 'PLT-DET'),
    ('SHIFT-C', 'Night Shift',     '22:00:00', '06:00:00', 8.00, 7.50, 'PLT-DET'),
    -- PLT-CLV: three 8-hour shifts, 15-min break → 7.75 production hours (continuous operation)
    ('SHIFT-D', 'Day Shift',       '06:00:00', '14:00:00', 8.00, 7.75, 'PLT-CLV'),
    ('SHIFT-E', 'Afternoon Shift', '14:00:00', '22:00:00', 8.00, 7.75, 'PLT-CLV'),
    ('SHIFT-F', 'Night Shift',     '22:00:00', '06:00:00', 8.00, 7.75, 'PLT-CLV'),
    -- PLT-CHI: two 10-hour shifts, 30-min break → 9.5 production hours
    ('SHIFT-G', 'Day Shift',       '06:00:00', '16:00:00', 10.00, 9.50, 'PLT-CHI'),
    ('SHIFT-H', 'Afternoon Shift', '16:00:00', '02:00:00', 10.00, 9.50, 'PLT-CHI'),
    -- PLT-MTY: two 8-hour shifts, 30-min break → 7.5 production hours
    ('SHIFT-I', 'Day Shift',       '07:00:00', '15:00:00', 8.00, 7.50, 'PLT-MTY'),
    ('SHIFT-J', 'Afternoon Shift', '15:00:00', '23:00:00', 8.00, 7.50, 'PLT-MTY')
ON CONFLICT (shift_code) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. defect_types
-- Source: BUSINESS_GLOSSARY.md + Quality domain knowledge (IATF 16949 / AIAG)
-- 15 canonical defect codes across 5 categories and 3 severity levels.
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO defect_types (defect_type_code, defect_type_name, defect_category, severity_level, is_customer_escape_risk, description, is_active)
VALUES
    -- Dimensional
    ('DFT-DIM-OOS',  'Dimensional Out-of-Specification',  'Dimensional',  'Critical', TRUE,
     'Part dimension outside drawing tolerance band. Common root causes: tool wear, thermal expansion, fixture shift, setup error.', TRUE),
    ('DFT-DIM-TPR',  'Taper or Runout Error',             'Dimensional',  'Major',    TRUE,
     'Geometric tolerance violation: concentricity, taper, cylindricity, or runout outside spec. Detected by CMM or V-block measurement.', TRUE),
    ('DFT-DIM-THR',  'Thread Form Defect',                'Dimensional',  'Critical', TRUE,
     'Thread pitch diameter, major diameter, or form outside specification. Detected by go/no-go thread gauge. Common on tapped holes after dull taps.', TRUE),
    -- Surface
    ('DFT-SURF-SCR', 'Surface Scratch or Score',          'Surface',      'Minor',    FALSE,
     'Surface mark from handling, tooling contact, or chip abrasion. Assessed against surface finish Ra specification on drawing.', TRUE),
    ('DFT-SURF-PIT', 'Pitting or Porosity',               'Surface',      'Major',    TRUE,
     'Material porosity from raw casting breaking through machined surface. Structural risk on bearing journals and sealing surfaces.', TRUE),
    ('DFT-SURF-RGH', 'Surface Roughness Out-of-Spec',     'Surface',      'Major',    TRUE,
     'Ra/Rz surface roughness exceeds specification measured by contact profilometer. Common on fine-ground or honed surfaces.', TRUE),
    ('DFT-SURF-BRN', 'Thermal Burn (Grinding)',           'Surface',      'Critical', TRUE,
     'Heat-induced surface damage from aggressive grinding: visible as discoloration (temper colors). Affects fatigue life and hardness. Detected by Barkhausen noise or nital etch.', TRUE),
    -- Structural
    ('DFT-STRUCT-CRK', 'Crack (Surface or Sub-surface)', 'Structural',   'Critical', TRUE,
     'Material crack detected by magnetic particle inspection (MPI) or dye penetrant. Immediate rejection and quarantine required. Zero tolerance.', TRUE),
    ('DFT-STRUCT-HAR', 'Hardness Out-of-Specification',  'Structural',   'Critical', TRUE,
     'HRC/HB hardness outside specification after heat treatment or carburizing. Affects wear resistance and fatigue life.', TRUE),
    ('DFT-STRUCT-MAT', 'Wrong Material / Mix-up',        'Structural',   'Critical', TRUE,
     'Material grade does not match drawing specification. Detected by positive material identification (PMI). Requires full lot quarantine.', TRUE),
    -- Functional
    ('DFT-FUNC-PRES', 'Failed Pressure Test',            'Functional',   'Critical', TRUE,
     'Component fails hydraulic pressure or pneumatic leak test. Applies to brake calipers, valve bodies, and hydraulic housings.', TRUE),
    ('DFT-FUNC-ASSY', 'Assembly Interference or Mis-fit','Functional',   'Major',    TRUE,
     'Component fails to assemble correctly with mating part. Detected in functional assembly fit check. Common root cause: dimensional stack-up error.', TRUE),
    -- Other
    ('DFT-OTHER-CONT', 'Contamination (Foreign Material)','Other',       'Major',    FALSE,
     'Foreign material present on or in the part: metallic chips, coolant residue, grinding debris. Risk for precision assemblies.', TRUE),
    ('DFT-OTHER-MARK', 'Missing or Incorrect Marking',   'Other',        'Minor',    FALSE,
     'Part number stamp, traceability mark, heat lot code, or date code missing, incorrect, or illegible. Traceability non-conformance.', TRUE),
    ('DFT-OTHER-UNK',  'Defect — Unclassified',          'Other',        'Minor',    FALSE,
     'Defect present but not yet classified by QA technician. Requires root cause investigation before lot disposition.', TRUE)
ON CONFLICT (defect_type_code) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. products
-- Source: MANUFACTURING_PROCESS.md §2.1 + COMPANY_PROFILE.md §4
-- 8 active products across 5 families manufactured at PLT-DET.
-- standard_cycle_time_sec sourced from ERP routing standards.
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO products (
    product_code, product_name, product_family, product_category,
    standard_cycle_time_sec, standard_material_cost, standard_labor_cost,
    is_active, erp_material_code
)
VALUES
    -- Powertrain family — LINE-A (CNC Turning and Grinding)
    ('PRD-001', 'Crankshaft Bearing Journal — Type A', 'Powertrain Components', 'Automotive',
     150.000,  42.5000,  8.7500, TRUE, 'MAT-PWR-001'),
    ('PRD-002', 'Transmission Gear Blank — Grade 5',   'Powertrain Components', 'Automotive',
     228.000,  38.2000,  9.1000, TRUE, 'MAT-PWR-002'),

    -- Brake family — LINE-B (CNC Milling and Boring)
    ('PRD-003', 'Brake Caliper Housing — Type B2',     'Brake Components',      'Automotive',
     228.000,  61.8000, 12.4000, TRUE, 'MAT-BRK-003'),
    ('PRD-004', 'Brake Bracket Precision Bore',         'Brake Components',      'Automotive',
     192.000,  29.9000,  7.6000, TRUE, 'MAT-BRK-004'),

    -- Steering & Suspension family — LINE-C (CNC Turning and Boring)
    ('PRD-005', 'Steering Housing — Precision Turn',    'Steering Components',   'Automotive',
     252.000,  55.3000, 11.2000, TRUE, 'MAT-STR-005'),
    ('PRD-006', 'Suspension Knuckle — CNC Turned',      'Suspension Components', 'Automotive',
     204.000,  48.7000, 10.8000, TRUE, 'MAT-SUS-006'),

    -- Multi-Process / Industrial family — LINE-D
    ('PRD-007', 'Industrial Flange — 4-Bolt Pattern',  'Industrial Components', 'Industrial',
     180.000,  31.5000,  6.9000, TRUE, 'MAT-IND-007'),
    ('PRD-008', 'Precision Shaft Assembly — 250mm',     'Industrial Components', 'Industrial',
     510.000,  74.2000, 18.5000, TRUE, 'MAT-IND-008')
ON CONFLICT (product_code) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- 5. spare_parts
-- Source: MANUFACTURING_PROCESS.md §5 (maintenance domain)
-- 20 representative parts from the SAP MM parts catalog at PLT-DET.
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO spare_parts (
    part_code, part_description, part_category,
    stock_qty, reorder_point, lead_time_days, unit_cost, supplier_code
)
VALUES
    ('SP-BEAR-6205',  'Deep groove ball bearing 6205-2RS, 25x52x15mm',           'Bearings',    24,   8,  5,   12.5000, 'SUP-SKF-001'),
    ('SP-BEAR-6206',  'Deep groove ball bearing 6206-2RS, 30x62x16mm',           'Bearings',    18,   6,  5,   15.8000, 'SUP-SKF-001'),
    ('SP-BEAR-7210',  'Angular contact bearing 7210-BECBP, 50x90x20mm',          'Bearings',    12,   4,  7,   42.3000, 'SUP-SKF-001'),
    ('SP-SEAL-VMQ30', 'VMQ oil seal 30x47x7mm, lip type',                        'Seals',       50,  15,  3,    4.2000, 'SUP-PARKER-001'),
    ('SP-SEAL-VMQ45', 'VMQ oil seal 45x62x8mm, lip type',                        'Seals',       45,  12,  3,    5.6000, 'SUP-PARKER-001'),
    ('SP-FILT-HYD5',  'Hydraulic oil filter 10 micron, spin-on type',            'Filters',     30,  10,  4,   18.9000, 'SUP-MANN-001'),
    ('SP-FILT-COOL3', 'Coolant filter cartridge 25 micron',                      'Filters',     40,  12,  4,    9.7500, 'SUP-MANN-001'),
    ('SP-BELT-VBB78', 'V-belt, cross-section B, reference length 78 in',         'Belts',       15,   5,  6,   22.4000, 'SUP-GATES-001'),
    ('SP-BELT-SPB280','Narrow V-belt SPB-2800, 22x2800mm',                       'Belts',       10,   4,  6,   34.6000, 'SUP-GATES-001'),
    ('SP-ELEC-RELAY', '24V DC relay coil, 10A contact rating',                   'Electronics', 20,   8,  8,    8.3000, 'SUP-OMRON-001'),
    ('SP-ELEC-FUSE',  'Control circuit fuse 2A, 5x20mm ceramic',                 'Electronics', 100, 30,  2,    0.8500, 'SUP-OMRON-001'),
    ('SP-ELEC-ENCDR', 'Incremental encoder 1024 PPR, 10mm shaft',                'Electronics',  6,   2, 14,  128.5000, 'SUP-HEID-001'),
    ('SP-HYD-PUMP',   'Hydraulic gear pump 16 cc/rev, SAE B mount',             'Hydraulics',   4,   2, 21,  385.0000, 'SUP-PARKER-001'),
    ('SP-HYD-VALVE',  'Solenoid directional control valve, 4/2 NG6, 24VDC',     'Hydraulics',   8,   3, 14,  145.0000, 'SUP-BOSCH-001'),
    ('SP-TOOL-INSERT','Carbide turning insert CNMG 120408-MF2 grade IC8250',     'Tooling',    200,  60,  2,    4.1500, 'SUP-ISCAR-001'),
    ('SP-TOOL-DRILL', 'Solid carbide drill 12.0mm, TiAlN coated',               'Tooling',     30,  10,  5,   38.5000, 'SUP-ISCAR-001'),
    ('SP-TOOL-ENDML', 'Solid carbide end mill 16mm 4-flute, TiAlN coated',      'Tooling',     20,   8,  5,   62.3000, 'SUP-SECO-001'),
    ('SP-COOL-CONC',  'Semi-synthetic coolant concentrate 5L, Mobilcut 322',    'Other',       60,  20,  3,   28.9000, 'SUP-EXXON-001'),
    ('SP-LUB-GREASE', 'Lithium EP grease 400g cartridge, NLGI Grade 2',         'Other',       40,  15,  3,    6.4000, 'SUP-SHELL-001'),
    ('SP-SENS-PROX',  'Inductive proximity sensor M18 NPN, Sn=8mm, 24VDC',      'Electronics', 15,   5,  7,   35.2000, 'SUP-OMRON-001')
ON CONFLICT (part_code) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- 6. employees (reference/pseudo employees)
-- Source: DATA_DICTIONARY.md §2.4
-- Seeds the special EMP-ROBOT pseudo-employee required by production_orders FK,
-- plus a minimal representative roster.
-- The full ~980-employee roster is loaded by the HRIS ETL pipeline (workday_extract).
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO employees (
    employee_id, role_code, role_name, department_code,
    shift_assignment, skill_level, training_certifications,
    hire_date, is_active, is_automated
)
VALUES
    -- Pseudo-employee: represents fully automated machine cycles (no human operator)
    -- Required for production_orders.operator_id FK where machine runs unattended.
    ('EMP-ROBOT',  'OPR-MCH', 'Automated Machine Cycle', 'DEPT-OPS',
     'SHIFT-A',    NULL,       NULL,
     NULL,         TRUE,       TRUE),

    -- System user: ETL pipeline service account for audit trail (created_by fields)
    ('EMP-SYSTEM', 'MNT-PLNR', 'System Service Account',  'DEPT-ENG',
     'SHIFT-A',    'Expert',    'ETL-PIPELINE',
     NULL,         TRUE,       FALSE),

    -- Representative operators — PLT-DET Day Shift (LINE-A)
    ('EMP-0001',   'OPR-MCH',  'Machine Operator',         'DEPT-OPS',
     'SHIFT-A',    'Senior',   'IATF-16949, Lock-Out-Tag-Out',
     '2019-03-15', TRUE,       FALSE),
    ('EMP-0002',   'OPR-MCH',  'Machine Operator',         'DEPT-OPS',
     'SHIFT-A',    'Junior',   'Lock-Out-Tag-Out',
     '2023-07-10', TRUE,       FALSE),
    ('EMP-0003',   'OPR-SET',  'Setup Technician',         'DEPT-OPS',
     'SHIFT-A',    'Expert',   'IATF-16949, Lock-Out-Tag-Out, CNC-Programming',
     '2016-11-01', TRUE,       FALSE),

    -- Representative operators — PLT-DET Afternoon Shift (LINE-A)
    ('EMP-0004',   'OPR-MCH',  'Machine Operator',         'DEPT-OPS',
     'SHIFT-B',    'Senior',   'Lock-Out-Tag-Out',
     '2020-06-22', TRUE,       FALSE),
    ('EMP-0005',   'OPR-SET',  'Setup Technician',         'DEPT-OPS',
     'SHIFT-B',    'Senior',   'IATF-16949, Lock-Out-Tag-Out, CNC-Programming',
     '2018-09-05', TRUE,       FALSE),

    -- Representative operators — PLT-DET Night Shift (LINE-A)
    ('EMP-0006',   'OPR-MCH',  'Machine Operator',         'DEPT-OPS',
     'SHIFT-C',    'Junior',   'Lock-Out-Tag-Out',
     '2024-01-08', TRUE,       FALSE),

    -- QA Technicians — PLT-DET
    ('EMP-0100',   'QA-TECH',  'Quality Technician',       'DEPT-QA',
     'SHIFT-A',    'Expert',   'IATF-16949, CMM-Programming, Six-Sigma-GB',
     '2015-04-20', TRUE,       FALSE),
    ('EMP-0101',   'QA-TECH',  'Quality Technician',       'DEPT-QA',
     'SHIFT-B',    'Senior',   'IATF-16949, CMM-Programming',
     '2021-02-14', TRUE,       FALSE),

    -- Maintenance Technicians — PLT-DET
    ('EMP-0200',   'MNT-TECH', 'Maintenance Technician',   'DEPT-MNT',
     'SHIFT-A',    'Expert',   'Lock-Out-Tag-Out, PLC-Programming, Hydraulics-Level-2',
     '2014-08-11', TRUE,       FALSE),
    ('EMP-0201',   'MNT-TECH', 'Maintenance Technician',   'DEPT-MNT',
     'SHIFT-B',    'Senior',   'Lock-Out-Tag-Out, Hydraulics-Level-1',
     '2019-05-30', TRUE,       FALSE),
    ('EMP-0202',   'MNT-TECH', 'Maintenance Technician',   'DEPT-MNT',
     'SHIFT-C',    'Senior',   'Lock-Out-Tag-Out',
     '2020-11-17', TRUE,       FALSE),

    -- Maintenance Planner — PLT-DET
    ('EMP-0300',   'MNT-PLNR', 'Maintenance Planner',      'DEPT-MNT',
     'SHIFT-A',    'Expert',   'CMRP, Six-Sigma-BB, IATF-16949',
     '2012-06-01', TRUE,       FALSE)
ON CONFLICT (employee_id) DO NOTHING;
