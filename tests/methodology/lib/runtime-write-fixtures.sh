#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

rtw_answers() {
  cat > answers.env <<'EOF'
decided_by=Runtime Tester
decided_on=2026-07-10
checked_statement=Runtime write-mode transition accepted
risk_disposition=none
open_questions=none
reviewed_revision=WORKTREE
EOF
}

rtw_git_baseline() {
  rm -rf .tmp
  git init -q
  git config user.name "Runtime Tester"
  git config user.email "runtime@example.invalid"
  git add -f .
  git commit -qm "runtime transition baseline"
  revision="$(git rev-parse HEAD)"
  if grep -q '^reviewed_revision=' answers.env; then
    perl -0pi -e "s/^reviewed_revision=.*/reviewed_revision=${revision}/m" answers.env
  else
    printf 'reviewed_revision=%s\n' "$revision" >> answers.env
  fi
}

rtw_set_gate() {
  gate="$1"
  perl -0pi -e "s/^  current_gate: G[0-9]/  current_gate: ${gate}/m; s/^    gate: G[0-9]/    gate: ${gate}/m" \
    docs/project/project.yaml
}

rtw_set_enforcement_ready() {
  mkdir -p src
  perl -0pi -e 's/  implementation_paths:\n    - TBD/  implementation_paths:\n    - src/m; s/^    required_attester: TBD/    required_attester: Runtime Tester/m' \
    docs/project/project.yaml
}

rtw_set_methodology_current() {
  perl -0pi -e 's/^  methodology_version:.*/  methodology_version: 1.0.2/m' \
    docs/project/project.yaml
}

rtw_set_phase_state() {
  position="$1"
  status="$2"
  perl -0pi -e "s/^  phase_position: .*/  phase_position: ${position}/m; s/^  phases: \\[\\]/  phases:\\n    - id: 1\\n      status: ${status}/m; s/^    - id: 1\\n      status: [A-Za-z_]+/    - id: 1\\n      status: ${status}/m" \
    docs/project/project.yaml
}

rtw_write_status_artifact() {
  path="$1"
  status="$2"
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<EOF
# Runtime Fixture Artifact

Status: ${status}
project: runtime-fixtures
Date: 2026-07-10
Owner: Runtime Tester
Produced by: runtime-fixture
Produced on: 2026-07-10
Produced with: runtime fixture
Agent identity: runtime-fixture
Derived from:
  - path: docs/project/vision/vision.md
    revision: 0000000

Runtime fixture content complete.
EOF
}

rtw_write_ready_vision() {
  mkdir -p docs/project/vision
  cat > docs/project/vision/vision.md <<'EOF'
# Vision: Runtime Fixtures

Status: Ready for Approval
project: runtime-fixtures
Date: 2026-07-10
Owner: Runtime Tester
Produced by: runtime-fixture
Produced on: 2026-07-10
Produced with: runtime fixture
Agent identity: runtime-fixture
Derived from:
  - path: docs/project/project.yaml
    revision: 0000000

## Product Vision

Runtime fixture vision content is complete and bounded.

## Success Criteria

| Criterion | Measure | Target | Read Timing | Owner | Evidence Source |
| --- | --- | --- | --- | --- | --- |
| Runtime transition | command status | pass | immediate | Runtime Tester | runtime suite |

## Out of Scope

No production behavior is exercised by this fixture.
EOF
}

rtw_refresh_terminal_provenance() {
  for path in \
    docs/project/testing/final-test-uat-report.md \
    docs/project/testing/phase-1-test-uat-plan.md \
    docs/project/traceability/traceability-matrix.md \
    docs/project/as-built/as-built-closeout.md \
    docs/project/as-built/phase-1-as-built-closeout.md \
    docs/project/build-plan/implementation-summary.md \
    docs/project/build-plan/phases/phase-1-code-review.md \
    docs/project/build-plan/phases/phase-1-implementation-evidence.md \
    docs/project/build-plan/phases/phase-1-learnings.md \
    docs/project/build-plan/phases/phase-1-remediation.md \
    docs/project/deployment/deployment-readiness.md \
    docs/project/deployment/production-runbook.md \
    docs/project/deployment/deployment-record.md \
    docs/project/review/code-review.md \
    docs/project/review/remediation.md; do
    [ -f "$path" ] || continue
    perl -0pi -e 's/revision: 0000000/revision: N\/A/g' "$path"
  done

  perl -0pi -e 's/revision: 0000000/revision: N\/A/g' \
    docs/project/as-built/value-review.md
}

