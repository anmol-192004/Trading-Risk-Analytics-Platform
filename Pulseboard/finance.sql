
-- =============================================================
-- Pulesboard – PART 2 (FIX): Finance / Market Data (MySQL 8+)
-- Run after PART 1 (core). This script is idempotent.
-- =============================================================
USE `pulesboard`;

-- Disable FKs during drops to avoid dependency errors
SET @OLD_FK_CHECKS = @@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS = 0;

-- Drops in child→parent order
DROP TABLE IF EXISTS `portfolio_weight`;
DROP TABLE IF EXISTS `asset_price`;
DROP TABLE IF EXISTS `factor_returns`;
DROP TABLE IF EXISTS `portfolio`;
DROP TABLE IF EXISTS `asset`;

-- Restore FK checks for creates
SET FOREIGN_KEY_CHECKS = @OLD_FK_CHECKS;

-- ---------------- Assets & Prices ----------------
CREATE TABLE `asset` (
  `asset_id`   INT PRIMARY KEY AUTO_INCREMENT,
  `symbol`     VARCHAR(24) NOT NULL UNIQUE,
  `name`       VARCHAR(160) NULL,
  `sector`     VARCHAR(80) NULL,
  `currency`   VARCHAR(12) NULL DEFAULT 'USD',
  `tags`       JSON NULL,
  `is_active`  BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE `asset_price` (
  `id`        BIGINT PRIMARY KEY AUTO_INCREMENT,
  `asset_id`  INT NOT NULL,
  `ts_date`   DATE NOT NULL,
  `open_px`   DOUBLE NULL,
  `high_px`   DOUBLE NULL,
  `low_px`    DOUBLE NULL,
  `close_px`  DOUBLE NOT NULL,
  `adj_close` DOUBLE NULL,
  `volume`    BIGINT NULL,
  UNIQUE KEY `u_asset_day` (`asset_id`, `ts_date`),
  KEY `k_asset_day` (`asset_id`, `ts_date`),
  CONSTRAINT `fk_price_asset`
    FOREIGN KEY (`asset_id`) REFERENCES `asset`(`asset_id`)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------- Portfolios & Weights ----------------
CREATE TABLE `portfolio` (
  `portfolio_id`  INT PRIMARY KEY AUTO_INCREMENT,
  `name`          VARCHAR(120) NOT NULL UNIQUE,
  `base_currency` VARCHAR(12) NOT NULL DEFAULT 'USD',
  `inception_nav` DOUBLE NOT NULL DEFAULT 1.0
) ENGINE=InnoDB;

CREATE TABLE `portfolio_weight` (
  `id`            BIGINT PRIMARY KEY AUTO_INCREMENT,
  `portfolio_id`  INT NOT NULL,
  `asset_id`      INT NOT NULL,
  `weight`        DOUBLE NOT NULL,
  `effective_date` DATE NOT NULL,
  UNIQUE KEY `u_pf_asset_eff` (`portfolio_id`, `asset_id`, `effective_date`),
  KEY `k_pf_eff` (`portfolio_id`, `effective_date`),
  CONSTRAINT `fk_w_pf` FOREIGN KEY (`portfolio_id`) REFERENCES `portfolio`(`portfolio_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_w_asset` FOREIGN KEY (`asset_id`) REFERENCES `asset`(`asset_id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------- Factor Returns (optional) ----------------
CREATE TABLE `factor_returns` (
  `id`      BIGINT PRIMARY KEY AUTO_INCREMENT,
  `ts_date` DATE NOT NULL,
  `factor`  VARCHAR(32) NOT NULL,
  `value`   DOUBLE NOT NULL,
  UNIQUE KEY `u_fac_date` (`factor`, `ts_date`)
) ENGINE=InnoDB;
