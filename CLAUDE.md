# CI Failure Analysis Optimized Workflow – ReportPortal Edition

**Note:** This workflow is designed for analyzing CI test failures collected from **ReportPortal**, the centralized test reporting platform. It retrieves failed test case logs from ReportPortal, analyzes them, and produces structured reports with actionable recommendations.

---

## Step 0 – Environment Validation
- **Action**: Run `./scripts/check_config.sh`
- **Purpose**: Ensure local environment and dependencies are correctly configured.
- **Condition**: Stop immediately if validation fails.

---

## Step 1 – Retrieve Failure Logs from ReportPortal
- **Action**:
  - Run `./scripts/get_logs.sh <LAUNCH_ID> <TOKEN> --filter` to download complete logs for failed test cases from ReportPortal.
  - Supports multi-page log retrieval for large launches.
  - Each failed test case produces an individual `.log` file.
  - **Smart auto-filtering**: Large logs (>200 lines) are automatically filtered using `scripts/filter_logs.sh`
- **Output**:
  - `failed_cases_<LAUNCH_ID>/logs/OCP-<CASE_ID>.log` (original logs, always created)
  - `failed_cases_<LAUNCH_ID>/logs/OCP-<CASE_ID>_filtered.log` (filtered for analysis, only if original >200 lines)
- **Analysis Priority**: **Use intelligent log selection** - prefer `*_filtered.log` if available, otherwise use original logs

---