rtw_phase_exit_artifacts() {
  rtw_write_status_artifact docs/project/build-plan/phases/phase-1-implementation-evidence.md Complete
  rtw_write_status_artifact docs/project/testing/phase-1-test-uat-plan.md Accepted
  rtw_write_status_artifact docs/project/build-plan/phases/phase-1-code-review.md Complete
  rtw_write_status_artifact docs/project/build-plan/phases/phase-1-remediation.md Complete
  rtw_write_status_artifact docs/project/traceability/traceability-matrix.md Complete
  rtw_write_status_artifact docs/project/as-built/phase-1-as-built-closeout.md Complete
  rtw_write_status_artifact docs/project/build-plan/phases/phase-1-learnings.md Accepted
}

rtw_late_gate_artifacts() {
  rtw_phase_exit_artifacts
  rtw_write_status_artifact docs/project/build-plan/implementation-summary.md Complete
  rtw_write_status_artifact docs/project/review/code-review.md Complete
  rtw_write_status_artifact docs/project/review/remediation.md Complete
  rtw_write_status_artifact docs/project/testing/final-test-uat-report.md Complete
  rtw_write_status_artifact docs/project/deployment/deployment-readiness.md "Ready for Approval"
  rtw_write_status_artifact docs/project/deployment/production-runbook.md Complete
}

rtw_append_phase_exit_event() {
  cat >> docs/project/approvals/gate-log.md <<'EOF'

### Phase Transition: G5.1.4

```yaml
event_id: EV-runtime-phase-1-exit
schema_version: 2
event_type: phase_transition
position: G5.1.4
phase_id: "1"
decision: exited
decided_by: Runtime Tester
decided_on: 2026-07-10
status: exited
checked: "Runtime Tester accepted phase exit evidence."
exit_test:
  path: docs/project/testing/phase-1-test-uat-plan.md
  result: passed
regression_suite:
  result: green
learnings: docs/project/build-plan/phases/phase-1-learnings.md
```
EOF
}

rtw_append_g7_to_g8_event() {
  cat >> docs/project/approvals/gate-log.md <<'EOF'

### Gate Event: G7 -> G8

```yaml
event_id: EV-runtime-g7-g8
schema_version: 2
event_type: gate_transition
from_gate: G7
to_gate: G8
decision: approved
decided_by: Runtime Tester
decided_on: 2026-07-10
status: approved
checked: "Runtime Tester accepted implementation for deployment readiness."
evidence:
  - artifact_id: final_code_review
    artifact_path: docs/project/review/code-review.md
    category: new_acceptance_status_only
    reviewed_revision: 0000000
    reviewed_blob_oid: 1111111111111111111111111111111111111111
    reviewed_digest: 1111111111111111111111111111111111111111111111111111111111111111
    resulting_blob_oid: 2222222222222222222222222222222222222222
    resulting_digest: 2222222222222222222222222222222222222222222222222222222222222222
    status: Accepted
verification_evidence:
  - command: ./scripts/check-methodology.sh
    result: passed
```
EOF
}

