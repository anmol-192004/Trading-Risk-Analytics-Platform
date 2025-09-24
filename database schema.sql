-- =====================================================
-- FINANCIAL TRADING & RISK ANALYTICS PLATFORM
-- MySQL Database Schema Design
-- =====================================================

-- Create database
CREATE DATABASE trading_analytics_platform;
USE trading_analytics_platform;

-- =====================================================
-- REFERENCE DATA TABLES
-- =====================================================

-- Asset master data
CREATE TABLE assets (
    asset_id VARCHAR(20) PRIMARY KEY,
    asset_name VARCHAR(100) NOT NULL,
    asset_type ENUM('EQUITY', 'BOND', 'OPTION', 'FUTURE', 'FOREX', 'CRYPTO') NOT NULL,
    sector VARCHAR(50),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    exchange VARCHAR(20),
    isin VARCHAR(12),
    bloomberg_ticker VARCHAR(20),
    multiplier DECIMAL(10,4) DEFAULT 1.0000,
    tick_size DECIMAL(10,6) DEFAULT 0.01,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Portfolio master
CREATE TABLE portfolios (
    portfolio_id VARCHAR(20) PRIMARY KEY,
    portfolio_name VARCHAR(100) NOT NULL,
    strategy_type VARCHAR(50),
    manager_name VARCHAR(100),
    base_currency VARCHAR(3) DEFAULT 'USD',
    inception_date DATE NOT NULL,
    initial_capital DECIMAL(15,2) NOT NULL,
    benchmark_index VARCHAR(20),
    risk_limit_var DECIMAL(15,2),
    max_drawdown_limit DECIMAL(5,4) DEFAULT 0.20,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Counterparties (brokers, exchanges, clearing houses)
CREATE TABLE counterparties (
    counterparty_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type ENUM('BROKER', 'EXCHANGE', 'CLEARINGHOUSE', 'CUSTODIAN') NOT NULL,
    country VARCHAR(2),
    credit_rating VARCHAR(10),
    credit_limit DECIMAL(15,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- MARKET DATA TABLES
-- =====================================================

-- Real-time and historical price data
CREATE TABLE market_data (
    data_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    asset_id VARCHAR(20) NOT NULL,
    price_date DATE NOT NULL,
    price_time TIME NOT NULL,
    open_price DECIMAL(12,6),
    high_price DECIMAL(12,6),
    low_price DECIMAL(12,6),
    close_price DECIMAL(12,6),
    volume BIGINT DEFAULT 0,
    bid_price DECIMAL(12,6),
    ask_price DECIMAL(12,6),
    bid_size INT,
    ask_size INT,
    vwap DECIMAL(12,6),
    data_source VARCHAR(20) DEFAULT 'BLOOMBERG',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (asset_id) REFERENCES assets(asset_id),
    INDEX idx_market_data_asset_date (asset_id, price_date, price_time),
    INDEX idx_market_data_datetime (price_date, price_time)
);

-- Currency exchange rates
CREATE TABLE fx_rates (
    rate_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    base_currency VARCHAR(3) NOT NULL,
    quote_currency VARCHAR(3) NOT NULL,
    rate_date DATE NOT NULL,
    exchange_rate DECIMAL(12,8) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_fx_rates (base_currency, quote_currency, rate_date),
    INDEX idx_fx_date (rate_date)
);

-- =====================================================
-- TRADING & POSITIONS TABLES
-- =====================================================

-- Trade orders
CREATE TABLE orders (
    order_id VARCHAR(30) PRIMARY KEY,
    portfolio_id VARCHAR(20) NOT NULL,
    asset_id VARCHAR(20) NOT NULL,
    order_type ENUM('MARKET', 'LIMIT', 'STOP', 'STOP_LIMIT') NOT NULL,
    side ENUM('BUY', 'SELL') NOT NULL,
    quantity DECIMAL(15,4) NOT NULL,
    price DECIMAL(12,6),
    stop_price DECIMAL(12,6),
    order_status ENUM('PENDING', 'PARTIALLY_FILLED', 'FILLED', 'CANCELLED', 'REJECTED') DEFAULT 'PENDING',
    time_in_force ENUM('DAY', 'GTC', 'IOC', 'FOK') DEFAULT 'DAY',
    counterparty_id VARCHAR(20),
    order_datetime TIMESTAMP NOT NULL,
    filled_quantity DECIMAL(15,4) DEFAULT 0,
    avg_fill_price DECIMAL(12,6),
    commission DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (portfolio_id) REFERENCES portfolios(portfolio_id),
    FOREIGN KEY (asset_id) REFERENCES assets(asset_id),
    FOREIGN KEY (counterparty_id) REFERENCES counterparties(counterparty_id),
    INDEX idx_orders_portfolio (portfolio_id),
    INDEX idx_orders_datetime (order_datetime)
);

-- Trade executions
CREATE TABLE trades (
    trade_id VARCHAR(30) PRIMARY KEY,
    order_id VARCHAR(30) NOT NULL,
    portfolio_id VARCHAR(20) NOT NULL,
    asset_id VARCHAR(20) NOT NULL,
    trade_side ENUM('BUY', 'SELL') NOT NULL,
    quantity DECIMAL(15,4) NOT NULL,
    price DECIMAL(12,6) NOT NULL,
    trade_value DECIMAL(18,2) GENERATED ALWAYS AS (quantity * price) STORED,
    commission DECIMAL(10,2) DEFAULT 0,
    tax DECIMAL(10,2) DEFAULT 0,
    total_cost DECIMAL(18,2) GENERATED ALWAYS AS (trade_value + commission + tax) STORED,
    counterparty_id VARCHAR(20),
    trade_datetime TIMESTAMP NOT NULL,
    settlement_date DATE,
    trade_status ENUM('PENDING', 'SETTLED', 'FAILED') DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (portfolio_id) REFERENCES portfolios(portfolio_id),
    FOREIGN KEY (asset_id) REFERENCES assets(asset_id),
    FOREIGN KEY (counterparty_id) REFERENCES counterparties(counterparty_id),
    INDEX idx_trades_portfolio (portfolio_id),
    INDEX idx_trades_asset (asset_id),
    INDEX idx_trades_datetime (trade_datetime)
);

-- Current positions
CREATE TABLE positions (
    position_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    portfolio_id VARCHAR(20) NOT NULL,
    asset_id VARCHAR(20) NOT NULL,
    quantity DECIMAL(15,4) NOT NULL,
    avg_cost_price DECIMAL(12,6) NOT NULL,
    market_price DECIMAL(12,6),
    market_value DECIMAL(18,2) GENERATED ALWAYS AS (quantity * market_price) STORED,
    unrealized_pnl DECIMAL(18,2) GENERATED ALWAYS AS (quantity * (market_price - avg_cost_price)) STORED,
    position_date DATE NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (portfolio_id) REFERENCES portfolios(portfolio_id),
    FOREIGN KEY (asset_id) REFERENCES assets(asset_id),
    UNIQUE KEY uk_positions (portfolio_id, asset_id, position_date),
    INDEX idx_positions_portfolio (portfolio_id),
    INDEX idx_positions_date (position_date)
);

-- =====================================================
-- RISK MANAGEMENT TABLES
-- =====================================================

-- Daily portfolio performance and risk metrics
CREATE TABLE portfolio_performance (
    perf_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    portfolio_id VARCHAR(20) NOT NULL,
    performance_date DATE NOT NULL,
    nav DECIMAL(18,2) NOT NULL,
    total_return DECIMAL(18,2),
    daily_return DECIMAL(8,6),
    cumulative_return DECIMAL(8,6),
    volatility_1m DECIMAL(8,6),
    volatility_3m DECIMAL(8,6),
    sharpe_ratio DECIMAL(8,4),
    max_drawdown DECIMAL(8,6),
    var_1d_95 DECIMAL(18,2),
    var_1d_99 DECIMAL(18,2),
    beta DECIMAL(8,4),
    alpha DECIMAL(8,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (portfolio_id) REFERENCES portfolios(portfolio_id),
    UNIQUE KEY uk_portfolio_perf (portfolio_id, performance_date),
    INDEX idx_perf_date (performance_date)
);

-- Risk limits and monitoring
CREATE TABLE risk_limits (
    limit_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    portfolio_id VARCHAR(20) NOT NULL,
    limit_type ENUM('VAR', 'EXPOSURE', 'CONCENTRATION', 'DRAWDOWN', 'LEVERAGE') NOT NULL,
    asset_id VARCHAR(20),
    sector VARCHAR(50),
    limit_value DECIMAL(18,2) NOT NULL,
    current_value DECIMAL(18,2),
    utilization DECIMAL(5,4) GENERATED ALWAYS AS (current_value / limit_value) STORED,
    breach_threshold DECIMAL(5,4) DEFAULT 0.90,
    is_breached BOOLEAN GENERATED ALWAYS AS (utilization > breach_threshold) STORED,
    effective_date DATE NOT NULL,
    expiry_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (portfolio_id) REFERENCES portfolios(portfolio_id),
    FOREIGN KEY (asset_id) REFERENCES assets(asset_id),
    INDEX idx_risk_limits_portfolio (portfolio_id),
    INDEX idx_risk_limits_breach (is_breached, is_active)
);

-- =====================================================
-- ANALYTICS & REPORTING TABLES
-- =====================================================

-- Daily P&L attribution
CREATE TABLE pnl_attribution (
    pnl_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    portfolio_id VARCHAR(20) NOT NULL,
    asset_id VARCHAR(20) NOT NULL,
    attribution_date DATE NOT NULL,
    position_pnl DECIMAL(15,2) DEFAULT 0,
    trading_pnl DECIMAL(15,2) DEFAULT 0,
    fx_pnl DECIMAL(15,2) DEFAULT 0,
    total_pnl DECIMAL(15,2) GENERATED ALWAYS AS (position_pnl + trading_pnl + fx_pnl) STORED,
    quantity_start DECIMAL(15,4),
    quantity_end DECIMAL(15,4),
    price_start DECIMAL(12,6),
    price_end DECIMAL(12,6),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (portfolio_id) REFERENCES portfolios(portfolio_id),
    FOREIGN KEY (asset_id) REFERENCES assets(asset_id),
    UNIQUE KEY uk_pnl_attribution (portfolio_id, asset_id, attribution_date),
    INDEX idx_pnl_date (attribution_date)
);

-- Audit trail for all critical operations
CREATE TABLE audit_log (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    operation_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    record_id VARCHAR(50) NOT NULL,
    old_values JSON,
    new_values JSON,
    user_id VARCHAR(50),
    operation_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_audit_table (table_name),
    INDEX idx_audit_datetime (operation_datetime)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- =====================================================

-- Composite indexes for common query patterns
CREATE INDEX idx_market_data_asset_time ON market_data(asset_id, price_date DESC, price_time DESC);
CREATE INDEX idx_trades_portfolio_date ON trades(portfolio_id, trade_datetime DESC);
CREATE INDEX idx_positions_portfolio_asset ON positions(portfolio_id, asset_id, position_date DESC);
CREATE INDEX idx_performance_portfolio_date ON portfolio_performance(portfolio_id, performance_date DESC);

-- Composite indexes for dashboard queries
CREATE INDEX idx_orders_dashboard ON orders(portfolio_id, order_status, order_datetime DESC, asset_id, side, quantity, price);

-- =====================================================
-- SAMPLE DATA POPULATION QUERIES
-- (Run these after schema creation)
-- =====================================================