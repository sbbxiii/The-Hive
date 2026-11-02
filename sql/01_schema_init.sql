-- ==============================================================================
-- The Hive — Infrastructure & Telemetry Database Schema
-- Dialect: MariaDB 11.4 / MySQL Compatible
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS homelab
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE homelab;

-- ------------------------------------------------------------------------------
-- 1. Cluster Physical & Virtual Nodes
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cluster_nodes (
    node_id INT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(64) NOT NULL UNIQUE,
    ip_address VARCHAR(45) NOT NULL,
    subnet_cidr VARCHAR(18) NOT NULL DEFAULT '192.168.100.0/24',
    cluster_role ENUM('manager', 'worker', 'standalone') NOT NULL DEFAULT 'worker',
    hardware_base VARCHAR(128) NOT NULL COMMENT 'e.g. Acer Aspire 1 A114-32 salvaged chassis',
    cpu_model VARCHAR(128) NOT NULL,
    cpu_cores INT NOT NULL,
    cpu_threads INT NOT NULL,
    ram_installed_mb INT NOT NULL,
    storage_capacity_gb DECIMAL(8, 2) NOT NULL,
    tdp_watts DECIMAL(5, 2) NOT NULL DEFAULT 15.00,
    os_kernel VARCHAR(128) NOT NULL DEFAULT 'Linux 6.12.107+deb13-amd64',
    distribution VARCHAR(64) NOT NULL DEFAULT 'Debian GNU/Linux 13 (Trixie)',
    tailscale_ip VARCHAR(45) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_node_role (cluster_role),
    INDEX idx_node_ip (ip_address)
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 2. Containerized Services & Stacks
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS container_services (
    service_id INT AUTO_INCREMENT PRIMARY KEY,
    node_id INT NOT NULL,
    service_name VARCHAR(64) NOT NULL,
    stack_name VARCHAR(64) NOT NULL DEFAULT 'primary',
    docker_image VARCHAR(128) NOT NULL,
    container_mode ENUM('replicated', 'global', 'standalone') NOT NULL DEFAULT 'replicated',
    allocated_replicas INT NOT NULL DEFAULT 1,
    published_port INT NULL,
    internal_port INT NULL,
    protocol ENUM('tcp', 'udp') DEFAULT 'tcp',
    memory_limit_mb INT NULL,
    storage_volume VARCHAR(128) NULL,
    health_status ENUM('healthy', 'running', 'degraded', 'stopped') DEFAULT 'running',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_service_node FOREIGN KEY (node_id)
        REFERENCES cluster_nodes (node_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    INDEX idx_service_status (health_status),
    INDEX idx_service_name (service_name)
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 3. Live Hardware Telemetry Time-Series
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS telemetry_snapshots (
    snapshot_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    node_id INT NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cpu_utilization_pct DECIMAL(5, 2) NOT NULL,
    cpu_temp_celsius DECIMAL(4, 1) NOT NULL,
    power_draw_watts DECIMAL(5, 2) NOT NULL DEFAULT 3.20,
    ram_used_mb INT NOT NULL,
    ram_free_mb INT NOT NULL,
    swap_used_mb INT NOT NULL,
    disk_used_gb DECIMAL(8, 2) NOT NULL,
    network_rx_kbps DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    network_tx_kbps DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    active_containers_count INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_telemetry_node FOREIGN KEY (node_id)
        REFERENCES cluster_nodes (node_id)
        ON DELETE CASCADE,
    INDEX idx_node_timestamp (node_id, recorded_at)
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 4. Hardware Teardown, Soldering & Maintenance Log
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS hardware_maintenance (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    node_id INT NOT NULL,
    maintenance_date DATE NOT NULL,
    category ENUM('chassis_repair', 'soldering_rework', 'thermal_paste', 'storage_upgrade', 'bios_firmware', 'os_repartition') NOT NULL,
    component_affected VARCHAR(128) NOT NULL,
    defect_description TEXT NOT NULL,
    action_taken TEXT NOT NULL,
    is_resolved BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_maintenance_node FOREIGN KEY (node_id)
        REFERENCES cluster_nodes (node_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------------------------
-- 5. Seed Initial Data (Current Cluster State)
-- ------------------------------------------------------------------------------
INSERT INTO cluster_nodes 
(hostname, ip_address, cluster_role, hardware_base, cpu_model, cpu_cores, cpu_threads, ram_installed_mb, storage_capacity_gb, tdp_watts, tailscale_ip)
VALUES 
('claude', '192.168.100.121', 'manager', 'Salvaged Acer Aspire 1 / Repaired i3-5005U Laptop', 'Intel(R) Core(TM) i3-5005U CPU @ 2.00GHz', 2, 4, 3840, 452.59, 15.00, '100.64.0.10'),
('gpt', '192.168.100.126', 'worker', 'Salvaged Bare-Metal Laptop Node', 'Intel Core x86_64 Low-Power Mobile CPU', 2, 4, 3840, 62.50, 15.00, NULL)
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

-- Insert Seed Maintenance Records
INSERT INTO hardware_maintenance 
(node_id, maintenance_date, category, component_affected, defect_description, action_taken)
VALUES
(1, '2025-08-14', 'chassis_repair', 'Display Hinge & Top Plastic Case', 'Severe chassis plastic fracture along left hinge anchor resulting in lid detachment.', 'Disassembled case, re-anchored brass threaded inserts with high-tensile epoxy, reinforced hinge pivot.'),
(1, '2025-08-16', 'soldering_rework', 'DC Barrel Jack Wire Harness', 'Intermittent contact and power dropouts on standard barrel input pin.', 'Desoldered fatigued leads, replaced DC harness, shielded with heat shrink and tested continuity.'),
(1, '2025-08-20', 'os_repartition', 'Storage Controller & eMMC / SSD', 'Original OEM drive locked; needed manual partition table for headless server.', 'Booted Debian installer, partitioned 1.0GB ESP, 3.2GB Swap, and 58.3GB ext4 bare-metal root partition.'),
(1, '2025-09-02', 'thermal_paste', 'Heatsink Thermal Interface', 'High idle temperatures (72C) due to degraded 5-year-old factory thermal grease.', 'Cleaned die with 99% isopropyl alcohol, applied Arctic MX-4 compound; dropped thermal equilibrium to 50C.');

-- Insert Active Services Running on claude
INSERT INTO container_services 
(node_id, service_name, stack_name, docker_image, container_mode, allocated_replicas, published_port, internal_port, health_status)
VALUES
(1, 'mariadb', 'database', 'mariadb:11.4', 'replicated', 1, 3306, 3306, 'healthy'),
(1, 'cloudbeaver', 'database', 'dbeaver/cloudbeaver:latest', 'replicated', 1, 8978, 8978, 'running'),
(1, 'portainer', 'management', 'portainer/portainer-ce:2.21.5', 'replicated', 1, 9443, 9443, 'running'),
(1, 'glances', 'telemetry', 'nicolargo/glances:latest-full', 'global', 1, 61208, 61208, 'running'),
(1, 'pihole', 'network', 'pihole/pihole:latest', 'replicated', 1, 53, 53, 'healthy'),
(1, 'n8n', 'automation', 'n8nio/n8n:2.34.4', 'replicated', 1, 5678, 5678, 'running'),
(1, 'jellyfin', 'media', 'linuxserver/jellyfin:10.11.10', 'replicated', 1, 8097, 8096, 'running'),
(1, 'spiderfoot', 'security', 'spiderfoot:local', 'replicated', 1, 5001, 5001, 'running'),
(1, 'gods-eye-view', 'analytics', 'gods-eye-view:local', 'replicated', 1, 4173, 4173, 'running');
