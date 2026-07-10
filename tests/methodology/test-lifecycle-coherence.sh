#!/usr/bin/env bash
# Focused mutation tests for the lifecycle registry coherence contract.

set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

pass_count=0
fail_count=0

pass() {
  printf 'PASS: %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf 'FAIL: %s\n' "$1"
  fail_count=$((fail_count + 1))
}

fixture="$workdir/repo"
mkdir -p "$fixture"
cp -R "$repo_root/." "$fixture/" 2>/dev/null || cp -R "$repo_root/" "$fixture/"

validator="$fixture/scripts/check-lifecycle-coherence.py"
generator="$fixture/scripts/generate-lifecycle-contract.py"
registry="$fixture/docs/methodology/schema/lifecycle.json"
contract="$fixture/scripts/lib/lifecycle-contract.sh"
project_template="$fixture/docs/project-template/project.yaml"
registry_clean="$workdir/lifecycle.clean.json"
contract_clean="$workdir/lifecycle-contract.clean.sh"
project_template_clean="$workdir/project-template.clean.yaml"
output="$workdir/output.txt"

cp "$registry" "$registry_clean"
cp "$contract" "$contract_clean"
cp "$project_template" "$project_template_clean"

CHECK_RC=0
CHECK_OUT=""
run_validator() {
  python3 "$validator" --root "$fixture" --registry "$registry" "$@" > "$output" 2>&1
  CHECK_RC=$?
  CHECK_OUT="$(cat "$output")"
}

reset_fixture() {
  cp "$registry_clean" "$registry"
  cp "$contract_clean" "$contract"
  cp "$project_template_clean" "$project_template"
}

make_release_ready_fixture() {
  reset_fixture
  python3 - "$fixture" "$registry" <<'PY'
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1])
registry_path = Path(sys.argv[2])
data = json.loads(registry_path.read_text(encoding="utf-8"))
candidate = data["versions"]["candidate"]

data["registry"]["status"] = "released"
data["registry"]["released_current"] = candidate
data["versions"]["candidate_status"] = "released"
data["versions"]["released_current"] = candidate

def resolve_planned(value):
    if isinstance(value, list):
        for item in value:
            resolve_planned(item)
    elif isinstance(value, dict):
        for key, item in list(value.items()):
            if item == "planned" and (key == "state" or key.endswith("_state")):
                value[key] = "current"
            else:
                resolve_planned(item)

resolve_planned(data)

enforcement_records = [
    data["references"]["enforcement"],
    data["event_history"]["enforcement"],
    data["document_sweep"]["enforcement"]["active_prose_and_examples"],
    data["document_sweep"]["enforcement"]["historical_links_and_release_metadata"],
]
for enforcement in enforcement_records:
    for field in ("enforcer_path", "verification_suite"):
        delivered = root / enforcement[field]
        delivered.parent.mkdir(parents=True, exist_ok=True)
        if not delivered.exists():
            delivered.write_text(
                "#!/usr/bin/env bash\n# Release-fixture delivered enforcement probe.\nexit 0\n",
                encoding="utf-8",
            )
            delivered.chmod(0o755)

for decision in data["decisions"]:
    decision["state"] = "accepted"
ratification_records = []
for record in data["decision_records"]:
    classification = record.get("classification", "")
    if classification == "active_candidate":
        record["classification"] = "active"
    elif classification == "partially_superseded_candidate":
        record["classification"] = "partially_superseded"
    if record.get("decision_ids"):
        ratification_records.append(record)
        source = root / record["source_file"]
        source.write_text(
            re.sub(
                r"(?m)^Status:\s*(?:Ready for Approval|Accepted)\s*$",
                "Status: Ready for Approval",
                source.read_text(encoding="utf-8"),
            ),
            encoding="utf-8",
        )

subprocess.run(
    ["git", "config", "user.name", "Lifecycle Test"], cwd=root, check=True
)
subprocess.run(
    ["git", "config", "user.email", "lifecycle-test@example.invalid"],
    cwd=root,
    check=True,
)
subprocess.run(
    ["git", "add", "--", *[record["source_file"] for record in ratification_records]],
    cwd=root,
    check=True,
)
staged = subprocess.run(
    ["git", "diff", "--cached", "--quiet"], cwd=root, check=False
).returncode
if staged != 0:
    subprocess.run(
        ["git", "commit", "-m", "test: record reviewed decision candidates"],
        cwd=root,
        check=True,
        capture_output=True,
    )
reviewed_revision = subprocess.check_output(
    ["git", "rev-parse", "HEAD"], cwd=root, text=True
).strip()
for record in ratification_records:
    source_path = root / record["source_file"]
    reviewed_bytes = subprocess.check_output(
        ["git", "show", f'{reviewed_revision}:{record["source_file"]}'], cwd=root
    )
    reviewed_blob_oid = subprocess.check_output(
        ["git", "rev-parse", f'{reviewed_revision}:{record["source_file"]}'],
        cwd=root,
        text=True,
    ).strip()
    status_pattern = re.compile(br"(?m)^Status: Ready for Approval(?P<cr>\r?)$")
    resulting_bytes, replacement_count = status_pattern.subn(
        lambda match: b"Status: Accepted" + match.group("cr"), reviewed_bytes, count=1
    )
    if replacement_count != 1:
        raise RuntimeError(f"reviewed fixture source has invalid status: {record['source_file']}")
    source_path.write_bytes(resulting_bytes)
    resulting_blob_oid = subprocess.check_output(
        ["git", "hash-object", "--stdin"], cwd=root, input=resulting_bytes
    ).decode("ascii").strip()
    record.update(
        {
            "ratification_state": "accepted",
            "ratified_by": "Release Fixture Approver",
            "ratified_on": "2026-07-10",
            "reviewed_revision": reviewed_revision,
            "reviewed_blob_oid": reviewed_blob_oid,
            "reviewed_digest": hashlib.sha256(reviewed_bytes).hexdigest(),
            "resulting_blob_oid": resulting_blob_oid,
            "resulting_digest": hashlib.sha256(resulting_bytes).hexdigest(),
            "checked_statement": "Reviewed the exact decision record and accepted it.",
            "amendments_or_constraints": "none",
            "risk_disposition": "accepted",
            "ratification_record": (
                "docs/resources/evolution/"
                "0.5.0-operational-coherence-execution-log.md"
            ),
        }
    )

for target in data["versions"]["synchronization_targets"]:
    target["delivery_state"] = "current"

projection_path = root / data["event_history"]["template_projection"]
projection_marker = "\n## Release Fixture Schema 2 Event Projection\n"
projection_text = projection_path.read_text(encoding="utf-8").split(projection_marker, 1)[0]
projection_lines = [projection_text.rstrip(), projection_marker.strip()]
for event in data["events"]:
    projection_lines.append(f"\n### {event['id']}")
    projection_lines.append("Fields: " + ", ".join(event["required_fields"]))
    for profile, fields in event.get("conditional_field_sets", {}).items():
        projection_lines.append(f"Profile {profile}: " + ", ".join(fields))
projection_lines.append("\n### event_history_corrections")
projection_lines.append(
    "Fields: "
    + ", ".join(
        data["event_serialization"]["common_conditional_field_sets"]["correction"]
    )
)
projection_path.write_text("\n".join(projection_lines) + "\n", encoding="utf-8")

