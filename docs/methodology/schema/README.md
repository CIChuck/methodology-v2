# GenDev Lifecycle Registry

Status: Release-mode production registry; publication pending
Schema version: 2
Target release: `1.0.1`
Registry: `docs/methodology/schema/lifecycle.json`

## Purpose

The lifecycle registry is the machine-readable source for GenDev enumerations and bindings that
must remain identical across checkers, transition commands, templates, and human guidance. It
defines mechanically determinate data; it does not replace the methodology's normative prose.

The registry exists to prevent each shell command from carrying a separate copy of gate names,
status values, paths, event types, and phase rules. Installed shell commands consume the generated
contract at `scripts/lib/lifecycle-contract.sh`. They do not parse JSON and do not require Python at
runtime.

## Authority And Precedence

Authority is divided as follows:

1. `docs/methodology/constitution/gendev.md` states constitutional requirements and delegates the
   major gate enumeration to the canonical lifecycle model.
2. `docs/methodology/guides/gates.md` is the normative human explanation of lifecycle purposes,
   entry criteria, exit criteria, and stop conditions.
3. `docs/methodology/schema/lifecycle.json` owns mechanically determinate IDs, vocabularies, paths,
   patterns, and bindings delegated by those documents.
4. `scripts/lib/lifecycle-contract.sh` is generated output. It has no independent authority and
   must always match the registry byte-for-byte through deterministic regeneration.

When prose and registry data conflict, stop. Do not select whichever version lets work proceed.
Resolve the conflict under the amendment and regression protocol, update the authority and registry
in the same reviewed change, regenerate the shell contract, and rerun coherence validation.

## Candidate And Release Modes

The registry supports two validation modes:

- candidate mode, used only while a future release target is being assembled and
  still has explicit planned work; and
- release mode, used for the published production methodology.

The live 1.0 registry is release-mode metadata for a production candidate. It
means the registry contains no planned delivery markers. It does not, by
itself, mean that the publication tag has been created.

Delivery markers use these values:

| Field | Values | Meaning |
| --- | --- | --- |
| `lifecycle_state` | `current`, `planned` | Whether an artifact contract is delivered now or by a named work package. |
| `template_state` | `current`, `planned` | Whether the template file exists in the baseline. |
| `identity_contract_state` | `current`, `planned` | Whether the template currently satisfies the required `project:` identity contract. |
| `delivery_state` | `current`, `planned` | Whether a canonical scaffold directory is created by current initialization. |
| `contract_state` | `current`, `planned` | Whether a composite contract, such as the schema-v2 manifest, is fully delivered. |
| `ratification_state` | `ready_for_approval`, `accepted` | Whether a delivered candidate decision record awaits exact-revision ratification or has a complete ratification record. |
| `enforcement_state` / `state` | `current`, `planned` | Whether a declared target rule already has its owning enforcement implementation. |
| `required_work_package` | work-package ID | The approved package that must convert a planned declaration to current. |

Candidate validation requires all `current` files and contracts and permits only explicitly marked
`planned` target work owned by a valid `required_work_package`. Release validation rejects every
remaining `planned` marker. A missing file without an explicit planned declaration and work-package
owner is always a finding.

The live registry metadata is:

```text
registry.status: released
registry.target_release: 1.0.1
versions.candidate_status: released
versions.released_current: 1.0.1
versions.release_stage: production
versions.publication_status: pending_publication
```

The historical baseline split remains recorded separately at revision
`02ae0fc192a898cd482007dfc65612ff907a3bda`:

```text
README.md                                                0.1.0-baseline
docs/methodology/constitution/gendev.md                  0.1.0-baseline
docs/project-template/project.yaml                       0.4.0-verification-first
observed published tag                                   v0.1.0-baseline
```

Recording those claims is evidence, not endorsement. Release validation treats
them as preserved historical observations and requires `registry.status:
released`, both `released_current` fields equal to the active release target,
and every synchronization target's `release_value_pattern` to match its live
file.

## Registry Shape

The top-level members have stable responsibilities:

