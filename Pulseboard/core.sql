
-- =============================================================
-- Pulesboard – PART 1: Core DB & Metric Store (MySQL 8+)
-- =============================================================

-- Create & use database (spelling per user request)
CREATE DATABASE IF NOT EXISTS pulesboard
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE pulesboard;

-- (Optional) safer SQL modes without ONLY_FULL_GROUP_BY
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- Drop (if re-running)
DROP TABLE IF EXISTS metric_value;
DROP TABLE IF EXISTS metric;

-- Core tables
CREATE TABLE metric (
  metric_id       INT PRIMARY KEY AUTO_INCREMENT,
  name            VARCHAR(120) NOT NULL UNIQUE,
  description     VARCHAR(400) NULL,
  frequency       ENUM('hourly','daily','weekly','monthly') NOT NULL DEFAULT 'daily',
  aggregator      ENUM('sum','avg','last','min','max') NOT NULL DEFAULT 'sum',
  unit            VARCHAR(40) NULL,
  entity          VARCHAR(120) NULL,
  tags            JSON NULL,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE metric_value (
  id             BIGINT PRIMARY KEY AUTO_INCREMENT,
  metric_id      INT NOT NULL,
  ts             DATETIME(3) NOT NULL,
  value          DOUBLE NOT NULL,
  source         VARCHAR(120) NULL,
  tags           JSON NULL,
  ts_date        DATE AS (DATE(ts)) STORED,
  UNIQUE KEY u_metric_ts (metric_id, ts),
  KEY k_metric_date (metric_id, ts_date, ts),
  CONSTRAINT fk_metric_value_metric
    FOREIGN KEY (metric_id) REFERENCES metric(metric_id)
    ON DELETE CASCADE
) ENGINE=InnoDB;