for artifact in data["artifacts"]:
    template = artifact.get("template")
    if not template:
        continue
    template_path = root / template
    template_path.parent.mkdir(parents=True, exist_ok=True)
    if not template_path.exists():
        template_path.write_text("project: release-fixture\nStatus: Draft\n", encoding="utf-8")
    if artifact.get("project_identity_required"):
        text = template_path.read_text(encoding="utf-8")
        if not re.search(r"(?m)^project:\s*\S+", text):
            template_path.write_text("project: release-fixture\n" + text, encoding="utf-8")

project_template = root / "docs/project-template/project.yaml"
project_text = project_template.read_text(encoding="utf-8")
project_text = re.sub(
    r"(?m)^(\s*methodology_version:)\s*\S+\s*$",
    rf"\1 {candidate}",
    project_text,
)
project_text = re.sub(r"(?m)^  (?:loop_status|current_phase_id):.*\n?", "", project_text)
project_text = re.sub(
    r"(?m)^phase:\s*$",
    "phase:\n  loop_status: not_started\n  current_phase_id: null",
    project_text,
    count=1,
)
project_template.write_text(project_text, encoding="utf-8")

readme = root / "README.md"
readme.write_text(
    re.sub(
        r"(?m)^Current methodology version:.*$",
        f"Current methodology version: `{candidate}`",
        readme.read_text(encoding="utf-8"),
    ),
    encoding="utf-8",
)
constitution = root / "docs/methodology/constitution/gendev.md"
constitution.write_text(
    re.sub(
        r"(?m)^Version:.*$",
        f"Version: {candidate}",
        constitution.read_text(encoding="utf-8"),
    ),
    encoding="utf-8",
)
release_index = root / "docs/resources/releases/README.md"
release_index.parent.mkdir(parents=True, exist_ok=True)
release_index.write_text(f"Latest release: {candidate}\n", encoding="utf-8")

initializer = root / "scripts/init-project.sh"
with initializer.open("a", encoding="utf-8") as handle:
    handle.write("\n# Release-fixture scaffold completeness probe.\n")
    handle.write("mkdir -p \\\n")
    for index, directory in enumerate(data["paths"]["canonical_directories"]):
        suffix = directory.removeprefix("docs/project/")
        ending = " \\\n" if index + 1 < len(data["paths"]["canonical_directories"]) else "\n"
        handle.write(f'  "$target/{suffix}"{ending}')

phase_command = root / data["compatibility"]["scaffold"]["phase_scaffold_command"]
phase_command.parent.mkdir(parents=True, exist_ok=True)
phase_command.write_text("#!/usr/bin/env bash\nexit 0\n", encoding="utf-8")
phase_command.chmod(0o755)

registry_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
  python3 "$generator" --registry "$registry" --output "$contract" > "$output" 2>&1
  RELEASE_GENERATE_RC=$?
}

expect_rc() {
  expected="$1"
  label="$2"
  if [ "$CHECK_RC" -eq "$expected" ]; then
    pass "$label (RC=$CHECK_RC)"
  else
    fail "$label expected RC=$expected, got RC=$CHECK_RC"
    printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
  fi
}

expect_rule() {
  rule="$1"
  label="$2"
  if printf '%s\n' "$CHECK_OUT" | grep -q "\[$rule\]\|\"rule_id\": \"$rule\""; then
    pass "$label reports $rule"
  else
    fail "$label did not report $rule"
    printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
  fi
}

expect_contract_value() {
  contract_file="$1"
  expected="$2"
  label="$3"
  shift 3
  CONTRACT_OUT="$(bash -c '. "$1"; shift; "$@"' _ "$contract_file" "$@")"
  CONTRACT_RC=$?
  if [ "$CONTRACT_RC" -eq 0 ] && [ "$CONTRACT_OUT" = "$expected" ]; then
    pass "$label"
  else
    fail "$label (RC=$CONTRACT_RC, OUT=$CONTRACT_OUT, EXPECTED=$expected)"
  fi
}

expect_contract_rc() {
  contract_file="$1"
  expected="$2"
  label="$3"
  shift 3
  bash -c '. "$1"; shift; "$@"' _ "$contract_file" "$@" > "$output" 2>&1
  CONTRACT_RC=$?
  if [ "$CONTRACT_RC" -eq "$expected" ]; then
    pass "$label (RC=$CONTRACT_RC)"
  else
    fail "$label expected RC=$expected, got RC=$CONTRACT_RC"
    sed 's/^/      /' "$output"
  fi
}