| Member | Responsibility |
| --- | --- |
| `schema_version` | Registry shape version. Version 2 is the strict operational-coherence model. |
| `registry` | Candidate/release identity, authority pointers, generator, and output path. |
| `versions` | Candidate identity, observed claims, synchronization targets, and publication rules. |
| `vocabularies` | Artifact, gate, project, phase, approval, remediation, value, and enforcement values. |
| `value_review_contract` | Disposition-specific fields, result values, and follow-up rules shared by phase, deployment, and terminal value evidence. |
| `ratification_contract` | Exact reviewed/status-only-result fields for accepting the two candidate decision records. |
| `paths` | Canonical directories, fixed paths, phase patterns, supporting-design path, and delivery state. |
| `roles` | Authoring, review, operations, closeout, named-human approval, and terminal roles. |
| `gates` | G0-G9 names, purposes, adjacent state, primary artifact, active role, approval, and criteria. |
| `criteria` | Stable criterion IDs and their gate-scoped meanings. |
| `transitions` | Legal major transitions, command, event, evidence, resulting state, and approval rule. |
| `checkpoints` | G5.0 and G5 phase-position grammar, order, role, event, approval, and evidence-class-to-artifact/event-field bindings. |
| `evidence_categories` | The three reviewed/resulting byte-binding categories from D-012. |
| `events` | Append-only schema-v2 event kinds and required fields. |
| `event_history` | Correction/supersession fields, duplicate-latest rejection, and append-only invariants. |
| `event_binding_rules` | Machine predicates for phase-exit coverage, reused authority, and deployment authorization. |
| `event_reference_item` | Pinned non-acceptance references that cannot substitute for a D-012 evidence item. |
| `event_evidence_item` | Per-artifact revision, blob, digest, status, and category contract. |
| `event_serialization` | Restricted-YAML top-level field shapes, scalar value contracts, common correction profile, nested record keys, conditional selectors, and list cardinality. |
| `approval_policy` | Named-human, delegation, risk, deployment, and closeout approval boundaries. |
| `deployment` | Deployment and explicit non-deployment authorization and terminal-path rules. |
| `artifacts` | Canonical artifacts, patterns, templates, owners, statuses, evidence classes, and delivery state. |
| `manifest` | Required control-plane fields and cross-field invariants. |
| `identifiers` | Phase, checkpoint, workstream, task, and event identifier grammar. |
| `references` | Typed relationship and target-kind vocabulary plus path/direction/cycle rules. |
| `scaling` | C1/C2/C3 combination, criteria-form, verification, phase-exit, and coverage rules. |
| `naa` | Authority-bearing NAA boundary and the bounded private implementation exception. |
| `compatibility` | Strict-new-project, legacy migration, and just-in-time phase-scaffold rules. |
| `decisions` | D-001 through D-018 and the registry sections that encode each decision. |
| `decision_records` | Active, partially superseded, candidate, and historical design-decision classifications. |
| `document_sweep` | Active, example, historical, research, and design-decision sweep classifications. |
| `generation` | Generator/output paths, portability target, dependency policy, and forbidden shell features. |

## Lifecycle Axes

The registry keeps major gate and phase position separate:

```text
project.current_gate   G0 through G9
phase.phase_position   null, G5.0, or G5.<phase-id>.1 through .4
```

`G4 -> G5` enters phase planning. The `G5.0` checkpoint accepts the phase plan and authorizes the
phase loop without changing `project.current_gate`. All phase checkpoints leave the major gate at
G5. The one `G5 -> G6` transition occurs only after every declared phase has a valid exit and the
aggregate integration and regression contract is satisfied or validly dispositioned.

The terminal major transition is `G8 -> G9`. G9 has no successor, uses role `none`, and requires
project status `closed`. Continued work begins through governed amendment/regression or a new
project/product cycle; no consumer may invent G10.

## Approval And Evidence

An Accepted artifact in strict mode requires a complete append-only event. The manifest's
`approvals.latest_decision` is a summary only. Event evidence binds the reviewed revision and path,
reviewed Git blob OID, portable SHA-256 digest, resulting blob/digest, status, and exactly one of:

```text
new_acceptance_status_only
complete_report_unchanged
accepted_authority_unchanged
```

The status-only category permits exactly one canonical header change from `Ready for Approval` to
`Accepted`; every other byte and the line-ending convention stay unchanged. Complete reports are
never rewritten during approval. Reused Accepted authority also cites its originating approval
event.

