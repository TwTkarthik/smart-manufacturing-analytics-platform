-- =============================================================================
-- 08_seed.sql
-- SMAP Operational Database — Static Reference Data
-- Seeds all static reference tables with canonical business data.
-- Safe to re-run (uses INSERT ... ON CONFLICT DO NOTHING).
-- Run AFTER 05_constraints.sql.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- production_lines
-- Source: COMPANY_PROFILE.md §3.1 + MANUFACTURING_PROCESS.md §2.1
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO production_lines (line_code, line_name, plant_code, primary_operation, shift_pattern, oee_target, is_active)
VALUES
    ('LINE-A', 'Powertrain Turning Cell',       'PLT-DET', 'CNC Turning and Grinding',     '3-shift, 6 days/week', 0.8100, TRUE),
    ('LINE-B', 'Brake Components Cell',         'PLT-DET', 'CNC Milling and Boring',       '3-shift, 6 days/week', 0.7800, TRUE),
    ('LINE-C', 'Steering and Suspension Cell',  'PLT-DET', 'CNC Turning and Boring',       '3-shift, 5 days/week', 0.7600, TRUE),
    ('LINE-D', 'Multi-Process / Assembly',      'PLT-DET', 'Mixed Machining and Assembly', '2-shift, 5 days/week', 0.7200, TRUE),
    ('LINE-E', 'CLV High-Volume Turning A',     'PLT-CLV', 'High-Volume CNC Turning',      '3-shift, 7 days/week', 0.8400, TRUE),
    ('LINE-F', 'CLV High-Volume Turning B',     'PLT-CLV', 'High-Volume CNC Turning',      '3-shift, 7 days/week', 0.8400, TRUE),
    ('LINE-G', 'CLV Gauging and Finish',        'PLT-CLV', 'Automated Gauging and Finish', '3-shift, 7 days/week', 0.8600, TRUE),
    ('LINE-H', 'CHI Stamping Line A',           'PLT-CHI', 'Progressive Die Stamping',     '2-shift, 5 days/week', 0.7800, TRUE),
    ('LINE-I', 'CHI Forming Line B',            'PLT-CHI', 'Deep Drawing and Roll Forming','2-shift, 5 days/week', 0.7500, TRUE),
    ('LINE-J', 'MTY Finishing Line A',          'PLT-MTY', 'Electroplating and Coating',   '3-shift, 5 days/week', 0.8000, TRUE),
    ('LINE-K', 'MTY Sub-Assembly Line B',       'PLT-MTY', 'Sub-Assembly and Packaging',   '2-shift, 5 days/week', 0.7700, TRUE)
ON CONFLICT (line_code) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- shifts
-- Source: MANUFACTURING_PROCESS.md §4.2
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO shifts (shift_code, shift_name, shift_start_time, shift_end_time, shift_duration_hours, planned_production_hours, plant_code)
VALUES
    -- PLT-DET shifts
    ('SHIFT-A', 'Day Shift',       '06:00:00', '14:00:00', 8.00, 7.50, 'PLT-DET'),
    ('SHIFT-B', 'Afternoon Shift', '14:00:00', '22:00:00', 8.00, 7.50, 'PLT-DET'),
    ('SHIFT-C', 'Night Shift',     '22:00:00', '06:00:00', 8.00, 7.50, 'PLT-DET'),
    -- PLT-CLV shifts (continuous 7-day operation)
    ('SHIFT-D', 'Day Shift',       '06:00:00', '14:00:00', 8.00, 7.75, 'PLT-CLV'),
    ('SHIFT-E', 'Afternoon Shift', '14:00:00', '22:00:00', 8.00, 7.75, 'PLT-CLV'),
    ('SHIFT-F', 'Night Shift',     '22:00:00', '06:00:00', 8.00, 7.75, 'PLT-CLV'),
    -- PLT-CHI shifts (2-shift, 10-hour)
    ('SHIFT-G', 'Day Shift',       '06:00:00', '16:00:00', 10.00, 9.50, 'PLT-CHI'),
    ('SHIFT-H', 'Afternoon Shift', '16:00:00', '02:00:00', 10.00, 9.50, 'PLT-CHI'),
    -- PLT-MTY shifts
    ('SHIFT-I', 'Day Shift',       '07:00:00', '15:00:00', 8.00, 7.50, 'PLT-MTY'),
    ('SHIFT-J', 'Afternoon Shift', '15:00:00', '23:00:00', 8.00, 7.50, 'PLT-MTY')