mutate_registry() {
  mutation="$1"
  python3 - "$registry" "$mutation" <<'PY'
import copy
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
mutation = sys.argv[2]
data = json.loads(path.read_text(encoding="utf-8"))

def record(records, identifier):
    return next(item for item in records if item.get("id") == identifier)

if mutation == "duplicate_gate":
    data["gates"].append(copy.deepcopy(data["gates"][0]))
elif mutation == "invalid_transition":
    transition = data["transitions"][0]
    transition["to"] = transition["from"]
elif mutation == "extra_skip_transition":
    transition = copy.deepcopy(data["transitions"][1])
    transition["id"] = "G1-to-G3-skip"
    transition["from"] = "G1"
    transition["to"] = "G3"
    data["transitions"].append(transition)
elif mutation == "duplicate_edge":
    transition = copy.deepcopy(data["transitions"][1])
    transition["id"] = "G1-to-G2-duplicate"
    data["transitions"].append(transition)
elif mutation == "missing_template":
    artifact = record(data["artifacts"], "vision")
    artifact["template"] = "docs/methodology/templates/does-not-exist.md"
    artifact["template_state"] = "current"
elif mutation == "missing_lifecycle_owner":
    record(data["artifacts"], "vision")["lifecycle_bindings"] = []
elif mutation == "incomplete_event_evidence_contract":
    data["event_evidence_item"]["required_fields"].remove("reviewed_revision")
elif mutation == "weaken_d18_controls":
    data["approval_policy"]["deployment"]["approver_kind"] = "automation"
    data["approval_policy"]["project_closeout"]["approver_kind"] = "automation"
    transition = record(data["transitions"], "G7-to-G8")
    transition["approval"] = "not_required"
    transition["approval_profiles"] = ["no_additional_approval"]
    data["deployment"]["artifact_requirements"] = []
    data["deployment"]["production_action_automatic"] = True
elif mutation == "remove_enforcement_ownership":
    data["references"].pop("enforcement", None)
    data["document_sweep"].pop("enforcement", None)
elif mutation == "premature_current_enforcement":
    data["references"]["enforcement"]["state"] = "current"
elif mutation == "weaken_event_predicate":
    record(data["event_binding_rules"], "all_declared_phase_exit_event_ids").pop(
        "quantifier", None
    )
elif mutation == "weaken_decision_invariants":
    data["naa"] = {}
    data["scaling"]["coverage_policy"]["universal_percentage"] = 90
    data["compatibility"]["automatic_gate_regression"] = True
    data["generation"]["platform_contract"] = []
    data["generation"]["runtime_dependency_policy"][
        "installed_transition_commands_require_python"
    ] = True
    data["evidence_categories"][0]["content_rule"] = ""
    data["references"]["depth_policy"]["default_supporting_depth"] = 2
    data["identifiers"]["workstream"]["reuse_retired_ids"] = True
    data["versions"]["release_rules"]["active_targets_change_atomically"] = False
elif mutation == "misroute_decision_binding":
    record(data["decisions"], "D-018")["mechanical_bindings"] = []
elif mutation == "wrong_g6_g7_binding":
    gate = record(data["gates"], "G6")
    gate["name"] = "Final Review Accepted"
    gate["purpose"] = "Complete final review and implementation acceptance."
elif mutation == "lost_final_phase_position":
    invariant = record(data["manifest"]["invariants"], "MANIFEST-PHASE-AXIS")
    invariant["retained_final_position"] = False
    invariant["rule"] = "phase.phase_position is null outside G5."
elif mutation == "invalid_nullable_checkpoint_field":
    record(data["checkpoints"], "G5.<id>.1")["nullable_event_fields"] = ["phase_id"]
elif mutation == "bad_fixed_path":
    data["paths"]["canonical_fixed_artifacts"]["vision"] = (
        "docs/project/[document-name].md"
    )
elif mutation == "competing_supporting_directory":
    data["paths"]["canonical_directories"].append("docs/project/supporting")
elif mutation == "stale_version_target":
    data["versions"]["candidate"] = "0.4.0-verification-first"
elif mutation == "bad_observation_revision":
    data["versions"]["observation_revision"] = "0" * 40
elif mutation == "premature_release_claim":
    candidate = data["versions"]["candidate"]
    data["registry"]["status"] = "released"
    data["registry"]["released_current"] = candidate
    data["versions"]["released_current"] = candidate
    data["versions"]["candidate_status"] = "released"
elif mutation == "invalid_candidate_status":
    data["registry"]["status"] = "banana"
    data["versions"]["candidate_status"] = "banana"
elif mutation == "fabricated_ratification_metadata":
    data["decision_records"][0]["reviewed_digest"] = "0" * 64
elif mutation == "planned_without_work_package":
    artifact = next(
        item for item in data["artifacts"] if item.get("lifecycle_state") == "planned"
    )
    artifact.pop("required_work_package", None)
elif mutation == "unbound_phase_exit_evidence":
    checkpoint = record(data["checkpoints"], "G5.<id>.4")
    checkpoint["required_evidence"].append(
        {
            "class": "unbound_phase_exit_probe",
            "artifact_ids": ["vision"],
            "event_fields": [],
        }
    )
elif mutation == "malformed_task_grammar":
    data["identifiers"]["task"]["pattern"] = "^TASK-[0-9]+$"
elif mutation == "non_posix_runtime_pattern":
    data["identifiers"]["task"]["pattern"] = (
        r"^PH-([A-Za-z0-9]+(?:-[A-Za-z0-9]+)*)-T([0-9]{3})$"
    )
elif mutation == "weaken_value_status_mapping":
    checkpoint = record(data["checkpoints"], "G5.<id>.4")
    checkpoint["reference_requirements"][0]["status_by_disposition"]["not_due"] = [
        "Complete"
    ]
elif mutation == "weaken_phase_exit_delegation":
    data["approval_policy"]["phase_exit"]["delegation_prohibited_classes"] = []
    record(data["events"], "phase_transition")["conditional_field_sets"] = {}
elif mutation == "weaken_deploy_owner_condition":
    transition = record(data["transitions"], "G8-to-G9")
    transition["conditional_transition_specific_event_fields"] = {}
    transition["transition_specific_event_fields"].append(
        "operational_owner_confirmation"
    )
elif mutation == "drift_gate_semantics":
    record(data["gates"], "G3")["primary_artifact"] = "prd"
elif mutation == "delete_checkpoint_evidence":
    checkpoint = record(data["checkpoints"], "G5.<id>.4")
    checkpoint["required_evidence"] = [
        item
        for item in checkpoint["required_evidence"]
        if item["class"] != "residual_risks"
    ]
elif mutation == "delete_post_loop_contract":
    transition = record(data["transitions"], "G7-to-G8")
    transition["required_artifacts"].remove("final_test_uat")
    transition["artifact_requirements"] = [
        item
        for item in transition["artifact_requirements"]
        if item["artifact_id"] != "final_test_uat"
    ]
elif mutation == "misroute_transition_command":
    record(data["transitions"], "G4-to-G5")["command"] = "scripts/close-gate.sh G3"
elif mutation == "drift_artifact_semantics":
    record(data["artifacts"], "vision")["owner_role"] = "prd-agent"
elif mutation == "coordinated_path_drift":
    canonical_path = "docs/project/vision/other.md"
    data["paths"]["canonical_fixed_artifacts"]["vision"] = canonical_path
    record(data["artifacts"], "vision")["path"] = canonical_path
elif mutation == "weaken_scaling_class":
    record(data["scaling"]["classes"], "C3")["unwanted_behavior_required"] = False
elif mutation == "weaken_scaffold_contract":
    data["compatibility"]["scaffold"]["seed_phase_must_be_complete"] = False
elif mutation == "weaken_manifest_terminal":
    record(data["manifest"]["invariants"], "MANIFEST-TERMINAL")[
        "next_gate_must_be_null"
    ] = False
elif mutation == "replace_baseline_observation":
    data["versions"]["observed_active_claims"][0] = {
        "source_file": "README.md",
        "field": "unrelated field",
        "value": "0.1.0-baseline",
    }
elif mutation == "extend_vocabulary":
    data["vocabularies"]["gate_statuses"].append("waived")
elif mutation == "serialization_missing_field_shape":
    data["event_serialization"]["field_contracts"].pop("checked_statement")
elif mutation == "serialization_invalid_item_contract":
    data["event_serialization"]["field_contracts"]["evidence"][
        "item_contract"
    ] = "missing_record_contract"
elif mutation == "serialization_evidence_source_drift":
    data["event_serialization"]["record_contracts"]["event_evidence_item"][
        "required_fields"
    ].remove("reviewed_digest")
elif mutation == "serialization_value_source_drift":
    data["event_serialization"]["record_contracts"]["value_review_details"][
        "conditional_field_sets"
    ]["not_due"].remove("owner")
elif mutation == "serialization_migration_source_drift":
    data["event_serialization"]["field_contracts"]["provenance"] = {
        "shape": "record_list",
        "item_contract": "event_reference_item",
    }
elif mutation == "serialization_zero_min_items":
    data["event_serialization"]["field_contracts"]["evidence"]["min_items"] = 0
elif mutation == "serialization_selector_drift":
    data["event_serialization"]["record_contracts"]["security_approval"][
        "conditional_profile_value_map"
    ]["true"] = "not_required"
elif mutation == "serialization_value_contract_drift":
    data["event_serialization"]["field_contracts"]["event_id"][
        "value_contract"
    ] = "gate_id"
elif mutation == "phase_exit_policy_not_object":
    data["approval_policy"]["phase_exit"] = []
elif mutation == "deployment_policy_not_object":
    data["approval_policy"]["deployment"] = []
elif mutation == "project_closeout_policy_not_object":
    data["approval_policy"]["project_closeout"] = []
elif mutation == "value_prerequisite_not_object":
    data["deployment"]["value_prerequisite_contract"] = []
elif mutation == "coverage_policy_not_object":
    data["scaling"]["coverage_policy"] = []
elif mutation == "malformed_top_level_shape":
    data["paths"] = []
else:
    raise SystemExit(f"unknown mutation: {mutation}")

path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
}

