# Golden Configuration Summary
## Home Lab ISR-4331 Routers
**Created**: 2026-01-13
**IOS Version**: 17.12.06
**Password**: c1sc0 (enable secret and username admin)

---

## Router Overview

### EdgeLabRouter-1
- **Management IP**: 192.168.10.55
- **Serial Number**: FLM2245034A
- **Purpose**: Primary edge router with WAN connectivity
- **Networks**:
  - WAN: 192.168.10.55/24 (Gi0/0/0)
  - LAN: 10.0.0.1/24 (Gi0/0/1) - connects to EdgeLabRouter-2
  - VLAN 1: 10.0.1.1/24
  - VLAN 200: 10.0.2.1/24
- **Features**: OSPF, NAT (overload on Gi0/0/0), SSH, SNMP, TACACS, NTP, Logging
- **Default Route**: 192.168.10.1 via Gi0/0/0
- **Config File**: `paste_configs/EdgeLabRouter-1_paste_ready.txt`

### EdgeLabRouter-2
- **Management IP**: 10.0.0.2
- **Serial Number**: FLM2006W08G
- **Purpose**: Downstream router handling 10.0.3.x and 10.0.4.x networks
- **Networks**:
  - Uplink: 10.0.0.2/24 (Gi0/0/1) - connects to EdgeLabRouter-1
  - VLAN 1: 10.0.3.1/24
  - VLAN 300: 10.0.4.1/24
- **Features**: OSPF, NAT (overload on Gi0/0/1), SSH, SNMP, TACACS, NTP, Logging
- **Default Route**: 10.0.0.1 (routes through EdgeLabRouter-1)
- **Config File**: `paste_configs/EdgeLabRouter-2_paste_ready.txt`

### ZTP-Router
- **Management IP**: 10.0.1.2
- **Serial Number**: FLM2120W1Y6
- **Purpose**: Zero Touch Provisioning router for lab automation
- **Networks**:
  - ZTP Network: 10.0.1.2/24 (Gi0/0/1 and VLAN 1)
  - DHCP Pool: 10.0.1.11 - 10.0.1.254
- **Features**:
  - DHCP server for ZTP clients
  - HTTPS enabled for provisioning
  - OSPF, SSH, SNMP, TACACS, NTP, Logging
  - 4 switch ports (Gi0/1/0-3) configured for ZTP clients
- **Config Files**:
  - Paste ready: `paste_configs/ZTP-Router_paste_ready.txt`
  - Rename script: `ZTP-Router_rename_config.txt`

---

## Network Topology

```
Internet
    |
    | 192.168.10.1 (Gateway)
    |
[EdgeLabRouter-1] 192.168.10.55 (WAN)
    |
    | 10.0.0.1 (LAN)
    |
    +-- [EdgeLabRouter-2] 10.0.0.2
    |       |
    |       +-- VLAN 1: 10.0.3.0/24
    |       +-- VLAN 300: 10.0.4.0/24
    |
    +-- VLAN 1: 10.0.1.0/24
    +-- VLAN 200: 10.0.2.0/24

[ZTP-Router] 10.0.1.2
    |
    +-- ZTP Network: 10.0.1.0/24
    +-- DHCP: 10.0.1.11 - 254
    +-- 4 ZTP Client Ports
```

---

## Configuration Files

### Directory Structure
```
ansible-files/
├── hosts                          # Ansible inventory
├── golden_configs/                # Reference configurations (show run format)
│   ├── EdgeLabRouter-1_golden_config.txt
│   ├── EdgeLabRouter-2_golden_config.txt
│   └── ZTP-Router_golden_config.txt
├── paste_configs/                 # Console paste-ready configurations
│   ├── EdgeLabRouter-1_paste_ready.txt
│   ├── EdgeLabRouter-2_paste_ready.txt
│   └── ZTP-Router_paste_ready.txt
├── ZTP-Router_rename_config.txt   # Commands to rename router to ZTP-Router and change IP to 10.0.1.2
└── ios_upgrade_edgelabrouter1.yml # Ansible playbook for IOS upgrade
```

### Usage

**To apply a configuration:**
1. Connect via console: `screen /dev/tty.usbserial-XXXXX 9600`
2. Copy the entire contents of the paste-ready file
3. Paste into the console (Command+V in screen)
4. Configuration will be applied and saved automatically

**To rename router to ZTP-Router and change IP to 10.0.1.2:**
1. Connect to router via console
2. Paste contents of `ZTP-Router_rename_config.txt`
3. Verify with: `show running-config | include hostname` and `show ip interface brief`

---

## Common Settings (All Routers)