ON CONFLICT (shift_code) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- defect_types
-- Source: BUSINESS_GLOSSARY.md + Quality domain knowledge
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO defect_types (defect_type_code, defect_type_name, defect_category, severity_level, is_customer_escape_risk, description, is_active)
VALUES
    ('DFT-DIM-OOS', 'Dimensional Out-of-Specification',    'Dimensional',  'Critical', TRUE,  'Part dimension outside drawing tolerance. Common causes: tool wear, thermal expansion, setup error.', TRUE),
    ('DFT-DIM-TPR', 'Taper or Runout Error',               'Dimensional',  'Major',    TRUE,  'Geometric tolerance violation (concentricity, taper, runout). Detected by CMM.', TRUE),
    ('DFT-DIM-THR', 'Thread Form Defect',                  'Dimensional',  'Critical', TRUE,  'Thread pitch, diameter, or form outside specification. Detected by thread gauge.', TRUE),
    ('DFT-SURF-SCR', 'Surface Scratch or Score',           'Surface',      'Minor',    FALSE, 'Surface mark from handling or machining. Assessed per surface finish Ra specification.', TRUE),
    ('DFT-SURF-PIT', 'Pitting or Porosity',                'Surface',      'Major',    TRUE,  'Material porosity (from casting) breaking through machined surface. Structural risk on bearing surfaces.', TRUE),
    ('DFT-SURF-RGH', 'Surface Roughness Out-of-Spec',      'Surface',      'Major',    TRUE,  'Ra/Rz surface roughness exceeds specification. Measured by profilometer.', TRUE),
    ('DFT-SURF-BRN', 'Thermal Burn (Grinding)',            'Surface',      'Critical', TRUE,  'Heat-induced surface damage from grinding. Visible as discoloration. Affects fatigue life.', TRUE),
    ('DFT-STRUCT-CRK', 'Crack (Surface or Sub-surface)',   'Structural',   'Critical', TRUE,  'Material crack detected by MPI or dye penetrant. Immediate rejection and quarantine required.', TRUE),
    ('DFT-STRUCT-HAR', 'Hardness Out-of-Specification',    'Structural',   'Critical', TRUE,  'Hardness (HRC/HB) outside specification after heat treatment. Affects wear and fatigue life.', TRUE),
    ('DFT-STRUCT-MAT', 'Wrong Material / Mix-up',          'Structural',   'Critical', TRUE,  'Material grade does not match specification. Detected by PMI (positive material identification).', TRUE),
    ('DFT-FUNC-PRES', 'Failed Pressure Test',              'Functional',   'Critical', TRUE,  'Component fails pressure/leak test. Applies to brake calipers and hydraulic housings.', TRUE),
    ('DFT-FUNC-ASSY', 'Assembly Interference or Mis-fit',  'Functional',   'Major',    TRUE,  'Component does not assemble correctly with mating part. Detected in functional assembly check.', TRUE),
    ('DFT-OTHER-CONT', 'Contamination (Foreign Material)', 'Other',        'Major',    FALSE, 'Foreign material (chips, coolant residue, debris) present on or in the part.', TRUE),
    ('DFT-OTHER-MARK', 'Missing or Incorrect Marking',     'Other',        'Minor',    FALSE, 'Part number stamp, traceability mark, or date code missing or incorrect.', TRUE),
    ('DFT-OTHER-UNK',  'Defect — Unclassified',            'Other',        'Minor',    FALSE, 'Defect present but not yet classified by QA technician. Requires root cause investigation.', TRUE)
ON CONFLICT (defect_type_code) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- products
-- Source: MANUFACTURING_PROCESS.md §2.1, COMPANY_PROFILE.md §4
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO products (product_code, product_name, product_family, product_category, standard_cycle_time_sec, standard_material_cost, standard_labor_cost, is_active, erp_material_code)
VALUES
    -- Powertrain family (LINE-A)
    ('PRD-001', 'Crankshaft Bearing Journal — Type A', 'Powertrain Components', 'Automotive', 150.0, 42.50, 8.75, TRUE, 'MAT-PWR-001'),
    ('PRD-002', 'Transmission Gear Blank — Grade 5',  'Powertrain Components', 'Automotive', 228.0, 38.20, 9.10, TRUE, 'MAT-PWR-002'),
    -- Brake family (LINE-B)
    ('PRD-003', 'Brake Caliper Housing — Type B2',    'Brake Components',      'Automotive', 228.0, 61.80, 12.40, TRUE, 'MAT-BRK-003'),
    ('PRD-004', 'Brake Bracket Precision Bore',       'Brake Components',      'Automotive', 192.0, 29.90, 7.60, TRUE, 'MAT-BRK-004'),
    -- Steering & Suspension family (LINE-C)
    ('PRD-005', 'Steering Housing — Precision Turn',  'Steering Components',   'Automotive', 252.0, 55.30, 11.20, TRUE, 'MAT-STR-005'),
    ('PRD-006', 'Suspension Knuckle — CNC Turned',    'Suspension Components', 'Automotive', 204.0, 48.70, 10.80, TRUE, 'MAT-SUS-006'),
    -- Multi-Process / Industrial family (LINE-D)
    ('PRD-007', 'Industrial Flange — 4-Bolt Pattern', 'Industrial Components', 'Industrial', 180.0, 31.50, 6.90, TRUE, 'MAT-IND-007'),
    ('PRD-008', 'Precision Shaft Assembly — 250mm',   'Industrial Components', 'Industrial', 510.0, 74.20, 18.50, TRUE, 'MAT-IND-008')