run_mutation_case() {
  mutation="$1"
  expected_rule="$2"
  label="$3"
  reset_fixture
  mutate_registry "$mutation"
  run_validator --format human --mode candidate
  expect_rc 1 "$label rejects the mutation"
  expect_rule "$expected_rule" "$label"
}

# The checked-in candidate must be clean in both output formats.
run_validator --format human --mode candidate
expect_rc 0 "clean candidate validates in human format"
if printf '%s\n' "$CHECK_OUT" | grep -q 'Lifecycle coherence: clean'; then
  pass "human clean diagnostic is explicit"
else
  fail "human clean diagnostic is missing"
fi

run_validator --format json --mode candidate
expect_rc 0 "clean candidate validates in JSON format"
if printf '%s\n' "$CHECK_OUT" | grep -q '"status": "clean"'; then
  pass "JSON clean status is machine-readable"
else
  fail "JSON clean status is missing"
fi

# Planned WP-02+ delivery is valid for a candidate but blocks release mode.
run_validator --format human --mode release
expect_rc 1 "release mode rejects intentionally planned delivery"
expect_rule "LC-DELIVERY-001" "release delivery boundary"

# Generator output is byte-deterministic.
generated_one="$workdir/generated-one.sh"
generated_two="$workdir/generated-two.sh"
python3 "$generator" --registry "$registry" --output "$generated_one" > "$output" 2>&1
GEN_ONE_RC=$?
python3 "$generator" --registry "$registry" --output "$generated_two" > "$output" 2>&1
GEN_TWO_RC=$?
if [ "$GEN_ONE_RC" -eq 0 ] && [ "$GEN_TWO_RC" -eq 0 ] && cmp -s "$generated_one" "$generated_two"; then
  pass "generated lifecycle contract is byte-deterministic"
else
  fail "generated lifecycle contract is not byte-deterministic"
fi

bash -c '. "$1"; . "$1"' _ "$contract" > "$output" 2>&1
CONTRACT_RC=$?
if [ "$CONTRACT_RC" -eq 0 ]; then
  pass "generated lifecycle contract may be sourced twice idempotently"
else
  fail "generated lifecycle contract second source failed with RC=$CONTRACT_RC"
  sed 's/^/      /' "$output"
fi

bash -c 'GENDEV_LIFECYCLE_CONTRACT_LOADED=conflict; . "$1"' _ \
  "$contract" > "$output" 2>&1
CONTRACT_RC=$?
if [ "$CONTRACT_RC" -eq 2 ] && grep -q 'conflicting loaded contract' "$output"; then
  pass "generated lifecycle contract rejects a conflicting prior load"
else
  fail "generated lifecycle contract conflict guard failed (RC=$CONTRACT_RC)"
  sed 's/^/      /' "$output"
fi

contract_digest="$(
  sed -n "s/^readonly GENDEV_LIFECYCLE_CONTRACT_LOADED='\([^']*\)'.*/\1/p" "$contract"
)"
bash -c 'GENDEV_LIFECYCLE_CONTRACT_LOADED=$2; . "$1"' _ \
  "$contract" "$contract_digest" > "$output" 2>&1
CONTRACT_RC=$?
if [ "$CONTRACT_RC" -eq 2 ] && grep -q 'incomplete loaded contract' "$output"; then
  pass "generated lifecycle contract rejects an incomplete matching preseed"
else
  fail "generated lifecycle matching preseed guard failed (RC=$CONTRACT_RC)"
  sed 's/^/      /' "$output"
fi

bash -c 'readonly GENDEV_GATE_IDS=conflict; . "$1"' _ "$contract" > "$output" 2>&1
CONTRACT_RC=$?
if [ "$CONTRACT_RC" -eq 2 ] && grep -q 'conflicting GENDEV_GATE_IDS' "$output"; then
  pass "generated lifecycle contract rejects a conflicting public constant"
else
  fail "generated lifecycle constant conflict guard failed (RC=$CONTRACT_RC)"
  sed 's/^/      /' "$output"
fi

expect_contract_value "$contract" "phase_transition" \
  "approval string accessor projects delegation event type" \
  gendev_approval_string phase_exit delegation_event_type
expect_contract_value "$contract" "false" \
  "approval boolean accessor projects C3 delegation prohibition" \
  gendev_approval_boolean phase_exit c3_delegation_allowed
expect_contract_value "$contract" \
  "delegated_by delegated_to accepted_by scope starts_on ends_on" \
  "approval field accessor projects delegation evidence" \
  gendev_approval_fields phase_exit c1_c2_delegation_required_fields
expect_contract_value "$contract" "true" \
  "combined-gate accessor projects C3 prohibition" \
  gendev_combined_gate_rule c3_prohibited
expect_contract_value "$contract" "true" \
  "event-evidence accessor projects Git revision requirement" \
  gendev_event_evidence_revision_boolean must_resolve_in_git
expect_contract_value "$contract" "record_list" \
  "event serialization projects evidence field shape" \
  gendev_event_field_shape evidence
expect_contract_value "$contract" "event_evidence_item" \
  "event serialization projects evidence item contract" \
  gendev_event_field_item_contract evidence
expect_contract_value "$contract" "1" \
  "event serialization projects evidence minimum cardinality" \
  gendev_event_field_min_items evidence
expect_contract_value "$contract" "event_id_pattern" \
  "event serialization projects event-id value contract" \
  gendev_event_field_value_contract event_id
expect_contract_value "$contract" "supersedes_event_id correction_reason" \
  "event serialization projects common correction fields" \
  gendev_event_common_conditional_fields correction
expect_contract_value "$contract" "disposition details" \
  "event serialization projects value record fields" \
  gendev_event_record_required_fields value_review
expect_contract_value "$contract" \
  "trigger expected_date_when_knowable owner evidence_source next_review_mechanism" \
  "event serialization projects nested value profile" \
  gendev_event_record_conditional_fields value_review_details not_due
expect_contract_value "$contract" "record_list" \
  "event serialization projects nested field override" \
  gendev_event_record_field_shape value_review_details criterion_results
expect_contract_value "$contract" "value_review_details" \
  "event serialization projects nested item reference" \
  gendev_event_record_field_item_contract value_review details
expect_contract_value "$contract" "value_result_item" \
  "event serialization projects keyed value-result item contract" \
  gendev_event_record_field_item_contract value_review_details criterion_results
expect_contract_value "$contract" "1" \
  "event serialization projects nonempty keyed value-result list" \
  gendev_event_record_field_min_items value_review_details criterion_results
expect_contract_value "$contract" "1" \
  "event serialization projects nested list minimum cardinality" \
  gendev_event_record_field_min_items test_uat_execution command_results
expect_contract_value "$contract" "git_revision" \
  "event serialization projects nested revision value contract" \
  gendev_event_record_field_value_contract event_reference_item revision
expect_contract_value "$contract" "required" \
  "event serialization projects conditional profile selector" \
  gendev_event_record_conditional_profile_selector security_approval
expect_contract_value "$contract" "required" \
  "event serialization maps boolean selector value to profile" \
  gendev_event_record_conditional_profile_for_value security_approval true
expect_contract_value "$contract" "event_id" \
  "event serialization projects migration reference fields" \
  gendev_migration_reference_required_fields stable_event_id