- **Timezone**: EST/EDT (UTC-5, DST enabled)
- **Domain**: mdblab.com
- **Enable Password**: c1sc0
- **Username**: admin / Password: c1sc0
- **SSH**: Version 2, 2048-bit RSA keys
- **Logging Servers**: 10.0.0.8, 10.0.0.10
- **SNMP Hosts**: 10.0.0.8, 10.0.0.10
- **TACACS Servers**: 10.0.0.100, 10.0.0.101
- **NTP Servers**: pool.ntp.org, time.cloudflare.com, time.nist.gov
- **OSPF**: Area 0, reference-bandwidth 1000
- **Console**: 30 min timeout, logging synchronous
- **VTY**: 15 min timeout, SSH only

---

## Interface Summary

### EdgeLabRouter-1
| Interface | Description | IP Address | Status |
|-----------|-------------|------------|--------|
| Gi0/0/0 | WAN Interface | 192.168.10.55/24 | UP |
| Gi0/0/1 | Connection to EdgeLabRouter-2 | 10.0.0.1/24 | UP |
| Gi0/0/2 | Reserved | - | DOWN |
| Gi0/1/0 | Switch_B_3850 | Switchport | UP |
| Gi0/1/1 | VLAN 200 device | Switchport | UP |
| Gi0/1/2-7 | Unused | Switchport | DOWN |
| VLAN 1 | Switch_B_3850 | 10.0.1.1/24 | UP |
| VLAN 200 | Additional Segment | 10.0.2.1/24 | UP |

### EdgeLabRouter-2
| Interface | Description | IP Address | Status |
|-----------|-------------|------------|--------|
| Gi0/0/0 | WAN (Reserved) | - | DOWN |
| Gi0/0/1 | Connection to EdgeLabRouter-1 | 10.0.0.2/24 | UP |
| Gi0/0/2 | Reserved | - | DOWN |
| Gi0/1/0 | Switch_C_3850 | Switchport | UP |
| Gi0/1/1 | VLAN 300 device | Switchport | UP |
| Gi0/1/2-7 | Unused | Switchport | DOWN |
| VLAN 1 | Switch_C_3850 | 10.0.3.1/24 | UP |
| VLAN 300 | Additional Segment | 10.0.4.1/24 | UP |

### ZTP-Router
| Interface | Description | IP Address | Status |
|-----------|-------------|------------|--------|
| Gi0/0/0 | WAN (Optional) | - | DOWN |
| Gi0/0/1 | ZTP Provisioning Network | 10.0.1.2/24 | UP |
| Gi0/0/2 | Reserved | - | DOWN |
| Gi0/1/0 | ZTP Client Port 1 | Switchport | UP |
| Gi0/1/1 | ZTP Client Port 2 | Switchport | UP |
| Gi0/1/2 | ZTP Client Port 3 | Switchport | UP |
| Gi0/1/3 | ZTP Client Port 4 | Switchport | UP |
| Gi0/1/4-7 | Unused | Switchport | DOWN |
| VLAN 1 | ZTP Management | 10.0.1.2/24 | UP |

---

## SSH Access

### EdgeLabRouter-1
```bash
ssh admin@192.168.10.55
```

### EdgeLabRouter-2
```bash
ssh admin@10.0.0.2
```

### ZTP-Router
```bash
ssh admin@10.0.1.2
```

**Password**: c1sc0

---

## Upgrade History

### 2026-01-13
- **EdgeLabRouter-1**: Upgraded from 03.16.04b → 17.12.06
  - Copied IOS from USB to bootflash
  - Deleted old IOS image
  - Applied full configuration
  - SSH enabled and tested ✅

- **EdgeLabRouter-2**: Upgraded from 03.15.03 → 17.12.06
  - Recovered from boot loop (flash: vs bootflash: issue)
  - Copied IOS from USB to bootflash
  - Deleted old IOS image
  - Applied full configuration
  - SSH enabled and tested ✅

---

## Maintenance Tasks

### Backup Configuration
```bash
# Via Ansible
ansible-playbook backup_configs.yml

# Via SSH/SCP
scp admin@192.168.10.55:system:running-config EdgeLabRouter-1-backup.cfg
```

### Verify Configuration
```bash
show running-config
show ip interface brief
show ip route
show ip ospf neighbor
show ip nat translations
show version
```

### Monitor Router
```bash
show processes cpu
show memory
show interface summary
show logging
```

---

## Troubleshooting

### SSH Issues
1. Verify SSH keys exist: `show crypto key mypubkey rsa`
2. Check SSH status: `show ip ssh`
3. Verify VTY lines: `show line vty 0 15`
4. Regenerate keys if needed: `crypto key generate rsa modulus 2048`

### OSPF Issues
1. Check OSPF neighbors: `show ip ospf neighbor`
2. Verify OSPF config: `show ip ospf`
3. Check routes: `show ip route ospf`

### NAT Issues
1. Check NAT translations: `show ip nat translations`
2. Verify NAT config: `show ip nat statistics`
3. Check ACL: `show ip access-lists NAT-TRAFFIC`

---

**Document Created**: 2026-01-13
**Last Updated**: 2026-01-13
**Branch**: claude/add-isr-routers-gbFxZ
