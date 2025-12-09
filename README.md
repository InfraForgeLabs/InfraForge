# 🛠️ InfraForge — Unified DevSecOps Framework
> ⚙️ Automate infrastructure, CI/CD, security, and monitoring — all from a single unified DevSecOps framework.

![InfraForge Banner](assets/banner.png)

<!-- 🌐 Global Project Badges -->

[![Terraform Templates](https://img.shields.io/badge/Terraform-Templates-7B42BC?logo=terraform\&logoColor=white)](https://github.com/gauravchile/InfraForge/tree/main/TerraformTemplates) [![Ansible Templates](https://img.shields.io/badge/Ansible-Playbooks-EE0000?logo=ansible\&logoColor=white)](https://github.com/gauravchile/InfraForge/tree/main/AnsibleTemplates) [![Docker Templates](https://img.shields.io/badge/Docker-Templates-2496ED?logo=docker\&logoColor=white)](https://github.com/gauravchile/InfraForge/tree/main/DockerTemplates) [![Helm Charts](https://img.shields.io/badge/Helm-Charts-0F1689?logo=helm\&logoColor=white)](https://github.com/gauravchile/InfraForge/tree/main/HelmTemplates) [![Kubernetes YAMLs](https://img.shields.io/badge/Kubernetes-YAMLs-326CE5?logo=kubernetes\&logoColor=white)](https://github.com/gauravchile/InfraForge/tree/main/K8sYamlTemplates) [![Argo CD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?logo=argo\&logoColor=white)](https://github.com/gauravchile/InfraForge/tree/main/ArgoCDTemplates) [![Jenkins Pipelines](https://img.shields.io/badge/Jenkins-Pipelines-D24939?logo=jenkins\&logoColor=white)](https://github.com/gauravchile/InfraForge/tree/main/JenkinsTemplates) [![Security Templates](https://img.shields.io/badge/Security-Templates-FF0000?logo=security\&logoColor=white)](https://github.com/gauravchile/InfraForge/tree/main/SecurityTemplates) [![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-E6522C?logo=prometheus\&logoColor=white)](https://github.com/gauravchile/InfraForge/tree/main/MonitoringTemplates) [![Grafana](https://img.shields.io/badge/Grafana-Dashboards-F46800?logo=grafana\&logoColor=white)](https://github.com/gauravchile/InfraForge/tree/main/MonitoringTemplates) [![Loki](https://img.shields.io/badge/Loki-Logs-00BFAE?logo=grafana\&logoColor=white)](https://github.com/gauravchile/InfraForge/tree/main/MonitoringTemplates) [![AWS Toolkit](https://img.shields.io/badge/AWS-Toolkit-FF9900?logo=amazon-aws\&logoColor=white)](https://github.com/gauravchile/InfraForge/tree/main/AWSToolkit)

A complete **end-to-end DevSecOps framework** built for automation, scalability, and production readiness. This repository contains modular, GitHub-connected templates covering the **entire DevOps lifecycle** — from infrastructure provisioning to CI/CD, monitoring, and security.

---

## 🧩 About This Project

The **InfraForge — Unified DevSecOps Framework** is a modular, automation-first repository designed to unify Infrastructure-as-Code, CI/CD, and security automation under one ecosystem. Each tool and template is plug-and-play, production-ready, and directly linked to GitHub for live updates.

## 📘 Table of Contents
- [About This Project](#-about-this-project)
- [Repository Overview](#-repository-overview)
- [Quick Start](#️-quick-start)
- [Features](#-features)
- [Deployment Options](#-deployment-options)
- [Integrations](#-integrations)
- [Contribution](#️-contribution)
- [Roadmap](#-infraforge-roadmap-20262028)
- [Support](#-support--credits)


### 🔧 Included Frameworks

* **Infrastructure:** Terraform, Ansible, Helm, Docker, Kubernetes YAMLs
* **CI/CD & GitOps:** Jenkins, ArgoCD
* **Observability:** Prometheus, Grafana, Loki
* **Security:** Compliance, Hardening, Scanning Templates
* **Automation Scripts:** Smart CLI generators for each tool
* **NEW:** 🧰 **AWSToolkit** — your CLI-based AWS automation suite for managing EC2, S3, IAM, Lambda, RDS, EKS, CloudFormation, and more.

---

## 🧹 Repository Overview

```
InfraForge/
├── assets/
│   ├── logo.png           # Main logo
│   ├── roadmap.png        # Roadmap timeline
│   ├── banner.png
├── AnsibleTemplates/      # Configuration management & playbooks
├── ArgoCDTemplates/       # GitOps deployments & applications
├── DockerTemplates/       # Dockerfiles & Compose stacks
├── HelmTemplates/         # Helm charts for app packaging
├── JenkinsTemplates/      # Declarative CI/CD pipelines
├── K8sYamlTemplates/      # Kubernetes YAMLs (minimal, production, addons)
├── MonitoringTemplates/   # Prometheus, Grafana, Loki, Alertmanager stack
├── SecurityTemplates/     # Hardening, scanning, compliance policies
├── TerraformTemplates/    # Multi-cloud infra (AWS/Azure/GCP)
├── AWSToolkit/            # AWS CLI-based automation modules
└── scripts/               # Universal generators (auto-fetch from GitHub)
    ├── ansible-gen.sh
    ├── argocd-gen.sh
    ├── docker-gen.sh
    ├── helm-gen.sh
    ├── jenkins-gen.sh
    ├── k8s-yaml-gen.sh
    ├── monitoring-gen.sh
    ├── security-gen.sh
    ├── terraform-gen.sh
    └── awstoolkit.sh
```

---

## ⚙️ Quick Start

### Option 1 — Clone the full repository

```bash
git clone https://github.com/InfraForgeLabs/InfraForge.git
cd InfraForge/scripts
```

### Option 2 — Download only the scripts/ folder (no need to clone)

```bash
curl -L -o temp.zip https://github.com/InfraForgeLabs/InfraForge/archive/refs/heads/main.zip && \
unzip -j temp.zip InfraForge-main/scripts/* -d scripts-temp && \
rm temp.zip && \
echo "✅ Downloaded scripts folder successfully!"
```

---

## 🌐  `--help` Flag Support

Each generator script supports a built-in **`--help`** flag for quick command reference and CLI automation.

```bash
bash generation-script.sh --help
```

### Applies to all scripts:

* Terraform
* Ansible
* Docker
* Helm
* Kubernetes
* Jenkins
* Monitoring
* Security
* ArgoCD

---

### Generate templates interactively

Each script auto-fetches the latest files from GitHub and supports offline fallback.

#### Example Commands:

```bash
bash terraform-gen.sh     # Terraform Infra
bash docker-gen.sh       # Docker & Compose
bash helm-gen.sh         # Helm Charts
bash jenkins-gen.sh      # Jenkins Pipelines
bash monitoring-gen.sh   # Monitoring Stack
bash security-gen.sh     # Security Templates
bash argocd-gen.sh       # GitOps (Argo CD)
```

---

## 🌐 Features

* 🌍 **Online + Offline support** — auto-fetches from GitHub or uses local fallback.
* 🧱 **Modular architecture** — every folder works standalone.
* 🧠 **Smart YAML generation** — replaces placeholders automatically.
* 🔐 **Security-first templates** — with vaults, secrets, and compliance rules.
* ⚙️ **CI/CD integrated** — easily connects with Jenkins, ArgoCD, and Terraform.
* 🧹 **Observability-ready** — full Prometheus + Grafana + Loki + Alertmanager setup.
* ☁️ **AWS Toolkit Integration** — manage EC2, S3, IAM, Lambda, CloudFormation, and more directly via scripts (`scripts/awstoolkit.sh`).

---

## 📡 Deployment Options

| Stack      | Deployment Method                       |
| ---------- | --------------------------------------- |
| Kubernetes | `kubectl apply -f` or `kustomize build` |
| Helm       | `helm install app helm/`                |
| Argo CD    | Declarative GitOps apps                 |
| Terraform  | `terraform apply`                       |
| Ansible    | `ansible-playbook site.yml`             |
| Jenkins    | Pipeline-as-Code (Jenkinsfile)          |
| Monitoring | Helm/Kustomize/Direct YAMLs             |

---

## 🔗 Integrations

| Tool                   | Integration Purpose                 |
| ---------------------- | ----------------------------------- |
| **Terraform**          | Cloud infra provisioning            |
| **Kubernetes**         | App orchestration                   |
| **Helm**               | App deployment packaging            |
| **Jenkins**            | CI/CD automation                    |
| **Argo CD**            | GitOps continuous delivery          |
| **Ansible**            | Configuration management            |
| **Monitoring Stack**   | Observability & alerting            |
| **Security Templates** | Compliance, scanning, and hardening |
| **AWS Toolkit**        | Cloud automation via Bash CLI       |

---

## 🛠️ Contribution

Want to extend this InfraForge?
Fork it, improve any module, and send a PR!

```bash
git checkout -b feature/new-module
# edit templates or scripts
git commit -m "✨ added new module"
git push origin feature/new-module
```

---

## 📜 License

This project is licensed under the **MIT License** — free to use, modify, and distribute.

---

## 🗓️ InfraForge Roadmap (2026–2028)

![InfraForge Roadmap](assets/roadmap.png)

---

## 💖 Support & Sponsorship

**InfraForge** is proudly built and maintained as an open-source DevSecOps framework.  

If you find this project useful, consider supporting its development — your contribution helps keep it active, updated, and community-driven.

### ☕ Ways to Support

- 💎 **GitHub Sponsors:** [Sponsor @gauravchile](https://github.com/sponsors/gauravchile)
- ☕ **Buy Me a Coffee:** [buymeacoffee.com/gauravchile](https://buymeacoffee.com/gauravchile)

> Every contribution — whether a coffee, a star ⭐, or a pull request — helps make InfraForge better for everyone.

---

## ⭐ Support & Credits

Developed & maintained by [Gaurav Chile](https://github.com/gauravchile)

Founder, **InfraForgeLabs**

> 💡 Tip: All generator scripts auto-update from GitHub — no manual sync needed.
> Perfect for DevOps learners, professionals, or teams building scalable infra-as-code.

---
