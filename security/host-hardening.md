# Host hardening (EC2)

No EC2 instances exist in this repository yet — compute is introduced in
Phase 7. This checklist is written now so it can be enforced from the
first instance/launch template onward, rather than retrofitted.

## Required for every EC2 instance / launch template

- [ ] **IMDSv2 only** — `metadata_options { http_tokens = "required" }`
      on the instance/launch template. Disables the older, SSRF-exploitable
      IMDSv1.
- [ ] **`http_put_response_hop_limit = 1`** unless the instance genuinely
      needs to proxy metadata requests (containers needing IMDS access
      should use IAM roles for tasks instead where possible).
- [ ] **EBS encryption at rest** using the `database` or a dedicated
      compute KMS key from `terraform/modules/kms/` — never an unencrypted
      root or data volume.
- [ ] **No public IP** for app/data-tier instances — they live in the
      `app_subnet_ids` / `data_subnet_ids` from `terraform/modules/networking/`,
      which have no direct internet route in (only outbound via NAT for
      the app tier).
- [ ] **Minimal AMI** — prefer Amazon Linux 2023 or a distroless/minimal
      base; avoid installing packages beyond what the workload needs.
- [ ] **Automatic security updates** enabled for OS packages (e.g.
      `dnf-automatic` / `unattended-upgrades`) unless a controlled patch
      pipeline replaces it.
- [ ] **No SSH access** — see `management-access.md`. Use SSM Session
      Manager.
- [ ] **Instance role, not instance credentials** — always attach the
      appropriate role from `terraform/modules/iam/` via an instance
      profile; never bake AWS credentials into an AMI or user-data script.
- [ ] **CloudWatch agent / log forwarding** configured to ship logs to the
      `/pesaguard/<environment>/*` log group family so they're covered by
      the `logs` KMS key and retention policy.

## Not yet applicable

Kubernetes node hardening (Pod Security Standards, node IAM scoping) is
out of scope until/unless EKS is chosen in Phase 7 — see
`terraform/modules/networking/README.md` and `../ARCHITECTURE.md` for the
current "start with ECS/EC2" stance.
