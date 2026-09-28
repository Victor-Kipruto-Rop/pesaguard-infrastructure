#!/usr/bin/env bash
# Create the Kafka topics (and their -retry / -dlq companions) declared in
# topics.yaml against an MSK cluster.
#
# Safety properties:
#   - DRY RUN by default. Nothing is created unless APPLY=yes.
#   - CREATE-ONLY. Uses --if-not-exists; never alters or deletes an
#     existing topic. Topics can hold financial event data, so changing
#     or removing one is a deliberate manual operation, not something a
#     re-run of this script can do by accident.
#   - Idempotent: safe to re-run.
#
# Usage:
#   ./apply-topics.sh                       # dry run: print what would be created
#   APPLY=yes BOOTSTRAP_SERVERS=b-1...:9098,b-2...:9098 \
#     COMMAND_CONFIG=./client-iam.properties ./apply-topics.sh
#
# Environment:
#   APPLY              "yes" to actually create topics (default: dry run)
#   BOOTSTRAP_SERVERS  MSK IAM bootstrap brokers (terraform output
#                      bootstrap_brokers_sasl_iam). Required when APPLY=yes.
#   COMMAND_CONFIG     Path to a Kafka client properties file configured for
#                      SASL/IAM (see README.md). Required when APPLY=yes.
#   KAFKA_TOPICS_BIN   Path to kafka-topics.sh (default: kafka-topics.sh on PATH)
#   REPLICATION_FACTOR_CAP
#                      Upper bound applied to every topic's replication factor
#                      (default: no cap). Set to the broker count for clusters
#                      with fewer than 3 brokers (dev/staging run 2), since
#                      Kafka rejects a replication factor above the broker
#                      count. Production (3 brokers) should leave this unset.
#   DLQ_RETENTION_MS   Minimum retention for <name>-dlq topics (default: 30 days;
#                      a DLQ never gets less retention than its primary topic)
#   MANIFEST           Path to the manifest (default: topics.yaml next to this script)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${MANIFEST:-${SCRIPT_DIR}/topics.yaml}"
APPLY="${APPLY:-no}"
KAFKA_TOPICS_BIN="${KAFKA_TOPICS_BIN:-kafka-topics.sh}"
DLQ_RETENTION_MS="${DLQ_RETENTION_MS:-2592000000}"
REPLICATION_FACTOR_CAP="${REPLICATION_FACTOR_CAP:-}"

log() { printf '[apply-topics] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

# --- prerequisites -------------------------------------------------------

command -v python3 >/dev/null 2>&1 || die "python3 is required to parse ${MANIFEST}"
python3 -c 'import yaml' 2>/dev/null || die "PyYAML is required (pip install pyyaml)"
[[ -f "${MANIFEST}" ]] || die "manifest not found: ${MANIFEST}"
if [[ -n "${REPLICATION_FACTOR_CAP}" ]] && ! [[ "${REPLICATION_FACTOR_CAP}" =~ ^[1-9][0-9]*$ ]]; then
  die "REPLICATION_FACTOR_CAP must be a positive integer, got '${REPLICATION_FACTOR_CAP}'"
fi

if [[ "${APPLY}" == "yes" ]]; then
  command -v "${KAFKA_TOPICS_BIN}" >/dev/null 2>&1 \
    || die "${KAFKA_TOPICS_BIN} not found on PATH (set KAFKA_TOPICS_BIN)"
  [[ -n "${BOOTSTRAP_SERVERS:-}" ]] || die "BOOTSTRAP_SERVERS must be set when APPLY=yes"
  [[ -n "${COMMAND_CONFIG:-}" && -f "${COMMAND_CONFIG}" ]] \
    || die "COMMAND_CONFIG must point to an existing client properties file when APPLY=yes"
else
  log "DRY RUN — no topics will be created. Set APPLY=yes to apply."
fi

# --- expand manifest into "name partitions rf retention_ms cleanup" lines --

expand_manifest() {
  MANIFEST="${MANIFEST}" DLQ_RETENTION_MS="${DLQ_RETENTION_MS}" REPLICATION_FACTOR_CAP="${REPLICATION_FACTOR_CAP}" python3 - <<'PYEOF'
import os
import sys
import yaml

with open(os.environ["MANIFEST"]) as fh:
    doc = yaml.safe_load(fh) or {}

topics = doc.get("topics") or []
skip = set(doc.get("no_dlq_companions") or [])
dlq_retention = int(os.environ["DLQ_RETENTION_MS"])
cap_raw = os.environ.get("REPLICATION_FACTOR_CAP", "")
cap = int(cap_raw) if cap_raw else None

seen = set()
for t in topics:
    for key in ("name", "partitions", "replication_factor", "retention_ms", "cleanup_policy"):
        if key not in t:
            sys.exit(f"topic {t!r} is missing required field '{key}'")
    name = t["name"]
    if name in seen:
        sys.exit(f"duplicate topic name in manifest: {name}")
    seen.add(name)
    rows = [(name, t["retention_ms"])]
    if name not in skip:
        rows.append((f"{name}-retry", t["retention_ms"]))
        # A DLQ must never expire sooner than the topic it backs.
        rows.append((f"{name}-dlq", max(dlq_retention, t["retention_ms"])))
    rf = t["replication_factor"]
    if cap is not None and rf > cap:
        print(f"note: capping replication factor {rf} -> {cap} for {name}", file=sys.stderr)
        rf = cap
    for topic_name, retention in rows:
        print(topic_name, t["partitions"], rf, retention, t["cleanup_policy"])
PYEOF
}

# --- create topics ---------------------------------------------------------

created=0
while read -r name partitions rf retention cleanup; do
  if [[ "${APPLY}" == "yes" ]]; then
    log "ensuring topic ${name} (partitions=${partitions}, rf=${rf}, retention.ms=${retention}, cleanup.policy=${cleanup})"
    "${KAFKA_TOPICS_BIN}" \
      --bootstrap-server "${BOOTSTRAP_SERVERS}" \
      --command-config "${COMMAND_CONFIG}" \
      --create --if-not-exists \
      --topic "${name}" \
      --partitions "${partitions}" \
      --replication-factor "${rf}" \
      --config "retention.ms=${retention}" \
      --config "cleanup.policy=${cleanup}"
  else
    log "would ensure topic ${name} (partitions=${partitions}, rf=${rf}, retention.ms=${retention}, cleanup.policy=${cleanup})"
  fi
  created=$((created + 1))
done < <(expand_manifest)

[[ "${created}" -gt 0 ]] || die "manifest produced no topics — refusing to report success"
log "done: ${created} topic(s) processed (apply=${APPLY})"
