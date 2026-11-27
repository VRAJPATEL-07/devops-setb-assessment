
=== Step 7: implementation commit history ===
Exact command: git --no-pager log --oneline -7
Timestamp (UTC): 2026-11-27T10:09:18Z
f0ea5d9 Add hardened Kubernetes deployment manifests
b7adda4 Gate image builds on the Python test suite
eb74b29 Containerize the API with hardened Compose defaults
2442f9d Build Terraform environment configuration
bf80246 Add log analysis and evidence helpers
b0a90e7 Add Set B starter kit
1348c84 Initial commit
exit code: 0

# Step 7 – 15-minute walkthrough notes

Each entry is two short sentences: what the file does and why it belongs in
this assessment.

## Configuration and runtime

- `.gitignore`: Excludes Terraform state, plans, generated service config, and Python caches. It deliberately leaves `.terraform.lock.hcl` trackable so provider versions are repeatable.
- `.dockerignore`: Keeps infrastructure, evidence, and generated files out of the build context. It retains the application source required by the image.
- `Dockerfile`: Builds the Python API on the requested slim base and runs it as UID 10001. Its health check uses Python's standard-library urllib rather than curl.
- `compose.yaml`: Runs the image on localhost with a read-only root filesystem, tmpfs, no extra capabilities, and no-new-privileges. This is the tested local runtime.
- `.github/workflows/ci.yml`: Runs compilation and unit tests before the build job. The explicit `needs: test` dependency is the test-failure gate.

## Terraform and scripts

- `infra/variables.tf`: Declares typed inputs and validation for port and failure mode. Invalid settings are rejected before creating the generated file.
- `infra/main.tf`: Uses `local_file` to write the Compose environment file and exposes its path. File and directory permissions are restricted to 0600 and 0700.
- `infra/.terraform.lock.hcl`: Pins the selected local provider release and checksums. This lock file is intentionally committed; state and plugin cache are not.
- `infra/dev.tfvars.example`: Supplies safe development defaults for repeatable Terraform commands. It contains no credentials.
- `infra/versions.tf`: Existing starter provider/version constraints were retained unchanged.
- `generated/service.env`: Terraform-generated runtime configuration with mode 0600. It is intentionally untracked and excluded from the submission archive.
- `scripts/analyze_logs.sh`: Counts requests, 4xx/5xx responses, error rate, and top routes. It validates missing arguments and input files with nonzero exits.
- `scripts/ev.sh`: Records the exact command, UTC timestamp, output, and exit code to evidence files. It made evidence capture consistent without saving shell-only state.

## Kubernetes manifests

- `k8s/namespace.yaml`: Creates the isolated `devops-assessment` namespace. It gives the demo's resources a bounded scope for cleanup.
- `k8s/configmap.yaml`: Provides non-secret application settings, including healthy `FAIL_MODE=0`. The bad release was introduced with `kubectl set env` rather than editing this source.
- `k8s/deployment.yaml`: Defines two hardened replicas, health probes, rolling-update safety, resource limits, and non-root security contexts. `maxUnavailable: 0` kept old pods available while the new pod failed readiness.
- `k8s/service.yaml`: Exposes ready pods internally on Service port 80 to container port 8080. Kubernetes readiness automatically controlled endpoint membership.

## README and evidence

- `README.md`: Provides prerequisites and copy-paste local, Terraform, Compose, CI, and Kubernetes workflows. It also documents monitoring, rollback, cleanup, and AI assistance disclosure.
- `evidence/00_SUMMARY.md`: Summarizes execution status for all seven assessment tasks. It distinguishes expected failures and absent hosted Actions runs from successful checks.
- `evidence/01_linux_git.txt`: Captures fixture counts, analyzer runs, branch/history, and ignore-rule proof. It records the analyzer's missing-file exit code.
- `evidence/02_terraform.txt`: Captures formatting, provider initialization, validation, plan/apply, generated output, and invalid-port validation. The expected validation failure is explicit.
- `evidence/03_docker_compose.txt`: Captures image build, health, API responses, logs, UID, and teardown. It demonstrates the Compose hardening working in the local engine.
- `evidence/04_ci.txt`: Captures workflow syntax and local test commands, then a failing-test simulation. The expected assertion was restored and its throwaway branch deleted.
- `evidence/05_kubernetes.txt`: Captures static validation, cluster creation, initial deployment, endpoint responses, and a healthy v2 update. The cluster was deleted after validation.
- `evidence/05b_bad_rollout_diagnosis.txt`: Captures failed readiness, pod events/logs, endpoint membership, continued old-pod traffic, and rollback. It shows liveness staying healthy with restart count zero.
- `evidence/06_monitoring_security.md`: Explains the observed rate, alert thresholds, health-probe distinction, security checks, and incident runbook. Raw proof commands and results precede the interpretation.

## Bad rollout story

The v2 release was healthy, so I deliberately set `FAIL_MODE=1` on the
Deployment to create a new ReplicaSet. The new pod repeatedly logged `/readyz`
503, stayed unready with restart count 0, and was excluded from Service
endpoints; the two existing ready pods continued returning 200. I confirmed
`/healthz` probes stayed 200, checked pod details/events/ReplicaSets/history,
then used `kubectl rollout undo`; the stable v2 deployment returned to 2/2
ready and `/readyz` returned 200 again.
