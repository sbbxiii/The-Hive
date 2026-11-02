-- ==============================================================================
-- The Hive — Analytical SQL Queries & Infrastructure Auditing
-- Demonstrates: CTEs, Window Functions, Aggregations, Conditional Filtering
-- ==============================================================================

USE homelab;

-- ------------------------------------------------------------------------------
-- Query 1: Cluster Health Overview & Total Workload Distribution
-- ------------------------------------------------------------------------------
SELECT 
    n.hostname,
    n.ip_address,
    n.cluster_role,
    COUNT(s.service_id) AS total_services_hosted,
    SUM(CASE WHEN s.health_status = 'healthy' THEN 1 ELSE 0 END) AS healthy_services,
    SUM(CASE WHEN s.health_status = 'running' THEN 1 ELSE 0 END) AS running_services,
    ROUND((n.ram_installed_mb / 1024), 2) AS total_ram_gb,
    n.tdp_watts
FROM 
    cluster_nodes n
LEFT JOIN 
    container_services s ON n.node_id = s.node_id
WHERE 
    n.is_active = TRUE
GROUP BY 
    n.node_id, n.hostname, n.ip_address, n.cluster_role, n.ram_installed_mb, n.tdp_watts
ORDER BY 
    total_services_hosted DESC;

-- ------------------------------------------------------------------------------
-- Query 2: Peak Power & Thermal Rolling Average (Common Table Expressions & Window Functions)
-- ------------------------------------------------------------------------------
WITH NodeMetrics AS (
    SELECT 
        node_id,
        recorded_at,
        cpu_utilization_pct,
        cpu_temp_celsius,
        power_draw_watts,
        AVG(cpu_temp_celsius) OVER (
            PARTITION BY node_id 
            ORDER BY recorded_at 
            ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) AS rolling_avg_temp_5_period,
        DENSE_RANK() OVER (
            PARTITION BY node_id 
            ORDER BY cpu_utilization_pct DESC
        ) AS load_spike_rank
    FROM 
        telemetry_snapshots
)
SELECT 
    m.node_id,
    n.hostname,
    m.recorded_at,
    m.cpu_utilization_pct,
    m.cpu_temp_celsius,
    ROUND(m.rolling_avg_temp_5_period, 2) AS smoothed_temp_c,
    m.power_draw_watts
FROM 
    NodeMetrics m
JOIN 
    cluster_nodes n ON m.node_id = n.node_id
WHERE 
    m.load_spike_rank <= 3
ORDER BY 
    m.cpu_utilization_pct DESC;

-- ------------------------------------------------------------------------------
-- Query 3: Maintenance History vs. Current Operational Status
-- ------------------------------------------------------------------------------
SELECT 
    n.hostname,
    n.hardware_base,
    m.maintenance_date,
    m.category,
    m.component_affected,
    m.action_taken,
    DATEDIFF(CURRENT_DATE, m.maintenance_date) AS days_since_service
FROM 
    hardware_maintenance m
JOIN 
    cluster_nodes n ON m.node_id = n.node_id
ORDER BY 
    m.maintenance_date DESC;

-- ------------------------------------------------------------------------------
-- Query 4: Memory Consumption by Service Type
-- ------------------------------------------------------------------------------
SELECT 
    stack_name,
    COUNT(service_id) AS service_count,
    GROUP_CONCAT(service_name ORDER BY service_name SEPARATOR ', ') AS deployed_services,
    SUM(COALESCE(memory_limit_mb, 128)) AS total_allocated_mem_mb
FROM 
    container_services
GROUP BY 
    stack_name
ORDER BY 
    total_allocated_mem_mb DESC;
