#!/usr/bin/env python3
"""Generate the Bash 3 lifecycle contract from the canonical JSON registry."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Any, Iterable


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_REGISTRY = REPO_ROOT / "docs/methodology/schema/lifecycle.json"
DEFAULT_OUTPUT = REPO_ROOT / "scripts/lib/lifecycle-contract.sh"


class RegistryError(ValueError):
    """Raised when the registry cannot produce a safe shell contract."""


def reject_duplicate_object_pairs(
    pairs: list[tuple[str, Any]],
) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise RegistryError(f"duplicate JSON object key: {key}")
        result[key] = value
    return result


def reject_nonstandard_json_constant(value: str) -> None:
    raise RegistryError(f"non-standard JSON constant is forbidden: {value}")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate or verify the portable lifecycle shell contract."
    )
    parser.add_argument(
        "--registry",
        type=Path,
        default=DEFAULT_REGISTRY,
        help="lifecycle registry JSON (default: repository canonical registry)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help="generated shell contract (default: scripts/lib/lifecycle-contract.sh)",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit 1 instead of writing when the generated output is stale",
    )
    return parser.parse_args(argv)


def require_mapping(value: Any, location: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise RegistryError(f"{location} must be an object")
    return value


def require_list(value: Any, location: str) -> list[Any]:
    if not isinstance(value, list):
        raise RegistryError(f"{location} must be an array")
    return value


def require_text(value: Any, location: str, *, allow_empty: bool = False) -> str:
    if not isinstance(value, str) or (not allow_empty and not value):
        qualifier = "a string" if allow_empty else "a non-empty string"
        raise RegistryError(f"{location} must be {qualifier}")
    if any(ord(character) < 32 or ord(character) == 127 for character in value):
        raise RegistryError(f"{location} contains a forbidden control character")
    try:
        value.encode("utf-8")
    except UnicodeEncodeError as error:
        raise RegistryError(f"{location} is not valid UTF-8 text") from error
    return value


def require_string(value: Any, location: str) -> str:
    return require_text(value, location)


def optional_string(value: Any, location: str) -> str:
    if value is None:
        return ""
    return require_string(value, location)


def require_string_list(value: Any, location: str) -> list[str]:
    result = require_list(value, location)
    return [require_string(item, f"{location}[{index}]") for index, item in enumerate(result)]


def require_nonnegative_int(value: Any, location: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool) or value < 0:
        raise RegistryError(f"{location} must be a non-negative integer")
    return value


def require_bool(value: Any, location: str) -> bool:
    if not isinstance(value, bool):
        raise RegistryError(f"{location} must be a boolean")
    return value


def optional_bool(value: Any, location: str) -> bool | None:
    if value is None:
        return None
    return require_bool(value, location)


def bool_text(value: Any, location: str) -> str:
    return "true" if require_bool(value, location) else "false"


def shell_quote(value: str) -> str:
    value = require_text(value, "generated shell value", allow_empty=True)
    return "'" + value.replace("'", "'\"'\"'") + "'"


def shell_assignment(name: str, value: str) -> str:
    return "\n".join(
        (
            f"readonly {name}={shell_quote(value)} || {{",
            f"  printf '%s\\n' 'lifecycle contract: conflicting {name}' >&2",
            "  return 2 2>/dev/null || exit 2",
            "}",
        )
    )


def joined(values: Iterable[str]) -> str:
    return " ".join(values)


def case_function(
    name: str,
    cases: Iterable[tuple[str, str]],
    *,
    arguments: int = 1,
) -> list[str]:
    if arguments < 1:
        raise RegistryError(f"{name} must accept at least one argument")
    selector = '"' + ":".join(f"${index}" for index in range(1, arguments + 1)) + '"'
    lines = [f"{name}() {{", f"  [ \"$#\" -eq {arguments} ] || return 2", f"  case {selector} in"]
    for key, value in cases:
        lines.append(f"    {shell_quote(key)}) printf '%s\\n' {shell_quote(value)} ;;")
    lines.extend(["    *) return 1 ;;", "  esac", "}", ""])
    return lines


def get_records(registry: dict[str, Any], key: str) -> list[dict[str, Any]]:
    records = require_list(registry.get(key), key)
    result: list[dict[str, Any]] = []
    seen: set[str] = set()
    for index, raw_record in enumerate(records):
        record = require_mapping(raw_record, f"{key}[{index}]")
        record_id = require_string(record.get("id"), f"{key}[{index}].id")
        if record_id in seen:
            raise RegistryError(f"duplicate {key} id: {record_id}")
        seen.add(record_id)
        result.append(record)
    return result


def checkpoint_evidence_classes(checkpoint: dict[str, Any]) -> list[str]:
    checkpoint_id = require_string(checkpoint.get("id"), "checkpoint.id")
    bindings = require_list(
        checkpoint.get("required_evidence"),
        f"checkpoints.{checkpoint_id}.required_evidence",
    )
    classes: list[str] = []
    for index, raw_binding in enumerate(bindings):
        binding = require_mapping(
            raw_binding,
            f"checkpoints.{checkpoint_id}.required_evidence[{index}]",
        )
        classes.append(
            require_string(
                binding.get("class"),
                f"checkpoints.{checkpoint_id}.required_evidence[{index}].class",
            )
        )
    return classes


def nested_records(
    owner: dict[str, Any],
    field: str,
    location: str,
    identifier_field: str,
) -> list[dict[str, Any]]:
    values = require_list(owner.get(field, []), f"{location}.{field}")
    result: list[dict[str, Any]] = []
    seen: set[str] = set()
    for index, raw_value in enumerate(values):
        value = require_mapping(raw_value, f"{location}.{field}[{index}]")
        identifier = require_string(
            value.get(identifier_field),
            f"{location}.{field}[{index}].{identifier_field}",
        )
        if identifier in seen:
            raise RegistryError(
                f"duplicate {location}.{field} {identifier_field}: {identifier}"
            )
        seen.add(identifier)
        result.append(value)
    return result


def named_mappings(value: Any, location: str) -> list[tuple[str, dict[str, Any]]]:
    mapping = require_mapping(value, location)
    result: list[tuple[str, dict[str, Any]]] = []
    for raw_name, raw_record in mapping.items():
        name = require_string(raw_name, f"{location} key")
        result.append((name, require_mapping(raw_record, f"{location}.{name}")))
    return result


def build_contract(registry_bytes: bytes, registry: dict[str, Any]) -> bytes:
    schema_version = registry.get("schema_version")
    if schema_version != 2:
        raise RegistryError("schema_version must be 2")

    metadata = require_mapping(registry.get("registry"), "registry")
    versions = require_mapping(registry.get("versions"), "versions")
    vocabularies = require_mapping(registry.get("vocabularies"), "vocabularies")
    paths = require_mapping(registry.get("paths"), "paths")
    identifiers = require_mapping(registry.get("identifiers"), "identifiers")
    references = require_mapping(registry.get("references"), "references")
    scaling = require_mapping(registry.get("scaling"), "scaling")
    deployment = require_mapping(registry.get("deployment"), "deployment")
    compatibility = require_mapping(registry.get("compatibility"), "compatibility")
    approval_policy = require_mapping(
        registry.get("approval_policy"), "approval_policy"
    )
    manifest = require_mapping(registry.get("manifest"), "manifest")
    value_review_contract = require_mapping(
        registry.get("value_review_contract"), "value_review_contract"
    )
    ratification_contract = require_mapping(
        registry.get("ratification_contract"), "ratification_contract"
    )
    event_history = require_mapping(registry.get("event_history"), "event_history")
    event_reference_item = require_mapping(
        registry.get("event_reference_item"), "event_reference_item"
    )
    event_evidence_item = require_mapping(
        registry.get("event_evidence_item"), "event_evidence_item"
    )
    event_serialization = require_mapping(
        registry.get("event_serialization"), "event_serialization"
    )

    gates = get_records(registry, "gates")
    transitions = get_records(registry, "transitions")
    checkpoints = get_records(registry, "checkpoints")
    artifacts = get_records(registry, "artifacts")
    events = get_records(registry, "events")
    evidence_categories = get_records(registry, "evidence_categories")
    event_binding_rules = get_records(registry, "event_binding_rules")
    reference_rules = get_records(references, "rules")
    value_dispositions = get_records(value_review_contract, "dispositions")
    criteria = get_records(registry, "criteria")
    roles = get_records(registry, "roles")
    migration_events = [item for item in events if item["id"] == "migration_reconciliation"]
    if len(migration_events) != 1:
        raise RegistryError("events must contain exactly one migration_reconciliation")
    migration_event = migration_events[0]
    migration_reference_contract = require_mapping(
        migration_event.get("historical_event_reference_contract"),
        "events.migration_reconciliation.historical_event_reference_contract",
    )
    migration_reference_fields = require_mapping(
        migration_reference_contract.get("required_fields_by_kind"),
        "events.migration_reconciliation."
        "historical_event_reference_contract.required_fields_by_kind",
    )
    migration_approval_rules = require_mapping(
        migration_event.get("approval_rules"),
        "events.migration_reconciliation.approval_rules",
    )

    digest = hashlib.sha256(registry_bytes).hexdigest()
    candidate = require_string(versions.get("candidate"), "versions.candidate")
    registry_status = require_string(metadata.get("status"), "registry.status")
    registry_id = require_string(metadata.get("id"), "registry.id")

    artifact_statuses = require_string_list(
        vocabularies.get("artifact_statuses"), "vocabularies.artifact_statuses"
    )
    gate_statuses = require_string_list(
        vocabularies.get("gate_statuses"), "vocabularies.gate_statuses"
    )
    project_statuses = require_string_list(
        vocabularies.get("project_statuses"), "vocabularies.project_statuses"
    )
    phase_loop_statuses = require_string_list(
        vocabularies.get("phase_loop_statuses"), "vocabularies.phase_loop_statuses"
    )
    phase_statuses = require_string_list(
        vocabularies.get("phase_statuses"), "vocabularies.phase_statuses"
    )
    approval_decisions = require_string_list(
        vocabularies.get("approval_decisions"), "vocabularies.approval_decisions"
    )
    remediation_dispositions = require_string_list(
        vocabularies.get("remediation_dispositions"),
        "vocabularies.remediation_dispositions",
    )
    value_review_dispositions = require_string_list(
        vocabularies.get("value_review_dispositions"),
        "vocabularies.value_review_dispositions",
    )
    value_results = require_string_list(
        vocabularies.get("value_results"), "vocabularies.value_results"
    )
    enforcement_classes = require_string_list(
        vocabularies.get("enforcement_classes"), "vocabularies.enforcement_classes"
    )
    blast_radius_classes = require_string_list(
        vocabularies.get("blast_radius_classes"), "vocabularies.blast_radius_classes"
    )

    canonical_directories = require_string_list(
        paths.get("canonical_directories"), "paths.canonical_directories"
    )
    forbidden_directories = require_string_list(
        paths.get("forbidden_competing_directories"),
        "paths.forbidden_competing_directories",
    )

    task = require_mapping(identifiers.get("task"), "identifiers.task")
    workstream = require_mapping(identifiers.get("workstream"), "identifiers.workstream")
    phase_id = require_mapping(identifiers.get("phase_id"), "identifiers.phase_id")
    checkpoint = require_mapping(identifiers.get("checkpoint"), "identifiers.checkpoint")
    event_id = require_mapping(identifiers.get("event_id"), "identifiers.event_id")
    reference_relationships = require_string_list(
        references.get("relationships"), "references.relationships"
    )
    deployment_intents = require_string_list(
        deployment.get("intents"), "deployment.intents"
    )
    reference_depth = require_mapping(references.get("depth_policy"), "references.depth_policy")
    reference_enforcement = require_mapping(
        references.get("enforcement"), "references.enforcement"
    )
    approval_profiles = named_mappings(approval_policy, "approval_policy")
    combined_gate_rules = require_mapping(
        scaling.get("combined_gate_rules"), "scaling.combined_gate_rules"
    )
    coverage_policy = require_mapping(
        scaling.get("coverage_policy"), "scaling.coverage_policy"
    )
    manifest_field_states = named_mappings(
        manifest.get("field_states", {}), "manifest.field_states"
    )
    manifest_invariants = nested_records(
        manifest, "invariants", "manifest", "id"
    )
    event_evidence_conditional_fields = require_mapping(
        event_evidence_item.get("conditional_fields", {}),
        "event_evidence_item.conditional_fields",
    )
    event_evidence_revision_rules = require_mapping(
        event_evidence_item.get("revision_rules"),
        "event_evidence_item.revision_rules",
    )
    event_field_contracts = named_mappings(
        event_serialization.get("field_contracts"),
        "event_serialization.field_contracts",
    )
    event_record_contracts = named_mappings(
        event_serialization.get("record_contracts"),
        "event_serialization.record_contracts",
    )
    event_common_conditional_fields = require_mapping(
        event_serialization.get("common_conditional_field_sets"),
        "event_serialization.common_conditional_field_sets",
    )
    event_default_scalar_value_contract = require_string(
        event_serialization.get("default_scalar_value_contract"),
        "event_serialization.default_scalar_value_contract",
    )
    event_history_enforcement = require_mapping(
        event_history.get("enforcement"), "event_history.enforcement"
    )
    g2_criterion_forms = require_mapping(
        scaling.get("g2_criterion_form_by_class"),
        "scaling.g2_criterion_form_by_class",
    )
    deployment_requirements = nested_records(
        deployment,
        "artifact_requirements",
        "deployment",
        "artifact_id",
    )
    deployment_value_contract = require_mapping(
        deployment.get("value_prerequisite_contract"),
        "deployment.value_prerequisite_contract",
    )
    deployment_correlations = nested_records(
        deployment,
        "terminal_correlations",
        "deployment",
        "authorization_intent",
    )
    deployment_paths = [
        (
            "deploy",
            require_mapping(deployment.get("deploy_path"), "deployment.deploy_path"),
        ),
        (
            "non_deployment",
            require_mapping(
                deployment.get("non_deployment_path"),
                "deployment.non_deployment_path",
            ),
        ),
    ]
    compatibility_scaffold = require_mapping(
        compatibility.get("scaffold"), "compatibility.scaffold"
    )

    lines = [
        "#!/bin/bash",
        "# Generated by scripts/generate-lifecycle-contract.py. Do not edit.",
        "# This file deliberately uses only syntax available in macOS Bash 3.2.",
        "",
        'if [ "${GENDEV_LIFECYCLE_CONTRACT_LOADED+x}" = x ]; then',
        f"  if [ \"$GENDEV_LIFECYCLE_CONTRACT_LOADED\" = {shell_quote(digest)} ]; then",
        f"    if [ \"${{GENDEV_LIFECYCLE_REGISTRY_SHA256:-}}\" = {shell_quote(digest)} ] && command -v gendev_gate_name >/dev/null 2>&1; then",
        "      return 0 2>/dev/null || exit 0",
        "    fi",
        "    printf '%s\\n' 'lifecycle contract: incomplete loaded contract' >&2",
        "    return 2 2>/dev/null || exit 2",
        "  fi",
        "  printf '%s\\n' 'lifecycle contract: conflicting loaded contract' >&2",
        "  return 2 2>/dev/null || exit 2",
        "fi",
        "",
        shell_assignment("GENDEV_LIFECYCLE_REGISTRY_ID", registry_id),
        shell_assignment("GENDEV_LIFECYCLE_SCHEMA_VERSION", str(schema_version)),
        shell_assignment("GENDEV_LIFECYCLE_REGISTRY_STATUS", registry_status),
        shell_assignment("GENDEV_LIFECYCLE_TARGET_VERSION", candidate),
        shell_assignment("GENDEV_LIFECYCLE_REGISTRY_SHA256", digest),
        shell_assignment("GENDEV_GATE_IDS", joined(require_string(gate["id"], "gate.id") for gate in gates)),
        shell_assignment("GENDEV_TERMINAL_GATE", require_string(gates[-1].get("id"), "gates[-1].id")),
        shell_assignment("GENDEV_CHECKPOINT_TEMPLATES", joined(require_string(item["id"], "checkpoint.id") for item in checkpoints)),
        shell_assignment("GENDEV_EVENT_TYPES", joined(require_string(item["id"], "event.id") for item in events)),
        shell_assignment("GENDEV_ARTIFACT_IDS", joined(require_string(item["id"], "artifact.id") for item in artifacts)),
        shell_assignment("GENDEV_ARTIFACT_STATUSES", "|".join(artifact_statuses)),
        shell_assignment("GENDEV_GATE_STATUSES", joined(gate_statuses)),
        shell_assignment("GENDEV_PROJECT_STATUSES", joined(project_statuses)),
        shell_assignment("GENDEV_PHASE_LOOP_STATUSES", joined(phase_loop_statuses)),
        shell_assignment("GENDEV_PHASE_STATUSES", joined(phase_statuses)),
        shell_assignment("GENDEV_APPROVAL_DECISIONS", joined(approval_decisions)),
        shell_assignment("GENDEV_REMEDIATION_DISPOSITIONS", joined(remediation_dispositions)),
        shell_assignment("GENDEV_VALUE_REVIEW_DISPOSITIONS", joined(value_review_dispositions)),
        shell_assignment("GENDEV_VALUE_RESULTS", joined(value_results)),
        shell_assignment("GENDEV_ENFORCEMENT_CLASSES", joined(enforcement_classes)),
        shell_assignment("GENDEV_VALUE_REVIEW_ARTIFACT_STATUS_IS_SEPARATE_FROM_DISPOSITION", bool_text(value_review_contract.get("artifact_status_is_separate_from_disposition"), "value_review_contract.artifact_status_is_separate_from_disposition")),
        shell_assignment("GENDEV_VALUE_REVIEW_UNOWNED_FUTURE_WORK_IS_INVALID", bool_text(value_review_contract.get("unowned_future_work_is_invalid"), "value_review_contract.unowned_future_work_is_invalid")),
        shell_assignment("GENDEV_VALUE_REVIEW_UNMEASURABLE_IS_NOT_SUCCESS", bool_text(value_review_contract.get("unmeasurable_is_not_success"), "value_review_contract.unmeasurable_is_not_success")),
        shell_assignment("GENDEV_BLAST_RADIUS_CLASSES", joined(blast_radius_classes)),
        shell_assignment("GENDEV_EVIDENCE_CATEGORIES", joined(require_string(item["id"], "evidence_category.id") for item in evidence_categories)),
        shell_assignment("GENDEV_CRITERION_IDS", joined(require_string(item["id"], "criterion.id") for item in criteria)),
        shell_assignment("GENDEV_ROLE_IDS", joined(require_string(item["id"], "role.id") for item in roles)),
        shell_assignment("GENDEV_CANONICAL_DIRECTORIES", joined(canonical_directories)),
        shell_assignment("GENDEV_FORBIDDEN_DIRECTORIES", joined(forbidden_directories)),
        shell_assignment("GENDEV_REFERENCE_RELATIONSHIPS", joined(reference_relationships)),
        shell_assignment("GENDEV_DEPLOYMENT_INTENTS", joined(deployment_intents)),
        shell_assignment("GENDEV_APPROVAL_POLICY_IDS", joined(name for name, _ in approval_profiles)),
        shell_assignment("GENDEV_EVENT_BINDING_RULE_IDS", joined(require_string(item["id"], "event_binding_rule.id") for item in event_binding_rules)),
        shell_assignment("GENDEV_EVENT_CORRECTION_FIELDS", joined(require_string_list(event_history.get("correction_fields"), "event_history.correction_fields"))),
        shell_assignment("GENDEV_EVENT_HISTORY_ENFORCEMENT_BEHAVIORS", joined(require_string_list(event_history_enforcement.get("required_behaviors"), "event_history.enforcement.required_behaviors"))),
        shell_assignment("GENDEV_EVENT_REFERENCE_FIELDS", joined(require_string_list(event_reference_item.get("required_fields"), "event_reference_item.required_fields"))),
        shell_assignment("GENDEV_EVENT_REFERENCE_DIGEST_ALGORITHM", require_string(event_reference_item.get("portable_digest_algorithm"), "event_reference_item.portable_digest_algorithm")),
        shell_assignment("GENDEV_EVENT_REFERENCE_CANNOT_SATISFY_ACCEPTANCE", bool_text(event_reference_item.get("cannot_satisfy_acceptance_without_evidence_category"), "event_reference_item.cannot_satisfy_acceptance_without_evidence_category")),
        shell_assignment("GENDEV_EVENT_EVIDENCE_FIELDS", joined(require_string_list(event_evidence_item.get("required_fields"), "event_evidence_item.required_fields"))),
        shell_assignment("GENDEV_EVENT_EVIDENCE_CONDITIONS", joined(require_string(name, "event_evidence_item.conditional_fields key") for name in event_evidence_conditional_fields)),
        shell_assignment("GENDEV_EVENT_SERIALIZATION_PROFILE", require_string(event_serialization.get("profile"), "event_serialization.profile")),
        shell_assignment("GENDEV_EVENT_SERIALIZATION_SCHEMA_VERSION", str(require_nonnegative_int(event_serialization.get("schema_version"), "event_serialization.schema_version"))),
        shell_assignment("GENDEV_EVENT_FIELD_IDS", joined(name for name, _ in event_field_contracts)),
        shell_assignment("GENDEV_EVENT_RECORD_CONTRACT_IDS", joined(name for name, _ in event_record_contracts)),
        shell_assignment("GENDEV_EVENT_COMMON_CONDITIONAL_PROFILES", joined(require_string(name, "event_serialization.common_conditional_field_sets key") for name in event_common_conditional_fields)),
        shell_assignment("GENDEV_EVENT_DEFAULT_SCALAR_VALUE_CONTRACT", event_default_scalar_value_contract),
        shell_assignment("GENDEV_DEPLOYMENT_REQUIRED_ARTIFACTS", joined(require_string(item["artifact_id"], "deployment.artifact_requirements.artifact_id") for item in deployment_requirements)),
        shell_assignment("GENDEV_DEPLOYMENT_CRITERION_IDS", joined(require_string_list(deployment.get("criterion_ids"), "deployment.criterion_ids"))),
        shell_assignment("GENDEV_DEPLOYMENT_VALUE_PREREQUISITE_FIELDS", joined(require_string_list(deployment_value_contract.get("required_fields"), "deployment.value_prerequisite_contract.required_fields"))),
        shell_assignment("GENDEV_DEPLOYMENT_VALUE_CONTRACT", require_string(deployment_value_contract.get("contract"), "deployment.value_prerequisite_contract.contract")),
        shell_assignment("GENDEV_DEPLOYMENT_AUTHORIZATION_EVENT", require_string(deployment.get("authorization_event"), "deployment.authorization_event")),
        shell_assignment("GENDEV_DEPLOYMENT_TERMINAL_TRANSITION", require_string(deployment.get("terminal_transition"), "deployment.terminal_transition")),
        shell_assignment("GENDEV_DEPLOYMENT_NONDEPLOYMENT_REQUIRED_FIELDS", joined(require_string_list(require_mapping(deployment.get("non_deployment_path"), "deployment.non_deployment_path").get("required_fields"), "deployment.non_deployment_path.required_fields"))),
        shell_assignment("GENDEV_COMBINED_GATE_REQUIRED_FIELDS", joined(require_string_list(scaling.get("combined_gate_required_fields"), "scaling.combined_gate_required_fields"))),
        shell_assignment("GENDEV_COVERAGE_REQUIRED_FIELDS", joined(require_string_list(coverage_policy.get("required_fields"), "scaling.coverage_policy.required_fields"))),
        shell_assignment("GENDEV_MANIFEST_REQUIRED_FIELDS", joined(require_string_list(manifest.get("required_fields"), "manifest.required_fields"))),
        shell_assignment("GENDEV_MANIFEST_INVARIANT_IDS", joined(require_string(item["id"], "manifest.invariant.id") for item in manifest_invariants)),
        shell_assignment("GENDEV_MANIFEST_SCHEMA_VERSION", str(require_nonnegative_int(manifest.get("schema_version"), "manifest.schema_version"))),
        shell_assignment("GENDEV_MANIFEST_SOURCE_FILE", require_string(manifest.get("source_file"), "manifest.source_file")),
        shell_assignment("GENDEV_MANIFEST_CONTRACT_STATE", require_string(manifest.get("contract_state"), "manifest.contract_state")),
        shell_assignment("GENDEV_MANIFEST_REQUIRED_WORK_PACKAGE", require_string(manifest.get("required_work_package"), "manifest.required_work_package")),
        shell_assignment("GENDEV_REFERENCE_DEPTH_EXCEPTION_FIELDS", joined(require_string_list(reference_depth.get("exception_required_fields"), "references.depth_policy.exception_required_fields"))),
        shell_assignment("GENDEV_REFERENCE_RULE_IDS", joined(require_string(item["id"], "references.rules.id") for item in reference_rules)),
        shell_assignment("GENDEV_REFERENCE_ENFORCEMENT_REQUIRED_RULE_IDS", joined(require_string_list(reference_enforcement.get("required_rule_ids"), "references.enforcement.required_rule_ids"))),
        shell_assignment("GENDEV_RATIFICATION_REVIEWED_STATUS", require_string(ratification_contract.get("reviewed_status"), "ratification_contract.reviewed_status")),
        shell_assignment("GENDEV_RATIFICATION_RESULTING_STATUS", require_string(ratification_contract.get("resulting_status"), "ratification_contract.resulting_status")),
        shell_assignment("GENDEV_RATIFICATION_EVIDENCE_CATEGORY", require_string(ratification_contract.get("evidence_category"), "ratification_contract.evidence_category")),
        shell_assignment("GENDEV_REFERENCE_DEFAULT_SUPPORTING_DEPTH", str(require_nonnegative_int(reference_depth.get("default_supporting_depth"), "references.depth_policy.default_supporting_depth"))),
        shell_assignment("GENDEV_PHASE_ID_PATTERN", require_string(phase_id.get("pattern"), "identifiers.phase_id.pattern")),
        shell_assignment("GENDEV_WORKSTREAM_ID_PATTERN", require_string(workstream.get("pattern"), "identifiers.workstream.pattern")),
        shell_assignment("GENDEV_TASK_ID_PATTERN", require_string(task.get("pattern"), "identifiers.task.pattern")),
        shell_assignment("GENDEV_CHECKPOINT_PATTERN", require_string(checkpoint.get("pattern"), "identifiers.checkpoint.pattern")),
        shell_assignment("GENDEV_EVENT_ID_PATTERN", require_string(event_id.get("pattern"), "identifiers.event_id.pattern")),
        shell_assignment("GENDEV_TASK_IMMUTABLE_AFTER_STATUS", require_string(task.get("immutable_after_status"), "identifiers.task.immutable_after_status")),
        shell_assignment("GENDEV_TASK_REUSE_RETIRED_IDS", bool_text(task.get("reuse_retired_ids"), "identifiers.task.reuse_retired_ids")),
        shell_assignment("GENDEV_WORKSTREAM_IMMUTABLE_AFTER_STATUS", require_string(workstream.get("immutable_after_status"), "identifiers.workstream.immutable_after_status")),
        shell_assignment("GENDEV_WORKSTREAM_REUSE_RETIRED_IDS", bool_text(workstream.get("reuse_retired_ids"), "identifiers.workstream.reuse_retired_ids")),
        shell_assignment("GENDEV_COMPATIBILITY_NEW_PROJECT_MODE", require_string(compatibility.get("new_project_mode"), "compatibility.new_project_mode")),
        shell_assignment("GENDEV_COMPATIBILITY_LEGACY_MODE", require_string(compatibility.get("legacy_mode"), "compatibility.legacy_mode")),
        shell_assignment("GENDEV_COMPATIBILITY_LEGACY_EVENT_POLICY", require_string(compatibility.get("legacy_event_policy"), "compatibility.legacy_event_policy")),
        shell_assignment("GENDEV_COMPATIBILITY_NEW_EVENTS_IN_LEGACY_MODE", require_string(compatibility.get("new_events_in_legacy_mode"), "compatibility.new_events_in_legacy_mode")),
        shell_assignment("GENDEV_COMPATIBILITY_AUTOMATIC_GATE_REGRESSION", bool_text(compatibility.get("automatic_gate_regression"), "compatibility.automatic_gate_regression")),
        shell_assignment("GENDEV_COMPATIBILITY_SCAFFOLD_FRESH_INIT", require_string(compatibility_scaffold.get("fresh_init"), "compatibility.scaffold.fresh_init")),
        shell_assignment("GENDEV_COMPATIBILITY_SCAFFOLD_PHASE_COMMAND", require_string(compatibility_scaffold.get("phase_scaffold_command"), "compatibility.scaffold.phase_scaffold_command")),
        shell_assignment("GENDEV_COMPATIBILITY_SCAFFOLD_STATE", require_string(compatibility_scaffold.get("phase_scaffold_state"), "compatibility.scaffold.phase_scaffold_state")),
        shell_assignment("GENDEV_COMPATIBILITY_SCAFFOLD_REQUIRED_WORK_PACKAGE", require_string(compatibility_scaffold.get("required_work_package"), "compatibility.scaffold.required_work_package")),
        shell_assignment("GENDEV_COMPATIBILITY_SCAFFOLD_SEED_PHASE_OPTION", require_string(compatibility_scaffold.get("seed_phase_option"), "compatibility.scaffold.seed_phase_option")),
        shell_assignment("GENDEV_COMPATIBILITY_SCAFFOLD_SEED_PHASE_MUST_BE_COMPLETE", bool_text(compatibility_scaffold.get("seed_phase_must_be_complete"), "compatibility.scaffold.seed_phase_must_be_complete")),
        shell_assignment("GENDEV_MIGRATION_ALLOWED_DECISIONS", joined(require_string_list(migration_event.get("allowed_decisions"), "events.migration_reconciliation.allowed_decisions"))),
        shell_assignment("GENDEV_MIGRATION_REFERENCE_KINDS", joined(require_string_list(migration_reference_contract.get("allowed_kinds"), "events.migration_reconciliation.historical_event_reference_contract.allowed_kinds"))),
        shell_assignment("GENDEV_MIGRATION_REFERENCE_DIGEST_ALGORITHM", require_string(migration_reference_contract.get("digest_algorithm"), "events.migration_reconciliation.historical_event_reference_contract.digest_algorithm")),
        shell_assignment("GENDEV_MIGRATION_LINE_NUMBER_ONLY_FORBIDDEN", bool_text(migration_reference_contract.get("line_number_only_forbidden"), "events.migration_reconciliation.historical_event_reference_contract.line_number_only_forbidden")),
        shell_assignment("GENDEV_MIGRATION_NAMED_HUMAN_REQUIRED_WHEN", joined(require_string_list(migration_approval_rules.get("named_human_required_when"), "events.migration_reconciliation.approval_rules.named_human_required_when"))),
        shell_assignment("GENDEV_MIGRATION_CRITICAL_UNCERTAINTY_WAIVABLE", bool_text(migration_approval_rules.get("critical_security_or_approval_uncertainty_waivable"), "events.migration_reconciliation.approval_rules.critical_security_or_approval_uncertainty_waivable")),
        shell_assignment("GENDEV_MIGRATION_AUTOMATION_MAY_APPROVE", bool_text(migration_approval_rules.get("automation_or_unbound_role_may_approve"), "events.migration_reconciliation.approval_rules.automation_or_unbound_role_may_approve")),
        shell_assignment("GENDEV_MIGRATION_UNRESOLVED_FIELDS_PROPAGATE_TO_READINESS", bool_text(migration_event.get("unresolved_fields_propagate_to_readiness"), "events.migration_reconciliation.unresolved_fields_propagate_to_readiness")),
        shell_assignment("GENDEV_MIGRATION_DUPLICATE_MAPPING_REQUIRES_SUPERSEDES", bool_text(migration_event.get("duplicate_mapping_requires_supersedes_event_id"), "events.migration_reconciliation.duplicate_mapping_requires_supersedes_event_id")),
        "",
        "gendev_list_contains() {",
        "  [ \"$#\" -eq 2 ] || return 2",
        "  case \" $1 \" in",
        "    *\" $2 \"*) return 0 ;;",
        "    *) return 1 ;;",
        "  esac",
        "}",
        "",
    ]

    approval_string_cases: list[tuple[str, str]] = []
    approval_boolean_cases: list[tuple[str, str]] = []
    approval_field_cases: list[tuple[str, str]] = []
    approval_string_fields = {
        "approver_kind",
        "delegation_event_type",
        "delegation_event_profile",
        "delegation_event_field",
    }
    approval_list_fields = {
        "c1_c2_delegation_required_fields",
        "delegation_allowed_classes",
        "delegation_prohibited_classes",
    }
    for profile, policy in approval_profiles:
        for raw_field, value in policy.items():
            field = require_string(raw_field, f"approval_policy.{profile} key")
            key = f"{profile}:{field}"
            if field in approval_string_fields:
                approval_string_cases.append(
                    (key, require_string(value, f"approval_policy.{profile}.{field}"))
                )
            elif field in approval_list_fields:
                approval_field_cases.append(
                    (
                        key,
                        joined(
                            require_string_list(
                                value, f"approval_policy.{profile}.{field}"
                            )
                        ),
                    )
                )
            else:
                approval_boolean_cases.append(
                    (key, bool_text(value, f"approval_policy.{profile}.{field}"))
                )
    lines.extend(
        case_function("gendev_approval_string", approval_string_cases, arguments=2)
    )
    lines.extend(
        case_function("gendev_approval_boolean", approval_boolean_cases, arguments=2)
    )
    lines.extend(
        case_function("gendev_approval_fields", approval_field_cases, arguments=2)
    )
    lines.extend(
        case_function(
            "gendev_approval_approver_kind",
            (
                (
                    profile,
                    require_string(
                        policy.get("approver_kind"),
                        f"approval_policy.{profile}.approver_kind",
                    ),
                )
                for profile, policy in approval_profiles
            ),
        )
    )

    lines.extend(
        case_function(
            "gendev_combined_gate_rule",
            (
                (
                    require_string(field, "scaling.combined_gate_rules key"),
                    bool_text(
                        value, f"scaling.combined_gate_rules.{field}"
                    ),
                )
                for field, value in combined_gate_rules.items()
            ),
        )
    )
    coverage_percentage = coverage_policy.get("universal_percentage")
    if coverage_percentage is None:
        coverage_percentage_text = ""
    else:
        coverage_percentage_text = str(
            require_nonnegative_int(
                coverage_percentage,
                "scaling.coverage_policy.universal_percentage",
            )
        )
    lines.extend(
        [
            shell_assignment(
                "GENDEV_COVERAGE_UNIVERSAL_PERCENTAGE", coverage_percentage_text
            ),
            shell_assignment(
                "GENDEV_COVERAGE_SHORTFALL_REQUIRES_NAMED_RISK_ACCEPTANCE",
                bool_text(
                    coverage_policy.get(
                        "shortfall_requires_named_risk_acceptance"
                    ),
                    "scaling.coverage_policy."
                    "shortfall_requires_named_risk_acceptance",
                ),
            ),
            "",
        ]
    )

    lines.extend(
        case_function(
            "gendev_event_evidence_conditional_fields",
            (
                (
                    require_string(
                        condition,
                        "event_evidence_item.conditional_fields key",
                    ),
                    joined(
                        require_string_list(
                            fields,
                            f"event_evidence_item.conditional_fields.{condition}",
                        )
                    ),
                )
                for condition, fields in event_evidence_conditional_fields.items()
            ),
        )
    )
    evidence_revision_string_cases: list[tuple[str, str]] = []
    evidence_revision_boolean_cases: list[tuple[str, str]] = []
    for raw_field, value in event_evidence_revision_rules.items():
        field = require_string(raw_field, "event_evidence_item.revision_rules key")
        if field == "portable_digest_algorithm":
            evidence_revision_string_cases.append(
                (
                    field,
                    require_string(
                        value, f"event_evidence_item.revision_rules.{field}"
                    ),
                )
            )
        else:
            evidence_revision_boolean_cases.append(
                (
                    field,
                    bool_text(
                        value, f"event_evidence_item.revision_rules.{field}"
                    ),
                )
            )
    lines.extend(
        case_function(
            "gendev_event_evidence_revision_string", evidence_revision_string_cases
        )
    )
    lines.extend(
        case_function(
            "gendev_event_evidence_revision_boolean",
            evidence_revision_boolean_cases,
        )
    )

    event_field_shape_cases: list[tuple[str, str]] = []
    event_field_item_cases: list[tuple[str, str]] = []
    event_field_min_items_cases: list[tuple[str, str]] = []
    event_field_value_contract_cases: list[tuple[str, str]] = []
    allowed_event_shapes = {"scalar", "scalar_list", "record", "record_list"}
    for field, contract in event_field_contracts:
        shape = require_string(
            contract.get("shape"), f"event_serialization.field_contracts.{field}.shape"
        )
        if shape not in allowed_event_shapes:
            raise RegistryError(
                f"event_serialization.field_contracts.{field}.shape is invalid"
            )
        event_field_shape_cases.append((field, shape))
        if shape == "scalar":
            event_field_value_contract_cases.append(
                (
                    field,
                    require_string(
                        contract.get(
                            "value_contract", event_default_scalar_value_contract
                        ),
                        "event_serialization.field_contracts."
                        f"{field}.value_contract",
                    ),
                )
            )
        if "item_contract" in contract:
            event_field_item_cases.append(
                (
                    field,
                    require_string(
                        contract["item_contract"],
                        "event_serialization.field_contracts."
                        f"{field}.item_contract",
                    ),
                )
            )
        if "min_items" in contract:
            event_field_min_items_cases.append(
                (
                    field,
                    str(
                        require_nonnegative_int(
                            contract["min_items"],
                            "event_serialization.field_contracts."
                            f"{field}.min_items",
                        )
                    ),
                )
            )
    lines.extend(case_function("gendev_event_field_shape", event_field_shape_cases))
    lines.extend(
        case_function("gendev_event_field_item_contract", event_field_item_cases)
    )
    lines.extend(
        case_function("gendev_event_field_min_items", event_field_min_items_cases)
    )
    lines.extend(
        case_function(
            "gendev_event_field_value_contract",
            event_field_value_contract_cases,
        )
    )
    lines.extend(
        case_function(
            "gendev_event_common_conditional_fields",
            (
                (
                    require_string(
                        profile,
                        "event_serialization.common_conditional_field_sets key",
                    ),
                    joined(
                        require_string_list(
                            fields,
                            "event_serialization.common_conditional_field_sets."
                            f"{profile}",
                        )
                    ),
                )
                for profile, fields in event_common_conditional_fields.items()
            ),
        )
    )

    record_required_cases: list[tuple[str, str]] = []
    record_field_id_cases: list[tuple[str, str]] = []
    record_profile_cases: list[tuple[str, str]] = []
    record_conditional_cases: list[tuple[str, str]] = []
    record_field_shape_cases: list[tuple[str, str]] = []
    record_field_item_cases: list[tuple[str, str]] = []
    record_field_min_items_cases: list[tuple[str, str]] = []
    record_field_value_contract_cases: list[tuple[str, str]] = []
    record_profile_selector_cases: list[tuple[str, str]] = []
    record_profile_value_cases: list[tuple[str, str]] = []
    for contract_id, contract in event_record_contracts:
        required_fields = require_string_list(
            contract.get("required_fields"),
            f"event_serialization.record_contracts.{contract_id}.required_fields",
        )
        conditional_fields = require_mapping(
            contract.get("conditional_field_sets", {}),
            "event_serialization.record_contracts."
            f"{contract_id}.conditional_field_sets",
        )
        default_shape = require_string(
            contract.get("default_field_shape"),
            f"event_serialization.record_contracts.{contract_id}.default_field_shape",
        )
        if default_shape not in allowed_event_shapes:
            raise RegistryError(
                "event_serialization.record_contracts."
                f"{contract_id}.default_field_shape is invalid"
            )
        shape_overrides = require_mapping(
            contract.get("field_shape_overrides", {}),
            "event_serialization.record_contracts."
            f"{contract_id}.field_shape_overrides",
        )
        item_contracts = require_mapping(
            contract.get("field_item_contracts", {}),
            "event_serialization.record_contracts."
            f"{contract_id}.field_item_contracts",
        )
        field_min_items = require_mapping(
            contract.get("field_min_items", {}),
            "event_serialization.record_contracts."
            f"{contract_id}.field_min_items",
        )
        field_value_contracts = require_mapping(
            contract.get("field_value_contracts", {}),
            "event_serialization.record_contracts."
            f"{contract_id}.field_value_contracts",
        )
        if "conditional_profile_selector" in contract:
            record_profile_selector_cases.append(
                (
                    contract_id,
                    require_string(
                        contract["conditional_profile_selector"],
                        "event_serialization.record_contracts."
                        f"{contract_id}.conditional_profile_selector",
                    ),
                )
            )
        profile_value_map = require_mapping(
            contract.get("conditional_profile_value_map", {}),
            "event_serialization.record_contracts."
            f"{contract_id}.conditional_profile_value_map",
        )
        for raw_value, raw_profile in profile_value_map.items():
            value = require_string(
                raw_value,
                "event_serialization.record_contracts."
                f"{contract_id}.conditional_profile_value_map key",
            )
            profile = require_string(
                raw_profile,
                "event_serialization.record_contracts."
                f"{contract_id}.conditional_profile_value_map.{value}",
            )
            record_profile_value_cases.append(
                (f"{contract_id}:{value}", profile)
            )
        field_ids = list(required_fields)
        profiles: list[str] = []
        for raw_profile, fields in conditional_fields.items():
            profile = require_string(
                raw_profile,
                "event_serialization.record_contracts."
                f"{contract_id}.conditional_field_sets key",
            )
            profiles.append(profile)
            profile_fields = require_string_list(
                fields,
                "event_serialization.record_contracts."
                f"{contract_id}.conditional_field_sets.{profile}",
            )
            record_conditional_cases.append(
                (f"{contract_id}:{profile}", joined(profile_fields))
            )
            for field in profile_fields:
                if field not in field_ids:
                    field_ids.append(field)
        record_required_cases.append((contract_id, joined(required_fields)))
        record_field_id_cases.append((contract_id, joined(field_ids)))
        record_profile_cases.append((contract_id, joined(profiles)))
        for field in field_ids:
            shape = require_string(
                shape_overrides.get(field, default_shape),
                "event_serialization.record_contracts."
                f"{contract_id}.field_shape.{field}",
            )
            if shape not in allowed_event_shapes:
                raise RegistryError(
                    "event_serialization.record_contracts."
                    f"{contract_id}.field_shape.{field} is invalid"
                )
            record_field_shape_cases.append((f"{contract_id}:{field}", shape))
            if shape == "scalar":
                record_field_value_contract_cases.append(
                    (
                        f"{contract_id}:{field}",
                        require_string(
                            field_value_contracts.get(
                                field, event_default_scalar_value_contract
                            ),
                            "event_serialization.record_contracts."
                            f"{contract_id}.field_value_contracts.{field}",
                        ),
                    )
                )
            if field in item_contracts:
                record_field_item_cases.append(
                    (
                        f"{contract_id}:{field}",
                        require_string(
                            item_contracts[field],
                            "event_serialization.record_contracts."
                            f"{contract_id}.field_item_contracts.{field}",
                        ),
                    )
                )
            if field in field_min_items:
                record_field_min_items_cases.append(
                    (
                        f"{contract_id}:{field}",
                        str(
                            require_nonnegative_int(
                                field_min_items[field],
                                "event_serialization.record_contracts."
                                f"{contract_id}.field_min_items.{field}",
                            )
                        ),
                    )
                )
    lines.extend(
        case_function("gendev_event_record_required_fields", record_required_cases)
    )
    lines.extend(
        case_function("gendev_event_record_field_ids", record_field_id_cases)
    )
    lines.extend(
        case_function("gendev_event_record_conditional_profiles", record_profile_cases)
    )
    lines.extend(
        case_function(
            "gendev_event_record_conditional_fields",
            record_conditional_cases,
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_event_record_field_shape",
            record_field_shape_cases,
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_event_record_field_item_contract",
            record_field_item_cases,
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_event_record_field_min_items",
            record_field_min_items_cases,
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_event_record_field_value_contract",
            record_field_value_contract_cases,
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_event_record_conditional_profile_selector",
            record_profile_selector_cases,
        )
    )
    lines.extend(
        case_function(
            "gendev_event_record_conditional_profile_for_value",
            record_profile_value_cases,
            arguments=2,
        )
    )

    lines.extend(
        case_function(
            "gendev_migration_reference_required_fields",
            (
                (
                    require_string(
                        kind,
                        "events.migration_reconciliation."
                        "historical_event_reference_contract."
                        "required_fields_by_kind key",
                    ),
                    joined(
                        require_string_list(
                            fields,
                            "events.migration_reconciliation."
                            "historical_event_reference_contract."
                            f"required_fields_by_kind.{kind}",
                        )
                    ),
                )
                for kind, fields in migration_reference_fields.items()
            ),
        )
    )

    event_history_string_cases = [
        (
            field,
            require_string(event_history.get(field), f"event_history.{field}"),
        )
        for field in (
            "template_projection",
            "template_projection_state",
            "required_work_package",
        )
    ]
    event_history_boolean_cases = [
        (
            field,
            bool_text(event_history.get(field), f"event_history.{field}"),
        )
        for field in (
            "append_only",
            "corrections_are_new_events",
            "duplicate_latest_is_invalid",
            "supersession_cycles_are_invalid",
            "prior_event_text_must_remain_byte_identical",
        )
    ]
    lines.extend(
        case_function("gendev_event_history_string", event_history_string_cases)
    )
    lines.extend(
        case_function("gendev_event_history_boolean", event_history_boolean_cases)
    )
    event_history_enforcement_string_cases: list[tuple[str, str]] = []
    for field in ("state", "required_work_package", "enforcer_path", "verification_suite"):
        event_history_enforcement_string_cases.append(
            (
                field,
                require_string(
                    event_history_enforcement.get(field),
                    f"event_history.enforcement.{field}",
                ),
            )
        )
    lines.extend(
        case_function(
            "gendev_event_history_enforcement_string",
            event_history_enforcement_string_cases,
        )
    )

    lines.extend(
        case_function(
            "gendev_reference_depth_rule",
            (
                (
                    field,
                    bool_text(
                        reference_depth.get(field),
                        f"references.depth_policy.{field}",
                    ),
                )
                for field in (
                    "greater_depth_requires_exception",
                    "supporting_to_supporting_reference_allowed_only_by_exception",
                )
            ),
        )
    )

    lines.extend(
        case_function(
            "gendev_manifest_field_contract_state",
            (
                (
                    field,
                    require_string(
                        state.get("contract_state"),
                        f"manifest.field_states.{field}.contract_state",
                    ),
                )
                for field, state in manifest_field_states
            ),
        )
    )
    lines.extend(
        case_function(
            "gendev_manifest_field_required_work_package",
            (
                (
                    field,
                    require_string(
                        state.get("required_work_package"),
                        f"manifest.field_states.{field}.required_work_package",
                    ),
                )
                for field, state in manifest_field_states
            ),
        )
    )
    manifest_invariant_string_cases: list[tuple[str, str]] = []
    manifest_invariant_boolean_cases: list[tuple[str, str]] = []
    for invariant in manifest_invariants:
        invariant_id = require_string(invariant.get("id"), "manifest.invariant.id")
        for raw_field, value in invariant.items():
            field = require_string(raw_field, f"manifest.invariants.{invariant_id} key")
            if field == "id":
                continue
            key = f"{invariant_id}:{field}"
            if isinstance(value, bool):
                manifest_invariant_boolean_cases.append(
                    (
                        key,
                        bool_text(value, f"manifest.invariants.{invariant_id}.{field}"),
                    )
                )
            elif isinstance(value, str):
                manifest_invariant_string_cases.append(
                    (
                        key,
                        require_string(
                            value, f"manifest.invariants.{invariant_id}.{field}"
                        ),
                    )
                )
            else:
                raise RegistryError(
                    f"manifest.invariants.{invariant_id}.{field} has unsupported value type"
                )
    lines.extend(
        case_function(
            "gendev_manifest_invariant_string",
            manifest_invariant_string_cases,
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_manifest_invariant_boolean",
            manifest_invariant_boolean_cases,
            arguments=2,
        )
    )

    deployment_path_string_cases: list[tuple[str, str]] = []
    deployment_path_boolean_cases: list[tuple[str, str]] = []
    deployment_path_field_cases: list[tuple[str, str]] = []
    deployment_path_string_fields = {
        "deployment_record_status",
        "terminal_disposition",
    }
    for path_name, path_contract in deployment_paths:
        for raw_field, value in path_contract.items():
            field = require_string(raw_field, f"deployment.{path_name}_path key")
            key = f"{path_name}:{field}"
            if field == "required_fields":
                deployment_path_field_cases.append(
                    (
                        key,
                        joined(
                            require_string_list(
                                value, f"deployment.{path_name}_path.{field}"
                            )
                        ),
                    )
                )
            elif field in deployment_path_string_fields:
                deployment_path_string_cases.append(
                    (
                        key,
                        require_string(value, f"deployment.{path_name}_path.{field}"),
                    )
                )
            else:
                deployment_path_boolean_cases.append(
                    (
                        key,
                        bool_text(value, f"deployment.{path_name}_path.{field}"),
                    )
                )
    lines.extend(
        case_function(
            "gendev_deployment_path_string", deployment_path_string_cases, arguments=2
        )
    )
    lines.extend(
        case_function(
            "gendev_deployment_path_boolean",
            deployment_path_boolean_cases,
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_deployment_path_fields", deployment_path_field_cases, arguments=2
        )
    )
    lines.extend(
        [
            shell_assignment(
                "GENDEV_DEPLOYMENT_PRODUCTION_ACTION_AUTOMATIC",
                bool_text(
                    deployment.get("production_action_automatic"),
                    "deployment.production_action_automatic",
                ),
            ),
            shell_assignment(
                "GENDEV_DEPLOYMENT_VALUE_MUST_BE_COMPLETE_BEFORE_AUTHORIZATION",
                bool_text(
                    deployment_value_contract.get(
                        "must_be_complete_before_authorization"
                    ),
                    "deployment.value_prerequisite_contract."
                    "must_be_complete_before_authorization",
                ),
            ),
            shell_assignment(
                "GENDEV_DEPLOYMENT_INTENT_MUST_MATCH_TERMINAL_DISPOSITION",
                bool_text(
                    deployment.get(
                        "authorization_intent_must_match_terminal_disposition"
                    ),
                    "deployment."
                    "authorization_intent_must_match_terminal_disposition",
                ),
            ),
            "",
        ]
    )

    lines.extend(
        case_function(
            "gendev_role_kind",
            (
                (
                    item["id"],
                    require_string(item.get("kind"), f"roles.{item['id']}.kind"),
                )
                for item in roles
            ),
        )
    )
    lines.extend(
        case_function(
            "gendev_role_may_approve",
            (
                (
                    item["id"],
                    bool_text(
                        item.get("may_approve"), f"roles.{item['id']}.may_approve"
                    ),
                )
                for item in roles
            ),
        )
    )

    lines.extend(case_function("gendev_gate_name", ((gate["id"], gate["name"]) for gate in gates)))
    lines.extend(
        case_function(
            "gendev_gate_successor",
            (
                (
                    gate["id"],
                    optional_string(
                        gate.get("successor"), f"gates.{gate['id']}.successor"
                    ),
                )
                for gate in gates
            ),
        )
    )
    lines.extend(case_function("gendev_gate_role", ((gate["id"], gate["active_role"]) for gate in gates)))
    lines.extend(
        case_function(
            "gendev_gate_primary_artifact",
            ((gate["id"], gate["primary_artifact"]) for gate in gates),
        )
    )
    lines.extend(
        case_function(
            "gendev_gate_approval",
            ((gate["id"], gate["human_approval"]) for gate in gates),
        )
    )
    lines.extend(
        case_function(
            "gendev_gate_criteria",
            ((gate["id"], joined(require_string_list(gate["criterion_ids"], f"gates.{gate['id']}.criterion_ids"))) for gate in gates),
        )
    )

    transition_records: list[tuple[str, dict[str, Any]]] = []
    transition_edges: set[str] = set()
    for item in transitions:
        transition_id = require_string(item["id"], "transition.id")
        from_gate = require_string(item.get("from"), f"transitions.{transition_id}.from")
        to_gate = require_string(item.get("to"), f"transitions.{transition_id}.to")
        edge = f"{from_gate}:{to_gate}"
        if edge in transition_edges:
            raise RegistryError(f"duplicate transition edge: {from_gate} -> {to_gate}")
        transition_edges.add(edge)
        transition_records.append((edge, item))
    lines.extend(
        case_function(
            "gendev_transition_event_type",
            ((key, item["event_type"]) for key, item in transition_records),
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_transition_command",
            ((key, item["command"]) for key, item in transition_records),
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_transition_approval",
            ((key, item["approval"]) for key, item in transition_records),
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_transition_required_artifacts",
            ((key, joined(require_string_list(item["required_artifacts"], f"transitions.{item['id']}.required_artifacts"))) for key, item in transition_records),
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_transition_criteria",
            ((key, joined(require_string_list(item["criterion_ids"], f"transitions.{item['id']}.criterion_ids"))) for key, item in transition_records),
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_transition_required_event_bindings",
            ((key, joined(require_string_list(item.get("required_event_bindings", []), f"transitions.{item['id']}.required_event_bindings"))) for key, item in transition_records),
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_transition_required_dynamic_evidence",
            ((key, joined(require_string_list(item.get("required_dynamic_evidence", []), f"transitions.{item['id']}.required_dynamic_evidence"))) for key, item in transition_records),
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_transition_specific_event_fields",
            ((key, joined(require_string_list(item.get("transition_specific_event_fields", []), f"transitions.{item['id']}.transition_specific_event_fields"))) for key, item in transition_records),
            arguments=2,
        )
    )
    transition_conditional_event_cases: list[tuple[str, str]] = []
    transition_conditional_profile_cases: list[tuple[str, str]] = []
    for key, item in transition_records:
        conditional_fields = require_mapping(
            item.get("conditional_transition_specific_event_fields", {}),
            f"transitions.{item['id']}.conditional_transition_specific_event_fields",
        )
        profiles: list[str] = []
        for raw_profile, fields in conditional_fields.items():
            profile = require_string(
                raw_profile,
                f"transitions.{item['id']}.conditional event profile",
            )
            profiles.append(profile)
            transition_conditional_event_cases.append(
                (
                    f"{key}:{profile}",
                    joined(
                        require_string_list(
                            fields,
                            "transitions."
                            f"{item['id']}.conditional_transition_specific_event_fields."
                            f"{profile}",
                        )
                    ),
                )
            )
        transition_conditional_profile_cases.append((key, joined(profiles)))
    lines.extend(
        case_function(
            "gendev_transition_conditional_event_profiles",
            transition_conditional_profile_cases,
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_transition_conditional_event_fields",
            transition_conditional_event_cases,
            arguments=3,
        )
    )
    lines.extend(
        case_function(
            "gendev_transition_resulting_project_status",
            ((key, require_string(item["resulting_project_status"], f"transitions.{item['id']}.resulting_project_status")) for key, item in transition_records),
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_transition_resulting_role",
            (
                (
                    key,
                    require_string(
                        item.get("resulting_role"),
                        f"transitions.{item['id']}.resulting_role",
                    ),
                )
                for key, item in transition_records
            ),
            arguments=2,
        )
    )
    transition_boolean_cases: list[tuple[str, str]] = []
    for key, item in transition_records:
        for field in ("terminal", "terminal_closeout"):
            if field in item:
                transition_boolean_cases.append(
                    (
                        f"{key}:{field}",
                        bool_text(item[field], f"transitions.{item['id']}.{field}"),
                    )
                )
    lines.extend(
        case_function(
            "gendev_transition_boolean", transition_boolean_cases, arguments=3
        )
    )
    lines.extend(
        case_function(
            "gendev_transition_approval_profiles",
            ((key, joined(require_string_list(item.get("approval_profiles", []), f"transitions.{item['id']}.approval_profiles"))) for key, item in transition_records),
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_transition_named_human_condition",
            (
                (
                    key,
                    require_string(
                        item["named_human_condition"],
                        f"transitions.{item['id']}.named_human_condition",
                    ),
                )
                for key, item in transition_records
                if item.get("named_human_condition") is not None
            ),
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_transition_artifact_requirement_policy",
            (
                (
                    key,
                    require_string(
                        item.get("artifact_requirement_policy", "evidence_bindings"),
                        f"transitions.{item['id']}.artifact_requirement_policy",
                    ),
                )
                for key, item in transition_records
            ),
            arguments=2,
        )
    )

    transition_requirements: list[tuple[str, dict[str, Any]]] = []
    for key, item in transition_records:
        for requirement in nested_records(
            item,
            "artifact_requirements",
            f"transitions.{item['id']}",
            "artifact_id",
        ):
            transition_requirements.append(
                (f"{key}:{requirement['artifact_id']}", requirement)
            )
    lines.extend(
        case_function(
            "gendev_transition_artifact_requirement_ids",
            (
                (
                    key,
                    joined(
                        require_string(requirement["artifact_id"], "transition artifact requirement")
                        for requirement in nested_records(
                            item,
                            "artifact_requirements",
                            f"transitions.{item['id']}",
                            "artifact_id",
                        )
                    ),
                )
                for key, item in transition_records
            ),
            arguments=2,
        )
    )
    for function_name, field in (
        ("gendev_transition_artifact_reviewed_statuses", "reviewed_statuses"),
        ("gendev_transition_artifact_resulting_statuses", "resulting_statuses"),
        ("gendev_transition_artifact_evidence_categories", "evidence_categories"),
        ("gendev_transition_artifact_required_dispositions", "required_dispositions"),
    ):
        lines.extend(
            case_function(
                function_name,
                (
                    (
                        key,
                        joined(
                            require_string_list(
                                requirement.get(field, []),
                                f"transition requirement {key}.{field}",
                            )
                        ),
                    )
                    for key, requirement in transition_requirements
                ),
                arguments=3,
            )
        )
    lines.extend(
        case_function(
            "gendev_transition_artifact_disposition_contract",
            (
                (
                    key,
                    optional_string(
                        requirement.get("disposition_contract"),
                        f"transition requirement {key}.disposition_contract",
                    ),
                )
                for key, requirement in transition_requirements
            ),
            arguments=3,
        )
    )

    lines.extend(
        case_function(
            "gendev_checkpoint_pattern",
            ((item["id"], item["position_pattern"]) for item in checkpoints),
        )
    )
    lines.extend(
        case_function(
            "gendev_checkpoint_event_type",
            ((item["id"], item["event_type"]) for item in checkpoints),
        )
    )
    lines.extend(
        case_function(
            "gendev_checkpoint_approval",
            ((item["id"], item["approval"]) for item in checkpoints),
        )
    )
    lines.extend(
        case_function(
            "gendev_checkpoint_order",
            (
                (
                    item["id"],
                    str(
                        require_nonnegative_int(
                            item.get("order"), f"checkpoints.{item['id']}.order"
                        )
                    ),
                )
                for item in checkpoints
            ),
        )
    )
    lines.extend(
        case_function(
            "gendev_checkpoint_active_major_gate",
            (
                (
                    item["id"],
                    require_string(
                        item.get("active_major_gate"),
                        f"checkpoints.{item['id']}.active_major_gate",
                    ),
                )
                for item in checkpoints
            ),
        )
    )
    lines.extend(
        case_function(
            "gendev_checkpoint_resulting_role",
            (
                (
                    item["id"],
                    require_string(
                        item.get("resulting_role"),
                        f"checkpoints.{item['id']}.resulting_role",
                    ),
                )
                for item in checkpoints
            ),
        )
    )
    lines.extend(
        case_function(
            "gendev_checkpoint_required_artifacts",
            ((item["id"], joined(require_string_list(item["required_artifacts"], f"checkpoints.{item['id']}.required_artifacts"))) for item in checkpoints),
        )
    )
    lines.extend(
        case_function(
            "gendev_checkpoint_required_evidence_classes",
            (
                (item["id"], joined(checkpoint_evidence_classes(item)))
                for item in checkpoints
            ),
        )
    )
    lines.extend(
        case_function(
            "gendev_checkpoint_criteria",
            ((item["id"], joined(require_string_list(item["criterion_ids"], f"checkpoints.{item['id']}.criterion_ids"))) for item in checkpoints),
        )
    )
    event_by_id = {require_string(item["id"], "event.id"): item for item in events}
    lines.extend(
        case_function(
            "gendev_checkpoint_required_event_fields",
            (
                (
                    item["id"],
                    joined(
                        require_string_list(
                            event_by_id[require_string(item["event_type"], f"checkpoints.{item['id']}.event_type")]["required_fields"],
                            f"events.{item['event_type']}.required_fields",
                        )
                    ),
                )
                for item in checkpoints
            ),
        )
    )
    lines.extend(
        case_function(
            "gendev_checkpoint_nullable_event_fields",
            ((item["id"], joined(require_string_list(item.get("nullable_event_fields", []), f"checkpoints.{item['id']}.nullable_event_fields"))) for item in checkpoints),
        )
    )
    lines.extend(
        case_function(
            "gendev_checkpoint_required_dynamic_evidence",
            ((item["id"], joined(require_string_list(item.get("required_dynamic_evidence", []), f"checkpoints.{item['id']}.required_dynamic_evidence"))) for item in checkpoints),
        )
    )

    checkpoint_requirements: list[tuple[str, dict[str, Any]]] = []
    checkpoint_references: list[tuple[str, dict[str, Any]]] = []
    checkpoint_evidence: list[tuple[str, dict[str, Any]]] = []
    for item in checkpoints:
        checkpoint_id = require_string(item["id"], "checkpoint.id")
        for requirement in nested_records(
            item,
            "artifact_requirements",
            f"checkpoints.{checkpoint_id}",
            "artifact_id",
        ):
            checkpoint_requirements.append(
                (f"{checkpoint_id}:{requirement['artifact_id']}", requirement)
            )
        for requirement in nested_records(
            item,
            "reference_requirements",
            f"checkpoints.{checkpoint_id}",
            "artifact_id",
        ):
            checkpoint_references.append(
                (f"{checkpoint_id}:{requirement['artifact_id']}", requirement)
            )
        for binding in nested_records(
            item,
            "required_evidence",
            f"checkpoints.{checkpoint_id}",
            "class",
        ):
            checkpoint_evidence.append(
                (f"{checkpoint_id}:{binding['class']}", binding)
            )

    checkpoint_reference_status_cases: list[tuple[str, str]] = []
    for key, requirement in checkpoint_references:
        status_by_disposition = require_mapping(
            requirement.get("status_by_disposition", {}),
            f"checkpoint reference {key}.status_by_disposition",
        )
        for raw_disposition, statuses in status_by_disposition.items():
            disposition = require_string(
                raw_disposition,
                f"checkpoint reference {key}.status_by_disposition key",
            )
            checkpoint_reference_status_cases.append(
                (
                    f"{key}:{disposition}",
                    joined(
                        require_string_list(
                            statuses,
                            "checkpoint reference "
                            f"{key}.status_by_disposition.{disposition}",
                        )
                    ),
                )
            )
    lines.extend(
        case_function(
            "gendev_checkpoint_reference_statuses_for_disposition",
            checkpoint_reference_status_cases,
            arguments=3,
        )
    )

    lines.extend(
        case_function(
            "gendev_checkpoint_artifact_requirement_ids",
            (
                (
                    item["id"],
                    joined(
                        require_string(requirement["artifact_id"], "checkpoint artifact requirement")
                        for requirement in nested_records(
                            item,
                            "artifact_requirements",
                            f"checkpoints.{item['id']}",
                            "artifact_id",
                        )
                    ),
                )
                for item in checkpoints
            ),
        )
    )
    lines.extend(
        case_function(
            "gendev_checkpoint_reference_artifacts",
            (
                (
                    item["id"],
                    joined(
                        require_string(requirement["artifact_id"], "checkpoint reference requirement")
                        for requirement in nested_records(
                            item,
                            "reference_requirements",
                            f"checkpoints.{item['id']}",
                            "artifact_id",
                        )
                    ),
                )
                for item in checkpoints
            ),
        )
    )

    for function_name, field in (
        ("gendev_checkpoint_artifact_reviewed_statuses", "reviewed_statuses"),
        ("gendev_checkpoint_artifact_resulting_statuses", "resulting_statuses"),
        ("gendev_checkpoint_artifact_evidence_categories", "evidence_categories"),
        ("gendev_checkpoint_artifact_required_dispositions", "required_dispositions"),
    ):
        lines.extend(
            case_function(
                function_name,
                (
                    (
                        key,
                        joined(
                            require_string_list(
                                requirement.get(field, []),
                                f"checkpoint requirement {key}.{field}",
                            )
                        ),
                    )
                    for key, requirement in checkpoint_requirements
                ),
                arguments=2,
            )
        )
    lines.extend(
        case_function(
            "gendev_checkpoint_artifact_disposition_contract",
            (
                (
                    key,
                    optional_string(
                        requirement.get("disposition_contract"),
                        f"checkpoint requirement {key}.disposition_contract",
                    ),
                )
                for key, requirement in checkpoint_requirements
            ),
            arguments=2,
        )
    )

    for function_name, field in (
        ("gendev_checkpoint_reference_allowed_statuses", "allowed_statuses"),
        ("gendev_checkpoint_reference_required_dispositions", "required_dispositions"),
        ("gendev_checkpoint_reference_required_fields", "required_fields"),
    ):
        lines.extend(
            case_function(
                function_name,
                (
                    (
                        key,
                        joined(
                            require_string_list(
                                requirement.get(field, []),
                                f"checkpoint reference {key}.{field}",
                            )
                        ),
                    )
                    for key, requirement in checkpoint_references
                ),
                arguments=2,
            )
        )
    for function_name, field in (
        ("gendev_checkpoint_reference_binding_mode", "binding_mode"),
        ("gendev_checkpoint_reference_parent_artifact", "parent_artifact_id"),
        ("gendev_checkpoint_reference_disposition_contract", "disposition_contract"),
    ):
        lines.extend(
            case_function(
                function_name,
                (
                    (
                        key,
                        optional_string(
                            requirement.get(field),
                            f"checkpoint reference {key}.{field}",
                        ),
                    )
                    for key, requirement in checkpoint_references
                ),
                arguments=2,
            )
        )

    for function_name, field in (
        ("gendev_checkpoint_evidence_artifacts", "artifact_ids"),
        ("gendev_checkpoint_evidence_event_fields", "event_fields"),
        ("gendev_checkpoint_evidence_referenced_artifacts", "referenced_artifact_ids"),
    ):
        lines.extend(
            case_function(
                function_name,
                (
                    (
                        key,
                        joined(
                            require_string_list(
                                binding.get(field, []),
                                f"checkpoint evidence {key}.{field}",
                            )
                        ),
                    )
                    for key, binding in checkpoint_evidence
                ),
                arguments=2,
            )
        )
    lines.extend(
        case_function(
            "gendev_checkpoint_evidence_binding_mode",
            (
                (
                    key,
                    require_string(
                        binding.get("binding_mode", "direct_evidence"),
                        f"checkpoint evidence {key}.binding_mode",
                    ),
                )
                for key, binding in checkpoint_evidence
            ),
            arguments=2,
        )
    )

    for function_name, field in (
        ("gendev_artifact_path", "path"),
        ("gendev_artifact_path_kind", "path_kind"),
        ("gendev_artifact_kind", "kind"),
        ("gendev_artifact_template", "template"),
        ("gendev_artifact_template_state", "template_state"),
        ("gendev_artifact_lifecycle_state", "lifecycle_state"),
        ("gendev_artifact_evidence_class", "evidence_class"),
        ("gendev_artifact_owner_role", "owner_role"),
        ("gendev_artifact_identity_contract_state", "identity_contract_state"),
    ):
        lines.extend(
            case_function(
                function_name,
                ((item["id"], item[field]) for item in artifacts),
            )
        )
    lines.extend(
        case_function(
            "gendev_artifact_allowed_statuses",
            ((item["id"], joined(require_string_list(item["allowed_statuses"], f"artifacts.{item['id']}.allowed_statuses"))) for item in artifacts),
        )
    )
    lines.extend(
        case_function(
            "gendev_artifact_lifecycle_bindings",
            (
                (
                    item["id"],
                    joined(
                        require_string_list(
                            item.get("lifecycle_bindings"),
                            f"artifacts.{item['id']}.lifecycle_bindings",
                        )
                    ),
                )
                for item in artifacts
            ),
        )
    )
    lines.extend(
        case_function(
            "gendev_artifact_required_work_package",
            (
                (
                    item["id"],
                    optional_string(
                        item.get("required_work_package"),
                        f"artifacts.{item['id']}.required_work_package",
                    ),
                )
                for item in artifacts
            ),
        )
    )
    for function_name, field in (
        ("gendev_artifact_project_identity_required", "project_identity_required"),
        ("gendev_artifact_provenance_required", "provenance_required"),
    ):
        lines.extend(
            case_function(
                function_name,
                (
                    (
                        item["id"],
                        bool_text(item.get(field), f"artifacts.{item['id']}.{field}"),
                    )
                    for item in artifacts
                ),
            )
        )

    lines.extend(
        case_function(
            "gendev_value_review_item_contract",
            (
                (
                    disposition["id"],
                    optional_string(
                        disposition.get("item_contract"),
                        "value_review_contract.dispositions."
                        f"{disposition['id']}.item_contract",
                    ),
                )
                for disposition in value_dispositions
            ),
        )
    )

    lines.extend(
        case_function(
            "gendev_event_required_fields",
            ((item["id"], joined(require_string_list(item["required_fields"], f"events.{item['id']}.required_fields"))) for item in events),
        )
    )
    event_conditional_cases: list[tuple[str, str]] = []
    event_conditional_profile_cases: list[tuple[str, str]] = []
    for item in events:
        conditional = item.get("conditional_field_sets", {})
        if not isinstance(conditional, dict):
            raise RegistryError(
                f"events.{item['id']}.conditional_field_sets must be an object"
            )
        profiles: list[str] = []
        for profile, fields in conditional.items():
            profile_location = f"events.{item['id']}.conditional_field_sets key"
            profile = require_string(profile, profile_location)
            profiles.append(profile)
            event_conditional_cases.append(
                (
                    f"{item['id']}:{profile}",
                    joined(
                        require_string_list(
                            fields,
                            f"events.{item['id']}.conditional_field_sets.{profile}",
                        )
                    ),
                )
            )
        event_conditional_profile_cases.append((item["id"], joined(profiles)))
    lines.extend(
        case_function(
            "gendev_event_conditional_profiles", event_conditional_profile_cases
        )
    )
    lines.extend(
        case_function(
            "gendev_event_conditional_fields",
            event_conditional_cases,
            arguments=2,
        )
    )
    lines.extend(
        case_function(
            "gendev_event_schema_version",
            (
                (
                    item["id"],
                    str(
                        require_nonnegative_int(
                            item.get("schema_version"),
                            f"events.{item['id']}.schema_version",
                        )
                    ),
                )
                for item in events
            ),
        )
    )
    lines.extend(
        case_function(
            "gendev_event_append_only",
            (
                (
                    item["id"],
                    bool_text(
                        item.get("append_only"), f"events.{item['id']}.append_only"
                    ),
                )
                for item in events
            ),
        )
    )
    lines.extend(
        case_function(
            "gendev_event_changes_major_gate",
            (
                (
                    item["id"],
                    bool_text(
                        item.get("changes_major_gate"),
                        f"events.{item['id']}.changes_major_gate",
                    ),
                )
                for item in events
            ),
        )
    )
    lines.extend(
        case_function(
            "gendev_evidence_reviewed_status",
            ((item["id"], item["reviewed_status"]) for item in evidence_categories),
        )
    )
    lines.extend(
        case_function(
            "gendev_evidence_resulting_status",
            ((item["id"], item["resulting_status"]) for item in evidence_categories),
        )
    )
    lines.extend(
        case_function(
            "gendev_artifact_status_is_valid",
            ((status, "true") for status in artifact_statuses),
        )
    )

    for function_name, field in (
        ("gendev_deployment_artifact_reviewed_statuses", "reviewed_statuses"),
        ("gendev_deployment_artifact_resulting_statuses", "resulting_statuses"),
        ("gendev_deployment_artifact_evidence_categories", "evidence_categories"),
        ("gendev_deployment_artifact_required_dispositions", "required_dispositions"),
    ):
        lines.extend(
            case_function(
                function_name,
                (
                    (
                        requirement["artifact_id"],
                        joined(
                            require_string_list(
                                requirement.get(field, []),
                                f"deployment.artifact_requirements.{requirement['artifact_id']}.{field}",
                            )
                        ),
                    )
                    for requirement in deployment_requirements
                ),
            )
        )

    for function_name, field in (
        ("gendev_value_review_required_fields", "required_fields"),
        ("gendev_value_review_allowed_results", "allowed_results"),
        ("gendev_value_review_follow_up_required_for", "follow_up_required_for"),
    ):
        lines.extend(
            case_function(
                function_name,
                (
                    (
                        disposition["id"],
                        joined(
                            require_string_list(
                                disposition.get(field, []),
                                f"value_review_contract.dispositions.{disposition['id']}.{field}",
                            )
                        ),
                    )
                    for disposition in value_dispositions
                ),
            )
        )

    lines.extend(
        case_function(
            "gendev_deployment_terminal_disposition",
            ((item["authorization_intent"], item["terminal_disposition"]) for item in deployment_correlations),
        )
    )
    lines.extend(
        case_function(
            "gendev_deployment_production_action_performed",
            (
                (
                    item["authorization_intent"],
                    bool_text(
                        item.get("production_action_performed"),
                        "deployment.terminal_correlations."
                        f"{item['authorization_intent']}.production_action_performed",
                    ),
                )
                for item in deployment_correlations
            ),
        )
    )

    for function_name, field in (
        ("gendev_event_binding_event_types", "event_types"),
        ("gendev_event_binding_allowed_intents", "allowed_intents"),
        ("gendev_event_binding_allowed_decisions", "allowed_decisions"),
    ):
        lines.extend(
            case_function(
                function_name,
                (
                    (
                        item["id"],
                        joined(
                            require_string_list(
                                item.get(
                                    field,
                                    [item["event_type"]]
                                    if field == "event_types" and "event_type" in item
                                    else [],
                                ),
                                f"event_binding_rules.{item['id']}.{field}",
                            )
                        ),
                    )
                    for item in event_binding_rules
                ),
            )
        )
    for function_name, field in (
        ("gendev_event_binding_quantifier", "quantifier"),
        ("gendev_event_binding_position_pattern", "position_pattern"),
        ("gendev_event_binding_evidence_category", "evidence_category"),
        ("gendev_event_binding_coverage_source", "coverage_source"),
        ("gendev_event_binding_major_gate", "major_gate"),
        ("gendev_event_binding_criterion_source", "required_criterion_ids_source"),
        ("gendev_event_binding_terminal_correlation", "terminal_correlation_contract"),
    ):
        lines.extend(
            case_function(
                function_name,
                (
                    (
                        item["id"],
                        optional_string(
                            item.get(field),
                            f"event_binding_rules.{item['id']}.{field}",
                        ),
                    )
                    for item in event_binding_rules
                ),
            )
        )
    binding_boolean_fields = (
        "same_project_required",
        "exact_candidate_required",
        "originating_event_required",
        "same_path_and_blob_required",
        "exact_release_candidate_required",
    )
    lines.extend(
        case_function(
            "gendev_event_binding_required_flags",
            (
                (
                    item["id"],
                    joined(
                        field
                        for field in binding_boolean_fields
                        if optional_bool(
                            item.get(field),
                            f"event_binding_rules.{item['id']}.{field}",
                        )
                        is True
                    ),
                )
                for item in event_binding_rules
            ),
        )
    )

    lines.extend(
        case_function(
            "gendev_reference_rule",
            (
                (
                    item["id"],
                    require_string(
                        item.get("rule"), f"references.rules.{item['id']}.rule"
                    ),
                )
                for item in reference_rules
            ),
        )
    )
    target_kinds = get_records(references, "target_kinds")
    lines.extend(
        case_function(
            "gendev_reference_target_scope",
            ((item["id"], item["path_scope"]) for item in target_kinds),
        )
    )
    lines.extend(
        case_function(
            "gendev_reference_authority_direction",
            ((item["id"], item["authority_direction"]) for item in target_kinds),
        )
    )
    for function_name, field in (
        ("gendev_reference_identity_contract", "identity_contract"),
        ("gendev_reference_form_contract", "form_contract"),
        ("gendev_reference_lifecycle_owner", "lifecycle_owner"),
        ("gendev_reference_cycle_policy", "cycle_policy"),
        ("gendev_reference_depth_policy", "depth_policy"),
        ("gendev_reference_validation_severity", "validation_severity"),
    ):
        lines.extend(
            case_function(
                function_name,
                (
                    (
                        item["id"],
                        optional_string(
                            item.get(field),
                            f"references.target_kinds.{item['id']}.{field}",
                        ),
                    )
                    for item in target_kinds
                ),
            )
        )

    classes = get_records(scaling, "classes")
    lines.extend(
        case_function(
            "gendev_scaling_requirements_form",
            ((item["id"], item["requirements_form"]) for item in classes),
        )
    )
    lines.extend(
        case_function(
            "gendev_scaling_gate_combination",
            ((item["id"], item["gate_combination"]) for item in classes),
        )
    )
    lines.extend(
        case_function(
            "gendev_scaling_label",
            ((item["id"], item["label"]) for item in classes),
        )
    )
    lines.extend(
        case_function(
            "gendev_scaling_design_interrogation",
            ((item["id"], item["design_interrogation"]) for item in classes),
        )
    )
    for function_name, field in (
        ("gendev_scaling_unwanted_behavior_required", "unwanted_behavior_required"),
        ("gendev_scaling_verification_spec_required", "verification_spec_required"),
        ("gendev_scaling_phase_exit_evidence_waivable", "phase_exit_evidence_waivable"),
    ):
        lines.extend(
            case_function(
                function_name,
                (
                    (
                        item["id"],
                        bool_text(item.get(field), f"scaling.classes.{item['id']}.{field}"),
                    )
                    for item in classes
                ),
            )
        )
    for function_name, field in (
        ("gendev_scaling_g2_required_all", "required_all"),
        ("gendev_scaling_g2_required_any", "required_any"),
    ):
        lines.extend(
            case_function(
                function_name,
                (
                    (
                        class_id,
                        joined(
                            require_string_list(
                                require_mapping(
                                    rule,
                                    f"scaling.g2_criterion_form_by_class.{class_id}",
                                ).get(field, []),
                                f"scaling.g2_criterion_form_by_class.{class_id}.{field}",
                            )
                        ),
                    )
                    for class_id, rule in g2_criterion_forms.items()
                ),
            )
        )

    lines.extend(
        [
            shell_assignment("GENDEV_LIFECYCLE_CONTRACT_LOADED", digest),
            "",
        ]
    )

    return ("\n".join(lines).rstrip() + "\n").encode("utf-8")


def load_registry(path: Path) -> tuple[bytes, dict[str, Any]]:
    try:
        registry_bytes = path.read_bytes()
    except OSError as error:
        raise RegistryError(f"cannot read registry {path}: {error}") from error
    try:
        raw = json.loads(
            registry_bytes,
            object_pairs_hook=reject_duplicate_object_pairs,
            parse_constant=reject_nonstandard_json_constant,
        )
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise RegistryError(f"cannot parse registry {path}: {error}") from error
    return registry_bytes, require_mapping(raw, "root")


def write_atomic(path: Path, content: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(content)
        os.chmod(temporary_path, 0o755)
        os.replace(temporary_path, path)
    except BaseException:
        temporary_path.unlink(missing_ok=True)
        raise


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        registry_bytes, registry = load_registry(args.registry)
        expected = build_contract(registry_bytes, registry)
    except RegistryError as error:
        print(f"lifecycle generator: {error}", file=sys.stderr)
        return 2
    except (AttributeError, IndexError, KeyError, TypeError) as error:
        print(f"lifecycle generator: invalid registry shape: {error}", file=sys.stderr)
        return 2

    if args.check:
        try:
            actual = args.output.read_bytes()
        except FileNotFoundError as error:
            print(f"lifecycle generator: generated contract unavailable: {error}", file=sys.stderr)
            return 1
        except OSError as error:
            print(f"lifecycle generator: cannot read generated contract: {error}", file=sys.stderr)
            return 2
        if actual != expected:
            print(
                f"lifecycle generator: {args.output} is stale; regenerate it",
                file=sys.stderr,
            )
            return 1
        print(f"lifecycle generator: {args.output} is current")
        return 0

    try:
        write_atomic(args.output, expected)
    except OSError as error:
        print(f"lifecycle generator: cannot write {args.output}: {error}", file=sys.stderr)
        return 2
    print(f"lifecycle generator: wrote {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
