-- =============================================================================
-- JOIN DEMO: Procurement / Supply-Chain Domain
-- =============================================================================
-- Two tables:
--   1. suppliers        (dimension table, ~35 records)
--   2. purchase_orders  (fact table, ~110 records)
--
-- Design choices that make every join type meaningful:
--
--   INNER JOIN        Most POs link to a supplier → matched pairs
--   LEFT  JOIN        suppliers ──► purchase_orders
--                     Some suppliers are approved but have never received a PO
--   RIGHT JOIN        suppliers ◄── purchase_orders
--                     Some POs have NULL supplier_id (spot-buy / emergency buys)
--   FULL OUTER JOIN   Shows both orphan suppliers AND orphan POs in one result
--   SELF  JOIN        suppliers.parent_supplier_id references suppliers
--                     (subsidiaries / regional arms of the same parent company)
--   CROSS JOIN        Every supplier × every fiscal quarter → gap analysis matrix
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. SUPPLIERS  (dimension — 35 rows)
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS purchase_orders;
DROP TABLE IF EXISTS suppliers;

CREATE TABLE suppliers (
    supplier_id          INT           PRIMARY KEY,
    supplier_name        VARCHAR(100)  NOT NULL,
    contact_person       VARCHAR(80),
    email                VARCHAR(120)  NOT NULL,
    phone                VARCHAR(20),
    city                 VARCHAR(60),
    country              VARCHAR(40)   NOT NULL,
    category             VARCHAR(40)   NOT NULL,     -- Raw Materials, Packaging, MRO, IT, Logistics, Professional Services
    payment_terms        VARCHAR(20)   NOT NULL,     -- Net-30, Net-45, Net-60, Net-90
    rating               DECIMAL(2,1)  NOT NULL,     -- 1.0 – 5.0
    contract_start       DATE          NOT NULL,
    contract_end         DATE,                       -- NULL = open-ended / evergreen
    parent_supplier_id   INT           NULL,         -- self-join: subsidiary → parent
    is_approved          BOOLEAN       NOT NULL DEFAULT TRUE
);

INSERT INTO suppliers VALUES
-- ── Raw Materials suppliers ─────────────────────────────────────────────────
(1,  'Apex Steel Corp',          'Robert Lang',      'rlang@apexsteel.com',        '312-555-0101', 'Chicago',       'USA',       'Raw Materials',  'Net-30', 4.5, '2020-01-15', NULL,         NULL, TRUE),
(2,  'Apex Steel – West',        'Linda Choi',       'lchoi@apexsteel-w.com',      '503-555-0102', 'Portland',      'USA',       'Raw Materials',  'Net-30', 4.2, '2021-03-01', NULL,         1,    TRUE),
(3,  'Apex Steel – South',       'Carlos Vega',      'cvega@apexsteel-s.com',      '713-555-0103', 'Houston',       'USA',       'Raw Materials',  'Net-30', 3.9, '2021-06-10', NULL,         1,    TRUE),
(4,  'Nordic Timber AS',         'Erik Lindgren',     'elindgren@nordictimber.no',  NULL,           'Oslo',          'Norway',    'Raw Materials',  'Net-45', 4.7, '2019-05-20', '2025-05-20', NULL, TRUE),
(5,  'Shanghai Polymers Ltd',    'Wei Zhang',         'wzhang@shpolymers.cn',       NULL,           'Shanghai',      'China',     'Raw Materials',  'Net-60', 3.8, '2020-09-01', '2025-08-31', NULL, TRUE),
(6,  'Greenfield Chemicals',     'Patricia Dunn',     'pdunn@greenfieldchem.com',   '614-555-0106', 'Columbus',      'USA',       'Raw Materials',  'Net-30', 4.0, '2021-01-10', NULL,         NULL, TRUE),
(7,  'Atlas Minerals Inc',       'James Okoro',       'jokoro@atlasminerals.com',   '602-555-0107', 'Phoenix',       'USA',       'Raw Materials',  'Net-45', 4.3, '2022-04-01', NULL,         NULL, TRUE),

-- ── Packaging suppliers ─────────────────────────────────────────────────────
(8,  'PackRight Solutions',      'Diane Foster',      'dfoster@packright.com',      '404-555-0108', 'Atlanta',       'USA',       'Packaging',      'Net-30', 4.6, '2019-08-15', NULL,         NULL, TRUE),
(9,  'EcoPack Industries',       'Samuel Green',      'sgreen@ecopack.com',         '215-555-0109', 'Philadelphia',  'USA',       'Packaging',      'Net-30', 4.1, '2020-11-01', NULL,         NULL, TRUE),
(10, 'EcoPack – Canada',         'Marie Tremblay',    'mtremblay@ecopack.ca',       NULL,           'Montreal',      'Canada',    'Packaging',      'Net-45', 3.7, '2022-02-15', NULL,         9,    TRUE),
(11, 'BoxCraft GmbH',            'Klaus Weber',       'kweber@boxcraft.de',         NULL,           'Munich',        'Germany',   'Packaging',      'Net-60', 4.4, '2020-06-20', '2025-06-19', NULL, TRUE),