## Step 2 – Locate Test Code
- **Action**:
  - Local search:
    ```bash
    grep -r "<CASE_ID>" <E2E_CODE_PATH>
    ```
  - GitHub search:
    - OpenShift E2E Tests: [openshift-tests-private](https://github.com/openshift/openshift-tests-private)
    - Origin Tests: [origin/test](https://github.com/openshift/origin/tree/master/test)
- **Output**: File path and relevant code snippets of the test.

---

## Step 2.5 – Deduplicate Test Cases (Critical Step)
- **Action**:
  - Examine available logs to identify duplicate test cases that share the same underlying failure
  - Group cases by actual test content rather than Case ID numbers
  - **Example**: OCP-28867 and OCP-41776 may be the same test with multiple Case IDs mentioned
- **Method**:
  ```bash
  # Extract test case names to identify duplicates
  cd failed_cases_<LAUNCH_ID>/logs/
  
  # Extract test case names from available logs (filtered if available, original otherwise)
  for log in *_filtered.log *.log; do
    [[ -f "$log" ]] || continue
    # Skip original logs if filtered version exists
    [[ "$log" == *.log && -f "${log%.log}_filtered.log" ]] && continue
    echo "=== $log ==="
    grep "\[FAIL\]" "$log" | head -1
  done
  
  # Group cases by identical test names (same test, different runs)
  # Example: OCP-28867 and OCP-41776 may have identical [FAIL] test names
  ```
- **Output**: List of unique test failures (typically 2-4 unique tests from 5-10 Case IDs)
- **Analysis Strategy**: **Only analyze unique test cases** to avoid redundant work

---

## Step 3 – Understand Test Intent & Analyze Failures
- **Action**:
  - Determine the test purpose, validation points, and expected flow.
  - Analyze the failure:
    - Error messages
    - Failure location
    - Dependencies
  - Classify errors: expected vs actual failures.
- **Output**: Initial failure analysis notes.

---

## Step 4 – Query Product Code via DeepWiki MCP
- **Action**:
  - Query DeepWiki MCP to map test logic to the corresponding product code.
  - Identify the product functionality or operator behavior causing the failure.
  - Run queries in parallel for multiple unique cases.
- **Repository Mapping**:
  - `sig-hive` tests → `openshift/hive`
  - `sig-cco` tests → `openshift/cloud-credential-operator`
- **Output**: Product code references for each failed test case.

---

## Step 5 – Cross-Reference Test Expectations
- **Action**:
  - Compare test expectations with actual product behavior.
  - Identify discrepancies between test logic and product behavior.
- **Output**: Notes on mismatches and potential root causes.

---

## Step 6 – Issue Classification
- **Action**:
  - Categorize failures as:
    - `E2E Bug`
    - `Product Bug`
    - `Spec Issue`
    - `Infrastructure Issue`
  - Assign confidence level and risk assessment.
- **Output**: Classification for each case.

---

## Step 7 – Provide Recommendations
- **Action**:
  - Give actionable recommendations:
    - Immediate fix
    - Long-term prevention
- **Output**: Suggested solutions with references to relevant PRs or issues.

---

## Step 8 – Comprehensive Analysis (All Failures) - OPTIMIZED FOR MAXIMUM SPEED
- **CRITICAL PERFORMANCE REQUIREMENTS**:
  - **MANDATORY**: Use **SINGLE MESSAGE** with **MAXIMUM PARALLEL Task calls** for all unique case analyses
  - **MANDATORY**: Use **SINGLE MultiEdit call** to create ALL output files simultaneously
  - **FORBIDDEN**: Sequential processing, multiple Write calls, or separate messages for each case

- **Action**:
  - **Phase 1 - Preparation (30 seconds max)**:
    - **Use intelligent log selection**: Process filtered logs if available, otherwise use original logs (small logs <200 lines don't need filtering)
    - **Smart deduplication**: Group identical test cases to identify unique failures (typically 2-4 unique tests from 5-10 Case IDs)
    - **Example grouping**: OCP-28867/OCP-41776 = 1 unique test, OCP-33832/OCP-42251/OCP-43033 = 1 unique test
  
  - **Phase 2 - Parallel Analysis (2-3 minutes max)**:
    - **MAXIMUM PARALLELISM**: Launch ALL unique case analyses in **ONE SINGLE MESSAGE** using multiple Task tool calls
    - **Implementation**: `Task("Analyze case 1"), Task("Analyze case 2"), Task("Analyze case 3"), Task("Analyze case 4")` - ALL IN ONE MESSAGE
    - **Target**: Process 4 unique cases simultaneously, complete in 2-3 minutes total
    - **Progress tracking**: 
      ```
      "Launching parallel analysis for X unique cases (Y total case IDs)"
      "Processing logs - using filtered logs where available, original logs for small files"
      "ETA: 2-3 minutes for complete analysis"
      ```
  
  - **Phase 3 - Report Generation (30 seconds max)**:
    - **SINGLE MultiEdit operation**: Create ALL files simultaneously in ONE tool call
    - **Files created in one operation**: All individual reports + summary + auxiliary files
    - **Target**: Complete file generation in <30 seconds

- **PERFORMANCE TARGETS**:
  - **Total execution time**: 3-4 minutes for 5-10 case IDs (2-4 unique tests)
  - **Parallel efficiency**: 4x speedup vs sequential processing
  - **File creation**: <30 seconds for all reports via single MultiEdit

- **Output** (Generated using **MANDATORY single MultiEdit call**):
  - `<LAUNCH_ID>-analyze-results/individual_reports/` - All individual reports created in one MultiEdit operation
  - `<LAUNCH_ID>-analyze-results/summary_report.md` - Created simultaneously with individual reports
  - Auxiliary files (created in same MultiEdit operation):
    - `failure_overview.md`
    - `debug_commands.sh`
    - `analysis_logs.txt`

---

## Output Structure

1. **Individual Case Reports** (Generated using single MultiEdit call for performance)  
   `<LAUNCH_ID>-analyze-results/individual_reports/OCP-<ID>_analysis.md`  
   - **Implementation**: Use ONE MultiEdit tool call to create ALL individual reports simultaneously - dramatically faster than multiple Write calls
   - Summary: Case ID, title, failure description, timestamp  
   - Root Cause: Primary issue, failure type, risk, impact  
   - Evidence: Key logs, test snippets, product code references  
   - Recommendations: Immediate fix, long-term prevention

2. **Summary Report** (Created in same MultiEdit operation)  
   `<LAUNCH_ID>-analyze-results/summary_report.md`  
   - Total cases, failure rate, analysis duration  
   - Failure patterns, root cause distribution  
   - Risk assessment matrix  
   - Immediate and long-term recommendations  
   - Debug commands and failed analyses  
   - Parallel processing efficiency metrics

3. **Auxiliary Files** (All created in single MultiEdit operation)  
   - `failure_overview.md`: Table of failures, classification, risk levels  
   - `debug_commands.sh`: Script template for reproducing or investigating failures  
   - `analysis_logs.txt`: Detailed internal process logs (optional)

---

## Key Principles - SPEED OPTIMIZATION MANDATORY
- **CRITICAL SPEED REQUIREMENTS**:
  - **MAXIMUM PARALLELISM**: ALL case analyses MUST be launched in ONE single message with multiple Task calls
  - **SINGLE MultiEdit MANDATORY**: ALL reports created in ONE MultiEdit operation - NEVER use multiple Write calls
  - **3-4 minute total target**: Complete analysis of 5-10 case IDs in 3-4 minutes maximum
  - **NO SEQUENTIAL PROCESSING**: Forbidden to process cases one by one

- **Core Speed Principles**:
  - **Intelligent log selection**: Use filtered logs (>200 lines) when available, original logs for smaller files - optimal processing regardless of size
  - **Deduplicate before analysis**: Identify unique test failures to avoid redundant work (typically 2-4 unique from 5-10 case IDs)
  - **Smart grouping**: Multiple Case IDs often represent the same underlying test failure
  - **Batch everything**: Combine maximum parallel Task calls + single MultiEdit for optimal performance

- **Quality Standards** (maintained despite speed focus):
  - Analysis is **conclusion-driven**: insights first, process second
  - Structure outputs for **human readability and automated parsing**
  - Include **risk level** and **actionable recommendations** for each case
  - Designed specifically to leverage **ReportPortal** as the source of CI failure data

- **Performance Monitoring**:
  - Track parallel analysis efficiency (target: 4x speedup)
  - Monitor file creation time (target: <30 seconds for all reports)
  - Measure end-to-end execution time (target: 3-4 minutes total)
