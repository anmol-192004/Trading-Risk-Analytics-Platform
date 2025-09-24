-- =====================================================
-- ADVANCED FINANCIAL ANALYTICS QUERIES (FIXED VERSION)
-- Real-World Trading & Risk Management SQL
-- =====================================================

USE trading_analytics_platform;

-- =====================================================
-- 1. PORTFOLIO PERFORMANCE & RISK ANALYTICS
-- =====================================================

-- Real-time Portfolio Dashboard with Key Metrics
SELECT 
    p.portfolio_id,
    p.portfolio_name,
    p.strategy_type,
    pp.nav as current_nav,
    p.initial_capital,
    pp.total_return,
    pp.cumulative_return * 100 as cum_return_pct,
    pp.volatility_1m * 100 as volatility_pct,
    pp.sharpe_ratio,
    pp.var_1d_95,
    pp.max_drawdown * 100 as max_drawdown_pct,
    -- Risk utilization
    rl.current_value as current_var,
    rl.limit_value as var_limit,
    rl.utilization * 100 as var_utilization_pct,
    CASE 
        WHEN rl.is_breached = 1 THEN 'BREACH' 
        WHEN rl.utilization > 0.8 THEN 'WARNING'
        ELSE 'NORMAL'
    END as risk_status
FROM portfolios p
LEFT JOIN portfolio_performance pp ON p.portfolio_id = pp.portfolio_id 
    AND pp.performance_date = (SELECT MAX(performance_date) FROM portfolio_performance WHERE portfolio_id = p.portfolio_id)
LEFT JOIN risk_limits rl ON p.portfolio_id = rl.portfolio_id 
    AND rl.limit_type = 'VAR' AND rl.is_active = TRUE
WHERE p.is_active = TRUE
ORDER BY pp.cumulative_return DESC;

-- =====================================================
-- 2. POSITION ANALYSIS & RISK EXPOSURE
-- =====================================================

-- Current Portfolio Positions with Risk Metrics
WITH position_metrics AS (
    SELECT 
        pos.portfolio_id,
        p.portfolio_name,
        pos.asset_id,
        a.asset_name,
        a.sector,
        pos.quantity,
        pos.avg_cost_price,
        pos.market_price,
        pos.market_value,
        pos.unrealized_pnl,
        -- Position sizing (handle division by zero)
        CASE 
            WHEN SUM(ABS(pos.market_value)) OVER (PARTITION BY pos.portfolio_id) = 0 THEN 0
            ELSE pos.market_value / SUM(ABS(pos.market_value)) OVER (PARTITION BY pos.portfolio_id) * 100 
        END as position_weight_pct,
        -- Risk contribution (handle division by zero)
        CASE 
            WHEN pp.nav = 0 THEN 0
            ELSE ABS(pos.market_value) / pp.nav * 100 
        END as exposure_pct,
        -- P&L metrics (handle division by zero)
        CASE 
            WHEN ABS(pos.quantity * pos.avg_cost_price) = 0 THEN 0
            ELSE pos.unrealized_pnl / ABS(pos.quantity * pos.avg_cost_price) * 100 
        END as unrealized_return_pct
    FROM positions pos
    INNER JOIN portfolios p ON pos.portfolio_id = p.portfolio_id
    INNER JOIN assets a ON pos.asset_id = a.asset_id
    INNER JOIN portfolio_performance pp ON pos.portfolio_id = pp.portfolio_id
        AND pp.performance_date = pos.position_date
    WHERE pos.position_date = '2024-01-19' AND pos.quantity != 0
)
SELECT *,
    CASE 
        WHEN position_weight_pct > 20 THEN 'HIGH_CONCENTRATION'
        WHEN position_weight_pct > 10 THEN 'MEDIUM_CONCENTRATION' 
        ELSE 'NORMAL'
    END as concentration_risk
FROM position_metrics
ORDER BY portfolio_id, ABS(position_weight_pct) DESC;

-- =====================================================
-- 3. TRADING PERFORMANCE ANALYSIS
-- =====================================================