-- ── MRO (Maintenance, Repair, Operations) ───────────────────────────────────
(12, 'Precision Tools Co',       'Angela Harris',     'aharris@precisiontools.com', '469-555-0112', 'Dallas',        'USA',       'MRO',            'Net-30', 4.8, '2018-03-01', NULL,         NULL, TRUE),
(13, 'SafetyFirst Supplies',     'Tom Bradley',       'tbradley@safetyfirst.com',   '305-555-0113', 'Miami',         'USA',       'MRO',            'Net-30', 4.2, '2019-07-10', NULL,         NULL, TRUE),
(14, 'Industrial Fasteners Ltd', 'Raj Patel',         'rpatel@indfasteners.co.uk',  NULL,           'Birmingham',    'UK',        'MRO',            'Net-45', 3.6, '2021-09-01', '2024-08-31', NULL, TRUE),
(15, 'CleanTech Janitorial',     'Susan Miller',      'smiller@cleantech.com',      '919-555-0115', 'Raleigh',       'USA',       'MRO',            'Net-30', 4.0, '2020-04-15', NULL,         NULL, TRUE),

-- ── IT / Technology suppliers ───────────────────────────────────────────────
(16, 'CloudNine Systems',        'David Park',        'dpark@cloudnine.io',         '415-555-0116', 'San Francisco', 'USA',       'IT',             'Net-30', 4.9, '2019-01-01', NULL,         NULL, TRUE),
(17, 'SecureNet Solutions',      'Karen White',       'kwhite@securenet.com',       '703-555-0117', 'Arlington',     'USA',       'IT',             'Net-30', 4.5, '2020-02-20', NULL,         NULL, TRUE),
(18, 'DataBridge Analytics',     'Michael Ross',      'mross@databridge.com',       '512-555-0118', 'Austin',        'USA',       'IT',             'Net-45', 4.1, '2021-05-10', NULL,         NULL, TRUE),
(19, 'Nexus Hardware Corp',      'Jennifer Liu',      'jliu@nexushw.com',           '408-555-0119', 'San Jose',      'USA',       'IT',             'Net-30', 3.9, '2022-01-15', NULL,         NULL, TRUE),

-- ── Logistics / Freight suppliers ───────────────────────────────────────────
(20, 'SwiftFreight Logistics',   'Brian Murphy',      'bmurphy@swiftfreight.com',   '901-555-0120', 'Memphis',       'USA',       'Logistics',      'Net-30', 4.3, '2018-06-01', NULL,         NULL, TRUE),
(21, 'TransGlobal Shipping',     'Anna Kowalski',     'akowalski@transglobal.com',  NULL,           'Rotterdam',     'Netherlands','Logistics',     'Net-45', 4.6, '2019-09-15', NULL,         NULL, TRUE),
(22, 'QuickHaul Trucking',       'Mark Jensen',       'mjensen@quickhaul.com',      '816-555-0122', 'Kansas City',   'USA',       'Logistics',      'Net-30', 3.5, '2021-11-01', '2024-10-31', NULL, TRUE),

-- ── Professional Services ───────────────────────────────────────────────────
(23, 'Summit Consulting Group',  'Laura Bennett',     'lbennett@summitcg.com',      '212-555-0123', 'New York',      'USA',       'Professional Services', 'Net-45', 4.7, '2020-03-01', NULL, NULL, TRUE),
(24, 'Bridgepoint Legal LLP',    'Steven Clark',      'sclark@bridgepointlaw.com',  '312-555-0124', 'Chicago',       'USA',       'Professional Services', 'Net-30', 4.4, '2019-11-20', NULL, NULL, TRUE),
(25, 'Pinnacle Accounting',      'Nancy Adams',       'nadams@pinnacleacct.com',    '617-555-0125', 'Boston',        'USA',       'Professional Services', 'Net-30', 4.0, '2020-07-10', NULL, NULL, TRUE),
(26, 'TalentForge HR',           'Derek Hughes',      'dhughes@talentforge.com',    '206-555-0126', 'Seattle',       'USA',       'Professional Services', 'Net-30', 3.8, '2022-08-01', NULL, NULL, TRUE),

