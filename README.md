# Set B – Outpatient Appointment Slots API

A small Python HTTP API packaged as a non-root container and deployed through
Terraform-generated local configuration, Docker Compose, GitHub Actions, and
Kubernetes. The supplied application and unit tests are intentionally unchanged.

## Prerequisites

- Python 3.12+ (the local assessment environment may provide a newer Python)
- Docker Engine with the Compose plugin
- Terraform 1.5+
- `kubectl` and kind for the Kubernetes walkthrough
- Bash, curl, Git, and PyYAML for the documented static checks

## Repository layout

| Path | Purpose |
| --- | --- |
| `app/`, `tests/` | Supplied API and its unit tests |
| `logs/access.log` | Fixed request log fixture |
| `scripts/` | Log analyzer and evidence-capture helper |
| `infra/` | Terraform variables, generated environment file, and provider lock |
| `Dockerfile`, `.dockerignore`, `compose.yaml` | Hardened local container runtime |
| `.github/workflows/ci.yml` | Test-before-build CI workflow |
| `k8s/` | Namespace, ConfigMap, Deployment, and Service manifests |
| `evidence/` | Captured command output, verification summary, and walkthrough notes |

## Local setup

Run the unit tests and syntax check:

```bash
python -m py_compile app/*.py tests/*.py
python -m unittest discover -s tests -v
```

Run the service in one terminal, then use a second terminal for the sample
requests:

```bash
python -m app.server
curl -i http://127.0.0.1:8080/healthz
curl -i 'http://127.0.0.1:8080/api/slots?department=orthopedics'
```

## Log analysis

```bash
scripts/analyze_logs.sh logs/access.log
```

The fixture has 24 requests, four 4xx responses, two 5xx responses, and an
8.33% 5xx rate. To exercise input validation, run
`scripts/analyze_logs.sh logs/missing.log`; it prints an error and exits 2.

## Terraform configuration

Run Terraform from `infra/`. The provider lock file is committed for repeatable
provider selection; `.terraform/`, state files, `tfplan`/`*.tfplan`, and the
generated `generated/service.env` are excluded from Git. The generated
environment file is created with mode 0600.

```bash
cd infra
terraform fmt -recursive
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan -var-file=dev.tfvars.example -out=tfplan
terraform apply -auto-approve -var-file=dev.tfvars.example
cat ../generated/service.env
cd ..
```

Port validation can be checked with
`(cd infra && terraform plan -var-file=dev.tfvars.example -var port=80)`;
that plan is expected to fail with the configured 1024–65535 validation error.

## Docker and Compose

```bash
docker compose config
docker compose up --build -d
docker compose ps
curl -i http://127.0.0.1:8080/healthz
curl -i http://127.0.0.1:8080/readyz
curl -i http://127.0.0.1:8080/info
curl -i 'http://127.0.0.1:8080/api/slots?department=orthopedics'
curl -i http://127.0.0.1:8080/unknown
docker compose exec appointment-slots id
docker inspect --format '{{.State.Health.Status}}' "$(docker compose ps -q appointment-slots)"
docker compose down
```

Compose binds only to localhost. The container runs as UID 10001, drops all
Linux capabilities, uses `no-new-privileges`, and has a read-only root
filesystem with `/tmp` mounted as tmpfs.

## CI and test gating

The GitHub Actions workflow runs Python compilation and the full unittest suite
in the `test` job. The image-build job has `needs: test`, so a test failure
prevents the Docker build from starting. It tags the local image with the
workflow commit SHA and does not log in to or push to a registry.

The workflow can be checked locally with:

```bash
python -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml')); print('YAML syntax: valid')"
python -m py_compile app/*.py tests/*.py
python -m unittest discover -s tests -v
```

Where `act` is unavailable, the evidence includes a local dependency simulation
on a throwaway branch: one expected slots count is temporarily changed, the
test command fails, and the chained image-build command is skipped. The test
file and branch are restored afterward. Push the branch yourself if you want
real GitHub Actions run screenshots; this assessment did not push anything.

## Kubernetes with kind

Create a local cluster, build and load the image, then apply resources in
dependency order:

```bash
kind create cluster --name devops-assessment
docker build -t appointment-slots:v1 .
kind load docker-image appointment-slots:v1 --name devops-assessment
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl rollout status deployment/appointment-slots -n devops-assessment --timeout=120s
kubectl get all,cm -n devops-assessment -o wide
kubectl port-forward -n devops-assessment svc/appointment-slots 8080:80
```

In another terminal, try `/healthz`, `/readyz`, `/info`,
`/api/slots?department=orthopedics`, and `/unknown` on port 8080. Stop the
port-forward with Ctrl-C before reusing that port.

For a healthy update:

```bash
docker build -t appointment-slots:v2 .
kind load docker-image appointment-slots:v2 --name devops-assessment
kubectl set image deployment/appointment-slots appointment-slots=appointment-slots:v2 -n devops-assessment
kubectl annotate deployment/appointment-slots -n devops-assessment kubernetes.io/change-cause="healthy release appointment-slots:v2" --overwrite
kubectl rollout status deployment/appointment-slots -n devops-assessment --timeout=120s
kubectl rollout history deployment/appointment-slots -n devops-assessment
kubectl get pods -n devops-assessment
```