Every checkpoint declares `artifact_requirements`, `reference_requirements`, and
`required_evidence` bindings. D-012 evidence items state reviewed/resulting status and category;
pinned Draft or otherwise non-acceptance inputs use `event_reference_item` and cannot satisfy an
approval by themselves. Each evidence class binds concrete artifact IDs and event fields. Every G5
checkpoint/exit acceptance uses a named human, while remaining interior to major gate G5. The Draft
`not_due` phase value record is a subordinate pinned reference in the Complete phase as-built item,
not a fourth D-012 category. C1 and C2 may combine document form, but they cannot waive an evidence
class. C3 gate combination is prohibited. Agents, models, automation identities, and unbound role
labels cannot approve a phase exit, implementation acceptance, deployment, risk acceptance, or
project closeout.

The shared value contract is conditional by disposition. `complete` records due
criteria, evidence, `met|missed|unmeasurable` results, and follow-up decisions
for missed or unmeasurable outcomes. `not_due` records trigger, expected date
when knowable, owner, evidence source, and next-review mechanism.
`not_applicable` records rationale plus named-human acceptance and date. Phase
exit, G8 deployment authorization, and G8-to-G9 closeout all reference this one
contract. Deployment authorization intent must also match the terminal
deployment disposition and whether a production action occurred.

Schema 2 preserves the active event IDs `gate_transition`, `phase_checkpoint`,
`phase_transition`, `traceability_sample`, `amendment`, `gate_regression`, `reconciliation`,
`enforcement_attestation`, and `enforcement_override`. It adds `project_initialization`,
`deployment_approval`, and the migration-specific `migration_reconciliation`; ordinary amendment
reconciliation and migration mapping are not aliases. Corrections append a new event with
`supersedes_event_id` and `correction_reason`. Duplicate unsuperseded latest decisions and
supersession cycles are invalid. The current gate-log template projection is explicitly planned for
WP-04, while append-only/correction/latest/cycle parser enforcement is separately
planned for WP-05. Both contracts name their enforcer and verification suite and
block release until those files and rule bindings are delivered.

Schema 2 also fixes the restricted serialization shape. Every required, event-conditional, or
common correction field is classified as a scalar, scalar list, record, or record list. Scalar
fields carry a default or field-specific value contract. Nested records declare their complete key
set, conditional-profile selector, value mapping, field shape, nested item contract, and non-empty
cardinality where evidence is mandatory. Test commands and results are paired records; Complete
value reviews use one keyed result record per criterion, with non-empty evidence and a required
follow-up decision for `missed` or `unmeasurable`. Consumers must use these declarations rather
than infer YAML shapes or maintain a second event table.

D-012 applies to every artifact evidence item. Administrative decisions such as
gate regression and enforcement override do not imply artifact acceptance, but
their schema still requires decision authority, checked statement, risk,
enforcement context, and next state. Migration reconciliation accepts only a
stable event ID or SHA-256-bound source reference; line-number-only provenance
and waiving critical security/approval uncertainty are forbidden.

## Artifact References

Every typed reference declares one target kind:

- `canonical_artifact` points to registered canonical authority or evidence; the registered
  artifact kind determines authority direction; and
- `supporting_design` points below `docs/project/design/` and can support but never govern canonical
  authority.

`docs/project/supporting/` is forbidden because it would create a competing supporting-artifact
location. The active relationship vocabulary remains `implements`, `satisfies`, `tested-by`,
`constrained-by`, and `refines`. Supporting references are depth one by default; a deeper graph
requires a declared, justified, named-human-approved exception. The registry contains the target
rules now, while graph enforcement remains explicitly planned for WP-05 and blocks release until
delivered.

## Generator

Regenerate the contract from the repository root:

```bash
python3 scripts/generate-lifecycle-contract.py
```

Verify freshness without writing:

```bash
python3 scripts/generate-lifecycle-contract.py --check
```

Mutation tests and external checks can use isolated paths:

```bash
python3 scripts/generate-lifecycle-contract.py \
  --registry /tmp/lifecycle.json \
  --output /tmp/lifecycle-contract.sh
python3 scripts/generate-lifecycle-contract.py \
  --registry /tmp/lifecycle.json \
  --output /tmp/lifecycle-contract.sh \
  --check
```

Exit codes are:

