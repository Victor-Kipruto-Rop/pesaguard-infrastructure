# scripts/messaging

Topic configuration for the MSK cluster (`terraform/modules/msk/`).

| File | Purpose |
|---|---|
| `topics.yaml` | Declarative manifest: primary topics, partitions, replication, retention |
| `apply-topics.sh` | Creates those topics plus `-retry` / `-dlq` companions. Dry run by default, create-only, idempotent |

## Running it

```bash
# 1. See what would be created (no cluster access needed):
./apply-topics.sh

# 2. Apply for real. Requires network access to the cluster's private
#    subnets (run from an SSM-connected instance in the app tier, never
#    over public SSH) and a Kafka distribution providing kafka-topics.sh:
APPLY=yes \
BOOTSTRAP_SERVERS="$(terraform -chdir=../../terraform/live/dev output -raw msk_bootstrap_brokers_sasl_iam)" \
COMMAND_CONFIG=./client-iam.properties \
./apply-topics.sh
```

**Replication factor vs broker count.** The manifest asks for replication
factor 3. Dev and staging run 2 brokers (2 AZs), and Kafka rejects a
replication factor above the broker count, so for those environments run
with `REPLICATION_FACTOR_CAP=2`. Production (3 brokers, 3 AZs) applies the
manifest as written. The script prints a note for every topic it caps.

`client-iam.properties` is not committed (it contains no secrets, but its
exact contents depend on the `aws-msk-iam-auth` jar path on the machine
running the script). It needs:

```properties
security.protocol=SASL_SSL
sasl.mechanism=AWS_MSK_IAM
sasl.jaas.config=software.amazon.msk.auth.iam.IAMLoginModule required;
sasl.client.callback.handler.class=software.amazon.msk.auth.iam.IAMClientCallbackHandler
```

The caller's IAM identity must be allowed `kafka-cluster:Connect`,
`kafka-cluster:CreateTopic`, and `kafka-cluster:DescribeTopic` on the
cluster (the `app_service` role has data-plane access; topic *creation*
is intentionally an operator action, so use an operator/admin role — not
the runtime application role).

## Why this script never deletes or alters topics

Topics carry financial event data. `apply-topics.sh` uses
`--if-not-exists` only. If you need to change partitions or retention on
an existing topic, or remove one, do it deliberately with
`kafka-topics.sh --alter` / `kafka-configs.sh` after reviewing the
consequences (partition count can only increase and changes key-to-
partition mapping, which breaks per-key ordering guarantees for
in-flight data). Editing `topics.yaml` alone will **not** change an
existing topic — the manifest describes what to create, not a desired
state to converge to.

## The retry / DLQ pattern

```
primary topic  -->  consumer  --success-->  done
                       |
                    failure
                       v
                <name>-retry  -->  consumer (with backoff)  --success--> done
                                        |
                                     failure
                                        v
                                  <name>-dlq   (terminal; humans/tooling investigate)
```

- `-retry` mirrors the primary's partition count and retention, so a
  retried message keeps its key → partition mapping (per-key ordering).
- `-dlq` never has shorter retention than its primary topic
  (`max(DLQ_RETENTION_MS, primary retention)`), so a dead letter cannot
  age out before anyone could reasonably have looked at it.

## What is NOT implemented

- **DLQ replay tooling.** Replaying from a `-dlq` topic into a primary
  topic can duplicate financial transactions unless consumers are
  idempotent. A replay tool must not be written until the idempotency
  contract (dedupe key, where it is enforced) is defined with the
  application repositories. Until then, replay is a manual, reviewed
  operation.
- **Consumer-lag and DLQ-growth alerting.** Needs the observability stack
  (Phase 8) so alerts have a destination.
- **Tests against a live cluster.** `apply-topics.sh` has been exercised
  in dry-run mode and with missing prerequisites only; it has not been
  run against a real MSK cluster.
