
-- =============================================================
-- Pulesboard – PART 4 (FIX): Views (MySQL 8+)
-- Replaces previous Part 4. Run AFTER parts 1–3.
-- =============================================================
USE pulesboard;

-- Drop in dependency order
DROP VIEW IF EXISTS v_portfolio_nav;
DROP VIEW IF EXISTS v_portfolio_returns_daily;
DROP VIEW IF EXISTS v_asset_returns_daily;
DROP VIEW IF EXISTS v_metric_outliers;
DROP VIEW IF EXISTS v_metric_rolling_stats;
DROP VIEW IF EXISTS v_metric_rollups_monthly;
DROP VIEW IF EXISTS v_metric_rollups_weekly;
DROP VIEW IF EXISTS v_metric_rollups_daily;

-- DAILY rollups (aggregator-aware)
CREATE OR REPLACE VIEW v_metric_rollups_daily AS
SELECT
  mv.metric_id,
  ANY_VALUE(m.name) AS metric_name,
  mv.ts_date AS bucket_date,
  CASE m.aggregator
    WHEN 'sum' THEN SUM(mv.value)
    WHEN 'avg' THEN AVG(mv.value)
    WHEN 'last' THEN MAX(CASE WHEN mv.ts = (
                           SELECT MAX(x.ts) FROM metric_value x
                           WHERE x.metric_id = mv.metric_id
                             AND DATE(x.ts) = mv.ts_date
                         ) THEN mv.value END)
    WHEN 'min' THEN MIN(mv.value)
    WHEN 'max' THEN MAX(mv.value)
  END AS agg_value
FROM metric_value mv
JOIN metric m ON m.metric_id = mv.metric_id
GROUP BY mv.metric_id, mv.ts_date;

-- WEEKLY rollups (week starts Monday)
CREATE OR REPLACE VIEW v_metric_rollups_weekly AS
SELECT
  mv.metric_id,
  ANY_VALUE(m.name) AS metric_name,
  DATE_SUB(DATE(mv.ts), INTERVAL WEEKDAY(mv.ts) DAY) AS week_start,
  CASE m.aggregator
    WHEN 'sum' THEN SUM(mv.value)
    WHEN 'avg' THEN AVG(mv.value)
    WHEN 'last' THEN MAX(CASE WHEN mv.ts = (
                           SELECT MAX(x.ts) FROM metric_value x
                           WHERE x.metric_id = mv.metric_id
                             AND DATE_SUB(DATE(x.ts), INTERVAL WEEKDAY(x.ts) DAY) =
                                 DATE_SUB(DATE(mv.ts), INTERVAL WEEKDAY(mv.ts) DAY)
                         ) THEN mv.value END)
    WHEN 'min' THEN MIN(mv.value)
    WHEN 'max' THEN MAX(mv.value)
  END AS agg_value
FROM metric_value mv
JOIN metric m ON m.metric_id = mv.metric_id
GROUP BY mv.metric_id, DATE_SUB(DATE(mv.ts), INTERVAL WEEKDAY(mv.ts) DAY);

-- MONTHLY rollups (first day of month)
CREATE OR REPLACE VIEW v_metric_rollups_monthly AS
SELECT
  mv.metric_id,
  ANY_VALUE(m.name) AS metric_name,
  DATE_ADD(MAKEDATE(YEAR(mv.ts),1), INTERVAL (MONTH(mv.ts)-1) MONTH) AS month_start,
  CASE m.aggregator
    WHEN 'sum' THEN SUM(mv.value)
    WHEN 'avg' THEN AVG(mv.value)
    WHEN 'last' THEN MAX(CASE WHEN mv.ts = (
                           SELECT MAX(x.ts) FROM metric_value x
                           WHERE x.metric_id = mv.metric_id
                             AND YEAR(x.ts) = YEAR(mv.ts)
                             AND MONTH(x.ts) = MONTH(mv.ts)
                         ) THEN mv.value END)
    WHEN 'min' THEN MIN(mv.value)
    WHEN 'max' THEN MAX(mv.value)
  END AS agg_value