| Code | Meaning |
| --- | --- |
| `0` | Generation succeeded, or `--check` found byte-identical output. |
| `1` | `--check` found missing or stale generated output. |
| `2` | Invocation, read, parse, registry-shape, or write failure. |

Generation is deterministic. The output contains no timestamp or host path and embeds the SHA-256
of the exact registry bytes. The generator writes atomically and assigns executable mode. Never edit
`scripts/lib/lifecycle-contract.sh` directly.

Python 3 standard library is a baseline-maintenance dependency only. Installed transition commands
source the generated Bash file and require no Python or JSON parser.

## Generated Shell API

The generated file uses no arrays, associative arrays, `mapfile`, process substitution, or other
syntax unavailable in macOS Bash 3.2. It exports read-only scalar constants and read-only lookup
behavior through functions.

The generated constants are:

```text
GENDEV_LIFECYCLE_SCHEMA_VERSION
GENDEV_LIFECYCLE_REGISTRY_ID
GENDEV_LIFECYCLE_REGISTRY_STATUS
GENDEV_LIFECYCLE_TARGET_VERSION
GENDEV_LIFECYCLE_REGISTRY_SHA256
GENDEV_LIFECYCLE_CONTRACT_LOADED
GENDEV_GATE_IDS
GENDEV_TERMINAL_GATE
GENDEV_CHECKPOINT_TEMPLATES
GENDEV_EVENT_TYPES
GENDEV_ARTIFACT_IDS
GENDEV_ARTIFACT_STATUSES
GENDEV_GATE_STATUSES
GENDEV_PROJECT_STATUSES
GENDEV_PHASE_LOOP_STATUSES
GENDEV_PHASE_STATUSES
GENDEV_APPROVAL_DECISIONS
GENDEV_REMEDIATION_DISPOSITIONS
GENDEV_VALUE_REVIEW_DISPOSITIONS
GENDEV_VALUE_RESULTS
GENDEV_ENFORCEMENT_CLASSES
GENDEV_VALUE_REVIEW_ARTIFACT_STATUS_IS_SEPARATE_FROM_DISPOSITION
GENDEV_VALUE_REVIEW_UNOWNED_FUTURE_WORK_IS_INVALID
GENDEV_VALUE_REVIEW_UNMEASURABLE_IS_NOT_SUCCESS
GENDEV_BLAST_RADIUS_CLASSES
GENDEV_EVIDENCE_CATEGORIES
GENDEV_CRITERION_IDS
GENDEV_ROLE_IDS
GENDEV_CANONICAL_DIRECTORIES
GENDEV_FORBIDDEN_DIRECTORIES
GENDEV_REFERENCE_RELATIONSHIPS
GENDEV_DEPLOYMENT_INTENTS
GENDEV_APPROVAL_POLICY_IDS
GENDEV_DEPLOYMENT_REQUIRED_ARTIFACTS
GENDEV_DEPLOYMENT_CRITERION_IDS
GENDEV_DEPLOYMENT_VALUE_PREREQUISITE_FIELDS
GENDEV_DEPLOYMENT_VALUE_CONTRACT
GENDEV_DEPLOYMENT_NONDEPLOYMENT_REQUIRED_FIELDS
GENDEV_DEPLOYMENT_AUTHORIZATION_EVENT
GENDEV_DEPLOYMENT_TERMINAL_TRANSITION
GENDEV_DEPLOYMENT_PRODUCTION_ACTION_AUTOMATIC
GENDEV_DEPLOYMENT_VALUE_MUST_BE_COMPLETE_BEFORE_AUTHORIZATION
GENDEV_DEPLOYMENT_INTENT_MUST_MATCH_TERMINAL_DISPOSITION
GENDEV_RATIFICATION_REVIEWED_STATUS
GENDEV_RATIFICATION_RESULTING_STATUS
GENDEV_RATIFICATION_EVIDENCE_CATEGORY
GENDEV_EVENT_BINDING_RULE_IDS
GENDEV_EVENT_CORRECTION_FIELDS
GENDEV_EVENT_HISTORY_ENFORCEMENT_BEHAVIORS
GENDEV_EVENT_REFERENCE_FIELDS
GENDEV_EVENT_REFERENCE_DIGEST_ALGORITHM
GENDEV_EVENT_REFERENCE_CANNOT_SATISFY_ACCEPTANCE
GENDEV_EVENT_EVIDENCE_FIELDS
GENDEV_EVENT_EVIDENCE_CONDITIONS
GENDEV_EVENT_SERIALIZATION_PROFILE
GENDEV_EVENT_SERIALIZATION_SCHEMA_VERSION
GENDEV_EVENT_FIELD_IDS
GENDEV_EVENT_RECORD_CONTRACT_IDS
GENDEV_EVENT_COMMON_CONDITIONAL_PROFILES
GENDEV_EVENT_DEFAULT_SCALAR_VALUE_CONTRACT
GENDEV_COMBINED_GATE_REQUIRED_FIELDS
GENDEV_COVERAGE_REQUIRED_FIELDS
GENDEV_COVERAGE_UNIVERSAL_PERCENTAGE
GENDEV_COVERAGE_SHORTFALL_REQUIRES_NAMED_RISK_ACCEPTANCE
GENDEV_MANIFEST_REQUIRED_FIELDS
GENDEV_MANIFEST_INVARIANT_IDS
GENDEV_MANIFEST_SCHEMA_VERSION
GENDEV_MANIFEST_SOURCE_FILE
GENDEV_MANIFEST_CONTRACT_STATE
GENDEV_MANIFEST_REQUIRED_WORK_PACKAGE
GENDEV_REFERENCE_DEFAULT_SUPPORTING_DEPTH
GENDEV_REFERENCE_DEPTH_EXCEPTION_FIELDS
GENDEV_REFERENCE_RULE_IDS
GENDEV_REFERENCE_ENFORCEMENT_REQUIRED_RULE_IDS
GENDEV_PHASE_ID_PATTERN
GENDEV_TASK_ID_PATTERN
GENDEV_WORKSTREAM_ID_PATTERN
GENDEV_CHECKPOINT_PATTERN
GENDEV_EVENT_ID_PATTERN
GENDEV_TASK_IMMUTABLE_AFTER_STATUS
GENDEV_TASK_REUSE_RETIRED_IDS
GENDEV_WORKSTREAM_IMMUTABLE_AFTER_STATUS
GENDEV_WORKSTREAM_REUSE_RETIRED_IDS
GENDEV_COMPATIBILITY_NEW_PROJECT_MODE
GENDEV_COMPATIBILITY_LEGACY_MODE
GENDEV_COMPATIBILITY_LEGACY_EVENT_POLICY
GENDEV_COMPATIBILITY_NEW_EVENTS_IN_LEGACY_MODE
GENDEV_COMPATIBILITY_AUTOMATIC_GATE_REGRESSION
GENDEV_COMPATIBILITY_SCAFFOLD_FRESH_INIT
GENDEV_COMPATIBILITY_SCAFFOLD_PHASE_COMMAND
GENDEV_COMPATIBILITY_SCAFFOLD_STATE
GENDEV_COMPATIBILITY_SCAFFOLD_REQUIRED_WORK_PACKAGE
GENDEV_COMPATIBILITY_SCAFFOLD_SEED_PHASE_OPTION
GENDEV_COMPATIBILITY_SCAFFOLD_SEED_PHASE_MUST_BE_COMPLETE
GENDEV_MIGRATION_ALLOWED_DECISIONS
GENDEV_MIGRATION_REFERENCE_KINDS
GENDEV_MIGRATION_REFERENCE_DIGEST_ALGORITHM
GENDEV_MIGRATION_LINE_NUMBER_ONLY_FORBIDDEN
GENDEV_MIGRATION_NAMED_HUMAN_REQUIRED_WHEN
GENDEV_MIGRATION_CRITICAL_UNCERTAINTY_WAIVABLE
GENDEV_MIGRATION_AUTOMATION_MAY_APPROVE
GENDEV_MIGRATION_UNRESOLVED_FIELDS_PROPAGATE_TO_READINESS
GENDEV_MIGRATION_DUPLICATE_MAPPING_REQUIRES_SUPERSEDES
```