To reproduce and diagnose a bad release in this local cluster only:

```bash
kubectl set env deployment/appointment-slots FAIL_MODE=1 -n devops-assessment
kubectl annotate deployment/appointment-slots -n devops-assessment kubernetes.io/change-cause="bad release FAIL_MODE=1" --overwrite
kubectl rollout status deployment/appointment-slots -n devops-assessment --timeout=60s
kubectl get pods -n devops-assessment -o wide
kubectl describe pod <new-pod> -n devops-assessment
kubectl logs <new-pod> -n devops-assessment
kubectl get events -n devops-assessment --sort-by=.lastTimestamp
kubectl get rs -n devops-assessment
kubectl rollout history deployment/appointment-slots -n devops-assessment
```

The readiness endpoint returns 503 on the new pod while `/healthz` remains 200.
The failed pod is removed from Service endpoints, the old ready pods continue
serving traffic, and the rollout stalls without container restarts. Recover:

```bash
kubectl rollout undo deployment/appointment-slots -n devops-assessment
kubectl rollout status deployment/appointment-slots -n devops-assessment --timeout=120s
kubectl get pods -n devops-assessment
kubectl port-forward -n devops-assessment svc/appointment-slots 8080:80
curl -i http://127.0.0.1:8080/readyz
kubectl get configmap appointment-slots -n devops-assessment -o jsonpath='{.data.FAIL_MODE}{"\n"}'
```

The two-replica Deployment uses `maxUnavailable: 0`, `maxSurge: 1`,
readiness/liveness probes, resource requests/limits, a non-root UID, Runtime
Default seccomp, dropped capabilities, and a read-only root filesystem.

## Monitoring, security, and incident runbook

- Alert when the 5xx rate is above 1% for five minutes; page above 5% for five
  minutes, when `/readyz` fails for two consecutive minutes, or when ready pod
  count falls below two. The fixture's 8.33% rate would trigger the page-level
  threshold. Its final two 503s are `/readyz` and the orthopedic slots route,
  consistent with the readiness/`FAIL_MODE` incident.
- Readiness failure removes a pod from Service endpoints and stalls a rollout;
  it does not restart the container. Liveness failure causes kubelet restarts.
  Here `/healthz` continued to return 200, so restart counts stayed at zero.
- Verify container identity with
  `docker compose exec appointment-slots id` and
  `kubectl exec -n devops-assessment deployment/appointment-slots -- id`.
- Check tracked files with
  `git ls-files | grep -E '(^|/)([^/]*\.tfstate[^/]*|service\.env|\.env|\.terraform)(/|$)'`;
  no state, generated environment file, or Terraform cache should be listed.
  The provider lock file `.terraform.lock.hcl` is intentionally tracked. Review
  `git grep -nEi 'password|token|secret|AKIA'` for unexpected credential-like
  values. CI is least-privilege (`contents: read`); Kubernetes drops all
  capabilities and uses a read-only root filesystem.

**Runbook:** Detect from the 5xx/readiness/ready-replica alerts. Diagnose with
`kubectl get pods -n devops-assessment -o wide`,
`kubectl describe pod <pod> -n devops-assessment`,
`kubectl logs <pod> -n devops-assessment`, and
`kubectl get events -n devops-assessment --sort-by=.lastTimestamp`. Mitigate
with `kubectl rollout undo deployment/appointment-slots -n devops-assessment`.
Verify rollout status, two ready pods, `/readyz` returning 200, and
`FAIL_MODE=0`; then record cause, timeline, and a preventive change.

## Validation checklist

- [x] Log fixture totals and route ranking agree with expected values.
- [x] Terraform format, initialization, validation, normal plan, apply, and
  invalid-port validation were run.
- [x] Compose build, health check, API probes, UID check, and teardown passed.
- [x] CI YAML and both local CI test commands passed; failing-test gating was
  demonstrated by local simulation because `act` is not installed.
- [x] kind deployment reached 2/2 ready, the failing readiness rollout was
  diagnosed, and rollback restored service.
- [x] Evidence and documentation are saved under `evidence/`.

## Cleanup and verification status

After stopping any port-forward, remove runtime resources if they are no longer
needed:

```bash
docker compose down
kubectl delete namespace devops-assessment
kind delete cluster --name devops-assessment
(cd infra && terraform destroy -auto-approve -var-file=dev.tfvars.example)
```

Terraform destroy also removes `generated/service.env`; skip that final command
if you want to keep the generated file available for review. Git ignores it and
Terraform state regardless.

| Area | Verification |
| --- | --- |
| Linux/logs/Git | 24 requests; 4 4xx; 2 5xx; route counts 8/6/5 |
| Terraform | fmt, validate, plan, apply passed; port 80 rejected |
| Docker/Compose | healthy, expected endpoint results, UID 10001, clean teardown |
| CI | YAML, compile, and 7 tests passed; failing-test dependency simulated |
| Kubernetes | 2/2 ready; bad rollout readiness failure observed and reverted |
| Security | generated config ignored and mode 0600; non-root and hardening verified |

## AI assistance disclosure

GitHub Copilot was used to assist with the assessment implementation and
documentation. All changes and command results were reviewed; the supplied
application and test files were not changed.
