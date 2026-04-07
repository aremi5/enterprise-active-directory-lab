Enterprise Active Directory Lab — RemiTech IT Solutions
Built on Microsoft Azure | Windows Server 2022 | Windows 11 Pro
---
Overview
I designed and deployed a fully functional enterprise Active Directory environment in Microsoft Azure to simulate real-world IT operations. This lab covers the complete lifecycle of domain administration — from infrastructure provisioning and identity management to security hardening, network diagnostics, protocol analysis, and ITSM ticketing via ServiceNow.
Every scenario in this lab was executed hands-on. I configured the domain controller, joined a client machine, wrote PowerShell automation scripts, captured live network traffic with Wireshark, diagnosed and resolved a simulated RDP outage, and documented the incident end-to-end in ServiceNow.
---
Environment
Component	Details
Domain	remitech.local
DC01	Windows Server 2022 Datacenter — 10.0.0.4
CLIENT01	Windows 11 Pro — 10.0.0.5
Azure Region	East US — Zone 1
VM Size	Standard D2s v3 (2 vCPUs, 8 GB RAM)
Resource Group	RemiTech-RG
VNet / Subnet	DC01-vnet / default — 10.0.0.0/24
---
Table of Contents
Azure Infrastructure Deployment
AD DS Installation and Domain Promotion
OU Structure and Bulk User Provisioning
Security Groups and RBAC (AGDLP)
Group Policy — Password and Lockout Policy
Group Policy — Security Baseline
Print Server and Network Printer Deployment
SMB File Share with Group Permissions
Domain Join — CLIENT01
Account Lockout Simulation and Recovery
TCP/IP Network Diagnostics
Wireshark Protocol Analysis
RDP Failure Simulation and Resolution
ServiceNow Incident Lifecycle
PowerShell Automation Scripts
Azure VM Overview
Lessons Learned
---
1. Azure Infrastructure Deployment
I provisioned both virtual machines in Microsoft Azure under a shared resource group (RemiTech-RG) and placed them on the same virtual network (DC01-vnet, 10.0.0.0/24). I assigned DC01 a static private IP of 10.0.0.4 to ensure DNS stability across the domain, and configured CLIENT01 at 10.0.0.5. Both VMs run on Standard D2s v3 instances in East US Zone 1.
I configured Azure Network Security Group (NSG) rules to control inbound traffic — keeping the environment secure while allowing the ports required for domain operations, RDP, and SMB.
---
2. AD DS Installation and Domain Promotion
I installed the Active Directory Domain Services role on DC01 using Server Manager and promoted it to a domain controller for the new forest remitech.local. During promotion, I configured the DNS Server role on DC01 and set the forest and domain functional levels to Windows Server 2016.
After promotion, I verified replication health and confirmed that the default AD partitions (Domain, Schema, Configuration) were created successfully.
---
3. OU Structure and Bulk User Provisioning
I designed a department-based OU structure in Active Directory Users and Computers (ADUC) before running any provisioning scripts — a deliberate sequencing decision to avoid script failures caused by missing target containers.
I created OUs for five departments: IT, HR, Finance, Marketing, and Operations. I then ran New-ADUser-Bulk.ps1 to provision 10 user accounts distributed across these departments.
![PowerShell bulk user creation output](screenshots/01-powershell-bulk-users-created.png)
PowerShell script output confirming 10 user accounts created across 5 departments.
![Users visible in ADUC department OUs](screenshots/02-aduc-users-in-department-ous.png)
ADUC confirming users are correctly placed in their department OUs.
---
4. Security Groups and RBAC (AGDLP)
I implemented role-based access control using the AGDLP (Account → Global → Domain Local → Permission) model. I created security groups aligned to each department and assigned user accounts as members.
This structure allows permissions to be managed at the group level rather than per-user, which scales cleanly as the organization grows.
![Security groups and membership in ADUC](screenshots/03-aduc-security-groups-members.png)
ADUC showing security groups with department members assigned.
---
5. Group Policy — Password and Lockout Policy
I created and linked a GPO to enforce the domain password and account lockout policy. I configured the following settings via Group Policy Management:
Minimum password length: 12 characters
Password complexity: Enabled
Maximum password age: 90 days
Account lockout threshold: 5 invalid attempts
Lockout duration: 30 minutes
Observation window: 30 minutes
I ran `gpupdate /force` on CLIENT01 to apply the policy immediately and verified the result.
![GPO password and lockout policy settings](screenshots/04-gpo-password-lockout-policy.png)
Group Policy Management Editor showing the configured password and lockout policy.
---
6. Group Policy — Security Baseline
I created a second GPO named REMITECH-Security-Baseline and linked it to the domain. This policy enforces two key security controls:
Screen lock: Workstation locks after 10 minutes of inactivity
USB storage block: Removable storage device installation is denied via registry policy
I ran `gpresult /r` on CLIENT01 to confirm the GPO was applied. I noted that `gpresult /r` returns N/A when executed under a local (non-domain) account — the command must be run as a domain user to display applied GPOs correctly.
![Security baseline GPO linked in GPMC](screenshots/05-gpo-security-baseline-linked.png)
GPMC showing the REMITECH-Security-Baseline GPO linked to the domain.
![gpresult output confirming policy applied](screenshots/06-gpo-security-baseline-gpresult.png)
gpresult /r on CLIENT01 confirming the security baseline policy was applied.
---
7. Print Server and Network Printer Deployment
I installed the Print and Document Services role on DC01 and configured it as a print server. I added the printer driver and created the shared printer Office-Network-Printer through Print Management.
I then deployed the printer to CLIENT01 via Group Policy, pushing the connection through the user configuration so it appeared automatically upon login. I verified the full deployment from both the server and client sides.
![Print and Document Services role installed](screenshots/07-print-server-role-installed.png)
Server Manager confirming the Print and Document Services role is installed on DC01.
![Print Spooler service running with drivers loaded](screenshots/07b-print-spooler-running-drivers.png)
Print Spooler service confirmed running and printer drivers visible in Print Management.
![Printer installation complete on DC01](screenshots/09-network-printer-installation-complete.png)
Network printer successfully created and shared on the print server.
![Printer wizard settings](screenshots/09b-network-printer-wizard-settings.png)
Printer wizard showing the configured share name and port settings.
![Office-Network-Printer confirmed in Print Management](screenshots/10-office-network-printer-confirmed.png)
Print Management confirming Office-Network-Printer is shared and available.
![Printer deployed to CLIENT01 via GPO](screenshots/11-client01-printer-deployed-settings.png)
CLIENT01 showing the printer successfully deployed and visible in Devices and Printers.
---
8. SMB File Share with Group Permissions
I created an SMB file share on DC01 and configured NTFS and share-level permissions aligned to the department security groups I created in Section 4. Only members of the appropriate security group can access the share — all others are denied.
I validated access from CLIENT01 by browsing to the share via File Explorer using a domain user account.
![SMB share created with permissions on DC01](screenshots/08-smb-share-created-permissions.png)
Share permissions configured on DC01 restricting access to the correct security group.
![SMB share visible from CLIENT01 in File Explorer](screenshots/13-smb-share-client01-file-explorer.png)
CLIENT01 File Explorer showing successful access to the SMB share using a domain account.
---
9. Domain Join — CLIENT01
I configured CLIENT01's DNS to point to DC01 (10.0.0.4) before initiating the domain join — a critical prerequisite. Without DNS resolving remitech.local, the join operation fails.
I joined CLIENT01 to the remitech.local domain through System Properties and confirmed the machine appeared in the domain computer objects in ADUC.
---
10. Account Lockout Simulation and Recovery
I simulated an account lockout on the domain user jokafor by intentionally entering the wrong password five consecutive times from CLIENT01, triggering the lockout policy configured in Section 5.
I then switched to DC01, located the locked account in ADUC, unlocked it, and verified the user could log in again. I also used Reset-ADPassword.ps1 to perform a scripted password reset.
To investigate the lockout event, I opened Event Viewer on DC01 and filtered Security logs for Event ID 4740 (account locked out) and Event ID 4625 (failed logon), confirming the source machine and timestamp.
![jokafor account locked out in ADUC](screenshots/14-jokafor-account-lockout.png)
ADUC showing jokafor's account in a locked-out state after failed login attempts.
![jokafor account unlocked in ADUC](screenshots/15-jokafor-account-unlocked.png)
ADUC confirming the account has been unlocked and is active.
![Event Viewer Event ID 4740 for jokafor lockout](screenshots/16-eventviewer-4740-jokafor-lockout.png)
Security event log on DC01 showing Event ID 4740 — account lockout for jokafor, including source machine.
---
11. TCP/IP Network Diagnostics
I ran a full suite of TCP/IP diagnostic commands from CLIENT01 to verify domain connectivity, DNS resolution, and active network connections.
Command	Purpose
`ipconfig /all`	Confirmed IP, subnet, gateway, and DNS server assignments
`ping 10.0.0.4`	Verified ICMP connectivity to DC01 by IP
`ping DC01.remitech.local`	Verified FQDN resolution and ICMP connectivity
`nslookup remitech.local`	Confirmed DNS resolving domain to DC01
`netstat -an`	Identified active TCP connections to domain services
`ipconfig /flushdns`	Cleared the DNS resolver cache to force fresh lookups
![ipconfig /all on CLIENT01](screenshots/17-client01-ipconfig-all.png)
ipconfig /all confirming IP configuration including DNS pointing to DC01.
![Ping to DC01 IP](screenshots/18-client01-ping-dc01-ip.png)
Successful ping to DC01 by IP address.
![Ping to DC01 FQDN](screenshots/19-client01-ping-dc01-fqdn.png)
Successful ping to DC01.remitech.local confirming DNS resolution.
![nslookup for remitech.local](screenshots/20-client01-nslookup-remitech.png)
nslookup confirming DC01 is authoritative DNS for remitech.local.
![netstat output showing DC01 connections](screenshots/21-client01-netstat-dc01-connections.png)
netstat showing active TCP connections from CLIENT01 to DC01 on domain service ports.
![ipconfig /flushdns](screenshots/22-client01-flushdns.png)
DNS resolver cache successfully flushed on CLIENT01.
---
12. Wireshark Protocol Analysis
I captured and analyzed live network traffic using Wireshark on CLIENT01 (run as Administrator — required for raw packet capture). I isolated and examined three core protocols used in the Active Directory environment.
DNS — I captured DNS query and response traffic to observe how CLIENT01 resolves remitech.local to DC01's IP address.
SMB2 — I captured SMB2 session traffic to observe the negotiation, authentication, and file access sequence when connecting to the domain share.
Kerberos — I captured Kerberos AS-REQ / AS-REP / TGS-REQ / TGS-REP exchanges to observe the ticket-granting process used for domain authentication.
![Wireshark DNS capture](screenshots/23-wireshark-dns-capture.png)
Wireshark capture showing DNS query from CLIENT01 resolving remitech.local.
![Wireshark SMB2 capture](screenshots/24-wireshark-smb2-capture.png)
Wireshark capture showing SMB2 session negotiation and authentication to the domain share.
![Wireshark Kerberos capture](screenshots/25-wireshark-kerberos-capture.png)
Wireshark capture showing Kerberos ticket exchange (AS-REQ/AS-REP) for domain authentication.
---
13. RDP Failure Simulation and Resolution
I simulated a locked-out RDP scenario by blocking TCP port 3389 on the Windows Firewall of DC01. This caused all remote desktop connection attempts to fail — mimicking a misconfigured firewall rule that would be escalated as a P2 incident in a production environment.
I diagnosed the failure from CLIENT01, confirmed the port was blocked, and then used Azure Run Command to restore the firewall rule remotely without requiring console access. This is the recovery method used in production Azure environments when RDP is the only remote access path and it has been inadvertently blocked.
After restoring the rule, I verified that RDP reconnected successfully.
![RDP connection failed](screenshots/26-rdp-connection-failed.png)
RDP connection attempt from CLIENT01 to DC01 failing — connection refused.
![Port blocked diagnosis](screenshots/27-rdp-port-blocked-diagnosis.png)
Diagnosis confirming TCP 3389 is blocked at the Windows Firewall level on DC01.
![RDP restored and working](screenshots/28-rdp-port-restored-success.png)
RDP session successfully established after restoring the firewall rule via Azure Run Command.
---
14. ServiceNow Incident Lifecycle
I documented the RDP outage from Section 13 as a formal incident in ServiceNow, walking through the complete ITSM lifecycle:
Incident Created — I logged the ticket with impact, urgency, affected user, and a detailed description of the RDP failure.
Work Notes Added — I documented the investigation steps: connection test, port diagnosis, root cause identification (firewall rule), and remediation via Azure Run Command.
Incident Resolved — I marked the ticket resolved with resolution notes confirming the service was restored and RDP connectivity verified.
![ServiceNow incident created](screenshots/31-servicenow-incident-created.png)
ServiceNow incident ticket created for the RDP outage with priority and details populated.
![ServiceNow work notes documenting investigation](screenshots/32a-servicenow-incident-work-notes.png)
Work notes showing the investigation steps, root cause, and remediation actions taken.
![ServiceNow incident resolved](screenshots/32b-servicenow-incident-resolved.png)
Incident marked resolved with resolution summary confirming RDP service restored.
---
15. PowerShell Automation Scripts
I wrote four PowerShell scripts to automate common administrative tasks in this environment. All scripts are located in the `/scripts` folder.
New-ADUser-Bulk.ps1
Reads a structured input and provisions multiple Active Directory user accounts in a single execution. Places users in the correct department OUs and sets initial passwords. Used in Section 3 to provision 10 users across 5 departments.
Reset-ADPassword.ps1
Resets a domain user's password and optionally forces a password change at next logon. Used during the account lockout recovery in Section 10.
Disable-StaleAccounts.ps1
Queries Active Directory for user accounts that have not logged in within a configurable number of days and disables them. Supports organizational security hygiene and access review workflows.
Fix-PrintSpooler.ps1
Stops the Print Spooler service, clears the print queue from the spool directory, and restarts the service. Used to recover from print job stuck states on DC01.
---
16. Azure VM Overview
I captured the Azure portal overview for both virtual machines to document the infrastructure configuration — VM size, region, private IP, OS disk, and NSG associations.
![Azure DC01 VM overview](screenshots/29-azure-dc01-vm-overview.png)
Azure portal overview of DC01 — Windows Server 2022, Standard D2s v3, East US Zone 1.
![Azure CLIENT01 VM overview](screenshots/30-azure-client01-vm-overview.png)
Azure portal overview of CLIENT01 — Windows 11 Pro, Standard D2s v3, East US Zone 1.
---
17. Lessons Learned
These are the ten most meaningful takeaways from building this lab — things I verified through direct failure and resolution, not just documentation.
Static IP on DC is non-negotiable. A dynamic IP on the domain controller breaks DNS for every domain-joined machine the moment the IP changes. I assigned 10.0.0.4 as a static private IP before domain promotion and never touched it again.
DNS must point to DC01 before domain join. CLIENT01's DNS had to be set to 10.0.0.4 before the domain join would succeed. Without it, the join wizard cannot resolve remitech.local and fails immediately.
GPO requires `gpupdate /force` to apply immediately. Group Policy applies on a background refresh cycle. During testing, I ran `gpupdate /force` on CLIENT01 to verify policy application in real time rather than waiting for the next cycle.
OUs must exist before running user creation scripts. Running New-ADUser-Bulk.ps1 against an OU that doesn't exist yet throws an error for every user in that department. I created all OUs first and validated them before executing the script.
Azure NSG rules are separate from Windows Firewall. Azure's Network Security Groups operate at the virtual NIC / subnet level. Windows Firewall operates at the OS level. Both must allow a port for traffic to flow. I learned this clearly during the RDP simulation — blocking at the Windows Firewall level was enough to lock out access even with the NSG port open.
Printer sharing has limitations in Azure with virtual drivers. Virtual machines in Azure don't have physical hardware, which can create friction when installing printer drivers that expect hardware detection. I worked through this using compatible generic drivers to complete the print server deployment.
`netstat` only shows connections active at the time of the command. It is a point-in-time snapshot, not a live feed. For ongoing connection monitoring, a repeated execution or a dedicated tool is required.
Wireshark must run as Administrator. Without elevated privileges, Wireshark cannot access the network adapter at the packet level and will show no capture interfaces. Every capture in this lab was run as Administrator.
RDP lockout recovery via Azure Run Command. When I blocked port 3389 on the Windows Firewall, I had no way to reconnect through RDP. Azure Run Command executes scripts directly on the VM through the Azure agent, bypassing the network — the correct recovery path in production when remote access is severed.
`gpresult /r` shows N/A when run as a local account. I initially ran `gpresult /r` on CLIENT01 while logged in as a local administrator and saw N/A for applied GPOs. The command must be run under a domain user context to display domain-applied policies correctly.
---
Repository Structure
```
enterprise-active-directory-lab/
├── README.md
├── screenshots/
│   ├── 01-powershell-bulk-users-created.png
│   ├── 02-aduc-users-in-department-ous.png
│   ├── 03-aduc-security-groups-members.png
│   ├── 04-gpo-password-lockout-policy.png
│   ├── 05-gpo-security-baseline-linked.png
│   ├── 06-gpo-security-baseline-gpresult.png
│   ├── 07-print-server-role-installed.png
│   ├── 07b-print-spooler-running-drivers.png
│   ├── 08-smb-share-created-permissions.png
│   ├── 09-network-printer-installation-complete.png
│   ├── 09b-network-printer-wizard-settings.png
│   ├── 10-office-network-printer-confirmed.png
│   ├── 11-client01-printer-deployed-settings.png
│   ├── 12-smb-share-created.png
│   ├── 13-smb-share-client01-file-explorer.png
│   ├── 14-jokafor-account-lockout.png
│   ├── 15-jokafor-account-unlocked.png
│   ├── 16-eventviewer-4740-jokafor-lockout.png
│   ├── 17-client01-ipconfig-all.png
│   ├── 18-client01-ping-dc01-ip.png
│   ├── 19-client01-ping-dc01-fqdn.png
│   ├── 20-client01-nslookup-remitech.png
│   ├── 21-client01-netstat-dc01-connections.png
│   ├── 22-client01-flushdns.png
│   ├── 23-wireshark-dns-capture.png
│   ├── 24-wireshark-smb2-capture.png
│   ├── 25-wireshark-kerberos-capture.png
│   ├── 26-rdp-connection-failed.png
│   ├── 27-rdp-port-blocked-diagnosis.png
│   ├── 28-rdp-port-restored-success.png
│   ├── 29-azure-dc01-vm-overview.png
│   ├── 30-azure-client01-vm-overview.png
│   ├── 31-servicenow-incident-created.png
│   ├── 32a-servicenow-incident-work-notes.png
│   └── 32b-servicenow-incident-resolved.png
└── scripts/
    ├── New-ADUser-Bulk.ps1
    ├── Reset-ADPassword.ps1
    ├── Disable-StaleAccounts.ps1
    └── Fix-PrintSpooler.ps1
```
---
Built by Aremi | GitHub