Artifact status values contain spaces and are therefore pipe-delimited in
`GENDEV_ARTIFACT_STATUSES`. Use `gendev_artifact_status_is_valid` for validation rather than
splitting that constant.

Lookup functions return `0` and print the value for a known key, return `1` for an unknown key, and
return `2` for the wrong number of arguments. The API includes:

```text
gendev_list_contains
gendev_approval_string
gendev_approval_boolean
gendev_approval_fields
gendev_approval_approver_kind
gendev_combined_gate_rule
gendev_event_evidence_conditional_fields
gendev_event_evidence_revision_string
gendev_event_evidence_revision_boolean
gendev_event_field_shape
gendev_event_field_item_contract
gendev_event_field_min_items
gendev_event_field_value_contract
gendev_event_common_conditional_fields
gendev_event_record_required_fields
gendev_event_record_field_ids
gendev_event_record_conditional_profiles
gendev_event_record_conditional_fields
gendev_event_record_field_shape
gendev_event_record_field_item_contract
gendev_event_record_field_min_items
gendev_event_record_field_value_contract
gendev_event_record_conditional_profile_selector
gendev_event_record_conditional_profile_for_value
gendev_migration_reference_required_fields
gendev_event_history_string
gendev_event_history_boolean
gendev_event_history_enforcement_string
gendev_reference_depth_rule
gendev_manifest_field_contract_state
gendev_manifest_field_required_work_package
gendev_manifest_invariant_string
gendev_manifest_invariant_boolean
gendev_deployment_path_string
gendev_deployment_path_boolean
gendev_deployment_path_fields
gendev_role_kind
gendev_role_may_approve
gendev_gate_name
gendev_gate_successor
gendev_gate_role
gendev_gate_primary_artifact
gendev_gate_approval
gendev_gate_criteria
gendev_transition_event_type
gendev_transition_command
gendev_transition_approval
gendev_transition_required_artifacts
gendev_transition_required_event_bindings
gendev_transition_required_dynamic_evidence
gendev_transition_specific_event_fields
gendev_transition_conditional_event_profiles
gendev_transition_conditional_event_fields
gendev_transition_resulting_project_status
gendev_transition_resulting_role
gendev_transition_boolean
gendev_transition_approval_profiles
gendev_transition_named_human_condition
gendev_transition_artifact_requirement_policy
gendev_transition_artifact_requirement_ids
gendev_transition_criteria
gendev_transition_artifact_reviewed_statuses
gendev_transition_artifact_resulting_statuses
gendev_transition_artifact_evidence_categories
gendev_transition_artifact_required_dispositions
gendev_transition_artifact_disposition_contract
gendev_checkpoint_pattern
gendev_checkpoint_event_type
gendev_checkpoint_approval
gendev_checkpoint_order
gendev_checkpoint_active_major_gate
gendev_checkpoint_resulting_role
gendev_checkpoint_required_artifacts
gendev_checkpoint_required_evidence_classes
gendev_checkpoint_required_event_fields
gendev_checkpoint_nullable_event_fields
gendev_checkpoint_required_dynamic_evidence
gendev_checkpoint_artifact_requirement_ids
gendev_checkpoint_reference_artifacts
gendev_checkpoint_criteria
gendev_checkpoint_artifact_reviewed_statuses
gendev_checkpoint_artifact_resulting_statuses
gendev_checkpoint_artifact_evidence_categories
gendev_checkpoint_artifact_required_dispositions
gendev_checkpoint_artifact_disposition_contract
gendev_checkpoint_reference_allowed_statuses
gendev_checkpoint_reference_required_dispositions
gendev_checkpoint_reference_required_fields
gendev_checkpoint_reference_statuses_for_disposition
gendev_checkpoint_reference_binding_mode
gendev_checkpoint_reference_parent_artifact
gendev_checkpoint_reference_disposition_contract
gendev_checkpoint_evidence_artifacts
gendev_checkpoint_evidence_event_fields
gendev_checkpoint_evidence_referenced_artifacts
gendev_checkpoint_evidence_binding_mode
gendev_artifact_path
gendev_artifact_path_kind
gendev_artifact_kind
gendev_artifact_template
gendev_artifact_template_state
gendev_artifact_lifecycle_state
gendev_artifact_evidence_class
gendev_artifact_owner_role
gendev_artifact_identity_contract_state
gendev_artifact_allowed_statuses
gendev_artifact_lifecycle_bindings
gendev_artifact_required_work_package
gendev_artifact_project_identity_required
gendev_artifact_provenance_required
gendev_artifact_status_is_valid
gendev_event_required_fields
gendev_event_conditional_profiles
gendev_event_conditional_fields
gendev_event_schema_version
gendev_event_append_only
gendev_event_changes_major_gate
gendev_evidence_reviewed_status
gendev_evidence_resulting_status
gendev_deployment_artifact_reviewed_statuses
gendev_deployment_artifact_resulting_statuses
gendev_deployment_artifact_evidence_categories
gendev_deployment_artifact_required_dispositions
gendev_value_review_required_fields
gendev_value_review_allowed_results
gendev_value_review_follow_up_required_for
gendev_value_review_item_contract
gendev_deployment_terminal_disposition
gendev_deployment_production_action_performed
gendev_event_binding_event_types
gendev_event_binding_allowed_intents
gendev_event_binding_allowed_decisions
gendev_event_binding_quantifier
gendev_event_binding_position_pattern
gendev_event_binding_evidence_category
gendev_event_binding_coverage_source
gendev_event_binding_major_gate
gendev_event_binding_criterion_source
gendev_event_binding_terminal_correlation
gendev_event_binding_required_flags
gendev_reference_target_scope
gendev_reference_rule
gendev_reference_authority_direction
gendev_reference_identity_contract
gendev_reference_form_contract
gendev_reference_lifecycle_owner
gendev_reference_cycle_policy
gendev_reference_depth_policy
gendev_reference_validation_severity
gendev_scaling_requirements_form
gendev_scaling_gate_combination
gendev_scaling_label
gendev_scaling_design_interrogation
gendev_scaling_unwanted_behavior_required
gendev_scaling_verification_spec_required
gendev_scaling_phase_exit_evidence_waivable
gendev_scaling_g2_required_all
gendev_scaling_g2_required_any
```

