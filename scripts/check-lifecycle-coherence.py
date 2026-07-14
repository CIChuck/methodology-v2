#!/usr/bin/env python3
"""Validate the GenDev lifecycle registry and its repository bindings."""

from __future__ import annotations

import argparse
import os
import hashlib
import json
import re
import shlex
import subprocess
import sys
import tempfile
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Iterable, Iterator, Sequence


RULE_SCHEMA = "LC-SCHEMA-001"
RULE_UNIQUE = "LC-UNIQUE-001"
RULE_TRANSITION = "LC-TRANSITION-001"
RULE_CHECKPOINT = "LC-CHECKPOINT-001"
RULE_REFERENCE = "LC-REFERENCE-001"
RULE_ARTIFACT = "LC-ARTIFACT-001"
RULE_TEMPLATE_PROJECT = "LC-TEMPLATE-PROJECT-001"
RULE_FIXED_PATH = "LC-FIXED-PATH-001"
RULE_PROJECT_TEMPLATE = "LC-PROJECT-TEMPLATE-001"
RULE_GATE_BINDING = "LC-GATE-BINDING-001"
RULE_VERSION = "LC-VERSION-001"
RULE_DECISION = "LC-DECISION-001"
RULE_SUPPORTING_DIR = "LC-SUPPORTING-DIR-001"
RULE_PHASE_EXIT = "LC-PHASE-EXIT-001"
RULE_TASK_GRAMMAR = "LC-TASK-GRAMMAR-001"
RULE_GENERATED = "LC-GENERATED-001"
RULE_DELIVERY = "LC-DELIVERY-001"
RULE_EVENT = "LC-EVENT-001"
RULE_APPROVAL = "LC-APPROVAL-001"


@dataclass(frozen=True)
class Finding:
    rule_id: str
    severity: str
    message: str
    file: str
    line: int | None = None

    def json_value(self) -> dict[str, Any]:
        return {key: value for key, value in asdict(self).items() if value is not None}


class RegistryError(Exception):
    """An invocation, parser, or unusable configuration error."""