-- Trading Performance by Portfolio and Strategy
WITH daily_trading_pnl AS (
    SELECT 
        t.portfolio_id,
        DATE(t.trade_datetime) as trade_date,
        SUM(CASE WHEN t.trade_side = 'BUY' THEN -t.total_cost ELSE t.total_cost END) as daily_trading_pnl,
        COUNT(*) as trade_count,
        SUM(t.commission) as total_commission
    FROM trades t
    WHERE t.trade_status = 'SETTLED'
    GROUP BY t.portfolio_id, DATE(t.trade_datetime)
),
portfolio_trading_stats AS (
    SELECT 
        dtp.portfolio_id,
        p.portfolio_name,
        COUNT(dtp.trade_date) as trading_days,
        SUM(dtp.daily_trading_pnl) as total_trading_pnl,
        AVG(dtp.daily_trading_pnl) as avg_daily_pnl,
        STDDEV(dtp.daily_trading_pnl) as pnl_volatility,
        SUM(dtp.trade_count) as total_trades,
        SUM(dtp.total_commission) as total_commissions,
        -- Win rate calculation (handle division by zero)
        CASE 
            WHEN COUNT(*) = 0 THEN 0
            ELSE SUM(CASE WHEN dtp.daily_trading_pnl > 0 THEN 1 ELSE 0 END) / COUNT(*) * 100 
        END as win_rate_pct,
        -- Risk-adjusted return (handle division by zero)
        CASE 
            WHEN STDDEV(dtp.daily_trading_pnl) > 0 AND STDDEV(dtp.daily_trading_pnl) IS NOT NULL
            THEN AVG(dtp.daily_trading_pnl) / STDDEV(dtp.daily_trading_pnl) 
            ELSE 0 
        END as sharpe_trading
    FROM daily_trading_pnl dtp
    INNER JOIN portfolios p ON dtp.portfolio_id = p.portfolio_id
    GROUP BY dtp.portfolio_id, p.portfolio_name
)
SELECT *,
    total_trading_pnl - total_commissions as net_trading_pnl,
    CASE 
        WHEN ABS(total_trading_pnl) = 0 THEN 0
        ELSE total_commissions / ABS(total_trading_pnl) * 100 
    END as commission_drag_pct
FROM portfolio_trading_stats
ORDER BY total_trading_pnl DESC;

-- =====================================================
-- 4. MARKET DATA & VOLATILITY ANALYSIS
-- =====================================================

-- Asset Volatility and Price Momentum Analysis
WITH price_analytics AS (
    SELECT 
        md.asset_id,
        a.asset_name,
        a.sector,
        md.price_date,
        -- Current price metrics
        md.close_price as current_price,
        LAG(md.close_price, 1) OVER (PARTITION BY md.asset_id ORDER BY md.price_date) as prev_price,
        LAG(md.close_price, 5) OVER (PARTITION BY md.asset_id ORDER BY md.price_date) as price_5d_ago,
        -- Daily returns (handle division by zero)
        CASE 
            WHEN LAG(md.close_price, 1) OVER (PARTITION BY md.asset_id ORDER BY md.price_date) = 0 THEN NULL
            ELSE (md.close_price / LAG(md.close_price, 1) OVER (PARTITION BY md.asset_id ORDER BY md.price_date) - 1) 
        END as daily_return,
        -- Volume analysis
        md.volume,
        AVG(md.volume) OVER (PARTITION BY md.asset_id ORDER BY md.price_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) as avg_volume_20d,
        -- Price levels
        MAX(md.high_price) OVER (PARTITION BY md.asset_id ORDER BY md.price_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) as high_20d,
        MIN(md.low_price) OVER (PARTITION BY md.asset_id ORDER BY md.price_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) as low_20d
    FROM market_data md
    INNER JOIN assets a ON md.asset_id = a.asset_id
    WHERE md.price_date >= '2024-01-01'
),
volatility_metrics AS (
    SELECT 
        asset_id,
        asset_name,
        sector,
        price_date,
        current_price,
        prev_price,
        price_5d_ago,
        daily_return,
        -- Momentum indicators (handle division by zero)
        CASE 
            WHEN prev_price = 0 OR prev_price IS NULL THEN NULL
            ELSE (current_price / prev_price - 1) * 100 
        END as daily_change_pct,
        CASE 
            WHEN price_5d_ago = 0 OR price_5d_ago IS NULL THEN NULL
            ELSE (current_price / price_5d_ago - 1) * 100 
        END as change_5d_pct,
        -- Volatility (20-day) - handle NULL values
        CASE 
            WHEN STDDEV(daily_return) OVER (PARTITION BY asset_id ORDER BY price_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) IS NOT NULL
            THEN STDDEV(daily_return) OVER (PARTITION BY asset_id ORDER BY price_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) * SQRT(252) * 100 
            ELSE NULL
        END as annualized_volatility,
        -- Technical indicators (handle division by zero)
        high_20d,
        low_20d,
        CASE 
            WHEN (high_20d - low_20d) = 0 THEN NULL
            ELSE (current_price - low_20d) / (high_20d - low_20d) * 100 
        END as stochastic_position,
        volume,
        avg_volume_20d,
        CASE 
            WHEN avg_volume_20d = 0 OR avg_volume_20d IS NULL THEN NULL
            ELSE volume / avg_volume_20d 
        END as volume_ratio,
        ROW_NUMBER() OVER (PARTITION BY asset_id ORDER BY price_date DESC) as rn
    FROM price_analytics
)
SELECT 
    asset_id,
    asset_name,
    sector,
    current_price,
    daily_change_pct,
    change_5d_pct,
    annualized_volatility,
    stochastic_position,
    volume_ratio,
    CASE 
        WHEN daily_change_pct > 3 AND volume_ratio > 1.5 THEN 'STRONG_BUY_SIGNAL'
        WHEN daily_change_pct < -3 AND volume_ratio > 1.5 THEN 'STRONG_SELL_SIGNAL'
        WHEN stochastic_position > 80 THEN 'OVERBOUGHT'
        WHEN stochastic_position < 20 THEN 'OVERSOLD'
        ELSE 'NEUTRAL'
    END as technical_signal
