const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.static('.'));

const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'Anmol@2004',
  database: 'trading_analytics_platform',
  port: 3306
});

db.connect(err => {
  if (err) console.error('Database connection failed:', err);
  else console.log('Connected to MySQL database!');
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

/* -------- Portfolio Overview -------- */
app.get('/api/portfolio-summary', (req, res) => {
  const q = `
    SELECT 
      p.portfolio_id,
      p.portfolio_name,
      p.strategy_type,
      pp.nav AS current_nav,
      pp.cumulative_return * 100 AS cum_return_pct,
      pp.volatility_1m * 100 AS volatility_pct,
      pp.sharpe_ratio,
      pp.max_drawdown * 100 AS max_drawdown_pct,
      rl.current_value AS current_var,
      rl.limit_value   AS var_limit,
      rl.utilization * 100 AS var_utilization_pct,
      CASE 
        WHEN rl.is_breached THEN 'BREACH'
        WHEN rl.utilization > 0.8 THEN 'WARNING'
        ELSE 'NORMAL'
      END AS risk_status
    FROM portfolios p
    LEFT JOIN portfolio_performance pp 
      ON pp.portfolio_id = p.portfolio_id
     AND pp.performance_date = (
          SELECT MAX(pp2.performance_date)
          FROM portfolio_performance pp2
          WHERE pp2.portfolio_id = p.portfolio_id
        )
    LEFT JOIN risk_limits rl 
      ON rl.portfolio_id = p.portfolio_id 
     AND rl.limit_type = 'VAR' 
     AND rl.is_active = TRUE
    WHERE p.is_active = TRUE
    ORDER BY pp.cumulative_return DESC`;
  db.query(q, (err, rows) => err ? res.status(500).json({error:'query failed'}) : res.json(rows));
});

/* -------- Positions (latest date per portfolio; no hard-coding) -------- */
app.get('/api/positions', (req, res) => {
  const q = `
    SELECT 
      pos.portfolio_id,
      p.portfolio_name   AS portfolio,
      pos.asset_id,
      a.asset_name       AS asset,
      a.sector,
      pos.quantity,
      pos.avg_cost_price AS avg_cost,
      pos.market_price,
      pos.market_value,
      pos.unrealized_pnl AS unrealized_pl,
      (pos.market_value / NULLIF(SUM(ABS(pos.market_value)) OVER (PARTITION BY pos.portfolio_id),0) * 100) AS weight_pct,
      ABS(pos.market_value) / NULLIF(pp.nav,0) * 100 AS exposure_pct,
      pos.unrealized_pnl / NULLIF(ABS(pos.quantity * pos.avg_cost_price),0) * 100 AS unrealized_return_pct
    FROM positions pos
    JOIN portfolios p ON pos.portfolio_id = p.portfolio_id
    JOIN assets a     ON pos.asset_id = a.asset_id
    JOIN portfolio_performance pp ON pp.portfolio_id = pos.portfolio_id
         AND pp.performance_date = (
            SELECT MAX(pp2.performance_date)
            FROM portfolio_performance pp2
            WHERE pp2.portfolio_id = pos.portfolio_id
         )
    WHERE pos.position_date = (
      SELECT MAX(p2.position_date) 
      FROM positions p2 
      WHERE p2.portfolio_id = pos.portfolio_id
    )
      AND pos.quantity <> 0
    ORDER BY pos.portfolio_id, ABS(weight_pct) DESC`;
  db.query(q, (err, rows) => err ? res.status(500).json({error:'query failed'}) : res.json(rows));
});

/* -------- Risk Limits (names aligned to UI) -------- */
app.get('/api/risk-limits', (req, res) => {
  const q = `
    SELECT 
      rl.portfolio_id,
      p.portfolio_name AS portfolio,
      rl.limit_type,
      rl.limit_value,
      rl.current_value,
      rl.utilization * 100 AS utilization_pct,
      rl.breach_threshold * 100 AS breach_threshold_pct,
      rl.is_breached,
      CASE 
        WHEN rl.is_breached THEN 'BREACHED'
        WHEN rl.utilization > 0.9 THEN 'CRITICAL'
        WHEN rl.utilization > 0.8 THEN 'HIGH'
        WHEN rl.utilization > 0.6 THEN 'MEDIUM'
        ELSE 'LOW'
      END AS status
    FROM risk_limits rl
    JOIN portfolios p ON rl.portfolio_id = p.portfolio_id
    WHERE rl.is_active = TRUE
    ORDER BY rl.utilization DESC`;
  db.query(q, (err, rows) => err ? res.status(500).json({error:'query failed'}) : res.json(rows));
});

/* -------- Sector exposure for charts -------- */
app.get('/api/sector-exposure', (req, res) => {
  const { portfolio_id } = req.query; // optional
  const q = `
    SELECT 
      a.sector,
      SUM(pos.market_value) AS market_value
    FROM positions pos
    JOIN assets a ON a.asset_id = pos.asset_id
    WHERE pos.position_date = (
      SELECT MAX(p2.position_date) FROM positions p2
      ${portfolio_id ? 'WHERE p2.portfolio_id = ?' : ''}
    )
    ${portfolio_id ? 'AND pos.portfolio_id = ?' : ''}
    GROUP BY a.sector
    ORDER BY SUM(pos.market_value) DESC`;
  const params = portfolio_id ? [portfolio_id, portfolio_id] : [];
  db.query(q, params, (err, rows) => err ? res.status(500).json({error:'query failed'}) : res.json(rows));
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Trading Analytics Platform running on http://localhost:${PORT}`);
});
