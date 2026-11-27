
=== Step 6: compute log rate using analyzer ===
Exact command: scripts/analyze_logs.sh logs/access.log
Timestamp (UTC): 2026-11-27T10:08:53Z
Total requests: 24
HTTP 4xx: 4
HTTP 5xx: 2
5xx rate: 8.33%
Top 3 routes:
      8 /healthz
      6 /api/slots?department=orthopedics
      5 /readyz
exit code: 0

=== Step 6: Compose non-root identity proof ===
Exact command: docker compose run --rm --no-deps --entrypoint id appointment-slots
Timestamp (UTC): 2026-11-27T10:08:53Z
 Network devops-setb-assessment_default Creating 
 Network devops-setb-assessment_default Creating 
 Network devops-setb-assessment_default Created 
 Network devops-setb-assessment_default Created 
 Container devops-setb-assessment-appointment-slots-run-3f7bb2794dcb Creating 
 Container devops-setb-assessment-appointment-slots-run-3f7bb2794dcb Created 
uid=10001(app) gid=10001(app) groups=10001(app)
exit code: 0

=== Step 6: Kubernetes non-root identity proof ===
Exact command: kubectl exec -n devops-assessment deployment/appointment-slots -- id
Timestamp (UTC): 2026-11-27T10:08:54Z
uid=10001(app) gid=10001(app) groups=10001(app)
exit code: 0

=== Step 6: tracked state and generated-file scan (no matches expected) ===
Exact command: git ls-files | grep -E '(^|/)([^/]*\.tfstate[^/]*|service\.env|\.env|\.terraform)(/|$)'
Timestamp (UTC): 2026-11-27T10:08:54Z
exit code: 1

=== Step 6: credential-keyword scan of tracked implementation files (no matches expected) ===
Exact command: git grep -nEi 'password|token|secret|AKIA' -- . ':!README.md' ':!evidence/**'
Timestamp (UTC): 2026-11-27T10:08:54Z
exit code: 1

=== Step 6: Kubernetes hardening and CI permission proof ===
Exact command: grep -nE 'runAsNonRoot|runAsUser|seccompProfile|allowPrivilegeEscalation|readOnlyRootFilesystem|drop:|contents: read' k8s/deployment.yaml .github/workflows/ci.yml
Timestamp (UTC): 2026-11-27T10:08:54Z
k8s/deployment.yaml:26:        runAsNonRoot: true
k8s/deployment.yaml:27:        runAsUser: 10001
k8s/deployment.yaml:28:        seccompProfile:
k8s/deployment.yaml:62:            allowPrivilegeEscalation: false
k8s/deployment.yaml:63:            readOnlyRootFilesystem: true
k8s/deployment.yaml:65:              drop:
.github/workflows/ci.yml:8:  contents: read
.github/workflows/ci.yml:27:      contents: read
exit code: 0

## Monitoring interpretation

The fixture's 5xx rate is 2/24 = 8.33%. Alert when the 5xx rate is above 1%
for five minutes; page when it exceeds 5% for five minutes, `/readyz` fails for
two consecutive minutes, or ready replicas fall below two. The 8.33% fixture
would fire the page threshold. The two final 503 requests are `/readyz` and
`/api/slots?department=orthopedics`, consistent with a `FAIL_MODE` readiness
incident.

## Readiness and liveness

Readiness failure removes the pod from Service endpoints and stalls this
`maxUnavailable: 0` rollout while the old replicas continue to serve traffic.
It does not restart the container. Liveness checks `/healthz`; that endpoint
kept returning 200, so the failing pod's restart count remained 0. The rollout
recovery command was `kubectl rollout undo deployment/appointment-slots -n
devops-assessment`; after recovery the deployment was 2/2 ready and `/readyz`
returned 200.

## Security checks

- The Compose and Kubernetes identity commands above both returned
  `uid=10001(app) gid=10001(app)`. The tracked-file scan for state, generated
  env, and Terraform cache returned no matches (grep exit code 1 means no
  matching paths); `.terraform.lock.hcl` is intentionally versioned and is not
  a state or cache artifact.
- The credential-keyword scan of tracked implementation files returned no
  matches (grep exit code 1). The manifest proof above confirms non-root,
  RuntimeDefault seccomp, no privilege escalation, read-only root filesystem,
  and dropped capabilities. CI permissions are limited to `contents: read`.
- The unfiltered tracked-file keyword scan's only hit is the documented grep
  command in `README.md`; it contains no credential value.

## Incident runbook

1. **Detect:** alert on 5xx rate, repeated readiness failure, or fewer than two
   ready pods.
2. **Diagnose:** run `kubectl get pods -n devops-assessment -o wide`,
   `kubectl describe pod <pod> -n devops-assessment`,
   `kubectl logs <pod> -n devops-assessment`, and
   `kubectl get events -n devops-assessment --sort-by=.lastTimestamp`.
   Check Service endpoint membership with
   `kubectl get endpointslice -n devops-assessment -l
   kubernetes.io/service-name=appointment-slots -o yaml`.
3. **Mitigate:** run
   `kubectl rollout undo deployment/appointment-slots -n devops-assessment`.
4. **Verify:** run
   `kubectl rollout status deployment/appointment-slots -n devops-assessment`,
   `kubectl get pods -n devops-assessment`, and
   `curl -i http://127.0.0.1:8080/readyz` through a port-forward. Confirm 2/2
   ready and the ConfigMap's `FAIL_MODE` is `0`.
5. **Post-incident:** preserve the rollout history and logs, document the
   timeline/root cause, and add a regression check or release safeguard.

=== Step 6: tracked-file credential keyword review ===
Exact command: git grep -nEi "password|token|secret|AKIA"
Timestamp (UTC): 2026-11-27T10:11:42Z
README.md:202:  `git grep -nEi 'password|token|secret|AKIA'` for unexpected credential-like
exit code: 0
