# Azure Internal Load Balancer Lab (Terraform)

This lab demonstrates how to deploy an **Azure Internal Load Balancer** using **Terraform**, fronting multiple **Windows Server IIS backend VMs** inside a virtual network.

The goal of this project is to show:
- Correct Azure networking fundamentals
- Internal (private) load balancing
- Health probes and load-balancing rules
- Infrastructure as Code best practices with Terraform
- A clean, incremental (“baby steps”) deployment approach

---

## Architecture Overview

**High-level design:**

- Resource Group  
- Virtual Network  
  - Frontend subnet (Internal Load Balancer)  
  - Backend subnet (VMs)  
- Azure Internal Load Balancer (Standard SKU)  
  - Private frontend IP  
  - Backend address pool  
  - Health probe (HTTP)  
  - Load-balancing rule (TCP 80)  
- Availability Set  
- 3 × Windows Server 2019 Datacenter VMs  
  - IIS installed  
  - Each VM serves a simple HTML page identifying itself  
- Azure Bastion for secure access (no public IPs on VMs)

**Traffic flow:**

Client (inside VNet)  
→ Internal Load Balancer (private IP)  
→ Backend Pool  
→ IIS on VM1 / VM2 / VM3  

---

## What This Lab Proves

- Internal Load Balancers do **not** require public IPs  
- Backend VM association is done via **NIC IP configurations**  
- Health probes directly control load-balancer traffic flow  
- IIS responses rotate across backend VMs  
- Terraform plans clearly show **what will change and why**  

---

## Technologies Used

- Azure  
- Terraform  
- Azure Virtual Networks  
- Azure Internal Load Balancer (Standard)  
- Windows Server 2019  
- IIS  
- Azure Bastion  

---

## Repository Structure

.
├── main.tf          # Core resources (VNet, VMs, Load Balancer, rules, probes)  
├── providers.tf     # Azure provider configuration  
├── variables.tf     # Input variables  
├── outputs.tf       # Useful outputs (subnet IDs, IPs, etc.)  
├── README.md        # Project documentation  
└── .gitignore       # Terraform state & local exclusions  

---

## Deployment Notes

- Terraform state is **not** committed (intentionally)  
- `.gitignore` excludes:
  - `.terraform/`
  - `*.tfstate`
  - `*.tfvars`
- Resources are deployed incrementally to keep plans readable  
- VM credentials are defined at deploy time (not stored in GitHub)  

---

## Validation Performed

- IIS reachable on each VM directly  
- Load Balancer private IP responds on port 80  
- Page content confirms traffic distribution between VMs  
- Health probe reports backend VMs as healthy  
- All resources visible and healthy in Azure Portal  

---

## Why This Matters (Interview Context)

This lab demonstrates real-world Azure skills:
- Designing private, secure architectures  
- Understanding how Azure Load Balancers actually work  
- Debugging common issues (NIC IP config names, probes, quotas)  
- Using Terraform responsibly in production-style workflows  

This is **not** a click-ops demo — it’s infrastructure you can reason about.

---

## Next Possible Enhancements

- NSGs with least-privilege rules  
- Azure Monitor / Log Analytics  
- Autoscaling with VM Scale Sets  
- HTTPS with internal certificates  
- CI/CD pipeline for Terraform  

---

## Author

Built as part of a hands-on Azure networking lab using Terraform, with a focus on clarity, correctness, and interview-ready architecture.
