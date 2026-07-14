#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
helpers="$script_dir/lib/test-helpers.sh"
runtime_write_fixtures="$script_dir/lib/runtime-write-fixtures.sh"

. "$helpers"

th_set_suite "runtime-tools"
th_set_keep_on_failure "${TH_KEEP_ON_FAILURE:-0}"
th_require_compatible_bash

if [ -n "${GENDEV_TEST_TMPDIR:-}" ]; then
  work_parent="$GENDEV_TEST_TMPDIR"
elif [ -n "${TH_WORKDIR:-}" ]; then
  work_parent="$TH_WORKDIR"
else
  work_parent="$repo_root/.tmp"
  trap 'rm -rf "$work_parent"' EXIT INT TERM
fi
work_root="$work_parent/methodology-runtime-tools-$(date +%s)-$$"
if [ -z "$work_root" ] || [ "$work_root" = "" ]; then
  th_init_suite
else
  TH_WORKDIR="$work_root"
  rm -rf "$TH_WORKDIR"
  th_init_suite "$TH_WORKDIR"
fi

trap th_cleanup EXIT

base_repo="$TH_WORKDIR/source"
th_temp_copy "$repo_root" "$base_repo"
rm -rf "$base_repo/.tmp"

fixture_root="$TH_WORKDIR/project fixture"
th_temp_copy "$base_repo" "$fixture_root"

th_run_case "RT-001" 0 "init-project displays usage" \
  "cd '$fixture_root' && ./scripts/init-project.sh --help" \
  '^Usage:'

th_run_case "RT-002" 2 "init-project rejects missing project name" \
  "cd '$fixture_root' && ./scripts/init-project.sh" \
  'Usage:'

th_run_case "RT-003" 1 "init-project rejects duplicate init when docs/project exists" \
  "cd '$fixture_root' && ./scripts/init-project.sh 'Runtime Fixtures' >/dev/null && ./scripts/init-project.sh 'Runtime Fixtures'" \
  'docs/project already exists'

th_run_case "RT-004" 0 "close-gate shows usage" \
  "cd '$fixture_root' && ./scripts/close-gate.sh --help" \
  'Usage:'

th_run_case "RT-005" 2 "close-gate requires supported document gate" \
  "cd '$fixture_root' && ./scripts/close-gate.sh G9" \
  'G9 is terminal'

th_run_case "RT-006" 0 "methodology-guard shows usage" \
  "cd '$fixture_root' && ./scripts/methodology-guard.sh --help" \
  'Usage:'

th_run_case "RT-007" 2 "methodology-guard --range requires base/head" \
  "cd '$fixture_root' && ./scripts/methodology-guard.sh --range" \
  'Usage:'

th_run_case "RT-008" 1 "close-gate fails without initialized project" \
  "mkdir -p '$fixture_root/no-project'; cd '$fixture_root/no-project'; ../scripts/close-gate.sh G1" \
  'Required file missing'

th_run_case "RT-009" 0 "record-phase-checkpoint shows usage" \
  "cd '$fixture_root' && ./scripts/record-phase-checkpoint.sh --help" \
  '^Usage:'

th_run_case "RT-010" 0 "close-phase shows usage" \
  "cd '$fixture_root' && ./scripts/close-phase.sh --help" \
  '^Usage:'

th_run_case "RT-011" 0 "record-deployment-approval shows usage" \
  "cd '$fixture_root' && ./scripts/record-deployment-approval.sh --help" \
  '^Usage:'

th_run_case "RT-012" 0 "record-phase-checkpoint dry-run does not mutate gate" \
  "cd '$fixture_root' && printf 'decided_by=Runtime Tester\nchecked_statement=Runtime dry-run accepted\nreviewed_revision=WORKTREE\n' > answers.env && perl -0pi -e 's/current_gate: G1/current_gate: G5/; s/gate: G1/gate: G5/' docs/project/project.yaml && ./scripts/record-phase-checkpoint.sh --dry-run --answers-file answers.env G5.0" \
  'DRY RUN: would record phase checkpoint G5.0'

