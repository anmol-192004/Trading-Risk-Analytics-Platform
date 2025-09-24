-- =====================================================
-- SAMPLE DATA POPULATION
-- Financial Trading Platform
-- =====================================================

USE trading_analytics_platform;

-- =====================================================
-- REFERENCE DATA
-- =====================================================

-- Insert sample assets
INSERT INTO assets (asset_id, asset_name, asset_type, sector, currency, exchange, bloomberg_ticker) VALUES
('AAPL', 'Apple Inc', 'EQUITY', 'Technology', 'USD', 'NASDAQ', 'AAPL US Equity'),
('GOOGL', 'Alphabet Inc', 'EQUITY', 'Technology', 'USD', 'NASDAQ', 'GOOGL US Equity'),
('MSFT', 'Microsoft Corp', 'EQUITY', 'Technology', 'USD', 'NASDAQ', 'MSFT US Equity'),
('TSLA', 'Tesla Inc', 'EQUITY', 'Consumer Discretionary', 'USD', 'NASDAQ', 'TSLA US Equity'),
('JPM', 'JPMorgan Chase', 'EQUITY', 'Financials', 'USD', 'NYSE', 'JPM US Equity'),
('GS', 'Goldman Sachs', 'EQUITY', 'Financials', 'USD', 'NYSE', 'GS US Equity'),
('SPY', 'SPDR S&P 500 ETF', 'EQUITY', 'ETF', 'USD', 'NYSE', 'SPY US Equity'),
('QQQ', 'Invesco QQQ Trust', 'EQUITY', 'ETF', 'USD', 'NASDAQ', 'QQQ US Equity'),
('BTCUSD', 'Bitcoin', 'CRYPTO', 'Cryptocurrency', 'USD', 'COINBASE', 'BTCUSD Curncy'),
('ETHUSD', 'Ethereum', 'CRYPTO', 'Cryptocurrency', 'USD', 'COINBASE', 'ETHUSD Curncy');

-- Insert portfolios
INSERT INTO portfolios (portfolio_id, portfolio_name, strategy_type, manager_name, initial_capital, inception_date, risk_limit_var) VALUES
('TECH_GROWTH', 'Technology Growth Fund', 'Long Only Growth', 'Sarah Johnson', 10000000.00, '2023-01-01', 500000.00),
('QUANT_ALPHA', 'Quantitative Alpha Strategy', 'Market Neutral', 'David Chen', 25000000.00, '2023-01-01', 750000.00),
('CRYPTO_FUND', 'Digital Assets Fund', 'Long/Short Crypto', 'Alex Rodriguez', 5000000.00, '2023-06-01', 1000000.00),
('BALANCED_FUND', 'Conservative Balanced', 'Multi-Asset', 'Lisa Wang', 15000000.00, '2023-01-01', 300000.00);

-- Insert counterparties
INSERT INTO counterparties (counterparty_id, name, type, country, credit_rating) VALUES
('GS_PRIME', 'Goldman Sachs Prime Services', 'BROKER', 'US', 'A+'),
('MS_PRIME', 'Morgan Stanley Prime', 'BROKER', 'US', 'A'),
('NASDAQ', 'NASDAQ Exchange', 'EXCHANGE', 'US', 'AAA'),
('NYSE', 'New York Stock Exchange', 'EXCHANGE', 'US', 'AAA'),
('DTCC', 'Depository Trust Company', 'CLEARINGHOUSE', 'US', 'AAA');

-- =====================================================
-- MARKET DATA - Recent 30 days sample
-- =====================================================

-- Insert sample market data for key assets (last 30 days)
INSERT INTO market_data (asset_id, price_date, price_time, open_price, high_price, low_price, close_price, volume) VALUES
-- AAPL data
('AAPL', '2024-01-15', '16:00:00', 185.50, 187.20, 184.10, 186.75, 52000000),
('AAPL', '2024-01-16', '16:00:00', 186.80, 189.40, 185.90, 188.25, 48000000),
('AAPL', '2024-01-17', '16:00:00', 188.30, 190.15, 187.50, 189.80, 45000000),
('AAPL', '2024-01-18', '16:00:00', 189.75, 191.20, 188.60, 190.45, 51000000),
('AAPL', '2024-01-19', '16:00:00', 190.50, 192.80, 189.90, 191.65, 49000000),