ON CONFLICT (product_code) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- spare_parts (representative catalog subset — 20 parts)
-- Source: MANUFACTURING_PROCESS.md §5 (maintenance domain)
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO spare_parts (part_code, part_description, part_category, stock_qty, reorder_point, lead_time_days, unit_cost, supplier_code)
VALUES
    ('SP-BEAR-6205', 'Deep groove ball bearing 6205-2RS, 25x52x15mm',        'Bearings',    24,  8,  5,  12.50,  'SUP-SKF-001'),
    ('SP-BEAR-6206', 'Deep groove ball bearing 6206-2RS, 30x62x16mm',        'Bearings',    18,  6,  5,  15.80,  'SUP-SKF-001'),
    ('SP-BEAR-7210', 'Angular contact bearing 7210-BECBP, 50x90x20mm',       'Bearings',    12,  4,  7,  42.30,  'SUP-SKF-001'),
    ('SP-SEAL-VMQ30', 'VMQ oil seal 30x47x7mm, lip type',                    'Seals',       50,  15, 3,   4.20,  'SUP-PARKER-001'),
    ('SP-SEAL-VMQ45', 'VMQ oil seal 45x62x8mm, lip type',                    'Seals',       45,  12, 3,   5.60,  'SUP-PARKER-001'),
    ('SP-FILT-HYD5', 'Hydraulic oil filter 10 micron, spin-on type',         'Filters',     30,  10, 4,  18.90,  'SUP-MANN-001'),
    ('SP-FILT-COOL3', 'Coolant filter cartridge 25 micron',                  'Filters',     40,  12, 4,   9.75,  'SUP-MANN-001'),
    ('SP-BELT-VBB78', 'V-belt, cross-section B, reference length 78 in',     'Belts',       15,  5,  6,  22.40,  'SUP-GATES-001'),
    ('SP-BELT-SPB280','Narrow V-belt SPB-2800, 22x2800mm',                   'Belts',       10,  4,  6,  34.60,  'SUP-GATES-001'),
    ('SP-ELEC-RELAY','24V DC relay coil, 10A contact rating',                'Electronics', 20,  8,  8,   8.30,  'SUP-OMRON-001'),
    ('SP-ELEC-FUSE',  'Control circuit fuse 2A, 5x20mm ceramic',             'Electronics', 100, 30, 2,   0.85,  'SUP-OMRON-001'),
    ('SP-ELEC-ENCDR', 'Incremental encoder 1024 PPR, 10mm shaft',            'Electronics',  6,  2,  14, 128.50, 'SUP-HEID-001'),
    ('SP-HYD-PUMP', 'Hydraulic gear pump 16 cc/rev, SAE B mount',            'Hydraulics',   4,  2,  21, 385.00, 'SUP-PARKER-001'),
    ('SP-HYD-VALVE', 'Solenoid directional control valve, 4/2 NG6, 24VDC',  'Hydraulics',   8,  3,  14, 145.00, 'SUP-BOSCH-001'),
    ('SP-TOOL-INSERT','Carbide turning insert CNMG 120408-MF2 grade IC8250',  'Tooling',    200, 60,  2,   4.15,  'SUP-ISCAR-001'),
    ('SP-TOOL-DRILL', 'Solid carbide drill 12.0mm, TiAlN coated',            'Tooling',     30,  10, 5,  38.50,  'SUP-ISCAR-001'),
    ('SP-TOOL-ENDML', 'Solid carbide end mill 16mm 4-flute, TiAlN coated',   'Tooling',     20,   8, 5,  62.30,  'SUP-SECO-001'),
    ('SP-COOL-CONC',  'Semi-synthetic coolant concentrate 5L, Mobilcut 322', 'Other',       60,  20, 3,  28.90,  'SUP-EXXON-001'),
    ('SP-LUB-GREASE', 'Lithium EP grease 400g cartridge, NLGI Grade 2',      'Other',       40,  15, 3,   6.40,  'SUP-SHELL-001'),
    ('SP-SENS-PROX',  'Inductive proximity sensor M18 NPN, Sn=8mm, 24VDC',  'Electronics', 15,   5, 7,  35.20,  'SUP-OMRON-001')
ON CONFLICT (part_code) DO NOTHING;