Checkpoint lookup functions take the template ID, such as `G5.<id>.4`. Consumers validate a
concrete position against the returned registry pattern and bind the captured phase ID to a declared
manifest phase. Transition artifact lookups take source gate, target gate, and artifact ID;
checkpoint artifact, reference, and evidence lookups take checkpoint template ID plus artifact or
evidence-class ID. These accessors expose status, category, disposition, predicate, and reference
bindings without downstream shell scripts carrying a second lifecycle table.

Phase value-reference status is correlated with disposition, not validated as two independent
lists: `complete` and `not_applicable` require `Complete`, while `not_due` requires `Draft`. A due
review therefore cannot pass phase exit as a Draft reference. Delegated C1/C2 phase-exit approval
is serialized as the `phase_transition` event's `delegation` field under the
`delegated_phase_exit` profile; the same contract prohibits delegation for C3.

Deployment approval serializes the non-deployment rationale, scope, candidate, approver, date, and
future trigger/finality under the `non_deployment` event profile. Terminal G8-to-G9 fields are
owned by the transition contract, with `operational_owner_confirmation` required only by the
`deploy` conditional profile. These conditional bindings keep deployment authorization intent,
terminal disposition, and actual production action mechanically correlated.

## Change Procedure

A registry change is incomplete until all of these steps pass:

1. Identify the constitutional, guide, or accepted decision authority for the change.
2. Update the registry without rewriting historical release evidence.
3. Mark undelivered target files or contracts `planned` with `required_work_package`; never suppress
   a missing current requirement.
4. Regenerate `scripts/lib/lifecycle-contract.sh`.
5. Run JSON parsing, the lifecycle coherence validator in the applicable mode, generator freshness,
   Bash syntax validation, and registry negative tests.
6. Reconcile affected human guidance, templates, roles, and examples in the work package that owns
   those surfaces.
7. Obtain the approval required by the authority change before presenting a candidate rule as
   accepted or released.

Minimum commands during WP-01 are:

```bash
python3 -m json.tool docs/methodology/schema/lifecycle.json >/dev/null
python3 scripts/check-lifecycle-coherence.py --mode candidate
python3 scripts/generate-lifecycle-contract.py --check
/bin/bash -n scripts/lib/lifecycle-contract.sh
bash tests/methodology/test-lifecycle-coherence.sh
```

Release preparation additionally runs the coherence validator in release mode. Any `planned`
delivery or contract marker blocks release.
