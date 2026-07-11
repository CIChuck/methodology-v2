#!/usr/bin/env awk -f
# SPDX-License-Identifier: MIT
#
# Restricted gate-log parser.
# Parses only event blocks under "## Gate Records", and only within fenced YAML blocks.
# Emits one validated event per line:
#   index    event_type    from_gate    to_gate    gate    status    has_checked
#   has_evidence    has_exec_or_verif    has_stale_status    approver
#   combined_gates    combined_gate_justification    position    phase_id
#   has_exit_test    has_regression_suite    has_learnings    event_id    schema_version
#
# Return code:
#   0 - parse completed with no validation failures
#   1 - structural issue or malformed event found

function fail(msg,    n) {
  n = ++error_count
  print "gate-log.awk: parse error (" n "): " msg > "/dev/stderr"
}

function reset_event(    k) {
  event_line = 0
  event_type = ""
  from_gate = ""
  to_gate = ""
  gate = ""
  status = ""
  approver = ""
  combined_gates = ""
  combined_gate_justification = ""
  position = ""
  phase_id = ""
  event_id = ""
  schema_version = ""
  has_checked = 0
  has_evidence = 0
  has_exec_or_verif = 0
  has_stale_status = 0
  has_exit_test = 0
  has_regression_suite = 0
  has_learnings = 0
  top_level_key_count = 0
  in_event = 1
  delete seen_keys
}

function emit_event(    t) {
  if (!in_event) {
    return
  }
  if (event_type == "") {
    fail("event block starting at line " event_start_line " is missing event_type")
    in_event = 0
    return
  }
  if (top_level_key_count == 0) {
    fail("event block starting at line " event_start_line " has no top-level keys")
    in_event = 0
    return
  }

  t = event_count
  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", t, event_type, from_gate, to_gate, gate, status, has_checked, has_evidence, has_exec_or_verif, has_stale_status, approver, combined_gates, combined_gate_justification, position, phase_id, has_exit_test, has_regression_suite, has_learnings, event_id, schema_version
  in_event = 0
}

function leading_spaces(line,    n) {
  n = 0
  while (n < length(line) && substr(line, n + 1, 1) == " ") {
    n++
  }
  return n
}

BEGIN {
  in_records = 0
  in_yaml = 0
  event_count = 0
  error_count = 0
}

/^## Gate Records/ {
  in_records = 1
  next
}
in_records && /^#{2,3}[[:space:]]+(Gate Event|Phase Checkpoint|Phase Transition|Deployment Approval)/ {
  next
}
in_records && /^## / {
  if (in_yaml) {
    emit_event()
    in_yaml = 0
    in_event = 0
  }
  exit
}
in_records && /^```[[:space:]]*yaml([[:space:]]+.*)?$/ {
  in_yaml = 1
  reset_event()
  event_count++
  event_start_line = NR
  next
}
in_records && /^```[[:space:]]*$/ && in_yaml {
  emit_event()
  in_yaml = 0
  in_event = 0
  next
}

in_records && in_yaml {
  if ($0 ~ /\t/) {
    fail("tabs are not allowed in gate-log YAML event blocks (line " NR ")")
    next
  }

  if ($0 ~ /^[[:space:]]*#/) {
    next
  }

  # Ignore empty lines and list entry lines; list entry contents are not parsed.
  if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^[[:space:]]*-/) {
    next
  }

  if ($0 ~ /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*:[[:space:]]*/) {
    indent = leading_spaces($0)
    if (indent % 2 != 0) {
      fail("malformed indentation in line " NR "; nested YAML keys must use 2-space increments")
      next
    }

    line = $0
    sub(/^[[:space:]]*/, "", line)
    key = line
    sub(/:.*/, "", key)

    value = line
    sub(/^[A-Za-z0-9_]+:[[:space:]]*/, "", value)

    if (indent == 0) {
      if (seen_keys[key] == 1) {
        fail("duplicate top-level key '" key "' in event block starting line " event_start_line)
        next
      }
      seen_keys[key] = 1
      top_level_key_count++
    }

    if (indent != 0) {
      next
    }

    if (key == "event_type") {
      event_type = value
    } else if (key == "event_id") {
      event_id = value
    } else if (key == "schema_version") {
      schema_version = value
    } else if (key == "from_gate") {
      from_gate = value
    } else if (key == "to_gate") {
      to_gate = value
    } else if (key == "gate" && gate == "") {
      gate = value
    } else if (key == "status") {
      status = value
      if (value == "Stale" || value == "Superseded") {
        has_stale_status = 1
      }
    } else if (key == "decided_by" && approver == "") {
      approver = value
    } else if (key == "approved_by" && approver == "") {
      approver = value
    } else if (key == "approver" && approver == "") {
      approver = value
    } else if (key == "decision" && status == "") {
      status = value
    } else if (key == "checked") {
      has_checked = 1
    } else if (key == "evidence") {
      has_evidence = 1
    } else if (key == "combined_gates") {
      combined_gates = value
    } else if (key == "combined_gate_justification") {
      combined_gate_justification = value
    } else if (key == "position") {
      position = value
      gsub(/^"|"$/, "", position)
    } else if (key == "phase_id") {
      phase_id = value
      gsub(/^"|"$/, "", phase_id)
    } else if (key == "exit_test") {
      has_exit_test = 1
    } else if (key == "regression_suite") {
      has_regression_suite = 1
    } else if (key == "learnings") {
      has_learnings = 1
    } else if (key == "executable_evidence" || key == "verification_evidence") {
      has_exec_or_verif = 1
    }
  } else if ($0 !~ /^[[:space:]]*$/) {
    # Any non-comment, non-key content inside yaml at unexpected indentation
    # is treated as a malformed event record line.
    fail("unexpected content in gate-log YAML event block at line " NR)
  }
}

END {
  if (in_yaml) {
    fail("gate-log YAML event block started at line " event_start_line " was not terminated by a closing fence")
    emit_event()
  }

  if (error_count > 0) {
    exit 1
  }
}
