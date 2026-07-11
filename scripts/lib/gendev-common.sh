#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

# Shared lightweight helpers for methodology scripts.

_GENDEV_COMMON_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENDEV_GATE_LOG_EVENTS_FILE=""
GENDEV_GATE_LOG_EVENTS_OUTPUT=""
GENDEV_GATE_LOG_EVENTS_RC=0

# Placeholder-agnostic unknown value checks used across checker/guard.
gendev_is_unknown() {
  case "$1" in
    "" | "TBD" | "\"TBD\"" | "[]" | "[TBD]" | "[Project Name]" | "[project-slug]")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Portable temporary resource helpers.
gendev_mktemp_file() {
  mktemp "$@"
}

gendev_mktemp_dir() {
  mktemp -d
}

gendev_cleanup_tmp() {
  path="$1"
  [ -z "$path" ] || rm -rf "$path"
}

# Portably render today in UTC date-only format.
gendev_utc_date() {
  date -u +%Y-%m-%d
}

# Minimal YAML scalar escaping for one-line values.
gendev_yaml_scalar_escape() {
  printf '%s' "$1" |
    sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g'
}

gendev_yaml_double_quote_scalar() {
  printf '"%s"\n' "$(gendev_yaml_scalar_escape "$1")"
}

# Manifest block parsers.
gendev_manifest_section_value() {
  manifest="$1"
  section="$2"
  key="$3"

  awk -v section="$section" -v key="$key" '
    /^[^[:space:]][^:]*:/ {
      current = $1
      sub(":", "", current)
      in_section = (current == section)
      next
    }
    in_section && $0 ~ "^[[:space:]]+" key ":" {
      sub("^[[:space:]]*" key ":[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$manifest"
}

gendev_manifest_nested_value() {
  manifest="$1"
  section="$2"
  nested="$3"
  key="$4"

  awk -v section="$section" -v nested="$nested" -v key="$key" '
    /^[^[:space:]][^:]*:/ {
      current = $1
      sub(":", "", current)
      in_section = (current == section)
      in_nested = 0
      next
    }
    in_section && $0 ~ "^[[:space:]]{2}" nested ":" {
      in_nested = 1
      next
    }
    in_section && in_nested && $0 ~ "^[[:space:]]{2}[A-Za-z0-9_]+:" {
      in_nested = 0
    }
    in_section && in_nested && $0 ~ "^[[:space:]]{4}" key ":" {
      sub("^[[:space:]]*" key ":[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$manifest"
}

gendev_manifest_section_list_values() {
  manifest="$1"
  section="$2"
  list_key="$3"

  awk -v section="$section" -v list_key="$list_key" '
    /^[^[:space:]][^:]*:/ {
      current = $1
      sub(":", "", current)
      in_section = (current == section)
      next
    }
    in_section && $0 ~ "^[[:space:]]{2}" list_key ":" {
      in_list = 1
      next
    }
    in_section && in_list && /^[[:space:]]{2}[A-Za-z0-9_]+:/ {
      exit
    }
    in_section && in_list && /^[[:space:]]{4}- / {
      sub("^[[:space:]]*-[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
    }
  ' "$manifest"
}

gendev_manifest_section_block() {
  manifest="$1"
  section="$2"

  awk -v section="$section" '
    /^[^[:space:]][^:]*:/ {
      current = $1
      sub(":", "", current)
      in_section = (current == section)
      if (in_section) {
        next
      }
    }
    in_section && /^[^[:space:]][^:]*:/ {
      exit
    }
    in_section {
      print
    }
  ' "$manifest"
}

gendev_manifest_current_gate_block() {
  manifest="$1"

  awk '
    /^approvals:/ {
      in_approvals = 1
      next
    }
    /^[^[:space:]][^:]*:/ && in_approvals {
      exit
    }
    in_approvals && /^  current_gate:/ {
      in_gate = 1
      next
    }
    in_gate && /^  [A-Za-z0-9_]+:/ {
      exit
    }
    in_gate {
      print
    }
  ' "$manifest"
}

gendev_manifest_current_gate_list_values() {
  manifest="$1"
  list_key="$2"

  awk -v list_key="$list_key" '
    /^approvals:/ {
      in_approvals = 1
      next
    }
    /^[^[:space:]][^:]*:/ && in_approvals {
      exit
    }
    in_approvals && /^  current_gate:/ {
      in_gate = 1
      next
    }
    in_gate && /^[[:space:]]{2}[A-Za-z0-9_]+:/ {
      exit
    }
    in_gate && $0 ~ "^[[:space:]]{4}" list_key ":" {
      in_list = 1
      next
    }
    in_list && /^    [A-Za-z0-9_]+:/ {
      exit
    }
    in_list && /^      - / {
      sub("^[[:space:]]*-[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
    }
  ' "$manifest"
}

# Gate-log parser helpers.
gendev_gate_log_records_section() {
  log="$1"

  awk '
    /^## Gate Records/ {
      in_records = 1
      next
    }
    in_records && /^## / {
      exit
    }
    in_records {
      print
    }
  ' "$log"
}

gendev_gate_log_load_events() {
  log="$1"

  if [ "$GENDEV_GATE_LOG_EVENTS_FILE" != "$log" ] || [ -z "${GENDEV_GATE_LOG_EVENTS_OUTPUT+x}" ]; then
    GENDEV_GATE_LOG_EVENTS_FILE="$log"
    awk_script="${_GENDEV_COMMON_LIB_DIR}/gate-log.awk"
    tmp_err="$(mktemp)"
    GENDEV_GATE_LOG_EVENTS_OUTPUT="$(awk -f "$awk_script" "$log" 2>"$tmp_err")"
    GENDEV_GATE_LOG_EVENTS_RC=$?
    cat "$tmp_err"
    rm -f "$tmp_err"
  fi

  return "$GENDEV_GATE_LOG_EVENTS_RC"
}

gendev_gate_log_events() {
  log="$1"

  [ -f "$log" ] || return 1

  if ! gendev_gate_log_load_events "$log"; then
    return 1
  fi

  printf '%s\n' "$GENDEV_GATE_LOG_EVENTS_OUTPUT"
}

gendev_gate_log_has_structured_event() {
  log="$1"
  event_type="$2"

  if ! parsed_gate_events="$(
    gendev_gate_log_events "$log"
  )"; then
    return 1
  fi

  printf '%s\n' "$parsed_gate_events" |
    awk -F'\t' -v event_type="$event_type" '{
      if ($2 == event_type) {
        exit_found = 1
      }
    }
    END { exit !exit_found }'
}

gendev_gate_log_has_legacy_approval() {
  log="$1"

  [ -f "$log" ] || return 1

  gendev_gate_log_records_section "$log" |
    grep -Eq '^## .+ Approval|Decision:[[:space:]]*(Approved|Accepted|approved|accepted)'
}

gendev_gate_log_missing_executable_evidence_for_g6_plus() {
  log="$1"

  [ -f "$log" ] || return 0

  if ! parsed_gate_events="$(
    gendev_gate_log_events "$log"
  )"; then
    return 1
  fi

  printf '%s\n' "$parsed_gate_events" |
    awk -F'\t' '
      {
        if ($2 != "gate_transition") {
          next
        }
        if ($4 !~ /^G[6-9]([.-]|$)/ && $5 !~ /^G[6-9]([.-]|$)/) {
          next
        }
        if ($9 == 0) {
          missing = 1
        }
      }
      END { exit !missing }
    '
}

gendev_gate_log_has_stale_gate_transition_evidence() {
  log="$1"

  [ -f "$log" ] || return 1

  if ! parsed_gate_events="$(
    gendev_gate_log_events "$log"
  )"; then
    return 1
  fi

  printf '%s\n' "$parsed_gate_events" |
    awk -F'\t' '
      $2 == "gate_transition" && $10 == 1 { found = 1 }
      END { exit !found }
    '
}
