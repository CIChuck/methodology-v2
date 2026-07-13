#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
test_dir="$repo_root/tests/methodology"

print_usage() {
  cat <<'USAGE'
Usage:
  ./scripts/test-methodology.sh
  ./scripts/test-methodology.sh --suite <name|all>
  ./scripts/test-methodology.sh --list
  ./scripts/test-methodology.sh --platform-summary
  ./scripts/test-methodology.sh --keep-on-failure

Options:
  --suite <name|all>         Run one suite or all suites.
  --list                     Show available suite names.
  --platform-summary         Print host platform summary.
  --keep-on-failure          Keep temporary fixtures when any case fails.
USAGE
}

platform_summary() {
  printf 'Platform summary:\n'
  printf '  uname: %s\n' "$(uname -a)"
  printf '  pwd:   %s\n' "$(pwd)"
  if command -v bash >/dev/null 2>&1; then
    printf '  bash:  %s\n' "$(command -v bash)"
  fi
  if command -v git >/dev/null 2>&1; then
    printf '  git:   %s\n' "$(command -v git)"
  fi
  if command -v python3 >/dev/null 2>&1; then
    printf '  python:%s\n' "$(command -v python3)"
  fi
  printf '\n'
}

run_suite() {
  local suite_name="$1"
  local suite_script=""

  case "$suite_name" in
    checker)
      suite_script="$test_dir/test-checker.sh"
      ;;
    shell-syntax)
      suite_script="$test_dir/test-shell-syntax.sh"
      ;;
    lifecycle)
      suite_script="$test_dir/test-lifecycle-coherence.sh"
      ;;
    runtime-tools)
      suite_script="$test_dir/test-runtime-tools.sh"
      ;;
    distribution-tools)
      suite_script="$test_dir/test-distribution-tools.sh"
      ;;
    enforcement-tools)
      suite_script="$test_dir/test-enforcement-tools.sh"
      ;;
    reference-graph)
      suite_script="$test_dir/test-reference-graph.sh"
      ;;
    documentation-coherence)
      suite_script="$test_dir/test-documentation-coherence.sh"
      ;;
    metrics)
      suite_script="$test_dir/test-metrics.sh"
      ;;
    examples)
      suite_script="$test_dir/test-examples.sh"
      ;;
    migration)
      suite_script="$test_dir/test-migration.sh"
      ;;
    release-coherence)
      suite_script="$test_dir/test-release-coherence.sh"
      ;;
    *)
      printf 'ERROR: unknown suite: %s\n' "$suite_name" >&2
      return 1
      ;;
  esac

  if [ ! -f "$suite_script" ]; then
    printf 'ERROR: suite script missing: %s\n' "$suite_script" >&2
    return 1
  fi

  printf '\n=== Running suite: %s ===\n' "$suite_name"
  printf 'Command shell: %s\n' "$(command -v bash)"

  if [ "${KEEP_ON_FAILURE}" -eq 1 ]; then
    TH_KEEP_ON_FAILURE=1
    export TH_KEEP_ON_FAILURE
  else
    export TH_KEEP_ON_FAILURE=0
  fi
  export TH_COMMAND_SHELL

  "$suite_script"
}

available_suites="shell-syntax checker lifecycle runtime-tools distribution-tools enforcement-tools reference-graph documentation-coherence metrics examples migration release-coherence"

SELECTED="all"
LIST_ONLY=0
PLATFORM_SUMMARY=0
KEEP_ON_FAILURE=0
TH_COMMAND_SHELL="${TH_COMMAND_SHELL:-/bin/bash}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --suite)
      if [ "$#" -lt 2 ]; then
        print_usage
        exit 2
      fi
      SELECTED="$2"
      shift 2
      ;;
    --list)
      LIST_ONLY=1
      shift
      ;;
    --platform-summary)
      PLATFORM_SUMMARY=1
      shift
      ;;
    --keep-on-failure)
      KEEP_ON_FAILURE=1
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      print_usage
      exit 2
      ;;
  esac
done

if [ "$PLATFORM_SUMMARY" -eq 1 ]; then
  platform_summary
fi

if [ "$LIST_ONLY" -eq 1 ]; then
  printf 'Available suites: %s\n' "$available_suites"
  exit 0
fi

if [ "$SELECTED" = "all" ]; then
  selected_list="$available_suites"
else
  selected_list="$SELECTED"
fi

# Installed-context restriction: in a product repository, only the
# shell-syntax suite is applicable. The remaining suites validate methodology
# internals and assume the authority repository; running them here produces
# false failures by construction. --suite all narrows to the applicable set;
# an explicit request for an inapplicable suite refuses with exit 4.
installed_safe_suites="shell-syntax"
if [ -f "$repo_root/docs/methodology/schema/installation.json" ]; then
  if [ "$SELECTED" = "all" ]; then
    printf 'Installed product repository detected: restricting suites to: %s\n' "$installed_safe_suites"
    selected_list="$installed_safe_suites"
  else
    for suite in $selected_list; do
      case " $installed_safe_suites " in
        *" $suite "*) ;;
        *)
          printf 'test-methodology.sh: suite %s is not applicable in an installed product repository; applicable suites: %s\n' "$suite" "$installed_safe_suites" >&2
          exit 4
          ;;
      esac
    done
  fi
fi

failed=0

for suite in $selected_list; do
  if ! run_suite "$suite"; then
    failed=1
  fi
done

if [ "$failed" -eq 0 ]; then
  printf '\nAll selected suites completed successfully.\n'
  exit 0
fi

printf '\nOne or more suites failed.\n' >&2
exit 1