-- ── Approved but NEVER ordered from (LEFT JOIN orphans) ─────────────────────
(27, 'GreenLeaf Bio-Materials',  'Olivia Chen',       'ochen@greenleafbio.com',     '503-555-0127', 'Portland',      'USA',       'Raw Materials',  'Net-45', 4.1, '2024-01-05', NULL,         NULL, TRUE),
(28, 'Aurora Coatings Ltd',      'Takeshi Mori',      'tmori@auroracoatings.jp',    NULL,           'Osaka',         'Japan',     'Raw Materials',  'Net-60', 4.3, '2024-02-10', NULL,         NULL, TRUE),
(29, 'FreshPrint Packaging',     'Amara Osei',        'aosei@freshprint.com',       '678-555-0129', 'Atlanta',       'USA',       'Packaging',      'Net-30', 3.9, '2024-03-01', NULL,         NULL, TRUE),
(30, 'SilverLine IT Services',   'Peter Novak',       'pnovak@silverlineit.com',    '720-555-0130', 'Denver',        'USA',       'IT',             'Net-30', 4.0, '2024-02-20', NULL,         NULL, TRUE),
(31, 'Redwood Facilities Mgmt',  'Christine Lee',     'clee@redwoodfm.com',         '916-555-0131', 'Sacramento',    'USA',       'MRO',            'Net-30', 3.7, '2024-04-01', NULL,         NULL, TRUE),

-- ── Deactivated / disqualified suppliers (still have old POs) ───────────────
(32, 'BudgetParts Intl',         'George Tan',        'gtan@budgetparts.com',       NULL,           'Shenzhen',      'China',     'MRO',            'Net-90', 2.1, '2019-01-15', '2022-06-30', NULL, FALSE),
(33, 'CheapShip Express',        'Ivan Petrov',       'ipetrov@cheapship.ru',       NULL,           'Moscow',        'Russia',    'Logistics',      'Net-60', 1.8, '2020-05-01', '2022-12-31', NULL, FALSE),

-- ── Parent-only entity (no direct orders, only subsidiaries order) ──────────
(34, 'Omni Industrial Group',    'Victoria Strand',   'vstrand@omniindustrial.com', '214-555-0134', 'Dallas',        'USA',       'Raw Materials',  'Net-45', 4.6, '2018-01-01', NULL,         NULL, TRUE),
(35, 'Omni – Metals Division',   'Frank Reyes',       'freyes@omni-metals.com',     '214-555-0135', 'Dallas',        'USA',       'Raw Materials',  'Net-45', 4.4, '2019-06-01', NULL,         34,   TRUE);


-- ---------------------------------------------------------------------------
-- 2. PURCHASE_ORDERS  (fact — ~110 rows)
-- ---------------------------------------------------------------------------
-- Includes:
--   • POs linked to registered suppliers (supplier_id NOT NULL)
--   • Spot-buy / emergency POs           (supplier_id NULL → RIGHT JOIN use)
--   • Various statuses: Issued, Received, Partial, Cancelled, Closed