FROM volatility_metrics 
WHERE rn = 1  -- Latest data only
ORDER BY annualized_volatility DESC;

-- =====================================================
-- 5. RISK MANAGEMENT & COMPLIANCE MONITORING
-- =====================================================

-- Risk Limit Monitoring and Breach Analysis
WITH risk_monitoring AS (
    SELECT 
        rl.portfolio_id,
        p.portfolio_name,
        rl.limit_type,
        rl.limit_value,
        rl.current_value,
        rl.utilization * 100 as utilization_pct,
        rl.breach_threshold * 100 as breach_threshold_pct,
        rl.is_breached,
        -- Days since limit was set
        DATEDIFF(CURRENT_DATE, rl.effective_date) as days_since_effective,
        -- Risk level assessment
        CASE 
            WHEN rl.utilization > 0.9 THEN 'CRITICAL'
            WHEN rl.utilization > 0.8 THEN 'HIGH'
            WHEN rl.utilization > 0.6 THEN 'MEDIUM'
            ELSE 'LOW'
        END as risk_level
    FROM risk_limits rl
    INNER JOIN portfolios p ON rl.portfolio_id = p.portfolio_id
    WHERE rl.is_active = TRUE
),
breach_summary AS (
    SELECT 
        portfolio_id,
        portfolio_name,
        COUNT(*) as total_limits,
        SUM(CASE WHEN is_breached = 1 THEN 1 ELSE 0 END) as breached_limits,
        AVG(utilization_pct) as avg_utilization,
        MAX(utilization_pct) as max_utilization,
        COUNT(CASE WHEN risk_level = 'CRITICAL' THEN 1 END) as critical_limits,
        COUNT(CASE WHEN risk_level = 'HIGH' THEN 1 END) as high_risk_limits
    FROM risk_monitoring
    GROUP BY portfolio_id, portfolio_name
)
SELECT 
    bs.*,
    CASE 
        WHEN breached_limits > 0 THEN 'BREACH_ALERT'
        WHEN critical_limits > 0 THEN 'CRITICAL_MONITORING'
        WHEN high_risk_limits > 0 THEN 'ENHANCED_MONITORING'
        ELSE 'NORMAL_MONITORING'
    END as compliance_status
FROM breach_summary bs
ORDER BY breached_limits DESC, critical_limits DESC;

-- =====================================================
-- 6. P&L ATTRIBUTION ANALYSIS
-- =====================================================