class Validator:
    def __init__(
        self,
        root: Path,
        registry_path: Path,
        data: dict[str, Any],
        mode: str,
    ) -> None:
        self.root = root
        self.registry_path = registry_path
        self.data = data
        self.mode = mode
        self.findings: list[Finding] = []
        try:
            self.registry_text = registry_path.read_text(encoding="utf-8")
        except OSError as exc:
            raise RegistryError(f"cannot read registry {registry_path}: {exc}") from exc

    def add(
        self,
        rule_id: str,
        message: str,
        *,
        severity: str = "error",
        file: str | Path | None = None,
        needle: str | None = None,
    ) -> None:
        shown_file = self._display_path(Path(file) if file is not None else self.registry_path)
        line = self._line_for(needle) if file is None or Path(file) == self.registry_path else None
        self.findings.append(Finding(rule_id, severity, message, shown_file, line))

    def _display_path(self, path: Path) -> str:
        try:
            return str(path.resolve().relative_to(self.root.resolve()))
        except ValueError:
            return str(path)

    def _line_for(self, needle: str | None) -> int | None:
        if not needle:
            return None
        for line_number, line in enumerate(self.registry_text.splitlines(), start=1):
            if needle in line:
                return line_number
        return None

    @staticmethod
    def collection(value: Any) -> list[dict[str, Any]]:
        if isinstance(value, list):
            return [item for item in value if isinstance(item, dict)]
        if isinstance(value, dict):
            result: list[dict[str, Any]] = []
            for key, item in value.items():
                if isinstance(item, dict):
                    copy = dict(item)
                    copy.setdefault("id", key)
                    result.append(copy)
            return result
        return []

    @staticmethod
    def first(item: dict[str, Any], *keys: str) -> Any:
        for key in keys:
            if key in item:
                return item[key]
        return None

    @staticmethod
    def strings(value: Any) -> list[str]:
        if isinstance(value, str):
            return [value]
        if isinstance(value, list):
            return [item for item in value if isinstance(item, str)]
        return []

    def run(self) -> list[Finding]:
        self.check_shape()
        if any(finding.rule_id == RULE_SCHEMA for finding in self.findings):
            return self.findings
        self.check_planned_markers()
        self.check_uniqueness()
        self.check_cross_references()
        self.check_contract_invariants()
        self.check_event_serialization_contract()
        self.check_transitions()
        self.check_checkpoints()
        self.check_endorsed_catalog_contracts()
        self.check_declared_paths()
        self.check_artifacts()
        self.check_project_templates()
        self.check_gate_bindings()
        self.check_versions()
        self.check_decisions()
        self.check_identifier_grammar()
        self.check_generated_contract()
        return sorted(
            self.findings,
            key=lambda finding: (
                finding.rule_id,
                finding.file,
                finding.line or 0,
                finding.message,
            ),
        )

    def check_shape(self) -> None:
        mapping_sections = (
            "registry",
            "versions",
            "vocabularies",
            "value_review_contract",
            "ratification_contract",
            "paths",
            "event_evidence_item",
            "event_history",
            "event_reference_item",
            "event_serialization",
            "manifest",
            "identifiers",
            "references",
            "scaling",
            "naa",
            "compatibility",
            "approval_policy",
            "deployment",
            "document_sweep",
            "generation",
        )
        list_sections = (
            "roles",
            "gates",
            "criteria",
            "transitions",
            "checkpoints",
            "evidence_categories",
            "artifacts",
            "events",
            "decisions",
            "decision_records",
            "event_binding_rules",
        )
        if self.data.get("schema_version") != 2:
            self.add(RULE_SCHEMA, "schema_version must be integer 2", needle="schema_version")
        for section in mapping_sections + list_sections:
            if section not in self.data:
                self.add(RULE_SCHEMA, f"required top-level section is missing: {section}")
        for section in mapping_sections:
            if section in self.data and not isinstance(self.data[section], dict):
                self.add(RULE_SCHEMA, f"{section} must be an object", needle=f'"{section}"')
        for section in list_sections:
            value = self.data.get(section)
            if section in self.data and not isinstance(value, list):
                self.add(RULE_SCHEMA, f"{section} must be an array", needle=f'"{section}"')
                continue
            if isinstance(value, list):
                for index, item in enumerate(value):
                    if not isinstance(item, dict):
                        self.add(
                            RULE_SCHEMA,
                            f"{section}[{index}] must be an object",
                            needle=f'"{section}"',
                        )

        nested_shapes: tuple[tuple[str, Any, type], ...] = (
            ("paths.canonical_directories", self._nested("paths", "canonical_directories"), list),
            (
                "paths.project_scaffold_directories",
                self._nested("paths", "project_scaffold_directories"),
                list,
            ),
            ("paths.canonical_fixed_artifacts", self._nested("paths", "canonical_fixed_artifacts"), dict),
            ("paths.phase_artifact_patterns", self._nested("paths", "phase_artifact_patterns"), dict),
            ("manifest.required_fields", self._nested("manifest", "required_fields"), list),
            ("manifest.field_states", self._nested("manifest", "field_states"), dict),
            (
                "approval_policy.phase_exit",
                self._nested("approval_policy", "phase_exit"),
                dict,
            ),
            (
                "approval_policy.deployment",
                self._nested("approval_policy", "deployment"),
                dict,
            ),
            (
                "approval_policy.project_closeout",
                self._nested("approval_policy", "project_closeout"),
                dict,
            ),
            (
                "deployment.value_prerequisite_contract",
                self._nested("deployment", "value_prerequisite_contract"),
                dict,
            ),
            (
                "scaling.coverage_policy",
                self._nested("scaling", "coverage_policy"),
                dict,
            ),
            (
                "versions.observed_active_claims",
                self._nested("versions", "observed_active_claims"),
                list,
            ),
            (
                "versions.synchronization_targets",
                self._nested("versions", "synchronization_targets"),
                list,
            ),
        )
        for location, value, expected_type in nested_shapes:
            if value is None:
                self.add(
                    RULE_SCHEMA,
                    f"required nested section is missing: {location}",
                    needle=location.rsplit(".", 1)[-1],
                )
            elif not isinstance(value, expected_type):
                self.add(
                    RULE_SCHEMA,
                    f"{location} must be {'an object' if expected_type is dict else 'an array'}",
                    needle=location.rsplit(".", 1)[-1],
                )

    def _nested(self, section: str, key: str) -> Any:
        value = self.data.get(section)
        return value.get(key) if isinstance(value, dict) else None

    def check_planned_markers(self) -> None:
        work_package_pattern = re.compile(r"^WP-(?:0[1-9]|1[01])$")

        def walk(value: Any, location: str) -> None:
            if isinstance(value, list):
                for index, item in enumerate(value):
                    walk(item, f"{location}[{index}]")
                return
            if not isinstance(value, dict):
                return
            planned_keys = [
                key
                for key, item in value.items()
                if item == "planned" and (key == "state" or key.endswith("_state"))
            ]
            if planned_keys:
                work_package = value.get("required_work_package")
                if not isinstance(work_package, str) or not work_package_pattern.fullmatch(
                    work_package
                ):
                    self.add(
                        RULE_DELIVERY,
                        f"planned marker at {location} requires required_work_package WP-01..WP-11",
                        needle=planned_keys[0],
                    )
                if self.mode == "release":
                    self.add(
                        RULE_DELIVERY,
                        f"release mode rejects planned contract at {location}",
                        needle=planned_keys[0],
                    )
            for key, item in value.items():
                walk(item, f"{location}.{key}" if location else key)

        walk(self.data, "")

    def check_uniqueness(self) -> None:
        sections = (
            "gates",
            "criteria",
            "transitions",
            "checkpoints",
            "roles",
            "artifacts",
            "events",
            "evidence_categories",
            "decisions",
            "event_binding_rules",
        )
        for section in sections:
            seen: set[str] = set()
            for item in self.collection(self.data.get(section)):
                identifier = self.first(item, "id", "event_type", "kind")
                if not isinstance(identifier, str) or not identifier:
                    self.add(RULE_UNIQUE, f"{section} entry has no non-empty id", needle=f'"{section}"')
                    continue
                if identifier in seen:
                    self.add(
                        RULE_UNIQUE,
                        f"duplicate {section} id: {identifier}",
                        needle=f'"{identifier}"',
                    )
                seen.add(identifier)

        path_values: dict[str, str] = {}
        for label, path, _state, _kind in self.iter_paths():
            if "project_scaffold_directories" in label:
                # These records attach delivery state to the canonical directory
                # declarations; repeating the same path here is intentional.
                continue
            normalized = path.rstrip("/")
            if normalized in path_values:
                self.add(
                    RULE_UNIQUE,
                    f"duplicate canonical path {path!r} for {path_values[normalized]} and {label}",
                    needle=path,
                )
            else:
                path_values[normalized] = label

        artifact_paths: dict[str, str] = {}
        for artifact in self.collection(self.data.get("artifacts")):
            identifier = str(artifact.get("id", ""))
            path = artifact.get("path")
            if not isinstance(path, str) or not path:
                self.add(RULE_ARTIFACT, f"artifact {identifier} has no non-empty path")
                continue
            if path in artifact_paths:
                self.add(
                    RULE_UNIQUE,
                    f"duplicate artifact path {path!r} for {artifact_paths[path]} and {identifier}",
                    needle=path,
                )
            artifact_paths[path] = identifier

    def check_contract_invariants(self) -> None:
        vocabularies = self.data.get("vocabularies", {})
        expected_vocabularies = {
            "artifact_statuses": [
                "Draft",
                "Ready for Review",
                "Ready for Approval",
                "Accepted",
                "Complete",
                "Stale",
                "Superseded",
            ],
            "gate_statuses": [
                "pending",
                "drafting",
                "ready_for_review",
                "ready_for_approval",
                "approved",
                "blocked",
                "superseded",
                "closed",
            ],
            "project_statuses": ["initialized", "active", "blocked", "closed"],
            "phase_loop_statuses": [
                "not_started",
                "active",
                "blocked",
                "ready_for_g6",
                "closed",
                "legacy_unreconciled",
            ],
            "phase_statuses": [
                "pending",
                "planning",
                "authorized",
                "in_progress",
                "ready_for_exit",
                "exited",
                "blocked",
                "superseded",
            ],
            "approval_decisions": ["approved", "rejected", "blocked", "superseded"],
            "remediation_dispositions": ["complete", "not_required", "blocked"],
            "value_review_dispositions": ["complete", "not_due", "not_applicable"],
            "value_results": ["met", "missed", "unmeasurable"],
            "enforcement_classes": ["attested", "guarded", "protected"],
            "blast_radius_classes": ["C1", "C2", "C3"],
        }
        if vocabularies != expected_vocabularies:
            self.add(
                RULE_GATE_BINDING,
                "lifecycle vocabularies must match the exact endorsed status and disposition catalogs",
                needle="vocabularies",
            )
        artifact_statuses = set(self.strings(vocabularies.get("artifact_statuses")))

        expected_role_ids = set(
            """none product-vision-agent prd-agent architecture-agent
            security-governance-agent phase-planning-agent implementation-agent
            test-uat-agent code-review-agent remediation-agent
            deployment-readiness-agent as-built-closeout-agent named-human-approver
            named-human-deployment-approver named-human-security-approver
            named-human-operational-owner""".split()
        )
        expected_artifact_ids = set(
            """project_manifest gate_log vision prd architecture technology_stack
            governance_security phase_plan phase_build_plan tactical_plan
            construction_directive build_prompt phase_test_uat implementation_evidence
            phase_code_review phase_remediation phase_learnings phase_as_built
            phase_value_review traceability implementation_summary final_code_review
            aggregate_remediation final_test_uat deployment_readiness production_runbook
            deployment_record project_value_review project_as_built supporting_design""".split()
        )
        expected_criterion_ids = set(
            """G0-MANIFEST G0-SCAFFOLD G0-IDENTITY
            G1-PROBLEM G1-USERS G1-SUCCESS G1-NON-GOALS G1-RISKS-QUESTIONS
            G2-REQ-ID G2-AC-COVERAGE G2-EARS-FORM G2-OBSERVABLE-FORM
            G2-UNWANTED-BEHAVIOR G2-TESTABILITY G3-ARCH-TRACE G3-BOUNDARIES
            G3-STATE-LIFECYCLE G3-STACK-ACCEPTED G3-VERIFICATION-SPEC
            G3-VERIFICATION-TRACE G3-DESIGN-INTERROGATION G4-ACTOR-MODEL
            G4-AUTHORIZATION G4-AUDIT G4-SECRETS-DATA G4-TRUST-TOOLS
            G4-NEGATIVE-TESTS G5-PHASE-ORDER G5-REQ-COVERAGE G5-INTEGRATION
            G5-PARTITION G5-COVERAGE-POLICY G5-PHASE-SCOPE
            G5-PHASE-EXIT-TEST-DESIGN G5-TACTICAL-TASKS G5-TACTICAL-DEPENDENCIES
            G5-TACTICAL-PATHS G5-TACTICAL-TESTS G5-TACTICAL-VERIFICATION
            G5-TACTICAL-ROLLBACK G5-DIRECTIVE-COMPLETE G5-BUILD-PROMPT
            G5-TEST-PLAN-ACCEPTED G5-UPSTREAM-PINNED G5-IMPLEMENTATION-APPROVAL
            G5-EXIT-IMPLEMENTATION G5-EXIT-TEST-UAT G5-EXIT-REVIEW
            G5-EXIT-REMEDIATION G5-EXIT-TRACEABILITY G5-EXIT-AS-BUILT
            G5-EXIT-LEARNINGS G5-EXIT-REGRESSION G5-EXIT-COVERAGE
            G5-EXIT-RESIDUALS G5-EXIT-AMENDMENTS G5-EXIT-VALUE-DISPOSITION
            G5-EXIT-APPROVAL G5-LOOP-AUTHORIZED G5-ALL-PHASES-EXITED
            G5-WHOLE-CANDIDATE G5-INTEGRATION-REGRESSION G5-CURRENT-TRACEABILITY
            G5-RESIDUAL-DISPOSITION G6-IMPLEMENTATION-SUMMARY
            G6-CANDIDATE-REVISION G6-CHANGED-FILES G6-INTEGRATION-REGRESSION
            G6-DEVIATIONS-RESIDUALS G6-REVIEW-PACKAGE G7-INDEPENDENT-REVIEW
            G7-REMEDIATION G7-FINAL-UAT G7-TRACEABILITY G7-RESIDUAL-RISK
            G7-UPSTREAM-BINDINGS G8-READINESS G8-RUNBOOK G8-RELEASE-SCOPE
            G8-CONFIG-SECRETS G8-MIGRATION-ROLLBACK G8-MONITORING-OWNERSHIP
            G8-VALUE-PREREQUISITES G8-DEPLOYMENT-APPROVAL
            G9-DEPLOYMENT-DISPOSITION G9-OPERATIONS-RESULTS G9-VALUE-DISPOSITION
            G9-FINAL-TRACEABILITY G9-AS-BUILT-CLOSEOUT""".split()
        )
        actual_role_ids = {
            str(role.get("id", "")) for role in self.collection(self.data.get("roles"))
        }
        actual_artifact_ids = {
            str(artifact.get("id", ""))
            for artifact in self.collection(self.data.get("artifacts"))
        }
        actual_criterion_ids = {
            str(criterion.get("id", ""))
            for criterion in self.collection(self.data.get("criteria"))
        }
        if actual_role_ids != expected_role_ids:
            self.add(
                RULE_GATE_BINDING,
                "role catalog IDs must match the exact endorsed lifecycle roles",
                needle="roles",
            )
        if actual_artifact_ids != expected_artifact_ids:
            self.add(
                RULE_ARTIFACT,
                "artifact catalog IDs must match the exact endorsed lifecycle artifacts",
                needle="artifacts",
            )
        if actual_criterion_ids != expected_criterion_ids:
            self.add(
                RULE_GATE_BINDING,
                "criterion catalog IDs must match the exact endorsed gate and checkpoint criteria",
                needle="criteria",
            )
        value_review = self.data.get("value_review_contract", {})
        expected_value_dispositions = {
            "complete": {
                "required_fields": {"criterion_results"},
                "allowed_results": {"met", "missed", "unmeasurable"},
                "follow_up_required_for": {"missed", "unmeasurable"},
                "item_contract": "value_result_item",
            },
            "not_due": {
                "required_fields": {
                    "trigger",
                    "expected_date_when_knowable",
                    "owner",
                    "evidence_source",
                    "next_review_mechanism",
                },
                "allowed_results": set(),
                "follow_up_required_for": set(),
                "item_contract": None,
            },
            "not_applicable": {
                "required_fields": {"rationale", "accepted_by", "accepted_on"},
                "allowed_results": set(),
                "follow_up_required_for": set(),
                "item_contract": None,
            },
        }
        actual_value_dispositions: dict[str, dict[str, set[str]]] = {}
        for disposition in self.collection(value_review.get("dispositions")):
            disposition_id = str(disposition.get("id", ""))
            actual_value_dispositions[disposition_id] = {
                "required_fields": set(self.strings(disposition.get("required_fields"))),
                "allowed_results": set(self.strings(disposition.get("allowed_results"))),
                "follow_up_required_for": set(
                    self.strings(disposition.get("follow_up_required_for"))
                ),
                "item_contract": disposition.get("item_contract"),
            }
        if (
            value_review.get("artifact_status_is_separate_from_disposition") is not True
            or value_review.get("unowned_future_work_is_invalid") is not True
            or value_review.get("unmeasurable_is_not_success") is not True
            or actual_value_dispositions != expected_value_dispositions
        ):
            self.add(
                RULE_GATE_BINDING,
                "value-review dispositions must preserve complete/not-due/not-applicable evidence and follow-up contracts",
                needle="value_review_contract",
            )

        ratification = self.data.get("ratification_contract", {})
        if ratification != {
            "reviewed_status": "Ready for Approval",
            "resulting_status": "Accepted",
            "evidence_category": "new_acceptance_status_only",
            "human_record_fields": [
                "decision_record",
                "decision",
                "approver",
                "decision_date",
                "reviewed_revision",
                "reviewed_blob_oid",
                "checked_statement",
                "amendments_or_constraints",
                "risk_disposition",
                "ratification_record",
            ],
            "computed_closeout_fields": [
                "reviewed_digest",
                "resulting_blob_oid",
                "resulting_digest",
            ],
            "status_only_exactly_one_line": True,
            "line_ending_preserved": True,
        }:
            self.add(
                RULE_DECISION,
                "ratification contract must preserve exact human and computed status-only evidence",
                needle="ratification_contract",
            )
        evidence_categories = self.collection(self.data.get("evidence_categories"))
        category_contracts = {
            "new_acceptance_status_only": (
                "Ready for Approval",
                "Accepted",
                False,
                "Only the single canonical Status header changes; every other byte and the line-ending convention are preserved.",
            ),
            "complete_report_unchanged": (
                "Complete",
                "Complete",
                False,
                "Reviewed and resulting Git blob OIDs and portable content digests are equal.",
            ),
            "accepted_authority_unchanged": (
                "Accepted",
                "Accepted",
                True,
                "Reviewed and resulting blobs/digests are equal and the originating approval event binds the same path and blob.",
            ),
        }
        if {str(category.get("id", "")) for category in evidence_categories} != set(
            category_contracts
        ):
            self.add(
                RULE_EVENT,
                "evidence categories must contain exactly the three D-012 result categories",
                needle="evidence_categories",
            )
        for category in evidence_categories:
            identifier = str(category.get("id", ""))
            for key in ("reviewed_status", "resulting_status"):
                status = category.get(key)
                if status not in artifact_statuses:
                    self.add(
                        RULE_EVENT,
                        f"evidence category {identifier} has invalid {key} {status!r}",
                        needle=identifier,
                    )
            expected_contract = category_contracts.get(identifier)
            if expected_contract is not None:
                actual_contract = (
                    category.get("reviewed_status"),
                    category.get("resulting_status"),
                    category.get("originating_event_required"),
                    category.get("content_rule"),
                )
                if actual_contract != expected_contract:
                    self.add(
                        RULE_EVENT,
                        f"evidence category {identifier} violates its D-012 status/origin contract",
                        needle=identifier,
                    )

        evidence_item = self.data.get("event_evidence_item", {})
        required_evidence_fields = {
            "artifact_id",
            "artifact_path",
            "category",
            "reviewed_revision",
            "reviewed_blob_oid",
            "reviewed_digest",
            "resulting_blob_oid",
            "resulting_digest",
            "reviewed_digest",
            "resulting_blob_oid",
            "resulting_digest",
            "status",
        }
        if set(self.strings(evidence_item.get("required_fields"))) != required_evidence_fields:
            self.add(
                RULE_EVENT,
                "event evidence item must declare the complete D-012 required field set",
                needle="event_evidence_item",
            )
        conditional_fields = evidence_item.get("conditional_fields", {})
        if (
            not isinstance(conditional_fields, dict)
            or conditional_fields.get("accepted_authority_unchanged")
            != ["originating_event_id"]
        ):
            self.add(
                RULE_EVENT,
                "accepted unchanged authority evidence must require originating_event_id",
                needle="conditional_fields",
            )
        revision_rules = evidence_item.get("revision_rules", {})
        expected_revision_rules = {
            "must_resolve_in_git": True,
            "dirty_untracked_missing_or_placeholder_rejected": True,
            "reviewed_blob_must_match_revision_path": True,
            "portable_digest_algorithm": "sha256",
            "one_category_exactly": True,
        }
        if not isinstance(revision_rules, dict) or any(
            revision_rules.get(key) != value for key, value in expected_revision_rules.items()
        ):
            self.add(
                RULE_EVENT,
                "event evidence revision rules must preserve exact Git/blob/sha256/category binding",
                needle="revision_rules",
            )

        event_history = self.data.get("event_history", {})
        if (
            event_history.get("append_only") is not True
            or event_history.get("corrections_are_new_events") is not True
            or event_history.get("correction_fields")
            != ["supersedes_event_id", "correction_reason"]
            or event_history.get("duplicate_latest_is_invalid") is not True
            or event_history.get("supersession_cycles_are_invalid") is not True
            or event_history.get("prior_event_text_must_remain_byte_identical") is not True
        ):
            self.add(
                RULE_EVENT,
                "event history must remain append-only with explicit acyclic correction events",
                needle="event_history",
            )
        projection = event_history.get("template_projection")
        projection_state = event_history.get("template_projection_state")
        if projection_state == "current":
            if not isinstance(projection, str) or not self.is_safe_repository_path(projection):
                self.add(
                    RULE_EVENT,
                    "current event-history projection must use a repository-relative template",
                    needle="template_projection",
                )
            elif not (self.root / projection).is_file():
                self.add(
                    RULE_REFERENCE,
                    f"current event-history projection does not exist: {projection}",
                    needle=projection,
                )
            else:
                projection_text = (self.root / projection).read_text(encoding="utf-8")
                section_matches = list(
                    re.finditer(r"(?m)^### ([A-Za-z0-9_:-]+)\s*$", projection_text)
                )
                sections: dict[str, str] = {}
                duplicate_sections: set[str] = set()
                for index, match in enumerate(section_matches):
                    section_id = match.group(1)
                    end = (
                        section_matches[index + 1].start()
                        if index + 1 < len(section_matches)
                        else len(projection_text)
                    )
                    if section_id in sections:
                        duplicate_sections.add(section_id)
                    sections[section_id] = projection_text[match.end() : end]

                projection_errors: list[str] = []
                for event in self.collection(self.data.get("events")):
                    event_id = str(event.get("id", ""))
                    event_section = sections.get(event_id)
                    if event_section is None:
                        projection_errors.append(f"missing event section {event_id}")
                        continue
                    missing_fields = [
                        field
                        for field in self.strings(event.get("required_fields"))
                        if not re.search(rf"\b{re.escape(field)}\b", event_section)
                    ]
                    if missing_fields:
                        projection_errors.append(
                            f"{event_id} missing fields {','.join(missing_fields)}"
                        )
                    conditional_sets = event.get("conditional_field_sets", {})
                    if isinstance(conditional_sets, dict):
                        for profile, fields in conditional_sets.items():
                            profile_match = re.search(
                                rf"(?m)^Profile {re.escape(str(profile))}:\s*(.*)$",
                                event_section,
                            )
                            profile_text = profile_match.group(1) if profile_match else ""
                            missing_profile_fields = [
                                field
                                for field in self.strings(fields)
                                if not re.search(
                                    rf"\b{re.escape(field)}\b", profile_text
                                )
                            ]
                            if profile_match is None or missing_profile_fields:
                                projection_errors.append(
                                    f"{event_id} profile {profile} missing fields "
                                    + ",".join(missing_profile_fields)
                                )

                correction_section = sections.get("event_history_corrections", "")
                serialization = self.data.get("event_serialization", {})
                common_profiles = (
                    serialization.get("common_conditional_field_sets", {})
                    if isinstance(serialization, dict)
                    else {}
                )
                serialized_correction_fields = (
                    common_profiles.get("correction", [])
                    if isinstance(common_profiles, dict)
                    else []
                )
                missing_correction_fields = [
                    field
                    for field in self.strings(serialized_correction_fields)
                    if not re.search(rf"\b{re.escape(field)}\b", correction_section)
                ]
                if missing_correction_fields:
                    projection_errors.append(
                        "event_history_corrections missing fields "
                        + ",".join(missing_correction_fields)
                    )
                if duplicate_sections:
                    projection_errors.append(
                        "duplicate sections " + ",".join(sorted(duplicate_sections))
                    )
                if projection_errors:
                    self.add(
                        RULE_EVENT,
                        "event-history template projection is incomplete: "
                        + "; ".join(projection_errors),
                        file=self.root / projection,
                    )
        elif projection_state != "planned":
            self.add(
                RULE_SCHEMA,
                f"event_history.template_projection_state is invalid: {projection_state!r}",
                needle="template_projection_state",
            )
        self.check_enforcement_record(
            event_history.get("enforcement"),
            label="event history",
            work_package="WP-05",
            contract_field="required_behaviors",
            expected_contract={
                "append_only",
                "correction_event",
                "duplicate_latest_rejected",
                "supersession_cycle_rejected",
            },
        )

        reference_item = self.data.get("event_reference_item", {})
        expected_reference_fields = {
            "artifact_id",
            "artifact_path",
            "status",
            "revision",
            "blob_oid",
            "digest",
        }
        if (
            set(self.strings(reference_item.get("required_fields")))
            != expected_reference_fields
            or reference_item.get("portable_digest_algorithm") != "sha256"
            or reference_item.get("cannot_satisfy_acceptance_without_evidence_category")
            is not True
        ):
            self.add(
                RULE_EVENT,
                "event reference items must preserve path/revision/blob/sha256 evidence binding",
                needle="event_reference_item",
            )

        event_minimums = {
            "project_initialization": {
                "event_id",
                "event_type",
                "schema_version",
                "project",
                "from_gate",
                "to_gate",
                "occurred_on",
                "manifest_result",
                "checked_statement",
            },
            "gate_transition": {
                "event_id",
                "event_type",
                "schema_version",
                "project",
                "from_gate",
                "to_gate",
                "criterion_ids",
                "evidence",
                "approval_profile",
                "checked_statement",
                "enforcement_context",
                "manifest_result",
                "next_state",
            },
        }
        approval_event_fields = {
            "event_id",
            "event_type",
            "schema_version",
            "project",
            "criterion_ids",
            "evidence",
            "decision",
            "approver",
            "approved_on",
            "checked_statement",
            "risk_disposition",
            "enforcement_context",
            "manifest_result",
            "next_state",
        }
        for event_type in ("phase_checkpoint", "phase_transition", "deployment_approval"):
            event_minimums[event_type] = approval_event_fields
        event_minimums["phase_checkpoint"] = approval_event_fields | {
            "major_gate",
            "position",
        }
        event_minimums["phase_transition"] = approval_event_fields | {
            "major_gate",
            "position",
            "phase_id",
            "candidate_revision",
            "test_uat_execution",
            "blocking_finding_count",
            "remediation_disposition",
            "phase_requirement_ids",
            "regression_result",
            "coverage_result",
            "residual_findings",
            "amendments",
            "references",
        }
        event_minimums["deployment_approval"] = approval_event_fields | {
            "major_gate",
            "release_candidate",
            "deployment_intent",
            "security_approval",
            "value_prerequisites",
        }
        generic_event_fields = {"event_id", "event_type", "schema_version", "project"}
        event_minimums["amendment"] = generic_event_fields | {
            "authority_path",
            "change_scope",
            "impact",
            "evidence",
            "decision",
            "approver",
            "approved_on",
            "checked_statement",
            "risk_disposition",
            "enforcement_context",
            "next_state",
        }
        event_minimums["gate_regression"] = generic_event_fields | {
            "from_gate",
            "to_gate",
            "invalidated_criteria",
            "decision",
            "approver",
            "approved_on",
            "checked_statement",
            "risk_disposition",
            "enforcement_context",
            "manifest_result",
            "next_state",
        }
        event_minimums["reconciliation"] = generic_event_fields | {
            "amendment_id",
            "artifacts",
            "remaining_stale_artifacts",
            "gate_movement_unblocked",
            "reconciled_on",
            "reconciled_by",
            "checked_statement",
            "manifest_result",
        }
        event_minimums["migration_reconciliation"] = generic_event_fields | {
            "source_methodology_version",
            "target_methodology_version",
            "historical_event_reference",
            "mapped_gate_or_checkpoint",
            "mapped_evidence_classes",
            "unresolved_fields",
            "provenance",
            "decision",
            "approval_disposition",
            "risk_disposition",
            "checked_statement",
        }
        event_minimums["traceability_sample"] = generic_event_fields | {
            "gate",
            "phase_id",
            "sampled_by",
            "sampled_on",
            "requirement_id",
            "traceability_row",
            "result",
            "discrepancy",
            "discrepancy_disposition",
        }
        event_minimums["enforcement_attestation"] = generic_event_fields | {
            "gate",
            "attested_by",
            "attested_on",
            "requirements_checked",
            "result",
            "exceptions",
        }
        event_minimums["enforcement_override"] = generic_event_fields | {
            "gate",
            "decision",
            "approved_by",
            "approved_on",
            "requirements_bypassed",
            "reason",
            "incident_or_emergency",
            "checked_statement",
            "risk_disposition",
            "enforcement_context",
            "normal_enforcement_resumed_on",
            "reconciliation_required",
            "next_state",
        }
        changes_major_gate = {
            "project_initialization": True,
            "gate_transition": True,
            "phase_checkpoint": False,
            "phase_transition": False,
            "deployment_approval": False,
            "amendment": False,
            "gate_regression": True,
            "reconciliation": False,
            "migration_reconciliation": False,
            "traceability_sample": False,
            "enforcement_attestation": False,
            "enforcement_override": False,
        }
        events = self.collection(self.data.get("events"))
        event_ids = {str(event.get("id", "")) for event in events}
        if event_ids != set(changes_major_gate):
            self.add(
                RULE_EVENT,
                "event catalog must contain exactly the required lifecycle event types",
                needle="events",
            )
        evidence_category_ids = {
            str(category.get("id", "")) for category in evidence_categories
        }
        binding_rules = self.collection(self.data.get("event_binding_rules"))
        binding_ids = {str(rule.get("id", "")) for rule in binding_rules}
        expected_binding_ids = {
            "all_declared_phase_exit_event_ids",
            "accepted_upstream_authority_set",
            "deployment_approval_or_non_deployment_approval",
        }
        if binding_ids != expected_binding_ids:
            self.add(
                RULE_EVENT,
                "event binding rules must contain exactly the required lifecycle predicates",
                needle="event_binding_rules",
            )
        binding_by_id = {str(binding.get("id", "")): binding for binding in binding_rules}
        phase_exit_binding = binding_by_id.get("all_declared_phase_exit_event_ids", {})
        if (
            phase_exit_binding.get("event_type") != "phase_transition"
            or phase_exit_binding.get("quantifier")
            != "exactly_one_per_declared_nonsuperseded_phase"
            or phase_exit_binding.get("coverage_source") != "manifest.phase.phases"
            or phase_exit_binding.get("position_pattern")
            != r"^G5\.[A-Za-z0-9]+(-[A-Za-z0-9]+)*\.4$"
            or phase_exit_binding.get("allowed_decisions") != ["approved"]
            or phase_exit_binding.get("same_project_required") is not True
            or phase_exit_binding.get("exact_candidate_required") is not True
        ):
            self.add(
                RULE_EVENT,
                "phase-exit event binding predicate is incomplete",
                needle="all_declared_phase_exit_event_ids",
            )
        upstream_binding = binding_by_id.get("accepted_upstream_authority_set", {})
        if (
            upstream_binding.get("event_types") != ["gate_transition", "phase_checkpoint"]
            or upstream_binding.get("quantifier") != "every_reused_accepted_authority"
            or upstream_binding.get("evidence_category") != "accepted_authority_unchanged"
            or upstream_binding.get("originating_event_required") is not True
            or upstream_binding.get("same_path_and_blob_required") is not True
        ):
            self.add(
                RULE_EVENT,
                "accepted-upstream event binding predicate is incomplete",
                needle="accepted_upstream_authority_set",
            )
        deployment_binding = binding_by_id.get(
            "deployment_approval_or_non_deployment_approval", {}
        )
        if (
            deployment_binding.get("event_type") != "deployment_approval"
            or deployment_binding.get("quantifier") != "exactly_one_latest_unsuperseded"
            or deployment_binding.get("major_gate") != "G8"
            or deployment_binding.get("allowed_intents") != ["deploy", "non_deployment"]
            or deployment_binding.get("allowed_decisions") != ["approved"]
            or deployment_binding.get("same_project_required") is not True
            or deployment_binding.get("exact_release_candidate_required") is not True
            or deployment_binding.get("required_criterion_ids_source")
            != "deployment.criterion_ids"
            or deployment_binding.get("terminal_correlation_contract")
            != "deployment.terminal_correlations"
        ):
            self.add(
                RULE_EVENT,
                "deployment event binding predicate is incomplete",
                needle="deployment_approval_or_non_deployment_approval",
            )
        for binding in binding_rules:
            identifier = str(binding.get("id", ""))
            raw_event_types = binding.get("event_types", binding.get("event_type"))
            category = binding.get("evidence_category")
            binding_event_types = self.strings(raw_event_types)
            if not binding_event_types or any(
                event_type not in event_ids for event_type in binding_event_types
            ):
                self.add(
                    RULE_EVENT,
                    f"event binding predicate {identifier} references unknown event types {raw_event_types!r}",
                    needle=identifier,
                )
            if category is not None and category not in evidence_category_ids:
                self.add(
                    RULE_EVENT,
                    f"event binding predicate {identifier} references unknown evidence category {category!r}",
                    needle=identifier,
                )
        for transition in self.collection(self.data.get("transitions")):
            identifier = str(transition.get("id", ""))
            for field in ("required_event_bindings", "required_dynamic_evidence"):
                raw_bindings = transition.get(field, [])
                if not isinstance(raw_bindings, (str, list)):
                    self.add(
                        RULE_EVENT,
                        f"transition {identifier} {field} must be a predicate ID or array",
                        needle=identifier,
                    )
                    continue
                for binding_id in self.strings(raw_bindings):
                    if binding_id not in binding_ids:
                        self.add(
                            RULE_EVENT,
                            f"transition {identifier} references unknown event predicate {binding_id}",
                            needle=identifier,
                        )
        for event in events:
            identifier = str(event.get("id", ""))
            if event.get("schema_version") != 2:
                self.add(
                    RULE_EVENT,
                    f"event {identifier} schema_version must be 2",
                    needle=identifier,
                )
            if event.get("append_only") is not True:
                self.add(
                    RULE_EVENT,
                    f"event {identifier} must be append-only",
                    needle=identifier,
                )
            expected_major_change = changes_major_gate.get(identifier)
            if expected_major_change is not None and event.get(
                "changes_major_gate"
            ) is not expected_major_change:
                self.add(
                    RULE_EVENT,
                    f"event {identifier} changes_major_gate must be {str(expected_major_change).lower()}",
                    needle=identifier,
                )
            fields = set(self.strings(event.get("required_fields")))
            required = event_minimums.get(identifier, generic_event_fields)
            missing = sorted(required - fields)
            if missing:
                self.add(
                    RULE_EVENT,
                    f"event {identifier} omits required fields: {', '.join(missing)}",
                    needle=identifier,
                )
            if identifier == "gate_transition":
                expected_profiles = {
                    "named_human": [
                        "decision",
                        "approver",
                        "approved_on",
                        "risk_disposition",
                    ],
                    "no_additional_approval": [
                        "approval_disposition",
                        "recorded_by",
                        "recorded_on",
                        "no_additional_approval_basis",
                    ],
                    "G8-to-G9": [
                        "deployment_disposition",
                        "operational_results",
                        "value_disposition",
                        "terminal_closeout",
                    ],
                    "G8-to-G9:deploy": ["operational_owner_confirmation"],
                }
                if event.get("conditional_field_sets") != expected_profiles:
                    self.add(
                        RULE_EVENT,
                        "gate_transition must declare exact approval and deploy-only terminal profiles",
                        needle=identifier,
                    )
            if identifier == "phase_transition" and event.get("conditional_field_sets") != {
                "delegated_phase_exit": ["delegation"]
            }:
                self.add(
                    RULE_EVENT,
                    "phase_transition must bind delegated phase exit to the delegation field",
                    needle=identifier,
                )
            if identifier == "deployment_approval" and event.get(
                "conditional_field_sets"
            ) != {
                "non_deployment": [
                    "disposition",
                    "rationale",
                    "scope",
                    "release_candidate",
                    "approver",
                    "approved_on",
                    "future_trigger_or_finality",
                ]
            }:
                self.add(
                    RULE_EVENT,
                    "deployment approval must bind the exact non-deployment field profile",
                    needle=identifier,
                )
            if identifier == "phase_checkpoint" and event.get("field_constraints") != {
                "phase_id": {"nullable_only_at": ["G5.0"]}
            }:
                self.add(
                    RULE_EVENT,
                    "phase_checkpoint phase_id may be null only at G5.0",
                    needle=identifier,
                )
            if identifier == "migration_reconciliation" and (
                event.get("allowed_decisions") != ["mapped", "partially_mapped", "not_mapped"]
                or event.get("conditional_field_sets")
                != {
                    "named_human_required": ["approver", "approval_date"],
                    "duplicate_mapping": ["supersedes_event_id", "correction_reason"],
                }
            ):
                self.add(
                    RULE_EVENT,
                    "migration_reconciliation must preserve mapping decisions and named-human conditional fields",
                    needle=identifier,
                )
            if identifier == "migration_reconciliation":
                historical_reference_contract = event.get(
                    "historical_event_reference_contract", {}
                )
                approval_rules = event.get("approval_rules", {})
                if (
                    historical_reference_contract
                    != {
                        "allowed_kinds": ["stable_event_id", "content_digest"],
                        "required_fields_by_kind": {
                            "stable_event_id": ["event_id"],
                            "content_digest": [
                                "source_path",
                                "reviewed_revision",
                                "digest_algorithm",
                                "content_digest",
                            ],
                        },
                        "digest_algorithm": "sha256",
                        "line_number_only_forbidden": True,
                    }
                    or approval_rules
                    != {
                        "named_human_required_when": [
                            "blast_radius_C3",
                            "unresolved_approval_provenance",
                            "unresolved_security_provenance",
                            "residual_historical_uncertainty_accepted",
                        ],
                        "critical_security_or_approval_uncertainty_waivable": False,
                        "automation_or_unbound_role_may_approve": False,
                    }
                    or event.get("unresolved_fields_propagate_to_readiness") is not True
                    or event.get("duplicate_mapping_requires_supersedes_event_id") is not True
                ):
                    self.add(
                        RULE_EVENT,
                        "migration reconciliation must preserve stable references, approval predicates, and uncertainty propagation",
                        needle=identifier,
                    )

        for role in self.collection(self.data.get("roles")):
            identifier = str(role.get("id", ""))
            if identifier.endswith("-agent") and role.get("may_approve") is not False:
                self.add(
                    RULE_APPROVAL,
                    f"automation role {identifier} may not approve lifecycle transitions",
                    needle=identifier,
                )
            if role.get("kind") == "human_approval" and role.get("may_approve") is not True:
                self.add(
                    RULE_APPROVAL,
                    f"named human approval role {identifier} must retain approval authority",
                    needle=identifier,
                )
            source = role.get("source_file")
            if isinstance(source, str) and not self.is_safe_repository_path(source):
                self.add(
                    RULE_REFERENCE,
                    f"role {identifier} source_file must be a safe repository-relative path",
                    needle=identifier,
                )

        gates = self.collection(self.data.get("gates"))
        for gate in gates:
            identifier = str(gate.get("id", ""))
            approval = str(gate.get("human_approval", ""))
            if "automation" in approval or (identifier != "G0" and approval == "not_required"):
                self.add(
                    RULE_APPROVAL,
                    f"gate {identifier} may not delegate approval to automation",
                    needle=identifier,
                )
            expected_terminal = identifier == "G9"
            if gate.get("terminal") is not expected_terminal:
                self.add(
                    RULE_GATE_BINDING,
                    f"gate {identifier} terminal must be {str(expected_terminal).lower()}",
                    needle=identifier,
                )
        if gates:
            terminal = gates[-1]
            if (
                terminal.get("id") != "G9"
                or terminal.get("successor") is not None
                or terminal.get("active_role") != "none"
            ):
                self.add(
                    RULE_GATE_BINDING,
                    "G9 must be terminal with no successor and active role none",
                    needle='"G9"',
                )

        artifact_by_id = {
            str(artifact.get("id")): artifact
            for artifact in self.collection(self.data.get("artifacts"))
        }
        paths = self.data.get("paths", {})
        declared_paths: dict[str, str] = {}
        declared_paths.update(paths.get("canonical_fixed_artifacts", {}))
        declared_paths.update(paths.get("phase_artifact_patterns", {}))
        for identifier, path in declared_paths.items():
            artifact_id = "project_manifest" if identifier == "manifest" else identifier
            artifact = artifact_by_id.get(artifact_id)
            if artifact is None or artifact.get("path") != path:
                self.add(
                    RULE_ARTIFACT,
                    f"path catalog and artifact {artifact_id} declaration disagree",
                    needle=str(path),
                )
        for artifact in artifact_by_id.values():
            identifier = str(artifact.get("id", ""))
            allowed = artifact.get("allowed_statuses")
            if not isinstance(allowed, list) or any(
                not isinstance(status, str) or status not in artifact_statuses
                for status in allowed
            ):
                self.add(
                    RULE_ARTIFACT,
                    f"artifact {identifier} allowed_statuses must use the declared vocabulary",
                    needle=identifier,
                )
            path = artifact.get("path")
            if isinstance(path, str) and not self.is_safe_repository_path(path):
                self.add(
                    RULE_FIXED_PATH,
                    f"artifact {identifier} path must be project-relative: {path}",
                    needle=identifier,
                )
            if (
                artifact.get("path_kind") == "fixed"
                and isinstance(path, str)
                and re.search(r"<[^>]+>|\[[^]]+\]", path)
            ):
                self.add(
                    RULE_FIXED_PATH,
                    f"fixed artifact path contains a placeholder: {path}",
                    needle=path,
                )

        for transition in self.collection(self.data.get("transitions")):
            identifier = str(transition.get("id", ""))
            command = transition.get("command")
            if not isinstance(command, str) or not command:
                self.add(RULE_REFERENCE, f"transition {identifier} has no command")
                continue
            try:
                command_path = shlex.split(command)[0]
            except (ValueError, IndexError):
                self.add(RULE_REFERENCE, f"transition {identifier} has an invalid command")
                continue
            if not self.is_safe_repository_path(command_path) or not (
                self.root / command_path
            ).is_file():
                self.add(
                    RULE_REFERENCE,
                    f"transition {identifier} command does not resolve in the repository: {command_path}",
                    needle=identifier,
                )

        deployment = self.data.get("deployment", {})
        deploy_path = deployment.get("deploy_path", {})
        if (
            not isinstance(deploy_path, dict)
            or deploy_path.get("authorization_required_before_action") is not True
        ):
            self.add(
                RULE_APPROVAL,
                "deployment path requires authorization before production action",
                needle="deploy_path",
            )
        authorization_event = deployment.get("authorization_event")
        if authorization_event != "deployment_approval" or authorization_event not in event_ids:
            self.add(
                RULE_EVENT,
                "deployment.authorization_event must bind the deployment_approval event",
                needle="authorization_event",
            )

        approval_policy = self.data.get("approval_policy", {})
        phase_exit_policy = approval_policy.get("phase_exit", {})
        if phase_exit_policy != {
            "approver_kind": "named_human",
            "c1_c2_delegation_allowed": True,
            "delegation_event_type": "phase_transition",
            "delegation_event_profile": "delegated_phase_exit",
            "delegation_event_field": "delegation",
            "delegation_allowed_classes": ["C1", "C2"],
            "delegation_prohibited_classes": ["C3"],
            "c1_c2_delegation_required_fields": [
                "delegated_by",
                "delegated_to",
                "accepted_by",
                "scope",
                "starts_on",
                "ends_on",
            ],
            "c3_delegation_allowed": False,
            "automation_or_unbound_role_may_approve": False,
            "critical_findings_block": True,
            "major_residual_requires_named_human_risk_acceptance": True,
        }:
            self.add(
                RULE_APPROVAL,
                "phase-exit approval must preserve exact delegation and residual-risk policy",
                needle="phase_exit",
            )
        checkpoint_policy = approval_policy.get("phase_checkpoint_acceptance", {})
        if checkpoint_policy != {
            "approver_kind": "named_human",
            "changes_major_gate": False,
            "automation_or_unbound_role_may_approve": False,
        }:
            self.add(
                RULE_APPROVAL,
                "phase checkpoint acceptance must remain named-human without changing the major gate",
                needle="phase_checkpoint_acceptance",
            )
        expected_approval_kinds = {
            "implementation_acceptance": "named_human",
            "deployment": "named_human_deployment_approver",
            "project_closeout": "named_human",
        }
        for policy_id, approver_kind in expected_approval_kinds.items():
            policy = approval_policy.get(policy_id, {})
            if (
                not isinstance(policy, dict)
                or policy.get("approver_kind") != approver_kind
                or policy.get("automation_or_unbound_role_may_approve") is not False
            ):
                self.add(
                    RULE_APPROVAL,
                    f"{policy_id} policy must preserve its named-human approval contract",
                    needle=policy_id,
                )
        if approval_policy.get("deployment", {}).get(
            "security_approver_when_governance_requires"
        ) is not True:
            self.add(
                RULE_APPROVAL,
                "deployment approval must retain conditional security approval",
                needle="deployment",
            )
        if approval_policy.get("project_closeout", {}).get(
            "operational_owner_confirmation_when_deployed"
        ) is not True:
            self.add(
                RULE_APPROVAL,
                "project closeout must retain deployed operational-owner confirmation",
                needle="project_closeout",
            )

        transitions_by_id = {
            str(transition.get("id")): transition
            for transition in self.collection(self.data.get("transitions"))
        }
        implementation_acceptance = transitions_by_id.get("G7-to-G8", {})
        if (
            implementation_acceptance.get("approval")
            != "named_human_implementation_acceptance"
            or implementation_acceptance.get("approval_profiles") != ["named_human"]
        ):
            self.add(
                RULE_APPROVAL,
                "G7-to-G8 must retain named-human implementation acceptance",
                needle="G7-to-G8",
            )
        project_closeout = transitions_by_id.get("G8-to-G9", {})
        if (
            project_closeout.get("approval") != "named_human_project_closeout"
            or project_closeout.get("approval_profiles") != ["named_human"]
        ):
            self.add(
                RULE_APPROVAL,
                "G8-to-G9 must retain named-human project closeout",
                needle="G8-to-G9",
            )
        phase_exit_checkpoint = next(
            (
                checkpoint
                for checkpoint in self.collection(self.data.get("checkpoints"))
                if checkpoint.get("id") == "G5.<id>.4"
            ),
            {},
        )
        phase_value_reference = next(
            (
                requirement
                for requirement in self.collection(
                    phase_exit_checkpoint.get("reference_requirements")
                )
                if requirement.get("artifact_id") == "phase_value_review"
            ),
            {},
        )
        if (
            phase_value_reference.get("disposition_contract") != "value_review_contract"
            or phase_value_reference.get("binding_mode") != "pinned_subordinate_reference"
            or phase_value_reference.get("parent_artifact_id") != "phase_as_built"
            or phase_value_reference.get("status_by_disposition")
            != {
                "complete": ["Complete"],
                "not_due": ["Draft"],
                "not_applicable": ["Complete"],
            }
            or set(self.strings(phase_value_reference.get("required_dispositions")))
            != {"complete", "not_due", "not_applicable"}
            or not {"value_review.disposition", "value_review.details"}
            <= set(self.strings(phase_value_reference.get("required_fields")))
        ):
            self.add(
                RULE_PHASE_EXIT,
                "phase value disposition must be a pinned subordinate reference governed by value_review_contract",
                needle="phase_value_review",
            )

        value_prerequisite = deployment.get("value_prerequisite_contract", {})
        if value_prerequisite != {
            "contract": "value_review_contract",
            "required_fields": ["disposition", "details"],
            "must_be_complete_before_authorization": True,
        }:
            self.add(
                RULE_GATE_BINDING,
                "deployment value prerequisites must bind the complete value_review_contract",
                needle="value_prerequisite_contract",
            )
        project_value_requirement = next(
            (
                requirement
                for requirement in self.collection(project_closeout.get("artifact_requirements"))
                if requirement.get("artifact_id") == "project_value_review"
            ),
            {},
        )
        if (
            project_value_requirement.get("disposition_contract") != "value_review_contract"
            or set(self.strings(project_value_requirement.get("required_dispositions")))
            != {"complete", "not_due", "not_applicable"}
        ):
            self.add(
                RULE_GATE_BINDING,
                "G8-to-G9 project value evidence must bind value_review_contract",
                needle="project_value_review",
            )

        expected_deployment_requirements = [
            {
                "artifact_id": "deployment_readiness",
                "reviewed_statuses": ["Ready for Approval"],
                "resulting_statuses": ["Accepted"],
                "evidence_categories": ["new_acceptance_status_only"],
            },
            {
                "artifact_id": "production_runbook",
                "reviewed_statuses": ["Complete"],
                "resulting_statuses": ["Complete"],
                "evidence_categories": ["complete_report_unchanged"],
            },
        ]
        if (
            deployment.get("artifact_requirements") != expected_deployment_requirements
            or deployment.get("authorization_event") != "deployment_approval"
            or deployment.get("intents") != ["deploy", "non_deployment"]
            or deployment.get("production_action_automatic") is not False
        ):
            self.add(
                RULE_GATE_BINDING,
                "deployment approval must bind readiness/runbook evidence and never perform production automatically",
                needle="deployment",
            )
        expected_g8_criteria = {
            "G8-READINESS",
            "G8-RUNBOOK",
            "G8-RELEASE-SCOPE",
            "G8-CONFIG-SECRETS",
            "G8-MIGRATION-ROLLBACK",
            "G8-MONITORING-OWNERSHIP",
            "G8-VALUE-PREREQUISITES",
            "G8-DEPLOYMENT-APPROVAL",
        }
        gates_by_id = {
            str(gate.get("id")): gate for gate in self.collection(self.data.get("gates"))
        }
        if (
            set(self.strings(deployment.get("criterion_ids"))) != expected_g8_criteria
            or set(self.strings(gates_by_id.get("G8", {}).get("criterion_ids")))
            != expected_g8_criteria
        ):
            self.add(
                RULE_GATE_BINDING,
                "deployment and G8 must bind the exact readiness/operations criterion set",
                needle="criterion_ids",
            )
        deploy_path = deployment.get("deploy_path", {})
        non_deployment_path = deployment.get("non_deployment_path", {})
        if (
            deploy_path
            != {
                "authorization_required_before_action": True,
                "deployment_record_status": "Complete",
                "operational_owner_confirmation_required": True,
                "terminal_disposition": "deployed",
                "production_action_performed": True,
            }
            or non_deployment_path
            != {
                "allowed": True,
                "authorization_required": True,
                "required_fields": [
                    "disposition",
                    "rationale",
                    "scope",
                    "release_candidate",
                    "approver",
                    "approved_on",
                    "future_trigger_or_finality",
                ],
                "deployment_record_status": "Complete",
                "terminal_disposition": "not_deployed",
                "production_action_performed": False,
            }
        ):
            self.add(
                RULE_APPROVAL,
                "deployment and non-deployment paths must preserve authorization, owner, disposition, and action semantics",
                needle="deploy_path",
            )
        expected_terminal_correlations = [
            {
                "authorization_intent": "deploy",
                "terminal_disposition": "deployed",
                "production_action_performed": True,
            },
            {
                "authorization_intent": "non_deployment",
                "terminal_disposition": "not_deployed",
                "production_action_performed": False,
            },
        ]
        if (
            deployment.get("terminal_correlations") != expected_terminal_correlations
            or deployment.get("authorization_intent_must_match_terminal_disposition") is not True
            or deployment.get("terminal_transition") != "G8-to-G9"
        ):
            self.add(
                RULE_GATE_BINDING,
                "deployment authorization intent must correlate exactly with terminal disposition/action",
                needle="terminal_correlations",
            )
        if (
            self.strings(transitions_by_id.get("G5-to-G6", {}).get("required_event_bindings"))
            != ["all_declared_phase_exit_event_ids"]
            or self.strings(
                transitions_by_id.get("G7-to-G8", {}).get("required_dynamic_evidence")
            )
            != ["accepted_upstream_authority_set"]
            or self.strings(transitions_by_id.get("G8-to-G9", {}).get("required_event_bindings"))
            != ["deployment_approval_or_non_deployment_approval"]
            or transitions_by_id.get("G8-to-G9", {}).get(
                "conditional_transition_specific_event_fields"
            )
            != {"deploy": ["operational_owner_confirmation"]}
            or "operational_owner_confirmation"
            in self.strings(
                transitions_by_id.get("G8-to-G9", {}).get(
                    "transition_specific_event_fields"
                )
            )
        ):
            self.add(
                RULE_EVENT,
                "G5/G7/G8 transitions must retain their required event/dynamic predicate bindings",
                needle="required_event_bindings",
            )

        scaling = self.data.get("scaling", {})
        criterion_form = scaling.get("g2_criterion_form_by_class", {})
        expected_forms = {
            "C1": {
                "required_all": set(),
                "required_any": {"G2-EARS-FORM", "G2-OBSERVABLE-FORM"},
            },
            "C2": {"required_all": {"G2-EARS-FORM"}, "required_any": set()},
            "C3": {"required_all": {"G2-EARS-FORM"}, "required_any": set()},
        }
        actual_forms: dict[str, dict[str, set[str]]] = {}
        if isinstance(criterion_form, dict):
            for class_id, contract in criterion_form.items():
                if isinstance(contract, dict):
                    actual_forms[class_id] = {
                        "required_all": set(self.strings(contract.get("required_all"))),
                        "required_any": set(self.strings(contract.get("required_any"))),
                    }
        if actual_forms != expected_forms:
            self.add(
                RULE_GATE_BINDING,
                "G2 criterion-form scaling must preserve the C1 alternative and C2/C3 EARS rule",
                needle="g2_criterion_form_by_class",
            )
        expected_scaling_classes = [
            {
                "id": "C1",
                "label": "Contained",
                "gate_combination": "G1-G4 may combine with explicit content preservation, evidence, named-human approval, and recorded justification.",
                "requirements_form": "plain_observable_or_ears",
                "unwanted_behavior_required": True,
                "verification_spec_required": True,
                "design_interrogation": "proportional",
                "phase_exit_evidence_waivable": False,
            },
            {
                "id": "C2",
                "label": "Standard",
                "gate_combination": "Full chain by default; a combination requires explicit span, preserved criteria, justification, and named-human approval.",
                "requirements_form": "ears",
                "unwanted_behavior_required": True,
                "verification_spec_required": True,
                "design_interrogation": "proportional",
                "phase_exit_evidence_waivable": False,
            },
            {
                "id": "C3",
                "label": "Critical",
                "gate_combination": "prohibited",
                "requirements_form": "ears",
                "unwanted_behavior_required": True,
                "verification_spec_required": True,
                "design_interrogation": "expanded",
                "phase_exit_evidence_waivable": False,
            },
        ]
        if (
            scaling.get("classes") != expected_scaling_classes
            or scaling.get("combined_gate_required_fields")
            != [
                "span",
                "blast_radius_class",
                "mode",
                "justification",
                "preserved_criterion_ids",
                "evidence",
                "approved_by",
                "approved_on",
                "event_id",
            ]
            or scaling.get("combined_gate_rules")
            != {
                "c3_prohibited": True,
                "nonadjacent_requires_declared_decision": True,
                "all_spanned_criteria_preserved": True,
                "nonwaivable_evidence_preserved": True,
                "phase_exit_may_combine_form_not_evidence": True,
            }
        ):
            self.add(
                RULE_GATE_BINDING,
                "D-017 scaling classes and combined-gate preservation rules must remain exact",
                needle="scaling",
            )
        unwanted_criterion = next(
            (
                criterion
                for criterion in self.collection(self.data.get("criteria"))
                if criterion.get("id") == "G2-UNWANTED-BEHAVIOR"
            ),
            {},
        )
        if unwanted_criterion != {
            "id": "G2-UNWANTED-BEHAVIOR",
            "gate": "G2",
            "description": "Every class states unwanted behavior wherever an error or failure path exists.",
        }:
            self.add(
                RULE_GATE_BINDING,
                "G2 unwanted-behavior criterion must remain an explicit all-class requirement",
                needle="G2-UNWANTED-BEHAVIOR",
            )
        coverage_policy = scaling.get("coverage_policy", {})
        expected_coverage_fields = {
            "metric",
            "measurement_tool",
            "denominator",
            "target",
            "scope",
            "measurement_command",
            "exclusions",
            "exclusion_rationale",
            "owner",
            "shortfall_disposition",
        }
        if (
            not isinstance(coverage_policy, dict)
            or coverage_policy.get("universal_percentage") is not None
            or set(self.strings(coverage_policy.get("required_fields")))
            != expected_coverage_fields
            or coverage_policy.get("shortfall_requires_named_risk_acceptance") is not True
        ):
            self.add(
                RULE_GATE_BINDING,
                "coverage policy must remain project-declared, measurable, and risk-disposed",
                needle="coverage_policy",
            )

        naa = self.data.get("naa", {})
        expected_naa = {
            "authority_bearing_categories": {
                "domain_business_entity_or_invariant",
                "persisted_shared_external_or_security_relevant_field",
                "public_or_cross_component_contract",
                "architectural_component_or_ownership_boundary",
                "trust_identity_authorization_audit_or_lifecycle_boundary",
            },
            "task_permitted_private_categories": {
                "private_helper",
                "local_adapter",
                "internal_value_type",
                "test_fixture",
                "fake",
                "mock",
                "framework_generated_type",
            },
            "private_exception_conditions": {
                "no_new_product_concept",
                "no_persisted_or_shared_state",
                "no_public_contract",
                "no_ownership_boundary",
                "no_governance_behavior",
                "covered_by_approved_tactical_task",
            },
        }
        if naa.get("name") != "No Undeclared Abstractions" or any(
            set(self.strings(naa.get(key))) != expected_values
            for key, expected_values in expected_naa.items()
        ) or set(self.strings(naa.get("quality_principles_still_apply"))) != {
            "YAGNI",
            "KISS",
            "DRY",
            "SRP",
            "Least Astonishment",
        }:
            self.add(
                RULE_GATE_BINDING,
                "NAA must preserve its exact authority boundary and private-task exception",
                needle="naa",
            )

        compatibility = self.data.get("compatibility", {})
        if (
            compatibility.get("new_project_mode") != "strict_schema_v2"
            or compatibility.get("legacy_mode") != "explicit_version_bound_migration"
            or compatibility.get("new_events_in_legacy_mode") != "must_conform_to_schema_v2"
            or compatibility.get("automatic_gate_regression") is not False
        ):
            self.add(
                RULE_GATE_BINDING,
                "compatibility policy must remain strict, version-bound, and non-regressive",
                needle="compatibility",
            )
        expected_scaffold_state = "current" if self.mode == "release" else "planned"
        if compatibility.get("scaffold") != {
            "fresh_init": "project_wide_only",
            "phase_scaffold_command": "scripts/init-phase.sh",
            "phase_scaffold_state": expected_scaffold_state,
            "required_work_package": "WP-04",
            "seed_phase_option": "--seed-phase",
            "seed_phase_must_be_complete": True,
        }:
            self.add(
                RULE_GATE_BINDING,
                "D-014 scaffold timing and complete --seed-phase contract must remain exact",
                needle="scaffold",
            )

        generation = self.data.get("generation", {})
        runtime_policy = generation.get("runtime_dependency_policy", {})
        expected_platforms = [
            "macOS system Bash 3.2 and BSD utilities",
            "Ubuntu GitHub-hosted runner Bash and GNU utilities",
        ]
        if (
            generation.get("deterministic") is not True
            or generation.get("registry_digest_algorithm") != "sha256"
            or generation.get("platform_contract") != expected_platforms
            or not isinstance(runtime_policy, dict)
            or runtime_policy.get("installed_transition_commands_require_python") is not False
            or runtime_policy.get("installed_core")
            != ["Bash 3.2", "portable POSIX-like utilities", "Git", "tar"]
            or runtime_policy.get("baseline_only_validator") != "Python 3 standard library"
            or generation.get("forbidden_shell_features")
            != [
                "mapfile",
                "associative arrays",
                "sed -i",
                "GNU 0,/regex/ addressing",
                "GNU-only cpio flags",
            ]
        ):
            self.add(
                RULE_GENERATED,
                "generation must preserve deterministic portable shell and Python-free installed transitions",
                needle="generation",
            )

        references = self.data.get("references", {})
        depth_policy = references.get("depth_policy", {})
        expected_target_kinds = {
            "canonical_artifact": {
                "path_scope": "canonical_fixed_or_phase_artifact",
                "identity_contract": "registered_artifact_identity_and_provenance",
                "authority_direction": "derive_from_registered_artifact_kind",
                "lifecycle_owner": "registered_artifact_owner_and_bindings",
                "cycle_policy": "global_reference_dag",
                "depth_policy": "registered_canonical_lifecycle",
                "validation_severity": "error_when_mechanical_warning_when_judgment",
            },
            "supporting_design": {
                "path_scope": "docs/project/design/",
                "identity_contract": "project_identity_and_derived_from_canonical_source",
                "form_contract": "textual_technique_specific_design",
                "authority_direction": "support_only",
                "lifecycle_owner": "declared_canonical_source_owner",
                "cycle_policy": "global_reference_dag",
                "depth_policy": "default_one_or_approved_exception",
                "validation_severity": "error_when_mechanical_warning_when_judgment",
            },
        }
        actual_target_kinds = {}
        for target_kind in self.collection(references.get("target_kinds")):
            target_id = str(target_kind.get("id", ""))
            actual_target_kinds[target_id] = {
                key: value for key, value in target_kind.items() if key != "id"
            }
        reference_rules = {
            str(rule.get("id")): str(rule.get("rule", ""))
            for rule in self.collection(references.get("rules"))
        }
        if (
            set(self.strings(references.get("relationships")))
            != {"implements", "satisfies", "tested-by", "constrained-by", "refines"}
            or actual_target_kinds != expected_target_kinds
            or set(reference_rules)
            != {
                "REF-TARGET-KIND",
                "REF-CANONICAL-PATH",
                "REF-SUPPORTING-PATH",
                "REF-AUTHORITY-DIRECTION",
                "REF-NO-CYCLE",
                "REF-DEPTH",
            }
            or "directed acyclic graph" not in reference_rules.get("REF-NO-CYCLE", "")
            or not isinstance(depth_policy, dict)
            or depth_policy.get("default_supporting_depth") != 1
            or depth_policy.get("greater_depth_requires_exception") is not True
            or depth_policy.get("supporting_to_supporting_reference_allowed_only_by_exception")
            is not True
            or set(self.strings(depth_policy.get("exception_required_fields")))
            != {"declared_by", "justification", "maximum_depth", "approved_by", "approved_on"}
        ):
            self.add(
                RULE_REFERENCE,
                "reference enforcement/depth contract is missing or weakened",
                needle="references",
            )
        self.check_enforcement_record(
            references.get("enforcement"),
            label="reference graph",
            work_package="WP-05",
            contract_field="required_rule_ids",
            expected_contract={
                "REF-TARGET-KIND",
                "REF-CANONICAL-PATH",
                "REF-SUPPORTING-PATH",
                "REF-AUTHORITY-DIRECTION",
                "REF-NO-CYCLE",
                "REF-DEPTH",
            },
        )

        document_sweep = self.data.get("document_sweep", {})
        required_active_roots = {
            "AGENTS.md",
            "README.md",
            "docs/methodology",
            "docs/project-template",
            "docs/resources/practitioner-guide",
            "scripts",
            ".github/workflows",
        }
        active_roots = set(self.strings(document_sweep.get("active_roots")))
        if active_roots != required_active_roots:
            self.add(
                RULE_REFERENCE,
                "document sweep active_roots must contain the exact current authority/tool roots",
                needle="active_roots",
            )
        for path in sorted(active_roots):
            if not self.is_safe_repository_path(path) or not (self.root / path).exists():
                self.add(
                    RULE_REFERENCE,
                    f"document sweep active root does not resolve safely: {path}",
                    needle=path,
                )
        sweep_enforcement = document_sweep.get("enforcement", {})
        active_sweep = (
            sweep_enforcement.get("active_prose_and_examples", {})
            if isinstance(sweep_enforcement, dict)
            else {}
        )
        historical_sweep = (
            sweep_enforcement.get("historical_links_and_release_metadata", {})
            if isinstance(sweep_enforcement, dict)
            else {}
        )
        if (
            not isinstance(sweep_enforcement, dict)
            or set(sweep_enforcement) != {
                "active_prose_and_examples",
                "historical_links_and_release_metadata",
            }
            or active_sweep.get("state") not in {"planned", "current"}
            or active_sweep.get("required_work_package") != "WP-09"
            or historical_sweep.get("state") not in {"planned", "current"}
            or historical_sweep.get("required_work_package") != "WP-11"
        ):
            self.add(
                RULE_DELIVERY,
                "document sweep enforcement ownership must remain explicit for WP-09 and WP-11",
                needle="enforcement",
            )
        self.check_enforcement_record(
            active_sweep,
            label="active documentation sweep",
            work_package="WP-09",
            contract_field="required_checks",
            expected_contract={
                "active_prose_coherence",
                "classified_design_decisions",
                "current_examples_non_authoritative",
            },
        )
        self.check_enforcement_record(
            historical_sweep,
            label="historical/release sweep",
            work_package="WP-11",
            contract_field="required_checks",
            expected_contract={
                "historical_links",
                "release_metadata",
                "version_synchronization",
            },
        )

    def check_event_serialization_contract(self) -> None:
        serialization = self.data.get("event_serialization", {})
        if not isinstance(serialization, dict):
            return
        correction_fields = ["supersedes_event_id", "correction_reason"]
        common_profiles = serialization.get("common_conditional_field_sets")
        if (
            serialization.get("schema_version") != 2
            or serialization.get("profile") != "restricted_yaml_v2"
            or serialization.get("default_scalar_value_contract") != "nonempty_string"
            or common_profiles != {"correction": correction_fields}
        ):
            self.add(
                RULE_EVENT,
                "event serialization must use restricted YAML v2 and the common correction profile",
                needle="event_serialization",
            )

        events = self.collection(self.data.get("events"))
        event_fields: set[str] = set(correction_fields)
        for event in events:
            event_fields.update(self.strings(event.get("required_fields")))
            conditional_sets = event.get("conditional_field_sets", {})
            if isinstance(conditional_sets, dict):
                for fields in conditional_sets.values():
                    event_fields.update(self.strings(fields))

        field_contracts = serialization.get("field_contracts", {})
        record_contracts = serialization.get("record_contracts", {})
        if not isinstance(field_contracts, dict) or set(field_contracts) != event_fields:
            self.add(
                RULE_EVENT,
                "event field-shape catalog must exactly cover every required, conditional, and correction field",
                needle="field_contracts",
            )
            field_contracts = field_contracts if isinstance(field_contracts, dict) else {}
        expected_record_ids = {
            "event_evidence_item",
            "event_reference_item",
            "coverage_result",
            "delegation",
            "enforcement_context",
            "historical_event_reference",
            "manifest_result",
            "next_state",
            "operational_owner_confirmation",
            "operational_results",
            "regression_result",
            "risk_disposition",
            "security_approval",
            "test_uat_execution",
            "command_result_item",
            "value_review",
            "value_review_details",
            "value_result_item",
            "reconciliation_artifact_item",
            "residual_finding_item",
            "migration_provenance_item",
            "enforcement_exception_item",
        }
        if not isinstance(record_contracts, dict) or set(record_contracts) != expected_record_ids:
            self.add(
                RULE_EVENT,
                "event record-contract catalog must contain the exact endorsed nested record types",
                needle="record_contracts",
            )
            record_contracts = record_contracts if isinstance(record_contracts, dict) else {}

        valid_shapes = {"scalar", "scalar_list", "record", "record_list"}
        record_shapes = {"record", "record_list"}
        for field, contract in field_contracts.items():
            if not isinstance(contract, dict):
                self.add(RULE_EVENT, f"event field {field} contract must be an object")
                continue
            shape = contract.get("shape")
            item_contract = contract.get("item_contract")
            is_record_shape = isinstance(shape, str) and shape in record_shapes
            expected_keys = {"shape", "item_contract"} if is_record_shape else {"shape"}
            if "min_items" in contract:
                expected_keys.add("min_items")
            if "value_contract" in contract:
                expected_keys.add("value_contract")
            min_items = contract.get("min_items")
            value_contract = contract.get("value_contract")
            if (
                not isinstance(shape, str)
                or shape not in valid_shapes
                or set(contract) != expected_keys
                or (
                    is_record_shape
                    and (
                        not isinstance(item_contract, str)
                        or item_contract not in record_contracts
                    )
                )
                or (
                    "min_items" in contract
                    and (
                        shape not in {"scalar_list", "record_list"}
                        or isinstance(min_items, bool)
                        or not isinstance(min_items, int)
                        or min_items < 1
                    )
                )
                or (
                    "value_contract" in contract
                    and (
                        shape != "scalar"
                        or not isinstance(value_contract, str)
                        or not value_contract
                    )
                )
            ):
                self.add(
                    RULE_EVENT,
                    f"event field {field} has an invalid shape or nested item contract",
                    needle=field,
                )

        allowed_record_keys = {
            "required_fields",
            "conditional_field_sets",
            "default_field_shape",
            "field_shape_overrides",
            "field_item_contracts",
            "conditional_profile_selector",
            "conditional_profile_value_map",
            "field_min_items",
            "field_value_contracts",
        }
        for record_id, contract in record_contracts.items():
            if not isinstance(contract, dict):
                self.add(RULE_EVENT, f"event record {record_id} contract must be an object")
                continue
            required = self.strings(contract.get("required_fields"))
            conditional = contract.get("conditional_field_sets", {})
            overrides = contract.get("field_shape_overrides", {})
            item_contracts = contract.get("field_item_contracts", {})
            profile_selector = contract.get("conditional_profile_selector")
            profile_value_map = contract.get("conditional_profile_value_map", {})
            field_min_items = contract.get("field_min_items", {})
            field_value_contracts = contract.get("field_value_contracts", {})
            all_fields = set(required)
            valid = (
                set(contract) <= allowed_record_keys
                and isinstance(contract.get("required_fields"), list)
                and len(required) == len(contract.get("required_fields", [])) == len(set(required))
                and isinstance(contract.get("default_field_shape"), str)
                and contract.get("default_field_shape") in valid_shapes
                and isinstance(conditional, dict)
                and isinstance(overrides, dict)
                and isinstance(item_contracts, dict)
                and isinstance(profile_value_map, dict)
                and isinstance(field_min_items, dict)
                and isinstance(field_value_contracts, dict)
            )
            if isinstance(conditional, dict):
                for fields in conditional.values():
                    normalized = self.strings(fields)
                    valid = valid and isinstance(fields, list) and len(normalized) == len(
                        fields
                    ) == len(set(normalized))
                    all_fields.update(normalized)
                if conditional:
                    valid = valid and isinstance(profile_selector, str) and bool(
                        profile_selector
                    )
                elif profile_selector is not None:
                    valid = False
            if isinstance(profile_value_map, dict):
                valid = valid and all(
                    isinstance(profile, str) and profile in conditional
                    for profile in profile_value_map.values()
                )
            if isinstance(overrides, dict):
                valid = valid and set(overrides) <= all_fields and all(
                    isinstance(shape, str) and shape in valid_shapes
                    for shape in overrides.values()
                )
            if isinstance(item_contracts, dict):
                valid = valid and set(item_contracts) <= all_fields and all(
                    isinstance(item, str) and item in record_contracts
                    for item in item_contracts.values()
                )
                for field in item_contracts:
                    override = overrides.get(field)
                    valid = (
                        valid
                        and isinstance(override, str)
                        and override in record_shapes
                    )
            for field, shape in overrides.items() if isinstance(overrides, dict) else ():
                if isinstance(shape, str) and shape in record_shapes:
                    valid = valid and field in item_contracts
            if isinstance(field_min_items, dict):
                valid = valid and set(field_min_items) <= all_fields
                for field, minimum in field_min_items.items():
                    shape = overrides.get(field, contract.get("default_field_shape"))
                    valid = (
                        valid
                        and shape in {"scalar_list", "record_list"}
                        and not isinstance(minimum, bool)
                        and isinstance(minimum, int)
                        and minimum >= 1
                    )
            if isinstance(field_value_contracts, dict):
                valid = valid and set(field_value_contracts) <= all_fields and all(
                    isinstance(value_contract, str) and bool(value_contract)
                    for value_contract in field_value_contracts.values()
                )
            if not valid:
                self.add(
                    RULE_EVENT,
                    f"event record {record_id} has invalid fields, shapes, or nested contract references",
                    needle=record_id,
                )

        evidence_record = record_contracts.get("event_evidence_item", {})
        reference_record = record_contracts.get("event_reference_item", {})
        evidence_source = self.data.get("event_evidence_item", {})
        reference_source = self.data.get("event_reference_item", {})
        if (
            evidence_record.get("required_fields") != evidence_source.get("required_fields")
            or evidence_record.get("conditional_field_sets")
            != evidence_source.get("conditional_fields")
            or reference_record.get("required_fields") != reference_source.get("required_fields")
        ):
            self.add(
                RULE_EVENT,
                "serialized evidence/reference item contracts must match their authoritative sources",
                needle="event_evidence_item",
            )

        dispositions = {
            str(item.get("id", "")): item.get("required_fields")
            for item in self.collection(
                self.data.get("value_review_contract", {}).get("dispositions")
            )
        }
        value_record = record_contracts.get("value_review", {})
        value_details = record_contracts.get("value_review_details", {})
        value_result = record_contracts.get("value_result_item", {})
        complete_disposition = next(
            (
                item
                for item in self.collection(
                    self.data.get("value_review_contract", {}).get("dispositions")
                )
                if item.get("id") == "complete"
            ),
            {},
        )
        deployment_value = self.data.get("deployment", {}).get(
            "value_prerequisite_contract", {}
        )
        if (
            value_record.get("required_fields") != ["disposition", "details"]
            or value_record.get("field_shape_overrides") != {"details": "record"}
            or value_record.get("field_item_contracts")
            != {"details": "value_review_details"}
            or value_details.get("conditional_field_sets") != dispositions
            or value_details.get("field_shape_overrides")
            != {"criterion_results": "record_list"}
            or value_details.get("field_item_contracts")
            != {"criterion_results": "value_result_item"}
            or value_details.get("field_min_items") != {"criterion_results": 1}
            or deployment_value.get("required_fields") != value_record.get("required_fields")
            or complete_disposition.get("item_contract") != "value_result_item"
            or value_result.get("required_fields")
            != ["criterion_id", "evidence", "result"]
            or value_result.get("conditional_field_sets")
            != {
                result: ["follow_up_decision"]
                for result in self.strings(
                    complete_disposition.get("follow_up_required_for")
                )
            }
            or value_result.get("conditional_profile_selector") != "result"
            or value_result.get("field_shape_overrides")
            != {"evidence": "scalar_list"}
            or value_result.get("field_min_items") != {"evidence": 1}
        ):
            self.add(
                RULE_EVENT,
                "serialized value-review records must match disposition and deployment prerequisites",
                needle="value_review_details",
            )

        test_execution = record_contracts.get("test_uat_execution", {})
        command_result = record_contracts.get("command_result_item", {})
        if (
            test_execution.get("required_fields")
            != ["candidate_revision", "command_results", "evidence_event_ids"]
            or test_execution.get("field_shape_overrides")
            != {"command_results": "record_list", "evidence_event_ids": "scalar_list"}
            or test_execution.get("field_item_contracts")
            != {"command_results": "command_result_item"}
            or test_execution.get("field_min_items")
            != {"command_results": 1, "evidence_event_ids": 1}
            or command_result
            != {
                "required_fields": ["command", "result"],
                "default_field_shape": "scalar",
            }
        ):
            self.add(
                RULE_EVENT,
                "serialized test execution must use keyed nonempty command-result records",
                needle="test_uat_execution",
            )

        migration = next(
            (event for event in events if event.get("id") == "migration_reconciliation"),
            {},
        )
        historical_record = record_contracts.get("historical_event_reference", {})
        historical_source = migration.get("historical_event_reference_contract", {})
        migration_profiles = migration.get("conditional_field_sets", {})
        if (
            historical_record.get("required_fields") != ["kind"]
            or historical_record.get("conditional_field_sets")
            != historical_source.get("required_fields_by_kind")
            or set(historical_record.get("conditional_field_sets", {}))
            != set(self.strings(historical_source.get("allowed_kinds")))
            or not isinstance(migration_profiles, dict)
            or migration_profiles.get("duplicate_mapping") != correction_fields
            or {
                key: field_contracts.get("historical_event_reference", {}).get(key)
                for key in ("shape", "item_contract")
            }
            != {"shape": "record", "item_contract": "historical_event_reference"}
            or {
                key: field_contracts.get("provenance", {}).get(key)
                for key in ("shape", "item_contract")
            }
            != {"shape": "record_list", "item_contract": "migration_provenance_item"}
        ):
            self.add(
                RULE_EVENT,
                "serialized migration references, provenance, and correction fields must match migration authority",
                needle="migration_reconciliation",
            )

        expected_source_bindings = {
            "evidence": ("record_list", "event_evidence_item"),
            "references": ("record_list", "event_reference_item"),
            "value_disposition": ("record", "value_review"),
            "value_prerequisites": ("record", "value_review"),
        }
        for field, (shape, item_contract) in expected_source_bindings.items():
            actual_binding = {
                key: field_contracts.get(field, {}).get(key)
                for key in ("shape", "item_contract")
            }
            if actual_binding != {
                "shape": shape,
                "item_contract": item_contract,
            }:
                self.add(
                    RULE_EVENT,
                    f"serialized {field} field must bind {item_contract}",
                    needle=field,
                )

        coverage_fields = set(
            self.strings(self.data.get("scaling", {}).get("coverage_policy", {}).get("required_fields"))
        ) | {"policy_reference", "actual", "result"}
        delegation_fields = self.data.get("approval_policy", {}).get("phase_exit", {}).get(
            "c1_c2_delegation_required_fields"
        )
        if (
            set(self.strings(record_contracts.get("coverage_result", {}).get("required_fields")))
            != coverage_fields
            or record_contracts.get("delegation", {}).get("required_fields")
            != delegation_fields
        ):
            self.add(
                RULE_EVENT,
                "serialized coverage and delegation records must match their policy sources",
                needle="record_contracts",
            )

        serialized = json.dumps(
            serialization, sort_keys=True, separators=(",", ":"), ensure_ascii=True
        )
        digest = hashlib.sha256((serialized + "\n").encode("utf-8")).hexdigest()
        # The checks above explain local drift; this endorsed digest also catches
        # coordinated shape/source edits that remain internally self-consistent.
        if digest != "cdc1040ea0ddb45c2ffd5730d2159f46bc72f2c881df207a691db00868d6198d":
            self.add(
                RULE_EVENT,
                "exact endorsed event serialization field/record catalog drifted",
                needle="event_serialization",
            )

    @staticmethod
    def is_safe_repository_path(path: str) -> bool:
        candidate = Path(path)
        return bool(path) and not candidate.is_absolute() and ".." not in candidate.parts

    def check_enforcement_record(
        self,
        record: Any,
        *,
        label: str,
        work_package: str,
        contract_field: str,
        expected_contract: set[str],
    ) -> None:
        if not isinstance(record, dict):
            self.add(RULE_DELIVERY, f"{label} enforcement record is missing")
            return
        state = record.get("state")
        enforcer = record.get("enforcer_path")
        suite = record.get("verification_suite")
        contract = set(self.strings(record.get(contract_field)))
        if (
            state not in {"planned", "current"}
            or record.get("required_work_package") != work_package
            or not isinstance(enforcer, str)
            or not self.is_safe_repository_path(enforcer)
            or not isinstance(suite, str)
            or not self.is_safe_repository_path(suite)
            or contract != expected_contract
        ):
            self.add(
                RULE_DELIVERY,
                f"{label} enforcement ownership/contract is incomplete",
                needle=label,
            )
            return
        if state == "current" and (
            not (self.root / enforcer).is_file() or not (self.root / suite).is_file()
        ):
            self.add(
                RULE_DELIVERY,
                f"{label} claims current enforcement without delivered enforcer and suite",
                needle=label,
            )

    def check_cross_references(self) -> None:
        gates = {str(item.get("id")) for item in self.collection(self.data.get("gates"))}
        checkpoints = {
            str(item.get("id")) for item in self.collection(self.data.get("checkpoints"))
        }
        roles = {str(item.get("id")) for item in self.collection(self.data.get("roles"))}
        artifacts = {str(item.get("id")) for item in self.collection(self.data.get("artifacts"))}
        events = {str(item.get("id")) for item in self.collection(self.data.get("events"))}
        criteria = {
            str(item.get("id")): item for item in self.collection(self.data.get("criteria"))
        }

        for gate in self.collection(self.data.get("gates")):
            gate_id = str(gate.get("id"))
            role = gate.get("active_role")
            artifact = gate.get("primary_artifact")
            if role not in roles:
                self.add(
                    RULE_REFERENCE,
                    f"gate {gate_id} references unknown active role {role!r}",
                    needle=gate_id,
                )
            if artifact not in artifacts:
                self.add(
                    RULE_REFERENCE,
                    f"gate {gate_id} references unknown primary artifact {artifact!r}",
                    needle=gate_id,
                )
            for criterion in self.strings(gate.get("criterion_ids")):
                entry = criteria.get(criterion)
                if entry is None:
                    self.add(
                        RULE_REFERENCE,
                        f"gate {gate_id} references unknown criterion {criterion}",
                        needle=criterion,
                    )
                elif entry.get("gate") != gate_id:
                    self.add(
                        RULE_GATE_BINDING,
                        f"criterion {criterion} is bound to {entry.get('gate')!r}, not {gate_id}",
                        needle=criterion,
                    )

        for transition in self.collection(self.data.get("transitions")):
            identifier = str(transition.get("id"))
            source = str(transition.get("from"))
            target = str(transition.get("to"))
            event = transition.get("event_type")
            if event not in events:
                self.add(
                    RULE_REFERENCE,
                    f"transition {identifier} references unknown event type {event!r}",
                    needle=identifier,
                )
            role = transition.get("resulting_role")
            if role not in roles:
                self.add(
                    RULE_REFERENCE,
                    f"transition {identifier} references unknown resulting role {role!r}",
                    needle=identifier,
                )
            for artifact in self.strings(transition.get("required_artifacts")):
                if artifact not in artifacts:
                    self.add(
                        RULE_REFERENCE,
                        f"transition {identifier} references unknown artifact {artifact}",
                        needle=identifier,
                    )
            for criterion in self.strings(transition.get("criterion_ids")):
                entry = criteria.get(criterion)
                if entry is None:
                    self.add(
                        RULE_REFERENCE,
                        f"transition {identifier} references unknown criterion {criterion}",
                        needle=identifier,
                    )
                elif entry.get("gate") not in {source, target}:
                    self.add(
                        RULE_GATE_BINDING,
                        f"transition {identifier} criterion {criterion} is bound outside {source}/{target}",
                        needle=identifier,
                    )

        for checkpoint in self.collection(self.data.get("checkpoints")):
            identifier = str(checkpoint.get("id"))
            if checkpoint.get("active_major_gate") != "G5":
                self.add(
                    RULE_CHECKPOINT,
                    f"checkpoint {identifier} must retain active major gate G5",
                    needle=identifier,
                )
            if checkpoint.get("resulting_role") not in roles:
                self.add(
                    RULE_REFERENCE,
                    f"checkpoint {identifier} references an unknown resulting role",
                    needle=identifier,
                )
            if checkpoint.get("event_type") not in events:
                self.add(
                    RULE_REFERENCE,
                    f"checkpoint {identifier} references an unknown event type",
                    needle=identifier,
                )
            for artifact in self.strings(checkpoint.get("required_artifacts")):
                if artifact not in artifacts:
                    self.add(
                        RULE_REFERENCE,
                        f"checkpoint {identifier} references unknown artifact {artifact}",
                        needle=identifier,
                    )
            for criterion in self.strings(checkpoint.get("criterion_ids")):
                entry = criteria.get(criterion)
                if entry is None:
                    self.add(
                        RULE_REFERENCE,
                        f"checkpoint {identifier} references unknown criterion {criterion}",
                        needle=identifier,
                    )
                elif entry.get("gate") != "G5":
                    self.add(
                        RULE_GATE_BINDING,
                        f"checkpoint {identifier} criterion {criterion} is not bound to G5",
                        needle=identifier,
                    )

        allowed_bindings = gates | checkpoints
        for artifact in self.collection(self.data.get("artifacts")):
            identifier = str(artifact.get("id"))
            owner = artifact.get("owner_role")
            if owner not in roles:
                self.add(
                    RULE_REFERENCE,
                    f"artifact {identifier} references unknown owner role {owner!r}",
                    needle=identifier,
                )
            for binding in self.strings(artifact.get("lifecycle_bindings")):
                if binding not in allowed_bindings:
                    self.add(
                        RULE_REFERENCE,
                        f"artifact {identifier} references unknown lifecycle binding {binding}",
                        needle=identifier,
                    )

        referenced_criteria: set[str] = set()
        for record in (
            self.collection(self.data.get("gates"))
            + self.collection(self.data.get("transitions"))
            + self.collection(self.data.get("checkpoints"))
        ):
            referenced_criteria.update(self.strings(record.get("criterion_ids")))
        if referenced_criteria != set(criteria):
            missing = sorted(set(criteria) - referenced_criteria)
            extra = sorted(referenced_criteria - set(criteria))
            self.add(
                RULE_REFERENCE,
                f"criterion catalog/reference coverage mismatch; unreferenced={missing}, unknown={extra}",
                needle="criteria",
            )

    def check_artifact_requirement_contract(
        self,
        record: dict[str, Any],
        label: str,
        rule_id: str,
        *,
        require_coverage: bool = True,
    ) -> None:
        artifacts = {
            str(artifact.get("id")): artifact
            for artifact in self.collection(self.data.get("artifacts"))
        }
        categories = {
            str(category.get("id")): category
            for category in self.collection(self.data.get("evidence_categories"))
        }
        vocabularies = self.data.get("vocabularies", {})
        artifact_statuses = set(self.strings(vocabularies.get("artifact_statuses")))
        valid_dispositions = set(
            self.strings(vocabularies.get("remediation_dispositions"))
            + self.strings(vocabularies.get("value_review_dispositions"))
        )
        required_artifacts = set(self.strings(record.get("required_artifacts")))
        artifact_requirements = record.get("artifact_requirements") or []
        reference_requirements = record.get("reference_requirements") or []
        if not isinstance(artifact_requirements, list) or not all(
            isinstance(requirement, dict) for requirement in artifact_requirements
        ):
            self.add(rule_id, f"{label} artifact_requirements must be an array of objects")
            artifact_requirements = []
        if not isinstance(reference_requirements, list) or not all(
            isinstance(requirement, dict) for requirement in reference_requirements
        ):
            self.add(rule_id, f"{label} reference_requirements must be an array of objects")
            reference_requirements = []

        artifact_requirement_ids = [
            str(requirement.get("artifact_id", "")) for requirement in artifact_requirements
        ]
        reference_requirement_ids = [
            str(requirement.get("artifact_id", "")) for requirement in reference_requirements
        ]
        covered_ids = set(artifact_requirement_ids + reference_requirement_ids)
        policy = record.get("artifact_requirement_policy")
        if policy is not None:
            if not (
                label == "G0-to-G1"
                and record.get("event_type") == "project_initialization"
                and policy == "project_initialization_result"
                and required_artifacts == {"project_manifest", "gate_log"}
                and not covered_ids
            ):
                self.add(
                    rule_id,
                    f"{label} has an invalid project-initialization artifact policy",
                    needle=label,
                )
        elif require_coverage and covered_ids != required_artifacts:
            self.add(
                rule_id,
                f"{label} artifact/reference requirements do not exactly cover required_artifacts",
                needle=label,
            )
        if len(artifact_requirement_ids + reference_requirement_ids) != len(covered_ids):
            self.add(rule_id, f"{label} contains duplicate artifact/reference requirements")

        for requirement in artifact_requirements:
            artifact_id = requirement.get("artifact_id")
            artifact = artifacts.get(str(artifact_id))
            reviewed = set(self.strings(requirement.get("reviewed_statuses")))
            resulting = set(self.strings(requirement.get("resulting_statuses")))
            category_ids = set(self.strings(requirement.get("evidence_categories")))
            if artifact is None or (require_coverage and artifact_id not in required_artifacts):
                self.add(rule_id, f"{label} artifact requirement references {artifact_id!r} incorrectly")
                continue
            allowed = set(self.strings(artifact.get("allowed_statuses")))
            if (
                not reviewed
                or not resulting
                or not reviewed <= artifact_statuses & allowed
                or not resulting <= artifact_statuses & allowed
                or not category_ids
                or not category_ids <= set(categories)
            ):
                self.add(
                    rule_id,
                    f"{label} artifact requirement for {artifact_id} has invalid status/category vocabulary",
                    needle=str(artifact_id),
                )
            for category_id in category_ids:
                category = categories.get(category_id, {})
                if category.get("reviewed_status") not in reviewed or category.get(
                    "resulting_status"
                ) not in resulting:
                    self.add(
                        rule_id,
                        f"{label} artifact requirement for {artifact_id} conflicts with {category_id}",
                        needle=str(artifact_id),
                    )
            dispositions = requirement.get("required_dispositions")
            if dispositions is not None and (
                not isinstance(dispositions, list)
                or not dispositions
                or not set(self.strings(dispositions)) <= valid_dispositions
            ):
                self.add(rule_id, f"{label} artifact requirement has invalid dispositions")

        reference_base_fields = {"artifact_path", "status", "revision", "blob_oid", "digest"}
        for requirement in reference_requirements:
            artifact_id = requirement.get("artifact_id")
            artifact = artifacts.get(str(artifact_id))
            allowed_statuses = set(self.strings(requirement.get("allowed_statuses")))
            required_fields = set(self.strings(requirement.get("required_fields")))
            binding_mode = requirement.get("binding_mode")
            if artifact is None or (require_coverage and artifact_id not in required_artifacts):
                self.add(rule_id, f"{label} reference requirement references {artifact_id!r} incorrectly")
                continue
            if (
                not allowed_statuses
                or not allowed_statuses <= set(self.strings(artifact.get("allowed_statuses")))
                or not reference_base_fields <= required_fields
                or binding_mode
                not in {"pinned_checkpoint_reference", "pinned_subordinate_reference"}
            ):
                self.add(
                    rule_id,
                    f"{label} reference requirement for {artifact_id} is incomplete",
                    needle=str(artifact_id),
                )
            parent = requirement.get("parent_artifact_id")
            if binding_mode == "pinned_subordinate_reference" and (
                parent not in required_artifacts or parent not in artifacts
            ):
                self.add(
                    rule_id,
                    f"{label} subordinate reference {artifact_id} has no required parent artifact",
                    needle=str(artifact_id),
                )
            dispositions = requirement.get("required_dispositions")
            if dispositions is not None and (
                not isinstance(dispositions, list)
                or not dispositions
                or not set(self.strings(dispositions)) <= valid_dispositions
            ):
                self.add(rule_id, f"{label} reference requirement has invalid dispositions")

    def check_transitions(self) -> None:
        gates = self.collection(self.data.get("gates"))
        gate_ids = [str(gate.get("id", "")) for gate in gates]
        expected = [f"G{number}" for number in range(10)]
        if gate_ids != expected:
            self.add(
                RULE_TRANSITION,
                f"gate order must be {' -> '.join(expected)}; found {' -> '.join(gate_ids)}",
                needle="gates",
            )

        gate_set = set(gate_ids)
        edges: list[tuple[str, str]] = []
        transitions = self.collection(self.data.get("transitions"))
        for transition in transitions:
            source = self.first(transition, "from", "from_gate", "source")
            target = self.first(transition, "to", "to_gate", "target")
            if not isinstance(source, str) or not isinstance(target, str):
                self.add(RULE_TRANSITION, "transition must declare string from/to gates")
                continue
            if source not in gate_set or target not in gate_set:
                self.add(
                    RULE_TRANSITION,
                    f"transition {source} -> {target} references an unknown gate",
                    needle=str(self.first(transition, "id") or source),
                )
                continue
            if source == target:
                self.add(
                    RULE_TRANSITION,
                    f"transition {source} -> {target} is a cycle",
                    needle=str(self.first(transition, "id") or source),
                )
            edges.append((source, target))
            self.check_artifact_requirement_contract(
                transition,
                str(transition.get("id", f"{source}-to-{target}")),
                RULE_ARTIFACT,
            )

        expected_edges = [(f"G{number}", f"G{number + 1}") for number in range(9)]
        if len(transitions) != len(expected_edges):
            self.add(
                RULE_TRANSITION,
                f"transition registry must contain exactly 9 edges; found {len(transitions)}",
            )
        duplicate_edges = sorted({edge for edge in edges if edges.count(edge) > 1})
        if duplicate_edges:
            self.add(
                RULE_TRANSITION,
                "duplicate transition edges are forbidden: "
                + ", ".join(f"{source}->{target}" for source, target in duplicate_edges),
            )
        if edges != expected_edges:
            self.add(
                RULE_TRANSITION,
                "transition edges must be exactly the ordered adjacent G0->G1 through G8->G9 chain",
            )

        graph: dict[str, list[str]] = {gate: [] for gate in gate_set}
        for source, target in edges:
            graph.setdefault(source, []).append(target)
        visiting: set[str] = set()
        visited: set[str] = set()

        def visit(node: str) -> bool:
            if node in visiting:
                return True
            if node in visited:
                return False
            visiting.add(node)
            if any(visit(target) for target in graph.get(node, [])):
                return True
            visiting.remove(node)
            visited.add(node)
            return False

        if any(visit(gate) for gate in gate_ids if gate not in visited):
            self.add(RULE_TRANSITION, "major transition graph contains a cycle")

        for index, gate in enumerate(gates):
            gate_id = gate_ids[index]
            expected_predecessor = gate_ids[index - 1] if index else None
            expected_successor = gate_ids[index + 1] if index + 1 < len(gate_ids) else None
            if gate.get("predecessor") != expected_predecessor:
                self.add(
                    RULE_TRANSITION,
                    f"{gate_id} predecessor must be {expected_predecessor!r}",
                    needle=f'"{gate_id}"',
                )
            if gate.get("successor") != expected_successor:
                self.add(
                    RULE_TRANSITION,
                    f"{gate_id} successor must be {expected_successor!r}",
                    needle=f'"{gate_id}"',
                )

    def check_checkpoints(self) -> None:
        checkpoints = self.collection(self.data.get("checkpoints"))
        ids = [str(item.get("id", "")) for item in checkpoints]
        expected_ids = ["G5.0"] + [f"G5.<id>.{number}" for number in range(1, 5)]
        if ids != expected_ids:
            self.add(
                RULE_CHECKPOINT,
                f"checkpoint IDs must be exactly {', '.join(expected_ids)} in order",
            )
        for index, item in enumerate(checkpoints):
            identifier = str(item.get("id", ""))
            if item.get("order") != index:
                self.add(
                    RULE_CHECKPOINT,
                    f"{identifier} order must be {index}",
                    needle=identifier,
                )
            nullable_fields = item.get("nullable_event_fields", [])
            expected_nullable_fields = ["phase_id"] if index == 0 else []
            if nullable_fields != expected_nullable_fields:
                self.add(
                    RULE_CHECKPOINT,
                    f"{identifier} nullable_event_fields must be {expected_nullable_fields}",
                    needle=identifier,
                )
            pattern = item.get("position_pattern")
            try:
                compiled_position = re.compile(pattern) if isinstance(pattern, str) else None
            except re.error as exc:
                self.add(
                    RULE_CHECKPOINT,
                    f"{identifier} position_pattern is invalid: {exc}",
                    needle=identifier,
                )
                compiled_position = None
            if compiled_position is None:
                self.add(
                    RULE_CHECKPOINT,
                    f"{identifier} must declare a valid position_pattern",
                    needle=identifier,
                )
            else:
                valid_position = "G5.0" if index == 0 else f"G5.10-5.{index}"
                invalid_positions = (
                    "G5.00",
                    "G5.1",
                    "G5.bad_phase.1",
                    f"G5.10-5.{(index + 1) % 5}",
                )
                if not compiled_position.fullmatch(valid_position) or any(
                    compiled_position.fullmatch(position) for position in invalid_positions
                ):
                    self.add(
                        RULE_CHECKPOINT,
                        f"{identifier} position_pattern accepts the wrong checkpoint language",
                        needle=identifier,
                    )
            event_type = self.first(item, "event_type", "event")
            rule_id = RULE_PHASE_EXIT if identifier == "G5.<id>.4" else RULE_CHECKPOINT
            expected_event = "phase_transition" if identifier.endswith(".4") else "phase_checkpoint"
            if event_type != expected_event:
                self.add(
                    RULE_CHECKPOINT,
                    f"{identifier} must bind event type {expected_event}, not {event_type!r}",
                    needle=identifier,
                )
            self.check_artifact_requirement_contract(item, identifier, rule_id)
            approval = item.get("approval")
            if identifier in set(expected_ids) and (
                not isinstance(approval, str) or "named_human" not in approval
            ):
                self.add(
                    RULE_APPROVAL,
                    f"{identifier} must require named-human approval",
                    needle=identifier,
                )
            required_evidence = item.get("required_evidence")
            if not isinstance(required_evidence, list):
                self.add(
                    rule_id,
                    f"{identifier} required_evidence must be an array",
                    needle=identifier,
                )
                continue

            required_artifacts = set(self.strings(item.get("required_artifacts")))
            known_artifacts = {
                str(artifact.get("id"))
                for artifact in self.collection(self.data.get("artifacts"))
            }
            event_records = {
                str(event.get("id")): event
                for event in self.collection(self.data.get("events"))
            }
            event_record = event_records.get(str(event_type), {})
            allowed_event_fields = set(self.strings(event_record.get("required_fields")))
            reference_requirements = {
                str(requirement.get("artifact_id")): requirement
                for requirement in self.collection(item.get("reference_requirements"))
            }
            seen_classes: set[str] = set()

            for index, evidence in enumerate(required_evidence):
                location = f"{identifier}.required_evidence[{index}]"
                if not isinstance(evidence, dict):
                    self.add(rule_id, f"{location} must be an object", needle=identifier)
                    continue
                evidence_class = evidence.get("class")
                artifact_ids = evidence.get("artifact_ids")
                event_fields = evidence.get("event_fields")
                if not isinstance(evidence_class, str) or not evidence_class.strip():
                    self.add(rule_id, f"{location}.class must be non-empty", needle=identifier)
                    normalized_class = ""
                else:
                    normalized_class = evidence_class.strip()
                    if normalized_class in seen_classes:
                        self.add(
                            rule_id,
                            f"{identifier} has duplicate required evidence class {normalized_class}",
                            needle=identifier,
                        )
                    seen_classes.add(normalized_class)

                artifact_list_valid = isinstance(artifact_ids, list) and all(
                    isinstance(value, str) and bool(value) for value in artifact_ids
                )
                event_fields_valid = isinstance(event_fields, list) and all(
                    isinstance(value, str) and bool(value) for value in event_fields
                )
                if not artifact_list_valid:
                    self.add(
                        rule_id,
                        f"{location}.artifact_ids must be an array of non-empty strings",
                        needle=identifier,
                    )
                if not event_fields_valid:
                    self.add(
                        rule_id,
                        f"{location}.event_fields must be an array of non-empty strings",
                        needle=identifier,
                    )
                if not artifact_list_valid or not event_fields_valid:
                    continue
                binding_mode = evidence.get("binding_mode")
                referenced_ids = evidence.get("referenced_artifact_ids", [])
                referenced_ids_valid = isinstance(referenced_ids, list) and all(
                    isinstance(value, str) and bool(value) for value in referenced_ids
                )
                if not referenced_ids_valid:
                    self.add(
                        rule_id,
                        f"{location}.referenced_artifact_ids must be an array of non-empty strings",
                        needle=identifier,
                    )
                    referenced_ids = []
                if binding_mode is None and referenced_ids:
                    self.add(
                        rule_id,
                        f"{location} references artifacts without a binding_mode",
                        needle=identifier,
                    )
                elif binding_mode is not None:
                    if binding_mode not in {
                        "pinned_checkpoint_reference",
                        "pinned_subordinate_reference",
                    } or not referenced_ids:
                        self.add(
                            rule_id,
                            f"{location} has an incomplete pinned-reference binding",
                            needle=identifier,
                        )
                    for referenced_id in referenced_ids:
                        requirement = reference_requirements.get(referenced_id)
                        if requirement is None or requirement.get("binding_mode") != binding_mode:
                            self.add(
                                rule_id,
                                f"{location} referenced artifact {referenced_id} lacks a matching reference requirement",
                                needle=identifier,
                            )
                        elif binding_mode == "pinned_subordinate_reference" and requirement.get(
                            "parent_artifact_id"
                        ) not in artifact_ids:
                            self.add(
                                rule_id,
                                f"{location} does not bind the subordinate reference through its parent artifact",
                                needle=identifier,
                            )
                if not artifact_ids and not event_fields:
                    self.add(
                        rule_id,
                        f"{location} must bind at least one artifact or event field",
                        needle=identifier,
                    )
                for artifact_id in artifact_ids:
                    if artifact_id not in known_artifacts:
                        self.add(
                            rule_id,
                            f"{location} references unknown artifact {artifact_id}",
                            needle=identifier,
                        )
                    elif artifact_id not in required_artifacts:
                        self.add(
                            rule_id,
                            f"{location} artifact {artifact_id} is not in checkpoint required_artifacts",
                            needle=identifier,
                        )
                for event_field in event_fields:
                    if event_field not in allowed_event_fields:
                        self.add(
                            rule_id,
                            f"{location} field {event_field} is not required by event {event_type}",
                            needle=identifier,
                        )

    def check_endorsed_catalog_contracts(self) -> None:
        """Lock endorsed semantic catalogs against coordinated internal drift."""
        expected_gates = {
            "G0": (
                "Project Initialized",
                "product-vision-agent",
                "project_manifest",
                "conditional_overwrite_only",
                {"G0-MANIFEST", "G0-SCAFFOLD", "G0-IDENTITY"},
                False,
            ),
            "G1": (
                "Vision Ready",
                "product-vision-agent",
                "vision",
                "required",
                {"G1-PROBLEM", "G1-USERS", "G1-SUCCESS", "G1-NON-GOALS", "G1-RISKS-QUESTIONS"},
                False,
            ),
            "G2": (
                "Requirements Ready",
                "prd-agent",
                "prd",
                "required",
                {"G2-REQ-ID", "G2-AC-COVERAGE", "G2-EARS-FORM", "G2-OBSERVABLE-FORM", "G2-UNWANTED-BEHAVIOR", "G2-TESTABILITY"},
                False,
            ),
            "G3": (
                "Architecture Ready",
                "architecture-agent",
                "architecture",
                "required",
                {"G3-ARCH-TRACE", "G3-BOUNDARIES", "G3-STATE-LIFECYCLE", "G3-STACK-ACCEPTED", "G3-VERIFICATION-SPEC", "G3-VERIFICATION-TRACE", "G3-DESIGN-INTERROGATION"},
                False,
            ),
            "G4": (
                "Governance Ready",
                "security-governance-agent",
                "governance_security",
                "required",
                {"G4-ACTOR-MODEL", "G4-AUTHORIZATION", "G4-AUDIT", "G4-SECRETS-DATA", "G4-TRUST-TOOLS", "G4-NEGATIVE-TESTS"},
                False,
            ),
            "G5": (
                "Build Ready",
                "phase-planning-agent",
                "phase_plan",
                "each_authority_acceptance_checkpoint_and_phase_exit",
                {"G5-PHASE-ORDER", "G5-REQ-COVERAGE", "G5-INTEGRATION", "G5-PARTITION", "G5-COVERAGE-POLICY"},
                False,
            ),
            "G6": (
                "Implementation Ready For Review",
                "implementation-agent",
                "implementation_summary",
                "conditional_skipped_critical_verification_or_nonwaivable_residual",
                {"G6-IMPLEMENTATION-SUMMARY", "G6-CANDIDATE-REVISION", "G6-CHANGED-FILES", "G6-INTEGRATION-REGRESSION", "G6-DEVIATIONS-RESIDUALS", "G6-REVIEW-PACKAGE"},
                False,
            ),
            "G7": (
                "Acceptance Ready",
                "code-review-agent",
                "final_code_review",
                "required_implementation_acceptance",
                {"G7-INDEPENDENT-REVIEW", "G7-REMEDIATION", "G7-FINAL-UAT", "G7-TRACEABILITY", "G7-RESIDUAL-RISK", "G7-UPSTREAM-BINDINGS"},
                False,
            ),
            "G8": (
                "Deployment Ready",
                "deployment-readiness-agent",
                "deployment_readiness",
                "required_deployment_and_closeout",
                {"G8-READINESS", "G8-RUNBOOK", "G8-RELEASE-SCOPE", "G8-CONFIG-SECRETS", "G8-MIGRATION-ROLLBACK", "G8-MONITORING-OWNERSHIP", "G8-VALUE-PREREQUISITES", "G8-DEPLOYMENT-APPROVAL"},
                False,
            ),
            "G9": (
                "As-Built Closed",
                "none",
                "project_as_built",
                "required_project_closeout",
                {"G9-DEPLOYMENT-DISPOSITION", "G9-OPERATIONS-RESULTS", "G9-VALUE-DISPOSITION", "G9-FINAL-TRACEABILITY", "G9-AS-BUILT-CLOSEOUT"},
                True,
            ),
        }
        for gate in self.collection(self.data.get("gates")):
            gate_id = str(gate.get("id", ""))
            expected = expected_gates.get(gate_id)
            actual = (
                gate.get("name"),
                gate.get("active_role"),
                gate.get("primary_artifact"),
                gate.get("human_approval"),
                set(self.strings(gate.get("criterion_ids"))),
                gate.get("terminal"),
            )
            if expected is not None and actual != expected:
                self.add(
                    RULE_GATE_BINDING,
                    f"{gate_id} semantic role/artifact/approval/criterion contract drifted",
                    needle=gate_id,
                )

        expected_checkpoints = {
            "G5.0": (
                "phase_checkpoint", "named_human",
                {"phase_plan", "traceability"}, {"phase_plan", "traceability"}, set(),
                {"phase_partition", "requirement_coverage", "integration_criteria", "coverage_policy"},
                {"G5-PHASE-ORDER", "G5-REQ-COVERAGE", "G5-INTEGRATION", "G5-PARTITION", "G5-COVERAGE-POLICY"},
                {"phase_id"}, set(),
            ),
            "G5.<id>.1": (
                "phase_checkpoint", "named_human",
                {"phase_build_plan", "phase_test_uat"}, {"phase_build_plan"}, {"phase_test_uat"},
                {"phase_scope", "phase_exit_test_design"},
                {"G5-PHASE-SCOPE", "G5-PHASE-EXIT-TEST-DESIGN"}, set(), set(),
            ),
            "G5.<id>.2": (
                "phase_checkpoint", "named_human", {"tactical_plan"}, {"tactical_plan"}, set(),
                {"stable_tasks", "dependencies", "paths", "tests", "verification", "rollback"},
                {"G5-TACTICAL-TASKS", "G5-TACTICAL-DEPENDENCIES", "G5-TACTICAL-PATHS", "G5-TACTICAL-TESTS", "G5-TACTICAL-VERIFICATION", "G5-TACTICAL-ROLLBACK"},
                set(), set(),
            ),
            "G5.<id>.3": (
                "phase_checkpoint", "named_human",
                {"construction_directive", "build_prompt", "phase_test_uat"},
                {"construction_directive", "build_prompt", "phase_test_uat"}, set(),
                {"pinned_upstream_authority", "complete_construction_directive", "accepted_test_uat_plan"},
                {"G5-DIRECTIVE-COMPLETE", "G5-BUILD-PROMPT", "G5-TEST-PLAN-ACCEPTED", "G5-UPSTREAM-PINNED", "G5-IMPLEMENTATION-APPROVAL"},
                set(), {"accepted_upstream_authority_set"},
            ),
            "G5.<id>.4": (
                "phase_transition", "named_human_phase_exit",
                {"implementation_evidence", "phase_test_uat", "phase_code_review", "phase_remediation", "traceability", "phase_as_built", "phase_learnings", "phase_value_review"},
                {"implementation_evidence", "phase_test_uat", "phase_code_review", "phase_remediation", "traceability", "phase_as_built", "phase_learnings"},
                {"phase_value_review"},
                {"implementation_candidate", "executed_test_uat", "independent_phase_review", "remediation_disposition", "cumulative_traceability", "phase_as_built_closeout", "phase_learnings", "regression", "coverage_result", "residual_risks", "amendments", "phase_value_disposition", "named_approval"},
                {"G5-EXIT-IMPLEMENTATION", "G5-EXIT-TEST-UAT", "G5-EXIT-REVIEW", "G5-EXIT-REMEDIATION", "G5-EXIT-TRACEABILITY", "G5-EXIT-AS-BUILT", "G5-EXIT-LEARNINGS", "G5-EXIT-REGRESSION", "G5-EXIT-COVERAGE", "G5-EXIT-RESIDUALS", "G5-EXIT-AMENDMENTS", "G5-EXIT-VALUE-DISPOSITION", "G5-EXIT-APPROVAL"},
                set(), set(),
            ),
        }
        for checkpoint in self.collection(self.data.get("checkpoints")):
            checkpoint_id = str(checkpoint.get("id", ""))
            expected = expected_checkpoints.get(checkpoint_id)
            actual = (
                checkpoint.get("event_type"), checkpoint.get("approval"),
                set(self.strings(checkpoint.get("required_artifacts"))),
                {str(item.get("artifact_id", "")) for item in self.collection(checkpoint.get("artifact_requirements"))},
                {str(item.get("artifact_id", "")) for item in self.collection(checkpoint.get("reference_requirements"))},
                {str(item.get("class", "")) for item in self.collection(checkpoint.get("required_evidence"))},
                set(self.strings(checkpoint.get("criterion_ids"))),
                set(self.strings(checkpoint.get("nullable_event_fields"))),
                set(self.strings(checkpoint.get("required_dynamic_evidence"))),
            )
            if expected is not None and actual != expected:
                rule = RULE_PHASE_EXIT if checkpoint_id == "G5.<id>.4" else RULE_CHECKPOINT
                self.add(
                    rule,
                    f"{checkpoint_id} endorsed artifact/reference/evidence/criterion contract drifted",
                    needle=checkpoint_id,
                )

        expected_post_loop = {
            "G5-to-G6": (
                "conditional_nonwaivable_residual",
                {"no_additional_approval", "named_human"},
                "skipped_critical_verification_or_otherwise_nonwaivable_residual",
                "active", "implementation-agent", {"phase_plan", "traceability"},
                {"G5-LOOP-AUTHORIZED", "G5-ALL-PHASES-EXITED", "G5-WHOLE-CANDIDATE", "G5-INTEGRATION-REGRESSION", "G5-CURRENT-TRACEABILITY", "G5-RESIDUAL-DISPOSITION"},
                {"all_declared_phase_exit_event_ids"}, set(),
                {"whole_build_candidate_revision", "integration_regression_result", "residual_findings"},
                {}, False,
            ),
            "G6-to-G7": (
                "conditional_skipped_critical_verification_or_risk",
                {"no_additional_approval", "named_human"},
                "skipped_critical_verification_or_allowed_risk_disposition",
                "active", "code-review-agent", {"implementation_summary", "traceability"},
                {"G6-IMPLEMENTATION-SUMMARY", "G6-CANDIDATE-REVISION", "G6-CHANGED-FILES", "G6-INTEGRATION-REGRESSION", "G6-DEVIATIONS-RESIDUALS", "G6-REVIEW-PACKAGE"},
                set(), set(), set(), {}, False,
            ),
            "G7-to-G8": (
                "named_human_implementation_acceptance", {"named_human"}, None,
                "active", "deployment-readiness-agent",
                {"final_code_review", "aggregate_remediation", "final_test_uat", "traceability"},
                {"G7-INDEPENDENT-REVIEW", "G7-REMEDIATION", "G7-FINAL-UAT", "G7-TRACEABILITY", "G7-RESIDUAL-RISK", "G7-UPSTREAM-BINDINGS"},
                set(), {"accepted_upstream_authority_set"},
                {"accepted_release_candidate", "deployment_intent"}, {}, False,
            ),
            "G8-to-G9": (
                "named_human_project_closeout", {"named_human"}, None,
                "closed", "none",
                {"deployment_record", "project_value_review", "traceability", "project_as_built"},
                {"G9-DEPLOYMENT-DISPOSITION", "G9-OPERATIONS-RESULTS", "G9-VALUE-DISPOSITION", "G9-FINAL-TRACEABILITY", "G9-AS-BUILT-CLOSEOUT"},
                {"deployment_approval_or_non_deployment_approval"}, set(),
                {"deployment_disposition", "operational_results", "value_disposition", "terminal_closeout"},
                {"deploy": ["operational_owner_confirmation"]}, True,
            ),
        }
        transitions = self.collection(self.data.get("transitions"))
        for transition in transitions:
            transition_id = str(transition.get("id", ""))
            expected = expected_post_loop.get(transition_id)
            if expected is None:
                continue
            actual = (
                transition.get("approval"),
                set(self.strings(transition.get("approval_profiles"))),
                transition.get("named_human_condition"),
                transition.get("resulting_project_status"),
                transition.get("resulting_role"),
                set(self.strings(transition.get("required_artifacts"))),
                set(self.strings(transition.get("criterion_ids"))),
                set(self.strings(transition.get("required_event_bindings"))),
                set(self.strings(transition.get("required_dynamic_evidence"))),
                set(self.strings(transition.get("transition_specific_event_fields"))),
                transition.get("conditional_transition_specific_event_fields", {}),
                transition.get("terminal"),
            )
            if actual != expected:
                self.add(
                    RULE_GATE_BINDING,
                    f"{transition_id} endorsed post-loop evidence/approval/state contract drifted",
                    needle=transition_id,
                )

        expected_commands = {"G0-to-G1": "scripts/init-project.sh"}
        expected_commands.update(
            {
                f"G{number}-to-G{number + 1}": f"scripts/close-gate.sh G{number}"
                for number in range(1, 9)
            }
        )
        actual_commands = {
            str(transition.get("id", "")): transition.get("command")
            for transition in transitions
        }
        if actual_commands != expected_commands:
            self.add(
                RULE_TRANSITION,
                "transition commands must map init to G0 and close-gate to each source G1-G8",
                needle="transitions",
            )

        paths = self.data.get("paths", {})
        expected_directories = [
            "docs/project/approvals", "docs/project/architecture", "docs/project/as-built",
            "docs/project/build-plan", "docs/project/build-plan/phases", "docs/project/decisions",
            "docs/project/deployment", "docs/project/design", "docs/project/prd",
            "docs/project/review", "docs/project/security-governance", "docs/project/testing",
            "docs/project/traceability", "docs/project/vision",
        ]
        expected_fixed_paths = {
            "manifest": "docs/project/project.yaml",
            "gate_log": "docs/project/approvals/gate-log.md",
            "vision": "docs/project/vision/vision.md",
            "prd": "docs/project/prd/prd.md",
            "architecture": "docs/project/architecture/architecture.md",
            "technology_stack": "docs/project/decisions/0001-technology-stack.md",
            "governance_security": "docs/project/security-governance/governance-security-spec.md",
            "phase_plan": "docs/project/build-plan/phase-plan.md",
            "implementation_summary": "docs/project/build-plan/implementation-summary.md",
            "traceability": "docs/project/traceability/traceability-matrix.md",
            "final_code_review": "docs/project/review/code-review.md",
            "aggregate_remediation": "docs/project/review/remediation.md",
            "final_test_uat": "docs/project/testing/final-test-uat-report.md",
            "deployment_readiness": "docs/project/deployment/deployment-readiness.md",
            "production_runbook": "docs/project/deployment/production-runbook.md",
            "deployment_record": "docs/project/deployment/deployment-record.md",
            "project_value_review": "docs/project/as-built/value-review.md",
            "project_as_built": "docs/project/as-built/as-built-closeout.md",
        }
        expected_phase_paths = {
            "phase_build_plan": "docs/project/build-plan/phases/phase-<id>-build-plan.md",
            "tactical_plan": "docs/project/build-plan/phases/phase-<id>-tactical-implementation-plan.md",
            "construction_directive": "docs/project/build-plan/phases/phase-<id>-construction-directive.md",
            "build_prompt": "docs/project/build-plan/phases/phase-<id>-build-prompt.md",
            "implementation_evidence": "docs/project/build-plan/phases/phase-<id>-implementation-evidence.md",
            "phase_code_review": "docs/project/build-plan/phases/phase-<id>-code-review.md",
            "phase_remediation": "docs/project/build-plan/phases/phase-<id>-remediation.md",
            "phase_learnings": "docs/project/build-plan/phases/phase-<id>-learnings.md",
            "phase_test_uat": "docs/project/testing/phase-<id>-test-uat-plan.md",
            "phase_as_built": "docs/project/as-built/phase-<id>-as-built-closeout.md",
            "phase_value_review": "docs/project/as-built/phase-<id>-value-review.md",
        }
        planned_scaffold_paths = {
            "docs/project/deployment",
            "docs/project/design",
            "docs/project/review",
        }
        expected_scaffold_records = []
        for directory in expected_directories:
            if directory in planned_scaffold_paths:
                record = {
                    "path": directory,
                    "delivery_state": "current" if self.mode == "release" else "planned",
                    "required_work_package": "WP-04",
                }
            else:
                record = {"path": directory, "delivery_state": "current"}
            expected_scaffold_records.append(record)
        if (
            paths.get("canonical_directories") != expected_directories
            or paths.get("project_scaffold_directories") != expected_scaffold_records
            or paths.get("canonical_fixed_artifacts") != expected_fixed_paths
            or paths.get("phase_artifact_patterns") != expected_phase_paths
            or paths.get("supporting_design_pattern") != "docs/project/design/<name>.md"
            or paths.get("forbidden_competing_directories") != ["docs/project/supporting"]
            or paths.get("rules")
            != {
                "phase_id_placeholder_is_only_valid_in_patterns": True,
                "fixed_authority_paths_must_not_contain_placeholders": True,
                "technique_specific_supporting_artifacts_use_design_directory": True,
            }
        ):
            self.add(
                RULE_FIXED_PATH,
                "canonical directory, fixed artifact, phase pattern, or supporting-design path contract drifted",
                needle="paths",
            )
        expected_artifact_paths = {
            "project_manifest": expected_fixed_paths["manifest"],
            **{key: value for key, value in expected_fixed_paths.items() if key != "manifest"},
            **expected_phase_paths,
            "supporting_design": "docs/project/design/<name>.md",
        }
        actual_artifact_paths = {
            str(artifact.get("id", "")): artifact.get("path")
            for artifact in self.collection(self.data.get("artifacts"))
        }
        if actual_artifact_paths != expected_artifact_paths:
            self.add(
                RULE_ARTIFACT,
                "artifact path values must match the exact canonical path maps",
                needle="artifacts",
            )

        def canonical_digest(value: Any) -> str:
            payload = json.dumps(
                value, sort_keys=True, separators=(",", ":"), ensure_ascii=True
            )
            return hashlib.sha256((payload + "\n").encode("utf-8")).hexdigest()

        exact_catalog_digests = {
            "checkpoints": "297d3764f6f96d05baebf5227961b11ef568dfeb5215461bb59ccb7980045859",
            "post_loop_transitions": "cdbcffe7cb7a3784f7706721ad38d33e8e46d56fc930f6a6dfee23238ef9fdf4",
            "artifacts_candidate": "2d75f8ef68c40e44d7455d7df7ae3cc1260f9e48b49abc53b64c3d022e2ae008",
            "artifacts_release": "590307e4a8223037a314b6fd2d7f66ecee8356a3775ee906d48e872a154eaa01",
        }
        exact_values = {
            "checkpoints": self.data.get("checkpoints"),
            "post_loop_transitions": [
                transition
                for transition in transitions
                if transition.get("id") in expected_post_loop
            ],
            f"artifacts_{self.mode}": self.data.get("artifacts"),
        }
        for label, value in exact_values.items():
            if canonical_digest(value) != exact_catalog_digests[label]:
                rule = RULE_ARTIFACT if label.startswith("artifacts") else RULE_GATE_BINDING
                self.add(
                    rule,
                    f"exact endorsed {label.replace('_', ' ')} record contract drifted",
                    needle="artifacts" if label.startswith("artifacts") else label.split("_")[0],
                )

    def iter_paths(self) -> Iterator[tuple[str, str, str, str]]:
        def walk(value: Any, label: str, inherited_state: str = "current") -> Iterator[tuple[str, str, str, str]]:
            if isinstance(value, str):
                if "/" in value and not value.startswith(("http://", "https://")):
                    yield label, value, inherited_state, "fixed"
                return
            if isinstance(value, list):
                for index, item in enumerate(value):
                    yield from walk(item, f"{label}[{index}]", inherited_state)
                return
            if not isinstance(value, dict):
                return
            state = str(value.get("lifecycle_state", value.get("state", inherited_state)))
            path = self.first(value, "path", "file", "template", "source")
            kind = str(value.get("path_kind", value.get("kind", "fixed")))
            if isinstance(path, str) and "/" in path:
                yield label, path, state, kind
            for key, item in value.items():
                if key in {"path", "file", "template", "source", "lifecycle_state", "state"}:
                    continue
                yield from walk(item, f"{label}.{key}", state)

        yield from walk(self.data.get("paths", {}), "paths")

    @staticmethod
    def is_variable_path(path: str, kind: str) -> bool:
        return kind in {"pattern", "variable", "phase_variable"} or bool(
            re.search(r"<(?:id|phase-id|project-slug|[^>]+)>", path)
        )

    def check_declared_paths(self) -> None:
        for label, declared, state, _kind in self.iter_paths():
            if (
                declared.startswith("docs/project/supporting")
                and "forbidden_competing_directories" not in label
            ):
                self.add(
                    RULE_SUPPORTING_DIR,
                    f"competing supporting directory is forbidden: {declared}",
                    needle=declared,
                )
            if (
                "canonical_fixed_artifacts" in label
                and re.search(r"<[^>]+>|\[[^]]+\]", declared)
            ):
                self.add(
                    RULE_FIXED_PATH,
                    f"fixed authority path contains a floating placeholder: {declared}",
                    needle=declared,
                )
            if state not in {"current", "planned", "historical"}:
                self.add(
                    RULE_SCHEMA,
                    f"invalid lifecycle_state {state!r} for {label}",
                    needle=declared,
                )

        forbidden = self.data.get("paths", {}).get("forbidden_competing_directories", [])
        if forbidden != ["docs/project/supporting"]:
            self.add(
                RULE_SUPPORTING_DIR,
                "forbidden competing directories must contain only docs/project/supporting",
                needle="forbidden_competing_directories",
            )

        supporting = self.data.get("paths", {}).get("supporting_design_pattern")
        if supporting != "docs/project/design/<name>.md":
            self.add(
                RULE_SUPPORTING_DIR,
                "supporting design pattern must be docs/project/design/<name>.md",
                needle="supporting_design_pattern",
            )

        self.check_source_references()

    def check_source_references(self) -> None:
        references: list[tuple[str, str, str]] = []
        registry = self.data.get("registry", {})
        if isinstance(registry, dict):
            for key in ("source_file", "human_authority", "constitutional_authority"):
                value = registry.get(key)
                if isinstance(value, str):
                    references.append((f"registry.{key}", value, "current"))
        for role in self.collection(self.data.get("roles")):
            value = role.get("source_file")
            if isinstance(value, str):
                references.append((f"role {role.get('id')}", value, "current"))
        for record in self.collection(self.data.get("decision_records")):
            value = record.get("source_file")
            state = str(record.get("lifecycle_state", "current"))
            if isinstance(value, str):
                references.append((f"decision record {value}", value, state))
        manifest = self.data.get("manifest", {})
        if isinstance(manifest, dict) and isinstance(manifest.get("source_file"), str):
            references.append(("manifest source", manifest["source_file"], "current"))

        for label, path, state in references:
            if not self.is_safe_repository_path(path):
                self.add(
                    RULE_REFERENCE,
                    f"source reference must be a safe repository-relative path ({label}): {path}",
                    needle=path,
                )
                continue
            exists = (self.root / path).is_file()
            if state == "current" and not exists:
                self.add(
                    RULE_REFERENCE,
                    f"current source reference does not exist ({label}): {path}",
                    needle=path,
                )
            elif state == "planned" and self.mode == "release":
                self.add(
                    RULE_DELIVERY,
                    f"release mode does not allow planned source ({label}): {path}",
                    needle=path,
                )

    def artifact_state(self, artifact: dict[str, Any]) -> str:
        return str(artifact.get("lifecycle_state", artifact.get("state", "current")))

    def check_artifacts(self) -> None:
        for artifact in self.collection(self.data.get("artifacts")):
            identifier = str(artifact.get("id", ""))
            lifecycle_state = self.artifact_state(artifact)
            if lifecycle_state == "planned" and self.mode == "release":
                self.add(
                    RULE_DELIVERY,
                    f"release mode does not allow planned artifact: {identifier}",
                    needle=identifier,
                )
            elif lifecycle_state not in {"current", "planned", "historical"}:
                self.add(
                    RULE_SCHEMA,
                    f"artifact {identifier} has invalid lifecycle_state {lifecycle_state!r}",
                    needle=identifier,
                )
            owner = self.first(artifact, "owner_role", "authoring_owner", "owner", "role")
            binding = self.first(
                artifact,
                "lifecycle_bindings",
                "lifecycle_binding",
                "gate_binding",
                "checkpoint_binding",
                "lifecycle_owner",
            )
            if not isinstance(owner, str) or not owner:
                self.add(
                    RULE_ARTIFACT,
                    f"artifact {identifier} has no authoring owner",
                    needle=identifier,
                )
            if binding in (None, "", []):
                self.add(
                    RULE_ARTIFACT,
                    f"artifact {identifier} has no lifecycle binding",
                    needle=identifier,
                )
            template = self.first(artifact, "template", "template_path")
            template_state = str(artifact.get("template_state", self.artifact_state(artifact)))
            if isinstance(template, str):
                if not self.is_safe_repository_path(template):
                    self.add(
                        RULE_REFERENCE,
                        f"artifact {identifier} template must be repository-relative: {template}",
                        needle=identifier,
                    )
                    continue
                if template.startswith("docs/project/supporting"):
                    self.add(
                        RULE_SUPPORTING_DIR,
                        f"artifact {identifier} uses forbidden supporting directory: {template}",
                        needle=template,
                    )
                template_path = self.root / template
                if template_state == "current" and not template_path.is_file():
                    self.add(
                        RULE_REFERENCE,
                        f"current template for artifact {identifier} does not exist: {template}",
                        needle=template,
                    )
                elif template_state == "planned" and self.mode == "release":
                    self.add(
                        RULE_DELIVERY,
                        f"release mode does not allow planned template for {identifier}: {template}",
                        needle=template,
                    )
                identity_state = str(
                    artifact.get("identity_contract_state", template_state)
                )
                if identity_state == "planned" and self.mode == "release":
                    self.add(
                        RULE_DELIVERY,
                        f"release mode does not allow planned project-identity contract for {identifier}",
                        needle=identifier,
                    )
                elif identity_state not in {"current", "planned"}:
                    self.add(
                        RULE_SCHEMA,
                        f"artifact {identifier} has invalid identity_contract_state {identity_state!r}",
                        needle=identifier,
                    )
                if (
                    template_path.is_file()
                    and identity_state == "current"
                    and self._requires_project_field(artifact)
                ):
                    if not re.search(
                        r"(?m)^project:\s*\S+", template_path.read_text(encoding="utf-8")
                    ):
                        self.add(
                            RULE_TEMPLATE_PROJECT,
                            f"per-project template for {identifier} lacks a non-empty project: field",
                            file=template_path,
                        )
            evidence_class = self.first(artifact, "evidence_class", "evidence_classes")
            if self._contains_binding(binding, "G5.<phase-id>.4", "G5.<id>.4", "phase_exit"):
                if evidence_class in (None, "", []):
                    self.add(
                        RULE_PHASE_EXIT,
                        f"phase-exit artifact {identifier} has no evidence class",
                        needle=identifier,
                    )

    @staticmethod
    def _contains_binding(binding: Any, *needles: str) -> bool:
        rendered = json.dumps(binding, sort_keys=True) if binding is not None else ""
        return any(needle in rendered for needle in needles)

    def _requires_project_field(self, artifact: dict[str, Any]) -> bool:
        value = self.first(artifact, "project_identity_required", "requires_project_field")
        if isinstance(value, bool):
            return value
        scope = str(artifact.get("scope", artifact.get("artifact_scope", "project")))
        return scope in {"project", "phase", "per_project", "per_phase"}

    def check_project_templates(self) -> None:
        manifest = self.data.get("manifest", {})
        if not isinstance(manifest, dict):
            return
        contract_state = str(manifest.get("contract_state", "current"))
        if contract_state == "planned" and self.mode == "release":
            self.add(
                RULE_DELIVERY,
                "release mode does not allow a planned manifest contract",
                needle="contract_state",
            )
        elif contract_state not in {"current", "planned"}:
            self.add(
                RULE_SCHEMA,
                f"manifest.contract_state is invalid: {contract_state!r}",
                needle="contract_state",
            )
        invariants = {
            str(invariant.get("id")): invariant
            for invariant in self.collection(manifest.get("invariants"))
        }
        phase_axis = invariants.get("MANIFEST-PHASE-AXIS")
        expected_delivery_state = "current" if self.mode == "release" else "planned"
        if (
            manifest.get("schema_version") != 2
            or manifest.get("source_file") != "docs/project-template/project.yaml"
            or manifest.get("contract_state") != expected_delivery_state
            or manifest.get("required_work_package") != "WP-04"
            or manifest.get("field_states")
            != {
                "phase.loop_status": {
                    "contract_state": expected_delivery_state,
                    "required_work_package": "WP-04",
                },
                "phase.current_phase_id": {
                    "contract_state": expected_delivery_state,
                    "required_work_package": "WP-04",
                },
            }
        ):
            self.add(
                RULE_PROJECT_TEMPLATE,
                "manifest schema/source/delivery and planned-field contracts must remain exact",
                needle="manifest",
            )
        expected_manifest_fields = {
            "project.name",
            "project.slug",
            "project.status",
            "project.current_gate",
            "project.methodology_version",
            "human_control.owner",
            "human_control.approver",
            "human_control.deployment_approver",
            "collaboration.active_role",
            "scaling.blast_radius_class",
            "approvals.current_gate",
            "approvals.latest_decision",
            "phase.loop_status",
            "phase.phase_position",
            "phase.current_phase_id",
            "phase.phase_plan",
            "phase.phases",
        }
        if set(self.strings(manifest.get("required_fields"))) != expected_manifest_fields:
            self.add(
                RULE_PROJECT_TEMPLATE,
                "manifest required_fields must preserve the full control-plane contract",
                needle="required_fields",
            )
        expected_terminal_invariant = {
            "id": "MANIFEST-TERMINAL",
            "rule": "G9 requires project.status closed, active_role none, and no next gate, role, or artifact.",
            "current_gate": "G9",
            "project_status": "closed",
            "active_role": "none",
            "next_gate_must_be_null": True,
            "next_role_must_be_null": True,
            "next_artifact_must_be_null": True,
        }
        if set(invariants) != {
            "MANIFEST-GATE-MAJOR",
            "MANIFEST-PHASE-AXIS",
            "MANIFEST-PHASE-MEMBER",
            "MANIFEST-PHASE-ORDER",
            "MANIFEST-LATEST-SUMMARY",
            "MANIFEST-TERMINAL",
            "MANIFEST-STRICT-V2",
        } or invariants.get("MANIFEST-TERMINAL") != expected_terminal_invariant:
            self.add(
                RULE_GATE_BINDING,
                "manifest must preserve its exact invariant catalog and terminal correlation",
                needle="MANIFEST-TERMINAL",
            )
        retained_final_position = False
        if isinstance(phase_axis, dict):
            retained_final_position = any(
                phase_axis.get(key) is True
                for key in (
                    "retained_final_position",
                    "retain_final_phase_position_after_loop",
                    "final_phase_position_retained",
                )
            )
            rule_text = str(phase_axis.get("rule", "")).lower()
            retained_final_position = retained_final_position or (
                "retain" in rule_text and "final phase position" in rule_text
            )
        if not retained_final_position:
            self.add(
                RULE_GATE_BINDING,
                "MANIFEST-PHASE-AXIS must retain the final phase position after the G5 loop closes",
                needle="MANIFEST-PHASE-AXIS",
            )
        template_path = self.first(manifest, "source_file", "template", "template_path", "path")
        if isinstance(template_path, str):
            target = self.root / template_path
            if not target.is_file():
                self.add(
                    RULE_PROJECT_TEMPLATE,
                    f"project manifest template does not exist: {template_path}",
                    needle=template_path,
                )
            else:
                text = target.read_text(encoding="utf-8")
                manifest_paths, manifest_syntax_errors = self.yaml_mapping_paths(text)
                for line_number, error in manifest_syntax_errors:
                    self.add(
                        RULE_PROJECT_TEMPLATE,
                        f"manifest template line {line_number}: {error}",
                        file=target,
                    )
                field_states = manifest.get("field_states", {})
                if not isinstance(field_states, dict):
                    self.add(
                        RULE_SCHEMA,
                        "manifest.field_states must be an object",
                        needle="field_states",
                    )
                    field_states = {}
                for field in self.strings(manifest.get("required_fields")):
                    raw_state = field_states.get(field, "current")
                    state = str(
                        raw_state.get("contract_state", "current")
                        if isinstance(raw_state, dict)
                        else raw_state
                    )
                    if state == "planned" and self.mode == "release":
                        self.add(
                            RULE_DELIVERY,
                            f"release mode does not allow planned manifest field: {field}",
                            needle=field,
                        )
                    elif state not in {"current", "planned"}:
                        self.add(
                            RULE_SCHEMA,
                            f"manifest field {field} has invalid state {state!r}",
                            needle=field,
                        )
                    elif state == "current" and field not in manifest_paths:
                        self.add(
                            RULE_PROJECT_TEMPLATE,
                            f"manifest template lacks required field {field}",
                            file=target,
                        )

        paths = self.data.get("paths", {})
        required_dirs = self.strings(paths.get("canonical_directories"))
        delivery_records = self.collection(paths.get("project_scaffold_directories"))
        delivered_by_project_path = {str(record.get("path")): record for record in delivery_records}
        initializer_path = self.root / "scripts/init-project.sh"
        initializer_text = (
            initializer_path.read_text(encoding="utf-8") if initializer_path.is_file() else ""
        )
        for directory in required_dirs:
            if directory.startswith("docs/project/supporting"):
                self.add(
                    RULE_SUPPORTING_DIR,
                    f"manifest declares forbidden supporting directory: {directory}",
                    needle=directory,
                )
            record = delivered_by_project_path.get(directory)
            if record is None:
                self.add(
                    RULE_PROJECT_TEMPLATE,
                    f"canonical directory lacks explicit scaffold delivery state: {directory}",
                    needle=directory,
                )
                continue
            state = str(record.get("delivery_state", ""))
            if state == "current":
                relative = directory.removeprefix("docs/project/")
                expected_initializer_path = f'"$target/{relative}"'
                emitted_descendant_prefix = f'"$target/{relative}/'
                if (
                    expected_initializer_path not in initializer_text
                    and emitted_descendant_prefix not in initializer_text
                ):
                    self.add(
                        RULE_PROJECT_TEMPLATE,
                        f"current scaffold directory is not emitted by init-project.sh: {directory}",
                        file=initializer_path,
                    )
            elif state == "planned" and self.mode == "release":
                self.add(
                    RULE_DELIVERY,
                    f"release mode does not allow planned scaffold directory: {directory}",
                    needle=directory,
                )
            elif state not in {"current", "planned"}:
                self.add(
                    RULE_SCHEMA,
                    f"scaffold delivery for {directory} has invalid state {state!r}",
                    needle=directory,
                )

        compatibility = self.data.get("compatibility", {})
        if isinstance(compatibility, dict):
            scaffold = compatibility.get("scaffold", {})
            if isinstance(scaffold, dict):
                command = scaffold.get("phase_scaffold_command")
                state = scaffold.get("phase_scaffold_state")
                if state == "planned" and self.mode == "release":
                    self.add(
                        RULE_DELIVERY,
                        f"release mode does not allow planned phase scaffold command: {command}",
                        needle="phase_scaffold_command",
                    )
                elif state == "current" and isinstance(command, str):
                    if not (self.root / command).is_file():
                        self.add(
                            RULE_REFERENCE,
                            f"current phase scaffold command does not exist: {command}",
                            needle=command,
                        )
                elif state not in {"current", "planned"}:
                    self.add(
                        RULE_SCHEMA,
                        f"phase scaffold state is invalid: {state!r}",
                        needle="phase_scaffold_state",
                    )

    @staticmethod
    def yaml_mapping_paths(text: str) -> tuple[set[str], list[tuple[int, str]]]:
        """Parse dotted paths and structural errors from the supported YAML subset."""
        paths: set[str] = set()
        errors: list[tuple[int, str]] = []
        prefixes: dict[int, tuple[str, ...]] = {0: ()}
        key_pattern = re.compile(r"^( *)([A-Za-z0-9_-]+):(.*)$")
        list_pattern = re.compile(r"^( *)-\s+(.*)$")
        inline_mapping_pattern = re.compile(r"^([A-Za-z0-9_-]+):(.*)$")
        for line_number, line in enumerate(text.splitlines(), start=1):
            if "\t" in line:
                errors.append((line_number, "tabs are not allowed in the manifest YAML subset"))
                continue
            if not line.strip() or line.lstrip().startswith("#"):
                continue

            key_match = key_pattern.match(line)
            list_match = list_pattern.match(line)
            match = key_match or list_match
            if match is None:
                errors.append(
                    (line_number, "line is not a supported mapping entry or list item")
                )
                continue
            indent = len(match.group(1))
            if indent % 2:
                errors.append((line_number, "indentation must use multiples of two spaces"))
                continue
            for depth in [depth for depth in prefixes if depth > indent]:
                del prefixes[depth]
            if indent not in prefixes:
                errors.append(
                    (
                        line_number,
                        "indentation skips a level or follows a scalar value",
                    )
                )
                continue

            prefix = prefixes[indent]
            prefixes.pop(indent + 2, None)
            if key_match is not None:
                key = key_match.group(2)
                path = ".".join((*prefix, key))
                if path in paths:
                    errors.append((line_number, f"duplicate mapping path {path}"))
                else:
                    paths.add(path)
                value = key_match.group(3).strip()
                if not value or value.startswith("#"):
                    prefixes[indent + 2] = (*prefix, key)
                continue

            item = list_match.group(2).strip()
            inline_mapping = inline_mapping_pattern.match(item)
            if inline_mapping is not None:
                # A list mapping creates an anonymous object. Its child keys do
                # not participate in the manifest control-plane field paths.
                prefixes[indent + 2] = (*prefix, "[]")

        return paths, errors

    def check_gate_bindings(self) -> None:
        gates = {str(item.get("id")): item for item in self.collection(self.data.get("gates"))}
        expected = {
            "G6": ("implementation", "readiness"),
            "G7": ("review", "remediation", "acceptance"),
            "G8": ("deployment", "operations"),
            "G9": ("as-built", "closeout", "closed"),
        }
        for gate_id, required_words in expected.items():
            gate = gates.get(gate_id)
            if gate is None:
                continue
            rendered = json.dumps(gate, sort_keys=True).lower()
            missing_words = [word for word in required_words if word not in rendered]
            if missing_words:
                self.add(
                    RULE_GATE_BINDING,
                    f"{gate_id} lacks lifecycle/evidence concepts: {', '.join(missing_words)}",
                    needle=f'"{gate_id}"',
                )
        g6 = json.dumps(gates.get("G6", {}), sort_keys=True).lower()
        g7 = json.dumps(gates.get("G7", {}), sort_keys=True).lower()
        if "final review" in g6 or "deployment" in g7:
            self.add(
                RULE_GATE_BINDING,
                "G6/G7 post-loop evidence ownership is reversed or stale",
                needle='"G6"',
            )

        deployment = self.data.get("deployment", {})
        if not isinstance(deployment, dict):
            self.add(RULE_GATE_BINDING, "deployment contract must be an object")
            return
        self.check_artifact_requirement_contract(
            deployment,
            "deployment authorization",
            RULE_ARTIFACT,
            require_coverage=False,
        )
        non_deployment = deployment.get("non_deployment_path", {})
        required_fields = {
            "disposition",
            "rationale",
            "scope",
            "release_candidate",
            "approver",
            "approved_on",
            "future_trigger_or_finality",
        }
        declared_fields = set(
            self.strings(non_deployment.get("required_fields"))
            if isinstance(non_deployment, dict)
            else []
        )
        if (
            not isinstance(non_deployment, dict)
            or non_deployment.get("allowed") is not True
            or non_deployment.get("authorization_required") is not True
            or declared_fields != required_fields
            or deployment.get("terminal_transition") != "G8-to-G9"
        ):
            self.add(
                RULE_GATE_BINDING,
                "explicit non-deployment path is incomplete or not bound to G8-to-G9",
                needle="non_deployment_path",
            )

    def check_versions(self) -> None:
        versions = self.data.get("versions", {})
        registry = self.data.get("registry", {})
        target = self.first(versions, "candidate", "candidate_target", "target", "target_version")
        if isinstance(target, dict):
            target = self.first(target, "version", "id")
        expected = "1.0.2"
        if target != expected:
            self.add(
                RULE_VERSION,
                f"candidate target must be {expected}, not {target!r}",
                needle="candidate",
            )
        if registry.get("target_release") != target:
            self.add(
                RULE_VERSION,
                "registry.target_release must equal versions.candidate",
                needle="target_release",
            )
        status = self.first(versions, "status", "candidate_status", "release_status")
        if isinstance(versions.get("candidate_target"), dict):
            status = versions["candidate_target"].get("status", status)
        if self.mode == "candidate":
            if registry.get("status") != "candidate":
                self.add(RULE_VERSION, "candidate mode requires registry.status candidate")
            if registry.get("released_current") is not None:
                self.add(
                    RULE_VERSION,
                    "candidate mode registry.released_current must remain null",
                    needle="released_current",
                )
            if versions.get("released_current") is not None:
                self.add(
                    RULE_VERSION,
                    "candidate mode versions.released_current must remain null",
                    needle="released_current",
                )
            if status not in {"proposed", "accepted_candidate"}:
                self.add(
                    RULE_VERSION,
                    "candidate mode candidate_status must be proposed or accepted_candidate",
                )
        else:
            if registry.get("status") != "released":
                self.add(RULE_VERSION, "release mode requires registry.status released")
            if registry.get("released_current") != target:
                self.add(
                    RULE_VERSION,
                    "release mode requires registry.released_current equal the candidate",
                    needle="released_current",
                )
            if versions.get("released_current") != target:
                self.add(
                    RULE_VERSION,
                    "release mode requires versions.released_current equal the candidate",
                    needle="released_current",
                )
            if status != "released":
                self.add(
                    RULE_VERSION,
                    "release mode requires candidate_status released",
                )

        release_rules = versions.get("release_rules", {})
        required_release_rules = {
            "candidate_must_not_be_presented_as_released": True,
            "active_targets_change_atomically": True,
            "unknown_historical_mapping_is_not_tagged": True,
            "tag_publication_requires_separate_human_approval": True,
        }
        if release_rules != required_release_rules:
            self.add(
                RULE_VERSION,
                "release rules must preserve candidate honesty, atomic identity, and approval-gated tags",
                needle="release_rules",
            )

        observed = self.first(versions, "observed_active_claims", "observed_claims")
        observation_revision = versions.get("observation_revision")
        expected_observed_claims = [
            {
                "source_file": "README.md",
                "field": "release badge and prose",
                "value": "0.1.0-baseline",
            },
            {
                "source_file": "docs/methodology/constitution/gendev.md",
                "field": "Version",
                "value": "0.1.0-baseline",
            },
            {
                "source_file": "docs/project-template/project.yaml",
                "field": "project.methodology_version",
                "value": "0.4.0-verification-first",
            },
        ]
        if (
            observed != expected_observed_claims
            or observation_revision != "02ae0fc192a898cd482007dfc65612ff907a3bda"
            or versions.get("published_tags_observed")
            != [
                "v0.1.0-baseline",
                "v0.2.0-phase-loop",
                "v0.3.0-documentation-structure",
                "v0.4.0-verification-first",
                "v0.5.0-operational-coherence",
            ]
        ):
            self.add(
                RULE_VERSION,
                "baseline observation revision, three active claims, and published tag set must remain exact",
                needle="observed_active_claims",
            )
        revision_valid = isinstance(observation_revision, str) and bool(
            re.fullmatch(r"[0-9a-fA-F]{40}", observation_revision)
        )
        if not revision_valid:
            self.add(
                RULE_VERSION,
                "versions.observation_revision must be an exact 40-hex commit",
                needle="observation_revision",
            )
        elif subprocess.run(
            ["git", "rev-parse", "--verify", f"{observation_revision}^{{commit}}"],
            cwd=self.root,
            capture_output=True,
            check=False,
        ).returncode != 0:
            self.add(
                RULE_VERSION,
                f"observation revision does not resolve: {observation_revision}",
                needle="observation_revision",
            )
            revision_valid = False

        if isinstance(observed, list):
            for claim in observed:
                if not isinstance(claim, dict):
                    continue
                path = self.first(claim, "source_file", "path", "file")
                value = self.first(claim, "value", "version")
                if not isinstance(path, str) or not isinstance(value, str):
                    self.add(RULE_VERSION, "observed version claim needs path and version")
                    continue
                if not self.is_safe_repository_path(path):
                    self.add(
                        RULE_REFERENCE,
                        f"observed version source must be repository-relative: {path}",
                        needle=path,
                    )
                    continue
                target_path = self.root / path
                if revision_valid:
                    historical = subprocess.run(
                        ["git", "show", f"{observation_revision}:{path}"],
                        cwd=self.root,
                        capture_output=True,
                        text=True,
                        check=False,
                    )
                    if historical.returncode != 0 or value not in historical.stdout:
                        self.add(
                            RULE_VERSION,
                            f"observed version {value!r} is not proven at {observation_revision}:{path}",
                            needle=path,
                        )
                if self.mode == "candidate" and not target_path.is_file():
                    self.add(
                        RULE_REFERENCE,
                        f"live version claim source does not exist: {path}",
                        needle=path,
                    )
                elif self.mode == "candidate" and value not in target_path.read_text(
                    encoding="utf-8"
                ):
                    self.add(
                        RULE_VERSION,
                        f"live candidate version {value!r} is not present in {path}",
                        needle=path,
                    )

        published_tags = versions.get("published_tags_observed")
        if not isinstance(published_tags, list) or not published_tags:
            self.add(RULE_VERSION, "published_tags_observed must be a non-empty array")
        else:
            for tag in published_tags:
                if not isinstance(tag, str) or not tag or subprocess.run(
                    ["git", "rev-parse", "--verify", f"refs/tags/{tag}^{{commit}}"],
                    cwd=self.root,
                    capture_output=True,
                    check=False,
                ).returncode != 0:
                    self.add(
                        RULE_VERSION,
                        f"observed published tag does not resolve: {tag!r}",
                        needle="published_tags_observed",
                    )

        synchronization_targets = versions.get("synchronization_targets", [])
        if not isinstance(synchronization_targets, list):
            self.add(RULE_VERSION, "versions.synchronization_targets must be an array")
            return
        release_index_state = "current" if self.mode == "release" else "planned"
        expected_sync_targets = [
            {
                "source_file": "README.md",
                "field": "current methodology version",
                "delivery_state": "current",
                "release_value_pattern": r"(?m)^Current methodology version: `1\.0\.2`\s*$",
            },
            {
                "source_file": "docs/methodology/constitution/gendev.md",
                "field": "Version",
                "delivery_state": "current",
                "release_value_pattern": r"(?m)^Version: 1\.0\.2\s*$",
            },
            {
                "source_file": "docs/project-template/project.yaml",
                "field": "project.methodology_version",
                "delivery_state": "current",
                "release_value_pattern": r"(?m)^\s+methodology_version:\s*1\.0\.2\s*$",
            },
            {
                "source_file": "docs/methodology/schema/lifecycle.json",
                "field": "versions.released_current",
                "delivery_state": "current",
                "release_value_pattern": r'(?m)^\s*"released_current":\s*"1\.0\.2"',
            },
            {
                "source_file": "docs/resources/releases/README.md",
                "field": "active release candidate",
                "delivery_state": release_index_state,
                "required_work_package": "WP-11",
                "release_value_pattern": r"(?m)^Active release candidate:\s*1\.0\.2\s*$",
            },
        ]
        if synchronization_targets != expected_sync_targets:
            self.add(
                RULE_VERSION,
                "release synchronization targets must preserve exact field-specific anchored candidate patterns",
                needle="synchronization_targets",
            )
        required_sync_paths = {
            "README.md",
            "docs/methodology/constitution/gendev.md",
            "docs/project-template/project.yaml",
            "docs/methodology/schema/lifecycle.json",
            "docs/resources/releases/README.md",
        }
        declared_sync_paths = [
            target_record.get("source_file")
            for target_record in synchronization_targets
            if isinstance(target_record, dict)
        ]
        if set(declared_sync_paths) != required_sync_paths or len(declared_sync_paths) != len(
            required_sync_paths
        ):
            self.add(
                RULE_VERSION,
                "version synchronization targets must contain exactly the five required active surfaces",
                needle="synchronization_targets",
            )
        for target_record in synchronization_targets:
            if not isinstance(target_record, dict):
                self.add(RULE_VERSION, "version synchronization target must be an object")
                continue
            path = target_record.get("source_file")
            state = target_record.get("delivery_state")
            if not isinstance(path, str) or state not in {"current", "planned"}:
                self.add(
                    RULE_VERSION,
                    f"version synchronization target has invalid path/state: {target_record!r}",
                )
                continue
            if not self.is_safe_repository_path(path):
                self.add(
                    RULE_REFERENCE,
                    f"version synchronization source must be repository-relative: {path}",
                    needle=path,
                )
                continue
            target_path = self.root / path
            if state == "current" and not target_path.is_file():
                self.add(
                    RULE_REFERENCE,
                    f"current version synchronization target does not exist: {path}",
                    needle=path,
                )
            elif state == "planned" and self.mode == "release":
                self.add(
                    RULE_DELIVERY,
                    f"release mode does not allow planned version synchronization target: {path}",
                    needle=path,
                )
            if self.mode == "release":
                pattern = target_record.get("release_value_pattern")
                if not isinstance(pattern, str) or not pattern:
                    self.add(
                        RULE_VERSION,
                        f"release synchronization target lacks release_value_pattern: {path}",
                        needle=path,
                    )
                    continue
                if path == "docs/resources/releases/README.md" and (
                    "Active release candidate" not in pattern
                    and "Latest published release" not in pattern
                ):
                    self.add(
                        RULE_VERSION,
                        "release-index pattern must bind the release identity field "
                        "(Active release candidate before publication, "
                        "Latest published release after)",
                        needle=path,
                    )
                try:
                    compiled = re.compile(pattern, re.MULTILINE)
                except re.error as exc:
                    self.add(
                        RULE_VERSION,
                        f"invalid release_value_pattern for {path}: {exc}",
                        needle=path,
                    )
                    continue
                if target_path.is_file() and not compiled.search(
                    target_path.read_text(encoding="utf-8")
                ):
                    self.add(
                        RULE_VERSION,
                        f"release value pattern does not match live file: {path}",
                        file=target_path,
                    )

    def check_decisions(self) -> None:
        valid = {
            "active",
            "active_candidate",
            "partially_superseded",
            "partially_superseded_candidate",
            "historical_example",
        }
        decision_records = self.collection(self.data.get("decision_records"))
        if not decision_records:
            self.add(RULE_DECISION, "registry classifies no design decisions")
            return
        known_decisions = {
            str(decision.get("id")) for decision in self.collection(self.data.get("decisions"))
        }
        expected_decisions = {f"D-{number:03d}" for number in range(1, 19)}
        if known_decisions != expected_decisions:
            self.add(
                RULE_DECISION,
                "decision catalog must contain exactly D-001 through D-018",
                needle="decisions",
            )
        expected_decision_contracts: dict[str, tuple[str, set[str]]] = {
            "D-001": ("Release Shape", {"versions"}),
            "D-002": ("Platform Contract", {"generation.platform_contract"}),
            "D-003": ("Core Dependency Policy", {"generation.runtime_dependency_policy"}),
            "D-004": (
                "Two-Axis G5 State Model",
                {"gates.G5", "checkpoints", "manifest.invariants"},
            ),
            "D-005": ("Complete Phase Exit", {"checkpoints.G5.<id>.4"}),
            "D-006": (
                "Phase Exit Approval",
                {
                    "checkpoints.G5.<id>.4.approval",
                    "approval_policy.phase_exit",
                    "events.phase_transition",
                    "scaling.classes",
                },
            ),
            "D-007": ("NAA Authority Boundary", {"naa"}),
            "D-008": (
                "Tactical Identifier Contract",
                {"identifiers.workstream", "identifiers.task"},
            ),
            "D-009": ("Canonical Artifact References", {"paths", "references"}),
            "D-010": ("Coverage Policy", {"scaling.coverage_policy"}),
            "D-011": (
                "Approval Evidence Contract",
                {"events", "event_serialization", "event_evidence_item"},
            ),
            "D-012": (
                "Reviewed Revision Contract",
                {
                    "evidence_categories",
                    "event_evidence_item.revision_rules",
                    "event_reference_item",
                    "event_serialization.record_contracts.event_evidence_item",
                },
            ),
            "D-013": ("Legacy Compatibility", {"compatibility"}),
            "D-014": ("Scaffold Timing", {"compatibility.scaffold"}),
            "D-015": ("Release And Historical Tags", {"versions.release_rules"}),
            "D-016": ("Single Lifecycle Registry", {"registry", "generation"}),
            "D-017": (
                "Verification-First Scaling",
                {"criteria.G2", "criteria.G3", "scaling.classes"},
            ),
            "D-018": (
                "Post-Loop Evidence Chain",
                {
                    "transitions.G5-to-G9",
                    "events.deployment_approval",
                    "deployment",
                    "value_review_contract",
                    "artifacts.aggregate",
                },
            ),
        }
        authority_records = [
            record for record in decision_records if self.strings(record.get("decision_ids"))
        ]
        ratification_states = {record.get("ratification_state") for record in authority_records}
        if ratification_states == {"ready_for_approval"}:
            expected_decision_state = "ready_for_ratification"
            expected_candidate_status = "proposed"
        elif ratification_states == {"accepted"}:
            expected_decision_state = "accepted"
            expected_candidate_status = (
                "released" if self.mode == "release" else "accepted_candidate"
            )
        else:
            expected_decision_state = "<invalid>"
            expected_candidate_status = "<invalid>"
            self.add(
                RULE_DECISION,
                "decision-record ratification states must be uniform and recognized",
                needle="decision_records",
            )
        if self.data.get("versions", {}).get("candidate_status") != expected_candidate_status:
            self.add(
                RULE_DECISION,
                "candidate status does not match decision-record ratification state",
                needle="candidate_status",
            )
        for decision in self.collection(self.data.get("decisions")):
            identifier = str(decision.get("id", ""))
            expected_contract = expected_decision_contracts.get(identifier)
            if expected_contract is None:
                continue
            expected_title, expected_bindings = expected_contract
            if (
                decision.get("title") != expected_title
                or decision.get("state") != expected_decision_state
                or set(self.strings(decision.get("mechanical_bindings"))) != expected_bindings
            ):
                self.add(
                    RULE_DECISION,
                    f"{identifier} title/state/mechanical bindings do not match its approved contract",
                    needle=identifier,
                )
        classified_decisions: set[str] = set()
        ratification_fields = (
            "ratified_by",
            "ratified_on",
            "reviewed_revision",
            "reviewed_blob_oid",
            "reviewed_digest",
            "resulting_blob_oid",
            "resulting_digest",
            "checked_statement",
            "amendments_or_constraints",
            "risk_disposition",
            "ratification_record",
        )
        for decision in decision_records:
            identifier = str(self.first(decision, "source_file", "id", "path") or "<unknown>")
            classification = self.first(decision, "classification", "status")
            if classification not in valid:
                self.add(
                    RULE_DECISION,
                    f"decision {identifier} has invalid classification {classification!r}",
                    needle=identifier,
                )
            if (
                self.mode == "release"
                and isinstance(classification, str)
                and classification.endswith("_candidate")
            ):
                self.add(
                    RULE_DECISION,
                    f"release mode rejects candidate decision classification for {identifier}",
                    needle=identifier,
                )
            if self.mode == "release" and decision.get("ratification_state") == "pending_human":
                self.add(
                    RULE_DECISION,
                    f"release mode rejects pending human ratification for {identifier}",
                    needle=identifier,
                )
            path = self.first(decision, "source_file", "path", "file")
            state = str(decision.get("lifecycle_state", "current"))
            if isinstance(path, str) and state == "current" and not (self.root / path).is_file():
                self.add(
                    RULE_REFERENCE,
                    f"current decision record does not exist: {path}",
                    needle=path,
                )
            source_status = None
            if isinstance(path, str) and (self.root / path).is_file():
                status_match = re.search(
                    r"(?m)^Status:\s*([^\r\n]+?)\s*$",
                    (self.root / path).read_text(encoding="utf-8"),
                )
                source_status = status_match.group(1) if status_match else None
            decision_ids = self.strings(decision.get("decision_ids"))
            if decision_ids:
                ratification_state = decision.get("ratification_state")
                if ratification_state == "ready_for_approval":
                    if source_status != "Ready for Approval":
                        self.add(
                            RULE_DECISION,
                            f"ready decision record {identifier} must have source Status: Ready for Approval",
                            needle=identifier,
                        )
                    if any(decision.get(field) not in (None, "") for field in ratification_fields):
                        self.add(
                            RULE_DECISION,
                            f"unratified decision record {identifier} must not fabricate approval metadata",
                            needle=identifier,
                        )
                    if self.mode == "release":
                        self.add(
                            RULE_DECISION,
                            f"release mode rejects pending human ratification for {identifier}",
                            needle=identifier,
                        )
                elif ratification_state == "accepted":
                    if source_status != "Accepted":
                        self.add(
                            RULE_DECISION,
                            f"ratified decision record {identifier} must have source Status: Accepted",
                            needle=identifier,
                        )
                    missing_metadata = [
                        field
                        for field in ratification_fields
                        if not isinstance(decision.get(field), str)
                        or not str(decision.get(field)).strip()
                        or str(decision.get(field)).strip() == "TBD"
                    ]
                    if missing_metadata:
                        self.add(
                            RULE_DECISION,
                            f"ratified decision record {identifier} lacks metadata: {', '.join(missing_metadata)}",
                            needle=identifier,
                        )
                    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", str(decision.get("ratified_on", ""))):
                        self.add(
                            RULE_DECISION,
                            f"ratified decision record {identifier} needs YYYY-MM-DD ratified_on",
                            needle=identifier,
                        )
                    ratification_record = decision.get("ratification_record")
                    if (
                        not isinstance(ratification_record, str)
                        or not self.is_safe_repository_path(ratification_record)
                        or not (self.root / ratification_record).is_file()
                    ):
                        self.add(
                            RULE_DECISION,
                            f"ratified decision record {identifier} must cite an existing repository ratification record",
                            needle=identifier,
                        )
                    reviewed_revision = decision.get("reviewed_revision")
                    reviewed_blob_oid = decision.get("reviewed_blob_oid")
                    commit = None
                    if isinstance(reviewed_revision, str) and reviewed_revision:
                        resolved_commit = subprocess.run(
                            [
                                "git",
                                "rev-parse",
                                "--verify",
                                f"{reviewed_revision}^{{commit}}",
                            ],
                            cwd=self.root,
                            capture_output=True,
                            text=True,
                            check=False,
                        )
                        if resolved_commit.returncode == 0:
                            commit = resolved_commit.stdout.strip()
                            if reviewed_revision != commit:
                                self.add(
                                    RULE_DECISION,
                                    f"ratified decision record {identifier} reviewed_revision must be the full resolved commit OID",
                                    needle=identifier,
                                )
                    if commit is None:
                        self.add(
                            RULE_DECISION,
                            f"ratified decision record {identifier} reviewed_revision does not resolve",
                            needle=identifier,
                        )
                    elif isinstance(path, str) and self.is_safe_repository_path(path):
                        resolved_blob = subprocess.run(
                            ["git", "rev-parse", "--verify", f"{commit}:{path}"],
                            cwd=self.root,
                            capture_output=True,
                            text=True,
                            check=False,
                        )
                        expected_blob = (
                            resolved_blob.stdout.strip()
                            if resolved_blob.returncode == 0
                            else None
                        )
                        if expected_blob is None or reviewed_blob_oid != expected_blob:
                            self.add(
                                RULE_DECISION,
                                f"ratified decision record {identifier} reviewed_blob_oid does not match the reviewed revision",
                                needle=identifier,
                            )
                        reviewed_content = subprocess.run(
                            ["git", "show", f"{commit}:{path}"],
                            cwd=self.root,
                            capture_output=True,
                            check=False,
                        )
                        if reviewed_content.returncode != 0:
                            self.add(
                                RULE_DECISION,
                                f"ratified decision record {identifier} reviewed source cannot be read",
                                needle=identifier,
                            )
                        else:
                            reviewed_bytes = reviewed_content.stdout
                            reviewed_digest = hashlib.sha256(reviewed_bytes).hexdigest()
                            if decision.get("reviewed_digest") != reviewed_digest:
                                self.add(
                                    RULE_DECISION,
                                    f"ratified decision record {identifier} reviewed_digest is incorrect",
                                    needle=identifier,
                                )
                            status_pattern = re.compile(
                                br"(?m)^Status: Ready for Approval(?P<cr>\r?)$"
                            )
                            if len(status_pattern.findall(reviewed_bytes)) != 1:
                                self.add(
                                    RULE_DECISION,
                                    f"ratified decision record {identifier} reviewed source lacks one canonical Ready for Approval status",
                                    needle=identifier,
                                )
                            else:
                                resulting_bytes = status_pattern.sub(
                                    lambda match: b"Status: Accepted" + match.group("cr"),
                                    reviewed_bytes,
                                    count=1,
                                )
                                resulting_blob = subprocess.run(
                                    ["git", "hash-object", "--stdin"],
                                    cwd=self.root,
                                    input=resulting_bytes,
                                    capture_output=True,
                                    check=False,
                                )
                                resulting_blob_oid = resulting_blob.stdout.decode(
                                    "ascii", errors="replace"
                                ).strip()
                                resulting_digest = hashlib.sha256(resulting_bytes).hexdigest()
                                live_path = self.root / path
                                live_bytes = live_path.read_bytes() if live_path.is_file() else None
                                if live_bytes != resulting_bytes:
                                    self.add(
                                        RULE_DECISION,
                                        f"ratified decision record {identifier} live source is not the exact status-only Accepted result",
                                        needle=identifier,
                                    )
                                if decision.get("resulting_blob_oid") != resulting_blob_oid:
                                    self.add(
                                        RULE_DECISION,
                                        f"ratified decision record {identifier} resulting_blob_oid is incorrect",
                                        needle=identifier,
                                    )
                                if decision.get("resulting_digest") != resulting_digest:
                                    self.add(
                                        RULE_DECISION,
                                        f"ratified decision record {identifier} resulting_digest is incorrect",
                                        needle=identifier,
                                    )
                                live_blob = subprocess.run(
                                    ["git", "hash-object", str(live_path)],
                                    cwd=self.root,
                                    capture_output=True,
                                    text=True,
                                    check=False,
                                )
                                if (
                                    live_blob.returncode != 0
                                    or live_blob.stdout.strip() != resulting_blob_oid
                                ):
                                    self.add(
                                        RULE_DECISION,
                                        f"ratified decision record {identifier} live blob does not match the deterministic result",
                                        needle=identifier,
                                    )
                else:
                    self.add(
                        RULE_DECISION,
                        f"decision record {identifier} has invalid ratification_state {ratification_state!r}",
                        needle=identifier,
                    )
            if classification in {"partially_superseded", "partially_superseded_candidate"}:
                clauses = self.first(decision, "clauses_still_in_force", "active_clauses")
                targets = self.first(
                    decision,
                    "supersession_target",
                    "supersession_targets",
                    "superseded_by",
                )
                if not clauses or not targets:
                    self.add(
                        RULE_DECISION,
                        f"partially superseded decision {identifier} must declare active clauses and targets",
                        needle=identifier,
                    )
            classified_decisions.update(decision_ids)
        if classified_decisions != known_decisions:
            missing = sorted(known_decisions - classified_decisions)
            extra = sorted(classified_decisions - known_decisions)
            self.add(
                RULE_DECISION,
                f"decision-record classification coverage mismatch; missing={missing}, extra={extra}",
                needle="decision_records",
            )

    def check_identifier_grammar(self) -> None:
        identifiers = self.data.get("identifiers", {})
        if not isinstance(identifiers, dict):
            self.add(RULE_TASK_GRAMMAR, "identifiers must be an object", needle="identifiers")
            return
        expected_patterns = {
            "phase_id": r"^[A-Za-z0-9]+(-[A-Za-z0-9]+)*$",
            "workstream": r"^PH-([A-Za-z0-9]+(-[A-Za-z0-9]+)*)-WS([0-9]{2})$",
            "task": r"^PH-([A-Za-z0-9]+(-[A-Za-z0-9]+)*)-T([0-9]{3})$",
            "event_id": r"^EV-[0-9]{8}-[A-Za-z0-9][A-Za-z0-9-]*$",
            "checkpoint": r"^G5(\.0|\.[A-Za-z0-9]+(-[A-Za-z0-9]+)*\.[1-4])$",
        }
        forbidden_ere_tokens = (
            "(?:",
            "(?=",
            "(?!",
            "(?<=",
            "(?<!",
            "(?P",
            r"\d",
            r"\D",
            r"\s",
            r"\S",
            r"\w",
            r"\W",
            r"\A",
            r"\Z",
        )
        for kind, expected_pattern in expected_patterns.items():
            entry = identifiers.get(kind, {})
            pattern = entry.get("pattern") if isinstance(entry, dict) else None
            if pattern != expected_pattern or (
                isinstance(pattern, str)
                and (
                    any(token in pattern for token in forbidden_ere_tokens)
                    or re.search(r"(?:\*|\+|\?|\{[^}]+\})\?", pattern)
                )
            ):
                self.add(
                    RULE_TASK_GRAMMAR,
                    f"{kind} pattern must be the exact Bash/POSIX ERE contract",
                    needle=kind,
                )

        bash_examples = {
            "phase_id": (
                ("1", "10-5", "API-2"),
                ("bad_phase", "-1", "1-"),
            ),
            "workstream": (
                ("PH-1-WS01", "PH-10-5-WS99"),
                ("PH-1-WS1", "PH-bad_phase-WS01", "PH-1-T001"),
            ),
            "task": (
                ("PH-1-T010", "PH-10-5-T020"),
                ("PH-1-T10", "PH-bad_phase-T001", "PH-1-WS01"),
            ),
            "checkpoint": (
                ("G5.0", "G5.1.1", "G5.10-5.4"),
                ("G5.00", "G5.1", "G5.bad_phase.1", "G5.1.5"),
            ),
        }
        for kind, (positive_examples, negative_examples) in bash_examples.items():
            entry = identifiers.get(kind, {})
            pattern = entry.get("pattern") if isinstance(entry, dict) else None
            if not isinstance(pattern, str):
                continue
            for value, should_match in [
                *((example, True) for example in positive_examples),
                *((example, False) for example in negative_examples),
            ]:
                completed = subprocess.run(
                    [
                        "/bin/bash",
                        "-c",
                        'pattern=$1; value=$2; [[ $value =~ $pattern ]]',
                        "_",
                        pattern,
                        value,
                    ],
                    capture_output=True,
                    check=False,
                )
                matched = completed.returncode == 0
                if completed.returncode not in {0, 1} or matched is not should_match:
                    expectation = "match" if should_match else "reject"
                    self.add(
                        RULE_TASK_GRAMMAR,
                        f"{kind} Bash ERE must {expectation} {value!r}",
                        needle=kind,
                    )
        expected_formats = {
            "workstream": "PH-<phase-id>-WS<NN>",
            "task": "PH-<phase-id>-T<NNN>",
        }
        for kind, expected_format in expected_formats.items():
            entry = identifiers.get(kind)
            pattern = entry.get("pattern") if isinstance(entry, dict) else entry
            declared_format = entry.get("format") if isinstance(entry, dict) else None
            if declared_format != expected_format:
                self.add(
                    RULE_TASK_GRAMMAR,
                    f"{kind} format must be {expected_format!r}, not {declared_format!r}",
                    needle=kind,
                )
            if not isinstance(entry, dict) or (
                entry.get("immutable_after_status") != "Accepted"
                or entry.get("reuse_retired_ids") is not False
            ):
                self.add(
                    RULE_TASK_GRAMMAR,
                    f"{kind} IDs must be immutable after Accepted and never reused",
                    needle=kind,
                )
            if not isinstance(pattern, str):
                self.add(RULE_TASK_GRAMMAR, f"{kind} must declare a regular-expression pattern")
                continue
            try:
                compiled = re.compile(pattern)
            except re.error as exc:
                self.add(RULE_TASK_GRAMMAR, f"{kind} grammar is invalid: {exc}", needle=kind)
                continue
            valid_example = "PH-10-5-WS01" if kind == "workstream" else "PH-10-5-T020"
            invalid_examples = ("PH-1-WS1", "PH--1-T001", "PH-1-T01")
            if not compiled.fullmatch(valid_example) or any(
                compiled.fullmatch(example) for example in invalid_examples
            ):
                self.add(
                    RULE_TASK_GRAMMAR,
                    f"{kind} grammar does not satisfy the fixed-width identifier contract",
                    needle=kind,
                )

    def check_generated_contract(self) -> None:
        generated = self.data.get("generation", {})
        if not isinstance(generated, dict):
            self.add(RULE_GENERATED, "generation must be an object")
            return
        output = self.first(generated, "output", "path")
        generator = self.first(generated, "generator", "generator_path")
        if not isinstance(output, str) or not isinstance(generator, str):
            self.add(RULE_GENERATED, "generated contract must declare path and generator")
            return
        if not self.is_safe_repository_path(output) or not self.is_safe_repository_path(generator):
            self.add(
                RULE_GENERATED,
                "generated contract path and generator must be safe repository-relative paths",
            )
            return
        output_path = self.root / output
        generator_path = self.root / generator
        if not output_path.is_file() or not generator_path.is_file():
            self.add(
                RULE_GENERATED,
                f"generated contract inputs are missing: generator={generator}, output={output}",
                needle=output,
            )
            return
        with tempfile.TemporaryDirectory(prefix="lifecycle-contract-") as temp_dir:
            candidate = Path(temp_dir) / "lifecycle-contract.sh"
            command = [
                sys.executable,
                str(generator_path),
                "--registry",
                str(self.registry_path),
                "--output",
                str(candidate),
            ]
            completed = subprocess.run(command, capture_output=True, text=True, check=False)
            if completed.returncode != 0:
                detail = completed.stderr.strip() or completed.stdout.strip() or "no diagnostic"
                self.add(RULE_GENERATED, f"contract generator failed: {detail}", needle=generator)
                return
            try:
                expected_bytes = candidate.read_bytes()
                actual_bytes = output_path.read_bytes()
            except OSError as exc:
                self.add(RULE_GENERATED, f"cannot compare generated contract: {exc}", needle=output)
                return
            if expected_bytes != actual_bytes:
                expected_hash = hashlib.sha256(expected_bytes).hexdigest()[:12]
                actual_hash = hashlib.sha256(actual_bytes).hexdigest()[:12]
                self.add(
                    RULE_GENERATED,
                    f"generated contract is stale (expected sha256 {expected_hash}, found {actual_hash})",
                    file=output_path,
                )
                return
            contract_text = actual_bytes.decode("utf-8", errors="replace")
            runtime_pattern_names = {
                "GENDEV_PHASE_ID_PATTERN": "phase_id",
                "GENDEV_WORKSTREAM_ID_PATTERN": "workstream",
                "GENDEV_TASK_ID_PATTERN": "task",
                "GENDEV_CHECKPOINT_PATTERN": "checkpoint",
            }
            forbidden_runtime_tokens = (
                "(?:",
                "(?=",
                "(?!",
                "(?<=",
                "(?<!",
                "(?P",
                r"\d",
                r"\D",
                r"\s",
                r"\S",
                r"\w",
                r"\W",
                r"\A",
                r"\Z",
            )
            identifier_records = self.data.get("identifiers", {})
            for constant, identifier_key in runtime_pattern_names.items():
                match = re.search(
                    rf"(?m)^readonly {re.escape(constant)}=(.+)$", contract_text
                )
                try:
                    generated_pattern = shlex.split(match.group(1))[0] if match else None
                except (ValueError, IndexError):
                    generated_pattern = None
                registry_record = (
                    identifier_records.get(identifier_key, {})
                    if isinstance(identifier_records, dict)
                    else {}
                )
                registry_pattern = (
                    registry_record.get("pattern")
                    if isinstance(registry_record, dict)
                    else None
                )
                if (
                    generated_pattern != registry_pattern
                    or not isinstance(generated_pattern, str)
                    or any(token in generated_pattern for token in forbidden_runtime_tokens)
                    or re.search(r"(?:\*|\+|\?|\{[^}]+\})\?", generated_pattern)
                ):
                    self.add(
                        RULE_GENERATED,
                        f"{constant} must preserve the registry's Bash/POSIX ERE without Python-only constructs",
                        file=output_path,
                    )
            required_api = {
                "GENDEV_LIFECYCLE_REGISTRY_ID",
                "GENDEV_LIFECYCLE_SCHEMA_VERSION",
                "GENDEV_LIFECYCLE_REGISTRY_STATUS",
                "GENDEV_LIFECYCLE_TARGET_VERSION",
                "GENDEV_LIFECYCLE_REGISTRY_SHA256",
                "GENDEV_GATE_IDS",
                "GENDEV_TERMINAL_GATE",
                "GENDEV_CHECKPOINT_TEMPLATES",
                "GENDEV_EVENT_TYPES",
                "GENDEV_ARTIFACT_IDS",
                "GENDEV_ARTIFACT_STATUSES",
                "GENDEV_GATE_STATUSES",
                "GENDEV_PROJECT_STATUSES",
                "GENDEV_PHASE_LOOP_STATUSES",
                "GENDEV_PHASE_STATUSES",
                "GENDEV_REMEDIATION_DISPOSITIONS",
                "GENDEV_VALUE_REVIEW_DISPOSITIONS",
                "GENDEV_BLAST_RADIUS_CLASSES",
                "GENDEV_EVIDENCE_CATEGORIES",
                "GENDEV_CRITERION_IDS",
                "GENDEV_ROLE_IDS",
                "GENDEV_CANONICAL_DIRECTORIES",
                "GENDEV_FORBIDDEN_DIRECTORIES",
                "GENDEV_REFERENCE_RELATIONSHIPS",
                "GENDEV_DEPLOYMENT_INTENTS",
                "GENDEV_EVENT_BINDING_RULE_IDS",
                "GENDEV_EVENT_CORRECTION_FIELDS",
                "GENDEV_EVENT_REFERENCE_FIELDS",
                "GENDEV_DEPLOYMENT_REQUIRED_ARTIFACTS",
                "GENDEV_DEPLOYMENT_VALUE_PREREQUISITE_FIELDS",
                "GENDEV_REFERENCE_DEFAULT_SUPPORTING_DEPTH",
                "GENDEV_PHASE_ID_PATTERN",
                "GENDEV_WORKSTREAM_ID_PATTERN",
                "GENDEV_TASK_ID_PATTERN",
                "GENDEV_CHECKPOINT_PATTERN",
                "gendev_gate_name",
                "gendev_gate_successor",
                "gendev_gate_role",
                "gendev_gate_primary_artifact",
                "gendev_gate_approval",
                "gendev_gate_criteria",
                "gendev_transition_event_type",
                "gendev_transition_command",
                "gendev_transition_approval",
                "gendev_transition_required_artifacts",
                "gendev_transition_criteria",
                "gendev_transition_required_event_bindings",
                "gendev_transition_required_dynamic_evidence",
                "gendev_transition_specific_event_fields",
                "gendev_transition_resulting_project_status",
                "gendev_transition_approval_profiles",
                "gendev_transition_artifact_requirement_policy",
                "gendev_transition_artifact_requirement_ids",
                "gendev_transition_artifact_reviewed_statuses",
                "gendev_transition_artifact_resulting_statuses",
                "gendev_transition_artifact_evidence_categories",
                "gendev_transition_artifact_required_dispositions",
                "gendev_checkpoint_pattern",
                "gendev_checkpoint_event_type",
                "gendev_checkpoint_approval",
                "gendev_checkpoint_required_artifacts",
                "gendev_checkpoint_required_evidence_classes",
                "gendev_checkpoint_criteria",
                "gendev_checkpoint_required_event_fields",
                "gendev_checkpoint_nullable_event_fields",
                "gendev_checkpoint_required_dynamic_evidence",
                "gendev_checkpoint_artifact_requirement_ids",
                "gendev_checkpoint_reference_artifacts",
                "gendev_checkpoint_artifact_reviewed_statuses",
                "gendev_checkpoint_artifact_resulting_statuses",
                "gendev_checkpoint_artifact_evidence_categories",
                "gendev_checkpoint_artifact_required_dispositions",
                "gendev_checkpoint_reference_allowed_statuses",
                "gendev_checkpoint_reference_required_dispositions",
                "gendev_checkpoint_reference_required_fields",
                "gendev_checkpoint_reference_binding_mode",
                "gendev_checkpoint_reference_parent_artifact",
                "gendev_checkpoint_evidence_artifacts",
                "gendev_checkpoint_evidence_event_fields",
                "gendev_checkpoint_evidence_referenced_artifacts",
                "gendev_checkpoint_evidence_binding_mode",
                "gendev_artifact_path",
                "gendev_artifact_kind",
                "gendev_artifact_template",
                "gendev_artifact_lifecycle_state",
                "gendev_artifact_evidence_class",
                "gendev_artifact_owner_role",
                "gendev_artifact_allowed_statuses",
                "gendev_event_required_fields",
                "gendev_event_conditional_fields",
                "gendev_evidence_reviewed_status",
                "gendev_evidence_resulting_status",
                "gendev_artifact_status_is_valid",
                "gendev_deployment_artifact_reviewed_statuses",
                "gendev_deployment_artifact_resulting_statuses",
                "gendev_deployment_artifact_evidence_categories",
                "gendev_deployment_artifact_required_dispositions",
                "gendev_event_binding_event_types",
                "gendev_event_binding_allowed_intents",
                "gendev_event_binding_allowed_decisions",
                "gendev_event_binding_quantifier",
                "gendev_event_binding_position_pattern",
                "gendev_event_binding_evidence_category",
                "gendev_event_binding_coverage_source",
                "gendev_event_binding_major_gate",
                "gendev_event_binding_required_flags",
                "gendev_reference_target_scope",
                "gendev_reference_authority_direction",
                "gendev_scaling_requirements_form",
                "gendev_scaling_gate_combination",
                "gendev_scaling_g2_required_all",
                "gendev_scaling_g2_required_any",
            }
            required_api.update(
                """GENDEV_APPROVAL_DECISIONS GENDEV_VALUE_RESULTS
                GENDEV_ENFORCEMENT_CLASSES
                GENDEV_VALUE_REVIEW_ARTIFACT_STATUS_IS_SEPARATE_FROM_DISPOSITION
                GENDEV_VALUE_REVIEW_UNOWNED_FUTURE_WORK_IS_INVALID
                GENDEV_VALUE_REVIEW_UNMEASURABLE_IS_NOT_SUCCESS
                GENDEV_APPROVAL_POLICY_IDS GENDEV_EVENT_HISTORY_ENFORCEMENT_BEHAVIORS
                GENDEV_EVENT_REFERENCE_DIGEST_ALGORITHM
                GENDEV_EVENT_REFERENCE_CANNOT_SATISFY_ACCEPTANCE
                GENDEV_EVENT_EVIDENCE_FIELDS GENDEV_EVENT_EVIDENCE_CONDITIONS
                GENDEV_EVENT_SERIALIZATION_PROFILE
                GENDEV_EVENT_SERIALIZATION_SCHEMA_VERSION GENDEV_EVENT_FIELD_IDS
                GENDEV_EVENT_RECORD_CONTRACT_IDS
                GENDEV_EVENT_COMMON_CONDITIONAL_PROFILES
                GENDEV_EVENT_DEFAULT_SCALAR_VALUE_CONTRACT
                GENDEV_DEPLOYMENT_CRITERION_IDS GENDEV_DEPLOYMENT_VALUE_CONTRACT
                GENDEV_DEPLOYMENT_AUTHORIZATION_EVENT
                GENDEV_DEPLOYMENT_TERMINAL_TRANSITION
                GENDEV_DEPLOYMENT_NONDEPLOYMENT_REQUIRED_FIELDS
                GENDEV_COMBINED_GATE_REQUIRED_FIELDS GENDEV_COVERAGE_REQUIRED_FIELDS
                GENDEV_COVERAGE_UNIVERSAL_PERCENTAGE
                GENDEV_COVERAGE_SHORTFALL_REQUIRES_NAMED_RISK_ACCEPTANCE
                GENDEV_MANIFEST_REQUIRED_FIELDS GENDEV_MANIFEST_INVARIANT_IDS
                GENDEV_MANIFEST_SCHEMA_VERSION GENDEV_MANIFEST_SOURCE_FILE
                GENDEV_MANIFEST_CONTRACT_STATE GENDEV_MANIFEST_REQUIRED_WORK_PACKAGE
                GENDEV_REFERENCE_DEPTH_EXCEPTION_FIELDS
                GENDEV_REFERENCE_RULE_IDS GENDEV_REFERENCE_ENFORCEMENT_REQUIRED_RULE_IDS
                GENDEV_RATIFICATION_REVIEWED_STATUS GENDEV_RATIFICATION_RESULTING_STATUS
                GENDEV_RATIFICATION_EVIDENCE_CATEGORY GENDEV_EVENT_ID_PATTERN
                GENDEV_TASK_IMMUTABLE_AFTER_STATUS GENDEV_TASK_REUSE_RETIRED_IDS
                GENDEV_WORKSTREAM_IMMUTABLE_AFTER_STATUS
                GENDEV_WORKSTREAM_REUSE_RETIRED_IDS
                GENDEV_COMPATIBILITY_NEW_PROJECT_MODE GENDEV_COMPATIBILITY_LEGACY_MODE
                GENDEV_COMPATIBILITY_LEGACY_EVENT_POLICY
                GENDEV_COMPATIBILITY_NEW_EVENTS_IN_LEGACY_MODE
                GENDEV_COMPATIBILITY_AUTOMATIC_GATE_REGRESSION
                GENDEV_COMPATIBILITY_SCAFFOLD_FRESH_INIT
                GENDEV_COMPATIBILITY_SCAFFOLD_PHASE_COMMAND
                GENDEV_COMPATIBILITY_SCAFFOLD_STATE
                GENDEV_COMPATIBILITY_SCAFFOLD_REQUIRED_WORK_PACKAGE
                GENDEV_COMPATIBILITY_SCAFFOLD_SEED_PHASE_OPTION
                GENDEV_COMPATIBILITY_SCAFFOLD_SEED_PHASE_MUST_BE_COMPLETE
                GENDEV_MIGRATION_ALLOWED_DECISIONS GENDEV_MIGRATION_REFERENCE_KINDS
                GENDEV_MIGRATION_REFERENCE_DIGEST_ALGORITHM
                GENDEV_MIGRATION_LINE_NUMBER_ONLY_FORBIDDEN
                GENDEV_MIGRATION_NAMED_HUMAN_REQUIRED_WHEN
                GENDEV_MIGRATION_CRITICAL_UNCERTAINTY_WAIVABLE
                GENDEV_MIGRATION_AUTOMATION_MAY_APPROVE
                GENDEV_MIGRATION_UNRESOLVED_FIELDS_PROPAGATE_TO_READINESS
                GENDEV_MIGRATION_DUPLICATE_MAPPING_REQUIRES_SUPERSEDES
                GENDEV_DEPLOYMENT_PRODUCTION_ACTION_AUTOMATIC
                GENDEV_DEPLOYMENT_VALUE_MUST_BE_COMPLETE_BEFORE_AUTHORIZATION
                GENDEV_DEPLOYMENT_INTENT_MUST_MATCH_TERMINAL_DISPOSITION
                gendev_approval_string gendev_approval_boolean gendev_approval_fields
                gendev_approval_approver_kind gendev_combined_gate_rule
                gendev_event_evidence_conditional_fields
                gendev_event_evidence_revision_string
                gendev_event_evidence_revision_boolean gendev_event_history_string
                gendev_event_field_shape gendev_event_field_item_contract
                gendev_event_field_min_items gendev_event_field_value_contract
                gendev_event_common_conditional_fields
                gendev_event_record_required_fields gendev_event_record_field_ids
                gendev_event_record_conditional_profiles
                gendev_event_record_conditional_fields
                gendev_event_record_field_shape
                gendev_event_record_field_item_contract
                gendev_event_record_field_min_items
                gendev_event_record_field_value_contract
                gendev_event_record_conditional_profile_selector
                gendev_event_record_conditional_profile_for_value
                gendev_migration_reference_required_fields
                gendev_event_history_boolean gendev_event_history_enforcement_string
                gendev_reference_depth_rule gendev_manifest_field_contract_state
                gendev_manifest_field_required_work_package
                gendev_manifest_invariant_string gendev_manifest_invariant_boolean
                gendev_deployment_path_string gendev_deployment_path_boolean
                gendev_deployment_path_fields
                gendev_transition_conditional_event_profiles
                gendev_transition_conditional_event_fields
                gendev_transition_resulting_role gendev_transition_boolean
                gendev_transition_named_human_condition
                gendev_transition_artifact_disposition_contract
                gendev_checkpoint_order gendev_checkpoint_active_major_gate
                gendev_checkpoint_resulting_role
                gendev_checkpoint_reference_statuses_for_disposition
                gendev_checkpoint_artifact_disposition_contract
                gendev_checkpoint_reference_disposition_contract
                gendev_artifact_path_kind gendev_artifact_template_state
                gendev_artifact_identity_contract_state
                gendev_artifact_lifecycle_bindings gendev_artifact_required_work_package
                gendev_artifact_project_identity_required
                gendev_artifact_provenance_required gendev_value_review_required_fields
                gendev_event_conditional_profiles gendev_event_schema_version
                gendev_event_append_only gendev_event_changes_major_gate
                gendev_value_review_allowed_results
                gendev_value_review_follow_up_required_for
                gendev_value_review_item_contract
                gendev_deployment_terminal_disposition
                gendev_deployment_production_action_performed
                gendev_role_kind gendev_role_may_approve
                gendev_event_binding_criterion_source
                gendev_event_binding_terminal_correlation
                gendev_reference_rule
                gendev_reference_identity_contract gendev_reference_form_contract
                gendev_reference_lifecycle_owner gendev_reference_cycle_policy
                gendev_reference_depth_policy gendev_reference_validation_severity
                gendev_scaling_label gendev_scaling_design_interrogation
                gendev_scaling_unwanted_behavior_required
                gendev_scaling_verification_spec_required
                gendev_scaling_phase_exit_evidence_waivable""".split()
            )
            defined_api = set(
                re.findall(r"(?m)^readonly (GENDEV_[A-Z0-9_]+)=", contract_text)
            ) | set(re.findall(r"(?m)^(gendev_[a-z0-9_]+)\(\) \{$", contract_text))
            missing_api = sorted(required_api - defined_api)
            if missing_api:
                self.add(
                    RULE_GENERATED,
                    f"generated lifecycle runtime API is incomplete: {', '.join(missing_api)}",
                    file=output_path,
                )


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, help="repository root (default: parent of scripts)")
    parser.add_argument("--registry", type=Path, help="registry JSON path")
    parser.add_argument("--format", choices=("human", "json"), default="human")
    parser.add_argument(
        "--mode",
        choices=("candidate", "release"),
        default="candidate",
        help="candidate permits explicitly planned delivery; release requires it delivered",
    )
    return parser.parse_args(argv)