-- GOOGL data
('GOOGL', '2024-01-15', '16:00:00', 142.30, 144.20, 141.80, 143.50, 28000000),
('GOOGL', '2024-01-16', '16:00:00', 143.60, 145.90, 142.90, 144.85, 32000000),
('GOOGL', '2024-01-17', '16:00:00', 144.90, 146.40, 143.70, 145.20, 29000000),
('GOOGL', '2024-01-18', '16:00:00', 145.25, 147.80, 144.50, 146.95, 31000000),
('GOOGL', '2024-01-19', '16:00:00', 147.00, 148.60, 145.80, 147.30, 27000000),

-- MSFT data
('MSFT', '2024-01-15', '16:00:00', 375.20, 378.50, 374.10, 377.25, 22000000),
('MSFT', '2024-01-16', '16:00:00', 377.30, 380.90, 375.80, 379.40, 25000000),
('MSFT', '2024-01-17', '16:00:00', 379.50, 382.20, 377.90, 381.15, 24000000),
('MSFT', '2024-01-18', '16:00:00', 381.20, 384.70, 379.80, 383.45, 26000000),
('MSFT', '2024-01-19', '16:00:00', 383.50, 386.20, 381.90, 385.75, 23000000);

-- FX Rates
INSERT INTO fx_rates (base_currency, quote_currency, rate_date, exchange_rate) VALUES
('USD', 'EUR', '2024-01-15', 0.8523),
('USD', 'GBP', '2024-01-15', 0.7845),
('USD', 'JPY', '2024-01-15', 148.25),
('USD', 'EUR', '2024-01-16', 0.8534),
('USD', 'GBP', '2024-01-16', 0.7856),
('USD', 'JPY', '2024-01-16', 148.45);

-- =====================================================
-- TRADING DATA
-- =====================================================

-- Sample orders
INSERT INTO orders (order_id, portfolio_id, asset_id, order_type, side, quantity, price, order_status, counterparty_id, order_datetime, filled_quantity, avg_fill_price) VALUES
('ORD-2024-001', 'TECH_GROWTH', 'AAPL', 'LIMIT', 'BUY', 5000.0000, 186.50, 'FILLED', 'GS_PRIME', '2024-01-15 09:30:00', 5000.0000, 186.52),
('ORD-2024-002', 'TECH_GROWTH', 'GOOGL', 'MARKET', 'BUY', 2000.0000, NULL, 'FILLED', 'MS_PRIME', '2024-01-15 10:15:00', 2000.0000, 143.48),
('ORD-2024-003', 'QUANT_ALPHA', 'MSFT', 'LIMIT', 'BUY', 3000.0000, 377.00, 'FILLED', 'GS_PRIME', '2024-01-15 11:20:00', 3000.0000, 377.15),
('ORD-2024-004', 'TECH_GROWTH', 'TSLA', 'STOP', 'SELL', 1500.0000, 245.00, 'FILLED', 'MS_PRIME', '2024-01-16 14:30:00', 1500.0000, 244.85),
('ORD-2024-005', 'QUANT_ALPHA', 'JPM', 'LIMIT', 'BUY', 4000.0000, 165.50, 'PARTIALLY_FILLED', 'GS_PRIME', '2024-01-17 09:45:00', 2500.0000, 165.52);