CREATE TABLE purchase_orders (
    po_id            INT            PRIMARY KEY,
    supplier_id      INT            NULL,               -- NULL = spot-buy / emergency purchase
    po_date          DATE           NOT NULL,
    delivery_date    DATE,
    status           VARCHAR(20)    NOT NULL,            -- Issued, Received, Partial, Cancelled, Closed
    department       VARCHAR(40)    NOT NULL,            -- Production, Maintenance, IT, Warehouse, Admin, R&D
    payment_method   VARCHAR(20)    NOT NULL,            -- Invoice, P-Card, Wire Transfer, ACH
    line_items       INT            NOT NULL DEFAULT 1,
    subtotal         DECIMAL(12,2)  NOT NULL,
    tax              DECIMAL(10,2)  NOT NULL,
    freight          DECIMAL(10,2)  NOT NULL,
    total_amount     DECIMAL(12,2)  NOT NULL,
    buyer            VARCHAR(60)    NOT NULL,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

INSERT INTO purchase_orders VALUES
-- ── Apex Steel Corp (supplier 1) — heavy volume ────────────────────────────
(5001, 1,  '2022-02-10', '2022-02-28', 'Closed',    'Production',   'Invoice',       4,  18500.00, 1480.00,  950.00, 20930.00, 'Helen Park'),
(5002, 1,  '2022-05-18', '2022-06-01', 'Closed',    'Production',   'Invoice',       3,  12400.00,  992.00,  750.00, 14142.00, 'Helen Park'),
(5003, 1,  '2022-09-03', '2022-09-20', 'Closed',    'Production',   'Wire Transfer', 5,  31200.00, 2496.00, 1200.00, 34896.00, 'Helen Park'),
(5004, 1,  '2023-01-22', '2023-02-05', 'Closed',    'Production',   'Invoice',       2,   8750.00,  700.00,  450.00,  9900.00, 'Tony Reeves'),
(5005, 1,  '2023-06-14', '2023-06-30', 'Closed',    'Production',   'Invoice',       6,  42000.00, 3360.00, 1500.00, 46860.00, 'Tony Reeves'),
(5006, 1,  '2024-01-05', '2024-01-22', 'Received',  'Production',   'ACH',           3,  15800.00, 1264.00,  800.00, 17864.00, 'Tony Reeves'),

-- ── Apex Steel – West (supplier 2, subsidiary of 1) ────────────────────────
(5007, 2,  '2022-04-02', '2022-04-18', 'Closed',    'Production',   'Invoice',       2,   9200.00,  736.00,  600.00, 10536.00, 'Helen Park'),
(5008, 2,  '2023-03-10', '2023-03-25', 'Closed',    'Production',   'Invoice',       3,  14500.00, 1160.00,  700.00, 16360.00, 'Tony Reeves'),
(5009, 2,  '2024-02-20', '2024-03-05', 'Received',  'Production',   'ACH',           2,  11000.00,  880.00,  550.00, 12430.00, 'Tony Reeves'),

-- ── Apex Steel – South (supplier 3, subsidiary of 1) ───────────────────────
(5010, 3,  '2022-07-15', '2022-08-01', 'Closed',    'Production',   'Invoice',       3,  13600.00, 1088.00,  650.00, 15338.00, 'Helen Park'),
(5011, 3,  '2023-05-08', '2023-05-22', 'Closed',    'Production',   'Invoice',       2,   7800.00,  624.00,  400.00,  8824.00, 'Tony Reeves'),

-- ── Nordic Timber AS (supplier 4) ──────────────────────────────────────────
(5012, 4,  '2022-03-12', '2022-04-15', 'Closed',    'Production',   'Wire Transfer', 3,  22500.00, 1800.00, 2200.00, 26500.00, 'Helen Park'),
(5013, 4,  '2022-08-20', '2022-09-25', 'Closed',    'Production',   'Wire Transfer', 4,  35000.00, 2800.00, 3100.00, 40900.00, 'Helen Park'),
(5014, 4,  '2023-02-05', '2023-03-10', 'Closed',    'Production',   'Wire Transfer', 2,  16800.00, 1344.00, 1800.00, 19944.00, 'Tony Reeves'),
(5015, 4,  '2023-09-18', '2023-10-20', 'Closed',    'Production',   'Wire Transfer', 5,  41200.00, 3296.00, 3500.00, 47996.00, 'Tony Reeves'),
(5016, 4,  '2024-03-01', NULL,         'Issued',    'Production',   'Wire Transfer', 3,  19500.00, 1560.00, 2000.00, 23060.00, 'Tony Reeves'),

-- ── Shanghai Polymers Ltd (supplier 5) ─────────────────────────────────────
(5017, 5,  '2022-06-10', '2022-07-25', 'Closed',    'Production',   'Wire Transfer', 4,  28000.00, 2240.00, 4500.00, 34740.00, 'Helen Park'),
(5018, 5,  '2023-01-15', '2023-02-28', 'Closed',    'Production',   'Wire Transfer', 3,  19500.00, 1560.00, 3800.00, 24860.00, 'Tony Reeves'),
(5019, 5,  '2023-08-22', '2023-10-05', 'Closed',    'Production',   'Wire Transfer', 5,  45000.00, 3600.00, 5200.00, 53800.00, 'Tony Reeves'),

-- ── Greenfield Chemicals (supplier 6) ──────────────────────────────────────
(5020, 6,  '2022-04-20', '2022-05-05', 'Closed',    'Production',   'Invoice',       2,   6400.00,  512.00,  350.00,  7262.00, 'Helen Park'),
(5021, 6,  '2022-10-08', '2022-10-22', 'Closed',    'Production',   'Invoice',       3,   9100.00,  728.00,  400.00, 10228.00, 'Helen Park'),
(5022, 6,  '2023-04-14', '2023-04-28', 'Closed',    'Production',   'ACH',           2,   5800.00,  464.00,  300.00,  6564.00, 'Tony Reeves'),
(5023, 6,  '2023-11-20', '2023-12-05', 'Closed',    'R&D',          'Invoice',       1,   2200.00,  176.00,  150.00,  2526.00, 'Maria Santos'),

-- ── Atlas Minerals Inc (supplier 7) ────────────────────────────────────────
(5024, 7,  '2022-06-25', '2022-07-10', 'Closed',    'Production',   'Invoice',       3,  11500.00,  920.00,  500.00, 12920.00, 'Helen Park'),
(5025, 7,  '2023-02-18', '2023-03-05', 'Closed',    'Production',   'Invoice',       2,   7200.00,  576.00,  350.00,  8126.00, 'Tony Reeves'),
(5026, 7,  '2023-10-10', '2023-10-25', 'Closed',    'Production',   'ACH',           4,  16800.00, 1344.00,  700.00, 18844.00, 'Tony Reeves'),

-- ── PackRight Solutions (supplier 8) ───────────────────────────────────────
(5027, 8,  '2022-03-05', '2022-03-15', 'Closed',    'Warehouse',    'Invoice',       5,   4200.00,  336.00,  200.00,  4736.00, 'Lisa Tran'),
(5028, 8,  '2022-06-18', '2022-06-28', 'Closed',    'Warehouse',    'Invoice',       4,   3800.00,  304.00,  180.00,  4284.00, 'Lisa Tran'),
(5029, 8,  '2022-09-22', '2022-10-02', 'Closed',    'Warehouse',    'Invoice',       6,   5600.00,  448.00,  250.00,  6298.00, 'Lisa Tran'),
(5030, 8,  '2023-01-10', '2023-01-20', 'Closed',    'Warehouse',    'Invoice',       5,   4500.00,  360.00,  200.00,  5060.00, 'Lisa Tran'),
(5031, 8,  '2023-05-05', '2023-05-15', 'Closed',    'Warehouse',    'P-Card',        3,   2800.00,  224.00,  150.00,  3174.00, 'Lisa Tran'),
(5032, 8,  '2023-09-12', '2023-09-22', 'Closed',    'Warehouse',    'Invoice',       4,   3900.00,  312.00,  180.00,  4392.00, 'Lisa Tran'),
(5033, 8,  '2024-01-18', '2024-01-28', 'Received',  'Warehouse',    'ACH',           5,   4800.00,  384.00,  220.00,  5404.00, 'Lisa Tran'),

-- ── EcoPack Industries (supplier 9) ────────────────────────────────────────
(5034, 9,  '2022-05-14', '2022-05-25', 'Closed',    'Warehouse',    'Invoice',       3,   2100.00,  168.00,  120.00,  2388.00, 'Lisa Tran'),
(5035, 9,  '2022-11-28', '2022-12-08', 'Closed',    'Warehouse',    'Invoice',       4,   3200.00,  256.00,  150.00,  3606.00, 'Lisa Tran'),
(5036, 9,  '2023-07-20', '2023-07-30', 'Closed',    'Warehouse',    'P-Card',        2,   1500.00,  120.00,  100.00,  1720.00, 'Lisa Tran'),

-- ── EcoPack – Canada (supplier 10, subsidiary of 9) ────────────────────────
(5037, 10, '2023-04-10', '2023-04-28', 'Closed',    'Warehouse',    'Wire Transfer', 3,   2800.00,  224.00,  350.00,  3374.00, 'Lisa Tran'),
(5038, 10, '2023-12-05', '2023-12-20', 'Closed',    'Warehouse',    'Wire Transfer', 2,   1900.00,  152.00,  280.00,  2332.00, 'Lisa Tran'),

-- ── BoxCraft GmbH (supplier 11) ────────────────────────────────────────────
(5039, 11, '2022-08-08', '2022-09-05', 'Closed',    'Warehouse',    'Wire Transfer', 4,   6200.00,  496.00,  800.00,  7496.00, 'Lisa Tran'),
(5040, 11, '2023-03-15', '2023-04-10', 'Closed',    'Warehouse',    'Wire Transfer', 3,   4800.00,  384.00,  650.00,  5834.00, 'Lisa Tran'),
(5041, 11, '2023-11-01', '2023-11-28', 'Closed',    'Warehouse',    'Wire Transfer', 5,   7500.00,  600.00,  900.00,  9000.00, 'Lisa Tran'),

-- ── Precision Tools Co (supplier 12) ───────────────────────────────────────
(5042, 12, '2022-02-22', '2022-03-05', 'Closed',    'Maintenance',  'P-Card',        6,   3400.00,  272.00,  150.00,  3822.00, 'Dan Brooks'),
(5043, 12, '2022-06-10', '2022-06-20', 'Closed',    'Maintenance',  'P-Card',        4,   2200.00,  176.00,  100.00,  2476.00, 'Dan Brooks'),
(5044, 12, '2022-10-30', '2022-11-10', 'Closed',    'Maintenance',  'Invoice',       5,   2900.00,  232.00,  120.00,  3252.00, 'Dan Brooks'),
(5045, 12, '2023-03-08', '2023-03-18', 'Closed',    'Maintenance',  'P-Card',        3,   1800.00,  144.00,   80.00,  2024.00, 'Dan Brooks'),
(5046, 12, '2023-07-25', '2023-08-05', 'Closed',    'Maintenance',  'Invoice',       7,   4100.00,  328.00,  180.00,  4608.00, 'Dan Brooks'),
(5047, 12, '2024-01-12', '2024-01-22', 'Received',  'Maintenance',  'ACH',           4,   2600.00,  208.00,  100.00,  2908.00, 'Dan Brooks'),

-- ── SafetyFirst Supplies (supplier 13) ─────────────────────────────────────
(5048, 13, '2022-04-15', '2022-04-25', 'Closed',    'Maintenance',  'P-Card',        8,   1800.00,  144.00,   90.00,  2034.00, 'Dan Brooks'),
(5049, 13, '2022-10-18', '2022-10-28', 'Closed',    'Maintenance',  'P-Card',        6,   1400.00,  112.00,   70.00,  1582.00, 'Dan Brooks'),
(5050, 13, '2023-04-22', '2023-05-02', 'Closed',    'Maintenance',  'Invoice',       5,   1200.00,   96.00,   60.00,  1356.00, 'Dan Brooks'),
(5051, 13, '2023-11-10', '2023-11-20', 'Closed',    'Maintenance',  'P-Card',        7,   1650.00,  132.00,   80.00,  1862.00, 'Dan Brooks'),

-- ── Industrial Fasteners Ltd (supplier 14) ─────────────────────────────────
(5052, 14, '2022-01-20', '2022-02-15', 'Closed',    'Maintenance',  'Wire Transfer', 3,   4500.00,  360.00,  550.00,  5410.00, 'Dan Brooks'),
(5053, 14, '2022-09-05', '2022-10-01', 'Closed',    'Maintenance',  'Wire Transfer', 4,   6200.00,  496.00,  700.00,  7396.00, 'Dan Brooks'),

-- ── CleanTech Janitorial (supplier 15) ─────────────────────────────────────
(5054, 15, '2022-05-10', '2022-05-18', 'Closed',    'Admin',        'P-Card',        4,    950.00,   76.00,   40.00,  1066.00, 'Dan Brooks'),
(5055, 15, '2022-11-05', '2022-11-12', 'Closed',    'Admin',        'P-Card',        3,    720.00,   57.60,   30.00,   807.60, 'Dan Brooks'),
(5056, 15, '2023-05-15', '2023-05-22', 'Closed',    'Admin',        'Invoice',       5,   1100.00,   88.00,   45.00,  1233.00, 'Dan Brooks'),
(5057, 15, '2023-11-28', '2023-12-05', 'Closed',    'Admin',        'P-Card',        4,    880.00,   70.40,   35.00,   985.40, 'Dan Brooks'),

-- ── CloudNine Systems (supplier 16) ────────────────────────────────────────
(5058, 16, '2022-01-15', '2022-01-15', 'Closed',    'IT',           'Invoice',       1,  24000.00, 1920.00,    0.00, 25920.00, 'Maria Santos'),
(5059, 16, '2022-07-01', '2022-07-01', 'Closed',    'IT',           'Invoice',       1,  24000.00, 1920.00,    0.00, 25920.00, 'Maria Santos'),
(5060, 16, '2023-01-01', '2023-01-01', 'Closed',    'IT',           'ACH',           1,  26400.00, 2112.00,    0.00, 28512.00, 'Maria Santos'),
(5061, 16, '2023-07-01', '2023-07-01', 'Closed',    'IT',           'ACH',           1,  26400.00, 2112.00,    0.00, 28512.00, 'Maria Santos'),
(5062, 16, '2024-01-01', '2024-01-01', 'Received',  'IT',           'ACH',           1,  28800.00, 2304.00,    0.00, 31104.00, 'Maria Santos'),

-- ── SecureNet Solutions (supplier 17) ──────────────────────────────────────
(5063, 17, '2022-03-20', '2022-03-20', 'Closed',    'IT',           'Invoice',       1,  18000.00, 1440.00,    0.00, 19440.00, 'Maria Santos'),
(5064, 17, '2023-03-20', '2023-03-20', 'Closed',    'IT',           'ACH',           1,  19800.00, 1584.00,    0.00, 21384.00, 'Maria Santos'),
(5065, 17, '2024-03-20', NULL,         'Issued',    'IT',           'ACH',           1,  21600.00, 1728.00,    0.00, 23328.00, 'Maria Santos'),

-- ── DataBridge Analytics (supplier 18) ─────────────────────────────────────
(5066, 18, '2022-08-01', '2022-08-15', 'Closed',    'IT',           'Invoice',       2,   8500.00,  680.00,    0.00,  9180.00, 'Maria Santos'),
(5067, 18, '2023-02-10', '2023-02-25', 'Closed',    'IT',           'ACH',           3,  12000.00,  960.00,    0.00, 12960.00, 'Maria Santos'),
(5068, 18, '2023-08-15', '2023-08-30', 'Closed',    'IT',           'ACH',           2,   9200.00,  736.00,    0.00,  9936.00, 'Maria Santos'),

-- ── Nexus Hardware Corp (supplier 19) ──────────────────────────────────────
(5069, 19, '2022-05-20', '2022-06-01', 'Closed',    'IT',           'P-Card',        8,   6400.00,  512.00,  200.00,  7112.00, 'Maria Santos'),
(5070, 19, '2023-01-28', '2023-02-10', 'Closed',    'IT',           'P-Card',       12,   9800.00,  784.00,  350.00, 10934.00, 'Maria Santos'),
(5071, 19, '2023-09-05', '2023-09-18', 'Closed',    'IT',           'Invoice',       6,   5200.00,  416.00,  150.00,  5766.00, 'Maria Santos'),
(5072, 19, '2024-02-10', '2024-02-22', 'Received',  'IT',           'ACH',          10,   8400.00,  672.00,  280.00,  9352.00, 'Maria Santos'),

-- ── SwiftFreight Logistics (supplier 20) ───────────────────────────────────
(5073, 20, '2022-03-28', '2022-04-05', 'Closed',    'Warehouse',    'Invoice',       1,   3200.00,  256.00,    0.00,  3456.00, 'Lisa Tran'),
(5074, 20, '2022-07-10', '2022-07-18', 'Closed',    'Warehouse',    'Invoice',       1,   4100.00,  328.00,    0.00,  4428.00, 'Lisa Tran'),
(5075, 20, '2022-11-15', '2022-11-22', 'Closed',    'Warehouse',    'Invoice',       1,   2800.00,  224.00,    0.00,  3024.00, 'Lisa Tran'),
(5076, 20, '2023-04-02', '2023-04-10', 'Closed',    'Warehouse',    'ACH',           1,   3500.00,  280.00,    0.00,  3780.00, 'Lisa Tran'),
(5077, 20, '2023-08-20', '2023-08-28', 'Closed',    'Warehouse',    'ACH',           1,   4600.00,  368.00,    0.00,  4968.00, 'Lisa Tran'),

-- ── TransGlobal Shipping (supplier 21) ─────────────────────────────────────
(5078, 21, '2022-04-25', '2022-05-15', 'Closed',    'Warehouse',    'Wire Transfer', 1,   8500.00,  680.00,    0.00,  9180.00, 'Lisa Tran'),
(5079, 21, '2022-10-12', '2022-11-02', 'Closed',    'Warehouse',    'Wire Transfer', 1,  11200.00,  896.00,    0.00, 12096.00, 'Lisa Tran'),
(5080, 21, '2023-06-08', '2023-06-28', 'Closed',    'Warehouse',    'Wire Transfer', 1,   9800.00,  784.00,    0.00, 10584.00, 'Lisa Tran'),
(5081, 21, '2024-01-25', '2024-02-15', 'Received',  'Warehouse',    'Wire Transfer', 1,  10500.00,  840.00,    0.00, 11340.00, 'Lisa Tran'),

-- ── QuickHaul Trucking (supplier 22, now deactivated contract) ─────────────
(5082, 22, '2022-01-05', '2022-01-12', 'Closed',    'Warehouse',    'Invoice',       1,   1800.00,  144.00,    0.00,  1944.00, 'Lisa Tran'),
(5083, 22, '2022-06-20', '2022-06-27', 'Closed',    'Warehouse',    'Invoice',       1,   2200.00,  176.00,    0.00,  2376.00, 'Lisa Tran'),

-- ── Summit Consulting Group (supplier 23) ──────────────────────────────────
(5084, 23, '2022-05-01', '2022-07-31', 'Closed',    'Admin',        'Invoice',       1,  45000.00, 3600.00,    0.00, 48600.00, 'Helen Park'),
(5085, 23, '2023-02-15', '2023-05-15', 'Closed',    'Admin',        'ACH',           1,  52000.00, 4160.00,    0.00, 56160.00, 'Helen Park'),
(5086, 23, '2024-01-10', NULL,         'Partial',   'R&D',          'ACH',           1,  38000.00, 3040.00,    0.00, 41040.00, 'Maria Santos'),

-- ── Bridgepoint Legal LLP (supplier 24) ────────────────────────────────────
(5087, 24, '2022-03-10', '2022-03-31', 'Closed',    'Admin',        'Invoice',       1,  12000.00,  960.00,    0.00, 12960.00, 'Helen Park'),
(5088, 24, '2022-09-15', '2022-10-15', 'Closed',    'Admin',        'Invoice',       1,  15500.00, 1240.00,    0.00, 16740.00, 'Helen Park'),
(5089, 24, '2023-06-01', '2023-07-01', 'Closed',    'Admin',        'ACH',           1,  18000.00, 1440.00,    0.00, 19440.00, 'Helen Park'),

-- ── Pinnacle Accounting (supplier 25) ──────────────────────────────────────
(5090, 25, '2022-02-01', '2022-02-28', 'Closed',    'Admin',        'Invoice',       1,   8500.00,  680.00,    0.00,  9180.00, 'Helen Park'),
(5091, 25, '2023-02-01', '2023-02-28', 'Closed',    'Admin',        'ACH',           1,   9200.00,  736.00,    0.00,  9936.00, 'Helen Park'),
(5092, 25, '2024-02-01', '2024-02-29', 'Received',  'Admin',        'ACH',           1,   9800.00,  784.00,    0.00, 10584.00, 'Helen Park'),

-- ── TalentForge HR (supplier 26) ──────────────────────────────────────────
(5093, 26, '2022-11-01', '2022-12-15', 'Closed',    'Admin',        'Invoice',       1,  22000.00, 1760.00,    0.00, 23760.00, 'Helen Park'),
(5094, 26, '2023-09-10', '2023-10-31', 'Closed',    'Admin',        'ACH',           1,  25000.00, 2000.00,    0.00, 27000.00, 'Helen Park'),

-- ── BudgetParts Intl (supplier 32, disqualified) ───────────────────────────
(5095, 32, '2021-04-10', '2021-05-20', 'Closed',    'Maintenance',  'Wire Transfer', 5,   3200.00,  256.00,  800.00,  4256.00, 'Dan Brooks'),
(5096, 32, '2022-01-18', '2022-03-05', 'Closed',    'Maintenance',  'Wire Transfer', 4,   2800.00,  224.00,  650.00,  3674.00, 'Dan Brooks'),

-- ── CheapShip Express (supplier 33, disqualified) ─────────────────────────
(5097, 33, '2021-08-15', '2021-09-20', 'Closed',    'Warehouse',    'Wire Transfer', 1,   1500.00,  120.00,    0.00,  1620.00, 'Lisa Tran'),
(5098, 33, '2022-05-10', '2022-06-25', 'Cancelled', 'Warehouse',    'Wire Transfer', 1,   2000.00,  160.00,    0.00,  2160.00, 'Lisa Tran'),

-- ── Omni – Metals Division (supplier 35, subsidiary of 34) ─────────────────
(5099, 35, '2022-08-12', '2022-08-28', 'Closed',    'Production',   'Invoice',       3,  14200.00, 1136.00,  600.00, 15936.00, 'Helen Park'),
(5100, 35, '2023-04-20', '2023-05-05', 'Closed',    'Production',   'Invoice',       4,  19500.00, 1560.00,  750.00, 21810.00, 'Tony Reeves'),
(5101, 35, '2023-12-10', '2023-12-28', 'Closed',    'Production',   'ACH',           2,  10800.00,  864.00,  400.00, 12064.00, 'Tony Reeves'),

-- ═══════════════════════════════════════════════════════════════════════════
-- SPOT-BUY / EMERGENCY PURCHASE ORDERS  (supplier_id IS NULL)
-- These are critical for demonstrating RIGHT JOIN and FULL OUTER JOIN.
-- In real procurement, these happen when buyers go off-contract for
-- urgent needs, one-time purchases, or small-dollar convenience buys.
-- ═══════════════════════════════════════════════════════════════════════════
(5102, NULL, '2022-03-15', '2022-03-16', 'Closed',    'Maintenance',  'P-Card',  2,    320.00,   25.60,    0.00,   345.60, 'Dan Brooks'),
(5103, NULL, '2022-06-28', '2022-06-29', 'Closed',    'Production',   'P-Card',  1,    890.00,   71.20,   45.00,  1006.20, 'Helen Park'),
(5104, NULL, '2022-09-10', '2022-09-11', 'Closed',    'IT',           'P-Card',  3,    450.00,   36.00,   15.00,   501.00, 'Maria Santos'),
(5105, NULL, '2022-12-20', '2022-12-21', 'Closed',    'Admin',        'P-Card',  1,    175.00,   14.00,    0.00,   189.00, 'Helen Park'),
(5106, NULL, '2023-02-08', '2023-02-09', 'Closed',    'Maintenance',  'P-Card',  4,    620.00,   49.60,    0.00,   669.60, 'Dan Brooks'),
(5107, NULL, '2023-05-30', '2023-05-31', 'Closed',    'Warehouse',    'P-Card',  2,    280.00,   22.40,   12.00,   314.40, 'Lisa Tran'),
(5108, NULL, '2023-08-14', '2023-08-15', 'Closed',    'Production',   'P-Card',  1,   1450.00,  116.00,   60.00,  1626.00, 'Tony Reeves'),
(5109, NULL, '2023-11-05', '2023-11-06', 'Closed',    'R&D',          'P-Card',  5,    980.00,   78.40,   25.00,  1083.40, 'Maria Santos'),
(5110, NULL, '2024-01-22', '2024-01-23', 'Received',  'Maintenance',  'P-Card',  3,    540.00,   43.20,    0.00,   583.20, 'Dan Brooks'),
(5111, NULL, '2024-03-08', NULL,         'Issued',    'Production',   'P-Card',  1,   2100.00,  168.00,   80.00,  2348.00, 'Tony Reeves');

