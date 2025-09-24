
-- =============================================================
-- Pulesboard – PART 6: Seed Data (MySQL 8+)
-- =============================================================
USE pulesboard;

-- Seed metrics
INSERT INTO metric (name, description, frequency, aggregator, unit, entity, tags)
VALUES 
 ('Website Sessions', 'All site sessions', 'daily', 'sum', 'visits', 'siteA', JSON_OBJECT('team','growth')),
 ('Revenue USD', 'Daily revenue in USD', 'daily', 'sum', 'USD', 'siteA', JSON_OBJECT('team','sales'))
ON DUPLICATE KEY UPDATE description=VALUES(description);

-- Seed metric values (14 days)
DELETE FROM metric_value WHERE metric_id IN (1,2);
INSERT INTO metric_value (metric_id, ts, value, source) VALUES
 (1, '2025-08-01 00:00:00', 10230, 'seed'),
 (1, '2025-08-02 00:00:00', 11020, 'seed'),
 (1, '2025-08-03 00:00:00', 9900,  'seed'),
 (1, '2025-08-04 00:00:00', 12010, 'seed'),
 (1, '2025-08-05 00:00:00', 11840, 'seed'),
 (1, '2025-08-06 00:00:00', 12320, 'seed'),
 (1, '2025-08-07 00:00:00', 12550, 'seed'),
 (1, '2025-08-08 00:00:00', 11980, 'seed'),
 (1, '2025-08-09 00:00:00', 13040, 'seed'),
 (1, '2025-08-10 00:00:00', 12770, 'seed'),
 (1, '2025-08-11 00:00:00', 12220, 'seed'),
 (1, '2025-08-12 00:00:00', 13510, 'seed'),
 (1, '2025-08-13 00:00:00', 14040, 'seed'),
 (1, '2025-08-14 00:00:00', 13880, 'seed'),
 (2, '2025-08-01 00:00:00',  8200.45, 'seed'),
 (2, '2025-08-02 00:00:00',  9012.30, 'seed'),
 (2, '2025-08-03 00:00:00',  8450.10, 'seed'),
 (2, '2025-08-04 00:00:00',  9801.99, 'seed'),
 (2, '2025-08-05 00:00:00',  9322.15, 'seed'),
 (2, '2025-08-06 00:00:00', 10011.20, 'seed'),
 (2, '2025-08-07 00:00:00', 10444.75, 'seed'),
 (2, '2025-08-08 00:00:00',  9722.60, 'seed'),
 (2, '2025-08-09 00:00:00', 11042.00, 'seed'),
 (2, '2025-08-10 00:00:00', 10890.40, 'seed'),
 (2, '2025-08-11 00:00:00', 10650.25, 'seed'),
 (2, '2025-08-12 00:00:00', 11880.10, 'seed'),
 (2, '2025-08-13 00:00:00', 12150.65, 'seed'),
 (2, '2025-08-14 00:00:00', 11970.05, 'seed');

-- Finance seeds
INSERT IGNORE INTO asset (symbol, name, sector) VALUES
 ('AAPL','Apple Inc.','Technology'),
 ('MSFT','Microsoft Corp.','Technology');

INSERT IGNORE INTO asset_price (asset_id, ts_date, close_px, volume) VALUES
 (1, '2025-08-01', 210.10, 100000000),
 (1, '2025-08-04', 211.90, 98000000),
 (1, '2025-08-05', 213.25, 97000000),
 (1, '2025-08-06', 212.80, 95000000),
 (1, '2025-08-07', 214.30, 96000000),
 (2, '2025-08-01', 440.50, 75000000),
 (2, '2025-08-04', 443.00, 72000000),
 (2, '2025-08-05', 444.20, 71000000),
 (2, '2025-08-06', 446.10, 69000000),
 (2, '2025-08-07', 445.75, 70000000);

INSERT IGNORE INTO portfolio (name, base_currency, inception_nav) VALUES ('Tech Duo', 'USD', 1.0);

INSERT IGNORE INTO portfolio_weight (portfolio_id, asset_id, weight, effective_date) VALUES
 (1, 1, 0.5, '2025-08-01'),
 (1, 2, 0.5, '2025-08-01');

-- Alerts & experiment seeds
INSERT IGNORE INTO alert_rule (metric_id, rule_name, direction, threshold, lookback_days)
VALUES (1, 'Sessions 7d below 11k', 'below', 11000, 7);

INSERT IGNORE INTO experiment (name, metric_id, start_ts, end_ts, variant_a_label, variant_b_label, notes)
VALUES ('Hero Banner Test', 1, '2025-08-01 00:00:00', NULL, 'control', 'variant', 'Homepage banner headline A/B');

INSERT IGNORE INTO experiment_observation (experiment_id, ts_date, variant, samples, conversions, value_sum, value_avg) VALUES
 (1, '2025-08-05', 'control', 5000, 550, NULL, NULL),
 (1, '2025-08-05', 'variant', 5100, 620, NULL, NULL),
 (1, '2025-08-06', 'control', 5200, 570, NULL, NULL),
 (1, '2025-08-06', 'variant', 5050, 610, NULL, NULL);

-- Quick checks (optional to run manually)
-- SELECT * FROM v_metric_rollups_daily WHERE metric_id=1 ORDER BY bucket_date;
-- SELECT * FROM v_asset_returns_daily ORDER BY asset_id, ts_date;
-- SELECT * FROM v_portfolio_nav ORDER BY portfolio_id, ts_date;
