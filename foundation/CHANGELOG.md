# 🧾 InfraForge Changelog

All notable changes to **InfraForge** will be documented in this file.  
Maintained by **InfraForgeLabs**.

This project adheres to **[Semantic Versioning](https://semver.org/spec/v2.0.0.html)**  
and follows the **[Keep a Changelog](https://keepachangelog.com/en/1.0.0/)** format.

---

## [Unreleased]
- Ongoing improvements, documentation refinements, and version stabilization efforts.

---

## [1.0.0] — 2026-01-26

### 🚀 Stable Release (Public)

* **InfraForge Core officially released**
* Stabilized local-first template generation engine
* Finalized and validated all core generators:
  * Terraform
  * Docker
  * Helm
  * Jenkins
  * ArgoCD
  * Monitoring
  * Security
* Hardened generator scripts for predictable, repeatable output
* Standardized project structure and naming conventions
* Improved safety guarantees:
  * No automatic deployment
  * No remote execution
  * No hidden side effects
* Refined CLI workflows:
  * `infraforge gen`
  * `infraforge show`
  * `infraforge list`
  * `infraforge version`
* Published Linux install and uninstall scripts
* Updated documentation for public onboarding
* Locked roadmap, versioning policy, and release philosophy
* Marked **v1.0.0 as the baseline stable foundation** for all future InfraForge releases

### 🔒 Stability Guarantee

* No breaking changes introduced in v1.0.0
* All future releases will be additive
* Existing workflows and templates will remain supported

---

## [0.9.0] — 2025-12-07

### 🤩 Pre-Release (Development Phase)

* Repository initialized under **InfraForge**  
* Added foundational directories:
  * TerraformTemplates, AnsibleTemplates, HelmTemplates, JenkinsTemplates
  * ArgoCDTemplates, MonitoringTemplates, SecurityTemplates, AWSToolkit
* Added generator scripts under `/scripts`
* Added `.github/workflows/auto-public.yml` for automation
* Created initial documentation & screenshots
* Verified folder interlinking and modularity
* Finalized version naming and roadmap structure

---

## 🗓️ InfraForge Roadmap (2026 – 2031)
> ⚙️ *Execution cadence balanced between 3–6 month intervals for design, testing, and stabilization.*

| Version | Target Period | Codename | Description | Status |
|----------|----------------|-----------|--------------|---------|
| **v1.0.0** | **Q1 2026** | 🧱 Genesis | Launch Bash Template Engine (Terraform, Docker, Helm, Jenkins, Security, ArgoCD ,etc) | ✅ Released |
| **v1.1.0** | **Q2 2026** | ⚙️ Integrate | Add CI/CD templates (GitHub Actions + GitLab CI) & Add Azure & GCP (Toolkit) | 🔄 Planned |
| **v1.3.0** | **Q3 2026 – Q4 2026** | 🧩 Orchestrate | Introduce `infraforge` CLI (config parser, setup engine) | 💡 Concept |
| **v1.4.0** | **Q1 2027** | 🧱 Validate | Add `infraforge check` and `.conf` validation engine | 🧠 Design |
| **v1.5.0** | **Q2 2027** | 🧰 Automate | Implement dry-run (`infraforge blueprint`) + workflow logic | 🎯 Development |
| **v2.0.0** | **Q3 2027 – Q4 2027** | ⚡ Execute | Add `infraforge deploy` with rollback, state tracking, audit logs | 🚧 Planned |
| **v2.5.0** | **Q1 2028** | 🔐 SecureOps | Add Secrets Vault + RBAC CLI access control | 🧩 Planned |
| **v3.0.0** | **Q2–Q3 2028** | 🚀 Runtime | Full CLI Runtime: Orchestration + Monitoring Integration | ✅ Milestone Target |
| **v4.0.0** | **Q1–Q2 2029** | 💻 ForgeDSL Alpha + 🔥 Ember |Introduce ForgeDSL `.if` syntax + compiler base.<br>🔹 Launch **Ember Alpha** in parallel – embedded reasoning core for syntax intelligence and policy validation | 🔬 Design Stage |
| **v4.1.0** | **Q3 2029** | 🧩 Parser | Build syntax parser, lexer, and ForgeDSL-to-Terraform translator | 🧱 Development |
| **v4.2.0** | **Q4 2029 – Q1 2030** | ⚙️ Compiler | Complete ForgeDSL compiler integration with InfraForge CLI | 🧠 Planned |
| **v5.0.0** | **Q2–Q3 2030** | ⚡ Native Engine | Native runtime automation engine executing ForgeDSL directly | 🚧 Research |
| **v6.0.0** | **Q4 2030 – Q1 2031** | 🧭 Adaptive | Self-optimizing runtime with telemetry & policy learning | 💡 Concept |
| **v6.5.0** | **Q2–Q3 2031** | 🌟 Evolution | Fully autonomous, self-orchestrating runtime environment | 🚀 Vision Stage |

---

## 🔖 Versioning Policy

* **MAJOR (X)** – Incompatible changes or redesigns  
* **MINOR (Y)** – New modules, features, or integrations  
* **PATCH (Z)** – Fixes, improvements, or documentation updates  

Format example: `v1.0.0`

---

## 👨‍💻 Maintainer

Developed and maintained by **[Gaurav Chile](https://github.com/gauravchile)**  
_Founder, InfraForgeLabs_

> *InfraForge — Forge your infrastructure with automation and precision.*

---

> ⏳ **Timeline Policy:** InfraForge follows flexible 3–6 month development cycles per version.  
> Complex phases such as ForgeDSL Compiler and Native Runtime may extend up to 6 months to ensure design maturity, stability, and community validation.

---