-- Sample trades
INSERT INTO trades (trade_id, order_id, portfolio_id, asset_id, trade_side, quantity, price, commission, counterparty_id, trade_datetime, settlement_date, trade_status) VALUES
('TRD-2024-001', 'ORD-2024-001', 'TECH_GROWTH', 'AAPL', 'BUY', 5000.0000, 186.52, 125.50, 'GS_PRIME', '2024-01-15 09:30:15', '2024-01-17', 'SETTLED'),
('TRD-2024-002', 'ORD-2024-002', 'TECH_GROWTH', 'GOOGL', 'BUY', 2000.0000, 143.48, 87.20, 'MS_PRIME', '2024-01-15 10:15:22', '2024-01-17', 'SETTLED'),
('TRD-2024-003', 'ORD-2024-003', 'QUANT_ALPHA', 'MSFT', 'BUY', 3000.0000, 377.15, 168.75, 'GS_PRIME', '2024-01-15 11:20:08', '2024-01-17', 'SETTLED'),
('TRD-2024-004', 'ORD-2024-004', 'TECH_GROWTH', 'TSLA', 'SELL', 1500.0000, 244.85, 92.40, 'MS_PRIME', '2024-01-16 14:30:45', '2024-01-18', 'SETTLED'),
('TRD-2024-005', 'ORD-2024-005', 'QUANT_ALPHA', 'JPM', 'BUY', 2500.0000, 165.52, 103.25, 'GS_PRIME', '2024-01-17 09:45:12', '2024-01-19', 'PENDING');

-- Sample current positions
INSERT INTO positions (portfolio_id, asset_id, quantity, avg_cost_price, market_price, position_date) VALUES
('TECH_GROWTH', 'AAPL', 5000.0000, 186.52, 191.65, '2024-01-19'),
('TECH_GROWTH', 'GOOGL', 2000.0000, 143.48, 147.30, '2024-01-19'),
('TECH_GROWTH', 'TSLA', -1500.0000, 244.85, 248.20, '2024-01-19'),
('QUANT_ALPHA', 'MSFT', 3000.0000, 377.15, 385.75, '2024-01-19'),
('QUANT_ALPHA', 'JPM', 2500.0000, 165.52, 168.90, '2024-01-19'),
('CRYPTO_FUND', 'BTCUSD', 125.5000, 45200.00, 47850.00, '2024-01-19'),
('BALANCED_FUND', 'SPY', 8000.0000, 485.20, 491.75, '2024-01-19');

-- Sample portfolio performance data
INSERT INTO portfolio_performance (portfolio_id, performance_date, nav, total_return, daily_return, cumulative_return, volatility_1m, sharpe_ratio, var_1d_95) VALUES
('TECH_GROWTH', '2024-01-19', 10250000.00, 250000.00, 0.0125, 0.0250, 0.0185, 1.35, -125000.00),
('QUANT_ALPHA', '2024-01-19', 25750000.00, 750000.00, 0.0080, 0.0300, 0.0145, 2.07, -180000.00),
('CRYPTO_FUND', '2024-01-19', 5350000.00, 350000.00, 0.0250, 0.0700, 0.0425, 1.65, -285000.00),
('BALANCED_FUND', '2024-01-19', 15150000.00, 150000.00, 0.0045, 0.0100, 0.0095, 1.05, -85000.00);

-- Sample risk limits
INSERT INTO risk_limits (portfolio_id, limit_type, limit_value, current_value, effective_date) VALUES
('TECH_GROWTH', 'VAR', 500000.00, 125000.00, '2024-01-01'),
('TECH_GROWTH', 'CONCENTRATION', 2000000.00, 1500000.00, '2024-01-01'),
('QUANT_ALPHA', 'VAR', 750000.00, 180000.00, '2024-01-01'),
('QUANT_ALPHA', 'LEVERAGE', 50000000.00, 35000000.00, '2024-01-01'),
('CRYPTO_FUND', 'VAR', 1000000.00, 285000.00, '2024-06-01'),
('BALANCED_FUND', 'DRAWDOWN', 0.15, 0.05, '2024-01-01');

-- Sample P&L attribution
INSERT INTO pnl_attribution (portfolio_id, asset_id, attribution_date, position_pnl, trading_pnl, quantity_start, quantity_end, price_start, price_end) VALUES
('TECH_GROWTH', 'AAPL', '2024-01-19', 25650.00, -125.50, 5000.0000, 5000.0000, 186.52, 191.65),
('TECH_GROWTH', 'GOOGL', '2024-01-19', 7640.00, -87.20, 2000.0000, 2000.0000, 143.48, 147.30),
('QUANT_ALPHA', 'MSFT', '2024-01-19', 25800.00, -168.75, 3000.0000, 3000.0000, 377.15, 385.75),
('QUANT_ALPHA', 'JPM', '2024-01-19', 8450.00, -103.25, 2500.0000, 2500.0000, 165.52, 168.90);