def strict_object_pairs(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise RegistryError(f"duplicate JSON object key: {key}")
        result[key] = value
    return result


def reject_nonfinite_constant(token: str) -> Any:
    raise RegistryError(f"non-finite JSON number is forbidden: {token}")


def load_registry(path: Path) -> dict[str, Any]:
    try:
        with path.open(encoding="utf-8") as handle:
            value = json.load(
                handle,
                object_pairs_hook=strict_object_pairs,
                parse_constant=reject_nonfinite_constant,
            )
    except FileNotFoundError as exc:
        raise RegistryError(f"registry does not exist: {path}") from exc
    except PermissionError as exc:
        raise RegistryError(f"registry is not readable: {path}") from exc
    except json.JSONDecodeError as exc:
        raise RegistryError(f"invalid JSON in {path}:{exc.lineno}:{exc.colno}: {exc.msg}") from exc
    except UnicodeError as exc:
        raise RegistryError(f"registry is not valid UTF-8: {path}: {exc}") from exc
    except OSError as exc:
        raise RegistryError(f"cannot read registry {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise RegistryError("registry root must be a JSON object")
    return value


def emit_findings(findings: Iterable[Finding], output_format: str, mode: str) -> None:
    materialized = list(findings)
    if output_format == "json":
        print(
            json.dumps(
                {
                    "status": "clean" if not materialized else "findings",
                    "mode": mode,
                    "finding_count": len(materialized),
                    "findings": [finding.json_value() for finding in materialized],
                },
                indent=2,
                sort_keys=True,
            )
        )
        return
    if not materialized:
        print(f"Lifecycle coherence: clean ({mode} mode)")
        return
    print(f"Lifecycle coherence: {len(materialized)} finding(s) ({mode} mode)")
    for finding in materialized:
        location = finding.file + (f":{finding.line}" if finding.line is not None else "")
        print(f"{finding.severity.upper()} [{finding.rule_id}] {location}: {finding.message}")


def emit_config_error(message: str, output_format: str, mode: str) -> None:
    if output_format == "json":
        print(
            json.dumps(
                {
                    "status": "error",
                    "mode": mode,
                    "error": {"kind": "configuration", "message": message},
                },
                indent=2,
                sort_keys=True,
            )
        )
    else:
        print(f"Lifecycle coherence configuration error: {message}", file=sys.stderr)


INSTALLED_CONTEXT_EXIT = 4


def refuse_in_installed_context(repo_root: str, mode: str) -> None:
    """Release-mode coherence belongs to the methodology authority repository.

    An installed product repository carries the registry as frozen provenance,
    not live release state; asking release-coherence questions there produces
    false findings by construction.
    """
    if mode != "release":
        return
    record = os.path.join(
        repo_root, "docs", "methodology", "schema", "installation.json"
    )
    if os.path.exists(record):
        print(
            "check-lifecycle-coherence.py --mode release: not applicable in an "
            "installed product repository; this check belongs to the "
            "methodology authority repository.",
            file=sys.stderr,
        )
        raise SystemExit(INSTALLED_CONTEXT_EXIT)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    default_root = Path(__file__).resolve().parent.parent
    root = (args.root or default_root).resolve()
    registry_path = args.registry or root / "docs/methodology/schema/lifecycle.json"
    if not registry_path.is_absolute():
        registry_path = (root / registry_path).resolve()
    if not root.is_dir():
        emit_config_error(f"repository root is not a directory: {root}", args.format, args.mode)
        return 2
    refuse_in_installed_context(str(root), args.mode)
    try:
        data = load_registry(registry_path)
        findings = Validator(root, registry_path, data, args.mode).run()
    except (RegistryError, UnicodeError, OSError) as exc:
        emit_config_error(str(exc), args.format, args.mode)
        return 2
    emit_findings(findings, args.format, args.mode)
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