expect_contract_value "$contract" "planned" \
  "event-history accessor projects enforcement state" \
  gendev_event_history_enforcement_string state
expect_contract_value "$contract" "true" \
  "reference-depth accessor projects exception requirement" \
  gendev_reference_depth_rule greater_depth_requires_exception
expect_contract_value "$contract" "true" \
  "manifest accessor projects terminal null-next invariant" \
  gendev_manifest_invariant_boolean MANIFEST-TERMINAL next_gate_must_be_null
expect_contract_value "$contract" \
  "disposition rationale scope release_candidate approver approved_on future_trigger_or_finality" \
  "deployment accessor projects non-deployment fields" \
  gendev_deployment_path_fields non_deployment required_fields
expect_contract_value "$contract" "operational_owner_confirmation" \
  "transition accessor projects deploy-only owner confirmation" \
  gendev_transition_conditional_event_fields G8 G9 deploy
expect_contract_value "$contract" "deploy" \
  "transition accessor enumerates deploy-only conditional profile" \
  gendev_transition_conditional_event_profiles G8 G9
expect_contract_value "$contract" "Draft" \
  "checkpoint accessor projects not-due value status" \
  gendev_checkpoint_reference_statuses_for_disposition \
  'G5.<id>.4' phase_value_review not_due
expect_contract_value "$contract" "true" \
  "artifact accessor projects provenance requirement" \
  gendev_artifact_provenance_required vision
expect_contract_value "$contract" "human_approval" \
  "role accessor projects named-human role kind" \
  gendev_role_kind named-human-approver
expect_contract_value "$contract" "true" \
  "role accessor projects named-human approval capability" \
  gendev_role_may_approve named-human-approver
expect_contract_value "$contract" \
  "trigger expected_date_when_knowable owner evidence_source next_review_mechanism" \
  "value-review accessor projects not-due evidence contract" \
  gendev_value_review_required_fields not_due
expect_contract_value "$contract" "value_result_item" \
  "value-review accessor projects complete result item contract" \
  gendev_value_review_item_contract complete
expect_contract_value "$contract" "deployment.criterion_ids" \
  "event-binding accessor projects criterion source" \
  gendev_event_binding_criterion_source deployment_approval_or_non_deployment_approval
expect_contract_value "$contract" \
  "project_identity_and_derived_from_canonical_source" \
  "reference accessor projects supporting identity contract" \
  gendev_reference_identity_contract supporting_design
expect_contract_value "$contract" \
  "All typed reference edges participate in one directed acyclic graph; approved depth exceptions do not permit cycles." \
  "reference accessor projects global acyclicity rule" \
  gendev_reference_rule REF-NO-CYCLE
expect_contract_value "$contract" "true" \
  "scaling accessor projects C3 unwanted-behavior requirement" \
  gendev_scaling_unwanted_behavior_required C3

expect_contract_rc "$contract" 2 "approval accessor rejects wrong arity" \
  gendev_approval_string phase_exit
expect_contract_rc "$contract" 2 "manifest accessor rejects wrong arity" \
  gendev_manifest_invariant_boolean MANIFEST-TERMINAL
expect_contract_rc "$contract" 2 "event serialization accessor rejects wrong arity" \
  gendev_event_record_conditional_fields value_review_details
expect_contract_rc "$contract" 2 "transition accessor rejects wrong arity" \
  gendev_transition_conditional_event_fields G8 G9
expect_contract_rc "$contract" 2 "checkpoint accessor rejects wrong arity" \
  gendev_checkpoint_reference_statuses_for_disposition \
  'G5.<id>.4' phase_value_review
expect_contract_rc "$contract" 2 "artifact accessor rejects wrong arity" \
  gendev_artifact_provenance_required

bash -c '
  . "$1"
  [[ PH-10-5-T020 =~ $GENDEV_TASK_ID_PATTERN ]] &&
    ! [[ PH-10-5-T20 =~ $GENDEV_TASK_ID_PATTERN ]] &&
    [[ PH-10-5-WS01 =~ $GENDEV_WORKSTREAM_ID_PATTERN ]] &&
    ! [[ PH-bad_phase-WS01 =~ $GENDEV_WORKSTREAM_ID_PATTERN ]] &&
    [[ 10-5 =~ $GENDEV_PHASE_ID_PATTERN ]] &&
    ! [[ bad_phase =~ $GENDEV_PHASE_ID_PATTERN ]] &&
    [[ G5.10-5.4 =~ $GENDEV_CHECKPOINT_PATTERN ]] &&
    ! [[ G5.bad_phase.4 =~ $GENDEV_CHECKPOINT_PATTERN ]]
' _ "$contract" > "$output" 2>&1
CONTRACT_RC=$?
if [ "$CONTRACT_RC" -eq 0 ]; then
  pass "generated POSIX ERE constants pass real Bash positive and negative matches"
else
  fail "generated POSIX ERE constants failed real Bash matching (RC=$CONTRACT_RC)"
fi

projection_registry="$workdir/projection-registry.json"
projection_contract="$workdir/projection-contract.sh"
python3 - "$registry" "$projection_registry" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
data["deployment"]["deploy_path"]["production_action_performed"] = False
terminal = next(
    item for item in data["manifest"]["invariants"]
    if item["id"] == "MANIFEST-TERMINAL"
)
terminal["next_gate_must_be_null"] = False
not_due = next(
    item for item in data["value_review_contract"]["dispositions"]
    if item["id"] == "not_due"
)
not_due["required_fields"].append("mutation_probe")
Path(sys.argv[2]).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
python3 "$generator" --registry "$projection_registry" \
  --output "$projection_contract" > "$output" 2>&1
PROJECTION_RC=$?
if [ "$PROJECTION_RC" -eq 0 ]; then
  pass "generator accepts a structurally valid projection mutation"
  expect_contract_value "$projection_contract" "false" \
    "deployment mutation reaches generated path accessor" \
    gendev_deployment_path_boolean deploy production_action_performed
  expect_contract_value "$projection_contract" "false" \
    "manifest mutation reaches generated invariant accessor" \
    gendev_manifest_invariant_boolean MANIFEST-TERMINAL next_gate_must_be_null
  expect_contract_value "$projection_contract" \
    "trigger expected_date_when_knowable owner evidence_source next_review_mechanism mutation_probe" \
    "value-review mutation reaches generated disposition accessor" \
    gendev_value_review_required_fields not_due
else
  fail "generator rejected a structurally valid projection mutation"
  sed 's/^/      /' "$output"
fi

CONTRACT_OUT="$(
  bash -c '. "$1"; shift; "$@"' _ \
    "$contract" \
    gendev_transition_artifact_evidence_categories \
    G7 G8 aggregate_remediation
)"
CONTRACT_RC=$?
if [ "$CONTRACT_RC" -eq 0 ] && [ "$CONTRACT_OUT" = "complete_report_unchanged" ]; then
  pass "generated 3-argument transition artifact lookup returns the registry value"
else
  fail "generated 3-argument transition artifact lookup failed (RC=$CONTRACT_RC, OUT=$CONTRACT_OUT)"
fi

bash -c '. "$1"; shift; "$@"' _ \
  "$contract" \
  gendev_transition_artifact_evidence_categories \
  G7 G8 missing-artifact > "$output" 2>&1
