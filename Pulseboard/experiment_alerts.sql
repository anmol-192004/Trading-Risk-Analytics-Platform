
-- =============================================================
-- Pulesboard – PART 3: Experiments & Alerts (MySQL 8+)
-- =============================================================
USE pulesboard;

-- Drops for re-runs
DROP TABLE IF EXISTS alert_event;
DROP TABLE IF EXISTS alert_rule;
DROP TABLE IF EXISTS experiment_observation;
DROP TABLE IF EXISTS experiment;

-- Experiments (A/B)
CREATE TABLE experiment (
  experiment_id     INT PRIMARY KEY AUTO_INCREMENT,
  name              VARCHAR(160) NOT NULL UNIQUE,
  metric_id         INT NOT NULL,
  start_ts          DATETIME NOT NULL,
  end_ts            DATETIME NULL,
  variant_a_label   VARCHAR(40) NOT NULL DEFAULT 'A',
  variant_b_label   VARCHAR(40) NOT NULL DEFAULT 'B',
  notes             VARCHAR(400) NULL,
  CONSTRAINT fk_exp_metric FOREIGN KEY (metric_id) REFERENCES metric(metric_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE experiment_observation (
  id             BIGINT PRIMARY KEY AUTO_INCREMENT,
  experiment_id  INT NOT NULL,
  ts_date        DATE NOT NULL,
  variant        VARCHAR(40) NOT NULL, -- 'A' or 'B'
  samples        INT NOT NULL,         -- exposure
  conversions    INT NULL,             -- successes for binary metric
  value_sum      DOUBLE NULL,          -- sum for continuous
  value_avg      DOUBLE NULL,          -- avg for continuous
  UNIQUE KEY u_exp_obs (experiment_id, ts_date, variant),
  CONSTRAINT fk_exp_obs FOREIGN KEY (experiment_id) REFERENCES experiment(experiment_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Alerts
CREATE TABLE alert_rule (
  rule_id        INT PRIMARY KEY AUTO_INCREMENT,
  metric_id      INT NOT NULL,
  rule_name      VARCHAR(160) NOT NULL,
  direction      ENUM('above','below') NOT NULL,
  threshold      DOUBLE NOT NULL,
  lookback_days  INT NOT NULL DEFAULT 1,
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_alert_metric FOREIGN KEY (metric_id) REFERENCES metric(metric_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE alert_event (
  event_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
  rule_id       INT NOT NULL,
  metric_id     INT NOT NULL,
  ts            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  observed      DOUBLE NOT NULL,
  message       VARCHAR(400) NULL,
  CONSTRAINT fk_event_rule FOREIGN KEY (rule_id) REFERENCES alert_rule(rule_id) ON DELETE CASCADE,
  CONSTRAINT fk_event_metric FOREIGN KEY (metric_id) REFERENCES metric(metric_id) ON DELETE CASCADE
) ENGINE=InnoDB;
