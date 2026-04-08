[README.md](https://github.com/user-attachments/files/26556222/README.md)
# Enterprise Active Directory Lab — RemiTech IT Environment

> **Live Azure Lab | Windows Server 2022 | Windows 11 | PowerShell Automation | ServiceNow ITSM**

A fully functional enterprise IT environment I built from scratch in Microsoft Azure. I configured Active Directory Domain Services, Group Policy, a print server, SMB file shares, and a complete ITSM workflow using ServiceNow. This lab simulates real-world helpdesk and service desk scenarios environment.

---

## Environment Overview

| Component | Details |
|-----------|---------|
| **Domain** | remitech.local |
| **DC01** | Windows Server 2022 Datacenter — 10.0.0.4 — Standard D2s v3 (2 vCPUs, 8 GB) |
| **CLIENT01** | Windows 11 Pro — 10.0.0.5 — Standard D2s v3 (2 vCPUs, 8 GB) |
| **Resource Group** | RemiTech-RG |
| **VNet** | DC01-vnet / default — 10.0.0.0/24 |
| **Region** | East US — Zone 1 |

---

## Table of Contents

1. [Azure Infrastructure Deployment](#1-azure-infrastructure-deployment)
2. [Active Directory — Users, OUs, and Groups](#2-active-directory--users-ous-and-groups)
3. [Group Policy — Password, Lockout, and Security Baseline](#3-group-policy--password-lockout-and-security-baseline)
4. [Print Server and Printer Deployment](#4-print-server-and-printer-deployment)
5. [SMB File Share with Group Permissions](#5-smb-file-share-with-group-permissions)
6. [Account Lockout Simulation and Recovery](#6-account-lockout-simulation-and-recovery)
7. [TCP/IP Troubleshooting and Network Diagnostics](#7-tcpip-troubleshooting-and-network-diagnostics)
8. [Wireshark Protocol Analysis](#8-wireshark-protocol-analysis)
9. [RDP Failure Simulation, Diagnosis, and Fix](#9-rdp-failure-simulation-diagnosis-and-fix)
10. [ServiceNow Incident Lifecycle](#10-servicenow-incident-lifecycle)
11. [PowerShell Scripts](#11-powershell-scripts)
12. [Lessons Learned](#12-lessons-learned)

---

## 1. Azure Infrastructure Deployment

I deployed two virtual machines in Azure within the same virtual network and subnet to simulate a domain environment. I provisioned DC01 (Windows Server 2022 Datacenter) with a static private IP of 10.0.0.4 and CLIENT01 (Windows 11 Pro) at 10.0.0.5. I then installed Active Directory Domain Services on DC01 and promoted it to a Domain Controller for the new forest remitech.local.

![DC01 Azure Overview](screenshots/25-azure-dc01-overview-essentials.png)

![DC01 Networking](screenshots/26-azure-dc01-properties-networking.png)

![DC01 Size and Image](screenshots/27-azure-dc01-properties-size-image.png)

![CLIENT01 Azure Overview](screenshots/28-azure-client01-overview-essentials.png)

![CLIENT01 Networking](screenshots/29-azure-client01-properties-networking.png)

![CLIENT01 Size and Image](screenshots/30-azure-client01-properties-size-image.png)

---

## 2. Active Directory — Users, OUs, and Groups

I created a hierarchical OU structure inside remitech.local before running any provisioning scripts. I then ran New-ADUser-Bulk.ps1 to create 10 users across 5 departments: HR, Finance, IT, Sales, and Operations.

I built security groups following the AGDLP model — Accounts into Global groups, nested into Domain Local groups, with permissions assigned at the group level.

![PowerShell Bulk Users Created](screenshots/01-powershell-bulk-users-created.png)

![ADUC Users in Department OUs](screenshots/02b-aduc-users-in-department-ous.png)

![Security Groups with Members](screenshots/03-aduc-security-groups-members.png)

---

## 3. Group Policy — Password, Lockout, and Security Baseline

I configured a domain-wide GPO enforcing password complexity and account lockout thresholds. I also created REMITECH-Security-Baseline targeting workstations to enforce screen lock and USB blocking. I verified application with gpresult /r after running gpupdate /force.

![GPO Password and Lockout Policy](screenshots/04-gpo-password-lockout-policy.png)

![Security Baseline Linked](screenshots/05-gpo-security-baseline-linked.png)

![Security Baseline gpresult](screenshots/06-gpo-security-baseline-gpresult.png)

---

## 4. Print Server and Printer Deployment

I installed the Print and Document Services role on DC01 and confirmed the Print Spooler was running with drivers loaded. I configured the shared printer Office-Network-Printer through Print Management and deployed it to CLIENT01 via Group Policy.

![Print Spooler Running](screenshots/02a-print-spooler-running-drivers.png)

![Print Management Console](screenshots/07-printer-print-management-console.png)

![Network Printer Installation Complete](screenshots/07c-network-printer-installation-complete.png)

![Print Spooler DC01](screenshots/07d-print-spooler-running-drivers.png)

![CLIENT01 Printer Deployed via GPO](screenshots/7b-client01-printer-deployed-settings.png)

---

## 5. SMB File Share with Group Permissions

I created an SMB file share on DC01 and configured NTFS and share-level permissions tied to department security groups. I verified access from CLIENT01 using File Explorer with a domain user account.

![SMB Share Created](screenshots/08-smb-share-created.png)

![CLIENT01 SMB Share in File Explorer](screenshots/09-smb-share-client01-file-explorer.png)

---

## 6. Account Lockout Simulation and Recovery

I triggered a lockout on user jokafor by entering incorrect passwords beyond the threshold. I investigated using Event Viewer on DC01, locating Event ID 4740 and Event ID 4625 to confirm the source. I then unlocked the account in ADUC.

![jokafor Account Locked Out](screenshots/10-jokafor-account-lockout.png)

![jokafor Account Unlocked](screenshots/11-jokafor-account-unlocked.png)

![Event Viewer Event ID 4740](screenshots/12-eventviewer-4740-jokafor-lockout.png)

---

## 7. TCP/IP Troubleshooting and Network Diagnostics

I ran a full suite of TCP/IP diagnostics from CLIENT01 to validate network health and domain connectivity.

| Command | Purpose |
|---------|---------|
| `ipconfig /all` | Verified IP, subnet, gateway, and DNS pointing to DC01 |
| `ping 10.0.0.4` | Confirmed ICMP reachability to DC01 by IP |
| `ping dc01.remitech.local` | Confirmed DNS resolution and ICMP by FQDN |
| `nslookup remitech.local` | Verified DC01 is authoritative DNS |
| `netstat` | Inspected active TCP connections to DC01 |
| `ipconfig /flushdns` | Cleared DNS cache and forced fresh lookups |

![ipconfig all](screenshots/13-client01-ipconfig-all.png)

![Ping DC01 by IP](screenshots/14-client01-ping-dc01-ip.png)

![Ping DC01 by FQDN](screenshots/15-client01-ping-dc01-fqdn.png)

![nslookup remitech.local](screenshots/16-client01-nslookup-remitech.png)

![netstat DC01 connections](screenshots/17-client01-netstat-dc01-connections.png)

![flushdns](screenshots/18-client01-flushdns.png)

---

## 8. Wireshark Protocol Analysis

I ran Wireshark as Administrator on CLIENT01 and captured DNS (port 53), SMB2 (port 445), and Kerberos (port 88) traffic to analyze core Active Directory protocols in action.

![Wireshark DNS Capture](screenshots/19-wireshark-dns-capture.png)

![Wireshark SMB2 Capture](screenshots/20-wireshark-smb2-capture.png)

![Wireshark Kerberos Capture](screenshots/21-wireshark-kerberos-capture.png)

---

## 9. RDP Failure Simulation, Diagnosis, and Fix

I blocked RDP port 3389 on DC01's Windows Firewall to simulate a misconfigured rule. I diagnosed the failure from CLIENT01, then used Azure Run Command to restore the firewall rule remotely without console access. I confirmed RDP reconnected successfully after the fix.

![RDP Connection Failed](screenshots/22-rdp-connection-failed.png)

![RDP Port Blocked Diagnosis](screenshots/23-rdp-port-blocked-diagnosis.png)

![RDP Port Restored Success](screenshots/24-rdp-port-restored-success.png)

---

## 10. ServiceNow Incident Lifecycle

I documented the jokafor account lockout as a complete ITSM ticket in ServiceNow — creating the incident, adding work notes with investigation steps, and resolving it after confirming the user could log in.

![ServiceNow Incident Created](screenshots/31-servicenow-incident-created.png)

![ServiceNow Work Notes](screenshots/32a-servicenow-incident-work-notes.png)

![ServiceNow Incident Resolved](screenshots/32b-servicenow-incident-resolved.png)

---

## 11. PowerShell Scripts

All scripts are in the [/scripts](scripts/) folder.

| Script | Description |
|--------|-------------|
| `New-ADUser-Bulk.ps1` | Creates 10 AD users across 5 departmental OUs |
| `Reset-ADPassword.ps1` | Resets a user password and forces change at next logon |
| `Disable-StaleAccounts.ps1` | Disables accounts inactive for 90+ days |
| `Fix-PrintSpooler.ps1` | Stops, clears queue, and restarts the Print Spooler |

---

## 12. Lessons Learned

1. **Static IP on the DC is non-negotiable.** I assigned 10.0.0.4 statically before domain promotion — a dynamic IP breaks DNS for every domain-joined machine the moment it changes.

2. **DNS must point to DC01 before the domain join.** I set CLIENT01's DNS to 10.0.0.4 first — without it the join wizard cannot resolve remitech.local and fails immediately.

3. **GPO requires gpupdate /force to apply immediately.** I ran this after every policy change to verify results in real time rather than waiting for the background refresh cycle.

4. **OUs must exist before running user creation scripts.** The bulk user script targets OUs by distinguished name — a missing OU throws an error for every user in that department.

5. **Azure NSG rules are separate from Windows Firewall.** Both must allow a port for traffic to flow — I confirmed this during the RDP simulation where blocking at the firewall level was enough to lock out access even with the NSG port open.

6. **Printer sharing has limitations in Azure with virtual drivers.** Azure VMs have no physical hardware so some driver installations behave differently — I used Microsoft's built-in drivers to work around this.

7. **netstat only shows active connections at the moment the command runs.** It is a point-in-time snapshot — I ran it while a connection was active to capture meaningful output.

8. **Wireshark must run as Administrator.** Without elevation it cannot bind to the network adapter and captures nothing.

9. **RDP lockout recovery via Azure Run Command.** When I lost RDP access I used the Azure portal Run Command feature to execute PowerShell directly on the VM — no console access needed.

10. **gpresult /r shows N/A when run as a local account.** Domain policy only appears in the output when run as a domain user — running as local admin produces misleading N/A entries.

---

## Repository Structure

```
enterprise-active-directory-lab/
├── README.md
├── screenshots/          # 32 labeled screenshots covering all lab scenarios
└── scripts/
    ├── New-ADUser-Bulk.ps1
    ├── Reset-ADPassword.ps1
    ├── Disable-StaleAccounts.ps1
    └── Fix-PrintSpooler.ps1
```

---

*Built by [@aremi5](https://github.com/aremi5) — RemiTech IT Lab*