CONTRACT_RC=$?
if [ "$CONTRACT_RC" -eq 1 ]; then
  pass "generated transition artifact lookup returns RC=1 for an unknown key"
else
  fail "generated transition artifact lookup unknown-key RC is $CONTRACT_RC, expected 1"
fi

bash -c '. "$1"; shift; "$@"' _ \
  "$contract" \
  gendev_transition_artifact_evidence_categories \
  G7 G8 > "$output" 2>&1
CONTRACT_RC=$?
if [ "$CONTRACT_RC" -eq 2 ]; then
  pass "generated transition artifact lookup returns RC=2 for wrong arity"
else
  fail "generated transition artifact lookup wrong-arity RC is $CONTRACT_RC, expected 2"
fi

CONTRACT_OUT="$(
  bash -c '. "$1"; shift; "$@"' _ \
    "$contract" gendev_scaling_g2_required_any C1
)"
CONTRACT_RC=$?
if [ "$CONTRACT_RC" -eq 0 ] && \
  [ "$CONTRACT_OUT" = "G2-EARS-FORM G2-OBSERVABLE-FORM" ]; then
  pass "generated G2 scaling lookup preserves the C1 criterion alternative"
else
  fail "generated G2 C1 scaling lookup failed (RC=$CONTRACT_RC, OUT=$CONTRACT_OUT)"
fi

malformed_generator_registry="$workdir/generator-malformed.json"
python3 - "$registry" "$malformed_generator_registry" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
data["gates"][0]["name"] = 123
Path(sys.argv[2]).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
python3 "$generator" \
  --registry "$malformed_generator_registry" \
  --output "$workdir/should-not-generate.sh" > "$output" 2>&1
GENERATOR_BAD_RC=$?
if [ "$GENERATOR_BAD_RC" -eq 2 ]; then
  pass "generator returns RC=2 for a syntactically valid malformed registry"
else
  fail "generator malformed-registry RC is $GENERATOR_BAD_RC, expected 2"
  sed 's/^/      /' "$output"
fi

python3 "$generator" --registry "$registry" --check \
  --output "$workdir" > "$output" 2>&1
GENERATOR_DIRECTORY_RC=$?
if [ "$GENERATOR_DIRECTORY_RC" -eq 2 ]; then
  pass "generator --check returns RC=2 when output is a directory"
else
  fail "generator --check directory-output RC is $GENERATOR_DIRECTORY_RC, expected 2"
  sed 's/^/      /' "$output"
fi

missing_check_output="$workdir/missing-check-contract.sh"
python3 "$generator" --registry "$registry" --check \
  --output "$missing_check_output" > "$output" 2>&1
GENERATOR_MISSING_RC=$?
if [ "$GENERATOR_MISSING_RC" -eq 1 ]; then
  pass "generator --check returns RC=1 when output is missing"
else
  fail "generator --check missing-output RC is $GENERATOR_MISSING_RC, expected 1"
  sed 's/^/      /' "$output"
fi

run_mutation_case "duplicate_gate" "LC-UNIQUE-001" "duplicate gate"
run_mutation_case "invalid_transition" "LC-TRANSITION-001" "invalid transition cycle"
run_mutation_case "extra_skip_transition" "LC-TRANSITION-001" "extra skip transition"
run_mutation_case "duplicate_edge" "LC-TRANSITION-001" "duplicate transition edge"
run_mutation_case \
  "malformed_top_level_shape" \
  "LC-SCHEMA-001" \
  "syntactically valid malformed top-level shape"
run_mutation_case "missing_template" "LC-REFERENCE-001" "missing current template"
run_mutation_case "missing_lifecycle_owner" "LC-ARTIFACT-001" "missing lifecycle owner"
run_mutation_case \
  "incomplete_event_evidence_contract" \
  "LC-EVENT-001" \
  "incomplete D-012 event evidence contract"
run_mutation_case "weaken_d18_controls" "LC-APPROVAL-001" "weakened D-018 controls"
run_mutation_case \
  "remove_enforcement_ownership" \
  "LC-DELIVERY-001" \
  "removed enforcement ownership"
run_mutation_case \
  "premature_current_enforcement" \
  "LC-DELIVERY-001" \
  "premature current enforcement claim"
run_mutation_case \
  "weaken_event_predicate" \
  "LC-EVENT-001" \
  "weakened event-binding predicate"
run_mutation_case \
  "weaken_decision_invariants" \
  "LC-GATE-BINDING-001" \
  "weakened cross-decision invariants"
run_mutation_case \
  "misroute_decision_binding" \
  "LC-DECISION-001" \
  "misrouted decision mechanical binding"
run_mutation_case "wrong_g6_g7_binding" "LC-GATE-BINDING-001" "wrong G6/G7 binding"
run_mutation_case \
  "lost_final_phase_position" \
  "LC-GATE-BINDING-001" \
  "lost retained final phase position"
run_mutation_case \
  "invalid_nullable_checkpoint_field" \
  "LC-CHECKPOINT-001" \
  "invalid nullable checkpoint field"

# Missing project identity is a source mutation, not a registry mutation.
reset_fixture
vision_template="$fixture/docs/methodology/templates/vision-template.md"
sed '/^project:/d' "$vision_template" > "$workdir/vision-template.md"
mv "$workdir/vision-template.md" "$vision_template"
run_validator --format json --mode candidate
expect_rc 1 "missing project field rejects the template"
expect_rule "LC-TEMPLATE-PROJECT-001" "missing project field"

run_mutation_case "bad_fixed_path" "LC-FIXED-PATH-001" "bad fixed authority path"
run_mutation_case \
  "competing_supporting_directory" \
  "LC-SUPPORTING-DIR-001" \
  "competing supporting directory"
run_mutation_case "stale_version_target" "LC-VERSION-001" "stale candidate version target"
run_mutation_case \
  "bad_observation_revision" \
  "LC-VERSION-001" \
  "unresolvable baseline observation revision"
run_mutation_case \
  "premature_release_claim" \
  "LC-VERSION-001" \
  "premature candidate release claim"
run_mutation_case \
  "invalid_candidate_status" \
  "LC-VERSION-001" \
  "invalid candidate status vocabulary"
run_mutation_case \
  "fabricated_ratification_metadata" \
  "LC-DECISION-001" \
  "fabricated pre-ratification metadata"
run_mutation_case \
  "planned_without_work_package" \
  "LC-DELIVERY-001" \
  "unowned planned delivery marker"
run_mutation_case \
  "unbound_phase_exit_evidence" \
  "LC-PHASE-EXIT-001" \
  "unbound phase-exit evidence"
run_mutation_case "malformed_task_grammar" "LC-TASK-GRAMMAR-001" "malformed task grammar"
run_mutation_case \
  "non_posix_runtime_pattern" \
  "LC-TASK-GRAMMAR-001" \
  "non-POSIX runtime pattern"
run_mutation_case \
  "weaken_value_status_mapping" \
  "LC-PHASE-EXIT-001" \
  "weakened value disposition status mapping"
run_mutation_case \
  "weaken_phase_exit_delegation" \
  "LC-APPROVAL-001" \
  "weakened phase-exit delegation"
run_mutation_case \
  "weaken_deploy_owner_condition" \
  "LC-EVENT-001" \
  "weakened deploy-only operational owner binding"
