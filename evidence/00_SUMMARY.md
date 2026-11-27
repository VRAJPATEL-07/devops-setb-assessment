
=== Step 7: evidence inventory snapshot ===
Exact command: find evidence -maxdepth 1 -type f -printf "%f\\n" | sort
Timestamp (UTC): 2026-11-27T10:09:18Z
00_SUMMARY.md
01_linux_git.txt
02_terraform.txt
03_docker_compose.txt
04_ci.txt
05_kubernetes.txt
05b_bad_rollout_diagnosis.txt
06_monitoring_security.md
README.txt
exit code: 0

# Step 7 – Assessment summary

| Task | Status | Evidence | Result |
| --- | --- | --- | --- |
| 1. Linux, log analysis, Git | EXECUTED | `01_linux_git.txt` | Fixture verified: 24 requests, 4 4xx, 2 5xx; route counts 8/6/5; analyzer success and missing-file error recorded. |
| 2. Terraform | EXECUTED | `02_terraform.txt` | fmt, init, validate, plan, and apply passed; generated env has mode 0600; invalid port 80 was rejected. |
| 3. Docker + Compose | EXECUTED | `03_docker_compose.txt` | Build and service health passed; endpoints returned expected responses, UID 10001 confirmed, teardown clean. |
| 4. CI/CD | EXECUTED | `04_ci.txt` | YAML, compile, and all 7 tests passed; local test-failure simulation showed build skipped. `act` was unavailable. |
| 5. Kubernetes | EXECUTED | `05_kubernetes.txt`, `05b_bad_rollout_diagnosis.txt` | kind deployment reached 2/2; bad readiness rollout returned 503 without restarts, old pods served traffic, and rollback restored 2/2. |
| 6. Monitoring, security, recovery | EXECUTED | `06_monitoring_security.md` | 8.33% 5xx rate and alert/runbook guidance documented; non-root, secret/state scan, and hardening evidence captured. |
| 7. README + evidence index | EXECUTED | `README.md`, `00_SUMMARY.md`, `INTERVIEW_NOTES.md` | Copy-paste instructions, honest verification statuses, file-by-file walkthrough notes, and archive-exclusion check added. |

No GitHub Actions run was triggered because no push was requested or performed.
The only intentionally failing commands were the invalid Terraform port
validation and the temporary failing-test/rollout demonstrations; their
failures were expected and recorded. Generated configuration/state and plans
are ignored; the Terraform provider lock file is committed.
The submission zip was verified to contain no state, Terraform cache, generated
environment file, or credential-like assignment. Terraform destroy was skipped
to preserve `generated/service.env` for review.

Evidence files:

- `01_linux_git.txt`
- `02_terraform.txt`
- `03_docker_compose.txt`
- `04_ci.txt`
- `05_kubernetes.txt`
- `05b_bad_rollout_diagnosis.txt`
- `06_monitoring_security.md`
- `INTERVIEW_NOTES.md`

=== Step 7: final evidence inventory ===
Exact command: find evidence -maxdepth 1 -type f -printf "%f\\n" | sort
Timestamp (UTC): 2026-11-27T10:11:56Z
00_SUMMARY.md
01_linux_git.txt
02_terraform.txt
03_docker_compose.txt
04_ci.txt
05_kubernetes.txt
05b_bad_rollout_diagnosis.txt
06_monitoring_security.md
INTERVIEW_NOTES.md
exit code: 0