th_run_case "RT-013" 0 "close-phase dry-run validates G5 command surface" \
  "cd '$fixture_root' && printf 'decided_by=Runtime Tester\nchecked_statement=Runtime phase close dry-run accepted\nreviewed_revision=WORKTREE\n' > answers.env && perl -0pi -e 's/current_gate: G1/current_gate: G5/; s/gate: G1/gate: G5/' docs/project/project.yaml && ./scripts/close-phase.sh --dry-run --answers-file answers.env 1" \
  'DRY RUN: would close phase 1 at G5.1.4'

th_run_case "RT-014" 0 "record-deployment-approval dry-run validates G8 command surface" \
  "cd '$fixture_root' && mkdir -p docs/project/deployment && printf '# Deployment Readiness\n\nStatus: Ready for Approval\nproject: runtime-fixtures\n' > docs/project/deployment/deployment-readiness.md && printf 'decided_by=Runtime Tester\nchecked_statement=Runtime deployment dry-run accepted\nreviewed_revision=WORKTREE\n' > answers.env && perl -0pi -e 's/current_gate: G[0-9]/current_gate: G8/; s/gate: G[0-9]/gate: G8/' docs/project/project.yaml && ./scripts/record-deployment-approval.sh --dry-run --answers-file answers.env" \
  'DRY RUN: would record deployment_approval at G8 without changing project.current_gate'

th_run_case "RT-015" 0 "record-phase-checkpoint write-mode updates phase state and log" \
  "case_dir='$TH_WORKDIR/phase-checkpoint-write'; rm -rf \"\$case_dir\"; cp -R '$base_repo/.' \"\$case_dir\"; cd \"\$case_dir\" && ./scripts/init-project.sh 'Runtime Fixtures' >/dev/null && . '$runtime_write_fixtures' && rtw_prepare_g5_checkpoint_fixture && rtw_git_baseline && ./scripts/record-phase-checkpoint.sh --answers-file answers.env G5.0 && grep -q '^  phase_position: G5.0' docs/project/project.yaml && grep -q 'event_type: phase_checkpoint' docs/project/approvals/gate-log.md" \
  'Recorded phase checkpoint G5.0'

th_run_case "RT-016" 0 "close-phase write-mode records phase exit" \
  "case_dir='$TH_WORKDIR/phase-exit-write'; rm -rf \"\$case_dir\"; cp -R '$base_repo/.' \"\$case_dir\"; cd \"\$case_dir\" && ./scripts/init-project.sh 'Runtime Fixtures' >/dev/null && . '$runtime_write_fixtures' && rtw_prepare_g5_phase_exit_fixture && rtw_git_baseline && ./scripts/close-phase.sh --answers-file answers.env 1 && grep -q '^  phase_position: G5.1.4' docs/project/project.yaml && grep -q 'status: exited' docs/project/project.yaml && grep -q 'event_type: phase_transition' docs/project/approvals/gate-log.md" \
  'Closed phase 1 at G5.1.4'

th_run_case "RT-017" 0 "record-deployment-approval write-mode accepts readiness without changing gate" \
  "case_dir='$TH_WORKDIR/deployment-approval-write'; rm -rf \"\$case_dir\"; cp -R '$base_repo/.' \"\$case_dir\"; cd \"\$case_dir\" && ./scripts/init-project.sh 'Runtime Fixtures' >/dev/null && . '$runtime_write_fixtures' && rtw_prepare_g8_deployment_fixture && rtw_git_baseline && ./scripts/record-deployment-approval.sh --answers-file answers.env && grep -q '^Status: Accepted' docs/project/deployment/deployment-readiness.md && grep -q '^  current_gate: G8' docs/project/project.yaml && grep -q 'event_type: deployment_approval' docs/project/approvals/gate-log.md && grep -q 'production_action_performed: false' docs/project/approvals/gate-log.md" \
  'Recorded deployment_approval at G8'

th_run_case "RT-018" 0 "close-gate write-mode records G1 to G2 transition" \
  "case_dir='$TH_WORKDIR/close-gate-g1-write'; rm -rf \"\$case_dir\"; cp -R '$base_repo/.' \"\$case_dir\"; cd \"\$case_dir\" && ./scripts/init-project.sh 'Runtime Fixtures' >/dev/null && . '$runtime_write_fixtures' && rtw_prepare_g1_close_fixture && rtw_git_baseline && ./scripts/close-gate.sh --answers-file answers.env G1 && grep -q '^Status: Accepted' docs/project/vision/vision.md && grep -q '^  current_gate: G2' docs/project/project.yaml && grep -q 'event_type: gate_transition' docs/project/approvals/gate-log.md && grep -q 'from_gate: G1' docs/project/approvals/gate-log.md && grep -q 'to_gate: G2' docs/project/approvals/gate-log.md" \
  'G1 closed to G2'