run_mutation_case \
  "drift_gate_semantics" \
  "LC-GATE-BINDING-001" \
  "coordinated gate semantic drift"
run_mutation_case \
  "delete_checkpoint_evidence" \
  "LC-PHASE-EXIT-001" \
  "deleted phase-exit evidence class"
run_mutation_case \
  "delete_post_loop_contract" \
  "LC-GATE-BINDING-001" \
  "deleted post-loop artifact contract"
run_mutation_case \
  "misroute_transition_command" \
  "LC-TRANSITION-001" \
  "misrouted transition command"
run_mutation_case \
  "drift_artifact_semantics" \
  "LC-ARTIFACT-001" \
  "artifact ownership drift"
run_mutation_case \
  "coordinated_path_drift" \
  "LC-FIXED-PATH-001" \
  "coordinated canonical path drift"
run_mutation_case \
  "weaken_scaling_class" \
  "LC-GATE-BINDING-001" \
  "weakened D-017 class"
run_mutation_case \
  "weaken_scaffold_contract" \
  "LC-GATE-BINDING-001" \
  "weakened D-014 scaffold contract"
run_mutation_case \
  "weaken_manifest_terminal" \
  "LC-GATE-BINDING-001" \
  "weakened structured terminal invariant"
run_mutation_case \
  "replace_baseline_observation" \
  "LC-VERSION-001" \
  "coordinated baseline observation replacement"
run_mutation_case \
  "extend_vocabulary" \
  "LC-GATE-BINDING-001" \
  "unendorsed vocabulary extension"
run_mutation_case \
  "serialization_missing_field_shape" \
  "LC-EVENT-001" \
  "missing serialized event field shape"
run_mutation_case \
  "serialization_invalid_item_contract" \
  "LC-EVENT-001" \
  "invalid serialized nested item contract"
run_mutation_case \
  "serialization_evidence_source_drift" \
  "LC-EVENT-001" \
  "serialized evidence source drift"
run_mutation_case \
  "serialization_value_source_drift" \
  "LC-EVENT-001" \
  "serialized value source drift"
run_mutation_case \
  "serialization_migration_source_drift" \
  "LC-EVENT-001" \
  "serialized migration source drift"
run_mutation_case \
  "serialization_zero_min_items" \
  "LC-EVENT-001" \
  "zero serialized list minimum"
run_mutation_case \
  "serialization_selector_drift" \
  "LC-EVENT-001" \
  "serialized selector mapping drift"
run_mutation_case \
  "serialization_value_contract_drift" \
  "LC-EVENT-001" \
  "serialized scalar value-contract drift"

run_nested_shape_case() {
  mutation="$1"
  shape_label="$2"
  reset_fixture
  mutate_registry "$mutation"

  run_validator --format human --mode candidate
  expect_rc 1 "$shape_label is rejected in human format"
  expect_rule "LC-SCHEMA-001" "$shape_label human diagnostic"
  if ! printf '%s\n' "$CHECK_OUT" | grep -q 'Traceback'; then
    pass "$shape_label human diagnostic is traceback-free"
  else
    fail "$shape_label human diagnostic contains a traceback"
  fi

  run_validator --format json --mode candidate
  expect_rc 1 "$shape_label is rejected in JSON format"
  expect_rule "LC-SCHEMA-001" "$shape_label JSON diagnostic"
  if printf '%s\n' "$CHECK_OUT" | grep -q '"status": "findings"' && \
    ! printf '%s\n' "$CHECK_OUT" | grep -q 'Traceback'; then
    pass "$shape_label JSON diagnostic is machine-readable and traceback-free"
  else
    fail "$shape_label JSON diagnostic is not stable machine-readable output"
  fi
}

run_nested_shape_case \
  "phase_exit_policy_not_object" \
  "non-object phase-exit approval policy"
run_nested_shape_case \
  "deployment_policy_not_object" \
  "non-object deployment approval policy"
run_nested_shape_case \
  "project_closeout_policy_not_object" \
  "non-object project-closeout approval policy"
run_nested_shape_case \
  "value_prerequisite_not_object" \
  "non-object deployment value prerequisite"
run_nested_shape_case \
  "coverage_policy_not_object" \
  "non-object scaling coverage policy"

# A source-level edit to generated output must be detected independently.
reset_fixture
printf '\n# unauthorized edit\n' >> "$contract"
run_validator --format human --mode candidate
expect_rc 1 "generated contract mismatch is rejected"
expect_rule "LC-GENERATED-001" "generated contract mismatch"

# Public API names in comments must not satisfy anchored definition checks.
reset_fixture
python3 - "$fixture" "$registry" "$contract" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
registry_path = Path(sys.argv[2])
source_contract = Path(sys.argv[3])
template = root / "scripts/lib/lifecycle-comment-spoof.sh"
spoof = source_contract.read_text(encoding="utf-8").replace(
    "gendev_gate_name() {",
    "gendev_gate_name_removed() {",
    1,
)
spoof += "\n# gendev_gate_name() {\n"
template.write_text(spoof, encoding="utf-8")

generator_path = root / "scripts/comment-spoof-generator.py"
generator_path.write_text(
    """#!/usr/bin/env python3
import argparse
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--registry')
parser.add_argument('--output', required=True)
args = parser.parse_args()
source = Path(__file__).parent / 'lib/lifecycle-comment-spoof.sh'
Path(args.output).write_bytes(source.read_bytes())
""",
    encoding="utf-8",
)

data = json.loads(registry_path.read_text(encoding="utf-8"))
data["generation"]["generator"] = "scripts/comment-spoof-generator.py"
data["generation"]["output"] = "scripts/lib/lifecycle-comment-spoof.sh"
registry_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
run_validator --format human --mode candidate
expect_rc 1 "comment-spoofed API name is rejected"
expect_rule "LC-GENERATED-001" "comment-spoofed API name"

# Parser and invocation failures are configuration errors (RC=2), not findings.
reset_fixture
printf '{invalid json\n' > "$registry"
run_validator --format human --mode candidate
expect_rc 2 "malformed registry JSON is a parser failure"

python3 - "$registry_clean" "$workdir" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text(encoding="utf-8")
target = Path(sys.argv[2])
target.joinpath("duplicate-key.json").write_text(
    source.replace(
        '  "schema_version": 2,',
        '  "schema_version": 2,\n  "schema_version": 2,',
        1,
    ),
    encoding="utf-8",
)
target.joinpath("nan.json").write_text(
    source.replace('"schema_version": 2', '"schema_version": NaN', 1),
    encoding="utf-8",
)
target.joinpath("infinity.json").write_text(
    source.replace('"schema_version": 2', '"schema_version": Infinity', 1),
    encoding="utf-8",
)
PY

