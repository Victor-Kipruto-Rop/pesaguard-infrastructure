# Container security

No container images or deployment configuration exist in this repository
yet (Docker/ECS land in Phase 6/7). This document sets the requirements
those phases must meet, written now so they're a checklist rather than an
afterthought.

## Required for every production image

- [ ] **Run as non-root** — `USER` set to a non-root UID in every
      Dockerfile; verify with `docker inspect` or an image-scanning policy
      that rejects root-running images.
- [ ] **Immutable, versioned tags** — never deploy `:latest` to any
      environment; use a git SHA or semver tag, or an image digest.
- [ ] **Minimal base images** — distroless, `-slim`, or Alpine variants
      preferred over full OS base images, to shrink attack surface and
      scan findings.
- [ ] **Image scanning in CI** (Trivy, per Phase 9) — scan results that
      surface Critical/High vulnerabilities block merge/deploy for
      production images.
- [ ] **Read-only root filesystem** where the application allows it
      (`readonlyRootFilesystem: true` / ECS `readonlyRootFilesystem`),
      with explicit writable mounts (e.g. `/tmp`) only where needed.
- [ ] **Drop unnecessary Linux capabilities** — start from `CAP_DROP: ALL`
      and add back only what's required.
- [ ] **Resource limits** (CPU/memory) set on every container definition —
      no unbounded containers.
- [ ] **Health checks** (`HEALTHCHECK` in Docker, or the orchestrator's
      liveness/readiness probes) so the platform can distinguish "process
      alive" from "service ready" (see `../ARCHITECTURE.md`).
- [ ] **No secrets baked into images** — secrets come from
      `terraform/modules/secrets/` via the runtime environment (ECS
      task definition secrets / Kubernetes Secrets backed by the same
      Secrets Manager entries), never `COPY`'d into an image layer or
      passed as a plain `ENV` default.

## Registry

Once a container registry (ECR) is provisioned (Phase 6/7):

- Enable image scanning on push.
- Set a lifecycle policy to expire untagged/old images.
- Restrict push access to the CI/CD role (`terraform/modules/iam/` —
  `terraform_ci`), not broad account access.
