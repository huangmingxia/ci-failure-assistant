# CI Failure Analysis Assistant

A tool to assist in analyzing CI test failures efficiently with automated workflows and comprehensive reporting.

## 📁 Project Structure

```
ci-failure-assistant/
├── scripts/           # Core shell scripts
│   ├── check_config.sh    # Environment validation
│   ├── get_logs.sh        # Report Portal log retrieval
│   └── filter_logs.sh     # Log filtering utility
├── CLAUDE.md                 # AI assistant instructions
├── CI_Failure_ReportPotal.md # ReportPortal workflow
├── .env.example       # Environment configuration template
└── README.md          # This file
```

## 🎯 Supported Scenarios

This tool supports **two types** of CI failure analysis:

### 1.  Report Portal Failure Case
Analyze failures reported in Report Portal with automated log extraction and intelligent analysis.

**📋 Prerequisites:**
- Report Portal access token
- VPN connection to internal resources  
- Launch ID from Report Portal (e.g., `767719`)
- Environment configuration: `cp .env.example .env` and edit with your credentials
- **Pure Shell implementation** - No dependencies required

**🚀 Execution:**  
Follow the workflow in **`CI_Failure_ReportPotal.md`**

**💡 Usage Example:** 

Provide launch ID to AI assistant for automated analysis

```
Analyze all failure cases from Report Portal launch id 767719
```

#### Demo

1. [AI_Assisted_CI_Failure](https://drive.google.com/file/d/144xV5h30ZbpFZabBWvoA4Acq6zGM-NEt/view?usp=drive_link)
---

### 2.  Prow Job Failure ⚠️ (WIP)
Analyze failures from a directly run Prow Job with detailed logs and root cause analysis.

**📋 Prerequisites:**
- Access to Prow job logs
- Job URL or build ID
- VPN connection (if required for internal jobs)

**🚀 Execution:**  
Follow the instructions in **`CI Failure Analysis Optimized Workflow – Prow Job Edition`**

**💡 Usage Example:**  
```bash
# Analyze specific Prow job failure
Analyze Prow job: https://prow.ci.openshift.org/view/gs/test-platform-results/logs/periodic-ci-openshift-cloud-credential-operator-release-4.20-periodics-e2e-azure-manual-oidc/1961997673242300416
```