=== Final required-file and placeholder check ===
Exact command: for f in Dockerfile .dockerignore compose.yaml .github/workflows/ci.yml k8s/*.yaml infra/*.tf infra/dev.tfvars.example scripts/analyze_logs.sh README.md evidence; do test -e "$f" || { echo "MISSING $f"; exit 1; }; printf "OK %s\\n" "$f"; done; if find . -type f \( -name "*.TODO" -o -name "README.txt" \) -print -quit | grep -q .; then echo "Placeholder files remain"; exit 1; else echo "No TODO or README.txt placeholders"; fi
Timestamp (UTC): 2026-11-27T10:11:56Z
OK Dockerfile
OK .dockerignore
OK compose.yaml
OK .github/workflows/ci.yml
OK k8s/configmap.yaml
OK k8s/deployment.yaml
OK k8s/namespace.yaml
OK k8s/service.yaml
OK infra/main.tf
OK infra/variables.tf
OK infra/versions.tf
OK infra/dev.tfvars.example
OK scripts/analyze_logs.sh
OK README.md
OK evidence
No TODO or README.txt placeholders
exit code: 0

=== Step 7: archive contents listing ===
Exact command: unzip -l ../Set_B_submission.zip
Timestamp (UTC): 2026-11-27T10:13:10Z
Archive:  ../Set_B_submission.zip
0effb7f128dce2ae18223c90e00157d59ea47d83
  Length      Date    Time    Name
---------  ---------- -----   ----
      121  2026-11-27 10:12   .dockerignore
        0  2026-11-27 10:12   .github/
        0  2026-11-27 10:12   .github/workflows/
      627  2026-11-27 10:12   .github/workflows/ci.yml
      126  2026-11-27 10:12   .gitignore
      484  2026-11-27 10:12   Dockerfile
    10805  2026-11-27 10:12   README.md
        0  2026-11-27 10:12   app/
        0  2026-11-27 10:12   app/__init__.py
     1768  2026-11-27 10:12   app/server.py
      311  2026-11-27 10:12   compose.yaml
        0  2026-11-27 10:12   evidence/
     3495  2026-11-27 10:12   evidence/00_SUMMARY.md
     2602  2026-11-27 10:12   evidence/01_linux_git.txt
    10546  2026-11-27 10:12   evidence/02_terraform.txt
    12563  2026-11-27 10:12   evidence/03_docker_compose.txt
     3977  2026-11-27 10:12   evidence/04_ci.txt
    17194  2026-11-27 10:12   evidence/05_kubernetes.txt
    20244  2026-11-27 10:12   evidence/05b_bad_rollout_diagnosis.txt
     5303  2026-11-27 10:12   evidence/06_monitoring_security.md
     5602  2026-11-27 10:12   evidence/INTERVIEW_NOTES.md
        0  2026-11-27 10:12   infra/
     1257  2026-11-27 10:12   infra/.terraform.lock.hcl
       92  2026-11-27 10:12   infra/dev.tfvars.example
      497  2026-11-27 10:12   infra/main.tf
      821  2026-11-27 10:12   infra/variables.tf
      152  2026-11-27 10:12   infra/versions.tf
        0  2026-11-27 10:12   k8s/
      199  2026-11-27 10:12   k8s/configmap.yaml
     1799  2026-11-27 10:12   k8s/deployment.yaml
       67  2026-11-27 10:12   k8s/namespace.yaml
      243  2026-11-27 10:12   k8s/service.yaml
        0  2026-11-27 10:12   logs/
     1414  2026-11-27 10:12   logs/access.log
        0  2026-11-27 10:12   scripts/
      810  2026-11-27 10:12   scripts/analyze_logs.sh
      599  2026-11-27 10:12   scripts/ev.sh
        0  2026-11-27 10:12   tests/
      997  2026-11-27 10:12   tests/test_server.py
---------                     -------
   104715                     39 files
exit code: 0

=== Step 7: archive excludes ignored state and secrets ===
Exact command: if unzip -l ../Set_B_submission.zip | grep -E "(^|/)([^/]*\\.tfstate[^/]*|service\\.env|\\.env|\\.terraform/)(/|$)|(^|/)(secrets?|credentials?)(/|$)"; then echo "Unexpected sensitive artifact found"; exit 1; else echo "Archive check passed: no state, Terraform cache, generated env, or credential files"; fi
Timestamp (UTC): 2026-11-27T10:13:10Z
Archive check passed: no state, Terraform cache, generated env, or credential files
exit code: 0

=== Step 7: tracked credential assignment scan ===
Exact command: if git grep -nEi "AKIA[0-9A-Z]{16}|password[[:space:]]*[:=]|token[[:space:]]*[:=]|secret[[:space:]]*[:=]" -- .; then echo "Potential credential assignment found"; exit 1; else echo "Tracked content scan passed: no credential-like assignments"; fi
Timestamp (UTC): 2026-11-27T10:13:10Z
Tracked content scan passed: no credential-like assignments
exit code: 0
