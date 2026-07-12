#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Shared helpers for methodology regression suites.

set -u
set -o pipefail

# Ripgrep is a declared GenDev prerequisite (see scripts/lib/gendev-common.sh).
# The suites previously emulated rg with grep when it was missing; that shim is
# gone because emulation drift between engines is worse than a hard
# requirement. A missing rg fails loudly here instead of silently changing
# which regex engine ran the checks.
if ! command -v rg >/dev/null 2>&1; then
  printf 'ERROR: methodology test suites require ripgrep (rg). ' >&2
  printf 'Install: apt install ripgrep | brew install ripgrep | winget install BurntSushi.ripgrep.MSVC | cargo install ripgrep\n' >&2
  exit 3
fi

TH_COMMAND_SHELL="/bin/bash"

TH_SUITE=""
TH_WORKDIR=""
TH_KEEP_ON_FAILURE=0
TH_CASE_PASS=0
TH_CASE_FAIL=0
TH_CASE_COUNT=0
TH_LAST_CASE_RC=0
TH_LAST_CASE_OUTPUT=""

th_set_suite() {
  TH_SUITE="$1"
}

th_set_keep_on_failure() {
  TH_KEEP_ON_FAILURE="$1"
}

th_require_compatible_bash() {
  if [ ! -x "$TH_COMMAND_SHELL" ]; then
    echo "Required command shell missing: $TH_COMMAND_SHELL" >&2
    return 1
  fi

  local major="${BASH_VERSINFO[0]:-0}"
  local minor="${BASH_VERSINFO[1]:-0}"
  if [ "$major" -lt 3 ] || ( [ "$major" -eq 3 ] && [ "$minor" -lt 2 ] ); then
    echo "Bash 3.2+ is required for portability compatibility, found $BASH_VERSION" >&2
    return 1
  fi
}

th_init_suite() {
  local requested_dir=""

  if [ "$#" -gt 0 ]; then
    requested_dir="$1"
    TH_WORKDIR="$requested_dir"
  else
    TH_WORKDIR="$(mktemp -d)"
  fi

  mkdir -p "$TH_WORKDIR/.methodology-suite-outputs"
  TH_CASE_PASS=0
  TH_CASE_FAIL=0
  TH_CASE_COUNT=0
  TH_LAST_CASE_RC=0
  TH_LAST_CASE_OUTPUT=""
}

th_temp_copy() {
  local source="$1"
  local destination="$2"

  rm -rf "$destination"
  mkdir -p "$destination"
  if (cd "$source" && tar --exclude .git --exclude .tmp -cf - .) | (cd "$destination" && tar -xf -); then
    :
  else
    cp -R "$source/." "$destination" 2>/dev/null || cp -R "$source/" "$destination"
  fi
  rm -rf "$destination/.git"
  rm -rf "$destination/.tmp"
}

th_hash_file() {
  local target="$1"

  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$target" | awk '{print $1}'
    return
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$target" | awk '{print $1}'
    return
  fi

  # Fallback for environments without a dedicated SHA-256 helper.
  python3 - "$target" <<'PY'
import hashlib
import sys

path = sys.argv[1]
with open(path, 'rb') as handle:
    print(hashlib.sha256(handle.read()).hexdigest())
PY
}

th_cleanup() {
  if [ "${TH_KEEP_ON_FAILURE}" -eq 1 ]; then
    if [ -n "${TH_WORKDIR}" ] && [ -d "${TH_WORKDIR}" ]; then
      printf 'Retained worktree: %s\n' "${TH_WORKDIR}" >&2
    fi
    return
  fi

  if [ "${TH_CASE_FAIL}" -gt 0 ]; then
    if [ -n "${TH_WORKDIR}" ] && [ -d "${TH_WORKDIR}" ]; then
      printf 'Retained worktree for failed run: %s\n' "${TH_WORKDIR}" >&2
    fi
    return
  fi

  if [ -n "${TH_WORKDIR}" ] && [ -d "${TH_WORKDIR}" ]; then
    rm -rf "${TH_WORKDIR}"
  fi
}

th_emit_case_line() {
  local verdict="$1"
  local case_id="$2"
  local expected_rc="$3"
  local actual_rc="$4"
  local description="$5"

  printf '%s | %s | expected=%s actual=%s | %s\n' \
    "$TH_SUITE" "$case_id" "$expected_rc" "$actual_rc" "$description"

  if [ "$verdict" = "PASS" ]; then
    printf '  [%s] %s\n' "$verdict" "$description"
  else
    printf '  [%s] %s\n' "$verdict" "$description"
    if [ -n "$TH_LAST_CASE_OUTPUT" ]; then
      printf '  output:\n'
      printf '%s\n' "$TH_LAST_CASE_OUTPUT" | sed -n '1,12p' | sed 's/^/    /'
      if [ "$TH_CASE_FAIL" -eq 1 ]; then
        printf '  ... first 12 lines shown ...\n'
      fi
    fi
  fi
}

th_run_case() {
  local case_id=""
  local expected_rc=""
  local description=""
  local command=""
  local expect_pattern=""

  case_id="$1"
  expected_rc="$2"
  description="$3"
  command="$4"

  if [ "$#" -gt 4 ]; then
    expect_pattern="$5"
  else
    expect_pattern=""
  fi

  TH_CASE_COUNT=$((TH_CASE_COUNT + 1))
  local output_file="$TH_WORKDIR/.methodology-suite-outputs/${case_id}.out"

  TH_LAST_CASE_RC=0
  TH_LAST_CASE_OUTPUT=""

  # ShellCheck is conservative about stringy commands, but here command is a
  # test literal authored in the suite.
  LC_ALL=C "$TH_COMMAND_SHELL" -lc "$command" > "$output_file" 2>&1
  TH_LAST_CASE_RC=$?
  TH_LAST_CASE_OUTPUT="$(cat "$output_file")"

  if [ "$TH_LAST_CASE_RC" -ne "$expected_rc" ]; then
    TH_CASE_FAIL=$((TH_CASE_FAIL + 1))
    th_emit_case_line "FAIL" "$case_id" "$expected_rc" "$TH_LAST_CASE_RC" "$description"
    return 1
  fi

  if [ -n "$expect_pattern" ]; then
    if ! printf '%s' "$TH_LAST_CASE_OUTPUT" | LC_ALL=C grep -Eq "$expect_pattern"; then
      TH_CASE_FAIL=$((TH_CASE_FAIL + 1))
      th_emit_case_line "FAIL" "$case_id" "$expected_rc" "$TH_LAST_CASE_RC" \
        "${description}: expected output match '$expect_pattern'"
      return 1
    fi
  fi

  TH_CASE_PASS=$((TH_CASE_PASS + 1))
  th_emit_case_line "PASS" "$case_id" "$expected_rc" "$TH_LAST_CASE_RC" "$description"
  return 0
}

th_summary() {
  printf '\nSuite %s: %s passed, %s failed, %s total\n' \
    "$TH_SUITE" "$TH_CASE_PASS" "$TH_CASE_FAIL" "$TH_CASE_COUNT"
}