rtw_append_g8_deployment_approval_event() {
  cat >> docs/project/approvals/gate-log.md <<'EOF'

### Deployment Approval: G8

```yaml
event_id: EV-runtime-g8-deployment-approval
schema_version: 2
event_type: deployment_approval
gate: G8
decision: approved
approved_by: Runtime Tester
approved_on: 2026-07-10
status: approved
checked: "Runtime Tester accepted deployment readiness."
deployment_disposition: approved
production_action_performed: false
evidence:
  - artifact_id: deployment_readiness
    artifact_path: docs/project/deployment/deployment-readiness.md
    category: new_acceptance_status_only
    reviewed_revision: 0000000
    reviewed_blob_oid: 1111111111111111111111111111111111111111
    reviewed_digest: 1111111111111111111111111111111111111111111111111111111111111111
    resulting_blob_oid: 2222222222222222222222222222222222222222
    resulting_digest: 2222222222222222222222222222222222222222222222222222222222222222
    status: Accepted
```
EOF
}

rtw_append_g4_to_g5_event() {
  cat >> docs/project/approvals/gate-log.md <<'EOF'

### Gate Event: G4 -> G5

```yaml
event_id: EV-runtime-g4-g5
schema_version: 2
event_type: gate_transition
from_gate: G4
to_gate: G5
decision: approved
decided_by: Runtime Tester
decided_on: 2026-07-10
status: approved
checked: "Runtime Tester accepted build planning entry."
evidence:
  - artifact_id: governance_security
    artifact_path: docs/project/security-governance/governance-security-spec.md
    category: new_acceptance_status_only
    reviewed_revision: 0000000
    reviewed_blob_oid: 1111111111111111111111111111111111111111
    reviewed_digest: 1111111111111111111111111111111111111111111111111111111111111111
    resulting_blob_oid: 2222222222222222222222222222222222222222
    resulting_digest: 2222222222222222222222222222222222222222222222222222222222222222
    status: Accepted
verification_evidence:
  - command: ./scripts/check-methodology.sh
    result: passed
```
EOF
}

rtw_prepare_g5_checkpoint_fixture() {
  rtw_set_gate G5
  rtw_set_enforcement_ready
  rtw_set_phase_state null pending
  rtw_answers
}

rtw_prepare_g1_close_fixture() {
  rtw_set_gate G1
  rtw_set_enforcement_ready
  rtw_write_ready_vision
  rtw_answers
}

rtw_prepare_g5_phase_exit_fixture() {
  rtw_set_gate G5
  rtw_set_enforcement_ready
  rtw_set_phase_state G5.1.3 in_progress
  rtw_phase_exit_artifacts
  rtw_append_g4_to_g5_event
  rtw_answers
}

rtw_prepare_g8_deployment_fixture() {
  rtw_set_gate G8
  rtw_set_enforcement_ready
  rtw_set_phase_state G5.1.4 exited
  rtw_late_gate_artifacts
  rtw_append_phase_exit_event
  rtw_append_g7_to_g8_event
  rtw_answers
}

rtw_prepare_g8_terminal_fixture() {
  rtw_set_gate G8
  rtw_set_enforcement_ready
  rtw_set_methodology_current
  rtw_set_phase_state G5.1.4 exited
  rtw_late_gate_artifacts
  rtw_write_status_artifact docs/project/deployment/deployment-readiness.md Accepted
  rtw_write_status_artifact docs/project/deployment/deployment-record.md Complete
  rtw_write_status_artifact docs/project/as-built/as-built-closeout.md Complete
  mkdir -p docs/project/as-built
  cat > docs/project/as-built/value-review.md <<'EOF'
# Project Value Review

Status: Complete
project: runtime-fixtures
Date: 2026-07-10
Owner: Runtime Tester
Produced by: runtime-fixture
Produced on: 2026-07-10
Produced with: runtime fixture
Agent identity: runtime-fixture
Derived from:
  - path: docs/project/deployment/deployment-record.md
    revision: 0000000
value_review.disposition: complete
value_review.details: Runtime value review completed.

Runtime fixture value-review content is complete.
EOF
  rtw_append_phase_exit_event
  rtw_append_g7_to_g8_event
  rtw_append_g8_deployment_approval_event
  rtw_refresh_terminal_provenance
  rtw_answers
}
