# The Hive — Resilient Multi-Node Docker Swarm Homelab & SQL Infrastructure

[![Operating System](https://img.shields.io/badge/OS-Debian%20GNU%2FLinux%2013%20(Trixie)-red.svg)](https://www.debian.org/)
[![Kernel](https://img.shields.io/badge/Kernel-Linux%206.12.107%2Bdeb13--amd64-blue.svg)]()
[![Container Orchestration](https://img.shields.io/badge/Orchestrator-Docker%20Swarm%2029.8.1-2496ED.svg)](https://docs.docker.com/engine/swarm/)
[![Database](https://img.shields.io/badge/Database-MariaDB%2011.4%20%7C%20PostgreSQL%2014-003545.svg)](https://mariadb.org/)
[![Network Security](https://img.shields.io/badge/Security-Tailscale%20Zero--Trust%20Mesh%20%7C%20Ed25519%20SSH-black.svg)](https://tailscale.com/)
[![Energy Efficiency](https://img.shields.io/badge/Power-3.2W%20Idle%20%7C%20%3C15W%20TDP-success.svg)]()
[![Uptime](https://img.shields.io/badge/Uptime-35%2B%20Days%20Continuous-brightgreen.svg)]()

**The Hive** is a production-grade, energy-efficient 2-node headless Linux server infrastructure built by salvaging, restoring, and repurposing **two decommissioned, physically damaged consumer laptops** into a high-availability **Docker Swarm** cluster:
* **Laptop Node 1 (`claude` — Swarm Manager @ `192.168.100.121`):** Salvaged Acer Aspire 1 laptop powered by an Intel Core i3-5005U processor (2 cores, 4 threads @ 2.0 GHz, 3.8 GB RAM, 453 GB storage), restored from structural casing fracture, DC barrel jack wire harness failure, and degraded thermal interface. Acts as the Swarm Leader hosting MariaDB 11.4 SQL, Portainer CE, n8n, Pi-hole, and core services.
* **Laptop Node 2 (`gpt` — Swarm Worker @ `192.168.100.126`):** Second salvaged low-spec mobile laptop repaired, fitted with bare-metal Debian Linux, and joined to the Swarm cluster as a dedicated compute worker to host distributed containerized workloads (CloudBeaver database GUI, Portainer Swarm agents).

By combining **mechatronics hardware overhaul** (structural case rebuilding, DC power harness repair, thermal compound replacement) with **enterprise IT systems administration** (bare-metal partition engineering, container orchestration, zero-trust overlay networking, and relational SQL database design), **The Hive** serves 14+ self-hosted microservices 24/7 across two physical laptop nodes with an idle thermal footprint of **3.2W** and continuous 35+ day uptime.

---

## Architecture & Cluster Topology

```mermaid
flowchart TD
    subgraph Clients["Client Access Layer"]
        Mac["MacBook Air / Admin Terminal"]
        Remote["Mobile / Remote Clients"]
    end

    subgraph MeshNetwork["Zero-Trust Security Layer (Tailscale & Hardened SSH)"]
        TS["Tailscale Encrypted Mesh Overlay (100.x.x.x)"]
        SSH["Ed25519 Cryptographic SSH Key Pair Auth"]
    end

    subgraph Cluster["The Hive — Swarm Cluster (Subnet 192.168.100.0/24)"]
        subgraph NodeClaude["Manager Node: 'claude' (192.168.100.121)"]
            OS1["Debian 13 (Linux 6.12 x86_64)<br/>Intel Core i3-5005U (4T @ 2.0GHz, 3.8GB RAM)"]
            SwarmM["Docker Swarm Leader / Engine 29.8.1"]
            PortainerM["Portainer CE (Port 9443)"]
            CasaOS["CasaOS Dashboard (Port 81)"]
            MariaDB["MariaDB 11.4 SQL (Port 3306)"]
            Postgres["PostgreSQL 14.2 (Port 5432)"]
            N8N["n8n Automation Engine (Port 5678)"]
            PiHole["Pi-hole DNS Sinkhole (Port 53/8080)"]
            Glances1["Glances Telemetry (Port 61208)"]
            Jellyfin["Jellyfin Media Server (Port 8096)"]
            Spiderfoot["SpiderFoot OSINT (Port 5001)"]
            GodsEye["God's Eye View 3D Tracker (Port 4173)"]
            Ollama["Ollama Local AI (Qwen 2.5 / Hermes)"]
        end

        subgraph NodeGPT["Worker Node: 'gpt' (192.168.100.126)"]
            OS2["Debian 13 Bare-Metal Node<br/>Low-Power x86 Mobile CPU (3.8GB RAM)"]
            SwarmW["Docker Swarm Worker"]
            PortAgent["Portainer Global Swarm Agent"]
            CloudBeaver["CloudBeaver SQL Web GUI (Port 8978)"]
        end
    end

    Mac --> TS
    Remote --> TS
    TS --> SSH
    SSH --> SwarmM
    SwarmM <===>|"Overlay Network (vxlan)"| SwarmW
```

---

## Hardware Restoration & Mechatronics Roots

Rather than buying expensive rack-mount servers, this cluster was engineered from discarded, low-spec laptops with damaged enclosures and power delivery faults.

| 1. Salvaged Acer Chassis & Model Plate | 2. Structural Hinge Fracture Before Repair |
| :---: | :---: |
| <img src="docs/images/01_salvaged_hardware_acer_back.jpg" alt="Acer Aspire Spec Plate" width="420"> | <img src="docs/images/02_hinge_chassis_crack_damage.jpg" alt="Hinge Damage" width="420"> |
| *Acer Aspire 1 (A114-32 / N17Q4) base chassis* | *Severe casing fracture adjacent to power switch & hinge anchor* |

| 3. Internal Hardware Overhaul & Teardown | 4. Bare-Metal Debian Partition Engineering |
| :---: | :---: |
| <img src="docs/images/03_hardware_teardown_repair.jpg" alt="Hardware Teardown" width="420"> | <img src="docs/images/04_baremetal_debian_partitioning.jpg" alt="Debian Partitioning" width="420"> |
| *Motherboard teardown, DC jack wiring rework, USB daughterboard, hinge epoxy anchoring, thermal cleaning* | *Manual partition mapping: 1.0GB ESP, 3.2GB Swap, 58.3GB ext4 bare-metal root partition on eMMC* |

### The Two Bare-Metal Physical Laptop Nodes
1. **Node 1: `claude` (Manager / Leader — `192.168.100.121`):**
   * **Base Machine:** Salvaged Acer Aspire 1 (A114-32 / N17Q4).
   * **Specs:** Intel Core i3-5005U (2 cores, 4 threads @ 2.00 GHz, 15W TDP), 3.74 GB DDR3 RAM, 453 GB mass storage.
   * **Role:** Docker Swarm Leader node running MariaDB 11.4 SQL, Portainer CE orchestrator, n8n workflow engine, Pi-hole DNS sinkhole, and system telemetry.
2. **Node 2: `gpt` (Compute Worker — `192.168.100.126`):**
   * **Base Machine:** Repaired low-power x86_64 mobile laptop.
   * **Specs:** 2 cores, 4 threads low-power CPU, 3.8 GB RAM, 62.5 GB bare-metal eMMC storage.
   * **Role:** Docker Swarm compute worker node running distributed worker containers (CloudBeaver SQL web client, Portainer global agent) attached via VXLAN overlay network.

### Key Mechanical & Electronic Interventions:
1. **Structural Case Repair:** Disassembled damaged chassis, bonded fractured structural ribs using high-tensile epoxy, and re-seated stripped brass threaded inserts to permanently secure the hinge assembly.
2. **DC Power Harness Soldering:** Repaired fatigued internal power leads on the DC barrel connector, insulating solder joints with heat shrink to eliminate power dropouts.
3. **Thermal Restoration:** Removed degraded 5-year-old factory paste from the Intel Core i3 SoC, polished heatsink mating surfaces with 99% isopropyl alcohol, and applied Arctic MX-4 compound—lowering idle temperatures from 72°C to **50°C** under continuous load.
4. **Firmware & BIOS Configuration:** Enabled AC power-loss auto-restart in BIOS, adjusted PCIe power states, and bypassed non-functional display panels.

---

## Live System Telemetry & Dashboards

| CasaOS Unified Microservices Dashboard | Glances Real-Time Hardware & Container Telemetry |
| :---: | :---: |
| <img src="docs/images/05_casaos_service_dashboard.jpeg" alt="CasaOS Dashboard" width="450"> | <img src="docs/images/06_glances_system_telemetry.jpeg" alt="Glances Telemetry" width="450"> |
| *14 active containers (MariaDB, CloudBeaver, Home Assistant, n8n, Pi-hole, Jellyfin, Tailscale) with healthy status* | *Debian 13 (Linux 6.12), Intel Core i3-5005U (4 threads), 3.74 GB RAM, 3.2W idle power draw, 50°C thermal equilibrium* |

---

## Microservices Architecture & Port Mapping

| Service Name | Stack / Role | Base Image | Published Port | Health / Mode | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **MariaDB** | Database | `mariadb:11.4` | `3306/tcp` | Replicated (Healthy) | Core relational SQL database for homelab metrics & app states |
| **CloudBeaver** | Database GUI | `dbeaver/cloudbeaver:latest` | `8978/tcp` | Replicated (Worker) | Web-based relational database administration interface |
| **PostgreSQL** | Database | `postgres:14.2` | `5432/tcp` | Standalone (Healthy) | Dedicated ACID-compliant relational backend for n8n workflows |
| **n8n** | Automation | `n8nio/n8n:2.34.4` | `5678/tcp` | Replicated | Low-code workflow automation orchestrating API & webhook tasks |
| **Portainer CE** | Orchestration | `portainer/portainer-ce:2.21.5` | `9000/9443/tcp` | Swarm Leader | Centralized web interface for Docker Swarm stack management |
| **Portainer Agent** | Orchestration | `portainer/agent:2.21.5` | `9001/tcp` | Global (All Nodes) | Distributed telemetry and task agent across cluster worker nodes |
| **Glances** | Monitoring | `nicolargo/glances:latest-full` | `61208/61209/tcp` | Global | Real-time multi-metric resource monitor (CPU, RAM, disk, I/O) |
| **Pi-hole** | DNS & Security | `pihole/pihole:latest` | `53/udp, 8080/tcp` | Replicated (Healthy) | Network-wide ad blocker and local recursive DNS resolver |
| **Tailscale** | Networking | `tailscale/tailscale:v1.98.3` | N/A (Mesh WireGuard) | Host Mode | Zero-trust encrypted overlay mesh VPN for secure remote administration |
| **SpiderFoot** | Security / OSINT | `spiderfoot:local` | `5001/tcp` | Replicated | Automated OSINT reconnaissance, IP lookup & security scanning |
| **God's Eye View** | Geospatial / AI | `gods-eye-view:local` | `4173/tcp` | Replicated | Real-time 3D spatial intelligence globe & vehicle tracking |
| **Jellyfin** | Media Streaming | `linuxserver/jellyfin:10.11.10`| `8096/8097/tcp` | Replicated | Private hardware-accelerated media streaming server |
| **Hermes / Ollama** | Private AI | `local-inference` | `8642/9119/tcp` | Replicated | Edge large language model execution (Qwen 2.5 Coder) |

---

## Relational SQL Engineering

The homelab runs **MariaDB 11.4** and **PostgreSQL 14.2** with structured schemas modeling nodes, containers, maintenance logs, and telemetry time-series:

### 1. Database Schema Highlights (`sql/01_schema_init.sql`)
* **`cluster_nodes`**: Tracks hardware specs, CPU cores/threads, RAM, storage, TDP wattage, OS kernel, and role.
* **`container_services`**: Tracks Docker images, replicated/global mode, published/internal ports, volumes, and health states.
* **`telemetry_snapshots`**: High-frequency metric logging (CPU %, thermal sensors, power watts, memory utilization, network Rx/Tx).
* **`hardware_maintenance`**: Grounded mechanical and electronic log documenting teardown, soldering, and partition history.

### 2. Analytical Queries (`sql/02_telemetry_queries.sql`)
Demonstrates production SQL capabilities including **Common Table Expressions (CTEs)**, **Window Functions** (`AVG() OVER ... ROWS BETWEEN 5 PRECEDING`), and **Aggregations**:

```sql
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
    FROM telemetry_snapshots
)
SELECT m.node_id, n.hostname, m.recorded_at, m.cpu_utilization_pct, 
       m.cpu_temp_celsius, ROUND(m.rolling_avg_temp_5_period, 2) AS smoothed_temp_c
FROM NodeMetrics m
JOIN cluster_nodes n ON m.node_id = n.node_id
WHERE m.load_spike_rank <= 3
ORDER BY m.cpu_utilization_pct DESC;
```

### 3. Role-Based Privilege Isolation (`sql/03_backup_and_maintenance.sql`)
* Created dedicated, least-privilege users (`telemetry_reader` restricted to `SELECT` on metrics, `n8n_app` scoped strictly to application tables).
* Stored procedures (`PurgeOldTelemetry`) for automatic time-series retention and table pruning.
* Automated triggers (`trg_thermal_overheat_alert`) creating maintenance tickets if CPU junction temperatures exceed 85°C.

---

## Linux System Administration & Headless Tuning

### 1. Systemd Power & Lid-Switch Configuration
Repurposing laptop motherboards requires disabling ACPI sleep triggers on lid closure:
```ini
# /etc/systemd/logind.conf.d/00-headless-server.conf
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
IdleAction=ignore
```

### 2. Zero-Trust Networking & SSH Hardening
* **Overlay Mesh:** Integrated **Tailscale** WireGuard mesh network; all administration occurs over authenticated Tailscale IP ranges, avoiding WAN port forwards.
* **Cryptographic Keys:** Enforced **Ed25519** public-key authentication, completely disabling password authentication and remote direct root logins:
```bash
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin prohibit-password
MaxAuthTries 3
```

---

## Repository Structure

```
The-Hive/
├── README.md                           # Comprehensive documentation & architecture guide
├── docker/
│   ├── docker-stack.yml                # Docker Swarm multi-node stack configuration
│   └── docker-compose.yml              # Standalone compose specification
├── sql/
│   ├── 01_schema_init.sql              # Relational schema (nodes, services, telemetry, maintenance)
│   ├── 02_telemetry_queries.sql        # Advanced analytics (CTEs, window functions, aggregations)
│   └── 03_backup_and_maintenance.sql   # Security isolation, stored procedures, retention triggers
├── scripts/
│   ├── setup_node.sh                   # Headless node provisioning & systemd configuration
│   └── backup_mariadb.sh               # Automated database backup and rotation script
└── docs/
    └── images/
        ├── 01_salvaged_hardware_acer_back.jpg
        ├── 02_hinge_chassis_crack_damage.jpg
        ├── 03_hardware_teardown_repair.jpg
        ├── 04_baremetal_debian_partitioning.jpg
        ├── 05_casaos_service_dashboard.jpeg
        └── 06_glances_system_telemetry.jpeg
```

---

## License

This project is licensed under the [MIT License](LICENSE).
