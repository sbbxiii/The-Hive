-- ==============================================================================
-- The Hive — Database Maintenance, Security Isolation & Performance Tuning
-- ==============================================================================

USE homelab;

-- ------------------------------------------------------------------------------
-- 1. Security & Principle of Least Privilege: Role Separation
-- ------------------------------------------------------------------------------
-- Read-only monitoring account for Grafana / Glances / Telemetry ingest
CREATE USER IF NOT EXISTS 'telemetry_reader'@'192.168.100.%' 
  IDENTIFIED BY 'telemetry_secure_readonly_token';

GRANT SELECT ON homelab.telemetry_snapshots TO 'telemetry_reader'@'192.168.100.%';
GRANT SELECT ON homelab.cluster_nodes TO 'telemetry_reader'@'192.168.100.%';
GRANT SELECT ON homelab.container_services TO 'telemetry_reader'@'192.168.100.%';

-- Application worker account restricted strictly to n8n database operations
CREATE USER IF NOT EXISTS 'n8n_app'@'192.168.100.%' 
  IDENTIFIED BY 'n8n_isolated_app_token';

GRANT SELECT, INSERT, UPDATE, DELETE ON homelab.container_services TO 'n8n_app'@'192.168.100.%';

FLUSH PRIVILEGES;

-- ------------------------------------------------------------------------------
-- 2. Performance Indexing Optimization
-- ------------------------------------------------------------------------------
-- Composite index for fast time-window analytical queries
ALTER TABLE telemetry_snapshots 
  ADD INDEX IF NOT EXISTS idx_telemetry_composite (node_id, recorded_at, cpu_utilization_pct);

-- ------------------------------------------------------------------------------
-- 3. Stored Procedure: Automated Telemetry Partition Pruning (Data Retention)
-- ------------------------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE IF NOT EXISTS PurgeOldTelemetry(IN retention_days INT)
BEGIN
    DECLARE deleted_rows INT DEFAULT 0;
    
    DELETE FROM telemetry_snapshots 
    WHERE recorded_at < DATE_SUB(NOW(), INTERVAL retention_days DAY);
    
    SET deleted_rows = ROW_COUNT();
    
    SELECT CONCAT('Successfully pruned ', deleted_rows, ' stale telemetry snapshots older than ', retention_days, ' days.') AS result_message;
END //

DELIMITER ;

-- ------------------------------------------------------------------------------
-- 4. Health Check Trigger: Flag Suspicious Hardware Temperatures (>85°C)
-- ------------------------------------------------------------------------------
DELIMITER //

CREATE TRIGGER IF NOT EXISTS trg_thermal_overheat_alert
BEFORE INSERT ON telemetry_snapshots
FOR EACH ROW
BEGIN
    IF NEW.cpu_temp_celsius > 85.0 THEN
        INSERT INTO hardware_maintenance (node_id, maintenance_date, category, component_affected, defect_description, action_taken, is_resolved)
        VALUES (
            NEW.node_id, 
            CURRENT_DATE, 
            'thermal_paste', 
            'CPU Heatsink & Blower Fan', 
            CONCAT('Thermal throttle danger: CPU recorded ', NEW.cpu_temp_celsius, 'C under ', NEW.cpu_utilization_pct, '% load.'), 
            'Automated warning created; pending physical dust inspection and fan speed check.',
            FALSE
        );
    END IF;
END //

DELIMITER ;