th_run_case "RT-019" 1 "close-gate write-mode rejects missing reviewed revision" \
  "case_dir='$TH_WORKDIR/close-gate-missing-reviewed-revision'; rm -rf \"\$case_dir\"; cp -R '$base_repo/.' \"\$case_dir\"; cd \"\$case_dir\" && ./scripts/init-project.sh 'Runtime Fixtures' >/dev/null && . '$runtime_write_fixtures' && rtw_prepare_g1_close_fixture && grep -v '^reviewed_revision=' answers.env > answers.tmp && mv answers.tmp answers.env && ./scripts/close-gate.sh --answers-file answers.env G1" \
  'reviewed_revision is required'

th_run_case "RT-020" 1 "close-gate write-mode rejects reviewed blob mismatch" \
  "case_dir='$TH_WORKDIR/close-gate-reviewed-blob-mismatch'; rm -rf \"\$case_dir\"; cp -R '$base_repo/.' \"\$case_dir\"; cd \"\$case_dir\" && ./scripts/init-project.sh 'Runtime Fixtures' >/dev/null && . '$runtime_write_fixtures' && rtw_prepare_g1_close_fixture && rtw_git_baseline && printf '\nUnreviewed mutation.\n' >> docs/project/vision/vision.md && ./scripts/close-gate.sh --answers-file answers.env G1" \
  'does not match current pre-transition artifact'

th_run_case "RT-021" 1 "close-gate write-mode rejects already accepted source artifact" \
  "case_dir='$TH_WORKDIR/close-gate-already-accepted'; rm -rf \"\$case_dir\"; cp -R '$base_repo/.' \"\$case_dir\"; cd \"\$case_dir\" && ./scripts/init-project.sh 'Runtime Fixtures' >/dev/null && . '$runtime_write_fixtures' && rtw_prepare_g1_close_fixture && perl -0pi -e 's/^Status: Ready for Approval/Status: Accepted/m' docs/project/vision/vision.md && rtw_git_baseline && ./scripts/close-gate.sh --answers-file answers.env G1" \
  'must be Ready for Approval'

th_run_case "RT-022" 1 "close-gate write-mode rolls back when postcheck fails" \
  "case_dir='$TH_WORKDIR/close-gate-postcheck-rollback'; rm -rf \"\$case_dir\"; cp -R '$base_repo/.' \"\$case_dir\"; cd \"\$case_dir\" && ./scripts/init-project.sh 'Runtime Fixtures' >/dev/null && . '$runtime_write_fixtures' && rtw_prepare_g1_close_fixture && rtw_git_baseline && perl -0pi -e 's/^    required_attester: Runtime Tester/    required_attester: TBD/m' docs/project/project.yaml && ./scripts/close-gate.sh --answers-file answers.env G1; rc=\$?; grep -q '^Status: Ready for Approval' docs/project/vision/vision.md && ! grep -q 'from_gate: G1' docs/project/approvals/gate-log.md && exit \$rc" \
  'Methodology check failed'

th_run_case "RT-023" 0 "close-gate write-mode records terminal G8 to G9 closeout" \
  "case_dir='$TH_WORKDIR/close-gate-g8-terminal'; rm -rf \"\$case_dir\"; cp -R '$base_repo/.' \"\$case_dir\"; cd \"\$case_dir\" && ./scripts/init-project.sh 'Runtime Fixtures' >/dev/null && . '$runtime_write_fixtures' && rtw_prepare_g8_terminal_fixture && rtw_git_baseline && ./scripts/close-gate.sh --answers-file answers.env G8 && grep -q '^  current_gate: G9' docs/project/project.yaml && grep -q '^  status: closed' docs/project/project.yaml && grep -q '^  active_role: none' docs/project/project.yaml && grep -q 'terminal_closeout: true' docs/project/approvals/gate-log.md && grep -q 'status: Complete' docs/project/approvals/gate-log.md" \
  'G8 closed to G9'

th_summary

exit $(( TH_CASE_FAIL > 0 ))
