
-- =============================================================
-- Pulesboard – PART 5: Stored Procedures (MySQL 8+)
-- =============================================================
USE pulesboard;

DROP PROCEDURE IF EXISTS sp_upsert_metric_value;
DROP PROCEDURE IF EXISTS sp_evaluate_alerts;

DELIMITER $$

CREATE PROCEDURE sp_upsert_metric_value(
  IN p_metric_id INT,
  IN p_ts DATETIME,
  IN p_value DOUBLE,
  IN p_source VARCHAR(120)
)
BEGIN
  INSERT INTO metric_value (metric_id, ts, value, source)
  VALUES (p_metric_id, p_ts, p_value, p_source)
  ON DUPLICATE KEY UPDATE
    value = VALUES(value),
    source = VALUES(source);
END$$

CREATE PROCEDURE sp_evaluate_alerts(IN p_metric_id INT)
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE v_rule_id INT;
  DECLARE v_rule_name VARCHAR(160);
  DECLARE v_direction VARCHAR(5);
  DECLARE v_threshold DOUBLE;
  DECLARE v_lookback INT;
  DECLARE recent_avg DOUBLE;

  DECLARE cur CURSOR FOR
    SELECT rule_id, rule_name, direction, threshold, lookback_days
    FROM alert_rule
    WHERE metric_id = p_metric_id AND is_active = TRUE;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_rule_id, v_rule_name, v_direction, v_threshold, v_lookback;
    IF done THEN LEAVE read_loop; END IF;

    -- Compute recent average on last v_lookback points
    SELECT AVG(value) INTO recent_avg
    FROM (
      SELECT value
      FROM metric_value
      WHERE metric_id = p_metric_id
      ORDER BY ts DESC
      LIMIT v_lookback
    ) t;

    IF recent_avg IS NOT NULL THEN
      IF (v_direction = 'above' AND recent_avg > v_threshold)
         OR (v_direction = 'below' AND recent_avg < v_threshold) THEN
        INSERT INTO alert_event (rule_id, metric_id, observed, message)
        VALUES (
          v_rule_id, p_metric_id, recent_avg,
          CONCAT('Rule "', v_rule_name, '" triggered: avg=', ROUND(recent_avg,4),
                 ' threshold=', v_threshold, ' direction=', v_direction)
        );
      END IF;
    END IF;
  END LOOP;
  CLOSE cur;
END$$

DELIMITER ;