-- Detailed P&L Attribution by Asset and Source
WITH pnl_analysis AS (
    SELECT 
        pa.portfolio_id,
        p.portfolio_name,
        pa.asset_id,
        a.asset_name,
        a.sector,
        pa.attribution_date,
        pa.position_pnl,
        pa.trading_pnl,
        pa.fx_pnl,
        pa.total_pnl,
        -- Performance attribution (handle division by zero)
        CASE 
            WHEN SUM(ABS(pa.total_pnl)) OVER (PARTITION BY pa.portfolio_id, pa.attribution_date) = 0 THEN 0
            ELSE pa.total_pnl / SUM(ABS(pa.total_pnl)) OVER (PARTITION BY pa.portfolio_id, pa.attribution_date) * 100 
        END as pnl_contribution_pct,
        -- Asset performance metrics (handle division by zero)
        CASE 
            WHEN pa.price_start = 0 OR pa.price_start IS NULL THEN NULL
            ELSE (pa.price_end / pa.price_start - 1) * 100 
        END as asset_return_pct,
        pa.quantity_end - pa.quantity_start as position_change
    FROM pnl_attribution pa
    INNER JOIN portfolios p ON pa.portfolio_id = p.portfolio_id
    INNER JOIN assets a ON pa.asset_id = a.asset_id
    WHERE pa.attribution_date >= '2024-01-15'
),
portfolio_pnl_summary AS (
    SELECT 
        portfolio_id,
        portfolio_name,
        COUNT(DISTINCT asset_id) as contributing_assets,
        SUM(total_pnl) as total_portfolio_pnl,
        SUM(position_pnl) as total_position_pnl,
        SUM(trading_pnl) as total_trading_pnl,
        SUM(fx_pnl) as total_fx_pnl,
        -- Top contributors
        COUNT(CASE WHEN total_pnl > 0 THEN 1 END) as positive_contributors,
        COUNT(CASE WHEN total_pnl < 0 THEN 1 END) as negative_contributors,
        -- Sector analysis
        COUNT(DISTINCT sector) as sectors_contributing
    FROM pnl_analysis
    GROUP BY portfolio_id, portfolio_name
)
SELECT 
    pps.*,
    CASE 
        WHEN pps.total_portfolio_pnl = 0 THEN 0
        ELSE pps.total_position_pnl / pps.total_portfolio_pnl * 100 
    END as position_pnl_pct,
    CASE 
        WHEN pps.total_portfolio_pnl = 0 THEN 0
        ELSE pps.total_trading_pnl / pps.total_portfolio_pnl * 100 
    END as trading_pnl_pct,
    CASE 
        WHEN pps.positive_contributors > pps.negative_contributors THEN 'BROAD_GAINS'
        WHEN pps.negative_contributors > pps.positive_contributors THEN 'CONCENTRATED_LOSSES'
        ELSE 'MIXED'
    END as pnl_distribution
FROM portfolio_pnl_summary pps
ORDER BY total_portfolio_pnl DESC;

-- =====================================================
-- 7. TRADE EXECUTION QUALITY ANALYSIS
-- =====================================================

-- Trade Execution Quality Analysis
WITH execution_analysis AS (
    SELECT 
        t.portfolio_id,
        t.asset_id,
        t.trade_datetime,
        t.trade_side,
        t.quantity,
        t.price as execution_price,
        -- Get market price at time of trade (using close price from same day)
        md.close_price as market_price_at_trade,
        -- Execution quality metrics (handle division by zero)
        CASE 
            WHEN md.close_price = 0 OR md.close_price IS NULL THEN NULL
            WHEN t.trade_side = 'BUY' THEN (t.price - md.close_price) / md.close_price * 10000  -- in basis points
            ELSE (md.close_price - t.price) / md.close_price * 10000  -- in basis points
        END as execution_shortfall_bps,
        t.commission,
        CASE 
            WHEN t.trade_value = 0 THEN 0
            ELSE t.commission / t.trade_value * 10000  -- in basis points
        END as commission_rate_bps
    FROM trades t
    INNER JOIN market_data md ON t.asset_id = md.asset_id 
        AND DATE(t.trade_datetime) = md.price_date
    WHERE t.trade_status = 'SETTLED'
),
execution_summary AS (
    SELECT 
        portfolio_id,
        asset_id,
        COUNT(*) as trade_count,
        SUM(quantity) as total_volume,
        AVG(execution_shortfall_bps) as avg_execution_shortfall_bps,
        STDDEV(execution_shortfall_bps) as execution_consistency,
        AVG(commission_rate_bps) as avg_commission_rate_bps,
        SUM(commission) as total_commission_cost
    FROM execution_analysis
    WHERE execution_shortfall_bps IS NOT NULL
    GROUP BY portfolio_id, asset_id
)
SELECT 
    es.*,
    a.asset_name,
    p.portfolio_name,
    CASE 
        WHEN avg_execution_shortfall_bps < -5 THEN 'POOR_EXECUTION'
        WHEN avg_execution_shortfall_bps < 0 THEN 'BELOW_MARKET'
        WHEN avg_execution_shortfall_bps < 5 THEN 'GOOD_EXECUTION'
        ELSE 'EXCELLENT_EXECUTION'
    END as execution_quality
FROM execution_summary es
INNER JOIN assets a ON es.asset_id = a.asset_id
INNER JOIN portfolios p ON es.portfolio_id = p.portfolio_id
ORDER BY avg_execution_shortfall_bps ASC;