FROM metric_value mv
JOIN metric m ON m.metric_id = mv.metric_id
GROUP BY mv.metric_id, YEAR(mv.ts), MONTH(mv.ts);

-- Rolling stats at native grain
CREATE OR REPLACE VIEW v_metric_rolling_stats AS
SELECT
  mv.metric_id,
  ANY_VALUE(m.name) AS metric_name,
  mv.ts,
  mv.value,
  AVG(mv.value) OVER (PARTITION BY mv.metric_id ORDER BY mv.ts
                      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ma_7d,
  AVG(mv.value) OVER (PARTITION BY mv.metric_id ORDER BY mv.ts
                      ROWS BETWEEN 27 PRECEDING AND CURRENT ROW) AS ma_28d,
  STDDEV_POP(mv.value) OVER (PARTITION BY mv.metric_id ORDER BY mv.ts
                      ROWS BETWEEN 27 PRECEDING AND CURRENT ROW) AS sd_28d
FROM metric_value mv
JOIN metric m ON m.metric_id = mv.metric_id;

-- Outliers via z-score vs 28d mean
CREATE OR REPLACE VIEW v_metric_outliers AS
SELECT
  metric_id,
  metric_name,
  ts,
  value,
  ma_28d,
  sd_28d,
  CASE WHEN sd_28d IS NULL OR sd_28d = 0 THEN NULL ELSE (value - ma_28d) / sd_28d END AS zscore,
  CASE WHEN sd_28d IS NULL OR sd_28d = 0 THEN 0
       WHEN ABS((value - ma_28d) / sd_28d) >= 3 THEN 1 ELSE 0 END AS is_outlier
FROM v_metric_rolling_stats;

-- Asset daily returns
CREATE OR REPLACE VIEW v_asset_returns_daily AS
SELECT
  ap.asset_id,
  ap.ts_date,
  ap.close_px,
  LAG(ap.close_px, 1) OVER (PARTITION BY ap.asset_id ORDER BY ap.ts_date) AS prev_close,
  CASE
    WHEN LAG(ap.close_px, 1) OVER (PARTITION BY ap.asset_id ORDER BY ap.ts_date) IS NULL
      THEN NULL
    WHEN LAG(ap.close_px, 1) OVER (PARTITION BY ap.asset_id ORDER BY ap.ts_date) = 0
      THEN NULL
    ELSE (ap.close_px / LAG(ap.close_px, 1) OVER (PARTITION BY ap.asset_id ORDER BY ap.ts_date)) - 1
  END AS ret
FROM asset_price ap;

-- Portfolio daily returns (latest weight <= date). Avoids alias 'pr'.
CREATE OR REPLACE VIEW v_portfolio_returns_daily AS
SELECT
  p.portfolio_id,
  p.name AS portfolio_name,
  ard.ts_date,
  SUM(
    COALESCE(ard.ret,0) *
    COALESCE((
      SELECT w.weight
      FROM portfolio_weight w
      WHERE w.portfolio_id = p.portfolio_id
        AND w.asset_id = ard.asset_id
        AND w.effective_date <= ard.ts_date
      ORDER BY w.effective_date DESC
      LIMIT 1
    ),0)
  ) AS portfolio_ret
FROM portfolio p
JOIN v_asset_returns_daily ard
  ON EXISTS (
    SELECT 1 FROM portfolio_weight w
    WHERE w.portfolio_id = p.portfolio_id
      AND w.asset_id = ard.asset_id
      AND w.effective_date <= ard.ts_date
  )
GROUP BY p.portfolio_id, ard.ts_date, p.name;

-- Portfolio NAV (cumulative product of 1+ret)
CREATE OR REPLACE VIEW v_portfolio_nav AS
SELECT
  portfolio_id,
  portfolio_name,
  ts_date,
  EXP(SUM(LOG(1 + COALESCE(portfolio_ret,0))) OVER (PARTITION BY portfolio_id ORDER BY ts_date)) AS nav
FROM v_portfolio_returns_daily
ORDER BY portfolio_id, ts_date;