run_strict_json_case() {
  source="$1"
  label="$2"
  diagnostic="$3"
  cp "$source" "$registry"
  run_validator --format human --mode candidate
  expect_rc 2 "$label is a validator parser failure"
  if printf '%s\n' "$CHECK_OUT" | grep -q "$diagnostic" && \
    ! printf '%s\n' "$CHECK_OUT" | grep -q 'Traceback'; then
    pass "$label validator diagnostic is stable and traceback-free"
  else
    fail "$label validator diagnostic is missing or contains a traceback"
    printf '%s\n' "$CHECK_OUT" | sed 's/^/      /'
  fi

  python3 "$generator" --registry "$registry" \
    --output "$workdir/strict-json-output.sh" > "$output" 2>&1
  GENERATOR_STRICT_RC=$?
  if [ "$GENERATOR_STRICT_RC" -eq 2 ] && ! grep -q 'Traceback' "$output"; then
    pass "$label is rejected by the generator in caller scope (RC=2)"
  else
    fail "$label generator RC=$GENERATOR_STRICT_RC, expected traceback-free RC=2"
    sed 's/^/      /' "$output"
  fi
}

run_strict_json_case \
  "$workdir/duplicate-key.json" \
  "duplicate JSON object key" \
  "duplicate JSON object key"
run_strict_json_case \
  "$workdir/nan.json" \
  "JSON NaN constant" \
  "non-finite JSON number"
run_strict_json_case \
  "$workdir/infinity.json" \
  "JSON Infinity constant" \
  "non-finite JSON number"

reset_fixture
printf '\377' > "$registry"
run_validator --format json --mode candidate
expect_rc 2 "non-UTF-8 registry is a parser failure"
if printf '%s\n' "$CHECK_OUT" | grep -q '"status": "error"'; then
  pass "non-UTF-8 JSON parser failure is machine-readable"
else
  fail "non-UTF-8 JSON parser failure is not machine-readable"
fi

reset_fixture
python3 "$validator" \
  --root "$fixture" \
  --registry "$fixture/docs/methodology/schema/missing.json" \
  --format json > "$output" 2>&1
CHECK_RC=$?
CHECK_OUT="$(cat "$output")"
expect_rc 2 "missing registry is an invocation/configuration failure"
if printf '%s\n' "$CHECK_OUT" | grep -q '"status": "error"'; then
  pass "JSON configuration failure is machine-readable"
else
  fail "JSON configuration failure is not machine-readable"
fi

# Build an isolated release-ready repository, prove it is clean, then drift one
# synchronized live surface without changing the registry or generated contract.
make_release_ready_fixture
if [ "$RELEASE_GENERATE_RC" -eq 0 ]; then
  pass "release fixture generated its matching shell contract"
else
  fail "release fixture could not generate its matching shell contract"
  sed 's/^/      /' "$output"
fi
run_validator --format human --mode release
expect_rc 0 "fully resolved release fixture validates cleanly"

projection="$fixture/docs/methodology/templates/gate-log-template.md"
python3 - "$projection" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
owned = "Profile G8-to-G9:deploy: operational_owner_confirmation"
if owned not in text:
    raise RuntimeError("deploy-only projection profile is missing")
text = text.replace(owned, "Profile G8-to-G9:deploy:", 1)
text += "\n### unrelated_projection_probe\nFields: operational_owner_confirmation\n"
path.write_text(text, encoding="utf-8")
PY
run_validator --format human --mode release
expect_rc 1 "globally present deploy-only field outside its profile is rejected"
expect_rule "LC-EVENT-001" "profile-scoped event projection"

make_release_ready_fixture

projection="$fixture/docs/methodology/templates/gate-log-template.md"
python3 - "$projection" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
owned = "Fields: supersedes_event_id, correction_reason"
if owned not in text:
    raise RuntimeError("correction projection section is missing")
text = text.replace(owned, "Fields:", 1)
text += "\n### unrelated_correction_probe\nFields: supersedes_event_id, correction_reason\n"
path.write_text(text, encoding="utf-8")
PY
run_validator --format human --mode release
expect_rc 1 "globally present correction fields outside their section are rejected"
expect_rule "LC-EVENT-001" "correction-scoped event projection"

make_release_ready_fixture

python3 - "$fixture/docs/project-template/project.yaml" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = re.sub(r"(?m)^  loop_status:.*\n?", "", path.read_text(encoding="utf-8"))
path.write_text(text + "\nloop_status: not_started\n", encoding="utf-8")
PY
run_validator --format human --mode release
expect_rc 1 "wrong-hierarchy manifest field is rejected"
expect_rule "LC-PROJECT-TEMPLATE-001" "wrong-hierarchy manifest field"

make_release_ready_fixture

python3 - "$project_template" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text, count = re.subn(
    r"(?m)^(  current_gate:.*)$",
    r"\1\n  current_gate: G2",
    path.read_text(encoding="utf-8"),
    count=1,
)
if count != 1:
    raise RuntimeError("could not duplicate project.current_gate")
path.write_text(text, encoding="utf-8")
PY
run_validator --format human --mode release
expect_rc 1 "duplicate project.current_gate mapping is rejected"
expect_rule "LC-PROJECT-TEMPLATE-001" "duplicate project.current_gate mapping"

make_release_ready_fixture

python3 - "$project_template" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text, count = re.subn(
    r"(?m)^(  loop_status:.*)$",
    r"\1\n  loop_status: blocked",
    path.read_text(encoding="utf-8"),
    count=1,
)
if count != 1:
    raise RuntimeError("could not duplicate phase.loop_status")
path.write_text(text, encoding="utf-8")
PY
run_validator --format human --mode release
expect_rc 1 "duplicate phase.loop_status mapping is rejected"
expect_rule "LC-PROJECT-TEMPLATE-001" "duplicate phase.loop_status mapping"

make_release_ready_fixture

python3 - "$project_template" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text, count = re.subn(
    r"(?m)^  current_gate:",
    "\tcurrent_gate:",
    path.read_text(encoding="utf-8"),
    count=1,
)
if count != 1:
    raise RuntimeError("could not introduce a tab")
path.write_text(text, encoding="utf-8")
PY
run_validator --format human --mode release
expect_rc 1 "tab-indented manifest mapping is rejected"
expect_rule "LC-PROJECT-TEMPLATE-001" "tab-indented manifest mapping"

make_release_ready_fixture

python3 - "$project_template" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text, count = re.subn(
    r"(?m)^  current_gate:",
    "    current_gate:",
    path.read_text(encoding="utf-8"),
    count=1,
)
if count != 1:
    raise RuntimeError("could not introduce malformed indentation")
path.write_text(text, encoding="utf-8")
PY
run_validator --format human --mode release
expect_rc 1 "manifest indentation level skip is rejected"
expect_rule "LC-PROJECT-TEMPLATE-001" "manifest indentation level skip"

make_release_ready_fixture

python3 - "$registry" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
data["versions"]["synchronization_targets"] = [
    target
    for target in data["versions"]["synchronization_targets"]
    if target["source_file"] != "README.md"
]
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
python3 "$generator" --registry "$registry" --output "$contract" > "$output" 2>&1
run_validator --format human --mode release
expect_rc 1 "missing mandatory synchronization target is rejected"
expect_rule "LC-VERSION-001" "missing mandatory synchronization target"

make_release_ready_fixture
release_readme="$fixture/README.md"
sed 's/^Current methodology version:.*$/Current methodology version: `wrong-release`/' \
  "$release_readme" > "$workdir/release-readme.md"
mv "$workdir/release-readme.md" "$release_readme"
run_validator --format human --mode release
expect_rc 1 "release synchronization drift is rejected"
expect_rule "LC-VERSION-001" "release synchronization drift"

printf '\n%d passed, %d failed\n' "$pass_count" "$fail_count"
[ "$fail_count" -eq 0 ]
